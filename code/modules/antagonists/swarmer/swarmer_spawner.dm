/obj/item/deactivated_swarmer
	name = "deactivated swarmer shell"
	desc = "Обесточенная оболочка свармера."
	icon = 'icons/mob/swarmer.dmi'
	icon_state = "swarmer_unactivated"
	custom_materials = list(/datum/material/iron = 10000, /datum/material/glass = 4000)

/obj/effect/mob_spawn/swarmer
	name = "unactivated swarmer shell"
	desc = "Оболочка свармера. Её можно деактивировать отвёрткой."
	icon = 'icons/mob/swarmer.dmi'
	icon_state = "swarmer_unactivated"
	density = FALSE
	anchored = FALSE
	death = FALSE
	roundstart = FALSE
	show_flavour = FALSE
	job_description = "Swarmer"
	mob_name = "Drone Swarmer"
	category = "swarmer"
	banType = ROLE_ALIEN
	mob_type = /mob/living/simple_animal/hostile/swarmer/basic
	var/datum/team/swarmer_team/team

/obj/effect/mob_spawn/swarmer/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	team = swarm_team
	if(team)
		LAZYADD(team.shells, src)
	notify_ghosts("На станции появилась оболочка свармера.", source = src, action = NOTIFY_ATTACK, flashwindow = FALSE)

/obj/effect/mob_spawn/swarmer/Destroy()
	if(team)
		LAZYREMOVE(team.shells, src)
	team = null
	return ..()

/obj/effect/mob_spawn/swarmer/create(ckey, name, load_character, spawn_type)
	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf || !uses || QDELETED(src))
		return
	if(!team)
		team = new
		LAZYADD(team.shells, src)
		new /obj/structure/swarmer/core(spawn_turf, team)
	if(QDELETED(team.swarmer_core))
		return
	return ..()

/obj/effect/mob_spawn/swarmer/equip(mob/M, load_character)
	var/mob/living/simple_animal/hostile/swarmer/body = M
	body.join_swarm(team)

/obj/effect/mob_spawn/swarmer/special(mob/M, name)
	var/mob/living/simple_animal/hostile/swarmer/body = M
	body.add_datum_if_not_exist()

/obj/effect/mob_spawn/swarmer/screwdriver_act(mob/living/user, obj/item/I)
	if(I.use_tool(src, user, 3 SECONDS, volume = 50) && !QDELETED(src))
		new /obj/item/deactivated_swarmer(get_turf(src))
		qdel(src)
	return TRUE

/obj/effect/mob_spawn/swarmer/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_TEAM
