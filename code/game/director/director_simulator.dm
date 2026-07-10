/// Снимок боевого состояния SSdirector перед симуляцией. Пара к restore_simulation_state():
/// всё, что dry_run-прогон способен замутировать, попадает сюда и восстанавливается оттуда.
/datum/controller/subsystem/director/proc/capture_simulation_state()
	var/list/state = list()
	state["profile"] = profile
	state["budgets"] = budgets.Copy()
	state["actions"] = actions.Copy()
	state["intensity_ledger"] = intensity_ledger.Copy()
	state["fired_counts"] = fired_counts.Copy()
	state["last_fired_at"] = last_fired_at.Copy()
	state["last_any_fired_at"] = last_any_fired_at
	state["last_antag_heavy_at"] = last_antag_heavy_at
	state["dry_run"] = dry_run
	state["paused"] = paused
	// pending_*: если админ дёрнет симулятор посреди живого окна отмены, run_beat() увидит
	// pending_action и вернёт DIRECTOR_BEAT_IDLE на каждом симулированном бите. Симулятор их
	// обнуляет на прогон - настоящее окно отмены не должно пострадать, поэтому сохраняем.
	state["pending_action"] = pending_action
	state["pending_candidates"] = pending_candidates
	state["pending_guaranteed"] = pending_guaranteed
	state["pending_timer_id"] = pending_timer_id
	state["pending_signals"] = pending_signals
	// Тумблер случайных событий симулятор форсит в TRUE (см. director_simulate) - вернём как было.
	state["allow_random_events"] = CONFIG_GET(flag/allow_random_events)
	// occurrences живут на самих датумах действий - actions.Copy() копирует список, но не датумы.
	// dry_run-учёт (spend_and_execute) их инкрементирует, поэтому снимаем слепок, иначе симуляция
	// посреди раунда съедала бы max_occurrences реальных событий.
	var/list/occurrences_snapshot = list()
	for(var/datum/director_action/action as anything in actions)
		occurrences_snapshot[action] = action.occurrences
	state["occurrences"] = occurrences_snapshot
	return state

/// Полное восстановление боевого состояния после симуляции. Вызывается и на нормальном пути,
/// и при аварии прогона (catch в director_simulate): рантайм посреди симуляции не должен
/// оставить живой директор с dry_run = TRUE (реальные действия перестали бы исполняться),
/// time_override в будущем и форснутым allow_random_events.
/datum/controller/subsystem/director/proc/restore_simulation_state(list/state)
	CONFIG_SET(flag/allow_random_events, state["allow_random_events"])
	var/list/occurrences_snapshot = state["occurrences"]
	for(var/datum/director_action/action as anything in occurrences_snapshot)
		action.occurrences = occurrences_snapshot[action]
	time_override = 0
	profile = state["profile"]
	budgets = state["budgets"]
	actions = state["actions"]
	intensity_ledger = state["intensity_ledger"]
	fired_counts = state["fired_counts"]
	last_fired_at = state["last_fired_at"]
	last_any_fired_at = state["last_any_fired_at"]
	last_antag_heavy_at = state["last_antag_heavy_at"]
	dry_run = state["dry_run"]
	paused = state["paused"]
	pending_action = state["pending_action"]
	pending_candidates = state["pending_candidates"]
	pending_guaranteed = state["pending_guaranteed"]
	pending_timer_id = state["pending_timer_id"]
	pending_signals = state["pending_signals"]

/// Оффлайн-прогон битов директора: hours часов раунда за один тик, без реального ожидания и без
/// исполнения действий взаправду (dry_run). Годится и для CI-санити, и для админ-верба поверх живого
/// раунда - мутирует состояние SSdirector и полностью восстанавливает его перед возвратом,
/// в том числе при рантайме посреди прогона.
/proc/director_simulate(round_type = null, hours = 2, sim_crew = 40)
	var/datum/controller/subsystem/director/D = SSdirector
	var/list/saved = D.capture_simulation_state()
	D.pending_action = null
	D.pending_candidates = null
	D.pending_guaranteed = FALSE
	D.pending_timer_id = null
	D.pending_signals = null
	// filter_candidates() отсекает все DIRECTOR_KIND_EVENT-действия, если сервер не разрешил
	// случайные события (config/config.txt) - в CI/дев-конфиге флаг обычно выключен.
	// Симулятор проверяет пейсинг профиля, а не текущий тумблер админа, поэтому включает его
	// на время прогона; вся симуляция синхронна (без sleep), другой код блип не увидит.
	CONFIG_SET(flag/allow_random_events, TRUE)

	D.dry_run = TRUE
	D.profile = director_profile_for(round_type || GLOB.round_type)
	D.reset_budgets(0)
	D.intensity_ledger = list()
	D.fired_counts = list()
	D.last_fired_at = list()
	D.last_antag_heavy_at = 0
	var/list/log_out = list()
	var/datum/director_signals/signals = new
	signals.effective_crew = sim_crew
	signals.staffing = list(DIRECTOR_DEPT_SECURITY = max(1, round(sim_crew / 12)),
		DIRECTOR_DEPT_ENGINEERING = max(1, round(sim_crew / 15)), DIRECTOR_DEPT_MEDICAL = max(1, round(sim_crew / 15)),
		DIRECTOR_DEPT_SCIENCE = 1, DIRECTOR_DEPT_SUPPLY = 1, DIRECTOR_DEPT_COMMAND = 1)
	var/sim_now = 0
	var/beat_step = 1 MINUTES
	D.time_override = world.time
	D.last_any_fired_at = D.time_override
	try
		for(var/i in 1 to (hours * 60))
			sim_now += beat_step
			D.time_override = world.time + sim_now
			// капля за минуту, разложенная по кошелькам ступеней
			var/minutes = sim_now / (1 MINUTES)
			var/rate = D.profile.base_drip * piecewise_eval(D.profile.time_curve, minutes) * piecewise_eval(D.profile.pop_curve, signals.effective_crew)
			D.distribute_to_budgets(rate)
			signals.active_intensity = D.get_active_intensity()
			// Сбрасываем перед битом: note_fired выставит их, если этот бит выстрелит.
			D.sim_last_severity = null
			D.sim_last_antag_heavy = FALSE
			var/result = D.run_beat(signals)
			log_out += list(list("minute" = minutes, "result" = result, "budget" = round(D.total_budget(), 0.1), \
				"intensity" = signals.active_intensity, "severity" = D.sim_last_severity, "antag_heavy" = D.sim_last_antag_heavy))
	catch(var/exception/sim_error)
		D.restore_simulation_state(saved)
		log_runtime("DIRECTOR: симуляция аварийно прервана: [sim_error] ([sim_error.file]:[sim_error.line])")
		message_admins("DIRECTOR: симуляция аварийно прервана рантаймом ([sim_error]), боевое состояние директора восстановлено.")
		return log_out
	D.restore_simulation_state(saved)
	return log_out

/client/proc/director_simulate_verb()
	set category = "Admin.Events"
	set name = "Director Simulate"
	if(!check_rights(R_ADMIN))
		return
	var/round_type = input(usr, "Тип раунда", "Симулятор") as null|anything in list(ROUNDTYPE_DYNAMIC_LIGHT, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_EXTENDED)
	if(!round_type)
		return
	var/crew = input(usr, "Экипаж", "Симулятор", 40) as num
	if(isnull(crew))
		return
	crew = clamp(crew, 5, 200)
	var/list/result = director_simulate(round_type, 2, crew)
	var/fired = 0
	for(var/list/entry in result)
		if(entry["result"] == DIRECTOR_BEAT_FIRED || entry["result"] == DIRECTOR_BEAT_GUARANTEED)
			fired++
	message_admins("[key_name_admin(usr)] прогнал симуляцию директора: [round_type], 2 часа, [crew] экипажа - [fired] действий. Полный лог в director_sim.json.")
	log_admin("[key_name(usr)] прогнал симуляцию директора: [round_type], 2 часа, [crew] экипажа - [fired] действий.")
	rustg_file_write(json_encode(result), "[GLOB.log_directory]/director_sim.json")
