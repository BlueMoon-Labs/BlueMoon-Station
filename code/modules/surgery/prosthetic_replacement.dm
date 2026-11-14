/datum/surgery/prosthetic_replacement
	name = "Prosthetic replacement"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/add_prosthetic)
	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_HEAD)
	requires_bodypart = FALSE //need a missing limb
	requires_bodypart_type = 0
	icon_state = "surgery_any"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_EMERGENCY

/datum/surgery/prosthetic_replacement/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	if(!iscarbon(target))
		return FALSE
	var/mob/living/carbon/C = target
	if(HAS_TRAIT(C, TRAIT_NAGA_ANATOMY) && (user.zone_selected == BODY_ZONE_L_LEG || user.zone_selected == BODY_ZONE_R_LEG))
		return FALSE
	if(!C.get_bodypart(user.zone_selected)) //can only start if limb is missing
		return TRUE
/datum/surgery_step/add_prosthetic
	name = "Добавить Конечность"
	implements = list(/obj/item/bodypart = 100, /obj/item/organ_storage = 100, /obj/item/chainsaw = 100, /obj/item/melee/synthetic_arm_blade = 100)
	time = 32
	var/organ_rejection_dam = 0
/datum/surgery_step/add_prosthetic/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(istype(tool, /obj/item/organ_storage))
		if(!tool.contents.len)
			to_chat(user, "<span class='notice'>There is nothing inside [tool]!</span>")
			return -1
		var/obj/item/I = tool.contents[1]
		if(!isbodypart(I))
			to_chat(user, "<span class='notice'>[I] cannot be attached!</span>")
			return -1
		tool = I
	if(istype(tool, /obj/item/bodypart))
		var/obj/item/bodypart/BP = tool
		if(istype(BP, /obj/item/bodypart/l_leg/naga_tail))
			to_chat(user, span_warning("Опорный хвост пересаживают через пах после ампутации обеих ног. Начните соответствующую операцию в области паха."))
			return -1
		if(ismonkey(target))// monkey patient only accept organic monkey limbs
			if(BP.is_robotic_limb() || BP.animal_origin != MONKEY_BODYPART)
				to_chat(user, "<span class='warning'>[BP] doesn't match the patient's morphology.</span>")
				return -1
		if(!BP.is_robotic_limb())
			organ_rejection_dam = 10
			if(ishuman(target))
				if(BP.animal_origin)
					to_chat(user, "<span class='warning'>[BP] doesn't match the patient's morphology.</span>")
					return -1
				var/mob/living/carbon/human/H = target
				if(H.dna.species.id != BP.species_id)
					organ_rejection_dam = 30

		if(target_zone == BP.body_zone) //so we can't replace a leg with an arm, or a human arm with a monkey arm.
			display_results(user, target, "<span class ='notice'>You begin to replace [target]'s [parse_zone(target_zone)] with [tool]...</span>",
				"[user] begins to replace [target]'s [parse_zone(target_zone)] with [tool].",
				"[user] begins to replace [target]'s [parse_zone(target_zone)].")
		else
			to_chat(user, "<span class='warning'>[tool] isn't the right type for [parse_zone(target_zone)].</span>")
			return -1
	else if(target_zone == BODY_ZONE_L_ARM || target_zone == BODY_ZONE_R_ARM)
		display_results(user, target, "<span class='notice'>You begin to attach [tool] onto [target]...</span>",
			"[user] begins to attach [tool] onto [target]'s [parse_zone(target_zone)].",
			"[user] begins to attach something onto [target]'s [parse_zone(target_zone)].")
	else
		to_chat(user, "<span class='warning'>[tool] must be installed onto an arm.</span>")
		return -1
/datum/surgery_step/add_prosthetic/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(istype(tool, /obj/item/organ_storage))
		tool.icon_state = initial(tool.icon_state)
		tool.desc = initial(tool.desc)
		tool.cut_overlays()
		tool = tool.contents[1]
	if(istype(tool, /obj/item/bodypart) && user.temporarilyRemoveItemFromInventory(tool))
		var/obj/item/bodypart/L = tool
		L.attach_limb(target)
		if(organ_rejection_dam)
			target.adjustToxLoss(organ_rejection_dam)
		display_results(user, target, "<span class='notice'>You succeed in replacing [target]'s [parse_zone(target_zone)].</span>",
			"[user] successfully replaces [target]'s [parse_zone(target_zone)] with [tool]!",
			"[user] successfully replaces [target]'s [parse_zone(target_zone)]!")
		return TRUE
	else
		var/obj/item/bodypart/L = target.newBodyPart(target_zone, FALSE, FALSE)
		L.is_pseudopart = TRUE
		L.attach_limb(target)
		display_results(user, target, "<span class='notice'>You attach [tool].</span>",
			"[user] finishes attaching [tool]!",
			"[user] finishes the attachment procedure!")
		qdel(tool)
		if(istype(tool, /obj/item/chainsaw))
			var/obj/item/mounted_chainsaw/new_arm = new(target)
			target_zone == BODY_ZONE_R_ARM ? target.put_in_r_hand(new_arm) : target.put_in_l_hand(new_arm)
			return TRUE
		else if(istype(tool, /obj/item/melee/synthetic_arm_blade))
			var/obj/item/melee/arm_blade/new_arm = new(target,TRUE,TRUE)
			target_zone == BODY_ZONE_R_ARM ? target.put_in_r_hand(new_arm) : target.put_in_l_hand(new_arm)
			return TRUE

// В паху сохраняется туловище, поэтому наличие хвоста проверяется отдельно от доступа.
/datum/surgery/naga_tail_replacement
	name = "Supporting tail transplantation"
	desc = "Пересадка опорного хвоста через доступ в области паха. У тела с ногами сначала необходимо ампутировать обе ноги."
	icon_state = "surgery_any"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/attach_naga_tail, /datum/surgery_step/close/naga_tail_replacement)
	possible_locs = list(BODY_ZONE_PRECISE_GROIN)
	requires_bodypart_type = 0
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_EMERGENCY
	special_surgery_traits = list(OPERATION_NEED_FULL_ANESTHETIC)

/datum/surgery/naga_tail_replacement/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	if(!ishuman(target))
		return FALSE
	var/mob/living/carbon/human/human = target
	return human.can_receive_naga_tail() && ..()

/datum/surgery_step/close/naga_tail_replacement/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	var/obj/item/bodypart/bodypart = target.get_bodypart(check_zone(target_zone))
	if(bodypart)
		// После разреза и одного зажима остаётся 7 стеков; обычное прижигание снимает 3.
		bodypart.generic_bleedstacks = max(0, bodypart.generic_bleedstacks - 4)
		bodypart.update_part_wound_overlay()
	return TRUE

/datum/surgery_step/attach_naga_tail
	name = "Пришить опорный хвост"
	parent_type = /datum/surgery_step/add_prosthetic
	implements = list(/obj/item/bodypart/l_leg/naga_tail = 100)

/datum/surgery_step/attach_naga_tail/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/mob/living/carbon/human/human = target
	if(!istype(human) || !human.can_receive_naga_tail())
		return -1
	display_results(user, target, span_notice("Вы начинаете пришивать опорный хвост [target]..."),
		"[user] начинает пришивать опорный хвост [target].",
		"[user] начинает пришивать опорный хвост [target].")

/datum/surgery_step/attach_naga_tail/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/mob/living/carbon/human/human = target
	if(!istype(human) || !human.can_receive_naga_tail())
		return FALSE
	var/obj/item/bodypart/l_leg/naga_tail/tail = tool
	if(!istype(tail) || !user.temporarilyRemoveItemFromInventory(tail))
		return FALSE
	if(!tail.attach_limb(target))
		user.put_in_hands(tail)
		return FALSE
	display_results(user, target, span_notice("Вы пришили опорный хвост [target]."),
		"[user] пришивает опорный хвост [target]!",
		"[user] пришивает опорный хвост [target]!")
	log_combat(user, target, "surgically attached supporting tail")
	return TRUE
