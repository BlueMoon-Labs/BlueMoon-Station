
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Emergency ///////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/emergency
	group = "Emergency"

/datum/supply_pack/emergency/vehicle
	name = "Biker Gang Kit" //TUNNEL SNAKES OWN THIS TOWN
	desc = "ТУННЕЛЬНЫЕ ЗМЕИ ВЛАДЕЮТ ЭТИМ ГОРОДОМ. Содержит вездеход без марки, две банки с аэрозольной краской и полный бандитский наряд - состоит из черных перчаток, банданы с угрожающим черепом и МИЛОГО кожаного пальто!"
	cost = 2500
	contraband = TRUE
	contains = list(/obj/vehicle/ridden/atv,
					/obj/item/key,
					/obj/item/toy/crayon/spraycan,
					/obj/item/toy/crayon/spraycan,
					/obj/item/clothing/suit/jacket/leather/overcoat,
					/obj/item/clothing/gloves/color/black,
					/obj/item/clothing/head/soft,
					/obj/item/clothing/mask/bandana/skull)//so you can properly #cargoniabikergang
	crate_name = "Biker Kit"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/emergency/bio
	name = "Biological Emergency Crate"
	desc = "В этом ящике находятся 2 полных биокостюма, которые защитят вас от вирусов, а также биопакет и два шприца с космоциллином."
	cost = 2000
	contains = list(/obj/item/clothing/head/bio_hood,
					/obj/item/clothing/head/bio_hood,
					/obj/item/clothing/suit/bio_suit,
					/obj/item/clothing/suit/bio_suit,
					/obj/item/storage/bag/bio,
					/obj/item/reagent_containers/syringe/antiviral,
					/obj/item/reagent_containers/syringe/antiviral,
					/obj/item/clothing/gloves/color/latex/nitrile,
					/obj/item/clothing/gloves/color/latex/nitrile)
	crate_name = "bio suit crate"

/datum/supply_pack/emergency/equipment
	name = "Emergency Bot/Internals Crate"
	desc = "Взрывы сбили тебя с ног? Эти расходные материалы гарантированно залатают дыры как на станциях, так и на людях! Поставляется с двумя плиточными ботами, двумя медицинскими ботами, пятью кислородными масками и пятью небольшими кислородными баллонами."
	cost = 2750
	contains = list(/mob/living/simple_animal/bot/floorbot,
					/mob/living/simple_animal/bot/floorbot,
					/mob/living/simple_animal/bot/medbot,
					/mob/living/simple_animal/bot/medbot,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas)
	crate_name = "emergency crate"
	crate_type = /obj/structure/closet/crate/internals

/datum/supply_pack/emergency/medicalemergency
	name = "Emergency Medical Supplies" //Almost all of this can be ordered seperatly for a much cheaper price, but the HUD increases it.
	desc = "Предметы первой необходимости для фронтового медика. Содержит две коробки с мешками для тела, медицинский HUD, дефибриллятор, медицинский пояс, флаконы с токсинами, эпинефрином и несколько видов медицинских наборов."
	cost = 10000
	contains = list(/obj/item/storage/box/bodybags,
					/obj/item/storage/box/bodybags,
					/obj/item/clothing/glasses/hud/health,
					/obj/item/defibrillator/loaded,
					/obj/item/storage/belt/medical,
					/obj/item/storage/firstaid/toxin,
					/obj/item/storage/firstaid/o2,
					/obj/item/storage/firstaid/brute,
					/obj/item/storage/firstaid/fire,
					/obj/item/reagent_containers/glass/bottle/toxin,
					/obj/item/reagent_containers/glass/bottle/toxin,
					/obj/item/storage/box/medipens)
	crate_name = "medical emergency crate"
	crate_type = /obj/structure/closet/crate/medical

/datum/supply_pack/emergency/medemergencylite
	name = "Emergency Medical Supplies (Lite)"
	desc = "Менее оптимальный, но все же эффективный набор инструментов для оказания неотложной помощи. Содержит коробку с мешками для тела, несколько обычных (и продвинутых) анализаторов здоровья, целебные спреи, аптечку первой помощи,  уголь, немного марли, флакон с токсинами и несколько запасных медикаментов."
	cost = 2800
	contains = list(/obj/item/storage/box/bodybags,
					/obj/item/stack/medical/gauze,
					/obj/item/stack/medical/gauze,
					/obj/item/healthanalyzer,
					/obj/item/healthanalyzer,
					/obj/item/healthanalyzer/advanced,
					/obj/item/storage/firstaid/regular,
					/obj/item/reagent_containers/medspray/styptic,
					/obj/item/reagent_containers/medspray/silver_sulf,
					/obj/item/reagent_containers/medspray/synthflesh,
					/obj/item/reagent_containers/glass/bottle/charcoal,
					/obj/item/reagent_containers/glass/bottle/charcoal,
					/obj/item/reagent_containers/glass/bottle/toxin,
					/obj/item/reagent_containers/hypospray/medipen,
					/obj/item/reagent_containers/hypospray/medipen,
					/obj/item/reagent_containers/hypospray/medipen,
					/obj/item/reagent_containers/hypospray/medipen)
	crate_name = "medical emergency crate (lite)"
	crate_type = /obj/structure/closet/crate/medical

/datum/supply_pack/emergency/radiatione_emergency
	name = "Emergency Radiation Protection Crate"
	desc = "Переживите Ядерный апокалипсис и двигатель Суперматерии одинаково с двумя комплектами радиационных костюмов. Каждый комплект содержит шлем, костюм и счетчик Гейгера. Мы даже добавим несколько пузырьков с таблетками, которые способны справиться с радиацией и последствиями отравления."
	cost = 2500
	contains = list(/obj/item/clothing/head/radiation,
					/obj/item/clothing/head/radiation,
					/obj/item/clothing/suit/radiation,
					/obj/item/clothing/suit/radiation,
					/obj/item/geiger_counter,
					/obj/item/geiger_counter,
					/obj/item/storage/pill_bottle/mutarad,
					/obj/item/storage/firstaid/radbgone)
	crate_name = "radiation protection crate"
	crate_type = /obj/structure/closet/crate/radiation

/datum/supply_pack/emergency/rcds
	name = "Emergency RCDs"
	desc = "Бомбы взрываются на станции? Ассистент взорвал СМ, и теперь вам нужно заделать дыру, которую кристалл оставил после себя? Что ж, в этом ящике есть пара RCD, чтобы вы могли легко устранить любую проблему, которая у вас может возникнуть! Заряды в комплект не входят !"
	cost = 1500
	contains = list(/obj/item/construction/rcd,
					/obj/item/construction/rcd)
	crate_name = "emergency rcds"
	crate_type = /obj/structure/closet/crate/internals

/datum/supply_pack/emergency/bomb
	name = "Explosive Emergency Crate"
	desc = "Ученный сошла с ума? Что-то пикает за шлюзом? Купите сейчас и станьте героем, которого требует станция! Время в комплект не входит, но есть полный бомбовый костюм и капюшон, а также маска и набор для обезвреживания! Только неядерные заряды."
	cost = 1500
	contains = list(/obj/item/clothing/head/bomb_hood,
					/obj/item/clothing/suit/bomb_suit,
					/obj/item/clothing/mask/gas,
					/obj/item/screwdriver,
					/obj/item/wirecutters,
					/obj/item/multitool)
	crate_name = "bomb suit crate"

/datum/supply_pack/emergency/firefighting
	name = "Firefighting Crate"
	desc = "Только вы можете предотвратить пожар на станции. Возьмите с собой два пожарных костюма, противогазы, фонарики, большие кислородные баллоны, огнетушители и каски!"
	cost = 1200
	contains = list(/obj/item/clothing/suit/fire/firefighter,
					/obj/item/clothing/suit/fire/firefighter,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/flashlight,
					/obj/item/flashlight,
					/obj/item/tank/internals/oxygen/red,
					/obj/item/tank/internals/oxygen/red,
					/obj/item/extinguisher/advanced,
					/obj/item/extinguisher/advanced,
					/obj/item/clothing/head/hardhat/red,
					/obj/item/clothing/head/hardhat/red)
	crate_name = "firefighting crate"

/datum/supply_pack/emergency/Flexiseal
	name = "Flexi Seal Crate"
	desc = "Flexi Seal - идеальный материал для обеспечения безопасности ядерного реактора!"
	cost = 1000
	contains = list(/obj/item/sealant)
	crate_name = "Flexi Seal Crate"
	crate_type = /obj/structure/closet/crate/radiation

/datum/supply_pack/emergency/atmostank
	name = "Firefighting Tank Backpack"
	desc = "Тушите пожары с помощью этого вместительного рюкзака для пожаротушения. Для открытия требуется доступ к атмосу"
	cost = 1000
	access = ACCESS_ATMOSPHERICS
	contains = list(/obj/item/watertank/atmos)
	crate_name = "firefighting backpack crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/emergency/internals
	name = "Internals Crate"
	desc = "Управляйте своей жизненной энергией и контролируйте свое дыхание с помощью трех дыхательных масок, трех аварийных кислородных баллонов и трех больших воздушных баллонов."//IS THAT A
	cost = 1000
	contains = list(/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath,
					/obj/item/tank/internals/emergency_oxygen,
					/obj/item/tank/internals/emergency_oxygen,
					/obj/item/tank/internals/emergency_oxygen,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air)
	crate_name = "internals crate"
	crate_type = /obj/structure/closet/crate/internals

/datum/supply_pack/emergency/metalfoam
	name = "Metal Foam Grenade Crate"
	desc = "Заделайте эти досадные пробоины в корпусе 14-тью металлическими пенопластовыми гранатами."
	cost = 1500
	contains = list(/obj/item/storage/box/metalfoam,
					/obj/item/storage/box/metalfoam)
	crate_name = "metal foam grenade crate"

/datum/supply_pack/emergency/mre
	name = "MRE Packs (Emergency Rations)"
	desc = "Свет выключен. Кислород на исходе. У вас закончилась еда. Не позволяй этому случиться с тобой! Закажите наши комплекты сухпайков под брендом NT уже сегодня! Этот набор содержит 5 упаковок с рандомизированным меню и кислородным баллоном."
	cost = 2000
	contains = list(/obj/item/storage/box/mre/menu1/safe,
					/obj/item/storage/box/mre/menu1/safe,
					/obj/item/storage/box/mre/menu2/safe,
					/obj/item/storage/box/mre/menu2/safe,
					/obj/item/storage/box/mre/menu3,
					/obj/item/storage/box/mre/menu4/safe)
	crate_name = "MRE crate (emergency rations)"

/datum/supply_pack/emergency/plasma_spacesuit
	name = "Plasmaman Space Envirosuits"
	desc = "Содержит два вместительных костюма. Закажите сейчас, и мы разыграем два бесплатных шлема! Для открытия требуется доступ в EVA."
	cost = 4000
	access = ACCESS_EVA
	contains = list(/obj/item/clothing/suit/space/eva/plasmaman,
					/obj/item/clothing/suit/space/eva/plasmaman,
					/obj/item/clothing/head/helmet/space/plasmaman,
					/obj/item/clothing/head/helmet/space/plasmaman)
	crate_name = "plasmaman EVA crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/emergency/plasmaman
	name = "Plasmaman Supply Kit"
	desc = "Два комплекта поддержания жизни плазмаменов."
	cost = 2000
	contains = list(/obj/item/clothing/under/plasmaman,
					/obj/item/clothing/under/plasmaman,
					/obj/item/tank/internals/plasmaman/belt/full,
					/obj/item/tank/internals/plasmaman/belt/full,
					/obj/item/clothing/head/helmet/space/plasmaman,
					/obj/item/clothing/head/helmet/space/plasmaman)
	crate_name = "plasmaman supply kit"

/datum/supply_pack/emergency/radiation
	name = "Radiation Protection Crate"
	desc = "Переживите Ядерный апокалипсис и двигатель Суперматерии с двумя комплектами радиационных костюмов. Каждый комплект содержит шлем, костюм и счетчик Гейгера. Мы даже добавим бутылку водки и несколько стаканов, учитывая продолжительность жизни людей, которые это заказывают."
	cost = 1300
	contains = list(/obj/item/clothing/head/radiation,
					/obj/item/clothing/head/radiation,
					/obj/item/clothing/suit/radiation,
					/obj/item/clothing/suit/radiation,
					/obj/item/geiger_counter,
					/obj/item/geiger_counter,
					/obj/item/reagent_containers/food/drinks/bottle/vodka,
					/obj/item/reagent_containers/food/drinks/drinkingglass/shotglass,
					/obj/item/reagent_containers/food/drinks/drinkingglass/shotglass)
	crate_name = "radiation protection crate"
	crate_type = /obj/structure/closet/crate/radiation

/datum/supply_pack/emergency/spacesuit
	name = "Space Suit Crate"
	desc = "Содержит два EVA костюма. Для открытия требуется доступ EVA."
	cost = 4500
	contains = list(/obj/item/clothing/suit/space/eva,
					/obj/item/clothing/suit/space/eva,
					/obj/item/clothing/head/helmet/space/eva,
					/obj/item/clothing/head/helmet/space/eva,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath)
	crate_name = "space suit crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/emergency/oldspacesuit
	name = "Space Suit Crate"
	desc = "Содержит два устаревших костюма от Space-Goodwill. Для открытия требуется доступ EVA."
	cost = 2000
	contains = list(/obj/item/clothing/suit/space,
					/obj/item/clothing/suit/space,
					/obj/item/clothing/head/helmet/space,
					/obj/item/clothing/head/helmet/space,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath)
	crate_name = "space suit crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/emergency/soft_suit
	name = "Space Suits (Fragile)"
	desc = "Бомбы взрываются слева и справа? Метеориты летают вокруг станции ? Ну что ж! Вот два хрупких скафандра на случай чрезвычайных ситуаций. Поставляется с воздухом и масками."
	cost = 4500
	contains = list(/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/suit/space/fragile,
					/obj/item/clothing/suit/space/fragile,
					/obj/item/clothing/head/helmet/space/fragile,
					/obj/item/clothing/head/helmet/space/fragile)
	crate_name = "emergency crate"
	crate_type = /obj/structure/closet/crate/internals

/datum/supply_pack/emergency/spacejets
	name = "Spare EVA Jetpacks"
	desc = "Содержит три реактивных ранца для EVA. Для открытия требуется доступ в EVA."
	cost = 2000
	access = ACCESS_EVA
	contains = list(/obj/item/tank/jetpack/carbondioxide/eva,
					/obj/item/tank/jetpack/carbondioxide/eva,
					/obj/item/tank/jetpack/carbondioxide/eva)
	crate_name = "EVA Jetpacks Crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/emergency/specialops
	name = "Special Ops Supplies"
	desc = "(*!&@#ЭТОТ МАЛЕНЬКИЙ ЗАКАЗ МОЖЕТ ПОМОЧЬ ВАМ В КРАЙНЕМ СЛУЧАЕ. СОДЕРЖИТ КОРОБКУ С ПЯТЬЮ ЭЛЕКТРОМАГНИТНЫМИ ГРАНАТАМИ, ТРЕМЯ ДЫМОВЫМИ ШАШКАМИ, ЗАЖИГАТЕЛЬНОЙ ГРАНАТОЙ И СОННОЙ РУЧКОЙ, ПОЛНОЙ ПРИЯТНЫХ ТОКСИНОВ!#@*$"
	hidden = TRUE
	cost = 2200
	contains = list(/obj/item/storage/box/emps,
					/obj/item/grenade/smokebomb,
					/obj/item/grenade/smokebomb,
					/obj/item/grenade/smokebomb,
					/obj/item/pen/sleepy,
					/obj/item/grenade/chem_grenade/incendiary)
	crate_name = "emergency crate"
	crate_type = /obj/structure/closet/crate/internals

/datum/supply_pack/emergency/weedcontrol
	name = "Weed Control Crate"
	desc = "Держите эти сорняки ПОДАЛЬШЕ. Содержит косу, противогаз, два баллончика с растением-B-Gone и две химические гранаты против сорняков. Гарантия аннулируется, если используется на ambrosia. Для открытия требуется доступ к гидропонике."
	cost = 1800
	access = ACCESS_HYDROPONICS
	contains = list(/obj/item/scythe,
					/obj/item/clothing/mask/gas,
					/obj/item/grenade/chem_grenade/antiweed,
					/obj/item/grenade/chem_grenade/antiweed,
					/obj/item/reagent_containers/spray/plantbgone,
					/obj/item/reagent_containers/spray/plantbgone)
	crate_name = "weed control crate"
	crate_type = /obj/structure/closet/crate/secure/hydroponics
