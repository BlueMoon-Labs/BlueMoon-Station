// ===== Мили-виляние: классификатор врага, уворотный waypoint, распределение стаи =====
// Проверяют: мили-моб уклоняется/распределяет путь против дальнобойного врага,
// прямой подход против ближника, реактивный флаг "по мне стреляют".

///Классификатор боевого типа цели: дальник (.ranged / держит пушку) или ближник.
/datum/unit_test/ai_target_is_ranged_classifier/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/ranged_mob = allocate(/mob/living/simple_animal/hostile, get_step(start, EAST))
	ranged_mob.ranged = TRUE
	var/mob/living/simple_animal/hostile/melee_mob = allocate(/mob/living/simple_animal/hostile, get_step(start, WEST))
	melee_mob.ranged = FALSE

	TEST_ASSERT(ai_target_is_ranged(ranged_mob), "A ranged simple hostile must classify as a ranged threat")
	TEST_ASSERT(!ai_target_is_ranged(melee_mob), "A melee simple hostile must not classify as a ranged threat")

	var/mob/living/carbon/human/gunman = allocate(/mob/living/carbon/human, get_step(start, NORTH))
	var/obj/item/gun/energy/e_gun/gun = allocate(/obj/item/gun/energy/e_gun, start)
	gunman.put_in_hands(gun)
	TEST_ASSERT(ai_target_is_ranged(gunman), "A human holding a gun must classify as a ranged threat")

	var/mob/living/carbon/human/unarmed = allocate(/mob/living/carbon/human, get_step(start, SOUTH))
	TEST_ASSERT(!ai_target_is_ranged(unarmed), "An unarmed human must not classify as a ranged threat")

///Попадание снаряда в пауна ставит флаг "по мне стреляют" на время AI_UNDER_FIRE_DURATION.
/datum/unit_test/ai_under_fire_flag_on_bullet/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)

	TEST_ASSERT(!(controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] > world.time), "A freshly created controller must not be under fire")

	var/obj/item/projectile/bullet = allocate(/obj/item/projectile, start)
	SEND_SIGNAL(pawn, COMSIG_ATOM_BULLET_ACT, bullet, BODY_ZONE_CHEST)

	TEST_ASSERT(controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] > world.time, "A bullet hit must stamp the under-fire deadline into the future")
	TEST_ASSERT(controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] <= world.time + AI_UNDER_FIRE_DURATION, "The under-fire deadline must not exceed the configured duration")

	qdel(controller)

///Против дальнобойной цели мили-моб получает фланговый тайл подхода,
///а не лобовую клетку на линии огня.
/datum/unit_test/ai_weave_flank_against_ranged/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/turf/shooter_turf = locate(start.x + 4, start.y, start.z)
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, shooter_turf)
	shooter.ranged = TRUE
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, shooter)

	var/datum/ai_planning_subtree/tactical_approach/weaver = GLOB.ai_subtrees[/datum/ai_planning_subtree/tactical_approach]
	weaver.SelectBehaviors(controller, 0.5)

	var/turf/approach = controller.blackboard[BB_AI_APPROACH_TILE]
	TEST_ASSERT_NOTNULL(approach, "A melee mob approaching a ranged threat must plan an approach tile")
	TEST_ASSERT(get_dist(approach, shooter_turf) <= 1, "The approach tile must hug the target")
	var/turf/head_on = get_step(shooter_turf, get_dir(shooter_turf, start))
	TEST_ASSERT(approach != head_on, "Under fire the head-on tile on the firing line must be avoided")

	qdel(controller)

///Прямой шаг занят союзником: мили-моб окружает, беря свободную клетку цели,
///а не встаёт в очередь за спиной сокомандника.
/datum/unit_test/ai_surround_instead_of_queue/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/turf/ally_turf = locate(start.x + 1, start.y, start.z)
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, ally_turf)
	var/turf/prey_turf = locate(start.x + 2, start.y, start.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	ally.density = TRUE
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_planning_subtree/tactical_approach/weaver = GLOB.ai_subtrees[/datum/ai_planning_subtree/tactical_approach]
	weaver.SelectBehaviors(controller, 0.5)

	var/turf/approach = controller.blackboard[BB_AI_APPROACH_TILE]
	TEST_ASSERT_NOTNULL(approach, "A queued melee mob must plan a free flanking tile instead of waiting in line")
	TEST_ASSERT(get_dist(approach, prey_turf) <= 1, "The surround tile must hug the target")
	TEST_ASSERT(approach != ally_turf, "The surround tile must not be the ally-occupied tile")

	qdel(controller)

///Милишное поведение переключает цель движения на тайл подхода и обратно.
/datum/unit_test/ai_melee_movement_follows_approach_tile/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/turf/prey_turf = locate(start.x + 3, start.y, start.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_behavior/hostile_melee_attack/fist = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	var/turf/flank = locate(start.x + 3, start.y + 1, start.z)
	controller.set_blackboard_key(BB_AI_APPROACH_TILE, flank)
	fist.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(controller.current_movement_target, flank, "While an approach tile is held, movement must aim at it")

	controller.clear_blackboard_key(BB_AI_APPROACH_TILE)
	fist.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(controller.current_movement_target, prey, "Without an approach tile, movement must aim at the target itself")

	controller.CancelActions()
	qdel(controller)

///Тайл подхода в шаге от пешки, цель в двух: гейт прибытия мовера
///(required_distance) считает такой тайл уже достигнутым и не делает ни шага,
///а адъяценси-гейт атаки ещё не открыт - моб замирал в двух клетках от жертвы
///до самого поводка погони. Дотянувшись до тайла, движение обязано перейти
///на саму цель.
/datum/unit_test/ai_melee_close_approach_tile_yields_to_target/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/turf/prey_turf = locate(start.x + 2, start.y, start.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_behavior/hostile_melee_attack/fist = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	var/turf/flank = locate(start.x + 1, start.y + 1, start.z)
	TEST_ASSERT(get_dist(pawn, flank) <= fist.required_distance, "Sanity: the flank tile must sit within the mover's arrival distance")
	TEST_ASSERT(get_dist(pawn, prey_turf) > 1, "Sanity: the prey must start out of melee reach")
	controller.set_blackboard_key(BB_AI_APPROACH_TILE, flank)
	fist.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(controller.current_movement_target, prey, "An approach tile the mover already considers reached must hand movement over to the target")

	controller.CancelActions()
	qdel(controller)

// ===== Живость: шум, укрытие, читаемый кайт, патрульный поводок =====

///Громкий шум рядом отправляет мирного моба проверить точку (SEARCH),
///занятый боем и троттленный - игнорируют, засадчик не расчехляется.
/datum/unit_test/ai_noise_investigation/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/listener = allocate(/mob/living/simple_animal/hostile, start)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human, get_step(start, NORTH))
	register_fake_player(fake_player, get_turf(fake_player))
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(listener)
	var/turf/epicenter = locate(start.x + 5, start.y, start.z)

	GLOB.ai_recent_noise.Cut() //изоляция от коалесцирования прошлых тестов
	ai_broadcast_noise(epicenter, AI_NOISE_GUNSHOT_RANGE)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_SEARCH, "A loud noise must send an idle mob into the search state")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_KNOWN_POS], epicenter, "The mob must investigate the noise epicenter")
	TEST_ASSERT(controller.blackboard[BB_AI_NOISE_COOLDOWN] > world.time, "An investigation must arm the noise throttle")

	//в бою шум не перебивает цель
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(start, EAST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.blackboard[BB_AI_NOISE_COOLDOWN] = 0
	controller.blackboard[BB_AI_LAST_KNOWN_POS] = null
	controller.hear_ai_noise(epicenter)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_LAST_KNOWN_POS], "A mob in combat must ignore noise")

	//засадчик не расчехляется на шум
	var/mob/living/simple_animal/hostile/lurker = allocate(/mob/living/simple_animal/hostile, get_step(start, WEST))
	var/datum/ai_controller/hostile_adapter/ambusher/ambush_controller = new(lurker)
	ambush_controller.hear_ai_noise(epicenter)
	TEST_ASSERT_NOTEQUAL(ambush_controller.blackboard[BB_AI_STATE], AI_STATE_SEARCH, "An ambusher must not break cover to investigate noise")

	unregister_fake_player(fake_player)
	qdel(controller)
	qdel(ambush_controller)

///Слух выстрела не через всю карту: моб дальше радиуса слышимости не срывается
///на разведку (иначе стрельба в одного собирала мобов со всего уровня сквозь стены).
/datum/unit_test/ai_distant_gunshot_ignored/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/listener = allocate(/mob/living/simple_animal/hostile, start)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(listener)
	var/turf/epicenter = locate(start.x + 7, start.y, start.z)

	GLOB.ai_recent_noise.Cut() //изоляция от коалесцирования прошлых тестов
	ai_broadcast_noise(epicenter, AI_NOISE_GUNSHOT_RANGE)
	TEST_ASSERT_NOTEQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_SEARCH, "A gunshot beyond the AI hearing radius must not rouse a distant mob")
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_LAST_KNOWN_POS], "A distant gunshot must not seed an investigation point")

	qdel(controller)

///Зажатый под огнём моб без достижимой цели уходит за укрытие от стрелка.
/datum/unit_test/ai_pinned_mob_takes_cover/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/pawn_turf = locate(start.x + 1, start.y + 1, start.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/turf/shooter_turf = locate(start.x + 4, start.y + 1, start.z)
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, shooter_turf)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_LAST_ATTACKER, shooter)
	controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] = world.time + AI_UNDER_FIRE_DURATION

	var/datum/ai_planning_subtree/take_cover_when_pinned/cover = GLOB.ai_subtrees[/datum/ai_planning_subtree/take_cover_when_pinned]
	var/verdict = cover.SelectBehaviors(controller, 0.5)

	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "A pinned mob must commit to taking cover")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/hold_covering_position) in controller.current_behaviors, "A pinned mob must plan a move into cover")
	var/list/stored_args = controller.behavior_args[/datum/ai_behavior/hold_covering_position]
	var/turf/hiding = stored_args?[1]
	TEST_ASSERT_NOTNULL(hiding, "The cover move must carry its tile")
	TEST_ASSERT(get_dist(hiding, shooter_turf) > get_dist(pawn_turf, shooter_turf), "Without walls the cover tile must at least fall back from the shooter")

	//цель в досягаемости и путь не исчерпан - прятки не перебивают бой
	controller.CancelActions()
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(pawn_turf, EAST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.blackboard[BB_AI_FRUSTRATION] = 0
	verdict = cover.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_NOTEQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "A mob with a reachable target must keep fighting instead of hiding")

	controller.CancelActions()
	qdel(controller)

///Гистерезис кайта: продолжение прошлого направления отступления побеждает
///равные альтернативы - стрейф читаемой линией, а не зигзагом.
/datum/unit_test/ai_retreat_direction_hysteresis/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/pawn_turf = locate(start.x + 1, start.y + 1, start.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/mob/living/carbon/human/threat = allocate(/mob/living/carbon/human, locate(start.x + 4, start.y + 1, start.z))
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)

	controller.blackboard[BB_AI_LAST_RETREAT_DIR] = NORTHWEST
	var/turf/chosen = controller.best_retreat_tile(list(threat))
	TEST_ASSERT_EQUAL(chosen, get_step(pawn_turf, NORTHWEST), "Continuing the previous retreat direction must win over equal-distance alternatives")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_RETREAT_DIR], NORTHWEST, "The taken retreat direction must be remembered")

	qdel(controller)

///Мирный поводок: уведённый от якоря моб возвращается домой ШТАТНЫМ мувером
///(план FSM), сырой Move() из idle-тика запрещён; якорь не крадётся
///выманиванием и переезжает только при явном скачке (телепорте).
/datum/unit_test/ai_patrol_leash_returns_home/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/pawn_turf = locate(start.x, start.y + 1, start.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	var/datum/idle_behavior/idle_random_walk/hostile_ambience/idler = controller.idle_behavior
	TEST_ASSERT(istype(idler), "Sanity: the melee profile must use the ambience idle behavior")

	//первый мирный тик ставит якорь на месте
	idler.perform_idle_behavior(0, controller)
	TEST_ASSERT_NOTNULL(controller.blackboard[BB_AI_PATROL_ANCHOR], "The first idle tick must anchor the mob's territory")

	//моб "оттащен" за поводок: idle-тик стоит на месте (никакого сырого Move),
	//якорь остаётся домом, а возврат планирует FSM через обычное движение
	var/turf/far_anchor = locate(pawn_turf.x + AI_PATROL_LEASH + 2, pawn_turf.y, pawn_turf.z)
	controller.set_blackboard_key(BB_AI_PATROL_ANCHOR, far_anchor)
	var/turf/before_turf = get_turf(pawn)
	idler.perform_idle_behavior(0, controller)
	TEST_ASSERT_EQUAL(get_turf(pawn), before_turf, "Beyond the leash the idle tick must not raw-step the pawn")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_PATROL_ANCHOR], far_anchor, "A same-z displacement must not steal the patrol anchor")

	var/datum/ai_planning_subtree/hostile_fsm/brain = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]
	var/verdict = brain.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "The FSM must commit to walking home")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/travel_towards/patrol_return) in controller.current_behaviors, "The way home must use the normal mover")
	TEST_ASSERT_EQUAL(controller.current_movement_target, far_anchor, "The mover must aim at the patrol anchor")
	controller.CancelActions()

	//явный скачок (телепорт) переставляет дом: якорь сбрасывается и ставится заново
	var/turf/teleport_turf = locate(pawn_turf.x, pawn_turf.y + 10, pawn_turf.z)
	pawn.forceMove(teleport_turf)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_PATROL_ANCHOR], "A teleport jump must drop the stale patrol anchor")
	idler.perform_idle_behavior(0, controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_PATROL_ANCHOR], teleport_turf, "The next idle tick must anchor the new home")

	qdel(controller)
