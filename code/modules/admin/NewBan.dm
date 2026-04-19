GLOBAL_VAR(CMinutes)
GLOBAL_DATUM(Banlist, /savefile)
GLOBAL_PROTECT(Banlist)


/proc/CheckBan(ckey, id, address)
	if(!GLOB.Banlist)		// if Banlist cannot be located for some reason
		LoadBans()		// try to load the bans
		if(!GLOB.Banlist)	// uh oh, can't find bans!
			return FALSE	// ABORT ABORT ABORT

	. = list()
	var/appeal
	var/bran = CONFIG_GET(string/banappeals)
	if(bran)
		appeal = "\nFor more information on your ban, or to appeal, head to <a href='[bran]'>[bran]</a>"
	GLOB.Banlist.cd = "/base"
	if( "[ckey][id]" in GLOB.Banlist.dir )
		GLOB.Banlist.cd = "[ckey][id]"
		if (GLOB.Banlist["temp"])
			if (!GetExp(GLOB.Banlist["minutes"]))
				ClearTempbans()
				return FALSE
			else
				.["desc"] = "\nReason: [GLOB.Banlist["reason"]]\nExpires: [GetExp(GLOB.Banlist["minutes"])]\nBy: [GLOB.Banlist["bannedby"]] during round ID [GLOB.Banlist["roundid"]][appeal]"
		else
			GLOB.Banlist.cd	= "/base/[ckey][id]"
			.["desc"]	= "\nReason: [GLOB.Banlist["reason"]]\nExpires: <B>PERMANENT</B>\nBy: [GLOB.Banlist["bannedby"]] during round ID [GLOB.Banlist["roundid"]][appeal]"
		.["reason"]	= "ckey/id"
		return .
	else
		for (var/A in GLOB.Banlist.dir)
			GLOB.Banlist.cd = "/base/[A]"
			var/matches
			if( ckey == GLOB.Banlist["key"] )
				matches += "ckey"
			if( id == GLOB.Banlist["id"] )
				if(matches)
					matches += "/"
				matches += "id"
			if( address == GLOB.Banlist["ip"] )
				if(matches)
					matches += "/"
				matches += "ip"

			if(matches)
				if(GLOB.Banlist["temp"])
					if (!GetExp(GLOB.Banlist["minutes"]))
						ClearTempbans()
						return FALSE
					else
						.["desc"] = "\nReason: [GLOB.Banlist["reason"]]\nExpires: [GetExp(GLOB.Banlist["minutes"])]\nBy: [GLOB.Banlist["bannedby"]] during round ID [GLOB.Banlist["roundid"]][appeal]"
				else
					.["desc"] = "\nReason: [GLOB.Banlist["reason"]]\nExpires: <B>PERMENANT</B>\nBy: [GLOB.Banlist["bannedby"]] during round ID [GLOB.Banlist["roundid"]][appeal]"
				.["reason"] = matches
				return .
	return FALSE

/proc/UpdateTime() //No idea why i made this a proc.
	GLOB.CMinutes = (world.realtime / 10) / 60
	return TRUE

/proc/LoadBans()
	if(!CONFIG_GET(flag/ban_legacy_system))
		return

	var/banlist_path = "data/banlist.bdb"
	var/banlist_lock_path = "[banlist_path].lk"
	if(fexists(banlist_lock_path))
		fdel(banlist_lock_path)

	try
		GLOB.Banlist = new /savefile(banlist_path)
	catch(var/exception/e)
		stack_trace("LoadBans(): failed to open legacy banlist [banlist_path]: [e]. Recreating savefile.")
		log_admin("Legacy banlist savefile is invalid; attempting to recreate [banlist_path].")
		if(fexists(banlist_lock_path))
			fdel(banlist_lock_path)
		if(fexists(banlist_path))
			var/banlist_backup_path = "[banlist_path].corrupt"
			if(fexists(banlist_backup_path))
				fdel(banlist_backup_path)
			fcopy(banlist_path, banlist_backup_path)
			fdel(banlist_path)
		try
			GLOB.Banlist = new /savefile(banlist_path)
		catch(var/exception/recreate_error)
			stack_trace("LoadBans(): failed to recreate legacy banlist [banlist_path]: [recreate_error]")
			log_admin("Failed to recreate legacy banlist savefile.")
			return FALSE
	log_admin("Loading Banlist")

	if (!length(GLOB.Banlist.dir))
		log_admin("Banlist is empty.")

	if (!GLOB.Banlist.dir.Find("base"))
		log_admin("Banlist missing base dir.")
		GLOB.Banlist.dir.Add("base")
		GLOB.Banlist.cd = "/base"
	else if (GLOB.Banlist.dir.Find("base"))
		GLOB.Banlist.cd = "/base"

	ClearTempbans()
	return TRUE

/proc/ClearTempbans()
	UpdateTime()

	GLOB.Banlist.cd = "/base"
	for (var/A in GLOB.Banlist.dir)
		GLOB.Banlist.cd = "/base/[A]"
		if (!GLOB.Banlist["key"] || !GLOB.Banlist["id"])
			RemoveBan(A)
			log_admin("Invalid Ban.")
			message_admins("Invalid Ban.")
			continue

		if (!GLOB.Banlist["temp"])
			continue
		if (GLOB.CMinutes >= GLOB.Banlist["minutes"])
			RemoveBan(A)

	return TRUE


/proc/AddBan(key, computerid, reason, bannedby, temp, minutes, address)

	var/bantimestamp
	var/ban_ckey = ckey(key)
	if (temp)
		UpdateTime()
		bantimestamp = GLOB.CMinutes + minutes

	GLOB.Banlist.cd = "/base"
	if ( GLOB.Banlist.dir.Find("[ban_ckey][computerid]") )
		to_chat(usr, text("<span class='danger'>Ban already exists.</span>"))
		return FALSE
	else
		GLOB.Banlist.dir.Add("[ban_ckey][computerid]")
		GLOB.Banlist.cd = "/base/[ban_ckey][computerid]"
		WRITE_FILE(GLOB.Banlist["key"], ban_ckey)
		WRITE_FILE(GLOB.Banlist["id"], computerid)
		WRITE_FILE(GLOB.Banlist["ip"], address)
		WRITE_FILE(GLOB.Banlist["reason"], reason)
		WRITE_FILE(GLOB.Banlist["bannedby"], bannedby)
		WRITE_FILE(GLOB.Banlist["temp"], temp)
		WRITE_FILE(GLOB.Banlist["roundid"], GLOB.round_id)
		if (temp)
			WRITE_FILE(GLOB.Banlist["minutes"], bantimestamp)
		if(!temp)
			create_message("note", key, bannedby, "Permanently banned - [reason]", null, null, 0, 0, null, 0, 0, dont_announce_to_events = TRUE)
		else
			create_message("note", key, bannedby, "Banned for [minutes] minutes - [reason]", null, null, 0, 0, null, 0, 0, dont_announce_to_events = TRUE)

	GLOB.bot_event_sending_que += list(list(
		"type" = "ban",
		"player" = ban_ckey,
		"admin" = bannedby,
		"reason" = reason,
		"banduration" = minutes,
		"bantimestamp" = SQLtime(),
		"round" = GLOB.round_id,
		"temp" = temp
	))

	return TRUE

/proc/RemoveBan(foldername)
	var/key
	var/id

	GLOB.Banlist.cd = "/base/[foldername]"
	GLOB.Banlist["key"] >> key
	GLOB.Banlist["id"] >> id
	GLOB.Banlist.cd = "/base"

	if (!GLOB.Banlist.dir.Remove(foldername))
		return FALSE

	if(!usr)
		log_admin_private("Ban Expired: [key]")
		message_admins("Ban Expired: [key]")
	else
		ban_unban_log_save("[key_name(usr)] unbanned [key]")
		log_admin_private("[key_name(usr)] unbanned [key]")
		message_admins("[key_name_admin(usr)] unbanned: [key]")
		usr.client.holder.DB_ban_unban( ckey(key), BANTYPE_ANY_FULLBAN)
	for (var/A in GLOB.Banlist.dir)
		GLOB.Banlist.cd = "/base/[A]"
		if (key == GLOB.Banlist["key"] /*|| id == Banlist["id"]*/)
			GLOB.Banlist.cd = "/base"
			GLOB.Banlist.dir.Remove(A)
			continue

	GLOB.bot_event_sending_que += list(list(
		"type" = "unban",
		"player" = key,
		"admin" = usr ? usr.key : null,
		"round" = GLOB.round_id
	))

	return TRUE

/proc/GetExp(minutes as num)
	UpdateTime()
	var/exp = minutes - GLOB.CMinutes
	if (exp <= 0)
		return FALSE
	else
		var/timeleftstring
		if (exp >= 1440) //1440 = 1 day in minutes
			timeleftstring = "[round(exp / 1440, 0.1)] Days"
		else if (exp >= 60) //60 = 1 hour in minutes
			timeleftstring = "[round(exp / 60, 0.1)] Hours"
		else
			timeleftstring = "[exp] Minutes"
		return timeleftstring

/datum/admins/proc/unbanpanel()
	if(!GLOB.Banlist)
		to_chat(usr, "<span class='danger'>Legacy banlist is not loaded.</span>")
		return

	var/count = 0
	var/dat = ""
	GLOB.Banlist.cd = "/base"
	for (var/A in GLOB.Banlist.dir)
		count++
		GLOB.Banlist.cd = "/base/[A]"
		var/ref		= "[REF(src)]"
		var/key		= GLOB.Banlist["key"]
		var/id		= GLOB.Banlist["id"]
		var/ip		= GLOB.Banlist["ip"]
		var/reason	= GLOB.Banlist["reason"]
		var/by		= GLOB.Banlist["bannedby"]
		var/expiry
		if(GLOB.Banlist["temp"])
			expiry = GetExp(GLOB.Banlist["minutes"])
			if(!expiry)
				expiry = "Removal Pending"
		else
			expiry = "Permaban"

		dat += "<tr><td><a href='?src=[ref];unbanf=[key][id]'>(U) Unban</a> <a href='?src=[ref];unbane=[key][id]'>(E) Edit</a></td><td><b>[key]</b></td><td>[id]</td><td>[ip]</td><td>[expiry]</td><td>[by]</td><td>[reason]</td></tr>"

	if(!count)
		dat = "<tr><td colspan='7' class='legacy-unban-empty'>No entries in the legacy banlist (data/banlist.bdb). This is normal for a fresh local server.</td></tr>"
	else
		dat = "<thead><tr><th>Actions</th><th>Key</th><th>Computer ID</th><th>IP</th><th>Expires</th><th>Banned by</th><th>Reason</th></tr></thead><tbody>[dat]</tbody>"

	var/html = {"<div class='ban-panel-wrap'><div class='ban-panel-main legacy-unban-main'>"}
	html += "<div class='ban-panel-add-card'><h2>Legacy unban panel</h2>"
	html += "<div class='ban-panel-hint'>Uses the local savefile banlist (<b>data/banlist.bdb</b>), not the SQL <b>ban</b> table. For full DB search/unban, disable <b>ban_legacy_system</b> and connect MySQL.</div>"
	html += "<div style='margin-top:8px;color:#98b0c3;font-size:11px'><b>(U)</b> = Unban &nbsp; <b>(E)</b> = Edit — <span style='color:#6dcc7a'>[count] ban[count == 1 ? "" : "s"]</span></div></div>"
	html += "<table class='legacy-ban-table'>[dat]</table>"
	html += "</div></div>"

	var/datum/browser/popup = new(usr, "unbanp", "Unban Panel", 900, 520)
	popup.add_stylesheet("unbanpanelcss", 'html/admin/unbanpanel.css')
	popup.add_stylesheet("banlookupcss", 'html/admin/banlookup.css')
	popup.set_content(html)
	popup.open(FALSE)

//////////////////////////////////// DEBUG ////////////////////////////////////

/proc/CreateBans()

	UpdateTime()

	var/i
	var/last

	for(i=0, i<1001, i++)
		var/a = pick(1,0)
		var/b = pick(1,0)
		if(b)
			GLOB.Banlist.cd = "/base"
			GLOB.Banlist.dir.Add("trash[i]trashid[i]")
			GLOB.Banlist.cd = "/base/trash[i]trashid[i]"
			WRITE_FILE(GLOB.Banlist["key"], "trash[i]")
		else
			GLOB.Banlist.cd = "/base"
			GLOB.Banlist.dir.Add("[last]trashid[i]")
			GLOB.Banlist.cd = "/base/[last]trashid[i]"
			WRITE_FILE(GLOB.Banlist["key"], last)
		WRITE_FILE(GLOB.Banlist["id"], "trashid[i]")
		WRITE_FILE(GLOB.Banlist["reason"], "Trashban[i].")
		WRITE_FILE(GLOB.Banlist["temp"], a)
		WRITE_FILE(GLOB.Banlist["minutes"], GLOB.CMinutes + rand(1,2000))
		WRITE_FILE(GLOB.Banlist["bannedby"], "trashmin")
		last = "trash[i]"

	GLOB.Banlist.cd = "/base"

/proc/ClearAllBans()
	GLOB.Banlist.cd = "/base"
	for (var/A in GLOB.Banlist.dir)
		RemoveBan(A)
