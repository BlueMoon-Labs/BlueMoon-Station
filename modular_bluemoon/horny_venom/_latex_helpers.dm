/datum/action/cooldown/latexmob/proc/check_LL_antagDatum(mob/living/user)
	return user?.mind?.has_antag_datum(/datum/antagonist/living_latex)

/datum/action/cooldown/latexmob/proc/get_latexOrgan_if_captured_by_LL(mob/living/carbon/human/user)
	if(!istype(user))
		return null
	return locate(/obj/item/organ/latexOrgan) in user.internal_organs

/datum/action/cooldown/latexmob/proc/is_venom_controlling(datum/antagonist/living_latex/latex)
	return latex?.current_controller == VENOM_USER

/datum/action/cooldown/latexmob/proc/LL_mob_choice_with_radial_menu(mob/living/user, pick_only_simplemob, list/use_custom_list)
	var/list/choices = list()
	var/list/images = list()
	var/list/targets = use_custom_list || oview(1, user)
	for(var/mob/living/target in targets)
		if(target == user || islatexmob(target))
			continue
		if(pick_only_simplemob && !isanimal(target))
			continue
		if(!isanimal(target) && !ishuman(target))
			continue
		var/key = "[target.name] ([length(choices) + 1])"
		choices[key] = target
		var/image/preview = image(target.icon, target.icon_state)
		preview.overlays = target.overlays
		images[key] = preview
	if(!length(choices))
		user.balloon_alert(user, "нет подходящих целей")
		return null
	return choices[show_radial_menu(user, user, images)]

/datum/action/cooldown/latexmob/proc/can_merge_target(mob/living/user, mob/living/target, pick_only_simplemob, can_absorb_alive)
	if(QDELETED(user) || QDELETED(target) || user == target || islatexmob(target))
		return FALSE
	if(user.stat != CONSCIOUS || !isturf(user.loc) || !user.Adjacent(target) || !isturf(target.loc))
		return FALSE
	if(user.training_origin != target.training_origin && (user.training_origin || target.training_origin))
		return FALSE
	if(target.mind && !target.client)
		return FALSE
	if(isanimal(target))
		return target.stat == DEAD || (can_absorb_alive && !target.mind && !target.client)
	if(!ishuman(target) || pick_only_simplemob || target.stat == DEAD)
		return FALSE
	var/mob/living/carbon/human/human = target
	if(human.latex_capture || get_latexOrgan_if_captured_by_LL(human))
		return FALSE
	if(istype(human.wear_suit, /obj/item/clothing/suit/space) && istype(human.head, /obj/item/clothing/head/helmet/space))
		return FALSE
	return TRUE

/datum/action/cooldown/latexmob/proc/do_absorb_simple_mob(mob/living/simple_animal/target, mob/living/simple_animal/latexmob/user, datum/antagonist/living_latex/latex, datum/action/cooldown/latexmob/venomAction/action)
	if(!can_merge_target(user, target, TRUE, action.can_absorb_alive))
		return FALSE
	var/modifier = max(1 - (action.absorbed_mobs_counter - 1) * LATEX_ABSORB_DECAY, LATEX_ABSORB_DECAY)
	latex.evolve_points = min(LATEX_MAX_POINTS, latex.evolve_points + target.maxHealth * LATEX_ABSORB_HEALTH_FACTOR * modifier)
	action.absorbed_mobs_counter++
	qdel(target)
	return TRUE

/datum/action/cooldown/latexmob/proc/swap_LL_body_to_new_form(mob/living/old_body, mob_typepath, turf/location)
	if(QDELETED(old_body) || !old_body.mind || !location)
		return null
	var/mob/living/new_body = new mob_typepath(location)
	new_body.training_origin = old_body.training_origin
	var/datum/mind/latex_mind = old_body.mind
	latex_mind.transfer_to(new_body)
	if(latex_mind.current != new_body)
		qdel(new_body)
		return null
	new_body.name = old_body.name
	old_body.drop_all_held_items()
	qdel(old_body)
	return new_body

/mob/proc/LL_build_latex_icon(icon_file, state)
	if(!icon_file || !state)
		return null
	var/icon/mask = getIconMask(src)
	if(!mask)
		return null
	var/icon/latex_icon = icon(icon_file, state)
	latex_icon.UseAlphaMask(mask)
	return latex_icon

/mob/proc/LL_apply_latex_overlay(icon_file, state, opacity = LIGHTING_PLANE_ALPHA_VISIBLE)
	var/icon/latex_icon = LL_build_latex_icon(icon_file, state)
	if(!latex_icon)
		return null
	var/mutable_appearance/overlay = mutable_appearance(latex_icon)
	overlay.alpha = opacity
	add_overlay(overlay)
	return overlay

/mob/proc/LL_apply_animated_latex_overlay_with_progressbar(icon_file, state, delay, mob/target)
	if(QDELETED(target) || !Adjacent(target))
		return FALSE
	var/mutable_appearance/overlay = target.LL_apply_latex_overlay(icon_file, state)
	var/finished = do_after(src, delay, target = target)
	if(!QDELETED(target))
		target.cut_overlay(overlay)
	return finished && !QDELETED(src) && !QDELETED(target) && Adjacent(target)
