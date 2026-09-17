/* BLUEMOON EDIT START
 * Хелперы нового интерфейса карго: превью-иконки товаров, содержимое паков.
 * Иконки считаются лениво, по требованию клиента, и кэшируются один раз за раунд,
 * потому что getFlatIcon достаточно дорогой (билд без iconRefMap - только base64).
 */

/// Кэш превью-иконок по typepath товара: typepath -> base64
GLOBAL_LIST_EMPTY(cargo_item_icon_cache)
/// Кэш инвентаря пака по id: id -> list("icon" = base64|null, "contents" = list(name/amount))
GLOBAL_LIST_EMPTY(cargo_pack_inventory_cache)

/**
 * Возвращает typepath первого содержимого пака. По нему рисуется превью-иконка
 * в каталоге. Возвращает null, если пак пустой.
 */
/datum/supply_pack/proc/get_first_item_type()
	for(var/item_type in contains)
		if(ispath(item_type))
			return item_type
	return null

/**
 * Возвращает содержимое пака для окна "Подробнее": список name + amount.
 * Иконки отдельных позиций не строим - каталог уже показывает иконку первого
 * предмета, а instantiate всего содержимого на каждую позицию слишком дорог.
 */
/datum/supply_pack/proc/get_ui_contents_data()
	var/list/data = list()
	var/list/items = contains
	for(var/item_type in items)
		var/atom/movable/item = new item_type()
		data += list(list(
			"name" = item.name,
			"amount" = items[item_type]
		))
		qdel(item)
	return data

/**
 * Данные строки каталога: превью-иконка и содержимое пака. Кэшируются на сервере.
 */
/proc/get_cargo_pack_inventory_data(pack_id)
	if(GLOB.cargo_pack_inventory_cache[pack_id])
		return GLOB.cargo_pack_inventory_cache[pack_id]

	var/list/inventory = list()
	// к нам приходит строковый id пака (typepath в текстовом виде), приводим к типичному пути
	var/datum/supply_pack/P = SSshuttle.supply_packs[text2path(pack_id) || pack_id]
	if(istype(P))
		inventory["icon"] = get_cargo_item_preview_image(P.get_first_item_type())
		inventory["contents"] = P.get_ui_contents_data()
	GLOB.cargo_pack_inventory_cache[pack_id] = inventory
	return inventory

/**
 * Превью-иконка товара в base64 для tgui. Считается один раз за раунд на typepath.
 */
/proc/get_cargo_item_preview_image(typepath)
	if(!ispath(typepath))
		return null
	if(GLOB.cargo_item_icon_cache[typepath])
		return GLOB.cargo_item_icon_cache[typepath]

	var/icon/preview_icon
	var/atom/movable/item
	try
		item = new typepath()
		preview_icon = getFlatIcon(item)
	catch
		preview_icon = null
	if(!isnull(item))
		qdel(item)
	if(!isicon(preview_icon))
		return null

	var/result = icon2base64(preview_icon)
	GLOB.cargo_item_icon_cache[typepath] = result
	return result

// BLUEMOON EDIT END