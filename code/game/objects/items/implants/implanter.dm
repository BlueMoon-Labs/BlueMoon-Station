/obj/item/implanter
	name = "Implanter"
	desc = "Стерильный инжектор-автоимплантер."
	icon = 'icons/obj/syringe.dmi'
	icon_state = "implanter0"
	item_state = "syringe_0"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_SMALL
	custom_materials = list(/datum/material/iron=600, /datum/material/glass=200)
	var/obj/item/implant/imp = null
	var/imp_type = null

/obj/item/implanter/update_icon_state()
	if(imp)
		icon_state = "implanter1"
	else
		icon_state = "implanter0"

/obj/item/implanter/attack(mob/living/M, mob/user)
	if(!istype(M))
		return
	if(user && imp)
		if(M != user)
			M.visible_message("<span class='warning'>[user] имплантирует [M].</span>")

		var/turf/T = get_turf(M)
		if(T && (M == user || do_mob(user, M, 50)))
			if(src && imp)
				if(imp.implant(M, user))
					if (M == user)
						to_chat(user, "<span class='notice'>Вы имплантировали себя.</span>")
					else
						M.visible_message("[user] имплантирует [M].", "<span class='notice'>[user] имплантирует вас.</span>")
					imp = null
					update_icon()
				else
					to_chat(user, "<span class='warning'>Вам не удалось имплантировать [M] при помощи [src].</span>")

/obj/item/implanter/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/pen))
		if(!user.can_write(W))
			to_chat(user, "<span class='notice'>You prod at [src] with [W]!</span>")
			return
		var/t = stripped_input(user, "What would you like the label to be?", name, null)
		if(user.get_active_held_item() != W)
			return
		if(!user.canUseTopic(src, BE_CLOSE))
			return
		if(t)
			name = "Implanter ([t])"
		else
			name = "Implanter"
	else
		return ..()

/obj/item/implanter/Initialize(mapload)
	. = ..()
	if(imp_type)
		imp = new imp_type(src)
	update_icon()

/obj/item/implanter/adrenalin
	name = "Implanter (adrenalin)"
	imp_type = /obj/item/implant/adrenalin

/obj/item/implanter/emp
	name = "Implanter (EMP)"
	imp_type = /obj/item/implant/emp

/obj/item/implanter/stealth
	name = "Implanter (stealth)"
	imp_type = /obj/item/implant/stealth

/obj/item/implanter/hijack
	name = "Implanter (hijack)"
	imp_type = /obj/item/implant/hijack
