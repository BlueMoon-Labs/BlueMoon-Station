/**
 * Optical sources publish a physical viewpoint and its native vision settings.
 * Consoles keep routing, authorization and viewer state; sources decide whether a live feed exists.
 */
/atom/proc/netrun_view_capable()
	return FALSE

/atom/proc/netrun_view_target()
	return null

/atom/proc/netrun_view_settings()
	return list("see_in_dark" = 2, "sight" = 0, "see_invisible" = SEE_INVISIBLE_LIVING)

/mob
	/// A viewer has one active optical session, even when using several consoles.
	var/datum/netrun_console/netrun_watch_console

// Cameras retain their recording switch, EMP state and generic node lockout.
/obj/machinery/camera/netrun_view_capable()
	return TRUE

/obj/machinery/camera/netrun_view_target()
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(!status || !can_use() || !node?.is_online())
		return null
	return src

/obj/machinery/camera/netrun_view_settings()
	. = ..()
	.["see_in_dark"] = 7
	.["sight"] = isXRay() ? (SEE_TURFS | SEE_MOBS | SEE_OBJS) : 0

// The cybernetics node carries the eyes' stream; another node on the wearer is unnecessary.
/mob/living/carbon/netrun_view_capable()
	var/obj/item/organ/eyes/eyes = getorganslot(ORGAN_SLOT_EYES)
	return istype(eyes) && eyes.netrun_is_cyber()

/mob/living/carbon/netrun_view_target()
	if(stat == DEAD || !netrun_cyber_uplink_available() || !netrun_view_capable())
		return null
	var/obj/item/organ/eyes/eyes = getorganslot(ORGAN_SLOT_EYES)
	if(eyes.owner != src || (eyes.organ_flags & ORGAN_FAILING) || eyes.netrun_suppressed())
		return null
	return src

/mob/living/carbon/netrun_view_settings()
	. = ..()
	if(!netrun_view_capable())
		return
	var/obj/item/organ/eyes/eyes = getorganslot(ORGAN_SLOT_EYES)
	.["see_in_dark"] = eyes.see_in_dark
	.["sight"] = eyes.sight_flags
	.["see_invisible"] = eyes.see_invisible

// HUD glasses have a remote lens only after the existing firmware/emag mechanism is used.
/obj/item/clothing/glasses/hud/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_OPTIC, list("reboot"), 3, list())

/obj/item/clothing/glasses/hud/netrun_owner_access(datum/netrun_console/console)
	var/mob/user = netrun_console_owner(console)
	return user && (user in get_nested_locs(src)) ? NETRUN_ACCESS_ROOT : NETRUN_ACCESS_NONE

/obj/item/clothing/glasses/hud/netrun_view_capable()
	return TRUE

/obj/item/clothing/glasses/hud/netrun_view_target()
	if(!(obj_flags & EMAGGED) || !ishuman(loc))
		return null
	var/mob/living/carbon/human/wearer = loc
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(wearer.glasses != src || !node?.is_online())
		return null
	return wearer

/obj/item/clothing/glasses/hud/netrun_view_settings()
	. = ..()
	.["see_in_dark"] = darkness_view
	.["sight"] = vision_flags
	.["see_invisible"] = invis_view

/obj/item/clothing/glasses/hud/netrun_status()
	. = ..()
	. += "Optics: [obj_flags & EMAGGED ? "firmware bypassed" : "secure"]"
	. += "Stream: [netrun_view_target() ? "live" : "unavailable"]"

/datum/netrun_api/hud
	atom_type = /obj/item/clothing/glasses/hud
	allow_emag = TRUE

/// The native remote-sight hook runs after a living viewer's own eye settings are calculated.
/// A separate eye keeps those settings from leaking into a network optical feed.
/obj/effect/netrun_view_eye
	name = "network optical viewpoint"
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	density = FALSE
	var/datum/netrun_console/console

/obj/effect/netrun_view_eye/New(loc, datum/netrun_console/console)
	src.console = console
	return ..()

/obj/effect/netrun_view_eye/Destroy()
	console = null
	return ..()

/obj/effect/netrun_view_eye/update_remote_sight(mob/living/user)
	if(!user)
		return FALSE
	var/list/settings = list("see_in_dark" = 2, "sight" = 0, "see_invisible" = SEE_INVISIBLE_LIVING)
	if(!QDELETED(console) && console.remote_session.watch_viewer == user && console.watch_target())
		var/atom/source = console.remote_session.watch_node.parent
		settings = source.netrun_view_settings()
	user.sight = settings["sight"]
	user.see_in_dark = settings["see_in_dark"]
	user.see_invisible = settings["see_invisible"]
	return TRUE

/obj/effect/netrun_view_eye/get_remote_view_fullscreens(mob/user)
	if(QDELETED(console) || console.remote_session.watch_viewer != user)
		return
	var/atom/target = console.watch_target()
	return target?.get_remote_view_fullscreens(user)
