// TGUI Backend для всех fabricators (Protolathe, Circuit Imprinter, Techfab)
// Unified system for oldTG

/obj/machinery/rnd/production
	/// Cached list of designs for TGUI
	var/list/cached_tgui_designs = list()

/obj/machinery/rnd/production/ui_interact(mob/user, datum/tgui/ui)
	if(!consoleless_interface)
		return ..()

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Fabricator")
		ui.open()

/obj/machinery/rnd/production/ui_static_data(mob/user)
	var/list/data = list()

	// Machine info
	data["machineName"] = name
	data["machineType"] = type
	data["departmentTag"] = department_tag
	data["organization"] = host_research?.organization || "Unknown"

	// Categories with subcategories
	var/list/categories_data = list()
	for(var/category in categories)
		var/list/subcats = list()
		// Find all subcategories for this category
		for(var/design_id in stored_research.researched_designs)
			var/datum/design/D = SSresearch.techweb_design_by_id(design_id)
			if(!(D.build_type & allowed_buildtypes))
				continue
			if(!(isnull(allowed_department_flags) || (D.departmental_flags & allowed_department_flags)))
				continue

			for(var/cat in D.category)
				if(cat == category)
					continue
				// Check if this is a subcategory (contains parent category name)
				if(findtext(cat, category) && !(cat in subcats))
					subcats += cat

		categories_data += list(list(
			"name" = category,
			"subcategories" = subcats
		))

	data["categories"] = categories_data

	// Build types
	data["allowedBuildTypes"] = allowed_buildtypes

	// All designs
	var/list/designs_data = list()
	for(var/design_id in stored_research.researched_designs)
		var/datum/design/D = SSresearch.techweb_design_by_id(design_id)

		// Check if this design is allowed
		if(!(D.build_type & allowed_buildtypes))
			continue
		if(!(isnull(allowed_department_flags) || (D.departmental_flags & allowed_department_flags)))
			continue

		var/list/design_data = list(
			"id" = D.id,
			"name" = D.name,
			"desc" = D.desc,
			"categories" = D.category,
			"buildPath" = "[D.build_path]",
			"constructionTime" = D.construction_time,
			"latheTimeFactor" = D.lathe_time_factor,
			"minSecurityLevel" = D.min_security_level,
			"maxSecurityLevel" = D.max_security_level,
			"departmentalFlags" = D.departmental_flags
		)

		// Materials
		var/list/materials_list = list()
		var/coeff = efficient_with(D.build_path) ? print_cost_coeff : 1
		for(var/mat in D.materials)
			var/datum/material/M = mat
			materials_list += list(list(
				"name" = M.name,
				"amount" = D.materials[mat] * coeff,
				"materialRef" = "[mat]"
			))
		design_data["materials"] = materials_list

		// Reagents
		var/list/reagents_list = list()
		for(var/reagent in D.reagents_list)
			reagents_list += list(list(
				"name" = "[reagent]",
				"amount" = D.reagents_list[reagent] * coeff
			))
		design_data["reagents"] = reagents_list

		designs_data += list(design_data)

	data["designs"] = designs_data

	return data

/obj/machinery/rnd/production/ui_data(mob/user)
	var/list/data = list()

	// Machine status
	data["busy"] = busy
	data["emagged"] = (obj_flags & EMAGGED) ? TRUE : FALSE
	data["disabled"] = disabled
	data["hacked"] = hacked

	// Efficiency
	data["efficiency"] = print_cost_coeff
	data["efficiencyPercent"] = round(print_cost_coeff * 100)

	// Materials
	var/list/materials_data = list()
	if(materials.mat_container)
		data["materialsConnected"] = TRUE
		data["materialsOnHold"] = materials.on_hold()
		data["materialsMaxStorage"] = materials.local_size

		for(var/mat_id in materials.mat_container.materials)
			var/datum/material/M = mat_id
			var/amount = materials.mat_container.materials[mat_id]
			materials_data += list(list(
				"name" = M.name,
				"amount" = amount,
				"ref" = REF(M),
				"sheets" = round(amount / MINERAL_MATERIAL_AMOUNT)
			))
	else
		data["materialsConnected"] = FALSE
		data["materialsOnHold"] = TRUE

	data["materials"] = materials_data

	// Reagents
	var/list/reagents_data = list()
	data["reagentsMaxVolume"] = reagents.maximum_volume
	data["reagentsTotalVolume"] = reagents.total_volume

	for(var/datum/reagent/R in reagents.reagent_list)
		reagents_data += list(list(
			"name" = R.name,
			"volume" = R.volume,
			"type" = "[R.type]"
		))

	data["reagents"] = reagents_data

	// Security level
	data["securityLevel"] = GLOB.security_level
	data["securityLevelName"] = NUM2SECLEVEL(GLOB.security_level)
	data["isStation"] = is_station_level(z)

	return data

/obj/machinery/rnd/production/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("build")
			if(busy)
				say("Warning: Fabricator is busy!")
				return FALSE

			var/design_id = params["id"]
			var/amount = params["amount"]
			if(!design_id || !amount)
				return FALSE

			amount = text2num(amount)
			if(!amount || amount < 1)
				return FALSE

			return user_try_print_id(design_id, amount)

		if("eject_material")
			var/mat_ref = params["ref"]
			var/amount = params["amount"]
			if(!mat_ref || !amount)
				return FALSE

			var/datum/material/M = locate(mat_ref)
			if(!M)
				return FALSE

			eject_sheets(M, text2num(amount))
			return TRUE

		if("dispose_reagent")
			var/reagent_type = text2path(params["type"])
			if(!reagent_type)
				return FALSE

			reagents.del_reagent(reagent_type)
			return TRUE

		if("dispose_all_reagents")
			reagents.clear_reagents()
			return TRUE

		if("sync_research")
			update_research()
			say("Research data synchronized.")
			return TRUE

// Protolathe specific
/obj/machinery/rnd/production/protolathe/ui_static_data(mob/user)
	var/list/data = ..()
	data["fabricatorType"] = "protolathe"
	return data

// Circuit Imprinter specific
/obj/machinery/rnd/production/circuit_imprinter/ui_static_data(mob/user)
	var/list/data = ..()
	data["fabricatorType"] = "imprinter"
	return data

/obj/machinery/rnd/production/circuit_imprinter/hacked/ui_static_data(mob/user)
	var/list/data = ..()
	data["fabricatorType"] = "imprinter_hacked"
	data["bypassSecurity"] = TRUE
	return data

// Techfab specific
/obj/machinery/rnd/production/techfab/ui_static_data(mob/user)
	var/list/data = ..()
	data["fabricatorType"] = "techfab"
	return data
