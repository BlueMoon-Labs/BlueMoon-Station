// Proc for sending Suspicious Logins to Admin Chat
/proc/suspect_message_to_admin_chat(msg)
	message_admins(msg)
	var/suspect_chat_channel_tag = CONFIG_GET(string/chat_suspect_login)
	if (suspect_chat_channel_tag)
		var/tgs_msg = new /datum/tgs_message_content(msg)
		send2chat(tgs_msg, suspect_chat_channel_tag)

/datum/tgui_panel
	var/telemetry_alert_sent = FALSE

/datum/tgui_panel/proc/on_panel_ready()
	if(!client)
		return
	if(client.prefs)
		client.prefs.record_connection_telemetry(client)
		check_connection_telemetry_history(client.prefs.get_connection_telemetry_history())
	request_telemetry()

/datum/tgui_panel/proc/report_banned_connection_match(list/found)
	if(!found || telemetry_alert_sent || QDELETED(client))
		return
	if(client?.holder?.check_for_rights(R_PERMISSIONS))
		return
	telemetry_alert_sent = TRUE
	var/msg = "[key_name(client)] has a banned account in connection history! https://iphub.info/?ip=[client.address] (Actual: [client.ckey], [client.address], [client.computer_id] ) (Matched: [found["ckey"]], [found["address"]], [found["computer_id"]])"
	suspect_message_to_admin_chat(msg)
	log_admin_private(msg)
	log_suspicious_login(msg, access_log_mirror = FALSE)

/datum/tgui_panel/proc/check_connection_telemetry_history(list/connections)
	if(!length(connections) || telemetry_alert_sent)
		return null
	var/list/found
	for(var/list/row in connections)
		if(QDELETED(client))
			return null
		if(!row || row.len < 3 || (!row["ckey"] || !row["address"] || !row["computer_id"]))
			continue
		if(world.IsBanned(row["ckey"], row["address"], row["computer_id"], real_bans_only = TRUE))
			found = row
			break
		CHECK_TICK
	report_banned_connection_match(found)
	return found

/datum/tgui_panel/request_telemetry()
	telemetry_requested_at = world.time
	telemetry_analyzed_at = null
	telemetry_alert_sent = FALSE
	window.send_message("telemetry/request", list(
		"limits" = list(
			"connections" = TGUI_TELEMETRY_MAX_CONNECTIONS,
		),
	))

/datum/tgui_panel/analyze_telemetry(payload)
	if(telemetry_alert_sent)
		return
	if(world.time > telemetry_requested_at + TGUI_TELEMETRY_RESPONSE_WINDOW)
		return
	if(telemetry_analyzed_at)
		return
	telemetry_analyzed_at = world.time
	var/list/incoming = list()
	if(payload && islist(payload["connections"]))
		incoming = payload["connections"]
	if(length(incoming) > TGUI_TELEMETRY_MAX_CONNECTIONS)
		message_admins("[key_name(client)] was kicked for sending a huge telemetry payload")
		qdel(client)
		return
	if(client?.prefs)
		client.prefs.merge_connection_telemetry(incoming)
		check_connection_telemetry_history(client.prefs.get_connection_telemetry_history())
