/// Тесты вертикального движения: zMove/can_z_move/zImpact.

/// Openspace только для тестов: без уровня снизу рисует подложку базового турфа вместо отката в пол.
/turf/open/openspace/unit_test_survives_no_bottom
	show_bottom_level = TRUE

/// Причина вертикального движения вытесняется только более приоритетной, сброс - только принудительный.
/datum/unit_test/multiz_currently_z_moving_priority

/datum/unit_test/multiz_currently_z_moving_priority/Run()
	var/obj/item/stack/sheet/metal/probe = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left)

	TEST_ASSERT(probe.set_currently_z_moving(CURRENTLY_Z_FALLING), "Первая установка причины движения должна засчитаться")
	TEST_ASSERT_EQUAL(probe.currently_z_moving, CURRENTLY_Z_FALLING, "Причина движения должна была записаться")

	TEST_ASSERT(!probe.set_currently_z_moving(CURRENTLY_Z_FALLING), "Повтор той же причины не должен считаться повышением приоритета")

	TEST_ASSERT(probe.set_currently_z_moving(CURRENTLY_Z_ASCENDING), "Подъём по лестнице должен перебивать падение")
	TEST_ASSERT_EQUAL(probe.currently_z_moving, CURRENTLY_Z_ASCENDING, "Более приоритетная причина должна была вытеснить менее приоритетную")

	TEST_ASSERT(!probe.set_currently_z_moving(CURRENTLY_Z_FALLING), "Менее приоритетная причина не должна вытеснять более приоритетную")
	TEST_ASSERT_EQUAL(probe.currently_z_moving, CURRENTLY_Z_ASCENDING, "Причина движения не должна была понизиться")

	probe.set_currently_z_moving(FALSE, TRUE)
	TEST_ASSERT_EQUAL(probe.currently_z_moving, FALSE, "Принудительный сброс должен обнулять причину движения независимо от приоритета")

/// Сбор группы переезда: буксируемые только по флагу, пристёгнутые всегда, конга-линия целиком.
/datum/unit_test/multiz_z_move_affected_group

/datum/unit_test/multiz_z_move_affected_group/Run()
	var/turf/arena = run_loc_floor_bottom_left
	var/mob/living/carbon/human/climber = allocate(/mob/living/carbon/human, arena)
	var/mob/living/carbon/human/dragged = allocate(/mob/living/carbon/human, arena)
	var/obj/structure/bed/seat = allocate(/obj/structure/bed, arena)
	var/mob/living/carbon/human/passenger = allocate(/mob/living/carbon/human, arena)

	seat.buckle_mob(passenger, force = TRUE)
	climber.start_pulling(dragged, supress_message = TRUE)
	TEST_ASSERT_EQUAL(climber.pulling, dragged, "Не удалось подготовить буксировку для теста")
	TEST_ASSERT_EQUAL(passenger.buckled, seat, "Не удалось подготовить пристёгнутого для теста")

	var/list/without_pulled = climber.get_z_move_affected(NONE)
	TEST_ASSERT(!(dragged in without_pulled), "Без ZMOVE_INCLUDE_PULLED буксируемый ехать не должен")

	var/list/with_pulled = climber.get_z_move_affected(ZMOVE_INCLUDE_PULLED)
	TEST_ASSERT(dragged in with_pulled, "С ZMOVE_INCLUDE_PULLED буксируемый должен ехать вместе с тягачом")
	TEST_ASSERT(climber in with_pulled, "Сам движимый обязан быть в списке едущих")

	var/list/seat_group = seat.get_z_move_affected(NONE)
	TEST_ASSERT(passenger in seat_group, "Пристёгнутый едет с сиденьем даже без ZMOVE_INCLUDE_PULLED")

	var/mob/living/carbon/human/tail = allocate(/mob/living/carbon/human, arena)
	dragged.start_pulling(tail, supress_message = TRUE)
	TEST_ASSERT_EQUAL(dragged.pulling, tail, "Не удалось подготовить вторую буксировку для теста")

	var/list/conga = climber.get_z_move_affected(ZMOVE_INCLUDE_PULLED)
	TEST_ASSERT(tail in conga, "Конга-линия должна собираться рекурсивно, а не рваться на втором звене")

/// Взаимный захват не должен закольцовывать сбор группы.
/datum/unit_test/multiz_mutual_pull_no_recursion

/datum/unit_test/multiz_mutual_pull_no_recursion/Run()
	var/turf/arena = run_loc_floor_bottom_left
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human, arena)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, arena)

	first.start_pulling(second, supress_message = TRUE)
	second.start_pulling(first, supress_message = TRUE)
	TEST_ASSERT_EQUAL(first.pulling, second, "Не удалось подготовить взаимный захват для теста")
	TEST_ASSERT_EQUAL(second.pulling, first, "Не удалось подготовить взаимный захват для теста")

	var/list/group = first.get_z_move_affected(ZMOVE_INCLUDE_PULLED)
	TEST_ASSERT_EQUAL(length(group), 2, "В кольцевом захвате должны собраться ровно двое, а не бесконечная цепочка")
	TEST_ASSERT(first in group, "Сам движимый обязан быть в списке едущих")
	TEST_ASSERT(second in group, "Схваченный обязан ехать вместе с тягачом")

/// zMove перевозит буксируемого вместе с тягачом и снимает флаг движения со всей группы.
/datum/unit_test/multiz_zmove_moves_whole_group

/datum/unit_test/multiz_zmove_moves_whole_group/Run()
	var/turf/source = run_loc_floor_bottom_left
	var/turf/destination = run_loc_floor_top_right
	var/mob/living/carbon/human/climber = allocate(/mob/living/carbon/human, source)
	var/mob/living/carbon/human/dragged = allocate(/mob/living/carbon/human, source)

	climber.start_pulling(dragged, supress_message = TRUE)
	TEST_ASSERT_EQUAL(climber.pulling, dragged, "Не удалось подготовить буксировку для теста")

	TEST_ASSERT(climber.zMove(null, destination, ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED), "zMove с готовой целью должен состояться")
	TEST_ASSERT_EQUAL(climber.loc, destination, "Сам движимый должен был переехать")
	TEST_ASSERT_EQUAL(dragged.loc, destination, "Буксируемый должен был переехать вместе с тягачом")
	TEST_ASSERT_EQUAL(climber.pulling, dragged, "Захват обязан пережить вертикальный переезд: forceMove ронял его на каждом участнике группы")
	TEST_ASSERT_EQUAL(climber.currently_z_moving, FALSE, "После zMove причина движения должна быть снята")
	TEST_ASSERT_EQUAL(dragged.currently_z_moving, FALSE, "После zMove причина движения должна сниматься со всей группы")

/// Незакреплённое сиденье буксируемого пассажира едет вместе с ним.
/datum/unit_test/multiz_pulled_passenger_brings_loose_seat

/datum/unit_test/multiz_pulled_passenger_brings_loose_seat/Run()
	var/turf/source = run_loc_floor_bottom_left
	var/turf/destination = run_loc_floor_top_right
	var/mob/living/carbon/human/climber = allocate(/mob/living/carbon/human, source)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, source)
	var/obj/structure/bed/roller/stretcher = allocate(/obj/structure/bed/roller, source)

	climber.start_pulling(patient, supress_message = TRUE)
	TEST_ASSERT_EQUAL(climber.pulling, patient, "Не удалось подготовить буксировку для теста")
	stretcher.buckle_mob(patient, force = TRUE)
	TEST_ASSERT_EQUAL(patient.buckled, stretcher, "Не удалось пристегнуть пациента к каталке")
	TEST_ASSERT_EQUAL(climber.pulling, patient, "Каталка не запрещает буксировку, захват должен пережить пристёгивание")

	var/list/group = climber.get_z_move_affected(ZMOVE_INCLUDE_PULLED)
	TEST_ASSERT(stretcher in group, "Незакреплённая каталка обязана ехать вместе с буксируемым пассажиром")

	TEST_ASSERT(climber.zMove(null, destination, ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED), "zMove с готовой целью должен состояться")
	TEST_ASSERT_EQUAL(patient.loc, destination, "Пациент должен был переехать")
	TEST_ASSERT_EQUAL(stretcher.loc, destination, "Каталка должна была переехать вместе с пациентом")
	TEST_ASSERT_EQUAL(patient.buckled, stretcher, "Пациент обязан приехать пристёгнутым к приехавшей каталке")

/// Прикрученное сиденье остаётся на месте, а буксируемый пассажир от него отстёгивается.
/datum/unit_test/multiz_pulled_passenger_leaves_anchored_seat

/datum/unit_test/multiz_pulled_passenger_leaves_anchored_seat/Run()
	var/turf/source = run_loc_floor_bottom_left
	var/turf/destination = run_loc_floor_top_right
	var/mob/living/carbon/human/climber = allocate(/mob/living/carbon/human, source)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, source)
	var/obj/structure/chair/seat = allocate(/obj/structure/chair, source)
	TEST_ASSERT(seat.anchored, "Тесту нужно прикрученное сиденье")

	climber.start_pulling(patient, supress_message = TRUE)
	TEST_ASSERT_EQUAL(climber.pulling, patient, "Не удалось подготовить буксировку для теста")
	seat.buckle_mob(patient, force = TRUE)
	TEST_ASSERT_EQUAL(patient.buckled, seat, "Не удалось пристегнуть пациента к стулу")

	var/list/group = climber.get_z_move_affected(ZMOVE_INCLUDE_PULLED)
	TEST_ASSERT(!(seat in group), "Прикрученный стул по лестнице ехать не должен")

	TEST_ASSERT(climber.zMove(null, destination, ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED), "zMove с готовой целью должен состояться")
	TEST_ASSERT_EQUAL(patient.loc, destination, "Пациент должен был переехать")
	TEST_ASSERT_EQUAL(seat.loc, source, "Прикрученный стул должен был остаться на месте")
	TEST_ASSERT_NULL(patient.buckled, "Пациент не может остаться пристёгнутым к стулу на другом этаже")
	TEST_ASSERT(!(patient in seat.buckled_mobs), "Стул не должен помнить уехавшего пассажира")

/// После вертикального переезда флаг движения не должен остаться ни на ком.
/datum/unit_test/multiz_buckled_clears_z_move_flag

/datum/unit_test/multiz_buckled_clears_z_move_flag/Run()
	var/turf/source = run_loc_floor_bottom_left
	var/turf/destination = run_loc_floor_top_right
	var/obj/structure/bed/seat = allocate(/obj/structure/bed, source)
	var/mob/living/carbon/human/passenger = allocate(/mob/living/carbon/human, source)

	seat.buckle_mob(passenger, force = TRUE)
	TEST_ASSERT_EQUAL(passenger.buckled, seat, "Не удалось подготовить пристёгнутого для теста")

	TEST_ASSERT(seat.zMove(null, destination, ZMOVE_ALLOW_BUCKLED|ZMOVE_CHECK_PULLEDBY), "Перемещение сиденья по вертикали должно состояться")
	TEST_ASSERT_EQUAL(passenger.loc, destination, "Пристёгнутый должен переехать вместе с сиденьем")
	TEST_ASSERT_EQUAL(passenger.buckled, seat, "Пристёгнутый обязан приехать всё ещё пристёгнутым: forceMove отстёгивал его по дороге")
	TEST_ASSERT_EQUAL(seat.currently_z_moving, FALSE, "После zMove флаг у сиденья должен быть снят")
	TEST_ASSERT_EQUAL(passenger.currently_z_moving, FALSE, "У пристёгнутого не должно остаться собственного непогашенного флага")

/// can_z_move: пол держит, дыра пускает, катуок и якорь удерживают, ZMOVE_IGNORE_OBSTACLES пробивает.
/datum/unit_test/multiz_can_z_move_obstacles

/datum/unit_test/multiz_can_z_move_obstacles/Run()
	var/turf/source = run_loc_floor_bottom_left
	var/turf/destination = run_loc_floor_top_right
	var/obj/item/stack/sheet/metal/probe = allocate(/obj/item/stack/sheet/metal, source)

	TEST_ASSERT(!probe.can_z_move(UP, source, destination, NONE), "Сквозь обычный пол сверху пройти нельзя")
	TEST_ASSERT(!probe.can_z_move(DOWN, source, destination, NONE), "Сквозь обычный пол вниз провалиться нельзя")

	TEST_ASSERT_EQUAL(probe.can_z_move(UP, source, destination, ZMOVE_IGNORE_OBSTACLES), destination, "ZMOVE_IGNORE_OBSTACLES обязан снимать проверку прохода")

	TEST_ASSERT(!probe.can_z_move(NORTH, source, destination, ZMOVE_IGNORE_OBSTACLES), "can_z_move не должен принимать горизонтальные направления")

	var/turf/open/openspace/hole = source.ChangeTurf(/turf/open/openspace/unit_test_survives_no_bottom)
	TEST_ASSERT(istype(hole), "Не удалось подготовить дырку в полу для теста")
	TEST_ASSERT(isopenspaceturf(hole), "Openspace обязан нести трейт дыры в полу")

	TEST_ASSERT_EQUAL(probe.can_z_move(DOWN, hole, destination, NONE), destination, "Из дыры в полу вниз пройти можно")

	var/obj/structure/lattice/catwalk/walkway = allocate(/obj/structure/lattice/catwalk, hole)
	TEST_ASSERT(!probe.can_z_move(DOWN, hole, destination, NONE), "Катуок обязан удержать падение")
	TEST_ASSERT_EQUAL(probe.can_z_move(DOWN, hole, destination, ZMOVE_IGNORE_OBSTACLES), destination, "ZMOVE_IGNORE_OBSTACLES обязан пробивать и катуок")

	qdel(walkway)
	TEST_ASSERT_EQUAL(probe.can_z_move(DOWN, hole, destination, NONE), destination, "Без катуока падение должно снова быть возможно")

	probe.anchored = TRUE
	TEST_ASSERT(!probe.can_z_move(DOWN, hole, destination, NONE), "Заякоренный предмет не должен проваливаться в дыру")
	probe.anchored = FALSE

/// zImpact и zFall отбивают удалённый атом и принимают живой.
/datum/unit_test/multiz_zimpact_survives_deleted_faller

/datum/unit_test/multiz_zimpact_survives_deleted_faller/Run()
	var/turf/upper = run_loc_floor_bottom_left
	var/turf/lower = run_loc_floor_top_right

	var/obj/item/stack/sheet/metal/doomed = new /obj/item/stack/sheet/metal(upper)
	qdel(doomed)
	TEST_ASSERT(QDELETED(doomed), "Не удалось подготовить удалённый стак для теста")

	TEST_ASSERT(!lower.zImpact(doomed, 1, upper), "Приземление удалённого атома должно отбиваться, а не двигать его")
	TEST_ASSERT(!lower.zFall(doomed), "Падение удалённого атома должно отбиваться")

	var/obj/item/stack/sheet/metal/survivor = allocate(/obj/item/stack/sheet/metal, upper)
	TEST_ASSERT(survivor.zMove(null, lower, ZMOVE_CHECK_PULLEDBY), "Перемещение вниз должно состояться")
	TEST_ASSERT_EQUAL(survivor.loc, lower, "Падающий должен был доехать до нижнего турфа")
	TEST_ASSERT(lower.zImpact(survivor, 2, upper), "Приземление живого атома должно состояться")

/// Лестница-терминатор перехватывает падение без сообщения и не рвёт захват.
/datum/unit_test/multiz_stairs_intercept_landing

/datum/unit_test/multiz_stairs_intercept_landing/Run()
	var/turf/landing = run_loc_floor_top_right
	var/obj/structure/stairs/steps = allocate(/obj/structure/stairs, landing)
	steps.terminator_mode = STAIR_TERMINATOR_YES

	var/obj/item/stack/sheet/metal/faller = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left)

	var/flags = steps.intercept_zImpact(list(faller), 1)
	TEST_ASSERT(flags & FALL_INTERCEPTED, "Лестница-терминатор обязана перехватывать падение")
	TEST_ASSERT(flags & FALL_NO_MESSAGE, "Перехваченное лестницей падение не должно печатать сообщение о провале")
	TEST_ASSERT(flags & FALL_RETAIN_PULL, "Лестница не должна рвать захват буксировки")

	steps.terminator_mode = STAIR_TERMINATOR_NO
	TEST_ASSERT(!(steps.intercept_zImpact(list(faller), 1) & FALL_INTERCEPTED), "Не-терминатор перехватывать падение не должен")

/// Кэш вертикальных связок покрывает все z, и участники связки делят один список.
/datum/unit_test/multiz_zlevel_stacks

/datum/unit_test/multiz_zlevel_stacks/Run()
	var/level_count = length(SSmapping.z_list)
	TEST_ASSERT(level_count > 0, "Мир без z-уровней — тестировать нечего")
	TEST_ASSERT_EQUAL(length(SSmapping.z_level_to_stack), level_count, "Кэш связок должен покрывать все z-уровни")

	for(var/z in 1 to level_count)
		var/list/stack = SSmapping.z_level_to_stack[z]
		TEST_ASSERT_NOTNULL(stack, "У z-уровня [z] нет связки — расклад не покрыл весь мир")
		TEST_ASSERT(z in stack, "z-уровень [z] обязан входить в собственную связку")

		for(var/member in stack)
			TEST_ASSERT_EQUAL(SSmapping.z_level_to_stack[member], stack, "Участники одной связки должны делить один список ([z] и [member] разошлись)")

		for(var/index in 1 to length(stack) - 1)
			var/lower = stack[index]
			var/upper = stack[index + 1]
			var/expected_up = lower + (SSmapping.level_trait(lower, ZTRAIT_UP) || 0)
			TEST_ASSERT_EQUAL(upper, expected_up, "Связка должна идти строго снизу вверх по ZTRAIT_UP (разрыв на [lower])")
			TEST_ASSERT_EQUAL(upper + (SSmapping.level_trait(upper, ZTRAIT_DOWN) || 0), lower, "Связь обязана быть обоюдной: у z=[upper] ZTRAIT_DOWN не смотрит на z=[lower]")

		for(var/index in 1 to length(stack))
			var/member = stack[index]
			var/expected_below = index > 1 ? stack[index - 1] : 0
			var/expected_above = index < length(stack) ? stack[index + 1] : 0
			TEST_ASSERT_EQUAL(SSmapping.z_level_below[member], expected_below, "z_level_below у z=[member] должен совпадать со связкой")
			TEST_ASSERT_EQUAL(SSmapping.z_level_above[member], expected_above, "z_level_above у z=[member] должен совпадать со связкой")

		var/plane_stacked = TRUE
		for(var/member in stack)
			if(SSmapping.level_trait(member, ZTRAIT_NO_PLANE_STACK))
				plane_stacked = FALSE
				break
		TEST_ASSERT_EQUAL(SSmapping.z_level_to_plane_offset[stack[length(stack)]], 0, "У верхнего уровня связки смещение плоскости должно быть нулевым")
		TEST_ASSERT_EQUAL(SSmapping.z_level_to_lowest_plane_offset[z], plane_stacked ? (length(stack) - 1) : 0, "Наибольшее смещение связки должно равняться числу уровней под верхушкой")
		if(!plane_stacked)
			for(var/member in stack)
				TEST_ASSERT_EQUAL(SSmapping.z_level_to_plane_offset[member], 0, "Связка с ZTRAIT_NO_PLANE_STACK не должна получать смещений плоскостей")
		TEST_ASSERT_EQUAL(SSmapping.get_connected_levels(z), stack, "get_connected_levels() должен отдавать тот же кэш")

	var/deepest = 0
	for(var/z in 1 to level_count)
		deepest = max(deepest, SSmapping.z_level_to_lowest_plane_offset[z])
	TEST_ASSERT_EQUAL(SSmapping.max_plane_offset, deepest, "max_plane_offset должен равняться глубине самой глубокой связки")
	TEST_ASSERT(SSmapping.max_plane_offset <= MAX_EXPECTED_Z_DEPTH, "Стопка глубже MAX_EXPECTED_Z_DEPTH: настройки игрока не покроют всю глубину")
	TEST_ASSERT(SSmapping.max_plane_offset <= MAX_SUPPORTED_Z_DEPTH, "Стопка глубже MAX_SUPPORTED_Z_DEPTH: слой релея уйдёт в минус и порядок этажей рассыпется")

	for(var/z in 1 to level_count)
		var/down_offset = SSmapping.level_trait(z, ZTRAIT_DOWN)
		if(!isnum(down_offset) || !down_offset)
			continue
		var/claimed_below = z + down_offset
		if(claimed_below < 1 || claimed_below > level_count)
			continue // Трейт указывает в никуда - ловится проверкой симметрии выше.
		TEST_ASSERT(SSmapping.z_level_below[z], "У z=[z] объявлен ZTRAIT_DOWN на существующий z=[claimed_below], но связка соседа снизу не знает")

	TEST_ASSERT_NOTNULL(SSmapping.plane_offset_to_true, "Справочник смещённых плоскостей не построен")
	TEST_ASSERT_EQUAL(PLANE_TO_TRUE(GAME_PLANE), GAME_PLANE, "Нулевое смещение обязано переводиться само в себя")
	var/list/game_offsets = TRUE_PLANE_TO_OFFSETS(GAME_PLANE)
	TEST_ASSERT_EQUAL(length(game_offsets), SSmapping.max_plane_offset + 1, "У игровой плоскости должно быть по одному варианту на каждый этаж стопки")
	for(var/offset_plane in game_offsets)
		TEST_ASSERT_EQUAL(PLANE_TO_TRUE(offset_plane), GAME_PLANE, "Смещённая игровая плоскость должна переводиться обратно в игровую")

/// Показ и снятие показа нижнего турфа не выбивают световой объект из vis_contents дыры.
/datum/unit_test/multiz_transparency_keeps_lighting_object

/datum/unit_test/multiz_transparency_keeps_lighting_object/Run()
	var/turf/hole = run_loc_floor_bottom_left
	var/turf/shown_below = run_loc_floor_top_right

	TEST_ASSERT_NOTNULL(hole.lighting_object, "Тесту нужен турф со световым объектом")
	TEST_ASSERT(hole.lighting_object in hole.vis_contents, "Наш световой объект живёт в vis_contents своего турфа — на этом держится весь тест")

	var/datum/element/turf_z_transparency/transparency = SSdcs.GetElement(list(/datum/element/turf_z_transparency, FALSE))
	TEST_ASSERT_NOTNULL(transparency, "Не удалось получить элемент прозрачности")

	transparency.show_turf_below(hole, shown_below)
	TEST_ASSERT(shown_below in hole.vis_contents, "Показанный снизу турф должен попасть в vis_contents")
	TEST_ASSERT(hole.lighting_object in hole.vis_contents, "Показ нижнего уровня не должен выбивать световой объект")

	transparency.clear_shown_turfs(hole)
	TEST_ASSERT(!(shown_below in hole.vis_contents), "Снятие показа должно убирать показанный турф")
	TEST_ASSERT(hole.lighting_object in hole.vis_contents, "Снятие показа не должно выбивать световой объект — раньше тут стоял vis_contents.len = 0")

/// Держатели соседей под дырой переиспользуются и живут по счётчику заказчиков.
/datum/unit_test/multiz_z_pillar_bookkeeping

/datum/unit_test/multiz_z_pillar_bookkeeping/Run()
	var/turf/shown = run_loc_floor_top_right
	var/turf/host = locate(shown.x - 1, shown.y, shown.z)
	var/turf/first_hole = run_loc_floor_bottom_left
	var/turf/second_hole = locate(first_hole.x + 1, first_hole.y, first_hole.z)
	TEST_ASSERT_NOTNULL(host, "Тесту нужен турф-носитель")
	TEST_ASSERT_NOTNULL(second_hole, "Тесту нужны два разных турфа-заказчика")

	request_z_pillar(shown, first_hole, host)
	var/obj/effect/abstract/z_holder/holder = GLOB.z_pillar_holders[shown]
	TEST_ASSERT_NOTNULL(holder, "Держатель обязан появиться на первый же заказ")
	TEST_ASSERT(shown in holder.vis_contents, "Показываемый турф обязан лежать в vis_contents держателя")
	TEST_ASSERT(!(shown in first_hole.vis_contents), "Сосед не должен попадать в vis_contents самой дыры — он нарисовался бы в её координатах")

	TEST_ASSERT_EQUAL(holder.loc, host, "Держатель обязан стоять на носителе, а не на дыре")

	request_z_pillar(shown, second_hole, host)
	TEST_ASSERT_EQUAL(GLOB.z_pillar_holders[shown], holder, "Второй заказчик должен переиспользовать тот же держатель, а не заводить второй")

	release_z_pillar(shown, first_hole)
	TEST_ASSERT_EQUAL(GLOB.z_pillar_holders[shown], holder, "Пока остаётся хоть один заказчик, держатель обязан жить")

	release_z_pillar(shown, second_hole)
	TEST_ASSERT_NULL(GLOB.z_pillar_holders[shown], "С последним заказчиком держатель должен уйти")
	TEST_ASSERT_NULL(GLOB.z_pillar_sources[shown], "Реестр заказчиков не должен копить пустые записи")

/// Прыжок на дыру: приземлившийся падает сам, а не на следующем шаге.
/datum/unit_test/multiz_jump_landing_falls

/datum/unit_test/multiz_jump_landing_falls/proc/turf_is_bare(turf/spot)
	if(spot.density)
		return FALSE
	for(var/atom/movable/thing as anything in spot.contents)
		if(!istype(thing, /atom/movable/lighting_object))
			return FALSE
	return TRUE

/// Пол связки с пустым полом под ним: дыру для теста открываем на живой карте, резервация уровня снизу не имеет.
/datum/unit_test/multiz_jump_landing_falls/proc/find_floor_over_floor()
	for(var/z in 1 to world.maxz)
		if(z > length(SSmapping.z_level_to_lowest_plane_offset) || !GET_LOWEST_STACK_OFFSET(z))
			continue
		for(var/turf/open/floor/candidate in block(locate(1, 1, z), locate(world.maxx, world.maxy, z)))
			if(!turf_is_bare(candidate) || !candidate.has_gravity(candidate))
				continue
			var/turf/open/floor/under = GET_TURF_BELOW(candidate)
			if(!istype(under) || !turf_is_bare(under))
				continue
			return candidate
	return null

/datum/unit_test/multiz_jump_landing_falls/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: падать некуда.

	var/turf/open/floor/spot = find_floor_over_floor()
	TEST_ASSERT_NOTNULL(spot, "В связке не нашлось пола с пустым полом под ним")
	var/original_type = spot.type
	var/turf/below = GET_TURF_BELOW(spot)
	var/turf/hole = spot.ChangeTurf(/turf/open/openspace)
	TEST_ASSERT(istype(hole, /turf/open/openspace), "Не удалось открыть дыру для теста")

	var/mob/living/carbon/human/jumper = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/component/jump/leap = jumper.GetComponent(/datum/component/jump) || jumper.AddComponent(/datum/component/jump)
	leap.do_jump(jumper)
	TEST_ASSERT(HAS_TRAIT(jumper, TRAIT_JUMPING), "Прыжок должен был начаться")

	jumper.forceMove(hole)
	TEST_ASSERT_EQUAL(jumper.loc, hole, "В полёте прыжка над дырой не падают")

	sleep(leap.jump_duration + 2)
	TEST_ASSERT(!HAS_TRAIT(jumper, TRAIT_JUMPING), "Прыжок должен был закончиться")
	TEST_ASSERT_EQUAL(jumper.z, below.z, "Приземлившийся на дыру обязан упасть, не дожидаясь следующего шага")

	hole.ChangeTurf(original_type)

/// Носитель, побывавший дырой, после закрытия снова держит турф для соседних дыр.
/datum/unit_test/multiz_z_pillar_restored_after_hole_closes

/datum/unit_test/multiz_z_pillar_restored_after_hole_closes/Run()
	var/turf/shown = run_loc_floor_top_right
	var/turf/host = run_loc_floor_bottom_left
	var/turf/neighbour = locate(host.x + 1, host.y, host.z)
	TEST_ASSERT_NOTNULL(neighbour, "Тесту нужен сосед носителя")

	var/datum/element/turf_z_transparency/transparency = SSdcs.GetElement(list(/datum/element/turf_z_transparency, FALSE))
	TEST_ASSERT_NOTNULL(transparency, "Не удалось получить элемент прозрачности")

	request_z_pillar(shown, neighbour, host)
	TEST_ASSERT_NOTNULL(GLOB.z_pillar_holders[shown], "Держатель обязан появиться на заказ соседа")

	transparency.show_turf_below(host, shown)
	TEST_ASSERT_NULL(GLOB.z_pillar_holders[shown], "Носитель, ставший дырой, не должен показывать турф ещё и держателем")

	transparency.clear_shown_turfs(host)
	ADD_TRAIT(neighbour, TURF_Z_TRANSPARENT_TRAIT, TURF_TRAIT)
	restore_z_pillars_over(host, shown)
	var/obj/effect/abstract/z_holder/holder = GLOB.z_pillar_holders[shown]
	TEST_ASSERT_NOTNULL(holder, "После закрытия носителя держатель для соседней дыры обязан вернуться")
	TEST_ASSERT_EQUAL(holder.loc, host, "Восстановленный держатель обязан стоять на носителе")
	TEST_ASSERT(neighbour in GLOB.z_pillar_sources[shown], "Заказчиком восстановленного держателя должна быть соседняя дыра")

	REMOVE_TRAIT(neighbour, TURF_Z_TRANSPARENT_TRAIT, TURF_TRAIT)
	release_z_pillar(shown, neighbour)
	TEST_ASSERT_NULL(GLOB.z_pillar_holders[shown], "С последним заказчиком держатель должен уйти")

/// Без этажа снизу космос не получает прозрачности и не откатывается в пол.
/datum/unit_test/multiz_transparent_space_needs_level_below

/datum/unit_test/multiz_transparent_space_needs_level_below/Run()
	var/turf/open/space/vacuum = run_loc_floor_bottom_left.ChangeTurf(/turf/open/space/basic)
	TEST_ASSERT(istype(vacuum), "Не удалось подготовить космический турф для теста")

	TEST_ASSERT(!vacuum.make_space_transparent(), "Без этажа снизу прозрачность вставать не должна")
	TEST_ASSERT(!HAS_TRAIT(vacuum, TURF_Z_TRANSPARENT_TRAIT), "Турф без этажа снизу не должен нести трейт прозрачности")
	TEST_ASSERT(isspaceturf(vacuum), "Космос не должен превращаться в пол")

/// shows_level_below() отвечает по трейту уровня, ещё до инициализации турфа.
/datum/unit_test/multiz_transparent_space_trait_gate

/datum/unit_test/multiz_transparent_space_trait_gate/Run()
	var/turf/open/space/vacuum = run_loc_floor_bottom_left.ChangeTurf(/turf/open/space/basic)
	TEST_ASSERT(istype(vacuum), "Не удалось подготовить космический турф для теста")

	var/datum/space_level/level = SSmapping.z_list[vacuum.z]
	TEST_ASSERT_NOTNULL(level, "Тесту нужен живой z-уровень")

	TEST_ASSERT(!vacuum.shows_level_below(), "Без трейта уровня космос ничего показывать не обещает")

	level.traits[ZTRAIT_TRANSPARENT_SPACE] = TRUE
	TEST_ASSERT(vacuum.shows_level_below(), "С трейтом уровня космос обязан считаться будущей дырой ещё до своей инициализации")
	TEST_ASSERT(!vacuum.make_space_transparent(), "Трейт без этажа снизу прозрачности давать не должен")
	TEST_ASSERT(!HAS_TRAIT(vacuum, TURF_Z_TRANSPARENT_TRAIT), "Несостоявшаяся прозрачность не должна оставлять после себя трейт")

	level.traits -= ZTRAIT_TRANSPARENT_SPACE
	TEST_ASSERT(!vacuum.shows_level_below(), "Снятый трейт обязан забрать обещание с собой")

/// Подложка базового турфа ставится один раз и уходит вместе с элементом.
/datum/unit_test/multiz_transparent_space_bottom_underlay

/datum/unit_test/multiz_transparent_space_bottom_underlay/Run()
	var/turf/open/space/vacuum = run_loc_floor_top_right.ChangeTurf(/turf/open/space/basic)
	TEST_ASSERT(istype(vacuum), "Не удалось подготовить космический турф для теста")

	var/before = length(vacuum.underlays)
	vacuum.AddElement(/datum/element/turf_z_transparency, TRUE)
	TEST_ASSERT(HAS_TRAIT(vacuum, TURF_Z_TRANSPARENT_TRAIT), "Элемент обязан пометить турф трейтом прозрачности")
	TEST_ASSERT_EQUAL(length(vacuum.underlays), before + 1, "Без этажа снизу элемент обязан подложить базовый турф")

	SEND_SIGNAL(vacuum, COMSIG_TURF_MULTIZ_NEW, null, DOWN)
	TEST_ASSERT_EQUAL(length(vacuum.underlays), before + 1, "Повторный пересчёт не должен задваивать подложку")

	vacuum.RemoveElement(/datum/element/turf_z_transparency, TRUE)
	TEST_ASSERT(!HAS_TRAIT(vacuum, TURF_Z_TRANSPARENT_TRAIT), "Снятый элемент обязан убрать трейт прозрачности")
	TEST_ASSERT_EQUAL(length(vacuum.underlays), before, "Снятый элемент обязан унести и свою подложку")
