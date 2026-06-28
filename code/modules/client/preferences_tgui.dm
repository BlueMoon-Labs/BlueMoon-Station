/datum/preferences/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GamePreferences")
		ui.title = "Настройки"
		ui.open()

/datum/preferences/ui_status(mob/user, datum/tgui/ui)
	return UI_INTERACTIVE

/datum/preferences/ui_state(mob/user)
	return GLOB.self_state

/datum/preferences/ui_data(mob/user)
	. = list()
	.["hotkeys"] = hotkeys

	// Sound toggles
	.["sound_lobby"] = !!(toggles & SOUND_LOBBY)
	.["sound_midi"] = !!(toggles & SOUND_MIDI)
	.["sound_instruments"] = !!(toggles & SOUND_INSTRUMENTS)
	.["sound_jukeboxes"] = !!(toggles & SOUND_JUKEBOXES)
	.["sound_personal_jukeboxes"] = !!(toggles & SOUND_PERSONAL_JUKEBOXES)
	.["sound_ambience"] = !!(toggles & SOUND_AMBIENCE)
	.["sound_ship_ambience"] = !!(toggles & SOUND_SHIP_AMBIENCE)
	.["sound_announcements"] = !!(toggles & SOUND_ANNOUNCEMENTS)
	.["sound_bark"] = !!(toggles & SOUND_BARK)
	.["sound_prayers"] = !!(toggles & SOUND_PRAYERS)
	.["sound_adminhelp"] = !!(toggles & SOUND_ADMINHELP)

	// Sound volumes
	.["sound_volume_midi"] = sound_volume_midi
	.["sound_volume_ambience"] = sound_volume_ambience
	.["sound_volume_ship_ambience"] = sound_volume_ship_ambience
	.["sound_volume_announcements"] = sound_volume_announcements
	.["sound_volume_bark"] = sound_volume_bark
	.["sound_volume_prayers"] = sound_volume_prayers
	.["sound_volume_adminhelp"] = sound_volume_adminhelp
	.["sound_volume_instruments"] = sound_volume_instruments
	.["sound_volume_jukeboxes"] = sound_volume_jukeboxes

	// Graphics toggles
	.["parallax"] = parallax
	.["ambient_occlusion"] = ambientocclusion
	.["widescreen"] = widescreenpref
	.["fullscreen"] = fullscreen
	.["fit_viewport"] = auto_fit_viewport
	.["clientfps"] = clientfps
	.["outline_enabled"] = outline_enabled
	.["screentip_pref"] = (screentip_pref == SCREENTIP_PREFERENCE_ENABLED)
	.["screentip_images"] = screentip_images
	.["tgui_fancy"] = tgui_fancy
	.["tgui_lock"] = tgui_lock
	.["chat_on_map"] = chat_on_map
	.["chat_on_map_looc"] = chat_on_map_looc
	.["see_chat_non_mob"] = see_chat_non_mob
	.["see_chat_emotes"] = see_chat_emotes
	.["hud_button_flashes"] = hud_toggle_flash

	// Chat toggles
	.["chat_ooc"] = !!(chat_toggles & CHAT_OOC)
	.["chat_looc"] = !!(chat_toggles & CHAT_LOOC)
	.["chat_ghostears"] = !!(chat_toggles & CHAT_GHOSTEARS)
	.["chat_ghostsight"] = !!(chat_toggles & CHAT_GHOSTSIGHT)
	.["chat_ghostwhisper"] = !!(chat_toggles & CHAT_GHOSTWHISPER)
	.["chat_ghostpda"] = !!(chat_toggles & CHAT_GHOSTPDA)
	.["chat_ghostradio"] = !!(chat_toggles & CHAT_GHOSTRADIO)
	.["chat_dead"] = !!(chat_toggles & CHAT_DEAD)
	.["chat_prayer"] = !!(chat_toggles & CHAT_PRAYER)
	.["chat_radio"] = !!(chat_toggles & CHAT_RADIO)
	.["chat_pullr"] = !!(chat_toggles & CHAT_PULLR)
	.["chat_bankcard"] = !!(chat_toggles & CHAT_BANKCARD)
	.["windowflashing"] = windowflashing
	.["windownoise"] = windownoise

	// Gameplay toggles
	.["no_antag"] = !!(toggles & NO_ANTAG)
	.["midround_antag"] = !!(toggles & MIDROUND_ANTAG)
	.["deathrattle"] = !(toggles & DISABLE_DEATHRATTLE)
	.["arrivalrattle"] = !(toggles & DISABLE_ARRIVALRATTLE)
	.["intent_style"] = !!(toggles & INTENT_STYLE)
	.["action_buttons_hide"] = action_buttons_hide_on_spawn
	.["announce_login"] = !!(toggles & ANNOUNCE_LOGIN)
	.["combohud_lighting"] = !!(toggles & COMBOHUD_LIGHTING)
	.["tg_player_panel"] = !!(toggles & TG_PLAYER_PANEL)

	// Gameplay: victim & combat
	.["be_victim"] = be_victim || BEVICTIM_NO
	.["disable_combat_cursor"] = disable_combat_cursor
	.["disable_combat_mouse_lock"] = disable_combat_mouse_lock

	// Screenshake
	.["screenshake"] = screenshake
	.["damage_screenshake"] = damagescreenshake
	.["recoil_push"] = recoil_screenshake

	// Admin
	.["has_admin"] = !!check_rights_for(user?.client, R_ADMIN)
	if(.["has_admin"])
		.["deadmin"] = deadmin

	// Antag roles
	var/list/antag_roles = list()
	for(var/role in GLOB.special_roles)
		antag_roles += list(list(
			"name" = role,
			"status" = (role in be_special) ? be_special[role] : -1
		))
	.["antag_roles"] = antag_roles

	// Content toggles
	.["verb_consent"] = !!(toggles & VERB_CONSENT)
	.["ranged_verb_pref"] = !!(toggles & RANGED_VERBS_CONSENT)
	.["lewd_verb_sounds"] = !!(toggles & LEWD_VERB_SOUNDS)
	.["arousable"] = arousable
	.["sexknotting"] = sexknotting
	.["genital_examine"] = !!(cit_toggles & GENITAL_EXAMINE)
	.["vore_examine"] = !!(cit_toggles & VORE_EXAMINE)
	.["medihound_sleeper"] = !!(cit_toggles & MEDIHOUND_SLEEPER)
	.["eating_noises"] = !!(cit_toggles & EATING_NOISES)
	.["digestion_noises"] = !!(cit_toggles & DIGESTION_NOISES)
	.["trash_forcefeed"] = !!(cit_toggles & TRASH_FORCEFEED)
	.["forced_fem"] = !!(cit_toggles & FORCED_FEM)
	.["forced_masc"] = !!(cit_toggles & FORCED_MASC)
	.["hypno"] = !!(cit_toggles & HYPNO)
	.["bimbofication"] = !!(cit_toggles & BIMBOFICATION)
	.["breast_enlargement"] = !!(cit_toggles & BREAST_ENLARGEMENT)
	.["penis_enlargement"] = !!(cit_toggles & PENIS_ENLARGEMENT)
	.["butt_enlargement"] = !!(cit_toggles & BUTT_ENLARGEMENT)
	.["belly_inflation"] = !!(cit_toggles & BELLY_INFLATION)
	.["never_hypno"] = !!(cit_toggles & NEVER_HYPNO)
	.["no_aphro"] = !!(cit_toggles & NO_APHRO)
	.["no_ass_slap"] = !!(cit_toggles & NO_ASS_SLAP)
	.["no_auto_wag"] = !!(cit_toggles & NO_AUTO_WAG)
	.["chastity_pref"] = !!(cit_toggles & CHASTITY)
	.["stimulation_pref"] = !!(cit_toggles & STIMULATION)
	.["edging_pref"] = !!(cit_toggles & EDGING)
	.["cum_onto_pref"] = !!(cit_toggles & CUM_ONTO)
	.["sex_jitter"] = !!(cit_toggles & SEX_JITTER)
	.["dance_disco"] = !(cit_toggles & NO_DISCO_DANCE)
	.["gfluid_blacklist"] = gfluid_blacklist

	// Old settings restoration
	.["outline_color"] = outline_color
	.["screentip_color"] = screentip_color
	.["max_chat_length"] = max_chat_length
	.["view_pixelshift"] = view_pixelshift
	.["lighting_blur"] = lighting_blur
	.["hud_toggle_color"] = hud_toggle_color
	.["tgui_input_mode"] = tgui_input_mode
	.["tgui_input_verbs"] = tgui_input_verbs
	.["UI_style"] = UI_style
	.["auto_capitalize_enabled"] = auto_capitalize_enabled
	.["preferred_chaos_level"] = preferred_chaos_level
	.["ghost_form"] = ghost_form
	.["ghost_orbit"] = ghost_orbit
	.["ghost_accs"] = ghost_accs
	.["ghost_others"] = ghost_others
	.["ooccolor"] = ooccolor
	.["aooccolor"] = aooccolor
	.["custom_colors"] = custom_colors

	// Keybindings
	var/list/kb_list = list()
	var/list/user_binds = list()
	var/list/user_modless_binds = list()
	for (var/key in key_bindings)
		for(var/kb_name in key_bindings[key])
			user_binds[kb_name] += list(key)
	for (var/key in modless_key_bindings)
		user_modless_binds[modless_key_bindings[key]] = key

	for (var/name in GLOB.keybindings_by_name)
		var/datum/keybinding/kb = GLOB.keybindings_by_name[name]
		var/independent_key = user_modless_binds[kb.name] || null
		var/list/keys = user_binds[kb.name] || list()
		var/list/default_keys = list()
		var/list/dk = hotkeys ? kb.hotkey_keys : kb.classic_keys
		if(LAZYLEN(dk))
			default_keys = dk.Copy()
		kb_list += list(list(
			"name" = kb.name,
			"full_name" = kb.full_name,
			"description" = kb.description,
			"category" = kb.category,
			"keys" = keys,
			"independent_key" = independent_key,
			"default_keys" = default_keys,
			"can_independent" = !kb.special && !kb.clientside,
		))
	.["keybindings"] = kb_list

	if(kb_capture_kb_name)
		var/datum/keybinding/capture_kb = GLOB.keybindings_by_name[kb_capture_kb_name]
		.["kb_capture"] = list(
			"keybinding" = kb_capture_kb_name,
			"old_key" = kb_capture_old_key,
			"independent" = kb_capture_independent,
			"full_name" = capture_kb?.full_name || kb_capture_kb_name,
			"description" = capture_kb?.description,
			"special" = capture_kb?.special || capture_kb?.clientside,
		)
	else
		.["kb_capture"] = null

/datum/preferences/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	var/mob/user = usr
	if(!user?.client)
		return

	switch(action)
		// Sound toggles
		if("toggle_sound")
			var/flag = params["flag"]
			switch(flag)
				if("sound_lobby")
					toggles ^= SOUND_LOBBY
					if(toggles & SOUND_LOBBY)
						if(isnewplayer(user))
							user.client.playtitlemusic()
					else
						user.stop_sound_channel(CHANNEL_LOBBYMUSIC)
				if("sound_midi")
					toggles ^= SOUND_MIDI
					if(!(toggles & SOUND_MIDI))
						user.stop_sound_channel(CHANNEL_ADMIN)
						user.client?.tgui_panel?.stop_music()
				if("sound_instruments")
					toggles ^= SOUND_INSTRUMENTS
				if("sound_jukeboxes")
					toggles ^= SOUND_JUKEBOXES
				if("sound_personal_jukeboxes")
					toggles ^= SOUND_PERSONAL_JUKEBOXES
				if("sound_ambience")
					toggles ^= SOUND_AMBIENCE
					if(!(toggles & SOUND_AMBIENCE))
						SSambience.remove_ambience_client(user.client)
						user.stop_sound_channel(CHANNEL_AMBIENCE)
				if("sound_ship_ambience")
					toggles ^= SOUND_SHIP_AMBIENCE
					if(!(toggles & SOUND_SHIP_AMBIENCE))
						user.stop_sound_channel(CHANNEL_BUZZ)
						user.client.ambience_playing = 0
				if("sound_announcements")
					toggles ^= SOUND_ANNOUNCEMENTS
				if("sound_bark")
					toggles ^= SOUND_BARK
				if("sound_prayers")
					toggles ^= SOUND_PRAYERS
				if("sound_adminhelp")
					toggles ^= SOUND_ADMINHELP
			save_preferences()

		// Sound volumes
		if("set_volume")
			var/flag = params["flag"]
			var/value = clamp(text2num(params["value"]), 0, 100)
			if(copytext(flag, 1, 14) == "sound_volume_" && (flag in vars))
				vars[flag] = value
				save_preferences()

		// Graphics toggles
		if("toggle_gfx")
			var/flag = params["flag"]
			switch(flag)
				if("ambient_occlusion")
					ambientocclusion = !ambientocclusion
					if(user?.hud_used)
						var/datum/hud/H = user.hud_used
						for(var/plane in list(GAME_PLANE, ABOVE_WALL_PLANE, WALL_PLANE, FLOOR_PLANE, LIGHTING_PLANE, CHAT_PLANE))
							var/atom/movable/screen/plane_master/PM = H.plane_masters["[plane]"]
							PM?.backdrop(user)
				if("widescreen")
					widescreenpref = !widescreenpref
					user.client?.view_size.setDefault(getScreenSize(widescreenpref))
				if("fullscreen")
					fullscreen = !fullscreen
					user.client?.ToggleFullscreen()
				if("fit_viewport")
					auto_fit_viewport = !auto_fit_viewport
					user.client?.fit_viewport()
				if("outline_enabled")
					outline_enabled = !outline_enabled
				if("screentip_pref")
					screentip_pref = (screentip_pref == SCREENTIP_PREFERENCE_ENABLED) ? SCREENTIP_PREFERENCE_DISABLED : SCREENTIP_PREFERENCE_ENABLED
				if("screentip_images")
					screentip_images = !screentip_images
				if("tgui_fancy")
					tgui_fancy = !tgui_fancy
				if("tgui_lock")
					tgui_lock = !tgui_lock
				if("chat_on_map")
					chat_on_map = !chat_on_map
				if("chat_on_map_looc")
					chat_on_map_looc = !chat_on_map_looc
				if("see_chat_non_mob")
					see_chat_non_mob = !see_chat_non_mob
				if("see_chat_emotes")
					see_chat_emotes = !see_chat_emotes
				if("hud_button_flashes")
					hud_toggle_flash = !hud_toggle_flash
			save_preferences()
			tgui_or_html_refresh(user)

		if("set_parallax")
			parallax = clamp(text2num(params["value"]), PARALLAX_DISABLE, PARALLAX_INSANE)
			parent?.parallax_holder?.Reset()
			save_preferences()

		if("set_clientfps")
			clientfps = sanitize_clientfps(text2num(params["value"]))
			save_preferences()

		// Chat toggles
		if("toggle_chat")
			var/flag = params["flag"]
			switch(flag)
				if("chat_ooc")
					chat_toggles ^= CHAT_OOC
				if("chat_looc")
					chat_toggles ^= CHAT_LOOC
				if("chat_ghostears")
					chat_toggles ^= CHAT_GHOSTEARS
				if("chat_ghostsight")
					chat_toggles ^= CHAT_GHOSTSIGHT
				if("chat_ghostwhisper")
					chat_toggles ^= CHAT_GHOSTWHISPER
				if("chat_ghostpda")
					chat_toggles ^= CHAT_GHOSTPDA
				if("chat_ghostradio")
					chat_toggles ^= CHAT_GHOSTRADIO
				if("chat_dead")
					chat_toggles ^= CHAT_DEAD
				if("chat_prayer")
					chat_toggles ^= CHAT_PRAYER
				if("chat_radio")
					chat_toggles ^= CHAT_RADIO
				if("chat_pullr")
					chat_toggles ^= CHAT_PULLR
				if("chat_bankcard")
					chat_toggles ^= CHAT_BANKCARD
				if("windowflashing")
					windowflashing = !windowflashing
				if("windownoise")
					windownoise = !windownoise
			save_preferences()

		// Gameplay toggles
		if("toggle_gameplay")
			var/flag = params["flag"]
			switch(flag)
				if("no_antag")
					toggles ^= NO_ANTAG
				if("midround_antag")
					toggles ^= MIDROUND_ANTAG
				if("deathrattle")
					toggles ^= DISABLE_DEATHRATTLE
				if("arrivalrattle")
					toggles ^= DISABLE_ARRIVALRATTLE
				if("intent_style")
					toggles ^= INTENT_STYLE
				if("action_buttons_hide")
					action_buttons_hide_on_spawn = !action_buttons_hide_on_spawn
				if("announce_login")
					toggles ^= ANNOUNCE_LOGIN
				if("combohud_lighting")
					toggles ^= COMBOHUD_LIGHTING
				if("tg_player_panel")
					toggles ^= TG_PLAYER_PANEL
				if("disable_combat_cursor")
					disable_combat_cursor = !disable_combat_cursor
				if("disable_combat_mouse_lock")
					disable_combat_mouse_lock = !disable_combat_mouse_lock
			save_preferences()

		// Antag role toggles
		if("toggle_antag")
			var/role = params["role"]
			var/value = text2num(params["value"])
			if(!(role in GLOB.special_roles))
				return
			if(value < 0)
				be_special -= role
			else
				be_special += role
				be_special[role] = value
			save_preferences()

		if("toggle_admin")
			var/flag = params["flag"]
			switch(flag)
				if("sound_adminhelp")
					toggles ^= SOUND_ADMINHELP
				if("announce_login")
					toggles ^= ANNOUNCE_LOGIN
				if("combohud_lighting")
					toggles ^= COMBOHUD_LIGHTING
				if("deadmin_play_login")
					deadmin ^= DEADMIN_ONLOGIN
				if("deadmin_play_spawn")
					deadmin ^= DEADMIN_ONSPAWN
				if("deadmin_antagonist")
					deadmin ^= DEADMIN_ANTAGONIST
				if("deadmin_head")
					deadmin ^= DEADMIN_POSITION_HEAD
				if("deadmin_security")
					deadmin ^= DEADMIN_POSITION_SECURITY
				if("deadmin_silicon")
					deadmin ^= DEADMIN_POSITION_SILICON
			save_preferences()

		if("set_be_victim")
			be_victim = params["value"]
			save_preferences()

		if("set_screenshake")
			var/flag = params["flag"]
			var/value = text2num(params["value"])
			switch(flag)
				if("screenshake")
					screenshake = clamp(value, 0, 100)
				if("damage_screenshake")
					damagescreenshake = clamp(value, 0, 2)
				if("recoil_push")
					recoil_screenshake = clamp(value, 0, 100)
			save_preferences()

	// Graphics value setter
		if("set_gfx_val")
			var/flag = params["flag"]
			var/value = params["value"]
			switch(flag)
				if("outline_color")
					outline_color = value
				if("screentip_color")
					screentip_color = value
				if("hud_toggle_color")
					hud_toggle_color = value
				if("max_chat_length")
					max_chat_length = clamp(text2num(value), 0, 512)
				if("lighting_blur")
					lighting_blur = clamp(text2num(value), LIGHTING_BLUR_MIN, LIGHTING_BLUR_MAX)
					if(user?.hud_used)
						var/datum/hud/H = user.hud_used
						for(var/plane in list(LIGHTING_PLANE, GAME_PLANE, ABOVE_WALL_PLANE, WALL_PLANE, FLOOR_PLANE, EMISSIVE_PLANE))
							var/atom/movable/screen/plane_master/PM = H.plane_masters["[plane]"]
							PM?.backdrop(user)
				if("preferred_chaos_level")
					preferred_chaos_level = clamp(text2num(value), 0, 3)
			save_preferences()

		if("toggle_gfx_val")
			var/flag = params["flag"]
			switch(flag)
				if("view_pixelshift")
					view_pixelshift = !view_pixelshift
				if("auto_capitalize_enabled")
					auto_capitalize_enabled = !auto_capitalize_enabled
			save_preferences()

		if("set_ui_pref")
			var/flag = params["flag"]
			var/value = params["value"]
			switch(flag)
				if("tgui_input_mode")
					tgui_input_mode = (value == "TGUI" ? TRUE : FALSE)
				if("tgui_input_verbs")
					tgui_input_verbs = (value == "TGUI" ? TRUE : FALSE)
				if("UI_style")
					UI_style = value
				if("ghost_form")
					ghost_form = value
				if("ghost_orbit")
					ghost_orbit = value
				if("ghost_accs")
					ghost_accs = value
				if("ghost_others")
					ghost_others = value
			save_preferences()

		if("set_ooc_pref")
			var/flag = params["flag"]
			var/value = params["value"]
			switch(flag)
				if("ooccolor")
					ooccolor = value
				if("aooccolor")
					aooccolor = value
				if("custom_colors")
					if(value)
						custom_colors |= CUSTOM_OOC
					else
						custom_colors &= ~CUSTOM_OOC
				if("custom_aooc")
					if(value)
						custom_colors |= CUSTOM_AOOC
					else
						custom_colors &= ~CUSTOM_AOOC
			save_preferences()

	// Content toggles
		if("pref")
			var/pref = params["pref"]
			switch(pref)
				if("verb_consent")
					toggles ^= VERB_CONSENT
				if("ranged_verb_pref")
					toggles ^= RANGED_VERBS_CONSENT
				if("lewd_verb_sounds")
					toggles ^= LEWD_VERB_SOUNDS
				if("arousable")
					arousable = !arousable
				if("sexknotting")
					sexknotting = !sexknotting
				if("genital_examine")
					cit_toggles ^= GENITAL_EXAMINE
				if("vore_examine")
					cit_toggles ^= VORE_EXAMINE
				if("medihound_sleeper")
					cit_toggles ^= MEDIHOUND_SLEEPER
				if("eating_noises")
					cit_toggles ^= EATING_NOISES
				if("digestion_noises")
					cit_toggles ^= DIGESTION_NOISES
				if("trash_forcefeed")
					cit_toggles ^= TRASH_FORCEFEED
				if("forced_fem")
					cit_toggles ^= FORCED_FEM
				if("forced_masc")
					cit_toggles ^= FORCED_MASC
				if("hypno")
					cit_toggles ^= HYPNO
				if("bimbofication")
					cit_toggles ^= BIMBOFICATION
				if("breast_enlargement")
					cit_toggles ^= BREAST_ENLARGEMENT
				if("penis_enlargement")
					cit_toggles ^= PENIS_ENLARGEMENT
				if("butt_enlargement")
					cit_toggles ^= BUTT_ENLARGEMENT
				if("belly_inflation")
					cit_toggles ^= BELLY_INFLATION
				if("never_hypno")
					cit_toggles ^= NEVER_HYPNO
				if("no_aphro")
					cit_toggles ^= NO_APHRO
				if("no_ass_slap")
					cit_toggles ^= NO_ASS_SLAP
				if("no_auto_wag")
					cit_toggles ^= NO_AUTO_WAG
				if("chastity_pref")
					cit_toggles ^= CHASTITY
				if("stimulation_pref")
					cit_toggles ^= STIMULATION
				if("edging_pref")
					cit_toggles ^= EDGING
				if("cum_onto_pref")
					cit_toggles ^= CUM_ONTO
				if("sex_jitter")
					cit_toggles ^= SEX_JITTER
				if("dance_disco")
					cit_toggles ^= NO_DISCO_DANCE
			save_preferences()

		// Keybinding actions
		if("toggle_hotkeys")
			hotkeys = !hotkeys
			user.client.ensure_keys_set(src)
			save_preferences()

		if("keybinding_capture")
			var/datum/keybinding/kb = GLOB.keybindings_by_name[params["keybinding"]]
			if(!kb)
				return
			kb_capture_kb_name = kb.name
			kb_capture_old_key = params["old_key"] || "Unbound"
			kb_capture_independent = text2num(params["independent"])
			return

		if("keybinding_cancel")
			ClearKeybindingCapture()
			return

		if("keybindings_set")
			var/datum/keybinding/kb = GLOB.keybindings_by_name[params["keybinding"]]
			if(!kb)
				ClearKeybindingCapture()
				return
			params["special"] = kb.special || kb.clientside
			if(ApplyKeybindingSet(user, params))
				user.client.ensure_keys_set(src)
				save_preferences()
			ClearKeybindingCapture()
			return

		if("keybinding_reset")
			var/choice = tgalert(user, "Выберите стиль раскладки:", "Сброс клавиш", "Горячие клавиши", "Классика", "Отмена")
			if(choice == "Отмена")
				return
			hotkeys = (choice == "Горячие клавиши")
			key_bindings = hotkeys ? deepCopyList(GLOB.hotkey_keybinding_list_by_key) : deepCopyList(GLOB.classic_keybinding_list_by_key)
			modless_key_bindings = list()
			user.client.ensure_keys_set(src)
			save_preferences()

	. = TRUE

/datum/preferences/proc/tgui_or_html_refresh(mob/user)
	if(!user?.client)
		return
	var/datum/tgui/ui = SStgui.get_open_ui(user, src, "GamePreferences")
	if(ui)
		ui.send_update()
	else
		ShowChoices(user)
