/// Раскладка кладёт пять разных частей: мотиватор - в шкаф на точке фабрики, недостающие контейнеры - на чёрный рынок.
/datum/unit_test/hk51_scatter_distribution

/datum/unit_test/hk51_scatter_distribution/Run()
	var/datum/hk51_part_scatter/scatter = new
	var/turf/factory_spot = run_loc_floor_top_right
	var/obj/structure/closet/stash = allocate(/obj/structure/closet/secure_closet, factory_spot)
	var/list/containers = list(stash)
	for(var/i in 1 to 2)
		containers += allocate(/obj/structure/closet)
	var/list/placed = scatter.scatter(containers, factory_spot)
	TEST_ASSERT_EQUAL(length(placed), 5, "Раскладка разложила не пять частей")
	TEST_ASSERT_EQUAL(placed[/obj/item/hk51_part/motivator], stash, "Мотиватор лёг не в шкаф на точке фабрики")
	TEST_ASSERT_NOTNULL(locate(/obj/item/hk51_part/motivator) in stash, "В шкафу фабрики нет мотиватора")
	var/stash_parts = 0
	for(var/obj/item/hk51_part/stashed in stash)
		stash_parts++
	TEST_ASSERT_EQUAL(stash_parts, 1, "Шкаф фабрики получил ещё одну часть")
	var/market_count = 0
	var/list/used_containers = list()
	for(var/part_type in placed)
		var/place = placed[part_type]
		if(place == HK51_PLACE_BLACK_MARKET)
			market_count++
			continue
		if(!(place in containers))
			continue
		TEST_ASSERT(!(place in used_containers), "Две части легли в один контейнер")
		used_containers += place
		TEST_ASSERT_NOTNULL(locate(part_type) in place, "[part_type] не лежит в своём контейнере")
	TEST_ASSERT_EQUAL(market_count, 2, "На рынок ушла не плановая часть плюс часть за недостающий контейнер")
	TEST_ASSERT_EQUAL(length(used_containers), 3, "Заняты не все контейнеры: шкаф фабрики и оба обычных")
	TEST_ASSERT_EQUAL(length(scatter.spawned_parts), 3, "Раскладчик помнит не все созданные части")
	qdel(scatter)
	for(var/obj/structure/closet/container as anything in containers)
		for(var/obj/item/hk51_part/part in container)
			qdel(part)

/// Без шкафа на точке фабрики мотиватор ложится на её пол.
/datum/unit_test/hk51_scatter_factory_floor

/datum/unit_test/hk51_scatter_factory_floor/Run()
	var/datum/hk51_part_scatter/scatter = new
	var/turf/factory_spot = run_loc_floor_top_right
	var/list/placed = scatter.scatter(list(), factory_spot)
	TEST_ASSERT_EQUAL(placed[/obj/item/hk51_part/motivator], factory_spot, "Мотиватор лёг не на точку фабрики")
	var/obj/item/hk51_part/motivator = locate() in factory_spot
	TEST_ASSERT_NOTNULL(motivator, "На точке фабрики нет мотиватора")
	qdel(scatter)
	qdel(motivator)

/// Без фабрики мотиватор ложится как обычная часть.
/datum/unit_test/hk51_scatter_no_factory

/datum/unit_test/hk51_scatter_no_factory/Run()
	var/datum/hk51_part_scatter/scatter = new
	var/list/containers = list()
	for(var/i in 1 to 4)
		containers += allocate(/obj/structure/closet)
	var/list/placed = scatter.scatter(containers, null)
	TEST_ASSERT_EQUAL(length(placed), 5, "Раскладка разложила не пять частей")
	TEST_ASSERT(placed[/obj/item/hk51_part/motivator] in containers, "Мотиватор без фабрики не лёг в контейнер")
	qdel(scatter)
	for(var/obj/structure/closet/container as anything in containers)
		for(var/obj/item/hk51_part/part in container)
			qdel(part)

/// Часть на рынке - лот с одной штукой, который видит аплинк, и снимается вместе с раскладчиком.
/datum/unit_test/hk51_scatter_market_listing

/datum/unit_test/hk51_scatter_market_listing/Run()
	var/datum/blackmarket_market/market = SSblackmarket.markets[HK51_MARKET]
	TEST_ASSERT_NOTNULL(market, "Нет чёрного рынка для частей HK-51")
	var/obj/item/blackmarket_uplink/uplink = allocate(/obj/item/blackmarket_uplink)
	uplink.viewing_market = HK51_MARKET
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/list/offers_before = list()
	for(var/obj/item/hk51_part/part_type as anything in subtypesof(/obj/item/hk51_part))
		var/listing_type = initial(part_type.market_listing)
		offers_before[listing_type] = count_offers(uplink, viewer, listing_type)

	var/datum/hk51_part_scatter/scatter = new
	var/list/placed = scatter.scatter(list(), null)
	for(var/part_type in placed)
		TEST_ASSERT_EQUAL(placed[part_type], HK51_PLACE_BLACK_MARKET, "[part_type] без контейнеров ушёл не на рынок")
	TEST_ASSERT_EQUAL(length(scatter.market_listings), 5, "На рынке не пять лотов частей")
	for(var/datum/blackmarket_item/listing as anything in scatter.market_listings)
		TEST_ASSERT(listing in market.available_items[listing.category], "Лота [listing.type] нет в категории рынка")
		TEST_ASSERT(listing.category in market.categories, "Категории [listing.category] нет на рынке")
		TEST_ASSERT_EQUAL(listing.stock, 1, "Лот [listing.type] продаёт не одну штуку")
		TEST_ASSERT(listing.price >= HK51_PART_PRICE_MIN && listing.price <= HK51_PART_PRICE_MAX, "Цена [listing.price] вне вилки")
		TEST_ASSERT_EQUAL(count_offers(uplink, viewer, listing.type), offers_before[listing.type] + 1, "Аплинк не показывает лот [listing.type]")

	qdel(scatter)
	for(var/listing_type in offers_before)
		TEST_ASSERT_EQUAL(count_offers(uplink, viewer, listing_type), offers_before[listing_type], "Лот [listing_type] остался после удаления раскладчика")

/datum/unit_test/hk51_scatter_market_listing/proc/count_offers(obj/item/blackmarket_uplink/uplink, mob/viewer, datum/blackmarket_item/listing_type)
	uplink.viewing_category = initial(listing_type.category)
	var/list/data = uplink.ui_data(viewer)
	. = 0
	for(var/list/entry as anything in data["items"])
		if(entry["id"] == listing_type && entry["amount"] == 1)
			.++

/// Одна часть ложится в шкаф техтоннелей станции, мотиватор туда не попадает, и след ведёт от неё дальше.
/datum/unit_test/hk51_scatter_station_part

/datum/unit_test/hk51_scatter_station_part/Run()
	var/datum/hk51_part_scatter/scatter = new
	var/turf/factory_spot = run_loc_floor_top_right
	var/obj/structure/closet/stash = allocate(/obj/structure/closet, factory_spot)
	var/obj/structure/closet/maint_closet = allocate(/obj/structure/closet)
	var/list/containers = list(stash)
	for(var/i in 1 to 3)
		containers += allocate(/obj/structure/closet)
	var/list/placed = scatter.scatter(containers, factory_spot, list(maint_closet))
	TEST_ASSERT_EQUAL(length(placed), 5, "Раскладка разложила не пять частей")
	var/list/station_parts = list()
	for(var/obj/item/hk51_part/part in maint_closet)
		station_parts += part
	TEST_ASSERT_EQUAL(length(station_parts), 1, "В шкаф техтоннелей легла не одна часть")
	var/obj/item/hk51_part/station_part = station_parts[1]
	TEST_ASSERT(!istype(station_part, /obj/item/hk51_part/motivator), "Мотиватор ушёл с фабрики на станцию")
	TEST_ASSERT_EQUAL(placed[station_part.type], maint_closet, "Раскладка не помнит часть станции")
	TEST_ASSERT(length(station_part.next_node), "Часть станции не называет место следующей")
	qdel(scatter)
	for(var/obj/structure/closet/container as anything in containers + maint_closet)
		for(var/obj/item/hk51_part/part in container)
			qdel(part)

/// Раскладка раунда сработала на старте и не берёт контейнеры центкома и резерва; на станции - не больше одной части и только в техтоннелях.
/datum/unit_test/hk51_scatter_off_station

/datum/unit_test/hk51_scatter_off_station/Run()
	var/datum/hk51_part_scatter/scatter = GLOB.hk51_scatter
	TEST_ASSERT_NOTNULL(scatter, "Нет раскладчика частей HK-51")
	var/deadline = world.time + 30 SECONDS
	while(!scatter.scattered && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(scatter.scattered, "Раскладка не сработала на старте раунда")
	TEST_ASSERT(length(scatter.market_listings) >= 1, "Раскладка раунда не выставила часть на рынок")
	var/station_parts = 0
	for(var/obj/item/hk51_part/part as anything in scatter.spawned_parts)
		var/turf/part_turf = get_turf(part)
		if(!is_station_level(part_turf.z))
			continue
		station_parts++
		TEST_ASSERT(istype(get_area(part), /area/maintenance), "[part] лежит на станции вне техтоннелей")
	TEST_ASSERT(station_parts <= 1, "На станции больше одной части: [station_parts]")

	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		TEST_ASSERT(!scatter.is_scatter_level(station_z), "Уровень станции [station_z] годится для частей")
	for(var/centcom_z in SSmapping.levels_by_trait(ZTRAIT_CENTCOM))
		TEST_ASSERT(!scatter.is_scatter_level(centcom_z), "Уровень центкома [centcom_z] годится для частей")
	TEST_ASSERT(!scatter.is_scatter_level(run_loc_floor_bottom_left.z), "Резервный уровень годится для частей")

	var/turf/floor = run_loc_floor_bottom_left
	allocate(/datum/hk_factory_test_floor, floor, /area/ruin)
	var/obj/structure/closet/reserved_closet = allocate(/obj/structure/closet, floor)
	var/valid = scatter.is_valid_container(reserved_closet)
	var/list/collected = scatter.collect_containers()
	TEST_ASSERT(!valid, "Шкаф руины на резервном уровне годится для частей")
	TEST_ASSERT(!(reserved_closet in collected), "Шкаф руины на резервном уровне попал в раскладку")
	for(var/obj/structure/closet/container as anything in collected)
		var/turf/container_turf = get_turf(container)
		TEST_ASSERT(scatter.is_scatter_level(container_turf.z), "[container] собран с уровня [container_turf.z]")
		TEST_ASSERT(istype(get_area(container), /area/ruin), "[container] собран вне руин")

/// Найденные части называют место следующей, а лот рынка - место одной из разложенных.
/datum/unit_test/hk51_scatter_trail

/datum/unit_test/hk51_scatter_trail/Run()
	var/datum/hk51_part_scatter/scatter = new
	var/list/containers = list()
	for(var/i in 1 to 3)
		containers += allocate(/obj/structure/closet)
	var/list/placed = scatter.scatter(containers, run_loc_floor_top_right)
	var/zone_hint = hk51_place_hint(run_loc_floor_bottom_left)
	TEST_ASSERT_NOTNULL(zone_hint, "Подсказка о месте пуста")
	for(var/obj/item/hk51_part/part as anything in scatter.spawned_parts)
		TEST_ASSERT(length(part.next_node), "У [part] нет бирки со следующим узлом")
	for(var/datum/blackmarket_item/misc/hk51_part/listing as anything in scatter.market_listings)
		TEST_ASSERT(length(listing.next_node) && findtext(listing.desc, listing.next_node), "Лот [listing.name] не называет место другой части")
		var/obj/item/hk51_part/bought = listing.spawn_item(run_loc_floor_bottom_left)
		TEST_ASSERT_EQUAL(bought.next_node, listing.next_node, "Купленная часть без бирки продавца")
		TEST_ASSERT(bought in scatter.spawned_parts, "Купленная часть не на учёте раскладчика")
		allocated += bought
	TEST_ASSERT_EQUAL(length(placed), HK51_PART_COUNT, "Раскладка разложила не все части")
	qdel(scatter)
	for(var/obj/item/hk51_part/part in run_loc_floor_top_right)
		qdel(part)
	for(var/obj/structure/closet/container as anything in containers)
		for(var/obj/item/hk51_part/part in container)
			qdel(part)

/// Части и каркас не горят, а пропавшая часть снова выставляется на рынок.
/datum/unit_test/hk51_lost_part_relisted

/datum/unit_test/hk51_lost_part_relisted/Run()
	for(var/obj/item/hk51_part/part_type as anything in subtypesof(/obj/item/hk51_part) + /obj/item/hk51_frame)
		var/flags = initial(part_type.resistance_flags)
		TEST_ASSERT((flags & (INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF)) == (INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF), "[part_type] можно сжечь, растворить или разбить")
	var/datum/hk51_part_scatter/scatter = new
	var/obj/item/hk51_part/head/head = scatter.spawn_part(/obj/item/hk51_part/head, run_loc_floor_bottom_left)
	var/obj/item/hk51_part/chassis/chassis = scatter.spawn_part(/obj/item/hk51_part/chassis, run_loc_floor_top_right)
	qdel(head)
	TEST_ASSERT_EQUAL(length(scatter.market_listings), 1, "Пропавшая часть не вернулась на рынок")
	var/datum/blackmarket_item/misc/hk51_part/relisted = scatter.market_listings[1]
	TEST_ASSERT_EQUAL(relisted.item, /obj/item/hk51_part/head, "На рынок вернулась не та часть")
	TEST_ASSERT_EQUAL(relisted.next_node, hk51_place_hint(chassis), "Новый лот не называет место уцелевшей части")

	var/obj/item/hk51_frame/frame = allocate(/obj/item/hk51_frame)
	frame.install_part(chassis)
	qdel(frame)
	TEST_ASSERT(!QDELETED(chassis), "Удалённый каркас унёс вставленную часть")
	TEST_ASSERT(isturf(chassis.loc), "Часть из удалённого каркаса не выпала на пол")
	TEST_ASSERT_EQUAL(length(scatter.market_listings), 1, "Часть из каркаса выставлена на рынок, хотя цела")
	qdel(scatter)
	qdel(chassis)

/// Купленная и снова пропавшая часть возвращается в тот же лот, и его можно купить ещё раз.
/datum/unit_test/hk51_lost_part_rebuy

/datum/unit_test/hk51_lost_part_rebuy/Run()
	var/datum/blackmarket_market/market = SSblackmarket.markets[HK51_MARKET]
	var/datum/hk51_part_scatter/scatter = new
	scatter.list_on_market(/obj/item/hk51_part/head)
	var/datum/blackmarket_item/misc/hk51_part/listing = scatter.market_listings[1]
	var/list/category_items = market.available_items[listing.category]
	var/list/round_lots = list()
	for(var/datum/blackmarket_item/other as anything in category_items)
		if(other.type == listing.type && other != listing)
			round_lots += other
	category_items -= round_lots
	var/obj/item/blackmarket_uplink/uplink = allocate(/obj/item/blackmarket_uplink)
	uplink.money = HK51_PART_PRICE_MAX * 4
	var/mob/living/carbon/human/buyer = allocate(/mob/living/carbon/human)
	buyer.mind_initialize()
	allocated += buyer.mind
	usr = buyer
	var/bought_first = market.purchase(listing.type, listing.category, SHIPPING_METHOD_LAUNCH, uplink, buyer)
	qdel(listing.spawn_item(run_loc_floor_bottom_left))
	var/listings_after_loss = length(scatter.market_listings)
	var/bought_again = market.purchase(listing.type, listing.category, SHIPPING_METHOD_LAUNCH, uplink, buyer)
	usr = null
	for(var/datum/blackmarket_purchase/purchase in SSblackmarket.queued_purchases)
		if(purchase.uplink == uplink)
			SSblackmarket.queued_purchases -= purchase
			qdel(purchase)
	qdel(scatter)
	category_items += round_lots
	TEST_ASSERT(bought_first, "Лот части не купить")
	TEST_ASSERT_EQUAL(listings_after_loss, 1, "Пропавшая часть выставлена вторым лотом вместо распроданного")
	TEST_ASSERT(bought_again, "Пропавшую купленную часть не купить снова")

/// Каркас принимает каждую часть один раз, растёт оверлеями частей и собирается только целиком.
/datum/unit_test/hk51_frame_assembly

/datum/unit_test/hk51_frame_assembly/Run()
	var/obj/item/hk51_frame/frame = allocate(/obj/item/hk51_frame)
	var/mob/living/carbon/human/roboticist = allocate(/mob/living/carbon/human)
	for(var/part_type in subtypesof(/obj/item/hk51_part))
		TEST_ASSERT(!frame.is_complete(), "Каркас собран раньше [part_type]")
		var/obj/item/hk51_part/part = allocate(part_type)
		roboticist.put_in_active_hand(part)
		frame.attackby(part, roboticist)
		TEST_ASSERT(part.loc == frame, "[part_type] не встал в каркас")
		TEST_ASSERT_EQUAL(frame.icon_state, "frame_0", "Под частями не голый каркас")
		TEST_ASSERT("frame_[part.part_id]" in frame.update_overlays(), "На каркасе не видно [part_type]")
		var/obj/item/hk51_part/duplicate = allocate(part_type)
		roboticist.put_in_active_hand(duplicate)
		frame.attackby(duplicate, roboticist)
		TEST_ASSERT(duplicate.loc != frame, "Второй [part_type] встал в каркас")
	TEST_ASSERT(frame.is_complete(), "Каркас со всеми пятью частями не собран")
	var/obj/item/hk51_part/head = frame.installed["head"]
	qdel(head)
	TEST_ASSERT(!frame.is_complete(), "Удалённая часть осталась в каркасе")
	TEST_ASSERT_NULL(frame.installed["head"], "Каркас помнит удалённую часть")
	TEST_ASSERT(!("frame_head" in frame.update_overlays()), "На каркасе видна удалённая голова")

/// Пеленгатор каркаса: стрелка к недостающей части на этом уровне, рынок - если части только там.
/datum/unit_test/hk51_frame_finder

/datum/unit_test/hk51_frame_finder/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/obj/item/hk51_frame/frame = allocate(/obj/item/hk51_frame, origin)
	var/obj/item/hk51_part/head/head = allocate(/obj/item/hk51_part/head, locate(origin.x + 3, origin.y, origin.z))
	var/reading = frame.finder_reading()
	TEST_ASSERT(findtext(reading, head.name) && findtext(reading, dir2text_ru(EAST)), "Пеленгатор не ведёт к голове на востоке: [reading]")
	frame.install_part(head)
	reading = frame.finder_reading()
	TEST_ASSERT(!findtext(reading, head.name), "Пеленгатор ищет уже вставленную часть: [reading]")

/obj/item/hk51_frame/test_fixture
	var/booted_on_floor = FALSE

/obj/item/hk51_frame/test_fixture/poll_candidates(mob/living/activator)
	booted_on_floor = isturf(loc) && anchored && icon_state == "frame_boot" && !isnull(boot_sound)
	return list()

/// Загрузка идёт на полу перед активатором с анимацией и звуком; без личности каркас снова можно взять.
/datum/unit_test/hk51_frame_boot_on_floor

/datum/unit_test/hk51_frame_boot_on_floor/Run()
	var/obj/item/hk51_frame/test_fixture/frame = allocate(/obj/item/hk51_frame/test_fixture)
	for(var/part_type in subtypesof(/obj/item/hk51_part))
		frame.install_part(allocate(part_type))
	var/mob/living/carbon/human/roboticist = allocate(/mob/living/carbon/human)
	roboticist.setDir(NORTH)
	roboticist.put_in_active_hand(frame)
	frame.activate(roboticist)
	TEST_ASSERT(frame.booted_on_floor, "Каркас грузился не на полу, не закреплён или без анимации и звука")
	TEST_ASSERT_EQUAL(frame.loc, get_step(roboticist, NORTH), "Каркас встал не перед активатором")
	TEST_ASSERT(!(frame in roboticist.held_items), "Каркас остался в руке активатора")
	TEST_ASSERT(!frame.anchored && !frame.activating, "После неудачной загрузки каркас нельзя взять")
	TEST_ASSERT_NULL(frame.boot_sound, "Звук загрузки не остановился")
	TEST_ASSERT_EQUAL(frame.icon_state, "frame_0", "После неудачной загрузки каркас застыл в анимации")

/// Собранный HK-51 получает хозяина-активатора, запись в базе СБ и не становится антагом при хозяине-экипаже.
/datum/unit_test/hk51_build_droid

/datum/unit_test/hk51_build_droid/Run()
	var/obj/item/hk51_frame/frame = allocate(/obj/item/hk51_frame)
	var/list/parts = list()
	for(var/part_type in subtypesof(/obj/item/hk51_part))
		var/obj/item/hk51_part/part = allocate(part_type)
		parts += part
		frame.install_part(part)
	var/mob/living/carbon/human/roboticist = allocate(/mob/living/carbon/human)
	roboticist.mind_initialize()
	allocated += roboticist.mind
	roboticist.setDir(NORTH)
	var/mob/living/carbon/human/droid = frame.build_droid(roboticist, null)
	allocated += list(droid, droid.mind)
	TEST_ASSERT(is_species(droid, /datum/species/ipc/hk/hk51), "Собран не HK-51")
	TEST_ASSERT_EQUAL(droid.loc, get_step(roboticist, NORTH), "Дроид встал не перед активатором")
	var/datum/component/hk_loyalty/loyalty = droid.GetComponent(/datum/component/hk_loyalty)
	TEST_ASSERT_EQUAL(loyalty?.get_master(), roboticist.mind, "Хозяин не активатор")
	TEST_ASSERT(QDELETED(frame), "Каркас не потрачен")
	for(var/obj/item/hk51_part/part as anything in parts)
		TEST_ASSERT(QDELETED(part) && part.consumed, "[part] не ушёл в дроида")
	TEST_ASSERT(!length(droid.mind?.antag_datums), "Хозяин-экипаж дал дроиду антаг-статус")
	TEST_ASSERT_NULL(droid.mind.enslaved_to, "Дроид экипажа порабощён")
	var/obj/item/card/id/card = droid.wear_id
	TEST_ASSERT(istype(card), "У дроида нет ID-карты")
	TEST_ASSERT_EQUAL(card.assignment, HK51_ASSIGNMENT, "На карте не должность дроида")
	TEST_ASSERT(!length(card.access), "Карта дроида что-то открывает")
	TEST_ASSERT_NOTNULL(droid.has_status_effect(/datum/status_effect/hk51_master_tracker), "Нет встроенного датчика хозяина")
	var/obj/item/organ/cyberimp/arm/gun/taser/hk51/taser = droid.getorganslot(ORGAN_SLOT_LEFT_ARM_AUG)
	TEST_ASSERT(istype(taser), "В левом предплечье нет тазера")
	TEST_ASSERT_NULL(droid.getorganslot(ORGAN_SLOT_RIGHT_ARM_AUG), "Правая рука занята: лазеру HK-50 некуда встать")
	var/obj/item/gun/energy/e_gun/advtaser/mounted/hk51/taser_gun = locate() in taser
	TEST_ASSERT(istype(taser_gun?.pin, /obj/item/firing_pin/hk_chassis), "Боёк тазера не сверяет шасси")
	TEST_ASSERT(taser_gun.pin.pin_auth(droid), "Тазер не стреляет у самого HK-51")
	TEST_ASSERT(!taser_gun.pin.pin_auth(roboticist), "Тазер стреляет у человека")
	var/datum/species/ipc/hk/hk51/species = droid.dna.species
	TEST_ASSERT_EQUAL(species.last_voice, "hk51_diagnostic", "Дроид загрузился без строки диагностики")
	var/datum/data/record/record = GLOB.data_core.security_by_id[species.record_id]
	TEST_ASSERT_NOTNULL(record, "HK-51 нет в базе СБ")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_NONE, "HK-51 в базе СБ числится преступником")
	TEST_ASSERT(findtext(record.fields["notes"], roboticist.mind.name), "Запись СБ не называет хозяина")
	TEST_ASSERT_NOTNULL(GLOB.data_core.general_by_id[species.record_id], "HK-51 нет в общем списке экипажа")
	hk51_forget_record(species.record_id)

/datum/unit_test/proc/hk51_forget_record(id)
	var/datum/data/record/security = GLOB.data_core.security_by_id[id]
	var/datum/data/record/general = GLOB.data_core.general_by_id[id]
	GLOB.data_core.security -= security
	GLOB.data_core.general -= general
	GLOB.data_core.security_by_id -= id
	GLOB.data_core.general_by_id -= id
	if(GLOB.data_core.security_by_name[HK51_NAME] == security)
		GLOB.data_core.security_by_name -= HK51_NAME
	if(GLOB.data_core.general_by_name[HK51_NAME] == general)
		GLOB.data_core.general_by_name -= HK51_NAME

/// Хозяин-антагонист забирает HK-51 к себе: разум дроида порабощён активатором, а запись СБ его имени не знает.
/datum/unit_test/hk51_build_droid_antag_master

/datum/unit_test/hk51_build_droid_antag_master/Run()
	var/obj/item/hk51_frame/frame = allocate(/obj/item/hk51_frame)
	for(var/part_type in subtypesof(/obj/item/hk51_part))
		frame.install_part(allocate(part_type))
	var/mob/living/carbon/human/traitor = allocate(/mob/living/carbon/human)
	traitor.mind_initialize()
	allocated += traitor.mind
	traitor.mind.name = "Предатель Сборщик"
	mark_hk47_antag(traitor.mind)
	var/mob/living/carbon/human/droid = frame.build_droid(traitor, null)
	allocated += list(droid, droid.mind)
	var/datum/species/ipc/hk/hk51/species = droid.dna.species
	var/datum/data/record/record = GLOB.data_core.security_by_id[species.record_id]
	var/notes_after_build = record?.fields["notes"]
	var/mob/living/carbon/human/accomplice = allocate(/mob/living/carbon/human)
	accomplice.mind_initialize()
	allocated += accomplice.mind
	accomplice.mind.name = "Сообщник Перепрошивщик"
	mark_hk47_antag(accomplice.mind)
	var/datum/component/hk_loyalty/loyalty = droid.GetComponent(/datum/component/hk_loyalty)
	TEST_ASSERT_EQUAL(droid.mind.enslaved_to, traitor, "Хозяин-антагонист не поработил дроида")
	TEST_ASSERT_EQUAL(loyalty?.get_master(), traitor.mind, "Хозяин не антагонист-активатор")
	loyalty.set_master(accomplice.mind)
	var/notes_after_reprogram = record?.fields["notes"]
	hk51_forget_record(species.record_id)
	TEST_ASSERT_NOTNULL(record, "HK-51 антагониста нет в базе СБ")
	TEST_ASSERT(!findtext(notes_after_build, traitor.mind.name), "Запись СБ называет хозяина-антагониста: [notes_after_build]")
	TEST_ASSERT(!findtext(notes_after_reprogram, accomplice.mind.name), "Перепрошивка антагонистом записала его имя в СБ: [notes_after_reprogram]")

/// Датчик хозяина смотрит на текущего хозяина, переводится сразу после перепрошивки и пуст без хозяина.
/datum/unit_test/hk51_master_tracker

/datum/unit_test/hk51_master_tracker/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human, origin)
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y, origin.z))
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 3, origin.z))
	first.mind_initialize()
	second.mind_initialize()
	allocated += list(first.mind, second.mind)
	var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty, first.mind)
	var/datum/status_effect/hk51_master_tracker/tracker = droid.apply_status_effect(/datum/status_effect/hk51_master_tracker)
	TEST_ASSERT_NOTNULL(tracker?.linked_alert, "У датчика нет алерта")
	TEST_ASSERT_EQUAL(tracker.linked_alert.icon_state, "pinpointer", "Стрелка не на корпусе пинпоинтера")
	TEST_ASSERT_EQUAL(tracker.linked_alert.dir, EAST, "Датчик не смотрит на первого хозяина")
	TEST_ASSERT_EQUAL(tracker.pointer, "pinonclose", "Близкий хозяин не отмечен как близкий")
	loyalty.set_master(second.mind)
	TEST_ASSERT_EQUAL(tracker.linked_alert.dir, NORTH, "Датчик не повернулся к новому хозяину сразу")
	loyalty.set_master(null)
	TEST_ASSERT_EQUAL(tracker.pointer, "pinonnull", "Без хозяина датчик не пуст")
	TEST_ASSERT_EQUAL(tracker.linked_alert.icon_state, "pinpointer", "Пустой датчик потерял корпус")

/// Палубы считаются по-русски, а хозяин без тела отпускает HK-51 на свободу.
/datum/unit_test/hk51_master_gone

/datum/unit_test/hk51_master_gone/Run()
	TEST_ASSERT_EQUAL(hk51_decks_text(1), "1 палубу", "Одна палуба")
	TEST_ASSERT_EQUAL(hk51_decks_text(3), "3 палубы", "Три палубы")
	TEST_ASSERT_EQUAL(hk51_decks_text(5), "5 палуб", "Пять палуб")
	TEST_ASSERT_EQUAL(hk51_decks_text(12), "12 палуб", "Двенадцать палуб")
	TEST_ASSERT_NULL(hk51_deck_relation(run_loc_floor_bottom_left, run_loc_floor_top_right), "Один уровень посчитан палубой")

	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human)
	master.mind_initialize()
	var/datum/mind/master_mind = master.mind
	allocated += master_mind
	var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty, master_mind)
	var/datum/status_effect/hk51_master_tracker/tracker = droid.apply_status_effect(/datum/status_effect/hk51_master_tracker)
	TEST_ASSERT(!tracker.check_master_gone(), "Живой хозяин считается ушедшим")
	qdel(master)
	TEST_ASSERT(tracker.check_master_gone(), "Хозяин без тела не отпустил дроида")
	TEST_ASSERT_NULL(loyalty.get_master(), "После ухода хозяина блок лояльности не сброшен")

/// Протокол телохранителя: нападение на хозяина даёт алерт с направлением и метку над нападавшим, своего хозяина и себя не метит.
/datum/unit_test/hk51_bodyguard_protocol

/datum/unit_test/hk51_bodyguard_protocol/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human, origin)
	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y, origin.z))
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 3, origin.z))
	master.mind_initialize()
	allocated += master.mind
	droid.AddComponent(/datum/component/hk_loyalty, master.mind)
	var/datum/status_effect/hk51_master_tracker/tracker = droid.apply_status_effect(/datum/status_effect/hk51_master_tracker)
	SEND_SIGNAL(master, COMSIG_LIVING_ATTACKER_SET, droid)
	TEST_ASSERT_NULL(droid.alerts["hk51_threat"], "Дроид пометил сам себя")
	SEND_SIGNAL(master, COMSIG_LIVING_ATTACKER_SET, attacker)
	var/atom/movable/screen/alert/hk51_threat/alert = droid.alerts["hk51_threat"]
	TEST_ASSERT_NOTNULL(alert, "Нападение на хозяина не подняло алерт")
	TEST_ASSERT_EQUAL(alert.dir, NORTH, "Алерт не показывает направление на нападавшего")
	TEST_ASSERT(findtext(alert.desc, attacker.name), "Алерт не называет нападавшего")
	var/datum/weakref/attacker_ref = WEAKREF(attacker)
	var/image/mark = LAZYACCESS(tracker.threat_marks, attacker_ref)
	TEST_ASSERT_NOTNULL(mark, "Над нападавшим нет метки")
	TEST_ASSERT(!(mark.appearance_flags & RESET_ALPHA), "Метка не тускнеет вместе с прозрачным нападавшим")
	qdel(attacker)
	TEST_ASSERT_NULL(LAZYACCESS(tracker.threat_marks, attacker_ref), "Метка пережила нападавшего")
	TEST_ASSERT_NULL(mark.loc, "Метка держит удалённого нападавшего")

/// Невидимку протокол телохранителя не опознаёт: тревога без имени, направления и метки.
/datum/unit_test/hk51_bodyguard_stealth

/datum/unit_test/hk51_bodyguard_stealth/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human, origin)
	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y, origin.z))
	var/mob/living/carbon/human/ninja = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 3, origin.z))
	ninja.name = "Тень в стелсе"
	ninja.alpha = HK47_STEALTH_ALPHA / 2
	master.mind_initialize()
	allocated += master.mind
	droid.AddComponent(/datum/component/hk_loyalty, master.mind)
	var/datum/status_effect/hk51_master_tracker/tracker = droid.apply_status_effect(/datum/status_effect/hk51_master_tracker)
	SEND_SIGNAL(master, COMSIG_LIVING_ATTACKER_SET, ninja)
	var/atom/movable/screen/alert/hk51_threat/alert = droid.alerts["hk51_threat"]
	TEST_ASSERT_NOTNULL(alert, "Нападение невидимки на хозяина прошло без тревоги")
	TEST_ASSERT(!findtext(alert.desc, ninja.name), "Тревога назвала невидимку")
	TEST_ASSERT(!length(alert.overlays), "Тревога показала направление на невидимку")
	TEST_ASSERT_NULL(LAZYACCESS(tracker.threat_marks, WEAKREF(ninja)), "Метка выдала невидимку")

/// Голос HK-51: свой файл на каждую строку, «удаления» - только после затишья, сбой эффективности - при входе в крит, верность - при смене хозяина.
/datum/unit_test/hk51_voice_lines

/datum/unit_test/hk51_voice_lines/Run()
	var/list/expected = list("hk51_diagnostic", "hk51_loyalty", "hk51_deletions", "hk51_efficiency_down")
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk51)
	var/datum/species/ipc/hk/hk51/species = droid.dna.species
	TEST_ASSERT_EQUAL(length(species.voice_lines), length(expected), "Число голосовых строк HK-51")
	for(var/key in expected)
		var/voice = species.voice_lines[key]
		TEST_ASSERT(isfile(voice), "[key] без звука")
		TEST_ASSERT_EQUAL("[voice]", "modular_bluemoon/sound/hk_droids/[key].ogg", "[key] играет чужой файл")

	TEST_ASSERT(species.note_combat(droid), "Первый бой начался без строки об удалениях")
	COOLDOWN_RESET(species, voice_cooldown)
	TEST_ASSERT(!species.note_combat(droid), "Строка повторилась посреди боя")
	species.last_combat_time = world.time - HK51_COMBAT_CALM_TIME
	TEST_ASSERT(species.note_combat(droid), "Новый бой после затишья прошёл молча")
	TEST_ASSERT(world.time < species.voice_busy_until, "Голосовая строка не заняла вокабулятор")

	COOLDOWN_RESET(species, voice_cooldown)
	species.last_voice = null
	var/obj/item/bodypart/chest = droid.get_bodypart(BODY_ZONE_CHEST)
	chest.receive_damage(droid.health - droid.crit_threshold + 10, wound_bonus = CANT_WOUND)
	TEST_ASSERT(droid.InCritical(), "Дроид не в крите: здоровье [droid.health], состояние [droid.stat]")
	TEST_ASSERT_EQUAL(species.last_voice, "hk51_efficiency_down", "Вход в крит прошёл без строки о боеспособности")

	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human)
	surgeon.mind_initialize()
	allocated += surgeon.mind
	var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty)
	loyalty.set_master(surgeon.mind)
	TEST_ASSERT_EQUAL(species.last_voice, "hk51_loyalty", "Новый хозяин не услышал строку о верности сразу после другой строки")

/datum/antagonist/hk47/contract_fixture/roll_rival_offer()
	return TRUE

/// Спецзаказ на HK-51: только живой HK-51 игрока с согласием на убийство; при принятии о заказе узнают хозяин и сам дроид.
/datum/unit_test/hk51_rival_offer

/datum/unit_test/hk51_rival_offer/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	TEST_ASSERT_NULL(hunter.rival_offer(), "Без HK-51 появился спецзаказ")

	var/datum/mind/master = hunter.add_crew(src, "Roboticist", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/rival = hunter.add_crew(src, HK51_ASSIGNMENT, ANTAG_OPT_IN_TEMPORARY)
	var/mob/living/carbon/human/rival_body = rival.current
	rival_body.set_species(/datum/species/ipc/hk/hk51)
	rival_body.AddComponent(/datum/component/hk_loyalty, master)
	TEST_ASSERT_NULL(hunter.rival_offer(), "HK-51 без согласия на убийство попал в спецзаказ")

	rival.antag_opt_in_level = ANTAG_OPT_IN_KILL
	hunter.test_style = ANTAG_OBJECTIVE_STYLE_QUIET
	TEST_ASSERT_NULL(hunter.rival_offer(), "Стиль без убийств получил спецзаказ")
	hunter.test_style = ANTAG_OBJECTIVE_STYLE_NORMAL

	hunter.generate_offers()
	TEST_ASSERT(length(hunter.offers) <= HK47_CONTRACT_OFFERS, "Спецзаказ добавился сверх списка, а не заменил предложение")
	var/datum/hk_contract/special
	for(var/datum/hk_contract/offer as anything in hunter.offers)
		if(istype(offer.task, /datum/hk_contract_task/kill/rival))
			special = offer
	TEST_ASSERT_NOTNULL(special, "Живой HK-51 не принёс спецзаказ")
	TEST_ASSERT_EQUAL(special.target_mind(), rival, "Цель спецзаказа - не HK-51")
	TEST_ASSERT_NOTEQUAL(special.client_id, HK_CLIENT_CENTCOM, "ЦК заказал HK-51")
	TEST_ASSERT_EQUAL(special.task.points, HK47_RIVAL_POINTS, "Спецзаказ стоит не дороже обычного")
	TEST_ASSERT(hunter.accept(special), "Спецзаказ нельзя принять")
	TEST_ASSERT_EQUAL(length(hunter.test_vip_messages), 2, "О заказе сказали не хозяину и дроиду по разу")
	TEST_ASSERT_EQUAL(findtext(hunter.test_vip_messages[1], master.current.real_name), 1, "Первое сообщение не хозяину HK-51")
	TEST_ASSERT_EQUAL(findtext(hunter.test_vip_messages[2], rival_body.real_name), 1, "Второе сообщение не самому HK-51")

	rival_body.death()
	TEST_ASSERT_NULL(hunter.rival_offer(), "Мёртвый HK-51 попал в спецзаказ")
