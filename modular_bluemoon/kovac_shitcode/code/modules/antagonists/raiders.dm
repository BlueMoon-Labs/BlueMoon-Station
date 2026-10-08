/datum/antagonist/raiders
	name = "InteQ Raider"
	job_rank = ROLE_TRAITOR
	roundend_category = "inteq raiders"
	antagpanel_category = "InteQ"
	threat = 15
	show_to_ghosts = TRUE
	var/datum/team/raiders/crew

/datum/antagonist/raiders/greet()
	SEND_SOUND(owner.current, sound('modular_bluemoon/kovac_shitcode/sound/inteq_raiders_spawn.ogg'))
	to_chat(owner, "<span class='boldannounce'>Вы - наёмник InteQ!</span>")
	to_chat(owner, "<B>Капитан станции отказался заплатить. Атакуйте её: похищайте ресурсы, берите заложников. Избегайте ненужных жертв. Не забывайте следить за своим кораблём.</B>")
	owner.announce_objectives()

/datum/antagonist/raiders/get_team()
	return crew

/datum/antagonist/raiders/create_team(datum/team/raiders/new_team)
	if(!new_team)
		for(var/datum/antagonist/raiders/P in GLOB.antagonists)
			if(!P.owner)
				continue
			if(P.crew)
				crew = P.crew
				return
		if(!new_team)
			crew = new /datum/team/raiders
			crew.forge_objectives()
			return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	crew = new_team

/datum/team/raiders/proc/forge_objectives()
	var/datum/objective/loot/getbooty = new()
	var/datum/objective/kidnap/kidnap_objective = new
	var/datum/objective/kidnap/kidnap_objective_additional = new

	getbooty.team = src
	for(var/obj/machinery/computer/piratepad_control/P in GLOB.machines)
		var/area/A = get_area(P)
		if(istype(A,/area/shuttle/inteq/collosus))
			getbooty.cargo_hold = P
			break
	getbooty.update_explanation_text()
	objectives += getbooty
	for(var/datum/mind/M in members)
		var/datum/antagonist/raiders/P = M.has_antag_datum(/datum/antagonist/raiders)
		if(P)
			P.objectives |= objectives

	//if(prob(45)) // BlueMoon. Тестируем цель на похищение. Первое время она будет гарантированно выдаваться рейдерам.
	kidnap_objective.team = src
	if(kidnap_objective.find_target())
		objectives += kidnap_objective
	else
		qdel(kidnap_objective)

	if(prob(25)) // Дополнительная цель
		kidnap_objective_additional.team = src
		if(kidnap_objective_additional.find_target())
			objectives += kidnap_objective_additional
		else
			qdel(kidnap_objective_additional)

	return

/datum/antagonist/raiders/on_gain()
	if(crew)
		objectives |= crew.objectives
	. = ..()

/datum/team/raiders
	name = "InteQ"

///////////////  Sleeper //////

/obj/effect/mob_spawn/human/raider
	name = "InteQ Raider Sleeper"
	desc = "A cryo sleeper. Look slightly modified. <i>Seems like it can be destroyed with the right tools...</i>"
	job_description = "InteQ Raider"
	random = TRUE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_name = "an InteQ raider"
	can_load_appearance = TRUE
	outfit = /datum/outfit/inteq_raider
	roundstart = FALSE
	death = FALSE
	anchored = TRUE
	density = FALSE
	show_flavour = FALSE //Flavour only exists for spawners menu
	can_load_appearance = TRUE
	short_desc = "You are an InteQ raider."
	flavour_text = "Капитан станции отказался платить в ответ на требование наёмников InteQ. Атакуйте её: похищайте ресурсы, берите заложников. Избегайте ненужных жертв. Не забывайте следить за своим корабль."
	assignedrole = "InteQ Raider"
	category = "midround"

/obj/effect/mob_spawn/human/raider/vanguard
	outfit = /datum/outfit/inteq_raider/vanguard

/obj/effect/mob_spawn/human/raider/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(user.mind.has_antag_datum(/datum/antagonist/raiders))
		to_chat(user, "<span class='notice'>Your shipmate sails within their dreams for now. Perhaps they may wake up eventually.</span>")
	else
		to_chat(user, "<span class='notice'>If you want to destroy the sleeper, something to pry open it might be the best way.</span>")


/obj/effect/mob_spawn/human/raider/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_CROWBAR && user.a_intent != INTENT_HARM)
		if(user.mind.has_antag_datum(/datum/antagonist/raiders))
			to_chat(user,"<span class='warning'>Why would you want to the PMC propercy? That'd be stupid.</span>")
			return
		user.visible_message("<span class='warning'>[user] start to pry open [src]...</span>",
				"<span class='notice'>You start to pry open [src]...</span>",
				"<span class='italics'>You hear prying...</span>")
		W.play_tool_sound(src)
		if(do_after(user, 100*W.toolspeed, target = src))
			user.visible_message("<span class='warning'>[user] pries open [src], devastating the sleeper.</span>",
				"<span class='notice'>You pry open [src], devastating the sleeper..</span>",
				"<span class='italics'>You hear prying, followed by devastating of sleeper..</span>")
			log_game("[key_name(user)] has successfully pried open [src] and disabled an InteQ raider spawner.")
			W.play_tool_sound(src)
			playsound(src.loc, 'sound/effects/bamf.ogg', 50, 1, 4, 1.2)
			qdel(src)
	else
		..()

/obj/effect/mob_spawn/human/raider/special(mob/living/new_spawn)
	new_spawn.mind.add_antag_datum(/datum/antagonist/raiders)
	new_spawn.grant_language(/datum/language/old_codes, source = LANGUAGE_MIND)

/obj/effect/mob_spawn/human/raider/Destroy()
	new/obj/structure/showcase/machinery/oldpod/used(drop_location())
	return ..()

/////////////////////////////// Outfits ///////////

/datum/outfit/inteq_raider
	name = "InteQ Raider"

	uniform = /obj/item/clothing/under/inteq
	shoes = /obj/item/clothing/shoes/combat
	ears = /obj/item/radio/headset/inteq/alt
	id = /obj/item/card/id/inteq

	var/command_radio = FALSE

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/inteq_raider/vanguard
	name = "InteQ Vanguard"
	id = /obj/item/card/id/inteq/anyone
	suit = /obj/item/clothing/suit/armor/inteq/vanguard
	head = /obj/item/clothing/head/HoS/inteq_vanguard
	l_pocket = /obj/item/clothing/gloves/krav_maga/combatglovesplus
	command_radio = TRUE

/datum/outfit/inteq_raider/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_INTEQ)
	R.freqlock = TRUE
	if(command_radio)
		R.command = TRUE

	var/obj/item/implant/weapons_auth/W = new
	W.implant(H)

	var/obj/item/card/id/B = H.wear_id
	if(B)
		B.registered_name = H.real_name
		B.update_label(H.real_name)

	H.grant_language(/datum/language/old_codes, TRUE, TRUE)
	H.faction |= ROLE_INTEQ
	H.update_icons()

/datum/outfit/inteq_raider/vanguard/honorable
	name = "InteQ Honorable Vanguard"
	suit = /obj/item/clothing/suit/armor/inteq/honorable_vanguard
	head = /obj/item/clothing/head/HoS/inteq_honorable_vanguard
	uniform = /obj/item/clothing/under/inteq/honorable_vanguard
	r_hand = /obj/item/gun/ballistic/revolver/inteq
	r_pocket = /obj/item/ammo_box/a357

////// Shuttle (Krashly) ///////////

/datum/map_template/shuttle/inteq_collosus
	prefix = "_maps/shuttles/bluemoon/"
	port_id = "inteq"
	suffix = "collosus"
	name = "Collosus Shuttle"

/obj/machinery/computer/shuttle/inteq_collosus
	name = "Collosus Control"
	desc = "Used to control the Collosus."
	icon_screen = "inteqshuttle"
	icon_keyboard = "inteq_key"
	light_color = LIGHT_COLOR_ORANGE
	circuit = /obj/item/circuitboard/computer/inteq_collosus
	shuttleId = "inteq_collosus"
	possible_destinations = "syndicate_z5;syndicate_ne;syndicate_nw;syndicate_n;syndicate_se;syndicate_sw;syndicate_s;inteq_collosus_custom;pirateship_home;raiders_away"

/obj/item/circuitboard/computer/inteq_collosus
	name = "Collosus Control Console (Computer Board)"
	build_path = /obj/machinery/computer/shuttle/inteq_collosus

/obj/machinery/computer/camera_advanced/shuttle_docker/inteq_collosus
	name = "Collosus Navigation Computer"
	desc = "The Navigation console for the Collosus."
	icon_screen = "inteqshuttle"
	icon_keyboard = "inteq_key"
	shuttleId = "inteq_collosus"
	lock_override = NONE
	shuttlePortId = "inteq_collosus_custom"
	jump_to_ports = list("whiteship_away" = 1, "whiteship_home" = 1)
	view_range = 14
	x_offset = -7
	y_offset = -7

/obj/machinery/porta_turret/syndicate/energy/pirate/inteq
	max_integrity = 260
	integrity_failure = 0.08
	armor = list(MELEE = 50, BULLET = 30, LASER = 30, ENERGY = 30, BOMB = 50, BIO = 0, RAD = 0, FIRE = 90, ACID = 90)
	faction = list("InteQ")

/obj/machinery/porta_turret/syndicate/energy/pirate/inteq/assess_perp(mob/living/carbon/human/perp)
	return 10

/obj/machinery/mineral/ore_redemption/inteq
	req_access = list(ACCESS_SYNDICATE)

/datum/team/raiders/roundend_report()
	var/list/parts = list()
	var/traitor_won = TRUE

	parts += "<span class='header'>InteQ Raiders were:</span>"

	var/all_dead = TRUE
	for(var/datum/mind/M in members)
		if(considered_alive(M))
			all_dead = FALSE
	parts += printplayerlist(members)

	parts += "Loot stolen: "
	var/datum/objective/loot/L = locate() in objectives
	parts += L.loot_listing()
	parts += "Total loot value : [L.get_loot_value()]/[L.target_value] credits"

	var/objectives_text = ""
	if(objectives.len)
		var/count = 1
		for(var/datum/objective/objective in objectives)
			var/completion = objective.check_completion()
			if(completion >= 1)
				objectives_text += "<br><B>Objective #[count]</B>: [objective.explanation_text] [span_greentext("Success!")]"
			else if(completion <= 0)
				objectives_text += "<br><B>Objective #[count]</B>: [objective.explanation_text] [span_redtext("Fail.")]"
				traitor_won = FALSE
			else
				objectives_text += "<br><B>Objective #[count]</B>: [objective.explanation_text] <span class='yellowtext'>[completion*100]%</span>"

			count++

	parts += objectives_text

	if(L.check_completion() && traitor_won && !all_dead)
		parts += "<span class='greentext big'>InteQ Raiders were successful!</span>"
	else
		parts += "<span class='redtext big'>InteQ Raiders have failed.</span>"

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"
