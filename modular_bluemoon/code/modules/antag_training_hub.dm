/area/antag_training/hub
	name = "Training Hub"
	dynamic_lighting = DYNAMIC_LIGHTING_ENABLED
	area_flags = NO_ALERTS | UNIQUE_AREA

/// Вестибюль хаба: безопасная зона, как центр ядра.
/area/antag_training/hub/lobby
	name = "Training Hub Lobby"

/area/antag_training/hub/station
	name = "Training Hub Station"
	area_flags = NO_ALERTS | UNIQUE_AREA | VALID_TERRITORY | BLOBS_ALLOWED | CULTMAGIC_BYPASS

/area/antag_training/hub/station/hallway
	name = "Training Hub Hallway"

/area/antag_training/hub/station/cargo
	name = "Training Hub Cargo"

/area/antag_training/hub/station/bar
	name = "Training Hub Bar"

/area/antag_training/hub/station/engineering
	name = "Training Hub Engineering"

/area/antag_training/hub/station/medbay
	name = "Training Hub Medbay"

/area/antag_training/hub/station/bridge
	name = "Training Hub Bridge"

/area/antag_training/hub/station/ai
	name = "Training Hub AI Core"

/area/antag_training/hub/station/science
	name = "Training Hub Science"

/area/antag_training/hub/station/brig
	name = "Training Hub Brig"

/area/antag_training/hub/pad
	name = "Training Hub Pad"
	area_flags = NO_ALERTS | UNIQUE_AREA | VALID_TERRITORY | BLOBS_ALLOWED | CULTMAGIC_BYPASS

/area/antag_training/hub/pad/one
	name = "Training Hub Pad 1"

/area/antag_training/hub/pad/two
	name = "Training Hub Pad 2"

/area/antag_training/hub/pad/three
	name = "Training Hub Pad 3"

/area/antag_training/hub/pad/four
	name = "Training Hub Pad 4"

/// Область одна на все загрузки: тревога и выключатель прошлой загрузки сбрасываются.
/area/antag_training/hub/proc/reset_state()
	lightswitch = TRUE
	fire = FALSE
	area_emergency_mode = FALSE
	STOP_PROCESSING(SSobj, src)
	power_change()

/proc/antag_training_map_template(map_path, name)
	var/datum/map_template/template = GLOB.antag_training_sector_templates[map_path]
	if(!template)
		template = new(map_path, name, TRUE)
		GLOB.antag_training_sector_templates[map_path] = template
	return template

/// Постоянная часть арены: вестибюль грузится с ядром, мини-станция и площадки - при первом входе игрока. До закрытия арены не выгружается.
/datum/antag_training_hub
	var/datum/antag_training_arena/arena
	var/map_path = "_maps/templates/antag_training/hub.dmm"
	/// Пустые слоты площадок, от угла хаба.
	var/pads_map_path = "_maps/templates/antag_training/hub_pads.dmm"
	var/list/pads_offset = list(2, 40)
	var/origin_x = ANTAG_TRAINING_HUB_X
	var/origin_y = ANTAG_TRAINING_HUB_Y
	var/list/bounds
	var/list/turf/turfs = list()
	var/list/landmark_offsets = list()
	var/list/datum/antag_training_hub_department/departments = list()
	/// Коридор последним: его стены принадлежат отсекам, раньше них он стравливает воздух в пустой слот.
	var/list/department_types = list(
		/datum/antag_training_hub_department/cargo,
		/datum/antag_training_hub_department/bar,
		/datum/antag_training_hub_department/engineering,
		/datum/antag_training_hub_department/medbay,
		/datum/antag_training_hub_department/bridge,
		/datum/antag_training_hub_department/ai,
		/datum/antag_training_hub_department/science,
		/datum/antag_training_hub_department/brig,
		/datum/antag_training_hub_department/hallway,
	)
	var/ready = FALSE
	var/loading = FALSE
	var/station_state = ANTAG_TRAINING_SECTOR_UNLOADED
	var/idle_timer

/datum/antag_training_hub/New(datum/antag_training_arena/owner)
	arena = owner
	for(var/department_type in department_types)
		var/datum/antag_training_hub_department/department = new department_type(src)
		departments[department.id] = department
	create_pads()

/datum/antag_training_hub/proc/load()
	if(ready || loading || !arena?.private_level || arena.finished)
		return ready
	loading = TRUE
	// Рантайм внутри place() возвращает сюда null.
	var/placed = place()
	loading = FALSE
	if(placed != TRUE || arena.finished)
		return FALSE
	ready = TRUE
	place_lobby_machines()
	idle_timer = addtimer(CALLBACK(src, PROC_REF(check_departments)), ANTAG_TRAINING_SECTOR_IDLE_CHECK, TIMER_STOPPABLE)
	return TRUE

/datum/antag_training_hub/proc/place()
	var/datum/map_template/template = antag_training_map_template(map_path, "Хаб полигона")
	var/level = arena.private_level.z_value
	bounds = list(origin_x, origin_x + template.width - 1, origin_y, origin_y + template.height - 1)
	turfs = block(locate(bounds[1], bounds[3], level), locate(bounds[2], bounds[4], level))
	for(var/area_type in typesof(/area/antag_training/hub))
		var/area/antag_training/hub/place = GLOB.areas_by_type[area_type] || new area_type
		// Владелец назначается до загрузки: атомы шаблона регистрируются в арене при Initialize.
		place.arena = arena
		place.reset_state()
	// Иначе обстановка запишется в личные вещи того, кто открыл полигон.
	usr = null
	if(!template.load(locate(origin_x, origin_y, level)))
		return FALSE
	settle(turfs)
	return TRUE

/// Отсеки мини-станции и площадки своими кусками карты; ждёт уже идущую загрузку.
/datum/antag_training_hub/proc/load_station()
	while(station_state == ANTAG_TRAINING_SECTOR_LOADING)
		stoplag()
	if(station_state == ANTAG_TRAINING_SECTOR_READY)
		return TRUE
	if(!ready || arena.finished)
		return FALSE
	station_state = ANTAG_TRAINING_SECTOR_LOADING
	for(var/department_id in departments)
		var/datum/antag_training_hub_department/department = departments[department_id]
		if(!department.place() || arena.finished)
			station_state = ANTAG_TRAINING_SECTOR_UNLOADED
			return FALSE
	if(!place_pads() || arena.finished)
		station_state = ANTAG_TRAINING_SECTOR_UNLOADED
		return FALSE
	station_state = ANTAG_TRAINING_SECTOR_READY
	return TRUE

/datum/antag_training_hub/proc/place_pads()
	var/datum/map_template/template = antag_training_map_template(pads_map_path, "Площадки хаба")
	var/turf/origin = locate(origin_x + pads_offset[1], origin_y + pads_offset[2], arena.private_level.z_value)
	usr = null
	if(!template.load(origin))
		return FALSE
	settle(block(origin, locate(origin.x + template.width - 1, origin.y + template.height - 1, origin.z)))
	attach_pads()
	return TRUE

/// Воздух, свои провода вместо раскладки раунда, выключенные GPS и метки мест.
/datum/antag_training_hub/proc/settle(list/turf/tiles)
	for(var/turf/open/floor in tiles)
		if(isspaceturf(floor))
			continue
		floor.air.copy_from_turf(floor)
		floor.air_update_turf(FALSE, FALSE)
		arena.yield_work()
	for(var/turf/tile as anything in tiles)
		for(var/obj/thing as anything in tile.GetAllContents(/obj))
			if(thing.wires)
				thing.wires.colors = list()
				thing.wires.randomize()
			var/datum/component/gps/gps = thing.GetComponent(/datum/component/gps)
			if(gps)
				gps.tracking = FALSE
		for(var/obj/effect/landmark/antag_training/mark in tile)
			if(mark.mark_id)
				landmark_offsets[mark.mark_id] = list(tile.x - origin_x, tile.y - origin_y)
			qdel(mark)
		arena.yield_work()

/datum/antag_training_hub/proc/landmark_turf(mark_id)
	var/list/offset = landmark_offsets[mark_id]
	if(!offset || !ready || !arena?.private_level)
		return null
	return locate(origin_x + offset[1], origin_y + offset[2], arena.private_level.z_value)

/datum/antag_training_hub/proc/contains(turf/tile)
	return ready && arena.inside_bounds(tile, bounds)

/datum/antag_training_hub/proc/lobby_turf(turf/tile)
	var/area/antag_training/hub/lobby/place = tile?.loc
	return istype(place) && place.arena == arena && contains(tile)

/datum/antag_training_hub/proc/department_at(turf/tile)
	var/area/antag_training/hub/station/place = tile?.loc
	if(!istype(place) || place.arena != arena)
		return null
	for(var/department_id in departments)
		var/datum/antag_training_hub_department/department = departments[department_id]
		if(department.area_type == place.type)
			return department

/// Отсек, куда зашёл участник, считается тронутым и сбросится после простоя.
/datum/antag_training_hub/proc/note_presence(turf/tile)
	var/datum/antag_training_hub_department/department = department_at(tile)
	if(department)
		department.used = TRUE
		department.last_occupied_at = world.time

/datum/antag_training_hub/proc/busy()
	if(loading || station_state == ANTAG_TRAINING_SECTOR_LOADING || pads_busy())
		return TRUE
	for(var/department_id in departments)
		var/datum/antag_training_hub_department/department = departments[department_id]
		if(department.resetting)
			return TRUE
	return FALSE

/datum/antag_training_hub/proc/check_departments()
	idle_timer = null
	if(!ready || arena.finished)
		return
	for(var/department_id in departments)
		var/datum/antag_training_hub_department/department = departments[department_id]
		department.check_idle()
	check_pads()
	idle_timer = addtimer(CALLBACK(src, PROC_REF(check_departments)), ANTAG_TRAINING_SECTOR_IDLE_CHECK, TIMER_STOPPABLE)

/datum/antag_training_hub/proc/release(yielding = TRUE)
	deltimer(idle_timer)
	idle_timer = null
	ready = FALSE
	for(var/department_id in departments)
		var/datum/antag_training_hub_department/department = departments[department_id]
		department.cancel_vote()
	detach_pads()
	var/list/turf/used_tiles = list()
	for(var/turf/tile as anything in turfs)
		if(!isspaceturf(tile) || length(tile.contents))
			used_tiles += tile
	if(length(used_tiles))
		drop_networks(used_tiles, yielding)
		arena.release_tiles(used_tiles, yielding)
	station_state = ANTAG_TRAINING_SECTOR_UNLOADED
	turfs = list()
	bounds = null
	landmark_offsets = list()
	for(var/area_type in typesof(/area/antag_training/hub))
		var/area/antag_training/hub/place = GLOB.areas_by_type[area_type]
		if(place?.arena == arena)
			place.arena = null

/// Трубы и кабель под полом удаляются пачками: по одной с ожиданием между тиками каждая сеть пересобиралась бы заново.
/datum/antag_training_hub/proc/drop_networks(list/turf/tiles, yielding = TRUE)
	var/count = 0
	for(var/turf/tile as anything in tiles)
		for(var/obj/thing in tile)
			if(!istype(thing, /obj/machinery/atmospherics/pipe) && !istype(thing, /obj/structure/cable))
				continue
			qdel(thing)
			if(yielding && !(++count % ANTAG_TRAINING_HUB_NETWORK_BATCH))
				arena.yield_work()

/datum/antag_training_hub/Destroy()
	if(arena)
		release(FALSE)
	QDEL_LIST_ASSOC_VAL(departments)
	QDEL_LIST(pads)
	arena = null
	return ..()

/// Отсек мини-станции: своя область и свой кусок карты, сбрасывается отдельно от остального хаба.
/datum/antag_training_hub_department
	var/id
	var/name
	var/area_type
	/// Угол куска карты от угла хаба.
	var/offset_x
	var/offset_y
	var/datum/antag_training_hub/hub
	var/list/turf/turfs = list()
	var/used = FALSE
	var/last_occupied_at = 0
	var/resetting = FALSE
	/// Слабая ссылка на сеанс -> согласие.
	var/list/votes = list()
	var/vote_deadline = 0
	var/vote_timer

/datum/antag_training_hub_department/New(datum/antag_training_hub/owner)
	hub = owner

/datum/antag_training_hub_department/proc/map_path()
	return "_maps/templates/antag_training/hub_[id].dmm"

/datum/antag_training_hub_department/proc/origin_turf()
	return locate(hub.origin_x + offset_x, hub.origin_y + offset_y, hub.arena.private_level.z_value)

/// Грузит свой кусок карты и запоминает клетки своей области.
/datum/antag_training_hub_department/proc/place()
	var/datum/map_template/template = antag_training_map_template(map_path(), name)
	var/turf/origin = origin_turf()
	usr = null
	if(!template.load(origin))
		return FALSE
	turfs = list()
	var/area/place = GLOB.areas_by_type[area_type]
	for(var/turf/tile as anything in block(origin, locate(origin.x + template.width - 1, origin.y + template.height - 1, origin.z)))
		if(tile.loc == place)
			turfs += tile
	hub.settle(turfs)
	used = FALSE
	last_occupied_at = world.time
	return TRUE

/datum/antag_training_hub_department/proc/occupants()
	. = list()
	var/area/place = GLOB.areas_by_type[area_type]
	for(var/datum/antag_training_session/member as anything in hub.arena.members)
		if(member.current_body && get_area(member.current_body) == place)
			. += member

/datum/antag_training_hub_department/proc/check_idle()
	if(resetting || hub.station_state != ANTAG_TRAINING_SECTOR_READY)
		return
	if(length(occupants()))
		used = TRUE
		last_occupied_at = world.time
	else if(used && world.time >= last_occupied_at + ANTAG_TRAINING_HUB_DEPARTMENT_IDLE)
		INVOKE_ASYNC(src, PROC_REF(reset))

/// Голосование тех, кто внутри; одному участнику хватает своего нажатия. Возвращает текст для участника.
/datum/antag_training_hub_department/proc/request_reset(datum/antag_training_session/requester)
	if(resetting || hub.station_state != ANTAG_TRAINING_SECTOR_READY || hub.arena.finished)
		return "Отсек «[name]» уже сбрасывается."
	var/list/inside = occupants()
	if(!(requester in inside))
		return "Сброс отсека голосуют те, кто внутри него."
	if(world.time < vote_deadline)
		if(votes[WEAKREF(requester)])
			return "Вы уже согласились. Ждём остальных в отсеке."
		votes[WEAKREF(requester)] = TRUE
		if(check_votes())
			return "Отсек «[name]» сбрасывается."
		return "Вы согласились на сброс отсека «[name]»."
	votes = list()
	for(var/datum/antag_training_session/member as anything in inside)
		votes[WEAKREF(member)] = member == requester
	vote_deadline = world.time + ANTAG_TRAINING_VOTE_TIME
	vote_timer = addtimer(CALLBACK(src, PROC_REF(cancel_vote)), ANTAG_TRAINING_VOTE_TIME, TIMER_STOPPABLE)
	for(var/datum/antag_training_session/member as anything in inside)
		if(member != requester)
			to_chat(member.current_body, span_notice("[requester.current_body] просит сбросить отсек «[name]». Чтобы согласиться, нажмите панель сброса отсека. Нужно согласие всех, кто внутри, за [ANTAG_TRAINING_VOTE_TIME / (1 SECONDS)] с."))
	if(check_votes())
		return "Отсек «[name]» сбрасывается."
	return "Запрошен сброс отсека «[name]». Остальные в отсеке подтверждают его на панели сброса."

/// Все, кто голосует и ещё внутри, согласны: отсек сбрасывается. Ушедшие голосование не держат.
/datum/antag_training_hub_department/proc/check_votes()
	if(!length(votes) || resetting || world.time >= vote_deadline)
		return FALSE
	var/list/inside = occupants()
	for(var/datum/weakref/voter_ref as anything in votes)
		var/datum/antag_training_session/voter = voter_ref.resolve()
		if(voter && (voter in inside) && !votes[voter_ref])
			return FALSE
	INVOKE_ASYNC(src, PROC_REF(reset))
	return TRUE

/datum/antag_training_hub_department/proc/vote_progress()
	var/approved = 0
	var/total = 0
	var/list/inside = occupants()
	for(var/datum/weakref/voter_ref as anything in votes)
		var/datum/antag_training_session/voter = voter_ref.resolve()
		if(!voter || !(voter in inside))
			continue
		total++
		if(votes[voter_ref])
			approved++
	return list(approved, total)

/datum/antag_training_hub_department/proc/cancel_vote()
	deltimer(vote_timer)
	vote_timer = null
	vote_deadline = 0
	votes = list()

/// Заново грузит свой кусок карты: участников внутри переносит в вестибюль, ИИ оставляет в ядре.
/datum/antag_training_hub_department/proc/reset()
	var/datum/antag_training_arena/arena = hub?.arena
	if(resetting || hub.station_state != ANTAG_TRAINING_SECTOR_READY || !arena || arena.finished || !length(turfs))
		return FALSE
	resetting = TRUE
	cancel_vote()
	var/turf/arrival = hub.landmark_turf("hub_arrival") || arena.entry_turf
	for(var/datum/antag_training_session/member as anything in occupants())
		if(isAI(member.current_body))
			continue
		member.current_body.forceMove(arrival)
		to_chat(member.current_body, span_notice("Отсек «[name]» сбрасывается: вы в вестибюле хаба."))
	hub.drop_networks(turfs)
	for(var/turf/tile as anything in turfs)
		arena.clear_tile(tile, TRUE)
		arena.yield_work()
	if(arena.finished)
		resetting = FALSE
		return FALSE
	. = place()
	if(.)
		var/area/antag_training/hub/place = GLOB.areas_by_type[area_type]
		place?.reset_state()
	arena.prune_targets()
	used = FALSE
	last_occupied_at = world.time
	resetting = FALSE

/datum/antag_training_hub_department/Destroy()
	cancel_vote()
	turfs = list()
	hub = null
	return ..()

/datum/antag_training_hub_department/hallway
	id = "hallway"
	name = "Коридоры и техтоннели"
	area_type = /area/antag_training/hub/station/hallway
	offset_x = 24
	offset_y = 1

/datum/antag_training_hub_department/cargo
	id = "cargo"
	name = "Снабжение"
	area_type = /area/antag_training/hub/station/cargo
	offset_x = 24
	offset_y = 1

/datum/antag_training_hub_department/bar
	id = "bar"
	name = "Бар и кухня"
	area_type = /area/antag_training/hub/station/bar
	offset_x = 36
	offset_y = 1

/datum/antag_training_hub_department/engineering
	id = "engineering"
	name = "Инженерный отсек"
	area_type = /area/antag_training/hub/station/engineering
	offset_x = 48
	offset_y = 1

/datum/antag_training_hub_department/medbay
	id = "medbay"
	name = "Медблок"
	area_type = /area/antag_training/hub/station/medbay
	offset_x = 58
	offset_y = 1

/datum/antag_training_hub_department/bridge
	id = "bridge"
	name = "Мостик"
	area_type = /area/antag_training/hub/station/bridge
	offset_x = 24
	offset_y = 19

/datum/antag_training_hub_department/ai
	id = "ai"
	name = "Серверная и ядро ИИ"
	area_type = /area/antag_training/hub/station/ai
	offset_x = 36
	offset_y = 19

/datum/antag_training_hub_department/science
	id = "science"
	name = "Научный отсек"
	area_type = /area/antag_training/hub/station/science
	offset_x = 48
	offset_y = 19

/datum/antag_training_hub_department/brig
	id = "brig"
	name = "Бриг"
	area_type = /area/antag_training/hub/station/brig
	offset_x = 58
	offset_y = 19

/datum/antag_training_arena/proc/hub_arrival()
	return hub?.landmark_turf("hub_arrival") || entry_turf

/// Центр ядра и вестибюль хаба: урон и оглушение отключены.
/datum/antag_training_arena/proc/safe_turf(turf/tile)
	return inside_bounds(tile, zones["hub"]["bounds"]) || hub?.lobby_turf(tile)

/// Единая точка входа в сектор для пульта и врат хаба: бронь группы проверяет enter_sector().
/datum/antag_training_session/proc/try_enter_sector(sector_id)
	if(finished || !arena || arena.finished || !istext(sector_id))
		return FALSE
	if(isAI(current_body))
		practice_message("Ядро ИИ не переносится: зоны и сектора ИИ смотрит через камеры.")
		return FALSE
	var/refusal = scenario_venue_refusal(sector_id)
	if(refusal)
		practice_message(refusal)
		return FALSE
	return console_enter_sector(sector_id)

/// Выбывший из идущей партии не входит на её место сразу, а не только выводится следующим тиком сценария.
/datum/antag_training_session/proc/scenario_venue_refusal(sector_id)
	var/datum/antag_training_scenario/current = scenario_in_play()
	return current?.venue?.id() == sector_id ? current.entry_refusal(src) : null

/obj/effect/landmark/antag_training/hub_arrival
	name = "training mark: hub arrival"
	mark_id = "hub_arrival"

/obj/effect/landmark/antag_training/hub_ai_core
	name = "training mark: hub AI core"
	mark_id = "hub_ai_core"

/// Место под доску групп и сценариев.
/obj/effect/landmark/antag_training/hub_board
	name = "training mark: hub squad board"
	mark_id = "hub_board"

/// Место под экраны трибуны.
/obj/effect/landmark/antag_training/hub_tribune
	name = "training mark: hub tribune"
	mark_id = "hub_tribune"

/obj/effect/landmark/antag_training/hub_pad
	name = "training mark: hub pad"

/obj/effect/landmark/antag_training/hub_pad/one
	mark_id = "hub_pad_1"

/obj/effect/landmark/antag_training/hub_pad/two
	mark_id = "hub_pad_2"

/obj/effect/landmark/antag_training/hub_pad/three
	mark_id = "hub_pad_3"

/obj/effect/landmark/antag_training/hub_pad/four
	mark_id = "hub_pad_4"

/proc/antag_training_area_arena(atom/thing)
	var/area/antag_training/place = get_area(thing)
	return istype(place) ? place.arena : null

/obj/structure/antag_training_barrier/hub
	desc = "Граница вестибюля хаба: участники проходят, снаряды, цели и воздух остаются по свою сторону."
	// Иначе вестибюль стравливает воздух в пустой слот мини-станции и площадок, пока они не загружены.
	CanAtmosPass = ATMOS_PASS_NO

/obj/structure/antag_training_barrier/hub/Initialize(mapload)
	. = ..(mapload, antag_training_area_arena(src))
	air_update_turf(TRUE)

/obj/structure/sign/antag_training_board/hub
	name = "training hub board"
	desc = "Голографический стенд хаба: кто на полигоне, что где находится, какие сценарии у групп и куда идти вашей программе."

/obj/structure/sign/antag_training_board/hub/examine(mob/user)
	. = list("[get_examine_string(user, TRUE)].<hr>", desc)
	var/datum/antag_training_arena/arena = training_arena()
	if(!arena)
		return
	. += span_notice("Участников на полигоне: [length(arena.members)].")
	. += span_notice("Раздевалка - налево: шкаф отдела меняет должность, снаряжение и доступ ID. Врата секторов - в зале за аркой, шаг на платформу переносит в сектор; обратно - платформа возврата у входа в сектор.")
	. += span_notice("Мини-станция - за барьером в зале врат: рабочие отделы, где ID открывает свои двери, а урон включён. Доска групп и сценариев - здесь, в зале прибытия. Трибуна с экранами камер забронированных секторов и занятых площадок, галерея и площадки - на север.")
	var/list/sector_lines = list()
	for(var/sector_id in arena.sectors)
		var/datum/antag_training_sector/sector = arena.sectors[sector_id]
		sector_lines += "[sector.name] - [antag_training_sector_state_text(sector)]"
	. += span_notice("Сектора: [sector_lines.Join("; ")].")
	if(arena.hub?.station_state == ANTAG_TRAINING_SECTOR_READY)
		. += span_notice("Площадки: [arena.hub.pads_summary()].")
	var/list/scenario_lines = list()
	for(var/datum/antag_training_squad/team as anything in arena.squads)
		var/datum/antag_training_scenario/scenario = team.scenario
		if(scenario)
			scenario_lines += "«[scenario.name]» у группы «[team.name]»[scenario.venue ? ", [scenario.venue.name()]" : ""] - [antag_training_scenario_phase_text(scenario.phase)]"
	if(length(scenario_lines))
		. += span_notice("Сценарии групп: [scenario_lines.Join("; ")].")
	var/datum/antag_training_session/session = arena.session_of(user)
	if(session)
		. += span_notice("Ваша программа «[session.program.name]»: [antag_training_route_text(antag_training_program_route(session.program.type))]. Подробнее - во вкладке «Моя роль» пульта.")
		. += span_notice("Нажмите на стенд, чтобы открыть пульт полигона.")

/obj/structure/sign/antag_training_board/hub/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	var/datum/antag_training_arena/arena = training_arena()
	var/datum/antag_training_session/session = arena?.session_of(user)
	if(!session?.can_control(user))
		return ..()
	session.ui_interact(user)
	return TRUE

/obj/structure/sign/antag_training_board/hub/attack_ai(mob/user)
	var/datum/antag_training_arena/arena = training_arena()
	var/datum/antag_training_session/session = arena?.session_of(user)
	if(!session?.can_control(user))
		return ..()
	session.ui_interact(user)
	return TRUE

/proc/antag_training_scenario_phase_text(phase)
	switch(phase)
		if(ANTAG_TRAINING_SCENARIO_STARTING)
			return "отсчёт до старта"
		if(ANTAG_TRAINING_SCENARIO_RUNNING)
			return "идёт"
		if(ANTAG_TRAINING_SCENARIO_SUMMARY)
			return "итог"
	return "набор в слоты"

/proc/antag_training_sector_state_text(datum/antag_training_sector/sector)
	var/inside = 0
	for(var/datum/antag_training_session/member as anything in sector.arena?.members)
		if(sector.bounds && sector.arena.inside_bounds(get_turf(member.current_body), sector.bounds))
			inside++
	switch(sector.state)
		if(ANTAG_TRAINING_SECTOR_READY)
			return inside ? "открыт, внутри [inside]" : "открыт, пуст"
		if(ANTAG_TRAINING_SECTOR_LOADING)
			return "загружается"
		if(ANTAG_TRAINING_SECTOR_UNLOADING)
			return "выгружается"
	return "не загружен, загрузится при входе"

/// Врата сектора: шаг на платформу - тот же вход, что кнопка сектора в пульте.
/obj/structure/antag_training_gate
	name = "sector gate"
	desc = "Платформа перехода в сектор полигона. Шагните на неё, и незагруженный сектор подгрузится."
	icon = 'icons/obj/telescience.dmi'
	icon_state = "qpad-idle"
	anchored = TRUE
	density = FALSE
	layer = BELOW_OBJ_LAYER
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/sector_id

/obj/structure/antag_training_gate/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(COMSIG_ATOM_ENTERED = PROC_REF(on_entered))
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/antag_training_gate/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	var/datum/antag_training_session/session = arena?.session_of(arrived)
	if(!session?.can_control(arrived))
		return
	var/datum/antag_training_sector/sector = arena.sectors[sector_id]
	var/refusal = sector?.entry_refusal(session) || session.scenario_venue_refusal(sector_id) || session.scenario_transit_refusal()
	if(refusal)
		to_chat(arrived, span_warning(refusal))
		return
	flick("qpad-beam", src)
	INVOKE_ASYNC(session, TYPE_PROC_REF(/datum/antag_training_session, try_enter_sector), sector_id)

/obj/structure/antag_training_gate/examine(mob/user)
	. = ..()
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	var/datum/antag_training_sector/sector = arena?.sectors[sector_id]
	if(!sector)
		return
	. += span_notice("Сектор «[sector.name]»: [antag_training_sector_state_text(sector)]. [sector.desc]")
	var/datum/antag_training_session/session = arena.session_of(user)
	var/list/exercises = arena.zone_exercise_names(sector_id, session)
	. += span_notice(length(exercises) ? "Упражнения: [exercises.Join("; ")]." : "Готовых упражнений здесь нет: сектор для свободной практики и сценариев.")
	var/list/scenarios = antag_training_venue_scenario_names(sector_id)
	if(length(scenarios))
		. += span_notice("Сценарии для групп: [scenarios.Join(", ")]. Группу и сценарий выбирают у доски групп в зале прибытия.")
	var/list/programs = antag_training_sector_program_names(sector_id)
	if(length(programs))
		. += span_notice("Здесь начинают программы: [programs.Join(", ")].")
	var/list/booking = sector.booking_entry(session)
	if(booking["squad"])
		. += span_notice("Забронирован группой «[booking["squad"]]»[booking["mine"] ? " (ваша)" : ""], осталось [antag_training_clock(booking["remaining"] SECONDS)].")
	if(length(booking["waitlist"]))
		. += span_notice("Очередь: [jointext(booking["waitlist"], ", ")].")

/obj/structure/antag_training_gate/dark
	sector_id = "dark"

/obj/structure/antag_training_gate/eva
	sector_id = "eva"

/obj/structure/antag_training_gate/engineering
	sector_id = "engineering"

/obj/structure/antag_training_gate/station
	sector_id = "station"

/obj/structure/antag_training_gate/atmos
	sector_id = "atmos"

/obj/structure/antag_training_gate/robotics
	sector_id = "robotics"

/// Шкаф раздевалки: должности своего отдела через тот же выбор роли, что в пульте.
/obj/structure/antag_training_wardrobe
	name = "department wardrobe"
	desc = "Шкаф раздевалки полигона. Нажмите, чтобы выбрать должность отдела: снаряжение, ID и доступ сменятся, программа останется прежней."
	icon = 'icons/obj/closet.dmi'
	icon_state = "generic"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/department
	var/door_state = "gen_wardrobe_door"

/obj/structure/antag_training_wardrobe/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/structure/antag_training_wardrobe/update_overlays()
	. = ..()
	. += door_state

/obj/structure/antag_training_wardrobe/examine(mob/user)
	. = ..()
	. += span_notice("Отдел: [department].")

/obj/structure/antag_training_wardrobe/proc/session_for(mob/user)
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	var/datum/antag_training_session/session = arena?.session_of(user)
	return session?.can_control(user) ? session : null

/obj/structure/antag_training_wardrobe/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	if(!session_for(user))
		return ..()
	ui_interact(user)
	return TRUE

/obj/structure/antag_training_wardrobe/attack_ai(mob/user)
	if(!session_for(user))
		return ..()
	ui_interact(user)
	return TRUE

/obj/structure/antag_training_wardrobe/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AntagTrainingWardrobe", name)
		ui.open()

/obj/structure/antag_training_wardrobe/proc/offers(datum/antag_training_role/role)
	return role.id == ANTAG_TRAINING_ROLE_DEFAULT || role.department == department

/obj/structure/antag_training_wardrobe/ui_data(mob/user)
	var/datum/antag_training_session/session = session_for(user)
	var/list/data = list("department" = department, "program" = session?.program?.name, "selected" = session?.role?.id, "busy" = !session || session.resetting || session.arena.resetting)
	var/list/roles = list()
	var/list/blocked = list()
	var/list/catalog = antag_training_roles()
	for(var/role_id in catalog)
		var/datum/antag_training_role/role = catalog[role_id]
		if(!offers(role))
			continue
		if(session && !antag_training_role_compatible(session.program.type, role))
			blocked += role.name
			continue
		roles += list(role.ui_entry())
	data["roles"] = roles
	data["blocked"] = blocked
	return data

/obj/structure/antag_training_wardrobe/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || action != "set_role")
		return
	var/datum/antag_training_session/session = session_for(usr)
	var/datum/antag_training_role/role = istext(params["role"]) ? antag_training_role(params["role"]) : null
	if(!session || !role || !offers(role) || role == session.role)
		return FALSE
	// Отказ партии объясняет сам сценарий: совет сменить программу или подождать был бы неправдой.
	if(session.scenario_role_locked())
		return FALSE
	if(!antag_training_role_compatible(session.program.type, role))
		to_chat(usr, span_warning("Программа «[session.program.name]» не работает с этой ролью. Смените программу в пульте полигона."))
		return FALSE
	if(!session.set_role(role.id))
		to_chat(usr, span_warning("Сменить должность сейчас не вышло: подождите несколько секунд и попробуйте снова."))
		return FALSE
	return TRUE

/obj/structure/antag_training_wardrobe/command
	name = "command wardrobe"
	department = "Командование"
	icon_state = "cap"
	door_state = "cap_door"

/obj/structure/antag_training_wardrobe/security
	name = "security wardrobe"
	department = "Служба безопасности"
	door_state = "sec_wardrobe_door"

/obj/structure/antag_training_wardrobe/medical
	name = "medical wardrobe"
	department = "Медицина"
	door_state = "med_wardrobe_door"

/obj/structure/antag_training_wardrobe/engineering
	name = "engineering wardrobe"
	department = "Инженерия"
	door_state = "engi_wardrobe_door"

/obj/structure/antag_training_wardrobe/science
	name = "science wardrobe"
	department = "Наука"
	door_state = "sci_wardrobe_door"

/obj/structure/antag_training_wardrobe/supply
	name = "supply wardrobe"
	department = "Снабжение"
	door_state = "cargo_wardrobe_door"

/obj/structure/antag_training_wardrobe/service
	name = "service wardrobe"
	department = "Сервис"
	door_state = "bar_wardrobe_door"

/obj/structure/antag_training_wardrobe/silicon
	name = "synthetics wardrobe"
	department = "Синтетики"
	door_state = "robo_wardrobe_door"

/// Панель сброса отсека мини-станции: голосуют те, кто внутри.
/obj/structure/antag_training_hub_reset
	name = "department reset panel"
	desc = "Панель сброса отсека мини-станции: возвращает обстановку как была. Голосуют участники внутри отсека, одному хватает своего нажатия. Пустой отсек, где кто-то побывал, сбрасывается сам."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "doorctrl"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/antag_training_hub_reset/proc/department()
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	return arena?.hub?.department_at(get_turf(src))

/obj/structure/antag_training_hub_reset/examine(mob/user)
	. = ..()
	var/datum/antag_training_hub_department/department = department()
	if(!department)
		return
	. += span_notice("Отсек «[department.name]». Пустой отсек сбрасывается сам через [ANTAG_TRAINING_HUB_DEPARTMENT_IDLE / (1 MINUTES)] мин после ухода последнего участника.")
	if(world.time < department.vote_deadline)
		var/list/progress = department.vote_progress()
		. += span_notice("Идёт голосование за сброс: согласны [progress[1]] из [progress[2]].")

/obj/structure/antag_training_hub_reset/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	var/datum/antag_training_session/session = arena?.session_of(user)
	var/datum/antag_training_hub_department/department = department()
	if(!department || !session?.can_control(user))
		return ..()
	flick("doorctrl1", src)
	to_chat(user, span_notice(department.request_reset(session)))
	return TRUE

/obj/structure/antag_training_hub_reset/attack_ai(mob/user)
	return on_attack_hand(user)

// Платформа возврата объявлена с секторами; киборг нажимает её, как рукой, а ядро ИИ она не переносит.
/obj/structure/antag_training_exit/attack_robot(mob/user)
	if(!Adjacent(user))
		return ..()
	return on_attack_hand(user)

/obj/structure/antag_training_exit/attack_ai(mob/user)
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	if(isAI(user) && arena?.session_of(user))
		to_chat(user, span_warning("Ядро ИИ не переносится: зоны и сектора ИИ смотрит через камеры."))
		return TRUE
	return ..()
