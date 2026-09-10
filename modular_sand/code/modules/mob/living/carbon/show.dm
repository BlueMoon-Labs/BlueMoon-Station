/obj/item/proc/showoff(mob/user)
	for(var/mob/M in view(user))
		M.show_message("[user] holds up [src]. <a HREF=?src=\ref[M];lookitem=\ref[src]>Take a closer look.</a>", 1)

/mob/living/carbon/verb/show_item()
	set name = "Show Held Item"
	set category = "Object"
	set desc = "Show the thing you're holding."

	showoff(usr)

/mob/living/carbon/proc/showoff()
	var/obj/item/I = get_active_held_item()
	var/obj/item/arm = get_active_hand()
	if(!I && arm)
		usr.show_message("[usr] holds up [arm].", 1)
	else if(!arm && !I)
		to_chat(usr, "<span class='notice'>You frown because now there's nothing you can show.</span>")
	else if(!HAS_TRAIT(I, ABSTRACT_ITEM_TRAIT))
		I.showoff(src)
		point_bubble(I)

/atom/movable/proc/point_bubble(atom/pointed_atom)
	var/mutable_appearance/thought_bubble = mutable_appearance(
		'modular_bluemoon/icons/effects/effects.dmi',
		"thought_bubble",
		//offset_spokesman = src,	//here MAY be some problems on multi-z maps
		plane = POINT_PLANE,
		appearance_flags = KEEP_APART,
	)

	var/mutable_appearance/pointed_atom_appearance = new(pointed_atom.appearance)
	pointed_atom_appearance.blend_mode = BLEND_INSET_OVERLAY
	pointed_atom_appearance.plane = FLOAT_PLANE
	pointed_atom_appearance.layer = FLOAT_LAYER
	pointed_atom_appearance.pixel_x = 0
	pointed_atom_appearance.pixel_y = 0
	thought_bubble.overlays += pointed_atom_appearance

	thought_bubble.pixel_x = 16
	thought_bubble.pixel_y = 32
	thought_bubble.alpha = 200

	add_overlay(thought_bubble)
	LAZYADD(update_overlays_on_z, thought_bubble)
	addtimer(CALLBACK(src, PROC_REF(clear_point_bubble), thought_bubble), 5 SECONDS)

/atom/movable/proc/clear_point_bubble(mutable_appearance/thought_bubble)
	LAZYREMOVE(update_overlays_on_z, thought_bubble)
	cut_overlay(thought_bubble)
