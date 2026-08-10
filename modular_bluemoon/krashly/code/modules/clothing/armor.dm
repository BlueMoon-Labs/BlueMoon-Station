/obj/item/clothing/suit/armor/hos/pmc_leader_armor
	name = "M4 pattern PMC leader armor"
	desc = "A modification of the M4 body armor, it is designed for high-profile security operators and corporate mercenaries in mind. This particular suit looks like it belongs to a high-ranking officer."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "officer_armor"
	item_state = "officer_armor"

/obj/item/clothing/suit/donator/bm/cerberus_suit/butler
	name = "butler jacket"
	desc = "White butler jacket."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "butler"
	item_state = "greatcoat"

/obj/item/clothing/head/donator/bm/cerberus_helmet/armored
	armor = list(MELEE = 45, BULLET = 30, LASER = 30,ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 70, ACID = 90, WOUND = 10)
	cold_protection = HEAD
	min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = SPACE_HELM_MAX_TEMP_PROTECT
	clothing_flags = STOPSPRESSUREDAMAGE
	strip_delay = 80

/obj/item/clothing/suit/donator/bm/cerberus_suit/armored
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	armor = list(MELEE = 45, BULLET = 30, LASER = 30, ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 70, ACID = 90, WOUND = 10)
	cold_protection = CHEST|GROIN|LEGS|ARMS
	heat_protection = CHEST|GROIN|LEGS|ARMS
	strip_delay = 80
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/donator/bm/cerberus_suit/armored/censor
	name = "censor's coat"
	desc = "A red overcoat with the coat of arms of Ravenheart in the middle. It has steel plates sewn into it."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "censor"
	item_state = "greatcoat"

/obj/item/clothing/suit/donator/bm/cerberus_suit/armored/baron
	name = "gorgeous red outfit"
	desc = "Lush black outfit with red stripes. Looks definitely very rich."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "baron"
	item_state = "greatcoat"
//////////////////////////////////////////////
/obj/item/clothing/suit/hooded/chaplain_hoodie/monk_robe
	name = "monk robe"
	desc = "Now with a hood."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "monk"
	item_state = "monk"
	hoodtype = /obj/item/clothing/head/hooded/chaplain_hood/monk_robe_hood
//
/obj/item/clothing/head/hooded/chaplain_hood/monk_robe_hood
	name = "monk robe hood"
	desc = "A torn hoodie that fits over your head."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/head.dmi'
	icon_state = "monk_robe_hood"
	item_state = "monk_robe_hood"
	flags_inv = HIDEHAIR|HIDEEARS

/obj/item/clothing/suit/donator/bm/rune_jacket
	name = "rune jacket"
	desc = "Темное пальто исписанное странного вида рунами неизвестного значения. Она чертовски неудобная, как будто шили под кого то."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "deepcoat"
	item_state = "deepcoat"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
////////////////////////////////////////////////
/obj/item/clothing/suit/hooded/plaguedoc_new
	name = "plague doctor robe"
	desc = "Everything will be fine..."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "plaguedoc"
	item_state = "plaguedoc"
	tail_state = "inteq-brown"
	gas_transfer_coefficient = 0.01
	permeability_coefficient = 0.01
	clothing_flags = THICKMATERIAL
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 100, RAD = 75, FIRE = 50, ACID = 100)
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT|HIDETAUR
	strip_delay = 70
	equip_delay_other = 70
	resistance_flags = ACID_PROOF
	hoodtype = /obj/item/clothing/head/hooded/plaguedoc_new
//
/obj/item/clothing/head/hooded/plaguedoc_new
	name = "plague doctor hood"
	desc = "A torn hoodie that fits over your head."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/head.dmi'
	icon_state = "plaguedoc_hood"
	item_state = "plaguedoc_hood"
	flags_inv = HIDEHAIR|HIDEEARS
///////////////////////////////////////////////
obj/item/clothing/suit/donator/bm/cerberus_suit/armored/inkvd
	name = "inquisitor's overcoat"
	desc = "Large overcoat with red embroidery on the sleeves. It also has a cross stitch on it."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "inkvd"
	item_state = "inkvd"

//InteQ//

/obj/item/clothing/suit/armor/inteq
	name = "InteQ armor vest"
	desc = "Strict black armor vest. Well, at least you won't die immediately."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "armor"
	item_state = "armor"

/obj/item/clothing/suit/armor/inteq/honorable_vanguard
	name = "InteQ black armored coat"
	desc = "Lush overcoat with fur around the neck. Has armor plates in its composition."
	icon_state = "armor_inteq_honorable_battlecoat"
	item_state = "armor_inteq_honorable_battlecoat"

/obj/item/clothing/suit/armor/inteq/vanguard
	name = "InteQ armored coat"
	desc = "Lush overcoat with fur around the neck. Has armor plates in its composition."
	icon_state = "armor_vanguard"
	item_state = "armor_vanguard"

/obj/item/clothing/suit/armor/inteq/labcoat
	name = "InteQ armored labcoat"
	desc = "Sterile (or almost) lab coat of the InteQ department for the modernization of existing technologies."
	icon_state = "labcoat_inteq"
	item_state = "labcoat_inteq"

///Winter Coat
/obj/item/clothing/suit/hooded/wintercoat/syndicate/inteq
	name = "InteQ winter coat"
	desc = "A sinister brown coat with black accents and a fancy mantle, it feels like it can take a hit."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "coatinteq"
	item_state = "coatinteq"
	hoodtype = /obj/item/clothing/head/hooded/winterhood/syndicate/inteq
///Hood
/obj/item/clothing/head/hooded/winterhood/syndicate/inteq
	name = "InteQ winter hood"
	desc = "A sinister brown hood with armor padding."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/head.dmi'
	icon_state = "winterhood_inteq"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
///

//InteQ Hardsuits//

//Helmet_ELITE
/obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/inteq
	name = "InteQ elite hardsuit helmet"
	desc = "InteQ elite stormtrooper hardsuit helmet."
	icon_state = "hardsuit0-inteqe"
	item_state = "hardsuit0-inteqe"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/head.dmi'
	hardsuit_type = "inteqe"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
//Suit_ELITE
/obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq
	name = "InteQ elite hardsuit"
	desc = "InteQ elite stormtrooper hardsuit."
	icon_state = "hardsuit0-inteqe"
	item_state = "hardsuit0-inteqe"
	tail_state = "inteq-elite"
	hardsuit_type = "inteqe"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits_digidrated.dmi'
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/inteq

/obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq/equipped(mob/living/user, slot)
	..()
	if(slot == ITEM_SLOT_OCLOTHING)
		if(!IS_INTEQ(user))
			to_chat(user, "<span class='danger'><B>СКАФАНДР МОДЕЛЬ ОДИН - ЩИТ</B>: Обнаружены неавторизованные сигнатуры. <B>Производится нейтрализация пользователя.</B></span>")
			playsound(get_turf(src), 'sound/machines/nuke/confirm_beep.ogg', 65, 1, 1)
			do_sparks(3, 1, src)
			user.dropItemToGround(src, TRUE)
			user.emote("realagony")
			user.adjustFireLoss(50)

//////////

//Helmet_STANDART
/obj/item/clothing/head/helmet/space/hardsuit/syndi/inteq
	name = "InteQ hardsuit helmet"
	desc = "InteQ stormtrooper hardsuit helmet."
	icon_state = "hardsuit0-inteq"
	item_state = "hardsuit0-inteq"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/head.dmi'
	hardsuit_type = "inteq"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
//Suit_STANDART
/obj/item/clothing/suit/space/hardsuit/syndi/inteq
	name = "InteQ hardsuit"
	desc = "InteQ stormtrooper hardsuit."
	icon_state = "hardsuit0-inteq"
	item_state = "hardsuit0-inteq"
	tail_state = "inteq"
	hardsuit_type = "inteq"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits_digidrated.dmi'
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/syndi/inteq

//////////

//Helmet_ALLIANCE
/obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/alliance
	name = "OTA Hardsuit Helmet"
	desc = "OTA stormtrooper hardsuit helmet."
	icon_state = "hardsuit0-alliance"
	item_state = "hardsuit0-alliance"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/head.dmi'
	hardsuit_type = "alliance"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
//Suit_ALLIANCE
/obj/item/clothing/suit/space/hardsuit/syndi/elite/alliance
	name = "OTA Hardsuit"
	desc = "OTA Stormtrooper Hardsuit."
	icon_state = "hardsuit-alliance"
	item_state = "hardsuit-alliance"
	tail_state = "hardsuit-winter"
	hardsuit_type = "alliance"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/syndi/elite/alliance

//////////

//Helmet_SHIELDED
/obj/item/clothing/head/helmet/space/hardsuit/shielded/syndi/inteq
	name = "InteQ shielded hardsuit helmet"
	desc = "InteQ shielded stormtrooper hardsuit helmet."
	icon_state = "hardsuit0-inteq"
	item_state = "hardsuit0-inteq"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/head.dmi'
	hardsuit_type = "inteq"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
//Suit_SHIELDED
/obj/item/clothing/suit/space/hardsuit/shielded/syndi/inteq
	name = "InteQ shielded hardsuit"
	desc = "InteQ shielded stormtrooper hardsuit."
	icon_state = "hardsuit0-inteq"
	item_state = "hardsuit0-inteq"
	tail_state = "inteq"
	hardsuit_type = "inteq"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits_digidrated.dmi'
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/shielded/syndi/inteq
	shield_state = "shield-yellow"

/obj/item/clothing/suit/space/hardsuit/shielded/syndi/inteq/equipped(mob/living/user, slot)
	..()
	if(slot == ITEM_SLOT_OCLOTHING)
		if(!IS_INTEQ(user))
			to_chat(user, "<span class='danger'><B>СКАФАНДР МОДЕЛЬ ОДИН - ЩИТ</B>: Обнаружены неавторизованные сигнатуры. <B>Производится нейтрализация пользователя.</B></span>")
			playsound(get_turf(src), 'sound/machines/nuke/confirm_beep.ogg', 65, 1, 1)
			do_sparks(3, 1, src)
			user.dropItemToGround(src, TRUE)
			user.emote("realagony")
			user.adjustFireLoss(50)

/obj/item/clothing/suit/space/hardsuit/shielded/syndi/inteq/proc/explode()
	do_sparks(3, 1, src)
	explosion(src.loc,0,1,1,1)
	qdel(src)

//////////

///Kovac added
////InteQ spacesuit
/obj/item/clothing/head/helmet/space/syndicate/inteq
	name = "brown space helmet"
	icon_state = "space-inteq"
	item_state = "space-inteq"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/head.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/space/syndicate/inteq
	name = "brown space suit"
	icon_state = "space-inteq"
	item_state = "space-inteq"
	tail_state = "inteq-brown"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/suits_digidrated.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC|STYLE_PAW_TAURIC
