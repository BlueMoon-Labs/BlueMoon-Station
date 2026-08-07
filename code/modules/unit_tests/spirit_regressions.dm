// ===== Регрессии "духи поломались" после порта слуха на спатиал-грид =====
//
// Слух теперь ищет кандидатов в ячейках грида, а не BFS-обходом view():
// любой мувер, который двигается голым присваиванием loc/x/y мимо Moved(),
// оставляет свою запись в ячейке точки спавна и глохнет навсегда.

/// Воображаемый друг двигался оверрайдом forceMove с голым loc= и не слышал
/// ни владельца, ни окружающих. Recall дополнительно сажал его в contents
/// владельца, где грид его не отслеживал.
/datum/unit_test/imaginary_friend_hearing/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/brain_trauma/special/imaginary_friend/trauma = new
	trauma.owner = host
	var/mob/camera/imaginary_friend/trapped/friend = allocate(/mob/camera/imaginary_friend/trapped, run_loc_floor_bottom_left, trauma)

	TEST_ASSERT(friend.spatial_grid_key, "An imaginary friend must register in the hearing channel on Initialize")
	TEST_ASSERT(friend in get_hearers_in_view(7, run_loc_floor_bottom_left), "premise: a freshly spawned imaginary friend must hear near its spawn")

	//(резервная тест-зона может лежать у края карты - шагаем туда, где есть место)
	var/far_x = run_loc_floor_bottom_left.x + SPATIAL_GRID_CELLSIZE * 2
	if(far_x > world.maxx)
		far_x = run_loc_floor_bottom_left.x - SPATIAL_GRID_CELLSIZE * 2
	var/turf/far_turf = locate(far_x, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	TEST_ASSERT_NOTNULL(far_turf, "test premise: a turf two grid cells away must exist")

	friend.forceMove(far_turf)
	TEST_ASSERT(friend in get_hearers_in_view(7, far_turf), "After forceMove the imaginary friend must hear at its new position")
	TEST_ASSERT(!(friend in get_hearers_in_view(7, run_loc_floor_bottom_left)), "The imaginary friend must not linger in the grid cell it left")

	friend.recall()
	TEST_ASSERT_EQUAL(friend.loc, get_turf(host), "recall() must put the friend on the owner's turf, not into their contents")
	TEST_ASSERT(friend in get_hearers_in_view(7, get_turf(host)), "After recall the imaginary friend must hear at the owner")

	//чистим руками: qdel травмы с owner зовёт on_lose и трогает друга/спавнер
	trauma.owner = null
	trauma.friend = null
	friend.trauma = null
	qdel(trauma)

/// Мёртвые мобы пропускали общий хук регистрации слуха: LOOC (и его рунчат)
/// ищет слушателей только через get_hearers_in_view и переставал видеть гостов.
/datum/unit_test/observer_hearing/Run()
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)

	TEST_ASSERT(ghost.spatial_grid_key, "A ghost must register in the hearing channel on Initialize")
	TEST_ASSERT(ghost in get_hearers_in_view(7, ghost), "A ghost must be findable by get_hearers_in_view (the LOOC path)")

	//(резервная тест-зона может лежать у края карты - шагаем туда, где есть место)
	var/far_x = run_loc_floor_bottom_left.x + SPATIAL_GRID_CELLSIZE * 2
	if(far_x > world.maxx)
		far_x = run_loc_floor_bottom_left.x - SPATIAL_GRID_CELLSIZE * 2
	var/turf/far_turf = locate(far_x, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	TEST_ASSERT_NOTNULL(far_turf, "test premise: a turf two grid cells away must exist")

	ghost.forceMove(far_turf)
	TEST_ASSERT(ghost in get_hearers_in_view(7, far_turf), "After forceMove a ghost must hear at its new position")
	TEST_ASSERT(!(ghost in get_hearers_in_view(7, run_loc_floor_bottom_left)), "A ghost must not linger in the grid cell it left")

/// Векторкрафт двигался голым x+=/y+= мимо Moved(): ячейка грида не переезжала
/// за машиной, пассажиры глохли и оставались глухими после выхода.
/datum/unit_test/vectorcraft_moves_via_moved
	var/moved_fired = FALSE

/datum/unit_test/vectorcraft_moves_via_moved/proc/on_moved(datum/source)
	SIGNAL_HANDLER
	moved_fired = TRUE

/datum/unit_test/vectorcraft_moves_via_moved/Run()
	var/obj/vehicle/sealed/vectorcraft/car = allocate(/obj/vehicle/sealed/vectorcraft, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/passenger = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	passenger.forceMove(car)
	TEST_ASSERT(passenger in car.important_recursive_contents?[RECURSIVE_CONTENTS_HEARING_SENSITIVE], \
		"premise: a passenger inside a vectorcraft must appear in its recursive hearing contents")

	RegisterSignal(car, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	var/turf/start_turf = get_turf(car)
	//одного вызова с максимальной скоростью хватает ровно на один тайл на восток
	car.vector["x"] = 110
	car.move_car()
	UnregisterSignal(car, COMSIG_MOVABLE_MOVED)

	TEST_ASSERT(get_turf(car) != start_turf, "test premise: move_car at full speed must move the car a tile")
	TEST_ASSERT(moved_fired, "vectorcraft movement must go through Moved() - direct x/y writes bypass the spatial grid and deafen passengers")
	TEST_ASSERT(passenger in get_hearers_in_view(7, get_turf(car)), "A passenger must stay hearable after the car drives")

	car.mob_exit(passenger)
	TEST_ASSERT(isturf(passenger.loc), "premise: mob_exit must drop the passenger onto a turf")
	TEST_ASSERT(passenger in get_hearers_in_view(7, get_turf(passenger)), "A passenger who left the car must hear at the exit spot")

/// Телепатия Карен (qareen): спелл выдаётся на Initialize, кнопка на месте
/// и can_cast проходит - "шептание в мозг" доступно.
/datum/unit_test/qareen_telepathy/Run()
	var/mob/living/simple_animal/qareen/spirit = allocate(/mob/living/simple_animal/qareen, run_loc_floor_bottom_left)

	var/obj/effect/proc_holder/spell/targeted/telepathy/qareen/transmit = locate() in spirit.mob_spell_list
	TEST_ASSERT_NOTNULL(transmit, "The qareen must receive its telepathy spell on Initialize")
	TEST_ASSERT_NOTNULL(transmit.action, "The telepathy spell must create its action button")
	TEST_ASSERT_EQUAL(transmit.action.owner, spirit, "The telepathy action must be granted to the qareen")

	//can_cast с player_lock требует минда с этим спеллом в одном из списков
	spirit.mind = new /datum/mind("qareen_telepathy_test")
	spirit.mind.current = spirit
	TEST_ASSERT(transmit.can_cast(spirit, TRUE, TRUE), "The qareen must pass can_cast for its telepathy spell")

	//цель в соседней клетке должна попадать в выборку целей спелла
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT(target in transmit.view_or_range(transmit.range, spirit, transmit.selection_type), \
		"An adjacent human must be a valid telepathy target")

	spirit.mind.current = null
	QDEL_NULL(spirit.mind)
