//This one's from bay12
/obj/machinery/vending/cart
	name = "\improper PTech"
	desc = "Cartridges for PDAs."
	product_slogans = "Картриджи!!!"
	icon_state = "cart"
	icon_deny = "cart-deny"
	//panel_type = "panel6"
	products = list(
		/obj/item/modular_computer/pda = 10,
		// Normal staff cards
		/obj/item/cartridge/medical = 10,
		/obj/item/cartridge/engineering = 10,
		/obj/item/cartridge/security = 10,
		/obj/item/cartridge/janitor = 10,
		/obj/item/cartridge/signal/toxins = 10,
		/obj/item/cartridge/roboticist = 10,
		/obj/item/cartridge/atmos = 10,
		/obj/item/cartridge/detective = 10,
		/obj/item/cartridge/lawyer = 10,
		/obj/item/cartridge/curator = 10,
		// Virus disks
		/obj/item/cartridge/virus/clown = 3,
		/obj/item/cartridge/virus/mime = 3,
		// Command staff cards
		/obj/item/cartridge/captain = 3,
		/obj/item/cartridge/quartermaster = 10,
		/obj/item/cartridge/head = 10,
		/obj/item/cartridge/hos = 10,
		/obj/item/cartridge/ce = 10,
		/obj/item/cartridge/cmo = 10,
		/obj/item/cartridge/rd = 10,
	)
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 50)
	refill_canister = /obj/item/vending_refill/cart
	default_price = PRICE_ALMOST_EXPENSIVE
	extra_price = PRICE_ALMOST_ONE_GRAND
	resistance_flags = FIRE_PROOF
	default_price = PRICE_ALMOST_EXPENSIVE
	extra_price = PRICE_ALMOST_ONE_GRAND
	payment_department = ACCOUNT_SRV
	light_mask = "cart-light-mask"

/obj/item/vending_refill/cart
	machine_name = "PTech"
	icon_state = "refill_smoke"
