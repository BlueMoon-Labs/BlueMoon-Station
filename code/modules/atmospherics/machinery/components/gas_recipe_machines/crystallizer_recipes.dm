/// Global list of recipes for atmospheric machines (id -> recipe)
GLOBAL_LIST_INIT(gas_recipe_meta, gas_recipes_list())

/proc/gas_recipes_list()
	. = list()
	for(var/recipe_path in subtypesof(/datum/gas_recipe))
		var/datum/gas_recipe/recipe = new recipe_path()
		if(recipe.id != "")
			.[recipe.id] = recipe

/datum/gas_recipe
	var/id = ""
	var/machine_type = ""
	var/name = ""
	var/min_temp = TCMB
	var/max_temp = INFINITY
	var/energy_release = 0
	var/dangerous = FALSE
	/// Gas ID -> moles required (e.g. list(GAS_O2 = 1000, GAS_HYPERNOB = 85))
	var/list/requirements
	/// path -> count (e.g. list(/obj/item/hypernoblium_crystal = 1))
	var/list/products

/datum/gas_recipe/crystallizer
	machine_type = "Crystallizer"

/datum/gas_recipe/crystallizer/hypern_crystalium
	id = "hyper_crystalium"
	name = "Hypernoblium Crystal"
	min_temp = 3
	max_temp = 250
	energy_release = -250000
	requirements = list(GAS_O2 = 1000, GAS_HYPERNOB = 85)
	products = list(/obj/item/hypernoblium_crystal = 1)

/datum/gas_recipe/crystallizer/diamond
	id = "diamond"
	name = "Diamond"
	min_temp = 10000
	max_temp = 30000
	energy_release = 9500000
	requirements = list(GAS_CO2 = 1500)
	products = list(/obj/item/stack/sheet/mineral/diamond = 1)

/datum/gas_recipe/crystallizer/plasma_sheet
	id = "plasma_sheet"
	name = "Plasma sheet"
	min_temp = 10
	max_temp = 20
	energy_release = 3500000
	requirements = list(GAS_PLASMA = 450)
	products = list(/obj/item/stack/sheet/mineral/plasma = 1)

/datum/gas_recipe/crystallizer/crystallized_nitrium
	id = "crystallized_nitrium"
	name = "Nitrium crystal"
	min_temp = 10
	max_temp = 25
	energy_release = -45000
	requirements = list(GAS_NITRIUM = 150, GAS_O2 = 70, GAS_BZ = 50)
	products = list(/obj/item/nitrium_crystal = 1)

/datum/gas_recipe/crystallizer/metallic_hydrogen
	id = "metal_h"
	name = "Metallic hydrogen"
	min_temp = 10000 // H2 + BZ catalyst at high heat and pressure (around or above 10,000 K)
	max_temp = 150000
	energy_release = -2500000
	requirements = list(GAS_HYDROGEN = 300, GAS_BZ = 50)
	products = list(/obj/item/stack/sheet/mineral/metal_hydrogen = 1)

/datum/gas_recipe/crystallizer/healium_grenade
	id = "healium_g"
	name = "Healium crystal"
	min_temp = 200
	max_temp = 400
	energy_release = -2000000
	requirements = list(GAS_HEALIUM = 100, GAS_O2 = 120, GAS_PLASMA = 50)
	products = list(/obj/item/grenade/gas_crystal/healium_crystal = 1)

/datum/gas_recipe/crystallizer/proto_nitrate_grenade
	id = "proto_nitrate_g"
	name = "Proto nitrate crystal"
	min_temp = 200
	max_temp = 400
	energy_release = 1500000
	requirements = list(GAS_PROTO_NITRATE = 100, GAS_N2 = 80, GAS_O2 = 80)
	products = list(/obj/item/grenade/gas_crystal/proto_nitrate_crystal = 1)

/datum/gas_recipe/crystallizer/hot_ice
	id = "hot_ice"
	name = "Hot ice"
	min_temp = 15
	max_temp = 35
	energy_release = -3000000
	requirements = list(GAS_FREON = 60, GAS_PLASMA = 160, GAS_O2 = 80)
	products = list(/obj/item/stack/sheet/hot_ice = 1)

/datum/gas_recipe/crystallizer/ammonia_crystal
	id = "ammonia_crystal"
	name = "Ammonia crystal"
	min_temp = 200
	max_temp = 240
	energy_release = 950000
	requirements = list(GAS_HYDROGEN = 50, GAS_N2 = 40)
	products = list(/obj/item/stack/ammonia_crystals = 2)

/datum/gas_recipe/crystallizer/shard
	id = "crystal_shard"
	name = "Supermatter crystal shard"
	min_temp = 10
	max_temp = 20
	energy_release = 3500000
	dangerous = TRUE
	requirements = list(GAS_HYPERNOB = 250, GAS_ANTINOBLIUM = 250, GAS_BZ = 200, GAS_PLASMA = 5000, GAS_O2 = 4500)
	products = list(/obj/machinery/power/supermatter_crystal/shard = 1)

/datum/gas_recipe/crystallizer/n2o_crystal
	id = "n2o_crystal"
	name = "Nitrous oxide crystal"
	min_temp = 50
	max_temp = 350
	energy_release = 3500000
	requirements = list(GAS_NITROUS = 150, GAS_BZ = 30)
	products = list(/obj/item/grenade/gas_crystal/nitrous_oxide_crystal = 1)

/datum/gas_recipe/crystallizer/crystal_ultra_cell
	id = "crystal_ultra_cell"
	name = "Crystal ultra cell"
	min_temp = 50
	max_temp = 90
	energy_release = -800000
	requirements = list(GAS_PLASMA = 800, GAS_HELIUM = 100, GAS_BZ = 50)
	products = list(/obj/item/stock_parts/cell/crystal_ultra_cell = 1)

/datum/gas_recipe/crystallizer/zaukerite
	id = "zaukerite"
	name = "Zaukerite sheet"
	min_temp = 5
	max_temp = 20
	energy_release = 2900000
	requirements = list(GAS_ANTINOBLIUM = 5, GAS_ZAUKER = 20, GAS_BZ = 8)
	products = list(/obj/item/stack/sheet/mineral/zaukerite = 2)

/datum/gas_recipe/crystallizer/fuel_pellet
	id = "fuel_basic"
	name = "standard fuel pellet"
	energy_release = -6000000
	requirements = list(GAS_O2 = 50, GAS_PLASMA = 100)
	products = list(/obj/item/fuel_pellet = 1)

/datum/gas_recipe/crystallizer/fuel_pellet_advanced
	id = "fuel_advanced"
	name = "advanced fuel pellet"
	energy_release = -6000000
	requirements = list(GAS_TRITIUM = 100, GAS_HYDROGEN = 100)
	products = list(/obj/item/fuel_pellet/advanced = 1)

/datum/gas_recipe/crystallizer/fuel_pellet_exotic
	id = "fuel_exotic"
	name = "exotic fuel pellet"
	energy_release = -6000000
	requirements = list(GAS_HYPERNOB = 100, GAS_NITRIUM = 100)
	products = list(/obj/item/fuel_pellet/exotic = 1)

/datum/gas_recipe/crystallizer/crystal_foam
	id = "crystal_foam"
	name = "Crystal foam grenade"
	energy_release = 140000
	requirements = list(GAS_CO2 = 150, GAS_NITROUS = 100, GAS_H2O = 25)
	products = list(/obj/item/grenade/gas_crystal/crystal_foam = 1)
