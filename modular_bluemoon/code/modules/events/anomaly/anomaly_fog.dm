/datum/round_event_control/anomaly/anomaly_fog
	name = "Anomaly: Fog"
	typepath = /datum/round_event/anomaly/anomaly_fog
	max_occurrences = 2
	weight = 20
	description = "Аномалия ползучего тумана."

/datum/round_event/anomaly/anomaly_fog
	start_when = ANOMALY_START_MEDIUM_TIME
	announce_when = ANOMALY_ANNOUNCE_MEDIUM_TIME
	anomaly_path = /obj/effect/anomaly/fog
	fakeable = FALSE

/datum/round_event/anomaly/anomaly_fog/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	var/department_name = get_area_name(impact_area)
	if(is_type_in_list(impact_area, list(/area/cargo)))
		department_name = "Cargo"
	else if(is_type_in_list(impact_area, list(/area/engineering, /area/command/heads_quarters/ce)))
		department_name = "Engineering"
	else if(is_type_in_list(impact_area, list(/area/medical, /area/command/heads_quarters/cmo)))
		department_name = "Medical"
	else if(is_type_in_list(impact_area, list(/area/science, /area/command/heads_quarters/rd)))
		department_name = "Science"
	else if(is_type_in_list(impact_area, list(/area/security, /area/command/heads_quarters/hos, /area/service/lawoffice)))
		department_name = "Security"
	else if(is_type_in_list(impact_area, list(/area/service/bar, /area/service/barbershop, /area/service/chapel, /area/service/hydroponics, /area/service/janitor, /area/service/kitchen, /area/service/library, /area/service/theater)))
		department_name = "Service"
	else if(istype(impact_area, /area/command))
		department_name = "Command or Restricted areas"
	else if(is_type_in_list(impact_area, list(/area/commons, /area/service/cafeteria, /area/service/coffeehouse, /area/service/observatory, /area/service/park, /area/service/sauna, /area/service/shop)))
		department_name = "Dorms or Recreation areas"
	priority_announce("Аномалия ползучего тумана об*ару**#а н- [department_name] \\|||#@#$#@%#@%@$^^#%!%@#@# T̵̨̟͈͍̈̓H̶̢̧̳͇̰͍̦͕̣͓̖̼͋̓̒̏̒̈́̊́͒̍̓̈́̑̚͜͝ͅẼ̴̪͘͝ ̶̧̨̳̠̯̦̻̬̫͇̺̘̲̋̾̑̀̍͋̀̀F̶͙͙̙̼̗͙̖̹̤̥̟͚̀͆͌ͅO̴̳̻͓͕̰͉̼̔̈͋̌̆͊̈́̑̂̒͂́̕ͅĜ̸̢͓̖̓̀̄̉̈́͌ ̶̢̛̼̲͕͙̀̑I̵̧̢͚̜̤̝̦͈͔̝͆́̉͂̅̕Ş̵̡̨̛̣̭̳̜͕̠̘͇̹̾̅̆̄͗̿̅̿̽͋͒̎͘͜ ̶̡̯̱̙̖̫͇̩̠̜͎̀̓͛̽͗̈̀ͅC̵̼̼͊̓̍̄̈́͊͘͠Ơ̴̡̺̪͖̞̜̮͚̩̜̈́͛̀̇M̶͕͕̤̩̹̠̫̗̼̫̟̻̈̌̈́́̓́̈͜͝Ȉ̸̱̹̓̿̋̕N̶̛̲͈̪̆͒̋̒̄̃̀̍̂G̵͚̠͍͉̽͌̔͛ @#$%@^^@#$||\\\\.", "ВНИМАНИЕ: АНОМАЛИЯ", 'modular_bluemoon/code/modules/events/anomaly/anomaly_fog.ogg')
