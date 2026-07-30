/obj/machinery/limbgrower/Initialize(mapload)
	var/list/extra_cat = list(
		"shadekin",
		"teshari"
	)
	LAZYADD(categories, extra_cat)
	. = ..()

/datum/species/mammal/shadekin
	limbs_id = SPECIES_SHADEKIN
	icon_limbs = DEFAULT_BODYPART_ICON_ORGANIC

/datum/species/mammal/teshari
	limbs_id = SPECIES_TESHARI
	icon_limbs = 'modular_splurt/icons/mob/teshari.dmi'
	icon_accessories = 'modular_splurt/icons/mob/clothing/species/teshari/accessories.dmi'
	icon_back = 'modular_splurt/icons/mob/clothing/species/teshari/back.dmi'
	icon_belt = 'modular_splurt/icons/mob/clothing/species/teshari/belt.dmi'
	icon_ears = 'modular_splurt/icons/mob/clothing/species/teshari/ears.dmi'
	icon_eyes = 'modular_splurt/icons/mob/clothing/species/teshari/eyes.dmi'
	icon_feet = 'modular_splurt/icons/mob/clothing/species/teshari/feet.dmi'
	icon_feet64 = 'modular_splurt/icons/mob/clothing/species/teshari/feet_64.dmi'
	icon_hands = 'modular_splurt/icons/mob/clothing/species/teshari/hands.dmi'
	icon_head = 'modular_splurt/icons/mob/clothing/species/teshari/head.dmi'
	icon_mask = 'modular_splurt/icons/mob/clothing/species/teshari/mask.dmi'
	icon_neck = 'modular_splurt/icons/mob/clothing/species/teshari/neck.dmi'
	icon_uniform = 'modular_splurt/icons/mob/clothing/species/teshari/uniform.dmi'
	icon_suit = 'modular_splurt/icons/mob/clothing/species/teshari/suit.dmi'

// Блок иконок для /datum/species/vox убран: этот путь в BlueMoon не является видом.
// Игровой вокс - /datum/species/mammal/vox (modular_bluemoon/kovac_shitcode/code/vox.dm),
// а полное splurt-определение /datum/species/vox в tgstation.dme не подключено. Из-за
// этого блока тип всё равно существовал, но без id - и попадал в GLOB.species_list по
// ключу null, роняя пикеры видов. Сами спрайты при этом никому не применялись: у
// mammal/vox свои icon_eyes/icon_head/icon_mask. Если splurt-набор одежды воксам нужен,
// его надо переносить в mammal/vox осознанно - это уже смена визуала, а не фикс.
