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

///Труп, пристёгнутый к стулу, - плотная неподвижная баррикада, которую CanAttack
///не видит (мёртвый - не цель). Паун обязан отстегнуть тело тем же глаголом, каким
///игрок снимает его одним кликом, - иначе трупы на стульях становятся неразрушимой
///стеной от NPC (репорт плейтеста).
/datum/unit_test/ai_body_block_clears_seated_corpse/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/blocker_turf = get_step(start, EAST)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y, start.z))
	var/obj/structure/chair/chair = allocate(/obj/structure/chair, blocker_turf)
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, blocker_turf)
	corpse.death()
	TEST_ASSERT(chair.buckle_mob(corpse, force = TRUE), "Санити: труп обязан пристёгиваться к стулу")
	TEST_ASSERT(corpse.density, "Санити: пристёгнутый труп обязан сидеть стоймя и быть плотным")
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, target)

	TEST_ASSERT_NULL(ai_path_blocker_mob(pawn, target), "A corpse must not be treated as an attackable body-block")
	TEST_ASSERT_EQUAL(ai_body_barricade_mob(pawn, target), corpse, "A seated corpse on the next path step must be detected as a body barricade")
	TEST_ASSERT(ai_step_blocker_attackable(pawn, blocker_turf), "The mover must hold position at a corpse barricade instead of detouring")

	var/datum/ai_planning_subtree/attack_obstacle_in_path/subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/attack_obstacle_in_path]
	subtree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/clear_body_barricade) in controller.current_behaviors, "A corpse barricade must queue the unbuckle behavior")

	var/datum/ai_behavior/clear_body_barricade/behavior = GET_AI_BEHAVIOR(/datum/ai_behavior/clear_body_barricade)
	behavior.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_NULL(corpse.buckled, "The pawn must unbuckle the corpse from the chair")
	TEST_ASSERT(!corpse.density, "The unbuckled corpse must fall and stop blocking the tile")
	TEST_ASSERT_NULL(ai_body_barricade_mob(pawn, target), "The path must read as clear once the corpse is on the floor")
	var/second_pass = behavior.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(second_pass & AI_BEHAVIOR_SUCCEEDED, "A cleared barricade must complete the behavior")

	controller.CancelActions()
	qdel(controller)

///Крепление, которое молча игнорирует чужой рывок (дыба вампира и подобные),
///не должно зацикливать пауна: бюджет попыток исчерпан - поведение проваливается
///и кормит штатную фрустрацию/перевыбор цели.
/datum/unit_test/ai_body_block_barricade_attempt_budget/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/blocker_turf = get_step(start, EAST)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y, start.z))
	var/obj/structure/chair/chair = allocate(/obj/structure/chair, blocker_turf)
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, blocker_turf)
	corpse.death()
	TEST_ASSERT(chair.buckle_mob(corpse, force = TRUE), "Санити: труп обязан пристёгиваться к стулу")
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, target)

	var/datum/ai_behavior/clear_body_barricade/behavior = GET_AI_BEHAVIOR(/datum/ai_behavior/clear_body_barricade)
	for(var/tug in 1 to AI_BARRICADE_UNBUCKLE_ATTEMPTS)
		var/result = behavior.perform(0.5, controller, BB_AI_CURRENT_TARGET)
		TEST_ASSERT(!(result & AI_BEHAVIOR_FAILED), "Рывок [tug] в пределах бюджета не должен проваливать поведение")
		//имитация неподдающегося крепления: тело оказывается пристёгнутым снова
		if(!corpse.buckled)
			TEST_ASSERT(chair.buckle_mob(corpse, force = TRUE), "Санити: труп обязан пристёгиваться повторно")
	var/exhausted = behavior.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(exhausted & AI_BEHAVIOR_FAILED, "Исчерпанный бюджет рывков обязан проваливать поведение, а не крутиться вечно")

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
