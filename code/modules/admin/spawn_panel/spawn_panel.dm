/datum/spawnpanel
	var/where_target_type = WHERE_FLOOR_BELOW_MOB
	var/selected_atom = null
	var/selected_icon = null // base64 of current atom icon, generated on selection
	var/atom_amount = 1
	var/atom_name = null
	var/atom_desc = null
	var/atom_dir = 2
	var/list/offset
	var/offset_type = OFFSET_RELATIVE
	var/precise_mode = PRECISE_MODE_OFF
	var/mob/owner = null

/datum/spawnpanel/New()
	. = (..())
	owner = usr
	offset = list("X" = 0, "Y" = 0, "Z" = 0)

/datum/spawnpanel/Destroy()
	if(precise_mode != PRECISE_MODE_OFF && owner?.client)
		owner.client.click_intercept = null
		owner.client.mouse_up_icon = null
		owner.client.mouse_down_icon = null
		owner.client.mouse_override_icon = null
		owner.update_mouse_pointer()
	owner = null
	. = ..()

/datum/spawnpanel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SpawnPanel")
		ui.open()

/datum/spawnpanel/ui_close(mob/user)
	. = ..()
	if(precise_mode != PRECISE_MODE_OFF)
		toggle_precise_mode(PRECISE_MODE_OFF, user)

/datum/spawnpanel/ui_state(mob/user)
	return GLOB.admin_state

/datum/spawnpanel/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/spawnpanel),
		get_asset_datum(/datum/asset/json/spawnpanel),
	)

/datum/spawnpanel/ui_data(mob/user)
	return list(
		"selected_object" = selected_atom,
		"selected_icon" = selected_icon,
		"where_target_type" = where_target_type,
		"atom_amount" = atom_amount,
		"atom_name" = atom_name,
		"atom_desc" = atom_desc,
		"atom_dir" = atom_dir,
		"offset" = list(offset["X"], offset["Y"], offset["Z"]),
		"offset_type" = offset_type,
		"precise_mode" = precise_mode,
	)

/datum/spawnpanel/ui_act(action, params, datum/tgui/ui)
	if(..())
		return
	if(!check_rights_for(ui.user.client, R_SPAWN))
		return FALSE

	switch(action)
		if("selected-atom-changed")
			selected_atom = params["newObj"]
			selected_icon = null
			atom_name = null
			atom_desc = null
			if(!selected_atom && precise_mode == PRECISE_MODE_TARGET)
				toggle_precise_mode(PRECISE_MODE_OFF, ui.user)
			if(selected_atom)
				var/path = text2path(selected_atom)
				if(path)
					var/atom_icon = initial(path:icon)
					var/atom_state = initial(path:icon_state)
					if(atom_icon)
						if(isnull(atom_state) || atom_state == "")
							var/list/states = icon_states(atom_icon)
							if(!("" in states) && length(states))
								atom_state = states[1]
						var/icon/I = icon(atom_icon, atom_state, SOUTH, 1)
						selected_icon = "data:image/png;base64,[icon2base64(I)]"
			return TRUE

		if("update-settings")
			if(!isnull(params["where_target_type"]))
				where_target_type = params["where_target_type"]
				if(precise_mode != PRECISE_MODE_OFF && !(where_target_type in list(WHERE_TARGETED_LOCATION, WHERE_TARGETED_LOCATION_POD, WHERE_TARGETED_MOB_HAND, WHERE_TARGETED_MOB_BAG)))
					toggle_precise_mode(PRECISE_MODE_OFF, ui.user)
			if(!isnull(params["atom_amount"]))
				atom_amount = clamp(text2num(params["atom_amount"]) || 1, 1, ADMIN_SPAWN_CAP)
			if(!isnull(params["atom_name"]))
				atom_name = sanitize(params["atom_name"]) || null
			if(!isnull(params["atom_desc"]))
				atom_desc = sanitize(params["atom_desc"]) || null
			if(!isnull(params["atom_dir"]))
				atom_dir = text2num(params["atom_dir"])
			if(!isnull(params["offset"]))
				var/list/off = params["offset"]
				if(length(off) >= 3)
					offset["X"] = text2num(off[1]) || 0
					offset["Y"] = text2num(off[2]) || 0
					offset["Z"] = text2num(off[3]) || 0
			if(!isnull(params["offset_type"]))
				offset_type = params["offset_type"]
			return TRUE

		if("create-atom-action")
			var/use_atom = params["selected_atom"] || selected_atom
			if(!use_atom)
				return FALSE
			if(!isnull(params["where_target_type"]))
				where_target_type = params["where_target_type"]
			if(!isnull(params["atom_amount"]))
				atom_amount = clamp(text2num(params["atom_amount"]) || 1, 1, ADMIN_SPAWN_CAP)
			if(!isnull(params["atom_name"]))
				atom_name = sanitize(params["atom_name"]) || null
			if(!isnull(params["atom_desc"]))
				atom_desc = sanitize(params["atom_desc"]) || null
			if(!isnull(params["atom_dir"]))
				atom_dir = text2num(params["atom_dir"])
			if(!isnull(params["offset"]))
				var/list/off2 = params["offset"]
				if(length(off2) >= 3)
					offset["X"] = text2num(off2[1]) || 0
					offset["Y"] = text2num(off2[2]) || 0
					offset["Z"] = text2num(off2[3]) || 0
			if(!isnull(params["offset_type"]))
				offset_type = params["offset_type"]
			var/list/spawn_params = list(
				"type" = use_atom,
				"amount" = atom_amount,
				"atom_name" = atom_name,
				"atom_desc" = atom_desc,
				"atom_dir" = atom_dir,
				"where" = where_target_type,
				"offsetX" = offset["X"],
				"offsetY" = offset["Y"],
				"offsetZ" = offset["Z"],
				"offset_type" = offset_type,
			)
			spawn_atom(spawn_params, ui.user)
			return TRUE

		if("toggle-precise-mode")
			var/new_mode = params["newPreciseType"] || PRECISE_MODE_OFF
			toggle_precise_mode(new_mode, ui.user)
			return TRUE

	return FALSE

/datum/spawnpanel/proc/toggle_precise_mode(new_mode, mob/user = owner)
	if(!selected_atom && new_mode == PRECISE_MODE_TARGET)
		to_chat(user, span_warning("SpawnPanel: select an atom first."))
		return
	if(!user?.client)
		return
	precise_mode = new_mode
	if(new_mode == PRECISE_MODE_OFF)
		user.client.click_intercept = null
		user.client.mouse_up_icon = null
		user.client.mouse_down_icon = null
		user.client.mouse_override_icon = null
		user.update_mouse_pointer()
	else
		user.client.click_intercept = src
		if(new_mode == PRECISE_MODE_TARGET)
			if(where_target_type == WHERE_TARGETED_LOCATION_POD)
				user.client.mouse_up_icon = 'icons/effects/mouse_pointers/supplypod_target.dmi'
				user.client.mouse_down_icon = 'icons/effects/mouse_pointers/supplypod_down_target.dmi'
			else
				user.client.mouse_up_icon = 'icons/effects/mouse_pointers/supplypod_pickturf.dmi'
				user.client.mouse_down_icon = 'icons/effects/mouse_pointers/supplypod_pickturf_down.dmi'
			user.client.mouse_override_icon = user.client.mouse_up_icon
			user.client.mouse_pointer_icon = user.client.mouse_override_icon
	SStgui.update_uis(src)

/datum/spawnpanel/proc/InterceptClickOn(mob/clicker, params, atom/target)
	if(!check_rights_for(clicker.client, R_SPAWN))
		toggle_precise_mode(PRECISE_MODE_OFF, clicker)
		return TRUE
	switch(precise_mode)
		if(PRECISE_MODE_TARGET)
			var/list/spawn_params = list(
				"type" = selected_atom,
				"amount" = atom_amount,
				"atom_name" = atom_name,
				"atom_desc" = atom_desc,
				"atom_dir" = atom_dir,
				"where" = where_target_type,
				"offsetX" = 0,
				"offsetY" = 0,
				"offsetZ" = 0,
				"offset_type" = OFFSET_RELATIVE,
			)
			if(where_target_type == WHERE_TARGETED_MOB_HAND || where_target_type == WHERE_TARGETED_MOB_BAG)
				spawn_params["targetMob"] = ismob(target) ? target : null
			else
				spawn_params["targetTurf"] = get_turf(target)
			spawn_atom(spawn_params, clicker)
		if(PRECISE_MODE_COPY)
			selected_atom = "[target.type]"
			toggle_precise_mode(PRECISE_MODE_OFF, clicker)
			SStgui.update_uis(src)
	return TRUE
