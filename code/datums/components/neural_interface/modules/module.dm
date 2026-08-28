/datum/neural_interface_module
	var/name = "EMPTY MODULE"
	var/datum/component/neural_interface/owner
	var/visible = TRUE

/datum/neural_interface_module/New(datum/component/neural_interface/new_owner)
	. = ..()
	// Аргумент назывался owner и присваивался сам себе, поэтому src.owner оставался null
	// навсегда. Из-за этого гард `if(owner?.host_mob)` в Destroy() не срабатывал ни разу:
	// экранные объекты панелей не снимались с client.screen, а модуль подсветки не чистил
	// свои записи.
	owner = new_owner

/datum/neural_interface_module/proc/UpdateVision(mob/user)
	if(!visible)
		return FALSE
	return TRUE

/datum/neural_interface_module/proc/hide_module(mob/user)
	if(!visible)
		return FALSE
	visible = FALSE
	return TRUE

/datum/neural_interface_module/proc/view_module(mob/user)
	if(visible)
		return FALSE
	visible = TRUE
	return TRUE

/datum/neural_interface_module/Destroy(force, ...)
	if(owner?.host_mob)
		hide_module(owner.host_mob)
		UpdateVision(owner.host_mob)
	owner = null
	. = ..()
