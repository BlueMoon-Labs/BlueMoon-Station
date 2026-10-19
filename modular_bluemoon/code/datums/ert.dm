/datum/ert/firesquad // Пожиратели огня
	roles = list(/datum/antagonist/ert/firesquad)
	leader_role = /datum/antagonist/ert/firesquad/leader
	enforce_human = TRUE
	rename_team = "NT Flametroopers Squad"
	code = "Red"
	mission = "экипаж станции не справляется с активной биологической угрозой. Окажите соответствующую поддержку."
	polldesc = "Elite Nanotrasen Fire Team"
	ertphrase = "modular_bluemoon/sound/ert/ert_firesquad_send.ogg"

/datum/ert/heavysquad // Удар молота
	roles = list(/datum/antagonist/ert/heavysquad, /datum/antagonist/ert/heavysquad/machinegun)
	leader_role = /datum/antagonist/ert/heavysquad/leader
	rename_team = "NT Heavy Weapons Squad"
	code = "Delta"
	mission = "по имеющимся разведанным на станции присутствует особо опасный и тяжеловооруженный противник. Корпорация заинтересована в сохранении своих активов. Разберитесь с проблемой."
	polldesc = "Elite Nanotrasen Heavy Team"
	ertphrase = "modular_bluemoon/sound/ert/ert_heavysquad_send.ogg"

/datum/ert/russian_ert // НРИ
	roles = list(/datum/antagonist/ert/russian_ert, /datum/antagonist/ert/russian_ert/support)
	leader_role = /datum/antagonist/ert/russian_ert/leader
	rename_team = "Novaya Rossiyskaya Imperiya Spetsnaz Squad"
	code = "Delta"
	mission = "от одной из близлежащих космических станций получен сигнал о помощи. Мы связались с НТ и получили добро на вмешательство. Окажите поддержку."
	polldesc = "Novaya Rossiyskaya Imperiya Spetsnaz Squad"
	ertphrase = "modular_bluemoon/sound/ert/nri_send.ogg"

/datum/ert/sol_ert // Солнечная Федерация
	roles = list(/datum/antagonist/ert/sol_ert, /datum/antagonist/ert/sol_ert/support)
	leader_role = /datum/antagonist/ert/sol_ert/leader
	rename_team = "Solar Federation Marine Squad"
	code = "Delta"
	mission = "Nanotrasen авторизовали интервенцию сил Солнечной Федерации на космическую станцию. Окажите помощь её экипажу."
	polldesc = "Solar Federation Marine Squad"
	ertphrase = "modular_bluemoon/sound/ert/sol_send.ogg"

/datum/ert/engineer_ert // Инженерное подразделение
	roles = list(/datum/antagonist/ert/engineer)
	leader_role = /datum/antagonist/ert/engineer_squadleader
	rename_team = "Emergency Engineer Squad"
	code = "Orange"
	mission = "окажите поддержку станции по части ремонтных работ."
	polldesc = "Emergency Engineer Squad"
	//ertphrase = "modular_bluemoon/sound/ert/sol_send.ogg"

/datum/ert/ntr_ert // Агенты Внутренних Дел
	roles = list(/datum/antagonist/ert/ntr_ert_agent)
	leader_role = /datum/antagonist/ert/ntr_ert_leader
	maxteamsize = 4
	rename_team = "Internal Affairs Squad"
	code = "Red"
	mission = "слушайтесь Представителя Корпорации. Окажите поддержку Представителю Корпорации в установлении порядка и верховенства права на станции."
	polldesc = "Internal Affairs Squad"
	//ertphrase = "modular_bluemoon/sound/ert/sol_send.ogg"

/datum/ert/maid_ert // рофлоЕРТ горничных
	roles = list(/datum/antagonist/ert/maid)
	leader_role = /datum/antagonist/ert/maid_leader
	rename_team = "Elite Maid Squad"
	code = "Delta"
	mission = "наведите порядок на станции, если вы понимаете, что офицер ССО имел ввиду."
	polldesc = "Elite Maid Squad"
	//ertphrase = "modular_bluemoon/sound/ert/sol_send.ogg"

/datum/ert/zealteam_ert // Удар наковальней
	roles = list(/datum/antagonist/ert/zeal_team)
	leader_role = /datum/antagonist/ert/zeal_team/leader
	rename_team = "Zeal Team Squad"
	polldesc = "Zeal Team Squad"
	code = "Delta"
	mission = "по имеющимся разведанным на станции присутствует особо опасный и тяжеловооруженный противник. Корпорация заинтересована в сохранении своих активов. Разберитесь с проблемой."
	ertphrase = "modular_bluemoon/sound/ert/ert_heavysquad_send.ogg"

/datum/ert/rabbit
	roles = list(/datum/antagonist/ert/security/rabbit)
	leader_role = /datum/antagonist/ert/commander/rabbit
	opendoors = FALSE
	maxteamsize = 10
	rename_team = "Rabbit Team"
	mission = "устраните любые нарушения и/или отклонения от нормы на станции."
	polldesc = "a Rabbit Team"
	code = "Orange"
	ertphrase = 'modular_bluemoon/sound/ert/rabbit_protocol.ogg'

/datum/ert/lfwb_ordinator
	roles = list(/datum/antagonist/ert/lfwb_ordinator)
	leader_role = /datum/antagonist/ert/lfwb_ordinator/leader
	opendoors = TRUE
	rename_team = "Tribunal Ordinator"
	code = "Red"
	mission = "уничтожить все угрозы Активам ПАКТа."
	polldesc = "an Nanotrasen Tribunal Ordinator"
	ertphrase = "modular_bluemoon/sound/ert/ert_tribunal.ogg"

/// Собирает отряд из уже опрошенных кандидатов на точках спауна ОБР; последний заспауненный - лидер.
/// Взятые кандидаты вынимаются из списка. Возвращает созданных бойцов.
/datum/ert/proc/spawn_members(list/mob/candidates, max_members = null)
	var/list/mob/living/carbon/human/members = list()
	var/agents_left = min(isnull(max_members) ? maxteamsize : max_members, length(candidates))
	if(agents_left <= 0)
		return members
	var/datum/team/ert/ert_team = new team
	if(rename_team)
		ert_team.name = rename_team
	var/datum/objective/mission_objective = new
	mission_objective.team = ert_team
	mission_objective.explanation_text = mission
	mission_objective.completed = TRUE
	ert_team.objectives += mission_objective
	ert_team.mission = mission_objective
	var/list/spawnpoints = GLOB.emergencyresponseteamspawn
	while(agents_left && length(candidates))
		if(agents_left > length(spawnpoints))
			agents_left--
			continue
		var/mob/chosen_candidate = pick_n_take(candidates)
		if(!chosen_candidate.key || !chosen_candidate.client)
			continue
		var/mob/living/carbon/human/operative = new mobtype(spawnpoints[agents_left])
		chosen_candidate.client.prefs.copy_to(operative)
		chosen_candidate.transfer_ckey(operative)
		if(enforce_human || operative.dna.species.dangerous_existence)
			operative.set_species(/datum/species/human)
		var/role_type = (agents_left == 1) ? leader_role : roles[WRAP(agents_left, 1, length(roles) + 1)]
		var/datum/antagonist/ert/ert_antag = new role_type
		operative.mind.add_antag_datum(ert_antag, ert_team)
		operative.mind.assigned_role = ert_antag.name
		log_game("[key_name(operative)] has been selected as an [ert_antag.name]")
		members += operative
		agents_left--
	if(!length(members))
		qdel(ert_team)
	return members
