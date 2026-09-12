/// Худ без клиента следит за своим мобом и переезжает на его этаж по сигналу, без ручного eye_z_changed().
/datum/unit_test/multiz_hud_eye_follows_owner

/datum/unit_test/multiz_hud_eye_follows_owner/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(owner.hud_used, "У моба без клиента не должно быть худа")
	var/datum/hud/human/hud = new(owner)
	owner.set_hud_used(hud)
	TEST_ASSERT_EQUAL(hud.tracked_eye, owner, "Худ без клиента обязан следить за своим мобом")
	TEST_ASSERT_EQUAL(hud.current_plane_offset, 0, "Резервация лежит на верхнем этаже, смещение должно быть нулевым")

	var/lower_z = 0
	for(var/z_index in 1 to length(SSmapping.z_level_to_plane_offset))
		if(SSmapping.z_level_to_plane_offset[z_index])
			lower_z = z_index
			break
	if(!lower_z)
		log_test("\tНа карте нет стопки этажей, переезд глаза не проверяется")
		return
	var/turf/lower_floor = locate(1, 1, lower_z)
	TEST_ASSERT_NOTNULL(lower_floor, "У нижнего этажа [lower_z] нет турфа в углу карты")

	owner.abstract_move(lower_floor)
	TEST_ASSERT_EQUAL(hud.tracked_eye, owner, "Переезд моба не должен менять отслеживаемый глаз")
	TEST_ASSERT_EQUAL(hud.current_plane_offset, GET_Z_PLANE_OFFSET(lower_z), "Худ не переехал на этаж моба после abstract_move()")
	TEST_ASSERT_EQUAL(hud.current_stack_depth, GET_LOWEST_STACK_OFFSET(lower_z), "Худ не подхватил глубину связки нового этажа")

	owner.abstract_move(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(hud.current_plane_offset, 0, "Худ не вернулся на верхний этаж после возврата моба")

/// Удаление чужого глаза откатывает худ к своему мобу; пересинхронизация чинит подписку, обойдённую мимо set_eye().
/datum/unit_test/multiz_hud_eye_qdel_fallback

/datum/unit_test/multiz_hud_eye_qdel_fallback/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/hud = new(owner)
	owner.set_hud_used(hud)
	var/mob/camera/eye = allocate(/mob/camera, run_loc_floor_top_right)

	hud.track_eye(eye)
	TEST_ASSERT_EQUAL(hud.tracked_eye, eye, "track_eye() не переключил отслеживаемый глаз")
	hud.eye_z_changed(force = TRUE)
	TEST_ASSERT_EQUAL(hud.tracked_eye, owner, "Пересинхронизация не вернула худ к глазу клиента или мобу")

	hud.track_eye(eye)
	allocated -= eye
	qdel(eye)
	TEST_ASSERT_EQUAL(hud.tracked_eye, owner, "После удаления глаза худ не откатился к своему мобу")

/// abstract_move() на другой z шлёт COMSIG_MOVABLE_Z_CHANGED так же, как forceMove().
/datum/unit_test/multiz_abstract_move_z_signal
	var/list/seen_transit

/datum/unit_test/multiz_abstract_move_z_signal/Run()
	var/mob/camera/mover = allocate(/mob/camera, run_loc_floor_bottom_left)
	var/turf/other_floor
	for(var/z_index in 1 to world.maxz)
		if(z_index == run_loc_floor_bottom_left.z)
			continue
		other_floor = locate(1, 1, z_index)
		if(other_floor)
			break
	TEST_ASSERT_NOTNULL(other_floor, "Не нашлось турфа на другом z-уровне")

	RegisterSignal(mover, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_z_changed))
	mover.abstract_move(other_floor)
	TEST_ASSERT_NOTNULL(seen_transit, "abstract_move() на другой z не отправил COMSIG_MOVABLE_Z_CHANGED")
	TEST_ASSERT_EQUAL(seen_transit[1], run_loc_floor_bottom_left.z, "В сигнале не тот старый z")
	TEST_ASSERT_EQUAL(seen_transit[2], other_floor.z, "В сигнале не тот новый z")

	seen_transit = null
	mover.abstract_move(locate(2, 1, other_floor.z))
	TEST_ASSERT_NULL(seen_transit, "Переезд в пределах одного z не должен слать COMSIG_MOVABLE_Z_CHANGED")

	mover.abstract_move(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(seen_transit[2], run_loc_floor_bottom_left.z, "Возврат в резервацию не отправил сигнал с её z")
	UnregisterSignal(mover, COMSIG_MOVABLE_Z_CHANGED)

/datum/unit_test/multiz_abstract_move_z_signal/proc/on_z_changed(datum/source, old_z, new_z)
	SIGNAL_HANDLER
	seen_transit = list(old_z, new_z)
