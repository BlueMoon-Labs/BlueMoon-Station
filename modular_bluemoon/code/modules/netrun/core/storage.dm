// MARK: Локальные файлы и съёмная память

/proc/netrun_file_name(value, fallback = "document.txt")
	if(!istext(value))
		return fallback
	return trim(copytext_char(sanitize_filename(strip_html_tags(value, TRUE)), 1, 65)) || fallback

/proc/netrun_text_size(text)
	return max(1, CEILING(length_char(text) / 500, 1))

/datum/netrun_console/proc/selected_local_file(required_kind, datum/netrun_request/request)
	var/datum/netrun_file/file = find_local_file(request ? request.file_uid : inventory.selected_file_uid)
	if(!file || (required_kind && file.kind != required_kind))
		return null
	return file

/datum/netrun_console/proc/file_payload()
	var/datum/netrun_file/file = selected_local_file()
	if(!file)
		inventory.selected_file_uid = null
		return null
	var/list/payload = file.ui_entry(inventory.selected_file_uid)
	payload["source"] = inventory.store_for(file) == inventory.session_store ? "session" : ((file in inventory.local_store.files) ? "local" : "shard")
	payload["can_import"] = inventory.store_for(file) == inventory.shard?.file_store
	var/datum/netrun_file_store/source = inventory.store_for(file)
	payload["deletable"] = file.can_delete(source)
	payload["delete_reason"] = payload["deletable"] ? null : "Носитель доступен только для чтения."
	payload["transfer"] = list(
		"local" = file_transfer_payload(source, inventory.local_store, file),
		"shard" = file_transfer_payload(source, inventory.shard?.file_store, file),
	)
	if(file.kind == NETRUN_FILE_BOT)
		payload["agent_builder"] = agent_builder_payload(file)
	payload["content"] = file.kind == NETRUN_FILE_TEXT ? file.content : null
	payload["image"] = null
	if(file.kind == NETRUN_FILE_PHOTO && file.picture)
		var/base64 = file.picture.get_base64()
		payload["image"] = base64 ? "data:image/png;base64,[base64]" : null
		payload["width"] = file.picture.psize_x
		payload["height"] = file.picture.psize_y
	return payload

/// Cheap UI admission uses the same actual disks and policy as the storage mutation.
/datum/netrun_console/proc/file_transfer_payload(datum/netrun_file_store/source, datum/netrun_file_store/destination, datum/netrun_file/file)
	var/copy_reason = source ? source.transfer_denial(destination, file) : "Исходный носитель недоступен."
	var/move_reason = source ? source.transfer_denial(destination, file, TRUE) : "Исходный носитель недоступен."
	return list("copy" = !copy_reason, "move" = !move_reason, "reason" = (copy_reason && move_reason) ? copy_reason : null,
		"merge" = !QDELETED(destination) && istype(file, /datum/netrun_file/acquired_key) && !!destination.acquired_key_target(file))

/// Все операции ограничены носителями этой консоли; UID удалённого узла сюда не проходит.
/datum/netrun_console/proc/file_act(action, list/params, mob/user)
	if(!(action in list("file_select", "file_new", "file_edit", "file_rename", "file_copy", "file_move", "file_import", "agent_create")))
		return FALSE
	if(action == "agent_create")
		create_agent_file(params, user)
		return TRUE
	if(action == "file_import")
		var/datum/netrun_file/imported = inventory.import_from_shard(params["uid"], !!params["move"])
		log_line(imported ? "Агент или файл [imported.name] [params["move"] ? "перемещён" : "скопирован"] в локальную память." : "Импорт отклонён: шард, файл или свободная память недоступны.", imported ? "good" : "bad")
		return TRUE
	var/datum/netrun_file/file = find_local_file(params["uid"])
	if(action == "file_new")
		create_text_file(params["name"], params["content"], !!params["to_shard"])
		return TRUE
	if(!file)
		log_line("Файл больше недоступен.", "bad")
		return TRUE
	switch(action)
		if("file_select")
			inventory.selected_file_uid = file.uid
			if(workspace_view != "agents")
				workspace_view = "files"
		if("file_edit")
			edit_text_file(file, params["content"])
		if("file_rename")
			rename_local_file(file, params["name"])
		if("file_copy", "file_move")
			transfer_local_file(file, !!params["to_shard"], action == "file_move")
	return TRUE

/datum/netrun_console/proc/rename_local_file(datum/netrun_file/file, new_name)
	var/datum/netrun_file_store/source = inventory.store_for(file)
	if(!source || !istext(new_name) || !length(trim(new_name)))
		return FALSE
	if(source.capacity <= 0)
		log_line("Носитель доступен только для чтения.", "bad")
		return FALSE
	file.name = netrun_file_name(new_name, file.name)
	if(file.picture)
		file.picture.picture_name = file.name
	source.notify_changed()
	log_line("Файл переименован: [file.name].", "good")
	return TRUE

/datum/netrun_console/proc/create_text_file(file_name, text, to_shard = FALSE)
	if(!istext(text))
		text = ""
	if(length_char(text) > 10000)
		log_line("Текст слишком большой: максимум 10000 символов.", "bad")
		return FALSE
	var/datum/netrun_file/file = new(netrun_file_name(file_name), NETRUN_FILE_TEXT, text, netrun_text_size(text))
	if(!store_file(file, to_shard))
		qdel(file)
		log_line("На выбранном носителе нет места.", "bad")
		return FALSE
	inventory.selected_file_uid = file.uid
	log_line("Создан файл [file.name].", "good")
	return TRUE

/datum/netrun_console/proc/edit_text_file(datum/netrun_file/file, text)
	if(file.kind != NETRUN_FILE_TEXT || !istext(text))
		return FALSE
	if(length_char(text) > 10000)
		log_line("Текст слишком большой: максимум 10000 символов.", "bad")
		return FALSE
	var/datum/netrun_file_store/source = inventory.store_for(file)
	if(!source)
		return FALSE
	var/new_size = netrun_text_size(text)
	if(source.used() - file.size + new_size > source.capacity)
		log_line("Для сохранения текста не хватает памяти.", "bad")
		return FALSE
	file.content = text
	file.size = new_size
	source.notify_changed()
	log_line("Сохранён файл [file.name].", "good")
	return TRUE

/datum/netrun_console/proc/transfer_local_file(datum/netrun_file/file, to_shard, move = FALSE)
	var/datum/netrun_file_store/source = inventory.store_for(file)
	var/datum/netrun_file_store/destination = to_shard ? inventory.shard?.file_store : inventory.local_store
	var/reason = source ? source.transfer_denial(destination, file, move) : "Исходный носитель недоступен."
	if(reason)
		log_line(reason, "bad")
		return FALSE
	var/original_name = file.name
	var/datum/netrun_file/copied = source.transfer_to(destination, file, move)
	if(!copied)
		return FALSE
	if(!move && !istype(copied, /datum/netrun_file/acquired_key))
		copied.name = netrun_file_name("Копия [file.name]")
		if(copied.picture)
			copied.picture.picture_name = copied.name
		inventory.selected_file_uid = copied.uid
		destination.notify_changed()
	inventory.selected_file_uid = copied.uid
	log_line("[move ? "Перемещён" : "Скопирован"] файл [original_name].", "good")
	return TRUE
