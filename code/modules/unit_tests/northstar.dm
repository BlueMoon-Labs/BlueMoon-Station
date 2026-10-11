/// На NorthStar пол над кабинетами под хелпером усиленного потолка лежит на усиленном настиле.
/datum/unit_test/northstar_reinforced_ceilings
	requires_full_map = TRUE

/datum/unit_test/northstar_reinforced_ceilings/Run()
	if(SSmapping.config.map_name != "NorthStar")
		return
	var/list/unprotected = list()
	var/checked = 0
	for(var/turf/below as anything in get_area_turfs(/area/ai_monitored/turret_protected/ai_upload))
		var/turf/ceiling = get_step_multiz(below, UP)
		if(isnull(ceiling) || isspaceturf(ceiling) || istype(ceiling, /turf/open/openspace) || isclosedturf(ceiling))
			continue
		checked++
		var/list/stack = islist(ceiling.baseturfs) ? ceiling.baseturfs : list(ceiling.baseturfs)
		if(!(/turf/open/floor/plating/reinforced in stack) && !istype(ceiling, /turf/open/floor/plating/reinforced))
			unprotected += "[ceiling.x],[ceiling.y],[ceiling.z]"
	TEST_ASSERT(checked, "Над аплоудом ИИ не нашлось ни одного пола")
	TEST_ASSERT(!length(unprotected), "Пол над аплоудом ИИ без усиленного настила ([length(unprotected)]): [unprotected.Join(", ")]")
