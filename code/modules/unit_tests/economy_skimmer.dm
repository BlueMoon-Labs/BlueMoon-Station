/datum/unit_test/economy_skimmer
	abstract_type = /datum/unit_test/economy_skimmer
	var/list/saved_flags
	var/saved_cash
	var/saved_transfer_max

/datum/unit_test/economy_skimmer/New()
	. = ..()
	saved_flags = SSeconomy.audit_flags
	SSeconomy.audit_flags = list()
	saved_cash = SSeconomy.cash_account.account_balance
	saved_transfer_max = SSeconomy.settings.transfer_max

/datum/unit_test/economy_skimmer/Destroy()
	QDEL_LIST(SSeconomy.audit_flags)
	SSeconomy.audit_flags = saved_flags
	econ_test_set_balance(SSeconomy.cash_account, saved_cash)
	SSeconomy.settings.transfer_max = saved_transfer_max
	return ..()

/datum/unit_test/economy_skimmer/proc/make_account(holder, balance = 0)
	var/datum/bank_account/account = new(holder)
	allocated += account
	if(balance)
		econ_test_set_balance(account, balance)
	return account

/// Человек с ID-картой на поясе ID, привязанной к account.
/datum/unit_test/economy_skimmer/proc/make_victim(datum/bank_account/account, turf/where)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, where)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = account
	victim.equip_to_slot(card, ITEM_SLOT_ID)
	return victim

/datum/unit_test/economy_skimmer/proc/flag_count(kind, datum/bank_account/account)
	. = 0
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.flags_for(account))
		if(flag.kind == kind)
			.++

/// Скиммер копирует счёт с карты на человеке за do_after, откачивает не больше лимита за скользящую минуту, оставляет след жертве и аудиту и не ставит жертве кулдаун переводов.
/datum/unit_test/economy_skimmer/siphon/Run()
	var/mob/living/carbon/human/thief = allocate(/mob/living/carbon/human)
	econ_test_traitor(thief)
	var/obj/item/card_skimmer/skimmer = allocate(/obj/item/card_skimmer)
	thief.put_in_active_hand(skimmer)
	var/datum/bank_account/victim_account = make_account("econ_test_victim", 5000)
	var/datum/bank_account/drop = make_account("econ_test_drop")
	var/mob/living/carbon/human/victim = make_victim(victim_account, get_step(thief, EAST))
	skimmer.melee_attack_chain(thief, victim)
	TEST_ASSERT(LAZYFIND(thief.do_afters, victim), "Считывание идёт через do_after")
	TEST_ASSERT_EQUAL(length(skimmer.stolen), 0, "До конца do_after доступа нет")
	var/list/budget = new_wait_budget(10 SECONDS, "скиммер считывает карту")
	while(LAZYFIND(thief.do_afters, victim))
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_EQUAL(length(skimmer.stolen), 1, "Доступ скопирован")
	var/rate = SSeconomy.settings.skim_rate
	var/result = skimmer.siphon(1, drop.account_id, rate, thief)
	TEST_ASSERT_NULL(result, "В пределах лимита: [result]")
	TEST_ASSERT_EQUAL(skimmer.siphon(1, drop.account_id, 1, thief), "Не больше [rate] кр. в минуту с одного счёта: сейчас можно ещё 0 кр.", "Сверх лимита отказ")
	TEST_ASSERT_EQUAL(drop.account_balance, rate, "Дошло")
	TEST_ASSERT_EQUAL(victim_account.account_balance, 5000 - rate, "Снято ровно столько, денег не напечатано")
	TEST_ASSERT_EQUAL(flag_count(AUDIT_FLAG_UNKNOWN_DEVICE, victim_account), 1, "Флаг \"неопознанное устройство\"")
	var/seen_in_history = FALSE
	for(var/datum/transaction/entry in victim_account.transaction_history)
		if(entry.reason == ECON_SKIM && entry.amount == -rate && entry.counterparty_number == drop.account_id)
			seen_in_history = TRUE
	TEST_ASSERT(seen_in_history, "Жертва видит списание в истории счёта")
	var/own_transfer = SSeconomy.send_transfer(victim_account, drop, 1, victim)
	TEST_ASSERT_NULL(own_transfer, "Свой перевод жертвы сразу после скима проходит: [own_transfer]")
	var/list/entry = victim_account.skim_log[1]
	entry[1] = world.time - 59 SECONDS
	TEST_ASSERT_NOTNULL(skimmer.siphon(1, drop.account_id, 1, thief), "Минута скользящая: через 59 секунд лимит ещё занят")
	entry[1] = world.time - 61 SECONDS
	TEST_ASSERT_NULL(skimmer.siphon(1, drop.account_id, rate, thief), "Через минуту после списания лимит свободен")

/// Отказы скиммера с точными текстами: свой счёт, бюджет, заблокированный и замороженный счёт, бюджет получателем; вытеснение старшего слота; два скиммера не удваивают лимит.
/datum/unit_test/economy_skimmer/refusals/Run()
	var/mob/living/carbon/human/thief = allocate(/mob/living/carbon/human)
	econ_test_traitor(thief)
	var/obj/item/card_skimmer/skimmer = allocate(/obj/item/card_skimmer)
	var/obj/item/card_skimmer/second = allocate(/obj/item/card_skimmer)
	var/datum/bank_account/drop = make_account("econ_test_drop")
	var/datum/bank_account/own = make_account("econ_test_thief", 1000)
	thief.account_id = own.account_id
	var/obj/item/card/id/own_card = allocate(/obj/item/card/id)
	own_card.registered_account = own
	TEST_ASSERT_EQUAL(skimmer.skim_problem(own_card, thief), "Это ваш собственный счёт.", "Свой счёт")
	TEST_ASSERT(!skimmer.skim_card(own_card, thief), "Свой счёт не копируется")
	var/datum/bank_account/civ_budget = SSeconomy.get_dep_account(ACCOUNT_CIV)
	var/obj/item/card/id/budget_card = allocate(/obj/item/card/id)
	budget_card.registered_account = civ_budget
	TEST_ASSERT_EQUAL(skimmer.skim_problem(budget_card, thief), "Бюджеты, служебные и заблокированные счета скиммер не берёт.", "Бюджет")
	TEST_ASSERT(!skimmer.skim_card(budget_card, thief), "Бюджет отдела не копируется")
	var/list/datum/bank_account/victims = list()
	for(var/index in 1 to SSeconomy.settings.skimmer_slots + 1)
		var/datum/bank_account/account = make_account("econ_test_victim_[index]", 1000)
		var/obj/item/card/id/card = allocate(/obj/item/card/id)
		card.registered_account = account
		TEST_ASSERT(skimmer.skim_card(card, thief), "Скопирован счёт [index]")
		victims += account
	TEST_ASSERT_EQUAL(length(skimmer.stolen), SSeconomy.settings.skimmer_slots, "Слотов не больше настройки")
	var/datum/weakref/oldest = skimmer.stolen[1]
	TEST_ASSERT(oldest.resolve() == victims[2], "Вытеснен самый старый счёт")
	var/datum/bank_account/frozen = victims[2]
	frozen.state = ACCOUNT_FROZEN
	TEST_ASSERT_EQUAL(skimmer.siphon(1, drop.account_id, 10, thief), "Счёт заморожен финансовым аудитом.", "Замороженный счёт не платит")
	frozen.state = ACCOUNT_ACTIVE
	frozen.transferable = FALSE
	TEST_ASSERT_EQUAL(skimmer.siphon(1, drop.account_id, 10, thief), "Счёт заблокирован.", "Заблокированный счёт не платит")
	frozen.transferable = TRUE
	TEST_ASSERT_EQUAL(frozen.account_balance, 1000, "С закрытых счетов ничего не ушло")
	TEST_ASSERT_EQUAL(skimmer.siphon(2, civ_budget.account_id, 10, thief), "Получать деньги можно только на личный счёт.", "На бюджет отдела не откачать")
	SSeconomy.settings.transfer_max = 5
	TEST_ASSERT_EQUAL(skimmer.siphon(2, drop.account_id, 10, thief), "Сумма выше лимита: не больше 5 кр. за раз.", "Лимит одного перевода")
	SSeconomy.settings.transfer_max = saved_transfer_max
	var/rate = SSeconomy.settings.skim_rate
	TEST_ASSERT_NULL(skimmer.siphon(2, drop.account_id, rate, thief), "Первый скиммер в лимите")
	var/obj/item/card/id/again = allocate(/obj/item/card/id)
	again.registered_account = victims[3]
	TEST_ASSERT(second.skim_card(again, thief), "Второй скиммер скопировал тот же счёт")
	TEST_ASSERT_EQUAL(second.siphon(1, drop.account_id, 1, thief), "Не больше [rate] кр. в минуту с одного счёта: сейчас можно ещё 0 кр.", "Второй скиммер упирается в тот же лимит счёта")
	TEST_ASSERT_EQUAL(drop.account_balance, rate, "Мимо лимита ничего не ушло")
	var/mob/living/carbon/human/bare = allocate(/mob/living/carbon/human, get_step(thief, EAST))
	thief.put_in_active_hand(skimmer)
	skimmer.melee_attack_chain(thief, bare)
	TEST_ASSERT(!LAZYFIND(thief.do_afters, bare), "Без карты считывание не начинается")

/datum/unit_test/economy_skimmer/holders
	var/attackby_hits = 0

/datum/unit_test/economy_skimmer/holders/proc/on_attackby(datum/source, obj/item/weapon, mob/user, params)
	SIGNAL_HANDLER
	attackby_hits++

/// Клик скиммером по чужому КПК и бумажнику копирует счёт сразу и гасит клик; отказ на своём бумажнике клик не гасит.
/datum/unit_test/economy_skimmer/holders/Run()
	var/mob/living/carbon/human/thief = allocate(/mob/living/carbon/human)
	econ_test_traitor(thief)
	var/obj/item/card_skimmer/skimmer = allocate(/obj/item/card_skimmer)
	thief.put_in_active_hand(skimmer)
	var/turf/near = get_step(thief, EAST)
	var/datum/bank_account/pda_account = make_account("econ_test_pda_owner")
	var/obj/item/card/id/pda_card = allocate(/obj/item/card/id)
	pda_card.registered_account = pda_account
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda, near)
	pda.InsertID(pda_card)
	skimmer.melee_attack_chain(thief, pda)
	var/datum/weakref/first = length(skimmer.stolen) ? skimmer.stolen[1] : null
	TEST_ASSERT(first?.resolve() == pda_account, "Счёт карты в КПК скопирован")
	var/datum/bank_account/wallet_account = make_account("econ_test_wallet_owner")
	var/obj/item/card/id/wallet_card = allocate(/obj/item/card/id)
	wallet_card.registered_account = wallet_account
	var/obj/item/storage/wallet/wallet = allocate(/obj/item/storage/wallet, near)
	wallet_card.forceMove(wallet)
	TEST_ASSERT(wallet.GetID() == wallet_card, "Карта в бумажнике")
	RegisterSignal(wallet, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	skimmer.melee_attack_chain(thief, wallet)
	var/datum/weakref/second = length(skimmer.stolen) > 1 ? skimmer.stolen[2] : null
	TEST_ASSERT(second?.resolve() == wallet_account, "Счёт карты в бумажнике скопирован")
	TEST_ASSERT_EQUAL(attackby_hits, 0, "Удачное копирование гасит клик")
	TEST_ASSERT(thief.is_holding(skimmer), "Скиммер остался в руке")
	var/datum/bank_account/own = make_account("econ_test_thief")
	thief.account_id = own.account_id
	var/obj/item/card/id/own_card = allocate(/obj/item/card/id)
	own_card.registered_account = own
	var/obj/item/storage/wallet/own_wallet = allocate(/obj/item/storage/wallet, near)
	own_card.forceMove(own_wallet)
	RegisterSignal(own_wallet, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	skimmer.melee_attack_chain(thief, own_wallet)
	TEST_ASSERT_EQUAL(length(skimmer.stolen), 2, "Свой счёт не скопирован")
	TEST_ASSERT_EQUAL(attackby_hits, 1, "Отказ на своём бумажнике пропускает клик дальше")
	UnregisterSignal(wallet, COMSIG_PARENT_ATTACKBY)
	UnregisterSignal(own_wallet, COMSIG_PARENT_ATTACKBY)

/// Существо на руках считывается тем же do_after, что и человек, а не мгновенно.
/datum/unit_test/economy_skimmer/micro_holder/Run()
	var/mob/living/carbon/human/thief = allocate(/mob/living/carbon/human)
	econ_test_traitor(thief)
	var/obj/item/card_skimmer/skimmer = allocate(/obj/item/card_skimmer)
	thief.put_in_active_hand(skimmer)
	var/datum/bank_account/micro_account = make_account("econ_test_micro")
	var/mob/living/carbon/human/micro = make_victim(micro_account, get_step(thief, EAST))
	var/obj/item/clothing/head/mob_holder/micro/holder = allocate(/obj/item/clothing/head/mob_holder/micro, get_turf(micro), micro)
	thief.put_in_inactive_hand(holder)
	TEST_ASSERT(holder.GetID(), "Карта существа видна через переноску")
	skimmer.melee_attack_chain(thief, holder)
	TEST_ASSERT(LAZYFIND(thief.do_afters, holder), "Считывание идёт через do_after")
	TEST_ASSERT_EQUAL(length(skimmer.stolen), 0, "Не мгновенно")
	var/list/budget = new_wait_budget(10 SECONDS, "скиммер считывает существо на руках")
	while(LAZYFIND(thief.do_afters, holder))
		if(!wait_budget_tick(budget))
			break
	var/datum/weakref/copied = length(skimmer.stolen) ? skimmer.stolen[1] : null
	TEST_ASSERT(copied?.resolve() == micro_account, "Счёт существа скопирован после do_after")

/// skim_rate выше transfer_max в конфиге - ошибка и встроенное значение.
/datum/unit_test/economy_skimmer/rate_config/Run()
	var/path = "data/unit_test_economy_skim.json"
	fdel(path)
	text2file("{\"settings\": {\"transfer_max\": 1000, \"skim_rate\": 2000}}", path)
	var/datum/economy_settings/settings = allocate(/datum/economy_settings)
	var/list/errors = settings.load(path)
	fdel(path)
	TEST_ASSERT_EQUAL(length(errors), 1, "Ошибка конфига: [jointext(errors, "; ")]")
	TEST_ASSERT_EQUAL(settings.transfer_max, 1000, "transfer_max принят")
	TEST_ASSERT_EQUAL(settings.skim_rate, initial(settings.skim_rate), "skim_rate вернулся к встроенному")

/// Анонимный счёт: не в отделе, без зарплаты, снятие наличных уводит деньги в оборот наличных и помечается зоной с любого пути, замороженный не обналичить.
/datum/unit_test/economy_skimmer/anon_cashout/Run()
	var/mob/living/carbon/human/thief = allocate(/mob/living/carbon/human)
	var/obj/item/anon_account_card/anon = allocate(/obj/item/anon_account_card)
	var/datum/bank_account/account = anon.account
	allocated += account
	TEST_ASSERT(istype(account, /datum/bank_account/anonymous), "Свой тип счёта")
	TEST_ASSERT(isnull(account.department_id) && account.offstation, "Без отдела и вне экипажа")
	TEST_ASSERT(SSeconomy.is_personal_account(account), "Принимает переводы как личный счёт")
	econ_test_set_balance(account, 500)
	TEST_ASSERT_EQUAL(account.payday(), 0, "Зарплаты нет")
	TEST_ASSERT_EQUAL(account.account_balance, 500, "Гарантированного минимума нет")
	var/cash_before = SSeconomy.cash_account.account_balance
	var/obj/item/holochip/chip = anon.cash_out(200, thief)
	TEST_ASSERT_NOTNULL(chip, "Голочип выдан")
	allocated += chip
	TEST_ASSERT_EQUAL(chip.credits, 200, "Сумма")
	TEST_ASSERT_EQUAL(account.account_balance, 300, "Списано со счёта")
	TEST_ASSERT_EQUAL(SSeconomy.cash_account.account_balance - cash_before, 200, "Ушло в наличные, а не напечатано")
	var/area_name = get_area_name(thief)
	var/found = FALSE
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.flags_for(account))
		if(flag.kind == AUDIT_FLAG_ANON_CASHOUT && findtext(flag.text, area_name) && flag.amount == 200 && isnull(flag.counterparty_number))
			found = TRUE
	TEST_ASSERT(found, "Место снятия в аудите")
	TEST_ASSERT(SSeconomy.move(account, SSeconomy.cash_account, 50, ECON_CASH_OUT, thief), "Снятие через привязанную ID-карту")
	TEST_ASSERT_EQUAL(flag_count(AUDIT_FLAG_ANON_CASHOUT, account), 1, "Тот же случай пополнен")
	var/datum/econ_audit_flag/case = SSeconomy.flags_for(account)[1]
	TEST_ASSERT_EQUAL(case.amount, 250, "Снятие мимо карты счёта тоже в деле")
	account.state = ACCOUNT_FROZEN
	TEST_ASSERT_NULL(anon.cash_out(100, thief), "Замороженный счёт не обналичить")
	TEST_ASSERT_EQUAL(account.account_balance, 250, "Заморозка удержала деньги")

/// Описания в аплинке берут числа из настроек; предметы только у предателей.
/datum/unit_test/economy_skimmer/uplink_text/Run()
	var/datum/uplink_item/stealthy_tools/card_skimmer/skimmer_item = allocate(/datum/uplink_item/stealthy_tools/card_skimmer)
	var/datum/uplink_item/stealthy_tools/anon_account/anon_item = allocate(/datum/uplink_item/stealthy_tools/anon_account)
	TEST_ASSERT(findtext(skimmer_item.desc, "[SSeconomy.settings.skim_rate] кр."), "Лимит в описании аплинка")
	TEST_ASSERT(findtext(skimmer_item.desc, "[SSeconomy.settings.skimmer_slots] счет"), "Слоты в описании аплинка")
	TEST_ASSERT_EQUAL(skimmer_item.purchasable_from, UPLINK_TRAITORS, "Скиммер только у предателей")
	TEST_ASSERT_EQUAL(anon_item.purchasable_from, UPLINK_TRAITORS, "Анонимный счёт только у предателей")
	TEST_ASSERT_EQUAL(skimmer_item.item, /obj/item/card_skimmer, "Скиммер в аплинке")
	TEST_ASSERT_EQUAL(anon_item.item, /obj/item/anon_account_card, "Карта счёта в аплинке")

/// Скиммер и карта анонимного счёта создаются и удаляются чисто; счёт переживает карту и отпускает её.
/datum/unit_test/economy_skimmer/create_and_destroy/Run()
	var/obj/item/card_skimmer/skimmer = new(run_loc_floor_bottom_left)
	var/datum/bank_account/victim = make_account("econ_test_victim")
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = victim
	TEST_ASSERT(skimmer.skim_card(card, null), "Скопировано")
	qdel(skimmer)
	TEST_ASSERT(QDELETED(skimmer), "Скиммер удалён")
	var/obj/item/anon_account_card/anon = new(run_loc_floor_bottom_left)
	var/datum/bank_account/account = anon.account
	allocated += account
	TEST_ASSERT(anon in account.bank_cards, "Карта получает сообщения счёта")
	qdel(anon)
	TEST_ASSERT(!(anon in account.bank_cards), "Счёт отпустил карту")
	TEST_ASSERT(!QDELETED(account) && SSeconomy.find_account(account.account_id) == account, "Счёт остаётся в банке после потери карты")
