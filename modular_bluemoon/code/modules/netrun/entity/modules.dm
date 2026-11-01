/** Entity capabilities keep their typed owner; composition belongs to the shared host. */
/datum/netrun_entity_module
	parent_type = /datum/netrun_agent_behavior
	var/mob/camera/netrun_entity/owner

/datum/netrun_entity_module/New(mob/camera/netrun_entity/owner)
	src.owner = owner

/datum/netrun_entity_module/bound_owner()
	return owner

/datum/netrun_entity_module/Destroy()
	. = ..()
	owner = null

/datum/netrun_entity_module/proc/wake_behavior()
	if(!installed || !enabled || QDELETED(owner))
		return
	var/datum/netrun_bot_brain/brain = owner.module_brain()
	if(!QDELETED(brain) && !brain.handling_behavior)
		brain.wake_now()

/mob/camera/netrun_entity
	var/datum/netrun_module_host/module_host
	/// Compatibility aliases; the host publishes a replacement order after mutation.
	var/list/datum/netrun_agent_behavior/entity_modules = list()
	var/list/datum/netrun_agent_behavior/entity_module_order = list()

/mob/camera/netrun_entity/netrun_modules_changed(datum/netrun_module_host/controller)
	entity_modules = controller.modules
	entity_module_order = controller.ordered

/mob/camera/netrun_entity/netrun_module_ready(datum/netrun_agent_behavior/module)
	SEND_SIGNAL(src, COMSIG_NETRUN_ENTITY_MODULE_READY, module)

/mob/camera/netrun_entity/proc/get_module_host()
	RETURN_TYPE(/datum/netrun_module_host)
	if(!module_host)
		module_host = new(src, /datum/netrun_entity_module)
	return module_host

/mob/camera/netrun_entity/proc/entity_module_types()
	return list(/datum/netrun_entity_module/identity, /datum/netrun_entity_module/console,
		/datum/netrun_entity_module/navigation, /datum/netrun_entity_module/vitals, /datum/netrun_entity_module/dive,
		/datum/netrun_entity_module/audio, /datum/netrun_entity_module/neural_feedback)

/// Optional behavior is resolved when a fact arrives, never captured before bot initialization.
/mob/camera/netrun_entity/proc/module_brain()
	RETURN_TYPE(/datum/netrun_bot_brain)
	return null

/mob/camera/netrun_entity/bot/module_brain()
	return brain

/mob/camera/netrun_entity/proc/module_dependencies_met(list/requirements)
	return get_module_host().module_dependencies_met(requirements)

/mob/camera/netrun_entity/proc/install_module(module_type)
	return get_module_host().install_module(module_type)

/mob/camera/netrun_entity/proc/install_module_candidate(datum/netrun_agent_behavior/module)
	return get_module_host().install_module_candidate(module)

/mob/camera/netrun_entity/proc/detach_entity_module(datum/netrun_agent_behavior/module)
	return get_module_host().detach_entity_module(module)

/mob/camera/netrun_entity/proc/remove_module(id)
	return get_module_host().remove_module(id)

/mob/camera/netrun_entity/proc/entity_module_current(datum/netrun_agent_behavior/module)
	return get_module_host().entity_module_current(module)

/mob/camera/netrun_entity/proc/process_modules(delta)
	return get_module_host().process_modules(delta)

/mob/camera/netrun_entity/proc/modules_need_processing()
	return get_module_host().modules_need_processing()

/mob/camera/netrun_entity/proc/dispatch_module_action(action, list/params, mob/user)
	return get_module_host().dispatch_module_action(action, params, user)

/mob/camera/netrun_entity/proc/process_behavior(datum/netrun_bot_brain/brain)
	return get_module_host().process_behavior(brain)

/mob/camera/netrun_entity/proc/assemble_modules()
	return get_module_host().assemble_modules(entity_module_types())

/mob/camera/netrun_entity/proc/destroy_modules()
	module_host?.destroy_modules()

// Shared capabilities ---------------------------------------------------------

/datum/netrun_entity_module/identity
	id = "identity"
	priority = 10
	var/datum/action/innate/netrun_rename/action

/datum/netrun_entity_module/identity/on_install()
	owner.get_persona()
	listen(owner, COMSIG_MOB_ON_NEW_MIND, PROC_REF(on_mind_changed))
	action = new
	owner.rename_action = action
	action.Grant(owner)
	return TRUE

/datum/netrun_entity_module/identity/proc/on_mind_changed(datum/source)
	SIGNAL_HANDLER
	owner?.on_persona_mind_changed(source)

/datum/netrun_entity_module/identity/on_remove()
	if(owner?.rename_action == action)
		owner.rename_action = null
	QDEL_NULL(action)
	var/datum/netrun_persona/profile = owner?.persona
	if(owner)
		owner.persona = null
	// A mind owns its shared style across dives; only resident-owned identity is ours.
	if(!QDELETED(profile) && profile.identity_ref?.resolve() == owner)
		qdel(profile)

/datum/netrun_entity_module/console
	id = "console"
	priority = 20
	requires = list("identity")
	var/datum/netrun_console/entity/client_console
	var/datum/action/innate/netrun_console/action

/datum/netrun_entity_module/console/on_install()
	var/path = owner.console_type
	if(!ispath(path, /datum/netrun_console/entity))
		return FALSE
	client_console = new path(owner, NETRUN_ORIGIN_ENTITY)
	owner.console = client_console
	action = new
	owner.console_action = action
	action.Grant(owner)
	listen(owner, COMSIG_MOB_ALLOWED, PROC_REF(on_access_check))
	listen(owner, COMSIG_NETRUN_ENTITY_MODULE_READY, PROC_REF(on_module_ready))
	return TRUE

/datum/netrun_entity_module/console/proc/on_access_check(datum/source, obj/target)
	SIGNAL_HANDLER
	return owner?.on_credential_access_check(source, target)

/datum/netrun_entity_module/console/proc/on_module_ready(datum/source, datum/netrun_entity_module/module)
	SIGNAL_HANDLER
	if(!QDELETED(owner) && owner.modules_need_processing())
		client_console?.activate()

/datum/netrun_entity_module/console/on_remove()
	if(owner?.console_action == action)
		owner.console_action = null
	QDEL_NULL(action)
	var/datum/netrun_console/entity/previous = client_console
	QDEL_NULL(client_console)
	if(owner?.console == previous)
		owner.console = null

/datum/netrun_entity_module/navigation
	id = "navigation"
	priority = 30
	requires = list("console")
	var/navigation_type = /datum/netrun_entity_navigation
	var/datum/netrun_entity_navigation/navigation

/datum/netrun_entity_module/navigation/on_install()
	navigation = new navigation_type(owner)
	owner.navigation = navigation
	listen(owner, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_node_changed))
	return TRUE

/datum/netrun_entity_module/navigation/proc/on_node_changed(datum/source, datum/component/netrun_node/previous, datum/component/netrun_node/current)
	SIGNAL_HANDLER
	wake_behavior()

/datum/netrun_entity_module/navigation/on_remove()
	if(owner?.navigation == navigation)
		owner.navigation = null
	QDEL_NULL(navigation)

/datum/netrun_entity_module/navigation/handle_action(action, list/params, mob/user)
	switch(action)
		if("move")
			navigation.move_to(SSnetrun.find_node(params["address"]))
			return TRUE
		if("hop", "relay_hop")
			var/datum/component/netrun_node/target = SSnetrun.find_node(params["address"])
			var/success = action == "hop" ? owner.hop(target) : owner.relay_hop(target)
			if(!success)
				owner.console.log_line(owner.hop_denial(target), "bad")
			return TRUE
		if("travel")
			if(!owner.travel_to(SSnetrun.find_node(params["address"])))
				owner.console.log_line("Автопроход невозможен: нет открытого пути к узлу.", "bad")
			return TRUE
		if("travel_cancel")
			navigation.cancel()
			owner.console.log_line("Автопроход отменён.")
			return TRUE
		if("pursue")
			return owner.console.start_pursuit(params["ref"])
		if("pursuit_stop")
			navigation.cancel()
			return TRUE
	return FALSE

/datum/netrun_entity_module/navigation/bot
	navigation_type = /datum/netrun_entity_navigation/bot

/datum/netrun_entity_module/vitals
	id = "vitals"
	priority = 40
	requires = list("console")

/datum/netrun_entity_module/vitals/on_install()
	listen(owner, COMSIG_NETRUN_ENTITY_INTEGRITY, PROC_REF(on_integrity))
	listen(owner, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_node_changed))
	return TRUE

/datum/netrun_entity_module/vitals/proc/on_integrity(datum/source, integrity, maximum, reason)
	SIGNAL_HANDLER
	owner.console?.activate()
	wake_behavior()

/datum/netrun_entity_module/vitals/proc/on_node_changed(datum/source, datum/component/netrun_node/previous, datum/component/netrun_node/current)
	SIGNAL_HANDLER
	owner.update_vision()
	wake_behavior()

/datum/netrun_entity_module/vitals/needs_processing()
	if(owner.console?.get_combat_encounter()?.active)
		return FALSE
	return !!owner.client || owner.integrity < owner.max_integrity || world.time < owner.combat_stun_until || world.time < owner.combat_shield_until || world.time < owner.combat_ignore_until || world.time < owner.next_hop

/datum/netrun_entity_module/vitals/process_tick(delta)
	if(owner.host_node)
		var/turf/here = owner.host_node.physical_turf()
		if(here && owner.loc != here)
			owner.abstract_move(here)
	if(owner.integrity < owner.max_integrity && !owner.console?.get_combat_encounter()?.active)
		var/calm = world.time - owner.console.intrusion.last_illegal > 20 SECONDS
		owner.integrity = min(owner.max_integrity, owner.integrity + delta * (calm ? 0.5 : 0.25))
	owner.update_vision()

/datum/netrun_entity_module/dive
	id = "dive"
	priority = 50
	requires = list("console", "navigation")
	var/datum/netrun_dive_link/link

/datum/netrun_entity_module/dive/on_install()
	link = new(owner)
	owner.dive_link = link
	return TRUE

/datum/netrun_entity_module/dive/needs_processing()
	return !QDELETED(link?.body)

/datum/netrun_entity_module/dive/process_tick(delta)
	link.process_tick(delta)

/datum/netrun_entity_module/dive/handle_action(action, list/params, mob/user)
	if(action != "return")
		return FALSE
	owner.return_to_body()
	return TRUE

/datum/netrun_entity_module/dive/on_remove()
	if(!QDELETED(owner) && !QDELETED(link?.body) && !link.returning)
		link.return_to_body()
	if(owner?.dive_link == link)
		owner.dive_link = null
	QDEL_NULL(link)

// Composable bot behaviors ----------------------------------------------------

/// Host-local reactions belong to the behavior interested in those facts. The
/// weak binding follows movement without a station-wide observer or idle poll.
/datum/netrun_entity_module/bot_local
	requires = list("console")
	var/datum/weakref/host_ref

/datum/netrun_entity_module/bot_local/on_install()
	listen(owner, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_node_changed))
	listen(owner, COMSIG_NETRUN_ENTITY_MODULE_READY, PROC_REF(on_ready))
	rebind_host(owner.host_node)
	return TRUE

/datum/netrun_entity_module/bot_local/proc/rebind_host(datum/component/netrun_node/current)
	var/datum/component/netrun_node/previous = host_ref?.resolve()
	if(previous == current)
		return
	if(previous)
		unlisten(previous, COMSIG_NETRUN_NODE_CHANGED)
	host_ref = QDELETED(current) ? null : WEAKREF(current)
	if(host_ref)
		listen(current, COMSIG_NETRUN_NODE_CHANGED, PROC_REF(on_local_changed))

/datum/netrun_entity_module/bot_local/proc/on_node_changed(datum/source, datum/component/netrun_node/previous, datum/component/netrun_node/current)
	SIGNAL_HANDLER
	rebind_host(current)
	wake_behavior()

/datum/netrun_entity_module/bot_local/proc/on_ready(datum/source, datum/netrun_entity_module/module)
	SIGNAL_HANDLER
	rebind_host(owner.host_node)
	wake_behavior()

/datum/netrun_entity_module/bot_local/proc/on_local_changed(datum/source, datum/component/netrun_node/node, flags)
	SIGNAL_HANDLER
	if(flags & (NETRUN_CHANGED_OCCUPANTS | NETRUN_CHANGED_BINDING))
		wake_behavior()

/datum/netrun_entity_module/bot_local/on_remove()
	host_ref = null

/datum/netrun_entity_module/bot_lifecycle
	id = "bot_lifecycle"
	priority = 100
	requires = list("console")
	var/expiry_timer
	var/expiry_at = 0

/datum/netrun_entity_module/bot_lifecycle/on_install()
	listen(owner, COMSIG_NETRUN_ENTITY_MODULE_READY, PROC_REF(on_ready))
	listen(owner, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_node_changed))
	on_ready(owner, null)
	return TRUE

/datum/netrun_entity_module/bot_lifecycle/proc/on_ready(datum/source, datum/netrun_entity_module/module)
	SIGNAL_HANDLER
	var/mob/camera/netrun_entity/bot/bot = owner
	if(!istype(bot))
		return
	var/datum/principal = bot.owner_principal_ref?.resolve()
	if(!QDELETED(principal))
		listen(principal, COMSIG_PARENT_QDELETING, PROC_REF(on_owner_deleted))
	var/datum/netrun_faction/faction = bot.owner_faction_ref?.resolve()
	if(!QDELETED(faction))
		listen(faction, COMSIG_PARENT_QDELETING, PROC_REF(on_owner_deleted))
	if(bot.expires_at != expiry_at)
		if(expiry_timer)
			deltimer(expiry_timer)
		expiry_timer = null
		expiry_at = bot.expires_at
		if(expiry_at > world.time)
			expiry_timer = addtimer(CALLBACK(src, PROC_REF(on_expired)), expiry_at - world.time, TIMER_STOPPABLE | TIMER_DELETE_ME)
	wake_behavior()

/datum/netrun_entity_module/bot_lifecycle/proc/on_node_changed(datum/source, datum/component/netrun_node/previous, datum/component/netrun_node/current)
	SIGNAL_HANDLER
	wake_behavior()

/datum/netrun_entity_module/bot_lifecycle/proc/on_owner_deleted(datum/source)
	SIGNAL_HANDLER
	wake_behavior()

/datum/netrun_entity_module/bot_lifecycle/proc/on_expired()
	expiry_timer = null
	wake_behavior()

/datum/netrun_entity_module/bot_lifecycle/on_remove()
	if(expiry_timer)
		deltimer(expiry_timer)
	expiry_timer = null

/datum/netrun_entity_module/bot_lifecycle/behavior_step(datum/netrun_bot_brain/brain)
	if(!brain)
		return FALSE
	var/mob/camera/netrun_entity/bot/bot = owner
	if(!istype(bot))
		return FALSE
	if(QDELETED(bot.console) || bot.client)
		return TRUE
	brain.prune_memory()
	if(bot.agent_orphaned())
		bot.console.log_line("Связь с владельцем потеряна.", "bad")
		bot.dissolve()
		return TRUE
	if(bot.expires_at && world.time >= bot.expires_at)
		if(bot.is_network_visitor() && !brain.visitor_departing)
			brain.begin_visitor_departure()
		else
			bot.retire(brain.visitor_departing ? "не найден доступный выход NTnet" : null)
			return TRUE
	if(!bot.host_node)
		brain.state = "без узла"
		return TRUE
	return FALSE

/datum/netrun_entity_module/bot_stun
	id = "bot_stun"
	priority = 110
	requires = list("vitals")
	var/stun_timer
	var/stun_until = 0

/datum/netrun_entity_module/bot_stun/on_install()
	listen(owner.console, COMSIG_NETRUN_COMBAT_CHANGED, PROC_REF(on_combat_changed))
	listen(owner, COMSIG_NETRUN_ENTITY_MODULE_READY, PROC_REF(on_ready))
	arm_recovery()
	return TRUE

/datum/netrun_entity_module/bot_stun/proc/arm_recovery()
	// Only turn-owned stuns lack a real-time deadline. A native trap can still
	// expire during our turn, and its recovery must wake the waiting brain.
	if(owner.combat_stun_until == INFINITY)
		if(stun_timer)
			deltimer(stun_timer)
		stun_timer = null
		stun_until = owner.combat_stun_until
		return
	if(owner.combat_stun_until == stun_until)
		return
	if(stun_timer)
		deltimer(stun_timer)
	stun_timer = null
	stun_until = owner.combat_stun_until
	if(stun_until > world.time)
		stun_timer = addtimer(CALLBACK(src, PROC_REF(on_recovered)), stun_until - world.time, TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_entity_module/bot_stun/proc/on_combat_changed(datum/source)
	SIGNAL_HANDLER
	arm_recovery()
	wake_behavior()

/datum/netrun_entity_module/bot_stun/proc/on_ready(datum/source, datum/netrun_entity_module/module)
	SIGNAL_HANDLER
	arm_recovery()

/datum/netrun_entity_module/bot_stun/proc/on_recovered()
	stun_timer = null
	wake_behavior()

/datum/netrun_entity_module/bot_stun/on_remove()
	if(stun_timer)
		deltimer(stun_timer)
	stun_timer = null

/datum/netrun_entity_module/bot_stun/behavior_step(datum/netrun_bot_brain/brain)
	if(!brain || !owner.is_stunned())
		return FALSE
	brain.state = "оглушён"
	return TRUE

/datum/netrun_entity_module/bot_local/watch
	id = "bot_watch"
	priority = 120
	var/inspection_due = TRUE
	var/inspection_timer

/datum/netrun_entity_module/bot_local/watch/on_ready(datum/source, datum/netrun_entity_module/module)
	inspection_due = TRUE
	return ..()

/datum/netrun_entity_module/bot_local/watch/on_node_changed(datum/source, datum/component/netrun_node/previous, datum/component/netrun_node/current)
	inspection_due = TRUE
	return ..()

/datum/netrun_entity_module/bot_local/watch/on_local_changed(datum/source, datum/component/netrun_node/node, flags)
	if(flags & (NETRUN_CHANGED_OCCUPANTS | NETRUN_CHANGED_BINDING))
		inspection_due = TRUE
	return ..()

/datum/netrun_entity_module/bot_local/watch/proc/on_inspection_due()
	inspection_timer = null
	wake_behavior()

/datum/netrun_entity_module/bot_local/watch/on_remove()
	if(inspection_timer)
		deltimer(inspection_timer)
	inspection_timer = null
	return ..()

/datum/netrun_entity_module/bot_local/watch/behavior_step(datum/netrun_bot_brain/brain)
	if(!brain || !inspection_due || !owner.host_node)
		return FALSE
	if(world.time < brain.next_rogue_report)
		if(!inspection_timer)
			inspection_timer = addtimer(CALLBACK(src, PROC_REF(on_inspection_due)), brain.next_rogue_report - world.time, TIMER_STOPPABLE | TIMER_DELETE_ME)
		return FALSE
	inspection_due = FALSE
	brain.report_rogues()
	return FALSE

/// Only the police capability receives station incident broadcasts. Installing
/// or removing it changes this reaction without changing the shared brain.
/datum/netrun_entity_module/bot_local/watch/police/on_install()
	. = ..()
	listen(SSnetrun, COMSIG_NETRUN_INCIDENT_REPORTED, PROC_REF(on_incident_reported))
	return .

/datum/netrun_entity_module/bot_local/watch/police/proc/on_incident_reported(datum/source, datum/netrun_incident/incident)
	SIGNAL_HANDLER
	var/datum/netrun_bot_brain/brain = owner?.module_brain()
	if(QDELETED(brain) || QDELETED(incident) || brain.claimed_incident() || incident.severity < NETRUN_INCIDENT_MEDIUM)
		return
	var/datum/claimer = incident.claimed_by()
	if(!claimer || claimer == brain)
		if(istype(brain.current_goal(), /datum/netrun_bot_goal/police_patrol))
			brain.clear_goals()
		wake_behavior()

/datum/netrun_entity_module/bot_local/combat
	id = "bot_combat"
	priority = 130
	requires = list("vitals", "navigation")

/datum/netrun_entity_module/bot_local/combat/on_install()
	. = ..()
	listen(owner.console, COMSIG_NETRUN_ICE_CAST_STARTED, PROC_REF(on_ice_cast))
	listen(owner.console, COMSIG_NETRUN_COMBAT_CHANGED, PROC_REF(on_combat_changed))
	return .

/datum/netrun_entity_module/bot_local/combat/proc/on_ice_cast(datum/source, datum/netrun_ice/ice, datum/netrun_console/victim)
	SIGNAL_HANDLER
	if(victim && victim == owner.console)
		wake_behavior()

/datum/netrun_entity_module/bot_local/combat/proc/on_combat_changed(datum/source)
	SIGNAL_HANDLER
	wake_behavior()

/datum/netrun_entity_module/bot_local/combat/behavior_step(datum/netrun_bot_brain/brain)
	return brain ? brain.combat_step() : FALSE

/datum/netrun_entity_module/bot_return_wait
	id = "bot_return_wait"
	priority = 140
	requires = list("navigation")

/datum/netrun_entity_module/bot_return_wait/behavior_step(datum/netrun_bot_brain/brain)
	if(!brain)
		return FALSE
	var/mob/camera/netrun_entity/bot/bot = owner
	if(!istype(bot) || !bot.return_pending)
		return FALSE
	brain.state = "возврат пакета"
	return TRUE

/datum/netrun_entity_module/bot_goals
	id = "bot_goals"
	priority = 150
	requires = list("navigation", "bot_lifecycle")

/datum/netrun_entity_module/bot_goals/on_install()
	listen(owner, COMSIG_NETRUN_ENTITY_GOALS_CHANGED, PROC_REF(on_goals_changed))
	listen(owner, COMSIG_NETRUN_ENTITY_COMMAND_FINISHED, PROC_REF(on_command_finished))
	listen(owner, COMSIG_NETRUN_ENTITY_MODULE_READY, PROC_REF(on_ready))
	return TRUE

/datum/netrun_entity_module/bot_goals/proc/on_goals_changed(datum/source, during_behavior)
	SIGNAL_HANDLER
	owner.console?.invalidate_ui()
	if(!during_behavior)
		wake_behavior()

/datum/netrun_entity_module/bot_goals/proc/on_command_finished(datum/source)
	SIGNAL_HANDLER
	wake_behavior()

/datum/netrun_entity_module/bot_goals/proc/on_ready(datum/source, datum/netrun_entity_module/module)
	SIGNAL_HANDLER
	wake_behavior()

/datum/netrun_entity_module/bot_goals/behavior_step(datum/netrun_bot_brain/brain)
	if(!brain)
		return FALSE
	brain.advance_goals()
	return TRUE
