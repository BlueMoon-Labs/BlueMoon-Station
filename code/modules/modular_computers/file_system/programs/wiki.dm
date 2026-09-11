/**
 * Википедия Nanotrasen — корпоративная энциклопедия
 * Содержит Космический Закон, НРП, гайды и справочники.
 * Доступна через NTNet Downloader (скачиваемая).
 */

/datum/computer_file/program/wiki
	filename = "ntwiki"
	filedesc = "Википедия"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "generic"
	extended_desc = "Корпоративная энциклопедия Nanotrasen: Космический Закон, Нормативы Рабочих Процедур, гайды и справочная информация для экипажа."
	size = 8
	tgui_id = "NtosWiki"
	program_icon = "book-open"
	available_on_ntnet = TRUE
	available_on_syndinet = FALSE
	requires_ntnet = FALSE
	usage_flags = PROGRAM_ALL
	detomatix_resistance = 1

/datum/computer_file/program/wiki/ui_data(mob/user)
	var/list/data = get_header_data()

	var/obj/item/computer_hardware/printer/printer
	var/has_paper = FALSE
	if(computer)
		printer = computer.all_components[MC_PRINT]
		if(computer.stored_paper > 0)
			has_paper = TRUE

	data["have_printer"] = !!printer
	data["can_print"] = !!printer || has_paper

	return data

/datum/computer_file/program/wiki/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("print_article")
			var/title = params["title"]
			var/content = params["content"]
			if(!title || !content)
				return FALSE

			var/obj/item/computer_hardware/printer/printer
			if(computer)
				printer = computer.all_components[MC_PRINT]

			// Try hardware printer first
			if(printer)
				var/print_content = {"<h2>[title]</h2><hr>[content]"}
				if(!printer.print_text(print_content, "Википедия: [title]"))
					to_chat(usr, span_warning("Ошибка принтера: нет бумаги!"))
					return FALSE
				else
					computer.visible_message(span_notice("\The [computer] печатает статью."))
					return TRUE
			else
				// Fallback: try PDA paper storage
				if(computer && computer.stored_paper > 0)
					computer.stored_paper--
					var/obj/item/paper/printed = new /obj/item/paper(get_turf(computer))
					printed.name = "Распечатка: [title]"
					printed.default_raw_text = "<h2>[title]</h2><hr>[content]"
					printed.update_appearance()
					to_chat(usr, span_notice("Распечатано: [title]"))
					return TRUE
				else
					to_chat(usr, span_warning("Нет бумаги или принтера!"))
					return FALSE

			return TRUE

	return FALSE
