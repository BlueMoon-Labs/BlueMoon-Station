GLOBAL_LIST_EMPTY(reaction_handbook)
GLOBAL_LIST_EMPTY(gas_handbook)

/// Builds factor metadata for the atmos handbook from a reaction's factor list.
/proc/atmos_handbook_parse_factors(list/factors, list/momentary_gas_list, reaction_id, reaction_name, list/reaction_info)
	for(var/factor in factors)
		var/list/factor_info = list()
		factor_info["desc"] = factors[factor]

		var/list/gas_info = momentary_gas_list[factor]
		if(gas_info)
			gas_info["reactions"][reaction_id] = reaction_name
			factor_info["factor_id"] = gas_info["id"]
			factor_info["factor_type"] = "gas"
			factor_info["factor_name"] = gas_info["name"]
		else
			factor_info["factor_name"] = factor
			factor_info["factor_type"] = "misc"
			if(factor == "Temperature" || factor == "Pressure")
				factor_info["tooltip"] = "Reaction is influenced by the [lowertext(factor)] of the place where the reaction is occurring."
			else if(factor == "Energy")
				factor_info["tooltip"] = "Energy released or absorbed by the reaction; actual temperature change depends on heat capacity and other gases present."
			else if(factor == "Radiation")
				factor_info["tooltip"] = "This reaction emits dangerous radiation! Take precautions."
			else if(factor == "Location")
				factor_info["tooltip"] = "This reaction has special behaviour when occurring on an open turf."

		reaction_info["factors"] += list(factor_info)

/// Populates GLOB.gas_handbook and GLOB.reaction_handbook for UIs (AtmoZphere handbook tab).
/proc/atmos_handbooks_init()
	GLOB.reaction_handbook = list()
	GLOB.gas_handbook = list()

	var/list/momentary_gas_list = list()
	for(var/gas_path in subtypesof(/datum/gas))
		var/datum/gas/gas = new gas_path
		var/list/gas_info = list()
		gas_info["id"] = gas.id
		gas_info["name"] = gas.name
		gas_info["description"] = ""
		gas_info["specific_heat"] = gas.specific_heat
		gas_info["reactions"] = list()
		momentary_gas_list[gas_path] = gas_info
		momentary_gas_list[gas.id] = gas_info

	for(var/reaction_path in subtypesof(/datum/gas_reaction))
		var/datum/gas_reaction/reaction = new reaction_path
		if(reaction.exclude && reaction.id == "condense")
			qdel(reaction)
			continue
		var/list/reaction_info = list()
		reaction_info["id"] = reaction.id
		reaction_info["name"] = reaction.name
		reaction_info["description"] = reaction.desc
		if(reaction.exclude)
			reaction_info["disabled"] = TRUE
		reaction_info["factors"] = list()
		atmos_handbook_parse_factors(reaction.factor, momentary_gas_list, reaction.id, reaction.name, reaction_info)
		GLOB.reaction_handbook += list(reaction_info)
		qdel(reaction)

	for(var/reaction_path in subtypesof(/datum/electrolyzer_reaction))
		var/datum/electrolyzer_reaction/reaction = new reaction_path
		var/list/reaction_info = list()
		reaction_info["id"] = reaction.id
		reaction_info["name"] = reaction.name
		reaction_info["description"] = reaction.desc
		reaction_info["factors"] = list()
		atmos_handbook_parse_factors(reaction.factor, momentary_gas_list, reaction.id, reaction.name, reaction_info)
		GLOB.reaction_handbook += list(reaction_info)
		qdel(reaction)

	for(var/gas_path in momentary_gas_list)
		if(!ispath(gas_path, /datum/gas))
			continue
		GLOB.gas_handbook += list(momentary_gas_list[gas_path])

/// Returns handbook data for TGUI static payloads.
/proc/return_atmos_handbooks()
	return list(
		"gasInfo" = GLOB.gas_handbook,
		"reactionInfo" = GLOB.reaction_handbook,
	)
