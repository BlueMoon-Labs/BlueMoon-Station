/datum/quirk/powersaving
	name = BLUEMOON_TRAIT_NAME_POWERSAVING
	desc = "ТОЛЬКО ДЛЯ СИНТЕТИКОВ! Ваше аппаратное обеспечение использует самые современные методики энергосбережения, благодаря чему вы разряжаетесь примерно на 40% медленнее."
	value = 2
	gain_text = span_danger("Выключение NTVIDIA 9090 экономит мне 400 ватт???")
	lose_text = span_notice("Стоп, как я буду смотреть новые выпуски JuicyMoons в 24k UltraMegaHD без своей 9090? Нужно включить её обратно...")
	on_spawn_immediate = FALSE // иначе on_spawn из-за потенциального удаления квирка ломается
	mob_trait = TRAIT_BLUEMOON_POWERSAVING

/datum/quirk/powersaving/on_spawn()
	. = ..()
	if(!isrobotic(quirk_holder))
		to_chat(quirk_holder, span_warning("Все квирки были сброшены, т.к. квирк [src] не подходит виду персонажа."))
		var/list/user_quirks = quirk_holder.roundstart_quirks
		user_quirks -= src
		for(var/datum/quirk/Q as anything in user_quirks)
			qdel(Q)
		qdel(src)

/datum/quirk/powersaving/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!istype(H) || !isrobotic(H))
		return
	H.physiology.hunger_mod *= 0.6

/datum/quirk/powersaving/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!istype(H) || !isrobotic(H))
		return
	if(!H.physiology)
		return
	H.physiology.hunger_mod /= 0.6
