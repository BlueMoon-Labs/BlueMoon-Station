/// Утечку типа с дорогим del() в раунде не сносим, а ждём, пока держатель отпустит сам:
/// del() моба стоит 200-300 мс фриза (раунды 10679-10683 - 280 таких фризов).
/datum/unit_test/gc_harddel_defer_expensive_leak
	parent_type = /datum/unit_test/gc_rewrite_base
	/// Внешний держатель утечек. Сам объект в локалях Run() не живёт - фрейм пиннит.
	var/list/keeper = list()

/datum/unit_test/gc_harddel_defer_expensive_leak/proc/leak(path, hint = QDEL_HINT_QUEUE)
	var/obj/effect/gc_rewrite_test_object/leaker = new path(run_loc_floor_bottom_left)
	leaker.destroy_hint = hint
	keeper += leaker
	var/ref = REF(leaker)
	qdel(leaker)
	return ref

/datum/unit_test/gc_harddel_defer_expensive_leak/proc/seed_cost(path, avg_ms)
	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(path)
	item.hard_deletes = 1
	item.hard_delete_time = avg_ms
	item.hard_delete_avg_ms = avg_ms
	return item

/datum/unit_test/gc_harddel_defer_expensive_leak/Run()
	configure_immediate_gc()
	// RECOVER: тут дорогой del() разрешён сразу, так что отказ от него - заслуга отсрочки.
	seed_hold_health(0, FALSE, 0.25, 2, 0)
	CONFIG_SET(number/gc_harddel_defer_min_ms, 50)
	CONFIG_SET(number/gc_harddel_defer_max, 1)
	var/datum/qdel_item/expensive = seed_cost(/obj/effect/gc_rewrite_test_object/expensive, 250)
	var/datum/qdel_item/over_cap = seed_cost(/obj/effect/gc_rewrite_test_object/expensive/second, 250)
	var/datum/qdel_item/cheap = seed_cost(/obj/effect/gc_rewrite_test_object, 5)

	var/parked_ref = leak(/obj/effect/gc_rewrite_test_object/expensive)
	leak(/obj/effect/gc_rewrite_test_object)
	run_gc_fire_cycles(3)

	TEST_ASSERT(SSgarbage.deferred_harddels[parked_ref], "Дорогую утечку не отложили")
	TEST_ASSERT_EQUAL(expensive.hard_deletes, 1, "Дорогую утечку снесли через del() посреди раунда")
	TEST_ASSERT_EQUAL(SSgarbage.harddels_deferred, 1, "Отложенный харддел не посчитан")
	TEST_ASSERT_EQUAL(cheap.hard_deletes, 2, "Дешёвую утечку перестали удалять как раньше")

	leak(/obj/effect/gc_rewrite_test_object/expensive/second)
	run_gc_fire_cycles(3)
	TEST_ASSERT_EQUAL(over_cap.hard_deletes, 2, "Сверх потолка отложенных утечку не удалили")
	TEST_ASSERT_EQUAL(length(SSgarbage.deferred_harddels), 1, "Потолок отложенных хардделов не соблюдён")

	// Держатель отпустил - запись собирается без del() на ближайшей перепроверке.
	keeper.Cut()
	run_gc_fire_cycles(2)
	TEST_ASSERT(!SSgarbage.deferred_harddels[parked_ref], "Собравшаяся утечка осталась в отложенных")
	TEST_ASSERT_EQUAL(SSgarbage.harddels_avoided, 1, "Сборка без del() не посчитана")
	TEST_ASSERT_EQUAL(expensive.hard_deletes, 1, "Отпущенную утечку всё равно снесли через del()")

	// QDEL_HINT_HARDDEL собрать нельзя в принципе - ждать нечего, удаляем сразу.
	var/datum/qdel_item/forced = seed_cost(/obj/effect/gc_rewrite_test_object/expensive, 250)
	leak(/obj/effect/gc_rewrite_test_object/expensive, QDEL_HINT_HARDDEL)
	run_gc_fire_cycles(2)
	TEST_ASSERT_EQUAL(forced.hard_deletes, 2, "Тип с QDEL_HINT_HARDDEL отложили вместо del()")
	keeper.Cut()

/// Выключатель: порог 0 возвращает прежнее поведение.
/datum/unit_test/gc_harddel_defer_disabled_by_config
	parent_type = /datum/unit_test/gc_harddel_defer_expensive_leak

/datum/unit_test/gc_harddel_defer_disabled_by_config/Run()
	configure_immediate_gc()
	seed_hold_health(0, FALSE, 0.25, 2, 0)
	CONFIG_SET(number/gc_harddel_defer_min_ms, 0)
	var/datum/qdel_item/expensive = seed_cost(/obj/effect/gc_rewrite_test_object/expensive, 250)
	leak(/obj/effect/gc_rewrite_test_object/expensive)
	run_gc_fire_cycles(3)
	TEST_ASSERT_EQUAL(expensive.hard_deletes, 2, "С выключенной отсрочкой утечку не удалили")
	TEST_ASSERT_EQUAL(length(SSgarbage.deferred_harddels), 0, "С выключенной отсрочкой что-то отложили")
	keeper.Cut()
