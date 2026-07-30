/// Red gate styling on the station gateway during an active siege
/datum/element/pact_siege_red_gateway/Attach(datum/target)
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE
	. = ..()
	var/atom/A = target
	RegisterSignal(A, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(overlay_red))
	A.update_appearance()

/datum/element/pact_siege_red_gateway/Detach(datum/target, force)
	. = ..()
	if(!isatom(target))
		return
	var/atom/A = target
	UnregisterSignal(A, COMSIG_ATOM_UPDATE_OVERLAYS)
	A.update_appearance()

/datum/element/pact_siege_red_gateway/proc/overlay_red(atom/source, list/overlays)
	SIGNAL_HANDLER
	var/mutable_appearance/glow = mutable_appearance('icons/obj/machines/gateway.dmi', "portal_light")
	glow.color = "#ff2525"
	glow.blend_mode = BLEND_ADD
	overlays += glow
