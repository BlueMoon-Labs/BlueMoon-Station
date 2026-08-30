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
	TEST_ASSERT_EQUAL(tracker.memory_warn_at_mb, 3230, "Порог лестницы посчитан не от установившегося уровня раунда")

	// Замер, не отошедший от базового уровня, - не повод для строки в логе.
	tracker.track_process_memory(list("vsz" = 3140, "rss" = 2900, "peak_vsz" = 3150), null)
	TEST_ASSERT_EQUAL(tracker.memory_warn_at_mb, 3230, "Ступень сработала на памяти, не отошедшей от базового уровня")

	// Ушли выше ступени - порог переезжает на ступень от текущего значения, а не от прежнего
	// порога: иначе процесс, перешагнувший планку однажды, пишет строку каждые десять секунд.
	tracker.track_process_memory(list("vsz" = 3400, "rss" = 3100, "peak_vsz" = 3410), null)
	TEST_ASSERT_EQUAL(tracker.memory_warn_at_mb, 3496, "Ступень не переехала после срабатывания")

	// Окно скорости роста после взятия базового уровня начинается пустым: замеры роундстарта
	// в нём остаться не должны, иначе прогноз получит сотни МБ/мин на ровном месте.
	TEST_ASSERT_EQUAL(tracker.memory_growth_mb_per_minute, 0, "Скорость роста посчиталась по огрызку окна сразу после базового уровня")

/**
 * Первая ступень лестницы обязана лежать НИЖЕ того, докуда раунд реально дорастает.
 *
 * Тест на конкретную ошибку из логов 28.08.2026. Ступень в 256 МБ была больше, чем прирост
 * короткого раунда, поэтому лестница не печатала ничего именно там, где перепись и нужна:
 * в 10133 раунд дошёл до 2547.3 МБ при первой ступени 2576.4, в 10134 за 42 минуты - до
 * 2725 при ступени 2833. Ни один из этих раундов не падал (10133 перезапустили руками под
 * деплой) - в том и суть: прибор молчит на ЛЮБОМ раунде такой длины, включая тот, который
 * однажды не доживёт.
 *
 * Цифры здесь боевые и заменять их «круглыми» нельзя: тест ловит не арифметику, а то, что
 * ступень снова стала шире прироста раунда.
 */
/datum/unit_test/memory_ladder_fires_before_death
	parent_type = /datum/unit_test/memory_tracker_state

/datum/unit_test/memory_ladder_fires_before_death/Run()
	var/datum/controller/subsystem/time_track/tracker = take_tracker_state()
	// Перепись заказывается со ступени и перебирает world.contents целиком - глушим кулдауном.
	tracker.memory_census_at = max(world.time, 1)
	tracker.memory_admin_warned = TRUE

	// Раунд 10133: потолок 4092 МБ, установившийся уровень 2320.4, верх роста 2547.3.
	tracker.process_address_ceiling_mb = 4092
	tracker.take_memory_baseline(2320, null)
	TEST_ASSERT(tracker.memory_warn_at_mb < 2547, \
		"Первая ступень встала на [tracker.memory_warn_at_mb] МБ - выше 2547 МБ, докуда дорос раунд 10133")
	// Ступень обязана и сработать: порог ниже верха роста бесполезен, если замер его не перешагнёт.
	tracker.track_process_memory(list("vsz" = 2547, "rss" = 2300, "peak_vsz" = 2547), null)
	TEST_ASSERT(tracker.memory_warn_at_mb > 2547, \
		"Порог не переехал после ступени: замер 2547 МБ не считается перешагнувшим [tracker.memory_warn_at_mb] МБ")

	// Раунд 10134: потолок 4088 МБ, установившийся уровень 2577, за 42 минуты дошёл до 2725.
	tracker.memory_baseline_mb = 0
	tracker.process_address_ceiling_mb = 4088
	tracker.take_memory_baseline(2577, null)
	TEST_ASSERT(tracker.memory_warn_at_mb < 2725, \
		"Первая ступень встала на [tracker.memory_warn_at_mb] МБ - выше 2725 МБ, докуда дошёл раунд 10134")

/**
 * Базовый уровень не снимается с закончившегося раунда.
 *
 * Тест на конкретную ошибку из раунда 10098. Раунд кончился через 14 секунд после старта,
 * уровень снялся через две минуты - посреди обработки конца раунда, с фотографиями манифеста
 * и итоговыми отчётами, - и напечатал 3164 МБ, то есть 77% потолка, вместо реальных ~2600.
 * Лестница от этой цифры встала на 3420 МБ. Причина - сравнение `>= GAME_STATE_PLAYING`, а
 * GAME_STATE_FINISHED больше GAME_STATE_PLAYING.
 */
/datum/unit_test/memory_baseline_ignores_finished_round
	parent_type = /datum/unit_test/memory_tracker_state
	var/saved_ticker_state
	var/ticker_state_taken = FALSE

/datum/unit_test/memory_baseline_ignores_finished_round/Destroy()
	if(ticker_state_taken)
		SSticker.current_state = saved_ticker_state
		ticker_state_taken = FALSE
	return ..()

/datum/unit_test/memory_baseline_ignores_finished_round/Run()
	var/datum/controller/subsystem/time_track/tracker = take_tracker_state()
	// Перепись заказывается из take_memory_baseline() и перебирает world.contents целиком.
	tracker.memory_census_at = max(world.time, 1)
	tracker.memory_admin_warned = TRUE
	tracker.process_address_ceiling_mb = 4092

	saved_ticker_state = SSticker.current_state
	ticker_state_taken = TRUE

	// Живой раунд: уровень настоящий.
	SSticker.current_state = GAME_STATE_PLAYING
	tracker.take_memory_baseline(2620, null)
	TEST_ASSERT(!tracker.memory_baseline_provisional, "Уровень идущего раунда помечен предварительным")

	// Закончившийся раунд: уровень обязан остаться предварительным, потому что замер
	// захватил обработку конца раунда, а не установившееся состояние.
	SSticker.current_state = GAME_STATE_FINISHED
	tracker.take_memory_baseline(3164, null)
	TEST_ASSERT(tracker.memory_baseline_provisional, "Уровень, снятый с закончившегося раунда, выдан за базовый")

	// И повторно снимать его с закончившегося раунда прибор не берётся: настоящего
	// установившегося уровня у такого раунда уже не будет.
	tracker.memory_baseline_mb = 3164
	TEST_ASSERT(!tracker.memory_baseline_due(), "Прибор снова просит базовый уровень у закончившегося раунда")

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

/**
 * Длина списка вместе с вложенным уровнем.
 *
 * Плоский length() на самом крупном из найденных накопителей отвечает пятёркой: /mob.logging
 * - это assoc из пяти ключей по типу сообщения, а тысячи записей лежат ВНУТРИ. Прибор, не
 * умеющий заглянуть на уровень вниз, такой накопитель не увидит вовсе, и проверять тут надо
 * именно это.
 */
/datum/unit_test/list_slots_deep

/datum/unit_test/list_slots_deep/Run()
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(list(1, 2, 3)), 3, "Плоский список посчитан неверно")
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(list()), 0, "Пустой список обязан дать ноль")

	// Устройство /mob.logging: пять ключей, внутри - записи. Пять плюс 10 плюс 4.
	var/list/logging_shaped = list("say" = new /list(10), "attack" = new /list(4))
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(logging_shaped), 2 + 10 + 4, "Вложенный уровень ассоциативного списка не посчитан")

	// Список списков без ключей - так устроены reagent_list и очереди пар.
	var/list/nested_flat = list(new /list(3), new /list(7))
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(nested_flat), 2 + 3 + 7, "Вложенный уровень списка списков не посчитан")

	// Числовой элемент плоского списка индексацией трогать нельзя: outer[2] это обращение
	// по ПОЗИЦИИ, и без гарда сюда приехал бы соседний элемент вместо отсутствующего значения.
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(list(2, 3, 1)), 3, "Числовой элемент принят за ключ - счёт уехал на соседа")

	// Длинный список разбирается ПО ВЫБОРКЕ, а не пропускается. Прежняя редакция для всего
	// длиннее потолка возвращала одну собственную длину, и это была главная слепота прибора:
	// книга рецептов диспенсера (747 ключей по 28 полей) отдавала "747" вместо ~21 тысячи.
	// Здесь 128 элементов, из них первые 64 - выборка; вложенный список ровно один, на
	// 1000 элементов, и разворот выборки на всю длину даёт 1000 * 128 / 64 = 2000.
	var/list/too_long = new /list(128)
	too_long[1] = new /list(1000)
	var/extrapolated_before = SStime_track.census_lists_extrapolated
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(too_long), 128 + 2000, "Длинный список не развёрнут по выборке")
	TEST_ASSERT_EQUAL(SStime_track.census_lists_extrapolated - extrapolated_before, 1, "Оценка по выборке не отмечена счётчиком - в логе она выдаст себя за точный замер")

	// Форма книги рецептов диспенсера: длинный АССОЦИАТИВНЫЙ список, у которого вложенное
	// лежит в значениях, а не элементами. Срезанная копия обязана сохранять пары - иначе
	// разворот по выборке даст ноль и недоучёт вернётся ровно там, где он и был.
	var/list/long_assoc = list()
	for(var/i in 1 to 100)
		long_assoc["ключ[i]"] = list(1, 2, 3, 4, 5)
	extrapolated_before = SStime_track.census_lists_extrapolated
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(long_assoc), 100 + 500, "Длинный ассоциативный список: вложенное в значениях не сосчиталось - срезанная копия потеряла пары")
	TEST_ASSERT_EQUAL(SStime_track.census_lists_extrapolated - extrapolated_before, 1, "Длинный ассоциативный список не отмечен как оценённый по выборке")

	// А список без вложенного внутри - это всё ещё ровно его длина, без всякой оценки:
	// contents космической зоны на 800 тысяч элементов не должен ни во что разворачиваться.
	var/list/long_and_flat = new /list(128)
	extrapolated_before = SStime_track.census_lists_extrapolated
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(long_and_flat), 128, "Плоский длинный список получил выдуманную вложенность")
	TEST_ASSERT_EQUAL(SStime_track.census_lists_extrapolated - extrapolated_before, 0, "Плоский список зря помечен как оценённый по выборке")

	// Встроенные списки BYOND ассоциативного чтения не терпят вовсе: contents[атом] - это не
	// null, а "bad index". Перепись обходит vars подряд и такие списки видит на каждом втором
	// атоме, так что без плоской копии прибор спамил рантайм весь раунд.
	var/obj/item/paper/sheet = allocate(/obj/item/paper, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(length(sheet.locs), 1, "однотайловый предмет занимает не один турф - проверять нечего")
	var/runtimes_before = GLOB.total_runtimes
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(sheet.locs), 1, "встроенный locs посчитан неверно")
	TEST_ASSERT_EQUAL(GLOB.total_runtimes - runtimes_before, 0, "обход встроенного списка поднял рантайм")

	runtimes_before = GLOB.total_runtimes
	TEST_ASSERT(SStime_track.list_slots_deep(run_loc_floor_bottom_left.contents) >= 1, "contents турфа с предметом посчитан пустым")
	TEST_ASSERT_EQUAL(GLOB.total_runtimes - runtimes_before, 0, "обход contents поднял рантайм")

/// Стенд для разделения общих и личных списков: статик на всех, личный у каждого.
/datum/memory_census_sample_dummy
	var/static/list/shared_cache = list("a" = 1, "b" = 2, "c" = 3, "d" = 4, "e" = 5)
	var/list/personal = list()

/**
 * Общий на тип список не должен приписываться каждому инстансу.
 *
 * Ради чего проверка. В прод-переписи 23.08 топ строки "элементы списков" состоял почти
 * целиком из статиков: /atom/movable/lighting_object отдавал 69 элементов на штуку при
 * 235 тысячах инстансов, скрытые трубы - 177 и "росли" до 194 (рос общий pipeimages),
 * а человек и обезьяна показывали 5071 и 4656 - почти одно число, потому что обе цифры
 * были общим кэшем limb_icon_cache. Умноженный на популяцию статик выдумывает миллионы
 * элементов там, где лежит один список, и топ отвечает не на тот вопрос, ради которого
 * написан.
 */
/datum/unit_test/memory_census_shared_lists

/datum/unit_test/memory_census_shared_lists/Run()
	var/datum/memory_census_sample_dummy/first = new
	var/datum/memory_census_sample_dummy/second = new
	first.personal = list(1, 2)
	second.personal = list(1, 2)

	var/list/reference_lists = list()
	var/first_slots = SStime_track.collect_instance_lists(first, reference_lists)
	// Пять ключей статика плюс два своих: первый инстанс считается целиком, разделять на
	// нём нечего.
	TEST_ASSERT_EQUAL(first_slots, 7, "Первый инстанс посчитан неверно: [first_slots]")
	TEST_ASSERT(reference_lists[first.shared_cache], "Статик не попал в эталонный набор ссылок")
	TEST_ASSERT(reference_lists[first.personal], "Личный список первого инстанса не попал в эталонный набор ссылок")

	var/list/clean_slots = list()
	var/list/shared_slots = list()
	var/list/counted_shared = list()
	SStime_track.sample_instance_lists(second, /datum/memory_census_sample_dummy, reference_lists, clean_slots, shared_slots, counted_shared, TRUE)

	TEST_ASSERT_EQUAL(clean_slots[/datum/memory_census_sample_dummy], 2, "Личный список второго инстанса посчитан неверно - статик просочился в личный счёт")
	TEST_ASSERT_EQUAL(shared_slots[/datum/memory_census_sample_dummy], 5, "Общий на тип список не отнесён в общий счёт")

	// Третий инстанс общее уже не считает: платится за него один раз на тип, а не по разу
	// на каждый разобранный инстанс.
	var/datum/memory_census_sample_dummy/third = new
	third.personal = list(1, 2)
	SStime_track.sample_instance_lists(third, /datum/memory_census_sample_dummy, reference_lists, clean_slots, shared_slots, counted_shared, FALSE)
	TEST_ASSERT_EQUAL(shared_slots[/datum/memory_census_sample_dummy], 5, "Общий список посчитан дважды")
	TEST_ASSERT_EQUAL(clean_slots[/datum/memory_census_sample_dummy], 4, "Личные списки двух инстансов не сложились")

	// Тот же статик, увиденный ДРУГИМ типом, второй раз не платится. Именно на этом
	// перепись 10100 потеряла весь топ: семь подтипов chem_dispenser записали себе один
	// и тот же список рецептов по 5432 элемента каждый, и настоящая утечка из топа выпала.
	var/datum/memory_census_sample_dummy/heir = new
	heir.personal = list(1, 2)
	var/list/heir_reference_lists = list()
	SStime_track.collect_instance_lists(heir, heir_reference_lists)
	var/datum/memory_census_sample_dummy/heir_second = new
	heir_second.personal = list(1, 2)
	// Ключом идёт любой другой тип: важно не какой именно, а что он второй.
	SStime_track.sample_instance_lists(heir_second, /datum, heir_reference_lists, clean_slots, shared_slots, counted_shared, TRUE)
	TEST_ASSERT(!shared_slots[/datum], "Один и тот же общий список записан двум типам сразу - память посчитана дважды")

/**
 * Пересчёт выборочной длины списков на весь мир.
 *
 * Списочные слоты - третье слепое пятно переписи после не-атомных датумов и внутренних
 * таблиц BYOND: растущий ассоциативный список на живом атоме даёт мегабайты при НУЛЕВОМ
 * приросте инстансов. Обойти vars у полутора миллионов атомов нельзя по цене, поэтому
 * длина берётся с выборки и умножается на количество - и вот этот множитель проверяется
 * здесь. Ошибка в нём даёт правдоподобную и полностью выдуманную цифру, а сверить её в
 * логе не с чем.
 */
/datum/unit_test/list_slot_top

/datum/unit_test/list_slot_top/Run()
	// Турфов вдесятеро больше, чем шкафов, но списки у шкафа длиннее в двадцать раз -
	// и по слотам шкафы обязаны обойти турфы.
	var/list/all_counts = list(
		/turf/open/floor/plating = 100000,
		/obj/structure/closet = 10000,
		/obj/effect/decal/cleanable/dirt = 5000,
	)
	var/list/type_list_samples = list(
		/turf/open/floor/plating = 3,
		/obj/structure/closet = 3,
		/obj/effect/decal/cleanable/dirt = 3,
	)
	// Первый инстанс типа тратится на эталон ссылок, так что личные слоты копятся с
	// ДВУХ инстансов из трёх - делитель тоже двойка.
	var/list/type_list_slots = list(
		/turf/open/floor/plating = 2 * 2,
		/obj/structure/closet = 2 * 40,
		/obj/effect/decal/cleanable/dirt = 0,
	)

	var/list/top = SStime_track.list_slot_top(all_counts, type_list_samples, type_list_slots, list())

	TEST_ASSERT_EQUAL(length(top), 2, "Тип без единого списочного элемента обязан выпасть из топа, а не занимать место")
	TEST_ASSERT(findtext(top[1], "/obj/structure/closet"), "Топ по списочным слотам отсортирован не по слотам: первым идёт [top[1]]")
	// 10000 штук по 40 элементов - четыреста тысяч.
	TEST_ASSERT(findtext(top[1], "400000"), "Пересчёт выборки на мир посчитан неверно: [top[1]]")
	TEST_ASSERT(findtext(top[2], "200000"), "Пересчёт выборки на мир посчитан неверно для турфов: [top[2]]")
	// BYOND интерполирует числа от миллиона шестью значащими цифрами, и без num2text в лог
	// поедет "2e+006" вместо количества слотов.
	TEST_ASSERT(!findtext(top[1], "e+"), "В строке списочных слотов осталась экспоненциальная запись: [top[1]]")

	// Тип, попавший в счёт количества, но не в выборку, делить не на что: нулевой знаменатель
	// не должен ни ронять перепись, ни выдумывать бесконечность.
	var/list/empty_top = SStime_track.list_slot_top(list(/turf/open/floor/plating = 100), list(/turf/open/floor/plating = 0), list(/turf/open/floor/plating = 10), list())
	TEST_ASSERT_EQUAL(length(empty_top), 0, "Нулевая выборка обязана дать пустой топ, а не деление на ноль")

	// Единственный инстанс типа: делить не на что, и берётся запасной путь - все списки
	// первого инстанса как есть. Именно так выглядит contents космической зоны, самая
	// крупная строка настоящей переписи, и потерять её нельзя.
	var/list/lone_top = SStime_track.list_slot_top(list(/area/space = 1), list(/area/space = 1), list(), list(/area/space = 813931))
	TEST_ASSERT_EQUAL(length(lone_top), 1, "Тип с единственным инстансом выпал из топа вместо запасного пути")
	TEST_ASSERT(findtext(lone_top[1], "813931"), "Запасной путь для одиночного инстанса посчитан неверно: [lone_top[1]]")

#ifdef DATUM_CENSUS
/**
 * Отчёт переписи не-атомных датумов.
 *
 * Перепись инстансов перебирает world.contents, а туда BYOND кладёт только турфы, зоны,
 * объекты и мобов: компоненты, газовые смеси, углы освещения, таймеры и коллбеки не видит
 * ни один прибор. Здесь проверяется арифметика разницы "создано минус qdel" - именно она
 * отвечает на вопрос "что из этого не удаляется", и ошибка в ней читается как утечка.
 */
/datum/unit_test/datum_census_report

/datum/unit_test/datum_census_report/Run()
	var/list/created = list(
		/datum/callback = 500000,
		/datum/reagents = 900,
		/datum/component/simple_rotation = 4000,
	)
	var/list/destroyed = list(
		/datum/reagents = 900,
		/datum/component/simple_rotation = 3990,
		// Атом в счёте удалений законен: /datum/Destroy() общий для всех, а отсев делает
		// перебор по ключам created, куда атом не доходит (/atom/New() родителя не зовёт).
		/obj/item/crowbar = 12000,
	)

	// Первая перепись: снимка ещё нет, отчёт абсолютный.
	var/list/first = datum_census_report_lines(created, destroyed, null, null, 2)

	TEST_ASSERT_EQUAL(length(first), 2, "Отчёт переписи датумов обязан быть ровно из двух строк")
	TEST_ASSERT(findtext(first[1], "/datum/callback x500000"), "Топ по созданию отсортирован неверно: [first[1]]")
	TEST_ASSERT(!findtext(first[1], "/obj/item/crowbar"), "Атом просочился в отчёт переписи датумов: [first[1]]")
	// 500000 мимо qdel, 900-900=0, 4000-3990=10. Итого 500010.
	TEST_ASSERT(findtext(first[1], "не удалено через qdel 500010"), "Остаток мимо qdel посчитан неверно: [first[1]]")
	TEST_ASSERT(findtext(first[2], "/datum/callback x500000"), "Топ мимо qdel отсортирован неверно: [first[2]]")

	// Вторая перепись поверх снимка: в топ обязан попасть тот, кто вырос, а не тот, кого
	// за раунд просто много. Ради этого разница и считается.
	var/list/snapshot_created = created.Copy()
	var/list/snapshot_residue = datum_census_residue(created, destroyed)
	created[/datum/component/simple_rotation] = 9000
	created[/datum/callback] = 500100
	destroyed[/datum/component/simple_rotation] = 4990

	var/list/second = datum_census_report_lines(created, destroyed, snapshot_created, snapshot_residue, 2)

	TEST_ASSERT(findtext(second[1], "/datum/component/simple_rotation x5000"), "Разница по созданию посчитана неверно: [second[1]]")
	TEST_ASSERT(findtext(second[1], "/datum/callback x100"), "Разница по созданию потеряла второй тип: [second[1]]")
	// Компонентов создано на 5000 больше, удалено на 1000 больше - мимо qdel ушло 4000.
	TEST_ASSERT(findtext(second[2], "/datum/component/simple_rotation x4000"), "Разница по остатку посчитана неверно: [second[2]]")

	// Ничего не изменилось - в топах обязана быть пустота, а не прошлые цифры.
	var/list/third = datum_census_report_lines(created, destroyed, created.Copy(), datum_census_residue(created, destroyed), 2)
	TEST_ASSERT(findtext(third[1], "пусто"), "Перепись без единого нового датума показала прирост: [third[1]]")

	TEST_ASSERT_EQUAL(length(datum_census_report_lines(list(), list(), null, null, 5)), 1, "Пустой счётчик обязан дать одну строку, а не рантайм")
#endif

/**
 * alist (516) в переписи списков.
 *
 * islist() отвечает на alist правдой, поэтому в list_slots_deep() он заходит наравне с
 * обычным списком - а позиционного доступа у него нет вовсе, и отрезок Copy(1, N) падает
 * "list index out of bounds". Ловить это некому: перепись живёт в INVOKE_ASYNC, её рантайм
 * виден только в логе. На проде хватало одной мехи (facing_modifiers) или любой подсистемы
 * (profile_cost_by_type), чтобы каждая перепись сыпала рантаймами до конца раунда.
 */
/datum/unit_test/census_list_slots_alist

/datum/unit_test/census_list_slots_alist/Run()
	// Вложенное внутри alist обязано считаться, а не ронять прок: 2 ключа + 3 + 2 элемента.
	var/list/nested_alist = alist("шлем" = list(1, 2, 3), "корпус" = list(4, 5))
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(nested_alist), 7, "перепись обязана досчитать вложенные списки alist, а не упасть на срезе")

	// Числовой ключ у alist - обычный ключ, а не позиция.
	var/list/numeric_alist = alist(1 = list("a", "b"), 2 = "плоское значение")
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(numeric_alist), 4, "числовой ключ alist читается как ключ, вложенный список по нему теряться не должен")

	// alist без вложенного - только собственная длина.
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(alist("a" = 1.5, "b" = 1, "c" = 0.5)), 3, "у alist без вложенных списков считается только своя длина")

	// Обычный список считается ровно как раньше: 2 своих слота + 2 + 3 вложенных.
	var/list/plain = list("ключ" = list(1, 2), list(3, 4, 5))
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(plain), 7, "плоский путь переписи не должен измениться")

	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(alist()), 0, "пустой alist - это ноль слотов, а не рантайм")

	// filters атома - третий вид списка: islist() признаёт, istype(x, /list) - нет, и при этом
	// он ровно противоположен alist'у - срез Copy() по нему работает, а чтения по ключу нет
	// вовсе ("bad index"). Отличать alist по ОТСУТСТВИЮ /list поэтому нельзя: filters уезжал
	// в ключевой перебор и валил перепись на каждом атоме с фильтром.
	var/obj/filter_holder = allocate(/obj)
	filter_holder.filters += filter(type = "blur", size = 1)
	filter_holder.filters += filter(type = "outline", size = 1)
	TEST_ASSERT_EQUAL(SStime_track.list_slots_deep(filter_holder.filters), 2,
		"список фильтров обязан считаться копией, а не перебором ключей")

/**
 * Ступени конца раунда по давлению памяти.
 *
 * Цифры в кейсах взяты из настоящих раундов 24.08.2026: потолок 4094, раунд 10105 стартовал
 * с 2306 МБ и упёрся в 4094.1 на 210-й минуте при росте 5.7 МБ/мин. Ошибка порога здесь
 * стоит либо целого раунда (сработали рано), либо молчаливой смерти процесса (не сработали).
 */
/datum/unit_test/memory_endgame_thresholds

/datum/unit_test/memory_endgame_thresholds/Run()
	var/ceiling = 4094
	var/lead = 40
	var/late_round = 200 MINUTES

	// Старт раунда: 2306 МБ - это 56% потолка. Даже с абсурдной скоростью роста ступени быть
	// не должно, иначе автоэвакуация срывается на роундстарте каждый раунд.
	TEST_ASSERT_EQUAL(memory_endgame_step(2306, ceiling, 200, 5 MINUTES, lead, FALSE, FALSE, TRUE), MEMORY_ENDGAME_NONE,
		"на старте раунда ступени быть не должно ни при какой скорости роста")

	// Середина 10105: 3506 МБ (86% потолка), рост 5.7 - до потолка ещё сто минут.
	TEST_ASSERT_EQUAL(memory_endgame_step(3506, ceiling, 5.7, 85 MINUTES, lead, FALSE, FALSE, TRUE), MEMORY_ENDGAME_NONE,
		"пока запаса больше срока, раунд трогать нельзя")

	// 104-я минута 10105: 3706 МБ (91% потолка), но получасовое окно показывает 9.7 МБ/мин
	// против 5.7 средних по раунду, и прогноз даёт ровно 40 минут. Планка 0.85 или 0.90
	// срезала бы здесь полтора часа живого раунда - именно поэтому она 0.93.
	TEST_ASSERT_EQUAL(memory_endgame_step(3706, ceiling, 9.7, 104 MINUTES, lead, FALSE, FALSE, TRUE), MEMORY_ENDGAME_NONE,
		"всплеск скорости роста на 91% потолка не должен обрезать раунд")

	// 160-я минута 10105: 3892 МБ (95%), рост 5.7 - расчётного запаса 35 минут.
	TEST_ASSERT_EQUAL(memory_endgame_step(3892, ceiling, 5.7, 160 MINUTES, lead, FALSE, FALSE, TRUE), MEMORY_ENDGAME_EVAC,
		"при 95% потолка и 35 расчётных минутах обязан вызываться шаттл")

	// Тот же замер, но шаттл уже вызван - повторного вызова быть не должно.
	TEST_ASSERT_EQUAL(memory_endgame_step(3892, ceiling, 5.7, 160 MINUTES, lead, TRUE, FALSE, TRUE), MEMORY_ENDGAME_NONE,
		"ступень эвакуации одноразовая")

	// Высокая занятость без роста: срока нет, ступени нет. Иначе плоская память у потолка
	// означала бы вечную эвакуацию.
	TEST_ASSERT_EQUAL(memory_endgame_step(3892, ceiling, 0, 160 MINUTES, lead, FALSE, FALSE, TRUE), MEMORY_ENDGAME_NONE,
		"без замеренной скорости роста срок посчитать нельзя, ступени быть не должно")

	// Бэкстоп: до потолка 94 МБ. Работает даже когда шаттл уже вызван и даже когда
	// автоэвакуация выключена конфигом - иначе выключенный флаг возвращал бы молчаливую смерть.
	TEST_ASSERT_EQUAL(memory_endgame_step(4000, ceiling, 5.7, late_round, lead, TRUE, FALSE, TRUE), MEMORY_ENDGAME_FORCE_END,
		"на остатке 94 МБ раунд обязан завершаться принудительно даже с вызванным шаттлом")
	TEST_ASSERT_EQUAL(memory_endgame_step(4000, ceiling, 5.7, late_round, lead, TRUE, FALSE, FALSE), MEMORY_ENDGAME_FORCE_END,
		"выключенная автоэвакуация не отменяет бэкстоп")
	TEST_ASSERT_EQUAL(memory_endgame_step(4000, ceiling, 5.7, late_round, lead, TRUE, TRUE, TRUE), MEMORY_ENDGAME_NONE,
		"бэкстоп одноразовый")

	// Выключенный флаг: эвакуации нет, пока бэкстоп не достигнут.
	TEST_ASSERT_EQUAL(memory_endgame_step(3892, ceiling, 5.7, 160 MINUTES, lead, FALSE, FALSE, FALSE), MEMORY_ENDGAME_NONE,
		"выключенная автоэвакуация обязана отключать именно эвакуацию")

	// Потолок не замерен - решать не по чему.
	TEST_ASSERT_EQUAL(memory_endgame_step(3892, PROCESS_ADDRESS_CEILING_UNKNOWN, 5.7, late_round, lead, FALSE, FALSE, TRUE), MEMORY_ENDGAME_NONE,
		"без замеренного потолка ступеней быть не может")

/**
 * Перепись графа освещения обязана отработать на живом мире и не уронить рантайм.
 *
 * Строка эта - единственный замер `corner.affecting` и `source.effect_str`: эти структуры не
 * видит ни перепись инстансов (углы и источники не лежат в world.contents), ни перепись
 * глобальных списков (они не глобалки). Рантайм внутри неё убил бы весь проход переписи, а не
 * только эту строку, поэтому проверяется именно то, что она проходит по настоящему миру.
 */
/datum/unit_test/memory_lighting_graph_census/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting не инициализирована")
	TEST_ASSERT_NOTNULL(GLOB.all_light_sources, "список источников света обязан существовать")
	SStime_track.log_lighting_graph_slots()

