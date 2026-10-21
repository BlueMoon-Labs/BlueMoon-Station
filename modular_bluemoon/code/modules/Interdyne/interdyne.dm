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
	name = "interdyne biosuit helmet"
	desc = "Шлем биокостюма Interdyne Pharmaceutics, защищающий владельца от биологически опасных материалов."
	icon = 'modular_bluemoon/icons/obj/Interdyne/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/head.dmi'
	icon_state = "ip_biosuit_head"
	item_state = "ip_biosuit_head"
	mutantrace_variation = NONE

/obj/item/clothing/suit/bio_suit/interdyne
	name = "interdyne biosuit"
	desc = "Биокостюм Interdyne Pharmaceutics, защищающий владельца от биологически опасных материалов. Легче обычного биокостюма."
	icon = 'modular_bluemoon/icons/obj/Interdyne/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/Interdyne/suit.dmi'
	icon_state = "ip_biosuit"
	item_state = "ip_biosuit"
	slowdown = 0.3

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


//Viva la InterMothFarm
