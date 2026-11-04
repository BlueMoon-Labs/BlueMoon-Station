/datum/unit_test/economy_register
	abstract_type = /datum/unit_test/economy_register
	var/obj/machinery/cash_register/register
	var/mob/living/carbon/human/cashier
	var/mob/living/carbon/human/customer
	var/datum/bank_account/cashier_account
	var/datum/bank_account/customer_account
	var/saved_share
	var/saved_service_balance
	var/saved_tax_rate

/datum/unit_test/economy_register/New()
	. = ..()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	saved_share = service.register_cashier_share
	saved_service_balance = service.account.account_balance
	saved_tax_rate = SSeconomy.tax_rate

/datum/unit_test/economy_register/Destroy()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	service.register_cashier_share = saved_share
	econ_test_set_balance(service.account, saved_service_balance)
	SSeconomy.tax_rate = saved_tax_rate
	return ..()

/datum/unit_test/economy_register/proc/make_person(holder, department_id, balance = 0, list/access)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new(holder)
	allocated += account
	account.department_id = department_id
	person.account_id = account.account_id
	if(balance)
		econ_test_set_balance(account, balance)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = account
	if(access)
		card.access = access
	person.put_in_hands(card)
	return person

/datum/unit_test/economy_register/proc/setup_register()
	register = allocate(/obj/machinery/cash_register/bar)
	cashier = make_person("econ_test_bartender", ACCOUNT_SRV)
	customer = make_person("econ_test_customer", null, 1000)
	cashier_account = econ_account_of(cashier)
	customer_account = econ_account_of(customer)

/datum/unit_test/economy_register/proc/swipe(mob/living/carbon/human/person, obj/item/card/id/card)
	if(!card)
		card = person.get_active_held_item()
	card.melee_attack_chain(person, register)

/datum/unit_test/economy_register/proc/pay(mob/living/person)
	var/price
	if(register.selected)
		var/list/item = register.menu[register.selected]
		price = item["price"]
	return register.register_act(person, "pay", list("index" = register.selected, "price" = price, "cashier" = register.cashier_account?.account_id))

/datum/unit_test/economy_register/proc/tip(mob/living/person, amount)
	return register.register_act(person, "tip", list("amount" = amount, "cashier" = register.cashier_account?.account_id))

/// Стоит ли кассир за кассой после свайпа и готова ли позиция к оплате.
/datum/unit_test/economy_register/proc/open_with_item(price)
	swipe(cashier)
	TEST_ASSERT(register.is_cashier(cashier), "Кассир встал за кассу своей картой")
	TEST_ASSERT(register.register_act(cashier, "add_item", list("name" = "Пиво", "price" = price)), "Позиция добавлена")
	TEST_ASSERT(register.register_act(cashier, "select", list("index" = 1)), "Позиция выбрана")

/// Оплата делится между кассиром и отделом по ставке главы, чаевые целиком кассиру; налога и эмиссии нет.
/datum/unit_test/economy_register/charge_and_tip/Run()
	setup_register()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	service.register_cashier_share = 40
	SSeconomy.tax_rate = 10
	open_with_item(100)
	var/budget_before = service.account.account_balance
	var/minted_before = SSeconomy.ledger.minted
	var/burned_before = SSeconomy.ledger.burned
	TEST_ASSERT(!register.register_act(customer, "pay", list("index" = 1, "price" = 50, "cashier" = cashier_account.account_id)), "Цена сменилась - оплата не проходит")
	TEST_ASSERT(!register.register_act(customer, "pay", list("index" = 1, "price" = 100, "cashier" = customer_account.account_id)), "Кассир сменился - оплата не проходит")
	TEST_ASSERT(pay(customer), "Оплачено")
	TEST_ASSERT_EQUAL(customer_account.account_balance, 900, "Списано 100")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 40, "Доля кассира без налога")
	TEST_ASSERT_EQUAL(service.account.account_balance - budget_before, 60, "Доля отдела")
	TEST_ASSERT_EQUAL(register.total_sales, 100, "Выручка кассы")
	TEST_ASSERT(!register.selected, "После оплаты позиция снята")
	TEST_ASSERT(!tip(customer, REGISTER_PRICE_MAX + 1), "Чаевые выше потолка кассы")
	TEST_ASSERT(!tip(customer, -5), "Отрицательные чаевые")
	TEST_ASSERT(!tip(cashier, 5), "Чаевые самому себе")
	TEST_ASSERT(tip(customer, 25), "Чаевые")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 65, "Чаевые кассиру целиком")
	TEST_ASSERT_EQUAL(customer_account.account_balance, 875, "Чаевые списаны")
	TEST_ASSERT(!tip(customer, 5), "Чаевые подряд ждут общий кулдаун личных платежей")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted_before, "Касса не создаёт денег")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned, burned_before, "Касса не сжигает денег")

/// Замороженный и приостановленный счёт не платят и не дают чаевых ни при какой доле, касса ничего не засчитывает.
/datum/unit_test/economy_register/blocked_payer/Run()
	setup_register()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	open_with_item(100)
	var/budget_before = service.account.account_balance
	customer_account.state = ACCOUNT_FROZEN
	for(var/share in list(0, 50))
		service.register_cashier_share = share
		TEST_ASSERT(!pay(customer), "Замороженный счёт не платит при доле [share]")
	TEST_ASSERT(!tip(customer, 10), "Замороженный счёт не даёт чаевых")
	customer_account.state = ACCOUNT_ACTIVE
	customer_account.transferable = FALSE
	for(var/share in list(0, 50))
		service.register_cashier_share = share
		TEST_ASSERT(!pay(customer), "Приостановленный счёт не платит при доле [share]")
	TEST_ASSERT(!tip(customer, 10), "Приостановленный счёт не даёт чаевых")
	customer_account.transferable = TRUE
	TEST_ASSERT_EQUAL(customer_account.account_balance, 1000, "С клиента ничего не списано")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 0, "Кассиру ничего")
	TEST_ASSERT_EQUAL(service.account.account_balance, budget_before, "Бюджету ничего")
	TEST_ASSERT_EQUAL(register.total_sales, 0, "Выручка не засчитана")
	TEST_ASSERT_EQUAL(register.selected, 1, "Позиция ждёт оплаты")

/// Кассира, замороженного или заблокированного после входа, касса не оплачивает; замороженный за кассу не встаёт.
/datum/unit_test/economy_register/blocked_cashier/Run()
	setup_register()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	open_with_item(100)
	var/budget_before = service.account.account_balance
	cashier_account.state = ACCOUNT_FROZEN
	TEST_ASSERT(findtext(register.charge_problem(customer_account), "кассира"), "Отказ объясняет, что дело в кассире")
	TEST_ASSERT(!pay(customer), "Замороженному кассиру оплата не идёт")
	cashier_account.state = ACCOUNT_ACTIVE
	cashier_account.transferable = FALSE
	TEST_ASSERT(!pay(customer), "Заблокированному кассиру оплата не идёт")
	cashier_account.transferable = TRUE
	TEST_ASSERT_EQUAL(customer_account.account_balance, 1000, "С клиента ничего не списано")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 0, "Кассиру ничего")
	TEST_ASSERT_EQUAL(service.account.account_balance, budget_before, "Бюджету ничего")
	swipe(cashier)
	cashier_account.state = ACCOUNT_FROZEN
	swipe(cashier)
	cashier_account.state = ACCOUNT_ACTIVE
	TEST_ASSERT_NULL(register.cashier_account, "Замороженный счёт за кассу не встаёт")

/// Свайп: свободная касса - вход, кассир - выход, клиент - оплата, но не сразу после смены позиции.
/datum/unit_test/economy_register/card_swipe/Run()
	setup_register()
	open_with_item(100)
	swipe(customer)
	TEST_ASSERT_EQUAL(customer_account.account_balance, 1000, "Сразу после выбора позиции свайп не платит")
	register.selected_at -= REGISTER_SELECT_GRACE
	swipe(customer)
	TEST_ASSERT_EQUAL(customer_account.account_balance, 900, "Свайп оплатил позицию")
	TEST_ASSERT(register.cashier_account == cashier_account, "Клиент не встал за кассу")
	swipe(cashier)
	TEST_ASSERT_NULL(register.cashier_account, "Кассир отошёл от кассы")
	TEST_ASSERT_EQUAL(length(register.menu), 1, "Меню осталось после выхода")

/// Меню правит только кассир; цена от 1 до потолка, длина меню ограничена.
/datum/unit_test/economy_register/menu_rules/Run()
	setup_register()
	swipe(cashier)
	TEST_ASSERT(!register.register_act(customer, "add_item", list("name" = "Чужое", "price" = 10)), "Клиент не правит меню")
	TEST_ASSERT(!register.register_act(cashier, "add_item", list("name" = "Дорого", "price" = REGISTER_PRICE_MAX + 1)), "Потолок цены")
	TEST_ASSERT(!register.register_act(cashier, "add_item", list("name" = "Отрицательно", "price" = -5)), "Отрицательная цена")
	TEST_ASSERT(!register.register_act(cashier, "add_item", list("name" = "Даром", "price" = 0)), "Нулевая цена")
	TEST_ASSERT(!register.register_act(cashier, "add_item", list("name" = "", "price" = 5)), "Пустое название")
	for(var/i in 1 to REGISTER_MENU_MAX)
		TEST_ASSERT(register.register_act(cashier, "add_item", list("name" = "Позиция [i]", "price" = 10)), "Позиция [i] добавлена")
	TEST_ASSERT(!register.register_act(cashier, "add_item", list("name" = "Лишняя", "price" = 10)), "Потолок меню")
	TEST_ASSERT(!register.register_act(customer, "select", list("index" = 2)), "Клиент не выбирает позицию")
	TEST_ASSERT(!register.register_act(customer, "remove_item", list("index" = 1)), "Клиент не убирает позицию")
	TEST_ASSERT(register.register_act(cashier, "select", list("index" = 3)), "Кассир выбрал позицию")
	var/list/chosen = register.menu[3]
	TEST_ASSERT(register.register_act(cashier, "remove_item", list("index" = 2)), "Кассир убрал позицию")
	TEST_ASSERT_EQUAL(length(register.menu), REGISTER_MENU_MAX - 1, "Позиция убрана")
	TEST_ASSERT(register.selected && register.menu[register.selected] == chosen, "Выбор держится за ту же позицию при правке меню перед ней")
	TEST_ASSERT(register.register_act(cashier, "remove_item", list("index" = register.selected)), "Кассир убрал выбранную позицию")
	TEST_ASSERT(!register.selected, "Выбор сброшен вместе с позицией")

/// Без денег оплата не проходит и ничего не двигает.
/datum/unit_test/economy_register/no_money/Run()
	setup_register()
	open_with_item(REGISTER_PRICE_MAX)
	TEST_ASSERT(!pay(customer), "Отказ")
	TEST_ASSERT_EQUAL(customer_account.account_balance, 1000, "Баланс цел")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 0, "Кассиру ничего")

/// Бюджет отдела через кассу не выводится: ни картой отдела, ни продажей самому себе.
/datum/unit_test/economy_register/no_budget_laundering/Run()
	setup_register()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/obj/item/card/id/departmental_budget/srv/budget_card = allocate(/obj/item/card/id/departmental_budget/srv)
	swipe(cashier, budget_card)
	TEST_ASSERT_NULL(register.cashier_account, "За кассу не встать картой бюджета")
	swipe(cashier, customer.get_active_held_item())
	TEST_ASSERT_NULL(register.cashier_account, "За кассу не встать чужой картой")
	open_with_item(100)
	sleep(REGISTER_SELECT_GRACE)
	var/budget_before = service.account.account_balance
	swipe(customer, budget_card)
	TEST_ASSERT_EQUAL(service.account.account_balance, budget_before, "Картой бюджета не заплатить")
	TEST_ASSERT(register.selected, "Позиция не оплачена")
	TEST_ASSERT(!pay(cashier), "Кассир не платит сам себе")
	TEST_ASSERT_EQUAL(service.account.account_balance, budget_before, "Бюджет не тронут")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 0, "Кассиру ничего")

/// Ушедшего далеко или умершего кассира сменяет следующий; меню остаётся, оплата и её подтверждение - новому кассиру; без отдела выручка вся кассиру.
/datum/unit_test/economy_register/takeover/Run()
	setup_register()
	var/mob/living/carbon/human/assistant = make_person("Econ Test Assistant", null)
	var/datum/bank_account/assistant_account = econ_account_of(assistant)
	var/obj/item/card/id/assistant_card = assistant.get_active_held_item()
	assistant_card.registered_name = "Econ Test Assistant"
	open_with_item(30)
	register.register_act(cashier, "select", list("index" = 0))
	swipe(assistant)
	TEST_ASSERT(register.cashier_account == cashier_account, "Пока кассир рядом, кассу не перехватить")
	var/turf/far_turf = locate(min(run_loc_floor_bottom_left.x + REGISTER_CASHIER_RANGE + 1, world.maxx), run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	cashier.forceMove(far_turf)
	swipe(assistant)
	TEST_ASSERT(register.cashier_account == assistant_account, "Ушедшего далеко кассира сменил новый")
	TEST_ASSERT_EQUAL(length(register.menu), 1, "Меню осталось при перехвате")
	TEST_ASSERT(register.register_act(assistant, "select", list("index" = 1)), "Новый кассир выбрал позицию")
	TEST_ASSERT(findtext(register.payment_line(), "Econ Test Assistant"), "Подтверждение называет получателя: [register.payment_line()]")
	TEST_ASSERT(pay(customer), "Оплачено")
	TEST_ASSERT_EQUAL(assistant_account.account_balance, 30, "Без отдела выручка вся новому кассиру")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 0, "Прежнему кассиру ничего")
	cashier.forceMove(run_loc_floor_bottom_left)
	swipe(cashier)
	TEST_ASSERT(register.cashier_account == assistant_account, "Живого кассира рядом не сменить")
	assistant.death()
	swipe(cashier)
	TEST_ASSERT(register.cashier_account == cashier_account, "Умершего кассира сменил новый")

/// Касса без кассира погашена, оплатившему печатает чек из окна один раз, в том числе когда кассир уже отошёл.
/datum/unit_test/economy_register/receipt/Run()
	setup_register()
	TEST_ASSERT_EQUAL(register.icon_state, "bar_off", "Касса без кассира погашена")
	open_with_item(100)
	TEST_ASSERT_EQUAL(register.icon_state, "bar", "За кассой кассир - экран горит")
	TEST_ASSERT(pay(customer), "Оплата прошла")
	swipe(cashier)
	TEST_ASSERT_NULL(register.cashier_account, "Кассир отошёл")
	TEST_ASSERT(register.ui_data(customer)["receipt"], "Чек доступен и без кассира")
	econ_ui_press(customer, register, "CashRegister", "receipt")
	econ_ui_press(customer, register, "CashRegister", "receipt")
	var/list/receipts = list()
	for(var/obj/item/econ_receipt/receipt in customer.held_items)
		receipts += receipt
	TEST_ASSERT_EQUAL(length(receipts), 1, "Один чек на одну оплату")
	if(length(receipts))
		var/obj/item/econ_receipt/receipt = receipts[1]
		TEST_ASSERT(findtext(jointext(receipt.lines, " "), "Пиво - 100 кр."), "В чеке позиция и цена")
	TEST_ASSERT(!register.ui_data(customer)["receipt"], "Чек уже распечатан")
	QDEL_LIST(receipts)

/// Долю кассира меняет только глава отдела, в пределах 0..100.
/datum/unit_test/economy_register/share_by_head/Run()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/mob/living/carbon/human/bartender = make_person("econ_test_bartender", ACCOUNT_SRV)
	var/mob/living/carbon/human/captain = make_person("econ_test_captain", ACCOUNT_CMD, access = list(ACCESS_CAPTAIN))
	var/default_share = SSeconomy.settings.register_cashier_share_default
	service.register_cashier_share = default_share
	TEST_ASSERT(!service.set_register_share(100, bartender), "Сотрудник не меняет долю")
	TEST_ASSERT_EQUAL(service.register_cashier_share, default_share, "Доля прежняя")
	TEST_ASSERT(service.set_register_share(150, captain), "Капитан меняет долю")
	TEST_ASSERT_EQUAL(service.register_cashier_share, 100, "Доля зажата сверху")
	TEST_ASSERT(service.set_register_share(-20, captain), "Капитан меняет долю")
	TEST_ASSERT_EQUAL(service.register_cashier_share, 0, "Доля зажата снизу")

/// Корпус выбирается на плате в руке, разборка возвращает плату с тем же корпусом.
/datum/unit_test/economy_register/board_skin/Run()
	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human)
	var/obj/item/circuitboard/machine/cash_register/board = allocate(/obj/item/circuitboard/machine/cash_register)
	engineer.put_in_active_hand(board)
	board.attack_self(engineer)
	TEST_ASSERT_EQUAL(board.build_path, /obj/machinery/cash_register/bar, "Плата переключилась на бар")
	for(var/i in 1 to 3)
		board.attack_self(engineer)
	TEST_ASSERT_EQUAL(board.build_path, /obj/machinery/cash_register, "Перебор корпусов по кругу")
	var/turf/work_turf = run_loc_floor_top_right
	var/obj/machinery/cash_register/kitchen/kitchen_register = new(work_turf)
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)
	var/obj/item/crowbar/crowbar = allocate(/obj/item/crowbar)
	screwdriver.melee_attack_chain(engineer, kitchen_register)
	crowbar.melee_attack_chain(engineer, kitchen_register)
	TEST_ASSERT(QDELETED(kitchen_register), "Касса разобрана")
	var/obj/item/circuitboard/machine/cash_register/dropped = locate() in work_turf
	TEST_ASSERT_NOTNULL(dropped, "Плата выпала при разборке")
	if(dropped)
		TEST_ASSERT_EQUAL(dropped.build_path, /obj/machinery/cash_register/kitchen, "Плата помнит корпус кухни")
	econ_test_clear_turf(work_turf)

/// Касса каждого вида создаётся и удаляется, отпуская кассира.
/datum/unit_test/economy_register/create_and_destroy/Run()
	cashier = make_person("econ_test_bartender", ACCOUNT_SRV)
	for(var/register_type in typesof(/obj/machinery/cash_register))
		register = new register_type(run_loc_floor_bottom_left)
		swipe(cashier)
		TEST_ASSERT(register.is_cashier(cashier), "[register_type]: кассир вошёл")
		qdel(register)
		TEST_ASSERT(QDELETED(register), "[register_type] удалена")
		register = null
