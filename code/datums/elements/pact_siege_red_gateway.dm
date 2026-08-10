/// Red gate styling on the station gateway during an active siege.
/// Calibration: portal_loading + reddish portal_light.
/// Open siege: reddish portal_light + reddish portal_mask.
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
	var/datum/inteq_pact_siege/siege = GLOB.inteq_pact_siege
	if(!siege?.active)
		return

	var/calibrating = !siege.gates_unlocked()
	var/gateway_icon = 'icons/obj/machines/gateway.dmi'
	var/red_tint = "#ff2525"
	var/found_light = FALSE

	/// Make existing portal_light overlays reddish (base gateway draws them when teleportion_possible)
	for(var/overlay in overlays)
		var/image/img = overlay
		if(!istype(img))
			continue
		if(img.icon == gateway_icon && img.icon_state == "portal_light")
			img.color = red_tint
			found_light = TRUE

	if(!found_light)
		var/mutable_appearance/glow = mutable_appearance(gateway_icon, "portal_light")
		glow.color = red_tint
		glow.blend_mode = BLEND_ADD
		overlays += glow
		overlays += emissive_appearance(gateway_icon, "portal_light", source)

	if(calibrating)
		overlays += mutable_appearance(gateway_icon, "portal_loading")
		return

	/// After calibration, while the siege channel is open — reddish portal_mask
	var/mutable_appearance/mask = mutable_appearance(gateway_icon, "portal_mask")
	mask.color = "#ff3030"
	mask.alpha = 220
	overlays += mask
	overlays += emissive_appearance(gateway_icon, "portal_mask", source)
