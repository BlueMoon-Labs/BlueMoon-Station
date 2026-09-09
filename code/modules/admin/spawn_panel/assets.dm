/// Сторона превьюшки в пикселях. Интерфейс вешает на них класс spawnpanel32x32
/// (см. SpawnPanel/CreateObject.tsx), так что весь лист обязан быть этого размера.
#define SPAWN_PANEL_PREVIEW_SIZE 32

GLOBAL_LIST_EMPTY(spawnpanel_icon_map) // "[typepath]" → spritesheet imgid string

/datum/asset/spritesheet_batched/spawnpanel
	name = "spawnpanel"

/**
 * Строит спрайтшит превьюшек для панели спавна: по одному спрайту на уникальную
 * пару "файл иконки + стейт", и карту "тип -> id спрайта" для JSON-ассета.
 *
 * Прок обходит все подтипы /obj, /turf и /mob (это десятки тысяч типов), поэтому
 * все справочники здесь - ассоциативные списки с прямым индексированием.
 * Оператор `in` по списку это линейный поиск, и на словаре дедупа, который
 * дорастает до ~12000 записей, он один стоил около 5 секунд старта сервера.
 *
 * Сами иконки здесь не рисуются: прок только описывает спрайты, а собирает лист
 * rust-g (см. /datum/asset/spritesheet_batched). Поэтому карта иконок готова уже
 * после инициализации SSassets, даже если png ещё досчитывается в лобби.
 */
/datum/asset/spritesheet_batched/spawnpanel/create_spritesheets()
	var/list/icon_dedup = list() // "файл|стейт" -> id спрайта в шите
	var/list/states_cache = list() // файл иконки -> icon_states() этого файла
	var/list/scale_cache = list() // файл иконки -> нужно ли тянуть кадр к 32x32
	var/counter = 0

	for(var/root_type in list(/obj, /turf, /mob))
		for(var/atom_type in typesof(root_type))
			if(atom_type == root_type)
				continue
			var/atom/reference = atom_type
			var/icon_file = initial(reference.icon)
			if(!icon_file)
				continue
			// IconForge читает стейты из DMI, а у пары титульных турфов и экранных
			// объектов icon - это голый .png без метаданных. Такой файл в лист не
			// отдать; превью у них не будет, спавнить их всё равно некому.
			if(copytext("[icon_file]", -4) != ".dmi")
				continue
			var/list/file_states = states_cache[icon_file]
			if(isnull(file_states))
				// Пустой список, а не null: иначе битый файл будет перечитываться
				// на каждом типе, который на него ссылается.
				file_states = icon_states(icon_file) || list()
				states_cache[icon_file] = file_states
			if(!length(file_states))
				continue
			var/icon_state = initial(reference.icon_state)
			if(!istext(icon_state) || !(icon_state in file_states))
				icon_state = ("" in file_states) ? "" : file_states[1]
			// icon_states() у файла без именованных стейтов отдаёт безымянную запись:
			// DM-путь брал её как есть, а в JSON для rust-g на месте стейта оказался бы
			// null, и на нём падает разбор всего шарда.
			if(!istext(icon_state))
				continue
			var/cache_key = "[icon_file]|[icon_state]"
			var/imgid = icon_dedup[cache_key]
			if(!imgid)
				imgid = "sp[counter]"
				var/datum/universal_icon/entry = uni_icon(icon_file, icon_state)
				// Кадры не того размера тянем к стороне превью. Размер - свойство
				// файла, поэтому метаданные читаются один раз на файл, а не на спрайт.
				var/needs_scale = scale_cache[icon_file]
				if(isnull(needs_scale))
					var/list/dimensions = dmi_frame_dimensions(icon_file)
					// Метаданные не прочитались - тянем на всякий случай: такой файл
					// rust-g всё равно не отрисует, а размер угадывать нечем.
					needs_scale = isnull(dimensions) || dimensions["width"] != SPAWN_PANEL_PREVIEW_SIZE || dimensions["height"] != SPAWN_PANEL_PREVIEW_SIZE
					scale_cache[icon_file] = needs_scale
				if(needs_scale)
					entry.scale(SPAWN_PANEL_PREVIEW_SIZE, SPAWN_PANEL_PREVIEW_SIZE)
				insert_icon(imgid, entry)
				counter++
				icon_dedup[cache_key] = imgid
			GLOB.spawnpanel_icon_map["[atom_type]"] = imgid

/datum/asset/json/spawnpanel
	name = "spawnpanel_atom_data"
	/// Сколько типов получили id спрайта на последней генерации. Снимается ради проверки
	/// в startup_bootstrap: после register() карта иконок освобождается, и пересчитать
	/// покрытие уже нечем.
	var/sprites_registered = 0

/datum/asset/json/spawnpanel/register()
	. = ..()
	// Карту иконок читает только generate(), и только один раз - из register() выше.
	// Дальше это двадцать четыре тысячи ключей ассоциативного списка, висящих до конца
	// раунда без единого читателя.
	GLOB.spawnpanel_icon_map.Cut()

/datum/asset/json/spawnpanel/generate()
	// Порядок сборки ассетов в SSassets - это порядок typesof(), то есть порядок
	// объявления типов. Сейчас спрайтшит объявлен выше и поднимается первым, но
	// JSON без него бессмысленен: он читает spawnpanel_icon_map. Держим
	// зависимость явной, чтобы перестановка объявлений не обнулила превьюшки.
	//
	// Именно load_asset_datum, а не get_asset_datum: нам нужна только карта иконок,
	// которую заполняет create_spritesheets() при создании датума. Дожидаться здесь
	// отрисовки листа значило бы вернуть на инициализацию мира ровно ту работу,
	// которую мы с неё убрали.
	load_asset_datum(/datum/asset/spritesheet_batched/spawnpanel)

	var/list/data = list()
	var/list/atoms = list()
	var/list/category_by_root = list(
		/obj = "Objects",
		/turf = "Turfs",
		/mob = "Mobs",
	)

	sprites_registered = 0
	for(var/root_type in category_by_root)
		var/category = category_by_root[root_type]
		for(var/atom_type in typesof(root_type))
			if(atom_type == root_type)
				continue
			var/atom/reference = atom_type
			var/type_key = "[atom_type]"
			var/iconid = GLOB.spawnpanel_icon_map[type_key]
			if(iconid)
				sprites_registered++
			atoms[type_key] = list(
				"name" = "[initial(reference.name)]",
				"type" = category,
				"iconid" = iconid
			)

	data["atoms"] = atoms
	return data

#undef SPAWN_PANEL_PREVIEW_SIZE
