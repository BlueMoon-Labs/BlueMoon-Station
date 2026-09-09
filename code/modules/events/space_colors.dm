#define SPACE_COLORS_TOKEN "space_colors"

/// Молекулярное облако (порт идеи goonstation "Pretty Space"): станция несколько минут
/// дрейфует сквозь разреженное облако межзвёздной пыли, и космос за иллюминаторами
/// плавно переливается необычными оттенками. Тихий младший брат авроры и кометного
/// пояса: без музыки, пацифизма и хореографии - только мягкая тонировка параллакса.
///
/// Тонировка идёт слоем профиля через стек модификаторов SSparallax. Раньше событие
/// само вело список клиентов, каждый тик искало опоздавших и держало отдельный
/// список сирот от отключившихся - всё это теперь делает держатель параллакса,
/// потому что слой лежит в сцене z-уровня, а не навешен на клиента вручную.
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
	/// z-уровни, на которые положен модификатор
	var/list/tinted_z_levels = list()
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
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		SSparallax.add_modifier(
			station_z,
			SPACE_COLORS_TOKEN,
			extra_layers = list(/atom/movable/screen/parallax_layer/tint/molecular_cloud),
			tint = palette[palette_index],
			priority = PARALLAX_PRIORITY_EVENT,
		)
		tinted_z_levels += station_z

/datum/round_event/space_colors/tick()
	// Смена оттенка примерно каждые 40 секунд. Тянем цвет прямо на живых слоях:
	// пересборка сцены оборвала бы переход у всех разом.
	if(activeFor % 20)
		return
	palette_index = (palette_index % length(palette)) + 1
	var/next_color = palette[palette_index]
	for(var/station_z in tinted_z_levels)
		SSparallax.animate_tint(station_z, SPACE_COLORS_TOKEN, next_color, 30 SECONDS)

/datum/round_event/space_colors/end()
	for(var/station_z in tinted_z_levels)
		SSparallax.fade_out_modifier(station_z, SPACE_COLORS_TOKEN, 8 SECONDS)
	tinted_z_levels.Cut()

/// Тонировка космоса: аддитивный фуллскрин-фильтр на плане параллакса.
/// Красится палитрой профиля, поэтому palette_tinted; своей позиции не имеет,
/// поэтому OVERLAY.
/atom/movable/screen/parallax_layer/tint
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	alpha = 45
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	blend_mode = BLEND_ADD
	layer_mode = PARALLAX_MODE_OVERLAY
	palette_tinted = TRUE
	parallax_intensity = PARALLAX_LOW
	fade_in_time = 10 SECONDS

/// Ниже glow кометного пояса: при наложении событий кометы главнее.
/atom/movable/screen/parallax_layer/tint/molecular_cloud
	layer = 4

#undef SPACE_COLORS_TOKEN
