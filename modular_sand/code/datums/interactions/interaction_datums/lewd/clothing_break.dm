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

	var/distance = is_hidden ? 1 : 7
	var/picked_hidden = is_hidden ? pick(hidden_additional) : ""

	// Проверка предмета в руке
	var/obj/item/item_in_hand = user.held_items[user.active_hand_index]
	if (!item_in_hand)
		to_chat(user, span_warning("Вам нужен любой острый предмет в активной руке"))
		return

	if (item_in_hand.sharpness < SHARP_EDGED)
		to_chat(user, span_warning("Ваш предмет недостаточно острый!"))
		return

	// Проверка униформы
	var/obj/item/clothing/target_uniform = partner_human.w_uniform
	if (!target_uniform)
		to_chat(user, span_warning("У цели нет униформы!"))
		return

	if(!partner_human.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_THICK))
		to_chat(user, span_warning("Что-то не даёт пробиться до униформы!"))
		return

	// Сообщения ДО начала
	to_chat(partner_human, span_big_warning("[user] начинает рвать вашу одежду при помощи [item_in_hand.name]"))
	partner_human.visible_message(span_danger("[user] начинает рвать одежду [partner_human] при помощи [item_in_hand.name]"))

	// ★★★ ГЛАВНЫЙ FIX: Вызываем do_after здесь ★★★
	if(!do_after(user, 3 SECONDS, target = partner_human))
		to_chat(user, span_warning("Вы остановились."))
		return

	// А теперь уже применяем повреждения
	var/damage_amount = rand(1, 1)
	var/lust_amount = NORMAL_LUST

	// Повреждаем униформу (добавьте этот прок в одежду)
	target_uniform.take_damage(150, BRUTE, MELEE, 0) // Или другой метод

	var/message = "[is_hidden ? picked_hidden : null]<b>[user]</b> рвёт униформу <b>[partner_human]</b> при помощи своего [item_in_hand.name]."
	if (user.a_intent == INTENT_HARM)
		message = "[is_hidden ? picked_hidden : null]<b>[user]</b> резким движением, с силой, рассекает униформу <b>[partner_human]</b> своим [item_in_hand.name] на куски."
		partner_human.apply_damage(damage_amount, BRUTE, BODY_ZONE_CHEST, partner_human.run_armor_check(BODY_ZONE_CHEST, MELEE))

	user.visible_message(message, ignored_mobs = user.get_unconsenting(), vision_distance = distance)

	if (HAS_TRAIT(partner_human, TRAIT_MASO))
		partner_human.handle_post_sex(lust_amount, null, user)
