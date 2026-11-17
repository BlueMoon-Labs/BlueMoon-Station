/// Разбор /proc для блока спайка: синтетические тексты в формате ядра.
/datum/unit_test/sched_probe_parsers/Run()
	// 13 цифр в нс: младшие разряды миллисекунд обязаны остаться точными
	var/list/schedstat = parse_proc_schedstat("5400123456789 812345678901 99887766\n")
	TEST_ASSERT_EQUAL(schedstat["run_ms"], 400123, "run_ms из schedstat: [schedstat["run_ms"]]")
	TEST_ASSERT_EQUAL(schedstat["wait_ms"], 812345, "wait_ms из schedstat: [schedstat["wait_ms"]]")
	TEST_ASSERT_EQUAL(schedstat["slices"], 887766, "срезы из schedstat: [schedstat["slices"]]")

	var/list/stat = parse_proc_self_stat("4242 (Dream Daemon) S 1 4242 4242 0 -1 4194560 7654321 0 17 0 2701234 51234 0 0 20 0 9 0 100 3000000000 500000 4294967295 1 1 0 0 0 0 0 0 0 0 0 0 17 3 0 0 33 0 0")
	TEST_ASSERT_NOTNULL(stat, "Имя процесса с пробелом сломало разбор /proc/self/stat")
	TEST_ASSERT_EQUAL(stat["minflt"], 654321, "minflt: [stat["minflt"]]")
	TEST_ASSERT_EQUAL(stat["majflt"], 17, "majflt: [stat["majflt"]]")
	TEST_ASSERT_EQUAL(stat["utime"], 701234, "utime: [stat["utime"]]")
	TEST_ASSERT_EQUAL(stat["stime"], 51234, "stime: [stat["stime"]]")
	TEST_ASSERT_EQUAL(stat["threads"], 9, "num_threads: [stat["threads"]]")
	TEST_ASSERT_EQUAL(stat["blkio"], 33, "delayacct_blkio_ticks: [stat["blkio"]]")

	var/list/host = parse_proc_stat_cpu("cpu  100 2 300 4000 50 6 7 80 0 0\ncpu0 50 1 150 2000 25 3 3 40 0 0\ncpu1 50 1 150 2000 25 3 4 40 0 0\nintr 1 2 3\n")
	TEST_ASSERT_EQUAL(host["total"], 4545, "Сумма тиков /proc/stat: [host["total"]]")
	TEST_ASSERT_EQUAL(host["steal"], 80, "steal: [host["steal"]]")
	TEST_ASSERT_EQUAL(host["cpus"], 2, "Число CPU: [host["cpus"]]")

	var/list/psi = parse_proc_pressure("some avg10=0.00 avg60=0.00 avg300=0.00 total=1234567\nfull avg10=0.00 avg60=0.00 avg300=0.00 total=89000\n")
	TEST_ASSERT_EQUAL(psi["some"], 1234, "PSI some в мс: [psi["some"]]")
	TEST_ASSERT_EQUAL(psi["full"], 89, "PSI full в мс: [psi["full"]]")

	var/list/v2 = parse_cgroup_cpu_stat("usage_usec 100\nnr_periods 50\nnr_throttled 7\nthrottled_usec 450000\n")
	TEST_ASSERT_EQUAL(v2["throttled_ms"], 450, "throttled_usec cgroup v2: [v2["throttled_ms"]]")
	TEST_ASSERT_EQUAL(v2["throttled_n"], 7, "nr_throttled cgroup v2: [v2["throttled_n"]]")
	var/list/v1 = parse_cgroup_cpu_stat("nr_periods 50\nnr_throttled 3\nthrottled_time 120000000\n")
	TEST_ASSERT_EQUAL(v1["throttled_ms"], 120, "throttled_time cgroup v1: [v1["throttled_ms"]]")

	TEST_ASSERT_EQUAL(proc_key_counter("Name:\tDreamDaemon\nvoluntary_ctxt_switches:\t1234\nnonvoluntary_ctxt_switches:\t56\n", "voluntary_ctxt_switches"), 1234, "Ключ voluntary спутан с nonvoluntary")
	TEST_ASSERT_EQUAL(proc_counter_delta(999990, 15), 25, "Перенос счётчика через ноль")

	var/list/paths = sched_probe_cgroup_candidates("0::/system.slice/byond.service\n")
	TEST_ASSERT_EQUAL(paths[1], "/sys/fs/cgroup/system.slice/byond.service/cpu.stat", "Путь cgroup v2: [paths[1]]")

/// Вердикт по разностям: каждый из исходов, которые изнутри DM выглядят одинаково.
/datum/unit_test/sched_probe_verdicts/Run()
	var/list/background = list("ms" = 1000, "run_ms" = 300, "wait_ms" = 10)
	// Окно 700мс, столл 500мс: фон на спокойные 200мс - 60мс CPU и 2мс очереди
	var/list/busy = list("ms" = 700, "run_ms" = 560, "wait_ms" = 3, "utime" = 57, "stime" = 1, "majflt" = 0, "minflt" = 10, "threads" = 9)
	TEST_ASSERT(findtext(sched_probe_verdict(busy, 500, background), "на процессоре"), "Поток на CPU всё окно столла: [sched_probe_verdict(busy, 500, background)]")

	var/list/starved = list("ms" = 700, "run_ms" = 70, "wait_ms" = 480, "utime" = 7, "stime" = 0, "majflt" = 0, "minflt" = 1, "threads" = 9, "host_total" = 1000, "host_steal" = 200)
	var/starved_verdict = sched_probe_verdict(starved, 500, background)
	TEST_ASSERT(findtext(starved_verdict, "очереди планировщика") && findtext(starved_verdict, "steal"), "Очередь планировщика при steal: [starved_verdict]")

	var/list/throttled = list("ms" = 700, "run_ms" = 70, "wait_ms" = 5, "cg_throttled_ms" = 450, "cg_throttled_n" = 5, "majflt" = 0)
	TEST_ASSERT(findtext(sched_probe_verdict(throttled, 500, background), "cgroup"), "Троттлинг cgroup не назван")

	var/list/disk = list("ms" = 700, "run_ms" = 70, "wait_ms" = 3, "blkio" = 45, "majflt" = 0)
	TEST_ASSERT(findtext(sched_probe_verdict(disk, 500, background), "диск"), "Ожидание блочного I/O не названо")

	var/list/asleep = list("ms" = 700, "run_ms" = 65, "wait_ms" = 3, "majflt" = 0, "blkio" = 0)
	TEST_ASSERT(findtext(sched_probe_verdict(asleep, 500, background), "спал или ждал"), "Поток не на CPU и не в очереди: [sched_probe_verdict(asleep, 500, background)]")

	var/list/lines = sched_probe_lines(starved, 500, background)
	TEST_ASSERT_EQUAL(length(lines), 3, "Строк /proc в блоке: [lines.Join(" || ")]")
	TEST_ASSERT(findtext(lines[1], "в очереди планировщика +480мс"), "Строка процесса: [lines[1]]")
	TEST_ASSERT(findtext(lines[2], "steal 20%"), "Строка хоста: [lines[2]]")

/// Блок спайка тем же путём, что в игре: строки /proc есть ровно тогда, когда /proc читается.
/datum/unit_test/sched_probe_in_spike_block/Run()
	var/datum/controller/subsystem/tick_spikes/recorder = SStick_spikes
	var/old_suppress = recorder.suppress_side_effects
	var/old_ignore_empty = recorder.ignore_empty_server
	var/old_self_inflicted = recorder.self_inflicted_until
	var/old_available = recorder.sched_probe_available
	recorder.suppress_side_effects = TRUE
	recorder.ignore_empty_server = TRUE
	recorder.self_inflicted_until = 0
	recorder.reset_state()
	recorder.sched_probe_available = TRUE

	var/list/live = read_sched_probe(recorder.now_ms())
	recorder.sched_probe_last = live
	recorder.sample_tick(1000, 300, 5, 10, 5)
	recorder.sample_tick(1650, 300.5, 5, 10, 5)
	TEST_ASSERT_EQUAL(length(recorder.spike_events), 1, "Синтетический спайк 600мс не записан блоком")
	var/event_text = recorder.spike_events[1]
	if(live)
		TEST_ASSERT(findtext(event_text, "процесс (/proc) за"), "На Linux блок спайка обязан нести строку /proc: [event_text]")
		TEST_ASSERT(recorder.sched_probe_last != live, "Снимок после столла не стал базой следующего окна")
	else
		TEST_ASSERT(!findtext(event_text, "/proc"), "Без /proc блок не должен ничего о нём писать: [event_text]")

	recorder.reset_state()
	recorder.suppress_side_effects = old_suppress
	recorder.ignore_empty_server = old_ignore_empty
	recorder.self_inflicted_until = old_self_inflicted
	recorder.sched_probe_available = old_available
