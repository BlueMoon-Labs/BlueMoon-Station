/// A resident sees local initiative without opening the combat panel or being hit.
/datum/unit_test/netrun_turn_observer_summary/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/first = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/second = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/observer = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	observer.console.workspace_view = "files"
	observer.console.map_view.selected_address = scene.node_b.address
	TEST_ASSERT(first.console.program_use("builtin:sting", REF(second)), "Two actual residents start their ordinary local combat")
	var/datum/netrun_combat_encounter/encounter = first.console.get_combat_encounter()
	var/paths_before = SSnetrun.combat_ui_tree_builds
	var/full_before = SSnetrun.combat_full_payloads
	var/list/summary = observer.console.combat_context.status_payload()
	var/list/turn = summary?["turn"]
	TEST_ASSERT_NOTNULL(turn, "An unthreatened resident receives local initiative outside the combat workspace")
	TEST_ASSERT(!turn["participating"] && turn["can_join"], "The summary explicitly offers entry rather than pretending the observer is already waiting")
	TEST_ASSERT_EQUAL(turn["join_id"], "[encounter.serial]", "Joining uses the stable identity of the inspected local encounter")
	TEST_ASSERT(!length(summary["incoming"]), "The observer has not been attacked")
	TEST_ASSERT(!("targets" in summary) && !("programs" in summary), "The cross-workspace summary does not serialize hidden combat cards")
	TEST_ASSERT_EQUAL(SSnetrun.combat_ui_tree_builds, paths_before, "Native residency needs no new route tree")
	TEST_ASSERT_EQUAL(SSnetrun.combat_full_payloads, full_before, "Summary observation does not invoke the full combat payload")
	TEST_ASSERT(!encounter.contains(observer) && !observer.console.get_combat_encounter(), "Reading initiative never enrolls its observer")

/// A visible spectator status follows movement and receives only the current node's facts.
/datum/unit_test/netrun_turn_observer_events/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/first = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/second = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/observer = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/datum/netrun_console/console = observer.console
	console.workspace_view = "files"
	console.last_ui_at = world.time
	TEST_ASSERT(first.console.program_use("builtin:sting", REF(second)), "The fixture uses a real local encounter")
	var/datum/netrun_combat_encounter/encounter = first.console.get_combat_encounter()
	TEST_ASSERT_NOTNULL(console.combat_context.status_payload(), "An active spectator opens its lightweight status subscription")
	console.ui_dirty = FALSE
	encounter.changed()
	TEST_ASSERT(console.ui_dirty, "A turn fact refreshes an active status outside the combat workspace")
	observer.enter_node(scene.node_b)
	TEST_ASSERT_EQUAL(console.combat_context.observed_turn_node?.resolve(), scene.node_b, "The observer subscription follows actual resident movement")
	TEST_ASSERT_NULL(console.combat_context.status_payload(), "Leaving the node removes its spectator status")
	console.ui_dirty = FALSE
	encounter.changed()
	TEST_ASSERT(!console.ui_dirty, "The old node cannot keep notifying a departed spectator")
	observer.enter_node(scene.node_a)
	TEST_ASSERT_NOTNULL(console.combat_context.status_payload(), "Returning to the local encounter restores observation without an attack")
	qdel(encounter)
	TEST_ASSERT_NULL(console.combat_context.status_payload(), "Deleting the encounter removes its initiative and join action")

/// A map selection and a stale host field are never enough to disclose another fight.
/datum/unit_test/netrun_turn_observer_residency/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/first = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/second = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/observer = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	observer.console.workspace_view = "terminal"
	observer.console.map_view.selected_address = scene.node_a.address
	TEST_ASSERT(first.console.program_use("builtin:sting", REF(second)), "The remote selected node contains a real fight")
	TEST_ASSERT_NULL(observer.console.combat_context.status_payload(), "Selecting another node does not publish foreign initiative as local status")
	observer.enter_node(scene.node_a)
	TEST_ASSERT_NOTNULL(observer.console.combat_context.status_payload(), "Actual residency makes the same encounter discoverable")
	LAZYREMOVE(scene.node_a.entities, observer)
	var/list/unlisted = observer.console.combat_context.status_payload()
	LAZYADD(scene.node_a.entities, observer)
	TEST_ASSERT_NULL(unlisted, "A stale host pointer without native occupant membership cannot expose a fight")
