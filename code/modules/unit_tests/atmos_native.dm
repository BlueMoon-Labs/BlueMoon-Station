// Functional tests for the native DM atmospherics core: gas exchange math,
// reaction dispatch through the key-gas index, scrubber gating, planetary
// templates and turf gas assumption. These pin down behavior the optimization
// work is required to preserve.

#define TEST_GAS_EPSILON 0.001

/// Reference copy of the pre-optimization share() (union list + full-list GC
/// sweeps). Used to verify the rewritten share() produces identical numbers.
/proc/unit_test_reference_share(datum/gas_mixture/source, datum/gas_mixture/sharer, our_coeff, sharer_coeff)
	if(!sharer || source.gc_share || sharer.gc_share)
		return 0
	our_coeff = clamp(our_coeff, 0, 1)
	sharer_coeff = clamp(sharer_coeff, 0, 1)
	if(!our_coeff && !sharer_coeff)
		return 0
	var/list/cached_gases = source.gases
	var/list/sharer_gases = sharer.gases
	var/list/self_archive = source.gas_archive || cached_gases
	var/list/sharer_archive = sharer.gas_archive || sharer_gases
	var/temperature_delta = source.temperature_archived - sharer.temperature_archived
	var/abs_temperature_delta = abs(temperature_delta)
	var/old_self_heat_capacity = 0
	var/old_sharer_heat_capacity = 0
	if(abs_temperature_delta > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		old_self_heat_capacity = source.heat_capacity()
		old_sharer_heat_capacity = sharer.heat_capacity()
	var/heat_capacity_self_to_sharer = 0
	var/heat_capacity_sharer_to_self = 0
	var/moved_moles = 0
	var/abs_moved_moles = 0
	var/list/cached_gasheats = GLOB.gas_data.specific_heats
	for(var/id in cached_gases | sharer_gases)
		var/delta = QUANTIZE((self_archive[id] || 0) - (sharer_archive[id] || 0))
		if(!delta)
			continue
		if(delta > 0)
			delta *= our_coeff
		else
			delta *= sharer_coeff
		if(abs_temperature_delta > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
			var/gas_heat_capacity = delta * (cached_gasheats[id] || 0)
			if(delta > 0)
				heat_capacity_self_to_sharer += gas_heat_capacity
			else
				heat_capacity_sharer_to_self -= gas_heat_capacity
		cached_gases[id] = (cached_gases[id] || 0) - delta
		sharer_gases[id] = (sharer_gases[id] || 0) + delta
		moved_moles += delta
		abs_moved_moles += abs(delta)
	source.last_share = abs_moved_moles
	if(abs_temperature_delta > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/new_self_heat_capacity = old_self_heat_capacity + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
		var/new_sharer_heat_capacity = old_sharer_heat_capacity + heat_capacity_self_to_sharer - heat_capacity_sharer_to_self
		if(new_self_heat_capacity > MINIMUM_HEAT_CAPACITY)
			source.temperature = (old_self_heat_capacity * source.temperature - heat_capacity_self_to_sharer * source.temperature_archived + heat_capacity_sharer_to_self * sharer.temperature_archived) / new_self_heat_capacity
		if(new_sharer_heat_capacity > MINIMUM_HEAT_CAPACITY)
			sharer.temperature = (old_sharer_heat_capacity * sharer.temperature - heat_capacity_sharer_to_self * sharer.temperature_archived + heat_capacity_self_to_sharer * source.temperature_archived) / new_sharer_heat_capacity
			if(abs(old_sharer_heat_capacity) > MINIMUM_HEAT_CAPACITY)
				if(abs(new_sharer_heat_capacity / old_sharer_heat_capacity - 1) < 0.1)
					source.temperature_share(sharer, OPEN_HEAT_TRANSFER_COEFFICIENT)
	for(var/id in cached_gases.Copy())
		if(QUANTIZE(cached_gases[id]) <= 0)
			cached_gases -= id
	for(var/id in sharer_gases.Copy())
		if(QUANTIZE(sharer_gases[id]) <= 0)
			sharer_gases -= id
	if(temperature_delta > MINIMUM_TEMPERATURE_TO_MOVE || abs(moved_moles) > MINIMUM_MOLES_DELTA_TO_MOVE)
		var/our_moles = 0
		for(var/id in cached_gases)
			our_moles += cached_gases[id]
		var/their_moles = 0
		for(var/id in sharer_gases)
			their_moles += sharer_gases[id]
		return (source.temperature_archived * (our_moles + moved_moles) - sharer.temperature_archived * (their_moles - moved_moles)) * R_IDEAL_GAS_EQUATION / source.volume
	return 0

/// Seeds one deterministic uneven mixture pair used by the equivalence tests.
/proc/unit_test_seed_share_pair(list/out_pair)
	var/datum/gas_mixture/hot_side = new(CELL_VOLUME)
	hot_side.set_moles(GAS_O2, 60)
	hot_side.set_moles(GAS_PLASMA, 12)
	hot_side.set_moles(GAS_CO2, 3)
	hot_side.set_temperature(T20C + 210)
	hot_side.archive()
	var/datum/gas_mixture/cold_side = new(CELL_VOLUME)
	cold_side.set_moles(GAS_O2, 10)
	cold_side.set_moles(GAS_N2, 80)
	cold_side.set_temperature(T20C - 30)
	cold_side.archive()
	out_pair += hot_side
	out_pair += cold_side

/datum/unit_test/atmos_share_matches_reference/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/list/new_pair = list()
	unit_test_seed_share_pair(new_pair)
	var/list/ref_pair = list()
	unit_test_seed_share_pair(ref_pair)

	var/datum/gas_mixture/new_a = new_pair[1]
	var/datum/gas_mixture/new_b = new_pair[2]
	var/datum/gas_mixture/ref_a = ref_pair[1]
	var/datum/gas_mixture/ref_b = ref_pair[2]

	var/new_result = new_a.share(new_b, 0.2, 0.25)
	var/ref_result = unit_test_reference_share(ref_a, ref_b, 0.2, 0.25)

	TEST_ASSERT(abs(new_result - ref_result) < 0.01, "share() return value diverged from reference: [new_result] vs [ref_result]")
	TEST_ASSERT(abs(new_a.last_share - ref_a.last_share) < TEST_GAS_EPSILON, "share() last_share diverged: [new_a.last_share] vs [ref_a.last_share]")
	TEST_ASSERT(abs(new_a.return_temperature() - ref_a.return_temperature()) < 0.01, "share() source temperature diverged: [new_a.return_temperature()] vs [ref_a.return_temperature()]")
	TEST_ASSERT(abs(new_b.return_temperature() - ref_b.return_temperature()) < 0.01, "share() sharer temperature diverged: [new_b.return_temperature()] vs [ref_b.return_temperature()]")
	for(var/id in new_a.get_gases() | ref_a.get_gases())
		TEST_ASSERT(abs(new_a.get_moles(id) - ref_a.get_moles(id)) < TEST_GAS_EPSILON, "share() source [id] diverged: [new_a.get_moles(id)] vs [ref_a.get_moles(id)]")
	for(var/id in new_b.get_gases() | ref_b.get_gases())
		TEST_ASSERT(abs(new_b.get_moles(id) - ref_b.get_moles(id)) < TEST_GAS_EPSILON, "share() sharer [id] diverged: [new_b.get_moles(id)] vs [ref_b.get_moles(id)]")

	qdel(new_a)
	qdel(new_b)
	qdel(ref_a)
	qdel(ref_b)

/datum/unit_test/atmos_react_dispatch/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	TEST_ASSERT(length(SSair.gas_reactions), "SSair.gas_reactions is empty")
	TEST_ASSERT(islist(SSair.reactions_by_key_gas), "reaction key-gas index was not built")

	// Every non-excluded reaction must be reachable: either via a key gas bucket
	// or via the temperature-gated list.
	var/indexed = 0
	for(var/id in SSair.reactions_by_key_gas)
		var/list/bucket = SSair.reactions_by_key_gas[id]
		indexed += length(bucket)
	indexed += length(SSair.temp_gated_reactions)
	TEST_ASSERT_EQUAL(indexed, length(SSair.gas_reactions), "key-gas index covers [indexed] reactions but SSair has [length(SSair.gas_reactions)]")

	// Ordinary station air must stay inert.
	var/datum/gas_mixture/air_mix = unit_test_air_mix()
	TEST_ASSERT_EQUAL(air_mix.react(null), NO_REACTION, "station air reacted")
	TEST_ASSERT_EQUAL(length(air_mix.reaction_results), 0, "inert react() left reaction_results populated")
	qdel(air_mix)

	// Plasma fire must ignite through the index and report fire results.
	var/datum/gas_mixture/fire_mix = new(CELL_VOLUME)
	fire_mix.set_moles(GAS_PLASMA, 50)
	fire_mix.set_moles(GAS_O2, 100)
	fire_mix.set_temperature(FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 300)
	var/fire_energy_before = fire_mix.thermal_energy()
	var/fire_result = fire_mix.react(null)
	TEST_ASSERT(fire_result & REACTING, "plasma+o2 at fire temperature did not react")
	TEST_ASSERT(fire_mix.reaction_results["fire"] > 0, "plasma fire did not report burned fuel in reaction_results")
	TEST_ASSERT(fire_mix.thermal_energy() > fire_energy_before, "plasma fire did not release energy")
	TEST_ASSERT(fire_mix.get_moles(GAS_CO2) > 0, "plasma fire produced no CO2")
	qdel(fire_mix)

	// Hyper-noblium must suppress all reactions, leaving fuel untouched.
	var/datum/gas_mixture/nob_mix = new(CELL_VOLUME)
	nob_mix.set_moles(GAS_PLASMA, 50)
	nob_mix.set_moles(GAS_O2, 100)
	nob_mix.set_moles(GAS_HYPERNOB, REACTION_OPPRESSION_THRESHOLD * 2)
	nob_mix.set_temperature(FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 300)
	var/nob_result = nob_mix.react(null)
	TEST_ASSERT(nob_result & STOP_REACTIONS, "hyper-noblium did not stop reactions")
	TEST_ASSERT(abs(nob_mix.get_moles(GAS_PLASMA) - 50) < TEST_GAS_EPSILON, "plasma burned despite hyper-noblium suppression")
	qdel(nob_mix)

/datum/unit_test/atmos_water_vapor_condensation/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/floor = run_loc_floor_bottom_left
	TEST_ASSERT(istype(floor), "test location is not an open turf")
	var/datum/gas_mixture/wet_mix = new(CELL_VOLUME)
	wet_mix.set_moles(GAS_H2O, 5)
	wet_mix.set_moles(GAS_N2, 80)
	wet_mix.set_temperature(T20C)
	var/moles_before = wet_mix.get_moles(GAS_H2O)
	var/result = wet_mix.react(floor)
	TEST_ASSERT(result & REACTING, "water vapor did not condense on a warm turf")
	TEST_ASSERT(wet_mix.get_moles(GAS_H2O) < moles_before, "condensation did not consume water vapor")
	qdel(wet_mix)

/datum/unit_test/atmos_transfer_conservation/Run()
	var/datum/gas_mixture/source_mix = new(CELL_VOLUME)
	source_mix.set_moles(GAS_O2, 60)
	source_mix.set_moles(GAS_N2, 40)
	source_mix.set_temperature(T20C + 100)
	var/datum/gas_mixture/target_mix = new(200)
	target_mix.set_moles(GAS_O2, 10)
	target_mix.set_temperature(T20C)

	var/moles_before = source_mix.total_moles() + target_mix.total_moles()
	var/energy_before = source_mix.thermal_energy() + target_mix.thermal_energy()

	TEST_ASSERT(source_mix.transfer_to(target_mix, 25), "transfer_to failed")
	TEST_ASSERT(abs(source_mix.total_moles() - 75) < TEST_GAS_EPSILON, "source should hold 75 moles, has [source_mix.total_moles()]")
	TEST_ASSERT(abs(target_mix.total_moles() - 35) < TEST_GAS_EPSILON, "target should hold 35 moles, has [target_mix.total_moles()]")
	// Composition moves proportionally: 60/100 of the 25 moles are oxygen.
	TEST_ASSERT(abs(target_mix.get_moles(GAS_O2) - 25) < TEST_GAS_EPSILON, "target o2 should be 10+15, has [target_mix.get_moles(GAS_O2)]")
	TEST_ASSERT(abs(target_mix.get_moles(GAS_N2) - 10) < TEST_GAS_EPSILON, "target n2 should be 10, has [target_mix.get_moles(GAS_N2)]")

	var/moles_after = source_mix.total_moles() + target_mix.total_moles()
	var/energy_after = source_mix.thermal_energy() + target_mix.thermal_energy()
	TEST_ASSERT(abs(moles_before - moles_after) < TEST_GAS_EPSILON, "transfer_to lost moles: [moles_before] -> [moles_after]")
	TEST_ASSERT(abs(energy_before - energy_after) < energy_before * 0.005, "transfer_to lost energy: [energy_before] -> [energy_after]")

	// Draining more than available moves everything and reports success.
	TEST_ASSERT(source_mix.transfer_to(target_mix, 1000), "over-draining transfer_to failed")
	TEST_ASSERT(source_mix.total_moles() < TEST_GAS_EPSILON, "source should be empty after over-drain")

	// An empty source is a no-op and must report FALSE (like vent_moles), so
	// vents/pumps can idle on the return value instead of counting phantom
	// transfers every fire.
	TEST_ASSERT(!source_mix.transfer_to(target_mix, 10), "transfer_to from an empty mixture must report FALSE")
	TEST_ASSERT(!source_mix.transfer_ratio_to(target_mix, 0.5), "transfer_ratio_to from an empty mixture must report FALSE")

	qdel(source_mix)
	qdel(target_mix)

/datum/unit_test/atmos_vent_ratio/Run()
	var/datum/gas_mixture/mix = unit_test_air_mix()
	var/moles_before = mix.total_moles()
	var/temperature_before = mix.return_temperature()
	TEST_ASSERT(mix.vent_ratio(0.25), "vent_ratio reported no gas discarded")
	TEST_ASSERT(abs(mix.total_moles() - moles_before * 0.75) < TEST_GAS_EPSILON, "vent_ratio(0.25) should leave 75% of moles")
	TEST_ASSERT_EQUAL(mix.return_temperature(), temperature_before, "vent_ratio must not change temperature")
	mix.clear()
	TEST_ASSERT(!mix.vent_ratio(0.5), "vent_ratio on an empty mixture must report FALSE")
	qdel(mix)

/datum/unit_test/atmos_scrubber_gating/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)
	var/datum/gas_mixture/pipe_side = scrubber.airs[1]
	TEST_ASSERT_NOTNULL(pipe_side, "scrubber has no internal gas mixture")

	// Clean room: scrub() must not move gas, must not reactivate the turf and
	// must not touch the pipenet.
	room.air.clear()
	room.air.set_moles(GAS_O2, MOLES_O2STANDARD)
	room.air.set_moles(GAS_N2, MOLES_N2STANDARD)
	room.air.set_temperature(T20C)
	SSair.remove_from_active(room)
	SSair.pipenets_needing_rebuilt -= scrubber
	TEST_ASSERT(!scrubber.scrub(room), "scrub() reported success over a clean room")
	TEST_ASSERT(!room.excited, "scrubbing a clean room reactivated its turf")
	TEST_ASSERT(!(scrubber in SSair.pipenets_needing_rebuilt), "scrubbing a clean room dirtied the pipenet path")
	TEST_ASSERT(pipe_side.total_moles() < TEST_GAS_EPSILON, "scrubbing a clean room moved gas")

	// Room with CO2: scrub() must collect it and reactivate the turf.
	room.air.set_moles(GAS_CO2, 6)
	var/co2_before = room.air.get_moles(GAS_CO2)
	TEST_ASSERT(scrubber.scrub(room), "scrub() failed over a CO2 room")
	TEST_ASSERT(room.air.get_moles(GAS_CO2) < co2_before, "scrub() did not reduce room CO2")
	TEST_ASSERT(pipe_side.get_moles(GAS_CO2) > 0, "scrub() did not collect CO2 into the scrubber")
	TEST_ASSERT(room.excited, "scrubbing an occupied room must reactivate its turf")
	TEST_ASSERT(abs((room.air.get_moles(GAS_CO2) + pipe_side.get_moles(GAS_CO2)) - co2_before) < TEST_GAS_EPSILON, "scrubbed CO2 was not conserved")

	// Cleanup subsystem side effects of the allocation.
	SSair.pipenets_needing_rebuilt -= scrubber
	room.air.copy_from_turf(room)
	SSair.remove_from_active(room)

/datum/unit_test/atmos_assume_air/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	room.air.clear()
	var/datum/gas_mixture/giver = new(1000)
	giver.set_moles(GAS_O2, 100)
	giver.set_temperature(T20C)
	SSair.remove_from_active(room)
	TEST_ASSERT(room.assume_air_moles(giver, 40), "assume_air_moles failed")
	TEST_ASSERT(abs(room.air.get_moles(GAS_O2) - 40) < TEST_GAS_EPSILON, "turf should have gained 40 moles of o2")
	TEST_ASSERT(abs(giver.get_moles(GAS_O2) - 60) < TEST_GAS_EPSILON, "giver should have lost 40 moles of o2")
	TEST_ASSERT(room.excited, "assume_air_moles must reactivate the turf")
	qdel(giver)
	room.air.copy_from_turf(room)
	SSair.remove_from_active(room)

/datum/unit_test/atmos_planetary_template/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/model = run_loc_floor_bottom_left
	TEST_ASSERT(istype(model), "test location is not an open turf")

	var/datum/gas_mixture/template = SSair.get_planetary_template(model)
	TEST_ASSERT_NOTNULL(template, "planetary template was not built")
	TEST_ASSERT(template.gc_share, "planetary template must be immutable")
	TEST_ASSERT_EQUAL(SSair.get_planetary_template(model), template, "planetary template was not cached")
	TEST_ASSERT_EQUAL(SSair.planetary[model.initial_gas_mix], template, "planetary cache must be keyed by the raw gas string")

	// share_with_template must reproduce the old new+copy_from_turf+share+qdel
	// path exactly, without mutating the template.
	var/datum/gas_mixture/new_path = new(CELL_VOLUME)
	new_path.set_moles(GAS_PLASMA, 8)
	new_path.set_moles(GAS_O2, 2)
	new_path.set_temperature(T20C + 150)
	new_path.archive()
	var/datum/gas_mixture/old_path = new(CELL_VOLUME)
	old_path.set_moles(GAS_PLASMA, 8)
	old_path.set_moles(GAS_O2, 2)
	old_path.set_temperature(T20C + 150)
	old_path.archive()

	var/template_moles_before = template.total_moles()
	new_path.share_with_template(template, 0.25)

	var/datum/gas_mixture/scratch = new
	scratch.copy_from_turf(model)
	scratch.archive()
	old_path.share(scratch, 0.25, 0.25)
	qdel(scratch)

	TEST_ASSERT(abs(template.total_moles() - template_moles_before) < TEST_GAS_EPSILON, "share_with_template mutated the template")
	TEST_ASSERT(abs(new_path.return_temperature() - old_path.return_temperature()) < 0.01, "template share temperature diverged: [new_path.return_temperature()] vs [old_path.return_temperature()]")
	TEST_ASSERT(abs(new_path.last_share - old_path.last_share) < TEST_GAS_EPSILON, "template share last_share diverged: [new_path.last_share] vs [old_path.last_share]")
	for(var/id in new_path.get_gases() | old_path.get_gases())
		TEST_ASSERT(abs(new_path.get_moles(id) - old_path.get_moles(id)) < TEST_GAS_EPSILON, "template share [id] diverged: [new_path.get_moles(id)] vs [old_path.get_moles(id)]")

	qdel(new_path)
	qdel(old_path)

/// External air changes (vent top-ups, breathing) must postpone excited group
/// dismantling without destroying the group: rebuilding room groups from
/// scratch every fire was a major source of permanently active turfs. They
/// must NOT postpone group averaging - self_breakdown spreading the gas across
/// the whole group is the only path gas has out of a drip-fed pocket (corpse
/// rot) whose per-cycle shares stay under the wake threshold.
/datum/unit_test/atmos_group_survives_external_change/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/first = run_loc_floor_bottom_left
	var/turf/open/second = locate(first.x + 1, first.y, first.z)
	TEST_ASSERT(istype(first), "test location is not an open turf")
	TEST_ASSERT(istype(second), "adjacent test location is not an open turf")

	var/datum/excited_group/group = new
	group.add_turf(first)
	group.add_turf(second)
	group.breakdown_cooldown = 3
	group.dismantle_cooldown = 9

	SSair.add_to_active(first)
	TEST_ASSERT_EQUAL(first.excited_group, group, "external change destroyed the excited group")
	TEST_ASSERT_EQUAL(second.excited_group, group, "external change detached a group member")
	TEST_ASSERT_EQUAL(group.breakdown_cooldown, 3, "external change must not postpone group averaging")
	TEST_ASSERT_EQUAL(group.dismantle_cooldown, 0, "external change must reset the dismantle cooldown")

	// A structural change (adjacency recalculated: door closed, wall built) must
	// dismantle the group instead, or self_breakdown would keep averaging gas
	// across the new blockage.
	first.air_update_turf(TRUE)
	TEST_ASSERT_NULL(first.excited_group, "adjacency change did not dismantle the excited group")
	TEST_ASSERT_NULL(second.excited_group, "adjacency change left a group member attached")

	group.garbage_collect()
	SSair.remove_from_active(first)
	SSair.remove_from_active(second)

/// A grouped turf whose shares stalled must rest individually (leave the
/// active list, stay in the group). Ejecting it through remove_from_active
/// nuked the whole group, which kept entire planetary surfaces (19k turfs)
/// cycling forever whenever any single member kept churning.
/// Interior turfs of the reservation: the testing zone borders reserved
/// space, and a space-adjacent turf is a genuine churner that must not rest.
/datum/unit_test/atmos_stalled_turf_rests/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/first = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/open/second = locate(origin.x + 2, origin.y + 1, origin.z)
	TEST_ASSERT(istype(first), "test location is not an open turf")
	TEST_ASSERT(istype(second), "adjacent test location is not an open turf")

	var/datum/excited_group/group = new
	group.add_turf(first)
	group.add_turf(second)
	SSair.add_to_active(first, FALSE)
	SSair.add_to_active(second, FALSE)

	// Both turfs hold settled identical air; first has been stalling for a
	// full individual-rest window already, second is one cycle short of it.
	first.atmos_cooldown = EXCITED_GROUP_INDIVIDUAL_REST_CYCLES
	second.atmos_cooldown = EXCITED_GROUP_INDIVIDUAL_REST_CYCLES - 1
	var/fire_count = max(first.current_cycle, second.current_cycle) + 1
	first.process_cell(fire_count)
	second.process_cell(fire_count)

	TEST_ASSERT(!(first in SSair.active_turfs), "stalled group member did not rest out of the active list")
	TEST_ASSERT(second in SSair.active_turfs, "a group member one cycle short of the rest window rested early")
	TEST_ASSERT_EQUAL(first.excited_group, group, "resting a stalled turf detached it from its excited group")
	TEST_ASSERT_EQUAL(second.excited_group, group, "resting a stalled turf destroyed the group for other members")
	TEST_ASSERT(group in SSair.excited_groups, "resting a stalled turf removed the group from SSair")

	group.garbage_collect()
	first.atmos_cooldown = 0
	second.atmos_cooldown = 0
	SSair.remove_from_active(first)
	SSair.remove_from_active(second)

/// Group averaging must not reset the members' personal stall counters:
/// zeroing atmos_cooldown every breakdown blocked the individual rest path
/// for every member of a group pinned awake by a single churning turf.
/datum/unit_test/atmos_breakdown_preserves_stall_counter/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/first = run_loc_floor_bottom_left
	var/turf/open/second = locate(first.x + 1, first.y, first.z)
	TEST_ASSERT(istype(first), "test location is not an open turf")
	TEST_ASSERT(istype(second), "adjacent test location is not an open turf")

	var/datum/excited_group/group = new
	group.add_turf(first)
	group.add_turf(second)
	first.atmos_cooldown = 10
	second.atmos_cooldown = 10

	group.self_breakdown()

	TEST_ASSERT_EQUAL(first.atmos_cooldown, 10, "self_breakdown reset a member's stall counter")
	TEST_ASSERT_EQUAL(second.atmos_cooldown, 10, "self_breakdown reset a member's stall counter")

	group.garbage_collect()
	first.atmos_cooldown = 0
	second.atmos_cooldown = 0
	first.air.copy_from_turf(first)
	second.air.copy_from_turf(second)
	SSair.remove_from_active(first)
	SSair.remove_from_active(second)

/// Group averaging must cover the ENTIRE group, resting members included,
/// without waking them. Excluding resting members preserved every settled
/// pocket, so post-breach fields flattened ring by ring through the poke
/// frontier - O(diameter^2) cycles of frontier churn for a large room - and
/// drip-fed gas (corpse rot) only left its pocket one poke ring at a time.
/// One breakdown must make the whole bucket uniform in a single pass.
/datum/unit_test/atmos_breakdown_averages_resting_members/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/first = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/open/second = locate(origin.x + 2, origin.y + 1, origin.z)
	var/turf/open/resting = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(first), "test location is not an open turf")
	TEST_ASSERT(istype(second), "adjacent test location is not an open turf")
	TEST_ASSERT(istype(resting), "resting test location is not an open turf")

	var/datum/excited_group/group = new
	group.add_turf(first)
	group.add_turf(second)
	group.add_turf(resting)
	SSair.add_to_active(first, FALSE)
	SSair.add_to_active(second, FALSE)
	SSair.add_to_active(resting, FALSE)
	SSair.sleep_active_turf(resting)
	TEST_ASSERT(!(resting in SSair.active_turfs), "sleep_active_turf left the turf in the active list")
	TEST_ASSERT_EQUAL(resting.excited_group, group, "sleep_active_turf detached the turf from its group")

	var/resting_o2_before = resting.air.get_moles(GAS_O2)
	first.air.set_moles(GAS_O2, resting_o2_before + 30)

	group.self_breakdown()

	TEST_ASSERT(abs(first.air.get_moles(GAS_O2) - (resting_o2_before + 10)) < 0.001, "awake members did not average to the expected mix")
	TEST_ASSERT(abs(second.air.get_moles(GAS_O2) - (resting_o2_before + 10)) < 0.001, "awake members did not average to the expected mix")
	TEST_ASSERT(abs(resting.air.get_moles(GAS_O2) - (resting_o2_before + 10)) < 0.001, "breakdown averaging skipped a resting member")
	TEST_ASSERT(!(resting in SSair.active_turfs), "breakdown averaging woke a resting member")
	TEST_ASSERT(!resting.excited, "breakdown averaging set a resting member excited")
	TEST_ASSERT_EQUAL(resting.excited_group, group, "breakdown averaging detached a resting member from its group")

	group.garbage_collect()
	first.air.copy_from_turf(first)
	second.air.copy_from_turf(second)
	resting.air.copy_from_turf(resting)
	SSair.remove_from_active(first)
	SSair.remove_from_active(second)
	SSair.remove_from_active(resting)

/// With full-group averaging, the poke's only remaining job is frontier
/// expansion: a resting member bordering turfs OUTSIDE the group must wake to
/// compare against them (that comparison is the only way the group can grow
/// into a settled room), while an interior resting member whose every open
/// neighbor is a group mate must stay asleep - it is already at the average.
/datum/unit_test/atmos_breakdown_pokes_group_boundary/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/center = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT(istype(center), "test location is not an open turf")
	TEST_ASSERT(LAZYLEN(center.atmos_adjacent_turfs), "center test turf has no atmos adjacency")

	var/datum/excited_group/group = new
	var/list/turf/open/members = list(center)
	for(var/turf/open/neighbor as anything in center.atmos_adjacent_turfs)
		TEST_ASSERT(istype(neighbor), "center neighbor is not an open turf")
		members += neighbor
	for(var/turf/open/member as anything in members)
		group.add_turf(member)
		SSair.add_to_active(member, FALSE)
		SSair.sleep_active_turf(member)

	// The breakdown must actually change every member's air: unchanged resting
	// members are evicted from the group instead of poked.
	center.air.set_moles(GAS_O2, center.air.get_moles(GAS_O2) + 150)

	group.self_breakdown(poke_resting = TRUE)

	TEST_ASSERT(!(center in SSair.active_turfs), "breakdown poked an interior resting member (all its neighbors are group mates)")
	var/poked = 0
	for(var/turf/open/member as anything in members)
		if(member == center)
			continue
		if(member in SSair.active_turfs)
			poked++
			TEST_ASSERT_EQUAL(member.atmos_cooldown, EXCITED_GROUP_INDIVIDUAL_REST_CYCLES, "poked boundary member did not get the one-shot stall budget")
	TEST_ASSERT_EQUAL(poked, length(members) - 1, "not every group-boundary resting member was poked")

	group.garbage_collect()
	for(var/turf/open/member as anything in members)
		member.atmos_cooldown = 0
		member.air.copy_from_turf(member)
		SSair.remove_from_active(member)

/// A group whose every member has individually rested can generate no new
/// deltas on its own (anything external wakes members back through
/// add_to_active): waiting out the rest of the dismantle window just kept
/// re-averaging an already-quiet room every breakdown. The next lifecycle
/// tick must dismantle such a group outright.
/datum/unit_test/atmos_group_dismantles_when_all_rest/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/first = run_loc_floor_bottom_left
	var/turf/open/second = locate(first.x + 1, first.y, first.z)
	TEST_ASSERT(istype(first), "test location is not an open turf")
	TEST_ASSERT(istype(second), "adjacent test location is not an open turf")

	var/datum/excited_group/group = new
	group.add_turf(first)
	group.add_turf(second)
	SSair.add_to_active(first, FALSE)
	SSair.add_to_active(second, FALSE)
	SSair.sleep_active_turf(first)
	SSair.sleep_active_turf(second)

	group.tick_lifecycle()

	TEST_ASSERT(!(group in SSair.excited_groups), "an all-resting group survived its lifecycle tick")
	TEST_ASSERT_NULL(first.excited_group, "dismantling an all-resting group left a member attached")
	TEST_ASSERT_NULL(second.excited_group, "dismantling an all-resting group left a member attached")

	first.atmos_cooldown = 0
	second.atmos_cooldown = 0
	SSair.remove_from_active(first)
	SSair.remove_from_active(second)

/// Averaging writes new air onto resting tiles without waking the tile itself;
/// a sleeping vent/scrubber registered on such a tile must still get its wake
/// call, or it only notices the new gas on its idle heartbeat much later.
/datum/unit_test/atmos_breakdown_wakes_registered_machines/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	var/turf/open/neighbor = locate(room.x + 1, room.y, room.z)
	TEST_ASSERT(istype(room), "test location is not an open turf")
	TEST_ASSERT(istype(neighbor), "adjacent test location is not an open turf")
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)
	scrubber.register_turf_wake()

	var/datum/excited_group/group = new
	group.add_turf(room)
	group.add_turf(neighbor)
	SSair.add_to_active(room, FALSE)
	SSair.add_to_active(neighbor, FALSE)
	SSair.sleep_active_turf(room)
	neighbor.air.set_moles(GAS_CO2, 20)

	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	TEST_ASSERT(!scrubber.atmos_processing, "scrubber did not go to sleep during setup")

	group.self_breakdown()

	TEST_ASSERT(scrubber.atmos_processing, "breakdown rewrote the tile's air but did not wake the registered machine")

	scrubber.unregister_turf_wake()
	group.garbage_collect()
	room.air.copy_from_turf(room)
	neighbor.air.copy_from_turf(neighbor)
	room.atmos_cooldown = 0
	neighbor.atmos_cooldown = 0
	SSair.remove_from_active(room)
	SSair.remove_from_active(neighbor)

/// The write-back wake is for tiles whose air actually changed. A tile already
/// sitting at the bucket average gets identical air written back, and its
/// sleeping vent/scrubber must stay in the idle heartbeat: perpetual excited
/// groups (freezer rooms, engine storages) break down every
/// EXCITED_GROUP_BREAKDOWN_CYCLES fires while a machine needs
/// ATMOS_MACHINE_IDLE_STREAK no-op fires to rest - an unconditional wake pins
/// every machine in such a room awake forever.
/datum/unit_test/atmos_breakdown_wake_needs_air_change/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	var/turf/open/neighbor = locate(room.x + 1, room.y, room.z)
	TEST_ASSERT(istype(room), "test location is not an open turf")
	TEST_ASSERT(istype(neighbor), "adjacent test location is not an open turf")
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)
	scrubber.register_turf_wake()

	// Both tiles hold the exact same mix, so averaging rewrites them with what
	// they already have.
	room.air.copy_from_turf(room)
	neighbor.air.copy_from(room.air)

	var/datum/excited_group/group = new
	group.add_turf(room)
	group.add_turf(neighbor)
	SSair.add_to_active(room, FALSE)
	SSair.add_to_active(neighbor, FALSE)
	SSair.sleep_active_turf(room)

	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	TEST_ASSERT(!scrubber.atmos_processing, "scrubber did not go to sleep during setup")

	group.self_breakdown()

	TEST_ASSERT(!scrubber.atmos_processing, "breakdown woke a machine on a tile whose air did not change")

	scrubber.unregister_turf_wake()
	group.garbage_collect()
	room.air.copy_from_turf(room)
	neighbor.air.copy_from_turf(neighbor)
	room.atmos_cooldown = 0
	neighbor.atmos_cooldown = 0
	SSair.remove_from_active(room)
	SSair.remove_from_active(neighbor)

/// Eviction replaces the boundary poke for settled members: a resting tile
/// whose air the breakdown did not change leaves the group without a wake, and
/// the vents/scrubbers standing on it (room perimeters are exactly where they
/// live) must stay in the idle heartbeat instead of being re-armed every
/// EXCITED_GROUP_BREAKDOWN_CYCLES fires.
/datum/unit_test/atmos_eviction_leaves_machines_asleep/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	var/turf/open/neighbor = locate(room.x + 1, room.y, room.z)
	TEST_ASSERT(istype(room), "test location is not an open turf")
	TEST_ASSERT(istype(neighbor), "adjacent test location is not an open turf")
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)
	scrubber.register_turf_wake()

	// Identical mixes keep the write-back wake gate shut; only the poke path
	// is under test.
	room.air.copy_from_turf(room)
	neighbor.air.copy_from(room.air)

	var/datum/excited_group/group = new
	group.add_turf(room)
	group.add_turf(neighbor)
	SSair.add_to_active(room, FALSE)
	SSair.add_to_active(neighbor, FALSE)
	SSair.sleep_active_turf(room)
	SSair.sleep_active_turf(neighbor)

	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	TEST_ASSERT(!scrubber.atmos_processing, "scrubber did not go to sleep during setup")

	group.self_breakdown(poke_resting = TRUE)

	TEST_ASSERT(!(room in SSair.active_turfs), "breakdown woke an unchanged resting member instead of evicting it")
	TEST_ASSERT_NULL(room.excited_group, "breakdown kept an unchanged resting member in the group")
	TEST_ASSERT(!scrubber.atmos_processing, "eviction woke a machine although the tile's air did not change")

	scrubber.unregister_turf_wake()
	group.garbage_collect()
	room.air.copy_from_turf(room)
	neighbor.air.copy_from_turf(neighbor)
	room.atmos_cooldown = 0
	neighbor.atmos_cooldown = 0
	SSair.remove_from_active(room)
	SSair.remove_from_active(neighbor)

/// Perpetual groups (planetary surfaces around a leak, space-edge drains) never
/// dismantle, and a turf has no individual way out of turf_list - over hours a
/// group accumulates every turf that was ever excited near it (32k members on a
/// live lavaland) and every EXCITED_GROUP_BREAKDOWN_CYCLES fires re-averages all
/// of them in one atomic unyieldable pass. Breakdown must evict resting members
/// it did not change: they sit exactly at the bucket average, contribute nothing
/// and receive nothing, and any real future delta re-adds them through the
/// normal share paths.
/datum/unit_test/atmos_breakdown_evicts_settled_members/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/awake = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/open/settled = locate(origin.x + 2, origin.y + 1, origin.z)
	var/turf/open/settled_too = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(awake), "test location is not an open turf")
	TEST_ASSERT(istype(settled), "adjacent test location is not an open turf")
	TEST_ASSERT(istype(settled_too), "adjacent test location is not an open turf")

	// All three hold the exact same mix: the bucket average IS their air, so the
	// write-back changes nothing on the resting members.
	awake.air.copy_from_turf(awake)
	settled.air.copy_from(awake.air)
	settled_too.air.copy_from(awake.air)

	var/datum/excited_group/group = new
	group.add_turf(awake)
	group.add_turf(settled)
	group.add_turf(settled_too)
	SSair.add_to_active(awake, FALSE)
	SSair.add_to_active(settled, FALSE)
	SSair.add_to_active(settled_too, FALSE)
	SSair.sleep_active_turf(settled)
	SSair.sleep_active_turf(settled_too)

	group.self_breakdown(poke_resting = TRUE)

	TEST_ASSERT(!(settled in group.turf_list), "breakdown kept an unchanged resting member in the group")
	TEST_ASSERT(!(settled_too in group.turf_list), "breakdown kept an unchanged resting member in the group")
	TEST_ASSERT_NULL(settled.excited_group, "evicted member still points at the group")
	TEST_ASSERT_NULL(settled_too.excited_group, "evicted member still points at the group")
	TEST_ASSERT(!(settled in SSair.active_turfs), "eviction woke a settled member")
	TEST_ASSERT(!settled.excited, "eviction left a settled member excited")
	TEST_ASSERT(awake in group.turf_list, "breakdown evicted an awake member")
	TEST_ASSERT_EQUAL(awake.excited_group, group, "breakdown detached an awake member")
	TEST_ASSERT(group in SSair.excited_groups, "breakdown killed a group that still has an awake member")

	group.garbage_collect()
	awake.air.copy_from_turf(awake)
	settled.air.copy_from_turf(settled)
	settled_too.air.copy_from_turf(settled_too)
	awake.atmos_cooldown = 0
	settled.atmos_cooldown = 0
	settled_too.atmos_cooldown = 0
	SSair.remove_from_active(awake)
	SSair.remove_from_active(settled)
	SSair.remove_from_active(settled_too)

/// The dismantle decision used to scan the whole turf_list for an awake member
/// every group-stage tick - a permanent O(N) tax once a perpetual group grows
/// large. The group must track its awake member count incrementally through
/// every excited-flag transition instead.
/datum/unit_test/atmos_group_awake_counter/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/first = run_loc_floor_bottom_left
	var/turf/open/second = locate(first.x + 1, first.y, first.z)
	TEST_ASSERT(istype(first), "test location is not an open turf")
	TEST_ASSERT(istype(second), "adjacent test location is not an open turf")

	var/datum/excited_group/group = new
	group.add_turf(first)
	TEST_ASSERT_EQUAL(group.awake_members, 1, "add_turf did not count a new awake member")
	group.add_turf(second)
	TEST_ASSERT_EQUAL(group.awake_members, 2, "add_turf did not count a second awake member")
	group.add_turf(first)
	TEST_ASSERT_EQUAL(group.awake_members, 2, "re-adding an awake member double-counted it")
	SSair.add_to_active(first, FALSE)
	TEST_ASSERT_EQUAL(group.awake_members, 2, "add_to_active double-counted an already-awake member")
	SSair.sleep_active_turf(first)
	TEST_ASSERT_EQUAL(group.awake_members, 1, "sleep_active_turf did not release an awake slot")
	SSair.add_to_active(first, FALSE)
	TEST_ASSERT_EQUAL(group.awake_members, 2, "add_to_active did not count a woken resting member")
	SSair.sleep_active_turf(first)
	SSair.sleep_active_turf(second)
	TEST_ASSERT_EQUAL(group.awake_members, 0, "resting every member left a nonzero awake count")

	group.tick_lifecycle()
	TEST_ASSERT(!(group in SSair.excited_groups), "an all-resting group survived its lifecycle tick")
	TEST_ASSERT_NULL(first.excited_group, "dismantling left a member attached")

	first.atmos_cooldown = 0
	second.atmos_cooldown = 0
	SSair.remove_from_active(first)
	SSair.remove_from_active(second)

/// Merging groups must transfer the awake count to the winner and leave the
/// loser truly empty: a dropped group that still lists turfs holds strong refs
/// to them until the datum is collected, and a stale awake count on it would
/// make any accidental lifecycle tick misjudge the dismantle decision.
/datum/unit_test/atmos_merge_transfers_awake_count/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/first = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/open/second = locate(origin.x + 2, origin.y + 1, origin.z)
	var/turf/open/third = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(first), "test location is not an open turf")
	TEST_ASSERT(istype(second), "adjacent test location is not an open turf")
	TEST_ASSERT(istype(third), "adjacent test location is not an open turf")

	// Bigger group keeps its identity and absorbs the smaller one.
	var/datum/excited_group/big = new
	big.add_turf(first)
	big.add_turf(second)
	var/datum/excited_group/small = new
	small.add_turf(third)
	big.merge_groups(small)
	TEST_ASSERT_EQUAL(big.awake_members, 3, "merge did not transfer the loser's awake count")
	TEST_ASSERT_EQUAL(third.excited_group, big, "merge did not repoint the loser's member")
	TEST_ASSERT_EQUAL(length(small.turf_list), 0, "merge left members listed in the dead loser group")
	TEST_ASSERT(!(small in SSair.excited_groups), "merge left the loser group registered")
	big.garbage_collect()

	// Mirror branch: the caller is the smaller group and dissolves into the
	// bigger one.
	var/datum/excited_group/tiny = new
	tiny.add_turf(first)
	var/datum/excited_group/pair = new
	pair.add_turf(second)
	pair.add_turf(third)
	tiny.merge_groups(pair)
	TEST_ASSERT_EQUAL(pair.awake_members, 3, "merge into the bigger group did not transfer the awake count")
	TEST_ASSERT_EQUAL(first.excited_group, pair, "merge into the bigger group did not repoint the smaller group's member")
	TEST_ASSERT_EQUAL(length(tiny.turf_list), 0, "merge left members listed in the dead smaller group")
	pair.garbage_collect()

	SSair.remove_from_active(first)
	SSair.remove_from_active(second)
	SSair.remove_from_active(third)

/// The awake counter is maintained incrementally; exotic paths (a turf type
/// change under a live group) can strand it. Every breakdown already walks the
/// whole membership, so it must recount the counter exactly - drift heals
/// within EXCITED_GROUP_BREAKDOWN_CYCLES instead of pinning the group alive
/// forever.
/datum/unit_test/atmos_breakdown_recounts_awake_members/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/first = run_loc_floor_bottom_left
	var/turf/open/second = locate(first.x + 1, first.y, first.z)
	TEST_ASSERT(istype(first), "test location is not an open turf")
	TEST_ASSERT(istype(second), "adjacent test location is not an open turf")
	first.air.copy_from_turf(first)
	second.air.copy_from(first.air)

	var/datum/excited_group/group = new
	group.add_turf(first)
	group.add_turf(second)
	group.awake_members = 99

	group.self_breakdown()

	TEST_ASSERT_EQUAL(group.awake_members, 2, "breakdown did not recount the awake members")

	group.garbage_collect()
	first.air.copy_from_turf(first)
	second.air.copy_from_turf(second)
	first.atmos_cooldown = 0
	second.atmos_cooldown = 0
	SSair.remove_from_active(first)
	SSair.remove_from_active(second)

/// A planetary turf must shed most of a pure-temperature excess in one cycle
/// (upstream follows the template share with a conductive share against a
/// 5x-inflated template heat capacity). The turf and all its neighbors are
/// heated uniformly so neighbor conduction is zero and only the template pull
/// acts, making the expectation independent of the local neighbor count.
/datum/unit_test/atmos_planetary_temperature_pull/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	// Center of the reservation: the zone borders reserved space, and a space
	// neighbor's conductive pull (vacuum heat capacity 7000) would swamp the
	// template pull being measured here.
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/planet_turf = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT(istype(planet_turf), "test location is not an open turf")
	for(var/turf/neighbor as anything in planet_turf.atmos_adjacent_turfs)
		TEST_ASSERT(isfloorturf(neighbor), "center test turf has a non-floor neighbor; the reservation layout changed")

	planet_turf.planetary_atmos = TRUE
	var/datum/gas_mixture/template = SSair.get_planetary_template(planet_turf)
	var/template_temperature = template.return_temperature()
	planet_turf.air.copy_from(template)
	planet_turf.air.set_temperature(template_temperature + 100)
	var/fire_count = planet_turf.current_cycle + 1
	for(var/turf/open/neighbor as anything in planet_turf.atmos_adjacent_turfs)
		neighbor.air.copy_from(template)
		neighbor.air.set_temperature(template_temperature + 100)
		fire_count = max(fire_count, neighbor.current_cycle + 1)
	SSair.add_to_active(planet_turf, FALSE)

	planet_turf.process_cell(fire_count)

	// The in-share coupling alone pulls 20% per cycle (80K left); with the
	// inflated-capacity conductive follow-up about 47K is left. Assert the
	// midpoint with margin on both sides.
	var/remaining_delta = planet_turf.air.return_temperature() - template_temperature
	TEST_ASSERT(remaining_delta < 60, "planetary turf kept [remaining_delta]K of a 100K excess after one cycle")

	if(planet_turf.excited_group)
		planet_turf.excited_group.garbage_collect()
	planet_turf.planetary_atmos = FALSE
	planet_turf.atmos_cooldown = 0
	planet_turf.air.copy_from_turf(planet_turf)
	SSair.remove_from_active(planet_turf)
	for(var/turf/open/neighbor as anything in planet_turf.atmos_adjacent_turfs)
		neighbor.atmos_cooldown = 0
		neighbor.air.copy_from_turf(neighbor)
		SSair.remove_from_active(neighbor)

/// Space drains must finish the job: below SPACE_DRAIN_FINISH_PRESSURE the
/// tile dumps everything in one pass and matches space temperature - the
/// exponential 1/(neighbors+1) bleed spends tens of cycles on residue that is
/// already unsurvivable, and that tail was pure churn. Above the threshold
/// the gradual drain (and its spacewind) must stay untouched.
/datum/unit_test/atmos_space_drain_finish/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/drain = locate(origin.x + 1, origin.y + 1, origin.z)
	TEST_ASSERT(istype(drain), "test location is not an open turf")

	// Pocket arena: three walls and one space neighbor, so the only exchange
	// the drain tile has is the space drain itself.
	var/turf/hole = locate(origin.x + 1, origin.y + 2, origin.z)
	var/turf/west_wall = locate(origin.x, origin.y + 1, origin.z)
	var/turf/east_wall = locate(origin.x + 2, origin.y + 1, origin.z)
	var/turf/south_wall = locate(origin.x + 1, origin.y, origin.z)
	hole.ChangeTurf(/turf/open/space/basic)
	west_wall.ChangeTurf(/turf/closed/wall)
	east_wall.ChangeTurf(/turf/closed/wall)
	south_wall.ChangeTurf(/turf/closed/wall)
	drain.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT_EQUAL(LAZYLEN(drain.atmos_adjacent_turfs), 1, "pocket arena should have exactly the space neighbor")
	TEST_ASSERT(locate(/turf/open/space) in drain.atmos_adjacent_turfs, "arena setup failed: no space neighbor")
	if(drain.excited_group)
		drain.excited_group.garbage_collect()
	SSair.remove_from_active(drain)

	// Above the threshold: one cycle takes 1/(neighbors+1) = half, not all.
	drain.air.copy_from_turf(drain)
	var/moles_full = drain.air.total_moles()
	TEST_ASSERT(moles_full > 0, "drain tile has no default air")
	SSair.add_to_active(drain, FALSE)
	var/fire_count = drain.current_cycle + 1
	drain.process_cell(fire_count)
	TEST_ASSERT(abs(drain.air.total_moles() - moles_full * 0.5) < 0.1, "above-threshold space drain is no longer gradual: [drain.air.total_moles()] of [moles_full] mol left")

	// Below the threshold: the tile dumps everything and matches space.
	drain.air.copy_from_turf(drain)
	drain.air.multiply(0.15)
	SSair.add_to_active(drain, FALSE)
	fire_count++
	drain.process_cell(fire_count)
	TEST_ASSERT(drain.air.total_moles() < 0.001, "sub-threshold space drain left residue: [drain.air.total_moles()] mol")
	TEST_ASSERT(abs(drain.air.return_temperature() - TCMB) < 0.01, "dumped tile did not match space temperature")

	if(drain.excited_group)
		drain.excited_group.garbage_collect()
	SSair.high_pressure_delta -= drain
	drain.pressure_difference = 0
	drain.atmos_cooldown = 0
	drain.air.copy_from_turf(drain)
	SSair.remove_from_active(drain)

/// Idle-heartbeat machines must wake instantly when air on their turf changes,
/// and enter the heartbeat only after a full streak of no-op fires.
/datum/unit_test/atmos_machine_idle_wake/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)

	// Streak accumulation drops the machine into the heartbeat.
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		TEST_ASSERT(scrubber.atmos_idle_until <= world.time, "machine went idle before completing the streak")
		scrubber.atmos_consider_idle()
	TEST_ASSERT(scrubber.atmos_idle_until > world.time, "machine did not enter the idle heartbeat after a full no-op streak")

	// atmos_wake clears it.
	scrubber.atmos_wake()
	TEST_ASSERT_EQUAL(scrubber.atmos_idle_until, 0, "atmos_wake did not clear the idle heartbeat")

	// Turf activation wakes registered machines.
	scrubber.register_turf_wake()
	scrubber.atmos_idle_until = world.time + ATMOS_MACHINE_IDLE_HEARTBEAT
	scrubber.atmos_idle_streak = ATMOS_MACHINE_IDLE_STREAK
	SSair.add_to_active(room, FALSE)
	TEST_ASSERT_EQUAL(scrubber.atmos_idle_until, 0, "turf activation did not wake the registered machine")
	TEST_ASSERT_EQUAL(scrubber.atmos_idle_streak, 0, "turf activation did not reset the idle streak")

	scrubber.unregister_turf_wake()
	TEST_ASSERT(!LAZYLEN(room.atmos_wake_machines), "unregister_turf_wake left a stale wake registration")

	// Destroy() must drop the registration too: the turf list holds a strong
	// ref that would otherwise pin the deleted machine forever.
	var/obj/machinery/atmospherics/components/binary/pump/doomed = new(room)
	doomed.register_turf_wake()
	TEST_ASSERT(LAZYLEN(room.atmos_wake_machines), "register_turf_wake did not register the pump")
	qdel(doomed)
	TEST_ASSERT(!LAZYLEN(room.atmos_wake_machines), "Destroy() left a stale wake registration on the turf")
	SSair.remove_from_active(room)

/// The heartbeat is a standing cost: every sleeping machine returns for one
/// full recheck each ATMOS_MACHINE_IDLE_HEARTBEAT. To attribute machinery-phase
/// cost the benchmark needs the per-fire wake count, so the wake proc must
/// report how many machines it returned to processing.
/datum/unit_test/atmos_heartbeat_wake_counter/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	TEST_ASSERT(scrubber in SSair.atmos_idle_queue, "scrubber did not enter the idle queue during setup")
	// Флаш уже истёкших ЧУЖИХ машин: heartbeat-очередь глобальная и живая станция
	// подмешивает в счётчик свои спящие вентиляции (наблюдалось woken=4 на Box).
	// Между флашем и замером снов нет, world.time заморожен - новые дедлайны истечь
	// не могут, значит следующий вызов посчитает ровно нашу машину.
	SSair.wake_expired_idle_machines()
	TEST_ASSERT(scrubber in SSair.atmos_idle_queue, "flushing expired machines must not touch the unexpired scrubber")
	// The queue is FIFO by deadline; simulating expiry means moving to the head.
	SSair.atmos_idle_queue.Remove(scrubber)
	SSair.atmos_idle_queue.Insert(1, scrubber)
	SSair.atmos_idle_queue[scrubber] = world.time - 1
	var/woken = SSair.wake_expired_idle_machines()
	TEST_ASSERT_EQUAL(woken, 1, "wake_expired_idle_machines did not report the single woken machine")
	TEST_ASSERT(scrubber.atmos_processing, "the counted machine was not actually returned to processing")

/// The benchmark's machinery decomposition: a profiled pass times every
/// processing machine bucketed by type, standing in for the normal pass without
/// changing its semantics (PROCESS_KILL returns still leave the list).
/datum/unit_test/atmos_machinery_profile_pass/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)
	TEST_ASSERT(scrubber.atmos_processing, "freshly created scrubber is not in SSair processing")
	var/obj/machinery/atmospherics/components/unary/portables_connector/port = allocate(/obj/machinery/atmospherics/components/unary/portables_connector, room)
	TEST_ASSERT(port.atmos_processing, "freshly created connector is not in SSair processing")

	var/list/result = SSair.profile_machinery_pass(SSair.wait * 0.1)

	TEST_ASSERT(islist(result), "profile pass returned no result")
	TEST_ASSERT(result["n"] >= 2, "profile pass did not count the processing machines")
	var/list/type_buckets = result["types"]
	TEST_ASSERT(islist(type_buckets), "profile result has no type buckets")
	var/list/bucket = type_buckets["[scrubber.type]"]
	TEST_ASSERT(islist(bucket), "profile pass did not bucket the processing scrubber")
	TEST_ASSERT(bucket["n"] >= 1, "scrubber type bucket has no count")
	TEST_ASSERT(!isnull(bucket["ms"]), "scrubber type bucket has no timing")
	// An unused connector PROCESS_KILLs itself: the profiled pass must honor it.
	TEST_ASSERT(!port.atmos_processing, "profiled pass ignored a PROCESS_KILL return")

/// Machines that entered the idle heartbeat must leave SSair.atmos_machinery
/// entirely (and rejoin on wake); settled portables and empty connectors must
/// drop out of processing via PROCESS_KILL.
/datum/unit_test/atmos_machinery_sleep/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")

	// A full no-op streak must remove the machine from the processing list.
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)
	TEST_ASSERT(scrubber.atmos_processing, "freshly created scrubber is not in SSair processing")
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	TEST_ASSERT(!scrubber.atmos_processing, "idle-heartbeat machine stayed in SSair processing")
	TEST_ASSERT(!(scrubber in SSair.atmos_machinery), "idle-heartbeat machine stayed in atmos_machinery")
	TEST_ASSERT(scrubber.atmos_idle_queued, "sleeping machine is not flagged as queued")
	TEST_ASSERT(scrubber in SSair.atmos_idle_queue, "sleeping machine is not in the idle wake queue")

	// An expired heartbeat deadline returns it for one full recheck. The queue
	// is FIFO by deadline, so simulating expiry means moving to the head too
	// (live station machines with future deadlines are queued ahead of us).
	SSair.atmos_idle_queue.Remove(scrubber)
	SSair.atmos_idle_queue.Insert(1, scrubber)
	SSair.atmos_idle_queue[scrubber] = world.time - 1
	SSair.wake_expired_idle_machines()
	TEST_ASSERT(scrubber.atmos_processing, "expired heartbeat did not return the machine to processing")
	TEST_ASSERT(!scrubber.atmos_idle_queued, "heartbeat-woken machine kept its queued flag")
	TEST_ASSERT(!(scrubber in SSair.atmos_idle_queue), "heartbeat-woken machine stayed in the idle wake queue")

	// Going idle again re-enqueues; an event wake must put it straight back.
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	TEST_ASSERT(!scrubber.atmos_processing, "second idle streak did not remove the machine again")
	scrubber.atmos_wake()
	TEST_ASSERT(scrubber.atmos_processing, "woken machine did not rejoin SSair processing")
	TEST_ASSERT(scrubber in SSair.atmos_machinery, "woken machine did not rejoin atmos_machinery")

	// Destroy() must pull a sleeping machine out of the wake queue: the queue
	// holds a strong ref that would otherwise pin the deleted machine.
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/doomed_sleeper = new(room)
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		doomed_sleeper.atmos_consider_idle()
	TEST_ASSERT(doomed_sleeper in SSair.atmos_idle_queue, "sleeping test machine did not enter the idle wake queue")
	qdel(doomed_sleeper)
	TEST_ASSERT(!(doomed_sleeper in SSair.atmos_idle_queue), "Destroy() left the machine in the idle wake queue")

	// A settled canister with a closed valve sleeps entirely.
	var/obj/machinery/portable_atmospherics/canister/oxygen/settled = allocate(/obj/machinery/portable_atmospherics/canister/oxygen, room)
	settled.process_atmos() // first pass after spawn may consume the initial excited state
	TEST_ASSERT_EQUAL(settled.process_atmos(), PROCESS_KILL, "settled closed canister did not return PROCESS_KILL")

	// An open valve (into a holding tank) must keep the canister processing.
	var/obj/machinery/portable_atmospherics/canister/oxygen/venting = allocate(/obj/machinery/portable_atmospherics/canister/oxygen, room)
	venting.holding = allocate(/obj/item/tank/internals/emergency_oxygen, room)
	venting.valve_open = TRUE
	venting.process_atmos()
	TEST_ASSERT(venting.process_atmos() != PROCESS_KILL, "open-valve canister went to sleep")
	venting.valve_open = FALSE
	venting.holding = null

	// A connector with no docked portable must not keep processing.
	var/obj/machinery/atmospherics/components/unary/portables_connector/port = allocate(/obj/machinery/atmospherics/components/unary/portables_connector, room)
	TEST_ASSERT_EQUAL(port.process_atmos(), PROCESS_KILL, "unused portables connector did not return PROCESS_KILL")

	// The internal pump of a portable pump is never in SSair processing;
	// idle bookkeeping must not drag it in.
	var/obj/machinery/portable_atmospherics/pump/portable = allocate(/obj/machinery/portable_atmospherics/pump, room)
	TEST_ASSERT(!portable.pump.atmos_processing, "internal pump of a portable is in SSair processing")
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK + 1)
		portable.pump.atmos_consider_idle()
	TEST_ASSERT(!portable.pump.atmos_processing, "idle bookkeeping dragged the internal pump into SSair processing")
	TEST_ASSERT(!portable.pump.atmos_idle_queued, "idle bookkeeping enqueued the internal pump for heartbeat wake-ups")
	SSair.remove_from_active(room)

#undef TEST_GAS_EPSILON
