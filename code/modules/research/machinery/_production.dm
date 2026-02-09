/obj/machinery/rnd/production
	name = "technology fabricator"
	desc = "Makes researched and prototype items with materials and energy."
	layer = BELOW_OBJ_LAYER
	var/consoleless_interface = TRUE			//Whether it can be used without a console.
	var/print_cost_coeff = 1				//Materials needed * coeff = actual.
	var/list/categories = list()
	var/datum/component/remote_materials/materials
	var/allowed_department_flags = ALL
	var/production_animation				//What's flick()'d on print.
	var/allowed_buildtypes = NONE
	var/list/cached_designs = list()
	var/list/_ui_cached_designs = list()
	var/department_tag = "Unidentified"			//used for material distribution among other things.
	var/datum/techweb/stored_research
	var/datum/techweb/host_research

	var/lathe_prod_time = 0.5

	/// What color is this machine's stripe? Leave null to not have a stripe.
	var/stripe_color = null
	COOLDOWN_DECLARE(cooldown_say) // Отвечает за КД SAY машины и за КД update_research()
	var/const/cooldown_say_time = 1.5 SECONDS
	var/const/max_build_amount = 60 // Отвечает за максимум в кнопке [Max: XXX] TGUI и максимум пердметов на печать в 1 пачке

/obj/machinery/rnd/production/Initialize(mapload)
	. = ..()
	create_reagents(0, OPENCONTAINER | NO_REACT)
	gen_access()
	stored_research = new
	host_research = SSresearch.science_tech
	INVOKE_ASYNC(src, PROC_REF(update_research))
	materials = AddComponent(/datum/component/remote_materials, "lathe", mapload, _after_insert=CALLBACK(src, PROC_REF(AfterMaterialInsert)))
	RefreshParts()

/obj/machinery/rnd/production/Destroy()
	materials = null
	cached_designs = null
	QDEL_NULL(stored_research)
	host_research = null
	return ..()

/obj/machinery/rnd/production/examine(mob/user)
	. = ..()
	var/datum/component/remote_materials/materials = GetComponent(/datum/component/remote_materials)
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>Статус-дисплей сообщает: \n\
		- Хранится до <b>[materials.local_size]</b> m/u локально.\n\
		- Затраты материалов: <b>[print_cost_coeff*100]%</b>.</span>"

//we eject the materials upon deconstruction.
/obj/machinery/rnd/production/on_deconstruction()
	for(var/obj/item/reagent_containers/glass/G in component_parts)
		reagents.trans_to(G, G.reagents.maximum_volume)
	return ..()

/obj/machinery/rnd/production/update_overlays()
	. = ..()

	if(!stripe_color)
		return

	var/mutable_appearance/stripe = mutable_appearance('icons/obj/machines/research.dmi', "protolathe_stripe[panel_open ? "_t" : ""]")
	stripe.color = stripe_color
	. += stripe

/*
/obj/machinery/rnd/production/emag_act()
	if(obj_flags & EMAGGED)
		return
	. = ..()
	balloon_alert(usr, span_balloon_warning("emagged"))
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	req_access = list()
	req_one_access = list()
	update_research()
*/

/obj/machinery/rnd/production/proc/update_research()
	host_research.copy_research_to(stored_research, TRUE)
	update_designs()

/obj/machinery/rnd/production/proc/update_designs()
	cached_designs.Cut()
	for(var/i in stored_research.researched_designs)
		var/datum/design/d = SSresearch.techweb_design_by_id(i)
		if((isnull(allowed_department_flags) || (d.departmental_flags & allowed_department_flags)) && (d.build_type & allowed_buildtypes))
			cached_designs |= d

	update_designs_ui()

/obj/machinery/rnd/production/proc/update_designs_ui()
	_ui_cached_designs.Cut()
	// Разворачиваем плоский лист категорий в ассоц.
	var/list/all_categories = categories.Copy()
	for(var/V in all_categories)
		all_categories[V] = list()

	// Проходимся по категориям дизайнов и добавляем их к нам
	for(var/datum/design/D in cached_designs)
		for(var/C in all_categories)
			if(C in D.category)
				all_categories[C] += D

	// Сокращаем названия формата Machine Design (XXX)
	var/static/list/replace_item_name_category = list(
			"Computer Boards",
			"Research Machinery",
			"Misc. Machinery",
			"Engineering Machinery",
			"Medical Machinery",
			"Teleportation Machinery",
			"Hydroponics Machinery",
			"Shuttle Machinery",
		)
	var/hide_sec_designs = !is_station_level(z) && !(LAZYLEN(req_access) || LAZYLEN(req_one_access))
	for(var/category in all_categories)
		var/list/cat = list(
			"name" = category,
			"items" = list())
		var/replace_item_name = replace_item_name_category.Find(category)
		for(var/datum/design/D in all_categories[category])
			if(!D.build_path)
				continue
			var/obj/item_path = D.build_path // ispath

			// Формируем стоимость в материалах
			var/coeff = efficient_with(D.build_path) ? print_cost_coeff : 1
			var/list/cost = list()
			for(var/datum/material/M in D.materials)
				cost[M.name] = D.materials[M] * coeff

			// Формируем стоимость в химикатах
			var/list/cost_chem = list()
			for(var/R_path in D.reagents_list)
				var/datum/reagent/R = R_path // ispath
				cost_chem += list(list("name" = initial(R.name), "id" = R, "amount" = D.reagents_list[R]))

			// Делаем описание для плат
			var/desc = ""
			if(ispath(item_path, /obj/item/circuitboard))
				var/obj/item/circuitboard/circuit = item_path // ispath
				var/obj/circuit_build_path = circuit.build_path // ispath
				desc = strip_html_tags(initial(circuit_build_path.desc))
			if(!desc)
				desc = strip_html_tags(initial(item_path.desc))

			// Проверка дизайна на ограничение по коду + его описание в одном проке
			var/sec_desc = design_sec_level_desc(D)
			// Если продакшн вне станции и не имеет доступов, разрешаем только предметы без требований к коду
			if(sec_desc && hide_sec_designs)
				continue

			cat["items"] += list(list(
				"id" = D.id,
				"name" = replace_item_name ? initial(item_path.name) : D.name,
				"desc" = desc,
				"cost" = cost,
				"cost_chem" = cost_chem,
				"sec_desc" = sec_desc,
				"min_sec_level" = D.min_security_level,
				"max_sec_level" = D.max_security_level,
			))

		if(LAZYLEN(cat["items"]))
			_ui_cached_designs += list(cat)

	update_static_data_for_all_viewers()

/obj/machinery/rnd/production/RefreshParts()
	. = ..()
	calculate_efficiency()
	update_designs_ui()

/obj/machinery/rnd/production/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Fabricator", "[host_research?.organization] [department_tag] [name]")
		ui.open()

/obj/machinery/rnd/production/ui_assets(mob/user)
	. = list(
		get_asset_datum(/datum/asset/spritesheet/research_designs),
		get_asset_datum(/datum/asset/spritesheet/sheetmaterials),
	)

/obj/machinery/rnd/production/ui_data(mob/user)
	. = list()
	.["current_sec_level"] = GLOB.security_level
	.["busy"] = busy
	.["materials"] = list()
	.["materials_text"] = ""
	.["onHold"] = FALSE
	if(materials?.mat_container)
		.["materials"] = materials.mat_container.ui_data(user)
		.["materials_text"] = materials.format_amount()
		.["onHold"] = materials.on_hold()

	.["chems"] = list()
	.["chems_maximum"] = reagents?.maximum_volume
	.["chems_total_volume"] = reagents?.total_volume
	if(reagents)
		var/list/chems = reagents.reagent_list
		for(var/datum/reagent/R in chems)
			.["chems"] += list(list("name" = R.name, "id" = R.type, "amount" = R.volume))

/obj/machinery/rnd/production/ui_static_data(mob/user)
	. = list()
	.["hacked"] = (obj_flags & EMAGGED)
	.["maxBuildButtonAmount"] = max_build_amount
	.["categories"] = _ui_cached_designs

/obj/machinery/rnd/production/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = usr
	if(!istype(user))
		return
	if(!user.can_use_production_topic(src, action))
		if(COOLDOWN_FINISHED(src, cooldown_say))
			say("В доступе отказано.")
			playsound(loc, 'sound/machines/uplinkerror.ogg', 70, 0)
			COOLDOWN_START(src, cooldown_say, cooldown_say_time)
		return
	switch(action)
		if("sync_research")
			if(!COOLDOWN_FINISHED(src, cooldown_say))
				return
			COOLDOWN_START(src, cooldown_say, cooldown_say_time)
			update_research()
			say("Синхронизация исследований с базой данных научно-исследовательского отдела.")
			return TRUE
		if("remove_mat")
			var/datum/material/M = locate(params["ref"])
			var/amount = params["amount"]
			if(!amount || !M)
				return
			return !!eject_sheets(M, amount)
		if("purge_chem")
			var/chem_path = params["chem"]
			if(!chem_path)
				return
			else if(chem_path == "all")
				reagents.clear_reagents()
			else
				reagents.del_reagent(text2path(chem_path))
			return TRUE
		if("build")
			var/build_id = params["id"]
			var/amount = params["amount"]
			if(!build_id || !amount)
				return
			return user_try_print_id(build_id, amount)

/obj/machinery/rnd/production/proc/calculate_efficiency()
	var/total_manip_rating = 0
	var/manips = 0
	if(reagents)		//If reagents/materials aren't initialized, don't bother, we'll be doing this again after reagents init anyways.
		reagents.maximum_volume = 0
		for(var/obj/item/reagent_containers/glass/G in component_parts)
			reagents.maximum_volume += G.volume
			G.reagents.trans_to(src, G.reagents.total_volume)
	if(materials)
		var/total_storage = 0
		for(var/obj/item/stock_parts/matter_bin/M in component_parts)
			total_storage += M.rating * 75000
		materials.set_local_size(total_storage)
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		total_manip_rating += M.rating
		manips++
	print_cost_coeff = STANDARD_PART_LEVEL_LATHE_COEFFICIENT(total_manip_rating / (manips? manips : 1))

/obj/machinery/rnd/production/proc/do_print(path, amount, list/matlist, notify_admins, mob/user)
	if(notify_admins)
		message_admins("[ADMIN_LOOKUPFLW(user)] has built [amount] of [path] at a [src]([type]).")
	for(var/i in 1 to amount)
		var/obj/O = new path(get_turf(src))
		if(efficient_with(O.type))
			O.set_custom_materials(matlist)
			O.rnd_crafted(src)
	playsound(src, 'sound/machines/prod_done.ogg', 50)
	SSblackbox.record_feedback("nested tally", "item_printed", amount, list("[type]", "[path]"))
	investigate_log("[key_name(user)] built [amount] of [path] at [src]([type]).", INVESTIGATE_RESEARCH)

/obj/machinery/rnd/production/proc/check_mat(datum/design/being_built, var/mat)	// now returns how many times the item can be built with the material
	if (!materials.mat_container)  // no connected silo
		return FALSE
	var/list/all_materials = being_built.reagents_list + being_built.materials

	var/A = materials.mat_container.get_material_amount(mat)
	if(!A)
		A = reagents.get_reagent_amount(mat)

	// these types don't have their .materials set in do_print, so don't allow
	// them to be constructed efficiently
	var/ef = efficient_with(being_built.build_path) ? print_cost_coeff : 1
	return round(A / max(1, all_materials[mat] * ef))

/obj/machinery/rnd/production/proc/efficient_with(path)
	return !ispath(path, /obj/item/stack/sheet) && !ispath(path, /obj/item/stack/ore/bluespace_crystal) && !ispath(path, /obj/item/stack/ducts)

/obj/machinery/rnd/production/proc/user_try_print_id(id, amount)
	if((!istype(linked_console) && requires_console) || !id)
		return FALSE
	if(busy)
		return FALSE
	if(istext(amount))
		amount = text2num(amount)
	if(isnull(amount))
		amount = 1
	if(amount > max_build_amount)
		if(COOLDOWN_FINISHED(src, cooldown_say))
			COOLDOWN_START(src, cooldown_say, cooldown_say_time)
			say("Warning: Printing failed: The request is too big!")
		return FALSE
	var/datum/design/D = (linked_console || requires_console)? (linked_console.stored_research.researched_designs[id]? SSresearch.techweb_design_by_id(id) : null) : SSresearch.techweb_design_by_id(id)
	if(!istype(D))
		return FALSE
	if(!(isnull(allowed_department_flags) || (D.departmental_flags & allowed_department_flags)))
		if(COOLDOWN_FINISHED(src, cooldown_say))
			COOLDOWN_START(src, cooldown_say, cooldown_say_time)
			say("Warning: Printing failed: This fabricator does not have the necessary keys to decrypt design schematics. Please update the research data with the on-screen button and contact Nanotrasen Support!")
		return FALSE
	if(D.build_type && !(D.build_type & allowed_buildtypes))
		if(COOLDOWN_FINISHED(src, cooldown_say))
			COOLDOWN_START(src, cooldown_say, cooldown_say_time)
			say("This machine does not have the necessary manipulation systems for this design. Please contact Nanotrasen Support!")
		return FALSE
	if(!(obj_flags & EMAGGED) && is_station_level(z))
		if(GLOB.security_level < D.min_security_level)
			if(COOLDOWN_FINISHED(src, cooldown_say))
				COOLDOWN_START(src, cooldown_say, cooldown_say_time)
				say("Minimum security alert level required to print this design not met, please contact the command staff.")
			return FALSE
		if(GLOB.security_level > D.max_security_level)
			if(COOLDOWN_FINISHED(src, cooldown_say))
				COOLDOWN_START(src, cooldown_say, cooldown_say_time)
				say("Exceeded maximum security alert level required to print this design, please contact the command staff.")
	if(!materials.mat_container)
		if(COOLDOWN_FINISHED(src, cooldown_say))
			COOLDOWN_START(src, cooldown_say, cooldown_say_time)
			say("No connection to material storage, please contact the quartermaster.")
		return FALSE
	if(materials.on_hold())
		if(COOLDOWN_FINISHED(src, cooldown_say))
			COOLDOWN_START(src, cooldown_say, cooldown_say_time)
			say("Mineral access is on hold, please contact the quartermaster.")
		return FALSE
	var/power = 1000
	amount = clamp(amount, 1, 50)
	for(var/M in D.materials)
		power += round(D.materials[M] * amount / 35)
	power = min(3000, power)
	use_power(power)
	var/coeff = efficient_with(D.build_path) ? print_cost_coeff : 1
	var/list/efficient_mats = list()
	for(var/MAT in D.materials)
		efficient_mats[MAT] = D.materials[MAT] * coeff
	if(!materials.mat_container.has_materials(efficient_mats, amount))
		if(COOLDOWN_FINISHED(src, cooldown_say))
			COOLDOWN_START(src, cooldown_say, cooldown_say_time)
			say("Not enough materials to complete prototype[amount > 1? "s" : ""].")
		return FALSE
	for(var/R in D.reagents_list)
		if(!reagents.has_reagent(R, D.reagents_list[R] * amount * coeff))
			if(COOLDOWN_FINISHED(src, cooldown_say))
				COOLDOWN_START(src, cooldown_say, cooldown_say_time)
				say("Not enough reagents to complete prototype[amount > 1? "s" : ""].")
			return FALSE
	materials.mat_container.use_materials(efficient_mats, amount)
	materials.silo_log(src, "built", -amount, "[D.name]", efficient_mats)
	for(var/R in D.reagents_list)
		reagents.remove_reagent(R, D.reagents_list[R] * amount * coeff)
	busy = TRUE
	if(production_animation)
		flick(production_animation, src)
	var/timecoeff = D.lathe_time_factor * print_cost_coeff
	addtimer(CALLBACK(src, PROC_REF(reset_busy)), (20 * timecoeff * amount) ** 0.5)
	addtimer(CALLBACK(src, PROC_REF(do_print), D.build_path, amount, efficient_mats, D.dangerous_construction, usr), (20 * timecoeff * amount) ** lathe_prod_time)
	playsound(src, 'sound/machines/prod.ogg', 50)
	return TRUE

/obj/machinery/rnd/production/proc/eject_sheets(eject_sheet, eject_amt)
	var/datum/component/material_container/mat_container = materials.mat_container
	if (!mat_container)
		if(COOLDOWN_FINISHED(src, cooldown_say))
			COOLDOWN_START(src, cooldown_say, cooldown_say_time)
			say("Нет доступа к хранилищу материалов, пожалуйста, свяжитесь с завхозом.")
		return FALSE
	if (materials.on_hold())
		if(COOLDOWN_FINISHED(src, cooldown_say))
			COOLDOWN_START(src, cooldown_say, cooldown_say_time)
			say("Доступ к материалам приостановлен, ожалуйста, свяжитесь с завхозом.")
		return FALSE
	var/count = mat_container.retrieve_sheets(text2num(eject_amt), eject_sheet, drop_location())
	var/list/matlist = list()
	matlist[eject_sheet] = MINERAL_MATERIAL_AMOUNT
	materials.silo_log(src, "ejected", -count, "sheets", matlist)
	return count

/obj/machinery/rnd/production/proc/design_sec_level_desc(datum/design/D)
	. = ""
	if(obj_flags & EMAGGED || !istype(D))
		return
	if(!(D.min_security_level > SEC_LEVEL_GREEN || D.max_security_level < SEC_LEVEL_DELTA))
		return

	. = "Только при уровнях тревоги: "
	var/list/levels = list()
	for(var/n in D.min_security_level to D.max_security_level)
		levels += NUM2SECLEVEL(n)
	. += english_list(levels, and_text = ", ")
