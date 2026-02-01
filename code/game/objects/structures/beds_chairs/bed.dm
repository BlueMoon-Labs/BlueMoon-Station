/* Beds... get your mind out of the gutter, they're for sleeping!
 * Contains:
 * 		Beds
 *		Roller beds
 */

/*
 * Beds
 */
/obj/structure/bed
	name = "bed"
	desc = "This is used to lie in, sleep in or strap on."
	icon_state = "bed"
	icon = 'icons/obj/objects.dmi'
	anchored = TRUE
	can_buckle = TRUE
	buckle_lying = TRUE
	resistance_flags = FLAMMABLE
	max_integrity = 100
	integrity_failure = 0.35
	var/buildstacktype = /obj/item/stack/sheet/metal
	var/buildstackamount = 2
	var/bolts = TRUE

/obj/structure/bed/examine(mob/user)
	. = ..()
	if(bolts)
		. += "<span class='notice'>Держится на парочке <b>болтов</b>.</span>"

/obj/structure/bed/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(buildstacktype)
			new buildstacktype(loc,buildstackamount)
	..()

/obj/structure/bed/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/bed/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH && !(flags_1&NODECONSTRUCT_1))
		W.play_tool_sound(src)
		deconstruct(TRUE)
	else if(istype(W, /obj/item/bedsheet))
		if(user.transferItemToLoc(W, drop_location()))
			to_chat(user, "<span class='notice'>You make \the [src] with [W].</span>")
			W.pixel_x = 0
			W.pixel_y = 0
	else if(istype(W, /obj/item/disk/nuclear))
		if(user.transferItemToLoc(W, drop_location()))
			to_chat(user, "<span class='notice'>You tuck little disky into bed. Good night disky.</span>")
			W.pixel_x = 6 //make sure they reach the pillow
			W.pixel_y = -6
	else
		return ..()

/obj/structure/bed/post_buckle_mob(mob/living/target)
	. = ..()
	target.pixel_y = target.get_standard_pixel_y_offset(TRUE)

/obj/structure/bed/double/post_unbuckle_mob(mob/living/target)
	. = ..()
	target.pixel_y = target.get_standard_pixel_y_offset(FALSE)

/*
 * Roller beds
 */
/obj/structure/bed/roller
	name = "Roller bed"
	desc = "Складываемая каталка, пригодная к ручной переноске."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "down"
	anchored = FALSE
	resistance_flags = NONE
	var/up = FALSE
	var/foldabletype = /obj/item/roller

/obj/structure/bed/roller/update_icon_state()
	. = ..()
	if(up)
		icon_state = "up"
	else
		icon_state = "down"

/obj/structure/bed/roller/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/roller/robo))
		var/obj/item/roller/robo/R = W
		if(R.loaded)
			to_chat(user, "<span class='warning'>You already have a roller bed docked!</span>")
			return

		if(has_buckled_mobs())
			if(buckled_mobs.len > 1)
				unbuckle_all_mobs()
				user.visible_message("<span class='notice'>[user] unbuckles all creatures from [src].</span>")
			else
				user_unbuckle_mob(buckled_mobs[1],user)
		else
			R.loaded = src
			forceMove(R)
			user.visible_message("[user] collects [src].", "<span class='notice'>You collect [src].</span>")
		return TRUE
	else
		return ..()

/obj/structure/bed/roller/MouseDrop(over_object, src_location, over_location)
	. = ..()
	if(over_object != usr)
		return .
	fold_roller(usr)

/obj/structure/bed/roller/proc/fold_roller(mob/user)
	if(Adjacent(user))
		if(!ishuman(user) || !user.canUseTopic(src, BE_CLOSE))
			return FALSE
		if(has_buckled_mobs())
			return FALSE
		user.visible_message("[user] collapses \the [src.name].", "<span class='notice'>You collapse \the [src.name].</span>")
		var/obj/item/roller/I = new foldabletype(get_turf(src))
		. = I
		user.put_in_hands(I)
		after_fold_roller(user, I)

/obj/structure/bed/roller/proc/after_fold_roller(mob/user, /obj/item/roller/I)
	qdel(src)

// BLUEMOON ADD AHEAD - сверхтяжёлых персонажей нельзя помещать на обычные носилки (предотвращает абуз через толкание + повышает значимость боргов, халков и других сверхтяжёлых персонажей)
/obj/structure/bed/roller/pre_buckle_mob(mob/living/M)
	if(M.mob_weight > MOB_WEIGHT_HEAVY)
		if(!can_move_superheavy_characters)
			usr.visible_message(span_warning("[usr] tried to put [M] on [src], but it doesn't lift. Too much weight!."), span_warning("You try to put [M] on [src], but it doesn't lift. Too much weight!"))
			return FALSE
	. = ..()
// BLUEMOON ADD END

/obj/structure/bed/roller/post_buckle_mob(mob/living/M)
	density = TRUE
	up = TRUE
	M.pixel_y = initial(M.pixel_y)
	update_appearance()

/obj/structure/bed/roller/Moved()
	. = ..()
	if(has_gravity())
		playsound(src, 'sound/effects/roll.ogg', 100, 1)

/obj/structure/bed/roller/post_unbuckle_mob(mob/living/M)
	density = FALSE
	up = FALSE
	M.pixel_x = M.get_standard_pixel_x_offset(M.lying)
	M.pixel_y = M.get_standard_pixel_y_offset(M.lying)
	update_appearance()

/obj/item/roller
	name = "Roller bed"
	desc = "A collapsed roller bed that can be carried around."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "folded"
	w_class = WEIGHT_CLASS_NORMAL // No more excuses, stop getting blood everywhere
	var/rollertype = /obj/structure/bed/roller

/obj/item/roller/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/roller/robo))
		var/obj/item/roller/robo/R = I
		if(R.loaded)
			to_chat(user, "<span class='warning'>[R] already has a roller bed loaded!</span>")
			return
		user.visible_message("<span class='notice'>[user] loads [src].</span>", "<span class='notice'>You load [src] into [R].</span>")
		R.loaded = new/obj/structure/bed/roller(R)
		qdel(src) //"Load"
		return
	else
		return ..()

/obj/item/roller/attack_self(mob/user)
	deploy_roller(user, user.loc)

/obj/item/roller/afterattack(obj/target, mob/user , proximity)
	. = ..()
	if(!proximity)
		return
	if(isopenturf(target))
		deploy_roller(user, target)

/obj/item/roller/proc/deploy_roller(mob/user, atom/location)
	. = new rollertype(location)
	after_deploy_roller(user, .)

/obj/item/roller/proc/after_deploy_roller(mob/user, obj/structure/bed/roller/R)
	R.add_fingerprint(user)
	qdel(src)

/obj/item/roller/robo //ROLLER ROBO DA!
	name = "Roller bed dock"
	var/loaded = null

/obj/item/roller/robo/New()
	loaded = new /obj/structure/bed/roller(src)
	desc = "A collapsed roller bed that can be ejected for emergency use. Must be collected or replaced after use."
	..()

/obj/item/roller/robo/examine(mob/user)
	. = ..()
	. += "The dock is [loaded ? "loaded" : "empty"]."

/obj/item/roller/robo/deploy_roller(mob/user, atom/location)
	if(loaded)
		var/obj/structure/bed/roller/R = loaded
		R.forceMove(location)
		. = R
		user.visible_message("[user] deploys [loaded].", "<span class='notice'>You deploy [loaded].</span>")
		loaded = null
	else
		to_chat(user, "<span class='warning'>The dock is empty!</span>")

//Dog bed

/obj/structure/bed/dogbed
	name = "dog bed"
	icon_state = "dogbed"
	desc = "A comfy-looking dog bed. You can even strap your pet in, in case the gravity turns off."
	anchored = FALSE
	buildstacktype = /obj/item/stack/sheet/mineral/wood
	buildstackamount = 10
	var/owned = FALSE

/obj/structure/bed/dogbed/ian
	desc = "Ian's bed! Looks comfy."
	name = "Ian's bed"
	anchored = TRUE

/obj/structure/bed/dogbed/cayenne
	desc = "Seems kind of... fishy."
	name = "Cayenne's bed"
	anchored = TRUE

/obj/structure/bed/dogbed/renault
	desc = "Renault's bed! Looks comfy. A foxy person needs a foxy pet."
	name = "Renault's bed"
	anchored = TRUE

/obj/structure/bed/dogbed/runtime
	desc = "A comfy-looking cat bed. You can even strap your pet in, in case the gravity turns off."
	name = "Runtime's bed"
	anchored = TRUE

/obj/structure/bed/dogbed/proc/update_owner(mob/living/M)
	if(owned || type != /obj/structure/bed/dogbed) //Only marked beds work
		return FALSE //Failed
	owned = TRUE
	name = "[M]'s bed"
	desc = "[M]'s bed! Looks comfy."
	return TRUE //Let any callers know that this bed is ours now

/obj/structure/bed/dogbed/buckle_mob(mob/living/M, force, check_loc)
	. = ..()
	update_owner(M)

// BLUEMOON ADD AHEAD - сверхтяжёлых персонажей нельзя помещать на кроватки для питомцев (потому что эти кроватки можно таскать, прямо как носилки)
/obj/structure/bed/dogbed/pre_buckle_mob(mob/living/M)
	if(M.mob_weight > MOB_WEIGHT_HEAVY)
		usr.visible_message(span_warning("[usr] tried to put [M] on [src], but it is too small!"), span_warning("You try to put [M] on [src], but it is too small!"))
		return FALSE
	. = ..()
// BLUEMOON ADD END

/obj/structure/bed/alien
	name = "resting contraption"
	desc = "This looks similar to contraptions from Earth. Could aliens be stealing our technology?"
	icon_state = "abed"

//Double Beds, for luxurious sleeping, i.e. the captain and maybe heads- Do use this for ERP
/obj/structure/bed/double
	name = "double bed"
	desc = "A luxurious double bed, for those too important for small dreams."
	icon_state = "bed_double"
	buildstackamount = 4
	max_buckled_mobs = 2
	///The mob who buckled to this bed second, to avoid other mobs getting pixel-shifted before he unbuckles.
	var/mob/living/goldilocks

/obj/structure/bed/double/post_buckle_mob(mob/living/target)
	target.pixel_y = target.get_standard_pixel_y_offset(TRUE)
	if(buckled_mobs.len > 1 && !goldilocks) //Push the second buckled mob a bit higher from the normal lying position
		target.pixel_y = target.get_standard_pixel_y_offset(FALSE) + 6
		goldilocks = target

/obj/structure/bed/double/post_unbuckle_mob(mob/living/target)
	target.pixel_y = target.get_standard_pixel_y_offset(FALSE)
	if(target == goldilocks)
		goldilocks = null
