/datum/dm_mode
	var/dm_mode_id = "fuck"
	var/dm_mode_flags = NONE
	var/list/sounds = list()

/datum/dm_mode/proc/check_pref(mob/mob_to_check)
	return TRUE

/datum/dm_mode/proc/mode_process(obj/new_belly/target_belly)
	if(!target_belly.owner)
		return
