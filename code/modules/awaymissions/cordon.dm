/// Area used in conjunction with the cordon turf to create a fully functioning world border.
/area/misc/cordon
	name = "CORDON"
	icon_state = "cordon"
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	area_flags = NOTELEPORT|HIDDEN_AREA
	requires_power = FALSE

/area/misc/cordon/Entered(atom/movable/arrived, atom/OldLoc)
	. = ..()
	for(var/mob/living/enterer as anything in get_cordon_contents(arrived))
		to_chat(enterer, span_userdanger("This was a bad idea..."))
		enterer.dust(just_ash = TRUE, drop_items = FALSE, force = TRUE)

/area/misc/cordon/proc/get_cordon_contents(atom/holder)
	var/list/results = list()
	if(istype(holder, /mob/living))
		results += holder
	for(var/atom/movable/thing as anything in holder.contents)
		results += get_cordon_contents(thing)
	return results