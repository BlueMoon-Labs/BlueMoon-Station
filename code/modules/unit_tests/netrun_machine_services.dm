/// Native numeric conversion, upgrade clamps and delivery-time ROOT all remain effective.
/datum/unit_test/netrun_service_smes/Run()
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/turf/spot = get_step(run_loc_floor_bottom_left, EAST)
	var/obj/machinery/power/terminal/terminal = scene.machine(/obj/machinery/power/terminal, get_step(spot, NORTH))
	terminal.setDir(SOUTH)
	var/obj/machinery/power/smes/storage = scene.machine(/obj/machinery/power/smes, spot)
	TEST_ASSERT_EQUAL(storage.terminal, terminal, "The real SMES discovers its physical energy terminal")
	var/datum/component/netrun_node/node = storage.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTNULL(node, "The real SMES publishes a network endpoint")
	var/datum/netrun_console/console = allocate(/datum/netrun_console, allocate(/obj/item))
	console.operator = allocate(/mob/living/carbon/human)
	console.connection.wireless = FALSE
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	var/datum/netrun_provider/provider = SSnetrun.get_provider(storage)
	TEST_ASSERT(istype(provider, /datum/netrun_api/smes), "The registry selects the native SMES adapter")
	TEST_ASSERT(console.do_remote_request(node, provider, "input", list("target" = 25000), node.network, console.operator), "USER can tune native charging")
	TEST_ASSERT_EQUAL(storage.input_level, 25000, "Numeric schema values reach the native text2num panel correctly")
	storage.input_level_max = 30000
	TEST_ASSERT(console.do_remote_request(node, provider, "input", list("target" = 50000), node.network, console.operator), "The native setter accepts a finite request")
	TEST_ASSERT_EQUAL(storage.input_level, 30000, "Actual machine parts impose the final charging limit")
	var/output_before = storage.output_attempt
	TEST_ASSERT(!console.do_remote_request(node, provider, "tryoutput", list(), node.network, console.operator), "USER cannot cut power to the downstream grid")
	TEST_ASSERT_EQUAL(storage.output_attempt, output_before, "Denied output control does not mutate power")
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	var/datum/netrun_request/remote/pending = new(console, node, provider, "tryoutput", list(), node.network, console.operator)
	TEST_ASSERT(pending.send(10 SECONDS), "A ROOT output change can enter flight")
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	TEST_ASSERT(!pending.deliver(), "Revoking ROOT rejects the output change at delivery")
	TEST_ASSERT_EQUAL(storage.output_attempt, output_before, "The queued action retains no stale output authority")
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	storage.panel_open = TRUE
	TEST_ASSERT_NULL(SSnetrun.get_provider(storage), "Maintenance withdraws the control service despite its cached type match")
	TEST_ASSERT(!console.do_remote_request(node, provider, "input", list("target" = 1), node.network, console.operator), "An open maintenance panel rejects old provider requests")
	storage.panel_open = FALSE
	var/datum/netrun_command/diagnostic = SSnetrun.get_command("smes_status")
	TEST_ASSERT(diagnostic.read_only && diagnostic.access == NETRUN_ACCESS_GUEST, "Engineering diagnostics are read-only guest commands")
	TEST_ASSERT(findtext(diagnostic.execute(node, console), "Пределы"), "The command reports native power limits")

/// Fire control has a useful local service while all physical interlocks stay authoritative.
/datum/unit_test/netrun_service_firealarm/Run()
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/firealarm/alarm = scene.machine(/obj/machinery/firealarm, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/component/netrun_node/node = alarm.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, allocate(/obj/item))
	console.operator = allocate(/mob/living/carbon/human)
	console.connection.wireless = FALSE
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	var/datum/netrun_provider/provider = SSnetrun.get_provider(alarm)
	TEST_ASSERT(istype(provider, /datum/netrun_provider/firealarm), "The real fire alarm has its own stateless service")
	TEST_ASSERT(console.do_remote_request(node, provider, "alarm", list(), node.network, console.operator), "USER can raise a native emergency alarm")
	TEST_ASSERT(alarm.myarea.fire && alarm.alarm_active, "The actual area's fire state changes")
	TEST_ASSERT(!console.do_remote_request(node, provider, "reset", list(), node.network, console.operator), "Suppressing an emergency requires ROOT")
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	var/datum/netrun_request/remote/pending = new(console, node, provider, "reset", list(), node.network, console.operator)
	TEST_ASSERT(pending.send(10 SECONDS), "The reset is admitted before a hardware change")
	alarm.button_wire_cut = TRUE
	TEST_ASSERT(!pending.deliver(), "A cut button wire revokes a reset already in flight")
	TEST_ASSERT(alarm.myarea.fire, "ROOT does not bypass the disabled physical control")
	alarm.button_wire_cut = FALSE
	TEST_ASSERT(console.do_remote_request(node, provider, "reset", list(), node.network, console.operator), "Repaired control permits the native reset")
	TEST_ASSERT(!alarm.myarea.fire && !alarm.alarm_active, "The native reset clears the real emergency")
	var/datum/netrun_command/diagnostic = SSnetrun.get_command("fire_status")
	TEST_ASSERT(diagnostic.read_only && diagnostic.access == NETRUN_ACCESS_GUEST, "Fire diagnostics need no mutation authority")
	TEST_ASSERT(findtext(diagnostic.execute(node, console), "Детектор"), "Diagnostics include the native detector state")

/// Kitchen service keeps food handling useful without granting USER a remote metal explosion.
/datum/unit_test/netrun_service_microwave/Run()
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/microwave/oven = scene.machine(/obj/machinery/microwave, get_step(run_loc_floor_bottom_left, EAST))
	oven.anchored = TRUE
	oven.efficiency = 1
	var/datum/component/netrun_node/node = oven.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, allocate(/obj/item))
	console.operator = allocate(/mob/living/carbon/human)
	console.connection.wireless = FALSE
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	var/datum/netrun_provider/provider = SSnetrun.get_provider(oven)
	TEST_ASSERT(istype(provider, /datum/netrun_provider/microwave), "The radial-menu machine gets an explicit native provider")
	var/obj/item/utensil = allocate(/obj/item, oven)
	oven.ingredients += utensil
	TEST_ASSERT(provider.action_unavailable_reason(oven, "cook_food", console, node), "A non-food load cannot use the safe food action")
	TEST_ASSERT(!console.do_remote_request(node, provider, "cook_any", list(), node.network, console.operator), "USER cannot request dangerous arbitrary contents")
	TEST_ASSERT(!oven.operating, "Denied cooking does not start the native cycle")
	TEST_ASSERT(console.do_remote_request(node, provider, "eject", list(), node.network, console.operator), "USER can recover a loaded item with the native eject mechanism")
	TEST_ASSERT_EQUAL(utensil.loc, oven.drop_location(), "Ejection moves the actual item to the appliance's physical location")
	TEST_ASSERT(!length(oven.ingredients), "Native Exited clears the loaded inventory")
	var/obj/item/reagent_containers/food/snacks/breadslice/plain/food = allocate(/obj/item/reagent_containers/food/snacks/breadslice/plain, oven)
	oven.ingredients += food
	var/datum/netrun_request/remote/pending = new(console, node, provider, "cook_food", list(), node.network, console.operator)
	TEST_ASSERT(pending.send(10 SECONDS), "A safe food cycle can enter flight")
	oven.wire_disabled = TRUE
	TEST_ASSERT(!pending.deliver(), "Disabling the real control wire rejects the pending cycle")
	TEST_ASSERT(!oven.operating && (food in oven.ingredients), "Rejected cooking preserves the real food")
	oven.wire_disabled = FALSE
	TEST_ASSERT(console.do_remote_request(node, provider, "cook_food", list(), node.network, console.operator), "Repairing the wire permits ordinary native cooking")
	TEST_ASSERT(oven.operating, "The native timer owns the cooking cycle")
	var/datum/netrun_command/diagnostic = SSnetrun.get_command("microwave_status")
	TEST_ASSERT(diagnostic.read_only && diagnostic.access == NETRUN_ACCESS_GUEST, "Appliance diagnostics are read-only")
	TEST_ASSERT(findtext(diagnostic.execute(node, console), "Цикл"), "The useful command reports the actual running cycle")
