// BLUEMOON ADD START - HUD разрешений на оружие (порт Skyrat company_imports)
/datum/atom_hud/data/human/permit
	hud_icons = list(PERMIT_HUD)

/// Какую иконку покажет permit-худа на этом человеке. Зеркалит логику permit_pin:
/// доступ ACCESS_WEAPONS на ID или прикреплённое бумажное разрешение.
/mob/living/carbon/human/proc/get_gun_permit_iconstate()
	var/obj/item/card/id/id_card = wear_id?.GetID() || wear_neck?.GetID()
	if(id_card && (ACCESS_WEAPONS in id_card.GetAccess()))
		return "hud_permit"
	var/obj/item/clothing/under/the_uniform = w_uniform
	if(the_uniform)
		for(var/obj/item/clothing/accessory/permit/permit in the_uniform.accessories_attached)
			if(permit.authorizes_user(src))
				return "hud_permit"
	return "hudfan_no"

/obj/item/clothing/glasses/hud/gun_permit
	name = "permit HUD"
	desc = "A heads-up display that scans humanoids in view, and displays if their current ID possesses a firearms permit or not."
	icon = 'modular_bluemoon/icons/obj/clothing/hud_goggles.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hud_goggles_worn.dmi'
	icon_state = "permithud"
	hud_type = DATA_HUD_PERMIT

/obj/item/clothing/glasses/hud/gun_permit/sunglasses
	name = "permit HUD sunglasses"
	desc = "A pair of sunglasses with a heads-up display that scans humanoids in view, and displays if their current ID possesses a firearms permit or not."
	flash_protect = 1
	tint = 1

/datum/design/permit_hud
	name = "Gun Permit HUD glasses"
	desc = "A heads-up display that scans humanoids in view, and displays if their current ID possesses a firearms permit or not."
	id = "permit_glasses"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT, /datum/material/glass = HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/glasses/hud/gun_permit
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_CARGO
// BLUEMOON ADD END