/obj/machinery/vending/games
	name = "\improper Good Clean Fun"
	desc = "Vends things that the Captain and Head of Personnel are probably not going to appreciate you fiddling with instead of your job..."
	product_slogans = "Побег в мир фэнтези!;Утолите свою зависимость от азартных игр!;Разрушьте свои дружеские отношения!;Прокачайте инициативу!;Эльфы и гномы!;Параноидальные компьютеры!;Абсолютно не сатанинские игры!;Веселое время навсегда!"
	icon_state = "games"
//	panel_type = "panel4"
	product_categories = list(
		list(
			"name" = "Cards",
			"icon" = "diamond",
			"products" = list(
				/obj/item/toy/cards/deck = 5,
				/obj/item/toy/cards/deck/cas = 3,
				/obj/item/toy/cards/deck/cas/black = 3,
				/obj/item/toy/cards/deck/tarot = 3,
				/obj/item/toy/cards/deck/unum = 3,
				/obj/item/toy/cards/deck/tarot = 3,
				/obj/item/toy/cards/deck/love_cards/truths = 4,
				/obj/item/toy/cards/deck/love_cards/kinks = 4,
				/obj/item/toy/cards/deck/love_cards/actions = 4,
				/obj/item/toy/cards/deck/love_cards/blanks = 4,
			),
		),
		list(
			"name" = "Art",
			"icon" = "palette",
			"products" = list(
				/obj/item/storage/crayons = 2,
				/obj/item/chisel = 3,
				/obj/item/canvas = 5,
				/obj/item/canvas/nineteenXnineteen = 5,
				/obj/item/canvas/twentyfour_twentyfour = 5,
				/obj/item/canvas/twentythreeXnineteen = 5,
				/obj/item/canvas/twentythreeXtwentythree = 5,
				/obj/item/canvas/ultra_big = 5,
				/obj/item/canvas/thirtysix_twentyfour = 5,
				/obj/item/canvas/fortyfive_twentyseven = 5,
				/obj/item/wallframe/painting = 5,
				/obj/item/wallframe/painting/large = 5,
			),
		),
		list(
			"name" = "Other",
			"icon" = "star",
			"products" = list(
				/obj/item/camera = 3,
				/obj/item/camera_film = 5,
				/obj/item/toy/crayon/spraycan = 6,
				/obj/item/cardpack/series_one = 100,
				/obj/item/dyespray = 3,
				/obj/item/razor = 3,
				/obj/item/tcgcard_binder = 10,
				/obj/item/storage/dice = 10,
				/obj/item/storage/dice/d6 = 5,
				/obj/item/reagent_containers/food/drinks/drinkingglass/wooden = 5,
				/obj/item/toy/prizeball/therapy = 6,
				/obj/item/tvcamera = 3,
				/obj/item/toy/nyamagotchi = 10,
				/obj/item/gun/ballistic/revolver/russian/lewd = 5,
			),
		),
		list(
			"name" = "cosmetic",
			"icon" = "theater-masks",
			"products" = list(
				/obj/item/lipstick/white = 5,
				/obj/item/lipstick = 5,
				/obj/item/lipstick/purple = 5,
				/obj/item/lipstick/jade = 5,
				/obj/item/lipstick/black = 5,
				/obj/item/lipstick/yellow = 5,
				/obj/item/lipstick/blue = 5,
				/obj/item/lipstick/teal = 5,
				/obj/item/lipstick/fuchsia = 5,
				/obj/item/lipstick/navy = 5,
				/obj/item/lipstick/aqua = 5,
				/obj/item/lipstick/white = 5,
				/obj/item/nailpolish/red = 5,
				/obj/item/nailpolish/blue = 5,
				/obj/item/nailpolish/aqua = 5,
				/obj/item/nailpolish/black = 5,
				/obj/item/nailpolish/white = 5,
				/obj/item/nailpolish/navy = 5,
				/obj/item/nailpolish/yellow = 5,
				/obj/item/nailpolish/purple = 5,
			),
		)
	)
	contraband = list(
		/obj/item/dice/fudge = 9,
		/obj/item/cardpack/syndicate = 10,
		/obj/item/clothing/shoes/wheelys = 4,
		/obj/item/gun/ballistic/revolver/russian = 1,
	)
	premium = list(
		/obj/item/disk/holodisk = 5,
		/obj/item/melee/skateboard/pro = 3,
		/obj/item/melee/skateboard/hoverboard = 1,
		/obj/item/choice_beacon/box/plushie = 5,
	)
	refill_canister = /obj/item/vending_refill/games
	default_price = PRICE_CHEAP
	extra_price = PRICE_ALMOST_EXPENSIVE
	payment_department = ACCOUNT_SRV
	light_mask = "games-light-mask"

/obj/item/vending_refill/games
	machine_name = "\improper Good Clean Fun"
	icon_state = "refill_games"
