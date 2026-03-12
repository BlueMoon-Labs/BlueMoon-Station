/datum/quirk/syscleaner
	name = BLUEMOON_TRAIT_NAME_SYSCLEANER
	desc = "ТОЛЬКО ДЛЯ СИНТЕТИКОВ! У вас установлена очень параноидальная система, которая постоянно проверяет целостность прошивки и восстанавливает её из бэкапов при малейших отклонениях. Это позволяет восстанавливать повреждения ПО (aka \"токсины\"), однако процесс увеличивает потребление энергии и мешает эффективной работе систем защиты от ЭМИ."
	gain_text = span_warning("Резервное копирование завершено. Рекомендация: удаление директории furryporn может ускорить процесс примерно на 400%.")
	lose_text = span_notice("Кому нужны бэкапы? Я использую самую стабильную операционную систему в мире...")
	value = 2
	mob_trait = TRAIT_BLUEMOON_SYSCLEANER
	on_spawn_immediate = FALSE // иначе on_spawn из-за потенциального удаления квирка ломается
	processing_quirk = TRUE
	var/syscleaning_in_progress = FALSE

/datum/quirk/syscleaner/on_spawn()
	. = ..()
	if(!isrobotic(quirk_holder))
		to_chat(quirk_holder, span_warning("Все квирки были сброшены, т.к. квирк [src] не подходит виду персонажа."))
		var/list/user_quirks = quirk_holder.roundstart_quirks
		user_quirks -= src
		for(var/datum/quirk/Q as anything in user_quirks)
			qdel(Q)
		qdel(src)

/datum/quirk/syscleaner/on_process()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	if (!istype(H))
		return

	var/consumed_damage = H.getToxLoss(TOX_SYSCORRUPT)
	if (!consumed_damage)
		if(syscleaning_in_progress)
			REMOVE_TRAIT(H, TRAIT_SYSCLEANER_IN_PROGRESS, QUIRK_TRAIT)
			if(H.physiology)
				H.physiology.hunger_mod /= 1.6
			syscleaning_in_progress = FALSE
		return

	if(!syscleaning_in_progress)
		if(!H.physiology)
			return
		ADD_TRAIT(H, TRAIT_SYSCLEANER_IN_PROGRESS, QUIRK_TRAIT)
		H.physiology.hunger_mod *= 1.6
		syscleaning_in_progress = TRUE

	var/heal_multiplier = H.getMaxHealth() / 100
	var/toxheal = -0.6

	if (consumed_damage > 40 * heal_multiplier)
		heal_multiplier *= 0.5
	H.adjustToxLoss(toxheal * heal_multiplier, TRUE, TRUE, TOX_SYSCORRUPT)

/datum/quirk/syscleaner/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if (!istype(H) || !syscleaning_in_progress)
		return
	if(H.physiology)
		H.physiology.hunger_mod /= 1.6
	REMOVE_TRAIT(quirk_holder, TRAIT_SYSCLEANER_IN_PROGRESS, QUIRK_TRAIT)
