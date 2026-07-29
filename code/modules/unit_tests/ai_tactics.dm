// ===== Тактические сабтри =====
//
// Проверяют кайт-band, бегство, дистанционную стрельбу и FSM
// (SEARCH к последней позиции без волхака, таймаут, промоушен переданной цели).

/obj/effect/ai_unit_test_opaque_blocker
	name = "opaque AI test blocker"
	opacity = TRUE
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
	//строим короткий горизонтальный коридор: стены сверху и снизу от стрелка
	var/turf/floor = run_loc_floor_bottom_left
	var/turf/wall_north = get_step(floor, NORTH)
	var/turf/wall_south = get_step(floor, SOUTH)
	wall_north.ChangeTurf(/turf/closed/wall)
	wall_south.ChangeTurf(/turf/closed/wall)
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
