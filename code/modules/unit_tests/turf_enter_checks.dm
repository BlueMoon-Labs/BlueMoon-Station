/// Tests for who gets consulted when a movable enters a turf.
///
/// /turf/Enter walks the destination's contents and calls Cross() on everything
/// standing there. The walk order is contents order, which is creation order,
/// not priority: the real priority is assembled in firstbump by layer and by
/// ON_BORDER_1. None of that had a test, and the walk cannot be rewritten
/// without one.
///
/// The exit side of the same contract lives in turf_exit_checks.dm.

/// A dense probe that always refuses, counting both how often it was asked and
/// how often something ran into it.
/obj/structure/enter_probe
	name = "enter probe"
	density = TRUE
	anchored = TRUE
	var/consulted = 0
	var/bumps = 0

/obj/structure/enter_probe/CanPass(atom/movable/mover, turf/target)
	consulted++
	return FALSE

/obj/structure/enter_probe/Bumped(atom/movable/bumping)
	bumps++
	return ..()

/// ON_BORDER_1 has to outrank layer when the victim of the bump is picked.
/obj/structure/enter_probe/border

/obj/structure/enter_probe/border/Initialize(mapload)
	. = ..()
	flags_1 |= ON_BORDER_1

/// Deletes the mover mid-walk. Enter() has to survive that and refuse.
/obj/structure/enter_probe/deleter

/obj/structure/enter_probe/deleter/CanPass(atom/movable/mover, turf/target)
	consulted++
	qdel(mover)
	return FALSE

/// Throws the mover somewhere else from inside Bumped(). The move has to be
/// abandoned rather than completed into the turf.
/obj/structure/enter_probe/shover

/// Counting is left to the parent - incrementing here as well would score one
/// bump twice.
/obj/structure/enter_probe/shover/Bumped(atom/movable/bumping)
	bumping.forceMove(get_step(bumping, WEST))
	return ..()

// -----------------------------------------------------------------------------
// Picking the victim of the bump
// -----------------------------------------------------------------------------

/datum/unit_test/turf_enter_bumps_the_highest_layer

/datum/unit_test/turf_enter_bumps_the_highest_layer/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)

	// The winner is created FIRST on purpose. contents is walked in creation
	// order, so an implementation that simply keeps the last refusal would pick
	// the other one - which is exactly the regression this test exists to catch.
	var/obj/structure/enter_probe/high = allocate(/obj/structure/enter_probe, destination)
	high.layer = ABOVE_MOB_LAYER
	var/obj/structure/enter_probe/low = allocate(/obj/structure/enter_probe, destination)
	low.layer = TABLE_LAYER
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)

	TEST_ASSERT(!destination.Enter(walker, origin), "A turf holding an impassable structure must refuse entry")
	TEST_ASSERT_EQUAL(high.bumps, 1, "The topmost blocker must be the one that gets bumped")
	TEST_ASSERT_EQUAL(low.bumps, 0, "Only one blocker may be bumped per entry attempt")

/datum/unit_test/turf_enter_prefers_border_objects

/datum/unit_test/turf_enter_prefers_border_objects/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)

	// Border first, taller decoy second - see the note in the layer test above.
	var/obj/structure/enter_probe/border/edge = allocate(/obj/structure/enter_probe/border, destination)
	edge.layer = TABLE_LAYER
	var/obj/structure/enter_probe/tall = allocate(/obj/structure/enter_probe, destination)
	tall.layer = ABOVE_MOB_LAYER
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)

	TEST_ASSERT(!destination.Enter(walker, origin), "A turf holding an impassable border must refuse entry")
	TEST_ASSERT_EQUAL(edge.bumps, 1, "A border object must win the bump even against a higher layer")
	TEST_ASSERT_EQUAL(tall.bumps, 0, "Only one blocker may be bumped per entry attempt")

// -----------------------------------------------------------------------------
// Phasing movers pass, but everything they pass through still hears about it
// -----------------------------------------------------------------------------

/datum/unit_test/turf_enter_phasing_bumps_everything_and_passes

/datum/unit_test/turf_enter_phasing_bumps_everything_and_passes/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)

	var/obj/structure/enter_probe/first = allocate(/obj/structure/enter_probe, destination)
	var/obj/structure/enter_probe/second = allocate(/obj/structure/enter_probe, destination)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)
	walker.setMovetype(walker.movement_type | PHASING)

	TEST_ASSERT(destination.Enter(walker, origin), "A phasing mover must be allowed in")
	TEST_ASSERT_EQUAL(first.bumps, 1, "A phasing mover must bump every blocker it passes through")
	TEST_ASSERT_EQUAL(second.bumps, 1, "A phasing mover must bump every blocker it passes through")

// -----------------------------------------------------------------------------
// The mover vanishing mid-walk
// -----------------------------------------------------------------------------

/datum/unit_test/turf_enter_survives_mover_deleted_in_canpass

/datum/unit_test/turf_enter_survives_mover_deleted_in_canpass/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)

	var/obj/structure/enter_probe/deleter/trap = allocate(/obj/structure/enter_probe/deleter, destination)
	var/obj/structure/enter_probe/bystander = allocate(/obj/structure/enter_probe, destination)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)

	TEST_ASSERT(!destination.Enter(walker, origin), "A deleted mover must not be let in")
	TEST_ASSERT_EQUAL(trap.consulted, 1, "The trap must have been the one to delete the mover")
	TEST_ASSERT_EQUAL(bystander.consulted, 0, "Nothing may be consulted once the mover is gone")
	TEST_ASSERT_EQUAL(bystander.bumps, 0, "Nothing may be bumped once the mover is gone")

/datum/unit_test/turf_enter_cancels_move_when_bump_displaces_the_mover

/datum/unit_test/turf_enter_cancels_move_when_bump_displaces_the_mover/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)
	var/turf/shoved_to = get_step(origin, WEST)

	var/obj/structure/enter_probe/shover/pusher = allocate(/obj/structure/enter_probe/shover, destination)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)

	TEST_ASSERT(!walker.Move(destination, EAST), "A move whose Bump displaced the mover must report failure")
	TEST_ASSERT_EQUAL(pusher.bumps, 1, "The blocker must have been bumped exactly once")
	TEST_ASSERT_EQUAL(walker.loc, shoved_to, "The mover must stay where Bump put it, not continue into the turf")

// -----------------------------------------------------------------------------
// The turf itself outranks whatever stands on it
// -----------------------------------------------------------------------------

/datum/unit_test/turf_enter_impassable_turf_beats_contents

/datum/unit_test/turf_enter_impassable_turf_beats_contents/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)
	var/floor_type = destination.type

	var/turf/closed/wall/barrier = destination.ChangeTurf(/turf/closed/wall)
	var/allowed = barrier.Enter(walker, origin)
	barrier.ChangeTurf(floor_type)

	TEST_ASSERT(!allowed, "A wall must refuse entry regardless of what stands on it")

// -----------------------------------------------------------------------------
// A border blocks its own side only
// -----------------------------------------------------------------------------

/datum/unit_test/turf_enter_border_blocks_only_its_own_side

/datum/unit_test/turf_enter_border_blocks_only_its_own_side/Run()
	var/turf/destination = run_loc_floor_bottom_left
	var/turf/from_west = get_step(destination, WEST)
	var/turf/from_north = get_step(destination, NORTH)

	var/obj/structure/railing/fence = allocate(/obj/structure/railing, destination)
	fence.setDir(WEST)
	fence.density = TRUE

	var/mob/living/carbon/human/western = allocate(/mob/living/carbon/human, from_west)
	var/mob/living/carbon/human/northern = allocate(/mob/living/carbon/human, from_north)

	TEST_ASSERT(!destination.Enter(western, from_west), "A west-facing railing must block entry from the west")
	TEST_ASSERT(destination.Enter(northern, from_north), "A west-facing railing must not block entry from the north")

// -----------------------------------------------------------------------------
// no_side_effects: ask without touching
// -----------------------------------------------------------------------------
// The only caller is modular_bluemoon/code/game/objects/structures/crate_shelf.dm:102,
// checking whether a crate would fit without bumping anything.
//
// Caveat, deliberately left untested: the flag only silences bumps coming from
// the turf's contents. An impassable turf itself still gets bumped, because
// that path assigns firstbump = src without ever consulting the flag. That is
// an inconsistency in the current code, not a contract worth freezing.

/datum/unit_test/turf_enter_no_side_effects_refuses_without_bumping

/datum/unit_test/turf_enter_no_side_effects_refuses_without_bumping/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/destination = get_step(origin, EAST)

	var/obj/structure/enter_probe/blocker = allocate(/obj/structure/enter_probe, destination)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, origin)

	TEST_ASSERT(!destination.Enter(walker, origin, TRUE), "A silent probe of a blocked turf must still refuse")
	TEST_ASSERT_EQUAL(blocker.consulted, 1, "The blocker must still be consulted")
	TEST_ASSERT_EQUAL(blocker.bumps, 0, "A silent probe must not bump anything")
