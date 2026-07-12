/// Пустой датум для замеров refcount - никто на него не ссылается.
/datum/gc_refcount_probe

/// Имитирует рантайм внутри полного обхода, не сканируя весь мир.
/datum/gc_refcount_probe/reftracker_runtime

/datum/gc_refcount_probe/reftracker_runtime/_search_references(references_to_clear)
	CRASH("Ожидаемый тестовый рантайм рефтрекера")

/datum/gc_refcount_duplicate_holder
	var/list/first_path
	var/list/second_path

/// Калибровка EXTERNAL_REFCOUNT: если BYOND сменит семантику refcount(),
/// этот тест упадёт первым и покажет, что все показания GC-телеметрии сдвинулись.
/datum/unit_test/gc_refcount_calibration/Run()
	var/datum/gc_refcount_probe/probe = new
	TEST_ASSERT_EQUAL(EXTERNAL_REFCOUNT(probe), 0, \
		"Свежий датум в одной локали должен показывать 0 внешних ссылок")
	var/list/holder = list(probe)
	TEST_ASSERT_EQUAL(EXTERNAL_REFCOUNT(probe), 1, \
		"Датум в локали + одном списке должен показывать 1 внешнюю ссылку")
	holder.Cut()
	TEST_ASSERT_EQUAL(EXTERNAL_REFCOUNT(probe), 0, \
		"После очистки списка внешних ссылок снова 0")
	qdel(probe)

/// Прогоняет настоящий OnLevelFail и проверяет, что ринг recent_failures
/// зафиксировал число внешних держателей (1 static-список).
/datum/unit_test/gc_refcount_telemetry
	var/static/list/telemetry_holder = list()

/datum/unit_test/gc_refcount_telemetry/Run()
	var/list/saved_ring = SSgarbage.recent_failures
	var/saved_skip_async = SSgarbage.test_ref_scan_skip_async
	SSgarbage.recent_failures = list()
	SSgarbage.test_ref_scan_skip_async = TRUE
	var/datum/gc_refcount_probe/probe = new
	telemetry_holder += probe
	SSgarbage.OnLevelFail(probe, GC_QUEUE_SOFTCHECK, REF(probe), world.time, QDEL_HINT_QUEUE)
	TEST_ASSERT_EQUAL(length(SSgarbage.recent_failures), 1, "OnLevelFail не записал событие в ринг")
	var/list/ring_entry = SSgarbage.recent_failures[1]
	TEST_ASSERT_EQUAL(length(ring_entry), 5, "Запись ринга должна содержать 5 элементов")
	TEST_ASSERT_EQUAL(ring_entry[5], 1, "Телеметрия должна показать ровно 1 внешнего держателя (static-список)")
	telemetry_holder.Cut()
	SSgarbage.recent_failures = saved_ring
	SSgarbage.test_ref_scan_skip_async = saved_skip_async
	qdel(probe, force = TRUE)

/// В CI клиентов нет - проб обязан отработать вхолостую без рантаймов.
/datum/unit_test/client_ref_probe_smoke/Run()
	var/datum/gc_refcount_probe/probe = new
	var/list/results = find_client_references(probe, quiet = TRUE)
	TEST_ASSERT_EQUAL(length(results), 0, "Проб без клиентов должен вернуть пустой список")
	qdel(probe)

/// CanAutoScan: кулдаун, кап за раунд, кап на тип.
/datum/unit_test/gc_reftrack_antistorm/Run()
	var/saved_last = SSgarbage.reftrack_last_autoscan
	var/saved_count = SSgarbage.reftrack_autoscans_this_round
	var/list/saved_types = SSgarbage.reftrack_autoscan_type_counts
	SSgarbage.reftrack_last_autoscan = 0
	SSgarbage.reftrack_autoscans_this_round = 0
	SSgarbage.reftrack_autoscan_type_counts = list()

	TEST_ASSERT(SSgarbage.CanAutoScan("/datum/foo"), "Свежий раунд должен разрешать авто-скан")
	SSgarbage.reftrack_last_autoscan = world.time
	TEST_ASSERT(!SSgarbage.CanAutoScan("/datum/foo"), "Кулдаун сразу после скана должен запрещать")
	SSgarbage.reftrack_last_autoscan = world.time - 10 MINUTES
	SSgarbage.reftrack_autoscan_type_counts["/datum/foo"] = GC_REFTRACK_AUTOSCAN_MAX_PER_TYPE
	TEST_ASSERT(!SSgarbage.CanAutoScan("/datum/foo"), "Кап на тип должен запрещать")
	TEST_ASSERT(SSgarbage.CanAutoScan("/datum/bar"), "Другой тип не задет капом первого")
	SSgarbage.reftrack_autoscans_this_round = GC_REFTRACK_AUTOSCAN_MAX_PER_ROUND
	TEST_ASSERT(!SSgarbage.CanAutoScan("/datum/bar"), "Кап за раунд должен запрещать")

	SSgarbage.reftrack_last_autoscan = saved_last
	SSgarbage.reftrack_autoscans_this_round = saved_count
	SSgarbage.reftrack_autoscan_type_counts = saved_types

/// Авто-скан объекта без внешних держателей только тратит полный обход мира.
/datum/unit_test/gc_reftrack_skips_zero_external_refs/Run()
	var/saved_last = SSgarbage.reftrack_last_autoscan
	var/saved_count = SSgarbage.reftrack_autoscans_this_round
	var/list/saved_types = SSgarbage.reftrack_autoscan_type_counts
	SSgarbage.reftrack_last_autoscan = 0
	SSgarbage.reftrack_autoscans_this_round = 0
	SSgarbage.reftrack_autoscan_type_counts = list()
	var/datum/gc_refcount_probe/probe = new
	TEST_ASSERT(!SSgarbage.TryAutoScan(probe, 0), "Авто-скан запустился без внешних ссылок")
	TEST_ASSERT_EQUAL(SSgarbage.reftrack_autoscans_this_round, 0, "Пропущенный авто-скан израсходовал раундовый лимит")
	qdel(probe)
	SSgarbage.reftrack_last_autoscan = saved_last
	SSgarbage.reftrack_autoscans_this_round = saved_count
	SSgarbage.reftrack_autoscan_type_counts = saved_types

/// Рантайм в полном скане не должен навсегда остановить SSgarbage или заблокировать следующие сканы.
/datum/unit_test/gc_reftrack_runtime_cleanup/Run()
	var/saved_gc_can_fire = SSgarbage.can_fire
	var/saved_active = GLOB.reftracker_active
	var/saved_cancel = GLOB.reftracker_cancel
	var/saved_remaining = GLOB.reftracker_references_to_clear
	SSgarbage.can_fire = TRUE
	GLOB.reftracker_active = FALSE
	GLOB.reftracker_cancel = FALSE
	var/datum/gc_refcount_probe/reftracker_runtime/probe = new
	probe.find_references(skip_alert = TRUE)
	TEST_ASSERT(SSgarbage.can_fire, "Рантайм полного скана оставил SSgarbage выключенным")
	TEST_ASSERT(!GLOB.reftracker_active, "Рантайм полного скана оставил глобальную блокировку")
	TEST_ASSERT(!GLOB.reftracker_cancel, "Рантайм полного скана оставил флаг отмены")
	TEST_ASSERT_EQUAL(GLOB.reftracker_references_to_clear, INFINITY, "Рантайм полного скана оставил счётчик ссылок")
	qdel(probe)
	SSgarbage.can_fire = saved_gc_can_fire
	GLOB.reftracker_active = saved_active
	GLOB.reftracker_cancel = saved_cancel
	GLOB.reftracker_references_to_clear = saved_remaining

/// GC failure world scan обязан принимать qdel-помеченную, но ещё живую цель.
/datum/unit_test/gc_world_scan_accepts_qdeling_target/Run()
	var/datum/gc_refcount_probe/probe = new
	probe.gc_destroyed = world.time || 1
	var/datum/gc_failure_viewer/gc_failure_entry/entry = new(null, probe.type, REF(probe), world.time, QDEL_HINT_QUEUE)
	TEST_ASSERT(entry.can_scan_target(probe), "World scan ошибочно считает QDELING-цель уже удалённой")
	qdel(entry)
	qdel(probe, force = TRUE)

/// resolve_target обязан отвергать чужой объект того же типа в переиспользованном ref-слоте.
/datum/unit_test/gc_entry_resolve_recycled_ref/Run()
	var/datum/gc_refcount_probe/probe = new
	probe.gc_destroyed = world.time || 1
	var/datum/gc_failure_viewer/gc_failure_entry/entry = new(null, probe.type, REF(probe), world.time, QDEL_HINT_QUEUE)
	entry.datum_ref = REF(probe)
	entry.target_gc_destroyed = probe.gc_destroyed
	TEST_ASSERT_EQUAL(entry.resolve_target(), probe, "Живая qdel-помеченная цель обязана резолвиться")
	del(probe)
	TEST_ASSERT_NULL(entry.resolve_target(), "resolve_target вернул объект после hard-delete цели")
	// Занимаем освободившийся слот объектами того же типа - имитация переиспользования ref.
	var/list/imposters = list()
	for (var/i in 1 to 8)
		imposters += new /datum/gc_refcount_probe
	TEST_ASSERT_NULL(entry.resolve_target(), "resolve_target вернул чужой объект того же типа в переиспользованном слоте")
	qdel(entry)
	QDEL_LIST(imposters)

/// Положительная метка обхода для прямого вызова DoSearchVar: боевые сканы используют
/// только отрицательные значения GLOB.reftracker_scan_id, а глобал тестам трогать нельзя -
/// сдвиг счётчика к нулю совпадает с дефолтным last_find_references и глушит обход.
#define REFTRACKER_TEST_SEARCH_MARK 100

/// Один и тот же список может быть достижим несколькими путями, но его элемент остаётся одной физической ссылкой.
/datum/unit_test/gc_reftrack_deduplicates_shared_list/Run()
	var/saved_remaining = GLOB.reftracker_references_to_clear
	var/list/saved_identities = GLOB.reftracker_found_identities.Copy()
	var/datum/gc_refcount_probe/probe = new
	var/datum/gc_refcount_duplicate_holder/holder = new
	var/list/shared_list = list(probe)
	holder.first_path = shared_list
	holder.second_path = shared_list
	GLOB.reftracker_references_to_clear = 2
	GLOB.reftracker_found_identities.Cut()
	probe.DoSearchVar(holder, "duplicate path test", REFTRACKER_TEST_SEARCH_MARK)
	TEST_ASSERT_EQUAL(GLOB.reftracker_references_to_clear, 1, "Одна ссылка через два пути была ошибочно посчитана дважды")
	holder.first_path = null
	holder.second_path = null
	shared_list.Cut()
	qdel(holder)
	qdel(probe)
	GLOB.reftracker_references_to_clear = saved_remaining
	GLOB.reftracker_found_identities = saved_identities

#undef REFTRACKER_TEST_SEARCH_MARK
