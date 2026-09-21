/datum/orbital_objective/artifact
	name = "Экстракция Артефакта"
	var/generated = FALSE
	//The blackbox required to recover.
	var/obj/item/alienartifact/objective/linked_artifact
	min_payout = 20 * CARGO_CRATE_VALUE
	max_payout = 60 * CARGO_CRATE_VALUE

/datum/orbital_objective/artifact/generate_objective_stuff(turf/chosen_turf)
	generated = TRUE
	linked_artifact = new(chosen_turf)
	var/list/turfs = RANGE_TURFS(30, chosen_turf)
	var/list/valid_turfs = list()
	for(var/turf/open/floor/F in turfs)
		if(locate(/obj/structure) in F)
			continue
		valid_turfs += F
	//Shuffle the list
	shuffle_inplace(valid_turfs)
	for(var/i in rand(6, 15))
		if(valid_turfs.len < i)
			message_admins("Ran out of valid turfs to create artifact defenses on.")
			return
		var/turf/selected_turf = valid_turfs[i]
		new /obj/structure/alien_artifact/watcher(selected_turf)

/datum/orbital_objective/artifact/get_text()
	. = "Аванпост [station_name] - наша исследовательская станция, на которой сейчас находится невероятно мощный артефакт. \
		Найдите и верните артефакт для получения награды в размере [payout] кредитов."
	if(linked_beacon)
		. += " Станция находится у маяка [linked_beacon.name]. Вперёд!"

/datum/orbital_objective/artifact/check_failed()
	if(!generated)
		return FALSE
	if(is_station_level(linked_artifact?.z))
		complete_objective()
		return FALSE
	if(!QDELETED(linked_artifact))
		return FALSE
	return TRUE
