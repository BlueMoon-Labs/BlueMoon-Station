// ===== Селектор способностей боссов =====
//
// Проверяют фазовые/дальностные гейты записей, индивидуальные кулдауны,
// взвешенную колоду с анти-повтором и гард от двойного огня легаси-пути.

///Таблица строится при посессии и глушит легаси-автозалп
/datum/unit_test/ai_boss_table_built/Run()
	var/mob/living/simple_animal/hostile/megafauna/legion/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/legion)
	var/datum/ai_controller/hostile_adapter/boss/controller = boss_mob.ai_controller
	TEST_ASSERT(istype(controller), "Sanity: legion must be on the boss profile")

	var/list/attack_table = controller.blackboard[BB_AI_BOSS_ATTACKS]
	TEST_ASSERT(length(attack_table) == 3, "Legion must build a three-entry attack table")
	TEST_ASSERT(boss_mob.ai_attack_tables_active, "An active table must suppress the legacy auto-OpenFire")

///Фазовые и дальностные гейты is_available
/datum/unit_test/ai_boss_availability_gates/Run()
	var/mob/living/simple_animal/hostile/megafauna/legion/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/legion)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	boss_mob.forceMove(run_loc_floor_bottom_left)

	//дальность: чардж легиона требует min_range 2 - вплотную недоступен
	var/datum/ai_controller/hostile_adapter/boss/controller = boss_mob.ai_controller
	var/list/attack_table = controller.blackboard[BB_AI_BOSS_ATTACKS]
	var/datum/boss_attack/charge_entry
	for(var/datum/boss_attack/entry as anything in attack_table)
		if(entry.name == "charge")
			charge_entry = entry
			break
	TEST_ASSERT_NOTNULL(charge_entry, "Sanity: legion table must have a charge entry")
	TEST_ASSERT(!charge_entry.is_available(boss_mob, prey), "A point-blank target must gate out the charge (min_range)")
	var/turf/far_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	prey.forceMove(far_turf)
	TEST_ASSERT(charge_entry.is_available(boss_mob, prey), "A distant target must allow the charge")

	//фаза: тестовая запись доступна только ниже половины здоровья
	var/datum/boss_attack/phase_entry = new("phase test", null, 1 SECONDS, 10, 0, INFINITY, 0, 0.5)
	TEST_ASSERT(!phase_entry.is_available(boss_mob, prey), "A sub-50% entry must be unavailable at full health")
	boss_mob.health = boss_mob.maxHealth * 0.25
	TEST_ASSERT(phase_entry.is_available(boss_mob, prey), "A sub-50% entry must open up at quarter health")
	boss_mob.health = boss_mob.maxHealth

	//кулдаун записи
	charge_entry.next_use_time = world.time + 10 SECONDS
	TEST_ASSERT(!charge_entry.is_available(boss_mob, prey), "A cooling-down entry must be unavailable")
	charge_entry.next_use_time = 0

///Колода выбирает только доступные записи (детерминизм при единственной
///доступной), исполняет легаси-прок и записывает анти-повтор
/datum/unit_test/ai_boss_selection_executes/Run()
	var/mob/living/simple_animal/hostile/megafauna/legion/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/legion)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	boss_mob.forceMove(run_loc_floor_bottom_left)

	var/datum/ai_controller/hostile_adapter/boss/controller = boss_mob.ai_controller
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	boss_mob.ranged_cooldown = 0

	//взвешенная колода детерминирована, когда доступна ровно одна запись:
	//остальные глушим их же кулдауном
	var/list/attack_table = controller.blackboard[BB_AI_BOSS_ATTACKS]
	var/datum/boss_attack/skull_entry
	for(var/datum/boss_attack/entry as anything in attack_table)
		if(entry.name == "legion skull")
			skull_entry = entry
		else
			entry.next_use_time = world.time + 10 MINUTES
	TEST_ASSERT_NOTNULL(skull_entry, "Sanity: legion table must contain the skull entry")

	var/datum/ai_planning_subtree/boss_ability_selection/selector = GLOB.ai_subtrees[/datum/ai_planning_subtree/boss_ability_selection]
	selector.SelectBehaviors(controller, 0.5)
	var/datum/boss_attack/chosen = controller.blackboard[BB_AI_BOSS_CHOSEN_ATTACK]
	TEST_ASSERT_NOTNULL(chosen, "The selector must choose an attack")
	TEST_ASSERT_EQUAL(chosen, skull_entry, "The deck must pick the only available entry")

	//исполнение: скалл легиона реально спавнится
	var/datum/ai_behavior/boss_use_attack/executor = GET_AI_BEHAVIOR(/datum/ai_behavior/boss_use_attack)
	var/verdict = executor.perform(0.5, controller, BB_AI_BOSS_CHOSEN_ATTACK, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "Executing the chosen attack must succeed")
	TEST_ASSERT(boss_mob.ranged_cooldown > world.time, "Execution must arm the boss's global pacing")
	TEST_ASSERT(chosen.next_use_time > world.time, "Execution must arm the entry's own cooldown")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_BOSS_LAST_ATTACK], skull_entry, "Execution must record the entry for the deck's anti-repeat")

	var/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion/skull = locate() in range(3, boss_mob)
	TEST_ASSERT_NOTNULL(skull, "The legacy skull-spawn proc must have actually run")

	controller.CancelActions()

///Гард двойного огня: AttackingTarget мегафауны с таблицей не зовёт OpenFire
///(субъект - вендиго: он не переопределяет AttackingTarget)
/datum/unit_test/ai_boss_no_double_fire/Run()
	var/mob/living/simple_animal/hostile/megafauna/wendigo/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/wendigo)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	boss_mob.forceMove(run_loc_floor_bottom_left)
	boss_mob.target = prey
	boss_mob.ranged_cooldown = 0
	boss_mob.recovery_time = 0

	boss_mob.AttackingTarget()

	//легаси-автозалп выставил бы ranged_cooldown; с таблицей он молчит
	TEST_ASSERT(boss_mob.ranged_cooldown <= world.time, "AttackingTarget with an active table must not auto-fire OpenFire")

///Активная спецфаза не может поставить вторую способность в очередь.
/datum/unit_test/ai_boss_busy_phase_gate/Run()
	var/mob/living/simple_animal/hostile/megafauna/dragon/drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/hostile_adapter/boss/controller = drake.ai_controller
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	drake.ranged_cooldown = 0
	drake.swooping = TRUE

	var/datum/ai_planning_subtree/boss_ability_selection/selector = GLOB.ai_subtrees[/datum/ai_planning_subtree/boss_ability_selection]
	selector.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_BOSS_CHOSEN_ATTACK], "A swooping drake must not select another ability")

///Recovery side effects из старого OpenFire выполняются перед реальным исполнением.
/datum/unit_test/ai_boss_recovery_parity/Run()
	var/mob/living/simple_animal/hostile/megafauna/wendigo/wendigo = allocate(/mob/living/simple_animal/hostile/megafauna/wendigo)
	var/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner/miner = allocate(/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner)
	wendigo.recovery_time = 0
	miner.recovery_time = 0

	wendigo.ai_ability_prelude()
	miner.ai_ability_prelude()
	TEST_ASSERT(wendigo.recovery_time > 0, "Wendigo controller attacks must retain SetRecoveryTime from OpenFire")
	TEST_ASSERT(miner.recovery_time > 0, "Demonic miner controller attacks must retain SetRecoveryTime from OpenFire")

///An asynchronous spiral must not leave projectiles retaining a deleted/nullspaced colossus.
/datum/unit_test/ai_colossus_nullspace_projectile_guard/Run()
	var/mob/living/simple_animal/hostile/megafauna/colossus/colossus = allocate(/mob/living/simple_animal/hostile/megafauna/colossus, run_loc_floor_bottom_left)
	var/turf/marker = get_step(colossus, EAST)
	colossus.moveToNullspace()

	TEST_ASSERT(!colossus.shoot_projectile(marker, 45), "A nullspaced colossus must refuse to create a projectile")

///A Rogue Process can be deleted while its plasma cutter is telegraphing.
///The delayed shot must stop before constructing a projectile in nullspace.
/datum/unit_test/ai_rogue_process_qdeleted_projectile_guard/Run()
	var/mob/living/simple_animal/hostile/megafauna/rogueprocess/rogue = new(run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)

	INVOKE_ASYNC(rogue, TYPE_PROC_REF(/mob/living/simple_animal/hostile/megafauna/rogueprocess, plasmashot), prey)
	sleep(1)
	qdel(rogue)
	TEST_ASSERT(QDELETED(rogue), "Sanity: the Rogue Process must be deleted during the plasma telegraph")
	sleep(3)

///NPC arena targets have no client or screen object, but may still receive the
///Seedling's beam status. Its periodic facing update must remain a safe no-op.
/datum/unit_test/ai_seedling_beam_indicator_without_client/Run()
	var/mob/living/simple_animal/hostile/jungle/seedling/seedling = allocate(/mob/living/simple_animal/hostile/jungle/seedling, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/megafauna/colossus/prey = allocate(/mob/living/simple_animal/hostile/megafauna/colossus, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/status_effect/seedling_beam_indicator/indicator = prey.apply_status_effect(/datum/status_effect/seedling_beam_indicator, seedling)

	TEST_ASSERT_NOTNULL(indicator, "A clientless living target must retain the beam status for normal attack cleanup")
	TEST_ASSERT_NULL(indicator.seedling_screen_object, "A clientless target must not allocate a HUD indicator")
	indicator.tick()

///The arena may delete a Drakeling during its fire-breath telegraph.
/datum/unit_test/ai_drakeling_qdeleted_fire_spew_guard/Run()
	var/mob/living/simple_animal/hostile/asteroid/elite/drakeling/drakeling = new(run_loc_floor_bottom_left)

	INVOKE_ASYNC(drakeling, TYPE_PROC_REF(/mob/living/simple_animal/hostile/asteroid/elite/drakeling, fire_spew))
	sleep(1)
	qdel(drakeling)
	TEST_ASSERT(QDELETED(drakeling), "Sanity: the Drakeling must be deleted during the fire-breath telegraph")
	sleep(5)

///The AI-held saw must skip allies in its arc and hold fire through an allied line.
/datum/unit_test/ai_blood_miner_filters_friendly_fire/Run()
	var/turf/ally_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/turf/prey_turf = get_step(ally_turf, EAST)
	var/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/miner = allocate(/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/ally = allocate(/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner, ally_turf)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)

	TEST_ASSERT(!miner.miner_saw.can_cleave_target(miner, ally), "The miner's cleave must skip a same-faction mob")
	TEST_ASSERT(miner.miner_saw.can_cleave_target(miner, prey), "The miner's cleave must retain a valid hostile target")
	TEST_ASSERT(miner.CheckFriendlyFire(prey), "An ally between the miner and prey must block the kinetic shot")

	miner.target = prey
	miner.ranged_cooldown = world.time
	miner.shoot_ka()
	TEST_ASSERT_EQUAL(miner.ranged_cooldown, world.time, "Holding fire must not consume the miner's ranged cooldown")

///Queued attacks must not run block/parry inventory logic on a qdeleted mob.
/datum/unit_test/ai_qdeleted_mob_ignores_block_checks/Run()
	var/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner/doomed = new(run_loc_floor_bottom_left)
	qdel(doomed)
	TEST_ASSERT(QDELETED(doomed), "Sanity: the miner must be qdeleted before the queued block check")
	TEST_ASSERT_EQUAL(doomed.do_run_block(TRUE, null, 8, "test attack", ATTACK_TYPE_MELEE, 0, null, null, list()), BLOCK_NONE, "A qdeleted mob must ignore queued block checks")

/// A boss callback can already be queued when its pawn is deleted. It must not
/// create a nullspace projectile and then attach a timer to that projectile.
/datum/unit_test/ai_frost_miner_qdeleted_attack_guard/Run()
	var/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner/miner = new(run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	miner.target = prey
	qdel(miner)

	miner.frost_orbs(0, 1)
	var/datum/boss_attack/attack = new("qdeleted attack", TYPE_PROC_REF(/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner, frost_orbs), 1 SECONDS, 1, 0, INFINITY, 0, 1, list(0, 1))
	TEST_ASSERT(!attack.execute(miner, prey), "A boss attack entry must reject a qdeleted pawn")
	qdel(attack)

/// Candy's recursive charge callback may already be queued when the boss dies.
/// It must neither touch nullspace nor enqueue another callback on a qdeleted mob.
/datum/unit_test/ai_candy_qdeleted_charge_guard/Run()
	var/mob/living/simple_animal/hostile/asteroid/elite/candy/candy = new(run_loc_floor_bottom_left)
	qdel(candy)

	candy.blood_charge_2(EAST, 0)
	TEST_ASSERT_NULL(candy.blood_charge_timer_id, "A qdeleted Candy queued another blood charge timer")

/// A target can enter nullspace while the trap/charge coroutine is sleeping.
/datum/unit_test/ai_candy_nullspace_trap_guard/Run()
	var/mob/living/simple_animal/hostile/asteroid/elite/candy/candy = allocate(/mob/living/simple_animal/hostile/asteroid/elite/candy, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	prey.moveToNullspace()

	TEST_ASSERT(!candy.bloodytrap(prey), "Candy must reject a nullspaced trap target")

/// Queued controller actions and attack coroutines must stop when Hierophant is
/// deleted instead of spawning visuals or timers from nullspace.
/datum/unit_test/ai_hierophant_qdeleted_attack_guard/Run()
	var/mob/living/simple_animal/hostile/megafauna/hierophant/hierophant = new(run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	hierophant.target = prey
	qdel(hierophant)

	hierophant.OpenFire()
	hierophant.diagonal_blasts(prey)
	TEST_ASSERT(QDELETED(hierophant), "The qdeleted Hierophant attack guard changed deletion state")

///Frequent retargeting must not make every InteQ civilian call guards every plan.
/datum/unit_test/ai_inteq_civilian_guard_call_cooldown/Run()
	var/mob/living/simple_animal/hostile/syndicate/civilian/civilian = allocate(/mob/living/simple_animal/hostile/syndicate/civilian, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	civilian.target = prey

	civilian.Aggro()
	var/first_guard_call = civilian.next_guard_call
	TEST_ASSERT(first_guard_call > world.time, "The first guard call must arm its cooldown")

	civilian.Aggro()
	TEST_ASSERT_EQUAL(civilian.next_guard_call, first_guard_call, "Retargeting during cooldown must not call guards again")
