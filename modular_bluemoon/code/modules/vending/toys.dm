/obj/machinery/vending/donksofttoyvendor
	name = "\improper Donksoft Toy Vendor"
	desc = "Ages 8 and up approved vendor that dispenses toys."
	icon_state = "syndi"
	//panel_type = "panel18"
	product_slogans = "Получите свои крутые игрушки сегодня!;Запустите действующего охотника сегодня!;Качественное игрушечное оружие по дешевым ценам!;Отдайте это ГП, чтобы получить бесплатный доступ!;Отдайте это ГСБ, чтобы получить путёвку в Пермабриг!;Почувствуйте себя сильным со своими игрушками!;Выразите своего внутреннего ребенка сегодня!;Игрушечное оружие не убивает людей, но действующие охотники убивают!;Кому нужна ответственность, когда у вас есть игрушечное оружие?;Сделайте свое следующее убийство веселым!!"
	vend_reply = "Возвращайся!!"
	light_mask = "donksoft-light-mask"
	circuit = /obj/item/circuitboard/machine/vending/donksofttoyvendor
	products = list(
		/obj/item/gun/ballistic/automatic/toy/unrestricted = 10,
		/obj/item/gun/ballistic/automatic/toy/pistol/unrestricted = 10,
		/obj/item/gun/ballistic/shotgun/toy/unrestricted = 10,
		/obj/item/toy/sword = 10,
		/obj/item/ammo_box/foambox = 20,
		/obj/item/toy/foamblade = 10,
		/obj/item/toy/syndicateballoon = 10,
		/obj/item/toy/balloon = 10,
		/obj/item/toy/balloon/long = 10,
		/obj/item/toy/waterballoon = 10,
		/obj/item/toy/balloon/corgi = 5,
		/obj/item/toy/balloon/heart = 5,
		/obj/item/toy/balloon/arrest = 5,
		/obj/item/clothing/suit/syndicatefake = 5,
		/obj/item/clothing/head/syndicatefake = 5,
	)
	contraband = list(
		/obj/item/gun/ballistic/shotgun/toy/crossbow = 10,
		/obj/item/gun/ballistic/automatic/c20r/toy/unrestricted = 10,
		/obj/item/gun/ballistic/automatic/l6_saw/toy/unrestricted = 10,
		/obj/item/toy/katana = 10,
		/obj/item/dualsaber/toy = 5,
		/obj/item/toy/balloon_animal/guy = 3,
		/obj/item/toy/balloon_animal/clown = 3,
		/obj/item/toy/balloon_animal/cat = 3,
		/obj/item/toy/balloon_animal/dog = 3,
		/obj/item/toy/balloon_animal/slime = 3,
		/obj/item/toy/balloon_animal/xeno = 3,
	)
	premium = list(
		/obj/item/dualsaber/toy = 4,
		/obj/item/storage/box/fakesyndiesuit = 4,
		/obj/item/gun/ballistic/automatic/c20r/toy/unrestricted = 4,
		/obj/item/gun/ballistic/automatic/l6_saw/toy/unrestricted = 4,
	)
	refill_canister = /obj/item/vending_refill/donksoft
	default_price = PRICE_ABOVE_NORMAL
	extra_price = PRICE_EXPENSIVE
	payment_department = ACCOUNT_SRV

/obj/item/vending_refill/donksoft
	machine_name = "Donksoft Toy Vendor"
	icon_state = "refill_donksoft"
