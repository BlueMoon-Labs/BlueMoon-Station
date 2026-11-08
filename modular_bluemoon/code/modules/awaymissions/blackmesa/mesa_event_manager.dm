GLOBAL_VAR_INIT(zombie_director, null)

// =============================================================================
// FORWARD DECLARATIONS (ПРОТОТИПЫ)
// =============================================================================
/datum/ai_director/zombie_mission

// =============================================================================
// MAIN SUBSYSTEM
// =============================================================================
SUBSYSTEM_DEF(blackmesa_events)
	name = "Black Mesa Events"
	runlevels = RUNLEVEL_GAME
	wait = 3000
	var/list/event_controls = list()
	var/day_phase = 0 // 0=Evening, 1=Night, 2=Morning, 3=Day
	var/phase_timer = 2 // Change every 2 fires (10 minutes)
	var/zombie_director_ref
	var/hecu_conflict_mode
	var/hecu_conflict_round_start_time
	var/hecu_ghost_roles_notified = FALSE

/datum/controller/subsystem/blackmesa_events/Initialize(time, zlevel)
	if(SSticker)
		hecu_conflict_round_start_time = SSticker.round_start_time
	for(var/type in typesof(/datum/round_event_control/blackmesa))
		if(type == /datum/round_event_control/blackmesa)
			continue
		var/datum/round_event_control/E = new type()
		if(!E.typepath)
			continue
		event_controls += E


	initialize_zombie_director()
	zombie_director_ref = GLOB.zombie_director
	return ..()

/datum/controller/subsystem/blackmesa_events/fire(resumed = FALSE)
	// Mission load check
	var/list/mission_areas = get_areas(/area/awaymission/ihategordon, TRUE)
	if(!mission_areas || !mission_areas.len)
		return

	// Day/Night Cycle
	phase_timer--
	if(phase_timer <= 0)
		phase_timer = 2
		cycle_day_night()

	if(!length(event_controls))
		return

	// Get current difficulty level from zombie director
	var/current_difficulty = 0
	if(GLOB.zombie_director)
		var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
		if(D)
			current_difficulty = D.difficulty_level

	var/list/possible_events = list()
	for(var/datum/round_event_control/E in event_controls)
		if(!E)
			continue
		if(E.max_occurrences > 0 && E.occurrences >= E.max_occurrences)
			continue
		// Check if event meets difficulty requirement
		if(istype(E, /datum/round_event_control/blackmesa))
			var/datum/round_event_control/blackmesa/BE = E
			if(BE && BE.min_difficulty_level > current_difficulty)
				continue
		possible_events += E

	if(!length(possible_events))
		return

	var/list/event_weights = list()
	for(var/datum/round_event_control/E in possible_events)
		if(!E)
			continue
		event_weights[E] = E.weight

	var/datum/round_event_control/selected = pickweight(event_weights)
	if(selected)
		selected.runEvent(random = TRUE)

/datum/controller/subsystem/blackmesa_events/proc/cycle_day_night()
	day_phase = (day_phase + 1) % 4
	var/new_color = "#6d4525"
	var/announce_text = ""
	var/announce_title = ""
	var/light_power = 0.8

	switch(day_phase)
		if(0) // Evening - gloomy dark red
			new_color = "#2a0a00"
			light_power = 0.6
			announce_text = "Внимание! Наступает вечер. Рекомендуется включить дополнительное освещение. ВНИМАНИЕ! состояние сектора ухудшается. Всем немедленно проследовать к ближайшим выходам из сектора."
			announce_title = "Evening Approach"
		if(1) // Night - gloomy like evening but still oppressive
			new_color = "#2a0a00"
			light_power = 0.6
			announce_text = "Внимание! Наступает ночь. Всем сотрудникам заступивших на ночную смену приступить к работе. ВНИМАНИЕ! Состояние сектора всё ещё критично. Требуется Немедленная эвакуация"
			announce_title = "Nightfall"
		if(2) // Morning - still dark and gloomy
			new_color = "#1f0800"
			light_power = 0.5
			announce_text = "Внимание! Наступает утро. Начало дневной смены через 30 минут. ВНИМАНИЕ! Состояние сектора остаётся критичным. Всем сотрудникам рекомендуется следовать указаниям военных подразделений HECU"
			announce_title = "Morning"
		if(3) // Day - dim and oppressive
			new_color = "#2d0f00"
			light_power = 0.7
			announce_text = "Внимание! Наступил день. Большая часть систем выведена из строя. Рекомендуется проведение немедленной эвакуации с сектора "
			announce_title = "Daytime"

	update_mesa_lights(new_color, light_power)
	mesa_announce(announce_text, announce_title, 'modular_bluemoon/sound/ambience/mesa/timeevent.ogg')

/datum/controller/subsystem/blackmesa_events/proc/update_mesa_lights(color, light_power)
	// Update floodlights
	if(!GLOB.machines)
		return
	for(var/obj/machinery/power/floodlight/urbanismlight/mesaoutside/L in GLOB.machines)
		if(!L || !istype(get_area(L), /area/awaymission/ihategordon))
			continue
		L.light_color = color
		L.set_light(L.light_range, light_power, color)

	// Update area lighting for all ihategordon areas (except those with ignore_mesa_events)
	for(var/area/awaymission/ihategordon/A in get_areas(/area/awaymission/ihategordon, TRUE))
		if(!A)
			continue
		// Skip areas that ignore mesa events - safely check if var exists
		var/skip_area = FALSE
		if("ignore_mesa_events" in A.vars)
			var/var_value = A.vars["ignore_mesa_events"]
			if(var_value)
				skip_area = TRUE
		if(skip_area)
			continue
		// Set gloomy ambient lighting via the official API so turf overlays are rebuilt
		A.set_dynamic_lighting(DYNAMIC_LIGHTING_IFSTARLIGHT)

/datum/controller/subsystem/blackmesa_events/proc/mesa_announce(text, title = "", sound = null, excluded_faction = null)
	if(!text)
		return
	var/announcement = "<h1 class='alert'>Black Mesa Announcement System</h1>"
	if(title)
		announcement += "<br><h2 class='alert'>[html_encode(title)]</h2>"
	announcement += "<br>[span_alert("[html_encode(text)]")]<br>"

	var/s = sound ? sound(sound) : null
	var/players_notified = 0
	for(var/mob/M in GLOB.player_list)
		if(!M)
			continue
		if(isnewplayer(M))
			continue
		var/area/A = get_area(M)
		if(!A)
			continue
		if(istype(A, /area/awaymission/ihategordon))
			if(excluded_faction && isliving(M))
				var/mob/living/living_mob = M
				if(excluded_faction in living_mob.faction)
					continue
			to_chat(M, announcement)
			players_notified++
			if(s && M.client && M.client.prefs && (M.client.prefs.toggles & SOUND_ANNOUNCEMENTS))
				SEND_SOUND(M, s)

	log_world("mesa_announce: '[title]' - notified [players_notified] players in Black Mesa area")

/datum/controller/subsystem/blackmesa_events/proc/declare_hecu_conflict(mob/living/user, conflict_mode, custom_announcement)
	if(SSticker && hecu_conflict_round_start_time != SSticker.round_start_time)
		hecu_conflict_round_start_time = SSticker.round_start_time
		hecu_conflict_mode = null
	if(hecu_conflict_mode)
		to_chat(user, span_warning("Конфликт уже был объявлен. Повторное объявление невозможно."))
		return FALSE
	if(!user || !user.client || !(FACTION_HECU in user.faction) || !istype(get_area(user), /area/awaymission/ihategordon))
		to_chat(user, span_warning("Устройство работает только для HECU внутри гейта Сектора H."))
		return FALSE
	if(conflict_mode != "war" && conflict_mode != "truce")
		to_chat(user, span_warning("Выбран неизвестный режим объявления."))
		return FALSE

	hecu_conflict_mode = conflict_mode
	var/announcement = custom_announcement
	if(!announcement)
		if(conflict_mode == "war")
			announcement = "Командование HECU объявляет Сектор H зоной боевых действий. Приказ: уничтожить экспедиторов и учёных Чёрной Мезы, находившихся в гейте на момент объявления."
		else
			announcement = "Командование HECU объявляет перемирие. Из-за установления перемирия конфликт между HECU и персоналом Сектора H невозможен. Всем сотрудникам, кроме HECU, оставаться в гейте и соблюдать указания командования."

	if(conflict_mode == "war")
		mesa_announce(announcement, "HECU: ОБЪЯВЛЕНИЕ ВОЙНЫ", 'modular_bluemoon/sound/ambience/mesa/hecudanger.ogg')
		issue_hecu_orders(
			"Приказ HECU: уничтожить экспедиторов и учёных Чёрной Мезы, находившихся в гейте в момент объявления войны.",
			"Уничтожить экспедиторов и учёных Чёрной Мезы, находившихся в Секторе H в момент объявления войны.",
		)
		spawn_conflict_ghost_roles(
			/obj/effect/mob_spawn/human/black_mesa/hecu/machinegunner,
			/obj/effect/landmark/awaymission/blackmesa/hecu_machinegunner_spawn,
			1,
			"HECU: пулемётчик прибыл",
		)
		spawn_conflict_ghost_roles(
			/obj/effect/mob_spawn/human/black_mesa/hecu/sniper,
			/obj/effect/landmark/awaymission/blackmesa/hecu_sniper_spawn,
			1,
			"HECU: снайпер прибыл",
		)
		return TRUE

	mesa_announce(
		announcement,
		"HECU: ПЕРЕМИРИЕ",
		'modular_bluemoon/sound/ambience/mesa/BMAS1.ogg',
		FACTION_HECU,
	)
	issue_hecu_orders(
		"Перемирие установлено. HECU должны немедленно эвакуироваться из гейта Сектора H.",
		"Объеденится с персоналом и вторженцами, после чего немедленно эвакуироваться из гейта Сектора H.",
	)
	spawn_conflict_ghost_roles(
		/obj/effect/mob_spawn/human/black_mesa/hecu/blackops/assault,
		/obj/effect/landmark/awaymission/blackmesa/blackops_spawn,
		4,
		"Black Ops: доступны роли оперативников зачистки",
	)
	set_maximum_difficulty()
	return TRUE

/datum/controller/subsystem/blackmesa_events/proc/issue_hecu_orders(message, objective_text)
	for(var/mob/living/hecu in GLOB.player_list)
		if(!hecu.client || hecu.stat == DEAD || !(FACTION_HECU in hecu.faction))
			continue
		if(!istype(get_area(hecu), /area/awaymission/ihategordon))
			continue
		to_chat(hecu, span_warning(message))
		add_scenario_objective(hecu, objective_text)

/datum/controller/subsystem/blackmesa_events/proc/add_scenario_objective(mob/living/target, objective_text)
	if(!target.mind)
		return
	var/datum/antagonist/ghost_role/ghost_role = target.mind.has_antag_datum(/datum/antagonist/ghost_role)
	if(!ghost_role)
		return
	for(var/datum/objective/custom/existing_objective in ghost_role.objectives)
		if(existing_objective.explanation_text == objective_text)
			return
	var/datum/objective/custom/objective = new(objective_text)
	objective.owner = target.mind
	ghost_role.objectives += objective
	target.mind.announce_objectives()

/datum/controller/subsystem/blackmesa_events/proc/spawn_conflict_ghost_roles(spawner_type, landmark_type, amount, notify_header)
	var/list/spawn_landmarks = list()
	for(var/obj/effect/landmark/awaymission/blackmesa/landmark in GLOB.landmarks_list)
		if(!istype(landmark, landmark_type))
			continue
		if(istype(get_area(landmark), /area/awaymission/ihategordon))
			spawn_landmarks += landmark

	if(!length(spawn_landmarks))
		stack_trace("No valid Black Mesa landmarks for ghost role [spawner_type] at landmark [landmark_type].")
		return 0

	var/spawned_count = 0
	for(var/i in 1 to amount)
		var/obj/effect/landmark/awaymission/blackmesa/spawn_landmark = spawn_landmarks[((i - 1) % length(spawn_landmarks)) + 1]
		var/turf/spawn_turf = get_turf(spawn_landmark)
		if(!spawn_turf)
			stack_trace("Black Mesa ghost role landmark [spawn_landmark] has no turf.")
			continue
		var/obj/effect/mob_spawn/human/black_mesa/spawner = new spawner_type(spawn_turf)
		if(!spawner)
			continue
		spawned_count++
		notify_ghosts(
			"[spawner.name] is available in [get_area_name(spawn_turf)].",
			source = spawner,
			action = NOTIFY_ATTACK,
			header = notify_header,
			ignore_dnr_observers = TRUE,
		)
	if(spawned_count < amount)
		stack_trace("Only [spawned_count] of [amount] requested Black Mesa ghost role spawners could be placed for [spawner_type].")
	return spawned_count

/datum/controller/subsystem/blackmesa_events/proc/notify_hecu_ghost_roles()
	if(hecu_ghost_roles_notified)
		return

	for(var/obj/effect/mob_spawn/human/black_mesa/hecu/spawner in GLOB.poi_list)
		if(QDELETED(spawner) || !spawner.ghost_usable || !spawner.uses || !get_turf(spawner))
			continue

		hecu_ghost_roles_notified = TRUE
		notify_ghosts(
			"Доступна гост-роль HECU: [spawner.name]. Нажмите на уведомление, чтобы перейти к спавнеру и выбрать эту роль.",
			source = spawner,
			action = NOTIFY_ATTACK,
			header = "Доступны гост-роли HECU",
			ignore_dnr_observers = TRUE,
		)
		return

/datum/controller/subsystem/blackmesa_events/proc/set_maximum_difficulty()
	if(!GLOB.zombie_director)
		initialize_zombie_director()
	var/datum/ai_director/zombie_mission/director = GLOB.zombie_director
	if(!director)
		stack_trace("Could not raise Black Mesa difficulty: zombie director is unavailable.")
		return
	director.difficulty_level = 8
	director.zombie_hp_multiplier = 3.0
	mesa_announce(
		"Отряд ХЕКУ объявляет перемирие и ОТКАЗЫВАЕТСЯ следовать приказу по уничтожению свидетелй. Уровень опасности Сектора H повышен до максимального. Ожидается резкое усиление враждебной активности.",
		"МАКСИМАЛЬНЫЙ УРОВЕНЬ ОПАСНОСТИ",
		'modular_bluemoon/sound/ambience/mesa/BMAS3.ogg',
	)

/datum/controller/subsystem/blackmesa_events/proc/initialize_zombie_director()
	if(!GLOB.zombie_director)
		GLOB.zombie_director = new /datum/ai_director/zombie_mission()
