/datum/quirk/modular
	name = "Модульные Конечности"
	desc = "Ваши конечности можно легко присоединять и отсоединять... к сожалению, все окружающие тоже могут изменять ваши конечности! Щелкните правой кнопкой мыши на себе, чтобы использовать эту причуду."
	value = 0
	mob_trait = TRAIT_MODULAR_LIMBS

/datum/quirk/modular/add()
	var/mob/living/carbon/human/C = quirk_holder
	add_verb(C,/mob/living/proc/alterlimbs)

/datum/quirk/modular/remove()
	var/mob/living/carbon/human/C = quirk_holder
	// BLUEMOON EDIT START - sanity check
	if(!C)
		return
	// BLUEMOON EDIT END
	remove_verb(C,/mob/living/proc/alterlimbs)

/mob/living/proc/alterlimbs()
	set name = "Alter Limbs"
	set desc = "Remove or attach a limb!"
	set category = "IC"
	set src in view(usr.client)

	var/mob/living/carbon/human/U = usr
	var/mob/living/carbon/human/C = src
	if(!istype(U) || !istype(C))
		return
	var/obj/item/bodypart/L = U.get_active_held_item()
	if(istype(L))
		C.modular_attach_limb(U, L)
	else
		C.modular_detach_limb(U, U.zone_selected)

/// Руки и ноги, которые снимаются с модульными конечностями
GLOBAL_LIST_INIT(modular_limb_zones, list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))

/mob/living/carbon/human/proc/modular_attach_limb(mob/living/carbon/human/user, obj/item/bodypart/limb)
	if(!HAS_TRAIT(src, TRAIT_MODULAR_LIMBS) || !user.is_holding(limb))
		return
	if(!Adjacent(user))
		to_chat(user, span_warning("Нужно стоять рядом с [src]!"))
		return
	if(get_bodypart(limb.body_zone))
		to_chat(user, span_warning("У [src] уже есть [ru_parse_zone(limb.body_zone)]!"))
		return
	modular_limb_message(user, "пытается присоединить", "пытаетесь присоединить", "к телу", limb.body_zone)
	if(!do_after(user, 4 SECONDS, target = src) || !Adjacent(user) || !user.is_holding(limb) || get_bodypart(limb.body_zone))
		to_chat(user, span_warning("Вы и [src] должны стоять на месте, чтобы присоединить конечность!"))
		return
	if(!user.temporarilyRemoveItemFromInventory(limb))
		return
	limb.attach_limb(src)
	update_equipment_speed_mods()
	modular_limb_message(user, "присоединяет", "присоединяете", "к телу", limb.body_zone)

/mob/living/carbon/human/proc/modular_detach_limb(mob/living/carbon/human/user, zone)
	if(!HAS_TRAIT(src, TRAIT_MODULAR_LIMBS))
		return
	if(!Adjacent(user))
		to_chat(user, span_warning("Нужно стоять рядом с [src]!"))
		return
	zone = check_zone(zone)
	if(!(zone in GLOB.modular_limb_zones))
		to_chat(user, span_warning("Выберите руку или ногу!"))
		return
	var/obj/item/bodypart/limb = get_bodypart(zone)
	if(!limb)
		to_chat(user, span_warning("У [src] уже нет этой конечности!"))
		return
	modular_limb_message(user, "пытается отсоединить", "пытаетесь отсоединить", "у", zone)
	if(!do_after(user, 4 SECONDS, target = src) || !Adjacent(user))
		to_chat(user, span_warning("Вы и [src] должны стоять на месте, чтобы отсоединить конечность!"))
		return
	if(get_bodypart(zone) != limb)
		return
	limb.drop_limb()
	update_equipment_speed_mods()
	modular_limb_message(user, "ловко отсоединяет", "ловко отсоединяете", "у", zone)

/// Себе - «себе», другому - «у/к телу [src]»; action - от третьего лица, action_you - от второго
/mob/living/carbon/human/proc/modular_limb_message(mob/user, action, action_you, preposition, zone)
	var/limb_name = ru_kogo_zone(zone)
	if(user == src)
		var/self_text = "Вы [action_you] себе [limb_name]."
		visible_message(span_warning("[user] [action] себе [limb_name]."), span_notice(self_text))
		return
	var/seen_text = "[user] [action] [preposition] [src] [limb_name]."
	var/target_text = "[user] [action] вам [limb_name]!"
	visible_message(span_warning(seen_text), span_userdanger(target_text))

/// Пункты меню ПКМ: присоединить конечность из руки или отсоединить выбранную (без выбранной - любую из оставшихся)
/mob/living/carbon/human/proc/modular_limb_menu_entries(mob/living/carbon/human/user)
	. = list()
	if(!HAS_TRAIT(src, TRAIT_MODULAR_LIMBS) || !istype(user) || !Adjacent(user))
		return
	var/obj/item/bodypart/held = user.get_active_held_item()
	if(istype(held))
		if(!get_bodypart(held.body_zone))
			. += new /datum/context_menu_entry/callback("Присоединить [ru_kogo_zone(held.body_zone)]", null, CONTEXT_ENTRY_NORMAL, CALLBACK(src, PROC_REF(modular_attach_limb), user, held))
		return
	var/list/zones = GLOB.modular_limb_zones
	var/selected = check_zone(user.zone_selected)
	if((selected in zones) && get_bodypart(selected))
		zones = list(selected)
	for(var/zone in zones)
		if(get_bodypart(zone))
			. += new /datum/context_menu_entry/callback("Отсоединить [ru_kogo_zone(zone)]", null, CONTEXT_ENTRY_NORMAL, CALLBACK(src, PROC_REF(modular_detach_limb), user, zone))
