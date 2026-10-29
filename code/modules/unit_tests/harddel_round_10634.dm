/// Регрессии по hard delete из прод-раунда 10634 (2026-10-29).

/// VR-аватар, удалённый напрямую (новый сеанс в капсуле, разбор капсулы), из сигнала
/// своего же удаления попадал в corpse_party уборщика VR-зоны и держался там до его
/// следующего прохода раз в 3 минуты. В проде так уходили в warnfail люди с одной ссылкой.
/datum/unit_test/vr_avatar_qdel_releases_corpse_party
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/vr_avatar_qdel_releases_corpse_party/proc/delete_avatar()
	var/mob/living/carbon/human/avatar = new(run_loc_floor_bottom_left)
	avatar.mind_initialize()
	avatar.AddComponent(/datum/component/virtual_reality)
	var/list/record = target_record(avatar, "VR-аватар, удалённый напрямую")
	qdel(avatar)
	return record

/datum/unit_test/vr_avatar_qdel_releases_corpse_party/Run()
	var/obj/effect/vr_clean_master/cleanbot = allocate(/obj/effect/vr_clean_master, run_loc_floor_bottom_left)
	TEST_ASSERT(!QDELETED(cleanbot), "уборщику VR-зоны не нашлось зоны")
	begin_isolated_gc()
	var/list/record = delete_avatar()
	TEST_ASSERT(!LAZYLEN(cleanbot.corpse_party), "удаляемый аватар попал в corpse_party уборщика")
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	scan_holders(record)
	assert_soft_collected(record)

/// Уборщик VR-зоны заводил новый таймер на каждом проходе поверх TIMER_LOOP,
/// и цепочки проходов копились с каждым циклом петли.
/datum/unit_test/vr_clean_master_single_timer

/datum/unit_test/vr_clean_master_single_timer/Run()
	var/obj/effect/vr_clean_master/cleanbot = allocate(/obj/effect/vr_clean_master, run_loc_floor_bottom_left)
	TEST_ASSERT(!QDELETED(cleanbot), "уборщику VR-зоны не нашлось зоны")
	var/timers_before = length(cleanbot.active_timers)
	cleanbot.clean_up()
	TEST_ASSERT_EQUAL(length(cleanbot.active_timers), timers_before, "проход уборщика завёл лишний таймер")

/// Держатель параллакса живёт у клиента. Игрок, ушедший призраком в лобби, параллакс больше
/// не пересчитывает, и удалённый призрак оставался в cached_eye, пока клиент сидел в лобби.
/datum/unit_test/parallax_holder_releases_deleted_eye
	parent_type = /datum/unit_test/harddel_9813_base

/datum/parallax_holder/unit_test_probe/New()
	return

/datum/unit_test/parallax_holder_releases_deleted_eye/proc/watch_and_delete(datum/parallax_holder/holder)
	var/mob/dead/observer/ghost = new(run_loc_floor_bottom_left)
	holder.set_cached_eye(ghost)
	var/list/record = target_record(ghost, "призрак, оставшийся глазом параллакса")
	qdel(ghost)
	return record

/datum/unit_test/parallax_holder_releases_deleted_eye/Run()
	var/datum/parallax_holder/unit_test_probe/holder = allocate(/datum/parallax_holder/unit_test_probe)
	begin_isolated_gc()
	var/list/record = watch_and_delete(holder)
	TEST_ASSERT_NULL(holder.cached_eye, "держатель параллакса держит удалённый глаз")
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	scan_holders(record)
	assert_soft_collected(record)
