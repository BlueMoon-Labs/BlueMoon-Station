/**
 * Детектор скачков VmSize в SStick_spikes.
 *
 * Раунд 10121: 81% роста за раунд пришли СЕМНАДЦАТЬЮ ступенями по 8-53 МБ, а 184 сэмпла
 * перф-CSV из 290 не росли вообще. Искать "то, что течёт каждый тик" было нечего - надо
 * было ловить ступени и называть виновника. Детектор отвечает на два вопроса: когда
 * скакнуло и заплатили ли за это датумами; арифметика второго и проверяется здесь.
 */

/// Инстансов не прибавилось (или стало меньше, как на старте раунда 10121) - значит
/// заплатили не датумами, и делить не на что.
/datum/unit_test/memory_jump_verdict_without_instances/Run()
	var/negative = memory_jump_verdict(666, -941)
	var/zero = memory_jump_verdict(43.7, 0)

	TEST_ASSERT(findtext(negative, "НЕ датумами"), "Отрицательная дельта объектов обязана называться прямо: [negative]")
	TEST_ASSERT(findtext(zero, "НЕ датумами"), "Нулевая дельта объектов обязана называться прямо: [zero]")
	TEST_ASSERT(!findtext(zero, "Б на объект"), "Делить на ноль объектов прибор не должен: [zero]")

/// Честная загрузка карты: мегабайты приходят вместе с объектами, и цена одного объекта
/// остаётся в сотнях байт.
/datum/unit_test/memory_jump_verdict_blames_instances/Run()
	// 22 500 объектов света z-уровня на 10 МБ - это 466 Б на объект.
	var/verdict = memory_jump_verdict(10, 22500)

	TEST_ASSERT(findtext(verdict, "честную аллокацию"), "Сотни байт на объект - это объекты, а не что-то ещё: [verdict]")
	TEST_ASSERT(findtext(verdict, "466 Б на объект"), "Цена объекта обязана быть в строке числом: [verdict]")

/// Объекты прибавились, но объяснить ими мегабайты нельзя: аппирансы, иконки, RSC или
/// поклиентская машинерия карты. Именно этот случай перф-CSV раунда 10121 не различал.
/datum/unit_test/memory_jump_verdict_rejects_thin_instances/Run()
	// 531 МБ на 79 768 объектов - 6.8 КБ на штуку, втрое выше потолка.
	var/verdict = memory_jump_verdict(531, 79768)

	TEST_ASSERT(findtext(verdict, "не объясняется"), "6.8 КБ на объект обязаны быть отвергнуты как объяснение: [verdict]")

/// Заголовок блока обязан нести и число, и вердикт: строку читают глазами в логе раунда,
/// и без вердикта она снова превращается в "сколько" без "кто".
/datum/unit_test/memory_jump_headline_carries_verdict/Run()
	// Синглтон, а не new: SUBSYSTEM_DEF заводит подсистему сам, а лишний инстанс полез бы
	// в очередь МК. memory_jump_headline() - чистый форматтер и состояния не трогает.
	var/datum/controller/subsystem/tick_spikes/recorder = SStick_spikes
	TEST_ASSERT_NOTNULL(recorder, "SStick_spikes не существует")
	var/headline = recorder.memory_jump_headline(43.7, 3352, 4005, 5)

	TEST_ASSERT(findtext(headline, "+43.7 МБ"), "Скачок обязан быть в заголовке со знаком: [headline]")
	TEST_ASSERT(findtext(headline, "3352 МБ"), "Итоговый VmSize обязан быть в заголовке: [headline]")
	TEST_ASSERT(findtext(headline, "+4005"), "Дельта объектов обязана быть в заголовке со знаком: [headline]")
	TEST_ASSERT(findtext(headline, "не объясняется"), "Вердикт обязан быть в заголовке: [headline]")
