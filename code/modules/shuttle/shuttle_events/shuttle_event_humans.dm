/// Humans with outfits (NPC waves — no ghost poll).
/datum/shuttle_event/simple_spawner/human_shuttle
	var/datum/outfit/outfit_type = /datum/outfit/job/assistant
	var/wave_spawn_started = FALSE

/datum/shuttle_event/simple_spawner/human_shuttle/event_process()
	if(!active)
		if(world.time < activate_at)
			return FALSE
		active = TRUE
		activate()
	if(wave_spawn_started)
		if(!length(spawning_list) && self_destruct_when_empty)
			return SHUTTLE_EVENT_CLEAR
		return .
	if(!length(spawning_list))
		if(self_destruct_when_empty)
			return SHUTTLE_EVENT_CLEAR
		return .
	if(!prob(spawn_probability_per_process))
		return .
	wave_spawn_started = TRUE
	spawn_entire_wave()
	if(self_destruct_when_empty)
		return SHUTTLE_EVENT_CLEAR
	return .

/datum/shuttle_event/simple_spawner/human_shuttle/proc/spawn_entire_wave()
	var/list/types_to_spawn = list()
	for(var/spawn_type in spawning_list)
		var/count = spawning_list[spawn_type]
		for(var/i in 1 to count)
			types_to_spawn += spawn_type
	spawning_list.Cut()
	for(var/spawn_type in types_to_spawn)
		var/turf/spawn_point = get_spawn_turf()
		if(!spawn_point)
			break
		post_spawn(new spawn_type(spawn_point))
		CHECK_TICK

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
	event_probability = 50
	spawn_probability_per_process = 5
	activation_fraction = 0.05
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE

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

/// Optional subtype for future mapping — same as greytide NPC.
/datum/shuttle_event/simple_spawner/human_shuttle/greytide/light
	spawning_list = list(/mob/living/carbon/human = 3)
	event_probability = 40
