/// Clock и native ABI изолированы; монитор не требует процесса Host или настоящего socket.
/datum/netrun_external_core/recovery_fixture/monitor
	var/monitor_clock = 1000

/datum/netrun_external_core/recovery_fixture/monitor/monitor_now()
	return monitor_clock

/datum/unit_test/proc/netrun_monitor_fixture()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/monitor/core = new(worker)
	worker.external_core = core
	core.world_epoch = "monitor-world"
	core.engine_epoch = "monitor-engine"
	core.binding_epoch = "monitor-binding"
	core.state = "ready"
	core.ready = TRUE
	core.monitoring_negotiated = TRUE
	core.opened_at = 1000
	return core

/datum/unit_test/proc/netrun_monitor_frame(datum/netrun_external_core/core, sequence = "1")
	return list("kind" = "monitor", "world_epoch" = core.world_epoch, "engine_epoch" = core.engine_epoch, "binding_epoch" = core.binding_epoch, "sample_sequence" = sequence, "host_metrics" = list("sync_state" = "Ready", "applied_sequence" = "0", "uptime_ms" = 2000, "node_count" = 0, "managed_bytes" = 1048576, "apply_us" = 250, "pump_us" = 750))

/// Heartbeat не подтверждает facts/outputs и не снимает native authority barrier.
/datum/unit_test/netrun_library_monitor_independent_telemetry/Run()
	var/datum/netrun_external_core/recovery_fixture/monitor/core = netrun_monitor_fixture()
	core.session_token = "monitor-token-must-stay-private"
	core.sent_input_sequence = "1"
	core.inflight_frames["1"] = list("started_at" = 1000, "bytes" = 64, "fact_through" = "1")
	core.fact_tail = "1"
	core.fact_acknowledged = "0"
	var/list/frame = netrun_monitor_frame(core)
	var/list/metrics = frame["host_metrics"]
	metrics["applied_sequence"] = "1"
	metrics["graph_version"] = "18446744073709551615"
	metrics["unexpected_payload"] = core.session_token
	TEST_ASSERT(core.process_frame(json_encode(frame)), "A negotiated monitor frame must be accepted")
	TEST_ASSERT_EQUAL(core.ack_output_sequence, "0", "Telemetry must not consume application output sequence")
	TEST_ASSERT_EQUAL(core.last_applied_sequence, "0", "Telemetry must not acknowledge accepted input")
	TEST_ASSERT_EQUAL(core.fact_acknowledged, "0", "Telemetry must not open the native causal gate")
	TEST_ASSERT_EQUAL(length(core.inflight_frames), 1, "Only application output may retire an inflight ledger entry")
	TEST_ASSERT_EQUAL(core.native_calls, 0, "Receiving telemetry must not call the native ABI")
	TEST_ASSERT_EQUAL(core.host_metrics["graph_version"], "18446744073709551615", "Diagnostic identities must retain decimal precision")
	TEST_ASSERT_EQUAL(core.host_apply_ms, 0.25, "Host microseconds must be converted to milliseconds")
	TEST_ASSERT(!("unexpected_payload" in core.host_metrics), "Only whitelisted scalar metrics may be retained")
	TEST_ASSERT(core.process_frame(json_encode(frame)), "A repeated sample is harmless")
	TEST_ASSERT_EQUAL(core.monitor_sample_sequence, "1", "Repeated sample must not manufacture progress")
	var/datum/controller/subsystem/netrun/worker = core.owner
	var/list/report = worker.library_monitor_snapshot()
	TEST_ASSERT(netrun_statistics_values_only(report), "Reports cannot hold Core, contexts, weakrefs or endpoints")
	TEST_ASSERT(!findtext(json_encode(report), core.session_token), "Token must never reach monitor UI data")
	TEST_ASSERT_EQUAL(core.native_calls, 0, "Reading the monitor must not launch bridge I/O")
	TEST_ASSERT(core.update_host_metrics(list("apply_us" = 500)), "Sparse output metrics must still work")
	TEST_ASSERT_EQUAL(core.host_metrics["sync_state"], "Ready", "Sparse output must not erase independent telemetry")
	core.update_host_metrics(list("working_set_bytes" = 2048, "process_cpu_ms" = 1000, "uptime_ms" = 2000))
	core.update_host_metrics(list("process_cpu_ms" = 2000, "uptime_ms" = 4000))
	TEST_ASSERT_EQUAL(core.host_metrics["process_cpu_percent"], 50, "CPU utilisation must derive from two process CPU/wall samples")
	core.update_host_metrics(list("working_set_bytes" = null, "process_cpu_ms" = null, "uptime_ms" = 6000))
	TEST_ASSERT_NULL(core.host_metrics["working_set_bytes"], "An explicit unavailable OS metric must clear its previous sample")
	TEST_ASSERT_NULL(core.host_metrics["process_cpu_percent"], "Unknown process CPU cannot be presented as current utilisation")

/// Staleness — только диагностика; idle Core не переподключается из-за открытого окна.
/datum/unit_test/netrun_library_monitor_health_and_staleness/Run()
	var/datum/netrun_external_core/recovery_fixture/monitor/core = netrun_monitor_fixture()
	var/datum/controller/subsystem/netrun/worker = core.owner
	TEST_ASSERT(core.process_frame(json_encode(netrun_monitor_frame(core))), "Fixture telemetry must be valid")
	var/list/report = worker.library_monitor_snapshot()
	var/list/status = report["status"]
	TEST_ASSERT_EQUAL(status["health"], "ok", "Fresh ready Core must report healthy")
	core.monitor_clock += 11 SECONDS
	report = worker.library_monitor_snapshot()
	status = report["status"]
	TEST_ASSERT_EQUAL(status["health"], "stale", "No heartbeat for 11 seconds must be visible")
	TEST_ASSERT_EQUAL(status["telemetry_age_s"], 11, "Freshness must use elapsed physical time")
	TEST_ASSERT_EQUAL(core.state, "ready", "Diagnostic freshness must not close the connection")
	TEST_ASSERT_EQUAL(core.native_calls, 0, "An idle monitor cannot initiate native work")
	var/list/output = list("kind" = "output", "world_epoch" = core.world_epoch, "engine_epoch" = core.engine_epoch, "binding_epoch" = core.binding_epoch, "output_sequence" = "1", "applied_sequence" = "0", "results" = list())
	TEST_ASSERT(core.process_frame(json_encode(output)), "A real output must continue to prove Host liveness")
	report = worker.library_monitor_snapshot()
	status = report["status"]
	TEST_ASSERT_EQUAL(status["health"], "ok", "Fresh application output must avoid false stale alarms when telemetry is skipped behind busy writer")
	TEST_ASSERT_EQUAL(status["telemetry_age_s"], 11, "The UI must still show the actual full-telemetry age")
	core.monitoring_negotiated = FALSE
	report = worker.library_monitor_snapshot()
	status = report["status"]
	TEST_ASSERT_EQUAL(status["health"], "ok", "Unsupported monitoring must not look like a dead Host")
	TEST_ASSERT(!status["telemetry_supported"], "Unsupported capability must be explicit")
	core.monitoring_negotiated = TRUE
	core.monitor_clock = 5
	core.last_host_monitor_at = 863995
	report = worker.library_monitor_snapshot()
	status = report["status"]
	TEST_ASSERT_EQUAL(status["telemetry_age_s"], 1, "A single midnight rollover must not produce negative or huge freshness")

/// Неверный binding/metrics не становится свежим успешным снимком.
/datum/unit_test/netrun_library_monitor_invalid_samples/Run()
	var/datum/netrun_external_core/recovery_fixture/monitor/core = netrun_monitor_fixture()
	var/list/frame = netrun_monitor_frame(core)
	var/list/metrics = frame["host_metrics"]
	metrics["managed_bytes"] = -1
	TEST_ASSERT(core.process_frame(json_encode(frame)), "Malformed optional telemetry does not close a healthy transport")
	TEST_ASSERT_NULL(core.last_error, "Optional diagnostic errors are counted without a transport failure")
	TEST_ASSERT_EQUAL(core.monitor_invalid_samples, 1, "Malformed scalar sample is counted")
	TEST_ASSERT(core.ready, "A bad diagnostic sample does not revoke transport readiness")
	TEST_ASSERT_EQUAL(core.monitor_sample_sequence, "0", "Invalid metric must not advance sample sequence")
	TEST_ASSERT_EQUAL(length(core.host_metrics), 0, "Partial validation must not publish a partial sample")
	TEST_ASSERT(core.process_frame(json_encode(netrun_monitor_frame(core, "2"))), "A later valid sample recovers without a new binding")
	TEST_ASSERT_EQUAL(core.monitor_sample_sequence, "2", "Only the valid complete sample is published")
	TEST_ASSERT_EQUAL(core.host_metrics["managed_bytes"], 1048576, "Invalid negative memory cannot leak into a recovered sample")
	core = netrun_monitor_fixture()
	frame = netrun_monitor_frame(core)
	frame["binding_epoch"] = "previous-binding"
	TEST_ASSERT(!core.process_frame(json_encode(frame)), "Telemetry from another binding must be rejected")
	TEST_ASSERT_EQUAL(core.last_error, "monitor_epoch_mismatch", "Cross-binding telemetry must have a safe error code")
	TEST_ASSERT_EQUAL(core.ack_output_sequence, "0", "Malformed telemetry must not consume application output")

/// История имеет постоянный размер и не возвращает собственные mutable списки.
/datum/unit_test/netrun_library_monitor_history_and_read_only/Run()
	var/datum/netrun_external_core/recovery_fixture/monitor/core = netrun_monitor_fixture()
	core.sample_library_monitor()
	for(var/index in 1 to 70)
		core.monitor_clock += 2 SECONDS
		core.sent_bytes += 2048
		core.received_bytes += 4096
		core.sample_library_monitor()
	TEST_ASSERT_EQUAL(length(core.library_monitor_history), 60, "Repeated sampling must retain at most 60 value snapshots")
	var/list/last = core.library_monitor_history[60]
	TEST_ASSERT_EQUAL(last["tx_kib_s"], 1, "TX rate must be bytes divided by elapsed seconds")
	TEST_ASSERT_EQUAL(last["rx_kib_s"], 2, "RX rate must be bytes divided by elapsed seconds")
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = core.owner
	var/list/report = worker.library_monitor_snapshot()
	var/list/history = report["history"]
	var/list/sample = history[60]
	sample["tx_kib_s"] = 999
	history.Cut()
	TEST_ASSERT_EQUAL(last["tx_kib_s"], 1, "UI cannot mutate retained history")
	TEST_ASSERT_EQUAL(length(core.library_monitor_history), 60, "UI cannot clear retained history")
	TEST_ASSERT_EQUAL(worker.config_reads + worker.token_reads + core.native_calls, 0, "Monitoring cannot read config/token or call native code")
	TEST_ASSERT(netrun_statistics_values_only(report), "All diagnostics must remain values-only")
