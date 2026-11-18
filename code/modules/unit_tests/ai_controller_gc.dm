/// Контроллер ИИ на предмете уходит в qdel вместе с ним: иначе живой mossglob держал /datum/ai_controller/haunted, вар pawn.
/datum/unit_test/haunted_item_releases_controller

/datum/unit_test/haunted_item_releases_controller/proc/spawn_and_qdel()
	var/obj/item/fish/mossglob/glob = allocate(/obj/item/fish/mossglob, run_loc_floor_bottom_left)
	var/datum/ai_controller/controller = glob.ai_controller
	allocated -= glob
	qdel(glob)
	return controller

/datum/unit_test/haunted_item_releases_controller/Run()
	var/datum/ai_controller/controller = spawn_and_qdel()
	TEST_ASSERT(istype(controller, /datum/ai_controller/haunted), "Живой mossglob должен парить под контроллером haunted")
	TEST_ASSERT(QDELETED(controller), "Контроллер пережил удалённый предмет")
	TEST_ASSERT_NULL(controller.pawn, "Контроллер держит удалённый предмет в pawn")
	for(var/list/zlevel_controllers as anything in GLOB.ai_controllers_by_zlevel)
		TEST_ASSERT(!(controller in zlevel_controllers), "Контроллер удалённого предмета остался в GLOB.ai_controllers_by_zlevel")

/// Бессмертный синглтон движения не держит прежнюю цель, удалённую до перезапуска лупа.
/datum/unit_test/ai_movement_record_releases_replaced_target

/datum/unit_test/ai_movement_record_releases_replaced_target/proc/chase_switch_and_delete(datum/ai_controller/controller, mob/living/carbon/monkey/new_prey)
	var/mob/living/carbon/monkey/old_prey = new(get_step(get_step(run_loc_floor_bottom_left, NORTH), NORTH))
	controller.set_movement_target(type, old_prey)
	controller.ai_movement.start_moving_towards(controller, old_prey, 1)
	TEST_ASSERT(controller.ai_movement.moving_controllers[controller], "Предпосылка: начатая погоня записана в синглтоне движения")
	controller.set_movement_target(type, new_prey)
	qdel(old_prey)

/datum/unit_test/ai_movement_record_releases_replaced_target/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/carbon/monkey/new_prey = allocate(/mob/living/carbon/monkey, get_step(get_step(run_loc_floor_bottom_left, EAST), EAST))
	var/datum/ai_controller/controller = hunter.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Предпосылка: у hostile должен быть контроллер")
	controller.set_ai_status(AI_STATUS_OFF)

	chase_switch_and_delete(controller, new_prey)
	var/recorded = controller.ai_movement.moving_controllers[controller]
	TEST_ASSERT(!isatom(recorded), "Синглтон движения держит удалённую прежнюю цель: [recorded]")
	recorded = null
	TEST_ASSERT(controller.current_movement_target == new_prey, "Удаление прежней цели не должно сбивать новую")

	controller.ai_movement.start_moving_towards(controller, new_prey, 1)
	TEST_ASSERT(controller.ai_movement.is_moving_towards(controller, new_prey), "Погоня за новой целью должна записываться как обычно")
	controller.ai_movement.stop_moving_towards(controller)
	TEST_ASSERT(!controller.ai_movement.moving_controllers[controller], "Остановка должна снимать запись")

	var/turf/hold_tile = get_step(run_loc_floor_bottom_left, NORTH)
	var/tile_had_weakref = !isnull(hold_tile.weak_reference)
	controller.ai_movement.start_moving_towards(controller, hold_tile, 1)
	TEST_ASSERT(controller.ai_movement.is_moving_towards(controller, hold_tile), "Погоня к турфу должна записываться как обычно")
	TEST_ASSERT(tile_had_weakref || isnull(hold_tile.weak_reference), "Погоня к турфу не должна вешать на турф weakref до конца раунда")
	controller.ai_movement.stop_moving_towards(controller)
