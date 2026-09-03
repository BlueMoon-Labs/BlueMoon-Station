/// Tests for the healthdoll memoization in /mob/living/carbon/human/update_health_hud().
///
/// The doll used to be torn down (cut_overlays) and rebuilt from scratch — up to
/// ten mutable_appearance() + add_overlay() calls plus two full-body limb walks —
/// on EVERY health change, which in round 9800 made /proc/mutable_appearance the
/// third most expensive proc in the whole server profile.
///
/// The rebuild is now gated on a cache key. These tests pin the contract that
/// makes that gate safe:
///
///   key unchanged  <=> rendered overlay set unchanged
///
/// If the key ever stops tracking something the renderer reads, the doll silently
/// stops updating in game — so the equivalence is asserted in both directions.

/// Damages a bodypart without letting wounds/dismemberment interfere.
#define HEALTHDOLL_TEST_HURT(BP, amount) BP.receive_damage(brute = amount, wound_bonus = CANT_WOUND, can_dismember = FALSE)

/// Convenience: build the doll overlays with a fixed style so tests don't depend
/// on a client's ui_style preference.
#define HEALTHDOLL_TEST_STYLE 'icons/mob/screen_midnight.dmi'

// -----------------------------------------------------------------------------
// Key stability — the case that matters for performance. A mob whose limbs
// haven't changed bucket must produce the same key twice in a row.
// -----------------------------------------------------------------------------

/datum/unit_test/healthdoll_key_stable_without_change

/datum/unit_test/healthdoll_key_stable_without_change/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	var/first = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	var/second = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)

	TEST_ASSERT_NOTNULL(first, "Healthdoll cache key should never be null")
	TEST_ASSERT_EQUAL(first, second, "An untouched mob must produce a stable healthdoll cache key")

// -----------------------------------------------------------------------------
// Damage buckets — the doll only has six states per limb, so the key must change
// when a limb crosses a bucket boundary and must NOT change for damage that
// lands in the same bucket. The second half is where the savings come from.
// -----------------------------------------------------------------------------

/datum/unit_test/healthdoll_key_tracks_damage_buckets

/datum/unit_test/healthdoll_key_tracks_damage_buckets/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/chest = patient.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_NOTNULL(chest, "Test human should have a chest")

	// The renderer buckets on multiples of max_damage/5.
	var/bucket = chest.max_damage / 5

	var/undamaged = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)

	HEALTHDOLL_TEST_HURT(chest, bucket * 0.4)
	var/lightly_hurt = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	TEST_ASSERT_NOTEQUAL(lightly_hurt, undamaged, "First point of damage moves the chest from bucket 0 to bucket 1")

	// Still inside bucket 1 (total 0.6 * bucket, boundary is 1.0 * bucket).
	HEALTHDOLL_TEST_HURT(chest, bucket * 0.2)
	var/still_bucket_one = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	TEST_ASSERT_EQUAL(still_bucket_one, lightly_hurt, "Damage inside the same bucket must not invalidate the doll")

	// Crosses into bucket 2 (total 1.2 * bucket).
	HEALTHDOLL_TEST_HURT(chest, bucket * 0.6)
	var/bucket_two = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	TEST_ASSERT_NOTEQUAL(bucket_two, still_bucket_one, "Crossing a bucket boundary must invalidate the doll")

// -----------------------------------------------------------------------------
// The renderer draws missing limbs and disabled limbs as their own overlays, so
// both must be in the key even though neither changes any limb's damage.
// -----------------------------------------------------------------------------

/datum/unit_test/healthdoll_key_tracks_missing_limb

/datum/unit_test/healthdoll_key_tracks_missing_limb/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/arm = patient.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT_NOTNULL(arm, "Test human should have a left arm")

	var/intact = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	arm.dismember()
	var/dismembered = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)

	TEST_ASSERT_NOTEQUAL(dismembered, intact, "Losing a limb must invalidate the doll")

/datum/unit_test/healthdoll_key_tracks_disabled_limb

/datum/unit_test/healthdoll_key_tracks_disabled_limb/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/arm = patient.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT_NOTNULL(arm, "Test human should have a left arm")

	var/enabled = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	arm.set_disabled(BODYPART_DISABLED_DAMAGE)
	var/disabled = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)

	TEST_ASSERT_NOTEQUAL(disabled, enabled, "Disabling a limb must invalidate the doll")

// -----------------------------------------------------------------------------
// Whole-doll states: death swaps the doll for a single "dead" icon_state, and
// the healthy screwyhud hallucination forces every limb to bucket 0.
// -----------------------------------------------------------------------------

/datum/unit_test/healthdoll_key_tracks_death

/datum/unit_test/healthdoll_key_tracks_death/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	var/alive = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	patient.set_stat(DEAD)
	var/dead = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)

	TEST_ASSERT_NOTEQUAL(dead, alive, "Dying must invalidate the doll")

/datum/unit_test/healthdoll_key_tracks_screwyhud

/datum/unit_test/healthdoll_key_tracks_screwyhud/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/chest = patient.get_bodypart(BODY_ZONE_CHEST)
	HEALTHDOLL_TEST_HURT(chest, chest.max_damage / 2)

	var/honest = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	patient.hal_screwyhud = SCREWYHUD_HEALTHY
	var/lying_hud = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)

	TEST_ASSERT_NOTEQUAL(lying_hud, honest, "A healthy-screwyhud hallucination hides real damage and must invalidate the doll")

/datum/unit_test/healthdoll_key_tracks_ui_style

/datum/unit_test/healthdoll_key_tracks_ui_style/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	var/midnight = patient.get_healthdoll_cache_key('icons/mob/screen_midnight.dmi')
	var/plasmafire = patient.get_healthdoll_cache_key('icons/mob/screen_plasmafire.dmi')

	TEST_ASSERT_NOTEQUAL(midnight, plasmafire, "Switching HUD style changes the overlay icons and must invalidate the doll")

// -----------------------------------------------------------------------------
// The invariant the gate depends on: equal keys imply an identical overlay set,
// and an unequal key implies the set actually differs. Asserted against the real
// overlay builder rather than against the key alone.
// -----------------------------------------------------------------------------

/datum/unit_test/healthdoll_key_matches_rendered_overlays

/datum/unit_test/healthdoll_key_matches_rendered_overlays/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/chest = patient.get_bodypart(BODY_ZONE_CHEST)
	var/bucket = chest.max_damage / 5

	var/key_before = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	var/list/overlays_before = patient.build_healthdoll_overlays(HEALTHDOLL_TEST_STYLE)
	TEST_ASSERT_EQUAL(length(overlays_before), 0, "An undamaged, fully limbed human should render no doll overlays at all")

	// Same bucket -> same key -> the builder must agree.
	HEALTHDOLL_TEST_HURT(chest, bucket * 0.5)
	HEALTHDOLL_TEST_HURT(chest, bucket * 0.2)
	var/key_same_bucket = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	var/list/overlays_same_bucket = patient.build_healthdoll_overlays(HEALTHDOLL_TEST_STYLE)
	TEST_ASSERT_NOTEQUAL(key_same_bucket, key_before, "Sanity: the first damage should have moved the chest out of bucket 0")

	// Now a change that must NOT alter the drawing: more damage inside bucket 1.
	HEALTHDOLL_TEST_HURT(chest, bucket * 0.1)
	var/key_still_same = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	var/list/overlays_still_same = patient.build_healthdoll_overlays(HEALTHDOLL_TEST_STYLE)

	TEST_ASSERT_EQUAL(key_still_same, key_same_bucket, "Key must be stable inside a bucket")
	TEST_ASSERT_EQUAL(length(overlays_still_same), length(overlays_same_bucket), "Equal keys must render the same number of overlays")
	for(var/i in 1 to length(overlays_same_bucket))
		TEST_ASSERT_EQUAL(overlays_still_same[i], overlays_same_bucket[i], "Equal keys must render an identical overlay at index [i]")

	// And a change that MUST alter the drawing.
	HEALTHDOLL_TEST_HURT(chest, bucket)
	var/key_new_bucket = patient.get_healthdoll_cache_key(HEALTHDOLL_TEST_STYLE)
	var/list/overlays_new_bucket = patient.build_healthdoll_overlays(HEALTHDOLL_TEST_STYLE)
	TEST_ASSERT_NOTEQUAL(key_new_bucket, key_still_same, "Crossing a bucket must change the key")

	var/differs = FALSE
	if(length(overlays_new_bucket) != length(overlays_still_same))
		differs = TRUE
	else
		for(var/i in 1 to length(overlays_new_bucket))
			if(overlays_new_bucket[i] != overlays_still_same[i])
				differs = TRUE
				break
	TEST_ASSERT(differs, "A changed key must correspond to an actually different overlay set")

// -----------------------------------------------------------------------------
// The overlay appearances themselves are drawn from a fixed, tiny set
// (6 zones x 8 states x ui_style), so they are cached instead of being rebuilt
// with mutable_appearance() on every call.
// -----------------------------------------------------------------------------

/datum/unit_test/healthdoll_appearance_cache_reuses_entries

/datum/unit_test/healthdoll_appearance_cache_reuses_entries/Run()
	var/doll_icons = ui_style_modular(HEALTHDOLL_TEST_STYLE, "health")

	var/first = get_healthdoll_appearance(doll_icons, "chest2")
	var/second = get_healthdoll_appearance(doll_icons, "chest2")
	var/other_state = get_healthdoll_appearance(doll_icons, "chest3")

	TEST_ASSERT_NOTNULL(first, "Healthdoll appearance lookup should return an appearance")
	TEST_ASSERT_EQUAL(first, second, "Repeated lookups for the same icon state must reuse the cached appearance")
	TEST_ASSERT_NOTEQUAL(first, other_state, "Different icon states must not collide in the appearance cache")

#undef HEALTHDOLL_TEST_HURT
#undef HEALTHDOLL_TEST_STYLE
