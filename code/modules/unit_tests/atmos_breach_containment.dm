#define TEST_BREACH_MOLES 100
#define TEST_BREACH_LEAN_MOLES 40
#define TEST_BREACH_RICH_MOLES 60
/// Доли стандартного давления по ту сторону шва: ниже и выше порога WARNING_LOW_PRESSURE.
#define TEST_BREACH_LOW_PRESSURE_RATIO 0.3
#define TEST_BREACH_SAFE_PRESSURE_RATIO 0.8
#define TEST_BREACH_EPSILON 0.01

/// Строит ряд "космос - a1 - a2 - проём с файрлоком - b1 - b2" и штампует всё вокруг, чтобы обход видел только его.
/proc/build_firelock_breach_row(turf/open/origin, list/row, cycle, with_space)
	var/row_y = origin.y + 2
	var/turf/space_spot = locate(origin.x - 1, row_y, origin.z)
	for(var/offset in 0 to 4)
		row += locate(origin.x + offset, row_y, origin.z)
	if(with_space)
		space_spot.ChangeTurf(/turf/open/space/basic)
		var/turf/open/seed = row[1]
		seed.ImmediateCalculateAdjacentTurfs()
	var/list/turf/open/stamped = list()
	for(var/turf/open/candidate in block(locate(origin.x - 1, origin.y - 1, origin.z), locate(origin.x + 5, origin.y + 5, origin.z)))
		if(candidate in row)
			continue
		candidate.equalize_cycle = cycle
		stamped += candidate
	return stamped

/proc/fill_breach_row(list/turf/open/row)
	for(var/turf/open/member as anything in row)
		member.air.clear()
		member.air.set_temperature(T20C)
		member.air.set_moles(GAS_O2, TEST_BREACH_MOLES)
		if(member.excited_group)
			member.excited_group.garbage_collect()
		SSair.remove_from_active(member)

// Обход не смешивает газ через файрлок и ждёт общей тревоги перед закрытием границы зоны.
/datum/unit_test/atmos_zone_walk_seals_firelock_on_breach

/datum/unit_test/atmos_zone_walk_seals_firelock_on_breach/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/cycle = SSair.times_fired + 1
	var/list/turf/open/row = list()
	var/list/turf/open/stamped = build_firelock_breach_row(run_loc_floor_bottom_left, row, cycle, TRUE)
	var/turf/open/seed = row[1]
	var/turf/open/near_side = row[2]
	var/turf/open/doorway = row[3]
	var/turf/open/far_side = row[4]
	var/turf/open/far_end = row[5]
	var/obj/machinery/door/firedoor/firelock = allocate(/obj/machinery/door/firedoor, doorway)
	doorway.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(near_side.atmos_adjacent_turfs[doorway] & ATMOS_ADJACENT_FIRELOCK, "the doorway pair carries no firelock flag")
	TEST_ASSERT(locate(/turf/open/space) in seed.atmos_adjacent_turfs, "the seed has no space neighbor")
	fill_breach_row(row)

	var/datum/atmos_zone_walk/walk = new
	var/started = walk.begin(seed, cycle)
	if(started)
		walk.advance(0)
	var/far_side_moles = far_side.air.total_moles()
	var/far_end_moles = far_end.air.total_moles()
	var/sealed_before_alarm = firelock.density
	var/area/base = get_base_area(doorway)
	var/saved_fire = base.fire
	base.fire = TRUE
	fill_breach_row(row)
	for(var/turf/open/member as anything in stamped)
		member.equalize_cycle = cycle + 1
	if(walk.begin(seed, cycle + 1))
		walk.advance(0)
	var/sealed_after_alarm = firelock.density
	base.fire = saved_fire
	if(firelock.operating)
		wait_for_var(firelock, "operating", FALSE)
	restore_zone_walk_turfs(row, stamped)

	TEST_ASSERT(started, "the walk refused the breach seed")
	TEST_ASSERT(abs(far_side_moles - TEST_BREACH_MOLES) < TEST_BREACH_EPSILON, "the walk mixed gas through an open firelock: [far_side_moles] mol behind it")
	TEST_ASSERT(abs(far_end_moles - TEST_BREACH_MOLES) < TEST_BREACH_EPSILON, "the walk mixed gas through an open firelock: [far_end_moles] mol at the far end")
	TEST_ASSERT(!sealed_before_alarm, "пограничный файрлок закрылся до подтверждения общей тревоги")
	TEST_ASSERT(sealed_after_alarm, "пограничный файрлок не закрылся при действующей общей тревоге")

/// Без выхода в космос обход по-прежнему не идёт через файрлок, но и не закрывает его.
/datum/unit_test/atmos_zone_walk_keeps_firelock_without_breach

/datum/unit_test/atmos_zone_walk_keeps_firelock_without_breach/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/cycle = SSair.times_fired + 1
	var/list/turf/open/row = list()
	var/list/turf/open/stamped = build_firelock_breach_row(run_loc_floor_bottom_left, row, cycle, FALSE)
	var/turf/open/seed = row[1]
	var/turf/open/near_side = row[2]
	var/turf/open/doorway = row[3]
	var/turf/open/far_side = row[4]
	var/obj/machinery/door/firedoor/firelock = allocate(/obj/machinery/door/firedoor, doorway)
	doorway.ImmediateCalculateAdjacentTurfs()
	fill_breach_row(row)
	seed.air.set_moles(GAS_O2, TEST_BREACH_LEAN_MOLES)
	near_side.air.set_moles(GAS_O2, TEST_BREACH_RICH_MOLES)

	var/datum/atmos_zone_walk/walk = new
	var/started = walk.begin(seed, cycle)
	if(started)
		walk.advance(0)
	var/seed_moles = seed.air.total_moles()
	var/far_side_moles = far_side.air.total_moles()
	var/sealed = firelock.density
	restore_zone_walk_turfs(row, stamped)

	TEST_ASSERT(walk.did_work, "the walk skipped a zone with a real pressure spread")
	TEST_ASSERT(abs(seed_moles - (TEST_BREACH_LEAN_MOLES + TEST_BREACH_RICH_MOLES) / 2) < TEST_BREACH_EPSILON, "the zone in front of the firelock was not averaged on its own: [seed_moles] mol")
	TEST_ASSERT(abs(far_side_moles - TEST_BREACH_MOLES) < TEST_BREACH_EPSILON, "the walk mixed gas through an open firelock: [far_side_moles] mol behind it")
	TEST_ASSERT(!sealed, "a zone with no way to space closed a firelock")

/// Ареал, стравливающий газ в разгерметизированный ареал через проём без файрлока, сам встаёт в декомп-очередь.
/datum/unit_test/decompression_spreads_through_open_seam
	var/turf/open/feeding
	var/turf/open/drained
	var/area/feeding_old_area
	var/area/drained_old_area
	var/area/unit_test_decompression/feeding_area
	var/area/unit_test_decompression/drained_area

/datum/unit_test/decompression_spreads_through_open_seam/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	feeding = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	drained = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	TEST_ASSERT(istype(feeding) && istype(drained), "test locations are not open turfs")
	feeding_old_area = get_area(feeding)
	drained_old_area = get_area(drained)
	feeding_area = new
	drained_area = new
	feeding_area.contents += feeding
	drained_area.contents += drained
	TEST_ASSERT(!(feeding.atmos_adjacent_turfs[drained] & ATMOS_ADJACENT_FIRELOCK), "the seam carries a firelock flag")

	SSair.decompression_handled_at[drained_area] = world.time
	seam_share(TEST_BREACH_LOW_PRESSURE_RATIO)
	TEST_ASSERT(SSair.decompression_areas[feeding_area], "a room feeding a decompressed area through an open seam was not queued")

	reset_seam()
	SSair.decompression_handled_at[drained_area] = world.time
	seam_share(TEST_BREACH_SAFE_PRESSURE_RATIO)
	TEST_ASSERT(!SSair.decompression_areas[feeding_area], "a seam above the low-pressure gate spread the decompression")

	reset_seam()
	seam_share(TEST_BREACH_LOW_PRESSURE_RATIO)
	TEST_ASSERT(!SSair.decompression_areas[feeding_area], "an area that is not decompressing spread a decompression")

/datum/unit_test/decompression_spreads_through_open_seam/proc/seam_share(drained_ratio)
	for(var/turf/open/member as anything in list(feeding, drained))
		if(member.excited_group)
			member.excited_group.garbage_collect()
		SSair.remove_from_active(member)
		member.air.copy_from_turf(member)
	drained.air.multiply(drained_ratio)
	SSair.decompression_pending[feeding_area] = SSair.times_fired - 1
	feeding.process_cell(max(SSair.times_fired, feeding.current_cycle, drained.current_cycle) + 1)

/datum/unit_test/decompression_spreads_through_open_seam/proc/reset_seam()
	for(var/area/test_area as anything in list(feeding_area, drained_area))
		SSair.decompression_areas -= test_area
		SSair.decompression_handled_at -= test_area
		SSair.decompression_pending -= test_area
		SSair.decompression_started_at -= test_area
		SSair.decompression_seen -= test_area

/datum/unit_test/decompression_spreads_through_open_seam/Destroy()
	if(feeding_area)
		reset_seam()
		for(var/turf/open/member as anything in list(feeding, drained))
			if(member.excited_group)
				member.excited_group.garbage_collect()
			SSair.remove_from_active(member)
			SSair.high_pressure_delta -= member
			member.high_pressure_queued = FALSE
			member.pressure_vector_x = 0
			member.pressure_vector_y = 0
			member.air.copy_from_turf(member)
		feeding_old_area.contents += feeding
		drained_old_area.contents += drained
	return ..()

/area/unit_test_decompression/outdoor
	outdoors = TRUE

/// Наружная зона не встаёт в декомп-очередь целиком, как и космос.
/datum/unit_test/decompression_skips_outdoor_area
	var/turf/open/spot
	var/area/old_area
	var/area/unit_test_decompression/outdoor/outdoor_area

/datum/unit_test/decompression_skips_outdoor_area/Run()
	spot = run_loc_floor_bottom_left
	old_area = get_area(spot)
	outdoor_area = new
	outdoor_area.contents += spot

	SSair.decompression_pending[outdoor_area] = SSair.times_fired - 1
	SSair.queue_decompression_area(spot)
	TEST_ASSERT(!SSair.decompression_areas[outdoor_area], "an outdoor area was queued for a whole-area decompression")

	outdoor_area.outdoors = FALSE
	SSair.queue_decompression_area(spot)
	TEST_ASSERT(SSair.decompression_areas[outdoor_area], "control: the same area without outdoors was not queued")

/datum/unit_test/decompression_skips_outdoor_area/Destroy()
	if(outdoor_area)
		SSair.decompression_areas -= outdoor_area
		SSair.decompression_handled_at -= outdoor_area
		SSair.decompression_pending -= outdoor_area
		SSair.decompression_started_at -= outdoor_area
		SSair.decompression_seen -= outdoor_area
		old_area.contents += spot
	return ..()

// Сначала изолируется повреждённый участок; общая тревога нужна при неудаче локализации.
/datum/unit_test/decompression_alarm_grace
	var/list/saved_air_state = list()
	var/list/original_areas = list()
	var/saved_count

/datum/unit_test/decompression_alarm_grace/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирована")
	for(var/state_name in list("decompression_handled_at", "decompression_pending", "decompression_areas", "decompression_started_at", "decompression_seen", "decompression_seals", "currentrun"))
		saved_air_state[state_name] = SSair.vars[state_name]
		SSair.vars[state_name] = list()
	saved_count = SSair.num_decompression_areas
	for(var/state_name in list("decompression_context", "decompression_check"))
		saved_air_state[state_name] = SSair.vars[state_name]
		SSair.vars[state_name] = null
	var/turf/open/origin = run_loc_floor_bottom_left
	var/list/turf/open/row = list()
	for(var/offset in 0 to 4)
		row += locate(origin.x + offset, origin.y + 2, origin.z)
	var/turf/open/spot = row[1]
	var/turf/open/doorway = row[3]
	var/turf/open/safe_side = row[4]
	var/turf/open/far_end = row[5]
	for(var/offset in -1 to 5)
		var/turf/north_wall = locate(origin.x + offset, spot.y + 1, spot.z)
		var/turf/south_wall = locate(origin.x + offset, spot.y - 1, spot.z)
		north_wall.ChangeTurf(/turf/closed/wall)
		south_wall.ChangeTurf(/turf/closed/wall)
	var/turf/west_end = get_step(spot, WEST)
	west_end.ChangeTurf(/turf/open/space/basic)
	var/turf/east_end = get_step(far_end, EAST)
	east_end.ChangeTurf(/turf/closed/wall)
	var/area/unit_test_decompression/base = new
	allocated += base
	for(var/turf/open/member as anything in row)
		original_areas[member] = get_area(member)
		base.contents += member
		member.ImmediateCalculateAdjacentTurfs()
	fill_breach_row(row)
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor, doorway)
	var/obj/machinery/airalarm/unit_test_decomp_probe/alarm = allocate(/obj/machinery/airalarm/unit_test_decomp_probe, safe_side)
	alarm.set_is_operational(TRUE)
	TEST_ASSERT(door in base.firedoors, "контроль: дверь не зарегистрирована в тестовом отсеке")

	SSair.queue_decompression_area(spot)
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 0, "единственный замер вызвал общую тревогу")
	SSair.decompression_pending[base] = SSair.times_fired - 1
	SSair.decompression_started_at[base] = world.time - DECOMPRESSION_AREA_ALARM_DELAY + 1
	SSair.queue_decompression_area(spot)
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 0, "общая тревога сработала до истечения задержки")
	TEST_ASSERT(door.density, "ближайший фаерлок не отсёк повреждённый участок")
	TEST_ASSERT(SSair.decompression_areas[base], "подтверждённая пробоина потеряна во время задержки")

	SSair.decompression_started_at[base] = world.time - DECOMPRESSION_AREA_ALARM_DELAY
	SSair.queue_decompression_area(spot)
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 0, "пробоина в отсечённом участке вызвала общую тревогу")
	TEST_ASSERT_EQUAL(SSair.decompression_started_at[base], world.time, "успешная локализация не сбросила задержку общей тревоги")
	// Геометрия может переиспользоваться, но потеря давления за дверью отменяет защиту.
	var/datum/decompression_context/contained_context = SSair.decompression_context
	TEST_ASSERT_NOTNULL(contained_context, "стабильная локализация не сохранила геометрию")
	safe_side.air.clear()
	TEST_ASSERT(!SSair.contain_decompression(base, list(spot), contained_context), "кэш локализации скрыл потерю давления за дверью")
	fill_breach_row(row)

	// Закрытая дверь с обходом через соседнюю зону не считается локализацией.
	var/list/bridge = list()
	for(var/offset in 1 to 3)
		var/turf/open/bypass = locate(origin.x + offset, spot.y + 1, spot.z)
		bypass = bypass.ChangeTurf(/turf/open/floor/plasteel)
		bypass.ImmediateCalculateAdjacentTurfs()
		bridge += bypass
	TEST_ASSERT(!SSair.contain_decompression(base, list(spot)), "обход закрытого фаерлока ошибочно признан локализацией")
	for(var/turf/bypass as anything in bridge)
		bypass.ChangeTurf(/turf/closed/wall)

	// При пробоинах с обеих сторон двери целой части за ней больше нет.
	east_end = get_step(far_end, EAST)
	east_end.ChangeTurf(/turf/open/space/basic)
	far_end.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(!SSair.contain_decompression(base, list(spot, far_end)), "две пробоины по разные стороны двери скрыли общую угрозу")
	east_end = get_step(far_end, EAST)
	east_end.ChangeTurf(/turf/closed/wall)

	if(door.operating)
		wait_for_var(door, "operating", FALSE)
	door.open()
	door.block_automatic_closing(FIRELOCK_MANUAL_OVERRIDE_GRACE)
	fill_breach_row(row)
	SSair.decompression_started_at[base] = world.time
	SSair.decompression_pending[base] = SSair.times_fired - 1
	SSair.queue_decompression_area(spot)
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	TEST_ASSERT(!door.density, "локализация обошла блокировку ручного открытия")
	TEST_ASSERT(SSair.decompression_areas[base], "контроль: повторная утечка не подтверждена после ожидания анимации")
	TEST_ASSERT(!SSair.contain_decompression(base, list(spot)), "открытая заблокированная дверь ошибочно признана локализацией")
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 0, "общая тревога не дала времени на повторную локализацию")

	SSair.decompression_started_at[base] = world.time - DECOMPRESSION_AREA_ALARM_DELAY
	SSair.queue_decompression_area(spot)
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 1, "неудачная локализация не вызвала общую тревогу после задержки")
	TEST_ASSERT(!(base in SSair.decompression_started_at), "обработанная пробоина сохранила время ожидания")
	SSair.queue_decompression_area(spot)
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 1, "кулдаун не подавил повторную общую тревогу")

	SSair.decompression_handled_at -= base
	SSair.queue_decompression_area(spot)
	SSair.decompression_pending[base] = SSair.times_fired - 1
	SSair.queue_decompression_area(spot)
	SSair.decompression_started_at[base] = world.time - DECOMPRESSION_AREA_ALARM_DELAY
	// Отсутствие нового газа не закрывает пустую пробоину: герметизируем сам проём.
	west_end = get_step(spot, WEST)
	west_end.ChangeTurf(/turf/closed/wall)
	spot.ImmediateCalculateAdjacentTurfs()
	SSair.decompression_seen.Cut()
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 1, "загерметизированный проём вызвал отложенную тревогу")
	TEST_ASSERT(!(base in SSair.decompression_areas), "отменённая тревога осталась в очереди")
	TEST_ASSERT(!(base in SSair.decompression_pending), "отменённая тревога осталась в подтверждении")
	TEST_ASSERT(!(base in SSair.decompression_started_at), "герметизация сохранила старый отсчёт задержки")
	west_end = get_step(spot, WEST)
	west_end.ChangeTurf(/turf/open/space/basic)
	spot.ImmediateCalculateAdjacentTurfs()
	SSair.queue_decompression_area(spot)
	TEST_ASSERT_EQUAL(SSair.decompression_started_at[base], world.time, "новая пробоина унаследовала старый отсчёт")

	// Пустая кромка всё ещё требует общей защиты, если изоляция остаётся открытой.
	spot.air.clear()
	spot.air.set_temperature(TCMB)
	SSair.decompression_started_at[base] = world.time - DECOMPRESSION_AREA_ALARM_DELAY
	SSair.decompression_pending[base] = SSair.times_fired - 1
	SSair.decompression_seen.Cut()
	spot.process_cell(max(SSair.times_fired, spot.current_cycle) + 1)
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 2, "открытая пробоина ниже порога давления потеряла общую тревогу")

/datum/unit_test/decompression_alarm_grace/Destroy()
	for(var/area/base as anything in SSair.decompression_seals.Copy())
		SSair.set_decompression_seals(base)
	for(var/turf/spot as anything in original_areas)
		var/area/original = original_areas[spot]
		original.contents += spot
	for(var/state_name in saved_air_state)
		SSair.vars[state_name] = saved_air_state[state_name]
	if(length(saved_air_state))
		SSair.num_decompression_areas = saved_count
	saved_air_state.Cut()
	original_areas.Cut()
	return ..()

// Три параллельных прохода удерживают две пробоины даже при малом перепаде у дверей.
/datum/unit_test/decompression_parallel_seals
	var/list/saved_air_state = list()
	var/list/original_areas = list()
	var/area/unit_test_decompression/base

/datum/unit_test/decompression_parallel_seals/Run()
	for(var/state_name in list("decompression_handled_at", "decompression_pending", "decompression_areas", "decompression_started_at", "decompression_seen", "decompression_seals", "currentrun"))
		saved_air_state[state_name] = SSair.vars[state_name]
		SSair.vars[state_name] = list()
	for(var/state_name in list("decompression_context", "decompression_check", "num_decompression_areas", "can_fire"))
		saved_air_state[state_name] = SSair.vars[state_name]
	SSair.decompression_context = null
	SSair.decompression_check = null
	SSair.can_fire = FALSE
	base = new
	allocated += base
	var/turf/open/origin = run_loc_floor_bottom_left
	var/list/room = list()
	for(var/dx in -1 to 3)
		for(var/dy in -1 to 5)
			var/turf/spot = locate(origin.x + dx, origin.y + dy, origin.z)
			if(dx < 0 || dx > 2 || dy < 0 || dy > 4)
				spot.ChangeTurf(/turf/closed/wall)
				continue
			var/turf/open/floor = spot.ChangeTurf(/turf/open/floor/plasteel)
			original_areas[floor] = get_area(floor)
			base.contents += floor
			floor.air.copy_from_turf(floor)
			SSair.remove_from_active(floor)
			room += floor
	var/turf/open/first_source = locate(origin.x, origin.y, origin.z)
	var/turf/open/second_source = locate(origin.x + 2, origin.y, origin.z)
	for(var/turf/open/source as anything in list(first_source, second_source))
		var/turf/hole = get_step(source, SOUTH)
		hole.ChangeTurf(/turf/open/space/basic)
	var/list/doors = list()
	for(var/dx in 0 to 2)
		var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor, locate(origin.x + dx, origin.y + 2, origin.z))
		door.machine_stat &= ~NOPOWER
		doors += door
	for(var/turf/open/member as anything in room)
		member.ImmediateCalculateAdjacentTurfs()
	SSair.decompression_areas[base] = TRUE
	SSair.decompression_started_at[base] = world.time
	SSair.decompression_seen[base] = list(first_source, second_source)
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	for(var/obj/machinery/door/firedoor/door as anything in doors)
		TEST_ASSERT(door.density && door.is_decompression_seal(), "не все параллельные проходы вошли в границу изоляции")
		if(door.operating)
			wait_for_var(door, "operating", FALSE)
		TEST_ASSERT(!door.is_holding_pressure(), "контроль: большой перепад скрыл бы ошибку таймера")
		for(var/retry in 1 to 3)
			door.try_auto_reopen()
			TEST_ASSERT(door.density && door.auto_closed && !door.operating, "таймер открыл защитный проход при сохраняющейся пробоине")
		// Снятие холодовой тревоги также не должно открывать защитную границу.
		door.alarm_type = FIRELOCK_ALARM_TYPE_COLD
	var/obj/machinery/door/firedoor/first_door = doors[1]
	first_door.recompute_atmos_alarm()
	base.ModifyFiredoors(TRUE)
	for(var/obj/machinery/door/firedoor/door as anything in doors)
		TEST_ASSERT(door.density && door.auto_closed && !door.operating, "снятие тревоги открыло защитный проход")

	// Опустевшая кромка может перестать присылать новые события физики.
	SSair.decompression_seen.Cut()
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	for(var/obj/machinery/door/firedoor/door as anything in doors)
		TEST_ASSERT(door.is_decompression_seal(), "пропуск замера снял защиту с незаделанной пробоины")

	first_door.block_automatic_closing(FIRELOCK_MANUAL_OVERRIDE_GRACE)
	first_door.open()
	SSair.decompression_seen.Cut()
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	TEST_ASSERT(!first_door.density && !first_door.can_auto_close(), "граница изоляции отменила ручное открытие на 8 секунд")
	first_door.try_to_crowbar(null, null)
	TEST_ASSERT_EQUAL(first_door.displayed_alarm_state, FIRELOCK_ALARM_TYPE_GENERIC, "ручная дверь на границе пробоины не показала местную угрозу")

	// Только реальный ремонт обеих пробоин снимает удержание; ручная дверь остаётся закрытой.
	for(var/turf/open/source as anything in list(first_source, second_source))
		var/turf/hole = get_step(source, SOUTH)
		hole.ChangeTurf(/turf/closed/wall)
		source.ImmediateCalculateAdjacentTurfs()
	SSair.decompression_seen.Cut()
	SSair.process_decompression_areas_auxtools(FALSE, 0)
	TEST_ASSERT(!(base in SSair.decompression_seals), "ремонт пробоин не снял удержание границы")
	TEST_ASSERT_NULL(first_door.displayed_alarm_state, "ремонт сохранил оверлей угрозы на ручной двери")
	for(var/obj/machinery/door/firedoor/door as anything in doors)
		TEST_ASSERT(!door.is_decompression_seal(), "ремонт сохранил ссылку на изоляцию в двери")
		if(door != first_door)
			door.try_auto_reopen()
	for(var/retry in 1 to 30)
		var/obj/machinery/door/firedoor/second_door = doors[2]
		var/obj/machinery/door/firedoor/third_door = doors[3]
		if(!second_door.density && !third_door.density)
			break
		sleep(1)
	for(var/obj/machinery/door/firedoor/door as anything in doors)
		TEST_ASSERT_EQUAL(door.density, door == first_door, "после ремонта нарушено автоматическое или ручное состояние двери")

/datum/unit_test/decompression_parallel_seals/Destroy()
	if(base && length(saved_air_state))
		SSair.set_decompression_seals(base)
	for(var/turf/spot as anything in original_areas)
		var/area/original = original_areas[spot]
		original.contents += spot
	for(var/state_name in saved_air_state)
		SSair.vars[state_name] = saved_air_state[state_name]
	return ..()

// Разбитое окно закрывает собственную шторку только при риске разгерметизации, не затрагивая удалённую дверь.
/datum/unit_test/window_breach_local_safety/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/remote = run_loc_floor_top_right
	for(var/turf/open/nearby in range(1, origin))
		nearby.air.copy_from_turf(nearby)
	var/obj/machinery/door/firedoor/window/local_door = allocate(/obj/machinery/door/firedoor/window, origin)
	local_door.machine_stat &= ~NOPOWER
	var/obj/machinery/door/firedoor/remote_door = allocate(/obj/machinery/door/firedoor, remote)
	var/obj/machinery/airalarm/unit_test_decomp_probe/alarm = allocate(/obj/machinery/airalarm/unit_test_decomp_probe, origin)
	var/obj/structure/window/window = allocate(/obj/structure/window/fulltile, origin)
	window.deconstruct(FALSE)
	TEST_ASSERT(!local_door.density, "разбитое окно внутри герметичной комнаты закрыло шторку")
	TEST_ASSERT(!remote_door.density, "окно без пробоины закрыло удалённую дверь")
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 0, "окно без пробоины вызвало общую тревогу")

	// Космос по диагонали не создаёт прямого атмосферного соединения с оконным тайлом.
	var/turf/diagonal = get_step(origin, SOUTHWEST)
	diagonal.ChangeTurf(/turf/open/space/basic)
	window = allocate(/obj/structure/window/fulltile, origin)
	window.deconstruct(FALSE)
	TEST_ASSERT(!local_door.density, "окно с космосом по диагонали закрыло шторку без перепада давления")
	TEST_ASSERT(!remote_door.density, "диагональное соседство с космосом закрыло удалённую дверь")
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 0, "диагональное соседство с космосом вызвало общую тревогу")

	// Прямой выход в космос после разрушения окна должен перекрываться немедленно.
	var/turf/outside = get_step(origin, WEST)
	outside.ChangeTurf(/turf/open/space/basic)
	TEST_ASSERT(origin.air.return_pressure() > DOOR_PRESSURE_DIFFERENCE_TOLERANCE, "для проверки пробоины нужен воздух под шторкой")
	window = allocate(/obj/structure/window/fulltile, origin)
	window.deconstruct(FALSE)
	TEST_ASSERT(local_door.density, "разбитое окно с выходом в космос не закрыло свою шторку немедленно")
	TEST_ASSERT(!remote_door.density, "локальная защита закрыла удалённую дверь")
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 0, "локальная защита вызвала общую тревогу")
	if(local_door.operating)
		wait_for_var(local_door, "operating", FALSE)
	TEST_ASSERT(!local_door.alarm_type && !local_door.generic_alarm, "контроль: общая тревога скрыла бы отсутствие местной индикации")
	TEST_ASSERT_EQUAL(local_door.alarm_overlay_state(), FIRELOCK_ALARM_TYPE_GENERIC, "защита разбитого окна не показала общую угрозу")
	var/has_threat_overlay = FALSE
	for(var/mutable_appearance/overlay as anything in local_door.overlays)
		if(overlay.icon_state == FIRELOCK_ALARM_TYPE_GENERIC)
			has_threat_overlay = TRUE
	TEST_ASSERT(has_threat_overlay, "на закрытой оконной шторке нет оверлея локальной угрозы")

// Аирбаг разбитого окна разворачивается и герметизирует турф; аккуратная разборка его не активирует.
/datum/unit_test/window_breach_airbag_safety/Run()
	var/turf/open/spot = run_loc_floor_bottom_left
	var/obj/structure/window/window = allocate(/obj/structure/window, spot)
	window.airbag_installed = TRUE
	window.deconstruct(FALSE)
	var/obj/item/airbag_module/immediate_arm/module = locate() in spot
	TEST_ASSERT_NOTNULL(module, "разбитое окно не выпустило аирбаг")
	allocated += module
	TEST_ASSERT(module.armed, "аирбаг разбитого окна не активирован")
	TEST_ASSERT(module.detonate_time < DECOMPRESSION_AREA_ALARM_DELAY, "аирбаг не успевает развернуться до общей тревоги")
	var/obj/structure/inflatable/airbag/barrier = module.bang()
	TEST_ASSERT_NOTNULL(barrier, "аирбаг не развернул мембрану")
	allocated += barrier
	spot.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(!length(spot.atmos_adjacent_turfs), "мембрана аирбага пропускает воздух")
	qdel(barrier)

	var/obj/structure/window/disassembled = allocate(/obj/structure/window, spot)
	disassembled.airbag_installed = TRUE
	var/obj/machinery/door/firedoor/window/door = allocate(/obj/machinery/door/firedoor/window, spot)
	disassembled.deconstruct(TRUE)
	TEST_ASSERT(!(locate(/obj/item/airbag_module/immediate_arm) in spot), "аккуратная разборка активировала аирбаг")
	TEST_ASSERT(!door.density, "аккуратная разборка закрыла файрлок")

#undef TEST_BREACH_MOLES
#undef TEST_BREACH_LEAN_MOLES
#undef TEST_BREACH_RICH_MOLES
#undef TEST_BREACH_LOW_PRESSURE_RATIO
#undef TEST_BREACH_SAFE_PRESSURE_RATIO
#undef TEST_BREACH_EPSILON
