/// Кэш контрабанды строит первый тик экономики; тест дожидается его или строит сам.
/proc/econ_test_contraband_ready()
	if(GLOB.econ_contraband_built)
		return
	if(GLOB.econ_contraband_building)
		var/deadline = world.time + 60 SECONDS
		UNTIL(GLOB.econ_contraband_built || !GLOB.econ_contraband_building || world.time > deadline)
	if(!GLOB.econ_contraband_built)
		econ_build_contraband_cache()

/datum/unit_test/economy_contraband_classification
	var/list/saved_market

/datum/unit_test/economy_contraband_classification/New()
	. = ..()
	saved_market = econ_test_swap_market()

/datum/unit_test/economy_contraband_classification/Destroy()
	econ_test_restore_market(saved_market)
	return ..()

/// Синдикатовские предметы - контрабанда, обычные и доступные экипажу иначе - нет; цена по ТК аплинка и рынку, стопка по числу кристаллов, потолок по чёрному рынку.
/datum/unit_test/economy_contraband_classification/Run()
	econ_test_contraband_ready()
	var/obj/item/card/id/syndicate/agent_card = allocate(/obj/item/card/id/syndicate)
	var/obj/item/card/emag/emag = allocate(/obj/item/card/emag)
	var/obj/item/clothing/glasses/thermal/syndi/thermals = allocate(/obj/item/clothing/glasses/thermal/syndi)
	TEST_ASSERT(econ_is_contraband(agent_card), "Агентская карта")
	TEST_ASSERT(econ_is_contraband(emag), "Емаг")
	TEST_ASSERT(econ_is_contraband(thermals), "Термальные очки Синдиката")
	for(var/subtype in subtypesof(/obj/item/card/id/syndicate) + subtypesof(/obj/item/card/id/inteq))
		if(ispath(subtype, /obj/item/card/id/syndicate/one_access_copy))
			TEST_ASSERT(!GLOB.econ_contraband_typecache[subtype], "Гражданскую карту Синдиката дают лоадаут и BountyVend: [subtype]")
		else
			TEST_ASSERT(GLOB.econ_contraband_typecache[subtype], "Подтип агентской карты [subtype]")
	for(var/ordinary_type in list(/obj/item/pen, /obj/item/storage/box, /obj/item/card/id, /obj/item/storage/firstaid/regular))
		var/obj/item/ordinary = allocate(ordinary_type)
		TEST_ASSERT(!econ_is_contraband(ordinary), "Обычный предмет [ordinary_type]")
	var/list/obtainable = list(
		/obj/item/ammo_box/magazine/wt550m9,
		/obj/item/storage/belt/military,
		/obj/item/melee/classic_baton/telescopic,
		/obj/item/toy/syndicateballoon,
		/obj/item/toy/eightball/haunted,
		/obj/item/suppressor,
		/obj/item/soap/syndie,
		/obj/item/clothing/gloves/tackler/combat/insulated,
		/obj/item/storage/box/syndie_kit/chameleon,
		/obj/item/book/granter/spell/summon_pie,
	)
	for(var/obtainable_type in obtainable)
		TEST_ASSERT(GLOB.econ_contraband_tc[obtainable_type], "[obtainable_type] есть в аплинке")
		TEST_ASSERT(!GLOB.econ_contraband_typecache[obtainable_type], "Экипаж получает [obtainable_type] и без аплинка")
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/commodity/contraband = SSmarket.get_commodity(COMMODITY_CONTRABAND)
	contraband.price_factor = 0.8
	var/market_factor = econ_sale_factor(COMMODITY_CONTRABAND)
	TEST_ASSERT(econ_contraband_value(agent_card) > 0, "Есть цена")
	TEST_ASSERT_EQUAL(econ_contraband_value(emag), round(GLOB.econ_contraband_tc[/obj/item/card/emag] * settings.contraband_value_per_tc * market_factor), "Емаг по ТК и рынку")
	var/obj/item/stack/telecrystal/crystals = allocate(/obj/item/stack/telecrystal, run_loc_floor_bottom_left, 5)
	TEST_ASSERT_EQUAL(econ_contraband_value(crystals), round(5 * settings.contraband_value_per_tc * market_factor), "Стопка по числу кристаллов")
	var/had_market_price = (/obj/item/card/emag in GLOB.econ_contraband_market_price)
	var/saved_market_price = GLOB.econ_contraband_market_price[/obj/item/card/emag]
	GLOB.econ_contraband_market_price[/obj/item/card/emag] = 100
	var/capped = econ_contraband_value(emag)
	var/saved_work_price = settings.work_prices[WORK_SEC_CONTRABAND]
	settings.work_prices[WORK_SEC_CONTRABAND] = 2
	var/capped_double = econ_contraband_value(emag)
	settings.work_prices[WORK_SEC_CONTRABAND] = saved_work_price
	TEST_ASSERT(capped_double * 2 * (100 + settings.work_personal_share) / 100 <= econ_blackmarket_price(100) + 2, "При прайсе 2 выплата с премией дороже чёрного рынка: [capped_double] кр. оценки")
	if(had_market_price)
		GLOB.econ_contraband_market_price[/obj/item/card/emag] = saved_market_price
	else
		GLOB.econ_contraband_market_price -= /obj/item/card/emag
	TEST_ASSERT_EQUAL(capped, round(econ_blackmarket_price(100) * 100 / (100 + settings.work_personal_share)), "Выплата с премией не дороже чёрного рынка")

/// Кэш строит тик экономики у СБ, а не первое касание хранилища.
/datum/unit_test/economy_contraband_built_on_tick/Run()
	econ_test_contraband_ready()
	var/list/saved_cache = GLOB.econ_contraband_typecache
	GLOB.econ_contraband_built = FALSE
	GLOB.econ_contraband_typecache = list()
	var/datum/economy_department/security = SSeconomy.get_department(ACCOUNT_SEC)
	security.on_economy_tick()
	var/deadline = world.time + 30 SECONDS
	UNTIL(GLOB.econ_contraband_built || world.time > deadline)
	var/rebuilt = GLOB.econ_contraband_built ? length(GLOB.econ_contraband_typecache) : 0
	if(!rebuilt)
		GLOB.econ_contraband_typecache = saved_cache
		GLOB.econ_contraband_built = TRUE
	TEST_ASSERT_EQUAL(rebuilt, length(saved_cache), "Тик СБ собрал тот же кэш")

/// Ни один тип кэша не выдают автоматы и раздатчики очков, призы аркады, лут блюспейс-крана, лоадаут и снаряжение станционных должностей.
/datum/unit_test/economy_contraband_not_obtainable/Run()
	econ_test_contraband_ready()
	var/list/sources = list()
	var/list/arcade = list()
	for(var/item in GLOB.arcade_prize_pool)
		arcade[item] = TRUE
	sources["аркада"] = arcade
	var/list/loadout = list()
	for(var/datum/gear/gear_type as anything in subtypesof(/datum/gear))
		loadout[initial(gear_type.path)] = TRUE
	sources["лоадаут"] = loadout
	var/list/outfits = list()
	for(var/datum/job/job as anything in SSjob.occupations)
		if(job.faction != "Station")
			continue
		for(var/outfit_type in list(job.outfit, job.plasma_outfit))
			if(ispath(outfit_type, /datum/outfit))
				econ_note_outfit_items(outfit_type, outfits)
	sources["должности"] = outfits
	var/list/tap_loot = list()
	for(var/spawner_type in typesof(/obj/effect/spawner/lootdrop/bluespace_tap))
		econ_note_loot_items(spawner_type, tap_loot)
	sources["блюспейс-кран"] = tap_loot
	var/list/vended = collect_vending_product_types(GLOB.econ_contraband_offstation_vendors, ACCESS_SYNDICATE)
	sources["автоматы"] = vended
	TEST_ASSERT(tap_loot[/obj/item/toy/syndicateballoon], "Лут крана прочитан")
	TEST_ASSERT(length(outfits) && length(vended), "Снаряжение и автоматы прочитаны")
	var/list/offenders = list()
	for(var/source_name in sources)
		var/list/items = sources[source_name]
		for(var/item in items)
			if(GLOB.econ_contraband_typecache[item])
				offenders += "[source_name]: [item]"
	TEST_ASSERT(!length(offenders), "Контрабанда выдаётся экипажу: [jointext(offenders, "; ")]")

/datum/unit_test/economy_contraband_build_failure_retries
	allowed_runtime_patterns = list("econ_build_contraband_cache: ")

/// Упавшая сборка снимает флаг сборки, оставляет stack_trace, следующая попытка строит кэш.
/datum/unit_test/economy_contraband_build_failure_retries/Run()
	econ_test_contraband_ready()
	var/list/saved_cache = GLOB.econ_contraband_typecache
	var/list/saved_occupations = SSjob.occupations
	GLOB.econ_contraband_built = FALSE
	SSjob.occupations = list("сломанная должность")
	econ_build_contraband_cache()
	SSjob.occupations = saved_occupations
	var/failed_building = GLOB.econ_contraband_building
	var/failed_built = GLOB.econ_contraband_built
	GLOB.econ_contraband_building = FALSE
	econ_build_contraband_cache()
	if(!GLOB.econ_contraband_built)
		GLOB.econ_contraband_typecache = saved_cache
		GLOB.econ_contraband_built = TRUE
	TEST_ASSERT(!failed_building, "Флаг сборки снят после сбоя")
	TEST_ASSERT(!failed_built, "Упавшая сборка не объявляет кэш готовым")
	TEST_ASSERT_EQUAL(length(GLOB.econ_contraband_typecache), length(saved_cache), "Повторная сборка построила кэш")

/// Надевает комбинезон и ID-карту с доступами; возвращает карту, если она на месте.
/proc/econ_test_badge(mob/living/carbon/human/wearer, list/access)
	var/obj/item/card/id/badge = new(wearer.loc)
	badge.access = access
	wearer.equip_to_slot_or_del(new /obj/item/clothing/under/color/grey(wearer.loc), ITEM_SLOT_ICLOTHING)
	wearer.equip_to_slot_or_del(badge, ITEM_SLOT_ID)
	return wearer.wear_id == badge ? badge : null

/datum/unit_test/economy_work/security
	abstract_type = /datum/unit_test/economy_work/security
	var/saved_window_start
	var/saved_paid_in_window
	var/list/saved_market
	var/list/saved_work_prices

/datum/unit_test/economy_work/security/New()
	. = ..()
	saved_market = econ_test_swap_market()
	saved_work_prices = SSeconomy.settings.work_prices.Copy()

/datum/unit_test/economy_work/security/Destroy()
	econ_test_restore_market(saved_market)
	for(var/work_type in saved_work_prices)
		SSeconomy.settings.work_prices[work_type] = saved_work_prices[work_type]
	if(!isnull(saved_window_start))
		SSeconomy.contraband_window_start = saved_window_start
		SSeconomy.contraband_paid_in_window = saved_paid_in_window
	return ..()

/datum/unit_test/economy_work/security/proc/setup_officer()
	econ_test_contraband_ready()
	saved_window_start = SSeconomy.contraband_window_start
	saved_paid_in_window = SSeconomy.contraband_paid_in_window
	SSeconomy.contraband_window_start = world.time
	SSeconomy.contraband_paid_in_window = 0
	setup_pair()
	performer_account.department_id = ACCOUNT_SEC
	budget = SSeconomy.get_dep_account(ACCOUNT_SEC)
	saved_budget = budget.account_balance
	return econ_test_badge(performer, list(ACCESS_SECURITY))

/datum/unit_test/economy_work/security/proc/hold(obj/item/thing)
	performer.put_in_active_hand(thing)
	return thing

/// Хранилище принимает только контрабанду и только от СБ; передача NT на станции платит СБ и премию офицеру.
/datum/unit_test/economy_work/security/evidence_locker/Run()
	TEST_ASSERT_NOTNULL(setup_officer(), "ID офицера надета")
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/evidence_locker/locker = allocate(/obj/machinery/evidence_locker, station_turf)
	var/obj/item/card/id/syndicate/agent_card = allocate(/obj/item/card/id/syndicate)
	TEST_ASSERT(!locker.store(hold(allocate(/obj/item/pen)), performer), "Ручку не принимает")
	TEST_ASSERT(!locker.store(hold(allocate(/obj/item/ammo_box/magazine/wt550m9)), performer), "Станционный магазин не принимает")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	var/obj/item/card/emag/emag = allocate(/obj/item/card/emag)
	stranger.put_in_active_hand(emag)
	TEST_ASSERT(!locker.store(emag, stranger), "Без доступа СБ не принимает")
	TEST_ASSERT(locker.store(hold(agent_card), performer), "Карту принимает")
	TEST_ASSERT(agent_card in locker.stored, "Карта среди улик")
	var/before = budget.account_balance
	var/value = econ_contraband_value(agent_card)
	TEST_ASSERT_EQUAL(locker.hand_over(agent_card, performer), value, "Выплата отделу")
	TEST_ASSERT_EQUAL(budget.account_balance - before, value, "Оплата изъятия")
	TEST_ASSERT(QDELETED(agent_card), "Улика ушла NT")
	TEST_ASSERT(!length(locker.stored), "Список улик пуст")
	TEST_ASSERT(performer_account.account_balance > 0, "Премия офицеру")
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, station_turf)
	TEST_ASSERT(findtext(jointext(locker.examine(viewer), "\n"), "[round(SSeconomy.settings.contraband_value_per_tc * econ_sale_factor(COMMODITY_CONTRABAND))] кр. за каждый телекристалл"), "Осмотр называет цену из настроек по рынку")
	var/obj/item/multitool/ai_detect/detector = allocate(/obj/item/multitool/ai_detect)
	TEST_ASSERT(econ_is_contraband(detector), "Мультитул-детектор ИИ - контрабанда")
	hold(detector)
	detector.melee_attack_chain(performer, locker)
	TEST_ASSERT(detector in locker.stored, "Контрабандный инструмент принимается кликом")
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)
	hold(screwdriver)
	screwdriver.melee_attack_chain(performer, locker)
	TEST_ASSERT(!(screwdriver in locker.stored) && locker.panel_open, "Обычная отвёртка открывает панель, а не сдаётся")

/// Из улики-контейнера NT забирает только контрабанду, остальное содержимое высыпается.
/datum/unit_test/economy_work/security/evidence_locker_container/Run()
	TEST_ASSERT_NOTNULL(setup_officer(), "ID офицера надета")
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/evidence_locker/locker = allocate(/obj/machinery/evidence_locker, station_turf)
	var/obj/item/storage/toolbox/syndicate/toolbox = allocate(/obj/item/storage/toolbox/syndicate)
	TEST_ASSERT(econ_is_contraband(toolbox), "Ящик Синдиката - контрабанда")
	for(var/obj/item/preloaded in toolbox.contents)
		qdel(preloaded)
	var/obj/item/pen/pen = allocate(/obj/item/pen)
	var/obj/item/card/emag/emag = allocate(/obj/item/card/emag)
	pen.forceMove(toolbox)
	emag.forceMove(toolbox)
	TEST_ASSERT(locker.store(hold(toolbox), performer), "Ящик принимает")
	TEST_ASSERT(locker.hand_over(toolbox, performer) > 0, "Ящик оплачен")
	TEST_ASSERT(QDELETED(toolbox), "Ящик ушёл NT")
	TEST_ASSERT(pen.loc == station_turf, "Ручка высыпана у хранилища")
	TEST_ASSERT(QDELETED(emag), "Вложенная контрабанда ушла вместе с ящиком")

/// Улика дороже остатка часового лимита ждёт в хранилище целиком, выплата и лимит считаются по цене работы из настроек.
/datum/unit_test/economy_work/security/evidence_locker_cap/Run()
	TEST_ASSERT_NOTNULL(setup_officer(), "ID офицера надета")
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/evidence_locker/locker = allocate(/obj/machinery/evidence_locker, station_turf)
	var/cap = SSeconomy.settings.contraband_cap_hour
	SSeconomy.contraband_paid_in_window = cap - 100
	var/obj/item/card/emag/emag = allocate(/obj/item/card/emag)
	TEST_ASSERT(econ_contraband_value(emag) > 100, "Емаг дороже остатка лимита")
	TEST_ASSERT(locker.store(hold(emag), performer), "Емаг принимает")
	var/before = budget.account_balance
	TEST_ASSERT_EQUAL(locker.hand_over(emag, performer), 0, "Улика дороже остатка лимита оплачена")
	TEST_ASSERT(!QDELETED(emag) && (emag in locker.stored), "Улика дороже остатка лимита ушла NT")
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Бюджет СБ получил часть цены улики")
	TEST_ASSERT(findtext(jointext(locker.examine(performer), " "), "осталось 100 кр."), "Осмотр называет остаток лимита")

	SSeconomy.settings.work_prices[WORK_SEC_CONTRABAND] = 2
	var/obj/item/card/id/syndicate/agent_card = allocate(/obj/item/card/id/syndicate)
	TEST_ASSERT(locker.store(hold(agent_card), performer), "Карту принимает")
	var/doubled = econ_contraband_value(agent_card) * 2
	SSeconomy.contraband_paid_in_window = cap - (doubled - 1)
	TEST_ASSERT_EQUAL(locker.hand_over(agent_card, performer), 0, "Выплата по цене работы превысила остаток лимита")
	TEST_ASSERT(agent_card in locker.stored, "Карта ушла NT сверх лимита")
	SSeconomy.contraband_paid_in_window = 0
	var/list/data = locker.ui_data(performer)
	var/list/entry
	for(var/list/item_entry as anything in data["items"])
		if(item_entry["ref"] == REF(agent_card))
			entry = item_entry
	TEST_ASSERT_NOTNULL(entry, "Карты нет в окне")
	TEST_ASSERT_EQUAL(entry["value"], doubled,"Окно показывает оценку без цены работы")
	TEST_ASSERT_EQUAL(locker.hand_over(agent_card, performer), doubled, "Выплата не по цене работы")
	TEST_ASSERT_EQUAL(budget.account_balance - before, doubled, "Бюджет СБ получил не цену работы")
	TEST_ASSERT_EQUAL(SSeconomy.contraband_cap_left(), cap - doubled, "Лимит списан не по выплате")
	var/expected_tc = round(SSeconomy.settings.contraband_value_per_tc * 2 * econ_sale_factor(COMMODITY_CONTRABAND))
	TEST_ASSERT(findtext(jointext(locker.examine(performer), " "), "[expected_tc] кр. за каждый телекристалл"), "Осмотр называет цену телекристалла без цены работы")

/// Вне станции хранилище улики держит, но NT за них не платит и не забирает.
/datum/unit_test/economy_work/security/evidence_locker_offstation/Run()
	TEST_ASSERT_NOTNULL(setup_officer(), "ID офицера надета")
	TEST_ASSERT(!is_station_level(run_loc_floor_bottom_left.z), "Тестовая резервация не станционная")
	var/obj/machinery/evidence_locker/locker = allocate(/obj/machinery/evidence_locker)
	var/obj/item/card/emag/emag = allocate(/obj/item/card/emag)
	TEST_ASSERT(locker.store(hold(emag), performer), "Улику принимает")
	var/before = budget.account_balance
	TEST_ASSERT_EQUAL(locker.hand_over(emag, performer), 0, "Вне станции не платит")
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Бюджет СБ не изменился")
	TEST_ASSERT(!QDELETED(emag) && (emag in locker.stored), "Улика осталась в хранилище")
	TEST_ASSERT(!findtext(jointext(locker.examine(performer), "\n"), "за каждый телекристалл"), "Вне станции оплату не обещает")

/datum/unit_test/economy_court_fee
	var/datum/bank_account/defendant_account
	var/datum/bank_account/department/sec_budget
	var/saved_sec_budget
	var/list/stashed_contracts

/datum/unit_test/economy_court_fee/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()

/datum/unit_test/economy_court_fee/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	if(sec_budget)
		econ_test_set_balance(sec_budget, saved_sec_budget)
	GLOB.data_core.remove_records_by_name("econ_test_defendant")
	QDEL_NULL(defendant_account)
	return ..()

/datum/unit_test/economy_court_fee/proc/make_staff(list/access)
	var/mob/living/carbon/human/staff = allocate(/mob/living/carbon/human)
	return econ_test_badge(staff, access) && staff

/datum/unit_test/economy_court_fee/proc/act(obj/machinery/computer/brig_assistant_console/console, mob/user, action, list/params)
	var/datum/tgui/window = allocate(/datum/tgui, user, console, "BrigAssistantConsole")
	window.status = UI_INTERACTIVE
	usr = user
	console.ui_act(action, params, window)
	usr = null

/datum/unit_test/economy_court_fee/proc/fines_of(record_id)
	var/datum/data/record/record = GLOB.data_core.security_by_id[record_id]
	return record.fields["fines"] || list()

/// Магистрат назначает пошлину записью СБ в пределах потолка; подсудимый платит её как штраф, деньги идут в бюджет СБ с причиной судебной пошлины.
/datum/unit_test/economy_court_fee/Run()
	sec_budget = SSeconomy.get_dep_account(ACCOUNT_SEC)
	saved_sec_budget = sec_budget.account_balance
	var/record_id = datacore_test_create_records("econ_test_defendant")
	var/obj/machinery/computer/brig_assistant_console/console = allocate(/obj/machinery/computer/brig_assistant_console)
	var/mob/living/carbon/human/magistrate = make_staff(list(ACCESS_SECURITY, ACCESS_LAWYER, ACCESS_HOS))
	var/mob/living/carbon/human/lawyer = make_staff(list(ACCESS_SECURITY, ACCESS_LAWYER, ACCESS_COURT))
	var/mob/living/carbon/human/defendant = allocate(/mob/living/carbon/human)
	TEST_ASSERT(magistrate && lawyer, "ID надеты")
	defendant_account = new("econ_test_defendant")
	defendant_account.credit(1000, ECON_ADMIN)
	var/obj/item/card/id/defendant_card = allocate(/obj/item/card/id)
	defendant_card.registered_name = "econ_test_defendant"
	defendant_card.registered_account = defendant_account
	magistrate.put_in_active_hand(defendant_card)
	console.attackby(defendant_card, magistrate)
	TEST_ASSERT(console.inserted_id == defendant_card, "Карта вставлена")
	console.finish_scan()
	var/list/magistrate_data = console.ui_data(magistrate)
	var/list/lawyer_data = console.ui_data(lawyer)
	TEST_ASSERT(magistrate_data["can_court_fee"], "Магистрату кнопка доступна")
	TEST_ASSERT(!lawyer_data["can_court_fee"], "Адвокату кнопка недоступна")
	TEST_ASSERT_EQUAL(magistrate_data["court_fee_max"], SSeconomy.settings.court_fee_max, "Потолок из настроек")
	act(console, lawyer, "court_fee", list("amount" = 200, "reason" = "Неуважение к суду"))
	TEST_ASSERT(!length(fines_of(record_id)), "Адвокат пошлину не назначает")
	act(console, magistrate, "court_fee", list("amount" = SSeconomy.settings.court_fee_max + 1, "reason" = "Неуважение к суду"))
	TEST_ASSERT(!length(fines_of(record_id)), "Пошлина выше потолка не назначается")
	act(console, magistrate, "court_fee", list("amount" = 200, "reason" = "Неуважение к суду"))
	var/list/fines = fines_of(record_id)
	TEST_ASSERT_EQUAL(length(fines), 1, "Пошлина назначена записью")
	var/datum/data/crime/fee = fines[1]
	TEST_ASSERT(fee.court_fee, "Запись помечена как пошлина")
	TEST_ASSERT_EQUAL(fee.fine, 200, "Сумма пошлины")
	TEST_ASSERT_EQUAL(defendant_account.account_balance, 1000, "Назначение денег не снимает")
	var/datum/data/crime/plain_fine = GLOB.data_core.createFineEntry("Тестовый штраф", "Тест", "Тест", "00:00:00", 100)
	GLOB.data_core.addFine(record_id, plain_fine)
	var/budget_before = sec_budget.account_balance
	var/fees_before = SSeconomy.ledger.by_reason[ECON_COURT_FEE] || 0
	var/fines_before = SSeconomy.ledger.by_reason[ECON_FINE] || 0
	act(console, defendant, "pay_fine_full", list("cdataid" = fee.dataId))
	act(console, defendant, "pay_fine_full", list("cdataid" = plain_fine.dataId))
	for(var/obj/item/paper/receipt in console.loc)
		qdel(receipt)
	TEST_ASSERT_EQUAL(defendant_account.account_balance, 700, "Подсудимый оплатил пошлину и штраф")
	TEST_ASSERT_EQUAL(sec_budget.account_balance - budget_before, 300, "Оплата в бюджете СБ")
	TEST_ASSERT_EQUAL((SSeconomy.ledger.by_reason[ECON_COURT_FEE] || 0) - fees_before, 200, "Пошлина в журнале - судебная пошлина")
	TEST_ASSERT_EQUAL((SSeconomy.ledger.by_reason[ECON_FINE] || 0) - fines_before, 100, "Штраф в журнале - штраф")

/// Улика, переданная NT из хранилища, поднимает тренд контрабанды и цены чёрного рынка.
/datum/unit_test/economy_work/security/seizure_raises_prices/Run()
	TEST_ASSERT_NOTNULL(setup_officer(), "ID офицера надета")
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/evidence_locker/locker = allocate(/obj/machinery/evidence_locker, station_turf)
	var/obj/item/card/id/syndicate/agent_card = allocate(/obj/item/card/id/syndicate)
	hold(agent_card)
	agent_card.melee_attack_chain(performer, locker)
	TEST_ASSERT(agent_card in locker.stored, "Карта не сдана кликом")
	var/datum/commodity/contraband = SSmarket.get_commodity(COMMODITY_CONTRABAND)
	contraband.trend = 1
	contraband.noise = 0
	contraband.recompute()
	var/price_before = econ_blackmarket_price(1000)
	TEST_ASSERT(locker.hand_over(agent_card, performer) > 0, "Изъятие не оплачено")
	TEST_ASSERT(contraband.trend > 1, "Тренд контрабанды не вырос")
	TEST_ASSERT(econ_blackmarket_price(1000) > price_before, "Чёрный рынок не подорожал: [price_before] -> [econ_blackmarket_price(1000)]")
