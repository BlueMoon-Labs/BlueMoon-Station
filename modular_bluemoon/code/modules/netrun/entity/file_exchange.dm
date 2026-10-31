/// A delivered proposal owns an inert file snapshot until its recipient accepts.
/// It neither mounts nor executes the file. Sender media always retain the original.
/datum/netrun_file_offer
	var/id
	var/sender_name
	var/datum/netrun_file/file
	var/expires_at

/datum/netrun_file_offer/Destroy()
	QDEL_NULL(file)
	return ..()

/datum/netrun_file_exchange
	var/datum/netrun_console/owner
	var/list/datum/netrun_file_offer/incoming = list()
	var/expiry_timer
	var/next_offer = 0
	var/static/serial = 0

/datum/netrun_file_exchange/New(datum/netrun_console/owner)
	src.owner = owner

/datum/netrun_file_exchange/Destroy()
	if(expiry_timer)
		deltimer(expiry_timer)
	QDEL_LIST_ASSOC_VAL(incoming)
	owner = null
	return ..()

/datum/netrun_file_exchange/proc/receive(datum/netrun_file/file, sender_name)
	prune_expired()
	if(QDELETED(file) || QDELETED(owner) || !file.can_transfer(owner.inventory.local_store) || !file.can_store(owner.inventory.local_store) || length(incoming) >= 8 || file.size > owner.inventory.local_store.capacity)
		qdel(file)
		return FALSE
	var/datum/netrun_file_offer/offer = new
	offer.id = "offer-[++serial]"
	offer.sender_name = sender_name
	offer.file = file
	offer.expires_at = world.time + 2 MINUTES
	incoming[offer.id] = offer
	arm_expiry()
	owner.log_line("[sender_name] предлагает копию [file.name]. Примите или отклоните её во вкладке файлов.", "label")
	owner.invalidate_ui()
	return TRUE

/datum/netrun_file_exchange/proc/arm_expiry()
	if(expiry_timer)
		deltimer(expiry_timer)
	expiry_timer = null
	var/earliest = INFINITY
	for(var/id in incoming)
		var/datum/netrun_file_offer/offer = incoming[id]
		earliest = min(earliest, offer.expires_at)
	if(earliest != INFINITY)
		expiry_timer = addtimer(CALLBACK(src, PROC_REF(expire)), max(1, earliest - world.time), TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_file_exchange/proc/expire()
	expiry_timer = null
	prune_expired()
	arm_expiry()

/// Expired offers release their owned snapshots before admitting new mail, even if a timer is queued.
/datum/netrun_file_exchange/proc/prune_expired()
	var/changed = FALSE
	for(var/id in incoming)
		var/datum/netrun_file_offer/offer = incoming[id]
		if(world.time < offer.expires_at)
			continue
		incoming -= id
		qdel(offer)
		changed = TRUE
	if(changed)
		owner?.invalidate_ui()

/datum/netrun_file_exchange/proc/payload()
	var/list/entries = list()
	for(var/id in incoming)
		var/datum/netrun_file_offer/offer = incoming[id]
		if(world.time >= offer.expires_at)
			continue
		var/can_accept = owner.inventory.local_store.can_fit(offer.file)
		entries += list(list("id" = id, "sender" = offer.sender_name, "name" = offer.file.name, "kind" = offer.file.kind,
			"size" = offer.file.size, "ttl" = max(0, round((offer.expires_at - world.time) / (1 SECONDS))),
			"can_accept" = can_accept, "reason" = can_accept ? null : "Недостаточно свободной локальной памяти."))
	return list("incoming" = entries, "max_offers" = 8)

/datum/netrun_file_exchange/proc/respond(id, accept)
	if(!istext(id) || !owner.netrun_actor())
		return FALSE
	var/datum/netrun_file_offer/offer = incoming[id]
	if(QDELETED(offer) || world.time >= offer.expires_at)
		return FALSE
	if(accept)
		var/file_name = offer.file.name
		var/datum/netrun_file/received = owner.inventory.local_store.insert(offer.file)
		if(!received)
			owner.log_line("Для копии [offer.file.name] нет места в памяти.", "bad")
			return FALSE
		owner.inventory.selected_file_uid = received.uid
		owner.log_line("Принята копия [file_name] от [offer.sender_name].", "good")
		offer.file = null
	else
		owner.log_line("Предложение [offer.sender_name] отклонено.")
	incoming -= id
	qdel(offer)
	arm_expiry()
	owner.invalidate_ui()
	return TRUE

/datum/netrun_console/proc/offer_entity_file(address, recipient_ref, uid)
	var/datum/self = netrun_actor()
	if(!self || !istext(recipient_ref) || !istext(uid) || world.time < file_exchange.next_offer)
		return FALSE
	var/datum/recipient = locate(recipient_ref)
	var/datum/component/netrun_node/node = SSnetrun.find_node(address)
	var/datum/netrun_file/file = find_local_file(uid)
	var/datum/netrun_path_tree/tree = connection.read_path_tree(TRUE)
	var/reason = entity_contact_denial(node, recipient, tree)
	var/datum/netrun_console/receiving_console = reason ? null : recipient.netrun_actor_console()
	if(reason || QDELETED(receiving_console) || QDELETED(file) || !inventory.store_for(file) || !file.can_copy() || !file.can_transfer(receiving_console.inventory.local_store))
		release_path_tree(tree)
		log_line("Нельзя предложить файл: [reason || "файл не принадлежит отправителю"].", "bad")
		return FALSE
	var/eta = latency_to(node, tree)
	var/list/route = tree.addresses_to(node.address)
	release_path_tree(tree)
	file_exchange.next_offer = world.time + 2 SECONDS
	var/datum/netrun_request/entity_file_offer/packet = new(src, node, recipient, file)
	return packet.send(eta, route)

/datum/netrun_request/entity_file_offer
	parent_type = /datum/netrun_request/delivery
	var/datum/weakref/recipient_ref
	var/sender_name
	operation_kind = "entity.file"
	operation_label = "Предложение копии файла"

/datum/netrun_request/entity_file_offer/New(datum/netrun_console/console, datum/component/netrun_node/node, datum/recipient, datum/netrun_file/file)
	..(console, node, node.network, console.operator, file.uid)
	recipient_ref = WEAKREF(recipient)
	sender_name = console.get_handle()
	operation.capture(list("recipient" = recipient.netrun_actor_name(), "file_uid" = file.uid, "name" = file.name))
	for(var/datum/dependency as anything in list(recipient, recipient.netrun_actor_console(FALSE)))
		if(dependency in dependencies)
			continue
		dependencies += dependency
		RegisterSignal(dependency, COMSIG_PARENT_QDELETING, TYPE_PROC_REF(/datum/netrun_request/delivery, on_dependency_deleted))

/datum/netrun_request/entity_file_offer/execute()
	var/datum/recipient = recipient_ref?.resolve()
	var/datum/netrun_file/file = console.find_local_file(file_uid)
	var/datum/netrun_path_tree/tree = console.connection.read_path_tree(TRUE)
	var/reason = console.entity_contact_denial(node, recipient, tree)
	var/datum/netrun_console/receiving_console = reason ? null : recipient.netrun_actor_console(FALSE)
	if(reason || QDELETED(receiving_console) || QDELETED(file) || !console.inventory.store_for(file) || !file.can_copy() || !file.can_transfer(receiving_console.inventory.local_store) || sender != console.operator || node.network != sent_network || !console.netrun_actor())
		console.release_path_tree(tree)
		return reject("Получатель, файл, маршрут или отправитель изменились.")
	operation.receive(tree.addresses_to(node.address))
	console.release_path_tree(tree)
	if(!receiving_console.file_exchange.receive(file.copy(), sender_name))
		return reject("Очередь предложений получателя заполнена или файл больше его памяти.")
	operation.set_result("Копия предложена [recipient.netrun_actor_name()]; ожидается согласие получателя.")
	return TRUE
