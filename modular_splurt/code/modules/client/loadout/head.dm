// removes resricted role for D.A.B. helmets. RIP N.E.E.T. gear as exclusive for assistants (2019-2021).
/datum/gear/head/neethelm
	subcategory = LOADOUT_SUBCATEGORY_SUIT_GENERAL
	restricted_roles = list()

// Updates restrictions to accomodate new jobs (mostly trekkie stuff)
/datum/gear/head/brodie
	restricted_roles = list("Security Officer", "Warden", "Head of Security", "Brig Physician", "Blueshield")

/datum/gear/head/trekcapcap
	restricted_roles = list("Captain","Head of Personnel","Blueshield")

/datum/gear/head/trekcapmedisci
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist", "Brig Physician")

/datum/gear/head/trekcapsec
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Warden","Detective","Security Officer","Brig Physician","Blueshield","Bridge Officer")

/datum/gear/head/orvkepicom
	restricted_roles = list("Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Chief Engineer", "Research Director", "Chief Medical Officer", "Quartermaster", "Bridge Officer")

/datum/gear/head/orvkepisec
	restricted_roles = list("Warden", "Detective", "Security Officer", "Head of Security", "Brig Physician", "Blueshield")

/datum/gear/head/orvkepimedsci
	restricted_roles = list("Chief Medical Officer", "Medical Doctor", "Chemist", "Virologist", "Paramedic", "Geneticist", "Research Director", "Scientist", "Roboticist", "Brig Physician")

/datum/gear/head/cowboyhat/sec
description = "Обычная коричневая ковбойская шляпа, йи-хау."
	restricted_roles = list("Warden","Detective","Security Officer","Head of Security", "Brig Physician", "Blueshield")

// Polychrome GWTB
/datum/gear/head/gonerhelm
	name = "polychromic trencher helmet"
	description = "Пластиковый шлем с полихромным пятном. Защищает как разве что коробка из-под бомбоубежища."
	cost = 2
	path = /obj/item/clothing/head/helmet/goner/fake/poly
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#D9D9D9")

/datum/gear/head/goneroffcap
	name = "polychromic trencher officer cap"
	description = "Дешёвая офицерская фуражка с полихромной заколкой."
	cost = 2
	path = /obj/item/clothing/head/helmet/goner/officer/fake/poly
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#F2F2F2")

/datum/gear/head/goneroffcap/classic
	name = "polychromic trencher officer cap (classic)"
	description = "Дешёвая офицерская фуражка с полихромной заколкой."
	path = /obj/item/clothing/head/helmet/goner/officer/fake/poly/classic

//Adds bowler hats
/datum/gear/head/bowler
	name = "Bowler-hat"
	description = "Господа, элита на борту!"
	cost = 1
	path = /obj/item/clothing/head/bowler

//Adds medical beret
/datum/gear/head/medberet
	name = "Medical officer's beret"
	description = "Нарядный берет с синим крестом — пахнет стерильностью."
	cost = 1
	path = /obj/item/clothing/head/beret/med
	restricted_roles = list("Chief Medical Officer", "Medical Doctor", "Chemist", "Virologist", "Paramedic", "Geneticist", "Brig Physician")
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS

//Adds the three basic flowers that can be pinned into the hair
/datum/gear/head/poppy
	name = "Poppy"
	description = "Давно служит символом покоя, мира и смерти."
	cost = 2
	path = /obj/item/reagent_containers/food/snacks/grown/poppy

/datum/gear/head/lily
	name = "Lily"
	description = "Красивый оранжевый цветок."
	cost = 2
	path = /obj/item/reagent_containers/food/snacks/grown/poppy/lily

/datum/gear/head/geranium
	name = "Geranium"
	description = "Красивый синий цветок."
	cost = 2
	path = /obj/item/reagent_containers/food/snacks/grown/poppy/geranium

/datum/gear/head/deckers
	name = "Decker Headphones"
	description = "Сладкая пара наушников."
	cost = 2
	path = /obj/item/clothing/head/deckers

/datum/gear/head/invisihat
	name = "invisifiber hat"
	description = "Шляпа из прозрачных волокон, часто используется с комплектами усиления."
	path = /obj/item/clothing/head/invisihat

/datum/gear/head/clussy_wig
	name = "Clussy wig"
	description = "Ношение этого заставит твою п...ду гудеть..."
	path = /obj/item/clothing/head/clussy_wig
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_roles = list("Clown")
	restricted_desc = "Clown"

/datum/gear/head/hoodcowl
	name = "Hood cowl"
	description = "Грязная, истёртая тряпка с грубо вырезанными дырками для глаз — одеждой это называется с большой натяжкой."
	path= /obj/item/clothing/head/hoodcowl

// BM add
/datum/gear/head/syndiewarden/civilian
    name = "Master At Arms' Police Hat"
    description = "Модная полицейская фуражка с золотым значком, выдаётся старшине. Защищает голову от ударов."
    path = /obj/item/clothing/head/hats/warden/syndicate/civil

/datum/gear/head/syndieberet/civil
    name = "brig officer's beret"
    description = "Стильный и защищающий берет, произведённый Interdyne Pharmaceuticals при помощи Gorlex Marauders."
    path = /obj/item/clothing/head/beret/sec/syndicate/civil

/datum/gear/head/syndieutility/civil
    name = "engine tech utility cover"
    description = "Рабочий головной убор техника двигателей, с биркой «IP-DS-2»."
    path = /obj/item/clothing/head/soft/sec/syndicate/civil

/datum/gear/head/swatds/civilian
    name = "SWAT helmet"
    description = "Прочный пригодный для космоса шлем с маленьким крестом и надписью «IP» на амбушюре."
    path = /obj/item/clothing/head/helmet/swat/ds/civil

/datum/gear/head/npc_questhuh_hat
    name = "NPC Huh hat"
    description = "Шляпа, похожая на большой вопросительный знак..."
    path = /obj/item/clothing/head/npc_questhuh_hat

/datum/gear/head/npc_questhey_hat
    name = "NPC Hey hat"
    description = "Шляпа, похожая на большой восклицательный знак..."
    path = /obj/item/clothing/head/npc_questhey_hat

//BM add end
