// ===== SSchunks: spatial faction hash gating hostile hearers() (TauCeti port) =====
//
// Hostile AI's ListTargets() runs a native hearers(vision_range) scan on every
// AI pass. The hash lets it early-out when no mob of a foreign faction is
// anywhere in range. Ported with two fixes over TauCeti: the y-range clamp
// used world.maxx (blind or out-of-bounds chunks on non-square maps), and the
// consumer passed vision_range in the faction argument slot.

/datum/unit_test/chunks_faction_hash/Run()
	var/mob/living/simple_animal/alpha = allocate(/mob/living/simple_animal)
	var/mob/living/simple_animal/beta = allocate(/mob/living/simple_animal)
	alpha.faction = list("chunktest_alpha")
	beta.faction = list("chunktest_beta")
	alpha.forceMove(run_loc_floor_bottom_left)
	beta.forceMove(get_step(run_loc_floor_bottom_left, EAST))

	SSchunks.rebuild()
	TEST_ASSERT(SSchunks.tick > 0, "rebuild must advance the hash tick")

	TEST_ASSERT(SSchunks.has_enemy_faction(alpha, alpha.faction, 9), "A foreign-faction mob in range must read as an enemy")
	TEST_ASSERT(SSchunks.has_ally_faction(alpha, list("chunktest_beta"), 9), "has_ally_faction must see the beta mob's faction")

	// Same faction everywhere -> no enemy reading
	beta.faction = list("chunktest_alpha")
	SSchunks.rebuild()
	TEST_ASSERT(!(SSchunks.has_enemy_faction(alpha, list("chunktest_alpha", "neutral"), 9)), "Mobs of only our own factions must not read as enemies")

	// Dead mobs drop out of the hash
	beta.faction = list("chunktest_beta")
	beta.stat = DEAD
	SSchunks.rebuild()
	TEST_ASSERT(!(SSchunks.has_enemy_faction(alpha, list("chunktest_alpha", "neutral"), 9)), "Dead mobs must not be hashed as enemies")
	beta.stat = CONSCIOUS
