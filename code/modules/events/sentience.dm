/datum/round_event_control/sentience
	name = "Random Human-level Intelligence"
	typepath = /datum/round_event/ghost_role/sentience
	weight = 50
	max_occurrences = 2
	category = EVENT_CATEGORY_FRIENDLY
	director_ghost_jobban = ROLE_SENTIENCE
	director_ghost_preference = ROLE_SENTIENCE

/datum/round_event/ghost_role/sentience
	minimum_required = 1
	role_name = "random animal"
	var/animals = 1
	var/one = "один"
	/// Blacklisted mob_biotypes - Hey can we like, not have player controlled megafauna?
	var/blacklisted_biotypes = MOB_EPIC
	fakeable = TRUE

/datum/round_event/ghost_role/sentience/announce(fake)
	var/sentience_report = ""

	var/data = pick("сканировании с наших сенсоров дальнего действия", "наших сложных вероятностных моделях", "нашем всемогуществе", "коммуникационном трафике на вашей станции", "обнаруженных нами выбросов энергии", "\[ОТРЕДАКТИРОВАНО\]")
	var/pets = pick("животных/ботов", "ботов/животных", "домашних животных", "простых животных", "\[ОТРЕДАКТИРОВАНО\]")
	var/strength = pick("человеческий", "умеренный", "ящеровидный", "охранный", "командный", "клоунский", "низкий", "очень низкий", "вульпский", "Айковский", "\[ОТРЕДАКТИРОВАНО\]")

	sentience_report += "Основываясь на [data], мы считаем, что [one] из [pets] станции развил [strength] уровень интеллекта и способность к общению."

	priority_announce(sentience_report, "Отдел Бесполезных Оповещений", 'sound/announcer/classic/sentinence.ogg')

/datum/round_event/ghost_role/sentience/spawn_role()
	var/list/mob/dead/observer/candidates
	candidates = get_candidates(ROLE_SENTIENCE, null, ROLE_SENTIENCE)

	// find our chosen mob to breathe life into
	// Mobs have to be simple animals, mindless and on station
	var/list/potential = list()
	for(var/mob/living/simple_animal/L in GLOB.alive_mob_list)
		var/turf/T = get_turf(L)
		if(!T || !is_station_level(T.z))
			continue
		if(L.mob_biotypes & blacklisted_biotypes)		//hey can you don't
			continue
		if(!(L in GLOB.player_list) && !L.mind && !L.incapacitated())
			potential += L

	if(!potential.len)
		return WAITING_FOR_SOMETHING
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/spawned_animals = 0
	while(spawned_animals < animals && candidates.len && potential.len)
		var/mob/living/simple_animal/SA = pick_n_take(potential)
		var/mob/SG = pick_n_take(candidates)

		spawned_animals++

		SG.transfer_ckey(SA, FALSE)

		SA.grant_all_languages(UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_ATOM)

		SA.sentience_act()

		SA.maxHealth = max(SA.maxHealth, 200)
		SA.health = SA.maxHealth
		SA.del_on_death = FALSE

		spawned_mobs += SA
		SA.AddElement(/datum/element/ghost_role_eligibility, penalize_on_ghost = TRUE)
		to_chat(SA, "<span class='userdanger'>Hello world!</span>")
		to_chat(SA, "<span class='warning'>Due to freak radiation and/or chemicals \
			and/or lucky chance, you have gained human level intelligence \
			and the ability to speak and understand human language!</span>")

	return SUCCESSFUL_SPAWN

/datum/round_event_control/sentience/all
	name = "Station-wide Human-level Intelligence"
	typepath = /datum/round_event/ghost_role/sentience/all
	admin_only = TRUE
	category = EVENT_CATEGORY_FRIENDLY
	description = "ALL animals and robots become sentient, provided there is enough ghosts."

/datum/round_event/ghost_role/sentience/all
	one = "all"
	animals = INFINITY // as many as there are ghosts and animals
	// cockroach pride, station wide
