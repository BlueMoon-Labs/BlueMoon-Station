/obj/item/storage/wallet
	name = "wallet"
	desc = "It can hold a few small and personal things."
	icon_state = "wallet"
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = FLAMMABLE
	slot_flags = ITEM_SLOT_ID

	var/obj/item/card/id/front_id = null
	var/list/combined_access

/obj/item/storage/wallet/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 4
	STR.cant_hold = typecacheof(list(/obj/item/screwdriver/power))
	STR.can_hold = typecacheof(list(
		/obj/item/stack/spacecash,
		/obj/item/holochip,
		/obj/item/card,
		/obj/item/clothing/mask/cigarette,
		/obj/item/flashlight/pen,
		/obj/item/seeds,
		/obj/item/stack/medical,
		/obj/item/toy/crayon,
		/obj/item/coin,
		/obj/item/dice,
		/obj/item/disk,
		/obj/item/implanter,
		/obj/item/lighter,
		/obj/item/lipstick,
		/obj/item/match,
		/obj/item/paper,
		/obj/item/pen,
		/obj/item/photo,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/syringe,
		/obj/item/screwdriver,
		/obj/item/valentine,
		/obj/item/stamp,
		/obj/item/key,
		/obj/item/cartridge,
		/obj/item/camera_film,
		/obj/item/stack/ore/bluespace_crystal,
		/obj/item/reagent_containers/food/snacks/grown/poppy,
		/obj/item/reagent_containers/hypospray/medipen,
		/obj/item/instrument/harmonica,
		/obj/item/mining_voucher,
		/obj/item/suit_voucher,
		/obj/item/reagent_containers/pill,
		/obj/item/gun/ballistic/derringer,
		/obj/item/genital_equipment/condom,
		/obj/item/card_sticker,
		/obj/item/clothing/accessory/permit,
		/obj/item/clothing/accessory/ring,
		/obj/item/clothing/accessory/hateredsoul_dogtag,
		/obj/item/clothing/accessory/SATTdogtag,
		/obj/item/clothing/accessory/indiv_number,
		))

/obj/item/storage/wallet/get_examine_string(mob/user, thats)
	. = ..()
	if(front_id)
		//. += " with [icon2html(front_id.get_cached_flat_icon(), user)] \a [front_id] on the front."
		. += " with \a [front_id.get_examine_string(user)] on the front"

/obj/item/storage/wallet/Exited(atom/movable/AM)
	. = ..()
	refreshID()

// BLUEMOON ADD START
/obj/item/storage/wallet/examine(mob/user)
	. = ..()
	. += span_notice("Ctrl-click to fast take ID.")

/obj/item/storage/wallet/CtrlClick(mob/user)
	. = ..()
	for(var/obj/item/I in contents)
		if(I.GetID())
			user.put_in_hands(I)
			refreshID()
			return TRUE
// BLUEMOON ADD END

/obj/item/storage/wallet/proc/refreshID()
	LAZYCLEARLIST(combined_access)
	if(!(front_id in src))
		front_id = null
	for(var/obj/item/card/id/I in contents)
		if(!front_id)
			front_id = I
		LAZYINITLIST(combined_access)
		combined_access |= I.access
	// BLUEMOON ADD START
	for(var/obj/item/pda/PDA in contents)
		var/obj/item/card/id/I = PDA.GetID()
		if(!istype(I))
			continue
		if(!front_id)
			front_id = I
		LAZYINITLIST(combined_access)
		combined_access |= I.access
	// BLUEMOON ADD END
	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		if(H.wear_id == src)
			H.sec_hud_set_ID()
	update_icon()

/obj/item/storage/wallet/Entered(atom/movable/AM)
	. = ..()
	refreshID()

/obj/item/storage/wallet/update_icon_state()
	var/new_state = "wallet"
	if(front_id)
		new_state = "wallet_id"
	if(new_state != icon_state)		//avoid so many icon state changes.
		icon_state = new_state

/obj/item/storage/wallet/GetID()
	return front_id

/obj/item/storage/wallet/RemoveID()
	if(!front_id)
		return
	. = front_id
	front_id.forceMove(get_turf(src))

/obj/item/storage/wallet/InsertID(obj/item/inserting_item)
	var/obj/item/card/inserting_id = inserting_item.RemoveID()
	if(!inserting_id)
		return FALSE
	attackby(inserting_id)
	if(inserting_id in contents)
		return TRUE
	return FALSE

/obj/item/storage/wallet/GetAccess()
	if(LAZYLEN(combined_access))
		return combined_access
	else
		return ..()

/obj/item/storage/wallet/random
	icon_state = "random_wallet"

/obj/item/storage/wallet/random/PopulateContents()
	new /obj/item/holochip(src, rand(5,30))
	icon_state = "wallet"
