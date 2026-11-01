/// Файл в сетевом хранилище
/datum/netrun_file
	var/name = "file"
	var/kind = NETRUN_FILE_TEXT
	/// Текст, ключ ЛВС или id демона
	var/content = ""
	var/size = 1
	/// Для ключей - id сети, которую открывает ключ
	var/network_id
	/// Фото принадлежит этому файлу. Копии файлов получают независимый снимок.
	var/datum/picture/picture
	/// Переносимая привязка к живому техвебу, не удерживающая удалённую сеть.
	var/datum/weakref/techweb_ref
	var/static/next_uid = 0
	var/uid

/datum/netrun_file/New(name, kind, content, size, network_id)
	uid = "[++next_uid]"
	if(name)
		src.name = name
	if(kind)
		src.kind = kind
	if(!isnull(content))
		src.content = content
	if(size)
		src.size = size
	else if(src.kind == NETRUN_FILE_TEXT)
		src.size = netrun_text_size(src.content)
	src.network_id = network_id

/datum/netrun_file/proc/copy()
	if(!can_copy())
		return null
	var/datum/netrun_file/result = new(name, kind, content, size, network_id)
	if(picture)
		result.picture = picture.Copy()
		result.picture.caption = picture.caption
	result.techweb_ref = techweb_ref
	result.data_receipt = data_receipt
	return result

/// Capability-bearing files can restrict transport at the storage boundary.
/datum/netrun_file/proc/can_copy()
	return TRUE

/datum/netrun_file/proc/can_transfer(datum/netrun_file_store/destination, move = FALSE)
	return TRUE

/datum/netrun_file/proc/can_store(datum/netrun_file_store/destination)
	return TRUE

/datum/netrun_file/proc/can_delete(datum/netrun_file_store/source)
	return source && source.capacity > 0

/// Copies normally occupy the same space; free native manuals become paid text.
/datum/netrun_file/proc/copy_storage_size()
	return size

/// Wire metadata contains no authorization result. Live native references stay uncached.
/datum/netrun_file/proc/ui_metadata_stable()
	return kind != NETRUN_FILE_TECHWEB_LINK

/datum/netrun_file/manual/copy_storage_size()
	refresh_text()
	return netrun_text_size(content)

/datum/netrun_file/manual/ui_metadata_stable()
	return FALSE

/datum/netrun_file/Destroy()
	data_receipt = null
	QDEL_NULL(picture)
	techweb_ref = null
	return ..()

/datum/netrun_file/proc/ui_entry(selected_uid)
	var/preview
	switch(kind)
		if(NETRUN_FILE_KEY)
			preview = "[network_id]: [content]"
		if(NETRUN_FILE_DAEMON)
			var/datum/netrun_program/daemon/daemon = SSnetrun.get_daemon(content)
			preview = daemon?.desc
		if(NETRUN_FILE_PROGRAM)
			var/datum/netrun_program/program = SSnetrun.get_program(content)
			preview = program?.desc
		if(NETRUN_FILE_TEXT)
			preview = copytext_char(content, 1, 200)
		if(NETRUN_FILE_TECHWEB)
			preview = "Дамп техвеба: [length(splittext(content, ";"))] технологий"
		if(NETRUN_FILE_TECHWEB_LINK)
			preview = "Привязка: [content][techweb_ref?.resolve() ? "" : " (сеть недоступна)"]"
		if(NETRUN_FILE_PHOTO)
			preview = picture ? "Фотография [picture.psize_x]×[picture.psize_y]" : "Нет изображения"
	return list(
		"uid" = uid,
		"name" = name,
		"kind" = kind,
		"size" = size,
		"copy_size" = copy_storage_size(),
		"preview" = preview,
		"selected" = uid == selected_uid,
		"transferable" = can_transfer(null),
		"copyable" = can_copy(),
		"session_bound" = FALSE,
	)

/// Чтение использует штатный просмотр фото; текст всегда экранируется как обычный текст.
/datum/netrun_file/proc/show(mob/user)
	if(!user?.client)
		return
	if(kind == NETRUN_FILE_PHOTO && picture)
		var/obj/item/photo/preview = new(null, picture)
		preview.show(user)
		qdel(preview)
		return
	var/text = content
	if(kind == NETRUN_FILE_TECHWEB_LINK)
		text = "Привязка к исследовательской сети: [content].\n[techweb_ref?.resolve() ? "Сеть доступна для подключения машин." : "Исходная сеть больше не существует."]"
	else if(kind != NETRUN_FILE_TEXT && kind != NETRUN_FILE_TECHWEB && kind != NETRUN_FILE_KEY)
		return
	var/datum/browser/popup = new(user, "netrun_file_[uid]", html_encode(name), 450, 500)
	popup.set_content("<tt>[replacetext(html_encode(text), "\n", "<br>")]</tt>")
	popup.open()

/// Программы-демоны, влияющие на взлом
/proc/netrun_daemon_file(id)
	var/datum/netrun_program/daemon/daemon = SSnetrun.get_daemon(id)
	return daemon?.create_file()

/// Шард данных: маленький переносной носитель
/obj/item/netrun_shard
	name = "data shard"
	desc = "Тонкая пластинка с кристаллом памяти. Вставляется в кибердеку, терминал или разъём нейролинка."
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk1"
	w_class = WEIGHT_CLASS_TINY
	var/datum/netrun_file_store/file_store
	/// Initial configuration only; writable state lives in file_store.capacity.
	var/initial_capacity = 8 * NETRUN_STORAGE_SCALE
	/// Что записано на шард при создании: list(тип файла = содержимое) или id демонов
	var/list/preload_daemons
	/// Боевые программы, записанные на шард при создании (id из реестра /datum/netrun_program)
	var/list/preload_programs

/obj/item/netrun_shard/Initialize(mapload)
	. = ..()
	file_store = new(src, initial_capacity)
	for(var/id in preload_daemons)
		var/datum/netrun_file/file = netrun_daemon_file(id)
		if(file)
			file_store.insert(file, TRUE)
	for(var/id in preload_programs)
		var/datum/netrun_file/file = netrun_program_file(id)
		if(file)
			file_store.insert(file, TRUE)

/obj/item/netrun_shard/Destroy()
	QDEL_NULL(file_store)
	return ..()

/obj/item/netrun_shard/examine(mob/user)
	. = ..()
	. += span_notice("Занято [file_store.used()] из [file_store.capacity] ячеек.")
	for(var/datum/netrun_file/file as anything in file_store.files)
		. += span_notice("— [file.name]")

/obj/item/netrun_shard/daemons
	name = "data shard (breach suite)"
	desc = "Шард с набором демонов для взлома. Чей-то рабочий инструмент."
	icon_state = "datadisk2"
	preload_daemons = list("buffer", "icepick", "cloak")

/proc/netrun_storage_used(list/files)
	. = 0
	for(var/datum/netrun_file/file as anything in files)
		. += file.size
