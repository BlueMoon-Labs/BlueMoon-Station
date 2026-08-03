// Режимы полёта в невесомости: стабилизация против свободного полёта.
// Разбор баг-репорта "Сломанное ускорение джетов в космосе" (25.07.2026):
//  - jetpack_stabilizers_persist: выбранный режим переживает выключение двигателя
//  - jetpack_registers_thrust:    включённый двигатель поднимает потолок собственной тяги
//  - jetpack_death_cuts_thrust:   смерть глушит двигатель, но не дрейф
//  - thrust_payment_rule:         разгон, торможение и поворот платные, накат по курсу - нет

/// Сброс стабилизации на каждом `turn_off` и был той "сбрасывающейся стабилизацией", из-за
/// которой игрок в треде был уверен, что включал её, и всё равно улетал неуправляемо.
/datum/unit_test/jetpack_stabilizers_persist/Run()
	var/obj/item/tank/jetpack/oxygen/pack = allocate(/obj/item/tank/jetpack/oxygen)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	TEST_ASSERT(pack.stabilizers, "джетпак обязан приходить со включённой стабилизацией")

	pack.turn_on(user)
	TEST_ASSERT(pack.set_stabilizers(FALSE, user), "переключатель обязан менять режим")
	TEST_ASSERT(!pack.stabilizers, "стабилизация должна была выключиться")

	pack.turn_off(user)
	TEST_ASSERT(!pack.stabilizers, "выключение джетпака не должно сбрасывать выбранный режим")
	pack.turn_on(user)
	TEST_ASSERT(!pack.stabilizers, "включённый заново джетпак обязан помнить свободный полёт")
	pack.turn_off(user)

/// Двигатель поднимает потолок разгона на всё время работы и опускает его обратно, когда снят.
/datum/unit_test/jetpack_registers_thrust/Run()
	var/obj/item/tank/jetpack/oxygen/pack = allocate(/obj/item/tank/jetpack/oxygen)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	TEST_ASSERT(pack.full_speed, "кислородный джетпак считается полноскоростным")
	TEST_ASSERT_EQUAL(user.self_thrust_cap, INERTIA_THRUST_CAP_UNAIDED, "без двигателя потолок должен быть голым")

	pack.turn_on(user)
	TEST_ASSERT_EQUAL(user.self_thrust_cap, INERTIA_THRUST_CAP_JETPACK_FULL, "полноскоростной джетпак обязан поднять потолок")
	pack.turn_off(user)
	TEST_ASSERT_EQUAL(user.self_thrust_cap, INERTIA_THRUST_CAP_UNAIDED, "снятый двигатель обязан вернуть потолок")

	// Джетпак, выпавший из рук, тоже перестаёт быть двигателем: иначе потолок остался бы задран.
	pack.turn_on(user)
	pack.dropped(user)
	TEST_ASSERT(!pack.on, "выпавший джетпак обязан выключиться")
	TEST_ASSERT_EQUAL(user.self_thrust_cap, INERTIA_THRUST_CAP_UNAIDED, "выпавший джетпак не должен держать потолок")

/// Жалоба "а когда умер, скорость не уменьшилась" закрывается не гашением дрейфа - тело обязано
/// лететь по инерции, - а тем, что двигатель перестаёт толкать и разгонять дальше некому.
/datum/unit_test/jetpack_death_cuts_thrust/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, center)
	var/obj/item/tank/jetpack/oxygen/pack = allocate(/obj/item/tank/jetpack/oxygen)
	pilot.AddElement(/datum/element/forced_gravity, 0) // невесомость, иначе дрейф не живёт

	pack.turn_on(pilot)
	pack.set_stabilizers(FALSE, pilot) // со стабилизацией дрейф не начался бы вовсе
	pilot.newtonian_move(NORTH, drift_force = 3, force_loop = FALSE)
	TEST_ASSERT_NOTNULL(pilot.drift_handler, "в свободном полёте дрейф должен был начаться")

	pilot.death()
	TEST_ASSERT(!pack.on, "смерть обязана заглушить двигатель")
	TEST_ASSERT_EQUAL(pilot.self_thrust_cap, INERTIA_THRUST_CAP_UNAIDED, "снятая тяга обязана вернуть потолок")
	TEST_ASSERT_NOTNULL(pilot.drift_handler, "дрейф после смерти обязан остаться - тело летит по инерции")

/// Платит двигатель только за изменение вектора. Накат по курсу на крейсерской скорости
/// бесплатен: двигатель в этот момент не работает, он лишь разрешает шагать.
/datum/unit_test/thrust_payment_rule/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, center)
	pilot.AddElement(/datum/element/forced_gravity, 0)
	pilot.self_thrust_cap = INERTIA_THRUST_CAP_JETPACK

	TEST_ASSERT(pilot.thrust_alters_velocity(NORTH, FALSE, FALSE), "трогаться с места - это работа")
	TEST_ASSERT(!pilot.thrust_alters_velocity(0, FALSE, FALSE), "без направления платить не за что")
	TEST_ASSERT(!pilot.thrust_alters_velocity(NORTH, TRUE, FALSE), "тик дрейфа без стабилизации двигатель не трогает")
	TEST_ASSERT(!pilot.thrust_alters_velocity(NORTH, TRUE, TRUE), "гасить нечего, пока дрейфа нет")

	pilot.newtonian_move(NORTH, drift_force = INERTIA_THRUST_CAP_JETPACK, controlled_cap = INERTIA_THRUST_CAP_JETPACK, force_loop = FALSE)
	TEST_ASSERT_NOTNULL(pilot.drift_handler, "дрейф должен был начаться")

	TEST_ASSERT(pilot.thrust_alters_velocity(NORTH, TRUE, TRUE), "стабилизация обязана платить за гашение дрейфа")
	TEST_ASSERT(!pilot.thrust_alters_velocity(NORTH, FALSE, FALSE), "накат по курсу на крейсерской скорости бесплатен")
	TEST_ASSERT(!pilot.thrust_alters_velocity(NORTHEAST, FALSE, FALSE), "соседняя диагональ - всё ещё курс, а не поворот")
	TEST_ASSERT(pilot.thrust_alters_velocity(EAST, FALSE, FALSE), "поворот на 90 градусов - это работа")
	TEST_ASSERT(pilot.thrust_alters_velocity(SOUTH, FALSE, FALSE), "разворот против курса - это работа")

	// Ниже потолка платим за любой шаг: это разгон.
	pilot.drift_handler.drift_force = INERTIA_THRUST_CAP_JETPACK - 1
	TEST_ASSERT(pilot.thrust_alters_velocity(NORTH, FALSE, FALSE), "пока не вышли на крейсер, каждый шаг разгоняет и потому платный")
