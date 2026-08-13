/// Admin-selectable: occupies a slot in the admin queue / random roll with no effect (useful to dilute random events).
/datum/shuttle_event/hyperspace_nothing
	name = "Ничего"
	event_probability = 90

/datum/shuttle_event/hyperspace_nothing/event_process()
	if(!active)
		if(world.time < activate_at)
			return FALSE
		active = TRUE
	return SHUTTLE_EVENT_CLEAR

/// InteQ hitchhiker — ghost role with /datum/outfit/inteq/full, gear first, optional prefs load, re-equip if prefs applied.
/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker/inteq
	name = "Оперативники ИнтеКью (автостоп по гиперпространству)"
	ghost_alert_string = "Налёт оперативников InteQ у эвакуационного шаттла. Я подсяду?"
	spawning_list = list(/mob/living/carbon/human = 3)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	event_probability = 20
	spawn_probability_per_process = 5
	activation_fraction = 0.2
	spawn_anyway_if_no_player = TRUE
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE
	role_type = ROLE_SENTIENCE

/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker/inteq/get_batch_poll_message(count)
	return "[ghost_alert_string] (До [count] оперативников. Вы не вернётесь в прежнее тело!)"

/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker/inteq/post_spawn(atom/movable/spawnee)
	// Skip assistant hitchhiker outfit from parent; gear is applied once in post_player_assigned / NPC path.
	call(src, /datum/shuttle_event/simple_spawner/proc/post_spawn)(spawnee)

/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker/inteq/post_player_assigned(mob/living/mob)
	if(!ishuman(mob))
		return
	var/mob/living/carbon/human/human = mob
	equip_inteq_hitchhiker(human)
	if(human.client)
		if(alert(human, "Загрузить внешность, расу и имя с ваших сохранённых персонажей?", "Внешность", "Да", "Нет") == "Да")
			human.load_client_appearance(human.client, FALSE)
			equip_inteq_hitchhiker(human)

/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker/inteq/on_batch_npc_spawn(mob/living/mob)
	if(ishuman(mob))
		equip_inteq_hitchhiker(mob)

/datum/shuttle_event/simple_spawner/player_controlled/human/hitchhiker/inteq/proc/equip_inteq_hitchhiker(mob/living/carbon/human/human)
	if(QDELETED(human))
		return
	human.equipOutfit(/datum/outfit/inteq/full)
	if(human.internal)
		human.update_action_buttons_icon()
