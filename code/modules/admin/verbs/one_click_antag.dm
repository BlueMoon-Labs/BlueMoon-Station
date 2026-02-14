/client/proc/one_click_antag()
	set name = "Create Antagonist"
	set desc = "Auto-create an antagonist of your choice"
	set category = "Admin.Events"

	if(holder)
		holder.one_click_antag()
	return


/datum/admins/proc/one_click_antag()

	var/dat = {"
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=traitors'>Make 1 Traitor</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=heretics'>Make 1 Heretic</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=changelings'>Make 1 Changeling</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=bloodsucker'>Make 1 Bloodsucker</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=revs'>Make 1 Head Rev</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=cult'>Make 1 Nar'Sie Cultist</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=clockcult'>Make 1 Clockwork Cultist</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=blob'>Make Blob</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=wizard'>Make Wizard (Requires Ghosts)</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=nukeops'>Make Nuke Team (Requires Ghosts)</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=syndicate_ops'>Make Syndicate Team (Requires Ghosts)</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=slaver'>Make Slave Trader Crew (Requires Ghosts)</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=centcom'>Make CentCom Response Team (Requires Ghosts)</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=abductors'>Make Abductor Team (Requires Ghosts)</a><br>
		<a href='?src=[REF(src)];[HrefToken()];makeAntag=revenant'>Make Revenant (Requires Ghost)</a><br>
		"}
	//<a href='?src=[REF(src)];[HrefToken()];makeAntag=qareen'>Make Qareen (Requires Ghost)</a><br> 	Temporary removed. - Gardelin0

	var/datum/browser/popup = new(usr, "oneclickantag", "Quick-Create Antagonist", 400, 400)
	popup.set_content(dat)
	popup.open()

/datum/admins/proc/isReadytoRumble(mob/living/carbon/human/applicant, targetrole, onstation = TRUE, conscious = TRUE)
	if(applicant.mind.special_role)
		return FALSE
	if(!HAS_ANTAG_PREF(applicant.client, targetrole)) // BLUEMOON EDIT - было if(!(targetrole in applicant.client.prefs.be_special))
		return FALSE
	// BLUEMOON ADD START - проверка на то, включено ли разрешение на бытие антагонистом посреди раунда
	if(!(applicant.client.prefs.toggles & MIDROUND_ANTAG))
		return FALSE
	// BLUEMOON ADD END
	if(onstation)
		var/turf/T = get_turf(applicant)
		if(!is_station_level(T.z))
			return FALSE
	if(conscious && applicant.stat) //incase you don't care about a certain antag being unconcious when made, ie if they have selfhealing abilities.
		return FALSE
	if(!considered_alive(applicant.mind) || considered_afk(applicant.mind)) //makes sure the player isn't a zombie, brain, or just afk all together
		return FALSE
	return (!jobban_isbanned(applicant, targetrole) && !jobban_isbanned(applicant, ROLE_INTEQ))


/datum/admins/proc/makeTraitors()
	var/datum/game_mode/traitor/temp = new

	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		temp.restricted_jobs += temp.protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		temp.restricted_jobs += "Assistant"

	var/list/mob/living/carbon/human/candidates = list()
	var/mob/living/carbon/human/H = null

	for(var/mob/living/carbon/human/applicant in GLOB.player_list)
		if(isReadytoRumble(applicant, ROLE_TRAITOR))
			if(temp.age_check(applicant.client))
				if(!(applicant.job in temp.restricted_jobs))
					candidates += applicant

	if(candidates.len)
		var/numTraitors = 1 // BLUEMOON EDIT - поставил 1, чтобы легче контролировать количество, а было min(candidates.len, 3)

		for(var/i = 0, i<numTraitors, i++)
			H = pick(candidates)
			H.mind.make_Traitor()
			candidates.Remove(H)

		return TRUE


	return FALSE

/datum/admins/proc/makeHeretics()

	var/datum/game_mode/heretics/temp = new
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		temp.restricted_jobs += temp.protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		temp.restricted_jobs += "Assistant"

	var/list/mob/living/carbon/human/candidates = list()
	var/mob/living/carbon/human/H = null

	for(var/mob/living/carbon/human/applicant in GLOB.player_list)
		if(isReadytoRumble(applicant, ROLE_HERETIC))
			if(temp.age_check(applicant.client))
				if(!(applicant.job in temp.restricted_jobs))
					candidates += applicant

	if(candidates.len)
		var/numHeretics = 1 // BLUEMOON EDIT - БЫЛО min(candidates.len, 3)

		for(var/i = 0, i<numHeretics, i++)
			H = pick(candidates)
			H.mind.make_Heretic()
			candidates.Remove(H)

		return 1

	return 0

/datum/admins/proc/makeChangelings()

	var/datum/game_mode/changeling/temp = new
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		temp.restricted_jobs += temp.protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		temp.restricted_jobs += "Assistant"

	var/list/mob/living/carbon/human/candidates = list()
	var/mob/living/carbon/human/H = null

	for(var/mob/living/carbon/human/applicant in GLOB.player_list)
		if(isReadytoRumble(applicant, ROLE_CHANGELING))
			if(temp.age_check(applicant.client))
				if(!(applicant.job in temp.restricted_jobs))
					candidates += applicant
		// BLUEMOON ADD START
		if(HAS_TRAIT(applicant, TRAIT_ROBOTIC_ORGANISM)) // никаких роботов-вампиров из далекого космоса
			candidates -= applicant
		// BLUEMOON ADD END

	if(candidates.len)
		var/numChangelings = 1 // BLUEMOON EDIT - было min(candidates.len, 3)

		for(var/i = 0, i<numChangelings, i++)
			H = pick(candidates)
			H.mind.make_Changeling()
			candidates.Remove(H)

		return TRUE

	return FALSE

/datum/admins/proc/makeRevs()

	var/datum/game_mode/revolution/temp = new
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		temp.restricted_jobs += temp.protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		temp.restricted_jobs += "Assistant"

	var/list/mob/living/carbon/human/candidates = list()
	var/mob/living/carbon/human/H = null

	for(var/mob/living/carbon/human/applicant in GLOB.player_list)
		if(isReadytoRumble(applicant, ROLE_REV))
			if(temp.age_check(applicant.client))
				if(!(applicant.job in temp.restricted_jobs))
					candidates += applicant

	if(candidates.len)
		var/numRevs = 1 // BLUEMOON EDIT - было min(candidates.len, 3)

		for(var/i = 0, i<numRevs, i++)
			H = pick(candidates)
			H.mind.make_Rev()
			candidates.Remove(H)
		return TRUE

	return FALSE

/datum/admins/proc/makeWizard()

	var/list/mob/candidates = pollGhostCandidates("Do you wish to be considered for the position of a Wizard Foundation 'diplomat'?", ROLE_WIZARD, null)

	var/mob/selected = pick_n_take(candidates)

	var/mob/living/carbon/human/new_character = makeBody(selected)
	new_character.mind.make_Wizard()
	return TRUE


/datum/admins/proc/makeCult()
	var/datum/game_mode/cult/temp = new
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		temp.restricted_jobs += temp.protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		temp.restricted_jobs += "Assistant"

	var/list/mob/living/carbon/human/candidates = list()
	var/mob/living/carbon/human/H = null

	for(var/mob/living/carbon/human/applicant in GLOB.player_list)
		if(isReadytoRumble(applicant, ROLE_CULTIST))
			if(temp.age_check(applicant.client))
				if(!(applicant.job in temp.restricted_jobs))
					candidates += applicant

	if(candidates.len)
		var/numCultists = 1 // BLUEMOON EDIT - было min(candidates.len, 4)

		for(var/i = 0, i<numCultists, i++)
			H = pick(candidates)
			H.mind.make_Cultist()
			candidates.Remove(H)

		return TRUE

	return FALSE


/datum/admins/proc/makeClockCult()
	var/datum/game_mode/clockwork_cult/temp = new
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		temp.restricted_jobs += temp.protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		temp.restricted_jobs += "Assistant"

	var/list/mob/living/carbon/human/candidates = list()
	var/mob/living/carbon/human/H = null

	for(var/mob/living/carbon/human/applicant in GLOB.player_list)
		if(isReadytoRumble(applicant, ROLE_SERVANT_OF_RATVAR))
			if(temp.age_check(applicant.client))
				if(!(applicant.job in temp.restricted_jobs))
					candidates += applicant

	if(candidates.len)
		var/numCultists = 1 // BLUEMOON EDIT - было min(candidates.len, 4)

		for(var/i = 0, i<numCultists, i++)
			H = pick(candidates)
			to_chat(H, "<span class='heavy_brass'>The world before you suddenly glows a brilliant yellow. You hear the whooshing steam and clanking cogs of a billion billion machines, and all at once \
			you see the truth. Ratvar, the Clockwork Justiciar, lies derelict and forgotten in an unseen realm, and he has selected you as one of his harbringers. You are now a servant of \
			Ratvar, and you will bring him back.</span>")
			H.playsound_local(get_turf(H), 'sound/ambience/antag/clockcultalr.ogg', 100, FALSE, pressure_affected = FALSE)
			add_servant_of_ratvar(H, TRUE)
			SSticker.mode.equip_servant(H)
			candidates.Remove(H)

		return TRUE

	return FALSE

#define MIN_AGENTS_REQ 3
#define MAX_AGENTS_REQ 5

/datum/admins/proc/makeNukeTeam()
	. = FALSE
	var/datum/game_mode/nuclear/temp = new
	var/list/mob/candidates = pollGhostCandidates("Do you wish to be considered for a nuke team being sent in?", ROLE_OPERATIVE, temp, minimum_required = MAX_AGENTS_REQ)
	var/list/mob/chosen = list()
	var/mob/theghost = null

	if(!candidates.len)
		return
	var/agentcount = 0

	for(var/i = 0, i < MAX_AGENTS_REQ, i++)
		shuffle_inplace(candidates) //More shuffles means more randoms
		for(var/mob/j in candidates)
			if(!j || !j.client)
				candidates.Remove(j)
				continue

			theghost = j
			candidates.Remove(theghost)
			chosen += theghost
			agentcount++
			break
	//Making sure we have atleast 3 Nuke agents, because less than that is kinda bad
	if(agentcount < MIN_AGENTS_REQ)
		return

	//Let's find the spawn locations
	var/leader_chosen = FALSE
	var/datum/team/nuclear/nuke_team
	for(var/mob/c in chosen)
		var/mob/living/carbon/human/new_character=makeBody(c)
		if(!leader_chosen)
			leader_chosen = TRUE
			var/datum/antagonist/nukeop/N = new_character.mind.add_antag_datum(/datum/antagonist/nukeop/leader)
			nuke_team = N.nuke_team
		else
			new_character.mind.add_antag_datum(/datum/antagonist/nukeop,nuke_team)
	return TRUE

/datum/admins/proc/makeSyndicateTeam()
	. = FALSE
	var/datum/game_mode/nuclear/temp = new
	var/list/mob/candidates = pollGhostCandidates("Do you wish to be considered for a nuke team being sent in?", ROLE_OPERATIVE, temp, minimum_required = MAX_AGENTS_REQ)
	var/list/mob/chosen = list()
	var/mob/theghost = null

	if(!candidates.len)
		return
	var/agentcount = 0

	for(var/i = 0, i < MAX_AGENTS_REQ,i++)
		shuffle_inplace(candidates) //More shuffles means more randoms
		for(var/mob/j in candidates)
			if(!j || !j.client)
				candidates.Remove(j)
				continue

			theghost = j
			candidates.Remove(theghost)
			chosen += theghost
			agentcount++
			break
	//Making sure we have atleast 3 Nuke agents, because less than that is kinda bad
	if(agentcount < MIN_AGENTS_REQ)
		return

	//Let's find the spawn locations
	var/leader_chosen = FALSE
	var/datum/team/nuclear/nuke_team
	for(var/mob/c in chosen)
		var/mob/living/carbon/human/new_character=makeBody(c)
		if(!leader_chosen)
			leader_chosen = TRUE
			var/datum/antagonist/syndicate_op/N = new_character.mind.add_antag_datum(/datum/antagonist/syndicate_op/leader)
			nuke_team = N.nuke_team
		else
			new_character.mind.add_antag_datum(/datum/antagonist/syndicate_op,nuke_team)
	return TRUE

#undef MIN_AGENTS_REQ
#undef MAX_AGENTS_REQ

//Abductors
///datum/admins/proc/makeAbductorTeam()
//	new /datum/round_event/ghost_role/abductor
//	return 1


/datum/admins/proc/makeAliens()
	var/datum/round_event/ghost_role/alien_infestation/E = new(FALSE)
	E.spawncount = 3
	// TODO The fact we have to do this rather than just have events start
	// when we ask them to, is bad.
	E.processing = TRUE
	return TRUE

/datum/admins/proc/makeSpaceNinja()
	new /datum/round_event/ghost_role/space_ninja()
	return TRUE

// DEATH SQUADS
/datum/admins/proc/makeDeathsquad()
	return makeEmergencyresponseteam(/datum/ert/deathsquad)

// CENTCOM RESPONSE TEAM

/datum/admins/proc/makeERTTemplateModified(list/settings)
	. = settings
	var/datum/ert/newtemplate = settings["mainsettings"]["template"]["value"]
	if (isnull(newtemplate))
		return
	if (!ispath(newtemplate))
		newtemplate = text2path(newtemplate)
	newtemplate = new newtemplate
	.["mainsettings"]["teamsize"]["value"] = newtemplate.teamsize
	.["mainsettings"]["mission"]["value"] = newtemplate.mission
	.["mainsettings"]["polldesc"]["value"] = newtemplate.polldesc
	.["mainsettings"]["ertphrase"]["value"] = newtemplate.ertphrase
	.["mainsettings"]["open_armory"]["value"] = newtemplate.opendoors ? "Yes" : "No"
	.["mainsettings"]["spawn_admin"]["value"] = newtemplate.spawn_admin ? "Yes" : "No"

/datum/admins/proc/equipAntagOnDummy(mob/living/carbon/human/dummy/mannequin, datum/antagonist/antag)
	for(var/I in mannequin.get_equipped_items(TRUE))
		qdel(I)
	if (ispath(antag, /datum/antagonist/ert))
		var/datum/antagonist/ert/ert = antag
		mannequin.equipOutfit(initial(ert.outfit), TRUE)
	else if (ispath(antag, /datum/antagonist/official))
		mannequin.equipOutfit(/datum/outfit/ert/centcom_official, TRUE)

/datum/admins/proc/makeERTPreviewIcon(list/settings)
	// Set up the dummy for its photoshoot
	var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_ADMIN)

	var/prefs = settings["mainsettings"]
	var/datum/ert/template = prefs["template"]["value"]
	if (isnull(template))
		return null
	if (!ispath(template))
		template = text2path(prefs["template"]["value"]) // new text2path ... doesn't compile in 511

	template = new template
	var/datum/antagonist/ert/ert = template.leader_role

	equipAntagOnDummy(mannequin, ert)

	CHECK_TICK
	var/icon/preview_icon = icon('icons/effects/effects.dmi', "nothing")
	preview_icon.Scale(48+32, 16+32)
	CHECK_TICK
	mannequin.setDir(NORTH)
	var/icon/stamp = getFlatIcon(mannequin)
	CHECK_TICK
	preview_icon.Blend(stamp, ICON_OVERLAY, 25, 17)
	CHECK_TICK
	mannequin.setDir(WEST)
	stamp = getFlatIcon(mannequin)
	CHECK_TICK
	preview_icon.Blend(stamp, ICON_OVERLAY, 1, 9)
	CHECK_TICK
	mannequin.setDir(SOUTH)
	stamp = getFlatIcon(mannequin)
	CHECK_TICK
	preview_icon.Blend(stamp, ICON_OVERLAY, 49, 1)
	CHECK_TICK
	preview_icon.Scale(preview_icon.Width() * 2, preview_icon.Height() * 2) // Scaling here to prevent blurring in the browser.
	CHECK_TICK
	unset_busy_human_dummy(DUMMY_HUMAN_SLOT_ADMIN)
	return preview_icon

/datum/admins/proc/makeEmergencyresponseteam(var/datum/ert/ertemplate = null)
	if (ertemplate)
		ertemplate = new ertemplate
	else
		ertemplate = new /datum/ert/centcom_official

	var/list/settings = list(
		"preview_callback" = CALLBACK(src, PROC_REF(makeERTPreviewIcon)),
		"mainsettings" = list(
		"template" = list("desc" = "Template", "callback" = CALLBACK(src, PROC_REF(makeERTTemplateModified)), "type" = "datum", "path" = "/datum/ert", "subtypesonly" = TRUE, "value" = ertemplate.type),
		"teamsize" = list("desc" = "Team Size", "type" = "number", "value" = ertemplate.teamsize),
		"mission" = list("desc" = "Mission", "type" = "string", "value" = ertemplate.mission),
		"polldesc" = list("desc" = "Ghost poll description", "type" = "string", "value" = ertemplate.polldesc),
		"ertphrase" = list("desc" = "ERT Sending Sound", "type" = "string", "value" = ertemplate.ertphrase),
		"enforce_human" = list("desc" = "Enforce human authority", "type" = "boolean", "value" = "[(CONFIG_GET(flag/enforce_human_authority) ? "Yes" : "No")]"),
		"open_armory" = list("desc" = "Open armory doors", "type" = "boolean", "value" = "[(ertemplate.opendoors ? "Yes" : "No")]"),
		"notify_players" = list("desc" = "Notify players that you have sent an ERT", "type" = "boolean", "value" = "[(ertemplate.notify_players ? "Yes" : "No")]"),
		"spawn_admin" = list("desc" = "Spawn yourself as briefing officer", "type" = "boolean", "value" = "[(ertemplate.spawn_admin ? "Yes" : "No")]"),
		)
	)

	var/list/prefreturn = presentpreflikepicker(usr,"Customize ERT", "Customize ERT", Button1="Ok", width = 600, StealFocus = 1,Timeout = 0, settings=settings)

	if (isnull(prefreturn))
		return FALSE

	if (prefreturn["button"] == 1)
		var/list/prefs = settings["mainsettings"]

		var/templtype = prefs["template"]["value"]
		if (!ispath(prefs["template"]["value"]))
			templtype = text2path(prefs["template"]["value"]) // new text2path ... doesn't compile in 511

		if (ertemplate.type != templtype)
			ertemplate = new templtype

		ertemplate.teamsize = prefs["teamsize"]["value"]
		ertemplate.mission = prefs["mission"]["value"]
		ertemplate.polldesc = prefs["polldesc"]["value"]
		ertemplate.ertphrase = prefs["ertphrase"]["value"]
		ertemplate.enforce_human = prefs["enforce_human"]["value"] == "Yes" ? TRUE : FALSE
		ertemplate.opendoors = prefs["open_armory"]["value"] == "Yes" ? TRUE : FALSE
		ertemplate.notify_players = prefs["notify_players"]["value"] == "Yes" ? TRUE : FALSE
		ertemplate.spawn_admin = prefs["spawn_admin"]["value"] == "Yes"
		if(ertemplate.notify_players)
			priority_announce("Внимание, [station_name()]. Мы формируем [ertemplate.polldesc] для отправки на станцию. Ожидайте.", "Инициализирован протокол ОБР", 'modular_bluemoon/sound/ert/ert_send.ogg') //BlueMoon sound

		var/list/mob/candidates = pollGhostCandidates("Do you wish to be considered for [ertemplate.polldesc]?", "Deathsquad", null, minimum_required = ertemplate.teamsize)
		var/team_name = ertemplate.polldesc || ertemplate.rename_team || ertemplate.code
		message_admins("Выбрано игроков: [candidates.len], для [team_name], минимум необходимо: [ertemplate.teamsize]")
		var/teamSpawned = FALSE
		if(candidates.len > 0)
			//Pick the (un)lucky players
			var/numagents = min(ertemplate.teamsize,candidates.len)

			//Create team
			var/datum/team/ert/ert_team = new ertemplate.team
			if(ertemplate.rename_team)
				ert_team.name = ertemplate.rename_team

			//Asign team objective
			var/datum/objective/missionobj = new
			missionobj.team = ert_team
			missionobj.explanation_text = ertemplate.mission
			missionobj.completed = TRUE
			ert_team.objectives += missionobj
			ert_team.mission = missionobj

			var/list/brief_spawn = list()
			for(var/obj/effect/landmark/ert_shuttle_brief_spawn/L in GLOB.landmarks_list)
				brief_spawn += L.loc
			if(!brief_spawn)
				message_admins("No valid spawn locations found, aborting...")
				return MAP_ERROR
			if(ertemplate.spawn_admin)
				if(isobserver(usr))
					var/mob/living/carbon/human/admin_officer = new (pick(brief_spawn))
					usr.client.prefs.copy_to(admin_officer)
					admin_officer.equipOutfit(/datum/outfit/spec_ops)
					admin_officer.key = usr.key
				else
					to_chat(usr, span_warning("Could not spawn you in as briefing officer as you are not a ghost!"))

			var/list/spawnpoints = GLOB.emergencyresponseteamspawn

			var/list/sorted_candidates = candidates.Copy()


			var/mob/living/carbon/human/candidate0
			var/mob/living/carbon/human/candidate1
			var/mob/living/carbon/human/candidate_max
			var/imax
			var/exp0
			var/exp1
			for (var/i = 1, i <= sorted_candidates.len, i++)
				candidate0 = sorted_candidates[i]
				exp0 = candidate0.client.prefs.exp[EXP_TYPE_ANTAG] * 10 + candidate0.client.prefs.exp[EXP_TYPE_SECURITY]
				imax = i
				for (var/j = i, j <= sorted_candidates.len, j++)
					candidate1 = sorted_candidates[j]
					exp1 = candidate1.client.prefs.exp[EXP_TYPE_ANTAG] * 10 + candidate1.client.prefs.exp[EXP_TYPE_SECURITY]
					if (exp0 < exp1)
						imax = j
						candidate_max = candidate1
				if (imax != i)
					sorted_candidates[imax] = candidate0
					sorted_candidates[i] = candidate_max

			var/candidate_id = 1
			while(numagents && candidates.len)
				if (numagents > spawnpoints.len)
					numagents--
					continue // This guy's unlucky, not enough spawn points, we skip him.
				var/spawnloc = spawnpoints[numagents]

				// выбираем кандидата ?
				//var/mob/chosen_candidate = pick(candidates)
				var/mob/chosen_candidate = sorted_candidates[candidate_id]

				candidates -= chosen_candidate
				if(!chosen_candidate.key)
					continue

				//Spawn the body
				var/mob/living/carbon/human/ERTOperative = new ertemplate.mobtype(spawnloc)
				chosen_candidate.client.prefs.copy_to(ERTOperative)
				chosen_candidate.transfer_ckey(ERTOperative)

				if(ertemplate.enforce_human || ERTOperative.dna.species.dangerous_existence) // Don't want any exploding plasmemes
					ERTOperative.set_species(/datum/species/human)

				//Give antag datum
				var/datum/antagonist/ert/ert_antag

				if(candidate_id == 1)
					ert_antag = new ertemplate.leader_role
				else
					ert_antag = ertemplate.roles[WRAP(numagents,1,length(ertemplate.roles) + 1)]
					ert_antag = new ert_antag

				ERTOperative.mind.add_antag_datum(ert_antag,ert_team)
				ERTOperative.mind.assigned_role = ert_antag.name

				//Logging and cleanup
				log_game("[key_name(ERTOperative)] has been selected as an [ert_antag.name]")
				numagents--
				teamSpawned++
				candidate_id++

			if (teamSpawned)
				message_admins("[ertemplate.polldesc] были отправлены на станцию со следующей миссией: [ertemplate.mission]")
				if(ertemplate.notify_players)
					priority_announce("Внимание, [station_name()]. Мы отправляем поздразделение - [ertemplate.polldesc]. Вам следует приготовиться.", "Подготовка Отряда Быстрого Реагирования", ertemplate.ertphrase) //BlueMoon sound
				if(ertemplate.code == "EPSILON")
					set_security_level(SEC_LEVEL_EPSILON)

			//Open the Armory doors
			if(ertemplate.opendoors)
				for(var/obj/machinery/door/poddoor/ert/door in GLOB.airlocks)
					door.open()
					CHECK_TICK
			return TRUE
		else
			if(ertemplate.notify_players)
				priority_announce("[station_name()], мы не можем выслать [ertemplate.polldesc] ввиду занятости всех действующих оперативников.", "Отряд Быстрого Реагирования недоступен", 'modular_bluemoon/sound/ert/ert_no.ogg') //BlueMoon sound
			return FALSE

	return

//Abductors
/datum/admins/proc/makeAbductorTeam()
	new /datum/round_event/ghost_role/abductor
	return TRUE

/datum/admins/proc/makeRevenant()
	new /datum/round_event/ghost_role/revenant(TRUE, TRUE)
	return TRUE

//datum/admins/proc/makeQareen()	Temporary removed. - Gardelin0
//	new /datum/round_event/ghost_role/qareen(TRUE, TRUE)
//	return TRUE
