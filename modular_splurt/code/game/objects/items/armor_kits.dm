/obj/item/armorkit/blueshield
	name = "aegis armor kit"
	desc = "A nanotrasen armoring kit with armored plates and some nanoglue, for reinforcing outerwear."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "blueshield_armor_kit" // I'm so sorry I butchered the sprite, Toriate.

/obj/item/armorkit/blueshield/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
	// yeah have fun making subtypes and modifying the afterattack if you want to make variants
	// idiot
	// I have no idea what you are talking about.
	var/used = FALSE

	// BLUEMOON ADD START
	if(!isclothing(target))
		return
	// BLUEMOON ADD END
	if(!(isobj(target) && target.slot_flags & ITEM_SLOT_OCLOTHING))
		return
	// BLUEMOON ADD START
	if(target.type in typesof(/obj/item/clothing/suit/toggle/captains_parade, /obj/item/clothing/suit/space, /obj/item/clothing/suit/armor))
		to_chat(user, span_danger("You cannot modify [target], as it already has armor or is a part of special equipment."))
		return
	// BLUEMOON ADD END
	var/obj/item/clothing/C = target

	/* BLUEMOON REMOVAL START - убираем возможности абузов статов брони (например, риот даёт 60 защиты. Давая на него рампарт, у него остается 60 от мили и добавляется всё остальное)
	if(C.armor.getRating(MELEE) < 30)
		C.armor = C.armor.setRating(MELEE = 30)
		used = TRUE
	if(C.armor.getRating(BULLET) < 30)
		C.armor = C.armor.setRating(BULLET = 30)
		used = TRUE
	if(C.armor.getRating(LASER) < 30)
		C.armor = C.armor.setRating(LASER = 30)
		used = TRUE
	if(C.armor.getRating(ENERGY) < 40)
		C.armor = C.armor.setRating(ENERGY = 40)
		used = TRUE
	if(C.armor.getRating(BOMB) < 25)
		C.armor = C.armor.setRating(BOMB = 25)
		used = TRUE
	if(C.armor.getRating(FIRE) < 70)
		C.armor = C.armor.setRating(FIRE = 70)
		used = TRUE
	if(C.armor.getRating(ACID) < 90)
		C.armor = C.armor.setRating(ACID = 90)
		used = TRUE
	if(C.armor.getRating(WOUND) < 20)
		C.armor = C.armor.setRating(WOUND = 20)
		used = TRUE
	/ BLUEMOON REMOVAL END */
	// BLUEMOON ADD START
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
	// BLUEMOON ADD END

	if(used)
		C.allowed = GLOB.security_vest_allowed
		user.visible_message("<span class = 'notice'>[user] reinforces [C] with [src].</span>", \
		"<span class = 'notice'>You reinforce [C] with [src], making it as protective as a blueshield armored vest.</span>")
		C.name = "aegis [C.name]"
		C.upgrade_prefix = "aegis" // god i hope this works <-- I'm not sure what this even does.
		qdel(src)
		return
	else
		to_chat(user, "<span class = 'notice'>You don't need to reinforce [C] any further.")
		return

/obj/item/armorkit/blueshield/helmet
	name = "aegis headgear kit"
	desc = "A nanotrasen armoring kit with armored plates and some nanoglue, for reinforcing hats or other headgear."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "blueshield_helmet_kit" // I'm so sorry I butchered the sprite, Toriate. (x2)

/obj/item/armorkit/blueshield/helmet/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
	var/used = FALSE

	// BLUEMOON ADD START
	if(!isclothing(target))
		return
	// BLUEMOON ADD END
	if(!(isobj(target) && target.slot_flags & ITEM_SLOT_HEAD))
		return
	// BLUEMOON ADD START
	if(target.type in typesof(/obj/item/clothing/head/helmet))
		to_chat(user, span_danger("You cannot modify [target], as it already has armor or is a part of special equipment."))
		return
	// BLUEMOON ADD END

	var/obj/item/clothing/C = target

	/* BLUEMOON REMOVAL START - убираем возможности абузов статов брони (например, риот даёт 60 защиты. Давая на него рампарт, у него остается 60 от мили и добавляется всё остальное)
	if(C.armor.getRating(MELEE) < 40)
		C.armor = C.armor.setRating(MELEE = 40)
		used = TRUE
	if(C.armor.getRating(BULLET) < 30)
		C.armor = C.armor.setRating(BULLET = 30)
		used = TRUE
	if(C.armor.getRating(LASER) < 25)
		C.armor = C.armor.setRating(LASER = 25)
		used = TRUE
	if(C.armor.getRating(ENERGY) < 10)
		C.armor = C.armor.setRating(ENERGY = 10)
		used = TRUE
	if(C.armor.getRating(BOMB) < 25)
		C.armor = C.armor.setRating(BOMB = 25)
		used = TRUE
	if(C.armor.getRating(BIO) < 10)
		C.armor = C.armor.setRating(BIO = 10)
		used = TRUE
	if(C.armor.getRating(FIRE) < 50)
		C.armor = C.armor.setRating(FIRE = 50)
		used = TRUE
	if(C.armor.getRating(ACID) < 60)
		C.armor = C.armor.setRating(ACID = 60)
		used = TRUE
	if(C.armor.getRating(WOUND) < 20)
		C.armor = C.armor.setRating(ACID = 20)
		used = TRUE
	/ BLUEMOON REMOVAL END */
	// BLUEMOON ADD START
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
	// BLUEMOON ADD END

	if(used)
		user.visible_message("<span class = 'notice'>[user] reinforces [C] with [src].</span>", \
		"<span class = 'notice'>You reinforce [C] with [src], making it as protective as a blueshield helmet.</span>")
		C.name = "aegis [C.name]"
		C.upgrade_prefix = "aegis"
		qdel(src)
		return
	else
		to_chat(user, "<span class = 'notice'>You don't need to reinforce [C] any further.")
		return

/obj/item/armorkit/security
	name = "rampart armor kit"
	desc = "A security armoring kit with flexible armored sheets and some nanoglue, for reinforcing outerwear."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "sec_armor_kit" // I'm so sorry I butchered the sprite, Toriate. (x3)

/obj/item/armorkit/security/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
	var/used = FALSE

	// BLUEMOON ADD START
	if(!isclothing(target))
		return
	// BLUEMOON ADD END
	if(!(isobj(target) && target.slot_flags & ITEM_SLOT_OCLOTHING))
		return
	// BLUEMOON ADD START
	if(target.type in typesof(/obj/item/clothing/suit/toggle/captains_parade, /obj/item/clothing/suit/space, /obj/item/clothing/suit/armor))
		to_chat(user, span_danger("You cannot modify [target], as it already has armor or is a part of special equipment."))
		return
	// BLUEMOON ADD END
	var/obj/item/clothing/C = target

	/* BLUEMOON REMOVAL START - убираем возможности абузов статов брони (например, риот даёт 60 защиты. Давая на него рампарт, у него остается 60 от мили и добавляется всё остальное)
	if(C.armor.getRating(MELEE) < 30)
		C.armor = C.armor.setRating(MELEE = 30)
		used = TRUE
	if(C.armor.getRating(BULLET) < 30)
		C.armor = C.armor.setRating(BULLET = 30)
		used = TRUE
	if(C.armor.getRating(LASER) < 30)
		C.armor = C.armor.setRating(LASER = 30)
		used = TRUE
	if(C.armor.getRating(ENERGY) < 10)
		C.armor = C.armor.setRating(ENERGY = 10)
		used = TRUE
	if(C.armor.getRating(BOMB) < 25)
		C.armor = C.armor.setRating(BOMB = 25)
		used = TRUE
	if(C.armor.getRating(FIRE) < 50)
		C.armor = C.armor.setRating(FIRE = 50)
		used = TRUE
	if(C.armor.getRating(ACID) < 50)
		C.armor = C.armor.setRating(ACID = 50)
		used = TRUE
	if(C.armor.getRating(WOUND) < 10)
		C.armor = C.armor.setRating(WOUND = 10)
		used = TRUE
	/ BLUEMOON REMOVAL END */
	// BLUEMOON ADD START
	var/obj/item/clothing/suit/armor/vest/A = new /obj/item/clothing/suit/armor/vest(src)
	C.set_armor(A.armor)
	C.body_parts_covered = A.body_parts_covered
	C.cold_protection = A.cold_protection
	C.heat_protection = A.heat_protection
	C.resistance_flags = A.resistance_flags
	C.clothing_flags = A.clothing_flags
	C.min_cold_protection_temperature = A.min_cold_protection_temperature
	C.max_heat_protection_temperature = A.max_heat_protection_temperature
	used = TRUE
	// BLUEMOON ADD END

	if(used)
		C.allowed = GLOB.security_vest_allowed
		user.visible_message("<span class = 'notice'>[user] reinforces [C] with [src].</span>", \
		"<span class = 'notice'>You reinforce [C] with [src], making it as protective as a security armored vest.</span>")
		C.name = "rampart [C.name]"
		C.upgrade_prefix = "rampart"
		qdel(src)
		return
	else
		to_chat(user, "<span class = 'notice'>You don't need to reinforce [C] any further.")
		return

/obj/item/armorkit/security/helmet
	name = "rampart headgear kit"
	desc = "A security armoring kit with flexible armored sheets and some nanoglue, for reinforcing hats or other headgear."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "sec_helmet_kit" // I'm so sorry I butchered the sprite, Toriate. (x4)

/obj/item/armorkit/security/helmet/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
	var/used = FALSE

	// BLUEMOON ADD START
	if(!isclothing(target))
		return
	// BLUEMOON ADD END
	if(!(isobj(target) && target.slot_flags & ITEM_SLOT_HEAD))
		return
	// BLUEMOON ADD START
	if(target.type in typesof(/obj/item/clothing/head/helmet))
		to_chat(user, span_danger("You cannot modify [target], as it already has armor or is a part of special equipment."))
		return
	// BLUEMOON ADD END

	var/obj/item/clothing/C = target

	/* BLUEMOON REMOVAL START - убираем возможности абузов статов брони (например, риот даёт 60 защиты. Давая на него рампарт, у него остается 60 от мили и добавляется всё остальное)
	if(C.armor.getRating(MELEE) < 40)
		C.armor = C.armor.setRating(MELEE = 40)
		used = TRUE
	if(C.armor.getRating(BULLET) < 30)
		C.armor = C.armor.setRating(BULLET = 30)
		used = TRUE
	if(C.armor.getRating(LASER) < 30)
		C.armor = C.armor.setRating(LASER = 30) // Why the fuck does the sec helmet have better laser protection than the blueshield's?
		used = TRUE
	if(C.armor.getRating(ENERGY) < 10)
		C.armor = C.armor.setRating(ENERGY = 10)
		used = TRUE
	if(C.armor.getRating(BOMB) < 25)
		C.armor = C.armor.setRating(BOMB = 25)
		used = TRUE
	if(C.armor.getRating(FIRE) < 50)
		C.armor = C.armor.setRating(FIRE = 50)
		used = TRUE
	if(C.armor.getRating(ACID) < 50)
		C.armor = C.armor.setRating(ACID = 50)
		used = TRUE
	if(C.armor.getRating(WOUND) < 10)
		C.armor = C.armor.setRating(WOUND = 10)
		used = TRUE
	/ BLUEMOON REMOVAL END */
	// BLUEMOON ADD START
	var/obj/item/clothing/head/helmet/sec/A = new /obj/item/clothing/head/helmet/sec(src)
	C.set_armor(A.armor)
	C.body_parts_covered = A.body_parts_covered
	C.cold_protection = A.cold_protection
	C.heat_protection = A.heat_protection
	C.resistance_flags = A.resistance_flags
	C.clothing_flags = A.clothing_flags
	C.min_cold_protection_temperature = A.min_cold_protection_temperature
	C.max_heat_protection_temperature = A.max_heat_protection_temperature
	used = TRUE
	// BLUEMOON ADD END

	if(used)
		user.visible_message("<span class = 'notice'>[user] reinforces [C] with [src].</span>", \
		"<span class = 'notice'>You reinforce [C] with [src], making it as protective as a security helmet.</span>")
		C.name = "rampart [C.name]"
		C.upgrade_prefix = "rampart"
		qdel(src)
		return
	else
		to_chat(user, "<span class = 'notice'>You don't need to reinforce [C] any further.")
		return

/obj/item/armorkit/syndicate
	name = "SynTech armor kit"
	desc = "Набор гибких армированных пластин которые будут совершенно незаметно сидеть под твоей толстовкой, с которой ты так не захотел расставаться, хиккан."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	icon_state = "syn_armor_kit"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/armorkit/syndicate/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
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
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	icon_state = "syn_helmet_kit"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/armorkit/helmet/syndicate/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
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
