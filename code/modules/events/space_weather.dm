/**
 * # Космическая погода
 *
 * Станция проходит сквозь явление, и на несколько минут за иллюминаторами
 * меняется вся сцена. Порт набора событий CEV-Eris - у них космическая погода
 * была главным и единственным потребителем параллакса.
 *
 * События ЧИСТО ВИЗУАЛЬНЫЕ, как молекулярное облако. Механику Eris переносить
 * не стали осознанно: пробои блюспейса и битые лампы завязаны на их корабль, а
 * деление яркости всего света в мире на четыре они и сами пометили в коде как
 * неоптимизированное и отключили.
 *
 * Профили этих событий держат вес 0 в автоподборе: явление, мимо которого
 * пролетаешь, не должно оказаться постоянным фоном раунда, иначе событие
 * перестанет что-либо менять.
 */
/**
 * Корень ветки. Сам ничего не показывает: без profile_id его start() падает,
 * поэтому шаблон выключен, а каждый конкретный подтип включает себя явно -
 * ровно как база спавнеров порталов.
 *
 * Категория тут не украшение и не группировка в панели: её ЕДИНСТВЕННЫЙ читатель -
 * /datum/round_event_control/New(), где она выбирает ступень директора, а из
 * ступени уже следуют цена, нагрузка и лимит одновременных. Смена обоев за
 * иллюминатором обязана оставаться FRIENDLY, то есть флейвором за ноль: в любой
 * ступени тяжелее она начнёт занимать бюджет настоящего контента и держать
 * директора в уверенности, что на станции что-то происходит.
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

/datum/round_event/space_weather
	announce_when = 1
	start_when = 3
	end_when = 150
	fakeable = FALSE
	/// id профиля, который событие кладёт на станционные z.
	var/profile_id
	/// Токен модификатора. Обязан быть уникален среди источников параллакса.
	var/token
	/// z-уровни, на которые лёг модификатор. Снимаем ровно с них.
	var/list/affected_z = list()
	/// Тексты объявлений. Пустой конец - объявления в конце не будет.
	var/announce_text
	var/announce_end_text
	var/announce_source = "Отдел Астрономии NanoTrasen"
	/// Длительность перехода сцены.
	var/transition_time = 2 SECONDS

/datum/round_event/space_weather/announce(fake)
	if(!announce_text)
		return
	priority_announce(announce_text, sound = 'sound/misc/notice2.ogg', sender_override = announce_source)

/datum/round_event/space_weather/start()
	if(!profile_id || !token)
		CRASH("Событие космической погоды [type] без профиля ('[profile_id]') или токена ('[token]')")
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		SSparallax.set_profile(station_z, profile_id, token, PARALLAX_PRIORITY_EVENT, transition_time)
		affected_z += station_z

/datum/round_event/space_weather/end()
	for(var/station_z in affected_z)
		SSparallax.restore_profile(station_z, token, transition_time)
	affected_z.Cut()
	if(announce_end_text)
		priority_announce(announce_end_text, sound = 'sound/misc/notice2.ogg', sender_override = announce_source)

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
	end_when = 200
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
	end_when = 120
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
	end_when = 160
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
	end_when = 140
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
	end_when = 100
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
	end_when = 180
	announce_source = "Отдел Астрономии NanoTrasen"
	announce_text = "В зоне видимости станции оказался коллапсировавший объект. Расстояние безопасно, гравитационного воздействия на станцию не ожидается. Отдел Астрономии рекомендует воспользоваться случаем: следующее такое сближение произойдёт нескоро."
	announce_end_text = "Коллапсировавший объект вышел из зоны видимости."
