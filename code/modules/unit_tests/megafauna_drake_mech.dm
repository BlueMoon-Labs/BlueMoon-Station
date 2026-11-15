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

/// Цель в шкафу милишке недосягаема: шкаф остаётся преградой пути, и дрейк его ломает.
/datum/unit_test/megafauna_drake_mech/closet

/datum/unit_test/megafauna_drake_mech/closet/Run()
	drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon, run_loc_floor_bottom_left)
	drake.toggle_ai(AI_OFF)
	drake.recovery_time = 0
	var/turf/closet_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, closet_turf)
	var/mob/living/carbon/human/hider = allocate(/mob/living/carbon/human, closet_turf)
	hider.forceMove(closet)
	drake.ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, hider)
	drake.GiveTarget(hider)
	TEST_ASSERT(!ai_step_reaches_target(drake, hider, closet_turf), "Цель в шкафу считается досягаемой для удара")

	var/datum/ai_planning_subtree/attack_obstacle_in_path/subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/attack_obstacle_in_path]
	subtree.SelectBehaviors(drake.ai_controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions) in drake.ai_controller.current_behaviors, "Шкаф с целью внутри не считается преградой пути")

	var/integrity_before = closet.obj_integrity
	var/datum/ai_behavior/attack_obstructions/obstruction = GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions)
	obstruction.perform(0.5, drake.ai_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(QDELETED(closet) || closet.obj_integrity < integrity_before, "Дрейк не ломает шкаф, в котором сидит цель")
	drake.ai_controller.CancelActions()

/// Мех с живым пилотом не окружение и не преграда: его бьют только как цель. Пустой мех - преграда.
/datum/unit_test/megafauna_drake_mech/occupied_vehicle

/datum/unit_test/megafauna_drake_mech/occupied_vehicle/Run()
	setup_scene()
	drake.toggle_ai(AI_OFF)
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y, start.z))
	drake.ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	drake.GiveTarget(prey)
	var/integrity_before = mech.obj_integrity

	var/datum/ai_behavior/destroy_surroundings/surroundings = GET_AI_BEHAVIOR(/datum/ai_behavior/destroy_surroundings)
	surroundings.perform(0.5, drake.ai_controller)
	TEST_ASSERT_EQUAL(mech.obj_integrity, integrity_before, "Снос окружения бьёт меха с пилотом, который не цель")
	var/datum/ai_behavior/attack_obstructions/obstruction = GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions)
	obstruction.perform(0.5, drake.ai_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(mech.obj_integrity, integrity_before, "Мех с пилотом сносится как преграда пути к пешему")

	var/obj/vehicle/sealed/mecha/combat/gygax/empty_mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, get_step(start, NORTH))
	empty_mech.deflect_chance = 0
	var/mob/living/carbon/human/far_prey = allocate(/mob/living/carbon/human, locate(start.x, start.y + 2, start.z))
	drake.ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, far_prey)
	drake.GiveTarget(far_prey)
	var/empty_before = empty_mech.obj_integrity
	obstruction.perform(0.5, drake.ai_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(empty_mech.obj_integrity < empty_before, "Пустой мех на пути перестал быть преградой")
	drake.ai_controller.CancelActions()

/// Занятую технику, которую моб целью не берёт (клоун-кар), он ломает как обычную преграду.
/datum/unit_test/megafauna_drake_mech/untargetable_vehicle

/datum/unit_test/megafauna_drake_mech/untargetable_vehicle/proc/occupied_car(turf/car_turf)
	var/obj/vehicle/sealed/car/clowncar/car = allocate(/obj/vehicle/sealed/car/clowncar, car_turf)
	var/mob/living/carbon/human/driver = allocate(/mob/living/carbon/human, car_turf)
	driver.forceMove(car)
	car.add_occupant(driver)
	return car

/datum/unit_test/megafauna_drake_mech/untargetable_vehicle/Run()
	var/turf/start = run_loc_floor_bottom_left
	drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon, start)
	drake.toggle_ai(AI_OFF)
	drake.recovery_time = 0

	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y, start.z))
	drake.ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	drake.GiveTarget(prey)

	var/obj/vehicle/sealed/car/clowncar/side_car = occupied_car(get_step(start, NORTH))
	TEST_ASSERT(ai_vehicle_has_living_occupant(side_car), "Санити: в клоун-каре нет живого седока")
	TEST_ASSERT(!drake.CanAttack(side_car), "Санити: дрейк берёт клоун-кар целью")
	var/side_before = side_car.obj_integrity
	drake.DestroySurroundings()
	TEST_ASSERT(QDELETED(side_car) || side_car.obj_integrity < side_before, "Снос окружения не трогает занятый клоун-кар")

	//удар выше взял кулдаун атаки
	drake.next_action = 0
	drake.next_action_immediate = 0
	drake.last_action = 0
	var/obj/vehicle/sealed/car/clowncar/path_car = occupied_car(get_step(start, EAST))
	var/path_before = path_car.obj_integrity
	var/datum/ai_behavior/attack_obstructions/obstruction = GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions)
	obstruction.perform(0.5, drake.ai_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(QDELETED(path_car) || path_car.obj_integrity < path_before, "Занятый клоун-кар на пути - неразрушимая стена")
	drake.ai_controller.CancelActions()

/// Отдых мегафауны после спецатаки бережёт только живых на пути, а не окружение.
/datum/unit_test/megafauna_recovery_spares_blocker

/datum/unit_test/megafauna_recovery_spares_blocker/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner/miner = allocate(/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner, start)
	miner.toggle_ai(AI_OFF)
	var/mob/living/carbon/human/blocker = allocate(/mob/living/carbon/human, get_step(start, NORTH))
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start.x, start.y + 2, start.z))
	miner.ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	miner.GiveTarget(prey)
	miner.recovery_time = world.time + 10 SECONDS
	TEST_ASSERT(!ai_pawn_path_paused(miner), "Отдых мегафауны ставит на паузу всю расчистку пути")

	var/blocker_health = blocker.health
	var/datum/ai_behavior/attack_path_blocker/body_block = GET_AI_BEHAVIOR(/datum/ai_behavior/attack_path_blocker)
	body_block.perform(0.5, miner.ai_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(blocker.health, blocker_health, "Ледяной шахтёр бьёт пешего на пути во время отдыха")

	miner.recovery_time = 0
	body_block.perform(0.5, miner.ai_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(blocker.health < blocker_health, "Санити: после отдыха шахтёр не бьёт пешего на пути")
	miner.ai_controller.CancelActions()

/// Ледяной шахтёр почти весь бой отдыхает: в отдыхе он всё равно копает породу и ломает мебель на пути.
/datum/unit_test/megafauna_recovery_still_digs

/datum/unit_test/megafauna_recovery_still_digs/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner/miner = allocate(/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner, start)
	miner.toggle_ai(AI_OFF)
	miner.recovery_time = world.time + 10 SECONDS
	var/datum/ai_behavior/attack_obstructions/obstruction = GET_AI_BEHAVIOR(/datum/ai_behavior/attack_obstructions)

	var/obj/structure/closet/closet = allocate(/obj/structure/closet, get_step(start, EAST))
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y, start.z))
	miner.ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	miner.GiveTarget(prey)
	var/closet_before = closet.obj_integrity
	obstruction.perform(0.5, miner.ai_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(QDELETED(closet) || closet.obj_integrity < closet_before, "Отдыхающий шахтёр не ломает шкаф на пути")

	var/turf/rock = get_step(start, NORTH)
	rock = rock.ChangeTurf(/turf/closed/mineral)
	var/mob/living/carbon/human/far_prey = allocate(/mob/living/carbon/human, locate(start.x, start.y + 2, start.z))
	miner.ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, far_prey)
	miner.GiveTarget(far_prey)
	obstruction.perform(0.5, miner.ai_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(!ismineralturf(rock), "Отдыхающий шахтёр не копает породу на пути")
	miner.ai_controller.CancelActions()

/// Моб, чей удар меха не царапает, не держит его целью; стрелок со снарядом - держит.
/datum/unit_test/ai_harmless_melee_ignores_mecha

/datum/unit_test/ai_harmless_melee_ignores_mecha/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/turf/mech_turf = locate(start_turf.x + 3, start_turf.y, start_turf.z)
	var/obj/vehicle/sealed/mecha/combat/gygax/mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, mech_turf)
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, mech_turf)
	pilot.forceMove(mech)
	mech.add_occupant(pilot)
	TEST_ASSERT(pawn.CanAttack(mech), "Санити: мех с пилотом атакуем для обычного моба")

	pawn.environment_smash = ENVIRONMENT_SMASH_NONE
	pawn.ranged = FALSE
	TEST_ASSERT(!pawn.CanAttack(mech), "Моб без сноса окружения считает меха целью, хотя не наносит ему урона")
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, mech)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_NOTEQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], mech, "Безвредный для меха моб удержал его целью")
	qdel(controller)

	pawn.ranged = TRUE
	TEST_ASSERT(!pawn.CanAttack(mech), "Моб с ranged без снаряда (элитка, хайвлорд) считает меха целью")
	pawn.projectiletype = /obj/item/projectile
	TEST_ASSERT(pawn.CanAttack(mech), "Стрелок без сноса окружения перестал считать меха целью")
	pawn.projectiletype = null
	pawn.casingtype = /obj/item/ammo_casing
	TEST_ASSERT(pawn.CanAttack(mech), "Стрелок с гильзой без сноса окружения перестал считать меха целью")

/// Пули не берут дрейка только в воздухе; после посадки он снова получает урон.
/datum/unit_test/megafauna_drake_bullets_after_landing

/datum/unit_test/megafauna_drake_bullets_after_landing/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/megafauna/dragon/drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon, start)
	drake.toggle_ai(AI_OFF)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start.x + 3, start.y, start.z))

	INVOKE_ASYNC(drake, TYPE_PROC_REF(/mob/living/simple_animal/hostile/megafauna/dragon, swoop_attack), FALSE, prey, 10)
	var/list/budget = new_wait_budget(2 SECONDS, "дрейк взлетает")
	while(!(drake.swooping & SWOOP_INVULNERABLE))
		if(!wait_budget_tick(budget))
			break
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

/// Похотливые мобы бьют меха-цель обычной атакой, а не лезут в поля моба на объекте.
/datum/unit_test/lewd_mobs_attack_mecha

/datum/unit_test/lewd_mobs_attack_mecha/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/mech_turf = get_step(start, EAST)
	var/list/attacker_types = list(
		/mob/living/simple_animal/hostile/deathclaw/funclaw,
		/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw,
		/mob/living/simple_animal/hostile/werewolf/funwolf,
		/mob/living/simple_animal/hostile/ice_wolf/funwolf,
		/mob/living/simple_animal/hostile/hellhound/funwolf,
		/mob/living/simple_animal/hostile/the_mosley/funwolf,
	)
	for(var/attacker_type in attacker_types)
		var/obj/vehicle/sealed/mecha/combat/gygax/mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, mech_turf)
		mech.deflect_chance = 0
		var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, mech_turf)
		pilot.forceMove(mech)
		mech.add_occupant(pilot)
		var/mob/living/simple_animal/hostile/attacker = allocate(attacker_type, start)
		attacker.toggle_ai(AI_OFF)
		attacker.target = mech
		var/integrity_before = mech.obj_integrity
		attacker.AttackingTarget()
		TEST_ASSERT(mech.obj_integrity < integrity_before, "[attacker_type] не бьёт меха-цель обычной атакой")
		TEST_ASSERT_NULL(attacker.pulling, "[attacker_type] схватил меха вместо удара")
		attacker.target = null
		qdel(attacker)
		qdel(mech)

/// Мягкие похотливые мобы меха целью не берут: им нужен партнёр, а не броня. Агрессивные - берут.
/datum/unit_test/lewd_gentle_mobs_ignore_mecha

/datum/unit_test/lewd_gentle_mobs_ignore_mecha/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/mech_turf = locate(start.x + 2, start.y, start.z)
	var/obj/vehicle/sealed/mecha/combat/gygax/mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, mech_turf)
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, mech_turf)
	pilot.forceMove(mech)
	mech.add_occupant(pilot)

	var/mob/living/simple_animal/hostile/deathclaw/funclaw/rough = allocate(/mob/living/simple_animal/hostile/deathclaw/funclaw, start)
	rough.toggle_ai(AI_OFF)
	rough.enemies += pilot
	TEST_ASSERT(rough.CanAttack(mech), "Агрессивный фанклав перестал брать целью меха с обидчиком внутри")
	rough.enemies -= pilot

	var/list/gentle_types = list(
		/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle,
		/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw,
		/mob/living/simple_animal/hostile/werewolf/funwolf/gentle,
		/mob/living/simple_animal/hostile/ice_wolf/funwolf/gentle,
		/mob/living/simple_animal/hostile/hellhound/funwolf/gentle,
		/mob/living/simple_animal/hostile/the_mosley/funwolf/gentle,
	)
	for(var/gentle_type in gentle_types)
		var/mob/living/simple_animal/hostile/gentle = allocate(gentle_type, start)
		gentle.toggle_ai(AI_OFF)
		gentle.enemies += pilot
		TEST_ASSERT(!gentle.CanAttack(mech), "[gentle_type] в мягком режиме берёт меха целью")
		gentle.enemies -= pilot
		qdel(gentle)
