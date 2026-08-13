//Порт tgstation@14140a6355d, адаптация: слушаем COMSIG_MOB_ATTACK_HAND с интентом
//(нет combat_mode/modifiers), эмоция свободным текстом через "me"-эмоут в стиле wuv
//(у мобов BlueMoon нет ключевых эмоций донора), без prob(33) - паритет с прежним
//wuv-поведением питомцев, мудлет через COMSIG_ADD_MOOD_EVENT (Citadel-мудлеты).
/**
 * ## Элемент pet_bonus
 *
 * Погладил питомца - питомец делает счастливую эмоцию и пускает сердечко,
 * а гладящий получает мудлет. Замена wuv в части поглаживания.
 */
/datum/element/pet_bonus
	element_flags = ELEMENT_BESPOKE
	id_arg_index = 2
	/// Текст счастливой "me"-эмоции питомца при поглаживании
	var/emote_message
	/// Тип эмоции: EMOTE_VISIBLE или EMOTE_AUDIBLE
	var/emote_type
	/// Тайп мудлета, который получает гладящий
	var/moodlet

/datum/element/pet_bonus/Attach(datum/target, emote_message, emote_type = EMOTE_VISIBLE, moodlet = /datum/mood_event/pet_animal)
	. = ..()
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE
	src.emote_message = emote_message
	src.emote_type = emote_type
	src.moodlet = moodlet
	RegisterSignal(target, COMSIG_MOB_ATTACK_HAND, PROC_REF(on_attack_hand), override = TRUE)

/datum/element/pet_bonus/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, COMSIG_MOB_ATTACK_HAND)

/datum/element/pet_bonus/proc/on_attack_hand(mob/living/pet, mob/living/petter, act_intent)
	SIGNAL_HANDLER
	if(act_intent != INTENT_HELP || pet.stat != CONSCIOUS)
		return
	// Отложка на тик: эффекты должны выйти после сообщения "гладит"
	addtimer(CALLBACK(src, PROC_REF(pet_the_pet), pet, petter), 1)

/// Собственно радость питомца: сердечко, эмоция, мудлет гладящему
/datum/element/pet_bonus/proc/pet_the_pet(mob/living/pet, mob/living/petter)
	if(QDELETED(pet) || QDELETED(petter) || pet.stat != CONSCIOUS)
		return
	new /obj/effect/temp_visual/heart(get_turf(pet))
	SEND_SIGNAL(pet, COMSIG_ANIMAL_PET, petter)
	if(emote_message)
		pet.emote("me", emote_type, emote_message)
	if(moodlet && !(pet.flags_1 & HOLOGRAM_1)) // Гард от бесконечного счастья в голопарке
		SEND_SIGNAL(petter, COMSIG_ADD_MOOD_EVENT, "petting_bonus", moodlet, pet)
