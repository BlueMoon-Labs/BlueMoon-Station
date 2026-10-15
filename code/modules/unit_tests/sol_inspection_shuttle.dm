/// Exercise the actual event, map initialization, crew equipment and both legs of the flight.
/datum/unit_test/sol_inspection_shuttle
	var/datum/round_event/sol_inspection/event
	var/obj/docking_port/stationary/landing
	var/list/cryo_deletions = list()

/datum/unit_test/sol_inspection_shuttle/Destroy()
	// Cryosleep defers gear deletion; do not leak our queue into later subsystem tests.
	for(var/atom/movable/pending as anything in cryo_deletions)
		SSauto_cryo.delete_queue -= pending
		if(!QDELETED(pending))
			qdel(pending)
	var/datum/team/sol_inspection/team = event?.inspection_team
	var/obj/docking_port/mobile/sol_inspection/vessel = team?.shuttle
	if(vessel && !QDELETED(vessel))
		var/obj/docking_port/stationary/home = vessel.home_dock
		vessel.jumpToNullSpace()
		qdel(home, force = TRUE)
	if(landing)
		qdel(landing, force = TRUE)
	if(team)
		QDEL_NULL(team.account)
		qdel(team)
	QDEL_NULL(event)
	return ..()

/datum/unit_test/sol_inspection_shuttle/Run()
	var/polls_before = SSpolling.total_polls
	event = new(FALSE)
	// start() only asks the crew for a bribe; the vessel is loaded once the demand is refused or expires.
	event.launch_inspection()
	TEST_ASSERT_EQUAL(SSpolling.total_polls, polls_before, "Sol inspection must announce capsule availability without starting recruitment polls.")
	var/datum/team/sol_inspection/team = event.inspection_team
	TEST_ASSERT(team, "The event must load the inspection vessel at CentCom.")
	var/obj/docking_port/mobile/sol_inspection/vessel = team.shuttle
	TEST_ASSERT(vessel && is_centcom_level(vessel.z), "The initial berth must be in the CentCom sector.")
	TEST_ASSERT(vessel.home_dock == vessel.get_docked(), "The home berth must be linked to the vessel.")
	TEST_ASSERT_EQUAL(vessel.width, 23, "The entire source hull must fit in the mobile port.")
	TEST_ASSERT_EQUAL(vessel.height, 23, "The entire source hull must fit in the mobile port.")

	var/spawner_count = 0
	var/sign_count = 0
	var/list/cryo_pods = list()
	var/obj/machinery/computer/cryopod/cryo_console
	var/obj/machinery/computer/shuttle/sol_inspection/flight_console
	var/obj/effect/mob_spawn/human/sol_inspector/commander/commander
	var/obj/effect/mob_spawn/human/sol_inspector/inspector_spawner
	var/obj/effect/mob_spawn/human/sol_inspector/guard/guard
	for(var/area/shuttle_area as anything in vessel.shuttle_areas)
		for(var/obj/machinery/cryopod/pod in shuttle_area)
			cryo_pods += pod
		for(var/obj/machinery/computer/cryopod/console in shuttle_area)
			cryo_console = console
		for(var/obj/machinery/computer/shuttle/sol_inspection/console in shuttle_area)
			flight_console = console
		for(var/obj/structure/sign/sign in shuttle_area)
			sign_count++
			TEST_ASSERT(sign.pixel_x == 32 * ((sign.dir == EAST) - (sign.dir == WEST)), "Shuttle signs must be displaced horizontally onto their supporting wall.")
			TEST_ASSERT(sign.pixel_y == 32 * ((sign.dir == NORTH) - (sign.dir == SOUTH)), "Shuttle signs must be displaced vertically onto their supporting wall.")
		for(var/obj/effect/mob_spawn/human/sol_inspector/spawner in shuttle_area)
			spawner_count++
			TEST_ASSERT(spawner.inspection_team == team, "All crew slots must share the event's team and bank account.")
			TEST_ASSERT(spawner.flags_1 & INITIALIZED_1, "Crew capsules must be initialized after the shuttle loads.")
			TEST_ASSERT(spawner in GLOB.poi_list, "Crew capsules must be selectable through Spawners Menu.")
			TEST_ASSERT(spawner in GLOB.mob_spawners[spawner.job_description], "Crew capsules must be registered in Spawners Menu.")
			TEST_ASSERT_EQUAL(spawner.category, "sol", "Crew capsules must use the Sol category supported by SpawnersMenu.")
			TEST_ASSERT(spawner.skip_reentry_check, "Inspection roles must accept observers outside the usual ghost-role eligibility pool.")
			if(istype(spawner, /obj/effect/mob_spawn/human/sol_inspector/commander))
				commander = spawner
			if(istype(spawner.outfit, /datum/outfit/sol_inspection/inspector))
				inspector_spawner = spawner
			if(istype(spawner, /obj/effect/mob_spawn/human/sol_inspector/guard))
				guard = spawner
	TEST_ASSERT_EQUAL(spawner_count, 4, "The vessel must contain four crew slots.")
	TEST_ASSERT_EQUAL(sign_count, 5, "The vessel must retain its five wall-mounted signs and posters.")
	TEST_ASSERT(commander, "The inspection needs a commander slot.")
	TEST_ASSERT(inspector_spawner, "The inspection needs an inspector slot.")
	TEST_ASSERT(guard, "The inspection needs a guard slot.")
	TEST_ASSERT_EQUAL(length(cryo_pods), 2, "The vessel must contain two round-exit cryopods.")
	TEST_ASSERT(cryo_console, "The cryopods need an onboard storage console.")
	var/cryo_console_direction = cryo_console.dir
	for(var/obj/machinery/cryopod/pod as anything in cryo_pods)
		TEST_ASSERT(pod.control_computer_weakref?.resolve() == cryo_console, "Each cryopod must link to the onboard console after map initialization.")
	TEST_ASSERT(flight_console, "The inspection needs a flight console for the return trip.")
	TEST_ASSERT(!home_destination_visible(flight_console), "The console must not offer a return before the first station visit.")
	var/mob/living/carbon/human/inspector = allocate(/mob/living/carbon/human, get_turf(commander))
	inspector.mind_initialize("sol_shuttle_test")
	commander.equip(inspector)
	commander.special(inspector)
	TEST_ASSERT(locate(/obj/item/sol_inspection_scanner) in inspector.GetAllContents(), "The commander's equipped outfit must include an inspection scanner.")
	for(var/obj/effect/mob_spawn/human/sol_inspector/spawner as anything in list(inspector_spawner, guard))
		var/mob/living/carbon/human/crew_member = allocate(/mob/living/carbon/human, get_turf(spawner))
		spawner.equip(crew_member)
		TEST_ASSERT(locate(/obj/item/sol_inspection_scanner) in crew_member.GetAllContents(), "Each equipped Sol inspection outfit must include an inspection scanner.")
	var/obj/item/card/id/card = inspector.wear_id
	TEST_ASSERT(card?.registered_account == team.account, "The spawned inspector's ID must use the shared account.")
	TEST_ASSERT(istype(inspector.wear_suit, /obj/item/clothing/suit/space/hardsuit/ert/alert/sol), "The inspector must wear the Sol hardsuit.")
	TEST_ASSERT_EQUAL(vessel.canDock(vessel.home_dock), SHUTTLE_NOT_A_DOCKING_PORT, "Return must be locked before the first inspection visit.")

	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/landing_direction = turn(vessel.dir, 90)
	var/turf/landing_turf
	// Runtime Station is not empty at fixed coordinates; locate a berth for the full hull.
	for(var/test_x in 24 to world.maxx - 24 step 24)
		for(var/test_y in 24 to world.maxy - 24 step 24)
			var/clear = TRUE
			for(var/turf/place as anything in vessel.return_ordered_turfs(test_x, test_y, station_z, landing_direction))
				if(!isspaceturf(place) || length(place.contents))
					clear = FALSE
					break
			if(clear)
				landing_turf = locate(test_x, test_y, station_z)
				break
		if(landing_turf)
			break
	TEST_ASSERT(landing_turf, "The test requires an empty station-sector berth.")
	landing = new(landing_turf)
	landing.setDir(landing_direction)
	landing.width = vessel.width
	landing.height = vessel.height
	landing.dwidth = vessel.dwidth
	landing.dheight = vessel.dheight
	landing.area_type = /area/space
	TEST_ASSERT_EQUAL(vessel.initiate_docking(landing), DOCKING_SUCCESS, "The loaded vessel must fly to the station sector.")
	TEST_ASSERT_EQUAL(vessel.dir, landing_direction, "The flight must exercise a 90-degree shuttle rotation.")
	TEST_ASSERT_EQUAL(cryo_console.dir, cryo_console_direction, "The cryo console must retain its readable orientation when the shuttle rotates.")
	TEST_ASSERT(team.visited_station, "The first station arrival must start the return timer.")
	TEST_ASSERT(team.return_available_at > world.time + 89 MINUTES, "The return delay must be 90 minutes.")
	TEST_ASSERT_EQUAL(vessel.canDock(vessel.home_dock), SHUTTLE_NOT_A_DOCKING_PORT, "Early return must remain blocked.")
	TEST_ASSERT(!home_destination_visible(flight_console), "The console must hide the CentCom berth during the inspection period.")
	team.return_available_at = world.time
	TEST_ASSERT(home_destination_visible(flight_console), "The console must automatically offer the CentCom berth when the 90-minute lock expires.")
	TEST_ASSERT_EQUAL(vessel.initiate_docking(vessel.home_dock), DOCKING_SUCCESS, "The vessel must return once the inspection period expires.")
	TEST_ASSERT(team.returned_home, "Returning to CentCom must finish the inspection.")
	TEST_ASSERT_EQUAL(cryo_console.dir, cryo_console_direction, "The cryo console must retain its orientation on the return flight too.")
	TEST_ASSERT(team.is_returned_inspector(inspector.mind), "A living inspector aboard the returning ship must complete the objective.")
	for(var/obj/machinery/cryopod/pod as anything in cryo_pods)
		var/datum/weakref/controller_ref = cryo_find_control_computer(pod)
		TEST_ASSERT(controller_ref?.resolve() == cryo_console, "Cryopods must retain their onboard console after both shuttle flights.")
	var/obj/machinery/cryopod/exit_pod = cryo_pods[1]
	exit_pod.close_machine(inspector)
	TEST_ASSERT(exit_pod.occupant == inspector, "An inspector must be able to enter an onboard cryopod.")
	var/list/previous_deletions = SSauto_cryo.delete_queue.Copy()
	exit_pod.despawn_occupant()
	cryo_deletions = SSauto_cryo.delete_queue - previous_deletions
	TEST_ASSERT(isnull(inspector.loc), "Cryosleep must remove the inspector from the round.")
	TEST_ASSERT_EQUAL(length(cryo_console.frozen_crew), 1, "The onboard console must record the inspector's departure.")
	TEST_ASSERT(!QDELETED(team.account), "Cryosleep must preserve the shared inspection account.")

/// Check the destination data actually rendered by ShuttleConsole.
/datum/unit_test/sol_inspection_shuttle/proc/home_destination_visible(obj/machinery/computer/shuttle/sol_inspection/console)
	var/list/data = console.ui_data()
	for(var/list/destination as anything in data["locations"])
		if(destination["id"] == "sol_inspection_home")
			return TRUE
	return FALSE
