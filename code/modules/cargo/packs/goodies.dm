
/datum/supply_pack/goody
	access = NONE
	group = "Goodies"
	goody = PACK_GOODY_PRIVATE

/datum/supply_pack/goody/combatknives_single
	name = "Combat Knife Single-Pack"
	desc = "Содержит один заточенный боевой нож. Гарантированно плотно прилегает к любому стандартному ботинку Nanotrasen."
	cost = 800
	contains = list(/obj/item/kitchen/knife/combat)

/datum/supply_pack/goody/sologamermitts
	name = "Insulated Gloves Single-Pack"
	desc = "Основа современного общества. Почти никогда не заказывался для реальных инженеров."
	cost = 800
	contains = list(/obj/item/clothing/gloves/color/yellow)

/datum/supply_pack/goody/sunglasses_single
	name = "Sunglasses Single-Pack"
	desc = "Стильные очки, что защитят вас от палящих лучей Солнца и флешеров."
	cost = 500
	contains = list(/obj/item/clothing/glasses/sunglasses)

/datum/supply_pack/goody/firstaidbruises_single
	name = "Bruise Treatment Kit Single-Pack"
	desc = "Аптечка первой помощи, идеально подходящая для восстановления после того, как вас придавили в воздушном шлюзе. Знаете ли вы, что людей постоянно раздавливает в воздушных шлюзах? Интересно..."
	cost = 330
	contains = list(/obj/item/storage/firstaid/brute)

/datum/supply_pack/goody/firstaidburns_single
	name = "Burn Treatment Kit Single-Pack"
	desc = "Аптечка первой помощи при ожогах. В рекламе изображен подмигивающий специалист по атмосферным воздействиям, поднимающий большой палец вверх и говорящий: Ошибки случаются!"
	cost = 330
	contains = list(/obj/item/storage/firstaid/fire)

/datum/supply_pack/goody/firstaid_single
	name = "First Aid Kit Single-Pack"
	desc = "Аптечка первой помощи, пригодная для лечения большинства видов телесных повреждений."
	cost = 250
	contains = list(/obj/item/storage/firstaid/regular)

/datum/supply_pack/goody/firstaidoxygen_single
	name = "Oxygen Deprivation Kit Single-Pack"
	desc = "Аптечка первой помощи при кислородном голодании, широко продаваемая для тех, кто сильно боится удушья."
	cost = 330
	contains = list(/obj/item/storage/firstaid/o2)

/datum/supply_pack/goody/firstaidtoxins_single
	name = "Toxin Treatment Kit Single-Pack"
	desc = "Аптечка первой помощи, предназначенная для заживления повреждений, нанесенных тяжелыми токсинами."
	cost = 330
	contains = list(/obj/item/storage/firstaid/toxin)

/datum/supply_pack/goody/toolbox // mostly just to water down coupon probability
	name = "Mechanical Toolbox"
	desc = "Полностью укомплектованный механический набор инструментов для тех случаев, когда вам лень просто распечатать их."
	cost = 300
	contains = list(/obj/item/storage/toolbox/mechanical)

/datum/supply_pack/goody/electrical_toolbox
	name = "Electrical Toolbox"
	desc = "Полностью укомплектованный набор инструментов для электромонтажа, на случай, если вам лень просто распечатать их."
	cost = 300
	contains = list(/obj/item/storage/toolbox/electrical)

/datum/supply_pack/goody/valentine
	name = "Valentine Card"
	desc = "Произведите впечатление на  особенного человека! Поставляется с одной валентинкой и бесплатным конфетным сердечком!"
	cost = 150
	contains = list(/obj/item/valentine,
					/obj/item/reagent_containers/food/snacks/candyheart)

/datum/supply_pack/goody/beeplush
	name = "Bee Plushie"
	desc = "Самая важная вещь, на которую вы могли бы потратить свои кровно заработанные деньги."
	cost = 1500
	contains = list(/obj/item/toy/plush/beeplushie)

/datum/supply_pack/goody/dyespray
	name = "Hair Dye Spray"
	desc = "Классный спрей для окрашивания волос в потрясающие цвета!"
	cost = PAYCHECK_EASY * 2
	contains = list(/obj/item/dyespray)

/datum/supply_pack/goody/beach_ball
	name = "Beach Ball"
	desc = "Простой пляжный мяч - один из самых популярных продуктов Nanotrasen."
	cost = 200
	contains = list(/obj/item/toy/beach_ball)

/datum/supply_pack/goody/medipen_twopack
	name = "Medipen Two-Pack"
	desc = "Содержит один стандартный медипен с эпинефрином и однин старндартный медипен первой помощи. На тот случай, если вы хотите подготовиться к худшему."
	cost = 500
	contains = list(/obj/item/reagent_containers/hypospray/medipen,
					/obj/item/reagent_containers/hypospray/medipen/ekit)

/datum/supply_pack/goody/industrialrcd
	name = "Industrial RCD Single-Pack"
	desc = "Тот самый случай, когда станцию разнесло в клочья, а инженер надрывается над целью. Этот индустриальный RCD позволить построить и залатать что угодно! Конечно последствиями небольшой наценки за пересылку. "
	cost = 3000
	contains = list(/obj/item/construction/rcd/industrial)

/datum/supply_pack/goody/radbgone
	name = "Rradiation treatment kit Single-Pack"
	desc = "Аптечка первой помощи, предназначенная для борьбы с последствиями радиационного облучения. Выбор 9 из 10 облученных инженеров."
	cost = 500
	contains = list(/obj/item/storage/firstaid/radbgone)

/datum/supply_pack/goody/russianroulete
	name = "Russian roulete revolver Single-Pack"
	desc = "Для тех кому совсем нечего делать в долгую смену"
	cost = 300
	contains = list(/obj/item/gun/ballistic/revolver/russian)
