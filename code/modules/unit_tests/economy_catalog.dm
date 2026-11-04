/// У каждого станционного отдела, кроме командования и гражданских, непустой каталог.
/datum/unit_test/economy_catalog_nonempty/Run()
	for(var/id in list(ACCOUNT_SEC, ACCOUNT_ENG, ACCOUNT_MED, ACCOUNT_SCI, ACCOUNT_CAR, ACCOUNT_SRV))
		var/datum/economy_department/department = SSeconomy.get_department(id)
		TEST_ASSERT(length(department.catalog()), "Пустой каталог [id]")

/datum/unit_test/economy_catalog
	abstract_type = /datum/unit_test/economy_catalog
	var/list/stashed_contracts
	var/list/saved_balances = list()
	var/list/saved_requests = list()
	var/list/saved_auto_approve = list()
	var/list/saved_shoppinglist
	/// Мобы, добавленные в GLOB.player_list как игроки на смене
	var/list/fake_players = list()

/datum/unit_test/economy_catalog/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		saved_balances[id] = department.account.account_balance
		saved_requests[id] = department.requests
		department.requests = list()
		saved_auto_approve[id] = department.auto_approve_after
		department.auto_approve_after = list()
	saved_shoppinglist = SSshuttle.shoppinglist.Copy()
	SSshuttle.shoppinglist.Cut()

/datum/unit_test/economy_catalog/Destroy()
	GLOB.player_list -= fake_players
	fake_players = null
	econ_test_restore_contracts(stashed_contracts)
	for(var/id in saved_balances)
		var/datum/economy_department/department = SSeconomy.departments[id]
		econ_test_set_balance(department.account, saved_balances[id])
		QDEL_LIST(department.requests)
		department.requests = saved_requests[id]
		department.auto_approve_after = saved_auto_approve[id]
	for(var/datum/supply_order/order as anything in SSshuttle.shoppinglist)
		qdel(order)
	SSshuttle.shoppinglist.Cut()
	SSshuttle.shoppinglist += saved_shoppinglist
	return ..()

/datum/unit_test/economy_catalog/proc/make_staff(department_id, list/access)
	var/mob/living/carbon/human/staff = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new("econ_test_[department_id]")
	account.department_id = department_id
	staff.account_id = account.account_id
	allocated += account
	if(access)
		var/obj/item/card/id/card = allocate(/obj/item/card/id)
		card.access = access
		staff.put_in_hands(card)
	return staff

/datum/unit_test/economy_catalog/proc/make_with_job(job_type)
	var/datum/job/job = SSjob.GetJobType(job_type)
	var/mob/living/carbon/human/staff = make_staff(job.paycheck_department, job.access.Copy())
	staff.mind_initialize()
	staff.mind.assigned_role = job.title
	return staff

/datum/unit_test/economy_catalog/proc/new_crates(list/before, crate_type)
	. = list()
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply.shuttle_areas)
		for(var/obj/structure/closet/crate in shuttle_area)
			if(istype(crate, crate_type) && !(crate in before))
				. += crate

/datum/unit_test/economy_catalog/proc/pack_above_auto_limit(datum/economy_department/department)
	for(var/datum/supply_pack/pack as anything in department.catalog())
		if(econ_pack_price(pack) > SSeconomy.settings.auto_approve_limit)
			return pack

/datum/unit_test/economy_catalog/proc/click_cargo(obj/machinery/computer/cargo/console, mob/living/user, action, list/params = list())
	var/datum/tgui/window = allocate(/datum/tgui, user, console, "Cargo")
	window.status = UI_INTERACTIVE
	usr = user
	. = console.ui_act(action, params, window)
	usr = null

/// Заявка: глава одобряет - бюджет списан, заказ встал в очередь карго предоплаченным.
/datum/unit_test/economy_catalog/request_approve/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/engineer = make_staff(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/datum/supply_pack/pack = pack_above_auto_limit(engineering)
	TEST_ASSERT_NOTNULL(pack, "Есть пак дороже лимита автоодобрения")
	var/price = econ_pack_price(pack)
	engineering.account.credit(price, ECON_ADMIN)
	var/datum/econ_request/request = engineering.submit_request(pack, engineer, "тест")
	TEST_ASSERT_NOTNULL(request, "Сотрудник подал заявку")
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_PENDING, "Ждёт главу")
	TEST_ASSERT(!engineering.approve(request, engineer), "Инженер не одобряет")
	var/before = engineering.account.account_balance
	TEST_ASSERT(engineering.approve(request, chief), "Глава одобряет")
	TEST_ASSERT_EQUAL(before - engineering.account.account_balance, price, "Списано с бюджета")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Заказ в очереди")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	TEST_ASSERT_EQUAL(order.prepaid, price, "Предоплачен ценой пака")
	TEST_ASSERT_EQUAL(order.department_id, ACCOUNT_ENG, "Заказ записан на отдел")
	TEST_ASSERT(!engineering.approve(request, chief), "Одобренную заявку второй раз не одобрить")
	TEST_ASSERT(!engineering.deny(request, chief), "Одобренную заявку не отклонить")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Повторное одобрение не заказывает")

/// Отказы: чужой отдел не подаёт, без денег заявка ждёт, отклонённую не одобрить, очередь заявок одного сотрудника ограничена.
/datum/unit_test/economy_catalog/request_refusals/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/datum/supply_pack/pack = pack_above_auto_limit(engineering)
	var/mob/living/carbon/human/outsider = make_staff(ACCOUNT_MED)
	TEST_ASSERT_NULL(engineering.submit_request(pack, outsider, "тест"), "Медик не подаёт заявку инженерам")
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/supply_pack/foreign
	for(var/datum/supply_pack/candidate as anything in medical.catalog())
		foreign = candidate
		break
	var/mob/living/carbon/human/engineer = make_staff(ACCOUNT_ENG)
	TEST_ASSERT_NULL(engineering.submit_request(foreign, engineer, "тест"), "Чужой каталог не заказать")
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	econ_test_set_balance(engineering.account, 0)
	var/datum/econ_request/poor = engineering.submit_request(pack, engineer, "тест")
	TEST_ASSERT(!engineering.approve(poor, chief), "Без денег не одобрить")
	TEST_ASSERT_EQUAL(poor.status, ECON_REQUEST_PENDING, "Заявка ждёт денег")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Без денег заказа нет")
	TEST_ASSERT(!engineering.deny(poor, engineer), "Инженер не отклоняет")
	TEST_ASSERT(engineering.deny(poor, chief), "Глава отклоняет")
	engineering.account.credit(econ_pack_price(pack), ECON_ADMIN)
	TEST_ASSERT(!engineering.approve(poor, chief), "Отклонённую не одобрить")
	for(var/i in 1 to SSeconomy.settings.request_pending_per_requester)
		TEST_ASSERT_NOTNULL(engineering.submit_request(pack, engineer, "тест"), "Заявка [i] принята")
	TEST_ASSERT_NULL(engineering.submit_request(pack, engineer, "тест"), "Сверх лимита ждущих заявок не принять")

/// Без начальства на смене дешёвая заявка одобряется сама, но не чаще перерыва на сотрудника.
/datum/unit_test/economy_catalog/request_auto_approve/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/supply_pack/cheap
	for(var/datum/supply_pack/pack as anything in medical.catalog())
		if(econ_pack_price(pack) <= SSeconomy.settings.auto_approve_limit)
			cheap = pack
			break
	TEST_ASSERT_NOTNULL(cheap, "Есть пак дешевле лимита автоодобрения")
	medical.account.credit(econ_pack_price(cheap) * 2, ECON_ADMIN)
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED)
	TEST_ASSERT(!medical.has_approver_on_shift(), "Начальства на смене нет")
	var/datum/econ_request/request = medical.submit_request(cheap, doctor, "тест")
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_APPROVED, "Автоодобрено")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Заказ в очереди")
	var/datum/econ_request/second = medical.submit_request(cheap, doctor, "тест")
	TEST_ASSERT_EQUAL(second.status, ECON_REQUEST_PENDING, "Второе автоодобрение ждёт перерыва")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Второго заказа нет")

/// Общая консоль снабжения не показывает и не заказывает эксклюзивы отделов; отмена предоплаченного заказа возвращает деньги отделу.
/datum/unit_test/economy_catalog/cargo_console/Run()
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/cargo_tech = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/supply_pack/exclusive = SSshuttle.supply_packs[/datum/supply_pack/department/engineering_export_node]
	TEST_ASSERT_NOTNULL(exclusive, "Эксклюзив инженеров зарегистрирован")
	var/list/static_data = console.ui_static_data(cargo_tech)
	for(var/group in static_data["supplies"])
		for(var/list/entry as anything in static_data["supplies"][group]["packs"])
			var/datum/supply_pack/shown = SSshuttle.supply_packs[entry["id"]]
			TEST_ASSERT(!shown.department_catalog, "Консоль показала эксклюзив [shown.name]")
	click_cargo(console, cargo_tech, "add", list("id" = "[exclusive.type]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Эксклюзив отдела не заказать с общей консоли")
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/price = econ_pack_price(exclusive)
	engineering.account.credit(price, ECON_ADMIN)
	var/before = engineering.account.account_balance
	TEST_ASSERT(engineering.order_pack(exclusive, chief, "тест"), "Глава заказал эксклюзив")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	var/list/cart = console.ui_data(cargo_tech)["cart"]
	TEST_ASSERT_EQUAL(cart[1]["cost"], 0, "В корзине карго предоплаченный заказ ничего не стоит")
	click_cargo(console, cargo_tech, "remove", list("id" = "[order.id]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Заказ снят")
	TEST_ASSERT_EQUAL(engineering.account.account_balance, before, "Деньги вернулись отделу")
	qdel(order)
	TEST_ASSERT(engineering.order_pack(exclusive, chief, "тест"), "Второй заказ")
	click_cargo(console, cargo_tech, "clear")
	TEST_ASSERT_EQUAL(engineering.account.account_balance, before, "Очистка корзины возвращает деньги отделу")

/// Доставка шаттлом: предоплаченный заказ никого не списывает повторно, содержимое помечено закупкой и не идёт в контракт.
/datum/unit_test/economy_catalog/shuttle_delivery/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/department/engineering_export_node]
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	engineering.account.credit(econ_pack_price(pack), ECON_ADMIN)
	TEST_ASSERT(engineering.order_pack(pack, chief, "тест"), "Заказ оформлен")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/cargo_before = cargo.account_balance
	var/engineering_before = engineering.account.account_balance
	var/list/crates_before = new_crates(list(), /obj/structure/closet)
	SSshuttle.supply.buy()
	SSshuttle.orderhistory -= order
	TEST_ASSERT(!(order in SSshuttle.shoppinglist), "Заказ отгружен")
	TEST_ASSERT_EQUAL(cargo.account_balance, cargo_before, "Карго не платит за заказ отдела")
	TEST_ASSERT_EQUAL(engineering.account.account_balance, engineering_before, "Отдел не платит второй раз")
	var/obj/structure/closet/crate/delivered
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply.shuttle_areas)
		for(var/obj/structure/closet/crate/crate in shuttle_area)
			if(!(crate in crates_before))
				delivered = crate
	TEST_ASSERT_NOTNULL(delivered, "Ящик на шаттле")
	allocated += delivered.GetAllContents()
	qdel(order)
	var/obj/item/paper/fluff/jobs/cargo/manifest/manifest = locate() in delivered
	var/obj/item/stack/cable_coil/cable = locate() in delivered
	TEST_ASSERT(cable || (manifest.errors & MANIFEST_ERROR_ITEM), "В ящике кабель")
	for(var/obj/item/thing in delivered)
		if(!istype(thing, /obj/item/paper))
			TEST_ASSERT(thing.econ_imported, "[thing] помечен закупкой")
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_ENG, new /datum/bounty/item/engineering/cablecoil)
	engineering.contracts += contract
	TEST_ASSERT(!econ_contracts_ship(delivered), "Купленное через каталог не засчитано")
	var/datum/bounty/item/bounty = contract.bounty
	TEST_ASSERT_EQUAL(bounty.shipped_count, 0, "Контракт ничего не получил")

/// Бридж-офицер с доступом ГП не управляет чужим отделом и не считается начальством на смене; ГП управляет по должности.
/datum/unit_test/economy_catalog/bridge_officer/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/supply_pack/pack = pack_above_auto_limit(medical)
	medical.account.credit(econ_pack_price(pack) * 2, ECON_ADMIN)
	var/mob/living/carbon/human/officer = make_with_job(/datum/job/bridgeofficer)
	var/obj/item/card/id/officer_card = officer.get_idcard(TRUE)
	TEST_ASSERT(ACCESS_HOP in officer_card.GetAccess(), "У бридж-офицера доступ ГП")
	TEST_ASSERT(!medical.can_manage(officer), "Бридж-офицер не управляет медициной")
	TEST_ASSERT(!medical.order_pack(pack, officer, "тест"), "Бридж-офицер не заказывает за медицину")
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED)
	var/datum/econ_request/request = medical.submit_request(pack, doctor, "тест")
	TEST_ASSERT(!medical.approve(request, officer), "Бридж-офицер не одобряет заявку медицины")
	GLOB.player_list += officer
	fake_players += officer
	TEST_ASSERT(!medical.has_approver_on_shift(), "Бридж-офицер на смене не начальство медицины")
	var/mob/living/carbon/human/hop = make_with_job(/datum/job/hop)
	TEST_ASSERT(medical.can_manage(hop), "ГП управляет медициной")
	TEST_ASSERT(medical.approve(request, hop), "ГП одобряет заявку медицины")
	GLOB.player_list += hop
	fake_players += hop
	TEST_ASSERT(medical.has_approver_on_shift(), "ГП на смене - начальство")
	var/mob/living/carbon/human/cmo = make_with_job(/datum/job/cmo)
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	TEST_ASSERT(medical.can_manage(cmo), "Главврач управляет медициной")
	TEST_ASSERT(!engineering.can_manage(cmo), "Главврач не управляет инженерией")

/// Разжалованный ГП без доступа ГП на карте не управляет отделами и казной и не считается начальством на смене.
/datum/unit_test/economy_catalog/demoted_hop/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	var/mob/living/carbon/human/hop = make_with_job(/datum/job/hop)
	TEST_ASSERT(medical.can_manage(hop), "ГП с доступом не управляет медициной")
	var/obj/item/card/id/card = hop.get_idcard(TRUE)
	card.access -= ACCESS_HOP
	TEST_ASSERT(!medical.can_manage(hop), "Разжалованный ГП управляет медициной")
	TEST_ASSERT(!command.can_manage(hop), "Разжалованный ГП управляет казной")
	GLOB.player_list += hop
	fake_players += hop
	TEST_ASSERT(!medical.has_approver_on_shift(), "Разжалованный ГП считается начальством на смене")

/// Заявка, запрос в казну и журнал работ называют человека по ID-карте, а не настоящим именем.
/datum/unit_test/economy_catalog/public_names/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED, list(ACCESS_CMO))
	doctor.real_name = "Econ Real Name"
	var/obj/item/card/id/card = doctor.get_idcard(TRUE)
	card.registered_name = "Econ Card Name"
	var/datum/econ_request/request = medical.submit_request(pack_above_auto_limit(medical), doctor, "тест")
	TEST_ASSERT_EQUAL(request?.requester, "Econ Card Name", "Заявка раскрыла настоящее имя")
	var/datum/econ_request/treasury/treasury_request = medical.request_treasury(100, "тест", doctor)
	TEST_ASSERT_EQUAL(treasury_request?.requester, "Econ Card Name", "Запрос в казну раскрыл настоящее имя")
	SSeconomy.treasury_requests -= treasury_request
	qdel(treasury_request)
	TEST_ASSERT(SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, doctor), "Работа не оплачена")
	var/list/last_work = medical.work_log[length(medical.work_log)]
	medical.work_log -= list(last_work)
	TEST_ASSERT_EQUAL(last_work["performer"], "Econ Card Name", "Журнал работ раскрыл настоящее имя")

/// Шкафчики материалов карго и отдела в одной отгрузке приходят раздельно и полными.
/datum/unit_test/economy_catalog/locker_bundles/Run()
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/glass50]
	TEST_ASSERT(ispath(pack.crate_type, /obj/structure/closet/secure_closet/cargo), "Стекло приходит в шкафчике")
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	TEST_ASSERT(pack in engineering.catalog(), "Стекло в каталоге инженерии")
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	cargo.credit(econ_pack_price(pack), ECON_ADMIN)
	engineering.account.credit(econ_pack_price(pack), ECON_ADMIN)
	SSshuttle.shoppinglist += new /datum/supply_order(pack, "econ_test", "econ_test", "econ_test", "тест")
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	TEST_ASSERT(engineering.order_pack(pack, chief, "тест"), "Инженерия заказала стекло")
	var/list/before = new_crates(list(), /obj/structure/closet)
	var/list/orders = SSshuttle.shoppinglist.Copy()
	SSshuttle.supply.buy()
	SSshuttle.orderhistory -= orders
	var/list/lockers = new_crates(before, /obj/structure/closet/secure_closet/cargo)
	for(var/obj/structure/closet/locker as anything in lockers)
		allocated += locker.GetAllContents()
	TEST_ASSERT_EQUAL(length(lockers), 2, "Два шкафчика: карго и инженерии")
	for(var/obj/structure/closet/locker as anything in lockers)
		TEST_ASSERT_NOTNULL(locate(/obj/item/paper/fluff/jobs/cargo/manifest) in locker, "Шкафчик [locker.name] собран по заказу")

/// Ни один пак каталога не продаётся на экспорт по базе дороже своей цены в начале раунда, а доставленный - дороже цены на дне рынка со скидкой высшей ступени, даже горячим и лучшему покупателю; разовые бонусы открытия (семена) засчитываются один раз.
/datum/unit_test/economy_catalog/no_export_farm
	var/list/saved_discovered
	var/list/saved_market

/datum/unit_test/economy_catalog/no_export_farm/New()
	. = ..()
	saved_market = econ_test_swap_market()
	if(!length(GLOB.exports_list))
		setupExports()
	var/datum/export/seed/seed_export = locate() in GLOB.exports_list
	saved_discovered = seed_export.discoveredPlants.Copy()

/datum/unit_test/economy_catalog/no_export_farm/Destroy()
	var/datum/export/seed/seed_export = locate() in GLOB.exports_list
	seed_export.discoveredPlants.Cut()
	for(var/plant in saved_discovered)
		seed_export.discoveredPlants[plant] = saved_discovered[plant]
	econ_test_restore_market(saved_market)
	return ..()

/datum/unit_test/economy_catalog/no_export_farm/Run()
	var/list/catalog_packs = list()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		for(var/datum/supply_pack/pack as anything in department.catalog())
			if(!econ_test_explodes_on_delete(pack))
				catalog_packs[pack] = id
	for(var/datum/supply_pack/pack as anything in catalog_packs)
		var/price = econ_pack_price(pack)
		var/value = export_value(pack, TRUE)
		if(value >= price)
			export_value(pack, FALSE)
			value = export_value(pack, TRUE)
		TEST_ASSERT(value < price, "[pack.name] ([catalog_packs[pack]]) раз за разом продаётся за [value] при цене [price]")
	econ_test_partner_extremes()
	var/list/farms = list()
	for(var/datum/supply_pack/pack as anything in catalog_packs)
		for(var/id in SSmarket.commodities)
			var/datum/commodity/commodity = SSmarket.commodities[id]
			commodity.price_factor = MARKET_PRICE_MIN
			commodity.hot_mult = MARKET_HOT_MULT_MAX
			commodity.demand = 1
		var/price = econ_pack_price(pack)
		var/value = export_value(pack, TRUE, delivered = TRUE)
		if(value >= price)
			farms += "[pack.name] ([catalog_packs[pack]]): [value] кр. при цене [price]"
	TEST_ASSERT(!length(farms), "Доставленное окупает закупку: [jointext(farms, "; ")]")

/// Выручка за содержимое пака: по базе или, если delivered, помеченное закупкой как из шаттла и по рынку.
/datum/unit_test/economy_catalog/no_export_farm/proc/export_value(datum/supply_pack/pack, dry_run, delivered = FALSE)
	var/obj/structure/closet/crate/crate = pack.generate(run_loc_floor_bottom_left)
	var/list/generated = crate.GetAllContents()
	if(delivered)
		econ_mark_imported(crate)
	var/datum/export_report/report = export_item_and_contents(crate, EXPORT_CARGO | EXPORT_CONTRABAND | EXPORT_EMAG, apply_elastic = delivered, delete_unsold = FALSE, dry_run = dry_run)
	. = econ_export_report_value(report)
	for(var/atom/movable/thing as anything in generated)
		if(!QDELETED(thing))
			qdel(thing)
	econ_test_clear_turf(run_loc_floor_bottom_left)
