/// Экономические события на изолированной копии рынка; состояние экономики, казна и карго возвращаются.
/datum/unit_test/economy_events
	abstract_type = /datum/unit_test/economy_events
	var/list/saved_market
	var/saved_state
	var/saved_treasury
	var/saved_cargo
	var/saved_poor_per_capita
	var/datum/bank_account/department/treasury
	var/datum/bank_account/department/cargo

/datum/unit_test/economy_events/New()
	..()
	saved_market = econ_test_swap_market()
	SSmarket.next_shift = world.time + 1 HOURS
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.volatility = 0
	SSmarket.hot_chance = 0
	saved_state = SSeconomy.economy_state
	treasury = SSeconomy.treasury()
	cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	saved_treasury = treasury.account_balance
	saved_cargo = cargo.account_balance
	saved_poor_per_capita = SSeconomy.settings.state_poor_per_capita

/datum/unit_test/economy_events/Destroy()
	SSeconomy.economy_state = saved_state
	SSeconomy.settings.state_poor_per_capita = saved_poor_per_capita
	econ_test_set_balance(treasury, saved_treasury)
	econ_test_set_balance(cargo, saved_cargo)
	treasury = null
	cargo = null
	econ_test_restore_market(saved_market)
	return ..()

/datum/unit_test/economy_events/proc/registered(control_type)
	for(var/datum/director_action/action as anything in SSdirector.actions)
		if(action.type == control_type)
			return action

/datum/unit_test/economy_events/proc/weight_in(datum/round_event_control/control, state)
	SSeconomy.economy_state = state
	return control.get_weight(null)

/datum/unit_test/economy_events/proc/news_has(text)
	for(var/line in SSmarket.pending_news)
		if(findtext(line, text))
			return TRUE
	return FALSE

/datum/unit_test/economy_events/proc/finish(datum/round_event/event)
	event.kill()
	qdel(event)

/// Новые события зарегистрированы у директора семейством economy, веса зависят от состояния экономики.
/datum/unit_test/economy_events/weights/Run()
	for(var/control_type in list(/datum/round_event_control/nt_grant, /datum/round_event_control/nt_aid_shipment, /datum/round_event_control/partner_embargo, /datum/round_event_control/sector_boom, /datum/round_event_control/commodity_shortage))
		var/datum/round_event_control/control = registered(control_type)
		TEST_ASSERT_NOTNULL(control, "[control_type] не зарегистрирован у директора")
		TEST_ASSERT_EQUAL(control.family, "economy", "[control_type]: семейство")
		TEST_ASSERT_EQUAL(control.category, EVENT_CATEGORY_BUREAUCRATIC, "[control_type]: категория")
	for(var/control_type in list(/datum/round_event_control/nt_grant, /datum/round_event_control/nt_aid_shipment))
		var/datum/round_event_control/control = registered(control_type)
		TEST_ASSERT(weight_in(control, ECON_STATE_POOR) > 0, "[control_type]: бедной станции вес")
		TEST_ASSERT_EQUAL(weight_in(control, ECON_STATE_NORMAL), 0, "[control_type]: обычной станции не выпадает")
		TEST_ASSERT_EQUAL(weight_in(control, ECON_STATE_RICH), 0, "[control_type]: богатой станции не выпадает")
	var/list/rich_doubled = list(/datum/round_event_control/partner_embargo, /datum/round_event_control/market_crash, /datum/round_event_control/pirates)
	for(var/control_type in rich_doubled)
		var/datum/round_event_control/control = registered(control_type)
		TEST_ASSERT(abs(weight_in(control, ECON_STATE_RICH) - 2 * weight_in(control, ECON_STATE_NORMAL)) < 0.01, "[control_type]: у богатой станции вдвое чаще")
	var/datum/round_event_control/crash = registered(/datum/round_event_control/market_crash)
	TEST_ASSERT(weight_in(crash, ECON_STATE_POOR) < weight_in(crash, ECON_STATE_NORMAL), "Обвал реже у бедной станции")
	var/datum/round_event_control/boom = registered(/datum/round_event_control/sector_boom)
	TEST_ASSERT(abs(weight_in(boom, ECON_STATE_POOR) - 2 * weight_in(boom, ECON_STATE_NORMAL)) < 0.01, "Бум у бедной станции вдвое чаще")
	var/datum/round_event_control/shortage = registered(/datum/round_event_control/commodity_shortage)
	TEST_ASSERT_EQUAL(weight_in(shortage, ECON_STATE_RICH), weight_in(shortage, ECON_STATE_POOR), "Дефицит от состояния не зависит")

/// Эмбарго закрывает случайного партнёра, кроме НТ Логистики и контрабандного, видно в окне снабжения и снимается по времени.
/datum/unit_test/economy_events/embargo/Run()
	econ_test_partner_extremes()
	var/datum/trade_partner/vey = SSmarket.get_partner("vey_med")
	var/datum/market_offer/taken = vey.new_offer()
	var/datum/market_offer/untaken = vey.new_offer()
	TEST_ASSERT(taken.accept(), "Спецзаказ до эмбарго не взят")
	var/list/embargoed = list()
	for(var/i in 1 to length(SSmarket.partners))
		var/datum/round_event/partner_embargo/event = new(FALSE)
		event.start()
		finish(event)
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		if(partner.embargoed())
			embargoed += id
	TEST_ASSERT(!(PARTNER_UNIVERSAL_ID in embargoed), "НТ Логистика под эмбарго")
	TEST_ASSERT(!("free_traders" in embargoed), "Вольные торговцы под эмбарго")
	TEST_ASSERT_EQUAL(length(embargoed), length(SSmarket.partners) - 2, "Под эмбарго все остальные партнёры: [jointext(embargoed, ", ")]")
	TEST_ASSERT(news_has(vey.name), "Нет новости об эмбарго Вей-Мед")
	TEST_ASSERT(!news_has("Вольные торговцы"), "Новость о Вольных торговцах")
	TEST_ASSERT_EQUAL(vey.buy_multiplier(COMMODITY_MEDICINE), 0, "Партнёр под эмбарго покупает")
	TEST_ASSERT(SSmarket.best_buyer(COMMODITY_MEDICINE) != vey, "Партнёр под эмбарго лучший покупатель")
	for(var/pack_id in SSshuttle.supply_packs)
		TEST_ASSERT(!vey.sells_pack(SSshuttle.supply_packs[pack_id]), "Партнёр под эмбарго продаёт [pack_id]")
	var/minutes_shown
	for(var/list/entry as anything in econ_cargo_partners_data(FALSE))
		if(entry["id"] == "vey_med")
			minutes_shown = entry["embargo_minutes"]
	TEST_ASSERT_EQUAL(minutes_shown, SSeconomy.settings.event_embargo_minutes, "Окно снабжения показывает срок эмбарго")
	TEST_ASSERT(taken.open(), "Взятый до эмбарго спецзаказ нельзя выполнить")
	TEST_ASSERT(!untaken.open(), "Невзятый спецзаказ партнёра под эмбарго открыт")
	var/list/untaken_entry = untaken.ui_entry()
	TEST_ASSERT(untaken_entry["embargoed"], "Окно не показывает эмбарго спецзаказа")
	var/turf/station_turf = find_walkable_station_turf()
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo, station_turf)
	var/mob/living/carbon/human/technician = allocate(/mob/living/carbon/human, station_turf)
	var/datum/tgui/window = allocate(/datum/tgui, technician, console, "Cargo")
	window.status = UI_INTERACTIVE
	usr = technician
	console.ui_act("accept_offer", list("uid" = untaken.uid), window)
	usr = null
	TEST_ASSERT(!untaken.accepted, "Консоль взяла спецзаказ партнёра под эмбарго")
	var/offers_before = length(vey.offers)
	SSmarket.offers_max = 10
	SSmarket.offer_chance = 100
	SSmarket.generate_offers()
	TEST_ASSERT_EQUAL(length(vey.offers), offers_before, "Партнёр под эмбарго выставил спецзаказ")
	vey.embargo_until = world.time - 1
	TEST_ASSERT(vey.buy_multiplier(COMMODITY_MEDICINE) > 0, "Эмбарго не снялось")

/// Выкуп пиратам уходит из казны, а не из бюджета карго; без денег в казне не списывается ничего.
/datum/unit_test/economy_events/pirate_ransom/Run()
	econ_test_set_balance(treasury, 100000)
	var/payoff = econ_ransom_demand(SSeconomy.settings.event_ransom_min, SSeconomy.settings.event_ransom_share)
	TEST_ASSERT_EQUAL(payoff, 80000, "Требование - доля казны")
	var/cargo_before = cargo.account_balance
	var/datum/round_event/pirates/pirates = new(FALSE)
	var/datum/comm_message/threat = new
	threat.answered = 1
	pirates.pirates_answered(threat, payoff, "Тестовый корабль", world.time, 5 MINUTES, null)
	TEST_ASSERT(pirates.pirates_spawned, "Оплаченный выкуп не снял угрозу")
	TEST_ASSERT_EQUAL(treasury.account_balance, 100000 - payoff, "Выкуп не списан с казны")
	TEST_ASSERT_EQUAL(cargo.account_balance, cargo_before, "Выкуп тронул бюджет карго")
	qdel(threat)
	finish(pirates)
	econ_test_set_balance(treasury, 10000)
	TEST_ASSERT_EQUAL(econ_ransom_demand(SSeconomy.settings.event_ransom_min, SSeconomy.settings.event_ransom_share), SSeconomy.settings.event_ransom_min, "Бедной казне - минимальное требование")
	TEST_ASSERT(!pirates_pay_ransom(SSeconomy.settings.event_ransom_min, "Тестовый корабль"), "Выкуп больше казны оплачен")
	TEST_ASSERT_EQUAL(treasury.account_balance, 10000, "Казна ушла в минус или потеряла деньги")

/// Деньги на чужих, спящих, внестанционных счетах и в наличных остаются в подсчёте состояния.
/datum/unit_test/economy_events/hidden_money/Run()
	var/datum/bank_account/anonymous/stash = allocate(/datum/bank_account/anonymous, "Анонимный")
	var/datum/bank_account/unowned = allocate(/datum/bank_account, "Счёт без владельца")
	var/datum/bank_account/friend = allocate(/datum/bank_account, "Знакомый")
	friend.department_id = ACCOUNT_CIV
	var/datum/bank_account/ghost = allocate(/datum/bank_account, "Будущая гост-роль")
	ghost.department_id = ACCOUNT_CIV
	econ_test_set_balance(treasury, 6000)
	var/list/totals = SSeconomy.state_totals()
	var/money_before = totals["money"]
	var/crew_before = totals["crew"]
	for(var/datum/bank_account/hideout as anything in list(stash, unowned, friend, ghost))
		TEST_ASSERT(SSeconomy.move(treasury, hideout, 1000, ECON_BUDGET_TRANSFER), "Перевод на [hideout.account_holder]")
	TEST_ASSERT(SSeconomy.move(treasury, SSeconomy.cash_account, 1000, ECON_CASH_OUT), "Снятие наличных")
	friend.state = ACCOUNT_DORMANT
	ghost.offstation = TRUE
	totals = SSeconomy.state_totals()
	TEST_ASSERT_EQUAL(totals["money"], money_before, "Спрятанные деньги выпали из подсчёта состояния")
	TEST_ASSERT_EQUAL(totals["crew"], crew_before - 2, "Спящий и гост-роль остались в экипаже")
	SSeconomy.move(SSeconomy.cash_account, treasury, 1000, ECON_CASH_IN)

/// Грант NT выдаётся только бедной станции с дефицитом до черты бедности и равен ему в пределах настроек.
/datum/unit_test/economy_events/grant/Run()
	var/datum/bank_account/worker = allocate(/datum/bank_account, "Работник")
	worker.department_id = ACCOUNT_CIV
	var/list/totals = SSeconomy.state_totals()
	var/crew = totals["crew"]
	TEST_ASSERT(crew >= 1, "Нет экипажа")
	SSeconomy.settings.state_poor_per_capita = (totals["money"] + 7000) / crew
	SSeconomy.economy_state = ECON_STATE_NORMAL
	var/before = treasury.account_balance
	var/datum/round_event/nt_grant/grant = new(FALSE)
	grant.triggered_randomly = TRUE
	grant.start()
	finish(grant)
	TEST_ASSERT_EQUAL(treasury.account_balance, before, "Грант выдан небедной станции")
	SSeconomy.economy_state = ECON_STATE_POOR
	grant = new(FALSE)
	grant.triggered_randomly = TRUE
	grant.start()
	finish(grant)
	TEST_ASSERT_EQUAL(treasury.account_balance - before, 7000, "Грант не равен дефициту")
	SSeconomy.settings.state_poor_per_capita = 0
	before = treasury.account_balance
	grant = new(FALSE)
	grant.start()
	finish(grant)
	TEST_ASSERT_EQUAL(treasury.account_balance, before, "Грант выдан без дефицита")
	totals = SSeconomy.state_totals()
	SSeconomy.settings.state_poor_per_capita = (totals["money"] + 1000000) / totals["crew"]
	grant = new(FALSE)
	grant.start()
	finish(grant)
	TEST_ASSERT_EQUAL(treasury.account_balance - before, SSeconomy.settings.event_grant_max, "Грант выше потолка")

/// Гуманитарная поставка сбрасывает капсулу с ящиком базовых припасов в отсек снабжения бесплатно.
/datum/unit_test/economy_events/aid
	var/area/station_bay
	var/turf/open/floor/bay_floor
	var/area/floor_area

/datum/unit_test/economy_events/aid/Destroy()
	if(bay_floor)
		floor_area.contents += bay_floor
		bay_floor = null
		floor_area = null
	GLOB.areas_by_type[/area/cargo/storage] = station_bay
	station_bay = null
	return ..()

/// Отсек снабжения из одного свободного станционного пола: поставка обязана сесть на него.
/datum/unit_test/economy_events/aid/proc/make_test_bay()
	var/static/area/cargo/storage/test_bay
	station_bay = GLOB.areas_by_type[/area/cargo/storage]
	if(!test_bay)
		test_bay = new
	GLOB.areas_by_type[/area/cargo/storage] = test_bay
	bay_floor = find_walkable_station_turf()
	if(!istype(bay_floor))
		return null
	floor_area = bay_floor.loc
	test_bay.contents += bay_floor
	return bay_floor

/datum/unit_test/economy_events/aid/Run()
	var/turf/open/floor/landing = make_test_bay()
	TEST_ASSERT_NOTNULL(landing, "Нет свободного станционного пола под отсек снабжения")
	var/cargo_before = cargo.account_balance
	var/treasury_before = treasury.account_balance
	var/datum/round_event/nt_aid_shipment/aid = new(FALSE)
	aid.triggered_randomly = TRUE
	SSeconomy.economy_state = ECON_STATE_NORMAL
	aid.start()
	TEST_ASSERT_NULL(aid.pod_ref, "Поставка небедной станции")
	SSeconomy.economy_state = ECON_STATE_POOR
	aid.start()
	var/obj/structure/closet/supplypod/pod = aid.pod_ref?.resolve()
	finish(aid)
	TEST_ASSERT_NOTNULL(pod, "Капсула не отправлена")
	var/obj/structure/closet/crate/crate = locate() in pod
	TEST_ASSERT_NOTNULL(crate, "В капсуле нет ящика")
	var/obj/effect/pod_landingzone/zone
	for(var/obj/effect/pod_landingzone/each in landing)
		if(each.pod == pod)
			zone = each
	TEST_ASSERT_NOTNULL(zone, "Нет зоны посадки капсулы в отсеке снабжения")
	TEST_ASSERT_EQUAL(cargo.account_balance, cargo_before, "Поставка списала бюджет карго")
	TEST_ASSERT_EQUAL(treasury.account_balance, treasury_before, "Поставка списала казну")
	for(var/atom/movable/thing as anything in crate.GetAllContents() - crate)
		TEST_ASSERT(thing.econ_imported, "[thing] из поставки не помечен купленным")
	var/obj/item/sample
	var/obj/item/fresh
	var/fresh_value = 0
	for(var/obj/item/candidate in crate)
		if(isstack(candidate))
			continue
		var/obj/item/copy = allocate(candidate.type)
		var/value = econ_export_report_value(export_item_and_contents(copy, EXPORT_CARGO, delete_unsold = FALSE, dry_run = TRUE))
		if(value > 0)
			sample = candidate
			fresh = copy
			fresh_value = value
			break
	TEST_ASSERT_NOTNULL(sample, "В поставке нет вещи с ценой")
	var/sample_value = econ_export_report_value(export_item_and_contents(sample, EXPORT_CARGO, delete_unsold = FALSE, dry_run = TRUE))
	TEST_ASSERT(sample_value <= fresh_value * econ_import_resale_factor() + 1, "[sample] из поставки продаётся за [sample_value] при цене новой [fresh_value]")
	var/datum/bounty/item/bounty = new
	bounty.wanted_types = typecacheof(list(sample.type))
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_CIV, bounty)
	TEST_ASSERT(!contract.wants(sample), "Контракт засчитывает вещь из поставки")
	TEST_ASSERT(contract.wants(fresh), "Контракт не берёт такую же вещь со станции")
	qdel(contract)
	var/datum/market_offer/offer = new("vey_med", sample.type, "тест", 1, 2, 10)
	TEST_ASSERT(!offer.matches(sample), "Спецзаказ засчитывает вещь из поставки")
	TEST_ASSERT(offer.matches(fresh), "Спецзаказ не берёт такую же вещь со станции")
	qdel(offer)
	QDEL_LIST(crate.contents)
	qdel(crate)
	qdel(zone.helper)
	qdel(zone)
	qdel(pod)

/// Без отсека снабжения на карте (SmolStation) поставка садится в другой отсек снабжения станции.
/datum/unit_test/economy_events/aid_without_cargo_bay
	var/area/hidden_bay

/datum/unit_test/economy_events/aid_without_cargo_bay/Destroy()
	if(hidden_bay)
		GLOB.areas_by_type[/area/cargo/storage] = hidden_bay
		hidden_bay = null
	return ..()

/datum/unit_test/economy_events/aid_without_cargo_bay/Run()
	hidden_bay = GLOB.areas_by_type[/area/cargo/storage]
	GLOB.areas_by_type[/area/cargo/storage] = null
	var/datum/round_event/nt_aid_shipment/aid = new(FALSE)
	SSeconomy.economy_state = ECON_STATE_POOR
	aid.start()
	var/obj/structure/closet/supplypod/pod = aid.pod_ref?.resolve()
	finish(aid)
	TEST_ASSERT_NOTNULL(pod, "Без отсека снабжения капсула не отправлена")
	var/obj/effect/pod_landingzone/zone
	for(var/area/cargo/cargo_area in GLOB.sortedAreas)
		for(var/turf/area_turf in cargo_area.contents)
			for(var/obj/effect/pod_landingzone/each in area_turf)
				if(each.pod == pod)
					zone = each
	TEST_ASSERT_NOTNULL(zone, "Капсула садится не в отсек снабжения")
	TEST_ASSERT(is_station_level(zone.z), "Капсула садится не на станцию")
	QDEL_LIST(pod.contents)
	qdel(zone.helper)
	qdel(zone)
	qdel(pod)

/// Директор не выбирает поставку, которую нельзя отправить: preflight называет причину; бедной станции с местом посадки - готова.
/datum/unit_test/economy_events/aid_preflight/Run()
	var/datum/round_event_control/nt_aid_shipment/control = registered(/datum/round_event_control/nt_aid_shipment)
	TEST_ASSERT_NOTNULL(control, "Поставка не зарегистрирована у директора")
	SSeconomy.economy_state = ECON_STATE_NORMAL
	TEST_ASSERT(SSdirector.action_preflight(control) == FALSE, "Preflight пропустил поставку небедной станции")
	TEST_ASSERT(length(control.director_preflight_failure), "Preflight не назвал причину отказа")
	SSeconomy.economy_state = ECON_STATE_POOR
	TEST_ASSERT(SSdirector.action_preflight(control), "Preflight отказал бедной станции: [control.director_preflight_failure]")

/// Сорванный в start() запуск поставки не съедает число запусков события.
/datum/unit_test/economy_events/aid_race_keeps_occurrence
	var/datum/round_event_control/nt_aid_shipment/control
	var/saved_occurrences

/datum/unit_test/economy_events/aid_race_keeps_occurrence/Destroy()
	if(control)
		control.occurrences = saved_occurrences
		control = null
	return ..()

/datum/unit_test/economy_events/aid_race_keeps_occurrence/Run()
	control = registered(/datum/round_event_control/nt_aid_shipment)
	TEST_ASSERT_NOTNULL(control, "Поставка не зарегистрирована у директора")
	saved_occurrences = control.occurrences
	control.occurrences = 1
	var/datum/round_event/nt_aid_shipment/aid = new(FALSE)
	aid.control = control
	aid.triggered_randomly = TRUE
	SSeconomy.economy_state = ECON_STATE_NORMAL
	aid.start()
	finish(aid)
	TEST_ASSERT_NULL(aid.pod_ref, "Поставка небедной станции")
	TEST_ASSERT_EQUAL(control.occurrences, 0, "Отменённая поставка съела запуск события")

GLOBAL_DATUM(econ_test_shuttle_load, /datum/callback)

/datum/controller/subsystem/shuttle/action_load(datum/map_template/shuttle/loading_template, obj/docking_port/stationary/destination_port, replace = FALSE)
	if(GLOB.econ_test_shuttle_load)
		return GLOB.econ_test_shuttle_load.Invoke()
	return ..()

/// Покупка шаттла списывает цену до загрузки, сорванная загрузка возвращает деньги и защиту бюджета от возврата излишка.
/datum/unit_test/economy_events/shuttle_purchase
	var/saved_custom_shuttles
	var/saved_purchased
	var/saved_existing
	var/list/saved_shield
	var/shuttle_cost = 0
	var/load_succeeds = TRUE
	var/spent_during_load = FALSE
	var/datum/map_template/shuttle/template
	var/obj/machinery/computer/communications/console
	var/mob/living/carbon/human/captain

/datum/unit_test/economy_events/shuttle_purchase/Destroy()
	GLOB.econ_test_shuttle_load = null
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= captain
	SSmapping.config.allow_custom_shuttles = saved_custom_shuttles
	SSshuttle.shuttle_purchased = saved_purchased
	SSshuttle.existing_shuttle = saved_existing
	if(saved_shield)
		cargo.department.shield = saved_shield
	saved_existing = null
	template = null
	console = null
	captain = null
	return ..()

/datum/unit_test/economy_events/shuttle_purchase/proc/fake_load()
	spent_during_load = cargo.debit(shuttle_cost, ECON_PURCHASE, null, "Тест: другая покупка во время загрузки")
	return load_succeeds ? SSshuttle.emergency : null

/// Консоль связи с капитаном на станции и первый продаваемый шаттл, цена которого положительна или отрицательна.
/datum/unit_test/economy_events/shuttle_purchase/proc/prepare(negative)
	saved_custom_shuttles = SSmapping.config.allow_custom_shuttles
	saved_purchased = SSshuttle.shuttle_purchased
	saved_existing = SSshuttle.existing_shuttle
	saved_shield = cargo.department.shield.Copy()
	SSmapping.config.allow_custom_shuttles = TRUE
	for(var/id in SSmapping.shuttle_templates)
		var/datum/map_template/shuttle/candidate = SSmapping.shuttle_templates[id]
		if(candidate.can_be_bought && candidate.credit_cost != INFINITY && candidate.credit_cost && (candidate.credit_cost < 0) == negative && candidate.prerequisites_met())
			template = candidate
			break
	TEST_ASSERT_NOTNULL(template, "Нет шаттла на продажу")
	shuttle_cost = template.credit_cost
	var/turf/open/spot = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(spot, "Есть станционный турф")
	console = allocate(/obj/machinery/computer/communications, spot)
	captain = allocate(/mob/living/carbon/human, spot)
	console.authenticated = TRUE
	console.authorize_access = list(ACCESS_CAPTAIN)
	TEST_ASSERT_EQUAL(console.can_buy_shuttles(captain), TRUE, "Консоль не даёт купить шаттл")
	GLOB.econ_test_shuttle_load = CALLBACK(src, PROC_REF(fake_load))

/datum/unit_test/economy_events/shuttle_purchase/proc/buy(shield = 0)
	SSshuttle.shuttle_purchased = SHUTTLEPURCHASE_PURCHASABLE
	SSshuttle.existing_shuttle = saved_existing
	spent_during_load = FALSE
	cargo.department.shield = list()
	econ_test_set_balance(cargo, max(shuttle_cost, 0))
	if(shield)
		cargo.department.add_shield(shield)
	var/datum/tgui/console_ui = allocate(/datum/tgui, captain, console, "CommunicationsConsole")
	console_ui.status = UI_INTERACTIVE
	usr = captain
	console.ui_act("purchaseShuttle", list("shuttle" = REF(template)), console_ui)
	usr = null

/datum/unit_test/economy_events/shuttle_purchase/Run()
	prepare(FALSE)
	buy()
	TEST_ASSERT_EQUAL(SSshuttle.shuttle_purchased, SHUTTLEPURCHASE_PURCHASED, "Шаттл не куплен")
	TEST_ASSERT(!spent_during_load, "Бюджет снабжения потрачен во время загрузки, шаттл достался даром")
	TEST_ASSERT_EQUAL(cargo.account_balance, 0, "Цена шаттла не списана")
	load_succeeds = FALSE
	buy(shuttle_cost)
	TEST_ASSERT_EQUAL(SSshuttle.shuttle_purchased, SHUTTLEPURCHASE_PURCHASABLE, "Сорванная загрузка оставила шаттл купленным")
	TEST_ASSERT_EQUAL(cargo.account_balance, shuttle_cost, "Сорванная загрузка не вернула деньги")
	TEST_ASSERT_EQUAL(cargo.department.shielded(), shuttle_cost, "Сорванная загрузка не вернула защиту бюджета от возврата излишка")

/// Шаттл с отрицательной ценой: NT доплачивает снабжению, объявление говорит о доплате, а не о цене со знаком минус.
/datum/unit_test/economy_events/shuttle_purchase/negative_cost/Run()
	prepare(TRUE)
	GLOB.player_list |= captain
	GLOB.unit_test_chat_capture = list()
	buy()
	var/list/chat = GLOB.unit_test_chat_capture
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= captain
	TEST_ASSERT_EQUAL(SSshuttle.shuttle_purchased, SHUTTLEPURCHASE_PURCHASED, "Шаттл не куплен")
	TEST_ASSERT_EQUAL(cargo.account_balance, -shuttle_cost, "NT не доплатил снабжению за шаттл")
	var/announcement
	for(var/list/line as anything in chat)
		if(line[1] == captain && findtext(line[2], "Shuttle Purchase"))
			announcement = line[2]
	TEST_ASSERT_NOTNULL(announcement, "Нет объявления о покупке шаттла")
	TEST_ASSERT(!findtext(announcement, "[shuttle_cost]"), "Объявление называет отрицательную цену: [announcement]")
	TEST_ASSERT(findtext(announcement, "[-shuttle_cost]"), "Объявление не называет доплату: [announcement]")

/// Бум двигает акции и делает горячими товары сразу, новость встаёт в очередь сводки.
/datum/unit_test/economy_events/boom/Run()
	var/list/prices = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		prices[ticker] = company.price
	var/datum/round_event/sector_boom/boom = new(FALSE)
	boom.start()
	finish(boom)
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT(company.price > prices[ticker], "[ticker] не вырос")
	var/hot = 0
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		if(commodity.hot_mult > 1)
			hot++
			TEST_ASSERT(id != COMMODITY_CONTRABAND, "Горячая контрабанда")
	TEST_ASSERT_EQUAL(hot, SSeconomy.settings.event_boom_goods, "Горячих товаров")
	TEST_ASSERT_EQUAL(length(SSmarket.pending_hot), hot, "Горячие товары не в очереди новостей")
	TEST_ASSERT(news_has(GLOB.market_station_event_news["sector_boom"]), "Нет новости о буме")

/// Обвал опускает тренды товаров и акции при объявлении, начало события не обваливает второй раз; без объявления обвал - в начале.
/datum/unit_test/economy_events/crash/Run()
	var/list/prices = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		prices[ticker] = company.price
	var/saved_surge = SSeconomy.price_surge_mult
	var/remaining = 1 - SSeconomy.settings.event_crash_trend_drop / 100
	var/datum/round_event/market_crash/crash = new(FALSE)
	crash.announce(FALSE)
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	TEST_ASSERT(abs(metals.trend - remaining) < 0.001, "Тренд металлов [metals.trend] после объявления")
	TEST_ASSERT(news_has(GLOB.market_station_event_news["market_crash"]), "Нет новости об обвале")
	var/list/after_announce = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT(company.price < prices[ticker], "[ticker] не упал при объявлении")
		after_announce[ticker] = company.price
	crash.start()
	TEST_ASSERT(abs(metals.trend - remaining) < 0.001, "Начало события обвалило второй раз")
	TEST_ASSERT(SSeconomy.price_surge_mult >= 2, "Автоматы не подорожали")
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT(abs(company.price - after_announce[ticker]) < 0.001, "[ticker] упал второй раз")
	finish(crash)
	TEST_ASSERT_EQUAL(SSeconomy.price_surge_mult, 1, "Наценка автоматов не снята")
	crash = new(FALSE)
	crash.start()
	TEST_ASSERT(abs(metals.trend - remaining * remaining) < 0.001, "Без объявления обвала нет в начале события")
	TEST_ASSERT(!crash.stocks_crashed, "Обвал в кулдауне биржи считает акции упавшими")
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT(abs(company.price - after_announce[ticker]) < 0.001, "[ticker] упал в кулдауне биржи")
	finish(crash)
	SSeconomy.price_surge_mult = saved_surge

/// Дефицит поднимает тренд одного товара и держит его заданное число сдвигов рынка.
/datum/unit_test/economy_events/shortage/Run()
	var/datum/round_event/commodity_shortage/shortage = new(FALSE)
	shortage.start()
	finish(shortage)
	var/datum/commodity/target
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		if(commodity.trend > 1)
			TEST_ASSERT_NULL(target, "Дефицит у двух товаров")
			target = commodity
	TEST_ASSERT_NOTNULL(target, "Нет товара в дефиците")
	var/expected = SSeconomy.settings.event_shortage_mult
	TEST_ASSERT(abs(target.price_factor - expected) < 0.001, "Цена в дефиците [target.price_factor]")
	TEST_ASSERT(news_has(target.name), "Нет новости о дефиците")
	for(var/i in 1 to SSeconomy.settings.event_shortage_shifts)
		SSmarket.market_shift()
		TEST_ASSERT(abs(target.trend - expected) < 0.001, "Дефицит ослаб на сдвиге [i]: [target.trend]")
	SSmarket.market_shift()
	TEST_ASSERT(target.trend < expected - 0.01, "Дефицит не закончился: [target.trend]")
