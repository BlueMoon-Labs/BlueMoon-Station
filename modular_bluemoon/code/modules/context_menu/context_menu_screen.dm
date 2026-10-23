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

/atom/movable/screen/context_menu/Initialize(mapload, datum/context_menu/menu, datum/context_menu_entry/entry)
	. = ..()
	src.menu = menu
	src.entry = entry
	if(entry)
		name = entry.name
	else
		mouse_over_pointer = MOUSE_INACTIVE_POINTER
	transform = matrix(CONTEXT_MENU_WIDTH / world.icon_size, 0, (CONTEXT_MENU_WIDTH - world.icon_size) / 2, 0, CONTEXT_MENU_ROW_HEIGHT / world.icon_size, (CONTEXT_MENU_ROW_HEIGHT - world.icon_size) / 2)

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
	var/header = target ? capitalize(target.name) : "На клетке"
	var/total_height = (length(rows) + 1) * CONTEXT_MENU_ROW_HEIGHT
	var/list/view_pixels = view_to_pixels(user.client?.view || world.view)
	var/left = clamp(origin_x + 4, 0, max(view_pixels[1] - CONTEXT_MENU_WIDTH, 0))
	var/top = clamp(origin_y, total_height, max(view_pixels[2], total_height))
	add_row(null, MAPTEXT("<b>[html_encode(header)]</b>"), left, top - CONTEXT_MENU_ROW_HEIGHT, "#121218")
	var/row_index = 1
	for(var/datum/context_menu_entry/entry as anything in rows)
		row_index++
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
		add_row(entry, MAPTEXT("<span style='color:[text_color]'>[html_encode(entry.name)]</span>"), left, top - row_index * CONTEXT_MENU_ROW_HEIGHT, background, hint)
	if(user?.client)
		user.client.screen += screen_objects

/datum/context_menu/proc/add_row(datum/context_menu_entry/entry, text, x, y, background, hint)
	var/screen_loc = "1:[round(x)],1:[round(y)]"
	var/atom/movable/screen/context_menu/row = new(null, src, entry)
	row.screen_loc = screen_loc
	row.set_base_color(background)
	row.alpha = 235
	screen_objects += row
	var/atom/movable/screen/context_menu_text/label = new()
	label.screen_loc = screen_loc
	label.maptext = text
	screen_objects += label
	if(hint)
		var/atom/movable/screen/context_menu_text/hint_label = new()
		hint_label.screen_loc = screen_loc
		hint_label.maptext = hint
		screen_objects += hint_label
