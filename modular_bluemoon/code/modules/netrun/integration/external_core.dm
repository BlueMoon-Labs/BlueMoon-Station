/// Canonical decimal-string arithmetic: идентификаторы и wire-счётчики не проходят через DM float.
/proc/netrun_external_decimal_next(value)
	if(!netrun_external_valid_decimal(value, TRUE) || netrun_external_decimal_compare(value, "18446744073709551615") >= 0)
		return null
	var/result = ""
	var/carry = TRUE
	for(var/index = length(value), index >= 1, index--)
		var/digit = text2ascii(value, index) - 48
		if(digit < 0 || digit > 9)
			return null
		if(carry)
			digit++
			carry = digit == 10
			if(carry)
				digit = 0
		result = "[ascii2text(48 + digit)][result]"
	return carry ? "1[result]" : result

/// Сравнивает неотрицательные canonical decimal строки без преобразования в число.
/proc/netrun_external_decimal_compare(first, second)
	if(length(first) != length(second))
		return length(first) < length(second) ? -1 : 1
	for(var/index in 1 to length(first))
		var/a = text2ascii(first, index)
		var/b = text2ascii(second, index)
		if(a != b)
			return a < b ? -1 : 1
	return 0

/// Проверяет wire-counter. Ноль разрешается только для ACK и journal boundaries.
/proc/netrun_external_valid_decimal(value, allow_zero = FALSE)
	if(!istext(value) || !length(value) || length(value) > 20)
		return FALSE
	if(value == "0")
		return allow_zero
	if(copytext(value, 1, 2) == "0")
		return FALSE
	for(var/index in 1 to length(value))
		var/digit = text2ascii(value, index)
		if(digit < 48 || digit > 57)
			return FALSE
	return netrun_external_decimal_compare(value, "18446744073709551615") <= 0

/// Сохраняет только bounded ASCII diagnostic token, никогда произвольный payload или текст исключения.
/proc/netrun_external_safe_code(value, fallback = "host_rejected")
	if(!istext(value) || !length(value) || length(value) > 64)
		return fallback
	for(var/index in 1 to length(value))
		var/code = text2ascii(value, index)
		if(!((code >= 65 && code <= 90) || (code >= 97 && code <= 122) || (code >= 48 && code <= 57) || code == 95 || code == 46 || code == 45))
			return fallback
	return value

/// DM TRUE/FALSE числовые; wire-схема требует настоящие JSON booleans.
/proc/netrun_external_json_bool(value)
	return value ? "true" : "false"

/// timeofday остаётся точно представимым DM float; один rollover покрывает короткие физические watchdog deadlines.
/proc/netrun_external_elapsed_since(start)
	var/now = world.timeofday
	return (now < start ? now + 864000 : now) - start

/// Собирает объект из уже сериализованных значений; значения никогда не интерпретируются как код.
/proc/netrun_external_json_object(list/fields)
	var/list/parts = list()
	for(var/key in fields)
		parts += "[json_encode(key)]:[fields[key]]"
	return "{[jointext(parts, ",")]}"

/// Явный массив сохраняет [] даже при пустом DM list и не меняет вложенную форму payload.
/proc/netrun_external_json_array(list/records)
	return "\[" + jointext(records, ",") + "\]"

/// Доверенная точка расширения native effects. Неизвестное событие не получает output ACK.
/datum/netrun_external_effects/proc/process_result(datum/netrun_external_core/client, list/result)
	return FALSE

/// Доверенный builder команд вызывается только после фактов: без I/O, yield и native effects.
/datum/netrun_external_effects/proc/prepare_input(datum/netrun_external_core/client)
	return FALSE

/// Admission/action является результатом команды, отдельным от transport completion и output ACK.
/datum/netrun_external_effects/proc/observe_result(datum/netrun_external_core/client, list/result)
	return

/// Владельцы logical requests классифицируют потерю связи до очистки source identity maps.
/datum/netrun_external_effects/proc/disconnected(datum/netrun_external_core/client, reason)
	return

/// Последовательный DM client: raw facts → bounded snapshot/journal → native bridge → локальный Host.
/datum/netrun_external_core
	/// Владелец исходных реестров; сетевой граф и маршруты для экспорта не запрашиваются.
	var/datum/controller/subsystem/netrun/owner
	/// Настроенная локальная библиотека и port; token поступает только из доверенного аргумента open.
	var/library_path
	var/endpoint_port
	var/session_token
	/// Идентичность мира сохраняется при resync; binding меняется при каждом новом open.
	var/world_epoch
	var/engine_epoch
	var/binding_epoch
	/// Внешний статус: ready дополнительно требует опубликованный graph, не только mirror.
	var/state = "closed"
	var/ready = FALSE
	var/last_error
	/// Исполнитель effects поставляется владельцем; exporter сам не вызывает машинные обработчики.
	var/datum/netrun_external_effects/effects
	/// Close/Destroy уведомляют исполнитель один раз за binding, включая reentrant cleanup.
	var/effects_disconnected = FALSE
	/// Monotonic opaque IDs и независимые input/output/journal counters.
	var/id_serial = "0"
	var/input_sequence = "0"
	var/ack_output_sequence = "0"
	var/last_applied_sequence = "0"
	var/journal_sequence = "0"
	/// Одно неизменяемое input-тело удерживается до application ACK, а не только bridge accepted.
	var/pending_frame
	var/pending_sequence
	var/pending_sent = FALSE
	var/poll_outstanding = FALSE
	/// Физические watchdog deadlines не зависят от продвижения игрового времени Host.
	var/opened_at = 0
	var/pending_started_at = 0
	/// Точное последнее игровое время; регресс требует новой сессии.
	var/last_simulation_time = 0
	/// Снимок обходится по живым реестрам; удаления просмотренных записей корректируют cursor.
	var/snapshot_id
	var/snapshot_phase
	var/node_cursor = 1
	var/service_cursor = 1
	var/chunk_index = "0"
	var/snapshot_record_count = "0"
	var/snapshot_chain
	var/list/scanned_nodes = list()
	var/list/scanned_services = list()
	var/list/snapshot_sectors = list()
	var/list/snapshot_buffer = list()
	/// Метаданные по datum identity не попадают на wire; обратные lookup используют weakrefs.
	var/list/node_metadata = list()
	var/list/nodes_by_id = list()
	var/list/service_metadata = list()
	var/list/services_by_id = list()
	var/list/services_by_node = list()
	var/list/area_ids = list()
	var/list/sector_metadata = list()
	/// Не более4096 native Z принадлежат одному известному connected stack; geometry change требует fresh binding.
	var/list/sector_by_z = list()
	/// Журнал хранит immutable JSON records; удаление никогда не coalesce-ится или не теряется.
	var/list/journal = list()
	/// Parallel opaque keys и O(1) индекс последнего unsent upsert; JSON payload не разбирается.
	var/list/journal_keys = list()
	var/list/journal_upserts = list()
	/// Logical command capture закрывает предыдущую epoch, сохраняя immutable причинный prefix.
	var/coalescing_epoch = "0"
	var/journal_head = 1
	var/journal_characters = 0
	var/journal_limit = 4096
	/// Causal prefix не требует глобально пустого журнала: новые unrelated facts не вытесняют команды.
	var/fact_tail = "0"
	var/fact_consumed = "0"
	/// Подтверждение именно Host Apply; popped/bridge accepted сами по себе не снимают native authority fence.
	var/fact_acknowledged = "0"
	var/pending_fact_through
	/// Последний факт о forwarder/секторе/native port, ещё требующий application ACK.
	var/infrastructure_barrier = "0"
	/// Bounded fingerprint окно завершённых output frames защищает native effects от replay.
	var/list/output_hashes = list()
	var/list/output_order = list()

/// Подписки не запускают IPC и не изменяют мир; initial scan начнётся только после hello_ack.
/datum/netrun_external_core/New(datum/controller/subsystem/netrun/source_owner = SSnetrun)
	owner = source_owner
	RegisterSignal(owner, COMSIG_NETRUN_NODE_REGISTERED, PROC_REF(on_node_registered))
	RegisterSignal(owner, COMSIG_NETRUN_NODE_UNREGISTERED, PROC_REF(on_node_unregistered))
	RegisterSignal(owner, COMSIG_NETRUN_NODE_MOVED, PROC_REF(on_node_moved))
	RegisterSignal(owner, COMSIG_NETRUN_NODE_CHANGED, PROC_REF(on_node_changed))
	return ..()

/// Отзывает source subscriptions и просит worker завершиться; ABI close не блокирует поток BYOND.
/datum/netrun_external_core/Destroy()
	close("destroyed")
	UnregisterSignal(owner, list(COMSIG_NETRUN_NODE_REGISTERED, COMSIG_NETRUN_NODE_UNREGISTERED, COMSIG_NETRUN_NODE_MOVED, COMSIG_NETRUN_NODE_CHANGED))
	owner = null
	return ..()

/// Token передаёт доверенный startup-код из ignored file; world.params для самого секрета не используется.
/datum/netrun_external_core/proc/open(bridge_library, port, token, world_id = null)
	if(state != "closed" && state != "resync_required")
		return FALSE
	if(!istext(token) || length(token) < 32 || length(token) > 256 || !istext(bridge_library) || !length(bridge_library))
		last_error = "invalid_configuration"
		return FALSE
	for(var/index in 1 to length(token))
		var/character = text2ascii(token, index)
		if(character < 33 || character > 126)
			last_error = "invalid_configuration"
			return FALSE
	library_path = bridge_library
	effects_disconnected = FALSE
	endpoint_port = "[port]"
	session_token = token
	world_epoch = world_id || world_epoch || rustg_generate_uuid_v4()
	binding_epoch = rustg_generate_uuid_v4()
	engine_epoch = null
	input_sequence = "0"
	ack_output_sequence = "0"
	last_applied_sequence = "0"
	journal_sequence = "0"
	fact_tail = "0"
	coalescing_epoch = "0"
	fact_consumed = "0"
	fact_acknowledged = "0"
	pending_fact_through = null
	infrastructure_barrier = "0"
	id_serial = "0"
	node_cursor = 1
	service_cursor = 1
	chunk_index = "0"
	snapshot_record_count = "0"
	snapshot_chain = null
	last_simulation_time = max(0, round(world.time))
	last_error = null
	ready = FALSE
	var/list/result = native_call("netrun_open", list("127.0.0.1", endpoint_port, "64", "4194304", "1048576"))
	if(result?["code"] != "accepted")
		last_error = "bridge_open_failed"
		return FALSE
	state = "connecting"
	opened_at = world.timeofday
	return TRUE

/// Ограниченный проход. Не вызывает ensure_topology, route, service discovery или игровые effects вне output handler.
/datum/netrun_external_core/proc/tick(max_records = 32)
	if(state == "closed" || state == "resync_required")
		return
	if((state == "connecting" || state == "handshaking") && netrun_external_elapsed_since(opened_at) > 100)
		abort_session("handshake_timeout")
		return
	poll(64)
	if(state == "closed" || state == "resync_required")
		return
	if(state == "connecting")
		var/list/status = native_call("netrun_status", list())
		if(status?["state"] == "connected")
			var/hello = netrun_external_json_object(list("kind" = json_encode("hello"), "protocol_major" = "1", "protocol_minor" = "3", "world_epoch" = json_encode(world_epoch), "binding_epoch" = json_encode(binding_epoch), "token" = json_encode(session_token)))
			var/list/sent = native_call("netrun_try_enqueue", list(hello))
			if(sent?["code"] == "accepted")
				state = "handshaking"
		else if(status?["state"] == "disconnected" || status?["state"] == "closed")
			abort_session("bridge_unavailable")
		return
	if(state == "handshaking")
		return
	if(pending_frame)
		if(pending_sent && netrun_external_elapsed_since(pending_started_at) > 100)
			abort_session("host_ack_timeout")
			return
		flush_pending()
		return
	if(snapshot_phase)
		advance_snapshot(clamp(max_records, 1, 32), clamp(max_records, 1, 128))
		flush_pending()
		return
	if(ready && effects?.prepare_input(src))
		flush_pending()
		return
	if(state == "closed" || state == "resync_required")
		return
	if(journal_head <= length(journal))
		send_journal(clamp(max_records, 1, 128), FALSE)
		flush_pending()
		return
	if(!poll_outstanding)
		var/body = netrun_external_json_object(list("kind" = json_encode("poll"), "world_epoch" = json_encode(world_epoch), "engine_epoch" = json_encode(engine_epoch), "binding_epoch" = json_encode(binding_epoch), "ack_output_sequence" = json_encode(ack_output_sequence), "max_events" = "64"))
		var/list/result = native_call("netrun_try_enqueue", list(body))
		poll_outstanding = result?["code"] == "accepted"

/// Забирает ограниченное количество готовых тел; native poll сам ограничивает serialized response.
/datum/netrun_external_core/proc/poll(max_frames = 64)
	var/list/result = native_call("netrun_poll", list("[clamp(max_frames, 1, 64)]", "4194304"))
	if(!islist(result))
		return abort_session("bridge_poll_failed")
	var/list/frames = result?["frames"]
	for(var/body in frames)
		if(!process_frame(body))
			return FALSE
	if(result?["state"] == "disconnected" || result?["state"] == "closed")
		abort_session("bridge_disconnected")
		return FALSE
	return TRUE

/// Полный output подтверждается только после всех results; неизвестный effect не получает ACK.
/datum/netrun_external_core/proc/process_frame(body)
	var/list/frame
	try
		frame = json_decode(body)
	catch
		return abort_session("invalid_output")
	if(!islist(frame))
		return abort_session("invalid_output")
	if(frame["kind"] == "hello_ack")
		if(state != "handshaking" || frame["protocol_major"] != 1 || frame["protocol_minor"] != 3 || frame["world_epoch"] != world_epoch || frame["binding_epoch"] != binding_epoch || !istext(frame["engine_epoch"]) || frame["snapshot_checksum_version"] != 3)
			return abort_session("handshake_mismatch")
		engine_epoch = frame["engine_epoch"]
		session_token = null
		snapshot_id = rustg_generate_uuid_v4()
		snapshot_phase = "begin"
		state = "snapshotting"
		return TRUE
	if(frame["kind"] != "output" || frame["world_epoch"] != world_epoch || frame["engine_epoch"] != engine_epoch || frame["binding_epoch"] != binding_epoch)
		return abort_session("output_epoch_mismatch")
	var/sequence = frame["output_sequence"]
	var/applied = frame["applied_sequence"]
	if(!netrun_external_valid_decimal(sequence) || !netrun_external_valid_decimal(applied, TRUE) || netrun_external_decimal_compare(applied, input_sequence) > 0)
		return abort_session("invalid_output_sequence")
	var/hash = rustg_hash_string(RUSTG_HASH_SHA256, body)
	if(netrun_external_decimal_compare(sequence, ack_output_sequence) <= 0)
		if(output_hashes[sequence] != hash)
			return abort_session("output_replay_conflict")
		return TRUE
	if(sequence != netrun_external_decimal_next(ack_output_sequence))
		return abort_session("output_sequence_gap")
	if(netrun_external_decimal_compare(applied, last_applied_sequence) < 0)
		return abort_session("applied_sequence_regression")
	var/list/results = frame["results"]
	// Host может добавить один runtime_result к 64 transport events.
	if(!islist(results) || length(results) > 65)
		return abort_session("invalid_output")
	if(pending_sequence && pending_fact_through && netrun_external_decimal_compare(applied, pending_sequence) >= 0)
		fact_acknowledged = pending_fact_through
		pending_fact_through = null
	for(var/result in results)
		if(!islist(result))
			return abort_session("invalid_output")
		if(!handle_result(result))
			return abort_session(last_error || "unsupported_output")
		if(state == "closed" || state == "resync_required")
			return FALSE
	ack_output_sequence = sequence
	last_applied_sequence = applied
	output_hashes[sequence] = hash
	output_order += sequence
	if(length(output_order) > 64)
		output_hashes -= output_order[1]
		output_order.Cut(1, 2)
	if(pending_sequence && netrun_external_decimal_compare(applied, pending_sequence) >= 0)
		pending_frame = null
		pending_sequence = null
		pending_sent = FALSE
	poll_outstanding = FALSE
	return TRUE

/// Runtime diagnostics не исполняют effects; ready требует barrier mirror и опубликованный graph.
/datum/netrun_external_core/proc/handle_result(list/result)
	if(result["kind"] == "runtime_result")
		effects?.observe_result(src, result)
		if(state == "closed" || state == "resync_required")
			return FALSE
		if(result["status"] == "rejected" || result["status"] == "resync_required" || result["error_code"])
			last_error = netrun_external_safe_code(result["error_code"] || result["code"])
			return FALSE
		ready = result["sync_state"] == "ready" && !result["topology_pending"] && result["graph_version"] != "0" && istext(result["graph_version"])
		if(ready)
			state = "ready"
		return TRUE
	if(result["kind"] == "pressure" || result["kind"] == "diagnostics")
		return TRUE
	if(effects?.process_result(src, result))
		return TRUE
	last_error = "unsupported_output"
	return FALSE

/// Фиксирует immutable frame до первого try_enqueue; повтор не пересериализует ACK или payload.
/datum/netrun_external_core/proc/enqueue(entries_json, record_count = 1)
	if(state == "closed" || state == "resync_required" || pending_frame || !engine_epoch || record_count < 0 || record_count > 128)
		return FALSE
	var/next_sequence = netrun_external_decimal_next(input_sequence)
	var/time_ds = max(0, round(world.time))
	if(!next_sequence || time_ds < last_simulation_time || time_ds > 2147483647)
		return abort_session("clock_or_sequence_limit")
	input_sequence = next_sequence
	pending_fact_through = null
	last_simulation_time = time_ds
	var/list/envelope = list("protocol_major" = "1", "protocol_minor" = "3", "world_epoch" = json_encode(world_epoch), "engine_epoch" = json_encode(engine_epoch), "binding_epoch" = json_encode(binding_epoch), "sequence" = json_encode(input_sequence), "ack_output_sequence" = json_encode(ack_output_sequence), "simulation_time_ds" = json_encode(time_ds), "entries" = entries_json)
	pending_frame = netrun_external_json_object(envelope)
	pending_sequence = input_sequence
	pending_sent = FALSE
	return TRUE

/// Отказ квоты не меняет pending body и не создаёт новый sequence.
/datum/netrun_external_core/proc/flush_pending()
	if(!pending_frame || pending_sent)
		return
	var/list/result = native_call("netrun_try_enqueue", list(pending_frame))
	if(result?["code"] == "accepted")
		pending_sent = TRUE
		pending_started_at = world.timeofday
	else if(result?["code"] != "would_block")
		abort_session("bridge_enqueue_failed")

/// Одна фаза/один bounded chunk за проход; живые registry cursors не копируют всю станцию.
/datum/netrun_external_core/proc/advance_snapshot(max_records, max_journal_records = 128)
	if(snapshot_phase == "begin")
		snapshot_chain = rustg_hash_string(RUSTG_HASH_SHA256, "NETRUN-SNAPSHOT-3")
		var/begin = netrun_external_json_object(list("kind" = json_encode("snapshot_begin"), "snapshot_id" = json_encode(snapshot_id), "journal_sequence" = json_encode("0"), "checksum_version" = "3"))
		enqueue(netrun_external_json_array(list(begin)))
		snapshot_phase = "nodes"
		return
	var/remaining_work = max_records
	if(snapshot_phase == "nodes")
		while(node_cursor <= length(owner.nodes_by_address) && length(snapshot_buffer) < max_records && remaining_work-- > 0)
			var/address = owner.nodes_by_address[node_cursor++]
			var/datum/component/netrun_node/node = owner.nodes_by_address[address]
			if(QDELETED(node))
				continue
			scanned_nodes[node] = TRUE
			var/list/records = export_node(node, TRUE)
			snapshot_buffer += records
		if(node_cursor > length(owner.nodes_by_address))
			snapshot_phase = "services"
	if(snapshot_phase == "services")
		var/datum/netrun_machine_transport/transport = owner.get_machine_transport()
		while(service_cursor <= length(transport.services) && length(snapshot_buffer) < max_records && remaining_work-- > 0)
			var/key = transport.services[service_cursor++]
			var/datum/netrun_machine_service/service = transport.services[key]
			if(QDELETED(service))
				continue
			scanned_services[service] = TRUE
			var/record = export_service(service, TRUE)
			if(record)
				snapshot_buffer += record
		if(service_cursor > length(transport.services))
			snapshot_phase = "commit"
	if(state == "closed" || state == "resync_required")
		return
	if(length(snapshot_buffer))
		var/list/chunk = snapshot_buffer.Copy(1, min(length(snapshot_buffer), max_records) + 1)
		snapshot_buffer.Cut(1, length(chunk) + 1)
		var/raw_changes = netrun_external_json_array(chunk)
		chunk_index = netrun_external_decimal_next(chunk_index)
		for(var/unused in chunk)
			snapshot_record_count = netrun_external_decimal_next(snapshot_record_count)
		var/chunk_hash = rustg_hash_string(RUSTG_HASH_SHA256, raw_changes)
		snapshot_chain = rustg_hash_string(RUSTG_HASH_SHA256, "[snapshot_chain]|[chunk_index]|[length(chunk)]|[chunk_hash]")
		var/body = netrun_external_json_object(list("kind" = json_encode("snapshot_chunk"), "snapshot_id" = json_encode(snapshot_id), "chunk_index" = json_encode(chunk_index), "changes" = raw_changes))
		enqueue(netrun_external_json_array(list(body)))
		return
	if(snapshot_phase == "commit")
		var/body = netrun_external_json_object(list("kind" = json_encode("snapshot_commit"), "snapshot_id" = json_encode(snapshot_id), "chunk_count" = json_encode(chunk_index), "record_count" = json_encode(snapshot_record_count), "sha256" = json_encode(snapshot_chain)))
		enqueue(netrun_external_json_array(list(body)))
		snapshot_phase = "catching_up"
		state = "catching_up"
		return
	if(snapshot_phase == "catching_up")
		if(journal_head <= length(journal))
			send_journal(max_journal_records, TRUE)
			return
		var/body = netrun_external_json_object(list("kind" = json_encode("catch_up_complete"), "snapshot_id" = json_encode(snapshot_id), "through_journal_sequence" = json_encode(journal_sequence)))
		enqueue(netrun_external_json_array(list(body)))
		snapshot_phase = null

/// Передаёт последовательный кусок журнала; consumed slots освобождаются, список периодически компактируется.
/datum/netrun_external_core/proc/send_journal(max_records, catch_up)
	if(pending_frame || journal_head > length(journal))
		return FALSE
	max_records = clamp(max_records, 1, 128)
	var/list/records = list()
	var/cursor = journal_head
	var/serialized_bytes = 2
	while(cursor <= length(journal) && length(records) < max_records)
		var/record = journal[cursor]
		var/cost = length(record) + (length(records) ? 1 : 0)
		if(serialized_bytes + cost > 131072)
			if(!length(records))
				return abort_session("source_fact_size")
			break
		records += record
		serialized_bytes += cost
		cursor++
	var/accepted
	var/next_journal_sequence
	if(catch_up)
		next_journal_sequence = netrun_external_decimal_next(journal_sequence)
		if(!next_journal_sequence)
			return abort_session("source_journal_sequence_limit")
		var/body = netrun_external_json_object(list("kind" = json_encode("catch_up_delta"), "snapshot_id" = json_encode(snapshot_id), "journal_sequence" = json_encode(next_journal_sequence), "changes" = netrun_external_json_array(records)))
		accepted = enqueue(netrun_external_json_array(list(body)))
	else
		accepted = enqueue(netrun_external_json_array(records), length(records))
	if(accepted)
		if(catch_up)
			journal_sequence = next_journal_sequence
		while(journal_head < cursor)
			var/key = journal_keys[journal_head]
			var/list/upsert = journal_upserts[key]
			if(upsert && upsert["slot"] == journal_head)
				journal_upserts -= key
			journal_characters -= length(journal[journal_head])
			journal[journal_head] = null
			journal_keys[journal_head++] = null
			fact_consumed = netrun_external_decimal_next(fact_consumed)
		if(journal_head > 256 && journal_head > length(journal) / 2)
			var/removed = journal_head - 1
			journal.Cut(1, journal_head)
			journal_keys.Cut(1, journal_head)
			journal_head = 1
			for(var/key in journal_upserts)
				var/list/upsert = journal_upserts[key]
				upsert["slot"] -= removed
		pending_fact_through = fact_consumed
	return accepted

/// Закрывает O(1) epoch перед захватом logical команды; новые upserts не изменят её причинный prefix.
/datum/netrun_external_core/proc/capture_fact_barrier()
	if(state == "closed" || state == "resync_required")
		return null
	var/next = netrun_external_decimal_next(coalescing_epoch)
	if(!next)
		abort_session("source_coalescing_epoch_limit")
		return null
	coalescing_epoch = next
	return fact_tail

/// Tombstone сохраняет все прежние записи, но запрещает последующему upsert заменить состояние до удаления.
/datum/netrun_external_core/proc/invalidate_fact_key(key)
	if(istext(key))
		journal_upserts -= key

/// Churn нельзя продолжать с потерянными записями: переполнение закрывает binding вместо усечения журнала.
/datum/netrun_external_core/proc/queue_fact(record, infrastructure = FALSE, coalescing_key = null)
	if(!record || state == "closed" || state == "resync_required")
		return FALSE
	if(!isnull(coalescing_key) && (!istext(coalescing_key) || !length(coalescing_key) || length(coalescing_key) > 256))
		return abort_session("source_fact_key")
	var/is_infrastructure = infrastructure || findtext(record, "\"kind\":\"sector_", 1, 32)
	var/list/upsert = journal_upserts[coalescing_key]
	if(upsert && upsert["epoch"] == coalescing_epoch && upsert["slot"] >= journal_head && upsert["slot"] <= length(journal))
		var/slot = upsert["slot"]
		var/characters = journal_characters - length(journal[slot]) + length(record)
		if(characters > 1048576)
			return abort_session("source_journal_overflow")
		journal[slot] = record
		journal_characters = characters
		if(is_infrastructure && netrun_external_decimal_compare(upsert["serial"], infrastructure_barrier) > 0)
			infrastructure_barrier = upsert["serial"]
		return TRUE
	if(length(journal) - journal_head + 1 >= journal_limit || journal_characters + length(record) > 1048576)
		return abort_session("source_journal_overflow")
	var/next = netrun_external_decimal_next(fact_tail)
	if(!next)
		return abort_session("source_fact_sequence_limit")
	fact_tail = next
	// Собственные sector records имеют фиксированный короткий prefix; payload здесь никогда не разбирается.
	if(is_infrastructure)
		infrastructure_barrier = next
	var/was_empty = journal_head > length(journal)
	journal += record
	journal_keys.len = length(journal)
	journal_keys[length(journal)] = coalescing_key
	if(coalescing_key)
		journal_upserts[coalescing_key] = list("slot" = length(journal), "epoch" = coalescing_epoch, "serial" = next)
	journal_characters += length(record)
	if(was_empty)
		owner?.wake_ready_delivery()
	return TRUE

/// pending_frame гарантирует application ACK отправленного prefix до следующей команды.
/// Сравнение строковых serial — O(1) по числу facts/commands, без обхода живого журнала.
/datum/netrun_external_core/proc/command_facts_ready(barrier)
	if(!netrun_external_valid_decimal(barrier, TRUE))
		return FALSE
	return !pending_frame && netrun_external_decimal_compare(fact_consumed, barrier) >= 0

/// Путь native эффекта нельзя считать текущим, пока Host не применил известную нам смену transit topology.
/datum/netrun_external_core/proc/infrastructure_facts_ready()
	return netrun_external_decimal_compare(fact_acknowledged, infrastructure_barrier) >= 0

/// Только raw native роль, без обхода adjacency или вычисления маршрута.
/datum/netrun_external_core/proc/node_is_forwarder(datum/component/netrun_node/node)
	return node && (node.node_type == NETRUN_NODE_APC || istype(node.parent, /obj/machinery/ntnet_relay))

/// Точный revision текущей native инкарнации; отсутствующий key не совпадёт с wire revision.
/datum/netrun_external_core/proc/node_revision(list/key)
	var/datum/component/netrun_node/node = resolve_node(key?["id"], key?["generation"])
	var/list/metadata = node_metadata[node]
	return metadata?["revision"]

/// Выделяет ID один раз на инкарнацию компонента; REF и DM paths не являются protocol IDs.
/datum/netrun_external_core/proc/node_key(datum/component/netrun_node/node)
	if(state == "closed" || state == "resync_required" || QDELETED(node))
		return null
	var/list/metadata = node_metadata[node]
	if(!metadata)
		if(length(node_metadata) >= 10000)
			abort_session("source_node_capacity")
			return null
		id_serial = netrun_external_decimal_next(id_serial)
		metadata = list("id" = "n[id_serial]", "revision" = "0")
		node_metadata[node] = metadata
		nodes_by_id[metadata["id"]] = WEAKREF(node)
		RegisterSignal(node, COMSIG_NETRUN_NODE_CHANGED, PROC_REF(on_direct_node_changed))
	return list("id" = metadata["id"], "generation" = "1")

/// Новая identity сервиса также создаётся при перепривязке прежнего adapter datum к новому owner node.
/datum/netrun_external_core/proc/service_key(datum/netrun_machine_service/service)
	if(state == "closed" || state == "resync_required" || QDELETED(service))
		return null
	var/datum/component/netrun_node/node = service.resolve_node()
	var/list/owner_key = node_key(node)
	if(!owner_key)
		return null
	var/list/metadata = service_metadata[service]
	if(metadata && metadata["owner"] != owner_key["id"])
		forget_service(service)
		if(state == "closed" || state == "resync_required")
			return null
		metadata = null
	if(!metadata)
		if(length(service_metadata) >= 10000)
			abort_session("source_service_capacity")
			return null
		id_serial = netrun_external_decimal_next(id_serial)
		metadata = list("id" = "s[id_serial]", "revision" = "0", "owner" = owner_key["id"], "node" = node)
		service_metadata[service] = metadata
		services_by_id[metadata["id"]] = WEAKREF(service)
		var/list/bucket = services_by_node[node]
		if(!bucket)
			bucket = list()
			services_by_node[node] = bucket
		bucket |= service
		RegisterSignal(service, COMSIG_PARENT_QDELETING, PROC_REF(on_service_deleted))
	return list("id" = metadata["id"], "generation" = "1")

/// Reverse lookup всегда повторно проверяет поколение и qdel-состояние перед будущим effect handler.
/datum/netrun_external_core/proc/resolve_node(id, generation)
	if(generation != "1")
		return null
	var/datum/weakref/reference = nodes_by_id[id]
	var/datum/component/netrun_node/node = reference?.resolve()
	return QDELETED(node) ? null : node

/// Отозванный или перепривязанный сервис не разрешается по старому protocol ID.
/datum/netrun_external_core/proc/resolve_service(id, generation)
	if(generation != "1")
		return null
	var/datum/weakref/reference = services_by_id[id]
	var/datum/netrun_machine_service/service = reference?.resolve()
	return QDELETED(service) ? null : service

/// Area IDs непрозрачны и ограничены; ссылка используется только внутри DM.
/datum/netrun_external_core/proc/area_key(area/room)
	if(state == "closed" || state == "resync_required" || !room)
		return null
	if(!area_ids[room])
		if(length(area_ids) >= 10000)
			abort_session("source_area_capacity")
			return null
		id_serial = netrun_external_decimal_next(id_serial)
		area_ids[room] = "a[id_serial]"
	return area_ids[room]

/// Dependency seam исходной mapping geometry: возвращает native порядок, без topology или routing.
/datum/netrun_external_core/proc/sector_levels(z)
	return SSmapping.get_connected_levels(z)

/// Экспортирует исходный порядок; смена уже известного stack отзывает binding до смешивания overlapping floors.
/datum/netrun_external_core/proc/export_sector(turf/position, snapshot)
	if(!position)
		return null
	return export_sector_at_z(position.z, snapshot)

/// Проверяет bounded raw geometry до изменения индексов; отдельный Z entry point не требует turf в hermetic tests.
/datum/netrun_external_core/proc/export_sector_at_z(native_z, snapshot)
	if(state == "closed" || state == "resync_required")
		return null
	if(!isnum(native_z) || native_z < 1 || native_z > 4096 || round(native_z) != native_z)
		abort_session("source_sector_invalid")
		return null
	var/list/levels = sector_levels(native_z)
	if(!islist(levels) || !length(levels) || length(levels) > 4096)
		abort_session("source_sector_invalid")
		return null
	var/min_z = native_z
	var/list/seen = list()
	for(var/z in levels)
		if(!isnum(z) || z < 1 || z > 4096 || round(z) != z || seen["[z]"])
			abort_session("source_sector_invalid")
			return null
		seen["[z]"] = TRUE
		min_z = min(min_z, z)
	if(!seen["[native_z]"])
		abort_session("source_sector_invalid")
		return null
	var/id = "sector:[min_z]"
	var/raw_levels = json_encode(levels)
	var/list/metadata = sector_metadata[id]
	if(metadata && metadata["levels"] != raw_levels)
		abort_session("sector_geometry_changed")
		return null
	for(var/z in levels)
		var/known = sector_by_z["[z]"]
		if(known && known != id)
			abort_session("sector_geometry_overlap")
			return null
	var/changed = !metadata
	if(!metadata)
		if(length(sector_metadata) >= 4096)
			abort_session("source_sector_capacity")
			return null
		metadata = list("revision" = "0")
		sector_metadata[id] = metadata
		for(var/z in levels)
			sector_by_z["[z]"] = id
	if(changed)
		metadata["revision"] = netrun_external_decimal_next(metadata["revision"])
		metadata["levels"] = raw_levels
		metadata["raw"] = netrun_external_json_object(list("kind" = json_encode("sector_upsert"), "sector_id" = json_encode(id), "generation" = json_encode("1"), "sector_revision" = json_encode(metadata["revision"]), "levels" = raw_levels))
	if(snapshot)
		if(snapshot_sectors[id])
			return null
		snapshot_sectors[id] = TRUE
		return metadata["raw"]
	return changed ? metadata["raw"] : null

/// Собирает полный raw node fact из физического носителя; existing binding передаётся только как bootstrap seed.
/datum/netrun_external_core/proc/export_node(datum/component/netrun_node/node, snapshot = FALSE)
	var/list/records = list()
	var/list/key = node_key(node)
	if(!key)
		return records
	var/list/metadata = node_metadata[node]
	var/turf/position = node.physical_turf()
	var/sector_record = export_sector(position, snapshot)
	if(state == "closed" || state == "resync_required")
		return records
	if(sector_record)
		records += sector_record
	var/sector_id = position ? sector_by_z["[position.z]"] : null
	var/area/base_area = get_base_area(position)
	var/area/supplied_area = base_area
	if(istype(node.parent, /obj/machinery/power/apc))
		var/obj/machinery/power/apc/apc = node.parent
		supplied_area = apc.area || get_area(apc)
		supplied_area = supplied_area?.base_area || supplied_area
	var/relay = istype(node.parent, /obj/machinery/ntnet_relay)
	var/operational = TRUE
	if(relay)
		var/obj/machinery/ntnet_relay/relay_host = node.parent
		operational = relay_host.is_operational()
	if(!metadata["anchor_initialized"])
		metadata["anchor_initialized"] = TRUE
		var/list/anchor = node.bound_apc != node ? node_key(node.bound_apc) : null
		metadata["anchor"] = anchor ? netrun_external_json_object(list("node_id" = json_encode(anchor["id"]), "generation" = json_encode(anchor["generation"]))) : "null"
	var/raw_position = position ? netrun_external_json_object(list("x" = json_encode(position.x), "y" = json_encode(position.y), "z" = json_encode(position.z))) : "null"
	var/network = netrun_external_json_object(list("base_area_id" = json_encode(area_key(base_area)), "supplied_area_id" = json_encode(area_key(supplied_area)), "department" = json_encode(netrun_department_key(supplied_area)), "is_ntnet_relay" = netrun_external_json_bool(relay), "relay_operational" = netrun_external_json_bool(operational), "is_station_level" = netrun_external_json_bool(position && is_station_level(position.z)), "is_mining_level" = netrun_external_json_bool(position && is_mining_level(position.z)), "initial_anchor" = metadata["anchor"]))
	var/raw_state = netrun_external_json_object(list("address" = json_encode(node.address), "node_type" = json_encode(node.node_type), "position" = raw_position, "sector_id" = json_encode(sector_id), "online" = netrun_external_json_bool(node.is_online()), "network" = network))
	var/changed = metadata["state"] != raw_state
	if(changed)
		metadata["revision"] = netrun_external_decimal_next(metadata["revision"])
		metadata["state"] = raw_state
		metadata["raw"] = netrun_external_json_object(list("kind" = json_encode("node_upsert"), "node_id" = json_encode(key["id"]), "generation" = json_encode("1"), "node_revision" = json_encode(metadata["revision"]), "state" = raw_state))
	if(snapshot || changed)
		records += metadata["raw"]
	return records

/// Объявляет только безопасный generic message contract; finer native operations добавляет отдельный adapter.
/datum/netrun_external_core/proc/export_service(datum/netrun_machine_service/service, snapshot = FALSE)
	var/list/key = service_key(service)
	if(!key)
		return null
	var/list/metadata = service_metadata[service]
	var/owner_json = netrun_external_json_object(list("node_id" = json_encode(metadata["owner"]), "generation" = json_encode("1")))
	var/operations = "\[{\"operation_id\":\"message\",\"safety\":\"mutating\",\"delivery\":\"delivery_only\",\"ordered\":true}\]"
	var/list/fields = list("owner" = owner_json, "family" = json_encode(service.service_id), "tag" = json_encode(service.service_tag()), "online" = netrun_external_json_bool(!QDELETED(service.host) && service.resolve_node()?.is_online()), "operations" = operations)
	var/communication = export_communication(service)
	if(communication)
		fields["communication"] = communication
	var/content = netrun_external_json_object(fields)
	var/changed = metadata["content"] != content
	if(changed)
		metadata["revision"] = netrun_external_decimal_next(metadata["revision"])
		metadata["content"] = content
		metadata["raw"] = "{\"kind\":\"service_upsert\",\"service_id\":[json_encode(key["id"])],\"generation\":\"1\",\"service_revision\":[json_encode(metadata["revision"])],[copytext(content, 2)]"
	return snapshot || changed ? metadata["raw"] : null

/// Рекламирует только существующий hub/relay port, не создавая components, topology или обратные связи.
/datum/netrun_external_core/proc/export_communication(datum/netrun_machine_service/service)
	var/obj/machinery/telecomms/machine = service?.host
	if(service?.service_id != "telecomms.relay" || QDELETED(machine) || (!istype(machine, /obj/machinery/telecomms/hub) && !istype(machine, /obj/machinery/telecomms/relay)))
		return null
	// Усечение filter до пустого списка расширило бы доступ. Непредставимый port не получает capability.
	if(length(machine.freq_listening) > 128 || length(machine.links) > 128 || machine.z < 0 || machine.z > 4096)
		return null
	var/list/frequencies = list()
	for(var/frequency in machine.freq_listening)
		if(!isnum(frequency) || frequency <= 0 || frequency >= 2.147483648e9 || round(frequency) != frequency)
			return null
		if(!(frequency in frequencies))
			frequencies += frequency
	var/list/links = list()
	var/list/seen_nodes = list()
	for(var/obj/machinery/telecomms/linked as anything in machine.links)
		if(!istype(linked) || QDELETED(linked))
			continue
		var/datum/component/netrun_node/node = linked.GetComponent(/datum/component/netrun_node)
		if(QDELETED(node) || seen_nodes[node])
			continue
		var/list/key = node_key(node)
		if(!key)
			continue
		seen_nodes[node] = TRUE
		links += netrun_external_json_object(list("node_id" = json_encode(key["id"]), "generation" = json_encode(key["generation"])))
	var/obj/machinery/telecomms/relay/relay = istype(machine, /obj/machinery/telecomms/relay) ? machine : null
	return netrun_external_json_object(list("kind" = json_encode(relay ? "relay" : "hub"), "on" = netrun_external_json_bool(machine.on), "toggled" = netrun_external_json_bool(machine.toggled), "operational" = netrun_external_json_bool(machine.is_operational()), "native_z" = json_encode(machine.z), "long_range" = netrun_external_json_bool(machine.long_range_link), "receiving" = netrun_external_json_bool(relay?.receiving), "broadcasting" = netrun_external_json_bool(relay?.broadcasting), "listening_frequencies" = json_encode(frequencies), "configured_links" = netrun_external_json_array(links)))

/// Native setters вызывают после мутации обоих концов; существующие components не создаются повторно.
/obj/machinery/telecomms/proc/netrun_external_ports_changed()
	var/datum/netrun_external_core/client = SSnetrun?.external_core
	if(!client || client.state == "closed" || client.state == "resync_required")
		return
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(!QDELETED(node))
		client.on_node_changed(src, node)

/// Typed upsert keys берутся из собственных metadata; prefix только различает два вида own exporter records.
/datum/netrun_external_core/proc/queue_node_records(datum/component/netrun_node/node)
	var/list/records = export_node(node)
	if(state == "closed" || state == "resync_required")
		return FALSE
	var/list/metadata = node_metadata[node]
	if(!metadata)
		return FALSE
	var/turf/position = node.physical_turf()
	var/sector_id = position ? sector_by_z["[position.z]"] : null
	for(var/record in records)
		var/sector = findtext(record, "\"kind\":\"sector_", 1, 32)
		var/key = sector ? "sector:[sector_id]" : "node:[metadata["id"]]"
		if(!queue_fact(record, sector || node_is_forwarder(node), key))
			return FALSE
	return TRUE

/// Полный service upsert заменяет только unsent состояние того же opaque ID и текущей causal epoch.
/datum/netrun_external_core/proc/queue_service_record(datum/netrun_machine_service/service)
	var/record = export_service(service)
	if(state == "closed" || state == "resync_required")
		return FALSE
	if(!record)
		return TRUE
	var/list/metadata = service_metadata[service]
	return metadata && queue_fact(record, service.service_id == "telecomms.relay", "service:[metadata["id"]]")

/// Hook register/index_service вызывается владельцем transport после обновления native registry.
/datum/netrun_external_core/proc/observe_service(datum/netrun_machine_service/service)
	if(state == "closed" || state == "resync_required" || QDELETED(service))
		return
	queue_node_records(service.resolve_node())
	queue_service_record(service)

/// Отзывает service ID до удаления из registry; повтор QDELETING/unregister остаётся no-op.
/datum/netrun_external_core/proc/forget_service(datum/netrun_machine_service/service)
	var/list/metadata = service_metadata[service]
	if(!metadata)
		return
	if(snapshot_phase == "services" && scanned_services[service])
		service_cursor = max(1, service_cursor - 1)
	scanned_services -= service
	var/revision = netrun_external_decimal_next(metadata["revision"])
	invalidate_fact_key("service:[metadata["id"]]")
	queue_fact(netrun_external_json_object(list("kind" = json_encode("service_remove"), "service_id" = json_encode(metadata["id"]), "generation" = json_encode("1"), "service_revision" = json_encode(revision))), service.service_id == "telecomms.relay")
	if(state == "closed" || state == "resync_required")
		return
	UnregisterSignal(service, COMSIG_PARENT_QDELETING)
	var/list/bucket = services_by_node[metadata["node"]]
	bucket -= service
	services_by_id -= metadata["id"]
	service_metadata -= service

/// Реальный component unregister удаляет старую identity; новый компонент получит новый opaque ID.
/datum/netrun_external_core/proc/forget_node(datum/component/netrun_node/node)
	if(snapshot_phase == "nodes" && scanned_nodes[node])
		node_cursor = max(1, node_cursor - 1)
	scanned_nodes -= node
	var/list/metadata = node_metadata[node]
	if(!metadata)
		return
	var/list/bucket = services_by_node[node]
	for(var/datum/netrun_machine_service/service as anything in bucket?.Copy())
		forget_service(service)
	services_by_node -= node
	invalidate_fact_key("node:[metadata["id"]]")
	queue_fact(netrun_external_json_object(list("kind" = json_encode("node_remove"), "node_id" = json_encode(metadata["id"]), "generation" = json_encode("1"), "node_revision" = json_encode(netrun_external_decimal_next(metadata["revision"])))), node_is_forwarder(node))
	UnregisterSignal(node, COMSIG_NETRUN_NODE_CHANGED)
	nodes_by_id -= metadata["id"]
	node_metadata -= node

/// Source registration уже находится в registry; факт попадает в журнал даже до своего snapshot cursor.
/datum/netrun_external_core/proc/on_node_registered(datum/source, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	on_node_changed(source, node)

/// Source registry удаляет node перед этим сигналом; cursor компенсирует сдвиг числовых индексов.
/datum/netrun_external_core/proc/on_node_unregistered(datum/source, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	forget_node(node)

/// Movement экспортирует физические факты без синхронного join_network или route.
/datum/netrun_external_core/proc/on_node_moved(datum/source, datum/component/netrun_node/node, turf/old_position, turf/new_position)
	SIGNAL_HANDLER
	on_node_changed(source, node)

/// Глобальный сигнал покрывает ранние availability/binding изменения ещё не просмотренных узлов.
/datum/netrun_external_core/proc/on_node_changed(datum/source, datum/component/netrun_node/node, flags)
	SIGNAL_HANDLER
	if(state == "closed" || state == "resync_required" || QDELETED(node))
		return
	queue_node_records(node)
	var/list/bucket = services_by_node[node]
	for(var/datum/netrun_machine_service/service as anything in bucket)
		queue_service_record(service)

/// Прямой node signal покрывает state-only изменения, которые subsystem намеренно не ретранслирует.
/datum/netrun_external_core/proc/on_direct_node_changed(datum/source, datum/component/netrun_node/node, flags)
	SIGNAL_HANDLER
	on_node_changed(source, node, flags)

/// Дополнительный отзыв identity до native Destroy; transport hook повторно ничего не удалит.
/datum/netrun_external_core/proc/on_service_deleted(datum/netrun_machine_service/service)
	SIGNAL_HANDLER
	forget_service(service)

/// Все native ошибки превращаются в локальный safe-code; содержимое исключения не выводится.
/datum/netrun_external_core/proc/native_call(export_name, list/arguments)
	if(!library_path)
		return null
	try
		var/raw = call_ext(library_path, export_name)(arglist(arguments))
		return json_decode(raw)
	catch
		return null

/// Потеря source journal/output integrity закрывает admission; новый open обязательно создаст новый binding.
/datum/netrun_external_core/proc/abort_session(reason)
	close(reason)
	state = "resync_required"
	return FALSE

/// Закрывает native worker неблокирующе и освобождает все borrowed source subscriptions и JSON-журналы.
/datum/netrun_external_core/proc/close(reason = "closed")
	ready = FALSE
	last_error = reason
	state = "closed"
	if(!effects_disconnected)
		effects_disconnected = TRUE
		effects?.disconnected(src, reason)
	if(library_path)
		native_call("netrun_close", list())
	for(var/datum/component/netrun_node/node as anything in node_metadata)
		UnregisterSignal(node, COMSIG_NETRUN_NODE_CHANGED)
	for(var/datum/netrun_machine_service/service as anything in service_metadata)
		UnregisterSignal(service, COMSIG_PARENT_QDELETING)
	node_metadata.Cut()
	nodes_by_id.Cut()
	service_metadata.Cut()
	services_by_id.Cut()
	services_by_node.Cut()
	area_ids.Cut()
	sector_metadata.Cut()
	sector_by_z.Cut()
	scanned_nodes.Cut()
	scanned_services.Cut()
	snapshot_sectors.Cut()
	snapshot_buffer.Cut()
	journal.Cut()
	journal_keys.Cut()
	journal_upserts.Cut()
	coalescing_epoch = "0"
	journal_head = 1
	journal_characters = 0
	output_hashes.Cut()
	output_order.Cut()
	pending_frame = null
	pending_sequence = null
	pending_sent = FALSE
	poll_outstanding = FALSE
	snapshot_phase = null
	session_token = null
	state = "closed"
	if(!QDELETED(owner) && owner.external_core == src)
		owner.schedule_external_retry(reason)
