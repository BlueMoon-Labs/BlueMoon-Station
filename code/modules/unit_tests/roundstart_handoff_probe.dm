/**
 * Прибор раздачи тел (ticker_handoff_probe.dm) считает цену стадии старта раунда на
 * игрока. Без живого раунда со ста игроками единственный проверяемый кусок - арифметика
 * строки стадии и монотонность счётчика фоновой работы, куда прибор пишет свою цену.
 *
 * Раунд 10121: сумма "хвостов" по 116 входам дала 1919 МБ при росте раунда 1395 МБ,
 * потому что стартовый шторм попал в окна тех, кто в эти секунды подключался. Именно
 * поэтому прибор ОБЯЗАН записывать свою цену на общий счёт фона, а не только логировать.
 */

/// Стадия с игроками печатает число игроков, цену на игрока и дельту объектов.
/datum/unit_test/handoff_stage_reports_per_player/Run()
	var/line = handoff_stage_line("equip 4.2с +120 МБ", 80, 120, 38600)

	TEST_ASSERT_EQUAL(line, "equip 4.2с +120 МБ (80 игроков, 1.5 МБ на игрока, +38600 объектов)", "Стадия с игроками обязана назвать число игроков, цену на игрока и дельту объектов")

/// Стадия без игроков (манифест) молчит про цену на игрока: приписанный ей знаменатель
/// был бы выдуманным.
/datum/unit_test/handoff_stage_without_players/Run()
	var/line = handoff_stage_line("manifest 1.1с +8 МБ", null, 8, 412)

	TEST_ASSERT_EQUAL(line, "manifest 1.1с +8 МБ (+412 объектов)", "Стадия без перебора игроков не должна дописывать цену на игрока, но дельта объектов остаётся")

/// Пустой раунд: делить не на что. Ноль игроков обязан сказать это словами, а не выдать
/// "0 МБ на игрока" - такая строка читалась бы как измеренная бесплатность.
/datum/unit_test/handoff_zero_players_says_so/Run()
	var/line = handoff_stage_line("create 0.1с 0 МБ", 0, 0, 0)

	TEST_ASSERT(findtext(line, "игроков нет"), "При нуле игроков строка обязана сказать это словами: [line]")
	TEST_ASSERT(!findtext(line, "на игрока"), "При нуле игроков цены на игрока быть не должно: [line]")

/// На Windows памяти нет: остаются секунды и число игроков, но не выдуманные мегабайты.
/datum/unit_test/handoff_stage_without_memory/Run()
	var/line = handoff_stage_line("transfer 6.3с", 91, 0, 91, measured = FALSE)

	TEST_ASSERT_EQUAL(line, "transfer 6.3с (91 игроков, +91 объектов)", "Без замера памяти остаются секунды, игроки и дельта объектов - на Windows это единственная измеримая половина")

/// Стартовая чистка лобби удаляет больше, чем создаёт: отрицательная дельта - это факт
/// раунда 10121 (-941 объект на окне в 666 МБ), и она обязана печататься со знаком, а не
/// теряться. Именно она говорит, что стадия заплатила НЕ датумами.
/datum/unit_test/handoff_stage_keeps_negative_instance_delta/Run()
	var/line = handoff_stage_line("transfer 8.4с +666 МБ", 105, 666, -941)

	TEST_ASSERT(findtext(line, "-941 объектов"), "Отрицательная дельта объектов обязана остаться в строке со знаком: [line]")

/// Счётчик фоновой работы - общий с прибором подключения и с постройкой света. Запись в
/// него теперь идёт через один прок, и он обязан оставаться монотонным: отрицательная
/// дельта означает "за окно ничего не сделано", а не "верните мегабайты".
/datum/unit_test/attributed_memory_counter_is_monotonic/Run()
	var/restore = GLOB.memory_attributed_elsewhere_mb
	GLOB.memory_attributed_elsewhere_mb = 100

	attribute_memory_elsewhere_mb(-40)
	var/after_negative = GLOB.memory_attributed_elsewhere_mb
	attribute_memory_elsewhere_mb(0)
	var/after_zero = GLOB.memory_attributed_elsewhere_mb
	attribute_memory_elsewhere_mb(25)
	var/after_positive = GLOB.memory_attributed_elsewhere_mb

	GLOB.memory_attributed_elsewhere_mb = restore

	TEST_ASSERT_EQUAL(after_negative, 100, "Отрицательная цена не должна уменьшать счётчик фоновой работы")
	TEST_ASSERT_EQUAL(after_zero, 100, "Нулевая цена не должна двигать счётчик фоновой работы")
	TEST_ASSERT_EQUAL(after_positive, 125, "Положительная цена обязана попасть в счётчик фоновой работы")
