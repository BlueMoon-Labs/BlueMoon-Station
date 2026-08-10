/// Mobs that try to give ghosts control before appearing near the shuttle (tg-style).
/datum/shuttle_event/simple_spawner/player_controlled
	/// If no ghost signs up, still spawn a hostile NPC when TRUE
	var/spawn_anyway_if_no_player = FALSE
	var/ghost_alert_string = "Хотите появиться у эвакуационного шаттла?"
	var/role_type = ROLE_SENTIENCE
	var/batch_spawn_started = FALSE

/datum/shuttle_event/simple_spawner/player_controlled/spawn_movable(spawn_type)
	if(batch_spawn_started)
		return FALSE
	if(!ispath(spawn_type, /mob/living))
		return ..()
	var/list/batch = build_batch_spawn_types()
	if(!length(batch))
		return FALSE
	batch_spawn_started = TRUE
	INVOKE_ASYNC(src, PROC_REF(async_batch_spawn_players), batch)
	return TRUE

/// Flatten spawning_list counts into an ordered spawn queue; clears the list when configured.
/datum/shuttle_event/simple_spawner/player_controlled/proc/build_batch_spawn_types()
	var/list/result = list()
	for(var/typepath in spawning_list)
		var/count = spawning_list[typepath]
		for(var/i in 1 to count)
			result += typepath
	if(remove_from_list_when_spawned)
		spawning_list.Cut()
	return result

/datum/shuttle_event/simple_spawner/player_controlled/proc/get_batch_poll_message(count)
	if(count > 1)
		return "[ghost_alert_string] (До [count] ролей. Вы не вернётесь в прежнее тело!)"
	return "[ghost_alert_string] (Вы не вернётесь в прежнее тело!)"

/datum/shuttle_event/simple_spawner/player_controlled/proc/async_batch_spawn_players(list/spawn_types)
	var/count = length(spawn_types)
	var/list/winners = pollCandidates(
		get_batch_poll_message(count),
		role_type,
		null,
		role_type,
		10 SECONDS,
		null,
		TRUE,
		get_all_ghost_role_eligible(),
	)

	for(var/spawn_type in spawn_types)
		var/turf/spawn_point = get_spawn_turf()
		if(!spawn_point)
			break
		var/mob/living/new_mob = new spawn_type(spawn_point)
		post_spawn(new_mob)
		if(length(winners))
			var/mob/chosen = winners[1]
			winners.Cut(1, 2)
			if(chosen && isobserver(chosen))
				if(!assign_ghost_to_mob(chosen, new_mob))
					qdel(new_mob)
					continue
				post_player_assigned(new_mob)
				continue
		if(spawn_anyway_if_no_player)
			on_batch_npc_spawn(new_mob)
		else
			qdel(new_mob)

/// Called for batch slots with no ghost player when spawn_anyway_if_no_player is TRUE.
/datum/shuttle_event/simple_spawner/player_controlled/proc/on_batch_npc_spawn(mob/living/mob)
	return

/datum/shuttle_event/simple_spawner/player_controlled/proc/post_player_assigned(mob/living/mob)
	return

/// Transfers a ghost into a living mob and resets camera/orbit state.
/datum/shuttle_event/simple_spawner/player_controlled/proc/assign_ghost_to_mob(mob/chosen, mob/living/new_mob)
	if(!chosen || !isobserver(chosen) || !new_mob)
		return FALSE
	var/mob/dead/observer/ghost = chosen
	if(ghost.orbiting)
		ghost.orbiting.end_orbit(ghost)
	ghost.reset_perspective(null)
	ghost.transfer_ckey(new_mob, FALSE)
	new_mob.reset_perspective(null)
	return TRUE

/// Alien queen — single ghost role.
/datum/shuttle_event/simple_spawner/player_controlled/alien_queen
	name = "Королева ксеноморфов"
	spawning_list = list(/mob/living/carbon/alien/humanoid/royal/queen = 1)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	event_probability = 10
	spawn_probability_per_process = 10
	activation_fraction = 0.5
	spawn_anyway_if_no_player = FALSE
	ghost_alert_string = "Хотите сыграть за королеву ксеноморфов у шаттла?"
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE
	role_type = ROLE_ALIEN

/datum/shuttle_event/simple_spawner/player_controlled/human
	name = "Человек (игрок)"
	admin_forceable = FALSE

/// Up to nine ghost-controlled carp — one poll, full wave.
/datum/shuttle_event/simple_spawner/player_controlled/carp
	name = "Космические карпы (игроки)"
	spawning_list = list(
		/mob/living/simple_animal/hostile/carp = 10,
		/mob/living/simple_animal/hostile/carp/megacarp = 2,
		/mob/living/simple_animal/hostile/carp/ranged = 2,
		/mob/living/simple_animal/hostile/carp/ranged/chaos = 1,
	)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	event_probability = 20
	spawn_probability_per_process = 10
	activation_fraction = 0.4
	spawn_anyway_if_no_player = TRUE
	ghost_alert_string = "Хотите сыграть за космического карпа у эвакуационного шаттла?"
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE
	role_type = ROLE_SENTIENCE
	var/max_carp_spawns = 9

/datum/shuttle_event/simple_spawner/player_controlled/carp/get_batch_poll_message(count)
	return "[ghost_alert_string] (До [count] карпов. Вы не вернётесь в прежнее тело!)"

/datum/shuttle_event/simple_spawner/player_controlled/carp/New(obj/docking_port/mobile/port)
	var/list/template = list(
		/mob/living/simple_animal/hostile/carp = 10,
		/mob/living/simple_animal/hostile/carp/megacarp = 2,
		/mob/living/simple_animal/hostile/carp/ranged = 2,
		/mob/living/simple_animal/hostile/carp/ranged/chaos = 1,
	)
	spawning_list.Cut()
	for(var/j in 1 to max_carp_spawns)
		var/chosen_type = pickweight(template)
		spawning_list[chosen_type] = (spawning_list[chosen_type] || 0) + 1
	. = ..(port)

/// ERT MOPP — ghost roles, one poll, spawn on shuttle decks after it docks at the station.
/datum/shuttle_event/simple_spawner/player_controlled/human_shuttle/ert_mopp
	name = "ОБР MOPP (подкрепление к шаттлу)"
	spawning_list = list(/mob/living/carbon/human = 5)
	spawn_anyway_if_no_player = FALSE
	ghost_alert_string = "Подкрепление ОБР MOPP прибыло на эвакуационный шаттл. Зайти за оперативника?"
	role_type = ROLE_SENTIENCE
	event_probability = 50
	var/next_mopp_index = 1
	var/list/spawning_turfs_interior = list()
	var/static/list/mopp_outfit_paths = list(
		/datum/outfit/ert/commander/mopp,
		/datum/outfit/ert/security/mopp,
		/datum/outfit/ert/medic/mopp,
		/datum/outfit/ert/engineer/mopp,
	)

/datum/shuttle_event/simple_spawner/player_controlled/human_shuttle/ert_mopp/get_batch_poll_message(count)
	return "[ghost_alert_string] (До [count] оперативников. Вы не вернётесь в прежнее тело!)"

/datum/shuttle_event/simple_spawner/player_controlled/human_shuttle/ert_mopp/proc/trigger_station_dock_spawn()
	if(batch_spawn_started)
		return
	spawning_turfs_interior = get_mobile_shuttle_interior_turfs(port)
	if(!length(spawning_turfs_interior))
		return
	next_mopp_index = 1
	var/list/batch = build_batch_spawn_types()
	if(!length(batch))
		return
	batch_spawn_started = TRUE
	INVOKE_ASYNC(src, PROC_REF(async_batch_spawn_ert_mopp), batch)

/datum/shuttle_event/simple_spawner/player_controlled/human_shuttle/ert_mopp/proc/async_batch_spawn_ert_mopp(list/spawn_types)
	var/max_slots = length(spawn_types)
	var/list/winners = pollCandidates(
		get_batch_poll_message(max_slots),
		role_type,
		null,
		role_type,
		15 SECONDS,
		null,
		TRUE,
		get_all_ghost_role_eligible(),
	)
	if(!length(winners))
		return
	var/spawn_count = min(max_slots, length(winners))
	priority_announce(
		"На борту эвакуационного шаттла зафиксировано подкрепление ОБР MOPP ([spawn_count] чел.).",
		null,
		"shuttledock",
		"Priority",
	)
	for(var/i in 1 to spawn_count)
		var/spawn_type = spawn_types[i]
		var/turf/spawn_point = get_spawn_turf()
		if(!spawn_point)
			break
		var/mob/chosen = winners[i]
		if(!chosen || !isobserver(chosen))
			continue
		var/mob/living/carbon/human/H = new spawn_type(spawn_point)
		post_spawn(H)
		equip_mopp_outfit(H)
		if(!assign_ghost_to_mob(chosen, H))
			qdel(H)
			continue
		post_player_assigned(H)

/datum/shuttle_event/simple_spawner/player_controlled/human_shuttle/ert_mopp/get_spawn_turf()
	if(!length(spawning_turfs_interior))
		return null
	return pick(spawning_turfs_interior)

/datum/shuttle_event/simple_spawner/player_controlled/human_shuttle/ert_mopp/post_spawn(atom/movable/spawnee)
	return

/datum/shuttle_event/simple_spawner/player_controlled/human_shuttle/ert_mopp/post_player_assigned(mob/living/mob)
	if(!ishuman(mob))
		return
	var/mob/living/carbon/human/H = mob
	ADD_TRAIT(H, TRAIT_EXEMPT_HEALTH_EVENTS, GHOSTROLE_TRAIT)
	ADD_TRAIT(H, TRAIT_NO_MIDROUND_ANTAG, GHOSTROLE_TRAIT)
	to_chat(H, span_boldannounce("Вы — оперативник ОБР MOPP, прибывший на эвакуационный шаттл для помощи экипажу."))

/datum/shuttle_event/simple_spawner/player_controlled/human_shuttle/ert_mopp/proc/equip_mopp_outfit(mob/living/carbon/human/H)
	if(QDELETED(H) || !length(mopp_outfit_paths))
		return
	var/slot = min(next_mopp_index, mopp_outfit_paths.len)
	H.equipOutfit(mopp_outfit_paths[slot])
	next_mopp_index++

/// Must live after /ert_mopp — emergency.dm is compiled earlier in the .dme.
/obj/docking_port/mobile/emergency/proc/try_station_dock_ert_mopp()
	var/datum/shuttle_event/simple_spawner/player_controlled/human_shuttle/ert_mopp/event = new /datum/shuttle_event/simple_spawner/player_controlled/human_shuttle/ert_mopp(src)
	if(!prob(event.event_probability))
		qdel(event)
		return
	event.trigger_station_dock_spawn()
