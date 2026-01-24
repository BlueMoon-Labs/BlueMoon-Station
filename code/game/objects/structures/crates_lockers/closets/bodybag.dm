
/obj/structure/closet/body_bag
	name = "body bag"
	desc = "A plastic bag designed for the storage and transportation of cadavers."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "bodybag"
	density = FALSE
	mob_storage_capacity = 2
	open_sound = 'sound/items/zip.ogg'
	close_sound = 'sound/items/zip.ogg'
	integrity_failure = 0
	material_drop = /obj/item/stack/sheet/cloth
	delivery_icon = null //unwrappable
	anchorable = FALSE
	var/foldedbag_path = /obj/item/bodybag
	var/tagged = 0 // so closet code knows to put the tag overlay back

/obj/structure/closet/body_bag/attackby(obj/item/I, mob/user, params)
	if (istype(I, /obj/item/pen) || istype(I, /obj/item/toy/crayon))
		if(!user.can_write(I))
			to_chat(user, "<span class='notice'>You scribble illegibly on [src]!</span>")
			return
		var/t = stripped_input(user, "What would you like the label to be?", name, null, 53)
		if(user.get_active_held_item() != I)
			return
		if(!user.canUseTopic(src, BE_CLOSE))
			return
		if(t)
			name = "body bag - [t]"
			tagged = 1
			update_icon()
		else
			name = "body bag"
		return
	else if(I.tool_behaviour == TOOL_WIRECUTTER)
		to_chat(user, "<span class='notice'>You cut the tag off [src].</span>")
		name = "body bag"
		tagged = 0
		update_icon()

/obj/structure/closet/body_bag/update_overlays()
	. = ..()
	if (tagged)
		. += "bodybag_label"

/obj/structure/closet/body_bag/close()
	if(..())
		density = FALSE
		return TRUE
	return FALSE

/obj/structure/closet/body_bag/handle_lock_addition()
	return

/obj/structure/closet/body_bag/handle_lock_removal()
	return

/obj/structure/closet/body_bag/MouseDrop(over_object, src_location, over_location)
	. = ..()
	if(over_object == usr && Adjacent(usr) && (in_range(src, usr) || usr.contents.Find(src)))
		if(!ishuman(usr))
			return FALSE
		if(contents.len)
			return FALSE
		visible_message("<span class='notice'>[usr] folds up [src].</span>")
		var/obj/item/bodybag/B = new foldedbag_path(get_turf(src))
		usr.put_in_hands(B)
		qdel(src)

/obj/structure/closet/body_bag/bluespace
	name = "bluespace body bag"
	desc = "A bluespace body bag designed for the storage and transportation of cadavers."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "bluebodybag"
	foldedbag_path = /obj/item/bodybag/bluespace
	mob_storage_capacity = 15
	max_mob_size = MOB_SIZE_LARGE

/obj/structure/closet/body_bag/bluespace/MouseDrop(over_object, src_location, over_location)
	. = ..()
	if(over_object == usr && Adjacent(usr) && (in_range(src, usr) || usr.contents.Find(src)))
		if(!ishuman(usr))
			return FALSE
		if(contents.len >= mob_storage_capacity / 2)
			to_chat(usr, "<span class='warning'>There are too many things inside of [src] to fold it up!</span>")
			return FALSE
		for(var/obj/item/bodybag/bluespace/B in src)
			to_chat(usr, "<span class='warning'>You can't recursively fold bluespace body bags!</span>" )
			return FALSE
		visible_message("<span class='notice'>[usr] folds up [src].</span>")
		var/obj/item/bodybag/B = new foldedbag_path(get_turf(src))
		usr.put_in_hands(B)
		for(var/atom/movable/A in contents)
			A.forceMove(B)
			if(isliving(A))
				to_chat(A, "<span class='userdanger'>You're suddenly forced into a tiny, compressed space!</span>")
		qdel(src)

/obj/structure/closet/body_bag/containment
	name = "containment body bag"
	desc = "A folded heavy body bag designed for the storage and transportation of cadavers with heavy radiation."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "radbodybag"
	mob_storage_capacity = 1
	foldedbag_path = /obj/item/bodybag/containment
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	/// The list of weathers we protect from.
	var/list/weather_protection = list(TRAIT_ASHSTORM_IMMUNE, TRAIT_RADSTORM_IMMUNE, TRAIT_SNOWSTORM_IMMUNE, TRAIT_VOIDSTORM_IMMUNE) // Does not protect against lava or the The Floor Is Lava spell.
	/// The contents of the gas to be distributed to an occupant. Set in Initialize()
	var/datum/gas_mixture/air_contents = null

/obj/structure/closet/body_bag/containment/nanotrasen
	name = "elite containment protection bag"
	desc = "A heavily reinforced and insulated bag, capable of fully isolating its contents from external factors."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "ntenvirobag"
	foldedbag_path = /obj/item/bodybag/containment/nanotrasen
	weather_protection = list(TRAIT_WEATHER_IMMUNE)

/// Securable enviro. bags

/obj/structure/closet/body_bag/containment/prisoner
	name = "prisoner transport bag"
	desc = "Intended for transport of prisoners through hazardous environments, this containment protection bag comes with straps to keep an occupant secure."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "prisonerenvirobag"
	foldedbag_path = /obj/item/bodybag/containment/prisoner
	breakout_time = 4 MINUTES // because it's probably about as hard to get out of this as it is to get out of a straightjacket.
	/// How long it takes to sinch the bag.
	var/sinch_time = 10 SECONDS
	/// Whether or not the bag is sinched. Starts unsinched.
	var/sinched = FALSE
	/// The sound that plays when the bag is done sinching.
	var/sinch_sound = 'sound/items/equip/toolbelt_equip.ogg'

/obj/structure/closet/body_bag/containment/prisoner/MouseDrop(mob/living/carbon/human/the_folder)
	if(sinched)
		to_chat(the_folder, span_warning("You wrestle with [src], but it won't fold while its straps are fastened."))
	return ..()

/obj/structure/closet/body_bag/containment/prisoner/update_icon()
	. = ..()
	if(sinched)
		icon_state = initial(icon_state) + "_sinched"
	else
		icon_state = initial(icon_state)

/obj/structure/closet/body_bag/containment/prisoner/open(mob/living/user, force = FALSE)
	if(sinched && !force)
		to_chat(user, span_danger("The buckles on [src] are sinched down, preventing it from opening."))
		return TRUE
	if(opened)
		return FALSE
	sinched = FALSE
	playsound(loc, open_sound, sinch_sound, TRUE, -3)
	opened = TRUE
	dump_contents()
	update_appearance()
	after_open(user, force)
	return TRUE

/obj/structure/closet/body_bag/containment/prisoner/container_resist_act(mob/living/user)
	/// copy-pasted with changes because flavor text as well as some other misc stuff
	if(opened)
		return
	if(ismovable(loc))
		user.changeNext_move(CLICK_CD_BREAKOUT)
		user.last_special = world.time + CLICK_CD_BREAKOUT
		var/atom/movable/location = loc
		location.relay_container_resist(user, src)
		return
	if(!sinched)
		open()
		return

	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message(span_warning("Someone in [src] begins to wriggle!"), \
		span_notice("You start wriggling, attempting to loosen [src]'s buckles... (this will take about [DisplayTimeText(breakout_time)].)"), \
		span_hear("You hear straining cloth from [src]."))
	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || opened || !sinched )
			return
		//we check after a while whether there is a point of resisting anymore and whether the user is capable of resisting
		user.visible_message(span_danger("[user] successfully broke out of [src]!"),
							span_notice("You successfully break out of [src]!"))
		bust_open()
	else
		if(user.loc == src) //so we don't get the message if we resisted multiple times and succeeded.
			to_chat(user, span_warning("You fail to break out of [src]!"))


/obj/structure/closet/body_bag/containment/prisoner/bust_open()
	sinched = FALSE
	// We don't break the bag, because the buckles were backed out as opposed to fully broken.
	open()

/obj/structure/closet/body_bag/containment/prisoner/togglelock(mob/living/user, silent)
	if(opened)
		to_chat(user, span_warning("You can't close the buckles while [src] is unzipped!"))
		return
	if(user in contents)
		to_chat(user, span_warning("You can't reach the buckles from here!"))
		return
	if(iscarbon(user))
		add_fingerprint(user)
	if(!sinched)
		for(var/mob/living/target in contents)
			to_chat(target, span_userdanger("You feel the lining of [src] tighten around you! Soon, you won't be able to escape!"))
		user.visible_message(span_notice("[user] begins sinching down the buckles on [src]."))
		if(!(do_after(user,(sinch_time),target = src)))
			return
	sinched = !sinched
	if(sinched)
		playsound(loc, sinch_sound, 15, TRUE, -2)
	user.visible_message(span_notice("[user] [sinched ? null : "un"]sinches [src]."),
							span_notice("You [sinched ? null : "un"]sinch [src]."),
							span_hear("You hear stretching followed by metal clicking from [src]."))
	user.log_message("[sinched ? "sinched":"unsinched"] secure containment bag [src]", LOG_GAME)
	update_appearance()

/obj/structure/closet/body_bag/containment/prisoner/syndicate
	name = "syndicate prisoner transport bag"
	desc = "An alteration of Nanotrasen's containment protection bag which has been used in several high-profile kidnappings. Designed to keep a victim unconscious, alive, and secured during transport."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "syndieenvirobag"
	foldedbag_path = /obj/item/bodybag/containment/prisoner/syndicate
	weather_protection = list(TRAIT_WEATHER_IMMUNE)
	breakout_time = 8 MINUTES
	sinch_time = 20 SECONDS
