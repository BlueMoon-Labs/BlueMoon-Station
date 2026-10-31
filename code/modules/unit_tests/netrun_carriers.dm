/// Observe the synchronous movement contract without running the node worker.
/datum/netrun_carrier_probe
	var/list/watched = list()
	var/list/counts = list()
	var/list/positions = list()

/datum/netrun_carrier_probe/New(list/nodes)
	for(var/datum/component/netrun_node/node as anything in nodes)
		watched[node.address] = TRUE
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_MOVED, PROC_REF(on_moved))

/datum/netrun_carrier_probe/proc/on_moved(datum/source, datum/component/netrun_node/node, turf/old_turf, turf/new_turf)
	SIGNAL_HANDLER
	if(!watched[node.address])
		return
	counts[node.address] = (counts[node.address] || 0) + 1
	positions[node.address] = new_turf

/datum/netrun_carrier_probe/proc/reset()
	counts.Cut()
	positions.Cut()

/datum/netrun_carrier_probe/Destroy()
	UnregisterSignal(SSnetrun, COMSIG_NETRUN_NODE_MOVED)
	watched.Cut()
	counts.Cut()
	positions.Cut()
	return ..()

/// One settled APC and a stationary observer keep carrier movement independent of discovery.
/datum/netrun_carrier_scene
	parent_type = /datum/netrun_route_scene
	var/mob/living/carbon/human/first
	var/mob/living/carbon/human/second
	var/obj/machinery/power/apc/apc
	var/obj/machinery/computer/netrun_terminal/observer
	var/datum/netrun_map_view/netrun_performance_test/view
	var/list/spots = list()

/datum/netrun_carrier_scene/New(turf/origin)
	..(origin.z)
	var/area/room = room(/area/netrun_route_test)
	for(var/turf/spot as anything in block(origin, locate(origin.x + 6, origin.y + 2, origin.z)))
		take(spot, room)
	for(var/i in 0 to 6)
		spots += locate(origin.x + i, origin.y, origin.z)
	apc = machine(/obj/machinery/power/apc, get_step(origin, NORTH))
	observer = machine(/obj/machinery/computer/netrun_terminal, origin)
	first = new(spots[2])
	second = new(spots[5])
	owned += first
	owned += second
	qdel(observer.console.map_view)
	view = new(observer.console)
	observer.console.map_view = view
	observer.console.workspace_view = "map"

/datum/netrun_carrier_scene/proc/warm(list/nodes)
	SSnetrun.ensure_topology()
	var/list/settle = nodes.Copy()
	settle |= apc.GetComponent(/datum/component/netrun_node)
	settle |= observer.GetComponent(/datum/component/netrun_node)
	for(var/datum/component/netrun_node/node as anything in settle)
		node.join_network()
		node.reconcile_state()
		node.publish_changes()
	SSnetrun.get_topology().borrow_infrastructure_tree(apc.GetComponent(/datum/component/netrun_node))
	observer.console.ui_data(null)
	observer.console.ui_data(null)

/// Native PDA/HUD slots and a nullspace neural implant follow one walking wearer immediately.
/datum/unit_test/netrun_carriers_worn_native_nodes/Run()
	var/datum/netrun_carrier_scene/scene = allocate(/datum/netrun_carrier_scene, run_loc_floor_bottom_left)
	var/obj/item/clothing/under/color/grey/uniform = new(scene.spots[2])
	var/obj/item/modular_computer/pda/pda = new(scene.spots[2])
	pda.enabled = TRUE
	var/obj/item/clothing/glasses/hud/health/glasses = new(scene.spots[2])
	var/obj/item/organ/cyberimp/brain/netlink/implant = new(scene.spots[2])
	scene.owned += uniform
	scene.owned += pda
	scene.owned += glasses
	scene.owned += implant
	TEST_ASSERT(scene.first.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING, disable_warning = TRUE), "The wearer must equip a real uniform for the PDA slot")
	TEST_ASSERT(scene.first.equip_to_slot_if_possible(pda, ITEM_SLOT_ID, disable_warning = TRUE), "The real PDA must be worn in its native ID slot")
	TEST_ASSERT(scene.first.equip_to_slot_if_possible(glasses, ITEM_SLOT_EYES, disable_warning = TRUE), "The real HUD glasses must be worn in their native eye slot")
	implant.Insert(scene.first, TRUE)
	TEST_ASSERT_NULL(implant.loc, "The installed neural implant must remain in native nullspace")
	var/datum/component/netrun_neural_adapter/adapter = implant.interface.GetComponent(/datum/component/netrun_neural_adapter)
	TEST_ASSERT_NOTNULL(adapter?.endpoint, "The native neural display must provide its distinct contained endpoint")
	var/list/nodes = list(pda.GetComponent(/datum/component/netrun_node), glasses.GetComponent(/datum/component/netrun_node), implant.GetComponent(/datum/component/netrun_node), adapter.endpoint.GetComponent(/datum/component/netrun_node))
	for(var/datum/component/netrun_node/node as anything in nodes)
		TEST_ASSERT_NOTNULL(node, "Every native carried device must provide its actual network component")
		TEST_ASSERT(node.is_online(), "Fresh location announcements require an operational native endpoint")
		TEST_ASSERT_EQUAL(node.physical_carrier, scene.first, "Worn and installed endpoints must subscribe to their common wearer")
	scene.warm(nodes)
	var/datum/netrun_carrier_probe/probe = allocate(/datum/netrun_carrier_probe, nodes)
	var/datum/netrun_topology/graph = SSnetrun.get_topology()
	var/revision = graph.revision
	var/infrastructure = graph.infrastructure_tree_builds
	var/rebuilds = scene.view.rebuilds
	var/turf/destination = scene.spots[3]
	scene.first.forceMove(destination)
	for(var/datum/component/netrun_node/node as anything in nodes)
		TEST_ASSERT(probe.counts[node.address] > 0, "Walking must synchronously publish movement for each worn PDA, HUD, implant and neural display")
		TEST_ASSERT_EQUAL(probe.positions[node.address], destination, "Movement publication must carry the wearer's new turf")
		TEST_ASSERT(node.pending_physical_update && graph.moved_nodes[node], "Movement must enqueue each contained endpoint before any polling or worker tick")
		TEST_ASSERT_EQUAL(node.topology_turf, scene.spots[2], "The synchronous notification must defer route and cable recomputation")
	scene.observer.console.ui_data(null)
	for(var/datum/component/netrun_node/node as anything in nodes)
		var/list/entry = scene.view.node_entries[node.address]
		TEST_ASSERT_EQUAL(entry?["x"], destination.x, "The first fresh UI poll must show each carried endpoint's new X")
		TEST_ASSERT_EQUAL(entry?["y"], destination.y, "The first fresh UI poll must show each carried endpoint's new Y")
		TEST_ASSERT_EQUAL(entry?["z"], destination.z, "The first fresh UI poll must show each carried endpoint's actual floor")
	TEST_ASSERT_EQUAL(scene.view.rebuilds, rebuilds, "A warm same-area walk must update carried markers without a full map rebuild")
	TEST_ASSERT_EQUAL(graph.revision, revision, "Walking with native devices must preserve the physical topology revision")
	TEST_ASSERT_EQUAL(graph.infrastructure_tree_builds, infrastructure, "Walking must not solve the shared APC infrastructure again")

/// Storage insertions and intermediate container transfers update every descendant subscription.
/datum/unit_test/netrun_carriers_nested_storage/Run()
	var/datum/netrun_carrier_scene/scene = allocate(/datum/netrun_carrier_scene, run_loc_floor_bottom_left)
	var/obj/item/storage/backpack/pack = new(scene.spots[2])
	var/obj/item/storage/box/box = new(scene.spots[2])
	var/obj/item/netrun_deck/deck = new(scene.spots[2])
	var/obj/item/toy/crayon/red/small = new(scene.spots[2])
	scene.owned += pack
	scene.owned += box
	scene.owned += deck
	scene.owned += small
	var/datum/component/netrun_node/box_node = box.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/component/netrun_node/small_node = small.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/component/netrun_node/deck_node = deck.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(scene.first.equip_to_slot_if_possible(pack, ITEM_SLOT_BACK, disable_warning = TRUE), "The outer native backpack must be equipped")
	TEST_ASSERT(SEND_SIGNAL(box, COMSIG_TRY_STORAGE_INSERT, deck, scene.first, TRUE, TRUE), "The real storage component must accept the deck")
	TEST_ASSERT(SEND_SIGNAL(box, COMSIG_TRY_STORAGE_INSERT, small, scene.first, TRUE, TRUE), "The real storage component must accept the second endpoint")
	TEST_ASSERT(SEND_SIGNAL(pack, COMSIG_TRY_STORAGE_INSERT, box, scene.first, TRUE, TRUE), "The real backpack must accept the nested box")
	var/list/nodes = list(box_node, small_node, deck_node)
	scene.warm(nodes)
	var/datum/netrun_carrier_probe/probe = allocate(/datum/netrun_carrier_probe, nodes)
	for(var/datum/component/netrun_node/node as anything in nodes)
		TEST_ASSERT_EQUAL(node.physical_carrier, scene.first, "A multi-level storage descendant must retain its actual outer wearer")
	scene.first.forceMove(scene.spots[3])
	for(var/datum/component/netrun_node/node as anything in nodes)
		TEST_ASSERT(probe.counts[node.address] > 0, "Moving the outer wearer must immediately notify every nested node")
		TEST_ASSERT_EQUAL(probe.positions[node.address], scene.spots[3], "Nested movement must publish the outer wearer's actual position")
	// Only the intermediate box moves here; the two innermost endpoints do not.
	box.forceMove(scene.second)
	for(var/datum/component/netrun_node/node as anything in nodes)
		TEST_ASSERT_EQUAL(node.physical_carrier, scene.second, "Moving a container must immediately replace every descendant's old owner")
	probe.reset()
	scene.first.forceMove(scene.spots[2])
	for(var/datum/component/netrun_node/node as anything in nodes)
		TEST_ASSERT(!probe.counts[node.address], "A previous wearer must not generate ghost motion for a transferred subtree")
	scene.second.forceMove(scene.spots[6])
	for(var/datum/component/netrun_node/node as anything in nodes)
		TEST_ASSERT(probe.counts[node.address] > 0, "The new wearer must immediately move every transferred descendant")
	box.forceMove(scene.spots[4])
	TEST_ASSERT_NULL(box_node.physical_carrier, "The dropped box's own node must no longer retain a wearer")
	TEST_ASSERT_EQUAL(deck_node.physical_carrier, box, "A nested endpoint on the floor must follow its outer movable container")
	probe.reset()
	scene.second.forceMove(scene.spots[5])
	TEST_ASSERT_EQUAL(length(probe.counts), 0, "A dropped subtree must unsubscribe its previous outer owner")
	box.forceMove(scene.spots[3])
	for(var/datum/component/netrun_node/node as anything in nodes)
		TEST_ASSERT(probe.counts[node.address] > 0, "Moving the dropped container must notify its own node and every descendant")

/// Direct pickup/drop and component deletion must release previous movement subscriptions.
/datum/unit_test/netrun_carriers_transfer_cleanup/Run()
	var/datum/netrun_carrier_scene/scene = allocate(/datum/netrun_carrier_scene, run_loc_floor_bottom_left)
	var/obj/item/endpoint = new(scene.spots[2])
	scene.owned += endpoint
	var/datum/component/netrun_node/node = endpoint.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_carrier_probe/probe = allocate(/datum/netrun_carrier_probe, list(node))
	TEST_ASSERT_NULL(node.physical_carrier, "A direct floor endpoint must have no separate carrier")
	endpoint.forceMove(scene.first)
	TEST_ASSERT_EQUAL(node.physical_carrier, scene.first, "A direct pickup must subscribe without waiting for the node worker")
	endpoint.forceMove(scene.second)
	TEST_ASSERT_EQUAL(node.physical_carrier, scene.second, "A direct owner transfer must synchronously replace the carrier")
	probe.reset()
	scene.first.forceMove(scene.spots[3])
	TEST_ASSERT(!probe.counts[node.address], "The old direct owner must not emit ghost movement")
	scene.second.forceMove(scene.spots[6])
	TEST_ASSERT(probe.counts[node.address] > 0, "The new direct owner must emit endpoint movement")
	endpoint.forceMove(scene.spots[4])
	TEST_ASSERT_NULL(node.physical_carrier, "Dropping a direct endpoint must clear its separate carrier")
	probe.reset()
	scene.second.forceMove(scene.spots[5])
	TEST_ASSERT(!probe.counts[node.address], "The dropped endpoint must not retain its former owner subscription")
	endpoint.forceMove(scene.spots[3])
	TEST_ASSERT(probe.counts[node.address] > 0, "The endpoint's own move subscription must survive pickup and drop")
	endpoint.forceMove(scene.first)
	var/address = node.address
	qdel(node)
	TEST_ASSERT_NULL(node.physical_carrier, "Deleting a contained node must release its owner reference")
	TEST_ASSERT_NULL(SSnetrun.get_task_scheduler().by_key["node:[REF(node)]"], "Deleting a moved endpoint must release its worker task")
	probe.reset()
	scene.first.forceMove(scene.spots[2])
	endpoint.forceMove(scene.spots[4])
	TEST_ASSERT(!probe.counts[address], "Neither owner nor parent movement may notify a deleted component")

/// Native nullspace ownership remains authoritative across removal and reinsertion.
/datum/unit_test/netrun_carriers_implant_reinsert/Run()
	var/datum/netrun_carrier_scene/scene = allocate(/datum/netrun_carrier_scene, run_loc_floor_bottom_left)
	var/obj/item/organ/cyberimp/brain/netlink/implant = new(scene.spots[2])
	scene.owned += implant
	implant.Insert(scene.first, TRUE)
	var/datum/component/netrun_node/node = implant.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_carrier_probe/probe = allocate(/datum/netrun_carrier_probe, list(node))
	TEST_ASSERT_EQUAL(node.physical_carrier, scene.first, "An installed organ must retain its native wearer subscription")
	TEST_ASSERT_NULL(implant.loc, "Native implantation must keep the organ in nullspace")
	var/obj/structure/closet/crate/container = new(scene.spots[2])
	scene.owned += container
	scene.first.forceMove(container)
	TEST_ASSERT_EQUAL(node.physical_carrier, container, "A nullspace implant must follow its wearer into an outer movable container")
	probe.reset()
	container.forceMove(scene.spots[3])
	TEST_ASSERT(probe.counts[node.address] > 0, "Moving the body's outer container must immediately notify its nullspace implant")
	TEST_ASSERT_EQUAL(probe.positions[node.address], scene.spots[3], "An enclosed body's implant must publish the container's actual turf")
	scene.first.forceMove(scene.spots[2])
	TEST_ASSERT_EQUAL(node.physical_carrier, scene.first, "Leaving the container must restore the implant's ordinary wearer subscription")
	probe.reset()
	container.forceMove(scene.spots[4])
	TEST_ASSERT(!probe.counts[node.address], "A former enclosing container must not generate ghost implant movement")
	implant.Remove(TRUE)
	TEST_ASSERT_NULL(implant.owner, "Native extraction must clear organ ownership")
	TEST_ASSERT_NULL(node.physical_carrier, "Extraction must clear the previous nullspace wearer's subscription")
	implant.forceMove(scene.spots[4])
	probe.reset()
	scene.first.forceMove(scene.spots[3])
	TEST_ASSERT(!probe.counts[node.address], "An extracted implant must not move with its former wearer")
	implant.Insert(scene.second, TRUE)
	TEST_ASSERT_EQUAL(node.physical_carrier, scene.second, "Reinsertion must immediately subscribe to the new native wearer")
	TEST_ASSERT_NULL(implant.loc, "Reinsertion must preserve native nullspace placement")
	probe.reset()
	scene.first.forceMove(scene.spots[2])
	TEST_ASSERT(!probe.counts[node.address], "Reinsertion must not restore the old wearer's subscription")
	scene.second.forceMove(scene.spots[6])
	TEST_ASSERT(probe.counts[node.address] > 0, "The new native wearer must immediately publish implanted endpoint motion")
	TEST_ASSERT_EQUAL(probe.positions[node.address], scene.spots[6], "The reinserted implant must publish the new wearer's actual position")

/// Native nullspace transitions must update nested subscribers as well as ordinary MOVED.
/datum/unit_test/netrun_carriers_container_nullspace/Run()
	var/datum/netrun_carrier_scene/scene = allocate(/datum/netrun_carrier_scene, run_loc_floor_bottom_left)
	var/obj/item/storage/box/container = new(scene.first)
	var/obj/item/endpoint = new(container)
	scene.owned += container
	scene.owned += endpoint
	var/datum/component/netrun_node/node = endpoint.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	scene.warm(list(node))
	var/datum/netrun_carrier_probe/probe = allocate(/datum/netrun_carrier_probe, list(node))
	TEST_ASSERT_EQUAL(node.physical_carrier, scene.first, "The nested endpoint must initially follow its outer owner")
	container.moveToNullspace()
	TEST_ASSERT_NULL(node.physical_turf(), "A nullspace container must not leave its descendant on the former owner's turf")
	TEST_ASSERT(probe.counts[node.address] > 0, "Entering nullspace must synchronously publish descendant endpoint movement")
	TEST_ASSERT_NULL(probe.positions[node.address], "The nullspace notification must publish no fabricated turf")
	TEST_ASSERT_EQUAL(node.physical_carrier, container, "A nullspace container must remain its descendant's root carrier")
	probe.reset()
	scene.first.forceMove(scene.spots[3])
	TEST_ASSERT(!probe.counts[node.address], "Nullspace entry must unsubscribe the container's former outer owner")
	container.forceMove(scene.spots[4])
	TEST_ASSERT(probe.counts[node.address] > 0, "Returning the container to the floor must immediately notify its descendant")
	TEST_ASSERT_EQUAL(probe.positions[node.address], scene.spots[4], "Returning from nullspace must publish the actual floor position")
	TEST_ASSERT_EQUAL(node.physical_carrier, container, "The floor container must continue carrying its nested endpoint")
