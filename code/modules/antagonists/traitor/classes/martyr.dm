/datum/traitor_class/human/martyr
	name = "InteQ Berserk"
	employer = "Brown Berserkers"
	weight = 2
	chaos = 5
	threat = 5
	min_players = 20
	uplink_filters = list(/datum/uplink_item/stealthy_weapons/romerol_kit,/datum/uplink_item/bundles_tc/contract_kit)

/datum/traitor_class/human/martyr/forge_objectives(datum/antagonist/traitor/T)
	var/datum/objective/martyr/O = new
	O.explanation_text = "InteQ предоставила вам полную свободу действий. Вы можете делать все, что пожелаете, однако по итогу вы должны умереть славной смертью!"
	O.owner = T.owner
	T.add_objective(O)
	return
