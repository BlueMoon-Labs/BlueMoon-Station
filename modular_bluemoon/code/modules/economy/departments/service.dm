/datum/economy_department/service
	id = ACCOUNT_SRV
	name = "Сервис"
	budget_name = "бюджет сервиса"
	head_access = list(ACCESS_HOP)
	/// Тип блюда дня, за него платят dish_of_the_day_mult
	var/dish_of_the_day
	var/next_dish_roll = 0
	/// Типы семян, урожай которых уже оплачен в этом раунде
	var/list/plants_seen = list()
	/// ckey уборщика -> оплаченных уборок за текущий тик экономики
	var/list/cleaned_this_tick = list()

/datum/economy_department/service/on_economy_tick()
	cleaned_this_tick.Cut()
	if(world.time >= next_dish_roll)
		roll_dish_of_the_day()

/datum/economy_department/service/proc/dish_candidates()
	. = list()
	for(var/datum/crafting_recipe/food/recipe as anything in subtypesof(/datum/crafting_recipe/food))
		var/result = initial(recipe.result)
		if(initial(recipe.always_availible) && ispath(result, /obj/item/reagent_containers/food/snacks))
			. |= result

/datum/economy_department/service/proc/roll_dish_of_the_day()
	next_dish_roll = world.time + ECON_DISH_OF_THE_DAY_PERIOD
	var/list/candidates = dish_candidates()
	if(!length(candidates))
		return
	dish_of_the_day = pick(candidates)
	var/obj/item/dish = dish_of_the_day
	SSmarket.post_news("Блюдо дня на станции - [initial(dish.name)]. До следующего объявления NT платит сервису за каждую его подачу [econ_times_text(SSeconomy.settings.dish_of_the_day_mult)] больше.")

/datum/economy_department/service/proc/note_harvest(obj/item/seeds/seed, mob/user)
	if(!seed || plants_seen[seed.type] || !econ_on_station(seed))
		return
	if(SSeconomy.record_work(id, WORK_SRV_NEW_PLANT, 1, user, memo = "Новый урожай: [seed.plantname]") > 0)
		plants_seen[seed.type] = TRUE

/datum/economy_department/service/proc/note_cleaning(mob/user)
	var/cleaner = econ_ckey_of(user)
	if(!cleaner || (cleaned_this_tick[cleaner] || 0) >= SSeconomy.settings.cleaning_cap_per_tick || !econ_on_station(user))
		return
	cleaned_this_tick[cleaner] += 1
	SSeconomy.record_work(id, WORK_SRV_CLEANING, 1, user)
