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
	var/list/saved_requestlist
	var/list/saved_announce = list()
	var/list/saved_supply_notice = list()
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
		saved_announce[id] = department.request_announce_cooldown
		department.request_announce_cooldown = 0
		saved_supply_notice[id] = department.supply_notice_cooldown
		department.supply_notice_cooldown = 0
	saved_shoppinglist = SSshuttle.shoppinglist.Copy()
	SSshuttle.shoppinglist.Cut()
	saved_requestlist = SSshuttle.requestlist.Copy()
	SSshuttle.requestlist.Cut()

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
		department.request_announce_cooldown = saved_announce[id]
		department.supply_notice_cooldown = saved_supply_notice[id]
	for(var/datum/supply_order/order as anything in SSshuttle.shoppinglist)
		qdel(order)
	SSshuttle.shoppinglist.Cut()
	SSshuttle.shoppinglist += saved_shoppinglist
	QDEL_LIST(SSshuttle.requestlist)
	SSshuttle.requestlist += saved_requestlist
	return ..()

/datum/unit_test/economy_catalog/proc/make_staff(department_id, list/access, account_type = /datum/bank_account)
	var/mob/living/carbon/human/staff = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new account_type("econ_test_[department_id]")
	account.department_id = department_id
	staff.account_id = account.account_id
	allocated += account
	if(access)
		var/obj/item/card/id/card = allocate(/obj/item/card/id)
		card.access = access
		staff.put_in_hands(card)
	return staff

/datum/unit_test/economy_catalog/proc/make_with_job(job_type, account_type = /datum/bank_account)
	var/datum/job/job = SSjob.GetJobType(job_type)
	var/mob/living/carbon/human/staff = make_staff(job.paycheck_department, job.access | job.get_access(), account_type)
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

/datum/unit_test/economy_catalog/proc/click_cargo(datum/console, mob/living/user, action, list/params = list())
	var/datum/tgui/window = allocate(/datum/tgui, user, console, "Cargo")
	window.status = UI_INTERACTIVE
	usr = user
	. = console.ui_act(action, params, window)
	usr = null

/// Гарнитура, которая запоминает "канал: сообщение" вместо передачи; без имени канала - "общий", как и уходит в эфир общий канал.
/obj/item/radio/headset/econ_test_spy
	var/list/heard = list()

/obj/item/radio/headset/econ_test_spy/talk_into(atom/movable/M, message, channel, list/spans, datum/language/language)
	heard += "[isnull(channel) ? "общий" : channel]: [message]"
	return ITALICS | REDUCE_RANGE

/// Счёт, который запоминает сообщения карты вместо показа.
/datum/bank_account/econ_test_ear
	var/list/heard = list()

/datum/bank_account/econ_test_ear/bank_card_talk(message, force, talk_sound, balloon, quiet = FALSE)
	heard += message

/// Рабочая система оповещения станции первой в списке, с гарнитурой-шпионом.
/datum/unit_test/economy_catalog/proc/spy_announcer()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/obj/machinery/announcement_system/announcer = allocate(/obj/machinery/announcement_system, locate(2, 2, station_z))
	announcer.machine_stat = NONE
	qdel(announcer.radio)
	var/obj/item/radio/headset/econ_test_spy/spy = new(announcer)
	announcer.radio = spy
	GLOB.announcement_systems -= announcer
	GLOB.announcement_systems.Insert(1, announcer)
	TEST_ASSERT(announcer.is_operational(), "Система оповещений станции работает")
	return spy

/datum/unit_test/economy_catalog/proc/on_shift(mob/living/carbon/human/player)
	GLOB.player_list += player
	fake_players += player

/// Пак каталога отдела, который видно в окне снабжения и есть у партнёров: дешевле лимита автоодобрения или дороже.
/datum/unit_test/economy_catalog/proc/window_pack(datum/economy_department/department, cheap)
	for(var/datum/supply_pack/pack as anything in department.catalog())
		if(pack.department_catalog || econ_pack_unavailable(pack))
			continue
		if(cheap == (econ_pack_price(pack) <= SSeconomy.settings.auto_approve_limit))
			return pack

/// Сотрудник медицины подаёт с консоли заявок пак своего каталога: заявка уходит медицине, без главы недорогая оплачивается бюджетом медицины сама, при главе на смене дорогие ждут его до лимита сотрудника, канал медицины и карта главы оповещены.
/datum/unit_test/economy_catalog/request_console_department/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/obj/machinery/computer/cargo/request/console = allocate(/obj/machinery/computer/cargo/request)
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED)
	var/datum/supply_pack/cheap = window_pack(medical, TRUE)
	var/datum/supply_pack/expensive = window_pack(medical, FALSE)
	TEST_ASSERT(cheap && expensive, "В каталоге медицины есть паки по обе стороны лимита автоодобрения")
	TEST_ASSERT(!medical.has_approver_on_shift(), "Начальства на смене нет")
	var/list/static_entry
	var/list/supplies = console.ui_static_data(doctor)["supplies"]
	for(var/group in supplies)
		for(var/list/entry as anything in supplies[group]["packs"])
			if(entry["id"] == cheap.type)
				static_entry = entry
	TEST_ASSERT_NOTNULL(static_entry, "Пак медицины в окне")
	TEST_ASSERT_EQUAL(static_entry["budget"], ACCOUNT_MED, "Окно помечает пак каталога медицины")
	var/list/budget = console.ui_data(doctor)["budget_request"]
	TEST_ASSERT_NOTNULL(budget, "Окно знает отдел подающего")
	TEST_ASSERT(budget["id"] == ACCOUNT_MED && !budget["manager"] && !budget["any"], "Окно: бюджет медицины, сотрудник не глава")
	var/price = round(econ_pack_price(cheap))
	econ_test_set_balance(medical.account, price + 1)
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/cargo_before = cargo.account_balance
	click_cargo(console, doctor, "add", list("id" = "[cheap.type]", "reason" = "Бинты"))
	TEST_ASSERT_EQUAL(length(SSshuttle.requestlist), 0, "Заявка на пак медицины ушла снабжению")
	TEST_ASSERT_EQUAL(length(medical.requests), 1, "Заявка в отделе")
	var/datum/econ_request/request = medical.requests[1]
	TEST_ASSERT_EQUAL(request.reason, "Бинты", "Причина из окна")
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_APPROVED, "Без главы недорогой пак одобрен сам")
	TEST_ASSERT_EQUAL(medical.account.account_balance, 1, "Пак оплачен бюджетом медицины")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Оплаченный заказ в очереди снабжения")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	TEST_ASSERT(order.prepaid == price && order.department_id == ACCOUNT_MED, "Заказ предоплачен медициной")
	TEST_ASSERT_EQUAL(cargo.account_balance, cargo_before, "Снабжение не платило")
	var/mob/living/carbon/human/cmo = make_with_job(/datum/job/cmo, /datum/bank_account/econ_test_ear)
	on_shift(cmo)
	click_cargo(console, doctor, "add", list("id" = "[expensive.type]", "reason" = "Операционная", "amount" = 5))
	var/limit = SSeconomy.settings.request_pending_per_requester
	var/datum/bank_account/doctor_account = econ_account_of(doctor)
	TEST_ASSERT_EQUAL(medical.pending_requests_of(doctor_account.account_id), limit, "По штуке на заявку, пока не упёрлись в лимит сотрудника")
	TEST_ASSERT_EQUAL(length(medical.requests), limit + 1, "Сверх лимита заявок нет")
	TEST_ASSERT_EQUAL(length(SSshuttle.requestlist), 0, "Дорогой пак при главе на смене не ушёл снабжению")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Дорогой пак ждёт главы")
	TEST_ASSERT(!COOLDOWN_FINISHED(medical, request_announce_cooldown), "Канал медицины не оповещён о ждущей заявке")
	TEST_ASSERT(console.radio.channels[RADIO_CHANNEL_MEDICAL], "Консоль не говорила в канал медицины")
	var/datum/bank_account/econ_test_ear/cmo_ear = econ_account_of(cmo)
	TEST_ASSERT_EQUAL(length(cmo_ear.heard), 1, "Главврачу на смене карта сообщила о заявке")
	TEST_ASSERT(findtext(cmo_ear.heard[1], expensive.name), "Карта главврача назвала пак: [cmo_ear.heard[1]]")

/// С консоли заявок и с КПК снабжению уходят паки вне каталога отдела подающего, заявки людей без отдела и дорогие паки без начальства на смене; капитан заказывает пак медицины сразу за её бюджет, окно не называет ему бюджет отдела его счёта.
/datum/unit_test/economy_catalog/request_console_cargo/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/obj/machinery/computer/cargo/request/console = allocate(/obj/machinery/computer/cargo/request)
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED)
	var/datum/supply_pack/metal = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	TEST_ASSERT_EQUAL(econ_pack_catalog_department(metal), ACCOUNT_ENG, "Металл в каталоге инженерии")
	click_cargo(console, doctor, "add", list("id" = "[metal.type]", "reason" = "Ремонт"))
	TEST_ASSERT_EQUAL(length(SSshuttle.requestlist), 1, "Пак чужого каталога - заявка снабжению")
	TEST_ASSERT_EQUAL(length(medical.requests), 0, "Пак чужого каталога не ушёл медицине")
	var/datum/supply_pack/expensive = window_pack(medical, FALSE)
	var/mob/living/carbon/human/visitor = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(console.ui_data(visitor)["budget_request"], "Без отдела окно не обещает бюджет отдела")
	click_cargo(console, visitor, "add", list("id" = "[expensive.type]", "reason" = "Нужно"))
	TEST_ASSERT_EQUAL(length(SSshuttle.requestlist), 2, "Заявка без отдела - снабжению")
	TEST_ASSERT_EQUAL(length(medical.requests), 0, "Заявка без отдела не ушла медицине")
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda/cargo)
	var/datum/computer_file/program/cargo_orders/app = locate() in pda.get_all_files()
	TEST_ASSERT_NOTNULL(app, "Приложение снабжения на КПК")
	TEST_ASSERT(!medical.has_approver_on_shift(), "Начальства медицины на смене нет")
	click_cargo(app, doctor, "add", list("id" = "[expensive.type]", "reason" = "С КПК"))
	TEST_ASSERT_EQUAL(length(SSshuttle.requestlist), 3, "Дорогую заявку с КПК без начальства на смене рассматривает снабжение")
	TEST_ASSERT_EQUAL(length(medical.requests), 0, "Дорогая заявка без начальства не зависла в отделе")
	var/datum/supply_pack/cheap = window_pack(medical, TRUE)
	econ_test_set_balance(medical.account, round(econ_pack_price(cheap)))
	click_cargo(app, doctor, "add", list("id" = "[cheap.type]", "reason" = "С КПК"))
	TEST_ASSERT_EQUAL(length(SSshuttle.requestlist), 3, "Недорогая заявка с КПК на пак медицины ушла снабжению")
	TEST_ASSERT_EQUAL(length(medical.requests), 1, "Заявка с КПК в отделе")
	TEST_ASSERT_NULL(app.radio?.loc, "Радио приложения не осталось в КПК")
	var/mob/living/carbon/human/captain = make_with_job(/datum/job/captain)
	var/list/budget = console.ui_data(captain)["budget_request"]
	TEST_ASSERT_NOTNULL(budget, "Капитану окно обещает бюджет отдела")
	TEST_ASSERT(budget["any"] && budget["manager"] && budget["approver"], "Капитану окно обещает бюджет отдела пака")
	TEST_ASSERT(isnull(budget["id"]) && isnull(budget["name"]) && isnull(budget["balance"]), "Капитану окно не называет бюджет отдела его счёта: [budget["name"]]")
	econ_test_set_balance(medical.account, round(econ_pack_price(expensive)))
	click_cargo(console, captain, "add", list("id" = "[expensive.type]", "reason" = "Срочно"))
	TEST_ASSERT_EQUAL(length(medical.requests), 2, "Заявка капитана в отделе")
	var/datum/econ_request/request = medical.requests[2]
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_APPROVED, "Заявку капитана бюджет оплатил сразу")
	TEST_ASSERT_EQUAL(medical.account.account_balance, 0, "Списано с бюджета медицины")
	for(var/obj/item/paper/requisition in get_turf(console))
		qdel(requisition)

/// Без начальства на смене окно знает, что одобрить некому: дорогой пак с консоли уходит снабжению, недорогой в перерыве автоодобрения ждёт и одобрится сам; ответ на пачку заявок собран по-человечески.
/datum/unit_test/economy_catalog/request_window_no_approver/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/obj/machinery/computer/cargo/request/console = allocate(/obj/machinery/computer/cargo/request)
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED)
	var/datum/supply_pack/cheap = window_pack(medical, TRUE)
	var/datum/supply_pack/expensive = window_pack(medical, FALSE)
	TEST_ASSERT(!medical.has_approver_on_shift(), "Начальства на смене нет")
	var/list/budget = console.ui_data(doctor)["budget_request"]
	TEST_ASSERT(budget && !isnull(budget["approver"]) && !budget["approver"], "Окно знает, что одобрить некому")
	click_cargo(console, doctor, "add", list("id" = "[expensive.type]", "reason" = "Операционная"))
	TEST_ASSERT_EQUAL(length(SSshuttle.requestlist), 1, "Дорогой пак без начальства - заявка снабжению")
	TEST_ASSERT_EQUAL(length(medical.requests), 0, "Дорогой пак без начальства не завис в отделе")
	var/mob/living/carbon/human/cmo = make_with_job(/datum/job/cmo)
	on_shift(cmo)
	budget = console.ui_data(doctor)["budget_request"]
	TEST_ASSERT(budget["approver"], "С главой на смене окно знает, что одобрить есть кому")
	TEST_ASSERT_EQUAL(econ_request_department(doctor, expensive), medical, "С главой на смене дорогой пак - заявка отделу")
	GLOB.player_list -= cmo
	econ_test_set_balance(medical.account, round(econ_pack_price(cheap)) * 3)
	var/answer = medical.submit_window_requests(cheap, doctor, "Бинты", 3)
	TEST_ASSERT(istext(answer), "Ответ подавшему - строка")
	TEST_ASSERT(findtext(answer, "1 одобрена и оплачена из бюджета отдела"), "Ответ про одобренную: [answer]")
	TEST_ASSERT(findtext(answer, "2 ждут: начальства отдела на смене нет, одобрятся сами через [SSeconomy.settings.auto_approve_wait_minutes] мин."), "Ответ про ждущие без начальства: [answer]")
	TEST_ASSERT(!findtext(answer, "решения главы"), "Без начальства ответ не обещает решения главы: [answer]")
	for(var/obj/item/paper/requisition in get_turf(console))
		qdel(requisition)

/// Одобренную заявку отдела и заказ главы снабжение слышит в своём канале: отдел, пак, без причины заявки, не чаще кулдауна отдела.
/datum/unit_test/economy_catalog/request_supply_notice/Run()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/engineer = make_staff(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/datum/supply_pack/pack = pack_above_auto_limit(engineering)
	econ_test_set_balance(engineering.account, round(econ_pack_price(pack)) * 2)
	var/datum/econ_request/request = engineering.submit_request(pack, engineer, "Секретная причина")
	spy.heard.Cut()
	TEST_ASSERT(engineering.approve(request, chief), "Глава одобряет")
	var/expected = "[RADIO_CHANNEL_SUPPLY]: Отдел \"[engineering.name]\" оплатил заказ: [pack.name], в корзине снабжения."
	TEST_ASSERT(expected in spy.heard, "Снабжение слышит об оплаченном заказе: [jointext(spy.heard, "; ")]")
	for(var/line in spy.heard)
		TEST_ASSERT(!findtext(line, "Секретная причина"), "Причина заявки ушла в эфир: [line]")
	spy.heard.Cut()
	TEST_ASSERT(engineering.order_pack(pack, chief, "тест"), "Глава заказывает второй раз")
	TEST_ASSERT(!length(spy.heard), "Второй заказ в кулдаун не объявлен: [jointext(spy.heard, "; ")]")

/// О заявке, ждущей решения, отдел оповещает сам, откуда бы её ни подали: канал отдела через систему оповещения и карты начальства на смене, кроме мёртвых; кулдаун общий.
/datum/unit_test/economy_catalog/request_pending_announce/Run()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED)
	var/mob/living/carbon/human/cmo = make_with_job(/datum/job/cmo, /datum/bank_account/econ_test_ear)
	var/mob/living/carbon/human/hop = make_with_job(/datum/job/hop, /datum/bank_account/econ_test_ear)
	var/mob/living/carbon/human/dead_captain = make_with_job(/datum/job/captain, /datum/bank_account/econ_test_ear)
	var/mob/living/carbon/human/offline_captain = make_with_job(/datum/job/captain, /datum/bank_account/econ_test_ear)
	on_shift(cmo)
	on_shift(hop)
	on_shift(dead_captain)
	dead_captain.death()
	var/datum/supply_pack/pack = pack_above_auto_limit(medical)
	econ_test_set_balance(medical.account, 0)
	var/datum/econ_request/request = medical.submit_request(pack, doctor, "Операционная")
	TEST_ASSERT_EQUAL(request?.status, ECON_REQUEST_PENDING, "Заявка ждёт решения")
	var/channel_line
	for(var/line in spy.heard)
		if(findtext(line, "[RADIO_CHANNEL_MEDICAL]: ") == 1)
			channel_line = line
	TEST_ASSERT(channel_line && findtext(channel_line, "№[request.uid]") && findtext(channel_line, pack.name), "Канал медицины слышит о заявке: [jointext(spy.heard, "; ")]")
	TEST_ASSERT(!findtext(channel_line, "Операционная"), "Причина заявки ушла в эфир: [channel_line]")
	for(var/mob/living/carbon/human/manager as anything in list(cmo, hop))
		var/datum/bank_account/econ_test_ear/ear = econ_account_of(manager)
		TEST_ASSERT_EQUAL(length(ear.heard), 1, "Карта [manager.mind.assigned_role] на смене сообщила о заявке")
	var/datum/bank_account/econ_test_ear/dead_ear = econ_account_of(dead_captain)
	TEST_ASSERT(!length(dead_ear.heard), "Мёртвому капитану карта не сообщает")
	var/datum/bank_account/econ_test_ear/offline_ear = econ_account_of(offline_captain)
	TEST_ASSERT(!length(offline_ear.heard), "Капитану не на смене карта не сообщает")
	spy.heard.Cut()
	medical.submit_request(pack, doctor, "Ещё")
	TEST_ASSERT(!length(spy.heard), "Вторая заявка в кулдаун не объявлена: [jointext(spy.heard, "; ")]")
	var/datum/bank_account/econ_test_ear/cmo_ear = econ_account_of(cmo)
	TEST_ASSERT_EQUAL(length(cmo_ear.heard), 1, "Вторая заявка в кулдаун не пишет на карту")

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

/// Недорогая заявка без ответа дольше auto_approve_wait_minutes одобряется на тике экономики, дорогая ждёт решения.
/datum/unit_test/economy_catalog/request_stale_auto_approve/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/supply_pack/cheap
	var/datum/supply_pack/expensive
	for(var/datum/supply_pack/pack as anything in medical.catalog())
		var/price = econ_pack_price(pack)
		if(!cheap && price <= SSeconomy.settings.auto_approve_limit)
			cheap = pack
		if(!expensive && price > SSeconomy.settings.auto_approve_limit)
			expensive = pack
	TEST_ASSERT_NOTNULL(cheap, "Есть пак дешевле лимита")
	TEST_ASSERT_NOTNULL(expensive, "Есть пак дороже лимита")
	medical.account.credit(econ_pack_price(cheap) + econ_pack_price(expensive), ECON_ADMIN)
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED)
	var/datum/bank_account/doctor_account = econ_account_of(doctor)
	medical.auto_approve_after["[doctor_account.account_id]"] = world.time + 1 HOURS
	var/datum/econ_request/waiting = medical.submit_request(cheap, doctor, "тест")
	var/datum/econ_request/big = medical.submit_request(expensive, doctor, "тест")
	TEST_ASSERT_EQUAL(waiting.status, ECON_REQUEST_PENDING, "Сразу заявка ждёт")
	medical.approve_stale_requests()
	TEST_ASSERT_EQUAL(waiting.status, ECON_REQUEST_PENDING, "До срока ожидания заявка ждёт")
	waiting.created -= SSeconomy.settings.auto_approve_wait_minutes MINUTES
	big.created -= SSeconomy.settings.auto_approve_wait_minutes MINUTES
	medical.approve_stale_requests()
	TEST_ASSERT_EQUAL(waiting.status, ECON_REQUEST_APPROVED, "Недорогая заявка без ответа одобрена")
	TEST_ASSERT_EQUAL(big.status, ECON_REQUEST_PENDING, "Дорогая заявка ждёт решения начальства")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "В очереди только недорогой заказ")

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

/// Человек с КПК в руке; в КПК - ID-карта со счётом, который запоминает сообщения карты.
/datum/unit_test/economy_catalog/proc/make_pda_buyer(holder, balance)
	var/mob/living/carbon/human/buyer = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	var/datum/bank_account/econ_test_ear/account = new(holder)
	allocated += account
	econ_test_set_balance(account, balance)
	card.registered_account = account
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda)
	pda.InsertID(card)
	buyer.put_in_active_hand(pda)
	return buyer

/datum/unit_test/economy_catalog/proc/pda_account(mob/living/carbon/human/buyer)
	var/obj/item/modular_computer/pda/pda = buyer.get_active_held_item()
	return pda.stored_id.registered_account

/// Нажатие в окне кошелька КПК; возвращает программу кошелька.
/datum/unit_test/economy_catalog/proc/press_wallet(mob/living/carbon/human/buyer, action, list/params = list())
	var/obj/item/modular_computer/pda/pda = buyer.get_active_held_item()
	var/datum/computer_file/program/wallet/wallet = locate() in pda.get_all_files()
	var/datum/tgui/window = allocate(/datum/tgui, buyer, wallet, "NtosWallet")
	window.status = UI_INTERACTIVE
	usr = buyer
	wallet.ui_act(action, params, window)
	usr = null
	return wallet

/datum/unit_test/economy_catalog/proc/pda_wallet(mob/living/carbon/human/holder)
	var/obj/item/modular_computer/pda/pda = holder.get_active_held_item()
	return locate(/datum/computer_file/program/wallet) in pda.get_all_files()

/// Заказ из кошелька КПК по цене, которую показывает окно; extra - получатель подарка и подпись.
/datum/unit_test/economy_catalog/proc/order_pda(mob/living/carbon/human/buyer, datum/supply_pack/pack, list/extra = list())
	var/datum/computer_file/program/wallet/wallet = pda_wallet(buyer)
	var/list/prices = wallet.wallet_data(buyer)["personal_prices"]
	var/list/shown = prices["[pack.type]"]
	return press_wallet(buyer, "personal_order", list("id" = "[pack.type]", "price" = shown?[1]) + extra)

/// Личный заказ из кошелька КПК: цена партнёра без наценки списывается сразу, заказ встаёт в очередь шаттла личным и оплаченным, карта сообщает об оплате, снабжение видит его в корзине; отмена до отлёта возвращает деньги, пака вне каталога и сверх лимита не заказать.
/datum/unit_test/economy_catalog/personal_wallet_order/Run()
	var/datum/supply_pack/pet = SSshuttle.supply_packs[/datum/supply_pack/critter/corgi]
	var/datum/supply_pack/outside = SSshuttle.supply_packs[/datum/supply_pack/critter/cow]
	var/mob/living/carbon/human/buyer = make_pda_buyer("Econ Wallet Buyer", 100000)
	var/datum/bank_account/econ_test_ear/account = pda_account(buyer)
	var/datum/computer_file/program/wallet/wallet = press_wallet(buyer, "personal_order", list("id" = "[outside.type]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Пак вне личного каталога заказан: [wallet.message]")
	TEST_ASSERT_EQUAL(account.account_balance, 100000, "Отказ списал деньги")
	var/price = round(econ_pack_price(pet, account))
	TEST_ASSERT(length(wallet.wallet_static_data()["personal_catalog"]), "Окно кошелька без личного каталога")
	var/list/prices = wallet.wallet_data(buyer)["personal_prices"]
	var/list/pet_price = prices["[pet.type]"]
	TEST_ASSERT(length(pet_price) && pet_price[1] == price, "Окно показывает не ту цену, что спишется: [json_encode(pet_price)] вместо [price]")
	press_wallet(buyer, "personal_order", list("id" = "[pet.type]", "price" = price - 1))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Заказ прошёл по устаревшей цене")
	TEST_ASSERT_EQUAL(account.account_balance, 100000, "Отказ по цене списал деньги")
	TEST_ASSERT(findtext(wallet.message, "Цена изменилась") && findtext(wallet.message, "[price] кр."), "Отказ не называет новую цену: [wallet.message]")
	press_wallet(buyer, "personal_order", list("id" = "[pet.type]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Заказ прошёл без показанной цены")
	order_pda(buyer, pet)
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Заказ не встал в очередь шаттла: [wallet.message]")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	TEST_ASSERT(order.pack == pet, "В очереди не тот пак")
	TEST_ASSERT(order.paying_account == account, "Заказ не личный")
	TEST_ASSERT_NULL(order.department_id, "Заказ записан на отдел")
	TEST_ASSERT_EQUAL(order.prepaid, price, "Заказ не оплачен ценой партнёра")
	TEST_ASSERT_EQUAL(account.account_balance, 100000 - price, "Списана не цена партнёра")
	TEST_ASSERT(findtext(jointext(account.heard, "\n"), "Заказ №[order.id] оплачен"), "Карта не сообщила об оплате")
	var/list/orders = wallet.wallet_data(buyer)["personal_orders"]
	TEST_ASSERT_EQUAL(length(orders), 1, "Кошелёк не показывает заказ")
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/list/cart = console.ui_data(buyer)["cart"]
	var/list/entry = cart[1]
	TEST_ASSERT(entry["paid"] && entry["prepaid"] && !entry["department"], "Снабжение видит не личный оплаченный заказ: [json_encode(entry)]")
	press_wallet(buyer, "personal_cancel", list("id" = order.id))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Отменённый заказ остался в очереди")
	TEST_ASSERT_EQUAL(account.account_balance, 100000, "Отмена не вернула деньги")
	var/limit = SSeconomy.settings.personal_order_limit
	for(var/i in 1 to limit)
		order_pda(buyer, pet)
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), limit, "Заказы до лимита не приняты: [wallet.message]")
	var/balance = account.account_balance
	order_pda(buyer, pet)
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), limit, "Принят заказ сверх лимита")
	TEST_ASSERT_EQUAL(account.account_balance, balance, "Отказ сверх лимита списал деньги")

/// Оплаченный с КПК заказ летит ближайшим шаттлом: второй раз не списывается, сбора снабжению нет, ящик заперт на покупателя, карта сообщает об отгрузке и о прибытии на станцию. Заказ, снятый снабжением с корзины, возвращает деньги покупателю.
/datum/unit_test/economy_catalog/personal_wallet_delivery/Run()
	var/datum/supply_pack/pet = SSshuttle.supply_packs[/datum/supply_pack/critter/corgi]
	var/mob/living/carbon/human/buyer = make_pda_buyer("Econ Wallet Receiver", 100000)
	var/datum/bank_account/econ_test_ear/account = pda_account(buyer)
	var/datum/computer_file/program/wallet/wallet = order_pda(buyer, pet)
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Заказ не оформлен: [wallet.message]")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	var/paid_balance = account.account_balance
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/cargo_before = cargo.account_balance
	var/list/crates_before = new_crates(list(), /obj/structure/closet)
	SSshuttle.supply.buy()
	SSshuttle.orderhistory -= order
	TEST_ASSERT(!(order in SSshuttle.shoppinglist), "Заказ не отгружен")
	TEST_ASSERT_EQUAL(account.account_balance, paid_balance, "Отгрузка списала деньги второй раз")
	TEST_ASSERT_EQUAL(cargo.account_balance, cargo_before, "Снабжение взяло сбор с личного каталога")
	var/list/delivered = new_crates(crates_before, /obj/structure/closet/crate/secure/owned)
	TEST_ASSERT_EQUAL(length(delivered), 1, "На шаттле нет именного ящика")
	var/obj/structure/closet/crate/secure/owned/crate = delivered[1]
	allocated += crate.GetAllContents()
	TEST_ASSERT(crate.buyer_account == account, "Ящик заперт не на покупателя")
	TEST_ASSERT(findtext(jointext(account.heard, "\n"), "№[order.id] ([pet.name]) отгружен"), "Карта не сообщила об отгрузке")
	TEST_ASSERT(!findtext(jointext(account.heard, "\n"), "привёз"), "О прибытии сказано до посадки")
	var/list/in_transit = wallet.wallet_data(buyer)["personal_in_transit"]
	TEST_ASSERT_EQUAL(length(in_transit), 1, "Кошелёк не показывает заказ в пути")
	SSshuttle.supply.notify_personal_arrivals()
	TEST_ASSERT(findtext(jointext(account.heard, "\n"), "привёз на станцию ваш заказ №[order.id]"), "Карта не сообщила о прибытии")
	qdel(order)

	order_pda(buyer, pet)
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Второй заказ не оформлен: [wallet.message]")
	var/datum/supply_order/removed = SSshuttle.shoppinglist[1]
	var/removed_price = removed.prepaid
	var/before_removal = account.account_balance
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/cargo_tech = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	click_cargo(console, cargo_tech, "remove", list("id" = "[removed.id]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Снабжение не сняло заказ")
	TEST_ASSERT_EQUAL(account.account_balance, before_removal + removed_price, "Снятый снабжением заказ не вернул деньги")
	TEST_ASSERT(findtext(jointext(account.heard, "\n"), "Снабжение сняло ваш заказ №[removed.id]"), "Карта не сообщила о снятии заказа")

/// Подарок с КПК: платит даритель, посылка заперта на получателя, карта получателя сразу узнаёт, что ему едет посылка, а по прибытии - что она пришла; имя дарителя скрывается по его выбору. Себе, спящему, замороженному и неизвестному подарок не оформить, отмена возвращает деньги дарителю.
/datum/unit_test/economy_catalog/personal_wallet_gift/Run()
	var/datum/supply_pack/pet = SSshuttle.supply_packs[/datum/supply_pack/critter/corgi]
	var/mob/living/carbon/human/giver = make_pda_buyer("Econ Gift Giver", 100000)
	var/datum/bank_account/econ_test_ear/payer = pda_account(giver)
	var/mob/living/carbon/human/friend = make_pda_buyer("Econ Gift Friend", 0)
	var/datum/bank_account/econ_test_ear/receiver = pda_account(friend)
	var/mob/living/carbon/human/sleeper_mob = make_pda_buyer("Econ Gift Sleeper", 0)
	var/datum/bank_account/sleeper = pda_account(sleeper_mob)
	sleeper.bind_owner(sleeper_mob)
	sleeper.away_since = world.time - (SSeconomy.settings.dormant_after_minutes MINUTES) - 1
	sleeper.update_dormancy()
	TEST_ASSERT_EQUAL(sleeper.state, ACCOUNT_DORMANT, "test premise: счёт без клиента не уснул")
	var/mob/living/carbon/human/frozen_mob = make_pda_buyer("Econ Gift Frozen", 0)
	var/datum/bank_account/frozen = pda_account(frozen_mob)
	SSeconomy.apply_freeze(frozen, "тест", "проверка подарка")
	var/datum/computer_file/program/wallet/wallet
	for(var/target in list(payer.account_holder, "[payer.account_id]", sleeper.account_holder, frozen.account_holder, "Econ Nobody Here"))
		wallet = order_pda(giver, pet, list("recipient" = target))
		TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Подарок для [target] оформлен: [wallet.message]")
	TEST_ASSERT(findtext(wallet.message, "не найден"), "Отказ неизвестному получателю не объясняет почему: [wallet.message]")
	TEST_ASSERT_EQUAL(payer.account_balance, 100000, "Отказ в подарке списал деньги")

	order_pda(giver, pet, list("recipient" = "[receiver.account_id]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Подарок не оформлен: [wallet.message]")
	var/datum/supply_order/gift = SSshuttle.shoppinglist[1]
	var/price = gift.prepaid
	TEST_ASSERT(gift.paying_account == payer && gift.gift_to == receiver, "Подарок записан не на тех: платит [gift.paying_account?.account_holder], получает [gift.gift_to?.account_holder]")
	TEST_ASSERT_EQUAL(payer.account_balance, 100000 - price, "Подарок списан не с дарителя")
	TEST_ASSERT_EQUAL(receiver.account_balance, 0, "Подарок списал деньги с получателя")
	var/receiver_heard = jointext(receiver.heard, "\n")
	TEST_ASSERT(findtext(receiver_heard, "Вам едет посылка") && findtext(receiver_heard, payer.account_holder), "Получатель не узнал, кто дарит: [receiver_heard]")
	var/list/orders = wallet.wallet_data(giver)["personal_orders"]
	var/list/listed = length(orders) ? orders[1] : list()
	TEST_ASSERT_EQUAL(listed["gift_to"], receiver.account_holder, "Кошелёк дарителя не показывает, кому подарок")
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/list/cart = console.ui_data(giver)["cart"]
	var/list/entry = cart[1]
	TEST_ASSERT(findtext(entry["object"], "подарок с КПК для [receiver.account_holder]"), "Корзина снабжения не помечает подарок: [json_encode(entry)]")

	var/list/crates_before = new_crates(list(), /obj/structure/closet)
	SSshuttle.supply.buy()
	SSshuttle.orderhistory -= gift
	var/list/delivered = new_crates(crates_before, /obj/structure/closet/crate/secure/owned)
	TEST_ASSERT_EQUAL(length(delivered), 1, "На шаттле нет именного ящика")
	var/obj/structure/closet/crate/secure/owned/crate = delivered[1]
	allocated += crate.GetAllContents()
	TEST_ASSERT(crate.buyer_account == receiver, "Ящик заперт не на получателя")
	TEST_ASSERT_EQUAL(payer.account_balance, 100000 - price, "Отгрузка подарка списала деньги второй раз")
	TEST_ASSERT(findtext(jointext(payer.heard, "\n"), "Подарок №[gift.id] ([pet.name]) для [receiver.account_holder] отгружен"), "Даритель не узнал об отгрузке")
	var/datum/computer_file/program/wallet/friend_wallet = pda_wallet(friend)
	TEST_ASSERT_EQUAL(length(friend_wallet.wallet_data(friend)["personal_in_transit"]), 1, "Получатель не видит подарок в пути")
	SSshuttle.supply.notify_personal_arrivals()
	TEST_ASSERT(findtext(jointext(receiver.heard, "\n"), "привёз на станцию ваш заказ №[gift.id] [pet.name] (подарок от [payer.account_holder])"), "Получатель не узнал о прибытии подарка")
	qdel(gift)

	wallet = order_pda(giver, pet, list("recipient" = receiver.account_holder))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Второй подарок подряд оформлен без паузы")
	TEST_ASSERT(findtext(wallet.message, "не чаще"), "Отказ в подарке подряд не объясняет почему: [wallet.message]")
	COOLDOWN_RESET(payer, personal_gift_cooldown)
	receiver.heard.Cut()
	order_pda(giver, pet, list("recipient" = receiver.account_holder, "hide_name" = TRUE))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Подарок без имени не оформлен: [wallet.message]")
	var/datum/supply_order/secret = SSshuttle.shoppinglist[1]
	cart = console.ui_data(giver)["cart"]
	entry = cart[1]
	TEST_ASSERT_EQUAL(entry["orderer"], "аноним", "Корзина снабжения называет дарителя, скрывшего имя")
	var/before_cancel = payer.account_balance
	price = secret.prepaid
	press_wallet(giver, "personal_cancel", list("id" = secret.id))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Отменённый подарок остался в корзине")
	TEST_ASSERT_EQUAL(payer.account_balance, before_cancel + price, "Отмена подарка не вернула деньги дарителю")
	TEST_ASSERT_EQUAL(receiver.account_balance, 0, "Отмена подарка заплатила получателю")
	var/secret_heard = jointext(receiver.heard, "\n")
	TEST_ASSERT(findtext(secret_heard, "кто-то из экипажа") && findtext(secret_heard, "отменён"), "Получатель не узнал о подарке без имени и его отмене: [secret_heard]")
	TEST_ASSERT(!findtext(secret_heard, payer.account_holder), "Подарок без имени назвал дарителя: [secret_heard]")

/// Владелец счёта ушёл со смены: неотгруженные личные заказы и подарки на его имя снимаются с корзины, деньги возвращаются тому, кто платил; подарок от ушедшего другому и уже отгруженное остаются.
/datum/unit_test/economy_catalog/personal_dormant_refund/Run()
	var/datum/supply_pack/pet = SSshuttle.supply_packs[/datum/supply_pack/critter/corgi]
	var/mob/living/carbon/human/buyer = make_pda_buyer("Econ Dormant Buyer", 100000)
	var/datum/bank_account/econ_test_ear/account = pda_account(buyer)
	var/mob/living/carbon/human/friend = make_pda_buyer("Econ Dormant Friend", 100000)
	var/datum/bank_account/econ_test_ear/friend_account = pda_account(friend)
	account.bind_owner(buyer)
	friend_account.bind_owner(friend)
	order_pda(buyer, pet)
	var/datum/supply_order/shipped = SSshuttle.shoppinglist[1]
	var/list/crates_before = new_crates(list(), /obj/structure/closet)
	SSshuttle.supply.buy()
	SSshuttle.orderhistory -= shipped
	for(var/obj/structure/closet/crate as anything in new_crates(crates_before, /obj/structure/closet))
		allocated += crate.GetAllContents()
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "test premise: первый заказ не отгружен")
	order_pda(buyer, pet)
	var/datum/supply_order/own = SSshuttle.shoppinglist[1]
	order_pda(friend, pet, list("recipient" = account.account_holder))
	order_pda(buyer, pet, list("recipient" = friend_account.account_holder))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 3, "test premise: заказы и подарки не оформлены")
	var/datum/supply_order/gift_in = SSshuttle.shoppinglist[2]
	var/datum/supply_order/gift_out = SSshuttle.shoppinglist[3]
	var/own_price = own.prepaid
	var/gift_in_price = gift_in.prepaid
	var/buyer_before = account.account_balance
	var/friend_before = friend_account.account_balance

	account.away_since = world.time - (SSeconomy.settings.dormant_after_minutes MINUTES) - 1
	account.update_dormancy()
	TEST_ASSERT_EQUAL(account.state, ACCOUNT_DORMANT, "test premise: счёт без клиента не уснул")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "С корзины снято не то: осталось [length(SSshuttle.shoppinglist)]")
	TEST_ASSERT(SSshuttle.shoppinglist[1] == gift_out, "Подарок от ушедшего другому снят с корзины")
	TEST_ASSERT_EQUAL(account.account_balance, buyer_before + own_price, "Ушедшему не вернулись деньги за его заказ")
	TEST_ASSERT_EQUAL(friend_account.account_balance, friend_before + gift_in_price, "Дарителю не вернулись деньги за подарок ушедшему")
	TEST_ASSERT(findtext(jointext(account.heard, "\n"), "пока вас не было на смене"), "Карта ушедшего не сказала о снятом заказе")
	TEST_ASSERT(findtext(jointext(friend_account.heard, "\n"), "ушёл со смены"), "Карта дарителя не сказала, почему подарок снят")
	TEST_ASSERT_EQUAL(length(SSshuttle.supply.personal_in_transit(account)), 1, "Отгруженный заказ ушедшего перестал числиться в пути")
	account.update_dormancy()
	TEST_ASSERT_EQUAL(account.account_balance, buyer_before + own_price, "Повторный тик спящего вернул деньги ещё раз")
	SSshuttle.supply.notify_personal_arrivals()
	qdel(shipped)

/// Именная посылка приходит целой: ошибка манифеста ничего не забирает из ящика и кейса на имя покупателя.
/datum/unit_test/economy_catalog/personal_owned_parcels_intact/Run()
	var/datum/supply_pack/crate_pack = SSshuttle.supply_packs[/datum/supply_pack/misc/candles]
	var/datum/supply_pack/goody_pack = SSshuttle.supply_packs[/datum/supply_pack/goody/beach_ball]
	var/datum/bank_account/owner = new("econ_test_parcels")
	allocated += owner
	var/lost_crates = 0
	var/lost_cases = 0
	for(var/i in 1 to 100)
		var/datum/supply_order/order = new(crate_pack, "econ_test", "econ_test", "econ_test", "econ_test", owner)
		var/obj/structure/closet/crate/crate = order.generate(run_loc_floor_bottom_left)
		qdel(order)
		if(!istype(crate, /obj/structure/closet/crate/secure/owned))
			return TEST_FAIL("Частный заказ приехал не в именном ящике: [crate.type]")
		if(pack_items_inside(crate, crate_pack) != length(crate_pack.contains))
			lost_crates++
		for(var/atom/movable/thing as anything in crate.GetAllContents())
			qdel(thing)
		var/obj/item/storage/lockbox/order/case = new(run_loc_floor_bottom_left, owner)
		var/datum/supply_order/combo = new
		combo.id = "#[i]"
		combo.generateCombo(case, owner.account_holder, goody_pack.contains)
		qdel(combo)
		if(pack_items_inside(case, goody_pack) != length(goody_pack.contains))
			lost_cases++
		for(var/atom/movable/thing as anything in case.GetAllContents())
			qdel(thing)
	TEST_ASSERT_EQUAL(lost_crates, 0, "Из именных ящиков пропадали вещи")
	TEST_ASSERT_EQUAL(lost_cases, 0, "Из именных кейсов пропадали вещи")

/// Сколько вещей из описи пака лежит прямо в container.
/datum/unit_test/economy_catalog/proc/pack_items_inside(atom/container, datum/supply_pack/pack)
	. = 0
	for(var/atom/movable/thing as anything in container)
		if(thing.type in pack.contains)
			.++

/// Именной кейс открывает и запирает только ID-карта владельца счёта - в руке, в КПК или в бумажнике; КПК с доступом арсенала и чужая карта его не открывают.
/datum/unit_test/economy_catalog/personal_parcel_lock/Run()
	var/datum/bank_account/owner = new("econ_test_parcel_owner")
	allocated += owner
	var/datum/bank_account/stranger = new("econ_test_parcel_warden")
	allocated += stranger
	var/obj/item/storage/lockbox/order/case = allocate(/obj/item/storage/lockbox/order, run_loc_floor_bottom_left, owner)
	var/mob/living/carbon/human/warden = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/card/id/armory = allocate(/obj/item/card/id)
	armory.access = list(ACCESS_ARMORY, ACCESS_SECURITY, ACCESS_CAPTAIN)
	armory.registered_account = stranger
	warden.put_in_active_hand(armory)
	armory.melee_attack_chain(warden, case)
	TEST_ASSERT(SEND_SIGNAL(case, COMSIG_IS_STORAGE_LOCKED), "Чужая карта с доступом арсенала открыла посылку")
	var/obj/item/modular_computer/pda/warden_pda = allocate(/obj/item/modular_computer/pda)
	warden.temporarilyRemoveItemFromInventory(armory)
	warden_pda.InsertID(armory)
	warden.put_in_active_hand(warden_pda)
	warden_pda.melee_attack_chain(warden, case)
	TEST_ASSERT(SEND_SIGNAL(case, COMSIG_IS_STORAGE_LOCKED), "КПК с доступом арсенала открыл чужую посылку")

	var/mob/living/carbon/human/buyer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = owner
	buyer.put_in_active_hand(card)
	card.melee_attack_chain(buyer, case)
	TEST_ASSERT(!SEND_SIGNAL(case, COMSIG_IS_STORAGE_LOCKED), "Владелец не открыл посылку картой в руке")
	card.melee_attack_chain(buyer, case)
	TEST_ASSERT(SEND_SIGNAL(case, COMSIG_IS_STORAGE_LOCKED), "Владелец не запер посылку картой")
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda)
	buyer.temporarilyRemoveItemFromInventory(card)
	pda.InsertID(card)
	buyer.put_in_active_hand(pda)
	pda.melee_attack_chain(buyer, case)
	TEST_ASSERT(!SEND_SIGNAL(case, COMSIG_IS_STORAGE_LOCKED), "Владелец не открыл посылку картой в КПК")
	pda.melee_attack_chain(buyer, case)
	var/obj/item/card/id/wallet_card = allocate(/obj/item/card/id)
	wallet_card.registered_account = owner
	var/obj/item/storage/wallet/wallet = allocate(/obj/item/storage/wallet)
	wallet_card.forceMove(wallet)
	buyer.temporarilyRemoveItemFromInventory(pda)
	buyer.put_in_active_hand(wallet)
	wallet.melee_attack_chain(buyer, case)
	TEST_ASSERT(!SEND_SIGNAL(case, COMSIG_IS_STORAGE_LOCKED), "Владелец не открыл посылку картой в бумажнике")

/// Посылка с КПК летит настоящим рейсом: отгружается при вылете от ЦК, о прибытии карта узнаёт, когда шаттл сел на станции; заказ, вернувшийся с шаттлом к ЦК без посадки на станции, в пути больше не числится.
/datum/unit_test/economy_catalog/personal_wallet_docking/Run()
	var/obj/docking_port/mobile/supply/supply = SSshuttle.supply
	var/obj/docking_port/stationary/away = SSshuttle.getDock("supply_away")
	var/obj/docking_port/stationary/home = SSshuttle.getDock("supply_home")
	TEST_ASSERT(supply && away && home, "test premise: на тестовой карте нет шаттла снабжения или его доков")
	var/obj/docking_port/stationary/transit = supply.assigned_transit || SSshuttle.generate_transit_dock(supply)
	TEST_ASSERT_NOTNULL(transit, "test premise: у шаттла снабжения нет транзита")
	var/obj/docking_port/stationary/start = supply.get_docked()
	if(start != away)
		TEST_ASSERT_EQUAL(supply.initiate_docking(away), DOCKING_SUCCESS, "test premise: шаттл снабжения не встал к ЦК")
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/misc/candles]
	var/mob/living/carbon/human/buyer = make_pda_buyer("Econ Docking Buyer", 100000)
	var/datum/bank_account/econ_test_ear/account = pda_account(buyer)
	var/datum/computer_file/program/wallet/wallet = order_pda(buyer, pack)
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Заказ не оформлен: [wallet.message]")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	var/list/crates_before = new_crates(list(), /obj/structure/closet)
	var/landed = supply.initiate_docking(home)
	SSshuttle.orderhistory -= order
	var/list/delivered = new_crates(crates_before, /obj/structure/closet/crate/secure/owned)
	for(var/obj/structure/closet/crate as anything in delivered)
		for(var/atom/movable/thing as anything in crate.GetAllContents())
			qdel(thing)
	TEST_ASSERT_EQUAL(landed, DOCKING_SUCCESS, "Шаттл снабжения не сел на станции")
	TEST_ASSERT_EQUAL(length(delivered), 1, "Рейс привёз не одну посылку")
	var/heard = jointext(account.heard, "\n")
	TEST_ASSERT(findtext(heard, "№[order.id] ([pack.name]) отгружен"), "Вылет от ЦК не отгрузил заказ")
	TEST_ASSERT(findtext(heard, "привёз на станцию ваш заказ №[order.id]"), "Посадка на станции не сообщила о прибытии")
	TEST_ASSERT_EQUAL(length(supply.personal_in_transit(account)), 0, "Привезённый заказ всё ещё числится в пути")
	qdel(order)

	TEST_ASSERT_EQUAL(supply.initiate_docking(away), DOCKING_SUCCESS, "Шаттл снабжения не вернулся к ЦК")
	order_pda(buyer, pack)
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Второй заказ не оформлен: [wallet.message]")
	var/datum/supply_order/returned = SSshuttle.shoppinglist[1]
	crates_before = new_crates(list(), /obj/structure/closet)
	TEST_ASSERT_EQUAL(supply.initiate_docking(transit), DOCKING_SUCCESS, "Шаттл снабжения не ушёл в транзит")
	SSshuttle.orderhistory -= returned
	TEST_ASSERT_EQUAL(length(supply.personal_in_transit(account)), 1, "Отгруженный заказ не числится в пути")
	for(var/obj/structure/closet/crate as anything in new_crates(crates_before, /obj/structure/closet))
		for(var/atom/movable/thing as anything in crate.GetAllContents())
			qdel(thing)
	TEST_ASSERT_EQUAL(supply.initiate_docking(away), DOCKING_SUCCESS, "Шаттл снабжения не вернулся к ЦК из транзита")
	TEST_ASSERT_EQUAL(length(supply.personal_in_transit(account)), 0, "Вернувшийся к ЦК заказ всё ещё числится в пути")
	qdel(returned)
	if(start != away)
		TEST_ASSERT_EQUAL(supply.initiate_docking(start), DOCKING_SUCCESS, "Шаттл снабжения не вернулся на исходный док")

/// Карточки личного каталога: без паков, которые нельзя доставить как есть (гроб, мыло, капсаицин), у бустеров опись числом, у плащей тешари свои описание и ящик, «случайные» - только когда пак кладёт не всё.
/datum/unit_test/economy_catalog/personal_catalog_cards/Run()
	for(var/excluded in list(/datum/supply_pack/misc/funeral, /datum/supply_pack/misc/shower, /datum/supply_pack/organic/fiestatortilla))
		TEST_ASSERT(!GLOB.econ_personal_catalog[excluded], "[excluded] в личном каталоге")
	var/list/cards = list()
	for(var/list/section as anything in econ_personal_catalog_ui())
		for(var/list/card as anything in section["packs"])
			cards[card["id"]] = card
	var/list/tcg = cards["[/datum/supply_pack/costumes_toys/randomised/tcg]"]
	TEST_ASSERT(length(tcg), "Бустеров нет в карточках каталога")
	var/list/tcg_contents = tcg["contents"]
	TEST_ASSERT(length(tcg_contents) && findtext(tcg_contents[1], "×10"), "У бустеров пустая опись: [json_encode(tcg_contents)]")
	TEST_ASSERT_EQUAL(tcg["random"], 0, "Бустеры названы случайными из пустой описи")
	var/list/plush = cards["[/datum/supply_pack/costumes_toys/randomised/plush]"]
	TEST_ASSERT_EQUAL(plush?["random"], 0, "Пак плюшевых игрушек кладёт всю опись, но назван случайным")
	var/list/cloak_card = cards["[/datum/supply_pack/costumes_toys/randomised/tesh_cloaks_vr]"]
	TEST_ASSERT_EQUAL(cloak_card?["random"], 3, "Плащи тешари - три случайных из набора")
	var/datum/supply_pack/hats = SSshuttle.supply_packs[/datum/supply_pack/costumes_toys/randomised]
	for(var/cloak_type in list(/datum/supply_pack/costumes_toys/randomised/tesh_cloaks_vr, /datum/supply_pack/costumes_toys/randomised/tesh_cloaks_b_vr, /datum/supply_pack/costumes_toys/randomised/tesh_beltcloaks_vr, /datum/supply_pack/costumes_toys/randomised/tesh_beltcloaks_b_vr, /datum/supply_pack/costumes_toys/randomised/tesh_hoodcloaks_vr, /datum/supply_pack/costumes_toys/randomised/tesh_hoodcloaks_b_vr))
		var/datum/supply_pack/cloaks = SSshuttle.supply_packs[cloak_type]
		TEST_ASSERT(cloaks.desc != hats.desc && cloaks.crate_name != hats.crate_name, "[cloak_type] описан как шляпы")

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

/// Капсула отдела: глава платит цену с наценкой из бюджета, пак прилетает рядом с ним мимо шаттла и помечен закупкой; дальше пауза, вне станции и не главе - отказ.
/datum/unit_test/economy_catalog/express_pod/Run()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/datum/supply_pack/pack
	for(var/datum/supply_pack/candidate as anything in service.catalog())
		if(candidate.crate_type && !econ_pack_unavailable(candidate))
			pack = candidate
			break
	TEST_ASSERT_NOTNULL(pack, "В каталоге сервиса есть пак в наличии")
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_SRV, list(ACCESS_CAPTAIN))
	var/mob/living/carbon/human/cook = make_staff(ACCOUNT_SRV)
	chief.forceMove(station_turf)
	var/price = service.express_price(pack)
	TEST_ASSERT(price > round(econ_pack_price(pack)), "Капсула дороже обычного заказа")
	econ_test_set_balance(service.account, price * 2)
	service.next_express = 0
	TEST_ASSERT(findtext(service.express_pack(pack, cook), "глава отдела"), "Не глава капсулу не заказывает")
	var/turf/away = run_loc_floor_bottom_left
	var/mob/living/carbon/human/away_chief = make_staff(ACCOUNT_SRV, list(ACCESS_CAPTAIN))
	away_chief.forceMove(away)
	TEST_ASSERT(findtext(service.express_pack(pack, away_chief), "негде сесть"), "Вне станции капсула не садится")
	TEST_ASSERT_EQUAL(service.account.account_balance, price * 2, "Отказы не тронули бюджет")
	TEST_ASSERT_NULL(service.express_pack(pack, chief), "Глава на станции заказал капсулу")
	TEST_ASSERT_EQUAL(service.account.account_balance, price, "Списана цена капсулы")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Капсула не встала в очередь шаттла")
	TEST_ASSERT(findtext(service.express_pack(pack, chief), "Следующую капсулу"), "Вторая капсула сразу не заказывается")
	TEST_ASSERT_EQUAL(service.account.account_balance, price, "Пауза не списала деньги")
	var/obj/structure/closet/crate/delivered
	for(var/i in 1 to 30)
		for(var/obj/structure/closet/crate/crate in range(ECON_EXPRESS_LANDING_RANGE, station_turf))
			if(istype(crate, pack.crate_type))
				delivered = crate
		if(delivered)
			break
		sleep(5)
	service.next_express = 0
	TEST_ASSERT_NOTNULL(delivered, "Капсула доставила ящик рядом с главой")
	allocated += delivered.GetAllContents()
	TEST_ASSERT_EQUAL(get_area(delivered), get_area(station_turf), "Ящик в том же помещении")
	for(var/obj/item/thing in delivered)
		if(!istype(thing, /obj/item/paper))
			TEST_ASSERT(thing.econ_imported, "[thing] помечен закупкой")

/// Шестой малый кейс одному получателю за отгрузку: сбор за доставку не списывается с того, кто уже оплатил подарок с КПК.
/datum/unit_test/economy_catalog/personal_gift_no_crate_tax/Run()
	var/datum/supply_pack/goody = SSshuttle.supply_packs[/datum/supply_pack/goody/dyespray]
	TEST_ASSERT(goody?.goody && econ_personal_catalog_orderable(goody.type), "test premise: краска для волос - малый кейс личного каталога")
	var/mob/living/carbon/human/friend = make_pda_buyer("Econ Goody Friend", 0)
	var/datum/bank_account/receiver = pda_account(friend)
	var/list/givers = list()
	for(var/i in 1 to GOODY_FREE_SHIPPING_MAX + 1)
		var/mob/living/carbon/human/giver = make_pda_buyer("Econ Goody Giver [i]", 100000)
		var/datum/computer_file/program/wallet/wallet = order_pda(giver, goody, list("recipient" = "[receiver.account_id]"))
		TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), i, "Подарок [i] не оформлен: [wallet.message]")
		var/datum/bank_account/payer = pda_account(giver)
		givers[payer] = payer.account_balance
	SSshuttle.supply.buy()
	for(var/datum/supply_order/order as anything in SSshuttle.orderhistory.Copy())
		if(order.gift_to == receiver)
			SSshuttle.orderhistory -= order
			qdel(order)
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Подарки не отгружены")
	for(var/datum/bank_account/payer as anything in givers)
		TEST_ASSERT_EQUAL(payer.account_balance, givers[payer], "С [payer.account_holder] при отгрузке списан сбор за чужие кейсы")
