/// Paint decides connections now: two pipes wearing different colours ignore
/// each other, with grey staying universal so the RPD default and every
/// unpainted device still join whatever they are laid against.

/// The rule itself, on pipes the test builds rather than on whatever the map
/// happens to contain.
/datum/unit_test/atmos_pipe_paint_rule/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/turf/open/east = locate(room.x + 1, room.y, room.z)
	TEST_ASSERT(istype(east), "test location has no open turf to its east")

	var/obj/machinery/atmospherics/pipe/simple/left = allocate(/obj/machinery/atmospherics/pipe/simple, room)
	var/obj/machinery/atmospherics/pipe/simple/right = allocate(/obj/machinery/atmospherics/pipe/simple, east)
	left.setDir(EAST)
	right.setDir(EAST)
	left.SetInitDirections()
	right.SetInitDirections()

	var/red = GLOB.pipe_paint_colors["red"]
	var/blue = GLOB.pipe_paint_colors["blue"]
	var/grey = GLOB.pipe_paint_colors["grey"]

	left.pipe_color = red
	right.pipe_color = red
	TEST_ASSERT(left.connection_check(right, left.piping_layer), "two red pipes refused to connect")

	right.pipe_color = blue
	TEST_ASSERT(!left.connection_check(right, left.piping_layer), "a red pipe connected to a blue one")
	TEST_ASSERT(!right.connection_check(left, right.piping_layer), "the paint rule is not symmetric")

	right.pipe_color = grey
	TEST_ASSERT(left.connection_check(right, left.piping_layer), "a red pipe refused a grey one")

	// Mapped uncoloured pipes carry no colour at all rather than the grey hex,
	// and that has to read the same way, or every /general pipe on every station
	// falls off its network.
	right.pipe_color = null
	TEST_ASSERT(left.connection_check(right, left.piping_layer), "a red pipe refused an unpainted one")

	// The layer rule still applies on top of the colour one.
	right.pipe_color = red
	right.piping_layer = left.piping_layer + 1
	TEST_ASSERT(!left.connection_check(right, left.piping_layer), "same-colour pipes connected across piping layers")

/// Every piping layer the codebase offers needs a fitting that can actually be
/// placed on it, otherwise the RPD hands out an invisible pipe.
/datum/unit_test/atmos_pipe_layer_range/Run()
	TEST_ASSERT_EQUAL(PIPING_LAYER_MIN, 1, "piping layers no longer start at 1")
	TEST_ASSERT_EQUAL(PIPING_LAYER_MAX, 5, "the piping layer count changed without the sprites following")
	TEST_ASSERT(PIPING_LAYER_DEFAULT > PIPING_LAYER_MIN && PIPING_LAYER_DEFAULT < PIPING_LAYER_MAX,
		"the default piping layer is not the middle one, so pipes would not be centred on their tile")

	var/turf/open/room = run_loc_floor_bottom_left
	for(var/layer in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
		var/obj/item/pipe/fitting = allocate(/obj/item/pipe/binary/bendable, room, /obj/machinery/atmospherics/pipe/simple, SOUTH)
		fitting.setPipingLayer(layer)
		TEST_ASSERT_EQUAL(fitting.piping_layer, layer, "a pipe fitting refused piping layer [layer]")
		var/obj/machinery/atmospherics/pipe/simple/built = allocate(/obj/machinery/atmospherics/pipe/simple, room)
		built.setPipingLayer(layer)
		built.update_icon()
		TEST_ASSERT(built.icon_state in icon_states(built.icon),
			"a pipe on layer [layer] draws missing sprite '[built.icon_state]'")

/// The layer adapter is the only fitting that crosses piping layers, so every
/// layer has to reach it from both sides and end up in the same pipenet. Its own
/// piping_layer stays at the default, which is why the neighbours have to be
/// found by walking the whole range rather than by matching against it.
/datum/unit_test/atmos_layer_adapter_bridges_every_layer/Run()
	// The reservation is a 5x5 block whose bottom-left corner is the run loc, so
	// the run has to be laid out northward from it rather than around it.
	var/turf/open/behind = run_loc_floor_bottom_left
	TEST_ASSERT(istype(behind), "test location is not an open turf")
	var/turf/open/room = locate(behind.x, behind.y + 1, behind.z)
	var/turf/open/ahead = locate(behind.x, behind.y + 2, behind.z)
	TEST_ASSERT(istype(room) && istype(ahead), "the test reservation has no three-tile column to build the adapter run in")

	var/obj/machinery/atmospherics/pipe/layer_manifold/adapter = allocate(/obj/machinery/atmospherics/pipe/layer_manifold, room)
	adapter.setDir(SOUTH)
	adapter.SetInitDirections()

	for(var/piping in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
		for(var/turf/open/side as anything in list(ahead, behind))
			var/obj/machinery/atmospherics/pipe/simple/branch = allocate(/obj/machinery/atmospherics/pipe/simple, side)
			branch.setDir(NORTH)
			branch.SetInitDirections()
			branch.setPipingLayer(piping)

	adapter.findAllConnections()

	// front_nodes/back_nodes keep one slot per layer and leave misses null, so
	// index by what was actually found rather than by slot position.
	var/list/reached_ahead = new /list(PIPING_LAYER_MAX)
	var/list/reached_behind = new /list(PIPING_LAYER_MAX)
	for(var/obj/machinery/atmospherics/node in adapter.front_nodes)
		reached_ahead[node.piping_layer] = node
	for(var/obj/machinery/atmospherics/node in adapter.back_nodes)
		reached_behind[node.piping_layer] = node

	var/list/expansion = adapter.pipeline_expansion()
	for(var/piping in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
		TEST_ASSERT(reached_ahead[piping], "the layer adapter found nothing on layer [piping] ahead of it")
		TEST_ASSERT(reached_behind[piping], "the layer adapter found nothing on layer [piping] behind it")
		TEST_ASSERT(reached_ahead[piping] in expansion, "layer [piping] ahead of the adapter is not part of its pipenet")
		TEST_ASSERT(reached_behind[piping] in expansion, "layer [piping] behind the adapter is not part of its pipenet")

	// One stub overlay per connected layer per side.
	adapter.update_icon()
	var/expected_stubs = (PIPING_LAYER_MAX - PIPING_LAYER_MIN + 1) * 2
	TEST_ASSERT_EQUAL(length(adapter.overlays), expected_stubs,
		"the layer adapter drew [length(adapter.overlays)] stubs for [expected_stubs] connected pipes")

/// Two adapters facing each other carry the whole stack across, so the joint has
/// to show every layer. The neighbour has no piping_layer of its own to read -
/// it sits in all of them - and reading one anyway drew a single pipe for the
/// entire stack.
/datum/unit_test/atmos_layer_adapter_joins_another_adapter/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/turf/open/ahead = locate(room.x, room.y + 1, room.z)
	TEST_ASSERT(istype(ahead), "test location has no open turf to its north")

	var/obj/machinery/atmospherics/pipe/layer_manifold/near = allocate(/obj/machinery/atmospherics/pipe/layer_manifold, room)
	var/obj/machinery/atmospherics/pipe/layer_manifold/far = allocate(/obj/machinery/atmospherics/pipe/layer_manifold, ahead)
	for(var/obj/machinery/atmospherics/pipe/layer_manifold/adapter as anything in list(near, far))
		adapter.setDir(SOUTH)
		adapter.SetInitDirections()

	near.findAllConnections()

	// front_nodes look along dir, so the neighbour to the north lands in back_nodes.
	for(var/piping in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
		TEST_ASSERT(near.back_nodes[piping] == far, "layer [piping] does not reach the adapter across the joint")

	near.update_icon()
	TEST_ASSERT_EQUAL(length(near.overlays), PIPING_LAYER_MAX - PIPING_LAYER_MIN + 1,
		"the adapter drew [length(near.overlays)] stubs toward its neighbouring adapter instead of one per layer")

/// The maps predate the paint rule. Anything on them that touches, shares a
/// layer and disagrees about colour is a pipenet that comes apart on round
/// start, silently and only for the half of the station downstream of it.
/datum/unit_test/atmos_mapped_pipe_paint_boundaries
	requires_full_map = TRUE

/datum/unit_test/atmos_mapped_pipe_paint_boundaries/Run()
	var/list/severed = list()
	for(var/obj/machinery/atmospherics/machine as anything in GLOB.machines)
		if(!istype(machine))
			continue
		var/turf/here = get_turf(machine)
		if(!here)
			continue
		for(var/direction in GLOB.cardinals)
			if(!(machine.initialize_directions & direction))
				continue
			for(var/obj/machinery/atmospherics/target in get_step(machine, direction))
				if(target == machine || target.loc == machine.loc)
					continue
				if(!(target.initialize_directions & get_dir(target, machine)))
					continue
				if(target.piping_layer != machine.piping_layer \
					&& !(target.pipe_flags & PIPING_ALL_LAYER) \
					&& !(machine.pipe_flags & PIPING_ALL_LAYER))
					continue
				if(machine.colors_connectable(target))
					continue
				severed += "[machine.type] at [AREACOORD(machine)] cannot reach [target.type] - paint differs"
	if(!length(severed))
		return
	// A whole station's worth of junctions in one failure line is unreadable;
	// the first handful is enough to find the map and the rest are in the log.
	for(var/line in severed)
		log_test("severed pipe junction: [line]")
	var/list/shown = severed.Copy(1, min(length(severed), 10) + 1)
	TEST_FAIL("[length(severed)] mapped pipe junction(s) severed by the paint rule:\n[jointext(shown, "\n")]")
