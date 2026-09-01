/// Замедление за вес тела, размеченное по тикам.
///
/// Цена шага выравнивается по тику, поэтому замедление, не дотягивающее до
/// четверти тика, пропадает целиком, а всё что больше превращается в целый
/// тик. Раньше лестница задавалась в долях децисекунды (0.2 и 0.7 от
/// конфиг-множителя) и после выравнивания превращалась в случайную ступеньку.
/// Теперь она задаётся сразу в тиках и ступеньки предсказуемы.
///
/// Точки обнуления штрафа сохранены: тяжёлому персонажу вес перестаёт мешать
/// при росте 120%, сверхтяжёлому при 170% - как и было задумано.

/datum/unit_test/movement_weight_slowdown

/datum/unit_test/movement_weight_slowdown/Run()
	var/tick_lag = 0.5

	// --- Округление замедления ---

	// В отличие от цены шага, ноль здесь законный результат: отсутствие
	// замедления надо уметь выразить.
	TEST_ASSERT_EQUAL(movement_quantize_slowdown(0, tick_lag), 0, "Нулевое замедление обязано остаться нулём, а не стать тиком")
	TEST_ASSERT_EQUAL(movement_quantize_slowdown(0.2, tick_lag), 0, "Замедление меньше половины ступени не выражается и обязано занулиться")
	TEST_ASSERT_EQUAL(movement_quantize_slowdown(0.3, tick_lag), 0.5, "Замедление больше половины ступени обязано стать целым тиком")
	TEST_ASSERT_EQUAL(movement_quantize_slowdown(1, tick_lag), 1, "Кратное значение не должно двигаться")
	// Ровно половина ступени уходит вниз, и уходит одинаково при любом хвосте:
	// иначе одно и то же замедление давало бы разный штраф от замера к замеру.
	TEST_ASSERT_EQUAL(movement_quantize_slowdown(0.25, tick_lag), 0, "Ровно половина ступени обязана уходить вниз")
	TEST_ASSERT_EQUAL(movement_quantize_slowdown(0.25 + 0.0000001, tick_lag), 0, "Хвост не имеет права перекинуть половину ступени вверх")

	// --- Лестница веса ---

	var/heavy_ticks = MOB_WEIGHT_HEAVY_SLOWDOWN_TICKS
	var/super_ticks = MOB_WEIGHT_HEAVY_SUPER_SLOWDOWN_TICKS
	var/heavy_cancel = MOB_WEIGHT_HEAVY_CANCEL_SIZE - 1
	var/super_cancel = MOB_WEIGHT_HEAVY_SUPER_CANCEL_SIZE - 1

	// Выключенная механика обязана оставаться выключенной при любом размере.
	TEST_ASSERT_EQUAL(movement_weight_slowdown(super_ticks, super_cancel, 1, 0, tick_lag), 0, "При нулевом конфиг-множителе замедления быть не может")

	// Персонаж обычного роста получает полный штраф.
	TEST_ASSERT_EQUAL(movement_weight_slowdown(super_ticks, super_cancel, 1, 1, tick_lag), super_ticks * tick_lag, "Сверхтяжёлый обычного роста обязан получить полный штраф в [super_ticks] тика")
	TEST_ASSERT_EQUAL(movement_weight_slowdown(heavy_ticks, heavy_cancel, 1, 1, tick_lag), heavy_ticks * tick_lag, "Тяжёлый обычного роста обязан получить полный штраф в [heavy_ticks] тик")

	// На точке обнуления штрафа нет: рост оправдывает массу.
	TEST_ASSERT_EQUAL(movement_weight_slowdown(super_ticks, super_cancel, MOB_WEIGHT_HEAVY_SUPER_CANCEL_SIZE, 1, tick_lag), 0, "На росте [MOB_WEIGHT_HEAVY_SUPER_CANCEL_SIZE * 100]% сверхтяжёлому вес мешать не должен")
	TEST_ASSERT_EQUAL(movement_weight_slowdown(heavy_ticks, heavy_cancel, MOB_WEIGHT_HEAVY_CANCEL_SIZE, 1, tick_lag), 0, "На росте [MOB_WEIGHT_HEAVY_CANCEL_SIZE * 100]% тяжёлому вес мешать не должен")

	// За точкой обнуления штраф не уходит в минус, иначе вес давал бы разгон.
	TEST_ASSERT_EQUAL(movement_weight_slowdown(super_ticks, super_cancel, 3, 1, tick_lag), 0, "За точкой обнуления штраф обязан остаться нулём, а не стать отрицательным")

	// Отклонение размера в меньшую сторону работает так же - это поведение
	// исходной механики, она берёт модуль отклонения.
	TEST_ASSERT_EQUAL(movement_weight_slowdown(super_ticks, super_cancel, 1 - super_cancel, 1, tick_lag), 0, "Отклонение размера вниз обязано снимать штраф так же, как вверх")

	// Между точками штраф убывает, и каждая ступень кратна тику.
	var/previous = movement_weight_slowdown(super_ticks, super_cancel, 1, 1, tick_lag)
	for(var/step in 1 to 7)
		var/size = 1 + (super_cancel * step / 7)
		var/slowdown = movement_weight_slowdown(super_ticks, super_cancel, size, 1, tick_lag)
		TEST_ASSERT(slowdown <= previous, "Штраф обязан убывать с ростом, а на размере [size] вырос с [previous] до [slowdown]")
		var/ticks = slowdown / tick_lag
		TEST_ASSERT(abs(ticks - round(ticks + 0.5)) < 0.001, "Штраф на размере [size] вышел [slowdown]ds - это [ticks] тика, а обязано быть целое")
		previous = slowdown
