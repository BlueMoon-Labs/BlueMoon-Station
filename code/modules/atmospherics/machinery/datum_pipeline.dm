/datum/pipeline
	var/datum/gas_mixture/air
	var/list/datum/gas_mixture/other_airs

	var/list/obj/machinery/atmospherics/pipe/members
	var/list/obj/machinery/atmospherics/components/other_atmosmch
	/// Subset of other_atmosmch that can bridge into other pipelines or portables
	/// (valves, relief valves, portables connectors). Maintained on membership
	/// changes so get_all_connected_airs() does not istype-scan every attached
	/// machine on every reconcile.
	var/list/obj/machinery/atmospherics/components/bridging_atmosmch

	/// Сеть ждёт реконсиляции. Писать НАПРЯМУЮ нельзя - только через
	/// [/datum/pipeline/proc/mark_dirty]: флаг обязан ходить парой со списком
	/// SSair.dirty_networks, иначе сеть либо перестанет обсчитываться совсем
	/// (газ в трубе замрёт), либо застрянет в списке навсегда.
	var/update = TRUE
	///Pipenet pressure at the last idle-machine wake broadcast; reconcile_air
	///wakes attached machines when pressure moves more than
	///ATMOS_PIPENET_WAKE_PRESSURE_DELTA away from it.
	var/last_wake_pressure = 0
	///Heat exchanging members, tracked separately so the temperature broadcast
	///does not have to scan the whole members list every reconcile. These sit in
	///`members`, which the pressure broadcast never touches, and they are the
	///only pipes that idle out - so they need a wake path of their own.
	var/list/obj/machinery/atmospherics/pipe/heat_exchanging/heat_exchanging_members
	///Pipenet temperature at the last heat exchanging wake broadcast.
	var/last_wake_temperature = 0

	/// Минимальный номинал по членам сети. Рвётся всегда слабейшее звено,
	/// поэтому один обычный переходник задаёт потолок всему контуру. Стартует
	/// с максимума, чтобы первый же track_member() опустил его до правды.
	var/min_rating = PIPE_PRESSURE_RATING_REINFORCED
	/// Накопленная усталость, PIPE_FATIGUE_MAX = следующая стадия повреждения.
	var/fatigue = 0
	/// Члены сети со стадией выше PIPE_DAMAGE_INTACT.
	var/list/obj/machinery/atmospherics/pipe/damaged_members
	/// Стоит ли сеть на учёте в SSair.stressed_pipenets.
	var/stress_registered = FALSE
	/// Когда сети снова можно подать голос в комнату.
	var/next_stress_message = 0

/datum/pipeline/New()
	other_airs = list()
	members = list()
	other_atmosmch = list()
	SSair.networks += src
	// Свежая сеть родилась грязной (см. дефолт update): её нужно свести хотя бы
	// раз, иначе собранный контур не поедет до первого внешнего события.
	SSair.dirty_networks += src

/datum/pipeline/Destroy()
	SSair.networks -= src
	SSair.dirty_networks -= src
	SSair.currentrun -= src
	SSair.stressed_pipenets -= src
	update = FALSE
	stress_registered = FALSE
	damaged_members = null
	if(air?.return_volume())  //	BLUEMOON EDIT: TODO:runtime
		temporarily_store_air()
	// Implicitly-typed `for(... in list)` skips null entries; `as anything` does
	// not. A member pipe/component hard-deleted elsewhere leaves a stale null in
	// these lists, so the filtering form is load-bearing here (same reason as the
	// build_pipeline note below). Do not "optimize" it back to `as anything`.
	for(var/obj/machinery/atmospherics/pipe/P in members)
		P.parent = null
	for(var/obj/machinery/atmospherics/components/C in other_atmosmch)
		if(!C.parents)
			continue
		for(var/i in 1 to length(C.parents))
			if(C.parents[i] == src)
				C.parents[i] = null
	members.Cut()
	other_atmosmch.Cut()
	other_airs.Cut()
	bridging_atmosmch = null
	heat_exchanging_members = null
	QDEL_NULL(air)
	return ..()

/// Единственный вход для «сеть надо свести». Ставит флаг и заводит сеть в
/// список грязных, по которому идёт фаза пайпнетов.
///
/// До этого фаза копировала и опрашивала ВСЕ сети каждый проход, а
/// `/datum/pipeline/process()` выходил первой же строкой у подавляющего
/// большинства. В раунде 9868 это дало ровно 3.0-3.45 мс в КАЖДОЙ из 248 строк
/// perf-лога - при том, что остальные фазы гуляли в десять раз, - на 379-402
/// сетях, из которых реально обновлялась горстка.
/datum/pipeline/proc/mark_dirty()
	if(update)
		return
	update = TRUE
	if(SSair)
		SSair.dirty_networks += src

/datum/pipeline/process()
	if(!update)	//	BLUEMOON EDIT: TODO:runtime
		return	//	BLUEMOON EDIT: TODO:runtime
	update = FALSE
	reconcile_air()
	// react() может вернуть REACTING - тогда сеть остаётся грязной и обязана
	// вернуться в список. Прямая запись `update = ...` этого не сделала бы.
	if(air?.react(src))
		mark_dirty()
	wake_heat_exchangers()
	// Давление считается РОВНО ОДИН раз за проход и обслуживает обоих
	// потребителей: постановку на учёт по напряжению и рассылку пробуждений.
	// Отдельный return_pressure() под каждого стоил бы вдвое, а на перф-ветке
	// это недопустимо.
	var/current_pressure = air ? air.return_pressure() : 0
	// Постановка на учёт идёт здесь, а не выше выхода по !update: подняться туда
	// значило бы считать давление и у сетей, которые вообще не обновляются. И
	// не нужно - сеть, переставшая обновляться, перестала менять давление, а на
	// последнем своём проходе уже встала на учёт с тем давлением, с которым
	// уснула. Но обязательно ВЫШЕ выхода по other_atmosmch: чисто трубная сеть
	// до него не доживает, а рваться она может не хуже прочих.
	if(!stress_registered && min_rating > 0 && current_pressure > min_rating)
		SSair.register_stressed_pipenet(src)
	// A meaningful pressure change (pipe emptied, distro refilled) must pull
	// idle-heartbeat vents attached to this net back to full processing; small
	// jitter around a steady pressure must not.
	if(!length(other_atmosmch) && !bridging_atmosmch)
		return
	// Порог относительный на низких давлениях: у криоконтура (2.7К) весь рабочий
	// диапазон лежит ниже абсолютных 5 кПа, и любое реальное событие оставалось
	// немым - спящие помпы там ждали одного лишь heartbeat.
	var/wake_delta = min(ATMOS_PIPENET_WAKE_PRESSURE_DELTA, max(ATMOS_PIPENET_WAKE_PRESSURE_FLOOR, max(current_pressure, last_wake_pressure) * ATMOS_PIPENET_WAKE_PRESSURE_RATIO))
	if(abs(current_pressure - last_wake_pressure) <= wake_delta)
		return
	last_wake_pressure = current_pressure
	// The filtering `in` form skips stale nulls left by hard-deleted members.
	for(var/obj/machinery/atmospherics/components/component in other_atmosmch)
		component.atmos_wake()
	// Nets bridged through this one (open valve, portables connector) receive gas
	// from reconcile_air without their update flag ever being set, so they would
	// sleep through the jump. Dirty them for one pass: each then runs this same
	// comparison against its own baseline (a closed bridge sees no delta and goes
	// straight back to sleep).
	for(var/obj/machinery/atmospherics/components/bridge in bridging_atmosmch)
		for(var/datum/pipeline/bridged_net in bridge.parents)
			if(bridged_net != src)
				bridged_net.mark_dirty()

/// Wakes sleeping heat exchanging members after the net's temperature moved.
///
/// Heat exchangers idle out once their air matches their surroundings, so heat
/// arriving through the pipeline (a burn chamber venting into the loop, a
/// freezer starting up) has to reach them explicitly. The pressure broadcast
/// below cannot do it: it iterates other_atmosmch, and pipes are not in it.
/datum/pipeline/proc/wake_heat_exchangers()
	if(!heat_exchanging_members)
		return
	var/current_temperature = air ? air.return_temperature() : 0
	if(abs(current_temperature - last_wake_temperature) <= ATMOS_PIPENET_WAKE_TEMPERATURE_DELTA)
		return
	last_wake_temperature = current_temperature
	// The filtering `in` form skips stale nulls left by hard-deleted members.
	// An actively circulating loop crosses the threshold every fire while its
	// pipes are already awake and working, so test the flag inline rather than
	// paying a proc call per member to have atmos_wake() decide the same thing.
	for(var/obj/machinery/atmospherics/pipe/heat_exchanging/exchanger in heat_exchanging_members)
		if(exchanger.atmos_idle_queued || exchanger.atmos_idle_streak)
			exchanger.atmos_wake()

/// Adds a pipe to the members list, keeping the heat exchanging index in step.
/datum/pipeline/proc/track_member(obj/machinery/atmospherics/pipe/member)
	members += member
	min_rating = min(min_rating, member.pressure_rating)
	// Перестроенная сеть обязана подобрать уже пробитые трубы и сразу встать на
	// учёт: дыра переживает разборку соседней секции, а вместе с ней и утечку.
	if(member.damage_stage)
		LAZYOR(damaged_members, member)
		SSair.register_stressed_pipenet(src)
	if(istype(member, /obj/machinery/atmospherics/pipe/heat_exchanging))
		LAZYOR(heat_exchanging_members, member)

/datum/pipeline/proc/build_pipeline(obj/machinery/atmospherics/base)
	if(QDELETED(base))
		stack_trace("build_pipeline() called with QDELETED base [base?.type] at [base ? COORD(base) : "null"]")
		return
	var/volume = 0
	if(istype(base, /obj/machinery/atmospherics/pipe))
		var/obj/machinery/atmospherics/pipe/E = base
		volume = E.volume
		track_member(E)
		if(E.air_temporary)
			air = E.air_temporary
			E.air_temporary = null
	else
		addMachineryMember(base)
	if(!air)
		air = new

	// O(1) membership probe replacing the O(M) members.Find call that made the
	// BFS quadratic on large pipenets. Seed it with whatever is already in
	// `members` (the base pipe, when it is one) so it is found as a neighbor.
	var/list/seen_members = list()
	for(var/obj/machinery/atmospherics/pipe/already in members)
		seen_members[already] = TRUE

	// Index-cursor BFS instead of `for(... in list); list -= current`. The old
	// pattern was O(P) per removal × P removals = quadratic; this is O(1) per
	// step and visits the same set of nodes (BFS reachability doesn't depend
	// on snapshot semantics for a connected graph).
	var/list/possible_expansions = list(base)
	var/cursor = 1
	while(cursor <= length(possible_expansions))
		var/obj/machinery/atmospherics/borderline = possible_expansions[cursor++]

		var/list/result = borderline.pipeline_expansion(src)
		if(!length(result))
			continue

		// Implicit-typed `for X in list` filters nulls AND non-atmos entries —
		// /obj/machinery/atmospherics/components/pipeline_expansion returns
		// `list(nodes[…])` and that slot is null on disconnected components.
		// Skipping the filter (e.g. via `as anything`) reaches setPipenet on
		// null and crashes during SSair pipenet setup.
		for(var/obj/machinery/atmospherics/P in result)
			if(istype(P, /obj/machinery/atmospherics/pipe))
				var/obj/machinery/atmospherics/pipe/item = P
				if(seen_members[item])
					continue
				seen_members[item] = TRUE

				if(item.parent)
					var/static/pipenetwarnings = 10
					if(pipenetwarnings > 0)
						log_mapping("build_pipeline(): [item.type] added to a pipenet while still having one. (pipes leading to the same spot stacking in one turf) Nearby: ([item.x], [item.y], [item.z]).")
						pipenetwarnings -= 1
						if(pipenetwarnings == 0)
							log_mapping("build_pipeline(): further messages about pipenets will be suppressed")
				track_member(item)
				possible_expansions += item

				volume += item.volume
				item.parent = src

				if(item.air_temporary)
					air.merge(item.air_temporary)
					QDEL_NULL(item.air_temporary)
			else
				P.setPipenet(src, borderline)
				addMachineryMember(P)

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
	if(istype(C, /obj/machinery/atmospherics/components/binary/valve) \
		|| istype(C, /obj/machinery/atmospherics/components/binary/relief_valve) \
		|| istype(C, /obj/machinery/atmospherics/components/unary/portables_connector))
		LAZYOR(bridging_atmosmch, C)
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
			if(E)
				merge(E)
		if(!members.Find(P))
			track_member(P)
			air.set_volume(air.return_volume() + P.volume)
	else
		A.setPipenet(src, N)
		addMachineryMember(A)

/datum/pipeline/proc/merge(datum/pipeline/E)
	if(E == src)
		return
	air.set_volume(air.return_volume() + E.air.return_volume())
	members.Add(E.members)
	// members.Add() минует track_member(), поэтому номинал и список пробитых
	// труб переносятся здесь руками.
	min_rating = min(min_rating, E.min_rating)
	if(E.damaged_members)
		LAZYOR(damaged_members, E.damaged_members)
		E.damaged_members = null
		SSair.register_stressed_pipenet(src)
	for(var/obj/machinery/atmospherics/pipe/S in E.members)
		S.parent = src
	if(E.heat_exchanging_members)
		LAZYOR(heat_exchanging_members, E.heat_exchanging_members)
		E.heat_exchanging_members = null
	air.merge(E.air)
	for(var/obj/machinery/atmospherics/components/C in E.other_atmosmch)
		C.replacePipenet(E, src)
	other_atmosmch |= E.other_atmosmch
	if(E.bridging_atmosmch)
		LAZYOR(bridging_atmosmch, E.bridging_atmosmch)
	if(null in E.other_airs)
		stack_trace("merge(): Pipeline [E]([REF(E)]) contains null gas mixtures in other_airs. Cleaning before merge.")
		listclearnulls(E.other_airs)
	other_airs |= E.other_airs
	E.members.Cut()
	E.other_atmosmch.Cut()
	mark_dirty()
	qdel(E)

/obj/machinery/atmospherics/proc/addMember(obj/machinery/atmospherics/A)
	return

/obj/machinery/atmospherics/pipe/addMember(obj/machinery/atmospherics/A)
	if(!parent)
		return
	parent.addMember(A, src)

/obj/machinery/atmospherics/components/addMember(obj/machinery/atmospherics/A)
	var/datum/pipeline/P = returnPipenet(A)
	if(!P)
		return
	P.addMember(A, src)


/datum/pipeline/proc/temporarily_store_air()
	//Update individual gas_mixtures by volume ratio

	for(var/obj/machinery/atmospherics/pipe/member in members)
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
	mark_dirty()

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
		for(var/obj/machinery/atmospherics/components/atmosmch as anything in P.bridging_atmosmch)
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
