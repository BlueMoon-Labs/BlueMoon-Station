///like normal callbacks but they also record their creation time for measurement purposes.
///they also require the user to still exist with a client when invoked (the base
////datum/callback already stores the creating usr as a weakref and restores it
///through world.PushUsr on deferred invocation).
/datum/callback/verb_callback
	var/creation_time = 0

/datum/callback/verb_callback/New(thingtocall, proctocall, ...)
	creation_time = DS2TICKS(world.time)
	. = ..()

#ifndef UNIT_TESTS // unit tests invoke these without clients attached
/datum/callback/verb_callback/Invoke(...)
	var/mob/our_user = user?.resolve()
	if(QDELETED(our_user) || isnull(our_user.client))
		return
	return ..()

/datum/callback/verb_callback/InvokeAsync(...)
	var/mob/our_user = user?.resolve()
	if(QDELETED(our_user) || isnull(our_user.client))
		return
	return ..()
#endif
