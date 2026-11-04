/// Opt-in adapter: Core (BotEngine) owns bot cognition — goals, planning, temperament, target/program
/// ranking — computed from Core graph/authority/combat/storage owners. DM supplies only raw facts through
/// `bot_configure` and renders the resulting read model.
///
/// Decision execution: navigation and combat are routed Core-side to the entity and combat owners (they reach
/// DM through the existing entity-move and combat-via-entity-view paths, not this adapter). This adapter runs
/// the native decisions Core still hands to DM: presentation (warning/store_report/incident), cancel
/// acknowledgement, and lifecycle termination (dissolve/leave_network). The remaining device-machinery
/// decisions (command/recover/recall/start_breach/sabotage) reply "uncertain" until their native execution
/// lands, which quiesces the brain without a stale action.
///
/// Requires the bot's actor to be registered first through `entity_proxy` (external_entities.dm): the brain
/// proxy reuses that actor identity and never invents a second one. Driving an opted-in bot through Core does
/// not disable the legacy DM brain.

/mob/camera/netrun_entity/bot
	var/datum/netrun_external_bot_brain_proxy/external_bot_proxy

/datum/netrun_external_effects/machines/queries
	var/list/bot_proxies = list()
	var/list/bot_generations = list()
	var/list/bot_native_pending = list()
	var/list/bot_native_known = list()
	var/list/bot_native_history = list()
	var/list/bot_native_history_order = list()
	var/bot_native_pump_binding
	var/datum/netrun_external_bot_decision/bot_native_active
	/// O(1) demand keeps the Core clock alive for idle configured brains without scanning them each tick.
	var/bot_clock_demand = 0

/proc/netrun_external_bot_key_valid(list/key)
	return islist(key) && length(key) == 2 && istext(key["bot_id"]) && length(key["bot_id"]) && length(key["bot_id"]) <= 128 && netrun_external_valid_decimal(key["generation"])

/proc/netrun_external_bot_key_same(list/first, list/second)
	return netrun_external_bot_key_valid(first) && netrun_external_bot_key_valid(second) && first["bot_id"] == second["bot_id"] && first["generation"] == second["generation"]

/proc/netrun_external_bot_key_json(list/key)
	return netrun_external_bot_key_valid(key) ? netrun_external_json_object(list("bot_id" = json_encode(key["bot_id"]), "generation" = json_encode(key["generation"]))) : null

/// Explicit opt-in. Identity carries no REF; a reused bot id requires a higher generation; a reconnect never
/// reuses a binding. The actor must already be a registered Core entity so Core can read its live residence.
/datum/netrun_external_core/proc/bot_proxy(mob/camera/netrun_entity/bot/bot, create = FALSE)
	if(QDELETED(bot) || !ready || !istype(effects, /datum/netrun_external_effects/machines/queries))
		return null
	var/datum/netrun_external_bot_brain_proxy/proxy = bot.external_bot_proxy
	if(proxy?.binding == binding_epoch && proxy.connected)
		return proxy
	if(!create)
		return null
	QDEL_NULL(proxy)
	var/datum/netrun_external_entity_proxy/actor = bot.external_entity_proxy
	if(QDELETED(actor) || !actor.registered || actor.binding != binding_epoch || !netrun_external_entity_actor_valid(actor.actor_key))
		return null
	proxy = new(src, bot, actor)
	bot.external_bot_proxy = proxy
	return proxy

/// One live brain. `view` is a Core read model, not a second planner or a mutable fallback.
/datum/netrun_external_bot_brain_proxy
	var/datum/weakref/client_ref
	var/datum/weakref/bot_ref
	var/binding
	var/list/bot_key
	var/list/actor_key
	var/connected = TRUE
	var/configured = FALSE
	var/configure_requested = FALSE
	var/clock_accounted = FALSE
	var/last_code
	var/list/view
	var/last_decision_serial = "0"

/datum/netrun_external_bot_brain_proxy/New(datum/netrun_external_core/client, mob/camera/netrun_entity/bot/bot, datum/netrun_external_entity_proxy/actor)
	client_ref = WEAKREF(client)
	bot_ref = WEAKREF(bot)
	binding = client.binding_epoch
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	var/id = actor.actor_key["actor_id"]
	var/generation = netrun_external_decimal_next(executor.bot_generations[id] || "0")
	executor.bot_generations[id] = generation
	bot_key = list("bot_id" = id, "generation" = generation)
	actor_key = actor.actor_key.Copy()
	executor.bot_proxies[id] = WEAKREF(src)
	RegisterSignal(bot, COMSIG_PARENT_QDELETING, PROC_REF(on_native_deleted))

/datum/netrun_external_bot_brain_proxy/Destroy()
	set_clock_demand(FALSE)
	var/mob/camera/netrun_entity/bot/bot = bot_ref?.resolve()
	if(bot)
		UnregisterSignal(bot, COMSIG_PARENT_QDELETING)
		if(bot.external_bot_proxy == src)
			bot.external_bot_proxy = null
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(istype(executor))
		var/datum/weakref/reference = executor.bot_proxies[bot_key?["bot_id"]]
		if(IS_WEAKREF_OF(src, reference))
			executor.bot_proxies -= bot_key["bot_id"]
		if(connected && (configured || configure_requested) && binding == client.binding_epoch)
			send_command(executor, "bot_remove", null, executor)
	connected = FALSE
	client_ref = null
	bot_ref = null
	bot_key = null
	actor_key = null
	view = null
	return ..()

/// Counter moves only on lifecycle edges; repeated configure/teardown cannot leak clock demand.
/datum/netrun_external_bot_brain_proxy/proc/set_clock_demand(enabled)
	if(clock_accounted == enabled)
		return
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(istype(executor) && binding == client.binding_epoch)
		executor.bot_clock_demand = max(0, executor.bot_clock_demand + (enabled ? 1 : -1))
	clock_accounted = enabled

/// Closed typed command bodies only; never a DM proc path or raw executable payload.
/datum/netrun_external_bot_brain_proxy/proc/send_command(datum/netrun_external_effects/machines/queries/executor, kind, body_json, datum/consumer = src)
	if(QDELETED(executor) || executor.closed || executor.query_disconnecting)
		return null
	var/id = executor.new_query_id("bot")
	if(!id)
		return null
	var/list/fields = list("kind" = json_encode(kind), "request_id" = json_encode(id), "bot" = netrun_external_bot_key_json(bot_key))
	if(body_json)
		fields += body_json
	if(!executor.enqueue_query(kind, netrun_external_json_object(fields), consumer))
		return null
	return id

/// Публикует сырые идентичности/credentials из текущих фактов; Core сам строит восприятие. Общий код для
/// первичной конфигурации и для повторной отправки (reconfigure) при изменении инвентаря/прав.
/datum/netrun_external_bot_brain_proxy/proc/send_configure()
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/mob/camera/netrun_entity/bot/bot = bot_ref?.resolve()
	var/datum/netrun_external_entity_proxy/actor = bot?.external_entity_proxy
	if(QDELETED(client) || QDELETED(bot) || QDELETED(bot.console) || QDELETED(bot.host_node) || binding != client.binding_epoch || !client.ready)
		return null
	if(QDELETED(actor) || !actor.registered || !netrun_external_entity_actor_same(actor.actor_key, actor_key))
		return null
	var/raw_access = client.entity_access_json(bot.console)
	var/home = client.entity_access_node_json(bot.host_node)
	if(!raw_access || !home)
		return null
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	var/id = executor.new_query_id("bot")
	if(!id)
		return null
	// owner/inventory/behavior stay null until the owner-actor and storage seams land; Core then uses the
	// program defaults and treats the brain as autonomous. console/goals remain enabled.
	var/configuration = netrun_external_json_object(list(
		"bot" = netrun_external_bot_key_json(bot_key),
		"actor" = netrun_external_entity_actor_json(actor_key),
		"program_id" = json_encode(bot.bot_kind),
		"access" = raw_access,
		"home" = home,
		"owner" = "null",
		"inventory" = "null",
		"behavior" = "null",
		"console_available" = netrun_external_json_bool(TRUE),
		"goals_enabled" = netrun_external_json_bool(TRUE)))
	var/raw = netrun_external_json_object(list("kind" = json_encode("bot_configure"), "request_id" = json_encode(id), "configuration" = configuration))
	return executor.enqueue_query("bot_configure", raw, src) ? id : null

/// Initial configure. Также подписывается на изменение инвентаря/прав консоли, чтобы заново отправить факты
/// после выданного ключа взлома, подобранного файла и т.п. — иначе восприятие Core осталось бы со старым доступом.
/datum/netrun_external_bot_brain_proxy/proc/configure()
	if(configured || configure_requested)
		return null
	var/id = send_configure()
	if(!id)
		return null
	configure_requested = TRUE
	set_clock_demand(TRUE)
	var/mob/camera/netrun_entity/bot/bot = bot_ref?.resolve()
	if(!QDELETED(bot?.console?.inventory))
		RegisterSignal(bot.console.inventory, COMSIG_NETRUN_INVENTORY_CHANGED, PROC_REF(on_facts_changed), TRUE)
	return id

/// Инвентарь/права изменились (ключ после взлома, подобранный файл): обновляем факты в Core вне стека сигнала,
/// коалесцируя частые изменения одним отложенным reconfigure.
/datum/netrun_external_bot_brain_proxy/proc/on_facts_changed(datum/source)
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(reconfigure)), 1, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_DELETE_ME)

/// Повторная отправка фактов: Core пересобирает восприятие с текущими credentials (напр. выданным ключом).
/datum/netrun_external_bot_brain_proxy/proc/reconfigure()
	if(connected && (configured || configure_requested))
		send_configure()

/// Shared FIFO wake; repeated signals coalesce in Core. Never an inline think.
/datum/netrun_external_bot_brain_proxy/proc/wake()
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(!configured || QDELETED(executor))
		return null
	return send_command(executor, "bot_wake", null)

/datum/netrun_external_bot_brain_proxy/proc/on_native_deleted(datum/source)
	SIGNAL_HANDLER
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if((configured || configure_requested) && istype(executor))
		send_command(executor, "bot_remove", null, executor)
	set_clock_demand(FALSE)
	connected = FALSE
	configured = FALSE
	bot_ref = null
	qdel(src)

/// Immutable Core projection of the brain. It never becomes a second mutable owner of goals or state.
/datum/netrun_external_bot_brain_proxy/proc/apply_view(datum/netrun_external_core/client, list/next, code)
	if(!connected || binding != client.binding_epoch)
		return FALSE
	last_code = netrun_external_safe_code(code, "bot_completed")
	if(isnull(next))
		set_clock_demand(FALSE)
		configured = FALSE
		configure_requested = FALSE
		view = null
		return TRUE
	if(!islist(next) || !netrun_external_bot_key_same(next["bot"], bot_key) || !netrun_external_entity_actor_valid(next["actor"]) || !netrun_external_valid_decimal(next["revision"]))
		return FALSE
	configured = TRUE
	configure_requested = FALSE
	set_clock_demand(TRUE)
	view = next.Copy()
	return TRUE

/datum/netrun_external_effects/machines/queries/proc/bot_proxy_for(list/key)
	if(!netrun_external_bot_key_valid(key))
		return null
	var/datum/weakref/reference = bot_proxies[key["bot_id"]]
	var/datum/netrun_external_bot_brain_proxy/proxy = reference?.resolve()
	return proxy && netrun_external_bot_key_same(proxy.bot_key, key) ? proxy : null

/// Admission ACK for a brain command. A rejected configure releases its clock demand and request slot.
/datum/netrun_external_effects/machines/queries/proc/observe_bot(datum/netrun_external_core/client, list/result, datum/netrun_external_query_command/command)
	var/list/admission = result["admission"]
	var/datum/netrun_external_bot_brain_proxy/proxy = command.consumer?.resolve()
	if(istype(proxy) && !(admission?["status"] in list("accepted", "duplicate")))
		proxy.last_code = netrun_external_safe_code(admission?["code"], "bot_rejected")
		forget_query(command.request_id)
		if(!proxy.configured)
			proxy.configure_requested = FALSE
			proxy.set_clock_demand(FALSE)

/// `bot_completed` carries the brain read model and the admission/configure outcome.
/datum/netrun_external_effects/machines/queries/proc/process_bot_completed(datum/netrun_external_core/client, list/result)
	if(length(result) != 7 || !known_query_id(result["request_id"]) || !netrun_external_bot_key_valid(result["bot"]) || !(result["accepted"] == TRUE || result["accepted"] == FALSE) || !istext(result["code"]))
		return FALSE
	var/datum/netrun_external_bot_brain_proxy/proxy = bot_proxy_for(result["bot"])
	if(QDELETED(proxy))
		return TRUE
	return proxy.apply_view(client, result["view"], result["code"])

/// Decoder only stages at most one bounded native decision. Presentation and the result reply run in a
/// separate cooperative pump, never on the IPC reader stack.
/datum/netrun_external_effects/machines/queries/proc/process_bot_native_decision(datum/netrun_external_core/client, list/result)
	if(length(result) != 4)
		return FALSE
	var/list/effect = result["effect"]
	if(!islist(effect) || !netrun_external_bot_key_valid(effect["bot"]) || !netrun_external_entity_actor_valid(effect["actor"]) || !netrun_external_valid_decimal(effect["action_serial"]) || !netrun_external_valid_decimal(effect["expected_revision"]) || !netrun_external_valid_decimal(effect["residence_revision"]))
		return FALSE
	var/list/action = effect["action"]
	if(!islist(action) || !istext(action["kind"]))
		return FALSE
	var/list/decision_bot = effect["bot"]
	var/token = "[decision_bot["bot_id"]]:[effect["action_serial"]]"
	if(bot_native_known[token])
		return TRUE
	var/datum/netrun_external_bot_decision/context = new
	context.binding = client.binding_epoch
	context.bot_key = decision_bot.Copy()
	context.actor_key = effect["actor"].Copy()
	context.action_serial = effect["action_serial"]
	context.expected_revision = effect["expected_revision"]
	context.kind = action["kind"]
	context.data = islist(action["data"]) ? action["data"].Copy() : null
	context.token = token
	var/datum/netrun_external_bot_brain_proxy/proxy = bot_proxy_for(context.bot_key)
	if(bot_native_history[token])
		context.finished = TRUE
		context.phase = bot_native_history[token]
	else if(!proxy || netrun_external_decimal_compare(context.action_serial, proxy.last_decision_serial) <= 0)
		context.finished = TRUE
		context.phase = "rejected"
	else
		proxy.last_decision_serial = context.action_serial
	bot_native_known[token] = TRUE
	bot_native_pending += context
	owner.wake_ready_delivery()
	return TRUE

/// One handed-off native decision. DM runs presentation (warning/store_report/incident), cancel ack,
/// lifecycle (dissolve/leave_network) and device actions (command/recover via the console API). The remaining
/// machinery decisions (recall/start_breach/sabotage) reply "uncertain": Core keeps authority, the brain
/// quiesces on AwaitFactRevision until its next fact, and no stale action is applied or retried blindly.
/datum/netrun_external_bot_decision
	var/binding
	var/list/bot_key
	var/list/actor_key
	var/action_serial
	var/expected_revision
	var/kind
	/// Сериализованные данные действия (snake_case) для device-решений: node/command_id/nonce/file_uid.
	var/list/data
	var/token
	var/finished = FALSE
	var/phase = "completed"

/datum/netrun_external_bot_decision/proc/execute(datum/netrun_external_core/client, datum/netrun_external_effects/machines/queries/executor)
	if(!finished)
		var/datum/netrun_external_bot_brain_proxy/proxy = executor.bot_proxy_for(bot_key)
		var/mob/camera/netrun_entity/bot/bot = proxy?.bot_ref?.resolve()
		if(binding == client.binding_epoch && proxy?.connected && proxy.binding == binding && !QDELETED(bot))
			switch(kind)
				if("warning")
					bot.host_node?.network?.add_log("Процесс [bot.real_name]: предупреждение Core.")
					phase = "completed"
				if("store_report")
					bot.host_node?.network?.add_log("Процесс [bot.real_name]: отчёт зафиксирован Core.")
					phase = "completed"
				if("incident")
					bot.host_node?.network?.add_log("Процесс [bot.real_name]: инцидент зафиксирован Core.")
					phase = "completed"
				if("cancel_action")
					phase = "completed"
				if("dissolve")
					bot.dissolve()
					phase = "completed"
				if("leave_network")
					bot.retire()
					phase = "completed"
				if("command")
					var/list/node_key = data?["node"]
					var/datum/component/netrun_node/node = node_key ? client.resolve_node(node_key["node_id"], node_key["generation"]) : null
					phase = (node && data && !QDELETED(bot.console) && bot.console.run_command(node, data["command_id"], data["nonce"])) ? "completed" : "rejected"
				if("recover")
					phase = (data && !QDELETED(bot.console) && istext(data["file_uid"]) && bot.console.recover_salvage(data["file_uid"])) ? "completed" : "rejected"
				if("start_breach")
					// Старт взлома фронтира (kind=network/node, id). При успехе выданный ключ меняет инвентарь
					// → on_facts_changed → reconfigure → Core видит доступ и hack-цель завершается.
					phase = (data && !QDELETED(bot.console) && bot.console.start_breach(data["kind"], data["target_id"], TRUE)) ? "completed" : "rejected"
				else
					// recall/sabotage: исполнение через игровую машинерию ещё не подключено (recall нужен
					// Core-маршрут возврата; sabotage — отдельная APC-машинерия). "uncertain" тихо гасит brain
					// без устаревшего действия. navigate/combat сюда не приходят — их исполняют владельцы Core.
					phase = "uncertain"
		else
			phase = "rejected"
		finished = TRUE
		executor.bot_native_history[token] = phase
		executor.bot_native_history_order += token
		while(length(executor.bot_native_history_order) > 4096)
			executor.bot_native_history -= executor.bot_native_history_order[1]
			executor.bot_native_history_order.Cut(1, 2)
	if(binding != client.binding_epoch || executor.closed || executor.query_disconnecting)
		return TRUE
	var/id = executor.new_query_id("bot")
	var/result_json = netrun_external_json_object(list(
		"bot" = netrun_external_bot_key_json(bot_key),
		"actor" = netrun_external_entity_actor_json(actor_key),
		"action_serial" = json_encode(action_serial),
		"expected_revision" = json_encode(expected_revision),
		"phase" = json_encode(phase),
		"response" = "null"))
	var/raw = netrun_external_json_object(list("kind" = json_encode("bot_effect_result"), "request_id" = json_encode(id), "result" = result_json))
	if(!id || !executor.enqueue_query("bot_effect_result", raw, executor))
		return FALSE
	return TRUE

/// Native decision queue shares the existing transport lifecycle and never runs brain simulation in DM.
/datum/netrun_external_effects/machines/queries/proc/advance_bot_native_effects(datum/netrun_external_core/client)
	set waitfor = FALSE
	if(bot_native_pump_binding || closed || query_disconnecting || !length(bot_native_pending))
		return
	var/captured_binding = client.binding_epoch
	bot_native_pump_binding = captured_binding
	while(captured_binding == client.binding_epoch && !closed && !query_disconnecting && length(bot_native_pending))
		bot_native_active = bot_native_pending[1]
		bot_native_pending.Cut(1, 2)
		if(!bot_native_active.execute(client, src))
			bot_native_pending.Insert(1, bot_native_active)
			bot_native_active = null
			break
		bot_native_known -= bot_native_active.token
		QDEL_NULL(bot_native_active)
		CHECK_TICK
		sleep(0)
	if(bot_native_pump_binding == captured_binding)
		bot_native_pump_binding = null

/datum/netrun_external_effects/machines/queries/proc/disconnect_bots()
	for(var/id in bot_proxies)
		var/datum/weakref/reference = bot_proxies[id]
		var/datum/netrun_external_bot_brain_proxy/proxy = reference?.resolve()
		if(proxy)
			proxy.set_clock_demand(FALSE)
			proxy.connected = FALSE
			proxy.configured = FALSE
			proxy.view = null
	bot_proxies.Cut()
	bot_generations.Cut()
	bot_clock_demand = 0
	QDEL_LIST(bot_native_pending)
	bot_native_pending = list()
	bot_native_known.Cut()
	bot_native_history.Cut()
	bot_native_history_order.Cut()
