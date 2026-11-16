/datum/unit_test/economy_cargo
	abstract_type = /datum/unit_test/economy_cargo
	var/datum/bank_account/department/cargo
	var/datum/economy_department/service/service
	var/saved_cargo
	var/saved_service
	/// Движения журнала за тест: list(target, amount, reason)
	var/list/moves = list()
	var/obj/machinery/mineral/ore_redemption/orm
	var/datum/space_level/patched_level
	var/list/original_traits
	/// Турф -> область, из которой его перенесли
	var/list/moved_turfs = list()
	/// Тип уникальной области -> прежняя запись GLOB.areas_by_type
	var/list/replaced_unique_areas = list()
	var/list/stashed_contracts
	var/list/saved_market

/datum/unit_test/economy_cargo/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	saved_market = econ_test_swap_market()

/datum/unit_test/economy_cargo/proc/setup()
	cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	service = SSeconomy.get_department(ACCOUNT_SRV)
	saved_cargo = cargo.account_balance
	saved_service = service.account.account_balance
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_moved))

/datum/unit_test/economy_cargo/proc/on_moved(datum/source, datum/bank_account/from, datum/bank_account/target, amount, reason, mob/actor)
	SIGNAL_HANDLER
	moves += list(list(target, amount, reason))

/datum/unit_test/economy_cargo/proc/moved_to(datum/bank_account/target, reason)
	. = list()
	for(var/list/move as anything in moves)
		if(move[1] == target && move[3] == reason)
			. += move[2]

/datum/unit_test/economy_cargo/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	econ_test_restore_market(saved_market)
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	if(orm)
		var/turf/orm_turf = get_turf(orm)
		QDEL_NULL(orm)
		for(var/obj/item/stack/leftover in orm_turf)
			qdel(leftover)
	for(var/turf/moved as anything in moved_turfs)
		var/area/original_area = moved_turfs[moved]
		original_area.contents.Add(moved)
	for(var/area_type in replaced_unique_areas)
		GLOB.areas_by_type[area_type] = replaced_unique_areas[area_type]
	if(patched_level)
		patched_level.traits = original_traits
		patched_level = null
	if(cargo)
		econ_test_set_balance(cargo, saved_cargo)
	if(service)
		econ_test_set_balance(service.account, saved_service)
	cargo = null
	service = null
	return ..()

/datum/unit_test/economy_cargo/proc/shuttle_floor()
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply?.shuttle_areas)
		for(var/turf/open/floor in shuttle_area)
			return floor

/datum/unit_test/economy_cargo/proc/set_mining_trait(z)
	patched_level = SSmapping.z_list[z]
	original_traits = patched_level.traits
	patched_level.traits = original_traits.Copy()
	patched_level.traits[ZTRAIT_MINING] = TRUE

/// Переносит турф в новую область типа area_type; Destroy() возвращает всё как было.
/datum/unit_test/economy_cargo/proc/move_floor_to(turf/floor, area_type)
	if(!moved_turfs[floor])
		moved_turfs[floor] = get_area(floor)
	var/area/new_area = area_type
	if((initial(new_area.area_flags) & UNIQUE_AREA) && !(area_type in replaced_unique_areas))
		replaced_unique_areas[area_type] = GLOB.areas_by_type[area_type]
	new_area = new area_type
	new_area.contents.Add(floor)

/datum/unit_test/economy_cargo/proc/feed_ore(ore_amount)
	var/obj/item/stack/ore/iron/ore = new(get_step(orm, orm.input_dir), ore_amount)
	var/before = cargo.account_balance
	orm.process_all_ores()
	var/deadline = world.time + 5 SECONDS
	while(!QDELETED(ore) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(QDELETED(ore), "ORM переработал руду")
	return cargo.account_balance - before

/datum/unit_test/economy_cargo/proc/ore_price(ore_amount)
	var/obj/item/stack/ore/iron/ore_type = /obj/item/stack/ore/iron
	return round(SSeconomy.settings.work_prices[WORK_MINING_ORE] * (initial(ore_type.points) * ore_amount * econ_sale_factor(COMMODITY_METALS)))

/datum/unit_test/economy_cargo/proc/click_print(obj/machinery/computer/cargo/console, mob/living/carbon/human/user)
	var/datum/tgui/window = allocate(/datum/tgui, user, console, "Cargo")
	window.status = UI_INTERACTIVE
	usr = user
	console.ui_act("print_manifest", list(), window)
	usr = null
	. = list()
	for(var/obj/item/export_manifest/manifest in user.held_items)
		. += manifest
		qdel(manifest)

/datum/unit_test/economy_cargo/proc/make_staff(name, department_id)
	var/mob/living/carbon/human/staff = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new(name)
	account.department_id = department_id
	staff.account_id = account.account_id
	allocated += account
	return staff

/// Отгрузка шаттлом: ящик с накладной отдела платит отделу за вычетом сбора карго, ящик без накладной - всё карго.
/datum/unit_test/economy_cargo/manifest_split/Run()
	setup()
	var/turf/open/floor = shuttle_floor()
	TEST_ASSERT_NOTNULL(floor, "Есть пол шаттла снабжения")
	var/obj/structure/closet/crate/labeled = allocate(/obj/structure/closet/crate, floor)
	new /obj/item/stack/sheet/metal/fifty(labeled)
	var/obj/item/export_manifest/manifest = service.print_manifest(labeled)
	TEST_ASSERT_EQUAL(manifest.department_id, ACCOUNT_SRV, "Накладная выписана на сервис")
	var/obj/structure/closet/crate/plain = allocate(/obj/structure/closet/crate, floor)
	new /obj/item/stack/sheet/metal/fifty(plain)
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(labeled) && QDELETED(plain) && QDELETED(manifest), "Ящики и накладная проданы")
	var/list/service_shares = moved_to(service.account, ECON_EXPORT)
	var/list/fees = moved_to(cargo, ECON_HANDLING_FEE)
	var/list/cargo_exports = moved_to(cargo, ECON_EXPORT)
	TEST_ASSERT_EQUAL(length(service_shares), 1, "Отдел получил одну выплату по накладной")
	TEST_ASSERT_EQUAL(length(fees), 1, "Карго получило один сбор")
	TEST_ASSERT_EQUAL(length(cargo_exports), 1, "Ящик без накладной оплачен карго")
	var/labeled_revenue = service_shares[1] + fees[1]
	TEST_ASSERT(labeled_revenue > 0 && cargo_exports[1] > 0, "Металл продаётся")
	TEST_ASSERT_EQUAL(fees[1], round(labeled_revenue * SSeconomy.settings.cargo_handling_fee / 100), "Сбор карго от выручки ящика")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "Выручка: [labeled_revenue + cargo_exports[1]] кр."), "Сообщение ЦК называет всю выручку: [SSshuttle.centcom_message]")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "[service.name] - [service_shares[1]] кр."), "Сообщение ЦК называет долю отдела: [SSshuttle.centcom_message]")

/// Маяк бомбы - контрабанда: штрафной экспорт не трогает деньги, NT его не берёт и шаттл возвращает; выручка в сообщении ЦК равна изменению бюджета снабжения.
/datum/unit_test/economy_cargo/penalty_export/Run()
	setup()
	var/turf/open/floor = shuttle_floor()
	TEST_ASSERT_NOTNULL(floor, "Есть пол шаттла снабжения")
	var/obj/structure/closet/crate/crate = allocate(/obj/structure/closet/crate, floor)
	new /obj/item/stack/sheet/metal/fifty(crate)
	var/obj/item/sbeacondrop/bomb/beacon = new(crate)
	var/before = cargo.account_balance
	var/saved_customs_chance = SSeconomy.settings.customs_chance
	SSeconomy.settings.customs_chance = 0
	SSshuttle.supply.sell()
	SSeconomy.settings.customs_chance = saved_customs_chance
	var/delta = cargo.account_balance - before
	TEST_ASSERT(!QDELETED(beacon) && isturf(beacon.loc), "Маяк бомбы не вернулся с шаттла")
	qdel(beacon)
	TEST_ASSERT(delta > 0, "Металл продан")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "Выручка: [delta] кр."), "Выручка сходится с бюджетом: [delta], [SSshuttle.centcom_message]")

/// Консоль печатает накладную своего отдела; снабженцу отказ; кулдаун у сотрудника, а не у консоли.
/datum/unit_test/economy_cargo/manifest_console/Run()
	setup()
	var/obj/machinery/computer/cargo/request/console = allocate(/obj/machinery/computer/cargo/request)
	var/obj/machinery/computer/cargo/request/other_console = allocate(/obj/machinery/computer/cargo/request)
	var/mob/living/carbon/human/cook = make_staff("econ_test_cook", ACCOUNT_SRV)
	var/mob/living/carbon/human/barman = make_staff("econ_test_barman", ACCOUNT_SRV)
	var/mob/living/carbon/human/technician = make_staff("econ_test_technician", ACCOUNT_CAR)
	var/list/cook_data = console.ui_data(cook)
	var/list/technician_data = console.ui_data(technician)
	TEST_ASSERT_EQUAL(cook_data["manifest_department"], service.name, "Консоль предлагает накладную отдела")
	TEST_ASSERT_NULL(technician_data["manifest_department"], "Снабженцу кнопки нет")
	var/list/first = click_print(console, cook)
	TEST_ASSERT_EQUAL(length(first), 1, "Накладная в руках")
	var/obj/item/export_manifest/manifest = first[1]
	TEST_ASSERT_EQUAL(manifest.department_id, ACCOUNT_SRV, "Накладная сервиса")
	TEST_ASSERT_EQUAL(length(click_print(other_console, cook)), 0, "Кулдаун держится на другой консоли")
	TEST_ASSERT_EQUAL(length(click_print(console, barman)), 1, "Чужой клик не занимает консоль")
	TEST_ASSERT_EQUAL(length(click_print(console, technician)), 0, "Снабженцу накладная не печатается")

/// ORM на станции платит карго долю стоимости руды по рынку металлов, а осмотр это описывает.
/datum/unit_test/economy_cargo/orm_station_share/Run()
	setup()
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	metals.price_factor = 2
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	orm = new(station_turf)
	var/paid = feed_ore(10)
	var/obj/item/stack/ore/iron/orm_ore = /obj/item/stack/ore/iron
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, station_turf)
	TEST_ASSERT_EQUAL(paid, ore_price(10), "Карго получило долю за руду по рынку")
	TEST_ASSERT_EQUAL(paid, initial(orm_ore.points) * 10 * 2 * SSeconomy.settings.work_prices[WORK_MINING_ORE], "Доля за руду не удвоилась с рынком металлов")
	TEST_ASSERT(findtext(jointext(orm.examine(viewer), "\n"), "отделу снабжения [SSeconomy.settings.work_prices[WORK_MINING_ORE] * 2] кр."), "Осмотр ORM называет долю карго по рынку")

/// Вне станции ORM не платит; на шахтёрском уровне платит, но не в руине и не в чужом шаттле, а в аванпосте шахтёров - платит.
/datum/unit_test/economy_cargo/orm_location_rules/Run()
	setup()
	var/turf/floor = run_loc_floor_bottom_left
	TEST_ASSERT(!is_station_level(floor.z) && !is_mining_level(floor.z), "Тестовая резервация не станция и не шахта")
	orm = new(floor)
	TEST_ASSERT_EQUAL(feed_ore(10), 0, "Вне станции руда не платит")
	set_mining_trait(floor.z)
	TEST_ASSERT_EQUAL(feed_ore(10), ore_price(10), "На шахтёрском уровне руда платит")
	move_floor_to(floor, /area/ruin)
	TEST_ASSERT_EQUAL(feed_ore(10), 0, "В руине руда не платит")
	move_floor_to(floor, /area/shuttle)
	TEST_ASSERT_EQUAL(feed_ore(10), 0, "В чужом шаттле руда не платит")
	move_floor_to(floor, /area/shuttle/auxillary_base)
	TEST_ASSERT_EQUAL(feed_ore(10), ore_price(10), "В аванпосте шахтёров руда платит")

/// Сканер на борту показывает ровно ту выручку, что придёт: спрос снимается разом после оценки всей отгрузки.
/datum/unit_test/economy_cargo/shipment_preview_matches/Run()
	setup()
	var/turf/open/floor = shuttle_floor()
	TEST_ASSERT_NOTNULL(floor, "Есть пол шаттла снабжения")
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	metals.demand_capacity = 1000
	var/list/crates = list()
	var/preview = 0
	var/packaging = 0
	for(var/i in 1 to 2)
		var/obj/structure/closet/crate/crate = allocate(/obj/structure/closet/crate, floor)
		new /obj/item/stack/sheet/metal/fifty(crate)
		crates += crate
		preview += econ_export_report_value(export_item_and_contents(crate, SSshuttle.supply.export_categories, dry_run = TRUE))
		packaging += econ_packaging_value(crate.type)
	SSshuttle.supply.sell()
	var/revenue = 0
	for(var/amount in moved_to(cargo, ECON_EXPORT))
		revenue += amount
	TEST_ASSERT(preview > packaging, "Металл в превью не оценён")
	TEST_ASSERT_EQUAL(revenue, preview, "Выплата не совпала с превью сканера")
	TEST_ASSERT(abs(metals.demand - max(1 - (preview - packaging) / metals.demand_capacity, 0)) < 0.001, "Спрос металлов [metals.demand] снят не по всей отгрузке")
