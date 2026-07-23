// So much of atmospherics.dm was used solely by components, so separating this makes things all a lot cleaner.
// On top of that, now people can add component-speciic procs/vars if they want!

/obj/machinery/atmospherics/components
	var/welded = FALSE //Used on pumps and scrubbers
	var/showpipe = FALSE
	var/shift_underlay_only = TRUE //Layering only shifts underlay?

	var/list/datum/pipeline/parents
	var/list/datum/gas_mixture/airs

/obj/machinery/atmospherics/components/New()
	parents = new(device_type)
	airs = new(device_type)
	..()

	for(var/i in 1 to device_type)
		var/datum/gas_mixture/A = new(200)
		airs[i] = A

// Iconnery

/obj/machinery/atmospherics/components/proc/update_icon_nopipes()
	return

/obj/machinery/atmospherics/components/update_icon()
	update_icon_nopipes()

	underlays.Cut()

	var/turf/T = loc
	if(level == 2 || (istype(T) && !T.intact))
		showpipe = TRUE
		plane = ABOVE_WALL_PLANE
	else
		showpipe = FALSE
		plane = FLOOR_PLANE

	if(!showpipe)
		return //no need to update the pipes if they aren't showing

	var/connected = 0 //Direction bitset

	for(var/i in 1 to device_type) //adds intact pieces
		if(nodes[i])
			var/obj/machinery/atmospherics/node = nodes[i]
			var/image/img = get_pipe_underlay("pipe_intact", get_dir(src, node), node.pipe_color)
			underlays += img
			connected |= img.dir

	for(var/direction in GLOB.cardinals)
		if((initialize_directions & direction) && !(connected & direction))
			underlays += get_pipe_underlay("pipe_exposed", direction)

	if(!shift_underlay_only)
		PIPING_LAYER_SHIFT(src, piping_layer)

/obj/machinery/atmospherics/components/proc/get_pipe_underlay(state, dir, color = null)
	if(color)
		. = getpipeimage('icons/obj/atmospherics/components/binary_devices.dmi', state, dir, color, piping_layer = shift_underlay_only ? piping_layer : 2)
	else
		. = getpipeimage('icons/obj/atmospherics/components/binary_devices.dmi', state, dir, piping_layer = shift_underlay_only ? piping_layer : 2)

// Pipenet stuff; housekeeping

/obj/machinery/atmospherics/components/nullifyNode(i)
	var/datum/gas_mixture/air_ref = airs ? airs[i] : null
	if(parents[i])
		nullifyPipenet(parents[i])
	prune_stale_pipeline_memberships(air_ref)
	QDEL_NULL(airs[i])
	return ..()

/obj/machinery/atmospherics/components/on_construction()
	..()
	update_parents()

/obj/machinery/atmospherics/components/build_network()
	if(!parents)
		stack_trace("[type] build_network() at [COORD(src)]: parents list is null - object may be destroyed or improperly initialized")
		return
	for(var/i in 1 to device_type)
		if(!parents[i])
			parents[i] = new /datum/pipeline()
			var/datum/pipeline/P = parents[i]
			P.build_pipeline(src)

/**
 * Called by nullify_node(), used to remove the pipeline the component is attached to
 * Arguments:
 * * -reference: the pipeline the component is attached to
 */
/obj/machinery/atmospherics/components/proc/nullifyPipenet(datum/pipeline/reference)
	if(!reference)
		CRASH("nullifyPipenet(null) called by [type] on [COORD(src)]")
	if(QDESTROYING(reference))
		stack_trace("nullifyPipenet() called on already-destroying pipeline [reference]([REF(reference)]) by [type] at [COORD(src)]")
		// Still need to clear our local references even if pipeline is being destroyed
		for (var/i in 1 to parents.len)
			if (parents[i] == reference)
				parents[i] = null
		return
	for (var/i in 1 to parents.len)
		if (parents[i] == reference)
			reference.other_airs -= airs[i] // Disconnects from the pipeline side
			parents[i] = null // Disconnects from the machinery side.
	reference.other_atmosmch -= src
	LAZYREMOVE(reference.bridging_atmosmch, src)
	/**
	 *  We explicitly qdel pipeline when this particular pipeline
	 *  is projected to have no member and cause GC problems.
	 *  We have to do this because components don't qdel pipelines
	 *  while pipes must and will happily wreck and rebuild everything
	 * again every time they are qdeleted.
	 */

	if(!length(reference.other_atmosmch) && !length(reference.members))
		if(QDESTROYING(reference))
			CRASH("nullifyPipenet() called on qdeleting [reference]")
		qdel(reference)

/obj/machinery/atmospherics/components/proc/prune_stale_pipeline_memberships(datum/gas_mixture/air_ref)
	var/list/seen_pipelines = list()
	for(var/list/source as anything in list(SSair.networks, SSair.currentrun))
		if(!islist(source))
			continue
		for(var/thing as anything in source)
			if(!istype(thing, /datum/pipeline))
				continue
			var/datum/pipeline/P = thing
			if(P in seen_pipelines)
				continue
			seen_pipelines += P
			if(QDELETED(P) || QDESTROYING(P))
				continue
			var/changed = FALSE
			if(src in P.other_atmosmch)
				P.other_atmosmch -= src
				LAZYREMOVE(P.bridging_atmosmch, src)
				changed = TRUE
			if(air_ref && (air_ref in P.other_airs))
				P.other_airs -= air_ref
				changed = TRUE
			if(changed)
				P.update = TRUE
				if(!length(P.other_atmosmch) && !length(P.members))
					qdel(P)

/obj/machinery/atmospherics/components/returnPipenetAirs(datum/pipeline/reference)
	var/list/returned_air = list()
	if(!parents || !airs)
		stack_trace("[type] returnPipenetAirs() at [COORD(src)]: parents=[parents ? "exists" : "null"] airs=[airs ? "exists" : "null"] - called during invalid state")
		return returned_air
	for (var/i in 1 to parents.len)
		if (parents[i] == reference)
			var/datum/gas_mixture/air = airs[i]
			if(air)
				returned_air += air
	return returned_air

/obj/machinery/atmospherics/components/pipeline_expansion(datum/pipeline/reference)
	if(reference)
		if(!parents?.len || !nodes?.len)
			return list()
		var/index = parents.Find(reference)
		if(!index || index > nodes.len)
			return list()
		return list(nodes[index])
	return ..()

/obj/machinery/atmospherics/components/setPipenet(datum/pipeline/reference, obj/machinery/atmospherics/A)
	if(!parents?.len || !nodes?.len)
		return
	var/index = nodes.Find(A)
	if(!index || index > parents.len)
		return
	parents[index] = reference

/obj/machinery/atmospherics/components/returnPipenet(obj/machinery/atmospherics/A = nodes[1]) //returns parents[1] if called without argument
	if(!parents?.len || !nodes?.len)
		return null
	var/index = nodes.Find(A)
	if(!index || index > parents.len)
		return null
	return parents[index]

/obj/machinery/atmospherics/components/replacePipenet(datum/pipeline/Old, datum/pipeline/New)
	if(!parents?.len)
		return
	for(var/index in 1 to parents.len)
		if(parents[index] == Old)
			parents[index] = New

/obj/machinery/atmospherics/components/unsafe_pressure_release(var/mob/user, var/pressures)
	..()

	var/turf/T = get_turf(src)
	if(T)
		//Remove the gas from airs and assume it
		var/datum/gas_mixture/environment = T.return_air()
		var/lost = null
		var/times_lost = 0
		for(var/i in 1 to device_type)
			var/datum/gas_mixture/air = airs[i]
			lost += pressures*environment.return_volume()/(air.return_temperature() * R_IDEAL_GAS_EQUATION)
			times_lost++
		var/shared_loss = lost/times_lost

		for(var/i in 1 to device_type)
			var/datum/gas_mixture/air = airs[i]
			T.assume_air_moles(air, shared_loss)
		air_update_turf(TRUE)

/obj/machinery/atmospherics/components/proc/safe_input(var/title, var/text, var/default_set)
	var/new_value = input(usr,text,title,default_set) as num
	if(usr.canUseTopic(src))
		return new_value
	return default_set

// Helpers

/**
 * Called in most atmos processes and gas handling situations, update the parents pipelines of the devices connected to the source component
 * This way gases won't get stuck
 */
/obj/machinery/atmospherics/components/proc/update_parents()
	if(!SSair.initialized)
		return
	for(var/i in 1 to device_type)
		var/datum/pipeline/parent = parents[i]
		if(!parent)
			investigate_log("[type] at [COORD(src)] is missing a pipenet, rebuilding", INVESTIGATE_ATMOS)
			SSair.add_to_rebuild_queue(src)
		else
			parent.update = TRUE

/obj/machinery/atmospherics/components/returnPipenets()
	. = list()
	for(var/i in 1 to device_type)
		. += returnPipenet(nodes[i])

// UI Stuff

/obj/machinery/atmospherics/components/ui_status(mob/user)
	if(allowed(user))
		return ..()
	to_chat(user, "<span class='danger'>Доступ запрещён.</span>")
	return UI_CLOSE

// Tool acts

/obj/machinery/atmospherics/components/return_analyzable_air()
	return airs

/obj/machinery/atmospherics/components/attack_ghost(mob/dead/observer/O)
	. = ..()
	atmosanalyzer_scan(airs, O, src, FALSE)

// Tool acts


/obj/machinery/atmospherics/components/analyzer_act(mob/living/user, obj/item/I)
	atmosanalyzer_scan(airs, user, src)
	return TRUE

/// Disconnects from pipenets, re-runs atmosinit, and rebuilds pipeline membership. Used after assembly or rotation.
/obj/machinery/atmospherics/components/proc/reconnect_nodes()
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		if(node)
			if(src in node.nodes)
				node.disconnect(src)
			nodes[i] = null
		if(parents[i])
			nullifyPipenet(parents[i])
	if(!SSair.initialized)
		return
	atmosinit()
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		if(node)
			node.atmosinit()
			node.addMember(src)
	build_network()
	update_icon()

/obj/machinery/atmospherics/components/default_change_direction_wrench(mob/user, obj/item/I)
	if(!..())
		return FALSE
	SetInitDirections()
	reconnect_nodes()
	return TRUE

/obj/machinery/atmospherics/components/proc/crowbar_deconstruction_act(mob/living/user, obj/item/tool, internal_pressure = 0)
	if(!panel_open)
		balloon_alert(user, "open the panel first!")
		return TRUE

	var/unsafe_wrenching = FALSE
	var/filled_pipe = FALSE
	var/datum/gas_mixture/environment_air = loc.return_air()

	for(var/i in 1 to device_type)
		var/datum/gas_mixture/inside_air = airs[i]
		if(inside_air?.total_moles() > 0 || internal_pressure)
			filled_pipe = TRUE
		if(nodes[i])
			internal_pressure = max(internal_pressure, airs[i].return_pressure())

	if(!filled_pipe)
		return default_deconstruction_crowbar(tool)

	to_chat(user, span_notice("You begin to unfasten \the [src]..."))

	if(environment_air)
		internal_pressure -= environment_air.return_pressure()

	if(internal_pressure > 2 * ONE_ATMOSPHERE)
		to_chat(user, span_warning("As you begin deconstructing \the [src] a gush of air blows in your face... maybe you should reconsider?"))
		unsafe_wrenching = TRUE

	if(!do_after(user, 2 SECONDS, src))
		return TRUE
	if(unsafe_wrenching)
		unsafe_pressure_release(user, internal_pressure)
	tool.play_tool_sound(src, 50)
	deconstruct(TRUE)
	return TRUE

// IMPORTANT: Call parent FIRST because parent's nullifyNode() accesses parents[] and airs[]
// Do NOT change this order to match child classes - they clean up different vars
/obj/machinery/atmospherics/components/Destroy()
	. = ..()
	parents = null
	QDEL_LIST(airs)
