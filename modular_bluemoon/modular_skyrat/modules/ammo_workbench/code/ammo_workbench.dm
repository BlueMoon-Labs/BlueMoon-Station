/obj/machinery/ammo_workbench
	name = "ammunitions workbench"
	desc = "A machine, somewhat akin to a lathe, made specifically for manufacturing ammunition. It has a slot for magazines, ammo boxes, clips... anything that holds ammo."
	icon = 'modular_bluemoon/modular_skyrat/modules/ammo_workbench/icons/ammo_workbench.dmi'
	icon_state = "ammobench"
	density = TRUE
	use_power = IDLE_POWER_USE
	circuit = /obj/item/circuitboard/machine/ammo_workbench
	var/busy = FALSE
	/// if it's hacked it's gonna be able to print lethals. it'll be mad at you for doing so but it'll print basic lethals.
	var/hacked = FALSE
	var/disabled = FALSE
	var/shocked = FALSE
	var/hack_wire
	var/disable_wire
	var/error_message = ""
	var/error_type = ""
	var/disk_error = ""
	var/disk_error_type = ""
	var/shock_wire
	var/timer_id
	var/turbo_boost = FALSE
	var/obj/item/ammo_box/loaded_magazine = null
	var/obj/item/disk/ammo_workbench/loaded_datadisk = null
	/// A list of all possible ammo types.
	var/list/possible_ammo_types = list()
	// hello future codediver. open to suggestions on how to do the following without it sucking so badly
	/// what casings we're able to use
	var/list/valid_casings = list()
	/// the material requirement strings for these casings (for the tooltip)
	var/list/casing_mat_strings = list()
	/// can it print ammunition flagged as harmful (e.g. most ammo)?
	var/allowed_harmful = FALSE
	/// can it print advanced ammunition types (e.g. armor-piercing)? see modular_skyrat\modules\modular_weapons\code\modular_projectiles.dm
	var/allowed_advanced = FALSE
	/// what datadisks have been loaded. uh... honestly this doesn't really do much either
	var/list/loaded_datadisks = list()
	/// current multiplier for material cost per round
	var/creation_efficiency = 1.4
	/// current amount of time in deciseconds it takes to assemble a round
	var/time_per_round = 1.8 SECONDS
	/// multiplier for material cost per round (when turbo isn't enabled)
	var/base_efficiency = 1.4
	// deciseconds per round (when turbo isn't enabled)
	var/base_time_per_round = 1.8 SECONDS
	/// deciseconds per round (when turbo is enabled)
	var/turbo_time_per_round = 0.225 SECONDS
	/// multiplier for material cost per round (when turbo is enabled)
	var/turbo_efficiency = 2.8
	/// can this print any round of any caliber given a correct ammo_box? (you varedit this at your own risk, especially if used in a player-facing context.)
	/// does not force ammo to load in. just makes it able to print wacky ammotypes e.g. lionhunter 7.62, techshells
	var/adminbus = FALSE
	idle_power_usage = 10
	active_power_usage = 300

/obj/machinery/ammo_workbench/unlocked
	allowed_harmful = TRUE
	allowed_advanced = TRUE

/obj/item/circuitboard/machine/ammo_workbench
	name = "Ammunition Workbench (Machine Board)"
	icon_state = "security"
	build_path = /obj/machinery/ammo_workbench
	req_components = list(
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stock_parts/matter_bin = 2,
		/obj/item/stock_parts/micro_laser = 2
	)

/obj/machinery/ammo_workbench/ComponentInitialize()
	. = ..()
	var/list/valid_materials = list(
		/datum/material/iron,
		/datum/material/glass,
		/datum/material/plastic,
		/datum/material/wood,
		/datum/material/plasma,
		/datum/material/gold,
		/datum/material/silver,
		/datum/material/titanium,
		/datum/material/diamond,
		/datum/material/uranium,
		/datum/material/bronze,
		/datum/material/runedmetal,
		/datum/material/bone,
		/datum/material/cardboard,
		/datum/material/paper,
		/datum/material/meat,
		/datum/material/pizza,
		/datum/material/sand,
	)
	AddComponent(/datum/component/material_container, valid_materials, 200000)

/obj/machinery/ammo_workbench/Initialize(mapload)
	. = ..()
	set_wires(new /datum/wires/ammo_workbench(src))

/obj/machinery/ammo_workbench/examine(mob/user)
	. += ..()
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Storing up to <b>[materials.max_amount]</b> material units.<br>Material consumption at <b>[creation_efficiency*100]%</b>.")

/obj/machinery/ammo_workbench/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AmmoWorkbench")
		ui.open()

	if(shocked)
		shock(user, 80)

/obj/machinery/ammo_workbench/proc/update_ammotypes()
	LAZYCLEARLIST(valid_casings)
	LAZYCLEARLIST(casing_mat_strings)
	if(!loaded_magazine)
		return
	var/obj/item/ammo_casing/ammo_type = loaded_magazine.ammo_type
	var/ammo_caliber = initial(ammo_type.caliber)
	var/obj/item/ammo_casing/ammo_parent_type = type2parent(ammo_type)

	if(loaded_magazine.multitype)
		if(ammo_caliber == initial(ammo_parent_type.caliber) && ammo_caliber != null)
			ammo_type = ammo_parent_type
		possible_ammo_types = typesof(ammo_type)
	else
		possible_ammo_types = list(ammo_type)

	for(var/obj/item/ammo_casing/our_casing as anything in possible_ammo_types)
		if(!adminbus)
			if(!(initial(our_casing.can_be_printed)))
				continue
			if(initial(our_casing.harmful) && (!allowed_harmful && !hacked))
				continue
			if(initial(our_casing.advanced_print_req) && !allowed_advanced)
				continue
		if(initial(our_casing.projectile_type) == null)
			continue

		// Создаём временный экземпляр для чтения custom_materials
		var/obj/item/ammo_casing/casing_actual = new our_casing
		var/list/raw_casing_mats = list()
		if(casing_actual.custom_materials && islist(casing_actual.custom_materials))
			raw_casing_mats = casing_actual.custom_materials.Copy()
		else
			raw_casing_mats = list(/datum/material/iron = 400)
		qdel(casing_actual)

		var/list/efficient_casing_mats = list()
		for(var/material in raw_casing_mats)
			efficient_casing_mats[material] = raw_casing_mats[material] * creation_efficiency

		var/mat_string = ""
		var/i = 0
		for(var/material in efficient_casing_mats)
			i++
			var/datum/material/our_material = material
			mat_string += "[efficient_casing_mats[our_material]] cm³ [our_material.name]"
			if(i < length(efficient_casing_mats))
				mat_string += ", "
		mat_string += " per cartridge"

		valid_casings += our_casing
		valid_casings[our_casing] = initial(our_casing.name)
		casing_mat_strings += mat_string

/obj/machinery/ammo_workbench/ui_data(mob/user)
	var/list/data = list()

	data["loaded_datadisks"] = list()
	data["datadisk_loaded"] = FALSE
	data["datadisk_name"] = null
	data["datadisk_desc"] = null

	data["disk_error"] = disk_error
	data["disk_error_type"] = disk_error_type

	if(loaded_datadisk)
		data["datadisk_loaded"] = TRUE
		data["datadisk_name"] = initial(loaded_datadisk.name)
		data["datadisk_desc"] = initial(loaded_datadisk.desc)

	for(var/type in loaded_datadisks)
		var/obj/item/disk/ammo_workbench/disk = type
		data["loaded_datadisks"] += list(list("loaded_disk_name" = initial(disk.name), "loaded_disk_desc" = initial(disk.desc)))

	data["mag_loaded"] = FALSE
	data["error"] = null
	data["error_type"] = null
	data["system_busy"] = busy

	data["efficiency"] = creation_efficiency
	data["time"] = time_per_round / 10
	data["hacked"] = hacked
	data["turboBoost"] = turbo_boost

	data["materials"] = list()
	var/datum/component/material_container/mat_container = GetComponent(/datum/component/material_container)
	if (mat_container)
		for(var/mat in mat_container.materials)
			var/datum/material/M = mat
			var/amount = mat_container.materials[M]
			var/sheet_amount = amount / MINERAL_MATERIAL_AMOUNT
			var/ref = REF(M)
			data["materials"] += list(list("name" = M.name, "id" = ref, "amount" = sheet_amount))

	if(error_message)
		data["error"] = error_message
		data["error_type"] = error_type
	else if(busy)
		data["error"] = "SYSTEM IS BUSY"
		data["error_type"] = ""

	if(!loaded_magazine)
		data["error"] = "NO MAGAZINE IS INSERTED"
		data["error_type"] = ""
		return data
	else
		data["mag_loaded"] = TRUE

	data["available_rounds"] = list()

	for(var/casings_to_relay = 1 to length(valid_casings))
		var/typepath = valid_casings[casings_to_relay]
		data["available_rounds"] += list(list(
			"name" = valid_casings[typepath],
			"typepath" = typepath,
			"mats_list" = casing_mat_strings[casings_to_relay]
		))

	data["mag_name"] = loaded_magazine.name
	data["current_rounds"] = length(loaded_magazine.stored_ammo)
	data["max_rounds"] = loaded_magazine.max_ammo

	return data

/obj/machinery/ammo_workbench/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("EjectMag")
			ejectItem()
			. = TRUE

		if("FillMagazine")
			var/type_to_pass = text2path(params["selected_type"])
			fill_magazine_start(type_to_pass)
			. = TRUE

		if("Release")
			var/datum/component/material_container/mat_container = GetComponent(/datum/component/material_container)

			if(!mat_container)
				return
			var/datum/material/mat = locate(params["id"])

			var/amount = mat_container.materials[mat]
			if(!amount)
				return

			var/stored_amount = CEILING(amount / MINERAL_MATERIAL_AMOUNT, 0.1)

			if(!stored_amount)
				return

			var/desired = 0
			if (params["sheets"])
				desired = text2num(params["sheets"])

			var/sheets_to_remove = round(min(desired,50,stored_amount))

			mat_container.retrieve_sheets(sheets_to_remove, mat, loc)
			. = TRUE

		if("ReadDisk")
			loadDisk()

		if("EjectDisk")
			ejectDisk()

		if("turboBoost")
			toggle_turbo_boost()

/// Toggles this ammo bench's turbo setting. If it's on, uses the turbo time-per-round/efficiency; if off, resets to base time-per-round/efficiency. forced_off forces turbo off.
/obj/machinery/ammo_workbench/proc/toggle_turbo_boost(forced_off = FALSE)
	if(forced_off)
		turbo_boost = FALSE
	else
		turbo_boost = !turbo_boost

	if(turbo_boost)
		time_per_round = turbo_time_per_round
		creation_efficiency = turbo_efficiency
	else
		time_per_round = base_time_per_round
		creation_efficiency = base_efficiency
	update_ammotypes()

/obj/machinery/ammo_workbench/proc/ejectItem(mob/living/user)
	if(loaded_magazine)
		loaded_magazine.forceMove(drop_location())

		if(user)
			try_put_in_hand(loaded_magazine, user)

		loaded_magazine = null
	busy = FALSE
	error_message = ""
	error_type = ""
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	update_ammotypes()
	update_appearance()

/obj/machinery/ammo_workbench/proc/fill_magazine_start(casing_type)
	if(machine_stat & (NOPOWER|BROKEN))
		busy = FALSE
		if(timer_id)
			deltimer(timer_id)
			timer_id = null
		return

	if(error_message)
		error_message = ""
		error_type = ""

	if(!(casing_type in valid_casings))
		error_message = "AMMUNITION MISMATCH"
		error_type = "bad"
		return

	var/obj/item/ammo_casing/our_casing = casing_type

	if(initial(our_casing.harmful) && !allowed_harmful)
		error_message = "SYSTEM CORRUPTION DETECTED, PLEASE EJECT CONTAINER AND SUBMIT SUPPORT TICKET"
		error_type = "bad"
		if(!hacked)
			return

	if(!loaded_magazine)
		error_message = "NO MAGAZINE INSERTED"
		error_type = ""
		return

	if(loaded_magazine.stored_ammo.len >= loaded_magazine.max_ammo)
		error_message = "MAGAZINE IS FULL"
		error_type = "good"
		return

	if(busy)
		return

	busy = TRUE

	timer_id = addtimer(CALLBACK(src, PROC_REF(fill_round), casing_type), time_per_round, TIMER_STOPPABLE)

/obj/machinery/ammo_workbench/proc/fill_round(casing_type)
	if(machine_stat & (NOPOWER|BROKEN))
		busy = FALSE
		if(timer_id)
			deltimer(timer_id)
			timer_id = null
		return

	if(!loaded_magazine)
		return

	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)

	var/obj/item/ammo_casing/new_casing = new casing_type

	// Читаем материалы напрямую из созданного объекта
	var/list/required_materials = list()
	if(new_casing.custom_materials && islist(new_casing.custom_materials))
		required_materials = new_casing.custom_materials.Copy()
	else
		required_materials = list(/datum/material/iron = 500)

	var/list/efficient_materials = list()
	for(var/material in required_materials)
		efficient_materials[material] = required_materials[material] * creation_efficiency

	if(!materials.has_materials(efficient_materials))
		error_message = "INSUFFICIENT MATERIALS"
		error_type = "bad"
		ammo_fill_finish(FALSE)
		qdel(new_casing)
		return

	if(new_casing.type in possible_ammo_types)
		if(!loaded_magazine.give_round(new_casing))
			error_message = "AMMUNITION MISMATCH"
			error_type = "bad"
			ammo_fill_finish(FALSE)
			qdel(new_casing)
			return
		materials.use_materials(efficient_materials)
		new_casing.custom_materials = efficient_materials
		loaded_magazine.update_appearance()
		flick("ammobench_process", src)
		use_power(3000)
		playsound(loc, 'sound/machines/piston/piston_raise.ogg', 60, 1)
	else
		qdel(new_casing)
		ammo_fill_finish(FALSE)
		return

	if(loaded_magazine.stored_ammo.len >= loaded_magazine.max_ammo)
		ammo_fill_finish()
		error_message = "CONTAINER IS FULL"
		error_type = "good"
		return

	SStgui.update_uis(src)

	timer_id = addtimer(CALLBACK(src, PROC_REF(fill_round), casing_type), time_per_round, TIMER_STOPPABLE)

/obj/machinery/ammo_workbench/proc/ammo_fill_finish(successfully = TRUE)
	SStgui.update_uis(src)
	if(successfully)
		playsound(loc, 'sound/machines/ping.ogg', 40, TRUE)
	else
		playsound(loc, 'sound/machines/buzz-sigh.ogg', 40, TRUE)
	update_appearance()
	busy = FALSE
	if(timer_id)
		deltimer(timer_id)
		timer_id = null

/obj/machinery/ammo_workbench/proc/loadDisk()
	disk_error = ""
	disk_error_type = ""
	if(!loaded_datadisk)
		return FALSE
	if(loaded_datadisk.type in loaded_datadisks)
		disk_error = "ERROR: DISK DATA ALREADY IN SYSTEM MEMORY"
		return FALSE

	disk_error = "DISK LOADED SUCCESSFULLY"
	disk_error_type = "good"
	loaded_datadisk.on_bench_install(src)
	loaded_datadisks += loaded_datadisk.type
	return TRUE

/obj/machinery/ammo_workbench/proc/ejectDisk()
	if(loaded_datadisk)
		loaded_datadisk.forceMove(drop_location())
		loaded_datadisk = null
		disk_error = ""
		disk_error_type = ""


//MISC MACHINE PROCS

/obj/machinery/ammo_workbench/RefreshParts()
	. = ..()
	toggle_turbo_boost(forced_off = TRUE)
	var/time_efficiency = 1.8 SECONDS
	for(var/obj/item/stock_parts/micro_laser/new_micro_laser in component_parts)
		time_efficiency -= new_micro_laser.rating * 2
	time_per_round = clamp(time_efficiency, 1, 20)
	base_time_per_round = time_per_round
	turbo_time_per_round = time_efficiency / 8

	var/efficiency = 1.4
	for(var/obj/item/stock_parts/manipulator/new_manipulator in component_parts)
		efficiency -= new_manipulator.rating * 0.1

	creation_efficiency = max(0, efficiency)
	base_efficiency = creation_efficiency
	turbo_efficiency = creation_efficiency * 2

	var/mat_capacity = 0
	for(var/obj/item/stock_parts/matter_bin/new_matter_bin in component_parts)
		mat_capacity += new_matter_bin.rating * (50 * MINERAL_MATERIAL_AMOUNT)

	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	materials.max_amount = mat_capacity
	update_ammotypes()

/obj/machinery/ammo_workbench/update_overlays()
	. = ..()
	if(loaded_magazine)
		. += "ammobench_loaded"

/obj/machinery/ammo_workbench/Destroy()
	QDEL_NULL(wires)
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	if(loaded_magazine)
		loaded_magazine.forceMove(loc)
		loaded_magazine = null
	if(loaded_datadisk)
		loaded_datadisk.forceMove(loc)
		loaded_datadisk = null

	return ..()

/obj/machinery/ammo_workbench/proc/shock(mob/user, prb)
	if(machine_stat & (BROKEN|NOPOWER))
		return FALSE
	if(!prob(prb))
		return FALSE
	do_sparks(5, TRUE, src)
	if (electrocute_mob(user, get_area(src), src, 0.7, TRUE))
		return TRUE
	else
		return FALSE

/obj/machinery/ammo_workbench/attackby(obj/item/O, mob/user, params)
	if (default_deconstruction_screwdriver(user, "[initial(icon_state)]_t", initial(icon_state), O))
		return
	if(default_deconstruction_crowbar(O))
		return
	if(panel_open && is_wire_tool(O))
		wires.interact(user)
		return TRUE
	if(is_refillable() && O.is_drainable())
		return FALSE

	// Обработка стэков материалов (всегда ДО оружия)
	if(istype(O, /obj/item/stack))
		var/obj/item/stack/S = O
		var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
		if(!materials)
			to_chat(user, span_warning("No material storage component!"))
			return TRUE
		if(!S.custom_materials || !length(S.custom_materials))
			to_chat(user, span_warning("This stack has no defined materials!"))
			return TRUE
		var/list/mats_to_add = list()
		var/total_to_add = 0
		for(var/mat_type in S.custom_materials)
			var/total_amount = S.custom_materials[mat_type]
			mats_to_add[mat_type] = total_amount
			total_to_add += total_amount
		if(materials.total_amount + total_to_add > materials.max_amount)
			to_chat(user, span_warning("Not enough space in [src]!"))
			return TRUE
		for(var/mat_type in mats_to_add)
			materials.materials[mat_type] += mats_to_add[mat_type]
			materials.total_amount += mats_to_add[mat_type]
		qdel(S)
		to_chat(user, span_notice("You insert [O] into [src]."))
		SStgui.update_uis(src)
		return TRUE

	if(Insert_Item(O, user))
		return TRUE

	if(O.force > 0)
		user.visible_message(span_danger("[user] hits [src] with [O]!"), span_danger("You hit [src] with [O]!"))
		take_damage(O.force, BRUTE, MELEE, 1)
		return TRUE

	return TRUE

/obj/machinery/ammo_workbench/proc/Insert_Item(obj/item/O, mob/living/user)
	if(user.combat_mode)
		return FALSE
	if(!is_insertion_ready(user))
		return FALSE
	if(istype(O, /obj/item/ammo_box))
		if(!user.transferItemToLoc(O, src))
			return FALSE
		if(loaded_magazine)
			to_chat(user, span_notice("You quickly swap [loaded_magazine] for [O]."))
			loaded_magazine.forceMove(drop_location())
			user.put_in_hands(loaded_magazine)
			loaded_magazine = null
			busy = FALSE
			error_message = ""
			error_type = ""
			if(timer_id)
				deltimer(timer_id)
				timer_id = null
		loaded_magazine = O
		to_chat(user, span_notice("You insert [O] to into [src]'s reciprocal."))
		flick("h_lathe_load", src)
		update_appearance()
		update_ammotypes()
		playsound(loc, 'sound/weapons/autoguninsert.ogg', 35, 1)
		return TRUE
	if(istype(O, /obj/item/disk/ammo_workbench))
		if(!user.transferItemToLoc(O, src))
			return FALSE
		loaded_datadisk = O
		to_chat(user, span_notice("You insert [O] to into [src]'s floppydisk port."))
		flick("h_lathe_load", src)
		update_appearance()
		playsound(loc, 'sound/machines/terminal_insert_disc.ogg', 35, 1)
		return TRUE
	return FALSE

/obj/machinery/ammo_workbench/proc/is_insertion_ready(mob/user, obj/item/O)
	if(panel_open)
		to_chat(user, span_warning("You can't load [src] while it's opened!"))
		return FALSE
	if(disabled)
		to_chat(user, span_warning("The insertion belts of [src] won't engage!"))
		return FALSE
	if(machine_stat & BROKEN)
		to_chat(user, span_warning("[src] is broken."))
		return FALSE
	if(machine_stat & NOPOWER)
		to_chat(user, span_warning("[src] has no power."))
		return FALSE
	if(istype(O, /obj/item/disk/ammo_workbench) && loaded_datadisk)
		to_chat(user, span_warning("[src] already has a disk inserted."))
		return FALSE
	return TRUE

/obj/machinery/ammo_workbench/proc/reset(wire)
	switch(wire)
		if(WIRE_HACK)
			if(!wires.is_cut(wire))
				adjust_hacked(FALSE)
		if(WIRE_SHOCK)
			if(!wires.is_cut(wire))
				shocked = FALSE
		if(WIRE_DISABLE)
			if(!wires.is_cut(wire))
				disabled = FALSE

/obj/machinery/ammo_workbench/proc/adjust_hacked(state)
	hacked = state


// WIRE DATUM
/datum/wires/ammo_workbench
	holder_type = /obj/machinery/ammo_workbench
	proper_name = "Ammunition Workbench"

/datum/wires/ammo_workbench/New(atom/holder)
	wires = list(
		WIRE_HACK, WIRE_DISABLE,
		WIRE_SHOCK, WIRE_ZAP
	)
	add_duds(6)
	..()

/datum/wires/ammo_workbench/interactable(mob/user)
	if(!..())
		return FALSE
	var/obj/machinery/ammo_workbench/A = holder
	if(A.panel_open)
		return TRUE

/datum/wires/ammo_workbench/get_status()
	var/obj/machinery/ammo_workbench/A = holder
	var/list/status = list()
	status += "The red light is [A.disabled ? "on" : "off"]."
	status += "The blue light is [A.hacked ? "on" : "off"]."
	return status

/datum/wires/ammo_workbench/on_pulse(wire)
	var/obj/machinery/ammo_workbench/A = holder
	switch(wire)
		if(WIRE_HACK)
			A.adjust_hacked(!A.hacked)
			addtimer(CALLBACK(A, TYPE_PROC_REF(/obj/machinery/ammo_workbench, reset), wire), 6 SECONDS)
		if(WIRE_SHOCK)
			A.shocked = !A.shocked
			addtimer(CALLBACK(A, TYPE_PROC_REF(/obj/machinery/ammo_workbench, reset), wire), 6 SECONDS)
		if(WIRE_DISABLE)
			A.disabled = !A.disabled
			addtimer(CALLBACK(A, TYPE_PROC_REF(/obj/machinery/ammo_workbench, reset), wire), 6 SECONDS)

/datum/wires/ammo_workbench/on_cut(wire, mend, source)
	var/obj/machinery/ammo_workbench/A = holder
	switch(wire)
		if(WIRE_HACK)
			A.adjust_hacked(!mend)
		if(WIRE_SHOCK)
			A.shocked = !mend
		if(WIRE_DISABLE)
			A.disabled = !mend
		if(WIRE_ZAP)
			A.shock(usr, 50)
