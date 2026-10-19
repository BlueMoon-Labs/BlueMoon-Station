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

// Общая тревога ждёт локальную защиту, отменяется после герметизации и сохраняется для открытой пробоины.
/datum/unit_test/decompression_alarm_grace
	var/list/saved_air_state = list()
	var/list/original_areas = list()
	var/saved_count

/datum/unit_test/decompression_alarm_grace/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирована")
	for(var/state_name in list("decompression_handled_at", "decompression_pending", "decompression_areas", "decompression_started_at", "decompression_seen", "currentrun"))
		saved_air_state[state_name] = SSair.vars[state_name]
		SSair.vars[state_name] = list()
	saved_count = SSair.num_decompression_areas
	var/turf/open/spot = run_loc_floor_bottom_left
	var/area/unit_test_decompression/base = new
	allocated += base
	original_areas[spot] = get_area(spot)
	base.contents += spot
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor, spot)
	var/obj/machinery/airalarm/unit_test_decomp_probe/alarm = allocate(/obj/machinery/airalarm/unit_test_decomp_probe, spot)
	alarm.set_is_operational(TRUE)
	TEST_ASSERT(door in base.firedoors, "контроль: дверь не зарегистрирована в тестовом отсеке")

	SSair.queue_decompression_area(spot)
	SSair.process_decompression_areas_auxtools(FALSE)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 0, "единственный замер вызвал общую тревогу")
	SSair.decompression_pending[base] = SSair.times_fired - 1
	SSair.decompression_started_at[base] = world.time - DECOMPRESSION_AREA_ALARM_DELAY + 1
	SSair.queue_decompression_area(spot)
	SSair.process_decompression_areas_auxtools(FALSE)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 0, "общая тревога сработала до истечения задержки")
	TEST_ASSERT(!door.density, "дверь отсека закрылась до истечения задержки")
	TEST_ASSERT(SSair.decompression_areas[base], "подтверждённая пробоина потеряна во время задержки")

	SSair.decompression_started_at[base] = world.time - DECOMPRESSION_AREA_ALARM_DELAY
	SSair.queue_decompression_area(spot)
	SSair.process_decompression_areas_auxtools(FALSE)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 1, "постоянная пробоина не подняла тревогу на границе задержки")
	TEST_ASSERT(door.density, "общая тревога не закрыла дверь отсека")
	TEST_ASSERT(!(base in SSair.decompression_started_at), "обработанная пробоина сохранила время ожидания")
	SSair.queue_decompression_area(spot)
	SSair.process_decompression_areas_auxtools(FALSE)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 1, "кулдаун не подавил повторную общую тревогу")

	SSair.decompression_handled_at -= base
	SSair.queue_decompression_area(spot)
	SSair.decompression_pending[base] = SSair.times_fired - 1
	SSair.queue_decompression_area(spot)
	SSair.decompression_started_at[base] = world.time - DECOMPRESSION_AREA_ALARM_DELAY
	// Полный проход без новой утечки соответствует уже загерметизированному проёму.
	SSair.decompression_seen.Cut()
	SSair.process_decompression_areas_auxtools(FALSE)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 1, "загерметизированный проём вызвал отложенную тревогу")
	TEST_ASSERT(!(base in SSair.decompression_areas), "отменённая тревога осталась в очереди")
	TEST_ASSERT(!(base in SSair.decompression_pending), "отменённая тревога осталась в подтверждении")
	TEST_ASSERT(!(base in SSair.decompression_started_at), "герметизация сохранила старый отсчёт задержки")
	SSair.queue_decompression_area(spot)
	TEST_ASSERT_EQUAL(SSair.decompression_started_at[base], world.time, "новая пробоина унаследовала старый отсчёт")

	// Пустой карман с открытым выходом в космос продолжает подтверждать уже замеченную пробоину.
	var/turf/open/drained = locate(spot.x + 3, spot.y + 2, spot.z)
	original_areas[drained] = get_area(drained)
	base.contents += drained
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(drained, direction)
		neighbor.ChangeTurf(direction == WEST ? /turf/open/space/basic : /turf/closed/wall)
	drained.ImmediateCalculateAdjacentTurfs()
	drained.air.clear()
	drained.air.set_temperature(TCMB)
	SSair.decompression_started_at[base] = world.time - DECOMPRESSION_AREA_ALARM_DELAY
	SSair.decompression_pending[base] = SSair.times_fired - 1
	SSair.decompression_seen.Cut()
	drained.process_cell(max(SSair.times_fired, drained.current_cycle) + 1)
	SSair.process_decompression_areas_auxtools(FALSE)
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 2, "открытая пробоина ниже порога давления потеряла общую тревогу")

/datum/unit_test/decompression_alarm_grace/Destroy()
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

// Разбитое окно немедленно закрывает собственный файрлок, не затрагивая удалённый.
/datum/unit_test/window_breach_local_safety/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/remote = run_loc_floor_top_right
	var/obj/machinery/door/firedoor/window/local_door = allocate(/obj/machinery/door/firedoor/window, origin)
	var/obj/machinery/door/firedoor/remote_door = allocate(/obj/machinery/door/firedoor, remote)
	var/obj/machinery/airalarm/unit_test_decomp_probe/alarm = allocate(/obj/machinery/airalarm/unit_test_decomp_probe, origin)
	var/obj/structure/window/window = allocate(/obj/structure/window, origin)
	window.deconstruct(FALSE)
	TEST_ASSERT(local_door.density, "разбитое окно не закрыло свой файрлок немедленно")
	TEST_ASSERT(!remote_door.density, "локальная защита закрыла удалённую дверь")
	TEST_ASSERT_EQUAL(alarm.decomp_calls, 0, "локальная защита вызвала общую тревогу")

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
