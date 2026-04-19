#define MAX_ADMIN_BANS_PER_ADMIN 1
#define MAX_ADMIN_BANS_PER_HEADMIN 3

//Either pass the mob you wish to ban in the 'banned_mob' attribute, or the banckey, banip and bancid variables. If both are passed, the mob takes priority! If a mob is not passed, banckey is the minimum that needs to be passed! banip and bancid are optional.
/datum/admins/proc/DB_ban_record(bantype, mob/banned_mob, duration = -1, reason, job = "", bankey = null, banip = null, bancid = null, forced_holder = FALSE, suppress_feedback = FALSE)

	if(!forced_holder && !check_rights(R_BAN))
		return "Not enough rights"

	if(!SSdbcore.Connect())
		to_chat(src, "<span class='danger'>Failed to establish database connection.</span>")
		return "DB Connect issue"

	var/bantype_pass = 0
	var/bantype_str
	var/maxadminbancheck	//Used to limit the number of active bans of a certein type that each admin can give. Used to protect against abuse or mutiny.
	var/announceinirc		//When set, it announces the ban in irc. Intended to be a way to raise an alarm, so to speak.
	var/blockselfban		//Used to prevent the banning of yourself.
	var/kickbannedckey		//Defines whether this proc should kick the banned person, if they are connected (if banned_mob is defined).
							//some ban types kick players after this proc passes (tempban, permaban), but some are specific to db_ban, so
							//they should kick within this proc.
	switch(bantype)
		if(BANTYPE_PERMA)
			bantype_str = "PERMABAN"
			duration = -1
			bantype_pass = 1
			blockselfban = 1
		if(BANTYPE_TEMP)
			bantype_str = "TEMPBAN"
			bantype_pass = 1
			blockselfban = 1
		if(BANTYPE_JOB_PERMA)
			bantype_str = "JOB_PERMABAN"
			duration = -1
			bantype_pass = 1
		if(BANTYPE_JOB_TEMP)
			bantype_str = "JOB_TEMPBAN"
			bantype_pass = 1
		if(BANTYPE_ADMIN_PERMA)
			bantype_str = "ADMIN_PERMABAN"
			duration = -1
			bantype_pass = 1
			maxadminbancheck = 1
			announceinirc = 1
			blockselfban = 1
			kickbannedckey = 1
		if(BANTYPE_ADMIN_TEMP)
			bantype_str = "ADMIN_TEMPBAN"
			bantype_pass = 1
			maxadminbancheck = 1
			announceinirc = 1
			blockselfban = 1
			kickbannedckey = 1
		if(BANTYPE_PACIFIST)
			bantype_str = "PACIFICATION_BAN"
			bantype_pass = 1
	if( !bantype_pass )
		return "Wrong ban type"
	if( !istext(reason) )
		return "Not given reason"
	if( !isnum(duration) )
		return "Not given duration"

	var/ckey
	var/computerid
	var/ip

	if(ismob(banned_mob))
		ckey = banned_mob.ckey
		bankey = banned_mob.key
		if(!ckey && banned_mob.mind?.key)
			ckey = ckey(banned_mob.mind.key)
			bankey = banned_mob.mind.key
		if(!ckey)
			return "No ckey"
		if(banned_mob.client)
			computerid = banned_mob.client.computer_id
			ip = banned_mob.client.address
		else
			computerid = banned_mob.computer_id
			ip = banned_mob.lastKnownIP
	else if(bankey)
		ckey = ckey(bankey)
		computerid = bancid
		ip = banip

	var/had_banned_mob = banned_mob != null
	var/client/banned_client = banned_mob?.client
	var/guest_check_key = had_banned_mob && (banned_mob.key || banned_mob.mind?.key)
	var/banned_mob_guest_key = guest_check_key && IsGuestKey(guest_check_key)
	banned_mob = null
	var/datum/db_query/query_add_ban_get_ckey = SSdbcore.NewQuery({"
		SELECT 1
		FROM [format_table_name("player")]
		WHERE ckey = :ckey"},
		list("ckey" = ckey))
	if(!query_add_ban_get_ckey.warn_execute())
		qdel(query_add_ban_get_ckey)
		return "Failed DB get key"
	var/seen_before = query_add_ban_get_ckey.NextRow()
	qdel(query_add_ban_get_ckey)
	if(!seen_before)
		if(!had_banned_mob || (had_banned_mob && !banned_mob_guest_key))
			if(!forced_holder && alert(usr, "[bankey] has not been seen before, are you sure you want to create a ban for them?", "Unknown ckey", "Yes", "No", "Cancel") != "Yes")
				return "Canceled"

	var/a_key
	var/a_ckey
	var/a_computerid
	var/a_ip

	if(istype(owner))
		a_key = owner.key
		a_ckey = owner.ckey
		a_computerid = owner.computer_id
		a_ip = owner.address

	if(forced_holder)
		a_key = "DISCORD BAN PASSTHRU"
		a_ckey = "DISCORD BAN PASSTHRU"
		a_computerid = "0"
		a_ip = "0.0.0.0"

	if(blockselfban)
		if(a_ckey == ckey)
			to_chat(usr, "<span class='danger'>You cannot apply this ban type on yourself.</span>")
			return "Self ban restricted"

	var/who
	for(var/client/C in GLOB.clients)
		if(!who)
			who = "[C]"
		else
			who += ", [C]"

	var/adminwho
	for(var/client/C in GLOB.admins)
		if(!adminwho)
			adminwho = "[C]"
		else
			adminwho += ", [C]"

	if(maxadminbancheck)
		var/datum/db_query/query_check_adminban_amt = SSdbcore.NewQuery({"
			SELECT count(id) AS num FROM [format_table_name("ban")]
			WHERE (a_ckey = :a_ckey) AND (bantype = 'ADMIN_PERMABAN'  OR (bantype = 'ADMIN_TEMPBAN' AND expiration_time > Now())) AND isnull(unbanned)
			"}, list("a_ckey" = a_ckey))
		if(!query_check_adminban_amt.warn_execute())
			qdel(query_check_adminban_amt)
			return "Failed DB admin ban amt run"
		if(query_check_adminban_amt.NextRow())
			var/adm_bans = text2num(query_check_adminban_amt.item[1])
			var/max_bans = MAX_ADMIN_BANS_PER_ADMIN
			if (check_rights(R_PERMISSIONS, FALSE))
				max_bans = MAX_ADMIN_BANS_PER_HEADMIN
			if(adm_bans >= max_bans)
				to_chat(usr, "<span class='danger'>You already logged [max_bans] admin ban(s) or more. Do not abuse this function!</span>")
				qdel(query_check_adminban_amt)
				return "Overlimit admin bans"
		qdel(query_check_adminban_amt)
	if(!computerid)
		computerid = "0"
	if(!ip)
		ip = "0.0.0.0"
	var/datum/db_query/query_add_ban = SSdbcore.NewQuery({"
		INSERT INTO [format_table_name("ban")] (`bantime`,`server_ip`,`server_port`,`round_id`,`bantype`,`reason`,`job`,`duration`,`expiration_time`,`ckey`,`computerid`,`ip`,`a_ckey`,`a_computerid`,`a_ip`,`who`,`adminwho`)
		VALUES (Now(), INET_ATON(:internet_address), :port, :round_id, :bantype_str, :reason, :job, :duration, Now() + INTERVAL :expiration_time MINUTE, :ckey, :computerid, INET_ATON(:ip), :a_ckey, :a_computerid, INET_ATON(:a_ip), :who, :adminwho)
		"}, list("internet_address" = world.internet_address ? world.internet_address : 0,
		"port" = world.port, "round_id" = GLOB.round_id, "bantype_str" = bantype_str, "reason" = reason,
		"job" = job, "duration" = duration ? "[duration]":"0", "expiration_time" = (duration > 0) ? duration : 0,
		"ckey" = ckey, "computerid" = computerid, "ip" = ip,
		"a_ckey" = a_ckey, "a_computerid" = a_computerid, "a_ip" = a_ip, "who" = who, "adminwho" = adminwho
		))
	if(!query_add_ban.warn_execute())
		qdel(query_add_ban)
		return "Failed to add ban"
	qdel(query_add_ban)
	var/datum/admin_help/AH = null
	if(!suppress_feedback)
		to_chat(usr, "<span class='adminnotice'>Ban saved to database.</span>")
		var/msg = "[key_name_admin(usr)] has added a [bantype_str] for [bankey] [(job)?"([job])":""] [(duration > 0)?"([duration] minutes)":""] with the reason: \"[reason]\" to the ban database."
		message_admins(msg,1)
		AH = admin_ticket_log(ckey, msg)

	if(announceinirc)
		send2adminchat("BAN ALERT","[a_key] applied a [bantype_str] on [bankey]")
	//splurt edit
	if(((bantype_str == "PACIFICATION_BAN") || (job == "pacifist")) && banned_client?.mob)
		ADD_TRAIT(banned_client.mob, TRAIT_PACIFISM, "pacification ban")
	//

	if(kickbannedckey)
		if(AH)
			AH.Resolve()	//with prejudice
		if(banned_client && banned_client.ckey == ckey)
			qdel(banned_client)
	return TRUE

/datum/admins/proc/DB_ban_unban(ckey, bantype, job = "")

	if(!check_rights(R_BAN))
		return

	var/bantype_str
	if(bantype)
		var/bantype_pass = 0
		switch(bantype)
			if(BANTYPE_PERMA)
				bantype_str = "PERMABAN"
				bantype_pass = 1
			if(BANTYPE_TEMP)
				bantype_str = "TEMPBAN"
				bantype_pass = 1
			if(BANTYPE_JOB_PERMA)
				bantype_str = "JOB_PERMABAN"
				bantype_pass = 1
			if(BANTYPE_JOB_TEMP)
				bantype_str = "JOB_TEMPBAN"
				bantype_pass = 1
			if(BANTYPE_ADMIN_PERMA)
				bantype_str = "ADMIN_PERMABAN"
				bantype_pass = 1
			if(BANTYPE_ADMIN_TEMP)
				bantype_str = "ADMIN_TEMPBAN"
				bantype_pass = 1
			if(BANTYPE_ANY_FULLBAN)
				bantype_str = "ANY"
				bantype_pass = 1
			if(BANTYPE_ANY_JOB)
				bantype_str = "ANYJOB"
				bantype_pass = 1
			if(BANTYPE_PACIFIST)
				bantype_str = "PACIFICATION_BAN"
				bantype_pass = 1
		if( !bantype_pass )
			return

	var/bantype_sql
	if(bantype_str == "ANY")
		bantype_sql = "(bantype = 'PERMABAN' OR (bantype = 'TEMPBAN' AND expiration_time > Now() ) )"
	else if(bantype_str == "ANYJOB")
		bantype_sql = "(bantype = 'JOB_PERMABAN' OR (bantype = 'JOB_TEMPBAN' AND expiration_time > Now() ) )"
	else
		bantype_sql = "bantype = '[bantype_str]'"
	var/sql = "SELECT id FROM [format_table_name("ban")] WHERE ckey = :ckey AND [bantype_sql] AND (unbanned is null OR unbanned = false)"
	var/list/sql_args = list("ckey" = ckey)
	if(job)
		sql += " AND job = :job"
		sql_args["job"] = job

	if(!SSdbcore.Connect())
		return

	var/ban_id
	var/ban_number = 0 //failsafe

	var/datum/db_query/query_unban_get_id = SSdbcore.NewQuery(sql, sql_args)
	if(!query_unban_get_id.warn_execute())
		qdel(query_unban_get_id)
		return
	while(query_unban_get_id.NextRow())
		ban_id = query_unban_get_id.item[1]
		ban_number++;
	qdel(query_unban_get_id)

	if(ban_number == 0)
		to_chat(usr, "<span class='danger'>Database update failed due to no bans fitting the search criteria. If this is not a legacy ban you should contact the database admin.</span>")
		return

	if(ban_number > 1)
		to_chat(usr, "<span class='danger'>Database update failed due to multiple bans fitting the search criteria. Note down the ckey, job and current time and contact the database admin.</span>")
		return

	if(istext(ban_id))
		ban_id = text2num(ban_id)
	if(!isnum(ban_id))
		to_chat(usr, "<span class='danger'>Database update failed due to a ban ID mismatch. Contact the database admin.</span>")
		return

	DB_ban_unban_by_id(ban_id)

/datum/admins/proc/DB_ban_edit(banid = null, param = null)

	if(!check_rights(R_BAN))
		return

	if(!isnum(banid) || !istext(param))
		to_chat(usr, "Cancelled")
		return

	var/datum/db_query/query_edit_ban_get_details = SSdbcore.NewQuery("SELECT IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].ckey), ckey), duration, reason FROM [format_table_name("ban")] WHERE id = [banid]")
	if(!query_edit_ban_get_details.warn_execute())
		qdel(query_edit_ban_get_details)
		return

	var/e_key = usr.key	//Editing admin key
	var/p_key				//(banned) Player key
	var/duration			//Old duration
	var/reason				//Old reason

	if(query_edit_ban_get_details.NextRow())
		p_key = query_edit_ban_get_details.item[1]
		duration = query_edit_ban_get_details.item[2]
		reason = query_edit_ban_get_details.item[3]
	else
		to_chat(usr, "Invalid ban id. Contact the database admin")
		qdel(query_edit_ban_get_details)
		return
	qdel(query_edit_ban_get_details)

	var/value

	switch(param)
		if("reason")
			if(!value)
				value = input("Insert the new reason for [p_key]'s ban", "New Reason", "[reason]", null) as null|text
				if(!value)
					to_chat(usr, "Cancelled")
					return

			var/datum/db_query/query_edit_ban_reason = SSdbcore.NewQuery("UPDATE [format_table_name("ban")] SET reason = '[value]', edits = CONCAT(edits,'- [e_key] changed ban reason from <cite><b>\\\"[reason]\\\"</b></cite> to <cite><b>\\\"[value]\\\"</b></cite><BR>') WHERE id = [banid]")
			if(!query_edit_ban_reason.warn_execute())
				qdel(query_edit_ban_reason)
				return
			qdel(query_edit_ban_reason)
			message_admins("[key_name_admin(usr)] has edited a ban for [p_key]'s reason from [reason] to [value]")
		if("duration")
			if(!value)
				value = input("Insert the new duration (in minutes) for [p_key]'s ban", "New Duration", "[duration]", null) as null|num
				if(!isnum(value) || !value)
					to_chat(usr, "Cancelled")
					return

			var/datum/db_query/query_edit_ban_duration = SSdbcore.NewQuery("UPDATE [format_table_name("ban")] SET duration = [value], edits = CONCAT(edits,'- [e_key] changed ban duration from [duration] to [value]<br>'), expiration_time = DATE_ADD(bantime, INTERVAL [value] MINUTE) WHERE id = [banid]")
			if(!query_edit_ban_duration.warn_execute())
				qdel(query_edit_ban_duration)
				return
			qdel(query_edit_ban_duration)
			message_admins("[key_name_admin(usr)] has edited a ban for [p_key]'s duration from [duration] to [value]")
		if("unban")
			if(alert("Unban [p_key]?", "Unban?", "Yes", "No") == "Yes")
				DB_ban_unban_by_id(banid)
				return
			else
				to_chat(usr, "Cancelled")
				return
		else
			to_chat(usr, "Cancelled")
			return

/datum/admins/proc/DB_ban_unban_by_id(id)

	if(!check_rights(R_BAN))
		return

	var/sql = "SELECT IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].ckey), ckey) FROM [format_table_name("ban")] WHERE id = [id]"

	if(!SSdbcore.Connect())
		return

	var/ban_number = 0 //failsafe

	var/p_key
	var/datum/db_query/query_unban_get_ckey = SSdbcore.NewQuery(sql)
	if(!query_unban_get_ckey.warn_execute())
		qdel(query_unban_get_ckey)
		return
	while(query_unban_get_ckey.NextRow())
		p_key = query_unban_get_ckey.item[1]
		ban_number++;
	qdel(query_unban_get_ckey)

	if(ban_number == 0)
		to_chat(usr, "<span class='danger'>Database update failed due to a ban id not being present in the database.</span>")
		return

	if(ban_number > 1)
		to_chat(usr, "<span class='danger'>Database update failed due to multiple bans having the same ID. Contact the database admin.</span>")
		return

	if(!istype(owner))
		return

	var/unban_ckey = owner.ckey
	var/unban_computerid = owner.computer_id
	var/unban_ip = owner.address

	var/sql_update = "UPDATE [format_table_name("ban")] SET unbanned = 1, unbanned_datetime = Now(), unbanned_ckey = '[unban_ckey]', unbanned_computerid = '[unban_computerid]', unbanned_ip = INET_ATON('[unban_ip]') WHERE id = [id]"
	var/datum/db_query/query_unban = SSdbcore.NewQuery(sql_update)
	if(!query_unban.warn_execute())
		qdel(query_unban)
		return
	qdel(query_unban)
	message_admins("[key_name_admin(usr)] has lifted [p_key]'s ban.")

	GLOB.bot_event_sending_que += list(list(
		"type" = "unban_a",
		"title" = "Разбан",
		"player" = p_key,
		"admin" = usr.key,
		"round" = GLOB.round_id,
	))

/client/proc/DB_ban_panel()
	set category = "Admin"
	set name = "Banning & Unbanning"
	set desc = "SQL ban lookup, custom ban, job role grid (WhiteMoon-style)"

	if(!holder)
		return

	holder.DB_ban_panel()


/datum/admins/proc/DB_ban_panel(playerckey, adminckey, ip, cid, page = 0)
	if(!usr.client)
		return

	if(!check_rights(R_BAN))
		return

	if(!SSdbcore.Connect())
		var/datum/browser/db_offline = new(usr, "lookupbans", "Banning & Unbanning", 920, 420)
		db_offline.add_stylesheet("unbanpanelcss", 'html/admin/unbanpanel.css')
		db_offline.add_stylesheet("banlookupcss", 'html/admin/banlookup.css')
		db_offline.set_content({"
			<div class='ban-panel-wrap'>
			<div class='ban-panel-main'>
			<div class='db-offline-notice'>
			<h2>Database not connected</h2>
			<div>SQL bans and search are unavailable until the server can connect to MySQL (check <b>dbconfig.txt</b> and that the DB service is running).</div>
			<div class='ban-panel-hint' style='margin-top:10px'>If your config uses the legacy banlist file instead, enable <b>ban_legacy_system</b> in game options for the old savefile-based panel (limited features).</div>
			</div>
			</div>
			</div>
		"})
		db_offline.open(FALSE)
		to_chat(usr, "<span class='danger'>Database not connected — opened offline notice panel.</span>")
		return

	var/output = "<div class='ban-panel-wrap'>"
	output += "<form method='GET' action='?src=[REF(src)]' class='searchbar'>"
	output += "<input type='hidden' name='src' value='[REF(src)]'>"
	output += HrefTokenFormField()
	output += "<b>Search</b> &mdash; Ckey: <input type='text' name='dbsearchckey' value='[playerckey]' size='18'>"
	output += " Admin: <input type='text' name='dbsearchadmin' value='[adminckey]' size='14'>"
	output += " IP: <input type='text' name='dbsearchip' value='[ip]' size='14'>"
	output += " CID: <input type='text' name='dbsearchcid' value='[cid]' size='12'>"
	output += "<input type='submit' value='Search'>"
	output += "</form>"
	output += "<div class='ban-panel-main'>"
	output += "<h1 class='ban-lookup-title'>Ban Lookup</h1>"
	output += "<div class='ban-panel-add-card'>"
	output += "<h2>Custom ban</h2>"
	output += "<div class='ban-panel-hint'>Use only if you cannot use the player panel or another in-game flow. Job bans apply next round.</div>"
	output += "<div class='ban-panel-hint'>Для JOB PERMA / JOB TEMP: отметьте роли ниже или выберите одну в списке Job. Снятие джоббанов: укажите Key (или найдите игрока поиском), снимите галочки с ролей, затем «Снять джоббаны».</div>"
	output += "<form method='GET' action='?src=[REF(src)]'>"
	output += "<input type='hidden' name='src' value='[REF(src)]'>"
	output += HrefTokenFormField()
	output += "<input type='hidden' name='dbsearchckey' value='[playerckey]'>"
	output += "<input type='hidden' name='dbsearchadmin' value='[adminckey]'>"
	output += "<input type='hidden' name='dbsearchip' value='[ip]'>"
	output += "<input type='hidden' name='dbsearchcid' value='[cid]'>"
	output += "<input type='hidden' name='dbsearchpage' value='[page]'>"
	output += "<table width='100%'><tr>"
	output += "<td><b>Ban type</b></td><td><select name='dbbanaddtype'>"
	output += "<option value=''>--</option>"
	output += "<option value='[BANTYPE_PERMA]'>PERMABAN</option>"
	output += "<option value='[BANTYPE_TEMP]'>TEMPBAN</option>"
	output += "<option value='[BANTYPE_JOB_PERMA]'>JOB PERMABAN</option>"
	output += "<option value='[BANTYPE_JOB_TEMP]'>JOB TEMPBAN</option>"
	output += "<option value='[BANTYPE_ADMIN_PERMA]'>ADMIN PERMABAN</option>"
	output += "<option value='[BANTYPE_ADMIN_TEMP]'>ADMIN TEMPBAN</option>"
	output += "<option value='[BANTYPE_PACIFIST]'>PACIFICATION BAN</option>"
	output += "</select></td>"
	output += "<td><b>Key</b> <input type='text' name='dbbanaddkey' value='[playerckey]'></td></tr>"
	output += "<tr><td><b>IP</b> <input type='text' name='dbbanaddip'></td>"
	output += "<td><b>Computer ID</b> <input type='text' name='dbbanaddcid'></td></tr>"
	output += "<tr><td><b>Duration</b> <input type='text' name='dbbaddduration' placeholder='minutes (temp)'></td>"
	output += "<td><b>Severity</b> <select name='dbbanaddseverity'>"
	output += "<option value=''>--</option>"
	output += "<option value='High'>High Severity</option>"
	output += "<option value='Medium'>Medium Severity</option>"
	output += "<option value='Minor'>Minor Severity</option>"
	output += "<option value='None'>No Severity</option>"
	output += "</select></td></tr>"
	output += "<tr><td colspan='2'><b>Job</b> <span class='ban-panel-hint'>(если не отмечены роли ниже)</span><br><select name='dbbanaddjob'>"
	output += "<option value=''>--</option>"
	for(var/j in get_all_jobs())
		output += "<option value='[j]'>[j]</option>"
	for(var/j in GLOB.nonhuman_positions)
		output += "<option value='[j]'>[j]</option>"
	for(var/j in list(ROLE_TRAITOR, ROLE_CHANGELING, ROLE_OPERATIVE, ROLE_REV, ROLE_CULTIST, ROLE_WIZARD, ROLE_HERETIC))
		output += "<option value='[j]'>[j]</option>"
	output += "</select></td></tr></table>"
	output += build_jobban_checkbox_section(playerckey)
	output += "<b>Reason</b><br><textarea name='dbbanreason' class='reason' charset='UTF-8' rows='5'></textarea><br>"
	output += "<input type='submit' name='submit_add_ban' value='Add ban'> "
	output += "<input type='submit' name='submit_job_unban_sync' value='Снять джоббаны (снятые галочки)'>"
	output += "</form></div>"
	output += "<p class='ban-panel-hint'>Учтите: джоббаны и снятие джоббанов действуют со следующего раунда.</p>"

	if(adminckey || playerckey || ip || cid)
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
		var/search = searchlist.Join(" AND ") // x = x AND y = z
		var/bancount = 0
		var/bansperpage = 15
		var/pagecount = 0
		page = text2num(page)
		var/datum/db_query/query_count_bans = SSdbcore.NewQuery({"
			SELECT COUNT(id) FROM [format_table_name("ban")]
			WHERE [search]
			"}, searchlist_args)
		if(!query_count_bans.warn_execute())
			qdel(query_count_bans)
			output += "</div></div>"
			return
		if(query_count_bans.NextRow())
			bancount = text2num(query_count_bans.item[1])
		qdel(query_count_bans)
		if(bancount > bansperpage)
			output += "<div class='ban-panel-pagination'><b>Page:</b> "
			while(bancount > 0)
				output+= "<a href='?_src_=holder;[HrefToken()];dbsearchckey=[playerckey];dbsearchadmin=[adminckey];dbsearchip=[ip];dbsearchcid=[cid];dbsearchpage=[pagecount]'>[pagecount == page ? "<b>\[[pagecount]\]</b>" : "\[[pagecount]\]"]</a> "
				bancount -= bansperpage
				pagecount++
			output += "</div>"
		var/limit = " LIMIT [bansperpage * page], [bansperpage]"

		var/datum/db_query/query_search_bans = SSdbcore.NewQuery({"
			SELECT id, bantime, bantype, reason, job, duration, expiration_time, IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].ckey), ckey), IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].a_ckey), a_ckey), unbanned, IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].unbanned_ckey), unbanned_ckey), unbanned_datetime, edits, round_id
			FROM [format_table_name("ban")]
			WHERE [search] ORDER BY bantime DESC[limit]"}, searchlist_args)
		if(!query_search_bans.warn_execute())
			qdel(query_search_bans)
			output += "</div></div>"
			return

		while(query_search_bans.NextRow())
			var/banid = query_search_bans.item[1]
			var/bantime = query_search_bans.item[2]
			var/bantype  = query_search_bans.item[3]
			var/reason = query_search_bans.item[4]
			var/job = query_search_bans.item[5]
			var/duration = query_search_bans.item[6]
			var/expiration = query_search_bans.item[7]
			var/ban_key = query_search_bans.item[8]
			var/a_key = query_search_bans.item[9]
			var/unbanned = query_search_bans.item[10]
			var/unban_key = query_search_bans.item[11]
			var/unbantime = query_search_bans.item[12]
			var/edits = query_search_bans.item[13]
			var/round_id = query_search_bans.item[14]

			var/typedesc =""
			switch(bantype)
				if("PERMABAN")
					typedesc = "<font color='red'><b>PERMABAN</b></font>"
				if("TEMPBAN")
					typedesc = "<b>TEMPBAN</b><br><font size='2'>([duration] minutes [(unbanned) ? "" : "(<a href=\"byond://?src=[REF(src)];[HrefToken()];dbbanedit=duration;dbbanid=[banid]\">Edit</a>))"]<br>Expires [expiration]</font>"
				if("JOB_PERMABAN")
					typedesc = "<b>JOBBAN</b><br><font size='2'>([job])"
				if("JOB_TEMPBAN")
					typedesc = "<b>TEMP JOBBAN</b><br><font size='2'>([job])<br>([duration] minutes [(unbanned) ? "" : "(<a href=\"byond://?src=[REF(src)];[HrefToken()];dbbanedit=duration;dbbanid=[banid]\">Edit</a>))"]<br>Expires [expiration]"
				if("ADMIN_PERMABAN")
					typedesc = "<b>ADMIN PERMABAN</b>"
				if("ADMIN_TEMPBAN")
					typedesc = "<b>ADMIN TEMPBAN</b><br><font size='2'>([duration] minutes [(unbanned) ? "" : "(<a href=\"byond://?src=[REF(src)];[HrefToken()];dbbanedit=duration;dbbanid=[banid]\">Edit</a>))"]<br>Expires [expiration]</font>"
				if("PACIFICATION_BAN")
					typedesc = "<b>PACIFICATION BAN</b><br><font size='2'>([duration] minutes [(unbanned) ? "" : "(<a href=\"byond://?src=[REF(src)];[HrefToken()];dbbanedit=duration;dbbanid=[banid]\">Edit</a>))"]<br>Expires [expiration]</font>"

			var/header_class = unbanned ? "unbanned" : "banned"
			output += "<div class='banbox'><div class='header [header_class]'>"
			output += "[typedesc] &nbsp; <b>[ban_key]</b> &middot; [bantime] &middot; Round #[round_id] &middot; by <b>[a_key]</b>"
			output += "</div><div class='reason-row'><b>Reason</b> [(unbanned) ? "" : "(<a href=\"byond://?src=[REF(src)];[HrefToken()];dbbanedit=reason;dbbanid=[banid]\">Edit</a>)"]</b>: <cite>\"[reason]\"</cite>"
			output += "<div class='actions'>[(unbanned) ? "" : "<a href=\"byond://?src=[REF(src)];[HrefToken()];dbbanedit=unban;dbbanid=[banid]\">Unban</a>"]</div></div>"
			if(edits)
				output += "<div class='meta'><b>Edits</b><br><font size='2'>[edits]</font></div>"
			if(unbanned)
				output += "<div class='meta'><b>Unbanned</b> by [unban_key] on [unbantime]</div>"
			output += "</div>"
		qdel(query_search_bans)

	output += "</div></div>"

	var/datum/browser/popup = new(usr, "lookupbans", "Banning & Unbanning", 980, 720)
	popup.add_stylesheet("unbanpanelcss", 'html/admin/unbanpanel.css')
	popup.add_stylesheet("banlookupcss", 'html/admin/banlookup.css')
	popup.add_stylesheet("ban_lookup", 'html/admin/ban_lookup.css')
	popup.add_stylesheet("banpanel", 'html/admin/banpanel.css')
	popup.add_script("banpanel", 'html/admin/banpanel.js')
	popup.set_content(output)
	popup.open(FALSE)
