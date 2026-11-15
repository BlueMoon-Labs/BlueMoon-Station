// Репорт: дрейк в полёте и сразу после приземления разбирал меха за полминуты, хотя
// пешего в эти моменты не трогал. Удары шли мимо AttackingTarget - через снос преград
// пути и окружения, где ни пикирование, ни отдых после посадки не проверялись.

/datum/unit_test/megafauna_drake_mech
	abstract_type = /datum/unit_test/megafauna_drake_mech
	var/mob/living/simple_animal/hostile/megafauna/dragon/drake
	var/obj/vehicle/sealed/mecha/combat/gygax/mech

/datum/unit_test/megafauna_drake_mech/proc/setup_scene()
	drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon, run_loc_floor_bottom_left)
	var/turf/mech_turf = get_step(run_loc_floor_bottom_left, EAST)
	mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, mech_turf)
	mech.deflect_chance = 0
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, mech_turf)
	pilot.forceMove(mech)
	mech.add_occupant(pilot)
	drake.ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, mech)
	drake.GiveTarget(mech)
	drake.recovery_time = 0

/datum/unit_test/megafauna_drake_mech/proc/strike_through_ai()
	var/datum/ai_behavior/attack_obstructions/obstruction = GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions)
	obstruction.perform(0.5, drake.ai_controller, BB_AI_CURRENT_TARGET)
	var/datum/ai_behavior/destroy_surroundings/surroundings = GET_AI_BEHAVIOR(/datum/ai_behavior/destroy_surroundings)
	surroundings.perform(0.5, drake.ai_controller)
	drake.MeleeAction(FALSE)

/// В полёте дрейк не бьёт меха ни милишкой, ни сносом "преграды" на пути.
/datum/unit_test/megafauna_drake_mech/swoop

/datum/unit_test/megafauna_drake_mech/swoop/Run()
	setup_scene()
	drake.swooping = SWOOP_DAMAGEABLE | SWOOP_INVULNERABLE
	var/integrity_before = mech.obj_integrity

	var/datum/ai_planning_subtree/attack_obstacle_in_path/subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/attack_obstacle_in_path]
	subtree.SelectBehaviors(drake.ai_controller, 0.5)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions) in drake.ai_controller.current_behaviors), "Пикирующий дрейк планирует снос преграды на пути")

	strike_through_ai()
	TEST_ASSERT_EQUAL(mech.obj_integrity, integrity_before, "Мех получил урон от дрейка в полёте")

	//пеший, вставший телом между пикирующим дрейком и целью, тоже не бьётся
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z))
	var/mob/living/carbon/human/blocker = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	drake.ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	var/blocker_health = blocker.health
	var/datum/ai_behavior/attack_path_blocker/body_block = GET_AI_BEHAVIOR(/datum/ai_behavior/attack_path_blocker)
	body_block.perform(0.5, drake.ai_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(blocker.health, blocker_health, "Пикирующий дрейк ударил пешего на пути")
	drake.ai_controller.CancelActions()
	drake.swooping = NONE

/// После посадки дрейк отдыхает: удары по меху идут только милишкой, после отдыха и через броню.
/datum/unit_test/megafauna_drake_mech/landing

/datum/unit_test/megafauna_drake_mech/landing/Run()
	setup_scene()
	drake.recovery_time = world.time + 10 SECONDS
	var/integrity_before = mech.obj_integrity

	var/datum/ai_planning_subtree/attack_obstacle_in_path/subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/attack_obstacle_in_path]
	subtree.SelectBehaviors(drake.ai_controller, 0.5)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions) in drake.ai_controller.current_behaviors), "Соседний мех-цель считается преградой пути")
	TEST_ASSERT_NULL(ai_get_blocked_path_turf(drake, mech), "Клетка соседней цели считается заблокированным шагом")

	strike_through_ai()
	TEST_ASSERT_EQUAL(mech.obj_integrity, integrity_before, "Мех получил урон, пока дрейк отдыхает после посадки")

	drake.recovery_time = 0
	drake.MeleeAction(FALSE)
	var/taken = integrity_before - mech.obj_integrity
	TEST_ASSERT(taken > 0, "После отдыха дрейк не бьёт меха вовсе")
	TEST_ASSERT(taken < 20 * drake.environment_smash, "Удар дрейка по меху не режется бронёй: [taken]")
	drake.ai_controller.CancelActions()

/// Пули не берут дрейка только в воздухе; после посадки он снова получает урон.
/datum/unit_test/megafauna_drake_bullets_after_landing

/datum/unit_test/megafauna_drake_bullets_after_landing/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/megafauna/dragon/drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon, start)
	drake.toggle_ai(AI_OFF)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start.x + 3, start.y, start.z))

	INVOKE_ASYNC(drake, TYPE_PROC_REF(/mob/living/simple_animal/hostile/megafauna/dragon, swoop_attack), FALSE, prey, 10)
	sleep(5)
	TEST_ASSERT(drake.swooping & SWOOP_INVULNERABLE, "Санити: дрейк обязан быть в воздухе")
	var/obj/item/projectile/airborne_shot = allocate(/obj/item/projectile, drake.loc)
	TEST_ASSERT(!airborne_shot.can_hit_target(drake, FALSE, TRUE), "Пуля попадает в дрейка в воздухе")

	TEST_ASSERT(wait_for_var(drake, "swooping", NONE, 6 SECONDS), "Пикирование не закончилось")
	TEST_ASSERT(drake.density, "Дрейк остался неплотным после посадки")
	TEST_ASSERT_EQUAL(drake.mouse_opacity, initial(drake.mouse_opacity), "Дрейк остался некликабельным после посадки")
	var/obj/item/projectile/landed_shot = allocate(/obj/item/projectile, drake.loc)
	landed_shot.damage = 30
	TEST_ASSERT(landed_shot.can_hit_target(drake, FALSE, TRUE), "Пуля не попадает в севшего дрейка")
	var/health_before = drake.health
	drake.bullet_act(landed_shot)
	TEST_ASSERT(drake.health < health_before, "Севший дрейк не получает урон от пуль")
