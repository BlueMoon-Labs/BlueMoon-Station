/// Leg-mounted cyberimplants.
///
/// Legs have no tool slots, so these augments do not deploy items: they are
/// permanent passive/activated upgrades until surgically removed. Every leg
/// implant is installed as a pair and occupies both leg slots at once.
/obj/item/organ/cyberimp/leg
	name = "leg-mounted implant"
	desc = "You shouldn't see this! Adminhelp and report this as an issue on github!"
	zone = BODY_ZONE_R_LEG
	organ_flags = ORGAN_SYNTHETIC
	icon_state = "implant-toolkit"
	w_class = WEIGHT_CLASS_NORMAL
	/// While implanted, this augment binds both leg slots and can be extracted from either leg.
	var/occupies_both_legs = TRUE

/obj/item/organ/cyberimp/leg/Initialize(mapload)
	. = ..()
	SetSlotFromZone()
	update_icon()

/obj/item/organ/cyberimp/leg/proc/SetSlotFromZone()
	switch(zone)
		if(BODY_ZONE_L_LEG)
			slot = ORGAN_SLOT_LEFT_LEG_AUG
		if(BODY_ZONE_R_LEG)
			slot = ORGAN_SLOT_RIGHT_LEG_AUG
		else
			CRASH("Invalid zone for [type]")

/// TRUE if this augment is explicitly configured to bind both legs at once.
/obj/item/organ/cyberimp/leg/proc/is_dual_leg_implant()
	return occupies_both_legs

/// Dual-leg augments hold both leg slots simultaneously, while `zone` decides the primary side.
/// Single-leg augments keep the default behaviour and only occupy their own slot.
/obj/item/organ/cyberimp/leg/get_organ_slots()
	if(is_dual_leg_implant())
		return list(ORGAN_SLOT_LEFT_LEG_AUG, ORGAN_SLOT_RIGHT_LEG_AUG)
	return ..()

/// Dual-leg augments display their overlay (if any) on both limbs.
/obj/item/organ/cyberimp/leg/get_bodypart_zones()
	if(is_dual_leg_implant())
		return list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	return ..()

/// A dual-leg implant counts as being inside either leg, so it can be extracted from both.
/obj/item/organ/cyberimp/leg/occupies_zone(target_zone)
	if(is_dual_leg_implant())
		return target_zone == BODY_ZONE_L_LEG || target_zone == BODY_ZONE_R_LEG
	return ..()

/// Surgery may install a dual-leg implant into either leg; it takes over both afterwards.
/obj/item/organ/cyberimp/leg/can_insert_into_zone(target_zone)
	if(is_dual_leg_implant())
		return target_zone == BODY_ZONE_L_LEG || target_zone == BODY_ZONE_R_LEG
	return ..()

/// Re-point a dual-leg implant at the leg it is being installed into.
/obj/item/organ/cyberimp/leg/prepare_insert(mob/living/carbon/target, target_zone)
	. = ..()
	if(is_dual_leg_implant())
		set_leg_zone(target_zone)

/// Changes the primary leg of the implant (default behaviour and item sprite direction).
/obj/item/organ/cyberimp/leg/proc/set_leg_zone(new_zone)
	if(new_zone != BODY_ZONE_L_LEG && new_zone != BODY_ZONE_R_LEG)
		return FALSE
	if(zone == new_zone)
		return TRUE
	zone = new_zone
	SetSlotFromZone()
	update_icon()
	return TRUE

/obj/item/organ/cyberimp/leg/update_icon_state()
	if(zone == BODY_ZONE_R_LEG)
		transform = null
	else // Mirroring the icon
		transform = matrix(-1, 0, 0, 0, 1, 0)

/obj/item/organ/cyberimp/leg/examine(mob/user)
	. = ..()
	if(is_dual_leg_implant())
		. += span_info("[src] is assembled in the [zone == BODY_ZONE_R_LEG ? "right" : "left"] leg configuration, but takes over both legs once implanted. You can use a screwdriver to reassemble it.")
	else
		. += span_info("[src] is assembled in the [zone == BODY_ZONE_R_LEG ? "right" : "left"] leg configuration. You can use a screwdriver to reassemble it.")

/obj/item/organ/cyberimp/leg/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return TRUE
	I.play_tool_sound(src)
	set_leg_zone(zone == BODY_ZONE_R_LEG ? BODY_ZONE_L_LEG : BODY_ZONE_R_LEG)
	to_chat(user, span_notice("You modify [src] to be installed on the [zone == BODY_ZONE_R_LEG ? "right" : "left"] leg."))

/obj/item/organ/cyberimp/leg/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(owner)
		to_chat(owner, span_warning("[src] is hit by EMP!"))

///////////////
// Reinforced Tendons
///////////////
/obj/item/organ/cyberimp/leg/tendons
	name = "reinforced tendons implant"
	desc = "A pair of synthetic tendon bundles replacing the muscles of both legs. Built-in micro-servos let the user perform a second jump in mid-air."
	icon_state = "implant-reinforcers"

/obj/item/organ/cyberimp/leg/tendons/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	. = ..()
	if(. && owner)
		apply_tendons()

/obj/item/organ/cyberimp/leg/tendons/Remove(special = FALSE)
	if(owner && !QDELETED(owner))
		remove_tendons()
	return ..()

/obj/item/organ/cyberimp/leg/tendons/proc/apply_tendons()
	if(QDELETED(owner))
		return
	var/datum/component/jump/jump = owner.GetComponent(/datum/component/jump)
	if(!jump)
		owner.set_jump_component()
		jump = owner.GetComponent(/datum/component/jump)
	if(!jump)
		return
	jump.set_vars(_jump_duration = 0.5 SECONDS, _jump_cooldown = 0.35 SECONDS, _stamina_cost = 18, _jump_height = 20, _jump_flags = JUMP_SHADOW)
	jump.leap_distance = 3
	jump.air_jumps = 1

/obj/item/organ/cyberimp/leg/tendons/proc/remove_tendons()
	if(QDELETED(owner))
		return
	var/datum/component/jump/jump = owner.GetComponent(/datum/component/jump)
	if(jump)
		jump.air_jumps = 0
		jump.jumps_performed = 0
	owner.set_jump_component()
	jump = owner.GetComponent(/datum/component/jump)
	if(jump)
		jump.leap_distance = 2

///////////////
// Fortified Ankles
///////////////
/obj/item/organ/cyberimp/leg/ankles
	name = "fortified ankles implant"
	desc = "Hydraulic pistons grafted into both ankles. They grant a built-in impulse boost that allows the user to dash forward in the direction they're facing."
	icon_state = "implant-reinforcers2"
	actions_types = list(/datum/action/item_action/organ_action/use)
	var/recharging_time = 0
	var/recharging_rate = 60
	var/jumpdistance = 5
	var/jumpspeed = 3

/obj/item/organ/cyberimp/leg/ankles/ui_action_click(mob/user, actiontype)
	if(!owner || owner != user)
		return
	if(owner.incapacitated() || owner.buckled)
		return
	if(!isturf(owner.loc))
		return
	if(recharging_time > world.time)
		to_chat(owner, span_warning("The hydraulic pistons need to recharge still!"))
		return
	var/atom/target = get_edge_target_turf(owner, owner.dir)
	if(owner.throw_at(target, jumpdistance, jumpspeed, spin = FALSE, diagonals_first = TRUE))
		playsound(owner, 'sound/effects/stealthoff.ogg', 50, 1, 1)
		recharging_time = world.time + recharging_rate
		owner.visible_message(span_warning("[owner] dashes forward with a hydraulic hiss!"), span_notice("You dash forward!"))
	else
		to_chat(owner, span_warning("Something prevents you from dashing forward!"))

///////////////
// Lynx Paws
///////////////
/obj/item/organ/cyberimp/leg/lynx_paws
	name = "lynx paws implant"
	desc = "Sound-dampening pads and artificial nerves installed in both feet. The user's footsteps become completely silent."
	icon_state = "implant-filter"

/obj/item/organ/cyberimp/leg/lynx_paws/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	. = ..()
	if(. && owner)
		ADD_TRAIT(owner, TRAIT_SILENT_STEP, REF(src))

/obj/item/organ/cyberimp/leg/lynx_paws/Remove(special = FALSE)
	if(owner && !QDELETED(owner))
		REMOVE_TRAIT(owner, TRAIT_SILENT_STEP, REF(src))
	return ..()


