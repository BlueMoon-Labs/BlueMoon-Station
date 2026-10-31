/**
 * Stateless capability provider. Instances belong to SSnetrun, never to a machine
 * or a session: all mutable gameplay context is passed into the contract.
 *
 * atom_type is a cheap static candidate filter; available() is a live condition.
 * A cached type match must never cache a wire, attachment or machine's state.
 */
/datum/netrun_provider
	var/atom_type
	var/interface_name
	var/allow_emag = FALSE
	/// Higher priority wins before type specificity, allowing opt-in capabilities.
	var/priority = 0
	/// action id = list(name, desc, access, danger, params = list(list(id,name,type)))
	var/list/actions = list()
	/// Static parent-atom notifications. Subscribe even while available() is FALSE.
	var/list/state_signals = list()

/datum/netrun_provider/proc/available(atom/target)
	return !QDELETED(target) && istype(target, atom_type)

/// Omitted schema access fails closed at USER, matching the machine-panel boundary.
/datum/netrun_provider/proc/action_access(action)
	var/list/entry = actions[action]
	return max(NETRUN_ACCESS_USER, isnum(entry?["access"]) ? entry["access"] : NETRUN_ACCESS_USER)

/// Machine policy supplements route/access checks; null means the action is usable.
/datum/netrun_provider/proc/action_unavailable_reason(atom/target, action, datum/netrun_console/console, datum/component/netrun_node/node)
	if(!actions[action] || !available(target))
		return "Сетевой сервис устройства недоступен."
	return null

/// Return a new payload, without modifying native ui_data or shared schema lists.
/datum/netrun_provider/proc/read_data(atom/target, datum/netrun_console/console, datum/component/netrun_node/node)
	return list()

/// Called only at delivery, after fresh topology, sender, schema and access checks.
/// TRUE means the provider accepted delivery, not that an asynchronous operation completed.
/datum/netrun_provider/proc/execute(atom/target, action, list/arguments, datum/netrun_console/console, datum/component/netrun_node/node)
	return FALSE

/datum/netrun_provider/proc/clean_params(action, list/input)
	var/list/entry = actions[action]
	if(!entry || !islist(input))
		return
	var/list/clean = list()
	for(var/list/param as anything in entry["params"])
		var/id = param["id"]
		var/value = input[id]
		if(isnull(value) || (!istext(value) && !isnum(value)))
			return
		value = trim("[value]")
		if(!length(value) || length(value) > 256)
			return
		if(param["type"] == "number")
			var/numeric = text2num(value)
			var/minimum = isnull(param["min"]) ? 0 : param["min"]
			var/maximum = isnull(param["max"]) ? 100000 : param["max"]
			if(!IS_FINITE(numeric) || numeric < minimum || numeric > maximum)
				return
			value = numeric
		clean[id] = value
	return clean

/datum/netrun_provider/proc/payload(atom/target, datum/netrun_console/console, datum/component/netrun_node/node)
	if(!interface_name || !available(target) || console.node_level(node) < NETRUN_ACCESS_USER || !console.can_route(node) || !node.is_online())
		return null
	var/list/entries = list()
	for(var/action in actions)
		var/list/entry = actions[action]
		var/reason = action_unavailable_reason(target, action, console, node)
		entries += list(list(
			"id" = action,
			"name" = entry["name"],
			"desc" = entry["desc"],
			"access" = action_access(action),
			"danger" = entry["danger"],
			"params" = entry["params"] || list(),
			"allowed" = !reason && console.node_level(node) >= action_access(action) && !console.is_locked(),
			"reason" = reason,
		))
	return list("interface" = interface_name, "data" = read_data(target, console, node), "actions" = entries)

/datum/controller/subsystem/netrun
	var/list/datum/netrun_provider/providers
	/// Only candidate lists are cached. available() is always evaluated for the live atom.
	var/list/provider_type_cache

/datum/controller/subsystem/netrun/proc/get_provider_candidates(atom/target)
	if(QDELETED(target))
		return
	if(!providers)
		providers = list()
		provider_type_cache = list()
		for(var/datum/netrun_provider/path as anything in subtypesof(/datum/netrun_provider))
			if(initial(path.atom_type))
				providers += new path
	if(!provider_type_cache)
		provider_type_cache = list()
	var/list/candidates = provider_type_cache[target.type]
	if(isnull(candidates))
		candidates = list()
		for(var/datum/netrun_provider/provider as anything in providers)
			if(istype(target, provider.atom_type))
				candidates += provider
		provider_type_cache[target.type] = candidates
	return candidates

/// A disabled capability must still wake its endpoint when it becomes available.
/// Build subscriptions from type candidates, never from the currently chosen service.
/datum/controller/subsystem/netrun/proc/get_provider_state_signals(atom/target)
	var/list/signals = list()
	for(var/datum/netrun_provider/provider as anything in get_provider_candidates(target))
		signals |= provider.state_signals
	return signals

/datum/controller/subsystem/netrun/proc/get_provider(atom/target)
	var/datum/netrun_provider/best
	for(var/datum/netrun_provider/provider as anything in get_provider_candidates(target))
		if(!provider.available(target))
			continue
		if(!best || provider.priority > best.priority || (provider.priority == best.priority && ispath(provider.atom_type, best.atom_type)))
			best = provider
	return best

/// Compatibility entry point for existing native adapters and downstream modules.
/datum/controller/subsystem/netrun/proc/get_api(atom/target)
	return get_provider(target)
