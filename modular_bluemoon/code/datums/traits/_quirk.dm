/datum/quirk/proc/give_item(obj/item/item_path, mob/living/carbon/human/H)
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET
	)

	var/T = new item_path(H)
	var/item_name = initial(item_path.name)
	var/where
	if(istype(T, /obj/item/clothing/accessory))
		var/obj/item/clothing/accessory/A = T
		var/obj/item/clothing/wear = H.get_item_by_slot(A.accessory_slot)
		// Пробуем крепить к одежде
		if(istype(wear) && wear.attach_accessory(A, H, FALSE))
			where = A.accessory_slot

	where = where || H.equip_in_one_of_slots(T, slots, critical = TRUE)
	if(!where)
		to_chat(H, "<span class='userdanger'>Unfortunately, you weren't able to get a [item_name]. This is very bad and you should adminhelp immediately (press F1).</span>")
		return FALSE
	else
		//to_chat(H, "<span class='danger'>You have a [item_name] in your [where].</span>")
		if(where == "backpack")
			SEND_SIGNAL(H.back, COMSIG_TRY_STORAGE_SHOW, H)
		return TRUE
