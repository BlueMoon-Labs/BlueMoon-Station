/// Observing a live ICE must not turn every subsequent quiet UI into a permanent poll.
/datum/unit_test/netrun_refresh_observed_ice_countdown/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	var/datum/netrun_combat_context/combat = entity.console.combat_context
	combat.observe(ice)
	TEST_ASSERT(!combat.needs_live_refresh(), "An idle observed ICE has no visible countdown")
	TEST_ASSERT(ice.begin_program(SSnetrun.get_program("strike"), entity), "A real ICE must prepare its attack")
	TEST_ASSERT(!combat.needs_live_refresh(), "A turn-owned cast has its native deadline and needs no blanket UI polling")
	ice.cancel_program()
	TEST_ASSERT(!combat.needs_live_refresh(), "Cancelling the cast must allow the UI to become quiet again")
	combat.program_cd["strike"] = world.time + 10 SECONDS
	entity.console.workspace_view = "terminal"
	TEST_ASSERT(!combat.needs_live_refresh(), "Hidden program cooldowns should not poll the terminal")
	entity.console.workspace_view = "combat"
	TEST_ASSERT(!combat.needs_live_refresh(), "Active turn cooldowns count own turns instead of polling wall-clock program timestamps")
	qdel(entity.console.get_combat_encounter())
	TEST_ASSERT(combat.needs_live_refresh(), "Outside an encounter the legacy real-time recovery still updates while visible")

/// Hidden window and map animation data must not wake unrelated workspaces.
/datum/unit_test/netrun_refresh_hidden_workspace/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.remote_session.active_window = "pinned-device"
	console.map_view.ping_route = list("route")
	console.map_view.ping_at = world.time
	console.workspace_view = "terminal"
	TEST_ASSERT(!console.needs_live_refresh(), "A hidden window/ping must not poll the terminal")
	console.workspace_view = "files"
	TEST_ASSERT(!console.needs_live_refresh(), "A hidden window/ping must not poll the file editor")
	console.workspace_view = "pinned"
	TEST_ASSERT(console.needs_live_refresh(), "An active native device page must reconcile external state")
	console.workspace_view = "map"
	TEST_ASSERT(console.needs_live_refresh(), "A visible ping must keep animating and expire")

/// Every ping has a finite lifetime and repeated identical routes remain separate events.
/datum/unit_test/netrun_refresh_ping_lifecycle/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_map_view/view = console.map_view
	var/list/hops = list(list("kind" = "node", "ref" = "PING-A"), list("kind" = "node", "ref" = "PING-B"))
	view.start_ping(hops)
	var/first_id = view.ping_id
	var/list/first = view.ping_metadata()
	TEST_ASSERT(view.has_ping(), "Starting a ping must publish its route")
	TEST_ASSERT_EQUAL(first["id"], first_id, "The metadata must identify the active ping instance")
	TEST_ASSERT(first["remaining_ms"] > 0 && first["remaining_ms"] <= 6000, "A ping must publish its remaining bounded lifetime in milliseconds")
	TEST_ASSERT(view.ping_route != hops, "The map must own its own hop list")
	view.start_ping(hops)
	TEST_ASSERT(view.ping_id > first_id, "Repeating the same path must still produce a new event id")
	TEST_ASSERT(!view.expire_ping(first_id), "A stale timer must not expire a newer ping over the same route")
	TEST_ASSERT(view.has_ping(), "A superseded ping's timer cannot clear the current route")
	view.ping_until = world.time - 1
	console.ui_dirty = FALSE
	TEST_ASSERT(view.expire_ping(view.ping_id), "The active ping must expire at its deadline")
	TEST_ASSERT_NULL(view.ping_route, "Expiry must release the retained route")
	TEST_ASSERT_NULL(view.ping_metadata(), "An expired ping cannot remain in UI metadata")
	TEST_ASSERT_NULL(view.ping_timer, "Expiry must release its scheduled timer")
	TEST_ASSERT(console.ui_dirty, "Expiry must push a closing frame even when the map is otherwise quiet")
	console.ui_dirty = FALSE
	TEST_ASSERT(!view.expire_ping(view.ping_id), "Expiry must be idempotent")
	TEST_ASSERT(!console.ui_dirty, "An already expired ping must not repeatedly wake the UI")
	var/list/payload = console.ui_data(null)
	TEST_ASSERT_NULL(payload["ping_route"], "The legacy ping_route field must clear with the new metadata")
	TEST_ASSERT_NULL(payload["ping"], "The next backend payload must clear the ping instance")

/// The processing path closes overdue pings even if timer delivery was delayed.
/datum/unit_test/netrun_refresh_ping_overdue/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.workspace_view = "map"
	console.map_view.start_ping(list(list("kind" = "node", "ref" = "PING")))
	console.map_view.ping_until = world.time - 1
	console.process_tick(0)
	TEST_ASSERT_NULL(console.map_view.ping_route, "Processing must close an overdue ping before deciding whether the UI is live")
	TEST_ASSERT_NULL(console.map_view.ping_timer, "The processing fallback must also release the timer")

/// Files and pinned tabs must receive external changes while their expensive map is asleep.
/datum/unit_test/netrun_refresh_hidden_map_observer/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/item/target = allocate(/obj/item)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 1, null, 8)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.note_ui_activity()
	console.map_view.selected_address = node.address
	// The fixture changes selection directly instead of going through a user action.
	SSnetrun.collect_console_node_interest(console)
	console.workspace_view = "files"
	console.map_view.subscribe()
	console.process_tick(0)
	TEST_ASSERT(!console.map_view.subscribed, "A hidden map must release its global projection subscriptions")
	console.ui_dirty = FALSE
	node.notify_changed()
	SSnetrun.flush_node_publications()
	TEST_ASSERT(console.ui_dirty, "A selected device change must still wake its file workspace")
	TEST_ASSERT_EQUAL(length(console.map_view.dirty_nodes), 0, "A hidden map must not accumulate a projection update queue")

	console.map_view.selected_address = null
	console.remote_session.windows += node.address
	console.remote_session.active_window = node.address
	console.workspace_view = "pinned"
	console.ui_dirty = FALSE
	node.notify_changed()
	SSnetrun.flush_node_publications()
	TEST_ASSERT(console.ui_dirty, "An active pinned device must react independently of the selected map node")

	console.workspace_view = "files"
	console.map_view.selected_address = node.address
	console.ui_dirty = FALSE
	var/datum/netrun_file/file = new("external.txt", NETRUN_FILE_TEXT, "Another runner uploaded this file.")
	TEST_ASSERT(node.file_store.insert(file), "The selected endpoint must accept a real external file")
	SSnetrun.flush_node_publications()
	TEST_ASSERT(console.ui_dirty, "An external remote-store write must wake the file list")
	console.ui_dirty = FALSE
	node.add_log("Another runner inspected this device.")
	SSnetrun.flush_node_publications()
	TEST_ASSERT(console.ui_dirty, "A selected device's new log line must wake its observers")
	console.map_view.selected_network = node.network.id
	console.ui_dirty = FALSE
	node.network.add_log("External network activity.")
	SSnetrun.flush_node_publications()
	TEST_ASSERT(console.ui_dirty, "A selected network log must wake its observers")

/// A backend notification queues one normal task immediately, independently of population.
/datum/unit_test/netrun_refresh_invalidation_coalesces/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	var/key = "console:[REF(console)]"
	console.note_ui_activity()
	scheduler.cancel("console", console)
	var/populations = SSnetrun.task_populations
	console.invalidate_ui()
	var/datum/netrun_task/task = scheduler.by_key[key]
	TEST_ASSERT_NOTNULL(task, "Backend invalidation must queue processing before the next population pass")
	TEST_ASSERT(!task.interactive, "A background notification must preserve the explicit-input lane for player actions")
	console.invalidate_ui()
	TEST_ASSERT_EQUAL(scheduler.by_key[key], task, "Several domain changes must share one queued console task")
	TEST_ASSERT_EQUAL(SSnetrun.task_populations, populations, "Queuing a reactive update must not repopulate all subsystem work")
	qdel(console)
	TEST_ASSERT_NULL(scheduler.by_key[key], "Deleting a console must cancel its pending reactive task")

/// Messages from another session must reach quiet readers without map or timer activity.
/datum/unit_test/netrun_refresh_chat_broadcast/Run()
	var/obj/item/first_host = allocate(/obj/item)
	var/obj/item/second_host = allocate(/obj/item)
	var/datum/netrun_console/first = allocate(/datum/netrun_console, first_host)
	var/datum/netrun_console/second = allocate(/datum/netrun_console, second_host)
	first.note_ui_activity()
	second.note_ui_activity()
	first.workspace_view = "terminal"
	second.workspace_view = "files"
	var/datum/ntnet_conversation/channel = SSnetrun.get_net_channel()
	first.ui_dirty = FALSE
	second.ui_dirty = FALSE
	channel.add_message("Reactive chat test.", "test-runner")
	TEST_ASSERT(first.ui_dirty, "A quiet terminal must receive a new channel message")
	TEST_ASSERT(!second.ui_dirty, "A hidden chat must not serialize the file workspace for every channel message")
	TEST_ASSERT(!first.map_view.subscribed && !second.map_view.subscribed, "Chat delivery must not subscribe hidden map projections")
	second.workspace_view = "terminal"
	var/list/payload = second.ui_data(null)
	var/list/chat = payload["chat"]
	TEST_ASSERT(findtext(jointext(chat["messages"], "\n"), "Reactive chat test."), "Opening the terminal receives messages that arrived while chat was hidden")

/// Turn-owned timers and invisible fortress panels do not create extra UI polls.
/datum/unit_test/netrun_refresh_fortress_scope/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Scoped refresh", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/turret = fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	var/datum/netrun_combat_encounter/encounter = scene.node_b.get_combat_encounter()
	TEST_ASSERT(encounter.admit(entity, 1, turret), "The native battery joins the process's actual encounter")
	turret.jammed_until = INFINITY
	TEST_ASSERT(!fortress.needs_live_refresh(), "Turn-owned jamming cannot start a permanent seconds-based UI poll")
	var/datum/netrun_console/console = entity.console
	console.map_view.selected_address = scene.node_b.address
	console.workspace_view = "map"
	TEST_ASSERT(!console.needs_live_refresh(), "A map with turn-owned battery state rests between real changes")
	fortress.add_module(NETRUN_FORT_WALL, FALSE)
	TEST_ASSERT(console.needs_live_refresh(), "A displayed construction countdown still refreshes")
	console.workspace_view = "files"
	TEST_ASSERT(console.needs_live_refresh(), "The visible file page keeps its fortress construction current")
	console.workspace_view = "agents"
	TEST_ASSERT(!console.needs_live_refresh(), "A hidden fortress countdown cannot wake the agent workspace")
	console.workspace_view = "pinned"
	console.map_view.selected_address = scene.node_a.address
	console.remote_session.active_window = scene.node_b.address
	TEST_ASSERT(console.needs_live_refresh(), "A pinned device uses its own displayed fortress instead of the map selection")

/// Context listeners follow the current operator and every container carrying the console.
/datum/unit_test/netrun_refresh_observer_lifecycle/Run()
	var/obj/item/carrier = allocate(/obj/item)
	var/obj/item/host = allocate(/obj/item, carrier)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/mob/living/first = allocate(/mob/living)
	var/mob/living/second = allocate(/mob/living)
	console.operator = first
	console.note_ui_activity()
	TEST_ASSERT(console.ui_context_sources[first], "The active operator must own a context subscription")
	TEST_ASSERT(console.ui_context_sources[carrier], "A nested console must observe the container moving its host")
	console.ui_dirty = FALSE
	carrier.forceMove(get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT(console.ui_dirty, "Moving a console's carrier must refresh the source without waiting for polling")

	console.operator = second
	console.observe_ui_state()
	TEST_ASSERT(!console.ui_context_sources[first], "Replacing the operator must release the old mob's listeners")
	TEST_ASSERT(console.ui_context_sources[second], "Replacing the operator must observe the new mob immediately")
	console.ui_dirty = FALSE
	SEND_SIGNAL(first, COMSIG_MOB_EQUIPPED_ITEM, host, ITEM_SLOT_HANDS)
	TEST_ASSERT(!console.ui_dirty, "The previous operator's equipment must no longer invalidate the console")
	SEND_SIGNAL(second, COMSIG_MOB_EQUIPPED_ITEM, host, ITEM_SLOT_HANDS)
	TEST_ASSERT(console.ui_dirty, "The new operator's equipment must invalidate derived access")

	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	console.map_view.subscribe()
	console.stop_ui_observation()
	TEST_ASSERT(!console.ui_observing && !length(console.ui_context_sources), "Suspending an inactive viewer must release all context listeners")
	TEST_ASSERT(!console.map_view.subscribed, "Suspending an inactive viewer must also release the map's global subscriptions")
	console.ui_dirty = FALSE
	SEND_SIGNAL(SSnetrun, COMSIG_NETRUN_CHAT_CHANGED)
	SEND_SIGNAL(second, COMSIG_MOB_EQUIPPED_ITEM, host, ITEM_SLOT_HANDS)
	node.notify_changed()
	TEST_ASSERT(!console.ui_dirty, "A suspended viewer must receive neither global nor context broadcasts")
	TEST_ASSERT_EQUAL(length(console.map_view.dirty_nodes), 0, "A suspended map must not collect stale node updates")
	console.note_ui_activity()
	SEND_SIGNAL(SSnetrun, COMSIG_NETRUN_CHAT_CHANGED)
	TEST_ASSERT(console.ui_dirty, "A reopened viewer must subscribe again")

/// A neural resident captures its ID once; unconscious body inventory is not polled.
/datum/unit_test/netrun_refresh_neural_body_credentials/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_MEDICAL)
	TEST_ASSERT(scene.user.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING, disable_warning = TRUE), "The diver must wear a uniform")
	TEST_ASSERT(scene.user.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE), "The diver must wear an ID")
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The fixture must enter the network")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/datum/netrun_console/entity/console = entity.console
	console.note_ui_activity()
	TEST_ASSERT(!console.ui_context_sources[scene.user], "The body is not an equipment-dependent credential input during a dive")
	console.access_cache = console.user_access(TRUE)
	TEST_ASSERT(ACCESS_MEDICAL in console.user_access(), "The cached credentials must include the body's ID")
	console.ui_dirty = FALSE
	TEST_ASSERT(scene.user.dropItemToGround(card), "Another actor must be able to remove the body's ID")
	TEST_ASSERT(ACCESS_MEDICAL in console.user_access(TRUE), "Removing the body's ID cannot revoke the entry snapshot")
	console.ui_dirty = FALSE
	TEST_ASSERT(scene.user.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE), "The ID must be replaceable during the dive")
	TEST_ASSERT(ACCESS_MEDICAL in console.user_access(TRUE), "Replacing the ID leaves the same entry snapshot active")
	var/datum/netrun_file/access/session_snapshot/snapshot = entity.dive_link.identity_snapshot
	TEST_ASSERT(console.delete_local_file(snapshot), "The player may explicitly revoke the session snapshot file")
	TEST_ASSERT(!(ACCESS_MEDICAL in console.user_access(TRUE)), "File revocation is immediate even while the physical ID remains worn")
	console.stop_ui_observation()
	TEST_ASSERT(!console.ui_context_sources[scene.user], "Closing the UI must release the body's subscriptions")
	console.ui_dirty = FALSE
	TEST_ASSERT(scene.user.dropItemToGround(card), "The ID must remain removable after closing the UI")
	TEST_ASSERT(!console.ui_dirty, "A closed UI must not receive body equipment events")

/// An ordinary carried item wakes the UI without invalidating its entire map.
/datum/unit_test/netrun_refresh_unrelated_inventory_keeps_map/Run()
	var/turf/origin = run_loc_floor_bottom_left
	netrun_connected_test_area()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, origin)
	var/obj/item/netrun_deck/deck = allocate(/obj/item/netrun_deck, carrier)
	var/datum/netrun_console/console = deck.console
	console.operator = carrier
	console.workspace_view = "map"
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	SSnetrun.ensure_topology()
	console.ui_data(null)
	var/rebuilds = view.rebuilds
	var/projected = view.serialized_nodes
	var/authorization = view.authorization_revision
	console.ui_dirty = FALSE
	var/obj/item/unrelated = allocate(/obj/item, origin)
	unrelated.forceMove(carrier)
	TEST_ASSERT(console.ui_dirty, "A real containment change must still wake the UI")
	TEST_ASSERT(!view.dirty, "An unrelated item must not force a full map projection")
	console.ui_data(null)
	TEST_ASSERT_EQUAL(view.rebuilds, rebuilds, "Moving an unrelated item into the carrier must retain the map")
	TEST_ASSERT_EQUAL(view.serialized_nodes, projected, "Unchanged device access must not reproject stationary nodes")
	TEST_ASSERT_EQUAL(view.authorization_revision, authorization, "An ordinary item must not fabricate an authorization change")

/// A same-tile transfer must revoke a worn endpoint's ownership on the next UI payload.
/datum/unit_test/netrun_refresh_same_tile_worn_owner_transfer/Run()
	var/turf/origin = run_loc_floor_bottom_left
	netrun_connected_test_area()
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human, origin)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, origin)
	var/obj/item/netrun_deck/deck = allocate(/obj/item/netrun_deck, first)
	var/obj/item/clothing/glasses/hud/health/night/glasses = allocate(/obj/item/clothing/glasses/hud/health/night, origin)
	TEST_ASSERT(first.equip_to_slot_if_possible(glasses, ITEM_SLOT_EYES, disable_warning = TRUE), "The first user must wear the real HUD glasses")
	var/datum/component/netrun_node/node = glasses.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_console/console = deck.console
	console.operator = first
	console.workspace_view = "map"
	SSnetrun.ensure_topology()
	node.join_network()
	node.reconcile_state()
	node.publish_changes()
	var/list/map = console.ui_data(null)["map"]
	var/list/entry
	for(var/list/candidate as anything in map["nodes"])
		if(candidate["address"] == node.address)
			entry = candidate
			break
	TEST_ASSERT_NOTNULL(entry, "The wearer's HUD node must appear on the live map")
	TEST_ASSERT_EQUAL(entry["access"], NETRUN_ACCESS_ROOT, "The wearer must see ROOT access before transferring the HUD")
	console.ui_dirty = FALSE
	TEST_ASSERT(first.dropItemToGround(glasses), "The first user must actually remove the worn HUD")
	TEST_ASSERT(second.put_in_hands(glasses), "The second user must pick up the same HUD")
	TEST_ASSERT_EQUAL(glasses.netrun_owner_access(console), NETRUN_ACCESS_NONE, "Ownership must end on the same physical tile")
	TEST_ASSERT(console.ui_dirty, "The ownership transfer must wake the open map")
	// No scheduler tick or manual node publication: this is the first UI update
	// after the actual inventory transfer, while both characters remain in place.
	map = console.ui_data(null)["map"]
	entry = null
	for(var/list/candidate as anything in map["nodes"])
		if(candidate["address"] == node.address)
			entry = candidate
			break
	if(entry)
		TEST_ASSERT_EQUAL(entry["access"], console.node_level(node), "The first map payload cannot retain the former owner's ROOT access")
		TEST_ASSERT(entry["access"] < NETRUN_ACCESS_ROOT, "A transferred HUD cannot retain ROOT on the old wearer's map")

/// Countdown repaint work must end after one task instead of requeuing in the same tick.
/datum/unit_test/netrun_refresh_countdown_does_not_requeue/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	console.note_ui_activity()
	// Establish the initial turf/credential observation before isolating the countdown.
	console.reconcile_ui_context()
	scheduler.cancel("console", console)
	console.intrusion.trace = 5
	console.intrusion.last_illegal = world.time
	console.ui_event_pending = FALSE
	console.ui_dirty = FALSE
	var/key = "console:[REF(console)]"
	var/datum/netrun_task/console/task = allocate(/datum/netrun_task/console, "console", key, NETRUN_TASK_NORMAL, console)
	task.execute(SSnetrun, SSnetrun.get_execution_limits())
	TEST_ASSERT(console.ui_dirty, "A visible trace countdown must still request its next repaint")
	TEST_ASSERT(!console.ui_event_pending, "A countdown repaint must not pretend to be a new domain event")
	TEST_ASSERT_NULL(scheduler.by_key[key], "A countdown task must not queue another same-tick task")
	var/datum/netrun_execution_limits/limits = SSnetrun.get_execution_limits()
	var/previous_flush = limits.interactive_flush
	limits.interactive_flush = FALSE
	console.ui_event_pending = TRUE
	task.execute(SSnetrun, limits)
	limits.interactive_flush = previous_flush
	TEST_ASSERT(console.ui_dirty && console.ui_event_pending, "A throttled domain event must remain pending for a later pass")
	TEST_ASSERT_NULL(scheduler.by_key[key], "Disabling immediate flushes must not create an event requeue loop")

/obj/item/netrun_refresh_status_test
	var/status_value = 1

/obj/item/netrun_refresh_status_test/netrun_status()
	return list("value" = status_value)

/// Legacy status fields without signals are compared locally without quiet panel redraws.
/datum/unit_test/netrun_refresh_selected_legacy_status/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/item/netrun_refresh_status_test/target = allocate(/obj/item/netrun_refresh_status_test)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.connection.wireless = FALSE
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	console.workspace_view = "files"
	console.note_ui_activity()
	console.reconcile_ui_context()
	console.ui_dirty = FALSE
	console.reconcile_ui_context()
	TEST_ASSERT(!console.ui_dirty, "A quiet legacy panel must not repaint an unchanged status")
	target.status_value = 2
	console.reconcile_ui_context()
	TEST_ASSERT(console.ui_dirty, "A native status change without a signal must refresh the visible selected panel")
	console.workspace_view = "terminal"
	console.reconcile_ui_context()
	console.ui_dirty = FALSE
	target.status_value = 3
	console.reconcile_ui_context()
	TEST_ASSERT(!console.ui_dirty, "Changes to a hidden legacy status must not repaint the terminal")

/// Closing the most recent viewer must not leave another open terminal without subscriptions.
/datum/unit_test/netrun_refresh_multiple_viewers/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/mob/living/first = allocate(/mob/living)
	var/mob/living/second = allocate(/mob/living)
	var/datum/tgui/first_ui = allocate(/datum/tgui, first, console, "NetrunTerminal")
	var/datum/tgui/second_ui = allocate(/datum/tgui, second, console, "NetrunTerminal")
	var/key = REF(console)
	var/list/previous_viewers = SStgui.open_uis_by_src[key]
	SStgui.open_uis_by_src[key] = list(first_ui, second_ui)
	console.operator = second
	console.note_ui_activity()
	var/both_observed = console.ui_context_sources[first] && console.ui_context_sources[second]
	SStgui.open_uis_by_src[key] = list(first_ui)
	console.last_ui_at = -INFINITY
	var/still_active = console.is_ui_active()
	console.refresh_ui_context_sources()
	var/remaining_observed = console.ui_context_sources[first]
	console.ui_dirty = FALSE
	SEND_SIGNAL(first, COMSIG_MOB_EQUIPPED_ITEM, host, ITEM_SLOT_HANDS)
	var/remaining_invalidated = console.ui_dirty
	if(isnull(previous_viewers))
		SStgui.open_uis_by_src -= key
	else
		SStgui.open_uis_by_src[key] = previous_viewers
	TEST_ASSERT(both_observed, "Every open viewer must receive credential-context subscriptions")
	TEST_ASSERT(still_active, "An older viewer must keep a shared console active after the last operator leaves")
	TEST_ASSERT(remaining_observed, "The remaining viewer must retain its context subscription")
	TEST_ASSERT(remaining_invalidated, "The remaining viewer's equipment must still invalidate the shared console")

/// This observer counts global publication only, independently of immediate local gameplay signals.
/datum/netrun_node_publication_probe
	var/datum/component/netrun_node/target
	var/count = 0
	var/flags = 0
	var/native_count = 0

/datum/netrun_node_publication_probe/proc/on_changed(datum/source, list/changes)
	SIGNAL_HANDLER
	if(!isnull(changes[target.address]))
		count++
		flags |= changes[target.address]

/datum/netrun_node_publication_probe/proc/on_native_changed(datum/source, datum/component/netrun_node/node, changes)
	SIGNAL_HANDLER
	if(node == target)
		native_count++

/datum/component/netrun_node/netrun_publication_probe
	var/online_calls = 0
	var/join_calls = 0

/datum/component/netrun_node/netrun_publication_probe/is_online(remote = TRUE)
	online_calls++
	return ..()

/datum/component/netrun_node/netrun_publication_probe/join_network()
	join_calls++
	return ..()

/// Observational bursts merge before UI fanout and never schedule native state work.
/datum/unit_test/netrun_refresh_cold_node_coalescing/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/netrun_publication_probe/node = host.AddComponent(/datum/component/netrun_node/netrun_publication_probe, NETRUN_NODE_TERMINAL)
	SSnetrun.flush_node_publications()
	var/datum/netrun_node_publication_probe/probe = allocate(/datum/netrun_node_publication_probe)
	probe.target = node
	probe.RegisterSignal(SSnetrun, COMSIG_NETRUN_NODES_CHANGED, TYPE_PROC_REF(/datum/netrun_node_publication_probe, on_changed))
	probe.RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_CHANGED, TYPE_PROC_REF(/datum/netrun_node_publication_probe, on_native_changed))
	SSnetrun.node_interest_until[node] = world.time + NETRUN_NODE_INTEREST_LEASE
	SSnetrun.dirty_nodes -= node
	SSnetrun.get_task_scheduler().cancel("node", node)
	node.urgent_update = FALSE
	node.last_processed_at = world.time
	var/processed_at = node.last_processed_at
	var/online_calls = node.online_calls
	var/join_calls = node.join_calls
	for(var/i in 1 to 40)
		node.add_log("Observer burst [i].")
		node.add_packet_log("packet-[i]", "FORWARD", "machine", "source", "target", "test")
		node.notify_changed(NETRUN_CHANGED_OCCUPANTS)
		node.queue_presentation(NETRUN_CHANGED_STATE)
	TEST_ASSERT_NULL(SSnetrun.dirty_nodes[node], "Logs and occupancy publications must not require a whole native node update")
	TEST_ASSERT_EQUAL(node.last_processed_at, processed_at, "An incoming signal must not pretend processing finished")
	TEST_ASSERT_EQUAL(node.online_calls, online_calls, "A journal/occupancy burst must not poll native power")
	TEST_ASSERT_EQUAL(node.join_calls, join_calls, "A journal/occupancy burst must not rejoin network bindings")
	TEST_ASSERT_EQUAL(probe.count, 0, "Repeated observations must wait for the single batched publication")
	TEST_ASSERT_EQUAL(probe.native_count, 0, "Observational changes must not wake native service listeners")
	TEST_ASSERT_NULL(SSnetrun.get_task_scheduler().by_key["node:[REF(node)]"], "Observational bursts must not enter the native scheduler")
	node.offline_until = world.time + 5 SECONDS
	node.notify_changed()
	TEST_ASSERT_EQUAL(probe.native_count, 1, "A true availability transition must still notify native service observers immediately")
	TEST_ASSERT(!node.last_online, "Native availability must be reconciled before a UI batch is published")
	SSnetrun.flush_node_publications()
	TEST_ASSERT_EQUAL(probe.count, 1, "The worker boundary must publish one merged address update")
	TEST_ASSERT(probe.flags & NETRUN_CHANGED_OCCUPANTS, "The batch must retain occupancy flags")
	TEST_ASSERT(probe.flags & NETRUN_CHANGED_STATE, "The batch must retain native state flags")
	TEST_ASSERT(probe.flags & NETRUN_CHANGED_DETAILS, "The batch must retain selected-panel detail changes")
	SSnetrun.node_interest_until -= node
	node.add_log("Unobserved background log.")
	TEST_ASSERT_NULL(SSnetrun.node_publications[node.address], "An unobserved journal must keep its contents without scheduling any publication")
	probe.UnregisterSignal(SSnetrun, list(COMSIG_NETRUN_NODES_CHANGED, COMSIG_NETRUN_NODE_CHANGED))

/// Player interest releases deferred work; urgent availability and timer work never waits.
/datum/unit_test/netrun_refresh_node_interest_and_timers/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.track_node(node)
	node.last_processed_at = world.time
	node.urgent_update = FALSE
	worker.queue_node(node)
	TEST_ASSERT_NULL(worker.get_task_scheduler().by_key["node:[REF(node)]"], "An idle dirty node must wait for its cold deadline")
	worker.retain_node_interest(node, world.time + 1 MINUTES)
	TEST_ASSERT_EQUAL(worker.node_interest_until[node], world.time + NETRUN_NODE_INTEREST_LEASE, "Interest must have a bounded lease")
	TEST_ASSERT_NOTNULL(worker.get_task_scheduler().by_key["node:[REF(node)]"], "Interaction must release a deferred node immediately")
	worker.finish_node_poll(node)
	TEST_ASSERT_EQUAL(worker.poll_nodes[node], world.time + worker.get_execution_limits().node_poll_interval, "Interesting legacy nodes need the fast cadence")
	worker.node_interest_until -= node
	worker.finish_node_poll(node)
	TEST_ASSERT_EQUAL(worker.poll_nodes[node], world.time + worker.get_execution_limits().node_idle_poll_interval, "An expired lease must restore sparse fallback polling")
	worker.get_task_scheduler().cancel("node", node)
	worker.dirty_nodes -= node
	worker.timed_nodes[node] = world.time
	worker.populate_node_tasks()
	var/datum/netrun_task/task = worker.get_task_scheduler().by_key["node:[REF(node)]"]
	TEST_ASSERT(task && task.priority == NETRUN_TASK_NORMAL && node.urgent_update, "A due native timer must bypass cold throttling")

/// Merely populating the world with autonomous entities must not make every node interesting.
/datum/unit_test/netrun_refresh_interest_ignores_idle_entities/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.nodes_by_address[node.address] = node
	entity.console.last_ui_at = -INFINITY
	worker.collect_console_node_interest(entity.console)
	TEST_ASSERT(!length(worker.node_interest_until), "A clientless idle entity must not renew player-interest leases")
	entity.console.note_ui_activity()
	worker.collect_console_node_interest(entity.console)
	TEST_ASSERT(!length(worker.node_interest_until), "An autonomous entity's simulated interaction must not impersonate a player viewer")
	var/datum/netrun_console/viewed = allocate(/datum/netrun_console, host)
	viewed.note_ui_activity()
	worker.collect_console_node_interest(viewed)
	TEST_ASSERT(worker.node_interest_until[node] > world.time, "An actually viewed physical console must retain its own host")

/// Route/ping interests use only the supplied path, never the full reachable graph.
/datum/unit_test/netrun_refresh_path_interest_scope/Run()
	var/obj/item/first_host = allocate(/obj/item)
	var/obj/item/second_host = allocate(/obj/item)
	var/obj/item/unrelated_host = allocate(/obj/item)
	var/datum/component/netrun_node/first = first_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/component/netrun_node/second = second_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/component/netrun_node/unrelated = unrelated_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.nodes_by_address[first.address] = first
	worker.nodes_by_address[second.address] = second
	worker.nodes_by_address[unrelated.address] = unrelated
	worker.retain_route_interest(list(first.address, list("kind" = "node", "ref" = second.address), list("kind" = "network", "ref" = unrelated.address)), world.time + 6 SECONDS)
	TEST_ASSERT(worker.node_interest_until[first] > world.time && worker.node_interest_until[second] > world.time, "Address and node-hop path formats must retain exactly their endpoints")
	TEST_ASSERT(isnull(worker.node_interest_until[unrelated]), "A network hop or unrelated registered device must not become hot")
	worker.untrack_node(second)
	TEST_ASSERT(isnull(worker.node_interest_until[second]), "Node teardown must release its interest lease")

/// A backlog must not amplify one overdue node into new producer requests every population.
/datum/unit_test/netrun_refresh_pending_node_admission/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.dirty_nodes[node] = world.time - 1 SECONDS
	worker.poll_nodes[node] = world.time - 1 SECONDS
	worker.timed_nodes[node] = world.time - 1 SECONDS
	for(var/population in 1 to 64)
		worker.populate_node_tasks()
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	var/datum/netrun_task_profile/profile = scheduler.profiles["node"]
	TEST_ASSERT_EQUAL(scheduler.pending(), 1, "Dirty, poll and timer demand must share one pending reconciliation")
	TEST_ASSERT_EQUAL(profile.requests, 1, "An overdue backlog must not repeatedly enter scheduler admission")
	TEST_ASSERT_EQUAL(profile.created, 1, "Repeated populations must allocate one node task")
	TEST_ASSERT(node.urgent_update, "Timer expiry must still bypass cold-node throttling")
	var/datum/netrun_task/task = scheduler.by_key["node:[REF(node)]"]
	TEST_ASSERT_EQUAL(task.priority, NETRUN_TASK_NORMAL, "A background poll cannot downgrade dirty/timer work")
	scheduler.cancel("node", node)
	worker.populate_node_tasks()
	TEST_ASSERT_EQUAL(profile.created, 2, "Cancellation cannot strand still-overdue native state")
	worker.untrack_node(node)
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "Node teardown must release the pending state and all deadlines")
