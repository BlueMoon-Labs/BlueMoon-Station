/obj/item/clothing/head
	name = BODY_ZONE_HEAD
	icon = 'icons/obj/clothing/hats.dmi'
	icon_state = "top_hat"
	item_state = "that"
	body_parts_covered = HEAD
	slot_flags = ITEM_SLOT_HEAD
	var/blockTracking = 0 //For AI tracking
	dynamic_hair_suffix = ""
	var/datum/beepsky_fashion/beepsky_fashion //the associated datum for applying this to a secbot
	var/vision_flags = NONE
	var/darkness_view = 2//Base human is 2
	var/invis_view = SEE_INVISIBLE_LIVING	//admin only for now
	var/lighting_alpha

/obj/item/clothing/head/Initialize(mapload)
	. = ..()
	if(ishuman(loc) && dynamic_hair_suffix)
		var/mob/living/carbon/human/H = loc
		H.update_hair()

///Special throw_impact for hats to frisbee hats at people to place them on their heads.
/obj/item/clothing/head/throw_impact(atom/hit_atom, datum/thrownthing/thrownthing)
	. = ..()
	///if the thrown object's target zone isn't the head
	if(thrownthing.target_zone != BODY_ZONE_HEAD)
		return
	///ignore any hats with downsides when worn
	if(clothing_flags & IGNORE_HAT_TOSS)
		return
	///if the hat happens to be capable of holding contents and has something in it. mostly to prevent super cheesy stuff like stuffing a mini-bomb in a hat and throwing it
	if(LAZYLEN(contents))
		return
	if(iscarbon(hit_atom))
		var/mob/living/carbon/H = hit_atom
		if(istype(H.head, /obj/item))
			var/obj/item/WH = H.head
			H.visible_message("<span class='warning'>[src] bounces off [H]'s [WH.name]!", "<span class='warning'>[src] bounces off your [WH.name], falling to the floor.</span>")
			return
		if(H.equip_to_slot_if_possible(src, ITEM_SLOT_HEAD, FALSE, TRUE))
			H.visible_message("<span class='notice'>[src] lands neatly on [H]'s head!", "<span class='notice'>[src] lands perfectly onto your head!</span>")
		return
	if(iscyborg(hit_atom))
		var/mob/living/silicon/robot/R = hit_atom
		///hats in the borg's blacklist bounce off
		if(is_type_in_typecache(src, GLOB.blacklisted_borg_hats))
			R.visible_message("<span class='warning'>[src] bounces off [R]!</span>", "<span class='warning'>[src] bounces off you, falling to the floor.</span>")
			return
		else
			R.visible_message("<span class='notice'>[src] lands neatly on top of [R]!</span>", "<span class='notice'>[src] lands perfectly on top of you.</span>")
			R.place_on_head(src) //hats aren't designed to snugly fit borg heads or w/e so they'll always manage to knock eachother off



/obj/item/clothing/head/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(!isinhands)
		if(damaged_clothes)
			. += mutable_appearance('icons/effects/item_damage.dmi', "damagedhelmet")
		if(blood_DNA)
			. += mutable_appearance('icons/effects/blood.dmi', "helmetblood", color = blood_DNA_to_color(), blend_mode = blood_DNA_to_blend())

/obj/item/clothing/head/update_clothes_damaged_state()
	..()
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_head()

/obj/item/clothing/head/visor_toggling()
	..()
	if(visor_vars_to_toggle & VISOR_VISIONFLAGS)
		vision_flags ^= initial(vision_flags)
	if(visor_vars_to_toggle & VISOR_DARKNESSVIEW)
		darkness_view ^= initial(darkness_view)
	if(visor_vars_to_toggle & VISOR_INVISVIEW)
		invis_view ^= initial(invis_view)
