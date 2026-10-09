/datum/antagonist/vox_scavengers
	name = "Vox Scavenger"
	job_rank = ROLE_TRAITOR
	roundend_category = "vox scavengers"
	antagpanel_category = "Vox"
	threat = 12
	show_to_ghosts = TRUE
	var/datum/team/vox_scavengers/crew

/datum/antagonist/vox_scavengers/greet()
	SEND_SOUND(owner.current, sound('modular_bluemoon/kovac_shitcode/sound/vox_spawn.ogg'))
	to_chat(owner, "<span class='boldannounce'>Вы - вокс-налётчик!</span>")
	to_chat(owner, "<B>Вам необходимо обокрасть станцию и выполнить свои цели. Вы можете как представиться торговцами, так и действовать скрытно и нелегально. Не начинайте конфликтов первыми и избегайте их: ваша философия не допускает напрасной потери жизней с обеих сторон. Кроме того, никто из воксов не должен оказаться за бортом.</B>")
	owner.announce_objectives()

/datum/antagonist/vox_scavengers/get_team()
	return crew

/datum/antagonist/vox_scavengers/create_team(datum/team/vox_scavengers/new_team)
	if(!new_team)
		for(var/datum/antagonist/vox_scavengers/P in GLOB.antagonists)
			if(!P.owner)
				continue
			if(P.crew)
				crew = P.crew
				return
		if(!new_team)
			crew = new /datum/team/vox_scavengers
			crew.forge_objectives()
			return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	crew = new_team

/datum/team/vox_scavengers/proc/forge_objectives()
	var/datum/objective/loot/getbooty = new()
	var/datum/objective/heist/heist_objective = new
	var/datum/objective/kidnap/kidnap_objective = new

	getbooty.team = src
	for(var/obj/machinery/computer/piratepad_control/P in GLOB.machines)
		var/area/A = get_area(P)
		if(istype(A,/area/shuttle/vox_raiders))
			getbooty.cargo_hold = P
			break
	getbooty.update_explanation_text()
	objectives += getbooty
	for(var/datum/mind/M in members)
		var/datum/antagonist/vox_scavengers/P = M.has_antag_datum(/datum/antagonist/vox_scavengers)
		if(P)
			P.objectives |= objectives

	heist_objective.team = src
	heist_objective.find_target()
	objectives += heist_objective


	if(prob(45))
		kidnap_objective.team = src
		if(kidnap_objective.find_target())
			objectives += kidnap_objective
		else
			qdel(kidnap_objective)

	return

/datum/antagonist/vox_scavengers/on_gain()
	if(crew)
		objectives |= crew.objectives
	. = ..()

/datum/team/vox_scavengers
	name = "Vox Scavengers"

/////// Sleepers and Outfits ////

/obj/structure/showcase/machinery/oldpod/used/oldpod
	icon_state = "oldpod-open"

/obj/effect/mob_spawn/human/vox_scavenger
	name = "Vox Sleeper"
	desc = "A cryo-sleep cell made with unknown materials."
	job_description = "Vox Scavenger"
	random = TRUE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "oldpod"
	mob_name = "a vox scavenger"
	mob_species = /datum/species/mammal/vox
	outfit = /datum/outfit/vox_scavenger
	roundstart = FALSE
	death = FALSE
	anchored = TRUE
	density = FALSE
	show_flavour = FALSE //Flavour only exists for spawners menu
	short_desc = "You are a Vox Scavenger."
	flavour_text = "Самое время поживиться чем-то полезным на просторах космической станции. Не начинайте конфликтов первыми и избегайте их: ваша философия не допускает напрасной потери жизней с обеих сторон. Кроме того, никто из воксов не должен оказаться за бортом."
	assignedrole = "Vox Scavenger"
	category = "midround"

/obj/effect/mob_spawn/human/vox_scavenger/special(mob/living/new_spawn)
	new_spawn.fully_replace_character_name(new_spawn.real_name,generate_scavenger_name())
	new_spawn.mind.add_antag_datum(/datum/antagonist/vox_scavengers)
	new_spawn.set_bark("lizard")

/datum/outfit/vox_scavenger
	name = "Vox Scavenger"

	uniform = /obj/item/clothing/under/syndicate
	shoes = /obj/item/clothing/shoes/jackboots/toeless
	//r_pocket = /obj/item/clothing/glasses/hud/security/sunglasses/inteq
	//gloves = /obj/item/clothing/gloves/combat
	//back = /obj/item/storage/backpack
	ears = /obj/item/radio/headset/pirate
	id = /obj/item/card/id/syndicate/vox_scavenger
	//belt = /obj/item/gun/ballistic/automatic/pistol
	//backpack_contents = list(/obj/item/storage/box/survival/syndie=1,
	//obj/item/kitchen/knife/combat/survival)


/datum/outfit/vox_scavenger/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	H.faction |= "Vox"

	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_PIRATE)
	R.freqlock = TRUE

	var/obj/item/implant/weapons_auth/W = new
	W.implant(H)

	var/obj/item/card/id/B = H.wear_id
	if(B)
		B.registered_name = H.real_name
		B.update_label(H.real_name)

	H.update_icons()

	H.left_eye_color = "00ffff"
	H.right_eye_color = "00ffff"

/obj/effect/mob_spawn/human/vox_scavenger/proc/generate_scavenger_name()
	return "[pick(GLOB.vox_names)]"

///obj/effect/mob_spawn/human/vox_scavenger/Destroy()
	//new/obj/structure/showcase/machinery/oldpod/used/oldpod(drop_location())
	//return ..()

////// Shuttle (Krashly again) ///////////

/datum/map_template/shuttle/vox_raiders
	prefix = "_maps/shuttles/bluemoon/"
	port_id = "vox"
	suffix = "skipjack"
	name = "Skipjack Shuttle"

/obj/machinery/computer/shuttle/vox_raiders
	name = "Skipjack Control"
	desc = "Used to control the Skipjack."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	light_color = LIGHT_COLOR_RED
	circuit = /obj/item/circuitboard/computer/vox_raiders
	shuttleId = "vox_raiders"
	possible_destinations = "vox_raiders_custom"

/obj/item/circuitboard/computer/vox_raiders
	name = "Skipjack Control Console (Computer Board)"
	build_path = /obj/machinery/computer/shuttle/vox_raiders

/obj/machinery/computer/camera_advanced/shuttle_docker/vox_raiders
	name = "Skipjack Navigation Computer"
	desc = "The Navigation console for the Skipjack."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	shuttleId = "vox_raiders"
	lock_override = NONE
	shuttlePortId = "vox_raiders_custom"
	jump_to_ports = list("whiteship_away" = 1, "whiteship_home" = 1)
	view_range = 7
	x_offset = 0
	y_offset = 0

/area/shuttle/vox_raiders
	name = "Skipjack Ship"

///////////////////////////////////////////////////////////////

/datum/team/vox_scavengers/roundend_report()
	var/list/parts = list()
	var/traitor_won = TRUE
	var/all_safe  = TRUE

	parts += "<span class='header'>Vox Scavengers were:</span>"

	parts += printplayerlist(members)

/////////////////////////////////// Отметка для Смайли. Не проходит проверка, all_safe всегда остается на значении TRUE, заданном выше.

	for(var/datum/antagonist/vox_scavengers/M in members) // Проверяем наличие всей команды в пределах зоны шаттла.
		if(!M.owner.current)
			all_safe = FALSE
		var/list/area/skipjack = list((/area/shuttle/vox_raiders))
		if(!is_type_in_list(get_area(M.owner.current), skipjack))
			all_safe = FALSE

///////////////////////////////////////////////////

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

	if(L.check_completion() && traitor_won)
		parts += "<span class='greentext big'>Vox Scavengers were successful!</span>"
	//else if(!all_safe)
		//parts += "<span class='redtext big'>The crew had left someone behind! Vox Scavengers have failed.</span>"
	else
		parts += "<span class='redtext big'>Vox Scavengers have failed.</span>"

	if(!all_safe)
		parts += "<span class='redtext big'>The crew had left someone behind!</span>"

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"
