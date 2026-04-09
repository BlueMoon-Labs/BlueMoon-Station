#define CARDCON_DEPARTMENT_SERVICE "Service"
#define CARDCON_DEPARTMENT_SECURITY "Security"
#define CARDCON_DEPARTMENT_MEDICAL "Medical"
#define CARDCON_DEPARTMENT_SUPPLY "Supply"
#define CARDCON_DEPARTMENT_SCIENCE "Science"
#define CARDCON_DEPARTMENT_LAW "Law"
#define CARDCON_DEPARTMENT_ENGINEERING "Engineering"
#define CARDCON_DEPARTMENT_COMMAND "Command"

/datum/computer_file/program/card_mod
	filename = "plexagonidwriter"
	filedesc = "Plexagon Access Management"
	category = PROGRAM_CATEGORY_CREW
	program_icon_state = "id"
	extended_desc = "Program for programming employee ID cards to access parts of the station."
	transfer_access = ACCESS_HEADS
	requires_ntnet = 0
	size = 8
	tgui_id = "NtosCard"
	program_icon = "id-card"
	usage_flags = PROGRAM_CONSOLE

	var/is_centcom = FALSE
	var/minor = FALSE
	var/authenticated = FALSE
	var/list/region_access = list()
	var/list/head_subordinates = list()

	//For some reason everything was exploding if this was static.
	var/list/sub_managers

/datum/computer_file/program/card_mod/New(obj/item/modular_computer/comp)
	. = ..()
	// same logic in /datum/computer_file/program/job_management
	sub_managers = list(
		"[ACCESS_HOP]" = list(
			"department" = list(CARDCON_DEPARTMENT_SERVICE, CARDCON_DEPARTMENT_COMMAND),
			"region" = 1,
			"head" = "Head of Personnel"
		),
		"[ACCESS_HOS]" = list(
			"department" = CARDCON_DEPARTMENT_SECURITY,
			"region" = 2,
			"head" = "Head of Security"
		),
		"[ACCESS_CMO]" = list(
			"department" = CARDCON_DEPARTMENT_MEDICAL,
			"region" = 3,
			"head" = "Chief Medical Officer"
		),
		"[ACCESS_RD]" = list(
			"department" = CARDCON_DEPARTMENT_SCIENCE,
			"region" = 4,
			"head" = "Research Director"
		),
		"[ACCESS_CE]" = list(
			"department" = CARDCON_DEPARTMENT_ENGINEERING,
			"region" = 5,
			"head" = "Chief Engineer"
		),
		"[ACCESS_QM]" = list(
			"department" = CARDCON_DEPARTMENT_SUPPLY,
			"region" = 6,
			"head" = "Quartermaster"
		)
	)

/datum/computer_file/program/card_mod/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	auto_authenticate()

/datum/computer_file/program/card_mod/process_tick(delta_time)
	. = ..()
	if(program_state != PROGRAM_STATE_ACTIVE)
		return
	auto_authenticate()

/datum/computer_file/program/card_mod/kill_program(forced)
	. = ..()
	authenticated = FALSE

/datum/computer_file/program/card_mod/proc/auto_authenticate()
	// Авто-аутентификация или деавторизация. Адекватно перевести бы это на сигналы...
	if(!computer)
		return
	var/obj/item/computer_hardware/card_slot/card_slot = computer.all_components[MC_CARD]
	if(!card_slot)
		return
	var/obj/item/card/id/user_id_card = card_slot.stored_card
	var/old_authenticated = authenticated
	var/old_region_access_len = region_access.len
	var/old_head_subordinates_len = head_subordinates.len
	authenticate(user_id_card)
	if(authenticated != old_authenticated || region_access.len != old_region_access_len || head_subordinates.len != old_head_subordinates_len)
		update_static_data_for_all_viewers()
		if(authenticated)
			playsound(computer, 'sound/machines/terminal_on.ogg', 50, FALSE)
		else
			playsound(computer, 'sound/machines/terminal_off.ogg', 50, FALSE)

/datum/computer_file/program/card_mod/proc/authenticate(obj/item/card/id/id_card)
	if(!id_card)
		authenticated = FALSE
		minor = FALSE
		return

	region_access = list()
	head_subordinates = list()
	if(ACCESS_CHANGE_IDS in id_card.access)
		minor = FALSE
		authenticated = TRUE
		return TRUE

	var/list/head_types = list()
	for(var/access_text in sub_managers)
		var/list/info = sub_managers[access_text]
		var/access = text2num(access_text)
		if((access in id_card.access))
			region_access += info["region"]
			//I don't even know what I'm doing anymore
			head_types += info["head"]

	if(length(head_types))
		for(var/j in SSjob.occupations)
			var/datum/job/job = j
			for(var/head in head_types)//god why
				if(head in job.department_head)
					head_subordinates += job.title

	authenticated = !!length(region_access)
	minor = TRUE
	return authenticated

/datum/computer_file/program/card_mod/proc/set_job(job_name, obj/item/card/id/target_id_card, mob/user)
	if(!computer || !authenticated || !target_id_card)
		return

	var/list/new_access = list()
	if(is_centcom)
		new_access = get_centcom_access(job_name)
	else
		var/datum/job/job = SSjob.name_occupations[job_name]
		if(!job)
			if(user)
				to_chat(user, span_warning("No class exists for this job: [job_name]"))
			return
		new_access = job.get_access()
		//финансовая вставка
		if(target_id_card?.registered_account)
			target_id_card.registered_account.account_job = job
		//конец финансов
	target_id_card.access -= get_all_centcom_access() + get_all_accesses()
	target_id_card.access |= new_access
	target_id_card.assignment = job_name
	target_id_card.custom_job = ""
	target_id_card.update_label()
	return TRUE

/datum/computer_file/program/card_mod/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/obj/item/computer_hardware/card_slot/card_slot
	var/obj/item/computer_hardware/card_slot/card_slot2
	var/obj/item/computer_hardware/printer/printer
	if(computer)
		card_slot = computer.all_components[MC_CARD]
		card_slot2 = computer.all_components[MC_CARD2]
		printer = computer.all_components[MC_PRINT]
		if(!card_slot || !card_slot2)
			return

	var/mob/user = usr
	var/obj/item/card/id/user_id_card = card_slot.stored_card

	var/obj/item/card/id/target_id_card = card_slot2.stored_card

	switch(action)
		if("PRG_print")
			if(!computer || !printer || !target_id_card || !authenticated)
				return
			var/contents = {"<h4>Access Report</h4>
						<u>Prepared By:</u> [user_id_card?.registered_name ? user_id_card.registered_name : "Unknown"]<br>
						<u>For:</u> [target_id_card.registered_name ? target_id_card.registered_name : "Unregistered"]<br>
						<hr>
						<u>Assignment:</u> [target_id_card.get_assignment_name()]<br>
						<b><u>Access:</u></b><br>
						%ACCESSES%
						"}

			var/list/compile_accesses = list()
			var/list/card_accesses = target_id_card.access.Copy()
			for(var/i in 1 to 7) // Перебираем все станционные доступы
				var/list/reg_access = list()
				for(var/access in get_region_accesses(i))
					if(access in target_id_card.access)
						reg_access += access
						card_accesses -= access
				if(length(reg_access))
					var/list/access_desc = list()
					for(var/access in reg_access)
						access_desc += get_access_desc(access)
					compile_accesses += "<b>[get_region_accesses_name(i)]:</b> [jointext(access_desc, ", ")]"
			if(length(card_accesses)) // Если остались доступы, записываем их отдельно
				var/list/access_desc = list()
				for(var/access in card_accesses)
					access_desc += get_access_desc(access)
				compile_accesses += "<b>Other:</b> [jointext(access_desc, ", ")]"

			contents = replacetext(contents, "%ACCESSES%", length(compile_accesses) ? jointext(compile_accesses, "<br>") : "No Accesses detected")

			if(!printer.print_text(contents,"access report"))
				to_chat(usr, "<span class='notice'>Hardware error: Printer was unable to print the file. It may be out of paper.</span>")
				return
			else
				playsound(computer, 'sound/machines/terminal_on.ogg', 50, FALSE)
				computer.visible_message("<span class='notice'>\The [computer] prints out a paper.</span>")
			return TRUE
		if("PRG_eject")
			if(!computer)
				return
			var/param = params["name"]
			switch(param)
				if("SecondID")
					if(!card_slot2)
						return
					if(target_id_card)
						target_id_card.update_manifest()
						return card_slot2.try_eject(user)
					else
						var/obj/item/card/id/id = user.get_active_held_item()
						if(istype(id))
							return card_slot2.try_insert(id)
				if("MainID")
					if(!card_slot)
						return
					if(user_id_card)
						. = card_slot.try_eject(user)
						if(. && authenticated)
							authenticated = FALSE
							playsound(computer, 'sound/machines/terminal_off.ogg', 50, FALSE)
						return
					else
						var/obj/item/card/id/id = user.get_active_held_item()
						if(istype(id))
							. = card_slot.try_insert(id)
							if(authenticate(id))
								playsound(computer, 'sound/machines/terminal_on.ogg', 50, FALSE)
							else
								playsound(computer, 'sound/machines/terminal_error.ogg', 50, FALSE)
							update_static_data_for_all_viewers()
							return
			return FALSE
		if("PRG_terminate")
			if(!computer || !authenticated || !target_id_card)
				return
			if(minor)
				var/assign = GetJobName(target_id_card.assignment)
				if(!(assign in head_subordinates))
					playsound(computer, 'sound/machines/terminal_error.ogg', 50, FALSE)
					return
			target_id_card.access -= get_all_centcom_access() + get_all_accesses()
			target_id_card.assignment = "Terminated"
			//финансовая вставка
			if(target_id_card?.registered_account)
				target_id_card.registered_account.account_job = null
			//конец финансов
			target_id_card.update_label()
			playsound(computer, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
			return TRUE
		if("PRG_demote")
			if(!computer || !authenticated || !target_id_card)
				return
			if(minor)
				var/assign = GetJobName(target_id_card.assignment)
				if(!(assign in head_subordinates))
					playsound(computer, 'sound/machines/terminal_error.ogg', 50, FALSE)
					return
			. = set_job("Assistant", target_id_card, user)
			if(.)
				playsound(computer, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			return
		if("PRG_reset_access")
			if(!computer || !authenticated || !target_id_card)
				return
			var/target = GetJobName(target_id_card.assignment)
			if(minor)
				if(!(target in head_subordinates))
					playsound(computer, 'sound/machines/terminal_error.ogg', 50, FALSE)
					return
			if(!target) // На всякий случай
				playsound(computer, 'sound/machines/terminal_error.ogg', 50, FALSE)
				return
			var/datum/job/job = SSjob.name_occupations[target]
			if(!job)
				to_chat(user, span_warning("No class exists for this job: [target]"))
				return
			var/list/new_access = is_centcom ? get_centcom_access(target) : job.get_access()
			target_id_card.access -= get_all_centcom_access() + get_all_accesses()
			target_id_card.access |= new_access
			playsound(computer, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			return TRUE
		if("PRG_edit")
			if(!computer || !authenticated || !target_id_card)
				return
			var/new_name = params["name"]
			if(!new_name)
				return
			target_id_card.registered_name = new_name
			target_id_card.update_label()
			playsound(computer, "terminal_type", 50, FALSE)
			return TRUE
		if("PRG_assign")
			if(!computer || !authenticated || !target_id_card)
				return
			var/target = params["assign_target"]
			if(!target)
				return

			if(target == "Custom")
				var/custom_name = params["custom_name"]
				custom_name = regex("^\\s+", "g").Replace(custom_name, "")
				custom_name = regex("\\s+$", "g").Replace(custom_name, "")
				if(!custom_name)
					return
				target_id_card.custom_job = custom_name
				target_id_card.update_label()
				. = TRUE
			else
				if(minor && !(GetJobName(target_id_card.assignment) in head_subordinates) && !(target in head_subordinates))
					playsound(computer, 'sound/machines/terminal_error.ogg', 50, FALSE)
					return
				. = set_job(target, target_id_card, user)
			if(.)
				playsound(computer, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			return
		if("PRG_access")
			if(!computer || !authenticated || !target_id_card)
				return
			var/access_type = text2num(params["access_target"])
			if(access_type in (is_centcom ? get_all_centcom_access() : get_all_accesses()))
				if(access_type in target_id_card.access)
					target_id_card.access -= access_type
				else
					target_id_card.access |= access_type
				playsound(computer, "terminal_type", 50, FALSE)
				return TRUE
		if("PRG_grantall")
			if(!computer || !authenticated || !target_id_card)
				return
			if(minor)
				var/list/new_access = list()
				for(var/region in region_access)
					new_access += get_region_accesses(region)
				new_access -= get_heads_access()
				target_id_card.access |= new_access
			else
				target_id_card.access |= (is_centcom ? get_all_centcom_access() : get_all_accesses())
			playsound(computer, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			return TRUE
		if("PRG_denyall")
			if(!computer || !authenticated || !target_id_card)
				return
			if(minor)
				var/list/new_access = list()
				for(var/region in region_access)
					new_access += get_region_accesses(region)
				new_access -= get_heads_access()
				target_id_card.access -= new_access
			else
				target_id_card.access -= get_all_centcom_access() + get_all_accesses()
			playsound(computer, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
			return TRUE
		if("PRG_grantregion")
			if(!computer || !authenticated || !target_id_card)
				return
			var/region = text2num(params["region"])
			if(isnull(region))
				return
			target_id_card.access |= get_region_accesses(region)
			playsound(computer, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			return TRUE
		if("PRG_denyregion")
			if(!computer || !authenticated || !target_id_card)
				return
			var/region = text2num(params["region"])
			if(isnull(region))
				return
			target_id_card.access -= get_region_accesses(region)
			playsound(computer, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
			return TRUE



/datum/computer_file/program/card_mod/ui_static_data(mob/user)
	var/list/data = list()
	data["station_name"] = station_name()
	data["centcom_access"] = is_centcom
	data["minor"] = minor

	var/list/departments
	if(is_centcom)
		departments = list("CentCom" = get_all_centcom_jobs())
	else
		departments = list(
			CARDCON_DEPARTMENT_COMMAND = GLOB.command_positions,//lol
			CARDCON_DEPARTMENT_ENGINEERING = GLOB.engineering_positions,
			CARDCON_DEPARTMENT_LAW = GLOB.law_positions,
			CARDCON_DEPARTMENT_MEDICAL = GLOB.medical_positions,
			CARDCON_DEPARTMENT_SCIENCE = GLOB.science_positions,
			CARDCON_DEPARTMENT_SECURITY = GLOB.security_positions,
			CARDCON_DEPARTMENT_SUPPLY = GLOB.supply_positions,
			CARDCON_DEPARTMENT_SERVICE = GLOB.civilian_positions
		)
	data["jobs"] = list()
	for(var/department in departments)
		var/list/job_list = departments[department]
		var/list/department_jobs = list()
		for(var/job in job_list)
			if(minor && !(job in head_subordinates))
				continue
			department_jobs += list(list(
				"display_name" = replacetext(job, "&nbsp", " "),
				"job" = job
			))
		if(length(department_jobs))
			data["jobs"][department] = department_jobs

	var/list/regions = list()
	var/static/list/minor_access_not_allowed // Если авторизация от доступа главы, то нельзя выдать доступ этой главы
	if(!minor_access_not_allowed)
		minor_access_not_allowed = list()
		for(var/access_text in sub_managers)
			minor_access_not_allowed += text2num(access_text)

	for(var/i in 1 to 7)
		if(minor && !(i in region_access))
			continue

		var/list/accesses = list()
		for(var/access in get_region_accesses(i))
			if(minor && (access in minor_access_not_allowed))
				continue
			if (get_access_desc(access))
				accesses += list(list(
					"desc" = replacetext(get_access_desc(access), "&nbsp", " "),
					"ref" = access,
				))

		regions += list(list(
			"name" = get_region_accesses_name(i),
			"regid" = i,
			"accesses" = accesses
		))

	data["regions"] = regions

	return data

/datum/computer_file/program/card_mod/ui_data(mob/user)
	var/list/data = get_header_data()

	data["station_name"] = station_name()

	var/obj/item/computer_hardware/card_slot/card_slot
	var/obj/item/computer_hardware/card_slot/card_slot2
	var/obj/item/computer_hardware/printer/printer

	if(computer)
		card_slot = computer.all_components[MC_CARD]
		card_slot2 = computer.all_components[MC_CARD2]
		printer = computer.all_components[MC_PRINT]
		data["have_id_slot"] = !!(card_slot2)
		data["have_printer"] = !!(printer)
	else
		data["have_id_slot"] = FALSE
		data["have_printer"] = FALSE

	data["authenticated"] = authenticated
	data["has_main_id"] = !!card_slot?.stored_card

	if(!card_slot2)
		return data //We're just gonna error out on the js side at this point anyway

	var/obj/item/card/id/id_card = card_slot2.stored_card
	data["has_id"] = !!id_card
	data["id_name"] = id_card ? id_card.name : "-----"
	data["id_rank"] = (id_card && id_card.get_assignment_name()) || "Unassigned"
	data["id_owner"] = id_card?.registered_name ? id_card.registered_name : "-----"
	data["id_custom_job"] = id_card?.custom_job ? id_card.custom_job : ""
	data["access_on_card"] = id_card?.access

	return data



#undef CARDCON_DEPARTMENT_SERVICE
#undef CARDCON_DEPARTMENT_SECURITY
#undef CARDCON_DEPARTMENT_MEDICAL
#undef CARDCON_DEPARTMENT_SCIENCE
#undef CARDCON_DEPARTMENT_LAW
#undef CARDCON_DEPARTMENT_SUPPLY
#undef CARDCON_DEPARTMENT_ENGINEERING
#undef CARDCON_DEPARTMENT_COMMAND
