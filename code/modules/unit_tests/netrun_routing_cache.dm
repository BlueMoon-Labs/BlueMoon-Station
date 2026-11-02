/// Firewall grant invalidation remains native gameplay authority.
/datum/unit_test/netrun_routing_cache_firewall_interest/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/netrun_terminal/granted = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	var/obj/machinery/computer/netrun_terminal/unrelated = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	granted.console.access_session.node_access[scene.target.node.address] = NETRUN_ACCESS_ROOT
	unrelated.console.ui_dirty = FALSE
	SSnetrun.active_consoles -= unrelated.console
	scene.target.node.raise_firewall()
	TEST_ASSERT_EQUAL(length(granted.console.access_session.pending_firewalls), 1, "The session with a compromised grant must receive its revocation")
	TEST_ASSERT_EQUAL(length(unrelated.console.access_session.pending_firewalls), 0, "Unrelated sessions must not allocate pending firewall work")
	TEST_ASSERT(!unrelated.console.ui_dirty && !SSnetrun.active_consoles[unrelated.console], "An unopened unrelated terminal must remain asleep after another node raises its firewall")
	granted.console.access_session.process_events()
	TEST_ASSERT_NULL(granted.console.access_session.node_access[scene.target.node.address], "Filtering unrelated listeners must not preserve the actual compromised grant")
