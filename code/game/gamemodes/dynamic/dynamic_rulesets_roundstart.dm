
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
	protected_roles = list("Expeditor", "Shaft Miner", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("AI", "Cyborg", "Positronic Brain") //BLUEMOON CHANGES
	required_candidates = 1
	weight = 13 //BLUEMOON CHANGES
	cost = 8 // Avoid raising traitor threat above 10, as it is the default low cost ruleset.
	scaling_cost = 9
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT) // BLUEMOON ADD
	requirements = list(101,10,10,10,10,10,10,10,10,10) //BLUEMOON CHANGES
	antag_cap = list("denominator" = 20) //BLUEMOON CHANGES
	var/autotraitor_cooldown = (30 MINUTES) //BLUEMOON CHANGES
	COOLDOWN_DECLARE(autotraitor_cooldown_check)

/datum/dynamic_ruleset/roundstart/traitor/pre_execute(population)
	. = ..()
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	COOLDOWN_START(src, autotraitor_cooldown_check, autotraitor_cooldown)
	var/num_traitors = get_antag_cap(population) * (scaled_times + 1)
	for (var/i = 1 to num_traitors)
		var/mob/M = pick_n_take(candidates)
		assigned += M?.mind
		M.mind.special_role = ROLE_TRAITOR
		M.mind.restricted_roles = restricted_roles
	return TRUE

/datum/dynamic_ruleset/roundstart/traitor/rule_process()
	if (COOLDOWN_FINISHED(src, autotraitor_cooldown_check))
		COOLDOWN_START(src, autotraitor_cooldown_check, autotraitor_cooldown)
		log_game("DYNAMIC: Checking if we can turn someone into a traitor.")
		mode.picking_specific_rule(/datum/dynamic_ruleset/midround/autotraitor)

//////////////////////////////////////////
//                                      //
//           BLOOD BROTHERS             //
//                                      //
//////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/traitorbro
	name = "Blood Brothers"
	antag_flag = ROLE_BROTHER
	antag_datum = /datum/antagonist/brother
	protected_roles = list("Expeditor", "Shaft Miner", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI")
	required_candidates = 2
	weight = 6 //BLUEMOON CHANGES
	cost = 15
	scaling_cost = 15
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
	protected_roles = list("Expeditor", "Prisoner", "Shaft Miner", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("AI", "Cyborg", "Positronic Brain")
	required_candidates = 1
	weight = 8 //BLUEMOON CHANGES
	cost = 15 //BLUEMOON CHANGES
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT) // BLUEMOON ADD
	scaling_cost = 10
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
	protected_roles = list("Expeditor", "Prisoner", "Shaft Miner", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("AI", "Cyborg", "Positronic Brain")
	required_candidates = 1
	weight = 8 //BLUEMOON CHANGES
	cost = 15
	scaling_cost = 9
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
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
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
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,101,60,50,40,30,20) //BLUEMOON CHANGES
	antag_cap = 3
	flags = HIGH_IMPACT_RULESET
	blocking_rules = list(/datum/dynamic_ruleset/latejoin/provocateur)
	// I give up, just there should be enough heads with 35 players...
//	minimum_players = 30 //BLUEMOON REMOVAL
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
	protected_roles = list("NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")  //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_candidates = 3 //BLUEMOON CHANGES
	weight = 20
	cost = 15
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT) // BLUEMOON ADD
	requirements = list(0,101,101,101,40,20,20,10,10,10) //BLUEMOON CHANGES
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
//BLUEMOON ADDITION AHEAD - новые раундстартовые роли из мидраунда
//////////////////////////////////////////////
//                                          //
//            SPACE NINJA                   //
//                                          //
//////////////////////////////////////////////

// /datum/dynamic_ruleset/roundstart/space_ninja
// 	name = "Space Ninja"
// 	antag_datum = /datum/antagonist/ninja
// 	antag_flag = "shiftstart space ninja"
// 	antag_flag_override = ROLE_NINJA
// 	flags = LONE_RULESET
// 	required_candidates = 1
// 	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
// 	weight = 6 //BLUEMOON CHANGES
// 	cost = 20
// 	requirements = list(101,101,101,60,40,20,20,20,10,10)
// 	var/list/spawn_locs = list()

// /datum/dynamic_ruleset/roundstart/space_ninja/pre_execute()
// 	. = ..()

// 	for(var/obj/effect/landmark/carpspawn/carp_spawn in GLOB.landmarks_list)
// 		if(!isturf(carp_spawn.loc))
// 			stack_trace("Carp spawn found not on a turf: [carp_spawn.type] on [isnull(carp_spawn.loc) ? "null" : carp_spawn.loc.type]")
// 			continue
// 		spawn_locs += carp_spawn.loc
// 	if(!spawn_locs.len)
// 		log_game("No valid spawn locations for [name], found, aborting...")
// 		message_admins("No valid spawn locations for [name] found, aborting...")
// 		return MAP_ERROR

// 	return TRUE

// /datum/dynamic_ruleset/roundstart/space_ninja/execute()
// 	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
// 	if(candidates.len <= 0)
// 		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
// 		return FALSE
// 	// BLUEMOON ADD END
// 	var/mob/candidate = pick_n_take(candidates)
// 	assigned += candidate.mind

// 	for(var/datum/mind/M in assigned)

// 		var/mob/living/carbon/human/ninja = create_space_ninja(pick(spawn_locs))
// 		var/current_key = M.current.key
// 		qdel(M.current)
// 		ninja.key = current_key

// 		ninja.mind.add_antag_datum(/datum/antagonist/ninja)
// 		return ninja

//////////////////////////////////////////////
//                                          //
//           XENOMORPH                      //
//                                          //
//////////////////////////////////////////////

// /datum/dynamic_ruleset/roundstart/xenomorph
// 	name = "Alien Infestation"
// 	antag_datum = /datum/antagonist/xeno
// 	antag_flag = "shiftstart xenomorph"
// 	antag_flag_override = ROLE_ALIEN
// 	required_candidates = 2
// 	weight = 3
// 	cost = 20
// 	flags = HIGH_IMPACT_RULESET
// 	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
// 	requirements = list(101,101,101,60,40,20,20,20,10,10)
// 	var/list/vents = list()
// 	antag_cap = list("denominator" = 20, "offset" = 1)

// /datum/dynamic_ruleset/roundstart/xenomorph/pre_execute()
// 	. = ..()
// 	// 50% chance of being incremented by one
// 	required_candidates += prob(50)
// 	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in GLOB.machines)
// 		if(QDELETED(temp_vent))
// 			continue
// 		if(is_station_level(temp_vent.loc.z) && !temp_vent.welded)
// 			var/datum/pipeline/temp_vent_parent = temp_vent.parents[1]
// 			if(!temp_vent_parent)
// 				continue // No parent vent
// 			// Stops Aliens getting stuck in small networks.
// 			// See: Security, Virology
// 			if(temp_vent_parent.other_atmosmch.len > 20)
// 				vents += temp_vent
// 	if(!vents.len)
// 		log_game("No valid spawn locations for [name], found, aborting...")
// 		message_admins("No valid spawn locations for [name], found, aborting...")
// 		return FALSE

// /datum/dynamic_ruleset/roundstart/xenomorph/execute()
// 	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
// 	if(candidates.len <= 0)
// 		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
// 		return FALSE
// 	// BLUEMOON ADD END
// 	var/mob/candidate = pick_n_take(candidates)
// 	assigned += candidate.mind

// 	var/obj/vent = pick_n_take(vents)
// 	for(var/datum/mind/M in assigned)

// 		var/mob/living/carbon/alien/larva/new_xeno = new(vent.loc)
// 		var/current_key = M.current.key
// 		qdel(M.current)
// 		new_xeno.key = current_key

// 		return new_xeno

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
	protected_roles = list("Expeditor", "Prisoner", "Shaft Miner", "NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")  //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT) // BLUEMOON ADD
	required_candidates = 1
	weight = 6
	cost = 5
	scaling_cost = 10
	requirements = list(101,101,60,50,40,30,20,15,10,10)
	antag_cap = list("denominator" = 39, "offset" = 1)

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
//               OVERTHROWN                 //
//                                          //
//////////////////////////////////////////////


/* TODO
/datum/dynamic_ruleset/roundstart/overthrown
	name = "Overthrown"
	antag_flag = ROLE_OVERTHROW
	antag_datum = /datum/antagonist/overthrow
	minimum_required_age = 0
	restricted_roles = list("AI", "Cyborg", "Prisoner", "Shaft Miner", "NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	required_candidates = 1
	weight = 38888
	delay = 5 SECONDS //BLUEMOON CHANGES
	cost = 0
	requirements = list(1,101,101,101,101,60,50,40,30,20) //BLUEMOON CHANGES
	antag_cap = 3
	flags = HIGH_IMPACT_RULESET

/datum/dynamic_ruleset/roundstart/overthrown/pre_execute(population)
	. = ..()
	message_admins("В связи с особенностями игрового режима и заходом игроков после начала раунда, до выдачи ролей путчистов осталось <b>[delay/10] минут.</b>")


	var/active_players = 0
	for(var/mob/dead/new_player/player in GLOB.player_list)
		if(player.client)
			active_players++

//	var/max_candidates = required_enemies + round(active_players*0.05) // At 100 players, it'd be 2 + 5 = 7 teams existing.
	var/max_candidates = 1

	for (var/i in 1 to max_candidates)
		if(candidates.len <= 0)
			break
		var/mob/M = pick_n_take(candidates)
		assigned += M.mind
		M.mind.restricted_roles = restricted_roles
		M.mind.special_role = antag_flag
	return TRUE

/// Give your candidates or assignees equipment and antag datum here.
/datum/dynamic_ruleset/oundstart/overthrown/execute()
	for(var/datum/mind/M in assigned)
		var/datum/antagonist/overthrow/O = M.add_antag_datum(/datum/antagonist/overthrow) // create_team called on_gain will create the team
		O.equip_initial_overthrow_agent()
	return TRUE

*/

//////////////////////////////////////////////
//                                          //
//           ABDUCTORS                      //
//                                          //
//////////////////////////////////////////////
// #define ABDUCTOR_MAX_TEAMS 4

// /datum/dynamic_ruleset/roundstart/abductors
// 	name = "Abductors"
// 	antag_flag = "Abductor"
// 	antag_flag_override = ROLE_ABDUCTOR
// 	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_TEAMBASED) // BLUEMOON ADD
// 	required_candidates = 2
// 	weight = 3
// 	cost = 2
// 	scaling_cost = 9
// 	requirements = list(0,101,101,60,40,20,20,20,10,10)
// 	var/datum/team/abductor_team/new_team

// /datum/dynamic_ruleset/roundstart/abductors/execute(mob/new_character, index)
// 	if (index == 1) // Our first guy is the scientist.  We also initialize the team here as well since this should only happen once per pair of abductors.
// 		new_team = new
// 		if(new_team.team_number > ABDUCTOR_MAX_TEAMS)
// 			return MAP_ERROR
// 		var/datum/antagonist/abductor/scientist/new_role = new
// 		new_character.mind.add_antag_datum(new_role, new_team)
// 	else // Our second guy is the agent, team is already created, don't need to make another one.
// 		var/datum/antagonist/abductor/agent/new_role = new
// 		new_character.mind.add_antag_datum(new_role, new_team)

// #undef ABDUCTOR_MAX_TEAMS

/// Вероятность того, что переход ИИ в состояние мальформации будет сопровождаться объявлением об ионной буре и некоторыми ионными законами.

#define MALF_ION_PROB 33
/// Вероятность замены существующего закона ионным законом вместо добавления нового ионного закона.

#define REPLACE_LAW_WITH_ION_PROB 10
//////////////////////////////////////////////
//                                          //
//         Malfunctioning AI                //
//                                         //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/malf
	name = "Malfunctioning AI"
	antag_datum = /datum/antagonist/traitor
	antag_flag = ROLE_MALF
	enemy_roles = list("Blueshield",  "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Scientist", "Chemist", "Research Director", "Chief Engineer") //BLUEMOON CHANGES
	exclusive_roles = list("AI")
	required_enemies = list(0,0,0,0,0,0,0,0,0,0)
	required_candidates = 1
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	weight = 6 //BLUEMOON CHANGES
	cost = 15 //BLUEMOON CHANGES - было 35, сейчас это обычный предатель
	requirements = list(101,101,80,70,60,60,50,50,40,40)
	required_type = /mob/living/silicon/ai

/datum/dynamic_ruleset/midround/malf/trim_candidates()
	. = ..()
	candidates = living_players
	for(var/mob/living/player in candidates)
		if(!isAI(player))
			candidates -= player
			continue

		if(is_centcom_level(player.z))
			candidates -= player
			continue

		if(player.mind && (player.mind.special_role || length(player.mind.antag_datums)))
			candidates -= player

/datum/dynamic_ruleset/midround/malf/execute()
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	var/mob/living/silicon/ai/M = pick_n_take(candidates)
	assigned += M.mind
	var/datum/antagonist/traitor/AI = new
	M.mind.special_role = antag_flag
	M.mind.add_antag_datum(AI)
	if(prob(MALF_ION_PROB))
		priority_announce("Ion storm detected near the station. Please check all AI-controlled equipment for errors.", "ВНИМАНИЕ: АНОМАЛИЯ", "ionstorm")
		if(prob(REPLACE_LAW_WITH_ION_PROB))
			M.replace_random_law(generate_ion_law(), list(LAW_INHERENT, LAW_SUPPLIED, LAW_ION))
		else
			M.add_ion_law(generate_ion_law())
	return TRUE
