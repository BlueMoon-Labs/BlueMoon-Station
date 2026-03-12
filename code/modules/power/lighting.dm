// The lighting system
//
// consists of light fixtures (/obj/machinery/light) and light tube/bulb items (/obj/item/light)

#define LIGHT_EMERGENCY_POWER_USE 0.2 //How much power emergency lights will consume per tick
// status values shared between lighting fixtures and items
#define LIGHT_OK 0
#define LIGHT_EMPTY 1
#define LIGHT_BROKEN 2
#define LIGHT_BURNED 3



/obj/item/wallframe/light_fixture
	name = "light fixture frame"
	desc = "Used for building lights."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube-construct-item"
	result_path = /obj/structure/light_construct
	inverse = TRUE

/obj/item/wallframe/light_fixture/small
	name = "small light fixture frame"
	icon_state = "bulb-construct-item"
	result_path = /obj/structure/light_construct/small
	custom_materials = list(/datum/material/iron=MINERAL_MATERIAL_AMOUNT)

/obj/item/wallframe/light_fixture/try_build(turf/on_wall, user)
	if(!..())
		return
	var/area/A = get_area(user)
	if(!IS_DYNAMIC_LIGHTING(A))
		to_chat(user, "<span class='warning'>You cannot place [src] in this area!</span>")
		return
	return TRUE


/obj/structure/light_construct
	name = "light fixture frame"
	desc = "A light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube-construct-stage1"
	anchored = TRUE
	layer = WALL_OBJ_LAYER
	max_integrity = 200
	armor = list(MELEE = 50, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 80, ACID = 50)

	var/stage = 1
	var/fixture_type = "tube"
	var/sheets_refunded = 2
	var/obj/machinery/light/newlight = null
	var/obj/item/stock_parts/cell/cell

	var/cell_connectors = TRUE

/obj/structure/light_construct/Initialize(mapload, ndir, building)
	. = ..()
	if(building)
		setDir(ndir)

/obj/structure/light_construct/Destroy()
	QDEL_NULL(cell)
	return ..()

/obj/structure/light_construct/get_cell()
	return cell

/obj/structure/light_construct/examine(mob/user)
	. = ..()
	switch(src.stage)
		if(1)
			. += "It's an empty frame."
		if(2)
			. += "It's wired."
		if(3)
			. += "The casing is closed."
	if(cell_connectors)
		if(cell)
			. += "You see [cell] inside the casing."
		else
			. += "The casing has no power cell for backup power."
	else
		. += "<span class='danger'>This casing doesn't support power cells for backup power.</span>"

/obj/structure/light_construct/attackby(obj/item/W, mob/user, params)
	add_fingerprint(user)
	if(istype(W, /obj/item/stock_parts/cell))
		if(!cell_connectors)
			to_chat(user, "<span class='warning'>This [name] can't support a power cell!</span>")
			return
		if(HAS_TRAIT(W, TRAIT_NODROP))
			to_chat(user, "<span class='warning'>[W] is stuck to your hand!</span>")
			return
		user.dropItemToGround(W)
		if(cell)
			user.visible_message("<span class='notice'>[user] swaps [W] out for [src]'s cell.</span>", \
			"<span class='notice'>You swap [src]'s power cells.</span>")
			cell.forceMove(drop_location())
			user.put_in_hands(cell)
		else
			user.visible_message("<span class='notice'>[user] hooks up [W] to [src].</span>", \
			"<span class='notice'>You add [W] to [src].</span>")
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		W.forceMove(src)
		cell = W
		add_fingerprint(user)
		return
	switch(stage)
		if(1)
			if(W.tool_behaviour == TOOL_WRENCH)
				to_chat(usr, "<span class='notice'>You begin deconstructing [src]...</span>")
				if (W.use_tool(src, user, 30, volume=50))
					new /obj/item/stack/sheet/metal(drop_location(), sheets_refunded)
					user.visible_message("[user.name] deconstructs [src].", \
						"<span class='notice'>You deconstruct [src].</span>", "<span class='italics'>You hear a ratchet.</span>")
					playsound(src.loc, 'sound/items/deconstruct.ogg', 75, 1)
					qdel(src)
				return

			if(istype(W, /obj/item/stack/cable_coil))
				if(W.use_tool(src, user, 0, 1, skill_gain_mult = TRIVIAL_USE_TOOL_MULT))
					icon_state = "[fixture_type]-construct-stage2"
					stage = 2
					user.visible_message("[user.name] adds wires to [src].", \
						"<span class='notice'>You add wires to [src].</span>")
				else
					to_chat(user, "<span class='warning'>You need one length of cable to wire [src]!</span>")
				return
		if(2)
			if(W.tool_behaviour == TOOL_WRENCH)
				to_chat(usr, "<span class='warning'>You have to remove the wires first!</span>")
				return

			if(W.tool_behaviour == TOOL_WIRECUTTER)
				stage = 1
				icon_state = "[fixture_type]-construct-stage1"
				new /obj/item/stack/cable_coil(drop_location(), 1, TRUE, "red")
				user.visible_message("[user.name] removes the wiring from [src].", \
					"<span class='notice'>You remove the wiring from [src].</span>", "<span class='italics'>You hear clicking.</span>")
				W.play_tool_sound(src, 100)
				return

			if(W.tool_behaviour == TOOL_SCREWDRIVER)
				user.visible_message("[user.name] closes [src]'s casing.", \
					"<span class='notice'>You close [src]'s casing.</span>", "<span class='italics'>You hear screwing.</span>")
				W.play_tool_sound(src, 75)
				switch(fixture_type)
					if("tube")
						newlight = new /obj/machinery/light/built(loc)
					if("bulb")
						newlight = new /obj/machinery/light/small/built(loc)
					if("floor") 												//just so floor lights can be built
						newlight = new /obj/machinery/light/floor/built(loc)	//this one too
				newlight.setDir(dir)
				transfer_fingerprints_to(newlight)
				if(cell)
					newlight.cell = cell
					cell.forceMove(newlight)
					cell = null
				qdel(src)
				return
	return ..()

/obj/structure/light_construct/blob_act(obj/structure/blob/B)
	if(B && B.loc == loc)
		qdel(src)


/obj/structure/light_construct/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/metal(loc, sheets_refunded)
	qdel(src)

/obj/structure/light_construct/small
	name = "small light fixture frame"
	icon_state = "bulb-construct-stage1"
	fixture_type = "bulb"
	sheets_refunded = 1

// the standard tube light fixture
/obj/machinery/light
	name = "light fixture"
	icon = 'icons/obj/lighting.dmi'
	var/overlayicon = 'icons/obj/lighting_overlay.dmi'
	var/base_state = "tube"		// base description and icon_state
	icon_state = "tube"
	desc = "A lighting fixture."
	layer = WALL_OBJ_LAYER
	max_integrity = 100
	use_power = ACTIVE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 20
	power_channel = LIGHT //Lights are calc'd via area so they dont need to be in the machine list
	var/on = FALSE					// 1 if on, 0 if off
	var/on_gs = FALSE
	var/static_power_used = 0
	var/brightness = 8			// luminosity when on, also used in power calculation
	var/bulb_power = 0.79			// basically the alpha of the emitted light source
	var/bulb_colour = "#cae2fa"	// befault colour of the light.
	var/cone_angle = LIGHTING_WALL_TUBE_CONE_ANGLE // Directional cone: light shines away from the wall
	var/status = LIGHT_OK		// LIGHT_OK, _EMPTY, _BURNED or _BROKEN
	var/flickering = FALSE
	var/light_type = /obj/item/light/tube		// the type of light item
	var/fitting = "tube"
	var/switchcount = 0			// count of number of times switched on/off
								// this is used to calc the probability the light burns out

	var/rigged = FALSE			// true if rigged to explode

	var/obj/item/stock_parts/cell/cell
	var/start_with_cell = TRUE	// if true, this fixture generates a very weak cell at roundstart

	var/nightshift_enabled = FALSE	//Currently in night shift mode?
	var/nightshift_allowed = TRUE	//Set to FALSE to never let this light get switched to night mode.
	var/nightshift_level = 0
	var/nightshift_brightness = 8
	var/nightshift_light_power = 0.47
	var/nightshift_light_color = "#A9BFFF" // More saturated than the daytime bulb tone so late-night interpolation reads visibly blue.
	var/nightshift_update_queued = FALSE
	var/last_overlay_alpha_bucket = -1
	var/last_overlay_color
	var/last_visual_mode

	var/emergency_mode = FALSE	// if true, the light is in emergency mode
	var/fire_mode = FALSE // if true, the light swaps over to emergency colour
	var/no_emergency = FALSE	// if true, this light cannot ever have an emergency mode

	var/bulb_emergency_brightness_mul = 0.25	// multiplier for this light's base brightness in emergency power mode
	var/bulb_emergency_colour = "#ff4e4e"	// determines the colour of the light while it's in emergency mode
	var/bulb_emergency_pow_mul = 0.75	// the multiplier for determining the light's power in emergency mode
	var/bulb_emergency_pow_min = 0.5	// the minimum value for the light's power in emergency mode
	var/hijacked = FALSE	// if true, the light is in a hijacked area
	/**
	 * Light can be connected to its individual light switch by tapping it with light switch frame.
	 * This variable changes during flipping individual switch.
	 * If this variable is:
	 * 		null -> light works as usual.
	 * 		TRUE/FALSE -> area.lightswitch will be ingored and this variable will be checked instead.
	 */
	var/individual_switch_state = null

	// Damage flickering state
	var/damage_flickering = FALSE
	var/damage_flicker_timer_id = null
	var/damage_flicker_base_power = null

	// Power loss animation state
	var/power_loss_stage = 0 // 0=normal, 1=death flicker, 2=dark, 3=emergency
	var/power_loss_timer_id = null

/obj/machinery/light/directional/north //Pixel offsets get overwritten on New()
	dir = NORTH

/obj/machinery/light/directional/south
	dir = SOUTH

/obj/machinery/light/directional/east
	dir = EAST

/obj/machinery/light/directional/west
	dir = WEST

/obj/machinery/light/dim/directional/north //Pixel offsets get overwritten on New()
	dir = NORTH

/obj/machinery/light/dim/directional/south
	dir = SOUTH

/obj/machinery/light/dim/directional/east
	dir = EAST

/obj/machinery/light/dim/directional/west
	dir = WEST

/obj/machinery/light/broken
	status = LIGHT_BROKEN
	icon_state = "tube-broken"

// the smaller bulb light fixture

/obj/machinery/light/small
	icon_state = "bulb"
	base_state = "bulb"
	fitting = "bulb"
	brightness = 5
	nightshift_brightness = 4
	bulb_colour = "#dcdeff"
	desc = "A small lighting fixture."
	light_type = /obj/item/light/bulb
	cone_angle = LIGHTING_WALL_BULB_CONE_ANGLE

/obj/machinery/light/small/directional/north //Pixel offsets get overwritten on New()
	dir = NORTH

/obj/machinery/light/small/directional/south
	dir = SOUTH

/obj/machinery/light/small/directional/east
	dir = EAST

/obj/machinery/light/small/directional/west
	dir = WEST

/obj/machinery/light/small/broken
	status = LIGHT_BROKEN
	icon_state = "bulb-broken"

/obj/machinery/light/Move()
	if(status != LIGHT_BROKEN)
		break_light_tube(1)
	return ..()

/obj/machinery/light/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()
	// Upgrade light source queue priority to FORCE_UPDATE — guarantees FULL path
	// with view() recalculation regardless of position detection result.
	if(light && !QDELETED(light))
		light.force_update()

/obj/machinery/light/built
	icon_state = "tube-empty"
	start_with_cell = FALSE

/obj/machinery/light/built/Initialize(mapload)
	. = ..()
	status = LIGHT_EMPTY
	update(0)

/obj/machinery/light/small/built
	icon_state = "bulb-empty"
	start_with_cell = FALSE

/obj/machinery/light/small/built/Initialize(mapload)
	. = ..()
	status = LIGHT_EMPTY
	update(0)



// create a new lighting fixture
/obj/machinery/light/Initialize(mapload)
	. = ..()
	if(start_with_cell && !no_emergency)
		cell = new/obj/item/stock_parts/cell/emergency_light(src)
	set_layer_by_dir() // BLUEMOON ADD START
	mark_apc_light_cache_dirty()
	var/area/current_area = get_base_area(src)
	sync_nightshift_from_current_apc(current_area)
	spawn(2)
		switch(fitting)
			if("tube")
				brightness = 9
				if(prob(2))
					break_light_tube(1)
			if("bulb")
				brightness = 5
				if(prob(5))
					break_light_tube(1)
		spawn(1)
			update(0)

/obj/machinery/light/Destroy()
	stop_damage_flicker()
	stop_power_loss_sequence()
	var/area/A = get_area(src)
	if(A)
		on = FALSE
	mark_apc_light_cache_dirty(A)
	nightshift_update_queued = FALSE
	QDEL_NULL(cell)
	return ..()

/obj/machinery/light/Moved(atom/OldLoc, Dir)
	var/area/old_area = OldLoc ? get_area(OldLoc) : null
	. = ..()
	var/area/new_area = get_base_area(src)
	if(old_area != new_area)
		mark_apc_light_cache_dirty(old_area)
		mark_apc_light_cache_dirty(new_area)
	if(sync_nightshift_from_current_apc(new_area))
		update(FALSE, TRUE)

// BLUEMOON ADD START - если лампа смотрит вниз, то она находится "под" мобом, чтобы можно было корректно её загораживать своим спрайтом
/obj/machinery/light/proc/set_layer_by_dir()
	if(dir == NORTH)
		layer = MOB_LOWER_LAYER
// BLUEMOON ADD END

/obj/machinery/light/proc/mark_apc_light_cache_dirty(area/target_area = get_base_area(src))
	if(!target_area)
		return
	var/obj/machinery/power/apc/current_apc = get_area_apc(target_area)
	if(current_apc)
		current_apc.mark_light_cache_dirty()

/obj/machinery/light/proc/get_area_apc(area/target_area = get_base_area(src))
	if(!target_area)
		return null
	var/area/root_area = target_area.base_area ? target_area.base_area : target_area
	var/obj/machinery/power/apc/current_apc = root_area.power_apc
	if(current_apc && !QDELETED(current_apc))
		var/area/apc_area = current_apc.area
		var/list/linked_areas = root_area.sub_areas
		if(apc_area == root_area || apc_area?.base_area == root_area || linked_areas?.Find(apc_area))
			return current_apc
	return target_area.get_apc()

/obj/machinery/light/proc/sync_nightshift_from_apc(obj/machinery/power/apc/current_apc)
	var/new_nightshift_enabled = FALSE
	var/new_nightshift_level = 0
	if(nightshift_allowed && current_apc?.nightshift_lights)
		new_nightshift_enabled = TRUE
		new_nightshift_level = current_apc.nightshift_level
	if(nightshift_enabled == new_nightshift_enabled && nightshift_level == new_nightshift_level)
		return FALSE
	nightshift_enabled = new_nightshift_enabled
	nightshift_level = new_nightshift_level
	return TRUE

/obj/machinery/light/proc/sync_nightshift_from_current_apc(area/target_area = get_base_area(src))
	return sync_nightshift_from_apc(get_area_apc(target_area))

/obj/machinery/light/proc/queue_nightshift_update()
	if(nightshift_update_queued)
		return FALSE
	nightshift_update_queued = TRUE
	GLOB.nightshift_light_queue += src
	return TRUE

/obj/machinery/light/proc/get_visual_mode(area/current_area)
	if(status != LIGHT_OK)
		return "[status]"
	if(emergency_mode || current_area?.fire)
		return "emergency"
	if(hijacked)
		return "hijacked"
	return "normal"

/obj/machinery/light/proc/get_overlay_alpha_bucket()
	if(!(on && status == LIGHT_OK))
		return 0
	return clamp(round(clamp(light_power * 250, 30, 200), 5), 0, 255)

/obj/machinery/light/proc/get_overlay_color(area/current_area)
	if(!(on && status == LIGHT_OK))
		return null
	if(emergency_mode || current_area?.fire)
		return bulb_emergency_colour
	if(hijacked)
		return color ? color : LIGHT_COLOR_YELLOW
	var/overlay_color = color || bulb_colour
	if(nightshift_enabled)
		overlay_color = blend_light_color(overlay_color, nightshift_light_color, nightshift_level)
	return overlay_color

/obj/machinery/light/proc/refresh_visuals(area/current_area)
	var/new_visual_mode = get_visual_mode(current_area)
	var/new_overlay_bucket = get_overlay_alpha_bucket()
	var/new_overlay_color = get_overlay_color(current_area)
	var/icon_changed = new_visual_mode != last_visual_mode
	var/overlay_changed = new_overlay_bucket != last_overlay_alpha_bucket || new_overlay_color != last_overlay_color
	last_visual_mode = new_visual_mode
	last_overlay_alpha_bucket = new_overlay_bucket
	last_overlay_color = new_overlay_color
	if(icon_changed)
		update_icon()
	else if(overlay_changed)
		update_overlays()

/obj/machinery/light/proc/interpolate_light_value(start_value, end_value, t)
	return round(start_value + (end_value - start_value) * t, 0.01)

/obj/machinery/light/proc/blend_light_color(from_color, to_color, t)
	if(isnull(to_color) || t <= 0)
		return from_color
	if(isnull(from_color) || t >= 1)
		return to_color
	var/r1 = GETREDPART(from_color)
	var/g1 = GETGREENPART(from_color)
	var/b1 = GETBLUEPART(from_color)
	var/r2 = GETREDPART(to_color)
	var/g2 = GETGREENPART(to_color)
	var/b2 = GETBLUEPART(to_color)
	return rgb(
		round(r1 + (r2 - r1) * t),
		round(g1 + (g2 - g1) * t),
		round(b1 + (b2 - b1) * t),
	)

/obj/machinery/light/update_icon_state()
	switch(status)		// set icon_states
		if(LIGHT_OK)
			var/area/A = get_base_area(src)
			if(emergency_mode || (A && A.fire))
				icon_state = "[base_state]_emergency"
			else
				if (hijacked)
					icon_state = "[base_state]_hijacked"
				else
					icon_state = "[base_state]"
		if(LIGHT_EMPTY)
			icon_state = "[base_state]-empty"
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"

/obj/machinery/light/update_overlays()
	. = ..()
	if(on && status == LIGHT_OK)
		var/overlay_alpha = get_overlay_alpha_bucket()
		var/mutable_appearance/M = mutable_appearance(overlayicon, base_state)
		M.alpha = overlay_alpha
		M.color = last_overlay_color || get_overlay_color(get_base_area(src))
		M.dir = dir
		. += M
		var/mutable_appearance/emissive_overlay = mutable_appearance(overlayicon, base_state, EMISSIVE_UNBLOCKABLE_LAYER, EMISSIVE_UNBLOCKABLE_PLANE)
		emissive_overlay.alpha = overlay_alpha
		emissive_overlay.color = M.color
		emissive_overlay.dir = dir
		. += emissive_overlay

// update the icon_state and luminosity of the light depending on its state
/obj/machinery/light/proc/update(trigger = TRUE, silent = FALSE)
	var/area/current_area = get_base_area(src)
	switch(status)
		if(LIGHT_BROKEN,LIGHT_BURNED,LIGHT_EMPTY)
			on = FALSE
			emergency_mode = FALSE
			stop_power_loss_sequence()
			set_light(0, l_cone_angle = 0)
	if(emergency_mode && !has_power())
		return // Active emergency lighting — handled by emergency_flicker_tick()
	emergency_mode = FALSE
	if(on)
		var/BR = brightness
		var/PO = bulb_power
		var/CO = bulb_colour
		if(color)
			CO = color
		if(current_area?.fire)
			CO = bulb_emergency_colour
		else if (hijacked)
			BR = BR * 1.5
			PO = PO * 1.5
			CO = color ? color : LIGHT_COLOR_YELLOW
		else if (nightshift_enabled)
			BR = interpolate_light_value(BR, nightshift_brightness, nightshift_level)
			PO = interpolate_light_value(PO, nightshift_light_power, nightshift_level)
			CO = blend_light_color(CO, nightshift_light_color, nightshift_level)
		var/desired_cone_dir = turn(dir, 180)
		var/matching = light && BR == light_range && PO == light_power && CO == light_color && cone_angle == light_cone_angle && desired_cone_dir == light_cone_dir
		if(!matching)
			var/can_apply_light = TRUE
			if(trigger)
				switchcount++
				if(rigged)
					if(status == LIGHT_OK)
						explode()
						can_apply_light = FALSE
				else if(prob(min(60, (switchcount^2)*0.01)))
					burn_out()
					can_apply_light = FALSE
			if(can_apply_light)
				use_power = ACTIVE_POWER_USE
				set_light(BR, PO, CO, l_cone_angle = cone_angle, l_cone_dir = desired_cone_dir)
				if(!silent)
					playsound(src.loc, 'sound/ambience/light_on.ogg', 65, 1)
	else if(has_emergency_power(LIGHT_EMERGENCY_POWER_USE) && !turned_off())
		use_power = IDLE_POWER_USE
		on = FALSE
		set_light(0, l_cone_angle = 0)
		// emergency_mode = TRUE
		START_PROCESSING(SSmachines, src)
	else
		use_power = IDLE_POWER_USE
		set_light(0, l_cone_angle = 0)
	if(fire_mode)
		set_emergency_lights()
	refresh_visuals(current_area)

	active_power_usage = (brightness * 10)
	if(on != on_gs)
		on_gs = on
		if(on)
			static_power_used = brightness * 20 * (hijacked ? 2 : 1) //20W per unit luminosity
			addStaticPower(static_power_used, STATIC_LIGHT)
		else
			removeStaticPower(static_power_used, STATIC_LIGHT)

/obj/machinery/light/update_atom_colour()
	. = ..()
	update()

/obj/machinery/light/process()
	/*SPLURT EDIT START - Stop processing if there's no turf, which implies it's stored,
	this stops the null.lightswitch runtime when lights are saved in Hilbert's Hotel storeRoom() proc.*/
	if(!isturf(loc))
		return PROCESS_KILL
	// SPLURT EDIT END
	if (!cell)
		return PROCESS_KILL
	if(has_power())
		if (cell.charge == cell.maxcharge)
			return PROCESS_KILL
		cell.charge = min(cell.maxcharge, cell.charge + LIGHT_EMERGENCY_POWER_USE) //Recharge emergency power automatically while not using it
	if(emergency_mode)
		if(!use_emergency_power(LIGHT_EMERGENCY_DRAIN_RATE))
			// Cell exhausted — turn off emergency mode
			clear_emergency_state(FALSE)
			return PROCESS_KILL
		update() //Disables emergency mode and sets the color to normal

/obj/machinery/light/proc/burn_out()
	if(status == LIGHT_OK)
		status = LIGHT_BURNED
		icon_state = "[base_state]-burned"
		on = FALSE
		set_light(0, l_cone_angle = 0)

// attempt to set the light's on/off status
// will not switch on if broken/burned/empty
/obj/machinery/light/proc/seton(s)
	on = (s && status == LIGHT_OK)
	update()

/obj/machinery/light/get_cell()
	return cell

// examine verb
/obj/machinery/light/examine(mob/user)
	. = ..()
	switch(status)
		if(LIGHT_OK)
			. += "It is turned [on? "on" : "off"]."
		if(LIGHT_EMPTY)
			. += "The [fitting] has been removed."
		if(LIGHT_BURNED)
			. += "The [fitting] is burnt out."
		if(LIGHT_BROKEN)
			. += "The [fitting] has been smashed."
	if(cell)
		. += "Its backup power charge meter reads [round((cell.charge / cell.maxcharge) * 100, 0.1)]%."
	. += span_notice("You can connect light switch frame to it.")



// attack with item - insert light (if right type), otherwise try to break the light

/obj/machinery/light/attackby(obj/item/W, mob/living/user, params)

	//fully implemented in "lightreplacer.dm"
	if(istype(W, /obj/item/lightreplacer))
		return //to avoid hitting it

	// attempt to insert light
	else if(istype(W, /obj/item/light))
		if(status == LIGHT_OK)
			to_chat(user, "<span class='warning'>There is a [fitting] already inserted!</span>")
		else
			src.add_fingerprint(user)
			var/obj/item/light/L = W
			if(istype(L, light_type))
				if(!user.temporarilyRemoveItemFromInventory(L))
					return

				src.add_fingerprint(user)
				if(status != LIGHT_EMPTY)
					drop_light_tube(user)
					to_chat(user, "<span class='notice'>You replace [L].</span>")
				else
					to_chat(user, "<span class='notice'>You insert [L].</span>")
				status = L.status
				switchcount = L.switchcount
				rigged = L.rigged
				brightness = L.brightness
				sync_nightshift_from_current_apc()
				on = has_power()
				update()

				qdel(L)

				if(on && rigged)
					explode()
			else
				to_chat(user, "<span class='warning'>This type of light requires a [fitting]!</span>")

	// attempt to stick weapon into light socket
	else if(status == LIGHT_EMPTY)
		if(W.tool_behaviour == TOOL_SCREWDRIVER) //If it acts like a screwdriver, open it.
			W.play_tool_sound(src, 75)
			user.visible_message("[user.name] opens [src]'s casing.", \
				"<span class='notice'>You open [src]'s casing.</span>", "<span class='italics'>You hear a noise.</span>")
			deconstruct()
		else
			to_chat(user, "<span class='userdanger'>You stick \the [W] into the light socket!</span>")
			if(has_power() && (W.flags_1 & CONDUCT_1))
				do_sparks(3, TRUE, src)
				if (prob(75))
					electrocute_mob(user, get_area(src), src, rand(0.7,1.0), TRUE)
	else
		return ..()

/obj/machinery/light/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/obj/structure/light_construct/newlight = null
		var/cur_stage = 2
		if(!disassembled)
			cur_stage = 1
		switch(fitting)
			if("tube")
				newlight = new /obj/structure/light_construct(src.loc)
				newlight.icon_state = "tube-construct-stage[cur_stage]"

			if("bulb")
				newlight = new /obj/structure/light_construct/small(src.loc)
				newlight.icon_state = "bulb-construct-stage[cur_stage]"
			if("floor")															//deconstruction.
				newlight = new /obj/structure/light_construct/floor(src.loc)	//this one too
				newlight.icon_state = "floor-construct-stage[cur_stage]"		//this one too x2
		newlight.setDir(src.dir)
		newlight.stage = cur_stage
		if(!disassembled)
			newlight.obj_integrity = newlight.max_integrity * 0.5
			if(status != LIGHT_BROKEN)
				break_light_tube()
			if(status != LIGHT_EMPTY)
				drop_light_tube()
			new /obj/item/stack/cable_coil(loc, 1, TRUE, "red")
		transfer_fingerprints_to(newlight)
		if(!QDELETED(cell))
			newlight.cell = cell
			cell.forceMove(newlight)
			cell = null
	qdel(src)

/obj/machinery/light/attacked_by(obj/item/I, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(status == LIGHT_BROKEN || status == LIGHT_EMPTY)
		if(on && (I.flags_1 & CONDUCT_1))
			if(prob(12))
				electrocute_mob(user, get_area(src), src, 0.3, TRUE)

/obj/machinery/light/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1)
	. = ..()
	if(. && !QDELETED(src))
		if(prob(damage_amount * 5))
			break_light_tube()
		else
			check_damage_flicker()




/obj/machinery/light/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(cell)
		cell.use(cell.charge)
	if(emergency_mode || power_loss_stage)
		clear_emergency_state()

/obj/machinery/light/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			switch(status)
				if(LIGHT_EMPTY)
					playsound(loc, 'sound/weapons/smash.ogg', 50, 1)
				if(LIGHT_BROKEN)
					playsound(loc, 'sound/effects/hit_on_shattered_glass.ogg', 90, 1)
				else
					playsound(loc, 'sound/effects/glasshit.ogg', 90, 1)
		if(BURN)
			playsound(src.loc, 'sound/items/welder.ogg', 100, 1)

// returns if the light has power /but/ is manually turned off
// if a light is turned off, it won't activate emergency power
/obj/machinery/light/proc/turned_off()
	var/area/A = get_area(src)
	if(!isnull(individual_switch_state))
		return !individual_switch_state && A.power_light || flickering
	return !A.lightswitch && A.power_light || flickering

// returns whether this light has power
// true if area has power and lightswitch is on
/obj/machinery/light/proc/has_power()
	var/area/A = get_area(src)
	if(!isnull(individual_switch_state))
		return individual_switch_state && A.power_light
	return A.lightswitch && A.power_light

// returns whether this light has emergency power
// can also return if it has access to a certain amount of that power
/obj/machinery/light/proc/has_emergency_power(pwr)
	if(no_emergency || !cell)
		return FALSE
	if(pwr ? cell.charge >= pwr : cell.charge)
		return status == LIGHT_OK

// attempts to use power from the installed emergency cell, returns true if it does and false if it doesn't
/obj/machinery/light/proc/use_emergency_power(pwr = LIGHT_EMERGENCY_POWER_USE)
	if(!has_emergency_power(pwr))
		return FALSE
	if(cell.charge > 300) //it's meant to handle 120 W, ya doofus
		visible_message("<span class='warning'>[src] short-circuits from too powerful of a power cell!</span>")
		burn_out()
		return FALSE
	cell.use(pwr)
	set_light(brightness * bulb_emergency_brightness_mul, max(bulb_emergency_pow_min, bulb_emergency_pow_mul * (cell.charge / cell.maxcharge)), bulb_emergency_colour, l_cone_angle = cone_angle, l_cone_dir = turn(dir, 180))
	return TRUE


/obj/machinery/light/proc/flicker(var/amount = rand(10, 20))
	set waitfor = 0
	if(flickering)
		return
	flickering = 1
	if(on && status == LIGHT_OK)
		for(var/i = 0; i < amount; i++)
			if(status != LIGHT_OK)
				break
			on = !on
			update(0)
			sleep(rand(5, 15))
		on = (status == LIGHT_OK)
		update(0)
	flickering = 0

// ai attack - make lights flicker, because why not

/obj/machinery/light/attack_ai(mob/user)
	no_emergency = !no_emergency
	to_chat(user, "<span class='notice'>Emergency lights for this fixture have been [no_emergency ? "disabled" : "enabled"].</span>")
	update(FALSE)
	return

// attack with hand - remove tube/bulb
// if hands aren't protected and the light is on, burn the player

/obj/machinery/light/on_attack_hand(mob/living/carbon/human/user)
	. = ..()
	user.DelayNextAction(CLICK_CD_MELEE)
	add_fingerprint(user)

	if(status == LIGHT_EMPTY)
		to_chat(user, "There is no [fitting] in this light.")
		return

	// make it burn hands if not wearing fire-insulated gloves
	if(on)
		var/prot = 0
		var/mob/living/carbon/human/H = user

		if(istype(H))
			var/datum/species/ethereal/eth_species = H.dna?.species
			if(istype(eth_species))
				to_chat(H, "<span class='notice'>You start channeling some power through the [fitting] into your body.</span>")
				if(do_after(user, 50, target = src))
					var/obj/item/organ/stomach/ethereal/stomach = H.getorganslot(ORGAN_SLOT_STOMACH)
					if(istype(stomach))
						to_chat(H, "<span class='notice'>You receive some charge from the [fitting].</span>")
						stomach.adjust_charge(2)
					else
						to_chat(H, "<span class='warning'>You can't receive charge from the [fitting]!</span>")
				return

			if(H.gloves)
				var/obj/item/clothing/gloves/G = H.gloves
				if(G.max_heat_protection_temperature)
					prot = (G.max_heat_protection_temperature > 360)
		else
			prot = 1

		if(prot > 0 || HAS_TRAIT(user, TRAIT_RESISTHEAT) || HAS_TRAIT(user, TRAIT_RESISTHEATHANDS))
			to_chat(user, "<span class='notice'>You remove the light [fitting].</span>")
		else if(istype(user) && user.dna.check_mutation(TK))
			to_chat(user, "<span class='notice'>You telekinetically remove the light [fitting].</span>")
		else
			to_chat(user, "<span class='warning'>You try to remove the light [fitting], but you burn your hand on it!</span>")

			var/obj/item/bodypart/affecting = H.get_bodypart("[(user.active_hand_index % 2 == 0) ? "r" : "l" ]_arm")
			if(affecting && affecting.receive_damage( 0, 5 ))		// 5 burn damage
				H.update_damage_overlays()
			return				// if burned, don't remove the light
	else
		to_chat(user, "<span class='notice'>You remove the light [fitting].</span>")
	// create a light tube/bulb item and put it in the user's hand
	drop_light_tube(user)

/obj/machinery/light/proc/drop_light_tube(mob/user)
	var/obj/item/light/L = new light_type()
	L.status = status
	L.rigged = rigged
	L.brightness = brightness

	// light item inherits the switchcount, then zero it
	L.switchcount = switchcount
	switchcount = 0

	INVOKE_ASYNC(L, TYPE_PROC_REF(/obj/machinery/light, update))
	L.forceMove(loc)

	if(user) //puts it in our active hand
		L.add_fingerprint(user)
		user.put_in_active_hand(L)

	status = LIGHT_EMPTY
	update()
	return L

/obj/machinery/light/attack_tk(mob/user)
	if(status == LIGHT_EMPTY)
		to_chat(user, "There is no [fitting] in this light.")
		return

	to_chat(user, "<span class='notice'>You telekinetically remove the light [fitting].</span>")
	// create a light tube/bulb item and put it in the user's hand
	var/obj/item/light/L = drop_light_tube()
	L.attack_tk(user)


// break the light and make sparks if was on

/obj/machinery/light/proc/break_light_tube(skip_sound_and_sparks = 0)
	if(status == LIGHT_EMPTY || status == LIGHT_BROKEN)
		return
	stop_damage_flicker()
	if(!skip_sound_and_sparks)
		if(status == LIGHT_OK || status == LIGHT_BURNED)
			playsound(src.loc, 'sound/effects/glasshit.ogg', 75, 1)
		if(on)
			do_sparks(3, TRUE, src)
	status = LIGHT_BROKEN
	update()

/obj/machinery/light/proc/fix()
	if(status == LIGHT_OK)
		return
	stop_damage_flicker()
	status = LIGHT_OK
	brightness = initial(brightness)
	sync_nightshift_from_current_apc()
	on = has_power()
	update()

/obj/machinery/light/zap_act(power, zap_flags)
	if(zap_flags & ZAP_MACHINE_EXPLOSIVE)
		explosion(src,0,0,0,flame_range = 5, adminlog = FALSE)
		qdel(src)
	else
		return ..()

// called when area power state changes
/obj/machinery/light/power_change()
	var/area/A = get_area(src)
	var/should_be_on
	if(!isnull(individual_switch_state))
		should_be_on = individual_switch_state && A.power_light
	else
		should_be_on = A.lightswitch && A.power_light
	// If light was on and is losing power, play death flicker animation
	if(on && !should_be_on && status == LIGHT_OK && !power_loss_stage && !A.power_light)
		start_power_loss_sequence()
		return
	// If power is being restored, cancel any ongoing power loss animation
	if(should_be_on && power_loss_stage)
		stop_power_loss_sequence()
	sync_nightshift_from_current_apc()
	seton(should_be_on)
	if(should_be_on && cell && cell.charge < cell.maxcharge)
		START_PROCESSING(SSmachines, src)

// called when on fire

/obj/machinery/light/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(prob(max(0, exposed_temperature - 673)))   //0% at <400C, 100% at >500C
		break_light_tube()

// explode the light

/obj/machinery/light/proc/explode()
	set waitfor = 0
	var/turf/T = get_turf(src.loc)
	break_light_tube()	// break it first to give a warning
	sleep(2)
	explosion(T, 0, 0, 2, 2)
	sleep(1)
	qdel(src)

// --- Damage flickering ---

/// Checks if light should start or stop flickering based on damage ratio
/obj/machinery/light/proc/check_damage_flicker()
	if(status != LIGHT_OK || !on)
		stop_damage_flicker()
		return
	var/ratio = obj_integrity / max_integrity
	if(ratio <= LIGHT_DAMAGE_FLICKER_THRESHOLD)
		if(!damage_flickering)
			start_damage_flicker()
	else
		if(damage_flickering)
			stop_damage_flicker()

/// Begins the damage flicker cycle, saving the currently emitted power and starting the timer loop
/obj/machinery/light/proc/start_damage_flicker()
	if(damage_flickering)
		return
	damage_flickering = TRUE
	damage_flicker_base_power = light ? light.light_power : bulb_power
	damage_flicker_tick()

/// Stops damage flickering, restores the normal effective light state, and kills any pending timers
/obj/machinery/light/proc/stop_damage_flicker()
	if(!damage_flickering)
		return
	damage_flickering = FALSE
	if(damage_flicker_timer_id)
		deltimer(damage_flicker_timer_id)
		damage_flicker_timer_id = null
	var/had_base_power = !isnull(damage_flicker_base_power)
	damage_flicker_base_power = null
	if(had_base_power && on && status == LIGHT_OK)
		update(FALSE, TRUE)

/// One tick of the damage flicker cycle — varies light power, may cause dropout
/obj/machinery/light/proc/damage_flicker_tick()
	if(!damage_flickering || !on || status != LIGHT_OK)
		stop_damage_flicker()
		return

	var/ratio = obj_integrity / max_integrity
	var/severe = ratio <= LIGHT_DAMAGE_FLICKER_SEVERE
	var/base_interval = severe ? LIGHT_FLICKER_INTERVAL_SEVERE : LIGHT_FLICKER_INTERVAL_NORMAL

	if(!has_z_viewers())
		var/next_interval = base_interval * (LIGHT_INTERVAL_JITTER_MIN + rand() * LIGHT_INTERVAL_JITTER_RANGE)
		damage_flicker_timer_id = addtimer(CALLBACK(src, PROC_REF(damage_flicker_tick)), next_interval, TIMER_STOPPABLE)
		return

	// Determine dropout chance and power variance
	var/dropout_prob = severe ? LIGHT_FLICKER_DROPOUT_PROB_SEVERE : LIGHT_FLICKER_DROPOUT_PROB_NORMAL
	var/power_variance = severe ? LIGHT_FLICKER_POWER_VARIANCE_SEVERE : LIGHT_FLICKER_POWER_VARIANCE

	if(prob(dropout_prob))
		// Dropout — power drops sharply for a brief moment
		var/dropout_power = damage_flicker_base_power * LIGHT_FLICKER_DROPOUT_POWER
		set_light(l_power = dropout_power)
		damage_flicker_timer_id = addtimer(CALLBACK(src, PROC_REF(damage_flicker_recover)), LIGHT_FLICKER_DROPOUT_DURATION, TIMER_STOPPABLE)
	else
		// Normal flicker — vary power around base
		var/power_mod = damage_flicker_base_power * (1 + rand(-100, 100) / 100 * power_variance)
		power_mod = clamp(power_mod, damage_flicker_base_power * LIGHT_FLICKER_POWER_CLAMP_MIN, damage_flicker_base_power * LIGHT_FLICKER_POWER_CLAMP_MAX)
		set_light(l_power = power_mod)
		// Schedule next tick with ±20% interval randomness
		var/next_interval = base_interval * (LIGHT_INTERVAL_JITTER_MIN + rand() * LIGHT_INTERVAL_JITTER_RANGE)
		damage_flicker_timer_id = addtimer(CALLBACK(src, PROC_REF(damage_flicker_tick)), next_interval, TIMER_STOPPABLE)

/// Recovers from a dropout, then resumes flicker cycle
/obj/machinery/light/proc/damage_flicker_recover()
	if(!damage_flickering || !on || status != LIGHT_OK)
		stop_damage_flicker()
		return
	if(!has_z_viewers())
		var/ratio = obj_integrity / max_integrity
		var/severe = ratio <= LIGHT_DAMAGE_FLICKER_SEVERE
		var/base_interval = severe ? LIGHT_FLICKER_INTERVAL_SEVERE : LIGHT_FLICKER_INTERVAL_NORMAL
		var/next_interval = base_interval * (LIGHT_INTERVAL_JITTER_MIN + rand() * LIGHT_INTERVAL_JITTER_RANGE)
		damage_flicker_timer_id = addtimer(CALLBACK(src, PROC_REF(damage_flicker_tick)), next_interval, TIMER_STOPPABLE)
		return
	// Restore to slightly varied power and continue the cycle
	set_light(l_power = damage_flicker_base_power)
	var/ratio = obj_integrity / max_integrity
	var/severe = ratio <= LIGHT_DAMAGE_FLICKER_SEVERE
	var/base_interval = severe ? LIGHT_FLICKER_INTERVAL_SEVERE : LIGHT_FLICKER_INTERVAL_NORMAL
	var/next_interval = base_interval * (LIGHT_INTERVAL_JITTER_MIN + rand() * LIGHT_INTERVAL_JITTER_RANGE)
	damage_flicker_timer_id = addtimer(CALLBACK(src, PROC_REF(damage_flicker_tick)), next_interval, TIMER_STOPPABLE)

// --- Power loss animation ---

/// Begins the power loss sequence: death flicker → darkness → emergency (if cell available)
/obj/machinery/light/proc/start_power_loss_sequence()
	if(power_loss_stage)
		return
	stop_damage_flicker()
	power_loss_stage = 1
	// Stage 1: Death flicker — rapid dim/off cycling over 0.5s
	death_flicker_tick(0)

/// Stops any ongoing power loss animation and resets state
/obj/machinery/light/proc/stop_power_loss_sequence()
	if(!power_loss_stage)
		return
	if(power_loss_timer_id)
		deltimer(power_loss_timer_id)
		power_loss_timer_id = null
	power_loss_stage = 0

/obj/machinery/light/proc/clear_emergency_state(stop_processing_if_unpowered = TRUE)
	emergency_mode = FALSE
	if(power_loss_timer_id)
		deltimer(power_loss_timer_id)
		power_loss_timer_id = null
	power_loss_stage = 0
	set_light(0, l_cone_angle = 0)
	update_icon()
	if(stop_processing_if_unpowered && !has_power())
		STOP_PROCESSING(SSmachines, src)

/// Returns TRUE if any clients are on this light's z-level
/obj/machinery/light/proc/has_z_viewers()
	var/our_z = z
	if(!our_z || !SSmobs?.initialized)
		return TRUE
	return our_z <= length(SSmobs.clients_by_zlevel) && length(SSmobs.clients_by_zlevel[our_z])

/// One step of the death flicker — rapidly toggles light dim/off
/obj/machinery/light/proc/death_flicker_tick(step)
	if(!power_loss_stage)
		return
	if(!has_z_viewers())
		step = LIGHT_DEATH_FLICKER_STEPS
	if(step >= LIGHT_DEATH_FLICKER_STEPS)
		// Death flicker done — go dark
		power_loss_stage = 2
		on = FALSE
		set_light(0, l_cone_angle = 0)
		// Handle static power accounting since we bypass update()
		if(on_gs)
			on_gs = FALSE
			removeStaticPower(static_power_used, STATIC_LIGHT)
		update_icon()
		// Schedule emergency activation after a random delay
		var/delay = rand(LIGHT_EMERGENCY_DELAY_MIN, LIGHT_EMERGENCY_DELAY_MAX)
		power_loss_timer_id = addtimer(CALLBACK(src, PROC_REF(activate_emergency_lighting)), delay, TIMER_STOPPABLE)
		return
	// Toggle between dim and off
	if(step % 2 == 0)
		set_light(brightness * LIGHT_DEATH_FLICKER_BRIGHTNESS_MUL, bulb_power * LIGHT_DEATH_FLICKER_POWER_MUL, bulb_colour, l_cone_angle = cone_angle, l_cone_dir = turn(dir, 180))
	else
		set_light(0, l_cone_angle = 0)
	power_loss_timer_id = addtimer(CALLBACK(src, PROC_REF(death_flicker_tick), step + 1), LIGHT_DEATH_FLICKER_DURATION, TIMER_STOPPABLE)

/// Activates emergency red lighting after power loss, if cell is available
/obj/machinery/light/proc/activate_emergency_lighting()
	if(!power_loss_stage || power_loss_stage != 2)
		return
	// Check if we can enter emergency mode
	if(!has_emergency_power(LIGHT_EMERGENCY_POWER_USE) || turned_off())
		power_loss_stage = 0
		power_loss_timer_id = null
		// No emergency power — just do normal update to handle emergency mode
		update()
		return
	power_loss_stage = 3
	on = FALSE
	emergency_mode = TRUE
	set_light(brightness * bulb_emergency_brightness_mul, max(bulb_emergency_pow_min, bulb_emergency_pow_mul * (cell.charge / cell.maxcharge)), bulb_emergency_colour, l_cone_angle = cone_angle, l_cone_dir = turn(dir, 180))
	update_icon()
	START_PROCESSING(SSmachines, src)
	// Start subtle emergency flicker
	var/next_interval = LIGHT_EMERGENCY_FLICKER_INTERVAL * (LIGHT_INTERVAL_JITTER_MIN + rand() * LIGHT_INTERVAL_JITTER_RANGE)
	power_loss_timer_id = addtimer(CALLBACK(src, PROC_REF(emergency_flicker_tick)), next_interval, TIMER_STOPPABLE)

/// Subtle power fluctuation on emergency red lights
/obj/machinery/light/proc/emergency_flicker_tick()
	if(power_loss_stage != 3 || !emergency_mode)
		power_loss_timer_id = null
		return
	if(!cell || !has_emergency_power(LIGHT_EMERGENCY_POWER_USE))
		clear_emergency_state()
		return
	if(!has_z_viewers())
		var/next_interval = LIGHT_EMERGENCY_FLICKER_INTERVAL * (LIGHT_INTERVAL_JITTER_MIN + rand() * LIGHT_INTERVAL_JITTER_RANGE)
		power_loss_timer_id = addtimer(CALLBACK(src, PROC_REF(emergency_flicker_tick)), next_interval, TIMER_STOPPABLE)
		return
	// Vary emergency power ±10%
	var/charge_ratio = cell.charge / cell.maxcharge
	var/em_power = max(bulb_emergency_pow_min, bulb_emergency_pow_mul * charge_ratio)
	em_power *= (LIGHT_EMERGENCY_POWER_JITTER_MIN + rand() * LIGHT_EMERGENCY_POWER_JITTER_RANGE)
	set_light(brightness * bulb_emergency_brightness_mul, em_power, bulb_emergency_colour, l_cone_angle = cone_angle, l_cone_dir = turn(dir, 180))
	var/next_interval = LIGHT_EMERGENCY_FLICKER_INTERVAL * (LIGHT_INTERVAL_JITTER_MIN + rand() * LIGHT_INTERVAL_JITTER_RANGE)
	power_loss_timer_id = addtimer(CALLBACK(src, PROC_REF(emergency_flicker_tick)), next_interval, TIMER_STOPPABLE)

// the light item
// can be tube or bulb subtypes
// will fit into empty /obj/machinery/light of the corresponding type

/obj/item/light
	icon = 'icons/obj/lighting.dmi'
	force = 2
	throwforce = 5
	w_class = WEIGHT_CLASS_TINY
	var/status = LIGHT_OK		// LIGHT_OK, LIGHT_BURNED or LIGHT_BROKEN
	var/base_state
	var/switchcount = 0	// number of times switched
	custom_materials = list(/datum/material/glass=100)
	grind_results = list(/datum/reagent/silicon = 5, /datum/reagent/nitrogen = 10) //Nitrogen is used as a cheaper alternative to argon in incandescent lighbulbs
	var/rigged = 0		// true if rigged to explode
	var/brightness = 2 //how much light it gives off

/obj/item/light/suicide_act(mob/living/carbon/user)
	if (status == LIGHT_BROKEN)
		user.visible_message("<span class='suicide'>[user] begins to stab себя with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
		return BRUTELOSS
	else
		user.visible_message("<span class='suicide'>[user] begins to eat \the [src]! It looks like [user.ru_who()] not very bright!</span>")
		shatter()
		return BRUTELOSS

/obj/item/light/tube
	name = "light tube"
	desc = "A replacement light tube."
	icon_state = "ltube"
	base_state = "ltube"
	item_state = "c_tube"
	brightness = 9

/obj/item/light/tube/broken
	status = LIGHT_BROKEN

/obj/item/light/bulb
	name = "light bulb"
	desc = "A replacement light bulb."
	icon_state = "lbulb"
	base_state = "lbulb"
	item_state = "contvapour"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	brightness = 5

/obj/item/light/bulb/broken
	status = LIGHT_BROKEN

/obj/item/light/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!..()) //not caught by a mob
		shatter()

// update the icon state and description of the light

/obj/item/light/proc/update()
	switch(status)
		if(LIGHT_OK)
			icon_state = base_state
			desc = "A replacement [name]."
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
			desc = "A burnt-out [name]."
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"
			desc = "A broken [name]."


/obj/item/light/Initialize(mapload)
	. = ..()
	update()


// attack bulb/tube with object
// if a syringe, can inject plasma to make it explode
/obj/item/light/attackby(obj/item/I, mob/user, params)
	..()
	if(istype(I, /obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/S = I

		to_chat(user, "<span class='notice'>You inject the solution into \the [src].</span>")

		if(S.reagents.has_reagent(/datum/reagent/toxin/plasma, 5))

			rigged = 1

		S.reagents.clear_reagents()
	else
		..()
	return

/obj/item/light/attack(mob/living/M, mob/living/user, def_zone)
	. = ..()
	shatter()

/obj/item/light/attack_obj(obj/O, mob/living/user)
	. = ..()
	shatter()

/obj/item/light/proc/shatter()
	if(status == LIGHT_OK || status == LIGHT_BURNED)
		visible_message("<span class='danger'>[src] shatters.</span>","<span class='italics'>You hear a small glass object shatter.</span>")
		status = LIGHT_BROKEN
		force = 5
		playsound(src.loc, 'sound/effects/glasshit.ogg', 75, 1)
		update()

/obj/machinery/light/floor
	name = "floor light"
	icon = 'icons/obj/lighting.dmi'
	base_state = "floor"		// base description and icon_state
	icon_state = "floor"
	brightness = 5
	nightshift_brightness = 4
	layer = 2.5
	light_type = /obj/item/light/bulb
	fitting = "floor" //making deconstruction give out the right type.
	cone_angle = 0 // Floor lights emit omnidirectional light

// BLUEMOON ADD START - если лампа смотрит вниз, то она находится "под" мобом, чтобы можно было корректно её загораживать своим спрайтом
/obj/machinery/light/floor/set_layer_by_dir()
	return TRUE
// BLUEMOON ADD END

// attempts to set emergency lights
/obj/machinery/light/proc/set_emergency_lights()
	var/area/current_area = get_area(src)
	var/obj/machinery/power/apc/current_apc = get_area_apc(current_area)
	if(status != LIGHT_OK || !current_apc || flickering || no_emergency)
		emergency_lights_off(current_area, current_apc)
		return
	if(current_apc.emergency_lights)
		emergency_lights_off(current_area, current_apc)
		return
	emergency_mode = TRUE
	set_light(6, 3, bulb_emergency_colour, l_cone_angle = cone_angle, l_cone_dir = turn(dir, 180))
	RegisterSignal(current_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(update), override = TRUE)

/obj/machinery/light/proc/emergency_lights_off(area/current_area, obj/machinery/power/apc/current_apc)
	set_light(0, 0, 0, l_cone_angle = 0) //you, sir, are off!
	if(current_apc)
		RegisterSignal(current_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(update), override = TRUE)

/obj/machinery/light/broken
	status = LIGHT_BROKEN
	icon_state = "tube-broken"

/obj/machinery/light/built
	icon_state = "tube-empty"
	start_with_cell = FALSE
	status = LIGHT_EMPTY

/obj/machinery/light/no_nightlight
	nightshift_enabled = FALSE

/obj/machinery/light/warm
	bulb_colour = "#fae5c1"

/obj/machinery/light/warm/no_nightlight
	nightshift_allowed = FALSE

/obj/machinery/light/warm/dim
	nightshift_allowed = FALSE
	bulb_power = 0.63

/obj/machinery/light/cold
	bulb_colour = LIGHT_COLOR_FAINT_BLUE
	nightshift_light_color = LIGHT_COLOR_FAINT_BLUE

/obj/machinery/light/cold/no_nightlight
	nightshift_allowed = FALSE

/obj/machinery/light/cold/dim
	nightshift_allowed = FALSE
	bulb_power = 0.63

/obj/machinery/light/red
	bulb_colour = "#FF3232"
	nightshift_allowed = FALSE
	no_emergency = TRUE

/obj/machinery/light/red/dim
	brightness = 4
	bulb_power = 0.74
	bulb_emergency_brightness_mul = 2

/obj/machinery/light/blacklight
	bulb_colour = "#A700FF"
	nightshift_allowed = FALSE

/obj/machinery/light/dim
	nightshift_allowed = FALSE
	bulb_colour = "#FFDDCC"
	bulb_power = 0.63

// the smaller bulb light fixture

/obj/machinery/light/small
	icon_state = "bulb"
	base_state = "bulb"
	fitting = "bulb"
	brightness = 4
	nightshift_brightness = 4
	bulb_emergency_brightness_mul = 3
	bulb_colour = "#FFD6AA"
	bulb_emergency_colour = "#bd3f46"
	desc = "A small lighting fixture."
	light_type = /obj/item/light/bulb

/obj/machinery/light/small/broken
	status = LIGHT_BROKEN
	icon_state = "bulb-broken"

/obj/machinery/light/small/built
	icon_state = "bulb-empty"
	start_with_cell = FALSE
	status = LIGHT_EMPTY

/obj/machinery/light/small/dim
	brightness = 2.4

/obj/machinery/light/small/red
	bulb_colour = "#FF3232"
	no_emergency = TRUE
	nightshift_allowed = FALSE
	bulb_emergency_colour = "#ff1100"

/obj/machinery/light/small/red/dim
	brightness = 2
	bulb_power = 0.84
	bulb_emergency_brightness_mul = 2

/obj/machinery/light/small/blacklight
	bulb_colour = "#A700FF"
	nightshift_allowed = FALSE
	brightness = 4
	bulb_emergency_brightness_mul = 3
	bulb_emergency_colour = "#d400ff"

// Kneecapping light values every light at a time.
/obj/machinery/light/dim
	brightness = 4
	nightshift_brightness = 4
	bulb_colour = LIGHT_COLOR_TUNGSTEN
	bulb_power = 0.42

/obj/machinery/light/small
	brightness = 5
	nightshift_brightness = 4.5
	bulb_colour = LIGHT_COLOR_TUNGSTEN
	bulb_power = 0.95

/obj/machinery/light/cold
	nightshift_light_color = null

/obj/machinery/light/warm
	bulb_colour = LIGHT_COLOR_TUNGSTEN
	nightshift_light_color = null

/// Create directional subtypes for a path to simplify mapping.
#define MAPPING_DIRECTIONAL_HELPERS(path, offset) ##path/directional/north {\
	dir = NORTH; \
	pixel_y = offset; \
} \
##path/directional/south {\
	dir = SOUTH; \
	pixel_y = -offset; \
} \
##path/directional/east {\
	dir = EAST; \
	pixel_x = offset; \
} \
##path/directional/west {\
	dir = WEST; \
	pixel_x = -offset; \
}

// -------- Directional presets
// The directions are backwards on the lights we have now
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light, 0)

// ---- Broken tube
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/broken, 0)

// ---- Tube construct
MAPPING_DIRECTIONAL_HELPERS(/obj/structure/light_construct, 0)

// ---- Tube frames
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/built, 0)

// ---- No nightlight tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/no_nightlight, 0)

// ---- Warm light tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/warm, 0)

// ---- No nightlight warm light tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/warm/no_nightlight, 0)

// ---- Dim warm light tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/warm/dim, 0)

// ---- Cold light tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cold, 0)

// ---- No nightlight cold light tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cold/no_nightlight, 0)

// ---- Dim cold light tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cold/dim, 0)

// ---- Red tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/red, 0)

// ---- Red dim tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/red/dim, 0)

// ---- Blacklight tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/blacklight, 0)

// ---- Dim tubes
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/dim, 0)


// -------- Bulb lights
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/small, 0)

// ---- Bulb construct
MAPPING_DIRECTIONAL_HELPERS(/obj/structure/light_construct/small, 0)

// ---- Bulb frames
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/small/built, 0)

// ---- Broken bulbs
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/small/broken, 0)

// ---- Red bulbs
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/small/dim, 0)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/small/red, 0)

// ---- Red dim bulbs
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/small/red/dim, 0)

// ---- Blacklight bulbs
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/small/blacklight, 0)
