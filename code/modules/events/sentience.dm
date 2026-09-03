/datum/round_event_control/sentience
	name = "Random Human-level Intelligence"
	typepath = /datum/round_event/ghost_role/sentience
	weight = 50
	max_occurrences = 2
	category = EVENT_CATEGORY_FRIENDLY
	description = "Один ценный бот (Beepsky, ED-209 и т.п.) обретает разум. Обычных питомцев госты могут занять в любой момент."
	director_ghost_jobban = ROLE_SENTIENCE
	director_ghost_preference = ROLE_SENTIENCE

/datum/round_event/ghost_role/sentience
	minimum_required = 1
	role_name = "random high-value bot"
	var/animals = 1
	var/one = "один"
	/// Blacklisted mob_biotypes - Hey can we like, not have player controlled megafauna?
	var/blacklisted_biotypes = MOB_EPIC
	/// If TRUE, only the valuable whitelist is eligible (normal event). Admin "all" turns this off.
	var/limit_to_valuable = TRUE
	/// Combat / high-impact station bots worth waking for ghosts.
	var/static/list/valuable_sentience_typecache
	fakeable = TRUE

/datum/round_event/ghost_role/sentience/New()
	. = ..()
	if(!valuable_sentience_typecache)
		valuable_sentience_typecache = typecacheof(list(
			/mob/living/simple_animal/bot/secbot,
			/mob/living/simple_animal/bot/ed209,
		))

/datum/round_event/ghost_role/sentience/announce(fake)
	var/sentience_report = ""

	var/data = pick("сканировании с наших сенсоров дальнего действия", "наших сложных вероятностных моделях", "нашем всемогуществе", "коммуникационном трафике на вашей станции", "обнаруженных нами выбросах энергии", "\[ОТРЕДАКТИРОВАНО\]")
	var/pets = pick("ботов службы безопасности", "автономных охранных единиц", "Securitron/ED-209", "станционных силовиков на колёсиках", "\[ОТРЕДАКТИРОВАНО\]")
	var/strength = pick("человеческий", "умеренный", "ящеровидный", "охранный", "командный", "клоунский", "низкий", "очень низкий", "вульпский", "Айковский", "\[ОТРЕДАКТИРОВАНО\]")

	sentience_report += "Основываясь на [data], мы считаем, что [one] из [pets] станции развил [strength] уровень интеллекта и способность к общению."

	priority_announce(sentience_report, "Отдел Бесполезных Оповещений", 'sound/announcer/classic/sentinence.ogg')

/// Ordinary pets are always ghost-joinable; this event is for rare high-impact bodies.
/datum/round_event/ghost_role/sentience/proc/is_sentience_candidate(mob/living/simple_animal/candidate)
	if(!istype(candidate))
		return FALSE
	if(candidate.playable_by_ghost)
		return FALSE
	if(candidate.mob_biotypes & blacklisted_biotypes)
		return FALSE
	if(limit_to_valuable && !is_type_in_typecache(candidate, valuable_sentience_typecache))
		return FALSE
	if(istype(candidate, /mob/living/simple_animal/bot))
		var/mob/living/simple_animal/bot/bot = candidate
		if(bot.paicard)
			return FALSE
	return TRUE

/datum/round_event/ghost_role/sentience/spawn_role()
	var/list/mob/dead/observer/candidates
	candidates = get_candidates(ROLE_SENTIENCE, null, ROLE_SENTIENCE)

	// find our chosen mob to breathe life into
	// Valuable bots by default; admin "all" ignores the whitelist
	var/list/potential = list()
	for(var/mob/living/simple_animal/L in GLOB.alive_mob_list)
		var/turf/T = get_turf(L)
		if(!T || !is_station_level(T.z))
			continue
		if((L in GLOB.player_list) || L.mind || L.incapacitated())
			continue
		if(!is_sentience_candidate(L))
			continue
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
	limit_to_valuable = FALSE
	// cockroach pride, station wide
