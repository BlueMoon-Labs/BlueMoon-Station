/**
 * Отрисовка меню действий браузером: элемент скина mainwindow.context_menu поверх карты, как тултипы.
 *
 * maptext BYOND - битмап без ClearType, мелкий текст в нём ступенчатый при любом шрифте и зуме.
 * Браузер рисует текст как остальной интерфейс. Позицию у курсора страница считает сама по размеру
 * и зуму карты (winget), клик по строке приходит в Topic меню.
 */
/client
	/// Когда клиенту отправлена страница меню; до её загрузки показ откладывается
	var/context_menu_page_sent_at

/// Страница меню едет клиенту один раз за сессию
/client/proc/send_context_menu_page()
	if(context_menu_page_sent_at)
		return
	var/static/page
	if(!page)
		page = file2text('modular_bluemoon/code/modules/context_menu/context_menu.html')
	src << browse(page, "window=[CONTEXT_MENU_HTML_CONTROL]")
	context_menu_page_sent_at = world.time

/datum/context_menu
	/// Пункты в порядке строк браузерного меню: по номеру из Topic находится пункт
	var/list/datum/context_menu_entry/html_rows
	/// Браузерное меню показано, при закрытии его надо спрятать
	var/html_shown = FALSE

/// Браузерное меню у этого игрока: выбрано в настройках и есть клиент (load_style)
/datum/context_menu/proc/html_renderer()
	return use_html

/datum/context_menu/proc/render_html()
	var/client/viewer = user.client
	viewer.send_context_menu_page()
	var/wait = viewer.context_menu_page_sent_at + CONTEXT_MENU_HTML_PAGE_GRACE - world.time
	if(wait > 0)
		addtimer(CALLBACK(src, PROC_REF(render)), wait, TIMER_UNIQUE|TIMER_OVERRIDE)
		return
	var/header = header_text || (target ? context_menu_name(target.name) : "На клетке")
	header_entry = new /datum/context_menu_entry/mode_choice(header)
	// в браузере список прокручивается, страниц нет; закреплённое - в конце
	var/list/pinned = pinned_entries()
	html_rows = (entries - pinned) + pinned
	page_entry = null
	var/list/rows = list()
	var/rows_have_icons = FALSE
	// новый значок - icon() и base64, в большой куче это десятки мс за раз: сверх бюджета их дорисует следующий показ
	var/icon_deadline = TICK_USAGE + CONTEXT_MENU_HTML_ICON_BUDGET
	var/icons_pending = FALSE
	for(var/datum/context_menu_entry/entry as anything in html_rows)
		var/icon_data
		if(show_icons)
			var/atom/icon_source = entry.icon_source()
			if(TICK_USAGE < icon_deadline || context_menu_icon_cached(icon_source))
				icon_data = context_menu_icon_base64(icon_source)
			else
				icons_pending = TRUE
		if(icon_data)
			rows_have_icons = TRUE
		rows += list(list("name" = entry_display_name(entry), "hint" = entry.hint, "style" = entry.style, "icon" = icon_data))
	var/list/view_pixels = view_to_pixels(viewer.view || world.view)
	var/list/style = user.context_menu_prefs()?.context_menu_style
	var/list/data = list(
		"ref" = REF(src),
		"control" = CONTEXT_MENU_HTML_CONTROL,
		"header" = show_header,
		"header_text" = header,
		"rows" = rows,
		"theme" = theme,
		"accent" = accent,
		"accent_custom" = context_menu_style_option(style, "accent"),
		"font" = context_menu_style_option(style, "font"),
		"weight" = context_menu_style_option(style, "weight"),
		"layout" = context_menu_style_option(style, "layout"),
		"width" = context_menu_style_option(style, "width"),
		"hover" = context_menu_style_option(style, "hover"),
		"icons" = show_icons,
		"rows_have_icons" = rows_have_icons,
		"icon_size" = context_menu_style_option(style, "icon_size"),
		"icon_side" = context_menu_style_option(style, "icon_side"),
		"text_size" = context_menu_style_option(style, "text_size"),
		"hint_style" = context_menu_style_option(style, "hint_style"),
		"header_icon_data" = (show_icons && context_menu_style_option(style, "header_icon")) ? context_menu_icon_base64(target) : null,
		"header_desc" = context_menu_style_option(style, "desc_line") == "none" ? null : target?.desc,
		"desc_line" = context_menu_style_option(style, "desc_line") == "line",
		"zebra" = context_menu_style_option(style, "zebra"),
		"header_style" = context_menu_style_option(style, "header_style"),
		"icon_frame" = context_menu_style_option(style, "icon_frame"),
		"auto_close" = context_menu_style_option(style, "auto_close"),
		"offset" = cursor_offset,
		"scale" = scale * 100,
		"density" = density_padding,
		"hints" = hints_mode,
		"position" = position,
		"border" = show_border,
		"stripe" = show_stripe,
		"separators" = row_gap,
		"caps" = caps,
		"outline" = text_outline,
		"smooth_hover" = smooth_hover,
		"animation" = opened ? "none" : animation,
		"anim_speed" = animation_speed,
		// список клетки листают в поисках вещи: видно больше строк, чем у действий
		"page_rows" = rows_per_page(),
		"origin_x" = origin_x,
		"origin_y" = origin_y,
		"view_w" = view_pixels[1],
		"view_h" = view_pixels[2],
	)
	if(!opened)
		play_menu_sound()
	opened = TRUE
	html_shown = TRUE
	viewer << output(list2params(list(json_encode(data))), "[CONTEXT_MENU_HTML_CONTROL]:menu.show")
	if(icons_pending)
		addtimer(CALLBACK(src, PROC_REF(render)), 1, TIMER_UNIQUE|TIMER_OVERRIDE)

/datum/context_menu/proc/hide_html()
	if(!html_shown)
		return
	html_shown = FALSE
	if(user?.client)
		user.client << output(null, "[CONTEXT_MENU_HTML_CONTROL]:menu.hide")
		winshow(user.client, CONTEXT_MENU_HTML_CONTROL, FALSE)

/// Клик по строке браузерного меню: choose - номер строки с 1, header - шапка; ctrl/shift/alt - модификаторы клика
/datum/context_menu/Topic(href, list/href_list)
	if(usr != user || QDELETED(src))
		return
	if(href_list["header"])
		choose(header_entry)
		return
	// курсор давно ушёл с меню (auto_close)
	if(href_list["close"])
		close_reason = "auto_close"
		qdel(src)
		return
	var/index = text2num(href_list["choose"])
	if(!index || index < 1 || index > length(html_rows))
		return
	var/datum/context_menu_entry/entry = html_rows[index]
	var/list/modifiers = list()
	for(var/key in list("ctrl", "shift", "alt", "right"))
		if(text2num(href_list[key]))
			modifiers[key] = 1
	click_row(entry, modifiers)

/**
 * Значок объекта для браузерного меню: основной стейт целиком в base64, по стейту один раз.
 * Прозрачные поля обрезает страница: попиксельный обход в DM стоил десятки мс на значок за один тик.
 * Люди собраны из оверлеев, их основной стейт - пустое тело, им значка нет.
 */
/proc/context_menu_icon_base64(atom/thing)
	var/key = context_menu_icon_key(thing)
	if(!key)
		return null
	var/list/cache = GLOB.context_menu_icon_cache
	if(key in cache)
		return cache[key]
	var/result
	if(context_menu_icon_has_state(thing.icon, thing.icon_state))
		result = icon2base64(icon(thing.icon, thing.icon_state, context_menu_icon_dir(thing), 1, FALSE)) || null
	if(length(cache) < CONTEXT_MENU_HTML_ICON_CACHE)
		cache[key] = result
	return result

GLOBAL_LIST_EMPTY(context_menu_icon_cache)

/// Значок уже готов (или известно, что его нет): отдать его ничего не стоит
/proc/context_menu_icon_cached(atom/thing)
	var/key = context_menu_icon_key(thing)
	return !key || (key in GLOB.context_menu_icon_cache)

/// Ключ кэша значков; null - значка у объекта не бывает
/proc/context_menu_icon_key(atom/thing)
	if(!thing?.icon || ishuman(thing))
		return null
	return "[thing.icon]|[thing.icon_state]|[context_menu_icon_dir(thing)]"

/// У однонаправленного стейта другой стороны нет, а вещь в руках и в меню всегда лицом
/proc/context_menu_icon_dir(atom/thing)
	return isitem(thing) ? SOUTH : thing.dir

/// Есть ли стейт в файле иконки; список стейтов файла собирается один раз
/proc/context_menu_icon_has_state(icon_file, icon_state)
	var/static/list/states_by_file = list()
	var/file_key = "[icon_file]"
	var/list/states = states_by_file[file_key]
	if(!states)
		states = list()
		for(var/state in icon_states(icon_file))
			states["[state]"] = TRUE
		states_by_file[file_key] = states
	return states["[icon_state]"] || FALSE
