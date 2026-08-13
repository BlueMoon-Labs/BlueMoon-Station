/// Heat exchanging pipes used to be the only atmos machinery with no idle path
/// at all: ordinary pipes leave processing on their first pass via PROCESS_KILL,
/// but heat exchangers override process_atmos and return nothing, so SSair kept
/// running every one of them every single fire forever. The headless he-loop
/// scenario measured 200 of them at 2.31ms - 69% of the whole machinery phase -
/// while sitting at thermal equilibrium with the room, doing no work whatsoever.
///
/// These tests pin the two halves of the fix: a pipe that has nothing to conduct
/// must fall asleep, and every way its situation can change must wake it back up.
/// Getting the second half wrong would silently break engineering - a sleeping
/// supermatter cooling loop is far worse than a slow one.

/// Sets up an isolated heat exchanging pipe with its own pipeline, so the test
/// controls both sides of the temperature comparison.
/datum/unit_test/proc/make_he_pipe(turf/open/room, pipe_temperature, list/created_pipelines)
	var/obj/machinery/atmospherics/pipe/heat_exchanging/simple/pipe = allocate(/obj/machinery/atmospherics/pipe/heat_exchanging/simple, room)
	var/datum/pipeline/net = new
	net.air = new /datum/gas_mixture(max(pipe.volume, 1))
	net.air.set_moles(GAS_N2, MOLES_N2STANDARD)
	net.air.set_temperature(pipe_temperature)
	// track_member is the same call the real assembly path (build_pipeline,
	// addMember, merge) uses, so the heat exchanging index is populated exactly
	// as it would be on a mapped pipenet.
	net.track_member(pipe)
	pipe.parent = net
	created_pipelines += net
	return pipe

/datum/unit_test/atmos_he_pipe_sleep/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/list/datum/pipeline/created_pipelines = list()
	var/room_temperature = room.air.return_temperature()

	// 1. A pipe whose air already matches the room has nothing to conduct, so a
	//    full no-op streak has to take it out of the processing list.
	var/obj/machinery/atmospherics/pipe/heat_exchanging/simple/settled = make_he_pipe(room, room_temperature, created_pipelines)
	TEST_ASSERT(settled.atmos_processing, "freshly created heat exchanging pipe is not in SSair processing")
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		settled.process_atmos()
	TEST_ASSERT(!settled.atmos_processing, "a heat exchanging pipe at equilibrium stayed in SSair processing")
	TEST_ASSERT(!(settled in SSair.atmos_machinery), "the sleeping heat exchanging pipe stayed in atmos_machinery")
	TEST_ASSERT(settled.atmos_idle_queued, "the sleeping heat exchanging pipe is not flagged as queued")

	// 2. A pipe with a real temperature difference is doing its job every fire
	//    and must never be allowed to doze off. It goes on a different tile:
	//    conducting into the same room would drag the first pipe out of the
	//    equilibrium the rest of this test depends on.
	var/turf/open/far_room = run_loc_floor_top_right
	TEST_ASSERT(istype(far_room) && far_room != room, "second test location is not a distinct open turf")
	var/far_temperature = far_room.air.return_temperature()
	var/obj/machinery/atmospherics/pipe/heat_exchanging/simple/working = make_he_pipe(far_room, far_temperature + 500, created_pipelines)
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK * 2)
		working.process_atmos()
	TEST_ASSERT(working.atmos_processing, "a conducting heat exchanging pipe fell asleep mid-transfer")
	TEST_ASSERT(working.parent.air.return_temperature() < far_temperature + 500, "the conducting pipe never actually moved heat")

	// 3. The room heating up has to reach a sleeping pipe. Sleeping machines
	//    subscribe to their turf, and air-changing activations fire that list.
	TEST_ASSERT(settled in room.atmos_wake_machines, "the sleeping pipe did not register for turf wake-ups")
	SSair.add_to_active(room)
	TEST_ASSERT(settled.atmos_processing, "a turf air change did not wake the sleeping heat exchanging pipe")

	// 4. Heat arriving through the pipeline itself must wake it too. This is the
	//    path the pressure broadcast cannot cover: heat exchanging pipes live in
	//    the pipeline's members list, not in other_atmosmch.
	// Waking it also let it conduct, so restore the equilibrium explicitly rather
	// than assuming the room is still where it started.
	settled.parent.air.set_temperature(room.air.return_temperature())
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		settled.process_atmos()
	TEST_ASSERT(!settled.atmos_processing, "the pipe did not go back to sleep after the turf wake")
	var/datum/pipeline/net = settled.parent
	TEST_ASSERT(settled in net.heat_exchanging_members, "the pipeline is not tracking its heat exchanging member")
	net.air.set_temperature(room_temperature + 800)
	net.update = TRUE
	net.process()
	TEST_ASSERT(settled.atmos_processing, "a pipeline temperature jump did not wake the sleeping heat exchanging pipe")

	for(var/datum/pipeline/created as anything in created_pipelines)
		qdel(created)
