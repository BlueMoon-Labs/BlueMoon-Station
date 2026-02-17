/obj/item/buttplug
	icon 		= 'modular_splurt/icons/obj/lewd_items/lewd_items.dmi'
	var/buttplug_size  = 1
	var/inside = FALSE

/obj/item/buttplug/small
	name		= "Small Buttplug"
	desc		= "Маленькая затычка для анального кольца. Обычно, она используется... для удовлетворения."
	icon_state  = "buttplug_metal_small"
	buttplug_size  = 1
	unique_reskin = list(
		"Basic Metal" = list(
			RESKIN_ICON_STATE = "buttplug_metal_small"
		),
		"Pink" = list(
			RESKIN_ICON_STATE = "buttplug_pink_small"
		),
		"Teal" = list(
			RESKIN_ICON_STATE = "buttplug_teal_small"
		),
		"Yellow" = list(
			RESKIN_ICON_STATE = "buttplug_yellow_small"
		),
		"Green" = list(
			RESKIN_ICON_STATE = "buttplug_green_small"
		),
	)

/obj/item/buttplug/med
	name		= "Medium Buttplug"
	desc		= "Средняя затычка для анального кольца. Обычно, она используется... для удовлетворения."
	icon_state  = "buttplug_metal_medium"
	buttplug_size  = 3
	unique_reskin = list(
		"Basic Metal" = list(
			RESKIN_ICON_STATE = "buttplug_metal_medium"
		),
		"Pink" = list(
			RESKIN_ICON_STATE = "buttplug_pink_medium"
		),
		"Teal" = list(
			RESKIN_ICON_STATE = "buttplug_teal_medium"
		),
		"Yellow" = list(
			RESKIN_ICON_STATE = "buttplug_yellow_medium"
		),
		"Green" = list(
			RESKIN_ICON_STATE = "buttplug_green_medium"
		),
	)

/obj/item/buttplug/big
	name		= "Big Buttplug"
	desc		= "Большая затычка для анального кольца. Обычно, она используется... для удовлетворения."
	icon_state  = "buttplug_metal_big"
	buttplug_size  = 4
	unique_reskin = list(
		"Basic Metal" = list(
			RESKIN_ICON_STATE = "buttplug_metal_big"
		),
		"Pink" = list(
			RESKIN_ICON_STATE = "buttplug_pink_big"
		),
		"Teal" = list(
			RESKIN_ICON_STATE = "buttplug_teal_big"
		),
		"Yellow" = list(
			RESKIN_ICON_STATE = "buttplug_yellow_big"
		),
		"Green" = list(
			RESKIN_ICON_STATE = "buttplug_green_big"
		),
	)

/obj/item/buttplug/ComponentInitialize()
	. = ..()
	var/list/procs_list = list(
		"before_inserting" = CALLBACK(src, PROC_REF(item_inserting)),
		"after_inserting" = CALLBACK(src, PROC_REF(item_inserted)),
		"after_removing" = CALLBACK(src, PROC_REF(item_removed)),
	)
	AddComponent(/datum/component/genital_equipment, list(ORGAN_SLOT_PENIS, ORGAN_SLOT_WOMB, ORGAN_SLOT_VAGINA, ORGAN_SLOT_BREASTS, ORGAN_SLOT_ANUS), procs_list)

/obj/item/buttplug/proc/item_inserting(datum/source, obj/item/organ/genital/G, mob/living/user)
	. = TRUE
	if(!(G.owner.client?.prefs?.erppref == "Yes"))
		to_chat(user, span_warning("They don't want you to do that!"))
		return FALSE

	if(!(CHECK_BITFIELD(G.genital_flags, GENITAL_CAN_STUFF)))
		to_chat(user, span_warning("This genital can't be stuffed!"))
		return FALSE

	if(locate(src.type) in G.contents)
		if(user == G.owner)
			to_chat(user, span_notice("You already have a buttplug inside your [G]!"))
		else
			to_chat(user, span_notice("\The <b>[G.owner]</b>'s [G] already has a buttplug inside!"))
		return FALSE

	if(user == G.owner)
		G.owner.visible_message(span_warning("\The <b>[user]</b> is trying to insert buttplug inside themselves!"),\
			span_warning("You try to insert buttplug inside yourself!"))
	else
		G.owner.visible_message(span_warning("\The <b>[user]</b> is trying to insert buttplug inside \the <b>[G.owner]</b>!"),\
			span_warning("\The <b>[user]</b> is trying to insert buttplug inside you!"))

	if(!do_mob(user, G.owner, 5 SECONDS))
		return FALSE

	to_chat(G.owner, span_userlove("[G] чувствует что-то крупное внутри!"))
	G.owner.handle_post_sex(NORMAL_LUST*3, null, G.owner)
	G.owner.plug13_genital_emote(G, NORMAL_LUST*2)
	G.owner.Jitter(2)
	playsound(G.owner, 'modular_sand/sound/lewd/champ_fingering.ogg', 50, 1, -1)

/obj/item/buttplug/proc/item_inserted(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE
	to_chat(user, span_userlove("You attach [src] to <b>\The [G.owner]</b>'s [G]."))
	playsound(G.owner, 'modular_sand/sound/lewd/champ_fingering.ogg', 50, 1, -1)
	inside = TRUE
	stuffed_movement(G.owner)

/obj/item/buttplug/proc/item_removed(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE
	to_chat(user, span_userlove("You retrieve [src] from <b>\The [G.owner]</b>'s [G]."))
	playsound(G.owner, 'modular_sand/sound/lewd/champ_fingering.ogg', 50, 1, -1)
	inside = FALSE

/obj/item/buttplug/proc/stuffed_movement(mob/living/user)
	while(inside)
		if(activate_after(src, rand(50,350))) //5 to 35 seconds, every 20 sec on average
			if(!istype(src.loc, /obj/item/organ/genital))
				return
			if(buttplug_size == 4)
				to_chat(user, span_userdanger(pick("Огромная затычка внутри сводит вас с ума!", "Вы чувствуете мучительное удовольствие от огромной затычки глубоко внутри!")))
				user.handle_post_sex(HIGH_LUST*2, null, user)
				user.plug13_genital_emote(loc, HIGH_LUST*2 * 2)
				if(user.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
					user.Jitter(2)
				user.Stun(3)
				user.emote("moan")
			else if(buttplug_size != 1)
				to_chat(user, span_love(pick("Затычка внутри сводит вас с ума!", "Вы чувствуете мучительное удовольствие от затычки глубоко внутри!")))
				user.handle_post_sex(NORMAL_LUST*2, null, user)
				user.plug13_genital_emote(loc, NORMAL_LUST*2 * 2)
				if(user.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
					user.Jitter(1)
				user.Stun(1)
				user.emote("moan")
			else
				to_chat(user, span_love(pick("Я чувствую анальную затычку внутри!", "Вы чувствуете удовольствие от затычки глубоко внутри!")))
				user.handle_post_sex(LOW_LUST*2, null, user)
				user.plug13_genital_emote(loc, LOW_LUST*2 * 2)
