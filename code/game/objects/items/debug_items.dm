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
	var/mass_mode = FALSE

/obj/item/debug/eraser/examine(mob/user)
	. = ..()
	. += span_notice("<b>Erasing mode: [mode_desc[mode]].</b>")
	. += span_notice("<b>Mass erase mode is [mass_mode ? "ON" : "OFF"]</b>")

/obj/item/debug/eraser/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!rights_check(user))
		return
	var/list/list_to_erase = list()
	if(mass_mode)
		var/turf/T = get_turf(target)
		if(T)
			list_to_erase += T.contents
			list_to_erase += T
	list_to_erase |= target
	var/succes_erase = FALSE
	for(var/atom/to_erase as anything in list_to_erase)
		if(user == to_erase)
			to_chat(user, span_warning("Ты правда хотел стереть себя?"))
			continue
		if(istype(to_erase, /atom/movable/screen))
			continue
		if(mode == ERASER_MODE_MOB && !ismob(to_erase))
			continue
		if(mode == ERASER_MODE_OBJ && !isobj(to_erase))
			continue
		if(mode == ERASER_MODE_TURF && (!isturf(to_erase) || isspaceturf(to_erase)))
			continue

		succes_erase = TRUE

		var/atom/A = to_erase
		var/coords = ""
		if(istype(A))
			var/turf/T = get_turf(A)
			if(T)
				coords = "at [COORD(T)]"

		log_admin("[key_name(user)] deleted [to_erase] [coords] with [src]")
		if(isturf(to_erase))
			var/turf/T = to_erase
			T.ScrapeAway()
		else
			qdel(to_erase)
	if(succes_erase)
		playsound(user, 'sound/magic/wandodeath.ogg', 35, TRUE)

/obj/item/debug/eraser/attack_self(mob/user)
	. = ..()
	if(!rights_check(user))
		return
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

/obj/item/debug/eraser/AltClick(mob/user)
	. = ..()
	if(!rights_check(user) || !Adjacent(user))
		return
	mass_mode = !mass_mode
	user.balloon_alert(user, "Mass erase: [mass_mode ? "ON" : "OFF"]")

/obj/item/debug/eraser/proc/rights_check(mob/user)
	if(!user.client?.holder)
		if(punish_process)
			return FALSE
		to_chat(user, span_userdanger("У ТЕБЯ НЕТ МОГУЩЕСТВА!"))
		punish_process = TRUE
		lightningbolt(user)
		punish_process = FALSE
		return FALSE
	return TRUE

#undef ERASER_MODE_MOB
#undef ERASER_MODE_OBJ
#undef ERASER_MODE_TURF
#undef ERASER_MODE_ALL
