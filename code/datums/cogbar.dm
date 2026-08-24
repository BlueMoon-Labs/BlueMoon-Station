#define COGBAR_ANIMATION_TIME (0.5 SECONDS)
#define COGBAR_PIXEL_OFFSET_Y 32

/// Ported from tgstation: represents that the user is busy doing something
/datum/cogbar
	var/mob/user
	var/client/user_client
	/// The visible element to other players
	var/obj/effect/overlay/vis/cog
	/// The blank image that overlaps the cog - hides it from the source user
	var/image/blank
	var/cogicon
	var/cogiconstate


/datum/cogbar/New(mob/user, cogicon = 'icons/effects/progressbar.dmi', cogiconstate = "cog")
	src.user = user
	src.user_client = user.client
	src.cogicon = cogicon
	src.cogiconstate = cogiconstate
	if(isnull(cogicon) || isnull(cogiconstate))
		stack_trace("/datum/cogbar was created without an icon or icon state.")
		qdel(src)
		return

	add_cog_to_user()

	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_user_delete))


/datum/cogbar/Destroy()
	if(user)
		if(cog)
			SSvis_overlays.remove_vis_overlay(user, list(cog))
		user_client?.images -= blank

	user = null
	user_client = null
	cog = null
	QDEL_NULL(blank)

	return ..()


/datum/cogbar/proc/add_cog_to_user()
	cog = SSvis_overlays.add_vis_overlay(user, cogicon, cogiconstate, ABOVE_MOB_LAYER, HIGH_GAME_PLANE, user.dir, alpha = 0, add_appearance_flags = APPEARANCE_UI_IGNORE_ALPHA, unique = TRUE)
	cog.pixel_y = COGBAR_PIXEL_OFFSET_Y
	animate(cog, alpha = user.alpha, time = COGBAR_ANIMATION_TIME)

	if(isnull(user_client))
		return

	blank = image('icons/blanks/32x32.dmi', cog, "nothing")
	SET_PLANE_EXPLICIT(blank, HIGH_GAME_PLANE, user)
	blank.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	blank.override = TRUE

	user_client.images += blank


/datum/cogbar/proc/remove()
	if(isnull(cog))
		qdel(src)
		return

	animate(cog, alpha = 0, time = COGBAR_ANIMATION_TIME)

	QDEL_IN(src, COGBAR_ANIMATION_TIME)


/datum/cogbar/proc/on_user_delete(datum/source)
	SIGNAL_HANDLER

	qdel(src)


#undef COGBAR_ANIMATION_TIME
#undef COGBAR_PIXEL_OFFSET_Y
