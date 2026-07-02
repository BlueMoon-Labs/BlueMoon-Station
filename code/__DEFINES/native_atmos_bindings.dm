// Атмосфера на DM (газ в gas_mixture.gases, реакции в react(), без Auxmos).

// Подсистема и глобальные заглушки
/datum/controller/subsystem/air
	/// Open turfs that participate in native DM atmos processing.
	var/list/turf/open/dm_registered_turfs = list()
	/// Turfs currently participating in active atmos processing.
	var/list/turf/open/active_turfs = list()
	/// Groups of turfs with active gas exchange.
	var/list/datum/excited_group/excited_groups = list()
	/// Deferred callbacks that used to be serviced by auxmos.
	var/list/datum/callback/dm_atmos_callbacks = list()
	/// Number of currently alive gas mixtures (for stat panel parity).
	var/dm_registered_gas_mixtures = 0
	/// Maximum number of simultaneously alive gas mixtures.
	var/dm_max_registered_gas_mixtures = 0

/datum/controller/subsystem/air/proc/get_max_gas_mixes()
	return dm_max_registered_gas_mixtures

/datum/controller/subsystem/air/proc/get_amt_gas_mixes()
	return dm_registered_gas_mixtures

/proc/equalize_all_gases_in_list(gas_list)
	if(!length(gas_list))
		return
	var/datum/gas_mixture/total = new
	var/list/datum/gas_mixture/participating = list()
	var/total_volume = 0
	for(var/datum/gas_mixture/G in gas_list)
		if(G && !G.gc_share)
			total.merge(G)
			participating += G
			total_volume += max(G.return_volume(), 0)
	if(!length(participating))
		qdel(total)
		return
	if(total_volume <= 0)
		qdel(total)
		return
	var/target_temperature = total.return_temperature()
	var/list/total_gases = total.gases
	for(var/datum/gas_mixture/G in participating)
		var/volume_ratio = G.return_volume() / total_volume
		G.clear()
		for(var/id in total_gases)
			var/moles = (total_gases[id] || 0) * volume_ratio
			if(moles > 0)
				G.gases[id] = moles
		G.set_temperature(target_temperature)
	qdel(total)

/datum/controller/subsystem/air/proc/process_turf_equalize_auxtools(remaining)
	if(!equalize_enabled)
		num_equalize_processed = 0
		return FALSE
	if(!length(currentrun))
		currentrun = active_turfs.Copy()
		num_equalize_processed = 0
		high_pressure_turfs = 0
		low_pressure_turfs = 0
	var/list/currentrun_copy = currentrun
	var/fire_count = times_fired
	while(currentrun_copy.len)
		var/turf/open/T = currentrun_copy[currentrun_copy.len]
		currentrun_copy.len--
		if(!istype(T) || T.blocks_air || !T.air)
			active_turfs -= T
			dm_registered_turfs -= T
			continue
		var/pressure = T.air.return_pressure()
		var/max_adjacent_delta = 0
		var/has_space_neighbor = FALSE
		for(var/turf/adjacent as anything in T.atmos_adjacent_turfs)
			if(istype(adjacent, /turf/open/space))
				has_space_neighbor = TRUE
				continue
			var/turf/open/open_adjacent = adjacent
			if(!istype(open_adjacent) || open_adjacent.blocks_air || !open_adjacent.air)
				continue
			max_adjacent_delta = max(max_adjacent_delta, abs(pressure - open_adjacent.air.return_pressure()))
		if(has_space_neighbor || max_adjacent_delta >= 5)
			if(T.equalize_pressure_in_zone(fire_count))
				num_equalize_processed++
				if(pressure >= ONE_ATMOSPHERE)
					high_pressure_turfs++
				else
					low_pressure_turfs++
		if(world.tick_usage > Master.current_ticklimit)
			pause()
			return TRUE
	// Do not leak equalize runlist into the next SSAIR stage.
	// The subsystem uses a shared `currentrun` slot, and leaving turf entries here
	// makes the excited-group stage treat turfs as groups.
	currentrun = list()
	return FALSE

/datum/controller/subsystem/air/proc/process_excited_groups_auxtools(remaining)
	if(!length(currentrun))
		currentrun = excited_groups.Copy()
		num_group_turfs_processed = 0
	var/list/currentrun_copy = currentrun
	while(currentrun_copy.len)
		var/datum/excited_group/EG = currentrun_copy[currentrun_copy.len]
		currentrun_copy.len--
		if(!EG)
			continue
		num_group_turfs_processed += length(EG.turf_list)
		EG.breakdown_cooldown++
		EG.dismantle_cooldown++
		if(EG.breakdown_cooldown >= EXCITED_GROUP_BREAKDOWN_CYCLES)
			EG.self_breakdown()
		else if(EG.dismantle_cooldown >= EXCITED_GROUP_DISMANTLE_CYCLES)
			EG.dismantle()
		if(world.tick_usage > Master.current_ticklimit)
			pause()
			return TRUE
	return FALSE

/datum/controller/subsystem/air/proc/process_turfs_auxtools(remaining)
	if(!length(currentrun))
		currentrun = active_turfs.Copy()
	var/fire_count = times_fired
	var/list/currentrun_copy = currentrun
	while(currentrun_copy.len)
		var/turf/open/T = currentrun_copy[currentrun_copy.len]
		currentrun_copy.len--
		if(!istype(T) || T.blocks_air || !T.air)
			active_turfs -= T
			dm_registered_turfs -= T
			continue
		T.process_cell(fire_count)
		if(world.tick_usage > Master.current_ticklimit)
			pause()
			return TRUE
	return FALSE

/datum/controller/subsystem/air/proc/finish_turf_processing_auxtools(time_remaining)
	if(!length(currentrun))
		currentrun = active_turfs.Copy()
	var/list/currentrun_copy = currentrun
	while(currentrun_copy.len)
		var/turf/open/T = currentrun_copy[currentrun_copy.len]
		currentrun_copy.len--
		if(!istype(T) || T.blocks_air || !T.air)
			active_turfs -= T
			dm_registered_turfs -= T
			continue
		if(T.excited_group || T.active_hotspot || T.planetary_atmos)
			continue
		var/current_pressure = T.air.return_pressure()
		var/current_moles = T.air.total_moles()
		if(current_moles <= MINIMUM_MOLES_DELTA_TO_MOVE && current_pressure <= (ONE_ATMOSPHERE * 0.05))
			sleep_active_turf(T)
		if(world.tick_usage > Master.current_ticklimit)
			pause()
			return TRUE
	return FALSE

/datum/controller/subsystem/air/proc/remove_from_active(turf/open/T)
	active_turfs -= T
	if(istype(T))
		T.excited = FALSE
		if(T.excited_group)
			T.excited_group.garbage_collect()

/datum/controller/subsystem/air/proc/add_to_active(turf/open/T, blockchanges = TRUE)
	if(!istype(T) || T.blocks_air || !T.air)
		return
	T.excited = TRUE
	active_turfs |= T
	if(blockchanges && T.excited_group)
		T.excited_group.garbage_collect()

/datum/controller/subsystem/air/proc/sleep_active_turf(turf/open/T)
	active_turfs -= T

/datum/controller/subsystem/air/proc/thread_running()
	return FALSE

/proc/finalize_gas_refs()
	return

/datum/controller/subsystem/air/proc/auxtools_update_reactions()
	return

/proc/auxtools_atmos_init(gas_data)
	return TRUE

/proc/_auxtools_register_gas(gas)
	return

/proc/process_atmos_callbacks(remaining)
	if(!SSair || !length(SSair.dm_atmos_callbacks))
		return FALSE
	while(SSair.dm_atmos_callbacks.len)
		var/datum/callback/CB = SSair.dm_atmos_callbacks[1]
		SSair.dm_atmos_callbacks.Cut(1, 2)
		if(CB)
			CB.Invoke()
		if(world.tick_usage > Master.current_ticklimit)
			return TRUE
	return FALSE

/turf/proc/__update_auxtools_turf_adjacency_info()
	if(!SSair || !istype(src, /turf/open))
		return
	var/turf/open/open_turf = src
	if(open_turf.blocks_air || !open_turf.air)
		SSair.remove_from_active(open_turf)
		return
	// During world bootstrap adjacency is recalculated for every open turf; waking all of them
	// at once causes massive active-list churn and slows perceived flow dramatically.
	if(!SSair.initialized)
		return
	SSair.add_to_active(open_turf, FALSE)

/turf/proc/update_air_ref(flag)
	if(!SSair)
		return
	if(!istype(src, /turf/open))
		SSair.dm_registered_turfs -= src
		return
	var/turf/open/open_turf = src
	if(flag == -1 || flag == 0 || open_turf.blocks_air || !open_turf.air)
		SSair.dm_registered_turfs -= open_turf
		SSair.remove_from_active(open_turf)
	else
		SSair.dm_registered_turfs |= open_turf
		if((flag & AIR_REF_PLANETARY_TURF) && !istype(open_turf, /turf/open/space))
			SSair.add_to_active(open_turf, FALSE)

/proc/_dm_atmos_should_process_pair(turf/open/source, turf/open/target)
	if(!source || !target || source == target)
		return FALSE
	if(source.z != target.z)
		return source.z < target.z
	if(source.y != target.y)
		return source.y < target.y
	return source.x < target.x

/datum/gas_mixture/proc/__gasmixture_register()
	if(dm_registered_to_ssair || !SSair)
		return FALSE
	dm_registered_to_ssair = TRUE
	SSair.dm_registered_gas_mixtures++
	SSair.dm_max_registered_gas_mixtures = max(SSair.dm_max_registered_gas_mixtures, SSair.dm_registered_gas_mixtures)
	return TRUE

/datum/gas_mixture/proc/__gasmixture_unregister()
	if(!dm_registered_to_ssair || !SSair)
		return FALSE
	dm_registered_to_ssair = FALSE
	SSair.dm_registered_gas_mixtures = max(0, SSair.dm_registered_gas_mixtures - 1)
	return TRUE

/datum/gas_mixture/proc/__auxtools_parse_gas_string(string)
	return parse_gas_string(string)

// gas_mixture: хранение в gases[gas_id] = moles, temperature, volume
/datum/gas_mixture/proc/get_moles(gas_id)
	return gases[gas_id] || 0

/datum/gas_mixture/proc/set_moles(gas_id, amt_val)
	if(gc_share)
		return FALSE
	gases[gas_id] = max(0, amt_val)
	return TRUE

/datum/gas_mixture/proc/adjust_moles(id_val, num_val)
	if(gc_share)
		return FALSE
	set_moles(id_val, get_moles(id_val) + num_val)
	return TRUE

/datum/gas_mixture/proc/return_temperature()
	return temperature

/datum/gas_mixture/proc/set_temperature(arg_temp)
	if(gc_share)
		return FALSE
	temperature = max(arg_temp, TCMB)
	return TRUE

/datum/gas_mixture/proc/return_volume()
	return max(0, volume)

/datum/gas_mixture/proc/set_volume(vol_arg)
	if(gc_share)
		return FALSE
	volume = max(0, vol_arg)
	return TRUE

/datum/gas_mixture/proc/total_moles()
	. = 0
	for(var/id in gases)
		. += gases[id]

/datum/gas_mixture/proc/heat_capacity()
	. = 0
	var/list/cached_gasheats = GLOB.gas_data.specific_heats
	for(var/id in gases)
		. += (gases[id] || 0) * (cached_gasheats[id] || 0)
	. = max(., min_heat_capacity)

/datum/gas_mixture/proc/thermal_energy()
	return temperature * heat_capacity()

/datum/gas_mixture/proc/return_pressure()
	if(volume <= 0)
		return 0
	return total_moles() * R_IDEAL_GAS_EQUATION * temperature / volume

/datum/gas_mixture/proc/clear()
	if(gc_share)
		return FALSE
	gases.Cut()
	return TRUE

/datum/gas_mixture/proc/archive()
	temperature_archived = temperature
	gas_archive = gases.Copy()
	return TRUE

/datum/gas_mixture/proc/get_gases()
	return gases

/datum/gas_mixture/proc/merge(datum/gas_mixture/giver)
	if(gc_share || !giver)
		return FALSE
	if(abs(temperature - giver.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = heat_capacity()
		var/giver_heat_capacity = giver.heat_capacity()
		var/combined_heat_capacity = giver_heat_capacity + self_heat_capacity
		if(combined_heat_capacity > 0)
			temperature = (giver.temperature * giver_heat_capacity + temperature * self_heat_capacity) / combined_heat_capacity
	for(var/giver_id in giver.gases)
		gases[giver_id] = (gases[giver_id] || 0) + (giver.gases[giver_id] || 0)
	return TRUE

/datum/gas_mixture/proc/copy_from(datum/gas_mixture/giver)
	if(gc_share || !giver)
		return FALSE
	gases.Cut()
	for(var/id in giver.gases)
		gases[id] = giver.gases[id]
	temperature = giver.temperature
	return TRUE

/datum/gas_mixture/proc/archived_heat_capacity()
	. = 0
	var/list/cached_gasheats = GLOB.gas_data.specific_heats
	var/list/archive = gas_archive || gases
	for(var/id in archive)
		. += (archive[id] || 0) * (cached_gasheats[id] || 0)
	. = max(., min_heat_capacity)

/datum/gas_mixture/proc/__remove(datum/gas_mixture/into, amount_arg)
	if(gc_share)
		return
	var/sum = total_moles()
	amount_arg = min(amount_arg, sum)
	if(amount_arg <= 0)
		return
	var/ratio = sum > 0 ? amount_arg / sum : 0
	into.temperature = temperature
	if(!into.gases)
		into.gases = list()
	for(var/id in gases)
		var/amt = (gases[id] || 0) * ratio
		if(amt > 0)
			into.gases[id] = (into.gases[id] || 0) + amt
			gases[id] = (gases[id] || 0) - amt
	GAS_GARBAGE_COLLECT(gases)

/datum/gas_mixture/proc/__remove_ratio(into, ratio_arg)
	if(gc_share)
		return
	ratio_arg = clamp(ratio_arg, 0, 1)
	__remove(into, total_moles() * ratio_arg)

/datum/gas_mixture/proc/transfer_to(datum/gas_mixture/other, moles)
	if(gc_share || !other || other.gc_share)
		return FALSE
	var/datum/gas_mixture/removed = new type(volume)
	__remove(removed, moles)
	other.merge(removed)
	qdel(removed)
	return TRUE

/datum/gas_mixture/proc/get_oxidation_power(temp)
	if(isnull(temp))
		temp = return_temperature()
	. = 0
	var/list/oxidation_temps = GLOB.gas_data.oxidation_temperatures
	var/list/oxidation_rates = GLOB.gas_data.oxidation_rates
	for(var/id in gases)
		var/t_ox = oxidation_temps[id]
		if(t_ox && temp >= t_ox)
			var/temperature_scale = max(0, 1 - (t_ox / max(temp, TCMB)))
			. += (gases[id] || 0) * (oxidation_rates[id] || 0) * temperature_scale
	return .

/datum/gas_mixture/proc/get_fuel_amount(temp)
	if(isnull(temp))
		temp = return_temperature()
	. = 0
	var/list/fuel_temps = GLOB.gas_data.fire_temperatures
	var/list/fuel_rates = GLOB.gas_data.fire_burn_rates
	for(var/id in gases)
		var/t_f = fuel_temps[id]
		if(t_f && temp >= t_f)
			var/temperature_scale = max(0, 1 - (t_f / max(temp, TCMB)))
			. += ((gases[id] || 0) / max(fuel_rates[id], 0.01)) * temperature_scale
	return .

/datum/gas_mixture/proc/equalize_with(datum/gas_mixture/total)
	if(gc_share || !total)
		return
	var/total_vol = volume + total.volume
	if(total_vol <= 0)
		return
	var/self_heat = heat_capacity()
	var/other_heat = total.heat_capacity()
	if(self_heat + other_heat > 0)
		temperature = (temperature * self_heat + total.temperature * other_heat) / (self_heat + other_heat)
		total.temperature = temperature
	for(var/id in gases | total.gases)
		var/our_m = gases[id] || 0
		var/their_m = total.gases[id] || 0
		var/combined = our_m + their_m
		gases[id] = combined * volume / total_vol
		total.gases[id] = combined * total.volume / total_vol

/datum/gas_mixture/proc/transfer_ratio_to(datum/gas_mixture/other, ratio)
	if(gc_share || !other || other.gc_share)
		return FALSE
	var/datum/gas_mixture/removed = new type(volume)
	__remove_ratio(removed, ratio)
	other.merge(removed)
	qdel(removed)
	return TRUE

/datum/gas_mixture/proc/adjust_heat(heat)
	if(gc_share)
		return FALSE
	var/cap = heat_capacity()
	if(cap > MINIMUM_HEAT_CAPACITY)
		set_temperature(temperature + heat / cap)
	return TRUE

/datum/gas_mixture/proc/compare(datum/gas_mixture/other)
	if(!other)
		return "invalid"
	for(var/id in gases | other.gases)
		var/gas_moles = gases[id] || 0
		var/other_moles = other.gases[id] || 0
		var/delta = abs(gas_moles - other_moles)
		if(delta > MINIMUM_MOLES_DELTA_TO_MOVE)
			if(delta > gas_moles * MINIMUM_AIR_RATIO_TO_MOVE)
				return id
	var/our_moles = total_moles()
	if(our_moles > MINIMUM_MOLES_DELTA_TO_MOVE)
		if(abs(temperature - other.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND)
			return "temp"
	return ""

/datum/gas_mixture/proc/mark_immutable()
	gc_share = TRUE
	return TRUE

/datum/gas_mixture/proc/scrub_into(datum/gas_mixture/into, ratio_v, list/gas_list)
	if(gc_share || !into || into.gc_share)
		return FALSE
	ratio_v = clamp(ratio_v, 0, 1)
	if(ratio_v <= 0 || !length(gas_list))
		return FALSE
	var/datum/gas_mixture/removed = new type(volume)
	removed.temperature = temperature
	for(var/gid in gas_list)
		var/current_moles = gases[gid] || 0
		if(current_moles <= 0)
			continue
		var/m = current_moles * ratio_v
		if(m > 0)
			removed.gases[gid] = (removed.gases[gid] || 0) + m
			gases[gid] = current_moles - m
	GAS_GARBAGE_COLLECT(gases)
	into.merge(removed)
	qdel(removed)
	return TRUE

/datum/gas_mixture/proc/get_by_flag(flag_val)
	. = list()
	var/list/flags = GLOB.gas_data.flags
	for(var/id in gases)
		if(flags[id] & flag_val)
			.[id] = gases[id]

/datum/gas_mixture/proc/__remove_by_flag(datum/gas_mixture/into, flag_val, amount_val)
	if(gc_share)
		return
	var/list/with_flag = get_by_flag(flag_val)
	var/sum = 0
	for(var/id in with_flag)
		sum += with_flag[id]
	if(sum <= 0)
		return
	var/ratio = min(1, amount_val / sum)
	into.temperature = temperature
	for(var/id in with_flag)
		var/amt = with_flag[id] * ratio
		if(amt > 0)
			into.gases[id] = (into.gases[id] || 0) + amt
			gases[id] = (gases[id] || 0) - amt
	GAS_GARBAGE_COLLECT(gases)

/datum/gas_mixture/proc/divide(num_val)
	if(gc_share)
		return FALSE
	if(num_val <= 0)
		return FALSE
	for(var/id in gases)
		gases[id] /= num_val
	return TRUE

/datum/gas_mixture/proc/multiply(num_val)
	if(gc_share)
		return FALSE
	for(var/id in gases)
		gases[id] *= num_val
	return TRUE

/datum/gas_mixture/proc/subtract(num_val)
	if(gc_share)
		return FALSE
	for(var/id in gases)
		gases[id] = max(0, (gases[id] || 0) - num_val)
	return TRUE

/datum/gas_mixture/proc/add(num_val)
	if(gc_share)
		return FALSE
	for(var/id in gases)
		gases[id] = (gases[id] || 0) + num_val
	return TRUE

/datum/gas_mixture/proc/adjust_multi(...)
	if(gc_share)
		return FALSE
	var/list/arglist = args
	for(var/i in 2 to length(arglist))
		var/list/elem = arglist[i]
		if(length(elem) >= 2)
			adjust_moles(elem[1], elem[2])
	return TRUE

/datum/gas_mixture/proc/adjust_moles_temp(id_val, num_val, temp_val)
	if(gc_share)
		return FALSE
	adjust_moles(id_val, num_val)
	if(num_val != 0 && total_moles() > 0)
		var/cap = heat_capacity()
		if(cap > MINIMUM_HEAT_CAPACITY)
			var/list/cached_gasheats = GLOB.gas_data.specific_heats
			var/delta_heat = num_val * (cached_gasheats[id_val] || 0) * temp_val
			temperature = (temperature * cap + delta_heat) / heat_capacity()
	return TRUE

/datum/gas_mixture/proc/partial_heat_capacity(gas_id)
	var/list/cached_gasheats = GLOB.gas_data.specific_heats
	return (gases[gas_id] || 0) * (cached_gasheats[gas_id] || 0)

/datum/gas_mixture/proc/set_min_heat_capacity(arg_min)
	if(gc_share)
		return FALSE
	min_heat_capacity = max(0, arg_min)
	return TRUE

/datum/gas_mixture/proc/temperature_share(datum/gas_mixture/sharer, conduction_coefficient, sharer_temperature, sharer_heat_capacity)
	if(gc_share)
		if(sharer)
			return sharer.return_temperature()
		return sharer_temperature
	var/sharer_is_immutable = sharer?.gc_share
	if(sharer)
		sharer_temperature = sharer.temperature_archived
	var/temperature_delta = temperature_archived - sharer_temperature
	if(abs(temperature_delta) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = archived_heat_capacity()
		if(!sharer_heat_capacity && sharer)
			sharer_heat_capacity = sharer.archived_heat_capacity()
		if(self_heat_capacity > MINIMUM_HEAT_CAPACITY && sharer_heat_capacity > MINIMUM_HEAT_CAPACITY)
			var/heat = conduction_coefficient * temperature_delta * (self_heat_capacity * sharer_heat_capacity / (self_heat_capacity + sharer_heat_capacity))
			temperature = max(temperature - heat / self_heat_capacity, TCMB)
			sharer_temperature = max(sharer_temperature + heat / sharer_heat_capacity, TCMB)
			if(sharer && !sharer_is_immutable)
				sharer.temperature = sharer_temperature
	return sharer_temperature

/datum/gas_mixture/proc/react(datum/holder)
	. = NO_REACTION
	if(!total_moles())
		return
	var/list/reactions = list()
	for(var/datum/gas_reaction/G in SSair.gas_reactions)
		reactions += G
	if(!length(reactions))
		return
	reaction_results = new
	var/temp = return_temperature()
	var/ener = thermal_energy()
	reaction_loop:
		for(var/r in reactions)
			var/datum/gas_reaction/reaction = r
			var/list/min_reqs = reaction.min_requirements
			if((min_reqs["TEMP"] && temp < min_reqs["TEMP"]) \
			|| (min_reqs["ENER"] && ener < min_reqs["ENER"]))
				continue
			if(min_reqs["MAX_TEMP"] && temp > min_reqs["MAX_TEMP"])
				continue
			for(var/id in min_reqs)
				if(id == "TEMP" || id == "ENER" || id == "MAX_TEMP")
					continue
				if(id == "FIRE_REAGENTS")
					if(get_oxidation_power(temp) < min_reqs[id] || get_fuel_amount(temp) < min_reqs[id])
						continue reaction_loop
					continue
				if(get_moles(id) < min_reqs[id])
					continue reaction_loop
			. |= reaction.react(src, holder)
			if(. & STOP_REACTIONS)
				break
