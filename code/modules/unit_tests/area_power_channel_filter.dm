/// Считает сигналы перерисовки и установки света на машинах в тестах питания.
/datum/power_flip_probe
	var/appearance_updates = 0
	var/set_light_calls = 0

/datum/power_flip_probe/proc/count_appearance(datum/source)
	SIGNAL_HANDLER
	appearance_updates++

/datum/power_flip_probe/proc/count_set_light(datum/source)
	SIGNAL_HANDLER
	set_light_calls++

/datum/unit_test/proc/power_flip_test_area(list/turf/floors)
	var/area/test_area = new /area
	for(var/turf/floor as anything in floors)
		claim_floor_into_area(floor, test_area)
	test_area.power_light = TRUE
	test_area.power_equip = TRUE
	test_area.power_environ = TRUE
	test_area.lightswitch = TRUE
	return test_area

/// Щелчок одного канала APC доходит только до машин этого канала; выключатель и лампы слушают канал света.
/datum/unit_test/area_power_flip_reaches_only_its_channel/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/turf/second_floor = get_step(floor, EAST)
	var/area/original_area = get_area(floor)
	var/area/test_area = power_flip_test_area(list(floor, second_floor))
	var/obj/machinery/computer/console = new(floor)
	allocated += console
	var/obj/machinery/light_switch/light_switch = new(second_floor)
	allocated += light_switch
	var/obj/machinery/light/lamp = new(second_floor)
	allocated += lamp
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(!(console.machine_stat & NOPOWER), "консоль в запитанной области должна быть запитана")
	TEST_ASSERT(lamp.on, "лампа в запитанной области с включённым выключателем должна гореть")

	var/datum/power_flip_probe/probe = new
	probe.RegisterSignal(console, COMSIG_ATOM_UPDATE_APPEARANCE, TYPE_PROC_REF(/datum/power_flip_probe, count_appearance))
	test_area.power_environ = FALSE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT_EQUAL(probe.appearance_updates, 0, "щелчок канала ENVIRON перерисовал консоль на канале EQUIP")
	test_area.power_equip = FALSE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(console.machine_stat & NOPOWER, "консоль без канала EQUIP должна обесточиться")
	TEST_ASSERT(probe.appearance_updates > 0, "обесточенная консоль должна перерисоваться")
	probe.UnregisterSignal(console, COMSIG_ATOM_UPDATE_APPEARANCE)
	TEST_ASSERT(lamp.on && !lamp.power_loss_stage, "щелчки чужих каналов не трогают лампу")

	test_area.power_light = FALSE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(light_switch.machine_stat & NOPOWER, "выключатель должен обесточиться вместе с каналом света")
	TEST_ASSERT(lamp.power_loss_stage, "лампа без канала света должна начать гаснуть")
	test_area.power_light = TRUE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(!(light_switch.machine_stat & NOPOWER), "выключатель должен ожить вместе с каналом света")
	TEST_ASSERT(lamp.on && !lamp.power_loss_stage, "лампа должна снова гореть")

	test_area.lightswitch = FALSE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(!lamp.on, "выключатель области гасит лампу")
	test_area.lightswitch = TRUE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(lamp.on, "выключатель области зажигает лампу")
	original_area.contents.Add(floor)
	original_area.contents.Add(second_floor)

/// Лампа в пожарном режиме не засчитывает себе переключение, когда APC щёлкает чужим каналом.
/datum/unit_test/light_ignores_other_channel_flip/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/test_area = power_flip_test_area(list(floor))
	var/obj/machinery/light/lamp = new(floor)
	allocated += lamp
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	lamp.fire_mode = TRUE
	lamp.update(FALSE, TRUE)
	lamp.switchcount = 1
	test_area.power_equip = FALSE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	test_area.power_equip = TRUE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT_EQUAL(lamp.switchcount, 1, "щелчки канала EQUIP крутили счётчик перегорания лампы")
	TEST_ASSERT(lamp.on, "лампа должна остаться включённой")
	original_area.contents.Add(floor)

/// Аварийная лампа без питания тратит батарейку как раньше, но не переставляет тот же свет каждый проход.
/datum/unit_test/light_emergency_glow_not_reapplied/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/test_area = power_flip_test_area(list(floor))
	var/obj/machinery/light/lamp = new(floor)
	allocated += lamp
	test_area.power_light = FALSE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(lamp.power_loss_stage, "обесточенная лампа должна начать гаснуть")
	lamp.death_flicker_tick(LIGHT_DEATH_FLICKER_STEPS)
	lamp.cell.charge = 60
	lamp.activate_emergency_lighting()
	TEST_ASSERT(lamp.emergency_mode, "погасшая лампа с батарейкой должна перейти на аварийный свет")
	var/datum/power_flip_probe/probe = new
	probe.RegisterSignal(lamp, COMSIG_ATOM_SET_LIGHT, TYPE_PROC_REF(/datum/power_flip_probe, count_set_light))
	for(var/i in 1 to 4)
		TEST_ASSERT_NOTEQUAL(lamp.process(), PROCESS_KILL, "лампа с зарядом должна остаться в аварийном режиме")
	probe.UnregisterSignal(lamp, COMSIG_ATOM_SET_LIGHT)
	TEST_ASSERT(probe.set_light_calls <= 1, "аварийный свет переставлен [probe.set_light_calls] раз за 4 прохода с одной и той же силой")
	TEST_ASSERT_EQUAL(lamp.cell.charge, 60 - 4 * LIGHT_EMERGENCY_DRAIN_RATE, "батарейка должна тратиться каждый проход")
	TEST_ASSERT(lamp.emergency_mode, "лампа должна остаться в аварийном режиме")
	TEST_ASSERT_EQUAL(lamp.light_power, lamp.bulb_emergency_pow_min, "аварийный свет на полупустой батарейке горит на минимуме")
	TEST_ASSERT_EQUAL(lamp.light_color, lamp.bulb_emergency_colour, "аварийный свет красный")
	original_area.contents.Add(floor)

/// Пожарный режим с заряжающейся батарейкой: свет ставится один раз за проход, а бросок на перегорание остаётся один.
/datum/unit_test/light_fire_mode_one_switch_per_process/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/turf/apc_floor = get_step(floor, EAST)
	var/area/original_area = get_area(floor)
	var/area/test_area = power_flip_test_area(list(floor, apc_floor))
	var/obj/machinery/power/apc/apc = new(apc_floor, SOUTH, TRUE)
	allocated += apc
	var/obj/machinery/light/lamp = new(floor)
	allocated += lamp
	test_area.power_light = TRUE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(lamp.get_area_apc() == apc, "лампе нужен APC области, иначе пожарный режим не включит аварийный свет")
	lamp.fire_mode = TRUE
	lamp.update(FALSE, TRUE)
	TEST_ASSERT(lamp.emergency_mode, "лампа в пожарном режиме должна перейти на аварийный свет")
	lamp.cell.charge = 10
	var/datum/power_flip_probe/probe = new
	probe.RegisterSignal(lamp, COMSIG_ATOM_SET_LIGHT, TYPE_PROC_REF(/datum/power_flip_probe, count_set_light))
	for(var/i in 1 to 3)
		lamp.switchcount = 1
		probe.set_light_calls = 0
		lamp.process()
		TEST_ASSERT_EQUAL(lamp.switchcount, 2, "проход [i]: ровно один бросок на перегорание")
		TEST_ASSERT_EQUAL(probe.set_light_calls, 1, "проход [i]: свет переставлен [probe.set_light_calls] раз")
	probe.UnregisterSignal(lamp, COMSIG_ATOM_SET_LIGHT)
	TEST_ASSERT(lamp.emergency_mode && lamp.status == LIGHT_OK, "лампа должна остаться целой на аварийном свете")
	TEST_ASSERT(lamp.light_range == 6 && lamp.light_power == 3 && lamp.light_color == lamp.bulb_emergency_colour, "пожарный свет [lamp.light_range]/[lamp.light_power]/[lamp.light_color]")
	TEST_ASSERT(abs(lamp.cell.charge - (10 + 3 * LIGHT_EMERGENCY_POWER_USE)) < 0.001, "батарейка заряжается как раньше: [lamp.cell.charge]")
	original_area.contents.Add(floor)
	original_area.contents.Add(apc_floor)

/// В полный тик смена питания доводит машины сразу, а лампы откладывает и потом приводит в то же состояние.
/datum/unit_test/area_power_flip_defers_lamps_in_full_tick/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/turf/second_floor = get_step(floor, EAST)
	var/area/original_area = get_area(floor)
	var/area/test_area = power_flip_test_area(list(floor, second_floor))
	var/obj/machinery/computer/console = new(floor)
	allocated += console
	var/obj/machinery/light/lamp = new(second_floor)
	allocated += lamp
	var/obj/machinery/light/doomed_lamp = new(second_floor)
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(lamp.on && doomed_lamp.on, "лампы в запитанной области должны гореть")

	var/saved_ticklimit = Master.current_ticklimit
	Master.current_ticklimit = 0
	test_area.power_light = FALSE
	test_area.power_equip = FALSE
	test_area.power_change()
	Master.current_ticklimit = saved_ticklimit
	TEST_ASSERT(console.machine_stat & NOPOWER, "машины обесточиваются в том же тике")
	TEST_ASSERT(lamp.on && !lamp.power_loss_stage, "в полный тик лампа должна дождаться следующего")
	TEST_ASSERT(lamp in GLOB.deferred_light_power_changes, "отложенная лампа должна стоять в очереди")
	qdel(doomed_lamp)
	TEST_ASSERT(!(doomed_lamp in GLOB.deferred_light_power_changes), "удалённая лампа должна уйти из очереди")
	doomed_lamp = null
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(lamp.power_loss_stage, "отложенная лампа должна погаснуть так же, как без очереди")
	TEST_ASSERT(!length(GLOB.deferred_light_power_changes), "очередь должна опустеть")
	TEST_ASSERT_NULL(GLOB.deferred_light_power_timer, "после доводки таймер очереди не нужен")

	test_area.power_light = TRUE
	test_area.power_equip = TRUE
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	TEST_ASSERT(lamp.on && !lamp.power_loss_stage, "лампа должна снова гореть")
	original_area.contents.Add(floor)
	original_area.contents.Add(second_floor)

/// Выключатель с привязанными лампами в полный тик рисует то положение, в которое их перевёл, а второй щелчок возвращает их обратно.
/datum/unit_test/light_switch_connected_lamps_full_tick/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/turf/second_floor = get_step(floor, EAST)
	var/area/original_area = get_area(floor)
	var/area/test_area = power_flip_test_area(list(floor, second_floor))
	var/obj/machinery/light_switch/light_switch = new(floor)
	allocated += light_switch
	var/obj/machinery/light/lamp = new(second_floor)
	allocated += lamp
	test_area.power_change()
	run_deferred_light_power_changes(TRUE)
	light_switch.connected_lights += lamp
	light_switch.update_appearance()
	TEST_ASSERT(lamp.on, "привязанная лампа в запитанной области должна гореть")
	TEST_ASSERT_EQUAL(light_switch.icon_state, "[light_switch.base_icon_state]1", "выключатель горящей лампы должен стоять во включённом положении")

	var/saved_ticklimit = Master.current_ticklimit
	for(var/expected_on in list(FALSE, TRUE))
		Master.current_ticklimit = 0
		light_switch.interact(null)
		Master.current_ticklimit = saved_ticklimit
		TEST_ASSERT_EQUAL(light_switch.icon_state, "[light_switch.base_icon_state][expected_on]", "в полный тик выключатель нарисовал не то положение, в которое перевёл лампу")
		run_deferred_light_power_changes(TRUE)
		TEST_ASSERT_EQUAL(lamp.on ? TRUE : FALSE, expected_on, "щелчок в полный тик не перевёл привязанную лампу")
	TEST_ASSERT_EQUAL(test_area.lightswitch, TRUE, "щелчок по привязанным лампам не трогает выключатель области")
	original_area.contents.Add(floor)
	original_area.contents.Add(second_floor)
