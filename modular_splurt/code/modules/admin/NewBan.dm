/datum/admins/proc/newBan(mob/M)
	if(!check_rights(R_BAN))
		return

	if(!ismob(M))
		to_chat(usr, "<span class='danger'>Invalid mob.</span>")
		return

	var/target_ckey = resolve_mob_ban_ckey(M)
	if(!target_ckey)
		to_chat(usr, "<span class='danger'>Cannot resolve this player's ckey (no client, mind, or stored ckey). Open their panel before they ghost out, or use the Banning Panel.</span>")
		return

	if(GLOB.admin_datums[target_ckey] || GLOB.deadmins[target_ckey])
		to_chat(usr, "<span class='danger'>Error: You cannot ban admins!</span>")
		return

	var/display_key = M.key || M.mind?.key || target_ckey

	switch(tgui_alert(usr, "Ban type", buttons = list("Temporary", "Permanent", "Cancel")))
		if("Temporary")
			var/mins = input(usr,"How long (in minutes)?","Ban time",1440) as num|null
			if(mins <= 0)
				to_chat(usr, "<span class='danger'>[mins] is not a valid duration.</span>")
				return
			var/reason = input(usr,"Please State Reason For Banning [display_key].","Reason") as message|null
			if(!reason)
				return
			if(DB_ban_record(BANTYPE_TEMP, M, mins, reason) != TRUE)
				to_chat(usr, "<span class='danger'>Failed to apply ban.</span>")
				return
			AddBan(target_ckey, M.computer_id, reason, usr.ckey, 1, mins)
			ban_unban_log_save("[key_name(usr)] has banned [key_name(M)]. - Reason: [reason] - This will be removed in [mins] minutes.")
			if(M.client)
				to_chat(M, "<span class='boldannounce'><BIG>You have been banned by [usr.client.key].\nReason: [reason]</BIG></span>")
				to_chat(M, "<span class='danger'>This is a temporary ban, it will be removed in [mins] minutes. The round ID is [GLOB.round_id].</span>")
				var/bran = CONFIG_GET(string/banappeals)
				if(bran)
					to_chat(M, "<span class='danger'>To try to resolve this matter head to [bran]</span>")
				else
					to_chat(M, "<span class='danger'>No ban appeals URL has been set.</span>")
			log_admin_private("[key_name(usr)] has banned [key_name(M)].\nReason: [reason]\nThis will be removed in [mins] minutes.")
			var/msg = "<span class='adminnotice'>[key_name_admin(usr)] has banned [key_name_admin(M)].\nReason: [reason]\nThis will be removed in [mins] minutes.</span>"
			message_admins(msg)
			var/datum/admin_help/AH = M.client?.current_ticket
			if(AH)
				AH.Resolve()
			GLOB.bot_event_sending_que += list(list(
				"type" = "ban_a",
				"title" = "Блокировка",
				"player" = display_key,
				"admin" = usr.key,
				"reason" = reason,
				"banduration" = mins,
				"bantimestamp" = SQLtime(),
				"round" = GLOB.round_id,
				"additional_info" = list()
			))
			if(M.client)
				qdel(M.client)
		if("Permanent")
			var/reason = input(usr,"Please State Reason For Banning [display_key].","Reason") as message|null
			if(!reason)
				return
			var/ip_ban = FALSE
			switch(alert(usr,"IP ban?",,"Да","Нет","Cancel"))
				if("Cancel")
					return
				if("Да")
					ip_ban = TRUE
				if("Нет")
					ip_ban = FALSE
			if(DB_ban_record(BANTYPE_PERMA, M, -1, reason) != TRUE)
				to_chat(usr, "<span class='danger'>Failed to apply ban.</span>")
				return
			if(ip_ban)
				AddBan(target_ckey, M.computer_id, reason, usr.ckey, 0, 0, M.lastKnownIP)
			else
				AddBan(target_ckey, M.computer_id, reason, usr.ckey, 0, 0)
			if(M.client)
				to_chat(M, "<span class='boldannounce'><BIG>You have been banned by [usr.client.key].\nReason: [reason]</BIG></span>")
				to_chat(M, "<span class='danger'>This is a permanent ban. The round ID is [GLOB.round_id].</span>")
				var/bran = CONFIG_GET(string/banappeals)
				if(bran)
					to_chat(M, "<span class='danger'>To try to resolve this matter head to [bran]</span>")
				else
					to_chat(M, "<span class='danger'>No ban appeals URL has been set.</span>")
			ban_unban_log_save("[key_name(usr)] has permabanned [key_name(M)]. - Reason: [reason] - This is a permanent ban.")
			log_admin_private("[key_name(usr)] has banned [key_name(M)].\nReason: [reason]\nThis is a permanent ban.")
			var/msg = "<span class='adminnotice'>[key_name_admin(usr)] has banned [key_name_admin(M)].\nReason: [reason]\nThis is a permanent ban.</span>"
			message_admins(msg)
			var/datum/admin_help/AH = M.client?.current_ticket
			if(AH)
				AH.Resolve()
			GLOB.bot_event_sending_que += list(list(
				"type" = "ban_a",
				"title" = "Пермаментная Блокировка",
				"player" = display_key,
				"admin" = usr.key,
				"reason" = reason,
				"banduration" = null,
				"bantimestamp" = SQLtime(),
				"round" = GLOB.round_id,
				"additional_info" = list()
			))
			if(M.client)
				qdel(M.client)
