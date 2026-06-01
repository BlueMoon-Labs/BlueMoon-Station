/client/proc/jumptoarea(area/A in GLOB.sortedAreas)
	set name = "Jump to Area"
	set desc = "Area to jump to"
	set category = "Admin.Game"
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.", confidential = TRUE)
		return

	if(!A)
		return

	var/list/turfs = list()
	for(var/turf/T in A)
		if(T.density)
			continue
		turfs.Add(T)

	if(length(turfs))
		var/turf/T = pick(turfs)
		usr.forceMove(T)
		log_admin("[key_name(usr)] jumped to [AREACOORD(T)]")
		message_admins("[key_name_admin(usr)] jumped to [AREACOORD(T)]")
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Area") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	else
		to_chat(src, "Nowhere to jump to!", confidential = TRUE)
		return


/client/proc/jumptoturf(turf/T in world)
	set name = "Jump to Turf"
	set category = "Admin.Game"
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.", confidential = TRUE)
		return

	log_admin("[key_name(usr)] jumped to [AREACOORD(T)]")
	message_admins("[key_name_admin(usr)] jumped to [AREACOORD(T)]")
	usr.forceMove(T)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Turf") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	return

/client/proc/jumptomob(mob/M in GLOB.mob_list)
	set category = "Admin.Game"
	set name = "Jump to Mob"

	if(!src.holder)
		to_chat(src, "Only administrators may use this command.", confidential = TRUE)
		return

	log_admin("[key_name(usr)] jumped to [key_name(M)]")
	message_admins("[key_name_admin(usr)] jumped to [ADMIN_LOOKUPFLW(M)] at [AREACOORD(M)]")
	if(src.mob)
		var/mob/A = src.mob
		var/turf/T = get_turf(M)
		if(T && isturf(T))
			SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Mob") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
			A.forceMove(M.loc)
		else
			to_chat(A, "This mob is not located in the game world.", confidential = TRUE)

/client/proc/jumptocoord(tx as num, ty as num, tz as num)
	set category = "Admin.Game"
	set name = "Jump to Coordinate"

	if (!holder)
		to_chat(src, "Only administrators may use this command.", confidential = TRUE)
		return

	if(src.mob)
		var/mob/A = src.mob
		var/turf/T = locate(tx,ty,tz)
		A.forceMove(T)
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Coordiate") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	message_admins("[key_name_admin(usr)] jumped to coordinates [tx], [ty], [tz]")

/client/proc/jumptokey()
	set category = "Admin.Game"
	set name = "Jump to Key"

	if(!src.holder)
		to_chat(src, "Only administrators may use this command.", confidential = TRUE)
		return

	var/list/keys = list()
	for(var/mob/M in GLOB.player_list)
		keys += M.client
	var/client/selection = input("Please, select a player!", "Admin Jumping", null, null) as null|anything in sortKey(keys)
	if(!selection)
		to_chat(src, "No keys found.", confidential = TRUE)
		return
	var/mob/M = selection.mob
	log_admin("[key_name(usr)] jumped to [key_name(M)]")
	message_admins("[key_name_admin(usr)] jumped to [ADMIN_LOOKUPFLW(M)]")

	usr.forceMove(M.loc)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Key") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/Getmob(mob/M in GLOB.mob_list - GLOB.dummy_mob_list)
	set category = "Admin.Game"
	set name = "Get Mob"
	set desc = "Mob to teleport"
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.", confidential = TRUE)
		return

	var/atom/loc = get_turf(usr)
	log_admin("[key_name(usr)] teleported [key_name(M)] to [AREACOORD(loc)]")
	var/msg = "[key_name_admin(usr)] teleported [ADMIN_LOOKUPFLW(M)] to [ADMIN_VERBOSEJMP(loc)]"
	message_admins(msg)
	admin_ticket_log(M, msg)
	M.forceMove(loc)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Get Mob") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/Getkey()
	set category = "Admin.Game"
	set name = "Get Key"
	set desc = "Key to teleport"

	if(!src.holder)
		to_chat(src, "Only administrators may use this command.", confidential = TRUE)
		return

	var/list/keys = list()
	for(var/mob/M in GLOB.player_list)
		keys += M.client
	var/client/selection = input("Please, select a player!", "Admin Jumping", null, null) as null|anything in sortKey(keys)
	if(!selection)
		return
	var/mob/M = selection.mob

	if(!M)
		return
	log_admin("[key_name(usr)] teleported [key_name(M)]")
	var/msg = "[key_name_admin(usr)] teleported [ADMIN_LOOKUPFLW(M)]"
	message_admins(msg)
	admin_ticket_log(M, msg)
	if(M)
		M.forceMove(get_turf(usr))
		usr.forceMove(M.loc)
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Get Key") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/sendmob(mob/M in sortmobs())
	set category = "Admin.Game"
	set name = "Send Mob"
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.", confidential = TRUE)
		return
	var/area/A = input(usr, "Pick an area.", "Pick an area") in GLOB.sortedAreas|null
	if(A && istype(A))
		var/list/turfs = get_area_turfs(A)
		if(length(turfs) && M.forceMove(pick(turfs)))

			log_admin("[key_name(usr)] teleported [key_name(M)] to [AREACOORD(M)]")
			var/msg = "[key_name_admin(usr)] teleported [ADMIN_LOOKUPFLW(M)] to [AREACOORD(M)]"
			message_admins(msg)
			admin_ticket_log(M, msg)
		else
			to_chat(src, "Failed to move mob to a valid location.", confidential = TRUE)
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Send Mob") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/// Proc to hook user-enacted teleporting behavior and keep logging of the event.
/atom/movable/proc/admin_teleport(atom/new_location, message = TRUE)
	if(isnull(new_location))
		log_admin("[key_name(usr)] teleported [key_name(src)] to nullspace")
		moveToNullspace()
	else
		log_admin("[key_name(usr)] teleported [key_name(src)] to [AREACOORD(loc)]")
		forceMove(new_location)

/mob/admin_teleport(atom/new_location, message = TRUE)
	var/msg = "[key_name_admin(usr)] teleported [ADMIN_LOOKUPFLW(src)] to [isnull(new_location) ? "nullspace" : ADMIN_VERBOSEJMP(loc)]"
	if(message)
		message_admins(msg)
	admin_ticket_log(src, msg)
	return ..()

/client/proc/admin_jump_to()
	set name = "Admin Jump To"
	set desc = "Open the unified jump to interface"
	set category = "Admin.Game"
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.", confidential = TRUE)
		return
	var/datum/admin_jump_to/jump = new(src)
	jump.ui_interact(src.mob)

/datum/admin_jump_to
	var/client/owner

/datum/admin_jump_to/New(client/C)
	if(!istype(C))
		qdel(src)
	owner = C

/datum/admin_jump_to/ui_state(mob/user)
	return GLOB.admin_state

/datum/admin_jump_to/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AdminJumpTo")
		ui.open()

/datum/admin_jump_to/ui_act(action, list/params, datum/tgui/ui)
	if(..())
		return
	if(!owner || !owner.holder)
		return
	switch(action)
		if("jump_mob")
			var/mob/M = tgui_input_list(owner, "Select a mob to jump to", "Jump to Mob", sortmobs())
			if(M)
				owner.jumptomob(M)
		if("jump_key")
			var/list/keys = list()
			for(var/mob/mob in GLOB.player_list)
				if(mob.client)
					keys += mob.client
			var/client/selection = tgui_input_list(owner, "Select a key to jump to", "Jump to Key", sortKey(keys))
			if(selection && selection.mob)
				var/mob/M = selection.mob
				log_admin("[key_name(owner)] jumped to [key_name(M)]")
				message_admins("[key_name_admin(owner)] jumped to [ADMIN_LOOKUPFLW(M)]")
				owner.mob.forceMove(M.loc)
				SSblackbox.record_feedback("tally", "admin_verb", 1, "Jump To Key")
		if("jump_area")
			var/area/A = tgui_input_list(owner, "Select an area to jump to", "Jump to Area", GLOB.sortedAreas)
			if(A)
				owner.jumptoarea(A)
		if("jump_turf")
			var/x = tgui_input_number(owner, "Enter X coordinate", "Jump to Turf", 1)
			if(!isnum(x))
				return
			var/y = tgui_input_number(owner, "Enter Y coordinate", "Jump to Turf", 1)
			if(!isnum(y))
				return
			var/z = tgui_input_number(owner, "Enter Z coordinate", "Jump to Turf", 1)
			if(!isnum(z))
				return
			var/turf/T = locate(x, y, z)
			if(T)
				owner.jumptoturf(T)
			else
				to_chat(owner, "Invalid turf coordinates.", confidential = TRUE)
		if("jump_coord")
			var/x = tgui_input_number(owner, "Enter X coordinate", "Jump to Coordinate", 1)
			if(!isnum(x))
				return
			var/y = tgui_input_number(owner, "Enter Y coordinate", "Jump to Coordinate", 1)
			if(!isnum(y))
				return
			var/z = tgui_input_number(owner, "Enter Z coordinate", "Jump to Coordinate", 1)
			if(!isnum(z))
				return
			owner.jumptocoord(x, y, z)
