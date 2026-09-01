/**
 * Память процесса DreamDaemon.
 *
 * Краши без DM-рантайма (раунды 10002/10003/10005 от 17.08.2026) разбором не берутся:
 * процесс умирает молча, а в логах нет ни одной цифры о том, сколько он ел и сколько
 * адресного пространства ему вообще отведено. Вопрос не праздный: DreamDaemon 32-битный
 * (других сборок BYOND не выпускает), и потолок над раундом есть всегда. Здесь снимаются
 * величины из /proc/self/status, текущие и ПИКОВЫЕ.
 *
 * Пик важнее текущего: сэмпл берётся раз в десять секунд, а всплеск, который добивает
 * процесс, живёт доли секунды и между сэмплами не виден вообще. VmPeak/VmHWM ведёт ядро,
 * поэтому они переживают любой промах сэмплера.
 *
 * VmData и RssAnon/RssFile отвечают на следующий вопрос после "память растёт": растёт ЧТО.
 * VmData - это куча процесса, RssFile - резидентная часть отображённых файлов (rsc, иконки,
 * сам бинарь). Раунд 10020 показал рост 21.7 МБ/мин при почти неизменном числе объектов -
 * то есть память уходила не в объекты; без этого разделения следующий шаг разбора упирается
 * в перебор гипотез.
 *
 * Всё это существует только на Linux. На Windows процедуры возвращают null, и вызывающий
 * обязан быть к этому готов.
 */

/// Килобайт в мегабайте: /proc отдаёт все размеры в кБ.
#define PROC_KB_PER_MB 1024
/// Байт в мегабайте: адреса в /proc/self/maps байтовые.
#define PROC_BYTES_PER_MB 1048576
/// Коды ASCII цифр - границы для выборки числа из строки /proc.
#define ASCII_DIGIT_ZERO 48
#define ASCII_DIGIT_NINE 57

/// Потолок адресного пространства неизвестен: не Linux, или /proc недоступен, или разбор не удался.
/// Единственный дефайн отсюда, который живёт дальше файла - его читает SStime_track.
#define PROCESS_ADDRESS_CEILING_UNKNOWN 0

/// Лимит в /proc/self/limits записан словом "unlimited" - ядро потолка не ставит.
/// Не снимается в конце файла: его сверяет юнит-тест разбора.
#define PROC_LIMIT_UNLIMITED -1

/// Сколько неудачных чтений /proc ПОДРЯД гасят замер до конца раунда.
///
/// Одиночный промах и "ядро таких полей не ведёт" по одному разу неразличимы, а цена ошибки
/// несимметрична: погасив замер на транзиентном отказе, мы теряем колонки памяти ровно в том
/// раунде, ради которого их и заводили. Замер снимается раз в десять секунд, так что три
/// промаха подряд - это полминуты молчания, а не рябь.
#define PROC_PROBE_FAILURE_LIMIT 3

/**
 * Достаёт значение поля /proc/self/status в килобайтах.
 *
 * Тем же форматом ("Ключ:<пробелы>число kB") устроен и /proc/meminfo, так что этот же прок
 * читает MemTotal и MemAvailable - см. get_host_memory_mb().
 *
 * Отдельным проком, потому что это единственная часть замера, которую можно проверить
 * юнит-тестом: /proc на машине разработчика нет, а формат строк - есть.
 *
 * Аргументы:
 * * status_text - содержимое /proc/self/status целиком
 * * key - имя поля без двоеточия, например "VmRSS"
 */
/proc/proc_status_value_kb(status_text, key)
	if(!status_text || !key)
		return null
	var/needle = "\n[key]:"
	var/start = findtext(status_text, needle)
	if(!start)
		// Первая строка файла двоеточием слева не отделена, для неё ищем без перевода.
		needle = "[key]:"
		if(findtext(status_text, needle) != 1)
			return null
		start = 1
	start += length(needle)
	var/line_end = findtext(status_text, "\n", start)
	var/line = copytext(status_text, start, line_end || 0)

	// Значение отбито от ключа то табом, то пробелами, а справа к нему приклеено "kB" -
	// поэтому берётся первая непрерывная группа цифр, а не результат trim(). Нечисловые
	// поля (Name, State) цифр в начале не имеют и честно дают null.
	var/digits = ""
	for(var/index in 1 to length(line))
		var/code = text2ascii(line, index)
		if(code >= ASCII_DIGIT_ZERO && code <= ASCII_DIGIT_NINE)
			digits += ascii2text(code)
		else if(length(digits))
			break
	return length(digits) ? text2num(digits) : null

/**
 * Снимок памяти процесса в мегабайтах.
 *
 * Возвращает assoc-список vsz/rss/peak_vsz/peak_rss либо null, если ОС цифр не даёт.
 * В мегабайтах, а не в килобайтах, намеренно: килобайты у боевого сервера уходят за
 * миллион, а BYOND интерполирует такие числа шестью значащими цифрами, и в CSV вместо
 * размера попадает "2.09715e+006".
 */
/proc/get_process_memory_mb()
	var/static/probe_available = null
	var/static/probe_failures = 0
	if(probe_available == FALSE)
		return null
	if(isnull(probe_available))
		probe_available = (world.system_type == UNIX) && rustg_file_exists("/proc/self/status")
		if(!probe_available)
			return null

	var/status_text = rustg_file_read("/proc/self/status")
	var/vsz_kb = status_text ? proc_status_value_kb(status_text, "VmSize") : null
	if(isnull(vsz_kb))
		// Гасим не с первого промаха: см. PROC_PROBE_FAILURE_LIMIT.
		if(++probe_failures >= PROC_PROBE_FAILURE_LIMIT)
			probe_available = FALSE
			log_world("MEMORY: /proc/self/status не прочитан [PROC_PROBE_FAILURE_LIMIT] раза подряд, замер памяти процесса выключен до конца раунда")
		return null
	probe_failures = 0

	// VmData есть у любого ядра, RssAnon/RssFile ведутся с 4.5. Отсутствующее поле уходит
	// в null, а не в ноль: пустая клетка CSV честно говорит "ядро не сказало", а ноль
	// соврал бы, что файловой резидентной памяти нет вовсе.
	//
	// То же самое касается VmRSS/VmPeak/VmHWM. Их ведёт любое ядро, но в контейнере с урезанным /proc
	// или на частично считанном файле поле может не найтись, а null в арифметике DM - это ноль.
	// Непрочитанный VmHWM без этой проверки превращается в "пик RSS 0.0 МБ" - цифру, которая
	// ломает инвариант rss <= peak_rss и выглядит в CSV измерением, а не пропуском.
	var/data_kb = proc_status_value_kb(status_text, "VmData")
	var/rss_anon_kb = proc_status_value_kb(status_text, "RssAnon")
	var/rss_file_kb = proc_status_value_kb(status_text, "RssFile")
	var/rss_kb = proc_status_value_kb(status_text, "VmRSS")
	var/peak_vsz_kb = proc_status_value_kb(status_text, "VmPeak")
	var/peak_rss_kb = proc_status_value_kb(status_text, "VmHWM")

	return list(
		"vsz" = round(vsz_kb / PROC_KB_PER_MB, 0.1),
		"rss" = isnull(rss_kb) ? null : round(rss_kb / PROC_KB_PER_MB, 0.1),
		"peak_vsz" = isnull(peak_vsz_kb) ? null : round(peak_vsz_kb / PROC_KB_PER_MB, 0.1),
		"peak_rss" = isnull(peak_rss_kb) ? null : round(peak_rss_kb / PROC_KB_PER_MB, 0.1),
		"data" = isnull(data_kb) ? null : round(data_kb / PROC_KB_PER_MB, 0.1),
		"rss_anon" = isnull(rss_anon_kb) ? null : round(rss_anon_kb / PROC_KB_PER_MB, 0.1),
		"rss_file" = isnull(rss_file_kb) ? null : round(rss_file_kb / PROC_KB_PER_MB, 0.1),
	)

/**
 * Мягкий лимит из /proc/self/limits в байтах.
 *
 * Формат файла - таблица с колонками "Limit / Soft Limit / Hard Limit / Units", разделёнными
 * пробелами, где в клетке лимита стоит либо число, либо слово unlimited. Нас интересует
 * мягкий: именно он ограничивает процесс, пока никто не поднял его до жёсткого.
 *
 * Возвращает число байт, PROC_LIMIT_UNLIMITED для unlimited, либо null, если поля нет.
 *
 * Аргументы:
 * * limits_text - содержимое /proc/self/limits целиком
 * * key - имя лимита как в первой колонке, например "Max address space"
 */
/proc/proc_limits_soft_bytes(limits_text, key)
	if(!limits_text || !key)
		return null
	var/start = findtext(limits_text, "\n[key]")
	if(start)
		start += 1 + length(key)
	else
		// Первая строка файла - заголовок таблицы, так что лимит с начала файла не начинается
		// никогда. Проверка всё равно есть: с ней прок не зависит от наличия заголовка.
		if(findtext(limits_text, key) != 1)
			return null
		start = 1 + length(key)
	var/line_end = findtext(limits_text, "\n", start)
	var/line = copytext(limits_text, start, line_end || 0)

	for(var/token in splittext(line, " "))
		if(!length(token))
			continue
		if(token == "unlimited")
			return PROC_LIMIT_UNLIMITED
		return text2num(token)
	return null

/**
 * Память ХОСТА в мегабайтах: assoc-список total/available, либо null, если ОС цифр не даёт.
 *
 * Нужна, чтобы различить два неотличимых по логам способа умереть молча. Упор в потолок
 * адресного пространства: VmSize под потолком, а у хоста памяти хоть сколько. OOM-killer:
 * VmSize умеренный, а MemAvailable у хоста в нуле - и тогда искать надо не утечку у нас,
 * а соседа по машине. Ни в том, ни в другом случае DM-рантайма не будет.
 */
/proc/get_host_memory_mb()
	var/static/probe_available = null
	var/static/probe_failures = 0
	if(probe_available == FALSE)
		return null
	if(isnull(probe_available))
		probe_available = (world.system_type == UNIX) && rustg_file_exists("/proc/meminfo")
		if(!probe_available)
			return null

	var/meminfo_text = rustg_file_read("/proc/meminfo")
	var/total_kb = meminfo_text ? proc_status_value_kb(meminfo_text, "MemTotal") : null
	if(isnull(total_kb))
		// Гасим не с первого промаха: см. PROC_PROBE_FAILURE_LIMIT.
		if(++probe_failures >= PROC_PROBE_FAILURE_LIMIT)
			probe_available = FALSE
			log_world("MEMORY: /proc/meminfo не прочитан [PROC_PROBE_FAILURE_LIMIT] раза подряд, замер памяти хоста выключен до конца раунда")
		return null
	probe_failures = 0

	// MemAvailable ведут ядра от 3.14. На более старых берём MemFree - он занижает
	// доступное (не считает отдаваемый кэш), но это лучше пустой колонки.
	var/available_kb = proc_status_value_kb(meminfo_text, "MemAvailable")
	if(isnull(available_kb))
		available_kb = proc_status_value_kb(meminfo_text, "MemFree")

	return list(
		"total" = round(total_kb / PROC_KB_PER_MB, 0.1),
		"available" = isnull(available_kb) ? null : round(available_kb / PROC_KB_PER_MB, 0.1),
	)

/**
 * Верхняя граница адресного пространства процесса в мегабайтах.
 *
 * Разрядность спрашивать бессмысленно: 64-битного DreamDaemon не существует, BYOND
 * поставляется 32-битным бинарём и на 64-битной системе живёт через multilib (см.
 * tools/ci/install_byond.sh - он ставит libcurl4:i386). Потолок над раундом есть всегда,
 * и интересна только его величина: 32-битный процесс получает от ядра либо ~3 ГБ при
 * классическом 3G/1G сплите, либо почти полные 4 ГБ на 64-битном ядре. Разница в целый
 * гигабайт решает, близко ли мы к смерти при двух с половиной занятых.
 *
 * Спрашиваем в два захода, и берём МЕНЬШЕЕ из двух ответов.
 *
 * Первый заход - ядро прямо: RLIMIT_AS из /proc/self/limits, это лимит, а не оценка.
 * Обычно там unlimited, но под `ulimit -v` или в контейнере с ограничением именно эта
 * цифра и обрежет процесс, причём куда раньше архитектурного потолка.
 *
 * Второй - сам архитектурный потолок, видимый только косвенно: по самому старшему адресу
 * в /proc/self/maps (у вершины лежит стек, так что оценка выходит близкой).
 *
 * Меньшее из двух, а не первый попавшийся ответ. RLIMIT_AS бывает и ВЫШЕ того, что
 * 32-битный процесс способен адресовать: `ulimit -v` ставят с запасом в гигабайтах, а
 * лимит контейнера вообще достаётся от 64-битного хоста. Названный слишком большим потолок
 * хуже неизмеренного: от него считаются и пороги лестницы, и прогноз, и раунд умрёт молча,
 * имея по расчёту гигабайты запаса. Неизмеренный хотя бы честно включает запасные планки.
 *
 * Заход в maps дорогой: у боевого процесса это десятки килобайт. Звать один раз за раунд.
 */
/proc/get_process_address_ceiling_mb()
	if(world.system_type != UNIX)
		return PROCESS_ADDRESS_CEILING_UNKNOWN

	var/architectural_mb = PROCESS_ADDRESS_CEILING_UNKNOWN
	if(rustg_file_exists("/proc/self/maps"))
		var/highest_address = proc_maps_highest_address(rustg_file_read("/proc/self/maps"))
		if(highest_address)
			architectural_mb = round(highest_address / PROC_BYTES_PER_MB)

	if(rustg_file_exists("/proc/self/limits"))
		var/limits_text = rustg_file_read("/proc/self/limits")
		var/limit_bytes = proc_limits_soft_bytes(limits_text, "Max address space")
		if(limit_bytes > 0)
			var/limit_mb = round(limit_bytes / PROC_BYTES_PER_MB)
			return architectural_mb ? min(limit_mb, architectural_mb) : limit_mb

	return architectural_mb

/**
 * Самый старший адрес из /proc/self/maps, в байтах. Ноль, если разбирать нечего.
 *
 * Отдельным проком по той же причине, что и proc_status_value_kb(): разбор - единственная
 * часть замера, которую можно проверить юнит-тестом, /proc на машине разработчика нет,
 * а формат строк есть.
 *
 * Аргументы:
 * * maps_text - содержимое /proc/self/maps целиком
 */
/proc/proc_maps_highest_address(maps_text)
	if(!maps_text)
		return 0

	var/highest_address = 0
	for(var/line in splittext(maps_text, "\n"))
		// Строка начинается с "начало-конец", дальше через пробел права доступа.
		var/dash = findtext(line, "-")
		if(!dash)
			continue
		var/range_end = findtext(line, " ", dash)
		if(!range_end)
			continue
		var/address = hex2num(copytext(line, dash + 1, range_end), safe = TRUE)
		if(!isnull(address))
			highest_address = max(highest_address, address)
	return highest_address

/**
 * Скорость роста VmSize по окну замеров, МБ в минуту.
 *
 * Это измерение, а не оценка скрытого параметра: сколько памяти процесс съел за окно,
 * делённое на длину окна. Прогноз на нём читается буквально - "если следующие полчаса будут
 * как прошлые полчаса, потолок вот через столько".
 *
 * Окно поэтому длинное, и вся защита от ступенек - в его длине. Память растёт двумя разными
 * способами: есть ровный дрейф от жизни раунда (единицы МБ/мин) и есть ступеньки по сотне МБ
 * за один замер - созданный z-уровень, инициализация света на нём, наплыв игроков. На
 * пятиминутном окне ступенька в 140 МБ читается как 28 МБ/мин и обещает смерть через десять
 * минут: раунд 10023 от 19.08.2026, гейтвей создал z19, и раунд увели на рестарт на двадцать
 * второй минуте зря. На получасовом та же ступенька даёт 4.7 МБ/мин, и это честная цифра -
 * память действительно потрачена и назад не вернётся.
 *
 * Усечённое среднее пошаговых скоростей, стоявшее здесь до 20.08.2026, убирало ступеньку
 * вместе с ответом. Разбор раунда 10028: верхние 15% шагов несли 112% всего роста, двенадцать
 * шагов из полутора тысяч - 79%. Рост шёл ступеньками ВЕСЬ раунд (игроки заходят пачками,
 * каждый стоит около десяти МБ), и усечение сверху давало медиану 0.00 и среднее -0.17 МБ/мин
 * при истинных 1.36. Прогноз при этом выключался совсем: отрицательная скорость означает
 * "срока нет". Робастная статистика тут не работает в принципе - у распределения шагов вся
 * масса в хвосте, и любая устойчивая к хвосту оценка возвращает ноль.
 *
 * Отрицательный результат осмыслен и не обнуляется - память умеет и падать (ушли игроки,
 * выгрузилась карта), и лог обязан это видеть.
 *
 * Пока окно не набрало min_span, отдаётся ноль: на роундстарте память прыгает на гигабайт
 * за две минуты, и любая оценка по огрызку окна предсказала бы смерть через пару минут.
 * Именно поэтому окно ещё и сбрасывается в момент взятия базового уровня раунда.
 *
 * Аргументы:
 * * times - world.time замеров, по возрастанию
 * * values - VmSize в МБ, тем же порядком
 * * min_span - какой разбег между краями окна уже достаточен, в тиках мира
 */
/proc/memory_growth_rate_mb_per_minute(list/times, list/values, min_span)
	if(!islist(times) || !islist(values) || length(times) != length(values))
		return 0
	if(length(times) < 2 || min_span <= 0)
		return 0

	// Разбег берётся по краям окна, а не по номинальному шагу замера: сэмплы берёт fire()
	// подсистемы, и на просевшем МК десять секунд между замерами превращаются в минуту.
	var/span = times[length(times)] - times[1]
	if(span < min_span)
		return 0
	return round((values[length(values)] - values[1]) / (span / (1 MINUTES)), 0.1)

/**
 * Сколько минут осталось до потолка адресного пространства при нынешней скорости роста.
 *
 * Возвращает null, когда вопрос не имеет смысла: потолок не замерен или память не растёт.
 * null здесь именно "неизвестно", а не "много" - вызывающий обязан различать, иначе
 * неизмеренный потолок превратится в вечное молчание либо в вечную тревогу.
 */
/proc/memory_minutes_to_ceiling(vsz_mb, ceiling_mb, growth_mb_per_minute)
	if(!ceiling_mb || growth_mb_per_minute <= 0)
		return null
	return round(max(0, ceiling_mb - vsz_mb) / growth_mb_per_minute, 0.1)

/**
 * Доля потолка адресного пространства, занятая на ПОСЛЕДНЕМ замере SStime_track.
 *
 * Ноль означает "неизвестно" и обязан читаться именно так: на Windows /proc нет и
 * get_process_memory_mb() возвращает null, потолок там тоже не замерен. Механизмы,
 * которые ужесточаются под давлением, при нуле должны вести себя как раньше, а не как
 * под нулевым давлением на пустом мире - разницы между этими двумя случаями в цифре нет.
 *
 * Читается замер, а не свежий вызов get_process_memory_mb(): чтение /proc/self/status
 * стоит миллисекунды, а спрашивать давление будут из горячих проков.
 */
/proc/memory_pressure_fraction()
	if(!SStime_track)
		return 0
	var/ceiling = SStime_track.process_address_ceiling_mb
	var/vsz = SStime_track.memory_last_vsz_mb
	if(ceiling <= 0 || vsz <= 0)
		return 0
	return vsz / ceiling

#undef PROC_KB_PER_MB
#undef PROC_BYTES_PER_MB
#undef ASCII_DIGIT_ZERO
#undef ASCII_DIGIT_NINE
#undef PROC_PROBE_FAILURE_LIMIT
