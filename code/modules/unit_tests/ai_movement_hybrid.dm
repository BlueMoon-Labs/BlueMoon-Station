// ===== Гибридное движение и obstacle policy =====
//
// Проверяют: атаку реальной преграды кэшированного JPS-пути
// (не направляющей догадки), переключение прямого режима на JPS после
// неудачных шагов, раннюю сдачу через фрустрацию и дверную политику.

///Тест ведёт луп руками: подкладывает movement_path, зовёт move()/recalculate_path().
///Живой луп в это время продолжает фиерить из SSai_movement и на любом сне теста
///(поиск пути внутри get_path_to, цепочка атаки) успевает шагнуть и срезать кэш
///маршрута из-под проверки. Отодвигаем его очередь, чтобы шагал только тест.
/datum/unit_test/proc/hold_move_loop(datum/move_loop/loop)
	loop.pause_for(1 MINUTES)

///Тестовый контроллер с гибридным движением
/datum/ai_controller/unit_test_mover
	ai_movement = /datum/ai_movement/hybrid
	blackboard = list(
		BB_AI_TARGETING_STRATEGY = /datum/targeting_strategy/hostile_legacy,
	)

/obj/structure/ai_unit_test_boundary
	name = "indestructible test boundary"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/ai_unit_test_barrier
	name = "test barrier"
	density = TRUE
	anchored = TRUE
	damage_deflection = 0
	max_integrity = 20

/obj/structure/ai_unit_test_barrier/expensive
	max_integrity = 200

/// Non-dense blocker whose pathing proc must opt into evaluation explicitly.
/obj/structure/ai_unit_test_path_probe
	density = FALSE
	can_astar_pass = CANASTARPASS_ALWAYS_PROC
	var/astar_checks = 0

/obj/structure/ai_unit_test_path_probe/CanAStarPass(obj/item/card/id/ID, to_dir, atom/movable/caller)
	astar_checks++
	return FALSE

///The hot edge cache must preserve an ALWAYS_PROC non-dense blocker and avoid
///calling it again when JPS probes the same directed edge repeatedly.
/datum/unit_test/ai_jps_directed_edge_cache/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/next_turf = get_step(start_turf, EAST)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/obj/structure/ai_unit_test_path_probe/probe = allocate(/obj/structure/ai_unit_test_path_probe, next_turf)
	var/datum/pathfind/pathfinder = new(pawn, start_turf, next_turf, null, 30, 0, TRUE, null)

	TEST_ASSERT(!pathfinder.can_step(start_turf, next_turf, EAST), "The opted-in non-dense blocker must reject the edge")
	TEST_ASSERT(!pathfinder.can_step(start_turf, next_turf, EAST), "The cached edge must retain the blocker result")
	TEST_ASSERT_EQUAL(probe.astar_checks, 1, "Repeated JPS probes must evaluate a directed edge only once per search")

	qdel(pathfinder)
	probe.can_astar_pass = CANASTARPASS_DENSITY
	pathfinder = new(pawn, start_turf, next_turf, null, 30, 0, TRUE, null)
	TEST_ASSERT(pathfinder.can_step(start_turf, next_turf, EAST), "A non-dense density-only object must use the fast pass path")
	TEST_ASSERT_EQUAL(probe.astar_checks, 1, "The density-only fast path must skip CanAStarPass entirely")
	qdel(pathfinder)

///Plastic flaps must inspect a real movable's pull chain without resolving the
///reserved caller symbol as /proc and producing undefined-var runtimes.
/datum/unit_test/ai_plastic_flaps_pull_chain_pathing/Run()
	var/turf/destination = get_step(run_loc_floor_bottom_left, EAST)
	var/obj/structure/plasticflaps/flaps = allocate(/obj/structure/plasticflaps, destination)
	var/obj/item/crowbar/carrier = allocate(/obj/item/crowbar, run_loc_floor_bottom_left)
	var/obj/item/wrench/pulled_item = allocate(/obj/item/wrench, run_loc_floor_bottom_left)
	TEST_ASSERT(carrier.start_pulling(pulled_item, GRAB_PASSIVE, MOVE_FORCE_OVERPOWERING, TRUE), "Test carrier must establish a pull chain")
	TEST_ASSERT(flaps.CanAStarPass(null, EAST, carrier), "A nonliving movable and its nonliving payload must pass plastic flaps")
	var/datum/pathfind/pathfinder = new(carrier, run_loc_floor_bottom_left, destination, null, 30, 0, TRUE, null)
	TEST_ASSERT(pathfinder.can_step(run_loc_floor_bottom_left, destination, EAST), "JPS must forward the movable path owner instead of the reserved caller proc")
	qdel(pathfinder)

///An expired pathfinder lease must never release the newer request which reused
///its slot, and normal completion must clear the owner reference.
/datum/unit_test/pathfinder_lease_generation/Run()
	var/datum/flowcache/cache = new(1)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/datum/pathfinder_lease/first_lease = cache.getfree(pawn)
	TEST_ASSERT_NOTNULL(first_lease, "The first pathfinder request must acquire the only slot")
	cache.found(first_lease, FALSE, FALSE)
	TEST_ASSERT(!QDELETED(first_lease), "A timed-out request must retain its token until the original search returns")

	var/datum/pathfinder_lease/second_lease = cache.getfree(pawn)
	TEST_ASSERT_NOTNULL(second_lease, "The second request must reuse the released slot")
	cache.found(first_lease)
	TEST_ASSERT_EQUAL(cache.run, 1, "Finishing an expired lease must not release its successor")
	TEST_ASSERT_EQUAL(cache.flow[second_lease.slot], second_lease, "The successor must still own the slot")

	cache.found(second_lease)
	TEST_ASSERT_EQUAL(cache.run, 0, "Finishing the live lease must release the slot exactly once")
	qdel(cache)

///Prospective atmosphere checks must not break legacy callers which omit it.
/datum/unit_test/simple_animal_environment_is_safe_argument/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/turf/open/current_turf = run_loc_floor_bottom_left
	var/datum/gas_mixture/vacuum = new

	TEST_ASSERT_EQUAL(pawn.environment_is_safe(), pawn.environment_is_safe(current_turf.air), "The no-argument call must still inspect the current turf")
	TEST_ASSERT(!pawn.environment_is_safe(vacuum), "A supplied vacuum mixture must be checked instead of the pawn's current turf")
	qdel(vacuum)

///Runtime atmos requirement changes must update the direct pathing bounds only
///through the documented refresh hook.
/datum/unit_test/simple_animal_atmos_bounds_refresh/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/datum/gas_mixture/vacuum = new

	TEST_ASSERT(!pawn.atmosphere_is_safe(vacuum), "Default oxygen requirements must reject vacuum")
	pawn.atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	pawn.refresh_atmos_pathing_sensitivity()
	TEST_ASSERT(pawn.atmosphere_is_safe(vacuum), "Refreshing zeroed requirements must make vacuum safe")
	TEST_ASSERT(!pawn.requires_safe_atmosphere(), "Refreshing zeroed requirements must disable atmosphere-sensitive pathing")
	qdel(vacuum)

///Хелпер: атаковать преграду с полностью подготовленным окружением
/datum/unit_test/proc/perform_obstacle_attack(datum/ai_controller/controller, atom/target)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, target)
	var/datum/ai_behavior/attack_obstructions/smasher = GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions)
	return smasher.perform(0.5, controller, BB_AI_CURRENT_TARGET)

///Атакуется реальный следующий турф JPS-пути, а не турф по направлению к цели
/datum/unit_test/ai_hybrid_attacks_real_path_blocker/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	pawn.melee_damage_lower = 20
	pawn.melee_damage_upper = 20
	//цель на востоке, но кэшированный путь ведёт на север
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/turf/east_guess = get_step(run_loc_floor_bottom_left, EAST)
	var/turf/north_path = get_step(run_loc_floor_bottom_left, NORTH)
	var/obj/structure/grille/path_blocker = new(north_path)

	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	pawn.forceMove(run_loc_floor_bottom_left)

	//JPS-луп с подложенным кэшем пути: следующий шаг - северный турф с решёткой
	var/datum/move_loop/has_target/jps/loop = SSmove_manager.jps_move(pawn, prey, 2, repath_delay = 10 SECONDS, subsystem = SSai_movement, extra_info = controller)
	TEST_ASSERT_NOTNULL(loop, "Sanity: jps_move must create a loop")
	hold_move_loop(loop)
	loop.movement_path = list(north_path)

	var/turf/reported = ai_get_blocked_path_turf(pawn, prey)
	TEST_ASSERT_EQUAL(reported, north_path, "The blocked-path helper must report the cached path turf, not the directional guess")
	TEST_ASSERT(!east_guess.is_blocked_turf(exclude_mobs = TRUE), "Sanity: the directional guess turf must be free")

	var/integrity_before = path_blocker.obj_integrity
	perform_obstacle_attack(controller, prey)
	TEST_ASSERT(path_blocker.obj_integrity < integrity_before, "The attack must damage the actual path blocker (grille on the cached path)")

	SSmove_manager.stop_looping(pawn, SSai_movement)
	qdel(path_blocker)
	qdel(controller)

///Репорт плейтеста: моб ломал дверь, которой не было на его маршруте. Пока JPS-луп
///ещё не отдал путь (асинхронный поиск ждёт слот SSpathfinder), направляющая догадка
///get_step_towards уводила удар на случайную преграду по прямой к цели. В прямом
///режиме догадка легитимна, в режиме JPS - нет: ждём настоящий следующий шаг.
/datum/unit_test/ai_obstacle_waits_for_pending_jps_route/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/guess_turf = get_step(start, EAST)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	pawn.melee_damage_lower = 20
	pawn.melee_damage_upper = 20
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start.x + 4, start.y, start.z))
	var/mob/living/carbon/human/body_blocker = allocate(/mob/living/carbon/human, guess_turf)
	var/obj/structure/grille/guessed_barrier = allocate(/obj/structure/grille, guess_turf)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)

	//прямой режим: JPS-лупа нет вовсе, догадка по направлению - единственный источник
	TEST_ASSERT_EQUAL(ai_get_blocked_path_turf(pawn, prey), guess_turf, "Direct-mode movement must still fall back to the directional guess")
	TEST_ASSERT_EQUAL(ai_path_blocker_mob(pawn, prey), body_blocker, "Direct-mode movement must still detect a body blocker ahead")

	var/datum/move_loop/has_target/jps/loop = SSmove_manager.jps_move(pawn, prey, 2, repath_delay = 10 SECONDS, subsystem = SSai_movement, extra_info = controller)
	TEST_ASSERT_NOTNULL(loop, "Sanity: jps_move must create a loop")
	hold_move_loop(loop)
	loop.movement_path = null
	loop.repath_in_progress = TRUE

	TEST_ASSERT_NULL(ai_get_blocked_path_turf(pawn, prey), "A pawn waiting for its JPS route must not attack an obstacle guessed off the straight line")
	TEST_ASSERT_NULL(ai_path_blocker_mob(pawn, prey), "A pawn waiting for its JPS route must not punch a mob guessed off the straight line")

	var/integrity_before = guessed_barrier.obj_integrity
	perform_obstacle_attack(controller, prey)
	TEST_ASSERT_EQUAL(guessed_barrier.obj_integrity, integrity_before, "A guessed obstacle must survive while the real route is still being calculated")

	//Поиск завершился и маршрута не нашёл: цель отгорожена, и пробить преграду -
	//единственный путь. Ждать больше нечего, иначе моб просто стоит столбом.
	loop.repath_in_progress = FALSE
	TEST_ASSERT_EQUAL(ai_get_blocked_path_turf(pawn, prey), guess_turf, "A finished JPS search that found no route must fall back to the directional guess")
	TEST_ASSERT_EQUAL(ai_path_blocker_mob(pawn, prey), body_blocker, "A finished JPS search that found no route must still see a body blocker ahead")

	loop.movement_path = list(guess_turf)
	loop.repath_in_progress = TRUE
	TEST_ASSERT_EQUAL(ai_get_blocked_path_turf(pawn, prey), guess_turf, "A ready route must report its real blocked step again")

	SSmove_manager.stop_looping(pawn, SSai_movement)
	qdel(controller)

///Кэшированный JPS-маршрут ведёт туда, где цель БЫЛА. Мовер обязан заказать
///перепрокладку, как только конец пути перестал приводить к цели, но не чаще,
///чем разрешает repath_cooldown.
/datum/unit_test/ai_jps_repaths_when_target_leaves_route/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/route_end = locate(start.x + 2, start.y, start.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, route_end)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)

	var/datum/move_loop/has_target/jps/loop = SSmove_manager.jps_move(pawn, prey, 2, repath_delay = 10 SECONDS, max_path_length = 10, subsystem = SSai_movement, extra_info = controller)
	TEST_ASSERT_NOTNULL(loop, "Sanity: jps_move must create a loop")
	hold_move_loop(loop)

	//цель стоит там, куда ведёт маршрут: шагаем по кэшу, перепрокладку не заказываем
	loop.movement_path = list(get_step(start, EAST), route_end)
	loop.repath_in_progress = FALSE
	COOLDOWN_RESET(loop, repath_cooldown)
	loop.move()
	TEST_ASSERT(COOLDOWN_FINISHED(loop, repath_cooldown), "A route that still ends at the target must not spend a rebuild")
	TEST_ASSERT_EQUAL(length(loop.movement_path), 1, "Sanity: the consumed step must be dropped from the cached route")

	//цель ушла: конец маршрута больше никуда не приводит
	prey.forceMove(locate(start.x + 4, start.y + 4, start.z))
	COOLDOWN_RESET(loop, repath_cooldown)
	loop.move()
	TEST_ASSERT(!COOLDOWN_FINISHED(loop, repath_cooldown), "A route whose end no longer reaches the target must be rebuilt")

	//кулдаун обязан гейтить частоту, иначе каждый шаг цели стоит поиска пути
	loop.movement_path = list(get_step(get_turf(pawn), EAST))
	loop.repath_in_progress = FALSE
	COOLDOWN_START(loop, repath_cooldown, 30 SECONDS)
	loop.move()
	TEST_ASSERT(!loop.repath_in_progress, "The repath cooldown must keep throttling rebuild requests")

	SSmove_manager.stop_looping(pawn, SSai_movement)
	qdel(controller)

///Неудачная перепрокладка на ходу (цель ушла за стену) не должна стирать рабочий
///маршрут: иначе моб встаёт колом посреди коридора вместо того, чтобы дойти.
/datum/unit_test/ai_jps_failed_rebuild_keeps_live_route/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/prey_turf = locate(start.x + 2, start.y + 2, start.z)
	//Наглухо замурованная цель: ни JPS, ни фолбэк через преграды маршрута не найдут.
	for(var/direction in GLOB.alldirs)
		allocate(/obj/structure/ai_unit_test_boundary, get_step(prey_turf, direction))

	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)

	var/datum/move_loop/has_target/jps/loop = SSmove_manager.jps_move(pawn, prey, 2, repath_delay = 10 SECONDS, max_path_length = 10, subsystem = SSai_movement, extra_info = controller)
	TEST_ASSERT_NOTNULL(loop, "Sanity: jps_move must create a loop")
	hold_move_loop(loop)
	var/turf/live_step = get_step(start, EAST)
	loop.movement_path = list(live_step)
	loop.repath_in_progress = FALSE
	COOLDOWN_RESET(loop, repath_cooldown)

	loop.recalculate_path()
	TEST_ASSERT_EQUAL(length(loop.movement_path), 1, "A failed mid-route rebuild must leave the working path in place")
	TEST_ASSERT_EQUAL(loop.movement_path[1], live_step, "The surviving path must still be the original one")

	SSmove_manager.stop_looping(pawn, SSai_movement)
	qdel(controller)

///Прямой режим переключается на JPS до первого удара в статическое препятствие.
/datum/unit_test/ai_hybrid_direct_to_jps_switch/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	//Цель близко (прямой режим), но путь перегорожен стеной вплотную.
	var/turf/wall_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)

	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	pawn.forceMove(run_loc_floor_bottom_left)

	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	mover.start_moving_towards(controller, prey, 1)

	var/datum/move_loop/first_loop = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT_NOTNULL(first_loop, "Sanity: the hybrid mover must start a move loop")
	TEST_ASSERT(!istype(first_loop, /datum/move_loop/has_target/jps), "A close target must start in direct mode")

	SEND_SIGNAL(first_loop, COMSIG_MOVELOOP_PREPROCESS_CHECK)
	var/datum/move_loop/final_loop = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT(istype(final_loop, /datum/move_loop/has_target/jps), "A known static blocker must switch the pawn onto a JPS loop before Move() bumps it")
	TEST_ASSERT_EQUAL(get_turf(pawn), run_loc_floor_bottom_left, "The proactive switch must happen before the pawn spends a move on the wall")

	mover.stop_moving_towards(controller)
	wall_turf.ChangeTurf(saved_turf_type)
	qdel(controller)

///Игрок берёт симпла под контроль: контроллер уходит в AI_STATUS_OFF, но гибридный
///move-loop живёт на SSai_movement отдельно и его гейт able_to_run на владении
///клиентом не срабатывает. Если луп не погасить, он каждые movement_delay ведёт
///пауна к устаревшей AI-цели и перебивает ввод игрока - управление "намертво".
///CancelActions() не помогает, когда запланированного движ-поведения уже нет,
///поэтому уход в OFF/IDLE обязан гасить луп напрямую.
/datum/unit_test/ai_controller_stops_movement_when_off/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	pawn.forceMove(run_loc_floor_bottom_left)

	//Активное преследование: контроллер ON, гибридный луп ведёт к цели.
	controller.set_ai_status(AI_STATUS_ON)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	mover.start_moving_towards(controller, prey, 1)
	TEST_ASSERT_NOTNULL(SSmove_manager.processing_on(pawn, SSai_movement), "Sanity: an active chase must have a move loop")
	TEST_ASSERT_EQUAL(mover.moving_controllers[controller], prey, "Sanity: the mover must track the chase target")

	//Игрок берёт моба: контроллер уходит в OFF (как в on_sentience_gained). Запланированного
	//движ-поведения нет, поэтому CancelActions() луп не тронет - его обязан снять сам переход.
	controller.set_ai_status(AI_STATUS_OFF)
	TEST_ASSERT_NULL(SSmove_manager.processing_on(pawn, SSai_movement), "Going OFF must stop the AI move loop so it cannot override a controlling player's movement")
	TEST_ASSERT_NULL(mover.moving_controllers[controller], "The mover bookkeeping must clear when the controller stops so a resumed chase re-plans movement")

	qdel(controller)

///A wall-smasher must break through the rock on its direct line instead of paying
///for an expensive open-terrain JPS detour: attack_obstacle_in_path clears the wall.
/mob/living/simple_animal/hostile/unit_test_wallbreaker
	environment_smash = ENVIRONMENT_SMASH_WALLS | ENVIRONMENT_SMASH_RWALLS
	melee_damage_lower = 40
	melee_damage_upper = 40
	obj_damage = 40

/datum/unit_test/ai_hybrid_smasher_breaks_through_instead_of_detour/Run()
	var/turf/wall_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/unit_test_wallbreaker/breaker = allocate(/mob/living/simple_animal/hostile/unit_test_wallbreaker, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)

	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(breaker)
	breaker.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(controller.clears_obstacles_in_path(), "Sanity: the melee profile must include the obstacle-clearing subtree")

	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	mover.start_moving_towards(controller, prey, 1)
	var/datum/move_loop/first_loop = SSmove_manager.processing_on(breaker, SSai_movement)
	TEST_ASSERT_NOTNULL(first_loop, "Sanity: the hybrid mover must start a move loop")
	TEST_ASSERT(!istype(first_loop, /datum/move_loop/has_target/jps), "A close target must start in direct mode")

	SEND_SIGNAL(first_loop, COMSIG_MOVELOOP_PREPROCESS_CHECK)
	var/datum/move_loop/after_check = SSmove_manager.processing_on(breaker, SSai_movement)
	TEST_ASSERT(!istype(after_check, /datum/move_loop/has_target/jps), "A wall-smasher must stay on the cheap direct loop and break through rock, not launch a JPS detour")
	TEST_ASSERT_EQUAL(get_turf(breaker), run_loc_floor_bottom_left, "The smasher must hold at the wall while the obstacle behavior clears it, not step onto the rock")

	//Контроль: непробиваемая преграда всё ещё уводит того же смэшера в JPS-обход.
	mover.stop_moving_towards(controller)
	wall_turf.ChangeTurf(/turf/closed/indestructible)
	mover.start_moving_towards(controller, prey, 1)
	var/datum/move_loop/second_loop = SSmove_manager.processing_on(breaker, SSai_movement)
	SEND_SIGNAL(second_loop, COMSIG_MOVELOOP_PREPROCESS_CHECK)
	var/datum/move_loop/after_indestructible = SSmove_manager.processing_on(breaker, SSai_movement)
	TEST_ASSERT(istype(after_indestructible, /datum/move_loop/has_target/jps), "An unbreakable wall must still switch the smasher onto a JPS detour")

	mover.stop_moving_towards(controller)
	wall_turf.ChangeTurf(saved_turf_type)
	qdel(controller)

///Clean JPS must route around a powered airlock which rejects the pawn's ID.
/datum/unit_test/ai_hybrid_routes_around_inaccessible_door/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/door_turf = get_step(start_turf, EAST)
	var/turf/target_turf = locate(start_turf.x + 3, start_turf.y, start_turf.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, door_turf)
	door.req_access = list(ACCESS_SECURITY)
	door.machine_stat &= ~NOPOWER
	door.locked = FALSE
	door.welded = FALSE
	door.density = TRUE

	var/list/path = get_path_to(pawn, prey, AI_MAX_PATH_LENGTH, 1, null, TRUE, null, TRUE)
	TEST_ASSERT(length(path), "JPS must find the open detour around an inaccessible airlock")
	TEST_ASSERT(!(door_turf in path), "The clean route must not enter the powered airlock without access")

///JPS после столкновения с мобом исключает занятый тайл и строит обход
/datum/unit_test/ai_hybrid_avoids_mob_blocker/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/turf/blocker_turf = get_step(run_loc_floor_bottom_left, EAST)
	//НЕатакуемый союзник: JPS-обход остаётся для союзников/нейтралов. Атакуемого врага
	//моб теперь пробивает, а не обходит (см. ai_body_block / attack_path_blocker).
	var/mob/living/simple_animal/hostile/blocker = allocate(/mob/living/simple_animal/hostile, blocker_turf)
	blocker.faction = pawn.faction.Copy()
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	pawn.forceMove(run_loc_floor_bottom_left)

	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	var/datum/move_loop/has_target/jps/loop = SSmove_manager.jps_move(pawn,
		prey,
		2,
		repath_delay = 10 SECONDS,
		max_path_length = AI_MAX_PATH_LENGTH,
		minimum_distance = 1,
		subsystem = SSai_movement,
		extra_info = controller)
	TEST_ASSERT_NOTNULL(loop, "Sanity: the JPS loop must be created")
	// jps_move() starts its initial route asynchronously. Wait for that owner to
	// release the loop before exercising the single-flight manual repath below.
	for(var/i in 1 to 20)
		if(!loop.repath_in_progress)
			break
		sleep(world.tick_lag)
	TEST_ASSERT(!loop.repath_in_progress, "Sanity: the initial asynchronous JPS route must finish")
	TEST_ASSERT(blocker.density, "Sanity: the blocking mob must be dense")
	loop.movement_path = list(blocker_turf)

	mover.post_move_jps(loop, FALSE)
	TEST_ASSERT_EQUAL(loop.avoid, blocker_turf, "A mob-blocked next step must become the temporary JPS avoidance turf")

	// post_move_jps() starts the replacement route asynchronously. The search
	// may yield under CI tick pressure, so wait for its published result rather
	// than racing it with a second single-flight recalculate_path() call.
	for(var/i in 1 to 20)
		if(length(loop.movement_path) && !loop.repath_in_progress)
			break
		sleep(world.tick_lag)
	TEST_ASSERT(length(loop.movement_path), "JPS must find an alternate route around the mob blocker")
	TEST_ASSERT(!(blocker_turf in loop.movement_path), "The alternate route must not cross the occupied turf")

	SSmove_manager.stop_looping(pawn, SSai_movement)
	qdel(controller)

///Атакуемого врага-блокера JPS НЕ обходит: avoid не ставится, моб держит позицию,
///чтобы его пробил attack_obstacle_in_path (fairness-паритет body-block).
/datum/unit_test/ai_hybrid_enemy_blocker_not_avoided/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/turf/blocker_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/mob/living/carbon/human/blocker = allocate(/mob/living/carbon/human, blocker_turf)
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	pawn.forceMove(run_loc_floor_bottom_left)

	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	var/datum/move_loop/has_target/jps/loop = SSmove_manager.jps_move(pawn,
		prey,
		2,
		repath_delay = 10 SECONDS,
		max_path_length = AI_MAX_PATH_LENGTH,
		minimum_distance = 1,
		subsystem = SSai_movement,
		extra_info = controller)
	TEST_ASSERT_NOTNULL(loop, "Sanity: the JPS loop must be created")
	for(var/i in 1 to 20)
		if(!loop.repath_in_progress)
			break
		sleep(world.tick_lag)
	TEST_ASSERT(pawn.CanAttack(blocker), "Sanity: the human blocker must be attackable by the hostile")
	loop.movement_path = list(blocker_turf)
	loop.avoid = null

	mover.post_move_jps(loop, FALSE)
	TEST_ASSERT_NULL(loop.avoid, "An attackable enemy blocker must not be routed around: the mob holds to attack it")

	SSmove_manager.stop_looping(pawn, SSai_movement)
	qdel(controller)

///A transient mob collision must not turn a cheap direct chase into a full JPS route.
/datum/unit_test/ai_hybrid_direct_retries_mob_blocker/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/turf/blocker_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/mob/living/carbon/human/blocker = allocate(/mob/living/carbon/human, blocker_turf)
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]

	mover.start_moving_towards(controller, prey, 1)
	var/datum/move_loop/has_target/direct_loop = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT_NOTNULL(direct_loop, "Sanity: direct movement loop must start")
	TEST_ASSERT(blocker.density, "Sanity: the neighbouring mob must block the direct step")

	var/frustration_before = controller.blackboard[BB_AI_FRUSTRATION] || 0
	mover.post_move_direct(direct_loop, FALSE)
	var/datum/move_loop/after_failure = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT(!istype(after_failure, /datum/move_loop/has_target/jps), "A moving mob blocker must stay on the cheap direct loop")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_FRUSTRATION] || 0, frustration_before, "A transient mob blocker must not make the target look unreachable")
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CONGESTED_TARGET], "One transient collision must not arm congestion retargeting")

	mover.stop_moving_towards(controller)
	qdel(controller)

///A sustained allied queue should keep the original target when alternatives
///are distant, then prefer a nearby open enemy without requiring it to attack.
/datum/unit_test/ai_hybrid_congestion_retargets_relevant_enemy/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/mob/living/simple_animal/hostile/ally_blocker = allocate(/mob/living/simple_animal/hostile, get_step(start_turf, EAST))
	pawn.faction = list("congestion_test_pack")
	ally_blocker.faction = list("congestion_test_pack")
	var/mob/living/carbon/human/blocked_target = allocate(/mob/living/carbon/human, locate(start_turf.x + 3, start_turf.y, start_turf.z))
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, blocked_target)
	mover.start_moving_towards(controller, blocked_target, 1)
	var/datum/move_loop/has_target/direct_loop = SSmove_manager.processing_on(pawn, SSai_movement)

	TEST_ASSERT_NOTNULL(direct_loop, "Sanity: the blocked chase must start a direct movement loop")
	TEST_ASSERT(ally_blocker.density, "Sanity: the allied mob must block the direct step")
	for(var/i in 1 to AI_MOB_CONGESTION_RETRY_THRESHOLD)
		mover.post_move_direct(direct_loop, FALSE)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CONGESTED_TARGET], blocked_target, "Repeated allied blocking must arm a congestion-aware target refresh")
	var/mob/living/carbon/human/far_open_target = allocate(/mob/living/carbon/human, locate(start_turf.x + 6, start_turf.y + 2, start_turf.z))
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_NOTNULL(far_open_target, "Sanity: a distant open alternative must exist")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], blocked_target, "Congestion must not replace the target with another long chase")

	var/mob/living/carbon/human/open_target = allocate(/mob/living/carbon/human, get_step(start_turf, NORTH))
	for(var/i in 1 to AI_MOB_CONGESTION_RETRY_THRESHOLD)
		mover.post_move_direct(direct_loop, FALSE)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CONGESTED_TARGET], blocked_target, "A sustained queue must re-arm target evaluation after the first scan")
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], open_target, "The queued hostile must prefer a nearby enemy with an open approach")
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_LAST_ATTACKER], "Congestion retargeting must not depend on retaliation")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_FRUSTRATION] || 0, 0, "Allied congestion must not masquerade as an unreachable static route")

	mover.stop_moving_towards(controller)
	qdel(controller)

///Фрустрация копится с неудачами и роняет план задолго до легаси-120с
/datum/unit_test/ai_hybrid_frustration_growth/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]

	var/frustration_before = controller.blackboard[BB_AI_FRUSTRATION] || 0
	for(var/i in 1 to mover.max_pathing_attempts)
		mover.increment_pathing_failures(controller)
	TEST_ASSERT(controller.blackboard[BB_AI_FRUSTRATION] >= frustration_before + mover.max_pathing_attempts, "Every failed step must grow frustration")
	TEST_ASSERT(controller.pathing_attempts >= mover.max_pathing_attempts, "Sanity: pathing attempts must accumulate to the give-up threshold")

	qdel(controller)

///Дверная политика: обесточенный шлюз открывается, болтированный - нет
/datum/unit_test/ai_obstacle_policy_doors/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/turf/door_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/obj/machinery/door/airlock/door = new(door_turf)
	door.machine_stat |= NOPOWER
	var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(/datum/obstacle_policy)

	//обесточенный шлюз: политика берётся открыть
	TEST_ASSERT(!door.hasPower(), "Sanity: a freshly placed test airlock must be unpowered")
	TEST_ASSERT(policy.try_handle(pawn, controller, door), "The policy must handle an unpowered closed airlock")
	sleep(2 SECONDS) //дверь открывается асинхронно с анимацией
	TEST_ASSERT(!door.density, "The unpowered airlock must end up open")

	//болтированная дверь не открывается и не ломается базовой политикой
	door.density = TRUE
	door.locked = TRUE
	var/obj/machinery/door/airlock/bolted = door
	TEST_ASSERT(!policy.try_airlock(pawn, bolted), "A bolted airlock must not be opened by the policy")

	qdel(door)
	qdel(controller)

///Climbable cover must be planned through and climbed instead of attacked.
/datum/unit_test/ai_obstacle_policy_climbs_sandbags/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/barrier_turf = get_step(start_turf, EAST)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/obj/structure/barricade/sandbags/sandbags = allocate(/obj/structure/barricade/sandbags, barrier_turf)
	var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(/datum/obstacle_policy)
	sandbags.climb_time = 1
	sandbags.climb_stun = 0
	var/integrity_before = sandbags.obj_integrity

	TEST_ASSERT_EQUAL(policy.get_blocker_breach_cost(pawn, controller, sandbags), policy.climb_cost, "Climbable sandbags must use the climbing path cost")
	TEST_ASSERT(policy.try_step(pawn, controller, start_turf, barrier_turf), "The obstacle policy must start climbing the sandbags")
	sleep(0.2 SECONDS)
	TEST_ASSERT_EQUAL(get_turf(pawn), barrier_turf, "The hostile mob must climb onto the sandbags")
	TEST_ASSERT_EQUAL(sandbags.obj_integrity, integrity_before, "Climbing must not damage the sandbags")

	qdel(controller)

///Spacewalkers may plan through vacuum, while an oxygen-dependent pawn must
///not gain that permission merely because it can push itself through space.
/datum/unit_test/ai_inteq_space_pathing_capability/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/space_turf = get_step(start_turf, EAST)
	var/saved_turf_type = space_turf.type
	space_turf.ChangeTurf(/turf/open/space)
	space_turf = get_step(start_turf, EAST)

	var/mob/living/simple_animal/hostile/syndicate/space/stormtrooper/stormtrooper = allocate(/mob/living/simple_animal/hostile/syndicate/space/stormtrooper, start_turf)
	var/datum/ai_controller/unit_test_mover/controller = new(stormtrooper)
	var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(/datum/obstacle_policy)
	TEST_ASSERT(controller.can_path_through_space(), "A vacuum-safe InteQ Stormtrooper must advertise stable space movement")
	TEST_ASSERT(controller.can_enter_dangerous_turf(space_turf), "The shared dangerous-turf gate must admit the Stormtrooper into space")
	TEST_ASSERT_EQUAL(policy.get_breach_step_cost(stormtrooper, controller, start_turf, space_turf, FALSE, null), 1, "Obstacle routing must treat an empty space step as traversable")

	var/turf/target_turf = locate(start_turf.x + 9, start_turf.y, start_turf.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	mover.start_jps_loop(controller, prey)
	var/datum/move_loop/has_target/jps/loop = SSmove_manager.processing_on(stormtrooper, SSai_movement)
	TEST_ASSERT(istype(loop), "The Stormtrooper's explicit JPS loop must start")
	TEST_ASSERT(!loop.simulated_only, "Stormtrooper JPS must include space tiles")
	TEST_ASSERT(loop.skip_first, "Hybrid JPS must not spend its first movement tick stepping onto its current turf")
	mover.stop_moving_towards(controller)

	var/mob/living/simple_animal/hostile/oxygen_dependent = allocate(/mob/living/simple_animal/hostile, start_turf)
	oxygen_dependent.spacewalk = TRUE
	var/datum/ai_controller/unit_test_mover/oxygen_controller = new(oxygen_dependent)
	TEST_ASSERT(!oxygen_controller.can_path_through_space(), "An oxygen-dependent mob must not plan a lethal vacuum route")
	TEST_ASSERT(!oxygen_controller.can_enter_dangerous_turf(space_turf), "The dangerous-turf gate must keep the oxygen-dependent mob out of space")

	space_turf.ChangeTurf(saved_turf_type)
	qdel(oxygen_controller)
	qdel(controller)

///Atmosphere-sensitive one-step movement must reject vacuum for ordinary
///pirates while admitting the explicitly sealed space variants.
/datum/unit_test/ai_pirate_tactical_atmosphere_gate/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/open/vacuum_turf = get_step(start_turf, EAST)
	var/datum/gas_mixture/saved_air = new
	saved_air.copy_from(vacuum_turf.air)
	vacuum_turf.air.clear()

	var/mob/living/simple_animal/hostile/pirate/melee/pirate = allocate(/mob/living/simple_animal/hostile/pirate/melee, start_turf)
	var/datum/ai_controller/hostile_adapter/pirate_controller = pirate.ai_controller
	TEST_ASSERT(!pirate_controller.can_enter_turf(vacuum_turf), "An oxygen-dependent pirate must reject a vacuum tactical step")

	qdel(pirate_controller)
	qdel(pirate)
	var/mob/living/simple_animal/hostile/pirate/melee/space/space_pirate = allocate(/mob/living/simple_animal/hostile/pirate/melee/space, start_turf)
	var/datum/ai_controller/hostile_adapter/space_controller = space_pirate.ai_controller
	TEST_ASSERT(space_controller.can_enter_turf(vacuum_turf), "A sealed space pirate must be able to pursue through vacuum")

	vacuum_turf.air.copy_from(saved_air)
	qdel(saved_air)
	qdel(space_controller)

///Playtest report: a pirate on a breached ruin ran to a distant airlock and broke it
///instead of walking through the hull breach next to it. A sealed space pirate has no
///atmosphere gate, so its route must take the adjacent breach; only an oxygen-dependent
///pirate is allowed to refuse the vacuum edge and detour.
/datum/unit_test/ai_space_pirate_prefers_hull_breach/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/goal = locate(start.x + 4, start.y, start.z)
	var/turf/breach = locate(start.x + 2, start.y, start.z)
	var/turf/door_turf = locate(start.x + 2, start.y + 4, start.z)
	//Solid partition on the pawn's column. The only two crossings are the breach directly
	//ahead and the airlock four tiles north, so a detour is always the longer route.
	for(var/y_offset in -4 to 3)
		if(!y_offset)
			continue
		var/turf/wall_turf = locate(start.x + 2, start.y + y_offset, start.z)
		if(wall_turf)
			allocate(/obj/structure/ai_unit_test_boundary, wall_turf)
	allocate(/obj/machinery/door/airlock, door_turf)

	var/saved_breach_type = breach.type
	breach.ChangeTurf(/turf/open/space)
	breach = locate(start.x + 2, start.y, start.z)

	var/mob/living/simple_animal/hostile/pirate/melee/space/space_pirate = allocate(/mob/living/simple_animal/hostile/pirate/melee/space, start)
	var/datum/ai_controller/hostile_adapter/space_controller = space_pirate.ai_controller
	TEST_ASSERT(space_controller.can_path_through_space(), "Sanity: a sealed space pirate must plan through vacuum")

	var/datum/pathfind/space_search = new(space_pirate, start, goal, null, AI_MAX_PATH_LENGTH, 0, !space_controller.can_path_through_space(), null)
	TEST_ASSERT(space_search.can_step(get_step(start, EAST), breach, EAST), "A sealed space pirate must accept the hull breach edge")
	var/list/space_path = space_search.search()
	qdel(space_search)

	TEST_ASSERT(length(space_path), "The space pirate must find a route to the far side")
	TEST_ASSERT(breach in space_path, "The route must use the breach next to the pawn, not a distant airlock")
	TEST_ASSERT(!(door_turf in space_path), "A four-tile breach route must never be traded for the airlock detour")
	qdel(space_controller)
	qdel(space_pirate)

	var/mob/living/simple_animal/hostile/pirate/melee/breather = allocate(/mob/living/simple_animal/hostile/pirate/melee, start)
	var/datum/ai_controller/hostile_adapter/breather_controller = breather.ai_controller
	TEST_ASSERT(!breather_controller.can_path_through_space(), "An oxygen-dependent pirate must not plan a lethal vacuum route")
	var/datum/pathfind/breather_search = new(breather, start, goal, null, AI_MAX_PATH_LENGTH, 0, !breather_controller.can_path_through_space(), null)
	TEST_ASSERT(!breather_search.can_step(get_step(start, EAST), breach, EAST), "An oxygen-dependent pirate must refuse the vacuum breach edge")
	var/list/breather_path = breather_search.search()
	qdel(breather_search)
	TEST_ASSERT(!(breach in breather_path), "An oxygen-dependent pirate's route must never cross the breach")

	breach.ChangeTurf(saved_breach_type)
	qdel(breather_controller)

///An exhausted route with the victim in plain sight a couple of tiles away must
///siege (hold the target, no demote thrash); an exhausted route to a hidden or
///distant victim must still release the target with a short rebuild delay.
/datum/unit_test/ai_unreachable_route_releases_target/Run()
	var/mob/living/simple_animal/hostile/pirate/melee/pirate = allocate(/mob/living/simple_animal/hostile/pirate/melee, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/hostile_adapter/controller = pirate.ai_controller
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	//жертва на виду вплотную: исчерпанный маршрут - это мебель между нами, а не
	//потерянная цель. Разжалование здесь давало вечный цикл "взял-исчерпал-бросил"
	//(round-23.35.57: моб у стеклянного стола, 34 цикла за 2.5 минуты).
	for(var/i in 1 to mover.max_pathing_attempts)
		mover.increment_pathing_failures(controller)
	TEST_ASSERT(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "A visible pointblank target must be sieged, not released")
	TEST_ASSERT(controller.blackboard[BB_AI_SIEGE_UNTIL] > world.time, "An exhausted route to a visible close target must arm the siege hold")

	//жертва скрылась за глухой преградой: исчерпанный маршрут честно освобождает цель
	controller.blackboard[BB_AI_SIEGE_UNTIL] = 0
	var/turf/far_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/turf/blocker_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	prey.forceMove(far_turf)
	allocate(/obj/effect/ai_unit_test_opaque_blocker, blocker_turf)
	TEST_ASSERT(!can_see(pirate, prey, AI_SIEGE_HOLD_RANGE), "Sanity: the blocker must hide the prey")
	for(var/i in 1 to mover.max_pathing_attempts)
		mover.increment_pathing_failures(controller)

	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "A hostile must release a hidden target after exhausting the route")
	TEST_ASSERT(controller.blackboard[BB_AI_ROUTE_RETRY_AT] > world.time, "An exhausted route must receive a short rebuild delay")
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/result = finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT(result & AI_BEHAVIOR_FAILED, "The target finder must respect the unreachable-route delay")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "The same unreachable target must not be reacquired immediately")

	controller.note_attacker(prey)
	TEST_ASSERT(isnull(controller.blackboard[BB_AI_ROUTE_RETRY_AT]), "Taking damage must clear the route delay immediately")
	qdel(controller)

///A mob that needs oxygen must neither path through nor attack a window in vacuum.
/datum/unit_test/ai_obstacle_policy_rejects_unsafe_breach/Run()
	var/turf/open/from_turf = run_loc_floor_bottom_left
	var/turf/open/vacuum_turf = get_step(from_turf, EAST)
	var/datum/gas_mixture/saved_air = new
	saved_air.copy_from(vacuum_turf.air)
	vacuum_turf.air.clear()

	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, from_turf)
	pawn.melee_damage_lower = 20
	pawn.melee_damage_upper = 20
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, vacuum_turf)
	var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(/datum/obstacle_policy)
	var/integrity_before = window.obj_integrity

	var/turf_safe = pawn.can_safely_enter_turf(vacuum_turf)
	var/path_blocked = from_turf.LinkBlockedWithAccess(vacuum_turf, pawn, null)
	var/handled = policy.try_step(pawn, controller, from_turf, vacuum_turf)
	var/integrity_after = window.obj_integrity
	vacuum_turf.air.copy_from(saved_air)
	qdel(saved_air)

	TEST_ASSERT(!turf_safe, "An oxygen-breathing hostile must classify vacuum as unsafe")
	TEST_ASSERT(path_blocked, "JPS must reject the unsafe vacuum edge")
	TEST_ASSERT(!handled, "The obstacle policy must refuse a breach into unsafe atmosphere")
	TEST_ASSERT_EQUAL(integrity_after, integrity_before, "The unsafe window must not be damaged")
	qdel(controller)

///Weighted breach A* must choose the cheaper destructible corridor.
/datum/unit_test/ai_breach_path_prefers_cheaper_barrier/Run()
	var/start_x = run_loc_floor_bottom_left.x
	var/center_y = run_loc_floor_bottom_left.y + 2
	var/z = run_loc_floor_bottom_left.z

	var/turf/start = locate(start_x, center_y, z)
	var/turf/goal = locate(start_x + 4, center_y, z)
	var/barrier_x = start_x + 2
	var/turf/expensive_turf = locate(barrier_x, center_y, z)
	var/turf/cheap_turf = locate(barrier_x, center_y + 1, z)
	//The line is too long to route around within six steps. The only two
	//crossings are the expensive direct blocker and a cheap one-tile detour.
	for(var/y in (center_y - 2) to (center_y + 2))
		if(y == center_y || y == center_y + 1)
			continue
		allocate(/obj/structure/ai_unit_test_boundary, locate(barrier_x, y, z))
	allocate(/obj/structure/ai_unit_test_barrier/expensive, expensive_turf)
	allocate(/obj/structure/ai_unit_test_barrier, cheap_turf)

	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	pawn.melee_damage_lower = 20
	pawn.melee_damage_upper = 20
	pawn.atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	pawn.refresh_atmos_pathing_sensitivity()
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(/datum/obstacle_policy)
	var/turf/lower_before_barrier = get_step(expensive_turf, WEST)
	var/turf/upper_before_barrier = get_step(cheap_turf, WEST)
	TEST_ASSERT(!QDELETED(controller), "Sanity: the test controller must remain alive")
	TEST_ASSERT_EQUAL(policy.get_breach_step_cost(pawn, controller, start, get_step(start, EAST), TRUE, null), 1, "An open corridor step must have the base cost")
	TEST_ASSERT(policy.get_breach_step_cost(pawn, controller, lower_before_barrier, expensive_turf, TRUE, null) > 0, "The expensive barrier must be clearable")
	TEST_ASSERT(policy.get_breach_step_cost(pawn, controller, upper_before_barrier, cheap_turf, TRUE, null) > 0, "The cheap barrier must be clearable")
	var/datum/ai_breach_pathfinder/pathfinder = new(pawn, controller, policy, start, goal, 6, 0, TRUE, null)
	var/list/path = pathfinder.search()
	qdel(pathfinder)

	TEST_ASSERT(length(path), "The weighted breach pathfinder must find a corridor")
	TEST_ASSERT(cheap_turf in path, "The route must cross the cheap barrier")
	TEST_ASSERT(!(expensive_turf in path), "The route must avoid the more expensive barrier")
	qdel(controller)

///JPS получает персональный бюджет контроллера, а не общий жёсткий лимит.
/datum/unit_test/ai_hybrid_controller_path_budget/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 12, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	controller.max_path_length = 77

	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	mover.start_jps_loop(controller, prey)
	var/datum/move_loop/has_target/jps/loop = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT(istype(loop), "The explicit JPS loop must start")
	TEST_ASSERT_EQUAL(loop.max_path_length, 77, "JPS must use the controller-specific path budget")

	mover.stop_moving_towards(controller)
	qdel(controller)

///Большая дистанция в открытом коридоре не должна сама по себе запускать JPS.
/datum/unit_test/ai_hybrid_distant_open_target_starts_direct/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 12, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]

	mover.start_moving_towards(controller, prey, 1)
	var/datum/move_loop/has_target/loop = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT_NOTNULL(loop, "A distant target must start a movement loop")
	TEST_ASSERT(!istype(loop, /datum/move_loop/has_target/jps), "Distance alone must not pay for JPS in an open corridor")

	mover.stop_moving_towards(controller)
	qdel(controller)

///Штатные спецфазы останавливают controller-movement без ложной фрустрации.
/datum/unit_test/ai_special_movement_gates/Run()
	var/mob/living/simple_animal/hostile/megafauna/dragon/drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon)
	var/mob/living/simple_animal/hostile/megafauna/bubblegum/bubblegum = allocate(/mob/living/simple_animal/hostile/megafauna/bubblegum)
	var/mob/living/simple_animal/hostile/megafauna/hierophant/hierophant = allocate(/mob/living/simple_animal/hostile/megafauna/hierophant)

	drake.swooping = TRUE
	bubblegum.charging = TRUE
	hierophant.blinking = TRUE
	TEST_ASSERT(!drake.can_ai_controller_move(), "A swooping drake must reject controller movement")
	TEST_ASSERT(!bubblegum.can_ai_controller_move(), "A charging Bubblegum must reject controller movement")
	TEST_ASSERT(!hierophant.can_ai_controller_move(), "A blinking Hierophant must reject controller movement")

	drake.swooping = FALSE
	bubblegum.charging = FALSE
	hierophant.blinking = FALSE
	TEST_ASSERT(drake.can_ai_controller_move() && bubblegum.can_ai_controller_move() && hierophant.can_ai_controller_move(), "Boss movement gates must reopen after their phases")

///The chase search radius must shrink to distance + detour slack for a close target,
///clamp to the path budget, and stay unbounded when the budget is infinite.
/datum/unit_test/ai_jps_effective_radius_bounds/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/target_turf = locate(start.x + 3, start.y, start.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)

	TEST_ASSERT_EQUAL(get_dist(pawn, prey), 3, "Sanity: the prey must be three tiles away")
	TEST_ASSERT_EQUAL(ai_effective_path_radius(pawn, prey, AI_MAX_PATH_LENGTH), 3 + AI_JPS_DETOUR_SLACK, "A close target must bound the radius to distance + detour slack")
	TEST_ASSERT(ai_effective_path_radius(pawn, prey, AI_MAX_PATH_LENGTH) < AI_MAX_PATH_LENGTH, "The bounded radius must be smaller than the full budget for a close target")
	TEST_ASSERT_EQUAL(ai_effective_path_radius(pawn, prey, 10), 10, "The radius must never exceed the path budget")
	TEST_ASSERT_EQUAL(ai_effective_path_radius(pawn, prey, 0), 0, "An infinite budget must stay unbounded")

///The bounded radius must still find a real detour around an obstacle - the cap trims
///wasted exploration on failed searches, it must not make a reachable target look stuck.
/datum/unit_test/ai_jps_capped_radius_keeps_detour/Run()
	var/turf/start = locate(run_loc_floor_bottom_left.x, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/turf/target_turf = locate(start.x + 3, start.y, start.z)
	var/turf/blocked_turf = locate(start.x + 1, start.y, start.z)
	//A one-column indestructible wall straddling the direct line forces a weave up and
	//over: reachable, but the path is longer than the straight-line distance.
	for(var/offset in -1 to 1)
		allocate(/obj/structure/ai_unit_test_boundary, locate(start.x + 1, start.y + offset, start.z))

	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	//Isolate the geometry from atmosphere gating so the test measures only the radius cap.
	pawn.atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	pawn.refresh_atmos_pathing_sensitivity()
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)

	var/effective_max = ai_effective_path_radius(pawn, prey, AI_MAX_PATH_LENGTH)
	TEST_ASSERT(effective_max < AI_MAX_PATH_LENGTH, "Sanity: the cap must be active for this close target")

	var/datum/pathfind/pathfinder = new(pawn, start, target_turf, null, effective_max, 0, TRUE, null)
	var/list/path = pathfinder.search()
	qdel(pathfinder)

	TEST_ASSERT(length(path), "The bounded search must still route around the wall to a reachable target")
	TEST_ASSERT(!(blocked_turf in path), "The detour must not pass through the indestructible wall")
	TEST_ASSERT(length(path) > get_dist(start, target_turf), "A path around the wall must be longer than the straight-line distance")

///Пол скорости погони обязан считаться от ФАКТИЧЕСКОГО RUN_DELAY, а не от
///константы. Июльская калибровка отсчитывалась от репозиторного RUN_DELAY 2.5,
///а прод всё это время крутил 1.5 - и пол, задуманный как "0.6 от игрока",
///по факту означал паритет.
/datum/unit_test/ai_pursuit_floor_tracks_run_delay/Run()
	var/player_run_delay = CONFIG_GET(number/movedelay/run_delay)
	TEST_ASSERT(player_run_delay > 0, "Санити: конфиг скорости бега обязан быть загружен")
	TEST_ASSERT_EQUAL(update_ai_pursuit_speed_floor(), max(world.tick_lag, player_run_delay * AI_PURSUIT_SPEED_RATIO), "Пол погони обязан считаться от фактического RUN_DELAY")

	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	TEST_ASSERT(pawn.ai_pursuit_speed_capped, "Санити: обычная фауна обязана быть под полом скорости")

	var/mob_step = movement_quantize_delay(pawn.ai_movement_delay(), world.tick_lag)
	var/player_step = movement_step_delay(player_run_delay, FALSE, world.tick_lag)
	TEST_ASSERT(mob_step > player_step, "Обычная фауна обязана быть медленнее бегущего игрока по прямой ([mob_step] против [player_step])")

///Мув-луп ИИ платит за диагональ ту же цену, что и игрок. Без этого моб на 1.5 дс
///проходил диагональ за 1.5 дс, а игрок за 2.0 - скрытые 1.33x поверх паритета.
/datum/unit_test/ai_move_loop_charges_for_diagonal/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/turf/diagonal_turf = locate(start.x + 2, start.y + 2, start.z)
	TEST_ASSERT_NOTNULL(diagonal_turf, "Санити: диагональный турф обязан существовать внутри резервации")
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, diagonal_turf)

	SSmove_manager.move_towards_legacy(pawn, prey, delay = 2, subsystem = SSai_movement)
	var/datum/move_loop/has_target/loop = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT_NOTNULL(loop, "Санити: мув-луп обязан быть создан")
	loop.set_delay(2)
	var/cardinal_price = loop.scheduled_delay

	TEST_ASSERT(loop.move(), "Санити: шаг к диагональной цели обязан пройти")
	TEST_ASSERT_EQUAL(get_turf(pawn), get_step(start, NORTHEAST), "Санити: первый шаг к диагональной цели обязан быть диагональным")
	TEST_ASSERT_EQUAL(loop.scheduled_delay, movement_step_delay(2, TRUE, world.tick_lag), "Диагональный шаг обязан стоить столько же, сколько диагональный шаг игрока")
	TEST_ASSERT(loop.scheduled_delay > cardinal_price, "Диагональ обязана быть дороже кардинального шага")

	qdel(loop)

///JPS-луп платит за диагональ ту же цену, что бюджетный луп и игрок: маршрут по
///открытой местности сплошь состоит из диагональных сегментов, и без надбавки
///длинная погоня по нему сохраняла те же скрытые 1.33x скорости.
/datum/unit_test/ai_jps_loop_charges_for_diagonal/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/turf/diagonal_turf = locate(start.x + 2, start.y + 2, start.z)
	TEST_ASSERT_NOTNULL(diagonal_turf, "Санити: диагональный турф обязан существовать внутри резервации")
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, diagonal_turf)
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)

	var/datum/move_loop/has_target/jps/loop = SSmove_manager.jps_move(pawn, prey, 2, repath_delay = 10 SECONDS, max_path_length = 10, subsystem = SSai_movement, extra_info = controller)
	TEST_ASSERT_NOTNULL(loop, "Санити: jps_move обязан создать луп")
	hold_move_loop(loop)
	loop.set_delay(2)
	var/cardinal_price = loop.scheduled_delay

	loop.movement_path = list(get_step(start, NORTHEAST), diagonal_turf)
	loop.repath_in_progress = FALSE
	COOLDOWN_RESET(loop, repath_cooldown)
	TEST_ASSERT(loop.move(), "Санити: диагональный шаг по кэшированному маршруту обязан пройти")
	TEST_ASSERT_EQUAL(get_turf(pawn), get_step(start, NORTHEAST), "Санити: шаг обязан быть диагональным")
	TEST_ASSERT_EQUAL(loop.scheduled_delay, movement_step_delay(2, TRUE, world.tick_lag), "Диагональный JPS-шаг обязан стоить столько же, сколько диагональный шаг игрока")
	TEST_ASSERT(loop.scheduled_delay > cardinal_price, "Диагональ JPS-маршрута обязана быть дороже кардинального шага")

	SSmove_manager.stop_looping(pawn, SSai_movement)
	qdel(controller)
