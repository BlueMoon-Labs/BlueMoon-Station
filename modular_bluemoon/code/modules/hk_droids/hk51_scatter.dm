GLOBAL_DATUM_INIT(hk51_scatter, /datum/hk51_part_scatter, new)

/// Раскладывает части HK-51 на старте раунда: мотиватор на фабрику HK, одну часть на чёрный рынок, одну в шкаф техтоннелей станции, остальные по ящикам названных руин без гост-ролей, по одной на руину; не хватит руин - в шкафы техтоннелей других зон, затем второй раз в руину, но не в фабрику.
/datum/hk51_part_scatter
	/// Части на учёте раскладчика: разложенные и купленные на рынке. Пропавшая снова выставляется на рынок.
	var/list/obj/item/hk51_part/spawned_parts = list()
	/// Лоты, выставленные на чёрный рынок.
	var/list/datum/blackmarket_item/market_listings = list()
	/// Раскладка раунда закончена.
	var/scattered = FALSE
	/// Семейства зон руин с гост-ролями: туда части не кладутся.
	var/list/ghost_families = list()
	/// Рамки шаблонов руин с гост-ролями: list(x1, y1, x2, y2, z).
	var/list/ghost_frames = list()

/datum/hk51_part_scatter/New()
	. = ..()
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(on_round_start))

/datum/hk51_part_scatter/Destroy(force)
	UnregisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING)
	for(var/obj/item/hk51_part/part as anything in spawned_parts)
		UnregisterSignal(part, COMSIG_PARENT_QDELETING)
	spawned_parts.Cut()
	var/datum/blackmarket_market/market = SSblackmarket.markets[HK51_MARKET]
	for(var/datum/blackmarket_item/listing as anything in market_listings)
		var/list/category_items = market?.available_items[listing.category]
		category_items -= listing
		qdel(listing)
	market_listings.Cut()
	return ..()

/datum/hk51_part_scatter/proc/on_round_start(datum/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(scatter_round_parts))

/datum/hk51_part_scatter/proc/scatter_round_parts()
	var/list/containers = collect_containers()
	var/list/station_containers = collect_station_containers()
	var/obj/effect/landmark/hk51_part_spot/factory/factory_landmark = locate() in GLOB.landmarks_list
	log_game("Раскладка HK-51: ящиков в руинах [length(containers)], шкафов техтоннелей [length(station_containers)], фабрика [factory_landmark ? "есть" : "не загружена"].")
	var/list/placed = scatter(containers, get_turf(factory_landmark), station_containers)
	for(var/obj/item/hk51_part/part_type as anything in placed)
		var/atom/place = placed[part_type]
		if(place == HK51_PLACE_BLACK_MARKET)
			log_game("Раскладка HK-51: [initial(part_type.name)] выставлен на чёрный рынок.")
		else if(isatom(place))
			log_game("Раскладка HK-51: [initial(part_type.name)] лежит в [place], [AREACOORD(place)].")
		else
			log_game("Раскладка HK-51: [initial(part_type.name)] не разложен - чёрного рынка нет.")
	scattered = TRUE

/// Раскладывает пять частей и возвращает тип части -> контейнер, турф или HK51_PLACE_BLACK_MARKET. Мотиватор - в шкаф на точке фабрики, без шкафа - на пол. Частям без свободной руины достаются шкафы других зон техтоннелей, потом второй ящик уже занятой руины (кроме фабрики), рынок - если нет и их.
/datum/hk51_part_scatter/proc/scatter(list/containers, turf/factory_spot, list/station_containers)
	var/list/placed = list()
	var/list/parts = list()
	var/list/remaining = shuffle(subtypesof(/obj/item/hk51_part))
	station_containers = spread_over_levels(station_containers, length(station_containers))
	var/factory_group
	if(factory_spot)
		factory_group = hk51_place_group(factory_spot)
		var/obj/structure/closet/stash = locate() in factory_spot
		containers = containers - stash
		remaining -= /obj/item/hk51_part/motivator
		var/atom/destination = stash || factory_spot
		parts[/obj/item/hk51_part/motivator] = spawn_part(/obj/item/hk51_part/motivator, destination)
		placed[/obj/item/hk51_part/motivator] = destination
	var/market_part = pick(remaining - /obj/item/hk51_part/motivator)
	remaining -= market_part
	placed[market_part] = list_on_market(market_part)
	if(length(station_containers))
		var/station_part = pick(remaining - /obj/item/hk51_part/motivator)
		remaining -= station_part
		var/obj/structure/closet/station_container = station_containers[1]
		station_containers.Cut(1, 2)
		parts[station_part] = spawn_part(station_part, station_container)
		placed[station_part] = station_container
	var/list/repeats = list()
	var/list/targets = spread_over_levels(containers, length(remaining), repeats, factory_group)
	targets += station_containers
	targets += repeats
	for(var/part_type in remaining)
		if(!length(targets))
			placed[part_type] = list_on_market(part_type)
			continue
		var/obj/structure/closet/container = targets[1]
		targets.Cut(1, 2)
		parts[part_type] = spawn_part(part_type, container)
		placed[part_type] = container
	lay_trail(placed, parts)
	return placed

/// Бирки курьера по кругу: каждая найденная часть называет место следующей, лот рынка - место одной из разложенных.
/datum/hk51_part_scatter/proc/lay_trail(list/placed, list/parts)
	var/list/order = shuffle(placed.Copy())
	var/list/found_places = list()
	for(var/part_type in order)
		if(isatom(placed[part_type]))
			found_places += placed[part_type]
	for(var/i in 1 to length(order))
		var/part_type = order[i]
		var/next_place = placed[order[(i % length(order)) + 1]]
		var/obj/item/hk51_part/part = parts[part_type]
		if(part)
			part.next_node = hk51_place_hint(next_place)
		else
			var/datum/blackmarket_item/misc/hk51_part/listing = listing_for(part_type)
			listing?.set_next_node(length(found_places) ? hk51_place_hint(pick(found_places)) : null)

/datum/hk51_part_scatter/proc/listing_for(part_type)
	for(var/datum/blackmarket_item/misc/hk51_part/listing in market_listings)
		if(listing.item == part_type)
			return listing

/// Выбирает до count контейнеров по кругу между уровнями, не больше одного на руину или зону. Вторые ящики уже взятых групп при недоборе уходят в repeats; группа closed_group не берётся вовсе.
/datum/hk51_part_scatter/proc/spread_over_levels(list/containers, count, list/repeats, closed_group)
	var/list/used_groups = list()
	var/list/by_level = list()
	for(var/obj/structure/closet/container as anything in containers)
		var/turf/container_turf = get_turf(container)
		if(QDELETED(container) || !container_turf)
			continue
		var/level_key = "[container_turf.z]"
		var/list/level_containers = by_level[level_key]
		if(!level_containers)
			level_containers = list()
			by_level[level_key] = level_containers
		level_containers += container
	var/list/queues = list()
	for(var/level_key in by_level)
		queues += list(shuffle(by_level[level_key]))
	shuffle_inplace(queues)
	var/list/picked = list()
	var/round_index = 1
	while(length(picked) < count)
		var/took_any = FALSE
		for(var/list/queue as anything in queues)
			if(round_index > length(queue))
				continue
			took_any = TRUE
			var/obj/structure/closet/container = queue[round_index]
			var/group = hk51_place_group(get_turf(container))
			if(closed_group && group == closed_group)
				continue
			if(used_groups[group])
				if(repeats)
					repeats += container
				continue
			used_groups[group] = TRUE
			picked += container
			if(length(picked) >= count)
				break
		if(!took_any)
			break
		round_index++
	return picked

/datum/hk51_part_scatter/proc/spawn_part(part_type, atom/destination)
	var/obj/item/hk51_part/part = new part_type(destination)
	track(part)
	return part

/// Взять часть на учёт: если она пропадёт не в собранном дроиде, её снова выставят на рынок.
/datum/hk51_part_scatter/proc/track(obj/item/hk51_part/part)
	if(!istype(part) || (part in spawned_parts))
		return
	spawned_parts += part
	RegisterSignal(part, COMSIG_PARENT_QDELETING, PROC_REF(on_part_deleted))

/datum/hk51_part_scatter/proc/on_part_deleted(obj/item/hk51_part/part)
	SIGNAL_HANDLER
	spawned_parts -= part
	if(part.consumed)
		return
	log_game("Раскладка HK-51: [part] пропал в [AREACOORD(part)] и снова выставлен на чёрный рынок.")
	var/datum/blackmarket_item/misc/hk51_part/relisted = market_listing(part.type)
	if(!relisted)
		return
	var/list/found_parts = list()
	for(var/obj/item/hk51_part/other as anything in spawned_parts)
		if(!istype(other.loc, /obj/item/hk51_frame) && get_turf(other))
			found_parts += other
	relisted.set_next_node(length(found_parts) ? hk51_place_hint(pick(found_parts)) : null)

/// Выставляет часть на рынок; HK51_PLACE_BLACK_MARKET или null, если рынка нет.
/datum/hk51_part_scatter/proc/list_on_market(obj/item/hk51_part/part_type)
	return market_listing(part_type) ? HK51_PLACE_BLACK_MARKET : null

/// Лот части с ещё одной штукой: распроданный лот того же типа выставляется снова, иначе заводится новый. add_item() рынка не годится - он бросает кубик доступности.
/datum/hk51_part_scatter/proc/market_listing(obj/item/hk51_part/part_type)
	var/datum/blackmarket_market/market = SSblackmarket.markets[HK51_MARKET]
	if(!market)
		stack_trace("HK-51: no black market for [part_type]")
		return null
	var/datum/blackmarket_item/misc/hk51_part/listing = listing_for(part_type)
	if(listing)
		listing.stock++
		return listing
	var/listing_type = initial(part_type.market_listing)
	listing = new listing_type
	listing.scatter_ref = WEAKREF(src)
	if(!(listing.category in market.categories))
		market.categories += listing.category
		market.available_items[listing.category] = list()
	market.available_items[listing.category] += listing
	market_listings += listing
	return listing

/// Все закрытые шкафы и ящики названных руин в космосе и на лаваленде, кроме руин с гост-ролями.
/datum/hk51_part_scatter/proc/collect_containers()
	find_ghost_bases()
	var/list/containers = list()
	for(var/area/ruin/ruin_area in GLOB.all_areas)
		if(!hk51_named_ruin_area(ruin_area) || ghost_families[hk51_ruin_family(ruin_area.type)])
			continue
		for(var/obj/structure/closet/container in ruin_area)
			if(is_valid_container(container))
				containers += container
		CHECK_TICK
	return containers

/datum/hk51_part_scatter/proc/is_valid_container(obj/structure/closet/container)
	if(container.opened || is_type_in_list(container, HK51_EXCLUDED_CONTAINERS))
		return FALSE
	var/turf/container_turf = container.loc
	return isturf(container_turf) && is_scatter_level(container_turf.z) && is_scatter_spot(container_turf)

/// Турф в зоне руины с названием, вне руин с гост-ролями.
/datum/hk51_part_scatter/proc/is_scatter_spot(turf/spot)
	var/area/ruin/ruin_area = spot.loc
	if(!hk51_named_ruin_area(ruin_area) || ghost_families[hk51_ruin_family(ruin_area.type)])
		return FALSE
	for(var/list/frame as anything in ghost_frames)
		if(hk51_in_frame(spot, frame))
			return FALSE
	return TRUE

/// Запоминает руины с гост-ролями: семейство зоны каждого спавнера и рамку шаблона руины, в которой он стоит.
/datum/hk51_part_scatter/proc/find_ghost_bases(list/spawner_turfs = ghost_spawner_turfs())
	ghost_families = list()
	ghost_frames = list()
	var/list/framed_marks = list()
	for(var/turf/spawner_turf as anything in spawner_turfs)
		var/area/ruin/ruin_area = spawner_turf.loc
		if(istype(ruin_area))
			ghost_families[hk51_ruin_family(ruin_area.type)] = TRUE
		for(var/obj/effect/landmark/ruin/ruin_mark as anything in GLOB.ruin_landmarks)
			if(framed_marks[ruin_mark])
				continue
			var/list/frame = hk51_ruin_frame(ruin_mark)
			if(frame && hk51_in_frame(spawner_turf, frame))
				framed_marks[ruin_mark] = TRUE
				ghost_frames += list(frame)

/// Турфы гост-ролей: спавнеры, оболочки дронов и раздатчики оболочек.
/datum/hk51_part_scatter/proc/ghost_spawner_turfs()
	var/list/spawners = list()
	for(var/role in GLOB.mob_spawners)
		spawners += GLOB.mob_spawners[role]
	for(var/obj/item/drone_shell/shell in GLOB.poi_list)
		spawners += shell
	for(var/obj/machinery/droneDispenser/dispenser in GLOB.machines)
		spawners += dispenser
	var/list/turfs = list()
	for(var/atom/spawner as anything in spawners)
		var/turf/spawner_turf = get_turf(spawner)
		if(spawner_turf)
			turfs |= spawner_turf
	return turfs

/// Закрытые шкафы техтоннелей станции: с найденной там части начинается след к остальным.
/datum/hk51_part_scatter/proc/collect_station_containers()
	var/list/containers = list()
	for(var/area/maintenance/maint_area in GLOB.all_areas)
		for(var/obj/structure/closet/container in maint_area)
			if(is_station_container(container))
				containers += container
		CHECK_TICK
	return containers

/datum/hk51_part_scatter/proc/is_station_container(obj/structure/closet/container)
	if(container.opened || is_type_in_list(container, HK51_EXCLUDED_CONTAINERS))
		return FALSE
	var/turf/container_turf = container.loc
	return isturf(container_turf) && istype(container_turf.loc, /area/maintenance) && is_station_level(container_turf.z)

/datum/hk51_part_scatter/proc/is_scatter_level(z)
	if(is_station_level(z) || is_centcom_level(z) || is_reserved_level(z))
		return FALSE
	return SSmapping.level_has_any_trait(z, HK51_SCATTER_LEVEL_TRAITS)

/// Безымянная зона руины - «Unexplored Location»: по такому названию место не найти.
/proc/hk51_named_ruin_area(area/ruin/ruin_area)
	return istype(ruin_area) && ruin_area.name != /area/ruin::name

/// Верхний предок зоны руины со своим названием: зоны одной базы делят семейство.
/proc/hk51_ruin_family(area/ruin/ruin_type)
	var/family = ruin_type
	var/area/ruin/parent = type2parent(ruin_type)
	while(parent != /area/ruin && ispath(parent, /area/ruin) && initial(parent.name) != /area/ruin::name)
		family = parent
		parent = type2parent(parent)
	return family

/// Рамка загруженного шаблона руины вокруг его метки: list(x1, y1, x2, y2, z), без шаблона - null.
/proc/hk51_ruin_frame(obj/effect/landmark/ruin/ruin_mark)
	var/datum/map_template/ruin/template = ruin_mark.ruin_template
	if(!template || !ruin_mark.z)
		return null
	var/x1 = ruin_mark.x - round(template.width / 2)
	var/y1 = ruin_mark.y - round(template.height / 2)
	return list(x1, y1, x1 + template.width - 1, y1 + template.height - 1, ruin_mark.z)

/proc/hk51_in_frame(turf/spot, list/frame)
	return spot.z == frame[5] && spot.x >= frame[1] && spot.x <= frame[3] && spot.y >= frame[2] && spot.y <= frame[4]

/// Метка шаблона руины, в рамку которого попадает турф.
/proc/hk51_ruin_mark_at(turf/spot)
	for(var/obj/effect/landmark/ruin/ruin_mark as anything in GLOB.ruin_landmarks)
		if(ruin_mark.z != spot.z)
			continue
		var/list/frame = hk51_ruin_frame(ruin_mark)
		if(frame && hk51_in_frame(spot, frame))
			return ruin_mark

/// Руина или зона места: по ней раскладка разводит части, по одной на группу. Руина - рамка её шаблона, вне рамок - семейство зоны.
/proc/hk51_place_group(turf/spot)
	if(!spot)
		return null
	var/obj/effect/landmark/ruin/ruin_mark = hk51_ruin_mark_at(spot)
	if(ruin_mark)
		return ruin_mark
	var/area/place_area = get_area(spot)
	return istype(place_area, /area/ruin) ? hk51_ruin_family(place_area.type) : place_area?.type

/// Подсказка о месте части: зона и сектор, либо чёрный рынок.
/proc/hk51_place_hint(place)
	if(place == HK51_PLACE_BLACK_MARKET)
		return "перекупщикам на чёрный рынок"
	var/turf/place_turf = get_turf(place)
	if(!place_turf)
		return null
	return "[hk51_area_label(place_turf)] ([hk51_sector_name(place_turf.z)])"

/// Имя зоны для бирки; зона без имени руины получает имя шаблона («DK Excavator 453: Bridge») или общего предка («The Skelter: Storage»).
/proc/hk51_area_label(turf/spot)
	var/area/place_area = get_area(spot)
	var/area_name = get_area_name(place_area, TRUE)
	var/obj/effect/landmark/ruin/ruin_mark = hk51_ruin_mark_at(spot)
	var/template_name = ruin_mark?.ruin_template.name
	if(length(template_name))
		template_name = format_text(template_name)
		return findtext(area_name, template_name) ? area_name : "[template_name]: [area_name]"
	if(!istype(place_area, /area/ruin))
		return area_name
	var/area/family = hk51_ruin_family(place_area.type)
	if(family == place_area.type)
		return area_name
	var/family_name = format_text(initial(family.name))
	if(findtext(area_name, family_name))
		return area_name
	return "[family_name]: [area_name]"

/proc/hk51_sector_name(z)
	if(is_station_level(z))
		return "станция"
	if(SSmapping.level_trait(z, ZTRAIT_LAVA_RUINS) || SSmapping.level_trait(z, ZTRAIT_MINING))
		return "лаваленд"
	if(SSmapping.level_trait(z, ZTRAIT_SPACE_RUINS))
		return "открытый космос"
	return "вне зоны связи"
