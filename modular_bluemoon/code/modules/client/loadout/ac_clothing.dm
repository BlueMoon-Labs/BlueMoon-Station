//					ГОЛОВА					//
//					ГОЛОВА					//
//					ГОЛОВА					//

/obj/item/clothing/head/soft/sec/ac
	name = "AC Cap"
	desc = "Special cap for special Mercenaries."
	icon = 'modular_bluemoon/icons/obj/clothing/ac_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/ac_clothing.dmi'
	icon_state = "acsoft"
	soft_type = "ac"

/obj/item/clothing/head/warden/ac
	name = "AC Officer Cap"
	desc = "Special cap for special Mercenaries."
	icon = 'modular_bluemoon/icons/obj/clothing/ac_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/ac_clothing.dmi'
	icon_state = "ac_officer"

/obj/item/clothing/head/beret/sec/ac
	name = "AC Beret"
	desc = "Beret for Mercenaries with special reinforced fabric to offer some protection."
	icon = 'modular_bluemoon/icons/obj/clothing/ac_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/ac_clothing.dmi'
	icon_state = "ac_beret"

//					КОСТЮМЫ					//
//					КОСТЮМЫ					//
//					КОСТЮМЫ					//

/obj/item/clothing/suit/toggle/captains_parade/hos_formal/ac
	name = "AC Armored Coat"
	desc = "An coat for a prestigious Mercenaries in the Adamas Cattus PMC."
	icon = 'modular_bluemoon/icons/obj/clothing/ac_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/ac_clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/ac_clothing.dmi'
	icon_state = "ac_coat"

//					УНИФОРМА					//
//					УНИФОРМА					//
//					УНИФОРМА					//

/obj/item/clothing/under/rank/security/officer/ac
	name = "AC Tanktop Uniform"
	desc= "An uniform for very special Mercenaries, sometimes they prefer to drink beer more then water."
	icon = 'modular_bluemoon/icons/obj/clothing/ac_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/ac_clothing.dmi'
	icon_state = "ac_tanktop"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	can_adjust = FALSE
	unique_reskin = null

/obj/item/clothing/under/rank/security/officer/ac/ac_combatuni
	name = "AC Combat Uniform"
	desc= "Standart tactical uniform for Mercencary in Catcrin PMC Adamas Cattus."
	icon_state = "ac_turtleneck"

/obj/item/clothing/under/rank/security/officer/ac/ac_combatski
	name = "AC Combat Skirt"
	desc= "Standart tactical skirt for Mercenary in Catcrin PMC Adamas Cattus."
	icon_state = "ac_turtleneck_skirt"

/obj/item/clothing/under/rank/security/officer/ac/ac_cassuit
	name = "AC Casual Uniform"
	desc= "Casual suit for special operations for Mercenaries in Adamas Cattus."
	icon_state = "ac_uni"

/obj/item/clothing/under/rank/security/officer/ac/ac_casski
	name = "AC Casual Skirt"
	desc= "Casual skirt for special operations for Mercenaries in Adamas Cattus."
	icon_state = "ac_uni_skirt"

/obj/item/clothing/suit/toggle/captains_parade/hos_formal/ac/invisible
	name = "Invisible Armored Coat"
	desc = "Кто-то очень сильно хотел светить своими телесами, даже через броню. Специально для такого случая - модифицированный хамелеон-плащ для всех 50-ти оттенков эгсбиционистов в рядах командования и силовых структур."
	icon = 'modular_splurt/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/suit.dmi'
	icon_state = "jacket_transparent"
	item_state = "jacket_transparent"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	var/current_mode = "jacket_transparent"

/obj/item/clothing/suit/toggle/captains_parade/hos_formal/ac/invisible/AltClick(mob/user)
	if(current_mode == "jacket_transparent")
		if(!istype(loc, /mob/living/carbon/human))
			return
		name = "Concord Modified Armored Coat"
		desc = "Халат для важных бумажных. Для создания таких используется вариант бронеплиты-халата службы безопасности. На подсумки же, увы, не хватило бюджета, зато тело в тепле."
		var/mob/living/carbon/human/wearer = loc
		var/obj/item/organ/genital/breasts/breast = wearer.getorganslot(ORGAN_SLOT_BREASTS)
		var/breast_size = clamp(round(breast?.size || 0)-1, 0, 7)
		icon_state = "concord_armored_coat_[breast_size]"
		item_state = "concord_armored_coat_[breast_size]"
		current_mode = "concord_armored_coat"
		update_icon()
	else
		name = "Invisible Armored Coat"
		desc = "Кто-то очень сильно хотел светить своими телесами, даже через броню. Специально для такого случая - модифицированный хамелеон-плащ для всех 50-ти оттенков эгсбиционистов в рядах командования и силовых структур."
		icon_state = "jacket_transparent"
		item_state = "jacket_transparent"
		current_mode = "jacket_transparent"
		update_icon()
	user.update_inv_wear_suit()
	user.update_body()

/obj/item/clothing/suit/toggle/captains_parade/hos_formal/ac/invisible/equipped(mob/user, slot) //оверрайдим этот прок, дабы у нас вызывалась обнова иконки в момент одевания
	. = ..()
	if(slot != ITEM_SLOT_OCLOTHING)
		return
	update_icon()

/obj/item/clothing/suit/toggle/captains_parade/hos_formal/ac/invisible/update_icon_state()
	. = ..()
	if(!istype(loc, /mob/living/carbon/human))
		return
	var/mob/living/carbon/human/H = loc
	if(current_mode == "jacket_transparent")
		icon_state = "jacket_transparent"
	else if(current_mode == "concord_armored_coat")
		var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
		var/breast_size = clamp(round(B?.size || 0)-1, 0, 7)
		icon_state = "concord_armored_coat_[breast_size]"
	H.update_inv_wear_suit()
	H.update_body()
