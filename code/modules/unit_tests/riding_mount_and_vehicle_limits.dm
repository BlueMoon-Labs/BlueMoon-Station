/// Одна мышь персонажа не везёт, стая из пяти везёт; тяжёлого стая не держит, сверхтяжёлый её давит.
/datum/unit_test/mouse_swarm_carries_rider

/datum/unit_test/mouse_swarm_carries_rider/proc/add_mouse()
	var/mob/living/simple_animal/mouse/mouse = allocate(/mob/living/simple_animal/mouse)
	// мышь не убредает из радиуса сбора стаи, пока тест её ждёт
	mouse.stop_automated_movement = TRUE
	return mouse

/datum/unit_test/mouse_swarm_carries_rider/Run()
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/mouse/host = add_mouse()
	var/list/mice = list(host)

	host.MouseDrop_T(rider, rider)
	TEST_ASSERT_NULL(rider.buckled, "Одна мышь увезла персонажа")

	for(var/i in 1 to 4)
		mice += add_mouse()
	host.MouseDrop_T(rider, rider)
	TEST_ASSERT_EQUAL(rider.buckled, host, "Стая из пяти мышей не подняла персонажа")
	TEST_ASSERT_NOTNULL(host.GetComponent(/datum/component/mouse_swarm_mount), "Остальные мыши не встали под седока")

	host.unbuckle_mob(rider, TRUE)
	TEST_ASSERT_NULL(host.GetComponent(/datum/component/mouse_swarm_mount), "Стая не распалась, когда седок слез")

	rider.mob_weight = MOB_WEIGHT_HEAVY
	host.MouseDrop_T(rider, rider)
	TEST_ASSERT_NULL(rider.buckled, "Тяжёлый персонаж оседлал стаю мышей")
	for(var/mob/living/simple_animal/mouse/mouse as anything in mice)
		TEST_ASSERT_EQUAL(mouse.stat, CONSCIOUS, "Мышь, разбежавшаяся из-под тяжёлого, пострадала")
		// разбежавшиеся мыши снова у ног седока
		mouse.forceMove(get_turf(rider))

	rider.mob_weight = MOB_WEIGHT_HEAVY_SUPER
	host.MouseDrop_T(rider, rider)
	TEST_ASSERT_NULL(rider.buckled, "Сверхтяжёлый персонаж оседлал стаю мышей")
	for(var/mob/living/simple_animal/mouse/mouse as anything in mice)
		TEST_ASSERT(QDELETED(mouse), "Сверхтяжёлый не раздавил мышь стаи")

/// Седок на звере сидит, а не лежит: лёжа он ехал бы на полной скорости мимо пуль.
/datum/unit_test/mount_keeps_rider_upright

/datum/unit_test/mount_keeps_rider_upright/Run()
	var/mob/living/simple_animal/pet/dog/corgi/mount = allocate(/mob/living/simple_animal/pet/dog/corgi)
	mount.can_buckle = TRUE
	mount.tame = TRUE
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	rider.update_size(0.3)
	rider.set_resting(TRUE, TRUE)
	TEST_ASSERT(rider.lying, "test premise: отдыхающий персонаж должен лежать")

	mount.MouseDrop_T(rider, rider)
	TEST_ASSERT_EQUAL(rider.buckled, mount, "test premise: седок должен оседлать корги")
	TEST_ASSERT(!rider.lying, "Седок лежит на спине зверя")
	TEST_ASSERT(rider.density, "Седок на звере не плотный и пропускает пули")

/// Труп скакуна, который не удаляется, сбрасывает седока, а не служит ему щитом.
/datum/unit_test/dead_mount_drops_rider

/datum/unit_test/dead_mount_drops_rider/Run()
	var/mob/living/simple_animal/pet/dog/corgi/mount = allocate(/mob/living/simple_animal/pet/dog/corgi)
	mount.can_buckle = TRUE
	mount.tame = TRUE
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	rider.update_size(0.3)

	mount.MouseDrop_T(rider, rider)
	TEST_ASSERT_EQUAL(rider.buckled, mount, "test premise: седок должен оседлать корги")
	mount.adjustBruteLoss(mount.maxHealth * 2)
	TEST_ASSERT_EQUAL(mount.stat, DEAD, "test premise: корги должен умереть")
	TEST_ASSERT(!QDELETED(mount), "test premise: труп корги должен остаться")
	TEST_ASSERT_NULL(rider.buckled, "Седок остался на трупе скакуна")

/// Без рук транспорт не водят: ни безрукий персонаж, ни мышь.
/datum/unit_test/vehicle_needs_driver_arms

/datum/unit_test/vehicle_needs_driver_arms/proc/try_drive(obj/vehicle/ridden/vehicle, mob/living/driver)
	var/turf/start = get_turf(vehicle)
	vehicle.MouseDrop_T(driver, driver)
	TEST_ASSERT_EQUAL(driver.buckled, vehicle, "test premise: [driver] должен сесть на [vehicle]")
	vehicle.relaymove(driver, EAST)
	return get_turf(vehicle) != start

/datum/unit_test/vehicle_needs_driver_arms/Run()
	// Каждый на своём ряду: уехавший спидбайк не должен загородить дорогу следующему
	var/turf/row = run_loc_floor_bottom_left
	var/mob/living/carbon/human/armed = allocate(/mob/living/carbon/human, row)
	var/obj/vehicle/ridden/space/speedbike/bike = allocate(/obj/vehicle/ridden/space/speedbike, row)
	TEST_ASSERT(try_drive(bike, armed), "test premise: персонаж с руками должен уехать на спидбайке")

	row = get_step(row, NORTH)
	var/mob/living/carbon/human/armless = allocate(/mob/living/carbon/human, row)
	for(var/zone in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
		var/obj/item/bodypart/arm = armless.get_bodypart(zone)
		arm.drop_limb()
		qdel(arm)
	TEST_ASSERT_EQUAL(armless.get_num_arms(), 0, "test premise: у персонажа не должно остаться рук")
	var/obj/vehicle/ridden/space/speedbike/armless_bike = allocate(/obj/vehicle/ridden/space/speedbike, row)
	TEST_ASSERT(!try_drive(armless_bike, armless), "Безрукий персонаж уехал на спидбайке")

	row = get_step(row, NORTH)
	var/mob/living/simple_animal/mouse/mouse = allocate(/mob/living/simple_animal/mouse, row)
	var/obj/vehicle/ridden/space/speedbike/mouse_bike = allocate(/obj/vehicle/ridden/space/speedbike, row)
	TEST_ASSERT(!try_drive(mouse_bike, mouse), "Мышь уехала на спидбайке")

/// Картонный танк водит тот, у кого есть руки; мышь внутри не рулит.
/datum/unit_test/cardboard_tank_needs_driver_arms
	var/area/test_area
	var/saved_gravity

/datum/unit_test/cardboard_tank_needs_driver_arms/Run()
	// На резервационном z нет гравитации, а танк без неё не едет вовсе
	test_area = get_area(run_loc_floor_bottom_left)
	saved_gravity = test_area.has_gravity
	test_area.has_gravity = STANDARD_GRAVITY
	var/obj/vehicle/sealed/cardboard_tank/tank = allocate(/obj/vehicle/sealed/cardboard_tank)
	var/turf/start = get_turf(tank)
	var/mob/living/simple_animal/mouse/mouse = allocate(/mob/living/simple_animal/mouse)
	tank.mob_enter(mouse)
	TEST_ASSERT(tank.is_driver(mouse), "test premise: мышь должна сесть за руль танка")
	tank.relaymove(mouse, EAST)
	TEST_ASSERT_EQUAL(get_turf(tank), start, "Мышь уехала на картонном танке")

	tank.mob_exit(mouse)
	var/mob/living/carbon/human/driver = allocate(/mob/living/carbon/human)
	tank.mob_enter(driver)
	TEST_ASSERT(tank.is_driver(driver), "test premise: персонаж должен сесть за руль танка")
	tank.relaymove(driver, EAST)
	TEST_ASSERT(get_turf(tank) != start, "Персонаж с руками не смог поехать на картонном танке")

/datum/unit_test/cardboard_tank_needs_driver_arms/Destroy()
	if(test_area)
		test_area.has_gravity = saved_gravity
	return ..()
