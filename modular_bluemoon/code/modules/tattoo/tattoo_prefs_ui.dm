// TGUI интерфейс для просмотра и удаления татуировок в настройках персонажа
// Удаление татуировок применяется только при следующем респауне

/// Датум для управления татуировками через настройки персонажа
/datum/tattoo_manager
	/// Клиент владельца
	var/client/owner_client
	/// Список зон с татуировками помеченными для удаления (zone = list(indexes))
	var/list/pending_removals = list()

/datum/tattoo_manager/New(client/C)
	. = ..()
	owner_client = C
	load_pending_removals()

/datum/tattoo_manager/Destroy(force, ...)
	save_pending_removals()
	owner_client = null
	SStgui.close_uis(src)
	return ..()

/datum/tattoo_manager/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TattooManager")
		ui.open()

/datum/tattoo_manager/ui_state(mob/user)
	return GLOB.always_state

/datum/tattoo_manager/ui_data(mob/user)
	. = list()

	var/list/tattoo_zones = list()
	var/has_tattoos = FALSE
	var/pending_count = 0

	// Доступные цвета чернил
	.["ink_colors"] = get_ink_colors_list()

	// Доступные зоны для татуировок
	.["available_zones"] = get_available_zones_list()

	if(!owner_client?.prefs?.tattoos_string)
		.["tattoo_zones"] = tattoo_zones
		.["has_tattoos"] = FALSE
		.["has_pending_removals"] = FALSE
		.["pending_removal_count"] = 0
		return

	var/list/zone_tattoos = list() // zone = list(list(index, text, etc))

	var/tattoo_index = 0
	for(var/tattoo_line in splittext(owner_client.prefs.tattoos_string, TATTOO_RECORD_SEPARATOR))
		if(!length(tattoo_line))
			continue

		var/list/tattoo_data = splittext(tattoo_line, TATTOO_FIELD_SEPARATOR)
		if(length(tattoo_data) != TATTOO_SAVE_LENGTH)
			continue

		var/zone = tattoo_data[TATTOO_SAVE_ZONE]
		var/raw_text = unescape_tattoo_text(tattoo_data[TATTOO_SAVE_TEXT])

		var/tattoo_sub_index = 0
		for(var/single_tattoo in splittext(raw_text, "; "))
			if(!length(single_tattoo))
				continue

			has_tattoos = TRUE

			var/is_description = findtext(single_tattoo, "\[D\]")
			var/display_text = replacetext(replacetext(single_tattoo, "\[T\]", ""), "\[D\]", "")

			var/color = "#4A4A4A"
			var/color_start = findtext(single_tattoo, "<span style='color:")
			if(color_start)
				var/color_value_start = color_start + length("<span style='color:")
				var/color_end = findtext(single_tattoo, "'", color_value_start)
				if(color_end)
					color = copytext(single_tattoo, color_value_start, color_end)

			display_text = strip_html_tags(display_text)

			// Проверяем, помечена ли для удаления
			var/removal_key = "[zone]_[tattoo_index]_[tattoo_sub_index]"
			var/is_pending = (removal_key in pending_removals) ? TRUE : FALSE
			if(is_pending)
				pending_count++

			if(!zone_tattoos[zone])
				zone_tattoos[zone] = list()

			zone_tattoos[zone] += list(list(
				"index" = "[tattoo_index]_[tattoo_sub_index]",
				"text" = single_tattoo,
				"display_text" = display_text,
				"color" = color,
				"style" = is_description ? "description" : "text",
				"pending_removal" = is_pending
			))

			tattoo_sub_index++

		tattoo_index++

	for(var/zone in zone_tattoos)
		var/zone_name = get_zone_display_name(zone)
		tattoo_zones += list(list(
			"zone" = zone,
			"zone_name" = zone_name,
			"tattoos" = zone_tattoos[zone]
		))

	.["tattoo_zones"] = tattoo_zones
	.["has_tattoos"] = has_tattoos
	.["has_pending_removals"] = length(pending_removals) > 0
	.["pending_removal_count"] = pending_count

/datum/tattoo_manager/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle_removal")
			var/zone = params["zone"]
			var/index = params["index"]
			var/removal_key = "[zone]_[index]"

			if(removal_key in pending_removals)
				pending_removals -= removal_key
			else
				pending_removals += removal_key

			save_pending_removals()
			return TRUE

		if("clear_pending")
			pending_removals = list()
			save_pending_removals()
			return TRUE

		if("add_tattoo")
			var/zone = params["zone"]
			var/text = params["text"]
			var/color = params["color"]
			var/style = params["style"]
			if(!zone || !text || !color || !style)
				return FALSE
			add_tattoo(zone, text, color, style)
			return TRUE

		if("edit_tattoo")
			var/zone = params["zone"]
			var/index = params["index"]
			var/new_text = params["text"]
			var/new_color = params["color"]
			var/new_style = params["style"]
			if(!zone || !index || !new_text || !new_color || !new_style)
				return FALSE
			edit_tattoo(zone, index, new_text, new_color, new_style)
			return TRUE

/// Получает отображаемое имя зоны на русском
/datum/tattoo_manager/proc/get_zone_display_name(zone)
	// Проверяем интимные зоны
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(zone_data)
		return zone_data[TATTOO_DATA_NAME_NOM]

	// Стандартные зоны тела
	switch(zone)
		if(BODY_ZONE_HEAD)
			return "Голова"
		if(BODY_ZONE_CHEST)
			return "Туловище"
		if(BODY_ZONE_PRECISE_GROIN)
			return "Пах"
		if(BODY_ZONE_L_ARM)
			return "Левая рука"
		if(BODY_ZONE_R_ARM)
			return "Правая рука"
		if(BODY_ZONE_L_LEG)
			return "Левая нога"
		if(BODY_ZONE_R_LEG)
			return "Правая нога"

	return zone

/// Загружает список помеченных для удаления татуировок из настроек
/datum/tattoo_manager/proc/load_pending_removals()
	pending_removals = list()
	if(!owner_client?.prefs)
		return

	var/list/saved_removals = owner_client.prefs.pending_tattoo_removals
	if(islist(saved_removals) && length(saved_removals))
		for(var/item in saved_removals)
			pending_removals += item

/// Сохраняет список помеченных для удаления татуировок в настройки
/datum/tattoo_manager/proc/save_pending_removals()
	if(!owner_client?.prefs)
		return

	var/list/new_removals = list()
	for(var/item in pending_removals)
		new_removals += item
	owner_client.prefs.pending_tattoo_removals = new_removals
	owner_client.prefs.save_character()

// Расширение preferences для хранения помеченных для удаления татуировок
/datum/preferences
	var/list/pending_tattoo_removals = list()

/// Применяет удаление помеченных татуировок и очищает список
/datum/preferences/proc/apply_pending_tattoo_removals()
	if(!length(pending_tattoo_removals) || !length(tattoos_string))
		return

	var/list/new_tattoos = list()
	var/tattoo_index = 0

	for(var/tattoo_line in splittext(tattoos_string, TATTOO_RECORD_SEPARATOR))
		if(!length(tattoo_line))
			continue

		var/list/tattoo_data = splittext(tattoo_line, TATTOO_FIELD_SEPARATOR)
		if(length(tattoo_data) != TATTOO_SAVE_LENGTH)
			tattoo_index++
			continue

		var/zone = tattoo_data[TATTOO_SAVE_ZONE]
		var/raw_text = unescape_tattoo_text(tattoo_data[TATTOO_SAVE_TEXT])

		// Фильтруем отдельные татуировки на зоне
		var/list/remaining_tattoos = list()
		var/tattoo_sub_index = 0

		for(var/single_tattoo in splittext(raw_text, "; "))
			if(!length(single_tattoo))
				continue

			var/removal_key = "[zone]_[tattoo_index]_[tattoo_sub_index]"
			if(!(removal_key in pending_tattoo_removals))
				remaining_tattoos += single_tattoo

			tattoo_sub_index++

		// Если остались татуировки на зоне - сохраняем их
		if(length(remaining_tattoos))
			var/new_text = jointext(remaining_tattoos, "; ")
			new_tattoos += "[TATTOO_CURRENT_VERSION][TATTOO_FIELD_SEPARATOR][zone][TATTOO_FIELD_SEPARATOR][escape_tattoo_text(new_text)]"

		tattoo_index++

	tattoos_string = length(new_tattoos) ? jointext(new_tattoos, TATTOO_RECORD_SEPARATOR) + TATTOO_RECORD_SEPARATOR : ""

	pending_tattoo_removals = list()

/// Глобальная переменная для хранения открытых менеджеров татуировок
GLOBAL_LIST_EMPTY(tattoo_managers)

/// Открывает окно управления татуировками для клиента
/client/proc/open_tattoo_manager()
	if(GLOB.tattoo_managers[ckey])
		var/datum/tattoo_manager/old_manager = GLOB.tattoo_managers[ckey]
		qdel(old_manager)

	var/datum/tattoo_manager/manager = new(src)
	GLOB.tattoo_managers[ckey] = manager
	manager.ui_interact(mob)

/// Возвращает список доступных цветов чернил для TGUI (формат list(list("name", "color"), ...))
/proc/get_ink_colors_list()
	var/list/result = list()
	for(var/name in GLOB.tattoo_ink_colors)
		result += list(list("name" = name, "color" = GLOB.tattoo_ink_colors[name]))
	return result

/// Возвращает список доступных зон для TGUI
/proc/get_available_zones_list()
	var/list/zones = list()
	// Стандартные зоны тела
	zones += list(list("id" = BODY_ZONE_HEAD, "name" = "Голова"))
	zones += list(list("id" = TATTOO_ZONE_LIPS, "name" = "Губы"))
	zones += list(list("id" = TATTOO_ZONE_CHEEKS, "name" = "Щёки"))
	zones += list(list("id" = TATTOO_ZONE_FOREHEAD, "name" = "Лоб"))
	zones += list(list("id" = TATTOO_ZONE_CHIN, "name" = "Подбородок"))
	zones += list(list("id" = TATTOO_ZONE_HORNS, "name" = "Рога"))
	zones += list(list("id" = BODY_ZONE_CHEST, "name" = "Туловище"))
	zones += list(list("id" = TATTOO_ZONE_BREASTS, "name" = "Грудь"))
	zones += list(list("id" = BODY_ZONE_PRECISE_GROIN, "name" = "Пах"))
	zones += list(list("id" = TATTOO_ZONE_BUTT, "name" = "Ягодицы"))
	zones += list(list("id" = TATTOO_ZONE_PUSSY, "name" = "Лобок"))
	zones += list(list("id" = TATTOO_ZONE_TESTICLES, "name" = "Яички"))
	zones += list(list("id" = TATTOO_ZONE_PENIS, "name" = "Член"))
	zones += list(list("id" = BODY_ZONE_L_ARM, "name" = "Левая рука"))
	zones += list(list("id" = TATTOO_ZONE_LEFT_HAND, "name" = "Левая кисть"))
	zones += list(list("id" = BODY_ZONE_R_ARM, "name" = "Правая рука"))
	zones += list(list("id" = TATTOO_ZONE_RIGHT_HAND, "name" = "Правая кисть"))
	zones += list(list("id" = BODY_ZONE_L_LEG, "name" = "Левая нога"))
	zones += list(list("id" = TATTOO_ZONE_LEFT_THIGH, "name" = "Левое бедро"))
	zones += list(list("id" = TATTOO_ZONE_LEFT_FOOT, "name" = "Левая ступня"))
	zones += list(list("id" = BODY_ZONE_R_LEG, "name" = "Правая нога"))
	zones += list(list("id" = TATTOO_ZONE_RIGHT_THIGH, "name" = "Правое бедро"))
	zones += list(list("id" = TATTOO_ZONE_RIGHT_FOOT, "name" = "Правая ступня"))
	zones += list(list("id" = TATTOO_ZONE_TAIL, "name" = "Хвост"))
	zones += list(list("id" = TATTOO_ZONE_EARS, "name" = "Уши"))
	zones += list(list("id" = TATTOO_ZONE_WINGS, "name" = "Крылья"))
	zones += list(list("id" = TATTOO_ZONE_BELLY, "name" = "Живот"))
	return zones

/// Добавляет новую татуировку в настройки персонажа
/datum/tattoo_manager/proc/add_tattoo(zone, text, color, style)
	if(!owner_client?.prefs)
		return FALSE

	// Формируем татуировку
	var/style_prefix = style == "text" ? "\[T\]" : "\[D\]"
	var/formatted_tattoo = "<span style='color:[color]'>[style_prefix][html_encode(text)]</span>"

	// Ищем существующую зону в tattoos_string
	var/list/all_tattoos = list()
	var/zone_found = FALSE

	if(length(owner_client.prefs.tattoos_string))
		for(var/tattoo_line in splittext(owner_client.prefs.tattoos_string, TATTOO_RECORD_SEPARATOR))
			if(!length(tattoo_line))
				continue

			var/list/tattoo_data = splittext(tattoo_line, TATTOO_FIELD_SEPARATOR)
			if(length(tattoo_data) != TATTOO_SAVE_LENGTH)
				continue

			var/existing_zone = tattoo_data[TATTOO_SAVE_ZONE]
			var/existing_text = unescape_tattoo_text(tattoo_data[TATTOO_SAVE_TEXT])

			if(existing_zone == zone)
				// Добавляем к существующей зоне
				existing_text = existing_text + "; " + formatted_tattoo
				all_tattoos += "[TATTOO_CURRENT_VERSION][TATTOO_FIELD_SEPARATOR][zone][TATTOO_FIELD_SEPARATOR][escape_tattoo_text(existing_text)]"
				zone_found = TRUE
			else
				all_tattoos += tattoo_line

	// Если зона не найдена - создаём новую запись
	if(!zone_found)
		all_tattoos += "[TATTOO_CURRENT_VERSION][TATTOO_FIELD_SEPARATOR][zone][TATTOO_FIELD_SEPARATOR][escape_tattoo_text(formatted_tattoo)]"

	owner_client.prefs.tattoos_string = length(all_tattoos) ? jointext(all_tattoos, TATTOO_RECORD_SEPARATOR) + TATTOO_RECORD_SEPARATOR : ""
	owner_client.prefs.save_character()
	return TRUE

/// Редактирует существующую татуировку
/datum/tattoo_manager/proc/edit_tattoo(zone, index, new_text, new_color, new_style)
	if(!owner_client?.prefs?.tattoos_string)
		return FALSE

	// Парсим индекс (формат: "tattoo_index_sub_index")
	var/list/index_parts = splittext(index, "_")
	if(length(index_parts) < 2)
		return FALSE

	var/target_tattoo_index = text2num(index_parts[1])
	var/target_sub_index = text2num(index_parts[2])

	// Формируем новую татуировку
	var/style_prefix = new_style == "text" ? "\[T\]" : "\[D\]"
	var/formatted_tattoo = "<span style='color:[new_color]'>[style_prefix][html_encode(new_text)]</span>"

	var/list/all_tattoos = list()
	var/tattoo_index = 0

	for(var/tattoo_line in splittext(owner_client.prefs.tattoos_string, TATTOO_RECORD_SEPARATOR))
		if(!length(tattoo_line))
			continue

		var/list/tattoo_data = splittext(tattoo_line, TATTOO_FIELD_SEPARATOR)
		if(length(tattoo_data) != TATTOO_SAVE_LENGTH)
			tattoo_index++
			continue

		var/existing_zone = tattoo_data[TATTOO_SAVE_ZONE]
		var/raw_text = unescape_tattoo_text(tattoo_data[TATTOO_SAVE_TEXT])

		if(existing_zone == zone && tattoo_index == target_tattoo_index)
			// Нашли нужную зону, теперь редактируем sub_index
			var/list/tattoos_on_zone = splittext(raw_text, "; ")
			var/list/new_tattoos_on_zone = list()
			var/sub_index = 0

			for(var/single_tattoo in tattoos_on_zone)
				if(!length(single_tattoo))
					continue
				if(sub_index == target_sub_index)
					new_tattoos_on_zone += formatted_tattoo
				else
					new_tattoos_on_zone += single_tattoo
				sub_index++

			var/new_zone_text = jointext(new_tattoos_on_zone, "; ")
			all_tattoos += "[TATTOO_CURRENT_VERSION][TATTOO_FIELD_SEPARATOR][zone][TATTOO_FIELD_SEPARATOR][escape_tattoo_text(new_zone_text)]"
		else
			all_tattoos += tattoo_line

		tattoo_index++

	owner_client.prefs.tattoos_string = length(all_tattoos) ? jointext(all_tattoos, TATTOO_RECORD_SEPARATOR) + TATTOO_RECORD_SEPARATOR : ""
	owner_client.prefs.save_character()
	return TRUE
