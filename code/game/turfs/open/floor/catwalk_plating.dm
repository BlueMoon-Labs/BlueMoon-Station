#define CATWALK_BELOW_OBJECTS list(/obj/structure/disposalpipe, /obj/structure/cable, /obj/machinery/atmospherics/pipe, \
/obj/machinery/atmospherics/components/unary/vent_scrubber, /obj/machinery/atmospherics/components/unary/vent_pump, \
/obj/machinery/navbeacon, /obj/machinery/power/terminal) // BLUEMOON ADD - catwalks_fix

/**
 * ## catwalk flooring
 *
 * They show what's underneath their catwalk flooring (pipes and the like)
 * you can crowbar it to interact with the underneath stuff without destroying the tile...
 * unless you want to!
 */
/turf/open/floor/catwalk_floor
	icon = 'modular_bluemoon/icons/turf/floors/catwalk_plating.dmi' // BLUEMOON EDIT - catwalks_fix
	icon_state = "maint_below"
	floor_tile = /obj/item/stack/tile/catwalk_tile
	name = "catwalk floor"
	desc = "Flooring that shows its contents underneath. Engineers love it!"
	baseturfs = /turf/open/floor/plating
	footstep = FOOTSTEP_CATWALK
	barefootstep = FOOTSTEP_CATWALK
	clawfootstep = FOOTSTEP_CATWALK
	heavyfootstep = FOOTSTEP_CATWALK
	intact = FALSE
	var/covered = TRUE
	var/catwalk_type = "maint"

	// BLUEMOON ADD START - catwalks_fix
/turf/open/floor/catwalk_floor/Destroy()
	for(var/atom/A in contents)
		if(is_type_in_list(A, CATWALK_BELOW_OBJECTS))
			A.plane = initial(A.plane)
	. = ..()
	// BLUEMOON ADD END

/turf/open/floor/catwalk_floor/Initialize(mapload)
	. = ..()
	update_icon(UPDATE_OVERLAYS)

/turf/open/floor/catwalk_floor/update_overlays()
	. = ..()
	if(covered)
		var/image/catwalk_overlay
		catwalk_overlay = new()
		catwalk_overlay.icon = icon
		catwalk_overlay.icon_state = "[catwalk_type]_above"
		catwalk_overlay.plane = FLOOR_PLANE // BLUEMOON EDIT - catwalks_fix
		catwalk_overlay.layer = CATWALK_LAYER
		catwalk_overlay = catwalk_overlay.appearance

		. += catwalk_overlay

	// BLUEMOON ADD START - catwalks_fix
		for(var/atom/A in contents)
			if(is_type_in_list(A, CATWALK_BELOW_OBJECTS))
				A.plane = FLOOR_PLANE
	else
		for(var/atom/A in contents)
			if(is_type_in_list(A, CATWALK_BELOW_OBJECTS))
				A.plane = initial(A.plane)
	// BLUEMOON ADD END

/turf/open/floor/catwalk_floor/screwdriver_act(mob/living/user, obj/item/tool)
	. = ..()
	covered = !covered
	user.balloon_alert(user, "[!covered ? "cover removed" : "cover added"]")
	tool.play_tool_sound(src)
	update_icon(UPDATE_OVERLAYS)

/turf/open/floor/catwalk_floor/crowbar_act(mob/user, obj/item/I)
	if(covered)
		user.balloon_alert(user, "remove cover first!")
		return FALSE
	return pry_tile(I, user)

//Reskins! More fitting with most of our tiles, and appear as a radial on the base type
/turf/open/floor/catwalk_floor/iron
	name = "iron plated catwalk floor"
	icon_state = "iron_below"
	floor_tile = /obj/item/stack/tile/catwalk_tile/iron
	catwalk_type = "iron"

/turf/open/floor/catwalk_floor/iron_white
	name = "white plated catwalk floor"
	icon_state = "whiteiron_below"
	floor_tile = /obj/item/stack/tile/catwalk_tile/iron_white
	catwalk_type = "whiteiron"

/turf/open/floor/catwalk_floor/iron_dark
	name = "dark plated catwalk floor"
	icon_state = "darkiron_below"
	floor_tile = /obj/item/stack/tile/catwalk_tile/iron_dark
	catwalk_type = "darkiron"

/turf/open/floor/catwalk_floor/titanium
	name = "titanium plated catwalk floor"
	icon_state = "titanium_below"
	floor_tile = /obj/item/stack/tile/catwalk_tile/titanium
	catwalk_type = "titanium"

/turf/open/floor/catwalk_floor/iron_smooth //the original green type
	name = "smooth plated catwalk floor"
	icon_state = "smoothiron_below"
	floor_tile = /obj/item/stack/tile/catwalk_tile/iron_smooth
	catwalk_type = "smoothiron"

#undef CATWALK_BELOW_OBJECTS // BLUEMOON ADD - catwalks_fix
