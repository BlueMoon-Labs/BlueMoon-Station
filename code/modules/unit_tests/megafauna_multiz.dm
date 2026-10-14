/// Пикирование дрейка не гонится за целью на другом этаже и бросает ушедшую туда на лету.
/datum/unit_test/megafauna_drake_swoop_keeps_floor

/datum/unit_test/megafauna_drake_swoop_keeps_floor/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/start = locate(60, 60, levels[1])
	var/mob/living/simple_animal/hostile/megafauna/dragon/drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon, start)
	drake.toggle_ai(AI_OFF)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(66, 62, levels[2]))

	drake.swoop_attack(FALSE, prey, 40)
	TEST_ASSERT_EQUAL(drake.loc, start, "Дрейк пикировал к цели на другом этаже и долетел под неё")

	prey.forceMove(locate(66, 62, levels[1]))
	INVOKE_ASYNC(drake, TYPE_PROC_REF(/mob/living/simple_animal/hostile/megafauna/dragon, swoop_attack), FALSE, prey, 40)
	sleep(12)
	prey.forceMove(locate(66, 62, levels[2]))
	TEST_ASSERT(wait_for_var(drake, "swooping", NONE, 6 SECONDS), "Пикирование не закончилось")
	TEST_ASSERT_EQUAL(drake.z, levels[1], "Дрейк сменил этаж в пикировании")
	TEST_ASSERT(drake.x != prey.x || drake.y != prey.y, "Дрейк догнал цель, ушедшую на другой этаж, и приземлился под ней")

/// Селектор способностей босса не берёт атаку против цели на другом этаже.
/datum/unit_test/megafauna_boss_ability_other_floor

/datum/unit_test/megafauna_boss_ability_other_floor/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/mob/living/simple_animal/hostile/megafauna/dragon/drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon, locate(70, 60, levels[1]))
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(76, 60, levels[2]))
	var/datum/ai_controller/hostile_adapter/boss/controller = drake.ai_controller
	var/list/attack_table = controller.blackboard[BB_AI_BOSS_ATTACKS]
	TEST_ASSERT(length(attack_table), "У дрейка нет таблицы способностей")

	for(var/datum/boss_attack/entry as anything in attack_table)
		TEST_ASSERT(!entry.is_available(drake, prey), "Атака [entry.name] доступна против цели на другом этаже")

	prey.forceMove(locate(76, 60, levels[1]))
	var/same_floor_available = FALSE
	for(var/datum/boss_attack/entry as anything in attack_table)
		if(entry.is_available(drake, prey))
			same_floor_available = TRUE
			break
	TEST_ASSERT(same_floor_available, "Санити: на одном этаже ни одна атака дрейка не доступна")

/// Иерофант не мерцает к цели на другом этаже.
/datum/unit_test/megafauna_hierophant_blink_keeps_floor

/datum/unit_test/megafauna_hierophant_blink_keeps_floor/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/start = locate(90, 60, levels[1])
	var/mob/living/simple_animal/hostile/megafauna/hierophant/hierophant = allocate(/mob/living/simple_animal/hostile/megafauna/hierophant, start)
	hierophant.toggle_ai(AI_OFF)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(96, 60, levels[2]))

	hierophant.blink(prey)
	TEST_ASSERT_EQUAL(hierophant.loc, start, "Иерофант мерцанием ушёл на другой этаж")

/// Бабблгам не уходит кровью в лужу у цели на другом этаже.
/datum/unit_test/megafauna_bubblegum_blood_warp_keeps_floor

/datum/unit_test/megafauna_bubblegum_blood_warp_keeps_floor/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/start = locate(110, 60, levels[1])
	var/turf/prey_turf = locate(116, 60, levels[2])
	start.ChangeTurf(/turf/open/floor/plasteel)
	prey_turf.ChangeTurf(/turf/open/floor/plasteel)
	var/mob/living/simple_animal/hostile/megafauna/bubblegum/bubblegum = allocate(/mob/living/simple_animal/hostile/megafauna/bubblegum, start)
	bubblegum.toggle_ai(AI_OFF)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	allocate(/obj/effect/decal/cleanable/blood, start)
	allocate(/obj/effect/decal/cleanable/blood, prey_turf)
	bubblegum.GiveTarget(prey)

	bubblegum.blood_warp()
	TEST_ASSERT_EQUAL(bubblegum.loc, start, "Бабблгам ушёл кровью на ([bubblegum.x],[bubblegum.y],[bubblegum.z])")
	start.ChangeTurf(/turf/open/space/basic)
	prey_turf.ChangeTurf(/turf/open/space/basic)

/// Вендиго не телепортируется к цели на другом этаже.
/datum/unit_test/megafauna_wendigo_teleport_keeps_floor

/datum/unit_test/megafauna_wendigo_teleport_keeps_floor/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/start = locate(130, 60, levels[1])
	var/mob/living/simple_animal/hostile/megafauna/wendigo/wendigo = allocate(/mob/living/simple_animal/hostile/megafauna/wendigo, start)
	wendigo.toggle_ai(AI_OFF)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(136, 60, levels[2]))
	wendigo.GiveTarget(prey)

	wendigo.teleport()
	TEST_ASSERT_EQUAL(wendigo.loc, start, "Вендиго телепортировался на другой этаж")

/// Пандора не телепортируется к цели на другом этаже.
/datum/unit_test/megafauna_pandora_teleport_keeps_floor

/datum/unit_test/megafauna_pandora_teleport_keeps_floor/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/start = locate(150, 60, levels[1])
	var/mob/living/simple_animal/hostile/asteroid/elite/pandora/pandora = allocate(/mob/living/simple_animal/hostile/asteroid/elite/pandora, start)
	pandora.toggle_ai(AI_OFF)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(156, 60, levels[2]))

	pandora.pandora_teleport(prey)
	var/list/budget = new_wait_budget(1 SECONDS, "pandora teleport")
	while(pandora.loc == start && wait_budget_tick(budget))
		continue
	TEST_ASSERT_EQUAL(pandora.loc, start, "Пандора телепортировалась на другой этаж")
