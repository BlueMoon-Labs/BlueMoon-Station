// The atmos_sensitive element shipped with a single consumer (fire alarms), so
// every atom that already implemented temperature_expose only ever reacted to a
// hotspot standing on its own tile - a room could sit at 2000 K with intact
// glass in it. These tests pin the flameless path: hot air alone enrolls the
// atom, damages it, and releases it once the room cools.

/datum/unit_test/atmos_exposure_consumers/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/site = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT(istype(site), "no open turf for the exposure consumer test")

	var/obj/structure/window/reinforced/pane = new(site)
	var/obj/structure/grille/mesh = new(site)
	var/obj/machinery/portable_atmospherics/canister/tank = new(site)
	var/list/subjects = list(pane, mesh, tank)

	// Pure nitrogen: hot enough for every threshold under test, inert enough
	// that no reaction lights a hotspot and reintroduces the flame path.
	site.air.clear()
	site.air.set_moles(GAS_N2, 500)
	site.air.set_temperature(2000)

	for(var/atom/subject as anything in subjects)
		subject.atmos_conditions_changed()
		TEST_ASSERT(subject.flags_1 & ATMOS_IS_PROCESSING_1, "[subject.type] did not enroll for atom processing in 2000 K air")
		TEST_ASSERT(subject in SSair.atom_process, "[subject.type] is flagged as processing but missing from SSair.atom_process")

	var/pane_before = pane.obj_integrity
	var/mesh_before = mesh.obj_integrity
	var/tank_before = tank.obj_integrity
	for(var/atom/subject as anything in subjects)
		subject.process_exposure()
	TEST_ASSERT(pane.obj_integrity < pane_before, "a reinforced window took no damage from 2000 K air ([pane.obj_integrity]/[pane_before])")
	TEST_ASSERT(mesh.obj_integrity < mesh_before, "a grille took no damage from 2000 K air ([mesh.obj_integrity]/[mesh_before])")
	TEST_ASSERT(tank.obj_integrity < tank_before, "a canister took no damage from 2000 K air ([tank.obj_integrity]/[tank_before])")

	// Cooling must release every subject: an atom left enrolled is a per-fire
	// cost with nothing to do.
	site.air.set_temperature(T20C)
	for(var/atom/subject as anything in subjects)
		subject.process_exposure()
		TEST_ASSERT(!(subject.flags_1 & ATMOS_IS_PROCESSING_1), "[subject.type] stayed enrolled in room-temperature air")
		TEST_ASSERT(!(subject in SSair.atom_process), "[subject.type] stayed in SSair.atom_process in room-temperature air")

	qdel(pane)
	qdel(mesh)
	qdel(tank)
	site.ImmediateCalculateAdjacentTurfs()
	unit_test_normalize_exposure_window(site)
	SSair.remove_from_active(site)
