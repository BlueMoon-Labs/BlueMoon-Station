#define ANTAG_TRAINING_MECHANICS_ORDER 2

GLOBAL_LIST_INIT(antag_training_mechanics_sectors, list("engineering", "atmos", "eva", "robotics"))

/proc/start_antag_training(mob/user, program_type, use_character, obj/machinery/antag_training_pod/pod, role_id = ANTAG_TRAINING_ROLE_DEFAULT)
	if(QDELETED(user) || !antag_training_program_selectable(program_type) || antag_training_round_over(user))
		return null
	var/player_key = user.ckey
	if(player_key && (GLOB.antag_training_sessions[player_key] || (player_key in GLOB.antag_training_pending)))
		return null
	var/datum/antag_training_arena/shared = GLOB.antag_training_arenas["shared"]
	if(shared?.finished)
		to_chat(user, span_notice("Общий полигон очищается. Попробуйте немного позже."))
		return null
	to_chat(user, span_notice("Подготавливаем учебного персонажа и полигон. Это может занять несколько секунд."))
	if(player_key)
		GLOB.antag_training_pending |= player_key
	var/had_client = !!user.client
	var/datum/antag_training_session/session = new(program_type, use_character ? user.client?.prefs : null, role_id)
	var/prepared = session.prepare()
	if(player_key)
		GLOB.antag_training_pending -= player_key
	if(!prepared || QDELETED(user) || user.ckey != player_key || (had_client && !user.client) || jobban_isbanned(user, ROLE_GHOSTROLE) || (pod && (QDELETED(pod) || user.loc != pod)) || !session.connect(user, pod))
		qdel(session)
		return null
	return session

/datum/antag_training_catalog
	var/mob/viewer
	var/datum/weakref/entry_ref

/datum/antag_training_catalog/New(mob/viewer, atom/entry)
	src.viewer = viewer
	entry_ref = WEAKREF(entry)
	ui_interact(viewer)

/datum/antag_training_catalog/Destroy()
	SStgui.close_uis(src)
	viewer = null
	entry_ref = null
	return ..()

/datum/antag_training_catalog/ui_state(mob/user)
	return GLOB.always_state

/datum/antag_training_catalog/ui_status(mob/user, datum/ui_state/state)
	var/atom/entry = entry_ref?.resolve()
	return (user == viewer && !QDELETED(entry)) ? UI_INTERACTIVE : UI_CLOSE

/datum/antag_training_catalog/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AntagTrainingCatalog", "Тренировочный полигон")
		ui.open()

/datum/antag_training_catalog/ui_static_data(mob/user)
	var/list/sector_names = antag_training_sector_names()
	var/list/records = GLOB.antag_training_exercise_records[user.ckey] || list()
	var/list/programs = list()
	for(var/datum/antag_training_program/program_type as anything in subtypesof(/datum/antag_training_program))
		if(antag_training_program_selectable(program_type))
			programs += list(antag_training_program_entry(program_type, sector_names, records))
	return list("programs" = programs, "mechanics" = antag_training_mechanics_entry(sector_names, records), "can_load_character" = !!user.client?.prefs, "roles" = antag_training_role_entries())

/proc/antag_training_sector_names()
	. = list()
	for(var/datum/antag_training_sector/sector_type as anything in subtypesof(/datum/antag_training_sector))
		if(initial(sector_type.id))
			.[initial(sector_type.id)] = initial(sector_type.name)

/proc/antag_training_program_learn(datum/antag_training_program/program_type)
	var/learn = initial(program_type.learn)
	return learn ? splittext(learn, "|") : list()

/// Тип тела, в котором программа проходит упражнения: у существа - свой моб, у синтетика поверх программы - его корпус, иначе человек.
/proc/antag_training_program_body(datum/antag_training_program/program_type, datum/antag_training_role/role)
	if(ispath(program_type, /datum/antag_training_program/creature))
		var/datum/antag_training_program/creature/creature = program_type
		return initial(creature.mob_type) || /mob/living
	var/datum/antag_training_role/silicon/silicon = role
	if(istype(silicon) && (initial(program_type.allowed_roles) & silicon.kind))
		return silicon.mob_type
	return /mob/living/carbon/human

/// Упражнения программы, посильные её телу: упражнения её роли и общие упражнения её сектора, у «Снаряжения и боя» - общие упражнения ядра.
/proc/antag_training_program_exercises(datum/antag_training_program/program_type, list/sector_names, body_type)
	. = list()
	var/home = initial(program_type.sector)
	var/core = ispath(program_type, /datum/antag_training_program/free)
	body_type ||= antag_training_program_body(program_type)
	for(var/exercise_id in GLOB.antag_training_exercises)
		var/datum/antag_training_exercise/exercise = GLOB.antag_training_exercises[exercise_id]
		if(!exercise.fits_body(body_type))
			continue
		if(exercise.program)
			if(ispath(program_type, exercise.program))
				. += exercise_id
		else if(home ? exercise.sector == home : (core && !sector_names[exercise.sector]))
			. += exercise_id

/proc/antag_training_exercise_progress(list/exercise_ids, list/records)
	var/done = 0
	for(var/exercise_id in exercise_ids)
		if(records[exercise_id])
			done++
	return list("exercises_done" = done, "exercises_total" = length(exercise_ids))

/// Карточка программы для каталога и пульта; records = null - без прогресса упражнений.
/proc/antag_training_program_entry(datum/antag_training_program/program_type, list/sector_names, list/records)
	var/sector_id = initial(program_type.sector)
	. = list("id" = "[program_type]", "name" = initial(program_type.name), "category" = initial(program_type.category), "desc" = initial(program_type.desc), "sector" = sector_id ? sector_names[sector_id] : null, "icon" = initial(program_type.icon), "color" = initial(program_type.color), "learn" = antag_training_program_learn(program_type), "difficulty" = initial(program_type.difficulty), "order" = initial(program_type.order), "allowed_roles" = initial(program_type.allowed_roles))
	if(records)
		. += antag_training_exercise_progress(antag_training_program_exercises(program_type, sector_names), records)

/// Шаг «Механики станции» в «С чего начать»: сектора механик проходят программой «Снаряжение и бой».
/proc/antag_training_mechanics_entry(list/sector_names, list/records)
	var/datum/antag_training_program/free = /datum/antag_training_program/free
	var/list/names = list()
	for(var/sector_id in GLOB.antag_training_mechanics_sectors)
		names += sector_names[sector_id]
	var/list/exercise_ids = list()
	for(var/exercise_id in GLOB.antag_training_exercises)
		var/datum/antag_training_exercise/exercise = GLOB.antag_training_exercises[exercise_id]
		if(!exercise.program && (exercise.sector in GLOB.antag_training_mechanics_sectors))
			exercise_ids += exercise_id
	. = list("id" = "mechanics", "program" = "[free]", "name" = "Механики станции", "category" = initial(free.category), "desc" = "Питание, атмос, выход в космос и робототехника в отдельных секторах с готовыми упражнениями. Войдите программой «[initial(free.name)]» и откройте нужный сектор в пульте, во вкладке «Зоны».", "sector" = jointext(names, ", "), "icon" = "screwdriver-wrench", "color" = "yellow", "learn" = list("Генератор, кабель и щиток", "Смесь газов, пробой и пожар", "Скафандр, джетпак и шлюз", "Сборка киборга и Рипли"), "difficulty" = 2, "order" = ANTAG_TRAINING_MECHANICS_ORDER)
	. += antag_training_exercise_progress(exercise_ids, records)

/// Программы, которые ставят куклу в этот сектор при старте.
/proc/antag_training_sector_program_names(sector_id)
	. = list()
	for(var/datum/antag_training_program/program_type as anything in subtypesof(/datum/antag_training_program))
		if(antag_training_program_selectable(program_type) && initial(program_type.sector) == sector_id)
			. += initial(program_type.name)
	sortTim(., GLOBAL_PROC_REF(cmp_text_asc))

/// Шаблоны сценариев, которые проходят в этом секторе или на площадке с этим пресетом.
/proc/antag_training_venue_scenario_names(sector_id, preset_id)
	. = list()
	var/list/templates = antag_training_scenarios()
	for(var/template_id in templates)
		var/datum/antag_training_scenario/template = templates[template_id]
		if((sector_id && template.sector == sector_id) || (preset_id && template.pad_preset == preset_id))
			. += template.name

/// Где тренировать программу: её сектор (у «Снаряжения и боя» - сектора механик), сценарии с её слотом и пресеты площадок под неё.
/proc/antag_training_program_route(datum/antag_training_program/program_type)
	var/list/sector_names = antag_training_sector_names()
	var/list/sector_ids = list()
	if(initial(program_type.sector))
		sector_ids += initial(program_type.sector)
	else if(ispath(program_type, /datum/antag_training_program/free))
		sector_ids += GLOB.antag_training_mechanics_sectors
	var/list/sectors = list()
	for(var/sector_id in sector_ids)
		sectors += list(list("id" = sector_id, "name" = sector_names[sector_id]))
	var/list/scenarios = list()
	var/list/templates = antag_training_scenarios()
	for(var/template_id in templates)
		var/datum/antag_training_scenario/template = templates[template_id]
		for(var/list/spec as anything in template.slot_specs)
			if(spec[4] && ispath(program_type, spec[4]))
				scenarios += list(list("id" = template.id, "name" = template.name, "venue" = template.pad_preset ? antag_training_pad_preset_name(template.pad_preset) : sector_names[template.sector]))
				break
	var/list/presets = list()
	for(var/preset_id in GLOB.antag_training_pad_presets)
		var/list/preset = GLOB.antag_training_pad_presets[preset_id]
		for(var/program_path in preset["programs"])
			if(ispath(program_type, program_path))
				presets += list(list("id" = preset_id, "name" = preset["name"]))
				break
	return list("sectors" = sectors, "scenarios" = scenarios, "presets" = presets)

/// Маршрут программы одной строкой для стендов хаба.
/proc/antag_training_route_text(list/route)
	var/list/parts = list()
	var/list/names = list()
	for(var/list/sector as anything in route["sectors"])
		names += sector["name"]
	if(length(names))
		parts += "[length(names) > 1 ? "сектора" : "сектор"] [names.Join(", ")]"
	names = list()
	for(var/list/scenario as anything in route["scenarios"])
		names += "«[scenario["name"]]» ([scenario["venue"]])"
	if(length(names))
		parts += "сценарии [names.Join(", ")]"
	names = list()
	for(var/list/preset as anything in route["presets"])
		names += preset["name"]
	if(length(names))
		parts += "пресеты площадок: [names.Join(", ")]"
	if(!length(parts))
		return "своего сектора, сценариев и пресетов нет, учебные цели и снаряжение - в пульте"
	return parts.Join("; ")

/datum/antag_training_catalog/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(!. && action == "join_squad" && ui.user == viewer)
		return join_squad(params)
	if(. || action != "start" || ui.user != viewer || !istext(params["program"]))
		return
	var/atom/entry = entry_ref?.resolve()
	if(QDELETED(entry))
		return
	for(var/program_type in subtypesof(/datum/antag_training_program))
		if("[program_type]" != params["program"] || !antag_training_program_selectable(program_type))
			continue
		var/role_id = istext(params["role"]) && antag_training_role(params["role"]) ? params["role"] : ANTAG_TRAINING_ROLE_DEFAULT
		if(!antag_training_role_compatible(program_type, antag_training_role(role_id)))
			to_chat(viewer, span_warning("Эта программа не работает с синтетиком. Выберите должность человека или программу «Снаряжение и бой»."))
			return TRUE
		var/mob/user = viewer
		qdel(src)
		// Вход - спавнер или капсула: call() ищет begin_training и catalog_closed по имени.
		INVOKE_ASYNC(entry, TYPE_PROC_REF(/obj/effect/mob_spawn/antag_training, begin_training), user, program_type, params["use_character"] == TRUE, role_id)
		return FALSE

/datum/antag_training_catalog/ui_close(mob/user)
	if(QDELETED(src))
		return
	var/mob/closed_viewer = viewer
	var/atom/entry = entry_ref?.resolve()
	qdel(src)
	if(entry)
		INVOKE_ASYNC(entry, TYPE_PROC_REF(/obj/effect/mob_spawn/antag_training, catalog_closed), closed_viewer)

#undef ANTAG_TRAINING_MECHANICS_ORDER
