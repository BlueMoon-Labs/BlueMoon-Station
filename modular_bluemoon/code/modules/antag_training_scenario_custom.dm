/// Подписи меток мест и меток сторон для целей своей сборки; неизвестный ключ показывается как есть.
GLOBAL_LIST_INIT(antag_training_place_names, list(
	"abductor" = "Отсек похитителей",
	"ai" = "Ядро ИИ",
	"ai_core" = "Ядро ИИ",
	"archive" = "Архив",
	"arrivals" = "Зал прибытия",
	"bar" = "Бар",
	"bridge" = "Мостик",
	"brig" = "Бриг",
	"captain" = "Каюта капитана",
	"casualties" = "Пострадавшие",
	"cells" = "Камеры",
	"center" = "Центр",
	"chemistry" = "Химлаборатория",
	"command" = "Командование",
	"corridor" = "Коридор",
	"crew" = "Пост экипажа",
	"deposit" = "Депозитарий",
	"depths" = "Дальние комнаты",
	"east" = "Восток",
	"entrance" = "Вход",
	"entry" = "Вход в ярус",
	"guard" = "Пост охраны",
	"hall" = "Зал",
	"head_office" = "Кабинет главы",
	"hideout" = "Укрытие",
	"interrogation" = "Допросная",
	"junk" = "Свалка",
	"kitchen" = "Кухня",
	"lobby" = "Вестибюль",
	"medbay" = "Медотсек",
	"meeting" = "Переговорная",
	"ne" = "Северо-восток",
	"north" = "Север",
	"nw" = "Северо-запад",
	"ritual" = "Ритуальный зал",
	"saboteur" = "Подсобка",
	"se" = "Юго-восток",
	"security" = "Пост СБ",
	"server" = "Серверная",
	"south" = "Юг",
	"storage" = "Склад",
	"substation" = "Подстанция",
	"surgery" = "Операционная",
	"sw" = "Юго-запад",
	"vault" = "Хранилище",
	"vestibule" = "Вестибюль",
	"ward" = "Палата",
	"west" = "Запад",
	"workshop" = "Мастерская",
	"wreck" = "Обломки",
))

/// Цели, которые лидер добавляет в свою сборку: вид -> тип, подпись и параметры.
GLOBAL_LIST_INIT(antag_training_custom_objectives, list(
	"side_down" = list("type" = /datum/antag_training_scenario_objective/side_down, "name" = "Вывести из строя противника", "params" = list("target")),
	"survive" = list("type" = /datum/antag_training_scenario_objective/survive, "name" = "Продержаться", "params" = list("minutes")),
	"detain" = list("type" = /datum/antag_training_scenario_objective/detain, "name" = "Задержать и доставить", "params" = list("target", "zone")),
	"steal" = list("type" = /datum/antag_training_scenario_objective/steal, "name" = "Вынести предмет", "params" = list("item_type", "source", "zone")),
	"heal" = list("type" = /datum/antag_training_scenario_objective/heal, "name" = "Вылечить пострадавших", "params" = list("count", "zone")),
	"restore_power" = list("type" = /datum/antag_training_scenario_objective/restore_power, "name" = "Вернуть питание", "params" = list()),
	"restore_pressure" = list("type" = /datum/antag_training_scenario_objective/restore_pressure, "name" = "Заделать пробой и вернуть давление", "params" = list()),
	"program_goal" = list("type" = /datum/antag_training_scenario_objective/program_goal, "name" = "Выполнить цель роли (взрыв учебной бомбы)", "params" = list()),
))

/// Предметы для цели «Вынести предмет»: ключ -> подпись и тип.
GLOBAL_LIST_INIT(antag_training_custom_items, list(
	"nt_documents" = list("Секретные документы NT", /obj/item/documents/nanotrasen),
	"syndicate_documents" = list("Документы Синдиката", /obj/item/documents/syndicate/red),
	"carp_plush" = list("Плюшевый карп", /obj/item/toy/plush/carpplushie),
))

GLOBAL_LIST_INIT(antag_training_custom_minutes, list(1, 3, 5, 10, 15, 20))
#define ANTAG_TRAINING_CUSTOM_PATIENTS 5
#define ANTAG_TRAINING_CUSTOM_OBJECTIVES 8

/// Именные метки места (бриг, хранилище) без меток сторон.
/datum/antag_training_venue/proc/mark_ids()
	return list()

/datum/antag_training_venue/sector/mark_ids()
	return ready() ? place.landmark_offsets.Copy() : list()

/datum/antag_training_venue/pad/mark_ids()
	return ready() ? place.mark_offsets.Copy() : list()

/// Места для целей своей сборки: именные метки и метки сторон ("side:ключ") -> подпись.
/datum/antag_training_venue/proc/place_ids()
	. = list()
	for(var/mark_id in mark_ids())
		.[mark_id] = GLOB.antag_training_place_names[mark_id] || mark_id
	for(var/side_key in side_keys())
		if(!(side_key in .))
			.["side:[side_key]"] = GLOB.antag_training_place_names[side_key] || side_key

/// Клетка места по ключу из place_ids() или по именной метке шаблона.
/datum/antag_training_venue/proc/place_turf(place_id)
	if(!istext(place_id))
		return null
	if(findtext(place_id, "side:") == 1)
		var/list/marks = side_turfs(copytext(place_id, 6))
		return length(marks) ? marks[1] : null
	return mark_turf(place_id)

/datum/antag_training_scenario
	/// Лидер собирает цели сторон из библиотеки сам.
	var/objectives_editable = FALSE
	/// Места с замкнутой комнатой для пульта: заливка дорогая, список живёт несколько секунд при тех же местах.
	var/list/room_places_cache
	var/room_places_key
	var/room_places_at = 0

/datum/antag_training_scenario/proc/place_name(place_id)
	return venue.place_ids()[place_id] || GLOB.antag_training_place_names[place_id] || place_id

/// Из мест places те, у которых есть замкнутая комната: туда доставляют задержанных и выносят предметы.
/datum/antag_training_scenario/proc/room_places(list/places)
	var/key = jointext(places, ",")
	if(room_places_cache && key == room_places_key && world.time < room_places_at + 5 SECONDS)
		return room_places_cache
	room_places_cache = list()
	for(var/place_id in places)
		if(length(venue.zone_turfs(place_id)))
			room_places_cache[place_id] = places[place_id]
	room_places_key = key
	room_places_at = world.time
	return room_places_cache

/// Виды целей, которые подходят месту, с вариантами параметров для пульта.
/datum/antag_training_scenario/proc/objective_library()
	. = list()
	var/list/places = venue.place_ids()
	for(var/kind in GLOB.antag_training_custom_objectives)
		if(!objective_kind_fits(kind, places))
			continue
		var/list/kind_spec = GLOB.antag_training_custom_objectives[kind]
		var/list/param_entries = list()
		for(var/param in kind_spec["params"])
			param_entries += list(list("key" = param, "label" = objective_param_label(kind, param), "options" = objective_param_options(param, (param == "zone" && kind != "heal") ? room_places(places) : places)))
		. += list(list("id" = kind, "name" = kind_spec["name"], "params" = param_entries))

/datum/antag_training_scenario/proc/objective_kind_fits(kind, list/places)
	switch(kind)
		if("heal")
			return length(places) > 0
		if("detain")
			return length(room_places(places)) > 0
		if("steal")
			return length(places) > 1 && length(room_places(places)) > 0
		if("restore_power")
			var/area/place = venue.power_area()
			return !QDELETED(place?.power_apc)
		if("restore_pressure")
			var/datum/antag_training_exercise/systems/breach/breach = GLOB.antag_training_exercises["atmos_breach"]
			var/datum/antag_training_sector/place = venue.sector()
			return istype(breach) && place?.id == breach.sector
	return TRUE

/datum/antag_training_scenario/proc/objective_param_label(kind, param)
	switch(param)
		if("target")
			return "Противник"
		if("minutes")
			return "Минут"
		if("count")
			return "Пострадавших"
		if("item_type")
			return "Предмет"
		if("source")
			return "Где лежит"
		if("zone")
			switch(kind)
				if("detain")
					return "Куда доставить"
				if("steal")
					return "Куда вынести"
			return "Где встанут"
	return param

/datum/antag_training_scenario/proc/objective_param_options(param, list/places)
	. = list()
	switch(param)
		if("target")
			for(var/side_id in sides)
				. += list(list("value" = side_id, "name" = side_name(side_id)))
		if("minutes")
			for(var/minutes in GLOB.antag_training_custom_minutes)
				. += list(list("value" = "[minutes]", "name" = "[minutes] мин"))
		if("count")
			for(var/count in 1 to ANTAG_TRAINING_CUSTOM_PATIENTS)
				. += list(list("value" = "[count]", "name" = "[count]"))
		if("item_type")
			for(var/item_id in GLOB.antag_training_custom_items)
				. += list(list("value" = item_id, "name" = GLOB.antag_training_custom_items[item_id][1]))
		if("source", "zone")
			for(var/place_id in places)
				. += list(list("value" = place_id, "name" = places[place_id]))

/// Проверяет выбор лидера и собирает спецификацию цели; текст - отказ.
/datum/antag_training_scenario/proc/build_custom_objective(kind, side_id, list/raw)
	var/list/kind_spec = GLOB.antag_training_custom_objectives[kind]
	if(!istext(kind) || !kind_spec)
		return "Такой цели нет."
	if(!istext(side_id) || !sides[side_id])
		return "Выберите сторону цели."
	var/list/places = venue.place_ids()
	if(!objective_kind_fits(kind, places))
		return "Цель «[kind_spec["name"]]» не подходит месту «[venue.name()]»."
	var/list/params = list()
	for(var/param in kind_spec["params"])
		var/value = raw?[param]
		switch(param)
			if("target")
				if(!istext(value) || !sides[value] || value == side_id)
					return "Выберите сторону-противника, не свою."
				params[param] = value
			if("minutes")
				var/minutes = isnum(value) ? value : text2num(value)
				if(!(minutes in GLOB.antag_training_custom_minutes))
					return "Выберите время из списка."
				params[param] = minutes
			if("count")
				var/count = isnum(value) ? value : text2num(value)
				if(!isnum(count) || count != round(count) || count < 1 || count > ANTAG_TRAINING_CUSTOM_PATIENTS)
					return "Пострадавших от 1 до [ANTAG_TRAINING_CUSTOM_PATIENTS]."
				params[param] = count
			if("item_type")
				var/list/item = istext(value) ? GLOB.antag_training_custom_items[value] : null
				if(!item)
					return "Выберите предмет из списка."
				params[param] = item[2]
				params["item_name"] = item[1]
			if("source", "zone")
				if(!istext(value) || !places[value])
					return "Такого места нет в «[venue.name()]»: выберите из списка."
				if(param == "zone" && kind != "heal" && !length(venue.zone_turfs(value)))
					return "У места «[places[value]]» нет замкнутой комнаты: стены, двери и окна не держат его край. Выберите место из списка."
				params[param] = value
	if(params["source"] && params["source"] == params["zone"])
		return "Предмет нужно вынести в другое место."
	if(params["count"])
		var/patients = params["count"]
		for(var/list/spec as anything in objective_specs)
			var/list/spec_params = length(spec) >= 3 ? spec[3] : null
			if(ispath(spec[1], /datum/antag_training_scenario_objective/heal))
				patients += spec_params?["count"] || 0
		if(patients > ANTAG_TRAINING_TARGET_LIMIT)
			return "Пострадавших во всех целях было бы [patients], а на полигоне не больше [ANTAG_TRAINING_TARGET_LIMIT] учебных целей."
	params["name"] = custom_objective_name(kind, params, places)
	params -= "item_name"
	return list(kind_spec["type"], side_id, params)

/datum/antag_training_scenario/proc/custom_objective_name(kind, list/params, list/places)
	switch(kind)
		if("side_down")
			return "Вывести из строя сторону «[side_name(params["target"])]»"
		if("survive")
			return "Продержаться [params["minutes"]] мин"
		if("detain")
			return "Задержать сторону «[side_name(params["target"])]» и доставить: [places[params["zone"]]] (убитые засчитываются)"
		if("steal")
			return "Вынести «[params["item_name"]]»: [places[params["source"]]] -> [places[params["zone"]]]"
		if("heal")
			return "Вылечить пострадавших ([params["count"]]): [places[params["zone"]]]"
	return GLOB.antag_training_custom_objectives[kind]["name"]

/datum/antag_training_scenario/proc/add_custom_objective(datum/antag_training_session/requester, list/params)
	if(!objectives_editable || !leader_can_edit(requester))
		return FALSE
	if(length(objective_specs) >= ANTAG_TRAINING_CUSTOM_OBJECTIVES)
		requester.practice_message("Целей уже [ANTAG_TRAINING_CUSTOM_OBJECTIVES], больше не добавить.")
		return FALSE
	var/spec = build_custom_objective(params["kind"], params["side"], params)
	if(istext(spec))
		requester.practice_message(spec)
		return FALSE
	objective_specs += list(spec)
	return TRUE

/datum/antag_training_scenario/proc/remove_custom_objective(datum/antag_training_session/requester, index)
	if(!objectives_editable || !leader_can_edit(requester))
		return FALSE
	index = isnum(index) ? index : text2num(index)
	if(!isnum(index) || index < 1 || index > length(objective_specs) || index != round(index))
		return FALSE
	objective_specs.Cut(index, index + 1)
	return TRUE

/// Цели своей сборки до старта: подпись и сторона.
/datum/antag_training_scenario/proc/objective_spec_entries()
	. = list()
	for(var/list/spec as anything in objective_specs)
		var/datum/antag_training_scenario_objective/objective_type = spec[1]
		var/list/params = length(spec) >= 3 ? spec[3] : null
		. += list(list("name" = params?["name"] || initial(objective_type.name), "side" = spec[2], "side_name" = side_name(spec[2])))

/// Партия без исхода не стартует: у цели нет исполнителей, её противник пуст или соперников нет вовсе.
/datum/antag_training_scenario/proc/objective_side_problem()
	for(var/list/spec as anything in objective_specs)
		var/datum/antag_training_scenario_objective/objective_type = spec[1]
		var/list/params = length(spec) >= 3 ? spec[3] : null
		var/objective_name = params?["name"] || initial(objective_type.name)
		var/list/members = side_members(spec[2])
		if(!length(members))
			// В шаблоне сторона без участников просто не играет, в своей сборке её цель - ошибка листа.
			if(objectives_editable)
				return "У стороны «[side_name(spec[2])]» есть цель «[objective_name]», но в её слотах никого."
			continue
		var/target = params?["target"]
		if(target && !length(side_members(target)))
			return "Цель «[objective_name]» стороны «[side_name(spec[2])]» направлена на сторону «[side_name(target)]», но в её слотах никого."
		if(ispath(objective_type, /datum/antag_training_scenario_objective/last_standing) && length(members) == length(assigned()))
			return "Цель «[objective_name]» требует соперников: все участники на стороне «[side_name(spec[2])]»."
	return null

#undef ANTAG_TRAINING_CUSTOM_PATIENTS
#undef ANTAG_TRAINING_CUSTOM_OBJECTIVES
