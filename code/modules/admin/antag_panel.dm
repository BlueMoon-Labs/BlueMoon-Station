GLOBAL_VAR(antag_prototypes)

//Things to do somewhere in the future (If you're reading this feel free to do any of these)
//Add HrefTokens to these
//Make this template or at least remove + "<br>" with joins where you can grasp the big picture.
//Span classes for the headers, wrap sections in div's and style them.
//Move common admin commands to /mob (maybe integrate with vv dropdown so the list is one thing with some flag where to show it)
//Move objective initialization/editing stuff from mind to objectives and completely remove mind.objectives

/proc/cmp_antagpanel(datum/antagonist/A,datum/antagonist/B)
	var/a_cat = initial(A.antagpanel_category)
	var/b_cat = initial(B.antagpanel_category)
	if(!a_cat && !b_cat)
		return sorttext(initial(A.name),initial(B.name))
	return sorttext(b_cat,a_cat)

/datum/mind/proc/add_antag_wrapper(antag_type,mob/user)
	var/datum/antagonist/new_antag = new antag_type()
	new_antag.admin_add(src,user)
	//If something gone wrong/admin-add assign another antagonist due to whatever clean it up
	if(!new_antag.owner)
		qdel(new_antag)

/proc/listtrim(list/L)
	for(var/x in L)
		if(istext(x) && !x)
			L -= x
	return L

/datum/antagonist/proc/antag_panel()
	var/list/commands = list()
	for(var/command in get_admin_commands())
		commands += "<a href='?src=[REF(src)];command=[command]'>[command]</a>"
	var/command_part = commands.Join(" | ")
	var/data_part = antag_panel_data()
	var/objective_part = antag_panel_objectives()
	var/memory_part = antag_panel_memory()

	var/list/parts = listtrim(list(command_part,data_part,objective_part,memory_part))

	return parts.Join("<br>")

/datum/antagonist/proc/antag_panel_objectives()
	var/result = "<i><b>Objectives</b></i>:<br>"
	if (objectives.len == 0)
		result += "EMPTY<br>"
	else
		var/obj_count = 1
		for(var/datum/objective/objective in objectives)
			result += "<B>[obj_count]</B>: [objective.explanation_text] <a href='?src=[REF(owner)];obj_edit=[REF(objective)]'>Edit</a> <a href='?src=[REF(owner)];obj_delete=[REF(objective)]'>Delete</a> <a href='?src=[REF(owner)];obj_completed=[REF(objective)]'><font color=[objective.completed ? "green" : "red"]>[objective.completed ? "Mark as incomplete" : "Mark as complete"]</font></a><br>"
			obj_count++
	result += "<a href='?src=[REF(owner)];obj_add=1;target_antag=[REF(src)]'>Add objective</a><br>"
	result += "<a href='?src=[REF(owner)];obj_announce=1'>Announce objectives</a><br>"
	return result

/datum/antagonist/proc/antag_panel_memory()
	var/out = "<b>Memory:</b><br>"
	out += antag_memory
	out += "<br><a href='?src=[REF(src)];memory_edit=1'>Edit memory</a><br>"
	return out

/datum/mind/proc/get_common_admin_commands()
	var/common_commands = "<span>Common Commands:</span>"
	if(ishuman(current))
		common_commands += "<a href='?src=[REF(src)];common=undress'>undress</a>"
	else if(iscyborg(current))
		var/mob/living/silicon/robot/R = current
		if(R.emagged)
			common_commands += "<a href='?src=[REF(src)];silicon=Unemag'>Unemag</a>"
	else if(isAI(current))
		var/mob/living/silicon/ai/A = current
		if (A.connected_robots.len)
			for (var/mob/living/silicon/robot/R in A.connected_robots)
				if (R.emagged)
					common_commands += "<a href='?src=[REF(src)];silicon=unemagcyborgs'>Unemag slaved cyborgs</a>"
					break
	return common_commands

/datum/mind/proc/get_special_statuses()
	var/list/result = LAZYCOPY(special_statuses)
	if(!current)
		result += "<span class='bad'>No body!</span>"
	if(current && HAS_TRAIT(current, TRAIT_MINDSHIELD))
		result += "<span class='good'>Mindshielded</span>"
	//Move these to mob
	if(iscyborg(current))
		var/mob/living/silicon/robot/robot = current
		if (robot.emagged)
			result += "<span class='bad'>Emagged</span>"
	return result.Join(" | ")

/datum/mind/proc/traitor_panel()
	if(!SSticker.HasRoundStarted())
		alert("Not before round-start!", "Alert")
		return
	if(QDELETED(src))
		alert("This mind doesn't have a mob, or is deleted! For some reason!", "Edit Memory")
		return

	if(!tgui_panel)
		tgui_panel = new /datum/traitor_panel_tgui(src)
	tgui_panel.ui_interact(usr)
