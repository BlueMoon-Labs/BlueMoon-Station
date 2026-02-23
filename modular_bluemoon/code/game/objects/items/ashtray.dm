/obj/item/ashtray
	name = "ashtray"
	desc = "A thing to keep your butts in."
	icon = 'modular_bluemoon/icons/obj/ashtray.dmi'
	icon_state = "ashtray"
	color = "#5c5454"
	throw_speed = 2
	throw_range = 10
	w_class = WEIGHT_CLASS_SMALL
	custom_materials = list(/datum/material/iron=1)
	var/max_butts = 10
	var/holey = FALSE

/obj/item/ashtray/Destroy()
	for(var/obj/O in contents)
		qdel(O)
	return ..()

/obj/item/ashtray/examine(mob/user)
	. = ..()
	if(contents.len >= max_butts)
		. += "It's full."
	else if(contents.len)
		. += "It has [contents.len] cig butts in it."

/obj/item/ashtray/update_icon()
	. = ..()
	cut_overlays()
	if (contents.len == max_butts)
		add_overlay(image('icons/obj/objects.dmi', "ashtray_full"))
	else if (contents.len >= max_butts/2)
		add_overlay(image('icons/obj/objects.dmi', "ashtray_half"))

/obj/item/ashtray/proc/store(obj/item/W, mob/user)
	if(!(istype(W, /obj/item/cigbutt) || istype(W, /obj/item/clothing/mask/cigarette) || istype(W, /obj/item/match)))
		return FALSE
	if(length(contents) >= max_butts)
		to_chat(user, "\The [src] is full.")
		return FALSE
	if(istype(W, /obj/item/clothing/mask/cigarette))
		var/obj/item/clothing/mask/cigarette/C = W
		if(C.lit)
			visible_message("[user] crushes [C] in [src], putting it out.")
			C.smoketime = 0
		else
			to_chat(user, "'<span class='notice'>You place [C] in [src] without even smoking it. Why would you do that?</span>")

	visible_message("[user] places [W] in [src].")
	if(iscarbon(W.loc))
		var/mob/living/carbon/M = W.loc
		M.transferItemToLoc(W, src)
	else
		W.forceMove(src)
	add_fingerprint(user)
	update_icon()

	return TRUE

/obj/item/ashtray/attackby(obj/item/W, mob/user)
	if(store(W, user))
		return
	else
		..()

/obj/item/ashtray/throw_impact(atom/hit_atom)
	if (contents.len)
		visible_message("'<span class='warning'\The [src] slams into [hit_atom], spilling its contents!</span>")
		for (var/obj/O in contents)
			O.forceMove(get_turf(loc))
	update_icon()
	return ..()

/obj/item/ashtray/verb/empty_butts()
	set name = "Empty Contents"
	set category = "Object"

	if(!ishuman(usr) || isobj(loc) || usr.stat || usr.restrained())
		return

	if(!contents.len)
		to_chat(usr, "'<span class='notice'\The [src] is empty!</span>")
		return

	visible_message("'<span class='notice'>[usr] flips \the [src], spilling its contents!</span>")
	for(var/obj/O in contents)
		O.forceMove(get_turf(loc))
	update_icon()

/obj/item/ashtray/plastic
	color = "#cccccc"
	custom_materials = list(/datum/material/plastic=1)

/obj/item/ashtray/bronze
	color = "#dd8639"
	custom_materials = list(/datum/material/bronze=1)

/obj/item/ashtray/glass
	color = "#b5edff"
	custom_materials = list(/datum/material/glass=1)
