// ===== Body-block fairness: моб пробивает врага на пути, а не обтекает =====
//
// Репорт игрока: "мобы круче игроков - обходят, если ты загораживаешь дорогу".
// Атакуемого врага-блокера моб теперь бьёт (attack_path_blocker), а JPS-мовер его
// не обходит; союзника/нейтрала по-прежнему обходит.

///Враг на следующем шаге пути детектится как блокер, планируется его атака, мовер
///помечает его "не обходить", а удар реально ранит блокера.
/datum/unit_test/ai_body_block_attacks_enemy/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y, start.z))
	var/mob/living/carbon/human/blocker = allocate(/mob/living/carbon/human, get_step(start, EAST))
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, target)

	TEST_ASSERT_EQUAL(ai_path_blocker_mob(pawn, target), blocker, "An attackable enemy on the next path step must be detected as a blocker")
	TEST_ASSERT(ai_step_blocker_attackable(pawn, get_turf(blocker)), "The mover must treat an attackable blocker as non-detourable")

	var/datum/ai_planning_subtree/attack_obstacle_in_path/subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/attack_obstacle_in_path]
	subtree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/attack_path_blocker) in controller.current_behaviors, "A body-blocking enemy must be attacked, not routed around")

	//удар обычной милишкой реально ранит блокера
	pawn.melee_damage_lower = 10
	pawn.melee_damage_upper = 10
	var/blocker_health_before = blocker.health
	blocker.attack_animal(pawn)
	TEST_ASSERT(blocker.health < blocker_health_before, "Attacking the body-blocker must damage it")

	controller.CancelActions()
	qdel(controller)

///Союзник (та же фракция, не атакуемый) блокером НЕ считается - его мовер обходит,
///атака блокера не планируется.
/datum/unit_test/ai_body_block_ignores_ally/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y, start.z))
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, get_step(start, EAST))
	ally.faction = pawn.faction.Copy()
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, target)

	TEST_ASSERT_NULL(ai_path_blocker_mob(pawn, target), "A same-faction ally must not be treated as a body-block to attack")
	TEST_ASSERT(!ai_step_blocker_attackable(pawn, get_turf(ally)), "The mover must still route around a non-attackable ally")

	var/datum/ai_planning_subtree/attack_obstacle_in_path/subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/attack_obstacle_in_path]
	subtree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/attack_path_blocker) in controller.current_behaviors), "An ally blocker must not trigger a blocker attack")

	controller.CancelActions()
	qdel(controller)
