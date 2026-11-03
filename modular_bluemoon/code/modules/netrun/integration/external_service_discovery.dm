/// Асинхронный C# lookup сохраняет штатную burst/coalescing/fanout семантику native messages.
/datum/netrun_machine_resolution/external
	/// Один запрос за generation resolution; wire IDs и binding не проходят через float.
	var/external_request_id
	var/external_binding
	var/external_phase = "idle"
	/// Ограниченная выборка identities; native фильтрация исполняется отдельными worker slices.
	var/list/external_keys = list()
	var/list/external_seen = list()
	var/external_cursor = 1
	/// Read-only каталог камеры удерживает weak результаты, а не игровые сервисы.
	var/catalog_only = FALSE
	var/catalog_key
	var/catalog_until = 0
	var/list/catalog_refs = list()
	var/catalog_graph
	var/catalog_availability
	var/filtering_running = FALSE

/// Отмена continuation не отменяет уже переданные transport messages.
/datum/netrun_machine_resolution/external/Destroy()
	var/datum/netrun_external_effects/machines/queries/executor = SSnetrun.external_core?.effects
	if(istype(executor) && external_request_id)
		executor.forget_query(external_request_id, external_phase == "pending" ? "service_discovery_cancel" : null)
	external_keys = null
	external_seen = null
	catalog_refs = null
	return ..()

/// Никакого native route lookup: Host получает полную bounded выборку до domain select_targets.
/datum/netrun_machine_resolution/external/proc/submit_external()
	var/datum/netrun_external_core/client = SSnetrun.external_core
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(!client?.ready || !istype(executor) || QDELETED(source) || QDELETED(source.host))
		return FALSE
	var/list/source_key = client.service_key(source)
	if(!source_key)
		return FALSE
	external_request_id = executor.new_query_id("discovery")
	if(!external_request_id)
		return FALSE
	external_binding = client.binding_epoch
	var/communications = netrun_communication_policy(source, destination_id)
	var/body = netrun_external_json_object(list("kind" = json_encode("service_discover"), "request_id" = json_encode(external_request_id), "source" = executor.service_json(source_key), "destination_family" = json_encode(destination_id), "recipient_tag" = json_encode(recipient_tag), "communications" = netrun_external_json_bool(communications), "frequency" = "null", "max_results" = "2147483647"))
	if(!executor.enqueue_query("service_discover", body, src))
		external_request_id = null
		return FALSE
	external_phase = "pending"
	return TRUE

/// Доменный отказ планирует обычную worker continuation, не вызывает native callbacks из JSON decoder.
/datum/netrun_machine_resolution/external/proc/external_failed(reason)
	failure_reason = reason
	external_phase = "failed"
	queue_delivery()

/// Native matches/select_targets сохраняют игровые права; геометрия и достижимость уже проверены C#.
/datum/netrun_machine_resolution/external/deliver()
	set waitfor = FALSE
	cancel_delivery()
	if(external_phase == "failed")
		qdel(src)
		return TRUE
	if(!SSnetrun.get_machine_transport().is_ready())
		SSnetrun.get_machine_transport().waiting_resolutions[WEAKREF(src)] = TRUE
		return FALSE
	if(external_phase == "idle")
		if(!submit_external())
			external_failed("Очередь поиска служб заполнена")
		return FALSE
	if(external_phase == "pending" || external_phase == "cached")
		return FALSE
	if(external_phase == "filtering")
		if(filtering_running)
			return FALSE
		var/datum/netrun_external_core/client = SSnetrun.external_core
		if(client?.binding_epoch != external_binding || QDELETED(source))
			external_failed("Подключение к сети изменилось")
			return FALSE
		if(!resolved_targets)
			resolved_targets = list()
		filtering_running = TRUE
		var/started = TICK_USAGE
		var/started_at = world.time
		var/budget = SSnetrun.remaining_task_budget_ms(SSnetrun.get_execution_limits().min_budget_ms)
		while(external_cursor <= length(external_keys))
			CHECK_TICK
			if(QDELETED(src))
				return FALSE
			if(client.binding_epoch != external_binding || QDELETED(source))
				filtering_running = FALSE
				external_failed("Подключение к сети изменилось")
				return FALSE
			var/list/key = external_keys[external_cursor++]
			var/datum/netrun_machine_service/target = client.resolve_service(key["service_id"], key["generation"])
			if(!QDELETED(target) && target.service_id == destination_id && target.matches(source, recipient_tag) && target.resolve_node()?.is_online())
				resolved_targets += target
			if(QDELETED(src))
				return FALSE
			if(budget != INFINITY && (world.time != started_at || TICK_DELTA_TO_MS(TICK_USAGE - started) >= budget))
				break
		filtering_running = FALSE
		if(external_cursor <= length(external_keys))
			queue_delivery()
			return FALSE
		external_keys.Cut()
		external_seen.Cut()
		resolved_targets = source.select_targets(destination_id, resolved_targets)
		if(QDELETED(src))
			return FALSE
		completed = TRUE
		external_phase = "dispatch"
		if(source.resolutions[query_key] == src)
			source.resolutions -= query_key
		if(catalog_only)
			for(var/datum/netrun_machine_service/target as anything in resolved_targets)
				if(!QDELETED(target))
					catalog_refs += WEAKREF(target)
			resolved_targets.Cut()
			external_phase = "cached"
			catalog_until = world.time + 1 SECONDS
			var/datum/netrun_external_effects/machines/queries/executor = client.effects
			catalog_graph = executor.discovery_infrastructure
			catalog_availability = executor.discovery_transit_availability
			SStgui.update_uis(source.host)
			return TRUE
	// Базовый fanout получает только уже отобранные native targets.
	return ..()

/// Directory pages и read-only camera caches делят bounded dispatcher с projection queries.
/datum/netrun_external_effects/machines/queries
	/// Только подсказки текущей публикации, не source of authority для machine effects.
	var/discovery_infrastructure
	var/discovery_transit_availability
	/// Не более 64 read-only catalog continuations; FIFO eviction отменяет pending lookup.
	var/list/discovery_catalogs = list()

/// Admission отказ не превращается в пустой успешный broadcast.
/datum/netrun_external_effects/machines/queries/proc/observe_discovery(datum/netrun_external_core/client, list/result, datum/netrun_external_query_command/command)
	if(!command)
		discovery_infrastructure = result["infra_stamp"]
		discovery_transit_availability = result["av_infra_stamp"]
		return
	var/datum/netrun_machine_resolution/external/query = command.consumer?.resolve()
	if(QDELETED(query) || get_query_consumer(command.request_id) != query)
		return
	var/list/admission = result["admission"]
	if(!(admission?["status"] in list("accepted", "duplicate")))
		forget_query(command.request_id)
		query.external_failed("Поиск службы временно недоступен")

/// До 64 identities за страницу; принимаются только точные live поколения, terminal truncation считается отказом.
/datum/netrun_external_effects/machines/queries/proc/process_discovery(datum/netrun_external_core/client, list/result)
	var/datum/netrun_machine_resolution/external/query = get_query_consumer(result["request_id"])
	var/list/keys = result["candidates"]
	if(!istype(query) || query.external_binding != client.binding_epoch || query.external_phase != "pending" || length(result) != 6 || !islist(keys) || length(keys) > 64 || !(result["complete"] == TRUE || result["complete"] == FALSE) || !(result["code"] in list("page", "completed", "truncated", "cancelled", "source_unavailable", "routing_unavailable")))
		return FALSE
	if((!result["complete"] && result["code"] != "page") || (result["complete"] && result["code"] == "page"))
		return FALSE
	for(var/list/key as anything in keys)
		if(!islist(key) || length(key) != 2 || !istext(key["service_id"]) || length(key["service_id"]) > 128 || !netrun_external_valid_decimal(key["generation"]))
			return FALSE
		var/identity = "[key["service_id"]]:[key["generation"]]"
		if(query.external_seen[identity])
			return FALSE
		query.external_seen[identity] = TRUE
		query.external_keys += list(key)
	if(result["complete"])
		forget_query(result["request_id"])
		if(result["code"] != "completed")
			query.external_failed("Не удалось получить полный список служб")
		else
			query.external_phase = "filtering"
			query.queue_delivery()
	return TRUE

/// Каталог возвращает только наблюдение; все реальные сообщения повторно проходят native и C# transport проверки.
/datum/netrun_external_effects/machines/queries/proc/discovery_lookup(datum/netrun_machine_service/source, destination_id, recipient_tag)
	var/datum/netrun_external_core/client = owner.external_core
	if(!client?.ready)
		return list()
	var/key = json_encode(list(source.service_key(), destination_id, recipient_tag))
	var/datum/netrun_machine_resolution/external/query = discovery_catalogs[key]
	if(QDELETED(query))
		discovery_catalogs -= key
		query = null
	if(query && (QDELETED(source) || query.external_binding != client.binding_epoch || (query.external_phase == "cached" && (query.catalog_until <= world.time || query.catalog_graph != discovery_infrastructure || query.catalog_availability != discovery_transit_availability))))
		discovery_catalogs -= key
		qdel(query)
		query = null
	if(!query)
		while(length(discovery_catalogs) >= 64)
			var/oldest = discovery_catalogs[1]
			qdel(discovery_catalogs[oldest])
			discovery_catalogs -= oldest
		query = new(source, destination_id, recipient_tag)
		query.catalog_only = TRUE
		query.catalog_key = key
		discovery_catalogs[key] = query
		query.begin()
	var/list/targets = list()
	if(query.external_phase == "cached")
		for(var/datum/weakref/reference as anything in query.catalog_refs)
			var/datum/netrun_machine_service/target = reference.resolve()
			if(!QDELETED(target) && target.matches(source, recipient_tag) && target.resolve_node()?.is_online())
				targets += target
	return targets

/// Все ожидающие bursts получают известный отказ; кеши не переживают binding.
/datum/netrun_external_effects/machines/queries/proc/disconnect_discovery(datum/netrun_external_core/client, reason)
	for(var/id in query_consumers.Copy())
		var/datum/netrun_machine_resolution/external/query = get_query_consumer(id)
		if(istype(query))
			query.failure_reason = "Связь с сетевым ядром потеряна"
			qdel(query)
	for(var/key in discovery_catalogs.Copy())
		qdel(discovery_catalogs[key])
	discovery_catalogs.Cut()
	discovery_infrastructure = null
	discovery_transit_availability = null
