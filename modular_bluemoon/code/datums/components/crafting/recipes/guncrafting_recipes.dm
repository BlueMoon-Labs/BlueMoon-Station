///datum/crafting_recipe/mk59
//	name = "MK59 Enforcer convertion"
//	result = /obj/item/gun/ballistic/automatic/mk59/nomag
//	reqs = list(/obj/item/gun/ballistic/automatic/pistol/enforcer = 1,
//				/obj/item/weaponcrafting/gunkit/mk59 = 1)
//	tools = list(TOOL_SCREWDRIVER)
//	time = 30
//	category = CAT_WEAPONRY
//	subcategory = CAT_WEAPON

/datum/crafting_recipe/mk60
	name = "MK60 Enforcer convertion"
	result = /obj/item/gun/ballistic/automatic/mk60/nomag
	reqs = list(/obj/item/gun/ballistic/automatic/pistol/enforcer = 1,
				/obj/item/weaponcrafting/gunkit/mk60 = 1)
	tools = list(TOOL_SCREWDRIVER)
	time = 30
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON

/datum/crafting_recipe/mk62
	name = "MK62 Enforcer convertion"
	result = /obj/item/gun/ballistic/automatic/mk60/mk62/nomag
	reqs = list(/obj/item/gun/ballistic/automatic/mk60 = 1,
				/obj/item/weaponcrafting/gunkit/mk62 = 1)
	tools = list(TOOL_SCREWDRIVER)
	time = 30
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON

/datum/crafting_recipe/vector
	name = "Vector SMG convertion"
	result = /obj/item/gun/ballistic/automatic/mk60/vector
	reqs = list(/obj/item/gun/ballistic/automatic/mk60/mk62 = 1,
				/obj/item/weaponcrafting/gunkit/vector = 1)
	tools = list(TOOL_SCREWDRIVER)
	time = 30
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON
