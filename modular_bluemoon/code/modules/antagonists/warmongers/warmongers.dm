/datum/antagonist/warmonger
	name = "medieval warmongers"
	job_rank = ROLE_TRAITOR
	roundend_category = "space pirates"
	antagpanel_category = "Warmongers"
	threat = 5
	show_to_ghosts = TRUE
	var/datum/team/warmonger/crew

/datum/antagonist/warmonger/greet()
	SEND_SOUND(owner.current, sound('sound/ambience/antag/pirate.ogg'))
	to_chat(owner, "<span class='boldannounce'>Вы - средневековый боец в космосе!</span>")
	to_chat(owner, "<B>Станция отказалась платить вам дань. Атакуйте станцию, украдите её ресурсы и средства из хранилища. Покажите слабым кто тут прав! Держите свой корабль в сохранности.</B>")
	owner.announce_objectives()

/datum/antagonist/warmonger/get_team()
	return crew

/datum/antagonist/warmonger/create_team(datum/team/pirate/new_team)
	if(!new_team)
		for(var/datum/antagonist/warmonger/P in GLOB.antagonists)
			if(!P.owner)
				continue
			if(P.crew)
				crew = P.crew
				return
		if(!new_team)
			crew = new /datum/team/warmonger
			crew.forge_objectives()
			return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	crew = new_team

/datum/antagonist/warmonger/on_gain()
	if(crew)
		objectives |= crew.objectives
	. = ..()

/datum/team/warmonger
	name = "Warmonegrs crew"

/datum/team/warmonger/proc/forge_objectives()
	var/datum/objective/loot/getbooty = new()

	getbooty.team = src
	for(var/obj/machinery/computer/piratepad_control/P in GLOB.machines)
		var/area/A = get_area(P)
		if(istype(A,/area/shuttle/medieval))
			getbooty.cargo_hold = P
			break
	getbooty.update_explanation_text()
	objectives += getbooty
	for(var/datum/mind/M in members)
		var/datum/antagonist/warmonger/P = M.has_antag_datum(/datum/antagonist/warmonger)
		if(P)
			P.objectives |= objectives
