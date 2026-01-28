/**
 * # Hyperstation 13 fleshlight
 *
 * Humbley request this doesnt get ported to other code bases, we strive to make things unique on our server and we dont have a lot of coders
 * but if you absolutely must. please give us some credit~ <3
 * made by quotefox and heavily modified by SandPoot
*/
/obj/item/fleshlight
	name 				= "Fleshlight"
	desc				= "Секс-игрушка, замаскированная под фонарик, используемая для стимуляции пениса в комплекте с меняющим цвет 'рукавом'."
	icon 				= 'modular_sand/icons/obj/fleshlight.dmi'
	icon_state 			= "fleshlight_base"
	item_state 			= "fleshlight"
	w_class				= WEIGHT_CLASS_SMALL
	var/style			= CUM_TARGET_VAGINA
	var/sleevecolor 	= "#ffcbd4" //pink
	custom_price 		= 8
	var/mutable_appearance/sleeve
	var/mutable_appearance/plushe
	var/plush_icon 		= NONE
	var/plush_iconstate = NONE
	var/inuse 			= 0

/obj/item/fleshlight/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Альт-ЛКМ [name] для изменения.</span>"

/obj/item/fleshlight/update_appearance(updates)
	. = ..()
	cut_overlay(sleeve)
	sleeve = mutable_appearance(icon, style) // Inherits icon for if an admin wants to var edit it, thank me later.
	sleeve.color = sleevecolor
	add_overlay(sleeve)

/obj/item/fleshlight/AltClick(mob/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	customize(user)
	return TRUE

/obj/item/fleshlight/proc/customize(mob/living/user)
	if(src && !user.incapacitated() && in_range(user,src))
		var/new_style = tgui_input_list(usr, "Изменить Стиль", "Изменить 'Фонарик'", list(CUM_TARGET_VAGINA, CUM_TARGET_ANUS))
		if(new_style)
			style = new_style
	update_appearance()
	if(src && !user.incapacitated() && in_range(user,src))
		var/new_color = input(user, "Изменить Цвет", "Изменить 'Фонарик'", sleevecolor) as color|null
		if(new_color)
			sleevecolor = new_color
	update_appearance()
	return TRUE

/obj/item/fleshlight/attack(mob/living/carbon/human/M, mob/living/carbon/human/user)
	var/possessive_verb = user.ru_ego()
	var/message = ""
	var/lust_amt = 0
	if(plush_icon != NONE)
		playsound(user, 'sound/items/squeaktoy.ogg', 30, 1)
	if(ishuman(M) && (M?.client?.prefs?.toggles & VERB_CONSENT))
		switch(user.zone_selected)
			if(BODY_ZONE_PRECISE_GROIN)
				if(M.has_penis() == HAS_EXPOSED_GENITAL || M.has_strapon() == HAS_EXPOSED_GENITAL)
					var/genital_name = (user == M) ? user.get_penetrating_genital_name() : M.get_penetrating_genital_name()
					message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению и трахает, натягивая [possessive_verb] прямо на свой [genital_name]" : "использует <b>'[src]'</b> по прямому назначению и трахает, натягивая прямо на свой <b>[M]</b> [genital_name]"
					lust_amt = NORMAL_LUST
	if(message)
		user.visible_message(span_lewd("<b>[user]</b> [message]."))
		M.handle_post_sex(lust_amt, null, user, ORGAN_SLOT_PENIS) //SPLURT edit
		user.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, min(lust_amt * 3, 100), PLUG13_DURATION_NORMAL)
		playlewdinteractionsound(loc, pick('modular_sand/sound/interactions/bang4.ogg',
							'modular_sand/sound/interactions/bang5.ogg',
							'modular_sand/sound/interactions/bang6.ogg'), 70, 1, -1)
		if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
			new /obj/effect/temp_visual/heart(user.loc)


	else if(user.a_intent == INTENT_HARM)
		return ..()

/obj/item/fleshlight/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/toy/plush) || istype(I, /obj/item/storage/daki))
		lefthand_file = I.lefthand_file
		righthand_file = I.righthand_file
		item_state = I.item_state
		plush_icon = I.icon
		plush_iconstate = I.icon_state
		qdel(I)
		to_chat(user, "<span class='notice'>Ты натягиваешь [I] поверх 'фонарика'.</span>")
		updateplushe()
	else
		. = ..()

/obj/item/fleshlight/proc/updateplushe()
	cut_overlay(plushe)
	plushe = mutable_appearance(plush_icon, plush_iconstate)
	plushe.pixel_y = 6
	plushe.pixel_x = -3
	plushe.layer = 33
	add_overlay(plushe)

/**
 * # Hyperstation 13 portal fleshlight
 * kinky!
*/

/obj/item/portallight
	name 				= "Портальный Фонарик"
	desc 				= "Серебряный Портальный Фонарик Love(TM), используемый для самостимуляции с технологией Блюспейс, которая позволяет любовникам заниматься сексом на расстоянии. Также работает как фаллоимитатор, если у вашего партнера есть соответствующие части тела."
	icon 				= 'modular_sand/icons/obj/fleshlight.dmi'
	icon_state 			= "unpaired"
	item_state 			= "fleshlight"
	w_class 			= WEIGHT_CLASS_SMALL
	var/partnercolor 	= "#ffcbd4"
	var/partnerbase 	= "normal"
	var/partnerorgan 	= "portal_vag"
	custom_price 		= 20
	var/mutable_appearance/sleeve
	var/mutable_appearance/organ
	var/mutable_appearance/plushe
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/portalunderwear
	var/plush_icon 		= NONE
	var/plush_iconstate = NONE
	var/targetting      = CUM_TARGET_PENIS
	var/useable 		= FALSE
	var/list/available_panties = list()

/obj/item/portallight/attack_self(mob/user)
	// BLUEMOON EDIT: Don't call parent to prevent interact() from opening UI
	switch(targetting)
		if(CUM_TARGET_PENIS)
			targetting = CUM_TARGET_VAGINA
		if(CUM_TARGET_VAGINA)
			targetting = CUM_TARGET_ANUS
		if(CUM_TARGET_ANUS)
			targetting = CUM_TARGET_URETHRA
		if(CUM_TARGET_URETHRA)
			targetting = CUM_TARGET_PENIS
	user.balloon_alert(user, "target: [targetting]")

/obj/item/portallight/examine(mob/user)
	. = ..()
	if(!portalunderwear)
		. += "<span class='notice'>Устройство не сопряжено. Для сопряжения проведите устройством по паре трусиков портала.</span>"
	else
		. += "<span class='notice'>Устройство сопряжено и ожидает использования по прямому назначению.</span>"
	if(available_panties.len)
		. += "Alt-Click для выбора трусиков."

/obj/item/portallight/update_appearance(updates)
	. = ..()
	updatesleeve()
	updateplushe()

/obj/item/portallight/attack(mob/living/carbon/human/M, mob/living/carbon/human/user)
	if(portalunderwear == null)
		return
	var/user_message = ""
	var/target_message = ""
	var/user_lust_amt = NONE
	var/target_lust_amt = NONE
	var/target
	// BLUEMOON EDIT: Also check for genital insertion
	var/mob/living/carbon/human/portal_target
	if(ishuman(portalunderwear.loc) && (portalunderwear.current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK)))
		portal_target = portalunderwear.loc
	else
		var/datum/component/genital_equipment/equipment = portalunderwear.GetComponent(/datum/component/genital_equipment)
		if(equipment?.holder_genital)
			portal_target = equipment.get_wearer()

	// Fluid tranfser inside partner. Also if it is FALSE, it nullifies "orifice" variable in handle_post_sex() to make it work properly, since "cum_inside" variable actually doesn't work correctly today.
	var/p_to_f = FALSE	//from panties to fleshlight
	var/f_to_p = FALSE	//from fleshlight to panties
	// BLUEMOON ADD START
	var/p_to_f_inside = null
	var/f_to_p_inside = null
	// BLUEMOON ADD END

	if(plush_icon != NONE)
		playsound(user, 'sound/items/squeaktoy.ogg', 30, 1)

	// BLUEMOON EDIT START
	var/genital_data = list(
		"M_has_penis" = M.has_penis(),
		"M_penis_desc" = "какой-то",
		"target_has_penis" = portal_target.has_penis(),
		"target_penis_desc" = "какой-то"
	)

	for(var/prefix in list("M", "target"))
		var/mob/living/carbon/human/person = prefix == "M" ? M : portal_target
		if(genital_data["[prefix]_has_penis"])
			var/obj/item/organ/genital/penis/person_penis = person.getorganslot(ORGAN_SLOT_PENIS)
			genital_data["[prefix]_penis_desc"] = "[round(person_penis.length * get_size(person), 0.25)]-см [lowertext(person_penis.shape)]"
		else if(person.has_strapon())
			var/obj/item/clothing/underwear/briefs/strapon/strap = person.get_strapon()
			genital_data["[prefix]_penis_desc"] = "[GLOB.dildo_size_names[strap.attached_dildo.dildo_size]] [strap.attached_dildo.dildo_shape]"

	if(ishuman(M) && (M?.client?.prefs?.toggles & VERB_CONSENT) && useable) // I promise all those checks are worth it!
		switch(user.zone_selected)
			if(BODY_ZONE_PRECISE_GROIN)
				switch(targetting)
					if(CUM_TARGET_PENIS)
						if(M.has_penis() == HAS_EXPOSED_GENITAL || M.has_strapon() == HAS_EXPOSED_GENITAL)
							switch(portalunderwear.targetting)
								if(CUM_TARGET_PENIS)
									user_message = (user == M) ? "трётся о чей-то [genital_data["target_has_penis"] ? "член" : "дилдо"], используя [name]" : "использует <b>'[src]'</b> по прямому назначению и [genital_data["target_has_penis"] ? "" : "безуспешно "]стимулирует [genital_data["target_has_penis"] ? "член" : "дилдо"] кого-то на другой стороне усилиями [genital_data["M_has_penis"] ? "члена" : "дилдо"] <b>[M]</b>, заставляя потираться о [genital_data["target_penis_desc"]] [name]"
									target_message = "трётся о твой [genital_data["target_has_penis"] ? "член" : "дилдо"]"
									target = CUM_TARGET_PENIS
									user_lust_amt = LOW_LUST
									target_lust_amt = LOW_LUST
									f_to_p = TRUE
									p_to_f = TRUE
									p_to_f_inside = FALSE
									f_to_p_inside = FALSE
								if(CUM_TARGET_VAGINA)
									user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению и трахает киску кого-то на другой стороне своим [genital_data["M_has_penis"] ? "членом" : "дилдо"]" : "использует <b>'[src]'</b> по прямому назначению и трахает <b>[M]</b> прямо в киску"
									target_message = "трахает твою киску с помощью [genital_data["M_penis_desc"]] [genital_data["M_has_penis"] ? "члена" : "дилдо"]"
									target = CUM_TARGET_PENIS
									user_lust_amt = NORMAL_LUST
									target_lust_amt = NORMAL_LUST
									f_to_p = TRUE
									p_to_f = TRUE
									p_to_f_inside = FALSE
								if(CUM_TARGET_ANUS)
									user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению и трахает анальное кольцо кого-то на другой стороне своим [genital_data["M_has_penis"] ? "членом" : "дилдо"]" : "использует <b>'[src]'</b> по прямому назначению и трахает <b>[M]</b> прямо в анал"
									target_message = "трахает твой анал с помощью [genital_data["M_penis_desc"]] [genital_data["M_has_penis"] ? "члена" : "дилдо"]"
									target = CUM_TARGET_PENIS
									user_lust_amt = NORMAL_LUST
									target_lust_amt = NORMAL_LUST
									f_to_p = TRUE
								if(CUM_TARGET_MOUTH)
									user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению и трахает ротик кого-то на другой стороне своим [genital_data["M_has_penis"] ? "членом" : "дилдо"]" : "использует <b>'[src]'</b> по прямому назначению и трахает <b>[M]</b> прямо в ротик"
									target_message = "трахает твой ротик с помощью [genital_data["M_penis_desc"]] [genital_data["M_has_penis"] ? "члена" : "дилдо"]"
									target = CUM_TARGET_PENIS
									user_lust_amt = NORMAL_LUST
									target_lust_amt = LOW_LUST
									f_to_p = TRUE
								if(CUM_TARGET_URETHRA)
									user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению и трахает уретру кого-то на другой стороне своим [genital_data["M_has_penis"] ? "членом" : "дилдо"]" : "использует <b>'[src]'</b> по прямому назначению и заставляет <b>[M]</b> войти в [genital_data["target_has_penis"] ? "уретру" : "отверстие дилдо"] на другой стороне, создавая хлюпающий звук"
									target_message = "трахает твою уретру с помощью [genital_data["M_penis_desc"]] [genital_data["M_has_penis"] ? "члена" : "дилдо"]"
									target = CUM_TARGET_PENIS
									user_lust_amt = NORMAL_LUST
									target_lust_amt = HIGH_LUST
									f_to_p = TRUE
						else
							to_chat(user, "<span class='warning'>Пенис закрыт или его нет!</span>")
					if(CUM_TARGET_VAGINA)
						if(M.has_vagina() == HAS_EXPOSED_GENITAL)
							switch(portalunderwear.targetting)
								if(CUM_TARGET_PENIS)
									user_message = (user == M) ? "использует [genital_data["target_penis_desc"]] <b>'[src]'</b> по прямому назначению, трахая свою киску" : "трахает киску <b>[M]</b> при помощи [genital_data["target_penis_desc"]] [name]"
									target_message = "трахает твой [genital_data["target_has_penis"] ? "член" : "дилдо"] с помощью своей киски"
									target = CUM_TARGET_VAGINA
									user_lust_amt = NORMAL_LUST
									target_lust_amt = NORMAL_LUST
									p_to_f = TRUE
									f_to_p = TRUE
								if(CUM_TARGET_VAGINA)
									user_message = (user == M) ? "потирает свою киску прямо о <b>'[src]'</b>, стимулирая киску на другой стороне" : "использует <b>'[src]'</b> по прямому назначению и стимулирует киску кого-то на другой стороне киской <b>[M]</b>"
									target_message = "потирает свою киску прямо о твою собственную"
									target = CUM_TARGET_VAGINA
									user_lust_amt = NORMAL_LUST
									target_lust_amt = NORMAL_LUST
									p_to_f = TRUE
									f_to_p = TRUE
									p_to_f_inside = FALSE
									f_to_p_inside = FALSE
								if(CUM_TARGET_ANUS)
									user_message = (user == M) ? "потирает свою киску прямо о <b>'[src]'</b>, стимулирая анус на другой стороне" : "использует <b>'[src]'</b> по прямому назначению и стимулирует анус кого-то на другой стороне киской <b>[M]</b>"
									target_message = "потирает свою киску прямо о твой анус"
									target = CUM_TARGET_VAGINA
									user_lust_amt = NORMAL_LUST
									target_lust_amt = LOW_LUST
									f_to_p = TRUE
									f_to_p_inside = FALSE
								if(CUM_TARGET_MOUTH)
									user_message = (user == M) ? "потирает свою киску прямо о <b>'[src]'</b>, заставляя себя вылизывать" : "использует <b>'[src]'</b> по прямому назначению и заставляет <b>[M]</b> поцеловаться своим слюнявым ротиком с киской на другой стороне, причмокивая в процессе"
									target_message = "потирает свою киску прямо о твой ротик"
									target = CUM_TARGET_VAGINA
									user_lust_amt = NORMAL_LUST
									target_lust_amt = NONE
									f_to_p = TRUE
								/* // i don't know how this would work
								if(CUM_TARGET_URETHRA)
									user_message = (user == M) ? "fucking urethra" : "force someone to fuck urethra"
									target_message = "urethra fucked by pussy"
									target = CUM_TARGET_VAGINA
									user_lust_amt = NORMAL_LUST
									target_lust_amt = LOW_LUST
								*/
						else
							to_chat(user, "<span class='warning'>Влагалище закрыто или его нет!</span>")
					if(CUM_TARGET_ANUS)
						if(M.has_anus() == HAS_EXPOSED_GENITAL)
							switch(portalunderwear.targetting)
								if(CUM_TARGET_PENIS)
									user_message = (user == M) ? "использует [genital_data["target_penis_desc"]] [name] по прямому назначению, трахая себя в анальное колечко" : "анально трахает <b>[M]</b> при помощи [genital_data["target_penis_desc"]] [name]"
									target_message = "нещадно трахает твой [genital_data["target_has_penis"] ? "член" : "дилдо"] своим анусом"
									target = CUM_TARGET_ANUS
									user_lust_amt = NORMAL_LUST
									target_lust_amt = NORMAL_LUST
									p_to_f = TRUE
								if(CUM_TARGET_VAGINA)
									user_message = (user == M) ? "потирает свой анус прямо о <b>'[src]'</b>, стимулирая киску кого-то на другой стороне" : "использует <b>'[src]'</b> по прямому назначению и стимулирует анус кого-то на другой стороне киской <b>[M]</b>"
									target_message = "потирает свой анус прямо о твою киску"
									target = CUM_TARGET_ANUS
									user_lust_amt = LOW_LUST
									target_lust_amt = NORMAL_LUST
									p_to_f = TRUE
									p_to_f_inside = FALSE
								if(CUM_TARGET_ANUS)
									user_message = (user == M) ? "потирает свой анус прямо о <b>'[src]'</b>, стимулирая анус кого-то на другой стороне" : "использует <b>'[src]'</b> по прямому назначению и стимулирует анус кого-то на другой стороне анусом <b>[M]</b>"
									target_message = "потирает свой анус прямо о твой собственный"
									target = CUM_TARGET_ANUS
									user_lust_amt = LOW_LUST
									target_lust_amt = LOW_LUST
								if(CUM_TARGET_MOUTH)
									user_message = (user == M) ? "потирает свой анус прямо о <b>'[src]'</b>, заставляя себя вылизывать" : "использует <b>'[src]'</b> по прямому назначению и заставляет <b>[M]</b> поцеловаться своим слюнявым ротиком с анусом на другой стороне, причмокивая в процессе"
									target_message = "потирает свой анус прямо о твой ротик"
									target = CUM_TARGET_ANUS
									user_lust_amt = NORMAL_LUST
									target_lust_amt = NONE
						else
							to_chat(user, "<span class='warning'>Анус закрыт или отсутствует!</span>")
					if(CUM_TARGET_URETHRA)
						if(M.has_penis() == HAS_EXPOSED_GENITAL || M.has_strapon() == HAS_EXPOSED_GENITAL)
							switch(portalunderwear.targetting)
								if(CUM_TARGET_PENIS)
									user_message = (user == M) ? "трахает [genital_data["M_has_penis"] ? "свою уретру" : "отверстие дилдо"] с помощью [genital_data["target_penis_desc"]] [name]" : "трахает уретру <b>[M]</b> своим [genital_data["target_penis_desc"]] [name]"
									target_message = "трахает свой [genital_data["target_has_penis"] ? "член" : "дилдо"] прямо в [genital_data["target_has_penis"] ? "уретру" : "отверстие"]"
									target = CUM_TARGET_URETHRA
									user_lust_amt = HIGH_LUST
									target_lust_amt = NORMAL_LUST
									p_to_f = TRUE
						else
							to_chat(user, "<span class='warning'>Уретра закрыта или отсутствует!</span>")
			if(BODY_ZONE_PRECISE_MOUTH)
				if((M.has_mouth() && (!M.is_mouth_covered() || istype(M.wear_mask, /obj/item/clothing/underwear/briefs/panties/portalpanties))))
					switch(portalunderwear.targetting)
						if(CUM_TARGET_PENIS)
							user_message = (user == M) ? "присасывается к [genital_data["target_penis_desc"]] [name]" : "использует <b>'[src]'</b> по прямому назначению и стимулирует член кого-то на другой стороне усилиями ротика <b>[M]</b>, заставляя посасывать [genital_data["target_penis_desc"]] [name]"
							target_message = "отсасывает твой [genital_data["target_has_penis"] ? "член" : "дилдо"]"
							target = CUM_TARGET_MOUTH
							user_lust_amt = LOW_LUST
							target_lust_amt = NORMAL_LUST
							p_to_f = TRUE
						if(CUM_TARGET_VAGINA)
							user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению и ублажает киску кого-то на другой стороне своим ротиком" : "использует <b>'[src]'</b> по прямому назначению и заставляет ублажать влагалище кого-то на другой стороне слюнявым ротиком <b>[M]</b>"
							target_message = "вылизывает твою киску"
							target = CUM_TARGET_MOUTH
							user_lust_amt = NONE
							target_lust_amt = NORMAL_LUST
							p_to_f = TRUE
						if(CUM_TARGET_ANUS)
							user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению и ублажает анус кого-то на другой стороне своим ротиком" : "использует <b>'[src]'</b> по прямому назначению и заставляет ублажать анус кого-то на другой стороне слюнявым ротиком <b>[M]</b>"
							target_message = "вылизывает твой анус"
							target = CUM_TARGET_MOUTH
							user_lust_amt = NONE
							target_lust_amt = NORMAL_LUST
						if(CUM_TARGET_MOUTH)
							user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению и целует кого-то на другой стороне в губы" : "использует <b>'[src]'</b> по прямому назначению и заставляет <b>[M]</b> поцеловаться с кем-то на другой стороне своим слюнявым ротиком, причмокивая в процессе"
							target_message = "целует твой ротик"
							target = CUM_TARGET_MOUTH
							user_lust_amt = (HAS_TRAIT(M, TRAIT_KISS_SLUT) ? LOW_LUST : NONE)
							target_lust_amt = (HAS_TRAIT(portal_target, TRAIT_KISS_SLUT) ? LOW_LUST : NONE)
						/* // i don't know how this would work
						if(CUM_TARGET_URETHRA)
							user_message = (user == M) ? "fucking urethra" : "force someone to fuck urethra"
							target_message = "urethra fucked by твой ротик"
							target = CUM_TARGET_MOUTH
							user_lust_amt = NORMAL_LUST
							target_lust_amt = LOW_LUST
						*/
				else
					to_chat(user, "<span class='warning'>Рот закрыт или его нет!</span>")
			if(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM)
				if(M.has_hand(REQUIRE_ANY))
					var/can_interact = FALSE
					if(user.zone_selected == BODY_ZONE_R_ARM)
						for(var/obj/item/bodypart/r_arm/R in M.bodyparts)
							can_interact = TRUE
					else
						for(var/obj/item/bodypart/l_arm/L in M.bodyparts)
							can_interact = TRUE
					if(can_interact)
						switch(portalunderwear.targetting)
							if(CUM_TARGET_PENIS)
								user_message = (user == M) ? "надрачивает [genital_data["target_penis_desc"]] [name]" : "использует <b>[M]</b> по прямому назначению и надрачивает [genital_data["target_penis_desc"]] [name]"
								target_message = "надрачивает твой пенис"
								target = CUM_TARGET_HAND
								user_lust_amt = NONE
								target_lust_amt = NORMAL_LUST
								p_to_f = TRUE
								p_to_f_inside = FALSE
							if(CUM_TARGET_VAGINA)
								user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению, играясь с киской на другой стороне своими пальчиками" : "использует <b>'[src]'</b> по прямому назначению и стимулирует влагалище кого-то на другой стороне усилиями шаловливых пальчиков <b>[M]</b>"
								target_message = "играется с твоей киской"
								target = CUM_TARGET_HAND
								user_lust_amt = NONE
								target_lust_amt = NORMAL_LUST
								p_to_f = TRUE
								p_to_f_inside = FALSE
							if(CUM_TARGET_ANUS)
								user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению, стимулируя анус на другой стороне своими пальчиками" : "использует <b>'[src]'</b> по прямому назначению и стимулирует попку кого-то на другой стороне усилиями шаловливых пальчиков <b>[M]</b>"
								target_message = "стимулирует твой анус"
								target = CUM_TARGET_HAND
								user_lust_amt = NONE
								target_lust_amt = NORMAL_LUST
							if(CUM_TARGET_MOUTH)
								user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению и стимулирует чей-то ротик на другой стороне своими пальчиками" : "использует <b>'[src]'</b> по прямому назначению и стимулирует ротик кого-то на другой стороне усилиями шаловливых пальчиков <b>[M]</b>"
								target_message = "вводит свои пальчики в твой ротик"
								target = CUM_TARGET_HAND
								user_lust_amt = NONE
								target_lust_amt = LOW_LUST
							/* // i don't know how this would work
							if(CUM_TARGET_URETHRA)
								user_message = (user == M) ? "fucking urethra" : "force someone to fuck urethra"
								target_message = "urethra fucked by hand"
								target = CUM_TARGET_HAND
								user_lust_amt = NORMAL_LUST
								target_lust_amt = LOW_LUST
							*/
					else
						to_chat(user, "<span class='warning'>Здесь нет [user.zone_selected == BODY_ZONE_R_ARM ? "правой" : "левой"] руки!</span>")
			if(BODY_ZONE_R_LEG, BODY_ZONE_L_LEG)
				if(M.has_feet(REQUIRE_ANY))
					var/can_interact = FALSE
					if(user.zone_selected == BODY_ZONE_R_LEG)
						for(var/obj/item/bodypart/r_leg/R in M.bodyparts)
							can_interact = TRUE
					else
						for(var/obj/item/bodypart/l_leg/L in M.bodyparts)
							can_interact = TRUE
					if(can_interact)
						switch(portalunderwear.targetting)
							if(CUM_TARGET_PENIS)
								user_message = (user == M) ? "потирается своим [genital_data["target_penis_desc"]] [name] прямо о свою ножку" : "потирается своим [genital_data["target_penis_desc"]] [name] прямо о <b>[M]</b> ножку"
								target_message = "потирает твой [genital_data["target_has_penis"] ? "член" : "дилдо"] с помощью своей ножки"
								target = CUM_TARGET_FEET
								user_lust_amt = NONE
								target_lust_amt = NORMAL_LUST
								p_to_f = TRUE
								p_to_f_inside = FALSE
							if(CUM_TARGET_VAGINA)
								user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению, стимулируя влагалище на другой стороне своими ножками" : "использует <b>'[src]'</b> по прямому назначению и стимулирует влагалище кого-то на другой стороне усилиями шаловливых пальцев ног <b>[M]</b>"
								target_message = "потирает твою киску с помощью своих ножек"
								target = CUM_TARGET_FEET
								user_lust_amt = NONE
								target_lust_amt = NORMAL_LUST
								p_to_f = TRUE
								p_to_f_inside = FALSE
							if(CUM_TARGET_ANUS)
								user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению, стимулируя анус на другой стороне своими ножками" : "использует <b>'[src]'</b> по прямому назначению и стимулирует анус кого-то на другой стороне усилиями шаловливых пальцев ног <b>[M]</b>"
								target_message = "потирает твой анус с помощью своих ножек"
								target = CUM_TARGET_FEET
								user_lust_amt = NONE
								target_lust_amt = NORMAL_LUST
							if(CUM_TARGET_MOUTH)
								user_message = (user == M) ? "использует <b>'[src]'</b> по прямому назначению, заставляя облизывать свои ножки кого-то на другой стороне" : "использует <b>'[src]'</b> по прямому назначению и проталкивает шаловливые пальцы ног <b>[M]</b> в ротик кого-то на другой стороне"
								target_message = "вводит пальцы своих ножек прямо в твой ротик"
								target = CUM_TARGET_FEET
								user_lust_amt = NONE
								target_lust_amt = LOW_LUST
							/* // i don't know how this would work
							if(CUM_TARGET_URETHRA)
								user_message = (user == M) ? "fucking urethra" : "force someone to fuck urethra"
								target_message = "urethra fucked by feet"
								target = CUM_TARGET_FEET
								user_lust_amt = NORMAL_LUST
								target_lust_amt = LOW_LUST
							*/
					else
						to_chat(user, "<span class='warning'>Здесь нет [user.zone_selected == BODY_ZONE_R_LEG ? "правой" : "левой"] ножки!</span>")
	if(!useable)
		to_chat(user, "<span class='notice'>Похоже, что устройство вышло из строя или на стороне партнёра что-то не так.</span>")
	if(user_message)
		if(portal_target && (portal_target?.client?.prefs.toggles & VERB_CONSENT || !portal_target.ckey))
			// if it self and have real penis, it must be main to cum
			if((M == portal_target && portalunderwear.targetting == CUM_TARGET_MOUTH && target == CUM_TARGET_VAGINA && !portal_target.is_fucking(M, CUM_TARGET_MOUTH, portal_target.getorganslot(CUM_TARGET_VAGINA), null)) || \
				(M == portal_target && !(portalunderwear.targetting == CUM_TARGET_MOUTH && target == CUM_TARGET_VAGINA) && !portal_target.is_fucking(M, target == CUM_TARGET_PENIS ? portalunderwear.targetting : target, portal_target.getorganslot(target == CUM_TARGET_PENIS ? target : portalunderwear.targetting), null)) || \
				(M != portal_target && (!portal_target.is_fucking(M, target, portal_target.getorganslot(portalunderwear.targetting), null) || !M.is_fucking(portal_target, portalunderwear.targetting, M.getorganslot(target), null))))
				portal_target.last_lewd_datum = null
				M.last_lewd_datum = null
				// if it self and have real penis, it must be main to cum
				if(portal_target == M && genital_data["target_has_penis"] && target == CUM_TARGET_PENIS)
					portal_target.set_is_fucking(M, portalunderwear.targetting, target)
				else if(portal_target == M && portalunderwear.targetting == CUM_TARGET_MOUTH && target == CUM_TARGET_VAGINA)
					portal_target.set_is_fucking(M, portalunderwear.targetting, target)
				else
					portal_target.set_is_fucking(M, target, portalunderwear.targetting)

			user.visible_message("<span class='lewd'>[user] [user_message].</span>")

			if(isnull(p_to_f_inside))
				p_to_f_inside = p_to_f
			if(isnull(f_to_p_inside))
				f_to_p_inside = f_to_p

			var/M_cum = FALSE
			var/self_get_lust = FALSE
			var/cum_inside_holes = list(CUM_TARGET_VAGINA, CUM_TARGET_ANUS, CUM_TARGET_MOUTH, CUM_TARGET_THROAT, CUM_TARGET_NIPPLE, CUM_TARGET_URETHRA, CUM_TARGET_EARS, CUM_TARGET_EYES)
			// Strapon and in hole
			if(portalunderwear.targetting == CUM_TARGET_PENIS && !(genital_data["target_has_penis"]) && (target in cum_inside_holes))
				var/obj/item/clothing/underwear/briefs/strapon/target_strapon = portal_target.get_strapon()
				if(target_strapon)
					user_lust_amt = target_strapon.attached_dildo.target_reaction(M, portal_target, (target in list(CUM_TARGET_MOUTH, CUM_TARGET_URETHRA) ? 1 : 0), target, null, FALSE, FALSE)
			// if self, use max, not both
			if(M == portalunderwear.targetting)
				user_lust_amt = max(user_lust_amt, target_lust_amt)
				target_lust_amt = max(user_lust_amt, target_lust_amt)
			if((target != CUM_TARGET_PENIS && target != CUM_TARGET_URETHRA) || genital_data["M_has_penis"])
				// if it self and have real penis, it must be main to cum
				if(M == portal_target && portalunderwear.targetting == CUM_TARGET_PENIS && genital_data["M_has_penis"])
					M_cum = M.handle_post_sex(target_lust_amt, p_to_f ? target : null, portal_target, portalunderwear.targetting, (p_to_f_inside && (target in cum_inside_holes)), TRUE)
					self_get_lust = target_lust_amt > 0
				else if(M == portal_target && portalunderwear.targetting == CUM_TARGET_VAGINA && target == CUM_TARGET_MOUTH)
					M_cum = M.handle_post_sex(target_lust_amt, p_to_f ? target : null, portal_target, portalunderwear.targetting, (p_to_f_inside && (target in cum_inside_holes)), TRUE)
					self_get_lust = target_lust_amt > 0
				else
					if(M == portal_target)
						self_get_lust = user_lust_amt > 0
					M_cum = M.handle_post_sex(user_lust_amt, f_to_p ? portalunderwear.targetting : null, portal_target, target, (f_to_p_inside && (portalunderwear.targetting in cum_inside_holes)), TRUE)

			if(M_cum)
				switch(target)
					if(CUM_TARGET_PENIS)
						switch(portalunderwear.targetting)
							if(CUM_TARGET_PENIS)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как [genital_data["M_has_penis"] ? "член" : "дилдо"] максимально сильным образом прижимается и... кончает!</span>")
							if(CUM_TARGET_VAGINA, CUM_TARGET_ANUS, CUM_TARGET_MOUTH)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как [genital_data["M_has_penis"] ? "член" : "дилдо"] углубляется прямо в [portalunderwear.targetting] и... кончает!</span>")
							if(CUM_TARGET_URETHRA)
								to_chat(portal_target, "<span class='userlove'>Чей-то [genital_data["M_has_penis"] ? "член" : "дилдо"] кончает вам прямо в уретру!</span>")
					if(CUM_TARGET_VAGINA)
						switch(portalunderwear.targetting)
							if(CUM_TARGET_PENIS)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как влагалище сквиртит прямо на твой [genital_data["target_has_penis"] ? "член" : "дилдо"]!</span>")
							if(CUM_TARGET_VAGINA, CUM_TARGET_ANUS)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как влагалище сквиртит прямо на твой [portalunderwear.targetting]!</span>")
							if(CUM_TARGET_MOUTH)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как влагалище сквиртит прямо в твой ротик!</span>")
					if(CUM_TARGET_ANUS)
						switch(portalunderwear.targetting)
							if(CUM_TARGET_PENIS)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как анус сжимается вокруг вашего [genital_data["target_has_penis"] ? "член" : "дилдо"]!</span>")
							if(CUM_TARGET_VAGINA)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как анус сжимается в оргазме, потираясь об ваш[pick("у киску","у вагину","е влагалище","е лоно")]!</span>")
							if(CUM_TARGET_ANUS)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как анус сжимается в оргазме, потираясь об ваш анус!</span>")
							if(CUM_TARGET_MOUTH)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как анус сжимается в оргазме, пока вы ублажаете его язычком!</span>")
					if(CUM_TARGET_URETHRA)
						switch(portalunderwear.targetting)
							if(CUM_TARGET_PENIS)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как из уретры вырывается семя прямо на [genital_data["target_has_penis"] ? "член" : "дилдо"]!</span>")
					if(CUM_TARGET_MOUTH)
						switch(portalunderwear.targetting)
							if(CUM_TARGET_PENIS)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как язык все более пылко ласкает твой [genital_data["target_has_penis"] ? "член" : "дилдо"], когда он внезапно напрягается и замирает, а затем, наконец, расслабляется.</span>")
							if(CUM_TARGET_VAGINA, CUM_TARGET_ANUS)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как язык все более пылко ласкает твой [portalunderwear.targetting], когда он внезапно напрягается и замирает, а затем, наконец, расслабляется.</span>")
							if(CUM_TARGET_MOUTH)
								to_chat(portal_target, "<span class='userlove'>Вы ощущаете, как пара губ еще сильнее прижимается к вашим и задрожав, расслабляется.</span>")
					// /* I don't think cumming while using these is even possible. If anyone feels otherwise, feel free to write some */
					// if(CUM_TARGET_HAND)
					// if(CUM_TARGET_FEET)
			switch(user.zone_selected)
				if(BODY_ZONE_PRECISE_GROIN)
					playlewdinteractionsound(loc, pick('modular_sand/sound/interactions/bang4.ogg',
														'modular_sand/sound/interactions/bang5.ogg',
														'modular_sand/sound/interactions/bang6.ogg'), 70, 1, -1)
				if(BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG)
					playlewdinteractionsound(loc, 'modular_sand/sound/interactions/champ_fingering.ogg', 50, 1, -1)

			to_chat(portal_target, "<span class='lewd'>Кто-то использует сопряжённый <b>'[name]'</b>, этот кто-то [target_message].</span>")

			// Strapon and in hole
			if(target == CUM_TARGET_PENIS && !(genital_data["M_has_penis"]) && (portalunderwear.targetting in cum_inside_holes))
				var/obj/item/clothing/underwear/briefs/strapon/M_strapon = M.get_strapon()
				if(M_strapon)
					target_lust_amt = M_strapon.attached_dildo.target_reaction(portal_target, M, (portalunderwear.targetting == CUM_TARGET_MOUTH ? 1 : 0), portalunderwear.targetting, null, FALSE, FALSE)
			var/target_cum = FALSE
			// if it self and have real penis, it must be main to cum
			if(portal_target == M && genital_data["target_has_penis"] && target == CUM_TARGET_PENIS)
				// already get lust
				if(!self_get_lust)
					target_cum = portal_target.handle_post_sex(user_lust_amt, f_to_p ? portalunderwear.targetting : null, M, target, (f_to_p_inside && (portalunderwear.targetting in cum_inside_holes)), TRUE)
			else
				target_cum = portal_target.handle_post_sex(target_lust_amt, p_to_f ? target : null, M, portalunderwear.targetting, (p_to_f_inside && (target in cum_inside_holes)), TRUE)
			if(target_cum)
				switch(portalunderwear.targetting)
					if(CUM_TARGET_VAGINA)
						switch(target)
							if(CUM_TARGET_PENIS)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [portalunderwear.targetting] сквиртит прямо на ваш [genital_data["M_has_penis"] ? pick("член", "пенис") : "дилдо"]!</span>")
							if(CUM_TARGET_MOUTH)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [portalunderwear.targetting] сквиртит прямо вам в ротик!</span>")
							if(CUM_TARGET_VAGINA)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [portalunderwear.targetting] сквиртит прямо на ваш[pick("у киску","у вагину","е влагалище","е лоно")]!</span>")
							if(CUM_TARGET_ANUS)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [portalunderwear.targetting] сквиртит прямо на [pick("ваш анус","твою попку")]!</span>")
							if(CUM_TARGET_HAND)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [portalunderwear.targetting] сквиртит прямо на вашу ручку!</span>")
							if(CUM_TARGET_FEET)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [portalunderwear.targetting] сквиртит прямо на вашу ножку!</span>")
					if(CUM_TARGET_ANUS)
						switch(target)
							if(CUM_TARGET_PENIS)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как анус сжимается в оргазме вокруг вашего [genital_data["M_has_penis"] ? "члена" : "дилдо"]!</span>")
							if(CUM_TARGET_VAGINA)
								to_chat(M, "<span class='userlove'>Вы ощущаете и наблюдаете, как анус сжимается в оргазме и трется об тво[pick("ю киску","ю вагину","е влагалище","е лоно")]!</span>")
							if(CUM_TARGET_ANUS)
								to_chat(M, "<span class='userlove'>Вы чувствуете, как анус в оргазме трётся о ваш собственный, сжимаясь в судорогах!</span>")
							if(CUM_TARGET_MOUTH)
								to_chat(M, "<span class='userlove'>Вы чувствуете, как анус пульсирует в оргазме, обжимая ваш язычок!</span>")
							if(CUM_TARGET_HAND)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как анус сжимается вокруг ваших пальцев!</span>")
							if(CUM_TARGET_FEET)
								to_chat(M, "<span class='userlove'>Вы чувствуете, как анус обхватывает вашу ножку, пульсируя в экстазе!</span>")
					if(CUM_TARGET_PENIS)
						switch(target)
							if(CUM_TARGET_PENIS)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [pick(list("член", "пенис"))] дергается несколько раз, прежде чем кончить прямо на твой [genital_data["M_has_penis"] ? pick("член", "пенис", "хрен") : "дилдо"]!</span>")
							if(CUM_TARGET_HAND)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [pick(list("член", "пенис"))] дергается несколько раз, прежде чем кончить прямо на твои пальцы!</span>")
							if(CUM_TARGET_VAGINA)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [pick(list("член", "пенис"))] дергается несколько раз, прежде чем кончить прямо в тво[pick("ю киску","ю вагину","е влагалище","е лоно")]!</span>")
							if(CUM_TARGET_ANUS)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [pick(list("член", "пенис"))] дергается несколько раз, прежде чем кончить прямо в тво[pick("й анус","ю попку")]!</span>")
							if(CUM_TARGET_MOUTH)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [pick(list("член", "пенис"))] дергается несколько раз, прежде чем кончить прямо в твой ротик!</span>")
							if(CUM_TARGET_FEET)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как [pick(list("член", "пенис"))] дергается несколько раз, прежде чем кончить прямо на твою ножку!</span>")
							if(CUM_TARGET_URETHRA)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как кто-то кончает в [genital_data["M_has_penis"] ? "твою уретру" : "отверстие твоего дилдо"]!</span>")
					if(CUM_TARGET_MOUTH)
						switch(target)
							if(CUM_TARGET_PENIS)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как губы дрожат, обхватывая твой [genital_data["M_has_penis"] ? pick("член", "пенис") : "дилдо"]!</span>")
							if(CUM_TARGET_VAGINA)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как язык дрожит, облизывая тво[pick("ю киску","ю вагину","е влагалище","е лоно")]!</span>")
							if(CUM_TARGET_ANUS)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как язык дрожит, облизывая тво[pick("й анус","ю попку")]!</span>")
							if(CUM_TARGET_MOUTH)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как дрожь охватывает чьи-то губы при соприкасании с твоими!</span>")
							if(CUM_TARGET_HAND)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как губы дрожат, обхватывая твои пальчики!</span>")
							if(CUM_TARGET_FEET)
								to_chat(M, "<span class='userlove'>Вы ощущаете, как губы дрожат, обхватывая твою ножку!</span>")
					if(CUM_TARGET_URETHRA)
						switch(target)
							if(CUM_TARGET_PENIS)
								to_chat(M, "<span class='userlove'>Из уретры вырывается семя прямо на ваш [genital_data["M_has_penis"] ? pick("член", "пенис") : "дилдо"]!</span>")
			if(M != portal_target && user.a_intent == INTENT_HARM && (portal_target.client?.prefs.cit_toggles & SEX_JITTER)) //By Gardelin0
			// BLUEMOON EDIT END
				portal_target.do_jitter_animation() //make your partner shake too!
			// BLUEMOON ADD: Chain interactions - notify other connected fleshlights
			if(portalunderwear?.portallight?.len > 1)
				for(var/obj/item/portallight/other_fleshlight in portalunderwear.portallight)
					if(other_fleshlight == src)
						continue  // Skip self
					var/datum/component/genital_equipment/fl_equipment = other_fleshlight.GetComponent(/datum/component/genital_equipment)
					if(fl_equipment?.holder_genital)
						var/mob/living/carbon/human/chain_target = fl_equipment.get_wearer()
						if(chain_target && chain_target != portal_target && chain_target != M)
							to_chat(chain_target, span_lewd("Вы ощущаете что-то через подключённое портальное устройство..."))
							chain_target.handle_post_sex(round(target_lust_amt / 2), null, M, null, FALSE, TRUE)
							if(user.a_intent == INTENT_HARM && (chain_target.client?.prefs.cit_toggles & SEX_JITTER))
								chain_target.do_jitter_animation()
		else
			user.visible_message("<span class='warning'><b>'[src]'</b> подает звуковой сигнал и не позволяет <b>[M]</b> войти.</span>")
	else if(user.a_intent == INTENT_HARM)
		return ..()

/obj/item/portallight/proc/updatesleeve()
	//get their looks and vagina colour!
	cut_overlays()

	var/mob/living/carbon/human/H = null
	if(portalunderwear && ishuman(portalunderwear.loc))
		H = portalunderwear.loc
	// BLUEMOON ADD: Also check for genital insertion
	else if(portalunderwear)
		var/datum/component/genital_equipment/equipment = portalunderwear.GetComponent(/datum/component/genital_equipment)
		if(equipment?.holder_genital)
			H = equipment.get_wearer()
	if(!H)
		useable = FALSE
		return
	var/obj/item/organ/genital/G

	if(portalunderwear.targetting == CUM_TARGET_VAGINA)
		G = H.getorganslot(ORGAN_SLOT_VAGINA)
		if(!G)
			useable = FALSE
			return
	else if(portalunderwear.targetting == CUM_TARGET_PENIS || portalunderwear.targetting == CUM_TARGET_URETHRA)
		G = H.getorganslot(ORGAN_SLOT_PENIS)
		if(!G)
			useable = FALSE
			return
	if(H) //if the portal panties are on someone.
		// BLUEMOON EDIT: Also check for genital insertion
		var/datum/component/genital_equipment/equipment = portalunderwear.GetComponent(/datum/component/genital_equipment)
		var/is_in_genital = equipment?.holder_genital != null
		if(!(portalunderwear.current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK)) && !is_in_genital)
			useable = FALSE
			return

		if(portalunderwear.targetting == CUM_TARGET_VAGINA || portalunderwear.targetting == CUM_TARGET_ANUS || portalunderwear.targetting == CUM_TARGET_MOUTH)
			sleeve = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_sleeve_normal")
			if(islizard(H)) // lizard nerd
				sleeve = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_sleeve_lizard")

			if(isslimeperson(H)) // slime nerd
				sleeve = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_sleeve_slime")

			if(H.dna.species.name == "Avian") // bird nerd (obviously bad hyper code)
				sleeve = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_sleeve_avian")

			sleeve.color = "#[H.dna.features["mcolor"]]"
			add_overlay(sleeve)
		else if(portalunderwear.targetting == CUM_TARGET_URETHRA)
			sleeve = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_sleeve_normal")
			sleeve.color = G.color
			add_overlay(sleeve)

		switch(portalunderwear.targetting)
			if(CUM_TARGET_VAGINA)
				organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag")
				switch(H.dna.features["vag_shape"])
					if("Human")
						organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag")
					if("Puffy")
						organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag_puffy")
					if("Gaping")
						organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag_gaping")
					if("Spade")
						organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag_spade")
					if("Feline")
						organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag_feline")
					if("Equine")
						organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag_equine")
					if("Cervine")
						organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag_cervine")
					if("Sergal")
						organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag_sergal")
					if("Cloaca")
						organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag_cloacal")
					if("Hemi")
						organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag_hemi")
				//if(GENITAL_CAN_AROUSE == TRUE)
					//add_overlay(mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_vag_drip"))
				organ.color = G.color
			if(CUM_TARGET_ANUS)
				organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_anus")
				organ.color = "#[H.dna.features["mcolor"]]"
			if(CUM_TARGET_PENIS)
				organ = mutable_appearance('modular_sand/icons/obj/dildo.dmi', "penis") // Credit goes to @Moltov#6925 (296074425562955777) from the Hyperstation 13 discord for the sprite work
				switch(H.dna.features["cock_shape"])
					if("human")
						organ = mutable_appearance('modular_sand/icons/obj/dildo.dmi', "penis")
					if("thick")
						organ = mutable_appearance('modular_sand/icons/obj/dildo.dmi', "humanthick")
					if("knotted", "barbknot")
						organ = mutable_appearance('modular_sand/icons/obj/dildo.dmi', "knotted")
					if("flared")
						organ = mutable_appearance('modular_sand/icons/obj/dildo.dmi', "flared")
					if("tapered")
						organ = mutable_appearance('modular_sand/icons/obj/dildo.dmi', "tapered")
					if("tentacle")
						organ = mutable_appearance('modular_sand/icons/obj/dildo.dmi', "tentacle")
					if("hemi", "hemiknot")
						organ = mutable_appearance('modular_sand/icons/obj/dildo.dmi', "hemi")
				organ.color = G.color
			if(CUM_TARGET_MOUTH)
				add_overlay(mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_mouth"))
				organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_mouth_lips") // TODO: find someone to replace shitty programmer art при помощи good shit
				organ.color = H.lip_style == "lipstick" ? H.lip_color : "#[H.dna.features["mcolor"]]"
			if(CUM_TARGET_URETHRA)
				organ = mutable_appearance('modular_sand/icons/obj/fleshlight.dmi', "portal_anus") // i refuse to even attempt spriting this, have a placeholder
				organ.color = G.color

		if (portalunderwear.targetting == CUM_TARGET_PENIS)
			name = replacetext(name, "Фонарик", "Дилдо")
		else
			name = replacetext(name, "Дилдо", "Фонарик")

		useable = TRUE
		add_overlay(organ)
	else
		useable = FALSE

/obj/item/portallight/attackby(obj/item/I, mob/user)  //перезарядка работает как у резака. Можно изменять, сколько требуется плазмы для полного заряда
	if(istype(I, /obj/item/toy/plush)) // Это делал Рен, но я переделал в лучшую сторону. По хорошему это всё должно лежать в модулях БМа, а не тут.
		var/obj/item/toy/plush/plush = I
		if(plush.can_you_fuck_plush)
			place_toy(I, user)

	if(istype(I, /obj/item/storage/daki))
		place_toy(I, user)

	return . = ..()

/obj/item/portallight/proc/place_toy(obj/item/I, mob/user)
	lefthand_file = I.lefthand_file
	righthand_file = I.righthand_file
	item_state = I.item_state
	plush_icon = I.icon
	plush_iconstate = I.icon_state
	qdel(I)
	to_chat(user, "<span class='notice'>Ты натягиваешь [I] поверх портального фонарика.</span>")
	updateplushe()

/obj/item/portallight/proc/updateplushe()
	cut_overlay(plushe)
	plushe = mutable_appearance(plush_icon, plush_iconstate)
	plushe.pixel_y = 6
	plushe.pixel_x = -3
	plushe.layer = 33
	add_overlay(plushe)

/obj/item/portallight/Destroy()
	if(available_panties.len)
		for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/temp in available_panties)
			temp.portallight -= src
	if(portalunderwear)
		portalunderwear.portallight -= src
		if(isliving(portalunderwear.loc))
			portalunderwear.audible_message("[icon2html(portalunderwear, hearers(portalunderwear))] *beep* *beep* *beep*")
			playsound(portalunderwear, 'sound/machines/triple_beep.ogg', ASSEMBLY_BEEP_VOLUME, TRUE)
			to_chat(portalunderwear.loc, "<span class='notice'>Трусики издают сигнал - связь с <b>'[src]'</b> потеряна.</span>")
	. = ..()

/**
 * # Hyperstation 13 portal underwear
 * Wear it, cannot be worn if not pointing to the bits you have.
*/
/obj/item/clothing/underwear/briefs/panties/portalpanties
	name = "Портальные Трусики"
	desc = "Пара портальных трусов Silver Love(TM) с технологией Блсюпейс позволяют любовникам заниматься сексом на расстоянии. Перед использованием необходимо использовать в паре с портальным фонариком. Может также использоваться как маска."
	icon = 'modular_sand/icons/obj/fleshlight.dmi'
	icon_state = "portalpanties"
	item_state = "fleshlight"
	w_class = WEIGHT_CLASS_SMALL
	var/list/portallight = list()
	var/targetting = CUM_TARGET_VAGINA
	equip_delay_self = 2 SECONDS
	equip_delay_other = 5 SECONDS

/obj/item/clothing/underwear/briefs/panties/portalpanties/attack_self(mob/user)
	// BLUEMOON EDIT: Don't call parent to prevent interact() from opening UI
	switch(targetting)
		if(CUM_TARGET_VAGINA)
			targetting = CUM_TARGET_ANUS
		if(CUM_TARGET_ANUS)
			targetting = CUM_TARGET_PENIS
		if(CUM_TARGET_PENIS)
			targetting = CUM_TARGET_URETHRA
		if(CUM_TARGET_URETHRA)
			targetting = CUM_TARGET_MOUTH
		if(CUM_TARGET_MOUTH)
			targetting = CUM_TARGET_VAGINA

	slot_flags         = targetting == CUM_TARGET_MOUTH ? ITEM_SLOT_MASK  : ITEM_SLOT_UNDERWEAR
	flags_cover        = targetting == CUM_TARGET_MOUTH ? MASKCOVERSMOUTH : NONE
	visor_flags_cover  = targetting == CUM_TARGET_MOUTH ? MASKCOVERSMOUTH : NONE

	if (targetting == CUM_TARGET_MOUTH)
		name = replacetext(name, "Трусики", "Маска")
		name = replacetext(name, "Портальные", "Портальная")
	else
		name = replacetext(name, "Маска", "Трусики")
		name = replacetext(name, "Портальная", "Портальные")

	to_chat(user, "<span class='notice'>Теперь при надевании портал будет обращен к вашему [targetting].</span>")
	update_portal()

/obj/item/clothing/underwear/briefs/panties/portalpanties/examine(mob/user)
	. = ..()
	if(!portallight.len)
		. += "<span class='notice'>Устройство не сопряжено, для сопряжения проведите фонариком по этой паре портальных трусиков (TM) или переведите устройство в <b>публичный режим</b> и ожидайте. </span>"
	else
		. += "<span class='notice'>Устройство сопряжено и ожидает использования по прямому назначению. Количество сопряженных устройств: <b>[portallight.len]</b>.</span>"
	var/mode_text = "закрыт"
	switch(portal_settings?.connection_mode)
		if(PORTAL_MODE_PUBLIC)
			mode_text = "публичный"
		if(PORTAL_MODE_PRIVATE)
			mode_text = "приватный"
		if(PORTAL_MODE_GROUP)
			mode_text = "групповой"
		if(PORTAL_MODE_DISABLED)
			mode_text = "закрыт"
	. += span_notice("Режим доступа: <b>[mode_text]</b>. (Alt+Click для настроек)")
	. += span_notice("Использование \"Latex Adjustment Override\" переключает возможность снятия предмета.")

/obj/item/clothing/underwear/briefs/panties/portalpanties/attackby(obj/item/I, mob/living/user) //pairing
	if(istype(I, /obj/item/portallight))
		var/obj/item/portallight/P = I
		if(!(P in portallight))
			portallight += P //pair the fleshlight
			P.available_panties += src
			P.portalunderwear = src
			P.icon_state = "paired"
			update_portal()
			playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
			to_chat(user, "<span class='notice'>[P] был успешно связан.</span>")
		else
			portallight -= P
			P.available_panties -= src
			if(P.portalunderwear == src || !P.available_panties.len)
				P.portalunderwear = null
				P.updatesleeve()
				P.updateplushe()
				P.icon_state = "unpaired"
			to_chat(user, "<span class='notice'>[P] был успешно отвязан.</span>")
	else
		..() //just allows people to hit it with other objects, if they so wished.

/obj/item/clothing/underwear/briefs/panties/portalpanties/mob_can_equip(M, equipper, slot, disable_warning, bypass_equip_delay_self)
	if(!..())
		return FALSE
	if(ishuman(M))
		var/mob/living/carbon/human/human = M
		switch(targetting)
			if(CUM_TARGET_VAGINA)
				if(!human.has_vagina() == HAS_EXPOSED_GENITAL)
					to_chat(human, span_warning("Влагалище закрыто или отсутствует!"))
					return FALSE
			if(CUM_TARGET_ANUS)
				if(!human.has_anus() == HAS_EXPOSED_GENITAL)
					to_chat(human, span_warning("Анус закрыт или отсутствует!"))
					return FALSE
			if(CUM_TARGET_PENIS)
				if(!human.has_penis() == HAS_EXPOSED_GENITAL && !human.has_strapon() == HAS_EXPOSED_GENITAL)
					to_chat(human, "<span class='warning'>Пенис закрыт или отсутствует!</span>")
					return FALSE
			if(CUM_TARGET_URETHRA)
				if(!human.has_penis() == HAS_EXPOSED_GENITAL && !human.has_strapon() == HAS_EXPOSED_GENITAL)
					to_chat(human, "<span class='warning'>Уретра закрыта или отсутствует!</span>")
					return FALSE
			if(CUM_TARGET_MOUTH)
				if(!human.has_mouth() || human.is_mouth_covered())
					to_chat(human, "<span class='warning'>Рот закрыт или отсутствует!</span>")
					return FALSE
	return TRUE

/obj/item/clothing/underwear/briefs/panties/portalpanties/equipped(mob/user, slot)
	. = ..()
	switch(slot)
		if(ITEM_SLOT_UNDERWEAR, ITEM_SLOT_MASK)
			RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(drop_out))
			// Portal settings setup
			if(ishuman(user))
				portal_settings?.owner = user
				START_PROCESSING(SSobj, src)
				RegisterSignal(user, COMSIG_MOVABLE_HEAR, PROC_REF(on_owner_hear))
			if(!portallight.len)
				audible_message("[icon2html(src, hearers(src))] *beep* *beep* *beep*")
				playsound(src, 'sound/machines/triple_beep.ogg', ASSEMBLY_BEEP_VOLUME, TRUE)
				to_chat(user, "<span class='notice'>Трусики не связаны с Портальным Фонариком.</span>")
			else
				update_portal()
		else
			update_portal()
			UnregisterSignal(user, COMSIG_PARENT_QDELETING)
			// Clear portal settings when not properly worn
			if(ishuman(user))
				UnregisterSignal(user, COMSIG_MOVABLE_HEAR)
				portal_settings?.owner = null
				STOP_PROCESSING(SSobj, src)

/obj/item/clothing/underwear/briefs/panties/portalpanties/dropped(mob/user)
	UnregisterSignal(user, COMSIG_PARENT_QDELETING)
	. = ..()
	update_portal()
	// Clear portal settings owner
	if(ishuman(user))
		UnregisterSignal(user, COMSIG_MOVABLE_HEAR)
		portal_settings?.owner = null
		STOP_PROCESSING(SSobj, src)

/obj/item/clothing/underwear/briefs/panties/portalpanties/Destroy()
	if(portallight.len)
		moveToNullspace() // loc cannot be human so let's destroy ourselves out of anything
		for(var/obj/item/portallight/temp in portallight)
			temp.portalunderwear = null
			temp.available_panties -= src
			temp.updatesleeve()
			temp.icon_state = "unpaired"
	. = ..()

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/drop_out()
	var/mob/living/carbon/human/deleted
	if(ishuman(loc))
		deleted = loc
	forceMove(get_turf(loc))
	dropped(deleted) // Act like we've been dropped
	plane = initial(plane)
	layer = initial(layer)
	update_portal()

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/update_portal()
	if(portallight.len)
		for(var/obj/item/portallight/P in portallight)
			if(P.portalunderwear == src)
				if(targetting == CUM_TARGET_PENIS)
					P.icon = 'modular_sand/icons/obj/dildo.dmi'
				else
					P.icon = 'modular_sand/icons/obj/fleshlight.dmi'
				P.updatesleeve()

/obj/item/storage/box/portallight
	name =  "Portal Fleshlight and Underwear"
	icon = 'modular_sand/icons/obj/fleshlight.dmi'
	desc = "Маленькая серебряная шкатулка с тиснением Silver Love Co."
	icon_state = "box"
	custom_price = 15
	illustration = null

// portal fleshlight box
/obj/item/storage/box/portallight/PopulateContents()
	new /obj/item/portallight/(src)
	new /obj/item/clothing/underwear/briefs/panties/portalpanties/(src)
	new /obj/item/paper/fluff/portallight(src)

/obj/item/paper/fluff/portallight
	name = "Инструкция по Использованию Портального Фонарика"
	default_raw_text = "Благодарим вас за покупку Портального Фонарика Silver Love Portal!<BR>\
	Для использования просто зарегистрируйте ваш новый Портальный Фонарик при помощи предоставленного нижнего белья, чтобы соединить их вместе, после чего попросите своего любовника надеть белье.<BR>\
	Повеселитесь, любовники,<BR>\
	<BR>\
	Wilhelmina Steiner."
