/// Throw an immovable rod at the target
/datum/smite/rod
	name = "Immovable Rod"
	var/force_looping = FALSE
	/// Сторона света, с которой влетает стержень; null = случайная.
	var/chosen_side

/datum/smite/rod/configure(client/user)
	var/loop_input = tgui_alert(usr,"Would you like this rod to force-loop across space z-levels?", "Loopy McLoopface", list("Yes", "No"))

	force_looping = (loop_input == "Yes")

	var/list/side_choices = list(
		"Случайная сторона" = "random",
		"С севера" = "north",
		"С юга" = "south",
		"С востока" = "east",
		"С запада" = "west",
	)
	var/choice = tgui_input_list(user, "С какой стороны света будет лететь стержень?", name, side_choices)
	switch(choice)
		if("north")
			chosen_side = NORTH
		if("south")
			chosen_side = SOUTH
		if("east")
			chosen_side = EAST
		if("west")
			chosen_side = WEST

/datum/smite/rod/effect(client/user, mob/living/target)
	. = ..()
	var/turf/target_turf = get_turf(target)
	var/startside = chosen_side ? chosen_side : pick(GLOB.cardinals)
	var/turf/start_turf = spaceDebrisStartLoc(startside, target_turf.z)
	var/turf/end_turf = spaceDebrisFinishLoc(startside, target_turf.z)
	new /obj/effect/immovablerod(start_turf, end_turf, target, force_looping)
