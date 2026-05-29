/obj/item/folder/biscuit
	name = "Biscuit card"
	desc = "A biscuit card. On the back, <b>DO NOT DIGEST</b> is printed in large lettering."
	icon_state = "paperbiscuit"
	bg_color = "#ffffff"
	w_class = WEIGHT_CLASS_TINY
	max_integrity = 130
	drop_sound = 'sound/items/handling/disk_drop.ogg'
	pickup_sound = 'sound/items/handling/disk_pickup.ogg'
	contents_hidden = TRUE
	max_contents = 1
	/// Is biscuit cracked open or not?
	var/cracked = FALSE
	/// Разрешено ли переименовывать?
	var/allow_labeling = FALSE
	/// The paper slip inside, if there is one
	var/obj/item/paper/paperslip/contained_slip

/obj/item/folder/biscuit/Initialize(mapload)
	. = ..()
	if(ispath(contained_slip, /obj/item/paper/paperslip))
		contained_slip = new contained_slip(src)

/obj/item/folder/biscuit/examine(mob/user)
	. = ..()
	if(cracked)
		. += span_notice("It's been cracked open.")
		if(contained_slip)
			. += span_notice("This one contains [contained_slip.name].")
	else
		. += span_notice("You'll need to crack it open to access its contents.")

/obj/item/folder/biscuit/Destroy()
	if(isdatum(contained_slip))
		QDEL_NULL(contained_slip)
	return ..()

/obj/item/folder/biscuit/Exited(atom/movable/AM, atom/newLoc)
	. = ..()
	if(contained_slip == AM)
		contained_slip = null

/obj/item/folder/biscuit/Entered(atom/movable/AM, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(isnull(contained_slip) && istype(AM, /obj/item/paper/paperslip))
		contained_slip = AM

/obj/item/folder/biscuit/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] tries to eat [src]! [user.p_theyre()] trying to commit suicide!"))
	playsound(get_turf(user), 'sound/effects/wounds/crackandbleed.ogg', 40, TRUE) //Don't eat plastic cards kids, they get really sharp if you chew on them.
	return BRUTELOSS

/obj/item/folder/biscuit/update_overlays()
	. = ..()
	if(contents.len) //This is to prevent the unsealed biscuit from having the folder_paper overlay when it gets sealed
		. -= "folder_paper"
		if(cracked) //Shows overlay only when it has contents and is cracked open
			. += "paperbiscuit_paper"

/obj/item/folder/biscuit/rename(mob/user, obj/item/writing_instrument)
	if(!allow_labeling)
		return FALSE
	. = ..()
	if(.) // Только 1 смена названия
		allow_labeling = FALSE

///Checks if the biscuit has been already cracked.
/obj/item/folder/biscuit/proc/crack_check(mob/living/user)
	if (cracked)
		return TRUE
	balloon_alert(user, "unopened!")
	return FALSE

//The next few checks are done to prevent you from reaching the contents or putting anything inside when it's not cracked open
/obj/item/folder/biscuit/remove_item(obj/item/Item, mob/living/user)
	if (!crack_check(user))
		return

	return ..()

/obj/item/folder/biscuit/attackby(obj/item/I, mob/living/user, params)
	if (is_type_in_typecache(I, folder_insertables) && !crack_check(user))
		return

	return ..()

/obj/item/folder/biscuit/attack_self(mob/user)
	add_fingerprint(user)
	if(!cracked)
		if (tgui_alert(user, "Do you want to crack it open?", "Biscuit Cracking", list("Yes", "No")) != "Yes")
			return
		cracked = TRUE
		contents_hidden = FALSE
		playsound(get_turf(user), 'sound/effects/wounds/crack1.ogg', 60)
		icon_state = "[icon_state]_cracked"
		update_appearance()
	else if(LAZYLEN(contents))
		remove_item(contents[1], user)
	ui_interact(user)

/obj/item/folder/biscuit/ui_interact(mob/user, datum/tgui/ui)
	return FALSE

//Corporate "confidential" biscuit cards
/obj/item/folder/biscuit/confidential
	name = "Confidential biscuit card"
	desc = "A confidential biscuit card. The tasteful blue color and NT logo on the front makes it look a little like a chocolate bar. \
		On the back, <b>DO NOT DIGEST</b> is printed in large lettering."
	icon_state = "paperbiscuit_secret"
	bg_color = "#355e9f"

/obj/item/folder/biscuit/confidential/spare_id_safe_code
	name = "Spare ID safe code biscuit card"
	contained_slip = /obj/item/paper/paperslip/spare_id_safe_code

//Biscuits which start open. Used for crafting, printing, and such
/obj/item/folder/biscuit/unsealed
	name = "Biscuit card"
	desc = "A biscuit card. On the back, <b>DO NOT DIGEST</b> is printed in large lettering."
	icon_state = "paperbiscuit_cracked"
	contents_hidden = FALSE
	cracked = TRUE
	allow_labeling = TRUE
	///Was the biscuit already sealed by players? Prevents re-sealing after use
	var/has_been_sealed = FALSE
	///What is the sprite for when it's sealed? It starts unsealed, so needs a sprite for when it's sealed.
	var/sealed_icon = "paperbiscuit"

/obj/item/folder/biscuit/unsealed/examine(mob/user)
	. = ..()
	if(!has_been_sealed)
		. += span_notice("This one could be sealed <b>in hand</b>. Once sealed, the contents are inaccessible until cracked open again - but once opened this is irreversible.")

//Asks if you want to seal the biscuit, after you do that it behaves like a normal paper biscuit.
/obj/item/folder/biscuit/unsealed/attack_self(mob/user)
	if(!cracked || has_been_sealed)
		return ..()
	if(tgui_alert(user, "Do you want to seal it? This can only be done once.", "Biscuit Sealing", list("Yes", "No")) != "Yes")
		return ..()
	add_fingerprint(user)
	cracked = FALSE
	has_been_sealed = TRUE
	contents_hidden = TRUE
	playsound(get_turf(user), 'sound/items/duct_tape_snap.ogg', 60)
	icon_state = "[sealed_icon]"
	update_appearance()

/obj/item/folder/biscuit/unsealed/confidential
	name = "Confidential biscuit card"
	desc = "A confidential biscuit card. The tasteful blue color and NT logo on the front makes it look a little like a chocolate bar. On the back, <b>DO NOT DIGEST</b> is printed in large lettering."
	icon_state = "paperbiscuit_secret_cracked"
	bg_color = "#355e9f"
	sealed_icon = "paperbiscuit_secret"
