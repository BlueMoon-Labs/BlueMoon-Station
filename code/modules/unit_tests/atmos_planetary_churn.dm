// Settling tests for planetary atmos boundaries. The 2026-07-06 benchmark
// showed ~400 turfs churning forever on an empty server, concentrated in
// areas where planetary turfs meet space (ruin exteriors), where planetary
// templates meet each other, or in mixed planetary/normal rooms (necropolis).
// Each scenario below isolates one boundary type in a sealed arena and drives
// the exact SSair stage sequence: a healthy boundary must go quiet.

#define PLANETARY_CHURN_TEMPLATE_A "o2=14;n2=23;TEMP=320"
#define PLANETARY_CHURN_TEMPLATE_B "o2=22;n2=82;TEMP=293.15"
#define PLANETARY_CHURN_MAX_CYCLES 400

/datum/unit_test/planetary_churn
	priority = TEST_LONGER
	/// The inner 3x3 open turfs of the walled arena.
	var/list/turf/open/room

/// Shared-helper parent: the runner executes every subtype of /datum/unit_test,
/// so the parent itself runs as a no-op instead of tripping the base TEST_FAIL.
/datum/unit_test/planetary_churn/Run()
	return

/// Walls off the 5x5 test zone perimeter and collects the inner 3x3 room,
/// settled to its default air with no groups and nothing active.
/datum/unit_test/planetary_churn/proc/build_room()
	var/turf/base = run_loc_floor_bottom_left
	for(var/dx in 0 to 4)
		for(var/dy in 0 to 4)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			if(dx == 0 || dy == 0 || dx == 4 || dy == 4)
				T.ChangeTurf(/turf/closed/wall)
	room = list()
	for(var/dx in 1 to 3)
		for(var/dy in 1 to 3)
			var/turf/open/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT(istype(T), "inner room turf is not open at offset [dx],[dy]")
			room += T
	settle_room()

/// Resets every room turf to its default air with clear lifecycle state.
/datum/unit_test/planetary_churn/proc/settle_room()
	for(var/turf/open/T as anything in room)
		T.ImmediateCalculateAdjacentTurfs()
		T.air.copy_from_turf(T)
		if(T.excited_group)
			T.excited_group.garbage_collect()
		SSair.remove_from_active(T)
		T.atmos_cooldown = 0
		T.current_cycle = 0
		T.archived_cycle = 0

/// Marks a turf as planetary with the given template string and prebuilds the
/// shared template, mirroring what update_air_ref does for mapped turfs.
/datum/unit_test/planetary_churn/proc/make_planetary(turf/open/T, gas_string)
	T.planetary_atmos = TRUE
	T.initial_gas_mix = gas_string
	var/datum/gas_mixture/template = SSair.get_planetary_template(T)
	TEST_ASSERT_NOTNULL(template, "planetary template failed to build for [gas_string]")

/// Drives the SSair stage sequence (active turfs, then group lifecycle) until
/// the room goes fully quiet. Returns the cycle count it settled on, or 0 if
/// it was still churning after max_cycles.
/datum/unit_test/planetary_churn/proc/drive_until_settled(max_cycles = PLANETARY_CHURN_MAX_CYCLES)
	var/fire_base = SSair.times_fired + 20000
	for(var/cycle in 1 to max_cycles)
		var/fire = fire_base + cycle
		for(var/turf/open/T as anything in room)
			if(T.excited)
				T.process_cell(fire)
		for(var/datum/excited_group/group as anything in SSair.excited_groups.Copy())
			if(!length(group.turf_list & room))
				continue
			group.tick_lifecycle()
		var/still_active = FALSE
		for(var/turf/open/T as anything in room)
			if(T.excited || T.excited_group)
				still_active = TRUE
				break
		if(!still_active)
			return cycle
	return 0

/// Cleanup mirror of the corpse-rot test: nothing may leak into the shared
/// reservation state even when an assertion is about to fail.
/datum/unit_test/planetary_churn/proc/cleanup_room()
	for(var/turf/open/T as anything in room)
		if(T.excited_group)
			T.excited_group.garbage_collect()
		SSair.remove_from_active(T)
		T.planetary_atmos = FALSE
		T.atmos_cooldown = 0
		T.current_cycle = 0
		T.archived_cycle = 0
		T.air.copy_from_turf(T)
		T.update_visuals()

/// Wakes the whole room the way a disturbance would.
/datum/unit_test/planetary_churn/proc/activate_room()
	for(var/turf/open/T as anything in room)
		SSair.add_to_active(T)

/// A room mixing planetary turfs (one wall of "outdoors") with normal station
/// air must settle: the normal side drains toward the planetary template and
/// everything goes quiet. This is the necropolis-interior shape.
/datum/unit_test/planetary_churn/mixed_room/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	build_room()
	var/turf/base = run_loc_floor_bottom_left
	for(var/dy in 1 to 3)
		var/turf/open/T = locate(base.x + 1, base.y + dy, base.z)
		make_planetary(T, PLANETARY_CHURN_TEMPLATE_A)
	activate_room()
	var/settled = drive_until_settled()
	cleanup_room()
	TEST_ASSERT(settled, "mixed planetary/normal room still churning after [PLANETARY_CHURN_MAX_CYCLES] cycles")

/// A planetary turf that borders space must not become a perpetual pump
/// (template refills it, space drains it, forever). This is the space-ruin
/// exterior shape: syndicate mothership, reactor ruin, slaver base.
/datum/unit_test/planetary_churn/space_boundary/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	build_room()
	var/turf/base = run_loc_floor_bottom_left
	var/turf/gap = locate(base.x, base.y + 2, base.z)
	gap.ChangeTurf(/turf/open/space/basic)
	var/turf/open/pump = locate(base.x + 1, base.y + 2, base.z)
	make_planetary(pump, PLANETARY_CHURN_TEMPLATE_A)
	pump.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(locate(/turf/open/space) in pump.atmos_adjacent_turfs, "arena setup failed: pump turf has no space neighbor")
	activate_room()
	var/settled = drive_until_settled()
	cleanup_room()
	TEST_ASSERT(settled, "space-adjacent planetary turf still churning after [PLANETARY_CHURN_MAX_CYCLES] cycles (perpetual vent/refill pump)")

/// Two adjacent planetary turfs with different templates must not fight
/// forever: each is anchored to its own sky, so exchanging gas between them
/// is work that regenerates itself every cycle.
/datum/unit_test/planetary_churn/template_boundary/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	build_room()
	var/turf/base = run_loc_floor_bottom_left
	// Wall the room down to a 1x2 corridor so the two templates only touch
	// each other.
	for(var/turf/open/T as anything in room.Copy())
		if(T.y != base.y + 2 || T.x > base.x + 2)
			room -= T
			T.ChangeTurf(/turf/closed/wall)
	TEST_ASSERT_EQUAL(length(room), 2, "template boundary arena should be exactly 2 turfs")
	var/turf/open/left = locate(base.x + 1, base.y + 2, base.z)
	var/turf/open/right = locate(base.x + 2, base.y + 2, base.z)
	make_planetary(left, PLANETARY_CHURN_TEMPLATE_A)
	make_planetary(right, PLANETARY_CHURN_TEMPLATE_B)
	settle_room()
	activate_room()
	var/settled = drive_until_settled()
	cleanup_room()
	TEST_ASSERT(settled, "adjacent different-template planetary turfs still churning after [PLANETARY_CHURN_MAX_CYCLES] cycles")

/// Cogplate (and reebe void) keep their infinite-air planetary template only
/// on an actual Reebe z-level: mapped anywhere else (necropolis chunks,
/// clockwork ruins) they must demote to ordinary turfs instead of anchoring a
/// foreign standard-air sky inside someone else's atmosphere.
/datum/unit_test/planetary_churn/reebe_outside_reebe/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/target = run_loc_floor_bottom_left
	TEST_ASSERT(!is_reebe(target.z), "test reservation unexpectedly has ZTRAIT_REEBE")
	var/turf/open/floor/clockwork/reebe/cogplate = target.ChangeTurf(/turf/open/floor/clockwork/reebe)
	TEST_ASSERT(istype(cogplate), "ChangeTurf did not produce a cogplate")
	var/kept_planetary = cogplate.planetary_atmos
	cogplate.ChangeTurf(/turf/open/floor/plating)
	TEST_ASSERT(!kept_planetary, "cogplate kept planetary atmos outside a Reebe z-level")

/// Recalculating the adjacency of a genuinely sealed tile (fulltile window,
/// walled-in plating) must not wake it back into SSair: process_cell would
/// find no neighbors, queue another recalculation and rest, and the
/// SSair <-> SSadjacent_air bounce becomes a permanent loop that also drags
/// the tile's open neighbors awake every cycle.
/datum/unit_test/planetary_churn/sealed_turf_no_bounce/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/sealed = locate(origin.x + 1, origin.y + 1, origin.z)
	TEST_ASSERT(istype(sealed), "test location is not an open turf")
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(sealed, direction)
		TEST_ASSERT_NOTNULL(neighbor, "sealed arena neighbor missing")
		neighbor.ChangeTurf(/turf/closed/wall)
	sealed.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT_EQUAL(LAZYLEN(sealed.atmos_adjacent_turfs), 0, "walled-in tile still has adjacency")
	SSair.remove_from_active(sealed)
	SSadjacent_air.queue -= sealed

	// This is the recalculation SSadjacent_air would run after process_cell
	// queued the sealed tile: it must confirm the seal and leave it resting.
	sealed.ImmediateCalculateAdjacentTurfs()
	var/woken = (sealed in SSair.active_turfs)

	for(var/direction in GLOB.cardinals)
		get_step(sealed, direction).ChangeTurf(/turf/open/floor/plating)
	sealed.ImmediateCalculateAdjacentTurfs()
	if(sealed.excited_group)
		sealed.excited_group.garbage_collect()
	SSair.remove_from_active(sealed)
	SSadjacent_air.queue -= sealed
	sealed.atmos_cooldown = 0

	TEST_ASSERT(!woken, "recalculating a sealed tile's adjacency re-woke it (perpetual SSair <-> SSadjacent_air bounce)")

/// The share-significance gates must scale with tile content. Grouped tiles
/// share unconditionally, and in a 400 atm supply tank the machinery ripple
/// (dozens of moles, under 0.1% of content) exceeded the absolute gates every
/// cycle, re-arming the group cooldowns and keeping engine rooms excited
/// forever.
/datum/unit_test/planetary_churn/pressurized_room/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	build_room()
	// 400+ atm of pure O2 with a +-15 mol per-tile ripple: far above the
	// absolute gates, far below any content-relative significance.
	var/datum/excited_group/group = new
	var/ripple = 15
	for(var/turf/open/T as anything in room)
		T.air.clear()
		T.air.set_moles(GAS_O2, 40000 + ripple)
		T.air.set_temperature(T20C)
		ripple = -ripple
		SSair.add_to_active(T)
		group.add_turf(T)
	// A visible starting value: a ripple share resetting the cooldown drops it
	// back to 0, an ignored ripple lets the lifecycle keep counting from here.
	group.dismantle_cooldown = 5
	var/fire = SSair.times_fired + 40000
	for(var/turf/open/T as anything in room)
		T.process_cell(fire)
	group.tick_lifecycle()
	var/cooldown_after = group.dismantle_cooldown
	cleanup_room()
	TEST_ASSERT(cooldown_after > 1, "a sub-0.1% ripple in a 400 atm room reset the group dismantle cooldown: suspend gates ignore tile pressure")

/// The inverse guard for the scaled significance gates: a real flood flow on
/// a high-mole tile (a few percent of content) must still fully reset the
/// group cooldowns. If it reads as noise, excited group breakdown keeps
/// firing mid-flow and averages the flood flat: stepwise gas movement with
/// no winds during canister releases.
/datum/unit_test/planetary_churn/flood_flow_stays_significant/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	build_room()
	var/turf/base = run_loc_floor_bottom_left
	// Reduce to a 1x2 corridor: one flood tile, one receiving tile.
	for(var/turf/open/T as anything in room.Copy())
		if(T.y != base.y + 2 || T.x > base.x + 2)
			room -= T
			T.ChangeTurf(/turf/closed/wall)
	TEST_ASSERT_EQUAL(length(room), 2, "flood arena should be exactly 2 turfs")
	var/turf/open/flood = locate(base.x + 1, base.y + 2, base.z)
	var/turf/open/receiver = locate(base.x + 2, base.y + 2, base.z)
	settle_room()
	flood.air.clear()
	flood.air.set_moles(GAS_O2, 3000)
	flood.air.set_temperature(T20C)
	receiver.air.clear()
	receiver.air.set_moles(GAS_O2, 2700)
	receiver.air.set_temperature(T20C)
	var/datum/excited_group/group = new
	SSair.add_to_active(flood)
	SSair.add_to_active(receiver)
	group.add_turf(flood)
	group.add_turf(receiver)
	group.breakdown_cooldown = 2
	group.dismantle_cooldown = 5
	var/fire = SSair.times_fired + 50000
	flood.process_cell(fire)
	receiver.process_cell(fire)
	var/breakdown_after = group.breakdown_cooldown
	cleanup_room()
	TEST_ASSERT_EQUAL(breakdown_after, 0, "a ~5% content flow on a 3000-mol tile did not reset group cooldowns: breakdown will average floods mid-flow")

/// Excited group breakdown must not average planetary members across template
/// boundaries. A mixed group (two different skies plus a station-air bridge)
/// used to blend everything into one mix that matched no template, so every
/// planetary member immediately re-shared with its own sky and re-armed the
/// group cooldowns forever - the icemoon surface (150K snow + 320K basalt
/// caves in one giant group) never went to sleep.
/datum/unit_test/planetary_churn/breakdown_respects_templates/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	build_room()
	var/turf/base = run_loc_floor_bottom_left
	var/turf/open/sky_a_turf = locate(base.x + 1, base.y + 2, base.z)
	var/turf/open/bridge = locate(base.x + 2, base.y + 2, base.z)
	var/turf/open/sky_b_turf = locate(base.x + 3, base.y + 2, base.z)
	make_planetary(sky_a_turf, PLANETARY_CHURN_TEMPLATE_A)
	make_planetary(sky_b_turf, PLANETARY_CHURN_TEMPLATE_B)
	settle_room()
	var/datum/gas_mixture/template_a = SSair.get_planetary_template(sky_a_turf)
	var/datum/gas_mixture/template_b = SSair.get_planetary_template(sky_b_turf)
	var/datum/excited_group/group = new
	for(var/turf/open/member as anything in list(sky_a_turf, bridge, sky_b_turf))
		SSair.add_to_active(member, FALSE)
		group.add_turf(member)
	group.self_breakdown()
	var/sky_a_diff = sky_a_turf.air.compare(template_a)
	var/sky_b_diff = sky_b_turf.air.compare(template_b)
	cleanup_room()
	TEST_ASSERT_EQUAL(sky_a_diff, "", "breakdown polluted a planetary turf away from its own template (differs by '[sky_a_diff]')")
	TEST_ASSERT_EQUAL(sky_b_diff, "", "breakdown polluted a planetary turf away from its own template (differs by '[sky_b_diff]')")

/// The planetary templates themselves must be chemically inert: a template
/// whose react() consumes its own gases turns every planetary turf into a
/// perpetual reaction+regeneration pump.
/datum/unit_test/planetary_churn/templates_inert/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	build_room()
	var/turf/open/holder = room[1]
	var/list/checked = list(
		"lavaland" = SSair.preprocess_gas_string(LAVALAND_DEFAULT_ATMOS),
		"icemoon" = SSair.preprocess_gas_string(ICEMOON_DEFAULT_ATMOS),
	)
	for(var/label in checked)
		var/gas_string = checked[label]
		holder.air.clear()
		holder.air.parse_gas_string(gas_string)
		var/moles_before = holder.air.total_moles()
		var/temperature_before = holder.air.return_temperature()
		for(var/i in 1 to 30)
			holder.air.react(holder)
		var/moles_delta = abs(holder.air.total_moles() - moles_before)
		var/temperature_delta = abs(holder.air.return_temperature() - temperature_before)
		TEST_ASSERT(moles_delta < 0.01, "[label] planetary template is not inert: total moles drifted by [moles_delta] over 30 react() calls ([gas_string])")
		TEST_ASSERT(temperature_delta < 0.5, "[label] planetary template is not inert: temperature drifted by [temperature_delta] K over 30 react() calls ([gas_string])")
	if(holder.active_hotspot)
		qdel(holder.active_hotspot)
	cleanup_room()

#undef PLANETARY_CHURN_TEMPLATE_A
#undef PLANETARY_CHURN_TEMPLATE_B
#undef PLANETARY_CHURN_MAX_CYCLES
