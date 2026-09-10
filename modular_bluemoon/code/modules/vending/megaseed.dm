/obj/machinery/vending/hydroseeds
	name = "\improper MegaSeed Servitor"
	desc = "When you need seeds fast!"
	product_slogans = "ЗДЕСЬ ЖИВУТ СЕМЕНА! GIT YOU SOME!;Лучший выбор семян на станции!;Также в наличии некоторые сорта грибов, больше для экспертов!; Получите сертификат сегодня!;Мы любим растения!;Выращивайте урожай!;Расти, детка, расти!;Ай да сынок!"
	icon_state = "seeds"
	//panel_type = "panel2"
	light_mask = "seeds-light-mask"
	product_categories = list(
		list(
			"name" = "Fruits",
			"icon" = "apple-whole",
			"products" = list (
				/obj/item/seeds/apple = 3,		//	 Apple
				/obj/item/seeds/banana = 3,		//	 Banana
				/obj/item/seeds/cherry = 3,		//	 Cherry
				/obj/item/seeds/berry = 3,		//	 Berry
				/obj/item/seeds/cocoapod = 3,  	//	 Cocoa Pod
				/obj/item/seeds/coconut = 3,	//	 Coconut
				/obj/item/seeds/grape = 3,		//	 Grape
				/obj/item/seeds/lemon = 3,		//	 Lemon
				/obj/item/seeds/lime = 3,		//	 Lime
				/obj/item/seeds/orange = 3,		//	 Orange
				/obj/item/seeds/peach = 3,		//	 Peach
				/obj/item/seeds/pineapple = 3,	//	 Pineapple
				/obj/item/seeds/strawberry = 3,	//	 Strawberry
				/obj/item/seeds/watermelon = 3,	//	 Watermelon
				/obj/item/seeds/melon = 3,		//	 Melon || BLUEMOON ADD
			),
		),

		list(
			"name" = "Vegetables",
			"icon" = "carrot",
			"products" = list(
				/obj/item/seeds/cabbage = 3,		//	 Cabbage
				/obj/item/seeds/carrot = 3,			//	 Carrot
				/obj/item/seeds/chili = 3,			//	 Chili
				/obj/item/seeds/corn = 3,			//	 Corn
				/obj/item/seeds/eggplant = 3,		//	 Eggplant
				/obj/item/seeds/garlic = 3,			//	 Garlic
				/obj/item/seeds/onion = 3,			//	 Onion
				/obj/item/seeds/peas = 3,			//	 Peas
				/obj/item/seeds/peanutseed = 3,  	//	 Peanut Seed
				/obj/item/seeds/potato = 3,			//	 Potato
				/obj/item/seeds/pumpkin = 3,		//	 Pumpkin
				/obj/item/seeds/soya = 3,  			//	 Soya
				/obj/item/seeds/tomato = 3,			//	 Tomato
				/obj/item/seeds/whitebeet = 3		//	 White Beet
			),
		),

		list(
			"name" = "Flowers",
			"icon" = "leaf",
			"products" = list(
				/obj/item/seeds/rose = 3,		//	 Rose
				/obj/item/seeds/poppy = 3,		//	 Poppy
				/obj/item/seeds/sunflower = 3,	//	 Sunflower
			),
		),

		list(
			"name" = "Miscellaneous",
			"icon" = "question",
			"products" = list(
				/obj/item/seeds/aloe = 3,			//	 Aloe
				/obj/item/seeds/ambrosia = 3,		//	 Ambrosia
				/obj/item/seeds/coffee = 3,  		//	 Coffee
				/obj/item/seeds/cotton = 3,  		//	 Cotton
				/obj/item/seeds/chanter = 3,		//	 Chanter
				/obj/item/seeds/grass = 3,  		//	 Grass
				/obj/item/seeds/replicapod = 3,  	//	 Replica Pod
				/obj/item/seeds/sugarcane = 3,  	//	 Sugarcane
				/obj/item/seeds/tea = 3,  			//	 Tea
				/obj/item/seeds/tobacco = 3,  		//	 Tobacco
				/obj/item/seeds/tower = 3,			//	 Tower
				/obj/item/seeds/wheat/rice = 3,		//	 Rice
				/obj/item/seeds/wheat = 3,  		//	 Wheat
				/obj/item/seeds/herbs = 3,  		//	 Herbs
			),
		),

	)
	contraband = list(
		/obj/item/seeds/amanita = 2,
		/obj/item/seeds/glowshroom = 2,
		/obj/item/seeds/liberty = 2,
		/obj/item/seeds/nettle = 2,
		/obj/item/seeds/plump = 2,
		/obj/item/seeds/reishi = 2,
		/obj/item/seeds/cannabis = 3,
		/obj/item/seeds/starthistle = 2,
		/obj/item/seeds/random = 2
	)

	premium = list(
		/obj/item/reagent_containers/spray/waterflower = 1,
	)

	refill_canister = /obj/item/vending_refill/hydroseeds
	default_price = PRICE_ALMOST_CHEAP
	extra_price = PRICE_NORMAL
	payment_department = ACCOUNT_SRV

/obj/item/vending_refill/hydroseeds
	machine_name = "MegaSeed Servitor"
	icon_state = "refill_plant"
