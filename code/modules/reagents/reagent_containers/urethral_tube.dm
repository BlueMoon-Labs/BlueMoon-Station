/// Уретральная трубка — контейнер с реагентами для переливания жидкостей внутрь уретры цели.
/obj/item/reagent_containers/urethral_tube
	name = "уретральная трубка"
	desc = "Гибкая трубка с наконечником для введения в уретру. Можно наполнить жидкостью и перелить её внутрь при обнажённом пахе цели."
	icon = 'modular_splurt/icons/obj/sounding.dmi'
	item_state = "urethral_tube"
	icon_state = "urethral_tube"
	amount_per_transfer_from_this = 5
	possible_transfer_amounts = null
	volume = 30
	reagent_flags = TRANSPARENT
	var/busy = FALSE

/obj/item/reagent_containers/urethral_tube/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/reagent_containers/urethral_tube/on_reagent_change(changetype)
	update_icon()

/obj/item/reagent_containers/urethral_tube/update_icon_state()
	if(reagents && reagents.total_volume)
		icon_state = "urethral_tube_filled"
	else
		icon_state = "urethral_tube"

/obj/item/reagent_containers/urethral_tube/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity || busy)
		return
	if(!isliving(target))
		if(istype(target, /obj/item/reagent_containers/glass))
			if(!target.reagents.total_volume)
				to_chat(user, "<span class='warning'>Внутри [target] пусто!</span>")
				return
			var/trans = target.reagents.trans_to(src, amount_per_transfer_from_this, log = TRUE)
			to_chat(user, "<span class='notice'>Вы наполнили [src] на [trans] u раствора. Теперь внутри [reagents.total_volume] u.</span>")
		return
	var/mob/living/L = target
	INVOKE_ASYNC(src, PROC_REF(attempt_urethral_transfusion), L, user)

/obj/item/reagent_containers/urethral_tube/attack_self(mob/user)
	. = ..()
	if(reagents?.total_volume)
		reagents.clear_reagents()
		to_chat(user, span_notice("Вы опустошили трубку."))
	else
		to_chat(user, span_notice("В трубке нет жидкости."))


/obj/item/reagent_containers/urethral_tube/proc/attempt_urethral_transfusion(mob/living/target, mob/user)
	if(busy)
		return
	if(!reagents?.total_volume)
		to_chat(user, span_notice("В трубке нет жидкости."))
		return

	// Только углеводородные гуманоиды с обнажённым пахом
	if(!iscarbon(target))
		to_chat(user, span_warning("Перелить жидкость в уретру можно только гуманоиду с соответствующими органами."))
		return

	var/mob/living/carbon/C = target

	if(!(C.has_penis() || C.has_vagina()))
		to_chat(user, span_warning("У [C] нет подходящего органа для введения трубки."))
		return
	if(!C.is_groin_exposed())
		to_chat(user, span_warning("Пах [C] должен быть обнажён."))
		return

	if(!C.reagents || C.reagents.total_volume >= C.reagents.maximum_volume)
		to_chat(user, span_notice("Организм [C] не примет больше веществ."))
		return

	// Согласие на ERP-действия
	if(C.client?.prefs?.erppref != "Yes")
		to_chat(user, span_warning("[C] не согласен на такие действия!"))
		return

	if(user != target)
		target.visible_message(
			span_warning("[user] подносит уретральную трубку к [target] и готовится ввести её в уретру!"),
			span_userdanger("[user] подносит уретральную трубку к тебе, собираясь ввести её в уретру!")
		)
		busy = TRUE
		if(!do_mob(user, target, 3 SECONDS))
			busy = FALSE
			return
		if(!reagents?.total_volume)
			busy = FALSE
			return
		if(C.reagents.total_volume >= C.reagents.maximum_volume)
			busy = FALSE
			return

	busy = TRUE
	var/amount = min(amount_per_transfer_from_this, reagents.total_volume)
	var/fraction = min(amount / reagents.total_volume, 1)

	reagents.reaction(C, INJECT, fraction)
	reagents.trans_to(C, amount, log = TRUE)

	if(user == target)
		user.visible_message(
			span_warning("[user] вводит уретральную трубку себе и переливает жидкость в уретру."),
			span_userlove("Вы вводите трубку в уретру и переливаете [amount] ед. жидкости.")
		)
	else
		target.visible_message(
			span_warning("[user] вводит уретральную трубку в уретру [target] и переливает жидкость."),
			span_userdanger("[user] вводит трубку в твою уретру и переливает жидкость — ты чувствуешь необычное ощущение внутри.")
		)
		log_combat(user, target, "urethral transfusion", src, addition="which had [reagents.log_list()]")

	to_chat(user, span_notice("Перелито [amount] ед. В трубке осталось [reagents.total_volume] ед."))
	playsound(target, 'modular_sand/sound/lewd/champ_fingering.ogg', 30, 1, -1)
	busy = FALSE
	update_icon()
