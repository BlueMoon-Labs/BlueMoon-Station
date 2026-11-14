/// Старт дольше этого считается сорванным: лист возвращается к разбору слотов.
#define ANTAG_TRAINING_SCENARIO_START_TIMEOUT (2 MINUTES)

GLOBAL_LIST_EMPTY(antag_training_scenarios)
GLOBAL_LIST_EMPTY(antag_training_scenario_entries)
GLOBAL_LIST_INIT(antag_training_scenario_actions, list("scenario_pick", "scenario_cancel", "scenario_book", "scenario_take", "scenario_leave", "scenario_assign", "scenario_slot_add", "scenario_slot_edit", "scenario_slot_remove", "scenario_start", "scenario_end", "scenario_replay", "scenario_swap", "scenario_finish", "scenario_objective_add", "scenario_objective_remove"))
/// Действия пульта, открытые участнику идущей партии; остальные закрыты до итога. Снаряжение пульта открыто: на нём держится «Королевская битва».
GLOBAL_LIST_INIT(antag_training_scenario_allowed_actions, list("equipment", "exit", "practice_stop", "exercise_stop", "exercise_hint", "duel_cancel", "reset_cancel"))
/// Почему закрыто действие пульта участнику идущей партии; без записи - общий отказ.
GLOBAL_LIST_INIT(antag_training_scenario_locked_actions, list(
	"restart" = "роль и программу задаёт ваш слот",
	"set_role" = "роль и программу задаёт ваш слот",
	"heal" = "восстановление пультом недоступно",
	"hub" = "переходы пультом недоступны",
	"move" = "переходы пультом недоступны",
	"sector_enter" = "переходы пультом недоступны",
	"kit" = "комплект переносит в свою зону, а переходы пультом недоступны",
	"practice" = "практика, упражнения и дуэли недоступны",
	"exercise_start" = "практика, упражнения и дуэли недоступны",
	"duel_request" = "практика, упражнения и дуэли недоступны",
	"duel_accept" = "практика, упражнения и дуэли недоступны",
	"spawn" = "учебные цели не создаются и не меняются",
	"target_heal" = "учебные цели не создаются и не меняются",
	"target_delete" = "учебные цели не создаются и не меняются",
	"target_hunt" = "учебные цели не создаются и не меняются",
	"target_injure" = "учебные цели не создаются и не меняются",
	"target_condition" = "учебные цели не создаются и не меняются",
	"clean_personal" = "учебные цели не создаются и не меняются",
))

/datum/antag_training_session
	/// Сценарий пересобирает тело сам и ставит его на метку стороны: сектор программы не открывается.
	var/scenario_placing = FALSE

/datum/antag_training_program
	/// Кнопки программы, открытые участнику идущей партии; остальные закрыты до итога.
	var/list/scenario_safe_options = list()

/obj/effect/landmark/antag_training/side
	name = "training mark: scenario side"
	/// Ключ стороны, на который ссылаются шаблоны сценариев.
	var/side

/obj/effect/landmark/antag_training/brig
	name = "training mark: brig"
	mark_id = "brig"

/obj/effect/landmark/antag_training/arrivals
	name = "training mark: arrivals"
	mark_id = "arrivals"

/obj/effect/landmark/antag_training/casualties
	name = "training mark: casualties"
	mark_id = "casualties"

/proc/antag_training_scenarios()
	if(!length(GLOB.antag_training_scenarios))
		var/list/found = list()
		for(var/datum/antag_training_scenario/scenario_type as anything in subtypesof(/datum/antag_training_scenario))
			if(initial(scenario_type.id))
				var/datum/antag_training_scenario/template = new scenario_type
				found[template.id] = template
		GLOB.antag_training_scenarios = sortTim(found, GLOBAL_PROC_REF(cmp_antag_training_scenarios), TRUE)
	return GLOB.antag_training_scenarios

/proc/cmp_antag_training_scenarios(datum/antag_training_scenario/first, datum/antag_training_scenario/second)
	return first.order - second.order

/proc/antag_training_scenario_entries()
	if(!length(GLOB.antag_training_scenario_entries))
		var/list/templates = antag_training_scenarios()
		for(var/template_id in templates)
			var/datum/antag_training_scenario/template = templates[template_id]
			GLOB.antag_training_scenario_entries += list(template.catalog_entry())
	return GLOB.antag_training_scenario_entries

/// Вернуть участнику роль и программу, с которыми он пришёл в сценарий, и поставить его в вестибюль хаба.
/proc/antag_training_scenario_restore(datum/antag_training_session/session, role_id, program_type)
	while(!QDELETED(session) && !session.finished && (session.resetting || session.arena?.resetting))
		stoplag()
	if(QDELETED(session) || session.finished || !session.arena)
		return FALSE
	session.role = antag_training_role(role_id) || antag_training_role(ANTAG_TRAINING_ROLE_DEFAULT)
	session.next_restart_at = 0
	session.scenario_placing = TRUE
	. = session.restart(program_type)
	if(QDELETED(session))
		return
	session.scenario_placing = FALSE
	if(. && session.current_body)
		session.current_body.forceMove(session.arena.hub_arrival())

/// Место проведения сценария. Площадки хаба наследуют этот интерфейс; движок сценария сектора напрямую не трогает.
/datum/antag_training_venue
	var/datum/antag_training_arena/arena

/datum/antag_training_venue/New(datum/antag_training_arena/owner)
	arena = owner

/datum/antag_training_venue/Destroy()
	arena = null
	return ..()

/// Ключ места: один на сектор или площадку.
/datum/antag_training_venue/proc/id()
	return null

/datum/antag_training_venue/proc/name()
	return "Место проведения"

/// «сектор» или «площадка» для сообщений; accusative - винительный падеж.
/datum/antag_training_venue/proc/noun(accusative = FALSE)
	return "сектор"

/// «в секторе «Имя»» или «на площадке «Имя»» для отказов.
/datum/antag_training_venue/proc/where()
	return "в секторе «[name()]»"

/// Загружено и готово принять участников.
/datum/antag_training_venue/proc/ready()
	return FALSE

/// Место закреплено за группой.
/datum/antag_training_venue/proc/held_by(datum/antag_training_squad/squad)
	return FALSE

/// Закрепляет место за группой; отказ объясняет requester. TRUE - бронь есть или поставлена.
/datum/antag_training_venue/proc/book(datum/antag_training_squad/squad, datum/antag_training_session/requester)
	return FALSE

/datum/antag_training_venue/proc/release(datum/antag_training_squad/squad, reason)
	return FALSE

/// Возвращает обстановку в исходное состояние; может спать. TRUE - место готово.
/datum/antag_training_venue/proc/reset()
	return FALSE

/// list(x1, x2, y1, y2) на z арены.
/datum/antag_training_venue/proc/area_bounds()
	return null

/// Ключ зоны арены, куда ставятся учебные цели (spawn_creature).
/datum/antag_training_venue/proc/target_zone()
	return null

/// Клетки меток стороны: ключ берётся из шаблона.
/datum/antag_training_venue/proc/side_turfs(side_key)
	return list()

/// Все ключи меток сторон места: своя сборка раскладывает стороны по ним по порядку.
/datum/antag_training_venue/proc/side_keys()
	return list()

/// Клетка именной метки (хранилище, кабинет) или null.
/datum/antag_training_venue/proc/mark_turf(mark_id)
	return null

/// Клетки зоны (бриг, прибытие) или null.
/datum/antag_training_venue/proc/zone_turfs(zone_id)
	return null

/// Свободный пол места: запас, если у стороны нет меток.
/datum/antag_training_venue/proc/floor_turfs()
	return list()

/// Область, чьё питание чинят в «Блэкауте».
/datum/antag_training_venue/proc/power_area()
	return null

/// Сектор под местом, если это сектор: цели с машинами сектора (пробой) работают только там.
/datum/antag_training_venue/proc/sector()
	return null

/datum/antag_training_venue/proc/contains(atom/thing)
	var/list/limits = area_bounds()
	return limits && arena?.inside_bounds(get_turf(thing), limits)

/datum/antag_training_venue/proc/free_spot(turf/center)
	var/list/limits = area_bounds()
	return limits ? arena?.free_spot(center, limits) : null

/// Клетка для стороны index из total, когда меток нет: стороны расходятся по полу места.
/datum/antag_training_venue/proc/spread_turf(index, total)
	var/list/floors = floor_turfs()
	if(!length(floors))
		return null
	return floors[clamp(round((index - 0.5) / max(1, total) * length(floors)) + 1, 1, length(floors))]

/datum/antag_training_venue/sector
	var/datum/antag_training_sector/place

/datum/antag_training_venue/sector/New(datum/antag_training_arena/owner, datum/antag_training_sector/target)
	..()
	place = target

/datum/antag_training_venue/sector/Destroy()
	place = null
	return ..()

/datum/antag_training_venue/sector/id()
	return place?.id

/datum/antag_training_venue/sector/name()
	return place?.name || ..()

/datum/antag_training_venue/sector/ready()
	return place?.state == ANTAG_TRAINING_SECTOR_READY

/datum/antag_training_venue/sector/held_by(datum/antag_training_squad/squad)
	return !!place && squad?.sector == place

/datum/antag_training_venue/sector/book(datum/antag_training_squad/squad, datum/antag_training_session/requester)
	if(held_by(squad))
		return TRUE
	return squad?.book(requester, place)

/datum/antag_training_venue/sector/release(datum/antag_training_squad/squad, reason)
	return held_by(squad) && squad.release(reason)

/datum/antag_training_venue/sector/reset()
	if(!place?.load())
		return FALSE
	while(arena && !arena.finished && (arena.resetting || world.time < arena.next_reset_at))
		stoplag()
	if(QDELETED(src) || !arena || arena.finished)
		return FALSE
	return arena.reset_zone(place.id) && ready()

/datum/antag_training_venue/sector/area_bounds()
	return place?.bounds

/datum/antag_training_venue/sector/target_zone()
	return place?.id

/datum/antag_training_venue/sector/side_turfs(side_key)
	. = list()
	if(!ready())
		return
	for(var/list/offset as anything in place.side_offsets[side_key])
		. += locate(place.origin_x + offset[1], place.origin_y + offset[2], arena.private_level.z_value)

/datum/antag_training_venue/sector/side_keys()
	. = list()
	if(!ready())
		return
	for(var/side_key in place.scenario_side_order)
		if(place.side_offsets[side_key])
			. += side_key
	var/list/rest = list()
	for(var/side_key in place.side_offsets)
		if(!(side_key in .))
			rest += side_key
	. += sort_list(rest)

/datum/antag_training_venue/sector/mark_turf(mark_id)
	return place?.landmark_turf(mark_id)

/datum/antag_training_venue/sector/zone_turfs(zone_id)
	var/turf/start = place_turf(zone_id)
	return start ? antag_training_room_turfs(start, place) : null

/datum/antag_training_venue/sector/floor_turfs()
	. = list()
	if(!ready())
		return
	for(var/turf/open/floor/tile in place.turfs)
		if(!tile.is_blocked_turf())
			. += tile

/datum/antag_training_venue/sector/power_area()
	return place?.sector_area

/datum/antag_training_venue/sector/sector()
	return place

/// Слот листа сценария: сторона, роль и программа, сколько мест и обязателен ли.
/datum/antag_training_scenario_slot
	var/side
	var/label
	var/role_id = ANTAG_TRAINING_ROLE_DEFAULT
	/// null - «Снаряжение и бой».
	var/program_type
	var/count = 1
	var/required = FALSE
	/// Ключ меток, если слот встаёт не там, где его сторона.
	var/spawn_key
	var/list/datum/antag_training_session/occupants = list()

/datum/antag_training_scenario_slot/New(side_id, slot_label, slot_role, slot_program, seats = 1, is_required = FALSE, slot_spawn)
	side = side_id
	role_id = slot_role || ANTAG_TRAINING_ROLE_DEFAULT
	program_type = slot_program
	count = clamp(round(seats), 1, ANTAG_TRAINING_SCENARIO_SLOT_SEATS)
	required = !!is_required
	spawn_key = slot_spawn
	label = slot_label || default_label()

/datum/antag_training_scenario_slot/Destroy()
	occupants.Cut()
	return ..()

/datum/antag_training_scenario_slot/proc/program_or_free()
	return program_type || /datum/antag_training_program/free

/datum/antag_training_scenario_slot/proc/program_name()
	var/datum/antag_training_program/program = program_or_free()
	return initial(program.name)

/datum/antag_training_scenario_slot/proc/default_label()
	if(program_type)
		return program_name()
	var/datum/antag_training_role/slot_role = antag_training_role(role_id)
	return slot_role?.name || "Участник"

/datum/antag_training_scenario_slot/proc/free_seats()
	return max(0, count - length(occupants))

/// Почему роль и программа не уживаются в одном слоте, или null.
/proc/antag_training_scenario_slot_refusal(role_id, program_type)
	var/datum/antag_training_role/slot_role = antag_training_role(role_id)
	if(!slot_role)
		return "Такой роли нет."
	if(program_type && !antag_training_program_selectable(program_type))
		return "Такой программы нет."
	if(!antag_training_role_compatible(program_type || /datum/antag_training_program/free, slot_role))
		var/datum/antag_training_program/program = program_type
		return "Программа «[initial(program.name)]» не работает с ролью «[slot_role.name]»: ей нужно человеческое тело. Выберите должность экипажа или программу «Снаряжение и бой»."
	return null

/proc/antag_training_scenario_program(value)
	if(!istext(value) || !length(value))
		return null
	var/program_type = text2path(value)
	return antag_training_program_selectable(program_type) ? program_type : FALSE

/// Шаблон сценария, а экземпляр с группой - идущая партия по этому шаблону.
/datum/antag_training_scenario
	var/id
	var/name
	var/desc
	var/order = 0
	/// id сектора; null - любой сектор или площадка хаба на выбор лидера.
	var/sector
	/// Быстрый сценарий площадки: пресет, который грузится на старте. Площадку группа получает сама.
	var/pad_preset
	var/min_players = 1
	var/max_players = ANTAG_TRAINING_SCENARIO_SLOTS
	/// 0 - без ограничения: партия идёт до целей или до ручного конца.
	var/time_limit = 15 MINUTES
	/// Чья победа, если время вышло, а цели не выполнены; null - ничья.
	var/timeout_winner
	/// id стороны -> list("name" = подпись, "spawn" = ключ меток места).
	var/list/sides = list()
	/// list(сторона, подпись, роль, программа, мест, обязателен[, ключ меток]).
	var/list/slot_specs = list()
	/// list(тип цели, сторона[, параметры]).
	var/list/objective_specs = list()

	var/datum/antag_training_squad/squad
	var/datum/antag_training_venue/venue
	var/phase = ANTAG_TRAINING_SCENARIO_SETUP
	var/list/datum/antag_training_scenario_slot/slots = list()
	var/list/datum/antag_training_scenario_objective/objectives = list()
	/// Сеанс -> list(id роли, тип программы) до первого старта: «Завершить» возвращает их.
	var/list/previous = list()
	var/list/start_defeats = list()
	var/list/eliminated = list()
	/// Имена ушедших из группы посреди партии.
	var/list/departed = list()
	var/list/datum/weakref/props = list()
	/// Когда нажали «Старт»: метка этого запуска, сорванный старт по ней снимается.
	var/starting_since = 0
	var/started_at = 0
	var/ended_at = 0
	var/runs = 0
	var/list/summary
	var/check_timer

/datum/antag_training_scenario/New(datum/antag_training_squad/owner, datum/target)
	if(!owner)
		return
	squad = owner
	if(istype(target, /datum/antag_training_hub_pad))
		venue = new /datum/antag_training_venue/pad(owner.arena, target, pad_preset)
	else
		venue = new /datum/antag_training_venue/sector(owner.arena, target)
	for(var/list/spec as anything in slot_specs)
		slots += new /datum/antag_training_scenario_slot(spec[1], spec[2], spec[3], spec[4], spec[5], spec[6], length(spec) >= 7 ? spec[7] : null)

/datum/antag_training_scenario/Destroy()
	deltimer(check_timer)
	check_timer = null
	clear_run()
	QDEL_LIST(slots)
	QDEL_NULL(venue)
	if(squad?.scenario == src)
		squad.scenario = null
	squad = null
	previous.Cut()
	return ..()

/datum/antag_training_scenario/proc/catalog_entry()
	var/list/side_names = list()
	for(var/side_id in sides)
		side_names += side_name(side_id)
	return list("id" = id, "name" = name, "desc" = desc, "sector" = sector, "pad_preset" = pad_preset, "pad_preset_name" = pad_preset ? antag_training_pad_preset_name(pad_preset) : null, "min_players" = min_players, "max_players" = max_players, "minutes" = time_limit / (1 MINUTES), "sides" = side_names, "order" = order)

/datum/antag_training_scenario/proc/side_name(side_id)
	return sides[side_id]?["name"] || side_id

/datum/antag_training_scenario/proc/announce(message)
	squad?.announce(message)

/datum/antag_training_scenario/proc/add_prop(atom/movable/thing)
	props += WEAKREF(thing)

/datum/antag_training_scenario/proc/clear_run()
	for(var/datum/antag_training_scenario_objective/objective as anything in objectives)
		objective.teardown()
	QDEL_LIST(objectives)
	for(var/datum/weakref/prop_ref as anything in props)
		var/atom/movable/thing = prop_ref.resolve()
		if(!QDELETED(thing))
			if(isliving(thing))
				var/mob/living/body = thing
				QDEL_NULL(body.mind)
			qdel(thing)
	props.Cut()
	start_defeats.Cut()
	eliminated.Cut()
	departed.Cut()

/datum/antag_training_scenario/proc/leader_can_edit(datum/antag_training_session/requester)
	if(requester != squad?.leader)
		requester?.practice_message("Слоты сценария правит лидер группы.")
		return FALSE
	if(phase != ANTAG_TRAINING_SCENARIO_SETUP && phase != ANTAG_TRAINING_SCENARIO_SUMMARY)
		requester.practice_message("Слоты меняются до старта или после итога.")
		return FALSE
	return TRUE

/datum/antag_training_scenario/proc/slot_of(datum/antag_training_session/session)
	for(var/datum/antag_training_scenario_slot/slot as anything in slots)
		if(session in slot.occupants)
			return slot
	return null

/datum/antag_training_scenario/proc/assigned()
	. = list()
	for(var/datum/antag_training_scenario_slot/slot as anything in slots)
		. += slot.occupants

/datum/antag_training_scenario/proc/side_members(side_id)
	. = list()
	for(var/datum/antag_training_scenario_slot/slot as anything in slots)
		if(slot.side == side_id)
			. += slot.occupants

/datum/antag_training_scenario/proc/seat(datum/antag_training_session/session, datum/antag_training_scenario_slot/slot)
	if(!slot.free_seats())
		return FALSE
	var/datum/antag_training_scenario_slot/current = slot_of(session)
	current?.occupants -= session
	slot.occupants += session
	return TRUE

/datum/antag_training_scenario/proc/take_slot(datum/antag_training_session/session, datum/antag_training_scenario_slot/slot)
	if(!slot || phase == ANTAG_TRAINING_SCENARIO_STARTING || phase == ANTAG_TRAINING_SCENARIO_RUNNING || !(session in squad.members))
		return FALSE
	if(session in slot.occupants)
		return TRUE
	if(!seat(session, slot))
		session.practice_message("В слоте «[slot.label]» нет свободных мест.")
		return FALSE
	return TRUE

/datum/antag_training_scenario/proc/leave_slot(datum/antag_training_session/session)
	if(phase == ANTAG_TRAINING_SCENARIO_STARTING || phase == ANTAG_TRAINING_SCENARIO_RUNNING)
		return FALSE
	var/datum/antag_training_scenario_slot/slot = slot_of(session)
	slot?.occupants -= session
	return !!slot

/datum/antag_training_scenario/proc/assign(datum/antag_training_session/requester, datum/antag_training_session/target, datum/antag_training_scenario_slot/slot)
	if(!leader_can_edit(requester) || !(target in squad.members))
		return FALSE
	if(!slot)
		var/datum/antag_training_scenario_slot/current = slot_of(target)
		current?.occupants -= target
		return TRUE
	if(target in slot.occupants)
		return TRUE
	if(!seat(target, slot))
		requester.practice_message("В слоте «[slot.label]» нет свободных мест.")
		return FALSE
	to_chat(target.current_body, span_notice("Лидер ставит вас в слот «[slot.label]» сценария «[name]»."))
	return TRUE

/datum/antag_training_scenario/proc/add_slot(datum/antag_training_session/requester, list/params)
	if(!leader_can_edit(requester))
		return null
	if(length(slots) >= ANTAG_TRAINING_SCENARIO_SLOTS)
		requester.practice_message("В листе уже [ANTAG_TRAINING_SCENARIO_SLOTS] слотов.")
		return null
	var/side_id = params["side"]
	if(!istext(side_id) || !sides[side_id])
		side_id = sides[1]
	var/role_id = istext(params["role"]) ? params["role"] : ANTAG_TRAINING_ROLE_DEFAULT
	var/program_type = antag_training_scenario_program(params["program"])
	if(program_type == FALSE)
		requester.practice_message("Такой программы нет.")
		return null
	var/refusal = antag_training_scenario_slot_refusal(role_id, program_type)
	if(refusal)
		requester.practice_message(refusal)
		return null
	var/seats = isnum(params["count"]) ? round(params["count"]) : 1
	var/datum/antag_training_scenario_slot/slot = new(side_id, antag_training_scenario_label(params["label"]), role_id, program_type, seats, params["required"] == TRUE)
	slots += slot
	return slot

/datum/antag_training_scenario/proc/remove_slot(datum/antag_training_session/requester, datum/antag_training_scenario_slot/slot)
	if(!slot || !leader_can_edit(requester))
		return FALSE
	slots -= slot
	qdel(slot)
	return TRUE

/datum/antag_training_scenario/proc/edit_slot(datum/antag_training_session/requester, datum/antag_training_scenario_slot/slot, field, value)
	if(!slot || !leader_can_edit(requester))
		return FALSE
	switch(field)
		if("role")
			var/refusal = istext(value) ? antag_training_scenario_slot_refusal(value, slot.program_type) : "Такой роли нет."
			if(refusal)
				requester.practice_message(refusal)
				return FALSE
			slot.role_id = value
		if("program")
			var/program_type = antag_training_scenario_program(value)
			var/refusal = program_type == FALSE ? "Такой программы нет." : antag_training_scenario_slot_refusal(slot.role_id, program_type)
			if(refusal)
				requester.practice_message(refusal)
				return FALSE
			slot.program_type = program_type
		if("side")
			if(!istext(value) || !sides[value])
				return FALSE
			slot.side = value
		if("count")
			if(!isnum(value))
				return FALSE
			slot.count = clamp(round(value), 1, ANTAG_TRAINING_SCENARIO_SLOT_SEATS)
			while(length(slot.occupants) > slot.count)
				slot.occupants.Cut(length(slot.occupants))
		if("required")
			slot.required = !!value
		if("label")
			var/label = antag_training_scenario_label(value)
			if(!label)
				return FALSE
			slot.label = label
		else
			return FALSE
	return TRUE

/proc/antag_training_scenario_label(raw_label)
	if(!istext(raw_label))
		return null
	var/label = copytext_char(raw_label, 1, ANTAG_TRAINING_SCENARIO_LABEL_LENGTH * 2)
	label = trim(strip_html_simple(sanitize_simple(label, list("\n" = " ", "\t" = " "))), ANTAG_TRAINING_SCENARIO_LABEL_LENGTH + 1)
	return length(label) ? label : null

/// Почему партию сейчас не начать, или null.
/datum/antag_training_scenario/proc/start_problem()
	if(phase == ANTAG_TRAINING_SCENARIO_STARTING)
		return "Сценарий уже запускается."
	if(phase == ANTAG_TRAINING_SCENARIO_RUNNING)
		return "Сценарий уже идёт."
	if(!venue.held_by(squad))
		return "Сначала займите [venue.noun(TRUE)] «[venue.name()]» для группы."
	var/total = 0
	for(var/datum/antag_training_scenario_slot/slot as anything in slots)
		if(slot.required && !length(slot.occupants))
			return "Обязательный слот «[slot.label]» пуст."
		total += length(slot.occupants)
	if(!total)
		return "Никто не занял слот."
	if(total < min_players)
		return "Нужно хотя бы [min_players] участника в слотах, сейчас [total]."
	if(total > max_players)
		return "В этом сценарии не больше [max_players] участников, в слотах [total]."
	return objective_side_problem()

/datum/antag_training_scenario/proc/request_start(datum/antag_training_session/requester)
	if(requester != squad?.leader)
		requester?.practice_message("Сценарий запускает лидер группы.")
		return FALSE
	if(!venue.held_by(squad) && !venue.book(squad, requester))
		return FALSE
	var/problem = start_problem()
	if(problem)
		requester.practice_message(problem)
		return FALSE
	phase = ANTAG_TRAINING_SCENARIO_STARTING
	starting_since = world.time
	INVOKE_ASYNC(src, PROC_REF(launch), starting_since)
	return TRUE

/// Запуск token ещё в силе: его не сорвали по времени и не сменили новым «Стартом».
/datum/antag_training_scenario/proc/launching(token)
	return !QDELETED(src) && phase == ANTAG_TRAINING_SCENARIO_STARTING && starting_since == token

/datum/antag_training_scenario/proc/launch(token)
	deltimer(check_timer)
	check_timer = null
	clear_run()
	summary = null
	announce("Сценарий «[name]»: [venue.noun()] «[venue.name()]» сбрасывается, тела собираются по слотам.")
	var/ready = venue.reset()
	if(!launching(token))
		return
	if(!ready || !venue.held_by(squad))
		abort_start("[capitalize(venue.noun())] «[venue.name()]» не удалось подготовить, сценарий не начался.")
		return
	// Цели проверяются до пересборки тел: сорванный старт не меняет никому роль.
	var/patients = 0
	for(var/list/spec as anything in objective_specs)
		var/objective_type = spec[1]
		var/datum/antag_training_scenario_objective/objective = new objective_type(src, spec[2], length(spec) >= 3 ? spec[3] : null)
		objectives += objective
		var/problem = objective.bind_problem()
		if(problem)
			abort_start("Цель «[objective.name]» не подготовить: [problem].")
			return
		patients += objective.targets_needed()
	if(patients && !venue.arena.has_target_room(patients))
		abort_start("Пострадавших для целей не поставить. [venue.arena.target_limit_refusal()]")
		return
	var/list/spawn_counts = list()
	for(var/datum/antag_training_scenario_slot/slot as anything in slots)
		for(var/datum/antag_training_session/member as anything in slot.occupants.Copy())
			if(!(member in squad.members) || member.finished)
				slot.occupants -= member
				continue
			if(!previous[member])
				previous[member] = list(member.role.id, member.program.type)
			var/spawn_key = slot.spawn_key || sides[slot.side]?["spawn"] || slot.side
			spawn_counts[spawn_key]++
			var/placed = place_member(member, slot, spawn_key, spawn_counts[spawn_key])
			if(!launching(token))
				return
			if(!placed)
				slot.occupants -= member
				if(!QDELETED(member) && !member.finished)
					announce("[member.squad_name()] не удалось собрать по слоту «[slot.label]»: участник смотрит со стороны.")
	if(!length(assigned()))
		abort_start("В слотах никого не осталось, сценарий не начался.")
		return
	for(var/datum/antag_training_scenario_objective/objective as anything in objectives)
		var/prepared = objective.bind()
		if(!launching(token))
			return
		if(prepared != TRUE)
			abort_start("Цель «[objective.name]» не подготовить: [prepared || "нет нужной обстановки"].")
			return
	for(var/datum/antag_training_session/member as anything in assigned())
		start_defeats[member] = member.defeats
	started_at = world.time
	ended_at = 0
	runs++
	phase = ANTAG_TRAINING_SCENARIO_RUNNING
	log_game("Полигон: группа «[squad.name]» начинает сценарий «[name]», место «[venue.name()]», участников [length(assigned())].")
	announce("Сценарий «[name]» начался.[time_limit ? " На партию [time_limit / (1 MINUTES)] мин." : ""] Цели и время - во вкладке «Сценарий» пульта.")
	check_timer = addtimer(CALLBACK(src, PROC_REF(tick)), ANTAG_TRAINING_SCENARIO_CHECK, TIMER_STOPPABLE)

/datum/antag_training_scenario/proc/abort_start(reason)
	clear_run()
	phase = ANTAG_TRAINING_SCENARIO_SETUP
	starting_since = 0
	venue?.phase_changed()
	announce(reason)

/// Запуск упал или завис дольше ANTAG_TRAINING_SCENARIO_START_TIMEOUT: лист снова в разборе слотов.
/datum/antag_training_scenario/proc/check_stale_start()
	if(phase != ANTAG_TRAINING_SCENARIO_STARTING || world.time < starting_since + ANTAG_TRAINING_SCENARIO_START_TIMEOUT)
		return FALSE
	log_game("Полигон: сценарий «[name]» группы «[squad?.name]» не начался за [ANTAG_TRAINING_SCENARIO_START_TIMEOUT / (1 MINUTES)] мин, старт снят.")
	for(var/datum/antag_training_session/member as anything in squad?.members)
		member.scenario_placing = FALSE
	abort_start("Сценарий «[name]» не начался за [ANTAG_TRAINING_SCENARIO_START_TIMEOUT / (1 MINUTES)] мин: старт сорван. Проверьте слоты и нажмите «Старт» снова.")
	return TRUE

/// Партия собирается или идёт.
/datum/antag_training_scenario/proc/in_play()
	check_stale_start()
	return phase == ANTAG_TRAINING_SCENARIO_STARTING || phase == ANTAG_TRAINING_SCENARIO_RUNNING

/datum/antag_training_scenario/proc/has_prop(atom/movable/thing)
	for(var/datum/weakref/prop_ref as anything in props)
		if(prop_ref.resolve() == thing)
			return TRUE
	return FALSE

/// Админ в режиме стенда проходит на любое место, в том числе на чужую партию.
/datum/antag_training_session/proc/stand_full()
	return stand_active() && stand_access() == ANTAG_TRAINING_STAND_FULL

/// Участник идущей партии не переходит платформами: врата и платформа возврата закрыты ему, как переходы пультом.
/datum/antag_training_session/proc/scenario_transit_refusal()
	if(scenario_placing || stand_full())
		return null
	var/datum/antag_training_scenario/current = scenario_in_play()
	return current ? "Идёт сценарий «[current.name]»: участник партии не переходит платформами. Это снова можно после итога или кнопкой «Завершить»." : null

/// Пускают ли сеанс на место партии: только участников, не выбывших, и админа стенда.
/datum/antag_training_scenario/proc/entry_refusal(datum/antag_training_session/session)
	if(session?.stand_full())
		return null
	if(!slot_of(session))
		return "Идёт сценарий «[name]»: на [venue.noun(TRUE)] «[venue.name()]» пускают только участников партии. Смотрите её на экранах трибуны в вестибюле хаба."
	if(eliminated[session])
		return "Вы выбыли из сценария «[name]»: смотрите партию на экранах трибуны в вестибюле хаба."
	return null

/// Почему creator не ставит цели на место идущей партии, или null. Сборка партии и её участники ставят, зрители и посторонние - только стендом.
/datum/antag_training_scenario/proc/target_refusal(datum/antag_training_session/creator)
	if(!creator || phase != ANTAG_TRAINING_SCENARIO_RUNNING || creator.stand_active() || slot_of(creator))
		return null
	return "Идёт сценарий «[name]»: цели на [venue.noun(TRUE)] «[venue.name()]» до итога ставит только сама партия."

/// Посторонний или выбывший, который всё же оказался на месте партии, выходит в вестибюль хаба.
/datum/antag_training_scenario/proc/evict_outsiders()
	for(var/datum/antag_training_session/member as anything in venue.arena.members)
		var/mob/living/body = member.current_body
		if(!isliving(body) || body.stat == DEAD || !venue.contains(body))
			continue
		var/refusal = entry_refusal(member)
		if(!refusal)
			continue
		body.throwing?.finalize(FALSE)
		body.forceMove(venue.arena.hub_arrival())
		member.practice_message(refusal)

/datum/antag_training_scenario/proc/place_member(datum/antag_training_session/member, datum/antag_training_scenario_slot/slot, spawn_key, number)
	var/datum/antag_training_role/slot_role = antag_training_role(slot.role_id)
	var/program_type = slot.program_or_free()
	if(!slot_role || !antag_training_role_compatible(program_type, slot_role))
		return FALSE
	while(!QDELETED(member) && !member.finished && (member.resetting || member.arena?.resetting))
		stoplag()
	if(QDELETED(src) || QDELETED(member) || member.finished)
		return FALSE
	member.role = slot_role
	member.next_restart_at = 0
	member.scenario_placing = TRUE
	var/rebuilt = member.restart(program_type)
	if(QDELETED(member))
		return FALSE
	member.scenario_placing = FALSE
	if(!rebuilt || member.finished || QDELETED(member.current_body))
		return FALSE
	var/turf/spot = spawn_spot(spawn_key, number)
	if(spot)
		member.current_body.forceMove(spot)
	to_chat(member.current_body, span_boldnotice("Сценарий «[name]»: вы - [slot.label], сторона «[side_name(slot.side)]»."))
	return TRUE

/datum/antag_training_scenario/proc/spawn_spot(spawn_key, number)
	var/list/marks = venue.side_turfs(spawn_key)
	var/side_index = sides.Find(spawn_key)
	if(!length(marks))
		var/list/keys = venue.side_keys()
		if(side_index && side_index <= length(keys))
			marks = venue.side_turfs(keys[side_index])
	var/turf/center = length(marks) ? marks[(number - 1) % length(marks) + 1] : venue.spread_turf(side_index || 1, max(1, length(sides)))
	return venue.free_spot(center) || center

/datum/antag_training_scenario/proc/member_down(datum/antag_training_session/member)
	if(eliminated[member])
		return TRUE
	var/mob/living/body = member.current_body
	if(!isliving(body))
		return FALSE
	if(body.stat == DEAD || body.health <= body.crit_threshold)
		return TRUE
	var/mob/living/carbon/prisoner = body
	return istype(prisoner) && !!prisoner.handcuffed

/datum/antag_training_scenario/proc/side_down(side_id)
	var/list/members = side_members(side_id)
	if(!length(members))
		return FALSE
	for(var/datum/antag_training_session/member as anything in members)
		if(!member_down(member))
			return FALSE
	return TRUE

/datum/antag_training_scenario/proc/update_eliminated()
	for(var/datum/antag_training_session/member as anything in assigned())
		if(!eliminated[member] && member.defeats > start_defeats[member])
			eliminated[member] = TRUE
			announce("[member.squad_name()] выбывает из сценария.")

/datum/antag_training_scenario/proc/winning_side()
	for(var/side_id in sides)
		var/has_goals = FALSE
		var/all_done = TRUE
		for(var/datum/antag_training_scenario_objective/objective as anything in objectives)
			if(objective.side != side_id)
				continue
			has_goals = TRUE
			if(!objective.done)
				all_done = FALSE
		if(has_goals && all_done)
			return side_id
	return null

/datum/antag_training_scenario/proc/tick()
	check_timer = null
	if(phase != ANTAG_TRAINING_SCENARIO_RUNNING || QDELETED(squad))
		return
	if(!venue.held_by(squad) || !venue.ready())
		end(null, "[capitalize(venue.noun())] «[venue.name()]» больше не за группой, партия остановлена.")
		return
	update_eliminated()
	evict_outsiders()
	for(var/datum/antag_training_scenario_objective/objective as anything in objectives)
		if(!objective.done && objective.check())
			objective.done = TRUE
			objective.done_at = world.time
			announce("Цель выполнена: «[objective.name]» ([side_name(objective.side)]).")
	var/side_id = winning_side()
	if(side_id)
		end(side_id, "Все цели стороны «[side_name(side_id)]» выполнены.")
		return
	if(time_limit && world.time >= started_at + time_limit)
		end(length(side_members(timeout_winner)) ? timeout_winner : null, "Время вышло.")
		return
	check_timer = addtimer(CALLBACK(src, PROC_REF(tick)), ANTAG_TRAINING_SCENARIO_CHECK, TIMER_STOPPABLE)

/// Партия закончена: итог висит в пульте до «Повтор», «Сменить стороны» или «Завершить».
/datum/antag_training_scenario/proc/end(winner_side, reason)
	if(phase != ANTAG_TRAINING_SCENARIO_RUNNING)
		return FALSE
	deltimer(check_timer)
	check_timer = null
	update_eliminated()
	phase = ANTAG_TRAINING_SCENARIO_SUMMARY
	ended_at = world.time
	venue?.phase_changed()
	var/list/out = list()
	for(var/datum/antag_training_session/member as anything in eliminated)
		out += member.squad_name()
	out += departed
	summary = list("winner" = winner_side, "winner_name" = winner_side ? side_name(winner_side) : null, "reason" = reason, "time" = round((ended_at - started_at) / (1 SECONDS)), "objectives" = objectives_entries(), "eliminated" = out)
	log_game("Полигон: сценарий «[name]» группы «[squad.name]» окончен: [winner_side ? "победа стороны «[side_name(winner_side)]»" : "без победителя"]. [reason]")
	announce("Сценарий «[name]» окончен: [winner_side ? "победа стороны «[side_name(winner_side)]»" : "без победителя"]. [reason] Итог - в пульте.")
	return TRUE

/datum/antag_training_scenario/proc/request_end(datum/antag_training_session/requester)
	if(requester != squad?.leader)
		requester?.practice_message("Остановить партию может лидер группы.")
		return FALSE
	return end(null, "Лидер остановил партию.")

/datum/antag_training_scenario/proc/replay(datum/antag_training_session/requester)
	if(phase != ANTAG_TRAINING_SCENARIO_SUMMARY)
		return FALSE
	return request_start(requester)

/// Участники каждой стороны встают в слоты следующей стороны листа; кто не влез - в свободные места.
/datum/antag_training_scenario/proc/swap_sides(datum/antag_training_session/requester)
	if(!leader_can_edit(requester))
		return FALSE
	var/list/order = list()
	for(var/side_id in sides)
		for(var/datum/antag_training_scenario_slot/slot as anything in slots)
			if(slot.side == side_id)
				order += side_id
				break
	if(length(order) < 2)
		requester.practice_message("Меняться не с кем: в листе одна сторона.")
		return FALSE
	var/list/movers = list()
	for(var/side_id in order)
		movers[side_id] = side_members(side_id)
	for(var/datum/antag_training_scenario_slot/slot as anything in slots)
		slot.occupants.Cut()
	var/list/leftover = list()
	for(var/index in 1 to length(order))
		var/destination = order[index % length(order) + 1]
		for(var/datum/antag_training_session/member as anything in movers[order[index]])
			if(!seat_on_side(member, destination))
				leftover += member
	for(var/datum/antag_training_session/member as anything in leftover)
		for(var/datum/antag_training_scenario_slot/slot as anything in slots)
			if(seat(member, slot))
				break
	announce("Стороны поменялись местами.")
	var/problem = start_problem()
	if(problem)
		phase = ANTAG_TRAINING_SCENARIO_SETUP
		requester.practice_message("Стороны поменялись, но начать нельзя: [problem] Поправьте слоты и нажмите «Старт».")
		return FALSE
	return request_start(requester)

/datum/antag_training_scenario/proc/seat_on_side(datum/antag_training_session/member, side_id)
	for(var/required_first in list(TRUE, FALSE))
		for(var/datum/antag_training_scenario_slot/slot as anything in slots)
			if(slot.side == side_id && slot.required == required_first && seat(member, slot))
				return TRUE
	return FALSE

/datum/antag_training_scenario/proc/finish(datum/antag_training_session/requester)
	if(requester != squad?.leader)
		requester?.practice_message("Завершает сценарий лидер группы.")
		return FALSE
	if(phase == ANTAG_TRAINING_SCENARIO_STARTING)
		requester.practice_message("Дождитесь, пока сценарий начнётся.")
		return FALSE
	return close("Сценарий «[name]» завершён: все возвращаются в вестибюль хаба с прежними ролями, бронь «[venue.name()]» снята.")

/// Полностью закрывает сценарий: роли до него, вестибюль хаба, снятая бронь. Для пульта стенда и админов.
/datum/antag_training_scenario/proc/force_end(reason)
	if(QDELETED(src))
		return FALSE
	return close(reason || "Сценарий «[name]» остановлен принудительно.")

/datum/antag_training_scenario/proc/close(reason)
	var/datum/antag_training_squad/team = squad
	var/list/restore = previous.Copy()
	previous.Cut()
	phase = ANTAG_TRAINING_SCENARIO_SUMMARY
	if(team)
		log_game("Полигон: группа «[team.name]» закрывает сценарий «[name]».")
		if(!venue.release(team, reason))
			team.announce(reason)
	qdel(src)
	for(var/datum/antag_training_session/member as anything in restore)
		var/list/before = restore[member]
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(antag_training_scenario_restore), member, before[1], before[2])
	return TRUE

/datum/antag_training_scenario/proc/cancel(datum/antag_training_session/requester)
	if(requester != squad?.leader || phase != ANTAG_TRAINING_SCENARIO_SETUP)
		return FALSE
	if(length(previous))
		return close("Сценарий «[name]» снят: все возвращаются с прежними ролями.")
	announce("Лидер снял сценарий «[name]».")
	qdel(src)
	return TRUE

/// Участник ушёл из группы: место в слоте освобождается, роль до сценария возвращается.
/datum/antag_training_scenario/proc/forget(datum/antag_training_session/session)
	var/datum/antag_training_scenario_slot/slot = slot_of(session)
	slot?.occupants -= session
	if(slot && phase == ANTAG_TRAINING_SCENARIO_RUNNING)
		departed += session.squad_name()
	eliminated -= session
	start_defeats -= session
	var/list/before = previous[session]
	previous -= session
	if(before && !session.finished && !QDELETED(session))
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(antag_training_scenario_restore), session, before[1], before[2])

/datum/antag_training_scenario/proc/objectives_entries()
	. = list()
	for(var/datum/antag_training_scenario_objective/objective as anything in objectives)
		. += list(list("name" = objective.name, "side" = objective.side, "side_name" = side_name(objective.side), "done" = objective.done, "progress" = objective.done ? null : objective.progress()))

/datum/antag_training_scenario/proc/ui_entry(datum/antag_training_session/viewer)
	var/list/side_entries = list()
	for(var/side_id in sides)
		side_entries += list(list("id" = side_id, "name" = side_name(side_id)))
	var/list/slot_entries = list()
	for(var/datum/antag_training_scenario_slot/slot as anything in slots)
		var/list/occupant_entries = list()
		for(var/datum/antag_training_session/member as anything in slot.occupants)
			occupant_entries += list(list("id" = REF(member), "name" = member.squad_name(), "self" = member == viewer, "out" = !!eliminated[member]))
		var/datum/antag_training_role/slot_role = antag_training_role(slot.role_id)
		slot_entries += list(list("id" = REF(slot), "side" = slot.side, "label" = slot.label, "role" = slot.role_id, "role_name" = slot_role?.name, "program" = slot.program_type ? "[slot.program_type]" : null, "program_name" = slot.program_name(), "count" = slot.count, "required" = slot.required, "occupants" = occupant_entries))
	var/list/member_entries = list()
	for(var/datum/antag_training_session/member as anything in squad.members)
		member_entries += list(list("id" = REF(member), "name" = member.squad_name(), "slot" = slot_of(member) ? REF(slot_of(member)) : null))
	var/running = phase == ANTAG_TRAINING_SCENARIO_RUNNING
	var/elapsed = running ? round((world.time - started_at) / (1 SECONDS)) : 0
	return list(
		"id" = id,
		"name" = name,
		"desc" = desc,
		"phase" = phase,
		"sector" = venue.name(),
		"sector_id" = venue.id(),
		"venue_kind" = istype(venue, /datum/antag_training_venue/pad) ? "pad" : "sector",
		"booked" = venue.held_by(squad),
		"leader" = viewer == squad.leader,
		"free_play" = !length(objective_specs),
		"min_players" = min_players,
		"max_players" = max_players,
		"time_limit" = time_limit / (1 SECONDS),
		"elapsed" = elapsed,
		"remaining" = running && time_limit ? max(0, time_limit / (1 SECONDS) - elapsed) : null,
		"sides" = side_entries,
		"slots" = slot_entries,
		"members" = member_entries,
		"my_slot" = slot_of(viewer) ? REF(slot_of(viewer)) : null,
		"objectives" = objectives_entries(),
		"objectives_editable" = objectives_editable,
		"objective_specs" = objective_spec_entries(),
		"objective_library" = objectives_editable ? objective_library() : null,
		"start_problem" = phase == ANTAG_TRAINING_SCENARIO_SETUP || phase == ANTAG_TRAINING_SCENARIO_SUMMARY ? start_problem() : null,
		"summary" = summary,
		"runs" = runs,
	)

/datum/antag_training_squad/proc/pick_scenario(datum/antag_training_session/requester, template_id, sector_id)
	if(requester != leader)
		requester.practice_message("Сценарий выбирает лидер группы.")
		return null
	var/datum/antag_training_scenario/template = istext(template_id) ? antag_training_scenarios()[template_id] : null
	if(!template)
		return null
	if(scenario && (scenario.phase != ANTAG_TRAINING_SCENARIO_SETUP || length(scenario.previous)))
		requester.practice_message("Сначала завершите сценарий «[scenario.name]» кнопкой «Завершить».")
		return null
	if(template.pad_preset || (!template.sector && istext(sector_id) && arena.hub?.pad_by_id(sector_id)))
		var/datum/antag_training_hub_pad/pad = arena.hub?.scenario_pad(src, sector_id, requester)
		if(!pad)
			return null
		if(scenario)
			qdel(scenario)
		scenario = new template.type(src, pad)
		announce("Лидер выбрал сценарий «[scenario.name]» на площадке «[pad.name]». Займите слоты во вкладке «Сценарий» пульта.")
		scenario.venue.book(src, requester)
		return scenario
	var/target_id = template.sector || (istext(sector_id) ? sector_id : sector?.id)
	var/datum/antag_training_sector/target = target_id ? arena.sectors[target_id] : null
	if(!target)
		requester.practice_message("Выберите сектор или площадку для своей сборки.")
		return null
	if(scenario)
		qdel(scenario)
	scenario = new template.type(src, target)
	announce("Лидер выбрал сценарий «[scenario.name]» в секторе «[target.name]». Займите слоты во вкладке «Сценарий» пульта.")
	if(sector != target && !sector)
		scenario.venue.book(src, requester)
	else if(sector != target)
		requester.practice_message("У группы бронь сектора «[sector.name]», а сценарий идёт в «[target.name]». Освободите бронь, «Старт» займёт нужный сектор.")
	return scenario

/datum/antag_training_session/proc/scenario_ui_data(list/data)
	data["scenario_templates"] = antag_training_scenario_entries()
	squad?.scenario?.check_stale_start()
	data["scenario"] = squad?.scenario?.ui_entry(src)

/// Сценарий группы, в слоте которого сеанс, пока партия собирается или идёт.
/datum/antag_training_session/proc/scenario_in_play()
	var/datum/antag_training_scenario/current = squad?.scenario
	return (current?.in_play() && current.slot_of(src)) ? current : null

/// Роль и программу участника партии задаёт слот: пульт, шкаф и стенд без прав админа их не меняют. Сборка тел самой партией проходит.
/datum/antag_training_session/proc/scenario_role_locked()
	if(scenario_placing)
		return FALSE
	var/datum/antag_training_scenario/current = scenario_in_play()
	if(!current)
		return FALSE
	practice_message("Идёт сценарий «[current.name]»: роль и программу задаёт ваш слот. Сменить их можно после итога или кнопкой «Завершить».")
	return TRUE

/// Почему действие пульта закрыто сценарием группы, или null.
/datum/antag_training_session/proc/scenario_refusal(action, list/params)
	var/datum/antag_training_scenario/current = squad?.scenario
	if(!current?.in_play())
		return null
	var/atom/movable/target = findtext(action, "target_") == 1 ? (locate(params["id"]) in arena.targets) : null
	if(target && current.has_prop(target))
		return "Идёт сценарий «[current.name]»: его реквизит меняет только сама партия."
	if(action == "clean_personal" && src == squad.leader && length(current.props))
		return "Идёт сценарий «[current.name]»: очистка своих объектов убрала бы реквизит партии. Она снова доступна после итога."
	if(!current.slot_of(src) || (action in GLOB.antag_training_scenario_allowed_actions) || findtext(action, "stand_") == 1)
		return null
	var/reason = GLOB.antag_training_scenario_locked_actions[action] || "это действие пульта участнику партии недоступно"
	if(action == "program_option")
		if(params["option"] in program.scenario_safe_options)
			return null
		reason = "кнопки программы участнику партии закрыты, «[params["option"]]» тоже"
	return "Идёт сценарий «[current.name]»: [reason]. Это снова можно после итога или кнопкой «Завершить»."

/// Действия сценария и запреты пульта участнику идущей партии. TRUE - действие обработано здесь.
/datum/antag_training_session/proc/scenario_intercepts(action, list/params)
	var/datum/antag_training_scenario/current = squad?.scenario
	if(action in GLOB.antag_training_scenario_actions)
		scenario_act(current, action, params)
		return TRUE
	var/refusal = scenario_refusal(action, params)
	if(refusal)
		practice_message(refusal)
		return TRUE
	return FALSE

/datum/antag_training_session/proc/scenario_act(datum/antag_training_scenario/current, action, list/params)
	current?.check_stale_start()
	if(action == "scenario_pick")
		if(!squad)
			practice_message("Сценарий запускает группа. Соберите её во вкладке «Участники».")
			return
		squad.pick_scenario(src, params["id"], params["sector"])
		return
	if(!current)
		return
	var/datum/antag_training_scenario_slot/slot = istext(params["slot"]) ? (locate(params["slot"]) in current.slots) : null
	var/datum/antag_training_session/member = istext(params["member"]) ? (locate(params["member"]) in squad.members) : null
	switch(action)
		if("scenario_cancel")
			current.cancel(src)
		if("scenario_book")
			if(src == squad.leader)
				current.venue.book(squad, src)
		if("scenario_take")
			current.take_slot(src, slot)
		if("scenario_leave")
			current.leave_slot(src)
		if("scenario_assign")
			if(member)
				current.assign(src, member, slot)
		if("scenario_slot_add")
			current.add_slot(src, params)
		if("scenario_slot_edit")
			current.edit_slot(src, slot, params["field"], params["value"])
		if("scenario_slot_remove")
			current.remove_slot(src, slot)
		if("scenario_start")
			current.request_start(src)
		if("scenario_end")
			current.request_end(src)
		if("scenario_replay")
			current.replay(src)
		if("scenario_swap")
			current.swap_sides(src)
		if("scenario_finish")
			current.finish(src)
		if("scenario_objective_add")
			current.add_custom_objective(src, params)
		if("scenario_objective_remove")
			current.remove_custom_objective(src, params["index"])

/// Свою цель программы (взрыв учебной бомбы) сценарий засчитывает стороне.
/datum/antag_training_program/proc/scenario_goal_reached(datum/antag_training_session/session)
	return FALSE

/datum/antag_training_program/antag/nukeop/scenario_goal_reached(datum/antag_training_session/session)
	return !!detonation_objective?.completed

#undef ANTAG_TRAINING_SCENARIO_START_TIMEOUT
