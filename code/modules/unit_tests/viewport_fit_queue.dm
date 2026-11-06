/// Очередь без клиента: вместо winget считает подгонки и даёт вмешаться посреди подгонки.
/datum/viewport_fit_queue/counting
	var/fits = 0
	var/datum/callback/during_fit

/datum/viewport_fit_queue/counting/fit()
	fits++
	during_fit?.Invoke()

/datum/viewport_fit_queue/counting/Destroy()
	during_fit = null
	return ..()

/// Логин, смена вида и полноэкранный режим просят подгонку почти одновременно - таймер один.
/datum/unit_test/viewport_fit_requests_coalesce

/datum/unit_test/viewport_fit_requests_coalesce/Run()
	var/datum/viewport_fit_queue/counting/queue = allocate(/datum/viewport_fit_queue/counting)
	queue.request()
	var/first_timer = queue.timer_id
	TEST_ASSERT_NOTNULL(first_timer, "Запрос не поставил таймер подгонки")
	queue.request()
	queue.request()
	TEST_ASSERT_EQUAL(queue.timer_id, first_timer, "Повторный запрос поставил второй таймер")

	// Ручной верб исполняет отложенный запрос сам, второй подгонки по таймеру быть не должно
	queue.run_fit()
	TEST_ASSERT_EQUAL(queue.fits, 1, "Подгонка не выполнилась ровно один раз")
	TEST_ASSERT_NULL(queue.timer_id, "После подгонки остался отложенный запрос")
	TEST_ASSERT_NULL(timeleft(first_timer), "Таймер склеенных запросов пережил подгонку")

/// Запрос посреди подгонки не запускает вторую параллельно, а ждёт конца первой.
/datum/unit_test/viewport_fit_request_during_fit_is_deferred

/datum/unit_test/viewport_fit_request_during_fit_is_deferred/Run()
	var/datum/viewport_fit_queue/counting/queue = allocate(/datum/viewport_fit_queue/counting)
	queue.during_fit = CALLBACK(queue, TYPE_PROC_REF(/datum/viewport_fit_queue, request))
	queue.run_fit()
	TEST_ASSERT_EQUAL(queue.fits, 1, "Запрос посреди подгонки запустил её повторно")
	TEST_ASSERT_NOTNULL(queue.timer_id, "Запрос посреди подгонки потерялся")
	TEST_ASSERT(!queue.requested_while_running, "Флаг отложенного запроса не сброшен")

	// Тот же класс через верб: игрок жмёт Fit Viewport, пока идёт подгонка по таймеру
	queue.during_fit = CALLBACK(queue, TYPE_PROC_REF(/datum/viewport_fit_queue, run_fit))
	queue.run_fit()
	TEST_ASSERT_EQUAL(queue.fits, 2, "Повторный верб вложил вторую подгонку в первую")
	TEST_ASSERT_NOTNULL(queue.timer_id, "Повторный верб посреди подгонки потерялся")
