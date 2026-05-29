GLOBAL_LIST_EMPTY(spawnpanel_icon_map) // "[typepath]" → spritesheet imgid string

/datum/asset/spritesheet/spawnpanel
	name = "spawnpanel"

/datum/asset/spritesheet/spawnpanel/ModifyInserted(icon/pre_asset)
	if(pre_asset.Width() != 32 || pre_asset.Height() != 32)
		pre_asset.Scale(32, 32)
	return pre_asset

/datum/asset/spritesheet/spawnpanel/proc/resolve_icon_state(icon_file, icon_state)
	var/list/states = icon_states(icon_file)
	if(!length(states))
		return null
	if(!isnull(icon_state) && (icon_state in states))
		return icon_state
	if("" in states)
		return ""
	return states[1]

/datum/asset/spritesheet/spawnpanel/register()
	var/list/icon_dedup = list()
	var/list/states_cache = list()
	var/counter = 0

	for(var/atom_type in typesof(/obj))
		if(atom_type == /obj)
			continue
		var/ifile = initial(atom_type:icon)
		if(!ifile)
			continue
		if(!(ifile in states_cache))
			states_cache[ifile] = icon_states(ifile)
		var/list/fstates = states_cache[ifile]
		if(!length(fstates))
			continue
		var/istate = initial(atom_type:icon_state)
		if(isnull(istate) || !(istate in fstates))
			istate = ("" in fstates) ? "" : fstates[1]
		var/cache_key = "[ifile]|[istate]"
		if(!(cache_key in icon_dedup))
			var/icon/I = icon(ifile, istate, SOUTH, 1)
			if(!I || !length(icon_states(I)))
				continue
			var/imgid = "sp[counter]"
			counter++
			Insert(imgid, I)
			icon_dedup[cache_key] = imgid
		GLOB.spawnpanel_icon_map["[atom_type]"] = icon_dedup[cache_key]

	for(var/turf_type in typesof(/turf))
		if(turf_type == /turf)
			continue
		var/ifile2 = initial(turf_type:icon)
		if(!ifile2)
			continue
		if(!(ifile2 in states_cache))
			states_cache[ifile2] = icon_states(ifile2)
		var/list/fstates2 = states_cache[ifile2]
		if(!length(fstates2))
			continue
		var/istate2 = initial(turf_type:icon_state)
		if(isnull(istate2) || !(istate2 in fstates2))
			istate2 = ("" in fstates2) ? "" : fstates2[1]
		var/cache_key2 = "[ifile2]|[istate2]"
		if(!(cache_key2 in icon_dedup))
			var/icon/I2 = icon(ifile2, istate2, SOUTH, 1)
			if(!I2 || !length(icon_states(I2)))
				continue
			var/imgid2 = "sp[counter]"
			counter++
			Insert(imgid2, I2)
			icon_dedup[cache_key2] = imgid2
		GLOB.spawnpanel_icon_map["[turf_type]"] = icon_dedup[cache_key2]

	for(var/mob_type in typesof(/mob))
		if(mob_type == /mob)
			continue
		var/ifile3 = initial(mob_type:icon)
		if(!ifile3)
			continue
		if(!(ifile3 in states_cache))
			states_cache[ifile3] = icon_states(ifile3)
		var/list/fstates3 = states_cache[ifile3]
		if(!length(fstates3))
			continue
		var/istate3 = initial(mob_type:icon_state)
		if(isnull(istate3) || !(istate3 in fstates3))
			istate3 = ("" in fstates3) ? "" : fstates3[1]
		var/cache_key3 = "[ifile3]|[istate3]"
		if(!(cache_key3 in icon_dedup))
			var/icon/I3 = icon(ifile3, istate3, SOUTH, 1)
			if(!I3 || !length(icon_states(I3)))
				continue
			var/imgid3 = "sp[counter]"
			counter++
			Insert(imgid3, I3)
			icon_dedup[cache_key3] = imgid3
		GLOB.spawnpanel_icon_map["[mob_type]"] = icon_dedup[cache_key3]

	return ..()

/datum/asset/json/spawnpanel
	name = "spawnpanel_atom_data"

/datum/asset/json/spawnpanel/generate()
	var/list/data = list()
	var/list/atoms = list()

	for(var/obj_type in typesof(/obj))
		if(obj_type == /obj)
			continue
		atoms["[obj_type]"] = list(
			"name" = "[initial(obj_type:name)]",
			"type" = "Objects",
			"iconid" = GLOB.spawnpanel_icon_map["[obj_type]"]
		)

	for(var/turf_type in typesof(/turf))
		if(turf_type == /turf)
			continue
		atoms["[turf_type]"] = list(
			"name" = "[initial(turf_type:name)]",
			"type" = "Turfs",
			"iconid" = GLOB.spawnpanel_icon_map["[turf_type]"]
		)

	for(var/mob_type in typesof(/mob))
		if(mob_type == /mob)
			continue
		atoms["[mob_type]"] = list(
			"name" = "[initial(mob_type:name)]",
			"type" = "Mobs",
			"iconid" = GLOB.spawnpanel_icon_map["[mob_type]"]
		)

	data["atoms"] = atoms
	return data
