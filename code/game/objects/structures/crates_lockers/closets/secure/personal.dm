/obj/structure/closet/secure_closet/personal
	desc = "It's a secure locker for personnel. The first card swiped gains control."
	name = "personal closet"
	req_access = list(ACCESS_ALL_PERSONAL_LOCKERS)
	var/registered_name = null
	var/reprograming = FALSE

/obj/structure/closet/secure_closet/personal/PopulateContents()
	..()
	if(prob(50))
		new /obj/item/storage/backpack/duffelbag(src)
	if(prob(50))
		new /obj/item/storage/backpack(src)
	else
		new /obj/item/storage/backpack/satchel(src)
	new /obj/item/radio/headset( src )

/obj/structure/closet/secure_closet/personal/patient
	name = "patient's closet"

/obj/structure/closet/secure_closet/personal/patient/PopulateContents()
	new /obj/item/clothing/under/color/white( src )
	new /obj/item/clothing/shoes/sneakers/white( src )

/obj/structure/closet/secure_closet/personal/cabinet
	icon_state = "cabinet"
	resistance_flags = FLAMMABLE
	max_integrity = 70
	material_drop = /obj/item/stack/sheet/mineral/wood
	cutting_tool = TOOL_SCREWDRIVER
	door_anim_time = 0 // no animation

/obj/structure/closet/secure_closet/personal/cabinet/PopulateContents()
	new /obj/item/storage/backpack/satchel/leather/withwallet( src )
	new /obj/item/instrument/piano_synth(src)
	new /obj/item/radio/headset( src )

/obj/structure/closet/secure_closet/personal/closet_update_overlays(list/new_overlays)
	. = ..()
	if(reprograming)
		. += "reprogram"

/obj/structure/closet/secure_closet/personal/attackby(obj/item/W, mob/user, params)
	var/obj/item/card/id/I = W.GetID()
	if(istype(I))
		if(broken)
			to_chat(user, "<span class='danger'>It appears to be broken.</span>")
			return
		if(!I || !I.registered_name)
			return
		var/is_access_open = allowed(user)
		if(is_access_open || !registered_name || (istype(I) && (registered_name == I.registered_name)))
			//they can open all lockers, or nobody owns this, or they own this locker
			locked = !locked
			update_icon()

			// don't register name
			if(is_access_open)
				return

			if(!registered_name)
				registered_name = I.registered_name
				desc = "Owned by [I.registered_name]."
		else if(!locked && registered_name && istype(I) && (registered_name != I.registered_name)) // Reprogram
			reprograming = TRUE
			update_icon()
			playsound(src, 'sound/rig/beep.ogg',80,TRUE)
			user.visible_message(span_warning("<b>[user]</b> started to reprogram the locker of <b>[registered_name]</b> for himself!"))

			var/failed = !do_after(user, 7 SECONDS, src)
			reprograming = FALSE
			update_icon()
			if(failed)
				return
			registered_name = I.registered_name
			desc = "Owned by [I.registered_name]."
		else
			to_chat(user, "<span class='danger'>Access Denied.</span>")
	else
		return ..()

/obj/structure/closet/secure_closet/personal/togglelock(mob/living/user, silent)
	if(secure && !broken && registered_name && ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/card/id/I = H.wear_id.GetID()
		if(istype(I) && (registered_name == I.registered_name))
			add_fingerprint(user)
			locked = !locked
			user.visible_message("<span class='notice'>[user] [locked ? null : "un"]locks [src].</span>",
							"<span class='notice'>You [locked ? null : "un"]lock [src].</span>")
			update_icon()
		else
			return ..()
	else
		return ..()


/obj/structure/closet/secure_closet/personal/handle_lock_addition() //If lock construction is successful we don't care what access the electronics had, so we override it
	if(..())
		req_access = list(ACCESS_ALL_PERSONAL_LOCKERS)
		lockerelectronics.accesses = req_access

/obj/structure/closet/secure_closet/personal/handle_lock_removal()
	if(..())
		registered_name = null
