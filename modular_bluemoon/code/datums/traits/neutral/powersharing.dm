/datum/quirk/powersharing
	name = BLUEMOON_TRAIT_NAME_POWERSHARING
	desc = "ТОЛЬКО ДЛЯ СИНТЕТИКОВ! Вы можете использовать в руке свой имплант зарядки, чтобы переключить его в режим раздачи энергии, чтобы заряжать ЛКП и батареи из своего аккумулятора. Если другой синтетик держит в руке зарядник, вы можете поделиться с ним зарядкой. К сожалению, эта модификация увеличивает постоянное потребление энергии на 5%."
	value = 0
	gain_text = span_danger("Я могу делиться энергией с другими!")
	lose_text = span_notice("Я вам что, павербанк? Катитесь к чёрту!")
	on_spawn_immediate = FALSE // иначе on_spawn из-за потенциального удаления квирка ломается
	mob_trait = TRAIT_BLUEMOON_POWERSHARING

/datum/quirk/powersharing/on_spawn()
	. = ..()
	if(!isrobotic(quirk_holder))
		to_chat(quirk_holder, span_warning("Все квирки были сброшены, т.к. квирк [src] не подходит виду персонажа."))
		var/list/user_quirks = quirk_holder.roundstart_quirks
		user_quirks -= src
		for(var/datum/quirk/Q as anything in user_quirks)
			qdel(Q)
		qdel(src)

/datum/quirk/powersharing/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!istype(H) || !isrobotic(H))
		return
	H.physiology.hunger_mod *= 1.05

/datum/quirk/powersharing/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!istype(H) || !isrobotic(H))
		return
	if(!H.physiology)
		return
	H.physiology.hunger_mod /= 1.05
