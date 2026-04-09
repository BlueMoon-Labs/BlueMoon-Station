#define CARDCON_DEPARTMENT_SERVICE "Service"
#define CARDCON_DEPARTMENT_SECURITY "Security"
#define CARDCON_DEPARTMENT_MEDICAL "Medical"
#define CARDCON_DEPARTMENT_SUPPLY "Supply"
#define CARDCON_DEPARTMENT_SCIENCE "Science"
#define CARDCON_DEPARTMENT_LAW "Law"
#define CARDCON_DEPARTMENT_ENGINEERING "Engineering"
#define CARDCON_DEPARTMENT_COMMAND "Command"

/// The time since the last job opening was created
GLOBAL_VAR_INIT(time_last_changed_position, 0)

#define MAX_PRIORITY_JOB 5

/datum/computer_file/program/job_management
	filename = "plexagoncore"
	filedesc = "Plexagon HR Core"
	category = PROGRAM_CATEGORY_CREW
	program_icon_state = "id"
	extended_desc = "Program for viewing and changing job slot avalibility."
	transfer_access = ACCESS_HEADS
	requires_ntnet = TRUE
	size = 4
	tgui_id = "NtosJobManager"
	program_icon = "address-book"

	var/change_position_cooldown = 30
	//Jobs you cannot open new positions for
	var/list/blacklisted = list(
		"AI",
		"Assistant",
		"Prisoner",
		"Stowaway",
		"Cyborg",
		"Captain",
		"Head of Personnel",
		"Head of Security",
		"NanoTrasen Representative",
		"Chief Engineer",
		"Research Director",
		"Chief Medical Officer",
		"Quartermaster")

	//The scaling factor of max total positions in relation to the total amount of people on board the station in %
	var/max_relative_positions = 75

	//This is used to keep track of opened positions for jobs to allow instant closing
	//Assoc array: "JobName" = (int)<Opened Positions>
	var/list/opened_positions = list()

	var/list/sub_managers

/datum/computer_file/program/job_management/New()
	. = ..()
	change_position_cooldown = CONFIG_GET(number/id_console_jobslot_delay)
	// same logic in /datum/computer_file/program/card_mod
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

/datum/computer_file/program/job_management/proc/can_open_job(datum/job/job)
	if(job?.title in blacklisted)
		return FALSE
	if((job.total_positions <= length(GLOB.player_list) * (max_relative_positions / 100)))
		var/delta = (world.time / 10) - GLOB.time_last_changed_position
		if((change_position_cooldown < delta) || (opened_positions[job.title] < 0))
			return TRUE
	return FALSE


/datum/computer_file/program/job_management/proc/can_close_job(datum/job/job)
	if(job?.title in blacklisted)
		return FALSE
	if(job.total_positions > job.current_positions)
		var/delta = (world.time / 10) - GLOB.time_last_changed_position
		if((change_position_cooldown < delta) || (opened_positions[job.title] > 0))
			return TRUE
	return FALSE


/datum/computer_file/program/job_management/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	var/obj/item/computer_hardware/card_slot/card_slot = computer.all_components[MC_CARD]
	var/obj/item/card/id/user_id = card_slot?.stored_card

	if(!user_id || !(ACCESS_CHANGE_IDS in user_id.access))
		return

	switch(action)
		if("PRG_open_job")
			var/edit_job_target = params["target"]
			var/datum/job/j = SSjob.GetJob(edit_job_target)
			if(!j || !can_open_job(j))
				return
			if(opened_positions[edit_job_target] >= 0)
				GLOB.time_last_changed_position = world.time / 10
			j.total_positions++
			opened_positions[edit_job_target]++
			log_game("[key_name(usr)] opened a [j.title] job position, for a total of [j.total_positions] open job slots.")
			playsound(computer, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			return TRUE
		if("PRG_close_job")
			var/edit_job_target = params["target"]
			var/datum/job/j = SSjob.GetJob(edit_job_target)
			if(!j || !can_close_job(j))
				return
			//Allow instant closing without cooldown if a position has been opened before
			if(opened_positions[edit_job_target] <= 0)
				GLOB.time_last_changed_position = world.time / 10
			j.total_positions--
			opened_positions[edit_job_target]--
			log_game("[key_name(usr)] closed a [j.title] job position, leaving [j.total_positions] open job slots.")
			playsound(computer, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			return TRUE
		if("PRG_priority")
			var/priority_target = params["target"]
			var/datum/job/j = SSjob.GetJob(priority_target)
			if(!j || (j?.title in blacklisted))
				return
			if(j.total_positions <= j.current_positions)
				return
			if(j in SSjob.prioritized_jobs)
				SSjob.prioritized_jobs -= j
			else
				if(length(SSjob.prioritized_jobs) < MAX_PRIORITY_JOB)
					SSjob.prioritized_jobs += j
				else
					computer.say("Error: CentCom employment protocols restrict prioritising more than [MAX_PRIORITY_JOB] jobs.")
			playsound(computer, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			return TRUE


/datum/computer_file/program/job_management/ui_data(mob/user)
	var/list/data = get_header_data()
	. = data

	var/authed = FALSE
	var/minor = FALSE
	var/list/head_subordinates = list()

	var/obj/item/computer_hardware/card_slot/card_slot = computer.all_components[MC_CARD]
	var/obj/item/card/id/user_id = card_slot?.stored_card
	if(user_id)
		if(ACCESS_CHANGE_IDS in user_id.access)
			authed = TRUE
		else
			minor = TRUE
			var/list/head_types = list()
			for(var/access_text in sub_managers)
				var/list/info = sub_managers[access_text]
				var/access = text2num(access_text)
				if(access in user_id.access)
					head_types += info["head"]

			if(length(head_types))
				for(var/j in SSjob.occupations)
					var/datum/job/job = j
					for(var/head in head_types)
						if(head in job.department_head)
							head_subordinates += job
			if(length(head_subordinates))
				authed = TRUE

	data["authed"] = authed
	if(!authed)
		return

	var/list/pos = list()
	for(var/j in SSjob.occupations)
		var/datum/job/job = j
		if(job.title in blacklisted)
			continue
		if(minor && !(job in head_subordinates))
			continue

		pos += list(list(
			"title" = job.title,
			"current" = job.current_positions,
			"total" = job.total_positions,
			"status_open" = authed ? can_open_job(job) : FALSE,
			"status_close" = authed ? can_close_job(job) : FALSE,
		))
	data["slots"] = pos
	var/delta = round(change_position_cooldown - ((world.time / 10) - GLOB.time_last_changed_position), 1)
	data["cooldown"] = delta < 0 ? 0 : delta
	var/list/priority = list()
	for(var/j in SSjob.prioritized_jobs)
		var/datum/job/job = j
		priority += job.title
	data["prioritized"] = priority

#undef CARDCON_DEPARTMENT_SERVICE
#undef CARDCON_DEPARTMENT_SECURITY
#undef CARDCON_DEPARTMENT_MEDICAL
#undef CARDCON_DEPARTMENT_SCIENCE
#undef CARDCON_DEPARTMENT_LAW
#undef CARDCON_DEPARTMENT_SUPPLY
#undef CARDCON_DEPARTMENT_ENGINEERING
#undef CARDCON_DEPARTMENT_COMMAND

#undef MAX_PRIORITY_JOB
