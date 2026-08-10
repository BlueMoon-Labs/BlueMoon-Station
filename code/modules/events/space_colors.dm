/// Молекулярное облако (порт идеи goonstation "Pretty Space"): станция несколько минут
/// дрейфует сквозь разреженное облако межзвёздной пыли, и космос за иллюминаторами
/// плавно переливается необычными оттенками. Тихий младший брат авроры и кометного
/// пояса: без музыки, пацифизма и хореографии - только мягкая тонировка параллакса
/// тем же приёмом, что glow кометного пояса (фуллскрин-оверлей на PLANE_SPACE_PARALLAX).
/datum/round_event_control/space_colors
	name = "Molecular Cloud"
	typepath = /datum/round_event/space_colors
	weight = 12
	max_occurrences = 1
	earliest_start = 15 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_FRIENDLY
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	description = "The station drifts through a molecular cloud: space slowly shifts through unusual colors."

/datum/round_event/space_colors
	announce_when = 1
	start_when = 5
	end_when = 150
	fakeable = FALSE
	/// client -> оверлей тонировки
	var/list/tint_overlays = list()
	/// Все созданные оверлеи, включая сирот от отключившихся клиентов
	var/list/all_overlay_objects = list()
	/// Выбранная на раунд палитра и позиция в ней
	var/list/palette
	var/palette_index = 1
	/// Палитры облаков: цвета сменяют друг друга по кругу
	var/static/list/palettes = list(
		list("#3A1A5E", "#B03A6E", "#E08040"),
		list("#0F3A5E", "#2E8E7E", "#7ED0A0"),
		list("#5E1A2A", "#B0483A", "#E0B060"),
		list("#1A2A5E", "#5E3AB0", "#A070E0"),
	)

/datum/round_event/space_colors/setup()
	palette = pick(palettes)

/datum/round_event/space_colors/announce(fake)
	priority_announce("Станция проходит через разреженное молекулярное облако. В ближайшее время пыль облака будет рассеивать звёздный свет, окрашивая космос в необычные оттенки. Явление полностью безопасно. Приятного наблюдения.",
		sound = 'sound/misc/notice2.ogg',
		sender_override = "Отдел Астрономии NanoTrasen")

/datum/round_event/space_colors/start()
	for(var/client/C in GLOB.clients)
		if(!C.mob || !is_station_level(C.mob.z))
			continue
		add_tint(C)

/datum/round_event/space_colors/tick()
	// Подключаем тех, кто прилетел на станцию или залогинился после старта
	for(var/client/C in GLOB.clients)
		if(tint_overlays[C])
			continue
		if(!C.mob || !is_station_level(C.mob.z))
			continue
		add_tint(C)
	// Смена оттенка примерно каждые 40 секунд. Альфу тянем вместе с цветом:
	// animate() перезаписывает очередь анимаций, и без alpha смена оттенка
	// замораживала бы недоигранный fade-in на полпути.
	if(activeFor % 20 == 0)
		palette_index = (palette_index % length(palette)) + 1
		var/next_color = palette[palette_index]
		for(var/client/C in tint_overlays)
			var/atom/movable/screen/space_colors_tint/tint = tint_overlays[C]
			if(tint)
				animate(tint, color = next_color, alpha = 45, time = 30 SECONDS)

/datum/round_event/space_colors/end()
	for(var/client/C in tint_overlays)
		var/atom/movable/screen/space_colors_tint/tint = tint_overlays[C]
		if(tint)
			animate(tint, alpha = 0, time = 8 SECONDS)
	// Очистка после того, как fade-out отыграл
	addtimer(CALLBACK(src, PROC_REF(final_cleanup)), 10 SECONDS)

/datum/round_event/space_colors/proc/add_tint(client/C)
	var/atom/movable/screen/space_colors_tint/tint = new
	tint.color = palette[palette_index]
	tint_overlays[C] = tint
	all_overlay_objects += tint
	C.screen += tint
	animate(tint, alpha = 45, time = 10 SECONDS)

/datum/round_event/space_colors/proc/final_cleanup()
	for(var/client/C in tint_overlays)
		C.screen -= tint_overlays[C]
	for(var/atom/movable/tint as anything in all_overlay_objects)
		qdel(tint)
	all_overlay_objects.Cut()
	tint_overlays.Cut()

/// Тонировка космоса: аддитивный фуллскрин-оверлей, красящий только план параллакса
/atom/movable/screen/space_colors_tint
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	alpha = 0
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = PLANE_SPACE_PARALLAX
	layer = 4 // ниже glow кометного пояса: при наложении событий кометы главнее
	blend_mode = BLEND_ADD
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
