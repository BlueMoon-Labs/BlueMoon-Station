#define WIZ_DROBE_DEFAULT_COUNT 5

/obj/machinery/vending/magivend
	name = "\improper MagiVend"
	desc = "A magic vending machine."
	icon_state = "MagiVend"
	//panel_type = "panel10"
	product_slogans = "Накладывайте заклинания правильным способом с помощью MagiVend!;Станьте своим собственным Гудини! Используйте MagiVend!;FJKLFJSD;AJKFLBJAKL;1234 LOONIES;LOL!;>MFW;KOS!!!;GET DAT FUKKEN DISK;HONK!;EI NATH;Destroy the station!;Admin conspiracies since forever!;Space-time bending hardware!"
	vend_reply = "Have an enchanted evening!"
	products = list(
		/obj/item/clothing/head/wizard = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/suit/wizrobe = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/head/wizard/red = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/suit/wizrobe/red = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/head/wizard/yellow = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/suit/wizrobe/yellow = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/head/wizard/black = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/suit/wizrobe/black = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/head/wizard/magus = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/suit/wizrobe/magusred = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/suit/wizrobe/magusblue = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/shoes/sandal/magic = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/head/wizard/marisa = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/suit/wizrobe/marisa = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/clothing/shoes/sandal/marisa = WIZ_DROBE_DEFAULT_COUNT,
		/obj/item/staff = WIZ_DROBE_DEFAULT_COUNT,
	)
	contraband = list(
		/obj/item/reagent_containers/glass/bottle/wizarditis = 1
	) //No one can get to the machine to hack it anyways; for the lulz - Microwave
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 50, MAGIC = 100)
	resistance_flags = FIRE_PROOF
	default_price = 0 //Just in case, since its primary use is storage.
	extra_price = PRICE_ABOVE_EXPENSIVE
	payment_department = ACCOUNT_SRV
	light_mask = "magivend-light-mask"

#undef WIZ_DROBE_DEFAULT_COUNT
