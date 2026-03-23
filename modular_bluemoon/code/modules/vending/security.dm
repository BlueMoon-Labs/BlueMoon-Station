/obj/machinery/vending/security
	name = "\improper SecTech"
	desc = "A security equipment vendor."
	product_slogans = "Разбейте коммунистические черепа!;Побейте несколько голов!;Не забывайте - вред есть благо!;Ваше оружие здесь.;Наручники!;Стоять, подонок!;Не бейте меня!;Бейте их, Большой Брат.;Почему бы не съесть пончик?"
	icon_state = "sec"
	icon_deny = "sec-deny"
	//panel_type = "panel6"
	light_mask = "sec-light-mask"
	req_access = list(ACCESS_SECURITY)
	products = list(
		/obj/item/restraints/handcuffs = 6,
		/obj/item/restraints/handcuffs/kinky = 6,
		/obj/item/restraints/handcuffs/cable/zipties = 6,
		/obj/item/grenade/flashbang = 4,
		/obj/item/assembly/flash/handheld = 5,
		/obj/item/reagent_containers/food/snacks/donut = 12,
		/obj/item/storage/box/evidence = 6,
		/obj/item/flashlight/seclite = 4,
		/obj/item/restraints/legcuffs/bola/energy = 12,
		/obj/item/evidencebag = 20,
		/obj/item/secbat = 5,
		/obj/item/fee_terminal = 10,
		/obj/item/ammo_box/magazine/e45/taser = 10,
		/obj/item/device/hailer = 10,
		/obj/item/clothing/suit/armor/vest/peacekeeper = 5,
		/obj/item/clothing/suit/armor/vest/metrocop = 2,
		/obj/item/clothing/head/helmet/metrocop = 2,
		/obj/item/storage/bag/security = 5,
		/obj/item/clothing/head/helmet/blueshirt = 5,
		/obj/item/clothing/head/helmet/hephaestus = 5,
		/obj/item/clothing/under/rank/security/officer/blueshirt = 5,
		/obj/item/clothing/suit/armor/vest/blueshirt = 5,
		/obj/item/armorkit/security = 5,
		/obj/item/armorkit/security/helmet = 5,
		/obj/item/storage/box/forensic_cards = 1,
	)
	contraband = list(
		/obj/item/clothing/glasses/sunglasses = 2,
		/obj/item/storage/fancy/donut_box = 2,
		/obj/item/storage/belt/sabre/secbelt = 1,
		/obj/item/storage/belt/slut = 5,
		/obj/item/bdsm_whip/ridingcrop = 3,
		/obj/item/electropack/shockcollar/security = 5,
		/obj/item/clothing/suit/armor/vest/stripper = 5,
		/obj/item/clothing/suit/armor/vest/stripper/bikini = 5,
		/obj/item/clothing/neck/petcollar/locked/security = 5,
		/obj/item/grenade/secbed = 3,
		/obj/item/dildo/flared/gigantic = 3,
	)
	premium = list(
		/obj/item/coin/antagtoken = 1,
		/obj/item/clothing/gloves/tackler = 4,
		/obj/item/grenade/stingbang = 4,
		/obj/item/ssword_kit = 1,
		/obj/item/storage/belt/bandolier = 2,
		/obj/item/storage/belt/military = 2,
		/obj/item/storage/belt/military/assault/hecu = 1,
		/obj/item/storage/belt/military/assault/hecu/black = 1,
		/obj/item/storage/backpack/hipbag = 1,
		/obj/item/storage/backpack/hipbag/tan = 1,
		/obj/item/storage/backpack/hipbag/green = 1,
		/obj/item/storage/bag/ammo = 3,
		/obj/item/stamp/security = 3,
		/obj/item/storage/belt/security/webbing/ds = 6,
	)
	refill_canister = /obj/item/vending_refill/security
	default_price = PRICE_ALMOST_EXPENSIVE
	extra_price = PRICE_REALLY_EXPENSIVE
	payment_department = ACCOUNT_SEC

/obj/machinery/vending/security/pre_throw(obj/item/thrown_item)
	if(isgrenade(thrown_item))
		var/obj/item/grenade/thrown_grenade = thrown_item
		thrown_grenade.preprime()
	else if(istype(thrown_item, /obj/item/flashlight))
		var/obj/item/flashlight/thrown_flashlight = thrown_item
		thrown_flashlight.on = TRUE
		thrown_flashlight.update_brightness()

/obj/item/vending_refill/security
	machine_name = "SecTech"
	icon_state = "refill_sec"
