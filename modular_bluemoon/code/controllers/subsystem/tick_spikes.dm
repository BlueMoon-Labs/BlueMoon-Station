/**
 * # SStick_spikes - детектор и рекордер тик-спайков (резких скачков time dilation)
 *
 * Проблема: "Откл" (time dilation) считается SStime_track раз в 10 секунд как средняя
 * потеря тиков за окно, а профайлер BYOND агрегирует время за весь раунд. Одиночный
 * фриз сервера на 200-1000 мс не виден ни там, ни там - он размазывается по средним.
 *
 * Эта подсистема каждый тик замеряет реальное время (монотонные часы rust-g) и сравнивает
 * его с игровым. Если реального времени прошло заметно больше игрового - тик "растянулся",
 * это и есть спайк. На каждый спайк пишется событие с контекстом:
 *  - кольцевой буфер последних тиков (usage/cpu/map_cpu) - что происходило вокруг;
 *  - сырые "тяжёлые прогоны" подсистем МК за последние секунды (хук в RunQueue).
 *    ВАЖНО: это wall-time - столл ОС/BYOND во время слота подсистемы выглядит как её
 *    тяжёлый прогон. Прежде чем винить подсистему, сверяй с дампом профайлера: если под
 *    ней нет соответствующего проковского self/over времени - это был столл в её слоте;
 *  - недавние хардделы из кольца SSgarbage - одиночный дорогой del() объясняет спайки Garbage;
 *  - автоклассификация источника (подсистема МК / DM вне МК / SendMaps / блокирующий вызов /
 *    пропущенные фаеры МК / внешний столл). Классы DM и SendMaps решаются по ПРИРОСТУ
 *    world.cpu и world.map_cpu над фоном последних тиков, а не по абсолютному значению:
 *    фон растёт по ходу раунда, и любой фиксированный порог в начале раунда недостижим,
 *    а в конце достижим одним фоном;
 *  - при активном захвате - JSON-снапшот профайлера (кумулятивный; окно спайка = дифф
 *    соседних дампов, числа в них монотонно растут).
 *
 * Как пользоваться (админ-вербы в категории Debug):
 *  - "Tick Spikes Report" - текущий отчёт со всеми пойманными спайками;
 *  - "Tick Spikes Capture" - включить сессию захвата с дампами профайлера на спайках;
 *  - "Simulate Tick Spike" - синтетический фриз заданной длины для проверки всей цепочки.
 *
 * Файлы за раунд: [папка логов]/tick_spikes.log, tick_spike_profile_N.json (дампы на
 * спайках) и tick_spike_periodic_N.json (sendmaps-профиль по равномерной сетке, см.
 * maybe_dump_periodic_profile - только по нему дельты кумулятивных счётчиков сравнимы).
 */

/// Размер кольцевого буфера пер-тиковой телеметрии (~30 сек при 20 fps)
#define TICK_SPIKES_HISTORY 600
/// Размер кольца сырых тяжёлых прогонов подсистем МК
#define TICK_SPIKES_HEAVY_HISTORY 128
/// Размер кольца медленных единиц работы вне МК (таймер-колбеки, отложенные вербы, Topic)
#define TICK_SPIKES_SLOW_WORK_HISTORY 64
/// Сколько последних тиков печатать в отчёте о событии
#define TICK_SPIKES_REPORT_WINDOW 20
/// За какое окно (в игровом времени) собирать тяжёлые прогоны в отчёт о событии
#define TICK_SPIKES_HEAVY_WINDOW (5 SECONDS)
/// Идентификатор монотонных часов rust-g
#define TICK_SPIKES_CLOCK "ss_tick_spikes"
/// Максимум событий, хранимых в памяти для отчёта
#define TICK_SPIKES_MAX_EVENTS 40
/// Минимальный дрифт (мс) для учёта в гистограмме
#define TICK_SPIKES_HISTOGRAM_FLOOR 25
// Верхние границы корзин гистограммы дрифтов (мс); нижняя граница первой - TICK_SPIKES_HISTOGRAM_FLOOR
#define TICK_SPIKES_HISTOGRAM_BUCKET_1 50
#define TICK_SPIKES_HISTOGRAM_BUCKET_2 100
#define TICK_SPIKES_HISTOGRAM_BUCKET_3 300
#define TICK_SPIKES_HISTOGRAM_BUCKET_4 1000
/// Сколько последних тиков считаются "тиками спайка" при классификации источника
#define TICK_SPIKES_CLASSIFY_WINDOW_TICKS 3
/// Порог ПРИРОСТА world.cpu (процентных пунктов над фоном) в тиках спайка, с которого
/// источник классифицируется как DM вне МК.
///
/// Абсолютный порог для этого негоден по построению: фоновый world.cpu растёт по ходу
/// раунда (в 9849 к 35-й минуте он сам по себе 40-50%), поэтому один и тот же порог в
/// начале раунда недостижим, а в конце достижим одним только фоном. Прирост же делит
/// классы чисто: у настоящего внешнего столла медиана прироста +0.9 п.п. (тик стартовал
/// позже, работы внутри тика не было), у DM-переработки того же размера дрифта +37...+50
/// п.п. На всех 76 полных блоках раунда 9849 порог 15 не ошибся ни разу.
#define TICK_SPIKES_CLASSIFY_CPU_DELTA 15
/// Порог прироста map_cpu (п.п.) над фоном для класса SendMaps. Наблюдаемый шум дельты
/// map_cpu у внешних столлов раунда 9849 - от -1.7 до +1.1 п.п., так что 3 п.п. вне шума.
#define TICK_SPIKES_CLASSIFY_MAP_CPU_DELTA 3
/// ЗАПАСНОЙ абсолютный порог cpu (%). Работает ТОЛЬКО когда фона ещё не набрано (первые
/// тики раунда, синтетика юнит-теста) и дельту считать не из чего. Как самостоятельное
/// ИЛИ он вреден: при фоне 90% его перешагивает один фон - в раунде 9849 так был ошибочно
/// назван DM-переработкой спайк #17 (cpu 96.3% при фоне 90.5%, прирост всего +5.8 п.п.,
/// а по шагу детектора видно, что дрифт накопился за три тика).
#define TICK_SPIKES_CLASSIFY_CPU_THRESHOLD 70
/// Запасной абсолютный порог map_cpu (%), та же роль. world.map_cpu - СГЛАЖЕННОЕ
/// среднее, а не мгновенная доля тика, поэтому порог 50 был практически недостижим: в
/// прод-раунде 9835 (125 клиентов, map_cpu фоном 13-22%) его перешли 4 тика из 758 спайков,
/// и вся стоимость рассылки карты утекала в "внешний столл".
/// 30% отделяет всплески от фона: в 9835 таких тиков 27, в спокойном 9834 - ни одного.
#define TICK_SPIKES_CLASSIFY_MAP_CPU_THRESHOLD 30
/// Границы фонового окна для дельт: тики с -OLDEST по -NEWEST относительно тика спайка.
/// Два ближних тика исключены намеренно - сглаженные world.cpu/world.map_cpu подтягиваются
/// с задержкой, и работа самого спайка успевает подмешаться в них.
#define TICK_SPIKES_BASELINE_OLDEST_TICK 10
#define TICK_SPIKES_BASELINE_NEWEST_TICK 3
/// За сколько примерно тиков world.cpu усредняет tick_usage. Проверено на спайке #2 раунда
/// 9849: дрифт 9850мс при тике 50мс - это 197 тиков работы, а world.cpu показал 1278%,
/// то есть работа размазалась по окну примерно в 16 тиков.
#define TICK_SPIKES_CPU_SMOOTHING_TICKS 16
/// Доля ожидаемого прироста cpu, ниже которой в блок пишется вывод "работы внутри тика не
/// было, тик просто стартовал позже"
#define TICK_SPIKES_CPU_SHORTFALL_RATIO 0.25
/// Со скольких пропущенных фаеров МК дрифт объявляется накопленным за несколько тиков
#define TICK_SPIKES_MISSED_FIRES_FLOOR 1
/// На сколько тиков после нашего дампа профайлера спайки считаются самонаведёнными
#define TICK_SPIKES_SELF_INFLICTED_TICKS 2
/// Какую долю дрифта должен покрыть блокирующий вызов, чтобы его назвали виновником
#define TICK_SPIKES_BLOCKING_COVERAGE 0.5
/// Как часто выгружать в лог накопленный итог по блокирующим вызовам
#define TICK_SPIKES_BLOCKING_SUMMARY_INTERVAL (5 MINUTES)
/// Бюджет авто-дампов sendmaps-профиля за раунд (вне сессии захвата)
#define TICK_SPIKES_MAX_AUTO_DUMPS 12
/// Шаг НЕЗАВИСИМОГО периодического дампа sendmaps-профиля. Спайковые дампы приходят
/// когда придётся (в раунде 9847 интервалы между ними гуляли от 15 до 130 секунд), а
/// счётчики профайлера кумулятивные: дельта соседних дампов делится на неизвестное
/// окно, и сравнивать такие дельты между собой нельзя. Равномерная сетка это чинит.
#define TICK_SPIKES_PERIODIC_DUMP_INTERVAL (60 SECONDS)
/// Бюджет периодических дампов за раунд - СВОЙ, лимит спайковых он не тратит.
/// 240 шагов по минуте = четыре часа покрытия, дольше типового раунда.
#define TICK_SPIKES_MAX_PERIODIC_DUMPS 240
/// Каждые сколько фаеров детектора проверять VmSize. Чтение /proc/self/status стоит
/// десятки микросекунд, но каждый тик оно всё равно лишнее: ступени, ради которых всё
/// затевалось, в раунде 10121 были по 8-53 МБ, и полусекундной сетки хватает, чтобы
/// каждая легла в свой сэмпл целиком, а кольца контекста (5 секунд) её накрыли.
#define TICK_SPIKES_MEMORY_SAMPLE_TICKS 5
/// Порог скачка VmSize (МБ), с которого пишется блок. В раунде 10121 семнадцать ступеней
/// >= 8 МБ дали 81% всего роста раунда, а 184 сэмпла из 290 не росли вообще: порог 8
/// ловит весь вклад и молчит на фоне.
#define TICK_SPIKES_MEMORY_JUMP_MB 8
/// Бюджет блоков о скачках памяти за раунд. Семнадцать ступеней в 10121 - типовой
/// масштаб; шестьдесят покрывают даже раунд, который течёт вчетверо охотнее.
#define TICK_SPIKES_MAX_MEMORY_EVENTS 60
/// Сколько байт на один новый объект - это ещё "заплатили датумами". /atom с записанными
/// варами стоит 200-600 Б, самый жирный - около килобайта. Всё, что выше двух килобайт на
/// объект, датумами не объясняется, и искать надо среди аппирансов, иконок, RSC и
/// поклиентской машинерии карты. Раунд 10121: 666 МБ пришли при УМЕНЬШИВШЕМСЯ на 941
/// числе инстансов, и ни перепись инстансов, ни перепись датумов их не увидели.
#define TICK_SPIKES_MEMORY_BYTES_PER_INSTANCE_CEILING 2048

/// Дрифт (мс), с которого полный блок пишется ВСЕГДА, в обход рейт-лимита. В раунде
/// 9847 три крупных спайка (849, 484 и 431мс) остались краткими однострочниками
/// только потому, что попали в трёхсекундное окно после предыдущего блока, и
/// диагностировать их было нечем.
#define TICK_SPIKES_FULL_EVENT_DRIFT_FLOOR 300

// Классы источников спайка
#define TICK_SPIKE_CLASS_MC "подсистема МК"
#define TICK_SPIKE_CLASS_DM "DM вне МК (вербы/Topic/спящие проки)"
#define TICK_SPIKE_CLASS_SENDMAPS "SendMaps (рассылка карты клиентам)"
#define TICK_SPIKE_CLASS_EXTERNAL "внешний столл (диск/ОС/BYOND), DM почти не работал"
#define TICK_SPIKE_CLASS_MISSED_FIRES "МК не давал детектору фаериться, дрифт накоплен за несколько тиков"
#define TICK_SPIKE_CLASS_SELF "дамп профайлера самой диагностики"
#define TICK_SPIKE_CLASS_BLOCKING "блокирующий вызов (ожидание клиента/диска)"

SUBSYSTEM_DEF(tick_spikes)
	name = "Tick Spikes"
	wait = 1
	priority = FIRE_PRIORITY_TICK_SPIKES
	flags = SS_TICKER | SS_NO_INIT
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	/// Порог дрифта (мс реального времени сверх игрового за тик), с которого фиксируем событие
	var/spike_threshold_ms = 100
	/// Порог сырого прогона подсистемы МК (в % тика), с которого он попадает в кольцо тяжёлых прогонов
	var/heavy_run_threshold = 40
	/// Дрифт (мс), с которого события анонсируются админам
	var/announce_threshold_ms = 500
	/// Анонсировать ли крупные спайки в админ-чат. По умолчанию выключено: на хайпопе спайки
	/// постоянные и спамят, а информация нужна разработчикам в логе, не админам в раунде.
	/// Включается через VV на время целевой отладки.
	var/announce_to_admins = FALSE
	/// Минимум мс между анонсами в админ-чат
	var/announce_cooldown_ms = 30000

	// --- Пер-тиковый кольцевой буфер ---
	var/list/ring_world_time
	var/list/ring_drift
	var/list/ring_usage_at_fire
	var/list/ring_cpu
	var/list/ring_map_cpu
	var/ring_pos = 0
	var/samples_collected = 0
	/// Шаг world.time (дс) между двумя последними замерами. В норме равен world.tick_lag;
	/// больше - значит МК несколько тиков подряд не давал нам фаериться, и дрифт накоплен
	/// не за один межтиковый промежуток, а за несколько. В раунде 9849 так было в 13
	/// событиях из 49, и отличить это от одиночного столла было нечем.
	var/last_step_ds = 0

	// --- Кольцо тяжёлых прогонов подсистем (пишется хуком из Master/RunQueue) ---
	var/list/heavy_time
	var/list/heavy_name
	var/list/heavy_usage
	var/heavy_pos = 0

	// --- Самый тяжёлый прогон очереди МК в ТЕКУЩЕМ тике (пишется хуком из Master/RunQueue).
	//
	// Поле структурно мёртвое и в отчёт больше не идёт. Хук обнуляет тройку при смене
	// world.time, а наш fire() стоит на приоритете 900: выше нас только SSinput (1000),
	// SSverb_manager (997) и SSmouse_entered (996), поэтому к моменту замера в текущем тике
	// успевают отработать только они. Сначала здесь лежал ПОСЛЕДНИЙ прогон и в 178 записях
	// раундов 9831/9832 стоял MouseEntered; после правки на "самый тяжёлый" во ВСЕХ блоках
	// раундов 9847 и 9849 стоит Input. Данные предыдущего тика хук затирает раньше, чем мы
	// их увидим, поэтому оживить поле можно только правкой Master/RunQueue (снапшот тройки
	// перед обнулением). До тех пор отчёт берёт самый тяжёлый прогон предыдущего тика из
	// кольца тяжёлых прогонов - оно смену тика переживает, см. heaviest_run_previous_tick().
	// Сами переменные оставлены: их пишет хук в code/controllers/master.dm ---
	var/heaviest_run_subsystem_name
	var/heaviest_run_subsystem_usage = 0
	var/heaviest_run_tick = 0

	// --- Кольцо медленных единиц работы вне слотов подсистем: таймер-колбеки (SStimer),
	// отложенные вербы (SSverb_manager), client/Topic. Раньше весь этот DM был анонимным -
	// спайк классифицировался как "DM вне МК" без имени виновника ---
	var/list/slow_work_time
	var/list/slow_work_kind
	var/list/slow_work_desc
	var/list/slow_work_cost
	var/slow_work_pos = 0
	/// Порог стоимости (мс синхронной части, до первого сна), с которого единица работы
	/// попадает в кольцо. Общий для всех точек замера, крутится через VV.
	var/slow_work_threshold_ms = 30

	// --- Учёт блокирующих вызовов ---
	// Пока DM стоит внутри winget/winexists (ожидание ответа клиента по сети),
	// записи в savefile или world.Export, процесс DreamDaemon не выполняет ни строчки
	// и не жжёт CPU. Детектор видит "реального времени прошло много, world.cpu низкий"
	// и списывает это на внешний столл - в раунде 9838 таких спайков было 122 из 246,
	// то есть половина потерь была безымянной. Замер вокруг самих примитивов
	// превращает анонимный столл в именованную запись.
	/// Суммарно мс за раунд во всех замеренных блокирующих вызовах (обе группы)
	var/blocking_total_ms = 0
	/// Сколько замеренных блокирующих вызовов было (обе группы)
	var/blocking_calls = 0
	/// Группа "усыпляющие": winget/winexists. Это собственное ожидание прока, миру оно
	/// не мешает - МК крутится дальше. Суммировать её с синхронной группой нельзя,
	/// иначе получается бессмыслица вида "= 3725% суммарного дрифта спайков".
	var/blocking_sleeping_calls = 0
	var/blocking_sleeping_ms = 0
	/// Группа "синхронные": savefile, world.Export, блокирующий SQL. Вот они реально
	/// морозят процесс, и только их доля от дрифта спайков имеет смысл.
	var/blocking_sync_calls = 0
	var/blocking_sync_ms = 0
	/// Разбивка по типу вызова: kind -> list("count" = N, "ms" = X, "max" = Y)
	var/list/blocking_by_kind
	/// world.time ЗАВЕРШЕНИЯ последнего блокирующего вызова, перешагнувшего slow_work_threshold_ms
	var/last_blocking_world = 0
	/// world.time НАЧАЛА того же вызова. У синхронных примитивов равен финишу (мир
	/// не тикает, пока процесс заморожен), у усыпляющих - отстаёт на всё время сна.
	var/last_blocking_started_world = 0
	/// Его стоимость и описание - для классификации спайка
	var/last_blocking_cost = 0
	var/last_blocking_kind
	var/last_blocking_desc
	/// world.time следующей периодической выгрузки итога по блокирующим вызовам
	var/next_blocking_summary_world = 0

	// --- Скачки памяти ---
	// Дрифт тика и рост памяти - разные болезни с общим контекстом. Кольца тиков, тяжёлых
	// прогонов, медленных единиц работы и хардделов уже собраны здесь и отвечают на вопрос
	// "что происходило в эти секунды" одинаково хорошо для обеих. Разбору раунда 10121 не
	// хватало ровно этого: рост оказался не фоном, а семнадцатью ступенями по 8-53 МБ (81%
	// роста за раунд), а ближайший прибор - перф-CSV - сэмплирует раз в десять секунд и
	// называет только "сколько", но не "кто".
	/// Порог скачка VmSize (МБ) за один сэмпл
	var/memory_jump_threshold_mb = TICK_SPIKES_MEMORY_JUMP_MB
	/// Через сколько фаеров снимать следующий замер памяти
	var/memory_sample_ticks = TICK_SPIKES_MEMORY_SAMPLE_TICKS
	/// Обратный отсчёт до следующего замера
	var/memory_sample_countdown = 0
	/// VmSize, world.time и world.contents.len на прошлом замере
	var/last_vsz_mb = 0
	var/last_vsz_world = 0
	var/last_vsz_instances = 0
	/// Снимок книги недатумных аллокаций на прошлом замере памяти. Разность с текущим и
	/// есть то, что известные недатумные аллокаторы успели сделать за окно скачка.
	var/list/last_ledger_snapshot
	/// FALSE после первого промаха get_process_memory_mb(): на Windows /proc нет, и
	/// дёргать его каждые полсекунды весь раунд незачем
	var/memory_probe_available = TRUE
	/// Статистика скачков за сессию
	var/memory_jump_count = 0
	var/memory_jump_total_mb = 0
	var/biggest_memory_jump_mb = 0
	var/biggest_memory_jump_at = 0
	/// Сколько блоков уже написано - бюджет TICK_SPIKES_MAX_MEMORY_EVENTS
	var/memory_events_written = 0

	// --- Состояние часов ---
	var/has_baseline = FALSE
	var/last_ms = 0
	var/last_world = 0

	// --- Статистика сессии ---
	var/session_spike_count = 0
	var/worst_drift_ms = 0
	var/worst_drift_at = 0
	var/total_spike_drift_ms = 0
	/// Гистограмма дрифтов: 5 корзин по границам TICK_SPIKES_HISTOGRAM_FLOOR / BUCKET_1..4, последняя - всё выше BUCKET_4
	var/list/drift_histogram
	/// Master.iteration и world.time предыдущего спайка. Голая итерация ни о чём не говорит,
	/// а её дельта в сравнении с числом прошедших тиков - готовый индикатор переработки
	/// очереди МК: сколько тиков МК не сумел провернуть целиком. В раунде 9849 дефицит рос
	/// от 1-3% в начале раунда до 9.5% в конце.
	var/last_spike_iteration = 0
	var/last_spike_world = 0
	/// Предыдущий кумулятивный снимок sendmaps-профиля (value в секундах и число вызовов).
	/// Нужен, чтобы в блоке печатать не только кумулятив, но и дельту с прошлого блока -
	/// файловых дампов на это не хватает, их бюджет выгорает за первые десять минут раунда.
	var/last_sendmaps_value = 0
	var/last_sendmaps_calls = 0

	/// Список текстовых блоков последних событий (для отчёта)
	var/list/spike_events

	// --- Сессия захвата с профайлером ---
	/// world.time, до которого активен захват (0 = выключен)
	var/capture_until = 0
	/// Запустили ли профайлер мы сами (чтобы не выключить чужой auto_profile)
	var/started_profiler = FALSE
	var/profile_dumps_done = 0
	var/last_profile_dump_ms = 0
	/// Числовой хвост к последней классификации (cpu/map_cpu). Живёт отдельно от строки
	/// класса, потому что класс сравнивается на точное равенство при решении об авто-дампе.
	var/last_classify_detail = ""
	///монотонный номер для имён файлов дампов: НЕ сбрасывается на start_capture,
	///иначе авто-дамп и дамп новой сессии склеили бы два JSON в один файл
	var/profile_dump_seq = 0
	/// Сколько авто-дампов (без сессии захвата) уже сделано за раунд - бюджет общий на
	/// классы SendMaps и "внешний столл", чтобы поток спайков на хайпопе не завалил
	/// каталог логов сотней JSON'ов.
	var/auto_dumps_done = 0
	/// world.time следующего периодического дампа sendmaps-профиля (сетка независима от спайков)
	var/next_periodic_dump_world = 0
	/// Сколько периодических дампов сделано за раунд (свой бюджет, см. TICK_SPIKES_MAX_PERIODIC_DUMPS)
	var/periodic_dumps_done = 0
	/// Монотонный номер файла периодического дампа. Как и profile_dump_seq, не сбрасывается:
	/// иначе WRITE_FILE доклеил бы новый JSON в конец уже существующего файла
	var/periodic_dump_seq = 0
	/// Минимум мс между дампами профайлера
	var/profile_dump_cooldown_ms = 15000
	/// world.time, до которого спайки считаются самонаведёнными (после нашего же дампа)
	var/self_inflicted_until = 0

	/// Минимум мс между ПОЛНЫМИ блоками событий в логе: на хайпопе спайки идут потоком,
	/// и полный контекст на каждый раздул бы лог. Промежуточные пишутся одной строкой.
	/// Троттлинг работает только для мелочи: дрифт от TICK_SPIKES_FULL_EVENT_DRIFT_FLOOR
	/// и выше получает полный блок всегда, интервал ему не помеха.
	var/full_event_min_interval_ms = 3000
	/// Момент (мс часов rust-g) последнего полного блока
	var/last_full_event_ms = 0
	/// Сколько спайков записано кратко из-за рейт-лимита
	var/suppressed_event_count = 0

	/// Метка для следующего события (ставится вербом симуляции)
	var/next_spike_tag

	var/last_announce_ms = 0
	/// Путь к файлу лога событий
	var/log_path

	// --- Тестовые крутилки ---
	/// Не писать в файлы и не дёргать админ-чат/профайлер (для юнит-тестов)
	var/suppress_side_effects = FALSE
	/// Детектить спайки даже без клиентов на сервере (для юнит-тестов и локалки)
	var/ignore_empty_server = FALSE

/datum/controller/subsystem/tick_spikes/PreInit()
	reset_state()
#if DM_VERSION >= 515
	// Always-on SendMaps profiling: the proc profiler can't see render/maptick
	// cost at all, and SendMaps spikes used to be diagnosable only during an
	// admin-started capture session. The sendmaps profile is a small aggregate
	// table (negligible overhead), so keep it running from boot and auto-dump
	// it whenever a spike classifies as SendMaps (see try_dump_profile).
	world.Profile(PROFILE_START, type = "sendmaps")
#endif

/// Пересоздание МК (NEW_SS_GLOBAL): PreInit() нового инстанса всё равно
/// обнулит кольца и статистику, поэтому переносим только то, что он не трогает -
/// админские настройки, активную сессию захвата и монотонный номер дампов
/// (без него следующий дамп доклеился бы WRITE_FILE'ом в старый JSON-файл).
/datum/controller/subsystem/tick_spikes/Recover()
	spike_threshold_ms = SStick_spikes.spike_threshold_ms
	heavy_run_threshold = SStick_spikes.heavy_run_threshold
	announce_threshold_ms = SStick_spikes.announce_threshold_ms
	announce_to_admins = SStick_spikes.announce_to_admins
	announce_cooldown_ms = SStick_spikes.announce_cooldown_ms
	last_announce_ms = SStick_spikes.last_announce_ms
	capture_until = SStick_spikes.capture_until
	started_profiler = SStick_spikes.started_profiler
	profile_dumps_done = SStick_spikes.profile_dumps_done
	last_profile_dump_ms = SStick_spikes.last_profile_dump_ms
	profile_dump_seq = SStick_spikes.profile_dump_seq
	periodic_dump_seq = SStick_spikes.periodic_dump_seq
	periodic_dumps_done = SStick_spikes.periodic_dumps_done
	next_periodic_dump_world = SStick_spikes.next_periodic_dump_world
	profile_dump_cooldown_ms = SStick_spikes.profile_dump_cooldown_ms
	self_inflicted_until = SStick_spikes.self_inflicted_until
	full_event_min_interval_ms = SStick_spikes.full_event_min_interval_ms
	log_path = SStick_spikes.log_path
	suppress_side_effects = SStick_spikes.suppress_side_effects
	ignore_empty_server = SStick_spikes.ignore_empty_server
	slow_work_threshold_ms = SStick_spikes.slow_work_threshold_ms
	memory_jump_threshold_mb = SStick_spikes.memory_jump_threshold_mb
	memory_sample_ticks = SStick_spikes.memory_sample_ticks
	memory_probe_available = SStick_spikes.memory_probe_available

/// Полный сброс колец и статистики. Не трогает настройки порогов.
/datum/controller/subsystem/tick_spikes/proc/reset_state()
	ring_world_time = new /list(TICK_SPIKES_HISTORY)
	ring_drift = new /list(TICK_SPIKES_HISTORY)
	ring_usage_at_fire = new /list(TICK_SPIKES_HISTORY)
	ring_cpu = new /list(TICK_SPIKES_HISTORY)
	ring_map_cpu = new /list(TICK_SPIKES_HISTORY)
	ring_pos = 0
	samples_collected = 0
	last_step_ds = 0
	heavy_time = new /list(TICK_SPIKES_HEAVY_HISTORY)
	heavy_name = new /list(TICK_SPIKES_HEAVY_HISTORY)
	heavy_usage = new /list(TICK_SPIKES_HEAVY_HISTORY)
	heavy_pos = 0
	slow_work_time = new /list(TICK_SPIKES_SLOW_WORK_HISTORY)
	slow_work_kind = new /list(TICK_SPIKES_SLOW_WORK_HISTORY)
	slow_work_desc = new /list(TICK_SPIKES_SLOW_WORK_HISTORY)
	slow_work_cost = new /list(TICK_SPIKES_SLOW_WORK_HISTORY)
	slow_work_pos = 0
	blocking_total_ms = 0
	blocking_calls = 0
	blocking_sleeping_calls = 0
	blocking_sleeping_ms = 0
	blocking_sync_calls = 0
	blocking_sync_ms = 0
	blocking_by_kind = list()
	last_blocking_world = 0
	last_blocking_started_world = 0
	last_blocking_cost = 0
	last_blocking_kind = null
	last_blocking_desc = null
	next_blocking_summary_world = 0
	memory_sample_countdown = 0
	last_vsz_mb = 0
	last_vsz_world = 0
	last_vsz_instances = 0
	last_ledger_snapshot = null
	memory_probe_available = TRUE
	memory_jump_count = 0
	memory_jump_total_mb = 0
	biggest_memory_jump_mb = 0
	biggest_memory_jump_at = 0
	memory_events_written = 0
	has_baseline = FALSE
	last_ms = 0
	last_world = 0
	session_spike_count = 0
	worst_drift_ms = 0
	worst_drift_at = 0
	total_spike_drift_ms = 0
	drift_histogram = list(0, 0, 0, 0, 0)
	last_spike_iteration = 0
	last_spike_world = 0
	last_sendmaps_value = 0
	last_sendmaps_calls = 0
	spike_events = list()
	last_full_event_ms = 0
	suppressed_event_count = 0

/datum/controller/subsystem/tick_spikes/stat_entry(msg)
	msg = "спайков:[session_spike_count] худший:[round(worst_drift_ms)]мс[memory_jump_count ? " память:[memory_jump_count]/[round(memory_jump_total_mb)]МБ" : ""][capture_until ? " ЗАХВАТ" : ""]"
	return ..()

/datum/controller/subsystem/tick_spikes/fire()
	sample_tick(rustg_time_milliseconds(TICK_SPIKES_CLOCK), world.time, TICK_USAGE, world.cpu, MAPTICK_LAST_INTERNAL_TICK_USAGE)
	sample_memory()
	if(capture_until && world.time > capture_until)
		stop_capture(automatic = TRUE)
	maybe_dump_periodic_profile()
	// Итог по блокирующим вызовам пишем периодически, а не на Shutdown: архив логов
	// снимают с живого раунда, а Shutdown при аварийном рестарте не отрабатывает вовсе
	if(world.time >= next_blocking_summary_world)
		next_blocking_summary_world = world.time + TICK_SPIKES_BLOCKING_SUMMARY_INTERVAL
		if(blocking_calls)
			// Каждая группа своей строкой и со своим таймстампом: строки читают глазами и грепают
			for(var/summary_line in build_blocking_summary_lines())
				write_to_log("[time_stamp_from_world(world.time)] [summary_line]")

/**
 * Обработка одного тика. Вынесена из fire() с явными аргументами,
 * чтобы юнит-тест мог скармливать синтетические последовательности.
 * Возвращает дрифт в мс (или null, если это был первый замер).
 */
/datum/controller/subsystem/tick_spikes/proc/sample_tick(now_ms, now_world, usage_at_fire, cpu, map_cpu)
	if(!has_baseline)
		has_baseline = TRUE
		last_ms = now_ms
		last_world = now_world
		return null

	var/real_delta = now_ms - last_ms
	var/world_delta = (now_world - last_world) * 100 // дс -> мс
	var/drift = real_delta - world_delta
	// Шаг игрового времени между замерами: в норме это ровно один тик. Больше - значит МК
	// нас пропускал, и весь дрифт ниже накоплен за несколько тиков, а не за один.
	last_step_ds = now_world - last_world
	last_ms = now_ms
	last_world = now_world

	ring_pos = (ring_pos % TICK_SPIKES_HISTORY) + 1
	ring_world_time[ring_pos] = now_world
	ring_drift[ring_pos] = drift
	ring_usage_at_fire[ring_pos] = usage_at_fire
	ring_cpu[ring_pos] = cpu
	ring_map_cpu[ring_pos] = map_cpu
	samples_collected++

	// Пустой сервер (sleep_offline, ребут, ожидание) даёт гигантские ложные дрифты -
	// не пускать их ни в гистограмму, ни в события (кольцо выше оставляем: это контекст, не статистика)
	if(!length(GLOB.clients) && !ignore_empty_server)
		return drift

	if(drift >= TICK_SPIKES_HISTOGRAM_FLOOR)
		if(drift < TICK_SPIKES_HISTOGRAM_BUCKET_1)
			drift_histogram[1]++
		else if(drift < TICK_SPIKES_HISTOGRAM_BUCKET_2)
			drift_histogram[2]++
		else if(drift < TICK_SPIKES_HISTOGRAM_BUCKET_3)
			drift_histogram[3]++
		else if(drift < TICK_SPIKES_HISTOGRAM_BUCKET_4)
			drift_histogram[4]++
		else
			drift_histogram[5]++

	if(drift < spike_threshold_ms)
		return drift

	register_spike(drift, now_ms, now_world)
	return drift

/**
 * Замер VmSize по своей сетке и блок на скачок.
 *
 * Отдельный от sample_tick() отсчёт: дрифт меряется каждый тик, память - раз в
 * memory_sample_ticks фаеров. Пустой сервер НЕ исключается, в отличие от дрифта:
 * растянутый тик на сервере без клиентов - артефакт sleep_offline, а выросшая на
 * пустом сервере память - это настоящая память (в раунде 10121 свет z-уровня строился
 * именно так).
 */
/datum/controller/subsystem/tick_spikes/proc/sample_memory()
	if(!memory_probe_available)
		return
	if(--memory_sample_countdown > 0)
		return
	memory_sample_countdown = memory_sample_ticks
	var/list/memory = get_process_memory_mb()
	if(!memory)
		// На Windows /proc нет, и промах здесь окончательный: сам get_process_memory_mb()
		// гасит себя после трёх подряд, так что повторять его каждые полсекунды незачем.
		memory_probe_available = FALSE
		return
	var/vsz = memory["vsz"]
	var/instances = world.contents.len
	var/previous_vsz = last_vsz_mb
	var/previous_world = last_vsz_world
	var/previous_instances = last_vsz_instances
	// Снимок книги недатумных аллокаций берётся КАЖДЫЙ раз, а не только на скачке: дельта
	// нужна за окно ДО скачка, а к моменту, когда скачок виден, окно уже закрыто.
	var/list/previous_ledger = last_ledger_snapshot
	last_ledger_snapshot = nondatum_ledger_snapshot()
	last_vsz_mb = vsz
	last_vsz_world = world.time
	last_vsz_instances = instances
	if(!previous_vsz)
		return
	var/jump = vsz - previous_vsz
	if(jump < memory_jump_threshold_mb)
		return
	register_memory_jump(jump, vsz, instances - previous_instances, world.time - previous_world, previous_ledger)

/**
 * Кто заплатил за скачок: датумы или что-то ещё.
 *
 * Это единственный вопрос, на который перф-CSV раунда 10121 ответить не мог, и весь
 * прибор затевался ради него. Отдельным проком, потому что арифметику "байт на объект"
 * без живого раунда иначе не проверить.
 */
/proc/memory_jump_verdict(jump_mb, instances_delta)
	if(instances_delta <= 0)
		return "объектов не прибавилось - платили НЕ датумами"
	var/bytes_each = round(jump_mb * 1048576 / instances_delta)
	if(bytes_each > TICK_SPIKES_MEMORY_BYTES_PER_INSTANCE_CEILING)
		return "[bytes_each] Б на объект - датумами это не объясняется"
	return "[bytes_each] Б на объект - похоже на честную аллокацию объектов"

/// Заголовок блока о скачке памяти. Вынесен, чтобы юнит-тест проверял формулировку
/// вердикта на синтетических числах, не поднимая раунд.
/datum/controller/subsystem/tick_spikes/proc/memory_jump_headline(jump_mb, vsz_mb, instances_delta, window_ds)
	return "скачок: [format_mb_delta(jump_mb)] VmSize за [round(window_ds / 10, 0.1)]с (стало [round(vsz_mb)] МБ), объектов [instances_delta >= 0 ? "+" : ""][instances_delta] - [memory_jump_verdict(jump_mb, instances_delta)]"

/**
 * Блок о скачке VmSize с тем же контекстом, что и у тик-спайка.
 *
 * Смысл ровно в переиспользовании контекста: кольца тяжёлых прогонов подсистем,
 * медленных единиц работы (таймер-колбеки, вербы, Topic, блокирующие вызовы) и недавних
 * хардделов уже отвечают на вопрос "что происходило в эти секунды". Разбор раунда 10121
 * остановился на семнадцати безымянных ступенях именно потому, что рядом с "сколько" не
 * было "кто".
 */
/datum/controller/subsystem/tick_spikes/proc/register_memory_jump(jump_mb, vsz_mb, instances_delta, window_ds, list/previous_ledger)
	memory_jump_count++
	memory_jump_total_mb += jump_mb
	if(jump_mb > biggest_memory_jump_mb)
		biggest_memory_jump_mb = jump_mb
		biggest_memory_jump_at = world.time
	if(memory_events_written >= TICK_SPIKES_MAX_MEMORY_EVENTS)
		return
	memory_events_written++

	var/list/event = list()
	event += "=== СКАЧОК ПАМЯТИ #[memory_jump_count] [time_stamp_from_world(world.time)] (wt [world.time]) ==="
	event += memory_jump_headline(jump_mb, vsz_mb, instances_delta, window_ds)
	event += "клиентов: [length(GLOB.clients)], итого за сессию [memory_jump_count] скачков на [round(memory_jump_total_mb)] МБ"
	event += build_size_metrics_line()
	// Вердикт выше говорит "платили НЕ датумами" и на этом останавливается - книга
	// продолжает фразу. Пустая книга при большой ступени тоже ответ: ни один известный
	// недатумный аллокатор в это окно не работал, ищите новый.
	event += nondatum_ledger_delta_line(previous_ledger, last_ledger_snapshot)

	var/list/heavy_lines = collect_heavy_runs(world.time - TICK_SPIKES_HEAVY_WINDOW)
	if(length(heavy_lines))
		event += "тяжёлые прогоны подсистем за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек:"
		event += heavy_lines

	var/list/slow_work_lines = collect_slow_work(world.time - TICK_SPIKES_HEAVY_WINDOW)
	if(length(slow_work_lines))
		event += "медленные единицы работы за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек (таймер-колбеки/вербы/Topic - именно здесь чаще всего стоит виновник разовой аллокации):"
		event += slow_work_lines

	var/list/harddel_lines = collect_recent_harddels(world.time - TICK_SPIKES_HEAVY_WINDOW)
	if(length(harddel_lines))
		event += "хардделы за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек:"
		event += harddel_lines

	var/event_text = event.Join("\n")
	spike_events += event_text
	if(length(spike_events) > TICK_SPIKES_MAX_EVENTS)
		spike_events.Cut(1, 2)
	if(!suppress_side_effects)
		write_to_log("\n[event_text]\n")

/// Пишется из Master/RunQueue: сырой (неусреднённый) прогон подсистемы, съевший заметную долю тика
/datum/controller/subsystem/tick_spikes/proc/record_heavy_run(datum/controller/subsystem/heavy_subsystem, usage)
	heavy_pos = (heavy_pos % TICK_SPIKES_HEAVY_HISTORY) + 1
	heavy_time[heavy_pos] = world.time
	heavy_name[heavy_pos] = heavy_subsystem.name
	heavy_usage[heavy_pos] = usage

/// Собирает тяжёлые прогоны за окно [since_world, до текущего] в текстовые строки (хронологически)
/datum/controller/subsystem/tick_spikes/proc/collect_heavy_runs(since_world)
	var/list/lines = list()
	for(var/i in heavy_ring_chronological())
		var/run_time = heavy_time[i]
		if(isnull(run_time) || run_time < since_world)
			continue
		lines += "  [time_stamp_from_world(run_time)] (wt [run_time]) [heavy_name[i]]: [round(heavy_usage[i], 0.1)]% тика (~[round(heavy_usage[i] * world.tick_lag, 0.1)]мс)"
	return lines

/// Хардделы из кольца SSgarbage за окно [since_world, сейчас]: del() с полным поиском
/// ссылок по миру - на проде одиночный харддел давал спайки по 200-330мс
/datum/controller/subsystem/tick_spikes/proc/collect_recent_harddels(since_world)
	var/list/lines = list()
	if(isnull(SSgarbage?.recent_hard_deletes))
		return lines
	for(var/list/entry in SSgarbage.recent_hard_deletes)
		var/del_time = entry[1]
		if(del_time < since_world)
			continue
		lines += "  [time_stamp_from_world(del_time)] (wt [del_time]) [entry[2]]: [entry[3]]мс"
	return lines

/// Индексы кольца тяжёлых прогонов от старых к новым (кольцо пишется по кругу от heavy_pos)
/datum/controller/subsystem/tick_spikes/proc/heavy_ring_chronological()
	var/list/order = list()
	for(var/i in heavy_pos + 1 to TICK_SPIKES_HEAVY_HISTORY)
		order += i
	for(var/i in 1 to heavy_pos)
		order += i
	return order

/**
 * Запись медленной единицы работы вне слотов подсистем (пишут SStimer,
 * SSverb_manager и client/Topic при стоимости >= slow_work_threshold_ms).
 * kind - короткий тип ("таймер"/"верб"/"Topic"), desc - что именно исполнялось.
 */
/datum/controller/subsystem/tick_spikes/proc/record_slow_work(kind, desc, cost_ms)
	slow_work_pos = (slow_work_pos % TICK_SPIKES_SLOW_WORK_HISTORY) + 1
	slow_work_time[slow_work_pos] = world.time
	slow_work_kind[slow_work_pos] = kind
	slow_work_desc[slow_work_pos] = desc
	slow_work_cost[slow_work_pos] = cost_ms

/// Текущее показание монотонных часов rust-g. Публичный доступ нужен обёрткам
/// блокирующих примитивов: они живут вне этого файла, а идентификатор часов - локальный дефайн.
/datum/controller/subsystem/tick_spikes/proc/now_ms()
	return rustg_time_milliseconds(TICK_SPIKES_CLOCK)

/**
 * Явный список примитивов, которые УСЫПЛЯЮТ вызывающий прок вместо того, чтобы
 * заморозить процесс. Пока такой вызов ждёт ответа скина, МК крутится дальше и
 * world.time идёт: его миллисекунды - собственное ожидание прока, а не потеря тика.
 *
 * Всё, чего здесь нет, считается синхронным (savefile, world.Export, блокирующий SQL) -
 * такой вызов действительно морозит мир. Новую обёртку достаточно дописать сюда, если
 * её примитив спит; строки должны совпадать с kind в местах вызова record_blocking_call
 * (см. modular_bluemoon/code/_HELPERS/blocking_calls.dm).
 */
/datum/controller/subsystem/tick_spikes/proc/is_sleeping_blocking_kind(kind)
	var/static/list/sleeping_kinds = list("winget", "winexists")
	return (kind in sleeping_kinds)

/**
 * Запись завершившегося блокирующего вызова.
 *
 * Считаем ВСЕ вызовы (для итоговой разбивки за раунд), а в кольцо медленной работы
 * и в классификацию отдаём только те, что перешагнули slow_work_threshold_ms.
 *
 * kind - короткий тип примитива ("winget", "savefile", "world.Export"),
 * desc - кого и о чём спрашивали,
 * started_world - world.time момента НАЧАЛА вызова. Не передан - считаем вызов
 * мгновенным (start == finish): для синхронных примитивов это точная правда, мир
 * при них не тикает.
 */
/datum/controller/subsystem/tick_spikes/proc/record_blocking_call(kind, desc, cost_ms, started_world)
	if(cost_ms < 0) //часы переехали - лучше потерять замер, чем испортить статистику
		return
	blocking_calls++
	blocking_total_ms += cost_ms
	if(is_sleeping_blocking_kind(kind))
		blocking_sleeping_calls++
		blocking_sleeping_ms += cost_ms
	else
		blocking_sync_calls++
		blocking_sync_ms += cost_ms
	var/list/bucket = blocking_by_kind[kind]
	if(!bucket)
		bucket = list("count" = 0, "ms" = 0, "max" = 0)
		blocking_by_kind[kind] = bucket
	bucket["count"]++
	bucket["ms"] += cost_ms
	if(cost_ms > bucket["max"])
		bucket["max"] = cost_ms
	if(cost_ms < slow_work_threshold_ms)
		return
	last_blocking_world = world.time
	last_blocking_started_world = isnull(started_world) ? world.time : started_world
	last_blocking_cost = cost_ms
	last_blocking_kind = kind
	last_blocking_desc = desc
	record_slow_work(kind, desc, cost_ms)

/// Описание колбека для кольца медленной работы: тип объекта + прок.
/// Зовётся только для уже пойманных медленных вызовов - стоимость строк не важна.
/datum/controller/subsystem/tick_spikes/proc/callback_desc(datum/callback/callback)
	if(!istype(callback))
		return "не-колбек"
	var/object_part
	if(istext(callback.object)) //GLOBAL_PROC - магическая строка
		object_part = "GLOBAL_PROC"
	else if(isnull(callback.object))
		object_part = "null"
	else
		object_part = "[callback.object.type]"
	// Для обёрток вроде qdel_weakref_resolve сам прок ни о чём не говорит -
	// реальный виновник это первый аргумент. Именуем его тип, если он датум/викреф.
	var/target_part = ""
	if(length(callback.arguments))
		var/first_arg = callback.arguments[1]
		if(isweakref(first_arg))
			var/datum/weakref/target_ref = first_arg
			var/datum/target = target_ref.hard_resolve()
			target_part = target ? " ([target.type])" : " (протухший weakref)"
		else if(isdatum(first_arg))
			var/datum/target = first_arg
			target_part = " ([target.type])"
	return "[object_part] -> [callback.delegate][target_part]"

/// Индексы кольца медленной работы от старых к новым (кольцо пишется по кругу от slow_work_pos)
/datum/controller/subsystem/tick_spikes/proc/slow_work_ring_chronological()
	var/list/order = list()
	for(var/i in slow_work_pos + 1 to TICK_SPIKES_SLOW_WORK_HISTORY)
		order += i
	for(var/i in 1 to slow_work_pos)
		order += i
	return order

/// Медленные единицы работы за окно [since_world, сейчас] в текстовые строки (хронологически)
/datum/controller/subsystem/tick_spikes/proc/collect_slow_work(since_world)
	var/list/lines = list()
	for(var/i in slow_work_ring_chronological())
		var/work_time = slow_work_time[i]
		if(isnull(work_time) || work_time < since_world)
			continue
		lines += "  [time_stamp_from_world(work_time)] (wt [work_time]) [slow_work_kind[i]]: [slow_work_desc[i]] - [round(slow_work_cost[i], 0.1)]мс"
	return lines

/// Форматирует world.time в человекочитаемое станционное время
/datum/controller/subsystem/tick_spikes/proc/time_stamp_from_world(world_ds)
	return gameTimestamp("hh:mm:ss", world_ds)

/**
 * Медиана значений одной колонки кольца за ФОНОВОЕ окно - тики с -OLDEST по -NEWEST
 * относительно текущей позиции кольца.
 *
 * Возвращает null, если фона ещё не набрано (первые тики раунда, синтетика юнит-теста):
 * тогда дельту считать не из чего, и решение принимают страховочные абсолютные пороги.
 * Медиана, а не среднее: в фоновом окне может оказаться хвост предыдущего спайка, и
 * одно выбросное значение утащило бы среднее вверх, замаскировав следующий спайк.
 */
/datum/controller/subsystem/tick_spikes/proc/ring_baseline_median(list/ring)
	var/list/values = list()
	for(var/offset in TICK_SPIKES_BASELINE_NEWEST_TICK to TICK_SPIKES_BASELINE_OLDEST_TICK)
		if(offset >= samples_collected)
			break
		var/idx = ring_pos - offset
		if(idx < 1)
			idx += TICK_SPIKES_HISTORY
		var/value = ring[idx]
		if(isnull(value))
			continue
		values += value
	var/count = length(values)
	if(!count)
		return null
	sortTim(values)
	if(count % 2)
		return values[round((count + 1) / 2)]
	return (values[count / 2] + values[count / 2 + 1]) / 2

/// Максимум значений одной колонки кольца по ТИКАМ СПАЙКА (последние
/// TICK_SPIKES_CLASSIFY_WINDOW_TICKS замеров): world.cpu отражает предыдущий тик, поэтому
/// одного тика спайка мало.
/datum/controller/subsystem/tick_spikes/proc/spike_window_max(list/ring)
	var/result = 0
	for(var/offset in 0 to TICK_SPIKES_CLASSIFY_WINDOW_TICKS - 1)
		var/idx = ring_pos - offset
		if(idx < 1)
			idx += TICK_SPIKES_HISTORY
		result = max(result, ring[idx] || 0)
	return result

/**
 * Ожидаемый прирост world.cpu (в процентных пунктах), если бы ВЕСЬ дрифт был DM-работой
 * внутри тика.
 *
 * world.cpu - скользящее среднее tick_usage примерно за TICK_SPIKES_CPU_SMOOTHING_TICKS
 * тиков, поэтому лишние drift мс работы поднимают его на drift / длина_тика / окно * 100.
 * Сравнение фактического прироста с этим числом и есть главный разделитель классов:
 * у DM-переработки они одного порядка, у внешнего столла фактический прирост около нуля.
 */
/datum/controller/subsystem/tick_spikes/proc/expected_cpu_delta(drift)
	var/tick_ms = world.tick_lag * 100
	if(tick_ms <= 0)
		return 0
	return drift / tick_ms / TICK_SPIKES_CPU_SMOOTHING_TICKS * 100

/// Сколько фаеров МК детектор пропустил перед последним замером (0 - фаерились каждый тик)
/datum/controller/subsystem/tick_spikes/proc/missed_fires()
	var/lag = world.tick_lag
	if(lag <= 0 || last_step_ds <= 0)
		return 0
	return max(round(last_step_ds / lag, 1) - 1, 0)

/**
 * Самый тяжёлый прогон подсистемы в ПРЕДЫДУЩЕМ тике - из кольца тяжёлых прогонов.
 *
 * Поле heaviest_run_subsystem_name для этого не годится (см. комментарий у переменной):
 * к нашему fire() в текущем тике очередь МК ещё почти не отработала. Кольцо смену тика
 * переживает, поэтому предыдущий тик - последний, по которому вообще есть полная картина.
 * Границы окна берутся с запасом в полтика: world.time - число с плавающей точкой, точное
 * сравнение с now_world - tick_lag ненадёжно.
 * Возвращает готовую строку или null, если в том тике никто не перешагнул heavy_run_threshold.
 */
/datum/controller/subsystem/tick_spikes/proc/heaviest_run_previous_tick(now_world)
	var/lag = world.tick_lag
	var/window_start = now_world - (lag * 1.5)
	var/window_end = now_world - (lag * 0.5)
	var/best_name
	var/best_usage = 0
	for(var/i in heavy_ring_chronological())
		var/run_time = heavy_time[i]
		if(isnull(run_time) || run_time < window_start || run_time >= window_end)
			continue
		if(heavy_usage[i] <= best_usage)
			continue
		best_usage = heavy_usage[i]
		best_name = heavy_name[i]
	if(isnull(best_name))
		return null
	return "[best_name] ([round(best_usage, 0.1)]% тика)"

/**
 * Классификация источника спайка по телеметрии вокруг него.
 *
 * Порядок проверок - от именованного виновника к безымянному: прогоны подсистем МК,
 * замеренные блокирующие вызовы, именованная DM-работа из кольца, и только потом эвристики
 * по ПРИРОСТУ cpu/map_cpu над фоном. Терминальный else ("внешний столл") обязан собирать
 * как можно меньше: в раунде 9849 он собрал 49 событий на 16.3 сек - 39.6% всей потери
 * времени за раунд, больше любого названного класса.
 *
 * Подсистему МК виним только если её тяжёлый прогон был прямо в тиках спайка:
 * фоновые прогоны (атмос и т.п.) из широкого 5-секундного окна - это контекст, а не виновник.
 */
/datum/controller/subsystem/tick_spikes/proc/classify_spike(now_world, drift)
	last_classify_detail = ""
	if(world.time < self_inflicted_until)
		return TICK_SPIKE_CLASS_SELF
	var/tight_window_start = now_world - (TICK_SPIKES_CLASSIFY_WINDOW_TICKS * world.tick_lag)
	var/list/culprits = list()
	var/culprits_ms = 0
	for(var/i in heavy_ring_chronological())
		var/run_time = heavy_time[i]
		if(isnull(run_time) || run_time < tight_window_start)
			continue
		culprits += "[heavy_name[i]] ([round(heavy_usage[i], 0.1)]% тика)"
		culprits_ms += heavy_usage[i] * world.tick_lag
	if(length(culprits))
		. = "[TICK_SPIKE_CLASS_MC]: [culprits.Join(", ")]"
		// Названные прогоны могут не покрывать дрифт: тогда основная потеря вне МК
		if(drift && culprits_ms < drift * 0.5)
			. += " - объясняют лишь ~[round(culprits_ms)]мс из [round(drift)]мс, остальное вне МК"
		return .
	// Блокирующий вызов виден раньше, чем cpu-эвристики: пока DM ждёт ответа клиента
	// или диска, world.cpu не растёт, и без этой проверки спайк уехал бы во "внешний
	// столл". Виним только если вызов И НАЧАЛСЯ, и завершился в тиках спайка, и при
	// этом закрывает заметную долю дрифта - иначе это совпадение, а не причина.
	//
	// Проверять один финиш нельзя: winget/winexists усыпляют вызывающий прок, а не
	// морозят мир, поэтому любой прок, спавший в winget во время ЧУЖОГО столла,
	// просыпается и финиширует ровно в тике спайка. В раунде 9847 так были ошибочно
	// помечены 7 спайков из 97, включая крупнейший (9782мс = 32% всего дрифта; реальная
	// причина - заморозка SSticker.setup()). Синхронные примитивы (savefile, SQL,
	// world.Export) не страдают: мир при них не тикает, у них старт равен финишу.
	if(last_blocking_started_world >= tight_window_start && last_blocking_world >= tight_window_start && drift && last_blocking_cost >= drift * TICK_SPIKES_BLOCKING_COVERAGE)
		last_classify_detail = " - [last_blocking_kind]: [last_blocking_desc], [round(last_blocking_cost)]мс из [round(drift)]мс"
		return TICK_SPIKE_CLASS_BLOCKING
	// Кольцо медленной работы в классификации раньше не участвовало вообще - смотрели
	// только ПОСЛЕДНИЙ блокирующий вызов. А в раунде 9849 у 7 событий из 49 прямо в окне
	// спайка лежала именованная DM-работа (Topic'и настроек, выбора работы и tgui),
	// покрывавшая весь дрифт целиком, и все семь всё равно уехали во "внешний столл".
	//
	// Усыпляющие виды (winget/winexists) пропускаем: они кольцо тоже наполняют, но мир не
	// морозят - это собственное ожидание прока, и виновником спайка быть не может.
	// Берём самую дорогую запись окна: если работ несколько, виноват крупнейший, а не первый.
	var/best_slow_work = 0
	var/best_slow_cost = 0
	for(var/i in slow_work_ring_chronological())
		var/work_time = slow_work_time[i]
		if(isnull(work_time) || work_time < tight_window_start)
			continue
		if(is_sleeping_blocking_kind(slow_work_kind[i]))
			continue
		var/work_cost = slow_work_cost[i]
		if(work_cost <= best_slow_cost)
			continue
		best_slow_cost = work_cost
		best_slow_work = i
	if(best_slow_work && drift && best_slow_cost >= drift * TICK_SPIKES_BLOCKING_COVERAGE)
		var/best_slow_kind = slow_work_kind[best_slow_work]
		last_classify_detail = " - [best_slow_kind]: [slow_work_desc[best_slow_work]], [round(best_slow_cost)]мс из [round(drift)]мс"
		// Синхронный блокирующий примитив (savefile/world.Export/SQL), пойманный кольцом, -
		// это тот же класс "блокирующий вызов": last_blocking_* хранит лишь ПОСЛЕДНИЙ вызов
		// и мог быть перебит более свежим и более дешёвым. Ключи blocking_by_kind - полный
		// список видов, которые вообще проходили через замер блокирующих примитивов.
		return (best_slow_kind in blocking_by_kind) ? TICK_SPIKE_CLASS_BLOCKING : TICK_SPIKE_CLASS_DM
	// Смотрим последние TICK_SPIKES_CLASSIFY_WINDOW_TICKS тика кольца: cpu отражает предыдущий тик
	var/max_cpu = spike_window_max(ring_cpu)
	var/max_map_cpu = spike_window_max(ring_map_cpu)
	// Решает ПРИРОСТ над фоном, а не абсолютное значение. Абсолютные пороги остались, но
	// строго как ЗАПАСНОЙ вариант - только когда фона ещё не набрано (первые тики раунда,
	// синтетика юнит-теста) и дельту считать не из чего. Как самостоятельное ИЛИ они вредны:
	// при фоне 90% порог 70 перешагивается одним фоном - спайк #17 раунда 9849 (cpu 96.3%
	// при фоне 90.5%, прирост всего +5.8 п.п.) так и был ошибочно назван DM-переработкой.
	var/cpu_baseline = ring_baseline_median(ring_cpu)
	var/map_baseline = ring_baseline_median(ring_map_cpu)
	var/cpu_delta = isnull(cpu_baseline) ? null : max_cpu - cpu_baseline
	var/map_delta = isnull(map_baseline) ? null : max_map_cpu - map_baseline
	// Цифры кладём в last_classify_detail, а не в саму строку класса: класс сравнивается
	// на точное равенство (решение об авто-дампе профайлера), и суффикс сломал бы это.
	var/dm_verdict = isnull(cpu_delta) ? (max_cpu >= TICK_SPIKES_CLASSIFY_CPU_THRESHOLD) : (cpu_delta >= TICK_SPIKES_CLASSIFY_CPU_DELTA)
	if(dm_verdict)
		last_classify_detail = " (cpu [format_cpu_delta(max_cpu, cpu_baseline, cpu_delta)])"
		return TICK_SPIKE_CLASS_DM
	var/sendmaps_verdict = isnull(map_delta) ? (max_map_cpu >= TICK_SPIKES_CLASSIFY_MAP_CPU_THRESHOLD) : (map_delta >= TICK_SPIKES_CLASSIFY_MAP_CPU_DELTA)
	if(sendmaps_verdict)
		last_classify_detail = " (map_cpu [format_cpu_delta(max_map_cpu, map_baseline, map_delta)])"
		return TICK_SPIKE_CLASS_SENDMAPS
	// Дрифт накоплен не за один межтиковый промежуток: МК несколько тиков не давал нам
	// фаериться. Это уже не "внешний столл", хотя выглядит точно так же - cpu не вырос.
	var/skipped = missed_fires()
	if(skipped >= TICK_SPIKES_MISSED_FIRES_FLOOR)
		last_classify_detail = " (пропущено фаеров: [skipped], шаг [round(last_step_ds, 0.01)]дс вместо [world.tick_lag]дс, то есть ~[round(drift / (skipped + 1))]мс на тик; cpu до [round(max_cpu, 0.1)]%, map_cpu до [round(max_map_cpu, 0.1)]%)"
		return TICK_SPIKE_CLASS_MISSED_FIRES
	last_classify_detail = " (cpu [format_cpu_delta(max_cpu, cpu_baseline, cpu_delta)], map_cpu до [round(max_map_cpu, 0.1)]%)"
	return TICK_SPIKE_CLASS_EXTERNAL

/// Хвост "X% при фоне Y% (прирост +Z п.п.)" для деталей классификации. Вынесен, чтобы
/// формулировка была одинаковой во всех классах и в блоке события.
/datum/controller/subsystem/tick_spikes/proc/format_cpu_delta(value, baseline, delta)
	if(isnull(baseline) || isnull(delta))
		return "до [round(value, 0.1)]%, фон неизвестен (мало замеров)"
	return "до [round(value, 0.1)]% при фоне [round(baseline, 0.1)]%, прирост [delta >= 0 ? "+" : ""][round(delta, 0.1)] п.п."

/**
 * Дельта Master.iteration с прошлого полного блока и дефицит итераций.
 *
 * Голое значение итерации в блоке не значило ничего. Полезно сравнение с числом прошедших
 * тиков: за тик МК проворачивает очередь один раз, и если итераций меньше, чем тиков,
 * значит очередь регулярно не влезала в тик. В раунде 9849 дефицит рос от 1-3% в начале
 * раунда до 9.5% в конце - готовый индикатор переработки очереди МК.
 *
 * ПОБОЧНЫЙ ЭФФЕКТ: запоминает текущие итерацию и время как базу для следующего блока.
 * Возвращает хвост к строке МК (пустой на первом блоке - сравнивать ещё не с чем).
 */
/datum/controller/subsystem/tick_spikes/proc/build_iteration_deficit(now_world)
	var/previous_iteration = last_spike_iteration
	var/previous_world = last_spike_world
	last_spike_iteration = Master.iteration
	last_spike_world = now_world
	if(!previous_iteration || !previous_world || world.tick_lag <= 0)
		return ""
	var/iterations_passed = Master.iteration - previous_iteration
	var/ticks_passed = round((now_world - previous_world) / world.tick_lag, 1)
	if(ticks_passed <= 0)
		return ""
	var/deficit = ticks_passed - iterations_passed
	return " (+[iterations_passed] за [ticks_passed] тиков, дефицит [deficit] = [round(deficit / ticks_passed * 100, 0.1)]%)"

/**
 * Строка "фактический прирост cpu против ожидаемого".
 *
 * Это и есть ответ словами на вопрос "работал ли DM внутри тика": если фактический прирост
 * много меньше ожидаемого, работы не было и тик просто стартовал позже - потеря снаружи DM.
 * Именно этой фразы не хватало человеку, читающему лог: голые проценты cpu он вынужден был
 * сравнивать с фоном вручную, глядя на таблицу последних тиков.
 */
/datum/controller/subsystem/tick_spikes/proc/build_cpu_expectation_line(drift)
	var/max_cpu = spike_window_max(ring_cpu)
	var/expected = expected_cpu_delta(drift)
	var/cpu_baseline = ring_baseline_median(ring_cpu)
	if(isnull(cpu_baseline))
		return "cpu: [round(max_cpu, 0.1)]%, фон неизвестен (мало замеров); ожидаемый прирост для DM-работы на [round(drift)]мс: +[round(expected, 0.1)] п.п."
	var/cpu_delta = max_cpu - cpu_baseline
	var/verdict = "работа внутри тика была, потеря объясняется ей"
	if(expected > 0 && cpu_delta < expected * TICK_SPIKES_CPU_SHORTFALL_RATIO)
		verdict = "работы внутри тика НЕ БЫЛО, тик просто стартовал позже - потеря снаружи DM"
	return "cpu: [round(max_cpu, 0.1)]% при фоне [round(cpu_baseline, 0.1)]% (медиана тиков -[TICK_SPIKES_BASELINE_OLDEST_TICK]..-[TICK_SPIKES_BASELINE_NEWEST_TICK]), прирост [cpu_delta >= 0 ? "+" : ""][round(cpu_delta, 0.1)] п.п. при ожидаемом +[round(expected, 0.1)] п.п. для DM-работы на [round(drift)]мс - [verdict]"

/// Строка о шаге игрового времени между замерами: один растянутый межтиковый промежуток
/// или несколько тиков, за которые МК нас ни разу не вызвал
/datum/controller/subsystem/tick_spikes/proc/build_step_line(drift)
	var/skipped = missed_fires()
	if(!skipped)
		return "шаг детектора: [round(last_step_ds, 0.01)]дс (= tick_lag), весь дрифт из одного межтикового промежутка"
	return "шаг детектора: [round(last_step_ds, 0.01)]дс вместо [world.tick_lag]дс - МК не дал фаериться [skipped] раз, дрифт [round(drift)]мс накоплен за [skipped + 1] тиков (~[round(drift / (skipped + 1))]мс на тик)"

/**
 * Размерные метрики для проверки версии "спайки от роста кучи". Все три - чтения длин.
 *
 * SSair.get_amt_gas_mixes() сюда намеренно НЕ входит: счётчик инкрементится в New(), а
 * декрементится только в Destroy(), который зовёт лишь qdel - транзитные смеси уходят
 * мягким GC без декремента. Счётчик монотонен по построению и уликой быть не может.
 */
/datum/controller/subsystem/tick_spikes/proc/build_size_metrics_line()
	var/gc_queues = "н/д"
	if(SSgarbage)
		var/list/gc_depths = list()
		for(var/level in 1 to GC_QUEUE_COUNT)
			gc_depths += SSgarbage.GetQueueDepth(level)
		gc_queues = gc_depths.Join("/")
	return "размеры: клиентов [length(GLOB.clients)], таймеров [length(SStimer?.timer_id_dict)], очередь GC [gc_queues], fps [world.fps], tick_lag [world.tick_lag]дс"

/**
 * Два числа sendmaps-профиля прямо в строку блока: кумулятивные value/calls и дельта с
 * прошлого блока.
 *
 * Файловых дампов на это не хватает: их бюджет (TICK_SPIKES_MAX_AUTO_DUMPS) выгорает за
 * первые десять минут раунда, и в 9849 34 блока из 49 остались вообще без артефакта.
 *
 * Частый вызов безопасен: PROFILE_REFRESH счётчики НЕ обнуляет. В референсе BYOND он
 * прямо назван синонимом PROFILE_START ("start/continue profiling but don't clear any
 * existing data"), обнуляют только PROFILE_CLEAR и PROFILE_RESTART, а их не зовёт никто.
 * Поэтому ни файловые дампы, ни равномерная сетка maybe_dump_periodic_profile не страдают.
 *
 * Возвращает готовую строку или null, если профиля нет (старый BYOND, юнит-тест, пустой ответ).
 */
/datum/controller/subsystem/tick_spikes/proc/build_sendmaps_line()
	if(suppress_side_effects)
		return null
#if DM_VERSION >= 515
	var/list/rows
	try
		rows = json_decode(world.Profile(PROFILE_REFRESH, type = "sendmaps", format = "json"))
	catch
		return null
	if(!length(rows))
		return null
	// Первая строка таблицы - суммарная ("SendMaps"), но полагаться на порядок не будем
	var/list/total_row
	for(var/list/row in rows)
		if(row["name"] == "SendMaps")
			total_row = row
			break
	if(isnull(total_row))
		return null
	var/value = total_row["value"]
	var/calls = total_row["calls"]
	if(isnull(value) || isnull(calls))
		return null
	var/tail = ""
	if(last_sendmaps_calls && calls > last_sendmaps_calls)
		var/delta_ms = (value - last_sendmaps_value) * 1000
		var/delta_calls = calls - last_sendmaps_calls
		tail = ", с прошлого блока +[round(delta_ms, 0.1)]мс за [delta_calls] вызовов (~[round(delta_ms / delta_calls, 0.01)]мс на вызов)"
	last_sendmaps_value = value
	last_sendmaps_calls = calls
	// num2text с 12 значащими: число вызовов за раунд перевалит за 1e6, а интерполяция
	// по умолчанию режет такие числа до шести значащих цифр и печатает "1.23457e+006"
	return "sendmaps: кумулятивно [round(value, 0.001)]с за [num2text(calls, 12)] вызовов[tail]"
#else
	return null
#endif

/// Фиксация события спайка: контекст, классификация, запись в лог, опциональный дамп профайлера
/datum/controller/subsystem/tick_spikes/proc/register_spike(drift, now_ms, now_world)
	session_spike_count++
	total_spike_drift_ms += drift
	if(drift > worst_drift_ms)
		worst_drift_ms = drift
		worst_drift_at = now_world

	var/tag_line = ""
	if(next_spike_tag)
		tag_line = " \[[next_spike_tag]]"
		next_spike_tag = null

	// Рейт-лимит полных блоков: статистика копится по всем спайкам, но полный контекст
	// пишется не чаще full_event_min_interval_ms, промежуточные - одной строкой.
	// Гейт по времени душит и мелочь, и крупняк одинаково, а крупняк как раз и нужен
	// с контекстом - поэтому от TICK_SPIKES_FULL_EVENT_DRIFT_FLOOR блок пишется всегда.
	if(drift < TICK_SPIKES_FULL_EVENT_DRIFT_FLOOR && last_full_event_ms && (now_ms - last_full_event_ms) < full_event_min_interval_ms)
		suppressed_event_count++
		var/brief_class = classify_spike(now_world, drift)
		write_to_log("СПАЙК #[session_spike_count][tag_line] (кратко) [time_stamp_from_world(now_world)] (wt [now_world]): дрифт [round(drift)]мс, [brief_class][last_classify_detail]")
		return
	last_full_event_ms = now_ms

	var/list/heavy_lines = collect_heavy_runs(now_world - TICK_SPIKES_HEAVY_WINDOW)
	var/spike_class = classify_spike(now_world, drift)

	var/list/event = list()
	event += "=== СПАЙК #[session_spike_count][tag_line] [time_stamp_from_world(now_world)] (wt [now_world]) ==="
	event += "дрифт: [round(drift)]мс (порог [spike_threshold_ms]мс), тик [world.tick_lag * 100]мс"
	event += "вероятный источник: [spike_class][last_classify_detail]"
	event += "клиентов: [length(GLOB.clients)], TD тек/быстр/сред: [round(SStime_track.time_dilation_current, 0.1)]% / [round(SStime_track.time_dilation_avg_fast, 0.1)]% / [round(SStime_track.time_dilation_avg, 0.1)]%"
	var/previous_heaviest = heaviest_run_previous_tick(now_world)
	// Считаем ДО сборки строки: прок запоминает базу для следующего блока, и прятать такой
	// побочный эффект внутрь интерполяции нельзя
	var/iteration_deficit = build_iteration_deficit(now_world)
	// sleep_delta ровно 1 значит, что МК себя виноватым не считает: он не растягивал сон,
	// то есть время потерялось помимо него. В раунде 9849 так было в 43 блоках из 49.
	var/sleep_delta_note = (Master.sleep_delta == 1) ? " (МК себя виноватым не считает)" : ""
	event += "МК: итерация [Master.iteration][iteration_deficit], sleep_delta [round(Master.sleep_delta, 0.01)][sleep_delta_note], skip_ticks [Master.skip_ticks], ticklimit [round(Master.current_ticklimit, 0.1)], самый тяжёлый прогон предыдущего тика: [previous_heaviest ? previous_heaviest : "нет (>=[heavy_run_threshold]% тика)"]"
	event += build_cpu_expectation_line(drift)
	event += build_step_line(drift)
	event += build_size_metrics_line()
	var/sendmaps_line = build_sendmaps_line()
	if(sendmaps_line)
		event += sendmaps_line

	if(length(heavy_lines))
		event += "тяжёлые прогоны подсистем за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек (wall-time: столл во время слота подсистемы выглядит как её прогон, сверяй с профайлером):"
		event += heavy_lines
	else
		event += "тяжёлых прогонов подсистем МК (>=[heavy_run_threshold]% тика) за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек не было"

	var/list/harddel_lines = collect_recent_harddels(now_world - TICK_SPIKES_HEAVY_WINDOW)
	if(length(harddel_lines))
		event += "хардделы за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек (одиночный дорогой del() - типовой виновник спайков в слоте Garbage):"
		event += harddel_lines

	var/list/slow_work_lines = collect_slow_work(now_world - TICK_SPIKES_HEAVY_WINDOW)
	if(length(slow_work_lines))
		event += "медленные единицы работы за последние [TICK_SPIKES_HEAVY_WINDOW / 10] сек (>=[slow_work_threshold_ms]мс - таймер-колбеки/вербы/Topic именуют DM вне МК, winget/winexists/savefile/world.Export именуют блокирующее ожидание, которое иначе выглядит как внешний столл):"
		event += slow_work_lines

	event += "последние тики (время | дрифт мс | usage% до МК | cpu% | map_cpu%):"
	var/window = min(TICK_SPIKES_REPORT_WINDOW, samples_collected)
	for(var/offset = window - 1, offset >= 0, offset--)
		var/idx = ring_pos - offset
		if(idx < 1)
			idx += TICK_SPIKES_HISTORY
		event += "  wt [ring_world_time[idx]] | [round(ring_drift[idx])] | [round(ring_usage_at_fire[idx], 0.1)] | [round(ring_cpu[idx], 0.1)] | [round(ring_map_cpu[idx], 0.1)]"

	var/profile_note = try_dump_profile(drift, now_ms, spike_class)
	if(profile_note)
		event += profile_note

	var/event_text = event.Join("\n")
	spike_events += event_text
	if(length(spike_events) > TICK_SPIKES_MAX_EVENTS)
		spike_events.Cut(1, 2)

	if(!suppress_side_effects)
		write_to_log("\n[event_text]\n")
		if(announce_to_admins && drift >= announce_threshold_ms && (!last_announce_ms || now_ms - last_announce_ms > announce_cooldown_ms))
			last_announce_ms = now_ms
			message_admins("Тик-спайк: [round(drift)]мс, источник: [spike_class]. Подробности: Debug -> Tick Spikes Report.")

/// Дамп окна профайлера на спайке (только при активном захвате). Возвращает строку для события или null.
/// Исключение: sendmaps-профиль работает всегда (см. PreInit), поэтому SendMaps-спайки
/// дампят его и БЕЗ сессии захвата - проковский профайлер их всё равно не объясняет.
/// То же для класса "внешний столл": в прод-раундах он собирает большую часть дрифта
/// (9832: 125 спайков из 210, 42 из 67 секунд), а классифицируется он именно тем, что
/// DM в тике почти не работал - значит проковский профайлер по нему пуст, и без
/// sendmaps-профиля самый крупный бак дрифта каждый раунд оставался без артефактов.
/datum/controller/subsystem/tick_spikes/proc/try_dump_profile(drift, now_ms, spike_class)
	if(suppress_side_effects)
		return null
	if(!capture_until || world.time > capture_until)
#if DM_VERSION >= 515
		var/auto_dumpable = (spike_class == TICK_SPIKE_CLASS_SENDMAPS) || (spike_class == TICK_SPIKE_CLASS_EXTERNAL)
		if(auto_dumpable && auto_dumps_done >= TICK_SPIKES_MAX_AUTO_DUMPS)
			return "sendmaps-профайл (авто) пропущен: исчерпан лимит [TICK_SPIKES_MAX_AUTO_DUMPS] дампов за раунд"
		if(auto_dumpable && (now_ms - last_profile_dump_ms >= profile_dump_cooldown_ms))
			last_profile_dump_ms = now_ms
			profile_dumps_done++
			profile_dump_seq++
			auto_dumps_done++
			self_inflicted_until = world.time + (TICK_SPIKES_SELF_INFLICTED_TICKS * world.tick_lag)
			// Имя разное, чтобы в каталоге логов было видно, какой класс спайка его породил.
			var/class_tag = (spike_class == TICK_SPIKE_CLASS_EXTERNAL) ? "external" : "sendmaps"
			var/auto_sendmaps_name = "tick_spike_[class_tag]_[profile_dump_seq].json"
			WRITE_FILE(file("[GLOB.log_directory]/[auto_sendmaps_name]"), world.Profile(PROFILE_REFRESH, type = "sendmaps", format = "json"))
			return "sendmaps-профайл (авто, без захвата) записан в [auto_sendmaps_name]"
#endif
		return null
	if(spike_class == TICK_SPIKE_CLASS_SELF)
		return "дамп профайлера пропущен: спайк вызван предыдущим дампом"
	if(now_ms - last_profile_dump_ms < profile_dump_cooldown_ms)
		return "дамп профайлера пропущен: кулдаун"
#if DM_BUILD < 1506
	return "дамп профайлера недоступен на этой версии BYOND"
#else
	last_profile_dump_ms = now_ms
	profile_dumps_done++
	profile_dump_seq++
	// Наш собственный дамп растянет следующий тик - не считать его новым спайком
	self_inflicted_until = world.time + (TICK_SPIKES_SELF_INFLICTED_TICKS * world.tick_lag)
	var/file_name = "tick_spike_profile_[profile_dump_seq].json"
	// PROFILE_REFRESH возвращает данные, но НЕ обнуляет их: снапшот кумулятивный с момента
	// старта профайлера. Окно между спайками = дифф соседних дампов (числа монотонные).
	WRITE_FILE(file("[GLOB.log_directory]/[file_name]"), world.Profile(PROFILE_REFRESH, format = "json"))
	. = "профайлер: кумулятивный снапшот записан в [file_name] (окно = дифф с предыдущим дампом)"
#if DM_VERSION >= 515
	if(spike_class == TICK_SPIKE_CLASS_SENDMAPS)
		var/sendmaps_name = "tick_spike_sendmaps_[profile_dump_seq].json"
		WRITE_FILE(file("[GLOB.log_directory]/[sendmaps_name]"), world.Profile(PROFILE_REFRESH, type = "sendmaps", format = "json"))
		. += "; sendmaps-профайл в [sendmaps_name]"
#endif
#endif

/**
 * Периодический дамп sendmaps-профиля по РАВНОМЕРНОЙ сетке, независимый от спайков.
 *
 * Счётчики профайлера кумулятивные, полезна только дельта соседних дампов - а она
 * имеет смысл лишь тогда, когда окна между дампами одинаковы. Спайковые дампы этому
 * условию не удовлетворяют: в раунде 9847 их бюджет (TICK_SPIKES_MAX_AUTO_DUMPS)
 * выгорел на десятой минуте, а интервалы между ними гуляли от 15 до 130 секунд.
 * Здесь свой шаг, свой бюджет и своё имя файла, чтобы не смешивать две сетки.
 */
/datum/controller/subsystem/tick_spikes/proc/maybe_dump_periodic_profile()
	if(suppress_side_effects)
		return
	if(world.time < next_periodic_dump_world)
		return
	next_periodic_dump_world = world.time + TICK_SPIKES_PERIODIC_DUMP_INTERVAL
	if(periodic_dumps_done >= TICK_SPIKES_MAX_PERIODIC_DUMPS)
		return
#if DM_VERSION >= 515
	periodic_dumps_done++
	periodic_dump_seq++
	// Наш собственный дамп растянет тик - не считать следующий тик новым спайком
	self_inflicted_until = world.time + (TICK_SPIKES_SELF_INFLICTED_TICKS * world.tick_lag)
	WRITE_FILE(file("[GLOB.log_directory]/tick_spike_periodic_[periodic_dump_seq].json"), world.Profile(PROFILE_REFRESH, type = "sendmaps", format = "json"))
#endif

/// Старт сессии захвата: включает профайлер и дампы его окон на спайках
/datum/controller/subsystem/tick_spikes/proc/start_capture(duration_ds, starter_key)
	capture_until = world.time + duration_ds
	profile_dumps_done = 0
	last_profile_dump_ms = 0
#if DM_BUILD >= 1506
	if(!CONFIG_GET(flag/auto_profile))
		SSprofiler.StartProfiling()
		started_profiler = TRUE
	// Намеренно НЕ обнуляем профайлер (PROFILE_RESTART): при включённом auto_profile это
	// сломало бы кумулятивный profiler.json от SSprofiler. Дампы диффятся оффлайн.
#endif
#if DM_VERSION >= 515
	world.Profile(PROFILE_START, type = "sendmaps")
#endif
	write_to_log("=== ЗАХВАТ ВКЛЮЧЁН [starter_key ? "([starter_key]) " : ""]на [duration_ds / 10] сек, до wt [capture_until] ===")

/// Остановка сессии захвата
/datum/controller/subsystem/tick_spikes/proc/stop_capture(automatic = FALSE, stopper_key)
	capture_until = 0
#if DM_BUILD >= 1506
	if(started_profiler && !CONFIG_GET(flag/auto_profile))
		SSprofiler.StopProfiling()
#endif
	// sendmaps-профиль НЕ останавливаем: он always-on с PreInit (нужен для
	// авто-дампов SendMaps-спайков вне сессий захвата)
	started_profiler = FALSE
	var/summary = "=== ЗАХВАТ ВЫКЛЮЧЕН [automatic ? "(по таймеру)" : "([stopper_key])"]: спайков за сессию [session_spike_count], дампов профайлера [profile_dumps_done] ==="
	write_to_log(summary)
	if(!suppress_side_effects)
		message_admins("Захват тик-спайков завершён: спайков [session_spike_count], худший [round(worst_drift_ms)]мс, дампов профайлера [profile_dumps_done]. Файлы в папке логов раунда.")

/// Итоговый текстовый отчёт для верба и для выгрузки мне
/datum/controller/subsystem/tick_spikes/proc/build_report()
	var/list/out = list()
	out += "===== SStick_spikes: отчёт ====="
	out += "время: [time_stamp_from_world(world.time)] (wt [world.time]), тик [world.tick_lag * 100]мс ([world.fps] fps)"
	out += "настройки: порог спайка [spike_threshold_ms]мс, порог тяжёлого прогона [heavy_run_threshold]% тика, анонс от [announce_threshold_ms]мс"
	out += "захват: [capture_until ? "АКТИВЕН до wt [capture_until]" : "выключен"], дампов профайлера: [profile_dumps_done]"
	out += "периодических дампов sendmaps: [periodic_dumps_done] из [TICK_SPIKES_MAX_PERIODIC_DUMPS] (шаг [TICK_SPIKES_PERIODIC_DUMP_INTERVAL / 10] сек, файлы tick_spike_periodic_N.json)"
	out += "клиентов: [length(GLOB.clients)], TD тек/быстр/сред/медл: [round(SStime_track.time_dilation_current, 0.1)]% / [round(SStime_track.time_dilation_avg_fast, 0.1)]% / [round(SStime_track.time_dilation_avg, 0.1)]% / [round(SStime_track.time_dilation_avg_slow, 0.1)]%"
	out += "тиков замерено: [samples_collected]"
	out += "спайков: [session_spike_count] (из них кратко в логе: [suppressed_event_count]), худший [round(worst_drift_ms)]мс в [worst_drift_at ? time_stamp_from_world(worst_drift_at) : "-"], суммарно потеряно в спайках ~[round(total_spike_drift_ms)]мс"
	out += "гистограмма дрифтов (мс): [TICK_SPIKES_HISTOGRAM_FLOOR]-[TICK_SPIKES_HISTOGRAM_BUCKET_1]: [drift_histogram[1]] | [TICK_SPIKES_HISTOGRAM_BUCKET_1]-[TICK_SPIKES_HISTOGRAM_BUCKET_2]: [drift_histogram[2]] | [TICK_SPIKES_HISTOGRAM_BUCKET_2]-[TICK_SPIKES_HISTOGRAM_BUCKET_3]: [drift_histogram[3]] | [TICK_SPIKES_HISTOGRAM_BUCKET_3]-[TICK_SPIKES_HISTOGRAM_BUCKET_4]: [drift_histogram[4]] | [TICK_SPIKES_HISTOGRAM_BUCKET_4]+: [drift_histogram[5]]"
	out += build_blocking_summary_lines()
	out += memory_probe_available \
		? "скачки памяти (порог [memory_jump_threshold_mb] МБ за [round(memory_sample_ticks * world.tick_lag * 100)]мс): [memory_jump_count] на [round(memory_jump_total_mb)] МБ, крупнейший [round(biggest_memory_jump_mb, 0.1)] МБ в [biggest_memory_jump_at ? time_stamp_from_world(biggest_memory_jump_at) : "-"], VmSize сейчас [round(last_vsz_mb)] МБ" \
		: "скачки памяти: не меряются (нет /proc/self/status - Windows или урезанный контейнер)"
	out += "лог событий: [log_path ? log_path : "ещё не создан"]"
	if(length(spike_events))
		out += ""
		out += "----- события ([length(spike_events)] последних) -----"
		for(var/event_text in spike_events)
			out += ""
			out += event_text
	else
		out += "событий пока нет"
	return out.Join("\n")

/**
 * Итог по блокирующим вызовам за раунд, ДВУМЯ независимыми группами.
 *
 * Это ответ на вопрос "куда делось время, которого не видит ни профайлер, ни world.cpu".
 * Но складывать усыпляющие вызовы с синхронными нельзя: первые не отнимают у мира
 * ничего (пока прок спит в winget, МК крутится дальше), вторые морозят процесс целиком.
 * Общий итог давал в раунде 9847 строку "= 3725% суммарного дрифта спайков" - число,
 * которое не значит ровным счётом ничего. Долю от дрифта считаем только по синхронным.
 *
 * Возвращает список строк: каждая уходит в лог отдельно, со своим таймстампом.
 */
/datum/controller/subsystem/tick_spikes/proc/build_blocking_summary_lines()
	if(!blocking_calls)
		return list("блокирующие вызовы: замеров нет")
	var/list/sleeping_parts = list()
	var/list/sync_parts = list()
	for(var/kind in blocking_by_kind)
		var/list/bucket = blocking_by_kind[kind]
		var/part = "[kind] x[bucket["count"]]: [round(bucket["ms"])]мс (макс [round(bucket["max"])]мс)"
		if(is_sleeping_blocking_kind(kind))
			sleeping_parts += part
		else
			sync_parts += part
	var/sleeping_tail = ""
	if(length(sleeping_parts))
		sleeping_tail = " | [sleeping_parts.Join(" | ")]"
	var/sync_tail = ""
	if(length(sync_parts))
		sync_tail = " | [sync_parts.Join(" | ")]"
	var/share = ""
	if(total_spike_drift_ms)
		share = " = [round(blocking_sync_ms / total_spike_drift_ms * 100)]% суммарного дрифта спайков"
	var/list/lines = list()
	lines += "блокирующие вызовы, ожидание прока (усыпляют вызывающего, миру НЕ мешают - МК крутится дальше, дрифту не соответствуют): [blocking_sleeping_calls] на [round(blocking_sleeping_ms)]мс[sleeping_tail]"
	lines += "блокирующие вызовы, синхронные (морозят весь процесс): [blocking_sync_calls] на [round(blocking_sync_ms)]мс[share][sync_tail]"
	return lines

/// Тот же итог одной строкой (для отчёта верба и для юнит-теста)
/datum/controller/subsystem/tick_spikes/proc/build_blocking_summary()
	var/list/lines = build_blocking_summary_lines()
	return lines.Join("\n")

/datum/controller/subsystem/tick_spikes/proc/write_to_log(text)
	if(suppress_side_effects)
		return
	if(!log_path)
		log_path = "[GLOB.log_directory]/tick_spikes.log"
	WRITE_LOG_NO_FORMAT(log_path, "[text]\n")

#undef TICK_SPIKES_HISTORY
#undef TICK_SPIKES_HEAVY_HISTORY
#undef TICK_SPIKES_SLOW_WORK_HISTORY
#undef TICK_SPIKES_REPORT_WINDOW
#undef TICK_SPIKES_HEAVY_WINDOW
#undef TICK_SPIKES_CLOCK
#undef TICK_SPIKES_MAX_EVENTS
#undef TICK_SPIKES_HISTOGRAM_FLOOR
#undef TICK_SPIKES_HISTOGRAM_BUCKET_1
#undef TICK_SPIKES_HISTOGRAM_BUCKET_2
#undef TICK_SPIKES_HISTOGRAM_BUCKET_3
#undef TICK_SPIKES_HISTOGRAM_BUCKET_4
#undef TICK_SPIKES_CLASSIFY_WINDOW_TICKS
#undef TICK_SPIKES_CLASSIFY_CPU_DELTA
#undef TICK_SPIKES_CLASSIFY_MAP_CPU_DELTA
#undef TICK_SPIKES_CLASSIFY_CPU_THRESHOLD
#undef TICK_SPIKES_CLASSIFY_MAP_CPU_THRESHOLD
#undef TICK_SPIKES_BASELINE_OLDEST_TICK
#undef TICK_SPIKES_BASELINE_NEWEST_TICK
#undef TICK_SPIKES_CPU_SMOOTHING_TICKS
#undef TICK_SPIKES_CPU_SHORTFALL_RATIO
#undef TICK_SPIKES_MISSED_FIRES_FLOOR
#undef TICK_SPIKES_SELF_INFLICTED_TICKS
#undef TICK_SPIKES_BLOCKING_COVERAGE
#undef TICK_SPIKES_BLOCKING_SUMMARY_INTERVAL
#undef TICK_SPIKES_MAX_AUTO_DUMPS
#undef TICK_SPIKES_PERIODIC_DUMP_INTERVAL
#undef TICK_SPIKES_MAX_PERIODIC_DUMPS
#undef TICK_SPIKES_FULL_EVENT_DRIFT_FLOOR
#undef TICK_SPIKES_MEMORY_SAMPLE_TICKS
#undef TICK_SPIKES_MEMORY_JUMP_MB
#undef TICK_SPIKES_MAX_MEMORY_EVENTS
#undef TICK_SPIKES_MEMORY_BYTES_PER_INSTANCE_CEILING
#undef TICK_SPIKE_CLASS_MC
#undef TICK_SPIKE_CLASS_DM
#undef TICK_SPIKE_CLASS_SENDMAPS
#undef TICK_SPIKE_CLASS_EXTERNAL
#undef TICK_SPIKE_CLASS_MISSED_FIRES
#undef TICK_SPIKE_CLASS_SELF
#undef TICK_SPIKE_CLASS_BLOCKING
