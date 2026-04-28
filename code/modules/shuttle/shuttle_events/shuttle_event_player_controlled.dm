/// Mobs that try to give ghosts control before appearing near the shuttle (tg-style).
/datum/shuttle_event/simple_spawner/player_controlled
	/// If no ghost signs up, still spawn a hostile NPC when TRUE
	var/spawn_anyway_if_no_player = FALSE
	var/ghost_alert_string = "Хотите появиться у эвакуационного шаттла?"
	var/role_type = ROLE_SENTIENCE

/datum/shuttle_event/simple_spawner/player_controlled/spawn_movable(spawn_type)
	if(ispath(spawn_type, /mob/living))
		INVOKE_ASYNC(src, PROC_REF(async_try_player_mob), spawn_type)
	else
		return ..()

/datum/shuttle_event/simple_spawner/player_controlled/proc/async_try_player_mob(spawn_type)
	var/list/winners = pollCandidates("[ghost_alert_string] (Вы не вернётесь в прежнее тело!)", role_type, null, role_type, 10 SECONDS, null, TRUE, get_all_ghost_role_eligible())
	var/turf/spawn_point = get_spawn_turf()
	if(!spawn_point)
		return
	if(!length(winners) && !spawn_anyway_if_no_player)
		return
	var/mob/living/new_mob = new spawn_type(spawn_point)
	post_spawn(new_mob)
	if(length(winners))
		var/mob/chosen = pick(winners)
		if(chosen && isobserver(chosen))
			new_mob.ckey = chosen.ckey
	else if(!spawn_anyway_if_no_player)
		qdel(new_mob)

/// Alien queen — single ghost role.
/datum/shuttle_event/simple_spawner/player_controlled/alien_queen
	name = "Королева ксеноморфов"
	spawning_list = list(/mob/living/carbon/alien/humanoid/royal/queen = 1)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	event_probability = 1
	spawn_probability_per_process = 10
	activation_fraction = 0.5
	spawn_anyway_if_no_player = FALSE
	ghost_alert_string = "Хотите сыграть за королеву ксеноморфов у шаттла?"
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE
	role_type = ROLE_ALIEN

/datum/shuttle_event/simple_spawner/player_controlled/human
	name = "Человек (игрок)"

/// Up to three ghost-controlled carp.
/datum/shuttle_event/simple_spawner/player_controlled/carp
	name = "Космические карпы (игроки)"
	spawning_list = list(
		/mob/living/simple_animal/hostile/carp = 10,
		/mob/living/simple_animal/hostile/carp/megacarp = 2,
		/mob/living/simple_animal/hostile/carp/ranged = 2,
		/mob/living/simple_animal/hostile/carp/ranged/chaos = 1,
	)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	event_probability = 2
	spawn_probability_per_process = 10
	activation_fraction = 0.4
	spawn_anyway_if_no_player = TRUE
	ghost_alert_string = "Хотите сыграть за космического карпа у эвакуационного шаттла?"
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE
	role_type = ROLE_SENTIENCE
	var/max_carp_spawns = 3

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
