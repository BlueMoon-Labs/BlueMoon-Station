/// Write ping diagnostics every 60 seconds under normal conditions.
#define PING_PERF_LOG_EVERY_TICKS 120
/// Always flush diagnostics early when RTT spikes above this threshold.
#define PING_PERF_SPIKE_RTT_MS 20
/// Always flush diagnostics early when raw glide jitter is unusually high.
#define PING_PERF_SPIKE_JITTER_PCT 8
/// Always flush diagnostics early on visible tick dilation spikes.
#define PING_PERF_SPIKE_TIDI_PCT 5

/// Какую долю потолка адресного пространства процесс может занять молча.
///
/// Планка работает вместе с полом "базовый уровень раунда плюс ступень", и на тяжёлых
/// картах побеждает именно пол: MetaStation в раунде 10020 устоялась на 3134 МБ при потолке
/// 4088, то есть на 77% потолка сразу после старта. Любая доля ниже этой означала бы строку
/// в логе на первой минуте каждого раунда - строку, которая не сообщает ничего.
#define MEMORY_WARN_CEILING_FRACTION 0.6
/// Порог, когда потолок замерить не удалось. DreamDaemon 32-битный всегда, так что потолок - от трёх до четырёх гигабайт.
#define MEMORY_WARN_FALLBACK_MB 2048
/// Следующее предупреждение - не раньше, чем ещё через столько мегабайт: иначе раз перешагнувший порог процесс пишет строку каждые десять секунд до конца раунда.
///
/// Ступень обязана быть МЕНЬШЕ того, на сколько раунд реально вырастает, иначе первая же
/// ступень оказывается за пределами его жизни и лестница молчит всегда. Прежние 256 МБ
/// этому не удовлетворяли: логи 28.08.2026 дают четыре раунда, и ступень напечаталась
/// ровно в одном.
/// * 10133: база 2320.4 МБ, потолок 4092, первая ступень 2576.4 - за все 24 минуты раунд
///   дошёл до 2547.3 и не дотянулся 29 МБ. Ни строки, ни переписи. (Раунд не падал, его
///   перезапустили руками под деплой; цифра - просто верх его роста.)
/// * 10134: база 2577 МБ, первая ступень 2833 - за 42 минуты дошёл до 2725, не дотянулся 108.
/// * 10132: раунд длиной 11 минут, до ступени не дожил.
/// * 10131: база 2228.9, ступень 2484.9 - единственный раунд, где лестница заговорила, и он
///   же единственный, который прожил пять с половиной часов.
///
/// 96 МБ измеряются по тем же логам: короткий раунд вырастает на 150-230 МБ, значит на этом
/// пробеге умещается две ступени плюс запас, и перепись приходит тогда, когда есть что
/// сравнивать. Спама это не даёт - порог переезжает от ТЕКУЩЕГО значения, а не от прежнего
/// порога, поэтому между строками процесс обязан вырасти ещё на ступень: при боевых
/// 12.8 МБ/мин это одна строка в семь с половиной минут.
#define MEMORY_WARN_STEP_MB 96

/// За сколько расчётных минут до упора в потолок уходит ЕДИНСТВЕННОЕ за раунд сообщение админам.
///
/// Триггер по времени, а не по доле потолка, намеренно. Сделать с адресным пространством
/// админ может ровно одно - увести раунд на рестарт раньше, чем процесс умрёт сам, - и для
/// этого решения нужна не доля, а срок. Доля же на нашей карте набирается почти сразу:
/// в раунде 10020 планка 0.8 была перейдена на восьмой минуте раунда, которому оставалось
/// жить ещё около сорока. Предупреждение, приходящее каждый раунд сразу после старта,
/// админы перестают читать за неделю.
#define MEMORY_ADMIN_WARN_LEAD_MINUTES 20
/// Сколько МБ до потолка считается последним рубежом: тут админам пишем независимо от расчёта.
///
/// Страховка на ступеньку, и потому величина абсолютная, а не доля потолка. Опасность здесь
/// создаёт одно выделение целиком: созданный z-уровень со светом стоит 150-250 МБ и приходит
/// за один-два сэмпла (раунд 10023, гейтвей: +140 МБ за сорок секунд). Триста мегабайт - это
/// запас на одну такую ступеньку с небольшим хвостом.
///
/// Долей эту планку держать нельзя. На картах, где раунд стартует с 86% потолка (Delta,
/// раунд 10023), любая доля порядка 0.9 срабатывает через четверть часа каждый раунд, и
/// предупреждение, приходящее всегда, админы перестают читать. Разбор четырёх раундов
/// 19.08.2026 по этой планке: 10021 (3155 МБ) молчит, 10022 (3724) молчит и доживает до
/// штатного рестарта, 10020 (3858) и 10023 (3796) предупреждают - и оба были в опасности.
#define MEMORY_ADMIN_WARN_HEADROOM_MB 300
/// То же для случая, когда потолок замерить не удалось: планка ставится руками.
#define MEMORY_ADMIN_WARN_FALLBACK_MB 2560

/// По какому окну считается скорость роста памяти.
///
/// Полчаса, и это не осторожность, а единственная защита от ступенек: одиночное выделение
/// в 140 МБ на пятиминутном окне читается как 28 МБ/мин и обещает смерть через десять минут
/// (раунд 10023, гейтвей), на получасовом - как 4.7 МБ/мин. Короче брать нельзя, длиннее
/// незачем: на настоящей быстрой утечке в десятки МБ/мин полчаса запаздывания стоят полутора
/// гигабайт, а столько у раунда нет.
///
/// Робастную оценку вместо длинного окна пробовали и откатили, см. комментарий у
/// memory_growth_rate_mb_per_minute(): рост идёт ступеньками весь раунд, и устойчивая
/// к ступенькам статистика отвечает нулём.
#define MEMORY_RATE_WINDOW (30 MINUTES)
/// С какого разбега между краями окна скорость вообще отдаётся.
///
/// Окно набирается с нуля после взятия базового уровня, и ждать все полчаса до первой цифры
/// нельзя: утечка в полсотни МБ/мин съест за это время полтора гигабайта. Десять минут -
/// компромисс: ступенька в 140 МБ на них даёт 14 МБ/мин, чего при живом запасе в гигабайт
/// на ложную тревогу не хватает.
#define MEMORY_RATE_MIN_SPAN (10 MINUTES)

/// Сколько раунд отстаивается после старта, прежде чем с него снимут базовый уровень.
#define MEMORY_BASELINE_SETTLE_TIME (2 MINUTES)
/// Запасной срок на случай, если раунд так и не начался: базовый уровень нужен и в лобби.
#define MEMORY_BASELINE_FALLBACK_TIME (6 MINUTES)

/// Перепись инстансов - не чаще, чем раз в столько: перебор world.contents стоит дорого.
#define MEMORY_CENSUS_COOLDOWN (5 MINUTES)
/// Сколько типов выписывать в перепись.
#define MEMORY_CENSUS_TOP 15
/// Сколько z-уровней выписывать в разрез переписи по уровням. Их всего восемнадцать, и хвост из пустых уровней в логе не нужен.
#define MEMORY_CENSUS_TOP_Z 6
/// Через сколько элементов перебора сверяться с бюджетом тика.
///
/// Не на каждом шаге: CHECK_TICK читает world.tick_usage, и на полутора миллионах
/// элементов эта сверка стоит заметной доли всего перебора. Пятьсот с лишним дешёвых
/// шагов между сверками тик не переполнят - тело цикла состоит из двух проверок типа
/// и одного инкремента в assoc-списке.
#define MEMORY_CENSUS_TICK_EVERY 512
/// Сколько инстансов каждого типа разбирается по переменным ради длины списков.
///
/// Выборка, а не сплошной проход: обойти vars у полутора миллионов атомов - это триста
/// миллионов обращений к ассоциативному списку, дороже всей остальной переписи на два
/// порядка. Расслоение по типам делает выборку осмысленной: внутри одного типа списки
/// устроены одинаково, и трёх штук хватает, чтобы узнать средний размер. Смещение у
/// выборки есть - в неё попадают ПЕРВЫЕ встреченные инстансы типа, то есть выложенные
/// картой, а не нажитые раундом; для типов, где эти две группы различаются, оценка врёт
/// в меньшую сторону.
#define MEMORY_CENSUS_LIST_SAMPLES 3
/// До какой длины список разворачивается ради вложенного уровня. См. list_slots_deep().
#define MEMORY_CENSUS_NESTED_SCAN_CAP 64

SUBSYSTEM_DEF(time_track)
	name = "Time Tracking"
	wait = 5
	flags = SS_NO_TICK_CHECK
	init_order = INIT_ORDER_TIMETRACK
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/time_dilation_current = 0

	var/time_dilation_avg_fast = 0
	var/time_dilation_avg = 0
	var/time_dilation_avg_slow = 0

	var/first_run = TRUE

	/// Last realtime value used for per-fire raw multiplier tracking.
	var/last_raw_realtime = 0
	/// Last byond world.time used for per-fire raw multiplier tracking.
	var/last_raw_byond_time = 0

	var/last_tick_realtime = 0
	var/last_tick_byond_time = 0
	var/last_tick_tickcount = 0

	var/raw_multiplier_last = 1
	var/raw_multiplier_jitter_abs_last = 0
	var/raw_multiplier_jitter_abs_avg = 0
	var/raw_multiplier_jitter_abs_max_window = 0
	var/glide_size_multiplier_current = 1
	/// Сглаженное состояние множителя glide, до снапа к единице. Хранится
	/// отдельно от опубликованного: снап в обратной связи съел бы любую
	/// просадку мельче десяти процентов. См. movement_glide_publish().
	var/glide_size_multiplier_smoothed = 1

	/// Потолок адресного пространства процесса в МБ. Замеряется один раз: /proc/self/maps дорогой.
	var/process_address_ceiling_mb = PROCESS_ADDRESS_CEILING_UNKNOWN
	/// Установившийся VmSize раунда в МБ. Ноль - базовый уровень ещё не снят, см. take_memory_baseline().
	var/memory_baseline_mb = 0
	/// Уровень снят до старта раунда и будет пересмотрен, когда раунд начнётся и отстоится.
	var/memory_baseline_provisional = FALSE
	/// VmSize в МБ, начиная с которого пишем в лог мира. Растёт ступенями, см. MEMORY_WARN_STEP_MB.
	var/memory_warn_at_mb = 0
	/// Единственное за раунд сообщение админам уже ушло.
	var/memory_admin_warned = FALSE
	/// world.time первого замера памяти: от него отсчитывается запасной срок взятия базового уровня.
	var/memory_first_sample_at = 0
	/// Окно замеров для оценки скорости роста: моменты и значения VmSize отдельными списками.
	/// Два списка, а не список пар - так окно уходит в memory_growth_rate_mb_per_minute() как есть.
	var/list/memory_sample_times = list()
	var/list/memory_sample_vsz = list()
	/// Скорость роста VmSize, МБ/мин по окну. Ноль - окно ещё короче MEMORY_RATE_MIN_SPAN.
	var/memory_growth_mb_per_minute = 0
	/// VmSize последнего замера в МБ. Ноль - память не меряется (Windows) либо замеров ещё
	/// не было. Отдельным варом, а не хвостом memory_sample_vsz: окно скорости чистится по
	/// времени и на длинной паузе МК пустеет целиком, а давление спрашивают из чужих
	/// подсистем, которым пустое окно ничего не должно говорить. См. memory_pressure_fraction().
	var/memory_last_vsz_mb = 0
	/// Прошлая перепись инстансов: тип -> количество. Нужна ради разницы, а не итога.
	var/list/memory_census_previous
	/// world.time последней переписи.
	var/memory_census_at = 0
	/// Сколько списков за проход переписи пришлось разворачивать по выборке, а не считать
	/// целиком (длиннее MEMORY_CENSUS_NESTED_SCAN_CAP). Печатается в строке личных списков:
	/// молча выдавать оценку за замер прибор не должен. Обнуляется на каждом проходе.
	var/census_lists_extrapolated = 0
	/// Итог элементов личных списков по ВСЕМУ миру за последний проход. Без него строка
	/// личных списков отдавала топ-15 и ничего больше, и баланс памяти по ней не сводился -
	/// в отличие от строк общих и глобальных списков, где итог был с самого начала.
	var/census_personal_slots_total = 0

	var/ping_samples = 0
	var/ping_rtt_last_avg = 0
	/// Медиана последних RTT по миру. Среднее тянет вверх любой одиночный клиент с плохим
	/// каналом, поэтому "типичный пинг" читать надо отсюда.
	var/ping_rtt_last_median = 0
	var/ping_rtt_last_max = 0
	/// Максимум серверной доли пинга, накопленный между строками CSV.
	/// rtt_last_max читают как задержку сервера, а это максимум по худшему клиенту
	/// мира: на проде rtt_last_max/tick_last_max = 1.005, то есть многосекундные
	/// хвосты там целиком чужая сеть. Эта колонка - про нас и только про нас.
	var/ping_server_max_window = 0
	var/ping_rtt_avg_avg = 0
	var/ping_tick_last_avg = 0
	var/ping_tick_last_max = 0
	var/ping_server_last_avg = 0
	var/ping_server_last_max = 0
	var/ping_server_avg_avg = 0

/datum/controller/subsystem/time_track/Initialize(start_timeofday)
	. = ..()
	GLOB.perf_log = "[GLOB.log_directory]/perf-[GLOB.round_id ? GLOB.round_id : "NULL"]-[SSmapping.config?.map_name].csv"
	GLOB.ping_perf_log = "[GLOB.log_directory]/ping-perf-[GLOB.round_id ? GLOB.round_id : "NULL"]-[SSmapping.config?.map_name].csv"
	log_process_memory_environment()
	// Про колонку num_timers: это НЕ население колеса таймеров, а только те таймеры,
	// у кого выставлен TIMER_STOPPABLE - timer_id_dict заполняется исключительно для
	// них (см. /datum/timedevent/New в timer.dm). Мудлеты, барки, flick_overlay и
	// амбиент в неё не попадают вообще. Колонку не убираем, по ней сравнивают с
	// историей прошлых раундов, но реальное население смотреть надо в соседних:
	// timer_buckets (bucket_count), timer_second_queue, timer_clienttime, timer_hashes.
	log_perf(perf_log_header())
	log_ping_perf(
		list(
			"time",
			"players",
			"ping_samples",
			"rtt_last_avg",
			"rtt_last_median",
			"rtt_last_max",
			"rtt_avg_avg",
			"tick_last_avg",
			"tick_last_max",
			"server_last_avg",
			"server_last_max",
			"server_avg_avg",
			"server_maint_cleanup_last_ms",
			"server_maint_cleanup_avg_ms",
			"server_maint_cleanup_target",
			"time_dilation_current",
			"maptick",
			"raw_multiplier_last",
			"raw_jitter_abs_last",
			"raw_jitter_abs_avg",
			"raw_jitter_abs_max_window",
			"server_max_window",
			"glide_size_multiplier_current",
		)
	)

/**
 * Разовая запись об окружении процесса в dd.log: потолок адресного пространства, версия
 * BYOND, память хоста и наша память на этот момент.
 *
 * Потолок здесь - главное. DreamDaemon 32-битный (64-битных сборок BYOND не выпускает),
 * так что упереться в потолок раунд может всегда; вопрос в том, где он - около трёх
 * гигабайт при классическом сплите ядра или почти четыре на 64-битном ядре. От этого
 * зависит, тревожны ли два с половиной занятых гигабайта или это ещё запас.
 *
 * А вот величину памяти из этой строки НЕЛЬЗЯ читать как старт раунда, и порогов от неё
 * тоже не считается. SStime_track инициализируется на INIT_ORDER_TIMETRACK (47): после
 * SSmapping (50), но до SSatoms (30), света, сглаживания иконок и ассетов. Это середина
 * инициализации: в раунде 10020 здесь напечаталось 1169 МБ при установившемся уровне
 * раунда 3134 МБ, и всякий, кто сравнил бы рост с этой цифрой, насчитал бы утечку вдвое
 * больше настоящей. Установившийся уровень снимает take_memory_baseline() отдельной строкой.
 */
/datum/controller/subsystem/time_track/proc/log_process_memory_environment()
	var/list/memory = get_process_memory_mb()
	if(!memory)
		log_world("## MEMORY: замер памяти процесса недоступен (system_type=[world.system_type]), колонки mem_* в perf-логе останутся пустыми")
		return

	process_address_ceiling_mb = get_process_address_ceiling_mb()
	var/list/host_memory = get_host_memory_mb()
	log_world("## MEMORY: BYOND [world.byond_version].[world.byond_build], потолок адресного пространства \
		[process_address_ceiling_mb ? "[process_address_ceiling_mb] МБ" : "замерить не удалось"], \
		на середине инициализации VmSize [memory["vsz"]] МБ / VmRSS [memory["rss"]] МБ \
		(это НЕ старт раунда, пороги ставятся по установившемуся уровню), \
		хост [host_memory ? "[host_memory["available"]] из [host_memory["total"]] МБ свободно" : "не опрошен"], \
		объектов [num2text(world.contents.len, 12)] на [world.maxz] z-уровнях")
	log_world(world_new_entry_memory_line(GLOB.world_new_entry_vsz_mb, memory["vsz"]))

/**
 * Сколько адресного пространства мир занял ДО первой строки DM.
 *
 * Это .dmb, типовые таблицы и инициализация глобальных переменных DM - всё, что происходит
 * до /world/New(). По внешнему стенду раунда 10108 - 696 МБ, около четверти базы, и это
 * самый крупный неразобранный кусок памяти: поставить метку раньше /world/New() в DM негде,
 * поэтому цифра до сих пор существовала только как замер стенда на Windows и ни разу не
 * снималась на проде.
 *
 * Отдельным проком, потому что без живого процесса иначе не проверить, что деление на две
 * половины сходится: сумма "до DM" и "инициализация" обязана давать середину инициализации.
 */
/proc/world_new_entry_memory_line(entry_vsz_mb, current_vsz_mb)
	if(isnull(entry_vsz_mb))
		return "## MEMORY: VmSize на входе в /world/New() не замерен - разложить базу на \".dmb и глобалки\" и \"инициализацию\" нечем"
	var/init_spent = round(current_vsz_mb - entry_vsz_mb, 0.1)
	return "## MEMORY: до первой строки DM (.dmb, типовые таблицы, глобалки) [entry_vsz_mb] МБ; \
		инициализация к этой отметке добавила [init_spent] МБ"

/**
 * Пора ли снимать базовый уровень раунда.
 *
 * Ждём, пока мир отстоится: на роундстарте память прыгает на гигабайт за полторы минуты
 * (в раунде 10020: 2144 МБ на первом замере, 3134 МБ через полторы), и уровень, снятый
 * в этом окне, не значит ничего. Отсчёт идёт от старта раунда, а не от начала мира,
 * потому что тянет память именно старт - спаун игроков, свет, ассеты.
 *
 * Запасной срок нужен раундам, которые не начались: лобби живёт часами, память в нём
 * тоже растёт, и остаться в нём вовсе без порогов нельзя.
 */
/datum/controller/subsystem/time_track/proc/memory_baseline_due()
	// Именно РАВЕНСТВО, а не >=. GAME_STATE_FINISHED больше GAME_STATE_PLAYING, и раунд,
	// кончившийся внутри окна отстаивания, отдавал уровень, снятый посреди обработки конца
	// раунда - фотографии манифеста, итоговые отчёты, генерация иконок. В раунде 10098
	// (кончился через 14 секунд после старта) это напечатало 3164 МБ, то есть 77% потолка,
	// вместо реальных ~2600, и подняло лестницу до 3420 МБ. Числа-мусора в логе, от
	// которого потом считают пороги, быть не должно.
	if(SSticker?.current_state == GAME_STATE_PLAYING && SSticker.round_start_time)
		if(world.time < SSticker.round_start_time + MEMORY_BASELINE_SETTLE_TIME)
			return FALSE
		// Уровень, снятый в лобби, здесь пересматривается. Лобби бывает длинным, и
		// предварительный уровень тогда снимается с пустого мира; роундстарт после него
		// выглядит утечкой на гигабайт, хотя это обычный спаун станции.
		return memory_baseline_provisional || !memory_baseline_mb
	return !memory_baseline_mb && world.time >= memory_first_sample_at + MEMORY_BASELINE_FALLBACK_TIME

/**
 * Установившийся уровень памяти раунда: от него считаются пороги и с ним сравнивают рост.
 *
 * Порог лестницы - максимум из доли потолка и "этот уровень плюс ступень". Второе слагаемое
 * и есть смысл всей процедуры: на тяжёлой карте раунд стартует выше любой разумной доли
 * потолка (MetaStation - 77% сразу), и порог, посчитанный только от потолка, срабатывал бы
 * на первой минуте каждого раунда, не сообщая ничего. Порог от установившегося уровня
 * срабатывает тогда, когда память ушла выше того, с чего раунд начался, - то есть на росте.
 */
/datum/controller/subsystem/time_track/proc/take_memory_baseline(vsz, list/host_memory)
	memory_baseline_mb = vsz
	memory_baseline_provisional = SSticker?.current_state != GAME_STATE_PLAYING
	// Окно скорости роста начинается здесь заново. Останься в нём замеры роундстарта,
	// первая же оценка получила бы сотни МБ/мин, прогноз дал бы пару минут до потолка,
	// и админам ушла бы ложная тревога - ровно на том раунде, который ничем не болен.
	memory_sample_times.Cut()
	memory_sample_vsz.Cut()
	memory_growth_mb_per_minute = 0
	memory_warn_at_mb = max(vsz + MEMORY_WARN_STEP_MB, process_address_ceiling_mb \
		? round(process_address_ceiling_mb * MEMORY_WARN_CEILING_FRACTION) \
		: MEMORY_WARN_FALLBACK_MB)
	var/level_label = "базовый"
	if(memory_baseline_provisional)
		level_label = SSticker?.current_state > GAME_STATE_PLAYING \
			? "предварительный (раунд уже закончился, замер захватил обработку конца раунда)" \
			: "предварительный (раунд ещё не начался)"
	log_world("## MEMORY: [level_label] уровень раунда VmSize [vsz] МБ\
		[process_address_ceiling_mb ? " ([round(vsz / process_address_ceiling_mb * 100)]% потолка в [process_address_ceiling_mb] МБ)" : ""], \
		объектов [num2text(world.contents.len, 12)] на [world.maxz] z-уровнях, \
		хост [host_memory ? "[host_memory["available"]] из [host_memory["total"]] МБ свободно" : "не опрошен"]; \
		лестница в лог с [memory_warn_at_mb] МБ, админам - за [MEMORY_ADMIN_WARN_LEAD_MINUTES] расчётных минут до потолка")
	// Перепись прямо на базовом уровне, а не только на ступенях лестницы. Без неё первая
	// ступень отдаёт абсолютный снимок, и вопрос "что накопилось за раунд" остаётся без
	// ответа до второй ступени - то есть ещё +256 МБ спустя, которых у раунда может и не
	// быть. С ней первая же ступень отдаёт разницу с картой на старте.
	//
	// Предварительный уровень переписи не заказывает: снимок пустого лобби не описывает
	// ни карту, ни раунд, а вот отсчётной точкой для следующей переписи стал бы - и первая
	// ступень отчиталась бы приростом на весь роундстарт.
	if(!memory_baseline_provisional)
		request_instance_census()

/**
 * Обновляет медленную половину чёрного ящика МК - величины, которые незачем пересчитывать каждый тик.
 *
 * Зовётся оттуда же, откуда берётся проба памяти, то есть раз в десять секунд, поэтому несёт
 * собственную отметку времени: по разнице с первой строкой сводки видно, насколько контекст
 * отстал от момента обрыва.
 */
/datum/controller/subsystem/time_track/proc/refresh_mc_state_context(list/memory, gc_queue_depth)
	if(!Master)
		return
	var/vsz = memory ? memory["vsz"] : null
	var/ceiling = process_address_ceiling_mb || "?"
	Master.state_snapshot_context = "контекст на [SQLtime()]: память [vsz || "?"]/[ceiling] МБ, рост [round(memory_growth_mb_per_minute, 0.1)] МБ/мин | клиентов [length(GLOB.clients)] | дилатация [round(time_dilation_avg_fast, 0.1)]% | очередь GC [gc_queue_depth]"

/**
 * Один замер памяти: окно скорости, базовый уровень, лестница в лог, сообщение админам.
 *
 * Зовётся из fire() раз в десять секунд - чаще незачем, дороже не стоит.
 */
/datum/controller/subsystem/time_track/proc/track_process_memory(list/memory, list/host_memory)
	var/vsz = memory["vsz"]
	if(!memory_first_sample_at)
		memory_first_sample_at = world.time
	memory_last_vsz_mb = vsz

	memory_sample_times += world.time
	memory_sample_vsz += vsz
	// Окно задано временем, а не числом замеров. Замеры берёт fire() подсистемы, и на
	// просевшем МК шаг между ними растягивается: тридцать замеров означали бы то полчаса,
	// то полтора, а скорость роста - величина в минутах, и окно у неё обязано быть в минутах.
	var/window_starts_at = world.time - MEMORY_RATE_WINDOW
	var/stale = 0
	for(var/index in 1 to length(memory_sample_times))
		if(memory_sample_times[index] >= window_starts_at)
			break
		stale = index
	if(stale)
		memory_sample_times.Cut(1, stale + 1)
		memory_sample_vsz.Cut(1, stale + 1)
	memory_growth_mb_per_minute = memory_growth_rate_mb_per_minute(memory_sample_times, memory_sample_vsz, MEMORY_RATE_MIN_SPAN)

	// Админский порог проверяется до базового уровня: если мир стартовал уже под потолком,
	// ждать, пока раунд отстоится, незачем - его может не стать раньше.
	check_memory_admin_warning(vsz, host_memory)
	// Ступени конца раунда по памяти идут следом за предупреждением и по тем же цифрам:
	// сообщение админам без действия раунд 10105 не спасло.
	check_memory_pressure_endgame(vsz)

	if(memory_baseline_due())
		take_memory_baseline(vsz, host_memory)
	if(!memory_baseline_mb)
		return

	if(memory_warn_at_mb && vsz >= memory_warn_at_mb)
		log_memory_ladder_step(memory, host_memory)
		memory_warn_at_mb = vsz + MEMORY_WARN_STEP_MB

/**
 * Ступень лестницы в dd.log плюс заказ переписи инстансов.
 *
 * Строка отвечает на три вопроса разом: сколько занято, куда это ушло (куча против
 * отображённых файлов) и сколько времени осталось при нынешней скорости.
 */
/datum/controller/subsystem/time_track/proc/log_memory_ladder_step(list/memory, list/host_memory)
	// Пик и RSS дописываются только когда ядро их назвало: с тех пор как снимок отдаёт
	// пропуск вместо нуля, безусловная интерполяция дала бы "пик VmSize  МБ" с дыркой.
	var/warning = "процесс занял [memory["vsz"]] МБ адресного пространства"
	if(!isnull(memory["rss"]))
		warning += " (RSS [memory["rss"]] МБ[isnull(memory["peak_vsz"]) ? "" : ", пик VmSize [memory["peak_vsz"]] МБ"])"
	else if(!isnull(memory["peak_vsz"]))
		warning += " (пик VmSize [memory["peak_vsz"]] МБ)"
	if(!isnull(memory["data"]))
		warning += ", куча VmData [memory["data"]] МБ"
	if(!isnull(memory["rss_anon"]))
		warning += ", RSS анонимной [memory["rss_anon"]] / файловой [memory["rss_file"]] МБ"
	// Свободное у хоста дописывается сюда же: без него по строке нельзя сказать,
	// упираемся мы в свой потолок или машине под нами уже нечем дышать.
	if(host_memory)
		warning += ", у хоста свободно [host_memory["available"]] из [host_memory["total"]] МБ"
	warning += ", объектов [num2text(world.contents.len, 12)], хардделов [num2text(SSgarbage.totaldels, 12)]"
	if(memory_baseline_mb)
		warning += ", база раунда [memory_baseline_mb][memory_baseline_provisional ? " МБ (предварительная, раунд ещё не начался)" : " МБ"]"
	if(memory_growth_mb_per_minute > 0)
		warning += ", рост [memory_growth_mb_per_minute] МБ/мин"
		var/minutes_left = memory_minutes_to_ceiling(memory["vsz"], process_address_ceiling_mb, memory_growth_mb_per_minute)
		if(!isnull(minutes_left))
			warning += ", до потолка [minutes_left] мин"
	log_world("## MEMORY: [warning]")
	// Строка в логе уходит и с предварительного уровня - длинное лобби тоже умеет съесть
	// память, и молчать о нём нельзя. А вот перепись с него не заказывается: снимок пустого
	// лобби стал бы отсчётной точкой memory_census_previous, и ПЕРВАЯ перепись начавшегося
	// раунда отчиталась бы приростом на весь роундстарт - ровно тот отказ, от которого
	// take_memory_baseline() уже сторожит свой собственный вызов переписи.
	if(memory_baseline_provisional)
		return
	request_instance_census()

/**
 * Единственное за раунд сообщение админам - и его обязательный дубль в лог мира.
 *
 * Дубль не косметика: message_admins() пишет только в админский чат (см. /proc/message_admins
 * в admin.dm), в файлы раунда не попадает ни строки, и разбор постфактум не может сказать,
 * предупредили админов или нет. В архиве раунда 10020 порог был перейден - а следа нет.
 *
 * Аргументы:
 * * vsz - VmSize этого замера в МБ, единственная величина, по которой решается тревога
 * * host_memory - память хоста, только для текста сообщения; порогов по ней нет, см. ниже
 */
/datum/controller/subsystem/time_track/proc/check_memory_admin_warning(vsz, list/host_memory)
	if(memory_admin_warned)
		return

	// Прогноз считается только по настоящему базовому уровню. По предварительному его
	// считать нельзя: окно замеров тогда упирается одним краем в пустое лобби, другим -
	// в только что заспауненную станцию, и наклон между ними означает роундстарт, а не
	// утечку. Страховка по остатку до потолка ниже работает всегда - она смотрит на величину,
	// а не на скорость, и обмануть её роундстартом невозможно.
	var/minutes_left = (memory_baseline_mb && !memory_baseline_provisional) \
		? memory_minutes_to_ceiling(vsz, process_address_ceiling_mb, memory_growth_mb_per_minute) \
		: null
	var/backstop_mb = process_address_ceiling_mb \
		? process_address_ceiling_mb - MEMORY_ADMIN_WARN_HEADROOM_MB \
		: MEMORY_ADMIN_WARN_FALLBACK_MB
	var/reason
	if(!isnull(minutes_left) && minutes_left <= MEMORY_ADMIN_WARN_LEAD_MINUTES)
		reason = "при нынешнем росте [memory_growth_mb_per_minute] МБ/мин запаса осталось примерно на [minutes_left] мин"
	else if(vsz >= backstop_mb)
		reason = process_address_ceiling_mb \
			? "до потолка осталось [round(process_address_ceiling_mb - vsz)] МБ, это [round(vsz / process_address_ceiling_mb * 100)]% потолка" \
			: "потолок замерить не удалось, планка выставлена руками на [MEMORY_ADMIN_WARN_FALLBACK_MB] МБ"
	else
		return

	memory_admin_warned = TRUE
	// Память хоста дописывается в текст, но порогом не служит и отдельной тревоги не поднимает.
	// Умереть молча можно двумя способами - упереться в своё адресное пространство и попасть
	// под OOM-killer, - и различает их именно эта пара цифр. Но действие у админа на них одно
	// и то же (увести раунд на рестарт), сообщение за раунд ровно одно, и отдельная планка по
	// хосту съела бы его на соседе по машине, оставив настоящий потолок без предупреждения.
	// Поэтому здесь строка, а не второй триггер: решение принимается по нашей памяти, а
	// хостовые цифры отвечают на следующий вопрос - кто именно кончился.
	var/host_note = host_memory \
		? " У хоста свободно [host_memory["available"]] из [host_memory["total"]] МБ." \
		: ""
	var/announcement = "ПАМЯТЬ: процесс занял [vsz] МБ адресного пространства\
		[process_address_ceiling_mb ? " из [process_address_ceiling_mb] доступных" : ""], [reason].[host_note] \
		Раунд имеет смысл увести на рестарт заранее: при исчерпании адресного пространства \
		сервер умирает молча и без сохранения. Повторных сообщений не будет, дальше смотреть в perf-лог."
	// Сначала лог, потом чат. Порядок важен ровно по той же причине, по которой дубль
	// вообще существует: message_admins() ходит по живым клиентам и способен упасть, а
	// строка в логе - единственное, по чему разбор постфактум узнаёт, что порог был
	// перейден. Терять её из-за проблемы с выводом в чат нельзя.
	log_world("## MEMORY: админам отправлено предупреждение - [announcement]")
	message_admins("<span class='boldannounce'>[announcement]</span>")

/// Сэмпл старше этого считается протухшим и в сводку по миру не идёт.
#define PING_SAMPLE_STALE_AFTER (90 SECONDS)

/datum/controller/subsystem/time_track/proc/update_ping_metrics()
	ping_samples = 0
	ping_rtt_last_avg = 0
	ping_rtt_last_median = 0
	ping_rtt_last_max = 0
	ping_rtt_avg_avg = 0
	ping_tick_last_avg = 0
	ping_tick_last_max = 0
	ping_server_last_avg = 0
	ping_server_last_max = 0
	ping_server_avg_avg = 0

	var/rtt_last_total = 0
	var/rtt_avg_total = 0
	var/tick_last_total = 0
	var/server_last_total = 0
	var/server_avg_total = 0
	var/list/rtt_last_samples = list()

	for(var/client/C as anything in GLOB.clients)
		if(!C || !C.connection_time || (world.time - C.connection_time < 25))
			continue
		// У подвисшего клиента ping-значения остаются последними навсегда, а max() по всем
		// клиентам залипал на них до конца раунда: в прод-логах rtt_last_max держался
		// десятками секунд и повторял одно и то же число в подряд идущих сэмплах.
		if(C.lastping_at && (world.time - C.lastping_at > PING_SAMPLE_STALE_AFTER))
			continue

		var/rtt_last = C.lastping_rtt_raw
		var/rtt_avg = C.avgping_rtt_raw
		var/tick_last = C.lastping_tick
		var/server_last = C.lastping_server
		var/server_avg = C.avgping_server
		if(!rtt_last && C.lastping_rtt)
			rtt_last = C.lastping_rtt
		if(!rtt_avg && C.avgping_rtt)
			rtt_avg = C.avgping_rtt

		// Compatibility fallback for clients that only have legacy ping values populated.
		if(!rtt_last && !rtt_avg && !tick_last && !server_last && !server_avg)
			rtt_last = C.lastping
			rtt_avg = C.avgping
			tick_last = C.lastping
			server_last = 0
			server_avg = 0

		if(!rtt_last && !rtt_avg && !tick_last && !server_last && !server_avg)
			continue

		ping_samples++
		rtt_last_samples += rtt_last
		rtt_last_total += rtt_last
		rtt_avg_total += rtt_avg
		tick_last_total += tick_last
		server_last_total += server_last
		server_avg_total += server_avg

		ping_rtt_last_max = max(ping_rtt_last_max, rtt_last)
		ping_tick_last_max = max(ping_tick_last_max, tick_last)
		ping_server_last_max = max(ping_server_last_max, server_last)
		// Копится через окно, а не сбрасывается каждый вызов: сэмплы приходят чаще,
		// чем пишется CSV, и мгновенный срез терял большую часть значений.
		ping_server_max_window = max(ping_server_max_window, server_last)

	if(!ping_samples)
		return

	ping_rtt_last_avg = rtt_last_total / ping_samples
	// Медиана рядом со средним: один клиент на спутниковом канале сдвигает арифметическое
	// среднее по миру на десятки миллисекунд, и именно это читалось как "у сервера пинг 50мс".
	sortTim(rtt_last_samples, GLOBAL_PROC_REF(cmp_numeric_asc))
	var/median_index = round((length(rtt_last_samples) + 1) * 0.5)
	ping_rtt_last_median = rtt_last_samples[clamp(median_index, 1, length(rtt_last_samples))]
	ping_rtt_avg_avg = rtt_avg_total / ping_samples
	ping_tick_last_avg = tick_last_total / ping_samples
	ping_server_last_avg = server_last_total / ping_samples
	ping_server_avg_avg = server_avg_total / ping_samples

/datum/controller/subsystem/time_track/fire()

	var/current_realtime = REALTIMEOFDAY
	var/current_byondtime = world.time
	var/current_tickcount = world.time/world.tick_lag

	var/raw_multiplier = 1
	if(last_raw_realtime && last_raw_byond_time)
		var/raw_realtime_delta = current_realtime - last_raw_realtime
		if(raw_realtime_delta > 0)
			raw_multiplier = (current_byondtime - last_raw_byond_time) / raw_realtime_delta
	last_raw_realtime = current_realtime
	last_raw_byond_time = current_byondtime

	raw_multiplier_last = raw_multiplier
	raw_multiplier_jitter_abs_last = abs(raw_multiplier - 1) * 100
	raw_multiplier_jitter_abs_avg = raw_multiplier_jitter_abs_avg ? MC_AVERAGE(raw_multiplier_jitter_abs_avg, raw_multiplier_jitter_abs_last) : raw_multiplier_jitter_abs_last
	raw_multiplier_jitter_abs_max_window = max(raw_multiplier_jitter_abs_max_window, raw_multiplier_jitter_abs_last)

	var/candidate = clamp(raw_multiplier, 0.75, 1.25)
	// Серверное время может только отставать от настоящего, никогда не
	// опережать, поэтому raw_multiplier систематически сидит чуть ниже единицы.
	// Без достаточно широкой мёртвой зоны множитель никогда не становится ровно
	// единицей, и выровненный по тику glide превращается обратно в дробный.
	if(abs(candidate - 1) < MOVEMENT_GLIDE_DILATION_DEADBAND)
		candidate = 1
	if(time_dilation_avg_fast < 3)
		candidate = clamp(candidate, 0.9, 1.1)
	// Smooth the multiplier to prevent jerky visual glide transitions during load spikes.
	//
	// Сглаживается сырое состояние, а наружу уходит снапнутое: подмешивать
	// снапнутое обратно нельзя, иначе просадка мельче десяти процентов никогда
	// не накопится. См. movement_glide_publish().
	glide_size_multiplier_smoothed = MC_AVERAGE(glide_size_multiplier_smoothed, candidate)
	GLOB.glide_size_multiplier = movement_glide_publish(glide_size_multiplier_smoothed)
	glide_size_multiplier_current = GLOB.glide_size_multiplier

	if(times_fired % 20)	// everything else is once every 10 seconds (wait=5 * 20 = 100ds)
		return

	if (!first_run)
		var/tick_drift = max(0, (((current_realtime - last_tick_realtime) - (current_byondtime - last_tick_byond_time)) / world.tick_lag))
		var/tickcount_delta = current_tickcount - last_tick_tickcount
		if(tickcount_delta > 0)
			time_dilation_current = tick_drift / tickcount_delta * 100

		time_dilation_avg_fast = MC_AVERAGE_FAST(time_dilation_avg_fast, time_dilation_current)
		time_dilation_avg = MC_AVERAGE(time_dilation_avg, time_dilation_avg_fast)
		time_dilation_avg_slow = MC_AVERAGE_SLOW(time_dilation_avg_slow, time_dilation_avg)
	else
		first_run = FALSE
	last_tick_realtime = current_realtime
	last_tick_byond_time = current_byondtime
	last_tick_tickcount = current_tickcount
	update_ping_metrics()
	var/list/memory = get_process_memory_mb()
	var/list/host_memory = get_host_memory_mb()
	var/gc_queue_depth = SSgarbage.GetQueueDepth(GC_QUEUE_SOFTCHECK) \
		+ SSgarbage.GetQueueDepth(GC_QUEUE_WARNFAIL) \
		+ SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE)
	if(memory)
		track_process_memory(memory, host_memory)
	refresh_mc_state_context(memory, gc_queue_depth)
	SSblackbox.record_feedback("associative", "time_dilation_current", 1, list("[SQLtime()]" = list("current" = "[time_dilation_current]", "avg_fast" = "[time_dilation_avg_fast]", "avg" = "[time_dilation_avg]", "avg_slow" = "[time_dilation_avg_slow]")))
	log_perf(perf_log_row(memory, host_memory, gc_queue_depth))
	var/should_log_ping_perf = ping_samples && (
		(times_fired % PING_PERF_LOG_EVERY_TICKS == 0) || \
		(ping_rtt_last_max >= PING_PERF_SPIKE_RTT_MS) || \
		(raw_multiplier_jitter_abs_max_window >= PING_PERF_SPIKE_JITTER_PCT) || \
		(time_dilation_current >= PING_PERF_SPIKE_TIDI_PCT)
	)
	if(should_log_ping_perf)
		log_ping_perf(
			list(
				world.time,
				length(GLOB.clients),
				ping_samples,
				ping_rtt_last_avg,
				ping_rtt_last_median,
				ping_rtt_last_max,
				ping_rtt_avg_avg,
				ping_tick_last_avg,
				ping_tick_last_max,
				ping_server_last_avg,
				ping_server_last_max,
				ping_server_avg_avg,
				SSserver_maint.cleanup_last_ms,
				SSserver_maint.cleanup_avg_ms,
				SSserver_maint.cleanup_target_last,
				time_dilation_current,
				MAPTICK_LAST_INTERNAL_TICK_USAGE,
				raw_multiplier_last,
				raw_multiplier_jitter_abs_last,
				raw_multiplier_jitter_abs_avg,
				raw_multiplier_jitter_abs_max_window,
				ping_server_max_window,
				glide_size_multiplier_current,
			)
		)
		raw_multiplier_jitter_abs_max_window = 0
		ping_server_max_window = 0

#undef PING_PERF_LOG_EVERY_TICKS
#undef PING_PERF_SPIKE_RTT_MS
#undef PING_PERF_SPIKE_JITTER_PCT
#undef PING_PERF_SPIKE_TIDI_PCT

/**
 * Заказ переписи инстансов: что именно копится в мире.
 *
 * Зовётся со ступени лестницы, а не по расписанию, и это существенно. Перебор world.contents
 * - это полтора миллиона элементов, и платить за него имеет смысл ровно тогда, когда память
 * уже ушла выше базового уровня раунда, то есть вопрос "чем именно" наконец задан.
 */
/datum/controller/subsystem/time_track/proc/request_instance_census()
	// От второй переписи поверх первой сторожит один только кулдаун, и этого достаточно:
	// момент заказа записывается ДО запуска, а сам перебор занимает секунды против пяти
	// минут кулдауна. Отдельный флаг "перепись идёт" был бы надёжнее ровно до первого
	// рантайма внутри перебора: в DM нет finally, сбросить флаг на аварийном выходе нечем,
	// и застрявший флаг выключил бы диагностику до конца раунда молча.
	if(memory_census_at && world.time < memory_census_at + MEMORY_CENSUS_COOLDOWN)
		return
	memory_census_at = world.time
	INVOKE_ASYNC(src, PROC_REF(run_instance_census))

/**
 * Сама перепись. Растянута по тикам через CHECK_TICK, поэтому итог - смазанный снимок,
 * а не срез на одно мгновение: пока идёт перебор, мир живёт и что-то создаёт. Для вопроса
 * "какого типа стало на десять тысяч больше" этой точности хватает с большим запасом.
 *
 * Турфы и зоны считаются отдельной кучей и в топ по количеству не идут. Их число задано
 * картой (полтора миллиона турфов на восемнадцати z-уровнях), они заняли бы весь список и
 * вытеснили то единственное, ради чего перепись по количеству и делается.
 *
 * Зато во второй топ - по ШИРИНЕ ТИПА - турфы входят обязательно. Счёт штук на вопрос
 * "куда ушли мегабайты" не отвечает вовсе: в раунде 10022 за рост в 1375 МБ отвечали
 * 283 тысячи новых объектов, то есть по 4.8 КБ на объект, чего не бывает.
 *
 * ВАЖНО про эту вторую строку: ширина типа - это НЕ цена инстанса. Замером на стенде
 * (полмиллиона датумов, три чередующихся прогона) показано, что BYOND заводит хранилище
 * переменной ЛЕНИВО, по факту присваивания: голый датум стоит 49 Б, датум с тридцатью
 * объявленными и ни разу не тронутыми переменными - те же 49 Б, со ста объявленными -
 * тоже 49 Б. Ненулевые значения по умолчанию тоже бесплатны: они лежат у типа, а не у
 * инстанса. А вот запись платная и необратимая: одна запись - 125 Б, тридцать - 582 Б,
 * сто - 1697 Б, то есть около 16 Б за переменную сверх сотни байт за само хранилище.
 * Платит даже запись значения, РАВНОГО дефолту, и запись null поверх null: 582 Б вышло
 * и у варианта, писавшего каждой переменной её собственный дефолт, и у варианта,
 * писавшего null в изначально нулевые. Отсюда и разнобой: турф с 190 объявленными
 * переменными в нетронутом космосе стоит единицы байт, а тот же турф после ChangeTurf
 * и полутора десятков присваиваний - несколько сотен.
 *
 * Поэтому строка про ширину типа читается как "у кого таблица шире", а не как раскладка
 * памяти. Раскладку памяти дают три другие строки: количество, длина списков и перепись
 * не-атомных датумов.
 */
/datum/controller/subsystem/time_track/proc/run_instance_census()
	census_lists_extrapolated = 0
	census_personal_slots_total = 0
	var/list/counts = list()
	var/list/weights = list()
	// Тип -> длина vars. Спрашивается ровно один раз на тип: length(thing.vars) на каждом из
	// полутора миллионов элементов стоил бы дороже всей остальной переписи.
	var/list/type_var_slots = list()
	// Тип -> сколько его инстансов уже разобрано по переменным, и сколько элементов нашлось
	// в их списках. Турфы и зоны сюда идут наравне с движимым: списки есть и у них
	// (contents, overlays, corners), а вопрос "где лежат мегабайты" к ним же и адресован.
	var/list/type_list_samples = list()
	var/list/type_list_slots = list()
	// Тип -> ассоциативный набор СПИСКОВ первого разобранного инстанса, ключами по самим
	// спискам. По нему следующие инстансы того же типа отличают свой список от общего на
	// весь тип; см. sample_instance_lists().
	var/list/type_reference_lists = list()
	// Тип -> элементы в общих (одна ссылка на все инстансы) списках. Считаются РОВНО ОДИН
	// раз на тип, потому что и памяти стоят один раз.
	var/list/type_shared_slots = list()
	// Набор уже посчитанных ОБЩИХ списков, ключами по самим спискам, на весь проход.
	// Статик, объявленный у родителя, в DM хранится в одном экземпляре, но КАЖДЫЙ подтип
	// видит его у себя и раньше приписывал себе целиком. В прод-переписи 10100 это заняло
	// все пятнадцать строк топа: семь подтипов chem_dispenser по 5432, четыре ловушки по
	// 2815, четыре винтеркоута по 1603 - на деле три списка, а не пятнадцать. Настоящая
	// растущая утечка (limb_icon_cache) из топа при этом вытеснялась.
	var/list/counted_shared_lists = list()
	// Тип -> элементы во ВСЕХ списках первого инстанса, вместе с общими. Запасной путь для
	// типов с единственным инстансом: делить общее и личное там не на чем, а цифра нужна -
	// именно так выглядит contents космической зоны.
	var/list/type_first_slots = list()
	// Количество ПО ВСЕМ типам, включая турфы и зоны. counts держит только движимое, а для
	// пересчёта выборочной длины списков на весь мир нужен множитель для каждого типа.
	var/list/all_counts = list()
	// Индекс - номер z, а не ключ: ассоциативный список с числовыми ключами в DM неотличим
	// от обращения по индексу и падает на первом же несуществующем ключе.
	var/list/movables_per_z = new /list(world.maxz)
	var/turf_count = 0
	var/area_count = 0
	var/movable_count = 0
	var/turf_slots = 0
	var/area_slots = 0
	var/movable_slots = 0

	var/scanned = 0
	// Длина списка ДО прохода. Перебор идёт по живому world.contents с CHECK_TICK внутри,
	// и удаление сдвигает всё, что лежало за удалённым: элемент сразу за ним обход не
	// увидит вовсе. Гард на null ловит только обнулившийся слот, сдвиг он не ловит.
	// Итог переписи - разница с прошлой, поэтому пропуск не сглаживается, а превращается
	// в цифру прироста. Само по себе это не лечится (снимка полутора миллионов элементов
	// за один тик не сделать), но величину дрейфа надо назвать: прирост меньше неё - шум.
	var/expected = length(world.contents)
	// Стенное время, а не world.time: перебор растянут по тикам, и интересна как раз та
	// длительность, которую видит наблюдатель. Она же - единственный способ заметить, что
	// перепись подорожала: строка в логе называет её каждый раз.
	var/started_at = REALTIMEOFDAY

	for(var/atom/thing as anything in world.contents)
		scanned++
		if(!(scanned % MEMORY_CENSUS_TICK_EVERY))
			CHECK_TICK
		// as anything, а не istype в заголовке цикла: проверка типа на каждом из полутора
		// миллионов элементов стоит дороже всего остального тела. Взамен нужен явный гард
		// на null - список живой, и между тиками из него что-то исчезает.
		if(isnull(thing))
			continue
		var/atom_type = thing.type
		var/slots = type_var_slots[atom_type]
		if(!slots)
			slots = length(thing.vars)
			type_var_slots[atom_type] = slots
		weights[atom_type] += slots
		all_counts[atom_type] += 1
		var/sampled = type_list_samples[atom_type]
		if(sampled < MEMORY_CENSUS_LIST_SAMPLES)
			type_list_samples[atom_type] = sampled + 1
			if(!sampled)
				// Первый инстанс типа только задаёт эталон: его списки запоминаются по
				// ссылке и в личный счёт не идут - на одном инстансе общий список от
				// личного не отличить. Тип с единственным инстансом разбирается ниже,
				// в list_slot_top(), по запасному пути.
				var/list/reference_lists = list()
				type_first_slots[atom_type] = collect_instance_lists(thing, reference_lists)
				type_reference_lists[atom_type] = reference_lists
			else
				sample_instance_lists(thing, atom_type, type_reference_lists[atom_type], type_list_slots, type_shared_slots, counted_shared_lists, sampled == 1)
		if(isturf(thing))
			turf_count++
			turf_slots += slots
			continue
		if(isarea(thing))
			area_count++
			area_slots += slots
			continue
		movable_count++
		movable_slots += slots
		counts[atom_type] += 1
		// z равен нулю у всего, что лежит внутри контейнера, а не на турфе. Такие в разрез
		// по уровням не идут: приписать их некуда, а врать про уровень нельзя.
		var/level = thing.z
		if(level && level <= length(movables_per_z))
			movables_per_z[level] += 1

	var/list/report = memory_census_previous ? instance_census_growth(counts, memory_census_previous) : counts.Copy()
	var/growth_report = !isnull(memory_census_previous)
	memory_census_previous = counts

	sortTim(report, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	var/list/top = list()
	for(var/type_path in report)
		if(length(top) >= MEMORY_CENSUS_TOP)
			break
		top += "[type_path] x[num2text(report[type_path], 12)]"

	// num2text здесь по той же причине, что и в соседней строке про вес: турфов в мире
	// больше миллиона, и без него в лог попадает "1.17045e+006" вместо числа.
	var/drift = expected - scanned
	log_world("## MEMORY: перепись инстансов за [round((REALTIMEOFDAY - started_at) / 10, 0.1)] с: \
		[num2text(turf_count + area_count + movable_count, 12)] всего \
		(турфов [num2text(turf_count, 12)], зон [area_count], прочего [num2text(movable_count, 12)])\
		[drift ? ", мир сдвинулся на [num2text(drift, 12)] за время перебора - прирост меньше этого читать нельзя" : ""]; \
		[growth_report ? "прирост с прошлой переписи" : "самые многочисленные типы"]: \
		[length(top) ? top.Join(", ") : "пусто"]")

	log_instance_weights(weights, counts, type_var_slots, turf_slots, area_slots, movable_slots)
	log_list_slots(all_counts, type_list_samples, type_list_slots, type_first_slots)
	log_shared_list_slots(type_shared_slots)
	log_global_list_slots()
	log_lighting_graph_slots()
	log_movables_per_z(movables_per_z)
	#ifdef DATUM_CENSUS
	for(var/line in datum_census_lines(MEMORY_CENSUS_TOP))
		log_world(line)
	#endif

/**
 * Сколько элементов лежит в списочных переменных одного инстанса.
 *
 * Третье слепое пятно переписи после не-атомных датумов и внутренних таблиц BYOND: растущий
 * ассоциативный список на живом атоме даёт мегабайты при НУЛЕВОМ приросте инстансов, а
 * length(vars) считает ШИРИНУ таблицы типа, то есть про длину списков не знает ничего.
 *
 * Цена элемента списка измерена стендом (по триста тысяч списков, два чередующихся
 * прогона на каждую длину): пустой list() - 41 Б, список от одного до четырёх элементов -
 * 107 Б, дальше по 8 Б за элемент (8/16/32 элемента - 141/205/336 Б). Ассоциативный
 * дороже впятеро: 149 Б за один ключ и по 47-51 Б за каждый следующий (1/4/16/32 ключа -
 * 149/274/869/1696 Б). То есть двадцать тысяч ключей в assoc - это мегабайт, и в переписи
 * инстансов он не виден никак.
 *
 * "vars" пропускается намеренно: это ссылка на сам список переменных, и её длина - это
 * ширина типа, уже посчитанная в weights. Всё остальное считается как есть, включая
 * contents и overlays: слот списка стоит памяти независимо от того, что в нём лежит.
 *
 * ОБЩИЕ СПИСКИ ОТДЕЛЕНЫ ОТ ЛИЧНЫХ. `var/static/list/` виден в vars как обычная переменная,
 * и раньше такой список приписывался КАЖДОМУ инстансу, раздувая строку на порядок. Это не
 * теоретическая оговорка: в прод-переписи 23.08 топ строки состоял почти целиком из статиков.
 * /atom/movable/lighting_object отдавал по 69 элементов на штуку, из которых сорок - два
 * двадцатиэлементных набора (общий на тип буфер цветовой матрицы и матрица color, живущая
 * в аппирансе). Скрытые трубы отдавали 177 элементов на штуку и "росли" до 194 за раунд -
 * это рос общий `pipeimages` из atmosmachinery.dm. Человек показывал 5071 на штуку, а
 * обезьяна 4656 - почти одно и то же число, потому что обе цифры были общим на весь
 * /mob/living/carbon кэшем `limb_icon_cache`, а вовсе не личными списками мобов. Строка,
 * которая должна отвечать на вопрос "кто накопил мегабайты за раунд", отвечала на вопрос
 * "у какого типа есть большой статик", то есть не отвечала ни на что.
 *
 * Отличаются они ПО ССЫЛКЕ: первый инстанс типа запоминает свои списки, следующие сверяются
 * с этим набором. Совпала ссылка - список общий, платится за него один раз на тип; не
 * совпала - список личный, и его длину можно умножать на популяцию. Заодно так же
 * отсеиваются типовые дефолты: список-дефолт в DM до первой записи один на всех
 * инстансов, и стоит он тоже один раз.
 */
/datum/controller/subsystem/time_track/proc/collect_instance_lists(datum/thing, list/reference_lists)
	var/slots = 0
	var/list/instance_vars = thing.vars
	for(var/var_name in instance_vars)
		if(var_name == "vars")
			continue
		var/value = instance_vars[var_name]
		if(!islist(value))
			continue
		// Ключом идёт сам список: сверка нужна по ссылке, а не по содержимому, и REF()
		// ради этого звать незачем - он на каждый вызов заводит новую строку, а строки
		// в BYOND живут до конца раунда.
		reference_lists[value] = TRUE
		slots += list_slots_deep(value)
	return slots

/**
 * Разбор ВТОРОГО и дальше инстанса типа: личные списки отдельно, общие отдельно.
 *
 * Аргументы:
 * * thing - разбираемый инстанс
 * * thing_type - его тип, ключ во всех накопителях
 * * reference_lists - списки первого инстанса этого типа, набор ссылок из collect_instance_lists()
 * * clean_slots - тип -> элементы в ЛИЧНЫХ списках, накапливается по всем таким инстансам
 * * shared_slots - тип -> элементы в ОБЩИХ списках, заполняется ровно один раз на тип
 * * counted_shared - набор уже посчитанных общих списков на весь проход, ключами по спискам
 * * count_shared - TRUE только на втором инстансе: общие списки считаются один раз
 */
/datum/controller/subsystem/time_track/proc/sample_instance_lists(datum/thing, thing_type, list/reference_lists, list/clean_slots, list/shared_slots, list/counted_shared, count_shared)
	var/slots = 0
	var/list/instance_vars = thing.vars
	for(var/var_name in instance_vars)
		if(var_name == "vars")
			continue
		var/value = instance_vars[var_name]
		if(!islist(value))
			continue
		if(reference_lists?[value])
			// Один список - одна запись, независимо от того, сколько подтипов его видят.
			// Статик родителя наследуется подтипами ОДНИМ объектом, и приписывать его
			// каждому - это считать одну и ту же память по нескольку раз. Тип, дошедший
			// до списка первым, его и получает; строка в логе про это предупреждает.
			if(count_shared && !counted_shared[value])
				counted_shared[value] = TRUE
				shared_slots[thing_type] += list_slots_deep(value)
			continue
		slots += list_slots_deep(value)
	clean_slots[thing_type] += slots

/**
 * Длина списка вместе с вложенным уровнем.
 *
 * Один уровень вложенности - не прихоть. Ровно так устроен самый крупный из найденных
 * накопителей: /mob/var/list/logging - это assoc из ПЯТИ ключей (по типу сообщения), в
 * каждом из которых лежит список на тысячи записей. Плоский length() отдал бы пятёрку и
 * не заметил бы ничего; для той же причины вложенность нужна reagent_list, comp_lookup,
 * datum_components и любому "список списков".
 *
 * Глубже второго уровня не идём, а длинные списки РАЗБИРАЕМ ПО ВЫБОРКЕ, а не пропускаем.
 * Прежняя редакция для списка длиннее MEMORY_CENSUS_NESTED_SCAN_CAP возвращала только его
 * собственную длину, и это была главная слепота прибора: cached_game_recipes_data на 747
 * ключей, в каждом из которых лежит список на 28 полей, отдавал ровно "747" - недоучёт в
 * тридцать раз. Всё, что "список списков" и длиннее шестидесяти четырёх, недосчитывалось
 * систематически; отсюда и берётся большая часть неатрибутированного роста.
 *
 * Теперь копия берётся ОТРЕЗКОМ в те же шестьдесят четыре элемента, вложенное считается по
 * нему и линейно разворачивается на всю длину. Отрезок решает и вторую задачу, ради которой
 * стоял кап: contents космической зоны на MetaStation - это 809 тысяч элементов, и полная
 * копия ради поиска вложенных списков стоила бы дороже всей переписи, а копия первых
 * шестидесяти четырёх стоит столько же, сколько у любого другого списка.
 *
 * Копия нужна потому, что встроенные списки BYOND - contents, overlays, verbs, locs,
 * vis_contents - ассоциативного чтения не поддерживают ВООБЩЕ: outer[элемент] на них не
 * отдаёт null, а падает "bad index". Плоская копия и снимает запрет, и сохраняет пары
 * настоящего ассоциативного списка.
 *
 * Фиксированная глубина заодно закрывает вопрос циклов: список, лежащий сам в себе,
 * перебор не зациклит, потому что перебора глубже второго уровня нет.
 */
/datum/controller/subsystem/time_track/proc/list_slots_deep(list/outer)
	var/own_length = length(outer)
	if(!own_length)
		return 0

	var/sample_size = min(own_length, MEMORY_CENSUS_NESTED_SCAN_CAP)
	var/nested_slots = 0

	if(istype(outer, /alist))
		// alist из 516: islist() отвечает на него правдой, а istype(x, /list) - нет. Проверять
		// надо именно /alist, а не отсутствие /list: под "не /list" попадает ещё и filters
		// атома, у которого всё наоборот - срез работает, а чтения по ключу нет вовсе
		// ("bad index"). Позиционного доступа у alist нет вовсе, поэтому
		// отрезок Copy(1, N) на нём падает "list index out of bounds" - перепись валила раунд
		// на каждой мехе с её facing_modifiers и на profile_*_by_type любой подсистемы.
		// Копия ему и не нужна: перебор отдаёт ключи, а чтение по ключу законно всегда,
		// включая числовой ключ.
		var/scanned = 0
		for(var/key in outer)
			scanned++
			if(scanned > sample_size)
				break
			if(islist(key))
				nested_slots += length(key)
			var/nested = outer[key]
			if(islist(nested))
				nested_slots += length(nested)
	else
		var/list/scan = outer.Copy(1, sample_size + 1)
		for(var/index in 1 to sample_size)
			var/element = scan[index]
			// Список прямо элементом - это "список списков", вроде reagent_list или очереди пар.
			if(islist(element))
				nested_slots += length(element)
				continue
			// Ассоциативная половина: перебор списка отдаёт КЛЮЧИ, значение достаётся индексацией.
			// Числовой ключ так брать нельзя - для плоского списка outer[число] это обращение по
			// позиции, и вместо отсутствующего значения вернётся соседний элемент.
			if(isnull(element) || isnum(element))
				continue
			var/nested = scan[element]
			if(islist(nested))
				nested_slots += length(nested)

	if(nested_slots && sample_size < own_length)
		// Разворот выборки на всю длину. Цифра становится оценкой, поэтому такие списки
		// считаются отдельно и называются в логе - читать их как точный замер нельзя.
		nested_slots = round(nested_slots * own_length / sample_size)
		census_lists_extrapolated++
	return own_length + nested_slots

/**
 * Четвёртая строка переписи: чей вес лежит в списках, а не в переменных.
 *
 * Считаются только ЛИЧНЫЕ списки инстансов - общие на весь тип уходят отдельной строкой,
 * см. log_shared_list_slots() и collect_instance_lists().
 *
 * Аргументы:
 * * all_counts - тип -> количество инстансов, включая турфы и зоны
 * * type_list_samples - тип -> сколько его инстансов разобрано по переменным
 * * type_list_slots - тип -> элементы в личных списках инстансов со ВТОРОГО и дальше
 * * type_first_slots - тип -> элементы во всех списках первого инстанса, запасной путь
 */
/datum/controller/subsystem/time_track/proc/log_list_slots(list/all_counts, list/type_list_samples, list/type_list_slots, list/type_first_slots)
	var/list/top = list_slot_top(all_counts, type_list_samples, type_list_slots, type_first_slots)
	if(!length(top))
		return
	log_world("## MEMORY: элементы ЛИЧНЫХ списков (выборка по [MEMORY_CENSUS_LIST_SAMPLES] инстанса на тип, \
		общие на тип списки не в счёт, пересчёт на мир): всего [num2text(census_personal_slots_total, 12)]\
		[census_lists_extrapolated ? ", из них [num2text(census_lists_extrapolated, 12)] списков длиннее [MEMORY_CENSUS_NESTED_SCAN_CAP] развёрнуты по выборке (оценка, не замер)" : ""]; \
		крупнейшие: [top.Join(", ")]")

/**
 * Пятая строка переписи: сколько лежит в ОБЩИХ на весь тип списках.
 *
 * Отдельная строка, а не слагаемое в предыдущей, потому что отвечает на другой вопрос.
 * Личный список типа с миллионной популяцией - это миллион списков; общий список того же
 * типа - ровно один, сколько бы инстансов ни было. Складывать их в одну цифру означало бы
 * ровно ту ошибку, ради которой они и разделены.
 *
 * Зато сама по себе строка ценна: растущий статик - это утечка ничем не хуже прочих, и до
 * этого разделения увидеть её было нечем. Первые кандидаты, ради которых строка написана, -
 * `limb_icon_cache` на /mob/living/carbon и `pipeimages` на атмос-машинерии: оба без капа,
 * оба растут весь раунд, оба держат иконки.
 */
/datum/controller/subsystem/time_track/proc/log_shared_list_slots(list/type_shared_slots)
	sortTim(type_shared_slots, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	var/list/top = list()
	var/total = 0
	for(var/type_path in type_shared_slots)
		total += type_shared_slots[type_path]
		if(length(top) < MEMORY_CENSUS_TOP)
			top += "[type_path] [num2text(type_shared_slots[type_path], 12)]"
	if(!length(top))
		return
	log_world("## MEMORY: элементы ОБЩИХ на тип списков (статики и типовые дефолты, каждый список \
		считается ОДИН раз на весь мир и записывается тому типу, который дошёл до него первым - \
		у статика родителя это может быть любой из подтипов): всего [num2text(total, 12)]; \
		крупнейшие: [top.Join(", ")]")

/**
 * Шестая строка переписи: глобальные списки и списки подсистем.
 *
 * ЗАЧЕМ. Перепись инстансов обходит world.contents, то есть видит атомы. Глобальных
 * переменных там нет ВООБЩЕ, переменных подсистем - тоже. А между тем это последний
 * DM-видимый резервуар памяти, и он же самый удобный для накопителя: любой `GLOB.что_то`
 * растёт весь раунд, никем не измеряемый. Разбор роста 23.08 упёрся ровно в это: за сто
 * минут раунда 10083 инстансов прибавилось 33 тысячи при росте адресного пространства на
 * 600 МБ, то есть инстансами объясняется меньше трёх процентов, а посмотреть, где лежит
 * остальное, было нечем.
 *
 * Обход дешёвый: глобалок порядка тысячи, подсистем несколько десятков, и это на порядки
 * меньше полутора миллионов атомов основного прохода. CHECK_TICK всё равно стоит - длина
 * отдельной глобалки бывает шестизначной.
 */
/datum/controller/subsystem/time_track/proc/log_global_list_slots()
	var/list/found = list()
	var/total = 0
	var/list/built_in = GLOB.gvars_datum_in_built_vars
	for(var/var_name in GLOB.vars)
		if(var_name == "vars" || (built_in && (var_name in built_in)))
			continue
		var/value = GLOB.vars[var_name]
		if(!islist(value))
			continue
		var/slots = list_slots_deep(value)
		if(!slots)
			continue
		found["GLOB.[var_name]"] = slots
		total += slots
		CHECK_TICK

	// Подсистемы разбираются здесь же, а не отдельной строкой: живут они столько же,
	// сколько глобалки, накапливают так же, и разделять их означало бы две коротких
	// строки вместо одной содержательной.
	for(var/datum/controller/subsystem/subsystem as anything in Master?.subsystems)
		for(var/var_name in subsystem.vars)
			if(var_name == "vars")
				continue
			var/value = subsystem.vars[var_name]
			if(!islist(value))
				continue
			var/slots = list_slots_deep(value)
			if(!slots)
				continue
			found["[subsystem.name].[var_name]"] = slots
			total += slots
		CHECK_TICK

	if(!length(found))
		return
	sortTim(found, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	var/list/top = list()
	for(var/entry in found)
		if(length(top) >= MEMORY_CENSUS_TOP)
			break
		top += "[entry] [num2text(found[entry], 12)]"
	log_world("## MEMORY: элементы глобальных списков и списков подсистем: \
		всего [num2text(total, 12)] в [length(found)] списках; крупнейшие: [top.Join(", ")]")

/**
 * Связи освещения: источники, углы и рёбра между ними.
 *
 * Это единственная крупная структура мира, которую не видит НИ ОДИН прибор. `/datum/light_source`
 * и `/datum/lighting_corner` не лежат в world.contents, поэтому перепись инстансов их не берёт;
 * их списки не глобалки и не типовые статики, поэтому строки личных и общих списков их тоже не
 * берут. По оценке через вычитание на них приходится 60-80 МБ, и до этой строки цифра выводилась
 * ровно так - вычитанием, а не замером.
 *
 * `corner.affecting` и `source.effect_str` - это два взгляда на один двудольный граф, поэтому
 * рёбра считаются один раз, по источникам, а расхождение между взглядами печатается отдельно:
 * если оно ненулевое, где-то отписка от угла прошла в одну сторону.
 */
/datum/controller/subsystem/time_track/proc/log_lighting_graph_slots()
	var/sources = 0
	var/edges_by_source = 0
	var/edges_by_corner = 0
	var/list/seen_corners = list()
	for(var/datum/light_source/source as anything in GLOB.all_light_sources)
		if(QDELETED(source))
			continue
		sources++
		var/list/effect_str = source.effect_str
		if(!length(effect_str))
			continue
		edges_by_source += length(effect_str)
		for(var/datum/lighting_corner/corner as anything in effect_str)
			if(QDELETED(corner) || seen_corners[corner])
				continue
			seen_corners[corner] = TRUE
			edges_by_corner += LAZYLEN(corner.affecting)
		CHECK_TICK

	var/corners = length(seen_corners)
	// Цена по измеренной модели: непустой список стоит 108 Б сверх слота, элемент списка - 8 Б,
	// сам датум угла с его двумя десятками записанных переменных - около 368 Б. Оценка идёт в
	// строку намеренно: без неё число рёбер ни о чём не говорит читателю лога.
	var/estimate_mb = round((corners * (368 + 108) + edges_by_source * 8 * 2 + sources * 108) / (1024 * 1024), 0.1)
	log_world("## MEMORY: граф освещения: источников [num2text(sources, 12)], углов [num2text(corners, 12)], 		рёбер [num2text(edges_by_source, 12)][edges_by_source == edges_by_corner ? "" : " (со стороны углов [num2text(edges_by_corner, 12)] - взгляды разошлись, где-то отписка прошла в одну сторону)"]; 		по измеренной модели это около [estimate_mb] МБ")

/**
 * Топ типов по суммарной длине ЛИЧНЫХ списочных переменных, строками для лога.
 *
 * Отдельным проком по той же причине, что и instance_weight_top(): перебирать world.contents
 * в тесте нечего, а пересчёт выборки на мир проверить надо - ошибка в множителе даёт
 * правдоподобную и полностью выдуманную цифру.
 *
 * Делитель здесь - число разобранных инстансов МИНУС ОДИН: первый инстанс типа тратится на
 * эталон ссылок и в личный счёт не идёт. Типу с единственным инстансом делить не на что, и
 * для него берётся запасной путь - все списки первого инстанса как есть. Разделять там
 * нечего и незачем: инстанс один, и платит он за свои списки ровно один раз, общие они или нет.
 */
/datum/controller/subsystem/time_track/proc/list_slot_top(list/all_counts, list/type_list_samples, list/type_list_slots, list/type_first_slots)
	var/list/estimated = list()
	var/list/per_instance_slots = list()
	for(var/type_path in type_list_samples)
		var/sampled = type_list_samples[type_path]
		if(sampled <= 0)
			continue
		var/per_instance
		if(sampled > 1)
			per_instance = type_list_slots[type_path] / (sampled - 1)
		else
			per_instance = type_first_slots?[type_path]
		if(!per_instance)
			continue
		per_instance_slots[type_path] = per_instance
		estimated[type_path] = round(per_instance * all_counts[type_path])
		// Итог по ВСЕМУ миру, а не только по топу: без него строка отдавала пятнадцать
		// строк и ничего больше, и свести баланс памяти по переписи было нечем.
		census_personal_slots_total += estimated[type_path]

	sortTim(estimated, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	var/list/top = list()
	for(var/type_path in estimated)
		if(length(top) >= MEMORY_CENSUS_TOP)
			break
		top += "[type_path] [num2text(estimated[type_path], 12)] (по [round(per_instance_slots[type_path], 0.1)] на штуку)"
	return top

/**
 * Вторая строка переписи: чей вес, а не чьё количество.
 *
 * Слоты переводятся в миллионы намеренно. Их там сотни миллионов, а BYOND интерполирует
 * большие числа в экспоненциальную запись с шестью значащими цифрами - в логе вместо суммы
 * оказалось бы "2e+008".
 */
/datum/controller/subsystem/time_track/proc/log_instance_weights(list/weights, list/counts, list/type_var_slots, turf_slots, area_slots, movable_slots)
	var/total_slots = turf_slots + area_slots + movable_slots
	if(total_slots <= 0)
		return

	var/list/top = instance_weight_top(weights, counts, type_var_slots, total_slots)

	// "Ширина" - это ОБЪЯВЛЕННЫЕ переменные, а платится только за ЗАПИСАННЫЕ, ступенями по
	// четыре слота. Числа из этой строки нельзя брать списком целей: снятие переменной,
	// которую никто не писал, не освобождает ни байта, а снятие одной из четырёх записанных
	// не двигает ступень. Разделить объявленные и записанные прибор не может: BYOND бита
	// "слот записан" не отдаёт, а обходные пути (initial() по имени переменной такого не
	// умеет; держать эталонный инстанс - это подмешивать фантомного держателя в диагностику
	// хардделов; WEAKREF пишет датум прямо в измеряемый объект) искажают сам замер.
	// Куда смотреть вместо неё, сказано в строке-подсказке ниже.
	log_world("## MEMORY: ширина типов (ОБЪЯВЛЕННЫЕ переменные - это НЕ цена и НЕ список целей, \
		платится только за записанные, ступенями по 4 слота; раскладку памяти дают строки \
		количества, личных списков и переписи датумов): \
		[round(total_slots / 1000000, 0.1)] млн слотов \
		(турфы [round(turf_slots / total_slots * 100, 0.1)]%, \
		движимое [round(movable_slots / total_slots * 100, 0.1)]%, \
		зоны [round(area_slots / total_slots * 100, 0.1)]%); \
		самые широкие типы: [length(top) ? top.Join(", ") : "пусто"]")

/**
 * Топ типов по весу, строками для лога.
 *
 * Отдельным проком по той же причине, что и instance_census_growth(): перебирать
 * world.contents в тесте нечего, а вот сортировку с арифметикой долей проверить надо.
 *
 * Аргументы:
 * * weights - тип -> суммарное число переменных всех его инстансов
 * * counts - тип -> количество, только для движимого (турфов и зон там нет)
 * * type_var_slots - тип -> длина vars одного инстанса
 * * total_slots - сумма весов по всему миру, знаменатель для долей
 */
/datum/controller/subsystem/time_track/proc/instance_weight_top(list/weights, list/counts, list/type_var_slots, total_slots)
	var/list/top = list()
	if(total_slots <= 0)
		return top

	sortTim(weights, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	for(var/type_path in weights)
		if(length(top) >= MEMORY_CENSUS_TOP)
			break
		var/slots_each = type_var_slots[type_path]
		if(!slots_each)
			continue
		// counts держит только движимое, поэтому количество для турфов и зон берётся делением
		// веса на длину vars: обе величины считались одним и тем же проходом. Точность тут
		// не абсолютная - вес мира это сотни миллионов слотов, а число в DM хранит целыми
		// лишь первые 2^24, - так что штука-другая на миллионе теряется. Для вопроса "чего
		// в мире много" этого хватает; точный счёт движимого лежит рядом, в counts.
		var/instances = counts[type_path] || round(weights[type_path] / slots_each)
		top += "[type_path] x[num2text(instances, 12)] по [slots_each] перем. - [round(weights[type_path] / total_slots * 100, 0.1)]%"
	return top

/**
 * Третья строка переписи: разрез движимого по z-уровням.
 *
 * Турфов на каждом уровне поровну (maxx на maxy), разрез по ним не сказал бы ничего. А вот
 * содержимое уровней различается на порядок, и именно уровнями память прибывает ступенями:
 * логи 10022 и 10023 показывают скачок на сотню-другую МБ ровно в момент инициализации света
 * на очередном z. Строка отвечает, какой уровень имеет смысл выключать первым.
 */
/datum/controller/subsystem/time_track/proc/log_movables_per_z(list/movables_per_z)
	var/list/by_level = list()
	for(var/level in 1 to length(movables_per_z))
		var/count = movables_per_z[level]
		if(!count)
			continue
		var/datum/space_level/space_level = (SSmapping && length(SSmapping.z_list) >= level) ? SSmapping.z_list[level] : null
		by_level["z[level] [space_level ? space_level.name : "без имени"]"] = count

	if(!length(by_level))
		return

	sortTim(by_level, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	var/list/top = list()
	for(var/label in by_level)
		if(length(top) >= MEMORY_CENSUS_TOP_Z)
			break
		top += "[label] [by_level[label]]"

	log_world("## MEMORY: движимое по z-уровням (самые населённые): [top.Join(", ")]")

/**
 * Разница двух переписей: тип -> насколько его стало больше.
 *
 * Убыль отбрасывается намеренно. Вопрос к переписи всегда один - что копится; тип, которого
 * стало меньше, на него не отвечает, а место в топе занимает.
 *
 * Отдельным проком, потому что это единственная часть переписи, которую можно проверить
 * юнит-тестом: перебирать world.contents в тесте нечего.
 */
/datum/controller/subsystem/time_track/proc/instance_census_growth(list/current, list/previous)
	var/list/growth = list()
	for(var/type_path in current)
		// previous[type_path] отсутствующего ключа даёт null, а null в арифметике DM - ноль,
		// то есть новый тип честно считается выросшим на всё своё количество.
		var/delta = current[type_path] - previous[type_path]
		if(delta > 0)
			growth[type_path] = delta
	return growth

#undef MEMORY_WARN_CEILING_FRACTION
#undef MEMORY_WARN_FALLBACK_MB
#undef MEMORY_WARN_STEP_MB
// MEMORY_ADMIN_WARN_LEAD_MINUTES живёт дальше файла намеренно: его читает
// code/modules/unit_tests/process_memory.dm, а .dm-файлы тестов включаются в .dme ПОЗЖЕ
// подсистемы, и снятый дефайн там уже недоступен. Записанная в тест цифрой, эта планка
// пережила бы любую перенастройку молча - тест продолжил бы проверять прежние двадцать минут.
#undef MEMORY_ADMIN_WARN_HEADROOM_MB
#undef MEMORY_ADMIN_WARN_FALLBACK_MB
#undef MEMORY_RATE_WINDOW
#undef MEMORY_RATE_MIN_SPAN
#undef MEMORY_BASELINE_SETTLE_TIME
#undef MEMORY_BASELINE_FALLBACK_TIME
#undef MEMORY_CENSUS_COOLDOWN
#undef MEMORY_CENSUS_TOP
#undef MEMORY_CENSUS_TOP_Z
#undef MEMORY_CENSUS_TICK_EVERY
#undef MEMORY_CENSUS_LIST_SAMPLES
#undef MEMORY_CENSUS_NESTED_SCAN_CAP
#undef PING_SAMPLE_STALE_AFTER


/// Заголовок перф-CSV. Вынесен из Initialize() отдельным проком, чтобы юнит-тест мог
/// сверить его длину с длиной строки значений: разъехавшись на один элемент, они дают
/// файл, где КАЖДАЯ величина сдвинута на соседнюю колонку, а числа остаются
/// правдоподобными. См. perf_log_columns.dm.
/datum/controller/subsystem/time_track/proc/perf_log_header()
	return list(
	"time",
	"players",
	"tidi",
	"tidi_fastavg",
	"tidi_avg",
	"tidi_slowavg",
	"maptick",
	"num_timers",
	"timer_buckets",
	"timer_second_queue",
	"timer_clienttime",
	"timer_hashes",
	"air_turf_cost",
	// Несглаженная стоимость фазы турфов последнего прохода. Раньше здесь
	// стоял auxmos-овский огрызок turf_process_time() - прок без тела,
	// то есть null, то есть пустая строка во всех строках всех логов.
	"air_turf_cost_last",
	"air_equalize_cost",
	"air_post_process_cost",
	"air_eg_cost",
	"air_highpressure_cost",
	"air_hotspots_cost",
	"air_heat_spread_cost",
	"air_pipenets_cost",
	"air_rebuilds_cost",
	"air_amt_gas_mixes",
	"air_alloc_gas_mixes",
	"air_hotspot_count",
	"air_network_count",
	// Сколько турфов фаза высокого давления реально обработала. Длина
	// самой очереди тут бесполезна: фаза съедает список по ходу, и любой
	// сэмплер видит либо ноль, либо случайный срез середины прохода.
	"air_highpressure_processed",
	// Главная величина фазы турфов: её стоимость - это ровно
	// "сколько активных турфов" на "сколько стоит process_cell".
	// Без неё разбор раунда не отличает подорожавшую клетку от
	// разросшегося фронта.
	"air_active_turfs",
	"air_excited_groups",
	"air_superconduct_turfs",
	"air_machinery_count",
	"air_atom_process_count",
	// Вход и выход клапана насыщения. Тайм-дилатация к фоновой
	// подсистеме слепа (MC_TICK_CHECK уступает ровно по бюджету тика,
	// и МК держит свои 20 fps, сколько бы SSair ни ел), поэтому
	// "нагрузка атмоса" - это длина полного прохода, делённая на
	// интервал, в который она обязана была уложиться.
	// air_pass_ms - процессорное время прохода, air_pass_wall_ms - реальное.
	// Они расходятся в пять с лишним раз, потому что МК отдаёт фоновой
	// подсистеме лишь долю остатка тика. Перегрузка живёт во второй
	// величине, и клапан подключён именно к ней.
	"air_pass_ms",
	"air_pass_wall_ms",
	"air_saturation_ratio",
	"air_saturation_scale",
	"air_pass_fire_slices",
	"air_wait",
	// Фаза машинерии не логировалась вообще, а это вторая по размеру
	// статья прохода: разбор раунда 9868 видел её только как разницу
	// между air_pass_ms и суммой остальных колонок (до 11 мс на проход).
	// Вместе с ней сюда же две другие немые фазы.
	"air_machinery_cost",
	"air_decompression_cost",
	"air_atoms_cost",
	// Машины, спящие на сердцебиении, и сети, ждущие сведения. Обе
	// величины - вход в решение "ротация или работа", и обе были видны
	// только из админской верхи.
	"air_machinery_idle",
	"air_dirty_pipenets",
	// Инвариант грязного списка: сеть с поднятым update, потерянная мимо
	// очереди, больше не обсчитается никогда. Обязан быть нулём.
	"air_orphan_dirty_pipenets",
	// Сколько активных турфов реально сдвинули газ. Главная колонка фазы:
	// 307 из 2980 в раунде 9868.
	"air_sharing_turfs",
	// Память процесса. Крашей 17.08.2026 разбор не взял ровно потому, что этих
	// четырёх колонок не было: процесс умирал молча, а сколько он ел - неизвестно.
	// Пиковые величины ведёт ядро, поэтому они переживают промах сэмплера между
	// строками CSV, а всплеск, который добивает процесс, живёт доли секунды.
	"mem_vsz_mb",
	"mem_rss_mb",
	"mem_peak_vsz_mb",
	"mem_peak_rss_mb",
	// Свободная память ХОСТА. Отличает упор в потолок адресного пространства
	// (мы у потолка, хосту хорошо) от OOM-killer'а (нам не тесно, хосту нечем
	// дышать). По одним только mem_* эти два случая неразличимы.
	"mem_host_avail_mb",
	// Дальше - косвенные счётчики роста, без которых по mem_* видно только "растёт",
	// но не видно, ЧТО растёт.
	// instances - всё, что BYOND считает содержимым мира (турфы, объекты, мобы,
	// зоны). Растёт вместе с mem_vsz - течёт объектами; стоит на месте, а память
	// идёт вверх - течёт тем, что объектами не считается: аппирансы, строки,
	// иконки, rsc-кэш. Величина уже считалась для админской стат-панели, но
	// нигде не сохранялась, то есть после раунда её было негде взять.
	"instances",
	// Хардделы это утечка по определению: объект, который не собрался. Разница
	// между строками CSV даёт скорость утечки, а не итог за раунд.
	"harddels",
	"softdels",
	// Очередь GC целиком. Затор в ней - это отложенная память, ещё не посчитанная
	// ни в хардделах, ни в софтделах.
	"gc_queue",
	// Z-уровни. Каждый - это maxx*maxy турфов, десятки мегабайт разом. Ступенька
	// в памяти без роста instances почти всегда означает подгруженную карту, и
	// двойные загрузки руин у нас уже случались.
	"maxz",
	// Сколько раз пересобиралось колесо таймеров, см. SStimer.bucket_reset_count.
	"timer_bucket_resets",
	// Колонки ниже дописаны позже и стоят в хвосте, а не рядом с роднёй из mem_*,
	// намеренно: разбор ходит по CSV разных раундов одним и тем же awk по номеру
	// колонки, и вставка в середину молча съехала бы на соседнюю величину во всём,
	// что было записано раньше. Дописывать в хвост можно всегда, вставлять - нет.
	//
	// Куча процесса и резидентная память по происхождению. Отвечают на следующий
	// вопрос после "память растёт": растёт ЧТО. VmData - куча, RssFile - отображённые
	// файлы (rsc, иконки, бинарь). В раунде 10020 память шла вверх на 21.7 МБ/мин
	// при почти неизменном числе объектов, и без этого разделения дальше разбора нет.
	"mem_data_mb",
	"mem_rss_anon_mb",
	"mem_rss_file_mb",
	// Потолок адресного пространства. Константа на весь раунд, но по одному только
	// CSV иначе нельзя сказать, 3378 МБ - это 80% потолка или 45%.
	"mem_ceiling_mb",
	// Скорость роста по получасовому окну. Дублирует наклон соседней колонки, но
	// именно эта величина решает, когда админам уходит предупреждение, - без неё
	// решение подсистемы нельзя перепроверить постфактум.
	"mem_growth_mb_min",
	// Всего памяти у хоста. Свободное без общего не читается: 45 ГБ свободно - это
	// просторно на машине с 62 ГБ и вообще-то тесно на машине с 512.
	"mem_host_total_mb",
	// Пересборки ВТОРОГО колеса бакетов, SSrunechat. Стоят столько же, сколько
	// пересборка таймерного, и до этой колонки не были видны нигде.
	"runechat_bucket_resets",
	// Провалы сборки иконок. Единственная колонка, ненулевое значение которой само
	// по себе означает, что мир на грани: рантайм в /icon/New() - это отказ крупной
	// НЕПРЕРЫВНОЙ аллокации, и в каскаде падений 23.08 (раунды 10084-10090) он был
	// последним, что мир успевал написать. Умирал он при этом на 2.5-3.0 ГБ, то есть
	// с запасом больше гигабайта до потолка - никакая колонка про объём такого не
	// показывает. См. code/__HELPERS/icon_alloc_guard.dm.
	"icon_alloc_failures",
	// Свет. До этих колонок SSlighting не писал о себе на диск НИЧЕГО: cost_* и
	// worst_fire_cost уходили только в stat_entry(), то есть во вкладку МК, которую в
	// headless и на проде не читает никто. При том что свет - вторая по цене подсистема
	// и главная статья базовой памяти (в раунде 10119 три постройки z-уровней = 466 МБ),
	// а любой размен "память против тика" в нём до сих пор было нечем проверить.
	// cost_* - сглаженные MC_AVERAGE миллисекунды фазы, worst - настоящий максимум
	// одного прогона, очереди - незакрытый хвост работы.
	"light_cost_sources",
	"light_cost_corners",
	"light_cost_objects",
	"light_worst_fire_ms",
	"light_queue_sources",
	"light_queue_corners",
	"light_queue_objects",
	"light_lit_deferred_z",
	// Качание сноса/подъёма отложенных уровней. Кумулятивные счётчики: в раунде 10126 их
	// пришлось восстанавливать подсчётом строк dd.log вручную, а разность соседних строк
	// CSV сразу показывает частоту. Ноль у обоих - отсрочка работает и никого не трясёт.
	"light_z_builds",
	"light_z_teardowns",
	// Книга недатумных аллокаций (code/__HELPERS/nondatum_ledger.dm). Кумулятив за раунд:
	// разность соседних строк отвечает на вопрос, который перепись инстансов не берёт -
	// чем платили ступени VmSize, в которых объектов не прибавилось.
	"ledger_icons",
	"ledger_icon_pixels",
	"ledger_asset_bytes",
	"ledger_rsc_bytes",
	"ledger_tgui_bytes",
	"ledger_statpanel_bytes",
	"ledger_spritesheets",
	)

/// Строка значений перф-CSV. Ширина обязана совпадать с perf_log_header() при любых
/// аргументах: без /proc (Windows) memory/host_memory приходят null, и колонки просто
/// пустые - выкидывать их нельзя, иначе CSV прода и локального прогона не сравнить.
/datum/controller/subsystem/time_track/proc/perf_log_row(list/memory, list/host_memory, gc_queue_depth)
	return list(
	world.time,
	length(GLOB.clients),
	time_dilation_current,
	time_dilation_avg_fast,
	time_dilation_avg,
	time_dilation_avg_slow,
	MAPTICK_LAST_INTERNAL_TICK_USAGE,
	length(SStimer.timer_id_dict),
	SStimer.bucket_count,
	length(SStimer.second_queue),
	length(SStimer.clienttime_timers),
	length(SStimer.hashes),
	SSair.cost_turfs,
	SSair.cost_turfs_last,
	SSair.cost_equalize,
	SSair.cost_post_process,
	SSair.cost_groups,
	SSair.cost_highpressure,
	SSair.cost_hotspots,
	SSair.cost_superconductivity,
	SSair.cost_pipenets,
	SSair.cost_rebuilds,
	SSair.get_amt_gas_mixes(),
	SSair.get_max_gas_mixes(),
	length(SSair.hotspots),
	length(SSair.networks),
	SSair.high_pressure_processed,
	length(SSair.active_turfs),
	length(SSair.excited_groups),
	length(SSair.active_super_conductivity),
	length(SSair.atmos_machinery),
	length(SSair.atom_process),
	SSair.cost_full.last_complete_ms,
	SSair.pass_wall_ds * 100,
	SSair.saturation_ratio,
	SSair.saturation_scale,
	SSair.pass_fire_slices_last,
	SSair.wait,
	SSair.cost_atmos_machinery,
	SSair.cost_decompression,
	SSair.cost_atmos_atoms,
	SSair.idle_machine_count(),
	length(SSair.dirty_networks),
	SSair.count_orphan_dirty_pipenets(),
	SSair.sharing_turfs,
	memory ? memory["vsz"] : "",
	memory ? memory["rss"] : "",
	memory ? memory["peak_vsz"] : "",
	memory ? memory["peak_rss"] : "",
	host_memory ? host_memory["available"] : "",
	// Счётчики, переваливающие за миллион, идут через num2text: интерполяция берёт
	// шесть значащих цифр, и в клетке оказывается "1.63212e+006" вместо 1632122.
	// Итог от этого ещё читается, а вот разность соседних строк - та самая скорость
	// роста, ради которой колонки и заведены, - становится шумом округления: шаг
	// округления на шести миллионах софтделов это целые десятки штук.
	num2text(world.contents.len, 12),
	num2text(SSgarbage.totaldels, 12),
	num2text(SSgarbage.totalgcs, 12),
	gc_queue_depth,
	world.maxz,
	SStimer.bucket_reset_count,
	memory ? memory["data"] : "",
	memory ? memory["rss_anon"] : "",
	memory ? memory["rss_file"] : "",
	process_address_ceiling_mb ? process_address_ceiling_mb : "",
	memory_growth_mb_per_minute,
	host_memory ? host_memory["total"] : "",
	SSrunechat.runechat_bucket_reset_count,
	GLOB.icon_alloc_failures,
	SSlighting.cost_sources,
	SSlighting.cost_corners,
	SSlighting.cost_objects,
	SSlighting.worst_fire_cost,
	length(GLOB.lighting_update_lights),
	length(GLOB.lighting_update_corners),
	length(GLOB.lighting_update_objects),
	SSlighting.lit_deferred_zlevel_count(),
	SSlighting.zlevel_builds_total,
	SSlighting.zlevel_teardowns_total,
	// num2text: счётчики байтов переваливают за миллион уже в первые минуты, а
	// интерполяция берёт шесть значащих цифр и превращает разность соседних строк
	// в шум округления (см. комментарий выше у instances).
	num2text(GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS], 12),
	num2text(GLOB.nondatum_ledger[NONDATUM_LEDGER_ICON_PIXELS], 12),
	num2text(GLOB.nondatum_ledger[NONDATUM_LEDGER_ASSET_BYTES], 12),
	num2text(GLOB.nondatum_ledger[NONDATUM_LEDGER_RSC_BYTES], 12),
	num2text(GLOB.nondatum_ledger[NONDATUM_LEDGER_TGUI_BYTES], 12),
	num2text(GLOB.nondatum_ledger[NONDATUM_LEDGER_STATPANEL_BYTES], 12),
	GLOB.nondatum_ledger[NONDATUM_LEDGER_SPRITESHEETS]
	)
