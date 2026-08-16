/// Коррекция сплиттера не имеет права схлопнуть окно карты.
///
/// Цикл подгонки вьюпорта читает ширину карты сразу после winset'а, и скин
/// регулярно отвечает ещё СТАРЫМ размером - в первую очередь на логине, пока окно
/// разворачивается. Поправка тогда считается по чужой ширине и выходит гигантской:
/// на реальных числах прод-скина (карта отвечает 1024 из skin.dmf при цели 337
/// внутри сплита 637) она равна -107 процентным пунктам. Без потолка сплиттер
/// уезжал в минус, карта схлопывалась в полоску, а чат занимал весь экран.
/datum/unit_test/fit_viewport_splitter

/datum/unit_test/fit_viewport_splitter/Run()
	// Те самые числа: окно ещё не развёрнуто (сплит 637), цель зажата резервом
	// в 300 пикселей под чат, а скин отвечает размером карты из скина.
	var/estimate_pct = 100 * (337 + 4) / 637
	var/stale_delta = 100 * (337 - 1024) / 637

	TEST_ASSERT(stale_delta < -100, "тестовые числа перестали давать слепую поправку: delta = [stale_delta]")

	var/corrected = fit_viewport_corrected_splitter(estimate_pct, estimate_pct, stale_delta)
	TEST_ASSERT(corrected > 0, "слепая поправка увела сплиттер в [corrected]: карта схлопнута, чат занял весь экран")
	TEST_ASSERT(corrected > estimate_pct * 0.5, "слепая поправка увела сплиттер с [estimate_pct] на [corrected] - больше чем вдвое")

	// Обратное направление: устаревший ответ может быть и меньше цели.
	var/stale_delta_up = -stale_delta
	var/corrected_up = fit_viewport_corrected_splitter(estimate_pct, estimate_pct, stale_delta_up)
	TEST_ASSERT(corrected_up < 100, "слепая поправка увела сплиттер в [corrected_up]: чат схлопнут")
	TEST_ASSERT(corrected_up < estimate_pct * 2, "слепая поправка увела сплиттер с [estimate_pct] на [corrected_up] - больше чем вдвое")

	// Честная поправка - это доли процента, и она обязана проходить как есть,
	// иначе цикл перестанет доводить ширину до пиксельной точности.
	var/honest = fit_viewport_corrected_splitter(estimate_pct, estimate_pct, 0.4)
	TEST_ASSERT_EQUAL(honest, estimate_pct + 0.4, "честная поправка не прошла через потолок")
