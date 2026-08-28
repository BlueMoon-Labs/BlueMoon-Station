/atom/movable/screen/screentip
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	screen_loc = "TOP,LEFT"
	// Габариты - это цена в памяти клиента, а не вёрстка. Обоснование и арифметика лежат
	// у дефайнов в code/__DEFINES/screentips.dm; высоту под число контекстных строк
	// выставляет on_mouse_enter в atoms.dm.
	maptext_height = SCREENTIP_BOX_HEIGHT_BASE
	maptext_width = SCREENTIP_BOX_MAX_WIDTH
	maptext = ""
	layer = SCREENTIP_LAYER

/atom/movable/screen/screentip/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	update_view()

/atom/movable/screen/screentip/proc/update_view(datum/source)
	SIGNAL_HANDLER
	if(!hud?.mymob?.client?.view_size) //Might not have been initialized by now
		return
	// Коробка больше НЕ растягивается на весь вьюпорт: на широком экране это стоило 1.41 МБ
	// на строку вместо 0.92. Ширину держит потолок, а центрирование, которое раньше давала
	// сама растяжка, теперь даёт сдвиг коробки - текст остаётся ровно там же, где был.
	var/viewport_width = view_to_pixels(hud.mymob.client.view_size.getView())[1]
	maptext_width = min(viewport_width, SCREENTIP_BOX_MAX_WIDTH)
	maptext_x = round((viewport_width - maptext_width) * 0.5)
