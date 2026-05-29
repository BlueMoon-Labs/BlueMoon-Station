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
	name = "Invisible AC Armored Coat"
	desc = "Кто-то очень сильно хотел светить своими телесами, даже через броню. Специально для такого случая - модифицированный хамелеон-плащ для всех 50-ти оттенков эгсбиционистов в рядах командования и силовых структур."
	icon = 'modular_splurt/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/suit.dmi'
	icon_state = "jacket_transparent"
	item_state = "jacket_transparent"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
