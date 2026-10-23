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

/atom/movable/screen/context_menu/MouseExited(location, control, params)
	. = ..()
	color = base_color

/atom/movable/screen/context_menu/Click(location, control, params)
	if(!menu || usr != menu.user)
		return
	if(entry)
		menu.choose(entry)

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
	var/list/size = context_menu_icon_size(source.icon)
	var/scale = CONTEXT_MENU_ICON_SIZE / max(size[1], size[2], 1)
	// масштаб идёт вокруг центра иконки, поэтому сдвиг - в левый край строки и по центру высоты
	look.transform = matrix(scale, 0, 2 - size[1] * (1 - scale) / 2, 0, scale, (row_height - size[2] * scale) / 2 - size[2] * (1 - scale) / 2)
	appearance = look

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
	var/left = clamp(origin_x + 4, 0, max(view_pixels[1] - width, 0))
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
		var/hint = entry.hint ? MAPTEXT("<span style='color:#8a8fa3;text-align:right'>[html_encode(entry.hint)]</span>") : null
		add_row(entry, MAPTEXT("<span style='color:[text_color]'>[html_encode(entry.name)]</span>"), left, y, background, hint, entry.icon_source())
	if(user?.client)
		user.client.screen += screen_objects

/datum/context_menu/proc/row_height(datum/context_menu_entry/entry)
	return entry?.icon_source() ? CONTEXT_MENU_ICON_ROW_HEIGHT : CONTEXT_MENU_ROW_HEIGHT

/// Ширина под самый длинный пункт: имя, значок и хоткей справа; в шапке ещё «режим»
/datum/context_menu/proc/fit_width(list/rows, header)
	var/widest = (length_char(header) + 1 + length_char("режим")) * CONTEXT_MENU_CHAR_WIDTH + 12
	for(var/datum/context_menu_entry/entry as anything in rows)
		var/row_width = length_char(entry.name) * CONTEXT_MENU_CHAR_WIDTH
		if(entry.hint)
			row_width += length_char(entry.hint) * CONTEXT_MENU_CHAR_WIDTH + 12
		if(entry.icon_source())
			row_width += CONTEXT_MENU_ICON_SIZE + 4
		widest = max(widest, row_width)
	return clamp(widest + 8, CONTEXT_MENU_MIN_WIDTH, CONTEXT_MENU_WIDTH)

/datum/context_menu/proc/add_row(datum/context_menu_entry/entry, text, x, y, background, hint, atom/icon_source)
	var/screen_loc = "1:[round(x)],1:[round(y)]"
	var/height = icon_source ? CONTEXT_MENU_ICON_ROW_HEIGHT : CONTEXT_MENU_ROW_HEIGHT
	var/text_y = round((height - 9) / 2)
	var/atom/movable/screen/context_menu/row = new(null, src, entry, width, height)
	row.screen_loc = screen_loc
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
