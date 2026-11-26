/datum/gear/suit/uniform_parade
	name = "Officer's parade uniform"
	description = "Великолепная и сияющая форма для почётных офицеров."
	path = /obj/item/clothing/suit/toggle/uniform_parade
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/suit_corset
	name = "Polychromic Suit Jacket"
	description = "Одежда, которую обычно носят, чтобы удерживать и формировать корпус желаемой формы — традиционно меньшую талию или более широкий низ — в эстетических или медицинских целях либо для поддержки груди."
	path = /obj/item/clothing/suit/bm/suit_corset

/datum/gear/suit/garland_suit
	name = "garlands"
	description = "Рождественские гирлянды"
	path = /obj/item/clothing/suit/garland_suit

/datum/gear/suit/polysuitjacket
	name = "Polychromic Suit Jacket"
	description = "Броское полихромное платье-жакет."
	path = /obj/item/clothing/suit/toggle/polysuitjacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/polyrobes
	name = "Polychromic Robes"
	description = "Великолепная мантия."
	path = /obj/item/clothing/suit/polyrobes

/datum/gear/suit/poly_labcoat
	name = "polychromic labcoat"
	description = "Костюм, защищающий от небольших химических разливов."
	path = /obj/item/clothing/suit/toggle/poly_labcoat

/datum/gear/suit/suspenders
	name = "Suspenders"
	description = "Они поддерживают иллюзию пантомимы."
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	path = /obj/item/clothing/suit/suspenders

/datum/gear/suit/suspenders_white
	name = "White Suspenders"
	description = "Они поддерживают иллюзию картины."
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	path = /obj/item/clothing/suit/suspenders/suspenders_white

/datum/gear/suit/nri_coat
	name = "Russian Empire Coat"
	description = "Пальто без броненосных волокон — для косплея."
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	path = /obj/item/clothing/suit/armor/nri_coat/armorless

/datum/gear/suit/mark45_armor
	name = "Mk. 45 Black Legionnaire Armor"
	description = "Штатная броня армии каткринов. Разработана в 2545 году. Броня заметно лёгкая, не стесняет движений и покрывает большую часть тела, при этом не теряет защитных свойств, оставаясь на одном уровне с аналогами. Личный код владельца написан снаружи. Эта выглядит поношенной — скорее всего, снята с трупа."
	path = /obj/item/clothing/suit/armor/mark45_armor
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Peacekeeper", "Blueshield")

/datum/gear/suit/mark45_armor_snow
	name = "Mk. 45 Snow Cover Аrmor set"
	description = "Модифицированная броня каткринов, оптимизированная для холодного климата. Внутри виден слой тёплой шерсти, сохраняющий тепло владельца. Личный код владельца написан снаружи. Эта выглядит поношенной — скорее всего, снята с трупа."
	path = /obj/item/clothing/suit/armor/mark45_armor/mark45_armor_snow
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Peacekeeper", "Blueshield")

/datum/gear/suit/mark45_armor_anomalist
	name = "Mk. 45 Anomalist Аrmor set"
	description = "Броня, созданная на базе Mk. 45. Её носят аномалисты армии каткринов — те, кто изучает потусторонний мир духов и связан с устранением различных враждебных аномалий. Она также украшена особой лёгкой бронированной тканью, показывающей статус владельца и защищающей его от возможных осколков. Личный код владельца написан снаружи. Эта выглядит поношенной — скорее всего, снята с трупа."
	path = /obj/item/clothing/suit/armor/mark45_armor/mark45_armor_anomalist
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Security Officer, Peacekeeper."
	restricted_roles = list("Security Officer", "Peacekeeper")

/datum/gear/suit/mark45_armor_combatengineer
	name = "Mk. 45 Combat engineer Аrmor set"
	description = "Модифицированная версия брони, созданная для боевых инженеров армии каткринов, с дополнительным манипулятором. Личный код владельца написан снаружи. Эта выглядит поношенной — скорее всего, снята с трупа."
	path = /obj/item/clothing/suit/armor/mark45_armor/mark45_armor_combatengineer
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Security Officer, Peacekeeper."
	restricted_roles = list("Security Officer", "Peacekeeper")

/datum/gear/suit/mark45_armor_support
	name = "Mk. 45 Support Аrmor set"
	description = "Более лёгкая версия брони Mk. 45 с дополнительными подсумками и опознавательным знаком на наплечнике. Её используют вспомогательные бойцы армии каткринов. Личный код владельца написан снаружи. Эта выглядит поношенной — скорее всего, снята с трупа."
	path = /obj/item/clothing/suit/armor/mark45_armor/mark45_armor_support
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Security Officer, Peacekeeper."
	restricted_roles = list("Security Officer", "Peacekeeper")

/datum/gear/suit/mark45_armor_officer
	name = "Mk. 45 Officer Аrmor set"
	description = "Несколько более усиленная броня, которую носят офицеры армии каткринов, с особым плащом на левом плече. Личный код владельца написан снаружи. Эта выглядит поношенной — скорее всего, снята с трупа."
	path = /obj/item/clothing/suit/armor/hos/mark45_armor_officer
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Blueshield."
	restricted_roles = list("Head of Security", "Blueshield")

/datum/gear/suit/mark45_armor_desert
	name = "Mk. 45 Desert Hunter Armor"
	description = "Модифицированная броня, обычно используемая пустынными каткринами. Одно из заметных отличий — слой ткани, снижающий износ от песчаных бурь и продлевающий срок службы в пустынных условиях. Личный код владельца написан снаружи. Эта выглядит поношенной — скорее всего, снята с трупа."
	path = /obj/item/clothing/suit/armor/mark45_armor/mark45_armor_desert
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Peacekeeper", "Blueshield")

/datum/gear/suit/mark45_armor_medic_h
	name = "Mk. 45 heavy combat medic Аrmor"
	description = "Модифицированная броня каткринов, более тяжёлая по медицинским меркам. На заметно большем наплечнике отличительный знак; её гораздо чаще 사용ят в боевых столкновениях. Личный код владельца написан снаружи. Эта выглядит поношенной — скорее всего, снята с трупа."
	path = /obj/item/clothing/suit/armor/brigdoc/mark45_armor/medic_h
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Brig Physician."
	restricted_roles = list("Brig Physician")

/datum/gear/suit/mark45_armor_medic_l
	name = "Mk. 45 medic's combat coat"
	description = "Особое пальто для медика армии каткринов с лёгкими пластинами на груди, защитой плеч и бронированной тканью, минимально мешающей движениям. Личный код владельца написан снаружи. Это выглядит поношенным — скорее всего, снято с трупа."
	path = /obj/item/clothing/suit/armor/brigdoc/mark45_armor/medic_l
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Brig Physician."
	restricted_roles = list("Brig Physician")

/datum/gear/suit/warm_ponchogreen
	name = "Green warm poncho"
	description = "Тёплый плед из грубой шерсти."
	path = /obj/item/clothing/suit/toggle/warm_poncho/green

/datum/gear/suit/warm_ponchored
	name = "Red warm poncho"
	description = "Тёплый плед из грубой шерсти."
	path = /obj/item/clothing/suit/toggle/warm_poncho/red

/datum/gear/suit/warm_ponchoblue
	name = "Blue warm poncho"
	description = "Тёплый плед из грубой шерсти."
	path = /obj/item/clothing/suit/toggle/warm_poncho/blue

/datum/gear/suit/warm_ponchorainbow
	name = "Rainbow warm poncho"
	description = "Тёплый плед из грубой шерсти."
	path = /obj/item/clothing/suit/toggle/warm_poncho

/datum/gear/suit/ac_armoredcoat
	name = "AC Armored Coat"
	description = "Пальто для престижных наёмников из ЧВК Adamas Cattus."
	path = /obj/item/clothing/suit/toggle/captains_parade/hos_formal/ac
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Warden, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Blueshield")

/datum/gear/suit/paratrench
	name = "Brown trenchcoat"
	description = "Тренч с биркой бренда TailorCo. Выглядит дорого."
	path = /obj/item/clothing/suit/jacket/paratrench
	subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS
	cost = 2

/datum/gear/suit/paratrenchblack
	name = "Black trenchcoat"
	description = "Тренч с биркой бренда TailorCo. Выглядит дорого."
	path = /obj/item/clothing/suit/jacket/paratrench/black
	subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS
	cost = 2

/datum/gear/suit/wizrobe/marisa/fake
	name = "Witch robe"
	description = "В магии всё дело в силе заклинания, ЗЕ!"
	path = /obj/item/clothing/suit/wizrobe/marisa/fake


/datum/gear/suit/sergal_leather_cape
	name = "Sergal leather cape"
	path = /obj/item/clothing/suit/bm/sergal_leather_cape

/datum/gear/suit/sergal_red_cape
	name = "Sergal red cape"
	path = /obj/item/clothing/suit/bm/sergal_red_cape

/datum/gear/suit/sergal_red_armor
	name = "Sergal red armor"
	path = /obj/item/clothing/suit/bm/sergal_red_armor

/datum/gear/suit/sergal_stylish_armor
	name = "Sergal stylish armor"
	path = /obj/item/clothing/suit/bm/sergal_stylish_armor

/datum/gear/suit/sergal_knight_armor
	name = "Sergal knight's armor"
	path = /obj/item/clothing/suit/bm/sergal_knight_armor

/datum/gear/suit/sergal_green_jacket
	name = "Sergal green jacket"
	path = /obj/item/clothing/suit/hooded/bm/sergal_green_jacket

/datum/gear/suit/occult
	name = "Occult collector's coat"
	description = "Большое тяжёлое пальто, подшитое кожей и тканью из слоновой кости, с капюшоном. Выглядит пыльным."
	path = /obj/item/clothing/suit/hooded/occult
