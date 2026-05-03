/// Humans with outfits (NPC waves — no ghost poll).
/datum/shuttle_event/simple_spawner/human_shuttle
	var/datum/outfit/outfit_type = /datum/outfit/job/assistant

/datum/shuttle_event/simple_spawner/human_shuttle/post_spawn(atom/movable/spawnee)
	. = ..()
	if(ishuman(spawnee) && outfit_type)
		var/mob/living/carbon/human/H = spawnee
		H.equipOutfit(outfit_type)

/datum/outfit/job/assistant/hitchhiker
	name = "Assistant — hitchhiker"
	mask = /obj/item/clothing/mask/breath
	suit = /obj/item/clothing/suit/space/eva
	head = /obj/item/clothing/head/helmet/space/eva
	suit_store = /obj/item/tank/internals/emergency_oxygen
	r_hand = /obj/item/spear/grey_tide

/datum/shuttle_event/simple_spawner/human_shuttle/greytide
	name = "Волна ассистентов"
	spawning_list = list(/mob/living/carbon/human = 5)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	outfit_type = /datum/outfit/ert/greybois/greygod
	event_probability = 5
	spawn_probability_per_process = 5
	activation_fraction = 0.05
	spawns_per_spawn = 5
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE

/// Single ghost-possessed hitchhiker in EVA.
/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker
	name = "Автостопом по гиперпространству"
	spawning_list = list(/mob/living/carbon/human = 1)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	event_probability = 5
	spawn_probability_per_process = 5
	activation_fraction = 0.2
	spawn_anyway_if_no_player = TRUE
	ghost_alert_string = "Хотите сыграть за пассажира, приближающегося к шаттлу?"
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE
	role_type = ROLE_SENTIENCE

/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker/post_spawn(atom/movable/spawnee)
	. = ..()
	if(ishuman(spawnee))
		var/mob/living/carbon/human/H = spawnee
		H.equipOutfit(/datum/outfit/job/assistant/hitchhiker)

/// Optional subtype for future mapping — same as greytide NPC.
/datum/shuttle_event/simple_spawner/human_shuttle/greytide/light
	spawning_list = list(/mob/living/carbon/human = 3)
	spawns_per_spawn = 3
	event_probability = 4

/datum/shuttle_event/simple_spawner/human_shuttle/ert_mopp
	name = "ОБР MOPP (подкрепление к шаттлу)"
	spawning_list = list(/mob/living/carbon/human = 5)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	outfit_type = null
	event_probability = 4
	activation_fraction = 0.18
	spawns_per_spawn = 4
	spawn_probability_per_process = 100
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE
	var/static/list/ert_mopp_outfit_paths
	var/next_mopp_index = 1

/datum/shuttle_event/simple_spawner/human_shuttle/ert_mopp/start_up_event(evacuation_duration)
	next_mopp_index = 1
	if(!ert_mopp_outfit_paths)
		ert_mopp_outfit_paths = list(
			/datum/outfit/ert/commander/mopp,
			/datum/outfit/ert/security/mopp,
			/datum/outfit/ert/medic/mopp,
			/datum/outfit/ert/engineer/mopp,
		)
	. = ..()

/datum/shuttle_event/simple_spawner/human_shuttle/ert_mopp/post_spawn(atom/movable/spawnee)
	. = ..()
	if(!ishuman(spawnee))
		return
	if(!ert_mopp_outfit_paths)
		ert_mopp_outfit_paths = list(
			/datum/outfit/ert/commander/mopp,
			/datum/outfit/ert/security/mopp,
			/datum/outfit/ert/medic/mopp,
			/datum/outfit/ert/engineer/mopp,
		)
	var/mob/living/carbon/human/H = spawnee
	var/slot = min(next_mopp_index, ert_mopp_outfit_paths.len)
	H.equipOutfit(ert_mopp_outfit_paths[slot])
	next_mopp_index++
