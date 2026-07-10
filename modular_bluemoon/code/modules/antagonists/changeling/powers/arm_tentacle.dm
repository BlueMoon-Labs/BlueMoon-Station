/datum/action/changeling/weapon/arm_tentacle
	name = "Arm Tentacle"
	desc = "We reform one of our arms into a pleasing tentacle. Costs no chemicals."
	helptext = "We may retract our arm tentacle in the same manner as we form it. Cannot be used while in lesser form."
	button_icon_state = "arm_tentacle"
	chemical_cost = 0
	dna_cost = 2
	loudness = 0
	req_human = TRUE
	recharge_slowdown = 0.1
	weapon_type = /obj/item/arm_tentacle
	weapon_name_simple = "tentacle arm"
	gamemode_restriction_type = ANTAG_EXTENDED

//ARM ITSELF//

/obj/item/arm_tentacle
	name = "tentacle arm"
	desc = "It wiggles and pulses!"
	icon = 'modular_bluemoon/icons/obj/items_and_weapons.dmi'
	icon_state = "arm_tentacle"
	item_state = "arm_tentacle"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/arm_tentacle_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/arm_tentacle_righthand.dmi'
	attack_verb = list("pricked", "tentacled")
	item_flags = NEEDS_PERMIT | ABSTRACT | DROPDEL
	w_class = WEIGHT_CLASS_HUGE
	force = 0
	throwforce = 0 //Just to be on the safe side
	throw_range = 0
	throw_speed = 0
	total_mass = TOTAL_MASS_HAND_REPLACEMENT
	var/hole = "Vagina"

/obj/item/arm_tentacle/attack_self(mob/living/carbon/human/user as mob)
	switch(hole)
		if("Vagina")
			hole = "Anus"
		if("Anus")
			hole = "Penis"
		if("Penis")
			hole = "Vagina"
	to_chat(user, "<span class='notice'>Я целюсь в... [hole].</span>")

/obj/item/arm_tentacle/attack(mob/living/carbon/human/M, mob/living/carbon/human/user)
	user.DelayNextAction(CLICK_CD_RANGE)
	var/message = ""
	if(ishuman(M) && (M?.client?.prefs?.toggles & VERB_CONSENT))
		switch(user.zone_selected)
			if(BODY_ZONE_PRECISE_GROIN)
				if(M.has_vagina() == HAS_EXPOSED_GENITAL && hole == "Vagina")
					message = (user == M) ? pick("играет со своей киской при помощи [src].", "использует [src] для стимуляции своей киски", "постанывает и запускает [src] глубже в свою промежность.") : pick("стимулирует киску <b>[M]</b> с помощью [src]", "запускает [src] глубоко в промежность <b>[M]</b>.")
					M.handle_post_sex(NORMAL_LUST*2, null, src)
					playsound(M, 'modular_sand/sound/lewd/champ_fingering.ogg', 75, 1, -1)
				if(M.has_penis() == HAS_EXPOSED_GENITAL && hole == "Penis")
					message = (user == M) ? pick("играет со своим членом при помощи [src].","использует [src] для стимуляции своего члена.", "постанывает и позволяет [src] глубоко заглотить свой член.") : pick("стимулирует член <b>[M]</b> с помощью [src]", "позволяет [src] глубоко заглотить член <b>[M]</b>.")
					M.handle_post_sex(NORMAL_LUST*2, null, src)
					playsound(M, 'modular_sand/sound/lewd/champ_fingering.ogg', 75, 1, -1)
				if(M.has_anus() == HAS_EXPOSED_GENITAL && hole == "Anus")
					message = (user == M) ? pick("играет со своей попой при помощи [src].", "использует [src] для стимуляции своей попы", "постанывает и запускает [src] глубже в своё анальное отверстие.") : pick("стимулирует попу <b>[M]</b> с помощью [src]", "запускает [src] глубоко в анальное отверстие <b>[M]</b>.")
					M.handle_post_sex(NORMAL_LUST*2, null, src)
					playsound(M, 'modular_sand/sound/lewd/champ_fingering.ogg', 75, 1, -1)

			if(BODY_ZONE_CHEST)
				if(M.has_breasts() == HAS_EXPOSED_GENITAL)
					message = (user == M) ? pick("играет со своей грудью при помощи [src].", "использует [src] для стимуляции своих сосоков.", "постанывает и прижимает [src] к своим сосочкам.") : pick("стимулирует грудь <b>[M]</b> с помощью [src]", "подставляет [src] к сосочкам <b>[M]</b>.")
					M.handle_post_sex(NORMAL_LUST, null, src)
					playsound(M, 'modular_sand/sound/lewd/champ_fingering.ogg', 75, 1, -1)
			if(BODY_ZONE_PRECISE_MOUTH)
				if(M.has_mouth() && !M.is_mouth_covered())
					message = (user == M) ? pick("трахает свой ротик при помощи [src].", "глубоко заглатывает [src].") : pick("трахает <b>[M]</b> прямо в ротик при помощи [src]", "заставляет <b>[M]</b> заглатывать [src].")
					playsound(M, pick('modular_sand/sound/interactions/bj1.ogg',
										'modular_sand/sound/interactions/bj2.ogg',
										'modular_sand/sound/interactions/bj3.ogg',
										'modular_sand/sound/interactions/bj4.ogg',
										'modular_sand/sound/interactions/bj5.ogg',
										'modular_sand/sound/interactions/bj6.ogg',
										'modular_sand/sound/interactions/bj7.ogg',
										'modular_sand/sound/interactions/bj8.ogg',
										'modular_sand/sound/interactions/bj9.ogg',
										'modular_sand/sound/interactions/bj10.ogg',
										'modular_sand/sound/interactions/bj11.ogg'), 50, 1, -1)

	if(message)
		user.visible_message("<span class='lewd'><b>[user]</b> [message].</span>")

		switch (user.zone_selected)
			if (BODY_ZONE_PRECISE_GROIN)
				user.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, min(NORMAL_LUST*2 * 5, 100), PLUG13_DURATION_NORMAL)
			if(BODY_ZONE_CHEST)
				user.client?.plug13.send_emote(PLUG13_EMOTE_CHEST, min(NORMAL_LUST*2 * 5, 100), PLUG13_DURATION_NORMAL)

		if(!HAS_TRAIT(M, TRAIT_LEWD_JOB))
			new /obj/effect/temp_visual/heart(M.loc)
	else if(user.a_intent == INTENT_HARM)
		return ..()
