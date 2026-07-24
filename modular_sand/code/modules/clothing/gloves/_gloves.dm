/obj/item/clothing/gloves
	var/dummy_thick = FALSE // is able to hold accessories on its item
	max_accessories = 1

/obj/item/clothing/gloves/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(CHECK_BITFIELD(flags_inv, HIDEACCESSORY))
		return
	for(var/obj/item/clothing/accessory/ring/attached_accessory as anything in accessories_attached)
		if(CHECK_BITFIELD(attached_accessory.flags_inv, HIDEACCESSORY))
			continue
		. += attached_accessory.build_worn_icon()

/obj/item/clothing/gloves/attackby(obj/item/I, mob/user, params)
	if(!attach_accessory(I, user))
		return ..()

/obj/item/clothing/gloves/AltClick(mob/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user), TRUE, FALSE))
		return
	if(length(accessories_attached))
		remove_accessory(user)

/obj/item/clothing/gloves/equipped(mob/user, slot)
	..()

	for(var/obj/item/clothing/accessory/ring/attached_accessory as anything in accessories_attached)
		if(attached_accessory && slot == ITEM_SLOT_HANDS && ishuman(user))
			attached_accessory.on_uniform_equip(src, user)

/obj/item/clothing/gloves/dropped(mob/user)
	for(var/obj/item/clothing/accessory/ring/attached_accessory as anything in accessories_attached)
		attached_accessory.on_uniform_dropped(src, user)
	..()

/obj/item/clothing/gloves/attach_accessory(obj/item/clothing/accessory/ring/accessory, mob/user, notifyAttach = TRUE)
	. = FALSE
	if(!istype(accessory))
		return
	if(length(accessories_attached) >= max_accessories)
		if(user)
			to_chat(user, "<span class='warning'>[src] already has [length(accessories_attached)] accessories.</span>")
		return
	if(dummy_thick)
		if(user)
			to_chat(user, "<span class='warning'>[src] is too bulky and cannot have accessories attached to it!</span>")
		return
	if(user && !user.temporarilyRemoveItemFromInventory(accessory))
		return
	if(!accessory.attach(src, user))
		return

	if(user && notifyAttach)
		to_chat(user, "<span class='notice'>You attach [accessory] to [src].</span>")

	if((flags_inv & HIDEACCESSORY) || (accessory.flags_inv & HIDEACCESSORY))
		return TRUE

	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		H.update_inv_gloves()

	return TRUE

/obj/item/clothing/gloves/proc/remove_accessory(mob/user)
	if(!isliving(user))
		return
	if(!can_use(user))
		return

	if(!LAZYLEN(accessories_attached))
		return
	var/obj/item/clothing/accessory/ring/accessory = accessories_attached[length(accessories_attached)]
	accessory.detach(src, user)
	if(user.put_in_hands(accessory))
		to_chat(user, span_notice("You detach [accessory] from [src]."))
	else
		to_chat(user, span_notice("You detach [accessory] from [src] and it falls on the floor."))

	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		H.update_inv_gloves()

/obj/item/clothing/gloves/examine(mob/user)
	. = ..()
	for(var/obj/item/clothing/accessory/ring/attached_accessory as anything in accessories_attached)
		. += "\A [attached_accessory] is attached to one of its fingers."
