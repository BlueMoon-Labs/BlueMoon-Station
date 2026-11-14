/// Каждый сектор грузится и выгружается, не оставляя следов в глобальных реестрах раунда.
/datum/unit_test/antag_training_sector_leaks/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	for(var/sector_id in arena.sectors)
		var/datum/antag_training_sector/sector = arena.sectors[sector_id]
		var/list/before = antag_training_global_snapshot()
		TEST_ASSERT(sector.load(), "[sector_id]: сектор загружается.")
		var/list/loaded = antag_training_global_snapshot()
		for(var/key in list("nuke", "poi", "gps", "spawners", "ai_cores", "start_landmarks", "shuttle_callers", "consoles", "casters", "rnd_servers", "mechs", "station_cameras", "ai_shells", "science_budget"))
			TEST_ASSERT_EQUAL(loaded[key], before[key], "[sector_id]: загрузка не добавляет [key].")
		for(var/obj/machinery/camera/camera as anything in GLOB.cameranet.cameras)
			if(arena.owns_area(get_area(camera)))
				TEST_ASSERT(length(camera.network) == 1 && camera.network[1] == "training", "[sector_id]: камера [camera.c_tag] только в учебной сети.")
		var/list/shared_wiring = list()
		var/list/tracked_gps = list()
		for(var/turf/tile as anything in sector.turfs)
			for(var/obj/thing as anything in tile.GetAllContents(/obj))
				var/datum/wires/wires = thing.wires
				for(var/wire_key in GLOB.wire_color_directory)
					if(wires?.colors == GLOB.wire_color_directory[wire_key])
						shared_wiring |= thing.type
				var/datum/component/gps/gps = thing.GetComponent(/datum/component/gps)
				if(gps?.tracking)
					tracked_gps |= thing.type
		TEST_ASSERT(!length(shared_wiring), "[sector_id]: раскладка проводов раунда у [shared_wiring.Join(", ")].")
		TEST_ASSERT(!length(tracked_gps), "[sector_id]: GPS сектора видны станции: [tracked_gps.Join(", ")].")
		sector.unload()
		var/list/after = antag_training_global_snapshot()
		for(var/key in before)
			TEST_ASSERT_EQUAL(after[key], before[key], "[sector_id]: выгрузка возвращает [key].")

/proc/antag_training_global_snapshot()
	var/station_cameras = 0
	for(var/obj/machinery/camera/camera as anything in GLOB.cameranet.cameras)
		if("ss13" in camera.network)
			station_cameras++
	var/tracking_gps = 0
	for(var/datum/component/gps/gps as anything in GLOB.GPS_list)
		if(gps.tracking)
			tracking_gps++
	var/datum/bank_account/science = SSeconomy.get_dep_account(ACCOUNT_SCI)
	return list("science_budget" = science?.account_balance, "nuke" = length(GLOB.nuke_list), "poi" = length(GLOB.poi_list), "gps" = tracking_gps, "spawners" = length(GLOB.mob_spawners), "ai_cores" = length(GLOB.ai_cores), "start_landmarks" = length(GLOB.start_landmarks_list), "shuttle_callers" = length(GLOB.shuttle_caller_list), "consoles" = length(GLOB.allConsoles), "casters" = length(GLOB.allCasters), "rnd_servers" = length(SSresearch.servers), "mechs" = length(GLOB.mechas_list), "station_cameras" = station_cameras, "ai_shells" = length(GLOB.available_ai_shells), "apcs" = length(GLOB.apcs_list), "cables" = length(GLOB.cable_list), "airlocks" = length(GLOB.airlocks), "powernets" = length(SSmachines.powernets))
