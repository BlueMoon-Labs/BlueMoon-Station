/// Addressed process communication uses the same authorized routes as device commands.
/datum/netrun_console
	var/next_entity_signal = 0

/// A closed LAN never publishes its resident processes through a gateway card.
/datum/netrun_console/proc/entity_contacts(datum/component/netrun_node/node)
	. = list()
	if(QDELETED(node) || !node.is_online() || !node_visible(node) || node_level(node) < NETRUN_ACCESS_GUEST)
		return
	var/list/occupants = list()
	occupants |= node.entities
	occupants |= node.netrun_ice
	for(var/datum/occupant as anything in occupants)
		if(QDELETED(occupant))
			continue
		var/datum/component/netrun_combatant/combatant = occupant.get_netrun_combatant()
		if(!combatant || combatant.node() != node)
			continue
		var/list/entry = combatant.ui_entry()
		var/is_self = occupant == netrun_actor()
		entry["self"] = is_self
		entry["can_signal"] = occupant.netrun_actor_present(node) && !is_self && !is_locked()
		entry["can_message"] = entry["can_signal"]
		entry["can_offer"] = entry["can_signal"] && !!netrun_actor()
		entry["offer_reason"] = entry["can_offer"] ? null : "Прямой обмен доступен между сетевыми сущностями."
		if(istype(occupant, /mob/camera/netrun_entity))
			var/mob/camera/netrun_entity/entity = occupant
			entry["state"] = entity.contact_state()
		else if(istype(occupant, /datum/netrun_ice))
			var/datum/netrun_ice/ice = occupant
			entry["state"] = ice.dormant ? "спит до появления угрозы" : (ice.is_stunned() ? "оглушён" : (ice.pending_program ? "готовит атаку" : (ice.enemy_ref?.resolve() ? "преследует" : (ice.kind == NETRUN_ICE_HUNTER ? "патрулирует" : "охраняет узел"))))
			entry["ice_kind"] = ice.kind
			entry["threat"] = ice_contact_threat(ice, node)
		. += list(entry)

/// Describe the viewer's actual risk without granting access to undiscovered residents.
/datum/netrun_console/proc/ice_contact_threat(datum/netrun_ice/ice, datum/component/netrun_node/node)
	if(ice.agent?.profile.illegal)
		return "Нелегальный BLACK ICE: доступ USER не защищает. Нейронная обратная связь повреждает тело при нейроподключении. Щит ослабляет удар, выход из узла или отмена взлома срывают доставку."
	var/mob/camera/netrun_entity/entity = combat_self()
	if(!istype(entity))
		return "Атакует процессы без доступа ПОЛЬЗОВАТЕЛЯ. Трассирует активный взлом своего узла или ЛВС."
	if(world.time < entity.combat_ignore_until)
		var/remaining = CEILING((entity.combat_ignore_until - world.time) / (1 SECONDS), 0.1)
		return "След скрыт ещё [remaining] с. Атака или оглушение ICE выдаст вас."
	if(ice.is_intruder(entity, node))
		return ice.enemy_ref?.resolve() == entity ? "ICE считает вас противником и атакует при встрече, даже с доступом ПОЛЬЗОВАТЕЛЯ." : "Опасный вход: ICE атакует ваш процесс. Ключ ЛВС разрешает переход, но не заменяет доступ ПОЛЬЗОВАТЕЛЯ."
	return "Доступ ПОЛЬЗОВАТЕЛЯ позволяет пройти. Атака или оглушение ICE вызовет ответ. Взлом узла или ЛВС всё ещё вызывает трассировку."

/// Reused at dispatch and delivery: a stale card cannot address an arbitrary mob REF.
/datum/netrun_console/proc/entity_contact_denial(datum/component/netrun_node/node, datum/recipient, datum/netrun_path_tree/tree)
	if(is_locked())
		return "точка подключения заблокирована"
	if(QDELETED(node) || !istype(recipient) || QDELETED(recipient) || recipient == netrun_actor() || !recipient.netrun_actor_present(node))
		return "процесс уже покинул узел"
	if(!node.is_online() || !can_route(node, tree) || node_level(node, tree) < NETRUN_ACCESS_GUEST)
		return "нет связи или доступа к узлу"
	return null

/// Null text is a presence signal; nonempty text is a private addressed message.
/datum/netrun_console/proc/signal_entity(datum/component/netrun_node/node, recipient_ref, text, input_nonce)
	var/kind = isnull(text) ? "entity.signal" : "entity.message"
	var/datum/netrun_packet_context/operation = new(kind, isnull(text) ? "Сигнал процессу" : "Личное сообщение процессу",
		route_source()?.address, node?.address, "entity_contact", src, input_nonce)
	if(!istext(recipient_ref))
		return reject_operation(operation, "Некорректный адрес процесса.")
	if(world.time < next_entity_signal)
		log_line("Канал связи с процессами ещё занят.", "average")
		return reject_operation(operation, "Канал связи с процессами ещё занят.")
	var/datum/recipient = locate(recipient_ref)
	if(!istype(recipient) || QDELETED(recipient) || !recipient.netrun_actor_node())
		return reject_operation(operation, "Процесс больше не существует.")
	var/datum/netrun_path_tree/tree = make_path_tree()
	var/reason = entity_contact_denial(node, recipient, tree)
	if(reason)
		qdel(tree)
		log_line("Связь с процессом недоступна: [reason].", "bad")
		return reject_operation(operation, reason)
	if(!isnull(text))
		if(!istext(text))
			qdel(tree)
			return reject_operation(operation, "Некорректный текст сообщения.")
		text = trim(copytext_char(sanitize(text), 1, 241))
		if(!length(text))
			qdel(tree)
			return reject_operation(operation, "Сообщение пустое.")
	var/latency = latency_to(node, tree)
	var/list/route_hops = tree.addresses_to(node.address)
	qdel(tree)
	next_entity_signal = world.time + 2 SECONDS
	var/datum/netrun_request/entity_contact/packet = new(src, node, recipient, text, operation)
	return packet.send(latency, route_hops)

/// The delivery owns its recipient and message snapshot, without borrowing a UI route.
/datum/netrun_request/entity_contact
	parent_type = /datum/netrun_request/delivery
	var/datum/weakref/recipient_ref
	var/message
	var/sender_name
	var/source_address
	operation_kind = "entity.signal"
	operation_label = "Связь с процессом"

/datum/netrun_request/entity_contact/New(datum/netrun_console/console, datum/component/netrun_node/node, datum/recipient, text, datum/netrun_packet_context/context)
	..(console, node, node?.network, console.operator, null, context)
	recipient_ref = WEAKREF(recipient)
	message = text
	sender_name = console.get_handle()
	source_address = operation.from_address
	operation.capture(list("recipient" = REF(recipient), "message" = text))
	if(!(recipient in dependencies))
		dependencies += recipient
		RegisterSignal(recipient, COMSIG_PARENT_QDELETING, TYPE_PROC_REF(/datum/netrun_request/delivery, on_dependency_deleted))

/datum/netrun_request/entity_contact/Destroy()
	recipient_ref = null
	return ..()

/datum/netrun_request/entity_contact/execute()
	if(QDELETED(console) || QDELETED(node))
		return FALSE
	var/datum/recipient = recipient_ref?.resolve()
	node.join_network()
	var/datum/netrun_path_tree/tree = console.make_path_tree()
	var/reason = console.entity_contact_denial(node, recipient, tree)
	if(!reason && (sender != console.operator || node.network != sent_network))
		reason = "сеанс отправителя изменился"
	if(reason)
		qdel(tree)
		console.log_line("Доставка процессу отменена: [reason].", "bad")
		return reject(reason)
	var/list/route_hops = tree.addresses_to(node.address)
	qdel(tree)
	operation.receive(route_hops)
	var/datum/netrun_console/receiving_console = recipient.netrun_actor_console()
	if(QDELETED(receiving_console))
		return reject("Сеанс получателя недоступен.")
	var/recipient_name = recipient.netrun_actor_name()
	var/line = isnull(message) ? "Адресный сигнал от [sender_name] ([source_address])." : "Личное сообщение от [sender_name] ([source_address]): [message]"
	receiving_console.log_line(line, "good")
	if(ismob(recipient))
		to_chat(recipient, span_notice(line))
	console.log_line(isnull(message) ? "Сигнал доставлен: [recipient_name] @ [node.address]." : "Сообщение доставлено: [recipient_name] @ [node.address].", "good")
	node.add_log("[sender_name]: [isnull(message) ? "сигнал" : "личное сообщение"] процессу [recipient_name].")
	if(!isnull(message) && sender)
		sender.log_talk(message, LOG_CHAT, tag = "NETRUN private to [recipient_name]")
	SSnetrun.post_event("command", node.network?.id, node.address)
	SEND_SIGNAL(recipient, COMSIG_NETRUN_ACTOR_CONTACT, console, message)
	return TRUE
