/// Tests for who gets consulted when a movable leaves a turf.
///
/// Leaving a turf used to walk its `contents` twice: BYOND's own Exit() calls
/// Uncross() natively on everything standing there, and /turf/Exit() then did
/// the same walk again in DM to add its Bump-on-border and PHASING handling.
/// In round 9800 that came to 553k Uncross() calls in 78 seconds — roughly 55
/// per step — and essentially none of them could refuse the exit.
///
/// Upstream removed the native pass for the same reason (their doc comment on
/// Uncross() cites a round where it collapsed the master controller outright).
/// Only the DM walk remains, and it only visits atoms that declare
/// blocks_exit_checks.

/// The probes tell the two passes apart by their arity: /turf/Exit() passes a
/// destination, BYOND's native pass does not.
/obj/item/exit_probe
	name = "exit probe"
	var/turf_exit_checks = 0
	var/engine_uncross_checks = 0

/obj/item/exit_probe/Uncross(atom/movable/AM, atom/newloc)
	if(newloc)
		turf_exit_checks++
	else
		engine_uncross_checks++
	return ..()

/mob/living/simple_animal/exit_probe_mob
	name = "exit probe mob"
	var/turf_exit_checks = 0
	var/engine_uncross_checks = 0

/mob/living/simple_animal/exit_probe_mob/Uncross(atom/movable/AM, atom/newloc)
	if(newloc)
		turf_exit_checks++
	else
		engine_uncross_checks++
	return ..()

/// A structure that really does want to be consulted, and can refuse.
/obj/structure/exit_blocker_probe
	name = "exit blocker probe"
	var/deny = FALSE
	var/consulted = 0

/obj/structure/exit_blocker_probe/Uncross(atom/movable/AM, atom/newloc)
	. = ..()
	consulted++
	if(deny)
		return FALSE

/// Stands in for the COMSIG_ATOM_EXIT + connect_loc pattern that replaces an
/// Uncross() override.
/datum/exit_veto_probe
	var/vetoes = 0

/datum/exit_veto_probe/proc/guard(atom/source, atom/movable/leaving, atom/new_loc)
	SIGNAL_HANDLER
	vetoes++
	return COMPONENT_ATOM_BLOCK_EXIT

// -----------------------------------------------------------------------------
// The native pass is the half that cannot be gated, so it has to go entirely.
// -----------------------------------------------------------------------------

/datum/unit_test/turf_exit_does_not_run_the_engine_pass

/datum/unit_test/turf_exit_does_not_run_the_engine_pass/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)

	var/obj/item/exit_probe/dropped = allocate(/obj/item/exit_probe, origin)
	var/mob/living/simple_animal/exit_probe_mob/bystander = allocate(/mob/living/simple_animal/exit_probe_mob, origin)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)

	TEST_ASSERT(origin.Exit(walker, destination), "Leaving a turf full of harmless things must be allowed")
	TEST_ASSERT_EQUAL(dropped.engine_uncross_checks, 0, "BYOND's native Uncross pass must not run over a loose item")
	TEST_ASSERT_EQUAL(bystander.engine_uncross_checks, 0, "BYOND's native Uncross pass must not run over a bystanding mob")

// -----------------------------------------------------------------------------
// The DM walk is what remains, so it must still do the whole job.
// -----------------------------------------------------------------------------

/datum/unit_test/turf_exit_skips_atoms_that_cannot_block

/datum/unit_test/turf_exit_skips_atoms_that_cannot_block/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)

	var/list/probes = list()
	for(var/i in 1 to 3)
		probes += allocate(/obj/item/exit_probe, origin)
	var/mob/living/simple_animal/exit_probe_mob/bystander = allocate(/mob/living/simple_animal/exit_probe_mob, origin)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)

	TEST_ASSERT(origin.Exit(walker, destination), "A human should be able to leave a turf holding only items and mobs")
	for(var/obj/item/exit_probe/probe as anything in probes)
		TEST_ASSERT_EQUAL(probe.turf_exit_checks, 0, "A loose item must not be consulted when something leaves its turf")
	TEST_ASSERT_EQUAL(bystander.turf_exit_checks, 0, "A bystanding mob must not be consulted when something leaves its turf")

/datum/unit_test/turf_exit_consults_declared_blockers

/datum/unit_test/turf_exit_consults_declared_blockers/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)

	var/obj/structure/exit_blocker_probe/gate = allocate(/obj/structure/exit_blocker_probe, origin)
	TEST_ASSERT(gate.blocks_exit_checks, "A structure is consulted on exit unless it opts out")
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)

	TEST_ASSERT(origin.Exit(walker, destination), "A permissive blocker must let the mover through")
	TEST_ASSERT_EQUAL(gate.consulted, 1, "A declared blocker must be consulted exactly once per exit")

	gate.deny = TRUE
	TEST_ASSERT(!origin.Exit(walker, destination), "A refusing blocker must still stop the exit")

/datum/unit_test/turf_exit_still_consults_border_structures

/datum/unit_test/turf_exit_still_consults_border_structures/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/blocked_side = get_step(origin, EAST)
	var/turf/open_side = get_step(origin, WEST)

	var/obj/structure/railing/fence = allocate(/obj/structure/railing, origin)
	fence.setDir(EAST)
	fence.density = TRUE
	TEST_ASSERT(fence.blocks_exit_checks, "A railing must declare itself as an exit checker")

	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)

	TEST_ASSERT(!origin.Exit(walker, blocked_side), "An east-facing railing must still block an exit to the east")
	TEST_ASSERT(origin.Exit(walker, open_side), "An east-facing railing must not block an exit to the west")

// -----------------------------------------------------------------------------
// /atom/Exit() no longer defers to BYOND, so its own contract has to hold on its
// own: allow by default, and honour a COMSIG_ATOM_EXIT veto. The latter is the
// replacement for an Uncross() override.
// -----------------------------------------------------------------------------

/datum/unit_test/atom_exit_allows_by_default

/datum/unit_test/atom_exit_allows_by_default/Run()
	var/obj/effect/container = allocate(/obj/effect)
	var/obj/item/passenger = allocate(/obj/item, container)

	TEST_ASSERT(container.Exit(passenger, null), "A plain atom must let its contents leave")
	TEST_ASSERT(container.Exit(passenger, run_loc_floor_bottom_left), "A plain atom must let its contents leave towards a turf too")

/datum/unit_test/atom_exit_honours_signal_veto

/datum/unit_test/atom_exit_honours_signal_veto/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)

	var/datum/exit_veto_probe/guard = new
	guard.RegisterSignal(origin, COMSIG_ATOM_EXIT, TYPE_PROC_REF(/datum/exit_veto_probe, guard))

	var/allowed = origin.Exit(walker, destination)
	var/vetoes = guard.vetoes
	guard.UnregisterSignal(origin, COMSIG_ATOM_EXIT)
	qdel(guard)

	TEST_ASSERT_EQUAL(vetoes, 1, "The exit signal must be sent exactly once")
	TEST_ASSERT(!allowed, "A COMSIG_ATOM_EXIT veto must still stop the exit")
