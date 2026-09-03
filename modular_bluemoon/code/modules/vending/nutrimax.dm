/obj/machinery/vending/hydronutrients
	name = "\improper NutriMax"
	desc = "A plant nutrients vendor."
	product_slogans = "Разве вы не рады, что вам не нужно удобрять естественным способом?;Теперь на 50% меньше вони!;Растения - это тоже люди!;Мы любим растения!;Не хотите ли и вы?;Самые зеленые пальцы на свете.;Мы любим большие растения.;Мягкая почва...;Вставай Шан Цунг... Ты должен вспахать поле в сто тысяч гектаров..."
	icon_state = "nutri"
	icon_deny = "nutri-deny"
	//panel_type = "panel2"
	light_mask = "nutri-light-mask"
	products = list(
		/obj/item/reagent_containers/glass/bottle/nutrient/ez = 30,
		/obj/item/reagent_containers/glass/bottle/nutrient/l4z = 20,
		/obj/item/reagent_containers/glass/bottle/nutrient/rh = 10,
		/obj/item/reagent_containers/spray/pestspray = 20,
		/obj/item/reagent_containers/syringe = 5,
		/obj/item/storage/bag/plants = 5,
		/obj/item/cultivator = 3,
		/obj/item/shovel/spade = 3,
		/obj/item/plant_analyzer = 4,
	)
	contraband = list(
		/obj/item/reagent_containers/glass/bottle/ammonia = 10,
		/obj/item/reagent_containers/glass/bottle/diethylamine = 5,
	)
	refill_canister = /obj/item/vending_refill/hydronutrients
	default_price = PRICE_REALLY_CHEAP
	extra_price = PRICE_CHEAP
	payment_department = ACCOUNT_SRV

/obj/item/vending_refill/hydronutrients
	machine_name = "NutriMax"
	icon_state = "refill_plant"
