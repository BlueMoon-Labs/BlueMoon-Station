/datum/antagonist/syndicate_op
	name = "Nuclear Operative"
	roundend_category = "Syndicate operatives" //just in case
	antagpanel_category = "SyndicateOp"
	job_rank = ROLE_OPERATIVE
	antag_moodlet = /datum/mood_event/focused
	threat = 10
	skill_modifiers = list(/datum/skill_modifier/job/level/wiring)
	show_to_ghosts = TRUE
	var/datum/team/syndicate_nuclear/nuke_team
	var/always_new_team = FALSE //If not assigned a team by default ops will try to join existing ones, set this to TRUE to always create new team.
	var/send_to_spawnpoint = TRUE //Should the user be moved to default spawnpoint.
	var/nukeop_outfit = /datum/outfit/syndicate
	var/title

/datum/antagonist/syndicate_op/proc/update_synd_icons_added(mob/living/M)
	var/datum/atom_hud/antag/opshud = GLOB.huds[ANTAG_HUD_OPS]
	opshud.join_hud(M)
	set_antag_hud(M, "synd")

/datum/antagonist/syndicate_op/proc/update_synd_icons_removed(mob/living/M)
	var/datum/atom_hud/antag/opshud = GLOB.huds[ANTAG_HUD_OPS]
	opshud.leave_hud(M)
	set_antag_hud(M, null)

/datum/antagonist/syndicate_op/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_synd_icons_added(M)
	ADD_TRAIT(owner, TRAIT_DISK_VERIFIER, NUKEOP_TRAIT)

/datum/antagonist/syndicate_op/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_synd_icons_removed(M)
	REMOVE_TRAIT(owner, TRAIT_DISK_VERIFIER, NUKEOP_TRAIT)

/datum/antagonist/syndicate_op/proc/equip_op()
	title = pick("Царь", "Босс", "Лидер", "Шеф", "Король", "Пингвин", "Директор", "Лорд", "Оверлорд", "Глав", "Альфа", "Первый", "Bождь", "Бонза", "Айко", "Русич", "Сек", "Мёртвый", "Не-Интековский")
	if(!ishuman(owner.current))
		return
	var/mob/living/carbon/human/H = owner.current

	if(!istype(H))
		return
	else
		H.equipOutfit(nukeop_outfit)

	give_alias()

	return TRUE

/datum/antagonist/syndicate_op/greet()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ops.ogg',100,0)
	to_chat(owner, "<span class='notice'>Вы Оперативник Синдиката!</span>")
	owner.announce_objectives()

/datum/antagonist/syndicate_op/on_gain()
	forge_objectives()
	. = ..()
	equip_op()
	memorize_code()
	if(send_to_spawnpoint)
		move_to_spawnpoint()


/datum/antagonist/syndicate_op/get_team()
	return nuke_team

/datum/antagonist/syndicate_op/proc/assign_nuke()
	if(nuke_team && !nuke_team.tracked_nuke)
		nuke_team.memorized_code = random_nukecode()
		var/obj/machinery/nuclearbomb/syndicate/nuke = locate() in GLOB.nuke_list
		if(nuke)
			nuke_team.tracked_nuke = nuke
			if(nuke.r_code == "ADMIN")
				nuke.r_code = nuke_team.memorized_code
			else //Already set by admins/something else?
				nuke_team.memorized_code = nuke.r_code
			for(var/obj/machinery/nuclearbomb/beer/beernuke in GLOB.nuke_list)
				beernuke.r_code = nuke_team.memorized_code
		else
			stack_trace("Syndicate nuke not found during nuke team creation.")
			nuke_team.memorized_code = null

/datum/antagonist/syndicate_op/proc/give_alias()
	if(nuke_team && nuke_team.syndicate_name)
		var/number = 1
		number = nuke_team.members.Find(owner)
		owner.current.real_name = "[nuke_team.syndicate_name] Оперативник #[number]"

/datum/antagonist/syndicate_op/proc/memorize_code()
	if(nuke_team && nuke_team.tracked_nuke && nuke_team.memorized_code)
		antag_memory += "<B>[nuke_team.tracked_nuke] Code</B>: [nuke_team.memorized_code]<br>"
		to_chat(owner, "The nuclear authorization code is: <B>[nuke_team.memorized_code]</B>")
	else
		to_chat(owner, "Unfortunately the Syndicate was unable to provide you with nuclear authorization code.")

/datum/antagonist/syndicate_op/proc/forge_objectives()
	if(nuke_team)
		objectives |= nuke_team.objectives

/datum/antagonist/syndicate_op/proc/move_to_spawnpoint()
	var/team_number = 1
	if(nuke_team)
		team_number = nuke_team.members.Find(owner)
	owner.current.forceMove(GLOB.syndiop_start[((team_number - 1) % GLOB.syndiop_start.len) + 1])

/datum/antagonist/syndicate_op/leader/move_to_spawnpoint()
	owner.current.forceMove(pick(GLOB.nukeop_leader_start))

/datum/antagonist/syndicate_op/create_team(datum/team/nuclear/new_team)
	if(!new_team)
		if(!always_new_team)
			for(var/datum/antagonist/syndicate_op/N in GLOB.antagonists)
				if(!N.owner)
					continue
				if(N.nuke_team)
					nuke_team = N.nuke_team
					return
		nuke_team = new /datum/team/syndicate_nuclear
		nuke_team.update_objectives()
		assign_nuke() //This is bit ugly
		return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	nuke_team = new_team

/datum/antagonist/syndicate_op/admin_add(datum/mind/new_owner,mob/admin)
	new_owner.assigned_role = ROLE_SYNDICATE
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has nuke op'ed [new_owner.current].")
	log_admin("[key_name(admin)] has nuke op'ed [new_owner.current].")

/datum/antagonist/syndicate_op/get_admin_commands()
	. = ..()
	.["Send to base"] = CALLBACK(src,PROC_REF(admin_send_to_base))
	.["Tell code"] = CALLBACK(src,PROC_REF(admin_tell_code))

/datum/antagonist/syndicate_op/proc/admin_send_to_base(mob/admin)
	owner.current.forceMove(pick(GLOB.syndiop_start))

/datum/antagonist/syndicate_op/proc/admin_tell_code(mob/admin)
	var/code
	for (var/obj/machinery/nuclearbomb/bombue in GLOB.machines)
		if (length(bombue.r_code) <= 5 && bombue.r_code != initial(bombue.r_code))
			code = bombue.r_code
			break
	if (code)
		antag_memory += "<B>Syndicate Nuclear Bomb Code</B>: [code]<br>"
		to_chat(owner.current, "The nuclear authorization code is: <B>[code]</B>")
	else
		to_chat(admin, "<span class='danger'>No valid nuke found!</span>")

/datum/antagonist/syndicate_op/leader
	name = "Nuclear Operative Leader"
	nukeop_outfit = /datum/outfit/syndicate/leader
	always_new_team = TRUE

/datum/antagonist/syndicate_op/leader/memorize_code()
	..()
	if(nuke_team?.memorized_code)
		var/obj/item/paper/nuke_code_paper = new
		nuke_code_paper.add_raw_text("The nuclear authorization code is: <b>[nuke_team.memorized_code]</b>")
		nuke_code_paper.name = "nuclear bomb code"
		var/mob/living/carbon/human/H = owner.current
		if(!istype(H))
			nuke_code_paper.forceMove(get_turf(H))
		else
			H.put_in_hands(nuke_code_paper, TRUE)
			H.update_icons()

/datum/antagonist/syndicate_op/leader/give_alias()
	if(nuke_team && nuke_team.syndicate_name)
		owner.current.real_name = "[nuke_team.syndicate_name] [title]"
	else
		owner.current.real_name = "Syndicate [title]"

/datum/antagonist/syndicate_op/leader/greet()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ops.ogg',100,0)
	to_chat(owner, "<B>You are the Syndicate [title] for this mission. You are responsible for the distribution of credits and your ID is the only one who can open the launch bay doors.</B>")
	to_chat(owner, "<B>If you feel you are not up to this task, give your ID to another operative.</B>")
	to_chat(owner, "<B>In your hand you will find a special item capable of triggering a greater challenge for your team. Examine it carefully and consult with your fellow operatives before activating it.</B>")
	owner.announce_objectives()
	priority_announce("Внимание экипажу станции, боевым крейсером триглава была перехвачена входящая передача, свидетельствующая о враждебной деятельности, направленной на ядерный саботаж. Командованием флота было принято решение выслать на ваш объект специальный отряд противодействия ядерным угрозам, состоящий из подготовленных оперативников отделения [title].", "Крейсер [title] ССО Синдиката", 'sound/misc/announce_syndi.ogg')
	addtimer(CALLBACK(src, PROC_REF(nuketeam_name_assign)), 1)

/datum/antagonist/syndicate_op/leader/proc/nuketeam_name_assign()
	if(!nuke_team)
		return
	nuke_team.rename_team(ask_name())

/datum/team/syndicate_nuclear/proc/rename_team(new_name)
	syndicate_name = new_name
	name = "[syndicate_name] Team"
	for(var/I in members)
		var/datum/mind/synd_mind = I
		var/mob/living/carbon/human/H = synd_mind.current
		if(!istype(H))
			continue
		var/chosen_name = H.dna.species.random_name(H.gender,0,syndicate_name)
		H.fully_replace_character_name(H.real_name,chosen_name)

/datum/antagonist/syndicate_op/leader/proc/ask_name()
	var/randomname = pick(GLOB.last_names)
	var/newname = stripped_input(owner.current,"Вы Ядерный Оперативник [title]. Пожалуйста, сделайте выбор, как будет называться ваша команда. Не называйте свою команду дебильно или будете взорваны.", "Name change",randomname)
	if (!newname)
		newname = randomname
	else
		newname = reject_bad_name(newname)
		if(!newname)
			newname = randomname

	return capitalize(newname)

/datum/antagonist/syndicate_op/reinforcement
	send_to_spawnpoint = FALSE
	nukeop_outfit = /datum/outfit/syndicate/no_crystals

/datum/team/syndicate_nuclear
	var/syndicate_name
	var/obj/machinery/nuclearbomb/tracked_nuke
	var/core_objective = /datum/objective/nuclear
	var/revert_objective = /datum/objective/nuclear/revert
	var/memorized_code
	var/list/team_discounts
	var/datum/weakref/war_button_ref

/datum/team/syndicate_nuclear/New()
	..()
	syndicate_name = syndicate_name()

/datum/team/syndicate_nuclear/proc/update_objectives()
	var/datum/objective/O = new revert_objective
	O.team = src
	objectives += O

/datum/team/syndicate_nuclear/proc/disk_rescued()
	for(var/obj/item/disk/nuclear/D in GLOB.poi_list)
		//If emergency shuttle is in transit disk is only safe on it
		if(SSshuttle.emergency.mode == SHUTTLE_ESCAPE)
			if(!SSshuttle.emergency.is_in_shuttle_bounds(D))
				return FALSE
		//If shuttle escaped check if it's on centcom side
		else if(SSshuttle.emergency.mode == SHUTTLE_ENDGAME)
			if(!D.onCentCom())
				return FALSE
		else //Otherwise disk is safe when on station
			var/turf/T = get_turf(D)
			if(!T || !is_station_level(T.z))
				return FALSE
	return TRUE

/datum/team/syndicate_nuclear/proc/operatives_dead()
	for(var/I in members)
		var/datum/mind/operative_mind = I
		if(ishuman(operative_mind.current) && (operative_mind.current.stat != DEAD))
			return FALSE
	return TRUE

/datum/team/syndicate_nuclear/proc/syndies_escaped()
	var/obj/docking_port/mobile/S = SSshuttle.getShuttle("syndicate")
	var/obj/docking_port/stationary/transit/T = locate() in S.loc
	return S && (is_centcom_level(S.z) || T)

/datum/team/syndicate_nuclear/proc/get_result()
	var/evacuation = EMERGENCY_ESCAPED_OR_ENDGAMED
	var/disk_rescued = disk_rescued()
	var/syndies_didnt_escape = !syndies_escaped()
	var/station_was_nuked = SSticker.mode.station_was_nuked
	var/nuke_off_station = SSticker.mode.nuke_off_station

	if(nuke_off_station == NUKE_SYNDICATE_BASE)
		return NUKE_RESULT_FLUKE
	else if(station_was_nuked && !syndies_didnt_escape)
		return NUKE_RESULT_NUKE_WIN
	else if (station_was_nuked && syndies_didnt_escape)
		return NUKE_RESULT_NOSURVIVORS
	else if (!disk_rescued && !station_was_nuked && nuke_off_station && !syndies_didnt_escape)
		return NUKE_RESULT_WRONG_STATION
	else if (!disk_rescued && !station_was_nuked && nuke_off_station && syndies_didnt_escape)
		return NUKE_RESULT_WRONG_STATION_DEAD
	else if ((disk_rescued && evacuation) && operatives_dead())
		return NUKE_RESULT_CREW_WIN_SYNDIES_DEAD
	else if (disk_rescued)
		return NUKE_RESULT_CREW_WIN
	else if (!disk_rescued && operatives_dead())
		return NUKE_RESULT_DISK_LOST
	else if (!disk_rescued && evacuation)
		return NUKE_RESULT_DISK_STOLEN
	else
		return	//Undefined result

/datum/team/syndicate_nuclear/roundend_report()
	var/list/parts = list()
	parts += "<span class='header'>[syndicate_name] Operatives:</span>"

	switch(get_result())
		if(NUKE_RESULT_FLUKE)
			parts += "<span class='redtext big'>Humiliating Syndicate Defeat</span>"
			parts += "<B>The crew of [station_name()] gave [syndicate_name] operatives back their bomb! The Syndicate base was destroyed!</B> Next time, don't lose the nuke!"
		if(NUKE_RESULT_NUKE_WIN)
			parts += "<span class='greentext big'>Syndicate Major Victory!</span>"
			parts += "<B>[syndicate_name] operatives have destroyed [station_name()]!</B>"
		if(NUKE_RESULT_NOSURVIVORS)
			parts += "<span class='neutraltext big'>Total Annihilation</span>"
			parts +=  "<B>[syndicate_name] operatives destroyed [station_name()] but did not leave the area in time and got caught in the explosion.</B> Next time, don't lose the disk!"
		if(NUKE_RESULT_WRONG_STATION)
			parts += "<span class='redtext big'>Crew Minor Victory</span>"
			parts += "<B>[syndicate_name] operatives secured the authentication disk but blew up something that wasn't [station_name()].</B> Next time, don't do that!"
		if(NUKE_RESULT_WRONG_STATION_DEAD)
			parts += "<span class='redtext big'>[syndicate_name] operatives have earned Darwin Award!</span>"
			parts += "<B>[syndicate_name] operatives blew up something that wasn't [station_name()] and got caught in the explosion.</B> Next time, don't do that!"
		if(NUKE_RESULT_CREW_WIN_SYNDIES_DEAD)
			parts += "<span class='redtext big'>Crew Major Victory!</span>"
			parts += "<B>The Research Staff has saved the disk and killed the [syndicate_name] Operatives</B>"
		if(NUKE_RESULT_CREW_WIN)
			parts += "<span class='redtext big'>Crew Major Victory</span>"
			parts += "<B>The Research Staff has saved the disk and stopped the [syndicate_name] Operatives!</B>"
		if(NUKE_RESULT_DISK_LOST)
			parts += "<span class='neutraltext big'>Neutral Victory!</span>"
			parts += "<B>The Research Staff failed to secure the authentication disk but did manage to kill most of the [syndicate_name] Operatives!</B>"
		if(NUKE_RESULT_DISK_STOLEN)
			parts += "<span class='greentext big'>Syndicate Minor Victory!</span>"
			parts += "<B>[syndicate_name] operatives survived the assault but did not achieve the destruction of [station_name()].</B> Next time, don't lose the disk!"
		else
			parts += "<span class='neutraltext big'>Neutral Victory</span>"
			parts += "<B>Mission aborted!</B>"

	var/text = "<br><span class='header'>The Syndicate operatives were:</span>"
	var/purchases = ""
	var/TC_uses = 0
	LAZYINITLIST(GLOB.uplink_purchase_logs_by_key)
	for(var/I in members)
		var/datum/mind/syndicate = I
		var/datum/uplink_purchase_log/H = GLOB.uplink_purchase_logs_by_key[syndicate.key]
		if(H)
			TC_uses += H.total_spent
			purchases += H.generate_render(show_key = FALSE)
	text += printplayerlist(members)
	text += "<br>"
	text += "(Syndicate used [TC_uses] CR) [purchases]"
	if(TC_uses == 0 && SSticker.mode.station_was_nuked && !operatives_dead())
		text += "<BIG>[icon2html('icons/badass.dmi', world, "badass")]</BIG>"

	parts += text

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/datum/team/syndicate_nuclear/antag_listing_name()
	if(syndicate_name)
		return "[syndicate_name] Syndicate"
	else
		return "Syndicate"

/datum/team/syndicate_nuclear/antag_listing_entry()
	var/disk_report = "<b>Nuclear Disk(s)</b><br>"
	disk_report += "<table cellspacing=5>"
	for(var/obj/item/disk/nuclear/N in GLOB.poi_list)
		disk_report += "<tr><td>[N.name], "
		var/atom/disk_loc = N.loc
		while(!isturf(disk_loc))
			if(ismob(disk_loc))
				var/mob/M = disk_loc
				disk_report += "carried by <a href='?_src_=holder;[HrefToken()];adminplayeropts=[REF(M)]'>[M.real_name]</a> "
			if(isobj(disk_loc))
				var/obj/O = disk_loc
				disk_report += "in \a [O.name] "
			disk_loc = disk_loc.loc
		disk_report += "in [disk_loc.loc] at ([disk_loc.x], [disk_loc.y], [disk_loc.z])</td><td><a href='?_src_=holder;[HrefToken()];adminplayerobservefollow=[REF(N)]'>FLW</a></td></tr>"
	disk_report += "</table>"
	var/common_part = ..()
	return common_part + disk_report

/datum/team/syndicate_nuclear/is_gamemode_hero()
	return SSticker.mode.name == "nuclear emergency"

/obj/item/paper/fluff/syndicate_dropship
	name = "Пояснение по поводу Дроп-Пода"
	default_raw_text = "Обойдётесь."

/datum/outfit/syndicate
	name = "Syndicate Operative - Basic"

	uniform = /obj/item/clothing/under/syndicate
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	back = /obj/item/storage/backpack
	ears = /obj/item/radio/headset/syndicate/alt
	l_pocket = /obj/item/pinpointer/nuke/syndicate
	id = /obj/item/card/id/syndicate
	belt = /obj/item/gun/ballistic/automatic/pistol
	backpack_contents = list(/obj/item/storage/box/survival/syndie=1,\
		/obj/item/kitchen/knife/combat/survival)

	var/tc = 75
	var/command_radio = FALSE
	var/uplink_type = /obj/item/syndicate_uplink_high/nuclear

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/syndicate/leader
	name = "Syndicate Leader - Basic"
	id = /obj/item/card/id/syndicate/nuke_leader
	gloves = /obj/item/clothing/gloves/krav_maga/combatglovesplus
	command_radio = TRUE

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/syndicate/leader/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/syndicate/no_crystals
	tc = 0

/datum/outfit/syndicate/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_SYNDICATE)
	R.freqlock = TRUE
	if(command_radio)
		R.command = TRUE

	if(tc)
		var/obj/item/U = new uplink_type(H, H.key, tc)
		H.equip_to_slot_or_del(U, ITEM_SLOT_BACKPACK)

	var/obj/item/implant/weapons_auth/W = new
	W.implant(H)
	var/obj/item/implant/explosive/E = new
	E.implant(H)

	H.faction |= ROLE_SYNDICATE
	H.update_icons()

/datum/outfit/syndicate/full
	name = "Syndicate Operative - Full Kit"

	glasses = /obj/item/clothing/glasses/night/syndicate
	mask = /obj/item/clothing/mask/gas/syndicate
	suit = /obj/item/clothing/suit/space/hardsuit/syndi
	r_pocket = /obj/item/tank/internals/emergency_oxygen/engi
	internals_slot = ITEM_SLOT_RPOCKET
	belt = /obj/item/storage/belt/military
	r_hand = /obj/item/gun/ballistic/automatic/shotgun/bulldog
	backpack_contents = list(/obj/item/storage/box/survival/syndie=1,\
		/obj/item/tank/jetpack/oxygen/harness=1,\
		/obj/item/gun/ballistic/automatic/pistol=1,\
		/obj/item/kitchen/knife/combat/survival)

/datum/outfit/syndicate/lone
	name = "Lone Operative"

	glasses = /obj/item/clothing/glasses/night/syndicate
	uniform = /obj/item/clothing/under/syndicate
	mask = /obj/item/clothing/mask/gas/syndicate
	suit = /obj/item/clothing/suit/space/syndicate/black/red
	head = /obj/item/clothing/head/helmet/space/syndicate/black/red
	id = /obj/item/card/id/syndicate
	r_pocket = /obj/item/tank/internals/emergency_oxygen/engi/syndi
	internals_slot = ITEM_SLOT_RPOCKET
	belt = /obj/item/storage/belt/military
	accessory = list(/obj/item/clothing/accessory/permit/special/disk_keeper)
	backpack_contents = list(/obj/item/storage/box/survival/syndie=1,
	/obj/item/tank/jetpack/oxygen/harness=1,
	/obj/item/gun/ballistic/automatic/pistol=1,
	/obj/item/kitchen/knife/combat/survival)

	uplink_type = /obj/item/syndicate_uplink
	tc = 120

/datum/outfit/syndicate/lone/post_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/obj/item/card/id/syndicate/W = H.wear_id
	W.registered_name = H.real_name
	W.assignment = "Syndicate Nuclear Disk Protector"
	W.special_assignment = "syndicate"
	W.update_label()
	W.update_appearance()
	H.sec_hud_set_ID()

/datum/outfit/syndicate/syndiesquad
	name = "Syndicate Special Forces"
	ears = /obj/item/radio/headset/headset_cent/alt
	uniform = /obj/item/clothing/under/syndicate
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	back = /obj/item/storage/backpack
	id = /obj/item/card/id/syndicate/locked_banking
	belt = /obj/item/gun/ballistic/automatic/pistol/APS
	backpack_contents = list(/obj/item/storage/box/survival/syndie=1,
	/obj/item/kitchen/knife/combat/survival)

	uplink_type = /obj/item/syndicate_uplink_high/nuclear

/datum/outfit/syndicate/syndiesquad/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(visualsOnly)
		return

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CENTCOM)
	R.freqlock = TRUE

	var/key = H.key ? H.key : preference_source ? preference_source.key : null
	var/obj/item/syndicate_uplink_high/nuclear/U = new /obj/item/syndicate_uplink_high/nuclear(H, key, 80)
	H.equip_to_slot_or_del(U, ITEM_SLOT_BACKPACK)

	var/obj/item/implant/mindshield/L = new //Here you go Deuryn
	L.implant(H, null, 1)

	var/obj/item/card/id/syndicate/W = H.wear_id
	W.icon_state = "syndie"
	W.access = get_all_accesses()+get_centcom_access("Death Commando")+get_all_syndicate_access()//They get full station access.
	W.assignment = "Syndicate Special Forces"
	W.registered_name = H.real_name
	W.update_label()

	var/obj/item/implant/weapons_auth/Q = new
	Q.implant(H)
	var/obj/item/implant/explosive/E = new
	E.implant(H)
	H.update_icons()

	H.grant_language(/datum/language/codespeak, source = LANGUAGE_MIND)
