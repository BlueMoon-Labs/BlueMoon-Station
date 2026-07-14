/// Накопитель лога решений; экспорт в director.json на каждом событии (rustg перезаписывает файл).
/datum/controller/subsystem/director
	var/list/beat_log = list()

/datum/controller/subsystem/director/proc/director_log_beat(datum/director_signals/signals, datum/director_action/action, result, list/rejected = null)
	// Симулятор ведёт свой лог в возврат director_simulate() - боевой beat_log/director.json не трогаем,
	// иначе 120 файловых записей за 2 симулированных часа засорили бы их за один клик админа.
	if(dry_run)
		return
	var/list/entry = list(
		"time" = (world.time - SSticker.round_start_time),
		"result" = result,
		"budget" = round(total_budget(), 0.1),
		"intensity" = signals ? signals.active_intensity : 0,
		"crew" = signals ? signals.effective_crew : 0,
		"dead_fraction" = signals ? round(signals.dead_fraction, 0.01) : 0,
		"living_antags" = signals ? signals.living_antags : 0,
		"evac" = signals ? signals.evac_state : 0,
		"action" = action ? action.action_name() : null,
		"severity" = action ? action.severity : null,
		"cost" = action ? action.cost : 0,
		// Экономика антаг-пулов: разбор прод-дампа "почему антагов нет" должен видеть нагрузку,
		// цель и кошельки прямо в бите, а не восстанавливать их по косвенным признакам.
		"antag_load" = round(antag_load(), 0.1),
		"antag_target" = signals ? round(antag_target(signals.effective_crew), 0.1) : 0,
		"wallet_antag" = round(budgets[DIRECTOR_SEVERITY_ANTAG], 0.1),
		"wallet_ghost" = round(budgets[DIRECTOR_SEVERITY_GHOST], 0.1),
	)
	if(length(rejected))
		entry["rejected"] = rejected
	beat_log += list(entry)
	export_director_log()

/datum/controller/subsystem/director/proc/export_director_log()
	var/list/out = list(
		"round_type" = GLOB.round_type,
		"profile" = profile ? "[profile.type]" : null,
		"beats" = beat_log,
	)
	rustg_file_write(json_encode(out), "[GLOB.log_directory]/director.json")
