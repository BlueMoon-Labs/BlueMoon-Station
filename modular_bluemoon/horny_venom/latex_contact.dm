/datum/status_effect/latex_stained
	id = "latex_stained"
	duration = LATEX_CONTACT_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/latex_stained
	examine_text = "На руках SUBJECTPRONOUN видны шевелящиеся чёрные кусочки латекса."
	var/stage = LATEX_STAIN_HANDS
	var/list/stain_overlays = list()
	COOLDOWN_DECLARE(shake_cooldown)

/datum/status_effect/latex_stained/on_creation(mob/living/new_owner, ...)
	. = ..()
	if(.)
		update_alert()

/datum/status_effect/latex_stained/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(washed))
	update_visuals()
	announce_stage()

/datum/status_effect/latex_stained/refresh(effect, ...)
	. = ..()
	if(stage >= LATEX_STAIN_MAX_STAGE)
		return
	stage++
	update_visuals()
	update_alert()
	announce_stage()

/datum/status_effect/latex_stained/proc/announce_stage()
	switch(stage)
		if(LATEX_STAIN_HANDS)
			to_chat(owner, span_warning("На ваших руках остались склизкие чёрные кусочки слайма. Они шевелятся!"))
		if(LATEX_STAIN_ARMS)
			to_chat(owner, span_warning("Новые кусочки латекса сливаются с прилипшими. Чёрная масса ползёт с кистей на предплечья!"))
		if(LATEX_STAIN_CHEST)
			to_chat(owner, span_warning("Латекса стало ещё больше: склизкие чёрные сгустки цепляются за руки и тянутся к груди. Они двигаются сами по себе!"))

/datum/status_effect/latex_stained/proc/update_visuals()
	owner.cut_overlay(stain_overlays)
	stain_overlays.Cut()
	for(var/index in 1 to stage)
		var/mutable_appearance/stain = mutable_appearance('modular_bluemoon/horny_venom/icons/latexmob.dmi', "slime_form", ABOVE_MOB_LAYER)
		var/scale = index == LATEX_STAIN_MAX_STAGE ? LATEX_STAIN_CHEST_SCALE : LATEX_STAIN_SCALE
		stain.transform = matrix() * scale
		stain.pixel_x = index == LATEX_STAIN_HANDS ? -LATEX_STAIN_HAND_OFFSET : LATEX_STAIN_HAND_OFFSET
		stain.pixel_y = LATEX_STAIN_HAND_HEIGHT
		if(index == LATEX_STAIN_MAX_STAGE)
			stain.pixel_x = 0
			stain.pixel_y = LATEX_STAIN_CHEST_HEIGHT
		stain_overlays += stain
	owner.add_overlay(stain_overlays)

/datum/status_effect/latex_stained/proc/update_alert()
	if(!linked_alert)
		return
	linked_alert.name = "[initial(linked_alert.name)] ([stage]/[LATEX_STAIN_MAX_STAGE])"
	linked_alert.desc = "На вас шевелятся склизкие чёрные кусочки живого латекса. Нажмите, чтобы попытаться стряхнуть их. Успех убирает одну стадию. Попытка доступна раз в [LATEX_STAIN_REMOVE_COOLDOWN / (1 SECONDS)] секунды. Латекс также можно смыть водой или мылом."

/datum/status_effect/latex_stained/proc/try_remove(mob/living/user)
	if(user != owner || QDELETED(owner) || owner.stat != CONSCIOUS || owner.incapacitated())
		return FALSE
	if(!COOLDOWN_FINISHED(src, shake_cooldown))
		return FALSE
	COOLDOWN_START(src, shake_cooldown, LATEX_STAIN_REMOVE_COOLDOWN)
	if(!roll_removal())
		to_chat(owner, span_warning("Вы пытаетесь стряхнуть латекс, но склизкие кусочки снова цепляются за вас."))
		return FALSE
	stage--
	if(!stage)
		to_chat(owner, span_notice("Вы стряхиваете последние кусочки живого латекса."))
		qdel(src)
		return TRUE
	to_chat(owner, span_notice("Вам удаётся стряхнуть часть латекса. Прилипших кусочков стало меньше."))
	update_visuals()
	update_alert()
	return TRUE

/datum/status_effect/latex_stained/proc/roll_removal()
	return prob(LATEX_STAIN_REMOVE_CHANCE)

/datum/status_effect/latex_stained/proc/washed()
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/latex_stained/on_remove()
	UnregisterSignal(owner, COMSIG_COMPONENT_CLEAN_ACT)
	owner.cut_overlay(stain_overlays)
	return ..()

/datum/status_effect/latex_stained/Destroy()
	. = ..()
	stain_overlays = null

/atom/movable/screen/alert/status_effect/latex_stained
	name = "Запачкан в латексе"
	desc = "На руках шевелятся склизкие чёрные кусочки живого латекса. Их можно смыть водой или мылом."
	icon = 'modular_bluemoon/horny_venom/icons/latexmob.dmi'
	icon_state = "slime_form"
	clickable_glow = TRUE

/atom/movable/screen/alert/status_effect/latex_stained/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/datum/status_effect/latex_stained/stain = attached_effect
	return stain?.try_remove(usr)

/datum/component/latex_contact
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/latex_ref

/datum/component/latex_contact/Initialize(datum/antagonist/living_latex/latex)
	if(!isliving(parent) && !isobj(parent))
		return COMPONENT_INCOMPATIBLE
	latex_ref = WEAKREF(latex)

/datum/component/latex_contact/RegisterWithParent()
	var/hand_signal = isliving(parent) ? COMSIG_MOB_ATTACK_HAND : COMSIG_ATOM_ATTACK_HAND
	RegisterSignal(parent, list(hand_signal, COMSIG_ATOM_ATTACK_ANIMAL, COMSIG_ATOM_BUMPED, COMSIG_ITEM_PICKUP), PROC_REF(touched))
	RegisterSignal(parent, COMSIG_MOVABLE_BUMP, PROC_REF(bumped))

/datum/component/latex_contact/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOB_ATTACK_HAND, COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_ANIMAL, COMSIG_ATOM_BUMPED, COMSIG_ITEM_PICKUP, COMSIG_MOVABLE_BUMP))

/datum/component/latex_contact/proc/touched(datum/source, mob/living/user)
	SIGNAL_HANDLER
	stain(user)

/datum/component/latex_contact/proc/bumped(datum/source, atom/target)
	SIGNAL_HANDLER
	if(isliving(target))
		stain(target)

/datum/component/latex_contact/proc/stain(mob/living/user)
	if(!istype(user) || user == parent || islatexmob(user))
		return FALSE
	var/mob/living/latex_mob
	if(isliving(parent))
		latex_mob = parent
	if(isobj(parent))
		var/obj/shell = parent
		var/datum/component/latex_mimicry/mimic = shell.GetComponent(/datum/component/latex_mimicry)
		latex_mob = mimic?.stored_latexmob
	var/datum/antagonist/living_latex/latex = latex_ref?.resolve() || latex_mob?.mind?.has_antag_datum(/datum/antagonist/living_latex)
	if(latex && !latex.leave_traces)
		return FALSE
	user.apply_status_effect(/datum/status_effect/latex_stained)
	return TRUE

/datum/component/latex_contact/Destroy()
	latex_ref = null
	return ..()
