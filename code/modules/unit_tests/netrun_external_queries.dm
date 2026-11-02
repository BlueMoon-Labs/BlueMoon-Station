/// Изолирует dispatcher от автоматических UI projection запросов; IPC остаётся fake client.
/datum/netrun_external_effects/machines/queries/fixture/prepare_projection(datum/netrun_external_core/client)
	return FALSE
/datum/netrun_external_effects/machines/queries/fixture/prepare_backbone(datum/netrun_external_core/client)
	return FALSE
/datum/netrun_external_effects/machines/queries/fixture/observe_projection(datum/netrun_external_core/client, list/result, datum/netrun_external_query_command/command)
	return
/datum/netrun_external_effects/machines/queries/fixture/disconnect_projection(datum/netrun_external_core/client, reason)
	return

/// Один hermetic executor без глобального переключения SSnetrun и без внешних процессов.
/datum/netrun_external_query_fixture
	var/datum/controller/subsystem/netrun/external_fixture/worker
	var/datum/netrun_external_core/fixture/client
	var/datum/netrun_external_effects/machines/queries/fixture/executor
/datum/netrun_external_query_fixture/New()
	worker = new
	worker.external_configuration_checked = TRUE
	worker.external_mode = "external"
	client = new(worker)
	worker.external_core = client
	client.world_epoch = "query-world"
	client.engine_epoch = "query-engine"
	client.binding_epoch = "query-binding"
	client.state = "ready"
	client.ready = TRUE
	executor = new(worker)
	client.effects = executor
/datum/netrun_external_query_fixture/Destroy()
	client.close("fixture_cleanup")
	QDEL_NULL(client)
	QDEL_NULL(executor)
	worker.external_core = null
	QDEL_NULL(worker)
	return ..()

/// Discovery/projection не обходят causal journal; semantic retry сохраняет прежний immutable command.
/datum/unit_test/netrun_external_queries_causal_retry/Run()
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/datum/consumer = allocate(/datum)
	var/id = fixture.executor.new_query_id("projection")
	var/body = netrun_external_json_object(list("kind" = json_encode("projection_query"), "request_id" = json_encode(id)))
	fixture.client.queue_fact("{}")
	TEST_ASSERT(fixture.executor.enqueue_query("projection_query", body, consumer), "A locally allocated read-only query owns one slot")
	TEST_ASSERT(!fixture.executor.prepare_input(fixture.client), "Query cannot overtake native world changes")
	fixture.client.send_journal(1, FALSE)
	fixture.client.pending_frame = null
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Drained journal permits a query")
	var/first_sequence = fixture.client.pending_sequence
	fixture.executor.observe_result(fixture.client, list("input_sequence" = first_sequence, "admission" = list("status" = "would_block")))
	fixture.client.pending_frame = null
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Capacity pressure retains the query for another input sequence")
	TEST_ASSERT(fixture.client.pending_sequence != first_sequence, "Domain identity is independent from outer sequence")
	var/list/retry = json_decode(fixture.client.sent_entries[length(fixture.client.sent_entries)])
	TEST_ASSERT_EQUAL(json_encode(retry[1]), json_encode(json_decode(body)), "Retry keeps exactly the same logical query")
	TEST_ASSERT_EQUAL(fixture.client.native_calls, 0, "The test never loads a native DLL")

/// Непрерывные более новые facts не требуют тихого окна для уже поставленной logical команды.
/datum/unit_test/netrun_external_queries_fact_prefix_under_churn/Run()
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/datum/consumer = allocate(/datum)
	fixture.client.queue_fact("{}")
	var/id = fixture.executor.new_query_id("projection")
	var/body = netrun_external_json_object(list("kind" = json_encode("projection_query"), "request_id" = json_encode(id)))
	TEST_ASSERT(fixture.executor.enqueue_query("projection_query", body, consumer), "Query captures its preceding fact prefix")
	TEST_ASSERT(!fixture.executor.prepare_input(fixture.client), "Prior facts still fence the query")
	fixture.client.send_journal(1, FALSE)
	TEST_ASSERT(!fixture.executor.prepare_input(fixture.client), "Bridge enqueue alone is not application ACK")
	fixture.client.pending_frame = null
	fixture.client.queue_fact("{}")
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "A newer unrelated fact cannot starve an older causal command")
	TEST_ASSERT(fixture.client.journal_head <= length(fixture.client.journal), "Newer facts remain queued behind the command")

/// Cancel до admission убирает локальную работу; после handoff нужен отдельный Host cancel.
/datum/unit_test/netrun_external_queries_cancel_and_late_page/Run()
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/datum/consumer = allocate(/datum)
	var/id = fixture.executor.new_query_id("projection")
	var/body = netrun_external_json_object(list("kind" = json_encode("projection_query"), "request_id" = json_encode(id)))
	TEST_ASSERT(fixture.executor.enqueue_query("projection_query", body, consumer), "Queued query is admitted locally")
	fixture.executor.forget_query(id, "projection_cancel")
	TEST_ASSERT_EQUAL(length(fixture.executor.query_commands), 0, "A never-sent query needs no wire cancel")
	id = fixture.executor.new_query_id("projection")
	body = netrun_external_json_object(list("kind" = json_encode("projection_query"), "request_id" = json_encode(id)))
	TEST_ASSERT(fixture.executor.enqueue_query("projection_query", body, consumer), "Second identity is independent")
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Second query crosses input handoff")
	fixture.executor.forget_query(id, "projection_cancel")
	TEST_ASSERT_EQUAL(length(fixture.executor.query_commands), 1, "A handed-off query retains a bounded cancel command")
	TEST_ASSERT(fixture.executor.process_result(fixture.client, list("kind" = "projection_page", "binding_epoch" = fixture.client.binding_epoch, "request_id" = id)), "A late cancelled read-only page is consumed without native effects")
	TEST_ASSERT(!fixture.executor.process_result(fixture.client, list("kind" = "projection_page", "binding_epoch" = fixture.client.binding_epoch, "request_id" = "projection:999")), "An unknown query identity does not receive an ACK")

/// Удаление native consumer не подменяет explicit terminal page ACK.
/datum/unit_test/netrun_external_queries_retired_stream_ack/Run()
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/datum/consumer = allocate(/datum)
	var/id = fixture.executor.new_query_id("projection")
	var/body = netrun_external_json_object(list("kind" = json_encode("graph_sync_start"), "request_id" = json_encode(id)))
	TEST_ASSERT(fixture.executor.enqueue_query("graph_sync_start", body, consumer), "A stream owns one persistent continuation")
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Stream start crosses handoff")
	fixture.client.pending_frame = null
	fixture.executor.forget_query(id, "graph_sync_cancel")
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Cancel crosses handoff after local consumer removal")
	fixture.client.pending_frame = null
	TEST_ASSERT(fixture.executor.process_result(fixture.client, list("kind" = "graph_sync_page", "binding_epoch" = fixture.client.binding_epoch, "request_id" = id, "page_index" = "2")), "Retired stream still acknowledges its terminal page")
	TEST_ASSERT_EQUAL(length(fixture.executor.control_commands), 1, "A detached bounded page ACK releases the Core stream slot")
	var/datum/netrun_external_command/ack = fixture.executor.control_commands[1]
	var/list/decoded = json_decode(ack.raw_json)
	TEST_ASSERT_EQUAL(decoded["kind"], "graph_sync_continue", "Socket output ACK alone is not a stream application ACK")
	TEST_ASSERT_EQUAL(decoded["page_index"], "2", "The exact terminal page is acknowledged")

/// Cached каталог — наблюдение: unrelated movement/input backlog не делает UI бесконечно пустым.
/datum/unit_test/netrun_external_queries_catalog_under_leaf_churn/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/datum/netrun_machine_resolution/external/query = new(scene.source, "transport.fixture", null)
	query.catalog_only = TRUE
	query.external_binding = fixture.client.binding_epoch
	query.external_phase = "cached"
	query.catalog_graph = "1"
	query.catalog_availability = "1"
	query.catalog_until = world.time + 1 SECONDS
	query.catalog_refs += WEAKREF(scene.target)
	var/key = json_encode(list(scene.source.service_key(), "transport.fixture", null))
	fixture.executor.discovery_catalogs[key] = query
	fixture.executor.observe_discovery(fixture.client, list("graph_version" = "999", "infra_stamp" = "1", "av_infra_stamp" = "1"), null)
	fixture.client.pending_frame = "pending newer facts"
	fixture.client.queue_fact("{}")
	var/list/targets = fixture.executor.discovery_lookup(scene.source, "transport.fixture", null)
	TEST_ASSERT_EQUAL(length(targets), 1, "Unrelated graph generations do not starve read-only catalog observations")
	TEST_ASSERT_EQUAL(targets[1], scene.target, "Live native matching still filters cached weak identities")
	TEST_ASSERT_EQUAL(length(fixture.executor.query_commands), 0, "A still-current observation does not allocate another query")

/// Query producers и continuation capacity не определяются произвольным wire input.
/datum/unit_test/netrun_external_queries_identity_and_bounds/Run()
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/datum/consumer = allocate(/datum)
	TEST_ASSERT_NULL(fixture.executor.new_query_id("unbounded-native-owner"), "Only fixed producers create watermarks")
	TEST_ASSERT(!fixture.executor.enqueue_query("projection_query", "{\"kind\":\"projection_query\",\"request_id\":\"projection:1\"}", consumer), "A caller cannot forge an unallocated ID")
	for(var/index in 1 to 256)
		var/id = fixture.executor.new_query_id("projection")
		var/body = netrun_external_json_object(list("kind" = json_encode("projection_query"), "request_id" = json_encode(id)))
		TEST_ASSERT(fixture.executor.enqueue_query("projection_query", body, consumer), "The fixed capacity accepts exactly its bounded slots")
	var/overflow = fixture.executor.new_query_id("projection")
	var/body = netrun_external_json_object(list("kind" = json_encode("projection_query"), "request_id" = json_encode(overflow)))
	TEST_ASSERT(!fixture.executor.enqueue_query("projection_query", body, consumer), "Capacity pressure does not create another continuation")
	TEST_ASSERT_EQUAL(length(fixture.executor.query_consumers), 256, "Registry memory remains bounded")

/// Частичные discovery pages не вызывают native matches/receive, а неполный broadcast завершается отказом.
/datum/unit_test/netrun_external_queries_discovery_staging/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_query_fixture/fixture = allocate(/datum/netrun_external_query_fixture)
	var/datum/netrun_machine_resolution/external/query = allocate(/datum/netrun_machine_resolution/external, scene.source, "fixture.family", null)
	query.external_request_id = fixture.executor.new_query_id("discovery")
	query.external_binding = fixture.client.binding_epoch
	query.external_phase = "pending"
	var/body = netrun_external_json_object(list("kind" = json_encode("service_discover"), "request_id" = json_encode(query.external_request_id)))
	TEST_ASSERT(fixture.executor.enqueue_query("service_discover", body, query), "Discovery cursor is registered")
	var/list/page = list("kind" = "discovery_page", "binding_epoch" = fixture.client.binding_epoch, "request_id" = query.external_request_id, "candidates" = list(list("service_id" = "service-1", "generation" = "1")), "complete" = FALSE, "code" = "page")
	TEST_ASSERT(fixture.executor.process_result(fixture.client, page), "One bounded page is staged")
	TEST_ASSERT_EQUAL(query.external_phase, "pending", "Partial results do not publish targets")
	TEST_ASSERT_NULL(query.resolved_targets, "No native selection runs inside output decoding")
	TEST_ASSERT(!fixture.executor.process_result(fixture.client, page), "A repeated candidate identity in another page is rejected")
	page["candidates"] = list()
	page["complete"] = TRUE
	page["code"] = "truncated"
	TEST_ASSERT(fixture.executor.process_result(fixture.client, page), "Explicit truncation is a known domain outcome")
	TEST_ASSERT_EQUAL(query.external_phase, "failed", "Truncation cannot dispatch an arbitrary partial broadcast")
	TEST_ASSERT_NULL(fixture.executor.get_query_consumer(query.external_request_id), "Terminal result releases the continuation slot")
