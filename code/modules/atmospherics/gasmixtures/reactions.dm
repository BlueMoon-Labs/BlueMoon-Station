//All defines used in reactions are located in ..\__DEFINES\reactions.dm

/proc/init_gas_reactions()
	. = list()

	for(var/r in subtypesof(/datum/gas_reaction))
		var/datum/gas_reaction/reaction = r
		reaction = new r
		if(!reaction.exclude)
			. += reaction
	sortTim(., GLOBAL_PROC_REF(cmp_gas_reaction))

/proc/cmp_gas_reaction(datum/gas_reaction/a, datum/gas_reaction/b) // compares lists of reactions by the maximum priority contained within the list
	return b.priority - a.priority

/datum/gas_reaction
	//regarding the requirements lists: the minimum or maximum requirements must be non-zero.
	//when in doubt, use MINIMUM_MOLE_COUNT.
	var/list/min_requirements
	var/exclude = FALSE //do it this way to allow for addition/removal of reactions midmatch in the future
	var/priority = 100 //lower numbers are checked/react later than higher numbers. if two reactions have the same priority they may happen in either order
	/// Position in the priority-sorted SSair.gas_reactions list, maintained by
	/// SSair.auxtools_update_reactions(); used to keep candidate evaluation order
	/// identical to the full-list scan when gathering reactions from the key-gas index.
	var/sort_index = 0
	var/name = "reaction"
	var/id = "r"
	/// Short description for the atmos handbook.
	var/desc
	/** Reaction factors for the atmos handbook — human-readable assoc list.
	 * Keys: /datum/gas types or misc strings like "Temperature", "Energy". */
	var/list/factor

/datum/gas_reaction/New()
	init_reqs()
	init_factors()

/datum/gas_reaction/proc/init_reqs()

/datum/gas_reaction/proc/init_factors()
	factor = list()

/datum/gas_reaction/proc/react(datum/gas_mixture/air, atom/location)
	return NO_REACTION

/datum/gas_reaction/proc/test()
	return list("success" = TRUE)

/datum/gas_reaction/nobliumsupression
	priority = INFINITY
	name = "Hyper-Noblium Reaction Suppression"
	id = "nobstop"

/datum/gas_reaction/nobliumsupression/init_reqs()
	min_requirements = list(
		GAS_HYPERNOB = REACTION_OPPRESSION_THRESHOLD,
		"TEMP" = REACTION_OPPRESSION_MIN_TEMP // only stops reactions when temp > 20 K
	)

/datum/gas_reaction/nobliumsupression/react()
	return STOP_REACTIONS

//water vapor: puts out fires?
/datum/gas_reaction/water_vapor
	priority = 1
	name = "Water Vapor"
	id = "vapor"

/datum/gas_reaction/water_vapor/init_reqs()
	min_requirements = list(
		GAS_H2O = MOLES_GAS_VISIBLE,
		"MAX_TEMP" = T0C + 40
	)

/datum/gas_reaction/water_vapor/react(datum/gas_mixture/air, datum/holder)
	var/turf/open/location = holder
	if(!istype(location))
		return NO_REACTION
	if (air.return_temperature() <= WATER_VAPOR_FREEZE)
		if(location && location.freon_gas_act())
			return REACTING
	else if(location && location.water_vapor_gas_act())
		air.adjust_moles(GAS_H2O,-MOLES_GAS_VISIBLE)
		return REACTING

// no test cause it's entirely based on location

/datum/gas_reaction/condensation
	priority = 0
	name = "Condensation"
	id = "condense"
	exclude = TRUE
	var/datum/reagent/condensing_reagent

/datum/gas_reaction/condensation/New(datum/reagent/R)
	. = ..()
	if(!istype(R))
		return
	min_requirements = list(
		"MAX_TEMP" = initial(R.boiling_point)
	)
	min_requirements[R.get_gas()] = MOLES_GAS_VISIBLE
	name = "[R.name] condensation"
	id = "[R.type] condensation"
	condensing_reagent = GLOB.chemical_reagents_list[R.type]
	exclude = FALSE

/datum/gas_reaction/condensation/react(datum/gas_mixture/air, datum/holder)
	. = NO_REACTION
	var/turf/open/location = holder
	if(!istype(location))
		return
	var/temperature = air.return_temperature()
	var/static/datum/reagents/reagents_holder = new
	reagents_holder.clear_reagents()
	reagents_holder.chem_temp = temperature
	var/G = condensing_reagent.get_gas()
	var/amt = air.get_moles(G)
	air.adjust_moles(G, -min(initial(condensing_reagent.condensation_amount), amt))
	if(air.get_moles(G) < MOLES_GAS_VISIBLE)
		amt += air.get_moles(G)
		air.set_moles(G, 0.0)
	reagents_holder.add_reagent(condensing_reagent.type, amt)
	. = REACTING
	for(var/atom/movable/AM in location)
		if(location.intact && AM.level == 1)
			continue
		reagents_holder.reaction(AM, TOUCH)
	reagents_holder.reaction(location, TOUCH)

//tritium combustion: combustion of oxygen and tritium (treated as hydrocarbons). creates hotspots. exothermic
/datum/gas_reaction/tritfire
	priority = -1 //fire should ALWAYS be last, but tritium fires happen before plasma fires
	name = "Tritium Combustion"
	id = "tritfire"

/datum/gas_reaction/tritfire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		GAS_TRITIUM = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT
	)

/proc/fire_expose(turf/open/location, datum/gas_mixture/air, temperature)
	if(istype(location) && temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
		location.hotspot_expose(temperature, CELL_VOLUME)
		for(var/I in location)
			var/atom/movable/item = I
			item.temperature_expose(air, temperature, CELL_VOLUME)
		location.temperature_expose(air, temperature, CELL_VOLUME)

/proc/radiation_burn(turf/open/location, rad_power)
	if(istype(location) && prob(10))
		radiation_pulse(location, rad_power)

/datum/gas_reaction/tritfire/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var/list/cached_results = air.reaction_results
	cached_results["fire"] = 0
	var/turf/open/location = isturf(holder) ? holder : null

	var/burned_fuel = 0
	if(air.get_moles(GAS_O2) < air.get_moles(GAS_TRITIUM))
		burned_fuel = air.get_moles(GAS_O2)/TRITIUM_BURN_OXY_FACTOR
		air.adjust_moles(GAS_TRITIUM, -burned_fuel)
	else
		burned_fuel = air.get_moles(GAS_TRITIUM)*TRITIUM_BURN_TRIT_FACTOR
		air.adjust_moles(GAS_TRITIUM, -air.get_moles(GAS_TRITIUM)/TRITIUM_BURN_TRIT_FACTOR)
		air.adjust_moles(GAS_O2,-air.get_moles(GAS_TRITIUM))

	if(burned_fuel)
		energy_released += (FIRE_HYDROGEN_ENERGY_RELEASED * burned_fuel)
		if(location && prob(10) && burned_fuel > TRITIUM_MINIMUM_RADIATION_ENERGY) //woah there let's not crash the server
			radiation_pulse(location, energy_released/TRITIUM_BURN_RADIOACTIVITY_FACTOR)

		air.adjust_moles(GAS_H2O, burned_fuel/TRITIUM_BURN_OXY_FACTOR)

		cached_results["fire"] += burned_fuel

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature((temperature*old_heat_capacity + energy_released)/new_heat_capacity)

	//let the floor know a fire is happening
	if(istype(location))
		temperature = air.return_temperature()
		if(temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
			location.hotspot_expose(temperature, CELL_VOLUME)
			for(var/I in location)
				var/atom/movable/item = I
				item.temperature_expose(air, temperature, CELL_VOLUME)
			location.temperature_expose(air, temperature, CELL_VOLUME)

	return cached_results["fire"] ? REACTING : NO_REACTION

/datum/gas_reaction/tritfire/test()
	var/datum/gas_mixture/G = new
	G.set_moles(GAS_TRITIUM,50)
	G.set_moles(GAS_O2,50)
	G.set_temperature(500)
	var/result = G.react()
	if(result != REACTING)
		return list("success" = FALSE, "message" = "Reaction didn't go at all!")
	if(!G.reaction_results["fire"])
		return list("success" = FALSE, "message" = "Trit fires aren't setting fire results correctly!")
	return ..()

//plasma combustion: combustion of oxygen and plasma (treated as hydrocarbons). creates hotspots. exothermic
/datum/gas_reaction/plasmafire
	priority = -2
	name = "Plasma Combustion"
	id = "plasmafire"

/datum/gas_reaction/plasmafire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		GAS_PLASMA = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/plasmafire/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var/list/cached_results = air.reaction_results
	cached_results["fire"] = 0
	var/turf/open/location = isturf(holder) ? holder : null

	//Handle plasma burning
	var/plasma_burn_rate = 0
	var/oxygen_burn_rate = 0
	//more plasma released at higher temperatures
	var/temperature_scale = 0
	//to make tritium
	var/super_saturation = FALSE

	if(temperature > PLASMA_UPPER_TEMPERATURE)
		temperature_scale = 1
	else
		temperature_scale = (temperature-PLASMA_MINIMUM_BURN_TEMPERATURE)/(PLASMA_UPPER_TEMPERATURE-PLASMA_MINIMUM_BURN_TEMPERATURE)
	if(temperature_scale > 0)
		oxygen_burn_rate = OXYGEN_BURN_RATE_BASE - temperature_scale
		if(air.get_moles(GAS_O2) / air.get_moles(GAS_PLASMA) > SUPER_SATURATION_THRESHOLD) //supersaturation. Form Tritium.
			super_saturation = TRUE
		if(air.get_moles(GAS_O2) > air.get_moles(GAS_PLASMA)*PLASMA_OXYGEN_FULLBURN)
			plasma_burn_rate = (air.get_moles(GAS_PLASMA)*temperature_scale)/PLASMA_BURN_RATE_DELTA
		else
			plasma_burn_rate = (temperature_scale*(air.get_moles(GAS_O2)/PLASMA_OXYGEN_FULLBURN))/PLASMA_BURN_RATE_DELTA

		if(plasma_burn_rate > MINIMUM_HEAT_CAPACITY)
			plasma_burn_rate = min(plasma_burn_rate,air.get_moles(GAS_PLASMA),air.get_moles(GAS_O2)/oxygen_burn_rate) //Ensures matter is conserved properly
			air.set_moles(GAS_PLASMA, QUANTIZE(air.get_moles(GAS_PLASMA) - plasma_burn_rate))
			air.set_moles(GAS_O2, QUANTIZE(air.get_moles(GAS_O2) - (plasma_burn_rate * oxygen_burn_rate)))
			if (super_saturation)
				air.adjust_moles(GAS_TRITIUM, plasma_burn_rate)
			else
				air.adjust_moles(GAS_CO2, plasma_burn_rate)

			energy_released += FIRE_PLASMA_ENERGY_RELEASED * (plasma_burn_rate)

			cached_results["fire"] += (plasma_burn_rate)*(1+oxygen_burn_rate)

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature((temperature*old_heat_capacity + energy_released)/new_heat_capacity)

	//let the floor know a fire is happening
	if(istype(location))
		temperature = air.return_temperature()
		if(temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
			location.hotspot_expose(temperature, CELL_VOLUME)
			for(var/I in location)
				var/atom/movable/item = I
				item.temperature_expose(air, temperature, CELL_VOLUME)
			location.temperature_expose(air, temperature, CELL_VOLUME)

	return cached_results["fire"] ? REACTING : NO_REACTION

/datum/gas_reaction/plasmafire/test()
	var/datum/gas_mixture/G = new
	G.set_moles(GAS_PLASMA,50)
	G.set_moles(GAS_O2,50)
	G.set_volume(1000)
	G.set_temperature(500)
	var/result = G.react()
	if(result != REACTING)
		return list("success" = FALSE, "message" = "Reaction didn't go at all!")
	if(!G.reaction_results["fire"])
		return list("success" = FALSE, "message" = "Plasma fires aren't setting fire results correctly!")
	if(!G.get_moles(GAS_CO2))
		return list("success" = FALSE, "message" = "Plasma fires aren't making CO2!")
	G.clear()
	G.set_moles(GAS_PLASMA,10)
	G.set_moles(GAS_O2,1000)
	G.set_temperature(500)
	result = G.react()
	if(!G.get_moles(GAS_TRITIUM))
		return list("success" = FALSE, "message" = "Plasma fires aren't making trit!")
	return ..()

/datum/gas_reaction/genericfire
	priority = -3 // very last reaction
	name = "Combustion"
	id = "genericfire"

/datum/gas_reaction/genericfire/init_reqs()
	var/lowest_fire_temp = INFINITY
	var/list/fire_temperatures = GLOB.gas_data.fire_temperatures
	for(var/gas in fire_temperatures)
		lowest_fire_temp = min(lowest_fire_temp, fire_temperatures[gas])
	var/lowest_oxi_temp = INFINITY
	var/list/oxidation_temperatures = GLOB.gas_data.oxidation_temperatures
	for(var/gas in oxidation_temperatures)
		lowest_oxi_temp = min(lowest_oxi_temp, oxidation_temperatures[gas])
	min_requirements = list(
		"TEMP" = max(lowest_oxi_temp, lowest_fire_temp),
		"FIRE_REAGENTS" = MINIMUM_MOLE_COUNT
	)

// no requirements, always runs
// bad idea? maybe
// требования по температуре и топливу из gas_data

/datum/gas_reaction/genericfire/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	var/turf/loc_turf = get_turf(holder)
	// Mining/lavaland Z: N2 is not fuel here — removes only the generic N2+O2 (air) burn; methane etc. unchanged.
	var/lavaland_block_n2 = loc_turf && is_mining_level(loc_turf.z)
	// tg-like pacing baseline: plasma combustion in tg is bounded by ~1/PLASMA_BURN_RATE_DELTA per processing step.
	var/const/MAX_GENERIC_FIRE_FRACTION_PER_TICK = (1 / PLASMA_BURN_RATE_DELTA)
	var/list/oxidation_temps = GLOB.gas_data.oxidation_temperatures
	var/list/oxidation_rates = GLOB.gas_data.oxidation_rates
	var/oxidation_power = 0
	var/list/burn_results = list()
	var/list/fuels = list()
	var/list/oxidizers = list()
	var/list/fuel_rates = GLOB.gas_data.fire_burn_rates
	var/list/fuel_temps = GLOB.gas_data.fire_temperatures
	var/total_fuel = 0
	var/energy_released = 0
	for(var/G in air.get_gases())
		var/oxidation_temp = oxidation_temps[G]
		if(oxidation_temp && temperature >= oxidation_temp)
			var/temperature_scale = max(0, 1 - (oxidation_temp / max(temperature, TCMB)))
			var/available_moles = air.get_moles(G)
			var/amt = available_moles * temperature_scale
			amt = min(amt, available_moles * MAX_GENERIC_FIRE_FRACTION_PER_TICK)
			oxidizers[G] = amt
			oxidation_power += amt * oxidation_rates[G]
		else
			var/fuel_temp = fuel_temps[G]
			if(fuel_temp && temperature >= fuel_temp)
				if(G == GAS_PLASMA || G == GAS_TRITIUM) // handled by plasmafire / tritfire
					continue
				if(lavaland_block_n2 && G == GAS_N2)
					continue
				var/available_moles = air.get_moles(G)
				var/amt = (available_moles / fuel_rates[G]) * max(0, 1 - (fuel_temp / max(temperature, TCMB)))
				amt = min(amt, available_moles * MAX_GENERIC_FIRE_FRACTION_PER_TICK)
				fuels[G] = amt // we have to calculate the actual amount we're using after we get all oxidation together
				total_fuel += amt
	if(oxidation_power <= 0 || total_fuel <= 0)
		return NO_REACTION
	var/oxidation_ratio = oxidation_power / total_fuel
	if(oxidation_ratio > 1)
		for(var/oxidizer in oxidizers)
			oxidizers[oxidizer] /= oxidation_ratio
	else if(oxidation_ratio < 1)
		for(var/fuel in fuels)
			fuels[fuel] *= oxidation_ratio
	fuels += oxidizers
	var/list/fire_products = GLOB.gas_data.fire_products
	var/list/fire_enthalpies = GLOB.gas_data.enthalpies
	for(var/fuel in fuels + oxidizers)
		var/amt = fuels[fuel]
		if(!burn_results[fuel])
			burn_results[fuel] = 0
		burn_results[fuel] -= amt
		energy_released += amt * fire_enthalpies[fuel]
		for(var/product in fire_products[fuel])
			if(!burn_results[product])
				burn_results[product] = 0
			burn_results[product] += amt
	var/final_energy = air.thermal_energy() + energy_released
	for(var/result in burn_results)
		air.adjust_moles(result, burn_results[result])
	air.set_temperature(final_energy / air.heat_capacity())
	var/list/cached_results = air.reaction_results
	cached_results["fire"] = min(total_fuel, oxidation_power) * 2
	return cached_results["fire"] ? REACTING : NO_REACTION


//fusion: a terrible idea that was fun but broken. Now reworked to be less broken and more interesting. Again (and again, and again). Again!
//Fusion Rework Counter: Please increment this if you make a major overhaul to this system again.
//6 reworks

/proc/fusion_ball(datum/holder, reaction_energy, instability)
	var/turf/open/location
	if (istype(holder,/datum/pipeline)) //Find the tile the reaction is occuring on, or a random part of the network if it's a pipenet.
		var/datum/pipeline/fusion_pipenet = holder
		location = get_turf(pick(fusion_pipenet.members))
	else
		location = get_turf(holder)
	if(location)
		var/particle_chance = ((PARTICLE_CHANCE_CONSTANT)/(reaction_energy-PARTICLE_CHANCE_CONSTANT)) + 1//Asymptopically approaches 100% as the energy of the reaction goes up.
		if(prob(PERCENT(particle_chance)))
			location.fire_nuclear_particle()
		var/rad_power = max((FUSION_RAD_COEFFICIENT/instability) + FUSION_RAD_MAX,0)
		radiation_pulse(location,rad_power)

/datum/gas_reaction/fusion
	exclude = TRUE // Disabled: reaction removed from active atmospheric gas reactions
	priority = 2
	name = "Plasmic Fusion"
	id = "fusion"

/datum/gas_reaction/fusion/init_reqs()
	min_requirements = list(
		"TEMP" = FUSION_TEMPERATURE_THRESHOLD,
		GAS_TRITIUM = FUSION_TRITIUM_MOLES_USED,
		GAS_PLASMA = FUSION_MOLE_THRESHOLD,
		GAS_CO2 = FUSION_MOLE_THRESHOLD)

/datum/gas_reaction/fusion/react(datum/gas_mixture/air, datum/holder)
	var/turf/open/location
	if (isopenturf(holder))
		return
	if (istype(holder,/datum/pipeline)) //Find the tile the reaction is occuring on, or a random part of the network if it's a pipenet.
		var/datum/pipeline/fusion_pipenet = holder
		location = get_turf(pick(fusion_pipenet.members))
	else
		location = get_turf(holder)
	if(!air.analyzer_results)
		air.analyzer_results = new
	var/list/cached_scan_results = air.analyzer_results
	var/old_heat_capacity = air.heat_capacity()
	var/reaction_energy = 0 //Reaction energy can be negative or positive, for both exothermic and endothermic reactions.
	var/initial_plasma = air.get_moles(GAS_PLASMA)
	var/initial_carbon = air.get_moles(GAS_CO2)
	var/scale_factor = (air.return_volume())/(PI) //We scale it down by volume/Pi because for fusion conditions, moles roughly = 2*volume, but we want it to be based off something constant between reactions.
	var/toroidal_size = (2*PI)+TORADIANS(arctan((air.return_volume()-TOROID_VOLUME_BREAKEVEN)/TOROID_VOLUME_BREAKEVEN)) //The size of the phase space hypertorus
	var/gas_power = 0
	var/list/gas_fusion_powers = GLOB.gas_data.fusion_powers
	for (var/gas_id in air.get_gases())
		gas_power += (gas_fusion_powers[gas_id]*air.get_moles(gas_id))
	var/instability = MODULUS((gas_power*INSTABILITY_GAS_POWER_FACTOR)**2,toroidal_size) //Instability effects how chaotic the behavior of the reaction is
	cached_scan_results["fusion"] = instability//used for analyzer feedback

	var/plasma = (initial_plasma-FUSION_MOLE_THRESHOLD)/(scale_factor) //We have to scale the amounts of carbon and plasma down a significant amount in order to show the chaotic dynamics we want
	var/carbon = (initial_carbon-FUSION_MOLE_THRESHOLD)/(scale_factor) //We also subtract out the threshold amount to make it harder for fusion to burn itself out.

	//The reaction is a specific form of the Kicked Rotator system, which displays chaotic behavior and can be used to model particle interactions.
	plasma = MODULUS(plasma - (instability*sin(TODEGREES(carbon))), toroidal_size)
	carbon = MODULUS(carbon - plasma, toroidal_size)


	air.set_moles(GAS_PLASMA, plasma*scale_factor + FUSION_MOLE_THRESHOLD) //Scales the gases back up
	air.set_moles(GAS_CO2 , carbon*scale_factor + FUSION_MOLE_THRESHOLD)
	var/delta_plasma = initial_plasma - air.get_moles(GAS_PLASMA)

	reaction_energy += delta_plasma*PLASMA_BINDING_ENERGY //Energy is gained or lost corresponding to the creation or destruction of mass.
	if(instability < FUSION_INSTABILITY_ENDOTHERMALITY)
		reaction_energy = max(reaction_energy,0) //Stable reactions don't end up endothermic.
	else if (reaction_energy < 0)
		reaction_energy *= (instability-FUSION_INSTABILITY_ENDOTHERMALITY)**0.5

	if(air.thermal_energy() + reaction_energy < 0) //No using energy that doesn't exist.
		air.set_moles(GAS_PLASMA,initial_plasma)
		air.set_moles(GAS_CO2, initial_carbon)
		return NO_REACTION
	air.adjust_moles(GAS_TRITIUM, -FUSION_TRITIUM_MOLES_USED)
	//The decay of the tritium and the reaction's energy produces waste gases, different ones depending on whether the reaction is endo or exothermic
	if(reaction_energy > 0)
		air.adjust_moles(GAS_O2, FUSION_TRITIUM_MOLES_USED*(reaction_energy*FUSION_TRITIUM_CONVERSION_COEFFICIENT))
		air.adjust_moles(GAS_NITROUS, FUSION_TRITIUM_MOLES_USED*(reaction_energy*FUSION_TRITIUM_CONVERSION_COEFFICIENT))
	else
		air.adjust_moles(GAS_BZ, FUSION_TRITIUM_MOLES_USED*(reaction_energy*-FUSION_TRITIUM_CONVERSION_COEFFICIENT))
		air.adjust_moles(GAS_NITRYL, FUSION_TRITIUM_MOLES_USED*(reaction_energy*-FUSION_TRITIUM_CONVERSION_COEFFICIENT))

	if(reaction_energy)
		if(location)
			var/particle_chance = ((PARTICLE_CHANCE_CONSTANT)/(reaction_energy-PARTICLE_CHANCE_CONSTANT)) + 1//Asymptopically approaches 100% as the energy of the reaction goes up.
			if(prob(PERCENT(particle_chance)))
				location.fire_nuclear_particle()
			var/rad_power = max((FUSION_RAD_COEFFICIENT/instability) + FUSION_RAD_MAX,0)
			radiation_pulse(location,rad_power)

		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(clamp(((air.return_temperature()*old_heat_capacity + reaction_energy)/new_heat_capacity),TCMB,INFINITY))
		return REACTING

/datum/gas_reaction/fusion/test()
	var/datum/gas_mixture/G = new
	G.set_moles(GAS_CO2,300)
	G.set_moles(GAS_PLASMA,1000)
	G.set_moles(GAS_TRITIUM,100.61)
	G.set_moles(GAS_NITRYL,1)
	G.set_temperature(15000)
	G.set_volume(1000)
	var/result = G.react()
	if(result != REACTING)
		return list("success" = FALSE, "message" = "Reaction didn't go at all!")
	if(abs(G.analyzer_results["fusion"] - 3) > 0.0000001)
		var/instability = G.analyzer_results["fusion"]
		return list("success" = FALSE, "message" = "Fusion is not calculating analyzer results correctly, should be 3.000000045, is instead [instability]")
	if(abs(G.get_moles(GAS_PLASMA) - 850.616) > 0.5)
		var/plas = G.get_moles(GAS_PLASMA)
		return list("success" = FALSE, "message" = "Fusion is not calculating plasma correctly, should be 850.616, is instead [plas]")
	if(abs(G.get_moles(GAS_CO2) - 1699.384) > 0.5)
		var/co2 = G.get_moles(GAS_CO2)
		return list("success" = FALSE, "message" = "Fusion is not calculating co2 correctly, should be 1699.384, is instead [co2]")
	if(abs(G.return_temperature() - 27600) > 200) // calculating this manually sucks dude
		var/temp = G.return_temperature()
		return list("success" = FALSE, "message" = "Fusion is not calculating temperature correctly, should be around 27600, is instead [temp]")
	return ..()

/datum/gas_reaction/nitrylformation //The formation of nitryl. Endothermic. Requires N2O as a catalyst.
	priority = 3
	name = "Nitryl formation"
	id = "nitrylformation"

/datum/gas_reaction/nitrylformation/init_reqs()
	min_requirements = list(
		GAS_O2 = 20,
		GAS_N2 = 20,
		GAS_NITROUS = 5,
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST*25
	)

/datum/gas_reaction/nitrylformation/react(datum/gas_mixture/air)
	var/temperature = air.return_temperature()

	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature/(FIRE_MINIMUM_TEMPERATURE_TO_EXIST*100),air.get_moles(GAS_O2),air.get_moles(GAS_N2))
	var/energy_used = heat_efficency*NITRYL_FORMATION_ENERGY
	if ((air.get_moles(GAS_O2) - heat_efficency < 0 )|| (air.get_moles(GAS_N2) - heat_efficency < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_O2, -heat_efficency)
	air.adjust_moles(GAS_N2, -heat_efficency)
	air.adjust_moles(GAS_NITRYL, heat_efficency*2)

	if(energy_used > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature*old_heat_capacity - energy_used)/new_heat_capacity),TCMB))
		return REACTING

/datum/gas_reaction/nitrylformation/test()
	var/datum/gas_mixture/G = new
	G.set_moles(GAS_O2,30)
	G.set_moles(GAS_N2,30)
	G.set_moles(GAS_NITROUS,10)
	G.set_volume(1000)
	G.set_temperature(150000)
	var/result = G.react()
	if(result != REACTING)
		return list("success" = FALSE, "message" = "Reaction didn't go at all!")
	if(G.get_moles(GAS_NITRYL) < 0.8)
		return list("success" = FALSE, "message" = "Nitryl isn't being generated correctly!")
	return ..()

/datum/gas_reaction/bzformation // Formation of BZ: at least 10 mol each N2O and Plasma at low pressure (optimal ~10 kPa). Plasma 2x N2O. Exothermic.
	priority = 4
	name = "BZ Gas formation"
	id = "bzformation"

/datum/gas_reaction/bzformation/init_reqs()
	min_requirements = list(
		GAS_NITROUS = 10,
		GAS_PLASMA = 10
	)


/datum/gas_reaction/bzformation/react(datum/gas_mixture/air)
	var/temperature = air.return_temperature()
	var/pressure = air.return_pressure()
	var/old_heat_capacity = air.heat_capacity()
	var/reaction_efficency = min(1/((pressure/(0.1*ONE_ATMOSPHERE))*(max(air.get_moles(GAS_PLASMA)/air.get_moles(GAS_NITROUS),1))),air.get_moles(GAS_NITROUS),air.get_moles(GAS_PLASMA)/2)
	var/energy_released = 2*reaction_efficency*FIRE_CARBON_ENERGY_RELEASED
	if ((air.get_moles(GAS_NITROUS) - reaction_efficency < 0 )|| (air.get_moles(GAS_PLASMA) - (2*reaction_efficency) < 0) || energy_released <= 0) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_BZ, reaction_efficency)
	if(reaction_efficency == air.get_moles(GAS_NITROUS))
		air.adjust_moles(GAS_BZ, -min(pressure,1))
		air.adjust_moles(GAS_O2, min(pressure,1))
	air.adjust_moles(GAS_NITROUS, -reaction_efficency)
	air.adjust_moles(GAS_PLASMA, -2*reaction_efficency)

	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, min((reaction_efficency**2)*BZ_RESEARCH_SCALE),BZ_RESEARCH_MAX_AMOUNT)

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature*old_heat_capacity + energy_released)/new_heat_capacity),TCMB))
		return REACTING

/datum/gas_reaction/bzformation/test()
	var/datum/gas_mixture/G = new
	G.set_moles(GAS_PLASMA,15)
	G.set_moles(GAS_NITROUS,15)
	G.set_volume(1000)
	G.set_temperature(10)
	var/result = G.react()
	if(result != REACTING)
		return list("success" = FALSE, "message" = "Reaction didn't go at all!")
	if(G.get_moles(GAS_BZ) < 4) // efficiency is 4.0643 and bz generation == efficiency
		return list("success" = FALSE, "message" = "BZ isn't being generated correctly!")
	return ..()

/datum/gas_reaction/stimformation //Stimulum formation follows a strange pattern of how effective it will be at a given temperature, having some multiple peaks and some large dropoffs. Exo and endo thermic.
	priority = 5
	name = "Stimulum formation"
	id = "stimformation"

/datum/gas_reaction/stimformation/init_reqs()
	min_requirements = list(
		GAS_TRITIUM = 30,
		GAS_PLASMA = 10,
		GAS_BZ = 20,
		GAS_NITRYL = 30,
		"TEMP" = STIMULUM_HEAT_SCALE/2)

/datum/gas_reaction/stimformation/react(datum/gas_mixture/air)
	var/old_heat_capacity = air.heat_capacity()
	var/heat_scale = min(air.return_temperature()/STIMULUM_HEAT_SCALE,air.get_moles(GAS_TRITIUM),air.get_moles(GAS_PLASMA),air.get_moles(GAS_NITRYL))
	var/stim_energy_change = heat_scale + STIMULUM_FIRST_RISE*(heat_scale**2) - STIMULUM_FIRST_DROP*(heat_scale**3) + STIMULUM_SECOND_RISE*(heat_scale**4) - STIMULUM_ABSOLUTE_DROP*(heat_scale**5)

	if ((air.get_moles(GAS_TRITIUM) - heat_scale < 0 )|| (air.get_moles(GAS_PLASMA) - heat_scale < 0) || (air.get_moles(GAS_NITRYL) - heat_scale < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_STIMULUM, heat_scale/10)
	air.adjust_moles(GAS_TRITIUM, -heat_scale)
	air.adjust_moles(GAS_PLASMA, -heat_scale)
	air.adjust_moles(GAS_NITRYL, -heat_scale)

	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, STIMULUM_RESEARCH_AMOUNT*max(stim_energy_change,0))
	if(stim_energy_change)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((air.return_temperature()*old_heat_capacity + stim_energy_change)/new_heat_capacity),TCMB))
		return REACTING

/datum/gas_reaction/stimformation/test()
	//above mentioned "strange pattern" is a basic quintic polynomial, it's fine, can calculate it manually
	var/datum/gas_mixture/G = new
	G.set_moles(GAS_BZ,30)
	G.set_moles(GAS_PLASMA,1000)
	G.set_moles(GAS_TRITIUM,1000)
	G.set_moles(GAS_NITRYL,1000)
	G.set_volume(1000)
	G.set_temperature(12998000) // yeah, really

	var/result = G.react()
	if(result != REACTING)
		return list("success" = FALSE, "message" = "Reaction didn't go at all!")
	if(G.get_moles(GAS_STIMULUM) < 900)
		return list("success" = FALSE, "message" = "Stimulum isn't being generated correctly!")
	return ..()

/datum/gas_reaction/nobliumformation // Hyper-Noblium at extremely low temps (below 15 K). N2 + Tritium, exothermic. 10 N2 per mol; Tritium 5 down to 0.005 with BZ.
	priority = 6
	name = "Hyper-Noblium condensation"
	id = "nobformation"

/datum/gas_reaction/nobliumformation/init_reqs()
	min_requirements = list(
		GAS_N2 = 10,
		GAS_TRITIUM = 5,
		"MAX_TEMP" = NOBLIUM_FORMATION_MAX_TEMP
	)

/datum/gas_reaction/nobliumformation/react(datum/gas_mixture/air)
	var/temperature = air.return_temperature()
	if(temperature > NOBLIUM_FORMATION_MAX_TEMP)
		return NO_REACTION
	var/n2_moles = air.get_moles(GAS_N2)
	var/tritium_moles = air.get_moles(GAS_TRITIUM)
	var/bz_moles = air.get_moles(GAS_BZ)
	// 10 N2 per mol Hyper-noblium; Tritium used = 5 * trit/(trit + 1000*bz) per mol (5 min, down to ~0.005 at 1:1000 Trit:BZ)
	var/trit_per_nob = 5 * tritium_moles / max(tritium_moles + 1000 * bz_moles, 0.001)
	var/nob_formed = min(n2_moles / 10, tritium_moles / max(trit_per_nob, 0.005))
	if(nob_formed <= 0)
		return NO_REACTION
	var/trit_consumed = nob_formed * trit_per_nob
	if(trit_consumed > tritium_moles || nob_formed * 10 > n2_moles)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	air.adjust_moles(GAS_N2, -nob_formed * 10)
	air.adjust_moles(GAS_TRITIUM, -trit_consumed)
	air.adjust_moles(GAS_HYPERNOB, nob_formed)
	// Exothermic; BZ reduces energy released
	var/energy_released = nob_formed * NOBLIUM_FORMATION_ENERGY / max(1, bz_moles * 10)
	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, nob_formed*NOBLIUM_RESEARCH_AMOUNT)
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/nobliumformation/test()
	var/datum/gas_mixture/G = new
	G.set_moles(GAS_N2, 100)
	G.set_moles(GAS_TRITIUM, 50)
	G.set_volume(1000)
	G.set_temperature(10) // below 15 K
	var/result = G.react()
	if(result != REACTING)
		return list("success" = FALSE, "message" = "Reaction didn't go at all!")
	if(abs(G.thermal_energy() - 23000000000) > 1000000) // god i hate floating points
		return list("success" = FALSE, "message" = "Hyper-nob formation isn't removing the right amount of heat! Should be 23,000,000,000, is instead [G.thermal_energy()]")
	return ..()


/datum/gas_reaction/miaster	//dry heat sterilization: sterilized into oxygen at 170°C (443.15 K)
	priority = -999 // lowest priority of all reactions
	name = "Dry Heat Sterilization"
	id = "sterilization"

/datum/gas_reaction/miaster/init_reqs()
	min_requirements = list(
		"TEMP" = T0C + 170, // 170°C
		GAS_MIASMA = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/miaster/react(datum/gas_mixture/air, datum/holder)
	// Presence of water vapor in quantities higher than 0.1 moles prevents this
	if(air.get_moles(GAS_H2O) > 0.1)
		return

	// Replace miasma with oxygen (slightly exothermic)
	var/cleaned_air = min(air.get_moles(GAS_MIASMA), 20 + (air.return_temperature() - (T0C + 170)) / 20)
	if(cleaned_air <= 0)
		return
	air.adjust_moles(GAS_MIASMA, -cleaned_air)
	air.adjust_moles(GAS_O2, cleaned_air)

	// Slightly exothermic
	air.set_temperature(air.return_temperature() + cleaned_air * 0.002)
	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, cleaned_air*MIASMA_RESEARCH_AMOUNT)
	return REACTING

/datum/gas_reaction/miaster/test()
	var/datum/gas_mixture/G = new
	G.set_moles(GAS_MIASMA,1)
	G.set_volume(1000)
	G.set_temperature(T0C + 170 + 10) // above 170°C
	var/result = G.react()
	if(result != REACTING)
		return list("success" = FALSE, "message" = "Reaction didn't go at all!")
	G.clear()
	G.set_moles(GAS_MIASMA,1)
	G.set_moles(GAS_H2O, 0.2) // >0.1 moles prevents
	G.set_temperature(T0C + 200)
	result = G.react()
	if(result != NO_REACTION)
		return list("success" = FALSE, "message" = "Miasma sterilization not stopping due to water vapor correctly!")
	return ..()

/datum/gas_reaction/nitric_oxide
	priority = -5
	name = "Nitric oxide decomposition"
	id = "nitric_oxide"

/datum/gas_reaction/nitric_oxide/init_reqs()
	min_requirements = list(
		"MAX_TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST+100,
		GAS_NITRIC = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/nitric_oxide/react(datum/gas_mixture/air, datum/holder)
	var/nitric = air.get_moles(GAS_NITRIC)
	if(nitric <= 0)
		return NO_REACTION
	var/oxygen = air.get_moles(GAS_O2)
	// Must never exceed current nitric: max(nitric/8, MINIMUM_MOLE_COUNT) alone can be > nitric (float / edge cases),
	// which would drive moles negative and crash auxmos (native illegal op).
	var/max_amount = min(nitric, max(nitric / 8, MINIMUM_MOLE_COUNT))
	var/enthalpy = air.return_temperature() * (air.heat_capacity() + R_IDEAL_GAS_EQUATION * air.total_moles())
	var/list/enthalpies = GLOB.gas_data.enthalpies
	if(oxygen > MINIMUM_MOLE_COUNT)
		var/reaction_amount = min(max_amount, oxygen) / 4
		// Second guard: do not remove more nitric than present (ordering vs other reactions).
		var/nitric_take = min(reaction_amount * 2, air.get_moles(GAS_NITRIC))
		reaction_amount = nitric_take * 0.5
		if(reaction_amount > 0)
			air.adjust_moles(GAS_NITRIC, -reaction_amount * 2)
			air.adjust_moles(GAS_O2, -reaction_amount)
			air.adjust_moles(GAS_NITRYL, reaction_amount * 2)
			enthalpy += (reaction_amount * -(enthalpies[GAS_NITRIC] - enthalpies[GAS_NITRYL]))
	var/decomp_amount = min(max_amount, air.get_moles(GAS_NITRIC))
	if(decomp_amount > 0)
		air.adjust_moles(GAS_NITRIC, -decomp_amount)
		air.adjust_moles(GAS_O2, decomp_amount * 0.5)
		air.adjust_moles(GAS_N2, decomp_amount * 0.5)
		enthalpy += decomp_amount * -enthalpies[GAS_NITRIC]
	var/denom = air.heat_capacity() + R_IDEAL_GAS_EQUATION * air.total_moles()
	if(denom > MINIMUM_HEAT_CAPACITY)
		var/new_temp = enthalpy / denom
		if(isnum(new_temp) && new_temp > TCMB)
			air.set_temperature(new_temp)
	return REACTING

/datum/gas_reaction/hagedorn
	priority = -INFINITY
	name = "Hagedorn decomposition"
	id = "hagedorn"

/datum/gas_reaction/hagedorn/init_reqs()
	min_requirements = list(
		"TEMP" = 2e12 // 2 trillion kelvins
	)

/datum/gas_reaction/hagedorn/react(datum/gas_mixture/air, datum/holder)
	var/initial_energy = air.thermal_energy()
	if(air.get_moles(GAS_QCD))
		return
	for(var/g in air.get_gases())
		air.set_moles(g, 0)
	var/amount = initial_energy / (air.return_temperature() * GLOB.gas_data.specific_heats[GAS_QCD])
	air.set_moles(GAS_QCD, amount)
	var/list/largest_values = SSresearch.science_tech.largest_values
	if(!(GAS_QCD in largest_values))
		largest_values[GAS_QCD] = 0
	var/previous_largest = largest_values[GAS_QCD]
	var/research_amount = min(amount * QCD_RESEARCH_AMOUNT, 100000)
	if(previous_largest <= research_amount)
		SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, research_amount)
		largest_values[GAS_QCD] = research_amount
	else
		SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, research_amount / 100)

/datum/gas_reaction/dehagedorn
	priority = 50
	name = "Hagedorn condensation"
	id = "dehagedorn"

/datum/gas_reaction/dehagedorn/init_reqs()
	min_requirements = list(
		"MAX_TEMP" = 1.99e12,
		GAS_QCD = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/dehagedorn/react(datum/gas_mixture/air, datum/holder)
	var/initial_energy = air.thermal_energy()
	var/energy_remaining = initial_energy
	air.set_moles(GAS_QCD, 0)
	air.set_temperature(min(air.return_temperature(), 1.8e12))
	var/new_temp = air.return_temperature()
	var/list/gases = GLOB.gas_data.specific_heats.Copy()
	gases -= GAS_QCD
	gases -= GAS_TRITIUM // no refusing sorry
	gases -= GAS_HYPERNOB // makes it waaay too easy to stabilize it
	while(energy_remaining > 0)
		var/G = pick(gases)
		air.adjust_moles(G, max(0.1, energy_remaining / (gases[G] * new_temp * 20)))
		energy_remaining = initial_energy - air.thermal_energy()
	air.set_temperature(initial_energy / air.heat_capacity())
	return REACTING

// === Fusion/exotic gas reactions — синтез вручную, полная картина атмоса ===

/datum/gas_reaction/freonfire
	priority = -12
	name = "Freon Combustion"
	id = "freonfire"

/datum/gas_reaction/freonfire/init_reqs()
	min_requirements = list(
		GAS_O2 = MINIMUM_MOLE_COUNT,
		GAS_FREON = MINIMUM_MOLE_COUNT,
		"TEMP" = FREON_TERMINAL_TEMPERATURE
	)

/datum/gas_reaction/freonfire/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	var/max_burn_temp = FREON_MAXIMUM_BURN_TEMPERATURE
	if(air.get_moles(GAS_PROTO_NITRATE) > MINIMUM_MOLE_COUNT)
		max_burn_temp = FREON_CATALYST_MAX_TEMPERATURE
	if(temperature > max_burn_temp)
		return NO_REACTION
	var/temperature_scale
	if(temperature < FREON_TERMINAL_TEMPERATURE)
		temperature_scale = 0
	else if(temperature < FREON_LOWER_TEMPERATURE)
		temperature_scale = 0.5
	else
		temperature_scale = (max_burn_temp - temperature) / (max_burn_temp - FREON_TERMINAL_TEMPERATURE)
	if(temperature_scale <= 0)
		return NO_REACTION
	var/oxygen_burn_ratio = OXYGEN_BURN_RATIO_BASE - temperature_scale
	var/freon_moles = air.get_moles(GAS_FREON)
	var/oxygen_moles = air.get_moles(GAS_O2)
	var/freon_burn_rate
	if(oxygen_moles < freon_moles * FREON_OXYGEN_FULLBURN)
		freon_burn_rate = ((oxygen_moles / FREON_OXYGEN_FULLBURN) / FREON_BURN_RATE_DELTA) * temperature_scale
	else
		freon_burn_rate = (freon_moles / FREON_BURN_RATE_DELTA) * temperature_scale
	if(freon_burn_rate < MINIMUM_HEAT_CAPACITY)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	freon_burn_rate = min(freon_burn_rate, freon_moles, oxygen_moles * INVERSE(oxygen_burn_ratio))
	air.adjust_moles(GAS_FREON, -freon_burn_rate)
	air.adjust_moles(GAS_O2, -(freon_burn_rate * oxygen_burn_ratio))
	air.adjust_moles(GAS_CO2, freon_burn_rate)
	var/energy_consumed = FIRE_FREON_ENERGY_CONSUMED * freon_burn_rate
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity - energy_consumed) / new_heat_capacity, TCMB))
	if(isopenturf(holder) && temperature >= FREON_HOT_ICE_MIN_TEMP && temperature <= FREON_HOT_ICE_MAX_TEMP && prob(5))
		new /obj/item/stack/sheet/hot_ice(get_turf(holder), 1)
	return REACTING

/datum/gas_reaction/freonformation
	priority = 33
	name = "Freon Formation"
	id = "freonformation"

/datum/gas_reaction/freonformation/init_reqs()
	min_requirements = list(
		GAS_PLASMA = MINIMUM_MOLE_COUNT,
		GAS_CO2 = MINIMUM_MOLE_COUNT,
		GAS_BZ = MINIMUM_MOLE_COUNT,
		"TEMP" = FREON_FORMATION_MIN_TEMPERATURE
	)

/datum/gas_reaction/freonformation/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	var/plasma_moles = air.get_moles(GAS_PLASMA)
	var/co2_moles = air.get_moles(GAS_CO2)
	var/bz_moles = air.get_moles(GAS_BZ)
	var/heat_factor = (temperature - FREON_FORMATION_MIN_TEMPERATURE) / 100
	var/minimal_mole_factor = min(plasma_moles / 0.6, co2_moles / 0.3, bz_moles / 0.1)
	var/reaction_units = min(heat_factor * minimal_mole_factor * 0.05, plasma_moles * INVERSE(0.6), co2_moles * INVERSE(0.3), bz_moles * INVERSE(0.1))
	if(reaction_units <= 0)
		return NO_REACTION
	air.adjust_moles(GAS_PLASMA, -reaction_units * 0.6)
	air.adjust_moles(GAS_CO2, -reaction_units * 0.3)
	air.adjust_moles(GAS_BZ, -reaction_units * 0.1)
	air.adjust_moles(GAS_FREON, reaction_units * 10)
	var/old_heat_capacity = air.heat_capacity()
	var/energy_consumed = FREON_FORMATION_ENERGY_CONSUMED * reaction_units
	if(old_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((air.return_temperature() * old_heat_capacity - energy_consumed) / air.heat_capacity(), TCMB))
	return REACTING

/datum/gas_reaction/halon_o2removal
	priority = 22
	name = "Halon Oxygen Absorption"
	id = "halon_o2removal"

/datum/gas_reaction/halon_o2removal/init_reqs()
	min_requirements = list(
		GAS_HALON = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT,
		"TEMP" = HALON_COMBUSTION_MIN_TEMPERATURE
	)

/datum/gas_reaction/halon_o2removal/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	var/halon_moles = air.get_moles(GAS_HALON)
	var/oxygen_moles = air.get_moles(GAS_O2)
	var/heat_efficiency = min(temperature / HALON_COMBUSTION_TEMPERATURE_SCALE, halon_moles, oxygen_moles * INVERSE(20))
	if(heat_efficiency <= 0)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	air.adjust_moles(GAS_HALON, -heat_efficiency)
	air.adjust_moles(GAS_O2, -(heat_efficiency * 20))
	air.adjust_moles(GAS_PLUOXIUM, heat_efficiency * 2.5)
	var/energy_used = heat_efficiency * HALON_COMBUSTION_ENERGY
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity - energy_used) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/healium_formation
	priority = 34
	name = "Healium Formation"
	id = "healium_formation"

/datum/gas_reaction/healium_formation/init_reqs()
	min_requirements = list(
		GAS_BZ = MINIMUM_MOLE_COUNT,
		GAS_FREON = MINIMUM_MOLE_COUNT,
		"TEMP" = HEALIUM_FORMATION_MIN_TEMP
	)

/datum/gas_reaction/healium_formation/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	if(temperature > HEALIUM_FORMATION_MAX_TEMP)
		return NO_REACTION
	var/freon_moles = air.get_moles(GAS_FREON)
	var/bz_moles = air.get_moles(GAS_BZ)
	var/heat_efficiency = min(temperature * 0.3, freon_moles * INVERSE(2.75), bz_moles * INVERSE(0.25))
	if(heat_efficiency <= 0)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	air.adjust_moles(GAS_FREON, -heat_efficiency * 2.75)
	air.adjust_moles(GAS_BZ, -heat_efficiency * 0.25)
	air.adjust_moles(GAS_HEALIUM, heat_efficiency * 3)
	var/energy_released = heat_efficiency * HEALIUM_FORMATION_ENERGY
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/zauker_formation
	priority = 35
	name = "Zauker Formation"
	id = "zauker_formation"

/datum/gas_reaction/zauker_formation/init_reqs()
	min_requirements = list(
		GAS_HYPERNOB = MINIMUM_MOLE_COUNT,
		GAS_NITRIUM = MINIMUM_MOLE_COUNT,
		"TEMP" = ZAUKER_FORMATION_MIN_TEMPERATURE
	)

/datum/gas_reaction/zauker_formation/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	if(temperature > ZAUKER_FORMATION_MAX_TEMPERATURE)
		return NO_REACTION
	var/hypernob_moles = air.get_moles(GAS_HYPERNOB)
	var/nitrium_moles = air.get_moles(GAS_NITRIUM)
	var/heat_efficiency = min(temperature * ZAUKER_FORMATION_TEMPERATURE_SCALE, hypernob_moles * INVERSE(0.01), nitrium_moles * INVERSE(0.5))
	if(heat_efficiency <= 0)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	air.adjust_moles(GAS_HYPERNOB, -heat_efficiency * 0.01)
	air.adjust_moles(GAS_NITRIUM, -heat_efficiency * 0.5)
	air.adjust_moles(GAS_ZAUKER, heat_efficiency * 0.5)
	var/energy_used = heat_efficiency * ZAUKER_FORMATION_ENERGY
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity - energy_used) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/zauker_decomp
	priority = 23
	name = "Zauker Decomposition"
	id = "zauker_decomp"

/datum/gas_reaction/zauker_decomp/init_reqs()
	min_requirements = list(
		GAS_ZAUKER = MINIMUM_MOLE_COUNT,
		GAS_N2 = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/zauker_decomp/react(datum/gas_mixture/air, datum/holder)
	var/n2_moles = air.get_moles(GAS_N2)
	var/zauker_moles = air.get_moles(GAS_ZAUKER)
	var/burned_fuel = min(ZAUKER_DECOMPOSITION_MAX_RATE, n2_moles, zauker_moles)
	if(burned_fuel <= 0)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	air.adjust_moles(GAS_ZAUKER, -burned_fuel)
	air.adjust_moles(GAS_O2, burned_fuel * 0.3)
	air.adjust_moles(GAS_N2, burned_fuel * 0.7)
	var/energy_released = ZAUKER_DECOMPOSITION_ENERGY * burned_fuel
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/nitrium_formation
	priority = 36
	name = "Nitrium Formation"
	id = "nitrium_formation"

/datum/gas_reaction/nitrium_formation/init_reqs()
	min_requirements = list(
		GAS_TRITIUM = 20,
		GAS_N2 = 10,
		GAS_BZ = 5,
		"TEMP" = NITRIUM_FORMATION_MIN_TEMP
	)

/datum/gas_reaction/nitrium_formation/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	var/tritium_moles = air.get_moles(GAS_TRITIUM)
	var/n2_moles = air.get_moles(GAS_N2)
	var/bz_moles = air.get_moles(GAS_BZ)
	var/heat_efficiency = min(temperature / NITRIUM_FORMATION_TEMP_DIVISOR, tritium_moles, n2_moles, bz_moles * INVERSE(0.05))
	if(heat_efficiency <= 0)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	air.adjust_moles(GAS_TRITIUM, -heat_efficiency)
	air.adjust_moles(GAS_N2, -heat_efficiency)
	air.adjust_moles(GAS_BZ, -heat_efficiency * 0.05)
	air.adjust_moles(GAS_NITRIUM, heat_efficiency)
	var/energy_used = heat_efficiency * NITRIUM_FORMATION_ENERGY
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity - energy_used) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/nitrium_decomposition
	priority = 24
	name = "Nitrium Decomposition"
	id = "nitrium_decomp"

/datum/gas_reaction/nitrium_decomposition/init_reqs()
	min_requirements = list(
		GAS_NITRIUM = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT, // decomposes when in contact with Oxygen
		"TEMP" = 1
	)

/datum/gas_reaction/nitrium_decomposition/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	if(temperature > NITRIUM_DECOMPOSITION_MAX_TEMP)
		return NO_REACTION
	var/nitrium_moles = air.get_moles(GAS_NITRIUM)
	var/heat_efficiency = min(temperature / NITRIUM_DECOMPOSITION_TEMP_DIVISOR, nitrium_moles)
	if(heat_efficiency <= 0)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	air.adjust_moles(GAS_NITRIUM, -heat_efficiency)
	air.adjust_moles(GAS_N2, heat_efficiency)
	air.adjust_moles(GAS_HYDROGEN, heat_efficiency)
	var/energy_released = heat_efficiency * NITRIUM_DECOMPOSITION_ENERGY
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/pluox_formation
	priority = 37
	name = "Pluoxium Formation"
	id = "pluox_formation"

/datum/gas_reaction/pluox_formation/init_reqs()
	min_requirements = list(
		GAS_CO2 = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT,
		GAS_TRITIUM = MINIMUM_MOLE_COUNT,
		"TEMP" = PLUOXIUM_FORMATION_MIN_TEMP
	)

/datum/gas_reaction/pluox_formation/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	if(temperature > PLUOXIUM_FORMATION_MAX_TEMP)
		return NO_REACTION
	var/co2_moles = air.get_moles(GAS_CO2)
	var/o2_moles = air.get_moles(GAS_O2)
	var/tritium_moles = air.get_moles(GAS_TRITIUM)
	// Consumption ratio 100 O2 : 50 CO2 : 1 Tritium per 50 pluoxium (i.e. 2 O2 : 1 CO2 : 0.01 Trit per 1 pluox)
	var/produced_amount = min(PLUOXIUM_FORMATION_MAX_RATE, o2_moles * 0.5, co2_moles, tritium_moles * INVERSE(0.01))
	if(produced_amount <= 0)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	air.adjust_moles(GAS_CO2, -produced_amount)
	air.adjust_moles(GAS_O2, -produced_amount * 2)
	air.adjust_moles(GAS_TRITIUM, -produced_amount * 0.01)
	air.adjust_moles(GAS_PLUOXIUM, produced_amount)
	air.adjust_moles(GAS_HYDROGEN, produced_amount * 0.01) // 1% H2 byproduct
	var/energy_released = produced_amount * PLUOXIUM_FORMATION_ENERGY
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/proto_nitrate_formation
	priority = 38
	name = "Proto Nitrate Formation"
	id = "proto_nitrate_formation"

/datum/gas_reaction/proto_nitrate_formation/init_reqs()
	min_requirements = list(
		GAS_PLUOXIUM = MINIMUM_MOLE_COUNT,
		GAS_HYDROGEN = MINIMUM_MOLE_COUNT,
		"TEMP" = PN_FORMATION_MIN_TEMPERATURE
	)

/datum/gas_reaction/proto_nitrate_formation/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	if(temperature > PN_FORMATION_MAX_TEMPERATURE)
		return NO_REACTION
	var/pluox_moles = air.get_moles(GAS_PLUOXIUM)
	var/h2_moles = air.get_moles(GAS_HYDROGEN)
	var/heat_efficiency = min(temperature * 0.005, pluox_moles * INVERSE(0.2), h2_moles * INVERSE(2))
	if(heat_efficiency <= 0)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	air.adjust_moles(GAS_HYDROGEN, -heat_efficiency * 2)
	air.adjust_moles(GAS_PLUOXIUM, -heat_efficiency * 0.2)
	air.adjust_moles(GAS_PROTO_NITRATE, heat_efficiency * 2.2)
	var/energy_released = heat_efficiency * PN_FORMATION_ENERGY
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/proto_nitrate_hydrogen_response
	priority = 25
	name = "Proto Nitrate Hydrogen Response"
	id = "proto_nitrate_hydrogen_response"

/datum/gas_reaction/proto_nitrate_hydrogen_response/init_reqs()
	min_requirements = list(
		GAS_PROTO_NITRATE = MINIMUM_MOLE_COUNT,
		GAS_HYDROGEN = PN_HYDROGEN_CONVERSION_THRESHOLD
	)

/datum/gas_reaction/proto_nitrate_hydrogen_response/react(datum/gas_mixture/air, datum/holder)
	var/proto_moles = air.get_moles(GAS_PROTO_NITRATE)
	var/h2_moles = air.get_moles(GAS_HYDROGEN)
	var/produced_amount = min(PN_HYDROGEN_CONVERSION_MAX_RATE, h2_moles, proto_moles)
	if(produced_amount <= 0)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	air.adjust_moles(GAS_HYDROGEN, -produced_amount)
	air.adjust_moles(GAS_PROTO_NITRATE, produced_amount * 0.5)
	var/energy_used = produced_amount * PN_HYDROGEN_CONVERSION_ENERGY
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity - energy_used) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/proto_nitrate_tritium_response
	priority = 26
	name = "Proto Nitrate Tritium Response"
	id = "proto_nitrate_tritium_response"

/datum/gas_reaction/proto_nitrate_tritium_response/init_reqs()
	min_requirements = list(
		GAS_PROTO_NITRATE = MINIMUM_MOLE_COUNT,
		GAS_TRITIUM = MINIMUM_MOLE_COUNT,
		"TEMP" = PN_TRITIUM_CONVERSION_MIN_TEMP
	)

/datum/gas_reaction/proto_nitrate_tritium_response/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	if(temperature > PN_TRITIUM_CONVERSION_MAX_TEMP)
		return NO_REACTION
	var/proto_moles = air.get_moles(GAS_PROTO_NITRATE)
	var/tritium_moles = air.get_moles(GAS_TRITIUM)
	var/produced_amount = min(temperature / 34 * (tritium_moles * proto_moles) / (tritium_moles + 10 * proto_moles), tritium_moles, proto_moles * INVERSE(0.01))
	if(produced_amount <= 0)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	air.adjust_moles(GAS_PROTO_NITRATE, -produced_amount * 0.01)
	air.adjust_moles(GAS_TRITIUM, -produced_amount)
	air.adjust_moles(GAS_HYDROGEN, produced_amount)
	var/energy_released = produced_amount * PN_TRITIUM_CONVERSION_ENERGY
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/proto_nitrate_bz_response
	priority = 27
	name = "Proto Nitrate BZ Response"
	id = "proto_nitrate_bz_response"

/datum/gas_reaction/proto_nitrate_bz_response/init_reqs()
	min_requirements = list(
		GAS_PROTO_NITRATE = MINIMUM_MOLE_COUNT,
		GAS_BZ = MINIMUM_MOLE_COUNT,
		"TEMP" = PN_BZASE_MIN_TEMP
	)

/datum/gas_reaction/proto_nitrate_bz_response/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	if(temperature > PN_BZASE_MAX_TEMP)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	var/proto_moles = air.get_moles(GAS_PROTO_NITRATE)
	var/bz_moles = air.get_moles(GAS_BZ)
	var/consumed_amount = min(temperature / 2240 * bz_moles * proto_moles / (bz_moles + proto_moles), bz_moles, proto_moles)
	if(consumed_amount <= 0)
		return NO_REACTION
	air.adjust_moles(GAS_BZ, -consumed_amount)
	air.adjust_moles(GAS_PROTO_NITRATE, -consumed_amount)
	air.adjust_moles(GAS_N2, consumed_amount * 0.4)
	air.adjust_moles(GAS_HELIUM, consumed_amount * 1.6)
	air.adjust_moles(GAS_PLASMA, consumed_amount * 0.8)
	var/energy_released = consumed_amount * PN_BZASE_ENERGY
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/antinoblium_replication
	priority = 40
	name = "Antinoblium Replication"
	id = "antinoblium_replication"

/datum/gas_reaction/antinoblium_replication/init_reqs()
	min_requirements = list(
		GAS_ANTINOBLIUM = MOLES_GAS_VISIBLE,
		"TEMP" = REACTION_OPPRESSION_MIN_TEMP
	)

/datum/gas_reaction/antinoblium_replication/react(datum/gas_mixture/air, datum/holder)
	var/old_heat_capacity = air.heat_capacity()
	var/total_moles = air.total_moles()
	var/antinoblium_moles = air.get_moles(GAS_ANTINOBLIUM)
	var/total_not_antinoblium_moles = total_moles - antinoblium_moles
	if(total_not_antinoblium_moles < MINIMUM_MOLE_COUNT)
		return NO_REACTION
	var/reaction_rate = min(antinoblium_moles / ANTINOBLIUM_CONVERSION_DIVISOR, total_not_antinoblium_moles)
	var/list/gases = air.get_gases()
	for(var/g in gases)
		if(g == GAS_ANTINOBLIUM)
			continue
		var/m = air.get_moles(g)
		if(m > 0)
			air.adjust_moles(g, -reaction_rate * (m / total_not_antinoblium_moles))
	air.adjust_moles(GAS_ANTINOBLIUM, reaction_rate)
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max(air.return_temperature() * old_heat_capacity / new_heat_capacity, TCMB))
	return REACTING
