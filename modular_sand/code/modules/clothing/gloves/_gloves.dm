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
		remove_accessory(user = user)

/obj/item/clothing/gloves/equipped(mob/user, slot)
	..()

	for(var/obj/item/clothing/accessory/ring/attached_accessory as anything in accessories_attached)
		if(attached_accessory && slot == ITEM_SLOT_HANDS && ishuman(user))
			attached_accessory.on_uniform_equip(src, user)

/obj/item/clothing/gloves/dropped(mob/user)
	for(var/obj/item/clothing/accessory/ring/attached_accessory as anything in accessories_attached)
		attached_accessory.on_uniform_dropped(src, user)
	..()

/obj/item/clothing/gloves/attach_accessory(obj/item/clothing/accessory/ring/accessory, mob/user, silent = FALSE)
	. = FALSE
	if(!istype(accessory))
		return
	if(length(accessories_attached) >= max_accessories)
		if(user && !silent)
			to_chat(user, "<span class='warning'>[src] already has [length(accessories_attached)] accessories.</span>")
		return
	if(dummy_thick)
		if(user && !silent)
			to_chat(user, "<span class='warning'>[src] is too bulky and cannot have accessories attached to it!</span>")
		return
	if(user && !user.dropItemToGround(accessory, silent = silent))
		return
	if(!accessory.attach(src, user))
		return

	if(user && !silent)
		to_chat(user, "<span class='notice'>You attach [accessory] to [src].</span>")

	if((flags_inv & HIDEACCESSORY) || (accessory.flags_inv & HIDEACCESSORY))
		return TRUE

	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		H.update_inv_gloves()

	return TRUE

/obj/item/clothing/gloves/remove_accessory(obj/item/clothing/accessory/accessory, mob/user, silent = FALSE)
	. = FALSE
	if(!isliving(user))
		return
	if(!accessory && !can_use(user))
		return

	if(!LAZYLEN(accessories_attached))
		return
	accessory = (accessories_attached.Find(accessory) && accessory) || accessories_attached[length(accessories_attached)]
	if(!istype(accessory))
		return
	accessory.detach(src, user)
	var/in_hand = user.put_in_hands(accessory, FALSE)
	if(!silent)
		to_chat(user, span_notice("Вы открепили [accessory] от [src][in_hand ? null : " с падением предмета на пол"]."))

	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		H.update_inv_gloves()
	return TRUE

/obj/item/clothing/gloves/examine(mob/user)
	. = ..()
	for(var/obj/item/clothing/accessory/ring/attached_accessory as anything in accessories_attached)
		. += "\A [attached_accessory] is attached to one of its fingers."
