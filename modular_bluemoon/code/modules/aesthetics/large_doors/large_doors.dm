/obj/machinery/door/airlock
	var/obj/airlock_filler_object/filler


/obj/machinery/door/airlock/multi_tile/Initialize(mapload)
	. = ..()

	SetBounds()


/obj/machinery/door/airlock/multi_tile/Move()
	SetBounds()

	return ..()


/obj/machinery/door/airlock/multi_tile/Destroy()
	if(filler)
		filler.force_destroy()

	return ..()


/obj/machinery/door/airlock/multi_tile/Adjacent(atom/neighbor)
	return ..() || filler?.Adjacent(neighbor)


/obj/machinery/door/airlock/multi_tile/open(forced)
	. = ..()

	filler?.sync()


/obj/machinery/door/airlock/multi_tile/close(forced)
	. = ..()

	filler?.sync()


/obj/machinery/door/airlock/multi_tile/sensor_obstacle_check()
	if(..())
		return TRUE

	var/turf/our_turf = get_turf(filler)
	for(var/atom/movable/M in (our_turf.contents - filler))
		if(M.density) // something is blocking the door
			return TRUE


/obj/machinery/door/airlock/multi_tile/proc/SetBounds()
	if(dir in list(NORTH, SOUTH))
		bound_width = 2 * world.icon_size
		bound_height = world.icon_size

		if(!filler)
			filler = new(get_step(src, EAST), src)

		else
			filler.loc = get_step(src, EAST)

	else
		bound_width = world.icon_size
		bound_height = 2 * world.icon_size

		if(!filler)
			filler = new(get_step(src, NORTH), src)

		else
			filler.loc = get_step(src, NORTH)

	filler.sync()


/obj/machinery/door/airlock/multi_tile/metal
	name = "large airlock"
	assemblytype = /obj/structure/door_assembly/multi_tile/metal
	has_environment_lights = FALSE


/obj/machinery/door/airlock/multi_tile/glass
	name = "large glass airlock"
	assemblytype = /obj/structure/door_assembly/multi_tile/glass
	airlock_material = "glass"
	opacity = FALSE
	glass = TRUE


/obj/machinery/door/airlock/multi_tile/narsie_act()
	return


/obj/airlock_filler_object
	name = ""
	density = TRUE
	opacity = TRUE
	anchored = TRUE
	var/obj/machinery/door/airlock/multi_tile/parent_airlock


/obj/airlock_filler_object/Initialize(mapload, obj/machinery/door/airlock/parent_airlock)
	. = ..()

	if(!parent_airlock)
		return INITIALIZE_HINT_QDEL_FORCE

	src.parent_airlock = parent_airlock


/obj/airlock_filler_object/Bump(atom/A)
	return parent_airlock.Bump(A)


/obj/airlock_filler_object/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()

	if(.)
		return

	// Snowflake handling for PASSGLASS.
	if(istype(mover) && (mover.pass_flags & PASSGLASS))
		return !opacity


/obj/airlock_filler_object/can_be_pulled(user, grab_state, force)
	return FALSE


/obj/airlock_filler_object/singularity_act()
	return


/obj/airlock_filler_object/singularity_pull(S, current_size)
	return


/obj/airlock_filler_object/Destroy(force)
	if(parent_airlock)
		parent_airlock.filler = null
		parent_airlock.SetBounds()

	return ..()


/obj/airlock_filler_object/proc/sync()
	if(!parent_airlock)
		return

	density = parent_airlock.density
	set_opacity(parent_airlock.opacity)


/obj/airlock_filler_object/proc/force_destroy()
	parent_airlock = null
	qdel(src)


// ASSEMBLYS!
/obj/structure/door_assembly/multi_tile
	var/width = 1


/obj/structure/door_assembly/multi_tile/Initialize(mapload)
	. = ..()

	SetBounds()


/obj/structure/door_assembly/multi_tile/Move()
	. = ..()

	SetBounds()


/obj/structure/door_assembly/multi_tile/proc/SetBounds()
	if(dir in list(NORTH, SOUTH))
		bound_width = width * world.icon_size
		bound_height = world.icon_size

	else
		bound_width = world.icon_size
		bound_height = width * world.icon_size


/obj/structure/door_assembly/multi_tile/metal
	name = "Large Airlock Assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/large_doors/metal/multi_tile.dmi'
	base_name = "Large Airlock"
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/large_doors/metal/overlays.dmi'
	airlock_type = /obj/machinery/door/airlock/multi_tile/metal
	glass_type = /obj/machinery/door/airlock/multi_tile/glass
	width = 2


/obj/structure/door_assembly/multi_tile/glass
	name = "Large Glass Airlock Assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/large_doors/glass/multi_tile.dmi'
	base_name = "Large Glass Airlock"
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/large_doors/glass/overlays.dmi'
	airlock_type =/obj/machinery/door/airlock/multi_tile/glass
	width = 2
