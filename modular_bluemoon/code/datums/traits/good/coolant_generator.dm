/datum/quirk/coolant_generator
	name = BLUEMOON_TRAIT_NAME_COOLANT_GENERATOR
	desc = "ТОЛЬКО ДЛЯ СИНТЕТИКОВ! В вашей системе охлаждения используется упрощённая версия охлаждающей жидкости, а также установлен компактный аппарат по дистилляции и переработке воды, позволяющий эффективно генерировать хладагент при её потреблении. Данная система увеличивает постоянное энергопотребление примерно на 15%."
	value = 2
	gain_text = span_danger("Интересно, у органиков иногда возникает желание пустить воду по вене?")
	lose_text = span_notice("Охлаждение водой - прошлый век. Я буду охлаждаться на пиве, прямо как РБМК!")
	on_spawn_immediate = FALSE // иначе on_spawn из-за потенциального удаления квирка ломается
	// Сама работа квирка заключается в этом трейте, который влияет на метаболизацию воды
	mob_trait = TRAIT_BLUEMOON_COOLANT_GENERATOR

/datum/quirk/coolant_generator/on_spawn()
	. = ..()
	if(!isrobotic(quirk_holder))
		to_chat(quirk_holder, span_warning("Все квирки были сброшены, т.к. квирк [src] не подходит виду персонажа."))
		var/list/user_quirks = quirk_holder.roundstart_quirks
		user_quirks -= src
		for(var/datum/quirk/Q as anything in user_quirks)
			qdel(Q)
		qdel(src)

/datum/quirk/coolant_generator/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!istype(H) || !isrobotic(H))
		return
	H.physiology.hunger_mod *= 1.15

/datum/quirk/coolant_generator/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!istype(H) || !isrobotic(H))
		return
	if(!H.physiology)
		return
	H.physiology.hunger_mod /= 1.15

