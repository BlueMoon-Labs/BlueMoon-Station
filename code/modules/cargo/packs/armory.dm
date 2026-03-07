
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Armory //////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/security/armory
	group = "Armory"
	access = ACCESS_ARMORY
	crate_type = /obj/structure/closet/crate/secure/weapon
	can_private_buy = FALSE

/datum/supply_pack/security/armory/bulletarmor
	name = "Bulletproof Armor Crate"
	desc = "Содержит три комплекта пуленепробиваемой брони. Гарантированно снижает останавливающую способность пули более чем наполовину. Для открытия требуется доступ к оружейной."
	cost = 1250
	contains = list(/obj/item/clothing/suit/armor/bulletproof,
					/obj/item/clothing/suit/armor/bulletproof,
					/obj/item/clothing/suit/armor/bulletproof)
	crate_name = "bulletproof armor crate"

/datum/supply_pack/security/armory/bullethelmets
	name = "Bulletproof Helmet Crate"
	desc = "Содержит три комплекта пуленепробиваемых шлемов. Гарантированно снижает останавливающую способность пули более чем наполовину. Для открытия требуется доступ к оружейной."
	cost = 1250
	contains = list(/obj/item/clothing/head/helmet/alt,
					/obj/item/clothing/head/helmet/alt,
					/obj/item/clothing/head/helmet/alt)
	crate_name = "bulletproof helmet crate"

/datum/supply_pack/security/armory/chemimp
	name = "Chemical Implants Crate"
	desc = "Содержит пять Remote Chemical implants. Для открытия требуется доступ к оружейной."
	cost = 1700
	contains = list(/obj/item/storage/box/chemimp)
	crate_name = "chemical implant crate"

/datum/supply_pack/security/armory/ballistic
	name = "Combat Shotguns Crate"
	desc = "Для тех случаев, когда врага абсолютно необходимо накормить свинцом. Содержит три боевых дробовика, разработанных Aussec, с тремя патронташами , а также семь патрон с картечью и 12-граммовыми пулями. Для открытия требуется доступ к оружейной."
	cost = 8000
	contains = list(/obj/item/gun/ballistic/shotgun/automatic/combat,
					/obj/item/gun/ballistic/shotgun/automatic/combat,
					/obj/item/gun/ballistic/shotgun/automatic/combat,
					/obj/item/storage/belt/bandolier,
					/obj/item/storage/belt/bandolier,
					/obj/item/storage/belt/bandolier,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/lethalslugs)
	crate_name = "combat shotguns crate"

/datum/supply_pack/security/armory/dragnetgun
	name = "DRAGnet gun Crate"
	desc = "Содержит два пулемета DRAGnet. Динамичное быстрое задержание виновных - это революция в правоохранительных технологиях, которую ВЫ хотите! Для открытия требуется доступ к оружейной."
	cost = 3250
	contains = list(/obj/item/gun/energy/e_gun/dragnet,
					/obj/item/gun/energy/e_gun/dragnet)
	crate_name = "anti riot net guns crate"

/datum/supply_pack/security/armory/energy
	name = "Energy Guns Crate"
	desc = "Содержит три Energy Guns, способных стрелять как несмертельными, так и смертельными лазерными импульсами. Для открытия требуется доступ к оружейной."
	cost = 3250
	contains = list(/obj/item/gun/energy/e_gun,
					/obj/item/gun/energy/e_gun,
					/obj/item/gun/energy/e_gun)
	crate_name = "energy gun crate"
	crate_type = /obj/structure/closet/crate/secure/plasma

/datum/supply_pack/security/armory/exileimp // Theres boxes in 2 lockers as well as gateway never realy being used sad
	name = "Exile Implants Crate"
	desc = "Содержит пять Exile Implants. Для открытия требуется доступ к оружейной."
	cost = 1050 //stops endless points
	contains = list(/obj/item/storage/box/exileimp)
	crate_name = "exile implant crate"

/datum/supply_pack/security/armory/lasercarbine
	name = "Modular Laser Rifle Carbine Crate"
	desc = "Содержит один модульный лазерный карабин. Данный карабин обладает возможностью самозарядки, а также обладает 5 видами стрельбы. Для открытия требуется доступ к оружейной."
	cost = 5000
	contains = list(/obj/item/gun/energy/modular_laser_rifle/carbine)
	crate_name = "modular laser rifle carbine crate"
	crate_type = /obj/structure/closet/crate/secure/plasma

/datum/supply_pack/security/armory/mindshield
	name = "Mindshield Implants Crate"
	desc = "Защититесь от радикальных мыслей с помощью трех Mindshield Implants. Для открытия требуется доступ к оружейной."
	cost = 4000
	contains = list(/obj/item/storage/lockbox/loyalty)
	crate_name = "mindshield implant crate"

/datum/supply_pack/security/armory/trackingimp
	name = "Tracking Implants Crate"
	desc = "Содержит четыре Tracking Implants и три зарядника с отслеживающими патронами 38 калибра. Для открытия требуется доступ к оружейной."
	cost = 1100
	contains = list(/obj/item/storage/box/trackimp,
					/obj/item/ammo_box/c38/trac,
					/obj/item/ammo_box/c38/trac,
					/obj/item/ammo_box/c38/trac)
	crate_name = "tracking implant crate"

/datum/supply_pack/security/armory/fire
	name = "Incendiary Weapons Crate"
	desc = "Гори, детка, гори. Содержит три зажигательные гранаты, семь зажигательных пуль, три плазменных баллона и огнемет. Для открытия требуется доступ к оружейной"
	cost = 1750
	access = ACCESS_HEADS
	contains = list(/obj/item/flamethrower/full,
					/obj/item/tank/internals/plasma,
					/obj/item/tank/internals/plasma,
					/obj/item/tank/internals/plasma,
					/obj/item/grenade/chem_grenade/incendiary,
					/obj/item/grenade/chem_grenade/incendiary,
					/obj/item/grenade/chem_grenade/incendiary,
					/obj/item/storage/box/fireshot)
	crate_name = "incendiary weapons crate"
	crate_type = /obj/structure/closet/crate/secure/plasma
	dangerous = TRUE

/datum/supply_pack/security/armory/miniguns
	name = "Personal Miniature Energy Guns"
	desc = "Содержит три миниатюрных энергетических пистолета. Имеется летальный и нелетальный режим. Для открытия требуется доступ к оружейной."
	cost = 3000
	contains = list(/obj/item/gun/energy/e_gun/mini,
					/obj/item/gun/energy/e_gun/mini,
					/obj/item/gun/energy/e_gun/mini)
	crate_name = "personal energy guns crate"
	crate_type = /obj/structure/closet/crate/secure/plasma

/datum/supply_pack/security/armory/riotarmor
	name = "Riot Armor Crate"
	desc = "Содержит три комплекта тяжелых бронежилетов. Усовершенствованная подкладка защищает от оружия ближнего боя, благодаря чему атаки кажутся носителю вполовину слабее. Для открытия требуется доступ к оружейной."
	cost = 1750
	contains = list(/obj/item/clothing/suit/armor/riot,
					/obj/item/clothing/suit/armor/riot,
					/obj/item/clothing/suit/armor/riot)
	crate_name = "riot armor crate"

/datum/supply_pack/security/armory/riothelmets
	name = "Riot Helmets Crate"
	desc = "Содержит три комплекта тяжелых шлемов. Для открытия требуется доступ к оружейной."
	cost = 1750
	contains = list(/obj/item/clothing/head/helmet/riot,
					/obj/item/clothing/head/helmet/riot,
					/obj/item/clothing/head/helmet/riot)
	crate_name = "riot helmets crate"

/datum/supply_pack/security/armory/riotshields
	name = "Riot Shields Crate"
	desc = "Содержит три тяжелых щита. Для открытия требуется доступ к оружейной."
	cost = 2200
	contains = list(/obj/item/shield/riot,
					/obj/item/shield/riot,
					/obj/item/shield/riot)
	crate_name = "riot shields crate"

/datum/supply_pack/security/armory/russian
	name = "Russian Surplus Crate"
	desc = "Здравствуйте, Товарищ , у нас есть самая современная российская военная техника, которую может предложить черный рынок, конечно, по правильной цене. К сожалению, мы не смогли снять замок, поэтому для его открытия требуется доступ в оружейную."
	cost = 7500
	contraband = TRUE
	contains = list(/obj/effect/spawner/lootdrop/mre = 3,
					/obj/item/clothing/suit/armor/vest/russian,
					/obj/item/clothing/suit/armor/vest/russian_coat,
					/obj/item/clothing/shoes/russian,
					/obj/item/clothing/gloves/tackler/combat/insulated,
					/obj/item/clothing/under/syndicate/rus_army,
					/obj/item/clothing/under/costume/soviet,
					/obj/item/clothing/mask/russian_balaclava,
					/obj/item/clothing/head/ushanka/soviet,
					/obj/item/clothing/head/ushanka/soviet,
					/obj/item/clothing/head/helmet/rus_helmet,
					/obj/effect/spawner/bundle/crate/mosin,
					/obj/effect/spawner/bundle/crate/surplusrifle,
					/obj/item/storage/toolbox/ammo,
					/obj/item/storage/toolbox/ammo/surplus)
	crate_name = "surplus military crate"
	crate_type = /obj/structure/closet/crate/secure/soviet

/datum/supply_pack/security/armory/russian/fill(obj/structure/closet/crate/C)
	for(var/i in 1 to 5)
		var/item = pick(contains)
		new item(C)

/datum/supply_pack/security/armory/frontier
	name = "Old West Surplus Crate"
	desc = "У вас есть проблемы с фауной? Вы хотите воплотить в жизнь свои фантазии о покорении границ на ультрасовременной станции по исследованию и добыче плазмы? Ты хочешь притвориться, что жил на Старом Западе земной славы? Что ж, эта коробка - и множество шляп в ней - возможно, для вас."
	cost = 7500
	contraband = TRUE
	contains = list(/obj/effect/spawner/bundle/crate/cowboyhat,
					/obj/effect/spawner/bundle/crate/cowboyboots,
					/obj/item/clothing/under/pants/chaps,
					/obj/item/reagent_containers/food/snacks/butterbiscuit,
					/obj/item/reagent_containers/food/snacks/butterbiscuit,
					/obj/item/reagent_containers/food/snacks/plumphelmetbiscuit,
					/obj/item/reagent_containers/food/snacks/plumphelmetbiscuit,
					/obj/item/ammo_box/c38/pouch,
					/obj/item/ammo_box/c38/pouch,
					/obj/item/ammo_box/c38/pouch,
					/obj/effect/spawner/bundle/crate/levergun
					)

/datum/supply_pack/security/armory/frontier/fill(obj/structure/closet/crate/C)
	for(var/i in 1 to 5)
		var/item = pick(contains)
		new item(C)

/datum/supply_pack/security/armory/swat
	name = "SWAT Crate"
	desc = "Содержит два полных комплекта прочных, огнеупорных герметичных костюмов, разработанных совместными усилиями IS-ERI и Nanotrasen. Каждый комплект содержит костюм, шлем, маску, боевой пояс, боевой нож и боевые перчатки. Для открытия требуется доступ к оружейной."
	cost = 9000
	contains = list(/obj/item/clothing/head/helmet/swat/nanotrasen,
					/obj/item/clothing/head/helmet/swat/nanotrasen,
					/obj/item/clothing/suit/space/swat,
					/obj/item/clothing/suit/space/swat,
					/obj/item/clothing/mask/gas/sechailer/swat,
					/obj/item/clothing/mask/gas/sechailer/swat,
					/obj/item/storage/belt/military/assault,
					/obj/item/storage/belt/military/assault,
					/obj/item/kitchen/knife/combat,
					/obj/item/kitchen/knife/combat,
					/obj/item/clothing/gloves/tackler/combat/insulated,
					/obj/item/clothing/gloves/tackler/combat/insulated)
	crate_name = "SWAT Crate"

/datum/supply_pack/security/armory/altyn_helmets
	name = "Altyn Helmets Crate"
	desc = "Содержит три специальных шлема типа 'АЛТЫН'. Для открытия требуется доступ к оружейной."
	cost = 1750
	contains = list(/obj/item/clothing/head/helmet/swat/nanotrasen/altyn,
					/obj/item/clothing/head/helmet/swat/nanotrasen/altyn,
					/obj/item/clothing/head/helmet/swat/nanotrasen/altyn)
	crate_name = "Altyn Helmets Crate"

/datum/supply_pack/security/armory/swat/updated_medsec
	name = "ERT Armor Crate | MedSec"
	desc = "Содержит два полных комплекта прочных костюмов, разработанных совместными усилиями Дочерних Компаний Синдиката и Nanotrasen. Каждый комплект содержит костюм, шлем, маску, боевой пояс, боевой нож и боевые перчатки. Для открытия требуется доступ к оружейной."
	cost = 6000
	contains = list(/obj/item/clothing/suit/armor/hos/security,
					/obj/item/clothing/suit/armor/hos/medical,
					/obj/item/clothing/head/helmet/swat/security,
					/obj/item/clothing/head/helmet/swat/medical,
					/obj/item/clothing/mask/gas/sechailer/swat,
					/obj/item/clothing/mask/gas/sechailer/swat,
					/obj/item/storage/belt/military/assault,
					/obj/item/storage/belt/military/assault,
					/obj/item/kitchen/knife/combat,
					/obj/item/kitchen/knife/combat,
					/obj/item/clothing/gloves/tackler/combat/insulated,
					/obj/item/clothing/gloves/tackler/combat/insulated)
	crate_name = "swat crate | MedSec"

/datum/supply_pack/security/armory/swat/updated_janeng
	name = "ERT Armor Crate | JanEng"
	desc = "Содержит два полных комплекта прочных костюмов, разработанных совместными усилиями Дочерних Компаний Синдиката и Nanotrasen. Каждый комплект содержит костюм, шлем, маску, боевой пояс, боевой нож и боевые перчатки. Для открытия требуется доступ к оружейной."
	cost = 6000
	contains = list(/obj/item/clothing/suit/armor/hos/engineer,
					/obj/item/clothing/suit/armor/hos/janitor,
					/obj/item/clothing/head/helmet/swat/engineer,
					/obj/item/clothing/head/helmet/swat/janitor,
					/obj/item/clothing/mask/gas/sechailer/swat,
					/obj/item/clothing/mask/gas/sechailer/swat,
					/obj/item/storage/belt/military/assault,
					/obj/item/storage/belt/military/assault,
					/obj/item/kitchen/knife/combat,
					/obj/item/kitchen/knife/combat,
					/obj/item/clothing/gloves/tackler/combat/insulated,
					/obj/item/clothing/gloves/tackler/combat/insulated)
	crate_name = "swat crate | JanEng"

/datum/supply_pack/security/armory/swat/updated_command
	name = "ERT Armor Crate | Command"
	desc = "Содержит два полных комплекта прочных костюмов, разработанных совместными усилиями Дочерних Компаний Синдиката и Nanotrasen. Каждый комплект содержит костюм, шлем, маску, боевой пояс, боевой нож и боевые перчатки. Для открытия требуется доступ к оружейной."
	cost = 6000
	contains = list(/obj/item/clothing/suit/armor/hos/command,
					/obj/item/clothing/suit/armor/hos/command,
					/obj/item/clothing/head/helmet/swat/command,
					/obj/item/clothing/head/helmet/swat/command,
					/obj/item/clothing/mask/gas/sechailer/swat,
					/obj/item/clothing/mask/gas/sechailer/swat,
					/obj/item/storage/belt/military/assault,
					/obj/item/storage/belt/military/assault,
					/obj/item/kitchen/knife/combat,
					/obj/item/kitchen/knife/combat,
					/obj/item/clothing/gloves/tackler/combat/insulated,
					/obj/item/clothing/gloves/tackler/combat/insulated)
	crate_name = "swat crate | Command"

/datum/supply_pack/security/armory/lasguns
	name = "Lasgun's Kit"
	desc = "Коробочка с автоматическими лазерными винтовками."
	cost = 6000
	contains = list(/obj/item/gun/ballistic/automatic/laser/lasgun,
					/obj/item/gun/ballistic/automatic/laser/lasgun)
	crate_name = "Lasgun's Kit"

/datum/supply_pack/security/armory/lasguns_ammo
	name = "Lasgun's Ammo Crate"
	desc = "Содержит четыре магазина на 32 патрона для полуавтоматического пистолета WT-550 SMG. Каждый магазин предназначен для быстрой тактической перезарядки. Для открытия требуется доступ к оружейной."
	cost = 3250
	contains = list(/obj/item/ammo_box/magazine/recharge/lasgun,
					/obj/item/ammo_box/magazine/recharge/lasgun,
					/obj/item/ammo_box/magazine/recharge/lasgun,
					/obj/item/ammo_box/magazine/recharge/lasgun)
	crate_name = "auto rifle ammo crate"

/datum/supply_pack/security/armory/wt550
	name = "WT-550 Semi-Auto Rifle Crate"
	desc = "Содержит две мощные полуавтоматические винтовки с калибром 4,6x30 мм. Для открытия требуется доступ к оружейной."
	cost = 6000
	contains = list(/obj/item/gun/ballistic/automatic/wt550,
					/obj/item/gun/ballistic/automatic/wt550)
	crate_name = "auto rifle crate"

/datum/supply_pack/security/armory/wt550ammo
	name = "WT-550 Semi-Auto SMG Ammo Crate"
	desc = "Содержит четыре магазина на 32 патрона для полуавтоматического пистолета WT-550 SMG. Каждый магазин предназначен для быстрой тактической перезарядки. Для открытия требуется доступ к оружейной."
	cost = 3250
	contains = list(/obj/item/ammo_box/magazine/wt550m9,
					/obj/item/ammo_box/magazine/wt550m9,
					/obj/item/ammo_box/magazine/wt550m9,
					/obj/item/ammo_box/magazine/wt550m9)
	crate_name = "auto rifle ammo crate"

/datum/supply_pack/security/armory/wt550ammo_nonlethal // Takes around 12 shots to stamcrit someone
	name = "WT-550 Semi-Auto SMG Non-Lethal Ammo Crate"
	desc = "Содержит четыре магазина на 32 нелеталных патрона для полуавтоматического пистолета WT-550 SMG. Каждый магазин предназначен для быстрой тактической перезарядки. Для открытия требуется доступ к оружейной."
	cost = 1000
	contains = list(/obj/item/ammo_box/magazine/wt550m9/wtrubber,
					/obj/item/ammo_box/magazine/wt550m9/wtrubber,
					/obj/item/ammo_box/magazine/wt550m9/wtrubber,
					/obj/item/ammo_box/magazine/wt550m9/wtrubber)
	crate_name = "auto rifle ammo crate"

/datum/supply_pack/security/armory/hell_single
	name = "Hellgun Single-Pack"
	crate_name = "hellgun crate"
	desc = "Содержит один Hellgun, старый образец лазерного ружья, печально известного своей способностью ужасно уродовать цели ожогами. Технически нарушает Космическую Женевскую конвенцию при использовании на гуманоидах."
	cost = 1500
	contains = list(/obj/item/gun/energy/laser/hellgun)

/datum/supply_pack/security/armory/derringerclassic
	name = "Holdout Crate"
	crate_name = "dented crate"
	desc = "Эй, пацан... иди сюда. Босс говорит, что мы должны выгрузить это любому покупателю, не задавая вопросов. Вы платите нам, мы даем вам три таких пистолета без каких-либо условий. Блокировки предназначены для того, чтобы гарантировать, что они попадут к платежеспособным клиентам."
	cost = 2000
	contraband = TRUE
	contains = list(/obj/item/storage/fancy/cigarettes/derringer/smuggled,
					/obj/item/storage/fancy/cigarettes/derringer/smuggled,
					/obj/item/storage/fancy/cigarettes/derringer/smuggled,
					/obj/item/storage/wallet)

/datum/supply_pack/security/armory/esoteric_arms
	name = "Esoteric Armory Shipment"
	desc = "Чтож.. вы человек со вкусом, это я точно могу сказать. За правильную цену.. мы могли бы ясно видеть наш путь, чтобы отправить вам одно из наших более... уникальных видов оружия."
	hidden = TRUE
	cost = 10000
	can_private_buy = TRUE
	crate_name = "dusty crate"
	var/num_contained = 1
	contains = list(/obj/item/gun/ballistic/shotgun/leveraction,
					/obj/item/storage/fancy/cigarettes/derringer/gold,
					/obj/item/gun/ballistic/revolver/nagant,
					/obj/item/gun/ballistic/automatic/pistol/APS,
					/obj/item/gun/ballistic/revolver/golden)

/datum/supply_pack/security/armory/esoteric_arms/fill(obj/structure/closet/crate/C)
	var/list/L = contains.Copy()
	for(var/i in 1 to num_contained)
		var/item = pick_n_take(L)
		new item(C)
