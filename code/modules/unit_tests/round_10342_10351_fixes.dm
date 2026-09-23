/// Шаги глаза навигационной консоли за одно нажатие пересчитывают посадочное место один раз, после последнего шага.
/datum/unit_test/shuttle_docker_relaymove_single_check
	var/mob/camera/aiEye/remote/shuttle_docker/the_eye

/datum/unit_test/shuttle_docker_relaymove_single_check/Run()
	var/obj/machinery/computer/camera_advanced/shuttle_docker/unit_test_dedup_counter/console = \
		allocate(/obj/machinery/computer/camera_advanced/shuttle_docker/unit_test_dedup_counter)
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human)
	var/turf/start = run_loc_floor_bottom_left

	the_eye = new(null, console)
	the_eye.forceMove(start)
	the_eye.eye_user = pilot
	console.check_landing_calls = 0
	the_eye.last_checked_turf = null
	the_eye.sprint = 50

	the_eye.relaymove(pilot, EAST)
	TEST_ASSERT_EQUAL(the_eye.x, start.x + 3, "при sprint 50 глаз обязан пройти три клетки за нажатие")
	TEST_ASSERT_EQUAL(console.check_landing_calls, 1, "посадочное место пересчитано [console.check_landing_calls] раз за одно нажатие")

/datum/unit_test/shuttle_docker_relaymove_single_check/Destroy()
	if(the_eye)
		the_eye.eye_user = null
		QDEL_NULL(the_eye)
	return ..()

/// Пересечение прямоугольников доков считается числами и совпадает с прежним покоординатным.
/datum/unit_test/rect_overlap_bounds/Run()
	var/list/overlap = get_rect_overlap(1, 4, 5, 10, 8, 6, 3, 2)
	TEST_ASSERT_NOTNULL(overlap, "пересекающиеся прямоугольники дали null")
	TEST_ASSERT_EQUAL(overlap[1], 3, "x_min")
	TEST_ASSERT_EQUAL(overlap[2], 4, "y_min")
	TEST_ASSERT_EQUAL(overlap[3], 5, "x_max")
	TEST_ASSERT_EQUAL(overlap[4], 6, "y_max")

	var/list/edge = get_rect_overlap(1, 1, 5, 5, 5, 5, 9, 9)
	TEST_ASSERT_NOTNULL(edge, "прямоугольники с общим углом пересекаются по одной клетке")
	TEST_ASSERT_EQUAL(edge[1], edge[3], "общий угол - одна клетка по x")

	TEST_ASSERT_NULL(get_rect_overlap(1, 1, 4, 4, 5, 1, 9, 4), "непересекающиеся по x")
	TEST_ASSERT_NULL(get_rect_overlap(1, 1, 4, 4, 1, 6, 4, 9), "непересекающиеся по y")

/// Затяжной ветер переигрывает порыв на том же визуале турфа, а не создаёт новый объект каждые две секунды.
/datum/unit_test/space_wind_visual_reuse
	var/turf/open/subject

/datum/unit_test/space_wind_visual_reuse/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	subject = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT(istype(subject), "нет открытого турфа для визуала")

	subject.pressure_vector_x = 150
	subject.high_pressure_movements()
	var/obj/effect/temp_visual/dir_setting/space_wind/first = subject.space_wind_visual
	TEST_ASSERT_NOTNULL(first, "первый проход не создал визуал ветра")

	subject.next_space_wind_at = 0
	subject.pressure_vector_x = 150
	subject.high_pressure_movements()

	var/winds = 0
	for(var/obj/effect/temp_visual/dir_setting/space_wind/wind in subject)
		winds++
	TEST_ASSERT_EQUAL(winds, 1, "второй порыв создал [winds] визуала вместо переигрывания первого")
	TEST_ASSERT_EQUAL(subject.space_wind_visual, first, "турф сменил визуал вместо переигрывания")

	qdel(first)
	TEST_ASSERT_NULL(subject.space_wind_visual, "удалённый визуал остался в турфе")

/datum/unit_test/space_wind_visual_reuse/Destroy()
	if(subject)
		for(var/obj/effect/temp_visual/dir_setting/space_wind/wind in subject)
			qdel(wind)
		subject.pressure_vector_x = 0
		subject.pressure_difference = 0
		subject.pressure_direction = NONE
		subject.next_space_wind_at = 0
	return ..()

/// Зона с критичной машиной распознаётся без обхода её содержимого, включая собранный ускоритель частиц; обычная машина зону не защищает.
/datum/unit_test/grid_check_critical_area/Run()
	var/area/test_area = get_area(run_loc_floor_bottom_left)
	TEST_ASSERT(!area_has_critical_machine(test_area), "в пустой тестовой зоне нашлась критичная машина")

	allocate(/obj/machinery/door/airlock/engineering/glass, run_loc_floor_bottom_left)
	TEST_ASSERT(!area_has_critical_machine(test_area), "обычный шлюз посчитан критичным")

	var/obj/machinery/particle_accelerator/control_box/accelerator = allocate(/obj/machinery/particle_accelerator/control_box, locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	TEST_ASSERT(!area_has_critical_machine(test_area), "несобранный ускоритель частиц посчитан критичным")
	accelerator.critical_machine = TRUE
	TEST_ASSERT(area_has_critical_machine(test_area), "собранный ускоритель частиц не защитил свою зону")
	accelerator.critical_machine = FALSE

	allocate(/obj/machinery/door/airlock/engineering/glass/critical, run_loc_floor_top_right)
	TEST_ASSERT(area_has_critical_machine(test_area), "критичный шлюз не защитил свою зону")

/// Открытые провода ищутся по списку кабелей: только плейтинг, без дублей и без занятых турфов.
/datum/unit_test/exposed_wires_from_cable_list
	var/list/changed_turfs = list()

/datum/unit_test/exposed_wires_from_cable_list/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/open_plating = make_plating(locate(origin.x + 1, origin.y, origin.z))
	var/turf/blocked_plating = make_plating(locate(origin.x + 2, origin.y, origin.z))
	var/turf/floor_tile = locate(origin.x + 3, origin.y, origin.z)
	TEST_ASSERT(!istype(floor_tile, /turf/open/floor/plating), "контрольный турф не должен быть плейтингом")

	allocate(/obj/structure/cable, open_plating)
	allocate(/obj/structure/cable, open_plating)
	allocate(/obj/structure/cable, blocked_plating)
	allocate(/obj/structure/grille, blocked_plating)
	allocate(/obj/structure/cable, floor_tile)

	var/list/exposed = find_exposed_wires(list(origin.z))
	var/hits = 0
	for(var/turf/found as anything in exposed)
		if(found == open_plating)
			hits++
	TEST_ASSERT_EQUAL(hits, 1, "плейтинг с двумя кабелями попал в список [hits] раз")
	TEST_ASSERT(!(blocked_plating in exposed), "занятый решёткой плейтинг попал в список")
	TEST_ASSERT(!(floor_tile in exposed), "обычный пол попал в список")

/datum/unit_test/exposed_wires_from_cable_list/proc/make_plating(turf/target)
	changed_turfs[target] = target.type
	return target.ChangeTurf(/turf/open/floor/plating)

/datum/unit_test/exposed_wires_from_cable_list/Destroy()
	QDEL_LIST(allocated)
	for(var/turf/changed as anything in changed_turfs)
		changed.ChangeTurf(changed_turfs[changed])
	return ..()

/datum/atom_hud/unit_test_collect_counter
	var/collect_calls = 0

/datum/atom_hud/unit_test_collect_counter/collect_hud_images_for(mob/M, list/out, check_visibility = TRUE)
	collect_calls++
	return ..()

/// Снятие HUD с моба без клиента не собирает картинки всех атомов худа: убирать их не из чего.
/datum/unit_test/hud_removal_without_client
	var/datum/atom_hud/unit_test_collect_counter/hud

/datum/unit_test/hud_removal_without_client/Run()
	hud = new
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/marked = allocate(/mob/living/carbon/human)
	hud.add_to_hud(marked)
	hud.add_hud_to(viewer)
	TEST_ASSERT(hud.hudusers[viewer], "моб не встал в зрители худа")
	hud.collect_calls = 0

	hud.remove_hud_from(viewer, TRUE)
	TEST_ASSERT(!hud.hudusers[viewer], "моб остался в зрителях худа")
	TEST_ASSERT_EQUAL(hud.collect_calls, 0, "без клиента картинки худа собраны [hud.collect_calls] раз")

/datum/unit_test/hud_removal_without_client/Destroy()
	QDEL_NULL(hud)
	return ..()

/// Удалённая запись снимается с консолей безопасности и медицины.
/datum/unit_test/record_destroy_clears_consoles/Run()
	var/obj/machinery/computer/secure_data/sec_console = allocate(/obj/machinery/computer/secure_data)
	var/obj/machinery/computer/med_data/med_console = allocate(/obj/machinery/computer/med_data)
	var/datum/data/record/record = new
	sec_console.active1 = record
	sec_console.active2 = record
	med_console.active1 = record
	med_console.active2 = record

	qdel(record)
	TEST_ASSERT_NULL(sec_console.active1, "консоль безопасности держит удалённую запись в active1")
	TEST_ASSERT_NULL(sec_console.active2, "консоль безопасности держит удалённую запись в active2")
	TEST_ASSERT_NULL(med_console.active1, "медконсоль держит удалённую запись в active1")
	TEST_ASSERT_NULL(med_console.active2, "медконсоль держит удалённую запись в active2")

/// Глаз ИИ зажигает камеры рядом по чанкам камерасети и гасит их, уходя.
/datum/unit_test/ai_eye_camera_lights
	var/mob/camera/aiEye/eye

/datum/unit_test/ai_eye_camera_lights/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/obj/machinery/camera/near_camera = allocate(/obj/machinery/camera, locate(origin.x + 2, origin.y, origin.z))
	TEST_ASSERT(near_camera.can_use(), "тестовая камера не работает")

	eye = new(origin)
	eye.update_camera_vis()
	TEST_ASSERT(near_camera in eye.active_cameras, "камера в двух клетках не зажглась")
	TEST_ASSERT_EQUAL(near_camera.in_use_lights, 1, "счётчик подсветки камеры")

	eye.moveToNullspace()
	eye.update_camera_vis()
	TEST_ASSERT(!(near_camera in eye.active_cameras), "камера осталась гореть после ухода глаза")
	TEST_ASSERT_EQUAL(near_camera.in_use_lights, 0, "счётчик подсветки после ухода")

/datum/unit_test/ai_eye_camera_lights/Destroy()
	if(eye)
		QDEL_NULL(eye)
	return ..()

/// Костюмы ЦК наследуют защиту своей базовой темы.
/datum/unit_test/mod_theme_centcom_base/Run()
	for(var/datum/mod_theme/theme_type as anything in subtypesof(/datum/mod_theme/centcom))
		TEST_ASSERT_EQUAL(initial(theme_type.siemens_coefficient), 0, "[theme_type] проводит ток")
		TEST_ASSERT(initial(theme_type.resistance_flags) & FIRE_PROOF, "[theme_type] не огнеупорна")
