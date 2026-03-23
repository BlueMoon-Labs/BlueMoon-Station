/obj/item/clothing/underwear/briefs/tentacle
	name = "panties?"
	icon_state = "panties_slim"
	var/tired = FALSE
	var/lust = 0

/obj/item/clothing/underwear/briefs/tentacle/random
	name = "undies"
/obj/item/clothing/underwear/briefs/tentacle/random/Initialize()
	. = ..()
	icon_state = pick("briefs", "boxer_briefs", "boxers", "bee_shorts", "boxers_commie", "boxers_heart", "boxers_long", "boxers_striped", "boxers_uk", "boxers_assblastusa", "jockstrap", "mankini", "panties", "panties_alt", "panties_bee-kini", "panties_commie", "panties_fishnet", "panties_kinky", "panties_neko", "panties_slim", "panties_striped", "panties_swimming", "panties_slim", "thong", "thong_babydoll", "panties_uk", "panties_assblastusa")

/obj/item/clothing/underwear/briefs/tentacle/equipped(mob/living/carbon/M)
	. = ..()
	tentacle_panties(M)

/obj/item/clothing/underwear/briefs/tentacle/chameleon
	name = "panties?"

/obj/item/clothing/underwear/briefs/tentacle/chameleon/Initialize(mapload)
	. = ..()
	var/datum/action/item_action/chameleon/change/chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/underwear/briefs
	chameleon_action.chameleon_name = "Panties"
	chameleon_action.initialize_disguises()

/obj/item/clothing/underwear/briefs/tentacle/attack_hand(mob/living/carbon/human/user)
	if(loc == user && ITEM_SLOT_UNDERWEAR)
		if(!istype(src, user.w_underwear))
			..()
		else
			user.visible_message("<span class='warning'>[user] пытается отодрать [src]!.</span>")
			if(do_after(user, rand(5,35)))
				if(prob(25))
					..()
				else
					to_chat(user, "<span class='warning'>Не отдирается!</span>")
					return
	else
		..()

/obj/item/clothing/underwear/briefs/tentacle/male
	name = "briefs"
	icon_state = "briefs"

/obj/item/clothing/underwear/briefs/tentacle/female
	name = "panties"
	icon_state = "panties_slim"

/obj/item/clothing/underwear/briefs/tentacle/portal
	name = "portal panties"
	icon = 'modular_sand/icons/obj/fleshlight.dmi'
	icon_state = "portalpanties"

/obj/item/storage/box/tentacle_panties
	name =  "Living panties box"
	icon = 'modular_sand/icons/obj/fleshlight.dmi'
	desc = "A small silver box with Silver Love Co embossed."
	icon_state = "box"
	custom_price = 500

// portal fleshlight box
/obj/item/storage/box/tentacle_panties/PopulateContents()
	new /obj/item/clothing/underwear/briefs/tentacle/male(src)
	new /obj/item/clothing/underwear/briefs/tentacle/female(src)
	new /obj/item/clothing/underwear/briefs/tentacle/portal(src)
	new /obj/item/clothing/underwear/briefs/tentacle/chameleon(src)

/obj/item/clothing/underwear/briefs/tentacle/proc/tentacle_panties(mob/living/carbon/human/M, slot)
	if(!istype(src, M.w_underwear))
		return
	while(istype(src, M.w_underwear))
		if(tired == TRUE)
			if(activate_after(src, rand(500,1000)))
				tired = FALSE

		if(activate_after(src, rand(25 ,50)) && tired == FALSE)
			if(prob(15))
				if(M.has_penis())
					to_chat(M, span_userdanger(pick("Движения в уретре сводят меня с ума!", "Вы чувствуете мучительное удовольствие от сильной стимуляции своего члена!")))
				if(M.has_vagina())
					to_chat(M, span_userdanger(pick("Сильные фрикции внутри сводят меня с ума!", "Вы чувствуете мучительное удовольствие от сильных фрикций внутри своих дырочек!")))
				M.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, NORMAL_LUST*2 * 2)
				M.handle_post_sex(NORMAL_LUST*2, null, M)
				if(M.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
					M.Jitter(3)
				M.Stun(30)
				M.emote("moan")
			else
				if(M.has_penis())
					to_chat(M, span_love(pick("Я чувствую что-то у своего члена!", "Оно обсасывает мой член!")))
				if(M.has_vagina())
					to_chat(M, span_love(pick("Я чувствую что-то внутри!", "Оно движется внутри меня!", "Я ощущаю фрикции в своих дырочках!")))
				M.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, NORMAL_LUST * 2)
				M.handle_post_sex(NORMAL_LUST, null, M)
				if(M.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
					M.do_jitter_animation()
			lust += rand(1 ,10)
			playsound(loc, 'modular_sand/sound/lewd/champ_fingering.ogg', 25, 1, -1)

			if(prob(50) && lust >= 300)
				tired = TRUE
				to_chat(M, span_love(pick("Оно меня обкончало!")))
				visible_message("<font color=purple>Вязкая жидкость вытекает из <b>[src]</b> и стекает по бедрам <b>[M]</b>!</font>")
				M.reagents.add_reagent(/datum/reagent/consumable/semen, 10)
				M.reagents.add_reagent(/datum/reagent/drug/aphrodisiacplus, 5) //Cum contains hexocrocin
				new /obj/effect/decal/cleanable/semen(loc)
