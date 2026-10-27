/// Сколько клеток вокруг тайника осматривается в поисках приметы.
#define PAPERWORK_LANDMARK_RANGE 3
#define PAPERWORK_LANDMARK_COUNT 2
/// Тайники разных вещей в одном отсеке не ближе этого расстояния.
#define PAPERWORK_HIDEOUT_SPACING 8
#define PAPERWORK_HIDEOUT_MIN_PRESSURE 80
#define PAPERWORK_HIDEOUT_MAX_PRESSURE 120
#define PAPERWORK_HIDEOUT_MIN_TEMP 270
#define PAPERWORK_HIDEOUT_MAX_TEMP 330
#define PAPERWORK_INTAKE_START_Y 10
#define PAPERWORK_INTAKE_LID_Y 4
#define PAPERWORK_INTAKE_END_Y -2
#define PAPERWORK_INTAKE_END_SCALE 0.6

/// Общая основа событий документооборота. Без typepath в каталог директора не попадает.
/datum/round_event_control/paperwork
	weight = 15
	max_occurrences = 1
	earliest_start = 20 MINUTES
	min_players = 5
	severity = DIRECTOR_SEVERITY_MINOR
	category = EVENT_CATEGORY_BUREAUCRATIC
	intensity_linger = 4 MINUTES

/datum/round_event_control/paperwork/director_preflight()
	director_preflight_failure = preflight_failure()
	director_preflight_detail = director_preflight_failure || "Цели на станции найдены."
	return !director_preflight_failure

/datum/round_event_control/paperwork/execute_action()
	if(!director_preflight())
		return FALSE
	return ..()

/// Причина отказа для панели директора или null, если событию есть где сработать.
/datum/round_event_control/paperwork/proc/preflight_failure()
	return null

/datum/round_event_control/paperwork/proc/find_hideouts(count)
	return find_maintenance_hideouts(count)

/datum/round_event_control/paperwork/proc/find_delivery_turf(list/area_types)
	return find_paperwork_delivery_turf(area_types)

/datum/round_event/paperwork
	fakeable = FALSE

/datum/round_event/paperwork/proc/deliver(turf/target, list/atom/movable/cargo)
	return paperwork_drop_pod(target, cargo)

/// Укромная клетка техтоннелей: свободный пол с пригодным воздухом и минимум двумя стенами рядом.
/proc/is_maintenance_hideout(turf/open/floor/spot)
	var/static/list/unsafe_areas = typecacheof(list(
		/area/maintenance/disposal,
		/area/maintenance/external,
		/area/maintenance/prison,
		/area/maintenance/solars,
		/area/maintenance/space_hut,
	))
	var/static/list/allowed_neighbours = typecacheof(list(
		/obj/effect,
		/obj/item,
		/obj/machinery/atmospherics/pipe,
		/obj/structure/cable,
		/obj/structure/disposalpipe,
	))
	if(!istype(spot) || !is_station_level(spot.z))
		return FALSE
	var/area/location = get_area(spot)
	if(!istype(location, /area/maintenance) || is_type_in_typecache(location, unsafe_areas))
		return FALSE
	if(spot.is_blocked_turf() || hideout_wall_count(spot) < 2)
		return FALSE
	for(var/obj/thing in spot)
		if(!is_type_in_typecache(thing, allowed_neighbours))
			return FALSE
	var/datum/gas_mixture/air = spot.return_air()
	if(!air)
		return FALSE
	var/pressure = air.return_pressure()
	return pressure > PAPERWORK_HIDEOUT_MIN_PRESSURE && pressure < PAPERWORK_HIDEOUT_MAX_PRESSURE && air.temperature > PAPERWORK_HIDEOUT_MIN_TEMP && air.temperature < PAPERWORK_HIDEOUT_MAX_TEMP

/proc/hideout_wall_count(turf/spot)
	. = 0
	for(var/direction in GLOB.cardinals)
		if(isclosedturf(get_step(spot, direction)))
			.++

/// По укромной клетке на отсек техтоннелей; при нехватке отсеков клетки берутся из уже выбранных.
/proc/find_maintenance_hideouts(count = 1)
	var/list/found = list()
	var/list/spare = list()
	for(var/area/location as anything in shuffle(get_areas(/area/maintenance)))
		var/list/area_spots = list()
		for(var/turf/open/floor/spot in location)
			if(is_maintenance_hideout(spot))
				area_spots += spot
			CHECK_TICK
		if(!length(area_spots))
			continue
		found += pick_n_take(area_spots)
		if(length(found) >= count)
			return found
		spare += area_spots
	while(length(found) < count && length(spare))
		var/turf/candidate = pick_n_take(spare)
		var/too_close = FALSE
		for(var/turf/chosen as anything in found)
			if(chosen.z == candidate.z && get_dist(chosen, candidate) < PAPERWORK_HIDEOUT_SPACING)
				too_close = TRUE
				break
		if(!too_close)
			found += candidate
	return found

/// Случайный свободный пол станции в первой из перечисленных зон, где он есть. Клетки у одной стены важнее: груз не встаёт посреди прохода.
/proc/find_paperwork_delivery_turf(list/area_types)
	for(var/area_type in area_types)
		var/list/spots = list()
		var/list/wall_spots = list()
		for(var/area/location as anything in get_areas(area_type))
			if(findtext("[location.type]", "/private"))
				continue
			for(var/turf/open/floor/spot in location)
				if(!is_station_level(spot.z) || spot.is_blocked_turf())
					continue
				spots += spot
				if(hideout_wall_count(spot) == 1)
					wall_spots += spot
			CHECK_TICK
		if(length(spots))
			return pick(length(wall_spots) ? wall_spots : spots)
	return null

/// Описание места словами: отсек, форма закутка и ближайшие приметы той же зоны в прямой видимости. Закреплённые приметы важнее подвижных.
/proc/describe_hideout(turf/spot)
	var/list/parts = list()
	var/area/location = get_area(spot)
	parts += "отсек [location.name]"
	switch(hideout_wall_count(spot))
		if(3)
			parts += "в тупике"
		if(2)
			var/vertical = isclosedturf(get_step(spot, NORTH)) && isclosedturf(get_step(spot, SOUTH))
			var/horizontal = isclosedturf(get_step(spot, EAST)) && isclosedturf(get_step(spot, WEST))
			parts += (vertical || horizontal) ? "в узком проходе" : "в углу"
	var/list/fixed = list()
	var/list/loose = list()
	for(var/obj/thing in range(PAPERWORK_LANDMARK_RANGE, spot))
		if(thing.invisibility || get_area(thing) != location || !can_see(spot, thing, PAPERWORK_LANDMARK_RANGE))
			continue
		if(thing.anchored)
			fixed += thing
		else
			loose += thing
	var/list/found = describe_landmarks(spot, fixed)
	parts += length(found) ? found : describe_landmarks(spot, loose)
	return jointext(parts, ", ")

/proc/describe_landmarks(turf/spot, list/candidates)
	var/static/list/landmarks = list(
		/obj/structure/reagent_dispensers/fueltank = "бака с топливом",
		/obj/structure/reagent_dispensers/watertank = "бака с водой",
		/obj/machinery/portable_atmospherics/canister = "газового баллона",
		/obj/machinery/space_heater = "обогревателя",
		/obj/machinery/power/apc = "щитка APC",
		/obj/machinery/airalarm = "панели воздушной тревоги",
		/obj/structure/closet/firecloset = "пожарного шкафа",
		/obj/structure/closet/emcloset = "аварийного шкафа",
		/obj/structure/closet/crate = "ящика",
		/obj/structure/closet = "шкафчика",
		/obj/structure/rack = "стеллажа",
		/obj/structure/table = "стола",
		/obj/structure/girder = "недостроенной стены",
		/obj/structure/grille = "решётки",
		/obj/structure/chair = "стула",
		/obj/structure/plasticflaps = "пластиковой шторки",
		/obj/structure/sign = "таблички",
		/obj/machinery/vending = "торгового автомата",
		/obj/machinery/door/airlock = "шлюза",
		/obj/machinery/atmospherics/components/unary/vent_pump = "вентиляционной решётки",
		/obj/machinery/atmospherics/components/unary/vent_scrubber = "скруббера",
		/obj/machinery/light = "лампы",
	)
	. = list()
	var/list/used = list()
	for(var/landmark_type in landmarks)
		var/atom/nearest
		for(var/obj/thing as anything in candidates)
			if(!istype(thing, landmark_type) || (thing in used))
				continue
			if(!nearest || get_dist(spot, thing) < get_dist(spot, nearest))
				nearest = thing
		if(!nearest)
			continue
		used += nearest
		. += describe_offset(nearest, spot, landmarks[landmark_type])
		if(length(used) >= PAPERWORK_LANDMARK_COUNT)
			return

/proc/describe_offset(atom/landmark, turf/spot, landmark_name)
	var/distance = get_dist(landmark, spot)
	if(!distance)
		return "прямо у [landmark_name]"
	var/direction = "к [dir2text_ru(get_dir(landmark, spot))]у от [landmark_name]"
	switch(distance)
		if(1)
			return "сразу [direction]"
		if(2)
			return "в двух шагах [direction]"
		if(3)
			return "в трёх шагах [direction]"
	return "в нескольких шагах [direction]"

/// Тихая капсула ЦК без взрыва: груз выкладывается на клетку и капсула улетает.
/proc/paperwork_drop_pod(turf/target, list/atom/movable/cargo)
	var/obj/structure/closet/supplypod/centcompod/pod = new()
	pod.effectQuiet = TRUE
	pod.delays = list(POD_TRANSIT = 8 SECONDS, POD_FALLING = 4, POD_OPENING = 2 SECONDS, POD_LEAVING = 2 SECONDS)
	for(var/atom/movable/thing as anything in cargo)
		thing.forceMove(pod)
	new /obj/effect/pod_landingzone(target, pod)
	return pod

/// Возвратная капсула забирает только свой объект и не везёт его обратно на станцию.
/obj/structure/closet/supplypod/centcompod/paperwork_pickup
	reversing = TRUE
	effectQuiet = TRUE
	delays = list(POD_TRANSIT = 8 SECONDS, POD_FALLING = 4, POD_OPENING = 2 SECONDS, POD_LEAVING = 3 SECONDS)
	var/datum/weakref/cargo_ref

/obj/structure/closet/supplypod/centcompod/paperwork_pickup/Initialize(mapload, customStyle = FALSE, atom/movable/cargo)
	. = ..()
	cargo_ref = WEAKREF(cargo)

/obj/structure/closet/supplypod/centcompod/paperwork_pickup/insertion_allowed(atom/to_insert)
	return to_insert == cargo_ref?.resolve()

/obj/structure/closet/supplypod/centcompod/paperwork_pickup/handleReturnAfterDeparting(atom/movable/holder = src)
	for(var/atom/movable/cargo as anything in contents)
		qdel(cargo)
	qdel(src)

/proc/paperwork_pickup_pod(atom/movable/cargo)
	var/turf/spot = get_turf(cargo)
	if(!spot)
		return null
	var/obj/structure/closet/supplypod/centcompod/paperwork_pickup/pod = new(null, FALSE, cargo)
	new /obj/effect/pod_landingzone(spot, pod)
	return pod

/// Счёт ID-карты, которую человек носит, а если не носит - держит в руке.
/proc/paperwork_account_of(mob/living/user)
	var/obj/item/card/id/card = user?.get_idcard(FALSE)
	return card?.registered_account

/// Сообщение в канал отдела через станционную систему оповещения, если она работает.
/proc/paperwork_radio(message, channel)
	for(var/obj/machinery/announcement_system/announcer as anything in GLOB.announcement_systems)
		if(!is_station_level(announcer.z) || !announcer.is_operational())
			continue
		announcer.radio?.talk_into(announcer, message, channel)
		return TRUE
	return FALSE

/proc/paperwork_print(atom/location, paper_name, text)
	var/obj/item/paper/report = new(location)
	report.name = paper_name
	report.add_raw_text(text, advanced_html = TRUE)
	report.update_appearance()
	return report

/// Предмет исчезает в приёмнике: копия облика опускается внутрь и гаснет.
/obj/effect/temp_visual/paperwork_intake
	randomdir = FALSE
	duration = 6

/obj/effect/temp_visual/paperwork_intake/Initialize(mapload, atom/movable/source)
	. = ..()
	if(!source)
		return
	appearance = source.appearance
	layer = ABOVE_OBJ_LAYER
	plane = GAME_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_x = 0
	pixel_y = PAPERWORK_INTAKE_START_Y
	animate(src, pixel_y = PAPERWORK_INTAKE_LID_Y, time = 0.2 SECONDS, easing = SINE_EASING)
	animate(pixel_y = PAPERWORK_INTAKE_END_Y, alpha = 0, transform = matrix() * PAPERWORK_INTAKE_END_SCALE, time = 0.3 SECONDS, easing = QUAD_EASING | EASE_IN)

#undef PAPERWORK_LANDMARK_RANGE
#undef PAPERWORK_LANDMARK_COUNT
#undef PAPERWORK_HIDEOUT_SPACING
#undef PAPERWORK_HIDEOUT_MIN_PRESSURE
#undef PAPERWORK_HIDEOUT_MAX_PRESSURE
#undef PAPERWORK_HIDEOUT_MIN_TEMP
#undef PAPERWORK_HIDEOUT_MAX_TEMP
#undef PAPERWORK_INTAKE_START_Y
#undef PAPERWORK_INTAKE_LID_Y
#undef PAPERWORK_INTAKE_END_Y
#undef PAPERWORK_INTAKE_END_SCALE
