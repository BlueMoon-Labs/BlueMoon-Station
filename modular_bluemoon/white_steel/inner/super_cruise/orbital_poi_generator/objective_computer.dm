/obj/machinery/computer/objective
	name = "консоль заданий"
	desc = "Консоль, которая загружает список свежих заданий от Центрального Командования."
	icon_screen = "bounty"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_ORANGE
	req_access = list( )
	var/list/viewing_mobs = list()

/obj/machinery/computer/objective/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	GLOB.objective_computers += src

/obj/machinery/computer/objective/Destroy()
	GLOB.objective_computers -= src
	. = ..()

/obj/machinery/computer/objective/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/objective/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Objective")
		ui.open()
	viewing_mobs += user

/obj/machinery/computer/objective/ui_close(mob/user, datum/tgui/tgui)
	viewing_mobs -= user

/obj/machinery/computer/objective/ui_static_data(mob/user)
	var/list/data = list()
	data["possible_objectives"] = list()
	for(var/datum/orbital_objective/objective in SSorbits.possible_objectives)
		data["possible_objectives"] += list(list(
			"name" = objective.name,
			"id" = objective.id,
			"payout" = objective.payout,
			"description" = objective.get_text()
		))
	data["selected_objective"] = null
	if(SSorbits.current_objective)
		data["selected_objective"] = list(
			"name" = SSorbits.current_objective.name,
			"id" = SSorbits.current_objective.id,
			"payout" = SSorbits.current_objective.payout,
			"description" = SSorbits.current_objective.get_text()
		)
	return data

/obj/machinery/computer/objective/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("assign")
			var/obj_id = params["id"]
			for(var/datum/orbital_objective/objective in SSorbits.possible_objectives)
				if(objective.id == obj_id)
					say(SSorbits.assign_objective(src, objective))
					return
		if("remove")
			if(SSorbits.current_objective)
				SSorbits.current_objective.remove_objective()
			return
		else
			return
