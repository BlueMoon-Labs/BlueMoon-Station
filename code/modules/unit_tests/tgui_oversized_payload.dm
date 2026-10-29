/// Сборка большой tgui-нагрузки из чанков: повторы безвредны, дыры и битый JSON не доходят до обработчика, а брошенная передача сообщается клиенту.
/datum/unit_test/tgui_oversized_payload

/datum/unit_test/tgui_oversized_payload/Run()
	var/datum/tgui_window/payload_test/window = new
	var/datum/payload_test_subscriber/subscriber = new
	window.subscribe(subscriber, TYPE_PROC_REF(/datum/payload_test_subscriber, on_message))

	TEST_ASSERT(window.create_oversized_payload("whole", "test/assembled", 3), "Передача создаётся.")
	window.on_message("payloadChunk", list("id" = "whole", "chunk" = "{\"name\":", "index" = 1))
	window.on_message("payloadChunk", list("id" = "whole", "chunk" = "{\"name\":", "index" = 1))
	var/list/oversized_payload = window.oversized_payloads["whole"]
	var/list/chunks = oversized_payload["chunks"]
	TEST_ASSERT_EQUAL(length(chunks), 1, "Повтор уже принятого чанка не дописывается в склейку.")
	var/list/last_ack = window.sent[length(window.sent)]
	TEST_ASSERT_EQUAL(last_ack[1], "acknowlegePayloadChunk", "Повтор тоже подтверждается.")
	TEST_ASSERT_EQUAL(last_ack[2]["index"], 1, "Подтверждение несёт номер чанка.")
	window.on_message("payloadChunk", list("id" = "whole", "chunk" = "\"капитан\"", "index" = 2))
	window.on_message("payloadChunk", list("id" = "whole", "chunk" = "}", "index" = 3))
	TEST_ASSERT_EQUAL(subscriber.received_type, "test/assembled", "Собранная нагрузка уходит обработчику.")
	TEST_ASSERT_EQUAL(subscriber.received_payload?["name"], "капитан", "Склейка разбирается как один JSON.")
	TEST_ASSERT_EQUAL(subscriber.received_raw, "{\"name\":\"капитан\"}", "Исходная строка лежит в href_list.")
	TEST_ASSERT_NULL(window.oversized_payloads["whole"], "Собранная передача убирается.")

	TEST_ASSERT(window.create_oversized_payload("gap", "test/assembled", 3), "Вторая передача создаётся.")
	TEST_ASSERT(!window.append_payload_chunk("gap", "{", 2), "Чанк через дыру отвергается.")
	TEST_ASSERT_NULL(window.oversized_payloads["gap"], "Передача с дырой бросается целиком.")

	subscriber.received_type = null
	TEST_ASSERT(window.create_oversized_payload("broken", "test/assembled", 1), "Третья передача создаётся.")
	TEST_ASSERT(!window.append_payload_chunk("broken", "{\"name\":", 1), "Битый JSON не собирается.")
	TEST_ASSERT_NULL(subscriber.received_type, "Битый JSON не доходит до обработчика.")

	TEST_ASSERT(window.create_oversized_payload("stale", "test/assembled", 2), "Четвёртая передача создаётся.")
	window.append_payload_chunk("stale", "{", 1)
	window.expire_oversized_payload("stale")
	TEST_ASSERT_NULL(window.oversized_payloads["stale"], "Просроченная передача убирается.")
	var/list/dropped = window.sent[length(window.sent)]
	TEST_ASSERT_EQUAL(dropped[1], "payloadDropped", "Клиент узнаёт о брошенной передаче.")
	TEST_ASSERT_EQUAL(dropped[2]["id"], "stale", "В сообщении id брошенной передачи.")

	window.on_message("oversizedPayloadRequest", list("id" = "nocount", "type" = "test/assembled"))
	TEST_ASSERT_NULL(window.oversized_payloads["nocount"], "Запрос без числа частей не создаёт передачу.")
	window.on_message("oversizedPayloadRequest", list("id" = "half", "type" = "test/assembled", "chunkCount" = 1.5))
	TEST_ASSERT_NULL(window.oversized_payloads["half"], "Дробное число частей не принимается.")
	window.on_message("oversizedPayloadRequest", "garbage")
	window.on_message("payloadChunk", "garbage")

	window.on_message("oversizedPayloadRequest", list("id" = "twice", "type" = "test/assembled", "chunkCount" = 2))
	window.on_message("payloadChunk", list("id" = "twice", "chunk" = "{\"name\":", "index" = 1))
	window.on_message("oversizedPayloadRequest", list("id" = "twice", "type" = "test/assembled", "chunkCount" = 2))
	var/list/repeat_response = window.sent[length(window.sent)]
	TEST_ASSERT_EQUAL(repeat_response[1], "oversizePayloadResponse", "На повтор запроса сервер отвечает.")
	TEST_ASSERT(repeat_response[2]["allow"], "Повтор запроса не отменяет идущую передачу.")
	oversized_payload = window.oversized_payloads["twice"]
	chunks = oversized_payload?["chunks"]
	TEST_ASSERT_EQUAL(length(chunks), 1, "Повтор запроса не сбрасывает принятые чанки.")
	window.on_message("payloadChunk", list("id" = "twice", "chunk" = "\"повтор\"}", "index" = 2))
	TEST_ASSERT_EQUAL(subscriber.received_payload?["name"], "повтор", "Передача с повтором запроса собирается.")

	TEST_ASSERT(window.create_oversized_payload("fat", "test/assembled", 2), "Пятая передача создаётся.")
	TEST_ASSERT(!window.append_payload_chunk("fat", "\[[jointext(new /list(TGUI_PAYLOAD_CHUNK_MAX_BYTES + 1), "1")]", 1), "Чанк длиннее потолка отвергается.")
	TEST_ASSERT_NULL(window.oversized_payloads["fat"], "Передача с толстым чанком бросается.")

	TEST_ASSERT(window.create_oversized_payload("orphan", "test/assembled", 2), "Шестая передача создаётся.")
	window.on_message("ready", list())
	TEST_ASSERT_EQUAL(length(window.oversized_payloads), 0, "Перезагруженная страница освобождает слоты прежней.")

/datum/tgui_window/payload_test
	var/list/sent = list()

/datum/tgui_window/payload_test/New()
	id = "payload-test"

/datum/tgui_window/payload_test/send_message(type, payload, force)
	sent += list(list(type, payload))

/datum/payload_test_subscriber
	var/received_type
	var/list/received_payload
	var/received_raw

/datum/payload_test_subscriber/proc/on_message(type, payload, href_list)
	if(type != "test/assembled")
		return FALSE
	received_type = type
	received_payload = payload
	received_raw = href_list?["payload"]
	return TRUE
