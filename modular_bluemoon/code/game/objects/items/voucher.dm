// если кто-то захочет - да это было сделано с мыслью возможности перенести и шахтёрские воучеры на это
/obj/item/card/voucher_blank
	name = "Prescription voucher"
	desc = "Токен для получения специализированных вещей. Впрочем конкретно этот производит процесс самозаписи и его скоро можно будет использовать."
	icon_state = "data_2"

/obj/item/card/voucher_blank/proc/handle_registration(mob/living/carbon/human/user, base_price, base_valid_traits, base_fortune_delivery, received_product, NVD_price, NVD_suspicious)
	if(isnull(src))
		return
	if(isnull(user))
		playsound(src, 'sound/machines/terminal_error.ogg', 30)
	else
		playsound(src, 'sound/machines/ping.ogg', 30)

	var/counterfeit = TRUE
	for(var/quirk in base_valid_traits)
		if(HAS_TRAIT(user, quirk))
			counterfeit = FALSE
			break

	var/used_loc = loc
	if(ishuman(loc))
		used_loc = get_turf(loc)
	if(!counterfeit && prob(base_fortune_delivery))
		say("Благодарим за оформление подписки на мгновенную доставку товаров, производится процесс телепортации.")
		new received_product(used_loc)
		qdel(src)
		return

	var/used_price = counterfeit ? NVD_price : base_price
	new /obj/item/card/voucher(used_loc, received_product, used_price, counterfeit ? NVD_suspicious : FALSE)
	qdel(src)

/obj/item/card/voucher
	name = "Prescription voucher"
	desc = "Токен для получения THING. Используйте в VENDOR. Стоимость приобретения составит PRICE кредитов."
	icon_state = "data_2"
	var/detail_color = CIRCUIT_COLOR_MEDICAL // цвет карточки
	var/obj/item/redeem_path = /obj/item/storage/pill_bottle // выдаваемый товар
	var/redeem_price = PRICE_NORMAL // цена товара
	var/counterfeit = FALSE // при TRUE на использовавшего такой рецепт навесится штраф за подделку документов
	var/obj/machinery/vending/vendor = /obj/machinery/vending/medical // вендомат для выдачи

/obj/item/card/voucher/Initialize(mapload, new_redeem_path, new_price, suspicious)
	. = ..()
	if(new_redeem_path)
		redeem_path = new_redeem_path
	if(new_price)
		redeem_price = new_price
	if(suspicious && prob(suspicious))
		counterfeit = TRUE
	desc = replacetext(desc, "THING", redeem_path::name)
	desc = replacetext(desc, "VENDOR", vendor::name)
	desc = replacetext(desc, "PRICE", redeem_price)
	update_icon()

/obj/item/card/voucher/update_overlays()
	. = ..()
	var/mutable_appearance/detail_overlay = mutable_appearance('icons/obj/card.dmi', "[icon_state]-color", color = detail_color)
	. += detail_overlay

/obj/item/card/voucher/attack_obj(obj/O, mob/living/carbon/human/user)
	if(!istype(O, vendor) || !istype(user))
		return ..()

	var/obj/machinery/vending/vend = O
	if(!vend.is_operational())
		to_chat(user, span_warning("Вы патетесь использовать воучер, но [vend.name] сейчас не принимает его."))
		return DISCARD_LAST_ACTION
	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C)
		vend.say("ID-карты не обнаружено.")
		flick(vend.icon_deny, vend)
		return DISCARD_LAST_ACTION
	if(!C.registered_account)
		vend.say("Банковского аккаунта не обнаружено.")
		flick(vend.icon_deny, vend)
		return DISCARD_LAST_ACTION
	var/datum/bank_account/account = C.registered_account

	if(redeem_price)
		if((!account.has_money(redeem_price) || account.state == ACCOUNT_FROZEN))
			vend.say(account?.state == ACCOUNT_FROZEN ? "Счёт заморожен финансовым аудитом, обналичивания воучера." : "Недостаточно средств для обналичивания воучера.")
			flick(vend.icon_deny, vend)
			return DISCARD_LAST_ACTION
		var/redeem_name = redeem_path::name // не переломается, таких воучеров ну максимум 30 раз используют за раунд
		var/datum/bank_account/owner = SSeconomy.get_dep_account(vend.payment_department)
		var/wholesale = owner ? round(redeem_price * SSeconomy.settings.vend_premium_sink_share / 100) : redeem_price
		var/memo = "Покупка: [redeem_name]"
		if(owner && owner != account)
			SSeconomy.move(account, owner, redeem_price - wholesale, ECON_VEND, usr, memo)
		account.debit(wholesale, ECON_VEND_WHOLESALE, usr, memo)
		SSblackbox.record_feedback("amount", "vending_spent", redeem_price)
		//SSeconomy.track_purchase(account, price_to_use, name)
		log_econ("[redeem_price] credits were inserted into [vend] by [account?.account_holder] to buy [redeem_name].")

	vend.say("Благодарим вас за обналичивание воучера у [vend.name]!")
	vend.use_power(vend.active_power_usage)
	if(vend.icon_vend) //Show the vending animation if needed
		flick(vend.icon_vend, vend)
	playsound(vend, vend.vending_sound, 50, TRUE, extrarange = -3)
	var/obj/item/vended_item = new redeem_path(vend.loc)
	SSblackbox.record_feedback("nested tally", "vending_machine_voucher_usage", 1, list("[vend.type]", "[redeem_path]"))
	qdel(src)

	if(counterfeit)
		var/datum/data/record/target_records = GLOB.data_core.security_by_name[user.name]
		if(!target_records)
			return
		target_records.fields["criminal"] = SEC_RECORD_STATUS_ARREST
		user.sec_hud_set_security_status()
		var/crime = GLOB.data_core.createCrimeEntry(204, "Применение фальсифицированного воучера для приобретения [vended_item.name]", "AUTO", STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), TRUE)
		GLOB.data_core.addMinorCrime(target_records.fields["id"], crime)
