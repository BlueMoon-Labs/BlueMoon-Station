/datum/loadout_color_handler
	var/name = "Loadout Color Editor"
	var/mob/user
	var/datum/preferences/prefs
	var/gear_name
	var/loadout_slot
	var/list/user_gear
	var/datum/gear/gear

	var/active_mode = COLORMATE_HSV
	var/activecolor = "#FFFFFF"
	var/list/color_matrix_last = list(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
	var/build_hue = 0
	var/build_sat = 1
	var/build_val = 1

/datum/loadout_color_handler/Destroy()
	if(prefs)
		prefs.loadout_color_handler = null
	prefs = null
	user = null
	user_gear = null
	gear = null
	return ..()

/datum/loadout_color_handler/proc/open(mob/target)
	ui_interact(target)

/datum/loadout_color_handler/ui_status(mob/user)
	return UI_INTERACTIVE

/datum/loadout_color_handler/ui_interact(mob/target, datum/tgui/ui)
	ui = SStgui.try_update_ui(target, src, ui)
	if(!ui)
		ui = new(target, src, "LoadoutColor", "[gear_name] - [name]")
		ui.open()

/datum/loadout_color_handler/proc/get_preview_base64()
	if(!gear?.path)
		return gear?.base64icon

	var/init_icon = gear.item_icon ? gear.item_icon : initial(gear.path.icon)
	var/init_icon_state = gear.item_icon_state ? gear.item_icon_state : initial(gear.path.icon_state)

	if(!init_icon || !init_icon_state)
		return gear?.base64icon

	var/icon/preview
	try
		preview = icon(init_icon, init_icon_state, SOUTH, 1, FALSE)
	catch
		return gear?.base64icon

	switch(active_mode)
		if(COLORMATE_TINT)
			var/r = hex2num(copytext(activecolor, 2, 4)) / 255
			var/g = hex2num(copytext(activecolor, 4, 6)) / 255
			var/b = hex2num(copytext(activecolor, 6, 8)) / 255
			preview.MapColors(r, 0, 0, 0, g, 0, 0, 0, b, 0, 0, 0)
		if(COLORMATE_HSV)
			var/list/cm = color_matrix_hsv(build_hue, build_sat, build_val)
			preview.MapColors(cm[1], cm[2], cm[3], cm[4], cm[5], cm[6], cm[7], cm[8], cm[9], cm[10], cm[11], cm[12])
		if(COLORMATE_MATRIX)
			preview.MapColors(
				color_matrix_last[1], color_matrix_last[2], color_matrix_last[3],
				color_matrix_last[4], color_matrix_last[5], color_matrix_last[6],
				color_matrix_last[7], color_matrix_last[8], color_matrix_last[9],
				color_matrix_last[10], color_matrix_last[11], color_matrix_last[12]
			)

	return icon2base64(preview)

/datum/loadout_color_handler/ui_data(mob/target)
	. = list()
	.["activemode"] = active_mode
	.["gear_name"] = gear_name
	.["sprite"] = gear?.base64icon
	.["preview"] = get_preview_base64()
	.["matrixcolors"] = list(
		"rr" = color_matrix_last[1],
		"rg" = color_matrix_last[2],
		"rb" = color_matrix_last[3],
		"gr" = color_matrix_last[4],
		"gg" = color_matrix_last[5],
		"gb" = color_matrix_last[6],
		"br" = color_matrix_last[7],
		"bg" = color_matrix_last[8],
		"bb" = color_matrix_last[9],
		"cr" = color_matrix_last[10],
		"cg" = color_matrix_last[11],
		"cb" = color_matrix_last[12]
	)
	.["buildhue"] = build_hue
	.["buildsat"] = build_sat
	.["buildval"] = build_val

	.["presets_tint"] = null
	.["presets_hsv"] = null
	.["presets_matrix"] = null

	if(!prefs || !gear)
		return

	var/t = gear.type
	.["presets_tint"] = assoc_to_keys(prefs.color_presets_tint[t] || null)
	.["presets_hsv"] = assoc_to_keys(prefs.color_presets_hsv[t] || null)
	.["presets_matrix"] = assoc_to_keys(prefs.color_presets_matrix[t] || null)

/datum/loadout_color_handler/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("switch_modes")
			active_mode = text2num(params["mode"])
			return TRUE
		if("choose_color")
			var/chosen_color = input(usr, "Choose a color: ", "Loadout Color", activecolor) as color|null
			if(chosen_color)
				activecolor = chosen_color
			return TRUE
		if("set_matrix_color")
			color_matrix_last[params["color"]] = params["value"]
			return TRUE
		if("set_hue")
			build_hue = clamp(text2num(params["buildhue"]), 0, 360)
			return TRUE
		if("set_sat")
			build_sat = clamp(text2num(params["buildsat"]), -10, 10)
			return TRUE
		if("set_val")
			build_val = clamp(text2num(params["buildval"]), -10, 10)
			return TRUE
		if("paint")
			do_paint()
			prefs?.save_preferences(silent = TRUE)
			prefs?.ShowChoices(usr)
			SStgui.close_uis(src)
			return TRUE
		if("clear")
			if(length(user_gear[LOADOUT_COLOR]))
				user_gear[LOADOUT_COLOR][1] = "#FFFFFF"
			return TRUE
		if("cancel")
			SStgui.close_uis(src)
			return TRUE
		if("preset_select", "preset_save", "preset_delete")
			if(!prefs || !gear)
				return

			var/preset_name = strip_control_chars(params["name"])
			var/presets_field
			var/list/presets

			switch(active_mode)
				if(COLORMATE_TINT)
					presets_field = "color_presets_tint"
					presets = prefs.color_presets_tint[gear.type]
				if(COLORMATE_HSV)
					presets_field = "color_presets_hsv"
					presets = prefs.color_presets_hsv[gear.type]
				if(COLORMATE_MATRIX)
					presets_field = "color_presets_matrix"
					presets = prefs.color_presets_matrix[gear.type]
				else
					return

			switch(action)
				if("preset_select")
					if(!presets || !preset_name)
						return
					var/list/value = presets[preset_name]
					switch(active_mode)
						if(COLORMATE_TINT)
							if(!istext(value))
								return
							activecolor = value
						if(COLORMATE_HSV)
							build_hue = value["hue"]
							build_sat = value["sat"]
							build_val = value["val"]
						if(COLORMATE_MATRIX)
							color_matrix_last = value.Copy()

				if("preset_save")
					if(!presets)
						prefs.vars[presets_field][gear.type] = list()
						presets = prefs.vars[presets_field][gear.type]

					if(!preset_name || (presets[preset_name] && tgui_alert(usr, "Preset already exists, update?", "Save Preset", list("Create new", "Update")) == "Create new"))
						var/const/max_length_name = 40
						preset_name = tgui_input_text(usr, "Enter name ([max_length_name] chars)", "Save Preset", max_length = max_length_name, multiline = FALSE, encode = TRUE)
					if(!preset_name)
						return

					switch(active_mode)
						if(COLORMATE_TINT)
							presets[preset_name] = activecolor
						if(COLORMATE_HSV)
							presets[preset_name] = list("hue" = build_hue, "sat" = build_sat, "val" = build_val)
						if(COLORMATE_MATRIX)
							presets[preset_name] = color_matrix_last.Copy()

					prefs.save_preferences(silent = TRUE)

				if("preset_delete")
					if(!presets || !preset_name)
						return
					presets -= preset_name
					prefs.save_preferences(silent = TRUE)

			return TRUE

/datum/loadout_color_handler/proc/do_paint()
	if(!user_gear)
		return
	if(!length(user_gear[LOADOUT_COLOR]))
		user_gear[LOADOUT_COLOR] = list("#FFFFFF")

	switch(active_mode)
		if(COLORMATE_TINT)
			user_gear[LOADOUT_COLOR][1] = activecolor
			user_gear -= LOADOUT_COLOR_HSV_DATA
		if(COLORMATE_MATRIX)
			user_gear[LOADOUT_COLOR][1] = rgb_construct_color_matrix(
				text2num(color_matrix_last[1]),
				text2num(color_matrix_last[2]),
				text2num(color_matrix_last[3]),
				text2num(color_matrix_last[4]),
				text2num(color_matrix_last[5]),
				text2num(color_matrix_last[6]),
				text2num(color_matrix_last[7]),
				text2num(color_matrix_last[8]),
				text2num(color_matrix_last[9]),
				text2num(color_matrix_last[10]),
				text2num(color_matrix_last[11]),
				text2num(color_matrix_last[12])
			)
			user_gear -= LOADOUT_COLOR_HSV_DATA
		if(COLORMATE_HSV)
			var/list/cm = color_matrix_hsv(build_hue, build_sat, build_val)
			user_gear[LOADOUT_COLOR][1] = cm
			user_gear[LOADOUT_COLOR_HSV_DATA] = list(build_hue, build_sat, build_val)

	user_gear[LOADOUT_COLOR_MODE] = active_mode

/datum/loadout_color_handler/ui_close(mob/target)
	. = ..()
	qdel(src)
