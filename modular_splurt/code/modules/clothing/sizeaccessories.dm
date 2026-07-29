//GLOVE SLOT ITEMS...
//SynTech ring
/obj/item/clothing/accessory/ring/syntech
	name = "normalizer ring"
	desc = "An expensive, shimmering SynTech ring gilded with golden NanoTrasen markings. It will 'normalize' the size of the user to a specified height approved for work-conditions, as long as it is equipped. The artificial violet gem inside twinkles ominously."
	icon = 'modular_splurt/icons/obj/clothing/sizeaccessories.dmi'
	icon_state = "ring"
	item_state = "sring" //No use in a unique sprite since it's just one pixel
	w_class = WEIGHT_CLASS_TINY
	body_parts_covered = 0
	transfer_prints = TRUE
	strip_delay = 40
	equip_delay_self = 175
	unequip_delay_self = 175
	var/owner = null	// владелец нормалайзера может нацепить его даже если у него стоит квирк ANTI_NORMALIZER
	var/list/previous_gloves_data[3] // strip_delay, equip_delay_self, unequip_delay_self
	//These are already defined under the parent ring, but I wanna leave em here for reference purposes

/obj/item/clothing/proc/clothing_size_normalize(mob/living/user, slot, slot_to_check, owner)
	var/used_size
	if(ishuman(user))
		var/mob/living/carbon/human/M = user
		if(M?.dna?.features["normalized_size"])
			used_size = M.dna.features["normalized_size"]
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

	user.AddComponent(/datum/component/size_normalized, wear=src, size_to_use = used_size)

/obj/item/clothing/proc/clothing_size_un_normalize(mob/living/user)
	var/datum/component/size_normalized/comp = user.GetComponent(/datum/component/size_normalized)
	if(comp?.attached_wear == src)
		qdel(comp)

//For glove slots
/obj/item/clothing/accessory/ring/syntech/equipped(mob/living/user, slot)
	clothing_size_normalize(user, slot, ITEM_SLOT_GLOVES, src.owner)
	..()

/obj/item/clothing/accessory/ring/syntech/dropped(mob/living/user, slot)
	clothing_size_un_normalize(user)
	..()

/obj/item/clothing/accessory/ring/syntech/attach(obj/item/clothing/cloth, mob/living/carbon/human/user)
	if(istype(user) && user.gloves == cloth)
		if(!user.dna.species.equip_delay_self_check(src, user))
			if(!user.put_in_hands(src)) // Из-за специфики работы прока attach_accessory следует проследить, чтобы кольцо не осталось внутри без локации на теле
				to_chat(user, "<span class='warning'>[src] just slip off your hands!</span>")
			return FALSE


	previous_gloves_data[1] = cloth.strip_delay
	cloth.strip_delay = max(cloth.strip_delay, strip_delay)
	previous_gloves_data[2] = cloth.equip_delay_self
	cloth.equip_delay_self = max(cloth.equip_delay_self, equip_delay_self)
	previous_gloves_data[3] = cloth.unequip_delay_self
	cloth.unequip_delay_self = max(cloth.unequip_delay_self, unequip_delay_self)
	..()

/obj/item/clothing/accessory/ring/syntech/detach(obj/item/clothing/cloth, user)
	clothing_size_un_normalize(user)
	cloth.strip_delay = previous_gloves_data[1]
	cloth.equip_delay_self = previous_gloves_data[2]
	cloth.unequip_delay_self = previous_gloves_data[3]
	..()

/obj/item/clothing/accessory/ring/syntech/on_uniform_equip(obj/item/clothing/cloth, mob/living/carbon/human/user)
	if(istype(user) && user.gloves == cloth)
		clothing_size_normalize(user, owner = src.owner)

/obj/item/clothing/accessory/ring/syntech/on_uniform_dropped(obj/item/clothing/cloth, mob/living/user)
	clothing_size_un_normalize(user)

//SynTech Wristband
/obj/item/clothing/wrists/syntech
	name = "normalizer wristband"
	desc = "An expensive technological wristband cast in SynTech purples with shimmering NanoTrasen golds. It will 'normalize' the size of the user to a specified height for approved work-conditions, as long as it is equipped. There is a small screen buzzing with information."
	icon = 'modular_splurt/icons/obj/clothing/sizeaccessories.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/hands.dmi'
	icon_state = "wristband"
	item_state = "syntechband"
	var/owner = null	// владелец нормалайзера может нацепить его даже если у него стоит квирк ANTI_NORMALIZER
	equip_delay_self = 175
	unequip_delay_self = 175

/obj/item/clothing/wrists/syntech/equipped(mob/user, slot)
	clothing_size_normalize(user, slot, ITEM_SLOT_WRISTS, src.owner)
	..()

/obj/item/clothing/wrists/syntech/dropped(mob/living/user, slot)
	clothing_size_un_normalize(user)
	..()

//NECK SLOT ITEMS...
//Syntech Pendant
/obj/item/clothing/neck/syntech
	name = "normalizer pendant"
	desc = "A vibrant violet jewel cast in silvery-gold metals, sporting the elegance of NanoTrasen with SynTech prowess. It will 'normalize' the size of the user to a specified height for approved work-conditions, as long as it is equipped. The artificial violet gem inside twinkles ominously."
	icon = 'modular_splurt/icons/obj/clothing/sizeaccessories.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "pendant"
	item_state = "pendant"
	var/owner = null	// владелец нормалайзера может нацепить его даже если у него стоит квирк ANTI_NORMALIZER
	equip_delay_self = 175
	unequip_delay_self = 175

//For neck items
/obj/item/clothing/neck/syntech/equipped(mob/living/user, slot)
	clothing_size_normalize(user, slot, ITEM_SLOT_NECK, src.owner)
	..()

/obj/item/clothing/neck/syntech/dropped(mob/living/user, slot)
	clothing_size_un_normalize(user)
	. = ..()

//Syntech Choker
/obj/item/clothing/neck/syntech/choker
	name = "normalizer choker"
	desc = "A sleek, tight-fitting choker embezzled with silver to gold, adorned with vibrant purple studs; combined technology of NanoTrasen and SynTech. It will 'normalize' the size of the user to a specified height for approved work-conditions, as long as it is equipped. There is a small screen buzzing with information."
	icon_state = "choker"
	item_state = "collar"

//Syntech Collar
/obj/item/clothing/neck/syntech/collar
	name = "normalizer collar"
	desc = "A cute pet collar, technologically designed with vibrant purples and smooth silvers. There is a small gem bordered by gold at the front, reading 'SYNTECH' engraved within the metal. It will 'normalize' the size of the user to a specified height for approved work-conditions, as long as it is equipped. The artificial violet gem inside twinkles ominously."
	icon_state = "collar"
	item_state = "collar"
