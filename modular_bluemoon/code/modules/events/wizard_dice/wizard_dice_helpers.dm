/// Picks a safe open turf on the station near where active crew already are (ported from WhiteMoon wizard dice).
/proc/get_safe_lucky_player_turf(list/mobs_to_check, list/mobs_to_exclude, list/areas_to_exclude)
	var/list/list_to_check
	if(islist(mobs_to_check) && length(mobs_to_check))
		list_to_check = mobs_to_check.Copy()
	else
		list_to_check = list()
		for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
			if(H.client)
				list_to_check += H
	shuffle_inplace(list_to_check)
	if(length(mobs_to_exclude))
		list_to_check -= mobs_to_exclude

	if(!length(list_to_check))
		return get_safe_random_station_turf()

	for(var/mob/living/player_mob as anything in list_to_check)
		if(!player_mob?.mind || !player_mob.client)
			continue
		if(player_mob.client.is_afk())
			continue
		var/datum/job/player_job = SSjob.GetJob(player_mob.mind.assigned_role)
		if(!player_job || player_job.faction != "Station")
			continue
		var/turf/player_turf = get_turf(player_mob)
		if(!player_turf)
			continue
		var/area/player_area = get_area(player_turf)
		if(length(areas_to_exclude) && (player_area in areas_to_exclude))
			continue
		var/turf/found_turf = get_safe_random_station_turf(list(player_area))
		if(!found_turf)
			continue
		return found_turf

	return get_safe_random_station_turf()
