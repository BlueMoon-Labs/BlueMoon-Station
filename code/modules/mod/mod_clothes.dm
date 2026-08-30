/obj/item/clothing/mod_part
	name = "Часть МОД костюма"
	desc = "Это базовый класс любого носимого на теле МОД костюма. \
			Раньше они не имели наследования и друг от друга, а брали родителя от типа \
			своего слота, т.е шлемов, ботинок и т.д. Вы не представляете, как же много макаронного кода \
			это порождало."

	var/obj/item/mod/control/mod
	var/obj/item/clothing/overslot
	var/list/seal_message = list(
		"затягивается и герметизируется на вас",
		)
	var/list/unseal_message = list(
		"расслабляется и открывается",
		)
	var/list/overslot_blacklist = list(
		/obj/item/clothing/suit/space,
		/obj/item/clothing/head/helmet,
		/obj/item/clothing/mod_part,
		//Сюда вписываем то, поверх чего должно быть невозможно развернуть элемент МОДа!
	)
	var/obj/item/mod/module/linked_modules = list()
	var/theme_category

/obj/item/clothing/mod_part/equipped(mob/user, slot)
	. = ..()
	RegisterSignal(mod.wearer, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_dropped))

/obj/item/clothing/mod_part/proc/on_dropped(mob/source, obj/item, force, new_location)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/clothing/mod_part))
		return
	UnregisterSignal(mod.wearer, COMSIG_MOB_UNEQUIPPED_ITEM)
	if(new_location == null)//чтобы не путать со штатным свертыванием
		return
	INVOKE_ASYNC(mod, TYPE_PROC_REF(/obj/item/mod/control, conceal), null, item, TRUE)
	INVOKE_ASYNC(mod, TYPE_PROC_REF(/obj/item/mod/control, remove_hardlight))

/obj/item/clothing/mod_part/proc/link_modpart_with_module(module)
	if(istype(module, /obj/item/mod/module) && (module in linked_modules))
		return FALSE
	linked_modules += module
	return TRUE

/obj/item/clothing/mod_part/proc/toggle_all_linked_modules(state)
	if(!linked_modules)
		return FALSE

	if(state == MODPART_CONSEALED)
		for(var/obj/item/mod/module/module in linked_modules)
			module.saved_state = module.active
			if(module.active)
				module.on_deactivation()
		return TRUE
	else
		for(var/obj/item/mod/module/module in linked_modules)
			if(!module.saved_state)
				continue
			module.on_activation()

/obj/item/clothing/mod_part/proc/check_module_ready()
	return mod.is_active() && mod.wearer.get_item_by_slot(src.slot_flags) == src

/obj/item/clothing/mod_part/proc/update_flags(list/used_skin)
	var/list/category = used_skin[theme_category]
	clothing_flags = category[UNSEALED_CLOTHING] || NONE
	visor_flags = category[SEALED_CLOTHING] || NONE
	flags_inv = category[UNSEALED_INVISIBILITY] || NONE
	visor_flags_inv = category[SEALED_INVISIBILITY] || NONE
	flags_cover = category[UNSEALED_COVER] || NONE
	visor_flags_cover = category[SEALED_COVER] || NONE

/obj/item/clothing/mod_part/proc/conseal_to_overslot()//Не давать скрывать space suit
	var/obj/item/clothing/item = mod.wearer.get_item_by_slot(slot_flags)
	if(!item)
		return TRUE
	overslot = item

	for(var/type in overslot_blacklist)
		if(istype(item, type))
			return FALSE

	return mod.wearer.transferItemToLoc(overslot, item, force = TRUE)

/obj/item/clothing/mod_part/proc/seal_part(seal)
	if(seal)
		clothing_flags |= visor_flags
		flags_inv |= visor_flags_inv
		flags_cover |= visor_flags_cover
		heat_protection = initial(heat_protection)
		cold_protection = initial(cold_protection)
	else
		flags_cover &= ~visor_flags_cover
		flags_inv &= ~visor_flags_inv
		clothing_flags &= ~visor_flags
		heat_protection = NONE
		cold_protection = NONE
	icon_state = "[mod.skin]-[initial(icon_state)][seal ? "-sealed" : ""]"
	item_state = "[mod.skin]-[initial(item_state)][seal ? "-sealed" : ""]"

/obj/item/clothing/mod_part/proc/equip_item_from_overslot()
	REMOVE_TRAIT(src, TRAIT_NODROP, MOD_TRAIT)
	if(!overslot)
		return
	if(!mod.wearer.equip_to_slot_if_possible(overslot, overslot.slot_flags, qdel_on_fail = FALSE, disable_warning = TRUE))//Экипировать элемент одежды с оверслота обратно
		mod.wearer.dropItemToGround(overslot, force = TRUE)//если условие выше не удалось, то дропать на землю
	overslot = null

/obj/item/clothing/mod_part/Destroy()
	if(!QDELETED(mod))
		mod.mod_parts -= src
		QDEL_NULL(mod)
	return ..()

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
	mod.wearer.update_inv_head()
	mod.wearer.update_inv_wear_mask()
	mod.wearer.update_hair()

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
	mod.wearer.update_inv_wear_suit()
	mod.wearer.update_inv_w_uniform()

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
	var/transfer_blood = FALSE
	var/transfer_prints = FALSE

/obj/item/clothing/mod_part/gloves/seal_part(seal)
	. = ..()
	mod.wearer.update_inv_gloves()

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
	mod.wearer.update_inv_shoes()

/obj/item/clothing/mod_part/shoes/negates_gravity()
	return clothing_flags & NOSLIP


//Для инфильтратора
//blockTracking = 1
//SEND_SIGNAL(C, COMSIG_CARBON_REMOVE_LIMB, src, dismembered)
