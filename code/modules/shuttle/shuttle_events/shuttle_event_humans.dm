/// Humans with outfits (NPC waves — no ghost poll).
/datum/shuttle_event/simple_spawner/human_shuttle
	var/datum/outfit/outfit_type = /datum/outfit/job/assistant

/datum/shuttle_event/simple_spawner/human_shuttle/post_spawn(atom/movable/spawnee)
	. = ..()
	if(ishuman(spawnee))
		var/mob/living/carbon/human/H = spawnee
		H.equipOutfit(outfit_type)

/datum/outfit/job/assistant/breath_mask
	name = "Assistant — противогаз"
	mask = /obj/item/clothing/mask/breath
	l_pocket = /obj/item/tank/internals/emergency_oxygen

/datum/outfit/job/assistant/hitchhiker
	name = "Assistant — автостопом"
	mask = /obj/item/clothing/mask/breath
	suit = /obj/item/clothing/suit/space/eva
	head = /obj/item/clothing/head/helmet/space/eva
	l_pocket = /obj/item/tank/internals/emergency_oxygen
	r_hand = /obj/item/storage/briefcase

/datum/shuttle_event/simple_spawner/human_shuttle/greytide
	name = "Волна ассистентов"
	spawning_list = list(/mob/living/carbon/human = 5)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	outfit_type = /datum/outfit/job/assistant/breath_mask
	event_probability = 2
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
	event_probability = 2
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
	event_probability = 3
