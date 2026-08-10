/datum/outfit/job/assistant/hitchhiker
	name = "Assistant — hitchhiker"
	mask = /obj/item/clothing/mask/breath
	suit = /obj/item/clothing/suit/space/eva
	head = /obj/item/clothing/head/helmet/space/eva
	suit_store = /obj/item/tank/internals/emergency_oxygen
	r_hand = /obj/item/spear/grey_tide

/// Single ghost-possessed hitchhiker in EVA.
/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker
	name = "Автостопом по гиперпространству"
	spawning_list = list(/mob/living/carbon/human = 1)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	event_probability = 50
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
