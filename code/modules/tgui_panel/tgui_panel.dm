/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/**
 * tgui_panel datum
 * Hosts tgchat and other nice features.
 */
/datum/tgui_panel
	var/client/client
	var/datum/tgui_window/window
	var/broken = FALSE
	var/initialized_at

/datum/tgui_panel/New(client/client)
	src.client = client
	window = new(client, "browseroutput")
	window.subscribe(src, PROC_REF(on_message))

/datum/tgui_panel/Del()
	window.unsubscribe(src)
	window.close()
	return ..()

/**
 * public
 *
 * TRUE if panel is initialized and ready to receive messages.
 */
/datum/tgui_panel/proc/is_ready()
	return !broken && window.is_ready()

/**
 * public
 *
 * Initializes tgui panel.
 */
/datum/tgui_panel/proc/initialize(force = FALSE)
	set waitfor = FALSE
	// Minimal sleep to defer initialization to after client constructor
	sleep(1)
	initialized_at = world.time
	// Perform a clean initialization
	window.initialize(assets = list(
		get_asset_datum(/datum/asset/simple/tgui_panel),
	))
	window.send_asset(get_asset_datum(/datum/asset/simple/namespaced/fontawesome))
	window.send_asset(get_asset_datum(/datum/asset/simple/namespaced/tgfont))
	window.send_asset(get_asset_datum(/datum/asset/spritesheet/chat))
	// Other setup
	request_telemetry()
	addtimer(CALLBACK(src, PROC_REF(on_initialize_timed_out)), 5 SECONDS)

/**
 * private
 *
 * Called when initialization has timed out.
 */
/datum/tgui_panel/proc/on_initialize_timed_out()
	// Currently does nothing but sending a message to old chat.
	SEND_TEXT(client, "<span class=\"userdanger\">Failed to load fancy chat, click <a href='?src=[REF(src)];reload_tguipanel=1'>HERE</a> to attempt to reload it.</span>")

/**
 * private
 *
 * Callback for handling incoming tgui messages.
 */
/datum/tgui_panel/proc/on_message(type, payload, href_list)
	if(type == "ready")
		broken = FALSE
		// Switch to new UI now that the panel is actually loaded.
		// Respects the user's explicit choice to use legacy chat.
		if(!client.use_legacy_chat)
			winset(client, "legacy_output_selector", "left=output_browser")
		window.send_message("update", list(
			"config" = list(
				"client" = list(
					"ckey" = client.ckey,
					"address" = client.address,
					"computer_id" = client.computer_id,
				),
				"window" = list(
					"fancy" = FALSE,
					"locked" = FALSE,
					"scale" = client.get_window_scaling(),
				),
			),
		))
		var/theme = "default"
		if(client?.prefs?.tgui_panel_theme in list("default", "light", "dark"))
			theme = client.prefs.tgui_panel_theme
		window.send_message("panel/theme", list(
			"theme" = theme,
		))
		// Restore saved panel state (chat tabs, filters, settings)
		if(client?.prefs?.tgui_panel_state && length(client.prefs.tgui_panel_state) > 2)
			window.send_message("panel/state", list(
				"state" = client.prefs.tgui_panel_state,
			))
		return TRUE
	if(type == "panel/state_set")
		// State JSON is sent as a direct href parameter (not inside payload)
		// to avoid double-JSON-encoding that inflates the topic URL size.
		var/state_json = href_list?["panel_state"]
		// Fallback: legacy payload path for backward compatibility
		if(!state_json && islist(payload))
			state_json = payload["state"]
		if(!istext(state_json) || length(state_json) > 16384)
			if(client && istext(state_json))
				window.send_message("panel/state_error", list("reason" = "too_large", "size" = length(state_json)))
			return TRUE
		if(client?.prefs && client.prefs.tgui_panel_state != state_json)
			client.prefs.tgui_panel_state = state_json
			client.prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
		return TRUE
	if(type == "panel/theme_set")
		var/theme
		if(islist(payload))
			theme = payload["theme"]
		if(!istext(theme) && islist(href_list))
			theme = href_list["theme"]
		if(theme in list("default", "light", "dark"))
			if(client?.prefs && client.prefs.tgui_panel_theme != theme)
				client.prefs.tgui_panel_theme = theme
				client.prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
		return TRUE
	if(type == "audio/setAdminMusicVolume")
		client.admin_music_volume = payload["volume"]
		return TRUE
	if(type == "telemetry")
		analyze_telemetry(payload)
		return TRUE

/**
 * public
 *
 * Sends a round restart notification.
 */
/datum/tgui_panel/proc/send_roundrestart()
	window.send_message("roundrestart")
