/// Сигнал рации и сообщения КПК с одного этажа связки доходят до телекомов на другом, а кэш связки остаётся нетронутым.
/datum/unit_test/multiz_radio_levels_cover_stack

/datum/unit_test/multiz_radio_levels_cover_stack/Run()
	if(!SSmapping.max_plane_offset)
		return // Односложный мир: связок нет.

	var/turf/lower = multiz_test_lower_turf()
	TEST_ASSERT_NOTNULL(lower, "В мире со стопкой не нашлось этажа со смещением")
	var/turf/upper = GET_TURF_ABOVE(lower)
	TEST_ASSERT_NOTNULL(upper, "Над нижним этажом стопки нет этажа")
	var/list/stack = SSmapping.get_connected_levels(lower)
	var/list/stack_before = stack.Copy()

	var/obj/item/radio/speaker_radio = allocate(/obj/item/radio, upper)
	var/datum/signal/subspace/vocal/signal = new(speaker_radio, FREQ_COMMON, null, /datum/language/common, "проба", list())
	TEST_ASSERT(lower.z in signal.levels, "Сигнал рации с верхнего этажа не доходит до телекомов нижнего")
	TEST_ASSERT(signal.levels != stack, "Сигнал рации взял кэш связки вместо копии")

	signal.levels += 0
	TEST_ASSERT_EQUAL(json_encode(SSmapping.get_connected_levels(lower)), json_encode(stack_before), "Правка уровней сигнала испортила кэш связки")

	var/datum/signal/subspace/messaging/message = new(speaker_radio, list())
	TEST_ASSERT(lower.z in message.levels, "Сообщение КПК с верхнего этажа не доходит до сервера нижнего")
