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
	/// Минимальное давление на подающей линии. Ноль - рецепту всё равно.
	///
	/// Проверяется давление ВХОДА, а не внутренней камеры: камера набирает
	/// давление сама по мере закачки, и порог на ней ничего бы не требовал.
	/// Порог на входе означает буквально "додави подающую линию" - это и есть
	/// смысл ворот.
	var/min_pressure = 0
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

// Алмаз - это углерод под давлением, и до сих пор он был лучшим рецептом в
// игре по соотношению труда к награде: 1500 молей самого дешёвого газа на
// станции (CO2 идёт при любом горении плазмы и его выдыхают люди) давали
// ценный материал без цепочки, риска и оборудования. Поднимать цену в молях
// бессмысленно - CO2 бесконечен, вырос бы только таймер. Вместо этого рецепт
// требует давления, до которого газовый насос не достаёт.
/datum/gas_recipe/crystallizer/diamond
	id = "diamond"
	name = "Diamond"
	min_temp = 10000
	max_temp = 30000
	min_pressure = GAS_RECIPE_HIGH_PRESSURE
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

// Пиронит здесь не для того, чтобы поднять цену - 300 молей поверх десяти тысяч
// ничего не меняют, - а чтобы верхний предмет игры требовал верхней цепочки:
// контур высокого давления ещё и должен в нём что-то сварить, а не просто
// довезти газ.
/datum/gas_recipe/crystallizer/shard
	id = "crystal_shard"
	name = "Supermatter crystal shard"
	min_temp = 10
	max_temp = 20
	min_pressure = GAS_RECIPE_HIGH_PRESSURE
	energy_release = 3500000
	dangerous = TRUE
	requirements = list(GAS_HYPERNOB = 250, GAS_ANTINOBLIUM = 250, GAS_BZ = 200, GAS_PYRONITE = 300, GAS_PLASMA = 5000, GAS_O2 = 4500)
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

// Заукер - шесть газов вглубь плюс антинобель, и до сих пор весь рецепт стоил
// 33 моля суммарно. Гипернобель при цепочке в два шага стоил 1085: самый
// глубокий газ в игре обходился в тридцать раз дешевле заметно более простого.
// Это была опечатка баланса, а не решение.
//
// Порога давления здесь нет намеренно. Ворота 15000 кПа честны только там, где
// линию можно догреть (алмаз): при криогенном окне 5-20 K они означают ~80+
// молей на литр ХОЛОДНОЙ подающей линии - десятки тысяч молей ради рецепта в
// 400, и нагревом это не решается, потому что камера обязана остаться ледяной.
// Цену рецепта несут моли и глубина цепочки, холод - его сборочные ворота.
/datum/gas_recipe/crystallizer/zaukerite
	id = "zaukerite"
	name = "Zaukerite sheet"
	min_temp = 5
	max_temp = 20
	energy_release = 2900000
	requirements = list(GAS_ANTINOBLIUM = 60, GAS_ZAUKER = 240, GAS_BZ = 100)
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

// Постоянные предметы второго уровня.
//
// Нитрий, хилий и прото-нитрат стоили по 260-270 молей каждый и давали ровно
// одну одноразовую гранату - то есть весь второй уровень отличался от первого
// только размером награды, а не её родом. Дешёвый рецепт-граната остаётся: его
// знают, и отбирать известный путь незачем. Рядом встаёт вчетверо более дорогой
// рецепт на предмет, который живёт всю смену, и выбор "расходник сейчас или
// вещь до конца смены" делает игрок, а не таблица.
//
// Все три предмета уже есть в кодовой базе, новых сущностей не заводится, и ни
// один из них не является антаг-снаряжением. Порога по давлению у этих рецептов
// нет намеренно: высокое давление - это признак третьего уровня, и смешивать
// уровни значило бы стереть между ними границу.
//
// Окно температур у каждого - подмножество окна его же гранаты: установка та
// же, требуется только более точное её ведение.

/datum/gas_recipe/crystallizer/healium_defibrillator
	id = "healium_defib"
	name = "Healium defibrillator core"
	min_temp = 240
	max_temp = 330
	energy_release = -2400000
	requirements = list(GAS_HEALIUM = 400, GAS_O2 = 400, GAS_PLASMA = 200, GAS_BZ = 100)
	products = list(/obj/item/defibrillator/compact/loaded/crystallizer = 1)

/datum/gas_recipe/crystallizer/nitrium_boots
	id = "nitrium_boots"
	name = "Nitrium impulse boots"
	min_temp = 12
	max_temp = 20
	energy_release = -60000
	requirements = list(GAS_NITRIUM = 500, GAS_O2 = 250, GAS_BZ = 150, GAS_TRITIUM = 200)
	products = list(/obj/item/clothing/shoes/bhop/crystallizer = 1)

/datum/gas_recipe/crystallizer/proto_nitrate_projector
	id = "proto_nitrate_projector"
	name = "Proto nitrate holofan emitter"
	min_temp = 250
	max_temp = 320
	energy_release = 1700000
	requirements = list(GAS_PROTO_NITRATE = 400, GAS_N2 = 300, GAS_O2 = 300, GAS_HYDROGEN = 100)
	products = list(/obj/item/holosign_creator/atmos/sustained = 1)
