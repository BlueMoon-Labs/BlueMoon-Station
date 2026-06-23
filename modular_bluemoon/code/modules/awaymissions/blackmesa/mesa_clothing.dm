/obj/item/clothing/shoes/bhop/blackops
	name = "Aperture science blackops jumpboots"
	desc = "Эти ботинки позволяют пользователю совершать прыжки на большие расстояния исключая всякий урон от падения."
	icon = 'modular_splurt/icons/obj/clothing/shoes.dmi'
	icon_state = "jackboots-tall"
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/shoes_digi.dmi'
	resistance_flags = ACID_PROOF
	cold_protection = FALSE
	min_cold_protection_temperature = FALSE
	heat_protection = FALSE
	max_heat_protection_temperature = FALSE
	unique_reskin = list(
		"Advanced" = list("icon_state" = "jackboots-heels-tall"),
	)
	jumpdistance = 6
	jumpspeed = 4
	recharging_rate = 70
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/shoes

/obj/item/clothing/glasses/night/blackops
	name = "Black operative night vision goggles"
	desc = "Линзы этих очков угрожающе горят красным цветом."
	icon = 'modular_bluemoon/icons/obj/clothing/glasses.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/eyes.dmi'
	icon_state = "blackopsnight"
	item_state = "blackopsnight"
	darkness_view = 8
	flash_protect = -2
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	color_cutoffs = list(30, 8, 5)
	glass_colour_type = /datum/client_colour/glass_colour/red
	alternate_worn_layer = ABOVE_HEAD_LAYER

/obj/item/clothing/glasses/night/blackops/update_icon_state()
	. = ..()
	icon_state = length(color_cutoffs) ? initial(icon_state) : "night_off"

/obj/item/clothing/suit/blackops
	name = "Black operative special armor"
	desc = "Почему нам всегда приходится убирать дерьмо, с которым не могут справиться пехотинцы?"
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "blackops"
	item_state = "blackops"
	allowed = list(/obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman)
	armor = list(MELEE = 30, BULLET = 40, LASER = 5, ENERGY = 0, BOMB = 20, BIO = 15, RAD = 5, FIRE = 5, ACID = 20)
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

//obj/item/clothing/glasses/welding/hecu
//	name = "welding goggles"
//	desc = "Защищает твои полные инженерным энтузиазмом глаза от слепоты"
//	icon = 'modular_bluemoon/icons/obj/clothing/glasses.dmi'
//	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/eyes.dmi'
//	icon_state = "hecu_engineer"
//	item_state = "hecu_engineer"
//Оставил код вырезанных очков (возможно я их когда-то смогу починить)

/obj/item/clothing/glasses/hud/health/sunglasses/hecu
	name = "aperture science special medical glasses"
	desc = "Модифицированные aperture science очки! Они помогают определять текущее состояние пациента.. И они точно не позволяют определить количество занaвесок для душа в секторе"
	icon_state = "glasses"
	darkness_view = 1
	flash_protect = 1
	tint = 1
	glass_colour_type = /datum/client_colour/glass_colour/blue


/obj/item/clothing/glasses/hud/security/hecu_ski
	name = "HECU ski glasses"
	desc = "Урбанистическая горнолыжная маска с обширным функционалом, разработанная специально для операций в городских местностях. Так-же отлично подходят для совершения военных преступлений на территории чёрной мезы"
	icon = 'modular_bluemoon/icons/obj/clothing/glasses.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/eyes.dmi'
	icon_state = "ski_hecu"
	item_state = "ski_hecu"
	alternate_worn_layer = ABOVE_HEAD_LAYER
