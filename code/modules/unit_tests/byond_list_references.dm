/// Проверяет освобождение ключей-списков при уничтожении alist.
/datum/unit_test/byond_alist_key_release/Run()
	var/list/key_list = list("probe")
	var/baseline = refcount(key_list)
	discard_holder(key_list)
	TEST_ASSERT_EQUAL(refcount(key_list), baseline, "Уничтоженный alist удерживает ключ-список")

/datum/unit_test/byond_alist_key_release/proc/discard_holder(list/key_list)
	var/alist/holder = alist()
	holder[key_list] = 1

/// Проверяет освобождение ключей обычного списка при нативном отсечении значений.
/datum/unit_test/byond_values_cut_release/Run()
	var/datum/probe = allocate(/datum)
	var/list/key_list = list("probe")
	var/probe_baseline = refcount(probe)
	var/list_baseline = refcount(key_list)
	var/list/holder = list()
	populate_holder(holder, probe, key_list)
	TEST_ASSERT_EQUAL(values_cut_under(holder, 0), 2, "Не удалены оба отрицательных значения")
	TEST_ASSERT_EQUAL(holder["retained"], 1, "Удалено положительное значение")
	TEST_ASSERT_EQUAL(refcount(probe), probe_baseline, "Нативное отсечение удерживает ключ-датум")
	TEST_ASSERT_EQUAL(refcount(key_list), list_baseline, "Нативное отсечение удерживает ключ-список")

/datum/unit_test/byond_values_cut_release/proc/populate_holder(list/holder, datum/probe, list/key_list)
	holder[probe] = -1
	holder[key_list] = -1
	holder["retained"] = 1

/// Проверяет, что запись за границу списка не оставляет ссылку на присваиваемый датум.
/datum/unit_test/byond_failed_list_write_release/Run()
	var/datum/probe = allocate(/datum)
	var/baseline = refcount(probe)
	TEST_ASSERT(fail_write(probe), "Запись за границу списка должна вызвать исключение")
	TEST_ASSERT_EQUAL(refcount(probe), baseline, "Неудачная запись в список удерживает датум")

/datum/unit_test/byond_failed_list_write_release/proc/fail_write(datum/probe)
	var/list/holder = list()
	try
		holder[1] = probe
	catch(var/exception/error)
		return findtext(error.name, "list index out of bounds")
	return FALSE

/area/byond_pruning_probe
	area_flags = NONE
	requires_power = FALSE

/area/byond_pruning_probe/Destroy()
	..()
	return QDEL_HINT_HARDDEL_NOW

/// Проверяет границы срока разгерметизации и освобождение ссылок на истёкшие зоны.
/datum/unit_test/decompression_native_pruning
	var/list/saved_handled
	var/list/saved_pending
	var/list/saved_areas
	var/list/saved_currentrun
	var/saved_count

/datum/unit_test/decompression_native_pruning/Run()
	saved_handled = SSair.decompression_handled_at
	saved_pending = SSair.decompression_pending
	saved_areas = SSair.decompression_areas
	saved_currentrun = SSair.currentrun
	saved_count = SSair.num_decompression_areas
	SSair.decompression_handled_at = list()
	SSair.decompression_pending = list()
	SSair.decompression_areas = list()
	var/area/byond_pruning_probe/expired = new
	var/area/byond_pruning_probe/boundary = new
	var/area/byond_pruning_probe/recent = new
	allocated += list(expired, boundary, recent)
	check_pruning(expired, boundary, recent)

/datum/unit_test/decompression_native_pruning/proc/check_pruning(area/expired, area/boundary, area/recent)
	var/baseline = refcount(expired)
	populate_logs(expired, boundary, recent)
	SSair.process_decompression_areas_auxtools(FALSE)
	TEST_ASSERT_EQUAL(length(SSair.decompression_handled_at), 1, "Кулдаун должен истекать включительно")
	TEST_ASSERT(recent in SSair.decompression_handled_at, "Свежий кулдаун удалён")
	TEST_ASSERT_EQUAL(length(SSair.decompression_pending), 2, "Граница окна подтверждения должна сохраняться")
	TEST_ASSERT(boundary in SSair.decompression_pending, "Граничный замер удалён")
	TEST_ASSERT(recent in SSair.decompression_pending, "Свежий замер удалён")
	TEST_ASSERT_EQUAL(refcount(expired), baseline, "Журналы удерживают истёкшую зону")

/datum/unit_test/decompression_native_pruning/proc/populate_logs(area/expired, area/boundary, area/recent)
	var/handled_cutoff = world.time - DECOMPRESSION_AREA_ALARM_COOLDOWN
	var/pending_cutoff = SSair.times_fired - DECOMPRESSION_PENDING_WINDOW_FIRES
	SSair.decompression_handled_at[expired] = handled_cutoff - 1
	SSair.decompression_handled_at[boundary] = handled_cutoff
	SSair.decompression_handled_at[recent] = handled_cutoff + 1
	SSair.decompression_pending[expired] = pending_cutoff - 1
	SSair.decompression_pending[boundary] = pending_cutoff
	SSair.decompression_pending[recent] = pending_cutoff + 1

/datum/unit_test/decompression_native_pruning/Destroy()
	SSair.decompression_handled_at = saved_handled
	SSair.decompression_pending = saved_pending
	SSair.decompression_areas = saved_areas
	SSair.currentrun = saved_currentrun
	SSair.num_decompression_areas = saved_count
	saved_handled = null
	saved_pending = null
	saved_areas = null
	saved_currentrun = null
	return ..()
