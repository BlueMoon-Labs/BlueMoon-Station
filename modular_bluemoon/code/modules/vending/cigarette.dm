/obj/machinery/vending/cigarette
	name = "\improper ShadyCigs Deluxe"
	desc = "If you want to get cancer, might as well do it in style."
	product_slogans = "Сигареты Космос имеют приятный вкус, как и положено сигарете.;Я лучше найду инструмент, чем брошу.;Курите!;Не верьте отчетам - курите сегодня!;Возможно, это не вредно для вас!;Не верьте ученым!;Это полезно для вас!;Не бросайте, покупайте больше!;Курите!;Никотиновый рай.;Лучшие сигареты с 2150 года.;Сигареты, удостоенные наград."
	icon_state = "cigs"
	//panel_type = "panel5"
	products = list(
		/obj/item/storage/fancy/cigarettes = 5,
		/obj/item/storage/fancy/cigarettes/cigpack_uplift = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_robust = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_carp = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_midori = 3,
		/obj/item/storage/box/matches = 10,
		/obj/item/lighter/greyscale = 4,
		/obj/item/storage/fancy/rollingpapers = 5,
		/obj/item/hookah = 3,
	)
	contraband = list(
		/obj/item/lighter = 3,
		/obj/item/clothing/mask/vape = 5,
		/obj/item/storage/fancy/cigarettes/cigpack_shadyjims = 1,
		/obj/item/clothing/mask/cigarette/dart = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_mindbreaker = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_cannabis = 3,
	)
	premium = list(
		/obj/item/storage/fancy/cigarettes/cigpack_robustgold = 3,
		/obj/item/storage/box/gum/nicotine = 2,
		/obj/item/lighter = 3,
		/obj/item/storage/fancy/cigarettes/cigars = 1,
		/obj/item/storage/fancy/cigarettes/cigars/havana = 1,
		/obj/item/storage/fancy/cigarettes/cigars/cohiba = 1,
	)

	refill_canister = /obj/item/vending_refill/cigarette
	default_price = PRICE_ALMOST_CHEAP
	extra_price = PRICE_ABOVE_NORMAL
	payment_department = ACCOUNT_SRV
	light_mask = "cigs-light-mask"

/obj/machinery/vending/cigarette/syndicate
	products = list(
		/obj/item/storage/fancy/cigarettes/cigpack_syndicate = 7,
		/obj/item/storage/fancy/cigarettes/cigpack_uplift = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_robust = 2,
		/obj/item/storage/fancy/cigarettes/cigpack_carp = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_midori = 1,
		/obj/item/storage/box/matches = 10,
		/obj/item/lighter/greyscale = 4,
		/obj/item/storage/fancy/rollingpapers = 5,
	)
	//initial_language_holder = /datum/language_holder/syndicate

/obj/machinery/vending/cigarette/syndicate/Initialize(mapload)
	. = ..()
	cost_multiplier_per_dept = list("[ACCESS_SYNDICATE]" = 0)

/obj/machinery/vending/cigarette/beach //Used in the lavaland_biodome_beach.dmm ruin
	name = "\improper ShadyCigs Ultra"
	desc = "Now with extra premium products!"
	product_slogans = "Возможно, это не вредно для тебя!;Наркотики помогут тебе пережить времена без денег лучше, чем деньги помогут тебе пережить времена без наркотиков!;Это полезно для тебя!;Включись, настройся, брось!;Лучше жить с помощью химии!;Курить!;Не забывай держать улыбку на губах и песню в сердце!"
	products = list(
		/obj/item/storage/fancy/cigarettes = 5,
		/obj/item/storage/fancy/cigarettes/cigpack_uplift = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_robust = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_carp = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_midori = 3,
		/obj/item/storage/fancy/cigarettes/cigpack_cannabis = 5,
		/obj/item/storage/box/matches = 10,
		/obj/item/lighter/greyscale = 4,
		/obj/item/storage/fancy/rollingpapers = 5,
	)
	premium = list(
		/obj/item/storage/fancy/cigarettes/cigpack_mindbreaker = 5,
		/obj/item/clothing/mask/vape = 5,
		/obj/item/lighter = 3,
	)
	//initial_language_holder = /datum/language_holder/beachbum

/obj/item/vending_refill/cigarette
	machine_name = "ShadyCigs Deluxe"
	icon_state = "refill_smoke"

/obj/machinery/vending/cigarette/pre_throw(obj/item/thrown_item)
	if(istype(thrown_item, /obj/item/lighter))
		var/obj/item/lighter/thrown_lighter = thrown_item
		thrown_lighter.set_lit(TRUE)
