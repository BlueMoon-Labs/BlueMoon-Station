/**
 * # Космическая погода
 *
 * Станция проходит сквозь явление, и на несколько минут за иллюминаторами меняется
 * вся сцена. Набор явлений - порт из CEV-Eris, у них космическая погода была главным
 * и единственным потребителем параллакса.
 *
 * # Явление как фазовый процесс
 *
 * Событие идёт тремя фазами: подход, пик, уход. Из фазы считается ОДНА нормализованная
 * величина - интенсивность 0..1, - и от неё работает всё остальное: и плотность
 * картинки за бортом, и воздействие на станцию.
 *
 * Смысл фаз не в хронометраже, а в том, что интенсивность ВИДНА В ОКНЕ. Сцена бледная
 * и редкая на подходе, плотная и яркая на пике, гаснет на уходе. Это единственное
 * событие в игре, о котором узнают не по радио, а посмотрев наружу, и фазы существуют
 * для того, чтобы иллюминатор работал индикатором.
 *
 * Подтипу тики не выдаются. Он получает интенсивность и три необязательных хука:
 * on_phase_enter() на разовую работу, apply_intensity() на масштабируемую,
 * sensor_readout() на то, что покажет астрометрический сенсор.
 */
/// Попыток найти один свободный турф у корпуса, прежде чем сдаться.
#define PHENOMENON_PLACEMENT_TRIES 120
/// На сколько тайлов от точки должно найтись что-то твёрдое, чтобы она считалась
/// прикорпусной. Дальше начинается глубина, откуда явление не видно из окна.
#define PHENOMENON_HULL_RANGE 5
/// Отступ от края карты при выборе места: у самого края начинается переход на другой z.
#define PHENOMENON_EDGE_PAD (TRANSITIONEDGE + 6)

/**
 * Корень ветки. Сам ничего не показывает: без profile_id его start() падает,
 * поэтому шаблон выключен, а каждый конкретный подтип включает себя явно -
 * ровно как база спавнеров порталов.
 *
 * Категория выбирает ступень директора в /datum/round_event_control/New(), а из ступени
 * следуют цена, нагрузка и лимит одновременных. Ступени явлений заданы ЯВНО на подтипах,
 * а не выведены из категории: с категорией ANOMALIES почти всё уехало бы в "крупное",
 * где лимит одновременных крупных держал бы явления насмерть.
 */
/datum/round_event_control/space_weather
	name = "Space Weather"
	typepath = /datum/round_event/space_weather
	enabled = FALSE
	weight = 0
	max_occurrences = 1
	earliest_start = 10 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_FRIENDLY
	/// Явления делят затухание повторов и паузу семейства: шесть вариантов "станция
	/// пролетает мимо чего-то" не должны обходить анти-повторы поодиночке.
	family = "space_weather"

/datum/round_event_control/space_weather/can_fire(datum/director_signals/signals)
	// Сцена z-уровня одна на всех. Второе явление положило бы свой модификатор поверх
	// чужого, а сняв его первым, вернуло бы зрителям профиль ЧУЖОГО события посреди
	// этого чужого события. Пропускаем ход, пока предыдущее не отыграет.
	for(var/datum/round_event/space_weather/phenomenon in SSdirector.running)
		if(!QDELETED(phenomenon))
			return FALSE
	// Явление кладётся на станционные z. Их нет - показывать его негде.
	if(!length(SSmapping.levels_by_trait(ZTRAIT_STATION)))
		return FALSE
	return ..()

/datum/round_event/space_weather
	announce_when = 1
	start_when = 3
	fakeable = FALSE
	/// id профиля, который событие кладёт на станционные z.
	var/profile_id
	/// Токен модификатора. Обязан быть уникален среди источников параллакса.
	var/token
	/// Токен пикового слоя. Выводится из token в New(): повторный add_modifier с тем же
	/// токеном ЗАМЕНЯЕТ запись, поэтому пиковый слой на токене события снёс бы сам профиль.
	var/peak_token
	/// z-уровни, на которые лёг модификатор. Снимаем ровно с них.
	var/list/affected_z = list()
	/// Название явления по-русски. Читает астрометрический сенсор; name у контроля
	/// английское и уходит в панель админа, а не на экран игрока.
	var/phenomenon_name = "неопознанное явление"
	/// Множитель выдачи сенсора. Редкое и опасное явление стоит дороже рядового.
	var/sensor_yield_mult = 1
	/// Тексты объявлений. Пустой текст - на этой фазе событие молчит.
	var/announce_text
	var/peak_announce_text
	var/announce_end_text
	var/announce_source = "Отдел Астрономии NanoTrasen"
	/// Длительность перехода сцены.
	var/transition_time = 2 SECONDS

	// --- фазы ---
	/// Длительности фаз в тиках директора (DIRECTOR_WAIT, две секунды на тик).
	/// end_when из них выводится, а не проставляется руками.
	var/approach_ticks = 35
	var/peak_ticks = 70
	var/departure_ticks = 30
	/// Текущая фаза, PHENOMENON_PHASE_*.
	var/phase = PHENOMENON_PHASE_NONE
	/// Текущая интенсивность 0..1. Читают и сенсор, и подтипы.
	var/intensity = 0
	/// Интенсивность, при которой последний раз тянули цвет сцены.
	var/tinted_at = -1

	// --- картинка ---
	/// Плотный слой, который каркас сам вешает на пик и гасит на выходе из него.
	var/peak_layer
	/// Цвета сцены на нулевой и полной интенсивности. Оба пустые - сцена не красится.
	var/tint_low
	var/tint_high

	/// Прибрано ли за событием. Уборка идемпотентна и зовётся из двух мест.
	var/cleaned_up = FALSE

/datum/round_event/space_weather/New(my_processing = TRUE)
	. = ..()
	// Считается ПОСЛЕ ..(), потому что ..() зовёт setup(), а тот вправе разбросать
	// длительности фаз. Разъехавшись с суммой фаз, end_when обрубил бы фазу ухода,
	// и сцена снялась бы рывком посреди явления.
	end_when = start_when + approach_ticks + peak_ticks + departure_ticks
	if(token)
		peak_token = "[token]_peak"

// ---------------------------------------------------------------------------
// Жизненный цикл
// ---------------------------------------------------------------------------

/datum/round_event/space_weather/announce(fake)
	announce_phase(announce_text)

/datum/round_event/space_weather/start()
	if(!profile_id || !token)
		CRASH("Событие космической погоды [type] без профиля ('[profile_id]') или токена ('[token]')")
	// Подсветка идёт СВОИМ слоем поверх профиля, а не перекраской его ярусов: донорский
	// арт не помечен palette_tinted, его цвет - часть картинки, и красить его значило бы
	// испортить то, ради чего профиль и брали.
	var/list/extra_layers = (tint_low && tint_high) ? list(/atom/movable/screen/parallax_layer/tint/phenomenon) : null
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		SSparallax.add_modifier(station_z, token, profile_id, extra_layers, null, PARALLAX_PRIORITY_EVENT, transition_time)
		affected_z += station_z
	enter_phase(PHENOMENON_PHASE_APPROACH)

/datum/round_event/space_weather/tick()
	var/elapsed = activeFor - start_when
	intensity = intensity_for_elapsed(elapsed)
	var/next_phase = phase_for_elapsed(elapsed)
	if(next_phase != phase)
		enter_phase(next_phase)
	update_scene_tint()
	apply_intensity(intensity)

/datum/round_event/space_weather/end()
	cleanup()
	announce_phase(announce_end_text)

/**
 * Админская отмена в secrets.dm зовёт kill() НАПРЯМУЮ, минуя end(), и делает это до того,
 * как событие успело объявиться. Без уборки здесь сцена залипла бы с профилем явления
 * до конца раунда, а снять его было бы уже нечем: токен знало только удалённое событие.
 */
/datum/round_event/space_weather/kill()
	cleanup()
	return ..()

/**
 * Снимает со сцены всё, что положило событие. Идемпотентен: в обычном ходе зовётся из
 * end(), следом за ним из kill(), и второй раз обязан ничего не делать.
 */
/datum/round_event/space_weather/proc/cleanup()
	if(cleaned_up)
		return
	cleaned_up = TRUE
	cleanup_effects()
	for(var/station_z in affected_z)
		// Пиковый слой лежит ПОВЕРХ профиля, поэтому снимается первым: обратный порядок
		// на один пересбор показал бы сцену без профиля, но с пиковым слоем.
		SSparallax.remove_modifier(station_z, peak_token, 0)
		SSparallax.restore_profile(station_z, token, transition_time)
	affected_z.Cut()
	phase = PHENOMENON_PHASE_NONE
	intensity = 0

// ---------------------------------------------------------------------------
// Фазы
// ---------------------------------------------------------------------------

/// Фаза по числу тиков от start(). Единственный источник истины о фазе.
/datum/round_event/space_weather/proc/phase_for_elapsed(elapsed)
	if(elapsed < approach_ticks)
		return PHENOMENON_PHASE_APPROACH
	if(elapsed < approach_ticks + peak_ticks)
		return PHENOMENON_PHASE_PEAK
	return PHENOMENON_PHASE_DEPARTURE

/**
 * Интенсивность 0..1 по числу тиков от start().
 *
 * Кривая непрерывна на стыках фаз, и это требование, а не аккуратность: рывок
 * интенсивности означал бы рывок картинки в иллюминаторе и скачок воздействия
 * на станцию в один тик.
 *
 * Подход тянет 0 -> APPROACH_TOP. Пик выходит с APPROACH_TOP на единицу за первую
 * долю PEAK_RAMP, держит единицу в середине и спадает до DEPARTURE_TOP за последнюю
 * такую же долю. Уход гасит остаток в ноль.
 */
/datum/round_event/space_weather/proc/intensity_for_elapsed(elapsed)
	switch(phase_for_elapsed(elapsed))
		if(PHENOMENON_PHASE_APPROACH)
			if(approach_ticks <= 0)
				return PHENOMENON_APPROACH_TOP
			return PHENOMENON_APPROACH_TOP * clamp(elapsed / approach_ticks, 0, 1)
		if(PHENOMENON_PHASE_PEAK)
			if(peak_ticks <= 0)
				return PHENOMENON_DEPARTURE_TOP
			var/into_peak = clamp((elapsed - approach_ticks) / peak_ticks, 0, 1)
			if(into_peak < PHENOMENON_PEAK_RAMP)
				var/ramp = into_peak / PHENOMENON_PEAK_RAMP
				return PHENOMENON_APPROACH_TOP + (1 - PHENOMENON_APPROACH_TOP) * ramp
			if(into_peak < 1 - PHENOMENON_PEAK_RAMP)
				return 1
			var/fall = (into_peak - (1 - PHENOMENON_PEAK_RAMP)) / PHENOMENON_PEAK_RAMP
			return 1 - (1 - PHENOMENON_DEPARTURE_TOP) * clamp(fall, 0, 1)
	if(departure_ticks <= 0)
		return 0
	var/into_departure = clamp((elapsed - approach_ticks - peak_ticks) / departure_ticks, 0, 1)
	return PHENOMENON_DEPARTURE_TOP * (1 - into_departure)

/// Переход в фазу: разовая работа каркаса, затем хук подтипа.
/datum/round_event/space_weather/proc/enter_phase(next_phase)
	var/previous_phase = phase
	phase = next_phase
	switch(next_phase)
		if(PHENOMENON_PHASE_PEAK)
			announce_phase(peak_announce_text)
			apply_peak_layer()
		if(PHENOMENON_PHASE_DEPARTURE)
			clear_peak_layer()
	on_phase_enter(next_phase, previous_phase)

/// Одна точка объявления. Пустой текст означает "на этой фазе молчим".
/datum/round_event/space_weather/proc/announce_phase(text)
	if(!text)
		return
	priority_announce(text, sound = 'sound/misc/notice2.ogg', sender_override = announce_source)

// ---------------------------------------------------------------------------
// Картинка
// ---------------------------------------------------------------------------

/**
 * Вешает пиковый слой отдельным модификатором приоритетом выше профиля события.
 * Свой токен обязателен: add_modifier с токеном события заменил бы запись профиля.
 */
/datum/round_event/space_weather/proc/apply_peak_layer()
	if(!peak_layer)
		return
	for(var/station_z in affected_z)
		SSparallax.add_modifier(station_z, peak_token, extra_layers = list(peak_layer), priority = PARALLAX_PRIORITY_EVENT + 1)

/// Гасит пиковый слой анимацией. Снятие модификатора берёт на себя сама подсистема.
/datum/round_event/space_weather/proc/clear_peak_layer()
	if(!peak_layer)
		return
	for(var/station_z in affected_z)
		SSparallax.fade_out_modifier(station_z, peak_token, PHENOMENON_PEAK_FADE_TIME)

/**
 * Тянет цвет сцены под текущую интенсивность.
 *
 * Порог обязателен: без него плато пика анимировало бы слои каждый тик в тот же самый
 * цвет, у каждого клиента на z и по всем слоям сцены.
 */
/datum/round_event/space_weather/proc/update_scene_tint()
	var/tint = phase_tint(intensity)
	if(!tint)
		return
	if(tinted_at >= 0 && abs(intensity - tinted_at) < PHENOMENON_TINT_STEP)
		return
	tinted_at = intensity
	for(var/station_z in affected_z)
		SSparallax.animate_layer_type(station_z, /atom/movable/screen/parallax_layer/tint/phenomenon, tint, PHENOMENON_TINT_TIME)

/// Цвет сцены под интенсивность. По умолчанию - интерполяция между tint_low и tint_high;
/// без обоих сцена показывает палитру своего профиля как есть.
/datum/round_event/space_weather/proc/phase_tint(current_intensity)
	if(!tint_low || !tint_high)
		return null
	return BlendRGB(tint_low, tint_high, clamp(current_intensity, 0, 1))

// ---------------------------------------------------------------------------
// Хуки подтипа
// ---------------------------------------------------------------------------

/// Разовая работа на переходе фазы: спавн, уборка спавна, свои объявления.
/datum/round_event/space_weather/proc/on_phase_enter(next_phase, previous_phase)
	return

/// Масштабируемое воздействие. Зовётся каждый тик активного явления.
/datum/round_event/space_weather/proc/apply_intensity(current_intensity)
	return

/**
 * Уборка воздействия подтипа: спавны, трейты, подменённые значения.
 *
 * Зовётся РОВНО ОДИН РАЗ из cleanup(), до снятия сцены, и потому покрывает оба выхода -
 * и штатный end(), и админский kill() мимо него. Подтипу не нужно ни своего гарда
 * идемпотентности, ни знания о том, каким путём событие закончилось.
 */
/datum/round_event/space_weather/proc/cleanup_effects()
	return

/// Строки для астрометрического сенсора: что именно будет на пике.
/datum/round_event/space_weather/proc/sensor_readout()
	return list()

// ---------------------------------------------------------------------------
// Справки для сенсора
// ---------------------------------------------------------------------------

/**
 * Секунд до начала пика. Ноль, если пик уже идёт или прошёл.
 *
 * Тик берётся у живой подсистемы, а не из DIRECTOR_WAIT: дефайн объявлен в самом
 * director.dm, и порядок включения в .dme решал бы, известен ли он тут.
 */
/datum/round_event/space_weather/proc/seconds_to_peak()
	var/ticks_left = approach_ticks - (activeFor - start_when)
	if(ticks_left <= 0)
		return 0
	return round(ticks_left * SSdirector.wait * 0.1)

/// Человекочитаемое имя фазы.
/datum/round_event/space_weather/proc/phase_name()
	switch(phase)
		if(PHENOMENON_PHASE_APPROACH)
			return "подход"
		if(PHENOMENON_PHASE_PEAK)
			return "пик"
		if(PHENOMENON_PHASE_DEPARTURE)
			return "уход"
	return "нет"

/// Явление, которое сейчас идёт на станции. null, если за бортом обычный космос.
/proc/active_space_phenomenon()
	RETURN_TYPE(/datum/round_event/space_weather)
	for(var/datum/round_event/space_weather/phenomenon in SSdirector.running)
		if(QDELETED(phenomenon) || phenomenon.phase == PHENOMENON_PHASE_NONE)
			continue
		return phenomenon
	return null

// ---------------------------------------------------------------------------
// Космос у корпуса
// ---------------------------------------------------------------------------

/**
 * Свободный космический турф у самого корпуса станции. null, если не нашлось.
 *
 * Ищем не равномерной выборкой по z, а от твёрдого турфа наружу: космоса на станционном
 * уровне десятки тысяч тайлов, и подавляющее большинство из них - глубина, откуда явление
 * не видно из окна и куда никто не полетит. Выборка от станции наружу попадает в
 * прикорпусное кольцо на порядок чаще.
 */
/datum/round_event/space_weather/proc/find_hull_space_turf(z_level)
	RETURN_TYPE(/turf)
	for(var/attempt in 1 to PHENOMENON_PLACEMENT_TRIES)
		var/turf/inside = locate(rand(PHENOMENON_EDGE_PAD, world.maxx - PHENOMENON_EDGE_PAD), rand(PHENOMENON_EDGE_PAD, world.maxy - PHENOMENON_EDGE_PAD), z_level)
		if(!inside || isspaceturf(inside))
			continue
		var/direction = pick(GLOB.cardinals)
		var/turf/probe = inside
		for(var/step in 1 to PHENOMENON_HULL_RANGE)
			probe = get_step(probe, direction)
			if(!probe)
				break
			if(!isspaceturf(probe))
				continue
			if(length(probe.contents) || !near_hull(probe))
				break
			return probe
	return null

/// Есть ли что-то твёрдое в пределах досягаемости по любому из четырёх направлений.
/// Это и есть контракт "у корпуса", который обязана соблюдать любая выборка места.
/datum/round_event/space_weather/proc/near_hull(turf/candidate)
	for(var/direction in GLOB.cardinals)
		var/turf/probe = candidate
		for(var/step in 1 to PHENOMENON_HULL_RANGE)
			probe = get_step(probe, direction)
			if(!probe)
				break
			if(!isspaceturf(probe))
				return TRUE
	return FALSE

// ---------------------------------------------------------------------------
// Фазовая подсветка
// ---------------------------------------------------------------------------

/**
 * Аддитивный фуллскрин-слой, которым каркас показывает интенсивность явления.
 *
 * Цвет ведёт update_scene_tint() от tint_low к tint_high, а не палитра профиля, поэтому
 * palette_tinted тут снят: иначе слой перекрашивался бы ещё и чужими модификаторами.
 * Аддитивное смешение делает почти чёрный цвет незаметным - именно так и работает
 * шкала: на подходе подсветки фактически нет, на пике она в полную силу.
 */
/atom/movable/screen/parallax_layer/tint/phenomenon
	palette_tinted = FALSE
	color = "#000000"
	alpha = 60
	layer = 4.2
	fade_in_time = 6 SECONDS

