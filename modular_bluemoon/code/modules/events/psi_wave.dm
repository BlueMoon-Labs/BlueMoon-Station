/datum/round_event_control/psi_wave
	name = "Psionic Wave"
	typepath = /datum/round_event/psi_wave
	weight = 10
	min_players = 8
	max_occurrences = 3
	earliest_start = 20 MINUTES
	category = EVENT_CATEGORY_ANOMALIES
	description = "Через станцию проходит серия пси-волн, временно сводящая часть экипажа с ума."
	gamemode_whitelist = list("dynamic")

#define PSI_WAVE_SHIELDED_DURATION (25 SECONDS)

/datum/round_event/psi_wave
	announce_when = 1
	start_when = 2
	end_when = 80
	fakeable = TRUE
	var/wave_count = 0
	var/total_affected = 0
	var/total_shielded = 0
	var/list/announce_lines = list(
		"Зафиксирован кратковременный всплеск пси-активности неизвестной природы. \
		Часть экипажа может испытывать дезориентацию, слуховые и зрительные галлюцинации. \
		Рекомендуется оставаться на местах и не доверять сенсорным ощущениям.",
		"Сканеры дальнего радиуса фиксируют аномальную псионическую волну, прошедшую через сектор станции. \
		Возможны временные нарушения восприятия у живых организмов. \
		Бортовая медслужба уведомлена.",
		"Зарегистрирован паранормальный резонанс класса B. \
		У части экипажа возможны временные расстройства восприятия. \
		Носителям лояльных имплантов рекомендовано доложить о самочувствии командованию.",
		)
	var/list/announce_lines_end = list(
		"Параметры пси-фона возвращаются к нормальным значениям. Аномалия завершена. \
		Медицинская служба готова принять пострадавших с устойчивыми симптомами.",
		"Сканеры фиксируют затухание псионического резонанса. \
		Симптомы расстройства восприятия должны спасть в течение нескольких минут. \
		Сохраняющиеся проявления требуют обращения в медотсек.",
		"Аномалия снята. Сенсорные показатели вернулись в норму. \
		Командованию рекомендуется провести опрос по факту инцидента.",
		)

/datum/round_event/psi_wave/announce(fake)
	var/idx = rand(1, length(announce_lines))
	var/list/audio_pools = list(
		list(
			'sound/hallucinations/psychosis/psi_announce_1.ogg',
			'sound/hallucinations/psychosis/psi_announce_v3_1.ogg',
		),
		list(
			'sound/hallucinations/psychosis/psi_announce_2.ogg',
			'sound/hallucinations/psychosis/psi_announce_v3_2.ogg',
		),
		list(
			'sound/hallucinations/psychosis/psi_announce_3.ogg',
		),
	)
	priority_announce(
		announce_lines[idx],
		"Аномалия: пси-резонанс",
		pick(audio_pools[idx]),
	)

/datum/round_event/psi_wave/start()
	fire_wave(
		hit_chance = 45,
		duration_min = 60 SECONDS,
		duration_max = 120 SECONDS,
		hit_sound = 'sound/hallucinations/psychosis/synth_fx.ogg',
		shake_strength = 1,
		shake_duration = 1,
	)

/datum/round_event/psi_wave/tick()
	switch(activeFor)
		if(30)
			fire_wave(
				hit_chance = 60,
				duration_min = 90 SECONDS,
				duration_max = 180 SECONDS,
				hit_sound = 'sound/hallucinations/psychosis/stinger_plucked.ogg',
				ambient_sound = 'sound/hallucinations/psychosis/alarm_scifi_2.ogg',
				shake_strength = 2,
				shake_duration = 1,
			)
		if(60)
			fire_wave(
				hit_chance = 75,
				duration_min = 120 SECONDS,
				duration_max = 240 SECONDS,
				hit_sound = 'sound/hallucinations/psychosis/stinger_cruel.ogg',
				ambient_sound = 'sound/hallucinations/psychosis/alarm_scifi_3.ogg',
				shake_strength = 2,
				shake_duration = 2,
			)

/datum/round_event/psi_wave/end()
	var/idx = rand(1, length(announce_lines_end))
	var/list/audio_pools_end = list(
		list(
			'sound/hallucinations/psychosis/psi_announce_end_1.ogg',
			'sound/hallucinations/psychosis/psi_announce_end_v3_1.ogg',
		),
		list(
			'sound/hallucinations/psychosis/psi_announce_end_2.ogg',
			'sound/hallucinations/psychosis/psi_announce_end_v3_2.ogg',
		),
		list(
			'sound/hallucinations/psychosis/psi_announce_end_3.ogg',
		),
	)
	priority_announce(
		announce_lines_end[idx],
		"Аномалия: пси-резонанс снят",
		pick(audio_pools_end[idx]),
	)
	log_game("Psi Wave event finished: [wave_count] waves, [total_affected] total crew affected (+[total_shielded] briefly through mindshield).")
	message_admins("Psi Wave event finished: [wave_count] waves, [total_affected] crew (+[total_shielded] mindshield).")

/datum/round_event/psi_wave/proc/fire_wave(hit_chance, duration_min, duration_max, hit_sound, ambient_sound, shake_strength = 2, shake_duration = 1)
	wave_count++
	// Каждая волна имеет общую тему - связный нарратив для всей пострадавшей группы.
	var/picked_theme = pick(GLOB.psychosis_themes)
	var/affected = 0
	var/affected_shielded = 0
	for(var/mob/living/carbon/victim in shuffle(GLOB.alive_mob_list))
		if(QDELETED(victim) || !victim.client)
			continue
		if(victim.stat == DEAD)
			continue
		if(!is_station_level(victim.z))
			continue
		if(HAS_TRAIT(victim, TRAIT_EXEMPT_HEALTH_EVENTS))
			continue
		if(!victim.getorgan(/obj/item/organ/brain))
			continue
		if(HAS_TRAIT(victim, TRAIT_ANTIMAGIC))
			continue
		var/resisted = HAS_TRAIT(victim, TRAIT_MINDSHIELD)
		if(!resisted && !prob(hit_chance))
			continue
		var/duration
		if(resisted)
			duration = PSI_WAVE_SHIELDED_DURATION
			affected_shielded++
		else
			duration = rand(duration_min, duration_max)
			affected++
		victim.apply_psychosis(duration, picked_theme)
		if(hit_sound)
			victim.playsound_local(victim, hit_sound, 35, FALSE)
		if(ambient_sound)
			victim.playsound_local(victim, ambient_sound, 22, FALSE)
		shake_camera(victim, shake_duration, shake_strength)
	total_affected += affected
	total_shielded += affected_shielded
	log_game("Psi Wave #[wave_count]: hit_chance=[hit_chance], affected=[affected] (+[affected_shielded] mindshielded), theme=[picked_theme], duration=[duration_min/10]-[duration_max/10]s.")

#undef PSI_WAVE_SHIELDED_DURATION
