/// Камера консоли переходит на соседний этаж связки кнопками этажей и не уходит за z_lock консоли.
/datum/unit_test/multiz_camera_console_floors

/datum/unit_test/multiz_camera_console_floors/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/lower = locate(20, 20, levels[1])
	var/turf/upper = locate(20, 20, levels[2])
	var/obj/machinery/computer/camera_advanced/console = allocate(/obj/machinery/computer/camera_advanced, lower)
	TEST_ASSERT(locate(/datum/action/innate/camera_multiz_up) in console.actions, "У камерной консоли нет кнопки этажа выше")
	TEST_ASSERT(locate(/datum/action/innate/camera_multiz_down) in console.actions, "У камерной консоли нет кнопки этажа ниже")
	var/obj/machinery/computer/camera_advanced/shuttle_docker/docker_type = /obj/machinery/computer/camera_advanced/shuttle_docker
	TEST_ASSERT_NULL(initial(docker_type.move_up_action), "Навигационная консоль шаттла не должна уводить камеру на другой этаж")

	var/mob/living/carbon/human/operator = allocate(/mob/living/carbon/human, lower)
	console.CreateEye()
	var/mob/camera/aiEye/remote/eye = console.eyeobj
	eye.eye_user = operator
	operator.remote_control = eye
	eye.setLoc(lower)

	TEST_ASSERT(camera_change_floor(operator, UP), "Камера не поднялась на этаж выше")
	TEST_ASSERT_EQUAL(get_turf(eye), upper, "Камера поднялась не на клетку над собой")
	TEST_ASSERT(!camera_change_floor(operator, UP), "Камера поднялась выше верхнего этажа связки")
	TEST_ASSERT_EQUAL(get_turf(eye), upper, "Неудачный подъём сдвинул камеру")

	console.z_lock = list(levels[2])
	TEST_ASSERT(!camera_change_floor(operator, DOWN), "Камера ушла с уровня, на который заперта консоль")
	console.z_lock = list()
	TEST_ASSERT(camera_change_floor(operator, DOWN), "Камера не спустилась на этаж ниже")
	TEST_ASSERT_EQUAL(get_turf(eye), lower, "Камера спустилась не на клетку под собой")

	eye.eye_user = null
	operator.remote_control = null

/// Shift/Ctrl-клик по платформе лифта доходит до консоли ксенобио как клик по полу под ней.
/datum/unit_test/xenobio_click_through_lift_platform
	var/list/clicked_turfs = list()

/datum/unit_test/xenobio_click_through_lift_platform/Run()
	var/mob/living/carbon/human/operator = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/turf/platform_turf = get_step(run_loc_floor_bottom_left, NORTH)
	var/obj/structure/transport/linear/platform = allocate(/obj/structure/transport/linear, platform_turf)
	RegisterSignals(operator, list(COMSIG_XENO_TURF_CLICK_SHIFT, COMSIG_XENO_TURF_CLICK_CTRL), PROC_REF(on_turf_click))
	platform.ShiftClick(operator)
	platform.CtrlClick(operator)
	UnregisterSignal(operator, list(COMSIG_XENO_TURF_CLICK_SHIFT, COMSIG_XENO_TURF_CLICK_CTRL))
	TEST_ASSERT_EQUAL(length(clicked_turfs), 2, "Клики по платформе лифта не дошли до консоли ксенобио")
	for(var/turf/clicked as anything in clicked_turfs)
		TEST_ASSERT_EQUAL(clicked, platform_turf, "Клик по платформе ушёл не на пол под ней")

/datum/unit_test/xenobio_click_through_lift_platform/proc/on_turf_click(datum/source, turf/target)
	SIGNAL_HANDLER
	clicked_turfs += target
