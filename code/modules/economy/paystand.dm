/obj/machinery/paystand
	name = "unregistered pay stand"
	desc = "Стенд оплаты. Проведите по нему ID-картой с личным счётом, чтобы привязать его к себе."
	icon = 'icons/obj/economy.dmi'
	icon_state = "card_scanner"
	density = TRUE
	anchored = TRUE
	var/locked = FALSE
	var/obj/item/card/id/my_card
	var/obj/item/assembly/signaler/signaler //attached signaler, let people attach signalers that get activated if the user's transaction limit is achieved.
	var/signaler_threshold = 0 //signaler threshold amount
	var/amount_deposited = 0 //keep track of the amount deposited over time so you can pay multiple times to reach the signaler threshold
	var/force_fee = 0 //replaces the "pay whatever" functionality with a set amount when non-zero.

/obj/machinery/paystand/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/card/id))
		if(W == my_card)
			if(user.a_intent == INTENT_DISARM)
				var/rename_msg = stripped_input(user, "Rename the Paystand:", "Paystand Naming", name)
				if(!rename_msg || !user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
					return
				name = rename_msg
				return
			else if(user.a_intent == INTENT_GRAB)
				var/force_fee_input = input(user,"Set the fee!","Set a fee!",0) as num|null
				if(isnull(force_fee_input) || !user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
					return
				force_fee = force_fee_input
				return
			locked = !locked
			to_chat(user, "<span class='notice'>You [src.locked ? "lock" : "unlock"] the paystand, protecting the bolts from [anchored ? "loosening" : "tightening"].</span>")
			return
		if(!my_card)
			var/obj/item/card/id/assistant_mains_need_to_die = W
			if(!assistant_mains_need_to_die.registered_account)
				return
			var/msg = stripped_input(user, "Название стенда оплаты:", "Название стенда", "Стенд оплаты [user]")
			if(!msg)
				return
			name = msg
			desc = "Стенд оплаты [assistant_mains_need_to_die.registered_account.account_holder]: оплата идёт прямо на этот счёт."
			my_card = assistant_mains_need_to_die
			to_chat(user, span_notice("Стенд привязан к вашему счёту."))
			return
		var/obj/item/card/id/vbucks = W
		if(vbucks.registered_account)
			var/payment_problem = card_payment_problem(vbucks.registered_account)
			if(payment_problem)
				to_chat(user, span_warning(payment_problem))
				return
		if(vbucks.registered_account)
			var/momsdebitcard = 0
			if(!force_fee)
				momsdebitcard = input(user, "Сколько заплатить?", "Оплата") as null|num
			else
				momsdebitcard = force_fee
			if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
				return
			var/payment_problem = card_payment_problem(vbucks.registered_account)
			if(payment_problem)
				to_chat(user, span_warning(payment_problem))
				return
			if(momsdebitcard < 1)
				to_chat(user, span_warning("Сумма должна быть не меньше 1 кр."))
				return
			momsdebitcard = round(momsdebitcard)
			if(purchase(vbucks.registered_account.account_holder, momsdebitcard, vbucks.registered_account, user))
				to_chat(user, span_notice("Оплачено [momsdebitcard] кр., владелец стенда получил уведомление."))
				return
			else
				to_chat(user, span_warning("Оплата не прошла: на счёте не хватает денег."))
				return
		else
			to_chat(user, span_warning("У этой карты нет банковского счёта."))
			return
	if(istype(W, /obj/item/holochip))
		var/obj/item/holochip/H = W
		var/cashmoney = input(user, "Сколько заплатить с голочипа?", "Оплата") as null|num
		if(!(cashmoney >= 1))
			to_chat(user, span_warning("Сумма должна быть не меньше 1 кр."))
			return
		cashmoney = round(cashmoney)
		var/seller_problem = SSeconomy.personal_account_problem(my_card?.registered_account, FALSE)
		if(seller_problem)
			to_chat(user, span_warning(seller_problem))
			return
		if(H.spend(cashmoney, FALSE))
			purchase(user, cashmoney, SSeconomy.cash_account, user)
			to_chat(user, span_notice("Оплачено [cashmoney] кр., владелец стенда получил уведомление."))
			return
		else
			to_chat(user, span_warning("На голочипе не хватает кредитов."))
			return
	if(istype(W, /obj/item/stack/spacecash))
		to_chat(user, "What is this, the 2000s? We only take card here.")
		return
	if(istype(W, /obj/item/coin))
		to_chat(user, "What is this, the 1800s? We only take card here.")
		return
	if(istype(W, /obj/item/assembly/signaler))
		var/obj/item/assembly/signaler/S = W
		if(S.secured)
			to_chat(user, "<span class='warning'>The signaler needs to be in attachable mode to add it to the paystand!</span>")
			return
		if(!my_card)
			to_chat(user, "<span class='warning'>ERROR: No identification card has been assigned to this paystand yet!</span>")
			return
		if(!signaler)
			var/cash_limit = input(user, "Enter the minimum amount of cash needed to deposit before the signaler is activated.", "Signaler Activation Threshold") as null|num
			if(cash_limit < 1)
				to_chat(user, "<span class='warning'>ERROR: Invalid amount designated.</span>")
				return
			if(cash_limit)
				S.forceMove(src)
				signaler = S
				signaler_threshold = cash_limit
				to_chat(user, "You attach the signaler to the paystand.")
				desc += " A signaler appears to be attached to the scanner."
		else
			to_chat(user, "<span class='warning'>A signaler is already attached to this unit!</span>")

	if(default_deconstruction_screwdriver(user, "card_scanner", "card_scanner", W))
		return

	else if(default_pry_open(W))
		return

	else if(default_unfasten_wrench(user, W))
		return

	else if(default_deconstruction_crowbar(W))
		return
	else
		return ..()

/obj/machinery/paystand/proc/card_payment_problem(datum/bank_account/payer)
	return SSeconomy.personal_account_problem(payer, TRUE) || SSeconomy.personal_account_problem(my_card?.registered_account, FALSE)

/obj/machinery/paystand/proc/purchase(buyer, price, datum/bank_account/payer, mob/user)
	if(!my_card?.registered_account || !SSeconomy.move(payer, my_card.registered_account, price, ECON_PURCHASE, user, "Оплата на стенде: [name]"))
		return FALSE
	my_card.registered_account.bank_card_talk("Стенд оплаты: [buyer] заплатил [price] кр.")
	amount_deposited = amount_deposited + price
	if(signaler && amount_deposited >= signaler_threshold)
		signaler.activate()
		amount_deposited = 0
	return TRUE

/obj/machinery/paystand/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	if(locked)
		to_chat(user, "<span class='warning'>The bolts on this paystand are currently covered!</span>")
		return FALSE
	. = ..()

/obj/machinery/paystand/examine(mob/user)
	. = ..()
	. += span_notice("Оплата картой или голочипом сразу уходит на личный счёт владельца стенда, без налога и без доли NT. Платить можно только с личного счёта, бюджетные карты отделов не принимаются.")
	if(force_fee)
		. += span_warning("Стенд берёт фиксированную плату: <b>[force_fee]</b> кр. за каждое касание картой.")
	if(user.get_active_held_item() == my_card)
		. += "<span class='notice'>Paystands can be edited through swiping your card with different intents. <b>Disarm</b> allows editing the name while <b>Grab</b> changes payment functionality.</span>"
