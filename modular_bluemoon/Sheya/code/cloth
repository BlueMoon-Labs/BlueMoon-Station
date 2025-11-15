/obj/item/armorkit/syndicate
	name = "SynTech armor kit"
	desc = "Набор гибких армированных пластин которые будут совершенно незаметно сидеть под твоей толстовкой, с которой ты так не захотел расставаться, хиккан."
	icon_state = "syn_armor_kit"
	icon = 'modular_bluemoon/Sheya/Icons/Obj/misc.dmi'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/armorkit/inteq/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
	var/used = FALSE
	if(!isclothing(target))
		return
	if(!(isobj(target) && target.slot_flags & ITEM_SLOT_OCLOTHING))
		return
	if(target.type in typesof(/obj/item/clothing/suit/toggle/captains_parade, /obj/item/clothing/suit/space, /obj/item/clothing/suit/armor))
		to_chat(user, span_danger("You cannot modify [target], as it already has armor or is a part of special equipment."))
		return
	var/obj/item/clothing/C = target
	var/obj/item/clothing/suit/armor/vest/bluesheid/A = new /obj/item/clothing/suit/armor/vest/bluesheid(src)
	C.set_armor(A.armor)
	C.body_parts_covered = A.body_parts_covered
	C.cold_protection = A.cold_protection
	C.heat_protection = A.heat_protection
	C.resistance_flags = A.resistance_flags
	C.clothing_flags = A.clothing_flags
	C.min_cold_protection_temperature = A.min_cold_protection_temperature
	C.max_heat_protection_temperature = A.max_heat_protection_temperature
	used = TRUE
	if(used)
		C.allowed = GLOB.security_vest_allowed
		user.visible_message("<span class = 'notice'>[user] reinforces [C] with [src].</span>", \
		"<span class = 'notice'>You reinforce [C] with [src], making it as protective as a armored vest.</span>")
		C.name = "rogue [C.name]"
		C.upgrade_prefix = "rogue"
		qdel(src)
		return
	else
		to_chat(user, "<span class = 'notice'>You don't need to reinforce [C] any further.")
		return
//Голова
/obj/item/armorkit/helmet/syndicate
	name = "SynTech helmet kit"
	desc = "Набор гибких армированных пластин которые будут совершенно незаметно сидеть под твоей кепкой, с которой ты так не захотел расставаться, хиккан."
	icon_state = "syn_helmet_kit"
	icon = 'modular_bluemoon/Sheya/Icons/Obj/misc.dmi'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/armorkit/helmet/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
	var/used = FALSE
	if(!isclothing(target))
		return
	if(!(isobj(target) && target.slot_flags & ITEM_SLOT_HEAD))
		return
	if(target.type in typesof(/obj/item/clothing/head/helmet))
		to_chat(user, span_danger("You cannot modify [target], as it already has armor or is a part of special equipment."))
		return
	var/obj/item/clothing/C = target
	var/obj/item/clothing/head/helmet/sec/blueshield/A = new /obj/item/clothing/head/helmet/sec/blueshield(src)
	C.set_armor(A.armor)
	C.body_parts_covered = A.body_parts_covered
	C.cold_protection = A.cold_protection
	C.heat_protection = A.heat_protection
	C.resistance_flags = A.resistance_flags
	C.clothing_flags = A.clothing_flags
	C.min_cold_protection_temperature = A.min_cold_protection_temperature
	C.max_heat_protection_temperature = A.max_heat_protection_temperature
	used = TRUE
	if(used)
		user.visible_message("<span class = 'notice'>[user] reinforces [C] with [src].</span>", \
		"<span class = 'notice'>You reinforce [C] with [src], making it as protective as a helmet.</span>")
		C.name = "rogue [C.name]"
		C.upgrade_prefix = "rogue"
		qdel(src)
		return
	else
		to_chat(user, "<span class = 'notice'>You don't need to reinforce [C] any further.")
		return
