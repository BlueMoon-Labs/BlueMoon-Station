/// Пустой датум для замеров refcount - никто на него не ссылается.
/datum/gc_refcount_probe

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
