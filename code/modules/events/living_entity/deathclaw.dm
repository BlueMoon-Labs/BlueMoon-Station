/datum/round_event_control/deathclaw_in_maints
	name = "Spawn Funclaw in Maints"
	typepath = /datum/round_event/deathclaw_in_maints
	// 50/5 при 10-25 у остального MODERATE-пула - клешни доминировали над аномалиями и штормами.
	max_occurrences = 3
	weight = 25
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_MODERATE

/datum/round_event/deathclaw_in_maints/announce(fake)
	send_fax_to_area(new /obj/item/paper/fax_CC_message/escapee/deathclaw_announce, /area/security, "Психиатрический Отдел Nanotrasen", FALSE)
	// priority_announce("Один из наших... кхм... особых заключённых сбежал. Так получилось, что его последнее известное местонахождение до того, как их маячок заглох, - это ваша станция, так что будьте осторожней и остерегайтесь Технических Тоннелей. И еще... вы не видели ящерку уборщика?",
	// sender_override = "Психиатрический Отдел Nanotrasen", has_important_message = TRUE)

/datum/round_event/deathclaw_in_maints/start()
	var/list/deathclaws_types = list( \
		/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw, \
		/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/mommyclaw, \
		/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/alphaclaw, \
		/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw)
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
	var/deathclaw_type = pick(deathclaws_types)
	new deathclaw_type(T)
	playsound(T, 'sound/alien/Voice/roarFar1.ogg', 75, 1, 1000)
	message_admins("An Syndicate mutant has been spawned at [COORD(T)][ADMIN_JMP(T)]")
	log_game("An Syndicate mutant has been spawned at [COORD(T)]")
	return SUCCESSFUL_SPAWN
