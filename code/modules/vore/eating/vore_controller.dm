/datum/component/vore_controller
	var/list/new_belly/my_bellies


/datum/component/vore_controller/Initialize(...)
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/vore_controller/proc/load_bellies()
