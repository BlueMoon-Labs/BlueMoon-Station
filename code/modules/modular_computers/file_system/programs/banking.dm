/**
 * NT Pay — ПДА банковская система
 */
/datum/computer_file/program/banking
	filename = "ntpay"
	filedesc = "NT Pay"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "generic"
	extended_desc = "Nanotrasen Pay — управляйте своим метадолларовым счётом, снимайте и пополняйте M$."
	requires_ntnet = FALSE
	transfer_access = null
	usage_flags = PROGRAM_PDA
	size = 6
	tgui_id = "NtosBanking"
	program_icon = "money-bill-wave"

/datum/computer_file/program/banking/ui_data(mob/user)
	var/list/data = get_header_data()

	var/balance = 0
	var/has_account = FALSE
	if(user?.client?.prefs)
		balance = user.client.prefs.metadollars
		has_account = TRUE

	data["has_account"] = has_account
	data["balance"] = balance
	data["currency"] = "M$"

	return data

/datum/computer_file/program/banking/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/living/user = usr
	if(!istype(user))
		return FALSE

	var/client/C = user.client
	if(!C?.prefs)
		to_chat(user, span_warning("Unable to access your metadollar account. No client connection."))
		return FALSE

	switch(action)
		if("withdraw")
			var/amount = text2num(params["amount"])
			if(!amount || amount <= 0)
				return FALSE
			amount = round(amount)
			if(C.prefs.metadollars < amount)
				to_chat(user, span_warning("Insufficient metadollars. Balance: [C.prefs.metadollars] M$."))
				return FALSE
			C.prefs.metadollars -= amount
			C.prefs.save_preferences()
			var/obj/item/stack/metadollar/MD = new(user.drop_location(), amount)
			user.put_in_hands(MD)
			log_admin("METADOLLAR: [user.real_name] ([C.ckey]) withdrew [amount] M$ via PDA. Balance: [C.prefs.metadollars] M$.")
			return TRUE

		if("deposit")
			var/obj/item/held = user.get_active_held_item()
			if(!held)
				to_chat(user, span_warning("Hold a metadollar stack in your active hand to deposit."))
				return FALSE
			if(!istype(held, /obj/item/stack/metadollar))
				to_chat(user, span_warning("[held] is not a metadollar stack."))
				return FALSE
			var/obj/item/stack/metadollar/MD = held
			var/amount = MD.amount
			if(amount <= 0)
				to_chat(user, span_warning("[MD] has no metadollars."))
				return FALSE
			C.prefs.metadollars += amount
			C.prefs.save_preferences()
			log_admin("METADOLLAR: [user.real_name] ([C.ckey]) deposited [amount] M$ via PDA. Balance: [C.prefs.metadollars] M$.")
			qdel(MD)
			return TRUE
