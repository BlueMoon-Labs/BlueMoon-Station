/// Математика шагового расписания и glide_size.
///
/// Шаг может произойти только на серверном тике: keyLoop() зовётся из SSinput,
/// а это SS_TICKER с wait = 1. То же и у мобов - SSmovement разливает бакет
/// не раньше своего времени, и тоже на тике.
///
/// Отсюда всё остальное. Пока цена шага не кратна тику, интервал обязан гулять:
/// 1.6ds на сетке 0.5ds даёт 3,3,3,3,4 тика, то есть скачок скорости на треть
/// каждый пятый шаг. Никакой расчёт glide этого не лечит - движение
/// действительно неравномерное. Поэтому выравнивается цена, а glide считается
/// от неё.

/datum/unit_test/movement_glide_math

/datum/unit_test/movement_glide_math/Run()
	var/tick_lag = 0.5 // прод: FPS 20 в config/entries/server.txt
	var/icon_size = 32
	var/run_delay = 1.5 // прод: RUN_DELAY, ровно три тика

	// --- Фазозависимое число тиков ---
	//
	// Нужно там, где расписание уже сдвинули и надо узнать, сколько тиков
	// осталось на самом деле: перебазирование шага на смене скорости считает
	// по нему остаток пути для glide.

	// Расписание в прошлом - ждать нечего.
	TEST_ASSERT_EQUAL(movement_ticks_until(500, 1000, tick_lag), 1, "Просроченное расписание отдаёт шаг на ближайшем тике")
	TEST_ASSERT_EQUAL(movement_ticks_until(1001.5, 1000, tick_lag), 3, "Полтора децисекунды впереди - это три тика")
	// Плавающий хвост не имеет права добавлять лишний тик.
	TEST_ASSERT_EQUAL(movement_ticks_until(1001.0000001, 1000, tick_lag), 2, "Хвост не имеет права добавлять тик к остатку")

	// Некратная задержка гуляет по построению: 1.6ds на сетке 0.5ds даёт
	// 4,3,3,3,3 с периодом в пять шагов. Среднее при этом точно 1.6 - то есть
	// скорость не искажается, искажается ритм. Ровно от этого и лечим.
	var/list/expected_intervals = list(4, 3, 3, 3, 3, 4, 3, 3, 3, 3)
	var/now = 0
	var/scheduled = 0
	for(var/index in 1 to length(expected_intervals))
		scheduled += 1.6
		var/interval = movement_ticks_until(scheduled, now, tick_lag)
		TEST_ASSERT_EQUAL(interval, expected_intervals[index], "Шаг [index] при 1.6ds обязан занять [expected_intervals[index]] тика, а занял [interval]")
		now += interval * tick_lag
	var/average_delay = now / length(expected_intervals)
	TEST_ASSERT(abs(average_delay - 1.6) < 0.001, "Некратная задержка обязана сохранять среднюю скорость, а вышло [average_delay]ds вместо 1.6")

	// А кратная не гуляет вовсе - в этом весь смысл выравнивания.
	now = 0
	scheduled = 0
	for(var/index in 1 to 10)
		scheduled += run_delay
		var/interval = movement_ticks_until(scheduled, now, tick_lag)
		TEST_ASSERT_EQUAL(interval, 3, "Кратная задержка [run_delay]ds обязана давать три тика каждый шаг, а шаг [index] занял [interval]")
		now += interval * tick_lag

	// --- Квантование задержки ---

	// База, уже кратная тику, обязана остаться собой.
	TEST_ASSERT_EQUAL(movement_step_delay(1.5, FALSE, tick_lag), 1.5, "Кратная база не должна двигаться")
	TEST_ASSERT_EQUAL(movement_step_delay(1.6, FALSE, tick_lag), 1.5, "1.6ds обязана подтянуться к 1.5 - это три тика")
	TEST_ASSERT_EQUAL(movement_step_delay(1.8, FALSE, tick_lag), 2, "1.8ds ближе к четырём тикам, чем к трём")

	// Диагональ считается от базы и тоже выравнивается. При базе 1.5 это
	// 2.121ds, то есть ровно четыре тика.
	TEST_ASSERT_EQUAL(movement_step_delay(1.5, TRUE, tick_lag), 2, "Диагональ при базе 1.5 обязана стать ровно четырьмя тиками")

	// Диагональ обязана быть медленнее прямого хода, иначе ходить наискось
	// станет выгоднее прямого - при любой базе.
	for(var/base in list(1, 1.5, 2, 2.5, 3, 5))
		var/straight = movement_step_delay(base, FALSE, tick_lag)
		var/diagonal = movement_step_delay(base, TRUE, tick_lag)
		TEST_ASSERT(diagonal > straight, "При базе [base]ds диагональ ([diagonal]) обязана быть длиннее прямого хода ([straight])")

	// Быстрее одного тика шагать нельзя - его просто не на чем показать.
	TEST_ASSERT_EQUAL(movement_quantize_delay(0.2, tick_lag), tick_lag, "Задержка короче тика квантуется в один тик, а не в ноль")
	TEST_ASSERT_EQUAL(movement_quantize_delay(0, tick_lag), tick_lag, "Нулевая задержка тоже занимает тик")

	// Ровно половина ступени обязана падать вниз, и падать одинаково каждый
	// раз. Без допуска её кидало бы между соседними тиками от плавающего
	// хвоста - то самое гуляние интервала, ради которого всё затевалось.
	TEST_ASSERT_EQUAL(movement_quantize_delay(1.75, tick_lag), 1.5, "Ровно половина ступени обязана уходить вниз")
	TEST_ASSERT_EQUAL(movement_quantize_delay(1.75 + 0.0000001, tick_lag), 1.5, "Хвост сверху не имеет права перекинуть половину ступени вверх")
	TEST_ASSERT_EQUAL(movement_quantize_delay(1.75 - 0.0000001, tick_lag), 1.5, "Хвост снизу обязан давать тот же ответ, что и хвост сверху")
	// А настоящее превышение половины - обязано.
	TEST_ASSERT_EQUAL(movement_quantize_delay(1.8, tick_lag), 2, "Настоящее превышение половины ступени обязано округляться вверх")

	// Что бы ни пришло на вход, на выходе обязано быть целое число тиков -
	// в этом весь смысл.
	for(var/base in list(0.1, 1.37, 1.6, 2.2222, 4.9))
		for(var/diagonal in list(FALSE, TRUE))
			var/result = movement_step_delay(base, diagonal, tick_lag)
			var/ticks = result / tick_lag
			TEST_ASSERT(abs(ticks - round(ticks + 0.5)) < 0.001, "База [base]ds (диагональ: [diagonal]) дала [result]ds - это [ticks] тика, а обязано быть целое")
			TEST_ASSERT(result >= tick_lag, "Задержка не имеет права быть короче тика, а получилась [result]ds")

	// --- Смена скорости, пока шаг в полёте ---
	//
	// Шаг оплачен вперёд. Ускорился - расписание подтягивается, замедлился -
	// остаётся как было: удорожать уже оплаченный шаг задним числом значит
	// останавливать персонажа посреди тайла.

	var/target = 1000 + run_delay // шаг сделан в 1000, следующий разрешён в 1001.5

	// Трогать можно только своё расписание. move_delay пишет ещё и захват
	// (world.time + 10), и админские вербы: подтянуть такой срок как свой -
	// значит отменить чужой штраф, и схваченный персонаж вырвется, надев ботинки.
	TEST_ASSERT(movement_can_reschedule(target, target, 1000.5), "Своё расписание перебазировать можно")
	TEST_ASSERT(!movement_can_reschedule(1010, target, 1000.5), "Чужой срок в расписании запрещает перебазирование")
	TEST_ASSERT(!movement_can_reschedule(target, target, target), "Наступивший срок ускорять нечего")
	TEST_ASSERT(!movement_can_reschedule(target, target, 1002), "Просроченный срок ускорять тоже нечего")
	// На старте раунда оба нуля совпадают - это не повод считать расписание своим.
	TEST_ASSERT(!movement_can_reschedule(0, 0, 0), "Нетронутое расписание в начале раунда перебазировать нельзя")

	// Замедление расписание не трогает.
	TEST_ASSERT_EQUAL(movement_reschedule_step(target, run_delay, 2.5, 1000.5, tick_lag), target, "Замедление не имеет права отодвигать уже оплаченный шаг")
	TEST_ASSERT_EQUAL(movement_reschedule_step(target, run_delay, run_delay, 1000.5, tick_lag), target, "Неизменная цена не имеет права двигать расписание")

	// Ускорение подтягивает ровно на разницу цен.
	TEST_ASSERT_EQUAL(movement_reschedule_step(target, run_delay, 1, 1000.5, tick_lag), 1001, "Ускорение обязано подтянуть расписание ровно на разницу цен")

	// Пересчёт при неизменной цене не имеет права разгонять: сколько ни зови,
	// срок стоит на месте. Иначе дёрганьем модификаторов можно было бы бегать
	// быстрее собственной скорости.
	var/repeated = target
	for(var/index in 1 to 5)
		repeated = movement_reschedule_step(repeated, 1, 1, 1000.5, tick_lag)
	TEST_ASSERT_EQUAL(repeated, target, "Повторный пересчёт при неизменной цене обязан оставлять расписание на месте")

	// Новая цена может оказаться уже в прошлом - тогда шаг отдаётся на
	// ближайшем тике, а не задним числом.
	TEST_ASSERT_EQUAL(movement_reschedule_step(target, run_delay, 0.5, 1001, tick_lag), 1001.5, "Подтягивать раньше следующего тика нельзя")
	// И никогда не позже текущего срока: подтягиваем, а не отодвигаем.
	var/late = movement_reschedule_step(1000.5, 2, 0.5, 1000, tick_lag)
	TEST_ASSERT(late <= 1000.5, "Перебазирование не имеет права отодвинуть срок, а отодвинуло до [late]")

	// --- glide на догон ---

	// Спрайт проехал два тика по 32/3 пикселя, осталось два тика до нового
	// срока: остаток пути делится на остаток тиков.
	var/step_glide = icon_size / 3
	var/catchup = movement_catchup_glide(step_glide, 2, 2, icon_size)
	TEST_ASSERT(abs(catchup - (icon_size - step_glide * 2) / 2) < 0.001, "glide на догон обязан делить остаток пути на остаток тиков, а вышло [catchup]")

	// Сколько бы ни осталось, спрайт обязан доехать ровно к сроку.
	for(var/elapsed in list(0, 1, 2))
		for(var/remaining in list(1, 2, 3))
			var/glide = movement_catchup_glide(step_glide, elapsed, remaining, icon_size)
			var/covered = (step_glide * elapsed) + (glide * remaining)
			TEST_ASSERT(abs(covered - icon_size) < 0.001, "После [elapsed] тиков пути и [remaining] тиков догона спрайт обязан покрыть тайл ровно, а покрыл [covered]")

	// Спрайт уже на месте - догонять нечего, и уводить glide в минус нельзя.
	TEST_ASSERT_EQUAL(movement_catchup_glide(icon_size, 2, 2, icon_size), 0, "Доехавшему спрайту догонять нечего")
	TEST_ASSERT_EQUAL(movement_catchup_glide(step_glide, 0, 0, icon_size), icon_size, "Без остатка тиков шаг обязан быть мгновенным, а не делить на ноль")

	// --- Множитель дилатации: снап на выходе сглаживания ---
	//
	// Мёртвая зона на замере спасает от систематического "чуть ниже единицы",
	// но наружу уходит сглаженное значение, а оно подходит к единице
	// асимптотически. Пока снап стоял только на входе, после каждой настоящей
	// просадки множитель подолгу висел в полосе 0.98-0.995: в прод-логе такими
	// были почти все замеры второй половины раунда, и glide на шаге в четыре
	// тика выходил 7.9 px вместо ровных восьми.

	TEST_ASSERT_EQUAL(movement_glide_publish(1), 1, "Единица обязана оставаться единицей")
	TEST_ASSERT_EQUAL(movement_glide_publish(0.99), 1, "Хвост восстановления обязан снапиться к единице")
	TEST_ASSERT_EQUAL(movement_glide_publish(1.01), 1, "Хвост сверху снапится так же")
	TEST_ASSERT_EQUAL(movement_glide_publish(0.97), 0.97, "Просадка за пределами зоны обязана доходить до движения нетронутой")
	TEST_ASSERT_EQUAL(movement_glide_publish(0.9), 0.9, "Настоящая просадка обязана доходить до движения")

	// Снапнутое значение нельзя подмешивать обратно в сглаживание: MC_AVERAGE
	// тянет состояние к прежнему на 80% за прогон, и просадка мельче десяти
	// процентов не накопилась бы никогда - множитель залип бы на единице и
	// перестал компенсировать дилатацию вообще. Проверяем именно это, чтобы
	// разделение состояния и публикуемого значения нельзя было "упростить".
	var/fed_back = 1
	for(var/index in 1 to 60)
		fed_back = movement_glide_publish(MC_AVERAGE(fed_back, 0.95))
	TEST_ASSERT_EQUAL(fed_back, 1, "Обратная связь через снап действительно съедает просадку - ради этого состояние и отделено")

	// А по сырому состоянию та же просадка доходит целиком.
	var/smoothed = 1
	for(var/index in 1 to 60)
		smoothed = MC_AVERAGE(smoothed, 0.95)
	TEST_ASSERT(abs(movement_glide_publish(smoothed) - 0.95) < 0.001, "Сглаживание по сырому состоянию обязано дойти до настоящей просадки, а дошло до [movement_glide_publish(smoothed)]")

/// Тестовый моб, у которого movement_delay() шире кэша замедлений - ровно как у
/// борга (вне спринта +0.5 и vtec) и у вендиго (+1 в темноте).
/mob/living/simple_animal/unit_test_wide_movement_delay

/mob/living/simple_animal/unit_test_wide_movement_delay/movement_delay()
	return ..() + 1

/// Цена шага обязана считаться от одного источника и там, где шаг оплачивают, и
/// там, где его пересчитывают на ходу.
///
/// Пересчёт брал cached_multiplicative_slowdown напрямую, а платил шаг по
/// movement_delay(). Для /mob это одно и то же, а для подтипа с более широким
/// movement_delay() новая цена всегда выходила ниже уплаченной: условие
/// "подешевело" срабатывало на каждом вызове, и расписание подтягивалось на тик
/// вперёд без всякой смены скорости.
/datum/unit_test/movement_step_cost

/datum/unit_test/movement_step_cost/Run()
	var/mob/living/simple_animal/unit_test_wide_movement_delay/critter = allocate(/mob/living/simple_animal/unit_test_wide_movement_delay)

	TEST_ASSERT_NOTEQUAL(critter.movement_delay(), critter.cached_multiplicative_slowdown, "Пример обязан быть про подтип, у которого эти величины расходятся")
	TEST_ASSERT_EQUAL(critter.movement_step_cost(FALSE), movement_step_delay(critter.movement_delay(), FALSE, world.tick_lag), "Цена шага обязана считаться от movement_delay()")
	TEST_ASSERT_NOTEQUAL(critter.movement_step_cost(FALSE), movement_step_delay(critter.cached_multiplicative_slowdown, FALSE, world.tick_lag), "Считать цену от кэша замедлений нельзя: пересчёт видел бы её ниже уплаченной и дарил шагу тик")
	TEST_ASSERT(critter.movement_step_cost(TRUE) > critter.movement_step_cost(FALSE), "Диагональ обязана стоить дороже прямого хода и в общем расчёте цены")

/// Квирк "Быстрый Шаг" обязан давать при ходьбе ровно скорость бега.
///
/// Раньше он вычитал константу 1.25, не кратную ступени тика. На проде (ходьба 3, бег 1.5,
/// тик 0.5) итог 1.75 садился ровно на половину ступени: у голого персонажа уходил вниз до
/// беговых 1.5, и проблемы не было видно. Любое дробное замедление сверху перекидывало сумму
/// через границу - ходьба платила лишний тик, бег нет, и квирк давал 25-33% медленнее бега.
/// Теперь вычитается разница ходьба-минус-бег: она кратна ступени, поэтому базы совпадают,
/// и дальше общее замедление квантуется для ходьбы и бега одинаково.
/// Проверяется сама скидка, а не мобы: задержки ходьбы и бега приходят из конфига, а он в
/// CI не загружается (у walk_delay/run_delay нет дефолтов, и там обе величины совпадают) -
/// мобный тест был бы вакуумным на одной машине и падал на другой.
/datum/unit_test/quick_step_walks_at_run_speed

/datum/unit_test/quick_step_walks_at_run_speed/Run()
	// Пары "ходьба / бег": прод, апстрим, вырожденная (равные) и перевёрнутая (ходьба быстрее).
	var/list/pairs = list(
		list(3, 1.5),
		list(5, 2.5),
		list(2, 2),
		list(1.5, 3),
	)
	for(var/list/pair as anything in pairs)
		var/walk_delay = pair[1]
		var/run_delay = pair[2]
		var/discounted = walk_delay - quick_step_walk_discount(walk_delay, run_delay)
		TEST_ASSERT_EQUAL(discounted, min(walk_delay, run_delay), "Быстрый шаг обязан сводить ходьбу [walk_delay] ровно к бегу [run_delay], а получилось [discounted]")

	TEST_ASSERT_EQUAL(quick_step_walk_discount(1.5, 3), 0, "Ходьба быстрее бега: скидка обязана быть нулевой, а не отрицательной")
	TEST_ASSERT_EQUAL(quick_step_walk_discount(null, 1.5), 0, "Незагруженный конфиг обязан давать нулевую скидку, а не рантайм")
	TEST_ASSERT_EQUAL(quick_step_walk_discount(3, null), 0, "Незагруженный конфиг обязан давать нулевую скидку, а не рантайм")

	// Главное свойство правки: цена совпадает с беговой при любой ступени тика.
	for(var/tick_lag in list(0.25, 0.5, 1))
		var/quick_walk = movement_step_delay(3 - quick_step_walk_discount(3, 1.5), FALSE, tick_lag)
		var/run = movement_step_delay(1.5, FALSE, tick_lag)
		TEST_ASSERT_EQUAL(quick_walk, run, "При тике [tick_lag] ходьба с быстрым шагом ([quick_walk]) обязана стоить как бег ([run])")

	// Тот самый дефект. На проде (тик 0.5) у ГОЛОГО персонажа прежние 1.25 давали ровно
	// беговые 1.5 - поэтому часть игроков проблемы не видела. Ломалось на дробном замедлении
	// сверху: шлем 0.2, хардсьют 0.55, протаскивание тела 0.6. Проверяем оба конца, иначе тест
	// прошёл бы и на прежней константе.
	for(var/extra in list(0.2, 0.55, 0.6))
		var/run_cost = movement_step_delay(1.5 + extra, FALSE, 0.5)
		var/fixed_cost = movement_step_delay(3 - quick_step_walk_discount(3, 1.5) + extra, FALSE, 0.5)
		TEST_ASSERT_EQUAL(fixed_cost, run_cost, "С замедлением [extra] ходьба с быстрым шагом ([fixed_cost]) обязана стоить как бег ([run_cost])")

		var/legacy_cost = movement_step_delay(3 - 1.25 + extra, FALSE, 0.5)
		TEST_ASSERT(legacy_cost > run_cost, "Контроль: прежняя константа при замедлении [extra] обязана давать ходьбу дороже бега ([legacy_cost] против [run_cost]) - иначе тест не сторожит тот дефект")

	// Обычная ходьба обязана остаться медленнее бега, иначе правка съела смысл интента.
	TEST_ASSERT(movement_step_delay(3, FALSE, 0.5) > movement_step_delay(1.5, FALSE, 0.5), "Ходьба без квирка обязана быть медленнее бега")
