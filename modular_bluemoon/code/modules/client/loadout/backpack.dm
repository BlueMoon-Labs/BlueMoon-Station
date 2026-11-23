/datum/gear/backpack/ring_gold
	name = "A golden ring (without box)"
	path = /obj/item/clothing/accessory/ring
	cost = 3

/datum/gear/backpack/ring_silver
	name = "A silver ring (without box)"
	path = /obj/item/clothing/accessory/ring/silver
	cost = 3

/datum/gear/backpack/ring_diamond
	name = "A diamond ring (without box)"
	path = /obj/item/clothing/accessory/ring/diamond
	cost = 5

/datum/gear/backpack/hcaarmband
    name = "HCA armband"
    subcategory = LOADOUT_SUBCATEGORY_BACKPACK_GENERAL
    path = /obj/item/clothing/accessory/armband/hcaarmband

/datum/gear/backpack/flat_chastity_box
	name = "Flat Chastity Box"
	path = /obj/item/storage/box/chastity_cage/flat

/datum/gear/backpack/fancy_maid_kit
	name = "fancy maid kit"
	path = /obj/item/storage/box/fancy_maid_kit

/datum/gear/backpack/black_tape
	name = "Black Sticky Tape"
	path = /obj/item/stack/sticky_tape/black

/datum/gear/backpack/dildo_huge
	name = "Huge dildo"
	path = /obj/item/dildo/flared/huge
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/fleshlight
	name = "Fleshlight"
	path = /obj/item/fleshlight
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/portallight
	name = "Портальный Фонарик"
	path = /obj/item/portallight
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/portallight_box
	name = "Portal Fleshlight and Underwear"
	path = /obj/item/storage/box/portallight
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/vibrator
	name = "Remote vibrator"
	path = /obj/item/electropack/vibrator
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/vibrator_small
	name = "Small Remote vibrator"
	path = /obj/item/electropack/vibrator/small
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/signaler
	name = "Remote signaling device"
	path = /obj/item/assembly/signaler
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS
	cost = 0 //Vibrators need them anyways

/datum/gear/backpack/timer
	name = "Timer"
	path = /obj/item/assembly/timer
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS
	cost = 0 //Vibrators need them anyways

/datum/gear/backpack/sounding
	name = "Уретральный стержень"
	path = /obj/item/genital_equipment/sounding
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/urethral_plug
	name = "Уретральная пробка"
	path = /obj/item/genital_equipment/urethral_plug
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/aphrodisiac_pump_plus
	name = "Hexacrocin pump box"
	path = /obj/item/storage/box/aphrodisiac_pump/plus
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS
	cost = 4 //More powerful than a regular one

/datum/gear/backpack/aphrodisiac_pump
	name = "Crocin pump box"
	path = /obj/item/storage/box/aphrodisiac_pump
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/bdsm_whip
	name = "BDSM whip"
	path = /obj/item/bdsm_whip
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/ridingcrop
	name = "Riding crop"
	path = /obj/item/bdsm_whip/ridingcrop
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/belt_belly_riding
	name = "belly riding harness"
	path = /obj/item/storage/belt/belly_riding
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/strapon_strap
	name = "Strapon strap"
	path = /obj/item/strapon_strap
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/latex_key
	name = "Latex Adjustment Override"
	path = /obj/item/key/latex
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/buttplug/small
    name = "Small buttplug"
    path = /obj/item/buttplug/small
    subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/buttplug/medium
    name = "Medium buttplug"
    path = /obj/item/buttplug/med
    subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/buttplug/big
    name = "Big buttplug"
    path = /obj/item/buttplug/big
    subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS

/datum/gear/backpack/flag
	name = "Flag"
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_GENERAL
	path = /obj/item/sign/flag

/datum/gear/backpack/sol_poster
	name = "SolFed poster"
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_GENERAL
	path = /obj/item/poster/sol

/datum/gear/backpack/nri_poster
	name = "NRI poster"
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_GENERAL
	path = /obj/item/poster/nri

/datum/gear/backpack/armyknife
	name = "Army Multitool"
	path = /obj/item/armyknife
	cost = 3

/datum/gear/backpack/clipboard
	name = "Clipboard"
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_GENERAL
	path = /obj/item/clipboard

/datum/gear/backpack/shockcollar
	name = "Shock Collar Kit"
	path = /obj/item/storage/box/shockcollar
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS
	cost = 2

/datum/gear/accessory/hippads
	name = "adjustable hip pads box"
	path = /obj/item/storage/box/hippads
	cost = 0

/datum/gear/backpack/prescription
	var/base_price = PRICE_EXPENSIVE // базовая цена покупки рецепта в вендомате
	var/list/base_valid_traits = list() // список трейтов валидных для законного использования воучера
	var/base_fortune_delivery = 5 // шанс с которым вместо рецепта при спавне будет выдан сразу продукт
	var/received_product // путь выдаваемого предмета при активации в мед вендомате
	/// NVD - Non Valid User
	var/NVD_price = PRICE_REALLY_EXPENSIVE // цена покупки рецепта не имея правильных квирков
	var/NVD_suspicious = 5 // шанс, что не имея правильных квирков рецепт при использовании выдаст штраф за кантробанду (подделку документов)
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_GENERAL
	path = /obj/item/card/voucher

/datum/gear/backpack/prescription/on_spawn(mob/living/carbon/human/user, obj/item/card/voucher/I)
	if(!istype(user))
		return
	addtimer(CALLBACK(src, PROC_REF(handle_late_spawn), user, I), 1 SECONDS)

/datum/gear/backpack/prescription/proc/handle_late_spawn(mob/living/carbon/human/user, obj/item/card/voucher/I)
	if(isnull(I) || isnull(user))
		return
	var/I_loc = I.loc
	qdel(I) // заглушка которая должная умереть
	var/counterfeit = TRUE
	for(var/quirk in base_valid_traits)
		if(HAS_TRAIT(user, quirk))
			counterfeit = FALSE
			break

	if(!counterfeit && prob(base_fortune_delivery))
		new received_product(I_loc)
		return

	var/used_price = counterfeit ? NVD_price : base_price
	new path(I_loc, received_product, used_price, NVD_suspicious)

/datum/gear/backpack/prescription/psicodine
	name = "Psicodine pill bottle prescription"
	description = "Рецептурный воучер на покупку в NanoMed Plus резервной банки псикодина за 325 кредитов. Воучер взятый без квирков депрессии или монофобии стоит 700 кредитов, а вместе с тем может быть и вовсе поддельным, активируя автоматизированную систему записи нарушений."
	cost = 1

	base_valid_traits = list(TRAIT_DEPRESSION, TRAIT_MONOPHOBIA)
	received_product = /obj/item/storage/pill_bottle/psicodine
	NVD_suspicious = 20

/datum/gear/backpack/prescription/lsd
	name = "LSD pill bottle prescription"
	description = "Рецептурный воучер на покупку в NanoMed Plus резервной банки ЛСД за 325 кредитов. Воучер взятый без квирка на диссоциативное расстройство стоит 700 кредитов, а вместе с тем может быть и вовсе поддельным, активируя автоматизированную систему записи нарушений."
	cost = 1

	base_valid_traits = list(TRAIT_INSANITY)
	received_product = /obj/item/storage/pill_bottle/lsdpsych
	NVD_suspicious = 40
