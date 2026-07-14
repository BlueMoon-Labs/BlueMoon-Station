/// Админ-вербы диагностики тик-спайков (SStick_spikes). См. шапку modular_bluemoon/code/controllers/subsystem/tick_spikes.dm

/// Идентификатор часов rust-g для busy-wait симуляции
#define TICK_SPIKE_SIM_CLOCK "tick_spike_sim"
/// Максимальная длительность синтетического фриза, мс
#define TICK_SPIKE_SIM_MAX_MS 2000

/client/proc/tick_spikes_report()
	set category = "Debug"
	set name = "Tick Spikes Report"
	set desc = "Отчёт детектора тик-спайков: пойманные фризы, их источники и телеметрия."

	if(!check_rights(R_DEBUG))
		return

	var/report = SStick_spikes.build_report()
	usr << browse("<html><head><meta charset='utf-8'><title>Tick Spikes</title></head><body><pre>[html_encode(report)]</pre></body></html>", "window=tick_spikes_report;size=900x700")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Tick Spikes Report")

/client/proc/tick_spikes_capture()
	set category = "Debug"
	set name = "Tick Spikes Capture"
	set desc = "Включить/выключить сессию захвата: на каждом спайке будет дамп окна профайлера в JSON."

	if(!check_rights(R_DEBUG))
		return

	if(SStick_spikes.capture_until)
		SStick_spikes.stop_capture(automatic = FALSE, stopper_key = key)
		log_admin("[key_name(usr)] выключил захват тик-спайков.")
		message_admins("[key_name_admin(usr)] выключил захват тик-спайков.")
		return

	var/duration_minutes = input(usr, "Длительность захвата в минутах. Профайлер будет включён на всё время захвата (небольшой оверхед).", "Захват тик-спайков", 10) as num|null
	if(isnull(duration_minutes) || duration_minutes <= 0)
		return
	duration_minutes = min(duration_minutes, 120)
	SStick_spikes.start_capture(duration_minutes MINUTES, key)
	log_admin("[key_name(usr)] включил захват тик-спайков на [duration_minutes] мин.")
	message_admins("[key_name_admin(usr)] включил захват тик-спайков на [duration_minutes] мин. Дампы и лог: папка логов раунда, tick_spikes.log / tick_spike_profile_N.json.")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Tick Spikes Capture")

/client/proc/tick_spikes_simulate()
	set category = "Debug"
	set name = "Simulate Tick Spike"
	set desc = "Синтетический фриз сервера на N мс для проверки детектора (busy-wait в одном тике)."

	if(!check_rights(R_DEBUG))
		return

	var/freeze_ms = input(usr, "Длительность фриза в мс (50-[TICK_SPIKE_SIM_MAX_MS]). Сервер реально замрёт на это время!", "Симуляция тик-спайка", 250) as num|null
	if(isnull(freeze_ms))
		return
	freeze_ms = clamp(freeze_ms, 50, TICK_SPIKE_SIM_MAX_MS)

	log_admin("[key_name(usr)] запустил синтетический тик-спайк на [freeze_ms]мс.")
	message_admins("[key_name_admin(usr)] запустил синтетический тик-спайк на [freeze_ms]мс.")

	SStick_spikes.next_spike_tag = "СИНТЕТИКА [freeze_ms]мс от [key]"
	var/started_at = rustg_time_milliseconds(TICK_SPIKE_SIM_CLOCK)
	var/spin_guard = 0
	while(rustg_time_milliseconds(TICK_SPIKE_SIM_CLOCK) - started_at < freeze_ms)
		// busy-wait: намеренно жжём тик без sleep, чтобы фриз лёг в один тик, как реальный залипший прок
		spin_guard++
		if(spin_guard > 100000000)
			break

	to_chat(usr, span_adminnotice("Синтетический фриз [freeze_ms]мс завершён. Детектор должен зафиксировать спайк в течение секунды - смотри Tick Spikes Report."))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Simulate Tick Spike")

#undef TICK_SPIKE_SIM_CLOCK
#undef TICK_SPIKE_SIM_MAX_MS
