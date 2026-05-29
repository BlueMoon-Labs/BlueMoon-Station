/datum/ban_panel
	var/playerckey
	var/adminckey
	var/ip
	var/cid
	var/page = 0

/datum/ban_panel/New(playerckey, adminckey, ip, cid, page)
	src.playerckey = playerckey
	src.adminckey = adminckey
	src.ip = ip
	src.cid = cid
	if(page)
		src.page = text2num(page)

/datum/ban_panel/Destroy(force, ...)
	SStgui.close_uis(src)
	return ..()

/datum/ban_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BanPanel")
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/ban_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/ban_panel/ui_data(mob/user)
	. = list()
	.["db_connected"] = SSdbcore.Connect()
	.["playerckey"] = playerckey
	.["adminckey"] = adminckey
	.["ip"] = ip
	.["cid"] = cid
	.["page"] = page

	var/list/job_categories = list()
	for(var/list/cat in GLOB.jobban_panel_data)
		var/list/cat_data = list()
		cat_data["name"] = cat["name"]
		cat_data["color"] = cat["color"]
		var/list/roles = list()
		for(var/r in cat["roles"])
			roles += list(list("name" = r))
		cat_data["roles"] = roles
		job_categories += list(cat_data)
	.["job_categories"] = job_categories

	if(playerckey)
		var/list/banned_roles = list()
		if(SSdbcore.Connect())
			banned_roles = get_active_job_bans_for_ckey(ckey(playerckey))
		.["banned_roles"] = banned_roles

	var/list/job_list = list()
	for(var/j in get_all_jobs())
		job_list += j
	for(var/j in GLOB.nonhuman_positions)
		job_list += j
	for(var/j in list(ROLE_TRAITOR, ROLE_CHANGELING, ROLE_OPERATIVE, ROLE_REV, ROLE_CULTIST, ROLE_WIZARD, ROLE_HERETIC))
		job_list += j
	.["job_list"] = job_list

	if(adminckey || playerckey || ip || cid)
		.["search_results"] = get_search_results()
		.["total_count"] = get_ban_count()

/datum/ban_panel/proc/get_ban_count()
	var/list/searchlist = list()
	var/list/searchlist_args = list()
	if(playerckey)
		searchlist += "ckey = :playerckey"
		searchlist_args["playerckey"] = playerckey
	if(adminckey)
		searchlist += "a_ckey = :adminckey"
		searchlist_args["adminckey"] = adminckey
	if(ip)
		searchlist += "ip = INET_ATON(:ip)"
		searchlist_args["ip"] = ip
	if(cid)
		searchlist += "computerid = :cid"
		searchlist_args["cid"] = cid
	var/search = searchlist.Join(" AND ")
	var/datum/db_query/query_count = SSdbcore.NewQuery({"SELECT COUNT(id) FROM [format_table_name("ban")] WHERE [search]"}, searchlist_args)
	if(!query_count.warn_execute())
		qdel(query_count)
		return 0
	var/count = 0
	if(query_count.NextRow())
		count = text2num(query_count.item[1])
	qdel(query_count)
	return count

/datum/ban_panel/proc/get_search_results()
	. = list()
	var/list/searchlist = list()
	var/list/searchlist_args = list()
	if(playerckey)
		searchlist += "ckey = :playerckey"
		searchlist_args["playerckey"] = playerckey
	if(adminckey)
		searchlist += "a_ckey = :adminckey"
		searchlist_args["adminckey"] = adminckey
	if(ip)
		searchlist += "ip = INET_ATON(:ip)"
		searchlist_args["ip"] = ip
	if(cid)
		searchlist += "computerid = :cid"
		searchlist_args["cid"] = cid
	var/search = searchlist.Join(" AND ")
	var/bansperpage = 15
	var/limit = " LIMIT [bansperpage * page], [bansperpage]"
	var/datum/db_query/query_search = SSdbcore.NewQuery({"
		SELECT id, bantime, bantype, reason, job, duration, expiration_time,
			IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].ckey), ckey),
			IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].a_ckey), a_ckey),
			unbanned,
			IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].unbanned_ckey), unbanned_ckey),
			unbanned_datetime, edits, round_id
		FROM [format_table_name("ban")]
		WHERE [search] ORDER BY bantime DESC[limit]"}, searchlist_args)
	if(!query_search.warn_execute())
		qdel(query_search)
		return
	while(query_search.NextRow())
		var/list/ban = list()
		ban["id"] = query_search.item[1]
		ban["bantime"] = query_search.item[2]
		ban["bantype"] = query_search.item[3]
		ban["reason"] = query_search.item[4]
		ban["job"] = query_search.item[5]
		ban["duration"] = query_search.item[6]
		ban["expiration"] = query_search.item[7]
		ban["ban_key"] = query_search.item[8]
		ban["a_key"] = query_search.item[9]
		ban["unbanned"] = text2num(query_search.item[10])
		ban["unban_key"] = query_search.item[11]
		ban["unbantime"] = query_search.item[12]
		ban["edits"] = query_search.item[13]
		ban["round_id"] = query_search.item[14]
		. += list(ban)
	qdel(query_search)

/datum/ban_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!check_rights(R_BAN))
		return

	switch(action)
		if("search")
			playerckey = params["playerckey"]
			adminckey = params["adminckey"]
			ip = params["ip"]
			cid = params["cid"]
			page = 0
			. = TRUE

		if("set_page")
			page = text2num(params["page"])
			. = TRUE

		if("add_ban")
			. = handle_add_ban(params)

		if("unban_jobs")
			. = handle_unban_jobs(params)

		if("edit_ban")
			. = handle_edit_ban(params)

		if("unban")
			. = handle_unban(params)

	SStgui.update_uis(src)

/datum/ban_panel/proc/handle_add_ban(list/params)
	if(!check_rights(R_BAN))
		return
	if(!SSdbcore.Connect())
		to_chat(usr, "<span class='danger'>Failed to establish database connection.</span>")
		return
	var/bantype = text2num(params["bantype"])
	var/bankey = params["bankey"]
	var/banckey = ckey(bankey)
	var/banip = params["banip"]
	var/bancid = params["bancid"]
	var/banduration = text2num(params["banduration"])
	var/banjob = params["banjob"]
	var/banreason = params["banreason"]
	var/banseverity = params["banseverity"]

	var/list/jobban_picks = list()
	var/list/flat_roles = usr.client.holder.get_jobban_flat_roles()
	var/jr_max = text2num(params["jr_max"]) || length(flat_roles)
	for(var/i = 1; i <= jr_max; i++)
		if(params["jr_[i]"] == "[i]")
			if(i <= length(flat_roles))
				jobban_picks += flat_roles[i]

	var/bantitle
	switch(bantype)
		if(BANTYPE_PERMA)
			bantitle = "Пермаментная Блокировка"
			if(!banckey || !banreason || !banseverity)
				to_chat(usr, "Not enough parameters (Requires ckey, severity, and reason).")
				return
			banduration = null
			banjob = null
		if(BANTYPE_TEMP)
			bantitle = "Блокировка"
			if(!banckey || !banreason || !banduration || !banseverity)
				to_chat(usr, "Not enough parameters (Requires ckey, reason, severity and duration).")
				return
			banjob = null
		if(BANTYPE_JOB_PERMA)
			bantitle = "Пермаментная Блокировка Роли"
			if(!banckey || !banreason || !banseverity)
				to_chat(usr, "Not enough parameters (Requires ckey, severity, and reason).")
				return
			if(!length(jobban_picks) && !banjob)
				to_chat(usr, "Not enough parameters (Requires job from the list or at least one role checkbox).")
				return
			banduration = null
		if(BANTYPE_JOB_TEMP)
			bantitle = "Блокировка Роли"
			if(!banckey || !banreason || !banduration || !banseverity)
				to_chat(usr, "Not enough parameters (Requires ckey, reason, severity and duration).")
				return
			if(!length(jobban_picks) && !banjob)
				to_chat(usr, "Not enough parameters (Requires job from the list or at least one role checkbox).")
				return
		if(BANTYPE_ADMIN_PERMA)
			bantitle = "Пермаментная Блокировка"
			if(!banckey || !banreason || !banseverity)
				to_chat(usr, "Not enough parameters (Requires ckey, severity and reason).")
				return
			banduration = null
			banjob = null
		if(BANTYPE_ADMIN_TEMP)
			bantitle = "Блокировка"
			if(!banckey || !banreason || !banduration || !banseverity)
				to_chat(usr, "Not enough parameters (Requires ckey, severity, reason and duration).")
				return
			banjob = null
		if(BANTYPE_PACIFIST)
			bantitle = "Пацификация"
			if(!banckey || !banreason || !banduration || !banseverity)
				to_chat(usr, "Not enough parameters (Requires ckey, severity, reason and duration).")
				return
			banjob = null

	var/mob/playermob
	for(var/mob/M in GLOB.player_list)
		if(M.ckey == banckey)
			if(!playermob || M.client)
				playermob = M

	banreason = "(MANUAL BAN) "+banreason
	if(!playermob)
		if(banip)
			banreason = "[banreason] (CUSTOM IP)"
		if(bancid)
			banreason = "[banreason] (CUSTOM CID)"
	else
		message_admins("Ban process: A mob matching [playermob.key] was found at location [playermob.x], [playermob.y], [playermob.z]. Custom ip and computer id fields replaced with the ip and computer id from the located mob.")

	if(length(jobban_picks) && (bantype == BANTYPE_JOB_PERMA || bantype == BANTYPE_JOB_TEMP))
		var/failed = FALSE
		for(var/job in jobban_picks)
			if(usr.client.holder.DB_ban_record(bantype, playermob, banduration, banreason, job, bankey, banip, bancid, suppress_feedback = TRUE) != TRUE)
				failed = TRUE
		if(failed)
			to_chat(usr, "<span class='danger'>[length(jobban_picks) > 1 ? "One or more job bans failed to apply." : "Failed to apply ban."]</span>")
			return
		var/jobs_joined = jointext(jobban_picks, ", ")
		to_chat(usr, "<span class='adminnotice'>Ban saved to database.</span>")
		message_admins("[key_name_admin(usr)] has added job ban(s) for [bankey] ([jobs_joined]) with the reason: \"[banreason]\" to the ban database.", 1)
		admin_ticket_log(banckey, "[key_name_admin(usr)] has added job ban(s) for [bankey] ([jobs_joined]) with the reason: \"[banreason]\" to the ban database.")
		create_message("note", bankey, null, "[banreason] (Jobs: [jobs_joined])", null, null, 1, 0, null, 0, banseverity, dont_announce_to_events = TRUE)
		GLOB.bot_event_sending_que += list(list(
			"type" = "ban_a",
			"title" = bantitle,
			"player" = bankey,
			"admin" = usr.key,
			"reason" = banreason,
			"banduration" = banduration,
			"bantimestamp" = SQLtime(),
			"round" = GLOB.round_id,
			"additional_info" = list("ban_type" = bantype, "ban_job" = jobs_joined)
		))
		return TRUE

	if(usr.client.holder.DB_ban_record(bantype, playermob, banduration, banreason, banjob, bankey, banip, bancid) != TRUE)
		to_chat(usr, "<span class='danger'>Failed to apply ban.</span>")
		return
	create_message("note", bankey, null, banreason, null, null, 1, 0, null, 0, banseverity, dont_announce_to_events = TRUE)
	GLOB.bot_event_sending_que += list(list(
		"type" = "ban_a",
		"title" = bantitle,
		"player" = bankey,
		"admin" = usr.key,
		"reason" = banreason,
		"banduration" = banduration,
		"bantimestamp" = SQLtime(),
		"round" = GLOB.round_id,
		"additional_info" = list("ban_type" = bantype, "ban_job" = banjob)
	))
	return TRUE

/datum/ban_panel/proc/handle_unban_jobs(list/params)
	if(!check_rights(R_BAN))
		return
	if(!SSdbcore.Connect())
		to_chat(usr, "<span class='danger'>Failed to establish database connection.</span>")
		return
	var/bankey = params["bankey"]
	if(!bankey)
		to_chat(usr, "<span class='warning'>Укажите Key (игрока).</span>")
		return
	var/banckey = ckey(bankey)
	var/list/flat_roles = usr.client.holder.get_jobban_flat_roles()
	var/jr_max = text2num(params["jr_max"]) || length(flat_roles)
	var/any_unban = FALSE
	for(var/i = 1; i <= jr_max; i++)
		var/was = params["was_jr_[i]"]
		var/now_checked = (params["jr_[i]"] == "[i]")
		if(was && !now_checked)
			if(i <= length(flat_roles))
				usr.client.holder.DB_ban_unban(banckey, BANTYPE_ANY_JOB, flat_roles[i])
				any_unban = TRUE
	var/client/C = GLOB.directory[banckey]
	if(C)
		jobban_buildcache(C)
	if(any_unban)
		message_admins("[key_name_admin(usr)] removed one or more job bans via SQL panel for [bankey].")
		to_chat(usr, "<span class='adminnotice'>Снятие джоббанов отправлено в БД.</span>")
	else
		to_chat(usr, "<span class='notice'>Нет снятых джоббанов: галочки должны быть сняты с ролей, по которым есть активный джоббан.</span>")
	return TRUE

/datum/ban_panel/proc/handle_edit_ban(list/params)
	if(!check_rights(R_BAN))
		return
	var/banid = text2num(params["banid"])
	var/banedit = params["banedit"]
	if(!banedit || !banid)
		return
	usr.client.holder.DB_ban_edit(banid, banedit)
	return TRUE

/datum/ban_panel/proc/handle_unban(list/params)
	if(!check_rights(R_BAN))
		return
	var/banid = text2num(params["banid"])
	if(!banid)
		return
	usr.client.holder.DB_ban_edit(banid, "unban")
	return TRUE

/proc/get_active_job_bans_for_ckey(ckey)
	. = list()
	if(!SSdbcore.Connect())
		return
	var/datum/db_query/query = SSdbcore.NewQuery({"
		SELECT job FROM [format_table_name("ban")]
		WHERE ckey = :ckey
		AND bantype IN ('JOB_PERMABAN', 'JOB_TEMPBAN')
		AND (unbanned IS NULL OR unbanned = 0)
		AND (expiration_time IS NULL OR expiration_time > NOW())
	"}, list("ckey" = ckey))
	if(!query.warn_execute())
		qdel(query)
		return
	while(query.NextRow())
		. += query.item[1]
	qdel(query)
