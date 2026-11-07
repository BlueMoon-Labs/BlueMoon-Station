GLOBAL_LIST_INIT(antag_training_holo_color, list(0.15, 0.45, 0.5, 0.15, 0.45, 0.5, 0.15, 0.45, 0.5, 0, 0.25, 0.3))
GLOBAL_LIST_INIT(antag_training_frame_color, list(0.3, 0.9, 1, 0.3, 0.9, 1, 0.3, 0.9, 1, 0.05, 0.2, 0.25))
GLOBAL_LIST_EMPTY(antag_training_frame_overlays)

#define ANTAG_TRAINING_FRAME_ALPHA 140
#define ANTAG_TRAINING_FRAME_SHIFT 12
#define ANTAG_TRAINING_FIELD_ALPHA 110
#define ANTAG_TRAINING_BOARD_RAISE 10
#define ANTAG_TRAINING_BOARD_LIGHT_RANGE 2
#define ANTAG_TRAINING_BOARD_LIGHT_POWER 0.6

/obj/structure/sign/antag_training_board
	name = "training info board"
	desc = "Голографический стенд полигона: тема зоны, что в ней тренировать и какие упражнения здесь есть."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "holopad1"
	plane = GAME_PLANE
	layer = LOW_OBJ_LAYER
	buildable_sign = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/sign/antag_training_board/Initialize(mapload)
	. = ..()
	update_appearance()
	// Эмиссив за see_in_dark не рисуется, в тёмной зоне стенд виден только при своём свете.
	var/area/place = get_area(src)
	if(place.dynamic_lighting != DYNAMIC_LIGHTING_DISABLED)
		set_light(ANTAG_TRAINING_BOARD_LIGHT_RANGE, ANTAG_TRAINING_BOARD_LIGHT_POWER, "#7fe8ff")

/obj/structure/sign/antag_training_board/update_overlays()
	. = ..()
	for(var/state in list("screen", "text"))
		var/mutable_appearance/hologram = mutable_appearance('icons/obj/money_machine.dmi', state, ABOVE_MOB_LAYER, alpha = 220, pixel_y = ANTAG_TRAINING_BOARD_RAISE)
		hologram.color = GLOB.antag_training_holo_color
		. += hologram

/obj/structure/sign/antag_training_board/proc/training_arena()
	var/area/antag_training/place = get_area(src)
	return istype(place) ? place.arena : null

/obj/structure/sign/antag_training_board/examine(mob/user)
	. = ..()
	var/datum/antag_training_arena/arena = training_arena()
	var/zone_id = arena?.match_zone(src)
	var/list/zone = arena?.zones[zone_id]
	if(!zone)
		return
	var/datum/antag_training_session/session = arena.session_of(user)
	. += span_notice("Зона «[zone["name"]]». Что тренировать: [zone["desc"]]")
	var/list/exercises = arena.zone_exercise_names(zone_id, session)
	if(length(exercises))
		. += span_notice("Упражнения: [exercises.Join("; ")].")
	else
		. += span_notice("Готовых упражнений здесь нет, зона для свободной практики.")
	if(session)
		. += span_notice("Нажмите на стенд, чтобы открыть упражнения в пульте полигона.")

/obj/structure/sign/antag_training_board/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	var/datum/antag_training_arena/arena = training_arena()
	var/datum/antag_training_session/session = arena?.session_of(user)
	if(!session?.can_control(user))
		return ..()
	session.open_exercises(user)
	return TRUE

/datum/antag_training_arena/proc/session_of(mob/user)
	for(var/datum/antag_training_session/member as anything in members)
		if(member.current_body == user)
			return member

/datum/antag_training_arena/proc/zone_exercise_names(zone_id, datum/antag_training_session/viewer)
	. = list()
	for(var/exercise_id in GLOB.antag_training_exercises)
		var/datum/antag_training_exercise/exercise = GLOB.antag_training_exercises[exercise_id]
		if(exercise.sector == zone_id)
			. += "[exercise.name] (сложность [exercise.difficulty][viewer && !exercise.available(viewer) ? ", не для вашей роли: [exercise.unavailable_reason(viewer)]" : ""])"
	for(var/practice_key in GLOB.antag_training_practice_exercises)
		var/list/practice = GLOB.antag_training_practice_exercises[practice_key]
		if(practice["zone"] == zone_id)
			. += "[practice["name"]] (сложность [practice["difficulty"]][viewer && !viewer.practice_available(practice_key) ? ", не для вашей роли" : ""])"

/datum/antag_training_session
	/// Следующее открытие пульта начнётся с вкладки «Упражнения».
	var/exercises_requested = FALSE

/// Пульт открывается заново на вкладке упражнений зоны участника.
/datum/antag_training_session/proc/open_exercises(mob/user)
	var/datum/tgui/open = SStgui.get_open_ui(user, src)
	open?.close()
	exercises_requested = TRUE
	ui_interact(user)

/datum/antag_training_session/proc/play_training_sound(soundin)
	current_body?.playsound_local(get_turf(current_body), soundin, ANTAG_TRAINING_SOUND_VOLUME, FALSE, pressure_affected = FALSE)

/// Клетка пола в двух шагах от точки входа: соседние с ней клетки остаются под мастерскую.
/datum/antag_training_arena/proc/board_spot(turf/center, list/bounds)
	if(!center)
		return null
	for(var/distance in list(2, 1))
		for(var/direction in list(NORTH, NORTHEAST, NORTHWEST, EAST, WEST, SOUTHEAST, SOUTHWEST, SOUTH))
			var/turf/open/spot = get_ranged_target_turf(center, direction, distance)
			if(!istype(spot) || isspaceturf(spot) || spot.x <= bounds[1] || spot.x >= bounds[2] || spot.y <= bounds[3] || spot.y >= bounds[4])
				continue
			if(spot.is_blocked_turf() || (locate(/obj/structure) in spot) || (locate(/obj/machinery) in spot) || (locate(/obj/effect/landmark) in spot))
				continue
			var/turf/between = get_step(center, direction)
			if(distance > 1 && between.is_blocked_turf())
				continue
			return spot
	return null

/datum/antag_training_arena/proc/place_zone_boards(zone_id)
	for(var/id in zones)
		var/list/zone = zones[id]
		if((zone_id && id != zone_id) || zone["sector"])
			continue
		var/turf/spot = board_spot(zone["spawn"], zone["bounds"])
		if(spot)
			new /obj/structure/sign/antag_training_board(spot)

/proc/antag_training_frame_overlays()
	if(length(GLOB.antag_training_frame_overlays))
		return GLOB.antag_training_frame_overlays
	. = GLOB.antag_training_frame_overlays
	for(var/side in GLOB.cardinals)
		var/mutable_appearance/bar = mutable_appearance('icons/effects/effects.dmi', "shieldwall", alpha = ANTAG_TRAINING_FRAME_ALPHA, appearance_flags = RESET_COLOR | RESET_ALPHA)
		bar.dir = (side & (NORTH | SOUTH)) ? EAST : SOUTH
		bar.color = GLOB.antag_training_frame_color
		antag_training_shift_inward(bar, side)
		.["[side]"] = bar

/proc/antag_training_shift_inward(mutable_appearance/bar, side)
	switch(side)
		if(SOUTH)
			bar.pixel_y = ANTAG_TRAINING_FRAME_SHIFT
		if(NORTH)
			bar.pixel_y = -ANTAG_TRAINING_FRAME_SHIFT
		if(WEST)
			bar.pixel_x = ANTAG_TRAINING_FRAME_SHIFT
		if(EAST)
			bar.pixel_x = -ANTAG_TRAINING_FRAME_SHIFT

/// Клетки края сектора: сторона -> список клеток; угловая клетка входит в две стороны.
/datum/antag_training_sector/proc/edge_tiles()
	. = list()
	var/level = arena.private_level.z_value
	.["[SOUTH]"] = block(locate(bounds[1], bounds[3], level), locate(bounds[2], bounds[3], level))
	.["[NORTH]"] = block(locate(bounds[1], bounds[4], level), locate(bounds[2], bounds[4], level))
	.["[WEST]"] = block(locate(bounds[1], bounds[3], level), locate(bounds[1], bounds[4], level))
	.["[EAST]"] = block(locate(bounds[2], bounds[3], level), locate(bounds[2], bounds[4], level))

/// Голографическое поле по краю: по оверлею на сторону клетки края, без своих атомов.
/datum/antag_training_sector/proc/set_frame(visible)
	if(!bounds || !arena?.private_level)
		return
	var/list/sides = edge_tiles()
	var/list/bars = antag_training_frame_overlays()
	for(var/side in sides)
		var/mutable_appearance/bar = bars[side]
		for(var/turf/tile as anything in sides[side])
			if(visible)
				tile.add_overlay(bar)
			else
				tile.cut_overlay(bar)

/datum/antag_training_sector/proc/find_board()
	for(var/turf/tile as anything in turfs)
		var/obj/structure/sign/antag_training_board/board = locate() in tile
		if(board)
			return board

/datum/antag_training_sector/proc/decorate(datum/antag_training_arena/owner)
	set_frame(TRUE)
	if(!find_board())
		var/turf/spot = owner.board_spot(spawn_turf(), bounds)
		if(spot)
			new /obj/structure/sign/antag_training_board(spot)
	sweep(TRUE)

/// Голограмма проходит по сектору волной: снизу вверх при загрузке, сверху вниз при растворении.
/datum/antag_training_sector/proc/sweep(materialize)
	var/width = bounds[2] - bounds[1] + 1
	var/height = bounds[4] - bounds[3] + 1
	var/top = height * world.icon_size
	var/half = world.icon_size / 2
	var/time = materialize ? ANTAG_TRAINING_SCAN_TIME : ANTAG_TRAINING_DISSOLVE_TIME
	var/turf/corner = locate(bounds[1], bounds[3], arena.private_level.z_value)
	var/matrix/covered = matrix(width, 0, (width - 1) * half, 0, height, top / 2 - half)
	var/matrix/clear = matrix(width, 0, (width - 1) * half, 0, 0, top - half)
	var/obj/effect/antag_training_sweep/field = new(corner)
	field.transform = materialize ? covered : clear
	animate(field, transform = materialize ? clear : covered, time = time, flags = ANIMATION_LINEAR_TRANSFORM)
	var/obj/effect/antag_training_sweep/line/line = new(corner)
	line.transform = matrix(width, 0, (width - 1) * half, 0, 1, 0)
	line.pixel_y = materialize ? -half : top - half
	animate(line, pixel_y = materialize ? top - half : -half, time = time)
	if(materialize)
		QDEL_IN(field, time)
		QDEL_IN(line, time)

/// Растворение видят и слышат только те, кто стоит в секторе; пустой сектор выгружается без задержки.
/datum/antag_training_sector/proc/dissolve(datum/antag_training_arena/owner)
	if(owner.finished || !bounds)
		return
	var/list/witnesses = list()
	for(var/datum/antag_training_session/member as anything in owner.members)
		if(owner.inside_bounds(get_turf(member.current_body), bounds))
			witnesses += member
	if(!length(witnesses))
		return
	for(var/datum/antag_training_session/member as anything in witnesses)
		member.play_training_sound(ANTAG_TRAINING_SOUND_SECTOR_UNLOAD)
	sweep(FALSE)
	sleep(ANTAG_TRAINING_DISSOLVE_TIME)

/obj/effect/antag_training_sweep
	name = "hologram"
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	color = "#7fe8ff"
	alpha = ANTAG_TRAINING_FIELD_ALPHA
	layer = ABOVE_ALL_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	appearance_flags = PIXEL_SCALE

/obj/effect/antag_training_sweep/line
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldwall"
	dir = EAST
	color = null
	alpha = 220

/obj/effect/antag_training_sweep/line/Initialize(mapload)
	. = ..()
	color = GLOB.antag_training_frame_color

#undef ANTAG_TRAINING_FRAME_ALPHA
#undef ANTAG_TRAINING_FRAME_SHIFT
#undef ANTAG_TRAINING_FIELD_ALPHA
#undef ANTAG_TRAINING_BOARD_RAISE
#undef ANTAG_TRAINING_BOARD_LIGHT_RANGE
#undef ANTAG_TRAINING_BOARD_LIGHT_POWER
