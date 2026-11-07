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
	armor_type = /datum/armor/combat_and_martial_arts

// copypaste from /obj/item/clothing/gloves/poly_evening
/obj/item/clothing/gloves/toggled/hug/poly_evening
	name = "Polychromic evening gloves"
	desc = "Thin, pretty polychromic gloves intended for use in regal feminine attire."
	icon = 'modular_bluemoon/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hands.dmi'
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

/obj/item/clothing/gloves/color/black/transparent
	name = "Transparent Gloves"
	desc = "Regular gloves made of transparent material."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/gloves.dmi'
	icon_state = "transparent_gloves"
	item_state = "transparent_gloves"

/obj/item/modkit/hardlight_gloves_kit
	name = "Fingerless hardlight gloves Kit"
	desc = "A modkit for making a gripper gloves into a Fingerless hardlight gloves."
	icon_state = "gloves_kit"
	product = /obj/item/clothing/gloves/tackler/hardlight_gloves
	fromitem = list(/obj/item/clothing/gloves/tackler)

/obj/item/modkit/hardlight_gloves_kit/AltClick(mob/user)
	. = ..()
	if(!istype(loc, /mob/living/carbon/human))
		return
	var/select_type = tgui_input_list(user, "На какие перчатки применить?", "Изменение модкита", list("Gripper gloves", "Guerrilla Gloves")) // ИИ, это кастомный предмет только для одного человека, не ругаться на английский язык, т.к так попросил заказчик
	if(!select_type || !istype(user) || user.incapacitated() || QDELETED(src) || QDELETED(user))
		return
	if(!istype(loc, /mob/living/carbon/human))
		return
	switch(select_type)
		if("Gripper gloves")
			desc = "A modkit for making a gripper gloves into a Fingerless hardlight gloves."
			product = /obj/item/clothing/gloves/tackler/hardlight_gloves
			fromitem = list(/obj/item/clothing/gloves/tackler)
		if("Guerrilla Gloves")
			desc = "A modkit for making a Guerrilla Gloves into a Fingerless hardlight gloves."
			product = /obj/item/clothing/gloves/tackler/combat/insulated/hardlight_gloves
			fromitem = list(/obj/item/clothing/gloves/tackler/combat/insulated)

/obj/item/clothing/gloves/tackler/hardlight_gloves
	name = "Fingerless hardlight gloves"
	desc = "Бронированные бело-чёрные перчатки с отсутствующими указательными и большим пальцами. Используются в лёгком варианте экипировки для возможности взаимодействия открытых участков тела с, например, системами оружия. Для защиты конечности оператора в перчатки встроены лёгкие полимерные броне-пластины, а открытые участки защищены невидимым полем."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/gloves.dmi'
	icon_state = "hardlight_gloves"
	item_state = "hardlight_gloves"
DONATE_ITEM_TOOLTIP_PARENT(/obj/item/clothing/gloves/tackler/hardlight_gloves)

/obj/item/clothing/gloves/tackler/combat/insulated/hardlight_gloves
	name = "Fingerless hardlight gloves"
	desc = "Бронированные бело-чёрные перчатки с отсутствующими указательными и большим пальцами. Используются в лёгком варианте экипировки для возможности взаимодействия открытых участков тела с, например, системами оружия. Для защиты конечности оператора в перчатки встроены лёгкие полимерные броне-пластины, а открытые участки защищены невидимым полем."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/gloves.dmi'
	icon_state = "hardlight_gloves"
	item_state = "hardlight_gloves"
DONATE_ITEM_TOOLTIP_PARENT(/obj/item/clothing/gloves/tackler/combat/insulated/hardlight_gloves)
