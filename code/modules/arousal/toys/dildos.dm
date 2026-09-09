//////////
//DILDOS//
//////////
/obj/item/dildo
	name 				= "dildo"
	desc 				= "Floppy!"
	icon 				= 'icons/obj/genitals/dildo.dmi'
	force 				= 0
	hitsound			= 'sound/weapons/tap.ogg'
	throwforce			= 0
	icon_state 			= "dildo_knotted_2"
	alpha 				= 192//transparent
	var/can_customize	= FALSE
	var/dildo_shape 	= "human"
	var/dildo_size		= 2
	var/dildo_type		= "dildo"//pretty much just used for the icon state
	var/random_color 	= TRUE
	var/random_size 	= FALSE
	var/random_shape 	= FALSE
	var/is_knotted		= FALSE
	//Lists moved to _cit_helpers.dm as globals so they're not instanced individually

/obj/item/dildo/update_appearance()
	icon_state = "[dildo_type]_[dildo_shape]_[dildo_size]"
	name = "[GLOB.dildo_size_names[dildo_size]] [dildo_shape][can_customize ? " custom" : ""] [dildo_type]"

/obj/item/dildo/AltClick(mob/living/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK, FALSE)) //BLUEMOON EDIT
		return
	customize(user)
	return TRUE

/obj/item/dildo/proc/customize(mob/living/user)
	if(!can_customize)
		return FALSE
	if(src && !user.incapacitated() && in_range(user,src))
		var/color_choice = input(user,"Choose a color for your dildo.","Dildo Color") as null|anything in GLOB.dildo_colors
		if(src && color_choice && !user.incapacitated() && in_range(user,src))
			//sanitize_inlist(color_choice, GLOB.dildo_colors, "Red") // BLUEMOON EDIT commented
			color = GLOB.dildo_colors[color_choice]
	update_appearance()
	if(src && !user.incapacitated() && in_range(user,src))
		var/shape_choice = input(user,"Choose a shape for your dildo.","Dildo Shape") as null|anything in GLOB.dildo_shapes
		if(src && shape_choice && !user.incapacitated() && in_range(user,src))
			//sanitize_inlist(shape_choice, GLOB.dildo_colors, "Knotted") // BLUEMOON EDIT commented
			dildo_shape = GLOB.dildo_shapes[shape_choice]
	update_appearance()
	if(src && !user.incapacitated() && in_range(user,src))
		var/size_choice = input(user,"Choose the size for your dildo.","Dildo Size") as null|anything in GLOB.dildo_sizes
		if(src && size_choice && !user.incapacitated() && in_range(user,src))
			//sanitize_inlist(size_choice, GLOB.dildo_colors, "Medium") // BLUEMOON EDIT commented
			dildo_size = GLOB.dildo_sizes[size_choice]
	update_appearance()
	if(src && !user.incapacitated() && in_range(user,src))
		var/transparency_choice = input(user,"Choose the transparency of your dildo. Lower is more transparent!(192-255)","Dildo Transparency") as null|num
		if(src && transparency_choice && !user.incapacitated() && in_range(user,src))
			transparency_choice = sanitize_integer(transparency_choice, 192, 255, 192) // BLUEMOON EDIT
			alpha = transparency_choice
	update_appearance()
	return TRUE

/obj/item/dildo/Initialize(mapload)
	. = ..()
	if(random_color == TRUE)
		var/randcolor = pick(GLOB.dildo_colors)
		color = GLOB.dildo_colors[randcolor]
	if(random_shape == TRUE)
		var/randshape = pick(GLOB.dildo_shapes)
		dildo_shape = GLOB.dildo_shapes[randshape]
	if(random_size == TRUE)
		var/randsize = pick(GLOB.dildo_sizes)
		dildo_size = GLOB.dildo_sizes[randsize]
	update_appearance()
	alpha		= rand(192, 255)
	pixel_y 	= rand(-7,7)
	pixel_x 	= rand(-7,7)

/obj/item/dildo/examine(mob/user)
	. = ..()
	if(can_customize)
		. += "<span class='notice'>Alt-Click \the [src.name] to customize it.</span>"

/obj/item/dildo/random//totally random
	name 				= "random dildo"//this name will show up in vendors and shit so you know what you're vending(or don't, i guess :^))
	random_color 		= TRUE
	random_shape 		= TRUE
	random_size 		= TRUE

/obj/item/dildo/knotted
	dildo_shape 		= "knotted"
	name 				= "knotted dildo"
	attack_verb 		= list("penetrated", "knotted", "slapped", "inseminated")

/obj/item/dildo/human
	dildo_shape 		= "human"
	name 				= "human dildo"
	attack_verb 		= list("penetrated", "slapped", "inseminated")

/obj/item/dildo/plain
	dildo_shape 		= "plain"
	name 				= "plain dildo"
	attack_verb 		= list("penetrated", "slapped", "inseminated")

/obj/item/dildo/flared
	dildo_shape 		= "flared"
	name 				= "flared dildo"
	attack_verb 		= list("penetrated", "slapped", "neighed", "gaped", "prolapsed", "inseminated")

/obj/item/dildo/flared/huge
	name 				= "The Penetrator"
	desc 				= "The absurdity of a sex toy with the lethality of a baseball bat."
	dildo_size 			= 4
	force				= 10
	hitsound			= 'sound/weapons/klonk.ogg'
	var/clashing

/obj/item/dildo/flared/huge/Moved()
	. = ..()
	var/obj/item/toy/plush/bm/millie/P = locate() in range(1, src)
	if(P && istype(P.loc, /turf/open) && !P.clash_target && !clashing)
		P.clash_of_the_plushies(src)

/obj/item/dildo/custom
	name 				= "customizable dildo"
	desc 				= "Thanks to significant advances in synthetic nanomaterials, this dildo is capable of taking on many different forms to fit the user's preferences! Pricy!"
	can_customize		= TRUE
	random_color 		= TRUE
	random_shape 		= TRUE
	random_size 		= TRUE

// Suicide acts, by request

/obj/item/dildo/proc/manual_suicide(mob/living/user)
	is_knotted = (src.dildo_shape == "knotted")
	if(HAS_TRAIT(user, TRAIT_NOBREATH) || HAS_TRAIT(user, TRAIT_DUMB_CUM))
		user.visible_message(span_suicide("[user] заглатывает '[src]' целиком, с выпирающим в горле бугром[is_knotted ? " и раздутыми от узла щеками" : ""]."))
		user.emote(user.gender == FEMALE ? "girlymoan" : "moan")
		return FALSE
	else
		if(is_knotted)
			user.visible_message(span_suicide("[user] не справляется с узлом на '[src]' и давится им насмерть."))
		else
			user.visible_message(span_suicide("[user], наконец, покончил[user.ru_a()] с заглотом '[src]' и своей жизнью."))
		user.adjustOxyLoss(300)
		user.death(0)
		layer = user.layer + 0.1
		return TRUE

/obj/item/dildo/suicide_act(mob/living/user)
	if(do_after(user, 25, target = src))
		user.visible_message(span_suicide("[user] давится со слезами, пытаясь пропихнуть '[src]' в свою глотку! Похоже, что [user.ru_who()] пытается покончить с собой!"))
		playsound(loc, 'sound/weapons/gagging.ogg', 50, 1, -1)
		user.Daze(30)
		user.adjustOxyLoss(30)
		user.adjust_blurriness(8)
		var/obj/item/organ/eyes/eyes = user.getorganslot(ORGAN_SLOT_EYES)
		eyes?.applyOrganDamage(10)
		if(do_after(user, 35, target = src))
			if(manual_suicide(user))
				return MANUAL_SUICIDE
			else
				user.suiciding = FALSE
				return FALSE

/obj/item/dildo/flared/huge/suicide_act(mob/living/user)
	if(do_after(user, 35, target = src))
		user.visible_message(span_suicide("[user] давится со слезами, пытаясь пропихнуть [src] в свою глотку! ПОЧЕМУ [user.ru_who()] ВООБЩЕ ПЫТАЕТСЯ? [user.ru_who()] пытается покончить с собой, не иначе!"))
		playsound(loc, 'sound/weapons/gagging.ogg', 50, 2, -1)
		user.Daze(50)
		user.adjustOxyLoss(50)
		user.adjust_blurriness(8)
		if(do_after(user, 35, target = src))
			if(manual_suicide(user))
				return MANUAL_SUICIDE
			else
				user.suiciding = FALSE
				return FALSE

