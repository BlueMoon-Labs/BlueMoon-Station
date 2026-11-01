/// Окно ввода, которое не открылось, обязано отпустить вызывающего.
///
/// Прод-раунд 10646: у призрака кончился пул окон tgui ("Pool exhausted"), и Jump to Mob
/// навсегда заснул в wait() со списком всех мобов мира. Каждый моб, живший в ту минуту,
/// потом уходил в hard delete с одной внешней ссылкой - мартышки и слаймы фермы первыми.
/datum/unit_test/tgui_input_open_failure_releases_caller
	var/caller_finished = FALSE

/// Повторяет jumptomob(): список выбора живёт в кадре, который ждёт ответа.
/datum/unit_test/tgui_input_open_failure_releases_caller/proc/prompt_like_jump_to_mob(mob/user, list/choices)
	var/datum/tgui_list_input/input = new(user, "Выбор", "Jump to Mob", choices, null, 0)
	input.ui_interact(user)
	input.wait()
	qdel(input)
	caller_finished = TRUE

/datum/unit_test/tgui_input_open_failure_releases_caller/proc/start_prompt(mob/user)
	var/datum/listed = new
	var/listed_ref = text_ref(listed)
	INVOKE_ASYNC(src, PROC_REF(prompt_like_jump_to_mob), user, list("target" = listed))
	qdel(listed)
	return listed_ref

/datum/unit_test/tgui_input_open_failure_releases_caller/proc/is_closed_after_failed_open(datum/prompt, mob/user)
	prompt.ui_interact(user)
	. = prompt.vars["closed"]
	qdel(prompt)

/datum/unit_test/tgui_input_open_failure_releases_caller/Run()
	// без клиента open() возвращает FALSE той же веткой, что и при исчерпанном пуле окон
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)

	var/listed_ref = start_prompt(user)
	sleep(world.tick_lag * 3)
	TEST_ASSERT(caller_finished, "tgui_list_input без открытого окна ждёт ответа вечно")
	var/datum/still_listed = locate(listed_ref)
	TEST_ASSERT(isnull(still_listed) || !QDELING(still_listed), "Ждущий кадр держит удалённый элемент списка выбора")
	still_listed = null

	TEST_ASSERT(is_closed_after_failed_open(new /datum/tgui_alert(user, "Текст", "Заголовок", list("Да", "Нет"), 0), user), "tgui_alert не закрылся, когда окно не открылось")
	TEST_ASSERT(is_closed_after_failed_open(new /datum/tgui_checkbox_input(user, "Текст", "Заголовок", list("а", "б"), 0, 1, 0), user), "tgui_checkbox_input не закрылся, когда окно не открылось")
	TEST_ASSERT(is_closed_after_failed_open(new /datum/tgui_input_number(user, "Текст", "Заголовок", 1, 10, 0, 0), user), "tgui_input_number не закрылся, когда окно не открылось")
	TEST_ASSERT(is_closed_after_failed_open(new /datum/tgui_input_text(user, "Текст", "Заголовок", "", 10, FALSE, TRUE, 0), user), "tgui_input_text не закрылся, когда окно не открылось")
	TEST_ASSERT(is_closed_after_failed_open(new /datum/tgui_input_color(user, "Текст", "Заголовок", "#ffffff", 0), user), "tgui_input_color не закрылся, когда окно не открылось")

/datum/tgui_async_probe

/datum/tgui_async_probe/proc/answer(value)
	return

/// Асинхронное окно, которое не открылось, удаляется сразу и не держит владельца колбека до тайм-аута.
/datum/unit_test/tgui_input_async_open_failure_releases_callback

/datum/unit_test/tgui_input_async_open_failure_releases_callback/proc/is_released(datum/prompt, mob/user)
	prompt.ui_interact(user)
	return QDELETED(prompt)

/datum/unit_test/tgui_input_async_open_failure_releases_callback/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/tgui_async_probe/probe = new
	var/baseline = refcount(probe)

	TEST_ASSERT(is_released(new /datum/tgui_alert/async(user, "Текст", "Заголовок", list("Да"), CALLBACK(probe, TYPE_PROC_REF(/datum/tgui_async_probe, answer)), 60 SECONDS, TRUE), user), "tgui_alert_async не удалился, когда окно не открылось")
	TEST_ASSERT(is_released(new /datum/tgui_list_input/async(user, "Текст", "Заголовок", list("а", "б"), null, CALLBACK(probe, TYPE_PROC_REF(/datum/tgui_async_probe, answer)), 60 SECONDS), user), "tgui_input_list_async не удалился, когда окно не открылось")
	TEST_ASSERT(is_released(new /datum/tgui_input_number/async(user, "Текст", "Заголовок", 5, CALLBACK(probe, TYPE_PROC_REF(/datum/tgui_async_probe, answer)), 60 SECONDS, FALSE), user), "tgui_input_number_async не удалился, когда окно не открылось")
	TEST_ASSERT(is_released(new /datum/tgui_input_text/async(user, "Текст", "Заголовок", "", CALLBACK(probe, TYPE_PROC_REF(/datum/tgui_async_probe, answer)), 10, FALSE, TRUE, 60 SECONDS), user), "tgui_input_text_async не удалился, когда окно не открылось")
	TEST_ASSERT(refcount(probe) == baseline, "Колбек неоткрывшегося асинхронного окна держит вызывающего")

	var/datum/tgui_list_input/async/list_input = new(user, "Текст", "Заголовок", list("а"), null, null, 0)
	TEST_ASSERT(list_input.title == "Заголовок" && list_input.message == "Текст", "tgui_list_input/async путает заголовок и текст")
	qdel(list_input)
	var/datum/tgui_input_text/async/text_input = new(user, "Текст", "Заголовок", "", null, 10, FALSE, TRUE, 0)
	TEST_ASSERT(text_input.title == "Заголовок" && text_input.message == "Текст", "tgui_input_text/async путает заголовок и текст")
	qdel(text_input)
	var/datum/tgui_input_number/async/number_input = new(user, "Текст", "Заголовок", 5, null, 0, FALSE)
	TEST_ASSERT(number_input.title == "Заголовок" && number_input.max_value == INFINITY && isnull(number_input.timeout), "tgui_input_number/async раскладывает аргументы не по местам")
	qdel(number_input)
	qdel(probe)
