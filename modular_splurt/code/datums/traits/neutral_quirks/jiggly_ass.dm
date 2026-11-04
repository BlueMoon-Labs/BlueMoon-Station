/datum/quirk/jiggly_ass
	name = "Булки Грома"
	desc = "Твоя задница, растягивающая штаны, настолько же приятна, насколько трудно удержать равновесие, когда ее шлепают!"
	value = 0
	mob_trait = TRAIT_JIGGLY_ASS
	flavor_quirk = TRUE
	gain_text = span_notice("Ваш зад кажется очень удобным для шлепков.")
	lose_text = span_notice("Ваша задница снова чувствует себя нормально.")

/datum/quirk/jiggly_ass/add()
	// Add examine text
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))

/datum/quirk/jiggly_ass/remove()
	// Remove examine text
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)

// Quirk examine text
/datum/quirk/jiggly_ass/proc/on_examine_holder(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list, anonymous = FALSE)
	examine_list += span_lewd("[anonymous ? "Его" : quirk_holder.ru_ego(TRUE)] заднице не помешает крепкий шлепок.")
