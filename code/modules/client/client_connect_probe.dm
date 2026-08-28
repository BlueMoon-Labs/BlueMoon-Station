/**
 * Цена подключения клиента: сколько адресного пространства и стенного времени стоит
 * один client/New(), по этапам.
 *
 * Раунд 10083 (Delta, 107 игроков): 300 из 444 МБ роста VmSize за час пришли тринадцатью
 * ступеньками по 12-84 МБ, и в каждом таком окне число инстансов не двигалось. Детектор
 * спайков в те же секунды показывал winget <окно>.dpi / winexists browseroutput на
 * 1.3-2.9 с - то есть client/New() ждал ответа клиента, - а строка ACCESS: Login у тех же
 * ckey появлялась на 20-100 секунд позже. Это клиенты с холодным кэшем, которым сервер
 * стримит ресурсы; с числом входов в окне корреляции нет (r = -0.27): платят не все входы,
 * а только такие. Ни перепись инстансов, ни перепись датумов этих мегабайт не видят - они
 * не в объектах DM.
 *
 * Прибор снимает VmSize/RSS на входе в client/New() и после каждого этапа, который может
 * ждать клиента или грузить данные (prefs, встроенный Login, первый round-trip dpi, хвост),
 * и через CONNECT_PROBE_FOLLOWUP_DELAY после входа делает контрольный замер: стриминг
 * ресурсов продолжается и после New(). Контрольный замер честен только пока между ним и
 * входом никто больше не подключался - поэтому в строке стоит число других подключений за
 * это время: при нуле дельта принадлежит этому клиенту, при большем числе это сумма.
 *
 * На Windows /proc нет: тогда в строке остаются только времена этапов, и это тоже ответ на
 * вопрос "сколько секунд сервер провёл в ожидании этого клиента".
 */

/// Через сколько после конца client/New() снять контрольный замер: стриминг ресурсов
/// клиенту продолжается после входа, и ступенька может прийти уже после Login.
#define CONNECT_PROBE_FOLLOWUP_DELAY (60 SECONDS)

/// Порядковый номер подключения за раунд: по разнице номеров контрольный замер видит,
/// сколько других клиентов вошло между концом New() и им самим.
GLOBAL_VAR_INIT(client_connect_serial, 0)

/// Мегабайты VmSize, которые фоновая работа уже записала на СВОЙ счёт. Счётчик только
/// растёт; прибор подключения вычитает его прирост за этап, потому что client/New() спит
/// секундами в acquire_dpi() и всё, что успело сделаться в это окно, иначе выставляется
/// счётом входящему игроку. В раунде 10119 так набежало 368 "МБ dpi" на десяти входах,
/// пока рядом строился свет z-уровней.
GLOBAL_VAR_INIT(memory_attributed_elsewhere_mb, 0)

/// Записать МБ VmSize на счёт фоновой работы. Единственная точка записи в счётчик:
/// монотонность - его контракт, а не деталь вызывающего (см.
/// /datum/unit_test/lighting_cost_counter_is_monotonic). Отрицательная дельта между
/// отметками законна и означает "за окно ничего не сделано", а не "верните мегабайты".
/proc/attribute_memory_elsewhere_mb(spent_mb)
	if(spent_mb > 0)
		GLOB.memory_attributed_elsewhere_mb += spent_mb

/// Готовая строка одного этапа. Вынесена из mark() отдельным проком: это единственное
/// место, где живёт арифметика вычета фона, и без живого клиента её иначе не проверить.
/// Вычтенный фон НАЗЫВАЕТСЯ в строке - молчаливый вычет прячет от читателя, что окно
/// было не его.
/proc/probe_stage_line(stage_name, seconds, vsz_delta, attributed_delta, measured = TRUE)
	var/line = "[stage_name] [seconds]с"
	if(!measured)
		return line
	var/background = probe_stage_background_mb(attributed_delta)
	line += " [format_mb_delta(probe_stage_own_mb(vsz_delta, attributed_delta))]"
	if(background > 0)
		line += " (мимо: [format_mb_delta(background)] фоновой работы)"
	return line

/// Сколько из окна принадлежит самому этапу. Прибор раздачи тел (ticker_handoff_probe.dm)
/// берёт ту же цифру, чтобы записать её на счёт фона - арифметика вычета обязана жить в
/// одном месте, иначе две копии разъедутся молча.
/proc/probe_stage_own_mb(vsz_delta, attributed_delta)
	return vsz_delta - probe_stage_background_mb(attributed_delta)

/// Счётчик фона монотонный, но отрицательная разница между отметками смысла не имеет и
/// прибавлять этапу мегабайт не должна.
/proc/probe_stage_background_mb(attributed_delta)
	return max(attributed_delta, 0)

/**
 * Шёл ли мир ещё инициализацией, когда открылось это окно замера.
 *
 * Master.current_runlevel остаётся null до первого SetRunLevel() в конце Master.Initialize(),
 * и это единственный доступный признак "мир ещё грузится". Флага "инициализация закончена"
 * в кодовой базе нет: initializations_finished_with_no_players_logged_in отвечает на другой
 * вопрос (был ли кто-то подключён в последнюю секунду инициализации) и null не только во
 * время инициализации, но и после неё, если игроки были.
 */
/proc/probe_started_during_world_init()
	return !Master?.current_runlevel

/**
 * Приписка к строке входа, открывшегося до конца инициализации мира.
 *
 * ЗАЧЕМ. Раунд 10126 начался волной реконнекта: 89 входов за 120 секунд, ровно поверх
 * 91 секунды инициализации мира. Прибор записал им 2057.5 МБ - и эта цифра дважды уводила
 * разбор в поиск утечки на логине. Контрольный замер после замера базы раунда закрывает
 * вопрос: 85 ПЕРВЫХ входов после базы стоят суммарно МИНУС мегабайт, то есть вход клиента
 * рычагом по памяти не является вовсе.
 *
 * Вычесть эти мегабайты нечем: GLOB.memory_attributed_elsewhere_mb умеет вычитать только
 * названную фоновую работу (свет z-уровня, раздача тел), а инициализация мира на свой счёт
 * ничего не пишет и писать не будет - она идёт до того, как приборы вообще заведены. Значит
 * строка обязана честно сказать, что её дельта принадлежит не входу.
 */
/proc/probe_init_window_note(during_init)
	return during_init ? " - ОКНО ИНИЦИАЛИЗАЦИИ МИРА, эти цифры принадлежат не входу" : ""

/datum/client_connect_probe
	/// ckey клиента - строкой, потому что к контрольному замеру клиент может уже уйти
	var/ckey
	/// Номер этого подключения в GLOB.client_connect_serial
	var/serial
	/// REALTIMEOFDAY на входе в client/New()
	var/started_at
	/// REALTIMEOFDAY последней отметки - этапы меряются от неё
	var/last_mark_at
	/// VmSize/VmRSS на входе; null - замер памяти недоступен (Windows, /proc не читается)
	var/start_vsz
	var/start_rss
	/// VmSize на последней отметке
	var/last_mark_vsz
	/// GLOB.memory_attributed_elsewhere_mb на последней отметке - разница с текущим и есть
	/// фон, который в это окно сделал не этот клиент
	var/last_mark_attributed = 0
	/// Шла ли ещё инициализация мира, когда открылось окно. Снимается на входе, а не в
	/// summary_line(): вход длится секунды, и к концу New() мир уже может быть готов, а
	/// мегабайты окна всё равно принадлежат инициализации.
	var/started_during_init = FALSE
	/// Тот же счётчик на входе в New(): из ИТОГОВОЙ дельты вычитается он
	var/start_attributed = 0
	/// Готовые куски строки по этапам: "prefs 0.1с +0.2 МБ"
	var/list/stages = list()
	/// Итог после finish(): VmSize и момент конца New(), от них считается контрольный замер
	var/finished_vsz
	var/finished_at

/datum/client_connect_probe/New(ckey)
	. = ..()
	src.ckey = ckey
	serial = ++GLOB.client_connect_serial
	started_at = REALTIMEOFDAY
	last_mark_at = started_at
	start_attributed = GLOB.memory_attributed_elsewhere_mb
	last_mark_attributed = start_attributed
	started_during_init = probe_started_during_world_init()
	var/list/memory = get_process_memory_mb()
	if(memory)
		start_vsz = memory["vsz"]
		start_rss = memory["rss"]
		last_mark_vsz = start_vsz

/// Закрыть этап: сколько секунд он шёл и на сколько МБ сдвинул VmSize с прошлой отметки.
/datum/client_connect_probe/proc/mark(stage_name)
	var/now = REALTIMEOFDAY
	var/seconds = round(max(now - last_mark_at, 0) / 10, 0.1)
	last_mark_at = now
	var/attributed_now = GLOB.memory_attributed_elsewhere_mb
	var/list/memory = isnull(start_vsz) ? null : get_process_memory_mb()
	var/part = memory \
		? probe_stage_line(stage_name, seconds, memory["vsz"] - last_mark_vsz, attributed_now - last_mark_attributed) \
		: probe_stage_line(stage_name, seconds, 0, 0, measured = FALSE)
	if(memory)
		last_mark_vsz = memory["vsz"]
	last_mark_attributed = attributed_now
	stages += part

/// Строка итога подключения: общее время, VmSize/RSS до и после, этапы.
/datum/client_connect_probe/proc/summary_line(login_index)
	var/total_seconds = round(max(REALTIMEOFDAY - started_at, 0) / 10, 0.1)
	var/line = "## MEMORY: подключение [ckey] (вход №[login_index]): New() [total_seconds]с"
	if(isnull(start_vsz))
		line += ", память не меряется"
	else
		var/list/memory = get_process_memory_mb()
		if(memory)
			finished_vsz = memory["vsz"]
			// VmSize до и после - сырой факт, а вот дельта в скобках уже за вычетом фона:
			// именно её складывают, когда считают цену клиента.
			var/background = max(GLOB.memory_attributed_elsewhere_mb - start_attributed, 0)
			line += ", VmSize [start_vsz] -> [finished_vsz] МБ ([format_mb_delta(finished_vsz - start_vsz - background)]"
			line += background > 0 ? ", мимо [format_mb_delta(background)] фоновой работы), " : "), "
			line += "RSS [format_mb_delta(memory["rss"] - start_rss)]"
	// Приписка ВНЕ ветки удачного замера: секунды New() печатаются всегда, и в окне
	// инициализации они раздуты ровно тем же, чем дельта. На Windows и при осечке
	// get_process_memory_mb() строка остаётся единственным объяснением четырёх секунд входа.
	line += probe_init_window_note(started_during_init)
	if(length(stages))
		line += "; этапы: [stages.Join(", ")]"
	return line

/// Конец client/New(): строка в лог мира и контрольный замер через минуту.
/datum/client_connect_probe/proc/finish(login_index)
	log_world(summary_line(login_index))
	finished_at = REALTIMEOFDAY
	if(isnull(finished_vsz))
		return
	addtimer(CALLBACK(src, PROC_REF(followup)), CONNECT_PROBE_FOLLOWUP_DELAY)

/// Строка контрольного замера: дельта VmSize с конца New() и сколько других клиентов
/// успело войти - при нуле дельта принадлежит этому подключению целиком.
/datum/client_connect_probe/proc/followup_line(current_vsz, current_serial)
	var/others = max(current_serial - serial, 0)
	return "## MEMORY: подключение [ckey] через [round(CONNECT_PROBE_FOLLOWUP_DELAY / 10)]с: VmSize [format_mb_delta(current_vsz - finished_vsz)] с конца New()[others ? ", за это время вошли ещё [others]" : ", других входов не было - дельта его"][probe_init_window_note(started_during_init)]"

/datum/client_connect_probe/proc/followup()
	var/list/memory = get_process_memory_mb()
	if(memory)
		log_world(followup_line(memory["vsz"], GLOB.client_connect_serial))

/// "+84.3 МБ" / "-0.5 МБ" / "0 МБ": знак нужен, потому что отрицательная дельта здесь
/// законна (ушёл другой клиент) и без знака читалась бы как рост.
/proc/format_mb_delta(delta_mb)
	var/rounded = round(delta_mb, 0.1)
	if(rounded > 0)
		return "+[rounded] МБ"
	return "[rounded] МБ"

#undef CONNECT_PROBE_FOLLOWUP_DELAY
