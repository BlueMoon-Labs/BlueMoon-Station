//////////////////////////////////////////////
//                                          //
//            MIDROUND RULESETS             //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround // Can be drafted once in a while during a round
	ruletype = "Midround"
	/// If the ruleset should be restricted from ghost roles.
	var/restrict_ghost_roles = TRUE
	/// What mob type the ruleset is restricted to.
	var/required_type = /mob/living/carbon/human
	var/should_use_midround_pref = TRUE
	var/list/living_players = list()
	var/list/living_antags = list()
	var/list/dead_players = list()
	var/list/list_observers = list()
	/// Деталь последней проверки ready() для панели и истории исполнения.
	var/ready_failure_reason = null

/// Директор выбрал midround-рулсет: собираем кандидатов (trim -> ready),
/// затем отложенно исполняем с учётом delay. Бюджет уже списан в SSdirector.spend_and_execute.
/datum/dynamic_ruleset/midround/execute_action()
	trim_candidates()
	if(!ready())
		return FALSE
	addtimer(CALLBACK(mode, TYPE_PROC_REF(/datum/game_mode/dynamic, execute_scheduled_ruleset), src), delay)
	return TRUE

/// Неинтерактивная проверка непосредственно перед выбором директора. null означает, что рулсет
/// не поддерживает preflight и будет проверен обычным execute_action(). Наследники не должны
/// открывать опросы или выдавать роли отсюда: панель вызывает этот proc каждые несколько секунд.
/datum/dynamic_ruleset/midround/director_preflight()
	return null

/// Общий безопасный preflight для рулсетов, которые после trim_candidates() кладут всех
/// потенциальных получателей роли в candidates. В отличие от crew-wizard этот путь не поллит.
/datum/dynamic_ruleset/midround/proc/director_preflight_candidates()
	trim_candidates()
	if(length(candidates) < required_candidates)
		ready_failure_reason = "подходящих членов экипажа [length(candidates)] из [required_candidates] (преференс midround, роль, бан и ограничения)"
		director_preflight_failure = ready_failure_reason
		return FALSE
	if(!ready())
		director_preflight_failure = ready_failure_reason
		return FALSE
	director_preflight_detail = "подходящих членов экипажа: [length(candidates)], требуется: [required_candidates]"
	director_preflight_failure = null
	return TRUE

/datum/dynamic_ruleset/midround/from_ghosts
	// Игроки приходят из призраков, а не из экипажа - своя ступень директора со своим
	// кошельком и своими паузами, независимыми от станционных антагов.
	severity = DIRECTOR_SEVERITY_GHOST
	weight = 0
	required_type = /mob/dead/observer
	should_use_midround_pref = FALSE
	/// Whether the ruleset should call generate_ruleset_body or not.
	var/makeBody = TRUE
	/// The rule needs this many applicants to be properly executed.
	var/required_applicants = 1

/datum/dynamic_ruleset/midround/trim_candidates()
	living_players = trim_list(mode.current_players[CURRENT_LIVING_PLAYERS])
	living_antags = trim_list(mode.current_players[CURRENT_LIVING_ANTAGS])
	dead_players = trim_list(mode.current_players[CURRENT_DEAD_PLAYERS])
	list_observers = trim_list(mode.current_players[CURRENT_OBSERVERS])

/datum/dynamic_ruleset/midround/proc/trim_list(list/L = list())
	var/list/trimmed_list = L.Copy()
	for(var/mob/M in trimmed_list)
		if (!istype(M, required_type))
			trimmed_list.Remove(M)
			continue
		if (!M.client) // Are they connected?
			trimmed_list.Remove(M)
			continue
		if(required_type == /mob/dead/observer && !M.can_reenter_round(TRUE))
			trimmed_list.Remove(M)
			continue
		if(should_use_midround_pref && !(M.client.prefs.toggles & MIDROUND_ANTAG))
			trimmed_list.Remove(M)
			continue
		if(!mode.check_age(M.client, minimum_required_age))
			trimmed_list.Remove(M)
			continue
		if(!has_required_antag_preference(M.client))
			trimmed_list.Remove(M)
			continue
		var/role_to_bancheck_mr = antag_flag_override ? antag_flag_override : antag_flag
		if(role_to_bancheck_mr && (jobban_isbanned(M, role_to_bancheck_mr) || QDELETED(M)))
			trimmed_list.Remove(M)
			continue
		if(jobban_isbanned(M, ROLE_INTEQ) || QDELETED(M))
			trimmed_list.Remove(M)
			continue
		if (M.mind)
			if (restrict_ghost_roles && (M.mind.assigned_role in GLOB.exp_specialmap[EXP_TYPE_SPECIAL])) // Are they playing a ghost role?
				trimmed_list.Remove(M)
				continue
			if (M.mind.assigned_role in restricted_roles) // Does their job allow it?
				trimmed_list.Remove(M)
				continue
			if ((exclusive_roles.len > 0) && !(M.mind.assigned_role in exclusive_roles)) // Is the rule exclusive to their job?
				trimmed_list.Remove(M)
				continue
			// BLUEMOON ADD START
			if(!(M.client.prefs.toggles & MIDROUND_ANTAG) && required_type != /mob/dead/observer) // У игрока отключен преф "быть антагонистом посреди раунда" и это не запрос для гостов
				trimmed_list.Remove(M)
				continue
			// BLUEMOON ADD END
	return trimmed_list

// You can then for example prompt dead players in execute() to join as strike teams or whatever
// Or autotator someone

// IMPORTANT, since /datum/dynamic_ruleset/midround may accept candidates from both living, dead, and even antag players, you need to manually check whether there are enough candidates
// (see /datum/dynamic_ruleset/midround/autotraitor/ready(forced = FALSE) for example)
/datum/dynamic_ruleset/midround/ready(forced = FALSE)
	ready_failure_reason = null
	director_preflight_detail = null
	director_preflight_failure = null
	if (!forced)
		var/job_check = 0
		if (enemy_roles.len > 0)
			for (var/mob/M in mode.current_players[CURRENT_LIVING_PLAYERS])
				if (M.stat == DEAD || !M.client)
					continue // Dead/disconnected players cannot count as opponents
				if (M.mind && (M.mind.assigned_role in enemy_roles) && (!(M in candidates) || (M.mind.assigned_role in restricted_roles)))
					job_check++ // Checking for "enemies" (such as sec officers). To be counters, they must either not be candidates to that rule, or have a job that restricts them from it

		var/threat = round(mode.threat_level/10)
		if (job_check < required_enemies[threat])
			ready_failure_reason = "контрролей [job_check] из [required_enemies[threat]] (уровень угрозы [mode.threat_level])"
			return FALSE
	return TRUE

/datum/dynamic_ruleset/midround/from_ghosts/ready(forced = FALSE)
	if(!..())
		return FALSE
	var/eligible_ghosts = length(dead_players) + length(list_observers)
	if(eligible_ghosts < required_applicants)
		var/role_preference = antag_flag_override ? antag_flag_override : antag_flag
		ready_failure_reason = "подходящих гостов [eligible_ghosts] из [required_applicants] (нужна включённая роль [role_preference], без бана и ограничений)"
		return FALSE
	director_preflight_detail = "подходящих гостов: [eligible_ghosts], требуется: [required_applicants]"
	return TRUE

/datum/dynamic_ruleset/midround/from_ghosts/director_preflight()
	trim_candidates()
	. = ready()
	director_preflight_failure = . ? null : ready_failure_reason

/datum/dynamic_ruleset/midround/from_ghosts/execute()
	execution_failure_reason = null
	var/list/possible_candidates = list()
	possible_candidates.Add(dead_players)
	possible_candidates.Add(list_observers)
	send_applications(possible_candidates)
	if(assigned.len > 0)
		return TRUE
	else
		if(!execution_failure_reason)
			execution_failure_reason = "опрос завершился без достаточного числа подходящих желающих"
		return FALSE

/// This sends a poll to ghosts if they want to be a ghost spawn from a ruleset.
/datum/dynamic_ruleset/midround/from_ghosts/proc/send_applications(list/possible_volunteers = list())
	if (possible_volunteers.len <= 0) // This shouldn't happen, as ready() should return FALSE if there is not a single valid candidate
		execution_failure_reason = "к моменту опроса не осталось подходящих призраков"
		message_admins("Possible volunteers was 0. This shouldn't appear, because of ready(), unless you forced it!")
		return
	message_admins("Polling [possible_volunteers.len] players to apply for the [name] ruleset.")
	log_game("DYNAMIC: Polling [possible_volunteers.len] players to apply for the [name] ruleset.")
	var/flag = antag_flag_override ? antag_flag_override : antag_flag
	candidates = pollGhostCandidates("The mode is looking for volunteers to become [antag_flag] for [name]", flag, be_special_flag = flag, ignore_category = antag_flag, poll_time = 300, poll_header = "[name] ([antag_flag])", poll_alert_pic = /obj/item/card/id/syndicate)

	if(!length(candidates))
		execution_failure_reason = "на гост-опрос не откликнулся ни один подходящий игрок"
		mode.dynamic_log("The ruleset [name] received no applications.")
		mode.executed_rules -= src
		attempt_replacement()
		return

	message_admins("[candidates.len] players volunteered for the ruleset [name].")
	log_game("DYNAMIC: [candidates.len] players volunteered for [name].")
	review_applications()

/// Here is where you can check if your ghost applicants are valid for the ruleset.
/// Called by send_applications().
/datum/dynamic_ruleset/midround/from_ghosts/proc/review_applications()
	if(candidates.len < required_applicants)
		execution_failure_reason = "на гост-опрос откликнулось [candidates.len] из необходимых [required_applicants]"
		mode.executed_rules -= src
		return
	for (var/i = 1, i <= required_candidates, i++)
		if(candidates.len <= 0)
			break
		var/mob/applicant = pick(candidates)
		candidates -= applicant
		if(!isobserver(applicant))
			if(applicant.stat == DEAD) // Not an observer? If they're dead, make them one.
				applicant = applicant.ghostize(FALSE)
			else // Not dead? Disregard them, pick a new applicant
				i--
				continue

		if(!applicant)
			i--
			continue

		var/mob/new_character = applicant

		if (makeBody)
			new_character = generate_ruleset_body(applicant)

		finish_setup(new_character, i)
		// Разум нового тела, не моб-призрак: assigned держит minds - по ним директор
		// считает живой вклад рулсета в intensity (см. tally_ruleset_intensity).
		assigned += new_character.mind
		notify_ghosts("[new_character] has been picked for the ruleset [name]!", source = new_character, action = NOTIFY_ORBIT, header="Something Interesting!")

/datum/dynamic_ruleset/midround/from_ghosts/proc/generate_ruleset_body(mob/applicant)
	var/mob/living/carbon/human/new_character = makeBody(applicant)
	new_character.dna.remove_all_mutations()
	return new_character

/datum/dynamic_ruleset/midround/from_ghosts/proc/finish_setup(mob/new_character, index)
	var/datum/antagonist/new_role = new antag_datum()
	setup_role(new_role)
	new_character.mind.add_antag_datum(new_role)
	new_character.mind.special_role = antag_flag

/datum/dynamic_ruleset/midround/from_ghosts/proc/setup_role(datum/antagonist/new_role)
	return

/// Кандидатов не нашлось. Повторную попытку теперь ведёт SSdirector на своих битах,
/// поэтому здесь ничего форсить не нужно.
/datum/dynamic_ruleset/midround/from_ghosts/proc/attempt_replacement()
	return

//////////////////////////////////////////////
//                                          //
//           INTEQ TRAITORS                 //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/autotraitor
	name = "InteQ Sleeper Agent"
	antag_datum = /datum/antagonist/traitor
	antag_flag = "traitor mid"
	antag_flag_override = ROLE_TRAITOR
	protected_roles = list("Expeditor", "Prisoner", "NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")  //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	required_candidates = 1
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT) // BLUEMOON ADD
	weight = 6 // лёгкая базовая инжекция, но не единственная цель ANTAG-пула
	cost = 8  //BLUEMOON CHANGES
	intensity = 15
	family = "traitor"
	requirements = list(101,40,30,20,10,10,10,10,10,10)
	repeatable = TRUE

	// Дефицит антагов уже гейтится общим клапаном SSdirector (antag_load/antag_target), а шанс
	// задаётся весом действия. Старые отдельные счётчик current_players и prob(threat_level)
	// здесь дублировали клапан и делали can_fire() недетерминированным для панели/ролла копилки.

/datum/dynamic_ruleset/midround/autotraitor/trim_candidates()
	. = ..()
	for(var/mob/living/player in living_players)
		if(issilicon(player)) // Your assigned role doesn't change when you are turned into a silicon.
			living_players -= player
		else if(is_centcom_level(player.z))
			living_players -= player // We don't autotator people in CentCom
		else if(player.mind && (player.mind.special_role || player.mind.antag_datums?.len > 0))
			living_players -= player // We don't autotator people with roles already

/datum/dynamic_ruleset/midround/autotraitor/ready(forced = FALSE)
	if (required_candidates > living_players.len)
		ready_failure_reason = "подходящих членов экипажа [living_players.len] из [required_candidates] (преференс midround, роль, бан и возраст)"
		return FALSE
	. = ..()
	if(.)
		director_preflight_detail = "подходящих членов экипажа: [living_players.len], требуется: [required_candidates]"

/datum/dynamic_ruleset/midround/autotraitor/director_preflight()
	trim_candidates()
	. = ready()
	director_preflight_failure = . ? null : ready_failure_reason

/datum/dynamic_ruleset/midround/autotraitor/execute()
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(living_players.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	var/mob/M = pick_n_take(living_players)
	assigned += M.mind // mind, не моб: по assigned директор считает вклад в intensity
	var/datum/antagonist/traitor/newTraitor = new
	M.mind.add_antag_datum(newTraitor)
	message_admins("[ADMIN_LOOKUPFLW(M)] was selected by the [name] ruleset and has been made into a midround traitor.")
	log_game("DYNAMIC: [key_name(M)] was selected by the [name] ruleset and has been made into a midround traitor.")
	return TRUE

//////////////////////////////////////////////
//                                          //
//                 FAMILIES                 //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/families
	name = "Family Head Aspirants"
	persistent = TRUE
	antag_datum = /datum/antagonist/gang
	antag_flag = ROLE_FAMILY_HEAD_ASPIRANT
	antag_flag_override = ROLE_FAMILIES
	force_antag_preference = TRUE
	restricted_roles = list("AI", "Cyborg", "Prisoner", "NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")  //BLUEMOON CHANGES
	required_candidates = 9
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT) // BLUEMOON ADD
	weight = 24 //BLUEMOON CHANGES
	cost = 10 //BLUEMOON CHANGES - низкая цена, т.к. надо в соло поднять семью
	intensity = 15
	requirements = list(101,101,101,50,30,20,10,10,10,10)
	flags = HIGH_IMPACT_RULESET
	blocking_rules = list(/datum/dynamic_ruleset/roundstart/families)
	/// A reference to the handler that is used to run pre_execute(), execute(), etc..
	var/datum/gang_handler/handler

/datum/dynamic_ruleset/midround/families/trim_candidates()
	. = ..()
	candidates = living_players
	for(var/mob/living/player in candidates)
		if(issilicon(player))
			candidates -= player
		else if(is_centcom_level(player.z))
			candidates -= player
		else if(player.mind && (player.mind.special_role || player.mind.antag_datums?.len > 0))
			candidates -= player
		else if(HAS_TRAIT(player, TRAIT_MINDSHIELD))
			candidates -= player


/datum/dynamic_ruleset/midround/families/ready(forced = FALSE)
	if (required_candidates > candidates.len)
		ready_failure_reason = "подходящих членов экипажа [candidates.len] из [required_candidates] для семей"
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/families/director_preflight()
	return director_preflight_candidates()

/datum/dynamic_ruleset/midround/families/pre_execute()
	..()
	handler = new /datum/gang_handler(candidates,restricted_roles)
	handler.gang_balance_cap = clamp((indice_pop - 3), 2, 5) // gang_balance_cap by indice_pop: (2,2,2,2,2,3,4,5,5,5)
	handler.midround_ruleset = TRUE
	handler.use_dynamic_timing = TRUE
	return handler.pre_setup_analogue()

/datum/dynamic_ruleset/midround/families/execute()
	return handler.post_setup_analogue(TRUE)

/datum/dynamic_ruleset/midround/families/clean_up()
	QDEL_NULL(handler)
	..()

/datum/dynamic_ruleset/midround/families/rule_process()
	return handler.process_analogue()

/datum/dynamic_ruleset/midround/families/round_result()
	return handler.set_round_result_analogue()

//////////////////////////////////////////////
//                                          //
//              WIZARD (CREW)               //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/wizard
	name = "Wizard"
	// persistent: rule_process() снимает Summon Events (wizardmode), когда волшебник погиб.
	// Без него wizardmode залипал на весь раунд, глуша обычные события директора навсегда.
	persistent = TRUE
	antag_datum = /datum/antagonist/wizard
	antag_flag = "wizard mid crew"
	antag_flag_override = ROLE_WIZARD
	protected_roles = list("Prisoner", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Chaplain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director")
	restricted_roles = list("AI", "Cyborg", "Positronic Brain")
	enemy_roles = list("Security Officer","Detective","Head of Security","Bridge Officer", "Captain")
	required_enemies = list(0,0,0,0,0,0,0,0,0,0)
	weight = 0
	cost = 20
	intensity = 45 // тяжёлый по cost, хотя вне ANTAG-пула директора (weight = 0, самоспавн из roundstart-визарда)
	antag_heavy = TRUE // для консистентности будущего использования, если weight когда-нибудь включат
	requirements = list(101,101,100,60,40,20,20,20,10,10)
	repeatable = TRUE
	var/datum/mind/wizard

/datum/dynamic_ruleset/midround/wizard/action_name()
	return "[name] (Crew)"

/datum/dynamic_ruleset/midround/wizard/trim_candidates()
	..()
	candidates = living_players
	for(var/mob/living/player as anything in candidates)
		var/turf/player_turf = get_turf(player)
		if(!player_turf || !is_station_level(player_turf.z))
			candidates -= player
			continue

		if(player.mind && (player.mind.special_role || length(player.mind.antag_datums) > 0))
			candidates -= player
	candidates = pollCandidates("Do you want to be a wizard?", antag_flag_override, be_special_flag = antag_flag_override, ignore_category = antag_flag_override, poll_time = 300)

/datum/dynamic_ruleset/midround/wizard/ready(forced = FALSE)
	if(GLOB.wizardstart.len == 0)
		log_admin("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		message_admins("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/wizard/execute()
	var/mob/M = pick_n_take(living_players)
	assigned += M.mind // mind, не моб: по assigned директор считает вклад в intensity
	var/datum/antagonist/wizard/on_station/wiz = new
	M.mind.add_antag_datum(wiz)
	wizard = M.mind
	message_admins("[ADMIN_LOOKUPFLW(M)] was selected by the [name] ruleset and has been made into a midround wizard.")
	log_game("DYNAMIC: [key_name(M)] was selected by the [name] ruleset and has been made into a midround wizard.")
	return TRUE

/datum/dynamic_ruleset/midround/wizard/rule_process()
	if(isliving(wizard.current) && wizard.current.stat!=DEAD)
		return FALSE
	for(var/obj/item/phylactery/P in GLOB.poi_list) //TODO : IsProperlyDead()
		if(P.mind && P.mind.has_antag_datum(/datum/antagonist/wizard))
			return FALSE

	if(SSdirector.wizardmode) //If summon events was active, turn it off
		SSdirector.toggle_wizardmode()

	return RULESET_STOP_PROCESSING

//////////////////////////////////////////////
//                                          //
//              WIZARD (GHOST)              //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/wizard
	name = "Wizard"
	// persistent: rule_process() снимает Summon Events (wizardmode), когда волшебник погиб.
	// Без него wizardmode залипал на весь раунд, глуша обычные события директора навсегда.
	persistent = TRUE
	antag_datum = /datum/antagonist/wizard
	antag_flag = "wizard mid"
	antag_flag_override = ROLE_WIZARD
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,0,0,0,0,0,0,0)
	required_candidates = 1
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	// Маг - единственный тяжёлый гост-рулсет без условий (1 гост + точки wizardstart есть везде),
	// поэтому раньше выпадал "около первым" и перебивал шанс другим гост-антагам. earliest_start
	// уводит его из первого получаса (лёгкие Devil/спавнеры играют раньше), вес снижен 4 -> 3,
	// чтобы среди поздних тяжёлых он не доминировал. Раунд-дефайнеры не открывают смену.
	earliest_start = 35 MINUTES
	weight = 3
	cost = 15 //BLUEMOON CHANGES
	intensity = 45
	antag_heavy = TRUE
	requirements = list(101,101,100,60,40,20,20,20,10,10)
	repeatable = FALSE
	var/datum/mind/wizard

/datum/dynamic_ruleset/midround/from_ghosts/wizard/action_name()
	return "[name] (Ghost)"

/datum/dynamic_ruleset/midround/from_ghosts/wizard/ready(forced = FALSE)
	if (required_candidates > (dead_players.len + list_observers.len))
		ready_failure_reason = "подходящих гостов [dead_players.len + list_observers.len] из [required_candidates]"
		return FALSE
	if(GLOB.wizardstart.len == 0)
		ready_failure_reason = "на карте нет точек спауна волшебника"
		if(!SSdirector.quiet_eval)
			log_admin("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
			message_admins("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/wizard/finish_setup(mob/new_character, index)
	..()
	new_character.forceMove(pick(GLOB.wizardstart))
	wizard = new_character.mind

/datum/dynamic_ruleset/midround/from_ghosts/wizard/rule_process()
	if(isliving(wizard.current) && wizard.current.stat!=DEAD)
		return FALSE
	for(var/obj/item/phylactery/P in GLOB.poi_list) //TODO : IsProperlyDead()
		if(P.mind && P.mind.has_antag_datum(/datum/antagonist/wizard))
			return FALSE

	if(SSdirector.wizardmode) //If summon events was active, turn it off
		SSdirector.toggle_wizardmode()

	return RULESET_STOP_PROCESSING

//////////////////////////////////////////////
//                                          //
//          NUCLEAR OPERATIVES (MIDROUND)   //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/nuclear
	name = "Nuclear Assault"
	antag_flag = "nukie mid"
	antag_datum = /datum/antagonist/nukeop
	antag_flag_override = ROLE_OPERATIVE
	enemy_roles = list("AI", "Cyborg", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,0,0,0,5,5,4,0) //BLUEMOON CHANGES
	required_candidates = 5
	weight = 2
	// Тяжёлый раунд-дефайнер не открывает смену: earliest_start уводит его из первого получаса
	// (как и мага). Дальше и так гейтится 5 гостами + cost 30.
	earliest_start = 35 MINUTES
	cost = 30 //BLUEMOON CHANGES
	antag_heavy = TRUE
	intensity = 45
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,101,101,60,40,30,10) //BLUEMOON CHANGES
	var/list/operative_cap = list(5,5,5,5,5,5,5,5,5,5)
	/// Минимум оперативников, с которого рейд уже стартует: полная команда из 5 гостов
	/// одновременно почти никогда не набиралась, и мидраунд-нюки не появлялись авто вовсе.
	/// Меньший отряд (3-5) - диверсионный удар вместо полной команды; poll всё равно берёт
	/// до operative_cap, сколько откликнулось.
	var/minimum_operatives = 3
	var/datum/team/nuclear/nuke_team
	flags = HIGH_IMPACT_RULESET

/datum/dynamic_ruleset/midround/from_ghosts/nuclear/acceptable(population=0, threat=0)
	if (locate(/datum/dynamic_ruleset/roundstart/nuclear) in mode.executed_rules)
		return FALSE // Unavailable if nuke ops were already sent at roundstart
	indice_pop = min(operative_cap.len, round(living_players.len/5)+1)
	required_candidates = operative_cap[indice_pop]
	// Цель - required_candidates (до 5), гейт опроса/готовности - минимум отряда.
	required_applicants = min(required_candidates, minimum_operatives)
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/nuclear/ready(forced = FALSE)
	if (required_applicants > (dead_players.len + list_observers.len))
		ready_failure_reason = "подходящих гостов [dead_players.len + list_observers.len] из [required_applicants]"
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/nuclear/finish_setup(mob/new_character, index)
	new_character.mind.special_role = "Nuclear Operative"
	new_character.mind.assigned_role = "Nuclear Operative"
	if (index == 1) // Our first guy is the leader
		var/datum/antagonist/nukeop/leader/new_role = new
		nuke_team = new_role.nuke_team
		new_character.mind.add_antag_datum(new_role)
	else
		return ..()

//////////////////////////////////////////////
//                                          //
//              Clock Cult (MID)            //
//                                          //
//////////////////////////////////////////////


//changes two people midround into clockwork cultists
/datum/dynamic_ruleset/midround/ratvar_awakening
	name = "Ratvar Awakening"
	antag_datum = /datum/antagonist/clockcult
	antag_flag = "clock mid"
	antag_flag_override = ROLE_SERVANT_OF_RATVAR
	protected_roles = list("NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Chaplain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("AI", "Cyborg", "Prisoner") //BLUEMOON CHANGES
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Chaplain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	required_enemies = list(1,1,1,1,1,1,0,0,0,0)
	required_candidates = 2
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	weight = 3
	cost = 20
	antag_heavy = TRUE
	intensity = 45
	requirements = list(101,101,101,101,50,40,30,20,10,10)
	var/list/clock_cap = list(1,1,1,2,3,4,5,5,5,5)
	/// Минимум обращаемых, с которого культ уже стартует: культ - снежный ком, малый посев
	/// вербует остальных в игре. Полная цель clock_cap 5-6 подходящих на среднем онлайне почти
	/// не набиралась, и мидраунд-культ не появлялся вовсе. Гейт = min(цель, этот минимум).
	var/minimum_candidates = 3
	/// Сколько обращаемых культ пытается взять при достатке (цель clock_cap); execute берёт
	/// столько, сколько есть, но не меньше required_candidates и не больше цели.
	var/target_candidates = 0
	flags = HIGH_IMPACT_RULESET

/datum/dynamic_ruleset/midround/ratvar_awakening/acceptable(population=0, threat=0)
	if (locate(/datum/dynamic_ruleset/roundstart/clockcult) in mode.executed_rules)
		return FALSE // Unavailable if clockies exist at round start
	indice_pop = min(clock_cap.len, round(population/5)+1)
	target_candidates = clock_cap[indice_pop]
	required_candidates = min(target_candidates, minimum_candidates)
	return ..()

/datum/dynamic_ruleset/midround/ratvar_awakening/director_preflight()
	return director_preflight_candidates()

/datum/dynamic_ruleset/midround/ratvar_awakening/ready(forced = FALSE)
	if(length(candidates) < required_candidates)
		ready_failure_reason = "подходящих членов экипажа [length(candidates)] из [required_candidates] для культа Ратвара"
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/ratvar_awakening/trim_candidates()
	..()
	candidates = living_players
	for(var/mob/living/player as anything in candidates)
		var/turf/player_turf = get_turf(player)
		if(!player_turf || !is_station_level(player_turf.z))
			candidates -= player //no ghost roles
			continue

		if(!is_eligible_servant(player))
			candidates -= player
			continue

		if(player.mind && (player.mind.special_role || length(player.mind.antag_datums) > 0))
			candidates -= player //no double dipping

/datum/dynamic_ruleset/midround/ratvar_awakening/execute()
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	// Цель - target_candidates (полный clock_cap), но берём сколько есть сверх минимума.
	var/to_convert = max(target_candidates, required_candidates)
	for(var/i = 0; i < to_convert; i++)
		if(!candidates.len)
			break
		var/mob/living/clock_antag = pick_n_take(candidates)
		assigned += clock_antag.mind
	for(var/datum/mind/M in assigned) //add them to the clockwork team
		add_servant_of_ratvar(M.current)
		SSticker.mode.equip_servant(M.current)
		SSticker.mode.greet_servant(M.current)
		message_admins("[ADMIN_LOOKUPFLW(M.current)] was selected by the [name] ruleset and has been made into a midround clock cultist.")
		log_game("DYNAMIC: [key_name(M.current)] was selected by the [name] ruleset and has been made into a midround clock cultist.")
	load_reebe()
	return ..()

//////////////////////////////////////////////
//                                          //
//              Blood Cult (MID)            //
//                                          //
//////////////////////////////////////////////


//changes six people midround into blood cultists
/datum/dynamic_ruleset/midround/narsie_awakening
	name = "Nar'Sie Awakening"
	antag_datum = /datum/antagonist/cult
	antag_flag = "narsie mid"
	antag_flag_override = ROLE_CULTIST
	protected_roles = list("NanoTrasen Representative", "Internal Affairs Agent", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Chaplain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	restricted_roles = list("AI", "Cyborg", "Prisoner") //BLUEMOON CHANGES
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Chaplain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director") //BLUEMOON CHANGES
	required_enemies = list(1,1,1,1,1,1,0,0,0,0)
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	required_candidates = 6
	weight = 3
	cost = 20
	antag_heavy = TRUE
	intensity = 45
	requirements = list(101,101,101,101,50,40,30,20,10,10)
	var/list/blood_cap = list(1,1,2,3,4,5,6,6,6,6)
	/// Минимум обращаемых, с которого культ уже стартует (см. Ratvar Awakening): кровавый культ
	/// снежным комом вербует остальных, полная цель blood_cap 6 почти не набиралась на среднем онлайне.
	var/minimum_candidates = 3
	/// Цель обращения (полный blood_cap); execute берёт сколько есть сверх минимума.
	var/target_candidates = 0
	var/datum/team/cult/main_cult
	flags = HIGH_IMPACT_RULESET

/datum/dynamic_ruleset/midround/narsie_awakening/acceptable(population=0, threat=0)
	if (locate(/datum/dynamic_ruleset/roundstart/bloodcult) in mode.executed_rules)
		return FALSE
	indice_pop = min(blood_cap.len, round(population/5)+1)
	target_candidates = blood_cap[indice_pop]
	required_candidates = min(target_candidates, minimum_candidates)
	return ..()

/datum/dynamic_ruleset/midround/narsie_awakening/director_preflight()
	return director_preflight_candidates()

/datum/dynamic_ruleset/midround/narsie_awakening/ready(forced = FALSE)
	if(length(candidates) < required_candidates)
		ready_failure_reason = "подходящих членов экипажа [length(candidates)] из [required_candidates] для культа Нар'Си"
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/narsie_awakening/trim_candidates()
	..()
	candidates = living_players
	for(var/mob/living/player as anything in candidates)
		var/turf/player_turf = get_turf(player)
		if(!player_turf || !is_station_level(player_turf.z))
			candidates -= player //no ghost roles
			continue

		if(!is_eligible_servant(player))
			candidates -= player
			continue

		if(player.mind && (player.mind.special_role || length(player.mind.antag_datums) > 0))
			candidates -= player //no double dipping

/datum/dynamic_ruleset/midround/narsie_awakening/execute()
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	// Цель - target_candidates (полный blood_cap), но берём сколько есть сверх минимума.
	var/to_convert = max(target_candidates, required_candidates)
	for(var/i = 0; i < to_convert; i++)
		if(!candidates.len)
			break
		var/mob/living/blood_antag = pick_n_take(candidates)
		assigned += blood_antag.mind
	main_cult = new
	for(var/datum/mind/M in assigned) //add them to the clockwork team
		var/datum/antagonist/cult/new_cultist = new antag_datum()
		new_cultist.cult_team = main_cult
		new_cultist.give_equipment = TRUE
		M.add_antag_datum(new_cultist)
		message_admins("[ADMIN_LOOKUPFLW(M.current)] was selected by the [name] ruleset and has been made into a midround blood cultist.")
		log_game("DYNAMIC: [key_name(M.current)] was selected by the [name] ruleset and has been made into a midround blood cultist.")
	main_cult.setup_objectives()
	return ..()

//////////////////////////////////////////////
//                                          //
//              BLOB (GHOST)                //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/blob
	name = "Blob"
	// Прямое событие Blob уже зарегистрировано в GHOST-пуле директора и умеет проверять/трекать
	// реального госта. Двойник остаётся для ручного форса, но не удваивает шанс одного контента.
	admin_only = TRUE
	antag_datum = /datum/antagonist/blob
	antag_flag = ROLE_BLOB
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,0,0,0,0,0,0,0)
	required_candidates = 1
	weight = 3 //BLUEMOON CHANGES
	cost = 10
	intensity = 15
	family = "blob" // с событием-двойником и заражением: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,50,40,30,20,10,10)
	repeatable = TRUE

/datum/dynamic_ruleset/midround/from_ghosts/blob/generate_ruleset_body(mob/applicant)
	var/body = applicant.become_overmind()
	return body

// name совпадает с /datum/round_event_control/blob ("Blob") - без суффикса рулсет и событие
// делили бы ключ конфига/intensity_ledger.
/datum/dynamic_ruleset/midround/from_ghosts/blob/action_name()
	return "[name] (Ruleset)"

/// Infects a random player, making them explode into a blob.
/datum/dynamic_ruleset/midround/blob_infection
	name = "Blob Infection"
	// Живого члена экипажа больше не превращаем в блоба естественным выбором директора.
	// Рулсет остаётся доступен для осознанного ручного запуска; естественный Blob приходит гостом.
	admin_only = TRUE
	antag_datum = /datum/antagonist/blob
	antag_flag = "blob mid"
	antag_flag_override = ROLE_BLOB
	protected_roles = list("Prisoner", "Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,0,0,0,0,0,0,0)
	required_candidates = 1
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	weight = 2
	cost = 10
	intensity = 15
	family = "blob" // с событием-двойником и гост-блобом: не подряд
	requirements = list(101,101,101,101,50,40,30,20,10,10)
	// Второе заражение в том же раунде вытесняло почти весь неблобовый ANTAG-пул. Одного
	// заражения достаточно; отдельное позднее ghost-событие Blob остаётся самостоятельной угрозой.
	repeatable = FALSE

/datum/dynamic_ruleset/midround/blob_infection/trim_candidates()
	..()
	candidates = living_players
	for(var/mob/living/player as anything in candidates)
		var/turf/player_turf = get_turf(player)
		if(!player_turf || !is_station_level(player_turf.z))
			candidates -= player
			continue

		if(player.mind && (player.mind.special_role || length(player.mind.antag_datums) > 0))
			candidates -= player

/datum/dynamic_ruleset/midround/blob_infection/director_preflight()
	return director_preflight_candidates()

/datum/dynamic_ruleset/midround/blob_infection/ready(forced = FALSE)
	if(length(candidates) < required_candidates)
		ready_failure_reason = "подходящих членов экипажа [length(candidates)] из [required_candidates] для заражения блобом"
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/blob_infection/execute()
	// BLUEMOON ADD START - если нет кандидатов и не выданы все роли, иначе выдаст рантайм
	if(candidates.len <= 0)
		message_admins("Рулсет [name] не был активирован по причине отсутствия кандидатов.")
		return FALSE
	// BLUEMOON ADD END
	var/mob/living/carbon/human/blob_antag = pick_n_take(candidates)
	assigned += blob_antag.mind
	blob_antag.mind.special_role = antag_flag_override
	return ..()

//////////////////////////////////////////////
//                                          //
//           XENOMORPH (GHOST)              //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph
	name = "Alien Infestation"
	admin_only = TRUE
	antag_datum = /datum/antagonist/xeno
	antag_flag = ROLE_ALIEN
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,0,6,6,5,5,4,0) //BLUEMOON CHANGES
	required_candidates = 1
	weight = 5
	cost = 15
	antag_heavy = TRUE
	intensity = 45
	family = "xenomorph" // с событием-двойником: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,50,40,30,20,10,10)
	repeatable = TRUE
	var/list/vents = list()

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/ready(forced = FALSE)
	if(!..())
		return FALSE
	if(!length(find_vent_spawns()))
		ready_failure_reason = "не найдено доступных вентиляций для спауна"
		return FALSE
	return TRUE

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/execute()
	required_candidates += prob(50)
	required_candidates += prob(50)
	required_candidates += prob(50)
	vents = find_vent_spawns()
	if(!length(vents))
		return FALSE
	. = ..()
	if(.)
		addtimer(CALLBACK(src, PROC_REF(announce_xenos)), rand(375, 600) SECONDS)

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/proc/announce_xenos()
	priority_announce("Неизвестные признаки жизни обнаружены на борту [station_name()]. Заблокируйте любой внешний доступ, включая воздуховоды и вентиляцию.", "ВНИМАНИЕ: НЕОПОЗНАННЫЕ ФОРМЫ ЖИЗНИ", ANNOUNCER_ALIENS)

// name совпадает с /datum/round_event_control/alien_infestation ("Alien Infestation") - без суффикса
// рулсет и событие делили бы ключ конфига/intensity_ledger.
/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/action_name()
	return "[name] (Ruleset)"

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/generate_ruleset_body(mob/applicant)
	var/obj/vent = length(vents) >= 2 ? pick_n_take(vents) : vents[1]
	var/mob/living/carbon/alien/larva/new_xeno = new(vent.loc)
	new_xeno.key = applicant.key
	message_admins("[ADMIN_LOOKUPFLW(new_xeno)] has been made into an alien by the midround ruleset.")
	log_game("DYNAMIC: [key_name(new_xeno)] was spawned as an alien by the midround ruleset.")
	return new_xeno

//////////////////////////////////////////////
//                                          //
//           TERROR SPIDERS (GHOST)              //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/terror_spiders
	name = "Terror Infestation"
	admin_only = TRUE
	antag_datum = /datum/antagonist/terror_spiders
	antag_flag = ROLE_TERROR_SPIDER
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,0,0,0,0,0,0,0)
	required_candidates = 1
	weight = 3
	cost = 20
	antag_heavy = TRUE
	intensity = 45
	family = "terror_spiders" // с событием-двойником: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD) // BLUEMOON ADD
	requirements = list(101,101,101,101,50,40,30,20,10,10)
	flags = HIGH_IMPACT_RULESET
	var/list/vents = list()
	var/spider_type = list()
	var/spider_types = list(4,3,2,1)

/datum/dynamic_ruleset/midround/from_ghosts/terror_spiders/execute()
	spider_type = rand(1,4)
	required_candidates = spider_types[spider_type]
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in GLOB.machines)
		if(QDELETED(temp_vent))
			continue
		if(is_station_level(temp_vent.loc.z) && !temp_vent.welded)
			var/datum/pipeline/temp_vent_parent = temp_vent.parents[1]
			if(!temp_vent_parent)
				continue // No parent vent
			// Stops Aliens getting stuck in small networks.
			// See: Security, Virology
			if(temp_vent_parent.other_atmosmch.len > 20)
				vents += temp_vent
	if(!vents.len)
		return FALSE
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/terror_spiders/generate_ruleset_body(mob/applicant)
	var/obj/vent = pick_n_take(vents)
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/new_spider
	if (spider_type == 1)
		new_spider = new /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/defiler(vent.loc)
	else if (spider_type == 2)
		new_spider = new /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/princess(vent.loc)
	else if (spider_type == 3)
		new_spider = new /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen(vent.loc)
	else if (spider_type == 4)
		new_spider = new /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/prince(vent.loc)
	new_spider.key = applicant.key
	message_admins("[ADMIN_LOOKUPFLW(new_spider)] has been made into an alien by the midround ruleset.")
	log_game("DYNAMIC: [key_name(new_spider)] was spawned as an alien by the midround ruleset.")
	return new_spider

//////////////////////////////////////////////
//                                          //
//           NIGHTMARE (GHOST)              //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/nightmare
	name = "Nightmare"
	admin_only = TRUE
	antag_datum = /datum/antagonist/nightmare
	antag_flag = "Nightmare"
	antag_flag_override = ROLE_ALIEN
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,4,4,3,3,2,0,0) //BLUEMOON CHANGES
	required_candidates = 1
	weight = 6 //BLUEMOON CHANGES
	cost = 10
	intensity = 15
	family = "nightmare" // с событием-двойником: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,50,30,25,20,10,10,10) //BLUEMOON CHANGES
	repeatable = TRUE
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/nightmare/execute()
	for(var/X in GLOB.xeno_spawn)
		var/turf/T = X
		var/light_amount = T.get_lumcount()
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			spawn_locs += T
	if(!spawn_locs.len)
		return FALSE
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/nightmare/generate_ruleset_body(mob/applicant)
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE

	var/mob/living/carbon/human/S = new (pick(spawn_locs))
	player_mind.transfer_to(S)
	player_mind.assigned_role = "Nightmare"
	player_mind.special_role = "Nightmare"
	player_mind.add_antag_datum(/datum/antagonist/nightmare)
	S.set_species(/datum/species/shadow/nightmare)

	playsound(S, 'sound/magic/ethereal_exit.ogg', 50, TRUE, -1)
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a Nightmare by the midround ruleset.")
	log_game("DYNAMIC: [key_name(S)] was spawned as a Nightmare by the midround ruleset.")
	return S

//////////////////////////////////////////////
//                                          //
//           SPACE DRAGON (GHOST)           //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/space_dragon
	name = "Space Dragon"
	admin_only = TRUE
	antag_datum = /datum/antagonist/space_dragon
	antag_flag = ROLE_SPACE_DRAGON
	antag_flag_override = ROLE_SPACE_DRAGON
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGE (should we include miners?)
	required_enemies = list(0,0,0,0,5,5,4,4,3,0) //BLUEMOON CHANGES
	required_candidates = 1
	weight = 6 //BLUEMOON CHANGES
	cost = 10
	intensity = 15
	family = "space_dragon" // с событием-двойником: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,50,40,30,20,10,10)
	repeatable = TRUE
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/space_dragon/execute()
	for(var/obj/effect/landmark/carpspawn/C in GLOB.landmarks_list)
		spawn_locs += (C.loc)
	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/space_dragon/generate_ruleset_body(mob/applicant)
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE

	var/mob/living/simple_animal/hostile/space_dragon/S = new (pick(spawn_locs))
	player_mind.transfer_to(S)
	player_mind.assigned_role = "Space Dragon"
	player_mind.special_role = ROLE_SPACE_DRAGON
	player_mind.add_antag_datum(/datum/antagonist/space_dragon)

	playsound(S, 'sound/magic/ethereal_exit.ogg', 50, TRUE, -1)
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a Space Dragon by the midround ruleset.")
	log_game("DYNAMIC: [key_name(S)] was spawned as a Space Dragon by the midround ruleset.")
	priority_announce("Большой поток органической энергии был зафиксирован вблизи [station_name()]. Пожалуйста, ожидайте.", "ВНИМАНИЕ: ОРГАНИКА")
	return S

//////////////////////////////////////////////
//                                          //
//              MORPH (GHOST)               //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/morph
	name = "Morph"
	// Каноническое естественное действие директора - /round_event_control/morph (Spawn Morph).
	// Рулсет остаётся для ручного запуска, но не дублирует тот же контент в GHOST-пуле.
	admin_only = TRUE
	antag_datum = /datum/antagonist/morph
	antag_flag = "Morph"
	antag_flag_override = ROLE_ALIEN
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security", "Bridge Officer", "Captain")
	required_enemies = list(0,0,0,0,0,5,4,3,3,0)
	required_candidates = 1
	weight = 8
	cost = 10
	intensity = 15
	family = "morph" // с событием-двойником: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED)
	requirements = list(101,101,101,50,30,25,20,10,10,10)
	repeatable = FALSE

/datum/dynamic_ruleset/midround/from_ghosts/morph/execute()
	if(!GLOB.xeno_spawn || !GLOB.xeno_spawn.len)
		execution_failure_reason = "на карте нет точек xeno_spawn для морфа"
		return FALSE
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/morph/ready(forced = FALSE)
	if(!GLOB.xeno_spawn || !GLOB.xeno_spawn.len)
		ready_failure_reason = "на карте нет точек xeno_spawn для морфа"
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/morph/generate_ruleset_body(mob/applicant)
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE

	var/mob/living/simple_animal/hostile/morph/S = new /mob/living/simple_animal/hostile/morph(pick(GLOB.xeno_spawn))
	player_mind.transfer_to(S)
	player_mind.assigned_role = "Morph"
	to_chat(S, S.playstyle_string)
	SEND_SOUND(S, sound('sound/magic/mutate.ogg'))
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a morph by the midround ruleset.")
	log_game("DYNAMIC: [key_name(S)] was spawned as a morph by the midround ruleset.")
	return S

//////////////////////////////////////////////
//                                          //
//              DEVIL (GHOST)               //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/devil
	name = "Devil"
	antag_datum = /datum/antagonist/devil
	antag_flag = ROLE_DEVIL
	antag_flag_override = ROLE_DEVIL
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security", "Bridge Officer", "Captain")
	required_enemies = list(0,0,0,0,0,5,4,3,3,0)
	required_candidates = 1
	weight = 6
	cost = 10
	intensity = 15
	family = "devil" // с событием-двойником: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM)
	requirements = list(101,101,101,50,40,30,20,10,10,10)
	repeatable = FALSE

/datum/dynamic_ruleset/midround/from_ghosts/devil/finish_setup(mob/new_character, index)
	add_devil(new_character, ascendable = TRUE)
	mode.add_devil_objectives(new_character.mind, 2)
	new_character.mind.special_role = ROLE_DEVIL
	new_character.mind.assigned_role = ROLE_DEVIL
	// Equip as Assistant so the devil has clothes (makeBody creates a naked human)
	if(ishuman(new_character))
		var/datum/job/assistant = SSjob.GetJob("Assistant")
		if(assistant)
			new_character.job = assistant.title
			assistant.equip(new_character, announce = FALSE)
	message_admins("[ADMIN_LOOKUPFLW(new_character)] has been made into a Devil by the midround ruleset.")
	log_game("DYNAMIC: [key_name(new_character)] was spawned as a Devil by the midround ruleset.")

//////////////////////////////////////////////
//                                          //
//           ABDUCTORS    (GHOST)           //
//                                          //
//////////////////////////////////////////////
#define ABDUCTOR_MAX_TEAMS 4

/datum/dynamic_ruleset/midround/from_ghosts/abductors
	name = "Abductors"
	admin_only = TRUE
	antag_flag = "Abductor"
	antag_flag_override = ROLE_ABDUCTOR
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,0,0,5,5,4,4,0) //BLUEMOON CHANGES
	required_candidates = 2
	required_applicants = 2
	weight = 3
	cost = 10
	intensity = 15
	family = "abductors" // с событием-двойником: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,101,101,30,20,15,10,10)
	repeatable = TRUE
	var/datum/team/abductor_team/new_team

/datum/dynamic_ruleset/midround/from_ghosts/abductors/ready(forced = FALSE)
	if (required_candidates > (dead_players.len + list_observers.len))
		ready_failure_reason = "подходящих гостов [dead_players.len + list_observers.len] из [required_candidates]"
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/abductors/finish_setup(mob/new_character, index)
	if (index == 1) // Our first guy is the scientist.  We also initialize the team here as well since this should only happen once per pair of abductors.
		new_team = new
		if(new_team.team_number > ABDUCTOR_MAX_TEAMS)
			return MAP_ERROR
		var/datum/antagonist/abductor/scientist/new_role = new
		new_character.mind.add_antag_datum(new_role, new_team)
	else // Our second guy is the agent, team is already created, don't need to make another one.
		var/datum/antagonist/abductor/agent/new_role = new
		new_character.mind.add_antag_datum(new_role, new_team)

// name совпадает с /datum/round_event_control/abductor ("Abductors") - без суффикса рулсет
// и событие делили бы ключ конфига/intensity_ledger.
/datum/dynamic_ruleset/midround/from_ghosts/abductors/action_name()
	return "[name] (Ruleset)"

#undef ABDUCTOR_MAX_TEAMS

//////////////////////////////////////////////
//                                          //
//            SWARMERS    (GHOST)           //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/swarmers
	name = "Swarmers"
	// Spawn Swarmer Shell уже является самостоятельным действием директора. Этот legacy-дубль
	// сохраняется для ручного запуска, но не удваивает шанс свормеров в естественном GHOST-пуле.
	admin_only = TRUE
	severity = DIRECTOR_SEVERITY_GHOST // спавнер для призраков, экипаж не тратится
	antag_flag = "Swarmer"
	antag_flag_override = ROLE_ALIEN
	required_type = /mob/dead/observer
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,0,6,6,5,5,4,0) //BLUEMOON CHANGES
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	required_candidates = 0
	weight = 2 //BLUEMOON CHANGES
	cost = 10
	intensity = 15
	family = "swarmers" // с событием-двойником: не подряд
	requirements = list(101,101,101,101,50,40,30,20,10,10)
	repeatable = TRUE

/datum/dynamic_ruleset/midround/swarmers/execute()
	var/list/spawn_locs = list()
	for(var/x in GLOB.xeno_spawn)
		var/turf/spawn_turf = x
		var/light_amount = spawn_turf.get_lumcount()
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			spawn_locs += spawn_turf
	if(!spawn_locs.len)
		message_admins("No valid spawn locations found in GLOB.xeno_spawn, aborting swarmer spawning...")
		return MAP_ERROR
	var/obj/effect/mob_spawn/swarmer/spawner = new(get_turf(GLOB.the_gateway))
	spawner.director_source_action = src
	spawner.director_refund_cost = director_pending_cost
	log_game("A Swarmer was spawned via Dynamic Mode.")
	return ..()

/datum/dynamic_ruleset/midround/swarmers/director_execution_detail(assigned_this_attempt)
	return "исполнение подтверждено; создан спавнер роли, назначение ожидает активации"

//////////////////////////////////////////////
//                                          //
//            SPACE NINJA (GHOST)           //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/space_ninja
	name = "Space Ninja"
	admin_only = TRUE
	antag_datum = /datum/antagonist/ninja
	antag_flag = "Space Ninja"
	antag_flag_override = ROLE_NINJA
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,0,5,5,4,4,3,0) //BLUEMOON CHANGES
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	required_candidates = 1
	weight = 6 //BLUEMOON CHANGES
	cost = 10
	intensity = 15
	requirements = list(101,101,101,101,60,50,30,20,10,10) //BLUEMOON CHANGES
	repeatable = TRUE
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/space_ninja/execute()
	for(var/obj/effect/landmark/carpspawn/carp_spawn in GLOB.landmarks_list)
		if(!isturf(carp_spawn.loc))
			stack_trace("Carp spawn found not on a turf: [carp_spawn.type] on [isnull(carp_spawn.loc) ? "null" : carp_spawn.loc.type]")
			continue
		spawn_locs += carp_spawn.loc
	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/space_ninja/generate_ruleset_body(mob/applicant)
	var/mob/living/carbon/human/ninja = create_space_ninja(pick(spawn_locs))
	ninja.key = applicant.key
	ninja.mind.add_antag_datum(/datum/antagonist/ninja)

	message_admins("[ADMIN_LOOKUPFLW(ninja)] has been made into a Space Ninja by the midround ruleset.")
	log_game("DYNAMIC: [key_name(ninja)] was spawned as a Space Ninja by the midround ruleset.")
	return ninja

//////////////////////////////////////////////
//                                          //
//            Revenant     (GHOST)          //
//                                          //
//////////////////////////////////////////////

/// Revenant ruleset
/datum/dynamic_ruleset/midround/from_ghosts/revenant
	name = "Revenant"
	admin_only = TRUE
	antag_datum = /datum/antagonist/revenant
	antag_flag = "Revenant"
	antag_flag_override = ROLE_REVENANT
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain", "Chaplain") //BLUEMOON CHANGES
	required_enemies = list(0,0,0,5,5,4,4,3,3,0) //BLUEMOON CHANGES
	required_candidates = 1
	weight = 3 //BLUEMOON CHANGES
	cost = 10
	intensity = 15
	family = "revenant" // с событием-двойником: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // not extended
	requirements = list(101,101,101,50,30,25,20,10,10,10) //BLUEMOON CHANGES
	repeatable = TRUE
	var/dead_mobs_required = 10
	var/need_extra_spawns_value = 15
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/revenant/acceptable(population=0, threat=0)
	if(GLOB.dead_mob_list.len < dead_mobs_required)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/revenant/execute()
	for(var/mob/living/corpse in GLOB.dead_mob_list) //look for any dead bodies
		var/turf/corpse_turf = get_turf(corpse)
		if(corpse_turf && is_station_level(corpse_turf.z))
			spawn_locs += corpse_turf
	if(!spawn_locs.len || spawn_locs.len < need_extra_spawns_value) //look for any morgue trays, crematoriums, ect if there weren't alot of dead bodies on the station to pick from
		for(var/obj/structure/bodycontainer/corpse_container in GLOB.bodycontainers)
			var/turf/container_turf = get_turf(corpse_container)
			if(container_turf && is_station_level(container_turf.z))
				spawn_locs += container_turf
	if(!spawn_locs.len) //If we can't find any valid spawnpoints, try the carp spawns
		for(var/obj/effect/landmark/carpspawn/carp_spawnpoint in GLOB.landmarks_list)
			if(isturf(carp_spawnpoint.loc))
				spawn_locs += carp_spawnpoint.loc
	if(!spawn_locs.len) //If we can't find THAT, then just give up and cry
		return FALSE
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/revenant/generate_ruleset_body(mob/applicant)
	var/mob/living/simple_animal/revenant/revenant = new(pick(spawn_locs))
	revenant.key = applicant.key
	message_admins("[ADMIN_LOOKUPFLW(revenant)] has been made into a revenant by the midround ruleset.")
	log_game("[key_name(revenant)] was spawned as a revenant by the midround ruleset.")
	return revenant

/// Sentient Disease ruleset
/datum/dynamic_ruleset/midround/from_ghosts/sentient_disease
	name = "Sentient Disease"
	admin_only = TRUE
	antag_datum = /datum/antagonist/disease
	antag_flag = "Sentient Disease"
	antag_flag_override = ROLE_ALIEN
	required_candidates = 1
	weight = 6 //BLUEMOON CHANGES
	cost = 10
	intensity = 15
	family = "sentient_disease" // с событием-двойником: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	requirements = list(101,101,101,50,30,25,20,10,10,10) //BLUEMOON CHANGES
	repeatable = TRUE

/datum/dynamic_ruleset/midround/from_ghosts/sentient_disease/generate_ruleset_body(mob/applicant)
	var/mob/camera/disease/virus = new /mob/camera/disease(SSmapping.get_station_center())
	virus.key = applicant.key
	INVOKE_ASYNC(virus, TYPE_PROC_REF(/mob/camera/disease, pick_name))
	message_admins("[ADMIN_LOOKUPFLW(virus)] has been made into a sentient disease by the midround ruleset.")
	log_game("[key_name(virus)] was spawned as a sentient disease by the midround ruleset.")
	return virus

/// Space Pirates ruleset
/datum/dynamic_ruleset/midround/pirates
	name = "Space Pirates"
	// Реальное событие уже зарегистрировано у директора; рулсет-дубль нужен только для админ-форса.
	admin_only = TRUE
	severity = DIRECTOR_SEVERITY_GHOST // событие поллит призраков, экипаж не тратится
	antag_flag = "Space Pirates"
	required_type = /mob/dead/observer
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGE
	required_enemies = list(0,0,0,0,0,5,4,3,3,3) //BLUEMOON CHANGES
	required_candidates = 0
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	weight = 6 //BLUEMOON CHANGES
	cost = 10
	intensity = 15
	family = "pirates" // с событием-двойником (execute() запускает его же): не подряд
	requirements = list(101,101,101,101,101,40,30,20,10,10) //BLUEMOON CHANGES
	repeatable = TRUE

/datum/dynamic_ruleset/midround/pirates/acceptable(population=0, threat=0)
	if(!SSmapping.empty_space && !length(SSmapping.levels_by_trait(ZTRAIT_SPACE_RUINS)) && !SSmapping.station_start)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/pirates/execute()
	var/datum/round_event_control/event = locate(/datum/round_event_control/pirates) in SSdirector.event_controls()
	if(event)
		event.execute_action()
	return ..()

// name совпадает с /datum/round_event_control/pirates ("Space Pirates"), который этот рулсет сам
// же и запускает через execute() - без суффикса они делили бы ключ конфига/intensity_ledger.
/datum/dynamic_ruleset/midround/pirates/action_name()
	return "[name] (Ruleset)"

//////////////////////////////////////////////
//                                          //
//            InteQ Raiders                 //
//                                          //
//////////////////////////////////////////////
/datum/dynamic_ruleset/midround/raiders
	name = "InteQ Raiders"
	// Реальное событие уже зарегистрировано у директора; рулсет-дубль нужен только для админ-форса.
	admin_only = TRUE
	severity = DIRECTOR_SEVERITY_GHOST // событие поллит призраков, экипаж не тратится
	antag_flag = "InteQ Raiders"
	required_type = /mob/dead/observer
	enemy_roles = list("Security Officer", "Detective", "Head of Security","Bridge Officer", "Captain")
	required_enemies = list(0,0,0,0,0,0,0,0,0,0)
	required_candidates = 0
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_TEAMBASED) // BLUEMOON ADD
	weight = 4
	cost = 15
	antag_heavy = TRUE
	intensity = 45
	family = "raiders" // с событием-двойником (execute() запускает его же): не подряд
	requirements = list(101,101,101,40,30,20,10,10,10,10)
	repeatable = FALSE

/datum/dynamic_ruleset/midround/raiders/acceptable(population=0, threat=0)
	if(!SSmapping.empty_space && !length(SSmapping.levels_by_trait(ZTRAIT_SPACE_RUINS)) && !SSmapping.station_start)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/raiders/execute()
	var/datum/round_event_control/event = locate(/datum/round_event_control/raiders) in SSdirector.event_controls()
	if(event && event.occurrences < event.max_occurrences)
		event.execute_action()
	return TRUE

// name совпадает с /datum/round_event_control/raiders ("InteQ Raiders"), который этот рулсет сам
// же и запускает через execute() - без суффикса они делили бы ключ конфига/intensity_ledger.
/datum/dynamic_ruleset/midround/raiders/action_name()
	return "[name] (Ruleset)"

/datum/dynamic_ruleset/midround/raiders/director_execution_detail(assigned_this_attempt)
	return "исполнение подтверждено; роли назначит запущенное событие после ответа станции"

//////////////////////////////////////////////
//                                          //
//            Medieval Warmongers           //
//                                          //
//////////////////////////////////////////////
/datum/dynamic_ruleset/midround/warmongers
	name = "Medieval Warmongers"
	// Реальное событие уже зарегистрировано у директора; рулсет-дубль нужен только для админ-форса.
	admin_only = TRUE
	severity = DIRECTOR_SEVERITY_GHOST // событие поллит призраков, экипаж не тратится
	antag_flag = "Medieval Warmongers"
	required_type = /mob/dead/observer
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGE
	required_enemies = list(0,0,0,0,0,5,4,3,3,3) //BLUEMOON CHANGES
	required_candidates = 0
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // BLUEMOON ADD
	weight = 3 //BLUEMOON CHANGES
	cost = 5
	intensity = 10
	family = "warmongers" // с событием-двойником (execute() запускает его же): не подряд
	requirements = list(101,101,101,101,101,40,30,20,10,10) //BLUEMOON CHANGES
	repeatable = TRUE

/datum/dynamic_ruleset/midround/warmongers/acceptable(population=0, threat=0)
	if(!SSmapping.empty_space && !length(SSmapping.levels_by_trait(ZTRAIT_SPACE_RUINS)) && !SSmapping.station_start)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/warmongers/execute()
	var/datum/round_event_control/event = locate(/datum/round_event_control/medieval_warmongers) in SSdirector.event_controls()
	if(event)
		event.execute_action()
	return ..()

// name совпадает с /datum/round_event_control/medieval_warmongers ("Medieval Warmongers"), который
// этот рулсет сам же и запускает через execute() - без суффикса они делили бы ключ
// конфига/intensity_ledger.
/datum/dynamic_ruleset/midround/warmongers/action_name()
	return "[name] (Ruleset)"

/datum/dynamic_ruleset/midround/warmongers/director_execution_detail(assigned_this_attempt)
	return "исполнение подтверждено; роли назначит запущенное событие после ответа станции"

// BLUEMOON ADD START

//////////////////////////////////////////////
//                                          //
//            BLOODSUCKERS                  //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/bloodsuckers
	name = "Bloodsuckers"
	// Кровососы сломаны и ждут починки/упрощения: естественно не выдаются ни в одном типе раунда.
	// Прежний хак (только team-based) заменён честным выключателем - ручной форс админом работает.
	admin_only = TRUE
	antag_flag = "Bloodsucker Mid"
	antag_flag_override = ROLE_BLOODSUCKER
	antag_datum = /datum/antagonist/bloodsucker
	protected_roles = list("Prisoner", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain")
	restricted_roles = list("AI", "Cyborg", "Positronic Brain")
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGES
	required_enemies = list(3,3,3,3,3,3,3,3,3,3)
	required_candidates = 1
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED)
	weight = 6
	cost = 8
	intensity = 15
	family = "bloodsuckers"
	scaling_cost = 10
	requirements = list(101,101,60,50,40,30,20,15,10,10)
	antag_cap = list("denominator" = 39, "offset" = 1)

/datum/dynamic_ruleset/midround/bloodsuckers/trim_candidates()
	. = ..()
	candidates = living_players
	for(var/mob/living/player in candidates)
		if(issilicon(player)) // никаких боргов
			candidates -= player
		else if(is_centcom_level(player.z))  // никаких ЦКшников
			candidates -= player
		else if(player.mind && (player.mind.special_role || player.mind.antag_datums?.len > 0)) // никаких мульти-антагонистов
			candidates -= player
		else if(HAS_TRAIT(player, TRAIT_MINDSHIELD)) // никаких кровососов с защитой разума
			candidates -= player
		else if(player.mob_weight > MOB_WEIGHT_HEAVY) // никаких сверхтяжёлых кровососов
			candidates -= player
		else if(HAS_TRAIT(player, TRAIT_ROBOTIC_ORGANISM)) // никаких роботов-вампиров из далекого космоса
			candidates -= player

/datum/dynamic_ruleset/midround/bloodsuckers/ready(forced = FALSE)
	var/needed = get_antag_cap(length(living_players)) * (scaled_times + 1)
	if(length(candidates) < needed)
		ready_failure_reason = "подходящих членов экипажа [length(candidates)] из [needed] для кровососов"
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/bloodsuckers/director_preflight()
	. = director_preflight_candidates()
	if(.)
		var/needed = get_antag_cap(length(living_players)) * (scaled_times + 1)
		director_preflight_detail = "подходящих членов экипажа: [length(candidates)], требуется: [needed]"

/datum/dynamic_ruleset/midround/bloodsuckers/pre_execute(population)
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
