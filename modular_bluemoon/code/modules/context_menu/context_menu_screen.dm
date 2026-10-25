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
	if(entry)
		color = "#454566"
		menu?.show_hint(src)

/atom/movable/screen/context_menu/MouseExited(location, control, params)
	. = ..()
	color = base_color
	if(menu?.hint_row == src)
		menu.hide_hint()

/atom/movable/screen/context_menu/Click(location, control, params)
	if(!menu || usr != menu.user)
		return
	if(!entry)
		return
	if(istype(entry, /datum/context_menu_entry/pick) && menu.click_picked(entry, params2list(params)))
		return
	menu.choose(entry)

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

/// Значок объекта в начале строки: его вид без эффектов на других планах, уменьшенный до CONTEXT_MENU_ICON_SIZE
/atom/movable/screen/context_menu_icon
	plane = ABOVE_HUD_PLANE
	layer = ABOVE_HUD_LAYER + 0.01
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/context_menu_icon/Initialize(mapload, atom/source, row_height = CONTEXT_MENU_ICON_ROW_HEIGHT)
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
	// целый масштаб держит пиксели чёткими: мелкое как есть, крупное вдвое, огромное - сколько нужно
	var/scale = 1
	while(visible * scale > CONTEXT_MENU_ICON_SIZE)
		scale /= 2
	// масштаб идёт вокруг центра иконки; центр видимой части - в середину места под значок
	var/list/icon_center = list(bounds[5] / 2, bounds[6] / 2)
	var/list/visible_center = list((bounds[1] - 1 + bounds[3]) / 2, (bounds[2] - 1 + bounds[4]) / 2)
	var/list/slot_center = list(2 + CONTEXT_MENU_ICON_SIZE / 2, row_height / 2)
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

/datum/context_menu/proc/render()
	hide_hint()
	if(user?.client)
		user.client.screen -= screen_objects
	QDEL_LIST(screen_objects)
	var/list/rows = visible_entries()
	var/header = header_text || (target ? capitalize(target.name) : "На клетке")
	width = fit_width(rows, header)
	var/total_height = CONTEXT_MENU_ROW_HEIGHT
	for(var/datum/context_menu_entry/entry as anything in rows)
		total_height += row_height(entry)
	var/list/view_pixels = view_to_pixels(user.client?.view || world.view)
	left = clamp(origin_x + 4, 0, max(view_pixels[1] - width, 0))
	var/top = clamp(origin_y, total_height, max(view_pixels[2], total_height))
	header_entry = new /datum/context_menu_entry/mode_choice(header)
	var/y = top - CONTEXT_MENU_ROW_HEIGHT
	add_row(header_entry, MAPTEXT("<b>[html_encode(header)]</b>"), left, y, "#121218", MAPTEXT("<span style='color:#6f7488;text-align:right'>режим</span>"))
	for(var/datum/context_menu_entry/entry as anything in rows)
		y -= row_height(entry)
		var/text_color = "#e8e8e8"
		var/background = "#1d1d26"
		switch(entry.style)
			if(CONTEXT_ENTRY_CURRENT)
				background = "#24324a"
			if(CONTEXT_ENTRY_DANGER)
				text_color = "#ff8a80"
			if(CONTEXT_ENTRY_SERVICE)
				text_color = "#9aa0b4"
		add_row(entry, MAPTEXT("<span style='color:[text_color]'>[html_encode(entry.name)]</span>"), left, y, background, null, entry.icon_source())
	if(user?.client)
		user.client.screen += screen_objects

/datum/context_menu/proc/row_height(datum/context_menu_entry/entry)
	return entry?.icon_source() ? CONTEXT_MENU_ICON_ROW_HEIGHT : CONTEXT_MENU_ROW_HEIGHT

/// Ширина под самый длинный пункт с его значком; в шапке ещё «режим». Хоткеи в ширину не входят, они - плашкой при наведении.
/datum/context_menu/proc/fit_width(list/rows, header)
	var/widest = context_menu_text_width(header, TRUE) + 8 + context_menu_text_width("режим")
	for(var/datum/context_menu_entry/entry as anything in rows)
		var/row_width = context_menu_text_width(entry.name)
		if(entry.icon_source())
			row_width += CONTEXT_MENU_ICON_SIZE + 4
		widest = max(widest, row_width)
	return clamp(widest + 8, CONTEXT_MENU_MIN_WIDTH, CONTEXT_MENU_WIDTH)

/// Ширина текста Small Fonts 7px с обводкой в пикселях карты; буквы не из таблицы считаются по 5
/proc/context_menu_text_width(text, bold = FALSE)
	var/static/list/glyph_widths
	if(!glyph_widths)
		glyph_widths = list()
		var/list/groups = list(
			"2" = " ",
			"3" = "!',.:;Iijl|",
			"4" = "\"()*-/1<=>?\[\\]`frst{}гя",
			"6" = "#%&ABCDGHKNOPQRSUwАБВДЖИЙКЛНОПРСЦЪЫЬЭЯдф",
			"7" = "MWmМФЮжмшщ…",
			"8" = "@ШЩ",
		)
		for(var/glyph_width in groups)
			var/glyphs = groups[glyph_width]
			for(var/i in 1 to length_char(glyphs))
				glyph_widths[copytext_char(glyphs, i, i + 1)] = text2num(glyph_width)
	. = 0
	for(var/i in 1 to length_char(text))
		. += (glyph_widths[copytext_char(text, i, i + 1)] || 5) + (bold ? 2 : 0)

/// Хоткей строки - плашкой справа от меню на её высоте, у правого края экрана - слева
/datum/context_menu/proc/show_hint(atom/movable/screen/context_menu/row)
	hide_hint()
	var/hint = row.entry?.hint
	if(!hint || !user)
		return
	hint_row = row
	var/hint_width = context_menu_text_width(hint) + 8
	var/list/view_pixels = view_to_pixels(user.client?.view || world.view)
	var/hint_x = left + width + 2
	if(hint_x + hint_width > view_pixels[1])
		hint_x = max(left - hint_width - 2, 0)
	var/height = row_height(row.entry)
	var/screen_loc = "1:[round(hint_x)],1:[row.row_y]"
	var/atom/movable/screen/context_menu/background = new(null, src, null, hint_width, height)
	background.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	background.screen_loc = screen_loc
	background.set_base_color("#121218")
	background.alpha = 235
	var/atom/movable/screen/context_menu_text/label = new()
	label.screen_loc = screen_loc
	label.maptext = MAPTEXT("<span style='color:#8a8fa3'>[html_encode(hint)]</span>")
	label.maptext_y = round((height - 9) / 2)
	label.maptext_width = hint_width - 8
	label.maptext_height = height
	hint_objects += background
	hint_objects += label
	user.client?.screen += hint_objects

/datum/context_menu/proc/hide_hint()
	hint_row = null
	if(!length(hint_objects))
		return
	user?.client?.screen -= hint_objects
	QDEL_LIST(hint_objects)

/datum/context_menu/proc/add_row(datum/context_menu_entry/entry, text, x, y, background, hint, atom/icon_source)
	var/screen_loc = "1:[round(x)],1:[round(y)]"
	var/height = icon_source ? CONTEXT_MENU_ICON_ROW_HEIGHT : CONTEXT_MENU_ROW_HEIGHT
	var/text_y = round((height - 9) / 2)
	var/atom/movable/screen/context_menu/row = new(null, src, entry, width, height)
	row.screen_loc = screen_loc
	row.row_y = round(y)
	row.set_base_color(background)
	row.alpha = 235
	screen_objects += row
	var/text_indent = 0
	if(icon_source)
		var/atom/movable/screen/context_menu_icon/icon_object = new(null, icon_source, height)
		icon_object.screen_loc = screen_loc
		screen_objects += icon_object
		text_indent = CONTEXT_MENU_ICON_SIZE + 4
	var/atom/movable/screen/context_menu_text/label = new()
	label.screen_loc = screen_loc
	label.maptext = text
	label.maptext_x += text_indent
	label.maptext_y = text_y
	label.maptext_width = width - 8 - text_indent
	label.maptext_height = height
	screen_objects += label
	if(hint)
		var/atom/movable/screen/context_menu_text/hint_label = new()
		hint_label.screen_loc = screen_loc
		hint_label.maptext = hint
		hint_label.maptext_y = text_y
		hint_label.maptext_width = width - 8
		hint_label.maptext_height = height
		screen_objects += hint_label
