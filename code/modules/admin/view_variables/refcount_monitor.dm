GLOBAL_LIST_EMPTY(refcount_monitors)

/// Живой монитор refcount: семплирует число внешних ссылок на цель и
/// репортит только дельты. Цель держится ТОЛЬКО text ref-ом - монитор
/// не мешает сборке и сам завершается, когда цель собрана.
/// Смысл: админ проводит эксперименты на проде (клиент вышел, закрыл
/// орбит-меню, снял HUD) и видит, какое действие отпускает ссылки.
/datum/refcount_monitor
	var/target_ref
	var/target_type
	var/owner_ckey
	var/sample_interval
	var/end_time
	var/last_count = -1
	var/samples = 0
	/// id отложенного Sample(): CALLBACK в таймере держит монитор, гасим его в Destroy.
	var/sample_timer

/datum/refcount_monitor/New(datum/target, client/owner, duration = 5 MINUTES, sample_interval = 1 SECONDS)
	src.target_ref = REF(target)
	src.target_type = "[target.type]"
	src.owner_ckey = owner.ckey
	src.sample_interval = max(sample_interval, REFCOUNT_MONITOR_MIN_INTERVAL)
	src.end_time = world.time + duration
	GLOB.refcount_monitors += src
	Report("старт мониторинга (интервал [src.sample_interval / (1 SECONDS)]с, до [duration / (1 SECONDS)]с). Короткие скачки на +-1 - VM-пины проходящих проков; значимы устойчивые дельты.")
	Sample()

/datum/refcount_monitor/Destroy()
	if(sample_timer)
		deltimer(sample_timer)
		sample_timer = null
	GLOB.refcount_monitors -= src
	return ..()

/datum/refcount_monitor/proc/Sample()
	if(QDELETED(src))
		return
	var/datum/target = locate(target_ref)
	if(isnull(target))
		Report("цель собрана GC или удалена - мониторинг завершён ([samples] замеров)")
		qdel(src)
		return
	var/count = EXTERNAL_REFCOUNT(target)
	samples++
	if(count != last_count)
		Report("внешних ссылок: [last_count < 0 ? "?" : last_count] -> [count][target.gc_destroyed ? " (в очереди GC)" : ""]")
		last_count = count
	if(world.time >= end_time)
		Report("время вышло - мониторинг завершён ([samples] замеров)")
		qdel(src)
		return
	sample_timer = addtimer(CALLBACK(src, PROC_REF(Sample)), sample_interval, TIMER_STOPPABLE)

/datum/refcount_monitor/proc/Report(msg)
	var/full_message = "REFCOUNT MONITOR [target_type] [target_ref]: [msg]"
	log_reftracker(full_message)
	var/client/owner = GLOB.directory[owner_ckey]
	if(owner)
		to_chat(owner, span_adminnotice(full_message), confidential = TRUE)

/// Остановить все мониторы refcount.
/client/proc/stop_refcount_monitors()
	set category = "Debug.1) Logs"
	set name = "Stop Refcount Monitors"
	set desc = "Остановить все активные мониторы refcount."
	if(!check_rights(R_DEBUG))
		return
	var/count = length(GLOB.refcount_monitors)
	for(var/datum/refcount_monitor/monitor as anything in GLOB.refcount_monitors.Copy())
		qdel(monitor)
	to_chat(src, span_notice("Остановлено мониторов: [count]."), confidential = TRUE)
