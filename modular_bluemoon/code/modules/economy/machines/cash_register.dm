#define REGISTER_DRAWER_SOUND_COOLDOWN (3 SECONDS)
#define REGISTER_FEEDBACK_COOLDOWN (1 SECONDS)

GLOBAL_LIST_INIT(econ_register_chings, list(
	'sound/economy/register_ching1.ogg',
	'sound/economy/register_ching2.ogg',
	'sound/economy/register_ching3.ogg',
))

/// Кассир за кассой и его счёт к оплате.
/datum/register_cashier
	var/datum/bank_account/account
	var/datum/weakref/mob_ref
	var/name
	/// Счёт к оплате: "[id позиции меню]" -> количество, в порядке добавления
	var/list/order = list()
	/// Меняется при каждой правке счёта: оплата из окна проходит только по тому счёту, который видел клиент
	var/order_rev = 0
	/// Когда счёт правили последний раз: свайп сразу после правки не платит
	var/order_at = 0

/datum/register_cashier/New(datum/bank_account/account, mob/living/user, name)
	src.account = account
	mob_ref = WEAKREF(user)
	src.name = name

/datum/register_cashier/Destroy()
	account = null
	mob_ref = null
	return ..()

/obj/machinery/cash_register
	name = "cash register"
	desc = "Касса заведения. Кассиры, до двух сразу, встают за неё своей ID-картой, составляют общее меню и набирают каждый свой счёт. Клиент оплачивает счёт картой или наличными и может оставить чаевые. Платить необязательно: NT и так оплачивает отделу его работу."
	icon = 'icons/obj/machines/economy/cash_register.dmi'
	icon_state = "universal_off"
	density = FALSE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/cash_register
	var/skin = "universal"
	var/skin_name = "универсальный"
	/// Позиции меню: list("id", "name", "price")
	var/list/menu = list()
	/// Кассиры за кассой, не больше REGISTER_CASHIERS_MAX
	var/list/datum/register_cashier/cashiers = list()
	var/total_sales = 0
	var/next_item_id = 0
	var/next_rev = 0
	/// Номер счёта -> последняя оплата с него картой, ещё без распечатанного чека: list("lines", "total", "cashier", "time")
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
	else if(!length(cashiers) || (machine_stat & BROKEN))
		icon_state = "[skin]_off"
	else
		icon_state = skin
	return ..()

/obj/machinery/cash_register/Destroy()
	QDEL_LIST(cashiers)
	return ..()

/obj/machinery/cash_register/examine(mob/user)
	. = ..()
	if(!length(cashiers))
		. += span_notice("Касса свободна, экран погашен: проведите своей ID-картой, чтобы встать за неё.")
	for(var/datum/register_cashier/cashier as anything in cashiers)
		var/datum/economy_department/department = department_of(cashier)
		var/total = order_total(cashier)
		var/order_text = total ? " Счёт к оплате: [total] кр." : ""
		if(department)
			. += span_notice("За кассой [cashier.name]: [department.register_cashier_share]% выручки кассиру, [100 - department.register_cashier_share]% в бюджет отдела \"[department.name]\".[order_text]")
		else
			. += span_notice("За кассой [cashier.name], выручка целиком ему.[order_text]")
	. += span_notice("Оплата - свайпом карты или из окна кассы, только с личного счёта, без налога. Наличные (голочип, купюры, монеты) прикладывают к кассе: сдачу она выдаёт голочипом.")
	if(is_cashier(user))
		. += span_notice("Цена позиции от 1 до [REGISTER_PRICE_MAX] кр., в меню до [REGISTER_MENU_MAX] позиций, до [REGISTER_ORDER_COUNT_MAX] шт. одной позиции в счёте. Свайп своей картой - отойти от кассы.")
	if(!user.Adjacent(src))
		return
	for(var/list/item as anything in menu)
		. += span_notice("[item["name"]] - [item["price"]] кр.")

/obj/machinery/cash_register/proc/cashier_of(mob/user)
	var/datum/bank_account/account = econ_account_of(user)
	if(!account)
		return null
	for(var/datum/register_cashier/cashier as anything in cashiers)
		if(cashier.account == account)
			return cashier

/obj/machinery/cash_register/proc/cashier_by_id(account_id)
	for(var/datum/register_cashier/cashier as anything in cashiers)
		if(cashier.account.account_id == account_id)
			return cashier

/obj/machinery/cash_register/proc/is_cashier(mob/user)
	return !!cashier_of(user)

/obj/machinery/cash_register/proc/cashier_present(datum/register_cashier/cashier)
	var/mob/living/person = cashier?.mob_ref?.resolve()
	var/turf/cashier_turf = get_turf(person)
	var/turf/register_turf = get_turf(src)
	if(!cashier_turf || !register_turf || person.stat == DEAD || cashier_turf.z != register_turf.z)
		return FALSE
	return get_dist(register_turf, cashier_turf) <= REGISTER_CASHIER_RANGE && econ_account_of(person) == cashier.account

/// Отдел кассира, если у отдела есть бюджет: туда идёт его доля выручки.
/obj/machinery/cash_register/proc/department_of(datum/register_cashier/cashier)
	var/datum/economy_department/department = SSeconomy.get_department(cashier.account.department_id)
	return department?.account ? department : null

/// Место за кассой: свободное или того, кто ушёл.
/obj/machinery/cash_register/proc/free_slot()
	if(length(cashiers) < REGISTER_CASHIERS_MAX)
		return TRUE
	for(var/datum/register_cashier/cashier as anything in cashiers)
		if(!cashier_present(cashier))
			return cashier
	return FALSE

/// Встать за кассу можно только своей картой, на свободное место или место ушедшего кассира.
/obj/machinery/cash_register/proc/login(mob/living/user, obj/item/card/id/card)
	var/datum/bank_account/account = econ_account_of(user)
	if(SSeconomy.personal_account_problem(account, TRUE) || (card && card.registered_account != account) || cashier_of(user))
		return FALSE
	var/slot = free_slot()
	if(!slot)
		return FALSE
	if(!card)
		card = user.get_idcard()
	var/new_name = card?.registered_name || user.name
	if(istype(slot, /datum/register_cashier))
		var/datum/register_cashier/gone = slot
		gone.account.bank_card_talk("Ваше место за кассой \"[name]\" занял [new_name], ваш счёт к оплате сброшен.")
		cashiers -= gone
		qdel(gone)
	var/datum/register_cashier/cashier = new(account, user, new_name)
	cashier.order_rev = ++next_rev
	cashiers += cashier
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
	var/datum/register_cashier/cashier = cashier_of(user)
	if(!cashier)
		return FALSE
	cashiers -= cashier
	qdel(cashier)
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

/// Убранная позиция уходит и из всех счетов к оплате.
/obj/machinery/cash_register/proc/remove_item(index, mob/user)
	if(!is_cashier(user) || !isnum(index) || index < 1 || index > length(menu))
		return FALSE
	var/list/item = menu[index]
	menu.Cut(index, index + 1)
	var/key = "[item["id"]]"
	for(var/datum/register_cashier/cashier as anything in cashiers)
		if(cashier.order[key])
			cashier.order -= key
			order_changed(cashier)
	return TRUE

/obj/machinery/cash_register/proc/order_changed(datum/register_cashier/cashier)
	cashier.order_rev = ++next_rev
	cashier.order_at = world.time

/// Кассир добавляет в свой счёт или убирает из него штуки позиции меню.
/obj/machinery/cash_register/proc/order_add(mob/user, item_id, delta)
	var/datum/register_cashier/cashier = cashier_of(user)
	if(!cashier || !isnum(delta) || !menu_index(item_id))
		return FALSE
	var/key = "[item_id]"
	var/count = clamp((cashier.order[key] || 0) + round(delta), 0, REGISTER_ORDER_COUNT_MAX)
	if(count == (cashier.order[key] || 0))
		return FALSE
	if(count)
		cashier.order[key] = count
	else
		cashier.order -= key
	order_changed(cashier)
	return TRUE

/obj/machinery/cash_register/proc/order_clear(mob/user)
	var/datum/register_cashier/cashier = cashier_of(user)
	if(!cashier || !length(cashier.order))
		return FALSE
	cashier.order.Cut()
	order_changed(cashier)
	return TRUE

/// Строки счёта: list("id", "name", "price", "count") по позициям меню.
/obj/machinery/cash_register/proc/order_lines(datum/register_cashier/cashier)
	. = list()
	for(var/key in cashier.order)
		var/index = menu_index(text2num(key))
		if(!index)
			continue
		var/list/item = menu[index]
		. += list(list("id" = item["id"], "name" = item["name"], "price" = item["price"], "count" = cashier.order[key]))

/obj/machinery/cash_register/proc/order_total(datum/register_cashier/cashier)
	. = 0
	for(var/list/line as anything in order_lines(cashier))
		. += line["price"] * line["count"]

/obj/machinery/cash_register/proc/open_orders()
	. = list()
	for(var/datum/register_cashier/cashier as anything in cashiers)
		if(length(cashier.order))
			. += cashier

/// Почему оплата картой не пройдёт: текст для клиента или null.
/obj/machinery/cash_register/proc/charge_problem(datum/bank_account/payer, datum/register_cashier/cashier)
	if(!cashier || !length(cashier.order))
		return "Кассир ещё не набрал счёт к оплате."
	if(SSeconomy.personal_account_problem(cashier.account, TRUE))
		return "Счёт кассира заморожен или заблокирован, касса оплату не принимает."
	. = SSeconomy.personal_account_problem(payer, TRUE)
	if(.)
		return
	if(payer == cashier.account)
		return "Нельзя платить самому себе."
	var/total = order_total(cashier)
	if(!payer.has_money(total))
		return "Недостаточно средств: на счёте [payer.account_balance] кр."

/obj/machinery/cash_register/proc/payment_line(datum/register_cashier/cashier)
	return "[order_total(cashier)] кр., получатель: [cashier.name]"

/// Сумма делится: доля кассира ему, остаток - в бюджет его отдела. source - счёт клиента или наличные в обороте.
/obj/machinery/cash_register/proc/settle(datum/register_cashier/cashier, datum/bank_account/source, total, mob/living/customer)
	var/datum/economy_department/department = department_of(cashier)
	var/cashier_part = department ? round(total * department.register_cashier_share / 100) : total
	var/budget_part = total - cashier_part
	var/memo = "[name]: счёт [cashier.name]"
	if(cashier_part && !SSeconomy.move(source, cashier.account, cashier_part, ECON_REGISTER, customer, memo))
		return null
	if(budget_part && !SSeconomy.move(source, department.account, budget_part, ECON_REGISTER, customer, memo))
		stack_trace("[src]: доля отдела не прошла после проверок, доля кассира [cashier_part] кр. уже списана")
	return cashier_part

/obj/machinery/cash_register/proc/receipt_lines(list/lines)
	. = list()
	for(var/list/line as anything in lines)
		. += "[line["name"]][line["count"] > 1 ? " x[line["count"]]" : ""] - [line["price"] * line["count"]] кр."

/obj/machinery/cash_register/proc/finish_sale(datum/register_cashier/cashier, mob/living/customer, total, cashier_part, how)
	total_sales += total
	cashier.order.Cut()
	order_changed(cashier)
	flick("[skin]_paid", src)
	cashier.account.bank_card_talk("Касса: [customer.name] оплатил счёт [how] - [total] кр., ваша доля [cashier_part] кр.", balloon = cashier_part ? "касса +[cashier_part] кр" : null)
	if(COOLDOWN_FINISHED(src, feedback_cooldown))
		COOLDOWN_START(src, feedback_cooldown, REGISTER_FEEDBACK_COOLDOWN)
		playsound(src, pick(GLOB.econ_register_chings), 40, FALSE)

/// Оплата счёта кассира картой. Всё, из-за чего move откажет, проверено в charge_problem.
/obj/machinery/cash_register/proc/charge(mob/living/customer, datum/bank_account/payer, datum/register_cashier/cashier)
	if(!payer)
		payer = econ_account_of(customer)
	var/problem = charge_problem(payer, cashier)
	if(problem)
		to_chat(customer, span_warning(problem))
		return FALSE
	var/list/lines = order_lines(cashier)
	var/total = order_total(cashier)
	var/cashier_part = settle(cashier, payer, total, customer)
	if(isnull(cashier_part))
		return FALSE
	receipts["[payer.account_id]"] = list("lines" = receipt_lines(lines), "total" = total, "cashier" = cashier.name, "time" = STATION_TIME_TIMESTAMP("hh:mm", world.time))
	finish_sale(cashier, customer, total, cashier_part, "картой")
	return TRUE

/proc/econ_is_cash(obj/item/thing)
	return istype(thing, /obj/item/holochip) || istype(thing, /obj/item/stack/spacecash) || istype(thing, /obj/item/coin)

/// Забирает из наличных сумму total и возвращает сдачу или null, если денег не хватило.
/obj/machinery/cash_register/proc/take_cash(obj/item/money, total)
	if(istype(money, /obj/item/holochip))
		var/obj/item/holochip/chip = money
		return chip.spend(total) ? 0 : null
	if(istype(money, /obj/item/stack/spacecash))
		var/obj/item/stack/spacecash/bills = money
		var/needed = CEILING(total / bills.value, 1)
		if(bills.amount < needed || !bills.use(needed))
			return null
		return needed * bills.value - total
	var/value = money.get_item_credit_value()
	if(value < total)
		return null
	qdel(money)
	return value - total

/// Оплата наличными: касса зачисляет их сразу на счета кассира и отдела, сдачу выдаёт голочипом, чек печатает сразу.
/obj/machinery/cash_register/proc/pay_cash(mob/living/customer, obj/item/money, datum/register_cashier/cashier)
	if(!cashier || !length(cashier.order))
		to_chat(customer, span_warning("Кассир ещё не набрал счёт к оплате."))
		return FALSE
	if(SSeconomy.personal_account_problem(cashier.account, TRUE))
		to_chat(customer, span_warning("Счёт кассира заморожен или заблокирован, касса оплату не принимает."))
		return FALSE
	var/total = order_total(cashier)
	var/value = money.get_item_credit_value()
	if(value < total)
		to_chat(customer, span_warning("Не хватает: в [money.name] [value] кр., счёт [total] кр."))
		return FALSE
	var/list/lines = order_lines(cashier)
	var/cashier_name = cashier.name
	var/change = take_cash(money, total)
	if(isnull(change))
		to_chat(customer, span_warning("Касса не смогла взять [total] кр. из [money.name]."))
		return FALSE
	var/cashier_part = settle(cashier, SSeconomy.cash_account, total, customer)
	if(change > 0)
		var/obj/item/holochip/change_chip = new(drop_location(), change)
		customer.put_in_hands(change_chip)
	finish_sale(cashier, customer, total, cashier_part || 0, "наличными")
	give_receipt(customer, list("lines" = receipt_lines(lines), "total" = total, "cashier" = cashier_name, "time" = STATION_TIME_TIMESTAMP("hh:mm", world.time)), change)
	to_chat(customer, span_notice("Оплачено наличными: [total] кр., получатель: [cashier_name].[change > 0 ? " Сдача [change] кр. голочипом." : ""]"))
	return TRUE

/obj/machinery/cash_register/proc/tip(mob/living/customer, amount, datum/register_cashier/cashier, datum/bank_account/payer)
	if(!payer)
		payer = econ_account_of(customer)
	if(!cashier || !isnum(amount) || round(amount) > REGISTER_PRICE_MAX)
		return FALSE
	var/error = SSeconomy.send_tip(payer, cashier.account, amount, customer)
	if(error)
		to_chat(customer, span_warning(error))
		return FALSE
	flick("[skin]_open", src)
	if(COOLDOWN_FINISHED(src, feedback_cooldown))
		COOLDOWN_START(src, feedback_cooldown, REGISTER_FEEDBACK_COOLDOWN)
		playsound(src, 'sound/economy/coin_soft.ogg', 35, TRUE)
		new /obj/effect/temp_visual/econ_coins(get_turf(src))
	return TRUE

/obj/machinery/cash_register/proc/give_receipt(mob/living/customer, list/sale, change)
	var/obj/item/econ_receipt/receipt = new(drop_location())
	receipt.lines = list("[name], [get_area_name(src)]") + sale["lines"] + list("Итого: [sale["total"]] кр.[isnull(change) ? "" : ", наличными, сдача [change] кр."]", "Кассир: [sale["cashier"]]", "Время: [sale["time"]]")
	customer.put_in_hands(receipt)
	flick("[skin]_print", src)
	playsound(src, 'sound/economy/register_print.ogg', 30, TRUE)

/// Чек последней оплаты картой со счёта покупателя, один раз на оплату.
/obj/machinery/cash_register/proc/print_receipt(mob/living/customer)
	var/datum/bank_account/account = econ_account_of(customer)
	var/list/sale = account && receipts["[account.account_id]"]
	if(!sale)
		return FALSE
	receipts -= "[account.account_id]"
	give_receipt(customer, sale)
	return TRUE

/// Действия кассы. Оплата и чаевые требуют того кассира, которого видел клиент: params["cashier"] - номер его счёта; оплата - ещё и тот же счёт: params["rev"] и params["total"].
/obj/machinery/cash_register/proc/register_act(mob/living/user, action, list/params)
	switch(action)
		if("add_item")
			return add_item(params["name"], params["price"], user)
		if("remove_item")
			return remove_item(params["index"], user)
		if("order")
			return order_add(user, params["id"], params["delta"])
		if("clear")
			return order_clear(user)
		if("join")
			return login(user)
		if("pay")
			var/datum/register_cashier/cashier = cashier_by_id(params["cashier"])
			if(!cashier || params["rev"] != cashier.order_rev || params["total"] != order_total(cashier))
				return FALSE
			return charge(user, null, cashier)
		if("tip")
			return tip(user, params["amount"], cashier_by_id(params["cashier"]))
		if("logout")
			return logout(user)
	return FALSE

/// Чей счёт платит клиент: единственный открытый или выбранный из списка, если кассиров двое.
/obj/machinery/cash_register/proc/choose_order(mob/living/user)
	var/list/open = open_orders()
	if(length(open) < 2)
		return length(open) ? open[1] : null
	var/list/choices = list()
	var/list/revs = list()
	for(var/datum/register_cashier/cashier as anything in open)
		choices["[cashier.name]: [order_total(cashier)] кр."] = cashier
		revs[cashier] = cashier.order_rev
	var/choice = tgui_input_list(user, "Чей счёт оплатить?", name, choices)
	var/datum/register_cashier/chosen = choice && choices[choice]
	if(!chosen || QDELETED(src) || !user.Adjacent(src))
		return null
	if(!(chosen in cashiers) || chosen.order_rev != revs[chosen])
		to_chat(user, span_warning("Счёт к оплате сменился, проверьте сумму."))
		return null
	return chosen

/// Свайпом встают за кассу, если за ней никого или только коллеги по отделу; иначе встать вторым - из окна кассы, чтобы клиент не занял место случайно.
/obj/machinery/cash_register/proc/can_join_by_swipe(mob/living/user)
	var/datum/bank_account/account = econ_account_of(user)
	for(var/datum/register_cashier/cashier as anything in cashiers)
		if(cashier_present(cashier) && (!account?.department_id || cashier.account.department_id != account.department_id))
			return FALSE
	return TRUE

/obj/machinery/cash_register/proc/swipe_card(mob/living/user, obj/item/card/id/card)
	if(is_cashier(user))
		logout(user)
		to_chat(user, span_notice("Вы отошли от кассы."))
		return
	if(!length(open_orders()))
		if(can_join_by_swipe(user) && login(user, card))
			to_chat(user, span_notice("Вы встали за кассу."))
			return
		var/problem = SSeconomy.personal_account_problem(econ_account_of(user), TRUE)
		if(problem || card.registered_account != econ_account_of(user))
			to_chat(user, span_warning(problem || "Встать за кассу можно только своей картой."))
		else
			to_chat(user, span_warning(length(cashiers) ? "Кассир ещё не набрал счёт к оплате. Встать вторым кассиром можно из окна кассы." : "Встать за кассу не вышло."))
		return
	var/datum/register_cashier/cashier = choose_order(user)
	if(!cashier)
		return
	if(world.time < cashier.order_at + REGISTER_SELECT_GRACE)
		to_chat(user, span_warning("Счёт только что изменился, проверьте сумму и проведите картой ещё раз."))
		return
	var/line = payment_line(cashier)
	if(charge(user, card.registered_account, cashier))
		to_chat(user, span_notice("Оплачено: [line]."))

/obj/machinery/cash_register/attackby(obj/item/thing, mob/living/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()
	if(isidcard(thing))
		swipe_card(user, thing)
		return TRUE
	if(!econ_is_cash(thing))
		return ..()
	if(!length(open_orders()))
		to_chat(user, span_warning("Кассир ещё не набрал счёт к оплате."))
		return TRUE
	var/datum/register_cashier/cashier = choose_order(user)
	if(!cashier || QDELETED(thing) || !user.is_holding(thing))
		return TRUE
	if(world.time < cashier.order_at + REGISTER_SELECT_GRACE)
		to_chat(user, span_warning("Счёт только что изменился, проверьте сумму и приложите наличные ещё раз."))
		return TRUE
	pay_cash(user, thing, cashier)
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
		"count_max" = REGISTER_ORDER_COUNT_MAX,
		"cashiers_max" = REGISTER_CASHIERS_MAX,
		"tip_max" = min(REGISTER_PRICE_MAX, settings.transfer_max),
		"transfer_cooldown" = settings.transfer_cooldown_seconds,
	)

/obj/machinery/cash_register/ui_data(mob/user)
	var/datum/bank_account/own = econ_account_of(user)
	var/datum/register_cashier/mine = cashier_of(user)
	var/list/rows = list()
	for(var/datum/register_cashier/cashier as anything in cashiers)
		var/datum/economy_department/department = department_of(cashier)
		rows += list(list(
			"id" = cashier.account.account_id,
			"name" = cashier.name,
			"present" = cashier_present(cashier),
			"mine" = cashier == mine,
			"order" = order_lines(cashier),
			"total" = order_total(cashier),
			"rev" = cashier.order_rev,
			"department" = department?.name,
			"share" = department ? department.register_cashier_share : 100,
			"pay_problem" = (!mine && length(cashier.order)) ? charge_problem(own, cashier) : null,
		))
	return list(
		"cashiers" = rows,
		"is_cashier" = !!mine,
		"can_join" = !mine && !!own && !!free_slot(),
		"menu" = menu,
		"total_sales" = mine ? total_sales : null,
		"has_account" = !!own,
		"balance" = own ? own.account_balance : 0,
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
		if("order")
			return register_act(user, action, list("id" = econ_ui_number(params["id"]), "delta" = econ_ui_number(params["delta"])))
		if("clear", "logout")
			return register_act(user, action, list())
		if("join")
			if(!register_act(user, action, list()))
				to_chat(user, span_warning(SSeconomy.personal_account_problem(econ_account_of(user), TRUE) || "Мест за кассой нет: оба кассира на месте."))
			return TRUE
		if("receipt")
			return print_receipt(user)
		if("pay", "tip")
			var/cashier_id = econ_ui_number(params["cashier"])
			var/datum/register_cashier/cashier = cashier_by_id(cashier_id)
			if(!cashier)
				to_chat(user, span_warning("Этот кассир уже отошёл от кассы."))
				return TRUE
			if(action == "tip")
				var/amount = econ_ui_number(params["amount"])
				if(register_act(user, action, list("amount" = amount, "cashier" = cashier_id)))
					to_chat(user, span_notice("Чаевые [round(amount)] кр. оставлены: [cashier.name]."))
				return TRUE
			var/rev = econ_ui_number(params["rev"])
			var/total = econ_ui_number(params["total"])
			if(rev != cashier.order_rev || total != order_total(cashier))
				to_chat(user, span_warning("Счёт к оплате сменился, проверьте сумму."))
				return TRUE
			var/line = payment_line(cashier)
			if(register_act(user, action, list("cashier" = cashier_id, "rev" = rev, "total" = total)))
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
