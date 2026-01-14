/datum/interaction/lewd/simplified_interaction
	simple_style = "lewd"
	big_user_target_text = TRUE
	var/target_organ		// орган для взаимодействия
	var/try_milking = FALSE // пытаемся-ли выдоить что-то в контейнер
	var/cum_target = ""
	// для фраз стоит находить формулировки в которых можно будет использовать USER и TARGET
	var/start_text
	var/help_text
	var/grab_text
	var/harm_text
	var/list/lewd_sounds
	var/p13target_strength_base_point = PLUG13_STRENGTH_NORMAL // точка к которой прибавляет +1 уровень при граб, дизарм и +2 уровня при харме

/datum/interaction/lewd/simplified_interaction/proc/text_picker(mob/living/user, mob/living/partner) // особая проверка для замены текста в n ситуации
	return

/datum/interaction/lewd/simplified_interaction/proc/lust_granted(mob/living/partner) // разрешение на получение удовольствия
	return TRUE

/datum/interaction/lewd/simplified_interaction/display_interaction(mob/living/user, mob/living/partner)
	var/obj/item/reagent_containers/liquid_container
	if(try_milking)
		var/obj/item/cached_item = user.get_active_held_item()
		if(istype(cached_item, /obj/item/reagent_containers))
			liquid_container = cached_item
		else
			cached_item = user.pulling
			if(istype(cached_item, /obj/item/reagent_containers))
				liquid_container = cached_item

	p13target_strength = p13target_strength_base_point
	simple_message = null	// используем для сообщения базовую переменную
	var/lust_amount = NORMAL_LUST
	var/obj/item/organ/genital/partner_organ = partner.getorganslot(target_organ)
	text_picker(user, partner)	// для особых случаев
	if(partner.is_fucking(user, cum_target, partner_organ))
		switch(user.a_intent)
			if(INTENT_HELP)
				simple_message = islist(help_text) ? pick(help_text) : help_text
			if(INTENT_GRAB, INTENT_DISARM)
				p13target_strength = min(p13target_strength + 20, 100)
				simple_message = islist(grab_text) ? pick(grab_text) : grab_text
				lust_amount += 4 // чуть лучше, но не прям на HIGH_LUST
			if(INTENT_HARM)
				p13target_strength = min(p13target_strength + 40, 100)
				simple_message = islist(harm_text) ? pick(harm_text) : harm_text
				if(HAS_TRAIT(partner, TRAIT_MASO))
					lust_amount = HIGH_LUST
				else
					lust_amount = LOW_LUST
	else	// начинаем как на help независимо от интента
		simple_message = islist(start_text) ? pick(start_text) : start_text
		partner.set_is_fucking(user, cum_target, partner_organ)

	if(liquid_container)
		simple_message += " Стараясь ловить исходящие жидкости в [liquid_container]"
	if(lust_granted(partner))
		partner.handle_post_sex(lust_amount, cum_target, liquid_container ? liquid_container : user,  partner_organ)
	if(massage_by_user)
		playlewdinteractionsound(get_turf(user), pick(lewd_sounds), 70, 1, -1)
	else
		playlewdinteractionsound(get_turf(partner), pick(lewd_sounds), 70, 1, -1)
	..() // отправка сообщения в родительском проке
