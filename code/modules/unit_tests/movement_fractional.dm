/mob/living/simple_animal/fractional_movement_fixture
	AIStatus = AI_OFF

/mob/living/simple_animal/fractional_movement_fixture/has_gravity(turf/target)
	return STANDARD_GRAVITY

/datum/unit_test/proc/fractional_test_step(datum/fractional_movement_schedule/schedule, mob/mover, delay, direction, now, external_target = 0)
	if(schedule.render_mode == FRACTIONAL_MOVEMENT_QUEUED && (isnull(schedule.saved_animation) || schedule.mover_ref?.resolve() != mover))
		schedule.begin_step(mover, schedule.next_target, now - 0.5, 0.5)
	if(schedule.begin_step(mover, schedule.next_target, now, 0.5) != TRUE)
		return FALSE
	var/turf/destination = get_step(mover, direction)
	mover.set_glide_size(DELAY_TO_GLIDE_SIZE(movement_step_delay(delay, ISDIAGONALDIR(direction), 0.5)))
	mover.Move(destination, direction)
	schedule.finish_step(mover, delay, ISDIAGONALDIR(direction) && mover.loc == destination, now, external_target, 0.5, 32, 1)
	return TRUE

/// Дробные цены сохраняют среднюю скорость и ограничивают ошибку одним тиком.
/datum/unit_test/fractional_movement_cadence/Run()
	var/datum/fractional_movement_schedule/schedule = allocate(/datum/fractional_movement_schedule, FRACTIONAL_MOVEMENT_QUEUED)
	for(var/tick_lag in list(0.25, 0.5, 1))
		for(var/cost in list(0, 0.2, 0.6, 1.5, 1.6, 1.7, 1.8, 1.5 * SQRT_2, 17.3))
			schedule.remainder = 0
			var/elapsed = 0
			for(var/index in 1 to 2000)
				schedule.plan_step(cost, 864000 + elapsed, 0, tick_lag)
				elapsed += schedule.step_interval
				var/error = elapsed - index * max(cost, tick_lag)
				TEST_ASSERT(error >= -0.01 && error <= tick_lag + 0.01, "Цена [cost], тик [tick_lag], шаг [index]: накопленная ошибка [error]")
				TEST_ASSERT(schedule.step_interval >= tick_lag, "Нельзя выдавать несколько шагов за тик")
				TEST_ASSERT(schedule.remainder >= 0 && schedule.remainder < tick_lag, "Остаток обязан помещаться в один тик")
				TEST_ASSERT_EQUAL(schedule.next_target, 864000 + elapsed, "Срок должен лежать на сетке тиков даже в длинном раунде")

/// Прямая серия сходится к номинальному glide без расчётных пауз на дробных шагах.
/datum/unit_test/fractional_movement_glide
	var/datum/turf_reservation/corridor

/datum/unit_test/fractional_movement_glide/Destroy()
	. = ..()
	QDEL_NULL(corridor)

/datum/unit_test/fractional_movement_glide/Run()
	corridor = SSmapping.RequestBlockReservation(66, 3)
	TEST_ASSERT_NOTNULL(corridor, "Нужен коридор для непрерывного движения")
	for(var/turf/tile as anything in corridor.reserved_turfs)
		tile.ChangeTurf(/turf/open/floor/plasteel)
	var/turf/start = locate(corridor.bottom_left_coords[1] + 1, corridor.bottom_left_coords[2] + 1, corridor.bottom_left_coords[3])
	var/mob/living/simple_animal/fractional_movement_fixture/mover = allocate(/mob/living/simple_animal/fractional_movement_fixture, start)
	var/datum/fractional_movement_schedule/schedule = allocate(/datum/fractional_movement_schedule, FRACTIONAL_MOVEMENT_QUEUED)
	for(var/cost in list(0.6, 1.5, 1.6, 1.7, 1.8, 2.12132, 17.3))
		mover.forceMove(start)
		var/now = 1000
		var/previous_finish = 0
		for(var/index in 1 to 60)
			TEST_ASSERT(fractional_test_step(schedule, mover, cost, EAST, now), "Шаг должен использовать экспериментальное расписание")
			TEST_ASSERT_EQUAL(mover.x, start.x + index, "Моб обязан реально пройти тайл")
			TEST_ASSERT(schedule.active, "Успешный шаг должен сохранять остаток")
			TEST_ASSERT(schedule.visual_duration + 0.0001 >= schedule.step_interval, "Спрайт не должен доезжать до следующего серверного шага")
			TEST_ASSERT(schedule.visual_duration - schedule.step_interval <= 0.5001, "Расчётный хвост не должен превышать тик")
			if(previous_finish)
				TEST_ASSERT(abs(previous_finish - (now + schedule.render_delay)) < 0.001, "Последовательные анимации обязаны стыковаться без пауз и наложения")
			previous_finish = now + schedule.visual_duration
			if(index >= 12)
				TEST_ASSERT(abs(mover.glide_size - 16 / cost) < 0.001, "Постоянная скорость [cost] должна давать устойчивый glide, получен [mover.glide_size]")
			now = schedule.next_target

/// Повороты, диагонали, ускорения и замедления сохраняют непрерывность модели.
/datum/unit_test/fractional_movement_turns/Run()
	var/mob/living/simple_animal/fractional_movement_fixture/mover = allocate(/mob/living/simple_animal/fractional_movement_fixture, get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/datum/fractional_movement_schedule/schedule = allocate(/datum/fractional_movement_schedule, FRACTIONAL_MOVEMENT_QUEUED)
	var/list/directions = list(EAST, WEST, NORTHEAST, NORTHWEST, SOUTHWEST, SOUTHEAST)
	var/list/costs = list(1.6, 1.8, 4.6, 0.6, 1.5, 1.7)
	var/now = 1000
	var/expected_total = 0
	for(var/index in 1 to length(directions))
		var/direction = directions[index]
		var/cost = costs[index]
		expected_total += cost * (ISDIAGONALDIR(direction) ? SQRT_2 : 1)
		TEST_ASSERT(fractional_test_step(schedule, mover, cost, direction, now), "Поворот должен быть оплачен")
		TEST_ASSERT(schedule.active, "Поворот должен действительно переместить моба")
		TEST_ASSERT(schedule.next_target - 1000 >= expected_total - 0.001, "Смена направления или скорости не должна выдавать бесплатные шаги")
		TEST_ASSERT(schedule.next_target - 1000 < expected_total + 0.5001, "Смена направления не должна терять дробный остаток")
		TEST_ASSERT(schedule.visual_duration >= schedule.step_interval - 0.0001, "При повороте нельзя закладывать простой")
		TEST_ASSERT(mover.glide_size > 0 && mover.glide_size <= MAX_GLIDE_SIZE, "Glide должен оставаться конечным и ограниченным")
		now = schedule.next_target

/// Неудачный шаг не перезапускает скольжение и не накапливает скидку.
/datum/unit_test/fractional_movement_blocked/Run()
	var/mob/living/simple_animal/fractional_movement_fixture/mover = allocate(/mob/living/simple_animal/fractional_movement_fixture)
	var/datum/fractional_movement_schedule/schedule = allocate(/datum/fractional_movement_schedule, FRACTIONAL_MOVEMENT_QUEUED)
	TEST_ASSERT(fractional_test_step(schedule, mover, 1.6, EAST, 1000), "Нужен первый шаг")
	var/previous_glide = mover.glide_size
	var/now = schedule.next_target
	TEST_ASSERT(schedule.begin_step(mover, now, now, 0.5), "Попытка шага должна начинаться")
	mover.set_glide_size(32)
	var/turf/old_turf = mover.loc
	var/turf/blocker = get_step(mover, EAST)
	blocker = blocker.ChangeTurf(/turf/closed/wall)
	mover.Move(blocker, EAST)
	TEST_ASSERT_EQUAL(mover.loc, old_turf, "Стена должна действительно остановить моба")
	schedule.finish_step(mover, 1.6, FALSE, now, 0, 0.5, 32, 1)
	TEST_ASSERT_EQUAL(mover.glide_size, previous_glide, "Упор в препятствие не должен менять текущую анимацию")
	TEST_ASSERT(!schedule.active, "Неудачный шаг разрывает серию")
	now = schedule.next_target
	TEST_ASSERT(schedule.begin_step(mover, now, now, 0.5), "После препятствия можно начать новый шаг")
	TEST_ASSERT_EQUAL(schedule.remainder, 0, "Неудачную попытку нельзя превратить в скидку")
	schedule.in_step = FALSE

/// Частично выполненная диагональ оплачивается и отображается как прямой шаг.
/datum/unit_test/fractional_movement_partial_diagonal/Run()
	var/mob/living/simple_animal/fractional_movement_fixture/mover = allocate(/mob/living/simple_animal/fractional_movement_fixture)
	var/datum/fractional_movement_schedule/schedule = allocate(/datum/fractional_movement_schedule, FRACTIONAL_MOVEMENT_QUEUED)
	var/turf/expected = get_step(mover, NORTH)
	var/turf/blocker = get_step(mover, NORTHEAST)
	blocker.ChangeTurf(/turf/closed/wall)
	TEST_ASSERT(fractional_test_step(schedule, mover, 1.6, NORTHEAST, 1000), "Нужна попытка движения по диагонали")
	TEST_ASSERT_EQUAL(mover.loc, expected, "Первая половина диагонали должна пройти на север")
	TEST_ASSERT_EQUAL(schedule.step_cost, 1.6, "За единственный пройденный тайл нельзя списывать диагональную цену")
	TEST_ASSERT_EQUAL(schedule.visual_distance, 32, "Модель должна использовать фактическое смещение")

/// Пауза, пропущенный тик и чужой кулдаун сбрасывают остаток без догоняющего рывка.
/datum/unit_test/fractional_movement_interruptions/Run()
	var/mob/living/simple_animal/fractional_movement_fixture/mover = allocate(/mob/living/simple_animal/fractional_movement_fixture)
	var/datum/fractional_movement_schedule/schedule = allocate(/datum/fractional_movement_schedule, FRACTIONAL_MOVEMENT_QUEUED)
	TEST_ASSERT(fractional_test_step(schedule, mover, 1.6, EAST, 1000), "Нужна дробная серия")
	TEST_ASSERT(schedule.remainder > 0, "В серии должен быть остаток")
	var/now = schedule.next_target + 0.5
	TEST_ASSERT(schedule.begin_step(mover, schedule.next_target, now, 0.5), "Пропущенный тик не блокирует движение")
	TEST_ASSERT_EQUAL(schedule.remainder, 0, "Пропущенное время не превращается в бесплатное движение")
	mover.Move(get_step(mover, NORTH), NORTH)
	schedule.finish_step(mover, 1.6, FALSE, now, now + 10, 0.5, 32, 1)
	TEST_ASSERT_EQUAL(schedule.next_target, now + 10, "Внешний штраф внутри Move нельзя сократить")
	TEST_ASSERT_NOTEQUAL(schedule.owned_target, schedule.next_target, "Чужой срок не должен стать собственным")
	TEST_ASSERT(!schedule.active, "Чужой штраф прерывает серию")
	TEST_ASSERT(schedule.begin_step(mover, schedule.next_target, schedule.next_target, 0.5), "После штрафа можно возобновить движение")
	TEST_ASSERT_EQUAL(schedule.remainder, 0, "Чужой штраф не даёт скидку")
	schedule.in_step = FALSE

/// Перемещение извне, смена тела и удаление разрывают состояние и подписки.
/datum/unit_test/fractional_movement_lifecycle/Run()
	var/mob/living/simple_animal/fractional_movement_fixture/first = allocate(/mob/living/simple_animal/fractional_movement_fixture)
	var/mob/living/simple_animal/fractional_movement_fixture/second = allocate(/mob/living/simple_animal/fractional_movement_fixture, get_step(run_loc_floor_bottom_left, NORTH))
	var/datum/fractional_movement_schedule/schedule = allocate(/datum/fractional_movement_schedule, FRACTIONAL_MOVEMENT_QUEUED)
	TEST_ASSERT(fractional_test_step(schedule, first, 1.6, EAST, 1000), "Нужна активная серия")
	first.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(!schedule.active && !schedule.visual_valid, "Телепорт сбрасывает модель")
	TEST_ASSERT_EQUAL(first.animate_movement, SLIDE_STEPS, "Телепорт восстанавливает обычную анимацию")
	TEST_ASSERT_EQUAL(first.pixel_w, 0, "Именованные анимации не оставляют горизонтальный сдвиг")
	TEST_ASSERT_EQUAL(first.pixel_z, 0, "Именованные анимации не оставляют вертикальный сдвиг")
	TEST_ASSERT(fractional_test_step(schedule, second, 1.6, EAST, 1000), "Новое тело должно начать собственную серию")
	first.forceMove(get_step(first, NORTH))
	TEST_ASSERT(schedule.active, "Движение прежнего тела не должно затрагивать новое")
	var/now = schedule.next_target
	TEST_ASSERT(schedule.begin_step(second, now, now, 0.5), "Нужен начатый шаг")
	second.forceMove(get_step(second, NORTH))
	schedule.finish_step(second, 1.6, FALSE, now, 0, 0.5, 32, 1)
	TEST_ASSERT(!schedule.visual_valid && !schedule.active, "forceMove внутри шага тоже сбрасывает модель")
	qdel(second)
	TEST_ASSERT_NULL(schedule.mover_ref, "Удаление тела освобождает подписку и weakref")

/// Пуллинг и дрейф возвращаются к штатному движению без оставшейся анимации.
/datum/unit_test/fractional_movement_pull_and_drift/Run()
	var/mob/living/simple_animal/fractional_movement_fixture/mover = allocate(/mob/living/simple_animal/fractional_movement_fixture)
	var/obj/item/pullee = allocate(/obj/item, mover.loc)
	var/datum/fractional_movement_schedule/schedule = allocate(/datum/fractional_movement_schedule, FRACTIONAL_MOVEMENT_QUEUED)
	TEST_ASSERT(fractional_test_step(schedule, mover, 1.6, EAST, 1000), "Нужен активный эксперимент")
	mover.start_pulling(pullee)
	TEST_ASSERT_EQUAL(mover.pulling, pullee, "Нужен настоящий пуллинг")
	TEST_ASSERT(!schedule.begin_step(mover, schedule.next_target, schedule.next_target, 0.5), "Пуллинг пока использует штатное движение")
	TEST_ASSERT_EQUAL(mover.animate_movement, SLIDE_STEPS, "Пуллинг возвращает штатную анимацию")
	mover.stop_pulling()
	mover.movement_type |= FLOATING
	TEST_ASSERT(!schedule.begin_step(mover, schedule.next_target, schedule.next_target, 0.5), "Дрейф должен остаться на штатном расписании")
	TEST_ASSERT(!schedule.active, "После перехода к дрейфу остаток не используется")

/// Отключение сохраняет исходные смещения и освобождает управление анимацией.
/datum/unit_test/fractional_movement_visual_cleanup/Run()
	var/mob/living/simple_animal/fractional_movement_fixture/mover = allocate(/mob/living/simple_animal/fractional_movement_fixture)
	var/datum/fractional_movement_schedule/schedule = allocate(/datum/fractional_movement_schedule, FRACTIONAL_MOVEMENT_QUEUED)
	mover.pixel_x = 7
	mover.pixel_y = 12
	TEST_ASSERT_EQUAL(schedule.begin_step(mover, 0, 999.5, 0.5), FRACTIONAL_MOVEMENT_PREPARING, "До первого шага нужно передать клиенту отключение glide")
	TEST_ASSERT(!schedule.in_step, "Подготовка не должна считаться начавшимся шагом")
	TEST_ASSERT_EQUAL(schedule.begin_step(mover, 0, 999.5, 0.5), FRACTIONAL_MOVEMENT_PREPARING, "Повторный ввод в тот же тик не обходит подготовку")
	TEST_ASSERT_EQUAL(schedule.begin_step(mover, 0, 1000, 0.5), TRUE, "Со следующего тика можно начинать шаг")
	TEST_ASSERT_EQUAL(mover.pixel_y, 12, "Начало шага сохраняет чужую высоту")
	var/turf/destination = get_step(mover, EAST)
	mover.Move(destination, EAST)
	TEST_ASSERT_EQUAL(mover.loc, destination, "Моб должен действительно пройти тайл")
	mover.pixel_x = 7
	mover.pixel_y = 12
	schedule.finish_step(mover, 1.6, FALSE, 1000, 0, 0.5, 32, 1)
	TEST_ASSERT_EQUAL(mover.animate_movement, NO_STEPS, "Штатный glide не должен складываться с новой анимацией")
	TEST_ASSERT_EQUAL(mover.pixel_x, 7, "Относительная анимация сохраняет исходное горизонтальное смещение")
	TEST_ASSERT_EQUAL(mover.pixel_y, 12, "Относительная анимация сохраняет исходную высоту")
	schedule.unwatch()
	TEST_ASSERT_EQUAL(mover.animate_movement, SLIDE_STEPS, "Отключение восстанавливает штатную анимацию")
	TEST_ASSERT_EQUAL(mover.pixel_x, 7, "Отключение не сбрасывает чужое смещение")
	TEST_ASSERT_EQUAL(mover.pixel_y, 12, "Отключение не сбрасывает чужую высоту")
	TEST_ASSERT_NULL(schedule.mover_ref, "Отключение освобождает подписку")

/// Оба способа отображения дают одинаковые сроки, но только очередь добавляет буфер.
/datum/unit_test/fractional_movement_native/Run()
	var/mob/living/simple_animal/fractional_movement_fixture/native = allocate(/mob/living/simple_animal/fractional_movement_fixture)
	var/mob/living/simple_animal/fractional_movement_fixture/queued = allocate(/mob/living/simple_animal/fractional_movement_fixture, get_step(native, NORTH))
	var/datum/fractional_movement_schedule/native_schedule = allocate(/datum/fractional_movement_schedule)
	var/datum/fractional_movement_schedule/queued_schedule = allocate(/datum/fractional_movement_schedule, FRACTIONAL_MOVEMENT_QUEUED)
	native.pixel_w = 7
	var/now = 1000
	for(var/cost in list(1.5, 1.6, 1.7, 1.8, 0.6, 2.12132))
		for(var/index in 1 to 20)
			var/direction = index % 2 ? EAST : WEST
			TEST_ASSERT(fractional_test_step(native_schedule, native, cost, direction, now), "Нужен шаг со штатным glide")
			TEST_ASSERT(fractional_test_step(queued_schedule, queued, cost, direction, now), "Нужен шаг с очередью")
			TEST_ASSERT(native_schedule.active && queued_schedule.active, "Оба моба должны действительно двигаться")
			TEST_ASSERT_EQUAL(native_schedule.next_target, queued_schedule.next_target, "Отображение не должно менять скорость")
			TEST_ASSERT_EQUAL(native_schedule.remainder, queued_schedule.remainder, "Дробный остаток не зависит от отображения")
			TEST_ASSERT_EQUAL(native_schedule.render_delay, 0, "Штатному glide не нужен буфер")
			TEST_ASSERT_EQUAL(native.animate_movement, SLIDE_STEPS, "Штатная анимация должна остаться включённой")
			TEST_ASSERT_NULL(native_schedule.saved_animation, "Штатный glide не должен захватывать управление анимациями")
			TEST_ASSERT_EQUAL(native.pixel_w, 7, "Штатный glide сохраняет горизонтальное смещение")
			TEST_ASSERT_EQUAL(native.pixel_z, 0, "Штатный glide не добавляет вертикальное смещение")
			TEST_ASSERT_EQUAL(queued.animate_movement, NO_STEPS, "Очередь должна отключать штатный glide")
			now = native_schedule.next_target
	native.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(!native_schedule.active, "Телепорт прерывает дробное расписание и со штатным glide")
	native.animate_movement = SYNC_STEPS
	native_schedule.unwatch()
	TEST_ASSERT_EQUAL(native.animate_movement, SYNC_STEPS, "Отключение штатного режима сохраняет чужую смену анимации")
	queued_schedule.unwatch()
	TEST_ASSERT_EQUAL(queued.animate_movement, SLIDE_STEPS, "Отключение очереди возвращает штатную анимацию")

/// Запасной путь игрока считает диагональ от уже выровненной прямой цены.
/datum/unit_test/fractional_movement_fallback_diagonal/Run()
	TEST_ASSERT_EQUAL(movement_client_step_delay(1.6, FALSE, 0.5), 1.5, "Прямой шаг 1.6 на прежнем расписании стоит три тика")
	TEST_ASSERT_EQUAL(movement_client_step_delay(1.6, TRUE, 0.5), 2, "Диагональ при беге 1.6 обязана стоить как при прежних 1.5, а не 2.5")
	for(var/base in list(0.5, 1, 1.5, 2, 3, 5))
		for(var/diagonal in list(FALSE, TRUE))
			TEST_ASSERT_EQUAL(movement_client_step_delay(base, diagonal, 0.5), movement_step_delay(base, diagonal, 0.5), "Кратная тику база [base] (диагональ: [diagonal]) не должна менять цену")
	for(var/base in list(1.1, 1.6, 1.7, 2.2, 2.6))
		TEST_ASSERT(movement_client_step_delay(base, TRUE, 0.5) > movement_client_step_delay(base, FALSE, 0.5), "Диагональ при базе [base] обязана стоить дороже прямого шага")
