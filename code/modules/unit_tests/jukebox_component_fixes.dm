/// Номер ячейки ограничения зоны в записи SSjukeboxes.activejukeboxes (JUKE_AREA_LIMIT)
#define JUKEBOX_TEST_AREA_LIMIT_SLOT 8

/// Перемещение по очереди с дублями двигает именно тот трек, на который нажали.
/datum/unit_test/jukebox_queue_move_with_duplicates
	requires_full_map = FALSE

/datum/unit_test/jukebox_queue_move_with_duplicates/Run()
	var/obj/item/jukebox/box = allocate(/obj/item/jukebox)
	var/datum/component/jukebox/jukebox = box.GetComponent(/datum/component/jukebox)
	var/datum/track/track_a = new("A", null, 10, 5, "a")
	var/datum/track/track_b = new("B", null, 10, 5, "b")
	var/datum/track/track_c = new("C", null, 10, 5, "c")

	jukebox.queuedplaylist = list(track_a, track_b, track_c, track_b)
	TEST_ASSERT(jukebox.move_queued_track(4, TRUE), "Сдвиг четвёртого трека вверх не сработал")
	TEST_ASSERT(jukebox.queuedplaylist ~= list(track_a, track_b, track_b, track_c), "Сдвинулся не тот дубль трека")

	TEST_ASSERT(jukebox.move_queued_track(1, TRUE), "Сдвиг первого трека вверх не сработал")
	TEST_ASSERT(jukebox.queuedplaylist ~= list(track_b, track_b, track_c, track_a), "Первый трек не ушёл в конец очереди")
	TEST_ASSERT(jukebox.move_queued_track(4, FALSE), "Сдвиг последнего трека вниз не сработал")
	TEST_ASSERT(jukebox.queuedplaylist ~= list(track_a, track_b, track_b, track_c), "Последний трек не ушёл в начало очереди")

	TEST_ASSERT(!jukebox.move_queued_track(5, TRUE), "Индекс за концом очереди прошёл")
	TEST_ASSERT(!jukebox.move_queued_track(1.5, TRUE), "Дробный индекс прошёл")
	jukebox.queuedplaylist = list()
	qdel(track_a)
	qdel(track_b)
	qdel(track_c)

/// Громкость джукбокса не выходит за потолок, строки из интерфейса разбираются.
/datum/unit_test/jukebox_volume_clamped
	requires_full_map = FALSE

/datum/unit_test/jukebox_volume_clamped/Run()
	var/obj/item/jukebox/box = allocate(/obj/item/jukebox)
	var/datum/component/jukebox/jukebox = box.GetComponent(/datum/component/jukebox)
	jukebox.set_volume("500")
	TEST_ASSERT_EQUAL(jukebox.volume, JUKEBOX_MAX_VOLUME, "Громкость обычной колонки ушла выше потолка")
	jukebox.set_volume(-5)
	TEST_ASSERT_EQUAL(jukebox.volume, 0, "Отрицательная громкость не обрезана до нуля")
	jukebox.set_volume("40")
	TEST_ASSERT_EQUAL(jukebox.volume, 40, "Строковая громкость не разобрана")
	TEST_ASSERT(!jukebox.set_volume("громко"), "Нечисловая громкость принята")
	TEST_ASSERT_EQUAL(jukebox.volume, 40, "Нечисловая громкость изменила значение")

	var/obj/item/jukebox/emagged/emagged_box = allocate(/obj/item/jukebox/emagged)
	var/datum/component/jukebox/emagged_jukebox = emagged_box.GetComponent(/datum/component/jukebox)
	emagged_jukebox.set_volume("max")
	TEST_ASSERT_EQUAL(emagged_jukebox.volume, JUKEBOX_MAX_VOLUME_EMAGGED, "Взломанная колонка не получила свой потолок")

/// Управление очередью без доступа к автомату не проходит и в обход интерфейса.
/datum/unit_test/jukebox_actions_require_access
	requires_full_map = FALSE

/datum/unit_test/jukebox_actions_require_access/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/machinery/jukebox/bar_jukebox = allocate(/obj/machinery/jukebox)
	var/datum/component/jukebox/jukebox = bar_jukebox.GetComponent(/datum/component/jukebox)
	var/datum/track/track = new("A", null, 10, 5, "a")
	jukebox.queuedplaylist = list(track, track)
	var/datum/tgui/ui = new(user, jukebox, "Jukebox")
	ui.status = UI_INTERACTIVE

	TEST_ASSERT(!bar_jukebox.allowed(usr), "Предпосылка: у вызывающего нет доступа бара")
	jukebox.ui_act("clear_queue", list(), ui)
	TEST_ASSERT_EQUAL(length(jukebox.queuedplaylist), 2, "Очередь очищена без доступа")
	jukebox.ui_act("remove_from_queue", list("index" = 1), ui)
	TEST_ASSERT_EQUAL(length(jukebox.queuedplaylist), 2, "Трек удалён из очереди без доступа")
	var/old_repeat = jukebox.repeat
	jukebox.ui_act("repeat", list(), ui)
	TEST_ASSERT_EQUAL(jukebox.repeat, old_repeat, "Повтор переключён без доступа")

	var/obj/item/jukebox/free_box = allocate(/obj/item/jukebox)
	var/datum/component/jukebox/free_jukebox = free_box.GetComponent(/datum/component/jukebox)
	free_jukebox.queuedplaylist = list(track)
	var/datum/tgui/free_ui = new(user, free_jukebox, "Jukebox")
	free_ui.status = UI_INTERACTIVE
	free_jukebox.ui_act("clear_queue", list(), free_ui)
	TEST_ASSERT_EQUAL(length(free_jukebox.queuedplaylist), 0, "Колонка без требований доступа не дала очистить очередь")

	jukebox.queuedplaylist = list()
	qdel(ui)
	qdel(free_ui)
	qdel(track)

/// Остановившийся автомат не снимает приватизацию зоны, которую уже забрал другой.
/datum/unit_test/jukebox_privatized_area_release
	requires_full_map = FALSE

/datum/unit_test/jukebox_privatized_area_release/Run()
	var/obj/machinery/jukebox/first_box = allocate(/obj/machinery/jukebox)
	var/obj/machinery/jukebox/second_box = allocate(/obj/machinery/jukebox)
	var/datum/component/jukebox/first_jukebox = first_box.GetComponent(/datum/component/jukebox)
	var/datum/component/jukebox/second_jukebox = second_box.GetComponent(/datum/component/jukebox)
	var/area/test_area = get_area(first_box)
	var/obj/previous_owner = test_area.jukebox_privatized_by

	first_jukebox.privatized_area = test_area
	second_jukebox.privatized_area = test_area
	test_area.jukebox_privatized_by = second_box
	first_jukebox.dance_over()
	TEST_ASSERT_EQUAL(test_area.jukebox_privatized_by, second_box, "Остановка чужого автомата сняла приватизацию зоны")
	TEST_ASSERT_NULL(first_jukebox.privatized_area, "Автомат не забыл зону после остановки")
	second_jukebox.dance_over()
	TEST_ASSERT_NULL(test_area.jukebox_privatized_by, "Владелец приватизации не снял её при остановке")

	test_area.jukebox_privatized_by = previous_owner

/// Слушатели шкатулки в руках считаются от турфа: hearers() от вещи в инвентаре никого вокруг не видит.
/datum/unit_test/jukebox_hearers_from_held_item
	requires_full_map = FALSE

/datum/unit_test/jukebox_hearers_from_held_item/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/listener = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/obj/item/jukebox/box = allocate(/obj/item/jukebox)
	TEST_ASSERT(holder.put_in_hands(box), "Колонка не легла в руки")

	TEST_ASSERT(!(listener in hearers(7, box)), "Предпосылка: hearers() от вещи в руках видит соседей, и хелпер не нужен")
	TEST_ASSERT(listener in jukebox_hearers(box), "Сосед в двух клетках не слышит колонку в руках")

/// Музыка тише при низком давлении и молчит у порога слышимости.
/datum/unit_test/jukebox_pressure_volume
	requires_full_map = FALSE

/datum/unit_test/jukebox_pressure_volume/Run()
	TEST_ASSERT_EQUAL(jukebox_pressure_volume(100, ONE_ATMOSPHERE), 100, "При одной атмосфере громкость урезана")
	TEST_ASSERT_EQUAL(jukebox_pressure_volume(100, ONE_ATMOSPHERE * 2), 100, "Высокое давление подняло громкость выше базовой")
	TEST_ASSERT_EQUAL(jukebox_pressure_volume(100, SOUND_MINIMUM_PRESSURE), 0, "На пороге давления музыка не замолчала")
	TEST_ASSERT_EQUAL(jukebox_pressure_volume(100, 0), 0, "В вакууме громкость ушла в минус или осталась")
	var/half_volume = jukebox_pressure_volume(100, ONE_ATMOSPHERE / 2)
	TEST_ASSERT(half_volume > 0 && half_volume < 100, "При половине атмосферы громкость не снизилась: [half_volume]")

/// Джукбокс без турфа не останавливает обработку остальных в SSjukeboxes.fire().
/datum/unit_test/jukebox_fire_skips_nullspace_box
	requires_full_map = FALSE

/datum/unit_test/jukebox_fire_skips_nullspace_box/Run()
	var/obj/item/jukebox/nullspace_box = allocate(/obj/item/jukebox)
	nullspace_box.moveToNullspace()
	var/obj/item/jukebox/floor_box = allocate(/obj/item/jukebox)
	var/datum/track/track = new("A", null, 10, 5, "a")

	TEST_ASSERT(SSjukeboxes.addjukebox(nullspace_box, track, 2), "Колонка в нуллспейсе не встала в очередь подсистемы")
	var/floor_index = SSjukeboxes.addjukebox(floor_box, track, 2)
	TEST_ASSERT(floor_index, "Колонка на полу не встала в очередь подсистемы")
	var/list/floor_entry = SSjukeboxes.activejukeboxes[floor_index]
	floor_entry[JUKEBOX_TEST_AREA_LIMIT_SLOT] = "sentinel"

	SSjukeboxes.fire()
	var/reached_floor_box = floor_entry[JUKEBOX_TEST_AREA_LIMIT_SLOT] != "sentinel"

	SSjukeboxes.removejukebox(SSjukeboxes.findjukeboxindex(floor_box))
	SSjukeboxes.removejukebox(SSjukeboxes.findjukeboxindex(nullspace_box))
	qdel(track)
	TEST_ASSERT(reached_floor_box, "fire() не дошёл до колонки после колонки без турфа")

#undef JUKEBOX_TEST_AREA_LIMIT_SLOT
