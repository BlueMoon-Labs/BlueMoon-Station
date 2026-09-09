// Регресс на харддел решёток, стёкол, виндоров и канистр после перелёта шаттла.
//
// /atom/movable/onShuttleMove двигает содержимое шаттла голым присваиванием loc,
// то есть мимо Moved() и COMSIG_MOVABLE_MOVED. Подписку на выброс газа ведёт
// /datum/element/atmos_sensitive из react_to_move() именно по этому сигналу, а
// хранится она в turf.atmos_exposure_listeners - ассоциативном списке, ключом в
// котором лежит сам слушатель. Оставленная на покинутом турфе запись поэтому
// является жёсткой ссылкой на атом, и Detach её уже не снимет: он ищет запись на
// ТЕКУЩЕМ турфе атома. Улетевшее с шаттлом стекло уходило в del() на ~240мс.

/// После перелёта подписка на выброс должна уехать вместе с атомом: со старого
/// турфа сняться, на новом появиться и работать.
/datum/unit_test/shuttle_move_atmos_exposure/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/destination = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT(istype(destination), "test premise: the arrival tile is not an open turf")

	var/obj/structure/grille/rider = allocate(/obj/structure/grille)
	TEST_ASSERT_EQUAL(rider.loc, origin, "test premise: the grille did not spawn on the test tile")
	TEST_ASSERT(LAZYACCESS(origin.atmos_exposure_listeners, rider), "test premise: an atmos-sensitive structure did not register exposure on its own turf")

	rider.onShuttleMove(destination, origin, null, NORTH, null, null)

	TEST_ASSERT_EQUAL(rider.loc, destination, "test premise: onShuttleMove did not move the grille")
	TEST_ASSERT(!LAZYACCESS(origin.atmos_exposure_listeners, rider), "a shuttle move left the exposure registration on the departed turf")
	TEST_ASSERT(LAZYACCESS(destination.atmos_exposure_listeners, rider), "a shuttle move did not register exposure on the arrival turf")

	// Запись в списке-гейте ничего не стоит без живой подписки на сигнал, так что
	// проверяем именно доставку: решётка греется выше T0C+1500 и должна встать в
	// очередь SSair, а покинутый турф больше не должен её доставать.
	SEND_SIGNAL(destination, COMSIG_TURF_EXPOSE, destination.air, T0C + 2000)
	TEST_ASSERT(rider in SSair.atom_process, "the exposure signal from the arrival turf did not reach the moved structure")

	rider.atmos_conditions_changed() // сбрасываем по реальному воздуху нового турфа
	TEST_ASSERT(!(rider in SSair.atom_process), "test premise: the grille stayed enrolled in SSair on room-temperature air")
	SEND_SIGNAL(origin, COMSIG_TURF_EXPOSE, origin.air, T0C + 2000)
	TEST_ASSERT(!(rider in SSair.atom_process), "the departed turf still drives exposure on a structure that flew away with the shuttle")

/// Удалённый после перелёта атом не должен оставаться ключом ни в одном
/// atmos_exposure_listeners: такая запись - ровно та одна внешняя ссылка,
/// из-за которой объект уходил в харддел.
/datum/unit_test/shuttle_move_atmos_exposure_harddel/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/destination = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT(istype(destination), "test premise: the arrival tile is not an open turf")

	var/obj/structure/window/shuttle/rider = allocate(/obj/structure/window/shuttle)
	TEST_ASSERT(LAZYACCESS(origin.atmos_exposure_listeners, rider), "test premise: a shuttle window did not register exposure on its own turf")

	rider.onShuttleMove(destination, origin, null, NORTH, null, null)
	qdel(rider)

	TEST_ASSERT(!LAZYACCESS(origin.atmos_exposure_listeners, rider), "the departed turf still holds a reference to the deleted shuttle window")
	TEST_ASSERT(!LAZYACCESS(destination.atmos_exposure_listeners, rider), "the arrival turf still holds a reference to the deleted shuttle window")
	TEST_ASSERT(!(rider in SSair.atom_process), "the deleted shuttle window stayed in SSair.atom_process")

/// Обычное удаление на месте (без перелёта) тоже обязано вычищать турф - это
/// базовая гарантия Detach, на которой держится проверка выше.
/datum/unit_test/atmos_exposure_destroy_clears_turf/Run()
	var/turf/open/spot = run_loc_floor_bottom_left

	var/obj/structure/grille/subject = allocate(/obj/structure/grille)
	TEST_ASSERT(LAZYACCESS(spot.atmos_exposure_listeners, subject), "test premise: the grille did not register exposure on its turf")

	qdel(subject)
	TEST_ASSERT(!LAZYACCESS(spot.atmos_exposure_listeners, subject), "qdel left the structure as an exposure listener on its turf")
