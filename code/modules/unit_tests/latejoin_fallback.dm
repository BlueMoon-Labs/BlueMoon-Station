/// Латеджойнер на карте без кресел и зоны шаттла прибытия попадает в комнату ошибок ЦК, а не в нуллспейс.
/datum/unit_test/latejoin_without_arrivals_lands_somewhere
	allowed_runtime_patterns = list("Unable to find last resort spawn point")

/datum/unit_test/latejoin_without_arrivals_lands_somewhere/Run()
	var/list/saved_trackers = SSjob.latejoin_trackers
	var/list/saved_areas = GLOB.sortedAreas
	var/area/saved_arrivals = GLOB.areas_by_type[/area/shuttle/arrival]
	var/list/areas_without_arrivals = list()
	for(var/area/station_area as anything in saved_areas)
		if(!istype(station_area, /area/shuttle/arrival))
			areas_without_arrivals += station_area
	SSjob.latejoin_trackers = list()
	GLOB.sortedAreas = areas_without_arrivals
	GLOB.areas_by_type[/area/shuttle/arrival] = null

	var/mob/living/carbon/human/latejoiner = allocate(/mob/living/carbon/human)
	latejoiner.moveToNullspace()
	SSjob.SendToLateJoin(latejoiner)
	var/turf/landed = get_turf(latejoiner)

	SSjob.latejoin_trackers = saved_trackers
	GLOB.sortedAreas = saved_areas
	GLOB.areas_by_type[/area/shuttle/arrival] = saved_arrivals
	TEST_ASSERT_NOTNULL(landed, "Латеджойнер без точки прибытия остался в нуллспейсе")
