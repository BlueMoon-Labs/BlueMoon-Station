/* This file contains standalone items for debug purposes. */

/obj/item/debug/human_spawner
	name = "human spawner"
	desc = "Spawn a human by aiming at a turf and clicking. Use in hand to change type."
	icon = 'icons/obj/guns/magic.dmi'
	icon_state = "nothingwand"
	item_state = "wand"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/datum/species/selected_species
	var/valid_species = list()

/obj/item/debug/human_spawner/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(isturf(target))
		var/mob/living/carbon/human/H = new /mob/living/carbon/human(target)
		if(selected_species)
			H.set_species(selected_species)

/obj/item/debug/human_spawner/attack_self(mob/user)
	. = ..()
	var/choice = tgui_input_list(user, "Select a species", "Human Spawner", GLOB.species_list)
	selected_species = GLOB.species_list[choice]

// Revive this once we purge all the istype checks for tools for tool_behaviour
/obj/item/debug/omnitool
	name = "omnitool"
	desc = "The original hypertool, born before them all. Use it in hand to unleash it's true power."
	icon = 'icons/obj/device.dmi'
	icon_state = "hypertool"
	item_state = "hypertool"
	toolspeed = 0.1
	tool_behaviour = null

/obj/item/debug/omnitool/examine()
	. = ..()
	. += " The mode is: [tool_behaviour]"

/obj/item/debug/omnitool/proc/check_menu(mob/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/debug/omnitool/attack_self(mob/user)
	if(!user)
		return
	var/list/tool_list = list(
		"Crowbar" = image(icon = 'icons/obj/tools.dmi', icon_state = "crowbar"),
		"Multitool" = image(icon = 'icons/obj/device.dmi', icon_state = "multitool"),
		"Screwdriver" = image(icon = 'icons/obj/tools.dmi', icon_state = "screwdriver_map"),
		"Wirecutters" = image(icon = 'icons/obj/tools.dmi', icon_state = "cutters_map"),
		"Wrench" = image(icon = 'icons/obj/tools.dmi', icon_state = "wrench"),
		"Welding Tool" = image(icon = 'icons/obj/tools.dmi', icon_state = "miniwelder"),
		"Analyzer" = image(icon = 'icons/obj/device.dmi', icon_state = "analyzer"),
		"Mining Tool" = image(icon = 'icons/obj/mining.dmi', icon_state = "minipick"),
		"Shovel" = image(icon = 'icons/obj/mining.dmi', icon_state = "spade"),
		"Retractor" = image(icon = 'icons/obj/surgery.dmi', icon_state = "retractor"),
		"Hemostat" = image(icon = 'icons/obj/surgery.dmi', icon_state = "hemostat"),
		"Cautery" = image(icon = 'icons/obj/surgery.dmi', icon_state = "cautery"),
		"Drill" = image(icon = 'icons/obj/surgery.dmi', icon_state = "drill"),
		"Scalpel" = image(icon = 'icons/obj/surgery.dmi', icon_state = "scalpel"),
		"Saw" = image(icon = 'icons/obj/surgery.dmi', icon_state = "saw"),
		"Blood filter" = image(icon = 'icons/obj/surgery.dmi', icon_state = "bloodfilter")
		)
	var/tool_result = show_radial_menu(user, src, tool_list, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(tool_result)
		if("Crowbar")
			tool_behaviour = TOOL_CROWBAR
		if("Multitool")
			tool_behaviour = TOOL_MULTITOOL
		if("Screwdriver")
			tool_behaviour = TOOL_SCREWDRIVER
		if("Wirecutters")
			tool_behaviour = TOOL_WIRECUTTER
		if("Wrench")
			tool_behaviour = TOOL_WRENCH
		if("Welding Tool")
			tool_behaviour = TOOL_WELDER
		if("Analyzer")
			tool_behaviour = TOOL_ANALYZER
		if("Mining Tool")
			tool_behaviour = TOOL_MINING
		if("Shovel")
			tool_behaviour = TOOL_SHOVEL
		if("Retractor")
			tool_behaviour = TOOL_RETRACTOR
		if("Hemostat")
			tool_behaviour = TOOL_HEMOSTAT
		if("Cautery")
			tool_behaviour = TOOL_CAUTERY
		if("Drill")
			tool_behaviour = TOOL_DRILL
		if("Scalpel")
			tool_behaviour = TOOL_SCALPEL
		if("Blood filter")
			tool_behaviour = TOOL_BLOODFILTER
		if("Saw")
			tool_behaviour = TOOL_SAW

#define ERASER_MODE_MOB "mob"
#define ERASER_MODE_OBJ "obj_item"
#define ERASER_MODE_TURF "turf"
#define ERASER_MODE_ALL "all"

/obj/item/debug/eraser
	name = "eraser"
	desc = "Erases things from reality."
	icon = 'icons/obj/guns/magic.dmi'
	icon_state = "arcanewand"
	item_state = "wand"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/mode = ERASER_MODE_MOB
	var/static/list/mode_desc = list(
		ERASER_MODE_MOB = "mobs",
		ERASER_MODE_OBJ = "items and objects",
		ERASER_MODE_TURF = "turfs",
		ERASER_MODE_ALL = "all",
	)
	var/punish_process = FALSE

/obj/item/debug/eraser/examine(mob/user)
	. = ..()
	. += span_notice("<b>Erasing mode: [mode_desc[mode]].</b>")

/obj/item/debug/eraser/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!user.client?.holder)
		if(punish_process)
			return
		to_chat(user, span_userdanger("У ТЕБЯ НЕТ МОГУЩЕСТВА!"))
		punish_process = TRUE
		lightningbolt(user)
		punish_process = FALSE
		return
	if(user == target)
		to_chat(user, span_warning("Ты правда хотел стереть себя?"))
		return
	if(istype(target, /atom/movable/screen))
		return
	if(mode == ERASER_MODE_MOB && !ismob(target))
		return
	if(mode == ERASER_MODE_OBJ && !isobj(target))
		return
	if(mode == ERASER_MODE_TURF && (!isturf(target) || isspaceturf(target)))
		return

	var/atom/A = target
	var/coords = ""
	var/jmp_coords = ""
	if(istype(A))
		var/turf/T = get_turf(A)
		if(T)
			coords = "at [COORD(T)]"
			jmp_coords = "at [ADMIN_COORDJMP(T)]"
		else
			jmp_coords = coords = "in nullspace"

	playsound(user, 'sound/magic/wandodeath.ogg', 50, 1)

	log_admin("[key_name(user)] deleted [target] [coords] with [src]")
	message_admins("[key_name_admin(user)] deleted [target] [jmp_coords] with [src]")
	SSblackbox.record_feedback("tally", "eraser", 1, "Delete")  //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	if(isturf(target))
		var/turf/T = target
		T.ScrapeAway()
	else
		qdel(target)

/obj/item/debug/eraser/attack_self(mob/user)
	. = ..()
	switch(mode)
		if(ERASER_MODE_MOB)
			mode = ERASER_MODE_OBJ
		if(ERASER_MODE_OBJ)
			mode = ERASER_MODE_TURF
		if(ERASER_MODE_TURF)
			mode = ERASER_MODE_ALL
		else
			mode = ERASER_MODE_MOB
	user.balloon_alert(user, "Now erase only: [mode_desc[mode]]")

#undef ERASER_MODE_MOB
#undef ERASER_MODE_OBJ
#undef ERASER_MODE_TURF
#undef ERASER_MODE_ALL
