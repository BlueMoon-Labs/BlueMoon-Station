/obj/machinery/vending/toyliberationstation
	name = "\improper Syndicate Donksoft Toy Vendor"
	desc = "An ages 8 and up approved vendor that dispenses toys. If you were to find the right wires, you can unlock the adult mode setting!"
	icon_state = "syndi"
	//panel_type = "panel18"
	product_slogans = "Получите свои крутые игрушки сегодня!;Запустите действующего охотника сегодня!;Качественное игрушечное оружие по дешевым ценам!;Отдайте это ГП, чтобы получить бесплатный доступ!;Отдайте это ГСБ, чтобы получить бесплатную путёвку в Пермабриг!;Почувствуйте себя сильным со своими игрушками!;Выразите своего внутреннего ребенка сегодня!;Игрушечное оружие не убивает людей, но действующие охотники убивают!;Кому нужна ответственность, когда у вас есть игрушечное оружие?;Сделайте свое следующее убийство веселым."
	vend_reply = "Come back for more!"
	circuit = /obj/item/circuitboard/machine/vending/syndicatedonksofttoyvendor
	products = list(
		/obj/item/gun/ballistic/automatic/toy/unrestricted = 10,
		/obj/item/gun/ballistic/automatic/toy/pistol/unrestricted = 10,
		/obj/item/gun/ballistic/shotgun/toy/unrestricted = 10,
		/obj/item/card/emagfake = 4,
		/obj/item/hot_potato/harmless/toy = 4,
		/obj/item/toy/sword = 12,
		/obj/item/dualsaber/toy = 12,
		/obj/item/toy/foamblade = 12,
		/obj/item/ammo_box/foambox = 20,
		/obj/item/toy/syndicateballoon = 10,
		/obj/item/clothing/suit/syndicatefake = 5,
		/obj/item/clothing/head/syndicatefake = 5
	)
	contraband = list(
		/obj/item/gun/ballistic/shotgun/toy/crossbow = 10,   //Congrats, you unlocked the +18 setting!
		/obj/item/gun/ballistic/automatic/c20r/toy/unrestricted/riot = 10,
		/obj/item/gun/ballistic/automatic/l6_saw/toy/unrestricted/riot = 10,
		/obj/item/ammo_box/foambox/riot = 20,
		/obj/item/toy/katana = 10,
		/obj/item/dualsaber/toy = 5,
		/obj/item/toy/cards/deck/syndicate = 10
	)
	armor_type = /datum/armor/vending_durable

	resistance_flags = FIRE_PROOF
	refill_canister = /obj/item/vending_refill/donksoft
	default_price = PRICE_ABOVE_NORMAL
	extra_price = PRICE_EXPENSIVE
	payment_department = ACCOUNT_SRV
	light_mask = "donksoft-light-mask"
