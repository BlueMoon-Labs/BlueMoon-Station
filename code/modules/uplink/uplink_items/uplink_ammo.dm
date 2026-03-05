
/*
	Uplink Items:
	Unlike categories, uplink item entries are automatically sorted alphabetically on server init in a global list,
	When adding new entries to the file, please keep them sorted by category.
*/

// Ammunition

/datum/uplink_item/ammo/derringer
	name = "Ammo Box - .45-70 GOVT"
	desc = "Содержит 10 дополнительных патронов .45-70 GOVT. Калибр крайне редкий, поэтому и цена соответствующая."
	item = /obj/item/ammo_box/g4570
	cost = 5
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/pistol
	name = "10mm Handgun Magazine"
	desc = "Дополнительный магазин на 8 патронов 10mm для пистолета Стечкин. Патроны дешёвые как грязь, но вдвое слабее .357."
	item = /obj/item/ammo_box/magazine/m10mm
	cost = 1
	purchasable_from = ~UPLINK_CLOWN_OPS

/datum/uplink_item/ammo/pistol/box
	name = "Ammo Box - 10mm"
	desc = "Дополнительная коробка патронов 10mm. В коробке 20 штук, магазин не прилагается."
	item = /obj/item/ammo_box/c10mm
	illegal_tech = FALSE

/datum/uplink_item/ammo/pistolap
	name = "10mm Armour Piercing Magazine"
	desc = "Дополнительный магазин на 8 бронебойных патронов 10mm для пистолета Стечкин. Хуже ранят, зато пробивают защиту."
	item = /obj/item/ammo_box/magazine/m10mm/ap
	cost = 2
	purchasable_from = ~UPLINK_CLOWN_OPS

/datum/uplink_item/ammo/pistolap/box
	name = "Ammo Box - 10mm Armour Piercing"
	desc = "Дополнительная коробка бронебойных патронов 10mm. В коробке 20 штук, магазин не прилагается."
	item = /obj/item/ammo_box/c10mm/ap
	illegal_tech = FALSE

/datum/uplink_item/ammo/pistolhp
	name = "10mm Hollow Point Magazine"
	desc = "Дополнительный магазин на 8 экспансивных патронов 10mm для пистолета Стечкин. Наносят больше урона, но бесполезны против брони."
	item = /obj/item/ammo_box/magazine/m10mm/hp
	cost = 3
	purchasable_from = ~UPLINK_CLOWN_OPS

/datum/uplink_item/ammo/pistolhp/box
	name = "Ammo Box - 10mm Hollow Point"
	desc = "Дополнительная коробка экспансивных патронов 10mm. В коробке 20 штук, магазин не прилагается."
	item = /obj/item/ammo_box/c10mm/hp
	illegal_tech = FALSE

/datum/uplink_item/ammo/pistolfire
	name = "10mm Incendiary Magazine"
	desc = "Дополнительный магазин на 8 зажигательных патронов 10mm для пистолета Стечкин. Урон небольшой, зато поджигают цель."
	item = /obj/item/ammo_box/magazine/m10mm/fire
	cost = 2
	purchasable_from = ~UPLINK_CLOWN_OPS

/datum/uplink_item/ammo/pistolfire/box
	name = "Ammo Box - 10mm Incendiary"
	desc = "Дополнительная коробка зажигательных патронов 10mm. В коробке 20 штук, магазин не прилагается."
	item = /obj/item/ammo_box/magazine/m10mm/fire
	illegal_tech = FALSE

/datum/uplink_item/ammo/pistolzzz
	name = "10mm Soporific Magazine"
	desc = "Дополнительный магазин на 8 усыпляющих патронов 10mm для пистолета Стечкин. Вырубают цель в сон. \
			ВНИМАНИЕ: усыпляющий эффект не мгновенный из-за ограничений калибра. Обычно нужно три попадания."
	item = /obj/item/ammo_box/magazine/m10mm/soporific
	cost = 2

/datum/uplink_item/ammo/pistolzzz/box
	name = "Ammo Box - 10mm Soporific"
	desc = "Дополнительная коробка усыпляющих патронов 10mm. В коробке 20 штук, магазин не прилагается."
	item = /obj/item/ammo_box/c10mm/soporific
	illegal_tech = FALSE

/datum/uplink_item/ammo/shotgun
	cost = 2
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/shotgun/bag
	name = "12g Ammo Duffel Bag"
	desc = "Спортивная сумка, набитая патронами 12g на целую команду, по сниженной цене."
	item = /obj/item/storage/backpack/duffelbag/syndie/ammo/shotgun
	cost = 12

/datum/uplink_item/ammo/shotgun/bioterror
	name = "12g Bioterror Dart Drum"
	desc = "Дополнительный барабан на 8 биотеррор-дротиков для дробовика Bulldog. \
			Пробивает броню и впрыскивает жуткий коктейль смерти в цель. Осторожнее с огнём по своим."
	cost = 6 //legacy price
	item = /obj/item/ammo_box/magazine/m12g/bioterror

/datum/uplink_item/ammo/shotgun/buck
	name = "12g Buckshot Drum"
	desc = "Дополнительный барабан на 8 картечных патронов для дробовика Bulldog. Этой стороной к противнику."
	item = /obj/item/ammo_box/magazine/m12g

/datum/uplink_item/ammo/shotgun/dragon
	name = "12g Dragon's Breath Drum"
	desc = "Альтернативный барабан на 8 зажигательных патронов Dragon's Breath для дробовика Bulldog. \
			Я поджигатель, чокнутый поджигатель!"
	item = /obj/item/ammo_box/magazine/m12g/dragon

/datum/uplink_item/ammo/shotgun/meteor
	name = "12g Meteorslug Shells"
	desc = "Альтернативный барабан на 8 метеорных снарядов для дробовика Bulldog. \
			Отлично выбивает шлюзы с петель и сбивает врагов с ног."
	item = /obj/item/ammo_box/magazine/m12g/meteor

/datum/uplink_item/ammo/shotgun/slug
	name = "12g Slug Drum"
	desc = "Дополнительный барабан на 8 пулевых патронов для дробовика Bulldog. \
			Теперь в 8 раз меньше шансов подстрелить своих."
	cost = 3
	item = /obj/item/ammo_box/magazine/m12g/slug

/datum/uplink_item/ammo/shotgun/stun
	name = "12g Stun Slug Drum"
	desc = "Альтернативный барабан на 8 оглушающих пулевых патронов для дробовика Bulldog. \
			Сказать, что они полностью нелетальные - было бы враньём."
	item = /obj/item/ammo_box/magazine/m12g/stun

/datum/uplink_item/ammo/revolver
	name = ".357 Speed Loader"
	desc = "Быстрозарядник на семь патронов .357 Magnum, можно дозарядить отдельными пулями. \
			Подходит для револьвера Syndicate. Когда действительно нужно, чтобы куча народу перестала шевелиться."
	item = /obj/item/ammo_box/a357
	cost = 3
	purchasable_from = ~UPLINK_CLOWN_OPS

/datum/uplink_item/ammo/revolver/ap
	name = ".357 Armor Piercing Speed Loader"
	desc = "Быстрозарядник на семь бронебойных патронов .357 AP Magnum для револьвера Syndicate. \
			Прошибает как горячий нож сквозь масло."
	item = /obj/item/ammo_box/a357/ap

/datum/uplink_item/ammo/revolver/dumdum
	name = ".357 DumDum Speed Loader"
	desc = "Быстрозарядник на семь разрывных патронов .357 DumDum Magnum для револьвера Syndicate. \
			Рви и кромсай."
	item = /obj/item/ammo_box/a357/dumdum

/datum/uplink_item/ammo/a40mm
	name = "40mm Grenade"
	desc = "Осколочно-фугасная граната 40mm для подствольного гранатомёта M-90gl. \
			Сокомандники попросят не стрелять ими в узких коридорах."
	item = /obj/item/ammo_casing/a40mm
	cost = 2
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/smg/bag
	name = ".45 Ammo Duffel Bag"
	desc = "Спортивная сумка, набитая патронами .45 на целую команду, по сниженной цене."
	item = /obj/item/storage/backpack/duffelbag/syndie/ammo/smg
	cost = 20 //instead of 27 TC
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/smg
	name = ".45 SMG Magazine"
	desc = "Дополнительный магазин на 24 патрона .45 для пистолета-пулемёта C-20r."
	item = /obj/item/ammo_box/magazine/smgm45
	cost = 3
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/sniper
	cost = 4
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/sniper/basic
	name = ".50 Magazine"
	desc = "Дополнительный стандартный магазин на 6 патронов .50 для снайперских винтовок."
	item = /obj/item/ammo_box/magazine/sniper_rounds

/datum/uplink_item/ammo/sniper/penetrator
	name = ".50 Penetrator Magazine"
	desc = "Магазин на 5 бронебойных патронов .50 для снайперских винтовок. \
			Пробивает стены и нескольких врагов насквозь."
	item = /obj/item/ammo_box/magazine/sniper_rounds/penetrator
	cost = 5

/datum/uplink_item/ammo/sniper/soporific
	name = ".50 Soporific Magazine"
	desc = "Магазин на 3 усыпляющих патрона .50 для снайперских винтовок. Усыпите своих врагов уже сегодня!"
	item = /obj/item/ammo_box/magazine/sniper_rounds/soporific
	cost = 6

/datum/uplink_item/ammo/carbine
	name = "5.56mm Toploader Magazine"
	desc = "Дополнительный магазин на 30 патронов 5.56mm для карабина M-90gl. \
			Бьют слабее 7.12x82mm, но всё равно мощнее .45."
	item = /obj/item/ammo_box/magazine/m556
	cost = 4
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/machinegun/match
	name = "7.12x82mm (Match) Box Magazine"
	desc = "Магазин на 50 матчевых патронов 7.12x82mm для пулемёта L6 SAW. Не знали, что на точные патроны \
			для пулемёта есть спрос? Эти пули идеально подогнаны и красиво рикошетят от стен."
	item = /obj/item/ammo_box/magazine/mm712x82/match
	cost = 10

/datum/uplink_item/ammo/machinegun
	cost = 6
	surplus = 0
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/machinegun/basic
	name = "7.12x82mm Box Magazine"
	desc = "Магазин на 50 патронов 7.12x82mm для пулемёта L6 SAW. \
			К моменту, когда он понадобится, вы уже будете стоять на горе трупов."
	item = /obj/item/ammo_box/magazine/mm712x82

/datum/uplink_item/ammo/machinegun/ap
	name = "7.12x82mm (Armor Penetrating) Box Magazine"
	desc = "Магазин на 50 бронебойных патронов 7.12x82mm для пулемёта L6 SAW. \
			Пробивают даже самую крепкую броню."
	item = /obj/item/ammo_box/magazine/mm712x82/ap
	cost = 9

/datum/uplink_item/ammo/machinegun/hollow
	name = "7.12x82mm (Hollow-Point) Box Magazine"
	desc = "Магазин на 50 экспансивных патронов 7.12x82mm для пулемёта L6 SAW. \
			Отлично справляются с небронированными толпами экипажа."
	item = /obj/item/ammo_box/magazine/mm712x82/hollow

/datum/uplink_item/ammo/machinegun/incen
	name = "7.12x82mm (Incendiary) Box Magazine"
	desc = "Магазин на 50 зажигательных патронов 7.12x82mm для пулемёта L6 SAW. \
			Поджигают каждого, в кого попадут. Некоторые просто хотят смотреть, как мир горит."
	item = /obj/item/ammo_box/magazine/mm712x82/incen

/datum/uplink_item/ammo/rocket
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/rocket/basic
	name = "84mm HE Rocket"
	desc = "Маломощная осколочная ракета 84mm. Отправим вас на тот свет со стилем!"
	item = /obj/item/ammo_casing/caseless/rocket
	cost = 4

/datum/uplink_item/ammo/rocket/hedp
	name = "84mm HEDP Rocket"
	desc = "Мощная кумулятивно-осколочная ракета 84mm HEDP. Крайне эффективна против бронированных целей \
			и всех, кто стоит рядом. Вселяйте страх в сердца врагов."
	item = /obj/item/ammo_casing/caseless/rocket/hedp
	cost = 6

/datum/uplink_item/ammo/pistolaps
	name = "9mm Handgun Magazine"
	desc = "Дополнительный магазин на 15 патронов 9mm для пистолета Стечкин АПС."
	item = /obj/item/ammo_box/magazine/pistolm9mm
	cost = 2
	purchasable_from = ~UPLINK_CLOWN_OPS

/datum/uplink_item/ammo/pistolaps
	name = "Ammo Box - 9mm"
	desc = "Дополнительная коробка патронов 9mm. В коробке 30 штук, магазин не прилагается."
	item = /obj/item/ammo_box/c9mm
	illegal_tech = FALSE

/datum/uplink_item/ammo/flechetteap
	name = "Armor Piercing Flechette Magazine"
	desc = "Дополнительный магазин на 40 флешетт для установки Flechette. \
			Бронебойные флешетты почти игнорируют броню, но слабо действуют по плоти."
	item = /obj/item/ammo_box/magazine/flechette
	cost = 2
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/flechettes
	name = "Serrated Flechette Magazine"
	desc = "Дополнительный магазин на 40 флешетт для установки Flechette. \
			Зазубренные флешетты кромсают плоть, но намертво застревают в броне. \
			С высокой вероятностью рассекают артерии и даже отрубают конечности."
	item = /obj/item/ammo_box/magazine/flechette/s
	cost = 2
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/toydarts
	name = "Box of Riot Darts"
	desc = "Коробка из 40 бунтовых дротиков Donksoft для перезарядки совместимых магазинов. Не забудьте поделиться!"
	item = /obj/item/ammo_box/foambox/riot
	cost = 2
	surplus = 0
	illegal_tech = FALSE

/datum/uplink_item/ammo/bioterror
	name = "Box of Bioterror Syringes"
	desc = "Коробка предзаряженных шприцов с химикатами, которые блокируют моторные и речевые \
			функции жертвы, лишая её возможности двигаться и говорить на некоторое время."
	item = /obj/item/storage/box/syndie_kit/bioterror
	cost = 6
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/ammo/bolt_action
	name = "Surplus Rifle Clip"
	desc = "Обойма для быстрой зарядки винтовок с продольно-скользящим затвором. Содержит 5 патронов."
	item = /obj/item/ammo_box/a762
	cost = 1
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/bolt_action_bulk
	name = "Surplus Rifle Clip Box"
	desc = "Ящик с патронами, найденный на складе. Содержит 7 обойм по 5 патронов для винтовок с затвором. Да, тех самых дешёвых."
	item = /obj/item/storage/toolbox/ammo
	cost = 4
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/ammo/dark_gygax/bag
	name = "Dark Gygax Ammo Bag"
	desc = "Спортивная сумка с боеприпасами на три полных перезарядки зажигательного карабина и светошумовой пусковой установки экзоскелета Dark Gygax."
	item = /obj/item/storage/backpack/duffelbag/syndie/ammo/dark_gygax
	cost = 4
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/ammo/mauler/bag
	name = "Mauler Ammo Bag"
	desc = "Спортивная сумка с боеприпасами на три полных перезарядки пулемёта, картечного карабина и ракетной установки SRM-8 экзоскелета Mauler."
	item = /obj/item/storage/backpack/duffelbag/syndie/ammo/mauler
	cost = 6
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/ammo/hermes/bag
	name = "Hermes Ammo Bag"
	desc = "Спортивная сумка с боеприпасами на три полных перезарядки зажигательного карабина и светошумовой пусковой установки, установленных на стандартном экзоскелете Hermes."
	item = /obj/item/storage/backpack/duffelbag/syndie/inteq/ammo/hermes
	cost = 4
	purchasable_from = UPLINK_NUKE_OPS

/datum/uplink_item/ammo/ares/bag
	name = "Ares Ammo Bag"
	desc = "Спортивная сумка с боеприпасами на три полных перезарядки пулемёта, дробовой винтовки и ракетной установки SRM-8, установленных на стандартном экзоскелете Ares."
	item = /obj/item/storage/backpack/duffelbag/syndie/inteq/ammo/ares
	cost = 6
	purchasable_from = UPLINK_NUKE_OPS
