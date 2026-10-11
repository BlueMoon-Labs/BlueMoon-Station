/// На z-уровне ЦК нет стартовых активных турфов: каждый такой - замапленный градиент газа.
/datum/unit_test/centcom_roundstart_active_turfs/Run()
	var/list/centcom_levels = SSmapping.levels_by_trait(ZTRAIT_CENTCOM)
	TEST_ASSERT(length(centcom_levels), "Нет z-уровня ЦК")
	var/list/offenders = list()
	for(var/turf/open/active_turf in GLOB.active_turfs_startlist)
		if(active_turf.z in centcom_levels)
			offenders += "[active_turf.type] [AREACOORD(active_turf)]"
	TEST_ASSERT(!length(offenders), "Стартовые активные турфы на ЦК ([length(offenders)]): [jointext(offenders, "; ")]")
