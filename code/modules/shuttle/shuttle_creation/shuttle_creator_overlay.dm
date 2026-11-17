/*
 * Manages the overlays for the shuttle creator drone.
*/

/datum/shuttle_creator_overlay_holder
	var/client/holder
	var/list/images = list()
	var/list/turfs = list()

/datum/shuttle_creator_overlay_holder/proc/add_client(client/C)
	remove_client()
	if(!C)
		return
	holder = C
	holder.images += images
	// Подсветку снимают только сменой пользователя: вышедший из игры держался бы здесь до конца раунда.
	RegisterSignal(holder, COMSIG_PARENT_QDELETING, PROC_REF(remove_client))

/datum/shuttle_creator_overlay_holder/proc/remove_client()
	SIGNAL_HANDLER
	if(holder)
		UnregisterSignal(holder, COMSIG_PARENT_QDELETING)
		holder.images -= images
		holder = null

/datum/shuttle_creator_overlay_holder/proc/clear_highlights()
	if(holder)
		holder.images -= images
	images.Cut()
	turfs.Cut()

/datum/shuttle_creator_overlay_holder/proc/create_hightlight(turf/T)
	if(T in turfs)
		return
	var/image/I = image('icons/turf/overlays.dmi', T, "greenOverlay")
	I.plane = BYOND_LIGHTING_PLANE
	images += I
	holder?.images += I
	turfs += T

/datum/shuttle_creator_overlay_holder/proc/remove_hightlight(turf/T)
	if(!(T in turfs))
		return
	turfs -= T
	holder?.images -= images
	for(var/image/I in images)
		if(get_turf(I) != T)
			continue
		images -= I
	holder?.images += images

/datum/shuttle_creator_overlay_holder/proc/highlight_area(list/turfs)
	for(var/turf/T in turfs)
		highlight_turf(T)

/datum/shuttle_creator_overlay_holder/proc/highlight_turf(turf/T)
	create_hightlight(T)

/datum/shuttle_creator_overlay_holder/proc/unhighlight_turf(turf/T)
	remove_hightlight(T)
