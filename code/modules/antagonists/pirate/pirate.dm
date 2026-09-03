/datum/antagonist/pirate
	name = "Space Pirate"
	job_rank = ROLE_TRAITOR
	roundend_category = "space pirates"
	antagpanel_category = "Pirate"
	threat = 5
	show_to_ghosts = TRUE
	var/datum/team/pirate/crew

/datum/antagonist/pirate/greet()
	SEND_SOUND(owner.current, sound('sound/ambience/antag/pirate.ogg'))
	to_chat(owner, "<span class='boldannounce'>Вы - Космический пират!</span>")
	to_chat(owner, "<B>Станция отказалась платить вам за крышу. Атакуйте станцию, украдите её ресурсы и средства из хранилища. Избегайте ненужных жертв. Держите свой корабль в сохранности.</B>")
	owner.announce_objectives()

/datum/antagonist/pirate/get_team()
	return crew

/datum/antagonist/pirate/create_team(datum/team/pirate/new_team)
	if(!new_team)
		for(var/datum/antagonist/pirate/P in GLOB.antagonists)
			if(!P.owner)
				continue
			if(P.crew)
				crew = P.crew
				return
		if(!new_team)
			crew = new /datum/team/pirate
			crew.forge_objectives()
			return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	crew = new_team

/datum/antagonist/pirate/on_gain()
	if(crew)
		objectives |= crew.objectives
	. = ..()

/datum/team/pirate
	name = "Pirate crew"

/datum/team/pirate/proc/forge_objectives()
	var/datum/objective/loot/getbooty = new()
	getbooty.team = src
	for(var/obj/machinery/computer/piratepad_control/P in GLOB.machines)
		var/area/A = get_area(P)
		if(istype(A,/area/shuttle/pirate))
			getbooty.cargo_hold = P
			break
	getbooty.update_explanation_text()
	objectives += getbooty
	for(var/datum/mind/M in members)
		var/datum/antagonist/pirate/P = M.has_antag_datum(/datum/antagonist/pirate)
		if(P)
			P.objectives |= objectives


/datum/objective/loot
	var/obj/machinery/computer/piratepad_control/cargo_hold
	explanation_text = "Добудьте ценные ресурсы и сложите их в обозначенной области."
	var/target_value = 75000
	///Собственная копия набранного. Терминал может исчезнуть (админ, шаттл, взрыв), и прогресс
	///команды не должен уходить вместе с ним - в отчёте конца раунда была пустая сумма.
	var/stored_value = 0

/datum/objective/loot/update_explanation_text()
	if(cargo_hold)
		var/area/storage_area = get_area(cargo_hold)
		explanation_text = "Добудьте ценных ресурсов на сумму [target_value] кредитов и сложите их в области [storage_area.name]."

/datum/objective/loot/proc/loot_listing()
	//Lists notable loot.
	if(!cargo_hold || !cargo_hold.total_report)
		return "Свободная задача"
	cargo_hold.total_report.total_value = sortTim(cargo_hold.total_report.total_value, cmp = GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
	var/count = 0
	var/list/loot_texts = list()
	for(var/datum/export/E in cargo_hold.total_report.total_value)
		if(++count > 5)
			break
		loot_texts += E.total_printout(cargo_hold.total_report,notes = FALSE)
	return loot_texts.Join(", ")

/datum/objective/loot/proc/get_loot_value()
	if(cargo_hold)
		stored_value = max(stored_value, cargo_hold.total_collected)
	return stored_value

/datum/objective/loot/check_completion()
	return ..() || get_loot_value() >= target_value

/datum/team/pirate/roundend_report()
	var/list/parts = list()

	parts += "<span class='header'>Space Pirates were:</span>"

	var/all_dead = TRUE
	for(var/datum/mind/M in members)
		if(considered_alive(M))
			all_dead = FALSE
	parts += printplayerlist(members)

	parts += "Loot stolen: "
	var/datum/objective/loot/L = locate() in objectives
	parts += L.loot_listing()
	parts += "Total loot value : [L.get_loot_value()]/[L.target_value] credits"

	if(L.check_completion() && !all_dead)
		parts += "<span class='greentext big'>The pirate crew was successful!</span>"
	else
		parts += "<span class='redtext big'>The pirate crew has failed.</span>"

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"
