/// TGUI-based Traitor Panel replacement
/datum/traitor_panel_tgui
	var/datum/mind/target_mind

/datum/traitor_panel_tgui/New(datum/mind/M)
	. = ..()
	target_mind = M

/datum/traitor_panel_tgui/Destroy(force, ...)
	target_mind = null
	SStgui.close_uis(src)
	return ..()

/datum/traitor_panel_tgui/ui_interact(mob/user, datum/tgui/ui)
	if(!target_mind)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TraitorPanel", "[target_mind.name] - Traitor Panel")
		ui.open()

/datum/traitor_panel_tgui/ui_state(mob/user)
	return GLOB.admin_state

/datum/traitor_panel_tgui/ui_data(mob/user)
	. = list()
	if(!target_mind)
		return

	.["mind_name"] = target_mind.name
	.["mind_key"] = target_mind.key
	.["mind_active"] = target_mind.active
	.["assigned_role"] = target_mind.assigned_role
	.["special_role"] = target_mind.special_role
	.["memory"] = target_mind.memory

	// Current mob info
	if(target_mind.current)
		.["mob_name"] = target_mind.current.real_name
		.["has_body"] = TRUE
		.["is_human"] = ishuman(target_mind.current)
		.["is_silicon"] = issilicon(target_mind.current)
		.["is_mindshielded"] = HAS_TRAIT(target_mind.current, TRAIT_MINDSHIELD)

		if(iscyborg(target_mind.current))
			var/mob/living/silicon/robot/R = target_mind.current
			.["is_emagged"] = R.emagged
		else
			.["is_emagged"] = FALSE

		// Activity component
		var/datum/component/activity/activity = target_mind.current.GetComponent(/datum/component/activity)
		if(activity)
			.["activity_level"] = activity.activity_level
			.["activity_idle_time"] = activity.not_moved_counter
	else
		.["has_body"] = FALSE

	// Uplink info
	.["has_uplink"] = FALSE
	.["uplink_tc"] = 0
	if(target_mind.current && ishuman(target_mind.current))
		var/datum/component/uplink/U = target_mind.find_syndicate_uplink()
		if(U)
			.["has_uplink"] = TRUE
			.["uplink_tc"] = U.telecrystals

	// Active antag datums
	var/list/active_antags = list()
	for(var/datum/antagonist/A in target_mind.antag_datums)
		var/list/antag_info = list()
		antag_info["name"] = A.name
		antag_info["type"] = "[A.type]"
		antag_info["ref"] = REF(A)
		antag_info["category"] = A.antagpanel_category

		// Objectives
		var/list/obj_list = list()
		for(var/datum/objective/O in A.objectives)
			obj_list += list(list(
				"text" = O.explanation_text,
				"completed" = O.completed,
				"ref" = REF(O)
			))
		antag_info["objectives"] = obj_list

		// Admin commands
		var/list/commands = list()
		for(var/cmd_name in A.get_admin_commands())
			commands += cmd_name
		antag_info["commands"] = commands

		// Memory
		antag_info["antag_memory"] = A.antag_memory

		active_antags += list(antag_info)
	.["active_antags"] = active_antags

	// Build available antags (categories with addable antags)
	if(!GLOB.antag_prototypes)
		GLOB.antag_prototypes = list()
		for(var/antag_type in subtypesof(/datum/antagonist))
			var/datum/antagonist/A = new antag_type
			var/cat_id = A.antagpanel_category
			if(!GLOB.antag_prototypes[cat_id])
				GLOB.antag_prototypes[cat_id] = list(A)
			else
				GLOB.antag_prototypes[cat_id] += A
		sortTim(GLOB.antag_prototypes, GLOBAL_PROC_REF(cmp_text_asc), associative = TRUE)

	var/list/available_categories = list()
	for(var/antag_category in GLOB.antag_prototypes)
		var/list/cat_antags = list()
		for(var/datum/antagonist/prototype in GLOB.antag_prototypes[antag_category])
			if(!prototype.show_in_antagpanel)
				continue
			var/is_active = !!target_mind.has_antag_datum(prototype.type)
			var/can_add = !is_active && prototype.can_be_owned(target_mind)
			var/pref_enabled = prototype.enabled_in_preferences(target_mind)
			cat_antags += list(list(
				"name" = prototype.name,
				"type_path" = "[prototype.type]",
				"is_active" = is_active,
				"can_add" = can_add,
				"pref_enabled" = pref_enabled
			))
		if(length(cat_antags))
			available_categories += list(list(
				"category" = antag_category,
				"antags" = cat_antags
			))
	.["available_categories"] = available_categories

/datum/traitor_panel_tgui/ui_act(action, params, datum/tgui/ui)
	if(..())
		return

	if(!check_rights(R_ADMIN))
		return

	var/client/admin = usr.client

	switch(action)
		if("add_antag")
			var/antag_path = text2path(params["antag_type"])
			if(!antag_path || !ispath(antag_path, /datum/antagonist))
				return
			target_mind.add_antag_wrapper(antag_path, usr)

		if("remove_antag")
			var/datum/antagonist/A = locate(params["antag_ref"]) in target_mind.antag_datums
			if(!istype(A))
				to_chat(usr, "<span class='warning'>Invalid antagonist reference.</span>")
				return
			A.admin_remove(usr)

		if("toggle_objective")
			var/datum/objective/O
			for(var/datum/antagonist/A in target_mind.antag_datums)
				O = locate(params["obj_ref"]) in A.objectives
				if(O)
					break
			if(!O)
				return
			O.completed = !O.completed
			log_admin("[key_name(usr)] toggled the completion of [target_mind.current]'s objective: [O.explanation_text]")

		if("delete_objective")
			var/datum/objective/O
			for(var/datum/antagonist/A in target_mind.antag_datums)
				O = locate(params["obj_ref"]) in A.objectives
				if(O)
					A.objectives -= O
					break
			if(!O)
				return
			message_admins("[key_name_admin(usr)] removed an objective from [target_mind.current]: [O.explanation_text]")
			log_admin("[key_name(usr)] removed an objective from [target_mind.current]: [O.explanation_text]")
			qdel(O)

		if("add_objective")
			// Delegate to the mind's existing objective-add Topic handler
			// This opens popups for picking objective type
			var/datum/antagonist/target_antag
			if(params["antag_ref"])
				target_antag = locate(params["antag_ref"]) in target_mind.antag_datums
			if(!target_antag)
				if(length(target_mind.antag_datums) == 1)
					target_antag = target_mind.antag_datums[1]
				else if(!length(target_mind.antag_datums))
					target_antag = target_mind.add_antag_datum(/datum/antagonist/custom)
				else
					target_antag = tgui_input_list(usr, "Which antagonist gets the objective:", "Antagonist", target_mind.antag_datums + "(new custom antag)")
					if(target_antag == "(new custom antag)")
						target_antag = target_mind.add_antag_datum(/datum/antagonist/custom)
					if(!istype(target_antag, /datum/antagonist))
						return

			if(!GLOB.objective_choices)
				populate_objective_choices()

			var/selected_type_name = tgui_input_list(usr, "Select objective type:", "Objective type", GLOB.objective_choices)
			var/selected_type = GLOB.objective_choices[selected_type_name]
			if(!selected_type)
				return

			var/datum/objective/new_obj = new selected_type
			new_obj.owner = target_mind
			new_obj.admin_edit(usr)
			target_antag.objectives += new_obj
			message_admins("[key_name_admin(usr)] added a new objective for [target_mind.current]: [new_obj.explanation_text]")
			log_admin("[key_name(usr)] added a new objective for [target_mind.current]: [new_obj.explanation_text]")

		if("announce_objectives")
			target_mind.announce_objectives()

		if("edit_memory")
			var/new_memo = stripped_multiline_input(usr, "Write new memory", "Memory", target_mind.memory, MAX_MESSAGE_LEN)
			if(!isnull(new_memo))
				target_mind.memory = new_memo

		if("edit_role")
			var/new_role = tgui_input_list(usr, "Select new role", "Assigned role", get_all_jobs())
			if(new_role)
				target_mind.assigned_role = new_role

		if("give_uplink")
			if(!target_mind.equip_traitor())
				to_chat(usr, "<span class='danger'>Equipping a syndicate uplink failed!</span>")
			else
				log_admin("[key_name(admin)] gave [target_mind.current] an uplink.")

		if("take_uplink")
			target_mind.take_uplink()
			target_mind.memory = null
			log_admin("[key_name(admin)] removed [target_mind.current]'s uplink.")

		if("set_tc")
			var/datum/component/uplink/U = target_mind.find_syndicate_uplink()
			if(U)
				var/crystals = text2num(params["tc_amount"])
				if(!isnull(crystals) && crystals >= 0)
					crystals = round(clamp(crystals, 0, 999))
					U.telecrystals = crystals
					message_admins("[key_name_admin(usr)] changed [target_mind.current]'s telecrystal count to [crystals].")
					log_admin("[key_name(usr)] changed [target_mind.current]'s telecrystal count to [crystals].")

		if("antag_command")
			var/datum/antagonist/A = locate(params["antag_ref"]) in target_mind.antag_datums
			if(!istype(A))
				return
			var/cmd_name = params["command"]
			var/list/admin_commands = A.get_admin_commands()
			if(!(cmd_name in admin_commands))
				return
			var/datum/callback/CB = admin_commands[cmd_name]
			CB.Invoke(usr)

		if("edit_antag_memory")
			var/datum/antagonist/A = locate(params["antag_ref"]) in target_mind.antag_datums
			if(!istype(A))
				return
			var/new_memo = stripped_multiline_input(usr, "Edit antag memory", "Antag Memory", A.antag_memory, MAX_MESSAGE_LEN)
			if(!isnull(new_memo))
				A.antag_memory = new_memo

		if("undress")
			if(target_mind.current)
				for(var/obj/item/W in target_mind.current)
					target_mind.current.dropItemToGround(W, TRUE)
