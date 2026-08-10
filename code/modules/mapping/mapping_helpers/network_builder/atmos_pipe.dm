/* Automatically places pipes on init based on any pipes connecting to it and adjacent helpers. Only supports cardinals.
 * Conflicts with ANY PIPE ON ITS LAYER, as well as atmos network build helpers on the same layer, as well as any pipe on all layers. Do those manually.
*/
/obj/effect/mapping_helpers/network_builder/atmos_pipe
	name = "atmos pipe autobuilder"
	icon_state = "manifold4w-2"
	layer = GAS_PIPE_HIDDEN_LAYER
	color = null
	level = 1
	/// Layer to put our pipes on
	var/piping_layer = PIPING_LAYER_DEFAULT
	/// Color to set our pipes to
	var/pipe_color
	// Whether or not pipes we make are visible
	// var/visible_pipes = TRUE
	/**
	 * Helper will try to create exact pipe type if possible. if not - will create default one with needed properties.
	 * It is desirable to do so, because some pipe procs try to set initial() type values.
	 */
	var/pipe_type = null
	/// pipes with different color won't connect even on the same piping_layer.
	/// EXCEPT "GREY (GENERAL) PIPES". General pipes are like wildcards and will connect to every other color.
	var/static/list/check_color_difference = list(	/obj/machinery/atmospherics/pipe/simple,
													/obj/machinery/atmospherics/pipe/manifold,
													/obj/machinery/atmospherics/pipe/manifold4w)

/obj/effect/mapping_helpers/network_builder/atmos_pipe/check_duplicates()
	for(var/obj/effect/mapping_helpers/network_builder/atmos_pipe/other in loc)
		if(other == src)
			continue
		if(other.piping_layer == piping_layer)
			if((other.color == color) || isnull(other.color) || isnull(color))
				return other // we can't check if those pipes will be with the same dir so be wary, this check won't save you from it.
	for(var/obj/machinery/atmospherics/A in loc)
		if(A.pipe_flags & PIPING_ALL_LAYER)
			return A
		if(A.piping_layer == piping_layer)
			if(!is_type_in_list(A, check_color_difference) || (A.color == color) || isnull(A.color) || isnull(color))
				return A // we can't check if those pipes will be with the same dir so be wary, this check won't save you from it.
	return FALSE

/// Scans directions, sets network_directions to have every direction that we can link to. If there's another power cable builder detected, make sure they know we're here by adding us to their cable directions list before we're deleted.
/obj/effect/mapping_helpers/network_builder/atmos_pipe/scan_directions()
	var/turf/T
	for(var/i in GLOB.cardinals)
		if(i in network_directions)
			continue				//we're already set, that means another builder set us.
		T = get_step(loc, i)
		if(!T)
			continue
		var/found = FALSE
		for(var/obj/effect/mapping_helpers/network_builder/atmos_pipe/other in T)
			if(other.piping_layer == piping_layer)
				if((other.color == color) || isnull(other.color) || isnull(color))
					network_directions += i
					other.network_directions += turn(i, 180)
					found = TRUE
					break
		if(found)
			continue
		for(var/obj/machinery/atmospherics/A in T)
			// we can't do /connection_check() since we don't have a pipe yet
			if(((A.piping_layer == piping_layer) || (A.pipe_flags & PIPING_ALL_LAYER)) && (istype(A, /obj/machinery/atmospherics/pipe/simple/multiz) || (A.initialize_directions & turn(i, 180)))) // (A.initialize_directions & get_dir(A, src)) perhaps?
				if(!is_type_in_list(A, check_color_difference) || (A.color == color) || isnull(A.color) || isnull(color))
					network_directions += i
					break
	return network_directions

/// Directions should only ever have cardinals.
/obj/effect/mapping_helpers/network_builder/atmos_pipe/build_network()
	if(length(network_directions) <= 0)
		return
	/**
	 * During process down below this proc will try to create exact pipe type if its path exists.
	 * It is desirable to do so, because some pipe procs try to set initial() type values.
	 * All those pipe paths are currently created in mapping.dm helpers like "HELPER(green, rgb(30, 255, 0))" or "HELPER_NAMED(supply, "air supply pipe", rgb(0, 0, 255))".
	 * It works now and presumably won't create any critical problems even after possible major pipe types reworks.
	 * If any major pipe types reworks have been occured you have to edit this algorithm of exact path creation.
	 * Otherwise this proc will create default pipes. This might not create major problems. Or will. I'm not responsible for this.
	 */
	pipe_type = "/obj/machinery/atmospherics/pipe" // will become path later
	var/pipe_color_new = null
	if(isnull(color))
		pipe_color_new = "general"  // check HELPER(general, null) in mapping.dm
	else
		for(var/i in GLOB.pipe_paint_colors)
			if((GLOB.pipe_paint_colors[i] == color))
				switch(i) // check HELPER_NAMED() in mapping.dm
					if("red")
						pipe_color_new = "scrubbers"
					if("blue")
						pipe_color_new = "supply"
					if("amethyst")
						pipe_color_new = "supplymain"
					else
						pipe_color_new = i
				break
	if(isnull(pipe_color_new))
		pipe_type = null
	var/visible_or_hidden = level == PIPE_VISIBLE_LEVEL ? "visible" : "hidden"
	// You may comment code above if it creates issues. Check description above it.
	var/obj/machinery/atmospherics/pipe/built
	switch(length(network_directions))
		if(1)
			pipe_type = "[pipe_type]/simple/[pipe_color_new]/[visible_or_hidden][piping_layer != 2 ? "/[piping_layer]" : "" ]"
			pipe_type = text2path(pipe_type)
			built = ispath(pipe_type) ? new pipe_type(loc) : new /obj/machinery/atmospherics/pipe/simple(loc)
			built.setDir(network_directions[1])
		if(2)		//straight pipe
			pipe_type = "[pipe_type]/simple/[pipe_color_new]/[visible_or_hidden][piping_layer != 2 ? "/[piping_layer]" : "" ]"
			pipe_type = text2path(pipe_type)
			built = ispath(pipe_type) ? new pipe_type(loc) : new /obj/machinery/atmospherics/pipe/simple(loc)
			var/d1 = network_directions[1]
			var/d2 = network_directions[2]
			var/combined = d1 | d2
			if(combined in GLOB.diagonals)
				built.setDir(combined)
			else
				built.setDir(d1)
		if(3)		//manifold
			var/list/missing = network_directions ^ GLOB.cardinals
			missing = missing[1]
			pipe_type = "[pipe_type]/manifold/[pipe_color_new]/[visible_or_hidden][piping_layer != 2 ? "/[piping_layer]" : "" ]"
			pipe_type = text2path(pipe_type)
			built = ispath(pipe_type) ? new pipe_type(loc) : new /obj/machinery/atmospherics/pipe/manifold(loc)
			built.setDir(missing)
		if(4)		//4 way manifold
			pipe_type = "[pipe_type]/manifold4w/[pipe_color_new]/[visible_or_hidden][piping_layer != 2 ? "/[piping_layer]" : "" ]"
			pipe_type = text2path(pipe_type)
			built = ispath(pipe_type) ? new pipe_type(loc) : new /obj/machinery/atmospherics/pipe/manifold4w(loc)
	built.SetInitDirections()
	if(isnull(pipe_type)) // we didn't find exact pipe type so we have to set its properties
		built.name = name
		// built.on_construction(pipe_color, piping_layer, level) // runtimes! because it tries to connect to vent pumps and otther machines too early!
		built.add_atom_colour(pipe_color, FIXED_COLOUR_PRIORITY)
		built.pipe_color = pipe_color
		built.level = level
		built.layer = layer
		built.setPipingLayer(piping_layer)
		// var/turf/T = get_turf(built)
		// built.atmosinit()
		// var/list/nodes = built.pipeline_expansion()
		// for(var/obj/machinery/atmospherics/A in built.nodes)
		// 	A.atmosinit()
		// 	A.addMember(src)
		// built.build_network()
		// built.hide(!visible_pipes)
	for(var/obj/machinery/meter/M in built.loc) // those things are being initialized before we create pipes.
		if(!M.target)
			M.reattach_to_layer()
