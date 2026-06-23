// ---------------------------------------------------------------------------
// Log Entry - Individual log message with text reveal animation
// ---------------------------------------------------------------------------
/datum/log_entry
	var/plain
	var/color
	var/char_index = 1
	var/char_speed
	var/size
	var/expiry_time
	var/font_family

/datum/log_entry/proc/format(text)
	return {"<span style='font-family: \"[font_family]\"; color: [color]; font-size: [size]pt; line-height: 0.8;-dm-text-outline: 1px black;'>[text]</span>"}

/datum/log_entry/proc/get_full_line()
	return format(plain)

/datum/log_entry/proc/get_line()
	if(char_index < length(plain))
		char_index = min(char_index + char_speed, length(plain)+1)

	var/revealed_text = copytext(plain, 1, char_index)

	return format(revealed_text)


// ---------------------------------------------------------------------------
// Log Module - Log holder
// ---------------------------------------------------------------------------
/datum/neural_interface_module/logs
	name = "LOGS MODULE"

	// Display configuration
	var/screen_loc = "LEFT+1.5,CENTER+1.5"
	var/maptext_width = 225
	var/maptext_height = 96

	var/list/datum/log_entry/logs = list()
	var/max_logs = 4
	var/atom/movable/screen/text/logs_view

	// UI customization
	var/header_color = "#4ad1fa86"
	var/separator_color = "#6b7280"
	var/font_size = 12
	var/font_family = "TinyUnicode"

	// Log category configuration
	var/list/log_categories = list(
		"SYSTEM" = "#4ad1fa86",
		"WARNING" = "#f59e0bff",
		"ERROR" = "#ef4444ff",
		"INFO" = "#10b981ff",
		"DATA" = "#8b5cf6ff",
		"SYNC" = "#06b6d4ff",
		"HEALTH" = "#f472b6ff",
		"MODULE" = "#a78bffff",
		"ALERT" = "#ff0000ff",
		"STATUS" = "#6b7280ff",
		"DEBUG" = "#94a3b8ff"
	)

	// Category-specific speeds (0 = use default)
	var/list/log_speeds = list(
		"SYSTEM" = 15,
		"WARNING" = 15,
		"ERROR" = 30,
		"INFO" = 15,
		"DATA" = 15,
		"SYNC" = 15,
		"HEALTH" = 30,
		"MODULE" = 15,
		"ALERT" = 30,
		"STATUS" = 10,
		"DEBUG" = 20
	)

/datum/neural_interface_module/logs/New()
	. = ..()
	logs_view = ScreenText(null, "", screen_loc, maptext_height, maptext_width)

/datum/neural_interface_module/logs/UpdateVision(mob/user)
	cleanup_expired_logs()

	if(!user?.client)
		return

	user.client.screen -= logs_view

	if(!visible)
		return

	var/write = ""
	if(logs.len)
		write += get_log_section()

	logs_view.maptext = write
	user.client.screen += logs_view


// ---------------------------------------------------------------------------
// Log Management - Write messages with categories and formatting
// ---------------------------------------------------------------------------
/datum/neural_interface_module/logs/proc/write_log(text, key="LOG", color="#4ad1fa86", size=12, speed=0)
	LAZYINITLIST(logs)

	// Apply category color if defined
	if(log_categories[key])
		color = log_categories[key]

	// Format log message
	var/plain_text = "\[[key]\] - [text]"

	// Remove oldest logs if at capacity
	if(logs.len >= max_logs)
		var/datum/log_entry/old = logs[1]
		logs.Splice(1, 2)
		QDEL_NULL(old)

	// Create log entry
	var/datum/log_entry/log = new()

	log.plain = plain_text
	log.color = color
	log.char_index = 1
	log.size = size
	log.expiry_time = world.time + 3 SECONDS
	log.font_family = font_family

	// Override speed if category has specific speed
	if(log_speeds[key] && speed == 0)
		log.char_speed = log_speeds[key]

	logs += log

	return TRUE

/datum/neural_interface_module/logs/proc/clear_logs()
	QDEL_LIST(logs)
	logs = list()
	return TRUE

/datum/neural_interface_module/logs/proc/remove_log(index)
	if(index >= 1 && index <= logs.len)
		var/datum/log_entry/removed = logs[index]
		logs.Cut(index, index + 1)
		QDEL_NULL(removed)
		return TRUE
	return FALSE

/datum/neural_interface_module/logs/proc/cleanup_expired_logs()
	var/list/to_remove = list()

	for(var/datum/log_entry/entry in logs)
		if(world.time >= entry.expiry_time)
			to_remove += entry

	for(var/removed in to_remove)
		logs -= removed
		QDEL_NULL(removed)

/datum/neural_interface_module/logs/proc/get_log_section()
	var/write = ""
	write += {"<span style='font-family: \"[font_family]\"; font-size: [font_size]pt; color: [separator_color]; line-height: 0.8; -dm-text-outline: 1px black;'>├─ LOG STREAM</span><br>"}

	for(var/datum/log_entry/log_entry in logs)
		write += {"<span style='font-family: \"[font_family]\"; font-size: [font_size]pt; line-height: 0.8; -dm-text-outline: 1px black;'>└ [log_entry.get_full_line()]</span><br>"}

	return write
