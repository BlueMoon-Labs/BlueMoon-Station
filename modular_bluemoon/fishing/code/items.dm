// снаряжение, хранение, каталог, анализатор и торговля


// сумка, сеть, трофейное крепление и рыбный рынок
/obj/item/storage/backpack/fishing_bag
	name = "fishing bag"
	desc = "Прочная сумка с утеплёнными карманами для свежепойманной рыбы."
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "fishing_bag"
	item_state = "fishing_bag"

/obj/item/storage/backpack/fishing_bag/carpskin
	name = "carpskin fishing bag"
	desc = "Рыбацкая сумка из выделанной шкуры космического карпа. Слегка пахнет сожалением."
	icon_state = "fishing_bag_carpskin"

/obj/item/storage/backpack/fishing_bag/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_FISH_SAFE_STORAGE, REF(src))

/obj/item/storage/backpack/fishing_bag/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR)
		STR.max_combined_w_class = 30
		STR.max_items = 14
		STR.can_hold = typecacheof(list(/obj/item/fish, /obj/item/bait, /obj/item/fishing_line, /obj/item/fishing_hook, /obj/item/fishing_lure, /obj/item/fishing_rod))

/obj/item/storage/fish_case
	name = "fish case"
	desc = "Небольшой кейс для одной рыбы. Внутри рыба не портится и не погибает."
	icon = 'modular_bluemoon/fishing/icons/obj/storage/case.dmi'
	icon_state = "fishbox"
	w_class = WEIGHT_CLASS_NORMAL
	var/case_capacity = 1

/obj/item/storage/fish_case/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_FISH_SAFE_STORAGE, REF(src))

/obj/item/storage/fish_case/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR)
		STR.max_combined_w_class = 100
		STR.max_items = case_capacity
		STR.can_hold = typecacheof(list(/obj/item/fish))

/obj/item/storage/fish_case/bluespace
	name = "bluespace fish case"
	desc = "Бездонный кейс для рыбы. Внутри рыба не портится и не погибает."
	icon_state = "fishbox_bluespace"
	case_capacity = 12

/obj/item/fishing_net
	name = "fishing net"
	desc = "Сложенная сеть. Разверните её в воде, чтобы ловить рыбу пассивно."
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "fishing_bag"
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/fishing_net/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag || !isturf(target))
		return ..()
	var/turf/turf = target
	if(!istype(turf, /turf/open/water) && !turf.liquids?.reagent_list[/datum/reagent/water])
		to_chat(user, span_warning("You need water to deploy [src]."))
		return
	if(locate(/obj/structure/fishing_net) in turf)
		to_chat(user, span_warning("There's already a net here."))
		return
	new /obj/structure/fishing_net(turf)
	user.visible_message(span_notice("[user] deploys [src]."), span_notice("You deploy [src]."))
	qdel(src)

/obj/structure/fishing_net
	name = "fishing net"
	desc = "Развёрнутая рыболовная сеть. Периодически что-то вылавливает из воды."
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "fishing_bag"
	anchored = TRUE
	density = FALSE
	max_integrity = 100
	var/datum/fish_source/fish_source
	var/next_catch = 0

/obj/structure/fishing_net/Initialize(mapload)
	. = ..()
	fish_source = GLOB.preset_fish_sources[/datum/fish_source/water/any]
	next_catch = world.time + rand(1 MINUTES, 2 MINUTES)
	START_PROCESSING(SSobj, src)

/obj/structure/fishing_net/process(seconds_per_tick)
	if(world.time < next_catch)
		return
	next_catch = world.time + rand(1 MINUTES, 2 MINUTES)
	if(!fish_source)
		return
	var/reward_path = fish_source.roll_reward(null, null, src)
	if(!reward_path || reward_path == FISHING_DUD)
		return
	var/atom/movable/reward = fish_source.spawn_reward(reward_path, get_turf(src), src)
	if(reward)
		visible_message(span_notice("[src] snags [reward]!"))

/obj/structure/fishing_net/attackby(obj/item/item, mob/user, params)
	new /obj/item/fishing_net(get_turf(src))
	user.visible_message(span_notice("[user] folds up [src]."), span_notice("You fold up [src]."))
	qdel(src)

/obj/structure/fishing_net/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/fish_mount
	name = "fish mount"
	desc = "Настенное крепление для трофейной рыбы."
	icon = 'modular_bluemoon/fishing/icons/obj/wallmounts.dmi'
	icon_state = "fish_mount"
	anchored = TRUE
	density = FALSE
	layer = SIGN_LAYER
	max_integrity = 100
	custom_materials = list(/datum/material/wood = SHEET_MATERIAL_AMOUNT)
	resistance_flags = FLAMMABLE
	var/obj/item/fish/mounted_fish

/obj/item/wallframe/fish
	name = "fish mount frame"
	desc = "Каркас для настенного крепления трофейной рыбы. Крепится на стену."
	icon = 'modular_bluemoon/fishing/icons/obj/wallmounts.dmi'
	icon_state = "fish_mount_item"
	result_path = /obj/structure/fish_mount
	custom_materials = list(/datum/material/wood = SHEET_MATERIAL_AMOUNT * 2)
	pixel_shift = 31

/obj/structure/fish_mount/update_overlays()
	. = ..()
	if(mounted_fish)
		var/mutable_appearance/fish_overlay = mutable_appearance(mounted_fish.icon, mounted_fish.icon_state)
		fish_overlay.pixel_y = 4
		. += fish_overlay

/obj/structure/fish_mount/attackby(obj/item/item, mob/user, params)
	if(!istype(item, /obj/item/fish))
		return ..()
	if(mounted_fish)
		to_chat(user, span_warning("[src] already has a fish mounted."))
		return TRUE
	var/obj/item/fish/fish = item
	mounted_fish = fish
	fish.forceMove(src)
	ADD_TRAIT(fish, TRAIT_FISH_STASIS, REF(src))
	fish.catcher_name = user.real_name
	fish.catch_date = time2text(world.realtime, "DD/MM/YYYY")
	name = "[fish.name] mount"
	desc = "Трофей: [fish.name]. Поймана [fish.catcher_name] [fish.catch_date]."
	update_icon()
	user.visible_message(span_notice("[user] mounts [fish] on [src]."), span_notice("You mount [fish] on [src]."))
	return TRUE

/obj/structure/fish_mount/attack_hand(mob/user)
	. = ..()
	if(mounted_fish)
		REMOVE_TRAIT(mounted_fish, TRAIT_FISH_STASIS, REF(src))
		mounted_fish.forceMove(drop_location())
		mounted_fish = null
		name = "fish mount"
		desc = "Настенное крепление для трофейной рыбы."
		update_icon()
		to_chat(user, span_notice("You take the fish off [src]."))

/obj/machinery/fish_market
	name = "fish market"
	desc = "Охлаждаемая витрина, которая покупает свежепойманную рыбу."
	icon = 'icons/obj/vending.dmi'
	icon_state = "seeds"
	density = TRUE
	var/total_payout = 0

/obj/machinery/fish_market/attackby(obj/item/item, mob/living/user, params)
	if(!istype(item, /obj/item/fish))
		return ..()
	var/obj/item/fish/fish = item
	var/price = round(fish.get_export_price(10), 1)
	if(price <= 0)
		to_chat(user, span_warning("[src] refuses [fish]."))
		return TRUE
	var/datum/bank_account/account = SSeconomy.get_dep_account(ACCOUNT_SRV)
	if(account)
		account.adjust_money(price)
	total_payout += price
	to_chat(user, span_nicegreen("[src] buys [fish] for [price] credits."))
	qdel(fish)
	return TRUE

/obj/machinery/fish_market/examine(mob/user)
	. = ..()
	. += span_notice("It has paid out [total_payout] credits so far.")


/obj/item/fish_analyzer
	name = "fish analyzer"
	desc = "Ручной сканер, показывающий здоровье и настроение рыбы."
	icon = 'modular_bluemoon/fishing/icons/obj/devices/scanner.dmi'
	icon_state = "analyzer"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/fish_analyzer/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag)
		return ..()
	if(istype(target, /obj/item/fish))
		var/obj/item/fish/fish = target
		var/new_discovery = SSfishing.discover_fish(fish)
		to_chat(user, span_notice("<b>[fish]</b>: [fish.size] cm, [fish.weight] g, health [round(fish.get_health_percentage() * 100, 1)]%, hunger [round(fish.get_hunger() * 100, 1)]%, beauty [fish.beauty], status [fish.status]."))
		if(fish.fish_traits && length(fish.fish_traits))
			var/list/trait_names = list()
			for(var/trait in fish.fish_traits)
				trait_names += GLOB.fish_traits[trait]?.name
			to_chat(user, span_notice("Traits: [english_list(trait_names)]."))
		if(new_discovery)
			to_chat(user, span_notice("Новый вид записан в рыбный каталог. Открыто видов: [SSfishing.get_discovered_count()]."))
		return
	if(istype(target, /obj/structure/aquarium))
		var/obj/structure/aquarium/aquarium = target
		to_chat(user, span_notice("Water: [aquarium.fluid_type], temperature [round(aquarium.fluid_temp - T0C, 0.1)] C, beauty [aquarium.beauty], [length(aquarium.tracked_fish)] fish."))
		for(var/obj/item/fish/fish in aquarium.tracked_fish)
			to_chat(user, span_notice("- [fish]: health [round(fish.get_health_percentage() * 100, 1)]%, hunger [round(fish.get_hunger() * 100, 1)]%, [fish.status]."))
		return
	return ..()


// рыбный каталог. Карманный справочник по всей рыбе и местам её ловли
/obj/item/fish_catalog
	name = "fish catalog"
	desc = "Водонепроницаемый справочник по рыбе известного космоса."
	icon = 'icons/obj/library.dmi'
	icon_state = "book"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/fish_catalog/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/fish_catalog/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FishCatalog", name)
		ui.open()

/obj/item/fish_catalog/ui_data(mob/user)
	var/list/data = list()
	data["sponsored_by"] = AQUARIUM_COMPANY
	data["discovered_count"] = SSfishing.get_discovered_count()
	var/list/fish_info = list()
	for(var/obj/item/fish/fish_path as anything in subtypesof(/obj/item/fish))
		if(fish_path == /obj/item/fish)
			continue
		if(!initial(fish_path.show_in_catalog) || !(initial(fish_path.fish_flags) & FISH_FLAG_SHOW_IN_CATALOG))
			continue
		if(!initial(fish_path.fish_id))
			continue
		var/list/fish_data = list(
			"name" = initial(fish_path.name),
			"desc" = initial(fish_path.desc),
			"fluid" = initial(fish_path.required_fluid_type),
			"temp_min" = round(initial(fish_path.required_temperature_min) - T0C, 0.1),
			"temp_max" = round(initial(fish_path.required_temperature_max) - T0C, 0.1),
			"feed" = initial(fish_path.food),
			"source" = "Ловится на рыбалке",
			"icon" = sanitize_css_class_name("[initial(fish_path.icon)][initial(fish_path.icon_state)]"),
			"discovered" = SSfishing.discovered_fish[initial(fish_path.fish_id)] ? 1 : 0,
		)
		fish_info += list(fish_data)
	data["fish_info"] = fish_info
	return data


// автомат рыболовных товаров и ящик со снаряжением
/obj/machinery/vending/fishing
	name = "\improper Angler's Friend"
	desc = "Всё, что нужно космическому рыбаку: от червей до аквариумов."
	icon_state = "seeds"
	product_slogans = "Gone fishing!;The fish are biting today!;Don't forget your bait!;A bad day fishing beats a good day working!"
	vend_reply = "Tight lines!"
	products = list(
		/obj/item/fishing_rod = 6,
		/obj/item/fishing_rod/fiberglass = 4,
		/obj/item/fishing_rod/titanium = 2,
		/obj/item/fishing_rod/science = 2,
		/obj/item/fishing_line = 6,
		/obj/item/fishing_line/reinforced = 4,
		/obj/item/fishing_line/bouncy = 3,
		/obj/item/fishing_line/cloaked = 3,
		/obj/item/fishing_hook = 8,
		/obj/item/fishing_hook/weighted = 4,
		/obj/item/fishing_hook/shiny = 4,
		/obj/item/fishing_hook/magnet = 3,
		/obj/item/bait_can/worm = 8,
		/obj/item/bait/doughball = 10,
		/obj/item/fishing_lure/minnow = 5,
		/obj/item/fishing_lure/spoon = 4,
		/obj/item/fishing_lure/grub = 4,
		/obj/item/fish_catalog = 4,
		/obj/item/fish_analyzer = 4,
		/obj/item/aquarium_kit = 2,
		/obj/item/aquarium_conductivity_kit = 2,
		/obj/item/reagent_containers/cup/fish_feed = 6,
		/obj/item/storage/backpack/fishing_bag = 3,
		/obj/item/storage/fish_case = 4,
		/obj/item/fishing_portal_kit = 2,
		/obj/item/fishing_net = 4,
	)
	premium = list(
		/obj/item/fishing_rod/gold = 1,
		/obj/item/fishing_rod/lunar = 1,
		/obj/item/fishing_line/auto_reel = 2,
		/obj/item/fishing_line/bluespace = 2,
		/obj/item/fishing_hook/jaws = 1,
		/obj/item/bait_can/super_baits = 2,
		/obj/item/storage/fish_case/bluespace = 2,
		/obj/item/aquarium_kit/filled = 1,
	)
	refill_canister = null
	default_price = PRICE_NORMAL
	extra_price = PRICE_ABOVE_NORMAL
	payment_department = ACCOUNT_SRV

/obj/structure/closet/crate/fishing
	name = "fishing supply crate"
	desc = "Ящик с рыболовным снаряжением."
	icon_state = "crate"

/obj/structure/closet/crate/fishing/PopulateContents()
	new /obj/item/fishing_rod(src)
	new /obj/item/fishing_line(src)
	new /obj/item/fishing_hook(src)
	new /obj/item/bait_can/worm(src)
	new /obj/item/fishing_lure/minnow(src)
	new /obj/item/fish_catalog(src)
	new /obj/item/bait/doughball(src)
	new /obj/item/storage/fish_case(src)

/obj/item/storage/box/fishing
	name = "fishing kit"
	desc = "Коробка с базовой удочкой и припасами."
	icon_state = "box"

/obj/item/storage/box/fishing/PopulateContents()
	new /obj/item/fishing_rod(src)
	new /obj/item/fishing_line(src)
	new /obj/item/fishing_hook(src)
	new /obj/item/bait/worm(src)
	new /obj/item/fish_catalog(src)
	new /obj/item/fishing_portal_kit(src)
