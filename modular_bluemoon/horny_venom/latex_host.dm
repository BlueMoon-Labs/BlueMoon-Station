/obj/item/organ/latexOrgan
	name = "strange black organ"
	zone = BODY_ZONE_CHEST
	slot = "living_latex"
	organ_flags = ORGAN_NO_SPOIL
	var/mob/living/simple_animal/latexmob/venom/ObserverBackseat
	var/datum/antagonist/living_latex/antag_datum
	var/datum/mind/host_mind
	var/datum/latex_coating/coating
	var/datum/action/cooldown/latex_host_release/release_action
	var/is_hiding = FALSE
	var/releasing = FALSE
	var/swapping = FALSE
	var/turf/safe_turf

/obj/item/organ/latexOrgan/proc/attach(datum/antagonist/living_latex/latex, mob/living/simple_animal/latexmob/actor, mob/living/carbon/human/target, datum/latex_coating/covering)
	if(QDELETED(latex) || QDELETED(actor) || QDELETED(target) || latex.host_organ || target.getorganslot(slot))
		return FALSE
	antag_datum = latex
	host_mind = target.mind
	if(!Insert(target))
		antag_datum = null
		return FALSE
	ObserverBackseat = new(target)
	ObserverBackseat.training_origin = target.training_origin
	ObserverBackseat.body = target
	ObserverBackseat.organ = src
	latex.host_organ = src
	latex.current_controller = BODY_OWNER
	latex.owner.transfer_to(ObserverBackseat, TRUE, FALSE)
	if(latex.owner.current != ObserverBackseat)
		latex.host_organ = null
		Remove(TRUE)
		return FALSE
	safe_turf = get_turf(target)
	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(host_moved))
	coating = covering
	release_action = new(src)
	release_action.Grant(target)
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(host_died))
	RegisterSignal(latex.owner, COMSIG_MIND_TRANSFER, PROC_REF(mind_changed))
	if(host_mind)
		RegisterSignal(host_mind, COMSIG_MIND_TRANSFER, PROC_REF(mind_changed))
	actor.drop_all_held_items()
	new /obj/effect/temp_visual/latexmob/venom_in(get_turf(target))
	qdel(actor)
	return TRUE

/obj/item/organ/latexOrgan/proc/swap_control()
	if(releasing || swapping || QDELETED(owner) || QDELETED(ObserverBackseat) || QDELETED(antag_datum))
		return FALSE
	var/datum/mind/latex_mind = antag_datum.owner
	var/mob/living/old_body = latex_mind.current
	var/mob/living/new_body = old_body == owner ? ObserverBackseat : owner
	if(old_body != owner && old_body != ObserverBackseat)
		return FALSE
	if(new_body == owner && (owner.stat != CONSCIOUS || !host_present() || owner.mind != host_mind))
		return FALSE
	var/datum/mind/other_mind = new_body.mind
	if(other_mind && other_mind != host_mind)
		return FALSE
	swapping = TRUE
	latex_mind.transfer_to(new_body, TRUE, FALSE)
	if(latex_mind.current != new_body)
		swapping = FALSE
		return FALSE
	if(other_mind)
		other_mind.transfer_to(old_body, TRUE, FALSE)
		if(other_mind.current != old_body)
			latex_mind.transfer_to(old_body, TRUE, FALSE)
			other_mind.transfer_to(new_body, TRUE, FALSE)
			swapping = FALSE
			return FALSE
	antag_datum.current_controller = new_body == owner ? VENOM_USER : BODY_OWNER
	release_action.Grant(host_mind?.current || owner)
	swapping = FALSE
	return TRUE

/obj/item/organ/latexOrgan/proc/host_present()
	return !host_mind || owner?.client

/obj/item/organ/latexOrgan/proc/update_hiding_state()
	is_hiding = antag_datum?.hide_latexorgan_on_healscan

/obj/item/organ/latexOrgan/proc/host_died()
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(release))

/obj/item/organ/latexOrgan/proc/mind_changed()
	SIGNAL_HANDLER
	if(!swapping && !releasing)
		INVOKE_ASYNC(src, PROC_REF(release))

/obj/item/organ/latexOrgan/proc/release(force = FALSE)
	if(releasing)
		return FALSE
	releasing = TRUE
	var/mob/living/carbon/human/body = owner
	if(!restore_players(body, force))
		releasing = FALSE
		return FALSE
	clear_host(body)
	if(owner)
		Remove(TRUE)
	if(!QDELING(src))
		qdel(src)
	return TRUE

/obj/item/organ/latexOrgan/proc/restore_players(mob/living/carbon/human/body, force)
	var/datum/mind/latex_mind = antag_datum?.owner
	var/mob/living/old_body = latex_mind?.current
	var/mob/living/simple_animal/latexmob/free_latex
	if(latex_mind && (old_body == body || old_body == ObserverBackseat))
		var/turf/location = get_turf(body) || get_turf(ObserverBackseat) || safe_turf
		if(location)
			free_latex = new(location)
			free_latex.training_origin = old_body.training_origin
			free_latex.name = antag_datum.latex_name
			latex_mind.transfer_to(free_latex, TRUE, FALSE)
		if(latex_mind.current != free_latex || !free_latex)
			QDEL_NULL(free_latex)
			if(!force)
				return FALSE
			old_body?.ghostize(TRUE)
	if(host_mind?.current == ObserverBackseat && body && !QDELETED(body))
		host_mind.transfer_to(body, TRUE, FALSE)
		if(host_mind.current != body && !force)
			if(free_latex)
				latex_mind.transfer_to(old_body, TRUE, FALSE)
				if(latex_mind.current == old_body)
					qdel(free_latex)
					return FALSE
			force = TRUE
	if(ObserverBackseat?.mind)
		ObserverBackseat.ghostize(TRUE)
	return TRUE

/obj/item/organ/latexOrgan/proc/clear_host(mob/living/carbon/human/body)
	if(body)
		UnregisterSignal(body, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED))
	if(antag_datum?.owner)
		UnregisterSignal(antag_datum.owner, COMSIG_MIND_TRANSFER)
	if(host_mind)
		UnregisterSignal(host_mind, COMSIG_MIND_TRANSFER)
	if(antag_datum)
		antag_datum.host_organ = null
		antag_datum.current_controller = BODY_OWNER
		antag_datum.hide_latexorgan_on_healscan = FALSE
	QDEL_NULL(release_action)
	QDEL_NULL(coating)
	if(ObserverBackseat)
		ObserverBackseat.organ = null
		ObserverBackseat.body = null
		if(!QDELETED(ObserverBackseat))
			qdel(ObserverBackseat)
		ObserverBackseat = null
	host_mind = null
	antag_datum = null
	safe_turf = null

/obj/item/organ/latexOrgan/proc/host_moved()
	SIGNAL_HANDLER
	safe_turf = get_turf(owner) || safe_turf

/obj/item/organ/latexOrgan/Remove(special)
	if(!releasing && antag_datum)
		release(TRUE)
	return ..()

/obj/item/organ/latexOrgan/Destroy()
	release(TRUE)
	antag_datum = null
	host_mind = null
	return ..()

/datum/action/cooldown/latex_host_release
	name = "Освободиться от латекса"
	desc = "Попросить живой латекс отделиться и вернуть управление телом."
	var/obj/item/organ/latexOrgan/organ

/datum/action/cooldown/latex_host_release/New(obj/item/organ/latexOrgan/organ)
	. = ..(organ)
	src.organ = organ

/datum/action/cooldown/latex_host_release/Activate()
	if(usr != owner || QDELETED(organ))
		return FALSE
	return organ.release()

/datum/action/cooldown/latex_host_release/Destroy()
	organ = null
	return ..()
