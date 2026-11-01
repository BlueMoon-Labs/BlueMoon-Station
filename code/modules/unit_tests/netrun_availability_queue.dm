/// Display traffic must not turn every route lookup into a power sweep.
/datum/unit_test/netrun_availability_display_noise/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	SSnetrun.reconcile_dirty_availability()
	var/checks = SSnetrun.availability_checks
	var/expiry_visits = SSnetrun.availability_expiry_visits
	for(var/i in 1 to 20)
		scene.source.node.add_packet_log(i, "SEND", "machine", "source", "target", "fixture")
		scene.target.node.on_state_changed()
		SSnetrun.reconcile_dirty_availability()
	TEST_ASSERT(scene.source.node in SSnetrun.dirty_nodes, "Packet traffic must still queue the node's presentation update")
	TEST_ASSERT_EQUAL(SSnetrun.availability_checks, checks, "Packet logs and display-only state must cause no availability checks during routing")
	TEST_ASSERT_EQUAL(SSnetrun.availability_expiry_visits, expiry_visits, "Routing must not sweep future outage timers on every access")

/// Native power changes are reconciled before SSnetrun's next processing pass.
/datum/unit_test/netrun_availability_native_same_tick/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/component/netrun_node/apc_node = scene.apc.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	SSnetrun.reconcile_dirty_availability()
	TEST_ASSERT(apc_node.is_online(), "The fixture must begin with a working native APC")
	var/revision = graph.transit_availability_revision
	var/checks = SSnetrun.availability_checks
	scene.apc.set_machine_stat(BROKEN)
	TEST_ASSERT(apc_node in SSnetrun.availability_nodes, "A native availability signal must queue its actual node immediately")
	SSnetrun.reconcile_dirty_availability()
	TEST_ASSERT(!apc_node.last_online, "Routing must observe the broken APC before the subsystem fires")
	TEST_ASSERT(graph.transit_availability_revision > revision, "A forwarding failure must invalidate retained paths")
	TEST_ASSERT_EQUAL(SSnetrun.availability_checks, checks + 1, "Repeated native signals must coalesce into one availability check")
	revision = graph.transit_availability_revision
	scene.apc.set_machine_stat(0)
	SSnetrun.reconcile_dirty_availability()
	TEST_ASSERT(apc_node.last_online, "Restoration in the same tick must not be hidden behind a tick cache")
	TEST_ASSERT(graph.transit_availability_revision > revision, "Same-tick restoration must retire the failed-path generation")
	checks = SSnetrun.availability_checks
	SSnetrun.reconcile_dirty_availability()
	TEST_ASSERT_EQUAL(SSnetrun.availability_checks, checks, "A drained availability queue must perform no further native checks")

/// Reboots expire without another native signal or a presentation poll.
/datum/unit_test/netrun_availability_outage_expiry/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/component/netrun_node/apc_node = scene.apc.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	apc_node.offline_until = world.time + 2 * world.tick_lag
	apc_node.notify_changed()
	TEST_ASSERT(apc_node in SSnetrun.offline_nodes, "A temporary outage must have its own routing deadline")
	TEST_ASSERT(!apc_node.last_online, "The temporary outage must begin offline")
	var/revision = graph.transit_availability_revision
	sleep(2 * world.tick_lag)
	graph.reconcile_availability()
	TEST_ASSERT(apc_node.last_online, "The first route after expiry must observe recovery")
	TEST_ASSERT(graph.transit_availability_revision > revision, "Expiry must invalidate paths built during the outage")
	TEST_ASSERT(!(apc_node in SSnetrun.offline_nodes), "An expired outage must leave no timer-index entry")
	var/visits = SSnetrun.availability_expiry_visits
	for(var/i in 1 to 8)
		SSnetrun.reconcile_dirty_availability()
	TEST_ASSERT_EQUAL(SSnetrun.availability_expiry_visits, visits, "Expired timers must not be revisited by subsequent routes")

/// Queues must not retain destroyed physical machines while a map remains closed.
/datum/unit_test/netrun_availability_deleted_node/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/component/netrun_node/apc_node = scene.apc.GetComponent(/datum/component/netrun_node)
	apc_node.offline_until = world.time + 1 MINUTES
	apc_node.notify_changed()
	scene.apc.set_machine_stat(BROKEN)
	TEST_ASSERT(apc_node in SSnetrun.offline_nodes, "The fixture must own a retained outage deadline")
	TEST_ASSERT(apc_node in SSnetrun.availability_nodes, "The fixture must own a pending native availability change")
	qdel(scene.apc)
	TEST_ASSERT(!(apc_node in SSnetrun.offline_nodes), "Destroyed nodes must leave the outage index immediately")
	TEST_ASSERT(!(apc_node in SSnetrun.availability_nodes), "Destroyed nodes must leave the pending availability set immediately")
