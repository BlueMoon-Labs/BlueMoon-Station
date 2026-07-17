/// Test: full shapeshift/restore cycle leaves no GC failures behind.
/// Regression coverage for the round-log leak trio: shape mob stranded in
/// GLOB.simple_animals[AI_ON] (direct AIStatus write bypassing toggle_ai),
/// plus the shapeshift_holder <-> soullink reference cycle.
/datum/unit_test/gc_shapeshift_cycle_cleanup
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_shapeshift_cycle_cleanup/Run()
	configure_immediate_gc()

	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/effect/proc_holder/spell/targeted/shapeshift/spell = allocate(/obj/effect/proc_holder/spell/targeted/shapeshift)
	spell.shapeshift_type = /mob/living/simple_animal/mouse

	spell.Shapeshift(caster)

	var/obj/shapeshift_holder/holder = caster.loc
	TEST_ASSERT(istype(holder), "Shapeshift() did not move the caster into a shapeshift holder")
	var/mob/living/simple_animal/shape = holder.shape
	TEST_ASSERT_NOTNULL(shape, "Shapeshift holder has no shape mob")
	var/datum/soullink/shapeshift/slink = holder.slink
	TEST_ASSERT_NOTNULL(slink, "Shapeshift holder has no soullink")

	// The BLUEMOON AI shutdown must migrate the mob between the AI bookkeeping
	// lists; a direct AIStatus write leaves it stranded in the AI_ON list and
	// Destroy() then removes it from the wrong one, leaking the mob forever.
	TEST_ASSERT(!(shape in GLOB.simple_animals[AI_ON]), "Shape mob is still tracked in GLOB.simple_animals[AI_ON] after AI shutdown")
	TEST_ASSERT(shape in GLOB.simple_animals[AI_OFF], "Shape mob is not tracked in GLOB.simple_animals[AI_OFF] after AI shutdown")

	spell.Restore(shape)

	TEST_ASSERT(QDELETED(holder), "Shapeshift holder was not qdeleted by restore()")
	TEST_ASSERT(QDELETED(shape), "Shape mob was not qdeleted by restore()")
	TEST_ASSERT(QDELETED(slink), "Shapeshift soullink was not qdeleted by restore()")
	TEST_ASSERT(isturf(caster.loc), "Caster was not returned to a turf by restore()")
	TEST_ASSERT(!caster.mob_transforming, "Caster is still flagged as mob_transforming after restore()")

	// Both sides of the holder <-> soullink cycle must be broken, otherwise
	// they keep each other's refcount above zero and both hard-delete.
	TEST_ASSERT_NULL(holder.slink, "Holder Destroy() did not clear its soullink reference")
	TEST_ASSERT_NULL(slink.source, "Soullink Destroy() did not clear its holder reference")

	TEST_ASSERT(!(shape in GLOB.simple_animals[AI_ON]), "Deleted shape mob is still tracked in GLOB.simple_animals[AI_ON]")
	TEST_ASSERT(!(shape in GLOB.simple_animals[AI_OFF]), "Deleted shape mob is still tracked in GLOB.simple_animals[AI_OFF]")

	holder = null
	shape = null
	slink = null
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	run_gc_fire_cycles(1, yield_for_gc = TRUE)

	assert_no_gc_failures(/obj/shapeshift_holder, "Shapeshift holder")
	assert_no_gc_failures(/datum/soullink/shapeshift, "Shapeshift soullink")
	// No GC-counter assert on the shape mob itself: at zero-timeout mobs are
	// nondeterministically grazed by transient holders unrelated to shapeshift
	// (a full-world reference scan finds no datum-side holders). The mob leak
	// this test guards against is the GLOB.simple_animals stranding asserted
	// explicitly above.

/// Test: the Beast Spirit quirk transform (the exact trio from round logs:
/// beastspirit + shapeshift_holder + soullink/shapeshift) collects cleanly.
/datum/unit_test/gc_beastspirit_cycle_cleanup
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_beastspirit_cycle_cleanup/Run()
	configure_immediate_gc()

	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/effect/proc_holder/spell/targeted/shapeshift/beast/spell = allocate(/obj/effect/proc_holder/spell/targeted/shapeshift/beast)

	spell.Shapeshift(caster) // sleeps 3 seconds for the transform animation

	var/obj/shapeshift_holder/holder = caster.loc
	TEST_ASSERT(istype(holder), "Beast Shapeshift() did not move the caster into a shapeshift holder")
	var/mob/living/simple_animal/hostile/beastspirit/shape = holder.shape
	TEST_ASSERT(istype(shape), "Beast shapeshift holder is not holding a beastspirit shape")
	var/datum/soullink/shapeshift/slink = holder.slink
	TEST_ASSERT_NOTNULL(slink, "Beast shapeshift holder has no soullink")

	TEST_ASSERT(!(shape in GLOB.simple_animals[AI_ON]), "Beastspirit is still tracked in GLOB.simple_animals[AI_ON] after AI shutdown")

	spell.Restore(shape)

	TEST_ASSERT(QDELETED(holder), "Beast shapeshift holder was not qdeleted by restore()")
	TEST_ASSERT(QDELETED(shape), "Beastspirit was not qdeleted by restore()")
	TEST_ASSERT(QDELETED(slink), "Beast shapeshift soullink was not qdeleted by restore()")
	TEST_ASSERT_NULL(holder.slink, "Beast holder Destroy() did not clear its soullink reference")
	TEST_ASSERT_NULL(slink.source, "Beast soullink Destroy() did not clear its holder reference")
	TEST_ASSERT(!(shape in GLOB.simple_animals[AI_ON]), "Deleted beastspirit is still tracked in GLOB.simple_animals[AI_ON]")
	TEST_ASSERT(!(shape in GLOB.simple_animals[AI_OFF]), "Deleted beastspirit is still tracked in GLOB.simple_animals[AI_OFF]")

	holder = null
	shape = null
	slink = null
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	run_gc_fire_cycles(1, yield_for_gc = TRUE)

	assert_no_gc_failures(/obj/shapeshift_holder, "Beast shapeshift holder")
	assert_no_gc_failures(/datum/soullink/shapeshift, "Beast shapeshift soullink")
	// No GC-counter assert on the beastspirit itself; see the note in
	// gc_shapeshift_cycle_cleanup.
