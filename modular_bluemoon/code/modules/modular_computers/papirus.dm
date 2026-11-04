// BLUEMOON ADD - Папирус: редактор документов для ноутбуков, ПДА и консолей с печатью на принтер компьютера.

/// Сколько блоков может быть в одном документе.
#define PAPIRUS_MAX_BLOCKS 60
/// Сколько символов может быть в одном блоке.
#define PAPIRUS_MAX_BLOCK_TEXT 2000
/// Сколько пользовательских шаблонов хранит программа.
#define PAPIRUS_MAX_TEMPLATES 15
/// Задержка между печатью листов.
#define PAPIRUS_PRINT_COOLDOWN (2 SECONDS)

/datum/computer_file/program/papirus
	filename = "papirus"
	filedesc = "Папирус"
	category = PROGRAM_CATEGORY_DEVICE
	program_icon_state = "generic"
	extended_desc = "Редактор служебных документов: шаблоны, разметка, подпись по ID-карте и печать на встроенный принтер."
	size = 4
	tgui_id = "NtosPapirus"
	program_icon = "scroll"
	usage_flags = PROGRAM_ALL

	/// Название документа, оно же название напечатанного листа.
	var/doc_title = "Рапорт"
	/// Блоки документа: list(id, type, align, text).
	var/list/blocks = list()
	/// Пользовательские шаблоны: list(name, title, blocks).
	var/list/user_templates = list()
	/// Заполнять подпись, должность, дату и время при печати.
	var/autofill = TRUE
	/// Счётчик для id блоков (нужен tgui как стабильный ключ).
	var/next_block_id = 1
	/// Растёт, когда документ заменяет сервер (шаблон, новый документ): тогда интерфейс берёт документ отсюда.
	/// Пока человек печатает, документ живёт в интерфейсе и только присылается сюда.
	var/revision = 1
	COOLDOWN_DECLARE(print_cooldown)

/datum/computer_file/program/papirus/New(obj/item/modular_computer/comp)
	. = ..()
	load_blocks(builtin_template("report"))

/datum/computer_file/program/papirus/clone(rename = FALSE)
	var/datum/computer_file/program/papirus/copy = ..()
	copy.doc_title = doc_title
	copy.load_blocks(blocks)
	for(var/list/template in user_templates)
		copy.user_templates += list(deepCopyList(template))
	copy.autofill = autofill
	return copy

/// Блок документа.
/datum/computer_file/program/papirus/proc/make_block(block_type = "p", text = "", align = "left", id)
	if(!isnum(id))
		id = next_block_id
	next_block_id = max(next_block_id, id) + 1
	return list("id" = id, "type" = block_type, "align" = align, "text" = text)

/**
 * Заменяет документ проверенной копией блоков (из шаблона или из интерфейса).
 *
 * * keep_ids - оставить id блоков (документ пришёл из интерфейса и остаётся там же)
 */
/datum/computer_file/program/papirus/proc/load_blocks(list/source, keep_ids = FALSE)
	var/static/list/block_types = list("p", "h1", "h2", "h3", "list", "hr", "spacer")
	var/static/list/aligns = list("left", "center", "right")
	blocks = list()
	for(var/list/block in source)
		if(!islist(block))
			continue
		if(length(blocks) >= PAPIRUS_MAX_BLOCKS)
			break
		var/block_type = block["type"]
		if(!(block_type in block_types))
			continue
		var/align = block["align"]
		if(!(align in aligns))
			align = "left"
		var/text = block["text"]
		text = istext(text) ? copytext_char(text, 1, PAPIRUS_MAX_BLOCK_TEXT + 1) : ""
		blocks += list(make_block(block_type, text, align, keep_ids ? block["id"] : null))
	if(!keep_ids)
		revision++

/// Название от клиента: без HTML (оно уходит в имя бумаги, чат и лог) и не длиннее MAX_NAME_LEN символов.
/datum/computer_file/program/papirus/proc/clean_name(raw)
	if(!istext(raw))
		return ""
	// Сначала вычищаем теги по всей строке, потом режем по символам: strip_html_simple режет байтами.
	return trim(copytext_char(strip_html_simple(raw, length(raw) + 1), 1, MAX_NAME_LEN))

/// Принимает документ из интерфейса (JSON: title, blocks).
/datum/computer_file/program/papirus/proc/sync_from_ui(raw)
	if(!istext(raw) || length(raw) > 200000)
		return FALSE
	var/list/doc = json_decode(raw)
	if(!islist(doc))
		return FALSE
	if(istext(doc["title"]))
		doc_title = clean_name(doc["title"])
	if(islist(doc["blocks"]))
		load_blocks(doc["blocks"], keep_ids = TRUE)
	return TRUE

/// Встроенные шаблоны. Токены в фигурных скобках превращаются в поля при печати.
/datum/computer_file/program/papirus/proc/builtin_templates()
	return list(
		list("id" = "report", "name" = "Рапорт", "title" = "Рапорт"),
		list("id" = "order", "name" = "Приказ", "title" = "Приказ"),
		list("id" = "pass", "name" = "Пропуск", "title" = "Пропуск"),
		list("id" = "statement", "name" = "Заявление", "title" = "Заявление"),
	)

/datum/computer_file/program/papirus/proc/builtin_template(id)
	switch(id)
		if("report")
			return list(
				list("type" = "p", "align" = "right", "text" = "Кому: {поле}\nОт: {поле}"),
				list("type" = "h1", "align" = "center", "text" = "РАПОРТ"),
				list("type" = "hr"),
				list("type" = "p", "align" = "left", "text" = "Настоящим докладываю, что {поле}"),
				list("type" = "spacer"),
				list("type" = "p", "align" = "left", "text" = "Дата: {дата}, время: {время}\nДолжность: {должность}\nПодпись: {подпись}"),
			)
		if("order")
			return list(
				list("type" = "h2", "align" = "center", "text" = "NanoTrasen"),
				list("type" = "p", "align" = "center", "text" = "*Космическая станция 13*"),
				list("type" = "hr"),
				list("type" = "h1", "align" = "center", "text" = "ПРИКАЗ № {поле}"),
				list("type" = "p", "align" = "left", "text" = "**Приказываю:**"),
				list("type" = "list", "align" = "left", "text" = "Первый пункт\nВторой пункт"),
				list("type" = "p", "align" = "left", "text" = "Ответственный: {поле}"),
				list("type" = "spacer"),
				list("type" = "p", "align" = "right", "text" = "{должность}: {подпись}\n{дата} {время}"),
			)
		if("pass")
			return list(
				list("type" = "h2", "align" = "center", "text" = "ПРОПУСК"),
				list("type" = "hr"),
				list("type" = "p", "align" = "left", "text" = "Выдан: {поле}\nДолжность: {поле}\nДоступ в: {поле}\nДействителен до: {поле}"),
				list("type" = "hr"),
				list("type" = "p", "align" = "left", "text" = "Выдал: {должность}\nПодпись: {подпись}\nДата: {дата}"),
			)
		if("statement")
			return list(
				list("type" = "p", "align" = "right", "text" = "Главе персонала\nот {должность}\n{подпись}"),
				list("type" = "h1", "align" = "center", "text" = "ЗАЯВЛЕНИЕ"),
				list("type" = "p", "align" = "left", "text" = "Прошу {поле}"),
				list("type" = "spacer"),
				list("type" = "p", "align" = "right", "text" = "{дата}\nПодпись: {подпись}"),
			)
	return list()

/**
 * Собирает Markdown для бумаги.
 *
 * * fills - если передан список, в него записывается номер поля => что в него вписать при печати
 * ("sign", "job", "date", "time"). Номера полей совпадают с тем, как их считает бумага: по порядку, с нуля.
 */
/datum/computer_file/program/papirus/proc/generate(list/fills)
	var/static/regex/token_regex = new(@"\[_+\]|\{(поле|подпись|должность|дата|время)\}", "g")
	var/static/list/token_fills = list("подпись" = "sign", "должность" = "job", "дата" = "date", "время" = "time")
	// Ширина поля на бумаге = число подчёркиваний: под имя, должность и дату нужно место, иначе текст обрезается.
	var/static/list/token_widths = list("поле" = 20, "подпись" = 26, "должность" = 26, "дата" = 18, "время" = 10)
	var/field_index = 0
	var/list/parts = list()
	for(var/list/block in blocks)
		var/block_type = block["type"]
		if(block_type == "hr")
			parts += "---"
			continue
		if(block_type == "spacer")
			parts += "<br>"
			continue

		// Поля и токены по порядку: так номер поля совпадёт с номером на бумаге.
		var/text = block["text"]
		var/out = ""
		var/last = 1
		while(token_regex.Find(text, last))
			out += copytext(text, last, token_regex.index)
			var/token = token_regex.group[1]
			if(token && token_fills[token] && fills)
				fills["[field_index]"] = token_fills[token]
			out += token ? "\[[repeat_string(token_widths[token], "_")]\]" : token_regex.match
			field_index++
			last = token_regex.next
		out += copytext(text, last)

		switch(block_type)
			if("h1")
				out = "# [replacetext(out, "\n", " ")]"
			if("h2")
				out = "## [replacetext(out, "\n", " ")]"
			if("h3")
				out = "### [replacetext(out, "\n", " ")]"
			if("list")
				var/list/items = list()
				for(var/line in splittext(out, "\n"))
					if(length(trim(line)))
						items += "- [line]"
				out = jointext(items, "\n")

		// Пустые строки вокруг тега нужны, чтобы Markdown внутри него разбирался.
		switch(block["align"])
			if("center")
				out = "<center>\n\n[out]\n\n</center>"
			if("right")
				out = "<div align=\"right\">\n\n[out]\n\n</div>"
		parts += out
	return jointext(parts, "\n\n")

/datum/computer_file/program/papirus/proc/get_printer()
	return computer?.all_components[MC_PRINT]

/// Печатает документ. Возвращает текст ошибки или null.
/datum/computer_file/program/papirus/proc/print_document(mob/user)
	var/obj/item/computer_hardware/printer/printer = get_printer()
	if(!printer)
		return "Принтер не установлен."
	if(!printer.check_functionality())
		return "Принтер не отвечает."
	if(printer.stored_paper <= 0)
		return "В принтере нет бумаги."
	if(!COOLDOWN_FINISHED(src, print_cooldown))
		return "Принтер ещё печатает."

	var/list/fills = list()
	var/text = generate(fills)
	if(!length(trim(text)))
		return "Документ пуст."
	if(length_char(text) > MAX_PAPER_LENGTH)
		return "Документ не помещается на лист: [length_char(text)] из [MAX_PAPER_LENGTH] символов."

	COOLDOWN_START(src, print_cooldown, PAPIRUS_PRINT_COOLDOWN)
	var/damaged = printer.damage > printer.damage_malfunction
	if(damaged)
		text = stars(text, 100 - printer.malfunction_probability)

	var/obj/item/paper/paper = new(printer.holder.drop_location())
	paper.add_raw_text(text, PRINTER_FONT)
	paper.name = length(trim(doc_title)) ? "бумага - '[doc_title]'" : "бумага"

	if(autofill && !damaged)
		var/obj/item/card/id/id_card = computer.GetID()
		for(var/field_id in fills)
			switch(fills[field_id])
				if("sign")
					if(id_card?.registered_name)
						paper.add_field_input(user, field_id, "%sign", PRINTER_FONT, null, FALSE, id_card.registered_name)
				if("job")
					var/job = id_card?.get_assignment_name()
					if(job)
						paper.add_field_input(user, field_id, job, PRINTER_FONT, null, FALSE)
				if("date")
					paper.add_field_input(user, field_id, "%date", PRINTER_FONT, null, FALSE)
				if("time")
					paper.add_field_input(user, field_id, "%time", PRINTER_FONT, null, FALSE)

	paper.update_appearance()
	printer.stored_paper--
	playsound(computer.physical || computer, 'sound/effects/printer.ogg', 50, TRUE)
	log_paper("[key_name(user)] printed a Papirus document \"[doc_title]\" from [computer]: [text]")
	return null


/datum/computer_file/program/papirus/ui_data(mob/user)
	var/list/data = get_header_data()
	data["doc"] = list("title" = doc_title, "blocks" = blocks)
	data["revision"] = revision
	data["autofill"] = autofill
	data["code"] = generate()
	data["max_length"] = MAX_PAPER_LENGTH
	data["max_block_text"] = PAPIRUS_MAX_BLOCK_TEXT
	data["max_blocks"] = PAPIRUS_MAX_BLOCKS

	var/obj/item/computer_hardware/printer/printer = get_printer()
	data["has_printer"] = !!printer
	data["paper"] = printer ? printer.stored_paper : 0
	data["max_paper"] = printer ? printer.max_paper : 0

	var/obj/item/card/id/id_card = computer?.GetID()
	data["id_name"] = id_card?.registered_name
	data["id_job"] = id_card?.get_assignment_name()

	data["builtin_templates"] = builtin_templates()
	var/list/templates = list()
	for(var/list/template in user_templates)
		templates += list(list("name" = template["name"]))
	data["user_templates"] = templates
	return data

/datum/computer_file/program/papirus/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = usr
	// Печать и сохранение шаблона приносят с собой свежий документ, чтобы не ждать синхронизации.
	if(params["doc"])
		sync_from_ui(params["doc"])
	switch(action)
		if("sync")
			return TRUE
		if("new_doc")
			doc_title = "Документ"
			load_blocks(list(list("type" = "p", "align" = "left", "text" = "")))
			return TRUE
		if("load_builtin")
			var/id = params["id"]
			for(var/list/template in builtin_templates())
				if(template["id"] == id)
					doc_title = template["title"]
					load_blocks(builtin_template(id))
					return TRUE
			return
		if("load_template")
			var/index = text2num(params["index"])
			if(isnull(index) || index < 0 || index >= length(user_templates))
				return
			var/list/template = user_templates[round(index) + 1]
			doc_title = template["title"]
			load_blocks(template["blocks"])
			return TRUE
		if("save_template")
			var/name = clean_name(params["name"])
			if(!length(name))
				return
			var/list/template = list("name" = name, "title" = doc_title, "blocks" = deepCopyList(blocks))
			for(var/i in 1 to length(user_templates))
				if(user_templates[i]["name"] == name)
					user_templates[i] = template
					return TRUE
			if(length(user_templates) >= PAPIRUS_MAX_TEMPLATES)
				to_chat(user, span_warning("Память шаблонов заполнена: не больше [PAPIRUS_MAX_TEMPLATES]."))
				return TRUE
			user_templates += list(template)
			return TRUE
		if("delete_template")
			var/index = text2num(params["index"])
			if(isnull(index) || index < 0 || index >= length(user_templates))
				return
			user_templates.Cut(round(index) + 1, round(index) + 2)
			return TRUE
		if("toggle_autofill")
			autofill = !autofill
			return TRUE
		if("print")
			var/error = print_document(user)
			if(error)
				to_chat(user, span_warning("Папирус: [error]"))
			else
				var/atom/movable/device = computer.physical || computer
				device.visible_message(span_notice("[device] печатает документ."))
			return TRUE

#undef PAPIRUS_MAX_BLOCKS
#undef PAPIRUS_MAX_BLOCK_TEXT
#undef PAPIRUS_MAX_TEMPLATES
#undef PAPIRUS_PRINT_COOLDOWN
