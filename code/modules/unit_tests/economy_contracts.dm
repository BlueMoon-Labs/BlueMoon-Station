/// Снимает контракты, появившиеся после снимка before.
/proc/econ_test_drop_new_contracts(list/before)
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts() - before)
		qdel(contract)

/// Убирает доски отделов на время теста, чтобы контракты не платили отделам сверх проверяемого.
/proc/econ_test_stash_contracts()
	. = list()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		.[id] = department.contracts
		department.contracts = list()

/proc/econ_test_restore_contracts(list/stash)
	for(var/id in stash)
		var/datum/economy_department/department = SSeconomy.departments[id]
		var/list/during_test = department.contracts
		department.contracts = stash[id]
		for(var/datum/econ_contract/contract as anything in during_test)
			qdel(contract)

/// После обновления у каждого станционного отдела, кроме командования, есть контракты.
/datum/unit_test/economy_contracts_generated/Run()
	SSeconomy.refresh_contracts(force = TRUE)
	for(var/id in list(ACCOUNT_SEC, ACCOUNT_ENG, ACCOUNT_MED, ACCOUNT_SCI, ACCOUNT_CAR, ACCOUNT_SRV, ACCOUNT_CIV))
		var/datum/economy_department/department = SSeconomy.get_department(id)
		TEST_ASSERT(length(department.contracts) >= 1, "Нет контрактов у [id]")
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	TEST_ASSERT_EQUAL(length(command.contracts), 0, "У командования контрактов нет")

/// Контракт деятельности засчитывается по записям работы взявшего и платит отделу и исполнителю.
/datum/unit_test/economy_work/activity_contract/Run()
	setup_pair()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/econ_contract/activity/contract = new /datum/econ_contract/activity/medical_discharges(ACCOUNT_MED)
	contract.target = 2
	medical.contracts += contract
	TEST_ASSERT(contract.take(performer_account), "Взят")
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_DISCHARGE_LIGHT, 1, performer)
	TEST_ASSERT(!contract.completed, "Один из двух")
	var/before = performer_account.account_balance
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_DISCHARGE_LIGHT, 1, performer)
	TEST_ASSERT(contract.completed, "Выполнен")
	TEST_ASSERT(performer_account.account_balance - before >= round(contract.reward * SSeconomy.settings.contract_performer_share / 100) - round(contract.reward * SSeconomy.tax_rate / 100), "Доля исполнителя")
	TEST_ASSERT(!(contract in medical.contracts), "Снят с доски")

/// Чужая работа, работа другого отдела и другого типа взятый контракт деятельности не двигают.
/datum/unit_test/economy_work/activity_contract_filters/Run()
	setup_pair()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/econ_contract/activity/contract = new /datum/econ_contract/activity/medical_surgeries(ACCOUNT_MED)
	medical.contracts += contract
	TEST_ASSERT(contract.take(performer_account), "Взят")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	var/datum/bank_account/service = SSeconomy.get_dep_account(ACCOUNT_SRV)
	var/saved_service = service.account_balance
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, stranger)
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_REVIVE, 1, performer)
	SSeconomy.record_work(ACCOUNT_SRV, WORK_MED_SURGERY, 1, performer)
	econ_test_set_balance(service, saved_service)
	TEST_ASSERT_EQUAL(contract.progress, 0, "Засчитана чужая или не та работа")
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, performer)
	TEST_ASSERT_EQUAL(contract.progress, 1, "Своя операция засчитана")
	qdel(contract)

/// Контракт поставки засчитывается отгрузкой подходящего предмета.
/datum/unit_test/economy_delivery_contract/Run()
	var/datum/economy_department/civilian = SSeconomy.get_department(ACCOUNT_CIV)
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_CIV, new /datum/bounty/item/assistant/scooter)
	civilian.contracts.Insert(1, contract)
	var/datum/bounty/item/wanted = contract.bounty
	var/wanted_type = wanted.wanted_types[1]
	var/obj/thing = allocate(wanted_type)
	var/before = civilian.account.account_balance
	TEST_ASSERT(econ_contracts_ship(thing), "Предмет засчитан")
	TEST_ASSERT(contract.completed, "Выполнен (самокат нужен один)")
	TEST_ASSERT(QDELETED(thing), "Засчитанный предмет уходит")
	TEST_ASSERT_EQUAL(civilian.account.account_balance - before, contract.payout(), "Без взявшего вся награда отделу")
	econ_test_set_balance(civilian.account, before)
	var/saved_modifier = SSeconomy.bounty_modifier
	SSeconomy.bounty_modifier = 2
	var/doubled = contract.payout()
	SSeconomy.bounty_modifier = saved_modifier
	TEST_ASSERT_EQUAL(doubled, contract.reward * 2, "Модификатор наград применяется к выплате")

/// Взятый срочный контракт, не выполненный к сроку, снимается при обновлении.
/datum/unit_test/economy_contract_expiry/Run()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/datum/econ_contract/activity/contract = new /datum/econ_contract/activity/service_dishes(ACCOUNT_SRV)
	contract.urgent = TRUE
	contract.deadline = world.time - 1
	service.contracts += contract
	SSeconomy.refresh_contracts()
	TEST_ASSERT(!(contract in service.contracts), "Просроченный снят")

/// Один взятый контракт на счёт, взятая поставка получает срок, контракт всего отдела не берётся, удалённый счёт освобождает контракт.
/datum/unit_test/economy_contract_take_rules/Run()
	var/datum/economy_department/civilian = SSeconomy.get_department(ACCOUNT_CIV)
	var/datum/econ_contract/first = new /datum/econ_contract/delivery(ACCOUNT_CIV, new /datum/bounty/item/assistant/scooter)
	var/datum/econ_contract/second = new /datum/econ_contract/activity/service_cleaning(ACCOUNT_SRV)
	var/datum/econ_contract/department_only = new /datum/econ_contract/activity/engineering_export(ACCOUNT_ENG)
	civilian.contracts += first
	var/datum/bank_account/account = new("econ_test_taker")
	TEST_ASSERT_EQUAL(first.deadline, 0, "У невзятой поставки срока нет")
	TEST_ASSERT(first.take(account), "Первый взят")
	TEST_ASSERT_EQUAL(round(first.deadline - world.time), ECON_CONTRACT_TAKEN_TIME, "Взятая поставка получила срок")
	TEST_ASSERT(!second.take(account), "Второй тем же счётом не взят")
	TEST_ASSERT(!department_only.take(account), "Контракт отдела не берётся")
	var/datum/bank_account/visitor = new("econ_test_visitor")
	visitor.offstation = TRUE
	TEST_ASSERT(!second.take(visitor), "Счёт вне станции контракт не берёт")
	qdel(visitor)
	qdel(account)
	TEST_ASSERT_NULL(first.taker, "Удалённый счёт снят с контракта")
	qdel(first)
	qdel(second)
	qdel(department_only)

/datum/unit_test/economy_special_contract
	var/list/contracts_before

/datum/unit_test/economy_special_contract/Destroy()
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts() - contracts_before)
		if(contract.pinned)
			qdel(contract)
	return ..()

/// Особый заказ ЦК переживает ротацию и не занимает место обычного контракта.
/datum/unit_test/economy_special_contract/Run()
	contracts_before = SSeconomy.all_contracts()
	TEST_ASSERT(try_add_bounty(new /datum/bounty/item/hk47_core), "Заказ выставлен")
	TEST_ASSERT(!try_add_bounty(new /datum/bounty/item/hk47_core), "Второй такой же не выставляется")
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/datum/econ_contract/delivery/special
	for(var/datum/econ_contract/delivery/contract in cargo.contracts)
		if(istype(contract.bounty, /datum/bounty/item/hk47_core))
			special = contract
	TEST_ASSERT_NOTNULL(special, "Заказ на ядро у снабжения")
	TEST_ASSERT(!special.takeable, "Особый заказ не берут")
	SSeconomy.refresh_contracts(force = TRUE)
	TEST_ASSERT(special in cargo.contracts, "Ротация не сняла особый заказ")
	var/regular = 0
	for(var/datum/econ_contract/contract as anything in cargo.contracts)
		if(!contract.pinned)
			regular++
	TEST_ASSERT_EQUAL(regular, SSeconomy.settings.contracts_per_department, "Обычных контрактов полный набор")

/// Настройки контрактов: значения из JSON, нулевая ротация и доля выше 100% отвергаются.
/datum/unit_test/economy_contract_settings/Run()
	var/path = "data/unit_test_economy_contracts.json"
	fdel(path)
	text2file("{\"settings\": {\"contract_rotation_ticks\": 0, \"contract_performer_share\": 101, \"contract_urgent_mult\": 2, \"contracts_per_department\": 2}}", path)
	var/datum/economy_settings/settings = new
	var/list/errors = settings.load(path)
	fdel(path)
	TEST_ASSERT_EQUAL(length(errors), 2, "Ошибки: ротация и доля ([jointext(errors, "; ")])")
	TEST_ASSERT_EQUAL(settings.contract_rotation_ticks, initial(settings.contract_rotation_ticks), "Нулевая ротация принята")
	TEST_ASSERT_EQUAL(settings.contract_performer_share, initial(settings.contract_performer_share), "Доля выше 100% принята")
	TEST_ASSERT_EQUAL(settings.contract_urgent_mult, 2, "Множитель срочности из JSON")
	TEST_ASSERT_EQUAL(settings.contracts_per_department, 2, "Число контрактов из JSON")

/datum/unit_test/economy_contract_machines
	abstract_type = /datum/unit_test/economy_contract_machines
	var/datum/economy_department/civilian
	var/saved_civilian
	var/datum/bank_account/taker_account
	var/mob/living/carbon/human/user
	var/list/contracts_before
	var/list/stashed_contracts

/datum/unit_test/economy_contract_machines/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()

/datum/unit_test/economy_contract_machines/proc/setup()
	civilian = SSeconomy.get_department(ACCOUNT_CIV)
	saved_civilian = civilian.account.account_balance
	contracts_before = SSeconomy.all_contracts()
	user = allocate(/mob/living/carbon/human)
	taker_account = new("econ_test_contractor")
	user.account_id = taker_account.account_id

/datum/unit_test/economy_contract_machines/Destroy()
	econ_test_drop_new_contracts(contracts_before)
	econ_test_restore_contracts(stashed_contracts)
	if(civilian)
		econ_test_set_balance(civilian.account, saved_civilian)
	civilian = null
	QDEL_NULL(taker_account)
	return ..()

/datum/unit_test/economy_contract_machines/proc/post_scooter_contract()
	return post_contract(/datum/bounty/item/assistant/scooter)

/datum/unit_test/economy_contract_machines/proc/post_contract(bounty_type)
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_CIV, new bounty_type)
	civilian.contracts.Insert(1, contract)
	return contract

/// Ошибка манифеста иногда удаляет предмет из ящика, поэтому несколько попыток.
/datum/unit_test/economy_contract_machines/proc/buy_toolbox(turf/where)
	for(var/attempt in 1 to 5)
		var/datum/supply_order/order = new(SSshuttle.supply_packs[/datum/supply_pack/goody/toolbox], "econ_test", "econ_test", "econ_test", "econ_test")
		var/obj/structure/closet/crate/crate = order.generate(where)
		qdel(order)
		allocated += crate
		var/obj/item/storage/toolbox/toolbox = locate() in crate
		if(toolbox)
			return toolbox

/datum/unit_test/economy_contract_machines/proc/click(obj/machinery/console, action, list/params = list())
	var/datum/tgui/window = allocate(/datum/tgui, user, console, "contracts")
	window.status = UI_INTERACTIVE
	usr = user
	console.ui_act(action, params, window)
	usr = null

/datum/unit_test/economy_contract_machines/proc/build_pad(turf/where)
	var/obj/machinery/piratepad/civilian/pad = allocate(/obj/machinery/piratepad/civilian, where)
	pad.warmup_time = 0
	var/obj/machinery/computer/piratepad_control/civilian/console = allocate(/obj/machinery/computer/piratepad_control/civilian, where)
	var/obj/item/multitool/tool = allocate(/obj/item/multitool)
	pad.multitool_act(user, tool)
	console.multitool_act(user, tool)
	TEST_ASSERT(console.linked_pad() == pad, "Пульт связан с падом мультитулом")
	return console

/// Пункт подработки на станции: контракт берётся с пульта, отправка с пада засчитывает поставку и платит взявшему долю.
/datum/unit_test/economy_contract_machines/pad_on_station/Run()
	setup()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/computer/piratepad_control/civilian/console = build_pad(station_turf)
	var/obj/machinery/piratepad/pad = console.linked_pad()
	var/datum/econ_contract/delivery/contract = post_scooter_contract()
	var/list/data = console.ui_data(user)
	TEST_ASSERT_EQUAL(length(data["contracts"]), length(SSeconomy.all_contracts()), "Пульт показывает все контракты")
	TEST_ASSERT_EQUAL(data["my_account"], taker_account.account_id, "Пульт знает счёт пользователя")
	click(console, "take", list("uid" = contract.uid))
	TEST_ASSERT(contract.taker == taker_account, "Контракт взят с пульта")
	var/obj/scooter = allocate(/obj/vehicle/ridden/scooter, get_turf(pad))
	var/obj/item/stack/sheet/metal/leftover = allocate(/obj/item/stack/sheet/metal, get_turf(pad))
	var/civilian_before = civilian.account.account_balance
	var/reward = contract.payout()
	click(console, "send")
	TEST_ASSERT(QDELETED(scooter), "Самокат ушёл ЦК")
	TEST_ASSERT(!QDELETED(leftover) && leftover.loc == get_turf(pad), "Лишнее осталось на паде")
	TEST_ASSERT(contract.completed, "Контракт выполнен")
	var/share = round(reward * SSeconomy.settings.contract_performer_share / 100)
	TEST_ASSERT_EQUAL(taker_account.account_balance, share - round(share * SSeconomy.tax_rate / 100), "Доля взявшего за вычетом налога")
	TEST_ASSERT_EQUAL(civilian.account.account_balance - civilian_before, reward - share, "Остальное отделу")

/// Пад подработки вне станции ничего не засчитывает.
/datum/unit_test/economy_contract_machines/pad_off_station/Run()
	setup()
	TEST_ASSERT(!is_station_level(run_loc_floor_bottom_left.z), "Тестовая резервация не станция")
	var/obj/machinery/computer/piratepad_control/civilian/console = build_pad(run_loc_floor_bottom_left)
	var/datum/econ_contract/delivery/contract = post_scooter_contract()
	var/obj/scooter = allocate(/obj/vehicle/ridden/scooter, run_loc_floor_bottom_left)
	click(console, "send")
	TEST_ASSERT(!QDELETED(scooter), "Самокат остался")
	TEST_ASSERT(!contract.completed, "Контракт не засчитан")
	TEST_ASSERT(findtext(console.status_report, "вне станции"), "Пульт объясняет отказ: [console.status_report]")

/// Консоль контрактов карго показывает доску всех отделов и даёт взять контракт.
/datum/unit_test/economy_contract_machines/cargo_console/Run()
	setup()
	var/obj/machinery/computer/bounty/console = allocate(/obj/machinery/computer/bounty)
	var/datum/econ_contract/delivery/contract = post_scooter_contract()
	var/list/data = console.ui_data(user)
	var/list/shown = list()
	for(var/list/entry as anything in data["contracts"])
		shown += entry["uid"]
	TEST_ASSERT(contract.uid in shown, "Новый контракт на доске карго")
	TEST_ASSERT_EQUAL(length(shown), length(SSeconomy.all_contracts()), "Доска показывает все отделы")
	click(console, "take", list("uid" = contract.uid))
	TEST_ASSERT(contract.taker == taker_account, "Контракт взят с консоли карго")

/// Отгрузка шаттлом: предмет по контракту засчитан и не продан, остальное из ящика продано.
/datum/unit_test/economy_cargo/contract_shuttle/Run()
	setup()
	var/datum/economy_department/civilian = SSeconomy.get_department(ACCOUNT_CIV)
	var/saved_civilian = civilian.account.account_balance
	var/turf/open/floor = shuttle_floor()
	TEST_ASSERT_NOTNULL(floor, "Есть пол шаттла снабжения")
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_CIV, new /datum/bounty/item/assistant/scooter)
	civilian.contracts.Insert(1, contract)
	var/obj/structure/closet/crate/crate = allocate(/obj/structure/closet/crate, floor)
	var/obj/scooter = new /obj/vehicle/ridden/scooter(crate)
	new /obj/item/stack/sheet/metal/fifty(crate)
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(scooter), "Самокат ушёл по контракту")
	TEST_ASSERT(contract.completed, "Контракт выполнен шаттлом")
	TEST_ASSERT(QDELETED(crate), "Ящик продан")
	TEST_ASSERT_EQUAL(length(moved_to(cargo, ECON_EXPORT)), 1, "Металл продан снабжением")
	TEST_ASSERT_EQUAL(civilian.account.account_balance - saved_civilian, contract.reward, "Награда отделу-заказчику")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "контрактам NT"), "ЦК сообщает о приёме: [SSshuttle.centcom_message]")
	econ_test_set_balance(civilian.account, saved_civilian)

/// Ротация снимает старые невзятые контракты без прогресса, а начатую поставку и свежий контракт оставляет.
/datum/unit_test/economy_contract_machines/rotation_by_age/Run()
	setup()
	var/rotation_age = SSeconomy.contract_rotation_age()
	var/datum/econ_contract/delivery/started = post_contract(/datum/bounty/item/assistant/toolbox)
	var/datum/econ_contract/delivery/stale = post_contract(/datum/bounty/item/assistant/scooter)
	var/datum/econ_contract/delivery/fresh = post_contract(/datum/bounty/item/assistant/soap)
	started.created = world.time - rotation_age - 1
	stale.created = world.time - rotation_age - 1
	var/obj/item/storage/toolbox/toolbox = allocate(/obj/item/storage/toolbox/mechanical)
	TEST_ASSERT(econ_contracts_ship(toolbox), "Ящик для инструментов засчитан")
	TEST_ASSERT(started.has_progress() && !started.completed, "Поставка начата, но не закрыта")
	var/list/entry = fresh.ui_entry()
	TEST_ASSERT(abs(entry["rotates_in"] - rotation_age / (1 SECONDS)) <= 1, "Доска показывает время до смены: [entry["rotates_in"]]")
	SSeconomy.refresh_contracts()
	TEST_ASSERT(started in civilian.contracts, "Начатая поставка пережила ротацию")
	TEST_ASSERT(fresh in civilian.contracts, "Свежий контракт не снят раньше своего возраста")
	TEST_ASSERT(QDELETED(stale), "Старый ничей контракт снят")
	SSeconomy.refresh_contracts(force = TRUE)
	TEST_ASSERT(started in civilian.contracts, "Принудительная ротация не снимает начатую поставку")
	entry = started.ui_entry()
	TEST_ASSERT(entry["started"], "Доска помечает начатую поставку")
	TEST_ASSERT(abs(entry["rotates_in"] - (rotation_age * ECON_CONTRACT_STALE_ROTATIONS - rotation_age - 1) / (1 SECONDS)) <= 1, "Доска показывает, когда снимется начатая поставка: [entry["rotates_in"]]")
	started.created = world.time - rotation_age * ECON_CONTRACT_STALE_ROTATIONS - 1
	SSeconomy.refresh_contracts()
	TEST_ASSERT(QDELETED(started), "Начатая ничья поставка снята через [ECON_CONTRACT_STALE_ROTATIONS] возраста ротации")

/// Купленное через снабжение (ящик пака и сборный ящик мелочи) не засчитывается, такой же предмет из другого источника засчитывается.
/datum/unit_test/economy_contract_machines/imported_refused/Run()
	setup()
	var/datum/econ_contract/delivery/contract = post_contract(/datum/bounty/item/assistant/toolbox)
	var/obj/item/storage/toolbox/bought = buy_toolbox(run_loc_floor_bottom_left)
	TEST_ASSERT_NOTNULL(bought, "В ящике пака есть ящик для инструментов")
	TEST_ASSERT(bought.econ_imported, "Купленное помечено")
	TEST_ASSERT(!econ_contracts_ship(bought.loc), "Ящик пака не засчитан")
	TEST_ASSERT(!QDELETED(bought), "Купленное не удалено")
	var/obj/structure/closet/crate/combo = allocate(/obj/structure/closet/crate)
	var/datum/supply_order/order = new(SSshuttle.supply_packs[/datum/supply_pack/goody/toolbox], "econ_test", "econ_test", "econ_test", "econ_test")
	order.generateCombo(combo, "econ_test", list(/obj/item/storage/toolbox/mechanical))
	qdel(order)
	TEST_ASSERT(!econ_contracts_ship(combo), "Сборный ящик мелочи не засчитан")
	var/datum/bounty/item/bounty = contract.bounty
	TEST_ASSERT_EQUAL(bounty.shipped_count, 0, "Ничего купленного не засчитано")
	var/obj/item/storage/toolbox/found = allocate(/obj/item/storage/toolbox/mechanical)
	TEST_ASSERT(econ_contracts_ship(found), "Не купленный ящик засчитан")
	TEST_ASSERT_EQUAL(bounty.shipped_count, 1, "Засчитан один")

/// Пад подработки объясняет, почему купленное через снабжение не ушло.
/datum/unit_test/economy_contract_machines/pad_imported/Run()
	setup()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/computer/piratepad_control/civilian/console = build_pad(station_turf)
	post_contract(/datum/bounty/item/assistant/toolbox)
	var/obj/item/storage/toolbox/bought = buy_toolbox(station_turf)
	click(console, "send")
	TEST_ASSERT(!QDELETED(bought), "Купленное осталось на паде")
	TEST_ASSERT(findtext(console.status_report, "через снабжение"), "Пульт объясняет отказ: [console.status_report]")

/// Машина, собранная из платы, купленной через снабжение, помечена и не засчитывается; из своей платы - засчитывается.
/datum/unit_test/economy_contract_machines/imported_board_machine/Run()
	setup()
	var/datum/econ_contract/delivery/contract = post_contract(/datum/bounty/item/engineering/pacman)
	var/obj/machinery/power/port_gen/pacman/bought = assemble_pacman(TRUE)
	TEST_ASSERT_NOTNULL(bought, "Машина из купленной платы собрана")
	TEST_ASSERT(bought.econ_imported, "Машина унаследовала метку платы")
	TEST_ASSERT(!econ_contracts_ship(bought), "Машина из купленной платы не засчитана")
	var/obj/machinery/power/port_gen/pacman/crafted = assemble_pacman(FALSE)
	TEST_ASSERT_NOTNULL(crafted, "Машина из своей платы собрана")
	TEST_ASSERT(!crafted.econ_imported, "Своя машина не помечена")
	TEST_ASSERT(econ_contracts_ship(crafted), "Машина из своей платы засчитана")
	TEST_ASSERT(contract.completed, "Контракт выполнен")

/datum/unit_test/economy_contract_machines/imported_board_machine/proc/assemble_pacman(imported)
	var/turf/where = imported ? run_loc_floor_bottom_left : run_loc_floor_top_right
	var/obj/structure/frame/machine/frame = allocate(/obj/structure/frame/machine, where)
	var/obj/item/circuitboard/machine/pacman/board = new(frame)
	board.econ_imported = imported
	frame.circuit = board
	frame.state = 3
	frame.req_components = list()
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)
	frame.attackby(screwdriver, user)
	var/obj/machinery/power/port_gen/pacman/machine = locate() in where
	if(machine)
		allocated += machine
	return machine

/// Взятый контракт снимается в срок по таймеру, а до снятия уже не держит слот взявшего и не принимает поставку.
/datum/unit_test/economy_contract_machines/taken_expiry_frees_slot/Run()
	setup()
	var/datum/econ_contract/delivery/expired = post_contract(/datum/bounty/item/assistant/cheesiehonkers)
	var/datum/econ_contract/delivery/next = post_scooter_contract()
	TEST_ASSERT(expired.take(taker_account), "Первый взят")
	TEST_ASSERT(length(expired.active_timers), "Взятие ставит таймер срока")
	expired.deadline = world.time - 1
	TEST_ASSERT(!expired.wants(allocate(/obj/item/reagent_containers/food/snacks/cheesiehonkers)), "Просроченный поставку не принимает")
	TEST_ASSERT(next.take(taker_account), "Просроченный не держит слот до снятия")
	expired.expire()
	TEST_ASSERT(QDELETED(expired), "Просроченный снят по таймеру")
	TEST_ASSERT(!(expired in civilian.contracts), "Снят с доски")

/// Купленное в автомате пад не отправляет и говорит почему; такой же предмет не из автомата уходит.
/datum/unit_test/economy_contract_machines/pad_vended/Run()
	setup()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/computer/piratepad_control/civilian/console = build_pad(station_turf)
	var/obj/machinery/piratepad/pad = console.linked_pad()
	var/datum/econ_contract/delivery/contract = post_contract(/datum/bounty/item/assistant/cheesiehonkers)
	var/list/vended = list()
	for(var/i in 1 to 3)
		var/obj/item/snack = allocate(/obj/item/reagent_containers/food/snacks/cheesiehonkers, get_turf(pad))
		econ_mark_vended(snack, 10)
		vended += snack
	click(console, "send")
	for(var/obj/item/snack as anything in vended)
		TEST_ASSERT(!QDELETED(snack), "Купленное в автомате осталось на паде")
	TEST_ASSERT(findtext(console.status_report, "в автоматах"), "Пульт объясняет отказ: [console.status_report]")
	for(var/i in 1 to 3)
		allocate(/obj/item/reagent_containers/food/snacks/cheesiehonkers, get_turf(pad))
	click(console, "send")
	TEST_ASSERT(contract.completed, "Найденные снеки засчитаны")

/// Отказ от взятого контракта: неначатый уходит с доски, начатый снова свободен без срока взятия, у срочного срок остаётся; чужой не снять, новый - после паузы.
/datum/unit_test/economy_contract_machines/drop/Run()
	setup()
	var/obj/machinery/computer/bounty/console = allocate(/obj/machinery/computer/bounty)
	var/datum/econ_contract/delivery/fresh = post_scooter_contract()
	click(console, "take", list("uid" = fresh.uid))
	TEST_ASSERT(fresh.taker == taker_account, "Контракт взят")
	var/datum/bank_account/stranger = new("econ_test_stranger")
	TEST_ASSERT(!econ_try_drop_contract(user, fresh.uid, stranger)[1], "Чужой контракт снят")
	qdel(stranger)
	TEST_ASSERT(fresh.taker == taker_account, "Чужой отказ снял исполнителя")
	click(console, "drop", list("uid" = fresh.uid))
	TEST_ASSERT(QDELETED(fresh), "Неначатый контракт после отказа остался на доске")

	var/datum/econ_contract/delivery/started = post_scooter_contract()
	var/datum/bounty/item/wanted = started.bounty
	wanted.required_count = 3
	wanted.shipped_count = 1
	TEST_ASSERT(!econ_try_take_contract(user, started.uid, taker_account)[1], "Новый контракт взят сразу после отказа")
	COOLDOWN_RESET(taker_account, contract_drop_cooldown)
	TEST_ASSERT(econ_try_take_contract(user, started.uid, taker_account)[1], "После паузы контракт берётся")
	TEST_ASSERT(started.deadline, "Взятый получил срок")
	click(console, "drop", list("uid" = started.uid))
	TEST_ASSERT(!QDELETED(started) && (started in civilian.contracts), "Начатый контракт ушёл с доски")
	TEST_ASSERT_NULL(started.taker, "Исполнитель остался после отказа")
	TEST_ASSERT_EQUAL(started.deadline, 0, "Срок взятия остался после отказа")
	TEST_ASSERT_EQUAL(wanted.shipped_count, 1, "Отгруженное по контракту пропало")

	var/datum/econ_contract/delivery/urgent = post_scooter_contract()
	urgent.urgent = TRUE
	urgent.set_deadline(world.time + 10 MINUTES)
	var/urgent_deadline = urgent.deadline
	COOLDOWN_RESET(taker_account, contract_drop_cooldown)
	TEST_ASSERT(urgent.take(taker_account), "Срочный взят")
	var/datum/bounty/item/urgent_wanted = urgent.bounty
	urgent_wanted.required_count = 3
	urgent_wanted.shipped_count = 1
	TEST_ASSERT(urgent.drop(taker_account), "От срочного не отказаться")
	TEST_ASSERT_EQUAL(urgent.deadline, urgent_deadline, "Срочный потерял свой срок")
