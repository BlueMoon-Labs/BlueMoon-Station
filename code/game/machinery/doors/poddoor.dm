/obj/machinery/door/poddoor
	name = "blast door"
	desc = "A heavy duty blast door that opens mechanically."
	icon = 'icons/obj/doors/blastdoor.dmi'
	icon_state = "closed"
	var/id = 1
	layer = BLASTDOOR_LAYER
	closingLayer = CLOSED_BLASTDOOR_LAYER
	sub_door = TRUE
	explosion_block = 3
	wave_explosion_block = EXPLOSION_BLOCK_BLAST_PROOF
	wave_explosion_multiply = EXPLOSION_DAMPEN_BLAST_PROOF
	heat_proof = TRUE
	safe = FALSE
	max_integrity = 600
	armor = list(MELEE = 50, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 70)
	resistance_flags = FIRE_PROOF
	damage_deflection = 70
	can_open_with_hands = FALSE
	poddoor = TRUE
	var/datum/crafting_recipe/recipe_type = /datum/crafting_recipe/blast_doors
	var/deconstruction = BLASTDOOR_FINISHED // deconstruction step

/obj/machinery/door/poddoor/Initialize(mapload)
	. = ..()
	register_context()

/obj/machinery/door/poddoor/examine(mob/user)
	. = ..()
	if(panel_open)
		if(deconstruction == BLASTDOOR_FINISHED)
			. += span_notice("The maintenance panel is opened and the electronics could be <b>pried</b> out.")
			. += span_notice("\The [src] could be calibrated to a blast door controller ID with a <b>multitool</b> or a <b>blast door controller</b>.")
		else if(deconstruction == BLASTDOOR_NEEDS_ELECTRONICS)
			. += span_notice("The <i>electronics</i> are missing and there are some <b>wires</b> sticking out.")
		else if(deconstruction == BLASTDOOR_NEEDS_WIRES)
			. += span_notice("The <i>wires</i> have been removed and it's ready to be <b>sliced apart</b>.")

/obj/machinery/door/poddoor/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	if(isnull(held_item))
		return NONE
	if(deconstruction == BLASTDOOR_NEEDS_WIRES && istype(held_item, /obj/item/stack/cable_coil))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Wire assembly")
		return CONTEXTUAL_SCREENTIP_SET
	if(deconstruction == BLASTDOOR_NEEDS_ELECTRONICS && istype(held_item, /obj/item/electronics/airlock))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Add electronics")
		return CONTEXTUAL_SCREENTIP_SET
	if(deconstruction == BLASTDOOR_FINISHED && istype(held_item, /obj/item/assembly/control))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Calibrate ID")
		return CONTEXTUAL_SCREENTIP_SET
	//we do not check for special effects like if they can actually perform the action because they will be told they can't do it when they try,
	//with feedback on what they have to do in order to do so.
	switch(held_item.tool_behaviour)
		if(TOOL_SCREWDRIVER)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Open panel")
			return CONTEXTUAL_SCREENTIP_SET
		if(TOOL_MULTITOOL)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Calibrate ID")
			return CONTEXTUAL_SCREENTIP_SET
		if(TOOL_CROWBAR)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Remove electronics")
			return CONTEXTUAL_SCREENTIP_SET
		if(TOOL_WIRECUTTER)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Remove wires")
			return CONTEXTUAL_SCREENTIP_SET
		if(TOOL_WELDER)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Disassemble")
			return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/door/poddoor/attackby(obj/item/I, mob/user, params)
	if(deconstruction == BLASTDOOR_NEEDS_WIRES && istype(I, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/coil = I
		var/datum/crafting_recipe/recipe = locate(recipe_type) in GLOB.crafting_recipes
		var/amount_needed = recipe.reqs[/obj/item/stack/cable_coil]
		if(coil.get_amount() < amount_needed)
			balloon_alert(user, "not enough cable!")
			return
		balloon_alert(user, "adding cables...")
		if(!do_after(user, 5 SECONDS, src))
			return
		coil.use(amount_needed)
		deconstruction = BLASTDOOR_NEEDS_ELECTRONICS
		balloon_alert(user, "cables added")
		return
	if(deconstruction == BLASTDOOR_NEEDS_ELECTRONICS && istype(I, /obj/item/electronics/airlock))
		balloon_alert(user, "adding electronics...")
		if(!do_after(user, 10 SECONDS, src))
			return
		qdel(I)
		balloon_alert(user, "electronics added")
		deconstruction = BLASTDOOR_FINISHED
		return
	if(deconstruction == BLASTDOOR_FINISHED && istype(I, /obj/item/assembly/control))
		if(density)
			balloon_alert(user, "open the door first!")
			return
		if(!panel_open)
			balloon_alert(user, "open the panel first!")
			return
		var/obj/item/assembly/control/controller_item = I
		id = controller_item.id
		balloon_alert(user, "id changed")
		return
	return ..()

/obj/machinery/door/poddoor/screwdriver_act(mob/living/user, obj/item/tool)
	. = ..()
	if (density)
		balloon_alert(user, "open the door first!")
		return TOOL_ACT_TOOLTYPE_SUCCESS
	else if (default_deconstruction_screwdriver(user, icon_state, icon_state, tool))
		return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/door/poddoor/multitool_act(mob/living/user, obj/item/tool)
	. = ..()
	if (density)
		balloon_alert(user, "open the door first!")
		return TOOL_ACT_TOOLTYPE_SUCCESS
	if (!panel_open)
		balloon_alert(user, "open the panel first!")
		return
	if (deconstruction != BLASTDOOR_FINISHED)
		return
	var/change_id = tgui_input_number(user, "Set the door controllers ID (Current: [id])", "Door Controller ID", isnum(id) ? id : null, 100)
	if(!change_id || QDELETED(usr) || QDELETED(src) || !usr.canUseTopic(src, be_close = TRUE, no_dextery = FALSE, no_tk = TRUE))
		return
	id = change_id
	to_chat(user, span_notice("You change the ID to [id]."))
	balloon_alert(user, "id changed")
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/door/poddoor/crowbar_act(mob/living/user, obj/item/tool)
	. = ..()
	if(machine_stat & NOPOWER)
		open(TRUE)
		return TOOL_ACT_TOOLTYPE_SUCCESS
	if (density)
		balloon_alert(user, "open the door first!")
		return TOOL_ACT_TOOLTYPE_SUCCESS
	if (!panel_open)
		balloon_alert(user, "open the panel first!")
		return
	if (deconstruction != BLASTDOOR_FINISHED)
		return
	balloon_alert(user, "removing airlock electronics...")
	if(tool.use_tool(src, user, 10 SECONDS, volume = 50))
		new /obj/item/electronics/airlock(loc)
		id = null
		deconstruction = BLASTDOOR_NEEDS_ELECTRONICS
		balloon_alert(user, "removed airlock electronics")
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/door/poddoor/wirecutter_act(mob/living/user, obj/item/tool)
	. = ..()
	if (density)
		balloon_alert(user, "open the door first!")
		return TOOL_ACT_TOOLTYPE_SUCCESS
	if (!panel_open)
		balloon_alert(user, "open the panel first!")
		return
	if (deconstruction != BLASTDOOR_NEEDS_ELECTRONICS)
		return
	balloon_alert(user, "removing internal cables...")
	if(tool.use_tool(src, user, 10 SECONDS, volume = 50))
		var/datum/crafting_recipe/recipe = locate(recipe_type) in GLOB.crafting_recipes
		var/amount = recipe.reqs[/obj/item/stack/cable_coil]
		new /obj/item/stack/cable_coil(loc, amount)
		deconstruction = BLASTDOOR_NEEDS_WIRES
		balloon_alert(user, "removed internal cables")
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/door/poddoor/welder_act(mob/living/user, obj/item/tool)
	. = ..()
	if (density)
		balloon_alert(user, "open the door first!")
		return TOOL_ACT_TOOLTYPE_SUCCESS
	if (!panel_open)
		balloon_alert(user, "open the panel first!")
		return
	if (deconstruction != BLASTDOOR_NEEDS_WIRES)
		return
	balloon_alert(user, "tearing apart...") //You're tearing me apart, Lisa!
	if(tool.use_tool(src, user, 15 SECONDS, volume = 50))
		var/datum/crafting_recipe/recipe = locate(recipe_type) in GLOB.crafting_recipes
		var/amount = recipe.reqs[/obj/item/stack/sheet/plasteel]
		new /obj/item/stack/sheet/plasteel(loc, amount)
		user.balloon_alert(user, "torn apart")
		qdel(src)
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/door/poddoor/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock, idnum, override=FALSE)
	id = "[idnum][id]"

/obj/machinery/door/poddoor/preopen
	icon_state = "open"
	density = FALSE
	opacity = 0

/obj/machinery/door/poddoor/ert
	desc = "A heavy duty blast door that only opens for dire emergencies."

//special poddoors that open when emergency shuttle docks at centcom
/obj/machinery/door/poddoor/shuttledock
	var/checkdir = 4	//door won't open if turf in this dir is `turftype`
	var/turftype = /turf/open/space

/obj/machinery/door/poddoor/shuttledock/proc/check()
	var/turf/T = get_step(src, checkdir)
	if(!istype(T, turftype))
		INVOKE_ASYNC(src, PROC_REF(open))
	else
		INVOKE_ASYNC(src, PROC_REF(close))

/obj/machinery/door/poddoor/incinerator_toxmix
	name = "combustion chamber vent"
	id = INCINERATOR_TOXMIX_VENT

/obj/machinery/door/poddoor/incinerator_atmos_main
	name = "turbine vent"
	id = INCINERATOR_ATMOS_MAINVENT

/obj/machinery/door/poddoor/incinerator_atmos_aux
	name = "combustion chamber vent"
	id = INCINERATOR_ATMOS_AUXVENT

/obj/machinery/door/poddoor/incinerator_syndicatelava_main
	name = "turbine vent"
	id = INCINERATOR_SYNDICATELAVA_MAINVENT

/obj/machinery/door/poddoor/incinerator_syndicatelava_aux
	name = "combustion chamber vent"
	id = INCINERATOR_SYNDICATELAVA_AUXVENT

/obj/machinery/door/poddoor/Bumped(atom/movable/AM)
	if(density)
		return FALSE
	else
		return ..()

//"BLAST" doors are obviously stronger than regular doors when it comes to BLASTS.
/obj/machinery/door/poddoor/ex_act(severity, target, origin)
	if(severity == 3)
		return
	..()

/obj/machinery/door/poddoor/do_animate(animation)
	switch(animation)
		if("opening")
			flick("opening", src)
			playsound(src, 'sound/machines/blastdoor.ogg', 30, 1)
		if("closing")
			flick("closing", src)
			playsound(src, 'sound/machines/blastdoor.ogg', 30, 1)

/obj/machinery/door/poddoor/update_icon_state()
	if(density)
		icon_state = "closed"
	else
		icon_state = "open"

/obj/machinery/door/poddoor/try_to_activate_door(mob/user, access_bypass = FALSE)
	return

/obj/machinery/door/poddoor/try_to_crowbar(obj/item/I, mob/user)
	if(machine_stat & NOPOWER)
		open(1)
