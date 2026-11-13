/datum/unit_test/economy_farm_caps
	abstract_type = /datum/unit_test/economy_farm_caps
	var/list/stashed_contracts
	var/list/saved_balances = list()
	/// Перехваченные COMSIG_ECONOMY_MOVED: list(source, target, amount, reason, actor)
	var/list/moves = list()

/datum/unit_test/economy_farm_caps/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		saved_balances[id] = department.account.account_balance
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_moved))

/datum/unit_test/economy_farm_caps/Destroy()
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	econ_test_restore_contracts(stashed_contracts)
	for(var/id in saved_balances)
		var/datum/economy_department/department = SSeconomy.departments[id]
		econ_test_set_balance(department.account, saved_balances[id])
	return ..()

/datum/unit_test/economy_farm_caps/proc/on_moved(datum/source, datum/bank_account/from, datum/bank_account/target, amount, reason, mob/actor)
	SIGNAL_HANDLER
	moves += list(list(from, target, amount, reason, actor))

/datum/unit_test/economy_farm_caps/proc/make_staff(department_id, list/access)
	var/mob/living/carbon/human/staff = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new("econ_farm_[department_id]")
	account.department_id = department_id
	account.pay_grade = PAY_GRADE_EASY
	staff.account_id = account.account_id
	allocated += account
	if(access)
		var/obj/item/card/id/card = allocate(/obj/item/card/id)
		card.access = access
		staff.put_in_hands(card)
	return staff

/// Проблемный компьютер снабжения платит бюджету по прайсу работ с исполнителем, а не тысячи кредитов без автора; ошибка денег не списывает.
/datum/unit_test/economy_farm_caps/problem_computer/Run()
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	econ_test_set_balance(cargo, 1000)
	var/obj/item/computermath/cargo/computer = allocate(/obj/item/computermath/cargo)
	var/mob/living/carbon/human/solver = allocate(/mob/living/carbon/human)
	var/price = SSeconomy.settings.work_prices[WORK_CARGO_PAPERWORK]
	TEST_ASSERT(price > 0, "У расчётов есть цена в прайсе работ")
	moves.Cut()
	computer.handle_reward(solver, "Cargo", TRUE, "Hard")
	TEST_ASSERT_EQUAL(cargo.account_balance, 1000 + price * 5, "Сложная задача стоит пять цен работы")
	TEST_ASSERT_EQUAL(computer.last_points, price * 5, "Экран показывает начисленные кредиты")
	var/list/move = moves[1]
	TEST_ASSERT_EQUAL(move[4], ECON_WORK, "Начисление идёт как оплата работы")
	TEST_ASSERT_EQUAL(move[5], solver, "У начисления есть исполнитель")
	var/before = cargo.account_balance
	computer.handle_reward(solver, "Cargo", FALSE, "Hard")
	TEST_ASSERT_EQUAL(cargo.account_balance, before, "Ошибка не списывает деньги снабжения")
	TEST_ASSERT_EQUAL(computer.last_points, 0, "За ошибку ноль кредитов")
	TEST_ASSERT(findtext(jointext(computer.examine(solver), "\n"), "[price * 5] кр."), "Осмотр называет оплату сложной задачи")

/// После конца раунда проблемный компьютер не обещает «начислено 0 кр.», а говорит, что смена закончена.
/datum/unit_test/economy_farm_caps/problem_computer_round_over/Run()
	var/obj/item/computermath/cargo/computer = allocate(/obj/item/computermath/cargo)
	var/mob/living/carbon/human/solver = allocate(/mob/living/carbon/human)
	var/previous_state = SSticker.current_state
	SSticker.current_state = GAME_STATE_FINISHED
	computer.handle_reward(solver, "Cargo", TRUE, "Hard")
	SSticker.current_state = previous_state
	TEST_ASSERT_EQUAL(computer.last_points, 0, "После конца раунда расчёт оплачен")
	TEST_ASSERT(!findtext(computer.last_message, "начислено") && findtext(computer.last_message, "смена закончена"), "Экран после конца раунда: [computer.last_message]")

/// Сделка с работорговцами платит снабжению один раз за раунд, сколько бы спавнеров ни сработало.
/datum/unit_test/economy_farm_caps/slavers_deal_once/Run()
	var/saved_flag = GLOB.slavers_deal_paid
	GLOB.slavers_deal_paid = FALSE
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	econ_test_set_balance(cargo, 0)
	var/first = slavers_pay_deal()
	var/second = slavers_pay_deal()
	var/balance = cargo.account_balance
	GLOB.slavers_deal_paid = saved_flag
	TEST_ASSERT(first, "Первая сделка оплачена")
	TEST_ASSERT(!second, "Вторая сделка не оплачивается")
	TEST_ASSERT_EQUAL(balance, SLAVERS_DEAL_PAYMENT, "Снабжение получило деньги на выкуп один раз")

/// Премии одному человеку от других глав и премии себе ограничены за час раздельно; через час лимит обновляется.
/datum/unit_test/economy_farm_caps/bonus_hourly_cap/Run()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/mob/living/carbon/human/engineer = make_staff(ACCOUNT_ENG)
	var/datum/bank_account/own = econ_account_of(chief)
	var/datum/bank_account/member = econ_account_of(engineer)
	econ_test_set_balance(engineering.account, settings.bonus_cap_hour * 3)
	TEST_ASSERT(settings.bonus_self_cap_hour < settings.bonus_cap_hour, "Лимит премий себе меньше общего")
	TEST_ASSERT(!engineering.pay_bonus(own, settings.bonus_self_cap_hour + 1, chief), "Себе больше лимита не выписать")
	TEST_ASSERT(engineering.pay_bonus(own, settings.bonus_self_cap_hour, chief), "Себе в пределах лимита")
	TEST_ASSERT(!engineering.pay_bonus(own, 1, chief), "Лимит себе исчерпан")
	TEST_ASSERT_EQUAL(own.bonus_left(), settings.bonus_cap_hour, "Премия себе не тратит лимит премий от других")
	TEST_ASSERT(engineering.pay_bonus(member, settings.bonus_cap_hour, chief), "Сотруднику в пределах лимита")
	TEST_ASSERT(!engineering.pay_bonus(member, 1, chief), "Лимит сотрудника исчерпан")
	TEST_ASSERT_EQUAL(member.bonus_left(), 0, "Остаток лимита сотрудника нулевой")
	member.bonus_window_start -= 1 HOURS
	TEST_ASSERT_EQUAL(member.bonus_left(), settings.bonus_cap_hour, "Через час лимит обновился")
	TEST_ASSERT(engineering.pay_bonus(member, 1, chief), "После часа премия снова проходит")

/// Бюджет Deep Space получает с майнеров больше станционного потолка, станционный счёт упирается в обычный.
/datum/unit_test/economy_farm_caps/crypto_offstation_cap/Run()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/bank_account/deep_space = SSeconomy.get_dep_account(ACCOUNT_DS)
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	TEST_ASSERT_NOTNULL(deep_space, "Есть бюджет Deep Space")
	TEST_ASSERT(settings.crypto_cap_offstation_per_tick > settings.crypto_cap_per_tick, "Потолок Deep Space выше станционного")
	var/saved_fire_count = SSeconomy.fire_count
	SSeconomy.fire_count += 1000
	var/ds_paid = SSeconomy.crypto_allowance(deep_space, settings.crypto_cap_offstation_per_tick * 2)
	var/cargo_paid = SSeconomy.crypto_allowance(cargo, settings.crypto_cap_offstation_per_tick * 2)
	SSeconomy.fire_count = saved_fire_count
	SSeconomy.crypto_paid = list()
	TEST_ASSERT_EQUAL(ds_paid, settings.crypto_cap_offstation_per_tick, "Deep Space упирается в свой потолок")
	TEST_ASSERT_EQUAL(cargo_paid, settings.crypto_cap_per_tick, "Снабжение упирается в станционный потолок")

/// Автомат с карты получает от NT стартовый банк один раз, с первой ставкой; собранный на смене - нет.
/datum/unit_test/economy_farm_caps/slot_bank_seed/Run()
	var/seed = SSeconomy.settings.slot_bank_seed
	TEST_ASSERT(seed > 0, "Стартовый банк задан")
	var/saved_cash = SSeconomy.cash_account.account_balance
	var/saved_jackpot = SSmarket.slot_jackpot
	var/obj/machinery/computer/slot_machine/built = allocate(/obj/machinery/computer/slot_machine)
	TEST_ASSERT(!built.bank_seed_due, "Собранный на смене автомат не ждёт стартового банка")
	var/obj/machinery/computer/slot_machine/mapped = allocate(/obj/machinery/computer/slot_machine)
	mapped.bank_seed_due = TRUE
	var/minted = SSeconomy.ledger.minted
	mapped.take_bet(100)
	var/first_bank = mapped.prize_bank
	var/first_minted = SSeconomy.ledger.minted - minted
	mapped.take_bet(100)
	var/second_minted = SSeconomy.ledger.minted - minted
	var/share = 100 - SSeconomy.settings.slot_house_edge - SSeconomy.settings.slot_jackpot_share
	mapped.prize_bank = 0
	SSmarket.slot_jackpot = saved_jackpot
	econ_test_set_balance(SSeconomy.cash_account, saved_cash)
	TEST_ASSERT_EQUAL(round(first_bank), seed + share, "Банк после первой ставки - стартовый плюс доля ставки")
	TEST_ASSERT_EQUAL(first_minted, seed, "NT выпустил ровно стартовый банк")
	TEST_ASSERT_EQUAL(second_minted, seed, "Вторая ставка банк не пополняет")
