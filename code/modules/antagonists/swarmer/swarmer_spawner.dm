GLOBAL_LIST_EMPTY(standalone_swarmer_shells)
GLOBAL_VAR_INIT(standalone_swarmer_poll_active, FALSE)

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
	ghost_usable = FALSE
	var/datum/team/swarmer_team/team
	var/mob/living/simple_animal/hostile/swarmer/basic/staged_body

/obj/effect/mob_spawn/swarmer/Initialize(mapload, datum/team/swarmer_team/swarm_team, prepare_body = FALSE)
	. = ..()
	team = swarm_team
	if(team)
		LAZYADD(team.shells, src)
		if(prepare_body)
			staged_body = new(src, team)
	else
		GLOB.standalone_swarmer_shells += src
		if(SSticker.HasRoundStarted())
			recruit_standalone_swarmers()
		else
			RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(on_round_start))

/obj/effect/mob_spawn/swarmer/Destroy()
	UnregisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING)
	GLOB.standalone_swarmer_shells -= src
	QDEL_NULL(staged_body)
	if(team)
		LAZYREMOVE(team.shells, src)
	team = null
	return ..()

/obj/effect/mob_spawn/swarmer/proc/on_round_start()
	SIGNAL_HANDLER
	UnregisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(recruit_standalone_swarmers))

/proc/recruit_standalone_swarmers()
	set waitfor = FALSE
	if(GLOB.standalone_swarmer_poll_active || !length(GLOB.standalone_swarmer_shells))
		return
	GLOB.standalone_swarmer_poll_active = TRUE
	var/list/mob/dead/observer/candidates = poll_swarmer_ghosts()
	for(var/obj/effect/mob_spawn/swarmer/shell as anything in GLOB.standalone_swarmer_shells.Copy())
		if(QDELETED(shell) || shell.team || !get_turf(shell))
			continue
		while(length(candidates))
			var/mob/dead/observer/candidate = pick_n_take(candidates)
			if(candidate?.client && candidate.can_reenter_round() && shell.create(candidate.ckey))
				break
	GLOB.standalone_swarmer_poll_active = FALSE

/proc/poll_swarmer_ghosts(mega = FALSE)
	var/question = mega ? "Хотите сыграть за мегасвармера?" : "Хотите сыграть за свармера?"
	return pollGhostCandidates(question, ROLE_ALIEN, null, poll_time = 10 SECONDS, ignore_category = POLL_IGNORE_SWARMER, priority_check = FALSE)

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
