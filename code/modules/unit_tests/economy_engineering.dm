/datum/unit_test/economy_engineering
	abstract_type = /datum/unit_test/economy_engineering
	var/datum/economy_department/engineering/engineering
	var/datum/bank_account/department/budget
	var/saved_budget
	var/saved_export_pending
	var/saved_export_due
	var/turf/moved_floor
	var/area/original_area
	var/list/stashed_contracts
	var/list/saved_market
	var/list/saved_work_prices

/// Узел на резервном уровне тестов, который продаёт как станционный.
/obj/machinery/power/export_node/econ_test_station

/obj/machinery/power/export_node/econ_test_station/on_station_grid()
	return TRUE

/datum/unit_test/economy_engineering/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	saved_market = econ_test_swap_market()
	saved_work_prices = SSeconomy.settings.work_prices.Copy()

/datum/unit_test/economy_engineering/proc/save_state()
	engineering = SSeconomy.get_department(ACCOUNT_ENG)
	budget = engineering.account
	saved_budget = budget.account_balance
	saved_export_pending = engineering.export_pending
	saved_export_due = engineering.export_payout_due
	engineering.export_pending = 0
	engineering.export_payout_due = 0

/datum/unit_test/economy_engineering/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	econ_test_restore_market(saved_market)
	for(var/work_type in saved_work_prices)
		SSeconomy.settings.work_prices[work_type] = saved_work_prices[work_type]
	if(budget)
		budget.debit(max(budget.account_balance, 0), ECON_ADMIN)
		budget.credit(saved_budget, ECON_ADMIN)
		budget = null
	if(engineering)
		engineering.export_pending = saved_export_pending
		engineering.export_payout_due = saved_export_due
		engineering = null
	if(moved_floor)
		original_area.contents.Add(moved_floor)
		moved_floor = null
		original_area = null
	SSeconomy.power_export_cycle = null
	return ..()

/datum/unit_test/economy_engineering/proc/power_cycle(datum/powernet/net, generated)
	SSeconomy.power_export_cycle = null
	net.newavail = generated
	net.reset()

/datum/unit_test/economy_engineering/proc/test_grid(obj/machinery/power/export_node/node)
	var/obj/structure/cable/cable = allocate(/obj/structure/cable)
	var/datum/powernet/grid = new
	SSmachines.powernets -= grid
	propagate_network(cable, grid)
	node.connect_to_network()
	return grid

/// Узел вне станции не продаёт излишек и не платит инженерии, осмотр и окно говорят почему.
/datum/unit_test/economy_engineering/power_export_offstation/Run()
	save_state()
	TEST_ASSERT(!is_station_level(run_loc_floor_bottom_left.z), "Тестовая резервация не станционная")
	var/obj/machinery/power/export_node/node = allocate(/obj/machinery/power/export_node)
	var/datum/powernet/grid = test_grid(node)
	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human)
	econ_ui_press(engineer, node, "PowerExportNode", "set_draw", list("kw" = 1000))
	econ_ui_press(engineer, node, "PowerExportNode", "toggle")
	TEST_ASSERT(node.active, "Узел не включился")
	for(var/i in 1 to 3)
		power_cycle(grid, 2000000)
		node.process(1)
	power_cycle(grid, 2000000)
	TEST_ASSERT_EQUAL(node.last_export_w, 0, "Узел вне станции продаёт энергию")
	TEST_ASSERT_EQUAL(engineering.export_pending, 0, "Узел вне станции копит доход инженерии")
	TEST_ASSERT(findtext(jointext(node.examine(engineer), "\n"), "Узел стоит вне станции"), "Осмотр не говорит, что узел вне станции")
	TEST_ASSERT(!node.ui_data(engineer)["on_station"], "Окно считает узел станционным")

/// Индекс исправности считается по APC и воздушным тревогам станции вне техтоннелей и платит инженерии на тике экономики.
/datum/unit_test/economy_engineering/integrity/Run()
	save_state()
	var/list/station_apcs = list()
	for(var/obj/machinery/power/apc/apc as anything in GLOB.apcs_list)
		if(is_station_level(apc.z))
			station_apcs[apc] = apc.operating
	var/list/station_alarms = list()
	for(var/obj/machinery/airalarm/alarm as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/airalarm))
		if(is_station_level(alarm.z))
			station_alarms[alarm] = alarm.danger_level
	TEST_ASSERT(length(station_apcs) && length(station_alarms), "На станции нет APC или воздушных тревог")

	for(var/obj/machinery/power/apc/apc as anything in station_apcs)
		apc.operating = FALSE
	for(var/obj/machinery/airalarm/alarm as anything in station_alarms)
		alarm.danger_level = 2
	var/broken_score = engineering.integrity_score()
	for(var/obj/machinery/power/apc/apc as anything in station_apcs)
		apc.operating = station_apcs[apc]
	for(var/obj/machinery/airalarm/alarm as anything in station_alarms)
		alarm.danger_level = station_alarms[alarm]
	TEST_ASSERT_EQUAL(broken_score, 0, "Выключенные APC и тревоги везде дают нулевой индекс")

	var/score = engineering.integrity_score()
	TEST_ASSERT(score > 0 && score <= 100, "Индекс исправной станции вне 1..100: [score]")
	var/before = budget.account_balance
	engineering.on_economy_tick()
	TEST_ASSERT_EQUAL(budget.account_balance - before, round(score * SSeconomy.settings.work_prices[WORK_ENG_INTEGRITY]), "Выплата по индексу")

	var/list/maint_floors = list()
	for(var/turf/open/floor in get_area_turfs(/area/maintenance, 0, TRUE))
		if(is_station_level(floor.z))
			maint_floors += floor
	TEST_ASSERT(length(maint_floors), "На станции нет техтоннелей")
	for(var/i in 1 to 5)
		var/obj/machinery/airalarm/maint_alarm = allocate(/obj/machinery/airalarm, maint_floors[1])
		maint_alarm.danger_level = 2
	TEST_ASSERT_EQUAL(engineering.integrity_score(), score, "Тревоги в техтоннелях снизили индекс")

/// Узел продаёт остаток сети после потребителей, платит инженерии крупной суммой, недобор грузит сеть следующим циклом.
/datum/unit_test/economy_engineering/power_export_node/Run()
	save_state()
	var/obj/machinery/power/export_node/node = allocate(/obj/machinery/power/export_node/econ_test_station)
	var/datum/powernet/grid = test_grid(node)
	TEST_ASSERT(node.powernet == grid, "Узел не подключился к сети кабеля")

	var/datum/economy_settings/settings = SSeconomy.settings
	node.set_target_kw(1000)
	TEST_ASSERT_EQUAL(node.target_kw, 1000, "Мощность отбора не задана")
	node.toggle(null)
	TEST_ASSERT(node.active, "Узел не включился")
	power_cycle(grid, 2000000)
	var/cycles = CEILING(ECON_POWER_EXPORT_PAYOUT_BULK / settings.power_export_credits_per_mj, 1)
	var/before = budget.account_balance
	for(var/i in 1 to cycles - 1)
		node.process(1)
		power_cycle(grid, 2000000)
	TEST_ASSERT_EQUAL(node.last_export_w, 1000000, "Продаётся вся заданная мощность")
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Выплата до накопления крупной суммы")
	node.process(1)
	power_cycle(grid, 2000000)
	var/earned = cycles * settings.power_export_credits_per_mj
	var/paid = budget.account_balance - before
	TEST_ASSERT(paid > 0, "Бюджет инженерии не получил оплату")
	TEST_ASSERT(abs(paid - round((earned - engineering.export_pending) * settings.work_prices[WORK_ENG_POWER_EXPORT])) < 0.1, "1 МВт × [cycles] с: выплачено [paid], в остатке [engineering.export_pending]")

	power_cycle(grid, 400000)
	node.process(1)
	power_cycle(grid, 400000)
	TEST_ASSERT_EQUAL(node.last_export_w, 400000, "Продано не столько, сколько осталось в сети")
	TEST_ASSERT_EQUAL(grid.load, 600000, "Недобор не лёг на сеть следующим циклом")
	node.process(1)
	power_cycle(grid, 400000)
	TEST_ASSERT_EQUAL(node.last_export_w, 0, "Узел продаёт из сети, которую сам перегрузил")

	power_cycle(grid, 2000000)
	node.panel_open = TRUE
	node.process(1)
	power_cycle(grid, 2000000)
	TEST_ASSERT(!node.last_export_w && !grid.load, "Узел с открытой панелью продаёт")
	node.crowbar_act(null, allocate(/obj/item/crowbar))
	TEST_ASSERT(!QDELETED(node), "Включённый узел разобран ломом")

	node.panel_open = FALSE
	node.toggle(null)
	node.process(1)
	power_cycle(grid, 2000000)
	TEST_ASSERT(!node.last_export_w && !grid.load, "Выключенный узел продаёт")

	node.set_target_kw(999999)
	TEST_ASSERT_EQUAL(node.target_kw, settings.power_export_max_kw, "Потолок отбора")
	node.set_target_kw(settings.power_export_step_kw * 2.2)
	TEST_ASSERT_EQUAL(node.target_kw, settings.power_export_step_kw * 2, "Мощность не округлена до шага")

/// Узлы сверх потолка станции продают энергию, но оплачивается только потолок по рынку энергии.
/datum/unit_test/economy_engineering/power_export_station_cap/Run()
	save_state()
	var/datum/commodity/energy = SSmarket.get_commodity(COMMODITY_ENERGY)
	energy.price_factor = 1.5
	var/datum/economy_settings/settings = SSeconomy.settings
	TEST_ASSERT(settings.power_export_station_cap_kw < settings.power_export_max_kw * 2, "Потолок станции не меньше двух узлов")
	var/obj/machinery/power/export_node/first = allocate(/obj/machinery/power/export_node/econ_test_station)
	var/obj/machinery/power/export_node/second = allocate(/obj/machinery/power/export_node/econ_test_station)
	var/datum/powernet/grid = test_grid(first)
	second.connect_to_network()
	for(var/obj/machinery/power/export_node/node as anything in list(first, second))
		node.set_target_kw(settings.power_export_max_kw)
		node.toggle(null)
	power_cycle(grid, 100000000)
	first.process(1)
	second.process(1)
	power_cycle(grid, 100000000)
	TEST_ASSERT(first.last_export_w == second.last_export_w && first.last_export_w == settings.power_export_max_kw * 1000, "Оба узла продают заданную мощность")
	var/expected = settings.power_export_station_cap_kw / 1000 * settings.power_export_credits_per_mj * econ_sale_factor(COMMODITY_ENERGY)
	TEST_ASSERT(abs(econ_sale_factor(COMMODITY_ENERGY) - 1.5) < 0.001, "Рынок энергии не выставлен")
	TEST_ASSERT(abs(engineering.export_pending - expected) < 0.1, "Оплачено [engineering.export_pending] кр. вместо [expected] за потолок станции")

/// Перегружающий узел сажает батарею APC той же сети, узел на излишке APC не мешает.
/datum/unit_test/economy_engineering/power_export_apc/Run()
	save_state()
	moved_floor = run_loc_floor_bottom_left
	original_area = get_area(moved_floor)
	var/area/test_area = new /area
	test_area.contents.Add(moved_floor)
	var/obj/machinery/power/apc/apc = allocate(/obj/machinery/power/apc)
	TEST_ASSERT(apc.terminal && apc.cell, "У APC нет терминала или батареи")
	var/obj/machinery/power/export_node/node = allocate(/obj/machinery/power/export_node/econ_test_station, run_loc_floor_top_right)
	var/datum/powernet/grid = new
	SSmachines.powernets -= grid
	grid.add_machine(apc.terminal)
	grid.add_machine(node)
	test_area.static_equip = 500
	apc.cell.charge = apc.cell.maxcharge / 2
	node.toggle(null)

	var/datum/economy_settings/settings = SSeconomy.settings
	node.set_target_kw(settings.power_export_step_kw)
	var/start_charge = apc.cell.charge
	for(var/i in 1 to 5)
		power_cycle(grid, 1000000)
		apc.process()
		node.process(1)
	TEST_ASSERT_EQUAL(node.last_export_w, settings.power_export_step_kw * 1000, "Узел не продаёт излишек")
	TEST_ASSERT(apc.cell.charge >= start_charge, "Узел на излишке посадил APC: [apc.cell.charge] из [start_charge]")

	node.set_target_kw(settings.power_export_max_kw)
	start_charge = apc.cell.charge
	for(var/i in 1 to 5)
		power_cycle(grid, 1000000)
		apc.process()
		node.process(1)
	TEST_ASSERT(apc.cell.charge < start_charge, "Перегрузка сети не посадила APC: [apc.cell.charge] из [start_charge]")

/// Катушки Теслы отдают разряд только в сеть: продаёт его узел экспорта в пределах потолка, напрямую инженерии они не платят.
/datum/unit_test/economy_engineering/tesla_coil_export/Run()
	save_state()
	var/before = budget.account_balance
	for(var/coil_type in list(/obj/machinery/power/tesla_coil/power, /obj/machinery/power/tesla_coil/research))
		var/obj/machinery/power/tesla_coil/coil = allocate(coil_type)
		coil.set_anchored(TRUE)
		coil.zap_act(1000000, ZAP_FUSION_FLAGS)
		TEST_ASSERT(engineering.export_pending < 0.01, "[coil_type] продал разряд мимо узла: [engineering.export_pending]")
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Катушки заплатили инженерии")

/// Научный режим коллектора продаёт энергию в общем потолке экспорта станции: при выбранном потолке не платит.
/datum/unit_test/economy_engineering/collector_export_cap/Run()
	save_state()
	var/turf/open/spot = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(spot, "Есть станционный турф")
	var/obj/machinery/power/rad_collector/anchored/collector = allocate(/obj/machinery/power/rad_collector/anchored, spot)
	var/obj/item/tank/internals/plasma/tank = allocate(/obj/item/tank/internals/plasma)
	tank.forceMove(collector)
	collector.loaded_tank = tank
	collector.bitcoinmining = TRUE
	var/saved_points = SSresearch.science_tech.research_points[TECHWEB_POINT_TYPE_DEFAULT]
	var/cap_w = SSeconomy.settings.power_export_station_cap_kw * 1000
	var/before = budget.account_balance
	for(var/cap_used in list(cap_w, 0))
		tank.air_contents.set_moles(GAS_TRITIUM, 10)
		tank.air_contents.set_moles(GAS_O2, 10)
		collector.stored_power = cap_w
		SSeconomy.power_export_cycle = SSmachines.times_fired
		SSeconomy.power_export_paid_w = cap_used
		collector.process()
		var/earned = budget.account_balance - before + engineering.export_pending
		if(cap_used)
			TEST_ASSERT(earned < 0.01, "Коллектор продал энергию сверх выбранного потолка: [earned]")
		else
			TEST_ASSERT(earned > 0, "Коллектор не продал энергию при свободном потолке")
			TEST_ASSERT_EQUAL(SSeconomy.power_export_paid_w, cap_w, "Коллектор не занял потолок станции")
	SSresearch.science_tech.research_points[TECHWEB_POINT_TYPE_DEFAULT] = saved_points
	collector.loaded_tank = null

/// Нулевой шаг отбора и отрицательный потолок станции в economy.json отвергаются.
/datum/unit_test/economy_engineering/settings_step/Run()
	var/path = "data/unit_test_economy_power_step.json"
	fdel(path)
	text2file("{\"settings\": {\"power_export_step_kw\": 0, \"power_export_station_cap_kw\": -1, \"power_export_max_kw\": 1500}}", path)
	var/datum/economy_settings/settings = new
	var/list/errors = settings.load(path)
	fdel(path)
	TEST_ASSERT_EQUAL(length(errors), 2, "Ошибки: [jointext(errors, "; ")]")
	TEST_ASSERT_EQUAL(settings.power_export_step_kw, initial(settings.power_export_step_kw), "Нулевой шаг принят")
	TEST_ASSERT_EQUAL(settings.power_export_station_cap_kw, initial(settings.power_export_station_cap_kw), "Отрицательный потолок принят")
	TEST_ASSERT_EQUAL(settings.power_export_max_kw, 1500, "Потолок из JSON не применился")
