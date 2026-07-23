// ===== Excited group lifecycle: VOLATILE_REACTION gate (tg port) =====
//
// tick_lifecycle() used to run self_breakdown on a pure counter: a group with a
// live fire got its members' air averaged mid-burn, smearing the hotspot's heat
// across the whole group (snuffing or teleporting the fire). The port defers
// breakdown while a member reported VOLATILE_REACTION (fire/hotspot) in the
// last air pass, freezes the dismantle countdown, and blocks dismantle while
// any reaction is live. Unlike tg, a volatile group has a ceiling
// (EXCITED_GROUP_VOLATILE_BREAKDOWN_CEILING), at which it runs
// evict_settled_members() - the giant-group churn control ordinary breakdown
// provides - WITHOUT averaging the gas, so a long fire is never smeared.

/datum/unit_test/excited_group_volatile_gate/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	// Walled 1x1 pocket: poke_resting has no bordering open turfs to wake.
	var/turf/base = run_loc_floor_bottom_left
	for(var/dx in 0 to 2)
		for(var/dy in 0 to 2)
			if(dx == 1 && dy == 1)
				continue
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			T.ChangeTurf(/turf/closed/wall)
	var/turf/open/subject = locate(base.x + 1, base.y + 1, base.z)
	TEST_ASSERT(istype(subject), "pocket center must be an open turf")

	var/datum/excited_group/group = new
	group.add_turf(subject) // resets cooldowns, sets awake_members = 1

	// --- Volatile reaction defers breakdown and freezes the dismantle countdown ---
	group.breakdown_cooldown = EXCITED_GROUP_BREAKDOWN_CYCLES
	group.dismantle_cooldown = 0
	group.turf_reactions = VOLATILE_REACTION
	group.tick_lifecycle()
	TEST_ASSERT_EQUAL(group.breakdown_cooldown, EXCITED_GROUP_BREAKDOWN_CYCLES + 1, "Volatile reaction must defer breakdown (cooldown keeps counting, no reset)")
	TEST_ASSERT_EQUAL(group.dismantle_cooldown, 0, "Volatile reaction must freeze the dismantle countdown")
	TEST_ASSERT_EQUAL(group.turf_reactions, NO_REACTION, "tick_lifecycle must consume the reaction flags")

	// --- Without flags the due breakdown runs and resets its cooldown ---
	group.tick_lifecycle()
	TEST_ASSERT_EQUAL(group.breakdown_cooldown, 0, "Quiet group past the breakdown window must break down")
	TEST_ASSERT(subject.excited_group == group, "Breakdown must keep the member in the group")

	// --- Ceiling: вечное горение упирается в потолок, но там работает
	// выселение осевших (evict_settled_members), а не усредняющий брейкдаун -
	// бодрствующий (горящий) член группы остаётся нетронутым ---
	group.turf_reactions = VOLATILE_REACTION
	group.breakdown_cooldown = EXCITED_GROUP_VOLATILE_BREAKDOWN_CEILING - 1
	group.tick_lifecycle()
	TEST_ASSERT_EQUAL(group.breakdown_cooldown, 0, "Volatile ceiling must fire and reset the breakdown counter")
	TEST_ASSERT(subject.excited_group == group, "An awake (burning) member must survive the volatile-ceiling eviction")

	// --- Any live reaction blocks dismantle ---
	group.turf_reactions = REACTING
	group.dismantle_cooldown = EXCITED_GROUP_DISMANTLE_CYCLES
	group.breakdown_cooldown = 0
	group.tick_lifecycle()
	TEST_ASSERT(length(group.turf_list) == 1 && subject.excited_group == group, "Reacting group past the dismantle window must not dismantle")

	// --- Quiet group past the dismantle window dismantles ---
	group.turf_reactions = NO_REACTION
	group.dismantle_cooldown = EXCITED_GROUP_DISMANTLE_CYCLES
	group.breakdown_cooldown = 0
	group.tick_lifecycle()
	TEST_ASSERT_EQUAL(length(group.turf_list), 0, "Quiet group past the dismantle window must dismantle")
	TEST_ASSERT_NULL(subject.excited_group, "Dismantle must unlink the member turf")

	// --- Merge carries the volatile gate from the ABSORBED group to the survivor ---
	var/datum/excited_group/survivor_group = new
	survivor_group.add_turf(subject)
	survivor_group.turf_reactions = NO_REACTION
	var/datum/excited_group/burning_group = new // empty shell group about to be absorbed
	burning_group.turf_reactions = VOLATILE_REACTION
	survivor_group.merge_groups(burning_group) // survivor is larger -> absorbs burning_group
	TEST_ASSERT(survivor_group.turf_reactions & VOLATILE_REACTION, "Merge must carry VOLATILE_REACTION from the absorbed group to the survivor")

	// Cleanup
	if(subject.excited_group)
		subject.excited_group.dismantle()
	SSair.remove_from_active(subject)

// ===== VOLATILE через реальную реакцию: generic combustion без хотспота =====
//
// genericfire пишет reaction_results["fire"] и возвращает REACTING, но hotspot
// не создаёт - гейт только по active_hotspot пропускал такое горение, и
// брейкдаун усреднял группу посреди пожара. Тест жжёт настоящую смесь.

/datum/unit_test/excited_group_volatile_generic_fire
	priority = TEST_LONGER

/datum/unit_test/excited_group_volatile_generic_fire/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	// Walled 1x1 pocket like the volatile gate test
	var/turf/base = run_loc_floor_bottom_left
	for(var/dx in 0 to 2)
		for(var/dy in 0 to 2)
			if(dx == 1 && dy == 1)
				continue
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			T.ChangeTurf(/turf/closed/wall)
	var/turf/open/subject = locate(base.x + 1, base.y + 1, base.z)
	TEST_ASSERT(istype(subject), "pocket center must be an open turf")

	// Метан горит ТОЛЬКО через genericfire: у плазмы/трития есть легаси-реакции
	// с hotspot_expose, а нам нужен именно пожар без хотспота
	var/datum/gas_mixture/saved_air = subject.air.copy()
	subject.air.clear()
	subject.air.set_moles(GAS_METHANE, 5)
	subject.air.set_moles(GAS_O2, 5)
	subject.air.set_temperature(1500)

	var/datum/excited_group/group = new
	group.add_turf(subject)
	SSair.add_to_active(subject, FALSE)

	subject.process_cell(SSair.times_fired + 3000)

	TEST_ASSERT(subject.air.reaction_results["fire"], "fixture must actually combust (no reaction_results fire recorded)")
	TEST_ASSERT_NULL(subject.active_hotspot, "premise: generic combustion must not create a hotspot")
	TEST_ASSERT(group.turf_reactions & VOLATILE_REACTION, "generic combustion without a hotspot must mark the group volatile")

	// Cleanup
	subject.air.copy_from(saved_air)
	if(subject.excited_group)
		subject.excited_group.dismantle()
	SSair.remove_from_active(subject)

// ===== Волатильный потолок: выселение осевших без усреднения газа =====
//
// self_breakdown размазал бы топливо и жар долгого горения по группе, поэтому
// на потолке волатильная группа лишь выселяет осевших членов: их газ не
// трогается, счётчик awake пересчитывается точно, бодрые члены остаются.

/datum/unit_test/excited_group_volatile_evict/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	// Walled 1x1 pocket, как в остальных тестах этого файла (идемпотентно)
	var/turf/base = run_loc_floor_bottom_left
	for(var/dx in 0 to 2)
		for(var/dy in 0 to 2)
			if(dx == 1 && dy == 1)
				continue
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			T.ChangeTurf(/turf/closed/wall)
	var/turf/open/subject = locate(base.x + 1, base.y + 1, base.z)
	TEST_ASSERT(istype(subject), "pocket center must be an open turf")

	// Осевший член (эквивалент sleep_active_turf) выселяется, газ не тронут
	var/datum/excited_group/group = new
	group.add_turf(subject)
	subject.excited = FALSE
	group.breakdown_cooldown = EXCITED_GROUP_VOLATILE_BREAKDOWN_CEILING
	var/moles_before = subject.air.total_moles()
	var/temp_before = subject.air.return_temperature()
	group.evict_settled_members()
	TEST_ASSERT_EQUAL(length(group.turf_list), 0, "evict must remove settled members from the group")
	TEST_ASSERT_NULL(subject.excited_group, "an evicted member must be unlinked from the group")
	TEST_ASSERT_EQUAL(group.awake_members, 0, "evict must recount awake members exactly")
	TEST_ASSERT_EQUAL(group.breakdown_cooldown, 0, "evict must reset the breakdown counter")
	TEST_ASSERT_EQUAL(subject.air.total_moles(), moles_before, "evict must not move gas (no averaging)")
	TEST_ASSERT_EQUAL(subject.air.return_temperature(), temp_before, "evict must not touch temperature (no averaging)")

	// Бодрый член переживает выселение
	var/datum/excited_group/second_group = new
	second_group.add_turf(subject) // ставит excited = TRUE
	second_group.evict_settled_members()
	TEST_ASSERT(subject.excited_group == second_group && (subject in second_group.turf_list), "an awake member must survive eviction")
	TEST_ASSERT_EQUAL(second_group.awake_members, 1, "the awake recount must keep counting the surviving member")

	// Cleanup
	if(subject.excited_group)
		subject.excited_group.dismantle()
	SSair.remove_from_active(subject)

// ===== Волатильность из самих реакций (tg parity) =====
//
// Синтез в process_cell видит только hotspot и reaction_results["fire"].
// Нобиум, антинобиум и фреоновое пламя не пишут ни того, ни другого - они
// обязаны сами возвращать VOLATILE_REACTION, иначе брейкдаун размажет
// активную реакцию по группе.

/datum/unit_test/volatile_reaction_flags/Run()
	// nobliumformation: конденсация ниже 15 К
	var/datum/gas_mixture/mix = new
	mix.set_moles(GAS_N2, 100)
	mix.set_moles(GAS_TRITIUM, 50)
	mix.set_volume(1000)
	mix.set_temperature(10)
	var/result = mix.react()
	TEST_ASSERT(result & REACTING, "premise: nobliumformation must react")
	TEST_ASSERT(result & VOLATILE_REACTION, "nobliumformation must flag VOLATILE_REACTION")

	// freonfire: пламя без reaction_results["fire"] и без хотспота
	mix = new
	mix.set_moles(GAS_FREON, 10)
	mix.set_moles(GAS_O2, 20)
	mix.set_volume(1000)
	mix.set_temperature(100)
	result = mix.react()
	TEST_ASSERT(result & REACTING, "premise: freonfire must react")
	TEST_ASSERT(result & VOLATILE_REACTION, "freonfire must flag VOLATILE_REACTION")

	// antinoblium_replication: активная репликация
	mix = new
	mix.set_moles(GAS_ANTINOBLIUM, 5)
	mix.set_moles(GAS_N2, 10)
	mix.set_volume(1000)
	mix.set_temperature(100)
	result = mix.react()
	TEST_ASSERT(result & REACTING, "premise: antinoblium replication must react")
	TEST_ASSERT(result & VOLATILE_REACTION, "antinoblium replication must flag VOLATILE_REACTION")
