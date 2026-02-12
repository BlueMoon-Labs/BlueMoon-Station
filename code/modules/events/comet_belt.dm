
/datum/round_event_control/comet_belt
	name = "Comet Belt"
	typepath = /datum/round_event/comet_belt
	max_occurrences = 2
	weight = 2
	earliest_start = 10 MINUTES
	category = EVENT_CATEGORY_FRIENDLY
	description = "A belt of comets passes near the station, creating a spectacular light show."

/datum/round_event_control/comet_belt/canSpawnEvent(players, gamemode)
	if(!CONFIG_GET(flag/starlight))
		return FALSE
	return ..()

/datum/round_event/comet_belt
	announce_when = 1
	start_when = 5
	end_when = 200 // safety-net, реальное завершение по world.time
	var/current_phase = 0
	var/music_start_time = 0 // world.time когда музыка начала играть
	var/last_music_sec = 0 // последняя обработанная секунда музыки
	var/list/comet_overlays = list()
	var/list/trails_overlays = list()
	var/list/dust_overlays = list()
	var/list/belt_stream_overlays = list()
	var/list/flash_overlays = list()
	var/list/glow_overlays = list()
	var/list/saved_parallax = list()
	var/list/saved_ambience_clients = list()
	var/list/all_overlay_objects = list()
	var/finale_announced = FALSE
	var/ambient_comets_active = FALSE

	var/static/list/choreography = list(\
		/* первые кометы (74–86s) */\
		list(74, 12,  "#50C8FF", 0.4, 0.9,  -5,  -2.5),\
		list(78, 15,  "#40B0FF", 0.5, 1.0,  -5.5,-2.8),\
		list(82, 12,  "#60E0FF", 0.5, 1.0,  -5,  -2.5),\
		list(86, 18,  "#80F0FF", 0.6, 1.2,  -6,  -3),\
		/* спам (130–168s) */\
		list(130, 25,  "#FFD040", 0.7, 1.4,  -8,  -4),\
		list(132, 20,  "#FFA830", 0.6, 1.3,  -7,  -3.5),\
		list(134, 30,  "#FF8020", 0.8, 1.6,  -8.5,-4.5),\
		list(136, 40,  "#FFE060", 0.9, 1.8,  -9,  -5),\
		list(140, 25,  "#FF6830", 0.7, 1.5,  -8,  -4),\
		list(144, 35,  "#FFCC40", 0.8, 1.6,  -8.5,-4.5),\
		list(148, 20,  "#60D8FF", 0.6, 1.2,  -6.5,-3),\
		list(152, 25,  "#FF9020", 0.7, 1.4,  -7,  -3.5),\
		list(156, 15,  "#E0C060", 0.5, 1.1,  -5.5,-2.8),\
		list(160, 12,  "#80C8FF", 0.5, 1.0,  -5,  -2.5),\
		list(164, 10,  "#60B0E8", 0.5, 1.0,  -5,  -2.5),\
		list(168,  8,  "#5098D8", 0.4, 0.9,  -4.5,-2.2),\
		/* конечная (170–186s) */\
		list(170, 15,  "#5888D0", 0.5, 1.0,  -5.5,-2.8),\
		list(174, 12,  "#6898E0", 0.4, 0.9,  -5,  -2.5),\
		list(178, 18,  "#4878D0", 0.6, 1.2,  -6,  -3),\
		list(182, 10,  "#3868C0", 0.4, 0.8,  -4.5,-2.2),\
		list(186,  6,  "#3060B8", 0.3, 0.7,  -4,  -2)\
	)

	var/static/list/dust_color_gradient = list(\
		0,     "#180840",\
		0.08,  "#281868",\
		0.16,  "#2850A0",\
		0.24,  "#3888B8",\
		0.30,  "#48C0D8",\
		0.36,  "#58A8C0",\
		0.44,  "#7080A8",\
		0.51,  "#9090B0",\
		0.53,  "#FFE0A0",\
		0.56,  "#FFF8E0",\
		0.59,  "#FFFFFF",\
		0.62,  "#FFD880",\
		0.66,  "#C0B0A0",\
		0.69,  "#70A0C8",\
		0.76,  "#5080A0",\
		0.84,  "#382868",\
		0.96,  "#180838",\
		1,     "#0A0420"\
	)

// ═══════════════════ ИВЕНТ ═══════════════════

/datum/round_event/comet_belt/announce()
	music_start_time = REALTIMEOFDAY // Системное время
	priority_announce("[station_name()]: Наши радары фиксируют приближение кометного пояса. Столкновения со станцией не ожидается — кометы пройдут на безопасном расстоянии. Рекомендуем всем сотрудникам воспользоваться этим редким зрелищем и понаблюдать за космосом через ближайшие иллюминаторы.",\
	sound = 'sound/misc/notice2.ogg',\
	sender_override = "Отдел Астрономии NanoTrasen")
	for(var/V in GLOB.player_list)
		var/mob/M = V
		if((M.client?.prefs?.toggles & SOUND_MIDI) && is_station_level(M.z))
			M.playsound_local(M, 'sound/ambience/star.ogg', 100, FALSE, pressure_affected = FALSE)

/datum/round_event/comet_belt/start()
	for(var/V in GLOB.player_list)
		var/mob/M = V
		if(is_station_level(M.z))
			ADD_TRAIT(M, TRAIT_PACIFISM, "comet_belt")
	for(var/client/C in GLOB.clients)
		if(!C.mob || !is_station_level(C.mob.z))
			continue
		setup_client(C)
	transition_to_phase(1)

/datum/round_event/comet_belt/tick()
	if(!music_start_time)
		return

	// Реальное время от начала музыки
	var/elapsed = REALTIMEOFDAY - music_start_time
	if(elapsed < 0) // переход через полночь
		elapsed += 864000
	var/music_sec = elapsed / 10

	// Принудительное завершение по реальному времени
	if(music_sec >= 250)
		if(activeFor < end_when)
			activeFor = end_when
		return

	var/new_phase
	if(music_sec < 8)
		return // Ещё до начала визуальной части
	else if(music_sec <= 72)
		new_phase = 1
	else if(music_sec <= 88)
		new_phase = 2
	else if(music_sec <= 125)
		new_phase = 3
	else if(music_sec <= 168)
		new_phase = 4
	else if(music_sec <= 188)
		new_phase = 5
	else
		new_phase = 6

	if(new_phase != current_phase)
		transition_to_phase(new_phase)

	var/progress = clamp((music_sec - 8) / 240.0, 0, 1)
	var/dust_col = get_gradient_color(progress, dust_color_gradient)
	update_all_dust_color(dust_col)
	update_belt_stream(dust_col, new_phase, music_sec)

	update_dust_dynamics(music_sec, new_phase)


	for(var/client/C in GLOB.clients)
		if(comet_overlays[C])
			continue
		if(!C.mob || !is_station_level(C.mob.z))
			continue
		setup_client(C)

	var/burst_fired = FALSE
	var/total_spawning = 0
	var/list/latest_burst
	for(var/list/burst in choreography)
		if(burst[1] > last_music_sec && burst[1] <= music_sec)
			latest_burst = burst
			total_spawning += burst[2]
			burst_fired = TRUE
	if(burst_fired)
		var/list/combined_burst = latest_burst.Copy()
		combined_burst[2] = total_spawning // суммарный spawning при пропуске тиков
		fire_comet_burst(combined_burst)
	else
		if(new_phase != 6)
			set_ambient_comets()
		else
			set_comet_spawning(0)

	last_music_sec = music_sec

/datum/round_event/comet_belt/end()
	for(var/V in GLOB.player_list)
		var/mob/M = V
		if(is_station_level(M.z))
			REMOVE_TRAIT(M, TRAIT_PACIFISM, "comet_belt")
	for(var/client/C in saved_ambience_clients)
		if(!C?.mob)
			continue
		if(C.prefs?.toggles & SOUND_AMBIENCE)
			SSambience.ambience_listening_clients[C] = world.time
	saved_ambience_clients.Cut()
	for(var/client/C in saved_parallax)
		if(C?.prefs)
			C.prefs.parallax = saved_parallax[C]
			if(C.parallax_holder)
				C.parallax_holder.Remove()
				C.parallax_holder.Apply()
	saved_parallax.Cut()
	if(current_phase < 6)
		start_fade_out()
	fade_space_glow()
	// Очистка с задержкой, чтобы fade-анимации успели отыграть
	addtimer(CALLBACK(src, PROC_REF(comet_final_cleanup)), 100)

// ═══════════════════ ФАЗЫ ═══════════════════

/datum/round_event/comet_belt/proc/transition_to_phase(phase)
	current_phase = phase

	switch(phase)
		if(1)
			update_space_glow("#282050", 15)

		if(2)
			update_space_glow("#4888B8", 25)

		if(3)
			update_space_glow("#486080", 20)

		if(4)
			update_space_glow("#FFE898", 50)
			addtimer(CALLBACK(src, PROC_REF(trigger_flash)), 30)

		if(5)
			update_space_glow("#6090B8", 35)

		if(6)
			if(!finale_announced)
				finale_announced = TRUE
				priority_announce("Кометный пояс удаляется за пределы видимости. Благодарим за внимание к этому астрономическому явлению. Возвращайтесь к своим обязанностям.",\
				sound = 'sound/misc/notice2.ogg',\
				sender_override = "Отдел Астрономии NanoTrasen")
			addtimer(CALLBACK(src, PROC_REF(start_fade_out)), 60)
			fade_space_glow()


/datum/round_event/comet_belt/proc/setup_client(client/C)
	if(!C?.mob)
		return
	C.mob.stop_sound_channel(CHANNEL_AMBIENCE)
	C.mob.stop_sound_channel(CHANNEL_BUZZ)
	if(SSambience.ambience_listening_clients[C])
		saved_ambience_clients[C] = TRUE
	SSambience.ambience_listening_clients -= C
	if(C.prefs)
		saved_parallax[C] = C.prefs.parallax
		C.prefs.parallax = PARALLAX_INSANE
		if(C.parallax_holder)
			C.parallax_holder.Remove()
			C.parallax_holder.Apply()
	add_comet_overlays(C)
	ADD_TRAIT(C.mob, TRAIT_PACIFISM, "comet_belt")
	apply_current_state_to_client(C)

/datum/round_event/comet_belt/proc/apply_current_state_to_client(client/C)
	if(!C)
		return
	var/atom/movable/screen/comet_space_glow/glow = glow_overlays[C]
	if(glow)
		var/glow_color
		var/glow_alpha
		switch(current_phase)
			if(1)
				glow_color = "#282050"
				glow_alpha = 15
			if(2)
				glow_color = "#4888B8"
				glow_alpha = 25
			if(3)
				glow_color = "#486080"
				glow_alpha = 20
			if(4)
				glow_color = "#FFE898"
				glow_alpha = 50
			if(5)
				glow_color = "#6090B8"
				glow_alpha = 35
		if(glow_color)
			glow.color = glow_color
			animate(glow, alpha = glow_alpha, time = 10)
	if(ambient_comets_active)
		var/atom/movable/screen/comet_overlay/comet = comet_overlays[C]
		if(comet?.particles)
			comet.particles.spawning = 2
			comet.particles.color = "#5898C8"
			comet.particles.scale = generator("num", 0.3, 0.7)
			comet.particles.icon_state = pick("star", "star1", "star2")
			comet.particles.position = generator("box", list(380, -300, 0), list(520, 300, 0))
			comet.particles.velocity = generator("vector", list(-3.5, -1, 0), list(-1.5, 0.5, 0))
		var/atom/movable/screen/comet_trails_overlay/trail = trails_overlays[C]
		if(trail?.particles)
			trail.particles.spawning = 5
			trail.particles.color = "#5898C8"
			trail.particles.position = generator("box", list(380, -300, 0), list(520, 300, 0))
			trail.particles.velocity = generator("vector", list(-3.5, -1, 0), list(-1.5, 0.5, 0))

// Запустить пачку комет с уникальными параметрами
/datum/round_event/comet_belt/proc/fire_comet_burst(list/burst)
	var/burst_spawning = burst[2]
	var/burst_color = burst[3]
	var/sc_min = burst[4]
	var/sc_max = burst[5]
	var/speed_min = abs(burst[7])
	var/speed_max = abs(burst[6])

	ambient_comets_active = FALSE // сбросить флаг, чтобы ambient пересчитался после burst'а
	for(var/client/C in comet_overlays)
		var/atom/movable/screen/comet_overlay/comet = comet_overlays[C]
		if(!comet?.particles)
			continue
		comet.particles.spawning = burst_spawning
		comet.particles.color = burst_color
		comet.particles.scale = generator("num", sc_min, sc_max)
		comet.particles.icon_state = pick("star", "star1", "star2")
		var/atom/movable/screen/comet_trails_overlay/trail = trails_overlays[C]
		if(trail?.particles)
			trail.particles.spawning = round(burst_spawning * 2.5)
			trail.particles.color = burst_color
		// Восток → Запад
		comet.particles.position = generator("box", list(380, -300, 0), list(520, 300, 0))
		comet.particles.velocity = generator("vector", list(-speed_max, -1.5, 0), list(-speed_min, 1.5, 0))
		if(trail?.particles)
			trail.particles.position = comet.particles.position
			trail.particles.velocity = comet.particles.velocity

// Выключить спавн комет
/datum/round_event/comet_belt/proc/set_comet_spawning(val)
	ambient_comets_active = FALSE
	for(var/client/C in comet_overlays)
		var/atom/movable/screen/comet_overlay/comet = comet_overlays[C]
		if(comet?.particles)
			comet.particles.spawning = val
		var/atom/movable/screen/comet_trails_overlay/trail = trails_overlays[C]
		if(trail?.particles)
			trail.particles.spawning = round(val * 2.5)

// Фоновый поток мелких комет между хореографическими пачками
/datum/round_event/comet_belt/proc/set_ambient_comets()
	if(ambient_comets_active)
		return
	ambient_comets_active = TRUE
	for(var/client/C in comet_overlays)
		var/atom/movable/screen/comet_overlay/comet = comet_overlays[C]
		if(!comet?.particles)
			continue
		comet.particles.spawning = 2
		comet.particles.color = "#5898C8"
		comet.particles.scale = generator("num", 0.3, 0.7)
		comet.particles.icon_state = pick("star", "star1", "star2")
		var/atom/movable/screen/comet_trails_overlay/trail = trails_overlays[C]
		if(trail?.particles)
			trail.particles.spawning = 5
			trail.particles.color = "#5898C8"
		// Восток → Запад
		comet.particles.position = generator("box", list(380, -300, 0), list(520, 300, 0))
		comet.particles.velocity = generator("vector", list(-3.5, -1, 0), list(-1.5, 0.5, 0))
		if(trail?.particles)
			trail.particles.position = comet.particles.position
			trail.particles.velocity = comet.particles.velocity

/datum/round_event/comet_belt/proc/update_dust_dynamics(music_sec, phase)
	var/target_spawning
	var/target_count
	var/target_alpha

	switch(phase)
		if(1) // 8–72s
			var/p = clamp((music_sec - 8) / 64.0, 0, 1)
			target_spawning = round(2 + p * 5)
			target_count = round(15 + p * 45)
			target_alpha = round(60 + p * 180)

		if(2)
			target_spawning = 7
			target_count = 60
			target_alpha = 240

		if(3) // 90–128s
			var/breath = sin((music_sec - 90) / 38.0 * 720)
			target_spawning = round(4 + breath * 3)
			target_count = 60
			target_alpha = round(180 + breath * 60)

		if(4)
			target_spawning = 8
			target_count = 60
			target_alpha = 255

		if(5)
			target_spawning = 5
			target_count = 60
			target_alpha = 220

		if(6) // 190–248s
			var/p = clamp((music_sec - 190) / 58.0, 0, 1)
			target_spawning = max(0, round(5 * (1 - p)))
			target_count = max(5, round(60 * (1 - p)))
			target_alpha = max(0, round(240 * (1 - p)))

	for(var/client/C in dust_overlays)
		var/atom/movable/screen/comet_dust_overlay/dust = dust_overlays[C]
		if(!dust)
			continue
		if(dust.particles)
			dust.particles.spawning = target_spawning
			dust.particles.count = target_count
		animate(dust, alpha = target_alpha, time = 15)

/// Обновить цвет пыли на всех клиентах
/datum/round_event/comet_belt/proc/update_all_dust_color(col)
	for(var/client/C in dust_overlays)
		var/atom/movable/screen/comet_dust_overlay/dust = dust_overlays[C]
		if(dust?.particles)
			dust.particles.color = col

/datum/round_event/comet_belt/proc/update_belt_stream(col, phase, music_sec)
	var/target_spawning
	var/target_alpha

	switch(phase)
		if(1) // нарастание 8–72s
			var/p = clamp((music_sec - 8) / 64.0, 0, 1)
			target_spawning = round(2 + p * 4)
			target_alpha = round(60 + p * 140)
		if(2) // первые кометы
			target_spawning = 6
			target_alpha = 200
		if(3) // затишье
			target_spawning = 4
			target_alpha = 160
		if(4) // кульминация
			target_spawning = 8
			target_alpha = 230
		if(5) // угасание
			target_spawning = 5
			target_alpha = 180
		if(6) // финал 190–248s
			var/p = clamp((music_sec - 190) / 58.0, 0, 1)
			target_spawning = max(0, round(5 * (1 - p)))
			target_alpha = max(0, round(200 * (1 - p)))

	for(var/client/C in belt_stream_overlays)
		var/atom/movable/screen/comet_belt_stream_overlay/belt = belt_stream_overlays[C]
		if(!belt)
			continue
		if(belt.particles)
			belt.particles.spawning = target_spawning
			belt.particles.color = col
		animate(belt, alpha = target_alpha, time = 15)

/datum/round_event/comet_belt/proc/trigger_flash()
	for(var/client/C in comet_overlays)
		if(!C)
			continue
		var/atom/movable/screen/comet_flash/flash = new
		flash_overlays[C] = flash
		C.screen += flash
		flash.do_flash()
		addtimer(CALLBACK(src, PROC_REF(remove_flash), C), 60)

/datum/round_event/comet_belt/proc/remove_flash(client/C)
	if(!C)
		return
	var/atom/movable/screen/comet_flash/flash = flash_overlays[C]
	if(flash)
		C.screen -= flash
		qdel(flash)
	flash_overlays -= C

/datum/round_event/comet_belt/proc/get_gradient_color(position, list/grad)
	position = clamp(position, 0, 1)
	var/prev_pos = grad[1]
	var/prev_color = grad[2]
	for(var/i in 3 to grad.len step 2)
		var/cur_pos = grad[i]
		var/cur_color = grad[i + 1]
		if(position <= cur_pos)
			if(cur_pos == prev_pos)
				return cur_color
			var/t = (position - prev_pos) / (cur_pos - prev_pos)
			return lerp_color(prev_color, cur_color, t)
		prev_pos = cur_pos
		prev_color = cur_color
	return prev_color

/datum/round_event/comet_belt/proc/lerp_color(hex_a, hex_b, t)
	t = clamp(t, 0, 1)
	var/ra = hex_to_num(copytext(hex_a, 2, 4))
	var/ga = hex_to_num(copytext(hex_a, 4, 6))
	var/ba = hex_to_num(copytext(hex_a, 6, 8))
	var/rb = hex_to_num(copytext(hex_b, 2, 4))
	var/gb = hex_to_num(copytext(hex_b, 4, 6))
	var/bb = hex_to_num(copytext(hex_b, 6, 8))
	return rgb(\
		clamp(round(ra + (rb - ra) * t), 0, 255),\
		clamp(round(ga + (gb - ga) * t), 0, 255),\
		clamp(round(ba + (bb - ba) * t), 0, 255)\
	)

/datum/round_event/comet_belt/proc/hex_to_num(hex_pair)
	var/static/list/hex_vals = list(\
		"0"=0, "1"=1, "2"=2, "3"=3, "4"=4, "5"=5, "6"=6, "7"=7,\
		"8"=8, "9"=9, "a"=10, "b"=11, "c"=12, "d"=13, "e"=14, "f"=15,\
		"A"=10, "B"=11, "C"=12, "D"=13, "E"=14, "F"=15\
	)
	return hex_vals[copytext(hex_pair, 1, 2)] * 16 + hex_vals[copytext(hex_pair, 2, 3)]


/datum/round_event/comet_belt/proc/update_space_glow(glow_color, glow_alpha)
	for(var/client/C in glow_overlays)
		var/atom/movable/screen/comet_space_glow/glow = glow_overlays[C]
		if(glow)
			glow.color = glow_color
			animate(glow, alpha = glow_alpha, time = 20)

/datum/round_event/comet_belt/proc/fade_space_glow()
	for(var/client/C in glow_overlays)
		var/atom/movable/screen/comet_space_glow/glow = glow_overlays[C]
		if(glow)
			animate(glow, alpha = 0, time = 60)

/datum/round_event/comet_belt/proc/add_comet_overlays(client/C)
	if(!C)
		return
	if(!comet_overlays[C])
		var/atom/movable/screen/comet_overlay/comet = new
		comet_overlays[C] = comet
		all_overlay_objects += comet
		C.screen += comet
		comet.fade_in(20)		// быстрый fade-in
	if(!trails_overlays[C])
		var/atom/movable/screen/comet_trails_overlay/trail = new
		trails_overlays[C] = trail
		all_overlay_objects += trail
		C.screen += trail
		trail.fade_in(20)
	if(!dust_overlays[C])
		var/atom/movable/screen/comet_dust_overlay/dust = new
		dust_overlays[C] = dust
		all_overlay_objects += dust
		C.screen += dust
	if(!belt_stream_overlays[C])
		var/atom/movable/screen/comet_belt_stream_overlay/belt = new
		belt_stream_overlays[C] = belt
		all_overlay_objects += belt
		C.screen += belt
		belt.fade_in(40)
	if(!glow_overlays[C])
		var/atom/movable/screen/comet_space_glow/glow = new
		glow_overlays[C] = glow
		all_overlay_objects += glow
		C.screen += glow

/datum/round_event/comet_belt/proc/start_fade_out()
	for(var/client/C in comet_overlays)
		var/atom/movable/screen/comet_overlay/comet = comet_overlays[C]
		if(comet)
			comet.fade_out(60)
	for(var/client/C in trails_overlays)
		var/atom/movable/screen/comet_trails_overlay/trail = trails_overlays[C]
		if(trail)
			trail.fade_out(60)
	for(var/client/C in dust_overlays)
		var/atom/movable/screen/comet_dust_overlay/dust = dust_overlays[C]
		if(dust)
			dust.fade_out(80)
	for(var/client/C in belt_stream_overlays)
		var/atom/movable/screen/comet_belt_stream_overlay/belt = belt_stream_overlays[C]
		if(belt)
			belt.fade_out(80)

/datum/round_event/comet_belt/proc/comet_final_cleanup()
	// Снять оверлеи с экранов живых клиентов
	for(var/client/C in comet_overlays)
		C.screen -= comet_overlays[C]
	for(var/client/C in trails_overlays)
		C.screen -= trails_overlays[C]
	for(var/client/C in dust_overlays)
		C.screen -= dust_overlays[C]
	for(var/client/C in belt_stream_overlays)
		C.screen -= belt_stream_overlays[C]
	for(var/client/C in glow_overlays)
		C.screen -= glow_overlays[C]
	for(var/client/C in flash_overlays)
		C.screen -= flash_overlays[C]
	// Удалить ВСЕ оверлеи (включая сироты от отключившихся клиентов)
	for(var/atom/movable/O in all_overlay_objects)
		qdel(O)
	// Отдельно flash-оверлеи (создаются вне add_comet_overlays)
	for(var/key in flash_overlays)
		var/atom/movable/screen/comet_flash/flash = flash_overlays[key]
		if(flash && !(flash in all_overlay_objects))
			qdel(flash)
	all_overlay_objects.Cut()
	comet_overlays.Cut()
	trails_overlays.Cut()
	dust_overlays.Cut()
	belt_stream_overlays.Cut()
	glow_overlays.Cut()
	flash_overlays.Cut()
