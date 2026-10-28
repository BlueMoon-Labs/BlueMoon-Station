/obj/item/organ/cyberimp/eyes/hud
	name = "HUD implant"
	desc = "These cybernetic eyes will display a HUD over everything you see. Maybe."
	icon_state = "eye_implant"
	implant_overlay = "eye_implant_overlay"
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	zone = BODY_ZONE_PRECISE_EYES
	w_class = WEIGHT_CLASS_TINY
	slot = ORGAN_SLOT_HUD
	var/HUD_type = 0
	var/active = FALSE
	var/datum/component/neural_interface/interface
	var/list/monitors = list()
	var/interface_source

/obj/item/organ/cyberimp/eyes/hud/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(!.)
		return
	toggle()

/obj/item/organ/cyberimp/eyes/hud/ui_action_click(mob/user, actiontype)
	toggle()

/obj/item/organ/cyberimp/eyes/hud/proc/toggle()
	if(!HUD_type || QDELETED(owner))
		return

	interface_source = "IMPLANT HUD[HUD_type]"
	if(active)
		var/datum/atom_hud/H = GLOB.huds[HUD_type]
		H.remove_hud_from(owner)
		var/datum/component/neural_interface/old_interface = interface
		interface = null
		if(old_interface)
			UnregisterSignal(old_interface, COMSIG_PARENT_QDELETING)
			if(!QDELETED(old_interface))
				old_interface.RemoveSource(interface_source)
	else
		var/datum/atom_hud/H = GLOB.huds[HUD_type]
		H.add_hud_to(owner)
		interface = owner.LoadComponent(/datum/component/neural_interface)
		//компонент общий на моба и самоудаляется, когда пустеет его список
		//источников - без сигнала вар вечно держал бы мёртвый компонент
		RegisterSignal(interface, COMSIG_PARENT_QDELETING, PROC_REF(on_interface_qdel), override = TRUE)
		interface.AddSource(interface_source)
		if(monitors?.len)
			interface.add_monitors_by_types(interface_source, monitors)

	active = !active

/obj/item/organ/cyberimp/eyes/hud/proc/on_interface_qdel(datum/source)
	SIGNAL_HANDLER
	interface = null

/obj/item/organ/cyberimp/eyes/hud/code_activate()
	. = ..()
	if(!active)
		toggle()

/obj/item/organ/cyberimp/eyes/hud/deactivate(removing)
	. = ..()
	if(active)
		toggle()

/obj/item/organ/cyberimp/eyes/hud/medical
	name = "Medical HUD implant"
	desc = "These cybernetic eye implants will display a medical HUD over everything you see."
	HUD_type = DATA_HUD_MEDICAL_ADVANCED
	monitors = list(
		/datum/neural_monitor/health_scan,
		/datum/neural_monitor/health,
		/datum/neural_monitor/wound
	)

/obj/item/organ/cyberimp/eyes/hud/diagnostic
	name = "Diagnostic HUD implant"
	desc = "These cybernetic eye implants will display a diagnostic HUD over everything you see."
	HUD_type = DATA_HUD_DIAGNOSTIC_ADVANCED

/obj/item/organ/cyberimp/eyes/hud/security
	name = "Security HUD implant"
	desc = "These cybernetic eye implants will display a security HUD over everything you see."
	HUD_type = DATA_HUD_SECURITY_ADVANCED

/obj/item/organ/cyberimp/eyes/hud/security/syndicate
	name = "Contraband Security HUD Implant"
	desc = "A Cybersun Industries brand Security HUD Implant. These illicit cybernetic eye implants will display a security HUD over everything you see."
	syndicate_implant = TRUE

/obj/item/organ/cyberimp/eyes/optical
	name = "Optical cybernetic implant"
	desc = "A modular optical implant."
	icon_state = "eye_implant"
	implant_overlay = "eye_implant_overlay"
	zone = BODY_ZONE_PRECISE_EYES
	slot = ORGAN_SLOT_EYES
	w_class = WEIGHT_CLASS_TINY
	actions_types = list(/datum/action/item_action/organ_action/toggle_zoom)

/obj/item/organ/cyberimp/eyes/optical/kiroshi
	name = "\improper Kiroshi optics"
	desc = "A high-precision optical implant that grants a sniper scope-like zoom for long-range targeting."
	var/zoomed = FALSE
	var/zoom_amt = 4
	var/zoom_out_amt = 0

/obj/item/organ/cyberimp/eyes/optical/kiroshi/ui_action_click(mob/user, actiontype)
	if(actiontype == /datum/action/item_action/organ_action/toggle_zoom)
		toggle_zoom(user)

/obj/item/organ/cyberimp/eyes/optical/kiroshi/proc/toggle_zoom(mob/living/carbon/user)
	if(!user || user != owner)
		return
	if(user.client)
		if(zoomed)
			user.client.view_size.zoomIn()
			zoomed = FALSE
			UnregisterSignal(user, COMSIG_ATOM_DIR_CHANGE)
		else
			user.client.view_size.zoomOut(zoom_out_amt, zoom_amt, user.dir)
			zoomed = TRUE
			RegisterSignal(user, COMSIG_ATOM_DIR_CHANGE, PROC_REF(rotate))

/obj/item/organ/cyberimp/eyes/optical/kiroshi/proc/rotate(atom/thing, old_dir, new_dir)
	if(ismob(thing) && zoomed)
		var/mob/living/carbon/human/lad = thing
		if(lad.client)
			lad.client.view_size.zoomOut(zoom_out_amt, zoom_amt, new_dir)

/obj/item/organ/cyberimp/eyes/optical/kiroshi/Remove(special = FALSE)
	if(zoomed && owner && owner.client)
		owner.client.view_size.zoomIn()
		zoomed = FALSE
		UnregisterSignal(owner, COMSIG_ATOM_DIR_CHANGE)
	return ..()

/obj/item/organ/cyberimp/eyes/optical/militech
	name = "\improper Militech optical suite"
	desc = "A high-precision optical implant with integrated flash protection and sniper scope-like zoom for long-range targeting."
	var/zoomed = FALSE
	var/zoom_amt = 4
	var/zoom_out_amt = 0

/obj/item/organ/cyberimp/eyes/optical/militech/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(!.)
		return
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/organ/eyes/E = H.getorganslot(ORGAN_SLOT_EYES)
		if(E)
			E.flash_protect = max(E.flash_protect, 3)

/obj/item/organ/cyberimp/eyes/optical/militech/Remove(special = FALSE)
	if(zoomed && owner && owner.client)
		owner.client.view_size.zoomIn()
		zoomed = FALSE
		UnregisterSignal(owner, COMSIG_ATOM_DIR_CHANGE)
	if(owner && ishuman(owner))
		var/mob/living/carbon/human/H = owner
		var/obj/item/organ/eyes/E = H.getorganslot(ORGAN_SLOT_EYES)
		if(E)
			E.flash_protect = initial(E.flash_protect)
	return ..()

/obj/item/organ/cyberimp/eyes/optical/militech/ui_action_click(mob/user, actiontype)
	if(actiontype == /datum/action/item_action/organ_action/toggle_zoom)
		toggle_zoom(user)

/obj/item/organ/cyberimp/eyes/optical/militech/proc/toggle_zoom(mob/living/carbon/user)
	if(!user || user != owner)
		return
	if(user.client)
		if(zoomed)
			user.client.view_size.zoomIn()
			zoomed = FALSE
			UnregisterSignal(user, COMSIG_ATOM_DIR_CHANGE)
		else
			user.client.view_size.zoomOut(zoom_out_amt, zoom_amt, user.dir)
			zoomed = TRUE
			RegisterSignal(user, COMSIG_ATOM_DIR_CHANGE, PROC_REF(rotate))

/obj/item/organ/cyberimp/eyes/optical/militech/proc/rotate(atom/thing, old_dir, new_dir)
	if(ismob(thing) && zoomed)
		var/mob/living/carbon/human/lad = thing
		if(lad.client)
			lad.client.view_size.zoomOut(zoom_out_amt, zoom_amt, new_dir)
