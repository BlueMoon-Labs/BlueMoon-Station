GLOBAL_LIST_EMPTY(spawnpanel_icon_map) // "[typepath]" → spritesheet imgid string

/datum/asset/spritesheet/spawnpanel
	name = "spawnpanel"

/datum/asset/spritesheet/spawnpanel/ModifyInserted(icon/pre_asset)
	if(pre_asset.Width() != 32 || pre_asset.Height() != 32)
		pre_asset.Scale(32, 32)
	return pre_asset

/**
 * Строит спрайтшит превьюшек для панели спавна: по одному спрайту на уникальную
 * пару "файл иконки + стейт", и карту "тип -> id спрайта" для JSON-ассета.
 *
 * Прок обходит все подтипы /obj, /turf и /mob (это десятки тысяч типов), поэтому
 * все справочники здесь - ассоциативные списки с прямым индексированием.
 * Оператор `in` по списку это линейный поиск, и на словаре дедупа, который
 * дорастает до ~12000 записей, он один стоил около 5 секунд старта сервера.
 */
/datum/asset/spritesheet/spawnpanel/register()
	var/list/icon_dedup = list() // "файл|стейт" -> id спрайта в шите
	var/list/states_cache = list() // файл иконки -> icon_states() этого файла
	var/counter = 0

	for(var/root_type in list(/obj, /turf, /mob))
		for(var/atom_type in typesof(root_type))
			if(atom_type == root_type)
				continue
			var/atom/reference = atom_type
			var/icon_file = initial(reference.icon)
			if(!icon_file)
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
			if(isnull(icon_state) || !(icon_state in file_states))
				icon_state = ("" in file_states) ? "" : file_states[1]
			var/cache_key = "[icon_file]|[icon_state]"
			var/imgid = icon_dedup[cache_key]
			if(!imgid)
				imgid = "sp[counter]"
				// Insert сам вырезает нужный стейт и отсеивает битые иконки,
				// так что отдельный icon()/icon_states() тут не нужен.
				if(!Insert(imgid, icon_file, icon_state))
					continue
				counter++
				icon_dedup[cache_key] = imgid
			GLOB.spawnpanel_icon_map["[atom_type]"] = imgid

	return ..()

/datum/asset/json/spawnpanel
	name = "spawnpanel_atom_data"

/datum/asset/json/spawnpanel/generate()
	// Порядок сборки ассетов в SSassets - это порядок typesof(), то есть порядок
	// объявления типов. Сейчас спрайтшит объявлен выше и поднимается первым, но
	// JSON без него бессмысленен: он читает spawnpanel_icon_map. Держим
	// зависимость явной, чтобы перестановка объявлений не обнулила превьюшки.
	// get_asset_datum идемпотентен.
	get_asset_datum(/datum/asset/spritesheet/spawnpanel)

	var/list/data = list()
	var/list/atoms = list()
	var/list/category_by_root = list(
		/obj = "Objects",
		/turf = "Turfs",
		/mob = "Mobs",
	)

	for(var/root_type in category_by_root)
		var/category = category_by_root[root_type]
		for(var/atom_type in typesof(root_type))
			if(atom_type == root_type)
				continue
			var/atom/reference = atom_type
			var/type_key = "[atom_type]"
			atoms[type_key] = list(
				"name" = "[initial(reference.name)]",
				"type" = category,
				"iconid" = GLOB.spawnpanel_icon_map[type_key]
			)

	data["atoms"] = atoms
	return data
