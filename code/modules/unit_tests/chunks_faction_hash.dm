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

	// Dead mobs drop out of the hash: valid ONLY because consumers that target
	// the dead (stat_attack) bypass the gate via can_use_faction_hash()
	beta.faction = list("chunktest_beta")
	beta.stat = DEAD
	SSchunks.rebuild()
	TEST_ASSERT(!(SSchunks.has_enemy_faction(alpha, list("chunktest_alpha", "neutral"), 9)), "Dead mobs must not be hashed as enemies")
	beta.stat = CONSCIOUS

	// A factionless mob must read as an enemy to everyone (sentinel key)
	beta.faction = list()
	SSchunks.rebuild()
	TEST_ASSERT(SSchunks.has_enemy_faction(alpha, alpha.faction, 9), "A factionless mob must read as an enemy")
	beta.faction = list("chunktest_beta")

	// Gate applicability: non-standard targeting must bypass the hash entirely
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile)
	TEST_ASSERT(hunter.can_use_faction_hash(), "A plain faction hunter must be allowed to use the hash")
	hunter.stat_attack = UNCONSCIOUS
	TEST_ASSERT(!hunter.can_use_faction_hash(), "Corpse/unconscious hunters (stat_attack) must bypass the hash")
	hunter.stat_attack = CONSCIOUS
	hunter.attack_same = 1
	TEST_ASSERT(!hunter.can_use_faction_hash(), "attack_same hunters must bypass the hash")
	hunter.attack_same = 0
	hunter.enemies = list(beta)
	TEST_ASSERT(!hunter.can_use_faction_hash(), "Hunters with personal grudges (retaliate) must bypass the hash")
	hunter.enemies = list()
	TEST_ASSERT(hunter.can_use_faction_hash(), "Restored plain hunter must use the hash again")

	// Кастомное таргетирование по СВОЕЙ фракции обязано обходить гейт целиком:
	// хэш видит только чужие фракции, а этим типам нужны цели своей
	var/mob/living/simple_animal/hostile/construct/builder/artificer = allocate(/mob/living/simple_animal/hostile/construct/builder)
	TEST_ASSERT(!artificer.can_use_faction_hash(), "Artificer (Found() heals own-faction constructs) must bypass the hash")
	var/mob/living/simple_animal/hostile/regalrat/rat_king = allocate(/mob/living/simple_animal/hostile/regalrat)
	TEST_ASSERT(!rat_king.can_use_faction_hash(), "Regal rat (unconditionally hostile to rival kings of the same faction) must bypass the hash")

	// Laziness: a second ensure_fresh inside the freshness window must not rebuild
	SSchunks.next_rebuild_time = 0
	SSchunks.ensure_fresh()
	var/tick_after_first = SSchunks.tick
	SSchunks.ensure_fresh()
	TEST_ASSERT_EQUAL(SSchunks.tick, tick_after_first, "ensure_fresh inside the freshness window must not rebuild the hash")
