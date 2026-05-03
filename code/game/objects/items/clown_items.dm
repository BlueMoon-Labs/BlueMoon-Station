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
/obj/item/soap/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target // BLUEMOON EDIT

		var/target_limb

		target_limb = zone2body_parts_covered_complicated(user.zone_selected)

		if(!target_limb)
			to_chat(user, span_warning("You must choose a bodypart on your doll to write on!"))
			return

		var/list/items_on_target = list()
		items_on_target = H.get_equipped_items()

		for(var/A in items_on_target)
			var/obj/item/worn_clothes = A
			if(worn_clothes.body_parts_covered & target_limb)
				to_chat(user, span_warning("The target body part is covered with their clothes."))
				return

		var/try_to_clean_genitals = FALSE
		switch(user.zone_selected)
			if(BODY_ZONE_PRECISE_MOUTH)
				H.visible_message("<span class='warning'>\the [user] begins to wash out \the [target]'s mouth with [src.name]!</span>", "<span class='danger'>[user] is starting to wash out your mouth with [src.name]! IT'S AWFUL!</span>") //washes mouth out with soap sounds better than 'the soap' here
				if(do_after(user, 4 SECONDS, target = H))
					H.visible_message("<span class='notice'>\the [user] washes \the [target]'s mouth out with [src.name]!</span>", "<span class='danger'>[user] washes out your mouth with [src.name]! IT WAS AWFUL!</span>") //washes mouth out with soap sounds better than 'the soap' here
					H.lip_style = null //removes lipstick
					H.update_body()
					return
			if(BODY_ZONE_PRECISE_EYES)
				target_limb = BODY_ZONE_HEAD
			if(BODY_ZONE_PRECISE_GROIN, BODY_ZONE_CHEST) // технически, у моба нет органа таза на момент написания
				target_limb = BODY_ZONE_CHEST
				try_to_clean_genitals = TRUE
			else
				target_limb = user.zone_selected

		var/obj/item/bodypart/affected = H.get_bodypart(target_limb)

		if(try_to_clean_genitals)
			if(user.zone_selected == BODY_ZONE_PRECISE_GROIN) // механически, моется не таз, а грудь
				H.visible_message(span_lewd("[user] begins to wash [target]'s groin with [name], as well as taking in account their genitals there."), span_lewd("[user] is starting to wash your groin with [name]... And your genitals their."))
			else
				H.visible_message(span_lewd("[user] begins to wash [target]'s [affected] with [name], as well as taking in account their private parts."), span_lewd("[user] is starting to wash your [affected] with [name]... And your private parts."))
		else
			H.visible_message(span_notice("[user] begins to wash [target]'s [affected] with [name]!"), span_notice("[user] is starting to wash your [affected] with [name]!"))

		if(do_after(user, 4 SECONDS, target = H))
			target.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
			target.clean_blood()
			SEND_SIGNAL(target, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_MEDIUM)
			target.wash_cream()
			target.wash_cum()
			if(affected)
				affected.writtentext = ""
			if(try_to_clean_genitals)
				for(var/obj/item/organ/genital/G in H.internal_organs)
					if(G.writtentext && G.is_exposed() && G.zone == user.zone_selected)
						G.writtentext = ""
				H.visible_message(span_lewd("[user] washed up [target]'s [affected]!... As well as personal belongings there."), span_lewd("[user] washed up your [affected], as well as your personal belongings there."))
			else
				H.visible_message(span_notice("[user] washed up [target]'s [affected]!"), span_notice("[user] washed up your [affected]!"))
// BLUEMOON ADD END

/obj/item/soap/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity || !check_allowed_items(target))
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
	/* BLUEMOON REMOVAL START - технически, этот кусок не работает, т.к. прок не работает на хуманов
	else if(ishuman(target) && user.zone_selected == BODY_ZONE_PRECISE_MOUTH)
		var/mob/living/carbon/human/H = user
		user.visible_message("<span class='warning'>\the [user] washes \the [target]'s mouth out with [src.name]!</span>", "<span class='notice'>You wash \the [target]'s mouth out with [src.name]!</span>") //washes mouth out with soap sounds better than 'the soap' here
		H.lip_style = null //removes lipstick
		H.update_body()
		return
	/ BLUEMOON REMOVAL END */
	else if(istype(target, /obj/structure/window))
		user.visible_message("[user] begins to clean \the [target.name] with [src]...", "<span class='notice'>You begin to clean \the [target.name] with [src]...</span>")
		if(do_after(user, src.cleanspeed, target = target))
			to_chat(user, "<span class='notice'>You clean \the [target.name].</span>")
			target.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
			target.set_opacity(initial(target.opacity))
	else
		user.visible_message("[user] begins to clean \the [target.name] with [src]...", "<span class='notice'>You begin to clean \the [target.name] with [src]...</span>")
		if(do_after(user, src.cleanspeed, target = target))
			to_chat(user, "<span class='notice'>You clean \the [target.name].</span>")
			var/obj/effect/decal/cleanable/C = locate() in target
			qdel(C)
			target.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
			target.clean_blood()
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
