/datum/pipeline
	var/datum/gas_mixture/air
	var/list/datum/gas_mixture/other_airs

	var/list/obj/machinery/atmospherics/pipe/members
	var/list/obj/machinery/atmospherics/components/other_atmosmch

	var/update = TRUE

/datum/pipeline/New()
	other_airs = list()
	members = list()
	other_atmosmch = list()
	SSair.networks += src

/datum/pipeline/Destroy()
	SSair.networks -= src
	if(air?.return_volume())  //	BLUEMOON EDIT: TODO:runtime
		temporarily_store_air()
	for(var/obj/machinery/atmospherics/pipe/P as anything in members)
		P.parent = null
	for(var/obj/machinery/atmospherics/components/C as anything in other_atmosmch)
		if(!C.parents)
			continue
		for(var/i in 1 to length(C.parents))
			if(C.parents[i] == src)
				C.parents[i] = null
	members.Cut()
	other_atmosmch.Cut()
	other_airs.Cut()
	air = null
	return ..()

/datum/pipeline/process()
	if(!update)	//	BLUEMOON EDIT: TODO:runtime
		return	//	BLUEMOON EDIT: TODO:runtime
	update = FALSE
	reconcile_air()
	update = air?.react(src)

/datum/pipeline/proc/build_pipeline(obj/machinery/atmospherics/base)
	if(QDELETED(base))
		stack_trace("build_pipeline() called with QDELETED base [base?.type] at [base ? COORD(base) : "null"]")
		return
	var/volume = 0
	if(istype(base, /obj/machinery/atmospherics/pipe))
		var/obj/machinery/atmospherics/pipe/E = base
		volume = E.volume
		members += E
		if(E.air_temporary)
			air = E.air_temporary
			E.air_temporary = null
	else
		addMachineryMember(base)
	if(!air)
		air = new
	var/list/possible_expansions = list(base)
	while(possible_expansions.len>0)
		for(var/obj/machinery/atmospherics/borderline in possible_expansions)

			var/list/result = borderline.pipeline_expansion(src)

			if(result.len>0)
				for(var/obj/machinery/atmospherics/P in result)
					if(istype(P, /obj/machinery/atmospherics/pipe))
						var/obj/machinery/atmospherics/pipe/item = P
						if(!members.Find(item))

							if(item.parent)
								var/static/pipenetwarnings = 10
								if(pipenetwarnings > 0)
									log_mapping("build_pipeline(): [item.type] added to a pipenet while still having one. (pipes leading to the same spot stacking in one turf) Nearby: ([item.x], [item.y], [item.z]).")
									pipenetwarnings -= 1
									if(pipenetwarnings == 0)
										log_mapping("build_pipeline(): further messages about pipenets will be suppressed")
							members += item
							possible_expansions += item

							volume += item.volume
							item.parent = src

							if(item.air_temporary)
								air.merge(item.air_temporary)
								item.air_temporary = null
					else
						P.setPipenet(src, borderline)
						addMachineryMember(P)

			possible_expansions -= borderline

	air.set_volume(volume)

/**
 *  For a machine to properly "connect" to a pipeline and share gases,
 *  the pipeline needs to acknowledge a gas mixture as its member.
 *  This is currently handled by the other_airs list in the pipeline datum.
 *
 *	Other_airs itself is populated by gas mixtures through the parents list that each machineries have.
 *	This parents list is populated when a machinery calls update_parents and is then added into the queue by the controller.
 */
/datum/pipeline/proc/addMachineryMember(obj/machinery/atmospherics/components/C)
	other_atmosmch |= C
	var/list/returned_airs = C.returnPipenetAirs(src)
	if (!length(returned_airs) || (null in returned_airs))
		stack_trace("addMachineryMember: Nonexistent (empty list) or null machinery gasmix added to pipeline datum from [C] \
		which is of type [C.type]. Nearby: ([C.x], [C.y], [C.z])")
		listclearnulls(returned_airs)
	other_airs |= returned_airs

/datum/pipeline/proc/addMember(obj/machinery/atmospherics/A, obj/machinery/atmospherics/N)
	if(istype(A, /obj/machinery/atmospherics/pipe))
		var/obj/machinery/atmospherics/pipe/P = A
		if(P.parent)
			merge(P.parent)
		P.parent = src
		var/list/adjacent = P.pipeline_expansion()
		for(var/obj/machinery/atmospherics/pipe/I in adjacent)
			if(I.parent == src)
				continue
			var/datum/pipeline/E = I.parent
			merge(E)
		if(!members.Find(P))
			members += P
			air.set_volume(air.return_volume() + P.volume)
	else
		A.setPipenet(src, N)
		addMachineryMember(A)

/datum/pipeline/proc/merge(datum/pipeline/E)
	if(E == src)
		return
	air.set_volume(air.return_volume() + E.air.return_volume())
	members.Add(E.members)
	for(var/obj/machinery/atmospherics/pipe/S as anything in E.members)
		S.parent = src
	air.merge(E.air)
	for(var/obj/machinery/atmospherics/components/C as anything in E.other_atmosmch)
		C.replacePipenet(E, src)
	other_atmosmch |= E.other_atmosmch
	if(null in E.other_airs)
		stack_trace("merge(): Pipeline [E]([REF(E)]) contains null gas mixtures in other_airs. Cleaning before merge.")
		listclearnulls(E.other_airs)
	other_airs |= E.other_airs
	E.members.Cut()
	E.other_atmosmch.Cut()
	update = TRUE
	qdel(E)

/obj/machinery/atmospherics/proc/addMember(obj/machinery/atmospherics/A)
	return

/obj/machinery/atmospherics/pipe/addMember(obj/machinery/atmospherics/A)
	parent.addMember(A, src)

/obj/machinery/atmospherics/components/addMember(obj/machinery/atmospherics/A)
	var/datum/pipeline/P = returnPipenet(A)
	if(!P)
		CRASH("null.addMember() called by [type] on [COORD(src)]")
	P.addMember(A, src)


/datum/pipeline/proc/temporarily_store_air()
	//Update individual gas_mixtures by volume ratio

	for(var/obj/machinery/atmospherics/pipe/member as anything in members)
		member.air_temporary = new
		member.air_temporary.set_volume(member.volume)
		member.air_temporary.copy_from(air)

		member.air_temporary.multiply(member.volume/air.return_volume())

		member.air_temporary.set_temperature(air.return_temperature())

/datum/pipeline/proc/temperature_interact(turf/target, share_volume, thermal_conductivity)
	var/total_heat_capacity = air.heat_capacity()
	var/partial_heat_capacity = total_heat_capacity*(share_volume/air.return_volume())
	var/target_temperature
	var/target_heat_capacity

	if(isopenturf(target))

		var/turf/open/modeled_location = target
		target_temperature = modeled_location.GetTemperature()
		target_heat_capacity = modeled_location.GetHeatCapacity()

		if(modeled_location.blocks_air)

			if((modeled_location.heat_capacity>0) && (partial_heat_capacity>0))
				var/delta_temperature = air.return_temperature() - target_temperature

				var/heat = thermal_conductivity*delta_temperature* \
					(partial_heat_capacity*target_heat_capacity/(partial_heat_capacity+target_heat_capacity))

				air.set_temperature(air.return_temperature() - heat/total_heat_capacity)
				modeled_location.TakeTemperature(heat/target_heat_capacity)

		else
			var/delta_temperature = 0
			var/sharer_heat_capacity = 0

			delta_temperature = (air.return_temperature() - target_temperature)
			sharer_heat_capacity = target_heat_capacity

			var/self_temperature_delta = 0
			var/sharer_temperature_delta = 0

			if((sharer_heat_capacity>0) && (partial_heat_capacity>0))
				var/heat = thermal_conductivity*delta_temperature* \
					(partial_heat_capacity*sharer_heat_capacity/(partial_heat_capacity+sharer_heat_capacity))

				self_temperature_delta = -heat/total_heat_capacity
				sharer_temperature_delta = heat/sharer_heat_capacity
			else
				return TRUE

			air.set_temperature(air.return_temperature() + self_temperature_delta)
			modeled_location.TakeTemperature(sharer_temperature_delta)


	else
		if((target.heat_capacity>0) && (partial_heat_capacity>0))
			var/delta_temperature = air.return_temperature() - target.return_temperature()

			var/heat = thermal_conductivity*delta_temperature* \
				(partial_heat_capacity*target.heat_capacity/(partial_heat_capacity+target.heat_capacity))

			air.set_temperature(air.return_temperature() - heat/total_heat_capacity)
	update = TRUE

/datum/pipeline/proc/return_air()
	. = other_airs.Copy()
	if(air)
		. += air
	if(null in .)
		listclearnulls(.)
		stack_trace("[src]([REF(src)]) has one or more null gas mixtures, which may cause bugs. Null mixtures will not be considered in reconcile_air().")

/datum/pipeline/proc/empty()
	for(var/datum/gas_mixture/GM in get_all_connected_airs())
		GM.clear()

/datum/pipeline/proc/get_all_connected_airs()
	var/list/datum/gas_mixture/GL = list()
	var/list/datum/pipeline/PL = list()
	PL += src

	for(var/i = 1; i <= PL.len; i++) //can't do a for-each here because we may add to the list within the loop
		var/datum/pipeline/P = PL[i]
		if(!P)
			continue
		if(length(P.other_airs))
			GL += P.other_airs
		if(P.air)
			GL += P.air
		for(var/obj/machinery/atmospherics/components/atmosmch as anything in P.other_atmosmch)
			if (istype(atmosmch, /obj/machinery/atmospherics/components/binary/valve))
				var/obj/machinery/atmospherics/components/binary/valve/V = atmosmch
				if(V.on)
					PL |= V.parents[1]
					PL |= V.parents[2]
			else if (istype(atmosmch,/obj/machinery/atmospherics/components/binary/relief_valve))
				var/obj/machinery/atmospherics/components/binary/relief_valve/V = atmosmch
				if(V.opened)
					PL |= V.parents[1]
					PL |= V.parents[2]
			else if (istype(atmosmch, /obj/machinery/atmospherics/components/unary/portables_connector))
				var/obj/machinery/atmospherics/components/unary/portables_connector/C = atmosmch
				if(C.connected_device)
					GL += C.portableConnectorReturnAir()
	return GL

/datum/pipeline/proc/reconcile_air()
	var/list/datum/gas_mixture/GL = get_all_connected_airs()
	if(null in GL)
		listclearnulls(GL)
	equalize_all_gases_in_list(GL)
