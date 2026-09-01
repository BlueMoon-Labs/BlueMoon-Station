/datum/round_event_control/cat_surgeon
	name = "Cat Surgeon"
	typepath = /datum/round_event/cat_surgeon
	max_occurrences = 2
	weight = 25
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_FLAVOR

/datum/round_event/cat_surgeon/announce(fake)
	send_fax_to_area(new /obj/item/paper/fax_CC_message/escapee/cat_surgeon_announce, /area/security, "Психиатрический Отдел Nanotrasen", FALSE)
	// priority_announce("Один из наших... кхм... особых заключённых сбежал. Так получилось, что его последнее известное местонахождение до того, как их маячок заглох, - это ваша станция, так что будьте осторожней и остерегайтесь Технических Тоннелей. И еще... никто не видел наших кошек?",
	// sender_override = "Психиатрический Отдел Nanotrasen", has_important_message = TRUE)


/datum/round_event/cat_surgeon/start()
	var/list/spawn_locs = list()
	var/list/unsafe_spawn_locs = list()
	for(var/X in GLOB.xeno_spawn)
		if(!isfloorturf(X))
			unsafe_spawn_locs += X
			continue
		var/turf/open/floor/F = X
		var/datum/gas_mixture/A = F.air
		var/oxy_moles = A.get_moles(GAS_O2)
		if((oxy_moles < 16 || oxy_moles > 50) || A.get_moles(GAS_PLASMA) || A.get_moles(GAS_CO2) >= 10)
			unsafe_spawn_locs += F
			continue
		if((A.return_temperature() <= 270) || (A.return_temperature() >= 360))
			unsafe_spawn_locs += F
			continue
		var/pressure = A.return_pressure()
		if((pressure <= 20) || (pressure >= 550))
			unsafe_spawn_locs += F
			continue
		spawn_locs += F

	if(!spawn_locs.len)
		spawn_locs += unsafe_spawn_locs

	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR

	var/turf/T = get_turf(pick(spawn_locs))
	var/mob/living/simple_animal/hostile/cat_butcherer/S = new(T)
	playsound(S, 'sound/misc/catscream.ogg', 75, 1, 1000)
	message_admins("A cat surgeon has been spawned at [COORD(T)][ADMIN_JMP(T)]")
	log_game("A cat surgeon has been spawned at [COORD(T)]")
	return SUCCESSFUL_SPAWN

