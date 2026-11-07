/// TRUE, если у разума есть роль антагониста. Не в счёт только гост-роли, ОБР, официальные лица, похищенные, валентинки, аварийные ассистенты ЦК, учебные роли полигона и братство own_team
/proc/brother_mind_is_antagonist(datum/mind/checked, datum/team/brother_team/own_team)
	var/static/list/not_antagonists = typecacheof(list(/datum/antagonist/ghost_role, /datum/antagonist/ert, /datum/antagonist/official, /datum/antagonist/abductee, /datum/antagonist/valentine, /datum/antagonist/heartbreaker, /datum/antagonist/greybois, /datum/antagonist/brother/training, /datum/antagonist/heretic/training))
	for(var/datum/antagonist/antag as anything in checked?.antag_datums)
		if(is_type_in_typecache(antag, not_antagonists))
			continue
		var/datum/antagonist/brother/brother_antag = antag
		if(own_team && istype(brother_antag) && brother_antag.team == own_team)
			continue
		return TRUE
	return FALSE
