/obj/effect/atoms_init_probe
	name = "atoms init probe"

/// Съедает бюджет тика, и обход InitializeAtoms() уступает тик на CHECK_TICK, как при загрузке большого шаблона.
/obj/effect/atoms_init_probe/tick_eater

/obj/effect/atoms_init_probe/tick_eater/Initialize(mapload)
	. = ..()
	Master.current_ticklimit = -1

/// Две загрузки шаблонов, чьи InitializeAtoms() перекрылись, возвращают обычный режим, и созданная потом машина не застревает в late_loaders.
/datum/unit_test/atoms_initialize_overlap
	var/slow_load_done = FALSE

/datum/unit_test/atoms_initialize_overlap/proc/load_slow(list/atoms)
	SSatoms.InitializeAtoms(atoms)
	slow_load_done = TRUE

/datum/unit_test/atoms_initialize_overlap/Run()
	TEST_ASSERT_EQUAL(SSatoms.initialized, INITIALIZATION_INNEW_REGULAR, "Тест начинается в обычном режиме инициализации.")
	SSatoms.map_loader_begin()
	var/obj/effect/atoms_init_probe/tick_eater/slow = new(run_loc_floor_bottom_left)
	var/obj/effect/atoms_init_probe/fast = new(run_loc_floor_bottom_left)
	SSatoms.map_loader_stop()
	allocated += slow
	allocated += fast
	INVOKE_ASYNC(src, PROC_REF(load_slow), list(slow))
	TEST_ASSERT(!slow_load_done, "Первая загрузка уступила тик посреди обхода.")
	SSatoms.InitializeAtoms(list(fast))
	var/list/budget = new_wait_budget(2 SECONDS, "первая загрузка дошла до конца")
	while(!slow_load_done && wait_budget_tick(budget))
		continue
	TEST_ASSERT(slow_load_done, "Первая загрузка закончилась.")
	var/mode_after = SSatoms.initialized

	var/obj/machinery/atmospherics/pipe/simple/pipe = new(run_loc_floor_top_right)
	var/waiting_late = (pipe in SSatoms.late_loaders)
	qdel(pipe)
	var/pipe_refs = refcount(pipe)
	TEST_ASSERT(mode_after == INITIALIZATION_INNEW_REGULAR, "После обеих загрузок новые атомы снова создаются не как часть карты, а режим [mode_after].")
	TEST_ASSERT(!waiting_late, "Труба, поставленная после загрузок, не ждёт чужой загрузки в late_loaders.")
	TEST_ASSERT(pipe_refs == 1, "Удалённую трубу держит только локальная переменная теста, а ссылок [pipe_refs].")

/datum/unit_test/atoms_initialize_overlap/Destroy()
	// Красный прогон оставляет режим карты: остальные тесты мира не должны его унаследовать.
	SSatoms.initialized = INITIALIZATION_INNEW_REGULAR
	return ..()
