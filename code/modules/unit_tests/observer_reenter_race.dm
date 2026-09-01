/**
 * Регрессионные тесты на гонку в do_reenter_corpse() (observer.dm).
 *
 * В проде transfer_ckey() -> new_mob.key = key -> Logout() призрака ставит
 * spawn(0) qdel(src), который успевает выполниться до возврата из transfer_ckey().
 * Destroy() обсервера зануляет mind, поэтому любое чтение src.mind после
 * переноса ключа даёт рант "Cannot read null.current" (десятки за раунд у
 * визитёров Гост-Кафе). Тесты симулируют это уничтожение синхронно через
 * COMSIG_MOB_PRE_PLAYER_CHANGE, который transfer_ckey() шлёт телу.
 */

/// Гонка: призрак уничтожается во время переноса ключа - перенос обязан завершиться без рантов
/datum/unit_test/reenter_corpse_ghost_qdel_race

/datum/unit_test/reenter_corpse_ghost_qdel_race/proc/kill_ghost_mid_transfer(datum/source, mob/new_mob, mob/old_mob)
	SIGNAL_HANDLER
	// В проде к моменту спавна qdel ключ уже уехал с призрака - повторяем это,
	// иначе qdel моба с ключом уйдёт в ghostize() и наплодит новых обсерверов
	old_mob.key = null
	qdel(old_mob)

/datum/unit_test/reenter_corpse_ghost_qdel_race/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/test_mind = new()
	test_mind.transfer_to(body)

	var/mob/dead/observer/ghost = new(run_loc_floor_bottom_left)
	allocated += ghost
	ghost.mind = test_mind
	ghost.can_reenter_corpse = TRUE
	ghost.key = "unit_test_reenter"

	RegisterSignal(body, COMSIG_MOB_PRE_PLAYER_CHANGE, PROC_REF(kill_ghost_mid_transfer))
	var/result = ghost.do_reenter_corpse()
	UnregisterSignal(body, COMSIG_MOB_PRE_PLAYER_CHANGE)

	TEST_ASSERT(QDELETED(ghost), "Симуляция гонки не сработала: призрак должен быть уничтожен внутри transfer_ckey()")
	TEST_ASSERT_EQUAL(result, TRUE, "do_reenter_corpse() оборвался рантом после уничтожения призрака во время переноса ключа")

	body.key = null // иначе qdel тела в teardown уйдёт в ghostize()

/// Обычный путь без гонки: ключ доезжает до тела, призрак удаляется, рантов нет
/datum/unit_test/reenter_corpse_clean_path

/datum/unit_test/reenter_corpse_clean_path/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/test_mind = new()
	test_mind.transfer_to(body)

	var/mob/dead/observer/ghost = new(run_loc_floor_bottom_left)
	allocated += ghost
	ghost.mind = test_mind
	ghost.can_reenter_corpse = TRUE
	ghost.key = "unit_test_reenter"

	var/result = ghost.do_reenter_corpse()

	TEST_ASSERT_EQUAL(result, TRUE, "do_reenter_corpse() оборвался рантом на пути без клиента (deref client без ?.)")
	TEST_ASSERT_EQUAL(body.key, "unit_test_reenter", "Ключ призрака не доехал до тела")
	TEST_ASSERT(QDELETED(ghost), "Призрак не был удалён после возврата в тело")

	body.key = null // иначе qdel тела в teardown уйдёт в ghostize()
