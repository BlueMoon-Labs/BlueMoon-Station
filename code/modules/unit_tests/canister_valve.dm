// Канистра: срабатывание таймера обязано оставлять след, а спрайт - переживать
// поломку. Оба дефекта выглядели для игрока как «канистра открылась сама».

/// Таймер - единственный путь, двигающий клапан без участия игрока, и он не
/// оставлял записи ни в investigate_log, ни в release_log самой канистры.
/// Сработавший таймер выглядел как самопроизвольное открытие с последней записью
/// в логе «закрыл такой-то», и разобрать жалобу было нечем.
/datum/unit_test/canister_timer_logs_its_own_toggle/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/obj/machinery/portable_atmospherics/canister/subject = allocate(/obj/machinery/portable_atmospherics/canister, room)

	// Стартуем с открытого клапана: таймер его ЗАКРОЕТ, и ни одна молекула не
	// уедет в турф теста.
	subject.valve_open = TRUE
	subject.set_active()
	TEST_ASSERT(subject.timing, "set_active did not arm the valve timer")
	TEST_ASSERT(subject.valve_timer > 0, "arming the timer left the deadline at zero")

	subject.valve_timer = world.time - 1
	var/log_before = length(subject.release_log)
	subject.process_atmos()

	TEST_ASSERT(!subject.valve_open, "the expired timer did not toggle the valve")
	TEST_ASSERT(!subject.timing, "the expired timer stayed armed")
	TEST_ASSERT(length(subject.release_log) > log_before, "the timer toggled the valve without recording it in release_log")
	TEST_ASSERT(findtext(subject.release_log, "timer"), "the release_log entry does not name the timer as the actor")

/// `valve_timer` по умолчанию был null, а null в числовом сравнении DM идёт за
/// ноль - то есть за взведённый в прошлом. Любой путь, выставивший `timing` мимо
/// set_active(), открыл бы клапан на ближайшем же фаере.
/datum/unit_test/canister_timer_needs_armed_deadline/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/obj/machinery/portable_atmospherics/canister/subject = allocate(/obj/machinery/portable_atmospherics/canister, room)

	TEST_ASSERT_EQUAL(subject.valve_timer, 0, "a fresh canister must not carry a null valve deadline")
	subject.valve_open = FALSE
	subject.timing = TRUE
	subject.valve_timer = 0

	subject.process_atmos()

	TEST_ASSERT(!subject.valve_open, "an unarmed deadline opened the valve on its own")

/// `icon_state = "[icon_state]-1"` дописывал суффикс к ТЕКУЩЕМУ состоянию, так
/// что вторая перерисовка сломанной канистры давала "-1-1" - стейта с таким
/// именем нет ни в одном .dmi, и канистра исчезала с экрана.
/datum/unit_test/canister_broken_sprite_does_not_stack/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/obj/machinery/portable_atmospherics/canister/subject = allocate(/obj/machinery/portable_atmospherics/canister, room)

	subject.update_icon_state()
	var/intact_state = subject.icon_state
	TEST_ASSERT_NOTNULL(subject.base_icon_state, "update_icon_state did not capture a base state")

	subject.set_machine_stat(subject.machine_stat | BROKEN)
	subject.update_icon_state()
	var/broken_state = subject.icon_state
	TEST_ASSERT_EQUAL(broken_state, "[subject.base_icon_state]-1", "broken canister did not land on the -1 state")

	subject.update_icon_state()
	TEST_ASSERT_EQUAL(subject.icon_state, broken_state, "a second redraw stacked another -1 onto the icon state")

	// Обратный переход: снятое BROKEN обязано вернуть целый спрайт.
	subject.set_machine_stat(subject.machine_stat & ~BROKEN)
	subject.update_icon_state()
	TEST_ASSERT_EQUAL(subject.icon_state, intact_state, "clearing BROKEN did not restore the intact sprite")
