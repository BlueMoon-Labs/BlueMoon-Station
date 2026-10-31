/** Native atmosphere automation speaks through the same routed network as runners. */
/datum/netrun_machine_message/atmos
	var/datum/weakref/registration_ref

/datum/netrun_machine_message/atmos/copy()
	var/datum/netrun_machine_message/atmos/result = ..()
	result.registration_ref = registration_ref
	return result

/datum/netrun_machine_message/atmos/delivered(datum/netrun_machine_service/recipient_service)
	var/datum/netrun_machine_service/atmos/device/device = registration_ref?.resolve()
	if(istype(recipient_service, /datum/netrun_machine_service/atmos/controller))
		device?.acknowledge_controller(recipient_service)

/datum/netrun_machine_message/atmos/failed(reason)
	. = ..()
	if(payload["sigtype"] != "status")
		return
	var/datum/netrun_machine_service/atmos/device/device = registration_ref?.resolve()
	if(QDELETED(device) || QDELETED(device.host))
		return
	device.refresh_registration()
	if(istype(recipient, /datum/netrun_machine_service/atmos/controller))
		var/datum/netrun_machine_service/atmos/controller/controller = recipient
		if(!QDELETED(controller) && controller.matches(device, null))
			device.acknowledged_controllers -= REF(controller)
	else if(isnull(recipient))
		// A discovery that failed before selecting a recipient still needs to
		// invalidate prior ACKs for matching controllers in the current area.
		var/list/controllers = SSnetrun.get_machine_transport().atmos_controllers_by_area[REF(device.registration_area)]
		for(var/datum/netrun_machine_service/atmos/controller/controller as anything in controllers)
			if(!QDELETED(controller) && controller.matches(device, null))
				device.acknowledged_controllers -= REF(controller)
	device.arm_registration()

/datum/netrun_machine_message/atmos/coalescing_key()
	if(payload["sigtype"] == "status")
		return "[payload["device"]]:[payload["tag"]]"
	if(payload["sigtype"] == "command" && ("status" in payload) && length(payload) <= 3)
		// Native read-only polls carry only tag, sigtype and status. Real orders
		// remain independent even when they also ask for a resulting status.
		return "atmos.poll:[payload["tag"]]"
	return null

/// Actor provenance is separate from the copied wire payload.
/atom/proc/netrun_atmos_send(source_id, destination_id, list/data, mob/user, recipient_tag)
	var/datum/netrun_machine_service/service = get_netrun_machine_service(source_id)
	if(!service)
		return FALSE
	// Message construction already owns a deep copy; strip actor provenance
	// from that copy without cloning every atmosphere payload twice.
	var/datum/netrun_machine_message/atmos/message = new(data)
	var/list/wire_data = message.payload
	wire_data -= "user"
	if(destination_id == "atmos.controller" && wire_data["sigtype"] == "status" && istype(service, /datum/netrun_machine_service/atmos/device))
		var/datum/netrun_machine_service/atmos/device/device = service
		device.refresh_registration()
		message.registration_ref = WEAKREF(device)
		device.arm_registration()
	if(user)
		message.user_ref = WEAKREF(user)
	return service.send(destination_id, message, recipient_tag)

/datum/netrun_machine_service/atmos
	var/area/registration_area

/datum/netrun_machine_transport
	/// These small area buckets avoid a station-wide alarm/device scan per retry.
	var/list/atmos_devices_by_area = list()
	var/list/atmos_controllers_by_area = list()

/datum/netrun_machine_service/atmos/proc/unindex_registration(list/index)
	if(!registration_area)
		return
	var/key = REF(registration_area)
	var/list/bucket = index[key]
	if(bucket)
		bucket -= src
	if(!length(bucket))
		index -= key
	registration_area = null

/datum/netrun_machine_service/atmos/proc/index_registration(list/index)
	var/area/current = get_base_area(host)
	if(current == registration_area)
		return FALSE
	unindex_registration(index)
	registration_area = current
	if(current)
		var/key = REF(current)
		var/list/bucket = index[key]
		if(!bucket)
			bucket = list()
			index[key] = bucket
		bucket |= src
	return TRUE

/datum/netrun_machine_service/atmos/proc/control_frequency()
	return null

/datum/netrun_machine_service/atmos/proc/same_channel(datum/netrun_machine_service/atmos/other)
	return istype(other) && control_frequency() && control_frequency() == other.control_frequency()

/datum/netrun_machine_service/atmos/controller
	service_id = "atmos.controller"
	var/registered_frequency

/datum/netrun_machine_service/atmos/controller/New(datum/component/netrun_node/node, atom/host_override)
	..(node, host_override)
	index_registration(SSnetrun.get_machine_transport().atmos_controllers_by_area)
	registered_frequency = control_frequency()
	RegisterSignal(host, list(COMSIG_MACHINERY_POWER_LOST, COMSIG_MACHINERY_POWER_RESTORED, COMSIG_MACHINERY_STAT_CHANGED, COMSIG_MOVABLE_MOVED), PROC_REF(registration_changed))
	rearm_local_devices()

/datum/netrun_machine_service/atmos/controller/Destroy()
	if(host)
		UnregisterSignal(host, list(COMSIG_MACHINERY_POWER_LOST, COMSIG_MACHINERY_POWER_RESTORED, COMSIG_MACHINERY_STAT_CHANGED, COMSIG_MOVABLE_MOVED))
	rearm_local_devices()
	unindex_registration(SSnetrun.get_machine_transport().atmos_controllers_by_area)
	return ..()

/datum/netrun_machine_service/atmos/controller/host_initialized()
	. = ..()
	var/changed = index_registration(SSnetrun.get_machine_transport().atmos_controllers_by_area)
	if(changed || registered_frequency != control_frequency())
		registered_frequency = control_frequency()
		rearm_local_devices()

/datum/netrun_machine_service/atmos/controller/proc/registration_changed()
	SIGNAL_HANDLER
	rearm_local_devices()
	if(index_registration(SSnetrun.get_machine_transport().atmos_controllers_by_area))
		rearm_local_devices()

/datum/netrun_machine_service/atmos/controller/proc/rearm_local_devices()
	var/list/bucket = SSnetrun.get_machine_transport().atmos_devices_by_area[REF(registration_area)]
	for(var/datum/netrun_machine_service/atmos/device/device as anything in bucket)
		device.acknowledged_controllers -= REF(src)
		device.registration_attempts = 0
		device.arm_registration(world.tick_lag)

/datum/netrun_machine_service/atmos/controller/control_frequency()
	var/obj/machinery/airalarm/alarm = host
	return alarm.frequency

/datum/netrun_machine_service/atmos/controller/matches(datum/netrun_machine_service/source_service, recipient_tag)
	return ..() && istype(source_service, /datum/netrun_machine_service/atmos/device) && same_channel(source_service) && get_base_area(host) == get_base_area(source_service.host)

/datum/netrun_machine_service/atmos/controller/discovery_candidates(destination_id, recipient_tag)
	if(destination_id == "atmos.device" && isnull(recipient_tag))
		return SSnetrun.get_machine_transport().atmos_devices_by_area[REF(get_base_area(host))]
	return ..()

/datum/netrun_machine_service/atmos/controller/accepts(datum/netrun_machine_message/message)
	return ..() && istype(message, /datum/netrun_machine_message/atmos) && message.payload["sigtype"] == "status" && message.payload["tag"] == message.source.service_tag() && matches(message.source, null)

/datum/netrun_machine_service/atmos/controller/receive(datum/netrun_machine_message/message)
	var/obj/machinery/airalarm/alarm = host
	var/tag = message.payload["tag"]
	if(message.payload["device"] == "VP")
		alarm.netrun_vent_info[tag] = netrun_copy_wire_value(message.payload)
	else if(message.payload["device"] == "VS")
		alarm.netrun_scrub_info[tag] = netrun_copy_wire_value(message.payload)
	else
		return FALSE
	SStgui.update_uis(alarm)
	SEND_SIGNAL(alarm, COMSIG_NETRUN_SERVICE_STATE_CHANGED)
	return TRUE

/datum/netrun_machine_service/atmos/alarm_source
	service_id = "atmos.alarm"

/datum/netrun_machine_service/atmos/alarm_source/control_frequency()
	var/obj/machinery/airalarm/alarm = host
	return alarm.alarm_frequency

/datum/netrun_machine_service/atmos/device
	service_id = "atmos.device"
	start_when_ready = TRUE
	var/list/acknowledged_controllers = list()
	var/registration_tag
	var/registration_frequency
	var/registration_timer
	var/registration_at = INFINITY
	var/registration_attempts = 0

/datum/netrun_machine_service/atmos/device/New(datum/component/netrun_node/node, atom/host_override)
	..(node, host_override)
	refresh_registration()
	RegisterSignal(host, list(COMSIG_MACHINERY_POWER_LOST, COMSIG_MACHINERY_POWER_RESTORED, COMSIG_MACHINERY_STAT_CHANGED, COMSIG_MOVABLE_MOVED), PROC_REF(registration_changed))
	if(registration_required())
		arm_registration(world.tick_lag)

/datum/netrun_machine_service/atmos/device/Destroy()
	SSnetrun.task_scheduler?.cancel("atmos_registration", src)
	if(registration_timer)
		deltimer(registration_timer)
	if(host)
		UnregisterSignal(host, list(COMSIG_MACHINERY_POWER_LOST, COMSIG_MACHINERY_POWER_RESTORED, COMSIG_MACHINERY_STAT_CHANGED, COMSIG_MOVABLE_MOVED))
	unindex_registration(SSnetrun.get_machine_transport().atmos_devices_by_area)
	acknowledged_controllers.Cut()
	return ..()

/datum/netrun_machine_service/atmos/device/host_initialized()
	. = ..()
	if(refresh_registration() && registration_required())
		registration_attempts = 0
		arm_registration(world.tick_lag)

/// Avoid running thousands of retries while the common network bootstrap is
/// still preparing APC routes. Each device gets one bounded readiness callback.
/datum/netrun_machine_service/atmos/device/network_ready()
	if(registration_required())
		arm_registration(world.tick_lag)

/datum/netrun_machine_service/atmos/device/proc/registration_required()
	return istype(host, /obj/machinery/atmospherics/components/unary/vent_pump) || istype(host, /obj/machinery/atmospherics/components/unary/vent_scrubber)

/datum/netrun_machine_service/atmos/device/proc/refresh_registration()
	// All device types belong to the native area index, including pumps/injectors
	// which accept commands but do not participate in air-alarm registration.
	var/changed = index_registration(SSnetrun.get_machine_transport().atmos_devices_by_area)
	if(!registration_required())
		return changed
	if(changed || registration_tag != service_tag() || registration_frequency != control_frequency())
		registration_tag = service_tag()
		registration_frequency = control_frequency()
		acknowledged_controllers.Cut()
		return TRUE
	return FALSE

/datum/netrun_machine_service/atmos/device/proc/registration_changed()
	SIGNAL_HANDLER
	refresh_registration()
	acknowledged_controllers.Cut()
	registration_attempts = 0
	arm_registration(world.tick_lag)

/datum/netrun_machine_service/atmos/device/proc/registration_complete()
	var/found = FALSE
	var/list/bucket = SSnetrun.get_machine_transport().atmos_controllers_by_area[REF(registration_area)]
	for(var/datum/netrun_machine_service/atmos/controller/controller as anything in bucket)
		if(QDELETED(controller) || !controller.matches(src, null))
			continue
		found = TRUE
		var/datum/weakref/ack = acknowledged_controllers[REF(controller)]
		if(ack?.resolve() != controller)
			return FALSE
	return found

/datum/netrun_machine_service/atmos/device/proc/acknowledge_controller(datum/netrun_machine_service/atmos/controller/controller)
	refresh_registration()
	if(QDELETED(controller) || !controller.matches(src, null))
		return
	acknowledged_controllers[REF(controller)] = WEAKREF(controller)
	// A real acknowledgement is progress, so give any still-unacked controllers a fresh budget.
	registration_attempts = 0
	if(registration_complete())
		if(registration_timer)
			deltimer(registration_timer)
		registration_timer = null
		registration_at = INFINITY
		SSnetrun.task_scheduler?.cancel("atmos_registration", src)

/datum/netrun_machine_service/atmos/device/proc/arm_registration(delay)
	if(!SSnetrun.get_machine_transport().bootstrap_complete)
		return
	if(isnull(delay))
		// A long APC/cable outage must not permanently strand an otherwise live
		// device. Keep probing slowly after the initial fast retry window.
		delay = registration_attempts >= NETRUN_ATMOS_REGISTRATION_MAX_ATTEMPTS ? 30 SECONDS : 5 SECONDS
	if(!registration_required() || QDELETED(src) || (registration_timer && registration_at <= world.time + delay))
		return
	if(registration_timer)
		deltimer(registration_timer)
	registration_at = world.time + delay
	registration_timer = addtimer(CALLBACK(src, PROC_REF(queue_registration)), delay, TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_machine_service/atmos/device/proc/queue_registration()
	registration_timer = null
	registration_at = INFINITY
	if(!QDELETED(host))
		SSnetrun.get_task_scheduler().enqueue("atmos_registration", src, NETRUN_TASK_BACKGROUND)

/datum/netrun_machine_service/atmos/device/proc/retry_registration()
	refresh_registration()
	if(registration_complete())
		registration_attempts = 0
		return
	var/online_missing = FALSE
	var/list/bucket = SSnetrun.get_machine_transport().atmos_controllers_by_area[REF(registration_area)]
	for(var/datum/netrun_machine_service/atmos/controller/controller as anything in bucket)
		var/datum/weakref/ack = acknowledged_controllers[REF(controller)]
		if(!QDELETED(controller) && controller.matches(src, null) && ack?.resolve() != controller && controller.resolve_node()?.is_online())
			online_missing = TRUE
			break
	if(!(resolve_node()?.is_online() && control_frequency()))
		// We cannot emit right now (offline or unconfigured). Our own power/config signals
		// reliably re-arm us once we can, so there is no point spinning in the meantime.
		return
	if(!online_missing)
		// No reachable compatible alarm is indexed for our area yet. This is routinely transient:
		// during a late reactor/shuttle load the alarm (or its own area index) can settle after our
		// first probe, and the rearm/power signals that would otherwise wake us can race that
		// indexing. Rather than permanently stranding a live, configured vent -- the cause of the
		// flaky missing-registration failures on large maps -- keep a backing-off probe that
		// re-indexes us (refresh_registration) each pass and relinks deterministically once a
		// compatible alarm is online and co-indexed. The 5s->30s backoff keeps a genuinely
		// alarm-less area from churning the scheduler.
		registration_attempts = min(registration_attempts + 1, NETRUN_ATMOS_REGISTRATION_MAX_ATTEMPTS)
		arm_registration()
		return
	// Controller registration uses the live APC service registry.
	// Do not resend statuses to an absent or entirely powered-down area.
	registration_attempts = min(registration_attempts + 1, NETRUN_ATMOS_REGISTRATION_MAX_ATTEMPTS)
	var/obj/machinery/atmospherics/components/unary/device = host
	if(istype(device, /obj/machinery/atmospherics/components/unary/vent_pump))
		var/obj/machinery/atmospherics/components/unary/vent_pump/vent = device
		vent.broadcast_status()
	else
		var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = device
		scrubber.broadcast_status()
	arm_registration()

/datum/netrun_task/atmos_registration
	kind = "atmos_registration"

/datum/netrun_task/atmos_registration/execute(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_machine_service/atmos/device/device = target()
	if(QDELETED(device))
		return FALSE
	device.retry_registration()
	return TRUE

/datum/netrun_machine_service/atmos/device/matches(datum/netrun_machine_service/source_service, recipient_tag)
	if(!..() || !same_channel(source_service))
		return FALSE
	if(istype(source_service, /datum/netrun_machine_service/atmos/controller))
		return get_base_area(host) == get_base_area(source_service.host)
	if(istype(source_service, /datum/netrun_machine_service/atmos/monitor))
		var/obj/machinery/computer/atmos_control/tank/controller = source_service.host
		return istype(controller) && (service_tag() == controller.input_tag || service_tag() == controller.output_tag || isnull(recipient_tag))
	if(istype(source_service, /datum/netrun_machine_service/atmos/vent_controller))
		var/obj/machinery/embedded_controller/radio/simple_vent_controller/controller = source_service.host
		return service_tag() == controller.airpump_tag
	return FALSE

/datum/netrun_machine_service/atmos/device/discovery_candidates(destination_id, recipient_tag)
	if(destination_id == "atmos.controller" && isnull(recipient_tag))
		return SSnetrun.get_machine_transport().atmos_controllers_by_area[REF(get_base_area(host))]
	return ..()

/// Alarms are already indexed by physical area. Once startup is complete,
/// send status to those known recipients directly instead of creating a new
/// discovery task for every vent retry. Delivery remains asynchronous and
/// still validates the route and recipient before changing an alarm.
/datum/netrun_machine_service/atmos/device/send(destination_id, datum/netrun_machine_message/message, recipient_tag)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	if(destination_id != "atmos.controller" || !isnull(recipient_tag) || QDELETED(message) || message.payload["sigtype"] != "status")
		return ..()
	if(!transport.bootstrap_complete)
		// The readiness callback broadcasts the then-current status. Keeping
		// thousands of obsolete startup snapshots would delay the bootstrap itself.
		qdel(message)
		return TRUE
	if(!transport.is_ready())
		return ..()
	var/sent = FALSE
	var/list/controllers = transport.atmos_controllers_by_area[REF(get_base_area(host))]
	var/datum/netrun_machine_service/atmos/controller/pending
	for(var/datum/netrun_machine_service/atmos/controller/controller as anything in controllers)
		if(!QDELETED(controller) && controller.matches(src, null))
			if(pending)
				sent = send_to(pending, message.copy()) || sent
			pending = controller
	if(pending)
		// The final recipient takes ownership of the original. With one local
		// alarm there is no reason to copy and then immediately delete it.
		sent = send_to(pending, message) || sent
	else
		message.failed("Служба недоступна по сети APC")
		qdel(message)
	return sent

/datum/netrun_machine_service/atmos/device/accepts(datum/netrun_machine_message/message)
	return ..() && istype(message, /datum/netrun_machine_message/atmos) && message.payload["sigtype"] == "command" && message.payload["tag"] == service_tag() && matches(message.source, service_tag())

/datum/netrun_machine_service/atmos/device/receive(datum/netrun_machine_message/message)
	var/list/data = netrun_copy_wire_value(message.payload)
	data["user"] = message.user_ref?.resolve()
	var/datum/signal/signal = new(data)
	var/obj/machinery/machine = host
	machine.receive_signal(signal)
	qdel(signal)
	return TRUE

/datum/netrun_machine_service/atmos/device/vent

/datum/netrun_machine_service/atmos/device/vent/service_tag()
	var/obj/machinery/atmospherics/components/unary/vent_pump/device = host
	return device.id_tag

/datum/netrun_machine_service/atmos/device/vent/control_frequency()
	var/obj/machinery/atmospherics/components/unary/vent_pump/device = host
	return device.frequency

/datum/netrun_machine_service/atmos/device/scrubber

/datum/netrun_machine_service/atmos/device/scrubber/service_tag()
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/device = host
	return device.id_tag

/datum/netrun_machine_service/atmos/device/scrubber/control_frequency()
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/device = host
	return device.frequency

/datum/netrun_machine_service/atmos/device/injector

/datum/netrun_machine_service/atmos/device/injector/service_tag()
	var/obj/machinery/atmospherics/components/unary/outlet_injector/device = host
	return device.id

/datum/netrun_machine_service/atmos/device/injector/control_frequency()
	var/obj/machinery/atmospherics/components/unary/outlet_injector/device = host
	return device.frequency

/datum/netrun_machine_service/atmos/device/pump

/datum/netrun_machine_service/atmos/device/pump/service_tag()
	var/obj/machinery/atmospherics/components/binary/pump/device = host
	return device.id

/datum/netrun_machine_service/atmos/device/pump/control_frequency()
	var/obj/machinery/atmospherics/components/binary/pump/device = host
	return device.frequency

/datum/netrun_machine_service/atmos/device/volume_pump

/datum/netrun_machine_service/atmos/device/volume_pump/service_tag()
	var/obj/machinery/atmospherics/components/binary/volume_pump/device = host
	return device.id

/datum/netrun_machine_service/atmos/device/volume_pump/control_frequency()
	var/obj/machinery/atmospherics/components/binary/volume_pump/device = host
	return device.frequency

/datum/netrun_machine_service/atmos/sensor
	service_id = "atmos.sensor"

/datum/netrun_machine_service/atmos/sensor/service_tag()
	var/obj/machinery/air_sensor/sensor = host
	return sensor.id_tag

/datum/netrun_machine_service/atmos/sensor/control_frequency()
	var/obj/machinery/air_sensor/sensor = host
	return sensor.frequency

/datum/netrun_machine_service/atmos/sensor/matches(datum/netrun_machine_service/source_service, recipient_tag)
	return ..() && istype(source_service, /datum/netrun_machine_service/atmos/monitor) && same_channel(source_service)

/datum/netrun_machine_service/atmos/sensor/meter

/datum/netrun_machine_service/atmos/sensor/meter/service_tag()
	var/obj/machinery/meter/meter = host
	return meter.id_tag

/datum/netrun_machine_service/atmos/sensor/meter/control_frequency()
	var/obj/machinery/meter/meter = host
	return meter.frequency

/datum/netrun_machine_service/atmos/vent_controller
	service_id = "atmos.vent_controller"

/datum/netrun_machine_service/atmos/vent_controller/control_frequency()
	var/obj/machinery/embedded_controller/radio/simple_vent_controller/controller = host
	return controller.frequency

/datum/netrun_machine_service/atmos/vent_controller/matches(datum/netrun_machine_service/source_service, recipient_tag)
	if(!..() || !istype(source_service, /datum/netrun_machine_service/atmos/device) || !same_channel(source_service))
		return FALSE
	var/obj/machinery/embedded_controller/radio/simple_vent_controller/controller = host
	return source_service.service_tag() == controller.airpump_tag

/datum/netrun_machine_service/atmos/vent_controller/accepts(datum/netrun_machine_message/message)
	return ..() && istype(message, /datum/netrun_machine_message/atmos) && matches(message.source, null)

/datum/netrun_machine_service/atmos/vent_controller/receive(datum/netrun_machine_message/message)
	var/obj/machinery/embedded_controller/controller = host
	var/datum/signal/signal = new(netrun_copy_wire_value(message.payload))
	controller.receive_signal(signal)
	qdel(signal)
	controller.updateDialog()
	return TRUE

/datum/netrun_machine_service/atmos/monitor
	service_id = "atmos.monitor"

/datum/netrun_machine_service/atmos/monitor/control_frequency()
	var/obj/machinery/computer/atmos_control/monitor = host
	return monitor.frequency

/datum/netrun_machine_service/atmos/monitor/matches(datum/netrun_machine_service/source_service, recipient_tag)
	if(!..() || !same_channel(source_service))
		return FALSE
	var/obj/machinery/computer/atmos_control/monitor = host
	if(istype(source_service, /datum/netrun_machine_service/atmos/sensor))
		return source_service.service_tag() in monitor.sensors
	if(istype(source_service, /datum/netrun_machine_service/atmos/device))
		var/obj/machinery/computer/atmos_control/tank/tank = host
		return istype(tank) && (source_service.service_tag() == tank.input_tag || source_service.service_tag() == tank.output_tag)
	return FALSE

/datum/netrun_machine_service/atmos/monitor/accepts(datum/netrun_machine_message/message)
	if(!..() || !istype(message, /datum/netrun_machine_message/atmos) || message.payload["sigtype"] != "status" || !matches(message.source, null))
		return FALSE
	var/source_tag = message.payload["tag"]
	if(isnull(source_tag))
		source_tag = message.payload["id_tag"]
	return source_tag == message.source.service_tag()

/datum/netrun_machine_service/atmos/monitor/receive(datum/netrun_machine_message/message)
	var/datum/signal/signal = new(netrun_copy_wire_value(message.payload))
	var/obj/machinery/machine = host
	machine.receive_signal(signal)
	qdel(signal)
	SStgui.update_uis(host)
	SEND_SIGNAL(host, COMSIG_NETRUN_SERVICE_STATE_CHANGED)
	return TRUE

/datum/netrun_machine_service/atmos/alert
	service_id = "atmos.alert"

/datum/netrun_machine_service/atmos/alert/control_frequency()
	var/obj/machinery/computer/atmos_alert/console = host
	return console.receive_frequency

/datum/netrun_machine_service/atmos/alert/matches(datum/netrun_machine_service/source_service, recipient_tag)
	return ..() && istype(source_service, /datum/netrun_machine_service/atmos/alarm_source) && same_channel(source_service)

/datum/netrun_machine_service/atmos/alert/accepts(datum/netrun_machine_message/message)
	return ..() && istype(message, /datum/netrun_machine_message/atmos) && matches(message.source, null)

/datum/netrun_machine_service/atmos/alert/receive(datum/netrun_machine_message/message)
	var/datum/signal/signal = new(netrun_copy_wire_value(message.payload))
	var/obj/machinery/machine = host
	machine.receive_signal(signal)
	qdel(signal)
	SStgui.update_uis(host)
	SEND_SIGNAL(host, COMSIG_NETRUN_SERVICE_STATE_CHANGED)
	return TRUE

/datum/netrun_machine_service/atmos/alert/door
	service_id = "atmos.alarmdoor"

/datum/netrun_machine_service/atmos/alert/door/control_frequency()
	var/obj/machinery/door/airlock/alarmlock/door = host
	return door.air_frequency

/datum/netrun_machine_service/atmos/alert/door/matches(datum/netrun_machine_service/source_service, recipient_tag)
	return ..() && get_base_area(host) == get_base_area(source_service.host)

/obj/machinery/airalarm
	/// Each controller knows only the telemetry actually delivered to its port.
	var/list/netrun_vent_info = list()
	var/list/netrun_scrub_info = list()

/obj/machinery/airalarm/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/controller, /datum/netrun_machine_service/atmos/alarm_source)

/obj/machinery/atmospherics/components/unary/vent_pump/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/device/vent)

/obj/machinery/atmospherics/components/unary/vent_scrubber/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/device/scrubber)

/obj/machinery/atmospherics/components/unary/outlet_injector/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/device/injector)

/obj/machinery/atmospherics/components/binary/pump/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/device/pump)

/obj/machinery/atmospherics/components/binary/volume_pump/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/device/volume_pump)

/obj/machinery/air_sensor/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/sensor)

/obj/machinery/meter/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/sensor/meter)

/obj/machinery/embedded_controller/radio/simple_vent_controller/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/vent_controller)

/obj/machinery/door/airlock/alarmlock/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/alert/door)

/obj/machinery/computer/atmos_control/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/monitor)

/obj/machinery/computer/atmos_alert/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/atmos/alert)

/obj/machinery/atmospherics/components/unary/vent_pump/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("reboot"), 1, list(ACCESS_ATMOSPHERICS))

/obj/machinery/atmospherics/components/unary/vent_scrubber/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("reboot"), 1, list(ACCESS_ATMOSPHERICS))

/obj/machinery/atmospherics/components/unary/outlet_injector/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("reboot"), 2, list(ACCESS_ATMOSPHERICS))

/obj/machinery/air_sensor/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("reboot"), 1, list(ACCESS_ATMOSPHERICS))

/obj/machinery/computer/atmos_control/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("reboot"), 2, list(ACCESS_ATMOSPHERICS))

/obj/machinery/computer/atmos_alert/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("reboot"), 2, list(ACCESS_ATMOSPHERICS))

/obj/machinery/meter/Initialize(mapload, new_piping_layer)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("reboot"), 1, list(ACCESS_ATMOSPHERICS))

/obj/machinery/embedded_controller/radio/simple_vent_controller/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_ATMOS, list("reboot"), 2, list(ACCESS_ATMOSPHERICS))

/obj/machinery/embedded_controller/radio/simple_vent_controller/post_signal(datum/signal/signal)
	var/admitted = netrun_atmos_send("atmos.vent_controller", "atmos.device", signal.data, null, signal.data["tag"])
	qdel(signal)
	return admitted

/obj/machinery/computer/atmos_control/tank/proc/netrun_poll_device(device_tag)
	if(device_tag)
		return netrun_atmos_send("atmos.monitor", "atmos.device", list("sigtype" = "command", "tag" = device_tag, "status" = TRUE), null, device_tag)
	return FALSE
