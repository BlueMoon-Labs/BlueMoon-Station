// Regression tests for the atmos/engineering branch: omni device gas
// conservation and ratio control, turf exposure listener lifecycle across
// ChangeTurf, firelock alarm hygiene, clothing examine integrity, plasma
// contamination behavior, fire alarm hot-air detection, decompression alarm
// cooldown and fan safety clutch idling.

/// A blocked filter port must not duplicate gas: whatever parks in the
/// rejected buffer has to leave it again when it returns to the input.
/datum/unit_test/atmos_omni_filter_conservation/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/obj/machinery/atmospherics/components/quaternary/omni_filter/filter = allocate(/obj/machinery/atmospherics/components/quaternary/omni_filter)
	filter.machine_stat = NONE
	filter.is_operational = TRUE
	filter.on = TRUE
	// process_atmos only checks node presence, not what the node is; fake the
	// connections so every port participates without building pipenets.
	for(var/i in 1 to QUATERNARY)
		filter.nodes[i] = filter

	var/datum/gas_mixture/input_air = filter.airs[1]
	input_air.set_moles(GAS_O2, 20)
	input_air.set_moles(GAS_PLASMA, 20)
	input_air.set_temperature(T20C)

	var/filter_index = filter.port_roles.Find("filter")
	TEST_ASSERT(filter_index, "default omni filter layout lost its filter port")
	var/datum/gas_mixture/filter_air = filter.airs[filter_index]
	var/filter_volume = filter_air.return_volume()
	TEST_ASSERT(filter_volume > 0, "filter port air has no volume")
	// Pin the filtered line above MAX_OUTPUT_PRESSURE so scrubbed plasma is
	// diverted into rejected_air every cycle.
	filter_air.set_moles(GAS_N2, MAX_OUTPUT_PRESSURE * filter_volume / (R_IDEAL_GAS_EQUATION * T20C) * 2)
	filter_air.set_temperature(T20C)

	var/total_before = filter.rejected_air.total_moles()
	for(var/i in 1 to QUATERNARY)
		total_before += filter.airs[i].total_moles()

	for(var/cycle in 1 to 3)
		filter.atmos_idle_until = 0
		filter.process_atmos()

	var/total_after = filter.rejected_air.total_moles()
	for(var/i in 1 to QUATERNARY)
		total_after += filter.airs[i].total_moles()

	// The fake nodes have no pipenets; drop the rebuild request update_parents queued.
	SSair.pipenets_needing_rebuilt -= filter
	filter.rebuild_queued = FALSE
	for(var/i in 1 to QUATERNARY)
		filter.nodes[i] = null

	TEST_ASSERT(abs(total_after - total_before) < 0.01, "omni filter created or destroyed gas: [total_before] mol became [total_after] mol")

/// The mixer concentration slider must actually apply the requested share.
/datum/unit_test/atmos_omni_mixer_ratio/Run()
	var/obj/machinery/atmospherics/components/quaternary/omni_mixer/mixer = allocate(/obj/machinery/atmospherics/components/quaternary/omni_mixer)
	mixer.normalize_inputs(2, 0.6)
	TEST_ASSERT(abs(mixer.concentrations[2] - 0.6) < 0.001, "preferred input concentration was not applied: got [mixer.concentrations[2]] instead of 0.6")
	TEST_ASSERT(abs(mixer.concentrations[1] - 0.2) < 0.001, "remaining input 1 did not split the remainder evenly: [mixer.concentrations[1]]")
	TEST_ASSERT(abs(mixer.concentrations[3] - 0.2) < 0.001, "remaining input 3 did not split the remainder evenly: [mixer.concentrations[3]]")

/// Restores standard air on a tile and its open cardinal neighbours. The unit
/// test zone is shared and earlier atmos tests leave vented or chilled tiles.
/proc/unit_test_normalize_exposure_window(turf/open/center)
	if(!istype(center))
		return
	if(center.air)
		center.air.copy_from_turf(center)
	for(var/direction in GLOB.cardinals)
		var/turf/open/neighbour = get_step(center, direction)
		if(istype(neighbour) && !isspaceturf(neighbour) && neighbour.air)
			neighbour.air.copy_from_turf(neighbour)

/// Counter probe for exposure registration tests.
/datum/unit_test_exposure_probe
	var/hits = 0

/datum/unit_test_exposure_probe/proc/on_exposure(turf/source, datum/gas_mixture/exposed_air, exposed_temperature)
	SIGNAL_HANDLER
	hits++

/// Exposure listeners must survive the watched turf being rebuilt: ChangeTurf
/// replaces the turf datum, and both the signal registration and the gate the
/// SSair hot path reads have to carry over to the replacement.
/datum/unit_test/atmos_exposure_changeturf/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/spot = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT(istype(spot), "test location is not an open turf")
	var/original_type = spot.type
	var/datum/unit_test_exposure_probe/probe = new

	probe.register_turf_exposure(spot, TYPE_PROC_REF(/datum/unit_test_exposure_probe, on_exposure))
	SEND_SIGNAL(spot, COMSIG_TURF_EXPOSE, spot.air, T20C)
	TEST_ASSERT_EQUAL(probe.hits, 1, "freshly registered probe did not receive the exposure signal")

	var/turf/open/rebuilt = spot.ChangeTurf(/turf/open/floor/plating)
	TEST_ASSERT(istype(rebuilt), "ChangeTurf did not return the replacement turf")
	TEST_ASSERT(islist(rebuilt.atmos_exposure_listeners) && rebuilt.atmos_exposure_listeners[probe], "exposure registration was lost across ChangeTurf")
	SEND_SIGNAL(rebuilt, COMSIG_TURF_EXPOSE, rebuilt.air, T20C)
	TEST_ASSERT_EQUAL(probe.hits, 2, "exposure signal did not reach the probe after ChangeTurf")

	probe.unregister_turf_exposure(rebuilt)
	TEST_ASSERT(!LAZYLEN(rebuilt.atmos_exposure_listeners), "unregister left a stale exposure client on the turf")
	SEND_SIGNAL(rebuilt, COMSIG_TURF_EXPOSE, rebuilt.air, T20C)
	TEST_ASSERT_EQUAL(probe.hits, 2, "probe still receives exposure after unregistering")

	rebuilt.ChangeTurf(original_type)
	qdel(probe)

/// Unregistering must be exact: a listener that never registered on a turf
/// cannot steal another listener's registration by unregistering there.
/datum/unit_test/atmos_exposure_exact_unregister/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/spot = locate(origin.x + 2, origin.y + 1, origin.z)
	TEST_ASSERT(istype(spot), "test location is not an open turf")
	var/datum/unit_test_exposure_probe/owner = new
	var/datum/unit_test_exposure_probe/stranger = new

	owner.register_turf_exposure(spot, TYPE_PROC_REF(/datum/unit_test_exposure_probe, on_exposure))
	stranger.unregister_turf_exposure(spot)
	// This is the exact gate process_cell reads before sending COMSIG_TURF_EXPOSE:
	// a stranger's unregister must not zero it while the owner is registered.
	TEST_ASSERT(spot.atmos_exposure_listeners, "a stranger's unregister cleared the turf exposure gate while the owner was still registered")
	SEND_SIGNAL(spot, COMSIG_TURF_EXPOSE, spot.air, T20C)
	TEST_ASSERT_EQUAL(owner.hits, 1, "a stranger's unregister killed the owner's exposure registration")

	owner.unregister_turf_exposure(spot)
	TEST_ASSERT(!LAZYLEN(spot.atmos_exposure_listeners), "cleanup left exposure clients on the turf")
	qdel(owner)
	qdel(stranger)

/// A merger refresh must rebuild the shared issue map from live members only:
/// entries contributed by doors that left the group (or turfs nobody watches
/// anymore) may not survive and latch the group alarm forever.
/datum/unit_test/firedoor_stale_alarm_cleanup/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor)
	// Earlier atmos tests share this zone and can leave chilled or vented
	// tiles; reset the door's watch window so the rescan sees standard air.
	unit_test_normalize_exposure_window(origin)
	var/turf/open/far_turf = locate(origin.x + 4, origin.y + 4, origin.z)
	TEST_ASSERT(istype(far_turf), "no far turf available for the stale entry")

	if(!door.issue_turfs)
		door.issue_turfs = list()
	door.issue_turfs[far_turf] = FIRELOCK_ALARM_TYPE_HOT
	door.alarm_type = FIRELOCK_ALARM_TYPE_HOT

	var/datum/merger/group = door.GetMergeGroup(door.merger_id, door.merger_typecache)
	TEST_ASSERT_NOTNULL(group, "firedoor has no merger group")
	group.Refresh()

	TEST_ASSERT(!door.issue_turfs[far_turf], "merger refresh kept a stale issue turf no member watches")
	if(door.alarm_type)
		var/list/details = list()
		for(var/turf/problem as anything in door.issue_turfs)
			details += "[problem.type] at ([problem.x],[problem.y]) T=[problem.return_temperature()] -> [door.issue_turfs[problem]]"
		TEST_FAIL("group alarm stayed [door.alarm_type]; live issue turfs: [details.len ? details.Join("; ") : "none"]")

/// The sensor knows why it shut the door - hot, cold or a neighbour's generic
/// alarm - but until now a closed firelock told the crew nothing. These pin the
/// lamp decision (the icon states themselves are ported sprites, so a typo in
/// the defines would silently render nothing at all).
/datum/unit_test/firedoor_alarm_lamps/Run()
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor)
	// The test zone has no APC, so the door lands unpowered: power it by hand,
	// otherwise every lamp assertion below would pass for the wrong reason.
	door.machine_stat &= ~NOPOWER
	TEST_ASSERT_NULL(door.alarm_overlay_state(), "a firelock with no alarm lit a lamp")

	door.alarm_type = FIRELOCK_ALARM_TYPE_HOT
	TEST_ASSERT_EQUAL(door.alarm_overlay_state(), FIRELOCK_ALARM_TYPE_HOT, "a heat alarm did not light the heat lamp")

	// Lamps are powered indicators: a firelock shut by a breach that also killed
	// the APC must not keep glowing.
	door.machine_stat |= NOPOWER
	TEST_ASSERT_NULL(door.alarm_overlay_state(), "an unpowered firelock lit its lamps")
	door.machine_stat &= ~NOPOWER

	door.alarm_type = FIRELOCK_ALARM_TYPE_COLD
	TEST_ASSERT_EQUAL(door.alarm_overlay_state(), FIRELOCK_ALARM_TYPE_COLD, "a cold alarm did not light the cold lamp")

	var/list/available_states = icon_states(door.icon)
	for(var/state in list(FIRELOCK_ALARM_TYPE_HOT, FIRELOCK_ALARM_TYPE_COLD, FIRELOCK_ALARM_TYPE_GENERIC))
		TEST_ASSERT(state in available_states, "[door.icon] has no icon state named [state]")

	door.alarm_type = null
	TEST_ASSERT_NULL(door.alarm_overlay_state(), "clearing the alarm left the lamps on")

/// Хвостовой модульный блок файрлока переопределял процы, уже объявленные выше
/// на том же типе. BYOND компилирует это молча и оставляет последнее
/// определение, поэтому живыми оказывались заглушки: осмотр без строки датчика
/// и открытие ломом без грейс-периода. Тест держит оба блока сведёнными.
/datum/unit_test/firedoor_merged_overrides/Run()
	var/mob/living/carbon/human/observer = allocate(/mob/living/carbon/human)
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor)
	unit_test_normalize_exposure_window(run_loc_floor_bottom_left)

	door.alarm_type = FIRELOCK_ALARM_TYPE_HOT
	var/list/examine_lines = door.examine(observer)
	var/examine_text = examine_lines.Join("\n")
	TEST_ASSERT(findtext(examine_text, "Атмосферный датчик"), "осмотр файрлока потерял строку атмосферного датчика: [examine_text]")
	TEST_ASSERT(findtext(examine_text, "manual override"), "осмотр файрлока потерял строку ручного открытия: [examine_text]")
	door.alarm_type = null

	// Открытие ломом обязано взводить грейс, иначе следующая же тревога
	// захлопывает дверь обратно перед носом у того, кто её открыл.
	door.density = TRUE
	door.emergency_close_timer = 0
	door.try_to_crowbar(null, observer)
	TEST_ASSERT(door.emergency_close_timer > world.time, "открытие ломом не взвело грейс-период")
	TEST_ASSERT(!door.density, "открытие ломом не открыло дверь")

	door.emergency_pressure_stop()
	TEST_ASSERT(!door.density, "тревога захлопнула дверь внутри грейс-периода")

	door.emergency_close_timer = 0
	door.emergency_pressure_stop()
	TEST_ASSERT(door.density, "истёкший грейс не дал тревоге закрыть дверь")

/// Перепад считался в молях, а моль зависит от температуры: горячая комната при
/// том же давлении содержит их заметно меньше. Закрывшийся по жару файрлок
/// рапортовал разгерметизацию там, где давление с обеих сторон было одинаковым.
/datum/unit_test/firedoor_pressure_check_ignores_temperature/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	// Дверь берём створчатую и ставим в ЦЕНТР резервации. Створка с ON_BORDER_1
	// смотрит ровно на одного соседа - того, что по её dir, - поэтому проверка не
	// зависит ни от края резервации (у угловой плитки соседи снаружи - вакуум),
	// ни от того, что оставили после себя соседние атмос-тесты.
	var/turf/open/center = locate(origin.x + 2, origin.y + 2, origin.z)
	var/turf/open/neighbour = locate(origin.x + 3, origin.y + 2, origin.z)
	TEST_ASSERT(istype(center) && center.air, "центральная плитка резервации не открытый турф с воздухом")
	TEST_ASSERT(istype(neighbour) && neighbour.air, "у центральной плитки нет открытого соседа с воздухом")
	center.air.copy_from_turf(center)
	neighbour.air.copy_from_turf(neighbour)

	var/obj/machinery/door/firedoor/border_only/door = allocate(/obj/machinery/door/firedoor/border_only, center)
	door.setDir(EAST)
	door.density = TRUE

	TEST_ASSERT(!door.is_holding_pressure(), "створка между двумя одинаковыми плитками решила, что удерживает давление")

	// Тот же газ, та же нагрузка на стенки, но горячий: давление выставляем
	// ровно прежнее, а молей при этом становится сильно меньше.
	var/datum/gas_mixture/neighbour_air = neighbour.air
	var/reference_pressure = center.air.return_pressure()
	TEST_ASSERT(reference_pressure > 0, "предпосылка: под дверью должен быть воздух")
	var/hot_temperature = 500
	neighbour_air.clear()
	neighbour_air.set_temperature(hot_temperature)
	neighbour_air.set_moles(GAS_N2, reference_pressure * neighbour_air.return_volume() / (R_IDEAL_GAS_EQUATION * hot_temperature))
	TEST_ASSERT(abs(neighbour_air.return_pressure() - reference_pressure) < 0.1, "не удалось выставить соседу то же давление: [neighbour_air.return_pressure()] против [reference_pressure]")

	// Без этой проверки тест перестанет ловить регресс: сетап обязан быть таким,
	// на котором прежний порог в 20 молей срабатывал.
	var/mole_gap = abs(center.air.total_moles() - neighbour_air.total_moles())
	TEST_ASSERT(mole_gap > 20, "сетап не воспроизводит ложное срабатывание: разница молей всего [mole_gap]")
	TEST_ASSERT(!door.is_holding_pressure(), "равное давление при разной температуре снова прочиталось как перепад")

	// Настоящую разгерметизацию проверка обязана видеть по-прежнему.
	neighbour_air.clear()
	TEST_ASSERT(door.is_holding_pressure(), "вакуум за дверью не прочитался как перепад давления")

	// Предупреждение больше не блокирует: раньше путь уходил в do_after, а тот
	// отказывает на пустом пользователе и дверь оставалась закрытой.
	door.emergency_close_timer = 0
	door.try_to_crowbar(null, null)
	TEST_ASSERT(!door.density, "вскрытие ломом на перепаде давления не открыло дверь")

	neighbour.air.copy_from_turf(neighbour)
	unit_test_normalize_exposure_window(center)

/// Плитка под дверью может стать закрытой: стену строят поверх содержимого
/// турфа, её же оставляют культ и перенос шаттла. Безусловный каст loc в
/// /turf/open падал рантаймом, а упавший проц возвращает null - дверь молча
/// считалась не удерживающей ничего и открывалась в разгерметизацию.
/datum/unit_test/firedoor_pressure_check_survives_closed_turf/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/original_type = origin.type
	unit_test_normalize_exposure_window(origin)
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor)
	door.density = TRUE

	var/turf/walled = origin.ChangeTurf(/turf/closed/wall)
	TEST_ASSERT(isclosedturf(walled), "плитка двери не стала закрытой: [walled?.type]")
	TEST_ASSERT_EQUAL(door.loc, walled, "дверь не осталась на перестроенной плитке")

	TEST_ASSERT(!door.is_holding_pressure(), "дверь на закрытой плитке не отчиталась о нулевом перепаде")
	TEST_ASSERT(door.density, "проверка давления оставила дверь проходимой")

	walled.ChangeTurf(original_type)

/// Один порог на вход и на выход заставлял турф у кромки пожара щёлкать
/// тревогой по нескольку раз в секунду, а каждый щелчок стоит перерисовки ламп
/// всей группы и хлопка дверью. Тревога держится до выхода за полосу возврата.
/datum/unit_test/firedoor_alarm_hysteresis/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor)
	unit_test_normalize_exposure_window(origin)
	door.generic_alarm = FALSE

	door.process_atmos_alarm(origin, origin.air, ATMOS_HEAT_ALARM_TEMPERATURE + 1)
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_HOT, "горячий турф не поднял тревогу")
	door.process_atmos_alarm(origin, origin.air, ATMOS_HEAT_ALARM_TEMPERATURE - (FIRELOCK_ALARM_TEMPERATURE_HYSTERESIS * 0.5))
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_HOT, "тревога о нагреве снялась внутри полосы возврата")
	door.process_atmos_alarm(origin, origin.air, ATMOS_HEAT_ALARM_TEMPERATURE - FIRELOCK_ALARM_TEMPERATURE_HYSTERESIS - 1)
	TEST_ASSERT_NULL(door.alarm_type, "тревога о нагреве не снялась за полосой возврата")

	// Порог холодной лампы считается от проекта самой комнаты, так что берём
	// его через тот же прок, что и живой код: у обычного турфа это общий порог.
	var/cold_limit = door.cold_alarm_limit(origin)
	door.process_atmos_alarm(origin, origin.air, cold_limit - 1)
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_COLD, "холодный турф не поднял тревогу")
	door.process_atmos_alarm(origin, origin.air, cold_limit + (FIRELOCK_ALARM_TEMPERATURE_HYSTERESIS * 0.5))
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_COLD, "тревога о холоде снялась внутри полосы возврата")
	door.process_atmos_alarm(origin, origin.air, cold_limit + FIRELOCK_ALARM_TEMPERATURE_HYSTERESIS + 1)
	TEST_ASSERT_NULL(door.alarm_type, "тревога о холоде не снялась за полосой возврата")

/// Комната, спроектированная горячей, не должна захлопывать свои створки на
/// каждом розжиге: порог тревоги её рабочую температуру не догоняет и близко, а
/// пожарных сигнализаций, чей провод детекции можно было бы перерезать, в зоне
/// сжигателя нет ни одной.
/datum/unit_test/firelock_heat_exempt_area/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor)
	unit_test_normalize_exposure_window(origin)
	door.generic_alarm = FALSE

	// Предпосылка: без флага тот же самый турф тревогу поднимает. Без неё тест
	// прошёл бы вхолостую, если бы тревога перестала подниматься вообще.
	door.process_atmos_alarm(origin, origin.air, ATMOS_HEAT_ALARM_TEMPERATURE + 1)
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_HOT, "горячий турф обязан поднимать тревогу, пока зона не освобождена")

	var/area/test_area = origin.loc
	TEST_ASSERT(isarea(test_area), "у тестового турфа нет зоны")
	var/saved_exempt = test_area.firelock_heat_exempt
	test_area.firelock_heat_exempt = TRUE
	door.process_atmos_alarm(origin, origin.air, ATMOS_HEAT_ALARM_TEMPERATURE + 1)
	TEST_ASSERT_NULL(door.alarm_type, "жар в комнате, которой положено быть горячей, всё равно поднял тревогу")
	test_area.firelock_heat_exempt = saved_exempt

	var/area/incinerator_type = /area/maintenance/disposal/incinerator
	TEST_ASSERT(initial(incinerator_type.firelock_heat_exempt), "зона сжигателя потеряла освобождение от тепловой тревоги")

/// Кэш "зона горит" (generic_alarm) обновляется только обходом area.firedoors по
/// фронту тревоги. Дверь, покинувшая зону с непогашенной тревогой (перелёт
/// шаттла, forceMove), из этого списка выпадает, и без перевывода на пересборке
/// журнала она уносит TRUE с собой: GENERIC печатает её новую merger-группу
/// навсегда - шаттеры шаттла стоят закрытыми до конца смены (VV-дамп с прода:
/// alarm_type=generic, auto_closed=1, тревоги вокруг нет).
/datum/unit_test/firedoor_move_clears_stale_generic_alarm/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor)
	unit_test_normalize_exposure_window(origin)
	door.generic_alarm = FALSE

	var/area/base = get_base_area(door)
	TEST_ASSERT(isarea(base), "у тестовой двери нет базовой зоны")
	var/saved_fire = base.fire

	// Тревога зоны доезжает до двери ровно этим путём (ModifyFiredoors ->
	// refresh_generic_alarm), зону целиком не дёргаем - она общая на все тесты.
	base.fire = TRUE
	door.refresh_generic_alarm()
	var/alarm_while_burning = door.alarm_type
	var/generic_while_burning = door.generic_alarm

	// Зона "осталась позади": у текущих affecting_areas тревоги больше нет, а
	// снять кэш обходом area.firedoors уже некому - дверь из списка выпала.
	base.fire = FALSE
	door.rebuild_alarm_ledger()
	var/alarm_after_move = door.alarm_type
	var/generic_after_move = door.generic_alarm
	base.fire = saved_fire

	TEST_ASSERT(generic_while_burning, "предпосылка: тревога зоны не взвела generic_alarm")
	TEST_ASSERT_EQUAL(alarm_while_burning, FIRELOCK_ALARM_TYPE_GENERIC, "предпосылка: тревога зоны не защёлкнула GENERIC на группе")
	TEST_ASSERT(!generic_after_move, "пересборка журнала не перевывела generic_alarm из новых зон - улетевшая дверь унесла тревогу с собой")
	TEST_ASSERT(alarm_after_move != FIRELOCK_ALARM_TYPE_GENERIC, "GENERIC пережил пересборку журнала в зоне без тревоги")

/// Одноразовый пшик разгерметизации - цикл наружного шлюза, мгновенно осушенный
/// карман - не пробоина: настоящая утечка перевзводит зону каждый фаер, пока
/// комнату кормят соседи. Без гейта подтверждения каждый выход в скафандре
/// поднимал полновесную пожарную тревогу базового ареала (сирена, файрлоки
/// каждые 10 секунд), которую никто не сбрасывает автоматически.
/datum/unit_test/decompression_alarm_needs_confirmation/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/area/base = get_base_area(origin)
	TEST_ASSERT(isarea(base), "у тестового турфа нет базовой зоны")
	SSair.decompression_areas -= base
	SSair.decompression_handled_at -= base
	SSair.decompression_pending -= base

	SSair.queue_decompression_base(base)
	TEST_ASSERT(!(base in SSair.decompression_areas), "первый же замеченный фаер поставил зону в очередь тревоги без подтверждения")
	TEST_ASSERT_EQUAL(SSair.decompression_pending[base], SSair.times_fired, "первый замер не записался в ожидающие")

	// Повтор в том же фаере - это соседние турфы того же прохода, не перевзвод.
	SSair.queue_decompression_base(base)
	TEST_ASSERT(!(base in SSair.decompression_areas), "повтор в том же фаере сошёл за подтверждение")

	// Перевзвод более поздним фаером - настоящая пробоина продолжает травить.
	SSair.decompression_pending[base] = SSair.times_fired - 1
	SSair.queue_decompression_base(base)
	TEST_ASSERT(base in SSair.decompression_areas, "перевзвод следующим фаером не поставил зону в очередь тревоги")
	TEST_ASSERT(!(base in SSair.decompression_pending), "подтверждённая зона осталась в ожидающих")

	// Протухший первый замер не подтверждает: два несвязанных пшика с разницей
	// в окно - это два первых замера, а не пробоина.
	SSair.decompression_areas -= base
	SSair.decompression_pending[base] = SSair.times_fired - DECOMPRESSION_PENDING_WINDOW_FIRES - 1
	SSair.queue_decompression_base(base)
	TEST_ASSERT(!(base in SSair.decompression_areas), "пшик за пределами окна сошёл за подтверждение")
	TEST_ASSERT_EQUAL(SSair.decompression_pending[base], SSair.times_fired, "протухший замер не перезаписался текущим фаером")

	SSair.decompression_pending -= base
	SSair.decompression_areas -= base

/// Дверь, закрытую мимо системы тревог (пожарная тревога зоны, разгерметизация,
/// whack_a_mole), открыть было некому: recompute_atmos_alarm() выходит по
/// равенству старой и новой тревоги, а у такого закрытия фронта нет вовсе -
/// журнал как был пустым, так и остался. В проде это давало створки, стоящие
/// закрытыми до конца смены при пустом issue_turfs и погашенной лампе.
/datum/unit_test/firelock_silent_close_reopens/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	// Центр резервации: у краевой плитки за границей вакуум, и дверь честно
	// сочла бы, что удерживает перепад давления.
	var/turf/open/center = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT(istype(center) && center.air, "центральная плитка резервации не открытый турф с воздухом")
	unit_test_normalize_exposure_window(center)
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor, center)

	// Ровно то состояние, что снято с прода: закрыта, тревоги нет, журнал пуст.
	door.density = TRUE
	door.alarm_type = null
	door.generic_alarm = FALSE
	door.issue_turfs = list()
	door.mark_auto_closed()
	TEST_ASSERT(!door.is_holding_pressure(), "предпосылка: под дверью не должно быть перепада давления")

	// Предпосылка регресса: штатный пересчёт такую дверь не открывает.
	door.recompute_atmos_alarm()
	TEST_ASSERT(door.density, "предпосылка теста не воспроизводится: пересчёт по фронту уже открыл дверь")

	door.try_auto_reopen()
	// Открытие асинхронное (колбек SStimer не спит анимацию двери), поэтому
	// результата дожидаемся, а не читаем сразу.
	for(var/i in 1 to 30)
		if(!door.density)
			break
		sleep(1)
	TEST_ASSERT(!door.density, "закрытая автоматикой дверь без единой причины стоять закрытой так и не открылась")
	TEST_ASSERT(!door.auto_closed, "флаг автоматического закрытия не снялся после открытия")

	// Закрытую руками автоматика открывать не имеет права.
	door.density = TRUE
	door.auto_closed = FALSE
	door.try_auto_reopen()
	TEST_ASSERT(door.density, "автоматика открыла дверь, которую закрыл человек")

	// Пока причина держится - дверь стоит закрытой.
	door.mark_auto_closed()
	door.alarm_type = FIRELOCK_ALARM_TYPE_HOT
	door.try_auto_reopen()
	TEST_ASSERT(door.density, "дверь открылась при живой тревоге по жару")
	TEST_ASSERT(door.auto_closed, "живая тревога сняла флаг автоматического закрытия")
	door.alarm_type = null
	door.auto_closed = FALSE

/// Таймерный колбек переоткрытия обязан возвращаться без сна: door/open() спит
/// анимацию целую секунду, и в раунде 9911 try_auto_reopen держал SStimer по
/// 300-350мс на колбек в разгар станционного пожара.
/datum/unit_test/firelock_auto_reopen_nonblocking/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/center = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT(istype(center) && center.air, "центральная плитка резервации не открытый турф с воздухом")
	unit_test_normalize_exposure_window(center)
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor, center)

	door.density = TRUE
	door.alarm_type = null
	door.generic_alarm = FALSE
	door.issue_turfs = list()
	door.mark_auto_closed()
	TEST_ASSERT(!door.is_holding_pressure(), "предпосылка: под дверью не должно быть перепада давления")

	var/time_before = world.time
	door.try_auto_reopen()
	TEST_ASSERT_EQUAL(world.time, time_before, "try_auto_reopen уснул в колбеке: SStimer стоял бы всю анимацию двери")
	for(var/i in 1 to 30)
		if(!door.density)
			break
		sleep(1)
	TEST_ASSERT(!door.density, "асинхронное открытие так и не открыло дверь")
	TEST_ASSERT(!door.auto_closed, "флаг автозакрытия не снялся после асинхронного открытия")

/// Чистый холодный QCD: у смеси нулевая энергия, цикл досыпки газов не
/// выполняется ни разу, и финальный set_temperature делил на нулевую
/// теплоёмкость пустой смеси. В раунде 9911 это 208 рантаймов на одном
/// вакуумном полу токсинов - реакция ни разу не завершилась.
/datum/unit_test/dehagedorn_zero_energy_no_runtime/Run()
	var/datum/gas_reaction/dehagedorn/reaction = new
	var/datum/gas_mixture/cold_qcd = new(CELL_VOLUME)
	cold_qcd.set_moles(GAS_QCD, 5)
	// Прямая запись: штатный set_temperature клампит к TCMB, а смесь с нулевой
	// температурой в проде существует - именно она и ловила деление на ноль.
	cold_qcd.temperature = 0
	reaction.react(cold_qcd, null)
	TEST_ASSERT_EQUAL(cold_qcd.get_moles(GAS_QCD), 0, "холодная конденсация не выжгла QCD")
	TEST_ASSERT(cold_qcd.return_temperature() >= TCMB, "реакция оборвалась, не дойдя до финальной температуры: [cold_qcd.return_temperature()] K")

	// Горячий путь обязан по-прежнему разложить энергию в газовый суп.
	var/datum/gas_mixture/hot_qcd = new(CELL_VOLUME)
	hot_qcd.set_moles(GAS_QCD, 100)
	hot_qcd.set_temperature(1e12)
	reaction.react(hot_qcd, null)
	TEST_ASSERT_EQUAL(hot_qcd.get_moles(GAS_QCD), 0, "горячая конденсация не выжгла QCD")
	TEST_ASSERT(hot_qcd.total_moles() > 0, "горячая конденсация не оставила газового супа")
	TEST_ASSERT(hot_qcd.return_temperature() <= 1.8e12, "конденсация не увела температуру под потолок стабилизации")

/// Examining armored clothing must include the armor tag line; the plasma
/// absorption proc must not have swallowed the tail of examine().
/datum/unit_test/clothing_examine_armor_tag/Run()
	var/mob/living/carbon/human/observer = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/suit/armor/vest/vest = allocate(/obj/item/clothing/suit/armor/vest)
	var/list/lines = vest.examine(observer)
	var/found = FALSE
	for(var/line in lines)
		if(findtext(line, "бирку"))
			found = TRUE
			break
	TEST_ASSERT(found, "examining armored clothing did not produce the armor tag line")

/// Pins the plasma contamination behavior: permeable worn clothing soaks in a
/// plasma atmosphere and poisons the wearer afterwards even in clean air.
/datum/unit_test/plasma_clothing_contamination/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	subject.equip_to_slot(uniform, ITEM_SLOT_ICLOTHING)
	TEST_ASSERT_EQUAL(subject.w_uniform, uniform, "could not equip the test uniform")

	var/datum/gas_mixture/plasma_env = new(CELL_VOLUME)
	plasma_env.set_moles(GAS_PLASMA, 15 * CELL_VOLUME / (R_IDEAL_GAS_EQUATION * T20C))
	plasma_env.set_temperature(T20C)
	// Simulated Life environment ticks in a plasma leak: enough for a
	// permeable uniform to soak past the poisoning threshold.
	for(var/tick in 1 to 30)
		subject.handle_plasma_clothing(plasma_env)
	TEST_ASSERT(uniform.plasma_contamination >= 1, "permeable uniform did not soak past the poisoning threshold after sustained exposure: [uniform.plasma_contamination]")

	var/datum/gas_mixture/clean_env = new(CELL_VOLUME)
	clean_env.set_moles(GAS_O2, MOLES_O2STANDARD)
	clean_env.set_moles(GAS_N2, MOLES_N2STANDARD)
	clean_env.set_temperature(T20C)
	var/tox_before = subject.getToxLoss()
	subject.handle_plasma_clothing(clean_env)
	TEST_ASSERT(subject.getToxLoss() > tox_before, "contaminated clothing did not poison the wearer in clean air")

/// Fire alarms must detect dangerously hot air on their tile through the
/// opt-in exposure path, not only direct hotspot contact.
/datum/unit_test/firealarm_hot_air/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	var/obj/machinery/firealarm/alarm = allocate(/obj/machinery/firealarm)
	alarm.machine_stat = NONE

	var/datum/gas_mixture/hot = new(CELL_VOLUME)
	hot.set_moles(GAS_O2, MOLES_O2STANDARD)
	hot.set_moles(GAS_N2, MOLES_N2STANDARD)
	hot.set_temperature(T0C + 400)

	alarm.check_atmos_process(room, hot, hot.return_temperature())
	TEST_ASSERT(alarm.flags_1 & ATMOS_IS_PROCESSING_1, "hot air did not enroll the fire alarm for exposure processing")

	var/datum/gas_mixture/stashed_air = new(room.air.return_volume())
	stashed_air.copy_from(room.air)
	room.air.copy_from(hot)
	alarm.process_exposure()
	room.air.copy_from(stashed_air)
	TEST_ASSERT(alarm.alarm_active, "fire alarm did not raise on dangerously hot air")

	var/area/base = get_base_area(alarm)
	base.firereset()
	alarm.alarm_active = FALSE
	SSair.atom_process -= alarm
	alarm.flags_1 &= ~ATMOS_IS_PROCESSING_1

/// The flameless detector is level-triggered by SSair: process_exposure() calls
/// atmos_expose() every fire for as long as the air is hot, and a turbine hall or
/// burn chamber is hot until the end of the round. Without a latch that meant a
/// siren and a firelock slam every FIREALARM_COOLDOWN forever, with the reset
/// button losing the race every single time.
/datum/unit_test/firealarm_heat_alarm_latches/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	var/obj/machinery/firealarm/alarm = allocate(/obj/machinery/firealarm)
	alarm.machine_stat = NONE

	var/hot = ATMOS_HEAT_ALARM_TEMPERATURE + 100
	var/still_hot = ATMOS_HEAT_ALARM_TEMPERATURE + 90
	var/inside_band = ATMOS_HEAT_ALARM_TEMPERATURE - (ATMOS_HEAT_ALARM_HYSTERESIS * 0.5)
	var/cooled_off = ATMOS_HEAT_ALARM_TEMPERATURE - ATMOS_HEAT_ALARM_HYSTERESIS - 1

	TEST_ASSERT(alarm.should_atmos_process(room.air, hot), "an idle detector ignored dangerously hot air")
	alarm.atmos_expose(room.air, hot)
	TEST_ASSERT(alarm.alarm_active, "the detector did not raise the alarm on the first hot reading")
	TEST_ASSERT(alarm.heat_alarm_latched, "the heat alarm did not latch after firing")

	TEST_ASSERT(!alarm.should_atmos_process(room.air, still_hot), "air that simply stayed hot re-armed the detector, so it would alarm again every cooldown")
	TEST_ASSERT(!alarm.should_atmos_process(room.air, inside_band), "air inside the release band re-armed the detector")

	TEST_ASSERT(alarm.should_atmos_process(room.air, cooled_off), "air back below the release band did not bring the detector round to release its latch")
	alarm.atmos_expose(room.air, cooled_off)
	TEST_ASSERT(!alarm.heat_alarm_latched, "cooling past the release band did not clear the latch")
	TEST_ASSERT(alarm.should_atmos_process(room.air, hot), "a released detector ignored the next hot spell")

	var/area/base = get_base_area(alarm)
	base.firereset()
	alarm.alarm_active = FALSE

/// Pressing reset is the crew saying "I know this room is hot". It has to hold,
/// or the same alarm is back before anyone can walk through the firelock. In a
/// room that is not hot it must NOT latch: the latch is only released by a
/// reading below the band, and a settled cold room never sends one, so latching
/// there would swallow the next real fire.
/datum/unit_test/firealarm_reset_acknowledges_heat/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	var/obj/machinery/firealarm/alarm = allocate(/obj/machinery/firealarm)
	alarm.machine_stat = NONE

	var/datum/gas_mixture/stashed_air = new(room.air.return_volume())
	stashed_air.copy_from(room.air)

	room.air.set_temperature(ATMOS_HEAT_ALARM_TEMPERATURE + 100)
	alarm.reset()
	TEST_ASSERT(alarm.heat_alarm_latched, "resetting in a hot room did not acknowledge the heat, so the alarm would come straight back")

	alarm.heat_alarm_latched = FALSE
	room.air.copy_from(stashed_air)
	alarm.reset()
	TEST_ASSERT(!alarm.heat_alarm_latched, "resetting in a cool room latched the detector, which would swallow the next fire")

	room.air.copy_from(stashed_air)

/// The firelock's own heat trip point has to be the one the fire alarm uses.
/// Below it the crew gets a siren, an area alarm and a reset button; a lower
/// firelock threshold left a hundred-kelvin band where the doors shut with no
/// alarm anywhere to reset.
/datum/unit_test/firelock_heat_threshold_matches_alarm/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor)
	unit_test_normalize_exposure_window(origin)
	door.generic_alarm = FALSE

	door.process_atmos_alarm(origin, origin.air, ATMOS_HEAT_ALARM_TEMPERATURE - 1)
	TEST_ASSERT_NULL(door.alarm_type, "the firelock tripped below the temperature the fire alarm reacts to")
	door.process_atmos_alarm(origin, origin.air, ATMOS_HEAT_ALARM_TEMPERATURE + 1)
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_HOT, "the firelock ignored air the fire alarm would already be screaming about")

/// Dedicated queueable area: the reservation zone itself lives in /area/space,
/// which the decompression queue rightly refuses.
/area/unit_test_decompression
	name = "Decompression Cooldown Test Area"
	requires_power = FALSE

/// A just-handled decompression area must not retrigger the whole alarm and
/// pressure-stop sweep every SSair fire while the breach is still draining.
/datum/unit_test/decompression_alarm_cooldown/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/spot = run_loc_floor_top_right
	TEST_ASSERT(istype(spot), "test location is not an open turf")
	var/area/old_area = get_area(spot)
	var/area/unit_test_decompression/base = new
	base.contents += spot

	SSair.decompression_areas -= base
	// Прайм подтверждающего гейта: тесту нужен кулдаун, а не окно подтверждения
	// (см. decompression_alarm_needs_confirmation - гейт покрыт отдельно).
	SSair.decompression_pending[base] = SSair.times_fired - 1
	SSair.queue_decompression_area(spot)
	TEST_ASSERT(SSair.decompression_areas[base], "precondition failed: a station-type area could not be queued for decompression")
	SSair.decompression_areas -= base

	SSair.handle_decompression_area(base)
	SSair.decompression_pending[base] = SSair.times_fired - 1
	SSair.queue_decompression_area(spot)
	var/requeued = SSair.decompression_areas[base]
	SSair.decompression_areas -= base
	SSair.decompression_pending -= base
	old_area.contents += spot
	TEST_ASSERT(!requeued, "a just-handled area was requeued for decompression within the alarm cooldown")

/// Опасный перепад давления через дверной проём с файрлоком захлопывает створку
/// прямо из парного шаринга, не дожидаясь зонной декомп-тревоги. Раунд 9906:
/// фронт быстрой разгерметизации проходил открытые двери раньше, чем зона
/// успевала алертнуться, и станция дренировалась целиком.
/datum/unit_test/firelock_pair_pressure_slam
	priority = TEST_LONGER

/datum/unit_test/firelock_pair_pressure_slam/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/base = run_loc_floor_bottom_left
	// Карман 4x3: пара A|B, на тайле B стоит открытый файрлок.
	for(var/dx in 0 to 3)
		for(var/dy in 0 to 2)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			if(dx == 0 || dy == 0 || dx == 3 || dy == 2)
				T.ChangeTurf(/turf/closed/wall)
	var/turf/open/tile_a = locate(base.x + 1, base.y + 1, base.z)
	var/turf/open/tile_b = locate(base.x + 2, base.y + 1, base.z)
	TEST_ASSERT(istype(tile_a) && istype(tile_b), "arena pair is not open turfs")
	var/obj/machinery/door/firedoor/lock = allocate(/obj/machinery/door/firedoor, tile_b)
	TEST_ASSERT(!lock.density, "a freshly spawned firelock must start open")
	tile_a.ImmediateCalculateAdjacentTurfs()
	tile_b.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(tile_a.atmos_adjacent_turfs[tile_b] & ATMOS_ADJACENT_FIRELOCK, "adjacency must carry the firelock bit for the pair")

	// A на штатной атмосфере, B почти пуст: перепад ~86 кПа выше порога захлопа.
	tile_a.air.copy_from_turf(tile_a)
	tile_b.air.copy_from_turf(tile_b)
	tile_b.air.multiply(0.15)
	if(tile_a.excited_group)
		tile_a.excited_group.garbage_collect()
	if(tile_b.excited_group)
		tile_b.excited_group.garbage_collect()
	SSair.add_to_active(tile_a, FALSE)
	var/fire = max(tile_a.current_cycle, tile_b.current_cycle, SSair.times_fired) + 300
	tile_a.process_cell(fire)

	// emergency_pressure_stop() уходит в close() с анимацией - плотность
	// появляется через несколько тиков.
	var/closed = FALSE
	for(var/i in 1 to 30)
		if(lock.density)
			closed = TRUE
			break
		sleep(1)
	TEST_ASSERT(closed, "a hazardous cross-door pressure delta must slam the firelock shut")

	// Cleanup: воздух и актив; дверь снимет allocate.
	tile_a.air.copy_from_turf(tile_a)
	tile_b.air.copy_from_turf(tile_b)
	if(tile_a.excited_group)
		tile_a.excited_group.dismantle()
	SSair.remove_from_active(tile_a)
	SSair.remove_from_active(tile_b)
	SSair.high_pressure_delta -= tile_a
	tile_a.high_pressure_queued = FALSE
	tile_a.pressure_vector_x = 0
	tile_a.pressure_vector_y = 0

/// Обычный RPD и блюспейс-раздатчик обязаны раздавать одну и ту же машинерию:
/// BSRPD отличается только собственной трубой. Каталоги лежат в разных файлах,
/// и каждый новый компонент рисковал попасть лишь в один из них.
/datum/unit_test/rpd_catalogue_parity/Run()
	TEST_ASSERT(length(GLOB.atmos_pipe_recipes), "the RPD atmos catalogue is empty")
	TEST_ASSERT(length(GLOB.bsatmos_pipe_recipes), "the BSRPD atmos catalogue is empty")

	var/list/bluespace_only = list()
	for(var/category in GLOB.atmos_pipe_recipes)
		var/list/bluespace_category = GLOB.bsatmos_pipe_recipes[category]
		TEST_ASSERT(length(bluespace_category), "the BSRPD is missing the whole '[category]' section of the catalogue")

		var/list/offered = list()
		for(var/datum/pipe_info/entry as anything in bluespace_category)
			offered[entry.name] = TRUE

		for(var/datum/pipe_info/recipe as anything in GLOB.atmos_pipe_recipes[category])
			TEST_ASSERT(offered[recipe.name], "the BSRPD cannot build '[recipe.name]', which the ordinary RPD lists under '[category]'")
			offered -= recipe.name

		bluespace_only += offered

	// The bluespace pipe is the one entry that may not leak the other way.
	TEST_ASSERT(bluespace_only["Bluespace Pipe"], "the BSRPD lost its own bluespace pipe")
	bluespace_only -= "Bluespace Pipe"
	TEST_ASSERT(!length(bluespace_only), "the BSRPD carries entries the ordinary RPD never got: [english_list(bluespace_only)]")

/// Кристаллизатор собирается из платы, а плата существовала только в карго -
/// сгоревшую машину нельзя было напечатать заново.
/datum/unit_test/crystallizer_board_printable/Run()
	var/datum/design/board_design = SSresearch.techweb_designs["crystallizer"]
	TEST_ASSERT_NOTNULL(board_design, "no techweb design prints the crystallizer board")
	TEST_ASSERT_EQUAL(board_design.build_path, /obj/item/circuitboard/machine/crystallizer, "the 'crystallizer' design does not build the crystallizer board")
	TEST_ASSERT(board_design.build_type & IMPRINTER, "the crystallizer board cannot be imprinted")

	var/datum/techweb_node/node = SSresearch.techweb_nodes["engineering"]
	TEST_ASSERT_NOTNULL(node, "the Industrial Engineering node is gone")
	TEST_ASSERT(node.design_ids["crystallizer"], "Industrial Engineering does not unlock the crystallizer board")

/// Печать плат не заменяет карго: ХФР собирается только из боксов, а плата
/// кристаллизатора должна оставаться доступной и без исследований.
/datum/unit_test/atmos_engine_parts_orderable/Run()
	var/datum/supply_pack/crystallizer = SSshuttle.supply_packs[/datum/supply_pack/engine/crystallizer]
	TEST_ASSERT_NOTNULL(crystallizer, "the crystallizer board crate left the cargo catalogue")
	TEST_ASSERT(/obj/item/circuitboard/machine/crystallizer in crystallizer.contains, "the crystallizer crate no longer ships the board")

	var/datum/supply_pack/hypertorus = SSshuttle.supply_packs[/datum/supply_pack/engine/hfr]
	TEST_ASSERT_NOTNULL(hypertorus, "the hypertorus kit left the cargo catalogue")
	var/static/list/hypertorus_parts = list(
		/obj/item/hfr_box/core,
		/obj/item/hfr_box/corner,
		/obj/item/hfr_box/body/fuel_input,
		/obj/item/hfr_box/body/moderator_input,
		/obj/item/hfr_box/body/waste_output,
		/obj/item/hfr_box/body/interface,
	)
	for(var/part in hypertorus_parts)
		TEST_ASSERT(part in hypertorus.contains, "the hypertorus kit no longer ships [part]")

/// get_food_seek_dir сингулярности падал "list index out of bounds" на каждом
/// вызове с самого рождения прока: числовой ключ направления в пустом list()
/// - это индексация, а не assoc. Синга всю жизнь ходила рандомом и спамила
/// рантайм каждые ~2 секунды (раунд 9884: 416 записей).
/datum/unit_test/singularity_food_seek_runtime_free/Run()
	var/obj/singularity/singulo = allocate(/obj/singularity, run_loc_floor_bottom_left)
	// Тестовая синга обязана быть инертной: без самостоятельного движения и
	// вне SSobj, иначе между тестами она поедет есть чужие аллокации.
	singulo.move_self = FALSE
	STOP_PROCESSING(SSobj, singulo)

	var/runtimes_before = GLOB.total_runtimes
	var/seek_dir = singulo.get_food_seek_dir()
	TEST_ASSERT_EQUAL(GLOB.total_runtimes - runtimes_before, 0, "get_food_seek_dir raised a runtime")
	TEST_ASSERT(seek_dir == 0 || (seek_dir in GLOB.alldirs), "get_food_seek_dir returned [seek_dir], which is not a direction")

	// Положительная проверка взвешивания: десяток предметов к востоку обязан
	// перетянуть любой мусор, оставшийся в общей тестовой зоне.
	var/turf/open/feast = locate(singulo.x + 2, singulo.y, singulo.z)
	TEST_ASSERT(istype(feast), "test reservation has no open turf two tiles east")
	for(var/i in 1 to 10)
		allocate(/obj/item/paper, feast)
	runtimes_before = GLOB.total_runtimes
	seek_dir = singulo.get_food_seek_dir()
	TEST_ASSERT_EQUAL(GLOB.total_runtimes - runtimes_before, 0, "get_food_seek_dir raised a runtime with food around")
	TEST_ASSERT_EQUAL(seek_dir, EAST, "get_food_seek_dir ignored the food pile to the east (returned [seek_dir])")

/// Космос обязан читаться холодным ОБОИМИ путями: смесью (immutable на TCMB) и
/// варом температуры самого турфа. Регресс ветки: /turf/return_temperature()
/// перестал быть пустой заглушкой эпохи auxmos, а космос свой вар из
/// initial_temperature никогда не выставлял (его Initialize не зовёт родителя),
/// то есть отдавал дефолтные T20C. Через isspaceturf-ветку get_temperature()
/// это читал каждый моб в открытом космосе - слаймы, фауна и люди перестали
/// замерзать: "космос тёплый".
/datum/unit_test/space_turf_reads_cold/Run()
	var/turf/open/target = get_step(run_loc_floor_bottom_left, NORTH)
	TEST_ASSERT(istype(target), "no open turf north of the test anchor")
	var/original_type = target.type
	var/turf/open/space/space_turf = target.ChangeTurf(/turf/open/space/basic)
	TEST_ASSERT(istype(space_turf), "ChangeTurf did not produce a space turf")

	TEST_ASSERT_EQUAL(space_turf.return_temperature(), TCMB, "space turf var temperature reads [space_turf.return_temperature()]K instead of TCMB")
	var/datum/gas_mixture/space_air = space_turf.return_air()
	TEST_ASSERT_NOTNULL(space_air, "space turf has no air mixture")
	TEST_ASSERT_EQUAL(space_air.return_temperature(), TCMB, "space air mixture reads [space_air.return_temperature()]K instead of TCMB")

	// Ровно тот путь, которым температуру среды берут handle_environment всех
	// мобов: isspaceturf-ветка подменяет показание смеси варом турфа.
	var/mob/living/simple_animal/victim = allocate(/mob/living/simple_animal, space_turf)
	TEST_ASSERT_EQUAL(victim.get_temperature(space_air), TCMB, "a mob in open space reads [victim.get_temperature(space_air)]K instead of TCMB")

	victim.forceMove(run_loc_floor_bottom_left)
	space_turf.ChangeTurf(original_type)

/// Разгерметизированная в космос зона обязана оседать ХОЛОДНОЙ. Ниже порога
/// видимости compare() (MINIMUM_MOLES_DELTA_TO_MOVE) пара турфов больше ничем
/// не обменивается, поэтому тёплый огрызок газа во внутреннем турфе сам остыть
/// не может, а брейкдаун, усредняя моль-взвешенно, размазал бы его тепло по
/// пустым турфам всей комнаты - слаймы в стравленной морилке ксенобио и комната
/// еретика Пустоты оставались тёплыми навсегда. Вент-ветка помечает группу
/// (vented_to_space), а snap_vented_wisp() приводит подпороговые остатки к TCMB.
/datum/unit_test/vented_zone_settles_cold/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/base = run_loc_floor_bottom_left

	// Карман 1x3 в стенах: [космос][кромка][интерьер]. Без стен process_cell
	// кромки затягивает в группу турфы резервации со станционным воздухом, и
	// усреднение честно возвращает в карман их тепло и моли - тест мерил бы
	// не снап, а воздух соседей.
	var/list/saved_wall_types = list()
	for(var/dx in 0 to 3)
		for(var/dy in list(0, 2))
			var/turf/wall_cell = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(wall_cell, "test reservation is missing a pocket perimeter cell at [dx],[dy]")
			saved_wall_types[wall_cell] = wall_cell.type
			wall_cell.ChangeTurf(/turf/closed/wall)
	var/turf/east_cap = locate(base.x + 3, base.y + 1, base.z)
	TEST_ASSERT_NOTNULL(east_cap, "test reservation is missing the pocket east cap")
	saved_wall_types[east_cap] = east_cap.type
	east_cap.ChangeTurf(/turf/closed/wall)

	var/turf/pocket_west = locate(base.x, base.y + 1, base.z)
	var/original_west_type = pocket_west.type
	var/turf/open/space/space_turf = pocket_west.ChangeTurf(/turf/open/space/basic)
	TEST_ASSERT(istype(space_turf), "ChangeTurf did not produce a space turf")

	var/turf/open/edge = locate(base.x + 1, base.y + 1, base.z)
	var/turf/open/interior = locate(base.x + 2, base.y + 1, base.z)
	TEST_ASSERT(istype(edge) && istype(interior), "pocket interior cells are not open turfs")
	var/datum/gas_mixture/saved_edge = edge.air.copy()
	var/datum/gas_mixture/saved_interior = interior.air.copy()
	// AfterChange ставит пересчёт смежности в очередь; тесту нужна детерминированность.
	edge.ImmediateCalculateAdjacentTurfs()
	interior.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(space_turf in edge.atmos_adjacent_turfs, "edge turf did not pick up the space neighbor")
	TEST_ASSERT(length(edge.atmos_adjacent_turfs) == 2, "pocket is not sealed: edge has [length(edge.atmos_adjacent_turfs)] open neighbors instead of 2")

	// Кромка: почти пусто, но тепло - вент-ветка возьмёт её по температурному
	// условию и пометит группу. Интерьер: тёплый огрызок ниже порога compare().
	edge.air.clear()
	edge.air.set_moles(GAS_O2, 0.02)
	edge.air.set_temperature(300)
	interior.air.clear()
	interior.air.set_moles(GAS_O2, 0.05)
	interior.air.set_temperature(300)

	var/datum/excited_group/group = new
	group.add_turf(edge)
	group.add_turf(interior)
	SSair.add_to_active(edge, FALSE)

	edge.process_cell(SSair.times_fired + 3000)
	TEST_ASSERT(group.vented_to_space || edge.excited_group?.vented_to_space, "the space vent path did not flag the excited group as vented")

	var/datum/excited_group/live_group = edge.excited_group || group
	live_group.self_breakdown()
	TEST_ASSERT(interior.air.return_temperature() <= TCMB + 1, "interior wisp stayed warm after breakdown: [interior.air.return_temperature()]K")
	TEST_ASSERT(edge.air.return_temperature() <= TCMB + 1, "edge turf stayed warm after venting: [edge.air.return_temperature()]K")

	// Контроль охвата: в ЗАВАРЕННОЙ комнате (группа без выхода в космос) тот же
	// огрызок остаётся при своей температуре - snap касается только зон,
	// реально стравленных в космос. Ряд y+3 лежит за северной стеной кармана.
	var/turf/open/sealed = locate(base.x + 1, base.y + 3, base.z)
	TEST_ASSERT(istype(sealed), "test reservation has no open turf for the sealed control")
	var/datum/gas_mixture/saved_sealed = sealed.air.copy()
	sealed.air.clear()
	sealed.air.set_moles(GAS_O2, 0.05)
	sealed.air.set_temperature(300)
	var/datum/excited_group/sealed_group = new
	sealed_group.add_turf(sealed)
	sealed_group.self_breakdown()
	TEST_ASSERT(sealed.air.return_temperature() > 250, "a sealed-room wisp was wrongly snapped to space temperature: [sealed.air.return_temperature()]K")

	// Cleanup
	if(edge.excited_group)
		edge.excited_group.dismantle()
	if(interior.excited_group)
		interior.excited_group.dismantle()
	if(sealed.excited_group)
		sealed.excited_group.dismantle()
	SSair.remove_from_active(edge)
	SSair.remove_from_active(interior)
	space_turf.ChangeTurf(original_west_type)
	for(var/turf/wall_cell as anything in saved_wall_types)
		wall_cell.ChangeTurf(saved_wall_types[wall_cell])
	edge.air.copy_from(saved_edge)
	interior.air.copy_from(saved_interior)
	sealed.air.copy_from(saved_sealed)
	edge.ImmediateCalculateAdjacentTurfs()
	interior.ImmediateCalculateAdjacentTurfs()
