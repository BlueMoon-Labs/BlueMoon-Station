
//////////////////////////////////////////////
//                                          //
//           INTEQ TRAITORS             //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/traitor
	name = "InteQ Traitors"
	persistent = TRUE
	antag_flag = ROLE_TRAITOR
	antag_datum = /datum/antagonist/traitor
	minimum_required_age = 0
	protected_roles = list("Expeditor", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("AI", "Cyborg", "Positronic Brain") //BLUEMOON CHANGES
	required_candidates = 1
	weight = 13 //BLUEMOON CHANGES
	cost = 8 // Avoid raising traitor threat above 10, as it is the default low cost ruleset.
	scaling_cost = 9
	// Вклад в активную нагрузку SSdirector, пока антаги рулсета живы (считается из executed_rules,
	// см. get_ruleset_intensity). Тиры как у мидраундов: лёгкие соло-антаги 15, тяжёлые/командные 45.
	intensity = 15
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT) // BLUEMOON ADD
	requirements = list(101,10,10,10,10,10,10,10,10,10) //BLUEMOON CHANGES
	antag_cap = list("denominator" = 20) //BLUEMOON CHANGES

/datum/dynamic_ruleset/roundstart/traitor/pre_execute(population)
	. = ..()
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	var/num_traitors = get_antag_cap(population) * (scaled_times + 1)
	for (var/i = 1 to num_traitors)
		var/mob/M = pick_n_take(candidates)
		assigned += M?.mind
		M.mind.special_role = ROLE_TRAITOR
		M.mind.restricted_roles = restricted_roles
	return TRUE

// Самоспавн слиперов из roundstart-трейтора удалён: InteQ Sleeper Agent теперь обычный
// midround-рулсет в ANTAG-пуле SSdirector (weight 7).

//////////////////////////////////////////
//                                      //
//           BLOOD BROTHERS             //
//                                      //
//////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/traitorbro
	name = "Blood Brothers"
	antag_flag = ROLE_BROTHER
	antag_datum = /datum/antagonist/brother
	protected_roles = list("Expeditor", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI")
	required_candidates = 2
	weight = 6 //BLUEMOON CHANGES
	cost = 15
	scaling_cost = 15
	intensity = 15
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,60,50,40,30,20,10) //BLUEMOON CHANGES
	antag_cap = 2 // Can pick 3 per team, but rare enough it doesn't matter.
	var/list/datum/team/brother_team/pre_brother_teams = list()
	var/const/min_team_size = 2

/datum/dynamic_ruleset/roundstart/traitorbro/pre_execute(population)
	. = ..()
	var/num_teams = (get_antag_cap(population)/min_team_size) * (scaled_times + 1) // 1 team per scaling
	for(var/j = 1 to num_teams)
		if(candidates.len < min_team_size || candidates.len < required_candidates)
			break
		var/datum/team/brother_team/team = new
		var/team_size = prob(10) ? min(3, candidates.len) : 2
		for(var/k = 1 to team_size)
			var/mob/bro = pick_n_take(candidates)
			assigned += bro.mind
			team.add_member(bro.mind)
			bro.mind.special_role = "brother"
			bro.mind.restricted_roles = restricted_roles
		pre_brother_teams += team
	return TRUE

/datum/dynamic_ruleset/roundstart/traitorbro/execute()
	for(var/datum/team/brother_team/team in pre_brother_teams)
		team.pick_meeting_area()
		team.forge_brother_objectives()
		for(var/datum/mind/M in team.members)
			M.add_antag_datum(/datum/antagonist/brother, team)
		team.update_name()
	mode.brother_teams += pre_brother_teams
	return TRUE

//////////////////////////////////////////////
//                                          //
//               CHANGELINGS                //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/changeling
	name = "Changelings"
	antag_flag = ROLE_CHANGELING
	antag_datum = /datum/antagonist/changeling
	protected_roles = list("Expeditor", "Prisoner", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("AI", "Cyborg", "Positronic Brain")
	required_candidates = 1
	weight = 8 //BLUEMOON CHANGES
	cost = 15 //BLUEMOON CHANGES
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	scaling_cost = 10
	intensity = 15
	requirements = list(101,101,60,50,40,30,20,15,10,10) //BLUEMOON CHANGES
	antag_cap = 1 //BLUEMOON CHANGES

/datum/dynamic_ruleset/roundstart/changeling/pre_execute(population)
	. = ..()
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	var/num_changelings = get_antag_cap(population) * (scaled_times + 1)
	for (var/i = 1 to num_changelings)
		var/mob/M = pick_n_take(candidates)
		assigned += M.mind
		M.mind.restricted_roles = restricted_roles
		M.mind.special_role = ROLE_CHANGELING
	return TRUE

// BLUEMOON ADD START
/datum/dynamic_ruleset/roundstart/changeling/trim_candidates()
	. = ..()
	for(var/mob/P in candidates)
		if(HAS_TRAIT(P, TRAIT_ROBOTIC_ORGANISM)) // никаких роботов-генокрадов из далекого космоса
			candidates -= P
// BLUEMOON ADD END

/datum/dynamic_ruleset/roundstart/changeling/execute()
	for(var/datum/mind/changeling in assigned)
		var/datum/antagonist/changeling/new_antag = new antag_datum()
		changeling.add_antag_datum(new_antag)
	return TRUE

//////////////////////////////////////////////
//                                          //
//              ELDRITCH CULT               //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/heretics
	name = "Heretics"
	antag_flag = ROLE_HERETIC
	antag_datum = /datum/antagonist/heretic
	protected_roles = list("Expeditor", "Prisoner", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("AI", "Cyborg", "Positronic Brain")
	required_candidates = 1
	weight = 8 //BLUEMOON CHANGES
	cost = 15
	scaling_cost = 9
	intensity = 15
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD; Существовал в тимбазе до удаления.
	requirements = list(101,101,101,50,40,20,20,15,10,10) //higher because of 'round end'
	antag_cap = 1 //BLUEMOON CHANGES

/datum/dynamic_ruleset/roundstart/heretics/pre_execute(population)
	. = ..()
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	var/num_ecult = get_antag_cap(population) * (scaled_times + 1)

	for (var/i = 1 to num_ecult)
		var/mob/picked_candidate = pick_n_take(candidates)
		assigned += picked_candidate.mind
		picked_candidate.mind.restricted_roles = restricted_roles
		picked_candidate.mind.special_role = ROLE_HERETIC
	return TRUE

/datum/dynamic_ruleset/roundstart/heretics/execute()

	for(var/c in assigned)
		var/datum/mind/cultie = c
		var/datum/antagonist/heretic/new_antag = new antag_datum()
		cultie.add_antag_datum(new_antag)
	return TRUE


//////////////////////////////////////////////
//                                          //
//               WIZARDS                    //
//                                          //
//////////////////////////////////////////////

// Dynamic is a wonderful thing that adds wizards to every round and then adds even more wizards during the round.
/datum/dynamic_ruleset/roundstart/wizard
	name = "Wizard"
	antag_flag = ROLE_WIZARD
	antag_datum = /datum/antagonist/wizard
	flags = LONE_RULESET
	minimum_required_age = 0 // BLUEMOON EDIT
	restricted_roles = list("Head of Security","Bridge Officer", "Captain") // Just to be sure that a wizard getting picked won't ever imply a Captain or HoS not getting drafted
	required_candidates = 1
	weight = 6 //BLUEMOON CHANGES
	cost = 20
	intensity = 45
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD) // BLUEMOON ADD
	requirements = list(101,101,101,60,40,20,20,20,10,10)  //BLUEMOON CHANGES
	var/list/roundstart_wizards = list()

/datum/dynamic_ruleset/roundstart/wizard/acceptable(population=0, threat=0)
	if(GLOB.wizardstart.len == 0)
		log_admin("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		message_admins("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		return FALSE
	return ..()

/datum/dynamic_ruleset/roundstart/wizard/pre_execute()
	. = ..()
	if(GLOB.wizardstart.len == 0)
		return FALSE
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	var/mob/M = pick_n_take(candidates)
	if (M)
		assigned += M.mind
		M.mind.assigned_role = ROLE_WIZARD
		M.mind.special_role = ROLE_WIZARD

	return TRUE

/datum/dynamic_ruleset/roundstart/wizard/execute()
	for(var/datum/mind/M in assigned)
		M.current.forceMove(pick(GLOB.wizardstart))
		M.add_antag_datum(new antag_datum())
	return TRUE

//////////////////////////////////////////////
//                                          //
//                BLOOD CULT                //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/bloodcult
	name = "Blood Cult"
	antag_flag = ROLE_CULTIST
	antag_datum = /datum/antagonist/cult
	minimum_required_age = 0 // BLUEMOON EDIT
	protected_roles = list("Expeditor", "NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")  //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_candidates = 2
	weight = 3  //BLUEMOON CHANGES
	cost = 20
	intensity = 45
	//requirements = list(100,90,80,60,40,30,10,10,10,10)
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,101,60,40,20,15,10) //BLUEMOON CHANGES
	flags = HIGH_IMPACT_RULESET
	antag_cap = list("denominator" = 20, "offset" = 1)
	var/datum/team/cult/main_cult

/datum/dynamic_ruleset/roundstart/bloodcult/ready(population, forced = FALSE)
	required_candidates = get_antag_cap(population)
	. = ..()

/datum/dynamic_ruleset/roundstart/bloodcult/pre_execute(population)
	. = ..()
	var/cultists = get_antag_cap(population)
	for(var/cultists_number = 1 to cultists)
		// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
		if(candidates.len <= 0)
			message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
			break
		// BLUEMOON ADD END
		var/mob/M = pick_n_take(candidates)
		assigned += M.mind
		M.mind.special_role = ROLE_CULTIST
		M.mind.restricted_roles = restricted_roles
	return TRUE

/datum/dynamic_ruleset/roundstart/bloodcult/execute()
	main_cult = new
	for(var/datum/mind/M in assigned)
		var/datum/antagonist/cult/new_cultist = new antag_datum()
		new_cultist.cult_team = main_cult
		new_cultist.give_equipment = TRUE
		M.add_antag_datum(new_cultist)
	main_cult.setup_objectives()
	return TRUE

/datum/dynamic_ruleset/roundstart/bloodcult/round_result()
	..()
	if(main_cult.check_cult_victory())
		SSticker.mode_result = "win - cult win"
		SSticker.news_report = CULT_SUMMON
	else
		SSticker.mode_result = "loss - staff stopped the cult"
		SSticker.news_report = CULT_FAILURE

//////////////////////////////////////////////
//                                          //
//          NUCLEAR OPERATIVES              //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/nuclear
	name = "Nuclear Emergency"
	antag_flag = ROLE_OPERATIVE
	antag_datum = /datum/antagonist/nukeop
	var/datum/antagonist/antag_leader_datum = /datum/antagonist/nukeop/leader
	minimum_required_age = 0 // BLUEMOON EDIT
	restricted_roles = list("Head of Security","Bridge Officer", "Captain") // Just to be sure that a nukie getting picked won't ever imply a Captain or HoS not getting drafted
	required_candidates = 5
	weight = 3 //BLUEMOON CHANGES
	cost = 20
	intensity = 45
	requirements = list(101,101,101,101,101,101,60,40,30,10) //BLUEMOON CHANGES
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD) // BLUEMOON ADD
	flags = HIGH_IMPACT_RULESET
	antag_cap = list("denominator" = 18, "offset" = 1)
	var/datum/team/nuclear/nuke_team

/datum/dynamic_ruleset/roundstart/nuclear/ready(population, forced = FALSE)
	required_candidates = get_antag_cap(population)
	. = ..()

/datum/dynamic_ruleset/roundstart/nuclear/pre_execute(population)
	. = ..()
	// If ready() did its job, candidates should have 5 or more members in it
	var/operatives = get_antag_cap(population)
	for(var/operatives_number = 1 to operatives)
		// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
		if(candidates.len <= 0)
			message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
			break
		// BLUEMOON ADD END
		var/mob/M = pick_n_take(candidates)
		assigned += M.mind
		M.mind.assigned_role = "Nuclear Operative"
		M.mind.special_role = "Nuclear Operative"
	return TRUE

/datum/dynamic_ruleset/roundstart/nuclear/execute()
	var/leader = TRUE
	for(var/datum/mind/M in assigned)
		if (leader)
			leader = FALSE
			var/datum/antagonist/nukeop/leader/new_op = M.add_antag_datum(antag_leader_datum)
			nuke_team = new_op.nuke_team
		else
			var/datum/antagonist/nukeop/new_op = new antag_datum()
			M.add_antag_datum(new_op)
	return TRUE

/datum/dynamic_ruleset/roundstart/nuclear/round_result()
	var/result = nuke_team.get_result()
	switch(result)
		if(NUKE_RESULT_FLUKE)
			SSticker.mode_result = "loss - syndicate nuked - disk secured"
			SSticker.news_report = NUKE_SYNDICATE_BASE
		if(NUKE_RESULT_NUKE_WIN)
			SSticker.mode_result = "win - syndicate nuke"
			SSticker.news_report = STATION_NUKED
		if(NUKE_RESULT_NOSURVIVORS)
			SSticker.mode_result = "halfwin - syndicate nuke - did not evacuate in time"
			SSticker.news_report = STATION_NUKED
		if(NUKE_RESULT_WRONG_STATION)
			SSticker.mode_result = "halfwin - blew wrong station"
			SSticker.news_report = NUKE_MISS
		if(NUKE_RESULT_WRONG_STATION_DEAD)
			SSticker.mode_result = "halfwin - blew wrong station - did not evacuate in time"
			SSticker.news_report = NUKE_MISS
		if(NUKE_RESULT_CREW_WIN_SYNDIES_DEAD)
			SSticker.mode_result = "loss - evacuation - disk secured - syndi team dead"
			SSticker.news_report = OPERATIVES_KILLED
		if(NUKE_RESULT_CREW_WIN)
			SSticker.mode_result = "loss - evacuation - disk secured"
			SSticker.news_report = OPERATIVES_KILLED
		if(NUKE_RESULT_DISK_LOST)
			SSticker.mode_result = "halfwin - evacuation - disk not secured"
			SSticker.news_report = OPERATIVE_SKIRMISH
		if(NUKE_RESULT_DISK_STOLEN)
			SSticker.mode_result = "halfwin - detonation averted"
			SSticker.news_report = OPERATIVE_SKIRMISH
		else
			SSticker.mode_result = "halfwin - interrupted"
			SSticker.news_report = OPERATIVE_SKIRMISH

//////////////////////////////////////////////
//                                          //
//               REVS                       //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/revs
	name = "Revolution"
	persistent = TRUE
	antag_flag = ROLE_REV_HEAD
	antag_flag_override = ROLE_REV
	antag_datum = /datum/antagonist/rev/head
	minimum_required_age = 0 // BLUEMOON EDIT
	protected_roles = list("NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")  //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_candidates = 3
	weight = 3 //BLUEMOON CHANGES
	delay = 5 MINUTES //BLUEMOON CHANGES
	cost = 20
	intensity = 45
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,101,60,50,40,30,20) //BLUEMOON CHANGES
	antag_cap = 3
	flags = HIGH_IMPACT_RULESET
	blocking_rules = list(/datum/dynamic_ruleset/latejoin/provocateur)
	// I give up, just there should be enough heads with 35 players...
//	min_players = 30 //BLUEMOON REMOVAL
	/// How much threat should be injected when the revolution wins?
	var/revs_win_threat_injection = 20
	var/datum/team/revolution/revolution
	var/finished = FALSE

/datum/dynamic_ruleset/roundstart/revs/pre_execute(population)
	. = ..()
	message_admins("В связи с особенностями игрового режима и заходом игроков после начала раунда, до выдачи ролей революцинерам осталось <b>[delay/10] минут.</b>")
	var/max_candidates = get_antag_cap(population)
	for(var/i = 1 to max_candidates)
		// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
		if(candidates.len <= 0)
			message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
			break
		// BLUEMOON ADD END
		var/mob/M = pick_n_take(candidates)
		assigned += M.mind
		M.mind.restricted_roles = restricted_roles
		M.mind.special_role = antag_flag
	return TRUE

/datum/dynamic_ruleset/roundstart/revs/execute()
	revolution = new()
	for(var/datum/mind/M in assigned)
		if(check_eligible(M))
			var/datum/antagonist/rev/head/new_head = new antag_datum()
			new_head.give_flash = TRUE
			new_head.give_hud = TRUE
			new_head.remove_clumsy = TRUE
			M.add_antag_datum(new_head,revolution)
		else
			assigned -= M
			log_game("DYNAMIC: [ruletype] [name] discarded [M.name] from head revolutionary due to ineligibility.")
	if(revolution.members.len)
		revolution.update_objectives()
		revolution.update_heads()
		SSshuttle.registerHostileEnvironment(revolution)
		return TRUE
	log_game("DYNAMIC: [ruletype] [name] failed to get any eligible headrevs. Refunding [cost] threat.")
	return FALSE

/datum/dynamic_ruleset/roundstart/revs/clean_up()
	qdel(revolution)
	..()

/datum/dynamic_ruleset/roundstart/revs/rule_process()
	var/winner = revolution.process_victory(revs_win_threat_injection)
	if (isnull(winner))
		return

	finished = winner
	return RULESET_STOP_PROCESSING

/// Checks for revhead loss conditions and other antag datums.
/datum/dynamic_ruleset/roundstart/revs/proc/check_eligible(datum/mind/M)
	var/turf/T = get_turf(M.current)
	if(!considered_afk(M) && considered_alive(M) && is_station_level(T.z) && !M.antag_datums?.len && !HAS_TRAIT(M, TRAIT_MINDSHIELD))
		return TRUE
	return FALSE

/datum/dynamic_ruleset/roundstart/revs/round_result()
	revolution.round_result(finished)

//////////////////////////////////////////////
//                                          //
//               Clock Cult                 //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/clockcult
	name = "Clock Cult"
	antag_flag = ROLE_SERVANT_OF_RATVAR
	antag_datum = /datum/antagonist/clockcult
	minimum_required_age = 0 // BLUEMOON EDIT
	protected_roles = list("NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")  //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_candidates = 2
	weight = 3
	cost = 20
	intensity = 45
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,101,50,40,30,20,15) //BLUEMOON CHANGES
	flags = HIGH_IMPACT_RULESET
	antag_cap = list("denominator" = 20, "offset" = 1)
	var/datum/team/clockcult/main_clockcult

/datum/dynamic_ruleset/roundstart/clockcult/ready(population, forced = FALSE)
	required_candidates = get_antag_cap(population)
	. = ..()

/datum/dynamic_ruleset/roundstart/clockcult/pre_execute(population)
	. = ..()
	var/cultists = get_antag_cap(population)
	for(var/cultists_number = 1 to cultists)
		// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
		if(candidates.len <= 0)
			message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
			break
		// BLUEMOON ADD END
		var/mob/M = pick_n_take(candidates)
		assigned += M.mind
		M.mind.special_role = ROLE_SERVANT_OF_RATVAR
		M.mind.restricted_roles = restricted_roles
	return TRUE

/datum/dynamic_ruleset/roundstart/clockcult/execute()
	main_clockcult = new
	for(var/datum/mind/M in assigned)
		var/datum/antagonist/clockcult/new_cultist = new antag_datum()
		new_cultist.clock_team = main_clockcult
		new_cultist.give_equipment = TRUE
		M.add_antag_datum(new_cultist)
		SSticker.mode.equip_servant(M.current)
		SSticker.mode.greet_servant(M.current)
	return TRUE

/datum/dynamic_ruleset/roundstart/clockcult/round_result()
	..()
	if(main_clockcult.check_clockwork_victory())
		SSticker.mode_result = "win - servants completed their objective (summon ratvar)"
		SSticker.news_report = CLOCK_SUMMON
	else
		SSticker.mode_result = "loss - servants failed their objective (summon ratvar)"
		SSticker.news_report = CULT_FAILURE

//////////////////////////////////////////////
//                                          //
//                 FAMILIES                 //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/families
	name = "Families"
	persistent = TRUE
	antag_datum = /datum/antagonist/gang
	antag_flag = ROLE_FAMILIES
	force_antag_preference = TRUE
	protected_roles = list("NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")  //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_candidates = 3 //BLUEMOON CHANGES
	weight = 48
	cost = 10
	intensity = 45
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT) // BLUEMOON ADD
	requirements = list(101,10,10,10,10,10,10,10,10,10) //BLUEMOON CHANGES
	flags = HIGH_IMPACT_RULESET
	antag_cap = list("denominator" = 5, "offset" = 1) //BLUEMOON ADDITION
	/// A reference to the handler that is used to run pre_execute(), execute(), etc..
	var/datum/gang_handler/handler

/datum/dynamic_ruleset/roundstart/families/pre_execute()
	..()
	handler = new /datum/gang_handler(candidates,restricted_roles)
/*BLUEMOON REMOVAL START
	handler.gangs_to_generate = (antag_cap[indice_pop] / 2)
	handler.gang_balance_cap = clamp((indice_pop - 3), 2, 5) // gang_balance_cap by indice_pop: (2,2,2,2,2,3,4,5,5,5)
BLUEMOON REMOVAL END*/
	return handler.pre_setup_analogue()

/datum/dynamic_ruleset/roundstart/families/execute()
	return handler.post_setup_analogue(TRUE)

/datum/dynamic_ruleset/roundstart/families/clean_up()
	QDEL_NULL(handler)
	..()

/datum/dynamic_ruleset/roundstart/families/rule_process()
	return handler.process_analogue()

/datum/dynamic_ruleset/roundstart/families/round_result()
	return handler.set_round_result_analogue()

// Admin only rulesets. The threat requirement is 101 so it is not possible to roll them.

//////////////////////////////////////////////
//                                          //
//               EXTENDED                   //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/extended
	name = "Extended"
	antag_flag = null
	antag_datum = null
	restricted_roles = list()
	required_candidates = 0
	weight = 3
	cost = 0
	requirements = list(101,101,101,101,101,101,101,101,101,101)
	flags = LONE_RULESET

/datum/dynamic_ruleset/roundstart/extended/pre_execute()
	. = ..()
	message_admins("Starting a round of extended.")
	log_game("Starting a round of extended.")
//	mode.spend_roundstart_budget(mode.round_start_budget) //BLUEMOON REMOVAL
//	mode.spend_midround_budget(mode.mid_round_budget) //BLUEMOON REMOVAL
	mode.threat_log += "[worldtime2text()]: Extended ruleset set threat to 0."
	return TRUE

//////////////////////////////////////////////
//                                          //
//               CLOWN OPS                  //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/nuclear/clown_ops
	name = "Clown Ops"
	antag_flag = "clown ops"
	antag_datum = /datum/antagonist/nukeop/clownop
	antag_leader_datum = /datum/antagonist/nukeop/leader/clownop
	requirements = list(101,101,101,101,101,101,101,101,101,101)

/datum/dynamic_ruleset/roundstart/nuclear/clown_ops/pre_execute()
	. = ..()
	if(.)
		for(var/obj/machinery/nuclearbomb/syndicate/S in GLOB.nuke_list)
			var/turf/T = get_turf(S)
			if(T)
				qdel(S)
				new /obj/machinery/nuclearbomb/syndicate/bananium(T)
		for(var/datum/mind/V in assigned)
			V.assigned_role = "Clown Operative"
			V.special_role = "Clown Operative"


//////////////////////////////////////////////
//                                          //
//               MONKEY                     //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/monkey
	name = "Monkey"
	antag_flag = ROLE_MONKEY
	antag_datum = /datum/antagonist/monkey/leader
	protected_roles = list("NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")  //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_candidates = 1
	weight = 3
	cost = 0
	intensity = 15
	requirements = list(101,101,101,101,101,101,101,101,101,101)
	flags = LONE_RULESET
	var/players_per_carrier = 30
	var/monkeys_to_win = 1
	var/escaped_monkeys = 0
	var/datum/team/monkey/monkey_team

/datum/dynamic_ruleset/roundstart/monkey/pre_execute()
	. = ..()
	var/carriers_to_make = max(round(mode.roundstart_pop_ready / players_per_carrier, 1), 1)

	for(var/j = 0, j < carriers_to_make, j++)
		// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
		if(candidates.len <= 0)
			message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
			break
		// BLUEMOON ADD END
		var/mob/carrier = pick_n_take(candidates)
		assigned += carrier.mind
		carrier.mind.special_role = "Monkey Leader"
		carrier.mind.restricted_roles = restricted_roles
		log_game("[key_name(carrier)] has been selected as a Jungle Fever carrier")
	return TRUE

/datum/dynamic_ruleset/roundstart/monkey/execute()
	for(var/datum/mind/carrier in assigned)
		var/datum/antagonist/monkey/M = carrier.add_antag_datum(/datum/antagonist/monkey/leader)
		if(M)
			monkey_team = M.monkey_team
	return TRUE

/datum/dynamic_ruleset/roundstart/monkey/proc/check_monkey_victory()
	if(SSshuttle.emergency.mode != SHUTTLE_ENDGAME)
		return FALSE
	var/datum/disease/D = new /datum/disease/transformation/jungle_fever()
	for(var/mob/living/carbon/human/M in GLOB.alive_mob_list)
		if(!ismonkey(M))
			continue
		if (M.HasDisease(D))
			if(M.onCentCom() || M.onSyndieBase())
				escaped_monkeys++
	if(escaped_monkeys >= monkeys_to_win)
		return TRUE
	else
		return FALSE

// This does not get called. Look into making it work.
/datum/dynamic_ruleset/roundstart/monkey/round_result()
	if(check_monkey_victory())
		SSticker.mode_result = "win - monkey win"
	else
		SSticker.mode_result = "loss - staff stopped the monkeys"

//////////////////////////////////////////////
//                                          //
//               METEOR                     //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/meteor
	name = "Meteor"
	persistent = TRUE
	required_candidates = 0
	weight = 3
	cost = 0
	requirements = list(101,101,101,101,101,101,101,101,101,101)
	flags = LONE_RULESET
	var/meteordelay = 2000
	var/nometeors = FALSE
	var/rampupdelta = 5

/datum/dynamic_ruleset/roundstart/meteor/rule_process()
	if(nometeors || meteordelay > world.time - SSticker.round_start_time)
		return

	var/list/wavetype = GLOB.meteors_normal
	var/meteorminutes = (world.time - SSticker.round_start_time - meteordelay) / 10 / 60

	if (prob(meteorminutes))
		wavetype = GLOB.meteors_threatening

	if (prob(meteorminutes/2))
		wavetype = GLOB.meteors_catastrophic

	var/ramp_up_final = clamp(round(meteorminutes/rampupdelta), 1, 10)

	spawn_meteors(ramp_up_final, wavetype)

//////////////////////////////////////////////
//                                          //
//               BLOODSUCKERS               //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/bloodsuckers
	name = "Bloodsuckers"
	antag_flag = "shiftstart bloodsucker"
	antag_flag_override = ROLE_BLOODSUCKER
	antag_datum = /datum/antagonist/bloodsucker
	protected_roles = list("Expeditor", "Prisoner", "NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")  //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED) // BLUEMOON ADD
	required_candidates = 1
	weight = 6
	cost = 5
	scaling_cost = 10
	intensity = 15
	requirements = list(101,101,60,50,40,30,20,15,10,10)
	antag_cap = list("denominator" = 39, "offset" = 1)

// Мидраунд-тёзка "Bloodsuckers" уже занимает ключ конфига/intensity_ledger - суффикс разводит их.
/datum/dynamic_ruleset/roundstart/bloodsuckers/action_name()
	return "[name] (Roundstart)"

/datum/dynamic_ruleset/roundstart/bloodsuckers/pre_execute(population)
	. = ..()
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	var/num_bloodsuckers = get_antag_cap(population) * (scaled_times + 1)
	for (var/i = 1 to num_bloodsuckers)
		var/mob/M = pick_n_take(candidates)
		assigned += M.mind
		M.mind.restricted_roles = restricted_roles
		M.mind.special_role = antag_flag
	return TRUE

/datum/dynamic_ruleset/roundstart/bloodsuckers/trim_candidates()
	. = ..()
	for(var/mob/P in candidates)
		if(P.mob_weight > MOB_WEIGHT_HEAVY) // никаких сверхтяжёлых кровососов
			candidates -= P
		else if(HAS_TRAIT(P, TRAIT_ROBOTIC_ORGANISM)) // никаких роботов-вампиров из далекого космоса
			candidates -= P

//////////////////////////////////////////////
//                                          //
//           BLOB INFECTION (ROUNDSTART)    //
//                                          //
//////////////////////////////////////////////

/// Late-stage blob carriers at shift start — same antagonist datum as midround infection (timed pop into overmind).
/datum/dynamic_ruleset/roundstart/blob_infection
	name = "Blob Infection"
	antag_datum = /datum/antagonist/blob
	antag_flag = "blob roundstart"
	antag_flag_override = ROLE_BLOB
	minimum_required_age = 0
	protected_roles = list("Prisoner", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_candidates = 1
	min_players = 30
	weight = 4
	cost = 18
	scaling_cost = 0
	intensity = 45
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,50,40,30,20,10,10)
	flags = HIGH_IMPACT_RULESET

// Мидраунд-тёзка "Blob Infection" уже занимает ключ конфига/intensity_ledger - суффикс разводит их.
/datum/dynamic_ruleset/roundstart/blob_infection/action_name()
	return "[name] (Roundstart)"

/datum/dynamic_ruleset/roundstart/blob_infection/ready(population, forced = FALSE)
	if(forced)
		return ..()
	if(!length(candidates))
		return FALSE
	return ..()

/datum/dynamic_ruleset/roundstart/blob_infection/pre_execute(population)
	. = ..()
	if(!.)
		return FALSE
	if(!length(candidates))
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	var/mob/M = pick_n_take(candidates)
	assigned += M.mind
	M.mind.special_role = ROLE_BLOB
	M.mind.restricted_roles = restricted_roles
	message_admins("[ADMIN_LOOKUPFLW(M)] был выбран раундстартовым правилом [name].")
	log_game("DYNAMIC: [key_name(M)] был выбран раундстартовым правилом [name].")
	return TRUE

// ////////////////////////////////////////////
//                                          //
//          SLAVERS OF SYNDICATE            //
//                                          //
// ////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/slavers
	name = "Slavers"
	antag_flag = ROLE_SLAVER
	antag_datum = /datum/antagonist/slaver
	var/datum/antagonist/antag_leader_datum = /datum/antagonist/slaver/leader
	minimum_required_age = 0
	restricted_roles = list("Head of Security","Bridge Officer", "Captain") // Just to be sure that a nukie getting picked won't ever imply a Captain or HoS not getting drafted
	required_candidates = 4
	weight = 3
	cost = 20
	intensity = 45
	requirements = list(101,101,101,101,101,101,60,40,30,10)
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT)
	flags = LONE_RULESET
	antag_cap = list("denominator" = 18, "offset" = 1)
	var/datum/team/slavers/slavers_team

/datum/dynamic_ruleset/roundstart/slavers/ready(population, forced = FALSE)
	required_candidates = get_antag_cap(population)
	. = ..()

/datum/dynamic_ruleset/roundstart/slavers/pre_execute(population)
	. = ..()
	var/operatives = get_antag_cap(population)
	for(var/operatives_number = 1 to operatives)
		if(!candidates.len) // Проверяем наличие кандидатов
			message_admins("Ruleset [name] failed to activate due to lack of candidates.")
			return FALSE // Возвращаем FALSE если нет кандидатов
		var/mob/M = pick_n_take(candidates)
		assigned += M.mind
		M.mind.assigned_role = "Slaver"
		M.mind.special_role = "Slaver"
	return TRUE

/datum/dynamic_ruleset/roundstart/slavers/execute()
	var/leader = TRUE
	for(var/datum/mind/M in assigned)
		if (leader)
			leader = FALSE
			M.add_antag_datum(antag_leader_datum)
		else
			var/datum/antagonist/slaver/slavers_op = new antag_datum()
			M.add_antag_datum(slavers_op)
	return TRUE

//////////////////////////////////////////////
//                                          //
//           ABDUCTORS (ROUNDSTART)          //
//                                          //
//////////////////////////////////////////////
/// Совпадает с лимитом команд в code/modules/antagonists/abductor/abductor.dm (этот файл может собираться раньше).
#define ABDUCTOR_MAX_TEAMS_DYNAMIC_RS 4

/// Пара абдукторов на старте смены (учёный + агент), как у midround from_ghosts, но из готовых кандидатов.
/datum/dynamic_ruleset/roundstart/abductors
	name = "Abductors"
	antag_flag = "Abductor"
	antag_flag_override = ROLE_ABDUCTOR
	minimum_required_age = 0
	protected_roles = list("Expeditor", "Prisoner", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("AI", "Cyborg", "Positronic Brain")
	required_candidates = 2
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	min_players = 30
	weight = 4
	cost = 15
	scaling_cost = 0
	intensity = 15
	flags = LONE_RULESET
	requirements = list(101,101,101,101,40,30,20,15,10,10)

// Событие-тёзка "Abductors" уже занимает ключ конфига/intensity_ledger - суффикс разводит их.
/datum/dynamic_ruleset/roundstart/abductors/action_name()
	return "[name] (Roundstart)"

/datum/dynamic_ruleset/roundstart/abductors/ready(population, forced = FALSE)
	if(forced)
		return ..()
	if(length(candidates) < required_candidates)
		return FALSE
	return ..()

/datum/dynamic_ruleset/roundstart/abductors/pre_execute(population)
	. = ..()
	if(!.)
		return FALSE
	if(length(candidates) < required_candidates)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	var/list/human_pool = list()
	for(var/mob/M in candidates)
		if(ishuman(M))
			human_pool += M
	if(length(human_pool) < required_candidates)
		return FALSE
	var/mob/scientist_mob = pick_n_take(human_pool)
	var/mob/agent_mob = pick_n_take(human_pool)
	candidates -= scientist_mob
	candidates -= agent_mob
	if(!scientist_mob?.mind || !agent_mob?.mind)
		return FALSE
	assigned += scientist_mob.mind
	assigned += agent_mob.mind
	scientist_mob.mind.special_role = ROLE_ABDUCTOR
	agent_mob.mind.special_role = ROLE_ABDUCTOR
	scientist_mob.mind.restricted_roles = restricted_roles
	agent_mob.mind.restricted_roles = restricted_roles
	message_admins("[ADMIN_LOOKUPFLW(scientist_mob)] и [ADMIN_LOOKUPFLW(agent_mob)] выбраны раундстартовым правилом [name] (учёный и агент).")
	log_game("DYNAMIC: [key_name(scientist_mob)] и [key_name(agent_mob)] выбраны раундстартовым правилом [name].")
	return TRUE

/// assigned[1] — учёный, assigned[2] — агент; одна команда на пару.
/datum/dynamic_ruleset/roundstart/abductors/execute()
	if(length(assigned) < 2)
		return FALSE
	var/datum/mind/sci_mind = assigned[1]
	var/datum/mind/agent_mind = assigned[2]
	if(!sci_mind?.current || !agent_mind?.current)
		return FALSE
	if(!ishuman(sci_mind.current) || !ishuman(agent_mind.current))
		return FALSE
	if(/datum/team/abductor_team::team_count > ABDUCTOR_MAX_TEAMS_DYNAMIC_RS)
		stack_trace("Roundstart abductors could not spawn: abductor team limit exceeded.")
		return FALSE
	var/datum/team/abductor_team/new_team = new
	sci_mind.add_antag_datum(/datum/antagonist/abductor/scientist, new_team)
	agent_mind.add_antag_datum(/datum/antagonist/abductor/agent, new_team)
	return TRUE

#undef ABDUCTOR_MAX_TEAMS_DYNAMIC_RS

//////////////////////////////////////////////
//                                          //
//         Malfunctioning AI                //
//                                         //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/malf
	name = "Malfunctioning AI"
	antag_flag = ROLE_MALF
	antag_datum = /datum/antagonist/traitor
	minimum_required_age = 0
	required_candidates = 1
	exclusive_roles = list("AI")
	weight = 3
	cost = 20
	intensity = 45
	requirements = list(101,101,101,101,101,101,60,40,30,10)
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM)
	flags = HIGH_IMPACT_RULESET

/datum/dynamic_ruleset/roundstart/malf/pre_execute(population)
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE

	var/mob/dead/new_player/M = pick_n_take(candidates)
	if(!M?.mind)
		return FALSE

	if(!SSjob.AssignRole(M, "AI"))
		message_admins("Рулсет [name] не был активирован по причине невозможности выдать слот AI.")
		return FALSE

	assigned += M.mind
	M.mind.special_role = ROLE_MALF
	return TRUE

/datum/dynamic_ruleset/roundstart/malf/execute()
	for(var/datum/mind/M in assigned)
		var/datum/antagonist/traitor/T = new antag_datum()
		M.add_antag_datum(T)
	return TRUE
