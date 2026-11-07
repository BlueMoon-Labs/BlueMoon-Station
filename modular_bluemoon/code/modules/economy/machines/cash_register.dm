#define REGISTER_DRAWER_SOUND_COOLDOWN (3 SECONDS)
#define REGISTER_FEEDBACK_COOLDOWN (1 SECONDS)

GLOBAL_LIST_INIT(econ_register_chings, list(
	'sound/economy/register_ching1.ogg',
	'sound/economy/register_ching2.ogg',
	'sound/economy/register_ching3.ogg',
))

/obj/machinery/cash_register
	name = "cash register"
	desc = "Касса заведения. Кассир встаёт за неё своей ID-картой и составляет меню, клиент оплачивает выбранную позицию картой и может оставить чаевые. Платить необязательно: NT и так оплачивает отделу его работу."
	icon = 'icons/obj/machines/economy/cash_register.dmi'
	icon_state = "universal_off"
	density = FALSE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/cash_register
	var/skin = "universal"
	var/skin_name = "универсальный"
	/// Позиции меню: list("id", "name", "price")
	var/list/menu = list()
	var/datum/bank_account/cashier_account
	var/datum/weakref/cashier_ref
	var/cashier_name
	var/selected = 0
	var/selected_at = 0
	var/total_sales = 0
	/// Растёт при каждой смене кассира: оплата из окна проходит только тому, кого видел клиент
	var/cashier_session = 0
	var/next_item_id = 0
	/// Номер счёта -> последняя оплата с него, ещё без распечатанного чека: list("item", "price", "cashier", "time")
	var/list/receipts = list()
	COOLDOWN_DECLARE(drawer_cooldown)
	COOLDOWN_DECLARE(feedback_cooldown)

/obj/machinery/cash_register/bar
	icon_state = "bar_off"
	skin = "bar"
	skin_name = "бар"

/obj/machinery/cash_register/kitchen
	icon_state = "kitchen_off"
	skin = "kitchen"
	skin_name = "кухня"

/obj/machinery/cash_register/clinic
	icon_state = "clinic_off"
	skin = "clinic"
	skin_name = "клиника"

/obj/machinery/cash_register/Initialize(mapload)
	. = ..()
	if(istype(circuit))
		circuit.build_path = type
	update_appearance()

/obj/machinery/cash_register/update_icon_state()
	if(panel_open)
		icon_state = "[skin]_panel"
	else if(!cashier_account || (machine_stat & BROKEN))
		icon_state = "[skin]_off"
	else
		icon_state = skin
	return ..()

/obj/machinery/cash_register/Destroy()
	cashier_account = null
	cashier_ref = null
	return ..()

/obj/machinery/cash_register/examine(mob/user)
	. = ..()
	if(!cashier_account)
		. += span_notice("Касса свободна, экран погашен: проведите своей ID-картой, чтобы встать за неё.")
	else
		var/datum/economy_department/department = SSeconomy.get_department(cashier_account.department_id)
		if(department?.account)
			. += span_notice("За кассой [cashier_name]. Выручка: [department.register_cashier_share]% кассиру, [100 - department.register_cashier_share]% в бюджет отдела \"[department.name]\", долю задаёт глава отдела.")
		else
			. += span_notice("За кассой [cashier_name], выручка целиком ему.")
	. += span_notice("Оплата - свайпом карты или рукой по кассе, там же чаевые кассиру и чек последней оплаты. Только с личного счёта, без налога.")
	if(is_cashier(user))
		. += span_notice("Цена позиции от 1 до [REGISTER_PRICE_MAX] кр., в меню до [REGISTER_MENU_MAX] позиций. Свайп своей картой - отойти от кассы.")
	if(!user.Adjacent(src))
		return
	for(var/index in 1 to length(menu))
		var/list/item = menu[index]
		. += span_notice("[index == selected ? "К оплате: " : ""][item["name"]] - [item["price"]] кр.")

/// Почему оплата не пройдёт: текст для клиента или null.
/obj/machinery/cash_register/proc/charge_problem(datum/bank_account/payer)
	if(!cashier_account || !selected)
		return "Кассир ещё не выбрал позицию к оплате."
	if(SSeconomy.personal_account_problem(cashier_account, TRUE))
		return "Счёт кассира заморожен или заблокирован, касса оплату не принимает."
	. = SSeconomy.personal_account_problem(payer, TRUE)
	if(.)
		return
	if(payer == cashier_account)
		return "Нельзя платить самому себе."
	var/list/item = menu[selected]
	if(!payer.has_money(item["price"]))
		return "Недостаточно средств: на счёте [payer.account_balance] кр."

/obj/machinery/cash_register/proc/is_cashier(mob/user)
	return cashier_account && econ_account_of(user) == cashier_account

/obj/machinery/cash_register/proc/cashier_present()
	var/mob/living/cashier = cashier_ref?.resolve()
	var/turf/cashier_turf = get_turf(cashier)
	var/turf/register_turf = get_turf(src)
	if(!cashier_turf || !register_turf || cashier.stat == DEAD || cashier_turf.z != register_turf.z)
		return FALSE
	return get_dist(register_turf, cashier_turf) <= REGISTER_CASHIER_RANGE && is_cashier(cashier)

/obj/machinery/cash_register/proc/payment_line()
	var/list/item = menu[selected]
	return "[item["name"]] - [item["price"]] кр., получатель: [cashier_name]"

/// Встать за кассу можно только своей картой и только когда прежний кассир ушёл.
/obj/machinery/cash_register/proc/login(mob/living/user, obj/item/card/id/card)
	var/datum/bank_account/account = econ_account_of(user)
	if(SSeconomy.personal_account_problem(account, TRUE) || (card && card.registered_account != account))
		return FALSE
	if(cashier_account && cashier_present())
		return FALSE
	var/new_name = card?.registered_name || user.name
	if(cashier_account && cashier_account != account)
		cashier_account.bank_card_talk("Кассу \"[name]\" заняли: за ней теперь [new_name].")
	cashier_account = account
	cashier_ref = WEAKREF(user)
	cashier_name = new_name
	cashier_session++
	selected = 0
	update_appearance()
	open_drawer()
	log_econ("[key_name(user)] встал за кассу [src] в [AREACOORD(src)]")
	return TRUE

/obj/machinery/cash_register/proc/open_drawer()
	if(!COOLDOWN_FINISHED(src, drawer_cooldown))
		return
	COOLDOWN_START(src, drawer_cooldown, REGISTER_DRAWER_SOUND_COOLDOWN)
	flick("[skin]_open", src)
	playsound(src, 'sound/economy/register_drawer.ogg', 35, TRUE)

/obj/machinery/cash_register/proc/logout(mob/user)
	if(!is_cashier(user))
		return FALSE
	cashier_account = null
	cashier_ref = null
	cashier_name = null
	selected = 0
	update_appearance()
	return TRUE

/obj/machinery/cash_register/proc/add_item(item_name, price, mob/user)
	if(!is_cashier(user) || length(menu) >= REGISTER_MENU_MAX || !istext(item_name) || !isnum(price))
		return FALSE
	item_name = reject_bad_text(item_name, MAX_NAME_LEN, ascii_only = FALSE)
	price = round(price)
	if(!item_name || price < 1 || price > REGISTER_PRICE_MAX)
		return FALSE
	menu += list(list("id" = ++next_item_id, "name" = trim(item_name), "price" = price))
	return TRUE

/obj/machinery/cash_register/proc/remove_item(index, mob/user)
	if(!is_cashier(user) || !isnum(index) || index < 1 || index > length(menu))
		return FALSE
	menu.Cut(index, index + 1)
	if(selected == index)
		selected = 0
	else if(selected > index)
		selected--
	return TRUE

/obj/machinery/cash_register/proc/select_item(index, mob/user)
	if(!is_cashier(user))
		return FALSE
	selected = (isnum(index) && index >= 1 && index <= length(menu)) ? index : 0
	selected_at = world.time
	return TRUE

/// Оплата выбранной позиции: доля кассира ему, остаток - в бюджет его отдела. Всё, из-за чего move откажет, проверено в charge_problem.
/obj/machinery/cash_register/proc/charge(mob/living/customer, datum/bank_account/payer)
	if(!payer)
		payer = econ_account_of(customer)
	var/problem = charge_problem(payer)
	if(problem)
		to_chat(customer, span_warning(problem))
		return FALSE
	var/list/item = menu[selected]
	var/price = item["price"]
	var/datum/economy_department/department = SSeconomy.get_department(cashier_account.department_id)
	var/datum/bank_account/budget = department?.account
	var/cashier_part = budget ? round(price * department.register_cashier_share / 100) : price
	var/budget_part = price - cashier_part
	var/memo = "[name]: [item["name"]]"
	if(cashier_part && !SSeconomy.move(payer, cashier_account, cashier_part, ECON_REGISTER, customer, memo))
		return FALSE
	if(budget_part && !SSeconomy.move(payer, budget, budget_part, ECON_REGISTER, customer, memo))
		stack_trace("[src]: доля отдела не прошла после проверок, доля кассира [cashier_part] кр. уже списана")
	total_sales += price
	selected = 0
	receipts["[payer.account_id]"] = list("item" = item["name"], "price" = price, "cashier" = cashier_name, "time" = STATION_TIME_TIMESTAMP("hh:mm", world.time))
	flick("[skin]_paid", src)
	cashier_account.bank_card_talk("Касса: [customer.name] оплатил \"[item["name"]]\" - [price] кр., ваша доля [cashier_part] кр.", balloon = cashier_part ? "касса +[cashier_part] кр" : null)
	if(COOLDOWN_FINISHED(src, feedback_cooldown))
		COOLDOWN_START(src, feedback_cooldown, REGISTER_FEEDBACK_COOLDOWN)
		playsound(src, pick(GLOB.econ_register_chings), 40, FALSE)
	return TRUE

/obj/machinery/cash_register/proc/tip(mob/living/customer, amount, datum/bank_account/payer)
	if(!payer)
		payer = econ_account_of(customer)
	if(!cashier_account || !isnum(amount) || round(amount) > REGISTER_PRICE_MAX)
		return FALSE
	var/error = SSeconomy.send_tip(payer, cashier_account, amount, customer)
	if(error)
		to_chat(customer, span_warning(error))
		return FALSE
	flick("[skin]_open", src)
	if(COOLDOWN_FINISHED(src, feedback_cooldown))
		COOLDOWN_START(src, feedback_cooldown, REGISTER_FEEDBACK_COOLDOWN)
		playsound(src, 'sound/economy/coin_soft.ogg', 35, TRUE)
		new /obj/effect/temp_visual/econ_coins(get_turf(src))
	return TRUE

/// Чек последней оплаты со счёта покупателя, один раз на оплату.
/obj/machinery/cash_register/proc/print_receipt(mob/living/customer)
	var/datum/bank_account/account = econ_account_of(customer)
	var/list/sale = account && receipts["[account.account_id]"]
	if(!sale)
		return FALSE
	receipts -= "[account.account_id]"
	var/obj/item/econ_receipt/receipt = new(drop_location())
	receipt.lines = list("[name], [get_area_name(src)]", "[sale["item"]] - [sale["price"]] кр.", "Кассир: [sale["cashier"]]", "Время: [sale["time"]]")
	customer.put_in_hands(receipt)
	flick("[skin]_print", src)
	playsound(src, 'sound/economy/register_print.ogg', 30, TRUE)
	return TRUE

/// Оплата и чаевые требуют того кассира, которого видел клиент: params["cashier"] - номер его счёта.
/obj/machinery/cash_register/proc/register_act(mob/living/user, action, list/params)
	switch(action)
		if("add_item")
			return add_item(params["name"], params["price"], user)
		if("remove_item")
			return remove_item(params["index"], user)
		if("select")
			return select_item(params["index"], user)
		if("pay")
			if(!selected || params["index"] != selected || params["cashier"] != cashier_account?.account_id)
				return FALSE
			var/list/item = menu[selected]
			if(params["price"] != item["price"])
				return FALSE
			return charge(user)
		if("tip")
			if(params["cashier"] != cashier_account?.account_id)
				return FALSE
			return tip(user, params["amount"])
		if("logout")
			return logout(user)
	return FALSE

/obj/machinery/cash_register/attackby(obj/item/thing, mob/living/user, params)
	if(!isidcard(thing) || user.a_intent == INTENT_HARM)
		return ..()
	var/obj/item/card/id/card = thing
	if(is_cashier(user))
		logout(user)
		to_chat(user, span_notice("Вы отошли от кассы."))
		return TRUE
	if(!cashier_account || (!selected && !cashier_present()))
		if(login(user, card))
			to_chat(user, span_notice("Вы встали за кассу."))
		else
			to_chat(user, span_warning(SSeconomy.personal_account_problem(econ_account_of(user), TRUE) || "Встать за кассу можно только своей картой."))
		return TRUE
	if(!selected)
		to_chat(user, span_warning("Кассир ещё не выбрал позицию к оплате."))
		return TRUE
	if(world.time < selected_at + REGISTER_SELECT_GRACE)
		to_chat(user, span_warning("Позиция к оплате только что сменилась, проверьте сумму и проведите картой ещё раз."))
		return TRUE
	var/line = payment_line()
	if(charge(user, card.registered_account))
		to_chat(user, span_notice("Оплачено: [line]."))
	return TRUE

/obj/machinery/cash_register/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CashRegister", name)
		ui.open()

/obj/machinery/cash_register/ui_static_data(mob/user)
	var/datum/economy_settings/settings = SSeconomy.settings
	return list(
		"skin" = skin,
		"skin_name" = skin_name,
		"price_max" = REGISTER_PRICE_MAX,
		"menu_max" = REGISTER_MENU_MAX,
		"name_max" = MAX_NAME_LEN,
		"tip_max" = min(REGISTER_PRICE_MAX, settings.transfer_max),
		"transfer_cooldown" = settings.transfer_cooldown_seconds,
	)

/obj/machinery/cash_register/ui_data(mob/user)
	var/datum/bank_account/own = econ_account_of(user)
	var/cashier_view = is_cashier(user)
	var/list/item = selected ? menu[selected] : null
	var/datum/economy_department/department = cashier_account ? SSeconomy.get_department(cashier_account.department_id) : null
	return list(
		"cashier" = cashier_account ? cashier_name : null,
		"cashier_present" = !!(cashier_account && cashier_present()),
		"session" = cashier_session,
		"is_cashier" = cashier_view,
		"menu" = menu,
		"selected" = item ? item["id"] : 0,
		"total_sales" = cashier_view ? total_sales : null,
		"department" = department?.account ? department.name : null,
		"cashier_share" = department?.account ? department.register_cashier_share : 100,
		"has_account" = !!own,
		"balance" = own ? own.account_balance : 0,
		"pay_problem" = (item && !cashier_view) ? charge_problem(own) : null,
		"cooldown_left" = own ? CEILING(COOLDOWN_TIMELEFT(own, personal_payment_cooldown) / (1 SECONDS), 1) : 0,
		"receipt" = !!(own && receipts["[own.account_id]"]),
	)

/// Номер позиции меню по её постоянному id: окно шлёт id, номера сдвигаются при удалении.
/obj/machinery/cash_register/proc/menu_index(item_id)
	if(!isnum(item_id))
		return 0
	for(var/index in 1 to length(menu))
		var/list/item = menu[index]
		if(item["id"] == item_id)
			return index
	return 0

/obj/machinery/cash_register/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = usr
	if(!isliving(user))
		return FALSE
	switch(action)
		if("add_item")
			return register_act(user, action, list("name" = params["name"], "price" = econ_ui_number(params["price"])))
		if("remove_item")
			var/index = menu_index(econ_ui_number(params["id"]))
			return index && register_act(user, action, list("index" = index))
		if("select")
			var/item_id = econ_ui_number(params["id"])
			var/index = item_id ? menu_index(item_id) : 0
			if(item_id && !index)
				return FALSE
			return register_act(user, action, list("index" = index))
		if("logout")
			return register_act(user, action, list())
		if("receipt")
			return print_receipt(user)
		if("pay", "tip")
			if(!cashier_account || econ_ui_number(params["session"]) != cashier_session)
				to_chat(user, span_warning("За кассой уже другой кассир, проверьте кассу."))
				return TRUE
			var/cashier_id = cashier_account.account_id
			if(action == "tip")
				var/amount = econ_ui_number(params["amount"])
				if(register_act(user, action, list("amount" = amount, "cashier" = cashier_id)))
					to_chat(user, span_notice("Чаевые [round(amount)] кр. оставлены: [cashier_name]."))
				return TRUE
			var/index = menu_index(econ_ui_number(params["id"]))
			var/list/item = index ? menu[index] : null
			if(!item || index != selected || econ_ui_number(params["price"]) != item["price"])
				to_chat(user, span_warning("Позиция или цена к оплате сменилась, проверьте сумму."))
				return TRUE
			var/line = payment_line()
			if(register_act(user, action, list("index" = index, "price" = econ_ui_number(params["price"]), "cashier" = cashier_id)))
				to_chat(user, span_notice("Оплачено: [line]."))
			return TRUE
	return FALSE

/obj/machinery/cash_register/screwdriver_act(mob/living/user, obj/item/tool)
	. = default_deconstruction_screwdriver(user, "[skin]_panel", skin, tool)
	update_appearance()

/obj/machinery/cash_register/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(tool)

/obj/item/econ_receipt
	name = "receipt"
	desc = "Кассовый чек: что куплено, за сколько и у кого."
	icon = 'icons/obj/economy/items.dmi'
	icon_state = "receipt"
	item_state = "receipt"
	lefthand_file = 'icons/mob/inhands/economy_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/economy_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	var/list/lines

/obj/item/econ_receipt/examine(mob/user)
	. = ..()
	for(var/line in lines)
		. += span_notice(line)

/obj/item/circuitboard/machine/cash_register
	name = "Cash Register (Machine Board)"
	icon_state = "service"
	build_path = /obj/machinery/cash_register
	req_components = list(/obj/item/stock_parts/scanning_module = 1)

/obj/item/circuitboard/machine/cash_register/examine(mob/user)
	. = ..()
	var/obj/machinery/cash_register/register_type = build_path
	. += span_notice("Корпус кассы: [initial(register_type.skin_name)]. Используйте плату в руке, чтобы сменить его.")

/obj/item/circuitboard/machine/cash_register/attack_self(mob/living/user)
	var/static/list/register_types = list(/obj/machinery/cash_register, /obj/machinery/cash_register/bar, /obj/machinery/cash_register/kitchen, /obj/machinery/cash_register/clinic)
	build_path = register_types[register_types.Find(build_path) % length(register_types) + 1]
	var/obj/machinery/cash_register/register_type = build_path
	to_chat(user, span_notice("Корпус кассы на плате: [initial(register_type.skin_name)]."))

#undef REGISTER_FEEDBACK_COOLDOWN
#undef REGISTER_DRAWER_SOUND_COOLDOWN
