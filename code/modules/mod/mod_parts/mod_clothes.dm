/obj/item/clothing/mod_part/head
	name = "MOD helmet"
	desc = "Шлем для MOD-костюма."
	icon = 'modular_bluemoon/icons/obj/clothing/modsuit/mod_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/modsuit/mod_clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/modsuit/mod_clothing_anthro.dmi'
	icon_state = "helmet"
	item_state = "helmet"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, FIRE = 25, ACID = 25, WOUND = 10)
	body_parts_covered = HEAD
	heat_protection = HEAD
	cold_protection = HEAD
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	clothing_flags = THICKMATERIAL|ALLOWINTERNALS
	resistance_flags = NONE
	flash_protect = 0
	flags_inv = HIDEFACIALHAIR
	flags_cover = NONE
	visor_flags = THICKMATERIAL|STOPSPRESSUREDAMAGE
	visor_flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR
	visor_flags_cover = HEADCOVERSMOUTH|HEADCOVERSEYES
	item_flags = IMMUTABLE_SLOW
	can_be_reinforced = FALSE
	var/alternate_layer = NECK_LAYER
	mutantrace_variation = STYLE_MUZZLE
	theme_category = HELMET_FLAGS
	slot_flags = ITEM_SLOT_HEAD
	var/vision_flags
	var/blockTracking = 0
	var/darkness_view = 2
	var/lighting_alpha
	var/lighting_cutoff = null
	var/list/color_cutoffs = null

/obj/item/clothing/mod_part/head/update_flags(list/used_skin)
	. = ..()
	alternate_worn_layer = used_skin["HELMET_LAYER"]
	alternate_layer = used_skin["HELMET_LAYER"]

/obj/item/clothing/mod_part/head/seal_part(seal)
	. = ..()
	if(seal)
		alternate_worn_layer = null
	else
		alternate_worn_layer = alternate_layer
	mod?.wearer?.update_inv_head()
	mod?.wearer?.update_inv_wear_mask()
	mod?.wearer?.update_hair()

//Дать на альт-клик отображать глаза поверх шлема.
/obj/item/clothing/mod_part/suit
	name = "MOD chestplate"
	desc = "Нагрудник для MOD-костюма."
	icon = 'modular_bluemoon/icons/obj/clothing/modsuit/mod_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/modsuit/mod_clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/modsuit/mod_clothing_anthro.dmi'
	icon_state = "chestplate"
	item_state = "chestplate"
	tail_state = ""
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, FIRE = 25, ACID = 25, WOUND = 10)
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	heat_protection = CHEST|GROIN|LEGS|ARMS
	cold_protection = CHEST|GROIN|LEGS|ARMS
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	clothing_flags = THICKMATERIAL
	visor_flags = STOPSPRESSUREDAMAGE
	visor_flags_inv = HIDEJUMPSUIT
	item_flags = IMMUTABLE_SLOW
	can_be_reinforced = FALSE
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/device/cooler)
	resistance_flags = NONE
	mutantrace_variation = STYLE_DIGITIGRADE
	theme_category = CHESTPLATE_FLAGS
	slot_flags = ITEM_SLOT_OCLOTHING
	var/taur_types_icon_whitelist = alist(	"_canine" = list("Canine", "Feline", "Eevee", "Virgo - Synthetic Feline",\
																"Virgo - Synthetic Feline (Inverted)", "Virgo - Synthetic Wolf", "Virgo - Synthetic Wolf (Inverted)"),)
	var/fire_resist = T0C+100
	var/blood_overlay_type = "armor"

/obj/item/clothing/mod_part/suit/seal_part(seal)
	. = ..()
	mod?.wearer?.update_inv_wear_suit()
	mod?.wearer?.update_inv_w_uniform()

/obj/item/clothing/mod_part/gloves
	name = "MOD gauntlets"
	desc = "Пара рукавиц для MOD-костюма."
	icon = 'modular_bluemoon/icons/obj/clothing/modsuit/mod_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/modsuit/mod_clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/modsuit/mod_clothing_anthro.dmi'
	icon_state = "gauntlets"
	item_state = "gauntlets"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, FIRE = 25, ACID = 25, WOUND = 10)
	body_parts_covered = HANDS|ARMS
	heat_protection = HANDS|ARMS
	cold_protection = HANDS|ARMS
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	clothing_flags = THICKMATERIAL
	resistance_flags = NONE
	item_flags = IMMUTABLE_SLOW
	can_be_reinforced = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	theme_category = GAUNTLETS_FLAGS
	slot_flags = ITEM_SLOT_GLOVES
	var/datum/component/tackler/gloves_tackler
	var/transfer_blood = FALSE
	var/transfer_prints = FALSE

	var/saved_siemens_coefficient

/obj/item/clothing/mod_part/gloves/Destroy()
	clear_mod_tackler_component()
	. = ..()

/obj/item/clothing/mod_part/gloves/proc/clear_mod_tackler_component()
	qdel(gloves_tackler)
	gloves_tackler = null

/obj/item/clothing/mod_part/gloves/use_clothing_features_through_overslot()
	. = ..()
	var/obj/item/clothing/gloves/gloves_in_overslot = overslot

	if(!istype(gloves_in_overslot, /obj/item/clothing/gloves))
		return
	if(siemens_coefficient != 0)
		saved_siemens_coefficient = siemens_coefficient
		siemens_coefficient = gloves_in_overslot.siemens_coefficient //изоли

	if(!istype(gloves_in_overslot, /obj/item/clothing/gloves/tackler))
		return

	var/obj/item/clothing/gloves/tackler/G = gloves_in_overslot
	gloves_tackler = mod.wearer.AddComponent(/datum/component/tackler, stamina_cost=G.tackle_stam_cost, base_knockdown = G.base_knockdown, range = G.tackle_range, speed = G.tackle_speed, skill_mod = G.skill_mod, min_distance = G.min_distance)

/obj/item/clothing/mod_part/gloves/restore_normal_features()
	var/obj/item/clothing/gloves/gloves_on_human = istype(..(), /obj/item/clothing/gloves) ? ..() : null//результат родителя
	if(!gloves_on_human)
		return
	siemens_coefficient = saved_siemens_coefficient
	clear_mod_tackler_component()

/obj/item/clothing/mod_part/gloves/seal_part(seal)
	. = ..()
	mod?.wearer?.update_inv_gloves()

/obj/item/clothing/mod_part/gloves/proc/Touch(atom/A, proximity)
	return FALSE // return TRUE to cancel attack_hand()

/obj/item/clothing/mod_part/shoes
	name = "MOD boots"
	desc = "Пара ботинок для MOD-костюма."
	icon = 'modular_bluemoon/icons/obj/clothing/modsuit/mod_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/modsuit/mod_clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/modsuit/mod_clothing_anthro.dmi'
	icon_state = "boots"
	item_state = "boots"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, FIRE = 25, ACID = 25, WOUND = 10)
	body_parts_covered = FEET|LEGS
	heat_protection = FEET|LEGS
	cold_protection = FEET|LEGS
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	clothing_flags = THICKMATERIAL
	resistance_flags = NONE
	item_flags = IMMUTABLE_SLOW
	can_be_reinforced = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE
	theme_category = BOOTS_FLAGS
	slot_flags = ITEM_SLOT_FEET

/obj/item/clothing/mod_part/shoes/seal_part(seal)
	. = ..()
	mod?.wearer?.update_inv_shoes()

/obj/item/clothing/mod_part/shoes/negates_gravity()
	return clothing_flags & NOSLIP
