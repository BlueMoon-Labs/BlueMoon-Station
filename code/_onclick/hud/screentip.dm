/atom/movable/screen/screentip
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	screen_loc = "TOP,LEFT"
	/**
	 * Высота коробки скринтипа. НЕ КОСМЕТИКА: это цена в памяти клиента.
	 *
	 * Растеризованный maptext занимает у клиента поверхность maptext_width * maptext_height * 4
	 * байта, и она живёт столько же, сколько appearance, в который попала, - то есть до конца
	 * сессии. При 480x480 одна УНИКАЛЬНАЯ строка скринтипа стоит 0.92 МБ, при широком экране
	 * (736 px) - 1.41 МБ.
	 *
	 * Уникальных строк много и они личные: в строку входит имя атома, вспомогательное имя,
	 * восемь веток контекста и ЦВЕТ ИЗ ЛИЧНЫХ ПРЕФОВ игрока (см. atoms.dm, конец
	 * on_mouse_enter). Дедуп там сравнивает только с предыдущим атомом под курсором, а
	 * SSmouse_entered фаерит с wait = 1, то есть до 10 раз в секунду. В комментарии у
	 * hud.dm зафиксировано около 142 тысяч MouseEntered за сессию.
	 *
	 * Замер прода 28.08.2026: 32-битный Dream Seeker после очистки кэша занимал 640 МБ и через
	 * ДЕСЯТЬ минут - 2771 МБ, то есть +213 МБ/мин. Это 2-4 уникальные строки в секунду по
	 * 0.92 МБ - ровно тот темп, с которым игрок водит мышью по объектам с разными именами.
	 *
	 * Высота 480 не была нужна никогда: в скринтипе строка имени плюс не больше четырёх строк
	 * подсказок (см. extra_lines там же), это 64 px текста, а maptext_y опускает блок вниз
	 * максимум на 42 px. 128 закрывает и то и другое с запасом вдвое, а поверхность режет
	 * почти вчетверо. Ширину трогать нельзя - она равна ширине вьюпорта и центрирует текст.
	 */
	maptext_height = 128
	maptext_width = 480
	maptext = ""
	layer = SCREENTIP_LAYER

/atom/movable/screen/screentip/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	update_view()

/atom/movable/screen/screentip/proc/update_view(datum/source)
	SIGNAL_HANDLER
	if(!hud?.mymob?.client?.view_size) //Might not have been initialized by now
		return
	maptext_width = view_to_pixels(hud.mymob.client.view_size.getView())[1]
