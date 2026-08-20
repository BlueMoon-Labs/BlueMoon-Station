// ===== Адаптер-контроллер hostile-мобов =====
//
// Проверяют: мигрированный карп находит цель планировщиком и зеркалирует её
// в легаси pawn.target; милишное поведение реально бьёт (урон проходит);
// двойного AI нет (легаси-бакеты не трогают моба с контроллером); боль
// будит и наводит на стрелка; чардж взводится.

/mob/living/simple_animal/hostile/unit_test_target_hooks
	var/give_target_calls = 0
	var/lose_target_calls = 0

/mob/living/simple_animal/hostile/unit_test_target_hooks/GiveTarget(new_target)
	give_target_calls++
	return ..()

/mob/living/simple_animal/hostile/unit_test_target_hooks/LoseTarget()
	lose_target_calls++
	return ..()

///Прогнать полный цикл планирования контроллера мимо MC
/datum/unit_test/proc/drive_ai_planning(datum/ai_controller/controller)
	var/saved_state = SSai_controllers.state
	var/saved_limit = Master.current_ticklimit
	SSai_controllers.state = SS_RUNNING
	Master.current_ticklimit = INFINITY
	SSai_controllers.currentrun = list(controller)
	while(length(SSai_controllers.currentrun))
		SSai_controllers.fire(TRUE)
	Master.current_ticklimit = saved_limit
	SSai_controllers.state = saved_state

///Карп на адаптере: цель найдена планированием и отзеркалена в pawn.target
/datum/unit_test/ai_adapter_carp_acquires_target/Run()
	var/mob/living/simple_animal/hostile/carp/fish = allocate(/mob/living/simple_animal/hostile/carp)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	register_fake_player(fake_player, run_loc_floor_bottom_left)
	fake_player.status_flags |= GODMODE //будит контроллер, но сам не цель
	fish.forceMove(run_loc_floor_bottom_left)

	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(fish)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Sanity: adapter near a player must be ON")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy, "Adapter must set the legacy strategy")

	//план ставит поиск целей в очередь; исполнение - в process()
	drive_ai_planning(controller)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets) in controller.current_behaviors, "The first plan must queue target search")
	controller.process(0.5)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "Target search must acquire the human")
	TEST_ASSERT_EQUAL(fish.target, prey, "The legacy pawn.target must mirror the blackboard target")

	//второй цикл планирования: холодное обнаружение даёт читаемую ALERT-паузу
	drive_ai_planning(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ALERT, "A cold acquisition must pass through the ALERT pause")
	//пауза отыграна - FSM входит в бой и ставит милишную атаку
	controller.blackboard[BB_AI_STATE_ENTERED_AT] = world.time - AI_ALERT_REACTION_TIME - 1
	drive_ai_planning(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ENGAGE, "The FSM must be engaging")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack) in controller.current_behaviors, "A melee plan must be queued")

	unregister_fake_player(fake_player)
	qdel(controller)

///High-vision mob whose long sight line must set pursuit range without ballooning
///the JPS/breach search radius: sight distance is unrelated to how far the pathfinder
///should explore for a local detour, and an inflated radius makes every open-terrain
///search pathologically expensive.
/mob/living/simple_animal/hostile/unit_test_farsighted
	vision_range = 4
	aggro_vision_range = 40

/datum/unit_test/ai_adapter_path_length_not_inflated_by_vision/Run()
	var/mob/living/simple_animal/hostile/unit_test_farsighted/watcher = allocate(/mob/living/simple_animal/hostile/unit_test_farsighted, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(watcher)

	TEST_ASSERT(controller.max_target_distance >= watcher.aggro_vision_range, "Pursuit range must still follow the mob's aggro vision")
	TEST_ASSERT(controller.interesting_dist >= watcher.aggro_vision_range, "The wake window must still follow the mob's aggro vision")
	TEST_ASSERT_EQUAL(controller.max_path_length, AI_MAX_PATH_LENGTH, "A long sight line must not inflate the pathfinding search radius")

	qdel(controller)

///Каденс милишки контроллера: легаси-формула "rapid_melee ударов за тик NPC-пула",
///ускоренная компромиссным AI_MELEE_CADENCE_SCALE (между дубовыми 2с легаси и
///имбовым плоским клик-делеем).
/datum/unit_test/ai_hostile_melee_matches_legacy_cadence/Run()
	var/datum/ai_behavior/hostile_melee_attack/melee = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)

	var/mob/living/simple_animal/hostile/slow = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	slow.rapid_melee = 1
	var/datum/ai_controller/hostile_adapter/melee_chaser/slow_controller = new(slow)
	TEST_ASSERT_EQUAL(melee.get_cooldown(slow_controller), SSnpcpool.wait * AI_MELEE_CADENCE_SCALE, "A rapid_melee 1 hostile must swing at the scaled NPC-pool cadence, not at the fast player click delay")

	var/mob/living/simple_animal/hostile/fast = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, EAST))
	fast.rapid_melee = 4
	var/datum/ai_controller/hostile_adapter/melee_chaser/fast_controller = new(fast)
	TEST_ASSERT_EQUAL(melee.get_cooldown(fast_controller), max(world.tick_lag, SSnpcpool.wait * AI_MELEE_CADENCE_SCALE / 4), "A rapid_melee 4 hostile must fit four scaled swings into one NPC-pool tick")

	//Монотонность: больше rapid_melee не может бить медленнее (баг делал rapid_melee 1 быстрее, чем 2)
	TEST_ASSERT(melee.get_cooldown(slow_controller) >= melee.get_cooldown(fast_controller), "Higher rapid_melee must never melee slower than lower")

	qdel(slow_controller)
	qdel(fast_controller)

///Баланс по фидбеку: массовый rapid_melee 2 (волк/синдикат/кот-мясник) не должен
///переигрывать игрока по темпу мили - его каденс не быстрее клик-кулдауна игрока.
/datum/unit_test/ai_hostile_melee_not_faster_than_player/Run()
	var/datum/ai_behavior/hostile_melee_attack/melee = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)

	var/mob/living/simple_animal/hostile/twinner = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	twinner.rapid_melee = 2
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(twinner)
	TEST_ASSERT(melee.get_cooldown(controller) >= CLICK_CD_MELEE, "A rapid_melee 2 hostile must not melee faster than a player's own click cooldown")

	qdel(controller)

///Пол скорости AI-погони: и быстрый моб, и моб на легаси-дефолте клампятся к
///живому полу, который считается от фактической скорости бегущего игрока;
///уже медленный моб и босс (opt-out) - как есть.
///
///Раньше пол был константой, равной легаси-дефолту, и моб на дефолте им не
///задевался. Это и было ошибкой: константу калибровали от репозиторного
///RUN_DELAY 2.5, а прод всегда крутил 1.5 - "пол" по факту означал паритет с
///бегущим игроком, и от фауны нельзя было уйти в принципе.
/datum/unit_test/ai_pursuit_speed_capped/Run()
	var/mob/living/simple_animal/hostile/sprinter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	sprinter.move_to_delay = 1
	TEST_ASSERT_EQUAL(sprinter.ai_movement_delay(), GLOB.ai_pursuit_min_move_delay, "A fast hostile's AI pursuit speed must be capped to the live minimum move delay")

	var/mob/living/simple_animal/hostile/standard = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, WEST))
	standard.move_to_delay = AI_PURSUIT_BASELINE_MOVE_TO_DELAY
	var/saved_pursuit_min_move_delay = GLOB.ai_pursuit_min_move_delay
	var/standard_pursuit_floor = max(saved_pursuit_min_move_delay, AI_LEGACY_MOVE_DELAY_DS(AI_PURSUIT_BASELINE_MOVE_TO_DELAY))
	GLOB.ai_pursuit_min_move_delay = standard_pursuit_floor
	var/standard_delay = standard.ai_movement_delay()
	GLOB.ai_pursuit_min_move_delay = saved_pursuit_min_move_delay
	TEST_ASSERT_EQUAL(standard_delay, standard_pursuit_floor, "A mob at the legacy default move_to_delay is exactly the case the floor exists for")

	var/mob/living/simple_animal/hostile/plodder = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, EAST))
	plodder.move_to_delay = 6
	TEST_ASSERT_EQUAL(plodder.ai_movement_delay(), AI_LEGACY_MOVE_DELAY_DS(6), "A mob already slower than the cap keeps its legacy delay")

	var/mob/living/simple_animal/hostile/boss = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, NORTH))
	boss.move_to_delay = 1
	boss.ai_pursuit_speed_capped = FALSE
	TEST_ASSERT_EQUAL(boss.ai_movement_delay(), AI_LEGACY_MOVE_DELAY_DS(1), "A speed-cap opt-out (boss) keeps its full legacy speed")

///Милишное поведение наносит урон через легаси AttackingTarget
/datum/unit_test/ai_adapter_melee_lands/Run()
	var/mob/living/simple_animal/hostile/brute = allocate(/mob/living/simple_animal/hostile)
	brute.melee_damage_lower = 10
	brute.melee_damage_upper = 10
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	brute.forceMove(run_loc_floor_bottom_left)

	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(brute)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/health_before = prey.health
	var/datum/ai_behavior/hostile_melee_attack/fangs = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	fangs.perform(0.5, controller, BB_AI_CURRENT_TARGET)

	TEST_ASSERT(prey.health < health_before, "An adjacent melee perform must damage the target through AttackingTarget")
	TEST_ASSERT(brute.in_melee, "Melee combat must set the legacy in_melee flag")

	qdel(controller)

///Тяжёлый удар телеграфируется и отменяется, если цель успела выйти.
/datum/unit_test/ai_adapter_melee_telegraph/Run()
	var/mob/living/simple_animal/hostile/asteroid/goliath/goliath = allocate(/mob/living/simple_animal/hostile/asteroid/goliath, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	goliath.target = prey
	var/health_before = prey.health

	goliath.AttackingTarget()
	TEST_ASSERT_EQUAL(prey.health, health_before, "A telegraphed heavy attack must not land immediately")
	prey.forceMove(locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	sleep(goliath.melee_telegraph_duration + 1)
	TEST_ASSERT_EQUAL(prey.health, health_before, "Leaving adjacency during the telegraph must cancel the attack")

	//Смена боевой цели тоже отменяет старый замах и не откатывает target назад.
	var/mob/living/carbon/human/old_target = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/new_target = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	goliath.target = old_target
	var/old_target_health = old_target.health
	goliath.AttackingTarget()
	goliath.target = new_target
	sleep(goliath.melee_telegraph_duration + 1)
	TEST_ASSERT_EQUAL(old_target.health, old_target_health, "Switching targets during the telegraph must cancel the stale attack")
	TEST_ASSERT_EQUAL(goliath.target, new_target, "A cancelled telegraph must not restore the stale legacy target")

///Моб с контроллером не живёт в легаси-бакетах даже после урона
/datum/unit_test/ai_adapter_no_dual_ai/Run()
	var/mob/living/simple_animal/hostile/carp/fish = allocate(/mob/living/simple_animal/hostile/carp)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(fish)

	TEST_ASSERT_EQUAL(fish.AIStatus, AI_OFF, "A controller-owned mob must have legacy AIStatus AI_OFF")
	for(var/bucket_status in list(AI_ON, AI_IDLE, AI_OFF, AI_Z_OFF))
		TEST_ASSERT(!(fish in GLOB.simple_animals[bucket_status]), "A controller-owned mob must not be in any legacy bucket (status [bucket_status])")

	//урон не возвращает в легаси-бакеты (adjustHealth wake идёт контроллеру)
	fish.adjustBruteLoss(5)
	TEST_ASSERT_EQUAL(fish.AIStatus, AI_OFF, "Damage must not resurrect the legacy AI path")
	TEST_ASSERT(!(fish in GLOB.simple_animals[AI_ON]), "Damage must not put the mob back into legacy buckets")

	//возврат на легаси-путь: после смерти контроллера обычный toggle_ai заново зачисляет
	QDEL_NULL(fish.ai_controller)
	fish.toggle_ai(AI_ON)
	TEST_ASSERT_EQUAL(fish.AIStatus, AI_ON, "After the controller dies, toggle_ai must restore the legacy status")
	TEST_ASSERT(fish in GLOB.simple_animals[AI_ON], "After the controller dies, toggle_ai must re-enroll the mob into the AI_ON bucket")

	//повторная миграция снова вынимает из всех бакетов
	controller = new(fish)
	for(var/bucket_status in list(AI_ON, AI_IDLE, AI_OFF, AI_Z_OFF))
		TEST_ASSERT(!(fish in GLOB.simple_animals[bucket_status]), "Re-migration must unenroll the mob from every legacy bucket (status [bucket_status])")

	qdel(controller)

///The adapter must preserve both the initial and runtime legacy movement cadence.
///Легаси move_to_delay - в мировых тиках walk_to, поэтому в move-луп он попадает
///сконвертированным в децисекунды (AI_LEGACY_MOVE_DELAY_DS).
/datum/unit_test/ai_adapter_preserves_movement_delay/Run()
	var/mob/living/simple_animal/hostile/asteroid/goliath/goliath = allocate(/mob/living/simple_animal/hostile/asteroid/goliath, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/datum/ai_controller/hostile_adapter/controller = goliath.ai_controller

	TEST_ASSERT_NOTNULL(controller, "Sanity: the goliath must start with a hostile adapter")
	TEST_ASSERT_EQUAL(controller.movement_delay, AI_LEGACY_MOVE_DELAY_DS(goliath.move_to_delay), "The adapter must inherit the pawn's legacy movement delay in deciseconds")

	controller.set_ai_status(AI_STATUS_ON)
	controller.ai_movement.start_moving_towards(controller, prey, 1)
	var/datum/move_loop/loop = goliath.move_packet?.existing_loops[SSai_movement]
	TEST_ASSERT_NOTNULL(loop, "The hostile movement datum must create a movement loop")
	TEST_ASSERT_EQUAL(loop.delay, AI_LEGACY_MOVE_DELAY_DS(goliath.move_to_delay), "The movement loop must start with the legacy movement delay in deciseconds")

	goliath.move_to_delay = 4
	SEND_SIGNAL(loop, COMSIG_MOVELOOP_PREPROCESS_CHECK)
	TEST_ASSERT_EQUAL(controller.movement_delay, AI_LEGACY_MOVE_DELAY_DS(goliath.move_to_delay), "Runtime phase speed changes must update the adapter")
	TEST_ASSERT_EQUAL(loop.delay, AI_LEGACY_MOVE_DELAY_DS(goliath.move_to_delay), "Runtime phase speed changes must update the active movement loop")
	controller.ai_movement.stop_moving_towards(controller)

///The adapter must expose a simple animal's internal access card to JPS.
/datum/unit_test/ai_adapter_uses_access_card/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/controller = hunter.ai_controller
	var/obj/item/card/id/internal_id = allocate(/obj/item/card/id, hunter)
	internal_id.access = list(ACCESS_SECURITY)
	hunter.access_card = internal_id

	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, get_step(run_loc_floor_bottom_left, EAST))
	door.req_access = list(ACCESS_SECURITY)
	door.machine_stat &= ~NOPOWER
	door.locked = FALSE
	door.welded = FALSE
	door.density = TRUE

	TEST_ASSERT_NOTNULL(controller, "Sanity: the hostile must have an adapter")
	TEST_ASSERT_EQUAL(controller.get_access(), internal_id, "The adapter must return the pawn's internal ID")
	TEST_ASSERT(!door.CanAStarPass(null, WEST, hunter), "The secured airlock must reject a path without an ID")
	TEST_ASSERT(door.CanAStarPass(controller.get_access(), WEST, hunter), "The secured airlock must accept the adapter's ID")

///Blackboard-цель проходит через сабтиповые legacy-хуки, а не только var target.
/datum/unit_test/ai_adapter_target_hooks/Run()
	var/mob/living/simple_animal/hostile/unit_test_target_hooks/hunter = allocate(/mob/living/simple_animal/hostile/unit_test_target_hooks)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = hunter.ai_controller

	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	TEST_ASSERT_EQUAL(hunter.give_target_calls, 1, "Acquiring a target must invoke the pawn GiveTarget override")
	TEST_ASSERT_EQUAL(hunter.target, prey, "GiveTarget must receive the blackboard target")

	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(hunter.lose_target_calls, 1, "Clearing a target must invoke the pawn LoseTarget override")
	TEST_ASSERT_NULL(hunter.target, "LoseTarget must clear the legacy target")

	hunter.GiveTarget(prey)
	TEST_ASSERT_EQUAL(hunter.give_target_calls, 2, "A legacy GiveTarget call must invoke its override exactly once")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "A legacy GiveTarget call must update the blackboard")

	hunter.LoseTarget()
	TEST_ASSERT_EQUAL(hunter.lose_target_calls, 2, "A legacy LoseTarget call must invoke its override exactly once")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "A legacy LoseTarget call must clear the blackboard")

/// QDEL-driven blackboard cleanup must also clear the adapter's mirrored
/// legacy refs. The combat stress case otherwise leaves shotgun InteQ mobs
/// referenced by a surviving hostile's target/rapid-fire state for minutes.
/datum/unit_test/ai_adapter_qdeleted_target_clears_legacy_refs/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/syndicate/ranged/shotgun/space/prey = new(get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/hostile_adapter/controller = hunter.ai_controller

	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	hunter.rapid = 2
	hunter.start_rapid_fire_sequence(prey)
	var/rapid_timer_id = hunter.rapid_fire_timer_id
	TEST_ASSERT_EQUAL(hunter.target, prey, "Sanity: the legacy target must mirror the blackboard before qdel")
	TEST_ASSERT_EQUAL(hunter.rapid_fire_target, prey, "Sanity: the active volley must hold the same target")
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[rapid_timer_id], "Sanity: the active volley timer must exist")

	qdel(prey)
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "QDEL must remove the target from the controller blackboard")
	TEST_ASSERT_NULL(hunter.target, "QDEL must clear the hostile's mirrored legacy target")
	TEST_ASSERT_NULL(hunter.rapid_fire_target, "QDEL must clear the hostile's active volley target")
	TEST_ASSERT_NULL(hunter.rapid_fire_timer_id, "QDEL must clear the hostile's active volley timer id")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[rapid_timer_id], "QDEL must remove the active volley timer")

	var/mob/living/simple_animal/hostile/stale_volley_target = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/simple_animal/hostile/current_target = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, SOUTH))
	controller.set_blackboard_key(BB_AI_LAST_ATTACKER, stale_volley_target)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, current_target)
	hunter.start_rapid_fire_sequence(stale_volley_target)
	qdel(stale_volley_target)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], current_target, "Deleting an old volley target must preserve a newer controller target")
	TEST_ASSERT_EQUAL(hunter.target, current_target, "Deleting an old volley target must preserve the newer mirrored target")
	TEST_ASSERT_NULL(hunter.rapid_fire_target, "Deleting an old volley target must still cancel its volley")

///Удаление цели обязано снимать запись из /datum/ai_movement.moving_controllers.
///Датумы движения - бессмертные синглтоны из SSai_movement.movement_types, поэтому
///забытая запись держала удалённого моба всё GC-окно: это и была основная причина
///хардделов обезьян и слаймов на ксенобио-фермах (по одной внешней ссылке на моба).
/datum/unit_test/ai_movement_target_delete_releases_controller/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/carbon/monkey/prey = new(get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/controller = hunter.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: the hostile must start migrated")

	controller.set_movement_target(type, prey)
	var/datum/ai_movement/mover = controller.ai_movement
	TEST_ASSERT_NOTNULL(mover, "Sanity: a migrated controller must hold a movement datum instance")
	mover.start_moving_towards(controller, prey, 1)
	TEST_ASSERT_EQUAL(mover.moving_controllers[controller], prey, "Sanity: starting a move must record the target on the movement singleton")

	qdel(prey)

	TEST_ASSERT_NULL(mover.moving_controllers[controller], "Deleting the movement target must release the entry on the immortal movement singleton")
	TEST_ASSERT_NULL(controller.current_movement_target, "Deleting the movement target must clear the controller's own reference")

	qdel(controller) //чтобы контроллер не тикал в фоне до самого teardown

///Смена типа движения не должна оставлять запись в покинутом синглтоне - опрашивать
///её потом уже некому, снять тоже.
/datum/unit_test/ai_movement_type_switch_releases_old_singleton/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/controller = hunter.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: the hostile must start migrated")

	controller.set_movement_target(type, prey)
	var/datum/ai_movement/original_mover = controller.ai_movement
	original_mover.start_moving_towards(controller, prey, 1)
	TEST_ASSERT_EQUAL(original_mover.moving_controllers[controller], prey, "Sanity: starting a move must record the target on the movement singleton")

	controller.change_ai_movement_type(/datum/ai_movement/jps)

	TEST_ASSERT_NULL(original_mover.moving_controllers[controller], "Switching movement type must release the entry on the abandoned singleton")
	TEST_ASSERT(controller.ai_movement != original_mover, "Sanity: the switch must actually swap the movement datum")
	controller.stop_ai_movement()
	qdel(controller)

///Legacy toggle_ai calls pause and resume an attached controller.
/datum/unit_test/ai_adapter_legacy_toggle_bridge/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/controller = hunter.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: the hostile must start migrated")

	hunter.toggle_ai(AI_OFF)
	TEST_ASSERT(HAS_TRAIT(hunter, TRAIT_AI_PAUSED), "toggle_ai(AI_OFF) must pause the attached controller")
	TEST_ASSERT(!controller.able_to_run, "A legacy-paused controller must be unable to run")

	hunter.toggle_ai(AI_ON)
	TEST_ASSERT(!HAS_TRAIT(hunter, TRAIT_AI_PAUSED), "toggle_ai(AI_ON) must resume the attached controller")
	TEST_ASSERT(controller.able_to_run, "A resumed controller must be able to run")

	ADD_TRAIT(hunter, TRAIT_AI_PAUSED, "unit_test_pause")
	hunter.toggle_ai(AI_OFF)
	hunter.toggle_ai(AI_ON)
	TEST_ASSERT(HAS_TRAIT(hunter, TRAIT_AI_PAUSED), "toggle_ai(AI_ON) must not remove another pause source")
	TEST_ASSERT(!controller.able_to_run, "Another pause source must keep the controller stopped")
	REMOVE_TRAIT(hunter, TRAIT_AI_PAUSED, "unit_test_pause")

///Типы, изначально выключенные для сценария/игрока, не активируются адаптером.
/datum/unit_test/ai_adapter_respects_initial_ai_off/Run()
	var/mob/living/simple_animal/hostile/carp/shuttle_passive/passive_carp = allocate(/mob/living/simple_animal/hostile/carp/shuttle_passive)
	TEST_ASSERT_NULL(passive_carp.ai_controller, "An AI_OFF hostile must not receive a controller")
	TEST_ASSERT_EQUAL(passive_carp.AIStatus, AI_OFF, "An inactive hostile must remain AI_OFF")

///Старый сабтиповый код получает фактический статус контроллера.
/datum/unit_test/ai_adapter_effective_status/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/controller = hunter.ai_controller
	controller.set_ai_status(AI_STATUS_ON)
	TEST_ASSERT_EQUAL(hunter.get_effective_ai_status(), AI_ON, "An active controller must map to legacy AI_ON")
	controller.set_ai_status(AI_STATUS_IDLE)
	TEST_ASSERT_EQUAL(hunter.get_effective_ai_status(), AI_IDLE, "An idle controller must map to legacy AI_IDLE")
	controller.set_ai_status(AI_STATUS_OFF)
	TEST_ASSERT_EQUAL(hunter.get_effective_ai_status(), AI_OFF, "A stopped controller must map to legacy AI_OFF")

///Боль будит спящий адаптер и наводит на обидчика
/datum/unit_test/ai_adapter_pain_wakes_and_targets/Run()
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	victim.forceMove(run_loc_floor_bottom_left)
	register_fake_player(attacker, get_turf(attacker))

	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(victim)
	if(controller.ai_status != AI_STATUS_IDLE)
		controller.set_ai_status(AI_STATUS_IDLE)

	//центральная точка возмездия: с контроллером обязана идти в note_attacker
	victim.RetaliateAgainst(attacker)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_ATTACKER], attacker, "Retaliation must record the attacker in controller memory")
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Pain must wake the dormant adapter")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], attacker, "Pain must immediately focus the attacker")

	unregister_fake_player(attacker)
	qdel(controller)

///Чардж: сабтри взводит бросок в band
/datum/unit_test/ai_adapter_charge/Run()
	var/mob/living/simple_animal/hostile/bull = allocate(/mob/living/simple_animal/hostile)
	bull.charger = TRUE
	bull.charge_distance = 4
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	bull.forceMove(run_loc_floor_bottom_left)

	var/datum/ai_controller/hostile_adapter/brute_charger/controller = new(bull)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_planning_subtree/hostile_charge/horns = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_charge]
	horns.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_charge) in controller.current_behaviors, "A chargeable target in band must queue the charge behavior")

	//enter_charge гейтится гравитацией (на резервации её нет) - проверяем
	//легаси-обвязку броска напрямую
	bull.handle_charge_target(prey)
	TEST_ASSERT(bull.charge_state || !COOLDOWN_FINISHED(bull, charge_cooldown), "The legacy charge plumbing must arm the throw")

	controller.CancelActions()
	qdel(controller)

///Легаси move_to_delay задан в мировых тиках walk_to (0.5дс при FPS 20);
///move-лупы ждут децисекунды. Без конверсии каждый hostile ходит вдвое медленнее.
/datum/unit_test/ai_adapter_movement_delay_units/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	pawn.move_to_delay = 10 //легаси-голиаф: шаг каждые 10 тиков = 5дс
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	TEST_ASSERT_EQUAL(controller.movement_delay, 10 * world.tick_lag, "The adapter must convert move_to_delay world ticks into move-loop deciseconds")
	qdel(controller)

///Фазовые смены move_to_delay (боссы, ускорения) синхронизируются в тех же единицах
/datum/unit_test/ai_hybrid_move_delay_runtime_sync/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	//Тест проверяет ds-конверсию рантайм-смены move_to_delay; пол скорости погони
	//(со своим отдельным тестом) не должен маскировать её на быстрой фазе.
	pawn.ai_pursuit_speed_capped = FALSE
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	pawn.move_to_delay = 6
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	var/datum/ai_movement/hybrid/mover = controller.ai_movement
	var/datum/move_loop/loop = SSmove_manager.move_towards_legacy(pawn, prey, controller.movement_delay, subsystem = SSai_movement, extra_info = controller)
	TEST_ASSERT_NOTNULL(loop, "Sanity: the test must obtain a live move loop")
	pawn.move_to_delay = 2 //фаза ускорения
	mover.shared_pre_move_checks(loop)
	TEST_ASSERT_EQUAL(loop.delay, 2 * world.tick_lag, "A runtime move_to_delay change must sync into the loop in deciseconds")
	if(!QDELETED(loop))
		qdel(loop)
	qdel(controller)

///Обстрел одного бойца отряда поднимает его соседей: жертва передаёт обидчика
///союзникам той же фракции (легаси такое умел только retaliate-семейством)
/datum/unit_test/ai_adapter_retaliation_alerts_allies/Run()
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	register_fake_player(attacker, get_turf(attacker))

	var/datum/ai_controller/hostile_adapter/melee_chaser/victim_controller = new(victim)
	var/datum/ai_controller/hostile_adapter/melee_chaser/ally_controller = new(ally)
	if(ally_controller.ai_status != AI_STATUS_IDLE)
		ally_controller.set_ai_status(AI_STATUS_IDLE)

	GLOB.ai_recent_herd_alerts.Cut() //изоляция от коалесцирования прошлых тестов
	victim.RetaliateAgainst(attacker)

	TEST_ASSERT_EQUAL(victim_controller.blackboard[BB_AI_CURRENT_TARGET], attacker, "The victim must focus its attacker")
	TEST_ASSERT_NULL(ally_controller.blackboard[BB_AI_CURRENT_TARGET], "The ally must not be handed the live atom as a target")
	TEST_ASSERT_EQUAL(ally_controller.blackboard[BB_AI_CONTACT_TARGET], attacker, "The victim must report its attacker as a contact to the nearby same-faction ally")
	TEST_ASSERT_EQUAL(ally_controller.blackboard[BB_AI_STATE], AI_STATE_SEARCH, "The reported ally must go investigate the contact point")
	TEST_ASSERT_EQUAL(ally_controller.ai_status, AI_STATUS_ON, "The ally alert must wake the dormant ally")
	TEST_ASSERT(victim.next_ally_alert > world.time, "The ally alert must arm its throttle")

	unregister_fake_player(attacker)
	qdel(victim_controller)
	qdel(ally_controller)

// ===== Спящие легаси-атаки не должны вешать тикер поведений =====

///Стрелок со спящим OpenFire (модель иерофанта: сон в телеграфе)
/mob/living/simple_animal/hostile/unit_test_sleepy_shooter
	ranged = 1
	var/fire_started_at
	var/fire_finished_at

/mob/living/simple_animal/hostile/unit_test_sleepy_shooter/OpenFire(atom/A)
	fire_started_at = world.time
	sleep(5)
	if(QDELETED(src))
		return
	fire_finished_at = world.time

///Милишник со спящим AttackingTarget (модель иерофанта в упор)
/mob/living/simple_animal/hostile/unit_test_sleepy_brawler
	var/swing_started_at
	var/swing_finished_at

/mob/living/simple_animal/hostile/unit_test_sleepy_brawler/AttackingTarget()
	swing_started_at = world.time
	sleep(5)
	if(QDELETED(src))
		return TRUE
	swing_finished_at = world.time
	return TRUE

///Спящий легаси-OpenFire обязан детачиться от perform, а не тащить его в сон
/datum/unit_test/ai_sleepy_openfire_detaches/Run()
	var/mob/living/simple_animal/hostile/unit_test_sleepy_shooter/shooter = allocate(/mob/living/simple_animal/hostile/unit_test_sleepy_shooter, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/ai_controller/hostile_adapter/ranged_chaser/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	shooter.ranged_cooldown = 0

	var/datum/ai_behavior/ranged_skirmish/gun = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)
	var/verdict = gun.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, 9, 2)

	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "A clean shot at a visible target must succeed")
	TEST_ASSERT_NOTNULL(shooter.fire_started_at, "The legacy OpenFire must have started synchronously")
	TEST_ASSERT_NULL(shooter.fire_finished_at, "perform must return before the sleeping OpenFire finishes (async detach)")

	qdel(controller)

///Спящий легаси-AttackingTarget обязан детачиться от милишного perform
/datum/unit_test/ai_sleepy_melee_detaches/Run()
	var/mob/living/simple_animal/hostile/unit_test_sleepy_brawler/brawler = allocate(/mob/living/simple_animal/hostile/unit_test_sleepy_brawler, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(brawler)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_behavior/hostile_melee_attack/fist = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	var/verdict = fist.perform(0.5, controller, BB_AI_CURRENT_TARGET)

	TEST_ASSERT(verdict & AI_BEHAVIOR_DELAY, "An adjacent melee swing must apply its cadence cooldown")
	TEST_ASSERT_NOTNULL(brawler.swing_started_at, "The legacy AttackingTarget must have started synchronously")
	TEST_ASSERT_NULL(brawler.swing_finished_at, "perform must return before the sleeping AttackingTarget finishes (async detach)")

	qdel(controller)

// ===== Канал зова союзников: стены, радиус, эстафета =====
//
// Легаси summon_backup обходил oview(distance) - союзник обязан РЕАЛЬНО ВИДЕТЬ
// зовущего. Грид-канал стен не знает, поэтому LOS-гейт, потолок радиуса и
// запрет эстафеты закреплены тестами: без них один выстрел поднимал весь
// аванпост ("они с другого конца ломают шлюзы и бегут").

///Стена гасит зов: сосед по комнате слышит, сосед за стеной - нет
/datum/unit_test/ai_ally_alert_stops_at_walls/Run()
	var/turf/west = run_loc_floor_bottom_left
	var/turf/wall_turf = locate(west.x + 1, west.y, west.z)
	var/turf/ally_turf = locate(west.x + 2, west.y, west.z)
	var/mob/living/simple_animal/hostile/reporter = allocate(/mob/living/simple_animal/hostile, west)
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, ally_turf)
	var/mob/living/carbon/human/enemy = allocate(/mob/living/carbon/human, locate(west.x, west.y + 1, west.z))
	var/datum/ai_controller/hostile_adapter/melee_chaser/reporter_controller = new(reporter)
	var/datum/ai_controller/hostile_adapter/melee_chaser/ally_controller = new(ally)
	var/obj/effect/ai_unit_test_opaque_blocker/wall = allocate(/obj/effect/ai_unit_test_opaque_blocker, wall_turf)

	TEST_ASSERT_EQUAL(reporter_controller.report_contact_to_allies(enemy), 0, "Зов обязан гаснуть на стене: союзник за стеной зовущего не видит")
	TEST_ASSERT_NULL(ally_controller.blackboard[BB_AI_CONTACT_TARGET], "Союзник за стеной получил контакт сквозь стену")

	qdel(wall)
	TEST_ASSERT_EQUAL(reporter_controller.report_contact_to_allies(enemy), 1, "Без стены зов обязан дойти до союзника в прямой видимости")
	TEST_ASSERT_EQUAL(ally_controller.blackboard[BB_AI_CONTACT_TARGET], enemy, "Союзник в прямой видимости не получил контакт")

	qdel(reporter_controller)
	qdel(ally_controller)

///Потолок радиуса: зов на 15 тайлов (легаси summon_backup) клампится до экрана
/datum/unit_test/ai_ally_alert_range_is_capped/Run()
	//Дальний союзник стоит за AI_ALLY_ALERT_RANGE, то есть дальше, чем общая
	//5x5-зона тестов. За её границей турфы принадлежат чужим резервациям того же
	//резервного z (арены соседних AI-тестов ставят там глухие стены), и фреймворк
	//их не сбрасывает - LOS-санити ловил чужую стену и валил тест на случайном
	//наборе карт в каждом прогоне. Берём коридор в собственную резервацию и
	//отвечаем за каждый турф на луче сами.
	var/datum/turf_reservation/corridor = SSmapping.RequestBlockReservation(AI_ALLY_ALERT_RANGE + 4, 3)
	TEST_ASSERT_NOTNULL(corridor, "Санити: не удалось зарезервировать коридор под проверку радиуса")
	for(var/turf/tile as anything in corridor.reserved_turfs)
		tile.ChangeTurf(/turf/open/floor/plasteel)

	//середина коридора: enemy встаёт строкой выше и тоже остаётся внутри резервации
	var/turf/origin = locate(corridor.bottom_left_coords[1], corridor.bottom_left_coords[2] + 1, corridor.bottom_left_coords[3])
	var/mob/living/simple_animal/hostile/reporter = allocate(/mob/living/simple_animal/hostile, origin)
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, get_step(origin, EAST))
	var/mob/living/carbon/human/enemy = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 1, origin.z))
	var/datum/ai_controller/hostile_adapter/melee_chaser/reporter_controller = new(reporter)
	var/datum/ai_controller/hostile_adapter/melee_chaser/ally_controller = new(ally)

	var/turf/far_turf = locate(origin.x + AI_ALLY_ALERT_RANGE + 2, origin.y, origin.z)
	TEST_ASSERT_NOTNULL(far_turf, "Санити: коридор оказался короче дальнего союзника")
	ally.forceMove(far_turf)
	//иначе тест мог бы пройти по LOS-гейту вместо проверяемого потолка радиуса
	var/ray_blocker = ally_alert_ray_blocker(reporter, ally)
	TEST_ASSERT(can_see(reporter, ally, 15), "Санити: дальний союзник обязан быть в прямой видимости, иначе проверяется не радиус, а стена. Луч перекрыл: [ray_blocker ? ray_blocker : "ничего не найдено"]")
	TEST_ASSERT_EQUAL(reporter_controller.report_contact_to_allies(enemy, 15), 0, "Зов на легаси-радиус 15 обязан клампиться до AI_ALLY_ALERT_RANGE")
	TEST_ASSERT_NULL(ally_controller.blackboard[BB_AI_CONTACT_TARGET], "Союзник за потолком радиуса получил контакт")

	ally.forceMove(get_step(origin, EAST))
	TEST_ASSERT_EQUAL(reporter_controller.report_contact_to_allies(enemy, 15), 1, "Союзник внутри потолка радиуса обязан получить контакт")

	qdel(reporter_controller)
	qdel(ally_controller)
	//мобы уходят из коридора до его release: турфы вернутся в космос
	for(var/mob/living/occupant in list(reporter, ally, enemy))
		if(!QDELETED(occupant))
			occupant.forceMove(run_loc_floor_bottom_left)
	qdel(corridor)

///Кто именно перекрыл луч - без этого падение санити-проверки не отличить от бага
/datum/unit_test/ai_ally_alert_range_is_capped/proc/ally_alert_ray_blocker(atom/source, atom/target)
	var/turf/current = get_turf(source)
	var/turf/target_turf = get_turf(target)
	if(!current || !target_turf)
		return null
	//шагов не больше габарита карты: get_step_towards между z никуда не приведёт
	for(var/step in 1 to world.maxx)
		if(current == target_turf)
			return null
		current = get_step_towards(current, target_turf)
		if(!current || current == target_turf)
			return null
		if(current.opacity)
			return "турф [current.type] в [COORD(current)]"
		for(var/atom/thing as anything in current)
			if(thing.opacity)
				return "[thing.type] в [COORD(current)]"
	return null

///Эстафета запрещена: прибежавший на зов сам зов дальше не рассылает
/datum/unit_test/ai_ally_alert_does_not_relay/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/relay = allocate(/mob/living/simple_animal/hostile, origin)
	var/mob/living/simple_animal/hostile/neighbour = allocate(/mob/living/simple_animal/hostile, get_step(origin, EAST))
	var/mob/living/carbon/human/enemy = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 1, origin.z))
	var/datum/ai_controller/hostile_adapter/melee_chaser/relay_controller = new(relay)
	var/datum/ai_controller/hostile_adapter/melee_chaser/neighbour_controller = new(neighbour)

	TEST_ASSERT(relay_controller.receive_combat_contact(enemy, get_turf(enemy), AI_CONTACT_ALLY), "Санити: контакт от союзника обязан приниматься")
	TEST_ASSERT(relay_controller.blackboard[BB_AI_ALLY_RELAY_MUTED_UNTIL] > world.time, "Принятый зов союзника обязан взводить запрет эстафеты")
	TEST_ASSERT_EQUAL(relay_controller.report_contact_to_allies(enemy), 0, "Поднятый чужим зовом не имеет права рассылать зов дальше")
	TEST_ASSERT_NULL(neighbour_controller.blackboard[BB_AI_CONTACT_TARGET], "Эстафета зова прошла дальше по цепочке")

	//шум и личный контакт эстафету не глушат: это собственное восприятие моба
	var/datum/ai_controller/hostile_adapter/melee_chaser/own_controller = new(allocate(/mob/living/simple_animal/hostile, origin))
	own_controller.receive_combat_contact(enemy, get_turf(enemy), AI_CONTACT_NOISE)
	TEST_ASSERT(!(own_controller.blackboard[BB_AI_ALLY_RELAY_MUTED_UNTIL] > world.time), "Шум - это собственное восприятие, он не имеет права глушить зов моба")

	qdel(relay_controller)
	qdel(neighbour_controller)
	qdel(own_controller)
