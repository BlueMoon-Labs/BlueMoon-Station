/// Поля подключаемого native proxy. До явной регистрации никакая старая механика не переключается.
/mob/camera/netrun_entity
	var/datum/netrun_external_entity_proxy/external_entity_proxy

/datum/netrun_ice
	var/datum/netrun_external_entity_proxy/external_entity_proxy

/datum/netrun_external_effects/machines/queries
	var/list/entity_proxies = list()
	var/list/entity_actor_generations = list()
	var/list/entity_native_pending = list()
	var/list/entity_native_known = list()
	var/list/entity_native_history = list()
	var/list/entity_native_history_order = list()
	var/entity_native_pump_binding
	var/datum/netrun_external_entity_native_effect/entity_native_active
	/// O(1) demand; native lifecycle не сканируется на каждом tick ради продвижения Core clock.
	var/entity_clock_demand = 0

/// Регистрация — явный opt-in. Identity не содержит REF, поколения и binding не переиспользуются после reconnect.
/datum/netrun_external_core/proc/entity_proxy(datum/actor, create = FALSE)
	if(QDELETED(actor) || !ready || !istype(effects, /datum/netrun_external_effects/machines/queries))
		return null
	var/datum/netrun_external_entity_proxy/proxy
	if(istype(actor, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = actor
		proxy = entity.external_entity_proxy
	else if(istype(actor, /datum/netrun_ice))
		var/datum/netrun_ice/ice = actor
		proxy = ice.external_entity_proxy
	else
		return null
	if(proxy?.binding == binding_epoch && proxy.connected)
		return proxy
	if(!create)
		return null
	QDEL_NULL(proxy)
	proxy = new(src, actor)
	if(istype(actor, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = actor
		entity.external_entity_proxy = proxy
	else
		var/datum/netrun_ice/ice = actor
		ice.external_entity_proxy = proxy
	return proxy

/proc/netrun_external_entity_actor_valid(list/key)
	return islist(key) && length(key) == 2 && istext(key["actor_id"]) && length(key["actor_id"]) && length(key["actor_id"]) <= 128 && netrun_external_valid_decimal(key["generation"])

/proc/netrun_external_entity_actor_same(list/first, list/second)
	return netrun_external_entity_actor_valid(first) && netrun_external_entity_actor_valid(second) && first["actor_id"] == second["actor_id"] && first["generation"] == second["generation"]

/proc/netrun_external_entity_actor_json(list/key)
	return netrun_external_entity_actor_valid(key) ? netrun_external_json_object(list("actor_id" = json_encode(key["actor_id"]), "generation" = json_encode(key["generation"]))) : null

/// Один live native actor. Поля view — read model Core, а не второй solver или mutable fallback.
/datum/netrun_external_entity_proxy
	var/datum/weakref/client_ref
	var/datum/weakref/actor_ref
	var/binding
	var/list/actor_key
	var/revision = "0"
	var/residence_revision = "0"
	var/list/view
	var/connected = TRUE
	var/registered = FALSE
	var/creation_requested = FALSE
	var/clock_accounted = FALSE
	var/last_code
	var/last_task_sequence = "0"
	var/pending_move_request
	var/pending_access_hash
	var/last_native_effect_sequence = "0"

/datum/netrun_external_entity_proxy/New(datum/netrun_external_core/client, datum/actor)
	client_ref = WEAKREF(client)
	actor_ref = WEAKREF(actor)
	binding = client.binding_epoch
	var/id = client.entity_access_identity(actor)
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	var/generation = netrun_external_decimal_next(executor.entity_actor_generations[id] || "0")
	executor.entity_actor_generations[id] = generation
	actor_key = list("actor_id" = id, "generation" = generation)
	executor.entity_proxies[id] = WEAKREF(src)
	RegisterSignal(actor, COMSIG_PARENT_QDELETING, PROC_REF(on_native_deleted))

/datum/netrun_external_entity_proxy/Destroy()
	set_clock_demand(FALSE)
	var/datum/actor = actor_ref?.resolve()
	if(actor)
		UnregisterSignal(actor, COMSIG_PARENT_QDELETING)
		if(istype(actor, /mob/camera/netrun_entity))
			var/mob/camera/netrun_entity/entity = actor
			if(entity.external_entity_proxy == src)
				entity.external_entity_proxy = null
		else if(istype(actor, /datum/netrun_ice))
			var/datum/netrun_ice/ice = actor
			if(ice.external_entity_proxy == src)
				ice.external_entity_proxy = null
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(istype(executor))
		var/datum/weakref/reference = executor.entity_proxies[actor_key?["actor_id"]]
		if(IS_WEAKREF_OF(src, reference))
			executor.entity_proxies -= actor_key["actor_id"]
		if(connected && (registered || creation_requested) && binding == client.binding_epoch)
			submit_action("delete", netrun_external_json_object(list("code" = json_encode("proxy_deleted"))), consumer = executor)
	connected = FALSE
	client_ref = null
	actor_ref = null
	actor_key = null
	view = null
	pending_access_hash = null
	return ..()

/datum/netrun_external_entity_proxy/proc/native_node()
	var/datum/actor = actor_ref?.resolve()
	if(istype(actor, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = actor
		return entity.host_node
	if(istype(actor, /datum/netrun_ice))
		var/datum/netrun_ice/ice = actor
		return ice.node
	return null

/datum/netrun_external_entity_proxy/proc/native_console()
	var/datum/actor = actor_ref?.resolve()
	if(istype(actor, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = actor
		return entity.console
	if(istype(actor, /datum/netrun_ice))
		var/datum/netrun_ice/ice = actor
		return ice.netrun_actor_console()
	return null

/// Data — JSON закрытого typed action, а не DM proc path или пользовательский executable payload.
/datum/netrun_external_entity_proxy/proc/submit_action(kind, data_json, access_json = null, expected_revision = null, datum/consumer = src)
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(!connected || binding != client?.binding_epoch || !client.ready || !istype(executor) || !(kind in list("create", "delete", "damage", "heal", "stun", "shield", "move", "control", "persona", "faction", "read")))
		return null
	if(!isnull(expected_revision) && !netrun_external_valid_decimal(expected_revision))
		return null
	if(kind == "move" && (pending_move_request || !istext(access_json)))
		return null
	var/id = executor.new_query_id("entity")
	if(!id)
		return null
	var/action = netrun_external_json_object(list("kind" = json_encode(kind), "data" = data_json))
	var/raw = netrun_external_json_object(list("kind" = json_encode("entity_operation"), "request_id" = json_encode(id), "actor" = netrun_external_entity_actor_json(actor_key), "expected_revision" = json_encode(expected_revision), "action" = action, "access" = access_json || "null"))
	if(!executor.enqueue_query("entity_operation", raw, consumer))
		return null
	if(kind == "move")
		pending_move_request = id
		pending_access_hash = md5(access_json)
	return id

/// Начальный register создаёт Core модель; вызывается только до передачи владения simulation библиотеке.
/datum/netrun_external_entity_proxy/proc/register()
	if(registered || creation_requested)
		return null
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/actor = actor_ref?.resolve()
	var/datum/component/netrun_node/node = native_node()
	var/datum/netrun_console/console = native_console()
	if(QDELETED(client) || QDELETED(actor) || QDELETED(node) || QDELETED(console))
		return null
	var/persona = "null"
	var/kind = 2
	var/max_integrity
	var/profile
	var/autonomous = TRUE
	var/expires
	if(istype(actor, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = actor
		var/datum/netrun_persona/style = entity.get_persona()
		persona = netrun_external_json_object(list("alias" = json_encode(entity.real_name), "avatar" = json_encode(style.avatar), "accent" = json_encode(style.accent), "tagline" = json_encode(style.tagline), "theme" = json_encode(style.theme)))
		kind = istype(entity, /mob/camera/netrun_entity/bot) ? 1 : 0
		max_integrity = entity.max_integrity
		autonomous = istype(entity, /mob/camera/netrun_entity/bot) && !entity.client
		var/mob/camera/netrun_entity/bot/bot = entity
		if(istype(bot))
			profile = bot.bot_kind
			expires = bot.expires_at || null
	else
		var/datum/netrun_ice/ice = actor
		max_integrity = ice.max_integrity
		profile = ice.kind
		persona = netrun_external_json_object(list("alias" = json_encode(ice.name), "avatar" = json_encode("orb"), "accent" = json_encode("silver"), "tagline" = json_encode(""), "theme" = json_encode("ion")))
	var/definition = netrun_external_json_object(list("actor" = netrun_external_entity_actor_json(actor_key), "kind" = json_encode(kind), "node" = client.entity_access_node_json(node), "max_integrity" = json_encode(max_integrity), "persona" = persona, "faction_id" = json_encode(actor.netrun_actor_faction()), "principal_id" = json_encode(client.entity_access_identity(console.personal_faction_principal())), "profile_id" = json_encode(profile), "autonomous" = netrun_external_json_bool(autonomous), "expires_at_ds" = json_encode(expires)))
	var/id = submit_action("create", netrun_external_json_object(list("definition" = definition)))
	creation_requested = !!id
	if(creation_requested)
		set_clock_demand(TRUE)
	return id

/// Счётчик изменяется только на lifecycle границах; repeated registration/teardown не создают лишний clock demand.
/datum/netrun_external_entity_proxy/proc/set_clock_demand(enabled)
	if(clock_accounted == enabled)
		return
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(istype(executor) && binding == client.binding_epoch)
		executor.entity_clock_demand = max(0, executor.entity_clock_demand + (enabled ? 1 : -1))
	clock_accounted = enabled

/// Native deletion is a fact. Executor itself owns the delete continuation after this actor has gone away.
/datum/netrun_external_entity_proxy/proc/on_native_deleted(datum/source)
	SIGNAL_HANDLER
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if((registered || creation_requested) && istype(executor))
		submit_action("delete", netrun_external_json_object(list("code" = json_encode("native_deleted"))), consumer = executor)
	set_clock_demand(FALSE)
	connected = FALSE
	registered = FALSE
	actor_ref = null
	pending_move_request = null
	pending_access_hash = null
	qdel(src)

/// Версия read model не становится physical movement. Residence меняет только native effect после revalidation.
/datum/netrun_external_entity_proxy/proc/apply_view(datum/netrun_external_core/client, list/next, code)
	if(!connected || binding != client.binding_epoch)
		return FALSE
	last_code = netrun_external_safe_code(code, "entity_changed")
	if(isnull(next))
		set_clock_demand(FALSE)
		registered = FALSE
		creation_requested = FALSE
		connected = FALSE
		view = null
		return TRUE
	if(!islist(next) || !netrun_external_entity_actor_same(next["actor"], actor_key) || !netrun_external_valid_decimal(next["revision"]) || !netrun_external_valid_decimal(next["residence_revision"]))
		return FALSE
	if(netrun_external_decimal_compare(next["revision"], revision) < 0)
		return TRUE
	var/datum/actor = actor_ref?.resolve()
	if(QDELETED(actor))
		return TRUE
	var/list/node_key = next["node"]
	var/datum/component/netrun_node/node = client.resolve_node(node_key?["node_id"], node_key?["generation"])
	if(!node || native_node() != node)
		return FALSE
	if(!isnum(next["integrity"]) || !IS_FINITE(next["integrity"]) || !isnum(next["max_integrity"]) || next["max_integrity"] <= 0 || !IS_FINITE(next["max_integrity"]) || !isnum(next["shield_factor"]) || !IS_FINITE(next["shield_factor"]) || next["shield_factor"] < 0.1 || next["shield_factor"] > 1)
		return FALSE
	for(var/field in list("stunned_until_ds", "shield_until_ds", "next_hop_ds"))
		if(!isnum(next[field]) || !IS_FINITE(next[field]) || next[field] < 0 || next[field] != round(next[field]))
			return FALSE
	var/list/persona = next["persona"]
	if(!islist(persona) || !istext(persona["alias"]) || !length(persona["alias"]) || length_char(persona["alias"]) > 42 || !istext(next["faction_id"]))
		return FALSE
	revision = next["revision"]
	residence_revision = next["residence_revision"]
	view = next.Copy()
	registered = TRUE
	set_clock_demand(TRUE)
	if(istype(actor, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = actor
		entity.integrity = next["integrity"]
		entity.max_integrity = next["max_integrity"]
		entity.combat_stun_until = next["stunned_until_ds"]
		entity.combat_shield_until = next["shield_until_ds"]
		entity.combat_shield_factor = next["shield_factor"]
		entity.next_hop = next["next_hop_ds"]
		var/datum/netrun_persona/style = entity.get_persona()
		style.alias = persona["alias"]
		style.avatar = persona["avatar"]
		style.accent = persona["accent"]
		style.tagline = persona["tagline"]
		style.theme = persona["theme"]
		entity.set_net_name(persona["alias"])
		var/mob/camera/netrun_entity/bot/bot = entity
		if(istype(bot))
			bot.net_faction = next["faction_id"]
		entity.combat_changed()
		entity.persona_changed()
	else
		var/datum/netrun_ice/ice = actor
		ice.integrity = next["integrity"]
		ice.max_integrity = next["max_integrity"]
		ice.combat_stun_until = next["stunned_until_ds"]
		ice.combat_shield_until = next["shield_until_ds"]
		ice.combat_shield_factor = next["shield_factor"]
		ice.name = persona["alias"]
		ice.node?.notify_changed(NETRUN_CHANGED_OCCUPANTS)
	return TRUE

/datum/netrun_external_effects/machines/queries/proc/entity_proxy_for(list/key)
	if(!netrun_external_entity_actor_valid(key))
		return null
	var/datum/weakref/reference = entity_proxies[key["actor_id"]]
	var/datum/netrun_external_entity_proxy/proxy = reference?.resolve()
	return proxy && netrun_external_entity_actor_same(proxy.actor_key, key) ? proxy : null

/datum/netrun_external_effects/machines/queries/proc/observe_entity(datum/netrun_external_core/client, list/result, datum/netrun_external_query_command/command)
	var/list/admission = result["admission"]
	var/datum/netrun_external_entity_proxy/proxy = command.consumer?.resolve()
	if(istype(proxy) && !(admission?["status"] in list("accepted", "duplicate")))
		proxy.last_code = netrun_external_safe_code(admission?["code"], "entity_rejected")
		if(proxy.pending_move_request == command.request_id)
			proxy.pending_move_request = null
			proxy.pending_access_hash = null
		forget_query(command.request_id)
		if(!proxy.registered)
			proxy.creation_requested = FALSE
			proxy.set_clock_demand(FALSE)

/datum/netrun_external_effects/machines/queries/proc/process_entity_changed(datum/netrun_external_core/client, list/result)
	var/id = result["request_id"]
	var/lifecycle = istext(id) && findtext(id, "entity.lifecycle:") == 1 && netrun_external_valid_decimal(copytext(id, length("entity.lifecycle:") + 1))
	if(length(result) != 6 || (!known_query_id(id) && !lifecycle) || !netrun_external_entity_actor_valid(result["actor"]) || !istext(result["code"]))
		return FALSE
	var/datum/netrun_external_entity_proxy/proxy = entity_proxy_for(result["actor"])
	return QDELETED(proxy) ? TRUE : proxy.apply_view(client, result["view"], result["code"])

/datum/netrun_external_effects/machines/queries/proc/process_entity_task_completed(datum/netrun_external_core/client, list/result)
	if(length(result) != 6 || !known_query_id(result["request_id"]) || !netrun_external_valid_decimal(result["task_sequence"]) || !(result["success"] == TRUE || result["success"] == FALSE) || !istext(result["code"]))
		return FALSE
	var/datum/netrun_external_entity_proxy/proxy = get_query_consumer(result["request_id"])
	if(istype(proxy))
		proxy.last_task_sequence = result["task_sequence"]
		proxy.last_code = netrun_external_safe_code(result["code"], "entity_task_completed")
		if(!result["success"] && !proxy.registered)
			proxy.creation_requested = FALSE
			proxy.set_clock_demand(FALSE)
		if(!result["success"] && proxy.pending_move_request == result["request_id"])
			proxy.pending_move_request = null
			proxy.pending_access_hash = null
	forget_query(result["request_id"])
	return TRUE

/// Decoder ставит только native adapter работу; экспорт и физическое действие выполняются отдельной cooperative помпой.
/datum/netrun_external_effects/machines/queries/proc/process_entity_native_effect(datum/netrun_external_core/client, list/result)
	if(length(result) != 8 || !known_query_id(result["request_id"]) || !netrun_external_entity_actor_valid(result["actor"]) || !istext(result["effect_id"]) || !length(result["effect_id"]) || length(result["effect_id"]) > 256 || !netrun_external_valid_decimal(result["residence_revision"]))
		return FALSE
	for(var/field in list("source", "destination"))
		var/list/key = result[field]
		if(!islist(key) || length(key) != 2 || !istext(key["node_id"]) || !netrun_external_valid_decimal(key["generation"]))
			return FALSE
	var/id = result["effect_id"]
	if(entity_native_known[id])
		return TRUE
	var/datum/netrun_external_entity_native_effect/context = new
	context.binding = client.binding_epoch
	context.actor_key = result["actor"].Copy()
	context.request_id = result["request_id"]
	context.effect_id = id
	context.residence_revision = result["residence_revision"]
	context.source = result["source"].Copy()
	context.destination = result["destination"].Copy()
	var/datum/netrun_external_entity_proxy/proxy = entity_proxy_for(context.actor_key)
	if(proxy && proxy.pending_move_request == context.request_id)
		context.access_hash = proxy.pending_access_hash
	var/sequence = copytext(context.request_id, findtext(context.request_id, ":") + 1)
	if(entity_native_history[id])
		context.finished = TRUE
		context.success = entity_native_history[id] == "success"
	else if(!proxy || netrun_external_decimal_compare(sequence, proxy.last_native_effect_sequence) <= 0)
		context.finished = TRUE
		context.success = FALSE
	else
		proxy.last_native_effect_sequence = sequence
	entity_native_known[id] = TRUE
	entity_native_pending += context
	owner.wake_ready_delivery()
	return TRUE

/datum/netrun_external_entity_native_effect
	var/binding
	var/request_id
	var/list/actor_key
	var/effect_id
	var/residence_revision
	var/list/source
	var/list/destination
	var/access_hash
	var/finished = FALSE
	var/success = FALSE

/// Caller — отдельная native помпа. Вычисление маршрута/прав здесь отсутствует: проверяются лишь exact raw facts.
/datum/netrun_external_entity_native_effect/proc/execute(datum/netrun_external_core/client, datum/netrun_external_effects/machines/queries/executor)
	if(!finished)
		var/datum/netrun_external_entity_proxy/proxy = executor.entity_proxy_for(actor_key)
		var/datum/netrun_console/console = proxy?.native_console()
		var/raw = access_hash && console ? client.entity_access_json(console) : null
		var/datum/actor = proxy?.actor_ref?.resolve()
		var/datum/component/netrun_node/source_node = client.resolve_node(source["node_id"], source["generation"])
		var/datum/component/netrun_node/target_node = client.resolve_node(destination["node_id"], destination["generation"])
		if(binding == client.binding_epoch && proxy?.connected && proxy.binding == binding && proxy.residence_revision == residence_revision && !QDELETED(actor) && source_node && target_node && source_node != target_node && proxy.native_node() == source_node && source_node.is_online() && target_node.is_online() && client.infrastructure_facts_ready() && raw && md5(raw) == access_hash)
			if(istype(actor, /mob/camera/netrun_entity))
				var/mob/camera/netrun_entity/entity = actor
				success = entity.enter_node(target_node, TRUE) && !QDELETED(entity) && entity.host_node == target_node
			else if(istype(actor, /datum/netrun_ice))
				var/datum/netrun_ice/ice = actor
				success = ice.enter_node(target_node) && !QDELETED(ice) && ice.node == target_node
		finished = TRUE
		executor.entity_native_history[effect_id] = success ? "success" : "failure"
		executor.entity_native_history_order += effect_id
		while(length(executor.entity_native_history_order) > 4096)
			executor.entity_native_history -= executor.entity_native_history_order[1]
			executor.entity_native_history_order.Cut(1, 2)
	if(binding != client.binding_epoch || executor.closed || executor.query_disconnecting)
		return TRUE
	var/id = executor.new_query_id("entity")
	var/raw = netrun_external_json_object(list("kind" = json_encode("entity_effect_result"), "request_id" = json_encode(id), "binding_epoch" = json_encode(binding), "actor" = netrun_external_entity_actor_json(actor_key), "effect_id" = json_encode(effect_id), "residence_revision" = json_encode(residence_revision), "success" = netrun_external_json_bool(success)))
	if(!id || !executor.enqueue_query("entity_effect_result", raw, executor))
		return FALSE
	var/datum/netrun_external_entity_proxy/proxy = executor.entity_proxy_for(actor_key)
	if(proxy?.pending_move_request == request_id)
		proxy.pending_move_request = null
		proxy.pending_access_hash = null
	return TRUE

/// Native effect queue живёт в том же transport lifecycle и никогда не исполняет actor simulation.
/datum/netrun_external_effects/machines/queries/proc/advance_entity_native_effects(datum/netrun_external_core/client)
	set waitfor = FALSE
	if(entity_native_pump_binding || closed || query_disconnecting || !length(entity_native_pending))
		return
	var/captured_binding = client.binding_epoch
	entity_native_pump_binding = captured_binding
	while(captured_binding == client.binding_epoch && !closed && !query_disconnecting && length(entity_native_pending))
		entity_native_active = entity_native_pending[1]
		entity_native_pending.Cut(1, 2)
		if(!entity_native_active.execute(client, src))
			entity_native_pending.Insert(1, entity_native_active)
			entity_native_active = null
			break
		entity_native_known -= entity_native_active.effect_id
		QDEL_NULL(entity_native_active)
		CHECK_TICK
		sleep(0)
	if(entity_native_pump_binding == captured_binding)
		entity_native_pump_binding = null

/// Существующая machine помпа сохраняет собственный lifecycle; entity эффекты используют тот же native tick.
/datum/netrun_external_effects/machines/queries/advance_native_invocations(datum/netrun_external_core/client)
	..()
	advance_entity_native_effects(client)

/datum/netrun_external_effects/machines/queries/has_pending_work()
	return entity_clock_demand > 0 || ..()

/datum/netrun_external_effects/machines/queries/proc/disconnect_entities()
	for(var/id in entity_proxies)
		var/datum/weakref/reference = entity_proxies[id]
		var/datum/netrun_external_entity_proxy/proxy = reference?.resolve()
		if(proxy)
			proxy.set_clock_demand(FALSE)
			proxy.connected = FALSE
			proxy.registered = FALSE
			proxy.view = null
			proxy.pending_move_request = null
			proxy.pending_access_hash = null
	entity_proxies.Cut()
	entity_actor_generations.Cut()
	entity_clock_demand = 0
	QDEL_LIST(entity_native_pending)
	entity_native_pending = list()
	entity_native_known.Cut()
	entity_native_history.Cut()
	entity_native_history_order.Cut()
