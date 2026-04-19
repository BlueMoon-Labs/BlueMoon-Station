// Stuff that helps the TGUI player panel jobban section to work

GLOBAL_LIST_INIT(jobban_panel_data, list(
	list(
		"name" = "Command",
		"color" = "yellow",
		"roles" = GLOB.command_positions
	),
	list(
		"name" = "Security",
		"color" = "red",
		"roles" = GLOB.security_positions
	),
	list(
		"name" = "Engineering",
		"color" = "orange",
		"roles" = GLOB.engineering_positions
	),
	list(
		"name" = "Medical",
		"color" = "blue",
		"roles" = GLOB.medical_positions
	),
	list(
		"name" = "Science",
		"color" = "violet",
		"roles" = GLOB.science_positions
	),
	list(
		"name" = "Supply",
		"color" = "brown",
		"roles" = GLOB.supply_positions
	),
	list(
		"name" = "Service",
		"color" = "green",
		"roles" = GLOB.civilian_positions
	),
	list(
		"name" = "Law",
		"color" = "purple",
		"roles" = GLOB.law_positions
	),
	list(
		"name" = "Silicon",
		"color" = "purple",
		"roles" = GLOB.nonhuman_positions
	),
	list(
		"name" = "Ghost Roles",
		"color" = "teal",
		"roles" = list(
			ROLE_PAI,
			ROLE_POSIBRAIN,
			ROLE_DRONE,
			ROLE_DEATHSQUAD,
			ROLE_LAVALAND,
			ROLE_GHOSTCAFE,
			ROLE_SENTIENCE,
			ROLE_MIND_TRANSFER
			)
	),
	list(
		"name" = "Antagonists",
		"color" = "red",
		"roles" = list(
			ROLE_TRAITOR,
			ROLE_CHANGELING,
			ROLE_HERETIC,
			ROLE_OPERATIVE,
			ROLE_REV,
			ROLE_CULTIST,
			ROLE_SERVANT_OF_RATVAR,
			ROLE_WIZARD,
			ROLE_ABDUCTOR,
			ROLE_ALIEN,
			ROLE_FAMILIES,
			ROLE_BLOODSUCKER,
			ROLE_SLAVER,
			ROLE_INTEQ
			)
	),
	list(
		"name" = "Other",
		"color" = "red",
		"roles" = list(
		"pacifist",
		"appearance",
		"emote",
		"OOC",
		"ahelp",
		"deadchat",
		ROLE_RESPAWN
		)
	)
))

/datum/admins/proc/get_jobban_flat_roles()
	. = list()
	for(var/list/cat in GLOB.jobban_panel_data)
		for(var/r in cat["roles"])
			. += r

/// Active JOB_PERMA / JOB_TEMP rows for this ckey (for panel checkboxes).
/datum/admins/proc/get_active_job_bans_for_ckey(target_ckey)
	. = list()
	if(!target_ckey || !SSdbcore.Connect())
		return
	var/datum/db_query/q = SSdbcore.NewQuery({"
		SELECT DISTINCT job FROM [format_table_name("ban")]
		WHERE ckey = :ckey
		AND (bantype = 'JOB_PERMABAN' OR (bantype = 'JOB_TEMPBAN' AND expiration_time > Now()))
		AND (unbanned is null OR unbanned = false)
		AND job IS NOT NULL AND job != ''
	"}, list("ckey" = target_ckey))
	if(!q.warn_execute())
		qdel(q)
		return
	while(q.NextRow())
		. += q.item[1]
	qdel(q)

/datum/admins/proc/build_jobban_checkbox_section(playerckey_for_state = null)
	var/list/banned_roles = list()
	if(playerckey_for_state)
		banned_roles = get_active_job_bans_for_ckey(ckey(playerckey_for_state))
	var/out = ""
	out += "<div class='ban-role-toolbar'>"
	out += "<button type='button' class='ban-btn' onclick='banpanel_select_all_except_other()'>Забанить всё, кроме Other</button>"
	out += "<button type='button' class='ban-btn ban-btn-unban' onclick='banpanel_unban_all_except_other()'>Разбанить всё, кроме Other</button>"
	out += "<span class='ban-panel-hint'> — бан: JOB PERMA/TEMP + <b>Add ban</b>; разбан: снять галочки + <b>Снять джоббаны</b>.</span>"
	if(length(banned_roles))
		out += "<br><span class='ban-panel-hint'>Активные джоббаны по Key уже отмечены. Снимите галочки и нажмите <b>Снять джоббаны</b> (как на WhiteMoon).</span>"
	out += "</div>"
	out += "<div class='ban-role-row'>"
	var/idx = 0
	for(var/list/cat in GLOB.jobban_panel_data)
		var/cat_name = cat["name"]
		var/ccls = ckey(cat_name)
		var/is_other = (ccls == "other")
		out += "<div class='banrole-column[is_other ? " ban-cat-other" : ""]'>"
		out += "<div class='rolegroup [ccls]'>"
		out += "<label class='cat-head'><input type='checkbox' data-cat='[ccls]' onclick='header_click_all_checkboxes(this)' /> <b>[html_encode(cat_name)]</b></label>"
		out += "<div class='content'>"
		for(var/r in cat["roles"])
			idx++
			var/is_banned = (r in banned_roles)
			var/checked = is_banned ? " checked" : ""
			var/banned_cls = is_banned ? " jr_label_banned" : ""
			out += "<label class='jr_label[banned_cls]'><input type='checkbox' class='jr_cb [ccls]' name='jr_[idx]' value='[idx]'[checked] /> [html_encode(r)]</label>"
			if(is_banned)
				out += "<input type='hidden' name='was_jr_[idx]' value='1'>"
		out += "</div></div></div>"
	out += "</div>"
	out += "<input type='hidden' name='jr_max' value='[idx]'>"
	return out

// notbannedlist is just a list of strings of the job titles you want to ban.
/datum/admins/proc/Jobban(mob/M, list/notbannedlist)
	if (!check_rights(R_BAN))
		to_chat(usr, "Error: You do not have sufficient admin rights to ban players.")
		return

	var/target_key = M.key || M.mind?.key || resolve_mob_ban_ckey(M)
	if(!target_key)
		to_chat(usr, "<span class='danger'>Cannot resolve player key for job ban.</span>")
		return

	var/severity = null
	var/reason = null

	switch(tgui_alert(usr, "Job ban type", buttons = list("Temporary", "Permanent", "Cancel")))
		if("Temporary")
			var/mins = input(usr,"How long (in minutes)?","Ban time",1440) as num|null
			if(mins <= 0)
				to_chat(usr, "<span class='danger'>[mins] is not a valid duration.</span>")
				return
			reason = input(usr,"Please State Reason For Banning [target_key].","Reason") as message|null
			if(!reason)
				return
			severity = tgui_alert(usr, "Set the severity of the note/ban", buttons = list("High", "Medium", "Minor", "None"))
			if(!severity)
				return
			var/msg
			for(var/job in notbannedlist)
				if(DB_ban_record(BANTYPE_JOB_TEMP, M, mins, reason, job) != TRUE)
					to_chat(usr, "<span class='danger'>Failed to apply ban.</span>")
					return
				if(M.client)
					jobban_buildcache(M.client)
				ban_unban_log_save("[key_name(usr)] temp-jobbanned [key_name(M)] from [job] for [mins] minutes. reason: [reason]")
				log_admin_private("[key_name(usr)] temp-jobbanned [key_name(M)] from [job] for [mins] minutes.")
				if(!msg)
					msg = job
				else
					msg += ", [job]"
			create_message("note", target_key, null, "Banned  from [msg] - [reason]", null, null, 0, 0, null, 0, severity, dont_announce_to_events = TRUE)
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] banned [key_name_admin(M)] from [msg] for [mins] minutes.</span>")
			if(M.client)
				to_chat(M, "<span class='boldannounce'><BIG>You have been [((msg == "ooc") || (msg == "appearance") || (msg == "pacifist")) ? "banned" : "jobbanned"] by [usr.client.key] from: [msg == "pacifist" ? "using violence" : msg].</BIG></span>")
				to_chat(M, "<span class='boldannounce'>The reason is: [reason]</span>")
				to_chat(M, "<span class='danger'>This jobban will be lifted in [mins] minutes.</span>")

			GLOB.bot_event_sending_que += list(list(
				"type" = "ban_a",
				"title" = "Блокировка",
				"player" = target_key,
				"admin" = usr.key,
				"reason" = reason,
				"banduration" = mins,
				"bantimestamp" = SQLtime(),
				"additional_info" = list("ban_job" = msg),
				"round" = GLOB.round_id
			))

		if("Permanent")
			reason = input(usr,"Please State Reason For Banning [target_key].","Reason") as message|null
			if (!reason)
				return
			severity = tgui_alert(usr, "Please State Reason For Banning", buttons = list("High", "Medium", "Minor", "None"))
			if (!severity)
				return

			var/msg
			for(var/job in notbannedlist)
				if(DB_ban_record(BANTYPE_JOB_PERMA, M, -1, reason, job) != TRUE)
					to_chat(usr, "<span class='danger'>Failed to apply ban.</span>")
					return
				if(M.client)
					jobban_buildcache(M.client)
				ban_unban_log_save("[key_name(usr)] perma-jobbanned [key_name(M)] from [job]. reason: [reason]")
				log_admin_private("[key_name(usr)] perma-banned [key_name(M)] from [job]")
				if(!msg)
					msg = job
				else
					msg += ", [job]"
			create_message("note", target_key, null, "Banned  from [msg] - [reason]", null, null, 0, 0, null, 0, severity, dont_announce_to_events = TRUE)
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] banned [key_name(M)] from [msg].</span>")
			if(M.client)
				to_chat(M, "<span class='boldannounce'><BIG>You have been [((msg == "ooc") || (msg == "appearance") || (msg == "pacifist")) ? "banned" : "jobbanned"] by [usr.client.key] from: [msg == "pacifist" ? "using violence" : msg].</BIG></span>")
				to_chat(M, "<span class='boldannounce'>The reason is: [reason]</span>")
				to_chat(M, "<span class='danger'>This jobban can be lifted only upon request.</span>")

			GLOB.bot_event_sending_que += list(list(
				"type" = "ban_a",
				"title" = "Пермаментная Блокировка",
				"player" = target_key,
				"admin" = usr.key,
				"reason" = reason,
				"banduration" = null,
				"bantimestamp" = SQLtime(),
				"additional_info" = list("ban_job" = msg),
				"round" = GLOB.round_id
			))

// notbannedlist is just a list of strings of the job titles you want to unban.
/datum/admins/proc/UnJobban(mob/M, list/bannedlist)

	if (!check_rights(R_BAN))
		to_chat(usr, "Error: You do not have sufficient admin rights to unban players.")
		return

	var/target_ckey = resolve_mob_ban_ckey(M)
	if(!target_ckey)
		to_chat(usr, "<span class='danger'>Cannot resolve player ckey for un-jobban.</span>")
		return

	var/msg
	for(var/job in bannedlist)
		var/reason = jobban_isbanned(M, job)
		if (tgui_alert(usr, "Job: '[job]' Ban reason: '[reason]'", "Un-Jobban This Player?", list("Yes", "No")) == "Yes")
			ban_unban_log_save("[key_name(usr)] unjobbanned [key_name(M)] from [job]")
			log_admin_private("[key_name(usr)] unbanned [key_name(M)] from [job]")
			DB_ban_unban(target_ckey, BANTYPE_ANY_JOB, job)
			if(M.client)
				jobban_buildcache(M.client)
			if(!msg)
				msg = job
			else
				msg += ", [job]"
	if(msg)
		message_admins("<span class='adminnotice'>[key_name_admin(usr)] unbanned [key_name(M)] from [msg].</span>")
		if(M.client)
			to_chat(M, "<span class='boldannounce'><BIG>You have been un-jobbanned by [usr.client.key] from [msg].</BIG></span>")
		GLOB.bot_event_sending_que += list(list(
			"type" = "unban_a",
			"title" = "Снятие блокировки",
			"player" = M.key || M.mind?.key || target_ckey,
			"admin" = usr.key,
			"additional_info" = list("ban_job" = msg),
			"round" = GLOB.round_id
		))
