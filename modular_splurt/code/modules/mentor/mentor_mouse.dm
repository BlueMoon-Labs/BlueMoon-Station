/client
	COOLDOWN_DECLARE(mentor_mouse_spawn)

/client/proc/spawn_mentor_mouse()
	set name = "Mentor Spawn"
	set category = "Mentor"

	var/mob/living/mentor
	var/turf/current_turf = get_turf(mob)

	if(isobserver(mob) && COOLDOWN_FINISHED(src, mentor_mouse_spawn))
		var/list/spawn_options = list("Mouse", "Cancel")
		if(is_super_mentor())
			spawn_options.Insert(2, "Drone")
		var/type = tgui_alert(src, "Which character you want to spawn?","Mentor Spawn", spawn_options)
		if(type == "Cancel" || !type)
			return
		if(type == "Mouse")
			mentor = /mob/living/simple_animal/hostile/syndimouse

		if(type == "Drone")
			if(!is_super_mentor())
				to_chat(src, span_warning("Only super mentors can spawn mentor drones."))
				return
			mentor = /mob/living/simple_animal/drone/mentordrone

		mentor = new mentor(current_turf)

		QDEL_IN(mob, 1)

		if(mob?.mind && isliving(mentor))
			mob?.mind.transfer_to(mentor, TRUE)
		else
			mob?.transfer_ckey(mentor)

		add_verb(src, /client/proc/despawn_mentor_mouse)
		remove_verb(src, /client/proc/spawn_mentor_mouse)
		message_admins("[ADMIN_LOOKUPFLW(src)] Spawned as a Mentor")
		log_mentor("[key_name(src)] Spawned as a Mentor")
		COOLDOWN_START(src, mentor_mouse_spawn, 10 SECONDS)

/client/proc/despawn_mentor_mouse()
	set name = "Mentor Despawn"
	set category = "Mentor"

	if(istype(mob, /mob/living/simple_animal/drone/mentordrone) || istype(mob, /mob/living/simple_animal/hostile/syndimouse))
		if(COOLDOWN_FINISHED(src, mentor_mouse_spawn))
			QDEL_IN(mob, 1)

			add_verb(src, /client/proc/spawn_mentor_mouse)
			remove_verb(src, /client/proc/despawn_mentor_mouse)
			message_admins("[ADMIN_LOOKUPFLW(src)] Mentor Despawned.")
			log_mentor("[key_name(src)] Mentor Despawned.")
			COOLDOWN_START(src, mentor_mouse_spawn, 20 SECONDS)
