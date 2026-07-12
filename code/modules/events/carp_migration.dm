/datum/round_event_control/carp_migration
	name = "Carp Migration"
	typepath = /datum/round_event/carp_migration
	weight = 25
	min_players = 10
	earliest_start = 10 MINUTES
	max_occurrences = 6
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_MINOR
	description = "Summons a school of space carp."

/datum/round_event_control/carp_migration/New()
	. = ..()
	if(HAS_TRAIT(SSstation, STATION_TRAIT_CARP_INFESTATION))
		weight *= 3
		max_occurrences *= 2
		earliest_start *= 0.5

/datum/round_event/carp_migration
	announce_when	= 3
	start_when = 50
	var/hasAnnounced = FALSE

/datum/round_event/carp_migration/setup()
	start_when = rand(40, 60)

/datum/round_event/carp_migration/announce(fake)
	if(prob(50))
		priority_announce("Неизвестные биологические организмы были обнаружены вблизи [station_name()], пожалуйста, приготовьтесь.", "ВНИМАНИЕ: НЕОПОЗНАННЫЕ ФОРМЫ ЖИЗНИ")
	else
		print_command_report("Неизвестные биологические организмы были обнаружены вблизи [station_name()], пожалуйста, приготовьтесь.", "ВНИМАНИЕ: НЕОПОЗНАННЫЕ ФОРМЫ ЖИЗНИ")


/datum/round_event/carp_migration/start()
	var/mob/living/simple_animal/hostile/carp/fish
	for(var/obj/effect/landmark/carpspawn/C in GLOB.landmarks_list)
		if(prob(95))
			fish = new (C.loc)
		else
			fish = new /mob/living/simple_animal/hostile/carp/megacarp(C.loc)
			fishannounce(fish) //Prefer to announce the megacarps over the regular fishies
	fishannounce(fish)

/datum/round_event/carp_migration/proc/fishannounce(atom/fish)
	if (!hasAnnounced)
		announce_to_ghosts(fish) //Only anounce the first fish
		hasAnnounced = TRUE
