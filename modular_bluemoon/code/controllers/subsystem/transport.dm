PROCESSING_SUBSYSTEM_DEF(transport)
	name = "Transport"
	wait = 0.05 SECONDS
	/// only used on maps with trams, so only enabled by such.
	can_fire = FALSE

	///associative list of the form: list(lift_id = list(all transport_controller datums attached to lifts of that type))
	var/list/transports_by_type = list()
	var/list/nav_beacons = list()
	var/list/crossing_signals = list()
	var/list/sensors = list()
	var/list/doors = list()
	var/list/displays = list()
	///how much time a tram can take per movement before we notify admins and slow down the tram. in milliseconds
	var/max_time = 15
	///how many times the tram can move costing over max_time milliseconds before it gets slowed down
	var/max_exceeding_moves = 5
	///how many times the tram can move costing less than half max_time milliseconds before we speed it back up again.
	///is only used if the tram has been slowed down for exceeding max_time
	var/max_cheap_moves = 5

/// Registers the subsystem to listen for incoming requests from paired devices
/datum/controller/subsystem/processing/transport/proc/hello(atom/new_unit, unit_name, id_tag)
	RegisterSignal(new_unit, COMSIG_TRANSPORT_REQUEST, PROC_REF(incoming_request))
	log_transport("Sub: Registered new transport component [unit_name] [id_tag].")

/datum/controller/subsystem/processing/transport/Recover()
	comp_lookup = SStransport.comp_lookup
	transports_by_type = SStransport.transports_by_type
	nav_beacons = SStransport.nav_beacons
	crossing_signals = SStransport.crossing_signals
	sensors = SStransport.sensors
	doors = SStransport.doors
	displays = SStransport.displays

/// Performs the request received from a registered transport device
/datum/controller/subsystem/processing/transport/proc/incoming_request(obj/source, transport_id, platform, options)
	SIGNAL_HANDLER

	log_transport("Sub: Received request from [source] ([REF(source)]). Contents: [transport_id] [platform] [options]")
	var/relevant
	var/request_flags = options
	var/datum/transport_controller/linear/tram/transport_controller
	var/obj/effect/landmark/transport/nav_beacon/tram/platform/destination
	for(var/datum/transport_controller/linear/tram/candidate_controller as anything in transports_by_type[TRANSPORT_TYPE_TRAM])
		if(candidate_controller.specific_transport_id == transport_id)
			transport_controller = candidate_controller
			break

	LAZYADD(relevant, source)

	if(isnull(transport_controller))
		log_transport("Sub: Transport [transport_id] has no controller datum! Someone deleted it or something catastrophic happened.")
		SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_RESPONSE, relevant, REQUEST_FAIL, BROKEN_BEYOND_REPAIR)
		log_transport("Sub: Sending response to [REF(source)]. Contents: [REQUEST_FAIL] [BROKEN_BEYOND_REPAIR].")
		return

	if(!transport_controller.controller_operational || !transport_controller.paired_cabinet)
		SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_RESPONSE, relevant, REQUEST_FAIL, NOT_IN_SERVICE)
		log_transport("Sub: Sending response to [REF(source)]. Contents: [REQUEST_FAIL] [NOT_IN_SERVICE]. Info: TC-[!transport_controller.controller_operational][!transport_controller.paired_cabinet].")
		return

	if(transport_controller.controller_status & SYSTEM_FAULT || transport_controller.controller_status & EMERGENCY_STOP)
		SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_RESPONSE, relevant, REQUEST_FAIL, INTERNAL_ERROR)
		log_transport("Sub: Sending response to [REF(source)]. Contents: [REQUEST_FAIL] [INTERNAL_ERROR]. Info: [SUB_TS_STATUS].")
		return

	if(transport_controller.controller_active)
		SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_RESPONSE, relevant, REQUEST_FAIL, TRANSPORT_IN_USE)
		log_transport("Sub: Sending response to [REF(source)]. Contents: [REQUEST_FAIL] [TRANSPORT_IN_USE]. Info: [TC_TA_INFO].")
		return

	// Players can set the platform ID themselves, so only accept platforms we know about
	var/network = LAZYACCESS(nav_beacons, transport_id)
	for(var/obj/effect/landmark/transport/nav_beacon/tram/platform/potential_destination in network)
		if(potential_destination.platform_code == platform)
			destination = potential_destination
			break

	if(!destination)
		SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_RESPONSE, relevant, REQUEST_FAIL, INVALID_PLATFORM)
		log_transport("Sub: Sending response to [REF(source)]. Contents: [REQUEST_FAIL] [INVALID_PLATFORM]. Info: RD0.")
		return

	if(transport_controller.idle_platform == destination)
		SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_RESPONSE, relevant, REQUEST_FAIL, NO_CALL_REQUIRED)
		log_transport("Sub: Sending response to [REF(source)]. Contents: [REQUEST_FAIL] [NO_CALL_REQUIRED]. Info: RD1.")
		return

	if(!transport_controller.calculate_route(destination))
		SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_RESPONSE, relevant, REQUEST_FAIL, INTERNAL_ERROR)
		log_transport("Sub: Sending response to [REF(source)]. Contents: [REQUEST_FAIL] [INTERNAL_ERROR]. Info: NV0.")
		return

	SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_RESPONSE, relevant, REQUEST_SUCCESS, destination.name)
	log_transport("Sub: Sending response to [REF(source)]. Contents: [REQUEST_SUCCESS] [destination.name].")

	INVOKE_ASYNC(src, PROC_REF(dispatch_transport), transport_controller, request_flags)

/// Dispatches the transport on a validated trip
/datum/controller/subsystem/processing/transport/proc/dispatch_transport(datum/transport_controller/linear/tram/transport_controller, request_flags)
	log_transport("Sub: Sending dispatch request to [transport_controller.specific_transport_id]. [request_flags ? "Contents: [request_flags]." : "No request flags."]")

	if(transport_controller.idle_platform == transport_controller.destination_platform)
		log_transport("Sub: [transport_controller.specific_transport_id] dispatch failed. Info: DE-1 Transport Controller idle and destination are the same.")
		return

	transport_controller.set_active(TRUE)
	pre_departure(transport_controller, request_flags)

/// Pre-departure checks for the tram
/datum/controller/subsystem/processing/transport/proc/pre_departure(datum/transport_controller/linear/tram/transport_controller, request_flags)
	log_transport("Sub: [transport_controller.specific_transport_id] start pre-departure. Info: [SUB_TS_STATUS]")

	transport_controller.set_status_code(PRE_DEPARTURE, TRUE)
	transport_controller.set_status_code(CONTROLS_LOCKED, TRUE)

	log_transport("Sub: [transport_controller.specific_transport_id] requested door close. Info: [SUB_TS_STATUS].")
	if(request_flags & RAPID_MODE || request_flags & BYPASS_SENSORS || transport_controller.controller_status & BYPASS_SENSORS)
		transport_controller.cycle_doors(CYCLE_CLOSED, BYPASS_DOOR_CHECKS)
		if(request_flags & RAPID_MODE)
			log_transport("Sub: [transport_controller.specific_transport_id] rapid mode enabled, bypassing validation.")
			transport_controller.dispatch_transport()
			return
	else
		playsound(transport_controller.nav_beacon, 'modular_bluemoon/sound/machines/tram/door_chime.ogg', 45, vary = FALSE, extrarange = MEDIUM_RANGE_SOUND_EXTRARANGE)
		stoplag(1.4 SECONDS)
		if(QDELETED(transport_controller))
			return
		transport_controller.set_status_code(DOORS_READY, FALSE)
		transport_controller.cycle_doors(CYCLE_CLOSED)

	addtimer(CALLBACK(src, PROC_REF(validate_and_dispatch), transport_controller), 3 SECONDS)

/// Operational checks, then start moving
/datum/controller/subsystem/processing/transport/proc/validate_and_dispatch(datum/transport_controller/linear/tram/transport_controller, attempt = 0)
	if(QDELETED(transport_controller))
		return
	log_transport("Sub: [transport_controller.specific_transport_id] start pre-departure validation. Attempts: [attempt].")

	if(attempt >= 4)
		log_transport("Sub: [transport_controller.specific_transport_id] pre-departure validation failed, but dispatching tram anyways. Info: [SUB_TS_STATUS].")
		transport_controller.dispatch_transport()
		return

	transport_controller.update_status()
	if(!(transport_controller.controller_status & DOORS_READY))
		addtimer(CALLBACK(src, PROC_REF(validate_and_dispatch), transport_controller, attempt + 1), 3 SECONDS)
		return

	transport_controller.dispatch_transport()
	log_transport("Sub: [transport_controller.specific_transport_id] pre-departure passed.")

/// Give a list of destinations to the tram controls
/datum/controller/subsystem/processing/transport/proc/detailed_destination_list(specific_transport_id)
	. = list()
	for(var/obj/effect/landmark/transport/nav_beacon/tram/platform/destination as anything in nav_beacons[specific_transport_id])
		var/list/this_destination = list()
		this_destination["name"] = destination.name
		this_destination["dest_icons"] = destination.tgui_icons
		this_destination["id"] = destination.platform_code
		. += list(this_destination)

/// Logging for transport (tram/elevator) actions
/proc/log_transport(text)
	WRITE_LOG("[GLOB.log_directory]/transport.log", "TRANSPORT: [text]")
