/datum/unit_test/timer_sanity/Run()
	TEST_ASSERT(SStimer.bucket_count >= 0,
		"SStimer is going into negative bucket count from something")

/// Сколько тиков даём планировщику на то, чтобы он успел ошибиться.
#define LONG_TIMER_GRACE_TICKS 5

/**
 * Таймеры длиннее одного оборота колеса бакетов (BUCKET_LEN - ровно минута) в бакеты не
 * влезают и ждут своей очереди в second_queue. Старая арифметика TIMER_MAX/BUCKET_POS
 * впускала такой таймер в бакет ПОЗАДИ курсора, и он срабатывал тем же проходом.
 *
 * Наружу это вылезало так: tgui_alert с таймаутом от минуты закрывался сам собой, а бонус
 * к операциям от стерилизина (ровно 600 децисекунд, то есть впритык к границе колеса) гас
 * раньше, чем хирург успевал сделать шаг - без бонуса и без зелёной строки на сканере.
 */
/datum/unit_test/long_timers_do_not_fire_early
	var/fired = FALSE

/datum/unit_test/long_timers_do_not_fire_early/proc/mark_fired()
	fired = TRUE

/datum/unit_test/long_timers_do_not_fire_early/Run()
	var/timer_id = addtimer(CALLBACK(src, PROC_REF(mark_fired)), 2 MINUTES, TIMER_STOPPABLE)
	TEST_ASSERT_NOTNULL(timer_id, "Премиса: остановимый таймер обязан вернуть id")

	var/datum/timedevent/scheduled = SStimer.timer_id_dict[timer_id]
	TEST_ASSERT_NOTNULL(scheduled, "Премиса: остановимый таймер обязан попасть в timer_id_dict")
	TEST_ASSERT(scheduled.timeToRun > world.time + 1 MINUTES, "Таймер на две минуты назначен раньше, чем через минуту")

	for(var/grace_tick in 1 to LONG_TIMER_GRACE_TICKS)
		stoplag(1)

	TEST_ASSERT(!fired, "Таймер на две минуты сработал в первые тики: длинные таймеры снова садятся в бакет позади курсора")
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[timer_id], "Таймер на две минуты исчез из очереди, не отработав")

	deltimer(timer_id)

#undef LONG_TIMER_GRACE_TICKS
