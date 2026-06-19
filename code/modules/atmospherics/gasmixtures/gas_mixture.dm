 /*
What are the archived variables for?
	Calculations are done using the archived variables with the results merged into the regular variables.
	This prevents race conditions that arise based on the order of tile processing.
*/
#define MINIMUM_MOLE_COUNT		0.01

/datum/gas_mixture
	/// Never ever set this variable, hooked into vv_get_var for view variables viewing.
	var/gas_list_view_only
	var/initial_volume = CELL_VOLUME //liters
	var/list/reaction_results
	var/list/analyzer_results //used for analyzer feedback - not initialized until its used
	var/_extools_pointer_gasmixture // legacy, не используется при нативной атмосфере
	var/list/gases = list()
	var/temperature = TCMB
	var/tmp/temperature_archived = TCMB
	var/volume = CELL_VOLUME
	var/min_heat_capacity = 0
	var/last_share = 0
	var/gc_share = FALSE
	var/list/gas_archive
	/// Native DM atmos registration guard.
	var/dm_registered_to_ssair = FALSE

/datum/gas_mixture/New(volume)
	if (!isnull(volume))
		initial_volume = volume
	src.volume = initial_volume
	temperature = TCMB
	temperature_archived = TCMB
	reaction_results = new
	__gasmixture_register()

/datum/gas_mixture/vv_edit_var(var_name, var_value)
	if(var_name == NAMEOF(src, _extools_pointer_gasmixture))
		return FALSE // please no. segfaults bad.
	if(var_name == NAMEOF(src, gas_list_view_only))
		return FALSE
	return ..()

/datum/gas_mixture/vv_get_var(var_name)
	. = ..()
	if(var_name == NAMEOF(src, gas_list_view_only))
		var/list/dummy = get_gases()
		for(var/gas in dummy)
			dummy[gas] = get_moles(gas)
			dummy["CAP [gas]"] = partial_heat_capacity(gas)
		dummy["TEMP"] = return_temperature()
		dummy["PRESSURE"] = return_pressure()
		dummy["HEAT CAPACITY"] = heat_capacity()
		dummy["TOTAL MOLES"] = total_moles()
		dummy["VOLUME"] = return_volume()
		dummy["THERMAL ENERGY"] = thermal_energy()
		return debug_variable("gases (READ ONLY)", dummy, 0, src)

/datum/gas_mixture/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---")
	VV_DROPDOWN_OPTION(VV_HK_PARSE_GASSTRING, "Parse Gas String")
	VV_DROPDOWN_OPTION(VV_HK_EMPTY, "Empty")
	VV_DROPDOWN_OPTION(VV_HK_SET_MOLES, "Set Moles")
	VV_DROPDOWN_OPTION(VV_HK_SET_TEMPERATURE, "Set Temperature")
	VV_DROPDOWN_OPTION(VV_HK_SET_VOLUME, "Set Volume")

/datum/gas_mixture/vv_do_topic(list/href_list)
	. = ..()
	if(!.)
		return
	if(href_list[VV_HK_PARSE_GASSTRING])
		var/gasstring = input(usr, "Input Gas String (WARNING: Advanced. Don't use this unless you know how these work.", "Gas String Parse") as text|null
		if(!istext(gasstring))
			return
		log_admin("[key_name(usr)] modified gas mixture [REF(src)]: Set to gas string [gasstring].")
		message_admins("[key_name(usr)] modified gas mixture [REF(src)]: Set to gas string [gasstring].")
		parse_gas_string(gasstring)
	if(href_list[VV_HK_EMPTY])
		log_admin("[key_name(usr)] emptied gas mixture [REF(src)].")
		message_admins("[key_name(usr)] emptied gas mixture [REF(src)].")
		clear()
	if(href_list[VV_HK_SET_MOLES])
		var/list/gases = get_gases()
		for(var/gas in gases)
			gases[gas] = get_moles(gas)
		var/gasid = input(usr, "What kind of gas?", "Set Gas") as null|anything in GLOB.gas_data.ids
		if(!gasid)
			return
		var/amount = input(usr, "Input amount", "Set Gas", gases[gasid] || 0) as num|null
		if(!isnum(amount))
			return
		amount = max(0, amount)
		log_admin("[key_name(usr)] modified gas mixture [REF(src)]: Set gas [gasid] to [amount] moles.")
		message_admins("[key_name(usr)] modified gas mixture [REF(src)]: Set gas [gasid] to [amount] moles.")
		set_moles(gasid, amount)
	if(href_list[VV_HK_SET_TEMPERATURE])
		var/temp = input(usr, "Set the temperature of this mixture to?", "Set Temperature", return_temperature()) as num|null
		if(!isnum(temp))
			return
		temp = max(2.7, temp)
		log_admin("[key_name(usr)] modified gas mixture [REF(src)]: Changed temperature to [temp].")
		message_admins("[key_name(usr)] modified gas mixture [REF(src)]: Changed temperature to [temp].")
		set_temperature(temp)
	if(href_list[VV_HK_SET_VOLUME])
		var/volume = input(usr, "Set the volume of this mixture to?", "Set Volume", return_volume()) as num|null
		if(!isnum(volume))
			return
		volume = max(0, volume)
		log_admin("[key_name(usr)] modified gas mixture [REF(src)]: Changed volume to [volume].")
		message_admins("[key_name(usr)] modified gas mixture [REF(src)]: Changed volume to [volume].")
		set_volume(volume)


/datum/gas_mixture/Destroy()
	__gasmixture_unregister()
	reaction_results = null
	analyzer_results = null
	..()
	return QDEL_HINT_QUEUE_THEN_HARDDEL

/proc/gas_types()
	var/list/L = subtypesof(/datum/gas)
	for(var/gt in L)
		var/datum/gas/G = gt
		L[gt] = initial(G.specific_heat)
	return L


// VV WRAPPERS - EXTOOLS HOOKED PROCS DO NOT TAKE ARGUMENTS FROM CALL() FOR SOME REASON.
/datum/gas_mixture/proc/vv_set_moles(gas_type, moles)
	return set_moles(gas_type, moles)
/datum/gas_mixture/proc/vv_get_moles(gas_type)
	return get_moles(gas_type)
/datum/gas_mixture/proc/vv_set_temperature(new_temp)
	return set_temperature(new_temp)
/datum/gas_mixture/proc/vv_set_volume(new_volume)
	return set_volume(new_volume)
/datum/gas_mixture/proc/vv_react(datum/holder)
	return react(holder)

/datum/gas_mixture/proc/get_last_share()
	return last_share

/datum/gas_mixture/proc/remove(amount)
	//Removes amount of gas from the gas_mixture
	//Returns: gas_mixture with the gases removed

/datum/gas_mixture/proc/remove_by_flag(flag, amount)
	//Removes amount of gas from the gas mixture by flag
	//Returns: gas_mixture with gases that match the flag removed

/datum/gas_mixture/proc/remove_ratio(ratio)
	//Proportionally removes amount of gas from the gas_mixture
	//Returns: gas_mixture with the gases removed

/datum/gas_mixture/proc/copy()
	//Creates new, identical gas mixture
	//Returns: duplicate gas mixture

/datum/gas_mixture/proc/copy_from_turf(turf/model)
	//Copies all gas info from the turf into the gas list along with temperature
	//Returns: 1 if we are mutable, 0 otherwise

/datum/gas_mixture/proc/parse_gas_string(gas_string)
	//Copies variables from a particularly formatted string.
	//Returns: 1 if we are mutable, 0 otherwise

/datum/gas_mixture/proc/share(datum/gas_mixture/sharer, our_coeff = 0.25, sharer_coeff = 0.25)
	//Performs air sharing calculations between two gas_mixtures assuming only 1 boundary length
	//Returns: amount of gas exchanged (+ if sharer received)
	if(!sharer || gc_share || sharer.gc_share)
		return 0
	our_coeff = clamp(our_coeff, 0, 1)
	sharer_coeff = clamp(sharer_coeff, 0, 1)
	if(!our_coeff && !sharer_coeff)
		return 0

	var/list/cached_gases = gases
	var/list/sharer_gases = sharer.gases
	var/list/self_archive = gas_archive || cached_gases
	var/list/sharer_archive = sharer.gas_archive || sharer_gases

	var/temperature_delta = temperature_archived - sharer.temperature_archived
	var/abs_temperature_delta = abs(temperature_delta)

	var/old_self_heat_capacity = 0
	var/old_sharer_heat_capacity = 0
	if(abs_temperature_delta > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		old_self_heat_capacity = heat_capacity()
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

	last_share = abs_moved_moles

	if(abs_temperature_delta > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/new_self_heat_capacity = old_self_heat_capacity + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
		var/new_sharer_heat_capacity = old_sharer_heat_capacity + heat_capacity_self_to_sharer - heat_capacity_sharer_to_self

		if(new_self_heat_capacity > MINIMUM_HEAT_CAPACITY)
			temperature = (old_self_heat_capacity * temperature - heat_capacity_self_to_sharer * temperature_archived + heat_capacity_sharer_to_self * sharer.temperature_archived) / new_self_heat_capacity

		if(new_sharer_heat_capacity > MINIMUM_HEAT_CAPACITY)
			sharer.temperature = (old_sharer_heat_capacity * sharer.temperature - heat_capacity_sharer_to_self * sharer.temperature_archived + heat_capacity_self_to_sharer * temperature_archived) / new_sharer_heat_capacity
			if(abs(old_sharer_heat_capacity) > MINIMUM_HEAT_CAPACITY)
				if(abs(new_sharer_heat_capacity / old_sharer_heat_capacity - 1) < 0.1)
					temperature_share(sharer, OPEN_HEAT_TRANSFER_COEFFICIENT)

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
		return (temperature_archived * (our_moles + moved_moles) - sharer.temperature_archived * (their_moles - moved_moles)) * R_IDEAL_GAS_EQUATION / volume
	return 0

/datum/gas_mixture/remove_by_flag(flag, amount)
	var/datum/gas_mixture/removed = new type
	__remove_by_flag(removed, flag, amount)

	return removed

/datum/gas_mixture/remove(amount)
	var/datum/gas_mixture/removed = new type
	__remove(removed, amount)

	return removed

/datum/gas_mixture/remove_ratio(ratio)
	var/datum/gas_mixture/removed = new type
	__remove_ratio(removed, ratio)

	return removed

/// Removes a specific amount of one gas. Returns a gas_mixture with that gas, or null if amount <= 0.
/// If into is supplied, that mixture is cleared and filled (no allocation); otherwise a new mixture is created.
/datum/gas_mixture/proc/remove_specific(gas_id, amount, datum/gas_mixture/into)
	if(gc_share)
		return null
	var/current = get_moles(gas_id)
	amount = min(amount, current)
	if(amount <= 0)
		return null
	if(into)
		into.clear()
		into.set_moles(gas_id, amount)
		into.set_temperature(return_temperature())
		adjust_moles(gas_id, -amount)
		return into
	var/datum/gas_mixture/removed = new type(return_volume())
	removed.set_moles(gas_id, amount)
	removed.set_temperature(return_temperature())
	adjust_moles(gas_id, -amount)
	return removed

/datum/gas_mixture/copy()
	var/datum/gas_mixture/copy = new type
	copy.copy_from(src)

	return copy

/datum/gas_mixture/copy_from_turf(turf/model)
	if(gc_share)
		return FALSE
	set_temperature(initial(model.initial_temperature))
	parse_gas_string(model.initial_gas_mix)
	return TRUE

/datum/gas_mixture/parse_gas_string(gas_string)
	if(gc_share)
		return FALSE
	gas_string = SSair.preprocess_gas_string(gas_string)
	var/list/gas = params2list(gas_string)
	if(gas["TEMP"])
		var/temp = text2num(gas["TEMP"])
		gas -= "TEMP"
		if(!isnum(temp) || temp < 2.7)
			temp = 2.7
		set_temperature(temp)
	clear()
	for(var/id in gas)
		set_moles(id, text2num(gas[id]))
	archive()
	return TRUE

/datum/gas_mixture/proc/set_analyzer_results(instability)
	if(!analyzer_results)
		analyzer_results = new
	analyzer_results["fusion"] = instability

//Mathematical proofs:
/*
get_breath_partial_pressure(gas_pp) --> gas_pp/total_moles()*breath_pp = pp
get_true_breath_pressure(pp) --> gas_pp = pp/breath_pp*total_moles()
10/20*5 = 2.5
10 = 2.5/5*20
*/

/datum/gas_mixture/turf

/*
/mob/verb/profile_atmos()
	/world{loop_checks = 0;}
	var/datum/gas_mixture/A = new
	var/datum/gas_mixture/B = new
	A.parse_gas_string("o2=200;n2=800;TEMP=50")
	B.parse_gas_string("co2=500;plasma=500;TEMP=5000")
	var/pa
	var/pb
	pa = world.tick_usage
	for(var/I in 1 to 100000)
		B.transfer_to(A, 1)
		A.transfer_to(B, 1)
	pb = world.tick_usage
	var/total_time = (pb-pa) * world.tick_lag
	to_chat(src, "Total time (gas transfer): [total_time]ms")
	to_chat(src, "Operations per second: [100000 / (total_time/1000)]")
	pa = world.tick_usage
	for(var/I in 1 to 100000)
		B.total_moles();
	pb = world.tick_usage
	total_time = (pb-pa) * world.tick_lag
	to_chat(src, "Total time (total_moles): [total_time]ms")
	to_chat(src, "Operations per second: [100000 / (total_time/1000)]")
	pa = world.tick_usage
	for(var/I in 1 to 100000)
		new /datum/gas_mixture
	pb = world.tick_usage
	total_time = (pb-pa) * world.tick_lag
	to_chat(src, "Total time (new gas mixture): [total_time]ms")
	to_chat(src, "Operations per second: [100000 / (total_time/1000)]")
*/

/// Releases gas from src to output air. This means that it can not transfer air to gas mixture with higher pressure.
/// a global proc due to rustmos
/proc/release_gas_to(datum/gas_mixture/input_air, datum/gas_mixture/output_air, target_pressure)
	var/output_starting_pressure = output_air.return_pressure()
	var/input_starting_pressure = input_air.return_pressure()

	if(output_starting_pressure >= min(target_pressure,input_starting_pressure-10))
		//No need to pump gas if target is already reached or input pressure is too low
		//Need at least 10 KPa difference to overcome friction in the mechanism
		return FALSE

	//Calculate necessary moles to transfer using PV = nRT
	if((input_air.total_moles() > 0) && (input_air.return_temperature()>0))
		var/pressure_delta = min(target_pressure - output_starting_pressure, (input_starting_pressure - output_starting_pressure)/2)
		//Can not have a pressure delta that would cause output_pressure > input_pressure

		var/transfer_moles = pressure_delta*output_air.return_volume()/(input_air.return_temperature() * R_IDEAL_GAS_EQUATION)

		//Actually transfer the gas
		if(output_air.gc_share)
			var/datum/gas_mixture/removed = input_air.remove(transfer_moles)
			if(!removed || removed.total_moles() <= 0)
				if(removed)
					qdel(removed)
				return FALSE
			qdel(removed)
		else if(!input_air.transfer_to(output_air, transfer_moles))
			return FALSE

		return TRUE
	return FALSE

/// Runs electrolyzer reactions on this gas mixture (see /datum/electrolyzer_reaction).
/datum/gas_mixture/proc/electrolyze(working_power = 0, list/electrolyzer_args = list())
	for(var/reaction_id in GLOB.electrolyzer_reactions)
		var/datum/electrolyzer_reaction/reaction = GLOB.electrolyzer_reactions[reaction_id]
		if(!reaction.reaction_check(src, electrolyzer_args))
			continue
		reaction.react(src, working_power, electrolyzer_args)
		. = TRUE
