// Атмосфера на DM (газ в gas_mixture.gases, реакции в react(), без Auxmos).

/// Sentinel temperature gate meaning "no temperature-gated reactions exist".
/// A plain huge constant because this file compiles before the INFINITY define.
#define ATMOS_NO_TEMPERATURE_GATE 1e30

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
	/// Reaction pre-filter: gas id -> list of reactions keyed by that gas. A reaction
	/// can only run if its key gas is present, so mixtures without exotic gases skip
	/// the full 28-reaction requirement scan entirely. Built by auxtools_update_reactions().
	var/list/reactions_by_key_gas
	/// Reactions with no gas requirement at all (assoc: reaction -> its TEMP gate).
	var/list/temp_gated_reactions
	/// Lowest TEMP gate among temp_gated_reactions, for a single cheap precheck.
	var/temp_gated_min_temp = ATMOS_NO_TEMPERATURE_GATE

/datum/controller/subsystem/air/proc/get_max_gas_mixes()
	return dm_max_registered_gas_mixtures

/datum/controller/subsystem/air/proc/get_amt_gas_mixes()
	return dm_registered_gas_mixtures

/proc/equalize_all_gases_in_list(gas_list)
	if(!length(gas_list))
		return
	// Runs for every dirty pipenet every fire: accumulate totals into reused
	// static lists instead of allocating (and qdel-ing) a scratch gas_mixture.
	var/static/list/total_gases = list()
	var/static/list/datum/gas_mixture/participating = list()
	total_gases.Cut()
	participating.Cut()
	var/total_volume = 0
	var/total_heat_capacity = 0
	var/total_thermal_energy = 0
	var/list/specific_heats = GLOB.gas_data.specific_heats
	for(var/datum/gas_mixture/mix in gas_list)
		if(!mix || mix.gc_share)
			continue
		participating += mix
		total_volume += max(mix.volume, 0)
		var/mix_heat_capacity = 0
		var/list/mix_gases = mix.gases
		for(var/id in mix_gases)
			var/moles = mix_gases[id]
			total_gases[id] = (total_gases[id] || 0) + moles
			mix_heat_capacity += moles * (specific_heats[id] || 0)
		mix_heat_capacity = max(mix_heat_capacity, mix.min_heat_capacity)
		total_heat_capacity += mix_heat_capacity
		total_thermal_energy += mix.temperature * mix_heat_capacity
	if(!length(participating) || total_volume <= 0)
		participating.Cut()
		return
	// Sequential capacity-weighted merges collapse to total energy over total
	// capacity; TCMB matches the scratch mixture's default when nothing had heat.
	var/target_temperature = TCMB
	if(total_heat_capacity > 0)
		target_temperature = max(total_thermal_energy / total_heat_capacity, TCMB)
	var/inv_total_volume = 1 / total_volume
	for(var/datum/gas_mixture/mix as anything in participating)
		var/volume_ratio = max(mix.volume, 0) * inv_total_volume
		var/list/mix_gases = mix.gases
		mix_gases.Cut()
		for(var/id in total_gases)
			var/moles = total_gases[id] * volume_ratio
			if(moles > 0)
				mix_gases[id] = moles
		mix.temperature = target_temperature
	// Do not keep strong references to pipenet mixtures between calls.
	participating.Cut()
	total_gases.Cut()

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
		var/datum/gas_mixture/turf_air = T.air
		var/current_moles = turf_air.total_moles()
		if(current_moles <= MINIMUM_MOLES_DELTA_TO_MOVE)
			var/volume_cache = turf_air.volume
			var/current_pressure = volume_cache > 0 ? (current_moles * R_IDEAL_GAS_EQUATION * turf_air.temperature / volume_cache) : 0
			if(current_pressure <= (ONE_ATMOSPHERE * 0.05))
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
	if(T.atmos_wake_machines)
		for(var/obj/machinery/atmospherics/machine as anything in T.atmos_wake_machines)
			machine.atmos_wake()
	if(blockchanges && T.excited_group)
		// External gas changes must postpone group averaging/dismantling, which
		// reset_cooldowns does; destroying the group here (the old behavior) made
		// every vent top-up and mob breath rebuild whole room groups from scratch
		// each fire, keeping hundreds of settled turfs permanently active.
		// Structural (adjacency) changes DO dismantle the group - see
		// /turf/air_update_turf(update = TRUE).
		T.excited_group.reset_cooldowns()

/// Rests a turf without touching its excited group: the turf stops paying
/// process_cell, but stays in the group's turf_list so breakdown/dismantle
/// bookkeeping continues. This is the individual escape hatch for settled
/// members of groups that are pinned awake by a few churning turfs
/// (planetary surfaces around a leak, space-edge drains).
/datum/controller/subsystem/air/proc/sleep_active_turf(turf/open/T)
	active_turfs -= T
	if(istype(T))
		T.excited = FALSE

/datum/controller/subsystem/air/proc/thread_running()
	return FALSE

/// Returns the shared immutable gas mixture a planetary turf regenerates toward.
/// Built once per unique gas string; replaces the old per-turf-per-cycle
/// `new + parse_gas_string + qdel` in process_cell. Keyed by the raw
/// initial_gas_mix string, matching what ashwalker lungs look up
/// (SSair.planetary[LAVALAND_DEFAULT_ATMOS]).
/datum/controller/subsystem/air/proc/get_planetary_template(turf/open/T)
	var/cache_key = T.initial_gas_mix
	var/datum/gas_mixture/template = planetary[cache_key]
	if(template)
		return template
	template = new(CELL_VOLUME)
	template.set_temperature(initial(T.initial_temperature))
	template.parse_gas_string(cache_key)
	template.mark_immutable()
	planetary[cache_key] = template
	return template

/proc/finalize_gas_refs()
	return

/datum/controller/subsystem/air/proc/auxtools_update_reactions()
	var/list/by_gas = list()
	var/list/temp_gated = list()
	var/gate_floor = ATMOS_NO_TEMPERATURE_GATE
	var/index = 0
	for(var/datum/gas_reaction/reaction as anything in gas_reactions)
		index++
		reaction.sort_index = index
		var/list/reqs = reaction.min_requirements
		var/key_gas
		for(var/id in reqs)
			if(id == "TEMP" || id == "ENER" || id == "MAX_TEMP" || id == "FIRE_REAGENTS")
				continue
			if(isnull(key_gas))
				key_gas = id
			else if(key_gas == GAS_O2 || key_gas == GAS_N2 || key_gas == GAS_CO2 || key_gas == GAS_H2O)
				// Prefer a rarer key so common-air mixtures never pull this reaction
				// in as a candidate; any other requirement gas beats the air staples.
				key_gas = id
		if(key_gas)
			var/list/bucket = by_gas[key_gas]
			if(!bucket)
				bucket = list()
				by_gas[key_gas] = bucket
			bucket += reaction
		else
			var/temp_gate = reqs["TEMP"] || 0
			temp_gated[reaction] = temp_gate
			gate_floor = min(gate_floor, temp_gate)
	reactions_by_key_gas = by_gas
	temp_gated_reactions = temp_gated
	temp_gated_min_temp = gate_floor

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
			// Eagerly build the shared planetary template so consumers that read
			// SSair.planetary directly (ashwalker lungs) find it populated.
			SSair.get_planetary_template(open_turf)
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

/// Moves `ratio` (0..1) of every gas from src into other in place, with the same
/// temperature math as merge(remove(...)), without allocating a temporary mixture.
/// Callers guarantee ratio > 0 and both mixtures mutable.
/// Returns TRUE only when gas actually moved, matching vent_moles/vent_ratio, so
/// callers can treat the result as "did work" for idle accounting.
/datum/gas_mixture/proc/__transfer_ratio_direct(datum/gas_mixture/other, ratio)
	var/list/cached_gases = gases
	var/list/other_gases = other.gases
	var/heat_transfer = abs(other.temperature - temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER
	var/other_old_capacity = 0
	var/moved_heat_capacity = 0
	var/list/cached_gasheats
	if(heat_transfer)
		other_old_capacity = other.heat_capacity()
		cached_gasheats = GLOB.gas_data.specific_heats
	var/moved_any = FALSE
	for(var/id in cached_gases)
		var/moved = cached_gases[id] * ratio
		if(moved <= 0)
			continue
		moved_any = TRUE
		other_gases[id] = (other_gases[id] || 0) + moved
		cached_gases[id] -= moved
		if(heat_transfer)
			moved_heat_capacity += moved * (cached_gasheats[id] || 0)
	if(!moved_any)
		return FALSE
	if(heat_transfer && moved_heat_capacity > 0)
		var/combined_heat_capacity = other_old_capacity + moved_heat_capacity
		other.temperature = (temperature * moved_heat_capacity + other.temperature * other_old_capacity) / combined_heat_capacity
	GAS_GARBAGE_COLLECT(cached_gases)
	return TRUE

/datum/gas_mixture/proc/transfer_to(datum/gas_mixture/other, moles)
	if(gc_share || !other || other.gc_share)
		return FALSE
	var/list/cached_gases = gases
	var/sum = 0
	for(var/id in cached_gases)
		sum += cached_gases[id]
	moles = min(moles, sum)
	if(moles <= 0)
		// Nothing to move (empty source): report no-op so vents/pumps can idle
		// instead of counting a phantom transfer every fire.
		return FALSE
	return __transfer_ratio_direct(other, moles / sum)

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
	ratio = clamp(ratio, 0, 1)
	if(ratio <= 0)
		// See transfer_to(): a no-op must not read as a successful transfer.
		return FALSE
	return __transfer_ratio_direct(other, ratio)

/// Discards `ratio` (0..1) of every gas in place: venting into an infinite sink
/// (space). Equivalent to qdel(remove_ratio(ratio)) without the allocation.
/// Returns TRUE if any gas was actually discarded.
/datum/gas_mixture/proc/vent_ratio(ratio)
	if(gc_share)
		return FALSE
	ratio = clamp(ratio, 0, 1)
	if(ratio <= 0)
		return FALSE
	var/keep = 1 - ratio
	var/vented = 0
	var/list/cached_gases = gases
	for(var/id in cached_gases)
		var/current_moles = cached_gases[id]
		if(current_moles <= 0)
			continue
		vented += current_moles * ratio
		cached_gases[id] = current_moles * keep
	if(vented <= 0)
		return FALSE
	GAS_GARBAGE_COLLECT(cached_gases)
	return TRUE

/// Discards `moles` of gas in place, proportionally across all gases.
/// Equivalent to qdel(remove(moles)) without the allocation.
/// Returns TRUE if any gas was actually discarded.
/datum/gas_mixture/proc/vent_moles(moles)
	if(gc_share)
		return FALSE
	var/list/cached_gases = gases
	var/sum = 0
	for(var/id in cached_gases)
		sum += cached_gases[id]
	moles = min(moles, sum)
	if(moles <= 0)
		return FALSE
	return vent_ratio(moles / sum)

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
	// Runs for every adjacent turf pair every cycle: iterate both key sets directly
	// instead of allocating a `gases | other.gases` union list per call.
	var/list/cached_gases = gases
	var/list/other_gases = other.gases
	var/our_moles = 0
	for(var/id in cached_gases)
		var/gas_moles = cached_gases[id] || 0
		our_moles += gas_moles
		var/delta = abs(gas_moles - (other_gases[id] || 0))
		if(delta > MINIMUM_MOLES_DELTA_TO_MOVE)
			if(delta > gas_moles * MINIMUM_AIR_RATIO_TO_MOVE)
				return id
	for(var/id in other_gases)
		if(id in cached_gases)
			continue
		// gas_moles is 0 for ids we lack, so the ratio gate is always passed.
		if(abs(other_gases[id] || 0) > MINIMUM_MOLES_DELTA_TO_MOVE)
			return id
	if(our_moles > MINIMUM_MOLES_DELTA_TO_MOVE)
		if(abs(temperature - other.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND)
			return "temp"
	return ""

/datum/gas_mixture/proc/mark_immutable()
	gc_share = TRUE
	immutable_heat_capacity = heat_capacity()
	return TRUE

/// Moves `ratio_v` of the gases named in gas_list into `into` in place, with the
/// same temperature math as merge(removed portion). Returns TRUE only when gas
/// actually moved, so callers can skip turf/pipenet updates for clean rooms.
/datum/gas_mixture/proc/scrub_into(datum/gas_mixture/into, ratio_v, list/gas_list)
	if(gc_share || !into || into.gc_share)
		return FALSE
	ratio_v = clamp(ratio_v, 0, 1)
	if(ratio_v <= 0 || !length(gas_list))
		return FALSE
	var/list/cached_gases = gases
	var/list/into_gases = into.gases
	var/heat_transfer = abs(into.temperature - temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER
	var/into_old_capacity = 0
	var/moved_heat_capacity = 0
	var/list/cached_gasheats
	if(heat_transfer)
		into_old_capacity = into.heat_capacity()
		cached_gasheats = GLOB.gas_data.specific_heats
	var/moved_any = FALSE
	for(var/gid in gas_list)
		var/current_moles = cached_gases[gid] || 0
		if(current_moles <= 0)
			continue
		var/moved = current_moles * ratio_v
		if(moved <= 0)
			continue
		moved_any = TRUE
		into_gases[gid] = (into_gases[gid] || 0) + moved
		cached_gases[gid] = current_moles - moved
		if(heat_transfer)
			moved_heat_capacity += moved * (cached_gasheats[gid] || 0)
	if(!moved_any)
		return FALSE
	if(heat_transfer && moved_heat_capacity > 0)
		var/combined_heat_capacity = into_old_capacity + moved_heat_capacity
		into.temperature = (temperature * moved_heat_capacity + into.temperature * into_old_capacity) / combined_heat_capacity
	GAS_GARBAGE_COLLECT(cached_gases)
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
	var/list/cached_gases = gases
	var/total = 0
	for(var/id in cached_gases)
		total += cached_gases[id]
	if(!total)
		// A mixture that reacted on a previous call and has since been emptied
		// must not leave stale per-call results (hotspots read them after react()).
		if(length(reaction_results))
			reaction_results.Cut()
		return

	// Gather candidates through the key-gas index instead of scanning every
	// registered reaction: a reaction can only fire if its key gas is present.
	// This runs for every active turf, pipenet and portable every SSair fire,
	// and ordinary o2/n2 air resolves to zero candidates.
	var/temp = temperature
	var/list/candidates
	// The single-bucket case (one keyed gas present, by far the most common)
	// borrows the prebuilt bucket read-only: buckets are already in sort_index
	// order and the reaction loop never mutates the list, so both the copy and
	// the re-sort below are only needed once a second source gets appended.
	var/candidates_owned = FALSE
	var/list/by_gas = SSair.reactions_by_key_gas
	if(by_gas)
		for(var/id in cached_gases)
			var/list/bucket = by_gas[id]
			if(!bucket)
				continue
			if(!candidates)
				candidates = bucket
			else
				if(!candidates_owned)
					candidates = candidates.Copy()
					candidates_owned = TRUE
				candidates += bucket
		if(temp >= SSair.temp_gated_min_temp)
			var/list/temp_gated = SSair.temp_gated_reactions
			for(var/r in temp_gated)
				if(temp >= temp_gated[r])
					if(!candidates)
						candidates = list()
						candidates_owned = TRUE
					else if(!candidates_owned)
						candidates = candidates.Copy()
						candidates_owned = TRUE
					candidates += r
	else
		candidates = SSair.gas_reactions.Copy()
		candidates_owned = TRUE

	// Every react() past the moles gate must leave reaction_results reflecting
	// only this call: hotspots read reaction_results["fire"] right after react().
	if(length(reaction_results))
		reaction_results.Cut()
	else if(!reaction_results)
		reaction_results = new

	if(!length(candidates))
		return

	// Restore the priority order of the full-list scan (insertion sort; the
	// candidate list is nearly always 1-3 entries). A borrowed single bucket is
	// already sorted and must not be written to.
	if(candidates_owned && candidates.len > 1)
		for(var/i in 2 to candidates.len)
			var/datum/gas_reaction/shifted = candidates[i]
			var/hole = i - 1
			while(hole >= 1)
				var/datum/gas_reaction/other = candidates[hole]
				if(other.sort_index <= shifted.sort_index)
					break
				candidates[hole + 1] = other
				hole--
			candidates[hole + 1] = shifted

	var/ener = -1
	reaction_loop:
		for(var/datum/gas_reaction/reaction as anything in candidates)
			var/list/min_reqs = reaction.min_requirements
			if(min_reqs["TEMP"] && temp < min_reqs["TEMP"])
				continue
			if(min_reqs["ENER"])
				if(ener < 0)
					ener = thermal_energy()
				if(ener < min_reqs["ENER"])
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
				if((cached_gases[id] || 0) < min_reqs[id])
					continue reaction_loop
			. |= reaction.react(src, holder)
			if(. & STOP_REACTIONS)
				break
