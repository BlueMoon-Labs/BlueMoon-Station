GLOBAL_LIST_INIT(brother_protected_roles, list(BROTHER_PROTECTED_ROLE_NAMES))

/datum/dynamic_ruleset/roundstart/traitorbro
	name = "Blood Brothers"
	antag_flag = ROLE_BROTHER
	antag_datum = /datum/antagonist/brother
	protected_roles = list(BROTHER_PROTECTED_ROLE_NAMES)
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_candidates = BROTHER_TEAM_START_SIZE
	weight = 6
	// Пара без аплинка и снаряжения угрожает раунду меньше соло-агента (cost 8/9) и в нагрузке директора весит ниже его
	cost = 6
	scaling_cost = 6
	intensity = 10
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT)
	requirements = list(101,101,101,101,60,50,40,30,20,10)
	antag_cap = 2
	var/list/datum/team/brother_team/pre_brother_teams = list()

/datum/dynamic_ruleset/roundstart/traitorbro/pre_execute(population)
	. = ..()
	var/num_teams = max(1, round(get_antag_cap(population) / BROTHER_TEAM_START_SIZE)) * (scaled_times + 1)
	for(var/team_number in 1 to num_teams)
		if(length(candidates) < BROTHER_TEAM_START_SIZE)
			break
		var/datum/team/brother_team/team = new
		for(var/member_number in 1 to BROTHER_TEAM_START_SIZE)
			var/mob/candidate = pick_n_take(candidates)
			assigned += candidate.mind
			team.add_member(candidate.mind)
			candidate.mind.special_role = ROLE_BROTHER
			candidate.mind.restricted_roles = restricted_roles
		pre_brother_teams += team
	if(!length(pre_brother_teams))
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	return TRUE

/datum/dynamic_ruleset/roundstart/traitorbro/execute()
	for(var/datum/team/brother_team/team as anything in pre_brother_teams)
		for(var/datum/mind/member as anything in team.members)
			member.add_antag_datum(/datum/antagonist/brother, team)
		team.start()
	return TRUE

/datum/dynamic_ruleset/midround/crew_conversion/blood_brothers
	name = "Blood Brothers Awakening"
	antag_datum = /datum/antagonist/brother
	antag_flag = "brother mid"
	antag_flag_override = ROLE_BROTHER
	protected_roles = list(BROTHER_PROTECTED_ROLE_NAMES, "Prisoner")
	required_candidates = BROTHER_TEAM_START_SIZE
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT)
	weight = 5
	cost = 8
	intensity = 10
	family = "brother"
	requirements = list(101,101,40,30,20,10,10,10,10,10)

/datum/dynamic_ruleset/midround/crew_conversion/blood_brothers/can_convert(mob/living/player)
	var/datum/mind/player_mind = player.mind
	if(player_mind && HAS_TRAIT(player_mind, TRAIT_BLOOD_OATH_SEVERED))
		return FALSE
	return ..() && !HAS_TRAIT(player, TRAIT_MINDSHIELD)

/datum/dynamic_ruleset/midround/crew_conversion/blood_brothers/prune_stale_living_players()
	for(var/mob/living/player as anything in living_players.Copy())
		if(QDELETED(player) || !player.mind || !GET_CLIENT(player) || !can_convert(player))
			living_players -= player

/datum/dynamic_ruleset/midround/crew_conversion/blood_brothers/execute()
	prune_stale_living_players()
	if(length(living_players) < BROTHER_TEAM_START_SIZE)
		execution_failure_reason = "кандидаты выбыли между отбором и исполнением"
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		log_game("DYNAMIC: [name] не активирован: кандидаты выбыли между отбором и исполнением.")
		return FALSE
	var/datum/team/brother_team/team = new
	for(var/member_number in 1 to BROTHER_TEAM_START_SIZE)
		var/mob/picked = pick_n_take(living_players)
		assigned += picked.mind
		team.add_member(picked.mind)
	for(var/datum/mind/member as anything in team.members)
		to_chat(member.current, span_boldwarning("Вы вспоминаете старую клятву..."))
		member.add_antag_datum(antag_datum, team)
		message_admins("[ADMIN_LOOKUPFLW(member.current)] was selected by the [name] ruleset.")
		log_game("DYNAMIC: [key_name(member.current)] was selected by the [name] ruleset.")
	team.start()
	return TRUE
