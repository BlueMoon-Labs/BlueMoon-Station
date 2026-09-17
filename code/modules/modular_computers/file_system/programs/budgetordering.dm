/datum/computer_file/program/budgetorders
	filename = "orderapp"
	filedesc = "NT IRN"
	category = PROGRAM_CATEGORY_SUPL
	program_icon_state = "request"
	extended_desc = "Nanotrasen Internal Requisition Network interface for supply purchasing using a department budget account."
	requires_ntnet = TRUE
	size = 20
	tgui_id = "NtosCargo"
	available_on_ntnet = FALSE
	///Are you actually placing orders with it?
	var/requestonly = TRUE
	///Can the tablet see or buy illegal stuff?
	var/contraband = FALSE
	///Is it being bought from a personal account, or is it being done via a budget/cargo?
	var/self_paid = FALSE
	///Can this console approve purchase requests?
	var/can_approve_requests = FALSE
	///What do we say when the shuttle moves with living beings on it.
	var/safety_warning = "For safety and ethical reasons, the automated supply shuttle \
		cannot transport live organisms, human remains, classified nuclear weaponry, mail, \
		homing beacons, unstable eigenstates or machinery housing any form of artificial intelligence."
	///If you're being raided by pirates, what do you tell the crew?
	var/blockade_warning = "Bluespace instability detected. Shuttle movement impossible."
	///The name of the shuttle template being used as the cargo shuttle. 'supply' is default and contains critical code. Don't change this unless you know what you're doing.
	var/cargo_shuttle = "supply"
	///The docking port called when returning to the station.
	var/docking_home = "supply_home"
	///The docking port called when leaving the station.
	var/docking_away = "supply_away"
	///If this console can loan the cargo shuttle. Set to false to disable.
	var/stationcargo = TRUE
	///The account this console processes and displays. Independent from the account the shuttle processes.
	var/cargo_account = ACCOUNT_CAR
	// BLUEMOON ADD - очередь ленивых обновлений каталога (иконки/содержимое) для нового UI
	var/list/queued_inventory_updates = list()

/datum/computer_file/program/budgetorders/proc/get_export_categories()
	. = EXPORT_CARGO

/datum/computer_file/program/budgetorders/run_emag()
	if(!contraband)
		contraband = TRUE
		return TRUE

/datum/computer_file/program/budgetorders/proc/is_visible_pack(mob/user, paccess_to_check, list/access, contraband)
	if(issilicon(user)) //Borgs can't buy things.
		return FALSE
	if(computer.obj_flags & EMAGGED)
		return TRUE
	else if(contraband) //Hide contrband when non-emagged.
		return FALSE
	if(!paccess_to_check) // No required_access, allow it.
		return TRUE
	if(IsAdminGhost(user))
		return TRUE

	//Aquire access from the inserted ID card.
	if(!length(access))
		var/obj/item/card/id/D
		var/obj/item/computer_hardware/card_slot/card_slot
		if(computer)
			card_slot = computer.all_components[MC_CARD]
			D = card_slot?.GetID()
		if(!D)
			return FALSE
		access = D.GetAccess()

	if(paccess_to_check in access)
		return TRUE

	return FALSE

/datum/computer_file/program/budgetorders/ui_data()
	. = ..()
	var/list/data = get_header_data()
	data["location"] = SSshuttle.supply.getStatusText()
	var/datum/bank_account/buyer = SSeconomy.get_dep_account(cargo_account)
	var/obj/item/computer_hardware/card_slot/card_slot = computer.all_components[MC_CARD]
	var/obj/item/card/id/id_card = card_slot?.GetID()
	if(id_card?.registered_account)
		if((ACCESS_HEADS in id_card.access) || (ACCESS_QM in id_card.access))
			requestonly = FALSE
			var/datum/job/pay_job = id_card.registered_account.account_job
			if(pay_job)
				buyer = SSeconomy.get_dep_account(pay_job.paycheck_department)
			can_approve_requests = TRUE
		else
			requestonly = TRUE
			can_approve_requests = FALSE
	else
		requestonly = TRUE
	if(buyer)
		data["points"] = buyer.account_balance

//Otherwise static data, that is being applied in ui_data as the crates visible and buyable are not static, and are determined by inserted ID.
	data["requestonly"] = requestonly
	data["department"] = "Cargo" // BLUEMOON ADD - контракт нового UI
	data["grocery"] = 0 // BLUEMOON ADD - системы кухонных поставок в этом билде нет
	data["max_order"] = CARGO_MAX_ORDER // BLUEMOON ADD
	data["supplies"] = list()
	for(var/pack in SSshuttle.supply_packs)
		var/datum/supply_pack/P = SSshuttle.supply_packs[pack]
		if(!is_visible_pack(usr, P.access , null, P.contraband) || P.hidden)
			continue
		if(!data["supplies"][P.group])
			data["supplies"][P.group] = list(
				"name" = P.group,
				"packs" = list()
			)
		if((P.hidden && (P.contraband && !contraband) || (P.special && !P.special_enabled) || P.DropPodOnly))
			continue
		data["supplies"][P.group]["packs"] += list(list(
			"name" = P.name,
			"cost" = P.get_cost(),
			"id" = pack,
			"desc" = P.desc || P.name, // If there is a description, use it. Otherwise use the pack's name.
			"goody" = P.goody,
			"access" = P.access
		))

//Data regarding the User's capability to buy things.
	data["has_id"] = id_card
	data["away"] = SSshuttle.supply.getDockedId() == docking_away
	data["self_paid"] = self_paid
	data["docked"] = SSshuttle.supply.mode == SHUTTLE_IDLE
	data["loan"] = !!SSshuttle.shuttle_loan
	data["loan_dispatched"] = SSshuttle.shuttle_loan && SSshuttle.shuttle_loan.dispatched
	data["can_send"] = FALSE //There is no situation where I want the app to be able to send the shuttle AWAY from the station, but conversely is fine.
	data["can_approve_requests"] = can_approve_requests
	data["app_cost"] = TRUE
	var/message = "Remember to stamp and send back the supply manifests."
	if(SSshuttle.centcom_message)
		message = SSshuttle.centcom_message
	if(SSshuttle.supplyBlocked)
		message = blockade_warning
	data["message"] = message
	// BLUEMOON ADD START - агрегированная корзина и количество заказов по именам (контракт нового UI)
	data["amount_by_name"] = list()
	var/list/cart_list = list()
	for(var/datum/supply_order/SO in SSshuttle.shoppinglist)
		var/entry = cart_list[SO.pack.name]
		if(entry)
			data["amount_by_name"][SO.pack.name] += 1
			entry[1]["amount"]++
			entry[1]["cost"] += SO.pack.get_cost()
			if(!isnull(SO.paying_account))
				entry[1]["paid"]++
			continue

		data["amount_by_name"][SO.pack.name] += 1
		cart_list[SO.pack.name] = list(list(
			"cost_type" = "",
			"object" = SO.pack.name,
			"cost" = SO.pack.get_cost(),
			"id" = SO.id,
			"amount" = 1,
			"orderer" = SO.orderer,
			"paid" = !isnull(SO.paying_account) ? 1 : 0, // количество заказов, оплаченных с личного/ведомственного счёта
			"dep_order" = 0, // ведомственные заказы в этом билде не отслеживаются
			"can_be_cancelled" = 1,
		))
	data["cart"] = list()
	for(var/item_id in cart_list)
		data["cart"] += cart_list[item_id]
	// BLUEMOON ADD END

	data["requests"] = list()
	for(var/datum/supply_order/SO in SSshuttle.requestlist)
		var/datum/supply_pack/pack = SO.pack
		data["amount_by_name"][pack.name] += 1 // BLUEMOON ADD
		data["requests"] += list(list(
			"object" = pack.name,
			"cost" = pack.get_cost(),
			"orderer" = SO.orderer,
			"reason" = SO.reason,
			"id" = SO.id
		))

	// BLUEMOON ADD - отдаём запрошенные новым UI иконки/содержимое каталога одним разом
	if(length(queued_inventory_updates))
		data["inventory_updates"] = queued_inventory_updates
		queued_inventory_updates = list()
	// BLUEMOON ADD END

	return data

/datum/computer_file/program/budgetorders/ui_act(action, params, datum/tgui/ui)
	if(..())
		return
	var/obj/item/computer_hardware/card_slot/card_slot = computer.all_components[MC_CARD]
	switch(action)
		if("send")
			if(!SSshuttle.supply.canMove())
				computer.say(safety_warning)
				return
			if(SSshuttle.supplyBlocked)
				computer.say(blockade_warning)
				return
			if(SSshuttle.supply.getDockedId() == docking_home)
				SSshuttle.supply.export_categories = get_export_categories()
				SSshuttle.moveShuttle(cargo_shuttle, docking_away, TRUE)
				computer.say("The supply shuttle is departing.")
				computer.investigate_log("[key_name(usr)] sent the supply shuttle away.", INVESTIGATE_CARGO)
			else
				computer.investigate_log("[key_name(usr)] called the supply shuttle.", INVESTIGATE_CARGO)
				computer.say("The supply shuttle has been called and will arrive in [SSshuttle.supply.timeLeft(600)] minutes.")
				SSshuttle.moveShuttle(cargo_shuttle, docking_home, TRUE)
			. = TRUE
		if("loan")
			if(!SSshuttle.shuttle_loan)
				return
			if(SSshuttle.supplyBlocked)
				computer.say(blockade_warning)
				return
			else if(SSshuttle.supply.mode != SHUTTLE_IDLE)
				return
			else if(SSshuttle.supply.getDockedId() != docking_away)
				return
			else if(stationcargo != TRUE)
				return
			else
				SSshuttle.shuttle_loan.loan_shuttle()
				computer.say("The supply shuttle has been loaned to CentCom.")
				computer.investigate_log("[key_name(usr)] accepted a shuttle loan event.", INVESTIGATE_CARGO)
				log_game("[key_name(usr)] accepted a shuttle loan event.")
				. = TRUE
		if("add")
			var/amount = text2num(params["amount"])
			if(amount < 1)
				amount = 1
			return add_orders(usr, params["id"], clamp(amount, 1, CARGO_MAX_ORDER))
		// BLUEMOON ADD START - действия нового UI
		if("add_by_name")
			var/supply_pack_id = name_to_id(params["order_name"])
			if(!supply_pack_id)
				return
			return add_orders(usr, supply_pack_id, 1)
		if("modify")
			var/order_name = params["order_name"]
			// снимаем все текущие заказы с этим именем, чтобы освободить место под новое количество
			for(var/datum/supply_order/SO in SSshuttle.shoppinglist)
				if(SO.pack.name == order_name)
					remove_item(SO.id)
			var/amount = text2num(params["amount"])
			if(amount == 0)
				return TRUE
			if(amount > CARGO_MAX_ORDER)
				return
			var/supply_pack_id = name_to_id(order_name)
			if(!supply_pack_id)
				return
			return add_orders(usr, supply_pack_id, amount)
		// BLUEMOON ADD END
		if("remove")
			var/order_name = params["order_name"] // BLUEMOON ADD - удаление по имени для нового UI
			if(order_name)
				// пытаемся снять хотя бы один заказ с указанным именем
				for(var/datum/supply_order/SO in SSshuttle.shoppinglist)
					if(SO.pack.name != order_name)
						continue
					if(remove_item(SO.id))
						break
				. = TRUE
			else
				var/id = text2num(params["id"])
				. = remove_item(id)
		if("clear")
			SSshuttle.shoppinglist.Cut()
			. = TRUE
		if("approve")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSshuttle.requestlist)
				if(SO.id == id)
					var/obj/item/card/id/id_card = card_slot?.GetID()
					if(id_card && id_card?.registered_account)
						SO.paying_account = SSeconomy.get_dep_account(id_card?.registered_account?.account_job.paycheck_department)
					SSshuttle.requestlist -= SO
					SSshuttle.shoppinglist += SO
					. = TRUE
					break
		if("deny")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSshuttle.requestlist)
				if(SO.id == id)
					SSshuttle.requestlist -= SO
					. = TRUE
					break
		if("denyall")
			SSshuttle.requestlist.Cut()
			. = TRUE
		if("toggleprivate")
			self_paid = !self_paid
			. = TRUE
		if("get_inventory") // BLUEMOON ADD - ленивая загрузка иконок/содержимого каталога
			. = TRUE
			for(var/pack_id in params["ids"])
				if(!queued_inventory_updates[pack_id])
					queued_inventory_updates[pack_id] = get_cargo_pack_inventory_data(pack_id)
	if(.)
		post_signal(cargo_shuttle)

/**
 * BLUEMOON ADD START
 * Размещает один или несколько заказов на паки. Используется как старым UI (add), так и новым (add_by_name/modify).
 */
/datum/computer_file/program/budgetorders/proc/add_orders(mob/user, id, amount = 1)
	var/supply_pack_id = text2path(id) || id
	var/datum/supply_pack/pack = SSshuttle.supply_packs[supply_pack_id]
	if(!istype(pack))
		return
	if((pack.hidden && (pack.contraband && !contraband)) || pack.DropPodOnly)
		return

	var/obj/item/computer_hardware/card_slot/card_slot = computer.all_components[MC_CARD]
	var/name = "*None Provided*"
	var/rank = "*None Provided*"
	var/ckey = user.ckey
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		name = H.get_authentification_name()
		rank = H.get_assignment(hand_first = TRUE)
	else if(issilicon(user))
		name = user.real_name
		rank = "Silicon"

	var/datum/bank_account/account
	if(self_paid)
		var/mob/living/carbon/human/H = user
		var/obj/item/card/id/id_card = H.get_idcard(TRUE)
		if(!istype(id_card))
			computer.say("No ID card detected.")
			return
		if(istype(id_card, /obj/item/card/id/departmental_budget))
			computer.say("The [src] rejects [id_card].")
			return
		account = id_card.registered_account
		if(!istype(account))
			computer.say("Invalid bank account.")
			return

	var/reason = ""
	if((requestonly && !self_paid) || !(card_slot?.GetID()))
		reason = stripped_input("Reason:", name, "")
		if(isnull(reason))
			return

	if(pack.goody && !self_paid)
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, FALSE)
		computer.say("ERROR: Small crates may only be purchased by private accounts.")
		return

	if(!self_paid && ishuman(user) && !account)
		var/obj/item/card/id/id_card = card_slot?.GetID()
		var/datum/job/order_job = id_card?.registered_account?.account_job
		if(order_job)
			account = SSeconomy.get_dep_account(order_job.paycheck_department)

	for(var/count in 1 to amount)
		var/turf/T = get_turf(src)
		var/datum/supply_order/SO = new(pack, name, rank, ckey, reason, account)
		SO.generateRequisition(T)
		if((requestonly && !self_paid) || !(card_slot?.GetID()))
			SSshuttle.requestlist += SO
		else
			SSshuttle.shoppinglist += SO
			if(self_paid)
				computer.say("Order processed. The price will be charged to [account.account_holder]'s bank account on delivery.")
	post_signal(cargo_shuttle)
	return TRUE

/**
 * Снимает заказ с корзины по его id. Возвращает TRUE, если такой заказ был найден и снят.
 */
/datum/computer_file/program/budgetorders/proc/remove_item(id)
	for(var/datum/supply_order/SO in SSshuttle.shoppinglist)
		if(SO.id != id)
			continue
		SSshuttle.shoppinglist -= SO
		return TRUE
	return FALSE

/**
 * Сопоставляет имя заказа, отображаемое в UI, с id пака в списке supply_packs.
 */
/datum/computer_file/program/budgetorders/proc/name_to_id(order_name)
	for(var/pack in SSshuttle.supply_packs)
		var/datum/supply_pack/supply = SSshuttle.supply_packs[pack]
		if(order_name == supply.name)
			return pack
	return null
// BLUEMOON ADD END

/datum/computer_file/program/budgetorders/proc/post_signal(command)

	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)

	if(!frequency)
		return

	var/datum/signal/status_signal = new(list("command" = command))
	frequency.post_signal(src, status_signal)
