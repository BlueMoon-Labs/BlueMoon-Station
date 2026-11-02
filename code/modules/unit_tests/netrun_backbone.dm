/// Native gameplay checks over imported fixture data; physical algorithms are tested in netrun-core.
/datum/unit_test/netrun_node_evacuation_keeps_all_residents/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/list/residents = list()
	for(var/i in 1 to 3)
		var/mob/camera/netrun_entity/entity = new(origin, source_node)
		scene.owned.Insert(1, entity)
		residents += entity
	TEST_ASSERT_EQUAL(length(source_node.entities), 3, "All fixture residents must share the doomed endpoint")
	qdel(source)
	for(var/mob/camera/netrun_entity/entity as anything in residents)
		TEST_ASSERT(!QDELETED(entity) && entity.host_node && entity.host_node != source_node, "Deleting a host must evacuate every resident, without skipping entries removed during iteration")

/// A sparse sector with fewer peers than K must not walk thousands of empty buckets.
/datum/unit_test/netrun_node_online_after_teardown/Run()
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock)
	var/datum/component/netrun_node/node = door.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTNULL(node, "A real airlock must expose a network endpoint")
	qdel(door)
	TEST_ASSERT(QDELETED(node), "Deleting a machine must delete its endpoint")
	TEST_ASSERT(!node.is_online(), "A deleted endpoint must be offline without reading torn-down native wires")

/// Finish candidate selection separately so binding regressions exercise the new bounded phase.
