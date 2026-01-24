GLOBAL_VAR_INIT(slavers_team_name, "Slave Traders")
GLOBAL_VAR_INIT(slavers_spawned, FALSE)
GLOBAL_VAR_INIT(slavers_credits_balance, 5000)
GLOBAL_VAR_INIT(slavers_credits_total, 0)
GLOBAL_VAR_INIT(slavers_slaves_sold, 0)

/// Price table for when trying to set slave prices automatically
GLOBAL_LIST_INIT(slavers_ransom_values, list(
	"Captain" 					= list("maxPrice" = SLAVER_RANSOM_HEAD_VALUABLE, "percent" = 0.9),
	"NanoTrasen Representative" = list("maxPrice" = SLAVER_RANSOM_HEAD_VALUABLE, "percent" = 0.9),
	"Head of Security" 			= list("maxPrice" = SLAVER_RANSOM_HEAD_VALUABLE/2, "percent" = 0.5),
	"Head of Personnel" 		= list("maxPrice" = SLAVER_RANSOM_HEAD, "percent" = 0.25),
	"Chief Engineer" 			= list("maxPrice" = SLAVER_RANSOM_HEAD, "percent" = 0.25),
	"Research Director" 		= list("maxPrice" = SLAVER_RANSOM_HEAD, "percent" = 0.25),
	"Chief Medical Officer" 	= list("maxPrice" = SLAVER_RANSOM_HEAD, "percent" = 0.25),
	"Quartermaster" 			= list("maxPrice" = SLAVER_RANSOM_HEAD, "percent" = 0.25),
	"Blueshield" 				= list("maxPrice" = SLAVER_RANSOM_VALUABLE, "percent" = 0.15),
	"Bridge Officer" 			= list("maxPrice" = SLAVER_RANSOM_VALUABLE, "percent" = 0.15),
	"Warden" 					= list("maxPrice" = SLAVER_RANSOM_VALUABLE, "percent" = 0.15),
	"Brig Physician" 			= list("maxPrice" = SLAVER_RANSOM_VALUABLE, "percent" = 0.1),
	"Security Officer" 			= list("maxPrice" = SLAVER_RANSOM_VALUABLE, "percent" = 0.1),
	"Peacekeeper" 				= list("maxPrice" = SLAVER_RANSOM_VALUABLE, "percent" = 0.1),
	"Detective" 				= list("maxPrice" = SLAVER_RANSOM_VALUABLE, "percent" = 0.1),
	"Internal Affairs Agent"	= list("maxPrice" = SLAVER_RANSOM_VALUABLE, "percent" = 0.1),
	"Stowaway"					= list("maxPrice" = 500, "percent" = 0.01),
	"Other" 					= list("maxPrice" = SLAVER_RANSOM_STANDARD, "percent" = SLAVER_RANSOM_STANDARD_PERCENT), // Для прайс листа в консоли
))

/datum/antagonist/slaver
	name = "Slave Trader"
	roundend_category = "slaver"
	antagpanel_category = "Slaver"
	job_rank = ROLE_SLAVER
	antag_moodlet = /datum/mood_event/focused
	threat = 7
	show_to_ghosts = TRUE
	var/static/datum/team/slavers/slaver_team = new /datum/team/slavers
	var/slaver_outfit = /datum/outfit/slaver
	var/send_to_spawnpoint = TRUE //Should the user be moved to default spawnpoint.
	var/equip_outfit = TRUE

/datum/antagonist/slaver/proc/update_slaver_icons_added(mob/living/M)
	var/datum/atom_hud/antag/slaverhud = GLOB.huds[ANTAG_HUD_SLAVER]
	slaverhud.join_hud(M)
	set_antag_hud(M, "slaver")

/datum/antagonist/slaver/proc/update_slaver_icons_removed(mob/living/M)
	var/datum/atom_hud/antag/slaverhud = GLOB.huds[ANTAG_HUD_SLAVER]
	slaverhud.leave_hud(M)
	set_antag_hud(M, null)

/datum/antagonist/slaver/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_slaver_icons_added(M)

/datum/antagonist/slaver/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_slaver_icons_removed(M)

/datum/antagonist/slaver/proc/equip_slaver()
	if(!ishuman(owner.current))
		return
	var/mob/living/carbon/human/H = owner.current

	H.equipOutfit(slaver_outfit)
	return TRUE

/datum/antagonist/slaver/greet()
	owner.assigned_role = ROLE_SLAVER
	owner.current.playsound_local(get_turf(owner.current), 'modular_splurt/sound/ambience/antag/slavers.ogg',100,0)
	to_chat(owner, "<B>You are a Slave Trader!</B>")

	var/mob/living/carbon/human/H = owner.current
	if(istype(H))
		H.set_antag_target_indicator() // Hide consent of this player, they are an antag and can't be a target

/datum/antagonist/slaver/on_gain()
	forge_objectives()
	. = ..()
	if(equip_outfit)
		equip_slaver()
	if(send_to_spawnpoint)
		move_to_spawnpoint()

	// Can see what players consent to being a victim
	var/datum/atom_hud/H = GLOB.huds[DATA_HUD_ANTAGTARGET]
	H.add_hud_to(owner.current)

// Lose antag status
/datum/antagonist/slaver/farewell()
	// Can no longer see what players consent to being a victim
	var/datum/atom_hud/H = GLOB.huds[DATA_HUD_ANTAGTARGET]
	H.remove_hud_from(owner.current)

/datum/antagonist/slaver/get_team()
	return slaver_team

/datum/antagonist/slaver/proc/forge_objectives()
	objectives |= slaver_team.objectives

/datum/antagonist/slaver/proc/move_to_spawnpoint()
	owner.current.forceMove(GLOB.slaver_start[(0 % GLOB.slaver_start.len) + 1])

/datum/antagonist/slaver/leader/move_to_spawnpoint()
	owner.current.forceMove(pick(GLOB.slaver_leader_start))

/datum/antagonist/slaver/admin_add(datum/mind/new_owner,mob/admin)
	send_to_spawnpoint = FALSE
	new_owner.add_antag_datum(src)

	message_admins("[key_name_admin(admin)] has slaver'd [new_owner.current].")
	log_admin("[key_name(admin)] has slaver'd [new_owner.current].")

/datum/antagonist/slaver/admin_remove(mob/user)
	var/datum/mind/player = owner
	. = ..()
	var/mob/living/carbon/human/H = player.current
	if(istype(H))
		H.set_antag_target_indicator() // Update consent HUD

/datum/antagonist/slaver/get_admin_commands()
	. = ..()
	.["Send to base"] = CALLBACK(src,PROC_REF(admin_send_to_base))

/datum/antagonist/slaver/proc/admin_send_to_base(mob/admin)
	owner.current.forceMove(pick(GLOB.slaver_start))

/datum/antagonist/slaver/leader
	name = "Slave Master"
	slaver_outfit = /datum/outfit/slaver/leader

/datum/antagonist/slaver/leader/greet()
	owner.assigned_role = ROLE_SLAVER_LEADER
	owner.current.playsound_local(get_turf(owner.current), 'modular_splurt/sound/ambience/antag/slavers.ogg',100,0)

	var/mob/living/carbon/human/H = owner.current
	if(istype(H))
		H.set_antag_target_indicator() // Hide consent of this player, they are an antag and can't be a target

	addtimer(CALLBACK(src, PROC_REF(slavers_name_assign)), 1)

/datum/antagonist/slaver/leader/proc/slavers_name_assign()
	GLOB.slavers_team_name = ask_name()

/datum/antagonist/slaver/leader/proc/ask_name()
	var/defaultname = GLOB.slavers_team_name
	var/newname = stripped_input(owner.current, "You are the slave master. Please choose a name for your crew.", "Crew name", defaultname)
	if (!newname)
		newname = defaultname
	else
		newname = reject_bad_name(newname)
		if(!newname)
			newname = defaultname

	return capitalize(newname)

/datum/team/slavers
	var/core_objective = /datum/objective/slaver

/datum/team/slavers/proc/update_objectives()
	if(core_objective)
		var/datum/objective/O = new core_objective
		O.team = src
		objectives += O

/datum/team/slavers/roundend_report()
	var/list/parts = list()
	parts += "<span class='header'>Slave Traders:</span>"

	var/text = "<br><span class='header'>The crew were:</span>"
	var/slavesSold = GLOB.slavers_slaves_sold
	var/earnedMoney = GLOB.slavers_credits_total
	var/slavesUnsold = 0

	var/all_dead = TRUE
	for(var/datum/mind/M in members)
		if(considered_alive(M))
			all_dead = FALSE

	for(var/obj/item/electropack/shockcollar/slave/collar in GLOB.tracked_slaves)
		if (isliving(collar.loc))
			slavesUnsold++

	text += "<br>"
	text += printplayerlist(members)
	text += "<br>"
	text += "<b>Slaves sold:</b> [slavesSold]<br>"
	text += "<b>Slaves not sold:</b> [slavesUnsold]<br>"
	text += "<b>Total money earned:</b> [earnedMoney]cr (needed at least 200,000cr)"

	// var/datum/objective/slaver/O = locate() in objectives
	if(GLOB.slavers_credits_total >= 200000 && !all_dead)
		parts += "<span class='greentext'>The slaver crew were successful!</span>"
	else
		parts += "<span class='redtext'>The slaver crew have failed.</span>"

	parts += text

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/proc/is_slaver(mob/M)
	return M && istype(M) && M.mind && M.mind.has_antag_datum(/datum/antagonist/slaver)

/obj/item/clothing/glasses/hud/slaver
	name = "Raper Sunglasses"
	desc = "Солнцезащитные очки тёмного цвета, дающие способность увидеть, желает ли член экипажа подвергнуться сексуальному насилию."
	icon_state = "bigsunglasses"
	hud_type = DATA_HUD_ANTAGTARGET
