/datum/unit_test/economy_work/service
	abstract_type = /datum/unit_test/economy_work/service
	var/datum/economy_department/service/service
	var/turf/station_turf
	var/saved_dish
	var/saved_next_roll
	var/list/saved_plants
	var/list/saved_cleaned

/datum/unit_test/economy_work/service/proc/setup_service()
	setup_pair()
	service = SSeconomy.get_department(ACCOUNT_SRV)
	budget = service.account
	saved_budget = budget.account_balance
	saved_dish = service.dish_of_the_day
	saved_next_roll = service.next_dish_roll
	saved_plants = service.plants_seen.Copy()
	saved_cleaned = service.cleaned_this_tick.Copy()
	service.dish_of_the_day = null
	service.plants_seen.Cut()
	service.cleaned_this_tick.Cut()
	station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	performer.forceMove(station_turf)
	patient.forceMove(station_turf)

/datum/unit_test/economy_work/service/Destroy()
	if(service)
		service.dish_of_the_day = saved_dish
		service.next_dish_roll = saved_next_roll
		service.plants_seen = saved_plants
		service.cleaned_this_tick = saved_cleaned
		service = null
	station_turf = null
	return ..()

/datum/unit_test/economy_work/service/proc/chef_dish(dish_type, complexity)
	var/obj/item/reagent_containers/food/snacks/dish = allocate(dish_type, station_turf)
	ADD_TRAIT(dish, TRAIT_FOOD_CHEF_MADE, REF(performer.mind))
	dish.econ_complexity = complexity
	dish.reagents.add_reagent(/datum/reagent/consumable/nutriment, 10)
	return dish

/datum/unit_test/economy_work/service/proc/new_guest(turf/where)
	var/mob/living/carbon/human/guest = allocate(/mob/living/carbon/human, where || station_turf)
	guest.mind_initialize()
	guest.mind.key = "econ_test_guest"
	return guest

/datum/unit_test/economy_work/service/proc/cut(obj/item/reagent_containers/food/snacks/food, result_type, amount, mob/user)
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife, station_turf)
	var/turf/food_turf = get_turf(food)
	food.StartProcessingAtom(user, knife, list(TOOL_PROCESSING_RESULT = result_type, TOOL_PROCESSING_AMOUNT = amount, TOOL_PROCESSING_TIME = 0))
	. = list()
	for(var/obj/item/piece in food_turf)
		if(istype(piece, result_type))
			. += piece
			allocated += piece

/datum/unit_test/economy_work/service/proc/glass_of(reagent_type)
	var/obj/item/reagent_containers/food/drinks/drinkingglass/glass = allocate(/obj/item/reagent_containers/food/drinks/drinkingglass, station_turf)
	glass.reagents.add_reagent(reagent_type, 20)
	glass.econ_pourer = WEAKREF(performer)
	return glass

/datum/unit_test/economy_work/service/proc/harvest_tray(seed_type, turf/where)
	var/obj/machinery/hydroponics/constructable/tray = allocate(/obj/machinery/hydroponics/constructable, where)
	var/obj/item/seeds/seed = new seed_type(tray)
	tray.myseed = seed
	tray.harvest = TRUE
	tray.attack_hand(performer)
	for(var/obj/item/reagent_containers/food/snacks/grown/product in performer.loc)
		qdel(product)

/// Блюдо повара, съеденное другим, платит сервису по сложности один раз: второй едок того же блюда ничего не приносит.
/datum/unit_test/economy_work/service/dish_paid_once/Run()
	setup_service()
	var/obj/item/reagent_containers/food/snacks/dish = chef_dish(/obj/item/reagent_containers/food/snacks/meat/steak, 3)
	var/mob/living/carbon/human/guest = new_guest()
	var/before = budget.account_balance
	dish.attack(patient, patient)
	dish.attack(guest, guest)
	TEST_ASSERT_EQUAL(dish.bitecount, 2, "Оба откусили блюдо")
	TEST_ASSERT_EQUAL(budget.account_balance - before, 3 * SSeconomy.settings.work_prices[WORK_SRV_DISH], "Один раз по сложности")
	TEST_ASSERT(dish.econ_paid, "Блюдо помечено оплаченным")

/// Повар, съевший своё блюдо, едок вне станции и повар вне станции не приносят сервису ничего.
/datum/unit_test/economy_work/service/dish_refusals/Run()
	setup_service()
	var/obj/item/reagent_containers/food/snacks/dish = chef_dish(/obj/item/reagent_containers/food/snacks/meat/steak, 1)
	var/before = budget.account_balance
	dish.attack(performer, performer)
	patient.forceMove(run_loc_floor_top_right)
	dish.attack(patient, patient)
	var/mob/living/carbon/human/guest = new_guest()
	performer.forceMove(run_loc_floor_bottom_left)
	dish.attack(guest, guest)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Сам себе и вне станции")
	TEST_ASSERT(!dish.econ_paid, "Блюдо осталось неоплаченным")

/// Блюдо дня платит с множителем, сложность упирается в потолок, тик экономики объявляет блюдо дня из общедоступных рецептов.
/datum/unit_test/economy_work/service/dish_of_the_day/Run()
	setup_service()
	service.dish_of_the_day = /obj/item/reagent_containers/food/snacks/meat/steak
	var/obj/item/reagent_containers/food/snacks/dish = chef_dish(/obj/item/reagent_containers/food/snacks/meat/steak, 99)
	var/before = budget.account_balance
	dish.attack(patient, patient)
	TEST_ASSERT_EQUAL(budget.account_balance - before, SSeconomy.settings.dish_complexity_max * SSeconomy.settings.dish_of_the_day_mult * SSeconomy.settings.work_prices[WORK_SRV_DISH], "Блюдо дня по потолку сложности")
	var/list/saved_pending = SSmarket.pending_news
	SSmarket.pending_news = list()
	service.dish_of_the_day = null
	service.next_dish_roll = 0
	service.on_economy_tick()
	TEST_ASSERT(ispath(service.dish_of_the_day, /obj/item), "Блюдо дня выбрано")
	TEST_ASSERT(service.next_dish_roll > world.time, "Следующий выбор отложен")
	var/list/queued = SSmarket.pending_news
	SSmarket.pending_news = saved_pending
	TEST_ASSERT_EQUAL(length(queued), 1, "Объявление ждёт выпуска новостей рынка")
	var/announcement = queued[1]
	var/obj/item/announced = service.dish_of_the_day
	TEST_ASSERT(findtext(announcement, "[initial(announced.name)]"), "В объявлении название блюда: [announcement]")
	var/announced_dish = service.dish_of_the_day
	service.on_economy_tick()
	TEST_ASSERT_EQUAL(service.dish_of_the_day, announced_dish, "До конца часа блюдо дня не меняется")
	var/list/available = list()
	var/list/learned_only = list()
	for(var/datum/crafting_recipe/food/recipe as anything in subtypesof(/datum/crafting_recipe/food))
		if(initial(recipe.always_availible))
			available |= initial(recipe.result)
		else
			learned_only |= initial(recipe.result)
	learned_only -= available
	TEST_ASSERT(length(learned_only), "Есть блюда, которые надо выучить")
	var/list/candidates = service.dish_candidates()
	for(var/result in learned_only)
		TEST_ASSERT(!(result in candidates), "Выучиваемое [result] может стать блюдом дня")

/// Куски нарезанного блюда повара оплачиваются один раз за всё блюдо; нарезка неприготовленной еды блюдом не делает.
/datum/unit_test/economy_work/service/dish_slices/Run()
	setup_service()
	var/obj/item/reagent_containers/food/snacks/pizza/margherita/pizza = chef_dish(/obj/item/reagent_containers/food/snacks/pizza/margherita, 4)
	var/list/slices = cut(pizza, pizza.slice_path, 2, patient)
	TEST_ASSERT_EQUAL(length(slices), 2, "Пицца нарезана")
	var/obj/item/reagent_containers/food/snacks/first = slices[1]
	var/obj/item/reagent_containers/food/snacks/second = slices[2]
	var/mob/living/carbon/human/guest = new_guest()
	var/before = budget.account_balance
	first.attack(patient, patient)
	second.attack(guest, guest)
	TEST_ASSERT_EQUAL(budget.account_balance - before, 4 * SSeconomy.settings.work_prices[WORK_SRV_DISH], "Пицца оплачена один раз по своей сложности")
	var/obj/item/reagent_containers/food/snacks/store/cheesewheel/wheel = allocate(/obj/item/reagent_containers/food/snacks/store/cheesewheel, station_turf)
	var/list/wedges = cut(wheel, /obj/item/reagent_containers/food/snacks/cheesewedge, 1, performer)
	TEST_ASSERT_EQUAL(length(wedges), 1, "Сыр нарезан")
	var/obj/item/reagent_containers/food/snacks/wedge = wedges[1]
	var/mob/living/carbon/human/stranger = new_guest()
	stranger.mind.key = "econ_test_stranger"
	before = budget.account_balance
	wedge.attack(stranger, stranger)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Нарезанный сыр не блюдо")

/// Блюдо со стола крафта помечено поваром и сложностью по числу видов ингредиентов.
/datum/unit_test/economy_work/service/crafted_dish/Run()
	setup_service()
	performer.forceMove(run_loc_floor_bottom_left)
	var/datum/crafting_recipe/food/sandwich/recipe = new
	allocated += recipe
	for(var/ingredient in recipe.reqs)
		for(var/i in 1 to recipe.reqs[ingredient])
			allocate(ingredient)
	var/datum/component/personal_crafting/crafting = performer.GetComponent(/datum/component/personal_crafting)
	var/obj/item/sandwich = crafting.construct_item(performer, recipe)
	TEST_ASSERT(istype(sandwich, recipe.result), "Сэндвич собран: [sandwich]")
	allocated += sandwich
	TEST_ASSERT(HAS_TRAIT_FROM(sandwich, TRAIT_FOOD_CHEF_MADE, REF(performer.mind)), "Сэндвич помечен поваром")
	TEST_ASSERT_EQUAL(sandwich.econ_complexity, length(recipe.reqs), "Сложность по видам ингредиентов")

/// Коктейль из шейкера, налитый барменом, платит при глотке другого один раз.
/datum/unit_test/economy_work/service/drink/Run()
	setup_service()
	var/obj/item/reagent_containers/food/drinks/shaker/shaker = allocate(/obj/item/reagent_containers/food/drinks/shaker, station_turf)
	var/obj/item/reagent_containers/food/drinks/drinkingglass/glass = allocate(/obj/item/reagent_containers/food/drinks/drinkingglass, station_turf)
	shaker.reagents.add_reagent(/datum/reagent/consumable/ethanol/vodka, 20)
	shaker.reagents.add_reagent(/datum/reagent/consumable/orangejuice, 10)
	TEST_ASSERT(shaker.reagents.has_reagent(/datum/reagent/consumable/ethanol/screwdrivercocktail), "Отвёртка смешалась")
	shaker.afterattack(glass, performer, TRUE)
	TEST_ASSERT_NOTNULL(glass.econ_pourer, "Бармен налил")
	var/before = budget.account_balance
	glass.attack(patient, patient)
	TEST_ASSERT(patient.reagents.has_reagent(/datum/reagent/consumable/ethanol/screwdrivercocktail), "Пациент отпил")
	glass.attack(patient, patient)
	TEST_ASSERT_EQUAL(budget.account_balance - before, SSeconomy.settings.work_prices[WORK_SRV_DRINK], "Коктейль")
	TEST_ASSERT_NULL(glass.econ_pourer, "Оплачен один раз")

/// Вода, напитки раздатчиков и бутылки Booze-O-Mat, даже получаемые реакцией, коктейлем не считаются.
/datum/unit_test/economy_work/service/drink_plain/Run()
	setup_service()
	var/before = budget.account_balance
	for(var/reagent_type in list(/datum/reagent/water, /datum/reagent/consumable/ethanol/beer, /datum/reagent/consumable/coffee))
		var/obj/item/reagent_containers/food/drinks/drinkingglass/glass = glass_of(reagent_type)
		glass.attack(patient, patient)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Базовые напитки не коктейли")
	for(var/dispenser_type in list(/obj/machinery/chem_dispenser/drinks, /obj/machinery/chem_dispenser/drinks/beer))
		var/obj/machinery/chem_dispenser/dispenser = allocate(dispenser_type)
		for(var/reagent_type in dispenser.dispensable_reagents | dispenser.upgrade_reagents | dispenser.upgrade_reagents2 | dispenser.upgrade_reagents3)
			TEST_ASSERT(!econ_is_mixed_drink(reagent_type), "[reagent_type] из [dispenser_type] считается коктейлем")
	var/obj/machinery/vending/boozeomat/boozeomat = allocate(/obj/machinery/vending/boozeomat)
	var/list/stock = boozeomat.premium | boozeomat.contraband | boozeomat.products
	for(var/list/category as anything in boozeomat.product_categories)
		stock |= category["products"]
	TEST_ASSERT(stock[/obj/item/reagent_containers/food/drinks/bottle/trappist], "Траппист продаётся в Booze-O-Mat")
	for(var/path in stock)
		if(!ispath(path, /obj/item/reagent_containers))
			continue
		var/obj/item/reagent_containers/bottle = allocate(path)
		var/list/contents = bottle.reagents ? bottle.reagents.reagent_list : list()
		for(var/datum/reagent/reagent as anything in contents)
			TEST_ASSERT(!econ_is_mixed_drink(reagent.type), "[reagent.type] из [path] считается коктейлем")
	TEST_ASSERT(!econ_is_mixed_drink(/datum/reagent/consumable/ethanol/trappist), "Траппист не коктейль")
	TEST_ASSERT(econ_is_mixed_drink(/datum/reagent/consumable/ethanol/screwdrivercocktail), "Отвёртка - коктейль")

/// Вне станции коктейль не платит и остаётся неоплаченным.
/datum/unit_test/economy_work/service/drink_offstation/Run()
	setup_service()
	var/obj/item/reagent_containers/food/drinks/drinkingglass/glass = glass_of(/datum/reagent/consumable/ethanol/screwdrivercocktail)
	patient.forceMove(run_loc_floor_top_right)
	var/before = budget.account_balance
	glass.attack(patient, patient)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Вне станции")
	TEST_ASSERT_NOTNULL(glass.econ_pourer, "Наливший не сброшен")

/// Первый урожай вида на станции платит, повторный - нет; урожай вне станции или без выплаты вид не помечает.
/datum/unit_test/economy_work/service/harvest/Run()
	setup_service()
	var/before = budget.account_balance
	harvest_tray(/obj/item/seeds/tomato, station_turf)
	harvest_tray(/obj/item/seeds/tomato, station_turf)
	TEST_ASSERT_EQUAL(budget.account_balance - before, SSeconomy.settings.work_prices[WORK_SRV_NEW_PLANT], "Только первый урожай вида")
	performer.forceMove(run_loc_floor_bottom_left)
	before = budget.account_balance
	harvest_tray(/obj/item/seeds/potato, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Вне станции")
	TEST_ASSERT(!service.plants_seen[/obj/item/seeds/potato], "Вид вне станции не помечен")
	performer.forceMove(station_turf)
	var/saved_price = SSeconomy.settings.work_prices[WORK_SRV_NEW_PLANT]
	SSeconomy.settings.work_prices[WORK_SRV_NEW_PLANT] = 0
	harvest_tray(/obj/item/seeds/potato, station_turf)
	SSeconomy.settings.work_prices[WORK_SRV_NEW_PLANT] = saved_price
	TEST_ASSERT(!service.plants_seen[/obj/item/seeds/potato], "Неоплаченный урожай вид не помечает")

/// Мытьё грязи шваброй на станции платит, вне станции нет, у каждого уборщика свой потолок за тик.
/datum/unit_test/economy_work/service/cleaning/Run()
	setup_service()
	var/obj/item/mop/mop = allocate(/obj/item/mop, station_turf)
	mop.reagents.add_reagent(/datum/reagent/space_cleaner, 30)
	allocate(/obj/effect/decal/cleanable/dirt, station_turf)
	var/before = budget.account_balance
	mop.afterattack(station_turf, performer, TRUE)
	TEST_ASSERT_EQUAL(budget.account_balance - before, SSeconomy.settings.work_prices[WORK_SRV_CLEANING], "Уборка на станции")
	performer.forceMove(run_loc_floor_bottom_left)
	allocate(/obj/effect/decal/cleanable/dirt, run_loc_floor_bottom_left)
	before = budget.account_balance
	mop.afterattack(run_loc_floor_bottom_left, performer, TRUE)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Вне станции")
	performer.forceMove(station_turf)
	var/mob/living/carbon/human/second_cleaner = new_guest()
	service.cleaned_this_tick.Cut()
	for(var/i in 1 to SSeconomy.settings.cleaning_cap_per_tick + 10)
		service.note_cleaning(performer)
		service.note_cleaning(second_cleaner)
	TEST_ASSERT_EQUAL(budget.account_balance - before, 2 * SSeconomy.settings.cleaning_cap_per_tick * SSeconomy.settings.work_prices[WORK_SRV_CLEANING], "Каждый уборщик упирается в свой потолок")
	service.on_economy_tick()
	before = budget.account_balance
	service.note_cleaning(performer)
	TEST_ASSERT_EQUAL(budget.account_balance - before, SSeconomy.settings.work_prices[WORK_SRV_CLEANING], "Тик экономики сбрасывает потолок")

/// Микроволновка, шейкер, лоток, швабра и мыло на станции называют оплату сервиса, вне станции - нет.
/datum/unit_test/economy_work/service/examine/Run()
	setup_service()
	var/list/prices = SSeconomy.settings.work_prices
	var/list/expected = list(
		/obj/machinery/microwave = "[prices[WORK_SRV_DISH]] кр.",
		/obj/item/reagent_containers/food/drinks/shaker = "[prices[WORK_SRV_DRINK]] кр.",
		/obj/machinery/hydroponics/constructable = "[prices[WORK_SRV_NEW_PLANT]] кр.",
		/obj/item/mop = "[prices[WORK_SRV_CLEANING]] кр.",
		/obj/item/soap = "[prices[WORK_SRV_CLEANING]] кр.",
	)
	for(var/thing_type in expected)
		var/atom/on_station = allocate(thing_type, station_turf)
		var/atom/off_station = allocate(thing_type, run_loc_floor_top_right)
		TEST_ASSERT(findtext(jointext(on_station.examine(performer), "\n"), "сервис"), "[thing_type] на станции говорит про сервис")
		TEST_ASSERT(findtext(jointext(on_station.examine(performer), "\n"), expected[thing_type]), "[thing_type] называет цену")
		TEST_ASSERT(!findtext(jointext(off_station.examine(patient), "\n"), "сервис"), "[thing_type] вне станции молчит")

/// Нулевые потолок сложности и множитель блюда дня в economy.json отвергаются, нулевой потолок уборки принимается.
/datum/unit_test/economy_service_settings/Run()
	var/path = "data/unit_test_economy_service.json"
	fdel(path)
	text2file("{\"settings\": {\"dish_complexity_max\": 0, \"dish_of_the_day_mult\": 0, \"cleaning_cap_per_tick\": 0}}", path)
	var/datum/economy_settings/settings = new
	var/list/errors = settings.load(path)
	fdel(path)
	TEST_ASSERT_EQUAL(length(errors), 2, "Ошибки: [jointext(errors, "; ")]")
	TEST_ASSERT_EQUAL(settings.dish_complexity_max, initial(settings.dish_complexity_max), "Нулевой потолок сложности принят")
	TEST_ASSERT_EQUAL(settings.dish_of_the_day_mult, initial(settings.dish_of_the_day_mult), "Нулевой множитель принят")
	TEST_ASSERT_EQUAL(settings.cleaning_cap_per_tick, 0, "Нулевой потолок уборки не применился")
