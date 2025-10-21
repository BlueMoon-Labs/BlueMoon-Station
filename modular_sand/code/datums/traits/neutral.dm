/datum/quirk/hypnotic_stupor //straight from skyrat
	name = "Гипнотический Ступор"
	desc = "Вы склонны к приступам крайнего ступора, который делает вас чрезвычайно внушаемым."
	value = 0
	human_only = TRUE
	gain_text = null // Handled by trauma.
	lose_text = null
	medical_record_text = "Пациент имеет не поддающееся лечению заболевание мозга, в результате чего он становится чрезвычайно... внушаемым...."

/datum/quirk/hypnotic_stupor/add()
	var/datum/brain_trauma/severe/hypnotic_stupor/T = new()
	var/mob/living/carbon/human/H = quirk_holder
	H.gain_trauma(T, TRAUMA_RESILIENCE_ABSOLUTE)
/*
/datum/quirk/infertile
	name = "Infertile"
	desc = "For one reason or another you simply don't seem able to get pregnant, no matter how hard you try."
	value = 0
	human_only = TRUE
	mob_trait = TRAIT_INFERTILE
	gain_text = "<span class='notice'>Your womb starts feeling dry and empty, all the life in it begins to fade away...</span>"
	lose_text = "<span class='love'>You feel the warm blow of life flooding your womb, full of newfound, vibrant fertility!</span>"
	medical_record_text = "Patient doesn't seem able to ovulate properly..."
*/

/datum/quirk/estrous_detection
	name = "Обнаружение Эструса"
	desc = "Вы обладаете особым чувством, чтобы определить, находится ли кто-то в эстральном цикле."
	value = 0
	mob_trait = TRAIT_ESTROUS_DETECT
	flavor_quirk = TRUE
	gain_text = span_love("Ваши органы чувств адаптируются, позволяя вам ощущать фертильность окружающих.")
	lose_text = span_notice("Ваши особые чувства регрессируют и вы больше не ощущаете фертильность окружающих.")
	human_only = FALSE

/datum/quirk/estrous_active
	name = "Эстральный Цикл"
	desc = "Ваш организм сгорает от желания совокупиться ради размножения. Удовлетворение вашей похоти сделает вас счастливей и ваша похоть кажется усилила шанс на оплодотворение на 25%. в то время как игнорирование этого желания может привести к тому что вы с каждой минутой становитесь плодовитей"
	value = 0
	mob_trait = TRAIT_ESTROUS_ACTIVE
	flavor_quirk = TRUE
	gain_text = span_love("Ваше тело горит от желания заняться размножением.")
	lose_text = span_notice("Вы чувствуете, что лучше контролируете свое тело и мысли.")

	// Default heat message for examine text
	var/heat_type = "нахождение в эстральном цикле"

	// Type of interaction to be performed
	// Intended for use with downstream quirks
	var/positional_orientation = "принять участие в совокуплении ради размножения"

/datum/quirk/estrous_active/add()
	// Add examine hook
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(quirk_examine_estrous_active))

	// Add organ change hooks
	RegisterSignal(quirk_holder, COMSIG_MOB_ORGAN_ADD, PROC_REF(update_heat_type))
	RegisterSignal(quirk_holder, COMSIG_MOB_ORGAN_REMOVE, PROC_REF(update_heat_type))

/datum/quirk/estrous_active/remove()
	// Remove signals
	if(!QDELETED(quirk_holder))
		UnregisterSignal(quirk_holder, list(COMSIG_MOB_ORGAN_ADD, COMSIG_MOB_ORGAN_REMOVE, COMSIG_PARENT_EXAMINE))

/datum/quirk/estrous_active/post_add()
	// Update text used by message
	update_heat_type()

/datum/quirk/estrous_active/proc/update_heat_type()
	// Define temporary list of heat phrases
	var/list/heat_phrases = list()

	// Check for male hormonal organ
	if(quirk_holder.has_balls())
		heat_phrases += "сильный стояк"

	// Check for female hormonal organ
	if(quirk_holder.getorganslot(ORGAN_SLOT_WOMB))
		heat_phrases += "сильную течку"

	// Check for synthetic
	if(isrobotic(quirk_holder))
		heat_phrases += "множество ошибок в гормональной программе"

	// Build English list
	heat_type = english_list(heat_phrases, nothing_text = "переизбыток гормонов")

/datum/quirk/estrous_active/proc/quirk_examine_estrous_active(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list)
	SIGNAL_HANDLER

	// Check if human examiner exists
	if(!istype(examiner))
		return

	// Check if examiner lacks the trait, or is self examining
	if(!HAS_TRAIT(examiner, TRAIT_ESTROUS_DETECT) || (examiner == quirk_holder))
		return

	// Add quirk message
	examine_list += span_love("<b>[quirk_holder.ru_who(TRUE)]</b> испытывает [heat_type], однозначно желая [positional_orientation].")

/datum/quirk/dnc_order
	name = "Приказ Не Клонировать"
	desc = "На вас записан приказ 'Не клонировать', в котором, как бы это странно не звучало, говорится, что вас нельзя клонировать. Вы все еще можете быть оживлены другими способами."
	value = 0
	mob_trait = TRAIT_DNC_ORDER
	medical_record_text = "Пациент имеет приказ DNC (Не Клонировать), в результате чего попытка воспользоваться клонированием будет отклонена."
