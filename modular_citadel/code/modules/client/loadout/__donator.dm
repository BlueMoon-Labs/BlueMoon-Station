//This is the file that handles donator loadout items.

/datum/gear/donator
	name = "Golden Horn!"
	description = "Золото? Ясно — сделано из банания! Хонк!"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bikehorn/golden
	category = LOADOUT_CATEGORY_DONATOR
	subcategory = LOADOUT_SUBCATEGORIES_DON01
	donator_group_id = DONATOR_GROUP_TIER_1
	ckeywhitelist = list()

//////////////////////// DONATOR_GROUP_TIER_2 ////////////////////////
/datum/gear/donator/t2
	name = null
	donator_group_id = DONATOR_GROUP_TIER_2
	subcategory = LOADOUT_SUBCATEGORIES_DON02

/datum/gear/donator/t2/syndicate_id_civilian
	name = "Civilian Syndicate Card"
	description = "Гражданская карта Синдиката с одноразовым разрешением на доступ."
	path = /obj/item/card/id/syndicate/one_access_copy/loadout
	cost = 2

/datum/gear/donator/t2/maskscream
	name = "Mask Scream"
	description = "Кричащая маска. ЧУВАААААК."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/screammask

/datum/gear/donator/t2/summon_pie
	name = "Book: Summon Pie"
	description = "Книга, которая ощущается тёплой. Позволяет вызывать кремовые пироги."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/book/granter/spell/summon_pie
	cost = 6

/datum/gear/donator/t2/syndicate_duffel
	name = "Syndicate Duffel Bag"
	description = "Большая сумка-мешок для дополнительного тактического снаряжения."
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/duffelbag/syndie
	cost = 6

/datum/gear/donator/t2/foam_lmg
	name = "Foam LMG"
	description = "Сильно модифицированный лёгкий пулемёт 7,12×82 мм под обозначением «L6 SAW». На ствольной коробке под обозначением выгравировано «Aussec Armoury — 2531»."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/gun/ballistic/automatic/l6_saw/toy/unrestricted/riot
	cost = 6

/datum/gear/donator/t2/foam_lmg_ammo
	name = "Foam LMG Ammo"
	description = "Коробка патронов."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/ammo_box/magazine/toy/m762/riot
	cost = 2

/datum/gear/donator/t2/money
	name = "Тысяча Денег (красивое)"
	description = "Пачка наличных номиналом тысяча кредитов."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/stack/spacecash/c1000

/datum/gear/donator/t2/chameleon_kit
	name = "Chameleon Box"
	path = /obj/item/storage/box/syndie_kit/chameleon
	cost = 8
	description = "Хамелеон-набор с именным разрешением на владение и использование."
	handle_post_equip = TRUE

/datum/gear/donator/t2/chameleon_kit/on_spawn(mob/user, obj/item/I)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/wearer = user
	// Если форму нельзя использовать для крепления, разрешение остаётся внутри выданной коробки.
	var/obj/item/clothing/accessory/permit/special/chameleon/permit = new(I)
	permit.bind_to_user(wearer, TRUE)
	var/obj/item/clothing/uniform = wearer.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	if(istype(uniform))
		uniform.attach_accessory(permit, wearer, TRUE)

/datum/gear/donator/t2/jukebox_mega
	name = "Personal Music Box"
	description = "Переносная музыкальная шкатулка."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/personal_music_box
	cost = 4

////////////////////////////////////////////////////////////////////////


/datum/gear/donator/backpack/penetrator
	name = "The Penetrator"
	description = "Абсурд секс-игрушки со смертоносностью бейсбольной биты."
	path = /obj/item/dildo/flared/huge

/datum/gear/donator/deskbox
	name = "Desk Box"
	description = "Содержит настольные игрушки. Просто!"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/box/desk

/datum/gear/donator/cleanercloak
	name = "Teshari Cleaner Cloak"
	description = "Для самой чистой тешари на станции."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/cleanercloak

/datum/gear/donator/fishingcloak
	name = "Teshari Fishing Cloak"
	description = "Для самой удачливой тешари, которая может рыбачить даже в туалете."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/fishingcloak

/datum/gear/donator/gamercloak
	name = "Teshari Gamer Cloack"
	description = "Для тешари, которые любят играть в игры."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/gamercloak

/datum/gear/donator/minercloak
	name = "Teshari Miner Cloack"
	description = "Для самых бэддаских тешари, которые не боятся убивать мегафауну."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/minercloak

/datum/gear/donator/smithingcloak
	name = "Teshari Smithing Cloak"
	description = "Для тешари, которые умеют обращаться с молотом и сталью."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/smithingcloak

/datum/gear/donator/productioncloak
	name = "Teshari Production Cloak"
	description = "Для самых продуктивных и быстрых тешари-работяг, которые знают, как решить любую проблему."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/productioncloak

/datum/gear/donator/playercloak
	name = "Teshari Player Cloak"
	description = "Для самых стильных тешари, которые хотят «вкусить радугу»."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/playercloak

/datum/gear/donator/pet
	name = "Pet Beacon"
	description = "Эй, почему ты это смотришь?!! Пожалуйста, сообщи в Centcom об этом странном случае."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet

/datum/gear/donator/rationpack
	name = "Ration Pack"
	description = "Упаковка с едой в блюспейс-кармане. При выдаче подбирается случайное меню из линейки NT (1–4)."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/mre/random_safe

/datum/gear/donator/rawk_satchel
	name = "Rawk Satchel"
	description = "Тактическая сумка для группы специального назначения."
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/satchel/rawk

/datum/gear/donator/gasmask_syndicate
	name = "The Syndicate Mask"
	description = "Плотно прилегающая тактическая маска, которую можно подключить к источнику воздуха."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate

/datum/gear/donator/jukebox
	name = "Handled Jukebox"
	description = "Переносная колонка для крутых."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/jukebox
	cost = 4

/datum/gear/donator/horny_stamp
	name = "horny active rubber stamp"
	description = "Резиновый штамп для важных документов."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/stamp/horny
	cost = 1

/datum/gear/donator/cat_stamp
	name = "cat approved rubber stamp"
	description = "Резиновый штамп для важных документов."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/stamp/cat
	cost = 1

/datum/gear/donator/pepe_stamp
	name = "Pepe rubber stamp"
	description = "Резиновый штамп для важных документов."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/stamp/pepe
	cost = 1

/datum/gear/donator/purple_zippo
	name = "Purple Zippo"
	description = "Всё космическое ремесло здесь высочайшего качества. Инкрустировано очищенными плазменными пластинами. На изделии изображён гном, а сбоку выцарапано: «Strike the Earth!»"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/lighter/purple
	cost = 1

/datum/gear/donator/neck_gaiter
	name = "The Neck Gaiter"
	description = "Для агента, который хочет остаться незамеченным и при этом скрыть личность. Есть маленький респиратор для подключения к внутреннему источнику воздуха."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/sechailer/syndicate

/datum/gear/donator/pseudo_euclidean_tennis_sphere
	name = "Pseudo-Euclidean Interdimensional Tennis Sphere"
	description = "Теннисный мяч из другого измерения. Очень клёвый."
	slot = ITEM_SLOT_MASK
	path = /obj/item/toy/fluff/tennis_poly/tri/squeak/rainbow

/datum/gear/donator/caligram
	name = "Caligram's Tactical Turtleneck"
	description = "С костюмом, подшитым таким количеством карманов, ты готов к работе."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/caligram

/datum/gear/donator/syndicate
	name = "Syndicate's Tactical Turtleneck"
	description = "Неприметная и слегка подозрительная водолазка с цифровым камуфляжом и грузовыми брюками."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate

/datum/gear/donator/syndicate_skirt
	name = "Syndicate's Tactical Skirtleneck"
	description = "Неприметная и слегка подозрительная юбка-водолазка."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/skirt

/datum/gear/donator/syndicate_maid
	name = "Syndicate's Tactical Maid Outfit"
	description = "«Тактическая» юбка-водолазка, сделанная под подобие формы горничной. Зачем у Синдиката такое — тебе никогда не узнать."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/maid

/datum/gear/donator/syndicate_overalls
	name = "Utility Overalls Turtleneck"
	description = "Пара нарядных комбинезонов с водолазкой внизу — одинаково полезны и в инженерии, и в ботанике."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/overalls

/datum/gear/donator/syndicate_overalls_skirt
	name = "Utility Overalls Skirtleneck"
	description = "Пара нарядных комбинезонов с водолазкой внизу, только вместо брюк юбка — дышится легко."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/overalls/skirt

/datum/gear/donator/carpet
	name = "Carpet Beacon"
	description = "Подумай как следует, чего ты хочешь, а потом оторви это!"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/box/carpet

/datum/gear/donator/chameleon_bedsheet
	name = "Chameleon Bedsheet"
	description = "Удивительно мягкая льняная простыня."
	slot = ITEM_SLOT_NECK
	path = /obj/item/bedsheet/chameleon

/datum/gear/donator/donortestingbikehorn
	name = "Donor item testing bikehorn"
	description = "Рог от велосипеда."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bikehorn
	geargroupID = list("DONORTEST") //This is a list mainly for the sake of testing, but geargroupID works just fine with ordinary strings

/datum/gear/donator/kevhorn
	name = "Airhorn"
	description = "Чёрт возьми, приятель, где ты это нашёл?"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bikehorn/airhorn

/datum/gear/donator/kiaracloak
	name = "Kiara's cloak"
	description = "Рисунок на этом выглядит слишком знакомым."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/inferno

/datum/gear/donator/kiaracollar
	name = "Kiara's collar"
	description = "Мягкий чёрный ошейник, который, кажется, растягивается под любого владельца."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/petcollar/inferno

/datum/gear/donator/kiaramedal
	name = "Insignia of Steele"
	description = "Изысканный кулон, который дарят тем, кто помог важной персоне из корпорации Steele."
	slot = ITEM_SLOT_ACCESSORY
	path = /obj/item/clothing/accessory/medal/steele
	handle_post_equip = TRUE

/datum/gear/donator/hheart
	name = "The Hollow Heart"
	description = "Иногда что-то слишком невозможно скрыть."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/hheart

/datum/gear/donator/engravedzippo
	name = "Engraved zippo"
	description = "Блестящая и довольно дорогая зажигалка Zippo. На дне выцарапано четверостишие: «Ни богов, ни хозяев — только человек»."
	slot = ITEM_SLOT_HANDS
	path = /obj/item/lighter/gold

/datum/gear/donator/geisha
	name = "Geisha suit"
	description = "Милый космический ниндзя-сэмпай не включён."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/costume/geisha

/datum/gear/donator/specialscarf
	name = "Special scarf"
	description = "Модный ошейник"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/scarf/zomb

/datum/gear/donator/redmadcoat
	name = "The Mad's labcoat"
	description = "Странно особенное пальто."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/toggle/labcoat/mad/red

/datum/gear/donator/santahat
	name = "Santa hat"
	description = "В первый день Рождества мой работодатель подарил мне! — От Владика с салатом"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/santa/fluff

/datum/gear/donator/reindeerhat
	name = "Reindeer hat"
	description = "Фальшивые оленьи рога и очень фальшивый красный нос — спонсор PWR Game(tm)"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/hardhat/reindeer/fluff

/datum/gear/donator/treeplushie
	name = "Christmas tree plushie"
	description = "Праздничный плюшевый зверь, который пищит, если его сжать!"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/tree

/datum/gear/donator/santaoutfit
	name = "Santa costume"
	description = "Празднично!"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/space/santa/fluff

/datum/gear/donator/treecloak
	name = "Christmas tree cloak"
	description = "Наверное, защитит от снега, угольков или эльфов."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/festive

/datum/gear/donator/carrotplush
	name = "Carrot plushie"
	description = "Обычная морковь полезна для глаз, но эта, похоже, больше подходит для обнимашек, чем для еды."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/carrot

/datum/gear/donator/carrotcloak
	name = "Carrot cloak"
	description = "Плащ в форме и цвете морковки!"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/carrot

/datum/gear/donator/albortorosamask
	name = "Alborto Rosa mask"
	description = "Носят крепкие бойцы, взмывающие ввысь, чтобы победить врагов!"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/luchador/

/datum/gear/donator/mankini
	name = "Mankini"
	description = "Розовый манкини — очень смелый наряд."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/misc/stripper/mankini

/datum/gear/donator/pinkshoes
	name = "Pink shoes"
	description = "Удобно выглядящая обувь."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/sneakers/pink

/datum/gear/donator/reecesgreatcoat
	name = "Reece's Great Coat"
	description = "Ты бы поклялся, что видел это в кошмарах после слишком большого количества овощей."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/trenchcoat/green

/datum/gear/donator/russianflask
	name = "Russian flask"
	description = "Каждый хороший русский космонавт знает: всегда стоит взять с собой пару пинт виски."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/reagent_containers/food/drinks/flask/russian
	cost = 2

/datum/gear/donator/stalkermask
	name = "S.T.A.L.K.E.R. mask"
	description = "Пахнет четвёртым реактором."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/stalker

/datum/gear/donator/cybersun
	name = "Cybersun mask"
	description = "Модная полумаска в брендовых цветах компании Киберсан. Поговаривают, такие продают как сувенир на далёких научных станциях."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/sechailer/syndicate/cybersun

/datum/gear/donator/stripedcollar
	name = "Striped collar"
	description = "Это для питомцев. Хоть ты и сам мог бы это надеть, но неизбежно стал бы посмешищем. Похоже, сделано из полихромного материала."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/petcollar/stripe

/datum/gear/donator/performersoutfit
	name = "Bluish performer's outfit"
	description = "От одного вида этого хочется петь."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/costume/singer/yellow/custom

/datum/gear/donator/vermillion
	name = "Vermillion clothing"
	description = "Некая одежда."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/suit/vermillion

/datum/gear/donator/AM4B
	name = "Foam Force AM4-B"
	description = "Реликвия ушедшей эпохи. Никто толком не знает, зачем она здесь. Покрыта полихромным слоем."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/gun/ballistic/automatic/AM4B

/datum/gear/donator/carrotsatchel
	name = "Carrot Satchel"
	description = "Сумка-сачок, сделанная так, чтобы выглядеть как морковка."
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/satchel/carrot

/datum/gear/donator/naomisweater
	name = "worn black sweater"
	description = "Любимый свитер, на котором видны следы нескольких стирок и перешивок. И несколько пятен. Это шерсть кошки?"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/sweater/black/naomi

/datum/gear/donator/naomicollar
	name = "worn pet collar"
	description = "Ошейник для питомца, который выглядит сильно поношенным."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/petcollar/naomi

/datum/gear/donator/gladiator
	name = "Gladiator Armor"
	description = "Разве ты не развлекаешься? Разве не ради этого ты здесь?"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/costume/gladiator

/datum/gear/donator/bloodredtie
	name = "Blood Red Tie"
	description = "Неосилковый галстук-клипса. У этого на кончике чёрная буква S — выглядит довольно уникально."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/tie/bloodred

/datum/gear/donator/puffydress
	name = "Puffy Dress"
	description = "Парадное пышное чёрно-красное викторианское платье."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/puffydress

/datum/gear/donator/labredblack
	name = "Black and Red Coat"
	description = "Странно особенное пальто."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/toggle/labcoat/labredblack

/datum/gear/donator/torisword
	name = "Rainbow Zweihander"
	description = "Самодельная игрушка со стильными радужными огнями."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/dualsaber/hypereutactic/toy/rainbow

/datum/gear/donator/darksabre
	name = "Dark Sabre"
	description = "Это лезвие выглядит таким же опасным, как его владелец."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/darksabre

/datum/gear/donator/darksabresheath
	name = "Dark Sabre Sheath"
	description = "Украшенные и довольно зловещие ножны для сабли."
	slot = ITEM_SLOT_BELT
	path = /obj/item/storage/belt/sabre/darksabre

/datum/gear/donator/toriball
	name = "Rainbow Tennis Ball"
	description = "Теннисный мяч из другого измерения. Очень клёвый."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/fluff/tennis_poly/tri/squeak/rainbow

/datum/gear/donator/izzyball
	name = "Katlin's Ball"
	description = "Трёхцветный полихромный теннисный мяч. Похоже, он пищит, если его сжать."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/fluff/tennis_poly/tri/squeak/izzy

/datum/gear/donator/cloak
	name = "Green Cloak"
	description = "Этот плащ не кажется особенно особенным."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/green

/datum/gear/donator/steelflask
	name = "Steel Flask"
	description = "Простая стальная фляга, запертая на замок и ключ. На лицевой стороне выгравировано «Конец»."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/reagent_containers/food/drinks/flask/steel
	cost = 2

/datum/gear/donator/paperhat
	name = "Paper Hat"
	description = "Листок бумаги, сложенный в аккуратную маленькую шапочку."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/paperhat
	// BLUEMOON EDIT START - иконки лодаута
	item_icon = 'icons/obj/clothing/hats.dmi'
	item_icon_state = "paper"
	// BLUEMOON EDIT END

/datum/gear/donator/cloakce
	name = "Polychromic CE Cloak"
	description = "Нарядный плащ, вышитый полихромной нитью в узоре, напоминающем о владельцах неограниченной власти."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/cloak/polychromic/polyce
	loadout_flags = LOADOUT_CAN_COLOR_POLYCHROMIC
	loadout_initial_colors = list("#808080", "#8CC6FF", "#FF3535")

/datum/gear/donator/ssk
	name = "Stun Sword Kit"
	description = "Набор для переделки электродубинки в электромеч."
	slot = ITEM_SLOT_BACKPACK
	path = 	/obj/item/ssword_kit

/datum/gear/donator/techcoat
	name = "Techomancers Labcoat"
	description = "Странно особенное пальто."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/toggle/labcoat/mad/techcoat

/datum/gear/donator/leechjar
	name = "Jar of Leeches"
	description = "Сомнительное лекарство от всего. Пробка, кажется, запечатана довольно хорошо, а стекло невозможно разбить."
	slot = ITEM_SLOT_BACKPACK
	path = 	/obj/item/custom/leechjar

/datum/gear/donator/darkarmor
	name = "Dark Armor"
	description = "Тёмный нефункциональный кусок брони с красно-чёрной отделкой."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/armor/vest/darkcarapace

/datum/gear/donator/devilwings
	name = "Strange Wings"
	description = "Эти странные крылья будто когда-то к чему-то крепились... или к кому-то...? Как бы то ни было, их присутствие вызывает беспокойство.."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/devilwings

/datum/gear/donator/flagcape
	name = "US Flag Cape"
	description = "По-настоящему патриотичный наряд героя."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/flagcape

/datum/gear/donator/luckyjack
	name = "Lucky Jackboots"
	description = "Удобные удачливые кирзовые сапоги со словом «Удача» на них."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/shoes/jackboots/lucky

/datum/gear/donator/m41
	name = "Toy M41"
	description = "Игрушечная копия штатной винтовки корпоративных наёмников. На боку написано «Для Автомата»."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/gun/m41

/datum/gear/donator/Divine_robes
	name = "Divine robes"
	description = "Небесные одежды kitsune Luna Pumpkin — ты чувствуешь исходящее от них сияние."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/custom/lunasune

/datum/gear/donator/gothcoat
	name = "Goth Coat"
	description = "Идеально для тех, кто любит отсиживаться в углу бара."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/gothcoat

/datum/gear/donator/corgisuit
	name = "Corgi Suit"
	description = "Костюм корги с капюшоном."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/hooded/ian_costume

/datum/gear/donator/sharkcloth
	name = "Leon's Skimpy Outfit"
	description = "Довольно откровенный наряд."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/custom/leoskimpy

/datum/gear/donator/mimemask
	name = "Mime Mask"
	description = "Традиционная маска мима. У неё жуткое выражение лица."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/mime

/datum/gear/donator/mimeoveralls
	name = "Mime's Overalls"
	description = "Не совсем традиционный наряд мима, дополненный парой комбинезонов, которые выглядят нелепо."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/custom/mimeoveralls

/datum/gear/donator/soulneck
	name = "Soul Necklace"
	description = "Медальон в форме сердца... На лицевой стороне выгравировано имя: «Зандер Сильфен». Что-то в этом ожерелье наполняет тебя решимостью."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/undertale

/datum/gear/donator/frenchberet
	name = "French Beret"
	description = "Качественный берет, пропитанный ароматом цепочек, курильщиков и любителей вина парижан. Почему-то меньше хочется ввязываться в боевые действия."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/frenchberet

/datum/gear/donator/zuliecloak
	name = "Project: Zul-E"
	description = "Стандартная версия прототипа плаща, который раздают верхушки NanoTrasen. Удивительно плотный и тяжёлый для плаща, хотя большая часть техники вырезана. В комплекте блюспейс-брелок, который призывает на владельца соответствующую шапку. Потёртая надпись внутри гласит «Fleuret»... остальное выцвело."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/hooded/cloak/zuliecloak

/datum/gear/donator/blackredgold
	name = "Black, Red, and Gold Coat"
	description = "Странно особенное пальто с чёрным, красным и золотым."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/blackredgold

/datum/gear/donator/kimono
	name = "Kimono"
	description = "Традиционное кимоно, это — голубое с фиолетовыми цветами."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/kimono

/datum/gear/donator/commjacket
	name = "Dusty Commisar's Cloak"
	description = "Пальто имперского комиссара, прямо с передовой, пропитанное грязью, с пулевыми отверстиями и десятками маленьких карманов. Удивительный золотой орёл на левой груди и надпись «200-й Веноланд» на внутренней подкладке хорошо видны. И всё же оно производит внушительное впечатление."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/commjacket

/datum/gear/donator/mw2_russian_para
	name = "Russian Paratrooper Jumper"
	description = "Старый российский парашютный комбинезон, с множеством карманов для удобного хранения снаряжения прошлой эпохи. Сколько он ни выглядит громоздким — удивительно лёгкий!"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/custom/mw2_russian_para

/datum/gear/donator/longblackgloves
	name = "Luna's Gauntlets"
	description = "Кажется, на этих перчатках есть слой слизистой жидкости — возможно, стоит вернуть их законному владельцу."
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/gloves/longblackgloves

/datum/gear/donator/trendy_fit
	name = "Trendy Fit"
	description = "Наряд прямо из космической скуки — такое носит только тот, кто пытается развлечься по пути к следующему пункту назначения."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/custom/trendy_fit

/datum/gear/donator/singery
	name = "Yellow Performer Outfit"
	description = "От одного вида этого хочется петь."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/costume/singer/yellow

/datum/gear/donator/csheet
	name = "NT Bedsheet"
	description = "На нём есть символ NanoTrasen, и оно сплетено из революционной новой нити, которая гарантирует 0,01% проницаемости для большинства нехимических веществ; популярно у большинства современных капитанов."
	slot = ITEM_SLOT_NECK
	path = /obj/item/bedsheet/captain

/datum/gear/donator/borgplush
	name = "Robot Plush"
	description = "Очаровательная мягкая игрушка робота."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/borgplushie

/datum/gear/donator/donorberet
	name = "Atmos Beret"
	description = "Плотно сидящий берет, предназначенный для техников атмосферных систем."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/blueberet

/datum/gear/donator/donorgoggles
	name = "Flight Goggles"
	description = "Старомодные лётные очки с прикреплённым кожаным колпаком."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/flight

/datum/gear/donator/onionneck
	name = "Onion Necklace"
	description = "Нить луковиц, соединённых вместе в форме ожерелья."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/necklace/onion

/datum/gear/donator/mikubikini
	name = "starlight singer bikini"
	description = "Бикини в стиле звезды-певицы."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/custom/mikubikini

/datum/gear/donator/mikujacket
	name = "starlight singer jacket"
	description = "Куртка в стиле звезды-певицы."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/mikujacket

/datum/gear/donator/mikuhair
	name = "starlight singer hair"
	description = "Волосы в стиле звезды-певицы."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/head/mikuhair

/datum/gear/donator/mikugloves
	name = "starlight singer gloves"
	description = "Перчатки в стиле звезды-певицы."
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/gloves/mikugloves

/datum/gear/donator/mikuleggings
	name = "starlight singer leggings"
	description = "Легинсы в стиле звезды-певицы."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/sneakers/mikuleggings

/datum/gear/donator/cosmos
	name = "cosmic space bedsheet"
	description = "Сделано из снов тех, кто смотрит на звёзды."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bedsheet/cosmos

/datum/gear/donator/customskirt
	name = "custom atmos skirt"
	description = "Юбка-комбинезон атмосферников: верхняя половина расстёгнута и обёрнута вокруг талии."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/custom/customskirt

/datum/gear/donator/hisakaki
	name = "halo"
	description = "Странной формы нимб, магически парящий над головой."
	slot = ITEM_SLOT_HEAD
	path = 	/obj/item/clothing/head/halo

/datum/gear/donator/vest
	name = "vest and shirt"
	description = "Жилет с рубашкой под ним."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/custom/vest

/datum/gear/donator/exo
	name = "exo frame"
	description = "Костюм, специально созданный для тех, кто живёт и дышит железом, с индивидуально подогнанными роботизированными манипуляторами для точной работы даже на самых опасных заданиях."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/custom/exo

/datum/gear/donator/choker
	name = "NT Choker"
	description = "Собственность NT с 21 января 2562 года."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/petcollar/donorchoker

/datum/gear/donator/strangemask
	name = "Strange Metal Mask"
	description = "Странная металлическая маска."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/breath/mmask

/datum/gear/donator/smaiden
	name = "shrine maiden outfit"
	description = "Кажется, слишком тесно для религиозных целей."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/smaiden

/datum/gear/donator/mgasmask
	name = "Military Gas Mask"
	description = "Редкий противогаз ЧВК, одна из очень дорогих моделей. Внутри удобно носить довольно долго. Но кроваво-красные глаза, кажется, смотрят прямо на тебя. Жутко."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/military

/datum/gear/donator/clownmask
	name = "Clown Mask"
	description = "Настоящий наряд шутника. Клоун без парика и маски — не клоун."
	path = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/clown_hat

/datum/gear/donator/spacehoodie
	name = "Space Hoodie"
	description = "Ты не уверен, зачем существует этот худи... но оно есть, и оно удобное."
	path = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/spacehoodie

/datum/gear/donator/pokerchips
	name = "pokerchip set"
	description = "Лоток с зелёными, красными, синими и чёрными фишками для покера."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/pockerchips

/datum/gear/donator/psychedelicjumpsuit
	name = "psychedelic jumpsuit"
	description = "Клёво!"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/misc/psyche

/datum/gear/donator/switchblade
	name = "Cool Switchblade"
	description = "Острый, скрытный нож с пружинным механизмом."
	slot = ITEM_SLOT_LPOCKET
	path = /obj/item/switchblade
	cost = 6

/datum/gear/donator/noir_trenchcoat
	name = "Noir Trenchcoat"
	description = "Серый тренч закалённого частного детектива."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/det_suit/grey

/datum/gear/donator/bluespacePetCarrier
	name = "The Bluespace Jar"
	description = "Банка, которая будто бы больше изнутри и как-то пропускает живые существа через узкое горлышко."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/pet_carrier/bluespace

/datum/gear/donator/glassworkTools
	name = "The Glasswork Tools"
	description = "Набор инструментов, которые понадобятся, чтобы придавать стеклу форму, лепить и доводить его до сложных фигур."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/glasswork/glasskit

/datum/gear/donator/glassblowingRod
	name = "The Glassblowing Rod"
	description = "Полая металлическая трубка для выдувания стекла."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/glasswork/blowing_rod

/datum/gear/donator/gonzoFistZippo
	name = "Gonzo Fist Zippo"
	description = "Зажигалка Zippo с культовым «Кулаком Гонзо» на матово-чёрной отделке."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/lighter/gonzofist

/datum/gear/donator/bottleOfLizardWine
	name = "Bottle of Lizard Wine"
	description = "Алкогольный напиток из Космического Китая, приготовленный настаиванием ящеричьих хвостов в этаноле. Необъяснимо популярен среди командного состава."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/reagent_containers/food/drinks/bottle/lizardwine

/datum/gear/donator/collectableWizardHat
	name = "The Collectable Wizard's Hat"
	description = "ПРИМЕЧАНИЕ: любые магические способности, полученные от ношения этой шапки, — чистое совпадение."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/collectable/wizard

/datum/gear/donator/bp_helmet
	name = "Old bullet proof helmet"
	description = "Старый стиль шлема BP. Это тот шлем без бронепластин — без них он просто стильный и крутой."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/assu_helmet/bp_helmet

/datum/gear/donator/aviator_helmet
	name = "Aviator Helmet"
	description = "Коснись небес и того, что выше!"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/helmet/aviator_helmet/no_armor

/datum/gear/donator/old_wrappings
	name = "Old Wrappings"
	description = "Пучок сшитых вместе кусков одежды, перемотанных бинтами."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/mantle/cowboy

/datum/gear/donator/book_alch
	name = "Alchemist's Book"
	description = "Покрытая пылью книга, заполненная странными рунами."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/paper/book_alch

/datum/gear/donator/cigpack_cannabis
	name = "Freak Brother's Special Cigpack"
	description = "На упаковке написано: «Одобрено Финеасом, Фредди и Франклином»."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/fancy/cigarettes/cigpack_cannabis

/// Личный маяк: призывает kit с owner_ckey; развернуть мультитулом может только владелец. Остальные собирают крафтом (5 коробок + pie cannon).
/datum/gear/donator/cardboard_tank_summon_beacon
	name = "Маяк призыва: картонный танк (личный)"
	description = "Заказной складной танк. Развернуть мультитулом сможете только вы."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/bm_cardboard_tank
	cost = 2

/datum/gear/donator/justice
	name = "Backpack of justice"
	description = "Крепкий рюкзак, выданный специально для крепких офицеров."
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/satchel/justice
	cost = 2

/datum/gear/donator/coconut_bong
	name = "Coconut Bong"
	description = "Водяная бонга для курения сушёных растений. Эта сделана из кокоса и бамбука."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bong/coconut

/datum/gear/donator/portallight_box
	name = "Portal Fleshlight and Underwear"
	description = "Маленькая серебряная шкатулка с тиснением Silver Love Co."
	path = /obj/item/storage/box/portallight

/datum/gear/donator/presscameradrone
	name = "Press Camera Drone"
	description = "Пресс-камера-дрон Ward-Takahashi EyeBuddy для прямых эфиров. Орудие выбор военных корреспондентов и операторов реалити-шоу. Похоже, встроенной памяти у него нет."
	path = /obj/item/tvcamera
