/datum/crafting_recipe/rebarxbow
	name = "Heated Rebar Crossbow"
	result = /obj/item/gun/ballistic/rebarxbow
	reqs = list(
		/obj/item/stack/rods = 6,
		/obj/item/stack/cable_coil = 12,
		/obj/item/inducer = 1,
	)
	blacklist = list(/obj/item/inducer/sci)
	tools = list(TOOL_WELDER)
	time = 50
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON

/datum/crafting_recipe/rebarxbowforced
	name = "Forced Rebar Crossbow"
	result = /obj/item/gun/ballistic/rebarxbow/forced
	reqs = list(/obj/item/gun/ballistic/rebarxbow = 1)
	blacklist = list(
		/obj/item/gun/ballistic/rebarxbow/forced,
		/obj/item/gun/ballistic/rebarxbow/syndie,
	)
	tools = list(TOOL_CROWBAR)
	time = 10
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON

/datum/crafting_recipe/rebar_sharpened
	name = "Sharpened iron rod"
	result = /obj/item/ammo_casing/rebar
	reqs = list(/obj/item/stack/rods = 1)
	time = 2
	category = CAT_WEAPONRY
	subcategory = CAT_AMMO

/datum/crafting_recipe/rebar_zaukerite
	name = "Zaukerite crossbow bolt"
	result = /obj/item/ammo_casing/rebar/zaukerite
	reqs = list(/obj/item/stack/sheet/mineral/zaukerite = 1)
	time = 2
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/rebar_hydrogen
	name = "Metallic hydrogen crossbow bolt"
	result = /obj/item/ammo_casing/rebar/hydrogen
	reqs = list(/obj/item/stack/sheet/mineral/metal_hydrogen = 1)
	time = 2
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/rebar_healium
	name = "Healium crystal crossbow bolt"
	result = /obj/item/ammo_casing/rebar/healium
	reqs = list(/obj/item/grenade/gas_crystal/healium_crystal = 1)
	time = 2
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/*
/datum/crafting_recipe/rebar_n2o
	name = "N2O crystal crossbow bolt"
	result = /obj/item/ammo_casing/rebar/n2o
	reqs = list(/obj/item/grenade/gas_crystal/nitrous_oxide_crystal = 1)
	time = 2
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS
*/

/datum/crafting_recipe/rebar_hypernoblium
	name = "Hypernoblium crystal crossbow bolt"
	result = /obj/item/ammo_casing/rebar/hypernoblium
	reqs = list(/obj/item/hypernoblium_crystal = 1)
	time = 2
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/rebar_nitrium
	name = "Nitrium crystal crossbow bolt"
	result = /obj/item/ammo_casing/rebar/nitrium
	reqs = list(/obj/item/nitrium_crystal = 1)
	time = 2
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/rebar_proto_nitrate
	name = "Proto nitrate crystal crossbow bolt"
	result = /obj/item/ammo_casing/rebar/proto_nitrate
	reqs = list(/obj/item/grenade/gas_crystal/proto_nitrate_crystal = 1)
	time = 2
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/rebar_paperball
	name = "Paper Ball"
	result = /obj/item/ammo_casing/rebar/paperball
	reqs = list(/obj/item/paper = 1)
	time = 1
	category = CAT_WEAPONRY
	subcategory = CAT_AMMO

/datum/crafting_recipe/rebar_syndie
	name = "Jagged iron rod"
	result = /obj/item/ammo_casing/rebar/syndie
	reqs = list(/obj/item/stack/rods = 1)
	tools = list(TOOL_WIRECUTTER)
	time = 1
	category = CAT_WEAPONRY
	subcategory = CAT_AMMO

/datum/crafting_recipe/rebar_supermatter
	name = "Supermatter crossbow bolt"
	result = /obj/item/ammo_casing/rebar/supermatter
	reqs = list(
		/obj/machinery/power/supermatter_crystal/shard = 1,
		/obj/item/stack/rods = 1,
	)
	tools = list(TOOL_WELDER)
	time = 30
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS
