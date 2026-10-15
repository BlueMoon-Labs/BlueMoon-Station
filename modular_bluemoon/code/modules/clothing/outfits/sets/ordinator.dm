// Тут содержатся все вещи Ординаторов Трибунала
/obj/item/clothing/under/syndicate/ordinator
	name = "tribunal enlisted uniform"
	desc = "Standard uniform for Nanotrasen Ordinator Tribunal."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniforms.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|USE_TAUR_CLIP_MASK|STYLE_NO_ANTHRO_ICON
	icon_state = "ordinator"
	armor_type = /datum/armor/under_ordinator
	alt_covers_chest = FALSE
	can_adjust = FALSE

/obj/item/clothing/under/syndicate/ordinator/leader
	name = "tribunal officer uniform"
	desc = "Standard uniform for Nanotrasen Ordinator Tribunal. This one is all covered in gold stripes."
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniforms.dmi'
	icon_state = "ordinatorLT"
	armor_type = /datum/armor/under_leader


/obj/item/clothing/suit/armor/hos/ordinator
	name = "flak jacket"
	desc = "A jacket that excels in protecting the wearer against high-velocity solid projectiles."
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "flakjacket"
	item_state = "greatcoat"
	tail_state = "none"
	body_parts_covered = CHEST|GROIN
	cold_protection = CHEST|GROIN|LEGS|ARMS
	heat_protection = CHEST|GROIN|LEGS|ARMS
	armor_type = /datum/armor/suit_ordinator

/obj/item/clothing/suit/armor/hos/ordinator/leader
	name = "coat flak jacket"
	desc = "A greatcoat that excels in protecting the wearer against high-velocity solid projectiles."
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "coatjacket"
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	cold_protection = CHEST|GROIN|LEGS|ARMS
	heat_protection = CHEST|GROIN|LEGS|ARMS
	armor_type = /datum/armor/suit_leader
	brc_mitigation_bonus = 20  // BLUEMOON ADD

/obj/item/clothing/mask/gas/atmos/lfwb
	name = "gas mask"
	desc = "A face-covering mask that can be connected to an air supply. filters harmful gases from the air."
	icon = 'modular_bluemoon/icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/masks.dmi'
	mutantrace_variation = STYLE_MUZZLE|STYLE_NO_ANTHRO_ICON
	icon_state = "gas_mask"
	item_state = "gas_mask"

/obj/item/clothing/glasses/hud/security/lfwb
	name = "security tribunal HUD"
	desc = "A head-up display that scans people in the field of view and provides accurate data about their identification status and security records."
	icon = 'modular_bluemoon/icons/obj/clothing/glasses.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/eyes.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	icon_state = "securityhud"

/obj/item/clothing/head/helmet/knight/ordinator
	name = "tribunal ordinator helmet"
	desc = "Standard issue helmet worn by Tribunal Ordinators. Theft of Tribunal equipment is punishable by death."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	mutantrace_variation = STYLE_MUZZLE|STYLE_NO_ANTHRO_ICON
	icon_state = "ordinator_helmet"
	item_state = "ordinator_helmet"
	armor_type = /datum/armor/head_ordinator
