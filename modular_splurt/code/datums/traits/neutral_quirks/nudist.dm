/datum/quirk/nudist
	// Mostly derived from masked_mook.
	// Spawning with a gear harness is preferable, but failed during testing.
	name = "Нудизм"
	desc = "Ношение большинства типов одежды нервирует вас. Несите портупею!"
	gain_text = span_notice("Вы чувствуете духовную связь со своим естеством.")
	lose_text = span_notice("Вы больше не чувствуете дискомфорта при ношении одежды.")
	medical_record_text = "Пациент выражает психологическую потребность оставаться без одежды."
	value = 0
	mood_quirk = TRUE
	var/is_nude

/datum/quirk/nudist/add()
	// Register signal handlers
	RegisterSignal(quirk_holder, COMSIG_MOB_UPDATE_GENITALS, PROC_REF(check_outfit))
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(quirk_examine_nudist))

/datum/quirk/nudist/remove()
	// Remove mood event
	SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, QMOOD_NUDIST)

	// Unregister signals
	UnregisterSignal(quirk_holder, list(COMSIG_MOB_UPDATE_GENITALS, COMSIG_PARENT_EXAMINE))

/datum/quirk/nudist/post_add()
	// Evaluate outfit
	check_outfit()

/datum/quirk/nudist/on_spawn()
	if(locate(/obj/item/implant/disrobe) in quirk_holder.implants)
		return
	var/obj/item/implant/disrobe/quirk_implant = new

	if(!quirk_implant.implant(quirk_holder, null, TRUE, TRUE))
		qdel(quirk_implant)

/datum/quirk/nudist/proc/check_outfit()
	SIGNAL_HANDLER

	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = quirk_holder

	// Check if torso is uncovered
	if(quirk_mob.is_chest_exposed() && quirk_mob.is_groin_exposed())
		// Send positive mood event
		SEND_SIGNAL(quirk_mob, COMSIG_ADD_MOOD_EVENT, QMOOD_NUDIST, /datum/mood_event/nudist_positive)

		// Check if already set
		if(is_nude)
			return

		// Alert user in chat
		to_chat(quirk_mob, span_nicegreen("Вам намного лучше без сковывающих вас обносков!"))

		// Set nude status
		is_nude = TRUE

	// Torso is covered
	else
		// Send negative mood event
		SEND_SIGNAL(quirk_mob, COMSIG_ADD_MOOD_EVENT, QMOOD_NUDIST, /datum/mood_event/nudist_negative)

		// Check if already set
		if(!is_nude)
			return

		// Alert user in chat
		to_chat(quirk_mob, span_warning("Одежда вашему телу не подходит..."))

		// Set nude status
		is_nude = FALSE

/datum/quirk/nudist/proc/quirk_examine_nudist(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list)
	SIGNAL_HANDLER

	// Define default status term
	var/mood_term = "в радостном состоянии из-за отсутствия на себе"

	// Define default span class
	var/span_class

	// Check if dressed
	if(!is_nude)
		// Set negative term
		mood_term = "в раздражении из-за ношения на себе"

		// Set negative span class
		span_class = "warning"

	// Add examine text
	examine_list += "<span class='[span_class]'>[quirk_holder.p_they_ru(TRUE)] [mood_term] одежды.</span>"
