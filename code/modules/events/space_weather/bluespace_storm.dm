/**
 * # Блюспейс-шторм
 *
 * Локальный блюспейс перенасыщен. Для науки это лучшее окно раунда: показания богаты,
 * сенсор берёт полуторную выдачу. Для всех остальных это худшее время пользоваться
 * телепортацией: точка прибытия плывёт тем сильнее, чем плотнее шторм.
 *
 * Сверх того станцию простреливает проколами - вещи в открытых помещениях сами собой
 * оказываются в паре шагов от того места, где лежали. Ничего не ломается, но найти
 * положенное становится задачей.
 */

/// Разброс точки прибытия на пике, в тайлах.
#define BLUESPACE_STORM_NOISE 6
/// Шанс прокола за тик на полной интенсивности, в процентах. За пик это два-три десятка
/// сдвинутых предметов по всей станции: заметно, но не настолько, чтобы вещи перестали
/// лежать там, где их оставили.
#define BLUESPACE_STORM_PUNCTURE_CHANCE 35
/// На сколько тайлов уводит прокол.
#define BLUESPACE_STORM_PUNCTURE_RANGE 5
/// Шанс за тик, что на пике проявится блюспейс-аномалия, в процентах.
#define BLUESPACE_STORM_ANOMALY_CHANCE 4
/// Сколько аномалий шторм выпускает за раз максимум.
#define BLUESPACE_STORM_ANOMALY_CAP 2

/datum/round_event_control/space_weather/bluespace_storm
	name = "Bluespace Storm"
	typepath = /datum/round_event/space_weather/bluespace_storm
	enabled = TRUE
	weight = 5
	earliest_start = 20 MINUTES
	category = EVENT_CATEGORY_ANOMALIES
	severity = DIRECTOR_SEVERITY_MODERATE
	cost = 6
	disruption = DIRECTOR_DISRUPTION_MILD
	description = "A bluespace storm saturates local space: rich readings, teleports that \
		miss, and loose items shifting a few tiles on their own."

/datum/round_event/space_weather/bluespace_storm
	profile_id = "bluespace_storm"
	token = "event_bluespace_storm"
	phenomenon_name = "Блюспейс-шторм"
	peak_layer = /atom/movable/screen/parallax_layer/eris/close/bluespace_storm/peak
	tint_low = "#000000"
	tint_high = "#1e3ca0"
	sensor_yield_mult = 1.5
	approach_ticks = 35
	peak_ticks = 70
	departure_ticks = 30
	announce_source = "Отдел Блюспейс-Исследований NanoTrasen"
	announce_text = "Сканеры зафиксировали блюспейс-шторм рядом со станцией. Локальный блюспейс перенасыщается: точность телепортации в ближайшее время не гарантируется. Показания приборов при этом исключительно богаты - Отдел рекомендует снять их, пока шторм не ушёл."
	peak_announce_text = "Шторм в полную силу. Телепортация промахивается на несколько метров, в помещениях возможны самопроизвольные смещения предметов."
	announce_end_text = "Блюспейс-шторм ушёл из зоны видимости. Телепортация снова штатна."
	/// Сколько аномалий шторм уже выпустил.
	var/anomalies_released = 0

/datum/round_event/space_weather/bluespace_storm/apply_intensity(current_intensity)
	// Разброс растёт вместе со штормом: на подходе телепорт ещё точен, на пике уже нет.
	GLOB.bluespace_teleport_noise = round(BLUESPACE_STORM_NOISE * current_intensity)
	// Проколы и аномалии - только на пике: подход даёт время дойти туда, куда собирались
	// телепортом, и убрать со столов то, что жалко потерять.
	if(phase != PHENOMENON_PHASE_PEAK)
		return
	punch_through(current_intensity)
	release_anomaly(current_intensity)

/datum/round_event/space_weather/bluespace_storm/cleanup_effects()
	GLOB.bluespace_teleport_noise = 0

/datum/round_event/space_weather/bluespace_storm/sensor_readout()
	. = list("Спектр: блюспейс-фон перенасыщен, локальная метрика плывёт.")
	. += "Прогноз на пик: разброс телепортации до [BLUESPACE_STORM_NOISE] м, самопроизвольные смещения предметов."
	. += "Показания богаче обычного в полтора раза. Снимать их имеет смысл именно на пике."
	if(anomalies_released)
		. += "Зафиксировано проявившихся аномалий: [anomalies_released]."

/**
 * Прокол: вещь оказывается в нескольких шагах от того места, где лежала.
 *
 * Двигаются только вещи в открытых помещениях и только незакреплённые. Закреплённое
 * оборудование не трогаем намеренно: событие про потерянные предметы, а не про
 * разобранную на части станцию.
 */
/datum/round_event/space_weather/bluespace_storm/proc/punch_through(current_intensity)
	if(!prob(current_intensity * BLUESPACE_STORM_PUNCTURE_CHANCE))
		return
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!length(station_levels))
		return
	var/turf/source = find_indoor_turf(pick(station_levels))
	if(!source)
		return
	var/obj/item/drifter = locate(/obj/item) in source
	if(!drifter || drifter.anchored)
		return
	var/turf/target = get_step_rand_range(source, BLUESPACE_STORM_PUNCTURE_RANGE)
	if(!target || target.density)
		return
	do_teleport(drifter, target, no_effects = TRUE, channel = TELEPORT_CHANNEL_BLUESPACE, forced = TRUE)

/// Случайный турф внутри станции, где вообще может что-то лежать.
/datum/round_event/space_weather/bluespace_storm/proc/find_indoor_turf(z_level)
	RETURN_TYPE(/turf)
	for(var/attempt in 1 to PHENOMENON_PLACEMENT_TRIES)
		var/turf/candidate = locate(rand(PHENOMENON_EDGE_PAD, world.maxx - PHENOMENON_EDGE_PAD), rand(PHENOMENON_EDGE_PAD, world.maxy - PHENOMENON_EDGE_PAD), z_level)
		if(!candidate || isspaceturf(candidate) || candidate.density)
			continue
		// Скобки обязательны: `in` связывает слабее `!`, и без них выражение читается
		// как `(!locate(/obj/item)) in candidate` - число в contents турфа не встречается,
		// условие всегда ложно, и прок отдаёт первый попавшийся пустой турф.
		if(!(locate(/obj/item) in candidate))
			continue
		return candidate
	return null

/// Смещённый турф в пределах радиуса прокола.
/datum/round_event/space_weather/bluespace_storm/proc/get_step_rand_range(turf/source, range)
	RETURN_TYPE(/turf)
	return locate(clamp(source.x + rand(-range, range), 1, world.maxx), clamp(source.y + rand(-range, range), 1, world.maxy), source.z)

/// Изредка шторм выносит на станцию настоящую аномалию. Потолок жёсткий: шторм - это
/// неудобство и научное окно, а не подмена события с аномалиями.
/datum/round_event/space_weather/bluespace_storm/proc/release_anomaly(current_intensity)
	if(anomalies_released >= BLUESPACE_STORM_ANOMALY_CAP)
		return
	if(!prob(current_intensity * BLUESPACE_STORM_ANOMALY_CHANCE))
		return
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!length(station_levels))
		return
	var/turf/spot = find_indoor_turf(pick(station_levels))
	if(!spot)
		return
	new /obj/effect/anomaly/bluespace(spot)
	anomalies_released++

#undef BLUESPACE_STORM_NOISE
#undef BLUESPACE_STORM_PUNCTURE_CHANCE
#undef BLUESPACE_STORM_PUNCTURE_RANGE
#undef BLUESPACE_STORM_ANOMALY_CHANCE
#undef BLUESPACE_STORM_ANOMALY_CAP
