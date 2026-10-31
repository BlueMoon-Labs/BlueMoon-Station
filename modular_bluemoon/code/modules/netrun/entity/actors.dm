/// A network actor keeps its identity independently of its mob/datum representation.
/// Reading a contact never allocates a session for every dormant guard in the LAN.
/datum/proc/netrun_actor_node()
	return null

/datum/proc/netrun_actor_name()
	return null

/datum/proc/netrun_actor_console(create = TRUE)
	RETURN_TYPE(/datum/netrun_console)
	return null

/datum/proc/netrun_actor_faction()
	return null

/datum/proc/netrun_actor_autonomous()
	return FALSE

/datum/proc/netrun_actor_wake()
	return

/datum/proc/netrun_actor_present(datum/component/netrun_node/node)
	return FALSE

/mob/camera/netrun_entity/netrun_actor_node()
	return host_node

/mob/camera/netrun_entity/netrun_actor_name()
	return real_name

/mob/camera/netrun_entity/netrun_actor_console(create = TRUE)
	return QDELETED(console) ? null : console

/mob/camera/netrun_entity/netrun_actor_faction()
	return netrun_faction()

/mob/camera/netrun_entity/netrun_actor_autonomous()
	return !client && !!module_brain()

/mob/camera/netrun_entity/netrun_actor_wake()
	var/datum/netrun_bot_brain/brain = module_brain()
	if(!QDELETED(brain) && !brain.handling_behavior)
		brain.wake_now()

/mob/camera/netrun_entity/netrun_actor_present(datum/component/netrun_node/node)
	return !QDELETED(src) && !QDELETED(node) && !QDELETED(console) && host_node == node && (src in node.entities)

/datum/netrun_ice
	var/datum/netrun_console/ice/actor_console

/datum/netrun_ice/netrun_actor_node()
	return node

/datum/netrun_ice/netrun_actor_name()
	return name

/datum/netrun_ice/netrun_actor_console(create = TRUE)
	if(QDELETED(src) || QDELETED(agent?.memory))
		return null
	if(QDELETED(actor_console) && create)
		actor_console = new(src)
	return QDELETED(actor_console) ? null : actor_console

/datum/netrun_ice/netrun_actor_faction()
	if(!agent?.profile.illegal)
		return NETRUN_FACTION_STATION
	var/datum/principal = deployer_principal_ref?.resolve()
	var/datum/netrun_faction/private/personal/faction = principal ? SSnetrun.personal_factions_by_principal[REF(principal)] : null
	return faction?.id || NETRUN_FACTION_ROGUE

/datum/netrun_ice/netrun_actor_autonomous()
	return TRUE

/datum/netrun_ice/netrun_actor_wake()
	reaction?.wake()

/datum/netrun_ice/netrun_module_ready(datum/netrun_agent_behavior/module)
	// The profile is assembled before the constructor publishes its agent alias.
	if(!QDELETED(src) && !QDELETED(agent) && module?.installed)
		reaction?.wake()

/datum/netrun_ice/netrun_actor_present(datum/component/netrun_node/where)
	return !QDELETED(src) && !QDELETED(where) && !QDELETED(agent?.memory) && node == where && (src in where.netrun_ice)

/// Physical terminals are clients, while a resident session has one stable actor.
/datum/netrun_console/proc/netrun_actor()
	return null

/datum/netrun_console/entity/netrun_actor()
	return host

/// ICE acquires the ordinary command, intrusion and inventory services on demand.
/// Its profile remains the owner of memory; closing this session cannot erase it.
/datum/netrun_console/ice
	name = "защитный процесс"
	origin = NETRUN_ORIGIN_ENTITY
	var/datum/netrun_ice/actor

/datum/netrun_console/ice/New(datum/netrun_ice/actor)
	src.actor = actor
	// The guarded machine can be a player, implant or deck. It is an endpoint,
	// never the owner/operator of this independently authorized process.
	..(null, NETRUN_ORIGIN_ENTITY)
	connection.wireless = FALSE
	inventory.UnregisterSignal(inventory.local_store, COMSIG_NETRUN_STORAGE_CHANGED)
	inventory.local_store = actor.agent.memory
	inventory.RegisterSignal(inventory.local_store, COMSIG_NETRUN_STORAGE_CHANGED, TYPE_PROC_REF(/datum/netrun_inventory, on_store_changed))
	RegisterSignal(inventory.local_store, COMSIG_PARENT_QDELETING, PROC_REF(on_actor_deleted))
	RegisterSignal(actor, COMSIG_PARENT_QDELETING, PROC_REF(on_actor_deleted))
	RegisterSignal(actor, COMSIG_NETRUN_ICE_NODE_CHANGED, PROC_REF(on_actor_moved))
	bind_actor_node(actor.node)

/datum/netrun_console/ice/Destroy()
	if(actor)
		UnregisterSignal(actor, list(COMSIG_PARENT_QDELETING, COMSIG_NETRUN_ICE_NODE_CHANGED))
		if(actor.actor_console == src)
			actor.actor_console = null
	if(inventory)
		UnregisterSignal(inventory.local_store, COMSIG_PARENT_QDELETING)
		inventory.UnregisterSignal(inventory.local_store, COMSIG_NETRUN_STORAGE_CHANGED)
		inventory.local_store = inventory.owned_store
	actor = null
	return ..()

/datum/netrun_console/ice/proc/on_actor_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/netrun_console/ice/proc/on_actor_moved(datum/source, datum/component/netrun_node/previous, datum/component/netrun_node/current)
	SIGNAL_HANDLER
	// A puzzle belongs to the source residency at which it began.
	QDEL_NULL(intrusion.breach)
	SSnetrun.currentbreaches -= src
	bind_actor_node(current)

/datum/netrun_console/ice/proc/bind_actor_node(datum/component/netrun_node/node)
	map_view.selected_address = node?.address
	map_view.viewed_network_id = node?.network?.id

/datum/netrun_console/ice/netrun_actor()
	return actor

/// Keep combat_self() entity-only; the ICE facade remains its actual turn actor.
/datum/netrun_console/ice/program_use(uid, target_ref, turn_id)
	if(QDELETED(actor) || is_locked() || !istext(uid))
		return FALSE
	var/datum/netrun_file/file = find_local_file(uid)
	if(QDELETED(file) || file.kind != NETRUN_FILE_PROGRAM || !(file in actor.agent.memory.files))
		return FALSE
	var/datum/netrun_program/program = SSnetrun.get_program(file.content)
	if(!program)
		return FALSE
	var/datum/netrun_combat_encounter/encounter = actor.get_combat_encounter()
	if(!isnull(turn_id) && !encounter?.accepts_input(turn_id))
		return FALSE
	var/datum/target = actor
	if(program.needs_target)
		if(!istext(target_ref))
			return FALSE
		target = locate(target_ref)
		if(!istype(target) || QDELETED(target))
			return FALSE
	return actor.begin_program(program, target)

/datum/netrun_console/ice/physical_route_source()
	return refresh_route_node(actor?.node)

/datum/netrun_console/ice/physical_turf()
	return actor?.node?.physical_turf()

/datum/netrun_console/ice/set_jack(datum/component/netrun_node/node)
	// Resident processes cannot borrow a physical cable or its loopback authority.
	connection.set_jack(null)

/datum/netrun_console/ice/jack_valid()
	return FALSE

/datum/netrun_console/ice/user_access(fresh = FALSE)
	if(!fresh && access_cache)
		return access_cache
	return credential_access(fresh)

/datum/netrun_console/ice/home_networks()
	return actor?.node?.network ? list(actor.node.network) : list()

/datum/netrun_console/ice/is_home_network(datum/netrun_network/network, datum/netrun_path_tree/tree)
	return network && actor?.node?.network == network

/datum/netrun_console/ice/autonomous()
	return TRUE

/datum/netrun_console/ice/automates_breach_input()
	return TRUE

/datum/netrun_console/ice/personal_faction_principal()
	return actor?.deployer_principal_ref?.resolve() || actor

/datum/netrun_console/ice/get_handle()
	return actor?.name || ..()

/datum/netrun_console/ice/log_source()
	return "защитный процесс [actor?.name]"

/datum/netrun_console/ice/ui_status(mob/user, datum/ui_state/state)
	return UI_CLOSE

/datum/netrun_console/ice/finish_user_action(datum/component/netrun_node/node)
	if(!QDELETED(node))
		node.reconcile_state()
		node.wake_defenses()

/datum/netrun_console/ice/log_line(text, kind = "label", notice_topic)
	log += list(list("time" = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), "text" = text, "kind" = kind))
	if(length(log) > NETRUN_MAX_CONSOLE_LOG)
		log.Cut(1, length(log) - NETRUN_MAX_CONSOLE_LOG + 1)
	SEND_SIGNAL(src, COMSIG_NETRUN_CONSOLE_EVENT, text, kind)
