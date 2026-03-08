GLOBAL_LIST_INIT(shriek_types, list(\
				SHRIEK_TYPE_GENERIC, SHRIEK_TYPE_GORILLA, SHRIEK_TYPE_ROAR, SHRIEK_TYPE_XENOMORPH, SHRIEK_TYPE_XENOMORPH_QUEEN, SHRIEK_TYPE_TERROR_SPIDER_QUEEN,
				SHRIEK_TYPE_TERROR_SPIDER_1, SHRIEK_TYPE_TERROR_SPIDER_2, SHRIEK_TYPE_TERROR_SPIDER_3, SHRIEK_TYPE_TERROR_SPIDER_4, SHRIEK_TYPE_TERROR_SPIDER_5,
				SHRIEK_TYPE_BIRD_1, SHRIEK_TYPE_BIRD_2, SHRIEK_TYPE_WEIL))

/datum/preferences
	var/shriek_type = SHRIEK_TYPE_GENERIC // вид крика

/*
 * ДЕЙСТВИЕ
 */

/datum/action/cooldown/shriek
	name = "Shriek"
	desc = "Вы издаёте особо громкий крик, вызывающий неприятные ощущения у окружающих."
	icon_icon = 'icons/mob/actions/actions.dmi'
	button_icon_state = "vampire_screech"
	cooldown_time = 400 // КД, 40 секунд
	transparent_when_unavailable = TRUE

/datum/action/cooldown/shriek/Activate()
	var/mob/living/carbon/human/H = owner
	var/sound_type = SHRIEK_TYPE_GENERIC
	var/sound_description = "крик"
	switch(H.client?.prefs.shriek_type)
		if(SHRIEK_TYPE_GENERIC)
			sound_type = "sound/voice/shriek1.ogg"
			sound_description = "протяжный крик"
		if(SHRIEK_TYPE_ROAR)
			sound_type = "sound/creatures/space_dragon_roar.ogg"
			sound_description = "протяжный рык"
		if(SHRIEK_TYPE_GORILLA)
			sound_type = "sound/creatures/gorilla.ogg"
			sound_description = "клич гранта"
		if(SHRIEK_TYPE_XENOMORPH_QUEEN)
			sound_type = "sound/creatures/terrorspiders/queen_shriek.ogg"
			sound_description = "протяжный крик"
		if(SHRIEK_TYPE_TERROR_SPIDER_QUEEN)
			sound_type = "sound/creatures/terrorspiders/princess_shriek.ogg"
			sound_description = "протяжный крик"
		if(SHRIEK_TYPE_TERROR_SPIDER_1)
			sound_type = "sound/creatures/terrorspiders/death1.ogg"
			sound_description = "протяжный крик"
		if(SHRIEK_TYPE_TERROR_SPIDER_2)
			sound_type = "sound/creatures/terrorspiders/death2.ogg"
			sound_description = "протяжный крик"
		if(SHRIEK_TYPE_TERROR_SPIDER_3)
			sound_type = "sound/creatures/terrorspiders/death4.ogg"
			sound_description = "протяжный крик"
		if(SHRIEK_TYPE_TERROR_SPIDER_4)
			sound_type = "sound/creatures/terrorspiders/death5.ogg"
			sound_description = "протяжный крик"
		if(SHRIEK_TYPE_TERROR_SPIDER_5)
			sound_type = "sound/creatures/terrorspiders/death6.ogg"
			sound_description = "протяжный крик"
		if(SHRIEK_TYPE_BIRD_1)
			sound_type = "sound/voice/scream/bird1.ogg"
			sound_description = "птичий крик"
		if(SHRIEK_TYPE_BIRD_2)
			sound_type = "sound/voice/scream/bird2.ogg"
			sound_description = "птичий крик"
		if(SHRIEK_TYPE_WEIL)
			sound_type = "sound/hallucinations/wail.ogg"
			sound_description = "протяжный вопль"
		if(SHRIEK_TYPE_XENOMORPH)
			sound_type = "sound/alien/Voice/screech[pick(rand(1,4))].ogg"
			sound_description = "протяжный вопль"

	playsound(get_turf(H), sound_type, 100, TRUE)
	H.visible_message(span_boldwarning("[H] издаёт [sound_description]!"), span_notice("Вы издаёте [sound_description]!"))
	H.balloon_alert_to_viewers("Издаёт [sound_description]!",  ignored_mobs = list(H)) // сообщение над персонажем при крике
	H.Shake(3, 3, 25) // тряска крикуна

	for(var/obj/machinery/light/L in view(4, get_turf(owner)))
		if(prob(30))
			L.flicker(3)
	for(var/mob/living/L in view(5, get_turf(owner)))
		if(!L.mind) // игрок не на месте, смысла нет
			continue
		if(HAS_TRAIT(L, TRAIT_BLUEMOON_SHRIEK))
			continue
		if(L.get_ear_protection() == FALSE)
			shake_camera(L, 2, 0.3)
			L.jitteriness += rand(2, 4)

	StartCooldown()
/*
 * КВИРК
 */

/datum/quirk/shriek
	name = BLUEMOON_TRAIT_NAME_SHRIEK
	desc = "Вы способны издавать особо громкий крик, мешающий работе систем освящения и вызыващий неприятные ощущения у всех, кто его услышит без защиты. \
	Такие же крикуны не почувствуют эффекта на себе. (Для настройки крика, используйте параметр Тип Крика в заголовке окна)"
	value = 1
	mob_trait = TRAIT_BLUEMOON_SHRIEK

/datum/quirk/shriek/add()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H)
		return
	var/datum/action/cooldown/shriek/C = new
	C.Grant(H)

/datum/quirk/shriek/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H)
		return
	var/datum/action/cooldown/shriek/C = locate() in H.actions
	C?.Remove(H)
	. = ..()
