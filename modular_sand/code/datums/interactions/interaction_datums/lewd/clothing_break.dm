/datum/interaction/lewd/tear_of_clothing
	description = "Порвать одежду."
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT
	write_log_user = "trying to tear off"
	write_log_target = "was tearing off"
	required_from_target = INTERACTION_REQUIRE_HANDS
	hearts_effect = FALSE

/datum/interaction/lewd/tear_of_clothing/special_check(mob/living/user, mob/living/target)
	. = FALSE
	var/mob/living/carbon/human/partner_human = target
	if(!istype(partner_human) || INTERACTING_WITH(user, partner_human))
		return
	if(ishuman(user))
		var/obj/item/item_in_hand = user.get_active_held_item()
		if(!item_in_hand)
			to_chat(user, span_warning("Вам нужен любой острый предмет в активной руке"))
			return
		if(item_in_hand.sharpness < SHARP_EDGED)
			to_chat(user, span_warning("Ваш предмет недостаточно острый!"))
			return
	
	// Проверка одежды
	var/obj/item/clothing/target_uniform = partner_human.w_uniform
	if(!target_uniform)
		to_chat(user, span_warning("Нечего кромсать!"))
		return
	if(target_uniform.damaged_clothes == CLOTHING_SHREDDED)
		to_chat(user, span_warning("[partner_human.ru_ego()] одежда уже как лохмотья!"))
		return

	if(!partner_human.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_THICK))
		to_chat(user, span_warning("Что-то не даёт пробиться до одежды или она слишком прочная!"))
		return

	return ..()

/datum/interaction/lewd/tear_of_clothing/display_interaction(mob/living/user, mob/living/target, is_hidden)
	var/mob/living/carbon/human/partner_human = target

	var/distance = is_hidden ? 1 : 7
	var/picked_hidden = pick(hidden_additional)

	var/obj/item/item_in_hand = user.get_active_held_item()
	partner_human.visible_message(span_danger("[user] начинает рвать одежду [partner_human][item_in_hand ? " при помощи [item_in_hand.name]" : null]."),\
								target = partner_human, target_message = span_userdanger("[user] начинает рвать вашу одежду[item_in_hand ? " при помощи [item_in_hand.name]" : null]."))
	
	var/obj/item/clothing/target_uniform = partner_human.w_uniform
	if(!do_after(user, 4 SECONDS, partner_human) || QDELETED(target_uniform) || partner_human.w_uniform != target_uniform)
		return

	target_uniform.obj_destruction(MELEE)

	if(HAS_TRAIT(partner_human, TRAIT_MASO))
		partner_human.handle_post_sex(NORMAL_LUST, null, user)

	var/message = "[is_hidden ? picked_hidden : null]<b>[user]</b> рвёт одежду <b>[partner_human]</b>[item_in_hand ? " при помощи своего [item_in_hand.name]" : null]."
	if(user.a_intent == INTENT_HARM)
		message = "[is_hidden ? picked_hidden : null]<b>[user]</b> резким движением, с силой рассекает одежду <b>[partner_human]</b>[item_in_hand ? " своим [item_in_hand.name]" : null] на куски."
		partner_human.apply_damage(rand(1, 5), BRUTE, BODY_ZONE_CHEST, partner_human.run_armor_check(BODY_ZONE_CHEST, MELEE), wound_bonus = CANT_WOUND)

	user.visible_message(span_danger(message), "Вы рвёте одежду на [partner_human], превращая её в клочья.", ignored_mobs = user.get_unconsenting(), vision_distance = distance,\
						target = partner_human, target_message = span_userdanger("[user] рвет на вас одежду, превращая её в клочья!"))
