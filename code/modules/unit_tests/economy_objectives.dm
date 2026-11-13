/// Человек с разумом, ключом и личным счётом.
/datum/unit_test/proc/econ_objective_traitor(key, balance = 0)
	var/mob/living/carbon/human/traitor = allocate(/mob/living/carbon/human)
	traitor.mind_initialize()
	traitor.mind.key = key
	var/datum/bank_account/account = allocate(/datum/bank_account, "Econ Test [key]")
	traitor.account_id = account.account_id
	if(balance)
		econ_test_set_balance(account, balance)
	return traitor

/datum/unit_test/proc/econ_objective_new(objective_type, datum/mind/owner)
	var/datum/objective/economy/objective = new objective_type
	allocated += objective
	objective.owner = owner
	return objective

/// Анонимная карта в руке; её счёт закрывается вместе с тестом.
/datum/unit_test/proc/econ_objective_anon_card(mob/living/carbon/human/holder)
	var/obj/item/anon_account_card/card = allocate(/obj/item/anon_account_card)
	allocated += card.account
	holder.put_in_hands(card)
	return card

/// Цель числится за предателем: так она действующая.
/datum/unit_test/proc/econ_objective_assign(mob/living/carbon/human/person, datum/objective/objective)
	var/datum/antagonist/traitor/antag = person.mind.has_antag_datum(/datum/antagonist/traitor)
	if(!antag)
		econ_test_traitor(person)
		antag = person.mind.has_antag_datum(/datum/antagonist/traitor)
	antag.objectives += objective

/// Экономические цели на настоящей экономике: дела аудита, наличные, шанс и режим раунда возвращаются.
/datum/unit_test/economy_objectives
	abstract_type = /datum/unit_test/economy_objectives
	var/list/saved_flags
	var/saved_cash
	var/saved_chance
	var/saved_round_type
	/// Счёт -> баланс до теста
	var/list/saved_balances = list()

/datum/unit_test/economy_objectives/New()
	. = ..()
	saved_flags = SSeconomy.audit_flags
	SSeconomy.audit_flags = list()
	saved_cash = SSeconomy.cash_account.account_balance
	saved_chance = SSeconomy.settings.traitor_econ_objective_chance
	saved_round_type = GLOB.round_type

/datum/unit_test/economy_objectives/Destroy()
	QDEL_LIST(SSeconomy.audit_flags)
	SSeconomy.audit_flags = saved_flags
	econ_test_set_balance(SSeconomy.cash_account, saved_cash)
	SSeconomy.settings.traitor_econ_objective_chance = saved_chance
	GLOB.round_type = saved_round_type
	for(var/datum/bank_account/account as anything in saved_balances)
		econ_test_set_balance(account, saved_balances[account])
	return ..()

/datum/unit_test/economy_objectives/proc/keep_balance(datum/bank_account/account)
	if(account && !(account in saved_balances))
		saved_balances[account] = account.account_balance

/// Растрата засчитывает только переводы из бюджета, проведённые владельцем цели; зарплата и премия другого главы не в счёт, возврат аудитом отнимает своё.
/datum/unit_test/economy_objectives/embezzle/Run()
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestembezzler")
	var/datum/bank_account/own = econ_account_of(traitor)
	own.department_id = ACCOUNT_ENG
	econ_test_badge(traitor, list(ACCESS_CE))
	var/mob/living/carbon/human/other_head = allocate(/mob/living/carbon/human)
	econ_test_badge(other_head, list(ACCESS_CE))
	var/mob/living/carbon/human/auditor = allocate(/mob/living/carbon/human)
	econ_test_badge(auditor, list(ACCESS_HOS))
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	for(var/datum/bank_account/budget_account as anything in list(engineering.account, SSeconomy.treasury(), SSeconomy.get_dep_account(ACCOUNT_SEC)))
		keep_balance(budget_account)
	econ_test_set_balance(engineering.account, 50000)

	var/datum/objective/economy/embezzle/objective = econ_objective_new(/datum/objective/economy/embezzle, traitor.mind)
	TEST_ASSERT(objective.forge(), "Растрата не выдана")
	var/budget = SSeconomy.settings.department_start_budget
	TEST_ASSERT(objective.target_amount >= budget * ECON_OBJECTIVE_EMBEZZLE_MIN / 100 && objective.target_amount <= budget * ECON_OBJECTIVE_EMBEZZLE_MAX / 100, "Сумма растраты [objective.target_amount] вне доли бюджета")
	objective.target_department = ACCOUNT_ENG
	var/amount = objective.target_amount

	TEST_ASSERT(SSeconomy.move(engineering.account, own, amount, ECON_WAGE), "Зарплата")
	TEST_ASSERT(engineering.pay_bonus(own, amount, other_head), "Премия от другого главы")
	TEST_ASSERT(!objective.check_completion(), "Зарплата и чужая премия засчитаны как растрата")
	TEST_ASSERT(engineering.pay_bonus(own, amount, traitor), "Премия себе")
	TEST_ASSERT(objective.check_completion(), "Премия себе из бюджета не засчитана")
	TEST_ASSERT(findtext(objective.explanation_text, "выведено [amount] из [amount] кр."), "Итог без прогресса: [objective.explanation_text]")

	var/datum/econ_audit_flag/case
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.flags_for(own))
		if(flag.kind == AUDIT_FLAG_SELF_BONUS)
			case = flag
	TEST_ASSERT_NOTNULL(case, "Премия себе не попала в аудит")
	TEST_ASSERT(SSeconomy.freeze_account(own, auditor, "растрата"), "Заморозка")
	TEST_ASSERT(SSeconomy.refund(own, engineering.account, amount, auditor, case.uid), "Возврат по делу")
	TEST_ASSERT(!objective.check_completion(), "Возвращённое аудитом засчитано")

/// Кража засчитывается за чужие деньги, которые владелец сам увёл скиммером, держится, пока украденное при нём, и уменьшается на возврат жертве по делу аудита.
/datum/unit_test/economy_objectives/hoard/Run()
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtesthoarder")
	var/datum/bank_account/own = econ_account_of(traitor)
	var/obj/item/anon_account_card/anon = econ_objective_anon_card(traitor)
	var/obj/item/card_skimmer/skimmer = allocate(/obj/item/card_skimmer)
	traitor.put_in_hands(skimmer)
	var/mob/living/carbon/human/friend = econ_objective_traitor("econtestfriend", 5000)
	var/datum/bank_account/sink = allocate(/datum/bank_account, "Econ Test Sink")

	var/datum/objective/economy/hoard/objective = econ_objective_new(/datum/objective/economy/hoard, traitor.mind)
	TEST_ASSERT(objective.forge(), "Кража не выдана")
	var/wage = SSeconomy.settings.wages[PAY_GRADE_MEDIUM]
	TEST_ASSERT(objective.target_amount >= wage * ECON_OBJECTIVE_HOARD_MIN && objective.target_amount <= wage * ECON_OBJECTIVE_HOARD_MAX, "Сумма кражи [objective.target_amount] вне диапазона")
	var/rate = SSeconomy.settings.skim_rate
	objective.target_amount = rate * 2

	own.credit(objective.target_amount * 3, ECON_WAGE)
	TEST_ASSERT_NULL(SSeconomy.send_transfer(econ_account_of(friend), own, 500, friend), "Подарок друга")
	TEST_ASSERT(!objective.check_completion(), "Честные деньги и подарок засчитаны как кража")
	TEST_ASSERT_NULL(SSeconomy.send_transfer(own, sink, own.account_balance, traitor), "Свои деньги потрачены")

	for(var/index in 1 to 2)
		var/datum/bank_account/victim = allocate(/datum/bank_account, "Econ Test Victim [index]")
		econ_test_set_balance(victim, 5000)
		var/obj/item/card/id/card = allocate(/obj/item/card/id)
		card.registered_account = victim
		TEST_ASSERT(skimmer.skim_card(card, traitor), "Скиммер не скопировал карту [index]")
		var/result = skimmer.siphon(index, anon.account.account_id, rate, traitor)
		TEST_ASSERT_NULL(result, "Скиммер не перевёл: [result]")
		if(index == 1)
			TEST_ASSERT(!objective.check_completion(), "Половина кражи засчитана")
	TEST_ASSERT(objective.check_completion(), "Украденное скиммером не засчитано")

	traitor.dropItemToGround(skimmer)
	var/obj/item/holochip/chip = anon.cash_out(anon.account.account_balance, traitor)
	TEST_ASSERT_NOTNULL(chip, "Наличные не сняты")
	traitor.put_in_hands(chip)
	TEST_ASSERT(objective.check_completion(), "Украденное наличными при себе не засчитано")
	chip.forceMove(get_step(traitor, EAST))
	var/obj/item/coin/gold/coin = allocate(/obj/item/coin/gold)
	coin.forceMove(traitor)
	TEST_ASSERT(!objective.check_completion(), "Засчитаны наличные, которых при себе нет")
	qdel(chip)

	var/mob/living/carbon/human/auditor = allocate(/mob/living/carbon/human)
	econ_test_badge(auditor, list(ACCESS_HOS))
	var/datum/bank_account/last_victim = allocate(/datum/bank_account, "Econ Test Victim 3")
	econ_test_set_balance(last_victim, 5000)
	var/obj/item/card/id/last_card = allocate(/obj/item/card/id)
	last_card.registered_account = last_victim
	TEST_ASSERT(skimmer.skim_card(last_card, traitor), "Скиммер не скопировал третью карту")
	TEST_ASSERT_NULL(skimmer.siphon(3, anon.account.account_id, rate, traitor), "Третья кража")
	var/datum/econ_audit_flag/case
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.flags_for(anon.account))
		if(flag.kind == AUDIT_FLAG_UNKNOWN_DEVICE && flag.account_number == last_victim.account_id)
			case = flag
	TEST_ASSERT_NOTNULL(case, "Кража не попала в аудит")
	TEST_ASSERT(SSeconomy.freeze_account(anon.account, auditor, "кража"), "Заморозка")
	anon.forceMove(get_step(traitor, WEST))
	TEST_ASSERT(SSeconomy.refund(anon.account, last_victim, rate, auditor, case.uid), "Возврат по делу")
	objective.check_completion()
	TEST_ASSERT(findtext(objective.explanation_text, "украдено [rate * 2] кр., при себе 0 кр."), "Возврат жертве со сбором СБ не вычтен с карты не на руках или монета посчитана: [objective.explanation_text]")

/// Наличные, снятые с чужого счёта и внесённые обратно, не засчитываются кражей, растратой и выкачкой; анонимный и служебный счета - не кража, служебный скиммер не копирует.
/datum/unit_test/economy_objectives/put_back/Run()
	GLOB.round_type = ROUNDTYPE_DYNAMIC_HARD
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestcycler")
	var/datum/bank_account/victim = allocate(/datum/bank_account, "Econ Test Cycle Victim")
	econ_test_set_balance(victim, 1000)
	var/obj/item/card/id/victim_card = allocate(/obj/item/card/id)
	victim_card.registered_account = victim
	var/datum/objective/economy/hoard/hoard = econ_objective_new(/datum/objective/economy/hoard, traitor.mind)
	TEST_ASSERT(hoard.forge(), "Кража не выдана")
	for(var/cycle in 1 to 3)
		TEST_ASSERT(SSeconomy.move(victim, SSeconomy.cash_account, 300, ECON_CASH_OUT, traitor), "Снятие наличных с чужой карты")
		victim_card.insert_money(allocate(/obj/item/holochip, run_loc_floor_bottom_left, 300), traitor)
	TEST_ASSERT_EQUAL(victim.account_balance, 1000, "Наличные не вернулись на счёт")
	TEST_ASSERT_EQUAL(hoard.stolen, 0, "Снятое и внесённое обратно засчитано кражей")
	TEST_ASSERT(SSeconomy.move(victim, SSeconomy.cash_account, 300, ECON_CASH_OUT, traitor), "Снятие наличных с чужой карты")
	TEST_ASSERT_EQUAL(hoard.stolen, 300, "Снятое не засчитано кражей")

	var/obj/item/anon_account_card/stash = allocate(/obj/item/anon_account_card)
	allocated += stash.account
	econ_test_set_balance(stash.account, 1000)
	TEST_ASSERT(SSeconomy.move(stash.account, SSeconomy.cash_account, 500, ECON_CASH_OUT, traitor), "Снятие с анонимного счёта")
	var/datum/team/sol_inspection/inspection = new
	var/datum/bank_account/service = inspection.account
	allocated += service
	qdel(inspection)
	TEST_ASSERT(service.service_account, "Счёт инспекции не служебный")
	econ_test_set_balance(service, 1000)
	TEST_ASSERT(SSeconomy.move(service, SSeconomy.cash_account, 500, ECON_CASH_OUT, traitor), "Снятие со служебного счёта")
	TEST_ASSERT_EQUAL(hoard.stolen, 300, "Анонимный или служебный счёт засчитан кражей")
	var/obj/item/card/id/stash_card = allocate(/obj/item/card/id)
	stash_card.registered_account = stash.account
	TEST_ASSERT(SSeconomy.move(victim, SSeconomy.cash_account, 300, ECON_CASH_OUT, traitor), "Снятие наличных с чужой карты")
	stash_card.insert_money(allocate(/obj/item/holochip, run_loc_floor_bottom_left, 300), traitor)
	TEST_ASSERT_NULL(SSeconomy.send_transfer(stash.account, victim, 300, traitor), "Перевод с анонимного счёта жертве")
	TEST_ASSERT_EQUAL(hoard.stolen, 300, "Вернувшееся жертве через анонимный счёт в шкафу засчитано кражей")
	var/obj/item/card_skimmer/skimmer = allocate(/obj/item/card_skimmer)
	var/obj/item/card/id/service_card = allocate(/obj/item/card/id)
	service_card.registered_account = service
	TEST_ASSERT(!skimmer.skim_card(service_card, traitor), "Скиммер скопировал служебный счёт")
	qdel(hoard)

	var/datum/objective/economy/drain_head/drain = econ_objective_new(/datum/objective/economy/drain_head, traitor.mind)
	drain.target = traitor.mind
	drain.target_account_id = victim.account_id
	for(var/cycle in 1 to 2)
		TEST_ASSERT(SSeconomy.move(victim, SSeconomy.cash_account, 300, ECON_CASH_OUT, traitor), "Снятие наличных с карты главы")
		victim_card.insert_money(allocate(/obj/item/holochip, run_loc_floor_bottom_left, 300), traitor)
	TEST_ASSERT_EQUAL(drain.drained, 0, "Снятое и внесённое обратно засчитано выкачкой")
	TEST_ASSERT(SSeconomy.move(victim, SSeconomy.cash_account, 300, ECON_CASH_OUT, traitor), "Снятие наличных с карты главы")
	TEST_ASSERT_EQUAL(drain.drained, 300, "Снятое с карты главы не засчитано выкачкой")
	qdel(drain)

	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	keep_balance(engineering.account)
	econ_test_set_balance(engineering.account, 50000)
	var/datum/objective/economy/embezzle/embezzle = econ_objective_new(/datum/objective/economy/embezzle, traitor.mind)
	TEST_ASSERT(embezzle.forge(), "Растрата не выдана")
	embezzle.target_department = ACCOUNT_ENG
	var/obj/item/card/id/budget_card = allocate(/obj/item/card/id)
	budget_card.registered_account = engineering.account
	for(var/cycle in 1 to 3)
		TEST_ASSERT(SSeconomy.move(engineering.account, SSeconomy.cash_account, 400, ECON_CASH_OUT, traitor), "Снятие с карты бюджета")
		budget_card.insert_money(allocate(/obj/item/holochip, run_loc_floor_bottom_left, 400), traitor)
	TEST_ASSERT_EQUAL(embezzle.moved, 0, "Снятое с бюджета и внесённое обратно засчитано растратой")
	TEST_ASSERT(SSeconomy.move(engineering.account, SSeconomy.cash_account, 400, ECON_CASH_OUT, traitor), "Снятие с карты бюджета")
	TEST_ASSERT_EQUAL(embezzle.moved, 400, "Снятое с бюджета не засчитано растратой")
	TEST_ASSERT(SSeconomy.record_work(ACCOUNT_ENG, WORK_ENG_POWER_EXPORT, 100, traitor), "Работа владельца не оплачена")
	TEST_ASSERT_EQUAL(embezzle.moved, 400, "Оплата работы владельца отделу отняла растрату")

/// В Лайте кража не засчитывает бюджеты отделов; в Харде засчитывает, кроме бюджета своей растраты; кража не выдаётся вместе с растратой.
/datum/unit_test/economy_objectives/hoard_budgets/Run()
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestbudgetthief")
	var/datum/bank_account/own = econ_account_of(traitor)
	own.department_id = ACCOUNT_ENG
	econ_test_badge(traitor, list(ACCESS_CE))
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	for(var/datum/bank_account/budget_account as anything in list(engineering.account, SSeconomy.treasury()))
		keep_balance(budget_account)
	econ_test_set_balance(engineering.account, 50000)

	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/datum/objective/economy/hoard/light = econ_objective_new(/datum/objective/economy/hoard, traitor.mind)
	TEST_ASSERT(light.forge(), "Кража в Лайте не выдана")
	TEST_ASSERT(!findtext(light.explanation_text, "бюджет"), "В Лайте текст зовёт красть бюджеты: [light.explanation_text]")
	GLOB.round_type = ROUNDTYPE_DYNAMIC_HARD
	var/datum/objective/economy/hoard/hard = econ_objective_new(/datum/objective/economy/hoard, traitor.mind)
	TEST_ASSERT(hard.forge(), "Кража в Харде не выдана")
	TEST_ASSERT(findtext(hard.explanation_text, "бюджетов отделов"), "В Харде текст без бюджетов: [hard.explanation_text]")

	TEST_ASSERT(engineering.pay_bonus(own, 500, traitor), "Премия себе")
	TEST_ASSERT_EQUAL(light.stolen, 0, "В Лайте бюджет засчитан кражей")
	TEST_ASSERT_EQUAL(hard.stolen, 500, "В Харде бюджет не засчитан кражей")

	var/datum/objective/economy/embezzle/embezzle = econ_objective_new(/datum/objective/economy/embezzle, traitor.mind)
	TEST_ASSERT(embezzle.forge(), "Растрата не выдана")
	embezzle.target_department = ACCOUNT_ENG
	TEST_ASSERT(engineering.pay_bonus(own, 500, traitor), "Вторая премия себе")
	TEST_ASSERT_EQUAL(embezzle.moved, 500, "Растрата не засчитала премию")
	TEST_ASSERT_EQUAL(hard.stolen, 500, "Одна премия закрыла и растрату, и кражу")

	qdel(light)
	qdel(hard)
	for(var/attempt in 1 to 30)
		var/datum/objective/economy/rolled = econ_random_objective(traitor.mind)
		TEST_ASSERT(!istype(rolled, /datum/objective/economy/hoard), "Кража выдана вместе с растратой")
		qdel(rolled)
	qdel(embezzle)
	var/datum/objective/economy/hoard/only_hoard = econ_objective_new(/datum/objective/economy/hoard, traitor.mind)
	TEST_ASSERT(only_hoard.forge(), "Кража не выдана")
	for(var/attempt in 1 to 30)
		var/datum/objective/economy/rolled = econ_random_objective(traitor.mind)
		TEST_ASSERT(!istype(rolled, /datum/objective/economy/embezzle) && !istype(rolled, /datum/objective/economy/drain_head), "Растрата или счёт главы выданы вместе с кражей")
		qdel(rolled)

/// Цель выбирает только главу, согласного быть целью без убийства; траты самого главы не в счёт, выкачанное владельцем - в счёт.
/datum/unit_test/economy_objectives/drain_head/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	world_state.set_hard_round(src)
	CONFIG_SET(number/antag_opt_in_command_min, ANTAG_OPT_IN_NOT_TARGET)
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestdrainer")
	var/datum/bank_account/own = econ_account_of(traitor)
	var/datum/mind/refusing = antag_opt_in_crew(ANTAG_OPT_IN_NOT_TARGET, "Chief Engineer")
	var/datum/mind/assistant = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/head = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY, "Captain")
	var/list/head_accounts = list()
	for(var/datum/mind/crew_mind as anything in list(refusing, assistant, head))
		var/datum/bank_account/account = allocate(/datum/bank_account, "Econ Test [crew_mind.assigned_role]")
		var/mob/living/carbon/human/body = crew_mind.current
		body.account_id = account.account_id
		head_accounts[crew_mind] = account
	var/datum/bank_account/head_account = head_accounts[head]
	var/datum/bank_account/sink = allocate(/datum/bank_account, "Econ Test Shop")
	world_state.set_crew(list(traitor.mind, refusing, assistant, head))

	for(var/attempt in 1 to 10)
		var/datum/objective/economy/drain_head/rolled = econ_objective_new(/datum/objective/economy/drain_head, traitor.mind)
		TEST_ASSERT(rolled.forge(), "Опустошение счёта не выдано")
		TEST_ASSERT(rolled.target == head, "Цель - не согласный глава: [rolled.target?.name]")
		qdel(rolled)
	var/datum/objective/economy/drain_head/objective = econ_objective_new(/datum/objective/economy/drain_head, traitor.mind)
	TEST_ASSERT(objective.forge(), "Опустошение счёта не выдано")
	TEST_ASSERT_EQUAL(objective.target_amount, SSeconomy.settings.wages[PAY_GRADE_COMMAND] * SSeconomy.settings.starting_paychecks, "Сколько выкачать")

	econ_test_set_balance(head_account, 2000)
	TEST_ASSERT(SSeconomy.move(head_account, sink, 2000 - ECON_OBJECTIVE_DRAIN_LEFT / 2, ECON_PURCHASE, head.current), "Глава потратил свои деньги")
	TEST_ASSERT(!objective.check_completion(), "Траты самого главы засчитаны")
	head_account.credit(2000, ECON_WAGE)
	TEST_ASSERT_NULL(SSeconomy.send_transfer(head_account, own, objective.target_amount, traitor), "Перевод с украденной карты")
	TEST_ASSERT(!objective.check_completion(), "Засчитано, хотя на счёте главы остались деньги")
	var/left = head_account.account_balance - ECON_OBJECTIVE_DRAIN_LEFT / 2
	TEST_ASSERT(SSeconomy.move(head_account, SSeconomy.cash_account, left, ECON_CASH_OUT, traitor), "Снятие наличных с украденной карты")
	TEST_ASSERT(objective.check_completion(), "Выкачанный счёт главы не засчитан")
	TEST_ASSERT(findtext(objective.explanation_text, "выкачано [objective.target_amount + left] из [objective.target_amount] кр., на счёте [ECON_OBJECTIVE_DRAIN_LEFT / 2] кр."), "Итог без прогресса: [objective.explanation_text]")
	TEST_ASSERT(findtext(objective.explanation_text, "Зарплата пополняет счёт"), "Текст не предупреждает о зарплате")

	head_account.credit(2000, ECON_WAGE)
	var/datum/objective/economy/drain_head/turned = econ_objective_new(/datum/objective/economy/drain_head, traitor.mind)
	TEST_ASSERT(turned.forge(), "Опустошение счёта не выдано")
	TEST_ASSERT(SSeconomy.move(head_account, sink, head_account.account_balance - ECON_OBJECTIVE_DRAIN_LEFT / 2, ECON_PURCHASE, head.current), "Глава потратил свои деньги")
	var/datum/antagonist/custom/role = new
	role.silent = TRUE
	head.add_antag_datum(role)
	var/turned_done = turned.check_completion()
	var/turned_text = turned.explanation_text
	head.remove_antag_datum(/datum/antagonist/custom)
	TEST_ASSERT(!turned_done, "Глава стал антагонистом, и задание засчитано без перекачки")
	TEST_ASSERT(!findtext(turned_text, "антагонист"), "Прогресс выдаёт антагониста: [turned_text]")

	world_state.set_crew(list(traitor.mind, refusing, assistant))
	TEST_ASSERT_NULL(turned.find_target(), "Без глав цель нашлась")
	var/listeners = SSeconomy.comp_lookup[COMSIG_ECONOMY_MOVED]
	TEST_ASSERT(listeners != turned && !(islist(listeners) && (turned in listeners)), "Цель без главы осталась подписана на переводы")
	world_state.set_crew(list(traitor.mind, head))
	TEST_ASSERT(turned.find_target() == head, "Глава не нашёлся при перевыборе")
	head_account.credit(1000, ECON_WAGE)
	TEST_ASSERT(SSeconomy.move(head_account, SSeconomy.cash_account, 1000, ECON_CASH_OUT, traitor), "Снятие наличных с украденной карты")
	TEST_ASSERT_EQUAL(turned.drained, 1000, "После перевыбора цель не слышит перекачку")

/// Ставка на аукционе с украденной карты главы засчитывается, а перебитая и вернувшаяся на его счёт - перестаёт.
/datum/unit_test/economy_objectives/drain_head_auction_refund/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	world_state.set_hard_round(src)
	CONFIG_SET(number/antag_opt_in_command_min, ANTAG_OPT_IN_NOT_TARGET)
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestbidder")
	var/datum/mind/head = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY, "Captain")
	var/datum/bank_account/head_account = allocate(/datum/bank_account, "Econ Test Captain")
	var/mob/living/carbon/human/head_body = head.current
	head_body.account_id = head_account.account_id
	world_state.set_crew(list(traitor.mind, head))
	var/datum/objective/economy/drain_head/objective = econ_objective_new(/datum/objective/economy/drain_head, traitor.mind)
	TEST_ASSERT(objective.forge() && objective.target == head, "Опустошение счёта главы не выдано")
	econ_test_set_balance(head_account, 2000)
	var/datum/auction_lot/lot = allocate(/datum/auction_lot)
	lot.name = "тестовый лот"
	TEST_ASSERT(SSeconomy.move(head_account, SSeconomy.market_account, 500, ECON_AUCTION_BID, traitor, "Аукцион: ставка"), "Ставка с украденной карты")
	lot.set_leader(head_account)
	lot.bid = 500
	TEST_ASSERT_EQUAL(objective.drained, 500, "Ставка с карты главы не засчитана")
	SSmarket.refund_auction_bid(lot)
	TEST_ASSERT_EQUAL(head_account.account_balance, 2000, "Перебитая ставка не вернулась главе")
	TEST_ASSERT_EQUAL(objective.drained, 0, "Вернувшаяся на счёт главы ставка осталась выкачанной")

/// Задания предателя: при шансе 100 в Лайте только мирные экономические цели без повторов, в Харде выпадают и остальные, при шансе 0 - ни одной.
/datum/unit_test/economy_objectives/forge/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	world_state.set_hard_round(src)
	CONFIG_SET(number/antag_opt_in_command_min, ANTAG_OPT_IN_NOT_TARGET)
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestforger")
	var/datum/mind/head = antag_opt_in_crew(ANTAG_OPT_IN_TEMPORARY, "Captain")
	var/datum/bank_account/head_account = allocate(/datum/bank_account, "Econ Test Captain")
	var/mob/living/carbon/human/head_body = head.current
	head_body.account_id = head_account.account_id
	world_state.set_crew(list(traitor.mind, head))
	var/list/light_types = list(/datum/objective/economy/hoard, /datum/objective/economy/stock_profit)
	SSeconomy.settings.traitor_econ_objective_chance = 100
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/datum/antagonist/traitor/antag = new
	var/datum/traitor_class/human/subterfuge = GLOB.traitor_classes[/datum/traitor_class/human/subterfuge]
	var/datum/traitor_class/human/human_class = GLOB.traitor_classes[/datum/traitor_class/human]
	var/list/saved_weights = list()
	for(var/kind in GLOB.traitor_classes)
		var/datum/traitor_class/class = GLOB.traitor_classes[kind]
		saved_weights[kind] = class.weight
	antag.should_equip = FALSE
	antag.silent = TRUE
	traitor.mind.add_antag_datum(antag)
	antag.set_traitor_kind(/datum/traitor_class/human/subterfuge)
	var/list/forged = list()
	for(var/datum/objective/objective as anything in antag.objectives)
		if(istype(objective, /datum/objective/escape))
			continue
		TEST_ASSERT(objective.type in light_types, "В Лайте выдано [objective.type]")
		TEST_ASSERT(!(objective.type in forged), "Повтор цели [objective.type]")
		TEST_ASSERT(length(objective.explanation_text), "Цель без текста")
		forged += objective.type
	TEST_ASSERT_EQUAL(length(forged), min(CONFIG_GET(number/traitor_objectives_amount), length(light_types)), "Задания не экономические")
	var/with_progress = 0
	for(var/list/entry as anything in antag.get_objectives())
		with_progress += !!findtext(entry["explanation"], "Сейчас:")
	TEST_ASSERT_EQUAL(with_progress, length(forged), "Окно антага не показывает прогресс экономических целей")
	QDEL_LIST(antag.objectives)
	traitor.mind.remove_antag_datum(/datum/antagonist/traitor)
	for(var/kind in saved_weights)
		var/datum/traitor_class/class = GLOB.traitor_classes[kind]
		class.weight = saved_weights[kind]

	var/datum/antagonist/traitor/holder = new
	allocated += holder
	holder.owner = traitor.mind
	for(var/attempt in 1 to 30)
		TEST_ASSERT(human_class.forge_single_objective(holder), "Задание не выдано")
		var/datum/objective/objective = holder.objectives[1]
		TEST_ASSERT(objective.type in light_types, "В Лайте выдано [objective.type]")
		QDEL_LIST(holder.objectives)

	GLOB.round_type = ROUNDTYPE_DYNAMIC_HARD
	var/list/seen = list()
	for(var/attempt in 1 to 60)
		TEST_ASSERT(subterfuge.forge_single_objective(holder), "Задание не выдано")
		var/datum/objective/objective = holder.objectives[1]
		TEST_ASSERT(istype(objective, /datum/objective/economy), "При шансе 100 выдано [objective.type]")
		seen[objective.type] = TRUE
		QDEL_LIST(holder.objectives)
	for(var/objective_type in subtypesof(/datum/objective/economy))
		TEST_ASSERT(seen[objective_type], "В Харде ни разу не выдано [objective_type]")

	SSeconomy.settings.traitor_econ_objective_chance = 0
	for(var/attempt in 1 to 30)
		if(!subterfuge.forge_single_objective(holder))
			continue
		for(var/datum/objective/objective as anything in holder.objectives)
			TEST_ASSERT(!istype(objective, /datum/objective/economy), "При шансе 0 выдано [objective.type]")
		QDEL_LIST(holder.objectives)

/// Цели снимают подписки на экономику и биржу при удалении.
/datum/unit_test/economy_objectives/create_and_destroy/Run()
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestdestroyer")
	for(var/objective_type in subtypesof(/datum/objective/economy))
		var/datum/objective/economy/objective = new objective_type
		objective.owner = traitor.mind
		objective.forge()
		qdel(objective)
		for(var/datum/subsystem as anything in list(SSeconomy, SSmarket))
			for(var/signal in subsystem.comp_lookup)
				var/listeners = subsystem.comp_lookup[signal]
				TEST_ASSERT(listeners != objective && !(islist(listeners) && (objective in listeners)), "[objective_type] остался подписан на [signal]")

/// Прибыль на бирже считается с выдачи цели по всем счетам, с которых владелец торговал: убыток выброшенной карты остаётся.
/datum/unit_test/economy_trading/insider/econ_objective_profit/Run()
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtesttrader", 50000)
	var/datum/bank_account/own = econ_account_of(traitor)
	var/ticker = company.ticker
	var/count = round((SSeconomy.settings.stock_position_cap - 1) / max(company.price, company.base_price))
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(own, ticker, count), "Покупка до задания")
	company.apply_shock(0.25)
	expire_cooldown(own, ticker)
	TEST_ASSERT_NULL(SSmarket.try_sell_shares(own, ticker, count), "Продажа до задания")
	TEST_ASSERT(own.realized_stock_profit > 0, "Прибыли до задания нет")

	var/datum/objective/economy/stock_profit/objective = econ_objective_new(/datum/objective/economy/stock_profit, traitor.mind)
	TEST_ASSERT(objective.forge(), "Прибыль на бирже не выдана")
	var/threshold = SSeconomy.settings.audit_insider_threshold
	TEST_ASSERT(objective.target_amount >= threshold * ECON_OBJECTIVE_STOCK_MIN / 100 && objective.target_amount <= threshold * ECON_OBJECTIVE_STOCK_MAX / 100, "Сумма прибыли [objective.target_amount] вне диапазона")
	TEST_ASSERT(!objective.check_completion(), "Прибыль до задания засчитана")

	var/obj/item/anon_account_card/losing = econ_objective_anon_card(traitor)
	econ_test_set_balance(losing.account, 50000)
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(losing.account, ticker, 10), "Покупка с убыточной карты")
	company.apply_shock(-0.25)
	expire_cooldown(losing.account, ticker)
	TEST_ASSERT_NULL(SSmarket.try_sell_shares(losing.account, ticker, 10), "Продажа с убыточной карты")
	var/loss = losing.account.realized_stock_profit
	TEST_ASSERT(loss < 0, "Убытка нет: [loss]")
	losing.forceMove(get_step(traitor, EAST))

	var/obj/item/anon_account_card/anon = econ_objective_anon_card(traitor)
	econ_test_set_balance(anon.account, 50000)
	count = round((SSeconomy.settings.stock_position_cap - 1) / max(company.price, company.base_price))
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(anon.account, ticker, count), "Покупка с анонимной карты")
	company.apply_shock(0.25)
	expire_cooldown(anon.account, ticker)
	TEST_ASSERT_NULL(SSmarket.try_sell_shares(anon.account, ticker, count), "Продажа с анонимной карты")
	var/gain = anon.account.realized_stock_profit
	TEST_ASSERT(gain + loss > 0, "Сделка не окупила убыток: [gain] и [loss]")
	objective.target_amount = gain
	TEST_ASSERT(!objective.check_completion(), "Убыток выброшенной карты не учтён")
	TEST_ASSERT(findtext(objective.explanation_text, "прибыль [gain + loss] кр."), "Итог без прогресса: [objective.explanation_text]")
	objective.target_amount = gain + loss
	TEST_ASSERT(objective.check_completion(), "Прибыль с анонимной карты не засчитана")

/// Обвал засчитывается только пока действует своя плохая фальшивка: падение без неё, от чужой фальшивки и после опровержения не в счёт; чужую фальшивку о компании задания не пропускают, пока жив владелец.
/datum/unit_test/economy_trading/insider/econ_objective_crash/Run()
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestcrasher")
	var/mob/living/carbon/human/stranger = econ_objective_traitor("econteststranger")
	econ_test_traitor(stranger)

	var/datum/objective/economy/crash_stock/rolled = econ_objective_new(/datum/objective/economy/crash_stock, traitor.mind)
	SSmarket.press_released = SSmarket.companies - company.ticker
	TEST_ASSERT(rolled.forge(), "Обвал не выдан")
	econ_objective_assign(traitor, rolled)
	TEST_ASSERT_EQUAL(rolled.company_ticker, company.ticker, "Выбрана компания, о которой фальшивка уже была")
	TEST_ASSERT(rolled.percent >= ECON_OBJECTIVE_CRASH_MIN && rolled.percent <= ECON_OBJECTIVE_CRASH_MAX, "Процент обвала [rolled.percent]")
	var/datum/objective/economy/crash_stock/second = econ_objective_new(/datum/objective/economy/crash_stock, stranger.mind)
	TEST_ASSERT(!second.forge(), "Вторая цель на ту же компанию")
	SSmarket.press_released = list()
	qdel(rolled)
	qdel(second)

	var/datum/objective/economy/crash_stock/objective = econ_objective_new(/datum/objective/economy/crash_stock, traitor.mind)
	TEST_ASSERT(objective.setup(company.ticker, 25), "Обвал не настроен")
	econ_objective_assign(traitor, objective)
	company.apply_shock(-0.15)
	market_tick()
	TEST_ASSERT(!objective.check_completion(), "Падение без фальшивки засчитано")
	var/obj/item/press_release_kit/stranger_kit = allocate(/obj/item/press_release_kit)
	stranger.put_in_hands(stranger_kit)
	var/ready_at = SSmarket.press_release_ready_at
	TEST_ASSERT(!stranger_kit.use_kit(stranger, company, FALSE), "Чужая фальшивка о компании задания принята")
	TEST_ASSERT(!QDELETED(stranger_kit) && SSmarket.press_release_ready_at == ready_at && !(company.ticker in SSmarket.press_released), "Отказ потратил черновик или кулдаун")
	TEST_ASSERT(findtext(objective.explanation_text, "не чаще раза в [SSmarket.press_release_cooldown()] мин."), "Текст без кулдауна сектора")

	var/mob/living/carbon/human/late_owner = econ_objective_traitor("econtestcrashowner")
	var/datum/objective/economy/crash_stock/dead_owner = econ_objective_new(/datum/objective/economy/crash_stock, late_owner.mind)
	var/datum/stock_company/abandoned = SSmarket.get_company("SOLX")
	TEST_ASSERT(dead_owner.setup(abandoned.ticker, 25), "Обвал не настроен")
	econ_objective_assign(late_owner, dead_owner)
	late_owner.death()
	abandoned.apply_shock(-0.15)
	TEST_ASSERT(stranger_kit.use_kit(stranger, abandoned, FALSE), "Компания мёртвого владельца задания осталась закрыта")
	market_tick()
	TEST_ASSERT(abandoned.price <= dead_owner.start_price * 0.75, "Чужая фальшивка не уронила цену: [abandoned.price]")
	TEST_ASSERT(!dead_owner.check_completion(), "Чужая фальшивка засчитана")

	SSmarket.press_release_ready_at = 0
	var/datum/stock_company/weak = SSmarket.get_company("PRSP")
	var/datum/objective/economy/crash_stock/weak_objective = econ_objective_new(/datum/objective/economy/crash_stock, traitor.mind)
	TEST_ASSERT(weak_objective.setup(weak.ticker, 25), "Обвал не настроен")
	weak.apply_shock(-0.15)
	market_tick()
	var/obj/item/press_release_kit/kit = allocate(/obj/item/press_release_kit)
	traitor.put_in_hands(kit)
	TEST_ASSERT(kit.use_kit(traitor, weak, FALSE), "Своя фальшивка не принята")
	TEST_ASSERT(!weak_objective.check_completion(), "Засчитано до выхода фальшивки")
	market_tick()
	TEST_ASSERT(weak_objective.check_completion(), "Своя фальшивка на слабых акциях не засчитана")

	SSmarket.press_release_ready_at = 0
	var/datum/stock_company/strong = SSmarket.get_company("EINS")
	var/datum/objective/economy/crash_stock/during = econ_objective_new(/datum/objective/economy/crash_stock, traitor.mind)
	TEST_ASSERT(during.setup(strong.ticker, 25), "Обвал не настроен")
	var/datum/objective/economy/crash_stock/after = econ_objective_new(/datum/objective/economy/crash_stock, traitor.mind)
	TEST_ASSERT(after.setup(strong.ticker, 60), "Обвал не настроен")
	var/obj/item/press_release_kit/second_kit = allocate(/obj/item/press_release_kit)
	traitor.put_in_hands(second_kit)
	TEST_ASSERT(second_kit.use_kit(traitor, strong, FALSE), "Своя фальшивка не принята")
	market_tick()
	TEST_ASSERT(!during.check_completion(), "Одной фальшивки на сильных акциях хватило: [strong.price]")
	strong.apply_shock(-0.2)
	market_tick()
	TEST_ASSERT(during.check_completion(), "Падение, пока действует своя фальшивка, не засчитано")
	release_on_tick(queued_refutation(strong))
	strong.apply_shock(-0.6)
	market_tick()
	TEST_ASSERT(strong.price <= after.start_price * 0.4, "Цена не упала после опровержения: [strong.price]")
	TEST_ASSERT(!after.check_completion(), "Падение после опровержения засчитано")
	TEST_ASSERT(findtext(after.explanation_text, "самая низкая цена при вашей фальшивке"), "Итог без прогресса: [after.explanation_text]")

/// Обвал считается по цене без сдвига от работы отделов: рост от работы при выдаче не завышает планку, а падение от работы СБ не засчитывается.
/datum/unit_test/economy_trading/insider/econ_objective_crash_work/Run()
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestcrashwork")
	var/datum/stock_company/cybersun = SSmarket.get_company("CYBS")
	cybersun.add_work(0.1, SSmarket.work_stock_cap)
	var/clean_price = cybersun.price / 1.1
	var/datum/objective/economy/crash_stock/objective = econ_objective_new(/datum/objective/economy/crash_stock, traitor.mind)
	TEST_ASSERT(objective.setup(cybersun.ticker, 25), "Обвал не настроен")
	econ_objective_assign(traitor, objective)
	if(abs(objective.start_price - clean_price) >= 0.01)
		TEST_FAIL("Планка обвала от цены с ростом от работы: [objective.start_price] вместо [clean_price]")
	objective.fake_until = world.time + 10 MINUTES
	cybersun.add_work(-0.3, SSmarket.work_stock_cap)
	cybersun.apply_shock(-0.1)
	market_tick()
	TEST_ASSERT(!objective.check_completion(), "Падение от работы станции засчитано в обвал: цена [cybersun.price], без работы [cybersun.price / (1 + cybersun.work_boost)]")
	cybersun.apply_shock(-0.2)
	market_tick()
	TEST_ASSERT(objective.check_completion(), "Обвал без учёта работы не засчитан: [objective.explanation_text]")

/// Снятый антагонист не держит компанию своим заданием на обвал.
/datum/unit_test/economy_trading/insider/econ_objective_crash_removed/Run()
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestcrashremoved")
	var/datum/objective/economy/crash_stock/objective = econ_objective_new(/datum/objective/economy/crash_stock, traitor.mind)
	TEST_ASSERT(objective.setup(company.ticker, 25), "Обвал не настроен")
	var/datum/antagonist/custom/role = new
	role.silent = TRUE
	traitor.mind.add_antag_datum(role)
	role.objectives += objective
	TEST_ASSERT(econ_press_release_reserved(company), "Задание действующего антагониста не держит компанию")
	traitor.mind.remove_antag_datum(/datum/antagonist/custom)
	TEST_ASSERT(!econ_press_release_reserved(company), "Снятый антагонист держит компанию")

/// Контрабанда засчитывается с выдачи цели по продажам Вольным торговцам, где владелец касался товара последним.
/datum/unit_test/economy_contraband/econ_objective_smuggle/Run()
	econ_test_contraband_ready()
	SSeconomy.settings.customs_chance = 0
	var/mob/living/carbon/human/traitor = econ_objective_traitor("econtestsmuggler")
	var/key = ckey(traitor.mind.key)
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/obj/item/card/emag/emag = allocate(/obj/item/card/emag)
	traitor.put_in_active_hand(emag)
	emag.melee_attack_chain(traitor, console)
	TEST_ASSERT(SSmarket.contraband_buyer(), "Вольные торговцы не открылись")
	SSshuttle.supply.export_categories = console.get_export_categories()

	var/obj/item/card/id/syndicate/early = new(shuttle_crate())
	early.fingerprintslast = key
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(early) && SSmarket.contraband_exported_by[key] > 0, "Контрабанда до задания не продана")

	var/datum/objective/economy/smuggle/objective = econ_objective_new(/datum/objective/economy/smuggle, traitor.mind)
	TEST_ASSERT(objective.forge(), "Контрабанда не выдана")
	var/per_tc = SSeconomy.settings.contraband_value_per_tc
	TEST_ASSERT(objective.target_amount >= per_tc * ECON_OBJECTIVE_SMUGGLE_MIN && objective.target_amount <= per_tc * ECON_OBJECTIVE_SMUGGLE_MAX, "Сумма контрабанды [objective.target_amount] вне диапазона")
	TEST_ASSERT(!objective.check_completion(), "Продажа до задания засчитана")

	var/obj/item/card/id/syndicate/foreign = new(shuttle_crate())
	foreign.fingerprintslast = "econtestbystander"
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(foreign), "Чужая контрабанда не продана")
	TEST_ASSERT(!objective.check_completion(), "Чужая продажа засчитана")
	TEST_ASSERT(findtext(objective.explanation_text, "продано на 0 кр."), "Чужая продажа в прогрессе: [objective.explanation_text]")
	var/obj/item/card/id/syndicate/smuggled = new(shuttle_crate())
	smuggled.fingerprintslast = key
	var/expected = econ_export_report_value(export_item_and_contents(smuggled, SSshuttle.supply.export_categories, delete_unsold = FALSE, dry_run = TRUE))
	TEST_ASSERT(expected > 0, "Вольные торговцы не оценили карту")
	objective.target_amount = expected
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(smuggled), "Карта не продана")
	TEST_ASSERT(objective.check_completion(), "Своя контрабанда не засчитана")
	TEST_ASSERT(findtext(objective.explanation_text, "продано на [expected] кр."), "Итог без прогресса: [objective.explanation_text]")
