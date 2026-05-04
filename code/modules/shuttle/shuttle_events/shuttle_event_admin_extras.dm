/// Admin-selectable: occupies a slot in the admin queue / random roll with no effect (useful to dilute random events).
/datum/shuttle_event/hyperspace_nothing
	name = "Ничего"
	event_probability = 9

/datum/shuttle_event/hyperspace_nothing/event_process()
	if(!active)
		if(world.time < activate_at)
			return FALSE
		active = TRUE
	return SHUTTLE_EVENT_CLEAR

/// InteQ hitchhiker — ghost role with /datum/outfit/inteq/full, optional prefs load, then re-equip.
/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker/inteq
	name = "Оперативники ИнтеКью (автостоп по гиперпространству)"
	ghost_alert_string = "Налёт оперативников InteQ у эвакуационного шаттла. Я подсяду?"
	spawning_list = list(/mob/living/carbon/human = 3)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	event_probability = 2
	spawn_probability_per_process = 5
	activation_fraction = 0.2
	spawn_anyway_if_no_player = TRUE
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE
	role_type = ROLE_SENTIENCE

/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker/inteq/post_spawn(atom/movable/spawnee)
	if(istype(spawnee, /mob/living/carbon/human))
		var/mob/living/carbon/human/human = spawnee
		human.equipOutfit(/datum/outfit/inteq/full)
		return
	return ..()

/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker/inteq/post_player_assigned(mob/living/mob)
	if(!ishuman(mob))
		return
	var/mob/living/carbon/human/human = mob
	if(human.client)
		if(alert(human, "Загрузить внешность, расу и имя с ваших сохранённых персонажей?", "Внешность", "Да", "Нет") == "Да")
			human.load_client_appearance(human.client, FALSE)
	human.equipOutfit(/datum/outfit/inteq/full)
