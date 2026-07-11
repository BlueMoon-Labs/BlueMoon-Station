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
	/// Отдельно для тяжёлых гост-антагов (GHOST): треки категорий полностью независимы
	var/last_ghost_heavy_at = 0
	/// world.time последнего успешного запуска вообще (для гарантированного бита и global_spacing)
	var/last_any_fired_at = 0
	/// Счётчик запусков по семействам действий (director_action.family) за раунд: общий фолл-офф повторов
	var/list/family_fired_counts = list()
	/// world.time последнего запуска на каждое семейство (пауза profile.family_spacing)
	var/list/family_last_fired_at = list()
	/// Активные вклады intensity: список list(name, amount, expires_at или 0 если "пока живо", severity или null для внешних вкладов)
	var/list/intensity_ledger = list()
	/// Счётчик запусков по ступеням за раунд (для share_correction)
	var/list/fired_counts = list()
	/// Кулдаун быстрых wizard-битов
	var/next_wizard_beat = 0
	/// Форс-события праздников (weight < 0) уже разобраны в этом раунде
	var/holiday_forced_done = FALSE
	/// Сигналы последнего бита (для панели)
	var/datum/director_signals/last_signals
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

/datum/controller/subsystem/director/Initialize(start_timeofday)
	register_event_actions()
	last_any_fired_at = now()
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
	var/list/current = currentrun
	while(current.len)
		var/datum/thing = current[current.len]
		current.len--
		if(thing)
			thing.process(wait * 0.1)
		else
			running.Remove(thing)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/director/proc/accumulate_drip()
	var/datum/director_signals/quick = last_signals || collect_signals()
	// Пустая станция: бюджет не копится, иначе первый вернувшийся экипаж встречала бы
	// очередь накоплений за все пустые часы.
	if(quick.effective_crew <= 0)
		return
	var/minutes = (now() - SSticker.round_start_time) / (1 MINUTES)
	var/rate = profile.base_drip * piecewise_eval(profile.time_curve, minutes) * piecewise_eval(profile.pop_curve, quick.effective_crew)
	if(quick.dead_fraction > profile.dead_fraction_threshold)
		rate *= 0.5
	distribute_to_budgets(rate * (wait / (1 MINUTES)))

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
/datum/controller/subsystem/director/proc/distribute_to_budgets(amount)
	if(!profile || !amount)
		return
	var/list/shares = profile.pool_shares
	var/list/active_sevs = list()
	var/flavor_share = 0
	for(var/sev in shares)
		if(sev == DIRECTOR_SEVERITY_FLAVOR)
			flavor_share = shares[sev]
			continue
		if(shares[sev] > 0)
			active_sevs += sev
	if(!length(active_sevs))
		return
	var/flavor_bonus = flavor_share / length(active_sevs)
	for(var/sev in active_sevs)
		budgets[sev] = max(0, budgets[sev] + amount * (shares[sev] + flavor_bonus))

/// Возврат средств в кошелёк конкретной ступени (провал запуска, refund_threat рулсета).
/datum/controller/subsystem/director/proc/refund_to_budget(severity, amount)
	if(amount <= 0)
		return
	budgets[severity] = max(0, budgets[severity] + amount)

/datum/controller/subsystem/director/proc/collect_signals()
	var/datum/director_signals/signals = new
	signals.update()
	signals.active_intensity = get_active_intensity()
	last_signals = signals
	return signals

/// Динамический вклад живых ANTAG-рулсетов: intensity рулсета * доля выживших назначенных.
/// Рулсеты не держат постоянных записей в intensity_ledger: вырезанные антаги
/// не должны глушить директора до конца раунда. Опционально помечает имена живых рулсетов в
/// live_names - их временные мосты в ledger вытесняются этим расчётом. В breakdown (если передан)
/// складываются строки list(имя, вклад, живых, назначено) - панель показывает их рядом с ledger.
/datum/controller/subsystem/director/proc/get_ruleset_intensity(list/live_names = null, list/breakdown = null)
	var/total = 0
	for(var/datum/director_action/action as anything in actions)
		if(action.director_kind != DIRECTOR_KIND_RULESET)
			continue
		var/datum/dynamic_ruleset/rule = action
		if(rule.occurrences <= 0 || !length(rule.assigned))
			continue
		var/living = 0
		for(var/datum/mind/assigned_mind as anything in rule.assigned)
			if(istype(assigned_mind) && assigned_mind.current && assigned_mind.current.stat != DEAD)
				living++
		if(living)
			var/contribution = rule.intensity * living / length(rule.assigned)
			total += contribution
			if(!isnull(breakdown))
				breakdown += list(list(rule.action_name(), contribution, living, length(rule.assigned)))
		if(!isnull(live_names))
			live_names[rule.action_name()] = TRUE
	return total

/datum/controller/subsystem/director/proc/get_active_intensity(list/breakdown = null)
	var/list/live_names = list()
	var/total = get_ruleset_intensity(live_names, breakdown)
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
	var/guaranteed = FALSE
	if(!forced && (now() - last_any_fired_at) > profile.max_quiet_time && signals.active_intensity < profile.quiet_intensity_threshold)
		guaranteed = TRUE
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
	var/list/candidates = filter_candidates(signals, guaranteed, reject_stats)
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
		spend_and_execute(picked, guaranteed ? "guaranteed" : "beat")
		director_log_beat(signals, picked, guaranteed ? DIRECTOR_BEAT_GUARANTEED : DIRECTOR_BEAT_FIRED, reject_stats)
	else
		announce_pick(picked, candidates, guaranteed, signals)
	return guaranteed ? DIRECTOR_BEAT_GUARANTEED : DIRECTOR_BEAT_FIRED

/// Отбор кандидатов с фильтрами темпа. guaranteed: только MINOR/MODERATE, бюджет игнорируется.
/// reject_stats (опционально): сюда считается отсев severity -> (DIRECTOR_REJECT_* -> число действий),
/// структурные пропуски (латеджойн-рулсеты, чужие ступени guaranteed-бита) не считаются.
/// verdicts (опционально, для панели): по-действийный вердикт на КАЖДОЕ действие, включая
/// структурные пропуски; у прошедших эффективный вес лежит в "eff_weight".
/datum/controller/subsystem/director/proc/filter_candidates(datum/director_signals/signals, guaranteed = FALSE, list/reject_stats = null, list/verdicts = null)
	var/list/result = list()
	var/intensity_full = signals.active_intensity >= profile.intensity_cap
	var/active_majors = count_active_majors()
	var/sec_needed = CEILING(signals.effective_crew / profile.security_per_players, 1)
	var/sec_short = signals.staffing[DIRECTOR_DEPT_SECURITY] < sec_needed
	var/dead_crisis = signals.dead_fraction > profile.dead_fraction_threshold
	for(var/datum/director_action/action as anything in actions)
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
		if(guaranteed && !(sev in list(DIRECTOR_SEVERITY_MINOR, DIRECTOR_SEVERITY_MODERATE)))
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
		// Гейт по кошельку своей ступени, а не по общему бюджету: MAJOR/ANTAG больше не голодают
		// из-за трат дешёвых MINOR/MODERATE.
		if(!guaranteed && budgets[action.severity] < action.cost)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_BUDGET,
				detail = isnull(verdicts) ? null : "[round(budgets[sev], 0.1)] из [action.cost]")
			continue
		if(!action.can_fire(signals))
			var/list/diag = isnull(verdicts) ? null : diagnose_can_fire(action, signals)
			note_reject(reject_stats, verdicts, action, DIRECTOR_REJECT_CAN_FIRE,
				verdict_reason = diag ? diag["reason"] : null, detail = diag ? diag["detail"] : null)
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
		if(action_weight > 0)
			var/weighted = max(1, round(action_weight * 100))
			result[action] = weighted
			if(!isnull(verdicts))
				var/list/entry = pool_entry(action, DIRECTOR_VERDICT_OK, null)
				entry["eff_weight"] = weighted
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
	return list(
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
		return FALSE
	action.occurrences++
	note_fired(action)
	return TRUE

/// Общий учёт запуска (и естественного, и форса админом)
/datum/controller/subsystem/director/proc/note_fired(datum/director_action/action)
	last_any_fired_at = now()
	fired_counts[action.severity] = (fired_counts[action.severity] || 0) + 1
	if(action.family)
		family_fired_counts[action.family] = (family_fired_counts[action.family] || 0) + 1
		family_last_fired_at[action.family] = now()
	if(DIRECTOR_IS_ANTAG_POOL(action.severity) && action.antag_heavy)
		if(action.severity == DIRECTOR_SEVERITY_GHOST)
			last_ghost_heavy_at = now()
		else
			last_antag_heavy_at = now()
	else
		last_fired_at[action.severity] = now()
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
	// хотим ли тратиться на антага: живых антагов по intensity меньше целевой доли.
	// Живые рулсеты считаются динамически (доля выживших), их мосты в ledger не дублируем.
	// Давление и порог считаются по ОБЕИМ антаг-ступеням: латеджойн-инжекция отвечает
	// на общий дефицит антагонистов, а не на дефицит одной категории.
	var/list/live_names = list()
	var/antag_intensity = get_ruleset_intensity(live_names)
	for(var/list/entry in intensity_ledger)
		if(DIRECTOR_IS_ANTAG_POOL(entry[4]) && !live_names[entry[1]] && (!entry[3] || entry[3] > now()))
			antag_intensity += entry[2]
	var/antag_pool_share = (profile.pool_shares[DIRECTOR_SEVERITY_ANTAG] || 0) + (profile.pool_shares[DIRECTOR_SEVERITY_GHOST] || 0)
	if(antag_intensity >= profile.intensity_cap * antag_pool_share * 2)
		return
	var/list/candidates = list()
	for(var/datum/director_action/action as anything in actions)
		if(action.director_kind != DIRECTOR_KIND_RULESET)
			continue
		var/datum/dynamic_ruleset/latejoin/rule = action
		if(!istype(rule))
			continue
		if(!spacing_allows(rule) || budgets[rule.severity] < rule.cost || !rule.can_fire(signals))
			continue
		rule.candidates = list(newPlayer)
		rule.trim_candidates()
		if(rule.ready())
			candidates[rule] = max(1, round(rule.get_weight(signals) * repeat_falloff(rule) * 100))
	if(!length(candidates))
		return
	var/datum/dynamic_ruleset/latejoin/picked = pickweight(candidates)
	spend_and_execute(picked, "latejoin")
	director_log_beat(signals, picked, DIRECTOR_BEAT_FIRED)

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
	spend_and_execute(fired_action, was_guaranteed ? "guaranteed" : "beat")
	director_log_beat(fired_signals, fired_action, was_guaranteed ? DIRECTOR_BEAT_GUARANTEED : DIRECTOR_BEAT_FIRED)
	pending_action = null
	pending_candidates = null
	pending_signals = null
	pending_timer_id = null

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
	if(href_list["reroll_pending"] && pending_action)
		deltimer(pending_timer_id)
		pending_candidates -= pending_action
		message_admins("[key_name_admin(usr)] заменил действие директора: [pending_action.action_name()].")
		log_admin("[key_name(usr)] заменил действие директора: [pending_action.action_name()].")
		if(length(pending_candidates))
			var/datum/director_action/next_pick = pickweight(pending_candidates)
			announce_pick(next_pick, pending_candidates, pending_guaranteed, pending_signals)
		else
			pending_action = null
			pending_signals = null

#undef DIRECTOR_WAIT
#undef DIRECTOR_BEAT_EVERY
#undef DIRECTOR_POOL_CACHE_TIME
