/datum/traitor_class/human/hijack
	name = "InteQ Agent"
	employer = "Admiral Brown's Chancellery"
	weight = 3
	chaos = 5
	threat = 3
	min_players = 25
	uplink_filters = list(/datum/uplink_item/stealthy_weapons/romerol_kit)

/datum/traitor_class/human/hijack/forge_objectives(datum/antagonist/traitor/T)
	var/datum/objective/hijack/O = new
	O.explanation_text = "InteQ даёт вам чрезмерно важную миссию и разрешает делать вам делать все, что вы хотите, при одном условии: Шаттл Эвакуации должен быть захвачен путем взлома его навигационных протоколов через консоль управления (АЛЬТ-ЛКМ на Консоль Управления Шаттлом)."
	O.owner = T.owner
	T.add_objective(O)
	return

/datum/traitor_class/human/hijack/finalize_traitor(datum/antagonist/traitor/T)
	T.hijack_speed=1
	return TRUE

/datum/traitor_class/human/hijack/clean_up_traitor(datum/antagonist/traitor/T)
	T.hijack_speed = 0.5

/datum/traitor_class/human/hijack/team_based
	name = "InteQ Evacuation Saboteur"
	employer = "Admiral Brown's Evacuation Sabotage Division"
	min_players = INFINITY // Назначается только рулсетом саботажника.

/datum/traitor_class/human/hijack/team_based/forge_objectives(datum/antagonist/traitor/T)
	if(prob(50) && add_targeted_objective(T, new /datum/objective/maroon))
		return
	return ..()

/datum/traitor_class/human/hijack/team_based/finalize_traitor(datum/antagonist/traitor/T)
	if(locate(/datum/objective/hijack) in T.objectives)
		return ..()
	return TRUE
