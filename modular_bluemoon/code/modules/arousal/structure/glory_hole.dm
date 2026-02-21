/obj/structure/chair/gloryhole
	name = "glory hole"
	desc = "A restraining device in the wall box. It provides easier access to the victim's genitalia and other holes."
	icon = 'modular_bluemoon/icons/obj/structures/lewd_devices.dmi'
	icon_state = "gloryhole"
	var/over_state = "nothing"
	var/restrains = 0
	var/self_unbuckle_time = 2 MINUTES
	var/aphrodisiac
	var/obj/item/letter //Any papers pinned to the gloryhole
	var/obj/item/picture //Any photos pinned to the gloryhole
	var/overlays_file = 'modular_bluemoon/icons/obj/structures/lewd_devices.dmi'
	var/static/list/gloryhole_overlays = list()
	anchored = 1
	dir = 2
	item_chair = null // нельзя брать в руки
	flags_1 = NODECONSTRUCT_1

/obj/structure/chair/gloryhole/Destroy()
	..()
	QDEL_NULL(letter)
	QDEL_NULL(picture)

/obj/structure/chair/gloryhole/handle_atom_del(atom/A)
	..()
	if(A == letter)
		letter = null
		update_icon()
	if(A == picture)
		picture = null
		update_icon()

/obj/structure/chair/gloryhole/update_icon()
	. = ..()
	set_gloryhole_overlays()

/obj/structure/chair/gloryhole/proc/set_gloryhole_overlays()
	var/mutable_appearance/state_overlay
	var/mutable_appearance/letter_overlay
	var/mutable_appearance/picture_overlay
	var/letter_type = letter_type()
	var/picture_type = picture_type()

	if(has_buckled_mobs())
		state_overlay = get_gloryhole_overlay("[icon_state]_[over_state]", overlays_file)

	if(letter)
		letter_overlay = get_gloryhole_overlay(letter_type, overlays_file)
	if(picture)
		picture_overlay = get_gloryhole_overlay(picture_type, overlays_file)

	cut_overlays()
	add_overlay(state_overlay)
	add_overlay(letter_overlay)
	add_overlay(picture_overlay)

/proc/get_gloryhole_overlay(icon_state, icon_file, targetlayer = MOB_LAYER + 1)
	var/obj/structure/chair/gloryhole/A
	pass(A)	//suppress unused warning
	var/list/gloryhole_overlays = A.gloryhole_overlays
	var/iconkey = "[icon_state][icon_file]"
	if((!(. = gloryhole_overlays[iconkey])))
		. = gloryhole_overlays[iconkey] = mutable_appearance(icon_file, icon_state, targetlayer)

/obj/structure/chair/gloryhole/proc/letter_type()
	if(!letter)
		return
	else if(istype(letter, /obj/item/paper))
		return "paper"

/obj/structure/chair/gloryhole/proc/picture_type()
	if(!picture)
		return
	else if(istype(picture, /obj/item/photo))
		return "photo"

/obj/structure/chair/gloryhole/examine(mob/user)
	. = ..()

	if(letter)
		if(!in_range(user, src))
			. += "There's a [letter.name] pinned to the front. You can't read it from here."
		else
			. += "There's a [letter.name] pinned to the front..."
			. += letter.examine(user)
	if(picture)
		if(!in_range(user, src))
			. += "There's a [picture.name] pinned to the front. You can't read it from here."
		else
			. += "There's a [picture.name] pinned to the front..."
			. += picture.examine(user)

	if(restrains)
		. += "<span class='notice'>Система замков включена.</span>"
	if(!restrains)
		. += "<span class='notice'>Система замков выключена.</span>"

	if(has_buckled_mobs())
		switch(over_state)
			if("over")
				. += "<span class='notice'>Имеется доступ к дырочкам спереди.</span>"
			if("b_over")
				. += "<span class='notice'>Имеется доступ к дырочкам спереди и груди.</span>"
			if("bo_over")
				. += "<span class='notice'>Имеется доступ к груди.</span>"
			if("o_over")
				. += "<span class='notice'>Имеется доступ ко рту.</span>"
			if("ob_over")
				. += "<span class='notice'>Имеется доступ ко рту и груди.</span>"
			if("all_over")
				. += "<span class='notice'>Имеется доступ к дырочкам спереди, рту и груди.</span>"
			if("bb_over")
				. += "<span class='notice'>Имеется доступ к дырочкам сзади.</span>"

	. += "<span class='notice'>Alt+Click чтобы изменить доступ дырочек.</span>"

/obj/structure/chair/gloryhole/AltClick(mob/living/user)
	if(has_buckled_mobs())
		for(var/m in buckled_mobs)
			var/mob/living/carbon/human/M = m
			switch(over_state)
				if("nothing")
					over_state = "over"
					M.dir = 2
				if("over")
					over_state = "b_over"
					M.dir = 2
				if("b_over")
					over_state = "bo_over"
					M.dir = 2
				if("bo_over")
					over_state = "o_over"
					M.dir = 2
				if("o_over")
					over_state = "ob_over"
					M.dir = 2
				if("ob_over")
					over_state = "all_over"
					M.dir = 2
				if("all_over")
					over_state = "bb_over"
					M.dir = 1
				if("bb_over")
					over_state = "over"
					M.dir = 2

		to_chat(usr, "Доступные дырочки изменены.")
		update_icon()
		update_overlays()

	else
		to_chat(usr, "Никого внутри.")
		return

/obj/structure/chair/gloryhole/verb/restrain()
	set name = "Активация замков"
	set category = "Object"
	set src in oview(1)

	if(!has_buckled_mobs())
		to_chat(usr, "Никого внутри.")
		return
	for(var/m in buckled_mobs)
		var/mob/living/carbon/human/M = m
		if(M == usr)
			to_chat(usr, "Не дотянуться до кнопки!")
			return
		else
			restrains = !restrains
			if(restrains)
				to_chat(usr, "[src] замки активированы.")
				playsound(loc, "sound/weapons/handcuffs.ogg", 30, 1)
			else
				to_chat(usr, "[src] замки деактивированы.")

/obj/structure/chair/gloryhole/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	if(QDELETED(buckled_mob) || QDELETED(user)) //SPLURT edit
		return
	if(INTERACTING_WITH(buckled_mob, src))
		to_chat(user, "<span class='notice'>You're already trying to unbuckle [buckled_mob == user ? "yourself" : buckled_mob]!")
		return
	if(!handle_unbuckling(buckled_mob, user))
		if(buckled_mob == user)
			to_chat(user, "<span class='warning'>You fail to unbuckle yourself.</span>")
		else
			to_chat(user, "<span class='warning'>You fail to unbuckle [buckled_mob].</span>")
		return

	over_state = "nothing"
	update_icon()
	update_overlays()
	return ..()

/obj/structure/chair/gloryhole/proc/handle_unbuckling(mob/living/buckled_mob, user)
	if(buckled_mob == user)
		if(restrains)
			var/input = tgui_alert(usr, "Вы уверены что хотите попытаться слезть сами? Это займёт более 2 минут и имеет шанс неудачи!", "Уверены?", list("Да", "Нет"))
			if(input == "Да")
				if(do_after(user, self_unbuckle_time, src))
					if(prob(30))
						to_chat(usr, "Не получилось!")
						return FALSE
					else
						return TRUE
				else
					return FALSE
			else
				return FALSE
		else
			return TRUE
	return TRUE

/obj/structure/chair/gloryhole/MouseDrop_T(mob/living/M, mob/living/user)
	if(istype(M))
		if(!iscarbon(M)) //No cleanbot fucking - no fun allowed!
			to_chat(usr, "Не помещается!")
			return
		if(get_turf(M) != get_turf(src) && user.stat == CONSCIOUS)
			var/message = M == user ? "[M] climbs in the [src]." : "[user] puts [M] in the [src]."
			var/self_message = M == user ? "You climb in the [src]." : "You put [M] in the [src]."
			visible_message(message, self_message)
			M.forceMove(get_turf(src))
			over_state = "over"
			update_icon()
			update_overlays()
		. = ..()
	return

/obj/structure/chair/gloryhole/verb/aphrodisiac()
	set name = "Ввести афродизиак"
	set category = "Object"
	set src in oview(1)
	if(has_buckled_mobs())
		if(!isliving(usr)) //no ghosts allowed
			return
		for(var/m in buckled_mobs)
			var/mob/living/carbon/human/M = m
			var/input = tgui_alert(usr, "Какой афродизиак ввести?", "Афродизиак", list("crocin", "hexacrocin"))
			if(M == usr)
				to_chat(usr, "Не дотянуться до кнопки!")
				return
			switch(input)
				if("crocin")
					M.reagents.add_reagent(/datum/reagent/drug/aphrodisiac, 15)
					to_chat(usr, "[input] введён.")
					playsound(loc, 'modular_bluemoon/sound/items/lewd/injection.ogg', 30, 1)
				if("hexacrocin")
					M.reagents.add_reagent(/datum/reagent/drug/aphrodisiacplus, 15)
					to_chat(usr, "[input] введён.")
					playsound(loc, 'modular_bluemoon/sound/items/lewd/injection.ogg', 30, 1)
	else
		to_chat(usr, "Никого внутри.")
		return

/obj/structure/chair/gloryhole/attackby(obj/item/used_item, mob/user, params)
	if(used_item.tool_behaviour == TOOL_WRENCH)
		to_chat(user, "<span class='notice'>You begin to [anchored ? "unwrench" : "wrench"] [src].</span>")
		if(used_item.use_tool(src, user, 20, volume=30))
			to_chat(user, "<span class='notice'>You successfully [anchored ? "unwrench" : "wrench"] [src].</span>")
			setAnchored(!anchored)
	else if(istype(used_item, /obj/item/screwdriver))
		to_chat(user, span_notice("You unscrew the frame and begin to deconstruct it..."))
		playsound(loc, "'sound/items/screwdriver.ogg'", 30, 1)
		if(used_item.use_tool(src, user, 8 SECONDS, volume = 50))
			to_chat(user, span_notice("You disassemble it."))
			new /obj/item/gloryhole_kit (src.loc)
			qdel(src)
	else if(istype(used_item, /obj/item/wirecutters))
		if(letter)
			user.visible_message("<span class='notice'>[user] cuts down [letter] from [src].</span>", "<span class='notice'>You remove [letter] from [src].</span>")
			letter.forceMove(get_turf(user))
			letter = null
			update_icon()
			playsound(loc, "sound/items/wirecutter.ogg", 30, 1)
		if(picture)
			user.visible_message("<span class='notice'>[user] cuts down [picture] from [src].</span>", "<span class='notice'>You remove [picture] from [src].</span>")
			picture.forceMove(get_turf(user))
			picture = null
			update_icon()
			playsound(loc, "sound/items/wirecutter.ogg", 30, 1)
	else if(istype(used_item, /obj/item/paper))
		if(letter)
			to_chat(user, "<span class='warning'>There's already something pinned to this gloryhole! Use wirecutters to remove it.</span>")
			return
		if(!user.transferItemToLoc(used_item, src))
			to_chat(user, "<span class='warning'>For some reason, you can't attach [used_item]!</span>")
			return
		user.visible_message("<span class='notice'>[user] pins [used_item] to [src].</span>", "<span class='notice'>You pin [used_item] to [src].</span>")
		letter = used_item
		update_icon()
	else if(istype(used_item, /obj/item/photo))
		if(picture)
			to_chat(user, "<span class='warning'>There's already something pinned to this gloryhole! Use wirecutters to remove it.</span>")
			return
		if(!user.transferItemToLoc(used_item, src))
			to_chat(user, "<span class='warning'>For some reason, you can't attach [used_item]!</span>")
			return
		user.visible_message("<span class='notice'>[user] pins [used_item] to [src].</span>", "<span class='notice'>You pin [used_item] to [src].</span>")
		picture = used_item
		update_icon()
	else
		return ..()

/obj/item/gloryhole_kit
	name = "gloryhole construction kit"
	desc = "Construction requires a screwdriver. Put it on the ground first!"
	icon = 'modular_bluemoon/icons/obj/structures/lewd_devices.dmi'
	icon_state = "kit"
	throwforce = 0
	var/unwrapped = 0
	w_class = WEIGHT_CLASS_HUGE

/obj/item/gloryhole_kit/attackby(obj/item/used_item, mob/user, params) //constructing a bed here.
	add_fingerprint(user)
	if(istype(used_item, /obj/item/screwdriver))
		if (!(item_flags & IN_INVENTORY) && !(item_flags & IN_STORAGE))
			to_chat(user, span_notice("You screw the frame to the floor and begin to construct it..."))
			playsound(loc, "'sound/items/screwdriver.ogg'", 30, 1)
			if(used_item.use_tool(src, user, 8 SECONDS, volume = 50))
				to_chat(user, span_notice("You assemble it."))
				new /obj/structure/chair/gloryhole (src.loc)
				qdel(src)
	else
		return ..()
