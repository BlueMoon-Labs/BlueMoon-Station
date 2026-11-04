/// Opt-in adapter: Core (ConsoleSessionWorld) owns console-session state. DM publishes raw session facts
/// (operator/origin/workspace/lock) through `console_configure` and renders the resulting projection. This is
/// the first (additive/shadow) slice of the console→CORE migration: the DM console still computes ui_data
/// locally; the Core projection is merged in as `core_session` without replacing anything. Later increments
/// cut over panels, route ui_act intents to Core and add Core-derived fields (connection/access/routes).

/datum/netrun_console
	var/datum/netrun_external_console_session/external_console_session

/datum/netrun_external_effects/machines/queries
	var/list/console_proxies = list()
	var/list/console_generations = list()

/proc/netrun_external_console_key_valid(list/key)
	return islist(key) && length(key) == 2 && istext(key["session_id"]) && length(key["session_id"]) && length(key["session_id"]) <= 128 && netrun_external_valid_decimal(key["generation"])

/proc/netrun_external_console_key_same(list/first, list/second)
	return netrun_external_console_key_valid(first) && netrun_external_console_key_valid(second) && first["session_id"] == second["session_id"] && first["generation"] == second["generation"]

/proc/netrun_external_console_key_json(list/key)
	return netrun_external_console_key_valid(key) ? netrun_external_json_object(list("session_id" = json_encode(key["session_id"]), "generation" = json_encode(key["generation"]))) : null

/// Explicit opt-in. Identity carries no REF; a reconnect uses a new binding and generation.
/datum/netrun_external_core/proc/console_session(datum/netrun_console/console, create = FALSE)
	if(QDELETED(console) || !ready || !istype(effects, /datum/netrun_external_effects/machines/queries))
		return null
	var/datum/netrun_external_console_session/proxy = console.external_console_session
	if(proxy?.binding == binding_epoch && proxy.connected)
		return proxy
	if(!create)
		return null
	QDEL_NULL(proxy)
	proxy = new(src, console)
	console.external_console_session = proxy
	return proxy

/// One live session proxy. `view` is a Core read model, not a second mutable owner of session state.
/datum/netrun_external_console_session
	var/datum/weakref/client_ref
	var/datum/weakref/console_ref
	var/binding
	var/list/session_key
	var/connected = TRUE
	var/configured = FALSE
	var/configure_requested = FALSE
	var/revision = "0"
	var/last_base
	var/last_workspace
	var/list/view

/datum/netrun_external_console_session/New(datum/netrun_external_core/client, datum/netrun_console/console)
	client_ref = WEAKREF(client)
	console_ref = WEAKREF(console)
	binding = client.binding_epoch
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	var/id = client.entity_access_identity(console)
	var/generation = netrun_external_decimal_next(executor.console_generations[id] || "0")
	executor.console_generations[id] = generation
	session_key = list("session_id" = id, "generation" = generation)
	executor.console_proxies[id] = WEAKREF(src)

/datum/netrun_external_console_session/Destroy()
	var/datum/netrun_console/console = console_ref?.resolve()
	if(console && console.external_console_session == src)
		console.external_console_session = null
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(istype(executor))
		var/datum/weakref/reference = executor.console_proxies[session_key?["session_id"]]
		if(IS_WEAKREF_OF(src, reference))
			executor.console_proxies -= session_key["session_id"]
		if(connected && (configured || configure_requested) && binding == client.binding_epoch && !executor.closed && !executor.query_disconnecting)
			var/id = executor.new_query_id("console")
			if(id)
				var/raw = netrun_external_json_object(list("kind" = json_encode("console_remove"), "request_id" = json_encode(id), "session" = netrun_external_console_key_json(session_key)))
				executor.enqueue_query("console_remove", raw, executor)
	connected = FALSE
	client_ref = null
	console_ref = null
	session_key = null
	view = null
	return ..()

/// Текущие сырые факты сессии или null, если оператора/подключения ещё нет.
/datum/netrun_external_console_session/proc/session_facts()
	var/datum/netrun_console/console = console_ref?.resolve()
	var/datum/netrun_external_core/client = client_ref?.resolve()
	if(QDELETED(console) || QDELETED(client) || QDELETED(console.operator) || binding != client.binding_epoch || !client.ready)
		return null
	var/operator_id = client.entity_access_identity(console.operator)
	if(!operator_id)
		return null
	var/locked = console.is_locked()
	return list("operator_id" = operator_id, "origin" = "[console.origin]", "workspace" = console.workspace_view || "terminal",
		"connection" = console.connection?.jack, "locked" = locked, "lock_until_ds" = locked ? clamp(round(console.intrusion.lockout_until), 0, 2147483647) : 0,
		"trace" = clamp(round(console.intrusion.trace), 0, 2147483647))

/// UI→CORE синхронизация по изменению: смена рабочей области — лёгкое намерение console_set_workspace,
/// изменение прочих фактов (operator/origin/lock) или первая конфигурация — полный console_configure.
/// UI-поллинг без изменений ничего не шлёт.
/datum/netrun_external_console_session/proc/refresh()
	if(!connected)
		return
	var/list/facts = session_facts()
	if(!facts)
		return
	var/base = "[facts["operator_id"]]|[facts["origin"]]|[facts["connection"]?.address]|[facts["locked"]]|[facts["lock_until_ds"]]|[facts["trace"]]"
	if(base != last_base || !(configured || configure_requested))
		publish_configure(facts, base)
	else if(facts["workspace"] != last_workspace)
		publish_workspace(facts["workspace"])

/// Полная публикация фактов сессии (первичная и при изменении operator/origin/lock).
/datum/netrun_external_console_session/proc/publish_configure(list/facts, base)
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(QDELETED(executor) || executor.closed || executor.query_disconnecting)
		return
	var/id = executor.new_query_id("console")
	if(!id)
		return
	revision = netrun_external_decimal_next(revision)
	if(!revision)
		return
	var/fact_json = netrun_external_json_object(list(
		"session" = netrun_external_console_key_json(session_key),
		"revision" = json_encode(revision),
		"operator_id" = json_encode(facts["operator_id"]),
		"origin" = json_encode(facts["origin"]),
		"workspace" = json_encode(facts["workspace"]),
		"connection" = facts["connection"] ? (client.entity_access_node_json(facts["connection"]) || "null") : "null",
		"locked" = netrun_external_json_bool(facts["locked"]),
		"lock_until_ds" = json_encode(facts["lock_until_ds"]),
		"trace" = json_encode(facts["trace"])))
	var/raw = netrun_external_json_object(list("kind" = json_encode("console_configure"), "request_id" = json_encode(id), "fact" = fact_json))
	if(executor.enqueue_query("console_configure", raw, src))
		configure_requested = TRUE
		last_base = base
		last_workspace = facts["workspace"]

/// UI→CORE намерение смены рабочей области: лёгкое, без переиздания всех фактов. Core владеет workspace.
/datum/netrun_external_console_session/proc/publish_workspace(workspace)
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(QDELETED(executor) || executor.closed || executor.query_disconnecting)
		return
	var/id = executor.new_query_id("console")
	if(!id)
		return
	var/raw = netrun_external_json_object(list("kind" = json_encode("console_set_workspace"), "request_id" = json_encode(id), "session" = netrun_external_console_key_json(session_key), "workspace" = json_encode(workspace)))
	if(executor.enqueue_query("console_set_workspace", raw, src))
		last_workspace = workspace

/// Неизменяемая проекция Core; DM её только отображает (блок core_session в ui_data).
/datum/netrun_external_console_session/proc/apply_view(datum/netrun_external_core/client, list/next, code)
	if(!connected || binding != client.binding_epoch)
		return FALSE
	if(isnull(next))
		configured = FALSE
		configure_requested = FALSE
		view = null
		return TRUE
	if(!islist(next) || !netrun_external_console_key_same(next["session"], session_key) || !netrun_external_valid_decimal(next["revision"]))
		return FALSE
	configured = TRUE
	configure_requested = FALSE
	view = next.Copy()
	return TRUE

/datum/netrun_external_effects/machines/queries/proc/console_proxy_for(list/key)
	if(!netrun_external_console_key_valid(key))
		return null
	var/datum/weakref/reference = console_proxies[key["session_id"]]
	var/datum/netrun_external_console_session/proxy = reference?.resolve()
	return proxy && netrun_external_console_key_same(proxy.session_key, key) ? proxy : null

/datum/netrun_external_effects/machines/queries/proc/observe_console(datum/netrun_external_core/client, list/result, datum/netrun_external_query_command/command)
	var/list/admission = result["admission"]
	var/datum/netrun_external_console_session/proxy = command.consumer?.resolve()
	if(istype(proxy) && !(admission?["status"] in list("accepted", "duplicate")))
		forget_query(command.request_id)
		if(!proxy.configured)
			proxy.configure_requested = FALSE

/datum/netrun_external_effects/machines/queries/proc/process_console_completed(datum/netrun_external_core/client, list/result)
	if(length(result) != 7 || !known_query_id(result["request_id"]) || !netrun_external_console_key_valid(result["session"]) || !(result["accepted"] == TRUE || result["accepted"] == FALSE) || !istext(result["code"]))
		return FALSE
	var/datum/netrun_external_console_session/proxy = console_proxy_for(result["session"])
	return QDELETED(proxy) ? TRUE : proxy.apply_view(client, result["view"], result["code"])

/datum/netrun_external_effects/machines/queries/proc/disconnect_console_sessions()
	for(var/id in console_proxies)
		var/datum/weakref/reference = console_proxies[id]
		var/datum/netrun_external_console_session/proxy = reference?.resolve()
		if(proxy)
			proxy.connected = FALSE
			proxy.configured = FALSE
			proxy.view = null
	console_proxies.Cut()
	console_generations.Cut()
