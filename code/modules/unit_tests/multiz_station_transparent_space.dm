/// Этаж станции, стоящий на другом этаже, показывает его сквозь космос, как space/openspace у tg на всех верхних уровнях.
/datum/unit_test/station_upper_levels_transparent_space

/datum/unit_test/station_upper_levels_transparent_space/Run()
	var/checked = 0
	for(var/file_name in flist("_maps/"))
		if(!findtext(file_name, ".json", -5))
			continue
		var/list/raw_json = json_decode(file2text("_maps/[file_name]"))
		var/list/raw_traits = raw_json["traits"]
		if(!islist(raw_traits))
			continue
		var/datum/map_config/config = load_map_config("_maps/[file_name]", error_if_missing = FALSE)
		var/list/levels = config.traits
		TEST_ASSERT(islist(levels) && length(levels) == length(raw_traits), "[file_name]: трейты уровней не загрузились")
		for(var/i in 1 to length(levels))
			var/list/level = levels[i]
			var/list/raw_level = raw_traits[i]
			if(!level[ZTRAIT_DOWN])
				continue
			checked++
			if(raw_level[ZTRAIT_TRANSPARENT_SPACE] == FALSE)
				TEST_ASSERT(!level[ZTRAIT_TRANSPARENT_SPACE], "[file_name]: уровень [i] явно отказался от прозрачного космоса, а получил его")
				continue
			TEST_ASSERT(level[ZTRAIT_TRANSPARENT_SPACE], "[file_name]: уровень [i] стоит на другом этаже, но его космос не показывает этаж снизу")
		qdel(config)
	TEST_ASSERT(checked, "Ни одна станция не нашлась многоэтажной")

/// На загруженной многоэтажной станции космос верхнего этажа берёт турф снизу в vis_contents.
/datum/unit_test/station_space_shows_lower_floor
	requires_full_map = TRUE

/datum/unit_test/station_space_shows_lower_floor/Run()
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		if(!SSmapping.z_level_below[z])
			continue
		var/opaque = 0
		var/total = 0
		var/turf/first_opaque
		for(var/turf/open/space/space_turf in Z_TURFS(z))
			if(space_turf.x <= TRANSITIONEDGE + 1 || space_turf.y <= TRANSITIONEDGE + 1 || space_turf.x >= world.maxx - TRANSITIONEDGE - 1 || space_turf.y >= world.maxy - TRANSITIONEDGE - 1)
				continue
			total++
			var/turf/below = GET_TURF_BELOW(space_turf)
			if(HAS_TRAIT(space_turf, TURF_Z_TRANSPARENT_TRAIT) && (below in space_turf.vis_contents))
				continue
			opaque++
			if(!first_opaque)
				first_opaque = space_turf
		TEST_ASSERT(!opaque, "[SSmapping.config.map_name], z=[z]: [opaque] из [total] турфов космоса не показывают этаж снизу, первый ([first_opaque?.x],[first_opaque?.y])")

/// Подписки элемента лежат в alist: удаление элемента обязано снять их со всех целей, хотя UnregisterSignal вычёркивает цель посреди обхода.
/datum/element/signal_probe

/datum/element/signal_probe/proc/on_probe(datum/source)
	SIGNAL_HANDLER

/datum/unit_test/element_signal_procs_unregister_all

/datum/unit_test/element_signal_procs_unregister_all/Run()
	var/datum/element/signal_probe/probe = new
	TEST_ASSERT(istype(probe.signal_procs, /alist), "Подписки элемента обязаны лежать в alist")
	var/list/targets = list()
	for(var/i in 1 to 6)
		var/datum/target = new
		targets += target
		probe.RegisterSignal(target, COMSIG_TURF_MULTIZ_NEW, TYPE_PROC_REF(/datum/element/signal_probe, on_probe))
	TEST_ASSERT_EQUAL(length(probe.signal_procs), 6, "Элемент обязан помнить все шесть целей")
	probe.UnregisterSignal(targets[3], COMSIG_TURF_MULTIZ_NEW)
	TEST_ASSERT_EQUAL(length(probe.signal_procs), 5, "Снятая подписка обязана вычеркнуть свою цель")
	qdel(probe, force = TRUE)
	for(var/datum/target as anything in targets)
		TEST_ASSERT(!target.comp_lookup?[COMSIG_TURF_MULTIZ_NEW], "Удалённый элемент оставил подписку на цели")
		qdel(target)
