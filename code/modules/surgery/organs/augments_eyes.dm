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
		if(!QDELETED(old_interface))
			old_interface.RemoveSource(interface_source)
	else
		var/datum/atom_hud/H = GLOB.huds[HUD_type]
		H.add_hud_to(owner)
		interface = owner.LoadComponent(/datum/component/neural_interface)
		interface.AddSource(interface_source)
		if(monitors?.len)
			interface.add_monitors_by_types(interface_source, monitors)

	active = !active

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
