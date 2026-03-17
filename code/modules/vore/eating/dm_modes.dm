/atom/var/vore_status_flags

/datum/dm_mode
	var/dm_mode_id = "fuck"
	var/dm_mode_flags = NONE
	var/list/sounds = list()

/datum/dm_mode/proc/mode_process(obj/new_belly/target_belly)
