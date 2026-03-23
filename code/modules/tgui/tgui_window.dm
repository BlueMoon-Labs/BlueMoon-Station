/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/datum/tgui_window
	var/id
	var/client/client
	var/pooled
	var/pool_index
	var/is_browser = FALSE
	var/status = TGUI_WINDOW_CLOSED
	var/locked = FALSE
	var/visible = FALSE
	var/datum/tgui/locked_by
	var/datum/subscriber_object
	var/subscriber_delegate
	var/fatally_errored = FALSE
	var/message_queue
	var/sent_assets = list()
	// Vars passed to initialize proc (and saved for later)
	var/initial_fancy
	var/initial_assets
	var/initial_inline_html
	var/initial_inline_js
	var/initial_inline_css

	var/list/oversized_payloads = list()

/**
 * public
 *
 * Create a new tgui window.
 *
 * required client /client
 * required id string A unique window identifier.
 */
/datum/tgui_window/New(client/client, id, pooled = FALSE)
	src.id = id
	src.client = client
	src.client.tgui_windows[id] = src
	src.pooled = pooled
	if(pooled)
		src.pool_index = TGUI_WINDOW_INDEX(id)

/**
 * public
 *
 * Initializes the window with a fresh page. Puts window into the "loading"
 * state. You can begin sending messages right after initializing. Messages
 * will be put into the queue until the window finishes loading.
 *
 * optional inline_assets list List of assets to inline into the html.
 * optional inline_html string Custom HTML to inject.
 * optional fancy bool If TRUE, will hide the window titlebar.
 */
/datum/tgui_window/proc/initialize(
		fancy = FALSE,
		assets = list(),
		inline_html = "",
		inline_js = "",
		inline_css = "")
	if(CONFIG_GET(flag/emergency_tgui_logging))
		log_tgui(client, "[id]/initialize ([src])")
	if(!client)
		return
	src.initial_fancy = fancy
	src.initial_assets = assets
	src.initial_inline_html = inline_html
	src.initial_inline_js = inline_js
	src.initial_inline_css = inline_css
	status = TGUI_WINDOW_LOADING
	fatally_errored = FALSE
	// Build window options
	var/options = "file=[id].html;can_minimize=0;auto_format=0;"
	// Pooled tgui windows are revealed by frontend after geometry is applied.
	// Keep them hidden at browse() time to avoid a first-frame flash.
	if(pooled)
		options += "is-visible=0;size=400x600;"
	// Remove titlebar and resize handles for a fancy window
	if(fancy)
		options += "titlebar=0;can_resize=0;"
	else
		options += "titlebar=1;can_resize=1;"
	// Generate page html
	var/html = SStgui.basehtml
	html = replacetextEx(html, "\[tgui:windowId]", id)
	// Inject inline assets
	var/inline_assets_str = ""
	var/first_js_url = null
	for(var/datum/asset/asset in assets)
		var/mappings = asset.get_url_mappings()
		for(var/name in mappings)
			var/url = mappings[name]
			// Not encoding since asset strings are considered safe
			if(copytext(name, -4) == ".css")
				inline_assets_str += "Byond.loadCss('[url]', true);\n"
			else if(copytext(name, -3) == ".js")
				inline_assets_str += "Byond.loadJs('[url]', true);\n"
				if(isnull(first_js_url))
					first_js_url = url
		asset.send(client)
	var/assets_placeholder_before = !!findtext(html, "<!-- tgui:assets -->")
	var/assets_placeholder_before_lf = !!findtext(html, "<!-- tgui:assets -->\n")
	var/assets_placeholder_before_crlf = FALSE
	if(findtext(html, "<!-- tgui:assets -->[ascii2text(13)]\n"))
		assets_placeholder_before_crlf = TRUE
	if(length(inline_assets_str))
		inline_assets_str = "<script>\n" + inline_assets_str + "</script>\n"
	// 516 migration: handle either LF or CRLF template line endings.
	html = replacetextEx(html, "<!-- tgui:assets -->\n", inline_assets_str)
	html = replacetextEx(html, "<!-- tgui:assets -->", inline_assets_str)
	var/assets_placeholder_after = !!findtext(html, "<!-- tgui:assets -->")
	var/first_js_url_display = first_js_url || "<none>"
	if(CONFIG_GET(flag/emergency_tgui_logging))
		log_tgui(client,
			"[id]/initialize assets_count=[length(assets)] inline_assets_chars=[length(inline_assets_str)] first_js_url=[first_js_url_display] placeholder_before=[assets_placeholder_before] lf=[assets_placeholder_before_lf] crlf=[assets_placeholder_before_crlf] placeholder_after=[assets_placeholder_after]",
			window = src)
	// Inject inline HTML
	if (inline_html)
		html = replacetextEx(html, "<!-- tgui:inline-html -->", inline_html)
		html = replacetextEx(html, "<!-- tgui:html -->", inline_html)
	// Inject inline JS
	if (inline_js)
		inline_js = "<script>\n[inline_js]\n</script>"
		html = replacetextEx(html, "<!-- tgui:inline-js -->", inline_js)
		html = replacetextEx(html, "<!-- tgui:js -->", inline_js)
	// Inject inline CSS
	if (inline_css)
		inline_css = "<style>\n[inline_css]\n</style>"
		html = replacetextEx(html, "<!-- tgui:inline-css -->", inline_css)
		html = replacetextEx(html, "<!-- tgui:css -->", inline_css)
	// Open the window
	client << browse(html, "window=[id];[options]")
	// BYOND 516 can occasionally present an initial frame despite browse options.
	// Force pooled windows hidden immediately; frontend will reveal when ready.
	if(pooled && istype(client))
		winset(client, id, "is-visible=0")
	// Detect whether the control is a browser
	var/win_type = winexists(client, id)
	is_browser = win_type == "BROWSER"
	if(CONFIG_GET(flag/emergency_tgui_logging))
		var/primary_target = get_primary_output_target()
		var/secondary_target = get_secondary_output_target()
		var/mirror_output = CONFIG_GET(flag/emergency_tgui_mirror_output)
		log_tgui(client,
			"[id]/initialize winexists=[win_type], is_browser=[is_browser], primary_target=[primary_target], secondary_target=[secondary_target], mirror_output=[mirror_output]",
			window = src)
	// Instruct the client to signal UI when the window is closed.
	if(!is_browser && istype(client)) // BLUEMOON EDIT - sanity check
		winset(client, id, "on-close=\"uiclose [id]\"")

/datum/tgui_window/proc/get_primary_output_target()
	return is_browser ? "[id]:update" : "[id].browser:update"

/datum/tgui_window/proc/get_secondary_output_target()
	return is_browser ? "[id].browser:update" : "[id]:update"

/datum/tgui_window/proc/get_output_targets()
	var/list/targets = list(get_primary_output_target())
	// Opt-in diagnostics only: mirror updates to the alternate output channel.
	if(CONFIG_GET(flag/emergency_tgui_mirror_output))
		targets += get_secondary_output_target()
	return targets

/datum/tgui_window/proc/send_output_message(message)
	if(!client)
		return
	for(var/target in get_output_targets())
		client << output(message, target)

/**
 * public
 *
 * Checks if the window is ready to receive data.
 *
 * return bool
 */
/datum/tgui_window/proc/is_ready()
	return status == TGUI_WINDOW_READY

/**
 * public
 *
 * Checks if the window can be sanely suspended.
 *
 * return bool
 */
/datum/tgui_window/proc/can_be_suspended()
	return !fatally_errored \
		&& pooled \
		&& pool_index > 0 \
		&& pool_index <= TGUI_WINDOW_SOFT_LIMIT \
		&& status == TGUI_WINDOW_READY

/**
 * public
 *
 * Acquire the window lock. Pool will not be able to provide this window
 * to other UIs for the duration of the lock.
 *
 * Can be given an optional tgui datum, which will be automatically
 * subscribed to incoming messages via the on_message proc.
 *
 * optional ui /datum/tgui
 */
/datum/tgui_window/proc/acquire_lock(datum/tgui/ui)
	locked = TRUE
	locked_by = ui

/**
 * public
 *
 * Release the window lock.
 */
/datum/tgui_window/proc/release_lock()
	// Clean up assets sent by tgui datum which requested the lock
	if(locked)
		sent_assets = list()
	locked = FALSE
	locked_by = null

/**
 * public
 *
 * Subscribes the datum to consume window messages on a specified proc.
 *
 * Note, that this supports only one subscriber, because code for that
 * is simpler and therefore faster. If necessary, this can be rewritten
 * to support multiple subscribers.
 */
/datum/tgui_window/proc/subscribe(datum/object, delegate)
	subscriber_object = object
	subscriber_delegate = delegate

/**
 * public
 *
 * Unsubscribes the datum. Do not forget to call this when cleaning up.
 */
/datum/tgui_window/proc/unsubscribe(datum/object)
	subscriber_object = null
	subscriber_delegate = null

/**
 * public
 *
 * Close the UI.
 *
 * optional can_be_suspended bool
 */
/datum/tgui_window/proc/close(can_be_suspended = TRUE, logout = FALSE)
	if(!client)
		return
	if(can_be_suspended && can_be_suspended())
		#ifdef TGUI_DEBUGGING
			log_tgui(client, "[id]/close: suspending")
		#endif
		visible = FALSE
		status = TGUI_WINDOW_READY
		send_message("suspend")
		// You would think that BYOND would null out client or make it stop passing istypes or, y'know, ANYTHING during
		// logout, but nope! It appears to be perfectly valid to call winset by every means we can measure in Logout,
		// and yet it causes a bad client runtime. To avoid that happening, we just have to know if we're in Logout or
		// not.
		if(!logout && client && !isnewplayer(client.mob)) // BLUEMOON EDIT - для new_player в лобби не сбрасываем фокус, иначе bm_lobby_browser перестаёт работать
			winset(client, null, "mapwindow.map.focus=true")
		return
	if(CONFIG_GET(flag/emergency_tgui_logging))
		log_tgui(client, "[id]/close")
	release_lock()
	visible = FALSE
	status = TGUI_WINDOW_CLOSED
	message_queue = null
	// Do not close the window to give user some time
	// to read the error message.
	if(!fatally_errored)
		client << browse(null, "window=[id]")
		if(!logout && istype(client) && !isnewplayer(client.mob)) // BLUEMOON EDIT - sanity check + не сбрасываем фокус для new_player в лобби
			winset(client, null, "mapwindow.map.focus=true")

/**
 * public
 *
 * Sends a message to tgui window.
 *
 * required type string Message type
 * required payload list Message payload
 * optional force bool Send regardless of the ready status.
 */
/datum/tgui_window/proc/send_message(type, payload, force)
	if(!client)
		return
	var/message = TGUI_CREATE_MESSAGE(type, payload)
	// Place into queue if window is still loading
	if(!force && status != TGUI_WINDOW_READY)
		if(!message_queue)
			message_queue = list()
		message_queue += list(message)
		return
	send_output_message(message)

/**
 * public
 *
 * Sends a raw payload to tgui window.
 *
 * required message string JSON+urlencoded blob to send.
 * optional force bool Send regardless of the ready status.
 */
/datum/tgui_window/proc/send_raw_message(message, force)
	if(!client)
		return
	// Place into queue if window is still loading
	if(!force && status != TGUI_WINDOW_READY)
		if(!message_queue)
			message_queue = list()
		message_queue += list(message)
		return
	send_output_message(message)

/**
 * public
 *
 * Makes an asset available to use in tgui.
 *
 * required asset datum/asset
 *
 * return bool - TRUE if any assets had to be sent to the client
 */
/datum/tgui_window/proc/send_asset(datum/asset/asset)
	if(!client || !asset)
		return
	sent_assets |= list(asset)
	. = asset.send(client)
	if(istype(asset, /datum/asset/spritesheet))
		var/datum/asset/spritesheet/spritesheet = asset
		send_message("asset/stylesheet", spritesheet.css_filename())
	send_raw_message(asset.get_serialized_url_mappings())

/**
 * private
 *
 * Sends queued messages if the queue wasn't empty.
 */
/datum/tgui_window/proc/flush_message_queue()
	if(!client || !message_queue)
		return
	var/queue_len = length(message_queue)
	if(CONFIG_GET(flag/emergency_tgui_logging))
		log_tgui(client,
			"[id]/flush_message_queue queue_len=[queue_len], status=[status]",
			window = src)
	for(var/message in message_queue)
		send_output_message(message)
	message_queue = null

/**
 * private
 *
 * Callback for handling incoming tgui messages.
 */
/datum/tgui_window/proc/on_message(type, payload, href_list)
	var/log_handshake = CONFIG_GET(flag/emergency_tgui_logging) \
		&& (type == "ready" || type == "ping" || type == "pingReply" || type == "log")
	if(log_handshake)
		log_tgui(client,
			"[id]/on_message type=[type], status_before=[status], queue_len=[length(message_queue)]",
			window = src)
	// Status can be READY if user has refreshed the window.
	if(type == "ready" && status == TGUI_WINDOW_READY)
		// Resend the assets
		for(var/asset in sent_assets)
			send_asset(asset)
	// Mark this window as fatally errored which prevents it from
	// being suspended.
	if(type == "log" && href_list["fatal"])
		fatally_errored = TRUE
	// Mark window as ready since we received this message from somewhere
	if(status != TGUI_WINDOW_READY)
		status = TGUI_WINDOW_READY
		flush_message_queue()
	// Pass message to UI that requested the lock
	if(locked && locked_by)
		var/prevent_default = locked_by.on_message(type, payload, href_list)
		if(prevent_default)
			return
	// Pass message to the subscriber
	else if(subscriber_object)
		var/prevent_default = call(
			subscriber_object,
			subscriber_delegate)(type, payload, href_list)
		if(prevent_default)
			return
	// If not locked, handle these message types
	switch(type)
		if("ping")
			send_message("pingReply", payload)
		if("visible")
			visible = TRUE
			SEND_SIGNAL(src, COMSIG_TGUI_WINDOW_VISIBLE, client)
		if("suspend")
			close(can_be_suspended = TRUE)
		if("close")
			close(can_be_suspended = FALSE)
		if("openLink")
			client << link(href_list["url"])
		if("cacheReloaded")
			// Reinitialize
			initialize(
				fancy = initial_fancy,
				assets = initial_assets,
				inline_html = initial_inline_html,
				inline_js = initial_inline_js,
				inline_css = initial_inline_css)
			// Resend the assets
			for(var/asset in sent_assets)
				send_asset(asset)
		if("oversizedPayloadRequest")
			var/payload_id = payload["id"]
			var/chunk_count = payload["chunkCount"]
			var/permit_payload = chunk_count <= CONFIG_GET(number/tgui_max_chunk_count)
			if(permit_payload)
				permit_payload = create_oversized_payload(payload_id, payload["type"], chunk_count)
			send_message("oversizePayloadResponse", list("allow" = permit_payload, "id" = payload_id))
		if("payloadChunk")
			var/payload_id = payload["id"]
			if(append_payload_chunk(payload_id, payload["chunk"]))
				send_message("acknowlegePayloadChunk", list("id" = payload_id))
			else
				send_message("payloadDropped", list("id" = payload_id))
	if(log_handshake)
		log_tgui(client,
			"[id]/on_message done type=[type], status_after=[status], queue_len=[length(message_queue)], fatally_errored=[fatally_errored]",
			window = src)

/datum/tgui_window/proc/create_oversized_payload(payload_id, message_type, chunk_count)
	// Limit concurrent in-flight payloads to prevent memory exhaustion
	if(length(oversized_payloads) >= 3)
		return FALSE
	if(oversized_payloads[payload_id])
		stack_trace("Attempted to create oversized tgui payload with duplicate ID.")
		return FALSE
	// Do NOT use TIMER_UNIQUE|TIMER_OVERRIDE: each new CALLBACK() has a different hash,
	// so those flags would not deduplicate timers — they would just accumulate.
	// Store the timer ID explicitly and use deltimer() before each reset.
	var/timer_id = addtimer(CALLBACK(src, PROC_REF(remove_oversized_payload), payload_id), 30 SECONDS, TIMER_STOPPABLE)
	oversized_payloads[payload_id] = list(
		"type" = message_type,
		"count" = chunk_count,
		"chunks" = list(),
		"timer" = timer_id,
	)
	return TRUE

/datum/tgui_window/proc/append_payload_chunk(payload_id, chunk)
	var/list/oversized_payload = oversized_payloads[payload_id]
	if(!oversized_payload)
		return FALSE // Payload was timed out or never existed — signal caller
	var/list/chunks = oversized_payload["chunks"]
	chunks += chunk
	if(length(chunks) >= oversized_payload["count"])
		deltimer(oversized_payload["timer"])
		var/message_type = oversized_payload["type"]
		var/final_payload = chunks.Join("")
		remove_oversized_payload(payload_id)
		on_message(message_type, json_decode(final_payload), list("type" = message_type, "payload" = final_payload, "tgui" = TRUE, "window_id" = id))
	else
		// Explicit deltimer + new addtimer to correctly reset the deadline
		deltimer(oversized_payload["timer"])
		oversized_payload["timer"] = addtimer(CALLBACK(src, PROC_REF(remove_oversized_payload), payload_id), 30 SECONDS, TIMER_STOPPABLE)
	return TRUE

/datum/tgui_window/proc/remove_oversized_payload(payload_id)
	oversized_payloads -= payload_id
