/obj/item/qareen_chalk
	name = "qareen enchanted chalk"
	desc = "A weird chalk covered in ectoplasm."
	icon = 'modular_bluemoon/icons/obj/lewd_items/qareen_chalk.dmi'
	icon_state = "chalk"
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_TINY

/obj/item/qareen_chalk/afterattack(atom/target, mob/user as mob, proximity)
	if(!proximity)
		return
	if(istype(target, /turf/open/floor))
		if(do_after(user, 5))
			to_chat(user, span_userdanger("[src] crumbles in your hands after being used!"))
			playsound(loc, 'sound/items/gavel.ogg', 50, 1)
			new /obj/effect/qareen_rune(target)
			qdel(src)

/obj/effect/qareen_rune
	name = "Qareen rune"
	desc = "It is believed this rune is capable of summoning horny ghosts!"
	icon = 'modular_bluemoon/icons/obj/lewd_items/qareen_chalk.dmi'
	icon_state = "rune"

/obj/effect/qareen_rune/attack_hand(mob/living/carbon/M)
	if(!isliving(M))
		return
	var/list/creatures = list()
	for(var/mob/living/simple_animal/qareen/Q in world)
		creatures += Q
	var/choice = tgui_alert(usr, "Do you want to attempt to summon Qareen?", "Attempt to summon Qareen?", list("Yes", "No"))
	switch(choice)
		if("No")
			return
		if("Yes")
			var/mob/living/simple_animal/qareen/target = input("Please, select a qareen!", "Select", null, null) as null|anything in creatures
			if(isnull(target))
				return
			else
				var/qareen_choice = tgui_alert(target, "You have been summoned! Do you want to answer?", "Do you want to answer?", list("Yes", "No"))
				switch(qareen_choice)
					if("No")
						to_chat(M, span_userdanger("It refuses to answer!"))
					if("Yes")
						new /obj/item/ectoplasm/qareen(src.loc)
						to_chat(M, span_userdanger("Something is happening!"))
						target.forceMove(src.loc)
						playsound(loc, 'modular_bluemoon/sound/effects/spook.ogg', 50, 1)
						for(var/obj/machinery/light/L in loc)
							L.flicker(20)
						qdel(src)
