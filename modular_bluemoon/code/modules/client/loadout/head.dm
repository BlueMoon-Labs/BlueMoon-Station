/datum/gear/head/beret_hca
    name = "HCA beret"
    description = "Чёрный берет с серебряным солнцем, вокруг которого расходятся лучи. Символ Триады Солнца — главной идеи партии «Содружество людей». Слава человечеству!"
    subcategory = LOADOUT_SUBCATEGORY_HEAD_GENERAL
    path = /obj/item/clothing/head/hcaberet

/datum/gear/head/turban
	name = "Turban"
	path = /obj/item/clothing/head/turban

/datum/gear/head/harebell
	name = "Harebell"
	description = "«Я смягчу твой печальный могильный холм: тебе не будет недоставать цветка, подобного твоему лицу — бледной примулы, и лазурного колокольчика, словно твои вены; нет, и листа шиповника, который, не в укор ему, не превзошёл аромат твоего дыхания.»"
	cost = 2
	path = /obj/item/reagent_containers/food/snacks/grown/harebell

/datum/gear/head/syndicate_cap
	name = "Syndicate Cap"
	description = "Чёрная фуражка, достойная высокопоставленного офицера синдиката."
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	path = /obj/item/clothing/head/HoS/syndicate
	restricted_roles = list("Captain","Head of Security")

/datum/gear/head/sol_beret
	name = "SolFed Beret"
	description = "Синий берет в стиле SolFed."
	subcategory = LOADOUT_SUBCATEGORY_HEAD_GENERAL
	path = /obj/item/clothing/head/HoS/beret/sol/plain/armorless

/datum/gear/head/sol_cap
	name = "SolFed Cap"
	description = "Синяя фуражка SolFed без какой-либо защиты."
	subcategory = LOADOUT_SUBCATEGORY_HEAD_GENERAL
	path = /obj/item/clothing/head/HoS/beret/sol/cap/armorless

/datum/gear/head/nri_cap
	name = "Russian Empire Cap"
	description = "Фуражка NRI без какой-либо защиты."
	subcategory = LOADOUT_SUBCATEGORY_HEAD_GENERAL
	path = /obj/item/clothing/head/HoS/beret/nri/cap/armorless

/datum/gear/head/chronos_beret
	name = "New Mecca Beret"
	description = "Но сжигание тех деревень, слёзы нагих крестьян..."
	subcategory = LOADOUT_SUBCATEGORY_HEAD_GENERAL
	path = /obj/item/clothing/head/beret/chronos

/datum/gear/head/bow
	name = "A polychromic bow"
	path = /obj/item/toy/fluff/bant

/datum/gear/head/rose
	name = "Rose"
	description = "Классический fleur d'amour — цветок любви. Остерегайтесь шипов!"
	path = /obj/item/grown/rose

/datum/gear/head/helmet/mark45
	name = "Mk. 45 Black Legionnaire helmet"
	description = "Штатный шлем армии каткринов. Разработан в 2545 году, может носиться отдельно от своего костюма — для этого снимается защитный чехол с нижней части шлема. Специально спроектированные накладки для ушей учитывают анатомию каткринов. Помимо максимального комфорта, встроенные серводвигатели самостоятельно поворачивают их к источникам звука, улавливая фоновый шум и приглушая громкие звуки для защиты слуха. Личный код владельца написан снаружи. Этот выглядит поношенным — скорее всего, снят с трупа."
	path = /obj/item/clothing/head/helmet/sec/mark45
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Peacekeeper", "Blueshield")

/datum/gear/head/helmet/mark45_desert
	name = "Mk. 45 Desert Hunter helmet"
	description = "Модифицированный шлем, обычно используемый пустынными каткринами. Одно из заметных отличий — слой ткани, снижающий износ от песчаных бурь и продлевающий срок службы в пустынных условиях. Личный код владельца написан снаружи. Этот выглядит поношенным — скорее всего, снят с трупа."
	path = /obj/item/clothing/head/helmet/sec/mark45_desert
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Peacekeeper", "Blueshield")

/datum/gear/head/helmet/mark45_snow
	name = "Mk. 45 Snow Cover helmet"
	description = "Модифицированный шлем каткринов, оптимизированный для холодного климата и сильно отличающийся внешне от оригинала. Сверху прикреплена лёгкая пластина для сбрасывания снега, а забрало уменьшено. Внутри шлем подшит шерстью, не тронуты только уши. Личный код владельца написан снаружи. Этот выглядит поношенным — скорее всего, снят с трупа."
	path = /obj/item/clothing/head/helmet/sec/mark45_snow
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Peacekeeper", "Blueshield")

/datum/gear/head/helmet/mark45_anomalist
	name = "Mk. 45 Anomalist helmet"
	description = "Шлем аномалиста армии каткринов с дополнительным украшением в виде лёгкой бронированной ткани. Он также защищает от мелких осколков и показывает статус владельца. Личный код владельца написан снаружи. Этот выглядит поношенным — скорее всего, снят с трупа."
	path = /obj/item/clothing/head/helmet/sec/mark45_anomalist
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Security Officer, Peacekeeper."
	restricted_roles = list("Security Officer", "Peacekeeper")

/datum/gear/head/helmet/mark45_combatengineer
	name = "Mk. 45 Combat engineer helmet"
	description = "Шлем боевого инженера армии каткринов с лёгким затемнением забрала для защиты глаз во время работы. Личный код владельца написан снаружи. Этот выглядит поношенным — скорее всего, снят с трупа."
	path = /obj/item/clothing/head/helmet/sec/mark45_combatengineer
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Security Officer, Peacekeeper."
	restricted_roles = list("Security Officer", "Peacekeeper")

/datum/gear/head/helmet/mark45_support
	name = "Mk. 45 Support helmet"
	description = "Шлем солдата поддержки армии каткринов с белым крестом для опознавания. Личный код владельца написан снаружи. Этот выглядит поношенным — скорее всего, снят с трупа."
	path = /obj/item/clothing/head/helmet/sec/mark45_support
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Security Officer, Peacekeeper."
	restricted_roles = list("Security Officer", "Peacekeeper")

/datum/gear/head/HoS/mark45_officer
	name = "Mk. 45 Officer helmet"
	description = "Шлем офицера каткринов с особыми отличительными метками. Личный код владельца написан снаружи. Этот выглядит поношенным — скорее всего, снят с трупа."
	path = /obj/item/clothing/head/HoS/mark45_officer
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Blueshield."
	restricted_roles = list("Head of Security", "Blueshield")

/datum/gear/head/helmet/brigdoc/mark45_medic_l
	name = "Mk. 45 light medic helmet"
	description = "Облегчённый модифицированный шлем медиков армии каткринов для помощи в боевых столкновениях. Личный код владельца написан снаружи. Этот выглядит поношенным — скорее всего, снят с трупа."
	path = /obj/item/clothing/head/helmet/brigdoc/mark45_medic_l
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Brig Physician."
	restricted_roles = list("Brig Physician")

/datum/gear/head/helmet/brigdoc/mark45_medic_h
	name = "Mk. 45 heavy medic helmet"
	description = "Тяжёлый модифицированный шлем медиков армии каткринов для помощи в боевых столкновениях. Личный код владельца написан снаружи. Этот выглядит поношенным — скорее всего, снят с трупа."
	path = /obj/item/clothing/head/helmet/brigdoc/mark45_medic_h
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Brig Physician."
	restricted_roles = list("Brig Physician")

/datum/gear/head/ac_beret
	name = "AC Beret"
	description = "Берет для наёмников со специальной усиленной тканью, дающей некоторую защиту."
	path = /obj/item/clothing/head/beret/sec/ac
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/head/ac_cap
	name = "AC Cap"
	description = "Особая фуражка для особых наёмников."
	path = /obj/item/clothing/head/soft/sec/ac
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/head/ac_officercap
	name = "AC Officer Cap"
	description = "Особая фуражка для особых наёмников."
	path = /obj/item/clothing/head/warden/ac
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_desc = "Head of Security, Warden, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Blueshield")

/datum/gear/head/saints
    name = "Saints hat"
    subcategory = LOADOUT_SUBCATEGORY_HEAD_GENERAL
    path = /obj/item/clothing/head/saints

/datum/gear/head/christmashatg
	name = "Christmas Beanie"
	path = /obj/item/clothing/head/beanie/christmas

/datum/gear/head/wizard/marisa/fake
	name = "Witch hat"
	description = "Странный головной убор. Хочется метать огненные шары."
	path = /obj/item/clothing/head/wizard/marisa/fake

/datum/gear/head/sergal_slalom_hat
	name = "Sergal slalom hat"
	path = /obj/item/clothing/head/bm/sergal_slalom_hat

/datum/gear/head/sergal_stylish_helmet
	name = "Sergal stylish helmet"
	path = /obj/item/clothing/head/bm/sergal_stylish_helmet

/datum/gear/head/sergal_red_helmet
	name = "Sergal red helmet"
	path = /obj/item/clothing/head/bm/sergal_red_helmet

/datum/gear/head/sergal_leather_hat
	name = "Sergal leather hat"
	path = /obj/item/clothing/head/bm/sergal_leather_hat

/datum/gear/head/sergal_brown_helmet
	name = "Sergal brown helmet"
	path = /obj/item/clothing/head/bm/sergal_brown_helmet

/datum/gear/head/sergal_knight_helmet
	name = "Sergal knight's helmet"
	path = /obj/item/clothing/head/bm/sergal_knight_helmet
