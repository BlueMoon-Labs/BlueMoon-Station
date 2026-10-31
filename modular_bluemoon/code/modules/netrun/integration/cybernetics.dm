/// Physical connectivity remains live; map projections may retain their last observed position.
/atom/proc/netrun_network_enabled()
	return TRUE

/// Local cybernetics have an explicitly owned guard, not an infinitely respawning reaction.
/atom/proc/netrun_reactive_defense_allowed()
	return TRUE

/// Robotic tissue alone has no radio. The installed uplink connects the wearer's internal bus.
/obj/item/organ/proc/netrun_has_uplink()
	return FALSE

/obj/item/organ/cyberimp/brain/netlink/netrun_has_uplink()
	return TRUE

/obj/item/organ/cyberimp/brain/netlink/netrun_network_enabled()
	return owner && owner.netrun_network_enabled()

/obj/item/organ/cyberimp/brain/netlink/netrun_reactive_defense_allowed()
	return FALSE

/obj/item/organ/cyberimp/brain/netlink/publish_netrun_security_event(datum/netrun_incident/incident)
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	node?.wake_defenses()
	owner?.publish_netrun_security_event(incident)

/mob/living/carbon
	var/netrun_cyber_disconnected = FALSE
	var/datum/action/innate/netrun_cyber_link/netrun_cyber_link_action
	var/list/datum/weakref/netrun_cyber_uplinks
	var/netrun_cyber_links_indexed = FALSE

/mob/living/carbon/proc/netrun_rebuild_cyber_uplinks(obj/item/organ/removing)
	netrun_cyber_links_indexed = TRUE
	netrun_cyber_uplinks = null
	for(var/obj/item/organ/organ as anything in internal_organs)
		if(organ != removing && organ.netrun_has_uplink())
			LAZYADD(netrun_cyber_uplinks, WEAKREF(organ))

/mob/living/carbon/proc/netrun_has_cyber_uplink(obj/item/organ/removing)
	if(!netrun_cyber_links_indexed)
		netrun_rebuild_cyber_uplinks(removing)
	return LAZYLEN(netrun_cyber_uplinks) > 0

/mob/living/carbon/netrun_network_enabled()
	return !netrun_cyber_disconnected && netrun_has_cyber_uplink()

/mob/living/carbon/proc/netrun_cyber_uplink_available()
	if(stat == DEAD || !netrun_network_enabled())
		return FALSE
	for(var/datum/weakref/reference as anything in netrun_cyber_uplinks)
		var/obj/item/organ/organ = reference.resolve()
		if(!QDELETED(organ) && organ.owner == src && !organ.netrun_suppressed())
			return TRUE
	return FALSE

/mob/living/carbon/netrun_reactive_defense_allowed()
	return FALSE

/mob/living/carbon/netrun_owner_access(datum/netrun_console/console)
	return netrun_console_owner(console) == src ? NETRUN_ACCESS_ROOT : NETRUN_ACCESS_NONE

/// Native ownership gives an exact display binding; no endpoint or organ scan is needed.
/mob/living/carbon/proc/netrun_cyber_neural_endpoint()
	RETURN_TYPE(/obj/effect/netrun_endpoint/neural)
	var/datum/component/neural_interface/interface = GetComponent(/datum/component/neural_interface)
	var/datum/component/netrun_neural_adapter/adapter = interface?.GetComponent(/datum/component/netrun_neural_adapter)
	return adapter?.endpoint

/// Installation and explicit reconnect are the only provisioning boundaries.
/mob/living/carbon/proc/netrun_refresh_cyber_security(reconnect = FALSE)
	var/datum/component/netrun_node/bus = GetComponent(/datum/component/netrun_node)
	var/obj/effect/netrun_endpoint/neural/display = netrun_cyber_neural_endpoint()
	display?.refresh_cyber_defense(reconnect)
	if(!netrun_has_cyber_uplink())
		if(netrun_cyber_link_action)
			netrun_cyber_link_action.Remove(src)
			QDEL_NULL(netrun_cyber_link_action)
		var/datum/component/netrun_cyber_guard/defense = GetComponent(/datum/component/netrun_cyber_guard)
		QDEL_NULL(defense)
		return
	if(!netrun_cyber_link_action)
		netrun_cyber_link_action = new
		netrun_cyber_link_action.Grant(src)
	if(bus)
		var/datum/component/netrun_cyber_guard/defense = LoadComponent(/datum/component/netrun_cyber_guard, bus)
		if(reconnect)
			defense.reconnect()
	for(var/obj/item/organ/organ as anything in internal_organs)
		if(!organ.netrun_has_uplink())
			continue
		var/datum/component/netrun_node/endpoint = organ.GetComponent(/datum/component/netrun_node)
		endpoint?.refresh_physical_host()
		if(endpoint)
			var/datum/component/netrun_cyber_guard/defense = organ.LoadComponent(/datum/component/netrun_cyber_guard, endpoint)
			if(reconnect)
				defense.reconnect()
			endpoint.notify_changed(NETRUN_CHANGED_STATE)
	bus?.notify_changed(NETRUN_CHANGED_STATE)
	if(reconnect)
		var/datum/netrun_machine_service/security_events/service = get_netrun_machine_service("security.events")
		service?.network_ready()

/mob/living/carbon/proc/set_netrun_cyber_connected(connected)
	if(!netrun_has_cyber_uplink() || netrun_cyber_disconnected == !connected)
		return FALSE
	var/obj/effect/netrun_endpoint/neural/display = netrun_cyber_neural_endpoint()
	var/datum/component/netrun_node/neural_node = display?.GetComponent(/datum/component/netrun_node)
	if(!connected)
		neural_node?.observe_location(TRUE)
		var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
		node?.observe_location(TRUE)
		for(var/obj/item/organ/organ as anything in internal_organs)
			if(organ.netrun_has_uplink())
				node = organ.GetComponent(/datum/component/netrun_node)
				node?.observe_location(TRUE)
	netrun_cyber_disconnected = !connected
	// Keep addresses and files in place while offline. Only explicit reconnect
	// may replace a guard destroyed in combat; power/EMP recovery does not.
	if(!connected)
		var/datum/component/netrun_cyber_guard/defense = GetComponent(/datum/component/netrun_cyber_guard)
		defense?.disconnect()
		defense = display?.GetComponent(/datum/component/netrun_cyber_guard)
		defense?.disconnect()
		for(var/obj/item/organ/organ as anything in internal_organs)
			if(organ.netrun_has_uplink())
				defense = organ.GetComponent(/datum/component/netrun_cyber_guard)
				defense?.disconnect()
	netrun_refresh_cyber_security(reconnect = connected)
	neural_node?.notify_changed(NETRUN_CHANGED_STATE)
	to_chat(src, span_notice(connected ? "Сетевой интерфейс кибернетики подключён; локальная защита инициализирована." : "Сетевой интерфейс кибернетики отключён. Удалённые команды больше не принимаются."))
	return TRUE

/datum/action/innate/netrun_cyber_link
	name = "Связь кибернетики"
	desc = "Подключить или отключить собственную кибернетику от сети. После явного переподключения запускается локальный защитник."
	button_icon_state = "camera_off"
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	background_icon_state = "bg_tech_blue"

/datum/action/innate/netrun_cyber_link/Activate()
	var/mob/living/carbon/carbon = owner
	if(!istype(carbon) || carbon.stat != CONSCIOUS || carbon.incapacitated())
		return FALSE
	return carbon.set_netrun_cyber_connected(carbon.netrun_cyber_disconnected)

/// One sleeping guard belongs to this endpoint. Losing it does not clear the component.
/datum/component/netrun_cyber_guard
	var/datum/component/netrun_node/node
	var/datum/netrun_ice/guard

/datum/component/netrun_cyber_guard/Initialize(datum/component/netrun_node/node)
	if(!isatom(parent) || QDELETED(node) || node.parent != parent)
		return COMPONENT_INCOMPATIBLE
	src.node = node
	RegisterSignal(node, COMSIG_PARENT_QDELETING, PROC_REF(endpoint_deleted))
	reconnect()

/datum/component/netrun_cyber_guard/Destroy()
	if(node)
		UnregisterSignal(node, COMSIG_PARENT_QDELETING)
	QDEL_NULL(guard)
	node = null
	return ..()

/datum/component/netrun_cyber_guard/proc/endpoint_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/component/netrun_cyber_guard/proc/disconnect()
	QDEL_NULL(guard)

/datum/component/netrun_cyber_guard/proc/reconnect()
	if(!QDELETED(guard) || QDELETED(node) || !node.is_online())
		return
	guard = SSnetrun.spawn_ice(node, NETRUN_ICE_SENTRY)
	if(guard)
		guard.name = "CYBER-GUARD"
		guard.drops_loot = FALSE

/// Machine publishers use native discovery and a bounded subscription set.
/obj/machinery/power/apc/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/security_events)

/obj/machinery/ntnet_relay/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/security_events)

/// Aggregate station equipment at its physical APC instead of registering a publisher per leaf.
/atom/proc/publish_netrun_security_event(datum/netrun_incident/incident)
	if(!incident || !(incident.severity >= NETRUN_INCIDENT_HIGH || (incident.severity >= NETRUN_INCIDENT_MEDIUM && incident.reports >= 2)))
		return
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(!node)
		return
	var/atom/publisher = (node?.bound_apc?.parent) || src
	var/datum/netrun_machine_service/security_events/service = publisher.get_netrun_machine_service("security.events")
	if(!service)
		return
	var/list/event = incident.ui_entry()
	event["suspect"] = null
	event["area"] = get_area_name(node.physical_turf(), TRUE)
	service.queue_event(event)

/mob/living/carbon/netrun_machine_service_types()
	. = ..()
	if(netrun_has_cyber_uplink())
		. |= /datum/netrun_machine_service/security_events

/mob/living/carbon/publish_netrun_security_event(datum/netrun_incident/incident)
	if(!incident || !netrun_cyber_uplink_available())
		return
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(world.time >= netrun_next_intrusion_warn)
		netrun_next_intrusion_warn = world.time + 8 SECONDS
		to_chat(src, span_userdanger("ТРЕВОГА КИБЕРНЕТИКИ: [incident.text || "обнаружен взлом"]. Отключите сетевой интерфейс или поднимите сетевой экран."))
		SEND_SOUND(src, sound('sound/machines/triple_beep.ogg', volume = 50))
	node?.wake_defenses()
	var/datum/netrun_machine_service/security_events/service = get_netrun_machine_service("security.events")
	var/list/event = incident.ui_entry()
	event["area"] = get_area_name(src, TRUE)
	service?.queue_event(event)

/// Discovery notices and desired subscription state are replaceable control data.
/// One wire slot per peer retains the latest toggle, not every intermediate click.
/datum/netrun_machine_message/security_advertisement

/datum/netrun_machine_message/security_advertisement/New(generation)
	return ..(list("operation" = "advertise", "generation" = generation))

/datum/netrun_machine_message/security_advertisement/coalescing_key()
	return "security.advertise"

/// Control traffic must drain alongside its NORMAL discovery producers; opting
/// into replacement does not turn subscription setup into background telemetry.
/datum/netrun_machine_message/security_advertisement/delivery_priority()
	return NETRUN_TASK_NORMAL

/datum/netrun_machine_message/security_advertisement/can_replace(datum/netrun_machine_message/previous)
	return !istype(previous, /datum/netrun_machine_message/security_advertisement) || payload["generation"] >= previous.payload["generation"]

/datum/netrun_machine_message/security_subscription

/datum/netrun_machine_message/security_subscription/New(enabled, generation)
	return ..(list("operation" = enabled ? "subscribe" : "unsubscribe", "generation" = generation))

/datum/netrun_machine_message/security_subscription/coalescing_key()
	return "security.subscription"

/datum/netrun_machine_message/security_subscription/delivery_priority()
	return NETRUN_TASK_NORMAL

/datum/netrun_machine_message/security_subscription/can_replace(datum/netrun_machine_message/previous)
	return !istype(previous, /datum/netrun_machine_message/security_subscription) || payload["generation"] >= previous.payload["generation"]

/datum/netrun_machine_message/security_subscription/delivered(datum/netrun_machine_service/recipient_service)
	var/datum/netrun_machine_service/security_monitor/monitor = source
	var/datum/netrun_machine_service/security_events/publisher = recipient_service
	if(istype(monitor) && !QDELETED(monitor) && istype(publisher) && !QDELETED(publisher))
		monitor.acknowledge_subscription(publisher, payload["generation"], payload["operation"] == "subscribe")

/datum/netrun_machine_service/security_events
	service_id = "security.events"
	start_when_ready = TRUE
	var/list/subscribers = list()
	var/list/pending_events = list()
	var/list/publishing
	var/list/recipient_keys
	var/recipient_cursor = 1
	/// A new readiness announcement also repairs subscriptions pruned during an
	/// outage. An older acknowledgement cannot suppress this recovery generation.
	var/advertisement_generation = 0

/datum/netrun_machine_service/security_events/network_ready()
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	if(!transport.is_ready())
		// Cybernetics call this directly on reconnect, including during map loads;
		// unlike machinery they may receive no later native power-restored signal.
		transport.defer_ready_service(src)
		return
	advertisement_generation++
	send("security.monitor", new /datum/netrun_machine_message/security_advertisement(advertisement_generation))

/datum/netrun_machine_service/security_events/host_initialized()
	. = ..()
	on_station_network_restored()

/datum/netrun_machine_service/security_events/New(datum/component/netrun_node/node, atom/host_override)
	. = ..()
	if(ismachinery(host))
		RegisterSignal(host, list(COMSIG_MACHINERY_POWER_RESTORED, COMSIG_MACHINERY_STAT_CHANGED), PROC_REF(on_station_network_restored))

/datum/netrun_machine_service/security_events/proc/on_station_network_restored()
	SIGNAL_HANDLER
	// Only re-advertise after the initial bootstrap wave has finished. During startup the
	// shared service_ready barrier already runs network_ready for every start_when_ready
	// service; enqueuing per-APC service_initialize here (host_initialized plus every power/
	// stat signal as APCs settle) floods the scheduler and starves the network_bootstrap
	// continuation, delaying the readiness barrier past the test budget on large maps.
	if(SSnetrun.get_machine_transport().bootstrap_complete && resolve_node()?.is_online())
		SSnetrun.get_task_scheduler().enqueue("service_initialize", src, NETRUN_TASK_BACKGROUND)

/datum/netrun_machine_service/security_events/Destroy()
	if(ismachinery(host))
		UnregisterSignal(host, list(COMSIG_MACHINERY_POWER_RESTORED, COMSIG_MACHINERY_STAT_CHANGED))
	SSnetrun.task_scheduler?.cancel("security.publish", src)
	subscribers.Cut()
	pending_events.Cut()
	publishing = null
	recipient_keys = null
	return ..()

/datum/netrun_machine_service/security_events/receive(datum/netrun_machine_message/message)
	var/datum/netrun_machine_service/security_monitor/monitor = message.source
	if(!istype(monitor) || !monitor.authorized())
		return FALSE
	var/operation = message.payload["operation"]
	if(istype(message, /datum/netrun_machine_message/security_subscription) && (message.payload["generation"] != monitor.subscription_generation || (operation == "subscribe") != monitor.enabled))
		return FALSE
	var/key = monitor.service_key()
	if(operation == "unsubscribe")
		remove_subscriber(key)
		return TRUE
	if(operation != "subscribe" || !monitor.enabled)
		return FALSE
	var/datum/weakref/existing = subscribers[key]
	if(existing?.resolve() == monitor)
		return TRUE
	// A duplicate never scans peers. Only capacity pressure needs a bounded sweep
	// to admit a replacement; publication separately rechecks each live recipient.
	if(!existing && length(subscribers) >= 32)
		prune_subscribers()
		if(length(subscribers) >= 32)
			return FALSE
	subscribers[key] = WEAKREF(monitor)
	return TRUE

/// Dropping server state also retires its local acknowledgement hint. This is
/// bookkeeping only: it neither grants access nor changes a peer's desired state.
/datum/netrun_machine_service/security_events/proc/remove_subscriber(key)
	var/datum/weakref/reference = subscribers[key]
	var/datum/netrun_machine_service/security_monitor/monitor = reference?.resolve()
	if(istype(monitor) && !QDELETED(monitor))
		monitor.forget_subscription(src)
	subscribers -= key

/// A quiet publisher must also release retired subscriptions before admitting a replacement.
/datum/netrun_machine_service/security_events/proc/prune_subscribers()
	for(var/key in subscribers.Copy())
		var/datum/weakref/reference = subscribers[key]
		var/datum/netrun_machine_service/security_monitor/monitor = reference?.resolve()
		if(!istype(monitor) || QDELETED(monitor) || !monitor.enabled || !monitor.authorized())
			remove_subscriber(key)

/datum/netrun_machine_service/security_events/proc/queue_event(list/event)
	if(!length(subscribers))
		return
	pending_events[event["id"]] = event.Copy()
	if(length(pending_events) > 8)
		pending_events.Cut(1, length(pending_events) - 7)
	SSnetrun.get_task_scheduler().enqueue("security.publish", src, NETRUN_TASK_NORMAL)

/datum/netrun_machine_service/security_events/proc/publish_slice()
	if(!publishing)
		if(!length(pending_events))
			return TRUE
		var/id = pending_events[1]
		publishing = pending_events[id]
		pending_events -= id
		recipient_keys = subscribers.Copy()
		recipient_cursor = 1
	var/end = min(length(recipient_keys), recipient_cursor + 3)
	while(recipient_cursor <= end)
		var/key = recipient_keys[recipient_cursor++]
		var/datum/weakref/reference = subscribers[key]
		var/datum/netrun_machine_service/security_monitor/monitor = reference?.resolve()
		if(QDELETED(monitor) || !monitor.enabled || !monitor.authorized())
			remove_subscriber(key)
			continue
		send_to(monitor, new /datum/netrun_machine_message(list("operation" = "event", "event" = publishing)))
	if(recipient_cursor > length(recipient_keys))
		publishing = null
		recipient_keys = null
	return !publishing && !length(pending_events)

/datum/netrun_task/security_publish
	parent_type = /datum/netrun_task/continuation
	kind = "security.publish"

/datum/netrun_task/security_publish/advance(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_machine_service/security_events/service = target()
	return service.publish_slice()

/// AI and sanctioned police clients receive notices only after ordinary packet delivery.
/mob/living/silicon/ai/netrun_machine_service_types()
	. = ..()
	. |= /datum/netrun_machine_service/security_monitor

/mob/camera/netrun_entity/bot/netrun_machine_service_types()
	. = ..()
	if(bot_kind == NETRUN_BOT_POLICE)
		. |= /datum/netrun_machine_service/security_monitor

/mob/camera/netrun_entity/bot/netrun_machine_service_node()
	return host_node

/datum/netrun_machine_service/security_monitor
	service_id = "security.monitor"
	start_when_ready = TRUE
	var/list/alerts = list()
	var/enabled = TRUE
	/// Reject stale desired state even when separate discovery generations arrive
	/// out of order. Ordinary event packets still validate native authorization.
	var/subscription_generation = 0
	/// Bounded weak acknowledgements are only a traffic hint. Eviction permits an
	/// idempotent retry; it never grants authority or suppresses a new recovery.
	var/list/acknowledged_publishers = list()
	var/next_station_alarm = 0

/datum/netrun_machine_service/security_monitor/New(datum/component/netrun_node/node, atom/host_override)
	. = ..()
	if(istype(host, /mob/camera/netrun_entity/bot))
		RegisterSignal(host, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(position_changed))
	if(istype(host, /obj/machinery/computer/security))
		RegisterSignal(host, list(COMSIG_MACHINERY_POWER_RESTORED, COMSIG_MACHINERY_STAT_CHANGED), PROC_REF(on_station_network_restored))

/datum/netrun_machine_service/security_monitor/proc/on_station_network_restored()
	SIGNAL_HANDLER
	// Post-bootstrap only: see the matching note on security_events. The startup wave
	// already covers readiness; signal-driven re-initialization is a live-round concern.
	if(SSnetrun.get_machine_transport().bootstrap_complete && enabled && authorized())
		SSnetrun.get_task_scheduler().enqueue("service_initialize", src, NETRUN_TASK_BACKGROUND)

/datum/netrun_machine_service/security_monitor/Destroy()
	acknowledged_publishers.Cut()
	if(host)
		UnregisterSignal(host, COMSIG_NETRUN_ENTITY_NODE_CHANGED)
		if(istype(host, /obj/machinery/computer/security))
			UnregisterSignal(host, list(COMSIG_MACHINERY_POWER_RESTORED, COMSIG_MACHINERY_STAT_CHANGED))
	return ..()

/datum/netrun_machine_service/security_monitor/proc/position_changed()
	SIGNAL_HANDLER
	node = resolve_node()
	SSnetrun.get_machine_transport().index_service(src)

/datum/netrun_machine_service/security_monitor/resolve_node()
	if(istype(host, /mob/camera/netrun_entity/bot))
		var/mob/camera/netrun_entity/bot/bot = host
		return bot.host_node
	return ..()

/datum/netrun_machine_service/security_monitor/proc/authorized()
	if(istype(host, /obj/machinery/computer/security))
		var/obj/machinery/computer/security/console = host
		return console.netrun_online()
	if(istype(host, /mob/living/silicon/ai))
		var/mob/living/silicon/ai/ai = host
		return ai.netrun_control_available()
	var/mob/camera/netrun_entity/bot/bot = host
	return istype(bot) && bot.bot_kind == NETRUN_BOT_POLICE && !QDELETED(bot.console)

/datum/netrun_machine_service/security_monitor/network_ready()
	if(enabled && authorized())
		subscription_generation++
		acknowledged_publishers.Cut()
		send("security.events", new /datum/netrun_machine_message/security_subscription(TRUE, subscription_generation))

/datum/netrun_machine_service/security_monitor/proc/acknowledge_subscription(datum/netrun_machine_service/security_events/publisher, generation, subscribed)
	if(QDELETED(publisher) || generation != subscription_generation || subscribed != enabled)
		return
	var/key = publisher.service_key()
	if(!subscribed)
		acknowledged_publishers -= key
		return
	if(!acknowledged_publishers[key] && length(acknowledged_publishers) >= 512)
		acknowledged_publishers.Cut(1, 2)
	acknowledged_publishers[key] = list("publisher" = WEAKREF(publisher), "generation" = generation, "advertisement_generation" = publisher.advertisement_generation)

/datum/netrun_machine_service/security_monitor/proc/subscription_acknowledged(datum/netrun_machine_service/security_events/publisher, advertisement_generation)
	var/list/acknowledgement = acknowledged_publishers[publisher.service_key()]
	if(!acknowledgement || acknowledgement["generation"] != subscription_generation || acknowledgement["advertisement_generation"] < advertisement_generation)
		return FALSE
	var/datum/weakref/reference = acknowledgement["publisher"]
	return reference?.resolve() == publisher

/datum/netrun_machine_service/security_monitor/proc/forget_subscription(datum/netrun_machine_service/security_events/publisher)
	var/key = publisher.service_key()
	var/list/acknowledgement = acknowledged_publishers[key]
	if(!acknowledgement)
		return
	var/datum/weakref/reference = acknowledgement["publisher"]
	if(reference?.resolve() == publisher)
		acknowledged_publishers -= key

/datum/netrun_machine_service/security_monitor/proc/set_subscription(value)
	if(!authorized())
		return FALSE
	value = !!value
	if(enabled == value)
		return TRUE
	enabled = value
	subscription_generation++
	acknowledged_publishers.Cut()
	return send("security.events", new /datum/netrun_machine_message/security_subscription(enabled, subscription_generation))

/datum/netrun_machine_service/security_monitor/receive(datum/netrun_machine_message/message)
	if(!enabled || !authorized() || !istype(message.source, /datum/netrun_machine_service/security_events))
		return FALSE
	if(message.payload["operation"] == "advertise")
		if(istype(message, /datum/netrun_machine_message/security_advertisement) && subscription_acknowledged(message.source, message.payload["generation"]))
			return TRUE
		return send_to(message.source, new /datum/netrun_machine_message/security_subscription(TRUE, subscription_generation))
	var/list/event = message.payload["event"]
	if(message.payload["operation"] != "event" || !islist(event))
		return FALSE
	if(istype(host, /obj/machinery/computer/security))
		if(!(event["severity"] >= NETRUN_INCIDENT_HIGH || (event["severity"] >= NETRUN_INCIDENT_MEDIUM && event["reports"] >= 2)))
			return FALSE
		// Keep one current row per incident, with no actor identity in the public journal.
		event = event.Copy()
		event["suspect"] = null
		for(var/list/previous as anything in alerts.Copy())
			if(previous["id"] == event["id"])
				alerts -= list(previous)
	alerts += list(event.Copy())
	if(length(alerts) > 32)
		alerts.Cut(1, length(alerts) - 31)
	var/text = "Сетевая тревога [event["id"]]: [event["text"] || event["kind"]] @ [event["address"]]."
	if(istype(host, /mob/living/silicon/ai))
		to_chat(host, span_warning(text))
	else if(istype(host, /obj/machinery/computer/security))
		var/obj/machinery/computer/security/console = host
		if(world.time >= next_station_alarm)
			next_station_alarm = world.time + 8 SECONDS
			console.say("Сетевая тревога: [event["area"] || "район не определён"], узел [event["address"]]. Проверьте журнал сетевых тревог и оборудование сектора.")
			playsound(console, 'sound/machines/triple_beep.ogg', 40, FALSE)
		SStgui.update_uis(console)
	else
		var/mob/camera/netrun_entity/bot/bot = host
		bot.console.log_line(text, "bad")
		bot.brain.wake_now()
	return TRUE

/// The real AI client can opt out and resubscribe through the same native service.
/datum/netrun_console/ai/host_actions()
	. = ..()
	var/datum/netrun_machine_service/security_monitor/service = host.get_netrun_machine_service("security.monitor")
	. += list(list("id" = "security_subscription", "name" = service?.enabled ? "Отключить сетевые тревоги" : "Подписаться на сетевые тревоги", "icon" = "shield-halved"))

/datum/netrun_console/ai/host_act(action, list/params, mob/user)
	if(action != "security_subscription")
		return ..()
	if(!available_to(user))
		return FALSE
	var/datum/netrun_machine_service/security_monitor/service = host.get_netrun_machine_service("security.monitor")
	return service?.set_subscription(!service.enabled)
