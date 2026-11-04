#define PLAYER_SAVE_AUDIT_ERROR_LIMIT 5
#define PLAYER_SAVE_AUDIT_PROGRESS_INTERVAL 100
#define PLAYER_SAVE_AUDIT_COMPARE_DEPTH 64
#define PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS 20
#define PLAYER_SAVE_AUDIT_FULL_READ_ITERATIONS 5
#define PLAYER_SAVE_AUDIT_SLOT_LIMIT 128

// Подключается только отдельной утилитой проверки, без запуска игрового мира.
/world/New()
	var/list/parameters = params
	var/list/manifest = json_decode(file2text(parameters["save-audit-manifest"]))
	var/work_directory = manifest["work_directory"]
	var/list/files = manifest["files"]
	if(manifest["mode"] == "export")
		player_save_export_legacy(manifest)
		del(world)
		return
	var/list/report = list("files" = files.len, "passed" = 0, "failed" = 0, "versions" = list(), "failures" = list(), "slots" = 0, "repaired" = list(), "missing_version" = list())
	var/started = REALTIMEOFDAY
	var/index = 0
	var/list/benchmarks = list()
	for(var/source_path in files)
		index++
		var/scratch = "[work_directory]/audit_[index].sav"
		fcopy(source_path, scratch)
		var/original_hash = rustg_hash_file(RUSTG_HASH_MD5, scratch)
		var/savefile/source = new(scratch)
		source.Flush()
		if(rustg_hash_file(RUSTG_HASH_MD5, scratch) != original_hash)
			var/list/repaired = report["repaired"]
			repaired += index
		try
			var/version
			source["version"] >> version
			if(!isnum(version))
				var/list/missing_version = report["missing_version"]
				missing_version += index
			var/list/versions = report["versions"]
			versions["[version]"]++
			for(var/key in source.dir)
				if(copytext(key, 1, 10) == "character")
					report["slots"]++
			var/list/tree = player_save_encode_tree(source)
			var/list/from_json = json_decode(json_encode(tree))
			var/savefile/restored = new
			player_save_decode_tree(restored, from_json)
			if(!player_save_audit_equal_tree(source, restored))
				throw EXCEPTION("Содержимое отличается после JSON")
			if(manifest["storage_roundtrip"])
				var/datum/player_save_json/account/storage = new(scratch)
				var/savefile/to_store = storage.open()
				if(!to_store || !storage.commit(to_store))
					throw EXCEPTION("Не удалось записать разделы JSON: [storage.error]")
				var/datum/player_save_json/account/reopened = new(scratch)
				var/savefile/from_disk = reopened.open()
				if(!from_disk || !player_save_audit_equal_tree(source, from_disk))
					throw EXCEPTION("Содержимое отличается после повторного открытия разделов JSON")
			if(manifest["benchmark"])
				var/list/measurement = player_save_benchmark(source, "[work_directory]/benchmark_[index].sav")
				measurement["index"] = index
				benchmarks += list(measurement)
			report["passed"]++
		catch(var/exception/failure)
			report["failed"]++
			if(report["failed"] <= PLAYER_SAVE_AUDIT_ERROR_LIMIT)
				world.log << "Save audit failure [index]: [failure.name]"
			var/list/failures = report["failures"]
			// Никаких имён персонажей, ckey или значений полей в отчёте.
			failures += list(list("index" = index, "error" = failure.name))
		source.Flush()
		if(fexists("[work_directory]/audit_[index]_bad_000.sav") || rustg_hash_file(RUSTG_HASH_MD5, scratch) != original_hash)
			var/list/repaired = report["repaired"]
			repaired |= index
		source = null
		fdel(scratch)
		fdel("[scratch].json")
		fdel("[scratch].json.recovery")
		fdel("[scratch].json.d/")
		if(!(index % PLAYER_SAVE_AUDIT_PROGRESS_INTERVAL))
			world.log << "Save audit: [index]/[files.len], failed=[report["failed"]]"
			var/progress_path = "[work_directory]/progress.json"
			fdel(progress_path)
			text2file(json_encode(report), progress_path)
			sleep(0.1 SECONDS)
	report["seconds"] = (REALTIMEOFDAY - started) / 10
	if(manifest["benchmark"])
		report["benchmarks"] = benchmarks
	var/report_path = "[work_directory]/report.json"
	fdel(report_path)
	text2file(json_encode(report), report_path)
	world.log << "Save audit complete: passed=[report["passed"]], failed=[report["failed"]], seconds=[report["seconds"]]"
	del(world)

/// Экспортирует согласованный набор JSON в отдельный .sav и проверяет его повторным чтением.
/proc/player_save_export_legacy(list/manifest)
	var/list/files = manifest["files"]
	var/list/outputs = manifest["outputs"]
	var/list/report = list("files" = files.len, "passed" = 0, "failed" = 0, "repaired" = list(), "missing_version" = list(), "failures" = list())
	for(var/index in 1 to files.len)
		try
			var/datum/player_save_json/account/storage = new(files[index])
			var/savefile/source = storage.open()
			if(!source)
				throw EXCEPTION(storage.error)
			if(!fcopy(source, outputs[index]))
				throw EXCEPTION("Не удалось записать экспорт .sav")
			var/savefile/readback = new(outputs[index])
			if(!player_save_audit_equal_tree(source, readback))
				throw EXCEPTION("Проверочное чтение экспорта не совпало с JSON")
			report["passed"]++
		catch(var/exception/failure)
			report["failed"]++
			var/list/failures = report["failures"]
			failures += list(list("index" = index, "error" = failure.name))
			fdel(outputs[index])
		if(!(index % PLAYER_SAVE_AUDIT_PROGRESS_INTERVAL))
			sleep(0.1 SECONDS)
	var/report_path = "[manifest["work_directory"]]/report.json"
	fdel(report_path)
	text2file(json_encode(report), report_path)
	world.log << "Save export complete: passed=[report["passed"]], failed=[report["failed"]]"

// Независимое сравнение значений BYOND, без повторного использования JSON-кодека.
/proc/player_save_audit_equal_value(left, right, depth = 0)
	if(depth > PLAYER_SAVE_AUDIT_COMPARE_DEPTH)
		return FALSE
	if(!islist(left) || !islist(right))
		if(isnull(left) || istext(left) || isnum(left) || ispath(left))
			return isnull(left) == isnull(right) && left == right
		var/savefile/left_value = new
		var/savefile/right_value = new
		left_value["value"] << left
		right_value["value"] << right
		return left_value.ExportText("/") == right_value.ExportText("/")
	var/list/left_list = left
	var/list/right_list = right
	if(left_list.len != right_list.len)
		return FALSE
	for(var/index in 1 to left_list.len)
		var/left_key = left_list[index]
		var/right_key = right_list[index]
		if(!player_save_audit_equal_value(left_key, right_key, depth + 1))
			return FALSE
		if(!isnull(left_key) && !isnum(left_key) && !player_save_audit_equal_value(left_list[left_key], right_list[right_key], depth + 1))
			return FALSE
	return TRUE

/proc/player_save_audit_equal_tree(savefile/left, savefile/right)
	var/left_directory = left.cd
	var/right_directory = right.cd
	if(left.dir.len != right.dir.len)
		throw EXCEPTION("Разное число ключей в [left.cd]: [left.dir.len]/[right.dir.len]")
	for(var/key in left.dir)
		if(!(key in right.dir))
			return FALSE
		var/left_value
		var/right_value
		left[key] >> left_value
		right[key] >> right_value
		if(!player_save_audit_equal_value(left_value, right_value))
			throw EXCEPTION("Разное значение поля [left.cd]/[key], numeric=[isnum(left_value)], list=[islist(left_value)]")
		left.cd = key
		right.cd = key
		if(!player_save_audit_equal_tree(left, right))
			return FALSE
		left.cd = left_directory
		right.cd = right_directory
	return TRUE


/// Оригинал не изменяется; среднее по нескольким повторам, в миллисекундах, без запуска станции.
/proc/player_save_benchmark(savefile/source, scratch)
	fdel(scratch)
	fdel("[scratch].json")
	fdel("[scratch].json.recovery")
	fdel("[scratch].json.d/")
	if(!fcopy(source, scratch))
		throw EXCEPTION("Не создана копия для замера")
	var/datum/player_save_json/account/storage = new(scratch)
	var/savefile/data = storage.open()
	if(!data || !storage.commit(data))
		throw EXCEPTION("Не создан JSON для замера")
	var/list/result = list()
	var/started = REALTIMEOFDAY
	for(var/i in 1 to PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS)
		data = storage.open("/")
		data["benchmark_setting"] << i
		if(!storage.commit(data, "/"))
			throw EXCEPTION("Ошибка записи при замере")
	result["json_root_write_ms"] = (REALTIMEOFDAY - started) * 100 / PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS
	started = REALTIMEOFDAY
	for(var/i in 1 to PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS)
		var/savefile/binary = new(scratch)
		binary["benchmark_setting"] << i
		binary.Flush()
		binary = null
	result["legacy_root_write_ms"] = (REALTIMEOFDAY - started) * 100 / PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS
	started = REALTIMEOFDAY
	for(var/i in 1 to PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS)
		data = storage.open("/")
		if(!storage.commit(data, "/"))
			throw EXCEPTION("Ошибка повторного сохранения при замере")
	result["json_unchanged_root_ms"] = (REALTIMEOFDAY - started) * 100 / PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS
	started = REALTIMEOFDAY
	var/list/names = storage.character_names(PLAYER_SAVE_AUDIT_SLOT_LIMIT)
	result["json_menu_cold_ms"] = (REALTIMEOFDAY - started) * 100
	if(!islist(names))
		throw EXCEPTION("Не прочитаны имена при замере")
	started = REALTIMEOFDAY
	for(var/i in 1 to PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS)
		storage.character_names(PLAYER_SAVE_AUDIT_SLOT_LIMIT)
	result["json_menu_warm_ms"] = (REALTIMEOFDAY - started) * 100 / PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS
	var/first_slot
	for(var/key in names)
		if(names[key])
			first_slot = key
			break
	if(first_slot)
		started = REALTIMEOFDAY
		for(var/i in 1 to PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS)
			data = storage.open("/[first_slot]")
			if(!data)
				throw EXCEPTION("Не прочитан слот при замере")
		result["json_one_slot_read_ms"] = (REALTIMEOFDAY - started) * 100 / PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS
	started = REALTIMEOFDAY
	for(var/i in 1 to PLAYER_SAVE_AUDIT_FULL_READ_ITERATIONS)
		data = storage.open()
		if(!data)
			throw EXCEPTION("Не прочитан полный аккаунт при замере")
	result["json_all_slots_read_ms"] = (REALTIMEOFDAY - started) * 100 / PLAYER_SAVE_AUDIT_FULL_READ_ITERATIONS
	fdel(scratch)
	fdel("[scratch].json")
	fdel("[scratch].json.recovery")
	fdel("[scratch].json.d/")
	return result

#undef PLAYER_SAVE_AUDIT_ERROR_LIMIT
#undef PLAYER_SAVE_AUDIT_PROGRESS_INTERVAL
#undef PLAYER_SAVE_AUDIT_COMPARE_DEPTH
#undef PLAYER_SAVE_AUDIT_BENCHMARK_ITERATIONS
#undef PLAYER_SAVE_AUDIT_FULL_READ_ITERATIONS
#undef PLAYER_SAVE_AUDIT_SLOT_LIMIT
