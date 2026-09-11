/// Домен удерживает холод и метки, пока враг находится внутри. Объекты и броски продолжают двигаться.
/obj/effect/domain_expansion
	parent_type = /obj/effect/heretic_combat_zone/void
	name = "Бесконечная пустота"
	desc = "Бледная печать вымывает краски из мира, сковывает шаг и отнимает голос. Покиньте её границу, чтобы избавиться от холода."
	radius = 3
	duration = 20 SECONDS
	var/list/immune = list()

/obj/effect/domain_expansion/Initialize(mapload, new_radius, new_duration, list/immune_atoms, start = TRUE)
	if(isnum(new_radius))
		radius = clamp(new_radius, 1, 5)
	if(isnum(new_duration))
		duration = max(1, new_duration)
	var/datum/mind/master
	for(var/mob/living/creator as anything in immune_atoms)
		immune |= creator
		if(!master)
			master = creator.mind
	. = ..(mapload, master)
	if(!start)
		STOP_PROCESSING(SSprocessing, src)

/obj/effect/domain_expansion/tick_zone(mob/living/user, list/visible)
	..()
	for(var/mob/living/victim as anything in affected)
		if(!(victim in immune))
			if(!victim.has_status_effect(/datum/status_effect/eldritch/void))
				victim.apply_status_effect(/datum/status_effect/eldritch/void)
			var/datum/status_effect/heretic_domain/presence = victim.has_status_effect(/datum/status_effect/heretic_domain)
			if(!presence)
				presence = victim.apply_status_effect(/datum/status_effect/heretic_domain)
			if(presence)
				presence.domains |= src

/obj/effect/domain_expansion/release_affected(list/victims)
	for(var/mob/living/victim as anything in victims)
		release_presence(victim)
	return ..()

/obj/effect/domain_expansion/proc/release_presence(mob/living/victim)
	if(QDELETED(victim))
		return
	var/datum/status_effect/heretic_domain/presence = victim.has_status_effect(/datum/status_effect/heretic_domain)
	presence?.remove_domain(src)

/obj/effect/domain_expansion/Destroy()
	immune.Cut()
	return ..()

/obj/effect/domain_expansion/magic
