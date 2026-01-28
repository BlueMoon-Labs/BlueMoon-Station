/obj/structure/shield
	name = "Heavy Shield"
	desc = "Густой, плотный, энергетический щит. Обычно, таких хватает на галактический час."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-red"
	density = FALSE
	anchored = TRUE
	opacity = FALSE//from TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/walltimer // tracks this wall's specific timer

#define FOG_DISSIPATE_TIME_MAX 60 MINUTES
GLOBAL_LIST_EMPTY(trespass_warns) // to avoid spamming the bandit's chat

/obj/structure/shield/Initialize()
	. = ..()
	walltimer = addtimer(CALLBACK(src, PROC_REF(dissipate_fog)), FOG_DISSIPATE_TIME_MAX, TIMER_STOPPABLE)

/obj/structure/shield/Destroy()
	deltimer(walltimer)
	walltimer = null
	return ..()

/obj/structure/shield/proc/dissipate_fog()
	qdel(src)

/datum/atom_hud/alternate_appearance/shield/mobShouldSee(mob/M)
	return TRUE

/obj/structure/shield/proc/describe_time()
	var/timedesc = "...хм, ну даже не знаю"
	switch(timeleft(walltimer))
		if(1 to 5 MINUTES)
			timedesc = "пропадающим"
		if(5 MINUTES to 15 MINUTES)
			timedesc = "почти что пропадающим"
		if(15 MINUTES to 30 MINUTES)
			timedesc = "достаточно рабочим"
		if(30 MINUTES to FOG_DISSIPATE_TIME_MAX)
			timedesc = "более чем рабочим"
	return timedesc

/obj/structure/shield/examine(mob/user)
	. = ..()
	. += span_info("В данный момент, энергетический щит смотрится [span_notice(describe_time())]. | Вторжение через энергетические щиты взведёт ракеты типа КОСМОС-КОСМОС ближайшего фрегата в активное состояние")

/obj/structure/shield/CanPass(atom/movable/AM)
	if(AM in GLOB.trespass_warns)
		return FALSE
	if(isliving(AM))
		var/mob/living/M = AM
		to_chat(M, span_warning("Я не могу пройти через щит.") + span_info("\n\
							В данный момент, щит смотрится [span_notice(describe_time())]."))
		GLOB.trespass_warns += M
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(clear_trespass_warning), M), 40 SECONDS)
		return FALSE

/proc/clear_trespass_warning(mob/target)
	if(target)
		GLOB.trespass_warns -= target

/obj/structure/shield/yellow
	icon_state = "shield-yellow"

/obj/structure/shield/golden
	icon_state = "shield-golden"

/obj/structure/shield/grey
	icon_state = "shield-grey"

/obj/structure/shield/blue
	icon_state = "shield-old"
