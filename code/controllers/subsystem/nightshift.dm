SUBSYSTEM_DEF(nightshift)
	name = "Night Shift"
	wait = 1 MINUTES
	flags = SS_NO_TICK_CHECK

	var/nightshift_active = FALSE
	var/nightshift_start_time = 19 HOURS + 30 MINUTES	//7:30 PM, solar time
	var/nightshift_end_time = 7 HOURS + 30 MINUTES		//7:30 AM, solar time
	var/nightshift_first_check = 30 SECONDS

	var/high_security_mode = FALSE

	/// Whether dynamic starlight color cycling is enabled (from config)
	var/dynamic_starlight_enabled = FALSE
	/// Admin or event override — suppresses solar cycle when TRUE
	var/starlight_override = FALSE
	/// Last computed starlight color (for quantized skip)
	var/last_starlight_color
	/// Last computed starlight power (for quantized skip)
	var/last_starlight_power
	/// Last quantized indoor nightshift level propagated to APCs.
	var/last_indoor_nightshift_level = 0
	/// Observability: APCs touched by the most recent indoor refresh.
	var/last_nightshift_apcs_touched = 0
	/// Observability: lamps queued by the most recent indoor refresh.
	var/last_nightshift_lights_queued = 0
	/// Monotonic request id for async APC refresh selection.
	var/nightshift_refresh_generation = 0
	/// TRUE while the APC selection pass is asynchronously walking GLOB.apcs_list.
	var/nightshift_refresh_running = FALSE
	/// Latest desired automatic nightshift state awaiting APC selection.
	var/queued_nightshift_active = FALSE
	var/queued_nightshift_level = 0
	var/queued_nightshift_max_level = 0
	var/queued_nightshift_force_clear = FALSE
	/// Admin-only solar-time override state. Stores the pre-override offset so Clear Override can restore normal progression.
	var/admin_solar_time_override = FALSE
	var/admin_solar_time_restore_offset = null

/datum/controller/subsystem/nightshift/Initialize()
	if(!CONFIG_GET(flag/enable_night_shifts))
		can_fire = FALSE
	dynamic_starlight_enabled = CONFIG_GET(flag/dynamic_starlight_cycle) && CONFIG_GET(flag/starlight) && CONFIG_GET(flag/enable_night_shifts)
	// Pre-seed starlight state so the first fire() doesn't trigger a redundant full iteration.
	// Space turfs already receive their initial light during SSlighting init via update_starlight().
	if(dynamic_starlight_enabled)
		var/solar_time = SOLAR_TIME(FALSE, world.time)
		var/list/result = compute_solar_starlight(solar_time)
		if(result)
			last_starlight_color = result[1]
			last_starlight_power = result[2]
			GLOB.current_starlight_color = result[1]
			GLOB.current_starlight_power = result[2]
	return ..()

/datum/controller/subsystem/nightshift/fire(resumed = FALSE)
	if(world.time - SSticker.round_start_time < nightshift_first_check)
		return
	check_nightshift()
	if(dynamic_starlight_enabled && !starlight_override)
		update_solar_starlight()

/datum/controller/subsystem/nightshift/proc/announce(message, announcement_sound)
	for(var/mob/M as anything in GLOB.player_list)
		if(!isnewplayer(M))
			to_chat(M, "[span_minorannounce("<font color=red>Автоматическая Система Освещения</font><BR>[message]")]<BR>")
			if(announcement_sound && M.can_hear() && M.client?.prefs?.toggles & SOUND_ANNOUNCEMENTS)
				SEND_SOUND(M, sound(announcement_sound))

/datum/controller/subsystem/nightshift/proc/check_nightshift(immediate_refresh = FALSE)
	var/emergency = GLOB.security_level > SEC_LEVEL_GREEN
	var/announcing = TRUE
	var/time = SOLAR_TIME(FALSE, world.time)
	var/night_time = is_solar_time_night(time)
	var/indoor_level = get_automatic_nightshift_level(time)
	if(high_security_mode != emergency)
		high_security_mode = emergency
		if(night_time)
			announcing = FALSE
			if(!emergency)
				announce("Восстановление нормальной работы конфигурации ночного освещения.", 'sound/misc/notice2.ogg')
			else
				announce("Отключение ночного освещения: станция находится в аварийном состоянии.", 'sound/misc/notice2.ogg')
	if(emergency)
		night_time = FALSE
		indoor_level = 0
	if(nightshift_active != night_time || last_indoor_nightshift_level != indoor_level)
		update_nightshift(night_time, announcing && (nightshift_active != night_time), null, immediate_refresh)

/datum/controller/subsystem/nightshift/proc/update_nightshift(active, announce = TRUE, max_level_override, immediate_refresh = FALSE, indoor_level_override)
	var/indoor_level = isnull(indoor_level_override) ? (active ? get_automatic_nightshift_level() : 0) : quantize_nightshift_level(indoor_level_override)
	var/force_clear_manual_override = !active && high_security_mode
	nightshift_active = active
	last_indoor_nightshift_level = indoor_level
	last_nightshift_apcs_touched = 0
	last_nightshift_lights_queued = 0
	if(announce)
		if(active)
			announce("Добрый вечер, экипаж. Чтобы снизить потребление энергии и стимулировать Биоритмы некоторых видов, все осветительные приборы на борту станции были приглушены на ночь.", 'modular_bluemoon/sound/announcements/night_light_notification.ogg')
		else
			announce("Доброе утро, экипаж. Поскольку сейчас дневное время, все осветительные приборы на борту станции были восстановлены до их прежней яркости.", 'modular_bluemoon/sound/announcements/day_light_notification.ogg')
	var/max_level
	var/configured_level = CONFIG_GET(number/night_shift_public_areas_only)
	if(isnull(max_level_override))
		max_level = active? configured_level : INFINITY		//by default, deactivating shuts off nightshifts everywhere.
	else
		max_level = max_level_override
	queue_apc_nightshift_refresh(active, indoor_level, max_level, force_clear_manual_override, immediate_refresh)

/datum/controller/subsystem/nightshift/proc/queue_apc_nightshift_refresh(active, indoor_level, max_level, force_clear_manual_override, immediate_refresh = FALSE)
	queued_nightshift_active = active
	queued_nightshift_level = indoor_level
	queued_nightshift_max_level = max_level
	queued_nightshift_force_clear = force_clear_manual_override
	nightshift_refresh_generation++
	if(immediate_refresh)
		process_apc_nightshift_refresh_now()
	else if(!nightshift_refresh_running)
		nightshift_refresh_running = TRUE
		process_apc_nightshift_refresh()

/datum/controller/subsystem/nightshift/proc/queue_apc_refresh_generation(active, indoor_level, max_level, force_clear_manual_override, request_generation)
	var/apcs_touched = 0
	for(var/A in GLOB.apcs_list)
		var/obj/machinery/power/apc/APC = A
		var/area/apc_area = APC.area
		if(apc_area?.is_station_member())
			var/their_level = apc_area.nightshift_public_area
			if(!max_level || (their_level <= max_level))
				if(APC.accepts_automatic_nightshift(force_clear_manual_override))
					apcs_touched++
					APC.queue_nightshift_refresh(active, indoor_level, force_clear_manual_override)
		CHECK_TICK
		if(request_generation != nightshift_refresh_generation)
			return apcs_touched
	return apcs_touched

/datum/controller/subsystem/nightshift/proc/queue_apc_refresh_generation_immediate(active, indoor_level, max_level, force_clear_manual_override)
	var/apcs_touched = 0
	for(var/A in GLOB.apcs_list)
		var/obj/machinery/power/apc/APC = A
		var/area/apc_area = APC.area
		if(apc_area?.is_station_member())
			var/their_level = apc_area.nightshift_public_area
			if(!max_level || (their_level <= max_level))
				if(APC.accepts_automatic_nightshift(force_clear_manual_override))
					apcs_touched++
					APC.queue_nightshift_refresh(active, indoor_level, force_clear_manual_override)
	return apcs_touched

/datum/controller/subsystem/nightshift/proc/process_apc_nightshift_refresh()
	set waitfor = FALSE
	while(TRUE)
		var/request_generation = nightshift_refresh_generation
		var/active = queued_nightshift_active
		var/indoor_level = queued_nightshift_level
		var/max_level = queued_nightshift_max_level
		var/force_clear_manual_override = queued_nightshift_force_clear
		var/apcs_touched = queue_apc_refresh_generation(active, indoor_level, max_level, force_clear_manual_override, request_generation)
		if(request_generation == nightshift_refresh_generation)
			last_nightshift_apcs_touched = apcs_touched
			last_nightshift_lights_queued = 0
			break
	nightshift_refresh_running = FALSE

/datum/controller/subsystem/nightshift/proc/process_apc_nightshift_refresh_now()
	// The synchronous path is used by no-sleep callers such as Initialize/death chains,
	// so it must not yield through CHECK_TICK/stoplag.
	last_nightshift_apcs_touched = queue_apc_refresh_generation_immediate(
		queued_nightshift_active,
		queued_nightshift_level,
		queued_nightshift_max_level,
		queued_nightshift_force_clear,
	)
	last_nightshift_lights_queued = 0
	nightshift_refresh_running = FALSE

/datum/controller/subsystem/nightshift/proc/drain_admin_nightshift_refresh()
	SSlighting.process_admin_nightshift_refresh_now()

/datum/controller/subsystem/nightshift/proc/normalize_admin_solar_time(solar_time)
	while(solar_time < 0)
		solar_time += 24 HOURS
	while(solar_time >= 24 HOURS)
		solar_time -= 24 HOURS
	return solar_time

/datum/controller/subsystem/nightshift/proc/is_solar_time_night(solar_time)
	return (solar_time < nightshift_end_time) || (solar_time >= nightshift_start_time)

/datum/controller/subsystem/nightshift/proc/get_automatic_nightshift_level(solar_time = SOLAR_TIME(FALSE, world.time))
	if(high_security_mode)
		return 0
	return quantize_nightshift_level(is_solar_time_night(solar_time) ? compute_indoor_nightshift_level(solar_time) : 0)

/datum/controller/subsystem/nightshift/proc/get_admin_mode_label()
	if(can_fire && CONFIG_GET(flag/enable_night_shifts))
		return "Auto"
	return nightshift_active ? "On" : "Off"

/datum/controller/subsystem/nightshift/proc/get_admin_status_text()
	var/solar_time = normalize_admin_solar_time(SOLAR_TIME(FALSE, world.time))
	return "Solar time: [seconds_to_clock(round(solar_time / 10))] | Mode: [get_admin_mode_label()] | Auto level: [round(get_automatic_nightshift_level(solar_time), 0.01)]"

/datum/controller/subsystem/nightshift/proc/apply_admin_starlight_now()
	var/solar_time = normalize_admin_solar_time(SOLAR_TIME(FALSE, world.time))
	var/list/result = compute_solar_starlight(solar_time)
	if(!result)
		return
	last_starlight_color = result[1]
	last_starlight_power = result[2]
	GLOB.current_starlight_color = result[1]
	GLOB.current_starlight_power = result[2]
	set_starlight(result[1], result[2])

/datum/controller/subsystem/nightshift/proc/apply_admin_mode(mode)
	switch(mode)
		if("Auto", "Авто")
			if(CONFIG_GET(flag/enable_night_shifts))
				can_fire = TRUE
				check_nightshift(TRUE)
			else
				can_fire = FALSE
				update_nightshift(FALSE, TRUE, null, TRUE)
		if("On", "Вкл")
			can_fire = FALSE
			update_nightshift(TRUE, TRUE, null, TRUE, 1)
		if("Off", "Выкл")
			can_fire = FALSE
			update_nightshift(FALSE, TRUE, null, TRUE)
		else
			return FALSE
	if(dynamic_starlight_enabled && !starlight_override)
		apply_admin_starlight_now()
	drain_admin_nightshift_refresh()
	return TRUE

/datum/controller/subsystem/nightshift/proc/set_admin_solar_time_override(solar_time)
	if(!admin_solar_time_override)
		admin_solar_time_restore_offset = SSticker.gametime_offset
	admin_solar_time_override = TRUE
	var/current_progress = (world.time - SSticker.round_start_time) * SSticker.station_time_rate_multiplier
	SSticker.gametime_offset = normalize_admin_solar_time(solar_time - current_progress)
	return SSticker.gametime_offset

/datum/controller/subsystem/nightshift/proc/clear_admin_solar_time_override()
	if(!admin_solar_time_override)
		return FALSE
	SSticker.gametime_offset = admin_solar_time_restore_offset
	admin_solar_time_restore_offset = null
	admin_solar_time_override = FALSE
	return TRUE

/datum/controller/subsystem/nightshift/proc/parse_admin_solar_time_input(raw_value)
	if(isnull(raw_value))
		return null
	var/text_value = trim("[raw_value]")
	if(!length(text_value))
		return null
	var/list/time_parts = splittext(text_value, ":")
	if(length(time_parts) < 2 || length(time_parts) > 3)
		return null
	var/hours = text2num(time_parts[1])
	var/minutes = text2num(time_parts[2])
	var/seconds = length(time_parts) >= 3 ? text2num(time_parts[3]) : 0
	if(isnull(hours) || isnull(minutes) || isnull(seconds))
		return null
	if(hours < 0 || hours >= 24 || minutes < 0 || minutes >= 60 || seconds < 0 || seconds >= 60)
		return null
	return hours HOURS + minutes MINUTES + seconds SECONDS

/datum/controller/subsystem/nightshift/proc/apply_admin_solar_time_change(solar_time, clear_override = FALSE)
	if(clear_override)
		clear_admin_solar_time_override()
	else
		set_admin_solar_time_override(solar_time)
	if(dynamic_starlight_enabled && !starlight_override)
		apply_admin_starlight_now()
	if(can_fire && CONFIG_GET(flag/enable_night_shifts))
		check_nightshift(TRUE)
	drain_admin_nightshift_refresh()
	return TRUE

/// Quantizes indoor nightshift interpolation to stable visual steps.
/datum/controller/subsystem/nightshift/proc/quantize_nightshift_level(level)
	return clamp(round(level, 0.05), 0, 1)

/// Returns 0..1 indoor nightshift intensity interpolated from station-local solar time.
/datum/controller/subsystem/nightshift/proc/compute_indoor_nightshift_level(solar_time)
	var/static/list/anchors = list(
		list(6 HOURS,               0.35),
		list(7 HOURS + 30 MINUTES,  0),
		list(19 HOURS + 30 MINUTES, 0.20),
		list(21 HOURS,              0.55),
		list(23 HOURS + 30 MINUTES, 1),
	)

	var/list/a1
	var/list/a2
	if(solar_time < anchors[1][1])
		a1 = list(anchors[length(anchors)][1] - 24 HOURS, anchors[length(anchors)][2])
		a2 = anchors[1]
	else
		for(var/i in 2 to length(anchors))
			if(solar_time <= anchors[i][1])
				a1 = anchors[i - 1]
				a2 = anchors[i]
				break
		if(!a1)
			a1 = anchors[length(anchors)]
			a2 = list(anchors[1][1] + 24 HOURS, anchors[1][2])

	var/span = a2[1] - a1[1]
	var/t = span > 0 ? clamp((solar_time - a1[1]) / span, 0, 1) : 0
	return a1[2] + (a2[2] - a1[2]) * t

/// Computes the current solar starlight color/power and applies it if changed.
/datum/controller/subsystem/nightshift/proc/update_solar_starlight()
	var/solar_time = SOLAR_TIME(FALSE, world.time)
	var/list/result = compute_solar_starlight(solar_time)
	if(!result)
		return
	var/new_color = result[1]
	var/new_power = result[2]
	// Quantized skip — avoid updating when nothing visually changed
	if(new_color == last_starlight_color && new_power == last_starlight_power)
		return
	last_starlight_color = new_color
	last_starlight_power = new_power
	GLOB.current_starlight_color = new_color
	GLOB.current_starlight_power = new_power
	// Signal SSlighting to propagate the change incrementally across space turfs,
	// instead of doing a synchronous full iteration here.
	GLOB.starlight_color_dirty = TRUE

/// Returns list(color_hex, power) interpolated from solar cycle anchor points.
/datum/controller/subsystem/nightshift/proc/compute_solar_starlight(solar_time)
	// Anchor points: list(time_ds, "#RRGGBB", power)
	// Smooth cycle: Night -> Dawn -> Day -> Dusk -> Night
	var/static/list/anchors = list(\
		list(0,                      COLOR_STARLIGHT,         STARLIGHT_POWER_NIGHT), \
		list(5 HOURS + 30 MINUTES,   COLOR_STARLIGHT,         STARLIGHT_POWER_NIGHT), \
		list(7 HOURS,                STARLIGHT_COLOR_DAWN,    STARLIGHT_POWER_DAWN),  \
		list(9 HOURS,                STARLIGHT_COLOR_DAY,     STARLIGHT_POWER_DAY_LOW), \
		list(12 HOURS,               STARLIGHT_COLOR_DAY,     STARLIGHT_POWER_DAY),     \
		list(15 HOURS,               STARLIGHT_COLOR_DAY,     STARLIGHT_POWER_DAY_LOW), \
		list(18 HOURS,               STARLIGHT_COLOR_DAWN,    STARLIGHT_POWER_DAWN),    \
		list(19 HOURS + 30 MINUTES,  STARLIGHT_COLOR_DUSK,    STARLIGHT_POWER_DUSK),    \
		list(21 HOURS,               STARLIGHT_COLOR_EVENING, STARLIGHT_POWER_EVENING), \
		list(22 HOURS,               COLOR_STARLIGHT,         STARLIGHT_POWER_NIGHT), \
		list(24 HOURS,               COLOR_STARLIGHT,         STARLIGHT_POWER_NIGHT), \
	)

	// Find bracketing anchors
	var/list/a1 = anchors[1]
	var/list/a2 = anchors[2]
	for(var/i in 2 to length(anchors))
		a2 = anchors[i]
		if(solar_time <= a2[1])
			break
		a1 = a2

	// Lerp factor
	var/span = a2[1] - a1[1]
	var/t = span > 0 ? clamp((solar_time - a1[1]) / span, 0, 1) : 0

	// Interpolate RGB channels
	var/r1 = GETREDPART(a1[2])
	var/g1 = GETGREENPART(a1[2])
	var/b1 = GETBLUEPART(a1[2])
	var/r2 = GETREDPART(a2[2])
	var/g2 = GETGREENPART(a2[2])
	var/b2 = GETBLUEPART(a2[2])

	var/r = round(r1 + (r2 - r1) * t, 4)
	var/g = round(g1 + (g2 - g1) * t, 4)
	var/b = round(b1 + (b2 - b1) * t, 4)

	var/new_color = rgb(r, g, b)
	var/new_power = round(a1[3] + (a2[3] - a1[3]) * t, 0.05)

	return list(new_color, new_power)
