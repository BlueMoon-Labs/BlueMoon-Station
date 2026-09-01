/// Помощники замера шагов живого игрока.
///
/// Зонд слушает COMSIG_MOB_CLIENT_MOVE и складывает по каждому шагу время, на
/// котором тот случился, и выставленный glide_size. Из этого считается главная
/// метрика - сколько тиков атом простоял на месте, доехав раньше срока.

/datum/unit_test/movement_probe_math

/datum/unit_test/movement_probe_math/Run()
	var/tick_lag = 0.5
	var/icon_size = 32

	// --- Интервал между шагами в целых тиках ---

	TEST_ASSERT_EQUAL(movement_probe_tick_delta(1002.5, 1000, tick_lag), 5, "2.5ds между шагами - это пять тиков")
	TEST_ASSERT_EQUAL(movement_probe_tick_delta(1004, 1000, tick_lag), 8, "4ds между шагами - это восемь тиков")

	// world.time приходит с плавающим хвостом, а интервал обязан быть целым.
	TEST_ASSERT_EQUAL(movement_probe_tick_delta(1002.4999, 1000, tick_lag), 5, "Хвост вниз не имеет права терять тик")
	TEST_ASSERT_EQUAL(movement_probe_tick_delta(1002.5001, 1000, tick_lag), 5, "Хвост вверх не имеет права добавлять тик")

	// Первый шаг в серии сравнивать не с чем.
	TEST_ASSERT_EQUAL(movement_probe_tick_delta(1000, null, tick_lag), 0, "Без предыдущего шага интервала нет")

	// --- Обратный пересчёт glide ---
	//
	// Простой считается через него, поэтому обращение обязано быть точным: glide,
	// рассчитанный на N тиков, обязан пересекать тайл ровно за N тиков.

	for(var/interval in list(1, 3, 4, 6))
		TEST_ASSERT(abs(movement_probe_ticks_to_cross(icon_size / interval, icon_size) - interval) < 0.001, "glide на [interval] тика обязан пересекать тайл ровно за [interval] тика")

	TEST_ASSERT_EQUAL(movement_probe_ticks_to_cross(0, icon_size), INFINITY, "Нулевой glide не пересекает тайл никогда и не имеет права делить на ноль")

	// --- Простой: сколько атом стоял, доехав раньше следующего шага ---

	// Ровный случай: glide рассчитан на те же пять тиков, что и ожидание.
	// Сравнение с допуском, а не на равенство: 32 / (32 / 5) в 32-битном
	// float не возвращает ровно 5.
	TEST_ASSERT(abs(movement_probe_idle_ticks(icon_size / 5, icon_size, 5)) < 0.001, "Совпадающий glide простоя не оставляет")

	// Отрицательный простой - это недоезд, атом ещё в движении когда его
	// двигают снова. Знак обязан сохраняться, иначе диагноз не отличить.
	TEST_ASSERT(movement_probe_idle_ticks(icon_size / 10, icon_size, 5) < 0, "Недоезд обязан быть отрицательным, а не обнулённым")

	// --- Недоезд в пикселях ---
	//
	// По знаку простоя недоезд считать нельзя: множитель glide, застрявший чуть
	// ниже единицы, делает простой отрицательным почти на каждом шаге, и
	// счётчик показывает 90% при недоезде в четверть пикселя. Глазом видна
	// величина, а не знак - её и меряем, сразу в том, в чём она видна.

	TEST_ASSERT_EQUAL(movement_probe_undershoot_pixels(icon_size / 5, icon_size, 5), 0, "Совпадающий glide недоезда не оставляет")
	TEST_ASSERT_EQUAL(movement_probe_undershoot_pixels(icon_size / 5, icon_size, 6), 0, "Приехавший раньше срока спрайт не имеет отрицательного недоезда")
	TEST_ASSERT_EQUAL(movement_probe_undershoot_pixels(10, icon_size, 3), 2, "glide 10 за три тика покрывает 30 из 32 пикселей")

	// Множитель на процент ниже единицы даёт недоезд втрое меньше пикселя -
	// то есть ровно то, чего никто не увидит. Именно это и показывал прежний
	// счётчик как "363 шага с недоездом".
	var/nearly_right = (icon_size / 3) * 0.99
	TEST_ASSERT(movement_probe_undershoot_pixels(nearly_right, icon_size, 3) < MOVEMENT_PROBE_UNDERSHOOT_PIXELS, "Недоезд от множителя 0.99 обязан быть меньше пикселя, а вышел [movement_probe_undershoot_pixels(nearly_right, icon_size, 3)]")

	// --- Скачок недоезда: то, что действительно видно ---
	//
	// Уровень недоезда глазу недоступен. При LONG_GLIDE спрайт не прыгает на
	// новый тайл, а едет из той точки, где стоит, поэтому постоянный недоезд -
	// это постоянный сдвиг картинки, сравнивать его не с чем. Видно переход:
	// один шаг доехал, следующий отстал на треть тайла.

	TEST_ASSERT_EQUAL(movement_probe_undershoot_jump(5, 5), 0, "Одинаковый недоезд на соседних шагах скачка не даёт")
	TEST_ASSERT_EQUAL(movement_probe_undershoot_jump(12, 4), 8, "Скачок - это разница недоездов")
	TEST_ASSERT_EQUAL(movement_probe_undershoot_jump(4, 12), 8, "Скачок в обратную сторону виден так же")

	// Просевший сервер даёт недоезд на КАЖДОМ шаге, но одинаковый - и скачка не
	// даёт. Ровно ради этого случая метрика и переделана: уровень кричал "302
	// шага из 397", скачок молчит.
	//
	// Пять процентов, а не три: недоезд равен icon_size * (1 - множитель), то
	// есть три процента дают 0.96 px и до порога видимости не дотягивают вовсе.
	// Порог в пиксель на тайле в 32 px переступает просадка от 3.2%.
	var/dilated_glide = (icon_size / 3) * 0.95
	var/steady_undershoot = movement_probe_undershoot_pixels(dilated_glide, icon_size, 3)
	TEST_ASSERT(steady_undershoot >= MOVEMENT_PROBE_UNDERSHOOT_PIXELS, "Просадка на 5% обязана давать недоезд больше пикселя, иначе пример не про то")
	TEST_ASSERT(movement_probe_undershoot_jump(steady_undershoot, steady_undershoot) < MOVEMENT_PROBE_UNDERSHOOT_JUMP_PIXELS, "Ровная просадка сервера не имеет права выглядеть рывком")

	// --- Гистограмма интервалов ---

	// Ключи текстовые: в DM обращение по числовому ключу читается как индекс
	// списка, а не как ключ, и гистограмма с числовыми ключами падает.
	var/list/histogram = movement_probe_histogram(list(5, 6, 5, 6, 5))
	TEST_ASSERT_EQUAL(histogram["5"], 3, "Пятёрок в выборке три")
	TEST_ASSERT_EQUAL(histogram["6"], 2, "Шестёрок в выборке две")
	TEST_ASSERT_EQUAL(length(histogram), 2, "Других значений в выборке нет")

	TEST_ASSERT_EQUAL(length(movement_probe_histogram(list())), 0, "Пустая выборка даёт пустую гистограмму")

	// Одна и та же строка печатает и интервалы, и причины, поэтому единица
	// измерения приходит снаружи. Зашитая давала в отчёте "норма тик(ов) x101".
	TEST_ASSERT_EQUAL(movement_probe_histogram_line(movement_probe_histogram(list(4, 4, 6)), "тик(ов)"), "4 тик(ов) x2, 6 тик(ов) x1", "Интервалы печатаются с единицей измерения")
	TEST_ASSERT_EQUAL(movement_probe_histogram_line(movement_probe_histogram(list("норма", "упёрся", "норма")), null), "норма x2, упёрся x1", "У причин единицы измерения нет")
	TEST_ASSERT_EQUAL(movement_probe_histogram_line(movement_probe_histogram(list()), "тик(ов)"), "", "Пустая гистограмма даёт пустую строку, а не мусор")

	// --- Классификация интервалов ---
	//
	// Порядок разбора важен: несостоявшийся шаг может совпасть со сменой
	// скорости, и списать его на скорость значило бы потерять настоящую причину.

	TEST_ASSERT_EQUAL(movement_probe_classify(3, 3.2, FALSE, FALSE), MOVEMENT_PROBE_BLOCKED, "Шаг без смены места - это упор в препятствие, что бы ещё ни совпало")
	TEST_ASSERT_EQUAL(movement_probe_classify(3, 3.2, TRUE, FALSE), MOVEMENT_PROBE_BLOCKED, "Упор в препятствие важнее смены скорости")
	TEST_ASSERT_EQUAL(movement_probe_classify(4, 3.2, TRUE, TRUE), MOVEMENT_PROBE_SPEED_CHANGE, "Изменившаяся задержка объясняет интервал сама")
	TEST_ASSERT_EQUAL(movement_probe_classify(14, 3.2, FALSE, TRUE), MOVEMENT_PROBE_STALL, "Интервал сильно длиннее номинала без смены скорости - пауза ввода")
	TEST_ASSERT_EQUAL(movement_probe_classify(4, 3.2, FALSE, TRUE), MOVEMENT_PROBE_NORMAL, "Гуляние на один тик вокруг номинала - норма, а не выброс")
	TEST_ASSERT_EQUAL(movement_probe_classify(3, 3.2, FALSE, TRUE), MOVEMENT_PROBE_NORMAL, "Интервал короче номинала в пределах тика - тоже норма")

	// --- Что показывать в списке выбросов ---
	//
	// Смена скорости сама по себе времени не стоит - стоит только сдвиг
	// расписания, который из неё вышел. Засорять список выбросов ею нельзя,
	// иначе он состоит из строк "4 тика против номинала 4, простой 0 мс".

	TEST_ASSERT(!movement_probe_is_outlier(0, 4, 4), "Шаг, попавший в свой номинал без скачка - не выброс")
	TEST_ASSERT(!movement_probe_is_outlier(1, 3, 3), "Скачок в пиксель - не выброс")
	// Ровный недоезд от просевшего сервера скачка не даёт, и в список попасть не
	// имеет права: на этом список один раз уже распух до половины забега.
	TEST_ASSERT(!movement_probe_is_outlier(0, 11, 11), "Уровень недоезда сам по себе выбросом не делает, каким бы он ни был")
	// Упор в стену - обычная игра, и пока он укладывается в свой номинал, он
	// ничего не стоит. Безусловный показ давал восемь одинаковых строк
	// "простой 0 мс, скачок 0 px" на чистом забеге; сколько было упоров, видно
	// из гистограммы причин.
	TEST_ASSERT(!movement_probe_is_outlier(0, 3, 3), "Упор, уложившийся в свой номинал, ничего не стоил и в список не идёт")

	TEST_ASSERT(movement_probe_is_outlier(0, 12, 3), "Дорогой упор - тот, что съел лишние тики, - остаётся виден")
	TEST_ASSERT(movement_probe_is_outlier(0, 9, 3), "Интервал втрое длиннее номинала - выброс")
	TEST_ASSERT(movement_probe_is_outlier(MOVEMENT_PROBE_UNDERSHOOT_JUMP_PIXELS, 4, 4), "Скачок недоезда в четверть тайла - выброс, даже если интервал ожидаемый")

	// --- Кто виноват в паузе ---
	//
	// Длинный интервал сам по себе ничего не объясняет. Сервер мог проседать,
	// и тогда world.time отстаёт от настоящего времени; а мог идти вровень, и
	// тогда шаг не состоялся по какой-то другой причине. Это разные диагнозы,
	// и различить их можно только сравнив серверное время с настоящим.

	// Сервер шёл вровень: за 10ds серверного времени прошло 10ds настоящего.
	TEST_ASSERT_EQUAL(movement_probe_dilation(10, 10), 1, "Ровно идущий сервер обязан давать единицу")
	// Сервер вдвое отстал: серверных 10ds заняли 20ds настоящих.
	TEST_ASSERT_EQUAL(movement_probe_dilation(10, 20), 0.5, "Вдвое просевший сервер обязан давать половину")
	// Настоящее время не двигалось - судить не о чем, но делить на ноль нельзя.
	TEST_ASSERT_EQUAL(movement_probe_dilation(10, 0), 1, "Без настоящего времени судить не о чем, но деления на ноль быть не должно")

	TEST_ASSERT_EQUAL(movement_probe_stall_source(0.5, TRUE), MOVEMENT_PROBE_STALL_SERVER, "Вдвое просевший сервер - это просадка сервера")
	TEST_ASSERT_EQUAL(movement_probe_stall_source(1, TRUE), MOVEMENT_PROBE_STALL_ELSEWHERE, "Ровно идущий сервер при зажатой клавише - настоящая потеря ввода")

	// Полоса неопределённости. Худший выброс прошлого забега дал ровно 0.903
	// при пороге 0.9 и был назван не-сервером на разнице в три тысячных -
	// вердикт, которого замер не выдерживает. Теперь такие честно помечаются.
	TEST_ASSERT_EQUAL(movement_probe_stall_source(0.903, TRUE), MOVEMENT_PROBE_STALL_UNCLEAR, "Отставание впритык к порогу не даёт уверенного вердикта")
	TEST_ASSERT_EQUAL(movement_probe_stall_source(0.97, TRUE), MOVEMENT_PROBE_STALL_ELSEWHERE, "Отставание в пару процентов - это шум замера, а не просадка")

	// Клавишу отпускали - пауза собственная, и валить её на потерю ввода нельзя.
	TEST_ASSERT_EQUAL(movement_probe_stall_source(1, FALSE), MOVEMENT_PROBE_STALL_RELEASED, "Отпущенная клавиша объясняет паузу сама")
	// Но просадка сервера важнее: она объясняет паузу независимо от клавиш.
	TEST_ASSERT_EQUAL(movement_probe_stall_source(0.5, FALSE), MOVEMENT_PROBE_STALL_SERVER, "Просевший сервер объясняет паузу независимо от клавиш")

	// --- Была ли клавиша зажата всю паузу ---
	//
	// keys_held хранит момент нажатия, поэтому вопрос решается сравнением:
	// нажали после предыдущего шага - значит отпускали.

	TEST_ASSERT(movement_probe_key_held_through(990, 1000), "Клавиша, нажатая до предыдущего шага, была зажата насквозь")
	TEST_ASSERT(!movement_probe_key_held_through(1005, 1000), "Клавиша, нажатая после предыдущего шага, до него зажата не была")
	TEST_ASSERT(!movement_probe_key_held_through(0, 1000), "Незажатая клавиша не могла быть зажата насквозь")

	var/list/movement_keys = list("W" = NORTH, "S" = SOUTH)
	TEST_ASSERT_EQUAL(movement_probe_movement_key_time(list("W" = 1005, "Shift" = 900), movement_keys), 1005, "Из зажатых клавиш считаем только клавиши движения")
	TEST_ASSERT_EQUAL(movement_probe_movement_key_time(list("W" = 1005, "S" = 990), movement_keys), 990, "Берём самую раннюю из зажатых клавиш движения")
	TEST_ASSERT_EQUAL(movement_probe_movement_key_time(list("Shift" = 900), movement_keys), 0, "Без клавиш движения момента нажатия нет")
	TEST_ASSERT_EQUAL(movement_probe_movement_key_time(null, movement_keys), 0, "Пустой список зажатых клавиш не должен падать")
