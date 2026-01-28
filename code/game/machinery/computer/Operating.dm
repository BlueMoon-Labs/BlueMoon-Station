#define MENU_OPERATION 1
#define MENU_SURGERIES 2

/obj/machinery/computer/operating
	name = "operating computer"
	desc = "Отслеживает состояние пациента и отображает прогресс операции пошагово. Имеет слот для дискет с операциями, для проведения экспериментальных процедур."
	icon_screen = "crew"
	icon_keyboard = "med_key"
	circuit = /obj/item/circuitboard/computer/operating
	var/mob/living/carbon/human/patient
	var/obj/structure/table/optable/table
	var/list/advanced_surgeries = list()
	var/datum/techweb/linked_techweb
	light_color = LIGHT_COLOR_BLUE

/obj/machinery/computer/operating/Initialize(mapload)
	. = ..()
	linked_techweb = SSresearch.science_tech
	find_table()

/obj/machinery/computer/operating/Destroy()
	if(table)
		if(table.computer && table.computer != src)
			stack_trace("Operating computer at [COORD(src)] has mismatched table.computer reference (table.computer=[REF(table.computer)], src=[REF(src)])")
		table.computer = null
		table = null
	patient = null
	linked_techweb = null
	advanced_surgeries = null
	return ..()

/obj/machinery/computer/operating/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/disk/surgery))
		user.visible_message("[user] begins to load \the [O] in \the [src]...",
			"You begin to load a surgery protocol from \the [O]...",
			"You hear the chatter of a floppy drive.")
		var/obj/item/disk/surgery/D = O
		if(do_after(user, 10, target = src))
			advanced_surgeries |= D.surgeries
		return TRUE
	return ..()

/obj/machinery/computer/operating/proc/sync_surgeries()
	for(var/i in linked_techweb.researched_designs)
		var/datum/design/surgery/D = SSresearch.techweb_design_by_id(i)
		if(!istype(D))
			continue
		advanced_surgeries |= D.surgery

/obj/machinery/computer/operating/proc/find_table()
	for(var/direction in GLOB.cardinals)
		table = locate(/obj/structure/table/optable, get_step(src, direction))
		if(table)
			table.computer = src
			break

/obj/machinery/computer/operating/ui_state(mob/user)
	return GLOB.not_incapacitated_state

/obj/machinery/computer/operating/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OperatingComputer", name)
		ui.open()

/obj/machinery/computer/operating/ui_data(mob/user)
	var/list/data = list()
	data["table"] = table
	var/static/list/surgeries_base = list()
	if(!surgeries_base.len)
		for(var/path in BASE_MED_SURGERY_OPERATIONS)
			var/datum/surgery/S = path
			surgeries_base += list( \
				list(
					"name" = initial(S.name),
					"desc" = initial(S.desc)
				))

	data["surgeries_base"] = surgeries_base
	if(table)
		var/list/surgeries = list()
		for(var/X in advanced_surgeries)
			var/datum/surgery/S = X
			var/list/surgery = list()
			surgery["name"] = initial(S.name)
			surgery["desc"] = initial(S.desc)
			surgeries += list(surgery)
		data["surgeries"] = surgeries
		if(!table.check_patient())
			data["patient"] = null
			return data

		data["patient"] = list()
		patient = table.patient
		switch(patient.stat)
			if(CONSCIOUS)
				data["patient"]["stat"] = "В сознании"
				data["patient"]["statstate"] = "good"
			if(SOFT_CRIT)
				data["patient"]["stat"] = "В сознании"
				data["patient"]["statstate"] = "average"
			if(UNCONSCIOUS)
				data["patient"]["stat"] = "Без сознания"
				data["patient"]["statstate"] = "average"
			if(DEAD)
				data["patient"]["stat"] = "М[table.patient.gender == FEMALE ? "ертва" : "ёртв"]"
				data["patient"]["statstate"] = "bad"
		data["patient"]["health"] = patient.health
		data["patient"]["blood_type"] = patient.dna.blood_type
		data["patient"]["maxHealth"] = patient.maxHealth
		data["patient"]["minHealth"] = HEALTH_THRESHOLD_DEAD
		data["patient"]["bruteLoss"] = patient.getBruteLoss()
		data["patient"]["fireLoss"] = patient.getFireLoss()
		data["patient"]["toxLoss"] = patient.getToxLoss()
		data["patient"]["oxyLoss"] = patient.getOxyLoss()
		data["patient"]["is_robotic_organism"] = HAS_TRAIT(patient, TRAIT_ROBOTIC_ORGANISM)
		data["procedures"] = list()
		if(patient.surgeries.len)
			for(var/datum/surgery/procedure in patient.surgeries)
				var/datum/surgery_step/surgery_step = procedure.get_surgery_step()
				var/chems_needed = surgery_step.get_chem_list()
				var/alternative_step
				var/alt_chems_needed = ""
				var/list/next_step_tools = surgery_step.get_max_chance_implements()
				var/next_step_chance = "[clamp(surgery_step.get_chance(patient, user, user.get_active_held_item(), procedure, TRUE),0,100)] %"
				var/list/alternative_step_tools = list()
				var/alternative_step_chance = 0
				if(surgery_step.repeatable)
					var/datum/surgery_step/next_step = procedure.get_surgery_next_step()
					if(next_step)
						alternative_step = capitalize(next_step.name)
						alt_chems_needed = next_step.get_chem_list()
						alternative_step_tools = next_step.get_max_chance_implements()
						alternative_step_chance = "[clamp(next_step.get_chance(patient, user, user.get_active_held_item(), procedure, TRUE),0,100)] %"
					else
						alternative_step = "Finish operation"
				data["procedures"] += list(list(
					"name" = capitalize("[parse_zone(procedure.location)] - [procedure.name]"),
					"next_step" = capitalize(surgery_step.name),
					"next_step_tools" = next_step_tools,
					"next_step_chance" = next_step_chance,
					"chems_needed" = chems_needed,
					"alternative_step" = alternative_step,
					"alternative_step_tools" = alternative_step_tools,
					"alternative_step_chance" = alternative_step_chance,
					"alt_chems_needed" = alt_chems_needed
				))
	return data



/obj/machinery/computer/operating/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("sync")
			sync_surgeries()
			. = TRUE
	. = TRUE

#undef MENU_OPERATION
#undef MENU_SURGERIES
