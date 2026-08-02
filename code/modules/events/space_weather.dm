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
	disruption = DIRECTOR_DISRUPTION_AMBIENT
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
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		SSparallax.set_profile(station_z, profile_id, token, PARALLAX_PRIORITY_EVENT, transition_time)
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
		SSparallax.animate_tint(station_z, token, tint, PHENOMENON_TINT_TIME)

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

/// Строки для астрометрического сенсора: что именно будет на пике.
/datum/round_event/space_weather/proc/sensor_readout()
	return list()

// ---------------------------------------------------------------------------
// Явления
// ---------------------------------------------------------------------------

/datum/round_event_control/space_weather/graveyard
	name = "Ship Graveyard"
	typepath = /datum/round_event/space_weather/graveyard
	enabled = TRUE
	weight = 9
	description = "The station drifts past a field of derelict hulls."

/datum/round_event/space_weather/graveyard
	profile_id = "graveyard"
	token = "event_graveyard"
	approach_ticks = 40
	peak_ticks = 80
	departure_ticks = 30
	announce_text = "Станция входит в зону скопления списанных корпусов. Обломки принадлежат кораблям, потерянным в этом секторе за последние сорок лет; траектории просчитаны, столкновение исключено. Отдел Астрономии просит воздержаться от несанкционированных выходов за борт."
	announce_end_text = "Станция покинула зону скопления обломков."

/datum/round_event_control/space_weather/micro_debris
	name = "Micro Debris Field"
	typepath = /datum/round_event/space_weather/micro_debris
	enabled = TRUE
	weight = 10
	description = "The station passes through a cloud of micro debris."

/datum/round_event/space_weather/micro_debris
	profile_id = "micro_debris"
	token = "event_micro_debris"
	approach_ticks = 30
	peak_ticks = 60
	departure_ticks = 25
	announce_text = "Станция проходит через поле микрообломков. Частицы слишком малы, чтобы повредить обшивку, но в ближайшие минуты за иллюминаторами будет заметна взвесь. Явление безопасно."
	announce_end_text = "Поле микрообломков пройдено."

/datum/round_event_control/space_weather/bluespace_storm
	name = "Bluespace Storm"
	typepath = /datum/round_event/space_weather/bluespace_storm
	enabled = TRUE
	weight = 6
	earliest_start = 20 MINUTES
	description = "A bluespace storm passes near the station."

/datum/round_event/space_weather/bluespace_storm
	profile_id = "bluespace_storm"
	token = "event_bluespace_storm"
	approach_ticks = 35
	peak_ticks = 70
	departure_ticks = 30
	announce_source = "Отдел Блюспейс-Исследований NanoTrasen"
	announce_text = "Сканеры зафиксировали блюспейс-шторм рядом со станцией. Искажения пространства останутся за пределами корпуса. Персоналу рекомендуется не пугаться вспышек за иллюминаторами."
	announce_end_text = "Блюспейс-шторм ушёл из зоны видимости."

/datum/round_event_control/space_weather/ion_blizzard
	name = "Ion Blizzard"
	typepath = /datum/round_event/space_weather/ion_blizzard
	enabled = TRUE
	weight = 7
	description = "An ion blizzard sweeps past the station."

/datum/round_event/space_weather/ion_blizzard
	profile_id = "ion_blizzard"
	token = "event_ion_blizzard"
	// Подход длиннее пика: буря вознаграждает подготовленную энергосеть, а подготовка
	// требует времени. Короткий подход превратил бы событие в лотерею.
	approach_ticks = 40
	peak_ticks = 60
	departure_ticks = 25
	announce_source = "Отдел Метеорологии NanoTrasen"
	announce_text = "Мимо станции проходит ионная буря. Заряженные частицы рассеиваются в корпусе без последствий для оборудования. Наблюдать можно из любого отсека с видом на космос."
	announce_end_text = "Ионная буря прошла."

/datum/round_event_control/space_weather/interphase
	name = "Bluespace Interphase"
	typepath = /datum/round_event/space_weather/interphase
	enabled = TRUE
	weight = 4
	earliest_start = 25 MINUTES
	description = "Space outside the station briefly stops looking like space."

/datum/round_event/space_weather/interphase
	profile_id = "bluespace_interphase"
	token = "event_interphase"
	approach_ticks = 25
	peak_ticks = 45
	departure_ticks = 20
	announce_source = "Отдел Блюспейс-Исследований NanoTrasen"
	announce_text = "Станция задевает край блюспейс-интерфазы. В ближайшие минуты пространство за бортом будет выглядеть неправильно. Это ожидаемо. Смотреть можно, тревожиться не нужно."
	announce_end_text = "Интерфаза свёрнута, пространство за бортом восстановлено."

/datum/round_event_control/space_weather/photon_vortex
	name = "Photon Vortex"
	typepath = /datum/round_event/space_weather/photon_vortex
	enabled = TRUE
	weight = 3
	earliest_start = 30 MINUTES
	description = "A collapsed object drifts into view."

/datum/round_event/space_weather/photon_vortex
	profile_id = "photon_vortex"
	token = "event_photon_vortex"
	approach_ticks = 45
	peak_ticks = 80
	departure_ticks = 35
	announce_source = "Отдел Астрономии NanoTrasen"
	announce_text = "В зоне видимости станции оказался коллапсировавший объект. Расстояние безопасно, гравитационного воздействия на станцию не ожидается. Отдел Астрономии рекомендует воспользоваться случаем: следующее такое сближение произойдёт нескоро."
	announce_end_text = "Коллапсировавший объект вышел из зоны видимости."
