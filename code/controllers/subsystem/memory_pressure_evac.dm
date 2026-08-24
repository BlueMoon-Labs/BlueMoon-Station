/**
 * Конец раунда по давлению памяти.
 *
 * DreamDaemon 32-битный, потолок адресного пространства меряется в рантайме и на проде
 * равен 4093 МБ. Раунд стартует уже с 2.2-2.6 ГБ и растёт на 5-13 МБ/мин, поэтому длинный
 * многолюдный раунд упирается в потолок гарантированно: 10105 (24.08.2026, Delta, 130
 * игроков, 210 минут) закончился ровно на 4094.1 из 4094, 10102 - на 3966 из 4093. Смерть
 * там молчаливая: процесса просто не становится, раунд в базе остаётся незакрытым, игроки
 * получают разрыв соединения вместо экрана итогов, а следом идёт волна реконнекта, которая
 * добивает уже следующий раунд.
 *
 * Предупреждение админам (см. check_memory_admin_warning в time_track.dm) эту смерть не
 * ловит: оно уходит в чат, и если админа у пульта нет, раунд едет в потолок как ехал.
 * Поэтому здесь действие, а не сообщение.
 *
 * Две ступени:
 *
 * 1. **Эвакуация.** Вызывается шаттл, отзыв запрещён, в эфир идёт отчёт командования.
 *    Раунд заканчивается штатно: итоги, блэкбокс, запись в базу, чистый рестарт процесса.
 *    Условия И: занято не меньше MEMORY_EVAC_CEILING_FRACTION потолка И по скорости роста
 *    до потолка осталось не больше memory_pressure_evac_lead_minutes из конфига. Одно только "занято много"
 *    порогом быть не может - раунд СТАРТУЕТ с 55-64% потолка, а по одной только скорости
 *    сорвалась бы любая ступенька на старте.
 *
 * 2. **Бэкстоп.** Если после вызова шаттла память всё равно дошла до
 *    MEMORY_FORCE_END_HEADROOM_MB от потолка (крейсер сбили, шаттл заминировали, раунд
 *    завис на подсчёте) - раунд завершается принудительно. Порог намеренно тугой: в 10105
 *    последние 120 МБ заняли двадцать минут, то есть бэкстоп не отнимает у раунда времени,
 *    пока эвакуация справляется сама.
 *
 * Обе ступени срабатывают не больше одного раза за раунд и пишут строку в лог мира: разбор
 * постфактум обязан отличать "раунд закончился по памяти" от "экипаж улетел сам".
 */

/// Ступень не нужна: запаса хватает.
#define MEMORY_ENDGAME_NONE 0
/// Пора вызывать шаттл.
#define MEMORY_ENDGAME_EVAC 1
/// Пора завершать раунд принудительно.
#define MEMORY_ENDGAME_FORCE_END 2

/// Доля потолка адресного пространства, ниже которой автоэвакуация не рассматривается вовсе.
///
/// Планка проверена прогоном по настоящим раундам 24.08.2026 (потолок 4093-4094):
/// 0.85 и 0.90 срывались на 10105 на 104-й минуте, потому что получасовое окно роста в тот
/// момент показывало 9.7 МБ/мин против 5.7 средних - раунд обрезался бы на 92 минуты зря.
/// 0.93 срабатывает там же на 170-й при 96% потолка и обрезает раунд на 25 минут вместо
/// падения на 211-й. На 10103 (кончился на 3292) и 10108 (3653) не срабатывает вовсе - и
/// это правильно, тем раундам эвакуация была не нужна.
#define MEMORY_EVAC_CEILING_FRACTION 0.93

/// Раньше этого времени раунда автоэвакуации не будет ни при каких цифрах. Роундстарт сам
/// по себе даёт скачок в полгигабайта, и окно оценки в эти минуты меряет именно его.
#define MEMORY_EVAC_MIN_ROUND_TIME (40 MINUTES)

/// Множитель к таймеру шаттла на автовызове. Штатный вызов на зелёном коде - двадцать минут;
/// столько ждать нельзя, ради этого вся ступень и заводилась.
#define MEMORY_EVAC_CALL_COEFFICIENT 0.5

/// Остаток до потолка в МБ, на котором раунд завершается принудительно.
///
/// Планка тугая намеренно: между вызовом шаттла (170-я минута 10105) и этим порогом (186-я)
/// должно поместиться всё отлетание - таймер 5 минут при MEMORY_EVAC_CALL_COEFFICIENT,
/// стыковка, окно эвакуации, перелёт и подсчёт итогов. Если бэкстоп поставить раньше, он
/// будет добивать раунды, которые эвакуация и так уже спасала.
///
/// Сотня мегабайт - это меньше, чем p95 невидимого сэмплеру всплеска (74 МБ по замеру за
/// 24.08), то есть запас тут почти нулевой. Так и задумано: это последняя ступень перед
/// молчаливой смертью, а не комфортный порог.
#define MEMORY_FORCE_END_HEADROOM_MB 100

/// Автоэвакуация уже вызвана в этом раунде.
/datum/controller/subsystem/time_track/var/memory_evac_called = FALSE
/// Принудительное завершение по бэкстопу уже запрошено в этом раунде.
/datum/controller/subsystem/time_track/var/memory_force_ended = FALSE

/**
 * Ступени конца раунда по памяти. Зовётся из того же замера, что и лестница порогов.
 *
 * Аргументы:
 * * vsz - VmSize этого замера в МБ.
 */
/datum/controller/subsystem/time_track/proc/check_memory_pressure_endgame(vsz)
	if(!SSticker || SSticker.current_state != GAME_STATE_PLAYING)
		return
	var/step = memory_endgame_step(
		vsz,
		process_address_ceiling_mb,
		memory_growth_mb_per_minute,
		world.time,
		CONFIG_GET(number/memory_pressure_evac_lead_minutes),
		memory_evac_called,
		memory_force_ended,
		CONFIG_GET(flag/memory_pressure_evac))
	switch(step)
		if(MEMORY_ENDGAME_FORCE_END)
			force_end_round_on_memory(vsz, process_address_ceiling_mb - vsz)
		if(MEMORY_ENDGAME_EVAC)
			call_evac_on_memory(vsz, process_address_ceiling_mb - vsz, 				memory_minutes_to_ceiling(vsz, process_address_ceiling_mb, memory_growth_mb_per_minute))

/**
 * Чистое решение: какая ступень нужна при этих цифрах. Отдельным глобальным проком, потому
 * что это единственная часть механизма, которую можно проверить юнит-тестом - вызвать шаттл
 * и завершить раунд в тесте нельзя, а ошибиться порогом здесь стоит целого раунда.
 *
 * Аргументы:
 * * vsz_mb - VmSize замера
 * * ceiling_mb - потолок адресного пространства, 0 если не замерен
 * * growth_mb_per_minute - скорость роста по окну, 0 если окно ещё короткое
 * * round_time - world.time; роундстарт сам даёт скачок в полгигабайта, и раньше
 *   MEMORY_EVAC_MIN_ROUND_TIME окно оценки меряет именно его
 * * lead_minutes - расчётный запас, ниже которого пора уводить раунд
 * * evac_already_called, force_already_ended - ступени одноразовые
 * * evac_enabled - флаг конфига; на бэкстоп он НЕ влияет: выключенная автоэвакуация
 *   означает "не трогай раунд заранее", а не "дай процессу умереть молча"
 */
/proc/memory_endgame_step(vsz_mb, ceiling_mb, growth_mb_per_minute, round_time, lead_minutes, evac_already_called, force_already_ended, evac_enabled)
	if(!ceiling_mb || !vsz_mb)
		return MEMORY_ENDGAME_NONE
	// Бэкстоп проверяется ПЕРВЫМ и не смотрит на evac_already_called: он существует ровно
	// для случая, когда шаттл уже вызван, а память всё равно доехала до края.
	if(!force_already_ended && (ceiling_mb - vsz_mb) <= MEMORY_FORCE_END_HEADROOM_MB)
		return MEMORY_ENDGAME_FORCE_END
	if(evac_already_called || !evac_enabled)
		return MEMORY_ENDGAME_NONE
	if(round_time < MEMORY_EVAC_MIN_ROUND_TIME)
		return MEMORY_ENDGAME_NONE
	if(vsz_mb < ceiling_mb * MEMORY_EVAC_CEILING_FRACTION)
		return MEMORY_ENDGAME_NONE
	var/minutes_left = memory_minutes_to_ceiling(vsz_mb, ceiling_mb, growth_mb_per_minute)
	if(isnull(minutes_left) || minutes_left > lead_minutes)
		return MEMORY_ENDGAME_NONE
	return MEMORY_ENDGAME_EVAC

/// Вызывает шаттл и запрещает отзыв. Отдельным проком, чтобы условие срабатывания
/// читалось без деталей работы с SSshuttle.
/datum/controller/subsystem/time_track/proc/call_evac_on_memory(vsz, headroom_mb, minutes_left)
	memory_evac_called = TRUE

	var/reason = "процесс занял [vsz] из [process_address_ceiling_mb] МБ адресного пространства \
		([round(vsz / process_address_ceiling_mb * 100)]% потолка, до края [round(headroom_mb)] МБ), \
		рост [memory_growth_mb_per_minute] МБ/мин, расчётного запаса [minutes_left] мин"

	if(!SSshuttle?.emergency)
		log_world("## MEMORY: автоэвакуация невозможна - эвакуационного шаттла нет. [reason]")
		message_admins("<span class='boldannounce'>ПАМЯТЬ: [reason]. Эвакуационного шаттла нет - уводите раунд вручную, иначе процесс умрёт молча.</span>")
		return

	// Отзыв запрещается ДО вызова: между request() и следующей строкой мир успевает
	// прокрутить тик, и экипаж, увидевший вызов, технически успевает нажать отзыв.
	SSshuttle.emergencyNoRecall = TRUE
	SSshuttle.emergency.request(null, null, "Автоматическая эвакуация: критическое состояние систем станции.", FALSE, MEMORY_EVAC_CALL_COEFFICIENT)

	log_world("## MEMORY: вызвана автоэвакуация - [reason]")
	message_admins("<span class='boldannounce'>ПАМЯТЬ: вызван эвакуационный шаттл автоматически, отзыв запрещён. [reason]. \
		Иначе процесс умирает молча и без сохранения раунда.</span>")

	priority_announce("Диагностические системы Нанотрейзен зафиксировали каскадный отказ вычислительного контура [station_name()]. \
		Продолжение смены признано небезопасным. Эвакуационный шаттл направлен к станции, отзыв заблокирован.", \
		"Экстренное уведомление командования")

/// Принудительное завершение раунда: последняя ступень перед молчаливой смертью процесса.
/datum/controller/subsystem/time_track/proc/force_end_round_on_memory(vsz, headroom_mb)
	memory_force_ended = TRUE
	var/reason = "процесс занял [vsz] из [process_address_ceiling_mb] МБ, до потолка осталось [round(headroom_mb)] МБ"
	log_world("## MEMORY: раунд завершён принудительно - [reason]")
	message_admins("<span class='boldannounce'>ПАМЯТЬ: раунд завершается принудительно, [reason]. \
		Дальше процесс умрёт молча и раунд не запишется вообще.</span>")
	SSticker.force_ending = 1
