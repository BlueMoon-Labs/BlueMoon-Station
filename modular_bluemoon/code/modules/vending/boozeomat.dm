/obj/machinery/vending/boozeomat
	name = "\improper Booze-O-Mat"
	desc = "A technological marvel, supposedly able to mix just the mixture you'd like to drink the moment you ask for one."
	icon_state = "boozeomat"
	icon_deny = "boozeomat-deny"
	//panel_type = "panel22"

	product_categories = list(
		list(
			"name" = "Alcoholic",
			"icon" = "wine-bottle",
			"products" = list(
				/obj/item/reagent_containers/food/drinks/bottle/gin = 5,
				/obj/item/reagent_containers/food/drinks/bottle/whiskey = 5,
				/obj/item/reagent_containers/food/drinks/bottle/tequila = 5,
				/obj/item/reagent_containers/food/drinks/bottle/vodka = 5,
				/obj/item/reagent_containers/food/drinks/bottle/vermouth = 5,
				/obj/item/reagent_containers/food/drinks/bottle/rum = 5,
				/obj/item/reagent_containers/food/drinks/bottle/wine = 5,
				/obj/item/reagent_containers/food/drinks/bottle/cognac = 5,
				/obj/item/reagent_containers/food/drinks/bottle/kahlua = 5,
				/obj/item/reagent_containers/food/drinks/bottle/hcider = 5,
				/obj/item/reagent_containers/food/drinks/bottle/absinthe = 5,
				/obj/item/reagent_containers/food/drinks/bottle/grappa = 5,
				/obj/item/reagent_containers/food/drinks/bottle/sake = 5,
				/obj/item/reagent_containers/food/drinks/bottle/amaretto = 5,
				/obj/item/reagent_containers/food/drinks/bottle/curacao = 3,
				/obj/item/reagent_containers/food/drinks/bottle/navy_rum = 3,
				/obj/item/reagent_containers/food/drinks/ale = 6,
				/obj/item/reagent_containers/food/drinks/beer = 6,
				/obj/item/reagent_containers/food/drinks/bottle/navy_rum = 3,
				/obj/item/reagent_containers/food/drinks/bottle/bloodwine = 3,
				/obj/item/reagent_containers/food/drinks/bottle/femcum_whiskey = 4,
				/obj/item/reagent_containers/food/drinks/bottle/cum_rum = 4,
			),
		),

		list(
			"name" = "Non-Alcoholic",
			"icon" = "bottle-water",
			"products" = list(
				/obj/item/reagent_containers/food/drinks/bottle/orangejuice = 4,
				/obj/item/reagent_containers/food/drinks/bottle/tomatojuice = 4,
				/obj/item/reagent_containers/food/drinks/bottle/limejuice = 4,
				/obj/item/reagent_containers/food/drinks/bottle/grenadine = 4,
				/obj/item/reagent_containers/food/drinks/bottle/menthol = 4,
				/obj/item/reagent_containers/food/drinks/bottle/cream = 4,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/banana = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/caramel = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/chili = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/crocin = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/semen = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/grape = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/cactus = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/mint = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/orange = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/saltcaramel = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/vanilla = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/syrup_bottle/watermelon = 5,
				/obj/item/reagent_containers/food/drinks/soda_cans/tonic = 8,
				/obj/item/reagent_containers/food/drinks/soda_cans/cola = 8,
				/obj/item/reagent_containers/food/drinks/soda_cans/synthdrink = 15,
				/obj/item/reagent_containers/food/drinks/soda_cans/sodawater = 15,
				/obj/item/reagent_containers/food/drinks/soda_cans/sol_dry = 8,
				/obj/item/reagent_containers/food/drinks/bottle/blank/vampire_bottle = 10,
				/obj/item/reagent_containers/food/drinks/kvass = 5, // BLUEMOON ADDED - kvass
				/obj/item/reagent_containers/food/drinks/ice = 10,
			),
		),

		list(
			"name" = "Glassware",
			"icon" = "wine-glass",
			"products" = list(
				/obj/item/reagent_containers/food/drinks/drinkingglass = 30,
				/obj/item/reagent_containers/food/drinks/drinkingglass/shotglass = 12,
				/obj/item/reagent_containers/food/drinks/flask = 3,
				/obj/item/reagent_containers/food/drinks/bottle/blank = 5,
				/obj/item/reagent_containers/food/drinks/bottle/blank/small = 10,
				/obj/item/reagent_containers/food/drinks/bottle/blank/pitcher = 2,
				/obj/item/reagent_containers/food/drinks/shaker = 2,
				/obj/item/reagent_containers/food/snacks/customizable/pet_bowl = 5,
			),
		),
	)

	contraband = list(
		/obj/item/reagent_containers/food/drinks/mug/tea = 12,
		/obj/item/reagent_containers/food/drinks/bottle/fernet = 5,
	)
	premium = list(
		/obj/item/reagent_containers/glass/bottle/ethanol = 4,
		/obj/item/reagent_containers/food/drinks/bottle/champagne = 5,
		/obj/item/reagent_containers/food/drinks/bottle/trappist = 5,
		/obj/item/reagent_containers/food/drinks/bottle/bitters = 5,
	)

	product_slogans = "Надеюсь, никто не попросит у меня чертову чашку чая...;Алкоголь - друг человечества. Вы не откажетесь от друга?;С удовольствием обслужим вас!;Никто не хочет пить на этой станции?;Пейте!;Выпивка полезна для вас!;Алкоголь - лучший друг человечества.;С удовольствием обслужим вас!;Не хотите ли хорошего, холодного пива? ;Ничто так не лечит, как выпивка!;Сделайте глоток!;Выпейте глоток!;Выпейте пива!;Пиво полезно для вас!;Только лучший алкоголь!;Самый качественный алкоголь с 2053 года!;Лучшее вино у нас!;Максимум алкоголя!;Человек любит пиво.;Тост за прогресс!"
	refill_canister = /obj/item/vending_refill/boozeomat
	default_price = PRICE_ALMOST_CHEAP
	extra_price = PRICE_EXPENSIVE
	payment_department = ACCOUNT_SRV
	light_mask = "boozeomat-light-mask"

/obj/machinery/vending/boozeomat/pubby_maint //abandoned bar on Pubbystation
	product_categories = list(
		list(
			"name" = "General",
			"icon" = "wine-bottle",
			"products" = list(
				/obj/item/reagent_containers/food/drinks/bottle/whiskey = 1,
				/obj/item/reagent_containers/food/drinks/bottle/absinthe = 1,
				/obj/item/reagent_containers/food/drinks/bottle/limejuice = 1,
				/obj/item/reagent_containers/food/drinks/bottle/cream = 1,
				/obj/item/reagent_containers/food/drinks/soda_cans/tonic = 1,
				/obj/item/reagent_containers/food/drinks/drinkingglass = 10,
				/obj/item/reagent_containers/food/drinks/ice = 3,
				/obj/item/reagent_containers/food/drinks/drinkingglass/shotglass = 6,
				/obj/item/reagent_containers/food/drinks/flask = 1
			),
		))

/obj/machinery/vending/boozeomat/pubby_captain //Captain's quarters on Pubbystation
	product_categories = list(
		list(
			"name" = "General",
			"icon" = "wine-bottle",
			"products" = list(
				/obj/item/reagent_containers/food/drinks/bottle/rum = 1,
				/obj/item/reagent_containers/food/drinks/bottle/wine = 1,
				/obj/item/reagent_containers/food/drinks/ale = 1,
				/obj/item/reagent_containers/food/drinks/drinkingglass = 6,
				/obj/item/reagent_containers/food/drinks/ice = 1,
				/obj/item/reagent_containers/food/drinks/drinkingglass/shotglass = 4
			),
		))
	payment_department = ACCOUNT_SEC

/obj/machinery/vending/boozeomat/all_access
	desc = "A technological marvel, supposedly able to mix just the mixture you'd like to drink the moment you ask for one. This model appears to have no access restrictions."
	req_access = null
/obj/machinery/vending/boozeomat/syndicate_access
	req_access = list(ACCESS_SYNDICATE)
	age_restrictions = FALSE
	payment_department = NO_FREEBIES

/obj/machinery/vending/boozeomat/syndicate_access/Initialize(mapload)
	. = ..()
	cost_multiplier_per_dept = list("[ACCESS_SYNDICATE]" = 0)

/obj/item/vending_refill/boozeomat
	machine_name = "Booze-O-Mat"
	icon_state = "refill_booze"
