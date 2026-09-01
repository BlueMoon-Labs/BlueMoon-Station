// Разгрузка shake_everyone() гравгена: смена состояния генератора обходила ВЕСЬ
// GLOB.mob_list синхронно в слоте SSmachines (326мс на прод-раунде). Теперь клиентские
// мобы обновляются сразу (тряска+звук+гравитация), а NPC доезжают отложенным проходом
// update_nonclient_mob_gravity() с CHECK_TICK. Тест проверяет, что отложенный проход
// реально доносит смену гравитации до NPC (наблюдаемо через алерт невесомости).

/datum/unit_test/deferred_npc_gravity_update/Run()
	var/mob/living/carbon/human/npc = allocate(/mob/living/carbon/human)

	// За пределами шаблона тест-зоны на резервном уровне - космос без гравитации.
	var/turf/weightless_turf
	for(var/turf/candidate as anything in RANGE_TURFS(15, run_loc_floor_bottom_left))
		if(isspaceturf(candidate))
			weightless_turf = candidate
			break
	TEST_ASSERT_NOTNULL(weightless_turf, "рядом с тест-зоной должен найтись космический турф")

	npc.forceMove(weightless_turf)
	TEST_ASSERT(!npc.mob_has_gravity(), "на космосе резервного уровня не должно быть гравитации")

	// Изолируем именно наш проход: сбрасываем алерт, который могло выставить само перемещение.
	npc.clear_alert("gravity")
	TEST_ASSERT_NULL(npc.alerts["gravity"], "прекондиция: алерт гравитации сброшен")

	update_nonclient_mob_gravity(weightless_turf.z)
	TEST_ASSERT_NOTNULL(npc.alerts["gravity"], "отложенный проход обязан обновить гравитацию NPC (алерт невесомости)")
