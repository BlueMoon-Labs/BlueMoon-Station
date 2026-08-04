// Regression tests for the rendering side of the atmos/engineering branch.
// A missing icon_state costs nothing at compile time and shows up in game as a
// silently invisible overlay, which is exactly how the firelock alarm lamps and
// the omni collector ports shipped broken the first time around.

/// Every firelock variant draws the same alarm lamp overlays out of its own
/// icon file. A subtype pointed at an icon without them loses the entire
/// readout, and nothing anywhere complains.
/datum/unit_test/firelock_alarm_lamp_states/Run()
	var/list/required = list(FIRELOCK_ALARM_TYPE_HOT, FIRELOCK_ALARM_TYPE_COLD, FIRELOCK_ALARM_TYPE_GENERIC)
	var/checked = 0
	for(var/obj/machinery/door/firedoor/firelock as anything in typesof(/obj/machinery/door/firedoor))
		var/icon_file = initial(firelock.icon)
		if(!icon_file)
			continue
		checked++
		var/list/present = icon_states(icon_file)
		for(var/state in required)
			TEST_ASSERT(state in present, "[firelock]: [icon_file] has no '[state]', its alarm lamps would never draw")
	TEST_ASSERT(checked >= 4, "expected several firelock subtypes to check, found [checked]")

/// The omni devices compose themselves out of a base plate, a centre glyph and
/// one overlay per port role, in lit and unlit flavours. Collector ports get
/// their own pair so a filter side cannot be mistaken for a plain output.
/datum/unit_test/omni_device_overlay_states/Run()
	var/obj/machinery/atmospherics/components/quaternary/reference = /obj/machinery/atmospherics/components/quaternary
	var/icon_file = initial(reference.icon)
	var/list/present = icon_states(icon_file)
	var/list/required = list("base")
	for(var/glyph in list("filter", "mixer"))
		required += list(glyph, "[glyph]_glow")
	for(var/side in list("north", "south", "east", "west"))
		for(var/role in list("in", "out", "filter"))
			required += list("[side]_[role]", "[side]_[role]_glow")
	for(var/state in required)
		TEST_ASSERT(state in present, "[icon_file] has no '[state]'")

	// The whole point of the collector pair: an output port and a filter port on
	// the same side must not be the same picture. Comparing the /icon datums
	// themselves would compare references, so walk the pixels.
	var/icon/sheet = icon(icon_file)
	var/differing_pixels = 0
	for(var/x in 1 to sheet.Width())
		for(var/y in 1 to sheet.Height())
			if(sheet.GetPixel(x, y, "north_out") != sheet.GetPixel(x, y, "north_filter"))
				differing_pixels++
	TEST_ASSERT(differing_pixels, "omni collector port is a pixel copy of the plain output port")

/// Layer-shifted devices need one map sprite per piping layer, and every layer
/// this codebase supports has to be covered - the sprites were ported from a
/// five-layer upstream where the indices do not line up.
/datum/unit_test/atmos_device_map_states/Run()
	var/list/families = list(
		/obj/machinery/atmospherics/components/binary/pressure_valve = "pvalve",
		/obj/machinery/atmospherics/components/binary/temperature_pump = "tpump",
		/obj/machinery/atmospherics/components/binary/temperature_gate = "tgate",
	)
	for(var/obj/machinery/atmospherics/components/binary/device_type as anything in families)
		var/prefix = families[device_type]
		var/list/present = icon_states(initial(device_type.icon))
		for(var/layer in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
			TEST_ASSERT("[prefix]_map-[layer]" in present, "[device_type]: no map sprite for piping layer [layer]")
		// The lane is PIPING_LAYER_SHIFT's job, so the runtime body is a single
		// sprite; only the variant the code actually names has to exist.
		TEST_ASSERT("[prefix]_off-[SENSOR_VALVE_BODY_OFFSET]" in present, "[device_type]: no unlit body sprite")
		TEST_ASSERT("[prefix]_on-[SENSOR_VALVE_BODY_OFFSET]" in present, "[device_type]: no lit body sprite")

	var/obj/machinery/atmospherics/pipe/bridge_pipe/bridge_type = /obj/machinery/atmospherics/pipe/bridge_pipe
	var/list/bridge_states = icon_states(initial(bridge_type.icon))
	TEST_ASSERT(initial(bridge_type.pipe_state) in icon_states('icons/obj/atmospherics/pipes/pipe_item.dmi'), "bridge pipe fitting has no item sprite")
	for(var/layer in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
		TEST_ASSERT("bridge_map-[layer]" in bridge_states, "bridge pipe has no map sprite for piping layer [layer]")

/// The layer adapter is the one fitting whose housing has to be as wide as the
/// number of piping layers. Its stubs are drawn at PIPING_LAYER_SHIFT's pixel
/// offsets, so a housing still drawn for three lanes leaves the outer two
/// hanging in mid-air next to it - which is exactly how it shipped when the
/// codebase went from three layers to five. Missing icon_states cannot catch
/// this: the states are all present, they are just too narrow.
/datum/unit_test/atmos_layer_adapter_housing_width/Run()
	var/obj/machinery/atmospherics/pipe/layer_manifold/adapter = /obj/machinery/atmospherics/pipe/layer_manifold
	var/adapter_icon = initial(adapter.icon)

	// Where a stub actually sits on an unshifted tile, measured off the stub
	// sprite rather than assumed, so the check keeps tracking the art.
	var/icon/stub = icon(adapter_icon, "pipe", SOUTH)
	var/stub_left = 0
	var/stub_right = 0
	for(var/x in 1 to stub.Width())
		if(!unit_test_icon_column_has_ink(stub, x))
			continue
		if(!stub_left)
			stub_left = x
		stub_right = x
	TEST_ASSERT(stub_left, "[adapter_icon] state 'pipe' is blank, the adapter has no stub to draw")
	var/stub_centre = round((stub_left + stub_right) / 2)

	// The mapped housing, the housing the machine actually wears once built, and
	// the fitting sprite the RPD hands out - all three are the same picture and
	// all three were left at three lanes.
	check_housing_width(adapter_icon, initial(adapter.icon_state), stub_centre)
	check_housing_width(adapter_icon, "manifoldlayer_center", stub_centre)
	check_housing_width('icons/obj/atmospherics/pipes/pipe_item.dmi', initial(adapter.pipe_state), stub_centre)

/datum/unit_test/atmos_layer_adapter_housing_width/proc/check_housing_width(housing_icon, state, stub_centre)
	var/icon/housing = icon(housing_icon, state, SOUTH)
	for(var/piping in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
		var/column = stub_centre + (piping - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_X
		TEST_ASSERT(unit_test_icon_column_has_ink(housing, column),
			"[housing_icon] state '[state]' is blank at x=[column], where layer [piping] connects - the housing is narrower than the layers it bridges")

/// Whether an icon has any non-transparent pixel in the given 1-based column.
/proc/unit_test_icon_column_has_ink(icon/sheet, x)
	if(x < 1 || x > sheet.Width())
		return FALSE
	for(var/y in 1 to sheet.Height())
		if(sheet.GetPixel(x, y))
			return TRUE
	return FALSE

/// A heat exchanging pipe is a fifteen-pixel ribbed band, and five lanes five
/// pixels apart need 15 + 4*5 = 35 pixels of a 32 pixel tile, so the per-layer
/// frames baked into the sheet cannot hold the outer two lanes - the sheet just
/// crops them. The lane now comes from a pixel offset at runtime, which nothing
/// crops. This pins the substitution: the centre frame moved by the offset must
/// land exactly on the baked frame, for every layer the sheet does carry, so the
/// pipes that already existed on the station cannot have moved a pixel.
/datum/unit_test/he_pipe_runtime_offset_matches_baked_art/Run()
	var/sheet_icon = 'icons/obj/atmospherics/pipes/he-simple.dmi'
	// The junction is deliberately excluded: its baked frames also slide the fork
	// along the pipe, which the runtime offset does not reproduce - and must not,
	// the fork has no business moving with the layer.
	for(var/piping in PIPING_LAYER_MIN + 1 to PIPING_LAYER_MAX - 1)
		// Every state, along both axes the lane can run.
		for(var/prefix in list("pipe11", "pipe10", "pipe01", "pipe00", "broken"))
			check_offset_matches(sheet_icon, prefix, piping, SOUTH)
			check_offset_matches(sheet_icon, prefix, piping, EAST)
		// Diagonals only for the connected run. The sheet's diagonal frames for
		// the free-end caps and the broken pipe were never consistent shifts of
		// each other to begin with - broken-4 does not even move in x where
		// broken-3 did - so there is nothing there to preserve.
		check_offset_matches(sheet_icon, "pipe11", piping, NORTHEAST)

/datum/unit_test/he_pipe_runtime_offset_matches_baked_art/proc/check_offset_matches(sheet_icon, prefix, piping, checked_dir)
	// The same two branches PIPING_LAYER_SHIFT takes, so the test cannot agree
	// with a broken macro by copying it.
	var/offset_x = (checked_dir & (NORTH|SOUTH)) ? (piping - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_X : 0
	var/offset_y = (checked_dir & (EAST|WEST)) ? (piping - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_Y : 0
	var/icon/centred = icon(sheet_icon, "[prefix]-[PIPING_LAYER_DEFAULT]", checked_dir)
	var/icon/baked = icon(sheet_icon, "[prefix]-[piping]", checked_dir)
	for(var/x in 1 to centred.Width())
		for(var/y in 1 to centred.Height())
			var/shifted_x = x + offset_x
			var/shifted_y = y + offset_y
			if(shifted_x < 1 || shifted_x > baked.Width() || shifted_y < 1 || shifted_y > baked.Height())
				continue
			TEST_ASSERT_EQUAL(centred.GetPixel(x, y), baked.GetPixel(shifted_x, shifted_y),
				"[sheet_icon] '[prefix]' layer [piping] dir [checked_dir]: the centre frame offset by [offset_x],[offset_y] does not match the baked frame at [shifted_x],[shifted_y]")

/// The straight pipe and the junction take their lane from a pixel offset, so
/// every layer is theirs. The manifolds cannot: their body shifts on both axes
/// at once and their stubs have to stretch to the tile edge rather than merely
/// move, so they keep the layers their sheet was drawn for.
/datum/unit_test/he_pipe_layer_reach/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	for(var/piping in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
		var/obj/machinery/atmospherics/pipe/heat_exchanging/simple/straight = allocate(/obj/machinery/atmospherics/pipe/heat_exchanging/simple, room)
		straight.setDir(SOUTH)
		straight.setPipingLayer(piping)
		TEST_ASSERT_EQUAL(straight.piping_layer, piping, "a straight heat exchanging pipe refused layer [piping]")
		TEST_ASSERT(straight.icon_state in icon_states(straight.icon),
			"a straight heat exchanging pipe on layer [piping] draws missing sprite '[straight.icon_state]'")
		// Facing south the lane is horizontal, and it has to be the same lane a
		// plain pipe of that layer occupies or the two would not line up.
		TEST_ASSERT_EQUAL(straight.pixel_x, (piping - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_X,
			"a straight heat exchanging pipe on layer [piping] sits at pixel_x [straight.pixel_x]")
		TEST_ASSERT_EQUAL(straight.pixel_y, 0, "a north-south heat exchanging pipe was pushed along its own run")

		var/obj/machinery/atmospherics/pipe/heat_exchanging/manifold/branch = allocate(/obj/machinery/atmospherics/pipe/heat_exchanging/manifold, room)
		branch.setPipingLayer(piping)
		TEST_ASSERT(branch.piping_layer >= PIPING_LAYER_MIN + 1 && branch.piping_layer <= PIPING_LAYER_MAX - 1,
			"a heat exchanging manifold accepted layer [piping] and landed on [branch.piping_layer]")

		// The fitting in hand has to end up wherever the machine it becomes does.
		var/obj/item/pipe/manifold_fitting = allocate(/obj/item/pipe/trinary, room, /obj/machinery/atmospherics/pipe/heat_exchanging/manifold, SOUTH)
		manifold_fitting.setPipingLayer(piping)
		TEST_ASSERT_EQUAL(manifold_fitting.piping_layer, branch.piping_layer,
			"the manifold fitting and the manifold it builds disagree about where layer [piping] ends up")

/// Turning a pipe moves its lane to the other axis, and the offset it had on the
/// old one has to go away with it.
/datum/unit_test/he_pipe_offset_follows_rotation/Run()
	var/obj/machinery/atmospherics/pipe/heat_exchanging/simple/straight = allocate(/obj/machinery/atmospherics/pipe/heat_exchanging/simple, run_loc_floor_bottom_left)
	straight.setDir(SOUTH)
	straight.setPipingLayer(PIPING_LAYER_MIN)
	TEST_ASSERT(straight.pixel_x != 0 && straight.pixel_y == 0, "a north-south pipe took its lane on the wrong axis")

	straight.setDir(EAST)
	straight.update_icon()
	TEST_ASSERT_EQUAL(straight.pixel_x, 0, "rotating the pipe left its old horizontal offset behind")
	TEST_ASSERT(straight.pixel_y != 0, "an east-west pipe did not take its lane on the vertical axis")

/// Every RPD entry renders from its type's pipe_state; a typo there is an empty
/// tile in the dispenser menu and an invisible fitting on the floor.
/datum/unit_test/pipe_fitting_item_states/Run()
	var/list/present = icon_states('icons/obj/atmospherics/pipes/pipe_item.dmi')
	var/checked = 0
	for(var/category in GLOB.atmos_pipe_recipes)
		for(var/datum/pipe_info/recipe as anything in GLOB.atmos_pipe_recipes[category])
			if(!recipe.icon_state)
				continue
			checked++
			TEST_ASSERT(recipe.icon_state in present, "RPD entry '[recipe.name]' wants missing fitting sprite '[recipe.icon_state]'")
	TEST_ASSERT(checked > 10, "expected the atmos RPD catalogue to be populated, found [checked] entries")

/// A bridge pipe that draws in the shared pipe layer loses to whatever it is
/// supposed to be crossing on an arbitrary tie-break.
/datum/unit_test/bridge_pipe_rides_over/Run()
	var/obj/machinery/atmospherics/pipe/bridge_pipe/bridge = allocate(/obj/machinery/atmospherics/pipe/bridge_pipe)
	var/obj/machinery/atmospherics/pipe/simple/crossed = allocate(/obj/machinery/atmospherics/pipe/simple)
	bridge.update_icon()
	crossed.update_icon()
	TEST_ASSERT(bridge.layer > crossed.layer, "bridge pipe draws at [bridge.layer], not above the ordinary pipe at [crossed.layer]")

/// Turf gas visuals collapse a mixture into a single overlay. It has to be the
/// dominant gas's own sprite: plasma, tritium and water vapour declare no color
/// at all, so a neutral shared cloud would strip the mixture of every cue.
/datum/unit_test/turf_gas_visual_dominant_gas/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/datum/gas_mixture/saved_air = room.air
	var/list/saved_overlays = room.atmos_overlay_types

	room.air = new /datum/gas_mixture(CELL_VOLUME)
	room.atmos_overlay_types = null
	room.air.set_moles(GAS_PLASMA, MOLES_GAS_VISIBLE * 12)
	room.air.set_moles(GAS_TRITIUM, MOLES_GAS_VISIBLE * 2)
	room.air.set_temperature(T20C)
	room.update_visuals()

	var/list/chosen = room.atmos_overlay_types
	TEST_ASSERT_EQUAL(length(chosen), 1, "a mixture of visible gases produced [length(chosen)] overlays instead of one")
	var/obj/effect/overlay/gas/cloud = chosen[1]
	var/datum/gas/plasma_gas = GLOB.gas_data.datums[GAS_PLASMA]
	TEST_ASSERT_EQUAL(cloud.icon_state, initial(plasma_gas.gas_overlay), "the plasma-dominated mixture did not draw plasma's own cloud")

	// Flip the balance: the trace gas that is furthest past its own visibility
	// threshold owns the tile, regardless of raw mole counts.
	room.atmos_overlay_types = null
	room.air.set_moles(GAS_PLASMA, MOLES_GAS_VISIBLE * 1.1)
	room.air.set_moles(GAS_TRITIUM, MOLES_GAS_VISIBLE * 30)
	room.update_visuals()
	var/obj/effect/overlay/gas/tritium_cloud = room.atmos_overlay_types[1]
	var/datum/gas/tritium_gas = GLOB.gas_data.datums[GAS_TRITIUM]
	TEST_ASSERT_EQUAL(tritium_cloud.icon_state, initial(tritium_gas.gas_overlay), "the tritium-dominated mixture did not draw tritium's own cloud")

	room.set_visuals(null)
	room.air = saved_air
	room.atmos_overlay_types = saved_overlays

/// A settled cloud recomputes the same overlay every SSair cycle, so
/// update_visuals returns early once it finds the result unchanged. The early
/// exit must leave the tile in exactly the state the full path would have: same
/// overlay recorded, same single entry in vis_contents, and it must not swallow
/// a change when the mixture actually moves to another rung of the ladder.
/datum/unit_test/turf_gas_visual_unchanged_is_stable/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/datum/gas_mixture/saved_air = room.air
	var/list/saved_overlays = room.atmos_overlay_types
	room.set_visuals(null)

	room.air = new /datum/gas_mixture(CELL_VOLUME)
	room.air.set_moles(GAS_PLASMA, MOLES_GAS_VISIBLE * 3)
	room.air.set_temperature(T20C)
	room.update_visuals()

	var/list/first = room.atmos_overlay_types
	TEST_ASSERT_EQUAL(length(first), 1, "a single visible gas produced [length(first)] overlays instead of one")
	var/obj/effect/overlay/gas/cloud = first[1]
	var/overlay_count = 0
	for(var/entry in room.vis_contents)
		if(entry == cloud)
			overlay_count++
	TEST_ASSERT_EQUAL(overlay_count, 1, "the overlay appears [overlay_count] times in vis_contents after the first update")

	// Idle cycles: nothing about the tile may drift.
	for(var/i in 1 to 5)
		room.update_visuals()
	TEST_ASSERT_EQUAL(length(room.atmos_overlay_types), 1, "repeated updates left [length(room.atmos_overlay_types)] overlays recorded")
	TEST_ASSERT(room.atmos_overlay_types[1] == cloud, "repeated updates swapped the overlay of an unchanged mixture")
	overlay_count = 0
	for(var/entry in room.vis_contents)
		if(entry == cloud)
			overlay_count++
	TEST_ASSERT_EQUAL(overlay_count, 1, "repeated updates left [overlay_count] copies of the overlay in vis_contents")

	// A real change must still get through: enough plasma to climb the ladder.
	room.air.set_moles(GAS_PLASMA, MOLES_GAS_VISIBLE + MOLES_GAS_VISIBLE_STEP * (FACTOR_GAS_VISIBLE_MAX + 1))
	room.update_visuals()
	var/obj/effect/overlay/gas/denser = room.atmos_overlay_types[1]
	TEST_ASSERT(denser != cloud, "a mixture dense enough to change rungs kept the thin overlay")

	// And so must the mixture becoming invisible again.
	room.air.set_moles(GAS_PLASMA, 0)
	room.air.set_moles(GAS_N2, MOLES_N2STANDARD)
	room.update_visuals()
	TEST_ASSERT(!length(room.atmos_overlay_types), "the overlay survived the visible gas leaving the tile")

	room.set_visuals(null)
	room.air = saved_air
	room.atmos_overlay_types = saved_overlays
