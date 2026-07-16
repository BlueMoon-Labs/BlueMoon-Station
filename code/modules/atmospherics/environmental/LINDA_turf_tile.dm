/turf
	//conductivity is divided by 10 when interacting with air for balance purposes
	var/thermal_conductivity = 0.05
	var/heat_capacity = 1
	var/temperature_archived = TCMB
	var/archived_cycle = 0
	var/current_cycle = 0

	//list of open turfs adjacent to us
	var/list/atmos_adjacent_turfs
	//bitfield of dirs in which we thermal conductivity is blocked
	var/conductivity_blocked_directions = NONE

	//used for mapping and for breathing while in walls (because that's a thing that needs to be accounted for...)
	//string parsed by /datum/gas/proc/copy_from_turf
	var/initial_gas_mix = OPENTURF_DEFAULT_ATMOS
	//approximation of MOLES_O2STANDARD and MOLES_N2STANDARD pending byond allowing constant expressions to be embedded in constant strings
	// If someone will place 0 of some gas there, SHIT WILL BREAK. Do not do that.

/turf/open
	//used for spacewind
	var/pressure_difference = 0
	var/pressure_direction = 0
	var/turf/pressure_specific_target

	var/datum/excited_group/excited_group
	var/excited = FALSE
	var/equalize_cycle = 0
	var/datum/gas_mixture/air

	var/obj/effect/hotspot/active_hotspot
	var/atmos_cooldown = 0
	var/planetary_atmos = FALSE //air will revert to initial_gas_mix over time

	var/list/atmos_overlay_types //gas IDs of current active gas overlays
	///Vents/scrubbers that want an instant wake-up when air on this turf changes.
	///Maintained by /obj/machinery/atmospherics/register_turf_wake().
	var/tmp/list/atmos_wake_machines

/turf/open/Initialize(mapload, inherited_virtual_z)
	air = new(2500,src)
	air.copy_from_turf(src)
	update_air_ref(planetary_atmos ? AIR_REF_PLANETARY_TURF : AIR_REF_OPEN_TURF)
	return ..()

/turf/open/Destroy()
	if(active_hotspot)
		QDEL_NULL(active_hotspot)
	for(var/turf/open/T as anything in atmos_adjacent_turfs)
		if(SSair)
			SSair.add_to_active(T, FALSE)
	update_air_ref(-1)
	air = null
	return ..()

/////////////////GAS MIXTURE PROCS///////////////////

/turf/open/assume_air(datum/gas_mixture/giver) //use this for machines to adjust air
	return assume_air_ratio(giver, 1)

/turf/open/assume_air_moles(datum/gas_mixture/giver, moles)
	if(!giver)
		return FALSE
	if(air?.gc_share)
		if(!giver.vent_moles(moles))
			return FALSE
	else if(!giver.transfer_to(air, moles))
		return FALSE
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return TRUE

/turf/open/assume_air_ratio(datum/gas_mixture/giver, ratio)
	if(!giver)
		return FALSE
	if(air?.gc_share)
		if(!giver.vent_ratio(ratio))
			return FALSE
	else if(!giver.transfer_ratio_to(air, ratio))
		return FALSE
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return TRUE

/turf/open/transfer_air(datum/gas_mixture/taker, moles)
	if(!taker || !return_air()) // shouldn't transfer from space
		return FALSE
	if(!air.transfer_to(taker, moles))
		return FALSE
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return TRUE

/turf/open/transfer_air_ratio(datum/gas_mixture/taker, ratio)
	if(!taker || !return_air())
		return FALSE
	if(!air.transfer_ratio_to(taker, ratio))
		return FALSE
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return TRUE

/turf/open/remove_air(amount)
	var/datum/gas_mixture/ours = return_air()
	var/datum/gas_mixture/removed = ours.remove(amount)
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return removed

/turf/open/remove_air_ratio(ratio)
	var/datum/gas_mixture/ours = return_air()
	var/datum/gas_mixture/removed = ours.remove_ratio(ratio)
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return removed

/turf/open/proc/copy_air_with_tile(turf/open/T)
	if(istype(T))
		air.copy_from(T.air)

/turf/open/proc/copy_air(datum/gas_mixture/copy)
	if(copy)
		air.copy_from(copy)

/turf/return_air()
	RETURN_TYPE(/datum/gas_mixture)
	var/datum/gas_mixture/GM = new
	GM.copy_from_turf(src)
	return GM

/turf/open/return_air()
	RETURN_TYPE(/datum/gas_mixture)
	return air

/turf/open/return_analyzable_air()
	return return_air()

/turf/temperature_expose()
	if(return_temperature() > heat_capacity)
		to_be_destroyed = TRUE

/turf/proc/archive()
	temperature_archived = return_temperature()

/turf/open/archive()
	if(!air)
		return
	air.archive()
	temperature_archived = air.return_temperature()
	archived_cycle = SSair.times_fired


/turf/open/proc/eg_reset_cooldowns()
	if(excited_group)
		excited_group.reset_cooldowns()
	atmos_cooldown = 0
/turf/open/proc/eg_garbage_collect()
	if(excited_group)
		excited_group.garbage_collect()
/turf/open/proc/get_excited()
	return excited
/turf/open/proc/set_excited()
	excited = TRUE
	if(SSair)
		SSair.add_to_active(src, FALSE)

/////////////////////////GAS OVERLAYS//////////////////////////////


/turf/open/proc/update_visuals()

	var/list/atmos_overlay_types = src.atmos_overlay_types // Cache for free performance
	var/static/list/nonoverlaying_gases = typecache_of_gases_with_no_overlays()

	if(!air) // 2019-05-14: was not able to get this path to fire in testing. Consider removing/looking at callers -Naksu
		if (atmos_overlay_types)
			for(var/overlay in atmos_overlay_types)
				vis_contents -= overlay
			src.atmos_overlay_types = null
		return

	// Runs for every active turf every cycle: read the gas list directly and only
	// allocate the overlay list once a visible gas is actually found.
	var/list/new_overlay_types
	var/list/cached_gases = air.gases
	var/list/gas_overlays = GLOB.gas_data.overlays
	var/list/gas_visibility = GLOB.gas_data.visibility
	for(var/gas_id as anything in cached_gases)
		if (nonoverlaying_gases[gas_id])
			continue
		var/gas_overlay = gas_overlays[gas_id]
		if(!gas_overlay)
			continue
		var/moles = cached_gases[gas_id]
		if(moles <= gas_visibility[gas_id])
			continue
		LAZYADD(new_overlay_types, gas_overlay[min(FACTOR_GAS_VISIBLE_MAX, CEILING(moles / MOLES_GAS_VISIBLE_STEP, 1))])

	if(!new_overlay_types && !atmos_overlay_types)
		return
	if(!new_overlay_types)
		new_overlay_types = list()

	if (atmos_overlay_types)
		for(var/overlay in atmos_overlay_types-new_overlay_types) //doesn't remove overlays that would only be added
			vis_contents -= overlay

	if (length(new_overlay_types))
		if (atmos_overlay_types)
			vis_contents += new_overlay_types - atmos_overlay_types //don't add overlays that already exist
		else
			vis_contents += new_overlay_types

	UNSETEMPTY(new_overlay_types)
	src.atmos_overlay_types = new_overlay_types

/turf/open/proc/set_visuals(list/new_overlay_types)
	if (atmos_overlay_types)
		for(var/overlay in atmos_overlay_types-new_overlay_types) //doesn't remove overlays that would only be added
			vis_contents -= overlay

	if (length(new_overlay_types))
		if (atmos_overlay_types)
			vis_contents += new_overlay_types - atmos_overlay_types //don't add overlays that already exist
		else
			vis_contents += new_overlay_types
	UNSETEMPTY(new_overlay_types)
	src.atmos_overlay_types = new_overlay_types

/proc/typecache_of_gases_with_no_overlays()
	. = list()
	for (var/gastype in subtypesof(/datum/gas))
		var/datum/gas/gasvar = gastype
		if (!initial(gasvar.gas_overlay))
			.[initial(gasvar.id)] = TRUE

/////////////////////////////SIMULATION///////////////////////////////////

// Significant gas movement also resets the receiving tile's stall counter and
// wakes it if it was resting: resting turfs stay in their excited group and
// receive gas passively, so anything meaningfully fed by a neighbor must come
// back to the active list to re-share (and, for planetary turfs, re-equalize
// with their template).
#define LAST_SHARE_CHECK \
	var/last_share = our_air.last_share; \
	if(last_share > our_suspend_threshold){ \
		our_excited_group.reset_cooldowns(); \
		cached_atmos_cooldown = 0; \
		enemy_tile.atmos_cooldown = 0; \
		if(!enemy_tile.excited && SSair){ \
			SSair.add_to_active(enemy_tile, FALSE); \
		} \
	} else if(last_share > our_move_threshold) { \
		our_excited_group.dismantle_cooldown = 0; \
		cached_atmos_cooldown = 0; \
		enemy_tile.atmos_cooldown = 0; \
		if(!enemy_tile.excited && SSair){ \
			SSair.add_to_active(enemy_tile, FALSE); \
		} \
	}

// Same cooldown handling for the template share; there is no enemy tile here.
#define PLANET_SHARE_CHECK \
	var/planet_last_share = our_air.last_share; \
	if(planet_last_share > our_suspend_threshold){ \
		our_excited_group.reset_cooldowns(); \
		cached_atmos_cooldown = 0; \
	} else if(planet_last_share > our_move_threshold) { \
		our_excited_group.dismantle_cooldown = 0; \
		cached_atmos_cooldown = 0; \
	}

/turf/proc/process_cell(fire_count)
	if(SSair)
		SSair.remove_from_active(src)
/turf/open/proc/equalize_pressure_in_zone(cyclenum)
	if(!SSair)
		return FALSE
	if(blocks_air || !air)
		return FALSE
	if(equalize_cycle >= cyclenum)
		return FALSE

	var/list/turf/open/zone_turfs = list()
	var/list/turf/open/space_edge_turfs = list()
	var/list/turf/open/pending = list(src)
	var/list/seen = list()
	seen[src] = TRUE

	var/pressure_high = air.return_pressure()
	var/pressure_low = pressure_high

	while(pending.len && zone_turfs.len < SSair.equalize_hard_turf_limit)
		var/turf/open/current_turf = pending[pending.len]
		pending.len--
		if(!istype(current_turf) || current_turf.blocks_air || !current_turf.air)
			continue
		if(current_turf.equalize_cycle >= cyclenum)
			continue

		current_turf.equalize_cycle = cyclenum
		zone_turfs += current_turf

		var/current_pressure = current_turf.air.return_pressure()
		pressure_high = max(pressure_high, current_pressure)
		pressure_low = min(pressure_low, current_pressure)

		for(var/turf/neighbor as anything in current_turf.atmos_adjacent_turfs)
			if(istype(neighbor, /turf/open/space))
				space_edge_turfs |= current_turf
				continue
			var/turf/open/open_neighbor = neighbor
			if(!istype(open_neighbor) || open_neighbor.blocks_air || !open_neighbor.air)
				continue
			if(seen[open_neighbor])
				continue
			seen[open_neighbor] = TRUE
			pending += open_neighbor

	if(!zone_turfs.len)
		return FALSE

	var/const/EQUALIZE_MIN_PRESSURE_DELTA = 5
	if((pressure_high - pressure_low) < EQUALIZE_MIN_PRESSURE_DELTA && !space_edge_turfs.len)
		return FALSE

	var/total_pressure_drop = 0
	for(var/turf/open/edge_turf as anything in space_edge_turfs)
		if(!edge_turf?.air)
			continue
		var/space_sides = 0
		var/turf/open/space/first_space
		for(var/turf/neighbor as anything in edge_turf.atmos_adjacent_turfs)
			if(!istype(neighbor, /turf/open/space))
				continue
			var/turf/open/space/space_neighbor = neighbor
			space_sides++
			if(!first_space)
				first_space = space_neighbor
			edge_turf.consider_firelocks(space_neighbor)
		if(!space_sides)
			continue

		var/starting_pressure = edge_turf.air.return_pressure()
		var/ratio = min(1, 0.25 * space_sides)
		edge_turf.air.vent_ratio(ratio)
		edge_turf.air.temperature_share(null, OPEN_HEAT_TRANSFER_COEFFICIENT, TCMB, HEAT_CAPACITY_VACUUM)

		var/pressure_drop = max(0, starting_pressure - edge_turf.air.return_pressure())
		total_pressure_drop += pressure_drop
		if(pressure_drop > 0 && first_space)
			edge_turf.consider_pressure_difference(first_space, pressure_drop)

	if(zone_turfs.len > 1)
		var/list/gas_list = list()
		for(var/turf/open/group_turf as anything in zone_turfs)
			if(group_turf.air)
				gas_list += group_turf.air
		equalize_all_gases_in_list(gas_list)

	for(var/turf/open/group_turf as anything in zone_turfs)
		if(!group_turf?.air)
			continue
		group_turf.update_visuals()
		if(SSair)
			SSair.add_to_active(group_turf, FALSE)

	if(total_pressure_drop > 0)
		for(var/turf/open/edge_turf as anything in space_edge_turfs)
			if(edge_turf)
				edge_turf.handle_decompression_floor_rip(total_pressure_drop)

	return TRUE

/turf/proc/consider_firelocks(turf/T2)
/turf/open/consider_firelocks(turf/T2)
	if(blocks_air)
		return
	for(var/obj/machinery/airalarm/alarm in src)
		alarm.handle_decomp_alarm()
	for(var/obj/machinery/door/firedoor/FD in src)
		FD.emergency_pressure_stop()
	for(var/obj/machinery/door/firedoor/FD in T2)
		FD.emergency_pressure_stop()

/turf/proc/handle_decompression_floor_rip()

/turf/open/floor/handle_decompression_floor_rip(sum)
	if(!blocks_air && sum > 20 && prob(clamp(sum / 10, 0, 30)))
		remove_tile()

/turf/open/process_cell(fire_count)
	if(blocks_air || !air)
		if(SSair)
			SSair.remove_from_active(src)
		return
	if(istype(src, /turf/open/space))
		if(SSair)
			SSair.remove_from_active(src)
		return

	if(archived_cycle < fire_count)
		archive()

	current_cycle = fire_count

	var/list/adjacent_turfs = atmos_adjacent_turfs
	if(!LAZYLEN(adjacent_turfs))
		// An active turf nothing can flow out of: either genuinely walled in,
		// or stranded by a blocking object that left (moved, lost density)
		// without an air update. Re-verify the adjacency - the queue dedupes,
		// and for genuinely sealed tiles the recalculation is four cheap
		// neighbor checks. Without this a stranded tile fed by a rotting
		// corpse hoards pressure forever.
		CALCULATE_ADJACENT_TURFS(src)
	var/datum/excited_group/our_excited_group = excited_group
	var/adjacent_turfs_length = max(1, LAZYLEN(adjacent_turfs))
	var/our_share_coeff = 1 / (adjacent_turfs_length + 1)
	var/cached_atmos_cooldown = atmos_cooldown + 1

	var/planet_atmos = planetary_atmos

	var/datum/gas_mixture/our_air = air
	// The share-significance defines are absolute moles calibrated for a
	// 104-mol standard cell. In a 400+ atm supply tank the same constants
	// read a 0.05% machinery ripple (dozens of moles) as "significant
	// movement" and kept whole engine rooms excited forever, because grouped
	// tiles share unconditionally and every share re-armed the cooldowns.
	// Scale the gates with tile content; at standard pressure the max()
	// resolves to the original constants. The scaled part must stay gentle
	// (1%, not the 10% the absolute define encodes at standard pressure):
	// canister-flood tiles hold thousands of moles, and gating their real
	// flows as insignificant lets breakdown average the flood flat mid-flow.
	var/our_cycle_moles = our_air.total_moles()
	var/our_suspend_threshold = max(MINIMUM_AIR_TO_SUSPEND, our_cycle_moles * SIGNIFICANT_SHARE_CONTENT_RATIO)
	var/our_move_threshold = max(MINIMUM_MOLES_DELTA_TO_MOVE, our_cycle_moles * MINIMUM_AIR_RATIO_TO_MOVE)

	for(var/turf/open/enemy_tile as anything in adjacent_turfs)
		if(!istype(enemy_tile) || enemy_tile.blocks_air)
			continue
		var/datum/gas_mixture/enemy_air = enemy_tile.air
		if(!enemy_air)
			continue

		// Space is represented by a shared immutable mix (the only turf air with
		// gc_share set), so vent explicitly instead of mutating it.
		if(enemy_air.gc_share)
			// A planetary turf never trades with space: the template refills
			// whatever the vacuum takes, so the pair is a perpetual vent/refill
			// pump that keeps the tile excited forever (space-ruin exteriors
			// mapped with planetary dirt: syndicate mothership, reactor ruin).
			// The sky wins - the tile just keeps its template air.
			if(planet_atmos)
				continue
			var/moles_before = our_air.total_moles()
			var/temperature_before = our_air.temperature
			if(moles_before <= MINIMUM_MOLES_DELTA_TO_MOVE && abs(temperature_before - TCMB) <= MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
				continue
			// Derive pressures from the known mole scaling instead of re-summing
			// the gas list through return_pressure().
			var/volume_cache = our_air.volume
			var/pressure_before = volume_cache > 0 ? (moles_before * R_IDEAL_GAS_EQUATION * temperature_before / volume_cache) : 0
			var/vent_everything = pressure_before < SPACE_DRAIN_FINISH_PRESSURE
			if(vent_everything)
				// Below survivable pressure the exponential bleed is pure churn:
				// space takes the rest in one pass and the tile leaves the drain
				// loop instead of asymptoting for tens of cycles. The emptied
				// tile matches space temperature too - a near-zero heat capacity
				// residue otherwise keeps paying temperature_share toward TCMB.
				our_air.vent_ratio(1)
				our_air.set_temperature(TCMB)
			else
				our_air.vent_ratio(our_share_coeff)
				if(abs(our_air.temperature - TCMB) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
					our_air.temperature_share(null, OPEN_HEAT_TRANSFER_COEFFICIENT, TCMB, HEAT_CAPACITY_VACUUM)
			// A turf draining to space must stay active until it is actually empty:
			// without a group the end-of-proc check deactivates a lone leaking turf
			// after one pass, freezing the leak mid-drain. Cooldown resets are gated
			// by the vented amount (mirroring LAST_SHARE_CHECK) so a residual
			// trickle stops pinning the whole group's breakdown/dismantle forever.
			if(!our_excited_group)
				var/datum/excited_group/space_group = new
				space_group.add_turf(src)
				our_excited_group = excited_group
			var/vented_moles = vent_everything ? moles_before : (moles_before * our_share_coeff)
			if(vented_moles > MINIMUM_AIR_TO_SUSPEND)
				our_excited_group.reset_cooldowns()
				cached_atmos_cooldown = 0
			else if(vented_moles > MINIMUM_MOLES_DELTA_TO_MOVE)
				our_excited_group.dismantle_cooldown = 0
				cached_atmos_cooldown = 0
			else if(pressure_before >= SPACE_DRAIN_FINISH_PRESSURE)
				// Vacuum exception (Baystation lesson): a superheated near-vacuum
				// tile (>=~10000K) holds survivable pressure on sub-0.1 mol content,
				// so both mole-gated resets above miss it and the tile would go to
				// sleep visibly pressurized against space. Pressure decays toward
				// the vent_everything threshold every cycle, so this cannot pin the
				// tile awake forever.
				// The GROUP lifecycle must be held off too: without this the
				// group's dismantle_cooldown keeps ticking and dismantle() pulls
				// the still-draining tile out of the active list mid-leak.
				our_excited_group.dismantle_cooldown = 0
				cached_atmos_cooldown = 0
			if(volume_cache > 0)
				var/pressure_after = vent_everything ? 0 : (moles_before * (1 - our_share_coeff) * R_IDEAL_GAS_EQUATION * our_air.temperature / volume_cache)
				var/pressure_delta_space = pressure_before - pressure_after
				if(pressure_delta_space > 0)
					consider_pressure_difference(enemy_tile, pressure_delta_space)
			continue

		// Two different skies meeting (lava shore, jungle river bank): both
		// tiles are anchored to their own template, so anything exchanged here
		// regenerates next cycle - an endless gradient that keeps whole surface
		// bands excited forever. Each side keeps its own sky; spilled gas still
		// leaves through the 0.8-ratio template pull within a couple of cycles.
		if(planet_atmos && enemy_tile.planetary_atmos && enemy_tile.initial_gas_mix != initial_gas_mix)
			continue

		if(fire_count <= enemy_tile.current_cycle)
			continue
		enemy_tile.archive()

		var/should_share_air = FALSE
		var/datum/excited_group/enemy_excited_group = enemy_tile.excited_group

		if(our_excited_group && enemy_excited_group)
			if(our_excited_group != enemy_excited_group)
				our_excited_group.merge_groups(enemy_excited_group)
				our_excited_group = excited_group
			should_share_air = TRUE
		else if(our_air.compare(enemy_air))
			if(!enemy_tile.excited && SSair)
				SSair.add_to_active(enemy_tile)
			var/datum/excited_group/EG = our_excited_group || enemy_excited_group || new
			if(!our_excited_group)
				EG.add_turf(src)
			if(!enemy_excited_group)
				EG.add_turf(enemy_tile)
			our_excited_group = excited_group
			should_share_air = TRUE

		if(should_share_air)
			var/enemy_share_coeff = 1 / (max(1, LAZYLEN(enemy_tile.atmos_adjacent_turfs)) + 1)
			var/difference = our_air.share(enemy_air, our_share_coeff, enemy_share_coeff)
			if(difference)
				if(difference > 0)
					consider_pressure_difference(enemy_tile, difference)
				else
					enemy_tile.consider_pressure_difference(src, -difference)
			LAST_SHARE_CHECK

	if(planet_atmos)
		var/datum/gas_mixture/template = SSair.get_planetary_template(src)
		if(our_air.compare(template))
			if(!our_excited_group)
				var/datum/excited_group/EG = new
				EG.add_turf(src)
				our_excited_group = excited_group
			// Neighbor shares above already moved gas this cycle: re-archive so
			// the template share works from current values. With the stale
			// cycle-start archive, an aggressive pull plus the neighbor shares
			// can overdraw the turf below the template.
			our_air.archive()
			our_air.share_with_template(template, PLANET_SHARE_RATIO)
			// Follow up with a conductive share against an inflated template
			// heat capacity (upstream behavior): pure temperature deltas are the
			// dominant planetary churn, and the weak in-share coupling alone
			// crawls toward the 4K suspend threshold for hundreds of cycles.
			our_air.temperature_share(null, OPEN_HEAT_TRANSFER_COEFFICIENT, template.temperature_archived, template.immutable_heat_capacity * PLANET_SHARE_TEMPERATURE_CAPACITY)
			PLANET_SHARE_CHECK

	var/reaction_result = our_air.react(src)

	// Feed the group lifecycle: a member with a live reaction or hotspot marks
	// the whole group so tick_lifecycle can hold off breakdown/dismantle
	// (averaging mid-burn smears the fire's heat across the group).
	if(our_excited_group)
		// Реакции сами возвращают VOLATILE_REACTION (нобиум, антинобиум,
		// фреоновое пламя) - бит доезжает сюда через OR в react().
		our_excited_group.turf_reactions |= reaction_result
		// Волатильным считается и generic combustion без хотспота (genericfire
		// пишет reaction_results["fire"], но hotspot не создаёт) - иначе
		// брейкдаун усреднит группу посреди такого горения.
		if(active_hotspot || ((reaction_result & REACTING) && our_air.reaction_results["fire"]))
			our_excited_group.turf_reactions |= VOLATILE_REACTION

	update_visuals()

	if(!active_hotspot && !(reaction_result & (REACTING | STOP_REACTIONS)))
		if(!our_excited_group)
			if(SSair)
				SSair.remove_from_active(src)
		else if(cached_atmos_cooldown > EXCITED_GROUP_INDIVIDUAL_REST_CYCLES)
			// Stalled for a full rest window inside a live group: rest this
			// turf alone. remove_from_active here would garbage-collect the whole
			// group, letting one churning member keep thousands of settled group
			// mates paying process_cell every fire. Resting early is safe: group
			// averaging keeps covering this turf, and anything meaningful wakes
			// it back through add_to_active or a boundary poke.
			if(SSair)
				SSair.sleep_active_turf(src)

	atmos_cooldown = cached_atmos_cooldown

//////////////////////////SPACEWIND/////////////////////////////

/turf/proc/consider_pressure_difference(turf/T, difference)
	return

/turf/open/consider_pressure_difference(turf/T, difference)
	SSair.high_pressure_delta |= src
	if(difference > pressure_difference)
		pressure_direction = get_dir(src, T)
		pressure_difference = difference

/turf/open/proc/high_pressure_movements()
	if(blocks_air)
		return
	var/multiplier = 1
	if(locate(/obj/structure/rack) in src)
		multiplier *= 0.1
	else if(locate(/obj/structure/table) in src)
		multiplier *= 0.2
	for(var/atom/movable/M as anything in contents.Copy())
		if(!M.anchored && !M.pulledby && M.last_high_pressure_movement_air_cycle < SSair.times_fired && (M.flags_1 & INITIALIZED_1) && !QDELETED(M))
			M.experience_pressure_difference(pressure_difference * multiplier, pressure_direction, 0, pressure_specific_target)

	if(pressure_difference > 100)
		new /obj/effect/temp_visual/dir_setting/space_wind(src, pressure_direction, clamp(round(sqrt(pressure_difference) * 2), 10, 255))

/atom/movable/var/pressure_resistance = 10
/atom/movable/var/last_high_pressure_movement_air_cycle = 0

/atom/movable/proc/experience_pressure_difference(pressure_difference, direction, pressure_resistance_prob_delta = 0, throw_target)
	var/const/PROBABILITY_OFFSET = 40
	var/const/PROBABILITY_BASE_PRECENT = 10
	var/max_force = sqrt(pressure_difference)*(MOVE_FORCE_DEFAULT / 5)
	set waitfor = 0
	var/move_prob = 100
	if (pressure_resistance > 0)
		move_prob = (pressure_difference/pressure_resistance*PROBABILITY_BASE_PRECENT)-PROBABILITY_OFFSET
	move_prob += pressure_resistance_prob_delta
	if (move_prob > PROBABILITY_OFFSET && prob(move_prob) && (move_resist != INFINITY) && (!anchored && (max_force >= (move_resist * MOVE_FORCE_PUSH_RATIO))) || (anchored && (max_force >= (move_resist * MOVE_FORCE_FORCEPUSH_RATIO))))
		var/move_force = max_force * clamp(move_prob, 0, 100) / 100
		if(ismob(src))
			var/mob/M = src
			if(M.mob_negates_gravity())
				move_force = 0
		if(move_force > 6000)
			// WALLSLAM HELL TIME OH BOY
			var/turf/throw_turf = get_ranged_target_turf(get_turf(src), direction, round(move_force / 2000))
			if(throw_target && (get_dir(src, throw_target) & direction))
				throw_turf = get_turf(throw_target)
			var/throw_speed = clamp(round(move_force / 3000), 1, 10)
			throw_at(throw_turf, move_force / 3000, throw_speed, quickstart = FALSE)
		else if(move_force > 0)
			step(src, direction)
		last_high_pressure_movement_air_cycle = SSair.times_fired

///////////////////////////EXCITED GROUPS/////////////////////////////

/datum/excited_group
	var/list/turf_list = list()
	var/breakdown_cooldown = 0
	var/dismantle_cooldown = 0
	/// Reaction flags OR-ed in by members during process_cell this air pass;
	/// consumed and reset by tick_lifecycle (tg turf_reactions port).
	var/turf_reactions = NO_REACTION
	/// Members currently excited. Maintained incrementally on every excited-flag
	/// transition and recounted exactly by self_breakdown, so the dismantle
	/// decision does not scan the whole turf_list every group-stage tick.
	var/awake_members = 0

/datum/excited_group/New()
	if(SSair)
		SSair.excited_groups += src

/datum/excited_group/proc/add_turf(turf/open/T)
	if(!istype(T))
		return
	// The turf leaves this proc awake: count it unless it is already an awake
	// member of this very group (re-adding one must not double count).
	if(T.excited_group != src || !T.excited)
		awake_members++
	turf_list |= T
	T.excited_group = src
	T.excited = TRUE
	reset_cooldowns()

/datum/excited_group/proc/merge_groups(datum/excited_group/E)
	if(!E || E == src)
		return
	// The loser keeps no state: its awake count moves to the winner, and its
	// turf_list empties so the dropped datum neither pins turf references nor
	// misjudges a lifecycle tick should anything still hold it.
	if(turf_list.len >= E.turf_list.len)
		if(SSair)
			SSair.excited_groups -= E
		for(var/turf/open/T as anything in E.turf_list)
			T.excited_group = src
			turf_list |= T
		awake_members += E.awake_members
		E.awake_members = 0
		turf_reactions |= E.turf_reactions // a burning group keeps its volatile gate through merges
		E.turf_list.Cut()
		reset_cooldowns()
	else
		if(SSair)
			SSair.excited_groups -= src
		for(var/turf/open/T as anything in turf_list)
			T.excited_group = E
			E.turf_list |= T
		E.awake_members += awake_members
		awake_members = 0
		turf_list.Cut()
		E.turf_reactions |= turf_reactions // a burning group keeps its volatile gate through merges
		E.reset_cooldowns()

/datum/excited_group/proc/reset_cooldowns()
	breakdown_cooldown = 0
	dismantle_cooldown = 0

/// One SSair group-stage step: advance both cooldowns and run whichever
/// lifecycle event is due. Kept as a proc so tests can drive the exact
/// stage behavior.
/datum/excited_group/proc/tick_lifecycle()
	// A group with no awake members can generate no new deltas on its own:
	// every member idled through a full rest window, and any external change
	// wakes its member back through add_to_active. Waiting out the rest of the
	// dismantle window would just keep re-averaging an already-quiet room.
	// The incremental counter replaces a full turf_list scan here - a permanent
	// O(N) per-fire tax once a perpetual group grows large. Drift from exotic
	// paths (turf type changes under a live group) only ever delays this
	// dismantle until self_breakdown recounts it exactly.
	if(awake_members <= 0)
		dismantle()
		return
	// A live fire on a member defers averaging (tg VOLATILE_REACTION gate):
	// breakdown mid-burn smears the hotspot's heat across the whole group and
	// can snuff or teleport the fire. A long burn still needs the settled-member
	// bookkeeping breakdown provides (giant-group churn control), so at the
	// ceiling we evict resting members WITHOUT averaging - the fire itself is
	// never touched (tg defers indefinitely; we only add the eviction).
	// Any reaction at all blocks dismantle.
	var/volatile_reaction = turf_reactions & VOLATILE_REACTION
	breakdown_cooldown++
	if(!volatile_reaction)
		dismantle_cooldown++
	if(breakdown_cooldown >= EXCITED_GROUP_BREAKDOWN_CYCLES)
		if(!volatile_reaction)
			self_breakdown(poke_resting = TRUE)
		else if(breakdown_cooldown >= EXCITED_GROUP_VOLATILE_BREAKDOWN_CEILING)
			evict_settled_members()
	else if(dismantle_cooldown >= EXCITED_GROUP_DISMANTLE_CYCLES && !(turf_reactions & (REACTING | STOP_REACTIONS)))
		dismantle()
	turf_reactions = NO_REACTION

/// Волатильный потолок: контроль роста turf_list без усреднения газа.
/// Вечное горение (горелка ТЭГ, плазменный пожар в коридоре) держит группу
/// живой бесконечно, а единственный штатный выход осевших членов из turf_list -
/// self_breakdown, который размазал бы топливо и жар по группе. Здесь осевшие
/// просто выселяются с их текущим газом: любой реальный будущий дельта-обмен
/// вернёт их через обычные share-пути. Заодно точный пересчёт awake_members
/// (самолечение дрейфа инкрементального счётчика, как в self_breakdown).
/datum/excited_group/proc/evict_settled_members()
	var/awake_recount = 0
	var/list/to_evict = list()
	for(var/turf/open/T as anything in turf_list)
		if(!istype(T))
			continue
		if(T.excited)
			awake_recount++
			continue
		to_evict += T
	awake_members = awake_recount
	for(var/turf/open/T as anything in to_evict)
		turf_list -= T
		if(T.excited_group == src)
			T.excited_group = null
	breakdown_cooldown = 0

/datum/excited_group/proc/self_breakdown(space_is_all_consuming = FALSE, poke_resting = FALSE)
	if(!length(turf_list))
		garbage_collect()
		return

	var/space_in_group = FALSE
	if(space_is_all_consuming)
		for(var/turf/open/T as anything in turf_list)
			if(!istype(T) || !T.air)
				continue
			if(istype(T.air, /datum/gas_mixture/immutable/space))
				space_in_group = TRUE
				break

	if(space_in_group)
		var/datum/gas_mixture/space_mix = new /datum/gas_mixture/immutable/space
		for(var/turf/open/T as anything in turf_list)
			if(!istype(T) || !T.air)
				continue
			T.air.copy_from(space_mix)
			T.update_visuals()
		qdel(space_mix)
	else
		// Average the ENTIRE group, resting members included, one atmosphere
		// domain at a time: planetary turfs bucket by their template string,
		// everything else shares the "" bucket. Excluding resting members
		// preserved every settled pocket, so post-breach fields flattened ring
		// by ring through the poke frontier (O(diameter^2) cycles of awake
		// churn for a large room) and drip-fed gas crawled out one ring per
		// breakdown. One pass here makes the bucket uniform: awake members
		// then find no deltas, rest within EXCITED_GROUP_INDIVIDUAL_REST_CYCLES
		// and the group dies, instead of the frontier staying awake for the
		// whole diffusive recovery. The O(group size) cost runs only once per
		// EXCITED_GROUP_BREAKDOWN_CYCLES and is far cheaper than the frontier
		// paying process_cell every fire.
		// Cross-template averaging is what kept whole planetary surfaces awake:
		// icemoon groups span 150K snow, 320K basalt caves and station-air
		// bridges, and one blended mix matches no template, so every planetary
		// member immediately re-shared with its own sky, re-armed the group
		// cooldowns, and the next breakdown re-polluted everyone - the surface
		// never slept and the active list grew without bound.
		var/list/bucket_mixes = list()
		var/list/bucket_counts = list()
		// This is the only place that already pays a full membership walk, so it
		// doubles as the exact recount for the incrementally-maintained awake
		// counter: any drift heals within EXCITED_GROUP_BREAKDOWN_CYCLES.
		var/awake_recount = 0
		for(var/turf/open/T as anything in turf_list)
			if(!istype(T))
				continue
			if(T.excited)
				awake_recount++
			if(!T.air)
				continue
			var/bucket_key = T.planetary_atmos ? T.initial_gas_mix : ""
			var/datum/gas_mixture/bucket_mix = bucket_mixes[bucket_key]
			if(!bucket_mix)
				bucket_mix = new
				bucket_mixes[bucket_key] = bucket_mix
			bucket_mix.merge(T.air)
			bucket_counts[bucket_key]++
		awake_members = awake_recount
		for(var/bucket_key in bucket_mixes)
			var/datum/gas_mixture/bucket_mix = bucket_mixes[bucket_key]
			bucket_mix.divide(bucket_counts[bucket_key])
		var/list/to_evict = list()
		for(var/turf/open/T as anything in turf_list)
			if(!istype(T) || !T.air)
				continue
			var/bucket_key = T.planetary_atmos ? T.initial_gas_mix : ""
			var/datum/gas_mixture/bucket_mix = bucket_mixes[bucket_key]
			// The write-back changes air on tiles that stay resting, so their
			// registered vents/scrubbers must get their wake call here - the
			// turf itself never goes through add_to_active. Gate it on the same
			// significance check turf shares use: perpetual groups (freezer
			// rooms, engine storages) break down every
			// EXCITED_GROUP_BREAKDOWN_CYCLES fires while a machine needs
			// ATMOS_MACHINE_IDLE_STREAK no-op fires to rest, so an
			// unconditional wake pinned every machine in such a room awake
			// forever (and their pumping re-broadcast through pipenet wakes).
			var/air_changed = T.air.compare(bucket_mix)
			T.air.copy_from(bucket_mix)
			T.update_visuals()
			if(air_changed)
				if(T.atmos_wake_machines)
					for(var/obj/machinery/atmospherics/machine as anything in T.atmos_wake_machines)
						machine.atmos_wake()
			else if(!T.excited)
				// A resting member the breakdown did not change sits exactly at
				// the bucket average: it contributes nothing and receives
				// nothing, yet stays on the books forever - a turf has no other
				// way out of turf_list while the group lives, so perpetual
				// groups (planetary surfaces around a leak, space-edge drains)
				// accumulate tens of thousands of settled members and every
				// breakdown re-averages all of them in one atomic unyieldable
				// pass. Evict it: any real future delta re-adds it through the
				// normal share paths, and the final copy_from above already ran
				// so the bucket mass stays conserved.
				to_evict += T
		for(var/turf/open/T as anything in to_evict)
			turf_list -= T
			if(T.excited_group == src)
				T.excited_group = null
		for(var/bucket_key in bucket_mixes)
			qdel(bucket_mixes[bucket_key])

	if(poke_resting)
		// With the whole group averaged flat, the only place new deltas can
		// come from is OUTSIDE the group: wake resting members that border a
		// non-member open turf so they compare against it next cycle (that
		// comparison is the only way the group grows into a settled room or
		// keeps draining into space). They get a maxed stall budget - share
		// something or rest right back. Interior resting members already sit
		// at the bucket average and stay asleep; a fully-enclosed room stops
		// poking entirely once the group covers it.
		var/list/turf/open/to_poke = list()
		for(var/turf/open/T as anything in turf_list)
			if(!istype(T) || !T.air || T.excited)
				continue
			for(var/turf/open/neighbor as anything in T.atmos_adjacent_turfs)
				if(!istype(neighbor) || neighbor.excited_group == src)
					continue
				to_poke += T
				break
		for(var/turf/open/T as anything in to_poke)
			if(SSair)
				// A poke does not change the tile's air - room perimeters are
				// exactly where vents/scrubbers stand, and waking them on
				// every poke of a perpetual group pinned them awake forever.
				SSair.add_to_active(T, FALSE, wake_machines = FALSE)
			T.atmos_cooldown = EXCITED_GROUP_INDIVIDUAL_REST_CYCLES

	breakdown_cooldown = 0

/datum/excited_group/proc/dismantle()
	for(var/turf/open/T as anything in turf_list)
		if(!istype(T))
			continue
		T.excited = FALSE
		// Upstream parity: a dismantled turf must not carry its stall counter
		// into the next activation, or it rests again after a single cycle.
		T.atmos_cooldown = 0
		T.excited_group = null
		if(SSair)
			SSair.active_turfs -= T
	garbage_collect()

/datum/excited_group/proc/garbage_collect()
	for(var/turf/open/T as anything in turf_list)
		if(istype(T))
			T.excited_group = null
	turf_list.Cut()
	awake_members = 0
	if(SSair)
		SSair.excited_groups -= src

#undef LAST_SHARE_CHECK
#undef PLANET_SHARE_CHECK
