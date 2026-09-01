/obj/effect/particle_effect/smoke/miasm
	lifetime = 5
	color = "#758f40ff"
	alpha = 64

/obj/effect/particle_effect/smoke/miasm/smoke_mob(mob/living/carbon/C)
	. = ..()
	if(!.)
		return
	if(prob(15))
		C.emote(pick("frown","grumble"))
	if(prob(0.5))
		to_chat(C, "<span class='userdanger'>КАК ЖЕ ВОНЯЕТ!!! Я БОЛЬШЕ НЕ МОГУ!!!</span>")
		C.vomit(10, distance = 3)
	SEND_SIGNAL(C, COMSIG_ADD_MOOD_EVENT, "miasm", /datum/mood_event/miasm, name)

/datum/effect_system/smoke_spread/miasm
	effect_type = /obj/effect/particle_effect/smoke/miasm


/datum/mood_event/miasm
	mood_change = -3
	timeout = 1 MINUTES

/datum/mood_event/miasm/add_effects(param)
	description = "<span class='warning'>Фу! Воняет отвратительно!</span>\n"
