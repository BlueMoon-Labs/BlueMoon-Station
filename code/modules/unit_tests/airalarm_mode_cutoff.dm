// Аварийная откачка (Panic Siphon) делит набор радиокоманд с прокачкой (Cycle) -
// это буквально один общий case в apply_mode_commands(). Разница между режимами
// была ровно одна: у прокачки есть отсечка по давлению, а у откачки её не было.
// Цена этого пропуска высокая, потому что widenet-скруббер по своей ветке в
// process_atmos() не умеет уходить в простой вообще: режим продолжал щупать по
// девять турфов на скруббер каждый фаер над уже пустой комнатой до конца смены,
// а перекушенный провод PANIC вешал его навсегда. Тесты закрепляют автовыход и,
// не менее важно, его границу - режим не должен сниматься, пока работа не сделана.

/// Отсек ещё держит воздух: снимать режим не за что, работа не закончена.
/datum/unit_test/airalarm_panic_holds_while_pressurized/Run()
	var/turf/open/floor = run_loc_floor_bottom_left
	TEST_ASSERT(istype(floor), "тесту нужен открытый турф с воздухом")

	var/datum/air_alarm_mode/panic_mode = /datum/air_alarm_mode/panic
	var/panic_id = initial(panic_mode.id)

	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	alarm.forceMove(floor)
	alarm.set_machine_stat(0)

	seed_turf_air(floor, list(GAS_O2 = MOLES_O2STANDARD, GAS_N2 = MOLES_N2STANDARD), T20C)
	alarm.mode = panic_id
	// Бэкофф выставляется прошлым прогоном process(), а тест обязан читать турф
	// именно сейчас.
	alarm.process_skips_left = 0
	alarm.process()
	TEST_ASSERT_EQUAL(alarm.mode, panic_id, "аварийная откачка снялась на отсеке под нормальным давлением")

/// Отсек стравлен: цель режима достигнута, дальше он только жжёт процессор.
/// Уход именно в Off, а не в Фильтрацию: фильтрация надула бы отсек заново,
/// вопреки тому, чего просил включивший режим.
/datum/unit_test/airalarm_panic_siphon_cutoff/Run()
	var/turf/open/floor = run_loc_floor_bottom_left
	TEST_ASSERT(istype(floor), "тесту нужен открытый турф с воздухом")

	var/datum/air_alarm_mode/panic_mode = /datum/air_alarm_mode/panic
	var/datum/air_alarm_mode/off_mode = /datum/air_alarm_mode/off
	var/datum/air_alarm_mode/scrubbing_mode = /datum/air_alarm_mode/scrubbing
	var/panic_id = initial(panic_mode.id)
	var/off_id = initial(off_mode.id)
	var/scrubbing_id = initial(scrubbing_mode.id)
	TEST_ASSERT_NOTEQUAL(off_id, scrubbing_id, "предпосылка: Off и Фильтрация обязаны быть разными режимами")

	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	alarm.forceMove(floor)
	alarm.set_machine_stat(0)

	// Один процент стандартного наполнения - около 1 кПа, заведомо ниже отсечки
	// в 5% атмосферы.
	seed_turf_air(floor, list(GAS_N2 = MOLES_CELLSTANDARD * 0.01), T20C)
	alarm.mode = panic_id
	alarm.process_skips_left = 0
	alarm.process()
	TEST_ASSERT_EQUAL(alarm.mode, off_id, "аварийная откачка не вышла в Off на стравленном отсеке")

/// Прокачка (Cycle) той же правкой не задета: её отсечка ведёт в Фильтрацию,
/// потому что этот режим по замыслу возвращает отсеку воздух.
/datum/unit_test/airalarm_cycle_cutoff_unchanged/Run()
	var/turf/open/floor = run_loc_floor_bottom_left

	var/datum/air_alarm_mode/replacement_mode = /datum/air_alarm_mode/replacement
	var/datum/air_alarm_mode/scrubbing_mode = /datum/air_alarm_mode/scrubbing
	var/replacement_id = initial(replacement_mode.id)
	var/scrubbing_id = initial(scrubbing_mode.id)

	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	alarm.forceMove(floor)
	alarm.set_machine_stat(0)

	seed_turf_air(floor, list(GAS_N2 = MOLES_CELLSTANDARD * 0.01), T20C)
	alarm.mode = replacement_id
	alarm.process_skips_left = 0
	alarm.process()
	TEST_ASSERT_EQUAL(alarm.mode, scrubbing_id, "прокачка перестала возвращаться в Фильтрацию")
