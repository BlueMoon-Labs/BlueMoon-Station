/datum/interaction/lewd/tear_of_clothing
	description = "Порвать униформу"
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT
	write_log_user = "trying to tear off"
	write_log_target = "was tearing off"
	required_from_target = INTERACTION_REQUIRE_HANDS

/datum/interaction/lewd/tear_of_clothing/display_interaction(mob/living/user, mob/living/partner, is_hidden)
	var/mob/living/carbon/human/partner_human = astype(partner, /mob/living/carbon/human)
	if(!partner_human)
		return
	var/distance = 7
	if(is_hidden)
		distance = 1

	var/picked_hidden = pick(hidden_additional)

	var/obj/item/item_in_hand = user.held_items[user.active_hand_index]
	if (!item_in_hand)
		to_chat(user, span_warning("Вам нужен любой острый предмет в активной руке"))
		return

	var/sharpness = item_in_hand.sharpness
	if (sharpness < SHARP_EDGED)
		to_chat(user, span_warning("Ваш предмет недостаточно острый!"))
		return

	var/obj/item/clothing/target_uniform = partner_human.w_uniform
	if (!target_uniform)
		to_chat(user, span_warning("У цели нет униформы!"))
		return
	to_chat(partner_human, span_big_warning("[user] начинает рвать вашу одежду при помощью [item_in_hand.name]"))
	partner_human.visible_message(span_danger("[user] начинает рвать одежду [partner_human] при помощью [item_in_hand.name]"))
	if(!partner_human.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_THICK)) //Можем ли добраться до униформы?
		to_chat(user, span_warning("Что-то не даёт пробиться до униформы!"))
		return

	if(target_uniform.attackby(item_in_hand, user) == CLOTHING_DAMAGED) //там внутри функции есть do_after. Если он завершается корректно, то всё что ниже выполняется

		var/message
		var/damage_amount = rand(1, 3)
		var/lust_amount = NORMAL_LUST

		if (user.a_intent == INTENT_HARM)
			message = "[is_hidden ? picked_hidden : null]<b>[user]</b> резким движением, с силой, рассекает униформу <b>[partner_human]</b> своим [item_in_hand.name] на куски."
			partner_human.apply_damage(damage_amount, BRUTE, BODY_ZONE_CHEST, partner_human.run_armor_check(BODY_ZONE_CHEST, MELEE))
		else
			message = "[is_hidden ? picked_hidden : null]<b>[user]</b> рвёт униформу <b>[partner_human]</b> при помощи своего [item_in_hand.name]."

		user.visible_message(message, ignored_mobs = user.get_unconsenting(), vision_distance = distance)

		if (HAS_TRAIT(partner_human, TRAIT_MASO))
			partner_human.handle_post_sex(lust_amount, null, user)
