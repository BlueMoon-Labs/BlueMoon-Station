/obj/item/blackcomb
	name = "black comb"
	desc = "Обычная чёрная расчёска."
	icon = 'modular_bluemoon/krashly/icons/obj/barbershop.dmi'
	icon_state = "blackcomb"

/obj/item/blackcomb/attack(mob/living/M, mob/living/user, attackchain_flags, damage_multiplier)
	combing()

/obj/item/blackcomb/proc/combing(mob/user)
	var/mob/living/carbon/human/our_guy = loc
	if(!istype(our_guy))
		return
	if(our_guy.hair_style == "Bald")
		return
	to_chat(user, "<span class='notice'>Вы начинаете расчесывать свои волосы...</span>")
	if(do_after(user, 10 SECONDS, our_guy))
		to_chat(user, "<span class='notice'>Вы причесали себя.</span>")
		SEND_SIGNAL(our_guy, COMSIG_ADD_MOOD_EVENT, "combed", /datum/mood_event/combed)

/datum/mood_event/combed
	description = "<span class='nicegreen'>Мои волосы замечательно выглядят!</span>\n"
	mood_change = 3
	timeout = 2 MINUTES

/obj/item/razor/scissors
	name = "scissors"
	desc = "Обычные ножницы. Ими можно кого-нибудь подстричь."
	icon = 'modular_bluemoon/krashly/icons/obj/barbershop.dmi'
	icon_state = "scissors"

/obj/item/razor/scissors/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] режет свою глотку ножницами! Кажется [user.p_theyre()] пытается совершить суицид!</span>")
	shave(user, BODY_ZONE_PRECISE_MOUTH)
	shave(user, BODY_ZONE_HEAD)//doesnt need to be BODY_ZONE_HEAD specifically, but whatever
	return BRUTELOSS

/obj/item/razor/scissors/shave(mob/living/carbon/human/H, location = BODY_ZONE_PRECISE_MOUTH)
	if(location == BODY_ZONE_PRECISE_MOUTH)
		return
	if(!usr || !ishuman(usr))
		return
	open_scissors_hair_picker(usr, H, src) // BLUEMOON EDIT - hair style picker window

/obj/item/razor/straight_razor
	name = "straight razor"
	desc = "Опасная бритва. Самое то чтобы подровнять вашу бороду."
	icon = 'modular_bluemoon/krashly/icons/obj/barbershop.dmi'
	icon_state = "straight_razor"

/obj/item/razor/straight_razor/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] режет свою глотку лезвием бритвы! Кажется [user.p_theyre()] пытается совершить суицид!</span>")
	shave(user, BODY_ZONE_PRECISE_MOUTH)
	shave(user, BODY_ZONE_HEAD)//doesnt need to be BODY_ZONE_HEAD specifically, but whatever
	return BRUTELOSS

/obj/item/razor/straight_razor/shave(mob/living/carbon/human/H, location = BODY_ZONE_PRECISE_MOUTH)
	if(location != BODY_ZONE_PRECISE_MOUTH)
		return
	if(!usr || !ishuman(usr))
		return
	open_razor_hair_picker(usr, H, src) // BLUEMOON EDIT - hair style picker window

/obj/item/dyespray/hairspray
	name = "hair dye spray"
	desc = "Спрей с краской для волос в разных цветах."
	icon = 'modular_bluemoon/krashly/icons/obj/barbershop.dmi'
	icon_state = "hairspraywhite"
	can_change_color = FALSE
	dye_sound = 'modular_bluemoon/krashly/sound/sprayer.ogg'
	var/spray_color = COLOR_WHITE

/obj/item/dyespray/hairspray/get_dye_color(mob/living/carbon/human/human_target)
	return sanitize_hexcolor(spray_color, 6)

/obj/item/dyespray/hairspray/white
	icon_state = "hairspraywhite"
	spray_color = COLOR_WHITE

/obj/item/dyespray/hairspray/black
	icon_state = "hairsprayblack"
	spray_color = COLOR_BLACK

/obj/item/dyespray/hairspray/red
	icon_state = "hairsprayred"
	spray_color = COLOR_RED

/obj/item/dyespray/hairspray/green
	icon_state = "hairspraygreen"
	spray_color = COLOR_GREEN

/obj/item/dyespray/hairspray/blue
	icon_state = "hairsprayblue"
	spray_color = COLOR_BLUE

/obj/item/dyespray/hairspray/brown
	icon_state = "hairspraybrown"
	spray_color = COLOR_BROWN

/obj/item/dyespray/hairspray/blond
	icon_state = "hairsprayblond"
	spray_color = COLOR_VERY_SOFT_YELLOW
