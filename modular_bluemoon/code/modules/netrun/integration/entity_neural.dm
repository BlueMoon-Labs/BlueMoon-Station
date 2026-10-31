/// Optional presentation capability. Autonomous agents share gameplay resources
/// with players without allocating screen monitors or a mobile display endpoint.
/datum/netrun_entity_module/neural_feedback
	id = "neural_feedback"
	priority = 60
	requires = list("console")
	var/datum/component/netrun_neural_feedback/feedback

/datum/netrun_entity_module/neural_feedback/on_install()
	var/datum/component/neural_interface/interface = owner.LoadComponent(/datum/component/neural_interface)
	feedback = owner.AddComponent(/datum/component/netrun_neural_feedback, interface, owner.console, "NETRUN_PROCESS")
	return !QDELETED(feedback)

/datum/netrun_entity_module/neural_feedback/on_remove()
	QDEL_NULL(feedback)

/// Feedback is composable: pAI and future clients can attach it without copying the display logic.
/datum/component/netrun_neural_feedback
	var/datum/component/neural_interface/interface
	var/datum/netrun_console/console
	var/source_id
	var/module_key
	var/last_uplink
	var/last_trace_band = 0
	var/last_locked = FALSE

/datum/component/netrun_neural_feedback/Initialize(datum/component/neural_interface/interface, datum/netrun_console/console, source_id)
	if(!ismob(parent) || !interface || !console)
		return COMPONENT_INCOMPATIBLE
	src.interface = interface
	src.console = console
	src.source_id = source_id
	module_key = "netrun:[source_id]"
	SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_ADD_SOURCE, source_id)
	var/datum/neural_interface_module/netrun/module = new(interface, console)
	module.visible = interface.visible
	interface.modules[module_key] = module
	SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Network interface connected.", "MODULE")

/datum/component/netrun_neural_feedback/RegisterWithParent()
	RegisterSignal(console, COMSIG_NETRUN_CONSOLE_EVENT, PROC_REF(on_console_event))
	RegisterSignal(console, COMSIG_PARENT_QDELETING, PROC_REF(on_dependency_deleted))
	RegisterSignal(interface, COMSIG_PARENT_QDELETING, PROC_REF(on_dependency_deleted))
	if(istype(parent, /mob/camera/netrun_entity))
		RegisterSignal(parent, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_node_changed))
		RegisterSignal(parent, COMSIG_NETRUN_ENTITY_INTEGRITY, PROC_REF(on_integrity))
		RegisterSignal(parent, COMSIG_NETRUN_ENTITY_TICK, PROC_REF(on_tick))
	else
		START_PROCESSING(SSfastprocess, src)

/datum/component/netrun_neural_feedback/UnregisterFromParent()
	STOP_PROCESSING(SSfastprocess, src)
	UnregisterSignal(parent, list(COMSIG_NETRUN_ENTITY_NODE_CHANGED, COMSIG_NETRUN_ENTITY_INTEGRITY, COMSIG_NETRUN_ENTITY_TICK))
	if(console)
		UnregisterSignal(console, list(COMSIG_NETRUN_CONSOLE_EVENT, COMSIG_PARENT_QDELETING))
	if(interface)
		UnregisterSignal(interface, COMSIG_PARENT_QDELETING)

/datum/component/netrun_neural_feedback/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	if(console)
		UnregisterSignal(console, list(COMSIG_NETRUN_CONSOLE_EVENT, COMSIG_PARENT_QDELETING))
	if(interface)
		UnregisterSignal(interface, COMSIG_PARENT_QDELETING)
	var/datum/component/neural_interface/old = interface
	interface = null
	console = null
	if(!QDELETED(old))
		var/datum/neural_interface_module/module = old.modules[module_key]
		old.modules -= module_key
		qdel(module)
		SEND_SIGNAL(old, COMSIG_NEURAL_INTERFACE_REMOVE_SOURCE, source_id)
	return ..()

/datum/component/netrun_neural_feedback/proc/on_dependency_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/component/netrun_neural_feedback/proc/on_console_event(datum/source, text, kind)
	SIGNAL_HANDLER
	var/category = kind == "bad" ? "ERROR" : kind == "average" ? "WARNING" : "DATA"
	SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_WRITE_LOG, netrun_neural_text(splittext("[text]", "\n")[1], 100), category)

/datum/component/netrun_neural_feedback/proc/on_node_changed(datum/source, datum/component/netrun_node/old_node, datum/component/netrun_node/new_node)
	SIGNAL_HANDLER
	SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_WRITE_LOG, new_node ? "Node: [netrun_neural_text(new_node.get_name())] [new_node.address]" : "Host link lost.", new_node ? "SYNC" : "WARNING")

/datum/component/netrun_neural_feedback/proc/on_integrity(datum/source, integrity, max_integrity, reason)
	SIGNAL_HANDLER
	SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Integrity [max(0, round(integrity))]/[max_integrity][reason ? ": [netrun_neural_text(reason)]" : ""].", "ALERT")

/datum/component/netrun_neural_feedback/proc/on_tick(datum/source, delta)
	SIGNAL_HANDLER
	update_feedback()

/datum/component/netrun_neural_feedback/process(delta_time)
	update_feedback()

/datum/component/netrun_neural_feedback/proc/update_feedback()
	if(QDELETED(interface) || QDELETED(console))
		return
	var/uplink = console.has_uplink()
	if(!isnull(last_uplink) && uplink != last_uplink)
		SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_WRITE_LOG, uplink ? "NTnet: connection restored." : "NTnet: connection lost.", uplink ? "SYNC" : "WARNING")
	last_uplink = uplink
	var/band = console.intrusion.trace >= 80 ? 2 : console.intrusion.trace >= 50 ? 1 : 0
	if(band > last_trace_band)
		SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Trace [round(console.intrusion.trace)]%.", band == 2 ? "ALERT" : "WARNING")
	last_trace_band = band
	var/locked = console.is_locked()
	if(locked && !last_locked)
		SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Network client locked.", "ERROR")
	last_locked = locked
	if(istype(parent, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = parent
		SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "INTEGRITY", "[max(0, round(entity.integrity))]/[entity.max_integrity]", 2 SECONDS, 10)
		SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "HOST", netrun_neural_text(entity.host_node ? "[entity.host_node.get_name()] [entity.host_node.address]" : "none"), 2 SECONDS, 5)
