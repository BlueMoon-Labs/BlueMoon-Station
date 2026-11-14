/// Датум с базой 40 мс и одним замером пачки batch_id с заданными лишним и простоем.
/datum/unit_test/ping_diag_batch/proc/replied(datum/ping_batch/batch, excess, stall = 0)
	var/datum/ping_diagnostics/diag = new("tester")
	diag.record_sample(1, 40, 0, 0, 0)
	var/slot = diag.record_sample(2, 40 + excess + stall, stall, batch.id, 0)
	batch.expect(diag)
	batch.add_reply(diag, slot)
	return list(diag, slot)

/datum/unit_test/ping_diag_batch/Run()
	var/datum/ping_batch/batch = new(7, 0)
	var/list/replies = list()
	for(var/excess in list(0, 10, 20, 30, 40, 200))
		replies += list(replied(batch, excess))
	TEST_ASSERT_EQUAL(batch.close(), 20, "общая доля - медиана")
	var/list/worst = replies[6]
	var/datum/ping_diagnostics/worst_diag = worst[1]
	TEST_ASSERT_EQUAL(worst_diag.sample_personal[worst[2]], 180, "личное у выбивающегося")
	var/list/calm = replies[2]
	var/datum/ping_diagnostics/calm_diag = calm[1]
	TEST_ASSERT_EQUAL(calm_diag.sample_personal[calm[2]], 0, "у спокойного личного нет")
	TEST_ASSERT_EQUAL(batch.ours_ms, 0 + 10 + 20 + 20 + 20 + 20, "наша доля по пачке")
	TEST_ASSERT_EQUAL(batch.yours_ms, 0 + 0 + 0 + 10 + 20 + 180, "доля игроков по пачке")
	TEST_ASSERT_NULL(batch.detect_event(10), "всплеск задел одного - не общее событие")

	var/datum/ping_batch/small = new(8, 0)
	for(var/excess in list(50, 60, 70, 80))
		replied(small, excess)
	TEST_ASSERT_NULL(small.close(), "мало ответивших - общая доля неизвестна")

/// Повтор ответа и ответ без рассылки не попадают в пачку: один игрок не двигает общую долю.
/datum/unit_test/ping_diag_batch_replies_once/Run()
	var/datum/ping_batch/batch = new(10, 0)
	for(var/i in 1 to 5)
		var/datum/ping_diagnostics/diag = new("tester")
		diag.record_sample(1, 40, 0, 0, 0)
		batch.expect(diag)
		TEST_ASSERT(batch.add_reply(diag, diag.record_sample(2, 50, 0, 10, 0)), "ответ на рассылку принят")
	var/datum/ping_diagnostics/spammer = new("spammer")
	spammer.record_sample(1, 40, 0, 0, 0)
	batch.expect(spammer)
	TEST_ASSERT(batch.add_reply(spammer, spammer.record_sample(2, 50, 0, 10, 0)), "первый ответ принят")
	for(var/i in 1 to 8)
		TEST_ASSERT(!batch.add_reply(spammer, spammer.record_sample(3 + i, 500, 0, 10, 0)), "повтор отброшен")
	var/datum/ping_diagnostics/stranger = new("stranger")
	stranger.record_sample(1, 40, 0, 0, 0)
	TEST_ASSERT(!batch.add_reply(stranger, stranger.record_sample(2, 500, 0, 10, 0)), "без рассылки отброшен")
	TEST_ASSERT_EQUAL(length(batch.excesses), 6, "в пачке по ответу на датум")
	TEST_ASSERT_EQUAL(batch.close(), 10, "общая доля не сдвинута")

/datum/unit_test/ping_diag_batch_events/proc/batch_with(excess, stall)
	RETURN_TYPE(/datum/ping_batch)
	var/datum/ping_batch/batch = new(9, 0)
	for(var/i in 1 to 6)
		var/datum/ping_diagnostics/diag = new("tester")
		diag.record_sample(1, 40, 0, 0, 0)
		batch.expect(diag)
		batch.add_reply(diag, diag.record_sample(2, 40 + excess + stall, stall, 9, 0))
	batch.close()
	return batch

/datum/unit_test/ping_diag_batch_events/Run()
	var/datum/ping_batch/stalled = batch_with(0, 150)
	var/list/event = stalled.detect_event(10)
	TEST_ASSERT_NOTNULL(event, "простой у всех - событие")
	TEST_ASSERT_EQUAL(event["type"], PING_EVENT_SERVER_STALL, "тип - сервер")
	TEST_ASSERT_EQUAL(event["stall_ms"], 150, "простой в событии")
	var/list/load = batch_with(90, 0).detect_event(95)
	TEST_ASSERT_EQUAL(load["type"], PING_EVENT_SERVER_LOAD, "забитый тик")
	var/list/uplink = batch_with(90, 0).detect_event(30)
	TEST_ASSERT_EQUAL(uplink["type"], PING_EVENT_HOST_NETWORK, "канал хоста")
	TEST_ASSERT_NULL(batch_with(20, 0).detect_event(30), "мелкая прибавка - не событие")

/// Ответ в открытой пачке не старше самой пачки, итоги конечны при любых числах от клиента.
/datum/unit_test/ping_diag_batch_clamp/Run()
	var/datum/ping_batch/batch = new(11, 100)
	var/datum/ping_diagnostics/diag = new("tester")
	diag.record_sample(1, 40, 0, 0, 0)
	batch.expect(diag)
	batch.add_reply(diag, diag.record_sample(101, 5040, 300, 11, 0), 101)
	var/extra = batch.excesses[1] + batch.stalls[1]
	TEST_ASSERT(extra >= 0 && round(extra, 1) <= 100, "лишнее с простоем обрезано возрастом пачки: [extra]")

	var/datum/ping_batch/forged = new(12, 100)
	for(var/i in 1 to 6)
		var/datum/ping_diagnostics/liar = new("liar")
		liar.record_sample(1, 40, 0, 0, 0)
		forged.expect(liar)
		forged.add_reply(liar, liar.record_sample(130, 1e30, 1e30, 12, 0), 130)
	forged.close(130)
	var/total = forged.ours_ms + forged.yours_ms
	TEST_ASSERT(total == total && round(total, 1) <= 6 * 3000, "итог пачки конечен и не больше её возраста: [total]")

/// Пачка из шести ожидавших: replying ответили вовремя, остальные молчат до закрытия.
/datum/unit_test/ping_diag_mass_freeze/proc/silent_batch(replying)
	var/datum/ping_batch/batch = new(13, 100)
	var/list/diags = list()
	for(var/i in 1 to 6)
		var/datum/ping_diagnostics/diag = new("tester")
		diag.record_sample(1, 40, 0, 0, 0)
		diag.note_sent(100, 13)
		batch.expect(diag)
		diags += diag
	for(var/i in 1 to replying)
		var/datum/ping_diagnostics/diag = diags[i]
		batch.add_reply(diag, diag.record_sample(105, 50, 0, 13, 0), 105)
	for(var/datum/ping_diagnostics/diag as anything in diags)
		diag.note_sent(136, 14)
	batch.close(140)
	for(var/datum/ping_diagnostics/diag as anything in diags)
		diag.note_sent(160, 15)
	return list(batch, diags)

/datum/unit_test/ping_diag_mass_freeze/Run()
	var/list/all_silent = silent_batch(0)
	var/datum/ping_batch/batch = all_silent[1]
	var/list/event = batch.detect_event(10)
	TEST_ASSERT_NOTNULL(event, "молчат все - общее событие")
	TEST_ASSERT_EQUAL(event["type"], PING_EVENT_MASS_FREEZE, "тип - подвисание у всех")
	TEST_ASSERT_EQUAL(event["clients"], 6, "в событии все ожидавшие")
	for(var/datum/ping_diagnostics/diag as anything in all_silent[2])
		TEST_ASSERT_EQUAL(length(diag.freeze_times), 0, "общее молчание не вешается на игрока")

	var/list/one_silent = silent_batch(5)
	batch = one_silent[1]
	TEST_ASSERT_NULL(batch.detect_event(10), "молчит один - не общее событие")
	var/list/diags = one_silent[2]
	for(var/i in 1 to 5)
		var/datum/ping_diagnostics/diag = diags[i]
		TEST_ASSERT_EQUAL(length(diag.freeze_times), 0, "ответившие без подвисаний")
	var/datum/ping_diagnostics/silent = diags[6]
	TEST_ASSERT_EQUAL(length(silent.freeze_times), 1, "подвисание у того, кто молчал")
