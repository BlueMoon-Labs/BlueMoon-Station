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

/// Атом, удалённый жёстко, пока ждал сглаживания, оставляет в очереди null: проход его пропускает.
/datum/unit_test/icon_smooth_skips_deleted_atoms

/datum/unit_test/icon_smooth_skips_deleted_atoms/Run()
	var/saved_can_fire = detach_subsystem(SSicon_smooth)
	var/list/saved_queue = SSicon_smooth.smooth_queue
	var/list/saved_deferred = SSicon_smooth.deferred
	var/obj/structure/window/doomed = allocate(/obj/structure/window, run_loc_floor_bottom_left)
	qdel(doomed)
	SSicon_smooth.smooth_queue = list(null, doomed)
	SSicon_smooth.deferred = list()
	// A spent tick budget may stop fire() after either deleted entry.
	for(var/slice in 1 to 2)
		SSicon_smooth.state = SS_RUNNING
		SSicon_smooth.fire()
		if(!length(SSicon_smooth.smooth_queue) && !length(SSicon_smooth.deferred))
			break
	var/list/leftover = SSicon_smooth.smooth_queue + SSicon_smooth.deferred
	SSicon_smooth.smooth_queue = saved_queue
	SSicon_smooth.deferred = saved_deferred
	release_subsystem(SSicon_smooth, (length(saved_queue) || length(saved_deferred)) ? TRUE : saved_can_fire)
	TEST_ASSERT(!length(leftover), "в очереди сглаживания остались удалённые атомы")

/// Маяк руины брал общий экземпляр события из runnable_events и оставался в его linked_z после удаления.
/datum/unit_test/ruin_beacon_releases_shared_event
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/ruin_beacon_releases_shared_event/proc/make_and_delete_beacon()
	var/datum/orbital_object/z_linked/beacon/ruin/beacon = new
	TEST_ASSERT_NOTNULL(beacon.ruin_event, "маяку руины не досталось события")
	var/list/record = target_record(beacon, "маяк руины после очистки уровня")
	qdel(beacon)
	return record

/datum/unit_test/ruin_beacon_releases_shared_event/Run()
	begin_isolated_gc()
	var/list/record = make_and_delete_beacon()
	for(var/datum/ruin_event/template as anything in SSorbits.runnable_events)
		TEST_ASSERT_NULL(template.linked_z, "общий шаблон события держит маяк [template.type]")
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	scan_holders(record)
	assert_soft_collected(record)

/// Кнопки суперкруиза удаляются вместе с телом оператора, консоль не должна их держать.
/datum/unit_test/supercruise_console_forgets_deleted_actions

/datum/unit_test/supercruise_console_forgets_deleted_actions/Run()
	var/obj/machinery/computer/shuttle_flight/console = allocate(/obj/machinery/computer/shuttle_flight, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/pilot = new(run_loc_floor_bottom_left)
	console.GrantActions(pilot)
	TEST_ASSERT_EQUAL(length(console.actions), 4, "консоль выдала не все кнопки")
	qdel(pilot)
	TEST_ASSERT_NULL(console.off_action, "консоль держит удалённую кнопку отключения")
	TEST_ASSERT_NULL(console.rotate_action, "консоль держит удалённую кнопку поворота")
	TEST_ASSERT_NULL(console.place_action, "консоль держит удалённую кнопку установки")
	TEST_ASSERT_NULL(console.docker_action, "консоль держит удалённую кнопку прыжка")
	TEST_ASSERT(!length(console.actions), "в списке кнопок консоли остались удалённые")

/// Точку стыковки на руине удаляет очистка уровня, пока шаттл помнит её точкой отлёта.
/datum/unit_test/stationary_port_clears_mobile_references

/datum/unit_test/stationary_port_clears_mobile_references/Run()
	var/obj/docking_port/mobile/shuttle = locate() in SSshuttle.mobile
	TEST_ASSERT_NOTNULL(shuttle, "на карте нет ни одного шаттла")
	var/obj/docking_port/stationary/saved_previous = shuttle.previous
	var/obj/docking_port/stationary/ruin_spot = new(run_loc_floor_bottom_left)
	shuttle.previous = ruin_spot
	qdel(ruin_spot, TRUE)
	var/obj/docking_port/stationary/leftover = shuttle.previous
	shuttle.previous = saved_previous
	TEST_ASSERT_NULL(leftover, "шаттл помнит удалённую точку отлёта")

/// Призрак не получает дата-худы без явной настройки: их картинки сервер сверяет с обзором каждый тик.
/datum/unit_test/ghost_data_huds_off_by_default

/datum/unit_test/ghost_data_huds_off_by_default/Run()
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	TEST_ASSERT(!ghost.data_huds_on, "призрак без настройки включил дата-худы")
	for(var/hud_type in ghost.datahuds)
		var/datum/atom_hud/hud = GLOB.huds[hud_type]
		TEST_ASSERT(!hud.hudusers[ghost], "призрак без настройки подписан на худ [hud_type]")
	ghost.sync_data_huds()
	TEST_ASSERT(!ghost.data_huds_on, "сверка без клиента включила дата-худы")
