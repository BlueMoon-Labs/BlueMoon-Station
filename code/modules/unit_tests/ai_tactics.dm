// ===== Тактические сабтри =====
//
// Проверяют кайт-band, бегство, дистанционную стрельбу и FSM
// (SEARCH к последней позиции без волхака, таймаут, промоушен переданной цели).

/obj/effect/ai_unit_test_opaque_blocker
	name = "opaque AI test blocker"
	opacity = TRUE
	anchored = TRUE

///Непроходимая тестовая преграда: для стен из мебели без атмос-побочек ChangeTurf
/obj/effect/ai_unit_test_dense_blocker
	name = "dense AI test blocker"
	density = TRUE
	anchored = TRUE

///Кайт-band: близко - шаг назад, далеко - догоняем.
///Пешка стоит НЕ в углу: западнее/южнее углового тайла лежит резервационный
///космос, куда наземный моб не пойдёт, а честный отход обязан строго
///увеличивать дистанцию (зажатый в углу кайтер теперь дерётся, не пляшет).
/datum/unit_test/ai_tactics_maintain_distance/Run()
	var/turf/mid_west = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	pawn.ranged = TRUE
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(mid_west, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	pawn.forceMove(mid_west)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.set_blackboard_key(BB_AI_MIN_DISTANCE, 2)
	controller.set_blackboard_key(BB_AI_MAX_DISTANCE, 2)

	var/datum/ai_planning_subtree/maintain_distance/keeper = GLOB.ai_subtrees[/datum/ai_planning_subtree/maintain_distance]

	//дистанция 1 < min 2: шаг назад (тайл строго дальше есть - запад свободен)
	keeper.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/step_away) in controller.current_behaviors, "Too-close target must queue step_away")
	controller.CancelActions()

	//дистанция 3 > max 2: догоняем, не выходя из общей тестовой резервации 5x5
	var/turf/far_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	prey.forceMove(far_turf)
	keeper.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/pursue_to_range) in controller.current_behaviors, "Too-far target must queue pursue_to_range")
	controller.CancelActions()

	qdel(controller)

///Бегство: цель рядом - убегаем, точка бегства дальше от угрозы
/datum/unit_test/ai_tactics_flee/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/turf/threat_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/threat = allocate(/mob/living/carbon/human, threat_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	pawn.forceMove(run_loc_floor_bottom_left)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, threat)

	var/datum/ai_planning_subtree/flee_target/coward = GLOB.ai_subtrees[/datum/ai_planning_subtree/flee_target]
	var/planning_verdict = coward.SelectBehaviors(controller, 0.5)

	TEST_ASSERT_EQUAL(planning_verdict, SUBTREE_RETURN_FINISH_PLANNING, "Fleeing must cancel further planning")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/run_away_from_target) in controller.current_behaviors, "A close threat must queue run_away_from_target")
	TEST_ASSERT_NOTNULL(controller.current_movement_target, "Fleeing must set a movement target")
	TEST_ASSERT(get_dist(threat, controller.current_movement_target) > get_dist(threat, pawn), "The flee destination must be farther from the threat than the pawn")

	controller.CancelActions()
	qdel(controller)

///Стрельба держит min/max дистанцию и взводит кулдаун моба
/datum/unit_test/ai_tactics_skirmish_band/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	pawn.ranged = TRUE
	pawn.projectiletype = /obj/item/projectile/beam/laser
	pawn.projectilesound = 'sound/weapons/laser.ogg'
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	pawn.forceMove(run_loc_floor_bottom_left)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_behavior/ranged_skirmish/gunner = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)

	//дистанция 1 < min 2: не стреляем
	var/close_result = gunner.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, 9, 2)
	TEST_ASSERT(close_result & AI_BEHAVIOR_FAILED, "Inside min range the skirmisher must not fire")
	TEST_ASSERT(pawn.ranged_cooldown <= world.time, "Sanity: no shot means no cooldown")

	//дистанция 5 в band: стреляем, кулдаун взведён
	var/turf/band_turf = locate(run_loc_floor_bottom_left.x + 5, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	prey.forceMove(band_turf)
	var/band_result = gunner.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, 9, 2)
	TEST_ASSERT(band_result & AI_BEHAVIOR_SUCCEEDED, "Inside the band the skirmisher must fire")
	TEST_ASSERT(pawn.ranged_cooldown > world.time, "Firing must arm the mob's ranged cooldown")

	qdel(controller)

///Союзник на линии огня вызывает боковое перестроение вместо холостого OpenFire.
/datum/unit_test/ai_tactics_safe_firing_lane/Run()
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, EAST))
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	TEST_ASSERT(shooter.faction_check_mob(ally), "Sanity: the blocker must be an ally")
	TEST_ASSERT(!shooter.check_friendly_fire, "Sanity: the legacy subtype has not opted into friendly-fire checks")
	TEST_ASSERT(shooter.CheckRangedFireLane(prey), "Controller ranged safety must protect allies without a legacy subtype flag")
	TEST_ASSERT_NULL(shooter.Shoot(prey), "The final projectile boundary must still reject an allied firing lane")
	var/datum/ai_planning_subtree/ranged_skirmish/skirmisher = GLOB.ai_subtrees[/datum/ai_planning_subtree/ranged_skirmish]
	var/verdict = skirmisher.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "An unsafe lane must stop the firing plan")
	TEST_ASSERT(controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/reposition_for_shot)], "An unsafe lane must queue a reposition")
	TEST_ASSERT(!controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)], "The shooter must not fire through its ally")

	qdel(controller)

///A corpse on the floor is below ordinary projectile aim, but a corpse held
///upright by a chair must be treated as cover when somebody stands behind it.
/datum/unit_test/ai_ranged_seated_corpse_blocks_lane/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/blocker_turf = get_step(start_turf, EAST)
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, start_turf)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/obj/structure/chair/chair = allocate(/obj/structure/chair, blocker_turf)
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, blocker_turf)
	corpse.death()
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start_turf.x + 3, start_turf.y, start_turf.z))
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	TEST_ASSERT(!chair.density, "Sanity: the chair itself must not be a dense firing-lane blocker")
	TEST_ASSERT(chair.buckle_mob(corpse, force = TRUE), "Sanity: the corpse must be buckled to the chair")
	TEST_ASSERT_EQUAL(corpse.buckled, chair, "Sanity: the corpse must remain seated in the firing lane")
	TEST_ASSERT(shooter.CheckRangedFireLane(prey), "A seated corpse must block a controller mob's shot at somebody behind it")
	TEST_ASSERT_NULL(shooter.Shoot(prey), "The final projectile boundary must reject a shot through a seated corpse")

	chair.unbuckle_mob(corpse, force = TRUE)
	TEST_ASSERT(!shooter.CheckRangedFireLane(prey), "The same corpse on the floor must no longer block ordinary projectile aim")
	var/obj/item/projectile/clear_shot = shooter.Shoot(prey)
	TEST_ASSERT_NOTNULL(clear_shot, "The shot must proceed after the corpse is removed from the chair")
	qdel(clear_shot)
	qdel(controller)

///can_see() skips the cardinal half of a diagonal projectile Move(). The ranged
///trace must notice that real first wall impact and choose a firing position.
/datum/unit_test/ai_ranged_diagonal_wall_lane/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/wall_turf = get_step(start_turf, NORTH)
	wall_turf.ChangeTurf(/turf/closed/wall)
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, start_turf)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start_turf.x + 2, start_turf.y + 2, start_turf.z))
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	TEST_ASSERT(can_see(shooter, prey, shooter.vision_range), "Sanity: legacy LOS must expose the diagonal corner bug")
	TEST_ASSERT(shooter.CheckRangedFireLane(prey), "The projectile-aligned trace must find the cardinal wall entered by a diagonal shot")
	TEST_ASSERT_NULL(shooter.Shoot(prey), "A controller must not create a projectile which can only hit the corner wall")
	var/datum/ai_planning_subtree/ranged_skirmish/skirmisher = GLOB.ai_subtrees[/datum/ai_planning_subtree/ranged_skirmish]
	var/verdict = skirmisher.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "A blocked diagonal lane must stop the firing plan")
	TEST_ASSERT(controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/reposition_for_shot)], "A blocked diagonal lane must queue a firing-position change")
	TEST_ASSERT(!controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)], "The shooter must not fire into the corner wall")
	wall_turf = wall_turf.ChangeTurf(/turf/open/floor/plating)
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, wall_turf)
	TEST_ASSERT(shooter.CheckRangedFireLane(prey), "The projectile-aligned trace must protect an ally on the cardinal half of a diagonal shot")
	ally.forceMove(get_step(start_turf, WEST))
	allocate(/obj/structure/window/fulltile, wall_turf)
	TEST_ASSERT(!shooter.CheckRangedFireLane(prey), "Projectile pass flags must keep a laser's valid diagonal shot through glass")

	qdel(controller)

///The Forgotten Ship Nanotrasen squad must recheck every shot in a rapid volley.
/datum/unit_test/ai_nanotrasen_rechecks_friendly_fire/Run()
	var/mob/living/simple_animal/hostile/nanotrasen/ranged/assault/shooter = allocate(/mob/living/simple_animal/hostile/nanotrasen/ranged/assault, run_loc_floor_bottom_left)
	shooter.casingtype = null
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/mob/living/simple_animal/hostile/nanotrasen/ally = allocate(/mob/living/simple_animal/hostile/nanotrasen, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))

	TEST_ASSERT(shooter.check_friendly_fire, "Nanotrasen ranged mobs must protect their own squad")
	TEST_ASSERT(shooter.faction_check_mob(ally), "Sanity: both Nanotrasen mobs must share a faction")
	TEST_ASSERT_NULL(shooter.Shoot(prey), "A queued shot must be cancelled when an ally enters its lane")

	ally.forceMove(get_step(run_loc_floor_bottom_left, NORTH))
	var/obj/item/projectile/projectile = shooter.Shoot(prey)
	TEST_ASSERT_NOTNULL(projectile, "The shot must proceed after the ally clears the lane")
	qdel(projectile)

///A retained target is not permission to shoot after it moves behind a wall.
/datum/unit_test/ai_ranged_rechecks_line_of_sight/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/syndicate/ranged/space/stormtrooper/shooter = allocate(/mob/living/simple_animal/hostile/syndicate/ranged/space/stormtrooper, start_turf)
	shooter.casingtype = null
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start_turf.x + 3, start_turf.y, start_turf.z))
	var/obj/effect/ai_unit_test_opaque_blocker/wall = allocate(/obj/effect/ai_unit_test_opaque_blocker, get_step(start_turf, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	TEST_ASSERT(!can_see(shooter, prey, shooter.vision_range), "Sanity: the opaque fixture must block the target")
	TEST_ASSERT_NULL(shooter.Shoot(prey), "A queued rapid shot must stop when the target goes behind a wall")
	var/datum/ai_behavior/ranged_skirmish/gunner = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)
	var/result = gunner.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, 9, 2)
	TEST_ASSERT(result & AI_BEHAVIOR_FAILED, "The ranged behavior must reject a cached target without current line of sight")
	TEST_ASSERT(shooter.ranged_cooldown <= world.time, "A rejected wall shot must not arm the weapon cooldown")

	qdel(wall)
	qdel(controller)

///FSM: холодное обнаружение проходит через ALERT, потеря цели ведёт к
///последней позиции, таймаут чистит память
/datum/unit_test/ai_tactics_fsm_search/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/turf/last_seen = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y + 3, run_loc_floor_bottom_left.z)

	var/datum/ai_planning_subtree/hostile_fsm/brain = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]

	//холодное обнаружение: читаемая ALERT-пауза, затем ENGAGE
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, last_seen)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	var/alert_verdict = brain.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ALERT, "A cold acquisition must pass through a readable ALERT pause")
	TEST_ASSERT_EQUAL(alert_verdict, SUBTREE_RETURN_FINISH_PLANNING, "ALERT must cut combat planning for its duration")
	controller.blackboard[BB_AI_STATE_ENTERED_AT] = world.time - AI_ALERT_REACTION_TIME - 1
	brain.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ENGAGE, "After the pause a valid target must put the FSM into ENGAGE")
	controller.CancelActions()

	//повторное обнаружение из боя не тормозит: нас уже били
	controller.set_blackboard_key(BB_AI_LAST_ATTACKER, prey)
	controller.blackboard[BB_AI_STATE] = AI_STATE_IDLE
	brain.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ENGAGE, "Acquiring the mob's own attacker must skip the ALERT pause")
	controller.clear_blackboard_key(BB_AI_LAST_ATTACKER)

	//потеря цели: идём к последней известной позиции
	controller.set_blackboard_key(BB_AI_LAST_KNOWN_POS, last_seen)
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
	var/verdict = brain.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_SEARCH, "Losing the target must move the FSM into SEARCH")
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "SEARCH must cut further planning")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/travel_towards) in controller.current_behaviors, "SEARCH must travel to the last known position")
	TEST_ASSERT(controller.blackboard[BB_AI_SEARCH_UNTIL] > world.time, "SEARCH must have a deadline")
	controller.CancelActions()

	//таймаут: память вычищена, покой
	controller.blackboard[BB_AI_SEARCH_UNTIL] = world.time - 1
	brain.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_IDLE, "Search timeout must return the FSM to IDLE")
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_LAST_KNOWN_POS], "Search timeout must clear the remembered position")

	qdel(controller)

///SEARCH must keep clearing a powered door on the route after LOS and the
///combat target have already been lost.
/datum/unit_test/ai_tactics_search_handles_inaccessible_door/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/door_turf = get_step(start_turf, EAST)
	var/turf/last_seen = locate(start_turf.x + 2, start_turf.y, start_turf.z)
	var/mob/living/simple_animal/hostile/syndicate/space/stormtrooper/pawn = allocate(/mob/living/simple_animal/hostile/syndicate/space/stormtrooper, start_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, door_turf)
	door.req_access = list(ACCESS_SECURITY)
	door.machine_stat &= ~NOPOWER
	door.locked = FALSE
	door.welded = FALSE
	door.density = TRUE

	controller.set_blackboard_key(BB_AI_LAST_KNOWN_POS, last_seen)
	controller.blackboard[BB_AI_STATE] = AI_STATE_SEARCH
	controller.blackboard[BB_AI_SEARCH_UNTIL] = world.time + AI_DEFAULT_SEARCH_TIME
	var/datum/ai_planning_subtree/hostile_fsm/brain = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]
	brain.SelectBehaviors(controller, 0.5)

	var/datum/ai_behavior/attack_obstructions/search/door_handler = GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions/search)
	TEST_ASSERT(door_handler in controller.current_behaviors, "SEARCH must queue its own obstacle handler for the remembered route")
	var/integrity_before = door.obj_integrity
	door_handler.perform(0.5, controller, BB_AI_LAST_KNOWN_POS)
	TEST_ASSERT(door.obj_integrity < integrity_before, "The exact Stormtrooper from the report must damage an inaccessible powered door while searching")

	qdel(controller)

///Доклад союзника даёт контакт и SEARCH, а не живую цель: захват - только
///собственным восприятием через find_potential_targets
/datum/unit_test/ai_tactics_fsm_contact_report/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/reported = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)

	controller.receive_combat_contact(reported, get_turf(reported), AI_CONTACT_ALLY)

	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "A reported contact must not become the current target by itself")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CONTACT_TARGET], reported, "The report must remember who to look for")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_SEARCH, "The report must send the mob investigating")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CONTACT_SOURCE], AI_CONTACT_ALLY, "The report must record its information source")

	//занятый боем получатель не принимает доклад: у него своё восприятие
	var/mob/living/carbon/human/own_prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, own_prey)
	var/accepted = controller.receive_combat_contact(reported, run_loc_floor_bottom_left, AI_CONTACT_ALLY)
	TEST_ASSERT(!accepted, "A mob in combat must reject ally reports")

	qdel(controller)

// ===== Threat-aware tactical positioning (дальники) =====

///score_fire_tile: чистая линия огня доминирует, угроза вплотную штрафуется
/datum/unit_test/ai_tactics_score_fire_tile/Run()
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)

	var/turf/clear_tile = run_loc_floor_bottom_left
	var/list/no_threats = list()
	var/clear_score = ai_score_fire_tile(shooter, clear_tile, prey, no_threats, 2, 6)

	//та же геометрия, но угроза вплотную к тайлу режет счёт
	var/turf/adjacent_turf = get_step(clear_tile, NORTH)
	var/mob/living/carbon/human/flanker = allocate(/mob/living/carbon/human, adjacent_turf)
	var/list/one_threat = list(flanker)
	var/threatened_score = ai_score_fire_tile(shooter, clear_tile, prey, one_threat, 2, 6)

	TEST_ASSERT(threatened_score < clear_score, "An adjacent threat must lower the fire-tile score")
	TEST_ASSERT(clear_score >= AI_FIRE_TILE_LANE_BONUS, "A clear lane must contribute the lane bonus")
	qdel(prey)
	qdel(flanker)
	qdel(shooter)

///Пробиваемое укрытие (мешки): стрелять сквозь него можно. Вплотную к своему
///укрытию линия чистая (пуля проходит гарантированно), издали - COVER, но не
///BLOCKED. Глухая стена на том же тайле - жёсткий блок (контраст).
/datum/unit_test/ai_ranged_fires_through_cover/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, start_turf)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/turf/cover_turf = locate(start_turf.x + 2, start_turf.y, start_turf.z)
	var/turf/adjacent_origin = locate(start_turf.x + 1, start_turf.y, start_turf.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start_turf.x + 4, start_turf.y, start_turf.z))
	var/obj/structure/barricade/sandbags/cover = allocate(/obj/structure/barricade/sandbags, cover_turf)

	TEST_ASSERT(cover.density, "Sanity: sandbags are dense cover")
	TEST_ASSERT(cover.is_ranged_ai_penetrable_cover(), "Sandbags must be classed as penetrable cover")

	//вплотную к своему укрытию: гарантированный выстрел поверх = чистая линия
	TEST_ASSERT_EQUAL(shooter.CheckRangedFireLaneStateFrom(prey, adjacent_origin), AI_FIRE_LANE_CLEAR, "Standing right behind its own cover the shooter has a clear lane")
	//издали то же укрытие даёт лишь частичный проход: COVER, но стрелять можно
	TEST_ASSERT_EQUAL(shooter.CheckRangedFireLaneStateFrom(prey, start_turf), AI_FIRE_LANE_COVER, "Distant cover downgrades the lane to COVER, not a hard block")
	TEST_ASSERT(!shooter.CheckRangedFireLaneFrom(prey, start_turf), "Penetrable cover in the lane must not forbid firing")

	//та же геометрия, но глухая стена = жёсткий блок
	qdel(cover)
	cover_turf.ChangeTurf(/turf/closed/wall)
	TEST_ASSERT_EQUAL(shooter.CheckRangedFireLaneStateFrom(prey, start_turf), AI_FIRE_LANE_BLOCKED, "A real wall in the lane is a hard block")
	TEST_ASSERT(shooter.CheckRangedFireLaneFrom(prey, start_turf), "A wall must forbid firing")
	cover_turf.ChangeTurf(/turf/open/floor/plating)

	qdel(prey)
	qdel(shooter)

///Регресс: лазер-дрон у рефлектора снова стреляет. Рефлектор зеркалит луч - для
///beam-снаряда это не тупик, линия не должна читаться как жёсткий блок. Пулю же
///рефлектор не отражает, для неё он остаётся блоком (контраст типозависимости).
/datum/unit_test/ai_ranged_fires_at_reflector/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, start_turf)
	shooter.ranged = TRUE
	var/turf/reflector_turf = locate(start_turf.x + 2, start_turf.y, start_turf.z)
	var/obj/structure/reflector/single/mirror = allocate(/obj/structure/reflector/single, reflector_turf)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start_turf.x + 4, start_turf.y, start_turf.z))

	TEST_ASSERT(mirror.density, "Sanity: a built reflector is dense")

	//beam-стрелок: луч зеркалится, рефлектор не блокирует линию огня
	shooter.projectiletype = /obj/item/projectile/beam/laser
	shooter.casingtype = null
	TEST_ASSERT_NOTEQUAL(shooter.CheckRangedFireLaneStateFrom(prey, start_turf), AI_FIRE_LANE_BLOCKED, "A reflector must not hard-block a beam shooter's fire lane")
	TEST_ASSERT(!shooter.CheckRangedFireLaneFrom(prey, start_turf), "A reflector in the lane must not forbid a beam drone from firing")

	//пуле-стрелок: рефлектор пулю не отражает, значит остаётся жёстким блоком
	shooter.projectiletype = null
	shooter.casingtype = /obj/item/ammo_casing/c46x30mm
	TEST_ASSERT_EQUAL(shooter.CheckRangedFireLaneStateFrom(prey, start_turf), AI_FIRE_LANE_BLOCKED, "A reflector still hard-blocks a non-reflectable bullet lane")

	qdel(prey)
	qdel(mirror)
	qdel(shooter)

///Разнос стрелков: свой стрелок вплотную к огневому тайлу режет его счёт ровно
///на один штраф спейсинга (союзник стоит рядом в обоих расчётах, меняется только
///список allies - изолирует эффект от бонуса плотного соседа).
/datum/unit_test/ai_tactics_ally_spacing/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, start_turf)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start_turf.x + 3, start_turf.y, start_turf.z))
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, get_step(start_turf, NORTH))
	var/list/no_threats = list()

	var/score_ignoring_ally = ai_score_fire_tile(shooter, start_turf, prey, no_threats, 0, 0, list())
	var/score_with_ally = ai_score_fire_tile(shooter, start_turf, prey, no_threats, 0, 0, list(ally))

	TEST_ASSERT(score_with_ally < score_ignoring_ally, "An allied shooter next to the tile must lower its fire score (spacing)")
	TEST_ASSERT_EQUAL(score_ignoring_ally - score_with_ally, AI_FIRE_TILE_ALLY_CROWD_PENALTY, "One adjacent ally must cost exactly one spacing penalty")

	qdel(prey)
	qdel(ally)
	qdel(shooter)

///Свои AI-мобы одной фракции не толкаются и не меняются местами: шаг на союзника
///честно проваливается (его ведёт очередь is_mob_only_blocked_step), вместо
///бесконечного обмена тайлами - "два стрелка спорят за место, выталкивая друг друга".
/datum/unit_test/ai_tactics_allies_do_not_shove/Run()
	var/turf/tile_a = run_loc_floor_bottom_left
	var/turf/tile_b = get_step(tile_a, EAST)
	//резервный z без гравитации не даёт ходить (нет опоры) - иначе шаг провалился
	//бы и без гейта, и тест ничего бы не проверял
	var/area/test_area = tile_a.loc
	var/saved_gravity = test_area.has_gravity
	test_area.has_gravity = TRUE
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, tile_a)
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, tile_b)
	var/datum/ai_controller/unit_test_hunter/shooter_ctrl = new(shooter)
	var/datum/ai_controller/unit_test_hunter/ally_ctrl = new(ally)

	TEST_ASSERT(shooter.ai_controller && !shooter.client, "Sanity: the shooter is AI-controlled")
	TEST_ASSERT(ally.ai_controller && !ally.client, "Sanity: the ally is AI-controlled")
	TEST_ASSERT(shooter.faction_check_mob(ally), "Sanity: both mobs share a faction")
	TEST_ASSERT_EQUAL(shooter.a_intent, INTENT_HELP, "Sanity: the default help intent is what makes two mobs swap places")
	TEST_ASSERT(ally.density, "Sanity: the ally physically blocks the tile")

	//шаг на союзника: без гейта они бы поменялись местами (INTENT_HELP swap)
	shooter.Move(tile_b, EAST)
	TEST_ASSERT_EQUAL(get_turf(ally), tile_b, "An AI mob must not shove/swap an allied AI mob off its tile")
	TEST_ASSERT_EQUAL(get_turf(shooter), tile_a, "The blocked AI mob must hold its tile instead of trading places")

	test_area.has_gravity = saved_gravity
	qdel(shooter_ctrl)
	qdel(ally_ctrl)

///nearest_threat_distance берёт минимальную дистанцию из списка
/datum/unit_test/ai_tactics_nearest_threat/Run()
	var/turf/tile = run_loc_floor_bottom_left
	var/mob/living/carbon/human/near = allocate(/mob/living/carbon/human, get_step(tile, EAST))
	var/mob/living/carbon/human/far = allocate(/mob/living/carbon/human, locate(tile.x + 4, tile.y, tile.z))
	TEST_ASSERT_EQUAL(ai_nearest_threat_distance(tile, list(near, far)), 1, "Nearest distance must be the closest threat")
	TEST_ASSERT_EQUAL(ai_nearest_threat_distance(tile, list()), INFINITY, "No threats means infinite distance")
	qdel(near)
	qdel(far)

///best_retreat_tile: при двух угрозах уходим от ближайшей, не к ней
/datum/unit_test/ai_tactics_retreat_from_nearest/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	pawn.ranged = TRUE
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/turf/centre = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	pawn.forceMove(centre)
	//угроза с востока вплотную, вторая - дальше с запада
	var/mob/living/carbon/human/east_threat = allocate(/mob/living/carbon/human, get_step(centre, EAST))
	var/mob/living/carbon/human/west_threat = allocate(/mob/living/carbon/human, locate(centre.x - 2, centre.y, centre.z))

	var/turf/retreat = controller.best_retreat_tile(list(east_threat, west_threat))
	TEST_ASSERT_NOTNULL(retreat, "A retreat tile must be found in open space")
	TEST_ASSERT(get_dist(retreat, east_threat) >= get_dist(centre, east_threat), "Retreat must not step toward the nearest threat")

	qdel(east_threat)
	qdel(west_threat)
	qdel(controller)

///Кайт при двух угрозах: шаг назад не приближает к ближайшему фланкеру
/datum/unit_test/ai_tactics_kite_two_targets/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	pawn.ranged = TRUE
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/turf/centre = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	pawn.forceMove(centre)
	//цель по скореру - западная (дальше), но вплотную зажимает восточная
	var/mob/living/carbon/human/west_target = allocate(/mob/living/carbon/human, locate(centre.x - 2, centre.y, centre.z))
	var/mob/living/carbon/human/east_flanker = allocate(/mob/living/carbon/human, get_step(centre, EAST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, west_target)
	controller.set_blackboard_key(BB_AI_MIN_DISTANCE, 4)
	controller.set_blackboard_key(BB_AI_MAX_DISTANCE, 6)

	//sanity: обе угрозы видны хелперу восприятия
	var/list/threats = controller.get_nearby_threats()
	TEST_ASSERT(east_flanker in threats, "The adjacent flanker must be seen as a threat")
	TEST_ASSERT(west_target in threats, "The current target must be seen as a threat")

	var/datum/ai_planning_subtree/maintain_distance/keeper = GLOB.ai_subtrees[/datum/ai_planning_subtree/maintain_distance]
	keeper.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_NOTNULL(controller.current_movement_target, "Being flanked must queue a retreat step")
	var/turf/retreat = controller.current_movement_target
	TEST_ASSERT(get_dist(retreat, east_flanker) >= get_dist(centre, east_flanker), "Kiting must not step toward the nearest flanker")

	controller.CancelActions()
	qdel(west_target)
	qdel(east_flanker)
	qdel(controller)

///Зажатый дальник с чистой линией стреляет в упор вместо холостого мили
/datum/unit_test/ai_tactics_pinned_point_blank/Run()
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	shooter.projectilesound = 'sound/weapons/laser.ogg'
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_behavior/point_blank_shot/blaster = GET_AI_BEHAVIOR(/datum/ai_behavior/point_blank_shot)
	TEST_ASSERT(shooter.ranged_cooldown <= world.time, "Sanity: weapon starts ready")
	var/result = blaster.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(result & AI_BEHAVIOR_SUCCEEDED, "A pinned shooter must act, not fail")
	TEST_ASSERT(shooter.ranged_cooldown > world.time, "A pinned shooter with a clear point-blank lane must fire (bypass min range)")

	//оружие остыло: огрызок в мили идёт легаси-каденсом NPC-пула, не ретрай-тиком
	var/melee_result = blaster.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(melee_result & AI_BEHAVIOR_SUCCEEDED, "A pinned shooter with a cooling weapon must claw back")
	TEST_ASSERT(blaster.get_cooldown(controller) > 0.4 SECONDS, "The melee last resort must pace at the NPC-pool cadence, not the 0.4s retry tick")

	qdel(prey)
	qdel(controller)

///Зажатый со всех сторон дальник планирует прорыв и урон, а не встаёт в мили
/datum/unit_test/ai_tactics_break_away_subtree/Run()
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile)
	shooter.ranged = TRUE
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	var/turf/centre = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	shooter.forceMove(centre)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(centre, EAST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_planning_subtree/hostile_break_away/breaker = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_break_away]
	var/verdict = breaker.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "A pinned ranged mob must commit to break-away planning")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/point_blank_shot) in controller.current_behaviors, "A pinned ranged mob must guarantee point-blank damage, not weak melee first")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_break_away) in controller.current_behaviors, "A pinned ranged mob with open space must plan an escape route")

	controller.CancelActions()
	qdel(prey)
	qdel(controller)

///Регресс: движущееся MOVE_AND_PERFORM-поведение (мили-подход, pursue) на
///чистом AI_BEHAVIOR_INSTANT не должно съедать весь process() и морить голодом
///поведения дальше по списку. До фикса файндер милишника в погоне не перформился
///вовсе: последняя подтверждённая позиция протухала на всю погоню, разжалование
///при потере LOS не наступало до самой адьяценси, перевыбор целей был мёртв.
/datum/unit_test/ai_moving_behavior_does_not_starve_queue/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	//воспроизводим злой порядок: мили-подход стоит ПЕРВЫМ в current_behaviors
	controller.queue_behavior(/datum/ai_behavior/hostile_melee_attack, BB_AI_CURRENT_TARGET)
	controller.queue_behavior(/datum/ai_behavior/find_potential_targets, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/datum/ai_behavior/melee = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	var/datum/ai_behavior/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	TEST_ASSERT_EQUAL(controller.current_behaviors[1], melee, "Sanity: the approach behavior must sit first in the queue")
	TEST_ASSERT(get_dist(pawn, prey) > 1, "Sanity: the target must be out of melee reach so the approach stays in transit")
	controller.behavior_cooldowns[finder] = 0
	controller.clear_blackboard_key(BB_AI_LAST_KNOWN_POS)

	controller.process(0.5)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_KNOWN_POS], prey_turf, "A moving approach must not starve the target finder: perception has to keep confirming the victim's position")

	controller.CancelActions()
	qdel(controller)

///Регресс репорта "имп бежит в стену вплотную к жертве и не атакует": в тупике
///ни один сосед не дальше от цели, чем текущий тайл. best_retreat_tile обязан
///признать зажим (null), чтобы step_away провалил setup и hostile_break_away
///спланировал урон в упор - иначе моб вечно пляшет у стены без единой атаки.
/datum/unit_test/ai_cornered_kiter_fights_back/Run()
	//тупик 1x1: стены с N/S/W и по диагоналям NW/SW, выход на восток перекрыт
	//целью; NE/SE открыты, но равноудалены от неё (дистанция 1, как и мы)
	var/turf/nook = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/list/wall_turfs = list(
		get_step(nook, NORTH), get_step(nook, SOUTH), get_step(nook, WEST),
		get_step(nook, NORTHWEST), get_step(nook, SOUTHWEST))
	var/list/saved_types = list()
	for(var/turf/wall_turf as anything in wall_turfs)
		saved_types[wall_turf] = wall_turf.type
		wall_turf.ChangeTurf(/turf/closed/wall)

	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, nook)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	shooter.projectilesound = 'sound/weapons/laser.ogg'
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(nook, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.set_blackboard_key(BB_AI_MIN_DISTANCE, 5)
	controller.set_blackboard_key(BB_AI_MAX_DISTANCE, 7)

	TEST_ASSERT_NULL(controller.best_retreat_tile(controller.get_nearby_threats()), "No dead-end neighbour is farther from the threat: the retreat tile must be null")

	//полный порядок профиля ranged_skirmisher: кайт планируется раньше прорыва
	var/datum/ai_planning_subtree/maintain_distance/keeper = GLOB.ai_subtrees[/datum/ai_planning_subtree/maintain_distance]
	var/datum/ai_planning_subtree/hostile_break_away/breaker = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_break_away]
	keeper.SelectBehaviors(controller, 0.5)
	breaker.SelectBehaviors(controller, 0.5)

	TEST_ASSERT(!controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/step_away)], "A doomed wall-shuffle must not pass for a retreat")
	TEST_ASSERT(controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/point_blank_shot)], "A cornered skirmisher must plan point-blank damage instead of running into the wall")

	//и реально стреляет в упор, а не стоит
	var/datum/ai_behavior/point_blank_shot/blaster = GET_AI_BEHAVIOR(/datum/ai_behavior/point_blank_shot)
	var/result = blaster.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(result & AI_BEHAVIOR_SUCCEEDED, "The cornered shooter must attack point-blank")

	controller.CancelActions()
	for(var/turf/wall_turf as anything in saved_types)
		wall_turf.ChangeTurf(saved_types[wall_turf])
	qdel(prey)
	qdel(controller)

///Коридор: с чистой линией из текущего тайла дальник держит позицию, не дёргается
/datum/unit_test/ai_tactics_corridor_hold/Run()
	//строим короткий горизонтальный коридор: стены сверху, снизу и за спиной
	//стрелка. Тыловая стена обязательна явно: раньше её роль играл космос за
	//краем резервации, но с кордоном арены тайл позади - проходимый пол с
	//бонусом укрытия от кольца, и репозиционер честно отступал бы на него.
	var/turf/floor = run_loc_floor_bottom_left
	var/turf/wall_north = get_step(floor, NORTH)
	var/turf/wall_south = get_step(floor, SOUTH)
	var/turf/wall_west = get_step(floor, WEST)
	wall_north.ChangeTurf(/turf/closed/wall)
	wall_south.ChangeTurf(/turf/closed/wall)
	wall_west.ChangeTurf(/turf/closed/wall)
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, floor)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(floor.x + 4, floor.y, floor.z))
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_behavior/reposition_for_shot/mover = GET_AI_BEHAVIOR(/datum/ai_behavior/reposition_for_shot)
	var/result = mover.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(get_turf(shooter), floor, "With a clear lane down the corridor the shooter must hold its tile, not jitter")
	TEST_ASSERT(result & AI_BEHAVIOR_SUCCEEDED, "Holding a good firing tile is a successful reposition")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_SAFE_FIRE_POSITION], floor, "The held tile must be committed as the safe firing position")

	wall_north.ChangeTurf(/turf/open/floor/plating)
	wall_south.ChangeTurf(/turf/open/floor/plating)
	qdel(prey)
	qdel(controller)

///Скрывшаяся за стеной цель: дальник поджидает на прикрывающей позиции
///(SEARCH-фаза удержания), вместо слепого сближения
/datum/unit_test/ai_tactics_covering_hold/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, start_turf)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start_turf.x + 3, start_turf.y, start_turf.z))
	var/obj/effect/ai_unit_test_opaque_blocker/wall = allocate(/obj/effect/ai_unit_test_opaque_blocker, get_step(start_turf, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_LAST_KNOWN_POS, get_turf(prey))
	controller.blackboard[BB_AI_STATE] = AI_STATE_ENGAGE //цель только что разжалована в контакт

	TEST_ASSERT(!can_see(shooter, prey, shooter.vision_range), "Sanity: the wall must hide the target")
	var/datum/ai_planning_subtree/hostile_fsm/brain = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]
	var/verdict = brain.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_SEARCH, "Losing sight must put the ranged mob into SEARCH")
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "A blind ranged mob must commit to holding, not chase blindly")
	TEST_ASSERT(controller.blackboard[BB_AI_HOLD_UNTIL] > world.time, "Entering SEARCH as a ranged mob must arm the covering-hold window")

	controller.CancelActions()
	qdel(wall)
	qdel(prey)
	qdel(controller)

///Память удержания вычищается вместе с боевой памятью
/datum/unit_test/ai_tactics_hold_memory_cleared/Run()
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.blackboard[BB_AI_HOLD_UNTIL] = world.time + AI_RANGED_HOLD_TIME
	controller.clear_engagement_memory()
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_HOLD_UNTIL], "clear_engagement_memory must drop the hold deadline")
	qdel(controller)

// ===== P0-регрессии: чардж, обиды, отступление =====

///Двойной замах чарджа невозможен: прелюдия взводит кулдаун и гард-таймер,
///а сорванная за прелюдию цель не бросает моба в пустоту
/datum/unit_test/ai_charge_windup_guard/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/brute = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start_turf.x + 2, start_turf.y, start_turf.z))
	brute.charger = TRUE
	//резервный z без гравитации: чарджу нужна опора
	var/turf/brute_turf = get_turf(brute)
	var/area/test_area = brute_turf.loc
	var/saved_gravity = test_area.has_gravity
	test_area.has_gravity = TRUE

	TEST_ASSERT(brute.enter_charge(prey), "Sanity: the first windup must start")
	TEST_ASSERT_NOTNULL(brute.charge_windup_timer, "The windup must arm its guard timer")
	TEST_ASSERT(!COOLDOWN_FINISHED(brute, charge_cooldown), "The windup must arm the charge cooldown immediately")
	TEST_ASSERT(!brute.enter_charge(prey), "A second windup during the first must be rejected")

	//цель ушла из зоны броска за прелюдию: перевалидация отменяет бросок
	prey.forceMove(locate(start_turf.x + brute.charge_distance + 5, start_turf.y, start_turf.z))
	deltimer(brute.charge_windup_timer)
	brute.charge_windup_timer = null
	brute.handle_charge_target(prey)
	TEST_ASSERT(!brute.charge_state, "An invalidated target must abort the throw after the windup")

	test_area.has_gravity = saved_gravity

///Протухшая обида не даёт бонуса скоринга и вычищается из списка
/datum/unit_test/ai_grudge_expiry_scoring/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/mob/living/carbon/human/old_foe = allocate(/mob/living/carbon/human, locate(start_turf.x + 7, start_turf.y, start_turf.z))
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(start_turf, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/datum/target_scorer/scorer = GET_TARGET_SCORER(/datum/target_scorer)

	controller.note_attacker(old_foe)
	TEST_ASSERT_EQUAL(scorer.select(controller, list(old_foe, bystander), null), old_foe, "A fresh grudge must outweigh a closer bystander")

	var/list/grudges = controller.blackboard[BB_AI_GRUDGE_LIST]
	grudges[old_foe] = world.time - AI_GRUDGE_TIMEOUT - 1
	TEST_ASSERT_EQUAL(scorer.select(controller, list(old_foe, bystander), null), bystander, "An expired grudge must not keep its scoring bonus")
	TEST_ASSERT(!length(controller.blackboard[BB_AI_GRUDGE_LIST]) || !controller.blackboard[BB_AI_GRUDGE_LIST][old_foe], "Scoring an expired grudge must clean it from the list")

	qdel(controller)

///RETREAT: вход по порогу здоровья, выход с гистерезисом, разворот при зажиме
/datum/unit_test/ai_retreat_hysteresis/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/pawn_turf = locate(start_turf.x + 2, start_turf.y + 2, start_turf.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(pawn_turf, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/datum/ai_planning_subtree/hostile_fsm/brain = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]
	controller.blackboard[BB_AI_RETREAT_HEALTH_FRAC] = 0.4
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	//просели ниже порога - бежим
	pawn.health = pawn.maxHealth * 0.3
	var/verdict = brain.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_RETREAT, "Dropping under the retreat threshold must enter RETREAT")
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "RETREAT must cut combat planning")
	controller.CancelActions()

	//гистерезис: подлечились чуть выше входного порога - всё ещё бежим
	pawn.health = pawn.maxHealth * 0.5
	controller.set_blackboard_key(BB_AI_RETREAT_LAST_POS, get_step(pawn_turf, WEST)) //"мы двигались"
	brain.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_RETREAT, "Recovering only slightly above the threshold must keep RETREAT (hysteresis)")
	controller.CancelActions()

	//восстановились с запасом - обратно в бой
	pawn.health = pawn.maxHealth * 0.7
	brain.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ENGAGE, "Recovering past the hysteresis margin must return to ENGAGE")
	controller.CancelActions()

	//зажат в углу: планы бегства без сдвига разворачивают драться с backoff
	pawn.health = pawn.maxHealth * 0.3
	for(var/plan_pass in 1 to AI_RETREAT_CORNERED_FRUSTRATION + 1)
		brain.SelectBehaviors(controller, 0.5)
		controller.CancelActions()
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ENGAGE, "A cornered mob must turn and fight instead of pacing the wall")
	TEST_ASSERT(controller.blackboard[BB_AI_RETREAT_BACKOFF_UNTIL] > world.time, "The cornered turnaround must arm a retreat backoff")

	qdel(controller)

///Дальник не стреляет из-за края экрана: жертва обязана видеть стрелка.
///Погоня и розыск дальность не теряют - режется именно огонь.
/datum/unit_test/ai_ranged_does_not_fire_offscreen/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, origin)
	shooter.ranged = TRUE
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y, origin.z))
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_planning_subtree/ranged_skirmish/gunner = GLOB.ai_subtrees[/datum/ai_planning_subtree/ranged_skirmish]
	TEST_ASSERT_EQUAL(gunner.max_range, AI_RANGED_MAX_FIRE_RANGE, "Дальность огня сабтри обязана браться из AI_RANGED_MAX_FIRE_RANGE")
	TEST_ASSERT(AI_RANGED_MAX_FIRE_RANGE <= 7, "Потолок огня обязан укладываться в радиус экрана игрока (7)")

	//в пределах экрана огонь планируется
	gunner.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(length(controller.current_behaviors), "Цель в пределах экрана обязана планировать стрелковое поведение")
	controller.CancelActions()

	//за потолком дальности - ни выстрела, ни перестановки под выстрел
	var/turf/offscreen = locate(origin.x + AI_RANGED_MAX_FIRE_RANGE + 1, origin.y, origin.z)
	TEST_ASSERT_NOTNULL(offscreen, "Санити: тестовой карте не хватило места для цели за краем экрана")
	prey.forceMove(offscreen)
	gunner.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!length(controller.current_behaviors), "Цель за потолком дальности не имеет права попадать под огонь")

	controller.CancelActions()
	qdel(controller)

///Кайт-шаг: анимация обязана тянуться на весь такт step_away. Иначе моб рывком
///проскакивает тайл и замирает - жалобы "не успеваешь понять, на какой он клетке".
/datum/unit_test/ai_kite_step_glide_covers_cadence/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	pawn.move_to_delay = 1 //самый быстрый легаси-темп: без правки глайд был бы вчетверо короче такта
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)

	var/datum/ai_movement/basic_avoidance/backstep/kite_mover = SSai_movement.movement_types[/datum/ai_movement/basic_avoidance/backstep]
	TEST_ASSERT_NOTNULL(kite_mover, "Санити: синглтон бекстеп-мувмента не найден")
	var/datum/ai_behavior/step_away/kite_step = GET_AI_BEHAVIOR(/datum/ai_behavior/step_away)
	TEST_ASSERT_NOTNULL(kite_step, "Санити: синглтон поведения step_away не найден")

	TEST_ASSERT(kite_mover.get_step_delay(controller) >= kite_step.action_cooldown, "Глайд кайт-шага обязан покрывать такт step_away, иначе шаг читается телепортом")

	//обычная погоня темп не теряет: кламп кайта не имеет права её замедлять
	var/datum/ai_movement/basic_avoidance/chase_mover = SSai_movement.movement_types[/datum/ai_movement/basic_avoidance]
	TEST_ASSERT_EQUAL(chase_mover.get_step_delay(controller), controller.movement_delay, "Обычное преследование обязано ходить в темпе movement_delay")

	qdel(controller)

///Пристёгнутый моб не катается на стуле: Move() пристёгнутого возвращает
///buckled.Move(), то есть толкает незаанкоренный стул вместо шага. Легаси-пул
///гейтил брождение по !buckled (simple_animal.dm), контроллеры при миграции
///этот гард потеряли.
/datum/unit_test/ai_buckled_pawn_does_not_ride_chair/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/obj/structure/chair/office/chair = allocate(/obj/structure/chair/office, run_loc_floor_bottom_left)
	var/datum/ai_controller/unit_test_wanderer/controller = new(pawn)

	TEST_ASSERT(!chair.anchored, "Санити: офисный стул обязан быть незаанкоренным, иначе тест ничего не проверяет")
	TEST_ASSERT(chair.buckle_mob(pawn, force = TRUE), "Санити: моба обязано получиться пристегнуть к стулу")
	TEST_ASSERT_EQUAL(pawn.buckled, chair, "Санити: паун обязан числиться пристёгнутым")

	var/turf/chair_start = get_turf(chair)
	var/turf/pawn_start = get_turf(pawn)
	//огромный delta_time = гарантированное срабатывание SPT_PROB брождения
	controller.idle_behavior.perform_idle_behavior(100, controller)

	TEST_ASSERT_EQUAL(get_turf(chair), chair_start, "Idle-брождение пристёгнутого пауна не имеет права двигать стул")
	TEST_ASSERT_EQUAL(get_turf(pawn), pawn_start, "Idle-брождение не имеет права двигать пристёгнутого пауна")

	qdel(controller)

///Вместо катания моб выбирается из стула, но не чаще AI_UNBUCKLE_COOLDOWN:
///user_unbuckle_mob спит в do_after, а зовут его из сигнал-хендлера мувера.
/datum/unit_test/ai_buckled_pawn_requests_unbuckle_on_cooldown/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/obj/structure/chair/office/chair = allocate(/obj/structure/chair/office, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Санити: у hostile-пауна обязан быть адаптер-контроллер")
	TEST_ASSERT(chair.buckle_mob(pawn, force = TRUE), "Санити: пауна обязано получиться пристегнуть к стулу")
	TEST_ASSERT_EQUAL(pawn.buckled, chair, "Санити: до следующего планирования паун обязан оставаться пристёгнутым")

	controller.SelectBehaviors(0.5)
	TEST_ASSERT(controller.blackboard[BB_AI_UNBUCKLE_AT] > world.time, "Попытка обязана взвести кулдаун")
	TEST_ASSERT_NULL(pawn.buckled, "Hostile-планирование обязано освободить пауна без ожидания движения")

	//Возвращаем пауна в стул, чтобы проверялся именно кулдаун, а не отсутствие
	//buckled. Второе планирование не должно спамить повторным освобождением.
	TEST_ASSERT(chair.buckle_mob(pawn, force = TRUE), "Санити: пауна обязано получиться пристегнуть повторно")
	controller.SelectBehaviors(0.5)
	TEST_ASSERT_EQUAL(pawn.buckled, chair, "Повторная попытка внутри кулдауна запрещена")
	chair.unbuckle_mob(pawn, force = TRUE)

	qdel(controller)

///Ломать окружение можно ради добычи, но не ради хлама. Мобы с
///search_objects/wanted_objects целью делают предмет (гусь - мусор, watcher -
///алмаз, голдграб - руду, майнбот - руду), и до гейта они вскрывали ради него
///преграды на пути.
/datum/unit_test/ai_does_not_breach_for_item_target/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/turf/barrier_turf = get_step(pawn_turf, EAST)
	var/turf/loot_turf = get_step(barrier_turf, EAST)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	allocate(/obj/structure/ai_unit_test_barrier, barrier_turf)
	var/obj/item/loot = allocate(/obj/item, loot_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	pawn.obj_damage = 100 //снести барьер моб способен - вопрос только в поводе

	var/datum/ai_planning_subtree/attack_obstacle_in_path/breaker = GLOB.ai_subtrees[/datum/ai_planning_subtree/attack_obstacle_in_path]
	TEST_ASSERT_NOTNULL(breaker, "Санити: синглтон сабтри взлома преград не найден")

	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, loot)
	breaker.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions) in controller.current_behaviors), "Предмет за преградой не повод её ломать")

	//живая цель за той же преградой - законный повод пробиваться
	controller.CancelActions()
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, loot_turf)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	breaker.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions) in controller.current_behaviors, "Живая цель за преградой обязана ставить взлом в план")

	qdel(controller)

///Дальник не расстреливает беспомощного. Прод 9887: watcher всадил 17 выстрелов
///в игрока, который уже был ниже нуля, последние шесть - в неподвижную цель на
///одном тайле с шагом 3.1 с. Мили-добивание вплотную это не трогает.
/datum/unit_test/ranged_ai_does_not_execute_downed_target/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(pawn_turf.x + 2, pawn_turf.y, pawn_turf.z))
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile
	//Ровно конфигурация watcher: без этой пары CanAttack отсекает лежачую цель
	//сам, ещё до нового гейта, и тест проверял бы не то, что нужно.
	shooter.robust_searching = 1
	shooter.stat_attack = UNCONSCIOUS
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_behavior/ranged_skirmish/gunner = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)
	TEST_ASSERT_NOTNULL(gunner, "Санити: синглтон поведения ranged_skirmish не найден")

	//санити: по стоящей на ногах цели стрелять можно
	shooter.ranged_cooldown = 0
	var/conscious_result = gunner.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, 7, 0)
	TEST_ASSERT(!(conscious_result & AI_BEHAVIOR_FAILED), "Санити: по цели в сознании выстрел обязан состояться")

	prey.set_stat(UNCONSCIOUS)
	TEST_ASSERT(shooter.CanAttack(prey), "Санити: со stat_attack UNCONSCIOUS цель остаётся валидной - гейт обязан быть именно дистанционным")
	shooter.ranged_cooldown = 0
	var/downed_result = gunner.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, 7, 0)
	TEST_ASSERT(downed_result & AI_BEHAVIOR_FAILED, "Беспомощная цель не имеет права оставаться мишенью для дистанционной атаки")

	//падальщик, который живёт именно добиванием, из-под гейта выведен
	shooter.stat_exclusive = TRUE
	shooter.ranged_cooldown = 0
	var/scavenger_result = gunner.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, 7, 0)
	TEST_ASSERT(!(scavenger_result & AI_BEHAVIOR_FAILED), "Падальщик со stat_exclusive обязан сохранить право стрелять по лежачим")

	qdel(controller)

///Тяжёлый залп предупреждает о себе: кулдаун взводится сразу вместе с окном
///телеграфа, иначе планировщик поставит второй залп поверх первого.
/datum/unit_test/ranged_burst_telegraphs_before_firing/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(pawn_turf.x + 2, pawn_turf.y, pawn_turf.z))
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile
	shooter.ranged_telegraph_duration = 0.6 SECONDS
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_behavior/ranged_skirmish/gunner = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)
	shooter.ranged_cooldown = 0
	var/expected_at_least = world.time + shooter.ranged_cooldown_time + shooter.ranged_telegraph_duration

	TEST_ASSERT(gunner.fire_at(controller, prey), "Санити: залп с телеграфом обязан быть принят к исполнению")
	TEST_ASSERT(shooter.ranged_cooldown >= expected_at_least, "Кулдаун обязан взводиться сразу и включать окно телеграфа")
	var/telegraph_timer_id = shooter.ranged_telegraph_timer_id
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[telegraph_timer_id], "Телеграф обязан ждать в одном остановимом таймере")
	TEST_ASSERT(!shooter.telegraphed_open_fire(prey), "Повторный вызов не должен ставить параллельный телеграф")
	TEST_ASSERT_EQUAL(shooter.ranged_telegraph_timer_id, telegraph_timer_id, "Повторный вызов не должен заменять активный таймер")

	//Имитируем callback после потери LOS: выстрел отменяется, но уже взведённый
	//кулдаун остаётся, поэтому следующий planning tick не создаст новый эффект.
	deltimer(telegraph_timer_id)
	shooter.ranged_telegraph_timer_id = null
	var/turf/wall_turf = get_step(pawn_turf, EAST)
	wall_turf = wall_turf.ChangeTurf(/turf/closed/wall)
	var/armed_cooldown = shooter.ranged_cooldown
	TEST_ASSERT(!shooter.finish_telegraphed_open_fire(prey), "Потеря LOS за время телеграфа обязана отменять выстрел")
	TEST_ASSERT_EQUAL(shooter.ranged_cooldown, armed_cooldown, "Отменённый по LOS телеграф обязан сохранить ranged cooldown")
	wall_turf.ChangeTurf(/turf/open/floor/plating)

	qdel(controller)

///Модель угрозы: окно останавливает пулю и не останавливает луч. До неё оценка
///укрытия сводилась к can_see(), то есть прозрачное стекло не считалось укрытием
///никогда - ни там, где оно работает, ни там, где нет ("мобы не понимают, что
///через стекло их расстреливают лазером, и стоят тупят").
/datum/unit_test/ai_cover_model_window_blocks_bullet_not_beam/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/turf/window_turf = get_step(pawn_turf, EAST)
	var/turf/shooter_turf = get_step(window_turf, EAST)
	var/mob/living/simple_animal/hostile/hider = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/mob/living/carbon/human/gunman = allocate(/mob/living/carbon/human, shooter_turf)
	var/obj/structure/window/fulltile/glass = allocate(/obj/structure/window/fulltile, window_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(hider)

	TEST_ASSERT(glass.density, "Санити: полнотайловое окно обязано быть плотным")
	TEST_ASSERT(!glass.opacity, "Санити: обычное окно обязано быть прозрачным - иначе тест проверял бы can_see, а не модель угрозы")
	TEST_ASSERT(can_see(pawn_turf, gunman, AI_HIDING_LOS_RANGE), "Санити: сквозь стекло стрелка видно")

	//без наблюдений угроза считается лучевой - осторожная оценка, стекло не укрытие
	TEST_ASSERT_EQUAL(controller.cover_quality(pawn_turf, gunman), AI_COVER_NONE, "Без наблюдений стекло не имеет права считаться укрытием")

	//прилетела пуля: от неё стекло укрывает
	var/obj/item/projectile/bullet = allocate(/obj/item/projectile, shooter_turf)
	controller.note_incoming_projectile(gunman, bullet)
	TEST_ASSERT_EQUAL(controller.cover_quality(pawn_turf, gunman), AI_COVER_FULL, "От баллистики окно обязано считаться укрытием")

	//тот же стрелок перешёл на луч: то же стекло укрытием быть перестаёт
	var/obj/item/projectile/beam/laser = allocate(/obj/item/projectile/beam, shooter_turf)
	controller.note_incoming_projectile(gunman, laser)
	TEST_ASSERT_EQUAL(controller.cover_quality(pawn_turf, gunman), AI_COVER_NONE, "От луча окно укрытием быть не может - PASSGLASS")

	qdel(controller)

///Стрелок под огнём на непрокрытой позиции обязан искать перестроение, а не
///стоять столбом. Раньше reposition_for_shot звался только при ПЕРЕКРЫТОЙ линии
///огня, то есть исключительно чтобы попасть, и никогда - чтобы не получить.
/datum/unit_test/ai_shooter_seeks_cover_under_fire/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/turf/window_turf = get_step(pawn_turf, EAST)
	var/turf/shooter_turf = get_step(window_turf, EAST)
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/mob/living/carbon/human/gunman = allocate(/mob/living/carbon/human, shooter_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, gunman)

	//не под огнём - поводов менять позицию ради безопасности нет
	TEST_ASSERT(!ai_should_seek_firing_cover(controller, gunman), "Вне обстрела стрелок позицию ради укрытия не меняет")

	controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] = world.time + 10 SECONDS
	controller.set_blackboard_key(BB_AI_LAST_ATTACKER, gunman)
	TEST_ASSERT(ai_should_seek_firing_cover(controller, gunman), "Под огнём на открытой позиции стрелок обязан искать перестроение")

	//поставили между ними стекло и запомнили, что стреляют баллистикой
	allocate(/obj/structure/window/fulltile, window_turf)
	var/obj/item/projectile/bullet = allocate(/obj/item/projectile, shooter_turf)
	controller.note_incoming_projectile(gunman, bullet)
	TEST_ASSERT(!ai_should_seek_firing_cover(controller, gunman), "Прикрытая от этой угрозы позиция перестроения не требует")

	qdel(controller)

///Стрелок под огнём на открытой земле НЕ прекращает огонь: перестроение
///планируется ВМЕСТЕ с выстрелом, а не вместо него. На голой земле лучшего
///тайла может не быть вовсе (best_reposition_tile честно возвращает текущий),
///и "искать укрытие" вырождалось в стояние столбом с молчащим стволом на всё
///время обстрела.
/datum/unit_test/ai_shooter_under_fire_keeps_firing/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	shooter.ranged = TRUE
	var/mob/living/carbon/human/gunman = allocate(/mob/living/carbon/human, locate(pawn_turf.x + 3, pawn_turf.y, pawn_turf.z))
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, gunman)
	controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] = world.time + 10 SECONDS
	controller.set_blackboard_key(BB_AI_LAST_ATTACKER, gunman)
	TEST_ASSERT(ai_should_seek_firing_cover(controller, gunman), "Санити: под огнём на открытой позиции повод перестроиться обязан быть")

	var/datum/ai_planning_subtree/ranged_skirmish/skirmisher = GLOB.ai_subtrees[/datum/ai_planning_subtree/ranged_skirmish]
	skirmisher.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/reposition_for_shot)], "Под огнём без укрытия стрелок обязан планировать перестроение")
	TEST_ASSERT(controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)], "Перестроение под огнём не имеет права отменять ответный огонь")

	controller.CancelActions()
	qdel(controller)

///Очередь стрелков в затылок: сосед линию не открывает, а свободный румб кольца
///боевой дистанции - открывает. Кольцевой поиск обязан вернуть проходимый тайл
///с чистой линией огня, а подтверждённый затор - планировать фланговый манёвр
///вместо вечного топтания в колонне (плейтест 22.06: очередь за мешками).
/datum/unit_test/ai_flank_fire_tile_breaks_queue/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/pawn_turf = locate(start.x, start.y + 2, start.z)
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, get_step(pawn_turf, EAST))
	var/turf/prey_turf = locate(start.x + 2, start.y + 2, start.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	//band профиля бывает шире резервации - зажимаем кольцо для теста
	controller.blackboard[BB_AI_MIN_DISTANCE] = 2
	controller.blackboard[BB_AI_MAX_DISTANCE] = 2

	TEST_ASSERT(shooter.faction_check_mob(ally), "Санити: блокер обязан быть союзником")
	TEST_ASSERT(shooter.CheckRangedFireLane(prey), "Санити: линия сквозь союзника обязана считаться перекрытой")

	var/turf/flank_tile = controller.find_flank_fire_tile(prey)
	TEST_ASSERT_NOTNULL(flank_tile, "Кольцевой поиск обязан найти свободный фланг")
	TEST_ASSERT(flank_tile != pawn_turf, "Фланг обязан быть новым тайлом, а не текущей позицией")
	TEST_ASSERT_EQUAL(get_dist(flank_tile, prey_turf), 2, "Фланг обязан лежать на кольце боевой дистанции")
	TEST_ASSERT(!shooter.CheckRangedFireLaneFrom(prey, flank_tile), "С фланга линия огня обязана быть чистой")

	//подтверждённый затор планирует манёвр, а не очередное топтание
	controller.blackboard[BB_AI_LANE_STUCK_AT] = world.time
	var/datum/ai_planning_subtree/ranged_skirmish/skirmisher = GLOB.ai_subtrees[/datum/ai_planning_subtree/ranged_skirmish]
	var/verdict = skirmisher.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "Фланговый манёвр обязан обрывать план на движении")
	TEST_ASSERT(controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/hold_covering_position)], "Подтверждённый затор обязан планировать фланговый манёвр")
	TEST_ASSERT(!controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/reposition_for_shot)], "Фланговый манёвр заменяет топтание на месте")
	TEST_ASSERT(controller.blackboard[BB_AI_FLANK_RETRY_AT] > world.time, "Кольцевой скан обязан взводить свой кулдаун")

	controller.CancelActions()
	qdel(controller)

///Мили-моб не бежит в лоб на стрелка: пока есть прикрытый шаг вперёд, он идёт
///перебежками. Плюс само опознание стрелка идёт памятью о попадании, а не
///проверкой рук - иначе КА, мех, турель и убранный на секунду ствол невидимы.
/datum/unit_test/ai_melee_approaches_shooter_under_cover/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/turf/bound_turf = get_step(pawn_turf, EAST)
	var/turf/blocker_turf = get_step(bound_turf, EAST)
	var/turf/shooter_turf = get_step(blocker_turf, EAST)
	var/mob/living/simple_animal/hostile/brawler = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/mob/living/carbon/human/gunman = allocate(/mob/living/carbon/human, shooter_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(brawler)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, gunman)

	var/datum/ai_planning_subtree/tactical_approach/approach = GLOB.ai_subtrees[/datum/ai_planning_subtree/tactical_approach]
	TEST_ASSERT_NOTNULL(approach, "Санити: синглтон сабтри подхода не найден")

	//без ствола в руках и без наблюдений цель за стрелка не считается
	TEST_ASSERT(!ai_target_is_ranged(gunman), "Санити: человек без ствола в руках дальним не считается")
	TEST_ASSERT(!controller.knows_target_shoots(gunman), "Санити: без наблюдений моб не знает, что цель стреляет")

	//в моба прилетело от этой цели - теперь он знает, чем и от кого
	var/obj/item/projectile/bullet = allocate(/obj/item/projectile, shooter_turf)
	controller.note_incoming_projectile(gunman, bullet)
	TEST_ASSERT(controller.knows_target_shoots(gunman), "Попадание снаряда обязано опознать цель как стрелка без всякого ствола в руках")

	//открытое поле: прикрытого шага вперёд нет, подход планируется обычной логикой
	TEST_ASSERT_NULL(approach.pick_covered_bound(controller, brawler, gunman), "На открытом месте перебежке взяться неоткуда")

	//поставили глухую преграду: соседний тайл к цели становится прикрытым
	allocate(/obj/effect/ai_unit_test_opaque_blocker, blocker_turf)
	TEST_ASSERT(!can_see(bound_turf, gunman, AI_HIDING_LOS_RANGE), "Санити: преграда обязана рвать линию от тайла перебежки к стрелку")
	TEST_ASSERT_EQUAL(approach.pick_covered_bound(controller, brawler, gunman), bound_turf, "Моб обязан идти к цели прикрытым шагом, а не по прямой в створ")

	qdel(controller)

// ===== Осада, персистентный фланг, эскалация кайта, отход от брошенной цели =====
// (разбор плейтеста round-23.35.57: мили-фриз у стола, мёртвый фланг, столб у стены)

///ENGAGE с активной осадой: мили-моб с целью в паре шагов и исчерпанным маршрутом
///стоит лицом к цели и бьёт преграду, а не пересобирает мёртвый план движения
/datum/unit_test/ai_siege_plans_standing_fight/Run()
	var/turf/pawn_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/turf/blocker_turf = get_step(pawn_turf, EAST)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	allocate(/obj/effect/ai_unit_test_dense_blocker, blocker_turf)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(blocker_turf, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.blackboard[BB_AI_STATE] = AI_STATE_ENGAGE
	controller.blackboard[BB_AI_SIEGE_UNTIL] = world.time + AI_SIEGE_HOLD_TIME

	var/datum/ai_planning_subtree/hostile_fsm/fsm = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]
	var/verdict = fsm.SelectBehaviors(controller, 0.5)

	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "Осада обязана обрывать план: пересборка движения к недостижимой цели и есть вечный цикл")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/alert_reaction) in controller.current_behaviors, "Осаждающий моб обязан стоять лицом к цели")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions) in controller.current_behaviors, "Преграда на прямой к цели обязана попадать под удар во время осады")

	//осада протухла - обычный боевой план (мили перепроложит маршрут)
	controller.CancelActions()
	controller.planned_behaviors.Cut()
	controller.blackboard[BB_AI_SIEGE_UNTIL] = 0
	verdict = fsm.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_NULL(verdict, "Протухшая осада не имеет права обрывать план: бой продолжается штатными сабтри")
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/alert_reaction) in controller.current_behaviors), "Без осады стойка не планируется")

	controller.CancelActions()
	qdel(controller)

///Закоммиченный фланговый манёвр переживает планировочные циклы: пока он жив,
///стрелок продолжает идти на фланг, а не отменяет его ради удержания позиции
/datum/unit_test/ai_flank_commit_persists/Run()
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, EAST)) //союзник перекрывает линию
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	TEST_ASSERT(shooter.CheckRangedFireLane(prey), "Санити: линия огня обязана быть перекрыта союзником")
	var/turf/committed = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	controller.set_blackboard_key(BB_AI_FLANK_TILE, committed)
	controller.blackboard[BB_AI_FLANK_UNTIL] = world.time + AI_FLANK_COMMIT_TIME

	var/datum/ai_planning_subtree/ranged_skirmish/skirmisher = GLOB.ai_subtrees[/datum/ai_planning_subtree/ranged_skirmish]
	var/verdict = skirmisher.SelectBehaviors(controller, 0.5)

	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "Живой фланговый манёвр обязан обрывать план на движении")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/hold_covering_position) in controller.current_behaviors, "Живой фланг обязан продолжать движение на закоммиченный тайл")
	TEST_ASSERT(!controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/reposition_for_shot)], "Пока манёвр жив, перестроение не имеет права его затирать")

	//манёвр протух: коммит снимается, стрелок возвращается к обычному перестроению
	controller.planned_behaviors.Cut()
	controller.blackboard[BB_AI_FLANK_UNTIL] = 0
	verdict = skirmisher.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(isnull(controller.blackboard[BB_AI_FLANK_TILE]), "Протухший фланговый коммит обязан сниматься")
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/hold_covering_position) in controller.current_behaviors), "Протухший манёвр обязан завершаться, а не вести моба на старый тайл")
	TEST_ASSERT(controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/reposition_for_shot)], "После протухшего манёвра стрелок возвращается к обычному перестроению")

	controller.CancelActions()
	qdel(controller)

///Разнос флангов: тайл, закоммиченный союзником, не выбирается вторым стрелком -
///иначе вся группа сходится в одну точку и толкается телами
/datum/unit_test/ai_flank_pick_respects_ally_claim/Run()
	var/turf/pawn_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/shooter = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	shooter.ranged = TRUE
	shooter.projectiletype = /obj/item/projectile/beam/laser
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(shooter)

	var/turf/first_pick = controller.find_flank_fire_tile(prey)
	TEST_ASSERT_NOTNULL(first_pick, "Санити: в пустой резервации фланговый тайл обязан находиться")

	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, get_step(pawn_turf, WEST))
	var/datum/ai_controller/unit_test_hunter/ally_controller = new(ally)
	ally_controller.set_blackboard_key(BB_AI_FLANK_TILE, first_pick)

	//кэш союзников живёт один тик планирования - имитируем следующий тик
	controller.blackboard[BB_AI_ALLY_CACHE_AT] = null
	var/turf/second_pick = controller.find_flank_fire_tile(prey)
	TEST_ASSERT_NOTNULL(second_pick, "При занятом фланге обязана находиться альтернатива на кольце")
	TEST_ASSERT_NOTEQUAL(second_pick, first_pick, "Закоммиченный союзником фланговый тайл обязан пропускаться")

	qdel(ally_controller)
	qdel(controller)

///Зажатый у стены кайтер после серии провалов отходит вбок (равная дистанция),
///а после длинной серии - прорывается на дальний тайл, вместо вечного столба
/datum/unit_test/ai_kite_pinned_slides_lateral/Run()
	var/turf/pawn_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	pawn.ranged = TRUE
	//стена из мебели с юга: все строго-дальние тайлы отхода заблокированы
	allocate(/obj/effect/ai_unit_test_dense_blocker, get_step(pawn_turf, SOUTH))
	allocate(/obj/effect/ai_unit_test_dense_blocker, get_step(pawn_turf, SOUTHEAST))
	allocate(/obj/effect/ai_unit_test_dense_blocker, get_step(pawn_turf, SOUTHWEST))
	var/turf/threat_turf = locate(pawn_turf.x, pawn_turf.y + 2, pawn_turf.z)
	var/mob/living/carbon/human/threat = allocate(/mob/living/carbon/human, threat_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, threat)
	controller.set_blackboard_key(BB_AI_MIN_DISTANCE, 4)
	controller.set_blackboard_key(BB_AI_MAX_DISTANCE, 6)

	//контракт строгого отхода сохранён: без серии провалов зажатый не пляшет
	var/datum/ai_planning_subtree/maintain_distance/keeper = GLOB.ai_subtrees[/datum/ai_planning_subtree/maintain_distance]
	keeper.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/step_away) in controller.current_behaviors), "Санити: без эскалации строгий отход у стены честно проваливается")
	TEST_ASSERT((controller.blackboard[BB_AI_KITE_PINNED_STREAK] || 0) > 0, "Провал отхода обязан копить серию зажатости")

	//серия провалов набрана: разрешается боковой шаг равной дистанции
	controller.CancelActions()
	controller.planned_behaviors.Cut()
	controller.blackboard[BB_AI_KITE_PINNED_STREAK] = AI_KITE_LATERAL_STREAK
	keeper.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/step_away) in controller.current_behaviors, "После серии провалов кайтер обязан отходить вбок, а не стоять столбом")
	var/turf/lateral = controller.current_movement_target
	TEST_ASSERT_NOTNULL(lateral, "Боковой отход обязан ставить цель движения")
	TEST_ASSERT(get_dist(lateral, threat) >= get_dist(pawn, threat), "Боковой шаг не имеет права приближать к угрозе")
	TEST_ASSERT_NOTEQUAL(lateral, pawn_turf, "Боковой шаг обязан быть настоящим шагом")

	//длинная серия: прорыв на дальний достижимый тайл вместо шага
	controller.CancelActions()
	controller.planned_behaviors.Cut()
	controller.blackboard[BB_AI_KITE_PINNED_STREAK] = AI_KITE_BREAK_AWAY_STREAK
	keeper.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_break_away) in controller.current_behaviors, "Длинная серия зажатости обязана эскалировать в прорыв")

	controller.CancelActions()
	qdel(controller)

///Бросивший бесполезную цель моб отходит от неё, а не стоит вплотную в idle
/datum/unit_test/ai_abandoned_futile_target_steps_away/Run()
	var/turf/pawn_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/mob/living/carbon/human/dropped = allocate(/mob/living/carbon/human, get_step(pawn_turf, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	controller.blackboard[BB_AI_STATE] = AI_STATE_IDLE
	controller.set_blackboard_key(BB_AI_ABANDON_AVOID, dropped)
	controller.blackboard[BB_AI_ABANDON_AVOID_UNTIL] = world.time + AI_PURSUIT_ABANDON_COOLDOWN

	var/datum/ai_planning_subtree/hostile_fsm/fsm = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]
	var/verdict = fsm.SelectBehaviors(controller, 0.5)

	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "Отход от брошенной цели обязан обрывать план")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/run_away_from_target/retreat) in controller.current_behaviors, "Моб обязан отходить от цели, которую доказанно нечем пробить")

	//окно отхода закрыто: ключ чистится, мирная жизнь продолжается
	controller.CancelActions()
	controller.planned_behaviors.Cut()
	controller.blackboard[BB_AI_ABANDON_AVOID_UNTIL] = 0
	fsm.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(isnull(controller.blackboard[BB_AI_ABANDON_AVOID]), "Закрытое окно отхода обязано чистить ключ брошенной цели")
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/run_away_from_target/retreat) in controller.current_behaviors), "После окна отхода бегство не планируется")

	controller.CancelActions()
	qdel(controller)
