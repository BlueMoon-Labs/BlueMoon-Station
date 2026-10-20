/* Clown Items
 * Contains:
 *		Soap
 *		Bike Horns
 *		Air Horns
 *		Canned Laughter
 */

/*
 * Soap
 */

/obj/item/soap
	name = "soap"
	desc = "A cheap bar of soap. Doesn't smell."
	gender = PLURAL
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "soap"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	item_flags = NOBLUDGEON
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	grind_results = list(/datum/reagent/lye = 10)
	var/cleanspeed = 50 //slower than mop
	force_string = "robust... against germs"

/obj/item/soap/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/slippery, 80)

// BLUEMOON ADD START - дополнительное описание
/obj/item/soap/examine(user, distance)
	. = ..()
	. += span_info("Мылом можно в том числе убирать надписи с частей тела, оставленные ручкой.") // рассказываем о механиках через описания
// BLUEMOON ADD END

/obj/item/soap/nanotrasen
	desc = "A Nanotrasen brand bar of soap. Smells of plasma."
	icon_state = "soapnt"

/obj/item/soap/homemade
	desc = "A homemade bar of soap. Smells of... well...."
	icon_state = "soapgibs"
	cleanspeed = 45 // a little faster to reward chemists for going to the effort

/obj/item/soap/deluxe
	desc = "A deluxe Waffle Co. brand bar of soap. Smells of high-class luxury."
	icon_state = "soapdeluxe"
	cleanspeed = 40 //same speed as mop because deluxe -- captain gets one of these

/obj/item/soap/syndie
	desc = "An untrustworthy bar of soap made of strong chemical agents that dissolve blood faster."
	icon_state = "soapsyndie"
	cleanspeed = 10 //much faster than mop so it is useful for traitors who want to clean crime scenes

/obj/item/soap/suicide_act(mob/user)
	user.say(";FFFFFFFFFFFFFFFFUUUUUUUDGE!!", forced="soap suicide")
	user.visible_message("<span class='suicide'>[user] lifts [src] to [user.ru_ego()] mouth and gnaws on it furiously, producing a thick froth! [user.ru_who(TRUE)]'ll never get that BB gun now!</span>")
	new /obj/effect/particle_effect/foam(loc)
	return (TOXLOSS)

// BLUEMOON ADD START - введено мытье отдельных частей тела, чтобы смывать с них надписи
/obj/item/soap/proc/clean_human(mob/living/carbon/human/target, mob/living/user, tongue)
	var/target_limb = zone2body_parts_covered_complicated(user.zone_selected)
	if(!target_limb)
		to_chat(user, span_warning("Вы должны выбрать часть тела чтобы её намыть!"))
		return FALSE

	var/list/items_on_target = list()
	items_on_target = target.get_equipped_items()

	for(var/A in items_on_target)
		var/obj/item/worn_clothes = A
		if(worn_clothes.body_parts_covered & target_limb)
			to_chat(user, span_warning("Часть тела, что вы пытались намылить на [target], сейчас закрыта одеждой."))
			return FALSE

	var/try_to_clean_genitals = FALSE
	switch(user.zone_selected)
		if(BODY_ZONE_PRECISE_MOUTH)
			if(!tongue)
				target.visible_message(span_warning("[user] начинает намывать рот [target] при помощи [src.name]!"), span_danger("[user] начинает намывать ваш рот при помощи [src.name]! ЭТО УЖАСНО!"))
			else
				target.visible_message(span_warning("[user] начинает вылизать губы [target]!"), span_lewd("[user] начинает вылизывать ваши губы! ЭТо... странно?"))
			if(!do_after(user, 4 SECONDS, target))
				return FALSE
			if(!tongue)
				target.visible_message(span_notice("[user] заканчивает намыливать рот [target] при помощи [src.name]!"), span_danger("[user] заканчивает намыливать ваш рот при помощи [src.name]! ЭТО УЖАСНО!"))
			else
				target.visible_message(span_notice("[user] заканчивает вылизывать губы [target]!"), span_lewd("[user] заканчивает вылизывать ваши губы!"))
			target.lip_style = null //removes lipstick
			target.update_body()
			return TRUE
		if(BODY_ZONE_PRECISE_EYES)
			target_limb = BODY_ZONE_HEAD
		if(BODY_ZONE_PRECISE_GROIN, BODY_ZONE_CHEST) // технически, у моба нет органа таза на момент написания
			target_limb = BODY_ZONE_CHEST
			try_to_clean_genitals = TRUE
		else
			target_limb = user.zone_selected

	var/obj/item/bodypart/affected = target.get_bodypart(target_limb)

	if(try_to_clean_genitals)
		if(user.zone_selected == BODY_ZONE_PRECISE_GROIN) // механически, моется не таз, а грудь
			target.visible_message(span_lewd("[user] начинает намывать пах [target] [tongue ? "своим языком" : "при помощи [name]"], беря в учёт и чужие гениталии."), span_lewd("[user] начинает намывать ваш пах при помощи [tongue ? "языка" : name]... И заодно ваши гениталии."))
		else
			target.visible_message(span_lewd("[user] начинает намывать туловище [target] [tongue ? "своим языком" : "при помощи [name]"], беря в учёт и интимные части тела."), span_lewd("[user] начинает намывать вашу грудь [tongue ? "своим языком" : "при помощи [name]"]... Как и заодно интимные части тела."))
	else
		target.visible_message(span_notice("[user] начинает намывать [affected.ru_name_y] [target] [tongue ? "своим языком" : "при помощи [name]"]!"), span_notice("[user] начинает намывать вышу [affected.ru_name_y] [tongue ? "своим языком" : "при помощи [name]"]!"))

	if(do_after(user, 4 SECONDS, target))
		target.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
		target.clean_blood()
		target.clear_fingerprints()
		SEND_SIGNAL(target, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_MEDIUM)
		target.wash_cream()
		target.wash_cum()
		if(affected)
			affected.writtentext = ""
		if(try_to_clean_genitals)
			for(var/obj/item/organ/genital/G in target.internal_organs)
				if(G.writtentext && G.is_exposed() && G.zone == user.zone_selected)
					G.writtentext = ""
			if(user.zone_selected == BODY_ZONE_PRECISE_GROIN)
				target.visible_message(span_lewd("[user] вымывает пах [target]!... беря в учёт и чужие гениталии."), span_lewd("[user] вымывает ваш пах, беря в учёт и гениталии."))
			else
				target.visible_message(span_lewd("[user] вымывает туловище [target]!... беря в учёт и интимные части тела."), span_lewd("[user] вымывает ваше туловище, беря в учёт и интимные части тела."))
		else if(user.zone_selected == BODY_ZONE_HEAD && tongue)
			user.visible_message(span_warning("[user] нежно облизывает лицо [target]!"), span_notice("Вы нежно облизываете лицо [target]!"))
		else
			target.visible_message(span_notice("[user] вымывает [affected.ru_name_y] [target]!"), span_notice("[user] вымывает вашу [affected.ru_name_y]!"))
		return TRUE
	return FALSE
// BLUEMOON ADD END

/obj/item/soap/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity || !check_allowed_items(target, target_self = TRUE))
		return
	//I couldn't feasibly  fix the overlay bugs caused by cleaning items we are wearing.
	//So this is a workaround. This also makes more sense from an IC standpoint. ~Carn
	if(user.client && ((target in user.client.screen) && !user.is_holding(target)))
		to_chat(user, "<span class='warning'>You need to take that [target.name] off before cleaning it!</span>")
	else if(istype(target, /obj/effect/decal/cleanable))
		user.visible_message("[user] begins to scrub \the [target.name] out with [src].", "<span class='warning'>You begin to scrub \the [target.name] out with [src]...</span>")
		if(do_after(user, src.cleanspeed, target = target))
			to_chat(user, "<span class='notice'>You scrub \the [target.name] out.</span>")
			qdel(target)
	else if(ishuman(target))
		clean_human(target, user)
	else if(istype(target, /obj/structure/window))
		user.visible_message("[user] begins to clean \the [target.name] with [src]...", "<span class='notice'>You begin to clean \the [target.name] with [src]...</span>")
		if(do_after(user, src.cleanspeed, target = target))
			to_chat(user, "<span class='notice'>You clean \the [target.name].</span>")
			target.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
			target.set_opacity(initial(target.opacity))
			target.clear_fingerprints()
	else
		user.visible_message("[user] begins to clean \the [target.name] with [src]...", "<span class='notice'>You begin to clean \the [target.name] with [src]...</span>")
		if(do_after(user, src.cleanspeed, target = target))
			to_chat(user, "<span class='notice'>You clean \the [target.name].</span>")
			var/obj/effect/decal/cleanable/C = locate() in target
			qdel(C)
			target.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
			target.clean_blood()
			target.clear_fingerprints()
			SEND_SIGNAL(target, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_MEDIUM)
			target.wash_cream()
			target.wash_cum() //sandstorm edit
	return


/*
 * Bike Horns
 */

/obj/item/bikehorn
	name = "bike horn"
	desc = "A horn off of a bicycle."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "bike_horn"
	item_state = "bike_horn"
	lefthand_file = 'icons/mob/inhands/equipment/horns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/horns_righthand.dmi'
	throwforce = 0
	hitsound = null //To prevent tap.ogg playing, as the item lacks of force
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	attack_verb = list("HONKED")
	var/moodlet = "honk" //used to define which kind of moodlet is added to the honked target
	var/list/honksounds = list('sound/items/bikehorn.ogg' = 1)

/obj/item/bikehorn/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/squeak, honksounds, 50)
	RegisterSignal(src, COMSIG_ITEM_ATTACK_SELF, PROC_REF(sound_false_note))

/obj/item/bikehorn/proc/sound_false_note(datum/source, mob/user)
	SIGNAL_HANDLER
	heretic_dance_false_note(get_turf(src))

/obj/item/bikehorn/attack(mob/living/carbon/M, mob/living/carbon/user)
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, moodlet, /datum/mood_event/honk)
	return ..()

/obj/item/bikehorn/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] solemnly points the horn at [user.ru_ego()] temple! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	playsound(src, pickweight(honksounds), 50, 1)
	return (BRUTELOSS)

//air horn
/obj/item/bikehorn/airhorn
	name = "air horn"
	desc = "Damn son, where'd you find this?"
	icon_state = "air_horn"
	honksounds = list('sound/items/airhorn2.ogg' = 1)

//golden bikehorn
/obj/item/bikehorn/golden
	name = "golden bike horn"
	desc = "Golden? Clearly, it's made with bananium! Honk!"
	icon_state = "gold_horn"
	item_state = "gold_horn"
	var/flip_cooldown = 0

/obj/item/bikehorn/golden/attack()
	if(flip_cooldown < world.time)
		flip_mobs()
	return ..()

/obj/item/bikehorn/golden/attack_self(mob/user)
	if(flip_cooldown < world.time)
		flip_mobs()
	..()

/obj/item/bikehorn/golden/proc/flip_mobs(mob/living/carbon/M, mob/user)
	var/turf/T = get_turf(src)
	for(M in ohearers(7, T))
		if(ishuman(M) && M.can_hear())
			var/mob/living/carbon/human/H = M
			if(istype(H.ears, /obj/item/clothing/ears/earmuffs))
				continue
		M.emote("flip")
	flip_cooldown = world.time + 7

/obj/item/bikehorn/silver
	name = "silver bike horn"
	desc = "A shiny bike horn handcrafted in the artisan workshops of Mars, with superior kevlar-reinforced rubber bulb attached to a polished plasteel reed horn."
	attack_verb = list("elegantly HONKED")
	icon_state = "silverhorn"

/obj/item/bikehorn/bluespacehonker
	name = "bluespace bike horn"
	desc = "A normal bike horn colored blue and has bluespace dust held in to reed horn allowing for silly honks through space and time, into your in childhood."
	attack_verb = list("HONKED in bluespace", "HONKED", "quantumly HONKED")
	icon_state = "bluespacehonker"
	moodlet = "bshonk"

//canned laughter
/obj/item/reagent_containers/food/drinks/soda_cans/canned_laughter
	name = "Canned Laughter"
	desc = "Just looking at this makes you want to giggle."
	icon_state = "laughter"
	list_reagents = list(/datum/reagent/consumable/laughter = 50)
