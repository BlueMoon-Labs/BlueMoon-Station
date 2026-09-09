/mob/living/carbon/human/proc/cleanup_overlays()
	remove_overlay(BODY_BEHIND_LAYER)
	remove_overlay(BODY_ADJ_LAYER)
	remove_overlay(BODY_ADJ_UPPER_LAYER)
	remove_overlay(BODY_FRONT_LAYER)
	remove_overlay(HORNS_LAYER)
	remove_overlay(BODYPART_EFFECT_LAYER)

/mob/living/carbon/human/proc/add_all_overlays()
	apply_overlay(BODY_BEHIND_LAYER)
	apply_overlay(BODY_ADJ_LAYER)
	apply_overlay(BODY_ADJ_UPPER_LAYER)
	apply_overlay(BODY_FRONT_LAYER)
	apply_overlay(HORNS_LAYER)
	apply_overlay(BODYPART_EFFECT_LAYER)

/mob/living/carbon/human/proc/have_tauric_body()
	if(dna.species.mutant_bodyparts["taur"] && dna.features["taur"] && dna.features["taur"] != "None")
		return TRUE
	else
		return FALSE

/datum/species/proc/search_coiling_action(mob/living/carbon/human/H)
	for(var/datum/action/A in H.actions)
		if(A.type == /datum/action/innate/ability/coiling)
			return A

/datum/species/proc/handle_digitigrade(list/bodyparts, mob/living/carbon/human/H, tauric)
	var/update_needed = FALSE
	var/not_digitigrade = TRUE
	for(var/obj/item/bodypart/B_part in H.bodyparts)
		if(!B_part.use_digitigrade)
			continue
		not_digitigrade = FALSE
		if(!(DIGITIGRADE in species_traits)) //Someone cut off a digitigrade leg and tacked it on
			species_traits += DIGITIGRADE
		var/should_be_squished = FALSE
		if(H.wear_suit)
			if(!(H.wear_suit.mutantrace_variation & STYLE_DIGITIGRADE) || (tauric && (H.wear_suit.mutantrace_variation & STYLE_ALL_TAURIC))) //digitigrade/taur suits
				should_be_squished = TRUE
		if(H.w_uniform && !H.wear_suit)
			if(!(H.w_uniform.mutantrace_variation & STYLE_DIGITIGRADE))
				should_be_squished = TRUE
		if(H.w_underwear && !H.wear_suit && !H.w_uniform)
			if(!(H.w_underwear.mutantrace_variation & STYLE_DIGITIGRADE))
				should_be_squished = TRUE
		if(H.w_socks && !H.wear_suit && !H.w_uniform)
			if(!(H.w_socks.mutantrace_variation & STYLE_DIGITIGRADE))
				should_be_squished = TRUE
		if(H.w_shirt && !H.wear_suit && !H.w_uniform)
			if(!(H.w_shirt.mutantrace_variation & STYLE_DIGITIGRADE))
				should_be_squished = TRUE
		if(B_part.use_digitigrade == FULL_DIGITIGRADE && should_be_squished)
			B_part.use_digitigrade = SQUISHED_DIGITIGRADE
			update_needed = TRUE
		else if(B_part.use_digitigrade == SQUISHED_DIGITIGRADE && !should_be_squished)
			B_part.use_digitigrade = FULL_DIGITIGRADE
			update_needed = TRUE
	if(not_digitigrade && (DIGITIGRADE in species_traits))
		species_traits -= DIGITIGRADE
	return update_needed

/datum/species/proc/grant_of_remove_coiling_action(mob/living/carbon/human/H, datum/action/found_action, var/tauric)
	if(found_action && (!tauric || (H.dna.features["taur"] != "Naga" && H.dna.features["taur"] != "Naga (coiled)")))
		found_action.Remove(H)

	if(!found_action && tauric && (H.dna.features["taur"] == "Naga" || H.dna.features["taur"] == "Naga (coiled)"))
		found_action = new /datum/action/innate/ability/coiling()
		found_action.Grant(H)
