/**
 * Что сделает ПКМ по атому: пустой рукой (held_item = null) или по предмету в руке (held_item = src).
 * Подпись идёт в скринтип и в меню действий. null - своего ПКМ-действия нет.
 */
/atom/proc/secondary_action_hint(mob/living/user, obj/item/held_item)
	return null

/// Собирает контекст скринтипа: сигналы атома и предмета в руке плюс ПКМ-действие
/atom/proc/collect_screentip_context(mob/living/user, obj/item/held_item, list/context)
	. = NONE
	if(flags_1 & HAS_CONTEXTUAL_SCREENTIPS_1 || held_item?.item_flags & ITEM_HAS_CONTEXTUAL_SCREENTIPS)
		. |= SEND_SIGNAL(src, COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM, context, held_item, user)
		if(held_item)
			. |= SEND_SIGNAL(held_item, COMSIG_ITEM_REQUESTING_CONTEXT_FOR_TARGET, context, src, user)
	if(context[SCREENTIP_CONTEXT_RMB] || (held_item && held_item != src))
		return
	var/hint = secondary_action_hint(user, held_item)
	if(hint)
		context[SCREENTIP_CONTEXT_RMB] = hint
		. |= CONTEXTUAL_SCREENTIP_SET

/// Открывает хранилище, не поднимая и не снимая его
/obj/item/proc/open_storage_in_place(mob/user)
	if(!user.CanReach(src))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_IS_STORAGE_LOCKED))
		to_chat(user, span_warning("[src] заперт."))
		return TRUE
	add_fingerprint(user)
	SEND_SIGNAL(src, COMSIG_TRY_STORAGE_SHOW, user)
	playsound(src, "rustle", 50, TRUE, -5)
	return TRUE

/obj/item/alt_attack_hand(mob/user)
	if(SEND_SIGNAL(src, COMSIG_CONTAINS_STORAGE))
		return open_storage_in_place(user)
	return ..()

/obj/item/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(SEND_SIGNAL(src, COMSIG_CONTAINS_STORAGE))
		return "Открыть"
	return ..()

// Стак: пустой рукой - выбрать, сколько взять

/obj/item/stack/alt_attack_hand(mob/user)
	if(is_cyborg || !isliving(user) || zero_amount())
		return ..()
	split_by_menu(user)
	return TRUE

/obj/item/stack/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(!held_item && !is_cyborg)
		return "Отделить"
	return ..()

// Ёмкости с реагентами: ЛКМ в руке - объём переливания больше, ПКМ - меньше

/obj/item/reagent_containers/rightclick_attack_self(mob/user)
	if(!(container_flags & APTFT_ALTCLICK) || length(possible_transfer_amounts) < 2)
		return ..()
	var/index = possible_transfer_amounts.Find(amount_per_transfer_from_this)
	index = index > 1 ? index - 1 : length(possible_transfer_amounts)
	amount_per_transfer_from_this = possible_transfer_amounts[index]
	balloon_alert(user, "по [amount_per_transfer_from_this] ед.")
	return TRUE

/obj/item/reagent_containers/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(held_item == src && (container_flags & APTFT_ALTCLICK) && length(possible_transfer_amounts) > 1)
		return "Меньше за раз"
	return ..()

// Баллон: внутренний воздух в руке и надетым

/obj/item/tank/rightclick_attack_self(mob/user)
	toggle_internals(user)
	return TRUE

/obj/item/tank/alt_attack_hand(mob/user)
	if(loc != user)
		return ..()
	toggle_internals(user)
	return TRUE

/obj/item/tank/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(loc == user && iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		return carbon_user.internal == src ? "Перекрыть воздух" : "Дышать из баллона"
	return ..()

// Одежда: стиль ношения не снимая

/obj/item/clothing/under/rightclick_attack_self(mob/user)
	if(!can_adjust)
		return ..()
	usr = user
	rolldown()
	return TRUE

/obj/item/clothing/under/alt_attack_hand(mob/user)
	if(loc != user || !can_adjust)
		return ..()
	usr = user
	rolldown()
	return TRUE

/obj/item/clothing/under/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(can_adjust && loc == user)
		return "Сменить стиль"
	return ..()

/obj/item/clothing/suit/toggle/rightclick_attack_self(mob/user)
	usr = user
	suit_toggle()
	return TRUE

/obj/item/clothing/suit/toggle/alt_attack_hand(mob/user)
	if(loc != user)
		return ..()
	usr = user
	suit_toggle()
	return TRUE

/obj/item/clothing/suit/toggle/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(loc == user)
		return suittoggled ? "Застегнуть" : "Расстегнуть"
	return ..()

/obj/item/clothing/suit/hooded/alt_attack_hand(mob/user)
	if(!ishuman(user) || user != loc)
		return ..()
	var/mob/living/carbon/human/wearer = user
	if(wearer.wear_suit != src)
		return ..()
	ToggleHood()
	return TRUE

/obj/item/clothing/suit/hooded/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(ishuman(user) && !held_item)
		var/mob/living/carbon/human/wearer = user
		if(wearer.wear_suit == src)
			return suittoggled ? "Снять капюшон" : "Надеть капюшон"
	return ..()

/obj/item/clothing/mask/alt_attack_hand(mob/user)
	if(!can_adjust_in_place(user))
		return ..()
	adjustmask(user)
	return TRUE

/obj/item/clothing/mask/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(!held_item && can_adjust_in_place(user))
		return mask_adjusted ? "Вернуть маску" : "Сдвинуть маску"
	return ..()

/obj/item/clothing/mask/proc/can_adjust_in_place(mob/user)
	return iscarbon(user) && loc == user && (/datum/action/item_action/adjust in actions_types)

// Свет: фонарик в кармане или на поясе, фонарь каски, фонарь на оружии

/obj/item/flashlight/alt_attack_hand(mob/user)
	if(loc != user)
		return ..()
	attack_self(user)
	return TRUE

/obj/item/flashlight/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(loc == user && !held_item)
		return on ? "Выключить" : "Включить"
	return ..()

/obj/item/clothing/head/hardhat/alt_attack_hand(mob/user)
	if(loc != user)
		return ..()
	toggle_helmet_light(user)
	return TRUE

/obj/item/clothing/head/hardhat/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(loc == user && !held_item)
		return on ? "Выключить фонарь" : "Включить фонарь"
	return ..()

/obj/item/gun/rightclick_attack_self(mob/user)
	if(!gun_light)
		return ..()
	usr = user
	toggle_gunlight()
	return TRUE

/obj/item/gun/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(held_item == src && gun_light)
		return gun_light.on ? "Выключить фонарь" : "Включить фонарь"
	return ..()

// Закрытая дверь: постучать

/obj/machinery/door/alt_attack_hand(mob/user)
	if(!density || operating || !isliving(user) || !Adjacent(user))
		return FALSE
	if(!user.CheckActionCooldown(CLICK_CD_MELEE))
		return TRUE
	user.DelayNextAction()
	user.do_attack_animation(src)
	playsound(src, 'sound/effects/Glassknock.ogg', 70, TRUE)
	user.visible_message(span_notice("[user] стучит в [src]."), span_notice("Вы стучите в [src]."))
	return TRUE

/obj/machinery/door/airlock/alt_attack_hand(mob/user)
	if(density && isElectrified() && shock(user, 100))
		return TRUE
	return ..()

/obj/machinery/door/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(density && !held_item)
		return "Постучать"
	return ..()

// Подсказки к уже существующим ПКМ-действиям

/obj/item/clipboard/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(!held_item && toppaper_ref?.resolve())
		return "Взять лист"
	return ..()

/obj/machinery/disposal/bin/secondary_action_hint(mob/living/user, obj/item/held_item)
	if(!held_item)
		return flush ? "Убрать смыв" : "Включить смыв"
	return ..()
