/// Макет станции: питание от своего SMES, учебные камеры и метки мест для ролей; ни камеры, ни записи экипажа не связывают его со станцией.
/datum/unit_test/antag_training_sector_station/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["station"]
	TEST_ASSERT_NOTNULL(sector, "Арена знает станционный макет.")
	var/obj/effect/landmark/antag_training/loose_mark = allocate(/obj/effect/landmark/antag_training/vault, run_loc_floor_bottom_left)
	TEST_ASSERT(!(loose_mark in GLOB.landmarks_list), "Метка полигона не попадает в общий список меток.")
	var/landmarks_before = length(GLOB.landmarks_list)
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	TEST_ASSERT_EQUAL(length(GLOB.landmarks_list), landmarks_before, "Загрузка макета не добавляет меток в общий список.")
	for(var/mark in list("vault", "ai_core", "ritual", "head_office", "abductor", "server"))
		var/turf/spot = sector.landmark_turf(mark)
		TEST_ASSERT(isopenturf(spot) && arena.inside_bounds(spot, sector.bounds), "Метка [mark] стоит на полу макета.")
	var/area/antag_training/sector/station/place = sector.sector_area
	TEST_ASSERT(istype(place), "Макет в своей области.")
	TEST_ASSERT(!(locate(/obj/effect/landmark/antag_training) in place), "Метки убираются после сбора.")
	TEST_ASSERT(place.area_flags & VALID_TERRITORY && place.area_flags & BLOBS_ALLOWED && place.area_flags & CULTMAGIC_BYPASS, "Макет допускает механики станции.")
	for(var/turf/tile as anything in sector.turfs)
		for(var/obj/thing in tile)
			TEST_ASSERT(thing.training_origin?.resolve() == arena, "[thing.type] с карты макета принадлежит арене.")
	for(var/obj/structure/filingcabinet/cabinet in place)
		TEST_ASSERT(!is_type_in_list(cabinet, list(/obj/structure/filingcabinet/security, /obj/structure/filingcabinet/medical, /obj/structure/filingcabinet/employment)), "В макете нет шкафа с записями экипажа: [cabinet.type].")
	for(var/obj/item/kirbyplants/training/potted in place)
		TEST_ASSERT(!length(potted.contents), "В горшке макета нет случайной находки: [english_list(potted.contents)].")

	var/obj/machinery/power/apc/apc = place.power_apc
	TEST_ASSERT_NOTNULL(apc, "У макета свой APC.")
	var/obj/machinery/power/smes/smes = locate() in place
	TEST_ASSERT(smes?.powernet && smes.powernet == apc.terminal?.powernet, "APC подключён к SMES щитовой.")
	var/list/budget = new_wait_budget(30 SECONDS, "APC макета получает питание от SMES")
	while(!(apc.avail() > 0 && place.powered(EQUIP) && place.powered(LIGHT)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(place.requires_power && apc.avail() > 0 && place.powered(EQUIP) && place.powered(LIGHT), "Макет запитан от сети щитовой.")
	var/turf/entrance = sector.spawn_turf()
	TEST_ASSERT(IS_DYNAMIC_LIGHTING(place) && entrance.lighting_object, "В макете работает динамический свет.")
	var/lamps = 0
	var/lit_lamps = 0
	for(var/obj/machinery/light/lamp in place)
		lamps++
		if(lamp.on)
			lit_lamps++
	TEST_ASSERT(lamps && lit_lamps * 2 >= lamps, "Горит [lit_lamps] ламп из [lamps].")

	var/list/cameras = list()
	for(var/obj/machinery/camera/training/camera in place)
		cameras += camera
	TEST_ASSERT(length(cameras) >= 6 && length(cameras) <= 8, "В макете 6-8 учебных камер, а не [length(cameras)].")
	var/obj/machinery/computer/security/training/training_console = locate() in place
	TEST_ASSERT_NOTNULL(training_console, "В макете есть учебная консоль камер.")
	var/list/training_view = training_console.get_available_cameras()
	var/obj/machinery/computer/security/station_console = allocate(/obj/machinery/computer/security, run_loc_floor_bottom_left)
	var/list/station_view = station_console.get_available_cameras()
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/station_ai = allocate(/mob/living/silicon/ai, run_loc_floor_bottom_left, null, donor)
	var/list/ai_view = station_ai.get_camera_list()
	var/list/ai_cameras = list()
	for(var/camera_name in ai_view)
		ai_cameras += ai_view[camera_name]
	for(var/obj/machinery/camera/training/camera as anything in cameras)
		TEST_ASSERT_EQUAL(training_view[camera.c_tag], camera, "Учебная консоль показывает камеру [camera.c_tag].")
		TEST_ASSERT(!(camera.c_tag in station_view), "Консоль станции не видит камеру [camera.c_tag].")
		TEST_ASSERT(!(camera in ai_cameras), "ИИ станции не видит камеру [camera.c_tag].")

	var/obj/machinery/camera/training/shown_camera = cameras[1]
	var/obj/item/paper/note = allocate(/obj/item/paper, run_loc_floor_bottom_left)
	GLOB.player_list += station_ai
	note.melee_attack_chain(session.current_body, shown_camera)
	GLOB.player_list -= station_ai
	TEST_ASSERT_NULL(station_ai.last_paper_seen, "Записка у учебной камеры не уходит ИИ станции.")

	var/mob/living/builder = session.current_body
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)
	var/obj/item/weldingtool/welder = allocate(/obj/item/weldingtool)
	welder.switched_on(builder)
	var/turf/camera_spot = get_turf(shown_camera)
	screwdriver.melee_attack_chain(builder, shown_camera)
	TEST_ASSERT(shown_camera.panel_open, "Панель учебной камеры открывается.")
	welder.melee_attack_chain(builder, shown_camera)
	TEST_ASSERT(!QDELETED(shown_camera), "Сварка не снимает учебную камеру.")
	shown_camera.take_damage(shown_camera.max_integrity * 4, BRUTE, MELEE, FALSE)
	TEST_ASSERT(QDELETED(shown_camera), "Учебную камеру можно разбить.")
	TEST_ASSERT(!(locate(/obj/item/wallframe/camera) in camera_spot) && !(locate(/obj/structure/camera_assembly) in camera_spot), "Разбитая учебная камера не оставляет рамки.")

	var/turf/build_spot = sector.spawn_turf()
	var/obj/structure/camera_assembly/assembly = allocate(/obj/structure/camera_assembly, build_spot)
	var/obj/item/stack/cable_coil/coil = allocate(/obj/item/stack/cable_coil)
	welder.melee_attack_chain(builder, assembly)
	coil.melee_attack_chain(builder, assembly)
	screwdriver.melee_attack_chain(builder, assembly)
	var/obj/machinery/camera/built = locate() in build_spot
	TEST_ASSERT(istype(built, /obj/machinery/camera/training) && length(built.network) == 1 && built.network[1] == "training", "Камера, собранная на полигоне, подключается только к учебной сети.")
	ai_view = station_ai.get_camera_list()
	for(var/camera_name in ai_view)
		TEST_ASSERT(ai_view[camera_name] != built, "ИИ станции не видит камеру, собранную на полигоне.")

	sector.unload()
	TEST_ASSERT_NULL(sector.landmark_turf("vault"), "Выгруженный макет не отдаёт клетки меток.")
	var/list/leftovers = dirty_sector_slot(sector, arena)
	TEST_ASSERT(!length(leftovers), "После выгрузки в слоте осталось: [leftovers.Join(", ")].")
	var/datum/antag_training_sector/station/load_probe/probe = new(arena)
	probe.id = sector.id
	arena.sectors[sector.id] = probe
	var/probe_loaded = probe.load()
	var/turf/seen_while_loading = probe.seen_while_loading
	probe.unload()
	arena.sectors[sector.id] = sector
	qdel(probe)
	TEST_ASSERT(probe_loaded, "Повторная загрузка макета проходит.")
	TEST_ASSERT_NULL(seen_while_loading, "Пока макет грузится, метки не отдаются.")

/datum/antag_training_sector/station/load_probe
	id = null
	var/turf/seen_while_loading

/datum/antag_training_sector/station/load_probe/after_load(datum/antag_training_arena/owner)
	. = ..()
	seen_while_loading = landmark_turf("vault")
	return .
