// Крафт тату-машинки

/datum/crafting_recipe/tattoo_gun
	name = "Tattoo Gun"
	result = /obj/item/tattoo_gun
	time = 60
	reqs = list(
		/obj/item/stack/sheet/metal = 2,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/sheet/glass = 1,
		/obj/item/pen = 1
	)
	tools = list(TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	category = CAT_MISCELLANEOUS
	subcategory = CAT_TOOL
