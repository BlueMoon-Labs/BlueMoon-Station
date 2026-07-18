/// Корень дерева логов - панель никогда не выходит выше него.
#define ADMIN_LOG_ROOT "data/logs/"
/// Размер страницы при постраничном просмотре.
#define ADMIN_LOG_PAGE_BYTES (256 * 1024)
/// Файлы не крупнее этого читаются целиком через rust-g без shell.
#define ADMIN_LOG_WHOLE_READ_MAX (1024 * 1024)
/// Кап совпадений серверного поиска.
#define ADMIN_LOG_SEARCH_MAX_MATCHES 500
/// Кап длины превью совпадения (в символах, не байтах).
#define ADMIN_LOG_SEARCH_PREVIEW_CHARS 300
/// Кап числа файлов в множественном скачивании (полный каталог скачивается архивом).
#define ADMIN_LOG_MULTI_SELECT_MAX 50

/// Валиден ли один сегмент пути (имя файла или каталога, без разделителей).
/proc/admin_log_valid_segment(segment)
	if(!istext(segment) || !length(segment) || length(segment) > 255)
		return FALSE
	if(findtext(segment, "/") || findtext(segment, "\\") || findtext(segment, ".."))
		return FALSE
	if(findtext(segment, "\n") || findtext(segment, ascii2text(13)))
		return FALSE
	return TRUE

/// Фильтрует клиентский список имён для множественного скачивания: без дублей, только
/// валидные сегменты, существующие в raw_listing как файлы (каталоги там с завершающим "/").
/// null - вход не список, пустой или длиннее капа; иначе список уцелевших имён (может быть пуст).
/proc/admin_log_filter_selection(list/names, list/raw_listing)
	if(!islist(names) || !islist(raw_listing))
		return null
	if(!length(names) || length(names) > ADMIN_LOG_MULTI_SELECT_MAX)
		return null
	var/list/picked = list()
	for(var/name in names)
		if(!istext(name) || !admin_log_valid_segment(name))
			continue
		if(!(name in raw_listing))
			continue
		if(name in picked)
			continue
		picked += name
	return picked

/// Живой ли каталог для архивации: его содержимое ещё может расти, потому что он
/// содержит каталог текущего раунда (предок или сам раунд) либо лежит внутри него.
/// dir_path - с завершающим "/", round_dir - без (как GLOB.log_directory).
/proc/admin_log_dir_is_live(dir_path, round_dir)
	if(!istext(dir_path) || !istext(round_dir) || !length(dir_path) || !length(round_dir))
		return FALSE
	var/round_slash = "[round_dir]/"
	if(findtext(round_slash, dir_path, 1, length(dir_path) + 1) == 1)
		return TRUE
	return findtext(dir_path, round_slash, 1, length(round_slash) + 1) == 1

/// Обрезает страницу по последнему переводу строки, если это не конец файла.
/// Возвращает list(текст, конечное_смещение) - смещение первого НЕ включённого байта.
/proc/admin_log_trim_page(chunk, start_offset, total_size)
	var/end_offset = start_offset + length(chunk)
	if(end_offset >= total_size || !length(chunk))
		return list(chunk, end_offset)
	var/last_nl = findlasttext(chunk, "\n")
	if(!last_nl)
		return list(chunk, end_offset)
	return list(copytext(chunk, 1, last_nl + 1), start_offset + last_nl)

/// Отбрасывает хвост строки, разрезанной началом страницы (для страниц не с начала файла).
/// Возвращает list(текст, фактическое_начальное_смещение).
/proc/admin_log_align_page(chunk, start_offset)
	if(start_offset <= 0 || !length(chunk))
		return list(chunk, max(start_offset, 0))
	var/first_nl = findtext(chunk, "\n")
	if(!first_nl)
		return list(chunk, start_offset)
	// Перевод строки последним байтом - тоже разрезанная строка: отдаём пустую страницу с честным смещением
	return list(copytext(chunk, first_nl + 1), start_offset + first_nl)

/// Размер файла в байтах, -1 при ошибке. Нативный length(file()) без чтения содержимого в DM;
/// при нуле перепроверяем шеллом (нулевой размер неотличим от ошибки чтения).
/proc/admin_log_file_size(path)
	if(!fexists(path))
		return -1
	var/native = length(file(path))
	if(isnum(native) && native > 0)
		return native
	if(is_safe_path_for_admin_shell(path))
		return get_admin_log_file_size_bytes(path)
	return isnum(native) ? native : -1

/proc/get_admin_log_file_size_bytes(path)
	if(!fexists(path) || !is_safe_path_for_admin_shell(path))
		return -1
	if(world.system_type == UNIX)
		var/list/so = world.shelleo("stat -c %s [shell_single_quote_path(path)]")
		if(so[1] != 0)
			return -1
		return text2num(trim(so[2]))
	if(world.system_type == MS_WINDOWS)
		var/id = "[world.realtime]_[rand(1, 999999)]"
		var/pathfile = "data/admin_log_szpath_[id].txt"
		var/ps1 = "data/admin_log_sz_[id].ps1"
		rustg_file_write(path, pathfile)
		var/ps_body = jointext(list(
			"$pf = Join-Path (Get-Location) 'data/admin_log_szpath_[id].txt'",
			"$src = (Get-Content -LiteralPath $pf -Raw).Trim()",
			"Write-Output ((Get-Item -LiteralPath $src).Length)",
		), "\n")
		rustg_file_write(ps_body, ps1)
		var/list/so = world.shelleo("powershell -NoProfile -ExecutionPolicy Bypass -File [ps1]")
		fdel(pathfile)
		fdel(ps1)
		if(so[1] != 0)
			return -1
		return text2num(trim(so[2]))
	return -1

/// Поиск подстроки (без регистра) по содержимому, прочитанному целиком.
/// Возвращает список совпадений: line (1-based), offset (байтовое смещение начала строки), preview.
/proc/admin_log_search_content(content, query)
	var/list/results = list()
	if(!istext(content) || !istext(query) || !length(query))
		return results
	var/list/lines = splittext(content, "\n")
	var/offset = 0
	for(var/i in 1 to length(lines))
		var/line_text = lines[i]
		if(findtext(line_text, query))
			results += list(list(
				"line" = i,
				"offset" = offset,
				"preview" = length_char(line_text) > ADMIN_LOG_SEARCH_PREVIEW_CHARS ? copytext_char(line_text, 1, ADMIN_LOG_SEARCH_PREVIEW_CHARS + 1) : line_text,
			))
			if(length(results) >= ADMIN_LOG_SEARCH_MAX_MATCHES)
				break
		offset += length(line_text) + 1
		CHECK_TICK
	return results

/// Поиск по файлу крупнее ADMIN_LOG_WHOLE_READ_MAX. Только Unix: grep с паттерном
/// через временный файл (в командную строку пользовательский ввод не попадает).
/// null - недоступно (Windows/небезопасный путь), иначе список как у admin_log_search_content.
/proc/admin_log_search_shell(path, query)
	if(world.system_type != UNIX)
		return null
	if(!is_safe_path_for_admin_shell(path))
		return null
	var/id = "[world.realtime]_[rand(1, 999999)]"
	var/patfile = "data/admin_log_pat_[id].txt"
	var/outfile = "data/admin_log_grep_[id].txt"
	rustg_file_write(replacetext(replacetext(query, "\n", " "), ascii2text(13), " "), patfile)
	// Статус пайплайна не читаем (он от head и почти всегда 0) - об ошибке судим по отсутствию outfile.
	// -a: логи с бинарными байтами иначе дают "Binary file matches" и парсятся как 0 совпадений.
	world.shelleo("grep -a -F -i -n -b -f [shell_single_quote_path(patfile)] -- [shell_single_quote_path(path)] | head -n [ADMIN_LOG_SEARCH_MAX_MATCHES] > [shell_single_quote_path(outfile)]")
	fdel(patfile)
	if(!fexists(outfile))
		return list()
	var/raw = rustg_file_read(outfile)
	fdel(outfile)
	var/list/results = list()
	for(var/line in splittext(raw, "\n"))
		if(!length(line))
			continue
		// Формат: "номер_строки:байтовое_смещение:текст"; в тексте могут быть свои двоеточия.
		var/first_colon = findtext(line, ":")
		if(!first_colon)
			continue
		var/second_colon = findtext(line, ":", first_colon + 1)
		if(!second_colon)
			continue
		var/line_num = text2num(copytext(line, 1, first_colon))
		var/byte_off = text2num(copytext(line, first_colon + 1, second_colon))
		if(isnull(line_num) || isnull(byte_off))
			continue
		var/text_part = copytext(line, second_colon + 1)
		results += list(list(
			"line" = line_num,
			"offset" = byte_off,
			"preview" = length_char(text_part) > ADMIN_LOG_SEARCH_PREVIEW_CHARS ? copytext_char(text_part, 1, ADMIN_LOG_SEARCH_PREVIEW_CHARS + 1) : text_part,
		))
	return results

/// Читает не более max_bytes с диска начиная с offset_bytes без загрузки всего файла в DM
/// (Unix: tail+head; Windows: PowerShell-скрипт с Seek). Имена временных файлов не пересекаются
/// с остальными admin_log-хелперами.
/proc/read_admin_log_chunk(path, offset_bytes, max_bytes)
	if(!fexists(path) || !is_safe_path_for_admin_shell(path))
		return null
	if(world.system_type == UNIX)
		var/tmp = "data/admin_log_chunk_view_[world.realtime]_[rand(1, 999999)].tmp"
		// num2text с 12 знаками: дефолтные 6 значащих цифр BYOND превращают смещения >= 1e6 в "1.04858e+06"
		var/list/so = world.shelleo("tail -c +[num2text(offset_bytes + 1, 12)] [shell_single_quote_path(path)] | head -c [num2text(max_bytes, 12)] > [shell_single_quote_path(tmp)]")
		if(so[1] != 0)
			if(fexists(tmp))
				fdel(tmp)
			return null
		if(!fexists(tmp))
			return null
		var/chunk = file2text(tmp)
		fdel(tmp)
		return chunk
	if(world.system_type == MS_WINDOWS)
		var/id = "[world.realtime]_[rand(1, 999999)]"
		var/pathfile = "data/admin_log_chunk_path_[id].txt"
		var/outfile = "data/admin_log_chunk_out_[id].tmp"
		var/ps1 = "data/admin_log_chunk_read_[id].ps1"
		rustg_file_write(path, pathfile)
		// $ и [] в тексте PS собираем через ascii2text — иначе dreamchecker ломает разбор строк.
		var/ps_dollar = ascii2text(36)
		var/ps_dot = ascii2text(46)
		var/ps_dq = ascii2text(34)
		var/ps_lb = ascii2text(91)
		var/ps_rb = ascii2text(93)
		var/ps_body = jointext(list(
			ps_dollar + "pf = Join-Path (Get-Location) " + ps_dq + "data/admin_log_chunk_path_" + id + ".txt" + ps_dq,
			ps_dollar + "out = Join-Path (Get-Location) " + ps_dq + "data/admin_log_chunk_out_" + id + ".tmp" + ps_dq,
			ps_dollar + "max = " + num2text(max_bytes, 12),
			ps_dollar + "src = (Get-Content -LiteralPath " + ps_dollar + "pf -Raw).Trim()",
			ps_dollar + "fs = " + ps_lb + "System" + ps_dot + "IO" + ps_dot + "File" + ps_rb + "::OpenRead(" + ps_dollar + "src)",
			"try {",
			"  " + ps_dollar + "null = " + ps_dollar + "fs" + ps_dot + "Seek(" + num2text(offset_bytes, 12) + ", \[System" + ps_dot + "IO" + ps_dot + "SeekOrigin\]::Begin)",
			"  " + ps_dollar + "buf = New-Object byte" + ps_lb + ps_rb + " " + ps_dollar + "max",
			"  " + ps_dollar + "r = " + ps_dollar + "fs" + ps_dot + "Read(" + ps_dollar + "buf, 0, " + ps_dollar + "buf" + ps_dot + "Length)",
			"  if (" + ps_dollar + "r -gt 0) {",
			"    " + ps_dollar + "slice = New-Object byte" + ps_lb + ps_rb + " " + ps_dollar + "r",
			"    " + ps_lb + "Array" + ps_rb + "::Copy(" + ps_dollar + "buf, " + ps_dollar + "slice, " + ps_dollar + "r)",
			"    " + ps_lb + "System" + ps_dot + "IO" + ps_dot + "File" + ps_rb + "::WriteAllBytes(" + ps_dollar + "out, " + ps_dollar + "slice)",
			"  } else {",
			"    " + ps_lb + "System" + ps_dot + "IO" + ps_dot + "File" + ps_rb + "::WriteAllBytes(" + ps_dollar + "out, (New-Object byte" + ps_lb + ps_rb + " 0))",
			"  }",
			"} finally {",
			"  " + ps_dollar + "fs" + ps_dot + "Dispose()",
			"}",
		), "\n")
		rustg_file_write(ps_body, ps1)
		var/list/so = world.shelleo("powershell -NoProfile -ExecutionPolicy Bypass -File [ps1]")
		fdel(pathfile)
		fdel(ps1)
		if(so[1] != 0)
			if(fexists(outfile))
				fdel(outfile)
			return null
		if(!fexists(outfile))
			return null
		var/outchunk = file2text(outfile)
		fdel(outfile)
		return outchunk
	return null
