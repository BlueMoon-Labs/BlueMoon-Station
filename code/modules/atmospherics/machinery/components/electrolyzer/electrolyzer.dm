#define ELECTROLYZER_MODE_STANDBY "standby"
#define ELECTROLYZER_MODE_WORKING "working"

/obj/machinery/electrolyzer
	anchored = FALSE
	density = TRUE
	interaction_flags_machine = INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN
	icon = 'icons/obj/pipes_n_cables/atmos.dmi'
	icon_state = "electrolyzer-off"
	name = "space electrolyzer"
	desc = "Thanks to the fast and dynamic response of our electrolyzers, on-site hydrogen production is guaranteed. Warranty void if used by clowns."
	max_integrity = 250
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 80, ACID = 10)
	circuit = /obj/item/circuitboard/machine/electrolyzer
	use_power = NO_POWER_USE
	var/obj/item/stock_parts/cell/cell
	var/on = FALSE
	var/mode = ELECTROLYZER_MODE_STANDBY
	var/working_power = 1
	var/efficiency = 0.5

/obj/machinery/electrolyzer/get_cell()
	return cell

/obj/machinery/electrolyzer/Initialize(mapload)
	. = ..()
	if(mapload && !cell)
		cell = new /obj/item/stock_parts/cell/high(src)
	update_power_source()
	SSair.start_processing_machine(src)
	update_appearance(UPDATE_ICON)
	register_context()

/obj/machinery/electrolyzer/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	context[SCREENTIP_CONTEXT_ALT_LMB] = "Turn [on ? "off" : "on"]"
	if(!held_item)
		return CONTEXTUAL_SCREENTIP_SET
	switch(held_item.tool_behaviour)
		if(TOOL_SCREWDRIVER)
			context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "Close" : "Open"] panel"
		if(TOOL_WRENCH)
			context[SCREENTIP_CONTEXT_LMB] = "[anchored ? "Unan" : "An"]chor"
	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/electrolyzer/Destroy()
	if(cell)
		QDEL_NULL(cell)
	return ..()

/obj/machinery/electrolyzer/on_deconstruction(disassembled)
	if(cell)
		LAZYADD(component_parts, cell)
		cell = null
	return ..()

/obj/machinery/electrolyzer/examine(mob/user)
	. = ..()
	. += "\The [src] is [on ? "on" : "off"], and the panel is [panel_open ? "open" : "closed"]."
	if(cell)
		. += "The charge meter reads [cell ? round(cell.percent(), 1) : 0]%."
	else
		. += "There is no power cell installed."
	if(in_range(user, src) || isobserver(user))
		. += span_notice("<b>Alt-click</b> to toggle [on ? "off" : "on"].")
		. += span_notice("It will drain power from the [anchored ? "area's APC" : "internal power cell"].")

/obj/machinery/electrolyzer/update_icon_state()
	icon_state = "electrolyzer-[on ? "[mode]" : "off"]"
	return ..()

/obj/machinery/electrolyzer/update_overlays()
	. = ..()
	if(panel_open)
		. += "electrolyzer-open"

/obj/machinery/electrolyzer/process_atmos()
	if(!is_operational && on)
		on = FALSE
	if(!on)
		return PROCESS_KILL
	if((!cell || cell.charge <= 0) && !anchored)
		on = FALSE
		update_appearance(UPDATE_ICON_STATE)
		return PROCESS_KILL

	var/turf/our_turf = loc
	if(!isturf(our_turf))
		if(mode != ELECTROLYZER_MODE_STANDBY)
			mode = ELECTROLYZER_MODE_STANDBY
			update_appearance(UPDATE_ICON_STATE)
		return

	var/new_mode = on ? ELECTROLYZER_MODE_WORKING : ELECTROLYZER_MODE_STANDBY
	if(mode != new_mode)
		mode = new_mode
		update_appearance(UPDATE_ICON_STATE)

	if(mode == ELECTROLYZER_MODE_STANDBY)
		return

	var/datum/gas_mixture/env = our_turf.return_air()
	if(!env)
		return

	call_reactions(env)
	our_turf.air_update_turf(FALSE, FALSE)

	var/power_to_use = (5 * (3 * working_power) * working_power) / (efficiency + working_power)
	if(anchored)
		use_power(power_to_use)
	else
		cell.use(power_to_use)

/obj/machinery/electrolyzer/proc/call_reactions(datum/gas_mixture/env)
	return env.electrolyze(working_power)

/obj/machinery/electrolyzer/RefreshParts()
	. = ..()
	var/power = 0
	var/cap = 0
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		power += M.rating
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		cap += C.rating
	working_power = max(power, 1)
	efficiency = (cap + 1) * 0.5

/obj/machinery/electrolyzer/screwdriver_act(mob/living/user, obj/item/tool)
	tool.play_tool_sound(src, 50)
	panel_open = !panel_open
	balloon_alert(user, "[panel_open ? "opened" : "closed"] panel")
	update_appearance(UPDATE_ICON)
	return TRUE

/obj/machinery/electrolyzer/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(default_unfasten_wrench(user, tool))
		update_power_source()
	return TRUE

/obj/machinery/electrolyzer/proc/update_power_source()
	use_power = anchored ? IDLE_POWER_USE : NO_POWER_USE

/obj/machinery/electrolyzer/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(tool)

/obj/machinery/electrolyzer/attackby(obj/item/I, mob/user, list/modifiers, list/attack_modifiers)
	add_fingerprint(user)
	if(istype(I, /obj/item/stock_parts/cell))
		if(!panel_open)
			balloon_alert(user, "open panel!")
			return
		if(cell)
			balloon_alert(user, "cell inside!")
			return
		if(!user.transferItemToLoc(I, src))
			return
		cell = I
		I.add_fingerprint(user)
		balloon_alert(user, "inserted cell")
		SStgui.update_uis(src)
		return
	return ..()

/obj/machinery/electrolyzer/AltClick(mob/user)
	if(panel_open)
		balloon_alert(user, "close panel!")
		return
	toggle_power(user)

/obj/machinery/electrolyzer/proc/toggle_power(mob/user)
	if(!anchored && !cell)
		balloon_alert(user, "insert cell or anchor!")
		return
	on = !on
	mode = on ? ELECTROLYZER_MODE_WORKING : ELECTROLYZER_MODE_STANDBY
	update_appearance(UPDATE_ICON_STATE)
	balloon_alert(user, "turned [on ? "on" : "off"]")
	if(on)
		SSair.start_processing_machine(src)

/obj/machinery/electrolyzer/ui_state(mob/user)
	return GLOB.physical_state

/obj/machinery/electrolyzer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Electrolyzer", name)
		ui.open()

/obj/machinery/electrolyzer/ui_data()
	var/list/data = list()
	data["open"] = panel_open
	data["on"] = on
	data["hasPowercell"] = !isnull(cell)
	data["anchored"] = anchored
	if(cell)
		data["powerLevel"] = round(cell.percent(), 1)
	return data

/obj/machinery/electrolyzer/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("power")
			toggle_power(ui.user)
			. = TRUE
		if("eject")
			if(panel_open && cell)
				cell.forceMove(drop_location())
				cell = null
				. = TRUE

#undef ELECTROLYZER_MODE_STANDBY
#undef ELECTROLYZER_MODE_WORKING
