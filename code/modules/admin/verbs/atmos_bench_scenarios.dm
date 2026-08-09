// ============================================================================
// ATMOS_HEADLESS_BENCH scenario library. Each scenario builds a synthetic
// arena on a reserved z-level and then provokes one specific expensive path of
// SSair, so a single unattended run answers "what does THIS subsystem phase
// cost under abuse" instead of A/B-ing a whole map. Scenario selection comes
// from run_headless.sh via world.params (atmos-bench-scenario=...).
//
// Scenarios:
//   plasma-fire    hotspots, volatile excited groups, firelock alarm cascade
//   giant-hall     one 12k-turf excited group, share wave, resumable breakdown
//   room-grid      120-room checkerboard: group creation/merge/dismantle churn
//   pipenet-stress closed vent/scrubber/pump loop: machinery + pipenet cost
//   heat-wall      superconduction through a shared wall, no fire
//   space-wind     breach into a littered room: the high pressure movement phase
//   reaction-zoo   one sealed cell per gas reaction, re-primed on an interval
//   he-loop        a long heat exchanging pipe run: machinery that never sleeps
//   atom-churn     a population of atmos-sensitive atoms held above threshold
//   changeturf-storm  a wall stripe that moves every interval: adjacency rebuilds
//   station-breach a hull breach on the real loaded map, floors littered first
// The pre-existing multi-breach scenario lives in atmos_benchmark.dm.
// ============================================================================
#ifdef ATMOS_HEADLESS_BENCH

#define ATMOS_BENCH_FIRE_CORRIDOR_LENGTH 102
#define ATMOS_BENCH_FIRE_CORRIDOR_WIDTH 3
#define ATMOS_BENCH_FIRE_PLASMA_COLUMNS 25
#define ATMOS_BENCH_FIRE_PLASMA_MOLES 80
#define ATMOS_BENCH_HALL_WIDTH 120
#define ATMOS_BENCH_HALL_HEIGHT 100
#define ATMOS_BENCH_HALL_PRESSURE_RATIO_HIGH 4
#define ATMOS_BENCH_HALL_PRESSURE_RATIO_LOW 0.25
#define ATMOS_BENCH_GRID_COLS 12
#define ATMOS_BENCH_GRID_ROWS 10
#define ATMOS_BENCH_GRID_ROOM 5
#define ATMOS_BENCH_GRID_RATIO_HIGH 3
#define ATMOS_BENCH_GRID_RATIO_LOW 0.3
#define ATMOS_BENCH_PIPE_ROOMS 16
#define ATMOS_BENCH_PIPE_ROOM_SPAN 7
#define ATMOS_BENCH_PIPE_VENT_TARGET_HIGH (ONE_ATMOSPHERE * 3)
#define ATMOS_BENCH_PIPE_VENT_TARGET_LOW (ONE_ATMOSPHERE * 0.3)
// vent_pump.dm's RELEASING/EXT_BOUND are file-local and compile after this
// file; the values are stable API (0 = siphon, 1 = release / ext bound).
#define ATMOS_BENCH_VENT_RELEASING 1
#define ATMOS_BENCH_VENT_EXT_BOUND 1
#define ATMOS_BENCH_HEAT_ROOM 20
#define ATMOS_BENCH_HEAT_HOT_MOLES 500
#define ATMOS_BENCH_HEAT_HOT_TEMPERATURE 6000
#define ATMOS_BENCH_WIND_WIDTH 60
#define ATMOS_BENCH_WIND_HEIGHT 40
/// One loose item per this many floor tiles; the wind phase only costs anything
/// where there is something to throw.
#define ATMOS_BENCH_WIND_ITEM_STRIDE 3
#define ATMOS_BENCH_ZOO_CELL 8
#define ATMOS_BENCH_ZOO_COLS 3
#define ATMOS_BENCH_ZOO_ROWS 2
#define ATMOS_BENCH_HE_PIPES 200
#define ATMOS_BENCH_HE_HOT_TEMPERATURE 3000
#define ATMOS_BENCH_ATOM_ROOM 30
/// Fire alarms hold the atom_process list steady (alarm() does not consume the
/// alarm); grilles decay out of it, which is the enrol/unenrol churn path.
#define ATMOS_BENCH_ATOM_ALARM_STRIDE 6
#define ATMOS_BENCH_ATOM_GRILLE_STRIDE 4
#define ATMOS_BENCH_ATOM_TEMPERATURE (T0C + 1800)
#define ATMOS_BENCH_STORM_WIDTH 60
#define ATMOS_BENCH_STORM_HEIGHT 40
/// station-breach: one loose item per this many station floor tiles, capped so
/// boot time stays bearable on a full map.
#define ATMOS_BENCH_STATION_ITEM_STRIDE 8
#define ATMOS_BENCH_STATION_ITEM_CAP 1500
/// Side of the square hull breach punched into the middle of the station.
#define ATMOS_BENCH_STATION_BREACH_SIDE 5

/// Conductive divider for the heat-wall scenario: standard walls ship with
/// WALL_HEAT_TRANSFER_COEFFICIENT = 0 (a deliberate balance choice, same as
/// tg), so the superconduction canary needs its own thermally live wall.
/turf/closed/wall/atmos_bench_conductive
	thermal_conductivity = 0.04
	heat_capacity = 6000

/datum/controller/subsystem/air
	/// Turfs the scenario event converts or ignites (doorways, divider, breach points).
	var/list/turf/headless_bench_event_turfs = list()
	/// Vents the pipenet-stress event retargets each event interval.
	var/list/obj/machinery/atmospherics/components/unary/vent_pump/headless_bench_vents = list()
	/// Scrubbers the pipenet-stress scenario keeps siphoning.
	var/list/obj/machinery/atmospherics/components/unary/vent_scrubber/headless_bench_scrubbers = list()
	/// Alternates the pipenet-stress vent target between high and low.
	var/headless_bench_flip_state = FALSE
	/// One-shot latch so single-event scenarios fire exactly once.
	var/headless_bench_event_fired = FALSE
	/// Heat exchanging pipes of the he-loop scenario, re-heated on an interval.
	var/list/obj/machinery/atmospherics/pipe/heat_exchanging/headless_bench_he_pipes = list()
	/// reaction-zoo cells: one entry per recipe, list(name, turfs).
	var/list/headless_bench_zoo_cells = list()
	/// changeturf-storm: floors currently walled off, restored on the next event.
	var/list/turf/headless_bench_storm_walls = list()
	/// changeturf-storm cursor, so the stripe walks the room instead of flapping.
	var/headless_bench_storm_column = 0

/// Build dispatch: called async from atmos_headless_bench_tick when a scenario
/// is requested but not yet built.
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_scenario()
	switch(headless_bench_scenario)
		if("multi-breach")
			atmos_headless_bench_build_multi_breach()
		if("plasma-fire")
			atmos_headless_bench_build_plasma_fire()
		if("giant-hall")
			atmos_headless_bench_build_giant_hall()
		if("giant-hall-eq")
			// A/B variant: same arena with the zone equalizer live. The config
			// default ships FALSE, so this measures what the flag would buy.
			equalize_enabled = TRUE
			atmos_headless_bench_build_giant_hall()
		if("room-grid")
			atmos_headless_bench_build_room_grid()
		if("pipenet-stress")
			atmos_headless_bench_build_pipenet_stress()
		if("heat-wall")
			atmos_headless_bench_build_heat_wall()
		if("space-wind")
			atmos_headless_bench_build_space_wind()
		if("reaction-zoo")
			atmos_headless_bench_build_reaction_zoo()
		if("he-loop")
			atmos_headless_bench_build_he_loop()
		if("atom-churn")
			atmos_headless_bench_build_atom_churn()
		if("changeturf-storm")
			atmos_headless_bench_build_changeturf_storm()
		if("station-breach")
			atmos_headless_bench_build_station_breach()
		else
			log_world("ATMOS-BENCH: unknown scenario '[headless_bench_scenario]', running as plain settling")
			headless_bench_scenario = null
			headless_bench_scenario_ready = TRUE
			headless_bench_scenario_building = FALSE

/// Event dispatch: called every completed cycle with the cycle number.
/datum/controller/subsystem/air/proc/atmos_headless_bench_scenario_event(cycle)
	switch(headless_bench_scenario)
		if("multi-breach")
			if(cycle == headless_bench_breach_cycle)
				atmos_headless_bench_open_breaches()
		if("plasma-fire")
			if(cycle == headless_bench_breach_cycle && !headless_bench_event_fired)
				headless_bench_event_fired = TRUE
				atmos_headless_bench_ignite()
		if("giant-hall", "giant-hall-eq", "room-grid")
			if(cycle == headless_bench_breach_cycle && !headless_bench_event_fired)
				headless_bench_event_fired = TRUE
				atmos_headless_bench_open_event_turfs()
		if("pipenet-stress")
			// Recurring: retarget the vents every interval so the machinery,
			// its wake paths and the pipenets never settle into sleep.
			if(cycle % headless_bench_breach_cycle == 0)
				atmos_headless_bench_flip_vents()
		if("space-wind")
			if(cycle == headless_bench_breach_cycle && !headless_bench_event_fired)
				headless_bench_event_fired = TRUE
				atmos_headless_bench_vent_event_turfs()
		if("reaction-zoo")
			// Recurring: burning cells consume their fuel in a handful of cycles,
			// so the whole zoo is re-primed on the interval. Otherwise the run
			// measures one short flare and 200 cycles of an inert room.
			if(cycle % headless_bench_breach_cycle == 0)
				atmos_headless_bench_prime_reaction_zoo()
		if("he-loop")
			// The pipe run bleeds its heat into the room within a few cycles; a
			// periodic reheat keeps the conduction path live for the whole run.
			if(cycle % headless_bench_breach_cycle == 0)
				atmos_headless_bench_reheat_he_loop()
		if("atom-churn")
			if(cycle % headless_bench_breach_cycle == 0)
				atmos_headless_bench_reheat_atom_room()
		if("changeturf-storm")
			if(cycle % headless_bench_breach_cycle == 0)
				atmos_headless_bench_move_storm_stripe()
		if("station-breach")
			if(cycle == headless_bench_breach_cycle && !headless_bench_event_fired)
				headless_bench_event_fired = TRUE
				atmos_headless_bench_vent_event_turfs()

/// Writes the standard scenario_ready event record.
/datum/controller/subsystem/air/proc/atmos_headless_bench_mark_ready(list/extra)
	headless_bench_scenario_ready = TRUE
	headless_bench_scenario_building = FALSE
	can_fire = TRUE
	var/list/record = list(
		"rec" = "event",
		"event" = "scenario_ready",
		"scenario" = headless_bench_scenario,
		"event_cycle" = headless_bench_breach_cycle,
		"equalize" = equalize_enabled,
		"heat" = heat_enabled,
		"seed" = Master.random_seed,
		"t" = world.time,
	)
	if(extra)
		record += extra
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)
	log_world("ATMOS-BENCH: scenario [headless_bench_scenario] ready")

/// Reserves the arena block or shuts the bench down. Returns the reservation.
/datum/controller/subsystem/air/proc/atmos_headless_bench_reserve(width, height)
	headless_bench_reservation = SSmapping.RequestBlockReservation(width, height)
	if(!headless_bench_reservation)
		log_world("ATMOS-BENCH: failed to reserve a [width]x[height] arena")
		GLOB.atmos_headless_bench_finished = TRUE
		can_fire = TRUE
		del(world)
	return headless_bench_reservation

/// Walls the border of the box, floors the inside, assigns the area. Returns
/// nothing; inner floors are appended to headless_bench_room_turfs.
/datum/controller/subsystem/air/proc/atmos_headless_bench_fill_box(x0, y0, z, outer_w, outer_h, area/room_area)
	for(var/x in x0 to x0 + outer_w - 1)
		for(var/y in y0 to y0 + outer_h - 1)
			var/turf/T = locate(x, y, z)
			if(room_area && T.loc != room_area)
				var/area/old_area = T.loc
				room_area.contents += T
				T.change_area(old_area, room_area, skip_blend = TRUE)
			if(x == x0 || x == x0 + outer_w - 1 || y == y0 || y == y0 + outer_h - 1)
				T.ChangeTurf(/turf/closed/wall)
			else
				var/turf/open/floor/floor = T.ChangeTurf(/turf/open/floor/plasteel)
				headless_bench_room_turfs += floor
			CHECK_TICK

/// Recomputes adjacency for every arena floor and wakes it, so each run starts
/// from an identical fully-connected graph (mirrors the multi-breach builder).
/datum/controller/subsystem/air/proc/atmos_headless_bench_activate_floors()
	for(var/turf/open/T as anything in headless_bench_room_turfs)
		T.ImmediateCalculateAdjacentTurfs()
		add_to_active(T)
		CHECK_TICK

/// Makes one bench area spanning the arena and registers it.
/datum/controller/subsystem/air/proc/atmos_headless_bench_make_area(name)
	var/area/atmos_headless_bench/one/room_area = new
	room_area.name = name
	headless_bench_areas += room_area
	return room_area

/// Runtime atmos machinery construction, mirroring the wrench path in
/// /obj/item/pipe/build_pipe: New() computes initialize_directions from the
/// DEFAULT dir, so setDir alone leaves every node dead - SetInitDirections
/// must be re-run before atmosinit stitches the nodes.
/datum/controller/subsystem/air/proc/atmos_headless_bench_construct(obj/machinery/atmospherics/machine, direction)
	machine.setDir(direction)
	machine.SetInitDirections()
	machine.on_construction(null, PIPING_LAYER_DEFAULT)
	return machine

// ---------------------------------------------------------------------------
// plasma-fire: a long corridor, plasma pre-mixed into the first quarter,
// firelock checkpoints across it, ignition at the event cycle. Measures the
// hotspot phase, reaction cost inside process_cell, volatile group behavior
// (they may never break down while burning) and the firelock alarm cascade.
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_plasma_fire()
	can_fire = FALSE
	var/outer_w = ATMOS_BENCH_FIRE_CORRIDOR_LENGTH + 2
	var/outer_h = ATMOS_BENCH_FIRE_CORRIDOR_WIDTH + 2
	if(!atmos_headless_bench_reserve(outer_w, outer_h))
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	var/area/room_area = atmos_headless_bench_make_area("Atmos Bench Fire Corridor")
	atmos_headless_bench_fill_box(base_x, base_y, base_z, outer_w, outer_h, room_area)
	room_area.reg_in_areas_in_z()

	// Firelock checkpoints at the quarter marks: a full row of doors each.
	for(var/checkpoint in 1 to 3)
		var/door_x = base_x + round(outer_w * checkpoint / 4)
		for(var/y in base_y + 1 to base_y + ATMOS_BENCH_FIRE_CORRIDOR_WIDTH)
			var/obj/machinery/door/firedoor/firedoor = new(locate(door_x, y, base_z))
			firedoor.CalculateAffectingAreas()
			headless_bench_firedoors += firedoor

	// Plasma pre-mix in the first quarter; the rest keeps standard air.
	for(var/turf/open/T as anything in headless_bench_room_turfs)
		if(T.x - base_x <= ATMOS_BENCH_FIRE_PLASMA_COLUMNS)
			T.air.set_moles(GAS_PLASMA, ATMOS_BENCH_FIRE_PLASMA_MOLES)
		CHECK_TICK
	headless_bench_event_turfs += locate(base_x + 1, base_y + 2, base_z)
	atmos_headless_bench_activate_floors()
	atmos_headless_bench_mark_ready(list(
		"corridor_turfs" = length(headless_bench_room_turfs),
		"firedoors" = length(headless_bench_firedoors),
	))

/datum/controller/subsystem/air/proc/atmos_headless_bench_ignite()
	for(var/turf/open/T as anything in headless_bench_event_turfs)
		T.hotspot_expose(FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 400, CELL_VOLUME)
		add_to_active(T)
	var/list/record = list(
		"rec" = "event",
		"event" = "ignite",
		"cyc" = headless_bench_cycles,
		"t" = world.time,
	)
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)

// ---------------------------------------------------------------------------
// giant-hall: one huge room split by a single wall column; the halves start at
// 4x and 0.25x pressure and the divider drops at the event cycle. Produces the
// biggest single excited group the codebase can see outside of a planetary
// breach: share wave first, then a 12k-member resumable breakdown.
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_giant_hall()
	can_fire = FALSE
	var/outer_w = ATMOS_BENCH_HALL_WIDTH + 2
	var/outer_h = ATMOS_BENCH_HALL_HEIGHT + 2
	if(!atmos_headless_bench_reserve(outer_w, outer_h))
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	var/area/room_area = atmos_headless_bench_make_area("Atmos Bench Giant Hall")
	atmos_headless_bench_fill_box(base_x, base_y, base_z, outer_w, outer_h, room_area)
	room_area.reg_in_areas_in_z()

	// Raise the divider and split the pressures.
	var/divider_x = base_x + round(outer_w / 2)
	for(var/y in base_y + 1 to base_y + ATMOS_BENCH_HALL_HEIGHT)
		var/turf/T = locate(divider_x, y, base_z)
		headless_bench_room_turfs -= T
		T.ChangeTurf(/turf/closed/wall)
		headless_bench_event_turfs += T
		CHECK_TICK
	for(var/turf/open/T as anything in headless_bench_room_turfs)
		var/ratio = T.x < divider_x ? ATMOS_BENCH_HALL_PRESSURE_RATIO_HIGH : ATMOS_BENCH_HALL_PRESSURE_RATIO_LOW
		T.air.set_moles(GAS_O2, MOLES_O2STANDARD * ratio)
		T.air.set_moles(GAS_N2, MOLES_N2STANDARD * ratio)
		CHECK_TICK
	atmos_headless_bench_activate_floors()
	atmos_headless_bench_mark_ready(list(
		"hall_turfs" = length(headless_bench_room_turfs),
		"divider_turfs" = length(headless_bench_event_turfs),
	))

/// Converts the stored event turfs (divider column / doorway walls) to floor
/// in one tick and wakes their neighborhoods: the worst-case adjacency and
/// share flood the mapper can produce with a single action.
/datum/controller/subsystem/air/proc/atmos_headless_bench_open_event_turfs()
	for(var/turf/T as anything in headless_bench_event_turfs)
		var/turf/open/floor/floor = T.ChangeTurf(/turf/open/floor/plasteel)
		floor.ImmediateCalculateAdjacentTurfs()
		add_to_active(floor)
		for(var/turf/open/neighbor in floor.atmos_adjacent_turfs)
			add_to_active(neighbor)
	var/list/record = list(
		"rec" = "event",
		"event" = "open_event_turfs",
		"cyc" = headless_bench_cycles,
		"opened" = length(headless_bench_event_turfs),
		"t" = world.time,
	)
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)

// ---------------------------------------------------------------------------
// room-grid: a lattice of small rooms with checkerboard pressures. Every room
// has a sealed doorway in its shared walls; the event opens all of them in the
// same tick. Measures mass excited-group creation, the merge cascade as the
// checkerboard equalizes through 1-tile chokepoints, and the dismantle churn
// afterwards - the "many small rooms" cost profile, as opposed to giant-hall's
// "one huge room".
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_room_grid()
	can_fire = FALSE
	var/span = ATMOS_BENCH_GRID_ROOM + 1
	var/outer_w = ATMOS_BENCH_GRID_COLS * span + 1
	var/outer_h = ATMOS_BENCH_GRID_ROWS * span + 1
	if(!atmos_headless_bench_reserve(outer_w, outer_h))
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	var/area/room_area = atmos_headless_bench_make_area("Atmos Bench Room Grid")

	// Lattice: wall on every span boundary, floors inside cells.
	for(var/x in base_x to base_x + outer_w - 1)
		for(var/y in base_y to base_y + outer_h - 1)
			var/turf/T = locate(x, y, base_z)
			if(T.loc != room_area)
				var/area/old_area = T.loc
				room_area.contents += T
				T.change_area(old_area, room_area, skip_blend = TRUE)
			var/on_wall = ((x - base_x) % span == 0) || ((y - base_y) % span == 0)
			if(on_wall)
				T.ChangeTurf(/turf/closed/wall)
			else
				var/turf/open/floor/floor = T.ChangeTurf(/turf/open/floor/plasteel)
				headless_bench_room_turfs += floor
			CHECK_TICK
	room_area.reg_in_areas_in_z()

	// Checkerboard pressures per cell, and one doorway per shared wall.
	var/room_center = round(ATMOS_BENCH_GRID_ROOM / 2) + 1
	for(var/col in 0 to ATMOS_BENCH_GRID_COLS - 1)
		for(var/row in 0 to ATMOS_BENCH_GRID_ROWS - 1)
			var/cell_x = base_x + col * span
			var/cell_y = base_y + row * span
			var/ratio = ((col + row) % 2) ? ATMOS_BENCH_GRID_RATIO_HIGH : ATMOS_BENCH_GRID_RATIO_LOW
			for(var/x in cell_x + 1 to cell_x + ATMOS_BENCH_GRID_ROOM)
				for(var/y in cell_y + 1 to cell_y + ATMOS_BENCH_GRID_ROOM)
					var/turf/open/T = locate(x, y, base_z)
					if(!istype(T) || !T.air)
						continue
					T.air.set_moles(GAS_O2, MOLES_O2STANDARD * ratio)
					T.air.set_moles(GAS_N2, MOLES_N2STANDARD * ratio)
					CHECK_TICK
			// Doorway to the east neighbor and to the north neighbor.
			if(col < ATMOS_BENCH_GRID_COLS - 1)
				headless_bench_event_turfs += locate(cell_x + span, cell_y + room_center, base_z)
			if(row < ATMOS_BENCH_GRID_ROWS - 1)
				headless_bench_event_turfs += locate(cell_x + room_center, cell_y + span, base_z)
	atmos_headless_bench_activate_floors()
	atmos_headless_bench_mark_ready(list(
		"rooms" = ATMOS_BENCH_GRID_COLS * ATMOS_BENCH_GRID_ROWS,
		"room_turfs" = length(headless_bench_room_turfs),
		"doorways" = length(headless_bench_event_turfs),
	))

// ---------------------------------------------------------------------------
// pipenet-stress: a row of rooms, each with a vent fed from a distribution
// line and a scrubber draining to a waste line; a volume pump closes the loop.
// The event interval flips every vent between over- and under-pressure
// targets, so machinery, atmos_wake paths and both pipenets stay busy for the
// whole run. Measures c_am / c_pn / mprof per-type costs under sustained load.
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_pipenet_stress()
	can_fire = FALSE
	var/span = ATMOS_BENCH_PIPE_ROOM_SPAN
	var/outer_w = ATMOS_BENCH_PIPE_ROOMS * span + 5 // loop-closure column on the east
	var/outer_h = 10
	if(!atmos_headless_bench_reserve(outer_w, outer_h))
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	var/area/room_area = atmos_headless_bench_make_area("Atmos Bench Pipenet Row")
	atmos_headless_bench_fill_box(base_x, base_y, base_z, outer_w, outer_h, room_area)
	room_area.reg_in_areas_in_z()

	// Interior dividers between rooms.
	for(var/room_index in 1 to ATMOS_BENCH_PIPE_ROOMS - 1)
		var/wall_x = base_x + room_index * span
		for(var/y in base_y + 1 to base_y + outer_h - 2)
			var/turf/T = locate(wall_x, y, base_z)
			headless_bench_room_turfs -= T
			T.ChangeTurf(/turf/closed/wall)
			CHECK_TICK

	var/distro_y = base_y + 6
	var/waste_y = base_y + 3
	var/loop_x = base_x + ATMOS_BENCH_PIPE_ROOMS * span + 2

	// Straight distro/waste lines with a manifold drop in every room.
	for(var/x in base_x + 1 to loop_x)
		for(var/line_y in list(distro_y, waste_y))
			var/in_room_center = ((x - base_x - 1) % span) == round(span / 2)
			var/at_loop_column = x == loop_x
			if(at_loop_column)
				// Corners: distro turns down, waste turns up, meeting the pump.
				atmos_headless_bench_construct(new /obj/machinery/atmospherics/pipe/simple(locate(x, line_y, base_z)), line_y == distro_y ? SOUTHWEST : NORTHWEST)
			else if(in_room_center)
				// Manifold ports face south + east + west.
				atmos_headless_bench_construct(new /obj/machinery/atmospherics/pipe/manifold(locate(x, line_y, base_z)), NORTH)
			else
				atmos_headless_bench_construct(new /obj/machinery/atmospherics/pipe/simple(locate(x, line_y, base_z)), EAST)
			CHECK_TICK

	// The loop closure: waste -> volume pump -> distro.
	var/obj/machinery/atmospherics/components/binary/volume_pump/loop_pump = atmos_headless_bench_construct(new /obj/machinery/atmospherics/components/binary/volume_pump(locate(loop_x, waste_y + 1, base_z)), NORTH)
	loop_pump.transfer_rate = MAX_TRANSFER_RATE
	loop_pump.on = TRUE
	loop_pump.update_icon()
	for(var/y in waste_y + 2 to distro_y - 1)
		atmos_headless_bench_construct(new /obj/machinery/atmospherics/pipe/simple(locate(loop_x, y, base_z)), NORTH)
		CHECK_TICK

	// Per room: a vent below the distro manifold, a scrubber below the waste one.
	for(var/room_index in 0 to ATMOS_BENCH_PIPE_ROOMS - 1)
		var/device_x = base_x + 1 + room_index * span + round(span / 2)
		var/obj/machinery/atmospherics/components/unary/vent_pump/vent = atmos_headless_bench_construct(new /obj/machinery/atmospherics/components/unary/vent_pump(locate(device_x, distro_y - 1, base_z)), NORTH)
		vent.on = TRUE
		vent.pump_direction = ATMOS_BENCH_VENT_RELEASING
		vent.pressure_checks = ATMOS_BENCH_VENT_EXT_BOUND
		vent.external_pressure_bound = ATMOS_BENCH_PIPE_VENT_TARGET_HIGH
		headless_bench_vents += vent
		var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = atmos_headless_bench_construct(new /obj/machinery/atmospherics/components/unary/vent_scrubber(locate(device_x, waste_y - 1, base_z)), NORTH)
		scrubber.on = TRUE
		scrubber.scrubbing = FALSE // siphon everything into the waste loop
		headless_bench_scrubbers += scrubber
		CHECK_TICK
	atmos_headless_bench_activate_floors()
	atmos_headless_bench_mark_ready(list(
		"rooms" = ATMOS_BENCH_PIPE_ROOMS,
		"vents" = length(headless_bench_vents),
		"scrubbers" = length(headless_bench_scrubbers),
	))

/datum/controller/subsystem/air/proc/atmos_headless_bench_flip_vents()
	headless_bench_flip_state = !headless_bench_flip_state
	var/new_target = headless_bench_flip_state ? ATMOS_BENCH_PIPE_VENT_TARGET_LOW : ATMOS_BENCH_PIPE_VENT_TARGET_HIGH
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/vent as anything in headless_bench_vents)
		if(QDELETED(vent))
			continue
		vent.external_pressure_bound = new_target
		vent.atmos_wake()
	for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber as anything in headless_bench_scrubbers)
		if(QDELETED(scrubber))
			continue
		scrubber.atmos_wake()
	// Loop health probe: a dead loop shows a permanently empty distro line.
	var/distro_kpa = 0
	var/waste_kpa = 0
	var/room_kpa = 0
	var/obj/machinery/atmospherics/components/unary/vent_pump/probe_vent = length(headless_bench_vents) ? headless_bench_vents[1] : null
	if(!QDELETED(probe_vent))
		var/datum/pipeline/distro_net = length(probe_vent.parents) ? probe_vent.parents[1] : null
		distro_kpa = distro_net?.air ? round(distro_net.air.return_pressure(), 0.1) : -1
		var/turf/open/vent_turf = get_turf(probe_vent)
		room_kpa = istype(vent_turf) && vent_turf.air ? round(vent_turf.air.return_pressure(), 0.1) : -1
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/probe_scrubber = length(headless_bench_scrubbers) ? headless_bench_scrubbers[1] : null
	if(!QDELETED(probe_scrubber))
		var/datum/pipeline/waste_net = length(probe_scrubber.parents) ? probe_scrubber.parents[1] : null
		waste_kpa = waste_net?.air ? round(waste_net.air.return_pressure(), 0.1) : -1
	var/list/record = list(
		"rec" = "event",
		"event" = "vent_flip",
		"cyc" = headless_bench_cycles,
		"target" = round(new_target, 0.1),
		"distro_kpa" = distro_kpa,
		"waste_kpa" = waste_kpa,
		"room_kpa" = room_kpa,
		"t" = world.time,
	)
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)

// ---------------------------------------------------------------------------
// heat-wall: two sealed rooms sharing one wall column; the west room holds
// inert superheated gas. Nothing burns and no door opens - every joule that
// reaches the east room went through the superconduction path, so c_sc and
// the heat phase are measured in isolation.
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_heat_wall()
	can_fire = FALSE
	var/outer_w = ATMOS_BENCH_HEAT_ROOM * 2 + 3
	var/outer_h = ATMOS_BENCH_HEAT_ROOM + 2
	if(!atmos_headless_bench_reserve(outer_w, outer_h))
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	var/area/room_area = atmos_headless_bench_make_area("Atmos Bench Heat Wall")
	atmos_headless_bench_fill_box(base_x, base_y, base_z, outer_w, outer_h, room_area)
	room_area.reg_in_areas_in_z()

	// Shared conductive wall column in the middle.
	var/divider_x = base_x + ATMOS_BENCH_HEAT_ROOM + 1
	for(var/y in base_y + 1 to base_y + outer_h - 2)
		var/turf/T = locate(divider_x, y, base_z)
		headless_bench_room_turfs -= T
		T.ChangeTurf(/turf/closed/wall/atmos_bench_conductive)
		CHECK_TICK

	// West room: inert superheated nitrogen. No oxidizer, so no combustion -
	// heat is the only thing that can cross the divider.
	set_heat_enabled(TRUE) // the scenario is the canary for conduction, so force it on whatever the config says
	for(var/turf/open/T as anything in headless_bench_room_turfs)
		if(T.x >= divider_x)
			continue
		T.air.clear()
		T.air.set_moles(GAS_N2, ATMOS_BENCH_HEAT_HOT_MOLES)
		T.air.set_temperature(ATMOS_BENCH_HEAT_HOT_TEMPERATURE)
		CHECK_TICK
	atmos_headless_bench_activate_floors()
	atmos_headless_bench_mark_ready(list(
		"room_turfs" = length(headless_bench_room_turfs),
		"hot_moles" = ATMOS_BENCH_HEAT_HOT_MOLES,
		"hot_temperature" = ATMOS_BENCH_HEAT_HOT_TEMPERATURE,
	))

// ---------------------------------------------------------------------------
// space-wind: a wide room littered with loose items, breached to space along a
// whole wall. The other arenas are empty, so their high-pressure phase costs
// nothing no matter how violent the decompression - there is simply nothing to
// throw. This one measures what the phase actually costs on a lived-in map.
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_space_wind()
	can_fire = FALSE
	var/outer_w = ATMOS_BENCH_WIND_WIDTH + 2
	var/outer_h = ATMOS_BENCH_WIND_HEIGHT + 2
	if(!atmos_headless_bench_reserve(outer_w, outer_h))
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	var/area/room_area = atmos_headless_bench_make_area("Atmos Bench Wind Hall")
	atmos_headless_bench_fill_box(base_x, base_y, base_z, outer_w, outer_h, room_area)
	room_area.reg_in_areas_in_z()

	var/litter = 0
	var/index = 0
	for(var/turf/open/T as anything in headless_bench_room_turfs)
		index++
		if(index % ATMOS_BENCH_WIND_ITEM_STRIDE)
			continue
		new /obj/item/stack/sheet/metal(T)
		litter++
		CHECK_TICK

	// The entire east wall goes at once: a wall-length breach produces the
	// widest possible pressure front, which is what makes the phase expensive.
	for(var/y in base_y + 1 to base_y + outer_h - 2)
		headless_bench_event_turfs += locate(base_x + outer_w - 1, y, base_z)
	atmos_headless_bench_activate_floors()
	atmos_headless_bench_mark_ready(list(
		"room_turfs" = length(headless_bench_room_turfs),
		"litter" = litter,
		"breach_turfs" = length(headless_bench_event_turfs),
	))

/// Turns the stored event turfs into space rather than floor: the wind
/// scenarios need a vacuum sink, not just a new opening.
/datum/controller/subsystem/air/proc/atmos_headless_bench_vent_event_turfs()
	for(var/turf/T as anything in headless_bench_event_turfs)
		T.ChangeTurf(/turf/open/space)
	var/list/record = list(
		"rec" = "event",
		"event" = "space_breach",
		"cyc" = headless_bench_cycles,
		"opened" = length(headless_bench_event_turfs),
		"t" = world.time,
	)
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)

// ---------------------------------------------------------------------------
// reaction-zoo: one sealed cell per gas reaction, re-primed on the event
// interval. plasma-fire only ever exercised plasma combustion, so the cost of
// the reaction dispatch and of the exotic recipes was never measured. Each
// cell also carries an inert control, which prices react() on a mixture that
// matches nothing - the case every settled tile on the station pays.
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_reaction_zoo()
	can_fire = FALSE
	var/span = ATMOS_BENCH_ZOO_CELL + 1
	var/outer_w = ATMOS_BENCH_ZOO_COLS * span + 1
	var/outer_h = ATMOS_BENCH_ZOO_ROWS * span + 1
	if(!atmos_headless_bench_reserve(outer_w, outer_h))
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	var/area/room_area = atmos_headless_bench_make_area("Atmos Bench Reaction Zoo")

	// Sealed lattice: every cell is its own airtight box, so one runaway recipe
	// cannot contaminate its neighbours and blur the attribution.
	for(var/x in base_x to base_x + outer_w - 1)
		for(var/y in base_y to base_y + outer_h - 1)
			var/turf/T = locate(x, y, base_z)
			if(T.loc != room_area)
				var/area/old_area = T.loc
				room_area.contents += T
				T.change_area(old_area, room_area, skip_blend = TRUE)
			if(((x - base_x) % span == 0) || ((y - base_y) % span == 0))
				T.ChangeTurf(/turf/closed/wall)
			else
				var/turf/open/floor/floor = T.ChangeTurf(/turf/open/floor/plasteel)
				headless_bench_room_turfs += floor
			CHECK_TICK
	room_area.reg_in_areas_in_z()

	var/list/recipes = list("tritfire", "plasmafire", "freonfire", "freonformation", "pluox_formation", "inert")
	var/recipe_index = 0
	for(var/col in 0 to ATMOS_BENCH_ZOO_COLS - 1)
		for(var/row in 0 to ATMOS_BENCH_ZOO_ROWS - 1)
			recipe_index++
			if(recipe_index > length(recipes))
				continue
			var/cell_x = base_x + col * span
			var/cell_y = base_y + row * span
			var/list/turf/open/cell_turfs = list()
			for(var/x in cell_x + 1 to cell_x + ATMOS_BENCH_ZOO_CELL)
				for(var/y in cell_y + 1 to cell_y + ATMOS_BENCH_ZOO_CELL)
					var/turf/open/T = locate(x, y, base_z)
					if(istype(T) && T.air)
						cell_turfs += T
					CHECK_TICK
			headless_bench_zoo_cells += list(list("recipe" = recipes[recipe_index], "turfs" = cell_turfs))
	atmos_headless_bench_prime_reaction_zoo()
	atmos_headless_bench_activate_floors()
	atmos_headless_bench_mark_ready(list(
		"cells" = length(headless_bench_zoo_cells),
		"cell_turfs" = ATMOS_BENCH_ZOO_CELL * ATMOS_BENCH_ZOO_CELL,
		"recipes" = recipes,
	))

/// Refills every cell with its recipe. Mole counts are deliberately generous:
/// a cell that burns out inside one interval would leave the rest of the run
/// measuring an empty room and quietly report that reactions are cheap.
/datum/controller/subsystem/air/proc/atmos_headless_bench_prime_reaction_zoo()
	var/list/live = list()
	for(var/list/cell as anything in headless_bench_zoo_cells)
		var/recipe = cell["recipe"]
		var/list/turf/open/cell_turfs = cell["turfs"]
		var/reacting = 0
		for(var/turf/open/T as anything in cell_turfs)
			var/datum/gas_mixture/air = T.air
			if(!air)
				continue
			air.clear()
			switch(recipe)
				if("tritfire")
					air.set_moles(GAS_TRITIUM, 30)
					air.set_moles(GAS_O2, 90)
					air.set_temperature(FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 200)
				if("plasmafire")
					air.set_moles(GAS_PLASMA, 40)
					air.set_moles(GAS_O2, 90)
					air.set_temperature(FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 200)
				if("freonfire")
					air.set_moles(GAS_FREON, 30)
					air.set_moles(GAS_O2, 90)
					air.set_temperature(FREON_TERMINAL_TEMPERATURE + 20)
				if("freonformation")
					air.set_moles(GAS_PLASMA, 60)
					air.set_moles(GAS_CO2, 30)
					air.set_moles(GAS_BZ, 10)
					air.set_temperature(FREON_FORMATION_MIN_TEMPERATURE + 100)
				if("pluox_formation")
					air.set_moles(GAS_CO2, 60)
					air.set_moles(GAS_O2, 60)
					air.set_moles(GAS_TRITIUM, 10)
					air.set_temperature(PLUOXIUM_FORMATION_MIN_TEMP + 10)
				else
					// Inert control: matches no recipe, so it prices the cost of
					// react() deciding that there is nothing to do.
					air.set_moles(GAS_N2, MOLES_N2STANDARD)
					air.set_moles(GAS_O2, MOLES_O2STANDARD)
					air.set_temperature(T20C)
			add_to_active(T)
			if(length(air.reaction_results))
				reacting++
			CHECK_TICK
		live["[recipe]"] = reacting
	var/list/record = list(
		"rec" = "event",
		"event" = "zoo_prime",
		"cyc" = headless_bench_cycles,
		// Liveness carried from the previous interval: a recipe that never
		// reports a reaction is a dud cell, not a cheap reaction.
		"reacted_last_interval" = live,
		"t" = world.time,
	)
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)

// ---------------------------------------------------------------------------
// he-loop: a long run of heat exchanging pipes in a cold room. Plain pipes
// return PROCESS_KILL on their first machinery pass and leave; heat exchanging
// pipes override process_atmos and never return it, so they are processed every
// single fire forever, with no idle path of any kind. This scenario prices that
// standing cost directly.
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_he_loop()
	can_fire = FALSE
	var/outer_w = ATMOS_BENCH_HE_PIPES + 4
	var/outer_h = 8
	if(!atmos_headless_bench_reserve(outer_w, outer_h))
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	var/area/room_area = atmos_headless_bench_make_area("Atmos Bench HE Run")
	atmos_headless_bench_fill_box(base_x, base_y, base_z, outer_w, outer_h, room_area)
	room_area.reg_in_areas_in_z()

	var/pipe_y = base_y + round(outer_h / 2)
	for(var/index in 0 to ATMOS_BENCH_HE_PIPES - 1)
		var/turf/pipe_turf = locate(base_x + 2 + index, pipe_y, base_z)
		var/obj/machinery/atmospherics/pipe/heat_exchanging/simple/pipe = atmos_headless_bench_construct(new /obj/machinery/atmospherics/pipe/heat_exchanging/simple(pipe_turf), EAST)
		headless_bench_he_pipes += pipe
		CHECK_TICK
	atmos_headless_bench_reheat_he_loop()
	atmos_headless_bench_activate_floors()
	atmos_headless_bench_mark_ready(list(
		"he_pipes" = length(headless_bench_he_pipes),
		"awake_machines" = length(atmos_machinery),
	))

/// Reheats the pipeline the run belongs to. Also reports how many of the pipes
/// are still in the processing list, which is the number this scenario exists
/// to expose.
/datum/controller/subsystem/air/proc/atmos_headless_bench_reheat_he_loop()
	var/list/datum/pipeline/seen = list()
	var/heated = 0
	var/processing = 0
	for(var/obj/machinery/atmospherics/pipe/heat_exchanging/pipe as anything in headless_bench_he_pipes)
		if(QDELETED(pipe))
			continue
		if(pipe.atmos_processing)
			processing++
		var/datum/pipeline/parent = pipe.parent
		if(!parent?.air || (parent in seen))
			continue
		seen += parent
		parent.air.set_moles(GAS_N2, max(parent.air.get_moles(GAS_N2), MOLES_N2STANDARD * 10))
		parent.air.set_temperature(ATMOS_BENCH_HE_HOT_TEMPERATURE)
		heated++
	var/list/record = list(
		"rec" = "event",
		"event" = "he_reheat",
		"cyc" = headless_bench_cycles,
		"pipelines" = heated,
		"pipes_processing" = processing,
		"pipes_total" = length(headless_bench_he_pipes),
		"t" = world.time,
	)
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)

// ---------------------------------------------------------------------------
// atom-churn: a room packed with atmos-sensitive structures, held above their
// exposure thresholds. Nothing else in the suite puts a single atom into
// SSair.atom_process, so the c_ao phase read a flat zero in every previous run.
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_atom_churn()
	can_fire = FALSE
	var/outer_w = ATMOS_BENCH_ATOM_ROOM + 2
	var/outer_h = ATMOS_BENCH_ATOM_ROOM + 2
	if(!atmos_headless_bench_reserve(outer_w, outer_h))
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	var/area/room_area = atmos_headless_bench_make_area("Atmos Bench Atom Room")
	atmos_headless_bench_fill_box(base_x, base_y, base_z, outer_w, outer_h, room_area)
	room_area.reg_in_areas_in_z()

	var/alarms = 0
	var/grilles = 0
	var/index = 0
	for(var/turf/open/T as anything in headless_bench_room_turfs)
		index++
		if(index % ATMOS_BENCH_ATOM_ALARM_STRIDE == 0)
			// Fire alarms re-alarm every exposure without consuming themselves,
			// so they hold the list at a steady size for the whole run.
			var/obj/machinery/firealarm/alarm = new(T)
			alarm.set_machine_stat(0)
			alarms++
		else if(index % ATMOS_BENCH_ATOM_GRILLE_STRIDE == 0)
			// Grilles burn down and drop out: that decay is the enrol/unenrol
			// churn, visible as the ao count sliding across the run.
			new /obj/structure/grille(T)
			grilles++
		CHECK_TICK
	atmos_headless_bench_reheat_atom_room()
	atmos_headless_bench_activate_floors()
	atmos_headless_bench_mark_ready(list(
		"firealarms" = alarms,
		"grilles" = grilles,
		"room_turfs" = length(headless_bench_room_turfs),
	))

/// Holds the room above every exposure threshold in play. Without the reheat
/// the gas cools past the fire alarm limit and the phase silently empties.
/datum/controller/subsystem/air/proc/atmos_headless_bench_reheat_atom_room()
	for(var/turf/open/T as anything in headless_bench_room_turfs)
		if(!T.air)
			continue
		// Inert: the room has to be hot, not on fire, or this measures hotspots.
		T.air.set_moles(GAS_N2, MOLES_N2STANDARD)
		T.air.set_moles(GAS_O2, 0)
		T.air.set_temperature(ATMOS_BENCH_ATOM_TEMPERATURE)
		add_to_active(T)
		CHECK_TICK
	var/list/record = list(
		"rec" = "event",
		"event" = "atom_reheat",
		"cyc" = headless_bench_cycles,
		"atom_process" = length(atom_process),
		"t" = world.time,
	)
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)

// ---------------------------------------------------------------------------
// changeturf-storm: a wall stripe that walks across a room, one column per
// interval. Every step tears down and rebuilds adjacency for hundreds of tiles,
// which is the cost profile of explosions, shuttle transits and heavy
// construction - none of which any other scenario produces.
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_changeturf_storm()
	can_fire = FALSE
	var/outer_w = ATMOS_BENCH_STORM_WIDTH + 2
	var/outer_h = ATMOS_BENCH_STORM_HEIGHT + 2
	if(!atmos_headless_bench_reserve(outer_w, outer_h))
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	var/area/room_area = atmos_headless_bench_make_area("Atmos Bench Storm Hall")
	atmos_headless_bench_fill_box(base_x, base_y, base_z, outer_w, outer_h, room_area)
	room_area.reg_in_areas_in_z()

	// A standing pressure split, so every stripe move actually moves gas rather
	// than rebuilding adjacency between two identical mixtures.
	var/mid_x = base_x + round(outer_w / 2)
	for(var/turf/open/T as anything in headless_bench_room_turfs)
		var/ratio = T.x < mid_x ? 2 : 0.5
		T.air.set_moles(GAS_O2, MOLES_O2STANDARD * ratio)
		T.air.set_moles(GAS_N2, MOLES_N2STANDARD * ratio)
		CHECK_TICK
	atmos_headless_bench_activate_floors()
	atmos_headless_bench_mark_ready(list(
		"room_turfs" = length(headless_bench_room_turfs),
		"stripe_height" = ATMOS_BENCH_STORM_HEIGHT,
	))

/// Restores the previous stripe to floor and walls the next column.
/datum/controller/subsystem/air/proc/atmos_headless_bench_move_storm_stripe()
	var/restored = 0
	for(var/turf/T as anything in headless_bench_storm_walls)
		var/turf/open/floor/floor = T.ChangeTurf(/turf/open/floor/plasteel)
		floor.ImmediateCalculateAdjacentTurfs()
		add_to_active(floor)
		restored++
		CHECK_TICK
	headless_bench_storm_walls.Cut()

	if(!headless_bench_reservation)
		return
	var/base_x = headless_bench_reservation.bottom_left_coords[1]
	var/base_y = headless_bench_reservation.bottom_left_coords[2]
	var/base_z = headless_bench_reservation.bottom_left_coords[3]
	headless_bench_storm_column = (headless_bench_storm_column % ATMOS_BENCH_STORM_WIDTH) + 1
	var/wall_x = base_x + headless_bench_storm_column
	var/raised = 0
	for(var/y in base_y + 1 to base_y + ATMOS_BENCH_STORM_HEIGHT)
		var/turf/T = locate(wall_x, y, base_z)
		if(!isopenturf(T))
			continue
		T.ChangeTurf(/turf/closed/wall)
		headless_bench_storm_walls += T
		raised++
		CHECK_TICK
	var/list/record = list(
		"rec" = "event",
		"event" = "storm_stripe",
		"cyc" = headless_bench_cycles,
		"column" = headless_bench_storm_column,
		"raised" = raised,
		"restored" = restored,
		"adjacency_queue" = length(SSadjacent_air.queue),
		"t" = world.time,
	)
	rustg_file_append("[json_encode(record)]\n", GLOB.atmos_headless_bench_path)

// ---------------------------------------------------------------------------
// station-breach: the realism check for everything above. The synthetic arenas
// are sterile - no lighting, no station machinery, no contents - so phases that
// only cost anything on a lived-in map read as free in them. This one runs on
// the loaded map itself: it litters the station floors, then punches a hull
// breach through the middle of it at the event cycle.
//
// Deliberately no area filter by type: the fork's maps do not share one station
// area root, so the selector is "open floor on a station z-level", which holds
// on every map the bench can boot.
// ---------------------------------------------------------------------------
/datum/controller/subsystem/air/proc/atmos_headless_bench_build_station_breach()
	can_fire = FALSE
	var/list/turf/open/floor/candidates = list()
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		for(var/turf/open/floor/floor as anything in block(locate(1, 1, z), locate(world.maxx, world.maxy, z)))
			if(!istype(floor) || !floor.air || isspaceturf(floor))
				continue
			// Powered, non-shuttle areas only. The station z-level also carries
			// docked shuttles and unpowered ruins, and the first attempt at this
			// scenario put its "middle of the station" breach inside the mining
			// shuttle - a real hull breach, but not the pressurised station
			// interior the scenario is supposed to be about.
			var/area/floor_area = floor.loc
			if(!istype(floor_area) || !floor_area.requires_power || istype(floor_area, /area/shuttle))
				continue
			candidates += floor
			CHECK_TICK
	if(!length(candidates))
		log_world("ATMOS-BENCH: station-breach found no station floors, running as plain settling")
		headless_bench_scenario = null
		headless_bench_scenario_ready = TRUE
		headless_bench_scenario_building = FALSE
		can_fire = TRUE
		return

	var/litter = 0
	for(var/index in 1 to length(candidates))
		if(index % ATMOS_BENCH_STATION_ITEM_STRIDE)
			continue
		if(litter >= ATMOS_BENCH_STATION_ITEM_CAP)
			break
		new /obj/item/stack/sheet/metal(candidates[index])
		litter++
		CHECK_TICK

	// Deterministic breach site: the middle of the scan order. Same map plus
	// same seed lands on the same tile, so A/B runs are comparable.
	var/turf/center = candidates[round(length(candidates) / 2) || 1]
	var/half = round(ATMOS_BENCH_STATION_BREACH_SIDE / 2)
	for(var/x in center.x - half to center.x + half)
		for(var/y in center.y - half to center.y + half)
			var/turf/T = locate(x, y, center.z)
			if(T)
				headless_bench_event_turfs += T
			CHECK_TICK
	var/area/breach_area = get_area(center)
	atmos_headless_bench_mark_ready(list(
		"station_floors" = length(candidates),
		"litter" = litter,
		"breach_turfs" = length(headless_bench_event_turfs),
		"breach_at" = "[center.x],[center.y],[center.z]",
		"breach_area" = breach_area ? "[breach_area.type]" : null,
	))

#undef ATMOS_BENCH_FIRE_CORRIDOR_LENGTH
#undef ATMOS_BENCH_FIRE_CORRIDOR_WIDTH
#undef ATMOS_BENCH_FIRE_PLASMA_COLUMNS
#undef ATMOS_BENCH_FIRE_PLASMA_MOLES
#undef ATMOS_BENCH_HALL_WIDTH
#undef ATMOS_BENCH_HALL_HEIGHT
#undef ATMOS_BENCH_HALL_PRESSURE_RATIO_HIGH
#undef ATMOS_BENCH_HALL_PRESSURE_RATIO_LOW
#undef ATMOS_BENCH_GRID_COLS
#undef ATMOS_BENCH_GRID_ROWS
#undef ATMOS_BENCH_GRID_ROOM
#undef ATMOS_BENCH_GRID_RATIO_HIGH
#undef ATMOS_BENCH_GRID_RATIO_LOW
#undef ATMOS_BENCH_PIPE_ROOMS
#undef ATMOS_BENCH_PIPE_ROOM_SPAN
#undef ATMOS_BENCH_PIPE_VENT_TARGET_HIGH
#undef ATMOS_BENCH_PIPE_VENT_TARGET_LOW
#undef ATMOS_BENCH_VENT_RELEASING
#undef ATMOS_BENCH_VENT_EXT_BOUND
#undef ATMOS_BENCH_HEAT_ROOM
#undef ATMOS_BENCH_HEAT_HOT_MOLES
#undef ATMOS_BENCH_HEAT_HOT_TEMPERATURE
#undef ATMOS_BENCH_WIND_WIDTH
#undef ATMOS_BENCH_WIND_HEIGHT
#undef ATMOS_BENCH_WIND_ITEM_STRIDE
#undef ATMOS_BENCH_ZOO_CELL
#undef ATMOS_BENCH_ZOO_COLS
#undef ATMOS_BENCH_ZOO_ROWS
#undef ATMOS_BENCH_HE_PIPES
#undef ATMOS_BENCH_HE_HOT_TEMPERATURE
#undef ATMOS_BENCH_ATOM_ROOM
#undef ATMOS_BENCH_ATOM_ALARM_STRIDE
#undef ATMOS_BENCH_ATOM_GRILLE_STRIDE
#undef ATMOS_BENCH_ATOM_TEMPERATURE
#undef ATMOS_BENCH_STORM_WIDTH
#undef ATMOS_BENCH_STORM_HEIGHT
#undef ATMOS_BENCH_STATION_ITEM_STRIDE
#undef ATMOS_BENCH_STATION_ITEM_CAP
#undef ATMOS_BENCH_STATION_BREACH_SIDE

#endif // ifdef ATMOS_HEADLESS_BENCH
