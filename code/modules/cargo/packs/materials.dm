
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
/////////////////////// Canisters & Materials ////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/materials
	group = "Canisters & Materials"

/datum/supply_pack/materials/bileworm
	name = "Кожа желчного червя"
	desc = "Два куска кожи желчного червя для усиления сферы шахтёрского MOD и защиты от лавы."
	cost = 1000
	contains = list(
		/obj/item/stack/sheet/animalhide/bileworm,
		/obj/item/stack/sheet/animalhide/bileworm,
	)
	crate_name = "кожа желчного червя"

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// Materials //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/materials/cardboard50
	crate_type = /obj/structure/closet/secure_closet/cargo
	name = "50 Cardboard Sheets"
	desc = "Создайте кучу коробок."
	cost = 3000
	contains = list(/obj/item/stack/sheet/cardboard/fifty)

/datum/supply_pack/materials/license50
	name = "50 Empty License Plates"
	desc = "Создайте кучу коробок."
	cost = 1000  // 50 * 25 + 700 - 1000 = 950 credits profit
	contains = list(/obj/item/stack/license_plates/empty/fifty)
	crate_name = "empty license plate crate"

/datum/supply_pack/materials/glass50
	crate_type = /obj/structure/closet/secure_closet/cargo
	name = "50 Стеклянных листов"
	desc = "Let some nice light in with fifty glass sheets!"
	cost = 3000
	contains = list(/obj/item/stack/sheet/glass/fifty)

/datum/supply_pack/materials/metal50
	crate_type = /obj/structure/closet/secure_closet/cargo
	name = "50 Metal Sheets"
	desc = "Любой строительный проект начинается с хорошей стопки из пятидесяти металлических листов!"
	cost = 3000
	contains = list(/obj/item/stack/sheet/metal/fifty)

/datum/supply_pack/materials/plasteel20
	crate_type = /obj/structure/closet/secure_closet/cargo
	name = "20 Plasteel Sheets"
	desc = "Укрепите целостность станции двадцатью листами пластали!"
	cost = 4000
	contains = list(/obj/item/stack/sheet/plasteel/twenty)

/datum/supply_pack/materials/plastic20
	crate_type = /obj/structure/closet/secure_closet/cargo
	name = "50 Plastic Sheets"
	desc = "Соберите неограниченное количество игрушек из пятидесяти пластиковых листов!"
	cost = 2000
	contains = list(/obj/item/stack/sheet/plastic/fifty)

/datum/supply_pack/materials/sandstone30
	crate_type = /obj/structure/closet/secure_closet/cargo
	name = "30 Sandstone Blocks"
	desc = "Ни песчаные, ни каменные, эти тридцать блоков все равно выполнят свою работу."
	cost = 1500
	contains = list(/obj/item/stack/sheet/mineral/sandstone/thirty)

/datum/supply_pack/materials/wood20
	crate_type = /obj/structure/closet/secure_closet/cargo
	name = "20 Wood Planks"
	desc = "Превратите скучную плитку в красивый панельный пол и многое другое с помощью двадцати деревянных досок!"
	cost = 2000 // 6-7 planks shy from having equal import/export prices
	contains = list(/obj/item/stack/sheet/mineral/wood/twenty)

/datum/supply_pack/materials/rcdammo
	crate_type = /obj/structure/closet/secure_closet/cargo
	name = "Large RCD ammo Single-Pack"
	desc = "Один большой сжатый пакет материалов для RCD, чтобы помочь с любыми отверстиями или проектами, над которыми могут работать люди."
	cost = 600
	contains = list(/obj/item/rcd_ammo/large)

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// Canisters //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/materials/bz
	name = "BZ Canister Crate"
	desc = "Содержит канистру BZ. Требуется доступ к токсинам, чтобы открыть."
	cost = 7500 // Costs 3 credits more than what you can get for selling it.
	access = ACCESS_TOX_STORAGE
	contains = list(/obj/machinery/portable_atmospherics/canister/bz)
	crate_name = "BZ canister crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/materials/carbon_dio
	name = "Carbon Dioxide Canister"
	desc = "Содержит канистру с углекислым газом."
	cost = 3000
	contains = list(/obj/machinery/portable_atmospherics/canister/carbon_dioxide)
	crate_name = "carbon dioxide canister crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/nitrogen
	name = "Nitrogen Canister"
	desc = "Содержит канистру с азотом."
	cost = 2000
	contains = list(/obj/machinery/portable_atmospherics/canister/nitrogen)
	crate_name = "nitrogen canister crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/nitrous_oxide_canister
	name = "Nitrous Oxide Canister"
	desc = "Содержит канистру с закисью азота. Для открытия требуется доступ к атмосферным воздействиям."
	cost = 3000
	access = ACCESS_ATMOSPHERICS
	contains = list(/obj/machinery/portable_atmospherics/canister/nitrous_oxide)
	crate_name = "nitrous oxide canister crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/materials/oxygen
	name = "Oxygen Canister"
	desc = "Содержит канистру с кислородом. Консервированный в Друидии."
	cost = 1500
	contains = list(/obj/machinery/portable_atmospherics/canister/oxygen)
	crate_name = "oxygen canister crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/water_vapor
	name = "Water Vapor Canister"
	desc = "Содержит баллон с водяным паром. Клянусь богом, если ты откроешь это в коридорах..."
	cost = 2500
	contains = list(/obj/machinery/portable_atmospherics/canister/water_vapor)
	crate_name = "water vapor canister crate"
	crate_type = /obj/structure/closet/crate/large

//////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Tanks ////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/materials/fueltank
	name = "Fuel Tank Crate"
	desc = "Содержит сварочный топливный бак. Осторожно, легко воспламеняется."
	cost = 800
	contains = list(/obj/structure/reagent_dispensers/fueltank)
	crate_name = "fuel tank crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/hightankfuel
	name = "Large Fuel Tank Crate"
	desc = "Содержит топливный бак большой емкости. Храните содержимое вдали от открытого огня."
	cost = 2000
	contains = list(/obj/structure/reagent_dispensers/fueltank/high)
	crate_name = "high-capacity fuel tank crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/watertank
	name = "Water Tank Crate"
	desc = "Содержит резервуар с монооксидом дигидрогена... звучит опасно."
	cost = 600
	contains = list(/obj/structure/reagent_dispensers/watertank)
	crate_name = "water tank crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/foamtank
	name = "Firefighting Foam Tank Crate"
	desc = "Содержит резервуар с противопожарной пеной. Также известен как проклятие плазменного человека."
	cost = 1500
	contains = list(/obj/structure/reagent_dispensers/foamtank)
	crate_name = "foam tank crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/hightank
	name = "Large Water Tank Crate"
	desc = "Содержит резервуар для воды большой емкости. Полезно для ботаники или других сервисных работ."
	cost = 1200
	contains = list(/obj/structure/reagent_dispensers/watertank/high)
	crate_name = "high-capacity water tank crate"
	crate_type = /obj/structure/closet/crate/large
