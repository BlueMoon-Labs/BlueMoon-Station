/// Станционные прилавки в аренду, для окна казны
GLOBAL_LIST_EMPTY(econ_rental_stalls)

/obj/machinery/vending/custom
	/// Прилавок с карты станции: продаёт только в платную аренду. Собранный игроком автомат привязывается бесплатно
	var/rentable = FALSE
	/// Кто, какой картой и что начал первым свайпом: второй свайп в окно STALL_CONFIRM_WINDOW подтверждает
	var/pending_swipe_key
	var/pending_swipe_until = 0
	/// Создан не загрузчиком карты: mapload бывает TRUE и у построенного во время загрузки шаблона
	var/created_live = FALSE

/obj/machinery/vending/custom/New(loc, ...)
	created_live = SSatoms.initialized != INITIALIZATION_INSSATOMS
	return ..()

/obj/machinery/vending/custom/Initialize(mapload)
	. = ..()
	if(mapload && !created_live && is_station_level(z))
		make_rentable()

/obj/machinery/vending/custom/proc/make_rentable()
	rentable = TRUE
	GLOB.econ_rental_stalls |= src

/datum/controller/subsystem/economy/proc/can_manage_stalls(mob/living/user)
	var/datum/economy_department/command = get_department(ACCOUNT_CMD)
	return command?.can_manage(user)

/// null, если этот счёт может арендовать прилавок сейчас, иначе текст отказа.
/datum/controller/subsystem/economy/proc/check_stall_rent(obj/machinery/vending/custom/stall, datum/bank_account/renter)
	if(QDELETED(stall))
		return "Прилавок не найден."
	if(!stall.rentable)
		return "Этот автомат не сдаётся в аренду."
	if(!stall.is_operational())
		return "Прилавок обесточен или сломан."
	. = personal_account_problem(renter, TRUE)
	if(.)
		return
	if(stall.rent_active())
		return "Прилавок уже арендован до [stall.rent_end_text()]."
	if(stall.linked_account && stall.linked_account != renter && stall.loaded_items)
		return "В прилавке остались товары прежнего арендатора. Освободить его может ГП или капитан."
	if(!treasury())
		return "Казна станции недоступна."
	if(!renter.has_money(settings.stall_rent_fee))
		return "Недостаточно средств: аренда стоит [settings.stall_rent_fee] кр."
	return null

/// Аренда станционного прилавка: плата в казну, выручка арендатору до конца срока. Возвращает null или текст отказа.
/datum/controller/subsystem/economy/proc/rent_stall(obj/machinery/vending/custom/stall, datum/bank_account/renter, mob/user)
	. = check_stall_rent(stall, renter)
	if(.)
		return
	var/fee = settings.stall_rent_fee
	if(fee && !move(renter, treasury(), fee, ECON_RENT, user, "Аренда прилавка: [stall.name]"))
		return "Оплата аренды не прошла."
	stall.set_renter(renter, world.time + settings.stall_rent_minutes MINUTES)
	log_econ("[renter.account_holder] арендовал [stall] ([AREACOORD(stall)]) на [settings.stall_rent_minutes] мин. за [fee] кр.[user ? " ([key_name(user)])" : ""]")
	return null

/datum/controller/subsystem/economy/proc/check_stall_evict(obj/machinery/vending/custom/stall, mob/living/user)
	if(!stall.rentable)
		return "Этот автомат не сдаётся в аренду."
	if(!can_manage_stalls(user))
		return "Освободить прилавок может только ГП или капитан."
	if(stall.rent_active())
		return "Аренда ещё идёт, до [stall.rent_end_text()]."
	if(!stall.linked_account)
		return "Прилавок и так свободен."
	return null

/// Освободить прилавок после конца аренды: товар выпадает наружу. Возвращает null или текст отказа.
/datum/controller/subsystem/economy/proc/evict_stall(obj/machinery/vending/custom/stall, mob/living/user)
	. = check_stall_evict(stall, user)
	if(.)
		return
	log_econ("[key_name(user)] освободил прилавок [stall] ([AREACOORD(stall)]) арендатора [stall.linked_account.account_holder], товаров: [stall.loaded_items]")
	stall.drop_goods()
	stall.set_renter(null, 0)
	return null

/obj/machinery/vending/custom/proc/rent_active()
	return rentable && linked_account && rented_until > world.time

/obj/machinery/vending/custom/proc/can_sell()
	return linked_account && (!rentable || rented_until > world.time)

/obj/machinery/vending/custom/proc/rent_end_text()
	return STATION_TIME_TIMESTAMP("hh:mm", rented_until)

/obj/machinery/vending/custom/proc/set_renter(datum/bank_account/renter, until)
	if(linked_account && linked_account != renter)
		UnregisterSignal(linked_account, COMSIG_PARENT_QDELETING)
	if(renter && renter != linked_account)
		RegisterSignal(renter, COMSIG_PARENT_QDELETING, PROC_REF(on_renter_deleted))
	linked_account = renter
	rented_until = until
	pending_swipe_key = null

/obj/machinery/vending/custom/proc/on_renter_deleted(datum/source)
	SIGNAL_HANDLER
	drop_goods()
	set_renter(null, 0)

/obj/machinery/vending/custom/proc/drop_goods()
	var/atom/drop_spot = drop_location()
	for(var/obj/item/goods in contents)
		if(goods == circuit || (goods in component_parts))
			continue
		goods.forceMove(drop_spot)
	vending_machine_input.Cut()
	loaded_items = 0

/// Собранный игроком автомат бесплатно привязывается к первому личному счёту.
/obj/machinery/vending/custom/proc/claim_free(datum/bank_account/account)
	var/problem = SSeconomy.personal_account_problem(account, FALSE)
	if(problem)
		say("Автомат не привязан: [problem]")
		return
	set_renter(account, 0)
	say("Автомат привязан к счёту [account.account_holder]: выручка пойдёт на него.")

/// Свайп ID-карты. Станционный прилавок: первый свайп называет условия, второй в окне подтверждает аренду или, для ГП и капитана, освобождение. Собранный автомат: бесплатная привязка.
/obj/machinery/vending/custom/proc/stall_swipe(mob/living/user, obj/item/card/id/card)
	var/datum/bank_account/account = card.registered_account
	if(!rentable)
		if(!linked_account)
			claim_free(account)
		else
			say("Автомат привязан к счёту [linked_account.account_holder].")
		return
	if(rent_active())
		if(account && account == linked_account)
			say("Прилавок арендован вами до [rent_end_text()]. Продлить аренду можно, когда она закончится.")
		else
			say("Прилавок арендован до [rent_end_text()].")
		return
	var/evict = linked_account && linked_account != account && loaded_items && SSeconomy.can_manage_stalls(user)
	var/problem = evict ? SSeconomy.check_stall_evict(src, user) : SSeconomy.check_stall_rent(src, account)
	if(problem)
		pending_swipe_key = null
		say(problem)
		return
	var/swipe_key = "[REF(user)]:[account?.account_id]:[evict]"
	if(pending_swipe_key != swipe_key || world.time > pending_swipe_until)
		pending_swipe_key = swipe_key
		pending_swipe_until = world.time + STALL_CONFIRM_WINDOW
		if(evict)
			say("Аренда [linked_account.account_holder] закончилась. Проведите картой ещё раз, чтобы освободить прилавок: товары выпадут наружу.")
		else
			say("Аренда на [SSeconomy.settings.stall_rent_minutes] мин. стоит [SSeconomy.settings.stall_rent_fee] кр. со счёта [account.account_holder], плата идёт в казну станции. Проведите этой картой ещё раз, чтобы подтвердить.")
		return
	pending_swipe_key = null
	problem = evict ? SSeconomy.evict_stall(src, user) : SSeconomy.rent_stall(src, account, user)
	if(problem)
		say(problem)
		return
	playsound(src, 'sound/machines/ping.ogg', 40, TRUE)
	if(evict)
		say("Прилавок освобождён.")
	else
		say("Прилавок арендован до [rent_end_text()]. Выручка пойдёт на счёт [account.account_holder].")

/obj/machinery/vending/custom/proc/rent_examine()
	. = list()
	if(!rentable)
		if(linked_account)
			. += span_notice("Собранный автомат привязан к счёту [linked_account.account_holder], выручка идёт на него без налога.")
		else
			. += span_notice("Собранный автомат ни к кому не привязан: проведите по нему ID-картой с личным счётом, чтобы бесплатно привязать его к себе.")
		. += span_notice("Покупать и получать выручку можно только личными счетами, бюджетные карты отделов не принимаются.")
		return
	if(rent_active())
		. += span_notice("Прилавок арендует [linked_account.account_holder] до [rent_end_text()]. Выручка идёт на счёт арендатора без налога.")
	else if(linked_account)
		. += span_warning("Аренда [linked_account.account_holder] закончилась, продажи закрыты. Арендатор может забрать свои товары или продлить аренду. Если товары остались внутри, ГП или капитан могут освободить прилавок двумя свайпами карты - товары выпадут наружу.")
	else
		. += span_notice("Прилавок свободен.")
	. += span_notice("Это станционный прилавок: он продаёт только в аренду. Аренда - [SSeconomy.settings.stall_rent_fee] кр. на [SSeconomy.settings.stall_rent_minutes] мин., плата идёт в казну станции. Чтобы арендовать, проведите ID-картой дважды. Покупать и получать выручку можно только личными счетами.")
