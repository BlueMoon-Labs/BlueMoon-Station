/** Shared composition and lifecycle for players, bots, owned agents and ICE.
 * Ordered snapshots are immutable during callbacks; mutations affect the next pass.
 */
/datum/netrun_agent_behavior
	var/id
	var/priority = 100
	var/enabled = TRUE
	/// Each behavior owns its subscriptions, independently of its agent's representation.
	var/list/subscriptions = list()
	var/list/requires = list()
	var/install_started = FALSE
	var/installed = FALSE
	var/removed = FALSE
	var/datum/netrun_module_host/controller

/datum/netrun_agent_behavior/Destroy()
	controller?.detach_entity_module(src)
	installed = FALSE
	if(install_started && !removed)
		removed = TRUE
		on_remove()
	clear_subscriptions()
	controller = null
	return ..()

/datum/netrun_agent_behavior/proc/bound_owner()
	return null

/datum/netrun_agent_behavior/proc/on_install()
	return TRUE

/datum/netrun_agent_behavior/proc/on_remove()
	return

/datum/netrun_agent_behavior/proc/process_tick(delta)
	return

/datum/netrun_agent_behavior/proc/needs_processing()
	return FALSE

/datum/netrun_agent_behavior/proc/handle_action(action, list/params, mob/user)
	return FALSE

/datum/netrun_agent_behavior/proc/behavior_step(datum/netrun_bot_brain/brain)
	return FALSE

/datum/netrun_agent_behavior/proc/advance(delta)
	return behavior_step(null)

/// A module is the signal receiver. Repeating a subscription is a no-op;
/// conflicting callbacks for the same source/signal are rejected atomically.
/datum/netrun_agent_behavior/proc/listen(datum/source, signals, callback)
	if(QDELETED(source) || !istext(callback))
		return FALSE
	var/list/names = islist(signals) ? signals : list(signals)
	var/key = REF(source)
	var/list/entry = subscriptions[key]
	var/list/owned = entry ? entry["signals"] : list()
	for(var/signal in names)
		if(!istext(signal) || (owned[signal] && owned[signal] != callback))
			return FALSE
	var/list/added = list()
	for(var/signal in names)
		if(!owned[signal])
			owned[signal] = callback
			added += signal
	if(length(added))
		RegisterSignal(source, added, callback)
	if(!entry)
		subscriptions[key] = list("source" = WEAKREF(source), "signals" = owned)
	return TRUE

/datum/netrun_agent_behavior/proc/unlisten(datum/source, signals)
	if(!source)
		return
	var/key = REF(source)
	var/list/entry = subscriptions[key]
	if(!entry)
		return
	var/list/owned = entry["signals"]
	var/list/names = islist(signals) ? signals : list(signals)
	UnregisterSignal(source, names)
	for(var/signal in names)
		owned -= signal
	if(!length(owned))
		subscriptions -= key

/datum/netrun_agent_behavior/proc/clear_subscriptions()
	for(var/key in subscriptions)
		var/list/entry = subscriptions[key]
		var/datum/weakref/reference = entry["source"]
		var/datum/source = reference.resolve()
		if(source)
			UnregisterSignal(source, entry["signals"])
	subscriptions.Cut()

/proc/cmp_netrun_agent_behavior(datum/netrun_agent_behavior/first, datum/netrun_agent_behavior/second)
	return first.priority == second.priority ? sorttext(second.id, first.id) : first.priority - second.priority

/datum/netrun_module_host
	var/datum/owner
	var/module_type = /datum/netrun_agent_behavior
	var/list/datum/netrun_agent_behavior/modules = list()
	var/list/datum/netrun_agent_behavior/ordered = list()
	var/destroying = FALSE

/datum/netrun_module_host/New(datum/owner, module_type)
	src.owner = owner
	if(module_type)
		src.module_type = module_type

/datum/netrun_module_host/Destroy()
	destroy_modules()
	owner = null
	return ..()

/datum/netrun_module_host/proc/accepts(path)
	return ispath(path, module_type) || ispath(path, /datum/netrun_agent_behavior/pattern)

/datum/proc/netrun_modules_changed(datum/netrun_module_host/controller)
	return

/datum/proc/netrun_module_ready(datum/netrun_agent_behavior/module)
	return

/datum/netrun_module_host/proc/module_dependencies_met(list/requirements)
	if(!islist(requirements))
		return FALSE
	for(var/required in requirements)
		var/datum/netrun_agent_behavior/module = modules[required]
		if(!istext(required) || QDELETED(module) || !module.installed)
			return FALSE
	return TRUE

/datum/netrun_module_host/proc/rebuild_ordered()
	var/list/ordered = list()
	for(var/id in modules)
		var/datum/netrun_agent_behavior/module = modules[id]
		if(!QDELETED(module) && module.installed)
			ordered += module
	sortTim(ordered, GLOBAL_PROC_REF(cmp_netrun_agent_behavior))
	src.ordered = ordered
	owner.netrun_modules_changed(src)

/datum/netrun_module_host/proc/install_module(module_type)
	RETURN_TYPE(/datum/netrun_agent_behavior)
	if(destroying || (QDELETED(src) || QDELETED(owner)) || !accepts(module_type))
		return null
	var/datum/netrun_agent_behavior/module = new module_type(owner)
	return install_module_candidate(module)

/// Lists declared on a type are initialized on its instance in DM. The factory
/// and assembly both validate this single candidate, never initial(type.requires).
/datum/netrun_module_host/proc/install_module_candidate(datum/netrun_agent_behavior/module)
	RETURN_TYPE(/datum/netrun_agent_behavior)
	if(QDELETED(module) || module.bound_owner() != owner || !accepts(module.type))
		return null
	var/id = module.id
	if(destroying || (QDELETED(src) || QDELETED(owner)) || module.install_started || !istext(id) || !length(id) || modules[id] || !IS_FINITE(module.priority) || !module_dependencies_met(module.requires))
		qdel(module)
		return null
	modules[id] = module
	module.controller = src
	module.install_started = TRUE
	if(!module.on_install() || (QDELETED(src) || QDELETED(owner)) || QDELETED(module) || module.id != id || modules[id] != module)
		if(modules[id] == module)
			modules -= id
		qdel(module)
		return null
	module.installed = TRUE
	rebuild_ordered()
	owner.netrun_module_ready(module)
	return QDELETED(module) ? null : module

/// Forced detach belongs to destruction; normal removal additionally checks dependents.
/datum/netrun_module_host/proc/detach_entity_module(datum/netrun_agent_behavior/module)
	if(modules[module.id] != module)
		return FALSE
	modules -= module.id
	module.installed = FALSE
	module.controller = null
	rebuild_ordered()
	return TRUE

/datum/netrun_module_host/proc/remove_module(id)
	var/datum/netrun_agent_behavior/module = modules[id]
	if(QDELETED(module) || destroying)
		return FALSE
	for(var/other_id in modules)
		var/datum/netrun_agent_behavior/other = modules[other_id]
		if(other != module && !QDELETED(other) && (id in other.requires))
			return FALSE
	detach_entity_module(module)
	qdel(module)
	return TRUE

/// Assemble in dependency order, independently of a program's authored list order.
/// Failure rolls back only this assembly's additions; pre-existing capabilities survive.
/datum/netrun_module_host/proc/assemble_modules(list/module_types)
	if(!islist(module_types) || destroying || (QDELETED(src) || QDELETED(owner)))
		return FALSE
	var/list/pending = list()
	var/list/requested = list()
	var/success = TRUE
	for(var/module_type in module_types)
		if(!accepts(module_type))
			success = FALSE
			break
		var/datum/netrun_agent_behavior/candidate = new module_type(owner)
		var/id = candidate.id
		if(!istext(id) || !length(id) || requested[id] || !IS_FINITE(candidate.priority) || !islist(candidate.requires))
			qdel(candidate)
			success = FALSE
			break
		requested[id] = TRUE
		pending += candidate
	var/list/added = list()
	while(length(pending) && success)
		var/progress = FALSE
		for(var/index = 1; index <= length(pending);)
			var/datum/netrun_agent_behavior/candidate = pending[index]
			var/id = candidate.id
			var/datum/netrun_agent_behavior/existing = modules[id]
			if(existing)
				if(QDELETED(existing) || !existing.installed || !istype(existing, candidate.type))
					success = FALSE
					break
				qdel(candidate)
			else
				if(!module_dependencies_met(candidate.requires))
					index++
					continue
				var/datum/netrun_agent_behavior/module = install_module_candidate(candidate)
				if(!module)
					success = FALSE
					break
				added += module
			pending.Cut(index, index + 1)
			progress = TRUE
		if(!progress)
			success = FALSE
	// Uninstalled candidates own no resources and must not run on_remove hooks.
	for(var/datum/netrun_agent_behavior/candidate as anything in pending)
		if(!QDELETED(candidate))
			qdel(candidate)
	if(!success)
		for(var/index = length(added); index >= 1; index--)
			var/datum/netrun_agent_behavior/module = added[index]
			if(!QDELETED(module))
				remove_module(module.id)
	return success

/datum/netrun_module_host/proc/destroy_modules()
	if(destroying)
		return
	destroying = TRUE
	var/list/snapshot = ordered
	var/list/previous = modules
	modules = list()
	ordered = list()
	owner.netrun_modules_changed(src)
	for(var/index = length(snapshot); index >= 1; index--)
		qdel(snapshot[index])
	// An on_install hook may have ended the owner before its module became ready.
	for(var/id in previous)
		var/datum/netrun_agent_behavior/module = previous[id]
		if(!QDELETED(module))
			qdel(module)
	destroying = FALSE

/datum/netrun_module_host/proc/entity_module_current(datum/netrun_agent_behavior/module)
	return !QDELETED(module) && module.installed && module.enabled && modules[module.id] == module && module_dependencies_met(module.requires)

/datum/netrun_module_host/proc/process_modules(delta)
	var/list/snapshot = ordered
	for(var/datum/netrun_agent_behavior/module as anything in snapshot)
		if((QDELETED(src) || QDELETED(owner)))
			return
		if(entity_module_current(module))
			module.process_tick(delta)

/datum/netrun_module_host/proc/modules_need_processing()
	var/list/snapshot = ordered
	for(var/datum/netrun_agent_behavior/module as anything in snapshot)
		if((QDELETED(src) || QDELETED(owner)))
			return FALSE
		if(entity_module_current(module) && module.needs_processing())
			return TRUE
	return FALSE

/datum/netrun_module_host/proc/dispatch_module_action(action, list/params, mob/user)
	var/list/snapshot = ordered
	for(var/datum/netrun_agent_behavior/module as anything in snapshot)
		if((QDELETED(src) || QDELETED(owner)))
			return FALSE
		if(entity_module_current(module) && module.handle_action(action, params, user))
			return TRUE
	return FALSE

/// Priority arbitrates one behavioral action; each capability owns its own facts/reactions.
/datum/netrun_module_host/proc/process_behavior(datum/netrun_bot_brain/brain)
	if(brain && (QDELETED(brain) || brain.owner != owner))
		return FALSE
	var/list/snapshot = ordered
	for(var/datum/netrun_agent_behavior/module as anything in snapshot)
		if((QDELETED(src) || QDELETED(owner)))
			return FALSE
		if(entity_module_current(module) && module.behavior_step(brain))
			return TRUE
	return FALSE

/// ICE and portable patterns share the same stable one-action dispatch.
/datum/netrun_module_host/proc/advance(delta)
	var/list/snapshot = ordered
	for(var/datum/netrun_agent_behavior/module as anything in snapshot)
		if(QDELETED(src) || QDELETED(owner))
			return FALSE
		if(entity_module_current(module) && module.advance(delta))
			return TRUE
	return FALSE

/datum/netrun_module_host/proc/set_enabled(id, enabled)
	var/datum/netrun_agent_behavior/module = modules[id]
	if(QDELETED(module) || !module.installed || destroying)
		return FALSE
	module.enabled = !!enabled
	owner.netrun_actor_wake()
	return TRUE

/datum/netrun_module_host/proc/mutate_pattern(id, list/changes)
	var/datum/netrun_agent_behavior/pattern/pattern = modules[id]
	if(!istype(pattern) || !entity_module_current(pattern) || !pattern.mutate(changes))
		return FALSE
	owner.netrun_actor_wake()
	return TRUE

/datum/proc/netrun_actor_modules()
	return null

/mob/camera/netrun_entity/netrun_actor_modules()
	return get_module_host()

/datum/netrun_ice/netrun_actor_modules()
	return agent

