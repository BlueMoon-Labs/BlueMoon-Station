/obj/item/strapon_strap
	name = "strapon strap"
	desc = "A strap used to create strapons. Attach a dildo onto it to create a strapon."
	icon = 'modular_splurt/icons/obj/strapon.dmi'
	icon_state = "strapon_strap"
	item_state = "strapon_strap"
	w_class = WEIGHT_CLASS_SMALL // BLUEMOON ADD

/obj/item/strapon_strap/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/dildo))
		to_chat(user, span_userlove("You attach the dildo to the strap."))

		var/obj/item/dildo/dildo = I
		var/obj/item/clothing/underwear/briefs/strapon/new_strapon = new /obj/item/clothing/underwear/briefs/strapon(user.loc)
		//BLUEMOON EDIT START
		if(!user.transferItemToLoc(dildo, new_strapon))
			return
		new_strapon.attached_dildo = dildo
		new_strapon.cut_overlays()
		new_strapon.update_icon_state()
		new_strapon.update_icon()
		if(loc == user)
			qdel(src)
			user.put_in_hands(new_strapon)
		//BLUEMOON EDIT END
		else
			qdel(src)
	else
		return ..()

/obj/item/clothing/underwear/briefs/strapon
	name = "strapon"
	desc = "A dildo on a strap, to be attached around one's waist."
	icon = 'modular_splurt/icons/obj/strapon.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/strapon.dmi'
	icon_state = "strapon_base"
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	flags_inv = NONE
	//BLUEMOON EDIT START
	var/obj/item/dildo/attached_dildo = new /obj/item/dildo/custom
	//BLUEMOON EDIT END

//BLUEMOON ADD START
/obj/item/clothing/underwear/briefs/strapon/Initialize(mapload)
	. = ..()
	update_icon_state()
	update_icon()
//BLUEMOON ADD END

/obj/item/clothing/underwear/briefs/strapon/update_overlays()
	. = ..()
	var/mutable_appearance/dildo_overlay = mutable_appearance('modular_splurt/icons/obj/strapon.dmi', "strapon_[attached_dildo.dildo_shape]") // BLUEMOON EDIT
	dildo_overlay.color = attached_dildo.color // BLUEMOON EDIT
	add_overlay(dildo_overlay)

/obj/item/clothing/underwear/briefs/strapon/examine(mob/user)
	. = ..()
	. += "There is a <span class='notice'>[attached_dildo.name]</span> attached to it." //BLUEMOON EDIT
	. += span_notice("Alt-Click \the [src.name] to separate the strap and dildo.")

/obj/item/clothing/underwear/briefs/strapon/AltClick(mob/living/user, obj/item/I)
	to_chat(user, span_userlove("You separate the dildo from the strap."))
	var/obj/item/strapon_strap/new_strapon_strap = new /obj/item/strapon_strap(user.loc)
	//BLUEMOON EDIT START
	var/obj/item/dildo/new_dildo = attached_dildo
	new_dildo.forceMove(user.loc)
	attached_dildo = null
	//BLUEMOON EDIT END
	if(loc == user)
		qdel(src)
		user.put_in_hands(new_strapon_strap)
		user.put_in_hands(new_dildo)
	else
		qdel(src)

/obj/item/clothing/underwear/briefs/strapon/proc/is_exposed()
	if(!istype(loc, /mob/living/carbon))
		return FALSE

	var/mob/living/carbon/owner = loc
	var/L = owner.get_equipped_items()
	L -= src
	return owner.is_groin_exposed(L)

/obj/item/clothing/underwear/briefs/strapon/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_UNDERWEAR)
		return

	if(istype(user, /mob/living/carbon))
		var/mob/living/carbon/C = user
		to_chat(C, span_userlove("You're now ready to bone someone!"))

/obj/item/clothing/underwear/briefs/strapon/mob_can_equip(M, equipper, slot, disable_warning, bypass_equip_delay_self)
	if(!..())
		return FALSE
	return TRUE
