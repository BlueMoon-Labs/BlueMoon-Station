SUBSYSTEM_DEF(nightshift)
	name = "Night Shift"
	wait = 600
	flags = SS_NO_TICK_CHECK

	var/nightshift_active = FALSE
	var/nightshift_start_time = 702000		//7:30 PM, solar time
	var/nightshift_end_time = 270000		//7:30 AM, solar time
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
	for(var/mob/M in GLOB.player_list)
		if(!isnewplayer(M))
			to_chat(M, "[span_minorannounce("<font color=red>Автоматическая Система Освещения</font><BR>[message]")]<BR>")
			if(announcement_sound && M.can_hear() && M.client?.prefs?.toggles & SOUND_ANNOUNCEMENTS)
				SEND_SOUND(M, sound(announcement_sound))

/datum/controller/subsystem/nightshift/proc/check_nightshift()
	var/emergency = GLOB.security_level > SEC_LEVEL_GREEN
	var/announcing = TRUE
	var/time = SOLAR_TIME(FALSE, world.time)
	var/night_time = (time < nightshift_end_time) || (time > nightshift_start_time)
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
	if(nightshift_active != night_time)
		update_nightshift(night_time, announcing)

/datum/controller/subsystem/nightshift/proc/update_nightshift(active, announce = TRUE, max_level_override)
	set waitfor = FALSE
	nightshift_active = active
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
	for(var/A in GLOB.apcs_list)
		var/obj/machinery/power/apc/APC = A
		if(APC.area?.type in GLOB.the_station_areas)
			var/their_level = APC.area.nightshift_public_area
			if(!max_level || (their_level <= max_level))		//if max level is 0, it means public area-only config is disabled so hit everything. if their level is 0, it means they have nightshift forced.
				APC.set_nightshift(active)
				CHECK_TICK

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
		list(0,      COLOR_STARLIGHT,        STARLIGHT_POWER_NIGHT), \
		list(198000, COLOR_STARLIGHT,        STARLIGHT_POWER_NIGHT), \
		list(252000, STARLIGHT_COLOR_DAWN,   STARLIGHT_POWER_DAWN),  \
		list(324000, STARLIGHT_COLOR_DAY,    0.70),                  \
		list(432000, STARLIGHT_COLOR_DAY,    STARLIGHT_POWER_DAY),   \
		list(540000, STARLIGHT_COLOR_DAY,    0.70),                  \
		list(648000, STARLIGHT_COLOR_DAWN,   STARLIGHT_POWER_DAWN),  \
		list(702000, STARLIGHT_COLOR_DUSK,   0.55),                  \
		list(756000, STARLIGHT_COLOR_EVENING, 0.52),                 \
		list(792000, COLOR_STARLIGHT,        STARLIGHT_POWER_NIGHT), \
		list(864000, COLOR_STARLIGHT,        STARLIGHT_POWER_NIGHT), \
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
