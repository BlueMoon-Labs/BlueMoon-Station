
/obj/item/bodybag
	name = "body bag"
	desc = "Сложенный мешок для хранения и транспортировки кадавров."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "bodybag_folded"
	var/unfoldedbag_path = /obj/structure/closet/body_bag
	w_class = WEIGHT_CLASS_SMALL

/obj/item/bodybag/attack_self(mob/user)
	deploy_bodybag(user, user.loc)

/obj/item/bodybag/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(proximity)
		if(isopenturf(target))
			deploy_bodybag(user, target)

/obj/item/bodybag/canReachInto(atom/user, atom/target, list/next, view_only, obj/item/tool)
	return (user in src)

/obj/item/bodybag/proc/deploy_bodybag(mob/user, atom/location)
	var/obj/structure/closet/body_bag/R = new unfoldedbag_path(location)
	R.open(user)
	R.add_fingerprint(user)
	qdel(src)

/obj/item/bodybag/suicide_act(mob/user)
	if(isopenturf(user.loc))
		user.visible_message(span_suicide("[user] залезает внутрь [src]! Похоже, что [user.ru_who()] пытается превратиться в кадавра!"))
		var/obj/structure/closet/body_bag/R = new unfoldedbag_path(user.loc)
		R.add_fingerprint(user)
		qdel(src)
		user.forceMove(R)
		playsound(src, 'sound/items/zip.ogg', 15, 1, -3)
		return (OXYLOSS)
	..()

// Bluespace bodybag

/obj/item/bodybag/bluespace
	name = "bluespace body bag"
	desc = "Сложенный блюспейс-мешок для хранения и транспортировки кадавров."
	icon_state = "bluebodybag_folded"
	unfoldedbag_path = /obj/structure/closet/body_bag/bluespace
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NO_MAT_REDEMPTION


/obj/item/bodybag/bluespace/examine(mob/user)
	. = ..()
	if(contents.len)
		var/x = contents.len == 1 ? "у" : "ы"
		. += span_notice("Вы можете разглядеть форм[x] [contents.len] шт. предметов в покрое [src].")

/obj/item/bodybag/bluespace/Destroy()
	for(var/atom/movable/A in contents)
		A.forceMove(get_turf(src))
		if(isliving(A))
			to_chat(A, span_notice("Внезапно вы ощущаете, как пространство вокруг вас рвётся! Вы свободны!"))
	return ..()

/obj/item/bodybag/bluespace/deploy_bodybag(mob/user, atom/location)
	var/obj/structure/closet/body_bag/R = new unfoldedbag_path(location)
	for(var/atom/movable/A in contents)
		A.forceMove(R)
		if(isliving(A))
			to_chat(A, span_notice("Внезапно вы ощущаете, как пространство вокруг вас рвётся! Вы свободны!"))
	R.open(user)
	R.add_fingerprint(user)
	qdel(src)

/obj/item/bodybag/bluespace/container_resist(mob/living/user)
	if(user.incapacitated())
		to_chat(user, span_warning("Вы не выберетесь, пока обездвижены подобным образом!"))
		return
	to_chat(user, span_notice("Вы продираетесь сквозь покрой [src], пытаясь разорвать его..."))
	to_chat(loc, span_warning("Кто-то пытается выбраться из [src]!"))
	if(!do_after(user, 200, target = src))
		to_chat(loc, span_warning("Напор спадает. Похоже, сопротивление от кого бы то ни было прекратилось..."))
		return
	loc.visible_message(span_warning("[user] внезапно появляется посреди <b>[loc]</b>!"), span_userdanger("[user] вырывается из [src]!"))
	qdel(src)

// Containment bodybag

/obj/item/bodybag/containment
	name = "radiation containment body bag"
	desc = "Сложенный тяжёлый мешок для хранения и транспортировки кадавров с высоким облучением."
	icon_state = "radbodybag_folded"
	unfoldedbag_path = /obj/structure/closet/body_bag/containment
	w_class = WEIGHT_CLASS_NORMAL
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE

/obj/item/bodybag/containment/nanotrasen
	name = "elite containment protection bag"
	desc = "Сложенный тяжёлый, укреплённый и изолированный мешок, способный полностью оградить содержимое от внешних факторов."
	icon_state = "ntenvirobag_folded"
	unfoldedbag_path = /obj/structure/closet/body_bag/containment/nanotrasen

/obj/item/bodybag/containment/prisoner
	name = "prisoner transport bag"
	desc = "Intended for transport of prisoners through hazardous environments, this folded containment protection bag comes with straps to keep an occupant secure."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "prisonerenvirobag_folded"
	unfoldedbag_path = /obj/structure/closet/body_bag/containment/prisoner

/obj/item/bodybag/containment/prisoner/syndicate
	name = "syndicate prisoner transport bag"
	desc = "An alteration of Nanotrasen's containment protection bag which has been used in several high-profile kidnappings. Designed to keep a victim unconscious, alive, and secured until they are transported to a required location."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "syndieenvirobag_folded"
	unfoldedbag_path = /obj/structure/closet/body_bag/containment/prisoner/syndicate

