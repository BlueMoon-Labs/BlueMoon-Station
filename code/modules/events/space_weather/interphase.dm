/**
 * # Блюспейс-интерфаза
 *
 * Зеркало шторма: блюспейс не перенасыщен, а схлопнут. Пока станция проходит интерфазу,
 * телепортация не работает вовсе, а идущий на вызов шаттл не может подойти.
 *
 * Взамен интерфаза - единственное окно, когда сенсор ловит эхо того, что по ту сторону:
 * выдача полуторная с лишним, и снять её больше негде.
 *
 * Событие намеренно не запускается при уже объявленной эвакуации, а шаттл задерживает
 * только на время пика. Отрезать экипажу отход насовсем - это не сложность, это тупик.
 */

/datum/round_event_control/space_weather/interphase
	name = "Bluespace Interphase"
	typepath = /datum/round_event/space_weather/interphase
	enabled = TRUE
	weight = 5
	earliest_start = 25 MINUTES
	category = EVENT_CATEGORY_ANOMALIES
	// Ломает мало - отключает канал, которым пользуются не каждую смену, - но ощущается
	// сильно. Ступень "малое", а не "среднее": цена по бюджету должна быть по факту.
	severity = DIRECTOR_SEVERITY_MINOR
	cost = 2
	disruption = DIRECTOR_DISRUPTION_MILD
	description = "Bluespace goes dead: teleports fail and the shuttle cannot approach \
		until the station is through."

/datum/round_event_control/space_weather/interphase/can_fire(datum/director_signals/signals)
	// Эвакуация уже объявлена - интерфаза отрезала бы экипажу отход. Это не сложность,
	// это тупик, и происходил бы он в самый неподходящий момент раунда.
	//
	// Отозванный вызов сюда не считается: EMERGENCY_IDLE_OR_RECALLED - готовый предикат
	// кодовой базы ровно для этого, и отзыв означает, что эвакуации снова нет.
	if(SSshuttle.emergency && !EMERGENCY_IDLE_OR_RECALLED)
		return FALSE
	return ..()

/datum/round_event/space_weather/interphase
	profile_id = "bluespace_interphase"
	token = "event_interphase"
	phenomenon_name = "Блюспейс-интерфаза"
	// Пикового яруса нет: у интерфазы один ровный фон без ярусов, уплотнять нечего.
	// Всю шкалу интенсивности здесь ведёт подсветка.
	tint_low = "#000000"
	tint_high = "#42207a"
	sensor_yield_mult = 1.6
	approach_ticks = 25
	peak_ticks = 45
	departure_ticks = 20
	announce_source = "Отдел Блюспейс-Исследований NanoTrasen"
	announce_text = "Станция задевает край блюспейс-интерфазы. Локальный блюспейс схлопывается: на время прохождения телепортация будет недоступна, подход шаттла невозможен. Пространство за бортом будет выглядеть неправильно. Это ожидаемо."
	peak_announce_text = "Блюспейс-связность потеряна полностью. Телепортация не работает. Отдел Блюспейс-Исследований снимает эхо-показания: другого такого окна не будет."
	announce_end_text = "Интерфаза свёрнута. Блюспейс-связность восстановлена."

/datum/round_event/space_weather/interphase/on_phase_enter(next_phase, previous_phase)
	// Канал глушится только на пике: подход и уход оставляют экипажу время дойти туда,
	// куда он собирался попасть телепортом.
	GLOB.bluespace_teleport_blocked = (next_phase == PHENOMENON_PHASE_PEAK)

/datum/round_event/space_weather/interphase/apply_intensity(current_intensity)
	if(phase != PHENOMENON_PHASE_PEAK)
		return
	hold_shuttle()

/datum/round_event/space_weather/interphase/cleanup_effects()
	GLOB.bluespace_teleport_blocked = FALSE

/datum/round_event/space_weather/interphase/sensor_readout()
	. = list("Спектр: блюспейс-фон обнулён. Локальная метрика замкнута сама на себя.")
	. += "Прогноз на пик: телепортация не работает, подход шаттла невозможен."
	. += "Эхо-показания снимаются только сейчас: выдача выше обычной более чем в полтора раза."

/**
 * Держит идущий на вызов шаттл, пока станция в интерфазе.
 *
 * Таймер именно отодвигается, а не останавливается: событие может кончиться раньше, чем
 * до него дойдут руки, и остановленный таймер пришлось бы кому-то запускать обратно.
 * Отодвинутый доигрывает сам, как только интерфаза перестала его двигать.
 *
 * Прибавка равна РОВНО тику директора: за тик таймер уходит на столько же, и прибавка
 * его замораживает. Любая большая величина означала бы, что интерфаза не держит шаттл,
 * а отгоняет его - за девяносто секунд пика по четыре секунды за тик шаттл потерял бы
 * три минуты вместо полутора.
 */
/datum/round_event/space_weather/interphase/proc/hold_shuttle()
	if(!SSshuttle.emergency || SSshuttle.emergency.mode != SHUTTLE_CALL)
		return
	SSshuttle.emergency.setTimer(SSshuttle.emergency.timeLeft(1) + SSdirector.wait)
