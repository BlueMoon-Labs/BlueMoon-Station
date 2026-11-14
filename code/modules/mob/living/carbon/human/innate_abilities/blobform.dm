
/datum/action/innate/ability/slime_blobform
	name = "Puddle Transformation"
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "slimepuddle"
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_alien"
	required_mobility_flags = MOBILITY_STAND
	var/is_puddle = FALSE
	var/in_transformation_duration = 12
	var/out_transformation_duration = 7
	var/puddle_into_effect = /obj/effect/temp_visual/slime_puddle
	var/puddle_from_effect = /obj/effect/temp_visual/slime_puddle/reverse
	var/puddle_into_effect_alt = /obj/effect/temp_visual/slime_puddle_alt
	var/puddle_from_effect_alt = /obj/effect/temp_visual/slime_puddle/reverse_alt
	var/puddle_icon = 'icons/mob/mob.dmi'
	var/puddle_state = "puddle"
	var/puddle_state_alt = "puddle_alt"
	var/mutable_appearance/tracked_overlay
	var/datum/component/squeak/squeak
	var/obj/effect/temp_visual/transformation_effect
	var/transforming = FALSE
	var/last_use
	var/transformation_cycle = 0
	var/had_passmob = FALSE

/datum/action/innate/ability/slime_blobform/IsAvailable()
	if(!transforming)
		return ..()
	else
		return FALSE

/datum/action/innate/ability/slime_blobform/Remove(mob/M)
	reset_form()
	return ..()

/datum/action/innate/ability/slime_blobform/Activate()
	var/mob/living/carbon/human/H = owner
	//if they have anything stuck to their hands, we immediately say 'no' and return
	for(var/obj/item/I in H.held_items)
		if(HAS_TRAIT(I, TRAIT_NODROP))
			to_chat(owner, "There's something stuck to your hand, stopping you from transforming!")
			return
	if(IsAvailable())
		UpdateButtons()
		var/mutcolor = get_puddle_color(H)
		if(!is_puddle)
			if(CHECK_MOBILITY(H, MOBILITY_USE)) //if we can use items, we can turn into a puddle
				transforming = TRUE
				var/cycle = ++transformation_cycle
				had_passmob = !!(H.pass_flags & PASSMOB)
				ADD_TRAIT(H, TRAIT_IMMOBILIZED, SLIMEPUDDLE_TRAIT)
				is_puddle = TRUE //so we know which transformation to use when its used
				ADD_TRAIT(H, TRAIT_HUMAN_NO_RENDER, SLIMEPUDDLE_TRAIT)
				owner.cut_overlays() //we dont show our normal sprite, we show a puddle sprite
				var/obj/effect/puddle_effect = new puddle_into_effect(get_turf(owner), owner.dir)
				if (H.dna.features["puddle_slime_fea"] == TRUE)
					qdel(puddle_effect)
					puddle_effect = new puddle_into_effect_alt(get_turf(owner), owner.dir)
				puddle_effect.color = mutcolor
				puddle_effect.transform = H.transform //copy mob size for consistent meltdown appearance
				transformation_effect = puddle_effect
				H.Stun(in_transformation_duration, ignore_canstun = TRUE) //cant move while transforming

				//series of traits that make up the puddle behaviour
				ADD_TRAIT(H, TRAIT_PARALYSIS_L_ARM, SLIMEPUDDLE_TRAIT)
				ADD_TRAIT(H, TRAIT_PARALYSIS_R_ARM, SLIMEPUDDLE_TRAIT)
				ADD_TRAIT(H, TRAIT_MOBILITY_NOPICKUP, SLIMEPUDDLE_TRAIT)
				ADD_TRAIT(H, TRAIT_MOBILITY_NOUSE, SLIMEPUDDLE_TRAIT)
				ADD_TRAIT(H, TRAIT_SPRINT_LOCKED, SLIMEPUDDLE_TRAIT)
				ADD_TRAIT(H, TRAIT_MOBILITY_NOREST, SLIMEPUDDLE_TRAIT)
				ADD_TRAIT(H, TRAIT_ARMOR_BROKEN, SLIMEPUDDLE_TRAIT)
				H.update_disabled_bodyparts(silent = TRUE)	//silently update arms to be paralysed
				H.add_movespeed_modifier(/datum/movespeed_modifier/slime_puddle)
				H.pass_flags |= PASSMOB //this actually lets people pass over you
				squeak = H.AddComponent(/datum/component/squeak, custom_sounds = list('sound/effects/blobattack.ogg')) //blorble noise when people step on you

				//if the user is a changeling, retract their sting
				H.unset_sting()

				sleep(in_transformation_duration)
				if(QDELETED(src) || QDELETED(H) || owner != H || transformation_cycle != cycle || !is_puddle)
					return

				QDEL_NULL(transformation_effect)
				REMOVE_TRAIT(H, TRAIT_IMMOBILIZED, SLIMEPUDDLE_TRAIT)

				//set the puddle overlay up
				var/puddle_sprite = get_puddle_icon()
				var/mutable_appearance/puddle_overlay = mutable_appearance(icon = puddle_sprite, icon_state = puddle_state)
				if (H.dna.features["puddle_slime_fea"] == TRUE)
					puddle_overlay = mutable_appearance(icon = puddle_sprite, icon_state = puddle_state_alt)
				puddle_overlay.color = mutcolor
				tracked_overlay = puddle_overlay
				owner.add_overlay(puddle_overlay)
				owner.update_antag_overlays()
				transforming = FALSE
				UpdateButtons()
		else
			detransform()
	else
		to_chat(owner, "<span class='warning'>You need to be standing up to do this!") //just assume they're a slime because it's such a weird edgecase to have it and not be one (it shouldn't even be possible)

/datum/action/innate/ability/slime_blobform/proc/detransform()
	var/mob/living/carbon/human/H = owner
	if(!H || !is_puddle || transforming)
		return
	transforming = TRUE
	ADD_TRAIT(H, TRAIT_IMMOBILIZED, SLIMEPUDDLE_TRAIT)
	var/cycle = ++transformation_cycle
	//like the above, but reverse everything done!
	H.cut_overlay(tracked_overlay)
	var/obj/effect/puddle_effect = new puddle_from_effect(get_turf(owner), owner.dir)
	if (H.dna.features["puddle_slime_fea"] == TRUE) // Блаамп
		qdel(puddle_effect)
		puddle_effect = new puddle_from_effect_alt(get_turf(owner), owner.dir)
	puddle_effect.color = tracked_overlay?.color
	puddle_effect.transform = H.transform //copy mob size for consistent transform size
	transformation_effect = puddle_effect
	H.Stun(out_transformation_duration, ignore_canstun = TRUE)
	sleep(out_transformation_duration)
	if(QDELETED(src) || QDELETED(H) || owner != H || transformation_cycle != cycle)
		return
	reset_form()

/datum/action/innate/ability/slime_blobform/proc/get_puddle_color(mob/living/carbon/human/human)
	return human.get_ability_property(INNATE_ABILITY_SLIME_BLOBFORM, PROPERTY_BLOBFORM_COLOR) || ("#" + human.dna.features["mcolor"])

/datum/action/innate/ability/slime_blobform/proc/get_puddle_icon()
	return puddle_icon

/datum/action/innate/ability/slime_blobform/proc/reset_form()
	transformation_cycle++
	QDEL_NULL(transformation_effect)
	var/mob/living/carbon/human/H = owner
	if(H)
		REMOVE_TRAIT(H, TRAIT_IMMOBILIZED, SLIMEPUDDLE_TRAIT)
	if(!H || !is_puddle)
		tracked_overlay = null
		transforming = FALSE
		is_puddle = FALSE
		QDEL_NULL(squeak)
		return
	H.cut_overlay(tracked_overlay)
	tracked_overlay = null
	REMOVE_TRAIT(H, TRAIT_PARALYSIS_L_ARM, SLIMEPUDDLE_TRAIT)
	REMOVE_TRAIT(H, TRAIT_PARALYSIS_R_ARM, SLIMEPUDDLE_TRAIT)
	REMOVE_TRAIT(H, TRAIT_MOBILITY_NOPICKUP, SLIMEPUDDLE_TRAIT)
	REMOVE_TRAIT(H, TRAIT_MOBILITY_NOUSE, SLIMEPUDDLE_TRAIT)
	REMOVE_TRAIT(H, TRAIT_SPRINT_LOCKED, SLIMEPUDDLE_TRAIT)
	REMOVE_TRAIT(H, TRAIT_MOBILITY_NOREST, SLIMEPUDDLE_TRAIT)
	REMOVE_TRAIT(H, TRAIT_ARMOR_BROKEN, SLIMEPUDDLE_TRAIT)
	REMOVE_TRAIT(H, TRAIT_HUMAN_NO_RENDER, SLIMEPUDDLE_TRAIT)
	H.update_disabled_bodyparts(silent = TRUE)
	H.remove_movespeed_modifier(/datum/movespeed_modifier/slime_puddle)
	if(!had_passmob)
		H.pass_flags &= ~PASSMOB
	had_passmob = FALSE
	is_puddle = FALSE
	QDEL_NULL(squeak)
	H.regenerate_icons()
	transforming = FALSE
	UpdateButtons()

/datum/action/innate/ability/slime_blobform/Destroy()
	reset_form()
	return ..()
