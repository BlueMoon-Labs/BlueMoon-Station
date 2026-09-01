/// Товары, дописанные вендоматам варэдитом в .dmm: обход по типам их не видит, а в коде они нужны ради детерминированного хэша.
GLOBAL_LIST_INIT(vending_products_from_map_varedits, list(
	// CentCom, /obj/machinery/vending/dinnerware: варэдит contraband.
	/obj/item/reagent_containers/food/condiment/flour,
	// Lambda Station, /obj/machinery/vending/medical: типовой список заменён модульным, кейса там нет.
	/obj/item/storage/briefcase/medical,
	// TauStation, /obj/machinery/vending/barkbox: варэдит products.
	/obj/item/pet_carrier,
))

/// Ассортимент всех типов вендоматов: набор зависит только от кода, поэтому хэш входа стабилен.
/// Инстанс приходится создавать - initial() на списочной переменной отдаёт пустой список, а не типовой дефолт.
/proc/collect_vending_product_types()
	var/list/product_types = list()
	for(var/product_path in GLOB.vending_products_from_map_varedits)
		product_types[product_path] = TRUE

	for(var/vendor_type in typesof(/obj/machinery/vending))
		var/machines_before = length(GLOB.machines)
		var/obj/machinery/vending/vendor = new vendor_type(null)
		// Вендомат-подменыш (cola/random) в Initialize() создаёт случайного брата и удаляет себя:
		// читать с него нечего, а брата надо убрать из нулевого пространства.
		if(!QDELETED(vendor))
			for(var/product_path in vendor.products)
				product_types[product_path] = TRUE
			for(var/product_path in vendor.contraband)
				product_types[product_path] = TRUE
			for(var/product_path in vendor.premium)
				product_types[product_path] = TRUE
			// products конструируемых вендоматов собирает RefreshParts и только при наличии деталей.
			for(var/list/category as anything in vendor.product_categories)
				for(var/product_path in category["products"])
					product_types[product_path] = TRUE
			qdel(vendor)
		qdel_vending_enumeration_strays(machines_before)

	for(var/vendor_type in typesof(/obj/machinery/mineral/equipment_vendor))
		var/machines_before = length(GLOB.machines)
		var/obj/machinery/mineral/equipment_vendor/vendor = new vendor_type(null)
		if(!QDELETED(vendor))
			for(var/datum/data/mining_equipment/prize as anything in vendor.prize_list)
				if(prize.equipment_path)
					product_types[prize.equipment_path] = TRUE
			qdel(vendor)
		qdel_vending_enumeration_strays(machines_before)

	return product_types

/// Снимает машины, созданные чужим Initialize() поверх временной. Индексы собираются в
/// отдельный лист: qdel вычёркивает машину из GLOB.machines прямо в Destroy().
/proc/qdel_vending_enumeration_strays(machines_before)
	if(length(GLOB.machines) <= machines_before)
		return
	var/list/strays = list()
	for(var/index = length(GLOB.machines), index > machines_before, index--)
		strays += GLOB.machines[index]
	for(var/obj/machinery/stray as anything in strays)
		if(!isnull(stray.loc))
			log_asset("spritesheet vending: обход ассортимента принял за подменыша машину с карты и не тронул её: [stray] ([stray.type]) на [COORD(stray)]")
			continue
		qdel(stray)

/// Сколько имён пропущенных товаров печатать в лог.
#define MISSED_VENDING_PRODUCTS_REPORTED 20

/// Сверяет обход с GLOB.vending_products раунда: на картах вне юнит-теста эта строка в логе - единственный сигнал.
/proc/log_vending_products_missed_by_static_walk(list/round_products, list/static_products)
	var/list/missed = list()
	for(var/product_path in round_products)
		if(!static_products[product_path])
			missed += product_path
	if(!length(missed))
		return missed
	var/list/reported = length(missed) > MISSED_VENDING_PRODUCTS_REPORTED ? missed.Copy(1, MISSED_VENDING_PRODUCTS_REPORTED + 1) : missed
	log_asset("spritesheet vending: статический обход не нашёл [length(missed)] товар(ов) из GLOB.vending_products - добраны в лист, но их надо дописать в vending_products_from_map_varedits: [jointext(reported, ", ")]")
	return missed

#undef MISSED_VENDING_PRODUCTS_REPORTED

/// Снимок GLOB.vending_products берётся до обхода: временные вендоматы дописывают ассортимент туда сами.
/proc/collect_vending_sheet_product_types()
	var/list/round_products = GLOB.vending_products.Copy()
	var/list/product_types = collect_vending_product_types()
	for(var/product_path in log_vending_products_missed_by_static_walk(round_products, product_types))
		product_types[product_path] = TRUE
	return product_types

/datum/asset/spritesheet_batched/vending
	name = "vending"
	// Порядок вставки зависит от порядка типов: сортировка держит шарды на месте между раундами.
	sort_sprites = TRUE

/datum/asset/spritesheet_batched/vending/create_spritesheets()
	// Один и тот же DMI обслуживает сотни товаров - разобранные наборы стейтов
	// держим при себе, чтобы не гонять icon_states() по кругу.
	var/list/states_by_file = list()

	var/list/product_types = collect_vending_sheet_product_types()

	for(var/atom/item as anything in product_types)
		if(!ispath(item, /atom))
			continue

		//if (initial(item.greyscale_colors) && initial(item.greyscale_config))
		//	icon_file = SSgreyscale.GetColoredIconByType(initial(item.greyscale_config), initial(item.greyscale_colors))
		//else
		var/icon_file = initial(item.icon)
		var/icon_state = initial(item.icon_state)

		// Апстрим здесь выбрасывает всё, у чего нет GAGS или цвета, и добирает
		// остальное компонентом DMIcon в tgui. DMIcon у нас нет - витрина живёт
		// только на спрайтшите, поэтому в лист идёт каждый товар.

		// Стейта нет в файле - IconForge на таком спрайте роняет генерацию всего
		// листа, а DM-путь такой спрайт молча выбрасывал (Insert() возвращал FALSE
		// на пустой иконке). Повторяем прежний исход: спрайта нет, лист есть.
		// Проверка безусловная именно поэтому: под UNIT_TESTS её было бы мало,
		// сломанный стейт дожил бы до прода и убил там весь ассет.
		var/list/all_states = states_by_file["[icon_file]"]
		if(isnull(all_states))
			all_states = icon_file ? icon_states(icon_file) : list()
			states_by_file["[icon_file]"] = all_states
		if(!(icon_state in all_states))
			continue

		var/imgid = replacetext(replacetext("[item]", "/obj/item/", ""), "/", "-")

		var/datum/universal_icon/sprite = uni_icon(icon_file, icon_state, SOUTH)
		// Цветом атома может быть матрица, а не строка - на DM-пути такой предмет
		// просто вставлялся без окраски, здесь же нестроковый цвет уронил бы лист.
		var/item_color = initial(item.color)
		if(istext(item_color) && uppertext(item_color) != "#FFFFFF")
			sprite.blend_color(item_color, ICON_MULTIPLY)

		insert_icon(imgid, sprite)
