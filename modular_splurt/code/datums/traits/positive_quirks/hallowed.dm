/datum/quirk/hallowed
	name = "Святой Дух"
	desc = "Вы были благословлены высшими силами или каким-то иным образом наделены святой энергией. Святая вода восстановит ваше здоровье!"
	value = 2
	mob_trait = TRAIT_HALLOWED
	flavor_quirk = TRUE
	gain_text = span_notice("Вы чувствуете, как святая энергия начинает течь по вашему телу.")
	lose_text = span_notice("Вы чувствуете, как угасает ваша святая энергия...")
	medical_record_text = "У пациента обнаружены неопознанные освященные материалы в крови. Проконсультируйтесь с капелланом."

/datum/quirk/hallowed/add()
	// Add examine text.
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))

/datum/quirk/hallowed/remove()
	// Remove examine text
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)

// Quirk examine text.
/datum/quirk/hallowed/proc/on_examine_holder(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list, anonymous = FALSE)
	examine_list += "[anonymous ? "Он" : quirk_holder.ru_who(TRUE)] излучает священную силу..."
