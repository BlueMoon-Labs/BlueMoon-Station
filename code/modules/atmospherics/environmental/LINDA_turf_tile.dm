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
		var/datum/gas_mixture/removed = giver.remove(moles)
		if(!removed || removed.total_moles() <= 0)
			if(removed)
				qdel(removed)
			return FALSE
		qdel(removed)
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
		var/datum/gas_mixture/removed = giver.remove_ratio(ratio)
		if(!removed || removed.total_moles() <= 0)
			if(removed)
				qdel(removed)
			return FALSE
		qdel(removed)
	else if(!giver.transfer_ratio_to(air, ratio))
		return FALSE
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return TRUE

/turf/open/transfer_air(datum/gas_mixture/taker, moles)
	if(!taker || !return_air()) // shouldn't transfer from space
		return FALSE
	air.transfer_to(taker, moles)
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return TRUE

/turf/open/transfer_air_ratio(datum/gas_mixture/taker, ratio)
	if(!taker || !return_air())
		return FALSE
	air.transfer_ratio_to(taker, ratio)
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
	var/list/new_overlay_types = list()
	var/static/list/nonoverlaying_gases = typecache_of_gases_with_no_overlays()

	if(!air) // 2019-05-14: was not able to get this path to fire in testing. Consider removing/looking at callers -Naksu
		if (atmos_overlay_types)
			for(var/overlay in atmos_overlay_types)
				vis_contents -= overlay
			src.atmos_overlay_types = null
		return


	for(var/id in air.get_gases())
		if (nonoverlaying_gases[id])
			continue
		var/gas_overlay = GLOB.gas_data.overlays[id]
		if(gas_overlay && air.get_moles(id) > GLOB.gas_data.visibility[id])
			new_overlay_types += gas_overlay[min(FACTOR_GAS_VISIBLE_MAX, CEILING(air.get_moles(id) / MOLES_GAS_VISIBLE_STEP, 1))]

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

#define LAST_SHARE_CHECK \
	var/last_share = our_air.last_share; \
	if(last_share > MINIMUM_AIR_TO_SUSPEND){ \
		our_excited_group.reset_cooldowns(); \
		cached_atmos_cooldown = 0; \
	} else if(last_share > MINIMUM_MOLES_DELTA_TO_MOVE) { \
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
		var/datum/gas_mixture/released = edge_turf.air.remove_ratio(ratio)
		if(released)
			qdel(released)
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
	var/datum/excited_group/our_excited_group = excited_group
	var/adjacent_turfs_length = max(1, LAZYLEN(adjacent_turfs))
	var/our_share_coeff = 1 / (adjacent_turfs_length + 1)
	var/cached_atmos_cooldown = atmos_cooldown + 1

	var/planet_atmos = planetary_atmos
	if(planet_atmos)
		adjacent_turfs_length++

	var/datum/gas_mixture/our_air = air

	for(var/turf/open/enemy_tile as anything in adjacent_turfs)
		if(!istype(enemy_tile) || enemy_tile.blocks_air || !enemy_tile.air)
			continue

		// Space is represented by a shared immutable mix, so vent explicitly instead of mutating it.
		if(istype(enemy_tile, /turf/open/space))
			var/moles_before = our_air.total_moles()
			var/temperature_before = our_air.return_temperature()
			if(moles_before <= MINIMUM_MOLES_DELTA_TO_MOVE && abs(temperature_before - TCMB) <= MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
				continue
			var/pressure_before = our_air.return_pressure()
			var/datum/gas_mixture/vented = our_air.remove_ratio(our_share_coeff)
			if(vented)
				qdel(vented)
			if(abs(our_air.return_temperature() - TCMB) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
				our_air.temperature_share(null, OPEN_HEAT_TRANSFER_COEFFICIENT, TCMB, HEAT_CAPACITY_VACUUM)
			var/pressure_delta_space = pressure_before - our_air.return_pressure()
			if(pressure_delta_space > 0)
				consider_pressure_difference(enemy_tile, pressure_delta_space)
			continue

		if(fire_count <= enemy_tile.current_cycle)
			continue
		enemy_tile.archive()

		var/should_share_air = FALSE
		var/datum/gas_mixture/enemy_air = enemy_tile.air
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
		var/datum/gas_mixture/G = new
		G.copy_from_turf(src)
		G.archive()
		if(our_air.compare(G))
			if(!our_excited_group)
				var/datum/excited_group/EG = new
				EG.add_turf(src)
				our_excited_group = excited_group
			our_air.share(G, our_share_coeff, our_share_coeff)
			LAST_SHARE_CHECK
		qdel(G)

	var/reaction_result = our_air.react(src)

	update_visuals()

	if((!our_excited_group && !active_hotspot && !(reaction_result & (REACTING | STOP_REACTIONS))) \
	  || (cached_atmos_cooldown > (EXCITED_GROUP_DISMANTLE_CYCLES * 2)))
		if(SSair)
			SSair.remove_from_active(src)

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

/datum/excited_group/New()
	if(SSair)
		SSair.excited_groups += src

/datum/excited_group/proc/add_turf(turf/open/T)
	if(!istype(T))
		return
	turf_list |= T
	T.excited_group = src
	T.excited = TRUE
	reset_cooldowns()

/datum/excited_group/proc/merge_groups(datum/excited_group/E)
	if(!E || E == src)
		return
	if(turf_list.len >= E.turf_list.len)
		if(SSair)
			SSair.excited_groups -= E
		for(var/turf/open/T as anything in E.turf_list)
			T.excited_group = src
			turf_list |= T
		reset_cooldowns()
	else
		if(SSair)
			SSair.excited_groups -= src
		for(var/turf/open/T as anything in turf_list)
			T.excited_group = E
			E.turf_list |= T
		E.reset_cooldowns()

/datum/excited_group/proc/reset_cooldowns()
	breakdown_cooldown = 0
	dismantle_cooldown = 0

/datum/excited_group/proc/self_breakdown(space_is_all_consuming = FALSE)
	if(!length(turf_list))
		garbage_collect()
		return

	var/datum/gas_mixture/A = new
	var/turflen = 0
	var/space_in_group = FALSE

	for(var/turf/open/T as anything in turf_list)
		if(!istype(T) || !T.air)
			continue
		if(space_is_all_consuming && !space_in_group && istype(T.air, /datum/gas_mixture/immutable/space))
			space_in_group = TRUE
			qdel(A)
			A = new /datum/gas_mixture/immutable/space
			break
		A.merge(T.air)
		turflen++

	if(!space_in_group && turflen > 0)
		A.divide(turflen)

	for(var/turf/open/T as anything in turf_list)
		if(!istype(T) || !T.air)
			continue
		T.air.copy_from(A)
		T.atmos_cooldown = 0
		T.update_visuals()

	breakdown_cooldown = 0
	qdel(A)

/datum/excited_group/proc/dismantle()
	for(var/turf/open/T as anything in turf_list)
		if(!istype(T))
			continue
		T.excited = FALSE
		T.excited_group = null
		if(SSair)
			SSair.active_turfs -= T
	garbage_collect()

/datum/excited_group/proc/garbage_collect()
	for(var/turf/open/T as anything in turf_list)
		if(istype(T))
			T.excited_group = null
	turf_list.Cut()
	if(SSair)
		SSair.excited_groups -= src

#undef LAST_SHARE_CHECK
