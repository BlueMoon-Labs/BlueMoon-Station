/// The light switch. Can have multiple per area.
/obj/machinery/light_switch
	name = "light switch"
	icon = 'icons/obj/power.dmi'
	icon_state = "light1"
	base_icon_state = "light"
	desc = "Make dark."
	mouse_over_pointer = MOUSE_HAND_POINTER
	var/area/area = null
	var/otherarea = null
	var/autoname = TRUE
	/// you can connect lights by tapping them with light switch frame
	var/list/connected_lights = list()

/obj/machinery/light_switch/directional/north
	dir = SOUTH
	pixel_y = 26

/obj/machinery/light_switch/directional/south
	dir = NORTH
	pixel_y = -26

/obj/machinery/light_switch/directional/east
	dir = WEST
	pixel_x = 26

/obj/machinery/light_switch/directional/west
	dir = EAST
	pixel_x = -26

/obj/machinery/light_switch/Initialize(mapload,  ndir, building)
	. = ..()
	if(istext(area))
		area = text2path(area)
	if(ispath(area))
		area = GLOB.areas_by_type[area]
	if(otherarea)
		area = locate(text2path("/area/[otherarea]"))
	if(!area)
		area = get_area(src)
	if(autoname && area)
		name = "light switch ([area.name])"
	if(building)
		setDir(ndir)
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -26 : 26)
		pixel_y = (dir & 3)? (dir == 1 ? -26 : 26) : 0
		update_icon()
	register_context()

/obj/machinery/light_switch/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(isnull(held_item))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, (area?.lightswitch ? "Flick off" : "Flick on"))
		return CONTEXTUAL_SCREENTIP_SET
	if(held_item.tool_behaviour == TOOL_SCREWDRIVER)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Deconstruct")
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_DISARM, "Disconnect lights")
		return CONTEXTUAL_SCREENTIP_SET
	return

/obj/machinery/light_switch/update_appearance(updates=ALL)
	. = ..()
	luminosity = (machine_stat & NOPOWER) ? 0 : 1

/obj/machinery/light_switch/update_icon_state()
	if(machine_stat & NOPOWER)
		icon_state = "[base_icon_state]-p"
		return ..()
	if(!area)
		return ..()
	icon_state = "[base_icon_state][area.lightswitch ? 1 : 0]"
	if(!isemptylist(connected_lights))
		var/obj/machinery/light/L = connected_lights[1]
		icon_state = "[base_icon_state][L?.on ? 1 : 0]"
	return ..()

/obj/machinery/light_switch/update_overlays()
	. = ..()
	if(!(machine_stat & NOPOWER))
		. += emissive_appearance(icon, "[base_icon_state]-glow", alpha = src.alpha)

/obj/machinery/light_switch/examine(mob/user)
	. = ..()
	. += "It is [area?.lightswitch ? "on" : "off"]."
	if(!isemptylist(connected_lights))
		. += "There are [length(connected_lights)] individual lights connected to this switch."

/obj/machinery/light_switch/interact(mob/user)
	. = ..()
	if(!isemptylist(connected_lights))
		for(var/obj/machinery/light/L in connected_lights)
			if(QDELETED(L))
				connected_lights -= L
				continue
			L.individual_switch_state = !L.on
			var/area/A = get_area(L)
			A.update_appearance()
			A.power_change()
		update_appearance()
		return
	if(!area)
		return
	area.lightswitch = !area.lightswitch
	area.update_appearance()
	for(var/obj/machinery/light_switch/L in area)
		L.update_appearance()
	area.power_change()

/obj/machinery/light_switch/screwdriver_act(mob/living/user, obj/item/I)
	if(!isemptylist(connected_lights))
		for(var/obj/machinery/light/L in connected_lights)
			if(QDELETED(L))
				connected_lights -= L
				continue
			L.individual_switch_state = null
			var/area/A = get_area(L)
			A.update_appearance()
			A.power_change()
		connected_lights = list()
		to_chat(user, "You disconnect all individual lights from [src].")
	if(user.a_intent == INTENT_DISARM)
		update_appearance()
		return TRUE // we disconnected lights and we are done.
	user.visible_message(span_notice("[user] starts unscrewing [src]..."), span_notice("You start unscrewing [src]..."))
	if(!I.use_tool(src, user, 40, volume = 50))
		return TRUE
	user.visible_message(span_notice("[user] unscrews [src]!"), span_notice("You detach [src] from the wall."))
	I.play_tool_sound(src, 50)
	deconstruct(TRUE)
	return TRUE

/obj/machinery/light_switch/power_change()
	if(!otherarea)
		if(powered(LIGHT))
			machine_stat &= ~NOPOWER
		else
			machine_stat |= NOPOWER
	update_appearance()

/obj/machinery/light_switch/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(!(machine_stat & (BROKEN|NOPOWER)))
		power_change()

/obj/machinery/light_switch/on_deconstruction()
	new /obj/item/wallframe/light_switch(loc)

/obj/item/wallframe/light_switch
	name = "light switch frame"
	desc = "An unmounted light switch. Attach it to a wall to use."
	icon = 'icons/obj/power.dmi'
	icon_state = "light-p"
	result_path = /obj/machinery/light_switch
	custom_materials = list(/datum/material/iron = MINERAL_MATERIAL_AMOUNT)
	/// you can connect lights by tapping them with light switch frame
	var/list/connected_lights = list()

/obj/item/wallframe/light_switch/pre_attack(atom/A, mob/living/user, params, attackchain_flags, damage_multiplier)
	. = ..()
	if(istype(A, /obj/machinery/light) && !LAZYFIND(connected_lights, A))
		connected_lights += A
		to_chat(user, "You connect this light to [src].")
		return TRUE

/obj/item/wallframe/light_switch/after_attach(obj/O)
	. = ..()
	if(!isemptylist(src.connected_lights))
		var/obj/machinery/light_switch/L = O
		L.connected_lights = src.connected_lights
		L.name = initial(L.name)
