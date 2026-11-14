#define SIM_HOURS 3
#define SIM_SEEDS 3
/// Траты экипажа в автоматах, кр. на человека в час: медиана econ.log прода, 189 раундов 10.2026
#define SIM_VEND_PER_CREW_HOUR 45
/// Доля чистого личного дохода, которую экипаж тратит на себя, проценты: (автоматы + частные заказы) / зарплата на проде, 27 раундов с выплатами в econ.log, среднее 28%, медиана 30%
#define SIM_SPEND_SHARE 28
/// Заказов отделов на всю станцию в час: прод 10.2026-11.2026
#define SIM_STATION_ORDERS_PER_HOUR 2.9
/// Средний заказ отдела, кр.: 19.6k кр./ч на 2.9 заказа/ч, медианы прода 10.2026-11.2026
#define SIM_ORDER_VALUE 6800
#define SIM_RESERVE_PAYDAYS 2
/// Глава копит на пак не дороже стольких средних заказов
#define SIM_GOAL_MAX_ORDERS 3
/// Экипаж медианного раунда; составы p25 и p75 - варианты для отчёта
#define SIM_ROSTER_MEDIAN 44
/// Причины, которыми деньги появляются в прогоне
#define SIM_EMISSION_REASONS list(ECON_GRANT, ECON_WORK, ECON_WORK_PREMIUM, ECON_CONTRACT, ECON_WAGE_FLOOR, ECON_EVENT, ECON_GAMBLING_WIN, ECON_DIVIDEND)
#define SIM_VEND_ATTEMPTS_MAX 50
#define SIM_SLOT_BET 25
/// Лотерея открывается через час прогона: событие с earliest_start 15 мин., к часу у экипажа накоплен бюджет
#define SIM_LOTTERY_TICK 12
#define SIM_SLOT_DEPOSIT_MIN 100
#define SIM_SLOT_DEPOSIT_MAX 1000
/// Минимум кредитов на счёте-якоре, чтобы прогон проверял пропорции, а не выход за ноль
#define SIM_MIN_MONEY 1
/// Запас потолка роста личных денег над моделью трат
#define SIM_CREW_GROWTH_MARGIN 1.1

/// Страж инвариантов экономики на трёх составах экипажа прода (37, 44, 80) и трёх сидах по 3 ч: деньги не создаются мимо известных причин и сходятся, отделы не должны зарплат, пассивная исправность инженерии не больше работы медицины, бюджеты держит потолок (сверх порога - только следующая зарплата, цель накопления, защищённые поступления и тик дохода), медиана личных денег под потолком модели трат, состояние NORMAL.
/// Доли стоков, закупки отделов и медицины только пишутся таблицей в лог: числа баланса калибруются на живом сервере.
/datum/unit_test/economy_simulation
	priority = TEST_LONGER
	var/world_ready = FALSE
	var/list/crew
	/// id отдела -> мобы-исполнители работы
	var/list/performers
	var/list/machines
	/// Автоматы с премиальными позициями для удовольствия, без медицины
	var/list/premium_machines
	var/obj/machinery/computer/slot_machine/slots
	var/mob/living/carbon/human/buyer
	var/obj/item/card/id/buyer_card
	var/list/saved_accounts
	var/list/saved_budgets
	var/list/saved_owed
	var/list/saved_work_logs
	var/list/saved_work_remainders
	var/list/saved_market
	var/list/saved_contracts
	var/list/saved_snapshots
	var/list/saved_ledger
	var/list/saved_by_reason
	var/list/saved_department_flows
	/// id отдела -> list("kept", "paid_out", "burned", "returned") для доли стоков отделов
	var/list/department_flows
	/// Причина -> сколько денег появилось ею за прогон
	var/list/minted_by_reason
	var/list/orders_before
	var/datum/econ_lottery/saved_lottery
	var/saved_contracts_started
	var/saved_fire_count
	var/saved_state
	var/saved_tax
	var/saved_centcom_message
	var/economy_could_fire
	var/market_could_fire
	/// "отдел|причина" -> сумма поступлений бюджету за симуляцию
	var/list/flows
	/// id отдела -> все поступления бюджету за симуляцию
	var/list/inflow
	/// Счёт экипажа -> кредиты, которые он готов потратить на себя
	var/list/spend_budget
	/// Причина -> сколько экипаж сжёг через неё
	var/list/crew_burns

/// Отделы, главы которых копят на крупную покупку (половина отделов с каталогом).
/datum/unit_test/economy_simulation/proc/goal_departments()
	return list(ACCOUNT_ENG, ACCOUNT_MED, ACCOUNT_SCI)

/// Экипаж медианного раунда и p25, p75 по уникальным заходам манифестов прода (37, 59, 80) с той же поправкой на долю смены.
/datum/unit_test/economy_simulation/proc/roster_sizes()
	return list(SIM_ROSTER_MEDIAN, 37, 80)

/// Доли личного бюджета сверх обычных автоматов, проценты: допущение, данных прода о новых тратах нет.
/datum/unit_test/economy_simulation/proc/spend_split()
	return list("premium" = 20, "catalog" = 40, "slots" = 25, "lottery" = 15)

/datum/unit_test/economy_simulation/Run()
	var/list/departments = list(ACCOUNT_CMD, ACCOUNT_SEC, ACCOUNT_ENG, ACCOUNT_MED, ACCOUNT_SCI, ACCOUNT_CAR, ACCOUNT_SRV, ACCOUNT_CIV)
	var/list/all_results = list()
	var/list/report = list("Синтетический раунд: [SIM_HOURS] ч, сиды 1..[SIM_SEEDS]. Отделы: доля стоков (без возврата излишка / без казны / без обоих); закупки по отделам; закупки медицины по часам")
	setup_world()
	for(var/size in roster_sizes())
		for(var/seed in 1 to SIM_SEEDS)
			var/list/result = simulate(departments, seed, size)
			result["size"] = size
			all_results += list(result)
			report += report_lines(result, departments, seed, size)
	log_test(jointext(report, "\n"))
	for(var/list/result as anything in all_results)
		var/problem = check_result(result, departments)
		TEST_ASSERT(!problem, "Экипаж [result["size"]], сид [result["seed"]]: [problem]")

/datum/unit_test/economy_simulation/proc/report_lines(list/result, list/departments, seed, size)
	. = list()
	var/list/purchases = list()
	for(var/id in departments)
		purchases += "[id] [result["bought"][id]]"
	. += "экипаж [size], сид [seed]: эмиссия [result["minted"]], стоки [result["burned"]] ([round(result["ratio"] * 100)]%); отделы [round(result["department_ratio"] * 100)]% ([round(result["department_ratio_no_return"] * 100)] / [round(result["department_ratio_no_cmd"] * 100)] / [round(result["department_ratio_bare"] * 100)]); закупки [jointext(purchases, ", ")]; медицина по часам [jointext(result["med_hourly"], "/")] на [result["med_spent"]] кр.; цели куплены: [jointext(result["goals_bought"], ", ")]; исправность ENG [result["eng_integrity"]] при работе MED [result["med_work"]]; экипаж x[round(result["crew_growth"], 0.01)]; состояние [jointext(result["states"], ", ")]"
	var/list/line = list()
	for(var/id in departments)
		line += "[id] [result["start"][id]] -> [result["end"][id]] (порог [result["threshold"][id]])"
	. += "  [jointext(line, "; ")]"
	. += "  [result["sources"]]"

/// Текст первого нарушенного инварианта или null.
/datum/unit_test/economy_simulation/proc/check_result(list/result, list/departments)
	var/list/unknown = result["minted_by_reason"] - SIM_EMISSION_REASONS
	if(length(unknown))
		return "эмиссия мимо известных причин: [jointext(unknown, ", ")]"
	var/minted_sum = 0
	for(var/reason in result["minted_by_reason"])
		minted_sum += result["minted_by_reason"][reason]
	if(minted_sum != result["minted"])
		return "журнал насчитал эмиссии [result["minted"]], по причинам [minted_sum]"
	if(result["money_delta"] != result["minted"] - result["burned"])
		return "деньги не сходятся: на счетах прибавилось [result["money_delta"]], эмиссия минус стоки [result["minted"] - result["burned"]]"
	for(var/id in departments)
		if(result["owed"][id])
			return "отдел [id] задолжал зарплату [result["owed"][id]]"
	for(var/id in departments)
		var/limit = result["threshold"][id] + result["payroll"][id] + result["protected"][id] + result["tick_income"][id]
		if(result["end"][id] > limit)
			return "бюджет [id] [result["end"][id]] выше порога [result["threshold"][id]], следующей зарплаты [result["payroll"][id]] и защищённого (цель и разовые поступления) [result["protected"][id]] больше чем на тик поступлений [result["tick_income"][id]]"
	if(result["eng_integrity"] > result["med_work"])
		return "пассивная исправность инженерии [result["eng_integrity"]] больше работы медицины [result["med_work"]]"
	if(result["crew_growth"] > crew_growth_ceiling())
		return "медиана личных денег выросла в [round(result["crew_growth"], 0.01)] раза, потолок [round(crew_growth_ceiling(), 0.01)]"
	for(var/state in result["states"])
		if(state != ECON_STATE_NORMAL)
			return "состояние экономики [jointext(result["states"], ", ")], нужно [ECON_STATE_NORMAL]"
	return null

/// Потолок выведен из той же модели трат (SIM_SPEND_SHARE% чистой зарплаты), что и траты прогона: подъёмные плюс зарплаты за вычетом налога и трат, с запасом 10%. Он ловит поломку стоков, а не проверяет модель.
/datum/unit_test/economy_simulation/proc/crew_growth_ceiling()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/paydays = SIM_HOURS * round(1 HOURS / SSeconomy.wait) / settings.payroll_interval_ticks
	var/kept = paydays * (100 - settings.tax_default) / 100 * (100 - SIM_SPEND_SHARE) / 100
	return (settings.starting_paychecks + kept) / settings.starting_paychecks * SIM_CREW_GROWTH_MARGIN

/datum/unit_test/economy_simulation/Destroy()
	if(world_ready)
		teardown_world()
	return ..()

/datum/unit_test/economy_simulation/proc/setup_world()
	economy_could_fire = SSeconomy.can_fire
	market_could_fire = SSmarket.can_fire
	SSeconomy.can_fire = FALSE
	SSmarket.can_fire = FALSE
	saved_fire_count = SSeconomy.fire_count
	saved_state = SSeconomy.economy_state
	saved_tax = SSeconomy.tax_rate
	saved_contracts_started = SSeconomy.contracts_started
	saved_snapshots = SSeconomy.ledger.snapshots.Copy()
	saved_ledger = list()
	for(var/var_name in list("minted", "burned", "last_minted", "last_burned", "department_minted", "department_burned", "department_paid_out", "department_received"))
		saved_ledger[var_name] = SSeconomy.ledger.vars[var_name]
	saved_by_reason = SSeconomy.ledger.by_reason.Copy()
	saved_department_flows = econ_test_copy_flows()
	saved_lottery = SSeconomy.lottery
	SSeconomy.lottery = null
	saved_centcom_message = SSshuttle.centcom_message
	SSeconomy.tax_rate = min(SSeconomy.settings.tax_default, SSeconomy.settings.tax_max)
	saved_accounts = SSeconomy.bank_accounts
	saved_budgets = list()
	saved_owed = list()
	saved_work_logs = list()
	saved_work_remainders = list()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		saved_budgets[id] = department.account.account_balance
		saved_owed[id] = department.owed
		saved_work_logs[id] = department.work_log.Copy()
		saved_work_remainders[id] = department.work_remainder.Copy()
	saved_contracts = econ_test_stash_contracts()
	orders_before = SSshuttle.shoppinglist.Copy()
	world_ready = TRUE
	machines = list()
	var/list/machine_shares = list(
		/obj/machinery/vending/medical = 21,
		/obj/machinery/vending/security = 17,
		/obj/machinery/vending/tool = 15,
		/obj/machinery/vending/cigarette = 24,
		/obj/machinery/vending/snack = 23,
	)
	premium_machines = list()
	for(var/machine_type in machine_shares)
		var/obj/machinery/vending/machine = allocate(machine_type)
		machines[machine] = machine_shares[machine_type]
		if(istype(machine, /obj/machinery/vending/cigarette) || istype(machine, /obj/machinery/vending/snack))
			premium_machines += machine
	slots = allocate(/obj/machinery/computer/slot_machine)
	buyer = allocate(/mob/living/carbon/human)
	buyer_card = allocate(/obj/item/card/id)
	buyer.put_in_active_hand(buyer_card)

/datum/unit_test/economy_simulation/proc/teardown_world()
	world_ready = FALSE
	if(crew)
		fire_crew()
	if(saved_market)
		econ_test_restore_market(saved_market)
		saved_market = null
	if(buyer_card)
		buyer_card.registered_account = null
	for(var/order in SSshuttle.shoppinglist - orders_before)
		SSshuttle.shoppinglist -= order
		qdel(order)
	QDEL_NULL(SSeconomy.lottery)
	SSeconomy.lottery = saved_lottery
	econ_test_restore_contracts(saved_contracts)
	SSeconomy.bank_accounts = saved_accounts
	for(var/id in saved_budgets)
		var/datum/economy_department/department = SSeconomy.departments[id]
		econ_test_set_balance(department.account, saved_budgets[id])
		department.owed = saved_owed[id]
		department.work_log = saved_work_logs[id]
		department.work_remainder = saved_work_remainders[id]
		department.shield = list()
		department.clear_saving_goal(ordered = TRUE)
		department.saving_goal_cooldown_until = 0
	SSeconomy.ledger.snapshots = saved_snapshots
	for(var/var_name in saved_ledger)
		SSeconomy.ledger.vars[var_name] = saved_ledger[var_name]
	SSeconomy.ledger.by_reason = saved_by_reason
	SSeconomy.ledger.department_flows = saved_department_flows
	SSeconomy.contracts_started = saved_contracts_started
	SSeconomy.fire_count = saved_fire_count
	SSeconomy.economy_state = saved_state
	SSeconomy.tax_rate = saved_tax
	SSshuttle.centcom_message = saved_centcom_message
	SSeconomy.can_fire = economy_could_fire
	SSmarket.can_fire = market_could_fire

/// Экипаж по составу манифестов прода (200 раундов 10.2026-11.2026, без силиконов): заходов на должность за раунд x0.75 - доля времени смены, ассистенты - средневзвешенное по времени; по главе на отдел. Счёт, должность и подъёмные - как в /datum/job/equip().
/datum/unit_test/economy_simulation/proc/hire_crew(size = SIM_ROSTER_MEDIAN)
	var/static/list/heads = list(/datum/job/captain, /datum/job/hop, /datum/job/hos, /datum/job/chief_engineer, /datum/job/cmo, /datum/job/rd, /datum/job/qm)
	var/list/roster = list(
		/datum/job/captain = 1, /datum/job/hop = 1, /datum/job/hos = 1, /datum/job/chief_engineer = 1, /datum/job/cmo = 1, /datum/job/rd = 1, /datum/job/qm = 1,
		/datum/job/officer = 3, /datum/job/peacekeeper = 1, /datum/job/brigdoc = 1, /datum/job/bridgeofficer = 1,
		/datum/job/engineer = 2,
		/datum/job/doctor = 3, /datum/job/chemist = 1, /datum/job/paramedic = 1, /datum/job/geneticist = 1,
		/datum/job/scientist = 3, /datum/job/expeditor = 2, /datum/job/roboticist = 1,
		/datum/job/cargo_tech = 1, /datum/job/mining = 2,
		/datum/job/entertainer = 2, /datum/job/bartender = 1, /datum/job/cook = 1, /datum/job/hydro = 1, /datum/job/janitor = 1,
		/datum/job/assistant = 8,
	)
	SSeconomy.bank_accounts = list()
	crew = list()
	performers = list()
	spend_budget = list()
	var/scale = (size - length(heads)) / (SIM_ROSTER_MEDIAN - length(heads))
	for(var/job_type in roster)
		var/datum/job/job = SSjob.GetJobType(job_type)
		var/count = (job_type in heads) ? roster[job_type] : max(round(roster[job_type] * scale + 0.5), 1)
		for(var/i in 1 to count)
			var/datum/bank_account/member = new("econ_sim_[length(crew) + 1]", job)
			member.set_job(job)
			member.credit(member.wage_amount() * SSeconomy.settings.starting_paychecks, ECON_STARTING_FUNDS)
			crew += member
			spend_budget[member] = list()
			if(!(member.department_id in list(ACCOUNT_MED, ACCOUNT_SRV, ACCOUNT_SCI, ACCOUNT_CAR)))
				continue
			var/mob/living/carbon/human/worker = allocate(/mob/living/carbon/human)
			worker.account_id = member.account_id
			LAZYADD(performers[member.department_id], worker)

/datum/unit_test/economy_simulation/proc/fire_crew()
	if(buyer_card)
		buyer_card.registered_account = null
	for(var/mob/living/carbon/human/worker as anything in performers_flat())
		worker.account_id = null
		qdel(worker)
	spend_budget = null
	QDEL_LIST(crew)
	crew = null
	performers = null

/datum/unit_test/economy_simulation/proc/performers_flat()
	. = list()
	for(var/id in performers)
		. += performers[id]

/// Работа отдела за час по замерам прода: id -> list(list(тип работы, записей в час, объём записи)).
/datum/unit_test/economy_simulation/proc/work_plan()
	return list(
		ACCOUNT_MED = list(
			list(WORK_MED_DISCHARGE_LIGHT, 2, 1),
			list(WORK_MED_DISCHARGE_HEAVY, 3, 1),
			list(WORK_MED_DISCHARGE_CRIT, 1, 1),
			list(WORK_MED_SURGERY, 6, 1),
			list(WORK_MED_REVIVE, 2, 1),
		),
		ACCOUNT_SRV = list(
			list(WORK_SRV_DISH, 8, 3),
			list(WORK_SRV_DRINK, 12, 1),
			list(WORK_SRV_CLEANING, 20, 1),
		),
		ACCOUNT_SCI = list(
			list(WORK_SCI_NODE, 48, 6),
		),
		ACCOUNT_CAR = list(
			list(WORK_MINING_ORE, 12, 100 * econ_sale_factor(COMMODITY_METALS)),
		),
	)

/datum/unit_test/economy_simulation/proc/simulate(list/departments, seed, size)
	rand_seed(seed)
	saved_market = econ_test_swap_market()
	for(var/id in departments)
		var/datum/economy_department/department = SSeconomy.get_department(id)
		econ_test_set_balance(department.account, department.start_budget())
		department.owed = 0
		department.work_remainder = list()
		department.shield = list()
		department.clear_saving_goal(ordered = TRUE)
		department.saving_goal_cooldown_until = 0
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts())
		qdel(contract)
	SSeconomy.fire_count = 0
	SSeconomy.contracts_started = TRUE
	hire_crew(size)
	department_flows = list()
	minted_by_reason = list()
	for(var/id in departments)
		department_flows[id] = list("kept" = 0, "paid_out" = 0, "burned" = 0, "returned" = 0)
	flows = list()
	inflow = list()
	crew_burns = list()
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(note_move))
	var/list/catalog_packs = list()
	for(var/id in departments)
		catalog_packs[id] = sorted_catalog(SSeconomy.get_department(id))
	var/list/goal_packs = list()
	for(var/id in goal_departments())
		var/datum/supply_pack/wanted
		for(var/datum/supply_pack/pack as anything in catalog_packs[id])
			var/price = econ_pack_price(pack)
			if(!econ_pack_unavailable(pack) && price <= SIM_GOAL_MAX_ORDERS * SIM_ORDER_VALUE && (!wanted || price > econ_pack_price(wanted)))
				wanted = pack
		goal_packs[id] = wanted
	var/list/goals_bought = list()
	var/list/states = list()
	var/list/med_hourly = list()
	var/med_spent = 0
	var/list/personal_packs = list()
	for(var/pack_type in GLOB.econ_personal_catalog)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(pack && !pack.DropPodOnly)
			personal_packs += pack
	var/list/start = list()
	for(var/id in departments)
		start[id] = budget(id)
	var/crew_start = crew_money()
	var/list/crew_start_balances = list()
	for(var/datum/bank_account/member as anything in crew)
		crew_start_balances[member] = member.account_balance
	var/datum/economy_ledger/ledger = SSeconomy.ledger
	var/department_minted_before = ledger.department_minted
	var/department_received_before = ledger.department_received
	var/department_paid_before = ledger.department_paid_out
	var/department_burned_before = ledger.department_burned
	var/minted_before = SSeconomy.ledger.minted
	var/money_before = SSeconomy.total_money()
	var/burned_before = SSeconomy.ledger.burned
	var/list/reasons_before = SSeconomy.ledger.by_reason.Copy()
	var/ticks_per_hour = round(1 HOURS / SSeconomy.wait)
	var/lottery_ticks = CEILING(SSeconomy.settings.lottery_sale_minutes MINUTES / SSeconomy.wait, 1)
	var/list/work = work_plan()
	var/list/bought = list()
	var/list/imported = list()
	var/vended = 0
	var/vend_debt = 0
	var/order_debt = 0
	var/performer_turn = 0
	var/lottery_drawn_at
	var/med_bought_hour = 0
	var/list/protected_last = list()
	for(var/tick in 1 to SIM_HOURS * ticks_per_hour)
		var/hour_tick = (tick - 1) % ticks_per_hour
		rand_seed(seed * 1000 + tick)
		SSmarket.market_shift()
		rand_seed(seed * 1000 + tick + 500)
		SSeconomy.fire()
		rand_seed(seed * 1000 + tick + 700)
		for(var/id in goal_packs)
			var/datum/economy_department/saver = SSeconomy.get_department(id)
			if(goal_packs[id] && !(id in goals_bought) && !saver.saving_goal && world.time >= saver.saving_goal_cooldown_until)
				saver.saving_goal = goal_packs[id]
				saver.saving_goal_until = world.time + SSeconomy.settings.saving_goal_minutes MINUTES
		for(var/id in work)
			var/list/workers = performers[id]
			if(!length(workers))
				continue
			for(var/list/entry as anything in work[id])
				var/records = round(entry[2] * (hour_tick + 1) / ticks_per_hour) - round(entry[2] * hour_tick / ticks_per_hour)
				for(var/n in 1 to records)
					performer_turn++
					SSeconomy.record_work(id, entry[1], entry[3], workers[(performer_turn % length(workers)) + 1])
		vend_debt += length(crew) * SIM_VEND_PER_CREW_HOUR / ticks_per_hour
		var/attempts = 0
		while(vend_debt > 0 && attempts++ < SIM_VEND_ATTEMPTS_MAX)
			var/datum/bank_account/member = pick(crew)
			var/paid = buy_from_machine(pickweight(machines), member, FALSE)
			vend_debt -= paid
			vended += paid
			spend_budget[member]["vend"] += paid
		if(tick == SIM_LOTTERY_TICK)
			SSeconomy.start_lottery()
		spend_personal(personal_packs)
		if(SSeconomy.lottery && tick >= SIM_LOTTERY_TICK + lottery_ticks)
			SSeconomy.lottery.draw()
			lottery_drawn_at = tick
		order_debt += SIM_STATION_ORDERS_PER_HOUR / ticks_per_hour
		while(order_debt >= 1)
			order_debt -= 1
			var/list/spare = list()
			var/list/choice = list()
			for(var/candidate in departments)
				var/datum/economy_department/candidate_department = SSeconomy.get_department(candidate)
				var/datum/supply_pack/option = candidate_department.saving_goal || pick_pack(catalog_packs[candidate], SIM_ORDER_VALUE)
				var/free_money = candidate_department.account.account_balance - payroll(candidate) * SIM_RESERVE_PAYDAYS
				if(option && free_money >= round(econ_pack_price(option)))
					spare[candidate] = free_money
					choice[candidate] = option
			if(!length(spare))
				continue
			var/id = pickweight(spare)
			var/datum/economy_department/department = SSeconomy.get_department(id)
			var/datum/supply_pack/pack = choice[id]
			var/price = round(econ_pack_price(pack))
			var/was_goal = pack == department.saving_goal
			var/list/orders_now = SSshuttle.shoppinglist.Copy()
			if(department.order_pack(pack, null, "Синтетический раунд", TRUE))
				bought[id] += 1
				imported[id] += price
				if(was_goal)
					goals_bought += id
				if(id == ACCOUNT_MED)
					med_bought_hour += 1
					med_spent += price
			for(var/order in SSshuttle.shoppinglist - orders_now)
				SSshuttle.shoppinglist -= order
				qdel(order)
		for(var/id in departments)
			var/datum/economy_department/guarded = SSeconomy.get_department(id)
			protected_last[id] = guarded.saving_goal_amount() + guarded.shielded()
		if(hour_tick == ticks_per_hour - 1)
			med_hourly += med_bought_hour
			med_bought_hour = 0
			states += SSeconomy.economy_state
		age_world(SSeconomy.wait)
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	var/minted = SSeconomy.ledger.minted - minted_before
	var/department_kept = (ledger.department_minted - department_minted_before) + (ledger.department_received - department_received_before) - (ledger.department_paid_out - department_paid_before)
	var/department_burned = ledger.department_burned - department_burned_before
	var/list/growth = list()
	for(var/datum/bank_account/member as anything in crew)
		growth += member.account_balance / max(crew_start_balances[member], SIM_MIN_MONEY)
	sortTim(growth, GLOBAL_PROC_REF(cmp_numeric_asc))
	var/burned = SSeconomy.ledger.burned - burned_before
	var/list/result = list(
		"minted" = minted,
		"burned" = burned,
		"ratio" = burned / max(minted, SIM_MIN_MONEY),
		"department_kept" = department_kept,
		"department_burned" = department_burned,
		"department_ratio" = department_burned / max(department_kept, SIM_MIN_MONEY),
		"department_ratio_no_return" = department_share(departments, FALSE),
		"department_ratio_no_cmd" = department_share(departments - ACCOUNT_CMD, TRUE),
		"department_ratio_bare" = department_share(departments - ACCOUNT_CMD, FALSE),
		"crew_growth" = growth[round((length(growth) + 1) / 2)],
		"start" = start,
		"end" = list(),
		"bought" = list(),
		"owed" = list(),
		"earned" = list(),
		"crew_start" = crew_start,
		"crew_end" = crew_money(),
		"vended" = vended,
		"seed" = seed,
		"minted_by_reason" = minted_by_reason.Copy(),
		"money_delta" = SSeconomy.total_money() - money_before,
		"med_hourly" = med_hourly,
		"med_spent" = med_spent,
		"states" = states,
		"goals_bought" = length(goals_bought) ? goals_bought : list("нет"),
		"eng_integrity" = flows["[ACCOUNT_ENG]|[ECON_WORK]"] || 0,
		"med_work" = flows["[ACCOUNT_MED]|[ECON_WORK]"] || 0,
		"threshold" = list(),
		"tick_income" = list(),
		"payroll" = list(),
		"protected" = list(),
	)
	var/list/burn_text = list()
	for(var/reason in crew_burns)
		burn_text += "[reason] [crew_burns[reason]]"
	result["crew_burns"] = jointext(burn_text, ", ") + (lottery_drawn_at ? "" : ", лотерея не разыграна")
	var/list/sources = list()
	for(var/reason in list(ECON_GRANT, ECON_WORK, ECON_WORK_PREMIUM, ECON_CONTRACT, ECON_WAGE_FLOOR, ECON_IMPORT, ECON_VEND_WHOLESALE, ECON_PERSONAL_CATALOG, ECON_GAMBLING, ECON_LOTTERY_HOUSE, ECON_TAX_NT, ECON_BUDGET_RETURN, ECON_WAGE, ECON_TAX))
		sources += "[reason] [SSeconomy.ledger.by_reason[reason] - reasons_before[reason]]"
	result["sources"] = jointext(sources, ", ")
	var/list/flow_text = list()
	for(var/key in flows)
		flow_text += "[key] [flows[key]]"
	result["flows"] = jointext(flow_text, ", ")
	for(var/id in departments)
		var/balance = budget(id)
		result["end"][id] = balance
		result["bought"][id] = bought[id] || 0
		result["owed"][id] = owed_wages(id)
		result["earned"][id] = balance + (imported[id] || 0) - start[id]
		var/datum/economy_department/department = SSeconomy.get_department(id)
		result["threshold"][id] = department.budget_threshold()
		result["payroll"][id] = payroll(id)
		result["protected"][id] = protected_last[id] || 0
		result["tick_income"][id] = round((inflow[id] || 0) / (SIM_HOURS * ticks_per_hour))
	fire_crew()
	for(var/order in SSshuttle.shoppinglist - orders_before)
		SSshuttle.shoppinglist -= order
		qdel(order)
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts())
		qdel(contract)
	econ_test_restore_market(saved_market)
	saved_market = null
	return result

/// Личный бюджет сверх обычных автоматов: премиум-позиции, личный каталог, слот-машина и лотерея по долям spend_split().
/datum/unit_test/economy_simulation/proc/spend_personal(list/personal_packs)
	var/list/split = spend_split()
	var/list/private_orders = list()
	for(var/datum/bank_account/member as anything in crew)
		var/list/wallet = spend_budget[member]
		var/free = (wallet["income"] || 0) * SIM_SPEND_SHARE / 100 - (wallet["vend"] || 0)
		wallet["income"] = 0
		wallet["vend"] = 0
		if(free < 0)
			wallet["carry_debt"] += -free
			free = 0
		var/repaid = min(free, wallet["carry_debt"] || 0)
		wallet["carry_debt"] -= repaid
		free -= repaid
		for(var/sink in split)
			wallet[sink] += free * split[sink] / 100
		while(wallet["premium"] > 0)
			var/spent = buy_from_machine(pick(premium_machines), member, TRUE)
			if(!spent)
				break
			wallet["premium"] -= spent
		var/list/affordable = list()
		for(var/datum/supply_pack/pack as anything in personal_packs)
			var/pack_price = round(econ_pack_price(pack, member))
			if(pack_price <= wallet["catalog"] && member.has_money(pack_price))
				affordable[pack] = pack_price
		if(length(affordable))
			var/datum/supply_pack/wanted = pick(affordable)
			private_orders += new /datum/supply_order(wanted, member.account_holder, "Синтетический раунд", null, "Личный каталог", member)
			wallet["catalog"] -= affordable[wanted]
		if(wallet["slots"] >= SIM_SLOT_DEPOSIT_MIN)
			wallet["slots"] -= play_slots(member, wallet["slots"])
		var/datum/econ_lottery/lottery = SSeconomy.lottery
		if(lottery && wallet["lottery"] > 0)
			var/tickets = wallet["lottery"] / lottery.ticket_price
			var/count = min(round(tickets) + (prob((tickets - round(tickets)) * 100) ? 1 : 0), lottery.tickets_per_account - (lottery.tickets["[member.account_id]"] || 0))
			if(count > 0 && !lottery.buy(member, count, buyer))
				wallet["lottery"] -= count * lottery.ticket_price
	if(length(private_orders))
		ship_private_orders(private_orders)

/// Частные заказы летят настоящим шаттлом снабжения, ящики после отгрузки убираются.
/datum/unit_test/economy_simulation/proc/ship_private_orders(list/private_orders)
	var/list/held = SSshuttle.shoppinglist.Copy()
	SSshuttle.shoppinglist.Cut()
	SSshuttle.shoppinglist += private_orders
	var/list/before = shuttle_contents()
	SSshuttle.supply.buy()
	for(var/pass in 1 to 3)
		for(var/atom/movable/thing as anything in shuttle_contents() - before)
			qdel(thing)
	for(var/order in SSshuttle.shoppinglist)
		qdel(order)
	SSshuttle.shoppinglist = held

/datum/unit_test/economy_simulation/proc/shuttle_contents()
	. = list()
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply.shuttle_areas)
		for(var/turf/floor in shuttle_area)
			for(var/atom/movable/thing in floor)
				. += thing

/// Внести бюджет слотов с карты и играть, пока хватает на ставку; остаток - обратно на счёт. Возвращает внесённое.
/datum/unit_test/economy_simulation/proc/play_slots(datum/bank_account/member, budget_amount)
	var/deposit = min(round(budget_amount), member.account_balance, SIM_SLOT_DEPOSIT_MAX)
	if(deposit < SIM_SLOT_BET)
		return 0
	buyer_card.registered_account = member
	var/datum/tgui/window = new(buyer, slots, "SlotMachine")
	window.status = UI_INTERACTIVE
	usr = buyer
	slots.ui_act("set_bet", list("amount" = "[SIM_SLOT_BET]"), window)
	slots.ui_act("card_deposit", list("amount" = "[deposit]"), window)
	usr = null
	qdel(window)
	while(slots.balance >= slots.bet_amount || slots.free_spins_remaining > 0)
		slots.charge_spin(buyer)
		slots.reset_spin_state()
		for(var/list/reel as anything in slots.reels)
			for(var/row in 1 to 3)
				reel[row] = pick(slots.symbols)
		slots.give_prizes(member.account_holder, buyer)
	var/left = slots.balance
	slots.balance = 0
	slots.gamble_available = FALSE
	if(left > 0)
		SSeconomy.move(SSeconomy.cash_account, member, left, ECON_CASH_IN, memo = "Голочип слот-машины")
	return deposit

/// Доля стоков отделов из счётчиков прогона; без with_return возврат излишка не входит ни в стоки, ни в оставшиеся деньги.
/datum/unit_test/economy_simulation/proc/department_share(list/ids, with_return)
	var/kept = 0
	var/burned = 0
	for(var/id in ids)
		var/list/flow = department_flows[id]
		kept += flow["kept"] - flow["paid_out"]
		burned += flow["burned"]
		if(!with_return)
			kept -= flow["returned"]
			burned -= flow["returned"]
	return burned / max(kept, SIM_MIN_MONEY)

/datum/unit_test/economy_simulation/proc/note_move(datum/source, datum/bank_account/payer, datum/bank_account/payee, amount, reason)
	SIGNAL_HANDLER
	if(!payer && minted_by_reason)
		minted_by_reason[reason] += amount
	var/payer_station = econ_is_station_budget(payer)
	var/payee_station = econ_is_station_budget(payee)
	if(payer_station != payee_station && department_flows)
		if(payee_station)
			var/datum/bank_account/department/payee_account = payee
			department_flows[payee_account.department_id]["kept"] += amount
		else
			var/datum/bank_account/department/payer_account = payer
			var/list/flow = department_flows[payer_account.department_id]
			if(payee)
				flow["paid_out"] += amount
			else
				flow["burned"] += amount
				if(reason == ECON_BUDGET_RETURN)
					flow["returned"] += amount
	var/datum/bank_account/department/payer_budget = payer
	var/datum/bank_account/department/payee_budget = payee
	if(istype(payee_budget) && payee_budget.department)
		flows["[payee_budget.department_id]|[reason]"] += amount
		inflow[payee_budget.department_id] += amount
	if(istype(payer_budget) && payer_budget.department)
		flows["[payer_budget.department_id]|-[reason]"] += amount
	if(payee && spend_budget?[payee] && (reason in list(ECON_WAGE, ECON_WAGE_FLOOR, ECON_WORK_PREMIUM, ECON_CONTRACT)))
		spend_budget[payee]["income"] += amount
	if(payer && spend_budget?[payer] && (reason in list(ECON_TAX, ECON_TAX_NT)))
		spend_budget[payer]["income"] -= amount
	if(payer && !payee && spend_budget?[payer])
		crew_burns[reason] += amount
	if(!payee && (payer == SSeconomy.cash_account || payer == SSeconomy.lottery?.pool))
		crew_burns[reason] += amount

/datum/unit_test/economy_simulation/proc/budget(id)
	var/datum/economy_department/department = SSeconomy.get_department(id)
	return department.account.account_balance

/datum/unit_test/economy_simulation/proc/crew_money()
	. = 0
	for(var/datum/bank_account/member as anything in crew)
		. += member.account_balance

/datum/unit_test/economy_simulation/proc/payroll(id)
	. = 0
	for(var/datum/bank_account/member as anything in crew)
		if(member.department_id == id)
			. += member.wage_amount()

/datum/unit_test/economy_simulation/proc/owed_wages(id)
	. = 0
	for(var/datum/bank_account/member as anything in crew)
		if(member.department_id == id)
			. += member.owed_wages

/// Каталог отдела от дешёвого к дорогому.
/datum/unit_test/economy_simulation/proc/sorted_catalog(datum/economy_department/department)
	. = list()
	var/list/by_price = list()
	for(var/datum/supply_pack/pack as anything in department.catalog())
		if(!econ_test_explodes_on_delete(pack))
			by_price[pack] = econ_pack_price(pack)
	for(var/datum/supply_pack/pack as anything in sortTim(by_price, GLOBAL_PROC_REF(cmp_numeric_asc), associative = TRUE))
		. += pack

/datum/unit_test/economy_simulation/proc/middle_price(list/packs)
	var/datum/supply_pack/pack = pick_pack(packs)
	return pack ? round(econ_pack_price(pack)) : 0

/// Пак из каталога, отсортированного по цене: ближайший к value по цене, без value - из середины.
/datum/unit_test/economy_simulation/proc/pick_pack(list/packs, value)
	if(!length(packs))
		return null
	var/middle = round(length(packs) / 2) + 1
	if(value)
		var/best_gap = INFINITY
		for(var/i in 1 to length(packs))
			var/gap = abs(econ_pack_price(packs[i]) - value)
			if(gap < best_gap)
				best_gap = gap
				middle = i
	for(var/offset in 0 to length(packs))
		var/index = middle + (offset % 2 ? -1 : 1) * round((offset + 1) / 2)
		if(index < 1 || index > length(packs))
			continue
		var/datum/supply_pack/pack = packs[index]
		if(!econ_pack_unavailable(pack))
			return pack

/// Покупка в автомате через окно, как у игрока; premium - из премиальных позиций. Возвращает списанную сумму.
/datum/unit_test/economy_simulation/proc/buy_from_machine(obj/machinery/vending/machine, datum/bank_account/member, premium)
	var/list/records = premium ? machine.coin_records : machine.product_records
	if(!length(records))
		return 0
	var/datum/data/vending_product/record = pick(records)
	record.amount = max(record.amount, 1)
	buyer_card.registered_account = member
	var/before = member.account_balance
	var/datum/tgui/window = new(buyer, machine, "Vending")
	window.status = UI_INTERACTIVE
	usr = buyer
	machine.ui_act("vend", list("ref" = REF(record)), window)
	usr = null
	qdel(window)
	for(var/obj/item/bought in buyer.contents + machine.loc.contents)
		if(bought != buyer_card && bought.type == record.product_path)
			qdel(bought)
	return before - member.account_balance

/// world.time в тесте стоит: сроки контрактов и окна премий сдвигаются назад на прошедший тик. Не сдвигаются и в прогоне не наступают: пополнение складов партнёров, эмбарго, окна кулдаунов работ и заявок, таймер розыгрыша лотереи (её разыгрывает сам прогон).
/datum/unit_test/economy_simulation/proc/age_world(delta)
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts())
		contract.created -= delta
		if(contract.deadline)
			contract.deadline -= delta
	for(var/datum/bank_account/member as anything in crew)
		member.premium_window_start -= delta
	if(SSeconomy.lottery)
		SSeconomy.lottery.ends_at -= delta
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		if(department.saving_goal)
			department.saving_goal_until -= delta
		department.saving_goal_cooldown_until -= delta

#undef SIM_HOURS
#undef SIM_SEEDS
#undef SIM_VEND_PER_CREW_HOUR
#undef SIM_SPEND_SHARE
#undef SIM_STATION_ORDERS_PER_HOUR
#undef SIM_ORDER_VALUE
#undef SIM_RESERVE_PAYDAYS
#undef SIM_GOAL_MAX_ORDERS
#undef SIM_ROSTER_MEDIAN
#undef SIM_EMISSION_REASONS
#undef SIM_VEND_ATTEMPTS_MAX
#undef SIM_SLOT_BET
#undef SIM_LOTTERY_TICK
#undef SIM_SLOT_DEPOSIT_MIN
#undef SIM_SLOT_DEPOSIT_MAX
#undef SIM_MIN_MONEY
#undef SIM_CREW_GROWTH_MARGIN
