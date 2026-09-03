/datum/round_event_control/mice_migration
	name = "Mice Migration"
	typepath = /datum/round_event/mice_migration
	weight = 60
	min_players = 10
	max_occurrences = 2
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_MINOR // категория ENTITIES по умолчанию даёт MAJOR, но мыши безобидны
	family = "vermin" // с Vermin Infestation: два грызунных события подряд - перебор

/datum/round_event/mice_migration
	var/minimum_mice = 15
	var/maximum_mice = 30

/datum/round_event/mice_migration/announce(fake)
	var/cause = pick("космозимы", "урезания бюджетов", "Рагнарёка",
		"холодного космоса", "\[REDACTED\]", "изменения климата",
		"невезения")
	var/plural = pick("группа", "стая", "толпа", "свора",
		"кучка", "не более чем [maximum_mice]")
	var/name = pick("грызунов", "мышей", "пищащих штук",
		"пожирателей проводов", "\[REDACTED\]", "паразитирующих уничтожителей энергии")
	var/movement = pick("мигрировала", "переехала", "приползла", "спустилась")
	var/location = pick("технические тоннели", "технические зоны",
		"\[REDACTED\]", "места, где находятся вкусные провода")
	if(prob(50))
		priority_announce("По причине [cause], [plural] [name] [movement] \
		в [location].", "ВНИМАНИЕ: Мыши!",
		'sound/effects/mousesqueek.ogg')
	else
		print_command_report("По причине [cause], [plural] [name] [movement] в [location].", "ВНИМАНИЕ: Мыши!")

/datum/round_event/mice_migration/start()
	SSminor_mapping.trigger_migration(rand(minimum_mice, maximum_mice))
