/// Hermetic read model соответствует полям EntityView; тест не включает production actor engine.
/datum/unit_test/proc/netrun_external_entity_view(datum/netrun_external_entity_proxy/proxy, datum/component/netrun_node/node, revision = "1", integrity = 100)
	var/datum/netrun_external_core/client = proxy.client_ref.resolve()
	var/list/key = client.node_key(node)
	return list("actor" = proxy.actor_key.Copy(), "revision" = revision, "residence_revision" = "1", "kind" = 0,
		"node" = list("node_id" = key["id"], "generation" = key["generation"]), "integrity" = integrity, "max_integrity" = 100,
		"persona" = list("alias" = "Fixture", "avatar" = "cipher", "accent" = "cyan", "tagline" = "", "theme" = "ion"),
		"faction_id" = "owner:fixture", "principal_id" = "fixture", "profile_id" = null, "autonomous" = FALSE,
		"stunned_until_ds" = 0, "shield_until_ds" = 0, "shield_factor" = 1, "next_hop_ds" = 0,
		"alive" = TRUE, "pending_effect_id" = null, "expires_at_ds" = null)

/// Registration/task completion and teardown maintain one O(1) clock-demand owner per native actor.
/datum/unit_test/netrun_external_entities_clock_lifecycle/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, null, scene.source.node)
	var/datum/netrun_external_entity_proxy/proxy = fixture.client.entity_proxy(entity, TRUE)
	TEST_ASSERT_NOTNULL(proxy, "An explicit proxy is created without switching a production engine")
	TEST_ASSERT_EQUAL(fixture.executor.entity_clock_demand, 0, "An unused proxy has no simulation-clock demand")
	var/id = proxy.register()
	TEST_ASSERT_NOTNULL(id, "Registration uses the ordinary auxiliary transport")
	TEST_ASSERT_EQUAL(fixture.executor.entity_clock_demand, 1, "One registered-or-pending proxy owns one clock demand")
	TEST_ASSERT_NULL(proxy.register(), "Duplicate register cannot enqueue a second create")
	TEST_ASSERT_EQUAL(fixture.executor.entity_clock_demand, 1, "Repeated register cannot inflate demand")
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Create reaches the existing causal input queue")
	fixture.executor.observe_result(fixture.client, list("input_sequence" = fixture.client.pending_sequence, "admission" = list("status" = "accepted")))
	fixture.client.pending_frame = null
	TEST_ASSERT(fixture.executor.process_result(fixture.client, list("kind" = "core_task_completed", "binding_epoch" = fixture.client.binding_epoch,
		"request_id" = id, "task_sequence" = "1", "success" = TRUE, "code" = "accepted")), "Task completion releases the transient consumer")
	TEST_ASSERT_NULL(fixture.executor.get_query_consumer(id), "No task consumer is retained just to advance a clock")
	TEST_ASSERT(fixture.executor.has_pending_work(), "Native actor lifetime still needs the Core simulation clock")
	fixture.client.last_simulation_time = max(0, round(world.time) - 1)
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "An idle actor sends a time-only input")
	TEST_ASSERT_EQUAL(fixture.client.pending_frame, "\[\]", "The clock frame contains no local simulation decisions")
	fixture.client.pending_frame = null
	TEST_ASSERT(!fixture.executor.prepare_input(fixture.client), "The same simulation time cannot create a busy loop")
	fixture.executor.disconnected(fixture.client, "test_disconnect")
	TEST_ASSERT_EQUAL(fixture.executor.entity_clock_demand, 0, "Disconnect releases every old-binding demand")
	TEST_ASSERT(!proxy.connected && !proxy.registered, "Disconnect is fail closed")
	qdel(proxy)
	TEST_ASSERT_EQUAL(fixture.executor.entity_clock_demand, 0, "Late proxy destruction cannot decrement a replacement binding")

/// Projection state cannot teleport a native representation or overwrite a newer actor generation/revision.
/datum/unit_test/netrun_external_entities_projection_stale/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, null, scene.source.node)
	var/datum/netrun_external_entity_proxy/proxy = fixture.client.entity_proxy(entity, TRUE)
	var/list/current = netrun_external_entity_view(proxy, scene.source.node, "2", 72)
	TEST_ASSERT(proxy.apply_view(fixture.client, current, "changed"), "An exact current native representation accepts its Core projection")
	TEST_ASSERT_EQUAL(entity.integrity, 72, "Integrity comes from the authoritative read model")
	TEST_ASSERT_EQUAL(fixture.executor.entity_clock_demand, 1, "A published live representation needs one clock owner")
	TEST_ASSERT(proxy.apply_view(fixture.client, netrun_external_entity_view(proxy, scene.source.node, "1", 11), "changed"), "Old revisions are harmless")
	TEST_ASSERT_EQUAL(entity.integrity, 72, "An old projection cannot roll back current integrity")
	var/list/foreign = netrun_external_entity_view(proxy, scene.source.node, "3", 10)
	foreign["actor"] = list("actor_id" = proxy.actor_key["actor_id"], "generation" = "2")
	TEST_ASSERT(!proxy.apply_view(fixture.client, foreign, "changed"), "A different native actor generation is rejected")
	TEST_ASSERT(!proxy.apply_view(fixture.client, netrun_external_entity_view(proxy, scene.target.node, "3", 10), "changed"), "A plain projection cannot move a native representation")
	TEST_ASSERT_EQUAL(entity.host_node, scene.source.node, "Only an exact native effect may change residence")
	TEST_ASSERT(fixture.executor.process_result(fixture.client, list("kind" = "entity_changed", "binding_epoch" = fixture.client.binding_epoch,
		"request_id" = "entity.lifecycle:4", "actor" = proxy.actor_key.Copy(), "view" = netrun_external_entity_view(proxy, scene.source.node, "4", 70), "code" = "status_expired")), "Core-owned lifecycle events do not require a locally allocated request")
	TEST_ASSERT_EQUAL(entity.integrity, 70, "Autonomous Core status projection is applied")
	TEST_ASSERT(proxy.apply_view(fixture.client, null, "removed"), "Core deletion removes only the proxy ownership")
	TEST_ASSERT_EQUAL(fixture.executor.entity_clock_demand, 0, "A removed Core actor does not keep a clock alive")

/// Replacing a proxy on the same native datum cannot reuse the previous Core actor generation.
/datum/unit_test/netrun_external_entities_proxy_generation/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, null, scene.source.node)
	var/datum/netrun_external_entity_proxy/first = fixture.client.entity_proxy(entity, TRUE)
	var/list/old = first.actor_key.Copy()
	qdel(first)
	TEST_ASSERT_NULL(entity.external_entity_proxy, "Destroy releases the native field")
	TEST_ASSERT_NULL(fixture.executor.entity_proxies[old["actor_id"]], "Destroy releases the weak registry even while resolve hides deleting objects")
	var/datum/netrun_external_entity_proxy/second = fixture.client.entity_proxy(entity, TRUE)
	TEST_ASSERT_EQUAL(second.actor_key["actor_id"], old["actor_id"], "The same physical datum retains its opaque identity")
	TEST_ASSERT(netrun_external_decimal_compare(second.actor_key["generation"], old["generation"]) > 0, "The replacement Core process receives a newer generation")
	TEST_ASSERT_NULL(fixture.executor.entity_proxy_for(old), "A stale actor key never resolves to its replacement")
	fixture.executor.disconnect_entities()
	fixture.client.binding_epoch = "replacement-binding"
	var/datum/netrun_external_entity_proxy/rebound = fixture.client.entity_proxy(entity, TRUE)
	TEST_ASSERT_EQUAL(rebound.binding, "replacement-binding", "Rebind creates a fresh native continuation")
	TEST_ASSERT(!netrun_external_entity_actor_same(old, rebound.actor_key), "Old-binding identities do not revive")

/// Opaque authority generations and original scope stamps are native facts, never refreshed DM levels.
/datum/unit_test/netrun_external_entities_raw_access_scopes/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, null, scene.source.node)
	var/datum/netrun_network/network = allocate(/datum/netrun_network, "raw-scope-fixture")
	var/datum/netrun_grant_scope/scope = allocate(/datum/netrun_grant_scope, network, scene.source.node)
	var/old_stamp = md5(network.passcode)
	var/datum/netrun_external_entity_access_cursor/cursor = allocate(/datum/netrun_external_entity_access_cursor, fixture.client, entity.console)
	network.passcode = "rotated-scope-fixture"
	var/list/grant = json_decode(cursor.node_grant_json(fixture.client, scene.source.node.address, NETRUN_ACCESS_USER, scope))
	TEST_ASSERT_EQUAL(grant["scope_key_epoch"], old_stamp, "An old scope keeps its original key stamp")
	TEST_ASSERT_NOTEQUAL(grant["scope_key_epoch"], md5(network.passcode), "Export cannot launder a revoked scope into current authority")
	TEST_ASSERT(istext(grant["scope_node_epoch"]), "Epochs are canonical strings, never float wire counters")
	TEST_ASSERT_EQUAL(netrun_external_entity_codes_json(null, TRUE), "null", "Null ANY requirements preserve native object fallback")
	TEST_ASSERT_EQUAL(netrun_external_entity_codes_json(list(), TRUE), "\[\]", "Empty ANY requirements remain an explicit empty requirement")
	var/list/first = fixture.client.entity_network_key(network)
	TEST_ASSERT_EQUAL(first["generation"], fixture.client.entity_network_key(network)["generation"], "A live domain keeps its generation")
	var/datum/netrun_network/replacement = allocate(/datum/netrun_network, "raw-scope-fixture")
	TEST_ASSERT_NOTEQUAL(fixture.client.entity_network_key(replacement)["generation"], first["generation"], "Recycled LAN ids do not reuse native authority generations")
	TEST_ASSERT(cursor.advance(1) <= 1, "Export obeys its per-call record budget")
	fixture.client.binding_epoch = "replacement-binding"
	cursor.advance(1)
	TEST_ASSERT_EQUAL(cursor.error, "entity_access_changed", "A partial old-binding export is never submitted")
