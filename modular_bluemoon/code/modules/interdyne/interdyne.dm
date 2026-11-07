// Interdyne Pharmaceutics - порт из NovaSector (код AGPL v3, иконки CC-BY-SA 3.0)

//Interdyne Medkits
// Вспомогательная процедура: кладёт в хранилище предметы из списка (тип = количество).
/obj/item/storage/proc/interdyne_fill(list/items_inside)
	for(var/item_path in items_inside)
		for(var/i in 1 to items_inside[item_path])
			new item_path(src)

// Пустая аптечка (для ручного заполнения)
/obj/item/storage/firstaid/tactical/interdyne_medium_empty
	name = "\improper Interdyne Empty Medkit"
	desc = "Большая аптечка Interdyne Pharmaceutics. Поставляется пустой."
	icon = 'modular_bluemoon/icons/obj/Interdyne/medkit.dmi'
	icon_state = "interdyne_premium"
	item_state = "medkit-tactical"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_righthand.dmi'

/obj/item/storage/firstaid/tactical/interdyne_medium_empty/PopulateContents()
	return

// Interdyne Medkit (tactical): 8 предметов
/obj/item/storage/firstaid/tactical/interdyne
	name = "\improper Interdyne Medkit"
	desc = "Большая аптечка Interdyne Pharmaceutics для самых разных ситуаций."
	icon = 'modular_bluemoon/icons/obj/Interdyne/medkit.dmi'
	icon_state = "interdyne_premium"
	item_state = "medkit-tactical"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_righthand.dmi'

/obj/item/storage/firstaid/tactical/interdyne/PopulateContents()
	interdyne_fill(list(
		/obj/item/stack/medical/gauze/adv = 1, // sterilized medical gauze
		/obj/item/reagent_containers/hypospray/combat = 1, // combat stimulant injector
		/obj/item/hypospray/mkii/CMO/combat/synthflesh = 4, // Combat Hypospray with Neosynth
		/obj/item/healthanalyzer/advanced = 1,
		/obj/item/reagent_containers/hypospray/medipen/stimulants = 1, // stimpack medipen
	))

// [пока убран до лучших времён] Interdyne Coroner Medkit: содержимое Advanced tactical first-aid kit, бинты заменены на улучшенные нити
// // TODO: проверьте тип родителя. Если у вас Advanced tactical kit называется иначе, поправьте строку ниже.
// /obj/item/storage/firstaid/advanced/interdyne_coroner
// 	name = "\improper Interdyne Coroner Medkit"
// 	desc = "Аптечка Interdyne Pharmaceutics для патологоанатомов."
// 	icon = 'modular_bluemoon/icons/obj/Interdyne/medkit.dmi'
// 	icon_state = "interdyne_premium_corpse"
// 	item_state = "medkit-tactical"
// 	lefthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_lefthand.dmi'
// 	righthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_righthand.dmi'
//
// /obj/item/storage/firstaid/advanced/interdyne_coroner/PopulateContents()
// 	. = ..()
// 	var/removed = 0
// 	for(var/obj/item/stack/medical/gauze/G in contents)
// 		qdel(G)
// 		removed++
// 	interdyne_fill(list(/obj/item/stack/medical/suture/medicated = max(removed, 1)))

// Interdyne Oxygen Medkit: точный список из 7 предметов (лимит аптечки), без наследования содержимого
/obj/item/storage/firstaid/o2/interdyne
	name = "\improper Interdyne Oxygen Medkit"
	desc = "Аптечка Interdyne Pharmaceutics для лечения кислородного голодания."
	icon = 'modular_bluemoon/icons/obj/Interdyne/medkit.dmi'
	icon_state = "interdyne_premium_oxy"
	item_state = "medkit-tactical"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_righthand.dmi'

/obj/item/storage/firstaid/o2/interdyne/PopulateContents()
	interdyne_fill(list(
		/obj/item/reagent_containers/hypospray/combat = 1, // combat stimulant injector
		/obj/item/reagent_containers/hypospray/medipen/salbutamol = 2,
		/obj/item/reagent_containers/pill/salbutamol = 2, // 30u
		/obj/item/healthanalyzer/advanced = 1,
		/obj/item/reagent_containers/glass/bottle/dexalin = 1, // TODO: если ошибка, найдите тип поиском по 'dexalin'
	))

// Interdyne Brute Medkit
/obj/item/storage/firstaid/brute/interdyne
	name = "\improper Interdyne Brute Medkit"
	desc = "Аптечка Interdyne Pharmaceutics для лечения физических травм."
	icon = 'modular_bluemoon/icons/obj/Interdyne/medkit.dmi'
	icon_state = "interdyne_premium_brute"
	item_state = "medkit-tactical"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_righthand.dmi'

/obj/item/storage/firstaid/brute/interdyne/PopulateContents()
	interdyne_fill(list(
		/obj/item/stack/medical/gauze/adv = 1,
		/obj/item/stack/medical/suture/medicated = 2,
		/obj/item/reagent_containers/hypospray/medipen/salacid = 2,
		/obj/item/hypospray/mkii/CMO/combat/synthflesh = 1, // Combat Hypospray with Neosynth
		/obj/item/healthanalyzer/advanced = 1,
	))

// Interdyne Burn Medkit
/obj/item/storage/firstaid/fire/interdyne
	name = "\improper Interdyne Burn Medkit"
	desc = "Аптечка Interdyne Pharmaceutics для лечения ожогов."
	icon = 'modular_bluemoon/icons/obj/Interdyne/medkit.dmi'
	icon_state = "interdyne_premium_burn"
	item_state = "medkit-tactical"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_righthand.dmi'

/obj/item/storage/firstaid/fire/interdyne/PopulateContents()
	interdyne_fill(list(
		/obj/item/stack/medical/gauze/adv = 1,
		/obj/item/stack/medical/mesh/advanced = 2,
		/obj/item/reagent_containers/hypospray/medipen/oxandrolone = 2,
		/obj/item/hypospray/mkii/CMO/combat/synthflesh = 1, // Combat Hypospray with Neosynth
		/obj/item/healthanalyzer/advanced = 1,
	))

// Interdyne Toxin Medkit: список с нуля, 7 предметов
/obj/item/storage/firstaid/toxin/interdyne
	name = "\improper Interdyne Toxin Medkit"
	desc = "Аптечка Interdyne Pharmaceutics для лечения отравлений и облучения."
	icon = 'modular_bluemoon/icons/obj/Interdyne/medkit.dmi'
	icon_state = "interdyne_premium_toxin"
	item_state = "medkit-tactical"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/equipment/medical_righthand.dmi'

/obj/item/storage/firstaid/toxin/interdyne/PopulateContents()
	interdyne_fill(list(
		/obj/item/reagent_containers/syringe/calomel = 1,
		/obj/item/reagent_containers/hypospray/medipen/penacid = 2, // pentetic acid medipen
		/obj/item/storage/pill_bottle/charcoal = 2, // bottle of charcoal pills
		/obj/item/healthanalyzer/advanced = 1,
		/obj/item/reagent_containers/hypospray/combat = 1, // combat stimulant injector
	))

//Interdyne Uniforms
/obj/item/clothing/under/syndicate/interdyne
	name = "interdyne turtleneck"
	desc = "Элегантная белая водолазка с оттенком фирменного зелёного Interdyne в паре с угольно-чёрными карго-штанами."
	icon = 'modular_bluemoon/icons/obj/Interdyne/syndicate.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/under/syndicate.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/Interdyne/under/syndicate_digi.dmi'
	icon_state = "ip_turtleneck"
	item_state = "ip_turtleneck"

// В syndicate_digi.dmi нет ip_miner - на лапах обычный спрайт.
/obj/item/clothing/under/syndicate/interdyne/miner
	name = "interdyne jumpsuit"
	desc = "Чёрно-зелёный комбинезон Interdyne Pharmaceutics с усиленными волокнами."
	icon_state = "ip_miner"
	item_state = "ip_miner"
	mutantrace_variation = USE_TAUR_CLIP_MASK

/obj/item/clothing/under/syndicate/interdyne/deckofficer
	name = "deck officer's jumpsuit"
	desc = "Чёрно-зелёная форма Interdyne Pharmaceutics с золотой пряжкой на ремне."
	icon_state = "ip_deckofficer"
	item_state = "ip_deckofficer"

//Interdyne Hats
/obj/item/clothing/head/interdyne_deckofficer_black
	name = "black deck officer's cap"
	desc = "Чёрная офицерская фуражка, требующая дисциплины от того, кто её носит."
	icon = 'modular_bluemoon/icons/obj/Interdyne/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/head.dmi'
	icon_state = "ip_officercap_black"
	item_state = "ip_officercap_black"

/obj/item/clothing/head/interdyne_deckofficer_white
	name = "white deck officer's cap"
	desc = "Белая офицерская фуражка, требующая дисциплины от того, кто её носит."
	icon = 'modular_bluemoon/icons/obj/Interdyne/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/head.dmi'
	icon_state = "ip_officercap_white"
	item_state = "ip_officercap_white"

//Interdyne Biosuit
/obj/item/clothing/head/bio_hood/interdyne
	name = "interdyne paramedic hood"
	desc = "Лёгкий капюшон парамедиков Interdyne Pharmaceutics из комплекта защитного костюма. Защищает не хуже армейского шлема MOPP."
	icon = 'modular_bluemoon/icons/obj/Interdyne/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/head.dmi'
	icon_state = "ip_biosuit_head"
	item_state = "ip_biosuit_head"
	// Статы и защита как у advance MOPP hood.
	armor_type = /datum/armor/head_advance
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL
	max_heat_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	mutantrace_variation = NONE

/obj/item/clothing/suit/bio_suit/interdyne
	name = "interdyne paramedic suit"
	desc = "Лёгкий защитный костюм парамедиков Interdyne Pharmaceutics. Мягкая дышащая ткань и свободный крой на спине не стесняют движений, поэтому его особенно ценят мотыльки. Защищает не хуже армейских костюмов MOPP."
	icon = 'modular_bluemoon/icons/obj/Interdyne/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/suit.dmi'
	icon_state = "ip_biosuit"
	item_state = "ip_biosuit"
	// Статы как у advance MOPP suit 'Medical': тот же armor datum и без замедления.
	armor_type = /datum/armor/suit_advance
	slowdown = 0
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL
	heat_protection = CHEST|GROIN|LEGS|ARMS
	max_heat_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	cold_protection = CHEST|GROIN|LEGS|ARMS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals/doubleoxygen, /obj/item/tank/internals/oxygen, /obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman, /obj/item/geiger_counter, /obj/item/tank/internals/emergency_nitrogen_ext, /obj/item/gun/medbeam, /obj/item/healthanalyzer, /obj/item/stack/medical, /obj/item/storage/firstaid, /obj/item/analyzer, /obj/item/reagent_containers/syringe, /obj/item/reagent_containers/hypospray, /obj/item/defibrillator)

//Interdyne Labcoats
/obj/item/clothing/suit/toggle/labcoat/interdyne_labcoat_black
	name = "interdyne black labcoat"
	desc = "Чёрный лабораторный халат с акцентами фирменного зелёного Interdyne."
	icon = 'modular_bluemoon/icons/obj/Interdyne/labcoat.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/labcoat.dmi'
	icon_state = "ip_labcoatblack"
	item_state = "ip_labcoatblack"

/obj/item/clothing/suit/toggle/labcoat/interdyne_labcoat_white
	name = "interdyne white labcoat"
	desc = "Белый лабораторный халат с акцентами фирменного зелёного Interdyne."
	icon = 'modular_bluemoon/icons/obj/Interdyne/labcoat.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/labcoat.dmi'
	icon_state = "ip_labcoatwhite"
	item_state = "ip_labcoatwhite"

/obj/item/clothing/suit/toggle/labcoat/interdyne_officer_labcoat
	name = "deck officer's labcoat"
	desc = "Лабораторный халат с зелёными акцентами, который носит высокопоставленный персонал Interdyne."
	icon = 'modular_bluemoon/icons/obj/Interdyne/labcoat.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/labcoat.dmi'
	icon_state = "ip_officerlabcoat"
	item_state = "ip_officerlabcoat"

/obj/item/clothing/suit/toggle/labcoat/interdyne_jacket
	name = "interdyne jacket"
	desc = "Зелёная светоотражающая куртка в цветах Interdyne."
	icon = 'modular_bluemoon/icons/obj/Interdyne/labcoat.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/labcoat.dmi'
	icon_state = "ip_armorlabcoat"
	item_state = "ip_armorlabcoat"

//Interdyne Backpacks
// Состояния в backpacks.dmi: backpack-dyne, satchel-dyne, duffel-dyne
/obj/item/storage/backpack/interdyne
	name = "interdyne backpack"
	desc = "Вместительный рюкзак в цветах Interdyne Pharmaceutics."
	icon = 'modular_bluemoon/icons/obj/Interdyne/backpacks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/back.dmi'
	icon_state = "backpack-dyne"
	item_state = "backpack-dyne"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/clothing/backpack_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/clothing/backpack_righthand.dmi'

/obj/item/storage/backpack/satchel/interdyne
	name = "interdyne satchel"
	desc = "Сумка-сэтчел в цветах Interdyne Pharmaceutics."
	icon = 'modular_bluemoon/icons/obj/Interdyne/backpacks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/back.dmi'
	icon_state = "satchel-dyne"
	item_state = "satchel-dyne"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/clothing/backpack_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/clothing/backpack_righthand.dmi'

/obj/item/storage/backpack/duffelbag/syndie/interdyne
	name = "interdyne duffel bag"
	desc = "Большая спортивная сумка в цветах Interdyne Pharmaceutics."
	icon = 'modular_bluemoon/icons/obj/Interdyne/backpacks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/back.dmi'
	icon_state = "duffel-dyne"
	item_state = "duffel-dyne"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/clothing/backpack_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/Interdyne/clothing/backpack_righthand.dmi'

//Interdyne Belts
// Состояния: ert_ntrauma и belt_white есть и в obj/Interdyne/belts.dmi, и в mob/Interdyne/belt.dmi
// Подтипы, чтобы не менять общий ntrauma-пояс у остальных.
/obj/item/storage/belt/medical/ntrauma/interdyne
	name = "interdyne trauma chest rig"
	desc = "Тактический разгрузочный жилет Interdyne Pharmaceutics для работы в зонах с травмами."
	icon = 'modular_bluemoon/icons/obj/Interdyne/belts.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/belt.dmi'
	icon_state = "ert_ntrauma"
	item_state = "ert_ntrauma"

/obj/item/storage/belt/medical/interdyne
	name = "interdyne medical belt"
	desc = "Белый медицинский пояс Interdyne Pharmaceutics."
	icon = 'modular_bluemoon/icons/obj/Interdyne/belts.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/belt.dmi'
	icon_state = "belt_white"
	item_state = "belt_white"

//Interdyne Defibrillator
// Оставлен только боевой поясной дефибриллятор. Обычный рюкзачный убран.
// defib.dmi: defibip, defibip-powered, defibip-emagged, defibip-nocell, defibip-charge100/75/50/25, defibip-paddles,
// ippaddles0/1 и ippaddles0/1_cooldown (лопатки).
// Имена оверлеев (paddle_state, powered_state и т.д.) и base_icon_state лопаток подогнаны под эти состояния.
// Свойства как у /obj/item/defibrillator/compact/combat (без предохранителя, реанимация сквозь скафандры,
// удар без задержки), носится на поясе. Лучше обычного боевого: лучше батарея, быстрее заряд,
// дольше окно реанимации, встроенное лечение после реанимации и защита от удара по тому, кто тащит тело.
/obj/item/defibrillator/interdyne/combat
	name = "interdyne combat defibrillator"
	desc = "Поясной дефибриллятор, который Interdyne Pharmaceutics выдаёт своим парамедикам в местах, откуда не принято возвращаться. Предохранители выпаяны, лопатки пробивают даже скафандр, а конденсаторы заряжаются быстрее, чем пациент успевает остыть. На корпусе выцарапан слоган: «Trauma Team Interdyne: прилетим на свет вашей беды за семь минут или вернём деньги! Мотыльки-парамедики не опаздывают.»"
	icon = 'modular_bluemoon/icons/obj/Interdyne/defib.dmi'
	icon_state = "defibip"
	// Worn-спрайт на поясе: стандартный от компактного дефиба.
	// Объектный defib.dmi в mob_overlay_icon ставить нельзя, на персонаже рисуется огромный спрайт.
	// Когда нарисуете свой: положите состояние "defibip-belt" в mob/Interdyne/belt.dmi и раскомментируйте две строки ниже.
	mob_overlay_icon = null
	item_state = "defibcompact"
	// mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/belt.dmi'
	// item_state = "defibip-belt"
	paddle_state = "defibip-paddles"
	powered_state = "defibip-powered"
	charge_state = "defibip-charge"
	nocell_state = "defibip-nocell"
	emagged_state = "defibip-emagged"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_NORMAL
	combat = TRUE
	safety = FALSE
	always_emagged = TRUE
	disarm_shock_time = 0
	primetime = 10
	timedeath = 20
	healdisk = TRUE
	pullshocksafely = TRUE
	cell = /obj/item/stock_parts/cell/bluespace

/obj/item/defibrillator/interdyne/combat/make_paddles()
	return new /obj/item/shockpaddles/interdyne(src)

/obj/item/defibrillator/interdyne/combat/item_action_slot_check(slot, mob/user, datum/action/A)
	if(slot == user.getBeltSlot())
		return TRUE

// Оверлей "defibip-emagged" (предохранитель выпаян, safety = FALSE) родитель рисует всегда.
// Здесь он используется как индикатор низкого заряда: виден только когда батарея на 20% и ниже.
/obj/item/defibrillator/interdyne/combat/update_overlays()
	. = ..()
	. -= emagged_state
	if(cell && cell.maxcharge && (cell.charge / cell.maxcharge) <= 0.2)
		. += emagged_state

/obj/item/shockpaddles/interdyne
	name = "interdyne defibrillator paddles"
	desc = "Лопатки дефибриллятора Interdyne Pharmaceutics."
	icon = 'modular_bluemoon/icons/obj/Interdyne/defib.dmi'
	icon_state = "ippaddles0"
	item_state = "ippaddles0"
	base_icon_state = "ippaddles"

//Interdyne Wardrobe (вендор)
// Состояния в vending.dmi: ipdrobe, ipdrobe-panel, ipdrobe-off, ipdrobe-broken
// TODO: если у вас у остальных вендоров-гардеробов задан refill_canister, добавьте свой, иначе перезарядка не потребуется.
/obj/machinery/vending/wardrobe/interdyne
	name = "InterDrobe"
	desc = "Автомат с одеждой и снаряжением Interdyne Pharmaceutics."
	icon = 'modular_bluemoon/icons/obj/Interdyne/vending.dmi'
	icon_state = "ipdrobe"
	product_ads = "Фирменный зелёный всегда в моде!;Interdyne заботится о вашем здоровье!;Безопасность прежде всего, стиль сразу после."
	vend_reply = "Спасибо, что выбрали Interdyne Pharmaceutics!"
	products = list(
		// Форма
		/obj/item/clothing/under/syndicate/interdyne = 3,
		/obj/item/clothing/under/syndicate/interdyne/miner = 3,
		/obj/item/clothing/under/syndicate/interdyne/deckofficer = 2,
		// Головные уборы
		/obj/item/clothing/head/interdyne_deckofficer_black = 2,
		/obj/item/clothing/head/interdyne_deckofficer_white = 2,
		// Биокостюм
		/obj/item/clothing/head/bio_hood/interdyne = 2,
		/obj/item/clothing/suit/bio_suit/interdyne = 2,
		// Халаты и куртка
		/obj/item/clothing/suit/toggle/labcoat/interdyne_labcoat_black = 3,
		/obj/item/clothing/suit/toggle/labcoat/interdyne_labcoat_white = 3,
		/obj/item/clothing/suit/toggle/labcoat/interdyne_officer_labcoat = 2,
		/obj/item/clothing/suit/toggle/labcoat/interdyne_jacket = 3,
		// Сумки
		/obj/item/storage/backpack/interdyne = 3,
		/obj/item/storage/backpack/satchel/interdyne = 3,
		/obj/item/storage/backpack/duffelbag/syndie/interdyne = 2,
		// Пояса
		/obj/item/storage/belt/medical/ntrauma/interdyne = 2,
		/obj/item/storage/belt/medical/interdyne = 3,
		// Аптечки
		/obj/item/storage/firstaid/tactical/interdyne_medium_empty = 2,
		/obj/item/storage/firstaid/tactical/interdyne = 2,
		/obj/item/storage/firstaid/o2/interdyne = 2,
		/obj/item/storage/firstaid/brute/interdyne = 2,
		/obj/item/storage/firstaid/fire/interdyne = 2,
		/obj/item/storage/firstaid/toxin/interdyne = 2,
		// Дефиб
		/obj/item/defibrillator/interdyne/combat = 2,
	)

//Viva la InterMothFarm
//ёбаный рот этого казино блять, мне ещё аванпост ДСам доделывать и искать мыш для тестов, так ещё и кодекс и НРП писать, убейтее меняяяяя
