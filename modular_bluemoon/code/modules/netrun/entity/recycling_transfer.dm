/// A collector carries a real file to a server, then submits an ordinary file
/// packet. Admission never reserves capacity or removes cargo from the process.
/datum/netrun_console/proc/deposit_to_node(uid, datum/component/netrun_node/node, delivered = FALSE, input_nonce)
	if(!delivered)
		return queue_file_request("deposit", node, uid, FALSE, input_nonce)
	var/reason = deposit_denial(uid, node)
	if(reason)
		log_line(reason, "bad")
		return FALSE
	if(is_locked() || !node.is_online() || !can_route(node) || node_level(node) < max(NETRUN_ACCESS_USER, node.fortress?.file_access_level(src) || 0))
		log_line("Разгрузка отклонена: сервер, маршрут или доступ изменились.", "bad")
		return FALSE
	var/datum/netrun_file/file = inventory.local_store.find_file(uid)
	if(!inventory.local_store.transfer_to(node.file_store, file, TRUE))
		log_line("Разгрузка отклонена: файл или свободная память изменились.", "bad")
		return FALSE
	node.touch()
	node.add_log("[log_source()]: разгружен исходный файл [file.name].")
	log_line("Разгружено на сервер: [file.name].", "good")
	node.network?.add_log("[log_source()] разгрузил [file.name] на [node.address]")
	if(legit_node_level(node) < NETRUN_ACCESS_USER)
		add_trace(3 * node.get_security())
	return TRUE

/// Locality, ownership and memory are checked at both ends of the delivery.
/// A shard or a private session mount is not a source of local collector cargo.
/datum/netrun_console/proc/deposit_denial(uid, datum/component/netrun_node/node)
	var/mob/camera/netrun_entity/entity = host
	if(!istype(entity) || QDELETED(entity) || entity.console != src || operator != entity || entity.host_node != node || entity.is_stunned())
		return "Для разгрузки действующий процесс должен находиться в узле сервера."
	if(QDELETED(node) || node.node_type != NETRUN_NODE_SERVER || QDELETED(node.file_store))
		return "Разгрузка доступна только в действующее серверное хранилище."
	var/datum/netrun_file/file = inventory.local_store.find_file(uid)
	if(!istext(uid) || QDELETED(file) || inventory.store_for(file) != inventory.local_store)
		return "Файл больше не принадлежит локальной памяти процесса."
	if(!file.can_transfer(node.file_store, TRUE))
		return "Этот файл не допускает переноса на сервер."
	if(!node.file_store.can_fit(file))
		return "В серверном хранилище нет места для исходного файла."
	return null

/// File work shares the brain's existing nonce/completion/cancellation channel.
/datum/netrun_console/proc/track_file_packet(datum/netrun_request/file/packet)
	return

/datum/netrun_console/entity/bot/track_file_packet(datum/netrun_request/file/packet)
	var/mob/camera/netrun_entity/bot/bot = host
	if(bot?.brain?.command_nonce && packet.operation?.nonce == bot.brain.command_nonce)
		bot.brain.command_packet_ref = WEAKREF(packet)
