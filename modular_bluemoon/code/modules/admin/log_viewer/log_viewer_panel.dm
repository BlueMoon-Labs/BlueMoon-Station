/// Кэш листинга каталога, чтобы не дёргать диск на каждый чих.
#define ADMIN_LOG_LISTING_CACHE_TIME (5 SECONDS)
/// Белый список расширений для просмотра и скачивания.
#define ADMIN_LOG_EXT_REGEX @{"\.(txt|log|htm|html|md|json|csv)$"}
/// Период проверки роста файла в режиме tail.
#define ADMIN_LOG_TAIL_PERIOD (3 SECONDS)
/// Куда складываются собранные архивы логов.
#define ADMIN_LOG_ARCHIVE_DIR "data/log_archives/"
/// Минимальный интервал пересборки архива живого каталога (содержащего текущий раунд).
#define ADMIN_LOG_ARCHIVE_REBUILD_COOLDOWN (1 MINUTES)
/// Через сколько удалять собранный архив (ftp к этому моменту давно ушёл).
#define ADMIN_LOG_ARCHIVE_TTL (10 MINUTES)
/// Кап длины команды tar при архивации выбранных файлов (лимит cmd на Windows ~8К).
#define ADMIN_LOG_MULTI_CMD_MAX 6000
/// Кап страницы в режиме "весь файл" (json-пересылка в tgui + рендер у клиента).
#define ADMIN_LOG_WHOLE_PAGE_MAX (8 * 1024 * 1024)

/// Относительный путь каталога -> world.time последней сборки архива.
GLOBAL_LIST_EMPTY(admin_log_archive_builds)
/// Пути архивов, сборка которых идёт прямо сейчас (shelleo спит) - защита от параллельных tar по одному файлу.
GLOBAL_LIST_EMPTY(admin_log_archive_building)

/datum/admins
	/// Панель просмотра логов этого админа (создаётся при первом открытии).
	var/datum/admin_log_viewer/log_viewer

/// TGUI-браузер серверных логов: навигация по data/logs, постраничный просмотр,
/// поиск, live-tail текущего раунда, скачивание файлов и архива раунда.
/datum/admin_log_viewer
	/// Клиент-владелец панели.
	var/client/owner
	/// Текущий каталог как список проверенных сегментов относительно ADMIN_LOG_ROOT.
	var/list/path_segments = list()
	/// Кэш листинга текущего каталога.
	var/list/listing
	var/listing_time = 0
	/// Открытый файл (имя в текущем каталоге) и его состояние просмотра.
	var/current_file
	var/file_size = 0
	var/page_start = 0
	var/page_end = 0
	var/page_content = ""
	/// Кэш целиком прочитанного файла (только для файлов <= ADMIN_LOG_WHOLE_READ_MAX).
	var/cached_content
	var/cached_path
	/// Результаты серверного поиска по файлу.
	var/list/search_results
	var/search_query = ""
	/// Троттлинг страничных чтений (спам кнопками пейджера не должен дёргать диск чаще ~2 раз/сек).
	var/last_page_act = 0
	/// Выбранный размер страницы в байтах; 0 - режим "весь файл" (кап ADMIN_LOG_WHOLE_PAGE_MAX).
	var/page_bytes = ADMIN_LOG_PAGE_BYTES
	/// Режим live-tail: активен ли и id зацикленного таймера.
	var/tail_active = FALSE
	var/tail_timer

/datum/admin_log_viewer/New(client/new_owner)
	..()
	owner = new_owner

/datum/admin_log_viewer/Destroy()
	stop_tail()
	SStgui.close_uis(src)
	owner = null
	return ..()

/datum/admin_log_viewer/ui_state(mob/user)
	return GLOB.admin_state

/datum/admin_log_viewer/ui_interact(mob/user, datum/tgui/ui)
	refresh_listing()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AdminLogViewer")
		// Страница может весить сотни КиБ - никаких автопушей раз в тик, только по действиям.
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/admin_log_viewer/ui_close(mob/user)
	stop_tail()
	return ..()

/// Абсолютный путь текущего каталога, всегда с завершающим "/".
/datum/admin_log_viewer/proc/current_dir_path()
	if(!length(path_segments))
		return ADMIN_LOG_ROOT
	return ADMIN_LOG_ROOT + jointext(path_segments, "/") + "/"

/// Абсолютный путь открытого файла или null.
/datum/admin_log_viewer/proc/current_file_path()
	if(isnull(current_file))
		return null
	return current_dir_path() + current_file

/// Перейти к произвольному списку сегментов (уже валидированных).
/datum/admin_log_viewer/proc/jump_to(list/segments)
	path_segments = segments.Copy()
	reset_file_state()
	refresh_listing(force = TRUE)

/datum/admin_log_viewer/proc/reset_file_state()
	stop_tail()
	current_file = null
	file_size = 0
	page_start = 0
	page_end = 0
	page_content = ""
	cached_content = null
	cached_path = null
	search_results = null
	search_query = ""

/datum/admin_log_viewer/proc/refresh_listing(force = FALSE)
	if(!force && listing && world.time < listing_time + ADMIN_LOG_LISTING_CACHE_TIME)
		return
	var/dir_path = current_dir_path()
	var/list/raw = flist(dir_path)
	var/list/meta = fetch_listing_meta(dir_path)
	var/list/dirs = list()
	var/list/files = list()
	for(var/entry in raw)
		if(findtext(entry, "/", -1))
			var/dir_name = copytext(entry, 1, -1)
			if(!admin_log_valid_segment(dir_name))
				continue
			dirs += list(list("name" = dir_name, "isDir" = TRUE, "size" = -1, "mtime" = 0))
		else
			if(!admin_log_valid_segment(entry))
				continue
			var/list/entry_meta = meta?[entry]
			files += list(list(
				"name" = entry,
				"isDir" = FALSE,
				"size" = entry_meta ? entry_meta[1] : admin_log_file_size(dir_path + entry),
				"mtime" = entry_meta ? entry_meta[2] : 0,
			))
	listing = dirs + files
	listing_time = world.time

/// Размеры и mtime всех файлов каталога одним shell-вызовом (только Unix).
/// null - метаданных нет, вызывающий падает на поштучный admin_log_file_size без mtime.
/datum/admin_log_viewer/proc/fetch_listing_meta(dir_path)
	if(world.system_type != UNIX || !is_safe_path_for_admin_shell(dir_path))
		return null
	var/id = "[world.realtime]_[rand(1, 999999)]"
	var/outfile = "data/admin_log_ls_[id].txt"
	var/list/so = world.shelleo("stat -c '%s|%Y|%n' -- [shell_single_quote_path(dir_path)]* > [shell_single_quote_path(outfile)]")
	if(so[SHELLEO_ERRORLEVEL] != 0)
		if(fexists(outfile))
			fdel(outfile)
		return null
	var/raw_meta = rustg_file_read(outfile)
	fdel(outfile)
	var/list/meta = list()
	for(var/line in splittext(raw_meta, "\n"))
		var/list/parts = splittext(line, "|")
		if(length(parts) < 3)
			continue
		// Имя файла может содержать "|" - склеиваем обратно всё после второго разделителя.
		var/full = jointext(parts.Copy(3), "|")
		var/slash = findlasttext(full, "/")
		var/name = slash ? copytext(full, slash + 1) : full
		if(!length(name))
			continue
		meta[name] = list(text2num(parts[1]), text2num(parts[2]))
	return meta

/// Открыть файл по имени из текущего каталога. Имя повторно сверяется с диском.
/datum/admin_log_viewer/proc/try_open_file(name)
	if(!admin_log_valid_segment(name))
		return
	var/list/raw = flist(current_dir_path())
	if(!(name in raw))
		return
	var/static/regex/valid_ext = regex(ADMIN_LOG_EXT_REGEX, "i")
	if(!valid_ext.Find(name))
		to_chat(owner, span_warning("Этот тип файла недоступен для просмотра."), confidential = TRUE)
		return
	reset_file_state()
	current_file = name
	var/path = current_file_path()
	file_size = admin_log_file_size(path)
	if(file_size < 0)
		to_chat(owner, span_warning("Не удалось получить размер файла."), confidential = TRUE)
		current_file = null
		return
	message_admins("[key_name_admin(owner)] accessed file: [path]")
	log_admin("[key_name(owner)] accessed log file [path]")
	load_page(0, already_aligned = TRUE)

/// Фактический размер страницы с учётом режима "весь файл".
/datum/admin_log_viewer/proc/effective_page_bytes()
	if(page_bytes > 0)
		return page_bytes
	return clamp(file_size, ADMIN_LOG_PAGE_BYTES, ADMIN_LOG_WHOLE_PAGE_MAX)

/// Загрузить страницу с байтового смещения. already_aligned - смещение уже указывает
/// на начало строки (начало файла, page_end предыдущей страницы, результат поиска).
/datum/admin_log_viewer/proc/load_page(offset, already_aligned = FALSE)
	var/path = current_file_path()
	if(isnull(path))
		return FALSE
	offset = clamp(offset, 0, max(file_size - 1, 0))
	var/page_size = effective_page_bytes()
	var/chunk
	//крупная страница поднимает и порог чтения целиком: файл в пределах страницы
	//читается rust-g без shell на любой ОС и кэшируется
	if(file_size <= max(ADMIN_LOG_WHOLE_READ_MAX, page_size))
		if(cached_path != path || isnull(cached_content))
			cached_content = rustg_file_read(path)
			cached_path = path
			file_size = length(cached_content)
			offset = clamp(offset, 0, max(file_size - 1, 0))
		chunk = copytext(cached_content, offset + 1, min(offset + page_size, file_size) + 1)
	else
		if(!is_safe_path_for_admin_shell(path))
			to_chat(owner, span_warning("Файл слишком большой, а путь содержит небезопасные символы - доступно только скачивание."), confidential = TRUE)
			return FALSE
		chunk = read_admin_log_chunk(path, offset, page_size)
		if(isnull(chunk))
			to_chat(owner, span_warning("Ошибка чтения файла."), confidential = TRUE)
			return FALSE
	if(!already_aligned)
		var/list/aligned = admin_log_align_page(chunk, offset)
		chunk = aligned[1]
		offset = aligned[2]
	var/list/trimmed = admin_log_trim_page(chunk, offset, file_size)
	page_content = trimmed[1]
	page_start = offset
	page_end = trimmed[2]
	return TRUE

/// Tail доступен только для файлов внутри каталога текущего раунда.
/datum/admin_log_viewer/proc/tail_available()
	if(isnull(current_file) || !istext(GLOB.log_directory))
		return FALSE
	var/round_dir = "[GLOB.log_directory]/"
	return findtext(current_dir_path(), round_dir, 1, length(round_dir) + 1) == 1

/datum/admin_log_viewer/proc/start_tail()
	if(tail_active || !tail_available())
		return
	tail_active = TRUE
	// Одноразовый таймер с самоперевзводом вместо TIMER_LOOP: deltimer изнутри
	// собственного луп-колбэка не отменяет таймер (spent-гард SStimer), плодя зомби-луп
	tail_timer = addtimer(CALLBACK(src, PROC_REF(tail_tick)), ADMIN_LOG_TAIL_PERIOD, TIMER_STOPPABLE)

/datum/admin_log_viewer/proc/stop_tail()
	tail_active = FALSE
	if(tail_timer)
		deltimer(tail_timer)
		tail_timer = null

/datum/admin_log_viewer/proc/tail_tick()
	tail_timer = null
	if(!tail_active || isnull(current_file) || isnull(owner))
		tail_active = FALSE
		return
	var/new_size = admin_log_file_size(current_file_path())
	if(new_size > file_size)
		file_size = new_size
		cached_content = null
		//хвост всегда минимальным окном: перечитывать и переслать мегабайтную
		//"весь файл"-страницу раз в 3 секунды - самоубийство для клиента
		if(!load_page(max(new_size - ADMIN_LOG_PAGE_BYTES, 0), already_aligned = (new_size <= ADMIN_LOG_PAGE_BYTES)))
			tail_active = FALSE
			return
		SStgui.update_uis(src)
	// Стоп мог прийти, пока тик спал в shelleo; а если за это время start_tail
	// уже взвёл свежий таймер - протухший тик не должен взводить второй параллельный
	if(!tail_active || tail_timer)
		return
	tail_timer = addtimer(CALLBACK(src, PROC_REF(tail_tick)), ADMIN_LOG_TAIL_PERIOD, TIMER_STOPPABLE)

/datum/admin_log_viewer/proc/do_search(query)
	var/path = current_file_path()
	if(isnull(path) || !istext(query))
		return
	query = trim(query)
	if(length(query) < 2 || length(query) > 256)
		to_chat(owner, span_warning("Запрос поиска: от 2 до 256 символов."), confidential = TRUE)
		return
	search_query = query
	//порог тот же, что у load_page: файл в пределах страницы ищем в памяти на любой ОС
	if(file_size <= max(ADMIN_LOG_WHOLE_READ_MAX, effective_page_bytes()))
		if(cached_path != path || isnull(cached_content))
			cached_content = rustg_file_read(path)
			cached_path = path
		search_results = admin_log_search_content(cached_content, query)
	else
		var/list/results = admin_log_search_shell(path, query)
		if(isnull(results))
			to_chat(owner, span_warning("Поиск по файлам крупнее 1 МиБ доступен только на Unix-сервере."), confidential = TRUE)
			return
		search_results = results
	log_admin("[key_name(owner)] searched log [path] for: [query]")

/// Скачать текущий каталог одним архивом (рекурсивно): раунд, день или месяц целиком.
/datum/admin_log_viewer/proc/download_archive()
	if(!length(path_segments)) // корень - это все логи сервера разом, такое не архивируем
		return
	var/dir_path = current_dir_path()
	if(!is_safe_path_for_admin_shell(dir_path))
		to_chat(owner, span_warning("Путь каталога содержит небезопасные символы - архивация недоступна."), confidential = TRUE)
		return
	if(owner.file_spam_check())
		return
	cleanup_archive_dir()
	var/rel = copytext(dir_path, length(ADMIN_LOG_ROOT) + 1)
	// Без хвостового "/" - иначе имя архива кончается подчёркиванием.
	var/flat = pathflatten(copytext(rel, 1, length(rel)))
	var/ext = (world.system_type == MS_WINDOWS) ? "zip" : "tar.gz"
	var/out = "[ADMIN_LOG_ARCHIVE_DIR][flat].[ext]"
	var/is_live = istext(GLOB.log_directory) && admin_log_dir_is_live(dir_path, GLOB.log_directory)
	if(GLOB.admin_log_archive_building[out])
		to_chat(owner, span_warning("Архив этого каталога уже собирается - попробуйте через минуту."), confidential = TRUE)
		return
	var/last_build = GLOB.admin_log_archive_builds[rel] || 0
	if(!fexists(out) || (is_live && world.time > last_build + ADMIN_LOG_ARCHIVE_REBUILD_COOLDOWN))
		to_chat(owner, "Собираю архив [rel] - на больших каталогах (день, месяц) это может занять заметное время...", confidential = TRUE)
		// rust-g создаёт недостающие каталоги; tar - нет.
		rustg_file_write("", "[ADMIN_LOG_ARCHIVE_DIR].keep")
		var/cmd
		if(world.system_type == MS_WINDOWS)
			// cmd /c: одинарные кавычки не работают, но наши пути из проверенных сегментов без кавычек внутри.
			cmd = "tar -a -c -f \"[out]\" -C \"[dir_path]\" ."
		else
			cmd = "tar -czf [shell_single_quote_path(out)] -C [shell_single_quote_path(dir_path)] ."
		GLOB.admin_log_archive_building[out] = TRUE
		var/list/so = world.shelleo(cmd) // спит; флаг building закрывает параллельный вход
		GLOB.admin_log_archive_building -= out
		// Итог сборки (чистка битого файла, кэш) обрабатываем до бейла по ушедшему админу,
		// чтобы недособранный архив не оставался в кэше
		if(!admin_log_tar_exit_ok(so[SHELLEO_ERRORLEVEL]) || !fexists(out))
			if(fexists(out))
				fdel(out) // недособранный файл не должен закэшироваться как валидный архив
			if(!QDELETED(src) && !isnull(owner))
				to_chat(owner, span_warning("Не удалось собрать архив (код [so[SHELLEO_ERRORLEVEL]])."), confidential = TRUE)
			return
		GLOB.admin_log_archive_builds[rel] = world.time
	// TTL перевзводится на каждую выдачу, не только на пересборку - иначе кэш-хит может исчезнуть под ftp
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(admin_log_delete_archive), out), ADMIN_LOG_ARCHIVE_TTL, TIMER_UNIQUE | TIMER_OVERRIDE)
	if(QDELETED(src) || isnull(owner)) // админ мог уйти, пока tar работал - архив собран и закэширован, но слать некому
		return
	message_admins("[key_name_admin(owner)] downloaded log archive: [rel]")
	log_admin("[key_name(owner)] downloaded log archive [rel]")
	owner << ftp(file(out), "[flat].[ext]")

/proc/admin_log_delete_archive(path)
	if(fexists(path))
		fdel(path)

/// GNU tar возвращает 1, если файл менялся во время чтения (живой лог текущего раунда) -
/// архив при этом валиден и выбрасывать его нельзя. На Windows у bsdtar код 1 = настоящая ошибка.
/proc/admin_log_tar_exit_ok(errorlevel)
	if(errorlevel == 0)
		return TRUE
	return world.system_type == UNIX && errorlevel == 1

/// Скачать несколько выбранных файлов текущего каталога: один - напрямую через ftp,
/// несколько - одноразовым архивом (уникальное имя, без кэша и лока сборки).
/datum/admin_log_viewer/proc/download_selected(list/names)
	if(!islist(names) || !length(names))
		return
	if(length(names) > ADMIN_LOG_MULTI_SELECT_MAX)
		to_chat(owner, span_warning("За раз можно скачать не больше [ADMIN_LOG_MULTI_SELECT_MAX] файлов - целый каталог удобнее скачать архивом."), confidential = TRUE)
		return
	var/dir_path = current_dir_path()
	var/list/picked = admin_log_filter_selection(names, flist(dir_path))
	if(!length(picked))
		to_chat(owner, span_warning("Выбранные файлы не найдены - обновите список."), confidential = TRUE)
		return
	if(length(picked) == 1)
		var/single = picked[1]
		if(owner.file_spam_check())
			return
		var/single_path = dir_path + single
		message_admins("[key_name_admin(owner)] downloaded file: [single_path]")
		log_admin("[key_name(owner)] downloaded log file [single_path]")
		to_chat(owner, "Отправляю [single] - большой файл может идти несколько минут.", confidential = TRUE)
		owner << ftp(file(single_path), single)
		return
	if(!is_safe_path_for_admin_shell(dir_path))
		to_chat(owner, span_warning("Путь каталога содержит небезопасные символы - архивация недоступна."), confidential = TRUE)
		return
	for(var/name in picked)
		if(!is_safe_path_for_admin_shell(dir_path + name))
			to_chat(owner, span_warning("Имя файла [name] содержит небезопасные символы - уберите его из выбора."), confidential = TRUE)
			return
	var/rel = copytext(dir_path, length(ADMIN_LOG_ROOT) + 1)
	var/flat = pathflatten(rel)
	var/ext = (world.system_type == MS_WINDOWS) ? "zip" : "tar.gz"
	var/out = "[ADMIN_LOG_ARCHIVE_DIR]selected_[flat][world.realtime]_[rand(1, 999999)].[ext]"
	var/list/quoted = list()
	for(var/name in picked)
		// Префикс "./" защищает имена, начинающиеся с дефиса, от разбора как опций tar.
		if(world.system_type == MS_WINDOWS)
			quoted += "\"./[name]\""
		else
			quoted += shell_single_quote_path("./[name]")
	var/cmd
	if(world.system_type == MS_WINDOWS)
		cmd = "tar -a -c -f \"[out]\" -C \"[dir_path]\" [jointext(quoted, " ")]"
	else
		cmd = "tar -czf [shell_single_quote_path(out)] -C [shell_single_quote_path(dir_path)] [jointext(quoted, " ")]"
	if(length(cmd) > ADMIN_LOG_MULTI_CMD_MAX)
		to_chat(owner, span_warning("Слишком длинный список файлов - выберите меньше за раз."), confidential = TRUE)
		return
	if(owner.file_spam_check())
		return
	cleanup_archive_dir()
	// rust-g создаёт недостающие каталоги; tar - нет.
	rustg_file_write("", "[ADMIN_LOG_ARCHIVE_DIR].keep")
	to_chat(owner, "Собираю архив из [length(picked)] файлов...", confidential = TRUE)
	var/list/so = world.shelleo(cmd) // спит; повторный вход придушен file_spam_check выше
	if(!admin_log_tar_exit_ok(so[SHELLEO_ERRORLEVEL]) || !fexists(out))
		if(fexists(out))
			fdel(out)
		if(!QDELETED(src) && !isnull(owner))
			to_chat(owner, span_warning("Не удалось собрать архив (код [so[SHELLEO_ERRORLEVEL]])."), confidential = TRUE)
		return
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(admin_log_delete_archive), out), ADMIN_LOG_ARCHIVE_TTL, TIMER_UNIQUE | TIMER_OVERRIDE)
	if(QDELETED(src) || isnull(owner)) // админ мог уйти, пока tar работал
		return
	message_admins("[key_name_admin(owner)] downloaded [length(picked)] selected log files from [rel]")
	log_admin("[key_name(owner)] downloaded selected log files from [rel]: [jointext(picked, ", ")]")
	owner << ftp(file(out), "selected_[flat][length(picked)]files.[ext]")

/// Одноразовая чистка остатков архивов с прошлого запуска сервера.
/// Зовётся до первой сборки этого запуска, так что удалять можно всё подряд.
/datum/admin_log_viewer/proc/cleanup_archive_dir()
	var/static/cleaned = FALSE
	if(cleaned)
		return
	cleaned = TRUE
	for(var/leftover in flist(ADMIN_LOG_ARCHIVE_DIR))
		if(findtext(leftover, "/", -1))
			continue
		fdel("[ADMIN_LOG_ARCHIVE_DIR][leftover]")

/datum/admin_log_viewer/ui_data(mob/user)
	var/list/data = list()
	data["crumbs"] = path_segments
	data["osUnix"] = (world.system_type == UNIX)
	data["canArchive"] = length(path_segments) > 0
	data["entries"] = listing || list()
	data["searchResults"] = search_results
	data["searchQuery"] = search_query
	if(isnull(current_file))
		data["file"] = null
	else
		var/page_size = effective_page_bytes()
		data["file"] = list(
			"name" = current_file,
			"size" = file_size,
			"pageStart" = page_start,
			"pageEnd" = page_end,
			"pageNum" = min(max(1, CEILING(file_size / page_size, 1)), round(page_start / page_size) + 1),
			"pageCount" = max(1, CEILING(file_size / page_size, 1)),
			"pageBytes" = page_bytes,
			"content" = page_content,
			"tailAvailable" = tail_available(),
			"tailActive" = tail_active,
		)
	return data

/datum/admin_log_viewer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!check_rights(R_SENSITIVE))
		return
	switch(action)
		if("navigate")
			var/name = params["name"]
			if(!admin_log_valid_segment(name))
				return TRUE
			if(!("[name]/" in flist(current_dir_path())))
				return TRUE
			path_segments += name
			reset_file_state()
			refresh_listing(force = TRUE)
			return TRUE
		if("crumb")
			var/index = text2num(params["index"])
			if(isnull(index) || index < 0 || index > length(path_segments))
				return TRUE
			path_segments.Cut(index + 1)
			reset_file_state()
			refresh_listing(force = TRUE)
			return TRUE
		if("go_current_round")
			jump_to(admin_log_segments_for_current_round())
			return TRUE
		if("refresh")
			refresh_listing(force = TRUE)
			if(current_file)
				file_size = admin_log_file_size(current_file_path())
				cached_content = null
				// page_start уже выровнен предыдущим load_page - повторное выравнивание съест первую строку
				load_page(page_start, already_aligned = TRUE)
			return TRUE
		if("open_file")
			try_open_file(params["name"])
			return TRUE
		if("close_file")
			reset_file_state()
			return TRUE
		if("page")
			if(isnull(current_file))
				return TRUE
			if(world.time < last_page_act + 0.5 SECONDS)
				return TRUE
			last_page_act = world.time
			switch(params["dir"])
				if("first")
					load_page(0, already_aligned = TRUE)
				if("next")
					if(page_end < file_size)
						load_page(page_end, already_aligned = TRUE)
				if("prev")
					var/target = max(page_start - effective_page_bytes(), 0)
					load_page(target, already_aligned = (target == 0))
				if("last")
					var/target = max(file_size - effective_page_bytes(), 0)
					load_page(target, already_aligned = (target == 0))
			return TRUE
		if("set_page_size")
			var/new_size = text2num(params["size"])
			//белый список: 256 КиБ / 1 МиБ / 4 МиБ / 0 = весь файл
			if(isnull(new_size) || !(new_size in list(0, ADMIN_LOG_PAGE_BYTES, ADMIN_LOG_PAGE_BYTES * 4, ADMIN_LOG_PAGE_BYTES * 16)))
				return TRUE
			if(new_size == page_bytes)
				return TRUE
			page_bytes = new_size
			if(!isnull(current_file))
				//"весь файл" показываем с начала; при смене размера остаёмся на текущем смещении
				load_page(page_bytes ? page_start : 0, already_aligned = TRUE)
			return TRUE
		if("download_file")
			var/path = current_file_path()
			if(isnull(path))
				return TRUE
			if(owner.file_spam_check())
				return TRUE
			message_admins("[key_name_admin(owner)] downloaded file: [path]")
			log_admin("[key_name(owner)] downloaded log file [path]")
			to_chat(owner, "Отправляю [current_file] - большой файл может идти несколько минут.", confidential = TRUE)
			owner << ftp(file(path), current_file)
			return TRUE
		if("search_file")
			do_search(params["query"])
			return TRUE
		if("clear_search")
			search_results = null
			search_query = ""
			return TRUE
		if("goto_offset")
			var/goto_offset = text2num(params["offset"])
			if(isnull(current_file) || isnull(goto_offset))
				return TRUE
			load_page(clamp(goto_offset, 0, max(file_size - 1, 0)), already_aligned = TRUE)
			return TRUE
		if("toggle_tail")
			if(tail_active)
				stop_tail()
			else
				start_tail()
			return TRUE
		if("download_archive")
			download_archive()
			return TRUE
		if("download_selected")
			download_selected(params["names"])
			return TRUE

/// Сегменты пути каталога текущего раунда, list() при любой странности.
/proc/admin_log_segments_for_current_round()
	var/dir = GLOB.log_directory
	if(!istext(dir) || findtext(dir, ADMIN_LOG_ROOT, 1, length(ADMIN_LOG_ROOT) + 1) != 1)
		return list()
	var/list/out = list()
	for(var/seg in splittext(copytext(dir, length(ADMIN_LOG_ROOT) + 1), "/"))
		if(!length(seg))
			continue
		if(!admin_log_valid_segment(seg))
			return list()
		out += seg
	return out

/// Открыть панель логов, при необходимости создав её, и перейти к сегментам.
/client/proc/open_log_viewer(list/segments)
	if(!check_rights(R_SENSITIVE))
		return
	if(isnull(holder.log_viewer))
		holder.log_viewer = new /datum/admin_log_viewer(src)
	// Холдер переживает реконнект, а BYOND обнуляет ссылку на умерший клиент - переподвязываем всегда
	holder.log_viewer.owner = src
	if(islist(segments))
		holder.log_viewer.jump_to(segments)
	holder.log_viewer.ui_interact(mob)
