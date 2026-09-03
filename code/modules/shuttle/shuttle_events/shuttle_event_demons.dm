/// Ghost-poll imps near the evacuation shuttle; hostile NPCs if ghosts decline.
/datum/shuttle_event/simple_spawner/player_controlled/imp
	name = "Импы гиперпространства"
	spawning_list = list(/mob/living/simple_animal/imp = 12)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	event_probability = 40
	spawn_probability_per_process = 10
	activation_fraction = 0.2
	spawn_anyway_if_no_player = TRUE
	ghost_alert_string = "Хотите сыграть за беса у эвакуационного шаттла?"
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE
	role_type = ROLE_SENTIENCE

/datum/shuttle_event/simple_spawner/player_controlled/imp/get_batch_poll_message(count)
	return "[ghost_alert_string] (До [count] бесов. Вы не вернётесь в прежнее тело!)"

/datum/shuttle_event/simple_spawner/player_controlled/imp/start_up_event(evacuation_duration)
	. = ..()
	if(length(spawning_turfs_hit))
		shuffle_inplace(spawning_turfs_hit)

/datum/shuttle_event/simple_spawner/player_controlled/imp/get_spawn_turf()
	if(!length(spawning_turfs_hit))
		return null
	return pick(spawning_turfs_hit)

/datum/shuttle_event/simple_spawner/player_controlled/imp/proc/apply_imp_antag(mob/living/mob)
	if(!istype(mob, /mob/living/simple_animal/imp) || !mob.mind)
		return
	mob.mind.add_antag_datum(new /datum/antagonist/imp())

/datum/shuttle_event/simple_spawner/player_controlled/imp/post_player_assigned(mob/living/mob)
	apply_imp_antag(mob)

/datum/shuttle_event/simple_spawner/player_controlled/imp/on_batch_npc_spawn(mob/living/mob)
	apply_imp_antag(mob)
