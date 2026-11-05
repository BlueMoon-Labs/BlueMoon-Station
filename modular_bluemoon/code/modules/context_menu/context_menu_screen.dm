/// Фон строки меню: растянутый белый квадрат, ловит наведение и клики
/atom/movable/screen/context_menu
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	plane = ABOVE_HUD_PLANE
	layer = ABOVE_HUD_LAYER
	mouse_over_pointer = MOUSE_HAND_POINTER
	var/datum/context_menu/menu
	var/datum/context_menu_entry/entry
	var/base_color
	/// Низ строки в пикселях экрана, по нему плашка хоткея
	var/row_y = 0

/atom/movable/screen/context_menu/Initialize(mapload, datum/context_menu/menu, datum/context_menu_entry/entry, width = CONTEXT_MENU_WIDTH, height = CONTEXT_MENU_ROW_HEIGHT)
	. = ..()
	src.menu = menu
	src.entry = entry
	if(entry)
		name = entry.name
	else
		mouse_over_pointer = MOUSE_INACTIVE_POINTER
	transform = matrix(width / world.icon_size, 0, (width - world.icon_size) / 2, 0, height / world.icon_size, (height - world.icon_size) / 2)

/atom/movable/screen/context_menu/Destroy()
	menu = null
	entry = null
	return ..()

/atom/movable/screen/context_menu/proc/set_base_color(new_color)
	base_color = new_color
	color = new_color

/atom/movable/screen/context_menu/MouseEntered(location, control, params)
	. = ..()
	if(entry && menu)
		var/hover_color = menu.theme?["hover_bg"] || "#454566"
		if(menu.smooth_hover)
			animate(src, color = hover_color, time = 1)
		else
			color = hover_color
		menu.show_hint(src)

/atom/movable/screen/context_menu/MouseExited(location, control, params)
	. = ..()
	if(menu?.smooth_hover)
		animate(src, color = base_color, time = 1.5)
	else
		color = base_color
	if(menu?.hint_row == src)
		menu.hide_hint()

/atom/movable/screen/context_menu/Click(location, control, params)
	if(!menu || usr != menu.user)
		return
	if(!entry)
		return
	menu.click_row(entry, params2list(params))

/atom/movable/screen/context_menu/MouseWheel(delta_x, delta_y, location, control, params)
	if(menu && usr == menu.user)
		menu.scroll(delta_y)

/// Надпись поверх фона: отдельный объект, чтобы maptext не растягивался вместе с фоном
/atom/movable/screen/context_menu_text
	plane = ABOVE_HUD_PLANE
	layer = ABOVE_HUD_LAYER + 0.01
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	maptext_width = CONTEXT_MENU_WIDTH - 8
	maptext_height = CONTEXT_MENU_ROW_HEIGHT
	maptext_x = 4
	maptext_y = 2

/// Значок объекта в начале строки: его вид без эффектов на других планах, уменьшенный до места под значок
/atom/movable/screen/context_menu_icon
	plane = ABOVE_HUD_PLANE
	layer = ABOVE_HUD_LAYER + 0.01
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/context_menu_icon/Initialize(mapload, atom/source, row_height = CONTEXT_MENU_ICON_ROW_HEIGHT, slot_size = CONTEXT_MENU_ICON_SIZE)
	. = ..()
	var/mutable_appearance/look = new(source)
	// свечение и блокеры света висят на своих планах и на экране рисовались бы поверх карты
	var/list/kept_overlays = list()
	for(var/mutable_appearance/overlay as anything in look.overlays)
		if(overlay.plane == FLOAT_PLANE)
			kept_overlays += overlay
	look.overlays = kept_overlays
	look.underlays = list()
	look.plane = plane
	look.layer = layer
	look.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	look.pixel_x = 0
	look.pixel_y = 0
	look.pixel_w = 0
	look.pixel_z = 0
	look.alpha = 255
	look.maptext = null
	// bounds: левый, нижний, правый, верхний непрозрачный пиксель и размер иконки
	var/list/bounds = context_menu_icon_bounds(source.icon, source.icon_state, source.dir)
	var/visible = max(bounds[3] - bounds[1], bounds[4] - bounds[2]) + 1
	// целый масштаб держит пиксели чёткими: мелкое как есть, крупное вдвое, огромное - сколько нужно; в крупном меню мелкое вдвое больше
	var/scale = 1
	while(visible * scale > slot_size)
		scale /= 2
	var/max_scale = max(1, FLOOR(slot_size / CONTEXT_MENU_ICON_SIZE, 1))
	while(scale * 2 <= max_scale && visible * scale * 2 <= slot_size)
		scale *= 2
	// масштаб идёт вокруг центра иконки; центр видимой части - в середину места под значок
	var/list/icon_center = list(bounds[5] / 2, bounds[6] / 2)
	var/list/visible_center = list((bounds[1] - 1 + bounds[3]) / 2, (bounds[2] - 1 + bounds[4]) / 2)
	var/list/slot_center = list(2 + slot_size / 2, row_height / 2)
	var/list/offset = list()
	for(var/axis in 1 to 2)
		offset += round(slot_center[axis] - icon_center[axis] - scale * (visible_center[axis] - icon_center[axis]))
	look.transform = matrix(scale, 0, offset[1], 0, scale, offset[2])
	appearance = look

/// Рамка непрозрачных пикселей стейта: list(x1, y1, x2, y2, ширина, высота), по стейту один раз. Пустой - вся иконка.
/proc/context_menu_icon_bounds(icon_file, icon_state, dir)
	var/static/list/bounds_cache = list()
	var/key = "[icon_file]|[icon_state]|[dir]"
	if(bounds_cache[key])
		return bounds_cache[key]
	// стейта нет (сглаженные столы и стены собраны из уголков) - рамка на всю иконку
	var/icon/sample = (icon_file && (icon_state in icon_states(icon_file))) ? icon(icon_file, icon_state, dir, 1) : null
	var/list/size = context_menu_icon_size(icon_file)
	var/width = size[1]
	var/height = size[2]
	var/list/bounds = list(width + 1, height + 1, 0, 0, width, height)
	if(sample)
		for(var/y in 1 to height)
			for(var/x in 1 to width)
				if(!sample.GetPixel(x, y))
					continue
				bounds[1] = min(bounds[1], x)
				bounds[2] = min(bounds[2], y)
				bounds[3] = max(bounds[3], x)
				bounds[4] = max(bounds[4], y)
	if(!bounds[3])
		// у однонаправленного стейта другой стороны нет
		if(sample && dir != SOUTH)
			bounds_cache[key] = context_menu_icon_bounds(icon_file, icon_state, SOUTH)
			return bounds_cache[key]
		bounds = list(1, 1, width, height, width, height)
	bounds_cache[key] = bounds
	return bounds

/// Размер иконки в пикселях, по файлу один раз
/proc/context_menu_icon_size(icon_file)
	var/static/list/sizes = list()
	if(!icon_file)
		return list(world.icon_size, world.icon_size)
	var/key = "[icon_file]"
	if(!sizes[key])
		var/icon/sample = icon(icon_file)
		sizes[key] = list(sample.Width(), sample.Height())
	return sizes[key]

/// Ставит меню у курсора; screen-loc вида "x:px,y:py", иногда с именем карты впереди
/datum/context_menu/proc/set_origin(screen_loc)
	var/list/view_pixels = view_to_pixels(user.client?.view || world.view)
	origin_x = view_pixels[1] / 2
	origin_y = view_pixels[2] / 2
	var/static/regex/screen_loc_regex = regex(@"(\d+):(\d+),(\d+):(\d+)$")
	if(screen_loc && screen_loc_regex.Find(screen_loc))
		origin_x = (text2num(screen_loc_regex.group[1]) - 1) * world.icon_size + text2num(screen_loc_regex.group[2])
		origin_y = (text2num(screen_loc_regex.group[3]) - 1) * world.icon_size + text2num(screen_loc_regex.group[4])

/// Вид меню из настроек игрока; без клиента (тесты) - по умолчанию
/datum/context_menu/proc/load_style()
	var/list/style = user?.context_menu_prefs()?.context_menu_style
	scale = context_menu_style_option(style, "scale") / 100
	font_id = context_menu_style_option(style, "font")
	use_html = context_menu_style_option(style, "renderer") == "html" && !!user?.client
	// на карте сглажены только Calibri и Candara (см. context_menu_font_families): по умолчанию там Calibri,
	// шрифт, для которого нет таблицы ширин, тоже заменяется им
	if(!use_html && (!style?["font"] || !(font_id in GLOB.context_menu_map_fonts)))
		font_id = "calibri"
	smooth_font = font_id != "pixel"
	// пиксельный шрифт мельче своих 7px только теряет буквы
	if(!smooth_font)
		scale = max(scale, 1)
	row_alpha = round(255 * context_menu_style_option(style, "opacity") / 100)
	show_icons = context_menu_style_option(style, "icons")
	theme = GLOB.context_menu_themes[context_menu_style_option(style, "theme")]
	density_padding = context_menu_density_padding(context_menu_style_option(style, "density"))
	animation = context_menu_style_option(style, "animation")
	// у карты нет масштаба строк при появлении: «зум» там - проявление
	if(!use_html && animation == "zoom")
		animation = "fade"
	hints_mode = context_menu_style_option(style, "hints")
	position = context_menu_style_option(style, "position")
	show_border = context_menu_style_option(style, "border")
	show_header = context_menu_style_option(style, "header")
	smooth_hover = context_menu_style_option(style, "smooth_hover")
	switch(context_menu_style_option(style, "anim_speed"))
		if("fast")
			animation_speed = 0.5
		if("slow")
			animation_speed = 2
		else
			animation_speed = 1
	show_stripe = context_menu_style_option(style, "stripe")
	show_shadow = context_menu_style_option(style, "shadow")
	row_gap = context_menu_style_option(style, "separators") ? 1 : 0
	caps = context_menu_style_option(style, "caps")
	text_outline = context_menu_style_option(style, "outline")
	page_rows = context_menu_style_option(style, "page_rows")
	accent = context_menu_style_option(style, "accent") || theme["accent"]
	confirm_danger = context_menu_style_option(style, "confirm_danger")
	close_on_move = context_menu_style_option(style, "close_on_move")
	pile_click = context_menu_style_option(style, "pile_click")
	cursor_offset = context_menu_style_option(style, "offset")
	menu_sound = context_menu_style_option(style, "sound")
	text_zoom = user?.client?.context_menu_zoom || CONTEXT_MENU_DEFAULT_ZOOM

/// Чьи настройки вида у меню этого моба
/mob/proc/context_menu_prefs()
	RETURN_TYPE(/datum/preferences)
	return client?.prefs

/datum/context_menu/proc/render()
	hide_hint()
	if(user?.client)
		user.client.screen -= screen_objects
	QDEL_LIST(screen_objects)
	row_groups = list()
	load_style()
	if(html_renderer())
		render_html()
		return
	hide_html()
	var/list/rows = visible_entries()
	var/header = header_text || (target ? context_menu_name(target.name) : "На клетке")
	header_entry = new /datum/context_menu_entry/mode_choice(header)
	width = fit_width(rows, header)
	var/header_height = show_header ? round((CONTEXT_MENU_ROW_HEIGHT + density_padding) * scale) : 0
	var/total_height = header_height
	for(var/datum/context_menu_entry/entry as anything in rows)
		total_height += row_height(entry)
	// разделители - щель в пиксель между строками, сквозь неё видна рамка или карта
	total_height += row_gap * max(length(rows) - (show_header ? 0 : 1), 0)
	var/list/view_pixels = view_to_pixels(user.client?.view || world.view)
	var/top_shift = 0
	switch(position)
		if("left")
			left = origin_x - width - cursor_offset
		if("center")
			left = origin_x - width / 2
		if("above")
			left = origin_x - width / 2
			top_shift = total_height + cursor_offset
		else
			left = origin_x + cursor_offset
	left = round(clamp(left, 0, max(view_pixels[1] - width, 0)))
	var/top = clamp(origin_y + top_shift, total_height, max(view_pixels[2], total_height))
	var/y = top
	if(show_header)
		y -= header_height
		add_row(header_entry, styled_text(header, theme["header_text"], TRUE), left, y, theme["header_bg"], styled_text("режим", theme["mode_text"], FALSE, TRUE), null, header_height)
	for(var/datum/context_menu_entry/entry as anything in rows)
		if(y != top)
			y -= row_gap
		y -= row_height(entry)
		var/text_color = theme["text"]
		var/background = theme["row_bg"]
		switch(entry.style)
			if(CONTEXT_ENTRY_CURRENT)
				background = theme["current_bg"]
			if(CONTEXT_ENTRY_DANGER)
				text_color = theme["danger"]
			if(CONTEXT_ENTRY_SERVICE)
				text_color = theme["service"]
			if(CONTEXT_ENTRY_ADMIN)
				text_color = theme["admin_text"]
				background = theme["admin_bg"]
		var/inline_hint = (hints_mode == "inline" && entry.hint) ? styled_text(entry.hint, theme["hint_text"], FALSE, TRUE) : null
		add_row(entry, styled_text(entry_display_name(entry), text_color), left, y, background, inline_hint, entry_icon(entry))
		// полоска акцента у основного действия и админ-пункта
		if(show_stripe && (entry.style == CONTEXT_ENTRY_CURRENT || entry.style == CONTEXT_ENTRY_ADMIN))
			add_backdrop(max(round(2 * scale), 1), row_height(entry), left, y, accent, 255, ABOVE_HUD_LAYER + 0.005, row_groups[length(row_groups)])
	if(show_border)
		// рамка - фон на пиксель шире меню со всех сторон, под строками; свой акцент красит и её
		add_backdrop(width + 2, total_height + 2, left - 1, y - 1, context_menu_style_option(user?.context_menu_prefs()?.context_menu_style, "accent") || theme["border"], row_alpha, ABOVE_HUD_LAYER - 0.01)
	if(show_shadow)
		add_backdrop(width, total_height, left + round(3 * scale), y - round(3 * scale), "#000000", round(row_alpha * 0.45), ABOVE_HUD_LAYER - 0.02)
	if(user?.client)
		user.client.screen += screen_objects
	if(!opened)
		opened = TRUE
		play_menu_sound()
		animate_opening(top)

/// Фон без пункта под меню или поверх строки: рамка, тень, полоска. Появляется со своей строкой group, без неё - с шапкой.
/datum/context_menu/proc/add_backdrop(box_width, box_height, x, y, color, alpha, layer, list/group)
	var/atom/movable/screen/context_menu/backdrop = new(null, src, null, box_width, box_height)
	backdrop.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	backdrop.layer = layer
	backdrop.screen_loc = "1:[round(x)],1:[round(y)]"
	backdrop.set_base_color(color)
	backdrop.alpha = alpha
	screen_objects += backdrop
	if(!group && length(row_groups))
		group = row_groups[1]
	group?.Add(backdrop)
	return backdrop

/**
 * Появление меню при открытии; листание и смена настроек перерисовывают без анимации.
 * Каждая строка - группа из фона, надписи и значка; цель анимации - их нынешняя прозрачность и место.
 */
/datum/context_menu/proc/animate_opening(top)
	if(animation == "none")
		return
	for(var/i in 1 to length(row_groups))
		var/list/group = row_groups[i]
		var/delay = (i - 1) * 0.4 * animation_speed
		var/time = 2 * animation_speed
		for(var/atom/movable/screen/thing as anything in group)
			var/target_alpha = thing.alpha
			thing.alpha = 0
			switch(animation)
				if("fade")
					animate(thing, alpha = target_alpha, time = time)
				if("slide")
					thing.pixel_y = round(6 * scale)
					animate(thing, alpha = target_alpha, pixel_y = 0, time = time, easing = CUBIC_EASING | EASE_OUT)
				if("drop")
					// строки выезжают из-под шапки, нижние дольше
					var/atom/movable/screen/context_menu/row = group[1]
					thing.pixel_y = max(top - row.row_y - row_height(row.entry), 0)
					animate(thing, alpha = target_alpha, pixel_y = 0, time = 0.75 * time + delay, easing = CUBIC_EASING | EASE_OUT)
				if("cascade")
					thing.pixel_x = round(-6 * scale)
					animate(thing, alpha = target_alpha, pixel_x = 0, time = 0.75 * time, delay = delay, easing = CUBIC_EASING | EASE_OUT)

/// Значок строки, если игрок их не выключил
/datum/context_menu/proc/entry_icon(datum/context_menu_entry/entry)
	return show_icons ? entry?.icon_source() : null

/// Строка со значком не мельче 100%: пиксель-арт в дробном масштабе рвётся
/datum/context_menu/proc/row_height(datum/context_menu_entry/entry)
	if(entry_icon(entry))
		return round((CONTEXT_MENU_ICON_ROW_HEIGHT + density_padding) * max(scale, 1))
	return round((CONTEXT_MENU_ROW_HEIGHT + density_padding) * scale)

/datum/context_menu/proc/icon_slot()
	return round(CONTEXT_MENU_ICON_SIZE * max(scale, 1))

/// Текст строки шрифтом из настроек; html экранируется здесь
/datum/context_menu/proc/styled_text(text, color, bold = FALSE, right = FALSE)
	var/body = html_encode(display_text(text))
	if(bold)
		body = "<b>[body]</b>"
	var/align = right ? ";text-align:right" : ""
	if(!smooth_font)
		return MAPTEXT("<span style='color:[color];-dm-text-outline:1px [theme["outline"]][align]'>[body]</span>")
	var/outline = text_outline ? ";-dm-text-outline:[max(1, round(scale * text_zoom / 2))]px [theme["outline"]]" : ""
	return "<span style='font-family:\"[GLOB.context_menu_font_families[font_id]]\";font-size:[round(CONTEXT_MENU_FONT_PX * context_menu_font_size_factor(font_id) * scale * text_zoom)]px;vertical-align:middle;color:[color][align][outline]'>[body]</span>"

/// Текст так, как его покажет меню: заглавными, если игрок так выбрал
/datum/context_menu/proc/display_text(text)
	return caps ? uppertext(text) : text

/// Ширина текста в пикселях карты шрифтом меню
/datum/context_menu/proc/text_width(text, bold = FALSE)
	text = display_text(text)
	if(smooth_font)
		return context_menu_smooth_text_width(text, bold, font_id) * CONTEXT_MENU_FONT_PX * context_menu_font_size_factor(font_id) * scale / 100
	return context_menu_text_width(text, bold) * scale

/// Ширина под самый длинный пункт с его значком; в шапке ещё «режим». Хоткеи - плашкой при наведении или справа в строке.
/datum/context_menu/proc/fit_width(list/rows, header)
	var/widest = show_header ? text_width(header, TRUE) + 8 * scale + text_width("режим") : 0
	for(var/datum/context_menu_entry/entry as anything in rows)
		var/row_width = text_width(entry.name)
		if(entry_icon(entry))
			row_width += icon_slot() + 4 * scale
		if(hints_mode == "inline" && entry.hint)
			row_width += 8 * scale + text_width(entry.hint)
		widest = max(widest, row_width)
	var/max_width = CONTEXT_MENU_WIDTH * scale * (hints_mode == "inline" ? 1.5 : 1)
	return round(clamp(widest + 8 * scale, CONTEXT_MENU_MIN_WIDTH * scale, max_width))

/// Ширина текста Small Fonts 7px с обводкой в пикселях карты; буквы не из таблицы считаются по 5
/proc/context_menu_text_width(text, bold = FALSE)
	var/static/list/glyph_widths
	if(!glyph_widths)
		glyph_widths = context_menu_glyph_table(list(
			"2" = " ",
			"3" = "!',.:;Iijl|",
			"4" = "\"()*-/1<=>?\[\\]`frst{}гя",
			"6" = "#%&ABCDGHKNOPQRSUwАБВДЖИЙКЛНОПРСЦЪЫЬЭЯдф",
			"7" = "MWmМФЮжмшщ…",
			"8" = "@ШЩ",
		))
	. = 0
	for(var/i in 1 to length_char(text))
		. += (glyph_widths[copytext_char(text, i, i + 1)] || 5) + (bold ? 2 : 0)

/// "ширина" = "буквы" -> буква = ширина
/proc/context_menu_glyph_table(list/groups)
	. = list()
	for(var/glyph_width in groups)
		var/glyphs = groups[glyph_width]
		for(var/i in 1 to length_char(glyphs))
			.[copytext_char(glyphs, i, i + 1)] = text2num(glyph_width)

/**
 * Надпись меню в пикселях карты: x, y - сдвиг от угла строки, box_width x box_height - коробка.
 * Гладкий шрифт растеризуется в коробке крупнее в зум карты раз и сжимается обратно transform-ом:
 * буквы ложатся на пиксели экрана один к одному, а не растягиваются зумом. Пиксельный при размере больше 100% растягивается.
 */
/datum/context_menu/proc/make_label(text, screen_loc, x, y, box_width, box_height)
	var/atom/movable/screen/context_menu_text/label = new()
	label.screen_loc = screen_loc
	label.maptext = text
	// коробка на целых пикселях карты: дробный сдвиг ложится между пикселями экрана, и BYOND выбрасывает столбцы букв
	x = round(x)
	y = round(y)
	box_width = round(box_width)
	box_height = round(box_height)
	// во сколько раз надпись на экране меньше своей коробки
	var/shrink = smooth_font ? 1 / text_zoom : scale
	if(smooth_font)
		// строку выше коробки BYOND не рисует вовсе, а высота строки у шрифтов разная (у Tahoma 1.6 кегля):
		// коробка втрое выше места с запасом на любой шрифт, текст в ней по центру (vertical-align:middle в styled_text)
		y += -box_height - text_offset(box_height)
		box_height *= 3
	label.maptext_x = round(x / shrink)
	label.maptext_y = round(y / shrink)
	label.maptext_width = round(box_width / shrink)
	label.maptext_height = round(box_height / shrink)
	if(shrink != 1)
		// масштаб вокруг центра квадрата world.icon_size: точка p переходит в p * shrink
		var/pivot = world.icon_size / 2
		label.transform = matrix(shrink, 0, pivot * shrink - pivot, 0, shrink, pivot * shrink - pivot)
	return label

/// Хоткей строки - плашкой справа от меню на её высоте, у правого края экрана - слева
/datum/context_menu/proc/show_hint(atom/movable/screen/context_menu/row)
	hide_hint()
	var/hint = row.entry?.hint
	if(!hint || !user || hints_mode != "hover")
		return
	hint_row = row
	var/hint_width = round(text_width(hint) + 8 * scale)
	var/list/view_pixels = view_to_pixels(user.client?.view || world.view)
	var/hint_x = left + width + 2
	if(hint_x + hint_width > view_pixels[1])
		hint_x = max(left - hint_width - 2, 0)
	var/height = row_height(row.entry)
	var/screen_loc = "1:[round(hint_x)],1:[row.row_y]"
	var/atom/movable/screen/context_menu/background = new(null, src, null, hint_width, height)
	background.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	background.screen_loc = screen_loc
	background.set_base_color(theme["hint_bg"])
	background.alpha = row_alpha
	hint_objects += background
	hint_objects += make_label(styled_text(hint, theme["hint_text"]), screen_loc, 4 * scale, text_offset(height), hint_width - 8 * scale, height)
	user.client?.screen += hint_objects

/// Сдвиг надписи от низа строки: строка текста около 9 пикселей при 100%
/datum/context_menu/proc/text_offset(height)
	return round((height - 9 * scale) / 2)

/datum/context_menu/proc/hide_hint()
	hint_row = null
	if(!length(hint_objects))
		return
	user?.client?.screen -= hint_objects
	QDEL_LIST(hint_objects)

/datum/context_menu/proc/add_row(datum/context_menu_entry/entry, text, x, y, background, hint, atom/icon_source, height)
	var/screen_loc = "1:[round(x)],1:[round(y)]"
	if(!height)
		height = row_height(entry)
	var/text_y = text_offset(height)
	var/list/group = list()
	var/atom/movable/screen/context_menu/row = new(null, src, entry, width, height)
	row.screen_loc = screen_loc
	row.row_y = round(y)
	row.set_base_color(background)
	row.alpha = row_alpha
	group += row
	var/text_indent = 0
	if(icon_source)
		var/atom/movable/screen/context_menu_icon/icon_object = new(null, icon_source, height, icon_slot())
		icon_object.screen_loc = screen_loc
		group += icon_object
		text_indent = icon_slot() + 4 * scale
	group += make_label(text, screen_loc, 4 * scale + text_indent, text_y, width - 8 * scale - text_indent, height)
	if(hint)
		group += make_label(hint, screen_loc, 4 * scale, text_y, width - 8 * scale, height)
	screen_objects += group
	row_groups += list(group)

/// Зум карты игрока: гладкий шрифт меню растеризуется под него. Спрашивается у клиента не чаще раза в пару секунд.
/client
	var/context_menu_zoom = CONTEXT_MENU_DEFAULT_ZOOM
	var/context_menu_zoom_checked = 0

/client/proc/refresh_context_menu_zoom()
	if(world.time < context_menu_zoom_checked + 2 SECONDS)
		return
	context_menu_zoom_checked = world.time
	var/list/map_params = params2list(winget(src, "mapwindow.map", "size;zoom"))
	if(QDELETED(src) || !length(map_params))
		return
	var/list/size = splittext(map_params["size"], "x")
	var/zoom = text2num(map_params["zoom"])
	if(!zoom && length(size) == 2)
		var/list/view_pixels = view_to_pixels(view)
		zoom = min(text2num(size[1]) / view_pixels[1], text2num(size[2]) / view_pixels[2])
	if(!zoom || zoom <= 0)
		return
	// зум нужен точный: надпись, сжатая в 2 раза при зуме 1.99, ложится на экран в 0.995 и теряет столбцы букв
	zoom = round(clamp(zoom, 0.5, 6), 0.0001)
	if(zoom == context_menu_zoom)
		return
	context_menu_zoom = zoom
	var/datum/context_menu/menu = mob?.active_context_menu
	if(menu?.smooth_font)
		menu.render()
