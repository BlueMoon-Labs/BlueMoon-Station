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

/datum/controller/subsystem/blackmesa_events/Initialize(time, zlevel)
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
		if(!L)
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
		// Set gloomy ambient lighting
		A.dynamic_lighting = DYNAMIC_LIGHTING_IFSTARLIGHT
		// Set gloomy ambient lighting via the official API so turf overlays are rebuilt
		A.set_dynamic_lighting(DYNAMIC_LIGHTING_IFSTARLIGHT)

/datum/controller/subsystem/blackmesa_events/proc/mesa_announce(text, title = "", sound = null)
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
		if(istype(A, /area/awaymission/ihategordon) || istype(A, /area/command/gateway))
			to_chat(M, announcement)
			players_notified++
			if(s && M.client && M.client.prefs && (M.client.prefs.toggles & SOUND_ANNOUNCEMENTS))
				SEND_SOUND(M, s)

	log_world("mesa_announce: '[title]' - notified [players_notified] players in Black Mesa area")

/datum/controller/subsystem/blackmesa_events/proc/initialize_zombie_director()
	if(!GLOB.zombie_director)
		GLOB.zombie_director = new /datum/ai_director/zombie_mission()

