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
	short_desc = "Вы — свармер. Собирайте ресурсы и защищайте ядро роя."
	job_description = "Swarmer"
	mob_name = "Drone Swarmer"
	category = "swarmer"
	banType = ROLE_ALIEN
	mob_type = /mob/living/simple_animal/hostile/swarmer/basic
	ghost_usable = FALSE
	var/datum/team/swarmer_team/team
	var/mob/living/simple_animal/hostile/swarmer/basic/staged_body

/obj/effect/mob_spawn/swarmer/Initialize(mapload, datum/team/swarmer_team/swarm_team, prepare_body = FALSE)
	. = ..()
	if(QDELETED(swarm_team))
		return INITIALIZE_HINT_QDEL
	team = swarm_team
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(update_ghost_access))
	LAZYADD(team.shells, src)
	if(prepare_body)
		staged_body = new(src, team)
	update_ghost_access()

/obj/effect/mob_spawn/swarmer/Destroy()
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	QDEL_NULL(staged_body)
	if(team)
		LAZYREMOVE(team.shells, src)
	team = null
	return ..()

/obj/effect/mob_spawn/swarmer/proc/update_ghost_access()
	SIGNAL_HANDLER
	var/obj/structure/swarmer/core/core = team?.swarmer_core
	var/available = !QDELETED(src) && isturf(loc) && !QDELETED(core) && !core.recruit_poll_active
	if(ghost_usable == available)
		return
	ghost_usable = available
	if(available)
		GLOB.poi_list |= src
		LAZYADD(GLOB.mob_spawners[job_description], src)
	else
		GLOB.poi_list -= src
		LAZYREMOVE(GLOB.mob_spawners[job_description], src)
		if(!LAZYLEN(GLOB.mob_spawners[job_description]))
			GLOB.mob_spawners -= job_description

/proc/poll_swarmer_ghosts(mutable_appearance/mega_icon)
	var/question = mega_icon ? "Хотите сыграть за мегасвармера?" : "Хотите сыграть за свармера?"
	var/header = mega_icon ? "Мегасвармер" : null
	return pollGhostCandidates(question, ROLE_ALIEN, null, poll_time = 10 SECONDS, ignore_category = POLL_IGNORE_SWARMER, priority_check = FALSE, poll_header = header, poll_alert_pic = mega_icon)

/obj/effect/mob_spawn/swarmer/create(ckey, name, load_character, spawn_type)
	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf || !uses || QDELETED(src))
		return
	if(QDELETED(team?.swarmer_core))
		return
	return ..()

/obj/effect/mob_spawn/swarmer/create_body(mob_path)
	if(QDELETED(staged_body) || staged_body.type != mob_path)
		return ..()
	var/mob/living/simple_animal/hostile/swarmer/basic/body = staged_body
	staged_body = null
	body.forceMove(loc)
	return body

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

/obj/effect/mob_spawn/swarmer_mega
	name = "Mega Swarmer"
	desc = "Свободный корпус мегасвармера."
	invisibility = INVISIBILITY_ABSTRACT
	density = FALSE
	death = FALSE
	roundstart = FALSE
	show_flavour = FALSE
	short_desc = "Возьмите под управление мегасвармера и защищайте ядро роя."
	job_description = "Mega Swarmer"
	mob_name = "Mega Swarmer"
	category = "swarmer"
	banType = ROLE_ALIEN
	mob_type = /mob/living/simple_animal/hostile/swarmer/mega
	ghost_usable = FALSE
	var/claiming = FALSE

/obj/effect/mob_spawn/swarmer_mega/Initialize(mapload)
	. = ..()
	var/mob/living/simple_animal/hostile/swarmer/mega/body = loc
	if(!istype(body))
		return INITIALIZE_HINT_QDEL
	RegisterSignal(body, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(on_body_login))

/obj/effect/mob_spawn/swarmer_mega/Destroy()
	if(ismob(loc))
		UnregisterSignal(loc, COMSIG_MOB_CLIENT_LOGIN)
	return ..()

/obj/effect/mob_spawn/swarmer_mega/proc/on_body_login()
	SIGNAL_HANDLER
	if(!claiming)
		qdel(src)

/obj/effect/mob_spawn/swarmer_mega/proc/offer_to_ghosts()
	if(QDELETED(src) || !body_available())
		return
	var/list/mob/dead/observer/candidates = poll_swarmer_ghosts(mutable_appearance(loc.icon, loc.icon_state))
	if(QDELETED(src) || !body_available())
		return
	while(length(candidates))
		var/mob/dead/observer/candidate = pick_n_take(candidates)
		if(candidate?.client && candidate.can_reenter_round() && create(candidate.ckey))
			return
	ghost_usable = TRUE
	GLOB.poi_list |= src
	LAZYADD(GLOB.mob_spawners[job_description], src)

/obj/effect/mob_spawn/swarmer_mega/proc/body_available()
	var/mob/living/simple_animal/hostile/swarmer/mega/body = loc
	return istype(body) && !QDELETED(body) && body.stat != DEAD && !body.key && !QDELETED(body.team?.swarmer_core) && SSticker.IsRoundInProgress()

/obj/effect/mob_spawn/swarmer_mega/can_latejoin()
	return FALSE

/obj/effect/mob_spawn/swarmer_mega/allow_spawn(mob/user, silent = FALSE)
	return isobserver(user) && body_available() && !claiming && !jobban_isbanned(user, ROLE_INTEQ)

/obj/effect/mob_spawn/swarmer_mega/create(ckey, name, load_character, spawn_type)
	if(QDELETED(src) || !ckey || !uses || claiming || !body_available())
		return
	claiming = TRUE
	ghost_usable = FALSE
	return ..()

/obj/effect/mob_spawn/swarmer_mega/create_body(mob_path)
	return loc

/obj/effect/mob_spawn/swarmer_mega/special(mob/M)
	var/mob/living/simple_animal/hostile/swarmer/mega/body = M
	body.add_datum_if_not_exist()
	log_game("[key_name(body)] получил роль мегасвармера.")
