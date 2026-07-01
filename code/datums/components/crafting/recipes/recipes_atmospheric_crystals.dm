// Крафты из продуктов кристаллайзера и атмос-оборудования (вкладка Atmospherics)

/datum/crafting_recipe/zaukerite_shard_break
	name = "Zaukerite shard (raw)"
	result = /obj/item/shard/zaukerite
	reqs = list(
		/obj/item/stack/sheet/mineral/zaukerite = 1,
	)
	time = 15
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/zaukerite_shard_weapon
	name = "Zaukerite shard"
	result = /obj/item/zaukerite_shard
	reqs = list(
		/obj/item/shard/zaukerite = 1,
		/obj/item/stack/sheet/cloth = 1,
	)
	time = 25
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/*
/datum/crafting_recipe/n2o_shard_break
	name = "N2O shard (raw)"
	result = /obj/item/shard/n2o
	reqs = list(
		/obj/item/grenade/gas_crystal/nitrous_oxide_crystal = 1,
	)
	time = 15
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/n2o_shard_weapon
	name = "N2O shard"
	result = /obj/item/n2o_shard
	reqs = list(
		/obj/item/shard/n2o = 1,
		/obj/item/stack/sheet/cloth = 1,
	)
	time = 25
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS
*/

/datum/crafting_recipe/healium_shard_break
	name = "Healium shard (raw)"
	result = /obj/item/shard/healium
	reqs = list(
		/obj/item/grenade/gas_crystal/healium_crystal = 1,
	)
	time = 15
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/healium_shard_weapon
	name = "Healium shard"
	result = /obj/item/healium_shard
	reqs = list(
		/obj/item/shard/healium = 1,
		/obj/item/stack/sheet/cloth = 1,
	)
	time = 25
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/hypernoblium_shard_break
	name = "Hypernoblium shard (raw)"
	result = /obj/item/shard/hypernoblium
	reqs = list(
		/obj/item/hypernoblium_crystal = 1,
	)
	time = 15
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/hypernoblium_shard_weapon
	name = "Hypernoblium shard"
	result = /obj/item/hypernoblium_shard
	reqs = list(
		/obj/item/shard/hypernoblium = 1,
		/obj/item/stack/sheet/cloth = 1,
	)
	time = 25
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/nitrium_shard_break
	name = "Nitrium shard (raw)"
	result = /obj/item/shard/nitrium
	reqs = list(
		/obj/item/nitrium_crystal = 1,
	)
	time = 15
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/nitrium_shard_weapon
	name = "Nitrium shard"
	result = /obj/item/nitrium_shard
	reqs = list(
		/obj/item/shard/nitrium = 1,
		/obj/item/stack/sheet/cloth = 1,
	)
	time = 25
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/proto_nitrate_shard_break
	name = "Proto nitrate shard (raw)"
	result = /obj/item/shard/proto_nitrate
	reqs = list(
		/obj/item/grenade/gas_crystal/proto_nitrate_crystal = 1,
	)
	time = 15
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/proto_nitrate_shard_weapon
	name = "Proto nitrate shard"
	result = /obj/item/proto_nitrate_shard
	reqs = list(
		/obj/item/shard/proto_nitrate = 1,
		/obj/item/stack/sheet/cloth = 1,
	)
	time = 25
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/hot_ice_pack
	name = "Hot ice cooling pack"
	result = /obj/item/hot_ice_pack
	reqs = list(
		/obj/item/stack/sheet/hot_ice = 3,
		/obj/item/stack/sheet/cloth = 2,
	)
	time = 30
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

// --- Atmos equipment (из WhiteMoon tailoring.dm + atmospheric.dm) ---
/datum/crafting_recipe/atmospherics_gas_mask
	name = "Atmospherics gas mask"
	result = /obj/item/clothing/mask/gas/atmos
	tools = list(TOOL_WELDER)
	time = 80
	reqs = list(
		/obj/item/stack/sheet/mineral/metal_hydrogen = 1,
		/obj/item/stack/sheet/mineral/zaukerite = 1,
	)
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/igniter
	name = "Igniter"
	result = /obj/machinery/igniter
	reqs = list(
		/obj/item/stack/sheet/metal = 5,
		/obj/item/assembly/igniter = 1,
	)
	time = 20
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/ammonia_pack
	name = "Ammonia pack"
	result = /obj/item/ammonia_pack
	reqs = list(
		/obj/item/stack/ammonia_crystals = 3,
		/obj/item/stack/sheet/cloth = 2,
	)
	time = 25
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/metallic_hydrogen_rod
	name = "Metallic hydrogen rod"
	result = /obj/item/metallic_hydrogen_rod
	reqs = list(
		/obj/item/stack/sheet/mineral/metal_hydrogen = 1,
		/obj/item/stack/rods = 1,
	)
	time = 30
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/metallic_hydrogen_cooling_pack
	name = "Metallic hydrogen cooling pack"
	result = /obj/item/metallic_hydrogen_cooling_pack
	reqs = list(
		/obj/item/stack/sheet/mineral/metal_hydrogen = 2,
		/obj/item/stack/sheet/cloth = 2,
	)
	time = 35
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/elder_atmosian_statue
	name = "Elder Atmosian statue"
	result = /obj/structure/statue/elder_atmosian
	reqs = list(
		/obj/item/stack/sheet/mineral/metal_hydrogen = 20,
		/obj/item/stack/sheet/mineral/zaukerite = 15,
		/obj/item/stack/sheet/metal = 30,
	)
	time = 60
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/elder_atmosian_armor
	name = "Elder Atmosian armor"
	result = /obj/item/clothing/suit/armor/elder_atmosian
	reqs = list(
		/obj/item/stack/sheet/mineral/metal_hydrogen = 5,
		/obj/item/stack/sheet/mineral/zaukerite = 3,
		/obj/item/stack/sheet/metal = 10,
		/obj/item/clothing/suit/fire/atmos = 1,
	)
	time = 40
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/elder_atmosian_helmet
	name = "Elder Atmosian helmet"
	result = /obj/item/clothing/head/helmet/elder_atmosian
	reqs = list(
		/obj/item/stack/sheet/mineral/metal_hydrogen = 3,
		/obj/item/stack/sheet/mineral/zaukerite = 2,
		/obj/item/stack/sheet/metal = 5,
		/obj/item/clothing/head/hardhat/atmos = 1,
	)
	time = 40
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/metal_h2_fireaxe
	name = "Metal hydrogen fire axe"
	result = /obj/item/fireaxe/metal_h2_axe
	reqs = list(
		/obj/item/stack/sheet/mineral/metal_hydrogen = 7,
	)
	time = 30
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS

/datum/crafting_recipe/crystal_cell_assembly
	name = "Crystal cell assembly"
	result = /obj/item/stock_parts/cell/crystal_cell
	reqs = list(
		/obj/item/stack/sheet/mineral/plasma = 2,
		/obj/item/stack/sheet/mineral/diamond = 1,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/sheet/glass = 1,
	)
	tools = list(TOOL_WELDER, TOOL_SCREWDRIVER)
	time = 40
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERICS
