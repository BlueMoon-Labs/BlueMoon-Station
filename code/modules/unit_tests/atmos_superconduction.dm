// ===== Superconduction: native rebuild of the solid-heat pass =====
//
// process_turf_heat() sat as an empty stub since the auxmos removal, so walls
// never carried heat anywhere. These tests pin the rebuilt native pass:
// gating on SSair.heat_enabled, heat crossing a conductive solid between two
// tiles, object-level thermal blocking, and the deliberate data choice that
// standard station walls (WALL_HEAT_TRANSFER_COEFFICIENT = 0) do not conduct.
//
// Also pins the adaptive zone-equalize valve: with the config flag off, the
// equalize stage engages only while an oversized excited group exists.

/// Deterministic conductive wall for the transfer test: plasma walls (the only
/// conductive mapped wall) ignite via temperature_expose and page admins.
/turf/closed/wall/unit_test_conductive
	thermal_conductivity = 0.04
	heat_capacity = 6000

/datum/unit_test/atmos_superconduction/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/hot_side = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/wall_site = locate(origin.x + 2, origin.y + 1, origin.z)
	var/turf/open/cold_side = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(hot_side) && istype(cold_side), "test strip is not open floor")

	var/saved_heat_enabled = SSair.heat_enabled
	var/original_wall_type = wall_site.type
	var/turf/wall_turf = wall_site.ChangeTurf(/turf/closed/wall/unit_test_conductive)
	hot_side.ImmediateCalculateAdjacentTurfs()
	cold_side.ImmediateCalculateAdjacentTurfs()
	wall_turf.ImmediateCalculateAdjacentTurfs()

	hot_side.air.clear()
	hot_side.air.set_moles(GAS_N2, 300)
	hot_side.air.set_temperature(1200)
	cold_side.air.clear()
	cold_side.air.set_moles(GAS_N2, MOLES_O2STANDARD + MOLES_N2STANDARD)
	cold_side.air.set_temperature(T20C)
	wall_turf.temperature = T20C

	// --- Gate: with heat disabled nothing may register ---
	SSair.heat_enabled = FALSE
	TEST_ASSERT(!hot_side.consider_superconductivity(starting = TRUE), "consider_superconductivity must refuse while heat_enabled is off")
	TEST_ASSERT(!(hot_side in SSair.active_super_conductivity), "the pass list must stay empty while heat_enabled is off")

	// --- Registration and transfer through a conductive solid ---
	SSair.heat_enabled = TRUE
	TEST_ASSERT(hot_side.consider_superconductivity(starting = TRUE), "hot dense air must register for superconduction")
	TEST_ASSERT(hot_side in SSair.active_super_conductivity, "registered turf missing from the pass list")

	var/wall_temp_before = wall_turf.return_temperature()
	var/cold_temp_before = cold_side.air.return_temperature()
	var/hot_temp_before = hot_side.air.return_temperature()
	for(var/i in 1 to 30)
		hot_side.archive()
		wall_turf.archive()
		cold_side.archive()
		for(var/turf/conducting as anything in SSair.active_super_conductivity.Copy())
			conducting.super_conduct()
	TEST_ASSERT(wall_turf.return_temperature() > wall_temp_before + 1, "conductive wall took no heat from the hot side ([wall_turf.return_temperature()] K)")
	TEST_ASSERT(cold_side.air.return_temperature() > cold_temp_before + 1, "heat never crossed the wall into the cold room ([cold_side.air.return_temperature()] K)")
	TEST_ASSERT(hot_side.air.return_temperature() < hot_temp_before - 1, "the hot side lost no heat ([hot_side.air.return_temperature()] K)")

	// --- An object that blocks heat must sever the direction ---
	var/obj/effect/clockwork/servant_blocker/blocker = new(wall_turf)
	hot_side.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(hot_side.conductivity_blocked_directions & get_dir(hot_side, wall_turf), "BlockThermalConductivity object did not mark the direction as heat-blocked")
	TEST_ASSERT(!(hot_side.conductivity_directions() & get_dir(hot_side, wall_turf)), "conductivity_directions still offers a heat-blocked direction")
	qdel(blocker, force = TRUE) // its Destroy() returns QDEL_HINT_LETMELIVE otherwise
	hot_side.ImmediateCalculateAdjacentTurfs()

	// --- Standard walls stay non-conductive by data, not by dead code ---
	wall_turf = wall_turf.ChangeTurf(/turf/closed/wall)
	hot_side.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(hot_side.conductivity_blocked_directions & get_dir(hot_side, wall_turf), "a zero-conductivity wall pairing must read as heat-blocked")

	// Cleanup: restore the strip and the global flag.
	SSair.active_super_conductivity -= hot_side
	SSair.active_super_conductivity -= wall_turf
	SSair.active_super_conductivity -= cold_side
	SSair.heat_enabled = saved_heat_enabled
	wall_turf.ChangeTurf(original_wall_type)
	var/turf/open/restored = locate(origin.x + 2, origin.y + 1, origin.z)
	if(istype(restored))
		restored.ImmediateCalculateAdjacentTurfs()
	hot_side.ImmediateCalculateAdjacentTurfs()
	cold_side.ImmediateCalculateAdjacentTurfs()
	unit_test_normalize_exposure_window(hot_side)
	unit_test_normalize_exposure_window(cold_side)
	SSair.remove_from_active(hot_side)
	SSair.remove_from_active(cold_side)

// Superconduction ships as a config flag with a runtime admin toggle, so the
// switch has to be clean in both directions: a pass list left populated pins
// turfs forever, and a conduction run caught mid-resume would keep conducting
// after the flag went down.
/datum/unit_test/atmos_heat_runtime_toggle/Run()
	var/saved_heat_enabled = SSair.heat_enabled
	var/saved_can_fire = SSair.can_fire
	SSair.can_fire = FALSE // no fire may walk our synthetic phase state

	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/hot_side = locate(origin.x + 1, origin.y + 1, origin.z)
	TEST_ASSERT(istype(hot_side), "no open turf for the heat toggle test")

	hot_side.air.clear()
	hot_side.air.set_moles(GAS_N2, 300)
	hot_side.air.set_temperature(1200)

	SSair.set_heat_enabled(TRUE)
	TEST_ASSERT(SSair.heat_enabled, "set_heat_enabled(TRUE) did not arm the conduction pass")
	TEST_ASSERT(hot_side.consider_superconductivity(starting = TRUE), "a hot turf refused to register while heat is enabled")
	TEST_ASSERT(length(SSair.active_super_conductivity), "the pass list is empty right after a successful registration")

	SSair.enter_conduction_phase_for_test()
	TEST_ASSERT(SSair.is_in_conduction_phase(), "the subsystem did not park in the conduction phase")

	SSair.set_heat_enabled(FALSE)
	TEST_ASSERT(!SSair.heat_enabled, "set_heat_enabled(FALSE) left the pass armed")
	TEST_ASSERT(!length(SSair.active_super_conductivity), "disabling heat left [length(SSair.active_super_conductivity)] turfs pinned in the pass list")
	TEST_ASSERT(!length(SSair.currentrun), "disabling heat left a resumable conduction run behind")
	TEST_ASSERT(!SSair.is_in_conduction_phase(), "the subsystem stayed parked in the conduction phase with heat disabled")
	TEST_ASSERT(!hot_side.consider_superconductivity(starting = TRUE), "a turf registered while heat is disabled")

	// The knob must be reachable from config, not only from code.
	SSair.set_heat_enabled(CONFIG_GET(flag/atmos_heat_enabled))
	TEST_ASSERT_EQUAL(SSair.heat_enabled, !!CONFIG_GET(flag/atmos_heat_enabled), "the config flag and the subsystem state disagree")

	// The run this test hijacked is deliberately not restored: set_heat_enabled()
	// left the subsystem in the rebuild-pipenets stage with an empty currentrun,
	// which every stage handles. Putting the saved list back would hand a stage
	// the previous stage's contents - a list of turfs reaching build_network().
	SSair.heat_enabled = saved_heat_enabled
	SSair.can_fire = saved_can_fire
	unit_test_normalize_exposure_window(hot_side)
	SSair.remove_from_active(hot_side)

/// Обмен с нулевой дельтой температур не переносит энергию, но безусловный
/// add_to_active на каждом проходе не давал осевшему соседу уснуть: после
/// станционного пожара в раунде 9911 две-три тысячи горячих стен приколачивали
/// 3-4 тысячи активных турфов до самого конца раунда.
/datum/unit_test/atmos_superconduction_wake_gate/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/subject = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/wall_site = locate(origin.x + 2, origin.y + 1, origin.z)
	TEST_ASSERT(istype(subject) && subject.air, "нет открытого турфа с воздухом для теста")

	var/saved_heat_enabled = SSair.heat_enabled
	var/original_wall_type = wall_site.type
	var/turf/wall_turf = wall_site.ChangeTurf(/turf/closed/wall/unit_test_conductive)
	subject.ImmediateCalculateAdjacentTurfs()
	wall_turf.ImmediateCalculateAdjacentTurfs()
	// Кондукция только в сторону испытуемого: остальные соседи стены не должны
	// ни греться, ни просыпаться от теста.
	wall_turf.conductivity_blocked_directions = (NORTH|SOUTH|EAST|WEST) & ~get_dir(wall_turf, subject)
	SSair.heat_enabled = TRUE

	// Осевшее состояние: стена и воздух на одной температуре, турф спит.
	subject.air.clear()
	subject.air.set_moles(GAS_N2, MOLES_O2STANDARD + MOLES_N2STANDARD)
	subject.air.set_temperature(500)
	wall_turf.temperature = 500
	SSair.remove_from_active(subject)
	TEST_ASSERT(!(subject in SSair.active_turfs), "предпосылка: турф не удалось усыпить")

	subject.archive()
	wall_turf.archive()
	wall_turf.super_conduct()
	TEST_ASSERT(!(subject in SSair.active_turfs), "обмен с нулевой дельтой температур разбудил осевший турф")

	// Настоящий перепад обязан и передать тепло, и разбудить воздух.
	subject.air.set_temperature(T20C)
	subject.archive()
	wall_turf.archive()
	wall_turf.super_conduct()
	TEST_ASSERT(subject in SSair.active_turfs, "перепад в две сотни кельвинов не разбудил турф")
	TEST_ASSERT(subject.air.return_temperature() > T20C + 1, "тепло из стены не дошло до воздуха ([subject.air.return_temperature()] K)")

	SSair.active_super_conductivity -= wall_turf
	SSair.active_super_conductivity -= subject
	SSair.heat_enabled = saved_heat_enabled
	wall_turf.ChangeTurf(original_wall_type)
	var/turf/open/restored = locate(origin.x + 2, origin.y + 1, origin.z)
	if(istype(restored))
		restored.ImmediateCalculateAdjacentTurfs()
	subject.ImmediateCalculateAdjacentTurfs()
	unit_test_normalize_exposure_window(subject)
	SSair.remove_from_active(subject)

/datum/unit_test/atmos_equalize_valve/Run()
	// Детектор проверяется относительно стартового состояния, а не относительно пустоты:
	// на больших картах (Festive, Layenia) атмос к моменту тестов ещё оседает и держит
	// собственную группу за порогом, так что "гигантских групп нет" - это утверждение
	// о живом мире, а не о коде.
	var/baseline_candidate = SSair.has_zone_equalize_candidate()

	// A synthetic group past the threshold must flip the detection.
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/subject = locate(origin.x + 1, origin.y + 1, origin.z)
	TEST_ASSERT(istype(subject), "no open turf for the synthetic group")
	// garbage_collect() снимает excited_group у каждого турфа своего списка, а тестовый
	// турф на живой станции может состоять в настоящей группе - её указатель возвращаем.
	var/datum/excited_group/subject_group = subject.excited_group
	var/datum/excited_group/group = new
	for(var/i in 1 to EXCITED_GROUP_ZONE_EQUALIZE_THRESHOLD)
		group.turf_list += subject
	TEST_ASSERT(SSair.has_zone_equalize_candidate(), "an excited group past EXCITED_GROUP_ZONE_EQUALIZE_THRESHOLD must arm the valve")
	group.garbage_collect()
	subject.excited_group = subject_group
	TEST_ASSERT_EQUAL(SSair.has_zone_equalize_candidate(), baseline_candidate, "detector did not return to its starting state after the synthetic group was collected")
