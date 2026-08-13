#define OFFER_TEXT_MAX_LINES 12

/obj/item/love_offer
	name = "ERP Ticket"
	desc = "What is ERP? You don't know.\nIt's a sex offer, yes, on paper."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "erp_ticket"
	custom_price = 5
	custom_premium_price = 25
	var/proposer_name = ""
	var/recipient_name = ""
	var/offer_text = "Ты заслуживаешь перерыва.\nПочему бы не провести его вместе\nи сделать незабываемым?"
	var/saved = FALSE

/obj/item/love_offer/examine(mob/user)
	. = ..()
	if(saved)
		. += span_love("Это предложение от [proposer_name] для [recipient_name].")

/obj/item/love_offer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LoveOffer", name)
		ui.open()

/obj/item/love_offer/ui_data(mob/user)
	return list(
		"proposer_name" = saved ? proposer_name : user.real_name,
		"recipient_name" = recipient_name,
		"offer_text" = offer_text,
		"saved" = saved,
	)

/obj/item/love_offer/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/mob/living/user = usr
	if(!user)
		return FALSE
	switch(action)
		if("set_offer_text")
			offer_text = params["offer_text"]
		if("set_recipient_name")
			var/r_name = recipient_name_check(params["recipient_name"], user)
			if(!r_name)
				return FALSE
			recipient_name = uppertext(r_name)
		if("save")
			var/lines_count = params["linesCount"]
			if(lines_count > OFFER_TEXT_MAX_LINES)
				to_chat(user, span_warning("Количество строк в предложении не должно быть больше [OFFER_TEXT_MAX_LINES]."))
				return FALSE

			if(!recipient_name_check(user = user))
				return FALSE

			proposer_name = uppertext(user.real_name)
			saved = TRUE
	return TRUE

/obj/item/love_offer/proc/recipient_name_check(text, mob/living/user)
	if(!text)
		text = recipient_name
	text = reject_bad_name(text, allow_numbers = TRUE)
	if(!text)
		to_chat(user, span_warning("Недопустимое имя получателя, длина должна составлять не менее 2 символов и не более [MAX_NAME_LEN]. Оно может содержать только символы A-Z, a-z, А-Я, а-я, -, ' и ."))
		return
	return text

#undef OFFER_TEXT_MAX_LINES
