/// A mob deleted while sitting in a sealed vehicle leaves the occupant list and the driver seat.
/datum/unit_test/sealed_vehicle_drops_deleted_occupant/Run()
	var/obj/vehicle/sealed/vectorcraft/auto/car = allocate(/obj/vehicle/sealed/vectorcraft/auto)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	car.mob_enter(rider)
	TEST_ASSERT(car.is_occupant(rider), "test premise: the rider must be inside the hovercraft")
	TEST_ASSERT_EQUAL(car.driver, rider, "test premise: the rider must drive the hovercraft")

	qdel(rider)

	TEST_ASSERT(!(rider in car.occupants), "A deleted mob must not stay in the vehicle occupants")
	TEST_ASSERT_NULL(car.driver, "A deleted mob must not stay in the driver seat")
	car.setDir(EAST)

/// A hovercraft without a driver stops its engine instead of reading the missing driver.
/datum/unit_test/vectorcraft_without_driver_stops/Run()
	var/obj/vehicle/sealed/vectorcraft/car = allocate(/obj/vehicle/sealed/vectorcraft)

	TEST_ASSERT(car.dead_check(), "A hovercraft without a driver must count as stopped")

/// A hovercraft that smashes an airlock does not make its riders bump the destroyed door.
/datum/unit_test/vectorcraft_smashed_door_not_bumped/Run()
	var/obj/vehicle/sealed/vectorcraft/car = allocate(/obj/vehicle/sealed/vectorcraft)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	car.mob_enter(rider)
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, get_step(run_loc_floor_bottom_left, EAST))
	door.obj_integrity = 1
	car.vector = list("x" = 100, "y" = 0)

	car.Bump(door)

	TEST_ASSERT(QDELETED(door), "test premise: the crash must destroy the airlock")
