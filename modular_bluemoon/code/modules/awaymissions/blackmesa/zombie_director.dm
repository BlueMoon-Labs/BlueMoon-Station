/datum/ai_director/zombie_mission
	var/wave_timer = 600
	var/max_wave_interval = 3000
	var/last_wave_time = 0
	var/current_wave_number = 0
	var/list/active_zombies = list()
	var/horde_music_playing = FALSE
	var/horde_music_start_time = 0
	var/horde_music_duration = 12000
	var/horde_music_cutoff_threshold = 5
	var/difficulty_level = 0
	var/zombie_hp_multiplier = 1.0
	var/initialized = FALSE
	var/wave_timer_paused = FALSE
	var/pause_start_time = 0
	var/horde_music_channel = 991
	var/spawning_wave = FALSE

	var/list/excluded_areas = list(
		/area/awaymission/ihategordon/hecu_abandoned_camp,
		/area/awaymission/ihategordon/rocks,
		/area/awaymission/ihategordon/outsideofmesa/hecu_camp,
		/area/awaymission/ihategordon/secret_rooms,
		/area/awaymission/ihategordon/underground_tunnels,
		/area/awaymission/ihategordon/sectorhnorthoffices,
		/area/awaymission/ihategordon/opposing/end,
		/area/awaymission/ihategordon/opposing/comlpex,
		/area/awaymission/ihategordon/opposing,
		/area/awaymission/ihategordon/outsideofmesa/restricted_zone,
		/area/awaymission/ihategordon/science_tunnel,
		/area/awaymission/ihategordon/gonome,
		/area/awaymission/ihategordon/sec_armory,
		/area/awaymission/ihategordon/tram_tunnel,
		/area/awaymission/ihategordon/entrance,
		/area/awaymission/ihategordon/dorm_rooms,
		/area/awaymission/ihategordon/hecu_camp_hall,
		/area/awaymission/ihategordon/hecu_camp_medbay,
		/area/awaymission/ihategordon/sci_medbay,
		/area/awaymission/ihategordon/custom_space,
		/area/awaymission/ihategordon/custom_walking
	)

/datum/ai_director/zombie_mission/New()
	. = ..()
	initialized = TRUE
	last_wave_time = world.time
	START_PROCESSING(SSprocessing, src)

/datum/ai_director/zombie_mission/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	active_zombies.Cut()
	. = ..()

/datum/ai_director/zombie_mission/process()
	if(!src)
		return
	if(!SSblackmesa_events)
		return

	var/list/mission_areas = get_areas(/area/awaymission/ihategordon, TRUE)
	if(!mission_areas || !mission_areas.len)
		return

	var/list/alive_players = get_alive_players_in_mission()
	if(!alive_players || !alive_players.len)
		if(!wave_timer_paused)
			wave_timer_paused = TRUE
			pause_start_time = world.time
		if(horde_music_playing)
			manage_horde_music()
		return
	else
		if(wave_timer_paused)
			wave_timer_paused = FALSE
			var/pause_duration = world.time - pause_start_time
			last_wave_time += pause_duration
			pause_start_time = 0

	if(world.time - last_wave_time >= wave_timer)
		attempt_spawn_wave()

	if(horde_music_playing)
		manage_horde_music()

/datum/ai_director/zombie_mission/proc/attempt_spawn_wave()
	if(!src)
		return
	if(spawning_wave)
		log_world("[src] Already spawning a wave, skipping duplicate spawn")
		return
	var/time_since_last = world.time - last_wave_time
	if(time_since_last < wave_timer)
		return

	var/list/alive_players = get_alive_players_in_mission()
	if(!alive_players || !alive_players.len)
		log_world("[src] No alive players in mission, pausing wave timer")
		wave_timer_paused = TRUE
		pause_start_time = world.time
		return

	var/threat_level = calculate_threat_level(alive_players.len)
	if(!threat_level || threat_level <= 0)
		log_world("[src] Invalid threat level: [threat_level]")
		last_wave_time = world.time
		return

	wave_timer = rand(300, max_wave_interval)

	log_world("[src] Attempting to spawn wave with threat=[threat_level]")
	spawning_wave = TRUE
	spawn_zombie_wave(threat_level, alive_players)
	spawning_wave = FALSE

	last_wave_time = world.time
	current_wave_number++

/datum/ai_director/zombie_mission/proc/get_alive_players_in_mission()
	if(!src)
		return list()
	var/list/players = list()
	var/list/valid_areas = get_mesa_areas()
	if(!valid_areas || !valid_areas.len)
		return players

	for(var/mob/living/L in GLOB.player_list)
		if(!L || !L.client || L.stat == DEAD)
			continue
		var/area/A = get_area(L)
		if(!A)
			continue
		if(A in valid_areas)
			players += L

	return players

/datum/ai_director/zombie_mission/proc/get_mesa_areas()
	if(!src)
		return list()
	var/list/source_areas = get_areas(/area/awaymission/ihategordon, TRUE)
	if(!source_areas || !source_areas.len)
		return list()

	var/list/areas = list()

	for(var/area/A in source_areas)
		if(!A || !A.contents || !A.contents.len)
			continue
		var/valid = TRUE
		for(var/EA in excluded_areas)
			if(ispath(A.type, EA))
				valid = FALSE
				break
		if(valid)
			areas += A
	return areas

/datum/ai_director/zombie_mission/proc/calculate_threat_level(player_count)
	if(!player_count)
		player_count = 1
	var/base_threat
	switch(difficulty_level)
		if(0)
			base_threat = rand(3, 4)
		if(1)
			base_threat = rand(4, 7)
		if(2)
			base_threat = rand(5, 8)
		if(3)
			base_threat = rand(6, 10)
		if(4)
			base_threat = rand(7, 12)
		if(5)
			base_threat = rand(8, 15)
		if(6)
			base_threat = rand(9, 17)
		if(7)
			base_threat = rand(10, 18)
		if(8)
			base_threat = rand(12, 20)
		else
			base_threat = rand(3, 4)

	var/player_multiplier = 1 + ((player_count - 1) * 0.1)
	var/threat = round(base_threat * player_multiplier)
	return threat

/datum/ai_director/zombie_mission/proc/spawn_zombie_wave(threat_level, list/players)
	if(!src)
		return
	if(!threat_level || threat_level <= 0)
		log_world("[src] Invalid threat_level: [threat_level]")
		return
	if(!players || !players.len)
		log_world("[src] No players provided")
		return

	var/zombies_to_spawn = threat_level
	var/list/spawned_zombies = list()

	log_world("[src] Starting zombie wave: threat=[threat_level], players=[players.len], zombies_to_spawn=[zombies_to_spawn]")

	var/list/cached_spawn_turfs = get_cached_spawn_turfs(players)
	if(!cached_spawn_turfs || !cached_spawn_turfs.len)
		log_world("[src] No valid spawn turfs found")
		return

	var/batch_size = rand(3, 5)
	var/zombies_spawned = 0
	var/failed_spawns = 0

	while(zombies_spawned < zombies_to_spawn && failed_spawns < 20)
		var/remaining = zombies_to_spawn - zombies_spawned
		var/current_batch = min(batch_size, remaining)

		for(var/i = 1 to current_batch)
			var/turf/spawn_turf = pick(cached_spawn_turfs)
			if(!spawn_turf)
				log_world("[src] Failed to pick spawn turf for zombie #[zombies_spawned + i]")
				failed_spawns++
				continue

			if(spawn_turf.density || spawn_turf.is_blocked_turf())
				failed_spawns++
				continue

			var/mob_type
			if(difficulty_level >= 5)
				// After trigger5, include hunter in rotation (rare special)
				var/spawn_roll = rand(1, 100)
				if(spawn_roll <= 55)
					mob_type = /mob/living/simple_animal/hostile/infected
				else if(spawn_roll <= 75)
					mob_type = /mob/living/simple_animal/hostile/infected/bruiser
				else if(spawn_roll <= 85)
					mob_type = /mob/living/simple_animal/hostile/infected/bruiser/alt
				else if(spawn_roll <= 90)
					mob_type = /mob/living/simple_animal/hostile/infected/acid_spitter
				else if(spawn_roll <= 97)
					mob_type = /mob/living/simple_animal/hostile/infected/charger
				else
					mob_type = /mob/living/simple_animal/hostile/infected/hunter
			else if(difficulty_level >= 4)
				// After trigger4, include acid spitter and charger in rotation
				var/spawn_roll = rand(1, 100)
				if(spawn_roll <= 40)
					mob_type = /mob/living/simple_animal/hostile/infected
				else if(spawn_roll <= 65)
					mob_type = /mob/living/simple_animal/hostile/infected/bruiser
				else if(spawn_roll <= 80)
					mob_type = /mob/living/simple_animal/hostile/infected/bruiser/alt
				else if(spawn_roll <= 95)
					mob_type = /mob/living/simple_animal/hostile/infected/acid_spitter
				else
					mob_type = /mob/living/simple_animal/hostile/infected/charger
			else
				// Before trigger4, only normal zombies and bruisers
				if(prob(70))
					mob_type = /mob/living/simple_animal/hostile/infected
				else
					mob_type = prob(50) ? /mob/living/simple_animal/hostile/infected/bruiser : /mob/living/simple_animal/hostile/infected/bruiser/alt

			if(!mob_type)
				failed_spawns++
				continue

			var/mob/living/simple_animal/hostile/infected/Z = new mob_type(spawn_turf)
			if(Z)
				if(zombie_hp_multiplier > 1.0)
					Z.maxHealth = round(Z.maxHealth * zombie_hp_multiplier)
					Z.health = Z.maxHealth
					log_world("[src] Applied HP multiplier [zombie_hp_multiplier] to zombie at [spawn_turf], new HP: [Z.maxHealth]")

				spawned_zombies += Z
				active_zombies += Z
				new /obj/effect/temp_visual/dir_setting/ninja/phase(spawn_turf)
				playsound(spawn_turf, 'sound/magic/Teleport_app.ogg', 50, TRUE)
				log_world("[src] Spawned zombie #[zombies_spawned + 1] at [spawn_turf]")
				zombies_spawned++
			else
				failed_spawns++
				log_world("[src] Failed to spawn zombie at [spawn_turf]")

		if(zombies_spawned < zombies_to_spawn && failed_spawns < 20)
			sleep(20)

	log_world("[src] Wave complete: intended=[zombies_to_spawn], spawned=[spawned_zombies.len], failed=[failed_spawns]")
	announce_wave(spawned_zombies.len)

	if(spawned_zombies.len > 0)
		if(difficulty_level > 0)
			start_horde_music()

/datum/ai_director/zombie_mission/proc/find_valid_spawn_turf(list/players)
	if(!src)
		return null
	if(!players || !players.len)
		return null

	var/list/valid_areas = get_mesa_areas()
	if(!valid_areas || !valid_areas.len)
		return null

	var/min_dist = 7
	var/max_dist = 8

	var/list/player_spawn_turfs = list()
	for(var/mob/living/target in players)
		if(!target)
			continue
		var/turf/center = get_turf(target)
		if(!center)
			continue
		var/area/player_area = get_area(center)
		if(!player_area || !(player_area in valid_areas))
			continue
		player_spawn_turfs[target] = list()
		for(var/turf/T in range(max_dist, center))
			if(!T)
				continue
			var/dist = get_dist(T, center)
			if(dist >= min_dist && dist <= max_dist)
				player_spawn_turfs[target] += T

	for(var/i = 1 to 50)
		var/mob/living/target = pick(players)
		if(!target)
			continue
		if(!player_spawn_turfs[target] || !LAZYLEN(player_spawn_turfs[target]))
			continue

		var/turf/T = pick(player_spawn_turfs[target])
		if(!T)
			continue

		if(T.density)
			continue

		if(T.is_blocked_turf())
			continue

		return T

	return null

/datum/ai_director/zombie_mission/proc/get_cached_spawn_turfs(list/players)
	if(!src)
		return null
	if(!players || !players.len)
		return null

	var/list/valid_areas = get_mesa_areas()
	if(!valid_areas || !valid_areas.len)
		return null

	var/min_dist = 7
	var/max_dist = 8

	var/list/cached_turfs = list()

	for(var/mob/living/target in players)
		if(!target)
			continue
		var/turf/center = get_turf(target)
		if(!center)
			continue
		var/area/player_area = get_area(center)
		if(!player_area || !(player_area in valid_areas))
			continue

		for(var/turf/T in range(max_dist, center))
			if(!T)
				continue
			var/dist = get_dist(T, center)
			if(dist >= min_dist && dist <= max_dist)
				if(!T.density && !T.is_blocked_turf())
					var/area/spawn_area = get_area(T)
					if(!spawn_area || !(spawn_area in valid_areas))
						continue
					cached_turfs += T

	return cached_turfs

/datum/ai_director/zombie_mission/proc/can_reach_player(turf/start_turf, turf/target_turf)
	if(!src)
		return FALSE
	if(!start_turf || !target_turf)
		return FALSE

	var/list/visited = list()
	var/list/queue = list(start_turf)
	visited[start_turf] = TRUE
	var/steps = 0
	var/max_steps = 50

	while(queue.len && steps < max_steps)
		var/turf/current = queue[1]
		queue.Cut(1, 2)
		steps++

		if(current == target_turf)
			return TRUE

		for(var/dir in GLOB.cardinals)
			var/turf/next_turf = get_step(current, dir)
			if(!next_turf || visited[next_turf])
				continue
			if(next_turf.density)
				continue
			var/blocked = FALSE
			for(var/atom/movable/AM in next_turf)
				if(AM.density && !istype(AM, /mob/living))
					if(istype(AM, /obj/structure/window) || istype(AM, /obj/structure/grille) || istype(AM, /obj/structure/fence))
						continue
					blocked = TRUE
					break
			if(blocked)
				continue
			visited[next_turf] = TRUE
			queue += next_turf

	return FALSE

/datum/ai_director/zombie_mission/proc/has_line_of_sight(turf/start_turf, turf/target_turf)
	if(!src)
		return FALSE
	if(!start_turf || !target_turf)
		return FALSE

	for(var/turf/T in getline(start_turf, target_turf))
		if(T == start_turf || T == target_turf)
			continue
		if(T.opacity)
			return FALSE
		if(T.density)
			return FALSE
		for(var/atom/movable/AM in T)
			if(AM.opacity || (AM.density && !istype(AM, /mob/living)))
				return FALSE

	return TRUE

/datum/ai_director/zombie_mission/proc/announce_wave(zombie_count)
	if(!src)
		return
	if(!SSblackmesa_events)
		log_world("[src] SSblackmesa_events is null, cannot announce")
		return
	if(!zombie_count)
		log_world("[src] zombie_count is 0, skipping announce")
		return

	log_world("[src] Announcing wave with [zombie_count] zombies")
	var/message = "ВНИМАНИЕ! Зафиксирована активность заражённых в Секторе H. Количество целей: [zombie_count]. Рекомендуется подготовиться к обороне."
	SSblackmesa_events.mesa_announce(message, "Zombie Horde Detected")

/datum/ai_director/zombie_mission/proc/trigger_horde()
	if(!src)
		return
	var/list/alive_players = get_alive_players_in_mission()
	if(!alive_players || !alive_players.len)
		return

	var/threat_level = calculate_threat_level(alive_players.len)
	if(!threat_level || threat_level <= 0)
		return

	spawn_zombie_wave(threat_level, alive_players)
	current_wave_number++

/datum/ai_director/zombie_mission/proc/start_horde_music()
	if(!src)
		return
	if(horde_music_playing)
		return

	var/zombie_count = count_visible_zombies()
	if(zombie_count <= 0)
		return

	horde_music_playing = TRUE
	horde_music_start_time = world.time

	var/list/valid_areas = get_mesa_areas()
	if(!valid_areas || !valid_areas.len)
		return

	for(var/mob/M in GLOB.player_list)
		if(!M || isnewplayer(M))
			continue
		var/area/A = get_area(M)
		if(!A)
			continue
		if(A in valid_areas)
			if(M.client && M.client.prefs && (M.client.prefs.toggles & SOUND_AMBIENCE))
				var/music_file = 'modular_bluemoon/sound/ambience/mesa/horde_music.ogg'
				if(istype(A, /area/awaymission/ihategordon/custom_event))
					music_file = 'modular_bluemoon/sound/ambience/mesa/xenhorde.ogg'
				SEND_SOUND(M, sound(music_file, repeat = FALSE, volume = 50, channel = horde_music_channel))

/datum/ai_director/zombie_mission/proc/stop_horde_music()
	if(!src)
		return
	if(!horde_music_playing)
		return

	horde_music_playing = FALSE

	var/list/valid_areas = get_mesa_areas()
	if(!valid_areas || !valid_areas.len)
		return

	for(var/mob/M in GLOB.player_list)
		if(!M || isnewplayer(M))
			continue
		var/area/A = get_area(M)
		if(!A)
			continue
		if(A in valid_areas)
			M.stop_sound_channel(horde_music_channel)

/datum/ai_director/zombie_mission/proc/manage_horde_music()
	if(!src)
		return
	if(!horde_music_playing)
		return

	var/time_elapsed = world.time - horde_music_start_time

	if(time_elapsed >= horde_music_duration)
		stop_horde_music()
		return

	var/visible_zombie_count = count_visible_zombies()
	if(visible_zombie_count <= horde_music_cutoff_threshold)
		stop_horde_music()
		return

/datum/ai_director/zombie_mission/proc/count_visible_zombies()
	if(!src)
		return 0
	var/count = 0
	var/list/valid_areas = get_mesa_areas()
	if(!valid_areas || !valid_areas.len)
		return count

	for(var/mob/living/simple_animal/hostile/infected/Z in active_zombies)
		if(!Z || QDELETED(Z) || Z.stat == DEAD)
			active_zombies -= Z
			continue
		var/area/A = get_area(Z)
		if(!A)
			continue
		if(A in valid_areas)
			count++

	return count
