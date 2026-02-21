/obj/machinery/vending/barkbox
	name = "Bark Box"
	desc = "For all your pet needs!"
	icon_state = "barkbox"
	product_slogans = "Вуф!;Гаф!;Раф-раф!!;Хочу лакомство!!!"
	products = list(
		/obj/item/storage/fancy/treat_box = 8,
		/obj/item/clothing/neck/petcollar = 5,
		/obj/item/clothing/neck/petcollar/ribbon = 5,
		/obj/item/clothing/neck/petcollar/leather = 5,
		/obj/item/clothing/suit/petharness = 4,
		/obj/item/clothing/suit/petharness/mesh = 4,
		/obj/item/toy/fluff/tennis_poly = 4,
		/obj/item/toy/fluff/tennis_poly/tri = 2,
		/obj/item/toy/fluff/bone_poly = 4,
		/obj/item/toy/fluff/frisbee_poly = 4,
		/obj/item/leash = 4,
		/obj/item/clothing/neck/petcollar/spike = 5,
		/obj/item/clothing/neck/petcollar/holo = 5,
		/obj/item/clothing/neck/petcollar/casino = 5,
		/obj/item/clothing/neck/petcollar/handmade = 5,
		/obj/item/reagent_containers/food/snacks/customizable/pet_bowl = 5,
	)
	contraband = list(
		/obj/item/clothing/neck/petcollar/locked = 2,
		/obj/item/clothing/neck/petcollar/locked/ribbon = 2,
		/obj/item/clothing/neck/petcollar/locked/leather = 2,
		/obj/item/clothing/neck/petcollar/locked/spike = 2,
		/obj/item/clothing/neck/petcollar/locked/holo = 2,
		/obj/item/clothing/neck/petcollar/locked/casino = 2,
		/obj/item/key/collar = 2,
		/obj/item/dildo/knotted = 3,
	)
	premium = list(
		/obj/item/bikehorn/rubberducky = 6,
		/obj/item/toy/fluff/tennis_poly/tri/squeak/rainbow = 1,
		/obj/item/toy/fluff/tennis_poly/tri/squeak = 1,
		/obj/item/toy/fluff/bone_poly/squeak = 1,
	)
	refill_canister = /obj/item/vending_refill/barkbox
	default_price = PRICE_NORMAL
	extra_price = PRICE_ALMOST_ONE_GRAND
	payment_department = NO_FREEBIES

/obj/item/vending_refill/barkbox
	machine_name 	= "Bark Box"
	icon_state 		= "refill_barkbox"
