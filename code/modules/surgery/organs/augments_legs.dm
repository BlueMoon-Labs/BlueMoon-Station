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
	desc = "Hydraulic pistons grafted into both ankles. After a short charge they launch the user forward in a single powerful leap."
	icon_state = "implant-reinforcers2"
	actions_types = list(/datum/action/item_action/organ_action/use)
	/// Guard against starting a second charge while one is already in progress.
	var/charging = FALSE

/obj/item/organ/cyberimp/leg/ankles/deactivate(removing)
	. = ..()
	charging = FALSE

/obj/item/organ/cyberimp/leg/ankles/ui_action_click(mob/user, actiontype)
	if(!owner || owner != user || charging)
		return
	if(owner.incapacitated() || owner.buckled || !isturf(owner.loc))
		to_chat(owner, span_warning("You cannot charge a jump right now."))
		return
	if(HAS_TRAIT(owner, TRAIT_JUMPING))
		to_chat(owner, span_warning("You are already in the air!"))
		return
	charging = TRUE
	to_chat(owner, span_notice("You crouch, charging the hydraulic pistons in your ankles..."))
	if(!do_after(owner, 2 SECONDS, owner))
		charging = FALSE
		return
	charging = FALSE
	if(!owner || QDELETED(src) || !(src in owner.internal_organs) || owner.incapacitated() || owner.buckled)
		return
	perform_charged_jump()

/obj/item/organ/cyberimp/leg/ankles/proc/perform_charged_jump()
	var/datum/component/jump/jump = owner.GetComponent(/datum/component/jump)
	if(!jump)
		owner.set_jump_component()
		jump = owner.GetComponent(/datum/component/jump)
	if(!jump)
		return
	var/old_height = jump.jump_height
	var/old_distance = jump.leap_distance
	var/old_duration = jump.jump_duration
	jump.jump_height = 28
	jump.leap_distance = 4
	jump.jump_duration = 0.7 SECONDS
	TIMER_COOLDOWN_END(owner, JUMP_COMPONENT_COOLDOWN)
	owner.visible_message(span_warning("[owner] launches into the air with a hydraulic hiss!"), span_notice("You launch yourself forward!"))
	SEND_SIGNAL(owner, COMSIG_KB_LIVING_JUMP, owner.dir)
	addtimer(CALLBACK(src, PROC_REF(restore_jump), old_height, old_distance, old_duration), 1 SECONDS)

/obj/item/organ/cyberimp/leg/ankles/proc/restore_jump(height, distance, duration)
	if(QDELETED(src) || !owner || QDELETED(owner))
		return
	var/datum/component/jump/jump = owner.GetComponent(/datum/component/jump)
	if(!jump)
		return
	jump.jump_height = height
	jump.leap_distance = distance
	jump.jump_duration = duration

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

///////////////////
// Microvibration Generator
///////////////////
/obj/item/organ/cyberimp/leg/microvibration
	name = "microvibration generator implant"
	desc = "A compact piston assembly hidden in both shins. When activated, it delivers a devastating vibrating kick that knocks the target off their feet."
	icon_state = "implant-power"
	actions_types = list(/datum/action/item_action/organ_action/use)
	/// Cooldown between kicks.
	var/kick_cooldown = 4 SECONDS

/obj/item/organ/cyberimp/leg/microvibration/ui_action_click(mob/user, actiontype)
	if(!owner || owner != user)
		return
	if(owner.incapacitated())
		to_chat(owner, span_warning("You cannot kick while incapacitated."))
		return
	if(HAS_TRAIT(owner, TRAIT_PACIFISM))
		to_chat(owner, span_warning("You are too peaceful to kick anyone."))
		return
	if(TIMER_COOLDOWN_CHECK(owner, "microvibration_kick"))
		to_chat(owner, span_warning("The generator is still recharging."))
		return
	var/mob/living/target = locate(/mob/living) in get_step(owner, owner.dir)
	if(!target || target == owner)
		to_chat(owner, span_warning("There is no one in front of you to kick."))
		return
	owner.do_attack_animation(target, ATTACK_EFFECT_KICK)
	playsound(get_turf(owner), 'sound/weapons/punch1.ogg', 50, TRUE)
	target.apply_damage(15, BRUTE, BODY_ZONE_CHEST)
	target.apply_damage(35, STAMINA)
	target.DefaultCombatKnockdown(20)
	var/turf/throw_turf = get_edge_target_turf(target, owner.dir)
	if(throw_turf)
		target.throw_at(throw_turf, 2, 2, owner)
	owner.visible_message(span_danger("[owner] delivers a powerful vibrating kick to [target]!"), span_danger("You kick [target] with the force of a piston!"))
	log_combat(owner, target, "microvibration-kicked")
	TIMER_COOLDOWN_START(owner, "microvibration_kick", kick_cooldown)
