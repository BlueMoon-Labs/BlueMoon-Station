/// Проводка плоскостного куба: имена render_target, номера плоскостей, цепочка реле.

/// Свой ключ стопки, чтобы не столкнуться с боевыми группами худа.
#define RENDER_GRAPH_TEST_KEY "unit-test-render-graph"

/// Собранная стопка сходится по аудиту, и у каждого этажа есть своя мировая плита.
/datum/unit_test/multiz_render_graph

/datum/unit_test/multiz_render_graph/Run()
	var/datum/plane_master_group/group = new /datum/plane_master_group/main(RENDER_GRAPH_TEST_KEY)
	group.ensure_depth(SSmapping.max_plane_offset)

	var/list/problems = group.audit_render_graph(0)
	TEST_ASSERT(!length(problems), "Граф рендера не сходится сразу после сборки:\n[problems.Join("\n")]")

	var/expected_offsets = SSmapping.max_plane_offset + 1
	var/list/game_world_plates = list()
	for(var/plane_key in group.plane_masters)
		var/atom/movable/screen/plane_master/master = group.plane_masters[plane_key]
		if(istype(master, /atom/movable/screen/plane_master/rendering_plate/game_world))
			game_world_plates += master
	TEST_ASSERT_EQUAL(length(game_world_plates), expected_offsets, "Мировая плита должна быть у каждого этажа стопки")

	qdel(group)

/// Два мастера на одном номере плоскости - до клиента доедет только один.
/datum/unit_test/plane_master_numbers_are_unique

/datum/unit_test/plane_master_numbers_are_unique/Run()
	var/list/claimed_by = list()
	for(var/atom/movable/screen/plane_master/master_type as anything in subtypesof(/atom/movable/screen/plane_master))
		//Абстрактная плита своей плоскости не имеет.
		if(master_type == /atom/movable/screen/plane_master/rendering_plate)
			continue
		var/plane_key = "[initial(master_type.plane)]"
		var/existing = claimed_by[plane_key]
		if(existing)
			TEST_FAIL("Плоскость [plane_key] заявлена дважды: [existing] и [master_type]. До клиента доедет только один из них.")
			continue
		claimed_by[plane_key] = "[master_type]"

/// Мастер-плита либо рисуется игроку, либо уезжает наверх, но не одновременно.
/datum/unit_test/multiz_render_graph_follows_eye

/datum/unit_test/multiz_render_graph_follows_eye/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: переключать нечего, куб не собирается.

	var/datum/plane_master_group/group = new /datum/plane_master_group/main(RENDER_GRAPH_TEST_KEY)
	group.ensure_depth(SSmapping.max_plane_offset)

	for(var/viewer_offset in 0 to SSmapping.max_plane_offset)
		//Глаз двигаем руками: build_planes_offset() решает по турфу и настройкам живого игрока.
		for(var/plane_key in group.plane_masters)
			var/atom/movable/screen/plane_master/master = group.plane_masters[plane_key]
			master.sync_to_viewer(viewer_offset)

		var/atom/movable/screen/plane_master/eye_plate = group.plane_masters["[GET_NEW_PLANE(RENDER_PLANE_MASTER, viewer_offset)]"]
		TEST_ASSERT_NOTNULL(eye_plate, "У этажа [viewer_offset] нет мастер-плиты")
		TEST_ASSERT_NOTNULL(eye_plate.get_relay_to(RENDER_PLANE_SCREEN), "Плита этажа глаза ([viewer_offset]) обязана сдавать картинку на экран")

		for(var/lower_offset in viewer_offset + 1 to SSmapping.max_plane_offset)
			var/atom/movable/screen/plane_master/lower_plate = group.plane_masters["[GET_NEW_PLANE(RENDER_PLANE_MASTER, lower_offset)]"]
			TEST_ASSERT_NOTNULL(lower_plate, "У этажа [lower_offset] нет мастер-плиты")
			TEST_ASSERT_NULL(lower_plate.get_relay_to(RENDER_PLANE_SCREEN), "Плита этажа [lower_offset] не должна рисоваться игроку: глаз на этаже [viewer_offset]")
			TEST_ASSERT_NOTNULL(lower_plate.get_relay_to(GET_NEW_PLANE(RENDER_PLANE_TRANSPARENT, lower_offset - 1)), "Плита этажа [lower_offset] обязана уезжать в дыру этажа выше")

		var/list/problems = group.audit_render_graph(viewer_offset)
		TEST_ASSERT(!length(problems), "Граф рендера не сходится, когда глаз на этаже [viewer_offset]:\n[problems.Join("\n")]")

	qdel(group)

/// Маска FoV одна на всю стопку: этажи ниже глаза читают её с нулевого этажа.
/datum/unit_test/multiz_fov_mask_shared_across_floors

/datum/unit_test/multiz_fov_mask_shared_across_floors/Run()
	TEST_ASSERT(SSmapping.render_offset_blacklist[FIELD_OF_VISION_RENDER_TARGET], "Таргет маски FoV не должен получать суффикс этажа")
	TEST_ASSERT(SSmapping.render_offset_blacklist[FIELD_OF_VISION_BLOCKER_RENDER_TARGET], "Таргет блокера FoV не должен получать суффикс этажа")
	TEST_ASSERT_EQUAL(GET_NEW_PLANE(FIELD_OF_VISION_PLANE, 1), FIELD_OF_VISION_PLANE, "Плоскость маски FoV не должна смещаться по этажам")
	TEST_ASSERT_EQUAL(GET_NEW_PLANE(FIELD_OF_VISION_BLOCKER_PLANE, 1), FIELD_OF_VISION_BLOCKER_PLANE, "Плоскость блокера FoV не должна смещаться по этажам")
	TEST_ASSERT_EQUAL(GET_NEW_PLANE(FIELD_OF_VISION_VISUAL_PLANE, 1), FIELD_OF_VISION_VISUAL_PLANE, "Плоскость тени FoV не должна смещаться по этажам")

	var/datum/plane_master_group/group = new /datum/plane_master_group/main(RENDER_GRAPH_TEST_KEY)
	group.ensure_depth(SSmapping.max_plane_offset)

	var/mask_masters = 0
	for(var/plane_key in group.plane_masters)
		if(istype(group.plane_masters[plane_key], /atom/movable/screen/plane_master/field_of_vision))
			mask_masters++
	TEST_ASSERT_EQUAL(mask_masters, 1, "Мастер маски FoV должен быть один на стопку")

	var/shared_target = OFFSET_RENDER_TARGET(FIELD_OF_VISION_RENDER_TARGET, 0)
	for(var/floor in 0 to SSmapping.max_plane_offset)
		var/atom/movable/screen/plane_master/game = group.plane_masters["[GET_NEW_PLANE(GAME_PLANE, floor)]"]
		TEST_ASSERT_NOTNULL(game, "У этажа [floor] нет игрового мастера")
		var/list/cone = game.filter_data?["vision_cone"]
		TEST_ASSERT_NOTNULL(cone, "Игровой мастер этажа [floor] обязан нести фильтр конуса")
		TEST_ASSERT_EQUAL(cone["render_source"], shared_target, "Игровой мастер этажа [floor] обязан читать маску с нулевого этажа")

	var/atom/movable/screen/plane_master/visual = group.plane_masters["[FIELD_OF_VISION_VISUAL_PLANE]"]
	TEST_ASSERT_NOTNULL(visual, "В стопке нет мастера тени конуса")
	for(var/viewer_offset in 0 to SSmapping.max_plane_offset)
		for(var/plane_key in group.plane_masters)
			var/atom/movable/screen/plane_master/master = group.plane_masters[plane_key]
			master.sync_to_viewer(viewer_offset)
		TEST_ASSERT_EQUAL(length(visual.relays), 1, "Тень конуса должна сдаваться ровно на одну плиту (глаз на этаже [viewer_offset])")
		TEST_ASSERT_NOTNULL(visual.get_relay_to(GET_NEW_PLANE(RENDER_PLANE_GAME_WORLD, viewer_offset)), "Тень конуса обязана лежать на плите этажа глаза ([viewer_offset])")
		var/list/problems = group.audit_render_graph(viewer_offset)
		TEST_ASSERT(!length(problems), "Граф рендера не сходится с тенью конуса на этаже [viewer_offset]:\n[problems.Join("\n")]")

	qdel(group)

/// Достроенные позже этажи получают действующую альфу света владельца худа.
/datum/unit_test/multiz_late_floors_inherit_lighting_alpha

/datum/unit_test/multiz_late_floors_inherit_lighting_alpha/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: достраивать нечего.

	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/hud = new viewer.hud_type(viewer)
	viewer.set_hud_used(hud)
	var/datum/plane_master_group/group = hud.master_groups[PLANE_GROUP_MAIN]
	TEST_ASSERT_NOTNULL(group, "У худа нет основной стопки")
	TEST_ASSERT_EQUAL(group.built_depth, 0, "На уровне без связки стопка должна строиться одним этажом")

	viewer.lighting_alpha = LIGHTING_PLANE_ALPHA_INVISIBLE
	viewer.sync_lighting_plane_alpha()
	group.ensure_depth(1)

	var/atom/movable/screen/plane_master/lower = group.plane_masters["[GET_NEW_PLANE(LIGHTING_PLANE, 1)]"]
	TEST_ASSERT_NOTNULL(lower, "Этаж 1 должен был достроиться")
	TEST_ASSERT_EQUAL(lower.alpha, LIGHTING_PLANE_ALPHA_INVISIBLE, "Достроенный этаж обязан унаследовать ночное зрение владельца")

	qdel(hud)

/// Ни один атом связки не должен сидеть на плоскости чужого этажа.
/datum/unit_test/multiz_level_atoms_on_own_floor

/datum/unit_test/multiz_level_atoms_on_own_floor/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: смещений нет.

	for(var/z in 1 to world.maxz)
		if(z > length(SSmapping.z_level_to_lowest_plane_offset) || !GET_LOWEST_STACK_OFFSET(z))
			continue
		var/list/samples = list()
		var/list/by_type = audit_z_level_planes(z, samples)
		if(!length(by_type))
			continue
		var/list/report = list()
		for(var/type_key in by_type)
			report += "[type_key]: [by_type[type_key]]"
		TEST_FAIL("На z=[z] (смещение [GET_Z_PLANE_OFFSET(z)]) атомы на чужом этаже:\n[report.Join("\n")]\nПримеры:\n[samples.Join("\n")]")

/// Предмет, который переезжает на этаж ещё до того, как /atom/movable/Initialize() расставит плоскости (как stationloving).
/obj/item/multiz_test_early_mover

/obj/item/multiz_test_early_mover/Initialize(mapload, turf/target)
	if(target)
		forceMove(target)
	return ..()

/// Смещение плоскости в Initialize() не должно складываться со смещением, которое уже дал переезд.
/datum/unit_test/multiz_initialize_offset_is_idempotent

/datum/unit_test/multiz_initialize_offset_is_idempotent/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: смещений нет.

	var/turf/lower = multiz_test_lower_turf()
	TEST_ASSERT_NOTNULL(lower, "В мире со стопкой не нашлось этажа со смещением")

	var/obj/item/multiz_test_early_mover/mover = allocate(/obj/item/multiz_test_early_mover, null, lower)
	TEST_ASSERT_EQUAL(mover.loc, lower, "Предмет должен был переехать на этаж до конца Initialize()")
	TEST_ASSERT_EQUAL(mover.plane, GET_NEW_PLANE(GAME_PLANE, GET_Z_PLANE_OFFSET(lower.z)), "Плоскость сместилась дважды: переездом и Initialize()")

/// Гост, созданный на нижнем этаже, встаёт на плоскости этого этажа: /mob/dead/Initialize() идёт мимо родителя.
/datum/unit_test/multiz_ghost_spawns_on_own_floor

/datum/unit_test/multiz_ghost_spawns_on_own_floor/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: смещений нет.

	var/turf/lower = multiz_test_lower_turf()
	TEST_ASSERT_NOTNULL(lower, "В мире со стопкой не нашлось этажа со смещением")

	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, lower)
	TEST_ASSERT_EQUAL(ghost.loc, lower, "Гост должен был появиться на нижнем этаже")
	TEST_ASSERT_EQUAL(ghost.plane, GET_NEW_PLANE(PLANE_TO_TRUE(initial(ghost.plane)), GET_Z_PLANE_OFFSET(lower.z)), "Гост на нижнем этаже обязан лежать на плоскости своего этажа, иначе его реле сняты вместе с этажом глаза")

#undef RENDER_GRAPH_TEST_KEY
