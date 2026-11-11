/// Частичное обновление tgui, равное уже отправленному, не уходит повторно; изменение и перезагрузка страницы снова пропускают его.
/datum/unit_test/tgui_partial_update_dedupe

/datum/unit_test/tgui_partial_update_dedupe/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/tgui_dedupe_test_host/host = new
	var/datum/tgui/ui = new(user, host, "DedupeTest")
	var/datum/tgui_window/update_recorder/window = new
	ui.window = window
	var/skipped_before = GLOB.tgui_traffic_skipped["DedupeTest/update"]

	TEST_ASSERT(ui.send_partial_update(list("data" = list("charge" = 1))), "Первое обновление не ушло")
	TEST_ASSERT(!ui.send_partial_update(list("data" = list("charge" = 1))), "Повтор того же обновления ушёл клиенту")
	TEST_ASSERT(ui.send_partial_update(list("data" = list("charge" = 2))), "Изменённое обновление не ушло")
	TEST_ASSERT_EQUAL(length(window.sent), 2, "Клиенту ушло не два сообщения")
	var/repeat_length = length(window.sent[2])
	TEST_ASSERT_EQUAL(GLOB.tgui_traffic_skipped["DedupeTest/update"] - skipped_before, length(window.sent[1]), "Непосланный повтор не попал в раскладку трафика")

	ui.on_message("ready", list(), list())
	TEST_ASSERT(ui.send_partial_update(list("data" = list("charge" = 2))), "После перезагрузки страницы повтор не ушёл")
	TEST_ASSERT_EQUAL(length(window.sent[3]), repeat_length, "После перезагрузки ушло не то сообщение")
	TEST_ASSERT(findtext(tgui_traffic_report(), "трафик tgui за раунд"), "Раскладка трафика не собирается")

	ui.window = null
	qdel(ui)
	qdel(window)
	qdel(host)

/datum/tgui_dedupe_test_host

/datum/tgui_window/update_recorder
	var/list/sent = list()

/datum/tgui_window/update_recorder/New()
	id = "dedupe-test"

/datum/tgui_window/update_recorder/send_built_message(type, payload, message, force)
	sent += message
