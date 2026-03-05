
/*
	Uplink Items:
	Unlike categories, uplink item entries are automatically sorted alphabetically on server init in a global list,
	When adding new entries to the file, please keep them sorted by category.
*/

//Space Suits and Hardsuits

/datum/uplink_item/suits/turtlenck
	name = "Brown Tactical Turtleneck"
	desc = "Слегка бронированный комбинезон без датчиков. Если кто-то увидит вас в нём — остаётся лишь надеяться, что они примут его за подделку."
	item = /obj/item/clothing/under/inteq
	cost = 1
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/suits/turtlenck_skirt
	name = "Brown Tactical Skirtleneck"
	desc = "Слегка бронированный комбинезон без датчиков. Если кто-то увидит вас в нём — остаётся лишь надеяться, что они примут его за подделку."
	item = /obj/item/clothing/under/inteq/skirt
	cost = 1
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE)

/datum/uplink_item/suits/padding
	name = "Soft Padding"
	desc = "Неприметная мягкая подкладка, носимая под комбинезоном. Смягчает удары в ближнем бою."
	item = /obj/item/clothing/accessory/padding
	cost = 1
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/suits/kevlar
	name = "Kevlar Padding"
	desc = "Неприметная кевларовая подкладка, носимая под комбинезоном. Защищает от баллистического урона."
	item = /obj/item/clothing/accessory/kevlar
	cost = 1
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/suits/plastic
	name = "Ablative Padding"
	desc = "Неприметная аблятивная подкладка, носимая под комбинезоном. Защищает от энергетических лазеров."
	item = /obj/item/clothing/accessory/plastics
	cost = 1
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/suits/space_suit
	name = "Syndicate Space Suit"
	desc = "Красно-чёрный скафандр Syndicate — менее громоздкий чем аналоги Nanotrasen, \
			влезает в сумки и имеет слот для оружия. Правда, персонал Nanotrasen обучен \
			сообщать о красных скафандрах."
	item = /obj/item/storage/box/syndie_kit/space
	cost = 4
	purchasable_from = ~(UPLINK_TRAITORS | UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/suits/hardsuit
	name = "Syndicate Hardsuit"
	desc = "Наводящий ужас скафандр ядерного агента Syndicate. Улучшенная броня и встроенный джетпак, \
			работающий на стандартных атмосферных баллонах. Переключение режима боя \
			позволяет сохранять мобильность без потери брони. Складывается и влезает в рюкзак. \
			Экипаж Nanotrasen паникует при виде этих скафандров."
	item = /obj/item/clothing/suit/space/hardsuit/syndi
	cost = 6
	purchasable_from = ~(UPLINK_TRAITORS | UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS) //you can't buy it in nuke, because the elite hardsuit costs the same while being better

/datum/uplink_item/suits/chameleon_hardsuit
	name = "Chameleon Hardsuit"
	desc = "Скафандр высшего класса, разработанный совместно Cybersun Industries и Gorlex Marauders, \
	фаворит контрактников Syndicate. Встроенная система хамелеона позволяет маскировать скафандр под самые \
	распространённые варианты в зоне операции. Этот замаскирован под инженерный скафандр."
	cost = 10 //reskinned blood-red hardsuit with chameleon
	item = /obj/item/storage/box/inteq_kit/chameleon_hardsuit

/datum/uplink_item/suits/hardsuit/elite
	name = "Elite Syndicate Hardsuit"
	desc = "Улучшенная элитная версия скафандра Syndicate. Огнеупорный, с превосходной бронёй \
			и мобильностью по сравнению со стандартным."
	item = /obj/item/clothing/suit/space/hardsuit/syndi/elite
	cost = 8
	purchasable_from = ~(UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/suits/hardsuit/shielded
	name = "Shielded Syndicate Hardsuit"
	desc = "Улучшенный скафандр Syndicate со встроенной системой энергетических щитов. \
			Щиты выдерживают до четырёх попаданий за короткое время и быстро восстанавливаются вне боя."
	item = /obj/item/clothing/suit/space/hardsuit/shielded/syndi
	cost = 30
	purchasable_from = ~(UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/suits/thiefgloves
	name = "Thieving Gloves"
	desc = "Изолированные и нескользящие перчатки, позволяющие легко обворовывать кого угодно."
	item = /obj/item/clothing/gloves/thief
	cost = 4

/datum/uplink_item/suits/wallwalkers
	name = "Wall Walking Boots"
	desc = "Благодаря украденной блюспейс-магии эти ботинки позволяют проскальзывать сквозь атомы чего угодно, \
			но только при ходьбе — для безопасности. К сожалению, вызывают незначительную потерю дыхания, \
			так как большая часть атомов из лёгких высасывается в твёрдые объекты."
	item = /obj/item/clothing/shoes/wallwalkers
	cost = 6
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/device_tools/guerrillagloves
	name = "Guerrilla Gloves"
	desc = "Крайне прочные боевые перчатки-хваталки, отличные для ближних захватов, с изоляционной подкладкой. Осторожно — не врежьтесь в стену!"
	item = /obj/item/clothing/gloves/tackler/combat/insulated
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS
	cost = 2

/datum/uplink_item/device_tools/syndicate_eyepatch
	name = "Mechanical Eyepatch"
	desc = "Повязка на глаз, подключающаяся к глазнице и невероятно улучшающая меткость — пули рикошетят гораздо чаще."
	item = /obj/item/clothing/glasses/eyepatch/syndicate
	cost = 4

/datum/uplink_item/device_tools/ablative_armwraps
	name = "Ablative Armwraps"
	desc = "Усиленные наручи, позволяющие парировать почти всё. Полностью отражают снаряды, нет штрафа за промах, но парировать ближний бой очень сложно."
	cost = 6
	item = /obj/item/clothing/gloves/fingerless/ablative
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)
