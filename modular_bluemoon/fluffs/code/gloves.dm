/obj/item/clothing/accessory/ring/syntech/winterschock
	name = "Ouroboros"
	desc = "An expensive and personally customized version of the normalizer ring with few modifications"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/gloves.dmi'
	icon_state = "ouroboros"
	var/current_normalized_size = 1
	var/max_normalized_size = 1
	var/min_normalized_size = 0.25

/obj/item/clothing/accessory/ring/syntech/winterschock/clothing_size_normalize(mob/living/user, slot, slot_to_check, owner)
	if(slot_to_check && slot != slot_to_check)
		return FALSE

	if(HAS_TRAIT(user, TRAIT_BLUEMOON_ANTI_NORMALIZER) && owner != user)
		to_chat(user, "<span class='warning'>\The [src] buzzes, as nothing changes.</span>")
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, 1)
		return FALSE

	if(user.GetComponent(/datum/component/size_normalized))
		to_chat(user, "<span class='warning'>\The [src] buzzes, being overwritten by another accessory.</span>")
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, 1)
		return FALSE

	user.AddComponent(/datum/component/size_normalized, wear=src, size_to_use = current_normalized_size)

/obj/item/clothing/accessory/ring/syntech/winterschock/proc/try_update_size(mob/living/carbon/human/user, force)
	var/datum/component/size_normalized/size_norm = user.GetComponent(/datum/component/size_normalized)
	if(!istype(size_norm) || !istype(user))
		return TRUE
	if(size_norm.attached_wear != src || size_norm.parent != user)
		return TRUE
	// Изменение размера если кольцо нацеплено
	var/mob/living/wearer = size_norm.parent
	size_norm.UnregisterSignal(wearer, COMSIG_MOB_RESIZED)	// Just in case
	if(!force)
		playsound(wearer, 'sound/effects/magic.ogg', 50, 1)
		wearer.flash_lighting_fx(3, 3, LIGHT_COLOR_PURPLE)
	wearer.update_size(current_normalized_size)
	size_norm.RegisterSignal(wearer, COMSIG_MOB_RESIZED, TYPE_PROC_REF(/datum/component/size_normalized, normalize_size))	// Just in case
	// Изменение размера если кольцо нацеплено end

/obj/item/clothing/accessory/ring/syntech/winterschock/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return
	var/size_select = tgui_input_number(usr, "Set prefered size ([min_normalized_size * 100]-[max_normalized_size * 100]%).", "Set Size", current_normalized_size * 100, max_normalized_size * 100, min_normalized_size * 100)
	if(!size_select) return
	current_normalized_size = clamp((size_select/100), max_normalized_size, min_normalized_size)
	to_chat(usr, "<span class='notice'>You set the size to [current_normalized_size * 100]%</span>")
	if(do_after(user, 10 SECONDS, user))
		try_update_size(user, FALSE)
	return TRUE

// copypaste from /obj/item/clothing/gloves/combat/maid/civil
/obj/item/clothing/gloves/toggled/hug/combat_maid_civil
	name = "Combat Maid Sleeves"
	desc = "These 'tactical' gloves and sleeves are fireproof and electrically insulated. Warm to boot."
	icon_state = "syndimaid_arms"
	item_state = "blackgloves"
	strip_delay = 80
	cold_protection = HANDS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	heat_protection = HANDS
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT
	resistance_flags = NONE
	strip_mod = 1.5
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 80, ACID = 50)

// copypaste from /obj/item/clothing/gloves/poly_evening
/obj/item/clothing/gloves/toggled/hug/poly_evening
	name = "Polychromic evening gloves"
	desc = "Thin, pretty polychromic gloves intended for use in regal feminine attire."
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/object/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/hands.dmi'
	icon_state = "poly_evening"
	item_state = "poly_evening"
	cold_protection = HANDS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	heat_protection = HANDS
	max_heat_protection_temperature = COAT_MAX_TEMP_PROTECT
	strip_mod = 0.9

/obj/item/clothing/gloves/toggled/hug/poly_evening/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/polychromic, list("#FEFEFE"), 1)

/obj/item/clothing/gloves/color/black/soviet_gloves
	name = "Soviet Black Gloves"
	desc = "Чёрные перчатки."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/gloves.dmi'
	icon_state = "sovietblackgloves"
	item_state = "sovietblackgloves"
