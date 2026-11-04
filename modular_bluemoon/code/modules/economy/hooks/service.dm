/obj/item
	/// Сложность приготовления для оплаты сервису: число видов ингредиентов рецепта
	var/econ_complexity = 1
	var/econ_paid = FALSE
	/// Общее состояние кусков одного нарезанного блюда
	var/datum/econ_dish/econ_dish

/obj/item/reagent_containers
	var/datum/weakref/econ_pourer

/datum/econ_dish
	var/chef_ref
	var/complexity = 1
	var/dish_type
	var/paid = FALSE

/datum/econ_dish/New(chef_ref, complexity, dish_type)
	src.chef_ref = chef_ref
	src.complexity = complexity
	src.dish_type = dish_type

/proc/econ_on_station(atom/thing)
	var/turf/thing_turf = get_turf(thing)
	return thing_turf && is_station_level(thing_turf.z)

/proc/econ_chef_ref(obj/item/food)
	var/list/sources = food.status_traits ? food.status_traits[TRAIT_FOOD_CHEF_MADE] : null
	return length(sources) ? sources[1] : null

/proc/econ_mob_of_mind_ref(mind_ref)
	if(!istext(mind_ref))
		return null
	var/datum/mind/owner_mind = locate(mind_ref)
	return istype(owner_mind) ? owner_mind.current : null

/// Нарезка делит блюдо повара на куски с общей оплатой; нарезка неприготовленной еды блюдом не считается.
/obj/item/OnCreatedFromProcessing(mob/living/user, obj/item/work_tool, list/chosen_option, atom/original_atom)
	. = ..()
	if(!isitem(original_atom))
		return
	var/obj/item/source = original_atom
	if(source.econ_dish)
		econ_dish = source.econ_dish
		return
	var/chef_ref = econ_chef_ref(source)
	if(!chef_ref || source.econ_paid)
		econ_paid = TRUE
		return
	source.econ_dish = new /datum/econ_dish(chef_ref, source.econ_complexity, source.type)
	econ_dish = source.econ_dish

/proc/econ_food_eaten(obj/item/food, mob/living/eater)
	var/datum/econ_dish/dish = food.econ_dish
	if(food.econ_paid || dish?.paid)
		return
	var/mob/living/chef = econ_mob_of_mind_ref(dish ? dish.chef_ref : econ_chef_ref(food))
	if(!isliving(chef) || !econ_on_station(chef) || !econ_on_station(eater))
		return
	var/datum/economy_department/service/service = SSeconomy.get_department(ACCOUNT_SRV)
	if(!service)
		return
	var/amount = clamp(dish ? dish.complexity : food.econ_complexity, 1, SSeconomy.settings.dish_complexity_max)
	if(service.dish_of_the_day && ispath(dish ? dish.dish_type : food.type, service.dish_of_the_day))
		amount *= SSeconomy.settings.dish_of_the_day_mult
	if(!SSeconomy.record_work(ACCOUNT_SRV, WORK_SRV_DISH, amount, chef, eater, "Блюдо: [food.name]"))
		return
	food.econ_paid = TRUE
	if(dish)
		dish.paid = TRUE

/// Реагенты, которые бар получает готовыми из Booze-O-Mat: коктейлем не считаются
GLOBAL_LIST_EMPTY(econ_bar_stock_reagents)

/obj/machinery/vending/boozeomat/Initialize(mapload)
	. = ..()
	var/list/stock = premium | contraband
	for(var/list/category as anything in product_categories)
		stock |= category["products"]
	econ_note_bar_stock(stock | products)

/proc/econ_note_bar_stock(list/stock)
	var/static/list/checked_paths = list()
	for(var/path in stock)
		if(checked_paths[path] || !ispath(path, /obj/item/reagent_containers))
			continue
		checked_paths[path] = TRUE
		var/obj/item/reagent_containers/sample = new path
		for(var/datum/reagent/reagent as anything in sample.reagents?.reagent_list)
			GLOB.econ_bar_stock_reagents[reagent.type] = TRUE
		qdel(sample)

/// Смешанный напиток: продукт реакции, которому игра ставит качество напитка. Пиво, вино, кофе и прочая база из раздатчиков качества не имеют.
/proc/econ_is_mixed_drink(reagent_type)
	var/static/list/reaction_products
	if(!length(reaction_products))
		reaction_products = list()
		for(var/key in GLOB.chemical_reactions_list)
			for(var/datum/chemical_reaction/reaction as anything in GLOB.chemical_reactions_list[key])
				for(var/product in reaction.results)
					reaction_products[product] = TRUE
	if(!ispath(reagent_type, /datum/reagent/consumable) || !reaction_products[reagent_type] || GLOB.econ_bar_stock_reagents[reagent_type])
		return FALSE
	var/datum/reagent/consumable/drink = reagent_type
	return initial(drink.quality) > 0

/proc/econ_note_pour(obj/item/reagent_containers/receiver, mob/living/user)
	if(istype(receiver) && isliving(user))
		receiver.econ_pourer = WEAKREF(user)

/proc/econ_drink_consumed(obj/item/reagent_containers/glass, mob/living/drinker)
	var/mob/living/pourer = glass.econ_pourer?.resolve()
	if(!isliving(pourer) || !econ_on_station(pourer) || !econ_on_station(drinker))
		return
	var/datum/reagent/main = glass.reagents?.get_master_reagent()
	if(!main || !econ_is_mixed_drink(main.type))
		return
	if(SSeconomy.record_work(ACCOUNT_SRV, WORK_SRV_DRINK, 1, pourer, drinker, "Напиток: [main.name]"))
		glass.econ_pourer = null

/proc/econ_note_harvest(obj/item/seeds/seed, mob/user)
	var/datum/economy_department/service/service = SSeconomy.get_department(ACCOUNT_SRV)
	service?.note_harvest(seed, user)

/proc/econ_note_cleaning(mob/user)
	var/datum/economy_department/service/service = SSeconomy.get_department(ACCOUNT_SRV)
	service?.note_cleaning(user)

/obj/machinery/microwave/examine(mob/user)
	. = ..()
	if(!econ_on_station(src))
		return
	var/datum/economy_department/service/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/price = SSeconomy.settings.work_prices[WORK_SRV_DISH]
	var/obj/item/dish_of_the_day = service?.dish_of_the_day
	. += span_notice("Сервис получает [price] кр., когда приготовленное поваром блюдо съедает другой член экипажа. Блюдо, собранное по рецепту крафта, приносит столько за каждый вид ингредиента, но не больше [price * SSeconomy.settings.dish_complexity_max] кр.[dish_of_the_day ? " Блюдо дня - [initial(dish_of_the_day.name)], за него платят [econ_times_text(SSeconomy.settings.dish_of_the_day_mult)] больше." : ""]")

/obj/item/reagent_containers/food/drinks/shaker/examine(mob/user)
	. = ..()
	if(econ_on_station(src))
		. += span_notice("Сервис получает [SSeconomy.settings.work_prices[WORK_SRV_DRINK]] кр., когда другой член экипажа выпьет налитый вами коктейль. Пиво, вино, соки, газировка из раздатчиков и бутылки из Booze-O-Mat коктейлем не считаются.")

/obj/machinery/hydroponics/examine(mob/user)
	. = ..()
	if(econ_on_station(src))
		. += span_notice("Первый за смену урожай каждого вида или мутации приносит сервису [SSeconomy.settings.work_prices[WORK_SRV_NEW_PLANT]] кр.")

/proc/econ_cleaning_examine()
	var/price = SSeconomy.settings.work_prices[WORK_SRV_CLEANING]
	return span_notice("Каждая отмытая от грязи плитка приносит сервису [price] кр., не больше [SSeconomy.settings.cleaning_cap_per_tick * price] кр. от одного уборщика за [SSeconomy.wait / (1 MINUTES)] мин.")

/obj/item/mop/examine(mob/user)
	. = ..()
	if(econ_on_station(src))
		. += econ_cleaning_examine()

/obj/item/soap/examine(mob/user, distance)
	. = ..()
	if(econ_on_station(src))
		. += econ_cleaning_examine()
