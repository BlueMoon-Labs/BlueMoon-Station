/// A capability fixture has no ui_act: successful delivery must use provider polymorphism.
/obj/item/netrun_provider_test
	var/service_enabled = TRUE
	var/deliveries = 0
	var/list/last_arguments

/obj/item/netrun_provider_test/conditional

/// Service is withdrawn before node registration, so dynamic selection cannot supply signals.
/obj/machinery/atmospherics/components/binary/pump/netrun_inactive_test
	panel_open = TRUE

/datum/netrun_provider_state_observer
	var/notifications = 0

/datum/netrun_provider_state_observer/proc/on_changed(datum/source)
	SIGNAL_HANDLER
	notifications++

/datum/netrun_provider/unit_test
	atom_type = /obj/item/netrun_provider_test
	interface_name = "ProviderTest"
	actions = list(
		"write" = list("name" = "Write", "access" = NETRUN_ACCESS_USER, "params" = list(list("id" = "value", "type" = "number", "min" = -10, "max" = 0))),
		"root" = list("name" = "Root", "access" = NETRUN_ACCESS_ROOT),
	)

/datum/netrun_provider/unit_test/execute(atom/target, action, list/arguments, datum/netrun_console/console, datum/component/netrun_node/node)
	var/obj/item/netrun_provider_test/fixture = target
	fixture.deliveries++
	fixture.last_arguments = arguments.Copy()
	return TRUE

/datum/netrun_provider/unit_test/conditional
	atom_type = /obj/item/netrun_provider_test/conditional

/datum/netrun_provider/unit_test/conditional/available(atom/target)
	if(!..())
		return FALSE
	var/obj/item/netrun_provider_test/fixture = target
	return fixture.service_enabled

/// Type caches store candidates, so two same-type atoms and changed live state remain independent.
/datum/unit_test/netrun_provider_conditional_selection/Run()
	var/obj/item/netrun_provider_test/conditional/first = allocate(/obj/item/netrun_provider_test/conditional)
	var/obj/item/netrun_provider_test/conditional/second = allocate(/obj/item/netrun_provider_test/conditional)
	second.service_enabled = FALSE
	var/datum/netrun_provider/first_provider = SSnetrun.get_provider(first)
	var/datum/netrun_provider/fallback = SSnetrun.get_provider(second)
	TEST_ASSERT_EQUAL(first_provider.type, /datum/netrun_provider/unit_test/conditional, "An available subtype capability must beat its general fallback")
	TEST_ASSERT_EQUAL(fallback.type, /datum/netrun_provider/unit_test, "Another same-type atom must independently fail the live condition")
	first.service_enabled = FALSE
	TEST_ASSERT_EQUAL(SSnetrun.get_provider(first), fallback, "Changing a capability must not retain the cached former provider")
	second.service_enabled = TRUE
	TEST_ASSERT_EQUAL(SSnetrun.get_provider(second), first_provider, "Restoring a service must reuse the stateless provider without rebuilding the type cache")
	TEST_ASSERT_EQUAL(SSnetrun.get_api(second), first_provider, "The existing native-adapter entry point must remain compatible")

/// An explicit zero maximum is a real limit, and non-finite numbers never cross a provider boundary.
/datum/unit_test/netrun_provider_numeric_bounds/Run()
	var/datum/netrun_provider/unit_test/provider = allocate(/datum/netrun_provider/unit_test)
	var/list/clean = provider.clean_params("write", list("value" = 0, "force" = TRUE))
	TEST_ASSERT_NOTNULL(clean, "The inclusive zero endpoint must be valid")
	TEST_ASSERT_EQUAL(clean["value"], 0, "Numeric zero must survive sanitization")
	TEST_ASSERT_EQUAL(length(clean), 1, "Only declared parameters may cross the boundary")
	TEST_ASSERT_NULL(provider.clean_params("write", list("value" = 1)), "max=0 must not silently become the default upper bound")
	TEST_ASSERT_NULL(provider.clean_params("write", list("value" = -11)), "A negative explicit minimum must still be enforced")
	TEST_ASSERT_NOTNULL(provider.clean_params("write", list("value" = -10)), "A negative inclusive minimum must remain valid")
	TEST_ASSERT_NULL(provider.clean_params("write", list("value" = INFINITY)), "Infinite numeric input must be rejected")
	TEST_ASSERT_NULL(provider.clean_params("write", list("value" = list(-1))), "Nested lists must not be coerced into primitive arguments")
	provider.actions = list("missing_access" = list("name" = "Incomplete schema"))
	TEST_ASSERT_EQUAL(provider.action_access("missing_access"), NETRUN_ACCESS_USER, "An omitted access level must default to USER rather than exposing a GUEST control")

/// Queue a packet, change its provider's condition, then deliver without timer sleeps.
/datum/unit_test/netrun_provider_delivery_revalidation/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/item/netrun_provider_test/conditional/target = allocate(/obj/item/netrun_provider_test/conditional)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 1, list(ACCESS_RD))
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.operator = allocate(/mob)
	console.connection.wireless = FALSE
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	var/datum/netrun_provider/provider = SSnetrun.get_provider(target)
	TEST_ASSERT(console.do_remote_request(node, provider, "write", list("value" = -2, "force" = TRUE), node.network, console.operator), "A non-native provider must receive an authorized delivery")
	TEST_ASSERT_EQUAL(target.deliveries, 1, "The custom provider must execute exactly once")
	TEST_ASSERT_EQUAL(target.last_arguments["value"], -2, "The provider must receive its validated value")
	TEST_ASSERT_EQUAL(length(target.last_arguments), 1, "Internal callers must also strip unpublished parameters at delivery")
	TEST_ASSERT(!console.do_remote_request(node, provider, "write", list("value" = 1), node.network, console.operator), "Internal callers must not bypass a published numeric maximum")
	TEST_ASSERT_EQUAL(target.deliveries, 1, "A malformed internal request must never execute")
	var/datum/netrun_request/remote/request = new(console, node, provider, "write", list("value" = -3), node.network, console.operator)
	TEST_ASSERT(request.send(10 SECONDS), "The queued provider request must be accepted initially")
	target.service_enabled = FALSE
	TEST_ASSERT(!request.deliver(), "A packet must not retain an unavailable provider or fall through to a different service")
	TEST_ASSERT_EQUAL(target.deliveries, 1, "A withdrawn capability must not execute its queued request")
	TEST_ASSERT(QDELETED(request), "Cancelled provider delivery must release its packet and timer")

/// Native callbacks that recheck UI state retain the original action's access level.
/datum/unit_test/netrun_provider_ui_state_access/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/item/netrun_provider_test/conditional/target = allocate(/obj/item/netrun_provider_test/conditional)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 1, list(ACCESS_RD))
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.operator = allocate(/mob)
	console.connection.wireless = FALSE
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	var/datum/netrun_provider/provider = SSnetrun.get_provider(target)
	var/datum/ui_state/netrun_request/state = allocate(/datum/ui_state/netrun_request, console, node, provider, "root")
	TEST_ASSERT_EQUAL(state.can_use_topic(target, console.operator), UI_INTERACTIVE, "An unchanged ROOT callback must remain interactive")
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	TEST_ASSERT_EQUAL(state.can_use_topic(target, console.operator), UI_CLOSE, "Losing ROOT must close a pending ROOT callback even if USER remains")
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	target.service_enabled = FALSE
	TEST_ASSERT_EQUAL(state.can_use_topic(target, console.operator), UI_CLOSE, "Withdrawing the capability must also close a native callback")

/// Network pump controls use native setters, units, hard limits, and atmos wakeups.
/datum/unit_test/netrun_provider_atmos_pumps/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/machinery/atmospherics/components/binary/pump/pump = allocate(/obj/machinery/atmospherics/components/binary/pump)
	pump.set_machine_stat(0)
	var/datum/component/netrun_node/node = pump.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTNULL(node, "A real pressure pump must register an atmospheric endpoint")
	TEST_ASSERT_EQUAL(node.node_type, NETRUN_NODE_ATMOS, "Atmospheric endpoints need a distinct map type")
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.operator = allocate(/mob)
	console.connection.wireless = FALSE
	console.set_jack(node)
	var/datum/netrun_provider/provider = SSnetrun.get_provider(pump)
	TEST_ASSERT_NOTNULL(provider, "The pressure-pump provider must be available on an intact machine")
	TEST_ASSERT(!console.do_remote_request(node, provider, "pressure", list("pressure" = 300), node.network, console.operator), "GUEST must not control an atmospheric machine")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	TEST_ASSERT(user.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING, disable_warning = TRUE), "The native ID slot must have its required uniform")
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_ATMOSPHERICS)
	TEST_ASSERT(user.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE), "The native pump operator must wear the actual atmospheric ID")
	console.operator = user
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	pump.atmos_idle_until = world.time + 1 MINUTES
	TEST_ASSERT(console.do_remote_request(node, provider, "pressure", list("pressure" = 300), node.network, console.operator), "A matching USER grant must enable the published pressure control")
	TEST_ASSERT_EQUAL(pump.target_pressure, 300, "The native pressure parser must receive the correct wire representation")
	TEST_ASSERT_EQUAL(pump.atmos_idle_until, 0, "Native network controls must wake the sleeping atmospheric machine")
	TEST_ASSERT(console.do_remote_request(node, provider, "pressure", list("pressure" = 0), node.network, console.operator), "Zero is a valid pressure setpoint")
	TEST_ASSERT_EQUAL(pump.target_pressure, 0, "Zero must reach the actual native pressure regulator")
	TEST_ASSERT(!console.do_remote_request(node, provider, "pressure", list("pressure" = MAX_OUTPUT_PRESSURE + 1), node.network, console.operator), "Out-of-range requests must not reach the machine")
	TEST_ASSERT_EQUAL(pump.target_pressure, 0, "A rejected setpoint must preserve the machine state")
	var/obj/machinery/atmospherics/components/binary/volume_pump/volume = allocate(/obj/machinery/atmospherics/components/binary/volume_pump)
	volume.set_machine_stat(0)
	node = volume.GetComponent(/datum/component/netrun_node)
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	provider = SSnetrun.get_provider(volume)
	TEST_ASSERT(console.do_remote_request(node, provider, "rate", list("rate" = 25), node.network, console.operator), "The volume-pump service must publish a distinct flow-rate control")
	TEST_ASSERT_EQUAL(volume.transfer_rate, 25, "The actual volume pump must receive litres per second rather than a pressure setpoint")
	volume.panel_open = TRUE
	TEST_ASSERT_NULL(SSnetrun.get_provider(volume), "An open maintenance panel must withdraw the conditional pump service immediately")

/// Air-alarm modes remain native, with explicit ROOT bypass and hard physical isolation.
/datum/unit_test/netrun_provider_airalarm/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	alarm.set_machine_stat(0)
	var/datum/component/netrun_node/node = alarm.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTNULL(node, "The real air alarm must register a network node")
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.operator = allocate(/mob)
	console.connection.wireless = FALSE
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	var/datum/netrun_provider/provider = SSnetrun.get_provider(alarm)
	TEST_ASSERT_NOTNULL(provider, "An intact air alarm must publish its service")
	TEST_ASSERT(provider.action_unavailable_reason(alarm, "mode_8", console, node), "A native software lock must be explained before sending a request")
	TEST_ASSERT(!console.do_remote_request(node, provider, "mode_8", list(), node.network, console.operator), "The native panel lock must prevent unadvertised bypass")
	var/datum/netrun_command/unlock = SSnetrun.get_command("atmos_lock")
	TEST_ASSERT_NOTNULL(unlock, "The alarm must expose an explicit ROOT lock-bypass command")
	TEST_ASSERT(unlock.execute(node, console), "The explicit ROOT command must toggle the software lock")
	TEST_ASSERT(!alarm.locked, "The actual panel lock must be opened")
	alarm.process_interval = 15
	TEST_ASSERT(console.do_remote_request(node, provider, "mode_8", list("mode" = "3"), node.network, console.operator), "A catalog mode must dispatch through the native air-alarm API")
	TEST_ASSERT_EQUAL(alarm.mode, 8, "Unpublished arguments must not replace the action's fixed native mode")
	TEST_ASSERT_EQUAL(alarm.process_interval, 1, "The native mode action must restore prompt atmospheric sampling")
	TEST_ASSERT(provider.action_unavailable_reason(alarm, "mode_6", console, node), "The emag-only flood mode must remain unavailable in normal firmware")
	alarm.aidisabled = TRUE
	TEST_ASSERT_NULL(SSnetrun.get_provider(alarm), "Disabling the control wire must withdraw the native service despite a warm type cache")
	TEST_ASSERT(!console.do_remote_request(node, provider, "mode_1", list(), node.network, console.operator), "A withdrawn control service must reject queued/forged deliveries")
	TEST_ASSERT_EQUAL(alarm.mode, 8, "A disabled control wire must preserve the previous operating mode")
	alarm.aidisabled = FALSE
	TEST_ASSERT_EQUAL(SSnetrun.get_provider(alarm), provider, "Repairing control must restore the same stateless provider")
	alarm.buildstage = 1
	TEST_ASSERT(!node.is_online(), "Dismantled air alarms must stop answering the network")

/// Real native UI and gestures must invalidate quiet map status without polling every status string.
/datum/unit_test/netrun_provider_native_state_notifications/Run()
	var/obj/machinery/atmospherics/components/binary/pump/netrun_inactive_test/pump = allocate(/obj/machinery/atmospherics/components/binary/pump/netrun_inactive_test)
	pump.set_machine_stat(0)
	var/datum/component/netrun_node/node = pump.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NULL(SSnetrun.get_provider(pump), "The fixture service must be unavailable during initial signal subscription")
	TEST_ASSERT(COMSIG_UI_ACT in node.subscribed_state_signals, "Native UI notifications must come from static candidates even when the service is unavailable")
	TEST_ASSERT(COMSIG_NETRUN_SERVICE_STATE_CHANGED in node.subscribed_state_signals, "Legacy atmosphere icon updates must be part of the provider's state contract")
	pump.panel_open = FALSE
	pump.target_pressure = 200
	node.reconcile_state()
	var/datum/netrun_provider_state_observer/observer = allocate(/datum/netrun_provider_state_observer)
	observer.RegisterSignal(node, COMSIG_NETRUN_NODE_CHANGED, TYPE_PROC_REF(/datum/netrun_provider_state_observer, on_changed))
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/tgui/ui = allocate(/datum/tgui, user, pump, "AtmosPump")
	ui.status = UI_INTERACTIVE
	world.PushUsr(user, CALLBACK(pump, TYPE_PROC_REF(/datum, ui_act), "pressure", list("pressure" = "275"), ui, ui.state))
	TEST_ASSERT_EQUAL(pump.target_pressure, 275, "The native UI fixture must actually change the setpoint")
	TEST_ASSERT(node.pending_state_notification, "A native UI action must queue a refresh even when online/security/occupancy are unchanged")
	TEST_ASSERT_EQUAL(observer.notifications, 0, "A synchronous native signal must not serialize or publish node state inline")
	node.reconcile_state()
	TEST_ASSERT_EQUAL(observer.notifications, 1, "The queued reconcile must publish the changed device status exactly once")
	TEST_ASSERT(!node.pending_state_notification, "Reconciliation must consume the queued native invalidation")
	pump.AltClick(user)
	TEST_ASSERT_EQUAL(pump.target_pressure, MAX_OUTPUT_PRESSURE, "The real AltClick interaction must execute successfully")
	TEST_ASSERT(node.pending_state_notification, "The legacy atmosphere icon path must also queue gesture changes")
	TEST_ASSERT_EQUAL(observer.notifications, 1, "Gesture notification must also remain deferred")
	node.reconcile_state()
	TEST_ASSERT_EQUAL(observer.notifications, 2, "A second native change must refresh a quiet node card")
	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	alarm.set_machine_stat(0)
	var/datum/component/netrun_node/alarm_node = alarm.GetComponent(/datum/component/netrun_node)
	alarm.aidisabled = TRUE
	alarm_node.reconcile_state()
	TEST_ASSERT_NULL(SSnetrun.get_provider(alarm), "The disabled air-alarm service must be withdrawn")
	alarm.reset(WIRE_AI)
	TEST_ASSERT_NOTNULL(SSnetrun.get_provider(alarm), "The native restoration callback must restore service availability")
	TEST_ASSERT(alarm_node.pending_state_notification, "Wire restoration without an icon change must still wake the network projection")
