/obj/machinery/vending/tool
	name = "\improper YouTool"
	desc = "Tools for tools."
	icon_state = "tool"
	icon_deny = "tool-deny"
	//panel_type = "panel11"
	light_mask = "tool-light-mask"
	products = list(
		/obj/item/stack/cable_coil/random = 15,
		/obj/item/crowbar = 5,
		/obj/item/weldingtool = 3,
		/obj/item/wirecutters = 5,
		/obj/item/wrench = 5,
		/obj/item/analyzer = 5,
		/obj/item/t_scanner = 5,
		/obj/item/screwdriver = 5,
		/obj/item/flashlight/glowstick = 3,
		/obj/item/flashlight/glowstick/red = 3,
		/obj/item/flashlight = 5,
		/obj/item/clothing/ears/earmuffs = 1,
	)
	contraband = list(
		/obj/item/weldingtool/largetank = 4,
		/obj/item/clothing/gloves/color/fyellow = 4,
		/obj/item/multitool = 2,
	)
	premium = list(
		/obj/item/storage/belt/utility = 2,
		/obj/item/clothing/gloves/color/yellow = 2,
		/obj/item/weldingtool/hugetank = 2,
		/obj/item/clothing/gloves/color/yellow = 1,
		/obj/item/rcl = 3,
		/obj/item/airlock_painter = 3,
		/obj/item/pipe_painter = 3,
		/obj/item/airlock_painter/decal = 3,
		/obj/item/airlock_painter/decal/tile = 3,
	)
	refill_canister = /obj/item/vending_refill/youtool
	default_price = PRICE_REALLY_CHEAP
	extra_price = PRICE_EXPENSIVE
	payment_department = ACCOUNT_ENG

/obj/item/vending_refill/youtool
	machine_name = "YouTool"
	icon_state = "refill_engi"
