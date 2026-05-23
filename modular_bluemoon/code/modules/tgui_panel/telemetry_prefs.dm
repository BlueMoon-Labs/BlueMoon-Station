#define CONNECTION_TELEMETRY_CACHE_FILE "data/connection_telemetry_cache.json"

/// Machine-local connection history (all ckeys on this computer_id), like browser telemetry storage.
GLOBAL_LIST_INIT(connection_telemetry_by_computer_id, list())

/// Persisted per-ckey backup in player prefs.
/datum/preferences
	var/list/connection_telemetry_history = list()

SUBSYSTEM_DEF(connection_telemetry)
	name = "Connection Telemetry"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_DBCORE - 1
	var/save_queued = FALSE

/datum/controller/subsystem/connection_telemetry/Initialize(start_timeofday)
	load_connection_telemetry_cache()
	return ..()

/datum/controller/subsystem/connection_telemetry/Shutdown()
	save_connection_telemetry_cache()
	return ..()

/datum/controller/subsystem/connection_telemetry/proc/queue_save()
	if(save_queued)
		return
	save_queued = TRUE
	addtimer(CALLBACK(src, PROC_REF(save_connection_telemetry_cache_deferred)), 5 SECONDS)

/datum/controller/subsystem/connection_telemetry/proc/save_connection_telemetry_cache_deferred()
	save_queued = FALSE
	save_connection_telemetry_cache()

/proc/load_connection_telemetry_cache()
	var/json_raw = file2text(CONNECTION_TELEMETRY_CACHE_FILE)
	if(!json_raw)
		return
	var/list/data = json_decode(json_raw)
	if(!islist(data))
		return
	for(var/computer_id in data)
		if(!istext(computer_id))
			continue
		var/list/history = sanitize_connection_telemetry_history(data[computer_id])
		if(length(history))
			GLOB.connection_telemetry_by_computer_id[computer_id] = history

/proc/save_connection_telemetry_cache()
	fdel(CONNECTION_TELEMETRY_CACHE_FILE)
	WRITE_FILE(file(CONNECTION_TELEMETRY_CACHE_FILE), json_encode(GLOB.connection_telemetry_by_computer_id))

/proc/sanitize_connection_telemetry_history(list/raw)
	var/list/sanitized = list()
	if(!islist(raw))
		return sanitized
	for(var/list/row in raw)
		if(!islist(row))
			continue
		var/ckey = row["ckey"]
		var/address = row["address"]
		var/computer_id = row["computer_id"]
		if(!istext(ckey) || !istext(address) || !istext(computer_id))
			continue
		if(!length(ckey) || !length(address) || !length(computer_id))
			continue
		sanitized += list(list(
			"ckey" = copytext(ckey, 1, 65),
			"address" = copytext(address, 1, 46),
			"computer_id" = copytext(computer_id, 1, 33),
		))
		if(length(sanitized) >= TGUI_TELEMETRY_MAX_CONNECTIONS)
			break
	return sanitized

/proc/connection_telemetry_rows_match(list/a, list/b)
	return a["ckey"] == b["ckey"] && a["address"] == b["address"] && a["computer_id"] == b["computer_id"]

/proc/connection_telemetry_history_contains(list/history, list/row)
	for(var/list/existing in history)
		if(connection_telemetry_rows_match(existing, row))
			return TRUE
	return FALSE

/proc/append_connection_telemetry_row(list/history, list/row)
	if(connection_telemetry_history_contains(history, row))
		return FALSE
	history.Insert(1, row)
	if(length(history) > TGUI_TELEMETRY_MAX_CONNECTIONS)
		history.Cut(TGUI_TELEMETRY_MAX_CONNECTIONS + 1)
	return TRUE

/proc/record_global_connection_telemetry(list/row)
	var/computer_id = row["computer_id"]
	if(!computer_id)
		return FALSE
	var/list/history = GLOB.connection_telemetry_by_computer_id[computer_id]
	if(!islist(history))
		history = list()
	if(!append_connection_telemetry_row(history, row))
		return FALSE
	GLOB.connection_telemetry_by_computer_id[computer_id] = history
	if(SSconnection_telemetry)
		SSconnection_telemetry.queue_save()
	return TRUE

/datum/preferences/proc/connection_telemetry_row_from_client(client/C)
	if(!C)
		return null
	return list(
		"ckey" = C.ckey,
		"address" = C.address,
		"computer_id" = C.computer_id,
	)

/datum/preferences/proc/get_connection_telemetry_history()
	var/list/merged = list()
	for(var/list/row in connection_telemetry_history)
		append_connection_telemetry_row(merged, row)
	var/client/C = parent
	if(istype(C))
		var/list/cid_history = GLOB.connection_telemetry_by_computer_id[C.computer_id]
		if(islist(cid_history))
			for(var/list/row in cid_history)
				append_connection_telemetry_row(merged, row)
	return merged

/datum/preferences/proc/record_connection_telemetry(client/C)
	var/list/row = connection_telemetry_row_from_client(C)
	if(!row)
		return
	record_connection_telemetry_row(row)

/datum/preferences/proc/record_connection_telemetry_row(list/row)
	var/list/sanitized = sanitize_connection_telemetry_history(list(row))
	if(!length(sanitized))
		return
	row = sanitized[1]
	var/prefs_changed = append_connection_telemetry_row(connection_telemetry_history, row)
	var/global_changed = record_global_connection_telemetry(row)
	if(prefs_changed)
		save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	else if(global_changed && !prefs_changed)
		// Global cache already queued a save; prefs list was already up to date.
		return

/datum/preferences/proc/merge_connection_telemetry(list/incoming)
	if(!islist(incoming))
		return
	var/prefs_changed = FALSE
	for(var/list/row in incoming)
		if(!islist(row))
			continue
		var/list/sanitized = sanitize_connection_telemetry_history(list(row))
		if(!length(sanitized))
			continue
		var/list/clean = sanitized[1]
		if(append_connection_telemetry_row(connection_telemetry_history, clean))
			prefs_changed = TRUE
		record_global_connection_telemetry(clean)
	if(prefs_changed)
		save_preferences(bypass_cooldown = TRUE, silent = TRUE)
