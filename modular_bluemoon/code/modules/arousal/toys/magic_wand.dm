/obj/item/magicwand
	name = "white magic wand"
	desc = "It doesn't cast spells tho."
	icon = 'modular_bluemoon/icons/obj/lewd_items/lewd_items.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_righthand.dmi'
	icon_state = "magicwand"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_UNDERWEAR
	base_icon_state = "magicwand"
	var/on = 0
	var/mode = 2
	var/intencity = 12

/obj/item/magicwand/update_icon()
	if(on)
		icon_state = "[base_icon_state]_1"
	else
		icon_state = "[base_icon_state]"
	..()

/obj/item/magicwand/attack_self(mob/user)
	on = !on
	if(on)
		to_chat(user, "[src] включен.")
	if(!on)
		to_chat(user, "[src] выключен.")
	update_icon()
	playsound(src.loc, 'modular_bluemoon/sound/items/lewd/toys/magicwand1.ogg', 25, 1)

/obj/item/magicwand/AltClick(mob/user)
	if(!istype(user))
		return
	if(isliving(user))
		playsound(user, 'sound/effects/clock_tick.ogg', 50, 1, -1)
		switch(mode)
			if(1)
				mode = 2
				update_icon()
				to_chat(user, span_notice("You twist the switch of [src], setting it to the medium setting."))
				return
			if(2)
				mode = 3
				update_icon()
				to_chat(user, span_warning("You twist the switch of [src], setting it to the high setting."))
				return
			if(3)
				mode = 1
				update_icon()
				to_chat(user, span_notice("You twist the switch of [src], setting it to the low setting."))
				return
		intencity = 6*mode

/obj/item/magicwand/attack(mob/living/carbon/human/M, mob/living/carbon/human/user)
	if(!on)
		to_chat(usr, "может стоит включить [src]?.")
		return

	user.DelayNextAction(CLICK_CD_RANGE)
	var/message = ""
	if(ishuman(M) && (M?.client?.prefs?.toggles & VERB_CONSENT))
		switch(user.zone_selected)
			if(BODY_ZONE_PRECISE_GROIN)
				if(M.has_vagina(REQUIRE_EXPOSED))
					message = (user == M) ? pick("крепко держит '\the [src]' и подставляет к своей киске.", "использует '\the [src]'для стимуляции своей киски", "постанывает и прижимается к '\the [src]' киской.") : pick("стимулирует киску <b>[M]</b> с помощью '\the [src]'", "подставляет '\the [src]' прямо к киске <b>[M]</b>.")
				if(M.has_penis(REQUIRE_EXPOSED))
					message = (user == M) ? pick("крепко держит '\the [src]' и подставляет к своему члену.","использует '\the [src]' для стимуляции своего члена.", "постанывает и прижимается к '\the [src]' членом.") : pick("стимулирует член <b>[M]</b> с помощью '\the [src]'", "подставляет '\the [src]' прямо к члену <b>[M]</b>.")
			if(BODY_ZONE_CHEST)
				if(M.has_breasts(REQUIRE_EXPOSED))
					message = (user == M) ? pick("крепко держит '\the [src]' и подставляет к своей груди.", "использует '\the [src]' для стимуляции своей груди.", "постанывает и прижимается к '\the [src]' грудью.") : pick("стимулирует грудь <b>[M]</b> с помощью '\the [src]'", "подставляет '\the [src]' прямо к груди <b>[M]</b>.")
	if(message)
		user.visible_message("<span class='lewd'><b>[user]</b> [message].</span>")
		M.handle_post_sex(intencity, null, src)

		switch (user.zone_selected)
			if (BODY_ZONE_PRECISE_GROIN)
				user.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, min(intencity * 5, 100), PLUG13_DURATION_NORMAL)
			if(BODY_ZONE_CHEST)
				user.client?.plug13.send_emote(PLUG13_EMOTE_CHEST, min(intencity * 5, 100), PLUG13_DURATION_NORMAL)

		switch(mode)
			if(1)
				playsound(loc, "modular_bluemoon/sound/items/lewd/toys/devicevibrator[rand(1,3)].ogg", 25, 1)
			if(2)
				playsound(loc, "modular_bluemoon/sound/items/lewd/toys/magicwand[rand(1, 2)].ogg", 25, 1)
			if(3)
				playsound(loc, pick('modular_bluemoon/sound/items/lewd/toys/magicwand3.ogg'), 25, 1)
				to_chat(M, span_userdanger("Вибрация слишком интенсивная!"))
				if(M.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
					M.Jitter(3)
				M.Stun(3)
				if(prob(50))
					M.emote("moan")
		if(!HAS_TRAIT(M, TRAIT_LEWD_JOB))
			new /obj/effect/temp_visual/heart(M.loc)
	else if(user.a_intent == INTENT_HARM)
		return ..()

/obj/item/magicwand/MouseDrop_T(mob/living/M, mob/living/user)
	if(!on)
		to_chat(usr, "может стоит включить [src]?.")
		return

	var/message = ""
	if(ishuman(M) && (M?.client?.prefs?.toggles & VERB_CONSENT))
		switch(user.zone_selected)
			if(BODY_ZONE_PRECISE_GROIN)
				if(M.has_vagina(REQUIRE_EXPOSED))
					message = (user == M) ? pick("распологается над '\the [src]'  и подставляет к своей киске.", "использует '\the [src]'для стимуляции своей киски", "постанывает и садится на '\the [src]' киской.") : pick("подставляет <b>[M]</b> киской к '\the [src]'!")
				if(M.has_penis(REQUIRE_EXPOSED))
					message = (user == M) ? pick("распологается над '\the [src]'  и подставляет к своему члену.", "использует '\the [src]'для стимуляции своего члена", "постанывает и садится на '\the [src]' членом.") : pick("подставляет <b>[M]</b> киской к '\the [src]'!")
			if(BODY_ZONE_CHEST)
				if(M.has_breasts(REQUIRE_EXPOSED))
					message = (user == M) ? pick("распологается над '\the [src]'  и подставляет к своей груди.", "использует '\the [src]'для стимуляции своей груди") : pick("подставляет <b>[M]</b> грудью к '\the [src]'!")
	if(message)
		user.visible_message("<span class='lewd'><b>[user]</b> [message].</span>")
		M.handle_post_sex(intencity, null, src)

		switch (user.zone_selected)
			if (BODY_ZONE_PRECISE_GROIN)
				user.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, min(intencity * 5, 100), PLUG13_DURATION_NORMAL)
			if(BODY_ZONE_CHEST)
				user.client?.plug13.send_emote(PLUG13_EMOTE_CHEST, min(intencity * 5, 100), PLUG13_DURATION_NORMAL)

		switch(mode)
			if(1)
				playsound(loc, "modular_bluemoon/sound/items/lewd/toys/devicevibrator[rand(1, 3)].ogg", 25, 1)
			if(2)
				playsound(loc, "modular_bluemoon/sound/items/lewd/toys/magicwand[rand(1, 2)].ogg", 25, 1)
			if(3)
				playsound(loc, pick('modular_bluemoon/sound/items/lewd/toys/magicwand3.ogg'), 25, 1)
				to_chat(M, span_userdanger("Вибрация слишком интенсивная!"))
				if(M.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
					M.Jitter(3)
				M.Stun(3)
				if(prob(50))
					M.emote("moan")

		if(!HAS_TRAIT(M, TRAIT_LEWD_JOB))
			new /obj/effect/temp_visual/heart(M.loc)

/obj/item/magicwand/equipped(mob/living/carbon/M)
	. = ..()
	vibrating(M)

/obj/item/magicwand/blackwand
	name = "Black magic wand"
	icon_state = "blackmwand"
	base_icon_state = "blackmwand"

/obj/item/magicwand/proc/vibrating(mob/living/carbon/human/M, slot)
	if(!istype(src, M.w_underwear))
		return
	if(!on)
		return

	while(istype(src, M.w_underwear))
		if(activate_after(src, 5))
			switch(mode)
				if(3)
					if(M.has_penis())
						to_chat(M, span_userdanger(pick("Сильная вибрация у члена сводит меня с ума!", "Вы чувствуете мучительное удовольствие от сильной стимуляции своего члена!")))
					if(M.has_vagina())
						to_chat(M, span_userdanger(pick("Сильная вибрация у киски сводит меня с ума!", "Вы чувствуете мучительное удовольствие от сильной стимуляции своей киски!")))
					if(M.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
						M.Jitter(3)
					M.emote("moan")
					M.handle_post_sex(intencity, null, src)
					M.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, intencity * 5)
					playsound(loc, 'modular_bluemoon/sound/items/lewd/toys/magicwand3.ogg', 25, 1)
					if(prob(50))
						M.Stun(5)
				if(2)
					if(M.has_penis())
						to_chat(M, span_love(pick("Я чувствую вибрацию у своего члена!", "Оно вибрирует мой член!")))
					if(M.has_vagina())
						to_chat(M, span_love(pick("Я чувствую вибрацию у своей киски!", "Оно вибрирует мою киску!")))
						M.handle_post_sex(intencity, null, src)
						M.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, intencity * 5)
						if(M.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
							M.do_jitter_animation()
						playsound(loc, "modular_bluemoon/sound/items/lewd/toys/magicwand[rand(1, 2)].ogg", 25, 1)
				if(1)
					if(M.has_penis())
						to_chat(M, span_love(pick("Я чувствую слабую вибрацию у своего члена!", "Оно слабо вибрирует мой член!")))
					if(M.has_vagina())
						to_chat(M, span_love(pick("Я чувствую слабую вибрацию у своей киски!", "Оно слабо вибрирует мою киску!")))
						M.handle_post_sex(intencity, null, src)
						M.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, intencity * 5)
						if(M.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
							M.do_jitter_animation()
						playsound(loc, "modular_bluemoon/sound/items/lewd/toys/devicevibrator[rand(1, 3)].ogg", 25, 1)
