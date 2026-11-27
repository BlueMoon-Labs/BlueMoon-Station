#define TGUI_PANEL_MAX_EMOTES 120
#define TGUI_PANEL_MAX_EMOTE_LENGTH 128
#define TGUI_PANEL_MAX_EMOTE_NAME_LENGTH 32
#define TGUI_PANEL_MAX_EMOTE_GROUPS 24
#define SHORT_EMOTE_MAX_LENGTH 40
#define CUSTOM_SHORT_EMOTE_COOLDOWN 0.4 SECONDS
#define CUSTOM_EMOTE_COOLDOWN 1 SECONDS

/*
	Панель эмоутов была переделана, и теперь вместо простого ассоциативного списка `emotes["sigh"] = "вздох"`
	у нас будет один из вариантов:
	 * `emotes["вздох"] = list("type" = 1, "key" = "sigh")`
 	 * `emotes["вздох"] = list("type" = 2, "key" = "sigh", "message_override" = "круто по-кастомну вздыхает")`
	 * `emotes["вздох"] = list("type" = 3, "message" = "круто по-кастомну вздыхает")`
	Где 1, 2 и 3 - TGUI_PANEL_EMOTE_TYPE_DEFAULT, TGUI_PANEL_EMOTE_TYPE_CUSTOM и TGUI_PANEL_EMOTE_TYPE_ME соответственно.
	В чём отличие между вторым и третьим вариантом? Во втором варианте всё ещё будет звук от "sigh". Особенно актуально в
	случае эмоутов с особыми эффектами (щелчками, маниакальным смехом и т.д.)

	Если ты меняешь эту схему, не забудь сделать миграцию в code/modules/client/preferences_savefile.dm.

	Стоит заметить, что all_emotes под это всё не подпадает и всё ещё является ассоциативным списком
	 * all_emotes["sigh"] = объект класса /datum/emote/sound/human/sigh
*/

/datum/tgui_panel
	var/static/list/all_emotes = list()
	var/emotes_chat_revision = 0

//to include only "key" property into the list
/datum/tgui_panel/proc/populate_all_emotes_list()
	if(all_emotes.len)
		return
	for(var/path in subtypesof(/datum/emote))
		var/datum/emote/E = new path()
		if(E.key)
			all_emotes[E.key] = E

/datum/tgui_panel/New(client/client)
	. = ..()
	populate_all_emotes_list()

/datum/tgui_panel/on_message(type, payload, href_list)
	. = ..()

	if (!client?.prefs)
		return

	if(.)
		if(type == "ready")
			emotes_send_chat_panel()
		return

	if(GLOB.chat_emote_panel_enabled)
		return emotes_handle_action(type, payload)

	if(type == "emotes/showHint")
		to_chat(client, span_notice("Быстрые эмоции переехали во вкладку «[STATPANEL_EMOTES_TAB]». В настройках статпанели (⚙ → Эмоции) можно изменить сортировку, размер и цвет кнопок. <a href='?src=[REF(client)];open_statpanel_emotes=1'>Открыть эмоции</a>"))
		return TRUE

/datum/tgui_panel/proc/emotes_handle_action(type, payload, from_statpanel = FALSE)
	var/list/panel = client.prefs.custom_emote_panel

	switch (type)
		if("act/emotes/setOrder")
			var/datum/preferences/prefs = client.prefs
			if(!islist(payload) || payload["slot"] != prefs.default_slot || payload["revision"] != emotes_chat_revision)
				return TRUE
			var/list/order = payload["order"]
			if(!islist(order) || length(order) > length(panel))
				return TRUE
			var/list/clean_order = sanitize_custom_emote_chat_order(order, panel)
			if(length(clean_order) != length(order) || compare_list(clean_order, prefs.custom_emote_chat_order))
				return TRUE
			prefs.custom_emote_chat_order = clean_order
			prefs.save_character(bypass_cooldown = TRUE, silent = TRUE)
			emotes_send_chat_panel()
			return TRUE

		if("act/emotes/resetOrder")
			if(islist(payload) && payload["slot"] == client.prefs.default_slot && payload["revision"] == emotes_chat_revision)
				emotes_reset_order(FALSE)
			return TRUE

		if ("emotes/execute")
			if (!islist(payload))
				return

			var/emote_name = payload["name"]
			if (!emote_name || !istext(emote_name) || !length(emote_name))
				return

			// Я не уверен что нужно ограничивать юзера панелькой,
			// но те кто знают JavaScript, смогут спамить эмоциями
			// даже теми, которых в панели нет, если не будет этой
			// проверки здесь
			if (!(emote_name in panel))
				to_chat(client, span_warning("Эмоции [emote_name] нет в вашей панели!"))
				return FALSE
			var/list/entry = panel[emote_name]
			if (!islist(entry) || isnull(entry["type"]))
				to_chat(client, span_warning("Эмоция [emote_name] не имеет типа!"))
				return FALSE
			var/emote_type = entry["type"]

			if (!isliving(client.mob))
				return TRUE
			var/mob/living/L = client.mob

			switch (emote_type)
				if (TGUI_PANEL_EMOTE_TYPE_DEFAULT)
					var/emote_key = entry["key"]
					L.emote(emote_key, intentional = TRUE)

				// Чтобы люди не спамили пастами из 128 символов со скоростью света
				if (TGUI_PANEL_EMOTE_TYPE_CUSTOM)
					if(L.nextsoundemote >= world.time)
						to_chat(L, span_warning("Не так быстро!"))
						return TRUE
					var/emote_key = entry["key"]
					var/message_override = entry["message_override"]
					L.emote(emote_key, intentional = TRUE, message_override = message_override)
					if (length_char(message_override) > SHORT_EMOTE_MAX_LENGTH)
						L.nextsoundemote = max(L.nextsoundemote, world.time + CUSTOM_EMOTE_COOLDOWN)
					else
						L.nextsoundemote = max(L.nextsoundemote, world.time + CUSTOM_SHORT_EMOTE_COOLDOWN)

				if (TGUI_PANEL_EMOTE_TYPE_ME)
					if(L.nextsoundemote >= world.time)
						to_chat(L, span_warning("Не так быстро!"))
						return TRUE
					var/message = entry["message"]
					L.emote("me", intentional = TRUE, message = message)
					if (length_char(message) > SHORT_EMOTE_MAX_LENGTH)
						L.nextsoundemote = max(L.nextsoundemote, world.time + CUSTOM_EMOTE_COOLDOWN)
					else
						L.nextsoundemote = max(L.nextsoundemote, world.time + CUSTOM_SHORT_EMOTE_COOLDOWN)

			return TRUE

		if ("emotes/create")
			if (length(panel) >= TGUI_PANEL_MAX_EMOTES)
				to_chat(client, span_warning("Добавлен максимум эмоций: [TGUI_PANEL_MAX_EMOTES]."))
				return

			var/mob/user = client.mob
			var/list/emote = list()

			var/emote_type_string = tgui_alert(client.mob, "Какую эмоцию добавить в панель?", "Выбор типа эмоции", list("Обычная", "С кастомным текстом", "*me"))
			if(!emotes_panel_is_current(panel, user))
				return
			if (!emote_type_string)
				to_chat(client, span_warning("Добавление эмоции отменено."))
				return

			var/suggested_name = ""
			switch (emote_type_string)
				if ("Обычная")
					var/emote_key = tgui_input_list(client.mob, "Какую эмоцию добавить в панель?", "Выбор эмоции", all_emotes)
					if(!emotes_panel_is_current(panel, user))
						return
					if (!emote_key)
						to_chat(client, span_warning("Добавление эмоции отменено."))
						return

					if (!(emote_key in all_emotes))
						to_chat(client, span_warning("Эмоция [emote_key] не существует!"))
						return

					suggested_name = emote_key
					emote = list(
						"type" = TGUI_PANEL_EMOTE_TYPE_DEFAULT,
						"key" = emote_key,
					)

				if ("С кастомным текстом")
					var/emote_key = tgui_input_list(client.mob, "Какую эмоцию добавить в панель?", "Выбор эмоции", all_emotes)
					if(!emotes_panel_is_current(panel, user))
						return
					if (!emote_key)
						to_chat(client, span_warning("Добавление эмоции отменено."))
						return

					if (!(emote_key in all_emotes))
						to_chat(client, span_warning("Эмоция [emote_key] не существует!"))
						return

					var/message_override = strip_control_chars(tgui_input_text(client.mob, "Какой кастомный текст будет у эмоции? (максимум - [TGUI_PANEL_MAX_EMOTE_LENGTH] символов)", "Кастомный текст", emote_key, TGUI_PANEL_MAX_EMOTE_LENGTH, TRUE, TRUE))
					if(!emotes_panel_is_current(panel, user))
						return
					if (!message_override)
						to_chat(client, span_warning("Текст \"[message_override]\" не подходит!"))
						return

					suggested_name = emote_key
					emote = list(
						"type" = TGUI_PANEL_EMOTE_TYPE_CUSTOM,
						"key" = emote_key,
						"message_override" = message_override,
					)

				if ("*me")
					var/message = strip_control_chars(tgui_input_text(client.mob, "Какой текст будет у эмоции? (максимум - [TGUI_PANEL_MAX_EMOTE_LENGTH] символов)", "Кастомный текст", "", TGUI_PANEL_MAX_EMOTE_LENGTH, TRUE, TRUE))
					if(!emotes_panel_is_current(panel, user))
						return
					if (!message)
						to_chat(client, span_warning("Текст \"[message]\" не подходит!"))
						return

					suggested_name = copytext_char(message, 1, TGUI_PANEL_MAX_EMOTE_NAME_LENGTH + 1)
					emote = list(
						"type" = TGUI_PANEL_EMOTE_TYPE_ME,
						"message" = message,
					)

			var/emote_name = strip_control_chars(tgui_input_text(client.mob, "Какое название эмоции будет в панели?", "Название эмоции", suggested_name, TGUI_PANEL_MAX_EMOTE_NAME_LENGTH, FALSE, TRUE))
			if(!emotes_panel_is_current(panel, user))
				return
			if (!emote_name)
				to_chat(client, span_warning("Название \"[emote_name]\" не подходит!"))
				return
			if (length(panel) >= TGUI_PANEL_MAX_EMOTES)
				to_chat(client, span_warning("Добавлен максимум эмоций: [TGUI_PANEL_MAX_EMOTES]."))
				return
			if (emote_name in panel)
				to_chat(client, span_warning("Эмоция \"[emote_name]\" уже существует!"))
				return

			panel[emote_name] = emote
			if(length(client.prefs.custom_emote_chat_order))
				client.prefs.custom_emote_chat_order += emote_name
			client.prefs.save_character(TRUE)
			emotes_send_list()

			return TRUE

		if ("emotes/contextAction")
			if (!islist(payload))
				return

			var/emote_name = payload["name"]
			if (!emote_name || !istext(emote_name) || !length(emote_name))
				return

			if (!(emote_name in panel))
				to_chat(client, span_warning("Эмоции [emote_name] нет в вашей панели!"))
				return FALSE
			var/list/entry = panel[emote_name]
			var/emote_type = islist(entry) ? entry["type"] : null

			var/list/actions = list()
			switch (emote_type)
				if (TGUI_PANEL_EMOTE_TYPE_DEFAULT, TGUI_PANEL_EMOTE_TYPE_CUSTOM, TGUI_PANEL_EMOTE_TYPE_ME)
					actions.Add("Переименовать", emote_type == TGUI_PANEL_EMOTE_TYPE_DEFAULT ? "Кастомизировать" : "Изменить текст")
					if(from_statpanel)
						actions += "Цвет кнопки"
						if(entry["color"])
							actions += "Сбросить цвет кнопки"
				else
					to_chat(client, span_warning("Эмоция не имеет типа, поэтому её можно только удалить."))
			actions += "Удалить"

			var/mob/user = client.mob
			var/prompt = "Что вы хотите сделать с эмоцией «[emote_name]»?"
			var/action = from_statpanel ? tgui_input_list(user, prompt, "Выбор действия", actions) : tgui_alert(user, prompt, "Выбор действия", actions)
			if(!emotes_panel_is_current(panel, user) || !(emote_name in panel) || panel[emote_name] != entry)
				return TRUE

			var/changed = FALSE
			switch (action)
				if ("Удалить")
					changed = emotes_remove(emote_name)
				if ("Переименовать")
					changed = emotes_rename(emote_name)
				if ("Кастомизировать", "Изменить текст")
					changed = emotes_change_custom_text(emote_name)
				if ("Цвет кнопки")
					changed = emotes_change_button_color(emote_name, payload["defaultColor"])
				if ("Сбросить цвет кнопки")
					entry -= "color"
					changed = TRUE

			if(changed)
				client.prefs.save_character(TRUE)
				emotes_send_list()
			return TRUE

/datum/tgui_panel/proc/emotes_panel_is_current(list/panel, mob/user)
	return user && client?.mob == user && client.prefs?.custom_emote_panel == panel

/datum/tgui_panel/proc/emotes_reset_order(from_statpanel)
	var/datum/preferences/prefs = client.prefs
	var/list/panel = prefs.custom_emote_panel
	var/list/chat_order = prefs.custom_emote_chat_order
	var/slot = prefs.default_slot
	var/mob/user = client.mob
	var/panel_location = from_statpanel ? "во вкладке «[STATPANEL_EMOTES_TAB]»" : "в панели под звёздочкой"
	var/confirmation = tgui_alert(user, "Сбросить ручной порядок эмоций [panel_location] для персонажа «[prefs.real_name]»? Кнопки будут расположены по алфавиту.", "Сброс порядка эмоций", list("Сбросить", "Отмена"))
	if(confirmation != "Сбросить" || !emotes_panel_is_current(panel, user) || prefs.default_slot != slot)
		return

	if(from_statpanel)
		var/list/sorted_names = sortTim(assoc_list_strip_value(panel), GLOBAL_PROC_REF(cmp_text_asc))
		if(compare_list(panel, sorted_names))
			return
		var/list/sorted_emotes = list()
		for(var/emote_name in sorted_names)
			sorted_emotes[emote_name] = panel[emote_name]
		prefs.custom_emote_panel = sorted_emotes
	else
		if(prefs.custom_emote_chat_order != chat_order || !length(chat_order))
			return
		prefs.custom_emote_chat_order = list()

	prefs.save_character(bypass_cooldown = TRUE, silent = TRUE)
	if(from_statpanel)
		emotes_send_statpanel()
	else
		emotes_send_chat_panel()

/datum/tgui_panel/proc/emotes_rename(emote_name)
	var/mob/user = client.mob
	var/list/panel = client.prefs.custom_emote_panel
	var/entry = panel[emote_name]
	var/new_emote_name = strip_control_chars(tgui_input_text(user, "Выберите новое название эмоции [emote_name]:", "Название эмоции", emote_name, TGUI_PANEL_MAX_EMOTE_NAME_LENGTH, FALSE, TRUE))
	if (!new_emote_name || !emotes_panel_is_current(panel, user) || panel[emote_name] != entry)
		return FALSE
	if (new_emote_name == emote_name)
		to_chat(client, span_notice("Переименование отменено"))
		return
	if (new_emote_name in panel)
		to_chat(client, span_warning("Эмоция \"[new_emote_name]\" уже существует!"))
		return

	if(!change_assoc_key_preserve_index(panel, new_emote_name, emote_name))
		return FALSE
	var/list/order = client.prefs.custom_emote_chat_order
	var/index = order.Find(emote_name)
	if(index)
		order[index] = new_emote_name
	return TRUE

/datum/tgui_panel/proc/emotes_remove(emote_name)
	var/mob/user = client.mob
	var/list/panel = client.prefs.custom_emote_panel
	var/entry = panel[emote_name]
	var/confirmation = tgui_alert(user, "Удалить эмоцию «[emote_name]» из панели?", "Подтверждение", list("Удалить", "Отмена"))
	if (confirmation != "Удалить" || !emotes_panel_is_current(panel, user) || panel[emote_name] != entry)
		return FALSE
	if(!panel.Remove(emote_name))
		return FALSE
	client.prefs.custom_emote_chat_order -= emote_name
	return TRUE

/datum/tgui_panel/proc/emotes_change_custom_text(emote_name)
	var/mob/user = client.mob
	var/list/panel = client.prefs.custom_emote_panel
	var/list/entry = panel[emote_name]
	if (!islist(entry))
		to_chat(client, span_warning("Эмоции [emote_name] нет в вашей панели!"))
		return FALSE

	var/emote_type = entry["type"]
	var/is_me = emote_type == TGUI_PANEL_EMOTE_TYPE_ME
	var/message_field = is_me ? "message" : "message_override"
	var/old_message = entry[message_field]
	var/prompt = is_me ? "Введите текст эмоции «[emote_name]»." : "Введите текст эмоции «[emote_name]». Подтвердите пустое поле, чтобы вернуть стандартный текст."
	var/new_message = tgui_input_text(user, prompt, "Текст эмоции", html_decode(old_message || ""), TGUI_PANEL_MAX_EMOTE_LENGTH, multiline = TRUE, encode = TRUE)
	if(isnull(new_message) || !emotes_panel_is_current(panel, user) || panel[emote_name] != entry || entry["type"] != emote_type || entry[message_field] != old_message)
		return FALSE
	if(!length(new_message))
		if(is_me)
			to_chat(client, span_warning("Для эмоции *me нужен текст."))
			return FALSE
		if(emote_type == TGUI_PANEL_EMOTE_TYPE_DEFAULT)
			return FALSE
		entry["type"] = TGUI_PANEL_EMOTE_TYPE_DEFAULT
		entry -= "message_override"
		return TRUE

	entry[message_field] = new_message
	if(!is_me)
		entry["type"] = TGUI_PANEL_EMOTE_TYPE_CUSTOM
	return TRUE

/datum/tgui_panel/proc/emotes_change_button_color(emote_name, default_color)
	var/mob/user = client.mob
	var/list/panel = client.prefs.custom_emote_panel
	var/list/entry = panel[emote_name]
	var/current_color = entry["color"]
	var/new_color = tgui_input_color(user, "Выберите цвет кнопки «[emote_name]».", "Цвет кнопки эмоции", current_color || default_color)
	if(!new_color || new_color == current_color || !emotes_panel_is_current(panel, user) || panel[emote_name] != entry || entry["color"] != current_color)
		return FALSE
	entry["color"] = new_color
	return TRUE

/datum/tgui_panel/proc/emotes_send_list()
	emotes_send_chat_panel()
	emotes_send_statpanel()

/datum/tgui_panel/proc/emotes_send_chat_panel()
	var/datum/preferences/prefs = client.prefs
	window.send_message("emotes/setList", list(
		"enabled" = GLOB.chat_emote_panel_enabled,
		"list" = prefs.custom_emote_panel,
		"order" = prefs.custom_emote_chat_order,
		"slot" = prefs.default_slot,
		"revision" = ++emotes_chat_revision,
	))

/proc/sanitize_custom_emote_chat_order(list/order, list/panel)
	var/list/cleaned = list()
	if(islist(order))
		for(var/emote_name in order)
			if(istext(emote_name) && (emote_name in panel))
				cleaned |= emote_name
	return cleaned

/datum/tgui_panel/proc/emotes_send_statpanel()
	var/datum/preferences/prefs = client?.prefs
	if(!prefs || !client.statbrowser_ready || client.stat_tab != STATPANEL_EMOTES_TAB)
		return

	// Массивы сохраняют порядок сейва, в том числе для эмоций с числовыми названиями.
	var/list/emotes = list()
	for(var/emote_name in prefs.custom_emote_panel)
		emotes += list(list("name" = emote_name, "entry" = prefs.custom_emote_panel[emote_name]))
	var/list/groups = list()
	var/list/saved_groups = prefs.custom_emote_groups
	var/list/ungrouped = saved_groups[EMOTE_PANEL_UNGROUPED_COLOR_KEY]
	for(var/group_id in saved_groups)
		if(group_id == EMOTE_PANEL_UNGROUPED_COLOR_KEY)
			continue
		var/list/group = saved_groups[group_id]
		groups += list(list("id" = group_id, "name" = html_decode(group["name"]), "color" = group["color"]))
	var/list/payload = list("slot" = prefs.default_slot, "emotes" = emotes, "groups" = groups, "ungroupedColor" = ungrouped?["color"])
	client << output(url_encode(json_encode(payload)), "statbrowser:update_emotes")

/datum/tgui_panel/proc/emotes_handle_stat_action(list/params)
	var/action = params["statpanel_emotes"]
	var/changed = FALSE
	switch(action)
		if("emotes/execute", "emotes/create", "emotes/contextAction")
			return emotes_handle_action(action, params, from_statpanel = TRUE)
		if("emotes/resetOrder")
			return emotes_reset_order(TRUE)
		if("emotes/move")
			changed = emotes_move(params["name"], params["group"] || "", params["anchor"], params["after"] == "1")
		if("emotes/moveGroup")
			var/group_id = params["group"]
			var/anchor = params["anchor"]
			if(!length(group_id) || !length(anchor) || group_id == EMOTE_PANEL_UNGROUPED_COLOR_KEY || anchor == EMOTE_PANEL_UNGROUPED_COLOR_KEY)
				return
			var/list/groups = client.prefs.custom_emote_groups
			var/from_index = groups.Find(group_id)
			var/anchor_index = groups.Find(anchor)
			if(!from_index || !anchor_index || from_index == anchor_index)
				return
			changed = moveElement(groups, from_index, anchor_index + (params["after"] == "1"))
		if("emotes/createGroup")
			changed = emotes_edit_group()
		if("emotes/colorGroup")
			changed = emotes_color_group(params["group"] || EMOTE_PANEL_UNGROUPED_COLOR_KEY, params["defaultColor"], params["reset"] == "1")
		if("emotes/editGroup")
			var/group_id = params["group"]
			if(!length(group_id) || group_id == EMOTE_PANEL_UNGROUPED_COLOR_KEY || !(group_id in client.prefs.custom_emote_groups))
				return
			changed = emotes_edit_group(group_id)
	if(changed)
		client.prefs.save_character(bypass_cooldown = TRUE, silent = TRUE)
		emotes_send_statpanel()

/datum/tgui_panel/proc/emotes_move(emote_name, group_id, anchor, insert_after)
	var/list/panel = client.prefs.custom_emote_panel
	if(!length(emote_name) || !(emote_name in panel))
		return FALSE
	var/list/entry = panel[emote_name]
	if(!islist(entry) || group_id == EMOTE_PANEL_UNGROUPED_COLOR_KEY || (length(group_id) && !(group_id in client.prefs.custom_emote_groups)))
		return FALSE

	var/current_group = entry["group"] || ""
	var/from_index = panel.Find(emote_name)
	var/to_index = length(panel) + 1
	if(length(anchor))
		if(anchor == emote_name || !(anchor in panel))
			return FALSE
		var/list/anchor_entry = panel[anchor]
		if(!islist(anchor_entry) || (anchor_entry["group"] || "") != group_id)
			return FALSE
		to_index = panel.Find(anchor) + insert_after
	else if(current_group == group_id)
		for(var/index in length(panel) to 1 step -1)
			var/list/candidate = panel[panel[index]]
			if(islist(candidate) && (candidate["group"] || "") == group_id)
				to_index = index + 1
				break

	var/moved = moveElement(panel, from_index, to_index)
	if(current_group == group_id)
		return moved
	if(length(group_id))
		entry["group"] = group_id
	else
		entry -= "group"
	return TRUE

/datum/tgui_panel/proc/emotes_edit_group(group_id)
	var/list/groups = client.prefs.custom_emote_groups
	var/list/panel = client.prefs.custom_emote_panel
	var/mob/user = client.mob
	var/list/group = group_id ? groups[group_id] : null
	var/current_name = group?["name"]
	if(group)
		var/action = tgui_alert(user, "Группа «[current_name]»", "Действие с группой", list("Переименовать", "Удалить", "Отмена"))
		if(!emotes_panel_is_current(panel, user) || groups[group_id] != group || group["name"] != current_name)
			return FALSE
		if(action == "Удалить")
			var/confirmation = tgui_alert(user, "Удалить группу «[current_name]»? Её эмоции переместятся в раздел «Без группы».", "Удаление группы", list("Удалить", "Отмена"))
			if(confirmation != "Удалить" || !emotes_panel_is_current(panel, user) || groups[group_id] != group || group["name"] != current_name)
				return FALSE
			for(var/emote_name in panel)
				var/list/entry = panel[emote_name]
				if(islist(entry) && entry["group"] == group_id)
					entry -= "group"
			return groups.Remove(group_id)
		if(action != "Переименовать")
			return FALSE
	else if(length(groups) - (EMOTE_PANEL_UNGROUPED_COLOR_KEY in groups) >= TGUI_PANEL_MAX_EMOTE_GROUPS)
		to_chat(client, span_warning("Добавлен максимум групп: [TGUI_PANEL_MAX_EMOTE_GROUPS]."))
		return FALSE

	var/new_name = trim(tgui_input_text(user, "Введите название группы эмоций.", "Название группы", html_decode(current_name || ""), TGUI_PANEL_MAX_EMOTE_NAME_LENGTH, encode = TRUE))
	if(!length(new_name) || new_name == current_name || !emotes_panel_is_current(panel, user))
		return FALSE
	if(group)
		if(groups[group_id] != group || group["name"] != current_name)
			return FALSE
		group["name"] = new_name
		return TRUE

	for(var/index in 1 to TGUI_PANEL_MAX_EMOTE_GROUPS)
		var/new_id = "[index]"
		if(!(new_id in groups))
			groups[new_id] = list("name" = new_name)
			return TRUE
	to_chat(client, span_warning("Добавлен максимум групп: [TGUI_PANEL_MAX_EMOTE_GROUPS]."))
	return FALSE

/datum/tgui_panel/proc/emotes_color_group(group_id, default_color, reset_color)
	var/list/groups = client.prefs.custom_emote_groups
	var/list/group = groups[group_id]
	var/is_ungrouped = group_id == EMOTE_PANEL_UNGROUPED_COLOR_KEY
	if(!group && !is_ungrouped)
		return FALSE

	if(reset_color)
		if(!group?["color"])
			return FALSE
		if(is_ungrouped)
			return groups.Remove(group_id)
		group -= "color"
		return TRUE

	var/list/panel = client.prefs.custom_emote_panel
	var/mob/user = client.mob
	var/current_color = group?["color"]
	var/new_color = tgui_input_color(user, "Выберите цвет заголовка группы эмоций.", "Цвет группы", current_color || default_color)
	if(!new_color || new_color == current_color || !emotes_panel_is_current(panel, user) || groups[group_id] != group || group?["color"] != current_color)
		return FALSE
	if(is_ungrouped && !group)
		groups[group_id] = list("color" = new_color)
	else
		group["color"] = new_color
	return TRUE

/proc/sanitize_custom_emote_groups(list/groups)
	var/list/cleaned = list()
	if(!islist(groups))
		return cleaned
	for(var/group_id in groups)
		if(!istext(group_id))
			continue
		var/index = text2num(group_id)
		if(isnull(index) || index < 0 || index > TGUI_PANEL_MAX_EMOTE_GROUPS || index != round(index) || group_id != "[index]")
			continue
		var/list/group = groups[group_id]
		if(!islist(group))
			continue
		var/group_color = group["color"]
		if(!istext(group_color) || !GLOB.is_color.Find(group_color))
			group_color = null
		if(group_id == EMOTE_PANEL_UNGROUPED_COLOR_KEY)
			if(group_color)
				cleaned[group_id] = list("color" = uppertext(group_color))
			continue
		if(!istext(group["name"]))
			continue
		var/group_name = trim(copytext_char(strip_control_chars(group["name"]), 1, TGUI_PANEL_MAX_EMOTE_NAME_LENGTH + 1))
		if(length(group_name))
			var/list/clean_group = list("name" = group_name)
			if(group_color)
				clean_group["color"] = uppertext(group_color)
			cleaned[group_id] = clean_group
	return cleaned

/// Rebuilds a custom_emote_panel list with control characters stripped from every
/// emote name (the assoc key) and stored message. Entries whose name becomes empty
/// after cleaning, or collide with an already-cleaned name, are dropped. This both
/// repairs legacy emotes whose control-character names could not round-trip through
/// TGUI (and were therefore impossible to rename or delete) and guards against any
/// such name re-entering the saved data. Always returns a list.
/proc/sanitize_custom_emote_panel(list/panel)
	if(!islist(panel))
		return list()
	var/list/cleaned = list()
	for(var/emote_name in panel)
		var/clean_name = strip_control_chars(emote_name)
		if(!length(clean_name))
			continue // name was entirely control characters - unrecoverable, drop it
		if(clean_name in cleaned)
			continue // a cleaned name already claimed this slot - drop the duplicate
		var/list/emote = panel[emote_name]
		if(islist(emote))
			if(emote["message"])
				emote["message"] = strip_control_chars(emote["message"])
			if(istext(emote["message_override"]) && length(emote["message_override"]))
				emote["message_override"] = strip_control_chars(emote["message_override"])
			if(emote["type"] == TGUI_PANEL_EMOTE_TYPE_CUSTOM && (!istext(emote["message_override"]) || !length(trim(emote["message_override"]))))
				emote["type"] = TGUI_PANEL_EMOTE_TYPE_DEFAULT
				emote -= "message_override"
			var/color = emote["color"]
			if(!istext(color) || !GLOB.is_color.Find(color))
				emote -= "color"
		cleaned[clean_name] = emote
	return cleaned

#undef TGUI_PANEL_MAX_EMOTES
#undef TGUI_PANEL_MAX_EMOTE_LENGTH
#undef TGUI_PANEL_MAX_EMOTE_NAME_LENGTH
#undef TGUI_PANEL_MAX_EMOTE_GROUPS
#undef SHORT_EMOTE_MAX_LENGTH
#undef CUSTOM_SHORT_EMOTE_COOLDOWN
#undef CUSTOM_EMOTE_COOLDOWN
