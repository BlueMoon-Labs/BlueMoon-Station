/// BLUEMOON: defer telemetry until the panel is ready (WebView2 / 516 loads slowly).
/datum/tgui_panel/initialize(force = FALSE)
	set waitfor = FALSE
	sleep(1)
	initialized_at = world.time
	window.initialize(assets = list(
		get_asset_datum(/datum/asset/simple/tgui_panel),
	))
	window.send_asset(get_asset_datum(/datum/asset/simple/namespaced/fontawesome))
	window.send_asset(get_asset_datum(/datum/asset/simple/namespaced/tgfont))
	window.send_asset(get_asset_datum(/datum/asset/spritesheet/chat))
	addtimer(CALLBACK(src, PROC_REF(on_initialize_timed_out)), 5 SECONDS)

/datum/tgui_panel/on_message(type, payload, href_list)
	if(type == "ready")
		var/prevent_default = ..()
		on_panel_ready()
		return prevent_default
	return ..()
