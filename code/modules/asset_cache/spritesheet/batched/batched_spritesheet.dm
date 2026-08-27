/**
 * Спрайтшит, который собирает не DM, а rust-g (IconForge).
 *
 * Старый /datum/asset/spritesheet платит одним icon() и одной вставкой в растущий
 * лист за каждый спрайт - на старте это десятки тысяч операций в один поток МК.
 * Здесь create_spritesheets() только ОПИСЫВАЕТ спрайты ([/datum/universal_icon]),
 * а рисование уезжает в rust: разом по всему листу, в несколько потоков и с
 * кросс-раундовым кэшем, который сверяет хэши DMI и не пересобирает лист вообще.
 *
 * Собранный лист не блокирует инициализацию мира: датумы встают в очередь
 * SSasset_loading и досчитываются в лобби, а если интерфейс попросит лист раньше -
 * get_asset_datum() дособирает его на месте (см. ensure_ready).
 */
#define SPR_SIZE "size_id"
#define SPR_IDX "position"
#define SPR_FILE "file"
#define CACHE_INVALID TRUE
#define CACHE_VALID FALSE
/// Бампни, если поменялся формат метаданных кэша или раскладка css - иначе прошлый
/// раунд отдаст png под несовпадающую раскладку.
#define SPRITESHEET_BATCHED_VERSION 1
/// Сколько спрайтов уходит в один png.
#define SPRITES_PER_SHARD_DEFAULT 256
/**
 * IconForge выкладывает лист ОДНОЙ строкой, поэтому ширина png растёт линейно от
 * числа спрайтов. Skia (а с ним и вебвью клиента) отказывается рисовать картинку
 * шире 32768 px, так что лист режется на шарды с двукратным запасом.
 */
#define MAX_SHEET_WIDTH 16384
/// Сколько ненайденных DMI перечислять в сообщениях лога.
#define MISSING_DMI_REPORTED 5
/// Сколько раз лист возвращается в очередь, если rust не смог прочитать часть DMI.
/// Двух попыток с шагом 15 с не хватало: в раунде 10114 дерево иконок докопировалось
/// только к 35-й секунде, лист панели спавна ушёл в пересборку с дырой и записал
/// кэш, который потом не сходился.
#define UNREAD_DMI_RETRIES 5
/// Базовая пауза перед повтором: даём деплою докопировать дерево иконок на диск.
#define UNREAD_DMI_RETRY_DELAY (15 SECONDS)
/// Потолок паузы. Удвоение без потолка увело бы последнюю попытку за пределы лобби.
#define UNREAD_DMI_RETRY_MAX_DELAY (2 MINUTES)

/datum/asset/spritesheet_batched
	_abstract = /datum/asset/spritesheet_batched
	var/name
	/// "32x32" -> TRUE
	var/list/sizes = list()
	/// "foo_bar" -> list("size_id" = "32x32", "position" = 5, "file" = "sheet_part1_32x32.png")
	var/list/sprites = list()
	/// Имена сгенерированных png - по одному на шард и размер.
	var/list/sheet_files = list()
	/// "foo_bar" -> описание иконки в списочном виде (см. /datum/universal_icon/to_list)
	var/list/entries = list()
	/// Ленивый кэш oversized_icon_classes(): считается один раз на собранный лист.
	var/list/oversized_classes
	/// Сколько спрайтов кладём в один шард.
	var/sprites_per_shard = SPRITES_PER_SHARD_DEFAULT

	/// Лист собран (или поднят из кэша) и зарегистрирован в транспорте.
	var/fully_generated = FALSE
	/// Собираться сразу в register(), не дожидаясь SSasset_loading.
	var/load_immediately = FALSE
	/// Не считать ошибкой жалобы rust-g на невалидный dir: бывает, что набор дирсов
	/// у стейта заранее неизвестен (см. pipes.dm).
	var/ignore_dir_errors = FALSE
	/// Отсортировать описание перед нарезкой на шарды. Нужно листу, чьи спрайты
	/// приходят из списка, который наполняет сам мир по ходу инициализации: порядок
	/// там пляшет от раунда к раунду, шарды разъезжаются, и кросс-раундовый кэш
	/// промахивается, хотя набор спрайтов тот же. Сортировка стоит один проход по
	/// именам, поэтому включаем её только там, где порядок действительно нестабилен.
	var/sort_sprites = FALSE

	/// Идентификатор текущей асинхронной задачи сборки, если есть.
	var/job_id
	/// Идентификатор текущей асинхронной задачи проверки кэша, если есть.
	var/cache_job_id
	/// Разобранные метаданные кэша.
	var/cache_data
	var/list/cache_sizes_data
	var/list/cache_sprites_data
	var/list/cache_sheet_files_data
	var/list/cache_png_hashes_data
	/// По одной записи кэша IconForge на каждый шард: rust хэширует разобранный вход
	/// пошардово, и хэш от склеенного JSON с его sprites_hash не сходится.
	var/list/cache_shards_data
	/// Результат проверки кэша, чтобы не гонять её по кругу при повторных заходах.
	var/cache_result
	/// Причина последнего промаха кэша строкой от rust. По ней отличаем настоящее
	/// изменение контента от файла, который в этот момент просто не читался.
	var/cache_mismatch_reason
	/// Гард одного пишущего: результат задачи rust-g одноразовый, второй опрашивающий
	/// его потеряет.
	var/generation_in_progress = FALSE
	/// Сохраняет ошибку владельца для тех, кто ждал его синхронно.
	var/generation_error
	/// DMI, которые rust не смог прочитать в последнем прогоне сборки.
	var/list/unread_dmi_paths = list()
	/// Сколько пересборок осталось листу, напоровшемуся на непрочитанные DMI. На боевом
	/// сервере это почти всегда гонка деплоя: dmb уже запущен, а дерево иконок ещё
	/// копируется (раунд 9954: jobs.dmi в 04:38:36 не открывался, а секундой позже
	/// та же генерация читала его без жалоб).
	var/unread_retries_left = UNREAD_DMI_RETRIES
	/// Таймер отложенной пересборки, чтобы unregister() мог его снять.
	var/retry_timer_id

/datum/asset/spritesheet_batched/proc/cache_meta_path()
	return "[SPRITESHEET_CACHE_DIR]cache_batched.[name].json"

/datum/asset/spritesheet_batched/proc/should_load_immediately()
#ifdef DO_NOT_DEFER_ASSETS
	return TRUE
#else
	return load_immediately
#endif

/datum/asset/spritesheet_batched/register()
	SHOULD_NOT_OVERRIDE(TRUE)

	if(!name)
		CRASH("spritesheet [type] cannot register without a name")

	// Сначала описание спрайтов - его же хэш сверяется с кэшем.
	create_spritesheets()
	if(sort_sprites)
		sort_entries()

	if(should_load_immediately())
		realize_spritesheets(yield = FALSE)
	else
		SSasset_loading.queue_asset(src)

/**
 * Раскладывает описание по именам спрайтов.
 *
 * Нарезка на шарды идёт по порядку записей, поэтому нестабильный порядок на входе
 * означает разные шарды в каждом раунде - и полную пересборку листа вместо подъёма
 * из кэша, хотя ни один спрайт не изменился.
 */
/datum/asset/spritesheet_batched/proc/sort_entries()
	var/list/sprite_names = list()
	for(var/sprite_name in entries)
		sprite_names += sprite_name
	sortTim(sprite_names, GLOBAL_PROC_REF(cmp_text_asc))
	var/list/sorted_entries = list()
	for(var/sprite_name in sprite_names)
		sorted_entries[sprite_name] = entries[sprite_name]
	entries = sorted_entries

/// Здесь зови insert_icon()/insert_all_icons() - и ничего тяжелее.
/datum/asset/spritesheet_batched/proc/create_spritesheets()
	CRASH("create_spritesheets() не реализован для [type]!")

/datum/asset/spritesheet_batched/proc/insert_icon(sprite_name, datum/universal_icon/entry)
	if(!istext(sprite_name) || !length(sprite_name))
		CRASH("Невалидное имя спрайта \"[sprite_name]\" в insert_icon()! Нестроковые имена ломают генерацию.")
	if(!istype(entry))
		CRASH("Невалидный тип в insert_icon()! Значение: [entry] (тип: [entry?.type])")
	if(entries[sprite_name])
		CRASH("Дубль спрайта \"[sprite_name]\" в листе [name] ([type])")
	entries[sprite_name] = entry.to_list()

/datum/asset/spritesheet_batched/proc/insert_all_icons(prefix, icon/icon_file, list/directions, prefix_with_dirs = TRUE)
	if(length(prefix))
		prefix = "[prefix]-"

	if(!directions)
		directions = list(SOUTH)

	for(var/icon_state_name in icon_states(icon_file))
		for(var/direction in directions)
			var/direction_prefix = (length(directions) > 1 && prefix_with_dirs) ? "[dir2text(direction)]-" : ""
			insert_icon("[prefix][direction_prefix][icon_state_name]", uni_icon(icon_file, icon_state_name, direction))

/**
 * Собирает лист или поднимает его из кэша.
 *
 * yield = TRUE только из SSasset_loading: внутри стоят UNTIL, то есть прок спит,
 * пока rust считает в своём потоке, и МК занимается остальным.
 */
/datum/asset/spritesheet_batched/proc/realize_spritesheets(yield)
	if(fully_generated)
		return
	if(generation_in_progress)
		// Второй заход из очереди не нужен вовсе. А вот синхронный потребитель не
		// имеет права увидеть полусобранный лист - он дожидается владельца.
		if(yield)
			return
		UNTIL(!generation_in_progress)
		if(fully_generated)
			return
		CRASH("Спрайтшит [name]: сборка не удалась ([generation_error || "владелец вышел без результата"])")

	generation_in_progress = TRUE
	generation_error = null
	try
		realize_spritesheets_owned(yield)
	catch(var/exception/error)
		generation_error = error.name
		// Результат задачи rust-g одноразовый: тот, кто заберёт его вторым, уснёт в UNTIL
		// навсегда. Оборванную попытку доигрывать некому, поэтому следующий заход
		// (ensure_ready или повтор из очереди) обязан начинать с чистых идентификаторов.
		job_id = null
		cache_job_id = null
		generation_in_progress = FALSE
		throw error
	generation_in_progress = FALSE

/datum/asset/spritesheet_batched/proc/realize_spritesheets_owned(yield)
	if(!length(entries))
		#ifdef ABSOLUTE_MINIMUM_MODE
		return
		#else
		CRASH("Спрайтшит [name] ([type]) пустой! Что он тут делает?")
		#endif
	if(sprites_per_shard <= 0)
		CRASH("Спрайтшит [name] ([type]): невалидный sprites_per_shard [sprites_per_shard]")

	if(isnull(cache_result))
		cache_result = should_refresh(yield)

	if(cache_result == CACHE_VALID && read_from_cache(yield))
		SSasset_loading.dequeue_asset(src)
		finish_generation()
		return

	// Кэш промахнулся, потому что rust не смог ОТКРЫТЬ один из DMI - это не изменение
	// контента, а гонка деплоя, и пересобирать лист из-за неё нельзя. Цена ошибки
	// измерена на проде: лист панели спавна стоит 400-670 МБ адресного пространства,
	// которые аллокатор не отдаёт обратно, и раунды 10114 и 10115 (единственные два из
	// шести, где он пересобирался) умерли по памяти. Ждём и перепроверяем.
	if(cache_result == CACHE_INVALID && looks_like_deploy_race(cache_mismatch_reason))
		if(can_retry_unread(yield))
			schedule_cache_recheck()
			return
		// Попытки кончились (или мы на синхронном пути, где ждать нельзя) - собираем
		// как есть, но в логе должно остаться, что причина была не в контенте.
		log_asset("Кэш spritesheet_[name] сброшен: [cache_mismatch_reason] - ждать больше нечего, собираем лист заново.")

	// Досюда дошли - кэш невалиден, нечего его хранить.
	fdel(cache_meta_path())
	// Число шардов между версиями меняется: сносим png только этого листа, чтобы
	// обрывки прошлой раскладки не уехали клиенту и не осели в вебруте.
	for(var/existing_file in flist(SPRITESHEET_CACHE_DIR))
		if(findtextEx(existing_file, "[name]_part") == 1 && copytext(existing_file, -4) == ".png")
			fdel("[SPRITESHEET_CACHE_DIR][existing_file]")

	sizes = list()
	sprites = list()
	oversized_classes = null
	sheet_files = list()
	unread_dmi_paths = list()
	retry_timer_id = null
	var/list/generated_cache_shards = list()
	var/list/shard_entries = list()
	var/shard_index = 1
	for(var/sprite_name in entries)
		shard_entries[sprite_name] = entries[sprite_name]
		if(length(shard_entries) < sprites_per_shard)
			continue
		generate_shard(shard_index++, shard_entries, generated_cache_shards, yield)
		shard_entries = list()
		// Лист всё равно уйдёт на пересборку целиком - остальные шарды считать незачем.
		if(needs_unread_retry(yield))
			break
		// Задача rust-g может вернуться в том же тике, и тогда UNTIL внутри не уснёт
		// ни разу: на листе панели спавна это полсотни шардов подряд в одном прогоне МК.
		if(yield)
			CHECK_TICK
	if(length(shard_entries) && !needs_unread_retry(yield))
		generate_shard(shard_index, shard_entries, generated_cache_shards, yield)
	if(needs_unread_retry(yield))
		schedule_unread_retry()
		return
	if(!length(sizes) || !length(sprites) || !length(sheet_files))
		CRASH("Спрайтшит [name]: rust-g вернул пустой результат")
	if(length(unread_dmi_paths))
		log_asset("Лист spritesheet_[name]: rust не прочитал [length(unread_dmi_paths)] DMI - их спрайты пропали с листа, и кэш этого листа мы не пишем. [describe_unread_dmis()]")

	var/list/png_hashes = list()
	for(var/png_name in sheet_files)
		var/png_path = "[SPRITESHEET_CACHE_DIR][png_name]"
		// Хэш считает rust. Без него транспорт зовёт md5asfile(), а тот читает файл
		// движком BYOND и морозит весь процесс - на листах выходит под 15 МБ за раунд.
		var/png_hash = rustg_hash_file(RUSTG_HASH_MD5, png_path)
		// fcopy_rsc снимает неизменяемый слепок: имя ассета несёт хэш содержимого и
		// считается один раз, а без слепка байты читались бы лениво - любая
		// перезапись файла в data/ разошлась бы с уже разосланным именем.
		SSassets.transport.register_asset(png_name, fcopy_rsc(file(png_path)), png_hash)
		png_hashes[png_name] = png_hash
		if(yield)
			CHECK_TICK

	register_css()
	if(length(unread_dmi_paths))
		// Кэш с неполными dmi_hashes не сойдётся НИКОГДА: rust отвечает на него
		// "more DMIs exist than DMI hashes provided", и лист пересобирается каждый
		// следующий раунд. Записать его хуже, чем не записать вовсе - без него
		// следующий раунд хотя бы соберёт лист начисто и сохранит полный кэш.
		fdel(cache_meta_path())
	else
		write_cache_meta(generated_cache_shards, png_hashes)
	SSasset_loading.dequeue_asset(src)
	finish_generation()

/// Отдаёт один шард в rust-g и раскладывает его результат по общим спискам листа.
/datum/asset/spritesheet_batched/proc/generate_shard(shard_index, list/shard_entries, list/generated_cache_shards, yield)
	var/shard_name = "[name]_part[shard_index]"
	var/shard_json = json_encode(shard_entries)
	var/data_out
	if(yield || !isnull(job_id))
		if(isnull(job_id))
			job_id = rustg_iconforge_generate_async(SPRITESHEET_CACHE_DIR, shard_name, shard_json, TRUE, FALSE, TRUE)
		UNTIL((data_out = rustg_iconforge_check(job_id)) != RUSTG_JOB_NO_RESULTS_YET)
		job_id = null
	else
		data_out = rustg_iconforge_generate(SPRITESHEET_CACHE_DIR, shard_name, shard_json, TRUE, FALSE, TRUE)
	if(data_out == RUSTG_JOB_ERROR || !findtext(data_out, "{", 1, 2))
		rustg_file_write(shard_json, "[GLOB.log_directory]/spritesheet_debug_[shard_name].json")
		CRASH("Спрайтшит [name], шард [shard_index]: сборка не удалась ([data_out])")
	var/list/generated = safe_json_decode(data_out)
	if(!islist(generated))
		CRASH("Спрайтшит [name], шард [shard_index]: rust-g вернул не JSON")
	var/list/shard_sizes = generated["sizes"]
	var/list/shard_sprites = generated["sprites"]
	if(generated["error"] && !(ignore_dir_errors && findtext(generated["error"], "is not in the set of valid dirs")))
		CRASH("Спрайтшит [name], шард [shard_index]: ошибка генерации ([generated["error"]])")
	if(!length(shard_sizes) || !length(shard_sprites))
		// Пустым шард выходит и тогда, когда деплой ещё не докопировал ни одного его
		// DMI - в этом случае лист уходит на пересборку, а не в CRASH.
		unread_dmi_paths |= unread_shard_dmis(shard_entries, generated["dmi_hashes"])
		if(needs_unread_retry(yield))
			return
		var/list/missing_dmis = missing_dmi_files(shard_entries)
		CRASH("Спрайтшит [name], шард [shard_index]: пустой результат[length(missing_dmis) ? " - на диске нет DMI: [missing_dmis.Join(", ")]" : ""]")

	for(var/size_id in shard_sizes)
		var/list/dimensions = splittext(size_id, "x")
		var/width = text2num(dimensions[1])
		var/sprites_of_size = 0
		for(var/sprite_name in shard_sprites)
			if(shard_sprites[sprite_name][SPR_SIZE] == size_id)
				sprites_of_size++
		if(width * sprites_of_size > MAX_SHEET_WIDTH)
			CRASH("Спрайтшит [name], шард [shard_index] вышел бы шириной [width * sprites_of_size]px - уменьши sprites_per_shard (сейчас [sprites_per_shard])")
		var/png_name = "[shard_name]_[size_id].png"
		sizes[size_id] = TRUE
		sheet_files += png_name
		// Позиция спрайта считается внутри его png, поэтому имя файла хранится рядом.
		for(var/sprite_name in shard_sprites)
			var/list/sprite = shard_sprites[sprite_name]
			if(sprite[SPR_SIZE] == size_id)
				sprite[SPR_FILE] = png_name
	for(var/sprite_name in shard_sprites)
		sprites[sprite_name] = shard_sprites[sprite_name]

	generated_cache_shards += list(list(
		"input_hash" = generated["sprites_hash"],
		"dmi_hashes" = generated["dmi_hashes"],
	))

	unread_dmi_paths |= unread_shard_dmis(shard_entries, generated["dmi_hashes"])

/**
 * DMI шарда, которые rust не смог прочитать.
 *
 * Ошибки чтения наружу не приезжают: rust просто не кладёт такой файл в dmi_hashes, а
 * спрайты из него молча пропадают с листа. Заодно из-за нехватки хэшей кросс-раундовый
 * кэш шарда не сходится НИКОГДА ("more DMIs exist than DMI hashes provided"), и лист
 * пересобирается каждый раунд. Причин две: регистр пути в коде, не совпадающий с именем
 * файла (BYOND такой путь находит, файловая система боевого сервера - нет), и гонка
 * деплоя - сервер уже стартовал, а дерево иконок ещё копируется на диск.
 */
/datum/asset/spritesheet_batched/proc/unread_shard_dmis(list/shard_entries, list/dmi_hashes)
	RETURN_TYPE(/list)
	var/list/unread = list()
	if(!islist(dmi_hashes))
		return unread
	var/list/referenced = shard_dmi_paths(shard_entries)
	if(length(referenced) <= length(dmi_hashes))
		return unread
	for(var/icon_path in referenced)
		if(isnull(dmi_hashes[icon_path]))
			unread += icon_path
	return unread

/// Непрочитанные DMI лечатся пересборкой только на отложенном пути: синхронный
/// потребитель ждать не может и получает лист как есть, с предупреждением в логе.
/datum/asset/spritesheet_batched/proc/needs_unread_retry(yield)
	return can_retry_unread(yield) && length(unread_dmi_paths)

/// Есть ли ещё право на повтор. Бюджет один на обе причины ждать (промах кэша от
/// нечитаемого файла и дыра в собранном листе): и то и другое - одна и та же гонка
/// деплоя, и растягивать её вдвое незачем.
/datum/asset/spritesheet_batched/proc/can_retry_unread(yield)
	return yield && unread_retries_left > 0

/**
 * Пауза перед следующей попыткой, вдвое больше предыдущей.
 *
 * Первая проверка почти всегда попадает в самое начало копирования дерева иконок, а
 * хвост его едет минутами (раунд 10114: попытка на 16-й секунде видела 18 непрочитанных
 * DMI против одного на старте - деплой в этот момент шёл полным ходом). Ровный шаг в
 * 15 с тратил бюджет попыток до того, как копирование заканчивалось.
 */
/datum/asset/spritesheet_batched/proc/retry_delay()
	var/attempt = max(1, UNREAD_DMI_RETRIES - unread_retries_left)
	return min(UNREAD_DMI_RETRY_DELAY * (2 ** (attempt - 1)), UNREAD_DMI_RETRY_MAX_DELAY)

/**
 * Откладывает ПЕРЕПРОВЕРКУ кэша, ничего не пересобирая.
 *
 * Сюда приходит промах вида "Error while hashing dmi_path 'X': No such file or directory":
 * кэш валиден, просто в момент проверки файла ещё не было на диске. Сбрасываем
 * разобранные метаданные, чтобы следующий заход перечитал их с нуля - за паузу деплой
 * мог доложить и сам json, и png.
 */
/datum/asset/spritesheet_batched/proc/schedule_cache_recheck()
	unread_retries_left--
	var/delay = retry_delay()
	log_asset("Кэш spritesheet_[name]: [cache_mismatch_reason] - файл не читается, похоже на гонку деплоя. Пересборку откладываем, перепроверка через [delay / 10] с, осталось попыток: [unread_retries_left].")
	cache_result = null
	cache_data = null
	cache_shards_data = null
	cache_sizes_data = null
	cache_sprites_data = null
	cache_sheet_files_data = null
	cache_png_hashes_data = null
	cache_mismatch_reason = null
	retry_timer_id = addtimer(CALLBACK(SSasset_loading, TYPE_PROC_REF(/datum/controller/subsystem/asset_loading, queue_asset), src), delay, TIMER_STOPPABLE)

/**
 * Отличает "файл не открылся" от "контент изменился".
 *
 * rust отдаёт причину промаха строкой, и у неё два принципиально разных класса.
 * Несовпавший хэш или другой набор спрайтов - настоящая инвалидация, лист обязан
 * пересобраться сейчас же. А ошибка чтения ("No such file or directory", нехватка
 * хэшей на шард) - это состояние диска в конкретную секунду, и пересборка по ней
 * стоит сотни мегабайт зря. По логам прода 25.08 промахи этого класса были в пяти
 * раундах из шести, в том числе на листах vending и pipes каждый раунд подряд.
 */
/datum/asset/spritesheet_batched/proc/looks_like_deploy_race(reason)
	if(!istext(reason))
		return FALSE
	return findtext(reason, "Error while hashing") \
		|| findtext(reason, "No such file or directory") \
		|| findtext(reason, "more DMIs exist than DMI hashes provided")

/**
 * Возвращает лист в очередь сборки с паузой на докопирование иконок.
 *
 * Прод-сценарий раунда 9954: сторож запускает мир по появлению dmb, пока деплой ещё
 * копирует 15 тысяч DMI. Листы, собравшиеся в первые пару минут, теряли спрайты из
 * ещё не доехавших файлов и до конца раунда показывали пустые рамки, а их кэш
 * записывался с неполными хэшами и промахивался все последующие раунды.
 */
/datum/asset/spritesheet_batched/proc/schedule_unread_retry()
	unread_retries_left--
	var/delay = retry_delay()
	log_asset("Лист spritesheet_[name]: rust не прочитал [length(unread_dmi_paths)] DMI - похоже, деплой ещё копирует дерево иконок. Пересборка через [delay / 10] с, осталось попыток: [unread_retries_left]. [describe_unread_dmis()]")
	sizes = list()
	sprites = list()
	oversized_classes = null
	sheet_files = list()
	retry_timer_id = addtimer(CALLBACK(SSasset_loading, TYPE_PROC_REF(/datum/controller/subsystem/asset_loading, queue_asset), src), delay, TIMER_STOPPABLE)

/// Первые MISSING_DMI_REPORTED непрочитанных путей с пометкой, виден ли файл BYOND-у.
/// fexists прощает регистр, поэтому "есть" означает гонку деплоя либо регистр пути,
/// а "нет" - файла не существует вовсе.
/datum/asset/spritesheet_batched/proc/describe_unread_dmis()
	var/list/described = list()
	for(var/icon_path in unread_dmi_paths)
		if(length(described) >= MISSING_DMI_REPORTED)
			described += "и ещё [length(unread_dmi_paths) - MISSING_DMI_REPORTED]"
			break
		described += "[icon_path] (fexists: [fexists(icon_path) ? "есть" : "нет"])"
	return "Не прочитаны: [described.Join(", ")]"

/**
 * DMI из описания шарда, которых нет на диске рядом с сервером.
 *
 * rust читает иконки файлами и ищет их относительно рабочего каталога мира, в .rsc он
 * не заглядывает. Ошибки чтения при этом наверх не приезжают - шард просто выходит
 * пустым, - поэтому причину ищем сами: обычно это деплой без дерева иконок
 * (см. tools/deploy.sh). Перечисляем не больше MISSING_DMI_REPORTED штук: если дерева
 * нет целиком, полный список в рантайме не нужен.
 */
/datum/asset/spritesheet_batched/proc/missing_dmi_files(list/shard_entries)
	RETURN_TYPE(/list)
	var/list/missing = list()
	for(var/icon_path in shard_dmi_paths(shard_entries))
		if(length(missing) >= MISSING_DMI_REPORTED)
			break
		if(!fexists(icon_path))
			missing += icon_path
	return missing

/// Все DMI, на которые ссылается описание шарда, включая вложенные в blend_icon.
/datum/asset/spritesheet_batched/proc/shard_dmi_paths(list/shard_entries)
	RETURN_TYPE(/list)
	var/list/paths = list()
	// Вложенные иконки (blend_icon) описаны такими же списками и живут в transform.
	var/list/pending = list()
	for(var/sprite_name in shard_entries)
		pending += list(shard_entries[sprite_name])
	while(length(pending))
		var/list/entry = pending[length(pending)]
		pending.len--
		if(!islist(entry))
			continue
		var/icon_path = entry["icon_file"]
		if(istext(icon_path))
			paths[icon_path] = TRUE
		for(var/list/operation as anything in entry["transform"])
			if(islist(operation["icon"]))
				pending += list(operation["icon"])
	return paths

/**
 * Проверяет кросс-раундовый кэш.
 *
 * Дешёвая часть (наличие и целостность метаданных) - на DM, дорогая (сверка хэшей
 * DMI и описания спрайтов) - в rust, отдельно по каждому шарду.
 */
/datum/asset/spritesheet_batched/proc/should_refresh(yield)
	cache_mismatch_reason = null
	var/meta_path = cache_meta_path()
	if(!fexists(meta_path))
		return CACHE_INVALID
	if(isnull(cache_data) || isnull(cache_shards_data))
		cache_data = rustg_file_read(meta_path)
		var/list/cache_json = safe_json_decode(cache_data)
		if(!islist(cache_json))
			log_asset("Кэш spritesheet_[name] - не JSON. Правили руками или оборвалась запись.")
			return CACHE_INVALID
		// Обновление rust-g может поменять саму раскладку - кэш прошлой версии не наш.
		if(cache_json["rustg_version"] != rustg_get_version() || cache_json["dm_version"] != SPRITESHEET_BATCHED_VERSION)
			log_asset("Кэш spritesheet_[name] сброшен: сменилась версия rust-g или формата кэша.")
			return CACHE_INVALID
		cache_sizes_data = cache_json["sizes"]
		cache_sprites_data = cache_json["sprites"]
		cache_sheet_files_data = cache_json["sheet_files"]
		cache_png_hashes_data = cache_json["png_hashes"]
		cache_shards_data = cache_json["shards"]
		if(!length(cache_shards_data) || !length(cache_sizes_data) || !length(cache_sprites_data) || !length(cache_sheet_files_data) || !length(cache_png_hashes_data))
			log_asset("Кэш spritesheet_[name] неполный. Правили руками или оборвалась запись.")
			return CACHE_INVALID

	// Без этой строки промах кэша не видно в логе вообще: лист просто молча
	// пересобирается каждый раунд, и понять, почему это происходит, нельзя.
	var/mismatch_reason = cache_shards_mismatch_reason(yield)
	if(mismatch_reason)
		cache_mismatch_reason = mismatch_reason
		// Промах от нечитаемого файла разбирает вызывающий: он не пересобирает лист,
		// а ждёт и проверяет заново, поэтому "сброшен" тут писать рано.
		if(!looks_like_deploy_race(mismatch_reason))
			log_asset("Кэш spritesheet_[name] сброшен: [mismatch_reason]")
		return CACHE_INVALID
	cache_mismatch_reason = null
	sizes = cache_sizes_data
	sprites = cache_sprites_data
	sheet_files = cache_sheet_files_data
	log_asset("Кэш spritesheet_[name] подтверждён.")
	return CACHE_VALID

/**
 * Режет описание на шарды тем же способом, что и сборка, и сверяет каждый с кэшем.
 *
 * Отдаёт причину промаха строкой (её пишут в лог) или null, если кэш сошёлся.
 */
/datum/asset/spritesheet_batched/proc/cache_shards_mismatch_reason(yield)
	var/list/shard_entries = list()
	var/shard_index = 1
	for(var/sprite_name in entries)
		shard_entries[sprite_name] = entries[sprite_name]
		if(length(shard_entries) < sprites_per_shard)
			continue
		var/reason = shard_mismatch_reason(shard_index, shard_entries, yield)
		if(reason)
			return reason
		shard_index++
		shard_entries = list()
	if(length(shard_entries))
		var/reason = shard_mismatch_reason(shard_index, shard_entries, yield)
		if(reason)
			return reason
		shard_index++
	// Шардов в кэше больше, чем у нас - раскладка поехала, кэшу верить нельзя.
	if(shard_index - 1 != length(cache_shards_data))
		return "шардов стало [shard_index - 1] вместо [length(cache_shards_data)]"
	return null

/datum/asset/spritesheet_batched/proc/shard_mismatch_reason(shard_index, list/shard_entries, yield)
	if(shard_index > length(cache_shards_data))
		return "шардов стало больше, чем в метаданных"
	var/list/cache_shard = cache_shards_data[shard_index]
	if(!islist(cache_shard) || !length(cache_shard["input_hash"]) || !length(cache_shard["dmi_hashes"]))
		return "метаданные шарда [shard_index] битые"
	var/input_hash = cache_shard["input_hash"]
	var/dmi_hashes_json = json_encode(cache_shard["dmi_hashes"])
	var/shard_json = json_encode(shard_entries)
	var/data_out
	if(yield || !isnull(cache_job_id))
		if(isnull(cache_job_id))
			cache_job_id = rustg_iconforge_cache_valid_async(input_hash, dmi_hashes_json, shard_json)
		UNTIL((data_out = rustg_iconforge_check(cache_job_id)) != RUSTG_JOB_NO_RESULTS_YET)
		cache_job_id = null
	else
		data_out = rustg_iconforge_cache_valid(input_hash, dmi_hashes_json, shard_json)
	if(data_out == RUSTG_JOB_ERROR || !findtext(data_out, "{", 1, 2))
		return "проверка шарда [shard_index] не удалась ([data_out])"
	var/list/result = safe_json_decode(data_out)
	if(!islist(result))
		return "rust вернул на шард [shard_index] не JSON"
	if(result["result"] == "1")
		return null
	// Причину знает rust: изменилось описание спрайтов, DMI или набор файлов.
	return "шард [shard_index] - [result["fail_reason"] || "причина не указана"]"

/**
 * Поднимает лист из кэша: png берутся с диска, css пересобирается.
 *
 * css не кэшируется намеренно - внутрь него зашиты URL из транспорта, а те живут
 * от конфига (browse_rsc против webroot, адрес CDN). Пересборка строки стоит
 * копейки, а вот отданный из прошлого раунда css указывал бы в пустоту.
 */
/datum/asset/spritesheet_batched/proc/read_from_cache(yield)
	var/list/png_snapshots = list()
	for(var/png_name in sheet_files)
		var/png_path = "[SPRITESHEET_CACHE_DIR][png_name]"
		if(!fexists(png_path))
			return FALSE
		var/expected_hash = cache_png_hashes_data?[png_name]
		if(!expected_hash)
			return FALSE
		// Хэш из метаданных - обещание о содержимом. Не сошлось - в каталог писал
		// кто-то ещё (второй мир, правка руками), и раскладке из кэша верить нельзя:
		// молча отдать клиенту чужие байты хуже, чем пересобрать. Считает rust:
		// md5asfile() на тех же файлах морозит процесс каждый раунд.
		if(rustg_hash_file(RUSTG_HASH_MD5, png_path) != expected_hash)
			log_asset("Кэш spritesheet_[name] сброшен: [png_name] на диске не совпал с хэшем из метаданных.")
			return FALSE
		png_snapshots[png_name] = fcopy_rsc(file(png_path))
		if(yield)
			CHECK_TICK

	for(var/png_name in sheet_files)
		SSassets.transport.register_asset(png_name, png_snapshots[png_name], cache_png_hashes_data[png_name], null)

	register_css()
	return TRUE

/// Пишет css на диск и регистрирует его в транспорте.
/datum/asset/spritesheet_batched/proc/register_css()
	var/css_name = "spritesheet_[name].css"
	var/css_path = "[SPRITESHEET_CACHE_DIR][css_name]"
	fdel(css_path)
	rustg_file_write(generate_css(), css_path)
	// Хэш опять же за rust: css панели спавна - это полтора мегабайта.
	SSassets.transport.register_asset(css_name, fcopy_rsc(file(css_path)), rustg_hash_file(RUSTG_HASH_MD5, css_path))

/datum/asset/spritesheet_batched/proc/write_cache_meta(list/cache_shards, list/png_hashes)
	rustg_file_write(json_encode(list(
		"shards" = cache_shards,
		"sizes" = sizes,
		"sprites" = sprites,
		"sheet_files" = sheet_files,
		"png_hashes" = png_hashes,
		"rustg_version" = rustg_get_version(),
		"dm_version" = SPRITESHEET_BATCHED_VERSION,
	)), cache_meta_path())

/**
 * Помечает лист собранным и отпускает описание спрайтов.
 *
 * Описание нужно только до конца генерации (и до сверки с кэшем), а у панели спавна
 * это ~12 тысяч записей и многомегабайтная JSON-строка - держать их весь раунд
 * незачем. Раскладка (sprites/sizes/sheet_files), от которой зависят css и
 * колл-сайты, остаётся.
 */
/datum/asset/spritesheet_batched/proc/finish_generation()
	entries = list()
	cache_data = null
	cache_shards_data = null
	cache_sizes_data = null
	cache_sprites_data = null
	cache_sheet_files_data = null
	cache_mismatch_reason = null
	fully_generated = TRUE

/datum/asset/spritesheet_batched/queued_generation()
	// Считаем задачу ДО спавна: между INVOKE_ASYNC и телом прока SSasset_loading не
	// должен решить, что очередь опустела, и вычистить кэш иконок в rust.
	SSasset_loading.assets_generating++
	INVOKE_ASYNC(src, PROC_REF(realize_queued_spritesheet))

/datum/asset/spritesheet_batched/proc/realize_queued_spritesheet()
	try
		realize_spritesheets(yield = TRUE)
	catch(var/exception/error)
		SSasset_loading.assets_generating--
		throw error
	SSasset_loading.assets_generating--

/datum/asset/spritesheet_batched/ensure_ready()
	if(!fully_generated)
		// Досборка на месте идёт СИНХРОННО, без MC_TICK_CHECK: мир стоит, пока rust
		// считает лист. У панели спавна это 47 шардов и 12 тысяч спрайтов, и такая
		// пауза посреди раунда выглядит снаружи как зависший сервер. Штатно листы
		// собирает SSasset_loading в лобби, поэтому попадание сюда - само по себе
		// новость: пишем, кого и надолго ли пришлось ждать.
		var/started_at = REALTIMEOFDAY
		realize_spritesheets(yield = FALSE)
		log_asset("Лист spritesheet_[name] дособран синхронно, мир стоял [(REALTIMEOFDAY - started_at) / 10] с - очередь SSasset_loading до него не дошла.")
	return ..()

/datum/asset/spritesheet_batched/send(client/client)
	if(!name)
		return
	ensure_ready()

	var/list/all_assets = list("spritesheet_[name].css")
	for(var/png_name in sheet_files)
		all_assets += png_name
	return SSassets.transport.send_assets(client, all_assets)

/datum/asset/spritesheet_batched/get_url_mappings()
	if(!name)
		return
	ensure_ready()

	. = list("spritesheet_[name].css" = SSassets.transport.get_asset_url("spritesheet_[name].css"))
	for(var/png_name in sheet_files)
		.[png_name] = SSassets.transport.get_asset_url(png_name)

/datum/asset/spritesheet_batched/proc/unregister()
	if(retry_timer_id)
		deltimer(retry_timer_id)
		retry_timer_id = null
	SSasset_loading.dequeue_asset(src)
	SSassets.transport.unregister_asset("spritesheet_[name].css")
	for(var/png_name in sheet_files)
		SSassets.transport.unregister_asset(png_name)

/datum/asset/spritesheet_batched/proc/generate_css()
	var/list/output = list()

	// Размер задаётся классом размера, а картинка - классом спрайта: спрайты одного
	// размера могут лежать в разных шардах.
	for(var/size_id in sizes)
		var/list/dimensions = splittext(size_id, "x")
		var/width = text2num(dimensions[1])
		var/height = text2num(dimensions[2])
		output += ".[name][size_id]{display:inline-block;width:[width]px;height:[height]px;background-repeat:no-repeat;}"

	for(var/sprite_id in sprites)
		var/list/sprite = sprites[sprite_id]
		var/size_id = sprite[SPR_SIZE]
		var/list/dimensions = splittext(size_id, "x")
		// IconForge кладёт спрайты одного размера в одну строку.
		var/x = sprite[SPR_IDX] * text2num(dimensions[1])
		output += ".[name][size_id].[sprite_id]{background-image:url('[SSassets.transport.get_asset_url(sprite[SPR_FILE])]');background-position:-[x]px 0;}"

	return output.Join("\n")

/**
 * Читающие геттеры НЕ дособирают лист.
 *
 * Класс спрайта спрашивают в том числе из речи (language.dm), а её зовут проки с
 * SHOULD_NOT_SLEEP - дособрать лист там нельзя, внутри сборки стоят UNTIL. Готовность
 * обеспечивает тот, кто отдаёт ассет клиенту (send/get_url_mappings), либо
 * load_immediately на самом листе.
 */
/datum/asset/spritesheet_batched/proc/css_tag()
	return {"<link rel="stylesheet" href="[css_filename()]" />"}

/datum/asset/spritesheet_batched/proc/css_filename()
	return SSassets.transport.get_asset_url("spritesheet_[name].css")

/datum/asset/spritesheet_batched/proc/icon_tag(sprite_name)
	var/list/sprite = sprites[sprite_name]
	if(!sprite)
		return null
	return {"<span class="[name][sprite[SPR_SIZE]] [sprite_name]"></span>"}

/datum/asset/spritesheet_batched/proc/icon_class_name(sprite_name)
	var/list/sprite = sprites[sprite_name]
	if(!sprite)
		return null
	return {"[name][sprite[SPR_SIZE]] [sprite_name]"}

/**
 * Класс размера (например design32x32) для конкретного спрайта.
 *
 * Arguments:
 * * sprite_name - спрайт, размер которого нужен
 */
/datum/asset/spritesheet_batched/proc/icon_size_id(sprite_name)
	var/list/sprite = sprites[sprite_name]
	if(!sprite)
		return null
	return "[name][sprite[SPR_SIZE]]"

/**
 * Карта "спрайт -> класс размера" для всех спрайтов, чей размер не равен тайлу
 * (в листе дизайнов это только крупные - широкие машины и высокие шкафы).
 *
 * Интерфейсу нужен размер, чтобы не рисовать широкую иконку в коробке 32x32 и не
 * резать её пополам. Слать класс каждому дизайну - лишние килобайты статики на
 * ровном месте: спрайтов не в тайл в листе единицы, остальным хватает дефолта.
 */
/datum/asset/spritesheet_batched/proc/oversized_icon_classes()
	RETURN_TYPE(/list)
	if(!isnull(oversized_classes))
		return oversized_classes
	oversized_classes = list()
	var/tile_size_id = "[world.icon_size]x[world.icon_size]"
	for(var/sprite_name in sprites)
		var/list/sprite = sprites[sprite_name]
		if(sprite[SPR_SIZE] == tile_size_id)
			continue
		oversized_classes[sprite_name] = "[name][sprite[SPR_SIZE]]"
	return oversized_classes

#undef SPR_SIZE
#undef SPR_IDX
#undef SPR_FILE
#undef CACHE_INVALID
#undef CACHE_VALID
#undef SPRITESHEET_BATCHED_VERSION
#undef SPRITES_PER_SHARD_DEFAULT
#undef MAX_SHEET_WIDTH
#undef MISSING_DMI_REPORTED
#undef UNREAD_DMI_RETRIES
#undef UNREAD_DMI_RETRY_DELAY
#undef UNREAD_DMI_RETRY_MAX_DELAY
