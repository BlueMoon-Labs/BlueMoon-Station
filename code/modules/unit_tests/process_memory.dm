/**
 * Разбор /proc/self/status.
 *
 * Самого /proc на машине разработчика и в CI под Windows нет, поэтому проверяется ровно
 * то, что проверить можно: разбор формата. Формат ядро не меняет уже двадцать лет, а вот
 * ошибка в поиске ключа (совпадение с хвостом соседнего поля, потерянная единица
 * измерения) тихо превратит замер памяти в нули - и разбор следующего краша снова
 * останется без цифр.
 */
/datum/unit_test/proc_status_parsing

/datum/unit_test/proc_status_parsing/Run()
	var/status = {"Name:	DreamDaemon
State:	S (sleeping)
VmPeak:	 2097152 kB
VmSize:	 2091008 kB
VmLck:	       0 kB
VmHWM:	 1150000 kB
VmRSS:	 1048576 kB
VmData:	 1900000 kB
RssAnon:	  900000 kB
RssFile:	  148576 kB
Threads:	5
"}

	TEST_ASSERT_EQUAL(proc_status_value_kb(status, "VmSize"), 2091008, "VmSize разобран неверно")
	TEST_ASSERT_EQUAL(proc_status_value_kb(status, "VmRSS"), 1048576, "VmRSS разобран неверно")
	TEST_ASSERT_EQUAL(proc_status_value_kb(status, "VmPeak"), 2097152, "VmPeak разобран неверно")
	TEST_ASSERT_EQUAL(proc_status_value_kb(status, "VmHWM"), 1150000, "VmHWM разобран неверно")
	TEST_ASSERT_EQUAL(proc_status_value_kb(status, "VmLck"), 0, "Нулевое поле должно читаться нулём, а не null")

	// Куча и разложение резидентной памяти: по ним отличают рост объектами от роста
	// отображёнными файлами, и промах в разборе здесь стоит целого шага разбора.
	TEST_ASSERT_EQUAL(proc_status_value_kb(status, "VmData"), 1900000, "VmData разобран неверно")
	TEST_ASSERT_EQUAL(proc_status_value_kb(status, "RssAnon"), 900000, "RssAnon разобран неверно")
	TEST_ASSERT_EQUAL(proc_status_value_kb(status, "RssFile"), 148576, "RssFile разобран неверно")

	// Поле без единицы измерения: разбор не должен на нём спотыкаться.
	TEST_ASSERT_EQUAL(proc_status_value_kb(status, "Threads"), 5, "Поле без kB разобрано неверно")

	// Первая строка файла слева переводом строки не отделена - для неё отдельная ветка.
	TEST_ASSERT_NULL(proc_status_value_kb(status, "Name"), "Нечисловое первое поле обязано дать null, а не мусор")

	// Ключ обязан совпадать целиком: "Anon" - это хвост поля RssAnon, а не самостоятельное поле.
	TEST_ASSERT_NULL(proc_status_value_kb(status, "Anon"), "Хвост чужого поля принят за своё - замер поедет на соседнюю величину")
	TEST_ASSERT_NULL(proc_status_value_kb(status, "VmNothing"), "Отсутствующее поле обязано дать null")
	TEST_ASSERT_NULL(proc_status_value_kb(null, "VmSize"), "Пустой ввод обязан дать null, а не рантайм")

/**
 * Разбор /proc/meminfo тем же проком: формат строки у него тот же, что у status.
 *
 * Величина отсюда решает, куда смотреть после молчаливой смерти процесса: у хоста кончилась
 * память (тогда виноват не обязательно наш процесс) или мы одни упёрлись в свой потолок.
 */
/datum/unit_test/proc_meminfo_parsing

/datum/unit_test/proc_meminfo_parsing/Run()
	var/meminfo = {"MemTotal:        8388608 kB
MemFree:          524288 kB
MemAvailable:    4194304 kB
Buffers:          131072 kB
"}

	// MemTotal стоит первой строкой - это отдельная ветка поиска, и здесь она проверяется
	// на числовом поле (в разборе status ту же ветку сторожит нечисловое Name).
	TEST_ASSERT_EQUAL(proc_status_value_kb(meminfo, "MemTotal"), 8388608, "MemTotal первой строкой разобран неверно")
	TEST_ASSERT_EQUAL(proc_status_value_kb(meminfo, "MemAvailable"), 4194304, "MemAvailable разобран неверно")
	TEST_ASSERT_EQUAL(proc_status_value_kb(meminfo, "MemFree"), 524288, "MemFree разобран неверно")

	// MemAvailable ведут не все ядра, и на старых замер обязан молча съехать на MemFree,
	// а не отдать пустую колонку.
	var/old_kernel_meminfo = {"MemTotal:        8388608 kB
MemFree:          524288 kB
"}
	TEST_ASSERT_NULL(proc_status_value_kb(old_kernel_meminfo, "MemAvailable"), "На старом ядре MemAvailable обязан дать null, чтобы сработал откат на MemFree")

/**
 * Разбор /proc/self/limits.
 *
 * RLIMIT_AS - единственный источник, который называет потолок адресного пространства прямо,
 * а не оценкой по разметке. Ошибка разбора здесь тем неприятна, что выглядит правдоподобно:
 * потолок просто окажется другим, и порог предупреждения молча уедет.
 */
/datum/unit_test/proc_limits_parsing

/datum/unit_test/proc_limits_parsing/Run()
	var/limits = {"Limit                     Soft Limit           Hard Limit           Units
Max cpu time              unlimited            unlimited            seconds
Max data size             unlimited            unlimited            bytes
Max stack size            8388608              unlimited            bytes
Max address space         3221225472           4294967296           bytes
Max open files            1024                 4096                 files
"}

	// У этой строки мягкий и жёсткий лимиты РАЗНЫЕ - тем она и выбрана: взять надо первый
	// столбец после имени, потому что режет процесс именно мягкий.
	// Сверяемся в мегабайтах, а не в байтах: трёхгигабайтный литерал в исходнике не пережил
	// бы точность DM-числа (компилятор на нём ругается), а замер и так переводит в мегабайты.
	TEST_ASSERT_EQUAL(round(proc_limits_soft_bytes(limits, "Max address space") / (1024 * 1024)), 3072, "Числовой лимит адресного пространства разобран неверно (жёсткий вместо мягкого?)")
	TEST_ASSERT_EQUAL(proc_limits_soft_bytes(limits, "Max stack size"), 8388608, "Числовой лимит стека разобран неверно")
	TEST_ASSERT_EQUAL(proc_limits_soft_bytes(limits, "Max open files"), 1024, "Лимит без единицы в байтах разобран неверно")

	// unlimited - это не ноль и не null: потолка нет, и оценивать его надо по разметке.
	TEST_ASSERT_EQUAL(proc_limits_soft_bytes(limits, "Max cpu time"), PROC_LIMIT_UNLIMITED, "unlimited обязан читаться отдельным значением")

	TEST_ASSERT_NULL(proc_limits_soft_bytes(limits, "Max locked memory"), "Отсутствующий лимит обязан дать null")
	TEST_ASSERT_NULL(proc_limits_soft_bytes(null, "Max address space"), "Пустой ввод обязан дать null, а не рантайм")

/**
 * Разбор /proc/self/maps.
 *
 * Когда RLIMIT_AS не поставлен - а обычно он не поставлен, - потолок адресного пространства
 * виден ТОЛЬКО отсюда, по самому старшему отображённому адресу. Ошибка разбора не падает,
 * а тихо сдвигает потолок, а от потолка считаются и порог лестницы, и прогноз, и планка
 * последнего рубежа: промах здесь отравляет сразу все три.
 */
/datum/unit_test/proc_maps_parsing

/datum/unit_test/proc_maps_parsing/Run()
	// Кусок настоящего maps 32-битного процесса. Дефис есть и внутри прав доступа ("r-xp"),
	// поэтому границу диапазона обязан задавать ПЕРВЫЙ дефис строки, а не любой.
	var/maps = {"08048000-08a2f000 r-xp 00000000 08:01 1234567 /opt/byond/bin/DreamDaemon
b7500000-b7521000 rw-p 00000000 00:00 0
bfd8b000-bfdac000 rw-p 00000000 00:00 0 \[stack]
"}
	TEST_ASSERT_EQUAL(proc_maps_highest_address(maps), hex2num("bfdac000"), "Старший адрес maps разобран неверно")

	// 64-битное ядро отдаёт 32-битному процессу почти полные четыре гигабайта, и вершина
	// разметки лежит у самой границы - величина, на которой ломается точность DM-числа,
	// если считать её неаккуратно.
	var/high_maps = "fffee000-fffff000 rw-p 00000000 00:00 0 \[stack]"
	TEST_ASSERT_EQUAL(proc_maps_highest_address(high_maps), hex2num("fffff000"), "Адрес у верхней границы 32-битного пространства разобран неверно")
	TEST_ASSERT_EQUAL(round(proc_maps_highest_address(high_maps) / (1024 * 1024)), 4095, "Потолок у верхней границы посчитан неверно")

	TEST_ASSERT_EQUAL(proc_maps_highest_address(null), 0, "Пустой ввод обязан дать ноль, а не рантайм")
	TEST_ASSERT_EQUAL(proc_maps_highest_address(""), 0, "Пустая строка обязана дать ноль, а не рантайм")
	TEST_ASSERT_EQUAL(proc_maps_highest_address("строка без диапазонов"), 0, "Строка без диапазонов обязана дать ноль")

/**
 * Оценка скорости роста памяти и прогноз запаса до потолка.
 *
 * Эти две величины решают, когда админам уходит единственное за раунд сообщение, поэтому
 * проверяются оба конца: молчать на слишком коротком окне (иначе роундстартовый скачок
 * объявит смерть через две минуты на каждом здоровом раунде) и считать честно на длинном.
 *
 * Окно задано временем, а не числом замеров, поэтому и в тестах длина окна - это разбег
 * между первым и последним замером, а сколько замеров туда попало, значения не имеет.
 */
/datum/unit_test/memory_growth_projection

/datum/unit_test/memory_growth_projection/Run()
	var/list/times = list()
	var/list/values = list()

	// Окно короче требуемого разбега - молчание. Это не осторожность, а единственная защита
	// от ложной тревоги: на роундстарте наклон в сотни МБ/мин совершенно нормален.
	for(var/index in 1 to 5)
		times += (index - 1) * (10 SECONDS)
		values += 3000 + index
	TEST_ASSERT_EQUAL(memory_growth_rate_mb_per_minute(times, values, 10 MINUTES), 0, "Скорость посчиталась по слишком короткому окну")

	// Частые замеры короткого окна тоже молчат: окно меряется минутами, а не штуками, и сотня
	// сэмплов за две минуты - это всё ещё две минуты.
	times = list()
	values = list()
	for(var/index in 1 to 100)
		times += (index - 1) * (1.2 SECONDS)
		values += 3000 + index
	TEST_ASSERT_EQUAL(memory_growth_rate_mb_per_minute(times, values, 10 MINUTES), 0, "Плотная пачка замеров сошла за набранное окно")

	// Полное окно: 61 замер с шагом в полминуты - это ровно полчаса между краями, за которые
	// VmSize вырос на 600 МБ, то есть 20 МБ/мин.
	times = list()
	values = list()
	for(var/index in 1 to 61)
		times += (index - 1) * (30 SECONDS)
		values += 3000 + (index - 1) * 10
	var/rate = memory_growth_rate_mb_per_minute(times, values, 10 MINUTES)
	TEST_ASSERT_EQUAL(rate, 20, "Скорость роста по полному окну посчитана неверно")

	// Прогноз: от 3100 до потолка 4100 при 20 МБ/мин - это ровно 50 минут.
	TEST_ASSERT_EQUAL(memory_minutes_to_ceiling(3100, 4100, rate), 50, "Запас до потолка посчитан неверно")

	// Память, которая не растёт, не даёт срока вовсе - и это null, а не ноль: ноль
	// означал бы "запаса не осталось" и поднял бы тревогу на самом спокойном раунде.
	TEST_ASSERT_NULL(memory_minutes_to_ceiling(3100, 4100, 0), "Нулевой рост обязан давать null, а не срок")
	TEST_ASSERT_NULL(memory_minutes_to_ceiling(3100, 4100, -5), "Убывающая память обязана давать null, а не срок")
	TEST_ASSERT_NULL(memory_minutes_to_ceiling(3100, PROCESS_ADDRESS_CEILING_UNKNOWN, rate), "Без замеренного потолка срок посчитать нельзя")

	// Уже за потолком: срок ноль, а не отрицательное число.
	TEST_ASSERT_EQUAL(memory_minutes_to_ceiling(4200, 4100, rate), 0, "За потолком срок обязан быть нулём")

	// Убывающая память даёт отрицательную скорость, а не ноль: в логе это осмысленная
	// величина, и обнулять её нельзя - иначе падение памяти неотличимо от плато.
	times = list()
	values = list()
	for(var/index in 1 to 181)
		times += (index - 1) * (10 SECONDS)
		values += 3000 - (index - 1)
	TEST_ASSERT_EQUAL(memory_growth_rate_mb_per_minute(times, values, 10 MINUTES), -6, "Убывающая память обязана давать отрицательную скорость")

	// Мусор на входе не должен ронять сэмплер: он зовётся каждые десять секунд весь раунд.
	TEST_ASSERT_EQUAL(memory_growth_rate_mb_per_minute(null, null, 10 MINUTES), 0, "Пустой ввод обязан дать ноль, а не рантайм")
	TEST_ASSERT_EQUAL(memory_growth_rate_mb_per_minute(list(1, 2), list(1), 10 MINUTES), 0, "Списки разной длины обязаны дать ноль, а не рантайм")
	TEST_ASSERT_EQUAL(memory_growth_rate_mb_per_minute(times, values, 0), 0, "Нулевой минимальный разбег обязан дать ноль, а не деление на ноль")

/**
 * Ступенька в окне не должна поднимать ложную тревогу.
 *
 * Регрессия с именем и датой: раунд 10023 от 19.08.2026. В 15:17 гейтвей создал z19, это
 * +72 тысячи объектов и ~140 МБ за один сэмпл. Пятиминутное окно дало под тридцать МБ/мин,
 * прогноз пообещал десять минут до потолка, админы увели раунд на рестарт на двадцать второй
 * минуте. Настоящий дрейф той сборки - около 6 МБ/мин (раунд 10022: +1375 МБ за три с
 * половиной часа).
 *
 * Лечится это длиной окна, а не робастной статистикой. Усечённое среднее пошаговых скоростей,
 * стоявшее здесь один день, прятало ступеньку вместе с ответом: в раунде 10028 рост шёл
 * ступеньками ВЕСЬ раунд, двенадцать шагов из полутора тысяч несли 79% роста, и усечение
 * выдавало ноль при истинных 1.36 МБ/мин.
 *
 * Поэтому проверяется тут не "ступеньки не видно", а "ступенька не поднимает тревогу":
 * цифра остаётся честной, память и правда потрачена, а от ложного срабатывания спасает то,
 * что потраченное поделено на полчаса.
 */
/datum/unit_test/memory_growth_rate_step_immunity

/datum/unit_test/memory_growth_rate_step_immunity/Run()
	var/list/times = list()
	var/list/values = list()

	// Ровный дрейф 1 МБ на замер (это 6 МБ/мин) плюс одна ступенька в 150 МБ посередине
	// получасового окна: 330 МБ за полчаса, то есть 11 МБ/мин.
	var/level = 3000
	for(var/index in 1 to 181)
		times += (index - 1) * (10 SECONDS)
		values += level
		level += (index == 90) ? 151 : 1
	var/rate = memory_growth_rate_mb_per_minute(times, values, 10 MINUTES)
	TEST_ASSERT_EQUAL(rate, 11, "Ступенька в получасовом окне посчитана не по длине окна")

	// Главное свойство: при живом запасе тревога от такой ступеньки не уходит. Запас в 300 МБ -
	// это планка последнего рубежа, ниже которой админам пишут и без всякого прогноза.
	// Порог упреждения берётся самим дефайном, а не цифрой: перенастроенное упреждение
	// обязано ронять этот тест, иначе он молча продолжит проверять прежние двадцать минут.
	TEST_ASSERT(memory_minutes_to_ceiling(3793, 4093, rate) > MEMORY_ADMIN_WARN_LEAD_MINUTES, "Одиночная ступенька подняла ложную тревогу")

	// А вот та же ступенька на пятиминутном окне тревогу поднимает - это и есть регрессия
	// раунда 10023, ради которой окно стало длинным. Срез берётся вокруг самой ступеньки.
	var/short_rate = memory_growth_rate_mb_per_minute(times.Copy(75, 106), values.Copy(75, 106), 1 MINUTES)
	TEST_ASSERT(memory_minutes_to_ceiling(3793, 4093, short_rate) <= MEMORY_ADMIN_WARN_LEAD_MINUTES, "Короткое окно перестало быть опасным - тест потерял смысл")

	// Тот же дрейф без ступеньки обязан дать свои 6 МБ/мин.
	times = list()
	values = list()
	for(var/index in 1 to 181)
		times += (index - 1) * (10 SECONDS)
		values += 3000 + (index - 1)
	TEST_ASSERT_EQUAL(memory_growth_rate_mb_per_minute(times, values, 10 MINUTES), 6, "Ровный дрейф посчитан неверно")

	// Настоящая быстрая утечка длиной окна не занижается: 5 МБ на каждый замер - это 30 МБ/мин.
	times = list()
	values = list()
	for(var/index in 1 to 181)
		times += (index - 1) * (10 SECONDS)
		values += 3000 + (index - 1) * 5
	TEST_ASSERT_EQUAL(memory_growth_rate_mb_per_minute(times, values, 10 MINUTES), 30, "Ровная утечка занижена")

	// Окно с неравномерным шагом: сэмплы берёт fire() подсистемы, и на просевшем МК шаг
	// растягивается. Скорость обязана считаться разбегом окна, а не номинальным шагом:
	// вдвое более редкие замеры при вдвое больших приростах - это та же скорость.
	times = list()
	values = list()
	for(var/index in 1 to 91)
		times += (index - 1) * (20 SECONDS)
		values += 3000 + (index - 1) * 2
	TEST_ASSERT_EQUAL(memory_growth_rate_mb_per_minute(times, values, 10 MINUTES), 6, "Растянутый шаг замеров исказил скорость")

/**
 * Разница двух переписей инстансов.
 *
 * Перепись отвечает на вопрос "что копится", и отвечает она разницей, а не итогом: полтора
 * миллиона турфов в топе абсолютных величин стоят всегда и не значат ничего.
 */
/datum/unit_test/instance_census_growth

/datum/unit_test/instance_census_growth/Run()
	var/list/previous = list(
		/obj/effect/decal/cleanable/dirt = 100,
		/mob/living/carbon/human = 50,
		/obj/effect/decal/cleanable/blood = 10,
	)
	var/list/current = list(
		/obj/effect/decal/cleanable/dirt = 100,
		/mob/living/carbon/human = 45,
		/obj/effect/decal/cleanable/blood = 2010,
		/obj/effect/particle_effect/smoke = 300,
	)

	var/list/growth = SStime_track.instance_census_growth(current, previous)

	TEST_ASSERT_EQUAL(growth[/obj/effect/decal/cleanable/blood], 2000, "Прирост существующего типа посчитан неверно")
	// Новый тип целиком новый: previous[ключ] отсутствует, а null в арифметике DM - ноль.
	TEST_ASSERT_EQUAL(growth[/obj/effect/particle_effect/smoke], 300, "Тип, которого не было в прошлой переписи, посчитан неверно")
	TEST_ASSERT_NULL(growth[/obj/effect/decal/cleanable/dirt], "Неизменившийся тип не должен попадать в прирост")
	TEST_ASSERT_NULL(growth[/mob/living/carbon/human], "Убывший тип не должен попадать в прирост")

	// Сортировка по убыванию значения - то, чем перепись пользуется для топа. Проверяется
	// здесь, потому что ошибка во флаге associative даёт список, отсортированный по ключам,
	// и в лог поедут не самые выросшие типы, а первые по алфавиту.
	sortTim(growth, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	TEST_ASSERT_EQUAL(growth[1], /obj/effect/decal/cleanable/blood, "Топ прироста отсортирован неверно")

/**
 * Топ переписи по весу, а не по количеству.
 *
 * Счёт штук на вопрос "куда ушли мегабайты" не отвечает: за рост раунда 10022 в 1375 МБ
 * отвечали 283 тысячи новых объектов, то есть по 4.8 КБ на штуку, чего не бывает. Вес
 * инстанса задаётся числом переменных его типа, и порядок типов по весу отличается от
 * порядка по количеству - ровно ради этого топ и считается отдельно.
 */
/datum/unit_test/instance_weight_top

/datum/unit_test/instance_weight_top/Run()
	// Турфов вдесятеро меньше, чем декалей, но переменных у турфа втрое больше - и по весу
	// турфы обязаны обойти декали. Ошибка в сортировке или в знаменателе перевернёт порядок.
	var/list/type_var_slots = list(
		/turf/open/floor/plating = 150,
		/obj/effect/decal/cleanable/dirt = 50,
		/mob/living/carbon/human = 200,
	)
	var/list/counts = list(
		/obj/effect/decal/cleanable/dirt = 1000,
		/mob/living/carbon/human = 40,
	)
	var/list/weights = list(
		/turf/open/floor/plating = 100 * 150,
		/obj/effect/decal/cleanable/dirt = 1000 * 50,
		/mob/living/carbon/human = 40 * 200,
	)
	var/total_slots = 15000 + 50000 + 8000

	var/list/top = SStime_track.instance_weight_top(weights, counts, type_var_slots, total_slots)

	TEST_ASSERT_EQUAL(length(top), 3, "Топ по весу потерял или выдумал типы")
	TEST_ASSERT(findtext(top[1], "/obj/effect/decal/cleanable/dirt"), "Топ по весу отсортирован не по весу: первым идёт [top[1]]")
	TEST_ASSERT(findtext(top[2], "/turf/open/floor/plating"), "Топ по весу отсортирован не по весу: вторым идёт [top[2]]")
	// Количество турфов в counts не лежит - оно восстанавливается делением веса на длину vars.
	TEST_ASSERT(findtext(top[2], "x100 "), "Количество турфов не восстановлено из веса: [top[2]]")
	// 50000 из 73000 - это 68.5%.
	TEST_ASSERT(findtext(top[1], "68.5%"), "Доля веса посчитана неверно: [top[1]]")

	// Пустой мир не должен ронять перепись: знаменатель нулевой, а прок зовётся из fire().
	TEST_ASSERT_EQUAL(length(SStime_track.instance_weight_top(list(), list(), list(), 0)), 0, "Нулевой знаменатель обязан дать пустой топ, а не рантайм")

	// Боевые величины: одних только турфов в мире больше миллиона, а BYOND интерполирует
	// такие числа шестью значащими цифрами. "x1.17045e+006" в логе переписи не читается
	// вообще, и то же самое случается с колонками instances/softdels в CSV - там от этого
	// ломается разность соседних строк, то есть скорость роста. Отсюда num2text.
	var/list/big_slots = list(/atom/movable/lighting_object = 5)
	var/list/big_counts = list(/atom/movable/lighting_object = 1170450)
	var/list/big_weights = list(/atom/movable/lighting_object = 1170450 * 5)
	var/list/big_top = SStime_track.instance_weight_top(big_weights, big_counts, big_slots, 1170450 * 5)
	TEST_ASSERT_EQUAL(length(big_top), 1, "Топ по весу потерял единственный тип")
	TEST_ASSERT(findtext(big_top[1], "x1170450 "), "Миллионное количество ушло в экспоненту: [big_top[1]]")
	TEST_ASSERT(!findtext(big_top[1], "e+"), "В строке переписи осталась экспоненциальная запись: [big_top[1]]")

/**
 * Общий снимок состояния SStime_track для тестов памяти.
 *
 * Тесты ниже правят БОЕВУЮ подсистему: своего экземпляра у неё нет, а проверять пороги
 * иначе нечем. Снимок возвращается в Destroy(), а не хвостом Run(), потому что в DM нет
 * finally: TEST_ASSERT разворачивается в `return Fail(...)`, то есть первая же упавшая
 * проверка выходит из Run() и до восстановления не доходит - ровно в том случае, ради
 * которого восстановление и написано. RunUnitTest() зовёт qdel(test) в любом исходе.
 *
 * Само оно не залечится: memory_baseline_due() второй раз базовый уровень не возьмёт,
 * и оставленный порог доживёт до конца прогона, пачкая лог мира и соседние тесты.
 */
/datum/unit_test/memory_tracker_state
	var/tracker_state_taken = FALSE
	var/saved_ceiling
	var/saved_baseline
	var/saved_provisional
	var/saved_warn_at
	var/saved_admin_warned
	var/saved_first_sample
	var/saved_growth
	var/saved_census_at
	var/list/saved_times
	var/list/saved_vsz

/datum/unit_test/memory_tracker_state/Run()
	return

/datum/unit_test/memory_tracker_state/proc/take_tracker_state()
	var/datum/controller/subsystem/time_track/tracker = SStime_track
	saved_ceiling = tracker.process_address_ceiling_mb
	saved_baseline = tracker.memory_baseline_mb
	saved_provisional = tracker.memory_baseline_provisional
	saved_warn_at = tracker.memory_warn_at_mb
	saved_admin_warned = tracker.memory_admin_warned
	saved_first_sample = tracker.memory_first_sample_at
	saved_growth = tracker.memory_growth_mb_per_minute
	saved_census_at = tracker.memory_census_at
	saved_times = tracker.memory_sample_times.Copy()
	saved_vsz = tracker.memory_sample_vsz.Copy()
	tracker_state_taken = TRUE
	return tracker

/datum/unit_test/memory_tracker_state/Destroy()
	if(tracker_state_taken)
		var/datum/controller/subsystem/time_track/tracker = SStime_track
		tracker.process_address_ceiling_mb = saved_ceiling
		tracker.memory_baseline_mb = saved_baseline
		tracker.memory_baseline_provisional = saved_provisional
		tracker.memory_warn_at_mb = saved_warn_at
		tracker.memory_admin_warned = saved_admin_warned
		tracker.memory_first_sample_at = saved_first_sample
		tracker.memory_growth_mb_per_minute = saved_growth
		tracker.memory_census_at = saved_census_at
		tracker.memory_sample_times = saved_times
		tracker.memory_sample_vsz = saved_vsz
		tracker_state_taken = FALSE
	saved_times = null
	saved_vsz = null
	return ..()

/**
 * Пороги предупреждения о памяти вокруг установившегося уровня раунда.
 *
 * Тест на конкретную ошибку, а не на абстрактную арифметику. Порог, посчитанный только как
 * доля потолка, на тяжёлой карте срабатывает на первом же замере раунда: в раунде 10020
 * потолок был 4088 МБ, а установившийся уровень - 3134 МБ, то есть 77% потолка сразу после
 * старта. Строка, приходящая в лог каждый раунд независимо ни от чего, не сообщает ничего,
 * и лестница, начинающаяся с неё, обесценивается целиком.
 */
/datum/unit_test/memory_warning_thresholds
	parent_type = /datum/unit_test/memory_tracker_state

/datum/unit_test/memory_warning_thresholds/Run()
	// Состояние подсистемы снимается целиком и возвращается в Destroy(), см. базовый тип.
	var/datum/controller/subsystem/time_track/tracker = take_tracker_state()

	// Перепись инстансов заказывается со ступени лестницы и перебирает world.contents
	// целиком. Здесь она не проверяется и стоит дорого - глушим её кулдауном.
	tracker.memory_census_at = max(world.time, 1)
	// Сообщение админам проверяется отдельно; здесь оно только мешало бы читать лог.
	tracker.memory_admin_warned = TRUE

	// Цифры боевые, из раунда 10020: потолок 4088 МБ, установившийся уровень 3134 МБ.
	tracker.process_address_ceiling_mb = 4088
	tracker.take_memory_baseline(3134, null)

	// 0.6 * 4088 = 2452, то есть порог от доли потолка оказался бы ниже уровня, с которого
	// раунд начался. Побеждать обязан пол "установившийся уровень плюс ступень".
	TEST_ASSERT_EQUAL(tracker.memory_warn_at_mb, 3390, "Порог лестницы посчитан не от установившегося уровня раунда")

	// Замер, не отошедший от базового уровня, - не повод для строки в логе.
	tracker.track_process_memory(list("vsz" = 3140, "rss" = 2900, "peak_vsz" = 3150), null)
	TEST_ASSERT_EQUAL(tracker.memory_warn_at_mb, 3390, "Ступень сработала на памяти, не отошедшей от базового уровня")

	// Ушли выше ступени - порог переезжает на ступень от текущего значения, а не от прежнего
	// порога: иначе процесс, перешагнувший планку однажды, пишет строку каждые десять секунд.
	tracker.track_process_memory(list("vsz" = 3400, "rss" = 3100, "peak_vsz" = 3410), null)
	TEST_ASSERT_EQUAL(tracker.memory_warn_at_mb, 3656, "Ступень не переехала после срабатывания")

	// Окно скорости роста после взятия базового уровня начинается пустым: замеры роундстарта
	// в нём остаться не должны, иначе прогноз получит сотни МБ/мин на ровном месте.
	TEST_ASSERT_EQUAL(tracker.memory_growth_mb_per_minute, 0, "Скорость роста посчиталась по огрызку окна сразу после базового уровня")

/**
 * Последний рубеж перед потолком: предупреждение по остатку, а не по доле.
 *
 * Цифры боевые, все четыре из логов 19.08.2026 при потолке около 4090 МБ. Раунд 10022 дожил
 * до штатного рестарта на 3724 МБ - на нём молчать. Раунды 10020 (3858) и 10023 (3796) были
 * в реальной опасности - на них предупреждать. Планка в виде доли потолка это различие не
 * ловит: базовый уровень раунда на Delta и так 86% потолка, и любые 0.9 срабатывают через
 * четверть часа каждый раунд.
 */
/datum/unit_test/memory_admin_warning_backstop
	parent_type = /datum/unit_test/memory_tracker_state

/datum/unit_test/memory_admin_warning_backstop/Run()
	var/datum/controller/subsystem/time_track/tracker = take_tracker_state()

	tracker.process_address_ceiling_mb = 4089
	tracker.memory_baseline_mb = 3521
	tracker.memory_baseline_provisional = FALSE

	// Рост обнулён, чтобы работал только последний рубеж: прогноз при нулевой скорости
	// отдаёт null и в решение не вмешивается.
	tracker.memory_growth_mb_per_minute = 0

	tracker.memory_admin_warned = FALSE
	tracker.check_memory_admin_warning(3724)
	TEST_ASSERT(!tracker.memory_admin_warned, "Предупреждение ушло на памяти раунда, дожившего до штатного рестарта")

	tracker.check_memory_admin_warning(3796)
	TEST_ASSERT(tracker.memory_admin_warned, "Последний рубеж не сработал в трёхстах МБ от потолка")

	// Вторая дорога к тому же предупреждению - прогноз. Памяти ещё много, но при быстром
	// росте срок до потолка короче упреждения, и админам надо сказать заранее.
	tracker.memory_admin_warned = FALSE
	tracker.memory_growth_mb_per_minute = 6
	tracker.check_memory_admin_warning(3600)
	TEST_ASSERT(!tracker.memory_admin_warned, "Предупреждение ушло при дрейфе, которого хватило бы на полтора часа")

	tracker.memory_growth_mb_per_minute = 30
	tracker.check_memory_admin_warning(3600)
	TEST_ASSERT(tracker.memory_admin_warned, "Прогноз не поднял тревогу на настоящей быстрой утечке")
