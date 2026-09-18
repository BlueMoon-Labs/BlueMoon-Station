/// Фиксированный набор целей позволяет проверить лимиты без запуска событий на карте станции.
/datum/round_event_control/station_incident/test_targets
	var/list/test_targets = list()

/datum/round_event_control/station_incident/test_targets/get_candidates(first_only = FALSE)
	return test_targets.Copy()

/datum/round_event_control/station_incident/test_targets/valid_location(atom/target)
	return TRUE

/datum/round_event/station_incident/test_counter
	var/list/affected_targets = list()

/datum/round_event/station_incident/test_counter/apply_effect(atom/target)
	if(target.name == "failed target")
		return FALSE
	affected_targets += target
	return TRUE

/datum/unit_test/station_incidents

/datum/unit_test/station_incidents/proc/make_event(event_path)
	var/datum/round_event/event = allocate(event_path, FALSE)
	SSdirector.running -= event
	return event

/datum/unit_test/station_incidents/Run()
	check_target_limits()
	check_resources()
	check_repairs()
	check_spawns()
	check_battery_and_pollen()
	check_shipment_seal()
	check_pollen_source()
	check_manifest_access()
	check_shipment_visuals()

/datum/unit_test/station_incidents/proc/check_target_limits()
	var/datum/round_event_control/station_incident/test_targets/controller = allocate(/datum/round_event_control/station_incident/test_targets)
	controller.target_type = /obj/item
	controller.target_count = 2
	var/obj/item/first = allocate(/obj/item)
	var/datum/round_event_control/station_incident/location_check = allocate(/datum/round_event_control/station_incident)
	TEST_ASSERT(!location_check.valid_location(first), "Резервный тестовый Z не является станцией")
	var/obj/item/second = allocate(/obj/item)
	var/obj/item/third = allocate(/obj/item)
	var/obj/item/failed = allocate(/obj/item)
	failed.name = "failed target"
	var/obj/item/container = allocate(/obj/item)
	var/obj/item/contained = allocate(/obj/item, container)
	controller.test_targets = list(first, second, third, failed, contained)
	TEST_ASSERT(!controller.valid_target(contained), "Предмет внутри контейнера не должен попадать в событие")
	var/datum/round_event/station_incident/test_counter/event = make_event(/datum/round_event/station_incident/test_counter)
	event.control = controller
	event.start()
	TEST_ASSERT_EQUAL(event.affected_count, 2, "Неудачная цель не должна расходовать лимит, успешных целей должно быть ровно две")
	TEST_ASSERT_EQUAL(length(event.affected_targets), 2, "Лимит ограничивает реальные эффекты")
	TEST_ASSERT(!(contained in event.affected_targets), "Нельзя затрагивать содержимое контейнера")
	TEST_ASSERT(!(failed in event.affected_targets), "Неудачный эффект не должен считаться успешным")
	controller.test_targets.Cut()
	TEST_ASSERT(!controller.director_preflight(), "Без целей событие должно отсеиваться до траты бюджета")
	TEST_ASSERT(!controller.execute_action(), "Исполнение без целей должно сообщать об отказе")
	var/datum/round_event/station_incident/test_counter/empty_event = make_event(/datum/round_event/station_incident/test_counter)
	empty_event.control = controller
	empty_event.start()
	TEST_ASSERT_EQUAL(empty_event.affected_count, 0, "Пустой запуск не создаёт последствий")

/datum/unit_test/station_incidents/proc/check_resources()
	var/obj/machinery/vending/cola/vendor = allocate(/obj/machinery/vending/cola)
	var/datum/data/vending_product/selected = vendor.product_records[1]
	for(var/datum/data/vending_product/product as anything in vendor.product_records)
		product.amount = 0
	selected.amount = 1
	var/datum/round_event/station_incident/vending_samples/samples = make_event(/datum/round_event/station_incident/vending_samples)
	var/turf/location = get_turf(vendor)
	var/list/before = location.contents.Copy()
	samples.apply_effect(vendor)
	var/list/created = location.contents - before
	allocated += created
	TEST_ASSERT_EQUAL(selected.amount, 0, "Раздача должна расходовать настоящий товар")
	var/products = 0
	for(var/obj/item/product in created)
		products++
	TEST_ASSERT_EQUAL(products, 1, "При остатке в один товар нельзя создать два пробника")

	var/obj/machinery/photocopier/copier = allocate(/obj/machinery/photocopier)
	copier.starting_paper = 2
	copier.toner_cartridge.charges = 0.125
	var/datum/round_event/station_incident/copier_spam/spam = make_event(/datum/round_event/station_incident/copier_spam)
	before = location.contents.Copy()
	spam.apply_effect(copier)
	created = location.contents - before
	allocated += created
	var/printed = 0
	for(var/obj/item/paper/form in created)
		printed++
	TEST_ASSERT_EQUAL(printed, 1, "При нехватке тонера число распечаток ограничено")
	TEST_ASSERT_EQUAL(copier.get_paper_count(), 1, "Распечатка должна расходовать бумагу")
	TEST_ASSERT_EQUAL(copier.toner_cartridge.charges, 0, "Тонер нельзя уводить в минус")

/datum/unit_test/station_incidents/proc/check_repairs()
	var/turf/open/floor/floor = run_loc_floor_bottom_left
	var/datum/round_event/station_incident/floor_damage/damage = make_event(/datum/round_event/station_incident/floor_damage)
	var/original_type = floor.type
	var/original_baseturfs = islist(floor.baseturfs) ? floor.baseturfs.Copy() : floor.baseturfs
	damage.apply_effect(floor)
	TEST_ASSERT(floor.broken, "Плитка должна повреждаться")
	TEST_ASSERT_EQUAL(floor.type, original_type, "Событие не должно превращать пол в космос или плейтинг")
	TEST_ASSERT_EQUAL(json_encode(floor.baseturfs), json_encode(original_baseturfs), "Слои палубы должны сохраниться")

	var/obj/machinery/computer/arcade/terminal = allocate(/obj/machinery/computer/arcade/battle)
	var/obj/item/circuitboard/board = terminal.circuit
	TEST_ASSERT(board, "У тестового терминала должна быть плата")
	var/datum/round_event/station_incident/terminal_burnout/burnout = make_event(/datum/round_event/station_incident/terminal_burnout)
	TEST_ASSERT(burnout.apply_effect(terminal), "Выгорание должно действительно отключать консоль")
	TEST_ASSERT_EQUAL(terminal.circuit, board, "Для ремонта должна сохраниться исходная плата")
	TEST_ASSERT(!QDELETED(board), "Плату нельзя удалять при поломке экрана")

	var/obj/machinery/hydroponics/tray = allocate(/obj/machinery/hydroponics)
	tray.myseed = new /obj/item/seeds/tomato(tray)
	var/obj/item/seeds/seed = tray.myseed
	tray.weedlevel = 2
	var/datum/round_event/station_incident/weed_bloom/weeds = make_event(/datum/round_event/station_incident/weed_bloom)
	weeds.apply_effect(tray)
	TEST_ASSERT_EQUAL(tray.weedlevel, 5, "Сорняки не должны сразу достигать порога замещения растения")
	TEST_ASSERT_EQUAL(tray.myseed, seed, "Событие должно сохранять посаженное растение")

/datum/unit_test/station_incidents/proc/check_spawns()
	var/turf/location = run_loc_floor_top_right
	var/list/spawn_events = list(
		/datum/round_event/station_incident/poultry,
		/datum/round_event/station_incident/repair_cache,
		/datum/round_event/station_incident/ore_stowaway,
		/datum/round_event/station_incident/mimic,
		/datum/round_event/station_incident/slimes,
	)
	for(var/event_path in spawn_events)
		var/datum/round_event/station_incident/event = make_event(event_path)
		var/obj/structure/closet/supplypod/pod = event.make_shipment()
		allocated += pod
		var/list/payload = pod.GetAllContents()
		allocated += payload
		var/obj/structure/closet/crate/incident_shipment/crate = locate() in pod
		TEST_ASSERT(crate, "[event_path] должен отправлять настоящий транспортный ящик")
		TEST_ASSERT(crate.manifest, "У груза должна быть накладная")
		TEST_ASSERT(length(crate.contents) > 1, "Груз должен содержать не только бумагу")
		TEST_ASSERT(!crate.opened && !crate.countdown_started, "В пути груз закрыт, отсчёт побега ещё не начался")
		// Воспроизводим выгрузку без ожидания анимации полёта капсулы.
		pod.forceMove(location)
		pod.open_pod(pod, broken = TRUE)
		TEST_ASSERT_EQUAL(crate.loc, location, "После доставки на полу должен оказаться контейнер")
		TEST_ASSERT(!crate.opened, "Капсула не должна распаковывать внутренний ящик")
		for(var/mob/living/animal in crate)
			TEST_ASSERT_EQUAL(animal.loc, crate, "Живность должна оставаться внутри до вскрытия")
		for(var/atom/thing as anything in payload)
			qdel(thing)
		qdel(pod)

/datum/unit_test/station_incidents/proc/check_shipment_seal()
	var/obj/structure/closet/crate/holding = allocate(/obj/structure/closet/crate)
	var/obj/structure/closet/crate/incident_shipment/slimes/crate = allocate(/obj/structure/closet/crate/incident_shipment/slimes, holding)
	allocated += crate.GetAllContents()
	TEST_ASSERT_NULL(crate.release_timer, "Таймер не должен идти внутри транспортного контейнера")
	crate.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(crate.release_timer, "Выгрузка должна запускать отсчёт аварии")
	TEST_ASSERT(crate.warning_timer, "Перед отказом затвора должно прозвучать повторное предупреждение")
	var/first_timer = crate.release_timer
	crate.forceMove(get_step(run_loc_floor_top_right, WEST))
	TEST_ASSERT_EQUAL(crate.release_timer, first_timer, "Перемещение не должно перезапускать минуту на ремонт")
	TEST_ASSERT(crate.repair_seal(), "Затвор можно закрепить до аварии")
	TEST_ASSERT_NULL(crate.release_timer, "Ремонт должен отменять отложенный побег")
	TEST_ASSERT_NULL(crate.warning_timer, "Исправленный контейнер не должен продолжать подавать тревогу")
	crate.release_cargo()
	TEST_ASSERT(!crate.opened, "Исправленный контейнер не должен раскрываться от старого callback")
	var/slime_count = 0
	for(var/mob/living/simple_animal/slime/slime in crate)
		slime_count++
	TEST_ASSERT_EQUAL(slime_count, 2, "Оба образца должны сохраняться для перевозки и исследований")
	TEST_ASSERT(crate.open(), "Исправленный контейнер можно намеренно открыть в камере")
	TEST_ASSERT(!crate.repair_seal(), "Ремонт не должен задним числом отменять уже состоявшийся побег")
	var/obj/structure/closet/crate/incident_shipment/poultry/unrepaired = allocate(/obj/structure/closet/crate/incident_shipment/poultry, run_loc_floor_top_right)
	allocated += unrepaired.GetAllContents()
	unrepaired.release_cargo()
	TEST_ASSERT(unrepaired.opened, "Без ремонта неисправный затвор должен выпускать содержимое")
	var/chickens = 0
	for(var/mob/living/simple_animal/chicken/bird in get_turf(unrepaired))
		chickens++
	TEST_ASSERT_EQUAL(chickens, 3, "После отказа затвора наружу выходят три реальные птицы")

/datum/unit_test/station_incidents/proc/check_battery_and_pollen()
	var/obj/machinery/power/apc/apc = allocate(/obj/machinery/power/apc)
	TEST_ASSERT(apc.cell, "У тестового APC должна быть батарея")
	apc.cell.charge = apc.cell.maxcharge
	var/original_capacity = apc.cell.maxcharge
	var/datum/round_event/station_incident/capacitor_discharge/discharge = make_event(/datum/round_event/station_incident/capacitor_discharge)
	TEST_ASSERT(discharge.apply_effect(apc), "Батарея должна разряжаться")
	TEST_ASSERT_EQUAL(apc.cell.charge, original_capacity * 0.4, "Разряд должен оставлять часть резервного питания")
	TEST_ASSERT_EQUAL(apc.cell.maxcharge, original_capacity * 0.5, "Деградация батареи требует её замены")
	TEST_ASSERT(!apc.cell.rigged, "Событие не должно превращать батарею в бомбу")

	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.mind_initialize()
	patient.mind.assigned_role = "Assistant"
	var/datum/round_event/station_incident/hay_fever/pollen = make_event(/datum/round_event/station_incident/hay_fever)
	TEST_ASSERT(pollen.expose(patient), "Пыльца должна вызывать реальный эффект")
	TEST_ASSERT_EQUAL(patient.reagents.get_reagent_amount(/datum/reagent/toxin/histamine), 4, "Доза должна оставаться ниже порога передозировки")
	patient.reagents.remove_all(100)
	TEST_ASSERT(!pollen.expose(patient), "За время выброса нельзя повторно заражать уже вылеченного человека")
	var/mob/living/carbon/human/protected = allocate(/mob/living/carbon/human)
	protected.mind_initialize()
	protected.mind.assigned_role = "Assistant"
	protected.wear_mask = allocate(/obj/item/clothing/mask/surgical, protected)
	TEST_ASSERT(!pollen.expose(protected), "Маска должна защищать от пыльцы")
	TEST_ASSERT_EQUAL(protected.reagents.get_reagent_amount(/datum/reagent/toxin/histamine), 0, "Защищённый человек не должен получать реагент")

/datum/unit_test/station_incidents/proc/check_pollen_source()
	var/obj/machinery/hydroponics/tray = allocate(/obj/machinery/hydroponics)
	tray.myseed = new /obj/item/seeds/tomato(tray)
	tray.harvest = TRUE
	var/datum/round_event/station_incident/hay_fever/pollen = make_event(/datum/round_event/station_incident/hay_fever)
	pollen.apply_effect(tray)
	var/obj/effect/incident_pollen_cloud/cloud = pollen.pollen_cloud
	TEST_ASSERT(cloud in tray.vis_contents, "Пыльца должна обозначать именно лоток-источник")
	tray.update_icon()
	TEST_ASSERT(cloud in tray.vis_contents, "Обновление растения не должно стирать пыльцу")
	tray.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(!QDELETED(cloud) && (cloud in tray.vis_contents), "Облачко должно перемещаться вместе с лотком")
	TEST_ASSERT_EQUAL(pollen.get_pollen_source(), tray, "Источником служит конкретный лоток с конкретным растением")
	tray.harvest = FALSE
	TEST_ASSERT_NULL(pollen.get_pollen_source(), "Сбор урожая должен прекращать выброс")
	tray.harvest = TRUE
	qdel(tray.myseed)
	tray.myseed = new /obj/item/seeds/tomato(tray)
	TEST_ASSERT_NULL(pollen.get_pollen_source(), "Новая посадка не должна наследовать событие старого растения")
	pollen.tick()
	TEST_ASSERT(QDELETED(cloud), "После прекращения выброса визуальная пыльца должна исчезать")
	TEST_ASSERT(!(cloud in tray.vis_contents), "После завершения события на лотке не должно оставаться визуальных объектов")
	pollen.apply_effect(tray)
	cloud = pollen.pollen_cloud
	pollen.end()
	TEST_ASSERT(QDELETED(cloud), "Естественное завершение события тоже должно убирать облако")
	pollen.apply_effect(tray)
	cloud = pollen.pollen_cloud
	qdel(tray)
	TEST_ASSERT(QDELETED(cloud), "Удаление лотка должно сразу убирать его облако")

/datum/unit_test/station_incidents/proc/check_manifest_access()
	var/obj/structure/closet/crate/incident_shipment/repair_cache/crate = allocate(/obj/structure/closet/crate/incident_shipment/repair_cache, run_loc_floor_top_right)
	allocated += crate.GetAllContents()
	var/mob/living/carbon/human/reader = allocate(/mob/living/carbon/human)
	var/obj/item/paper/note = crate.manifest
	crate.on_attack_hand(reader)
	TEST_ASSERT(!crate.opened, "Чтение накладной не должно выпускать содержимое")
	TEST_ASSERT_NULL(crate.manifest, "Первое взаимодействие снимает накладную с крышки")
	TEST_ASSERT_EQUAL(note.loc, reader, "Накладная должна оказаться в руках читателя")
	crate.on_attack_hand(reader)
	TEST_ASSERT(crate.opened, "После ознакомления ящик можно открыть обычным взаимодействием")

/// Проверяем закрытый и открытый вид, короткую анимацию и индикаторы затвора.
/datum/unit_test/station_incidents/proc/check_shipment_visuals()
	var/obj/structure/closet/crate/holding = allocate(/obj/structure/closet/crate)
	for(var/crate_path in subtypesof(/obj/structure/closet/crate/incident_shipment))
		var/obj/structure/closet/crate/incident_shipment/crate = allocate(crate_path, holding)
		allocated += crate.GetAllContents()
		var/list/states = icon_states(crate.icon)
		TEST_ASSERT(crate.icon_state in states, "Закрытый груз [crate_path] должен иметь существующий спрайт")
		TEST_ASSERT("[initial(crate.icon_state)]_rattle" in states, "Груз [crate_path] должен иметь анимацию реакции на встряску")
		var/list/closed_overlays = crate.closet_update_overlays(list())
		for(var/overlay_state in closed_overlays)
			TEST_ASSERT(overlay_state in states, "Слой [overlay_state] должен существовать в иконке ящика")
		if(crate.seal_fault)
			TEST_ASSERT("securecrater" in closed_overlays, "Неисправный затвор должен показывать красный индикатор")
#ifdef STATION_INCIDENT_VISUAL_PREVIEWS
		fcopy(getFlatIcon(crate, no_anim = TRUE), "[GLOB.log_directory]/incident_[crate.icon_state]_closed.png")
#endif
		if(crate.seal_fault)
			crate.repair_seal()
			var/list/repaired_overlays = crate.closet_update_overlays(list())
			TEST_ASSERT("securecrateg" in repaired_overlays, "После ремонта индикатор должен стать зелёным")
			TEST_ASSERT(!("securecrater" in repaired_overlays), "Красный индикатор должен погаснуть после ремонта")
#ifdef STATION_INCIDENT_VISUAL_PREVIEWS
			fcopy(getFlatIcon(crate, no_anim = TRUE), "[GLOB.log_directory]/incident_[crate.icon_state]_repaired.png")
#endif
		// Проверяем внешний вид отдельно от выпуска мобов и проходимости крышки.
		crate.opened = TRUE
		crate.update_icon()
		TEST_ASSERT(crate.icon_state in states, "Открытый груз [crate_path] должен иметь существующий спрайт")
		var/list/open_overlays = crate.closet_update_overlays(list())
		TEST_ASSERT(!("securecrater" in open_overlays) && !("securecrateg" in open_overlays), "На открытой крышке не должно быть индикатора затвора")
#ifdef STATION_INCIDENT_VISUAL_PREVIEWS
		fcopy(getFlatIcon(crate, no_anim = TRUE), "[GLOB.log_directory]/incident_[crate.icon_state]_open.png")
#endif

#ifdef STATION_INCIDENT_TESTS
TEST_FOCUS(/datum/unit_test/station_incidents)
#endif
