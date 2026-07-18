/// Интервал fire: 2 секунды - каденция тиков запущенных событий (наследие старой подсистемы событий,
/// раннеры /datum/round_event рассчитаны на этот шаг). Бит решения происходит раз в
/// DIRECTOR_BEAT_EVERY файров, то есть раз в WAIT * BEAT_EVERY = 60 секунд.
#define DIRECTOR_WAIT (2 SECONDS)
#define DIRECTOR_BEAT_EVERY 30
/// Срок жизни кэша оценки пула для панели: она полится каждые ~2 секунды и открыта бывает
/// у нескольких админов сразу, а оценка обходит все действия с can_fire каждого.
#define DIRECTOR_POOL_CACHE_TIME (5 SECONDS)
/// Мост intensity рулсета на окно delay между schedule (note_fired) и execute (assigned наполнен).
/// После execute живой рулсет считается динамически (get_ruleset_intensity), мост снимается.
#define DIRECTOR_RULESET_BRIDGE_TIME (5 MINUTES)
/// Порог (в % тика) стоимости одного process() события, с которого запуск попадает в лог:
/// tick() события исполняется атомарно, кусок в полтика и больше - это уже видимый статтер.
#define DIRECTOR_EVENT_HEAVY_TICK_USAGE 50
/// Пауза между записями лога о тяжёлом тике одного и того же события: событие с вечно
/// тяжёлым tick() (каждые 2 секунды) не должно засорять game.log построчным спамом.
#define DIRECTOR_EVENT_HEAVY_LOG_COOLDOWN (30 SECONDS)
/// Провалившееся действие ненадолго исключается из выбора: быстрый повтор предлагает раунду
/// другой вариант, а не тот же самый 30-секундный гост-опрос.
#define DIRECTOR_FAILED_ACTION_COOLDOWN (5 MINUTES)
#define DIRECTOR_FAILED_ACTION_RETRY_DELAY (2 SECONDS)
/// Возраст исполнения, до которого живой рулсет даёт полный вклад в intensity.
/// Для раундстартов возраст считается от старта раунда, для мидраунд/латеджойн-инжекций -
/// от их собственного запуска (executed_at).
#define DIRECTOR_RULESET_DECAY_FULL_TIME (40 MINUTES)
/// Возраст исполнения, к которому вклад рулсета линейно опускается до пола затухания.
#define DIRECTOR_RULESET_DECAY_END (100 MINUTES)
/// Пол затухания: живой антаг старого рулсета всё ещё держит часть intensity,
/// но уже не глушит директора целиком (закрыл цели и залёг - раунд должен оживать).
#define DIRECTOR_RULESET_DECAY_FLOOR 0.25

SUBSYSTEM_DEF(director)
	name = "Director"
	init_order = INIT_ORDER_DIRECTOR
	runlevels = RUNLEVEL_GAME
	wait = DIRECTOR_WAIT

	/// Все зарегистрированные действия (события + midround/latejoin рулсеты)
	var/list/datum/director_action/actions = list()
	/// Запущенные события (тикаются в fire() наравне с рулсетами)
	var/list/running = list()
	var/list/currentrun = list()
	/// Кошельки бюджета по ступеням (severity -> очки). Капля раскладывается по ним пропорционально
	/// profile.pool_shares в accumulate_drip: дешёвые MINOR/MODERATE не осушают общий бюджет,
	/// а MAJOR/ANTAG стабильно копят на свой cost.
	var/list/budgets = list(
		DIRECTOR_SEVERITY_FLAVOR = 0,
		DIRECTOR_SEVERITY_MINOR = 0,
		DIRECTOR_SEVERITY_MODERATE = 0,
		DIRECTOR_SEVERITY_MAJOR = 0,
		DIRECTOR_SEVERITY_ANTAG = 0,
		DIRECTOR_SEVERITY_GHOST = 0,
	)
	/// Активный профиль темпа
	var/datum/director_profile/profile
	/// Пауза от админа: капля и биты стоят, раннер событий работает
	var/paused = FALSE
	/// Ступени, запрещённые к выбору админом с панели (DIRECTOR_SEVERITY_*)
	var/list/blocked_severities = list()
	/// Режим "Summon Events"
	var/wizardmode = FALSE
	/// Счётчик файров до бита
	var/fires_until_beat = DIRECTOR_BEAT_EVERY
	/// world.time последнего запуска на каждую ступень (spacing)
	var/list/last_fired_at = list()
	/// Отдельно для тяжёлых антагов из экипажа (ANTAG)
	var/last_antag_heavy_at = 0
	/// world.time последней латеджойн-инжекции: у латеджойн-канала свой трек спейсинга,
	/// не пересекающийся с полосой битов (латеджойн не должен запирать биты и наоборот)
	var/last_latejoin_at = 0
	/// Отдельно для тяжёлых гост-антагов (GHOST): треки категорий полностью независимы
	var/last_ghost_heavy_at = 0
	/// world.time последнего успешного запуска вообще (для global_spacing)
	var/last_any_fired_at = 0
	/// world.time последнего запуска реального контента (не FLAVOR и не филлер): таймер тишины
	/// гарантированного бита. Флейвор и пустышки не должны маскировать мёртвый эфир - в проде
	/// капающий раз в 5 минут флейвор бесконечно откладывал гарантию.
	var/last_real_fired_at = 0
	/// Счётчик запусков по семействам действий (director_action.family) за раунд: общий фолл-офф повторов
	var/list/family_fired_counts = list()
	/// world.time последнего запуска на каждое семейство (пауза profile.family_spacing)
	var/list/family_last_fired_at = list()
	/// Активные вклады intensity: список list(name, amount, expires_at или 0 если "пока живо", severity или null для внешних вкладов)
	var/list/intensity_ledger = list()
	/// Успешные ghost-role события: ассоциативные записи с minds/weakref мобов. Их вклад
	/// существует по факту жизни созданных ролей, а не фиксированные 30-45 минут после спавнера.
	var/list/live_ghost_role_spawns = list()
	/// Счётчик запусков по ступеням за раунд (для share_correction)
	var/list/fired_counts = list()
	/// Кулдаун быстрых wizard-битов
	var/next_wizard_beat = 0
	/// Форс-события праздников (weight < 0) уже разобраны в этом раунде
	var/holiday_forced_done = FALSE
	/// Сигналы последнего бита (для панели)
	var/datum/director_signals/last_signals
	/// Кэш дефицита антаг-нагрузки (0..1): antag_load() обходит все действия, а капля тикает каждые
	/// 2 секунды - дефицит пересчитывается раз в бит (collect_signals), между битами стабилен.
	var/last_antag_deficit = 1
	/// Копилка антаг-пулов: severity -> действие, на которое пул копит кошелёк. Цель выбирается
	/// взвешенным роллом БЕЗ оглядки на кошелёк (roll_pool_target) - иначе дешёвые действия
	/// выжигали бы кошелёк раньше, чем дорогие вообще становились доступны, и нюк-асолт за 20
	/// не случался бы никогда при живом автотрейторе за 8.
	var/list/pool_saving = list()
	/// Копилка: severity -> ассоц-список имён действий, доступных на момент выбора цели.
	/// Рост набора (появился новый валидный вариант) перевыбирает цель: план, зафиксированный
	/// в бедном пуле первых минут (один Devil без earliest_start), не должен доживать до
	/// исполнения со 100%-роллом, когда к 20-й минуте открылась дюжина альтернатив.
	var/list/pool_target_options = list()
	/// Действие -> world.time конца короткого карантина после фактического провала.
	var/list/action_failure_cooldowns = list()
	/// Действие -> снимок пейсинга до note_fired(). Нужен, пока асинхронный рулсет/ghost poll
	/// не подтвердит, что контент действительно появился.
	var/list/action_attempt_rollbacks = list()
	/// Отсев кандидатов последнего боевого бита: severity -> (DIRECTOR_REJECT_* -> счётчик) (для панели)
	var/list/last_reject_stats
	/// Кэш живой оценки пула (evaluate_pool) и время его сборки
	var/list/pool_cache
	var/pool_cache_at = 0
	/// TRUE на время оценки пула панелью: контент-код (acceptable автотрейтора) не должен
	/// логировать свои отказы при каждой перерисовке - это не решение директора
	var/quiet_eval = FALSE
	/// Действие, ожидающее окно отмены (MODERATE+)
	var/datum/director_action/pending_action
	/// Список кандидатов, из которых было выбрано pending_action (для reroll)
	var/list/pending_candidates
	/// guaranteed-флаг pending_action (для источника лога/note_fired)
	var/pending_guaranteed = FALSE
	/// ID таймера отложенного запуска pending_action
	var/pending_timer_id
	/// Снапшот сигналов момента выбора pending_action (last_signals мутируется on_latejoin внутри окна)
	var/datum/director_signals/pending_signals
	/// Подмена world.time для оффлайн-симулятора (director_simulator.dm): 0 значит "часы реальные".
	/// Все расчёты бита в этом файле идут через now(), а не через world.time напрямую.
	var/time_override = 0
	/// Режим симуляции: spend_and_execute() только учитывает бюджет/spacing/intensity, не запускает
	/// действие взаправду; окно отмены (announce_pick) и форс-праздники (run_forced_events) обходятся.
	var/dry_run = FALSE
	/// Ступень и тяжесть последнего запуска - для лога симулятора (боевая логика не читает).
	var/sim_last_severity = null
	var/sim_last_antag_heavy = FALSE
	/// Троттлинг лога тяжёлых тиков: имя события -> world.time, с которого можно писать снова
	var/list/heavy_tick_log_at = list()

/datum/controller/subsystem/director/Initialize(start_timeofday)
	register_event_actions()
	last_any_fired_at = now()
	last_real_fired_at = now()
	return ..()

/// Текущее время бита. Симулятор двигает time_override вперёд без реального ожидания;
/// в боевом режиме (time_override == 0) ведёт себя как обычный world.time.
/datum/controller/subsystem/director/proc/now()
	return time_override || world.time

/datum/controller/subsystem/director/proc/register_event_actions()
	for(var/type in typesof(/datum/round_event_control))
		var/datum/round_event_control/event_control = new type()
		if(!event_control.typepath)
			continue
		actions += event_control

/datum/controller/subsystem/director/proc/register_ruleset_actions(list/datum/dynamic_ruleset/rules)
	for(var/datum/dynamic_ruleset/rule as anything in rules)
		actions += rule
	// load_config() в pre_setup отрабатывает ДО регистрации рулсетов (setup_profile внутри
	// generate_threat), поэтому секция actions конфига их не видела - доприменяем из кэша.
	if(!islist(cached_config))
		return
	var/list/actions_conf = cached_config["actions"]
	if(!islist(actions_conf))
		return
	for(var/datum/dynamic_ruleset/rule as anything in rules)
		var/list/action_conf = actions_conf[rule.action_name()]
		if(islist(action_conf))
			apply_action_config(rule, action_conf)

/// Все событийные действия (реестр round_event_control)
/datum/controller/subsystem/director/proc/event_controls()
	var/list/result = list()
	for(var/datum/director_action/action as anything in actions)
		if(action.director_kind == DIRECTOR_KIND_EVENT)
			result += action
	return result

/// Выбор профиля на старте раунда (зовёт dynamic после установки GLOB.round_type)
/datum/controller/subsystem/director/proc/setup_profile()
	profile = director_profile_for(GLOB.round_type)
	log_game("DIRECTOR: профиль [profile.type] для [GLOB.round_type]")
	load_config()
	// Стартовый аванс кошельков: с нулевыми кошельками первое MODERATE набиралось только
	// к ~25 минуте, а тяжёлые ступени голодали часами. Аванс раскладывается по долям профиля
	// ПОСЛЕ конфига (доли могли быть переопределены) и просто сдвигает первую половину часа.
	distribute_to_budgets(profile.initial_grant)
	// Аванс антаг-кошельков поверх общей доли: дефицит-капля при живых, но тихих
	// раундстартерах набирала первую гост-роль только к ~25-й минуте (прод-раунд) -
	// аванс сдвигает первый гост-контент к открытию его earliest_start.
	feed_antag_pools(profile.antag_initial_grant)

/datum/controller/subsystem/director/fire(resumed = FALSE)
	if(!resumed)
		if(!paused && profile && SSticker.HasRoundStarted())
			accumulate_drip()
			fires_until_beat--
			if(wizardmode && next_wizard_beat < now())
				wizard_beat()
			else if(fires_until_beat <= 0)
				fires_until_beat = DIRECTOR_BEAT_EVERY
				var/datum/director_signals/signals = collect_signals()
				run_beat(signals)
		currentrun = running.Copy()
		// Бит (fires_until_beat == 0) сам мог съесть тик - раннер событий получает свежий слайс,
		// иначе спайк бита и тяжёлый tick() события складываются в один и тот же игровой тик.
		if(MC_TICK_CHECK)
			return
	var/list/current = currentrun
	while(current.len)
		var/datum/round_event/thing = current[current.len]
		current.len--
		if(thing)
			var/started_at = world.time
			var/usage_before = TICK_USAGE
			thing.process(wait * 0.1)
			// Атрибуция статтеров: tick() события исполняется атомарным куском, и раннер не может
			// его прервать - но может назвать виновника. При сне внутри process() (CHECK_TICK
			// в start() сканов) дельта TICK_USAGE через тики бессмысленна - такой запуск не меряем.
			if(world.time == started_at)
				var/usage = TICK_USAGE - usage_before
				if(usage >= DIRECTOR_EVENT_HEAVY_TICK_USAGE)
					log_heavy_event_tick(thing, usage)
		else
			running.Remove(thing)
		if(MC_TICK_CHECK)
			return

/// Лог тяжёлого тика события с троттлингом по имени: прод-жалоба "статтерит раз в 2 секунды"
/// должна раскрываться грепом game.log по DIRECTOR HEAVY, а не VV-раскопками running.
/datum/controller/subsystem/director/proc/log_heavy_event_tick(datum/round_event/event, usage)
	var/event_name = event.control ? event.control.name : "[event.type]"
	if(world.time < heavy_tick_log_at[event_name])
		return
	heavy_tick_log_at[event_name] = world.time + DIRECTOR_EVENT_HEAVY_LOG_COOLDOWN
	log_game("DIRECTOR HEAVY: тик события [event_name] съел [round(TICK_DELTA_TO_MS(usage), 0.1)]мс ([round(usage)]% тика)")

/datum/controller/subsystem/director/proc/accumulate_drip()
	var/datum/director_signals/quick = last_signals || collect_signals()
	// Пустая станция: бюджет не копится, иначе первый вернувшийся экипаж встречала бы
	// очередь накоплений за все пустые часы.
	if(quick.effective_crew <= 0)
		return
	var/minutes = (now() - SSticker.round_start_time) / (1 MINUTES)
	var/dead_crisis = quick.dead_fraction > profile.dead_fraction_threshold
	var/rate = profile.base_drip * piecewise_eval(profile.time_curve, minutes) * piecewise_eval(profile.pop_curve, quick.effective_crew)
	// Антаг-кошельки живут НЕ на доле событийной капли, а на собственном дефицит-потоке:
	// пустой от антагов раунд наполняется со скоростью antag_drip, насыщенный не копит вовсе.
	// Прежняя схема (доля 0.12-0.15 от общей капли с клапаном-перераспределением) давала
	// ~0.15 очка/мин - одна лёгкая инжекция в час на 30+ экипажа, тяжёлые не набирались никогда.
	var/antag_rate = profile.antag_drip * last_antag_deficit
	if(dead_crisis)
		rate *= 0.5
		antag_rate *= 0.5
	var/step = wait / (1 MINUTES)
	distribute_to_budgets(rate * step, include_antag_pools = FALSE)
	feed_antag_pools(antag_rate * step)

/// Суммарная живая антаг-нагрузка: динамический вклад рулсетов (мидраунд + раундстарт с затуханием)
/// плюс не вытесненные ими записи антаг-пулов в ledger (мосты запланированных инжекций,
/// гост-антаг события). Общая валюта клапана давления, гейта латеджойна и гейта насыщения в битах.
/// В breakdown (если передан) untracked-источник добавляет свою строку для панели.
/datum/controller/subsystem/director/proc/antag_load(list/breakdown = null)
	var/list/live_names = list()
	var/list/counted_minds = list()
	. = get_ruleset_intensity(live_names, counted_minds = counted_minds)
	. += get_ghost_role_intensity(live_names, only_antag = TRUE, counted_minds = counted_minds)
	for(var/list/entry in intensity_ledger)
		if(DIRECTOR_IS_ANTAG_POOL(entry[4]) && !live_names[entry[1]] && (!entry[3] || entry[3] > now()))
			. += entry[2]
	// Третий источник нагрузки: живые антаги без рулсета/гост-ролью (админ/жетон, спавнеры карт,
	// обращённые). Дедуп против counted_minds, чтобы не задвоить уже посчитанных рулсетами.
	. += get_untracked_antag_intensity(counted_minds, breakdown)

/// Живые жёсткие антаги, которых директор не создавал и не отслеживает: выданные админом или
/// жетоном (как еретик из прод-раунда), спавнеры карт, обращённые культом/ревами. Клапан
/// антаг-давления обязан их видеть - иначе директор считает раунд недогруженным и льёт ещё
/// антагов поверх реальных. counted_minds - разумы, уже учтённые рулсетами и гост-ролями (дедуп).
/// is_active_antag_mind уже отсекает soft_antag, мёртвых и пойманных (перма/гулаг).
/// В breakdown (если передан) добавляется строка list(имя, вклад, голов) - без неё панель
/// показывала прод-раунду Families 70+ нагрузки от вербовки при пустых "Активных вкладах".
/datum/controller/subsystem/director/proc/get_untracked_antag_intensity(list/counted_minds, list/breakdown = null)
	var/total = 0
	var/list/seen = list()
	var/list/names = list()
	for(var/datum/antagonist/antag as anything in GLOB.antagonists)
		var/datum/mind/antag_mind = antag.owner
		// Один разум может держать несколько антаг-датумов - считаем его один раз.
		if(!istype(antag_mind) || seen[antag_mind])
			continue
		if(counted_minds && counted_minds[antag_mind])
			continue
		if(!is_active_antag_mind(antag_mind))
			continue
		seen[antag_mind] = TRUE
		// Не на станции - не давит на раунд: токен-антаг, засевший на шахтёрском уровне,
		// или улетевшая команда не должны глушить клапан (прод-жалоба "нагрузка есть,
		// антагов не видно"). Вернётся на станцию - вклад вернётся тем же битом.
		var/turf/location = get_turf(antag_mind.current)
		if(!location || !is_station_level(location.z))
			continue
		// Затухание по возрасту, как у рулсетов: часовой токен-антаг оседает к полу так же,
		// как старый раундстарт. Точка отсчёта штампуется при первой встрече (с точностью
		// до бита совпадает с выдачей роли); симулятор (time_override) живой mind не трогает -
		// оффлайн-прогон записывал бы в раунд будущие таймштампы.
		var/untracked_since = antag_mind.director_untracked_since || now()
		if(!antag_mind.director_untracked_since && !time_override)
			antag_mind.director_untracked_since = untracked_since
		var/decay = ruleset_intensity_decay(untracked_since)
		total += DIRECTOR_UNTRACKED_ANTAG_INTENSITY * decay * antag_activity_mult(antag_mind)
		names += antag_mind.current.real_name || antag_mind.name
	if(total && !isnull(breakdown))
		breakdown += list(list(untracked_source_label(names), total, length(names)))
	return total

/// Подпись строки untracked-вкладов: до четырёх имён прямо в панели ("от кого нагрузка"),
/// дальше свёртка. Безымянная строка заставляла админов гадать, кто держит клапан.
/datum/controller/subsystem/director/proc/untracked_source_label(list/names)
	if(!length(names))
		return DIRECTOR_UNTRACKED_SOURCE_NAME
	var/shown_count = min(length(names), 4)
	var/list/shown = names.Copy(1, shown_count + 1)
	var/label = "[DIRECTOR_UNTRACKED_SOURCE_NAME]: [jointext(shown, ", ")]"
	if(length(names) > shown_count)
		label += " и ещё [length(names) - shown_count]"
	return label

/// Целевая антаг-нагрузка раунда: масштабируется от живого экипажа, а не от фиксированного
/// потолка intensity. 3 стелс-антага - норма на 20 экипажа и голод на 60 телах.
/datum/controller/subsystem/director/proc/antag_target(crew)
	return crew * profile.antag_intensity_per_crew

/// Актуализация копилок антаг-пулов: у пула без цели (или с протухшей - can_fire отвалился,
/// например кончились кандидаты-призраки, либо живой вес затух до нуля) роллится новая.
/// Валидная цель не перевыбирается - пул последовательно копит и исполняет план.
/datum/controller/subsystem/director/proc/ensure_pool_targets(datum/director_signals/signals)
	// Контент-код (can_fire) не должен логировать отказы при проверке плана - это не решение о запуске.
	quiet_eval = TRUE
	for(var/sev in list(DIRECTOR_SEVERITY_ANTAG, DIRECTOR_SEVERITY_GHOST))
		var/datum/director_action/target = pool_saving[sev]
		// Живой вес - часть валидности плана: у действий с изменяемым весом условие может
		// пропасть уже после выбора цели (вес Lone Operative затухает, когда диск снова
		// носят - nuclearbomb.dm). План с нулевым весом висел бы до исполнения, и оперативник
		// приходил бы спустя полчаса после того, как диск унесли, - "спавн без причины".
		if(QDELETED(target) || action_recently_failed(target) || !target.can_fire(signals) || !action_preflight(target) || target.get_weight(signals) <= 0)
			roll_pool_target(sev, signals)
			continue
		// Цель валидна, но пул мог вырасти: план, взятый из одного-двух ранних вариантов
		// (прод-жалоба "в харду каждый раунд дьявол"), перевыбирается честным роллом,
		// как только появляется вариант, которого не было на момент выбора.
		var/list/options = collect_pool_options(sev, signals)
		if(pool_options_grew(sev, options))
			roll_pool_target(sev, signals, precollected_options = options)
	quiet_eval = FALSE

/// Валидные цели накопления пула с весами (без гейта бюджета - см. roll_pool_target).
/// Латеджойн-рулсеты целью не становятся: они стреляют только в окно захода игрока,
/// такая цель заморозила бы пул до случайного латеджойна.
/datum/controller/subsystem/director/proc/collect_pool_options(sev, datum/director_signals/signals)
	var/list/options = list()
	for(var/datum/director_action/action as anything in actions)
		if(action.severity != sev)
			continue
		if(istype(action, /datum/dynamic_ruleset/latejoin))
			continue
		// Гейт filter_candidates: выключенная профилем тяжесть не должна становиться целью
		// накопления - пул заморозился бы на неисполнимом плане.
		if(action.antag_heavy && !profile.antag_heavy_enabled)
			continue
		// Цель выбирается и на cooldown: её стоимость остаётся защищённым резервом, а готовый
		// соседний трек может тратить только излишек сверх резерва (см. filter_candidates).
		// Иначе дешёвые роли съедали бы кошелёк до того, как heavy вообще накопит свою цену.
		if(action_recently_failed(action))
			continue
		if(!action.can_fire(signals))
			continue
		if(!action_preflight(action))
			continue
		var/action_weight = action.get_weight(signals) * repeat_falloff(action) * profile.disruption_mult(action)
		if(action_weight > 0)
			options[action] = max(1, round(action_weight * 100))
	return options

/// TRUE, если среди options есть действие, которого не было в наборе на момент выбора цели.
/// Набор без записи (цель ставилась до включения механизма/руками) считается не выросшим.
/datum/controller/subsystem/director/proc/pool_options_grew(sev, list/options)
	var/list/known = pool_target_options[sev]
	if(!islist(known))
		return FALSE
	for(var/datum/director_action/action as anything in options)
		if(!known[action.action_name()])
			return TRUE
	return FALSE

/// Взвешенный ролл цели накопления пула по всем валидным действиям, БЕЗ гейта бюджета.
/// max_cost (замена после провала/отказа админа): цель только по средствам - обещанная замена
/// должна случиться сейчас, а не "когда докапает"; при пустом отборе цель НЕ перезаписывается,
/// вызывающий решает, откатываться ли на неограниченный ролл.
/datum/controller/subsystem/director/proc/roll_pool_target(sev, datum/director_signals/signals, max_cost = null, list/precollected_options = null)
	var/list/options = precollected_options || collect_pool_options(sev, signals)
	if(!isnull(max_cost))
		var/list/affordable = list()
		for(var/datum/director_action/option as anything in options)
			if(option.cost <= max_cost)
				affordable[option] = options[option]
		if(!length(affordable))
			return null
		options = affordable
	var/list/known = list()
	for(var/datum/director_action/option as anything in options)
		known[option.action_name()] = TRUE
	pool_target_options[sev] = known
	pool_saving[sev] = length(options) ? pickweight(options) : null
	return pool_saving[sev]

/// Неинтерактивная проверка второй ступени готовности (кандидаты, контрроли, точки спауна).
/// null от действия означает, что отдельной проверки у него нет.
/datum/controller/subsystem/director/proc/action_preflight(datum/director_action/action)
	var/result = action.director_preflight()
	return isnull(result) ? TRUE : result

/// Точный неинтерактивный аналог фильтра до ghost poll: способен вернуться в раунд,
/// подключён, включил нужную роль и не имеет соответствующего/InteQ-бана.
/datum/controller/subsystem/director/proc/count_eligible_ghosts(jobban_type = null, preference_flag = null)
	var/count = 0
	for(var/mob/candidate as anything in get_all_ghost_role_eligible(priority_only = FALSE))
		if(!candidate.key || !candidate.client)
			continue
		if(preference_flag && (!(candidate.client.prefs) || !(preference_flag in candidate.client.prefs.be_special)))
			continue
		if(jobban_type && (jobban_isbanned(candidate, jobban_type) || jobban_isbanned(candidate, ROLE_INTEQ)))
			continue
		count++
	return count

/datum/controller/subsystem/director/proc/ghost_event_preflight(datum/round_event_control/control)
	var/eligible = count_eligible_ghosts(control.director_ghost_jobban, control.director_ghost_preference)
	var/role_text = control.director_ghost_preference ? " для роли [control.director_ghost_preference]" : ""
	control.director_preflight_detail = "подходящих гостов: [eligible], требуется: [control.director_ghost_minimum][role_text]"
	if(eligible < control.director_ghost_minimum)
		control.director_preflight_failure = "подходящих гостов [eligible] из [control.director_ghost_minimum][role_text] (роль, бан или таймаут возврата)"
		return FALSE
	control.director_preflight_failure = null
	return TRUE

/datum/controller/subsystem/director/proc/action_recently_failed(datum/director_action/action)
	var/until = action_failure_cooldowns[action]
	if(!until)
		return FALSE
	if(until <= now())
		action_failure_cooldowns -= action
		return FALSE
	return TRUE

/// Дефицит антаг-нагрузки (0..1) - скорость антаг-капли пропорциональна ему: пустой от антагов
/// раунд (все выбыли или залегли) наполняет кошельки полным ходом, насыщенный не копит вовсе
/// (иначе кошелёк растёт в стену гейта насыщения и разом выливается позже).
/datum/controller/subsystem/director/proc/antag_deficit(crew)
	var/target = antag_target(crew)
	if(target <= 0)
		return 0
	return clamp(1 - antag_load() / target, 0, 1)

/// Сумма всех кошельков - "общий бюджет" для отчётов, панели и лога.
/datum/controller/subsystem/director/proc/total_budget()
	var/sum = 0
	for(var/sev in budgets)
		sum += budgets[sev]
	return sum

/// Обнуляет (или заполняет value) все кошельки. Для симулятора и юнит-тестов.
/datum/controller/subsystem/director/proc/reset_budgets(value = 0)
	budgets = list(
		DIRECTOR_SEVERITY_FLAVOR = value,
		DIRECTOR_SEVERITY_MINOR = value,
		DIRECTOR_SEVERITY_MODERATE = value,
		DIRECTOR_SEVERITY_MAJOR = value,
		DIRECTOR_SEVERITY_ANTAG = value,
		DIRECTOR_SEVERITY_GHOST = value,
	)

/// Раскладывает amount по кошелькам ступеней в пропорции profile.pool_shares.
/// FLAVOR стоит 0 и на бюджет не гейтится (budgets[FLAVOR] бесполезен как кошелёк), поэтому его
/// долю раздаём поровну между остальными ненулевыми ступенями - капля/донат/дельта не теряются.
/// amount может быть отрицательным (кнопка "-бюджет"): каждый кошелёк клампится на нуле.
/// include_antag_pools = FALSE - раздача только по событийным ступеням (MINOR..MAJOR): так живёт
/// событийная капля, у антаг-кошельков собственный дефицит-поток (feed_antag_pools). Разовые
/// вливания (initial_grant, донаты динамика, кнопка админа) раздаются по всем кошелькам.
/datum/controller/subsystem/director/proc/distribute_to_budgets(amount, include_antag_pools = TRUE)
	if(!profile || !amount)
		return
	var/list/shares = profile.pool_shares
	var/list/active_sevs = list()
	var/list/effective_shares = list()
	var/flavor_share = 0
	for(var/sev in shares)
		if(sev == DIRECTOR_SEVERITY_FLAVOR)
			flavor_share = shares[sev]
			continue
		if(!include_antag_pools && DIRECTOR_IS_ANTAG_POOL(sev))
			continue
		var/share = shares[sev]
		if(share > 0)
			active_sevs += sev
			effective_shares[sev] = share
	if(!length(active_sevs))
		return
	var/flavor_bonus = flavor_share / length(active_sevs)
	var/total_share = flavor_share
	for(var/sev in active_sevs)
		total_share += effective_shares[sev]
	for(var/sev in active_sevs)
		budgets[sev] = max(0, budgets[sev] + amount * (effective_shares[sev] + flavor_bonus) / total_share)

/// Прямое пополнение антаг-кошельков (дефицит-капля, событие фондирования): amount делится
/// между ANTAG и GHOST в пропорции их pool_shares. Профиль без антаг-долей (экипажная ступень
/// Extended) отдаёт всё живой из двух; без обеих - раздача не происходит вовсе.
/datum/controller/subsystem/director/proc/feed_antag_pools(amount)
	if(!profile || amount <= 0)
		return
	var/antag_share = profile.pool_shares[DIRECTOR_SEVERITY_ANTAG] || 0
	var/ghost_share = profile.pool_shares[DIRECTOR_SEVERITY_GHOST] || 0
	var/total_share = antag_share + ghost_share
	if(total_share <= 0)
		return
	budgets[DIRECTOR_SEVERITY_ANTAG] += amount * antag_share / total_share
	budgets[DIRECTOR_SEVERITY_GHOST] += amount * ghost_share / total_share

/// Возврат средств в кошелёк конкретной ступени (провал запуска, refund_threat рулсета).
/datum/controller/subsystem/director/proc/refund_to_budget(severity, amount)
	if(amount <= 0)
		return
	budgets[severity] = max(0, budgets[severity] + amount)

/datum/controller/subsystem/director/proc/collect_signals()
	var/datum/director_signals/signals = new
	signals.update()
	signals.active_intensity = get_active_intensity()
	signals.event_intensity = get_event_intensity()
	last_antag_deficit = antag_deficit(signals.effective_crew)
	last_signals = signals
	return signals

/// Динамический вклад живых ANTAG-рулсетов: intensity рулсета * доля активных назначенных.
/// Рулсеты не держат постоянных записей в intensity_ledger: вырезанные антаги
/// не должны глушить директора до конца раунда. Опционально помечает имена живых рулсетов в
/// live_names - их временные мосты в ledger вытесняются этим расчётом. В breakdown (если передан)
/// складываются строки list(имя, вклад, живых, назначено) - панель показывает их рядом с ledger.
/datum/controller/subsystem/director/proc/get_ruleset_intensity(list/live_names = null, list/breakdown = null, list/counted_minds = null)
	var/total = 0
	for(var/datum/director_action/action as anything in actions)
		if(action.director_kind != DIRECTOR_KIND_RULESET)
			continue
		var/datum/dynamic_ruleset/rule = action
		if(rule.occurrences <= 0 || !length(rule.assigned))
			continue
		total += tally_ruleset_intensity(rule, live_names, breakdown, counted_minds)
	// Раундстартовые рулсеты в actions не регистрируются (их пул кандидатов держит ссылки на
	// new_player и должен освободиться после старта), но исполненные живут в executed_rules
	// динамика весь раунд. Их живые антаги нагружают intensity наравне с мидраундами.
	// istype-фильтр цикла заодно отсекает midround/latejoin из executed_rules - те уже
	// посчитаны выше через actions.
	var/datum/game_mode/dynamic/mode = SSticker.mode
	if(istype(mode))
		for(var/datum/dynamic_ruleset/roundstart/rule in mode.executed_rules)
			if(!length(rule.assigned))
				continue
			total += tally_ruleset_intensity(rule, live_names, breakdown, counted_minds)
	return total

/// Множитель затухания вклада рулсета по возрасту его исполнения: полный до
/// DIRECTOR_RULESET_DECAY_FULL_TIME, затем линейно вниз до пола к DIRECTOR_RULESET_DECAY_END.
/// Старый антаг (раундстарт или давняя инжекция), закрывший цели и залёгший, не глушит
/// директора до конца смены - его слот нагрузки освобождается под новые волны.
/datum/controller/subsystem/director/proc/ruleset_intensity_decay(fired_at)
	var/age = now() - fired_at
	if(age <= DIRECTOR_RULESET_DECAY_FULL_TIME)
		return 1
	var/fade = (age - DIRECTOR_RULESET_DECAY_FULL_TIME) / (DIRECTOR_RULESET_DECAY_END - DIRECTOR_RULESET_DECAY_FULL_TIME)
	return max(DIRECTOR_RULESET_DECAY_FLOOR, 1 - (1 - DIRECTOR_RULESET_DECAY_FLOOR) * fade)

/// Вклад одного исполненного рулсета: intensity * затухание по возрасту исполнения * сумма
/// множителей активности живых назначенных / всего назначено. Тихоня весит
/// DIRECTOR_ACTIVITY_MULT_MIN своей доли, буйный (перестрелки, убийства, розыск) - до
/// DIRECTOR_ACTIVITY_MULT_MAX: "антаг, занявший всё СБ" насыщает клапан как полтора-два обычных,
/// а стелсер, за час никак не проявившийся, оставляет директору место. Возраст раундстартов
/// (executed_at = 0) считается от старта раунда, инжекций - от их запуска (штамп в note_fired).
/// Заодно добавляет строку разбивки для панели и помечает имя в live_names (см. get_ruleset_intensity).
/datum/controller/subsystem/director/proc/tally_ruleset_intensity(datum/dynamic_ruleset/rule, list/live_names, list/breakdown, list/counted_minds = null)
	. = 0
	refund_lost_ruleset_antags(rule)
	var/living = 0
	var/activity_sum = 0
	for(var/datum/mind/assigned_mind as anything in rule.assigned)
		if(istype(assigned_mind) && is_active_antag_mind(assigned_mind))
			living++
			activity_sum += antag_activity_mult(assigned_mind)
			if(!isnull(counted_minds))
				counted_minds[assigned_mind] = TRUE
	if(living)
		var/decay = ruleset_intensity_decay(rule.executed_at || SSticker.round_start_time)
		. = rule.intensity * decay * activity_sum / length(rule.assigned)
		if(!isnull(breakdown))
			breakdown += list(list(rule.action_name(), ., living, length(rule.assigned)))
	if(!isnull(live_names))
		live_names[rule.action_name()] = TRUE

/// Считается ли назначенный рулсетом разум действующей угрозой: жив, всё ещё держит хотя бы один
/// жёсткий (не soft_antag) антаг-датум (деконверсия и снятие роли обнуляют угрозу) и не пойман
/// (пермабриг/гулаг не двигают раунд). Окно "assigned наполнен, датум ещё не выдан" у отложенных
/// рулсетов (revs) даёт недоучёт на минуты - их intensity прикрыта мостом/ранним раундом.
/datum/controller/subsystem/director/proc/is_active_antag_mind(datum/mind/assigned_mind)
	var/mob/current_mob = assigned_mind.current
	if(!current_mob || current_mob.stat == DEAD)
		return FALSE
	if(!is_hard_antag_mind(assigned_mind))
		return FALSE
	var/area/current_area = get_area(current_mob)
	if(istype(current_area, /area/security/prison) || istype(current_area, /area/mine/laborcamp))
		return FALSE
	return TRUE

/// Держит ли разум хотя бы один жёсткий (не soft_antag) антаг-датум.
/datum/controller/subsystem/director/proc/is_hard_antag_mind(datum/mind/checked_mind)
	for(var/datum/antagonist/antag as anything in checked_mind.antag_datums)
		if(!antag.soft_antag)
			return TRUE
	return FALSE

/// Окончательная потеря роли, в отличие от временного обезвреживания: смерть/удаление тела,
/// крио или снятие последнего жёсткого антаг-датума. Перма и гулаг освобождают intensity,
/// но страховку не выплачивают — заключённый ещё может вернуться в игру.
/datum/controller/subsystem/director/proc/is_terminal_antag_loss(datum/mind/checked_mind)
	var/mob/current_mob = checked_mind?.current
	if(!current_mob || current_mob.stat == DEAD)
		return TRUE
	return !is_hard_antag_mind(checked_mind)

/// Неотработанная доля индивидуальной страховки. policy хранит цену, время выдачи роли и
/// накопленную активность mind на тот момент, поэтому повторная роль того же игрока считается с нуля.
/datum/controller/subsystem/director/proc/antag_loss_refund_value(list/policy, activity_total = 0)
	if(!islist(policy) || !profile || profile.antag_loss_refund_window <= 0 || profile.antag_loss_activity_threshold <= 0)
		return 0
	var/age = now() - policy["at"]
	if(age < 0 || age > profile.antag_loss_refund_window)
		return 0
	var/activity = max(0, activity_total - (policy["activity"] || 0))
	var/unworked_fraction = clamp(1 - activity / profile.antag_loss_activity_threshold, 0, 1)
	return (policy["amount"] || 0) * unworked_fraction

/// Направляет страховую выплату только в два антаг-кошелька. Так исчезнувшего экипажного
/// антага можно заменить гост-ролью, если живых кандидатов в текущем раунде уже нет.
/datum/controller/subsystem/director/proc/grant_antag_loss_refund(source_name, amount, lost_count)
	if(amount <= 0)
		return 0
	var/before = budgets[DIRECTOR_SEVERITY_ANTAG] + budgets[DIRECTOR_SEVERITY_GHOST]
	feed_antag_pools(amount)
	var/granted = budgets[DIRECTOR_SEVERITY_ANTAG] + budgets[DIRECTOR_SEVERITY_GHOST] - before
	if(granted <= 0)
		return 0
	pool_cache = null
	var/shown = round(granted, 0.1)
	message_admins("DIRECTOR: страховка [source_name] вернула [shown] бюджета за раннюю потерю ролей ([lost_count]).")
	log_game("DIRECTOR: страховка [source_name] вернула [shown] бюджета за раннюю потерю ролей ([lost_count])")
	return granted

/// Одноразово страхует каждую подтверждённо выданную рулсетом роль. Стоимость уже разделена
/// confirm_action_success() между новыми assigned, поэтому масштабированные и повторные рулсеты
/// возвращают ровно свою фактически потраченную долю, а не текущий cost на глаз.
/datum/controller/subsystem/director/proc/refund_lost_ruleset_antags(datum/dynamic_ruleset/rule)
	if(!length(rule.director_loss_refund_values))
		return 0
	var/refund = 0
	var/lost_count = 0
	for(var/datum/mind/assigned_mind as anything in rule.assigned)
		var/list/policy = rule.director_loss_refund_values[assigned_mind]
		if(!islist(policy) || !is_terminal_antag_loss(assigned_mind))
			continue
		// Сначала закрываем полис: даже полная выплата не повторится после воскрешения/новой смерти,
		// а слишком поздняя или уже отработанная роль тоже не будет проверяться бесконечно.
		rule.director_loss_refund_values -= assigned_mind
		rule.director_loss_accounted[assigned_mind] = TRUE
		lost_count++
		refund += antag_loss_refund_value(policy, assigned_mind.director_activity_total)
	return grant_antag_loss_refund(rule.action_name(), refund, lost_count)

/// Текущий score активности антага с ленивым затуханием: полураспад DIRECTOR_ACTIVITY_HALF_LIFE,
/// сам score на mind не переписывается (перезапись - только в bump_antag_activity).
/datum/controller/subsystem/director/proc/antag_activity(datum/mind/checked_mind)
	if(!checked_mind.director_activity)
		return 0
	var/dt = now() - checked_mind.director_activity_at
	if(dt <= 0)
		return checked_mind.director_activity
	return checked_mind.director_activity * (2 ** (-dt / DIRECTOR_ACTIVITY_HALF_LIFE))

/// Множитель вклада антага в intensity по его активности: [MULT_MIN .. MULT_MAX].
/datum/controller/subsystem/director/proc/antag_activity_mult(datum/mind/checked_mind)
	return min(DIRECTOR_ACTIVITY_MULT_MIN + antag_activity(checked_mind) / DIRECTOR_ACTIVITY_MULT_SCALE, DIRECTOR_ACTIVITY_MULT_MAX)

/// Атрибуция шума: контент-код (log_combat, death, розыск) сообщает, что разум проявил себя.
/// Не-антагов игнорирует сам - вызывающим достаточно передать mind без проверок.
/datum/controller/subsystem/director/proc/bump_antag_activity(datum/mind/noisy_mind, amount)
	if(!istype(noisy_mind) || amount <= 0 || !is_hard_antag_mind(noisy_mind))
		return
	noisy_mind.director_activity = min(antag_activity(noisy_mind) + amount, DIRECTOR_ACTIVITY_CAP)
	noisy_mind.director_activity_at = now()
	noisy_mind.director_activity_total += amount

/datum/controller/subsystem/director/proc/get_active_intensity(list/breakdown = null)
	var/list/live_names = list()
	var/total = get_ruleset_intensity(live_names, breakdown)
	total += get_ghost_role_intensity(live_names, breakdown)
	// Итерация по индексам с конца: удаление записи внутри for-in сдвигало бы список
	// и пропускало элемент, следующий за истёкшим (он бы не суммировался в этом вызове).
	for(var/i = length(intensity_ledger), i >= 1, i--)
		var/list/entry = intensity_ledger[i]
		var/expires_at = entry[3]
		if(expires_at && expires_at < now())
			intensity_ledger.Cut(i, i + 1)
			continue
		// Мост рулсета, чей assigned уже наполнен: динамический вклад учтён выше, мост снимаем.
		if(DIRECTOR_IS_ANTAG_POOL(entry[4]) && live_names[entry[1]])
			intensity_ledger.Cut(i, i + 1)
			continue
		total += entry[2]
	return total

/// Видимая (событийная) нагрузка для порога тишины гарантированного бита: сумма живых
/// ledger-записей вне антаг-пулов. Стелс-нагрузка (динамический вклад живых рулсетов и мосты
/// антаг-инжекций) не считается: три скрытных раундстарт-антага дают intensity, но игрокам
/// "ничего не видно" - гарантия обязана продолжать работать.
/datum/controller/subsystem/director/proc/get_event_intensity()
	var/total = get_ghost_role_intensity(only_antag = FALSE)
	for(var/list/entry in intensity_ledger)
		if(DIRECTOR_IS_ANTAG_POOL(entry[4]))
			continue
		if(entry[3] && entry[3] < now())
			continue
		total += entry[2]
	return total

/// Полностью снимает временный вклад конкретного действия, включая уже поставленный на linger.
/// Нужен отложенным гост-ролям: к моменту ответа на poll событие уже могло завершить datum,
/// а его статический мост - получить expires_at, из-за чего remove_intensity() его не трогает.
/datum/controller/subsystem/director/proc/clear_action_intensity(datum/director_action/action)
	if(!action)
		return FALSE
	for(var/i = length(intensity_ledger), i >= 1, i--)
		var/list/entry = intensity_ledger[i]
		if(entry[1] != action.action_name() || entry[4] != action.severity)
			continue
		intensity_ledger.Cut(i, i + 1)
		return TRUE
	return FALSE

/// Перевод успешного отложенного ghost-role действия со статического мостика ledger на реально
/// созданные роли. Mind переживает смену тела, weakref покрывает управляемых мобов без mind.
/// intensity_override/refund_cost_override нужны командным спавнерам: если poll пуст, каждый
/// оставшийся спавнер позже добавляет только свою долю общей нагрузки и страховки команды.
/datum/controller/subsystem/director/proc/track_ghost_role_spawn(datum/director_action/action, list/spawned_mobs, budget_backed = FALSE, intensity_override = null, refund_cost_override = null, log_execution = TRUE)
	if(!action || !length(spawned_mobs))
		return FALSE
	var/list/minds = list()
	var/list/mob_refs = list()
	var/list/hard_minds = list()
	for(var/mob/spawned as anything in spawned_mobs)
		if(QDELETED(spawned))
			continue
		if(spawned.mind)
			minds |= spawned.mind
			if(is_hard_antag_mind(spawned.mind))
				hard_minds |= spawned.mind
		else
			mob_refs += WEAKREF(spawned)
	if(!length(minds) && !length(mob_refs))
		return FALSE
	var/list/refund_values = list()
	var/refund_cost = isnull(refund_cost_override) ? (budget_backed ? action.cost : 0) : refund_cost_override
	if(refund_cost > 0 && DIRECTOR_IS_ANTAG_POOL(action.severity))
		var/share = refund_cost / (length(minds) + length(mob_refs))
		for(var/datum/mind/insured_mind as anything in minds)
			refund_values[insured_mind] = list(
				"amount" = share,
				"at" = now(),
				"activity" = insured_mind.director_activity_total,
			)
		for(var/datum/weakref/insured_ref as anything in mob_refs)
			refund_values[insured_ref] = list("amount" = share, "at" = now(), "activity" = 0)
	clear_action_intensity(action)
	var/tracked_intensity = isnull(intensity_override) ? action.intensity : intensity_override
	live_ghost_role_spawns += list(list(
		"name" = action.action_name(),
		"intensity" = tracked_intensity,
		"severity" = action.severity,
		"minds" = minds,
		"hard_minds" = hard_minds,
		"mobs" = mob_refs,
		"refund_values" = refund_values,
		// Точка отсчёта возрастного затухания вклада (см. get_ghost_role_intensity):
		// гост-команда оседает к полу так же, как старый рулсет или токен-антаг.
		"at" = now(),
	))
	confirm_action_success(action)
	pool_cache = null
	if(log_execution)
		var/assigned_count = length(minds) + length(mob_refs)
		director_log_beat(collect_signals(), action, DIRECTOR_BEAT_EXECUTED,
			detail = "исполнение подтверждено; назначено ролей: [assigned_count]")
	return TRUE

/// Отложенное действие успешно завершилось без антагов (например, станция заплатила рейдерам).
/// Контент состоялся, поэтому бюджет/occurrences не откатываются, но прогноз антаг-нагрузки
/// больше не должен закрывать ANTAG/GHOST-пулы.
/datum/controller/subsystem/director/proc/complete_deferred_action_without_roles(datum/director_action/action, detail)
	if(!action)
		return
	clear_action_intensity(action)
	confirm_action_success(action)
	pool_cache = null
	director_log_beat(collect_signals(), action, DIRECTOR_BEAT_EXECUTED,
		detail = detail || "исполнение завершено без назначенных ролей")

/// Живая нагрузка ghost-role событий. only_antag: null = все для общего intensity,
/// TRUE = только ANTAG/GHOST для клапана антагов, FALSE = только видимые не-антаг события.
/// Антаг-команды считаются как рулсеты: возрастное затухание, множитель активности и
/// скидка за отсутствие на станции - улетевшие с лутом рейдеры не держат полные 45
/// нагрузки до конца смены (прод-раунд: 30 минут запертых антаг-каналов). Не-антаг
/// гост-роли (мирные спавнеры) считаются по-старому: живые головы без модификаторов.
/datum/controller/subsystem/director/proc/get_ghost_role_intensity(list/live_names = null, list/breakdown = null, only_antag = null, list/counted_minds = null)
	var/total = 0
	for(var/i = length(live_ghost_role_spawns), i >= 1, i--)
		var/list/entry = live_ghost_role_spawns[i]
		var/list/minds = entry["minds"]
		var/list/hard_minds = entry["hard_minds"]
		var/list/mob_refs = entry["mobs"]
		var/list/refund_values = entry["refund_values"]
		var/is_antag = DIRECTOR_IS_ANTAG_POOL(entry["severity"])
		var/assigned = length(minds) + length(mob_refs)
		var/living = 0
		var/presence_sum = 0
		var/refund = 0
		var/lost_count = 0
		for(var/datum/mind/assigned_mind as anything in minds)
			var/mob/current = assigned_mind?.current
			var/list/policy = refund_values?[assigned_mind]
			var/role_removed = islist(hard_minds) && (assigned_mind in hard_minds) && !is_hard_antag_mind(assigned_mind)
			if(!current || current.stat == DEAD || role_removed)
				if(islist(policy))
					refund_values -= assigned_mind
					lost_count++
					refund += antag_loss_refund_value(policy, assigned_mind.director_activity_total)
				continue
			living++
			if(is_antag)
				presence_sum += ghost_member_presence(current) * antag_activity_mult(assigned_mind)
			// Дедуп для get_untracked_antag_intensity: разум, уже посчитанный как живая гост-роль,
			// не должен всплыть повторно третьим источником через GLOB.antagonists. Помечаем только
			// разумы записей, вошедших в текущий подсчёт: при only_antag = TRUE мирная гост-роль
			// не считается, и её разум, ставший жёстким антагом, обязан остаться видимым untracked-скану.
			if(!isnull(counted_minds) && (isnull(only_antag) || is_antag == only_antag))
				counted_minds[assigned_mind] = TRUE
		for(var/datum/weakref/mob_ref as anything in mob_refs)
			var/mob/current = mob_ref.resolve()
			if(current && current.stat != DEAD)
				living++
				if(is_antag)
					presence_sum += ghost_member_presence(current)
				continue
			var/list/policy = refund_values?[mob_ref]
			if(islist(policy))
				refund_values -= mob_ref
				lost_count++
				refund += antag_loss_refund_value(policy)
		grant_antag_loss_refund(entry["name"], refund, lost_count)
		if(!assigned || !living)
			live_ghost_role_spawns.Cut(i, i + 1)
			continue
		if(!isnull(only_antag) && is_antag != only_antag)
			continue
		var/amount
		if(is_antag)
			var/decay = ruleset_intensity_decay(entry["at"] || SSticker.round_start_time)
			amount = entry["intensity"] * decay * presence_sum / assigned
		else
			amount = entry["intensity"] * living / assigned
		total += amount
		if(!isnull(breakdown))
			breakdown += list(list(entry["name"], amount, living, assigned))
		if(!isnull(live_names))
			live_names[entry["name"]] = TRUE
	return total

/// Вес присутствия члена гост-команды: на станции - полный, вне её - половина.
/// Симметрия с untracked-антагами: команда, улетевшая с лутом, давит на клапан
/// вполсилы, а не наравне с живыми на станции угрозами.
/datum/controller/subsystem/director/proc/ghost_member_presence(mob/member)
	var/turf/location = get_turf(member)
	if(location && is_station_level(location.z))
		return 1
	return DIRECTOR_OFFSTATION_ANTAG_MULT

/// Тяжёлые антаг-команды (antag_heavy) покупаются только в достаточно пустой раунд:
/// живая нагрузка не выше antag_heavy_load_fraction цели профиля.
/datum/controller/subsystem/director/proc/antag_heavy_load_blocked(load, target)
	return target > 0 && load > target * profile.antag_heavy_load_fraction

/// Реальный контент для таймера тишины: то, что игроки замечают как "что-то происходит".
/// Флейвор и филлер не считались и раньше; MINOR без intensity (лотерея, бумажные события)
/// тоже не повод молчать гарантии - прод-раунд забивал таймер тишины Money Lottery.
/datum/controller/subsystem/director/proc/is_real_content(datum/director_action/action)
	if(action.filler || action.severity == DIRECTOR_SEVERITY_FLAVOR)
		return FALSE
	if(action.severity == DIRECTOR_SEVERITY_MINOR)
		return action.intensity > 0
	return TRUE

/// Регистрация вклада intensity. expires_at = 0 означает "снимется вручную по завершении".
/datum/controller/subsystem/director/proc/add_intensity(source_name, amount, duration = 0)
	if(amount <= 0)
		return
	intensity_ledger += list(list(source_name, amount, duration ? now() + duration : 0, null))

/// Снять вклад по имени (для событий с end())
/datum/controller/subsystem/director/proc/remove_intensity(source_name, linger = 0)
	for(var/list/entry in intensity_ledger)
		if(entry[1] != source_name || entry[3])
			continue
		if(linger)
			entry[3] = now() + linger
		else
			intensity_ledger -= list(entry)
		return

/// Главная логика бита. Чистая: всё состояние мира приходит в signals.
/datum/controller/subsystem/director/proc/run_beat(datum/director_signals/signals, forced = FALSE)
	if(signals.evac_state == DIRECTOR_EVAC_GONE)
		return DIRECTOR_BEAT_IDLE
	// В симуляции форс-праздники не исполняются взаправду (execute_action() напрямую, мимо dry_run) -
	// и holiday_forced_done не трогается, чтобы боевой раунд после симуляции всё ещё разобрал их сам.
	if(!dry_run && !holiday_forced_done)
		run_forced_events(signals)
		holiday_forced_done = TRUE
	// Пустая станция: события некому играть, биты простаивают (пустой дев-сервер иначе копил бы
	// аномалии и поды). Форс-бит админа проходит - это его осознанное решение.
	if(!forced && signals.effective_crew <= 0)
		return DIRECTOR_BEAT_IDLE
	// Живое окно отмены: новый пик перезаписал бы pending без deltimer. Это ожидание, не решение - без лога.
	if(pending_action)
		return DIRECTOR_BEAT_IDLE
	// План антаг-пулов: цель накопления на каждый пул (roll_pool_target). Здесь, а не в
	// filter_candidates: фильтр зовётся и оценкой пула для панели, план - только боевым битом.
	ensure_pool_targets(signals)
	var/guaranteed = FALSE
	var/guaranteed_ghost = FALSE
	// Тишина меряется по РЕАЛЬНОМУ контенту (не флейвор и не филлер: капающая раз в 5 минут
	// аврора или "Nothing" не должны бесконечно откладывать гарантию) и по ВИДИМОЙ нагрузке
	// (event_intensity: живые стелс-антаги дают intensity, но игрокам ничего не видно).
	if(!forced && (now() - last_real_fired_at) > profile.max_quiet_time && signals.event_intensity < profile.quiet_intensity_threshold)
		guaranteed = TRUE
		// Затянувшаяся тишина при пустых антаг-каналах: одними MINOR/MODERATE раунд не оживить,
		// если антагов почти нет. После двойного порога тишины и при дефиците нагрузки >= 50%
		// гарантированный бит может купить и гост-роль (бюджет для неё честный, см. filter).
		guaranteed_ghost = (now() - last_real_fired_at) > profile.max_quiet_time * 2 && last_antag_deficit >= 0.5
	// Глобальная пауза: что-то только что стреляло - бит простаивает целиком, чтобы легальные по
	// ступенчатым паузам очереди "moderate + minor + flavor за четыре минуты" не собирались.
	// Гарантированный бит по определению после долгого затишья, форс админа - осознанное решение.
	if(!forced && !guaranteed && (now() - last_any_fired_at) < profile.global_spacing)
		var/list/global_stats = list(DIRECTOR_REJECT_SEV_ALL = list(DIRECTOR_REJECT_GLOBAL = 1))
		if(!dry_run)
			last_reject_stats = global_stats
		director_log_beat(signals, null, DIRECTOR_BEAT_IDLE, global_stats)
		return DIRECTOR_BEAT_IDLE
	var/list/reject_stats = list()
	var/list/candidates = filter_candidates(signals, guaranteed, reject_stats, allow_ghost_guarantee = guaranteed_ghost)
	if(!dry_run)
		last_reject_stats = reject_stats
	if(!length(candidates))
		director_log_beat(signals, null, guaranteed ? DIRECTOR_BEAT_BLOCKED : DIRECTOR_BEAT_IDLE, reject_stats)
		return guaranteed ? DIRECTOR_BEAT_BLOCKED : DIRECTOR_BEAT_IDLE
	var/datum/director_action/picked = pickweight(candidates)
	if(!picked)
		director_log_beat(signals, null, DIRECTOR_BEAT_IDLE, reject_stats)
		return DIRECTOR_BEAT_IDLE
	// dry_run обходит окно отмены целиком: announce_pick рассчитан на реальных админов и реальный
	// таймер, симуляция идёт в один тик и должна исполнять решение сразу.
	if(dry_run || picked.severity == DIRECTOR_SEVERITY_FLAVOR || picked.severity == DIRECTOR_SEVERITY_MINOR)
		var/executed = spend_and_execute(picked, guaranteed ? "guaranteed" : "beat")
		var/result = guaranteed ? DIRECTOR_BEAT_GUARANTEED : DIRECTOR_BEAT_FIRED
		if(!executed)
			result = DIRECTOR_BEAT_FAILED
		else if(!dry_run && picked.director_kind == DIRECTOR_KIND_RULESET)
			result = DIRECTOR_BEAT_SCHEDULED
		var/detail = selection_detail(picked, candidates)
		if(!executed)
			detail = "[execution_failure_detail(picked)]; [detail]"
		director_log_beat(signals, picked, result, reject_stats, detail)
		return result
	else
		announce_pick(picked, candidates, guaranteed, signals)
	return guaranteed ? DIRECTOR_BEAT_GUARANTEED : DIRECTOR_BEAT_FIRED

/// Отбор кандидатов с фильтрами темпа. guaranteed: только MINOR/MODERATE, бюджет игнорируется
/// (allow_ghost_guarantee дополнительно открывает GHOST - с честным гейтом кошелька).
/// reject_stats (опционально): сюда считается отсев severity -> (DIRECTOR_REJECT_* -> число действий),
/// структурные пропуски (латеджойн-рулсеты, чужие ступени guaranteed-бита) не считаются.
/// verdicts (опционально, для панели): по-действийный вердикт на КАЖДОЕ действие, включая
/// структурные пропуски; у прошедших эффективный вес лежит в "eff_weight".
/datum/controller/subsystem/director/proc/filter_candidates(datum/director_signals/signals, guaranteed = FALSE, list/reject_stats = null, list/verdicts = null, allow_ghost_guarantee = FALSE)
	var/list/result = list()
	var/intensity_full = signals.active_intensity >= profile.intensity_cap
	var/active_majors = count_active_majors()
	var/sec_needed = CEILING(signals.effective_crew / profile.security_per_players, 1)
	var/sec_short = signals.staffing[DIRECTOR_DEPT_SECURITY] < sec_needed
	var/dead_crisis = signals.dead_fraction > profile.dead_fraction_threshold
	// Насыщение антагами: живая антаг-нагрузка на цели профиля - антаг-пулы закрыты,
	// пока кто-то из живых не выбудет (или раундстарт не затухнет).
	var/antag_target_now = antag_target(signals.effective_crew)
	var/antag_load_now = antag_target_now > 0 ? antag_load() : 0
	var/antag_saturated = antag_target_now > 0 && antag_load_now >= antag_target_now
	for(var/datum/director_action/action as anything in actions)
		// Не показываем результат preflight с прошлой оценки: он мог устареть вместе со
		// списком призраков/экипажа.
		action.director_preflight_detail = null
		action.director_preflight_failure = null
		var/sev = action.severity
		if(sev in blocked_severities)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_BLOCKED)
			continue
		if(action.director_kind == DIRECTOR_KIND_EVENT && !CONFIG_GET(flag/allow_random_events))
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_EVENTS_OFF)
			continue
		// Латеджойн-рулсеты не участвуют в битах: их единственный путь - on_latejoin,
		// где кандидатом ставится сам зашедший игрок. Бит запустил бы их с пустым candidates.
		// В reject_stats не считаются (структурный пропуск), но вердикт для панели получают.
		if(istype(action, /datum/dynamic_ruleset/latejoin))
			note_reject(null, verdicts, action, DIRECTOR_VERDICT_LATEJOIN)
			continue
		if(guaranteed && !(sev in list(DIRECTOR_SEVERITY_MINOR, DIRECTOR_SEVERITY_MODERATE)) && !(allow_ghost_guarantee && sev == DIRECTOR_SEVERITY_GHOST))
			continue
		// Гарантированный бит случается после долгой тишины - филлер-пустышка там не ответ.
		// Структурный пропуск без учёта в reject_stats: панель оценивает пул не-гарантированным путём.
		if(guaranteed && action.filler)
			continue
		if(intensity_full && sev != DIRECTOR_SEVERITY_FLAVOR)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_INTENSITY_CAP,
				detail = isnull(verdicts) ? null : "[round(signals.active_intensity)] при потолке [profile.intensity_cap]")
			continue
		if(signals.evac_state == DIRECTOR_EVAC_CALLED && (sev == DIRECTOR_SEVERITY_MAJOR || DIRECTOR_IS_ANTAG_POOL(sev)))
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_EVAC)
			continue
		if(dead_crisis && (sev == DIRECTOR_SEVERITY_MAJOR || (DIRECTOR_IS_ANTAG_POOL(sev) && action.antag_heavy)))
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_DEAD_CRISIS)
			continue
		if(antag_saturated && DIRECTOR_IS_ANTAG_POOL(sev))
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_ANTAG_SATURATED,
				detail = isnull(verdicts) ? null : "нагрузка [round(antag_load_now)] при цели [round(antag_target_now)]")
			continue
		// Тяжёлые антаг-действия (нюк-асолт, блоб, ксено) в мягких профилях выключены целиком:
		// Light/Extended - фоновые раунды, командный асолт там не "редкий", а неуместный.
		if(action.antag_heavy && !profile.antag_heavy_enabled)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_ANTAG_HEAVY,
				detail = isnull(verdicts) ? null : "профиль без тяжёлых антагов")
			continue
		// Тяжёлая команда - главное блюдо пустого раунда, а не довесок к заполненному:
		// рейдеры с intensity 45, купленные в запас 9.8 (прод-раунд), пробили цель почти
		// вдвое и заперли антаг-каналы гейтом насыщения до конца смены.
		if(action.antag_heavy && DIRECTOR_IS_ANTAG_POOL(sev) && antag_heavy_load_blocked(antag_load_now, antag_target_now))
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_ANTAG_HEADROOM,
				detail = isnull(verdicts) ? null : "нагрузка [round(antag_load_now)] при пороге [round(antag_target_now * profile.antag_heavy_load_fraction)]")
			continue
		if(sev == DIRECTOR_SEVERITY_MAJOR && active_majors >= profile.max_active_major)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_MAJOR_CAP,
				detail = isnull(verdicts) ? null : "[active_majors] из [profile.max_active_major]")
			continue
		if(!spacing_allows(action))
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_SPACING,
				detail = isnull(verdicts) ? null : minutes_left_text(spacing_remaining(sev, action.antag_heavy)))
			continue
		// Пауза семейства: после любого запуска из семейства его остальные варианты ждут тоже -
		// иначе десять "переливов труб" чередуются, легально обходя ступенчатые паузы и фолл-офф.
		var/family_left = family_spacing_remaining(action)
		if(family_left > 0)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_FAMILY,
				detail = isnull(verdicts) ? null : minutes_left_text(family_left))
			continue
		if(action_recently_failed(action))
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_RECENT_FAILURE,
				detail = isnull(verdicts) ? null : "новая попытка через [minutes_left_text(action_failure_cooldowns[action] - now())]; сейчас выбирается замена")
			continue
		// can_fire проверяет статический контракт, preflight рулсета - живых кандидатов,
		// контрроли и карту. Оба стоят до бюджета/копилки: неисполнимая цель не должна
		// замораживать антаг-кошелёк и маскироваться в панели как "не хватает очков".
		if(!action.can_fire(signals))
			var/list/diag = isnull(verdicts) ? null : diagnose_can_fire(action, signals)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_CAN_FIRE,
				verdict_reason = diag ? diag["reason"] : null, detail = diag ? diag["detail"] : null)
			continue
		if(!action_preflight(action))
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_READINESS,
				detail = action.director_preflight_failure || "внутренняя проверка ready() не пройдена")
			continue
		// Гейт по кошельку своей ступени, а не по общему бюджету: MAJOR/ANTAG больше не голодают
		// из-за трат дешёвых MINOR/MODERATE. Гарантия игнорирует кошелёк только для событийных
		// ступеней: гост-роль из гарантии тишины всё равно оплачивается честно.
		if((!guaranteed || DIRECTOR_IS_ANTAG_POOL(sev)) && budgets[action.severity] < action.cost)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_BUDGET,
				detail = isnull(verdicts) ? null : "[round(budgets[sev], 0.1)] из [action.cost]")
			continue
		// Копилка антаг-пула защищает полную стоимость выбранной цели. Если её трек временно
		// закрыт cooldown/семейством (или heavy запрещён из-за смертности), независимый второй
		// трек может запускаться только из бюджета СВЕРХ резерва. Так готовая light-роль не
		// простаивает при уже накопленной heavy, но и не может проесть её накопление.
		if(!guaranteed && DIRECTOR_IS_ANTAG_POOL(sev))
			var/datum/director_action/saving_for = pool_saving[sev]
			if(saving_for && saving_for != action)
				var/target_waiting = !spacing_allows(saving_for) || family_spacing_remaining(saving_for) > 0 || (dead_crisis && saving_for.antag_heavy) \
					|| (saving_for.antag_heavy && antag_heavy_load_blocked(antag_load_now, antag_target_now))
				var/other_track = saving_for.antag_heavy != action.antag_heavy
				var/free_budget = max(0, budgets[sev] - saving_for.cost)
				if(!target_waiting || !other_track || free_budget < action.cost)
					note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_SAVING,
						detail = isnull(verdicts) ? null : "резерв [saving_for.cost] на [saving_for.action_name()]; свободно [round(free_budget, 0.1)] из [action.cost]")
					continue
		// Навязчивость: мягкие профили глушат мешающие играть события. Нулевой множитель - это
		// осознанное "в этом профиле такому не место", отдельная причина отсева для панели.
		var/disruption_mult = profile.disruption_mult(action)
		if(disruption_mult <= 0)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_DISRUPTION,
				detail = isnull(verdicts) ? null : "профиль исключает метку [action.get_disruption()]")
			continue
		var/action_weight = action.get_weight(signals)
		if(action_weight <= 0)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_NO_WEIGHT,
				detail = (isnull(verdicts) || action.weight >= 0) ? null : "форс-событие праздника, в выборе не участвует")
			continue
		if(sec_short && (sev == DIRECTOR_SEVERITY_MAJOR || (DIRECTOR_IS_ANTAG_POOL(sev) && action.antag_heavy)))
			action_weight *= profile.security_penalty_mult
		action_weight *= share_correction(sev)
		action_weight *= repeat_falloff(action)
		action_weight *= disruption_mult
		// Запас цели: лёгкая антаг-покупка, не влезающая в остаток (headroom / intensity),
		// сильно уступает влезающим - директор докупает по размеру свободного места,
		// а не по каталогу, и не перепрыгивает цель одним махом.
		if(DIRECTOR_IS_ANTAG_POOL(sev) && !action.antag_heavy && action.intensity > 0 && antag_target_now > 0)
			action_weight *= clamp((antag_target_now - antag_load_now) / action.intensity, DIRECTOR_HEADROOM_WEIGHT_FLOOR, 1)
		if(action_weight > 0)
			var/weighted = max(1, round(action_weight * 100))
			result[action] = weighted
			if(!isnull(verdicts))
				var/list/entry = pool_entry(action, DIRECTOR_VERDICT_OK, null)
				entry["eff_weight"] = weighted
				entry["effectiveWeight"] = round(action_weight, 0.01)
				verdicts += list(entry)
		else if(!isnull(verdicts))
			// Нулевая доля ступени в профиле (share_correction = 0): в боевом бите отсев молчаливый,
			// панель показывает причину.
			note_reject(null, verdicts, action, DIRECTOR_REJECT_NO_WEIGHT, detail = "доля ступени в профиле = 0")
	return result

/// Счётчик отсева для бит-лога + по-действийный вердикт для панели. Оба приёмника опциональны:
/// боевой бит передаёт только reject_stats, живая оценка пула - оба (или только verdicts).
/// verdict_reason: причина для вердикта, если она детальнее, чем reason (расшифровка can_fire).
/datum/controller/subsystem/director/proc/note_reject(list/reject_stats, list/verdicts, datum/director_action/action, reason, verdict_reason = null, detail = null)
	if(!isnull(reject_stats))
		var/list/sev_counts = reject_stats[action.severity]
		if(isnull(sev_counts))
			sev_counts = list()
			reject_stats[action.severity] = sev_counts
		sev_counts[reason] = (sev_counts[reason] || 0) + 1
	if(!isnull(verdicts))
		verdicts += list(pool_entry(action, verdict_reason || reason, detail))

/// Строка пула для панели: паспорт действия + вердикт текущей оценки.
/datum/controller/subsystem/director/proc/pool_entry(datum/director_action/action, verdict, detail)
	var/list/entry = list(
		"name" = action.action_name(),
		"kind" = action.director_kind,
		"severity" = action.severity,
		"cost" = action.cost,
		"intensity" = action.intensity,
		"weight" = action.weight,
		"occurrences" = action.occurrences,
		"family" = action.family,
		"disruption" = action.get_disruption(),
		"verdict" = verdict,
		"detail" = detail,
	)
	entry["preflight"] = action.director_preflight_detail
	return entry

/// Объяснение конкретного взвешенного выбора: помогает отличить "выбрал случайно из пяти"
/// от единственного прошедшего кандидата. candidates хранит целочисленные эффективные веса.
/datum/controller/subsystem/director/proc/selection_detail(datum/director_action/action, list/candidates)
	var/total_weight = 0
	for(var/datum/director_action/candidate as anything in candidates)
		total_weight += candidates[candidate]
	var/action_weight = candidates[action] || 0
	var/chance = total_weight > 0 ? round(action_weight / total_weight * 100, 0.1) : 0
	return "ролл: [chance]% (эффективный вес [round(action_weight / 100, 0.01)] из [round(total_weight / 100, 0.01)], кандидатов [length(candidates)])"

/// Причина синхронного провала execute_action(). Для midround ready() уже оставил точную
/// диагностику; для остального остаётся честный общий фолбэк.
/datum/controller/subsystem/director/proc/execution_failure_detail(datum/director_action/action)
	if(istype(action, /datum/dynamic_ruleset/midround))
		var/datum/dynamic_ruleset/midround/rule = action
		if(rule.ready_failure_reason)
			return rule.ready_failure_reason
	return "execute_action() вернул FALSE; бюджет возвращён"

/// Расшифровка провала can_fire() по полям базового контракта: гейты проверяются в том же
/// порядке, что и в /datum/director_action/can_fire(). Специфику подклассов (погода, цели,
/// внутренние проверки рулсетов) отсюда не видно - для неё общий DIRECTOR_CANTFIRE_SPECIAL.
/datum/controller/subsystem/director/proc/diagnose_can_fire(datum/director_action/action, datum/director_signals/signals)
	if(!action.enabled)
		return list("reason" = DIRECTOR_CANTFIRE_DISABLED, "detail" = null)
	if(action.admin_only)
		return list("reason" = DIRECTOR_CANTFIRE_ADMIN_ONLY, "detail" = null)
	if(action.max_occurrences && action.occurrences >= action.max_occurrences)
		return list("reason" = DIRECTOR_CANTFIRE_OCCURRENCES, "detail" = "[action.occurrences] из [action.max_occurrences]")
	var/round_elapsed = now() - SSticker.round_start_time
	if(action.earliest_start && round_elapsed < action.earliest_start)
		return list("reason" = DIRECTOR_CANTFIRE_EARLY, "detail" = minutes_left_text(action.earliest_start - round_elapsed))
	if(signals.effective_crew < action.min_players)
		return list("reason" = DIRECTOR_CANTFIRE_MIN_PLAYERS, "detail" = "[signals.effective_crew] из [action.min_players]")
	if(action.required_round_type && !(GLOB.round_type in action.required_round_type))
		return list("reason" = DIRECTOR_CANTFIRE_ROUND_TYPE, "detail" = null)
	if(action.min_staffing)
		for(var/dept in action.min_staffing)
			if(signals.staffing[dept] < action.min_staffing[dept])
				return list("reason" = DIRECTOR_CANTFIRE_STAFFING, "detail" = "[dept]: [signals.staffing[dept]] из [action.min_staffing[dept]]")
	// Гейты round_event_control поверх базового контракта: во время Summon Events (wizardmode)
	// обычные события заглушены, а wizard-события доступны только в нём - без явной причины
	// весь пул событий читался бы как невнятное "специфичное условие".
	if(istype(action, /datum/round_event_control))
		var/datum/round_event_control/event_control = action
		if(event_control.wizardevent != wizardmode)
			return list("reason" = DIRECTOR_CANTFIRE_WIZARDMODE, "detail" = null)
		if(event_control.holidayID && (!SSholidays.holidays || !SSholidays.holidays[event_control.holidayID]))
			return list("reason" = DIRECTOR_CANTFIRE_HOLIDAY, "detail" = null)
	return list("reason" = DIRECTOR_CANTFIRE_SPECIAL, "detail" = null)

/// "ещё N мин" для деталей вердиктов панели
/datum/controller/subsystem/director/proc/minutes_left_text(deciseconds)
	return "ещё [max(1, CEILING(deciseconds / (1 MINUTES), 1))] мин"

/// Живая оценка всего пула для панели: тот же filter_candidates, что и в бою, но с вердиктами.
/// Кэш общий для всех открытых панелей; прошедшим действиям дописывается шанс выбора в процентах.
/datum/controller/subsystem/director/proc/evaluate_pool()
	if(pool_cache && (world.time - pool_cache_at) < DIRECTOR_POOL_CACHE_TIME)
		return pool_cache
	if(!profile || !SSticker.HasRoundStarted())
		return list()
	var/list/verdicts = list()
	var/datum/director_signals/signals = collect_signals()
	quiet_eval = TRUE
	filter_candidates(signals, FALSE, null, verdicts)
	quiet_eval = FALSE
	var/total_weight = 0
	for(var/list/entry in verdicts)
		if(entry["verdict"] == DIRECTOR_VERDICT_OK)
			total_weight += entry["eff_weight"]
	if(total_weight)
		for(var/list/entry in verdicts)
			if(entry["verdict"] == DIRECTOR_VERDICT_OK)
				entry["chance"] = round(entry["eff_weight"] / total_weight * 100, 0.1)
	pool_cache = verdicts
	pool_cache_at = world.time
	return verdicts

/// Множитель затухания повторов: вес делится на (1 + occurrences * repeat_penalty),
/// чтобы уже стрелявшие действия уступали место ещё не виденным ("спавнит одно и то же").
/// Члены семейства считаются по запускам всего семейства: у "Clogged Vents: Semen" и
/// "Scrubber Overflow: Normal" разные счётчики occurrences, но для игрока это один и тот же ивент.
/datum/controller/subsystem/director/proc/repeat_falloff(datum/director_action/action)
	var/penalty = isnull(action.repeat_penalty) ? profile.repeat_penalty : action.repeat_penalty
	var/effective_occurrences = action.occurrences
	if(action.family)
		effective_occurrences = max(effective_occurrences, family_fired_counts[action.family] || 0)
	if(penalty <= 0 || !effective_occurrences)
		return 1
	return 1 / (1 + effective_occurrences * penalty)

/// Сколько децисекунд осталось до конца паузы семейства (<= 0 - пауза не мешает).
/// Действия вне семейств и семейства без запусков не гейтятся.
/datum/controller/subsystem/director/proc/family_spacing_remaining(datum/director_action/action)
	if(!action.family)
		return 0
	var/last_time = family_last_fired_at[action.family]
	if(!last_time)
		return 0
	return profile.family_spacing - (now() - last_time)

/datum/controller/subsystem/director/proc/count_active_majors()
	var/count = 0
	for(var/list/entry in intensity_ledger)
		if(entry[4] == DIRECTOR_SEVERITY_MAJOR && (!entry[3] || entry[3] > now()))
			count++
	return count

/// Сколько децисекунд осталось до конца паузы ступени (<= 0 - пауза не мешает).
/// antag_heavy: у тяжёлых антаг-инжекций отдельные пауза и счётчик последнего запуска.
/// Паузы и треки ANTAG и GHOST полностью независимы: культ не откладывает нюков и наоборот.
/datum/controller/subsystem/director/proc/spacing_remaining(severity, antag_heavy = FALSE)
	if(severity == DIRECTOR_SEVERITY_ANTAG)
		var/spacing = antag_heavy ? profile.antag_heavy_spacing : profile.antag_light_spacing
		var/last_time = antag_heavy ? last_antag_heavy_at : (last_fired_at[DIRECTOR_SEVERITY_ANTAG] || 0)
		return spacing - (now() - last_time)
	if(severity == DIRECTOR_SEVERITY_GHOST)
		var/spacing = antag_heavy ? profile.ghost_heavy_spacing : profile.ghost_light_spacing
		var/last_time = antag_heavy ? last_ghost_heavy_at : (last_fired_at[DIRECTOR_SEVERITY_GHOST] || 0)
		return spacing - (now() - last_time)
	var/spacing = profile.severity_spacing[severity]
	if(isnull(spacing))
		return 0
	return spacing - (now() - (last_fired_at[severity] || 0))

/datum/controller/subsystem/director/proc/spacing_allows(datum/director_action/action)
	return spacing_remaining(action.severity, action.antag_heavy) <= 0

/// Поправка веса ступени: отстающие от целевой доли ступени получают буст, обогнавшие - штраф.
/datum/controller/subsystem/director/proc/share_correction(sev)
	var/target = profile.pool_shares[sev]
	if(!target)
		return 0
	var/total_fired = 0
	var/sev_fired = 0
	for(var/key in fired_counts)
		total_fired += fired_counts[key]
	sev_fired = fired_counts[sev] || 0
	if(!total_fired)
		return 1
	var/actual = sev_fired / total_fired
	return clamp(target / max(actual, 0.01), 0.25, 4)

/datum/controller/subsystem/director/proc/spend_and_execute(datum/director_action/action, source = "beat")
	if(dry_run)
		// Симулятор никогда не запускает действие взаправду - только списывает бюджет и ведёт
		// тот же учёт occurrences/spacing/intensity, что и боевой запуск, чтобы пейсинг был честным.
		budgets[action.severity] = max(0, budgets[action.severity] - action.cost)
		action.occurrences++
		note_fired(action)
		return TRUE
	var/spent = min(budgets[action.severity], action.cost)
	budgets[action.severity] -= spent
	if(!action.execute_action())
		// Провал ДО планирования (например, рулсет не набрал кандидатов) - вернуть списанное.
		// Провал ПОСЛЕ таймера (execute_scheduled_ruleset) рефандится отдельно через rule.clean_up().
		budgets[action.severity] += spent
		action_failure_cooldowns[action] = now() + DIRECTOR_FAILED_ACTION_COOLDOWN
		return FALSE
	if(action.director_kind == DIRECTOR_KIND_RULESET)
		var/datum/dynamic_ruleset/rule = action
		rule.director_pending_cost += spent
	action.occurrences++
	note_fired(action, from_latejoin = (source == "latejoin"))
	return TRUE

/// Откат учёта действия, которое было принято/запланировано, но не породило контент.
/// Возвращаются не только бюджет/intensity, но и все паузы: провальный Ratvar не имеет права
/// закрыть ANTAG-пул на полчаса. Само действие получает короткий карантин, затем ищется замена.
/datum/controller/subsystem/director/proc/note_failed_action(datum/director_action/action, refund_budget = FALSE, retry_replacement = FALSE)
	if(action.occurrences > 0)
		action.occurrences--
	// Латеджойн note_fired() намеренно не входит в доли битов, откатывать там нечего.
	if(!istype(action, /datum/dynamic_ruleset/latejoin) && (fired_counts[action.severity] || 0) > 0)
		fired_counts[action.severity]--
	if(action.family && (family_fired_counts[action.family] || 0) > 0)
		family_fired_counts[action.family]--
	rollback_action_attempt(action)
	var/refund_amount = action.cost
	if(action.director_kind == DIRECTOR_KIND_RULESET)
		var/datum/dynamic_ruleset/rule = action
		refund_amount = rule.director_pending_cost
		rule.director_pending_cost = 0
		// Удаляем последний временный мост именно этой попытки. Обычный remove_intensity()
		// намеренно пропускает записи с expires_at и для отложенного рулсета здесь не подходит.
		for(var/i = length(intensity_ledger), i >= 1, i--)
			var/list/entry = intensity_ledger[i]
			if(entry[1] != action.action_name() || entry[4] != action.severity || !entry[3])
				continue
			intensity_ledger.Cut(i, i + 1)
			break
	else
		remove_intensity(action.action_name())
	if(refund_budget)
		refund_to_budget(action.severity, refund_amount)
	if(retry_replacement)
		action_failure_cooldowns[action] = now() + DIRECTOR_FAILED_ACTION_COOLDOWN
		if(pool_saving[action.severity] == action)
			pool_saving[action.severity] = null
		if(!dry_run)
			addtimer(CALLBACK(src, PROC_REF(retry_failed_action), action), DIRECTOR_FAILED_ACTION_RETRY_DELAY)
	pool_cache = null

/// Сохраняем бухгалтерию до предварительного note_fired только для действий, которые способны
/// подтвердить провал позже: отложенные рулсеты и события с ghost poll.
/datum/controller/subsystem/director/proc/remember_action_attempt(datum/director_action/action)
	if(dry_run)
		return
	var/is_delayed_ruleset = istype(action, /datum/dynamic_ruleset)
	var/datum/round_event_control/event_control = action
	var/is_ghost_poll = istype(event_control) && ispath(event_control.typepath, /datum/round_event/ghost_role)
	if(!is_delayed_ruleset && !is_ghost_poll)
		return
	var/executed_at = 0
	if(is_delayed_ruleset)
		var/datum/dynamic_ruleset/rule = action
		executed_at = rule.executed_at
	action_attempt_rollbacks[action] = list(
		"at" = now(),
		"last_any" = last_any_fired_at,
		"last_real" = last_real_fired_at,
		"last_latejoin" = last_latejoin_at,
		"last_severity" = last_fired_at[action.severity] || 0,
		"last_antag_heavy" = last_antag_heavy_at,
		"last_ghost_heavy" = last_ghost_heavy_at,
		"family_last" = action.family ? (family_last_fired_at[action.family] || 0) : 0,
		"executed_at" = executed_at,
	)

/datum/controller/subsystem/director/proc/rollback_action_attempt(datum/director_action/action)
	var/list/snapshot = action_attempt_rollbacks[action]
	if(!islist(snapshot))
		return
	var/stamped_at = snapshot["at"]
	// Не затираем более новый форс/бит, если он успел случиться до ответа асинхронного опроса.
	if(last_any_fired_at == stamped_at)
		last_any_fired_at = snapshot["last_any"]
	if(last_real_fired_at == stamped_at)
		last_real_fired_at = snapshot["last_real"]
	if(last_latejoin_at == stamped_at)
		last_latejoin_at = snapshot["last_latejoin"]
	if(last_fired_at[action.severity] == stamped_at)
		last_fired_at[action.severity] = snapshot["last_severity"]
	if(last_antag_heavy_at == stamped_at)
		last_antag_heavy_at = snapshot["last_antag_heavy"]
	if(last_ghost_heavy_at == stamped_at)
		last_ghost_heavy_at = snapshot["last_ghost_heavy"]
	if(action.family && family_last_fired_at[action.family] == stamped_at)
		family_last_fired_at[action.family] = snapshot["family_last"]
	if(action.director_kind == DIRECTOR_KIND_RULESET)
		var/datum/dynamic_ruleset/rule = action
		if(rule.executed_at == stamped_at)
			rule.executed_at = snapshot["executed_at"]
	action_attempt_rollbacks -= action

/datum/controller/subsystem/director/proc/confirm_action_success(datum/director_action/action)
	action_attempt_rollbacks -= action
	action_failure_cooldowns -= action
	if(action.director_kind != DIRECTOR_KIND_RULESET)
		return
	var/datum/dynamic_ruleset/rule = action
	var/confirmed_cost = rule.director_pending_cost
	rule.director_pending_cost = 0
	if(confirmed_cost <= 0)
		return
	var/list/newly_insured = list()
	for(var/datum/mind/assigned_mind as anything in rule.assigned)
		if(!istype(assigned_mind) || rule.director_loss_accounted[assigned_mind] || islist(rule.director_loss_refund_values[assigned_mind]))
			continue
		newly_insured += assigned_mind
	if(length(newly_insured))
		var/share = confirmed_cost / length(newly_insured)
		for(var/datum/mind/insured_mind as anything in newly_insured)
			rule.director_loss_refund_values[insured_mind] = list(
				"amount" = share,
				"at" = now(),
				"activity" = insured_mind.director_activity_total,
			)
	rule.total_cost += confirmed_cost

/// Асинхронный отказ не ждёт следующего минутного бита: после короткой технической задержки
/// заново оцениваем именно тот же ANTAG/GHOST-пул, исключив провалившийся вариант.
/datum/controller/subsystem/director/proc/retry_failed_action(datum/director_action/failed_action)
	if(!action_recently_failed(failed_action))
		return
	if(paused || !profile || pending_action || !SSticker.HasRoundStarted())
		return
	var/severity = failed_action.severity
	if(!(severity in list(DIRECTOR_SEVERITY_ANTAG, DIRECTOR_SEVERITY_GHOST)))
		return
	var/datum/director_signals/signals = collect_signals()
	if(signals.evac_state == DIRECTOR_EVAC_GONE || signals.effective_crew <= 0)
		return
	ensure_pool_targets(signals)
	reroll_pool_target_affordable(severity, signals)
	var/list/reject_stats = list()
	var/list/candidates = filter_candidates(signals, FALSE, reject_stats)
	for(var/datum/director_action/candidate as anything in candidates.Copy())
		if(candidate.severity != severity)
			candidates -= candidate
	last_reject_stats = reject_stats
	if(!length(candidates))
		return
	var/datum/director_action/replacement = pickweight(candidates)
	message_admins("DIRECTOR: [failed_action.action_name()] не породил антагониста; паузы и бюджет возвращены, предлагаю замену [replacement.action_name()].")
	announce_pick(replacement, candidates, FALSE, signals)

/// Замена обязана быть исполнимой сейчас: если перевыбранная цель копилки дороже остатка
/// кошелька (прод-раунд: после провала генлинг-метеора цель ушла в рейдеров за 15 при 12.5),
/// пробуем цель по средствам. Вариантов по средствам нет - оставляем дорогой план копиться.
/datum/controller/subsystem/director/proc/reroll_pool_target_affordable(severity, datum/director_signals/signals)
	if(!DIRECTOR_IS_ANTAG_POOL(severity))
		return
	var/datum/director_action/planned = pool_saving[severity]
	if(QDELETED(planned) || planned.cost <= budgets[severity])
		return
	quiet_eval = TRUE
	roll_pool_target(severity, signals, max_cost = budgets[severity])
	quiet_eval = FALSE

/// Общий учёт запуска (и естественного, и форса админом). from_latejoin: инжекция из окна захода
/// игрока - у неё собственный трек спейсинга (last_latejoin_at), и она не трогает паузы битов:
/// латеджойн-трейтор невидим для игроков в момент выдачи, он не "событие" в темпе раунда,
/// и запирать им полосу битов (или таймер тишины) нельзя - именно так лейтджойны душили биты.
/datum/controller/subsystem/director/proc/note_fired(datum/director_action/action, from_latejoin = FALSE)
	remember_action_attempt(action)
	// Возраст исполнения для затухания вклада (tally_ruleset_intensity): штампуется на ЛЮБОЙ
	// запуск рулсета (бит, латеджойн, форс админа). Окно delay между schedule и execute на
	// масштабе 40-минутного затухания несущественно.
	if(action.director_kind == DIRECTOR_KIND_RULESET)
		var/datum/dynamic_ruleset/rule = action
		rule.executed_at = now()
	if(from_latejoin)
		last_latejoin_at = now()
	else
		last_any_fired_at = now()
		// Таймер тишины гарантированного бита двигает только реальный контент (см. is_real_content):
		// флейвор, филлер и MINOR без intensity не считаются "чем-то происходящим".
		if(is_real_content(action))
			last_real_fired_at = now()
		// Доли ступеней (share_correction) считаются по решениям битов: латеджойн-канал не должен
		// "перегонять" ступень ANTAG в счётчике и штрафовать её вес в самих битах.
		fired_counts[action.severity] = (fired_counts[action.severity] || 0) + 1
	if(action.family)
		family_fired_counts[action.family] = (family_fired_counts[action.family] || 0) + 1
		family_last_fired_at[action.family] = now()
	// Ступенчатые паузы битов латеджойн не трогает - см. шапку прока.
	if(!from_latejoin)
		if(DIRECTOR_IS_ANTAG_POOL(action.severity) && action.antag_heavy)
			if(action.severity == DIRECTOR_SEVERITY_GHOST)
				last_ghost_heavy_at = now()
			else
				last_antag_heavy_at = now()
		else
			last_fired_at[action.severity] = now()
	// Исполненная цель копилки снимается (в т.ч. форс-запуск админом) - следующий бит роллит новую.
	if(DIRECTOR_IS_ANTAG_POOL(action.severity) && pool_saving[action.severity] == action)
		pool_saving[action.severity] = null
	// Симулятор читает ступень последнего запуска этого бита отсюда (боевая логика поля не трогает).
	sim_last_severity = action.severity
	sim_last_antag_heavy = (DIRECTOR_IS_ANTAG_POOL(action.severity) && action.antag_heavy)
	if(action.intensity > 0)
		var/expires_at
		if(dry_run)
			// dry_run никогда не зовёт execute_action(), поэтому ни remove_intensity() из event/kill(),
			// ни динамический подсчёт рулсетов (assigned пуст) не сработают - one-shot вклад иначе висел
			// бы в ledger'е до конца прогона и душил бы intensity_cap. Отклонение от боевого поведения:
			// в симуляции such-вклад всегда гаснет через max(intensity_linger, 10 минут).
			expires_at = now() + max(action.intensity_linger, 10 MINUTES)
		else if(action.director_kind == DIRECTOR_KIND_RULESET)
			// Рулсет: постоянной записи нет (get_ruleset_intensity считает живого антага динамически
			// по доле выживших assigned). Эта запись - только мост на окно delay между schedule и
			// execute, пока assigned ещё пуст; после наполнения assigned мост снимается.
			expires_at = now() + DIRECTOR_RULESET_BRIDGE_TIME
		else
			// Событие: вклад снимается вручную в /datum/round_event/kill() -> remove_intensity(name,
			// linger), поэтому линяет от КОНЦА события. Здесь всегда 0, а не now()+linger от старта -
			// иначе remove_intensity не смог бы переставить уже "истекающую" запись.
			expires_at = 0
		intensity_ledger += list(list(action.action_name(), action.intensity, expires_at, action.severity))

/// Ручные запуски (ForceEvent, форс-рулсеты) регистрируются, но бюджет не трогают
/datum/controller/subsystem/director/proc/note_forced_run(datum/director_action/action)
	note_fired(action)

/// Латеджойн: окно возможности для ANTAG-пула
/datum/controller/subsystem/director/proc/on_latejoin(mob/living/carbon/human/newPlayer)
	if(paused || !profile || GLOB.round_type == ROUNDTYPE_EXTENDED)
		return
	// Рулсеты регистрируются dynamic'ом в pre_setup - пока их нет, дальше проверять нечего.
	var/has_ruleset_actions = FALSE
	for(var/datum/director_action/action as anything in actions)
		if(action.director_kind == DIRECTOR_KIND_RULESET)
			has_ruleset_actions = TRUE
			break
	if(!has_ruleset_actions)
		return
	var/datum/director_signals/signals = collect_signals()
	if(signals.evac_state != DIRECTOR_EVAC_NONE)
		return
	// У латеджойн-канала собственный трек спейсинга: паузы полосы битов его не запирают
	// (и наоборот, см. note_fired). Иначе каждая инжекция замораживала оба канала разом.
	if((now() - last_latejoin_at) < profile.latejoin_spacing)
		return
	// Хотим ли тратиться на антага: живая антаг-нагрузка ниже цели профиля (crew * per_crew,
	// та же валюта, что дефицит-капля и гейт насыщения в битах). Нагрузка считается по ОБЕИМ
	// антаг-ступеням: латеджойн-инжекция отвечает на общий дефицит антагонистов.
	var/antag_load_now = antag_load()
	var/antag_target_now = antag_target(signals.effective_crew)
	if(antag_load_now >= antag_target_now)
		return
	// Защита копилки: латеджойн живёт из того же кошелька ANTAG, что и биты, но не должен
	// перебивать выбранный план. Полная стоимость цели неприкосновенна; латеджойн тратит
	// только излишек, иначе дорогая heavy-роль могла бы вечно оставаться наполовину накопленной.
	var/datum/director_action/saving_for = pool_saving[DIRECTOR_SEVERITY_ANTAG]
	var/reserve = QDELETED(saving_for) ? 0 : saving_for.cost
	var/list/candidates = list()
	for(var/datum/director_action/action as anything in actions)
		if(action.director_kind != DIRECTOR_KIND_RULESET)
			continue
		var/datum/dynamic_ruleset/latejoin/rule = action
		if(!istype(rule))
			continue
		if(rule.antag_heavy && !profile.antag_heavy_enabled)
			continue
		// Тяжёлый латеджойн ждёт пустой раунд так же, как тяжёлая покупка в бите.
		if(rule.antag_heavy && antag_heavy_load_blocked(antag_load_now, antag_target_now))
			continue
		if(budgets[rule.severity] - rule.cost < reserve || !rule.can_fire(signals))
			continue
		rule.candidates = list(newPlayer)
		rule.trim_candidates()
		if(rule.ready())
			var/rule_weight = rule.get_weight(signals) * repeat_falloff(rule)
			// Тот же headroom-вес, что в битах: инжекция по размеру свободного места.
			if(!rule.antag_heavy && rule.intensity > 0 && antag_target_now > 0)
				rule_weight *= clamp((antag_target_now - antag_load_now) / rule.intensity, DIRECTOR_HEADROOM_WEIGHT_FLOOR, 1)
			candidates[rule] = max(1, round(rule_weight * 100))
	if(!length(candidates))
		return
	var/datum/dynamic_ruleset/latejoin/picked = pickweight(candidates)
	var/executed = spend_and_execute(picked, "latejoin")
	var/result = executed ? DIRECTOR_BEAT_SCHEDULED : DIRECTOR_BEAT_FAILED
	var/detail = selection_detail(picked, candidates)
	if(!executed)
		detail = "[execution_failure_detail(picked)]; [detail]"
	director_log_beat(signals, picked, result, null, detail)

/// Форс-события (weight < 0, например Halloween): разово в начале раунда, мимо бюджета и спейсинга -
/// безусловный запуск для всех прошедших can_fire.
/datum/controller/subsystem/director/proc/run_forced_events(datum/director_signals/signals)
	for(var/datum/director_action/action as anything in event_controls())
		if(action.weight >= 0)
			continue
		if(!action.can_fire(signals))
			continue
		if(action.execute_action())
			action.occurrences++

/// Быстрый цикл Summon Events: wizard-события мимо бюджета и потолков
/datum/controller/subsystem/director/proc/wizard_beat()
	next_wizard_beat = now() + rand(1 MINUTES, 5 MINUTES)
	var/datum/director_signals/signals = collect_signals()
	var/list/candidates = list()
	for(var/datum/director_action/action as anything in actions)
		var/datum/round_event_control/event_control = action
		if(!istype(event_control) || !event_control.wizardevent)
			continue
		if(!event_control.can_fire(signals))
			continue
		candidates[event_control] = max(1, round(event_control.get_weight(signals) * 100))
	var/datum/director_action/picked = pickweight(candidates)
	if(picked)
		picked.execute_action()
		picked.occurrences++

/datum/controller/subsystem/director/proc/toggle_wizardmode()
	wizardmode = !wizardmode
	message_admins("Summon Events has been [wizardmode ? "enabled" : "disabled"]!")
	log_game("Summon Events was [wizardmode ? "enabled" : "disabled"]!")

/// Объявляет выбор MODERATE+ действия и открывает окно отмены/замены для админов.
/// signals - снимок момента выбора: фиксируется в pending_signals для отложенных записей лога.
/datum/controller/subsystem/director/proc/announce_pick(datum/director_action/action, list/candidates, guaranteed, datum/director_signals/signals)
	pending_action = action
	pending_candidates = candidates
	pending_guaranteed = guaranteed
	pending_signals = signals
	// FIRED пишется не здесь, а в execute_pending после реального запуска: объявление - ещё не факт
	// запуска (окно может кончиться отменой -> CANCELLED в Topic). Иначе лог соврал бы "запущено".
	message_admins("DIRECTOR: через [profile.admin_cancel_time / 10] сек запустится [action.action_name()] ([action.severity]). \
		(<a href='?src=[REF(src)];cancel_pending=1'>CANCEL</a>) (<a href='?src=[REF(src)];reroll_pending=1'>SOMETHING ELSE</a>)")
	pending_timer_id = addtimer(CALLBACK(src, TYPE_PROC_REF(/datum/controller/subsystem/director, execute_pending)), profile.admin_cancel_time, TIMER_STOPPABLE)

/// Исполняет отложенное действие по истечении окна отмены.
/datum/controller/subsystem/director/proc/execute_pending()
	if(!pending_action)
		return
	var/datum/director_action/fired_action = pending_action
	var/datum/director_signals/fired_signals = pending_signals
	var/was_guaranteed = pending_guaranteed
	var/list/retry_candidates = pending_candidates
	var/detail = selection_detail(fired_action, retry_candidates)
	var/executed = spend_and_execute(fired_action, was_guaranteed ? "guaranteed" : "beat")
	var/result = was_guaranteed ? DIRECTOR_BEAT_GUARANTEED : DIRECTOR_BEAT_FIRED
	if(!executed)
		result = DIRECTOR_BEAT_FAILED
		detail = "[execution_failure_detail(fired_action)]; [detail]"
	else if(fired_action.director_kind == DIRECTOR_KIND_RULESET)
		result = DIRECTOR_BEAT_SCHEDULED
	director_log_beat(fired_signals, fired_action, result, null, detail)
	pending_action = null
	pending_candidates = null
	pending_signals = null
	pending_timer_id = null
	// Кандидат мог исчезнуть за окно отмены. Не сжигаем весь бит: убираем провалившийся
	// вариант и даём админам такое же окно отмены для следующего всё ещё готового кандидата.
	if(!executed && length(retry_candidates))
		retry_candidates -= fired_action
		var/datum/director_signals/retry_signals = collect_signals()
		ensure_pool_targets(retry_signals)
		// Гарантия могла прийти с открытым GHOST (guaranteed_ghost в run_beat) - повторный отбор
		// не должен резать гост-кандидатов; пересечение с retry_candidates не даст ему расшириться.
		var/list/current_candidates = filter_candidates(retry_signals, was_guaranteed, allow_ghost_guarantee = was_guaranteed)
		for(var/datum/director_action/retry as anything in retry_candidates.Copy())
			if(!(retry in current_candidates))
				retry_candidates -= retry
				continue
			retry_candidates[retry] = current_candidates[retry]
		if(length(retry_candidates))
			var/datum/director_action/next_pick = pickweight(retry_candidates)
			message_admins("DIRECTOR: [fired_action.action_name()] не запустился ([execution_failure_detail(fired_action)]), выбираю замену.")
			announce_pick(next_pick, retry_candidates, was_guaranteed, retry_signals)

/datum/controller/subsystem/director/Topic(href, href_list)
	..()
	if(!check_rights(R_ADMIN))
		return
	if(href_list["cancel_pending"] && pending_action)
		deltimer(pending_timer_id)
		message_admins("[key_name_admin(usr)] отменил действие директора: [pending_action.action_name()].")
		log_admin("[key_name(usr)] отменил действие директора: [pending_action.action_name()].")
		director_log_beat(pending_signals, pending_action, DIRECTOR_BEAT_CANCELLED)
		pending_action = null
		pending_candidates = null
		pending_signals = null
		pending_timer_id = null
	if(href_list["reroll_pending"] && pending_action)
		deltimer(pending_timer_id)
		message_admins("[key_name_admin(usr)] заменил действие директора: [pending_action.action_name()].")
		log_admin("[key_name(usr)] заменил действие директора: [pending_action.action_name()].")
		replace_pending_action()

/// Реальная замена отклонённого админом выбора. Штатный путь - другой кандидат из того же
/// списка, но у ANTAG/GHOST-пиков список почти всегда из одного действия (гейт копилки),
/// и раньше кнопка замены молча очищала pending, ничего не предлагая взамен.
/// Отклонённое действие получает тот же карантин, что и провалившееся, копилка перецеливается
/// по средствам, и замена ищется свежим отбором той же ступени.
/// override_signals - подмена живого снимка мира для юнит-тестов.
/datum/controller/subsystem/director/proc/replace_pending_action(datum/director_signals/override_signals = null)
	var/datum/director_action/rejected = pending_action
	var/was_guaranteed = pending_guaranteed
	var/list/stale_candidates = pending_candidates
	var/datum/director_signals/rejected_signals = pending_signals
	pending_action = null
	pending_candidates = null
	pending_signals = null
	pending_timer_id = null
	// Карантин отклонённому: без него свежий отбор (и перевыбор цели копилки) тут же
	// предложат то же самое действие обратно.
	action_failure_cooldowns[rejected] = now() + DIRECTOR_FAILED_ACTION_COOLDOWN
	if(pool_saving[rejected.severity] == rejected)
		pool_saving[rejected.severity] = null
	if(islist(stale_candidates))
		stale_candidates -= rejected
		if(length(stale_candidates))
			announce_pick(pickweight(stale_candidates), stale_candidates, was_guaranteed, rejected_signals)
			return
	// Список исчерпан: собираем замену заново из той же ступени свежим отбором.
	var/datum/director_signals/signals = override_signals || collect_signals()
	ensure_pool_targets(signals)
	reroll_pool_target_affordable(rejected.severity, signals)
	// Гарантированный GHOST-пик без allow_ghost_guarantee не нашёл бы замену вовсе: фильтр
	// гарантии резал бы всю ступень. Для прочих ступеней флаг гасится сужением по severity ниже.
	var/list/candidates = filter_candidates(signals, was_guaranteed, allow_ghost_guarantee = was_guaranteed)
	for(var/datum/director_action/candidate as anything in candidates.Copy())
		if(candidate.severity != rejected.severity)
			candidates -= candidate
	if(!length(candidates))
		message_admins("DIRECTOR: замену для [rejected.action_name()] подобрать не удалось - в ступени [rejected.severity] сейчас нет готовых кандидатов.")
		return
	announce_pick(pickweight(candidates), candidates, was_guaranteed, signals)

#undef DIRECTOR_WAIT
#undef DIRECTOR_BEAT_EVERY
#undef DIRECTOR_POOL_CACHE_TIME
#undef DIRECTOR_EVENT_HEAVY_TICK_USAGE
#undef DIRECTOR_EVENT_HEAVY_LOG_COOLDOWN
#undef DIRECTOR_FAILED_ACTION_COOLDOWN
#undef DIRECTOR_FAILED_ACTION_RETRY_DELAY
