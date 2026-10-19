GLOBAL_DATUM_INIT(hk51_scatter, /datum/hk51_part_scatter, new)

/// Раскладывает части HK-51 на старте раунда: мотиватор на фабрику HK, одну часть на чёрный рынок, остальные по ящикам руин вне станции.
/datum/hk51_part_scatter
	/// Части на учёте раскладчика: разложенные и купленные на рынке. Пропавшая снова выставляется на рынок.
	var/list/obj/item/hk51_part/spawned_parts = list()
	/// Лоты, выставленные на чёрный рынок.
	var/list/datum/blackmarket_item/market_listings = list()
	/// Раскладка раунда закончена.
	var/scattered = FALSE

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
	var/obj/effect/landmark/hk51_part_spot/factory/factory_landmark = locate() in GLOB.landmarks_list
	var/list/placed = scatter(containers, get_turf(factory_landmark))
	for(var/obj/item/hk51_part/part_type as anything in placed)
		var/atom/place = placed[part_type]
		if(place == HK51_PLACE_BLACK_MARKET)
			log_game("Раскладка HK-51: [initial(part_type.name)] выставлен на чёрный рынок.")
		else if(isatom(place))
			log_game("Раскладка HK-51: [initial(part_type.name)] лежит в [place], [AREACOORD(place)].")
		else
			log_game("Раскладка HK-51: [initial(part_type.name)] не разложен - чёрного рынка нет.")
	scattered = TRUE

/// Раскладывает пять частей и возвращает тип части -> контейнер, турф или HK51_PLACE_BLACK_MARKET. Мотиватор - в шкаф на точке фабрики, без шкафа - на пол.
/datum/hk51_part_scatter/proc/scatter(list/containers, turf/factory_spot)
	var/list/placed = list()
	var/list/parts = list()
	var/list/remaining = shuffle(subtypesof(/obj/item/hk51_part))
	if(factory_spot)
		var/obj/structure/closet/stash = locate() in factory_spot
		containers = containers - stash
		remaining -= /obj/item/hk51_part/motivator
		var/atom/destination = stash || factory_spot
		parts[/obj/item/hk51_part/motivator] = spawn_part(/obj/item/hk51_part/motivator, destination)
		placed[/obj/item/hk51_part/motivator] = destination
	var/market_part = pick(remaining - /obj/item/hk51_part/motivator)
	remaining -= market_part
	placed[market_part] = list_on_market(market_part)
	var/list/targets = spread_over_levels(containers, length(remaining))
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

/// Выбирает до count контейнеров, по кругу между уровнями, чтобы части разошлись по разным z.
/datum/hk51_part_scatter/proc/spread_over_levels(list/containers, count)
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
			picked += queue[round_index]
			took_any = TRUE
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

/// Все закрытые шкафы и ящики руин вне станции, центкома и резерва.
/datum/hk51_part_scatter/proc/collect_containers()
	var/list/containers = list()
	for(var/area/ruin/ruin_area in GLOB.all_areas)
		for(var/obj/structure/closet/container in ruin_area)
			if(is_valid_container(container))
				containers += container
		CHECK_TICK
	return containers

/datum/hk51_part_scatter/proc/is_valid_container(obj/structure/closet/container)
	if(container.opened || is_type_in_list(container, HK51_EXCLUDED_CONTAINERS))
		return FALSE
	var/turf/container_turf = container.loc
	if(!isturf(container_turf) || !istype(container_turf.loc, /area/ruin))
		return FALSE
	return is_scatter_level(container_turf.z)

/datum/hk51_part_scatter/proc/is_scatter_level(z)
	return !is_station_level(z) && !is_centcom_level(z) && !is_reserved_level(z)

/// Подсказка о месте части: зона и сектор, либо чёрный рынок.
/proc/hk51_place_hint(place)
	if(place == HK51_PLACE_BLACK_MARKET)
		return "перекупщикам на чёрный рынок"
	var/turf/place_turf = get_turf(place)
	if(!place_turf)
		return null
	return "[get_area_name(place_turf, TRUE)] ([hk51_sector_name(place_turf.z)])"

/proc/hk51_sector_name(z)
	if(SSmapping.level_trait(z, ZTRAIT_ICE_RUINS) || SSmapping.level_trait(z, ZTRAIT_ICE_RUINS_UNDERGROUND))
		return "ледяная луна"
	if(SSmapping.level_trait(z, ZTRAIT_LAVA_RUINS) || SSmapping.level_trait(z, ZTRAIT_MINING))
		return "лаваленд"
	if(SSmapping.level_trait(z, ZTRAIT_SPACE_RUINS))
		return "открытый космос"
	if(is_station_level(z))
		return "станция"
	return "дальний сектор"
