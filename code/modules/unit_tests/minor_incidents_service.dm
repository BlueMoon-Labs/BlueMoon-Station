/// Гости корпоратива берутся из заданного списка и отсека теста: у тестовых мобов нет клиента.
/datum/round_event/station_incident/service/corporate_mixer/test_party
	var/list/test_guests = list()
	var/area/test_area

/datum/round_event/station_incident/service/corporate_mixer/test_party/in_party_area(atom/movable/thing)
	return get_area(thing) == test_area

/datum/round_event/station_incident/service/corporate_mixer/test_party/gather_guests()
	var/list/guests = list()
	for(var/mob/living/guest as anything in test_guests)
		if(is_guest(guest))
			guests += guest
	return guests

/obj/item/minor_reliquary/test_wander
	var/turf/test_destination

/obj/item/minor_reliquary/test_wander/find_neighbour_turf()
	return test_destination

/obj/item/book/minor_manuscript/test_cache
	var/turf/test_cache_spot

/obj/item/book/minor_manuscript/test_cache/find_cache_spot()
	return test_cache_spot

/obj/item/book/minor_manuscript/test_cache/is_library_shelf(atom/place)
	return istype(place, /obj/structure/bookcase)

/datum/unit_test/minor_incidents_service

/datum/unit_test/minor_incidents_service/Run()
	check_preflight()
	check_mixer_quorum()
	check_mixer_guests()
	check_mixer_outcomes()
	check_popper()
	check_tasting_modes()
	check_orders_cookable()
	check_tasting_dish()
	check_tasting_cocktail()
	check_tasting_courier()
	check_spirit_effects()
	check_spirit_wander()
	check_spirit_calm()
	check_spirit_ritual()
	check_manuscript()
	check_manuscript_shelf()
	check_sprites()

/datum/unit_test/minor_incidents_service/proc/make_event(event_path)
	var/datum/round_event/event = allocate(event_path, FALSE)
	SSdirector.running -= event
	return event

/datum/unit_test/minor_incidents_service/proc/make_crew(job = "Assistant", turf/spot)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, spot || run_loc_floor_bottom_left)
	crew.mind_initialize()
	crew.mind.assigned_role = job
	return crew

/datum/unit_test/minor_incidents_service/proc/give_wallet(mob/living/carbon/human/owner)
	var/datum/bank_account/wallet = new("unit_test_[owner.mind.assigned_role]")
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = wallet
	owner.put_in_hands(card)
	return wallet

/datum/unit_test/minor_incidents_service/proc/full_glass()
	var/obj/item/reagent_containers/food/drinks/drinkingglass/glass = allocate(/obj/item/reagent_containers/food/drinks/drinkingglass)
	glass.reagents.add_reagent(/datum/reagent/consumable/ethanol/manhattan, 10)
	return glass

/datum/unit_test/minor_incidents_service/proc/first_export(obj/thing)
	if(!length(GLOB.exports_list))
		setupExports()
	for(var/datum/export/export as anything in GLOB.exports_list)
		if(export.applies_to(thing, EXPORT_CARGO))
			return export
	return null

/datum/unit_test/minor_incidents_service/proc/reset_budget(datum/bank_account/budget, balance)
	budget._adjust_money(balance - budget.account_balance)

/// Без подходящего отсека событие отсеивается до траты бюджета директора и называет причину.
/datum/unit_test/minor_incidents_service/proc/check_preflight()
	var/datum/round_event_control/station_incident/service/tasting_request/tasting = allocate(/datum/round_event_control/station_incident/service/tasting_request)
	TEST_ASSERT(!tasting.director_preflight(), "Дегустация без повара и бармена не проходит preflight")
	TEST_ASSERT(findtext(tasting.director_preflight_failure, "повара"), "Директор видит, что дегустации не хватает повара или бармена")
	make_crew("Cook")
	var/list/controls = list(
		/datum/round_event_control/station_incident/service/corporate_mixer,
		/datum/round_event_control/station_incident/service/tasting_request,
		/datum/round_event_control/station_incident/service/restless_spirit,
		/datum/round_event_control/station_incident/service/rare_manuscript,
	)
	for(var/control_path in controls)
		var/datum/round_event_control/station_incident/service/control = allocate(control_path)
		TEST_ASSERT_EQUAL(control.severity, DIRECTOR_SEVERITY_MINOR, "[control_path] должен быть минорным")
		TEST_ASSERT(control.description, "[control_path] без описания для панели директора")
		control.area_groups = list()
		TEST_ASSERT(!control.director_preflight(), "[control_path] без отсека не должен проходить preflight")
		TEST_ASSERT(findtext(control.director_preflight_failure, "отсека"), "[control_path] без отсека называет причину отказа")
		TEST_ASSERT(!control.execute_action(), "[control_path] без отсека не должен запускаться")

/datum/unit_test/minor_incidents_service/proc/check_mixer_quorum()
	var/datum/round_event/station_incident/service/corporate_mixer/mixer = make_event(/datum/round_event/station_incident/service/corporate_mixer)
	TEST_ASSERT_EQUAL(mixer.required_attendance(2), 3, "На малом онлайне порог не ниже трёх")
	TEST_ASSERT_EQUAL(mixer.required_attendance(10), 4, "Порог - сорок процентов экипажа")
	TEST_ASSERT_EQUAL(mixer.required_attendance(36), 5, "Порог не выше пяти")
	var/mob/living/carbon/human/clientless = make_crew()
	clientless.put_in_hands(full_glass())
	TEST_ASSERT(!(clientless in mixer.gather_guests()), "Гость без клиента не считается")

/// Засчитываются только гости в баре с колпаком, хлопушкой или напитком.
/datum/unit_test/minor_incidents_service/proc/check_mixer_guests()
	var/datum/round_event/station_incident/service/corporate_mixer/bar_only = make_event(/datum/round_event/station_incident/service/corporate_mixer)
	var/datum/round_event/station_incident/service/corporate_mixer/test_party/party = make_event(/datum/round_event/station_incident/service/corporate_mixer/test_party)
	party.test_area = get_area(run_loc_floor_bottom_left)

	var/mob/living/carbon/human/plain = make_crew()
	TEST_ASSERT(!party.is_guest(plain), "Гость без колпака, хлопушки и напитка не считается")
	TEST_ASSERT(plain.equip_to_slot_if_possible(allocate(/obj/item/clothing/head/festive), ITEM_SLOT_HEAD), "Колпак надевается")
	TEST_ASSERT(party.is_guest(plain), "Гость в колпаке считается")
	TEST_ASSERT(!bar_only.is_guest(plain), "Гость в колпаке вне бара не считается")

	var/mob/living/carbon/human/reveller = make_crew()
	reveller.put_in_hands(allocate(/obj/item/minor_party_popper))
	TEST_ASSERT(party.is_guest(reveller), "Гость с хлопушкой считается")

	var/mob/living/carbon/human/drinker = make_crew()
	var/obj/item/reagent_containers/food/drinks/drinkingglass/empty = allocate(/obj/item/reagent_containers/food/drinks/drinkingglass)
	drinker.put_in_hands(empty)
	TEST_ASSERT(!party.is_guest(drinker), "Пустой стакан не делает гостем")
	drinker.put_in_hands(full_glass())
	TEST_ASSERT(party.is_guest(drinker), "Гость с напитком считается")
	TEST_ASSERT_NOTNULL(party.held_drink(drinker), "Напиток в руке находится")

/datum/unit_test/minor_incidents_service/proc/check_mixer_outcomes()
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	TEST_ASSERT_NOTNULL(budget, "Нет бюджета сервиса")
	var/balance = budget.account_balance
	var/area/party_area = get_area(run_loc_floor_bottom_left)
	var/mob/living/carbon/human/viewer = make_crew()

	var/datum/round_event/station_incident/service/corporate_mixer/test_party/flop = make_event(/datum/round_event/station_incident/service/corporate_mixer/test_party)
	flop.test_area = party_area
	flop.quorum = 3
	var/obj/structure/minor_mixer_banner/flop_banner = allocate(/obj/structure/minor_mixer_banner)
	flop.banner_ref = WEAKREF(flop_banner)
	var/mob/living/carbon/human/lonely = make_crew()
	lonely.put_in_hands(full_glass())
	flop.test_guests = list(lonely)
	TEST_ASSERT(!flop.evaluate(), "Без кворума корпоратив переносится")
	TEST_ASSERT_EQUAL(budget.account_balance, balance, "Перенесённый корпоратив не платит")
	TEST_ASSERT(findtext(jointext(flop_banner.examine(viewer), " "), "не состоялся"), "Баннер после подсчёта показывает провал")

	var/datum/round_event/station_incident/service/corporate_mixer/test_party/party = make_event(/datum/round_event/station_incident/service/corporate_mixer/test_party)
	party.test_area = party_area
	party.quorum = 3
	var/mob/living/carbon/human/hatted = make_crew()
	hatted.equip_to_slot_if_possible(allocate(/obj/item/clothing/head/festive), ITEM_SLOT_HEAD)
	var/mob/living/carbon/human/reveller = make_crew()
	reveller.put_in_hands(allocate(/obj/item/minor_party_popper))
	var/mob/living/carbon/human/drinker = make_crew()
	drinker.put_in_hands(full_glass())
	var/list/guests = list(hatted, reveller, drinker)
	var/mob/living/carbon/human/ghost_guest = make_crew()
	ghost_guest.equip_to_slot_if_possible(allocate(/obj/item/clothing/head/festive), ITEM_SLOT_HEAD)
	ghost_guest.death()
	var/mob/living/carbon/human/bystander = make_crew()
	party.test_guests = guests + ghost_guest + bystander
	var/mob/living/carbon/human/bartender = make_crew("Bartender")
	var/datum/bank_account/tips = give_wallet(bartender)
	var/obj/structure/minor_mixer_banner/banner = allocate(/obj/structure/minor_mixer_banner)
	party.banner_ref = WEAKREF(banner)
	TEST_ASSERT(party.evaluate(), "Кворум из трёх живых гостей засчитывает корпоратив")
	TEST_ASSERT_EQUAL(party.attendance, 3, "Мёртвые и пришедшие без колпака, хлопушки и напитка не считаются")
	TEST_ASSERT_EQUAL(party.drinkers, 1, "Гости с напитками посчитаны отдельно")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 300, "Бюджет сервиса получает премию")
	TEST_ASSERT_EQUAL(tips.account_balance, 25, "Бармен получает за гостя с напитком")
	TEST_ASSERT_EQUAL(party.bartender_tip, 25, "Премия бармену записана для объявления")
	for(var/mob/living/carbon/human/guest as anything in guests)
		var/datum/component/mood/mood = guest.GetComponent(/datum/component/mood)
		TEST_ASSERT(mood?.mood_events["minor_corporate_mixer"], "Гость получает хорошее настроение")
	TEST_ASSERT(locate(/obj/effect/temp_visual/minor_confetti_burst) in get_turf(banner), "Баннер празднует конфетти")
	TEST_ASSERT(findtext(jointext(banner.examine(viewer), " "), "состоялся: 3"), "Баннер после подсчёта показывает итог")
	TEST_ASSERT(!party.evaluate(), "Повторный подсчёт ничего не начисляет")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 300, "Премия выдаётся один раз")
	TEST_ASSERT_EQUAL(tips.account_balance, 25, "Бармену платят один раз")
	TEST_ASSERT_EQUAL(party.pay_bartender(10), 150, "Премия бармену ограничена шестью гостями")
	reset_budget(budget, balance)
	qdel(tips)

	party.ends_at = world.time + 5 MINUTES
	var/obj/structure/closet/supplypod/pod = party.make_shipment()
	allocated += pod
	allocated += pod.contents
	var/obj/structure/minor_mixer_banner/shipped_banner = locate() in pod
	TEST_ASSERT_NOTNULL(shipped_banner, "В капсуле есть баннер")
	TEST_ASSERT_EQUAL(shipped_banner.party_ends_at, party.ends_at, "Отсчёт на баннере совпадает с таймером подсчёта")
	TEST_ASSERT(locate(/obj/item/minor_party_popper) in pod, "В капсуле есть хлопушки")
	TEST_ASSERT(locate(/obj/item/clothing/head/festive) in pod, "В капсуле есть колпаки")

/datum/unit_test/minor_incidents_service/proc/check_popper()
	var/obj/item/minor_party_popper/popper = allocate(/obj/item/minor_party_popper, run_loc_floor_top_right)
	var/mob/living/carbon/human/reveller = make_crew(spot = run_loc_floor_top_right)
	TEST_ASSERT(popper.pop(reveller), "Хлопушка срабатывает")
	TEST_ASSERT(popper.spent, "Хлопушка одноразовая")
	TEST_ASSERT_EQUAL(popper.icon_state, "popper_spent", "Пустая хлопушка выглядит пустой")
	TEST_ASSERT(locate(/obj/effect/decal/cleanable/confetti) in run_loc_floor_top_right, "Конфетти остаётся на полу")
	TEST_ASSERT(locate(/obj/effect/temp_visual/minor_confetti_burst) in run_loc_floor_top_right, "Хлопок даёт залп частиц")
	TEST_ASSERT(!popper.pop(reveller), "Пустая хлопушка не хлопает")

/datum/unit_test/minor_incidents_service/proc/check_tasting_modes()
	var/datum/round_event/station_incident/service/tasting_request/request = make_event(/datum/round_event/station_incident/service/tasting_request)
	TEST_ASSERT_EQUAL(request.choose_mode(FALSE, TRUE, TRUE, TRUE), "cocktail", "Бармен без повара получает коктейль")
	TEST_ASSERT_EQUAL(request.choose_mode(TRUE, TRUE, TRUE, TRUE), "dish", "При поваре заказ - блюдо")
	TEST_ASSERT_EQUAL(request.choose_mode(FALSE, FALSE, TRUE, TRUE), "dish", "Без персонала заказ уходит на кухню")
	TEST_ASSERT_EQUAL(request.choose_mode(TRUE, FALSE, FALSE, TRUE), "cocktail", "Без кухни заказ уходит в бар")
	TEST_ASSERT_NULL(request.choose_mode(TRUE, TRUE, FALSE, FALSE), "Без кухни и бара заказа нет")
	request.mode = "cocktail"
	request.choose_order()
	TEST_ASSERT(request.order_path in request.cocktail_orders, "Коктейльный заказ берётся из коктейлей")
	TEST_ASSERT(findtext(request.order_name, "("), "В названии заказа есть игровое имя рецепта")

/// Каждое блюдо и коктейль из меню реально готовится на станции.
/datum/unit_test/minor_incidents_service/proc/check_orders_cookable()
	var/datum/round_event/station_incident/service/tasting_request/request = make_event(/datum/round_event/station_incident/service/tasting_request)
	TEST_ASSERT_NOTNULL(request, "Заказ на дегустацию создаётся")
	var/list/dish_results = list()
	for(var/datum/crafting_recipe/recipe as anything in subtypesof(/datum/crafting_recipe/food))
		dish_results[initial(recipe.result)] = TRUE
	for(var/dish in request.dish_orders)
		TEST_ASSERT(dish_results[dish], "Блюдо [dish] нельзя приготовить по рецептам кухни")
	var/list/drink_results = list()
	for(var/reagent_key in GLOB.chemical_reactions_list)
		for(var/datum/chemical_reaction/reaction as anything in GLOB.chemical_reactions_list[reagent_key])
			for(var/result in reaction.results)
				drink_results[result] = TRUE
	for(var/drink in request.cocktail_orders)
		TEST_ASSERT(drink_results[drink], "Коктейль [drink] не смешивается ни одной реакцией")

/datum/unit_test/minor_incidents_service/proc/check_tasting_dish()
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	var/balance = budget.account_balance
	var/obj/item/minor_tasting_case/case = allocate(/obj/item/minor_tasting_case)
	case.set_order("dish", /obj/item/reagent_containers/food/snacks/khachapuri, "хачапури (khachapuri)", "Центральное командование")
	TEST_ASSERT(case.cooling && case.deadline_timer, "Заказ запускает охлаждение и срок")
	var/mob/living/carbon/human/chef = make_crew("Cook")
	var/datum/bank_account/wallet = give_wallet(chef)

	TEST_ASSERT(!case.try_seal(chef), "Пустой кейс не запечатывается")
	TEST_ASSERT(!case.insert_item(allocate(/obj/item/pen), chef), "В кейс кладут только еду")
	var/obj/item/reagent_containers/food/snacks/omelette/wrong = allocate(/obj/item/reagent_containers/food/snacks/omelette)
	TEST_ASSERT(case.insert_item(wrong, null), "Блюдо помещается в кейс")
	TEST_ASSERT(case.check_contents(), "Не то блюдо называется причиной отказа")
	TEST_ASSERT(!case.try_seal(chef), "Не то блюдо не запечатывается")
	TEST_ASSERT(!case.sealed, "Кейс остаётся открытым")
	TEST_ASSERT(case.eject_item(chef), "Неподходящее блюдо можно достать")
	TEST_ASSERT_NOTEQUAL(wrong.loc, case, "Блюдо покинуло кейс")

	var/obj/item/reagent_containers/food/snacks/khachapuri/dish = allocate(/obj/item/reagent_containers/food/snacks/khachapuri)
	TEST_ASSERT(case.insert_item(dish, null), "Заказанное блюдо помещается в кейс")
	dish.bitecount = 1
	TEST_ASSERT(findtext(case.check_contents(), "надкусано"), "Надкусанное блюдо не принимается")
	TEST_ASSERT(!case.try_seal(chef), "Надкусанное блюдо не запечатывается")
	dish.bitecount = 0
	TEST_ASSERT_NULL(case.check_contents(), "Заказанное блюдо подходит")
	TEST_ASSERT(case.try_seal(chef), "Кейс с заказом запечатывается")
	TEST_ASSERT(case.sealed && case.pickup_timer, "Запечатанный кейс ждёт курьера")
	TEST_ASSERT_NULL(case.deadline_timer, "После пломбы срок не истекает")
	TEST_ASSERT(!case.eject_item(chef), "Запечатанный кейс не открывается")
	TEST_ASSERT(case.complete_delivery(), "Курьер забирает заказ")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 400, "Бюджет сервиса получает оплату")
	TEST_ASSERT_EQUAL(wallet.account_balance, 150, "Запечатавший получает чаевые")
	TEST_ASSERT(!case.complete_delivery(), "Повторная сдача ничего не даёт")
	TEST_ASSERT_EQUAL(budget.account_balance, balance + 400, "Оплата бюджету один раз")
	TEST_ASSERT_EQUAL(wallet.account_balance, 150, "Чаевые один раз")
	reset_budget(budget, balance)
	qdel(case)
	qdel(wallet)

/datum/unit_test/minor_incidents_service/proc/check_tasting_cocktail()
	var/obj/item/minor_tasting_case/case = allocate(/obj/item/minor_tasting_case)
	case.set_order("cocktail", /datum/reagent/consumable/ethanol/manhattan, "коктейль «Манхэттен» (Manhattan)", "Лайнер «Северное сияние»")
	var/obj/item/reagent_containers/food/drinks/drinkingglass/glass = allocate(/obj/item/reagent_containers/food/drinks/drinkingglass)
	glass.reagents.add_reagent(/datum/reagent/consumable/ethanol/manhattan, 10)
	case.insert_item(glass, null)
	TEST_ASSERT(case.check_contents(), "Неполный стакан не принимается")
	glass.reagents.add_reagent(/datum/reagent/consumable/ethanol/manhattan, 20)
	TEST_ASSERT_NULL(case.check_contents(), "Тридцать единиц коктейля в стакане подходят")
	case.eject_item(null)
	var/obj/item/reagent_containers/food/drinks/bottle/bottle = allocate(/obj/item/reagent_containers/food/drinks/bottle)
	bottle.reagents.add_reagent(/datum/reagent/consumable/ethanol/manhattan, 30)
	case.insert_item(bottle, null)
	TEST_ASSERT(case.check_contents(), "Коктейль подают в стакане, а не в бутылке")
	case.eject_item(null)

	TEST_ASSERT(case.expire(), "Срок заказа истекает")
	TEST_ASSERT(!case.cooling, "Индикатор охлаждения гаснет")
	TEST_ASSERT(!case.insert_item(glass, null), "Отменённый заказ ничего не принимает")
	TEST_ASSERT(!case.try_seal(null), "Отменённый заказ не запечатывается")
	TEST_ASSERT(!case.expire(), "Повторное истечение ничего не меняет")

/datum/unit_test/minor_incidents_service/proc/check_tasting_courier()
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	var/balance = budget.account_balance
	var/obj/item/minor_tasting_case/case = new(run_loc_floor_top_right)
	case.set_order("dish", /obj/item/reagent_containers/food/snacks/hotdog, "хот-дог (hotdog)", "Центральное командование")
	case.insert_item(new /obj/item/reagent_containers/food/snacks/hotdog(run_loc_floor_top_right), null)
	TEST_ASSERT(case.try_seal(null), "Кейс запечатывается и без известного автора")
	TEST_ASSERT(case.call_courier(), "Курьер вылетает")
	TEST_ASSERT_NULL(case.pickup_timer, "Таймер вызова курьера погашен")
	var/obj/effect/minor_courier_pod/courier = locate() in run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(courier, "Капсула курьера садится на клетку кейса")
	TEST_ASSERT_EQUAL(courier.cargo, case, "Курьер знает свой груз")
	courier.load_cargo()
	TEST_ASSERT_EQUAL(case.loc, courier, "Кейс погружен в капсулу")
	TEST_ASSERT(case.delivered, "Погрузка оплачивает заказ")
	qdel(courier)
	TEST_ASSERT(QDELETED(case), "Улетевший кейс не остаётся в мире")
	reset_budget(budget, balance)

/datum/unit_test/minor_incidents_service/proc/check_spirit_effects()
	var/obj/item/minor_reliquary/reliquary = allocate(/obj/item/minor_reliquary)
	TEST_ASSERT(reliquary.start_haunting(1 MINUTES), "Дух просыпается")
	TEST_ASSERT(reliquary.haunted && reliquary.spook_timer && reliquary.fade_timer && reliquary.wander_timer, "Неспокойный дух держит таймеры проявлений, ухода в соседний отсек и угасания")
	TEST_ASSERT(!reliquary.start_haunting(1 MINUTES), "Второй дух в тот же реликварий не вселяется")

	var/obj/item/candle/candle = allocate(/obj/item/candle, run_loc_floor_top_right)
	candle.light()
	var/candle_range = candle.light_range
	TEST_ASSERT(reliquary.spook_candles(FALSE), "Дух заставляет свечу мигнуть")
	TEST_ASSERT(candle.lit && candle.light_range < candle_range, "Мигнувшая свеча горит, но тусклее")
	reliquary.restore_candle(WEAKREF(candle), candle_range)
	TEST_ASSERT_EQUAL(candle.light_range, candle_range, "Свет свечи возвращается")
	TEST_ASSERT(reliquary.spook_candles(TRUE), "Дух гасит свечу рядом")
	TEST_ASSERT(!candle.lit, "Свеча погасла")
	qdel(candle)

	allocate(/obj/item/pen, run_loc_floor_top_right)
	var/list/spots = list()
	for(var/obj/item/thing in range(5, reliquary))
		if(isturf(thing.loc))
			spots[thing] = thing.loc
	TEST_ASSERT(reliquary.spook_nudge(), "Дух сдвигает мелочь")
	var/moved = 0
	for(var/obj/item/thing as anything in spots)
		if(thing.loc == spots[thing])
			continue
		moved++
		TEST_ASSERT_EQUAL(get_dist(thing, spots[thing]), 1, "[thing] сдвинулся ровно на клетку")
		TEST_ASSERT(thing.w_class <= WEIGHT_CLASS_SMALL && thing != reliquary, "Сдвигаются только мелочи")
	TEST_ASSERT_EQUAL(moved, 1, "За одно проявление сдвигается одна вещь")
	TEST_ASSERT(reliquary.spook_whisper(), "Шёпот звучит всегда")
	TEST_ASSERT(reliquary.spook(), "Проявление срабатывает")
	TEST_ASSERT(reliquary.spook_timer, "Следующее проявление запланировано")

	TEST_ASSERT(reliquary.fade_out(), "Дух затихает к концу срока")
	TEST_ASSERT(!reliquary.haunted && !reliquary.calmed, "Затихший дух не делает реликварий антиквариатом")
	TEST_ASSERT_NULL(reliquary.spook_timer, "После угасания проявлений нет")
	TEST_ASSERT_NULL(reliquary.wander_timer, "После угасания дух никуда не уходит")
	TEST_ASSERT_NULL(first_export(reliquary), "Затихший сам реликварий не продаётся")

	var/obj/item/minor_reliquary/haunted_one = new(run_loc_floor_bottom_left)
	haunted_one.start_haunting(1 MINUTES)
	qdel(haunted_one)

/// Неуспокоенный дух переносит проявления в соседний отсек и снова планирует уход.
/datum/unit_test/minor_incidents_service/proc/check_spirit_wander()
	var/obj/item/minor_reliquary/test_wander/reliquary = allocate(/obj/item/minor_reliquary/test_wander)
	var/area/home = get_area(reliquary)
	TEST_ASSERT(!reliquary.is_wander_target(run_loc_floor_top_right, home), "Тот же отсек не считается соседним")
	TEST_ASSERT(!reliquary.wander(), "Спокойный дух никуда не уходит")
	reliquary.start_haunting(1 MINUTES)
	TEST_ASSERT_EQUAL(reliquary.haunt_center(), get_turf(reliquary), "Сначала дух у реликвария")
	TEST_ASSERT(!reliquary.wander(), "Без соседнего отсека дух остаётся на месте")
	TEST_ASSERT(reliquary.wander_timer, "Неудачный уход повторится позже")
	reliquary.test_destination = run_loc_floor_top_right
	TEST_ASSERT(reliquary.wander(), "Дух перебирается в соседний отсек")
	TEST_ASSERT_EQUAL(reliquary.haunt_center(), run_loc_floor_top_right, "Проявления идут на новом месте")
	TEST_ASSERT(reliquary.wander_timer, "Следующий уход запланирован")
	TEST_ASSERT(locate(/obj/effect/temp_visual/minor_spirit_shade) in get_turf(reliquary), "Уход духа виден у реликвария")
	TEST_ASSERT(locate(/obj/effect/temp_visual/minor_spirit_shade) in run_loc_floor_top_right, "Дух виден на новом месте")
	var/mob/living/carbon/human/chaplain = make_crew("Chaplain")
	TEST_ASSERT(reliquary.calm(chaplain), "Ушедший дух успокаивается через реликварий")
	TEST_ASSERT_NULL(reliquary.haunt_turf, "Успокоенный дух не держит чужой отсек")
	TEST_ASSERT_NULL(reliquary.wander_timer, "Успокоенный дух больше не уходит")

/datum/unit_test/minor_incidents_service/proc/check_spirit_calm()
	var/obj/item/minor_reliquary/reliquary = allocate(/obj/item/minor_reliquary)
	var/mob/living/carbon/human/chaplain = make_crew("Chaplain")
	chaplain.mind.isholy = TRUE
	var/mob/living/carbon/human/visitor = make_crew()
	TEST_ASSERT(reliquary.calm_chance(chaplain) < 100, "Без обряда и у священника выходит не всегда")
	TEST_ASSERT(reliquary.calm_chance(visitor) < reliquary.calm_chance(chaplain), "Мирянину нужна удача больше, чем священнику")
	TEST_ASSERT(reliquary.calm_time(visitor) > reliquary.calm_time(chaplain), "Мирянин успокаивает дольше")
	TEST_ASSERT(reliquary.is_calming_tool(allocate(/obj/item/nullrod)), "Нулевой жезл успокаивает дух")
	TEST_ASSERT(!reliquary.calm(chaplain), "Спокойный реликварий нечего успокаивать")
	reliquary.start_haunting(1 MINUTES)
	TEST_ASSERT_NULL(first_export(reliquary), "Реликварий с духом не продаётся")
	TEST_ASSERT(reliquary.calm(chaplain), "Священник успокаивает дух")
	TEST_ASSERT(reliquary.calmed && !reliquary.haunted, "Дух успокоен")
	TEST_ASSERT_NULL(reliquary.spook_timer, "Проявления прекращаются")
	TEST_ASSERT_NULL(reliquary.fade_timer, "Таймер угасания снят")
	TEST_ASSERT(locate(/obj/effect/temp_visual/minor_spirit_shade) in get_turf(reliquary), "Успокоенный дух видимо покидает реликварий")
	TEST_ASSERT_EQUAL(reliquary.name, "antique reliquary", "Реликварий становится антиквариатом")
	var/datum/component/mood/mood = chaplain.GetComponent(/datum/component/mood)
	TEST_ASSERT(mood?.mood_events["minor_spirit_calmed"], "Успокоивший получает хорошее настроение")
	var/datum/export/sale = first_export(reliquary)
	TEST_ASSERT(istype(sale, /datum/export/minor_reliquary), "Антиквариат продаётся своим экспортом")
	TEST_ASSERT_EQUAL(sale?.get_cost(reliquary, EXPORT_CARGO), 250, "Цена антиквариата")
	TEST_ASSERT(!reliquary.calm(chaplain), "Повторное успокоение ничего не даёт")
	TEST_ASSERT(!reliquary.start_haunting(1 MINUTES), "Успокоенный дух не возвращается")

/// Реликварий на алтаре с горящими свечами рядом успокаивается наверняка, в том числе нулевым жезлом через attackby.
/datum/unit_test/minor_incidents_service/proc/check_spirit_ritual()
	var/obj/item/minor_reliquary/reliquary = allocate(/obj/item/minor_reliquary)
	var/mob/living/carbon/human/chaplain = make_crew("Chaplain")
	chaplain.mind.isholy = TRUE
	var/mob/living/carbon/human/visitor = make_crew()
	reliquary.start_haunting(1 MINUTES)
	TEST_ASSERT(!reliquary.on_altar(), "На голом полу обряда нет")
	allocate(/obj/structure/sacrificealtar)
	TEST_ASSERT(reliquary.on_altar(), "Реликварий стоит на алтаре")
	var/obj/item/candle/first = allocate(/obj/item/candle, get_step(run_loc_floor_bottom_left, NORTH))
	var/obj/item/candle/second = allocate(/obj/item/candle, get_step(run_loc_floor_bottom_left, EAST))
	first.light()
	TEST_ASSERT(!reliquary.ritual_ready(), "Одной свечи для обряда мало")
	second.light()
	TEST_ASSERT(reliquary.ritual_ready(), "Алтарь и две свечи - обряд готов")
	TEST_ASSERT_EQUAL(reliquary.calm_chance(visitor), 100, "Обряд работает и у мирянина")
	TEST_ASSERT(findtext(jointext(reliquary.examine(visitor), " "), "свечей рядом: 2 из 2"), "Осмотр показывает готовность обряда")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	chaplain.put_in_hands(rod)
	TEST_ASSERT(reliquary.attackby(rod, chaplain), "Нулевой жезл запускает успокоение")
	TEST_ASSERT(reliquary.calmed, "Обряд с нулевым жезлом успокаивает дух")
	second.put_out_candle()
	TEST_ASSERT(!reliquary.ritual_ready(), "Погасшая свеча ломает обряд")

/datum/unit_test/minor_incidents_service/proc/check_manuscript()
	var/obj/item/book/minor_manuscript/test_cache/manuscript = allocate(/obj/item/book/minor_manuscript/test_cache)
	manuscript.test_cache_spot = run_loc_floor_top_right
	var/mob/living/carbon/human/curator = make_crew("Curator")
	var/datum/bank_account/wallet = give_wallet(curator)
	var/mob/living/carbon/human/reader = make_crew()
	TEST_ASSERT(isbook(manuscript), "Рукопись встаёт на книжную полку")
	TEST_ASSERT_EQUAL(manuscript.decipher_time(curator) * 2, manuscript.decipher_time(reader), "Библиотекарь расшифровывает вдвое быстрее")
	TEST_ASSERT_NULL(first_export(manuscript), "Нерасшифрованная рукопись не продаётся")
	TEST_ASSERT(manuscript.advance_stage(reader), "Первый этап расшифровки")
	TEST_ASSERT_EQUAL(manuscript.stage, 1, "Прогресс хранится в рукописи")
	TEST_ASSERT_EQUAL(manuscript.icon_state, "manuscript_open", "Вскрытая рукопись раскрыта")
	TEST_ASSERT_EQUAL(manuscript.name, "unsealed manuscript", "После вскрытия печати рукопись больше не запечатана")
	TEST_ASSERT(!findtext(manuscript.desc, "запечатанная"), "Описание вскрытой рукописи без печати")
	TEST_ASSERT(findtext(manuscript.dat, manuscript.fragments[1]), "Этап открывает первый фрагмент")
	TEST_ASSERT(!findtext(manuscript.dat, manuscript.fragments[2]), "Следующие фрагменты пока скрыты")
	TEST_ASSERT(!(locate(/obj/item/storage/toolbox/minor_keeper_stash) in run_loc_floor_top_right), "Тайник появляется только с последним фрагментом")
	manuscript.advance_stage(curator)
	manuscript.advance_stage(curator)
	TEST_ASSERT_EQUAL(manuscript.name, "transcribed manuscript", "После трёх этапов рукопись расшифрована")
	TEST_ASSERT_EQUAL(wallet.account_balance, 150, "Архивная служба платит переводчику")
	var/obj/item/paper/translation = locate() in curator.held_items
	TEST_ASSERT_NOTNULL(translation, "Перевод оказывается в руках расшифровавшего")
	allocated += translation
	TEST_ASSERT(findtext(translation.get_raw_text(), manuscript.fragments[3]), "Перевод содержит последний фрагмент")
	var/obj/item/storage/toolbox/minor_keeper_stash/stash = locate() in run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(stash, "Последний фрагмент выводит к тайнику смотрителя")
	allocated += stash
	TEST_ASSERT(locate(/obj/item/reagent_containers/food/snacks/tuna) in stash, "В тайнике консервы для кота")
	TEST_ASSERT(locate(/obj/item/toy/cattoy) in stash, "В тайнике игрушка")
	TEST_ASSERT(locate(/obj/item/stack/spacecash) in stash, "В тайнике наличные")
	TEST_ASSERT(manuscript.cache_note, "Место тайника описано словами")
	TEST_ASSERT(findtext(translation.get_raw_text(), manuscript.cache_note), "Перевод указывает, где тайник")
	TEST_ASSERT(!manuscript.advance_stage(curator), "Лишний этап ничего не даёт")
	TEST_ASSERT_EQUAL(wallet.account_balance, 150, "Перевод оплачивается один раз")
	var/papers = 0
	for(var/obj/item/paper/sheet in curator.held_items + run_loc_floor_bottom_left.contents)
		papers++
	TEST_ASSERT_EQUAL(papers, 1, "Перевод выдаётся один раз")
	var/datum/export/sale = first_export(manuscript)
	TEST_ASSERT(istype(sale, /datum/export/minor_manuscript), "Перевод продаётся своим экспортом")
	TEST_ASSERT_EQUAL(sale?.get_cost(manuscript, EXPORT_CARGO), 500, "Цена расшифрованной рукописи")
	qdel(wallet)

/// Расшифрованная рукопись с полки библиотеки поднимает настроение читателю.
/datum/unit_test/minor_incidents_service/proc/check_manuscript_shelf()
	var/obj/item/book/minor_manuscript/test_cache/manuscript = allocate(/obj/item/book/minor_manuscript/test_cache)
	var/obj/structure/bookcase/shelf = allocate(/obj/structure/bookcase, run_loc_floor_top_right)
	var/mob/living/carbon/human/reader = make_crew()
	manuscript.forceMove(shelf)
	TEST_ASSERT(!manuscript.shelved, "Нерасшифрованная рукопись на полке читателей не радует")
	manuscript.forceMove(run_loc_floor_bottom_left)
	for(var/i in 1 to 3)
		manuscript.advance_stage(null)
	TEST_ASSERT(!manuscript.reward_reader(reader), "Рукопись не с полки настроения не даёт")
	manuscript.forceMove(shelf)
	TEST_ASSERT(manuscript.shelved, "Перевод на полке числится в фонде библиотеки")
	manuscript.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(manuscript.reward_reader(reader), "Читатель рукописи с полки получает настроение")
	var/datum/component/mood/mood = reader.GetComponent(/datum/component/mood)
	TEST_ASSERT(mood?.mood_events["minor_manuscript_read"], "Настроение от рукописи записано")

/datum/unit_test/minor_incidents_service/proc/check_sprites()
	var/list/expected = list(
		'modular_bluemoon/icons/obj/minor_incidents/corporate_mixer.dmi' = list("banner", "popper", "popper_spent"),
		'modular_bluemoon/icons/obj/minor_incidents/tasting_request.dmi' = list("case_open", "case_closed", "case_lip", "led_cold", "led_sealed", "led_off"),
		'modular_bluemoon/icons/obj/minor_incidents/restless_spirit.dmi' = list("reliquary"),
		'modular_bluemoon/icons/effects/minor_incidents/restless_spirit.dmi' = list("wisp"),
		'modular_bluemoon/icons/obj/minor_incidents/rare_manuscript.dmi' = list("manuscript_sealed", "manuscript_open"),
		'icons/mob/mob.dmi' = list("ghost"),
		'icons/obj/storage.dmi' = list("toolbox_blue_old"),
	)
	for(var/icon_file in expected)
		var/list/states = icon_states(icon_file)
		for(var/state in expected[icon_file])
			TEST_ASSERT(state in states, "В [icon_file] нет состояния [state]")
	var/list/held = list(/obj/item/minor_reliquary, /obj/item/minor_party_popper, /obj/item/minor_tasting_case, /obj/item/storage/toolbox/minor_keeper_stash)
	for(var/obj/item/item_path as anything in held)
		var/state = initial(item_path.item_state)
		TEST_ASSERT(state in icon_states(initial(item_path.lefthand_file)), "У [item_path] нет спрайта в левой руке")
		TEST_ASSERT(state in icon_states(initial(item_path.righthand_file)), "У [item_path] нет спрайта в правой руке")
