/obj/machinery/vending/snack
	name = "\improper Getmore Chocolate Corp"
	desc = "A snack machine courtesy of the Getmore Chocolate Corporation, based out of Mars."
	product_slogans = "Попробуйте нашу новую плитку нуги!;В два раза больше калорий за полцены!;Самая полезная!;Отмеченная наградами шоколадная плитка!;Ммм! Так вкусно!;Боже мой, как сочно!;Перекусите.;Перекусы полезны для вас!;Возьмите еще!!!;Самые качественные закуски прямо с Марса.;Мы любим шоколад!;Попробуйте наше новое вяленое мясо!"
	icon_state = "snack"
	//panel_type = "panel2"
	light_mask = "snack-light-mask"
	products = list(
		/obj/item/reagent_containers/food/snacks/candy = 5,
		/obj/item/reagent_containers/food/snacks/chocolatebar = 5,
		/obj/item/reagent_containers/food/drinks/dry_ramen = 5,
		/obj/item/reagent_containers/food/snacks/chips = 5,
		/obj/item/reagent_containers/food/snacks/sosjerky = 5,
		/obj/item/reagent_containers/food/snacks/no_raisin = 5,
		/obj/item/reagent_containers/food/snacks/spacetwinkie = 5,
		/obj/item/reagent_containers/food/snacks/cheesiehonkers = 5,
		/obj/item/reagent_containers/food/snacks/cornchips = 5,
		/obj/item/reagent_containers/food/snacks/energybar = 6,
		/obj/item/storage/fancy/jellybean_bowl = 5,
		/obj/item/reagent_containers/food/snacks/sfseeds = 5,
	)
	contraband = list(
		/obj/item/reagent_containers/food/snacks/cracker = 10,
		/obj/item/reagent_containers/food/snacks/honeybar = 5,
		/obj/item/reagent_containers/food/snacks/syndicake = 5,
		/obj/item/reagent_containers/food/snacks/intecookies = 5, // Bluemoon Changes
		/obj/item/reagent_containers/food/snacks/beans = 2,
	)
	premium = list(
		/obj/item/reagent_containers/food/snacks/lollipop = 2,
		/obj/item/reagent_containers/food/snacks/spiderlollipop = 2,
		/obj/item/storage/box/gum = 4,
		/obj/item/storage/box/gum/happiness = 4,
		/obj/item/storage/box/gum/nicotine = 4,
		/obj/item/storage/box/gum/bubblegum = 4,
		/obj/item/reagent_containers/food/snacks/gumball = 4,
		/obj/item/reagent_containers/food/snacks/chococoin = 2,
		/obj/item/storage/box/marshmallow = 2,
		/obj/item/storage/box/donkpockets = 2,
		/obj/item/reagent_containers/food/snacks/swirl_lollipop = 4,
	)
	refill_canister = /obj/item/vending_refill/snack
	req_access = list(ACCESS_KITCHEN)
	canload_access_list = list(ACCESS_KITCHEN)
	default_price = PRICE_REALLY_CHEAP
	extra_price = PRICE_ALMOST_CHEAP
	payment_department = ACCOUNT_SRV
	input_display_header = "Chef's Food Selection"

/obj/item/vending_refill/snack
	machine_name = "Getmore Chocolate Corp"

/obj/machinery/vending/snack/random
	name = "\improper Random Snackies"
	icon_state = "random_snack"
	desc = "Uh oh!"

/obj/machinery/vending/snack/random/Initialize(mapload)
	. = ..()
	var/obj/machinery/vending/snack/T = pick(subtypesof(/obj/machinery/vending/snack) - /obj/machinery/vending/snack/random)
	T = new T(loc)
	T.pixel_x = pixel_x
	T.pixel_y = pixel_y
	return INITIALIZE_HINT_QDEL

/obj/machinery/vending/snack/blue
	icon_state = "snackblue"

/obj/machinery/vending/snack/orange
	icon_state = "snackorange"

/obj/machinery/vending/snack/green
	icon_state = "snackgreen"

/obj/machinery/vending/snack/teal
	icon_state = "snackteal"
