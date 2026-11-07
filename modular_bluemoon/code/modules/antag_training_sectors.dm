GLOBAL_LIST_EMPTY(antag_training_sector_templates)

/area/antag_training/sector
	name = "Training Sector"
	area_flags = NO_ALERTS | UNIQUE_AREA

/// Область одна на все загрузки: выключатель, тревога и учёт питания прошлой загрузки сбрасываются.
/area/antag_training/sector/proc/reset_state()
	lightswitch = TRUE
	fire = FALSE
	area_emergency_mode = FALSE
	STOP_PROCESSING(SSobj, src)
	power_light = TRUE
	power_equip = TRUE
	power_environ = TRUE
	used_light = 0
	used_equip = 0
	used_environ = 0
	static_light = 0
	static_equip = 0
	static_environ = 0
	power_change()

/area/antag_training/sector/dark
	name = "Training Dark Sector"
	// Без требования питания ENABLED в Initialize() области превращается в DISABLED.
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED

/datum/antag_training_arena/proc/owns_area(area/place)
	var/area/antag_training/training_area = place
	return istype(training_area) && training_area.arena == src

/datum/antag_training_sector
	var/id
	var/name
	var/desc
	var/map_path
	var/area_type = /area/antag_training/sector
	var/origin_x
	var/origin_y
	var/list/spawn_offset = list(1, 1)
	var/list/target_offset = list(1, 1)
	var/state = ANTAG_TRAINING_SECTOR_UNLOADED
	var/datum/antag_training_arena/arena
	var/area/antag_training/sector/sector_area
	var/list/turf/turfs = list()
	var/list/bounds
	var/last_occupied_at = 0
	var/idle_timer

/datum/antag_training_sector/New(datum/antag_training_arena/owner)
	arena = owner

/datum/antag_training_sector/proc/load()
	while(state == ANTAG_TRAINING_SECTOR_LOADING || state == ANTAG_TRAINING_SECTOR_UNLOADING)
		stoplag()
	if(QDELETED(src) || !arena || arena.finished)
		return FALSE
	if(state == ANTAG_TRAINING_SECTOR_READY)
		return TRUE
	var/datum/antag_training_arena/owner = arena
	state = ANTAG_TRAINING_SECTOR_LOADING
	// Рантайм внутри place() возвращает сюда null, поэтому состояние меняется только здесь.
	if(place(owner) != TRUE || QDELETED(src) || owner.finished)
		clear_slot(owner)
		state = ANTAG_TRAINING_SECTOR_UNLOADED
		return FALSE
	state = ANTAG_TRAINING_SECTOR_READY
	last_occupied_at = world.time
	idle_timer = addtimer(CALLBACK(src, PROC_REF(check_idle)), ANTAG_TRAINING_SECTOR_IDLE_CHECK, TIMER_STOPPABLE)
	return TRUE

/datum/antag_training_sector/proc/place(datum/antag_training_arena/owner)
	var/level = owner.private_level.z_value
	var/datum/map_template/template = GLOB.antag_training_sector_templates[map_path]
	if(!template)
		template = new(map_path, name, TRUE)
		GLOB.antag_training_sector_templates[map_path] = template
	bounds = list(origin_x, origin_x + template.width - 1, origin_y, origin_y + template.height - 1)
	turfs = block(locate(bounds[1], bounds[3], level), locate(bounds[2], bounds[4], level))
	var/area/antag_training/sector/slot_area = GLOB.areas_by_type[area_type] || new area_type
	// Владелец назначается до загрузки: атомы шаблона регистрируются в арене при Initialize.
	slot_area.arena = owner
	sector_area = slot_area
	slot_area.reset_state()
	// Иначе register_training_atom() запишет обстановку шаблона в личные вещи того, кто открыл сектор.
	usr = null
	if(!template.load(locate(origin_x, origin_y, level)))
		return FALSE
	for(var/turf/open/floor in turfs)
		if(isspaceturf(floor))
			continue
		floor.air.copy_from_turf(floor)
		floor.air_update_turf(FALSE, FALSE)
		owner.yield_work()
	owner.zones[id] = list("name" = name, "desc" = desc, "bounds" = bounds, "spawn" = spawn_turf(), "target" = target_turf(), "sector" = TRUE)
	return after_load(owner)

/// Доводка загруженного шаблона: свои провода вместо раскладки раунда, связь солнечных панелей, выключенные GPS.
/// Результат place() отдаёт в load(): переопределение без `. = ..()` или `return TRUE` срывает каждую загрузку.
/datum/antag_training_sector/proc/after_load(datum/antag_training_arena/owner)
	for(var/turf/tile as anything in turfs)
		for(var/obj/thing as anything in tile.GetAllContents(/obj))
			if(thing.wires)
				thing.wires.colors = list()
				thing.wires.randomize()
			var/obj/machinery/power/solar_control/solar_console = thing
			if(istype(solar_console))
				solar_console.search_for_connected()
			var/datum/component/gps/gps = thing.GetComponent(/datum/component/gps)
			if(gps)
				gps.tracking = FALSE
		owner.yield_work()
	collect_landmarks()
	decorate(owner)
	place_exit(owner)
	add_tribune_cameras(owner)
	return TRUE

/datum/antag_training_sector/proc/place_exit(datum/antag_training_arena/owner)
	var/turf/spot = owner.board_spot(spawn_turf(), bounds)
	if(spot)
		new /obj/structure/antag_training_exit(spot)

/// Платформа возврата у входа в сектор: нажатие переносит в зал прибытия хаба, как кнопка «В хаб» пульта.
/obj/structure/antag_training_exit
	name = "hub return pad"
	desc = "Платформа возврата полигона. Нажмите на неё, чтобы вернуться в зал прибытия хаба к вратам секторов, раздевалке и доске групп."
	icon = 'icons/obj/telescience.dmi'
	icon_state = "qpad-idle"
	anchored = TRUE
	density = FALSE
	layer = BELOW_OBJ_LAYER
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/antag_training_exit/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	var/datum/antag_training_session/session = arena?.session_of(user)
	if(!session?.can_control(user))
		return ..()
	var/turf/arrival = arena.hub?.ready ? arena.hub_arrival() : null
	if(!arrival || session.preparing || arena.resetting)
		to_chat(user, span_warning("Хаб сейчас недоступен: полигон занят подготовкой или сбросом. Попробуйте через несколько секунд."))
		return TRUE
	var/refusal = session.scenario_transit_refusal()
	if(refusal)
		session.practice_message(refusal)
		return TRUE
	flick("qpad-beam", src)
	user.forceMove(arrival)
	return TRUE

/datum/antag_training_sector/proc/unload(yielding = TRUE)
	var/datum/antag_training_arena/owner = arena
	if(state != ANTAG_TRAINING_SECTOR_READY || !owner)
		return FALSE
	state = ANTAG_TRAINING_SECTOR_UNLOADING
	if(yielding)
		dissolve(owner)
	clear_slot(owner, yielding)
	state = ANTAG_TRAINING_SECTOR_UNLOADED
	return TRUE

/datum/antag_training_sector/proc/clear_slot(datum/antag_training_arena/owner, yielding = TRUE)
	deltimer(idle_timer)
	idle_timer = null
	owner.stop_zone_exercises(id)
	owner.zones -= id
	if(owner.pending_reset_zone == id)
		owner.cancel_reset()
	for(var/datum/antag_training_session/member as anything in owner.members)
		if(member.current_body && (get_turf(member.current_body) in turfs))
			member.current_body.forceMove(owner.entry_turf)
	set_frame(FALSE)
	owner.release_tiles(turfs, yielding)
	turfs = list()
	bounds = null
	owner.prune_targets()

/// Чистит клетки и возвращает их космосу. Воздух уходит до уборки дверей и замены турфов, иначе его выдувает в космос.
/datum/antag_training_arena/proc/release_tiles(list/turf/tiles, yielding)
	drain_air(tiles)
	for(var/turf/tile as anything in tiles)
		clear_tile(tile)
		if(yielding)
			yield_work()
	drain_air(tiles)
	var/area/space_area = GLOB.areas_by_type[world.area]
	var/list/turf/open/space/voids = list()
	for(var/turf/tile as anything in tiles)
		space_area.contents += tile
		if(!isspaceturf(tile))
			voids += release_turf(tile)
		if(yielding)
			yield_work()
	// Старлайт ставится в очередь один раз по готовому космосу, а не девятью соседями на каждую клетку по ходу замены.
	for(var/turf/open/space/void as anything in voids)
		for(var/turf/open/space/space_tile in RANGE_TURFS(1, void))
			space_tile.queue_starlight()
		if(yielding)
			yield_work()

/// Пустая клетка без воздуха уходит в космос: без пересчёта воздуха, заслонок и лишних обходов старлайта; соседство атмоса и сглаживание - в очередь.
/datum/antag_training_arena/proc/release_turf(turf/tile)
	var/deferring = GLOB.lighting_defer_active
	GLOB.lighting_defer_active = TRUE
	var/turf/open/space/void = tile.ChangeTurf(/turf/open/space, /turf/open/space, CHANGETURF_DEFER_CHANGE | CHANGETURF_IGNORE_AIR)
	GLOB.lighting_defer_active = deferring
	GLOB.lighting_deferred_starlight -= void
	CALCULATE_ADJACENT_TURFS(void)
	queue_smooth_neighbors(void)
	return void

/datum/antag_training_arena/proc/drain_air(list/turf/tiles)
	for(var/turf/open/floor in tiles)
		if(!isspaceturf(floor))
			floor.air.clear()

/datum/antag_training_arena/proc/sectors_busy()
	for(var/sector_id in sectors)
		var/datum/antag_training_sector/sector = sectors[sector_id]
		if(sector.state == ANTAG_TRAINING_SECTOR_LOADING || sector.state == ANTAG_TRAINING_SECTOR_UNLOADING)
			return TRUE
	return FALSE

/datum/antag_training_sector/proc/spawn_turf()
	if(arena?.private_level)
		return locate(origin_x + spawn_offset[1], origin_y + spawn_offset[2], arena.private_level.z_value)

/datum/antag_training_sector/proc/target_turf()
	if(arena?.private_level)
		return locate(origin_x + target_offset[1], origin_y + target_offset[2], arena.private_level.z_value)

/datum/antag_training_sector/proc/occupied()
	for(var/datum/antag_training_session/member as anything in arena.members)
		if(arena.inside_bounds(get_turf(member.current_body), bounds))
			return TRUE
	return FALSE

/datum/antag_training_sector/proc/check_idle()
	deltimer(idle_timer)
	idle_timer = null
	if(state != ANTAG_TRAINING_SECTOR_READY || !arena || arena.finished)
		return
	if(occupied() || arena.resetting || booked_by)
		last_occupied_at = world.time
	else if(world.time >= last_occupied_at + ANTAG_TRAINING_SECTOR_IDLE)
		INVOKE_ASYNC(src, PROC_REF(unload))
		return
	idle_timer = addtimer(CALLBACK(src, PROC_REF(check_idle)), ANTAG_TRAINING_SECTOR_IDLE_CHECK, TIMER_STOPPABLE)

/datum/antag_training_sector/Destroy()
	unload(FALSE)
	clear_priority()
	deltimer(idle_timer)
	idle_timer = null
	if(sector_area?.arena == arena)
		sector_area.arena = null
	sector_area = null
	arena = null
	return ..()

/datum/antag_training_sector/dark
	id = "dark"
	name = "Тёмный сектор"
	desc = "Нижний ярус: заброшенный техтоннель и комнаты без света. Скрытность, засады, фонари и ночное зрение."
	map_path = "_maps/templates/antag_training/dark.dmm"
	area_type = /area/antag_training/sector/dark
	origin_x = 61
	origin_y = 1
	spawn_offset = list(2, 12)
	target_offset = list(18, 12)
