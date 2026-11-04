/datum/overlay_effect/living_latex
	name = "Living latex"
	icon = null
	color = LATEX_COLOR
	need_use_color = TRUE

/mob/living/carbon/human
	var/datum/latex_capture/latex_capture
	var/datum/latex_coating/latex_coating

/datum/latex_coating
	var/mob/living/carbon/human/host
	var/datum/overlay_effect/living_latex/effect
	var/list/covered = list()
	var/list/clothing_layers = list()
	var/updating = FALSE
	var/datum/component/latex_contact/contact

/datum/latex_coating/New(mob/living/carbon/human/host, datum/antagonist/living_latex/latex)
	. = ..()
	src.host = host
	effect = new
	host.latex_coating = src
	if(!host.GetComponent(/datum/component/latex_contact))
		contact = host.AddComponent(/datum/component/latex_contact, latex)
	RegisterSignal(host, COMSIG_PARENT_QDELETING, PROC_REF(host_deleted))

/datum/latex_coating/proc/host_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/latex_coating/proc/cover(zone)
	if(QDELETED(host) || (zone in covered))
		return
	covered += zone
	host.apply_bodypart_overlays(list(zone), effect_datum = effect)
	switch(zone)
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			clothing_layers |= list(SHOES_LAYER, SOCKS_LAYER)
		if(BODY_ZONE_CHEST)
			clothing_layers |= list(UNIFORM_LAYER, SUIT_LAYER, UNDERWEAR_LAYER, SHIRT_LAYER, BELT_LAYER, BACK_LAYER, NECK_LAYER)
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
			clothing_layers |= list(GLOVES_LAYER, WRISTS_LAYER)
		if(BODY_ZONE_HEAD)
			clothing_layers |= list(HEAD_LAYER, FACEMASK_LAYER, GLASSES_LAYER, EAR_LEFT_LAYER, EAR_RIGHT_LAYER)
	update_clothing()

/datum/latex_coating/proc/update_clothing(changed_layer)
	if(updating || QDELETED(host) || (changed_layer && !(changed_layer in clothing_layers)))
		return
	updating = TRUE
	host.remove_overlay(LATEX_CLOTHING_LAYER)
	var/list/projections = list()
	for(var/layer in clothing_layers)
		var/source = host.overlays_standing[layer]
		if(!source)
			continue
		var/list/appearances = islist(source) ? source : list(source)
		for(var/appearance as anything in appearances)
			var/mutable_appearance/projection = new /mutable_appearance(appearance)
			projection.color = LATEX_COLOR
			projection.layer = -BODYPART_EFFECT_LAYER
			projections += projection
	host.overlays_standing[LATEX_CLOTHING_LAYER] = projections
	host.apply_overlay(LATEX_CLOTHING_LAYER)
	updating = FALSE

/datum/latex_coating/Destroy()
	if(host)
		UnregisterSignal(host, COMSIG_PARENT_QDELETING)
		for(var/zone in covered)
			var/list/params = host.layers_for_apply_effect[zone]
			if(params?[LATEX_EFFECT_INDEX] == effect)
				host.remove_overlay_by_bodypart_key(zone, FALSE)
		host.remove_overlay(LATEX_CLOTHING_LAYER)
		if(host.latex_coating == src)
			host.latex_coating = null
		if(!QDELETED(host))
			host.update_overlayed_parts(covered)
	host = null
	covered = null
	clothing_layers = null
	QDEL_NULL(contact)
	QDEL_NULL(effect)
	return ..()
