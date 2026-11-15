// Hyper stuff

//Lipstick
/obj/item/lipstick/yellow
	name = "yellow lipstick"
	colour = "yellow"

/obj/item/lipstick/blue
	name = "blue lipstick"
	colour = "blue"

/obj/item/lipstick/teal
	name = "teal lipstick"
	colour = "teal"

/obj/item/lipstick/fuchsia
	name = "fuchsia lipstick"
	colour = "fuchsia"

/obj/item/lipstick/navy
	name = "navy blue lipstick"
	colour = "navy"

/obj/item/lipstick/aqua
	name = "cyan lipstick"
	colour = "aqua"

/obj/item/lipstick/white
	name = "white lipstick"
	colour = "white"

//Nail polish
/obj/item/nailpolish
	name = "nail polish"
	desc = "Лак с тонкой кисточкой: накрасить ногти себе или кому-нибудь ещё. Держится, пока его не смоют нарочно: душ, вода и пена его не берут, а мыло по руке или плеснутый на руки ацетон снимают. Поверх старого лака новый не ложится."
	icon = 'modular_splurt/icons/obj/cosmetic.dmi'
	icon_state = "nailcap"
	item_state = "nailpolish"
	w_class = WEIGHT_CLASS_SMALL
	var/paint = "black"
	var/mutable_appearance/bottle //show the colour on the bottle.

/obj/item/nailpolish/red
	name = "red nail polish"
	paint = "red"

/obj/item/nailpolish/blue
	name = "blue nail polish"
	paint = "blue"

/obj/item/nailpolish/aqua
	name = "cyan nail polish"
	paint = "aqua"

/obj/item/nailpolish/black
	name = "black nail polish"
	paint = "black"

/obj/item/nailpolish/white
	name = "white nail polish"
	paint = "white"

/obj/item/nailpolish/navy
	name = "navy nail polish"
	paint = "navy"

/obj/item/nailpolish/yellow
	name = "yellow nail polish"
	paint = "yellow"

/obj/item/nailpolish/purple
	name = "purple nail polish"
	paint = "purple"

/obj/item/nailpolish/Initialize()
	. = ..()
	bottle = mutable_appearance('modular_splurt/icons/obj/cosmetic.dmi', "nailpolish")
	bottle.color = paint
	add_overlay(bottle)


/obj/item/nailpolish/attack(mob/M, mob/user)
	if(!ishuman(M))
		to_chat(user, span_warning("Тут нет ногтей, которые можно накрасить."))
		return
	var/mob/living/carbon/human/H = M
	if(!can_paint(H, user))
		return
	if(H != user)
		user.visible_message(span_notice("[user] начинает красить ногти [H] лаком."), span_notice("Вы начинаете красить ногти [H] лаком..."))
		if(!do_after(user, NAIL_POLISH_APPLY_TIME, target = H) || !can_paint(H, user))
			return
	H.nail_style = "nails"
	H.nail_color = paint
	H.update_body()
	if(H == user)
		user.visible_message(span_notice("[user] красит себе ногти лаком."), span_notice("Вы аккуратно красите ногти лаком. Идеально!"))
	else
		user.visible_message(span_notice("[user] красит ногти [H] лаком."), span_notice("Вы красите ногти [H] лаком."))

/obj/item/nailpolish/proc/can_paint(mob/living/carbon/human/H, mob/user)
	if(H.nail_style)
		to_chat(user, span_warning("На ногтях уже есть лак. Сначала его нужно смыть мылом или ацетоном."))
		return FALSE
	if(!H.get_num_arms(FALSE))
		to_chat(user, span_warning("Нет рук - нет и ногтей."))
		return FALSE
	if(H.nail_polish_hands_covered())
		to_chat(user, span_warning("Ногти закрыты, сначала снимите перчатки."))
		return FALSE
	return TRUE

/// Закрыты ли кисти одеждой: лак под ней не красят и не смывают.
/mob/living/carbon/human/proc/nail_polish_hands_covered(hand_bits = HANDS)
	for(var/obj/item/worn as anything in list(gloves, wear_suit, w_uniform, wrists, w_shirt))
		if(worn?.body_parts_covered & hand_bits)
			return TRUE
	return FALSE

/// Снимает лак с ногтей. Вода и пена его не берут: только мыло по руке или ацетон.
/mob/living/carbon/human/proc/remove_nail_polish()
	if(!nail_style)
		return FALSE
	nail_style = null
	update_body()
	return TRUE
