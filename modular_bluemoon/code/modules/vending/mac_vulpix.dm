/obj/machinery/vending/snack/max_vulpix
	name = "\improper MacVulpix Deluxe Food"
	desc = "Торговый автомат сети ресторанов быстрого питания МакВульпикс с забавным лисом на логотипе."
	icon = 'modular_bluemoon/icons/obj/vending.dmi'
	icon_state = "mac_vulpix"
	icon_deny = "mac_vulpix-deny"
	light_mask = "mac_vulpix-light-mask"
	product_slogans = "Не любите вульп? Вы просто не умеете их готовить!;Если вам понравились вульпиксы - ингредиенты погибли не зря!;МакВульпикс - выбор настоящего гурмана, одобрено девятью из десяти диетологами!;МакВульпикс! То что я люблю!;Если чревоугодие — это грех, то добро пожаловать в ад!"
	products = list(
		/obj/item/small_delivery/donk_vulpix = 5,
		/obj/item/small_delivery/donk_vulpix/cheese = 5,
		/obj/item/reagent_containers/food/snacks/chips/macnachos = 5,
		/obj/item/storage/fancy/macvulpburger = 5,
		/obj/item/reagent_containers/food/drinks/bottle/macvulp = 5,
		/obj/item/reagent_containers/food/drinks/bottle/macvulp/choco = 5,
		/obj/item/reagent_containers/food/drinks/bottle/macvulp/banana = 5,
		/obj/item/reagent_containers/food/drinks/beer/macvulp = 5,
		/obj/item/reagent_containers/food/drinks/drinkingglass = 30
	)
	contraband = list(
		/obj/item/poster/mac_vulpix = 10,
		/obj/item/toy/plush/bm/vulpix = 3
	)
	premium = list(
		/obj/item/pizzabox/macvulpizza = 5
	)
	refill_canister = /obj/item/vending_refill/max_vulpix
	req_access = list(ACCESS_KITCHEN)
	canload_access_list = list(ACCESS_KITCHEN)
	default_price = PRICE_ABOVE_NORMAL
	extra_price = PRICE_ALMOST_EXPENSIVE
	payment_department = ACCOUNT_SRV
	input_display_header = "Chef's Food Selection"

/obj/item/vending_refill/max_vulpix
	machine_name = "MacVulpix Deluxe Food"
	icon_state = "refill_snack"
