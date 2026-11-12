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

/// Место кассира за кассой: по человеку или первое.
/datum/unit_test/economy_register/proc/till(mob/living/person)
	if(person)
		return register.cashier_of(person)
	return length(register.cashiers) ? register.cashiers[1] : null

/datum/unit_test/economy_register/proc/item_id(index = 1)
	var/list/item = register.menu[index]
	return item["id"]

/datum/unit_test/economy_register/proc/order(mob/living/person, index = 1, delta = 1)
	return register.register_act(person, "order", list("id" = item_id(index), "delta" = delta))

/datum/unit_test/economy_register/proc/pay(mob/living/person, datum/register_cashier/seller)
	if(!seller)
		seller = till()
	if(!seller)
		return FALSE
	return register.register_act(person, "pay", list("cashier" = seller.account.account_id, "rev" = seller.order_rev, "total" = register.order_total(seller)))

/// Чек у человека в руках или под кассой.
/datum/unit_test/economy_register/proc/find_receipt(mob/living/person)
	. = locate(/obj/item/econ_receipt) in person.held_items
	if(!.)
		. = locate(/obj/item/econ_receipt) in register.drop_location()

/datum/unit_test/economy_register/proc/tip(mob/living/person, amount)
	var/datum/register_cashier/seller = till()
	return register.register_act(person, "tip", list("amount" = amount, "cashier" = seller?.account.account_id))

/// Кассир встаёт за кассу свайпом, заводит позицию и ставит одну штуку в свой счёт.
/datum/unit_test/economy_register/proc/open_with_item(price)
	swipe(cashier)
	TEST_ASSERT(register.is_cashier(cashier), "Кассир встал за кассу своей картой")
	TEST_ASSERT(register.register_act(cashier, "add_item", list("name" = "Пиво", "price" = price)), "Позиция добавлена")
	TEST_ASSERT(order(cashier), "Позиция в счёте")

/// Оплата делится между кассиром и отделом по ставке главы, чаевые целиком кассиру; налога и эмиссии нет.
/datum/unit_test/economy_register/charge_and_tip/Run()
	setup_register()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	service.register_cashier_share = 40
	SSeconomy.tax_rate = 10
	open_with_item(100)
	var/datum/register_cashier/seller = till()
	var/budget_before = service.account.account_balance
	var/minted_before = SSeconomy.ledger.minted
	var/burned_before = SSeconomy.ledger.burned
	TEST_ASSERT(!register.register_act(customer, "pay", list("cashier" = cashier_account.account_id, "rev" = seller.order_rev, "total" = 50)), "Сумма сменилась - оплата не проходит")
	TEST_ASSERT(!register.register_act(customer, "pay", list("cashier" = cashier_account.account_id, "rev" = seller.order_rev - 1, "total" = 100)), "Счёт правили - оплата не проходит")
	TEST_ASSERT(!register.register_act(customer, "pay", list("cashier" = customer_account.account_id, "rev" = seller.order_rev, "total" = 100)), "Кассир сменился - оплата не проходит")
	TEST_ASSERT(pay(customer), "Оплачено")
	TEST_ASSERT_EQUAL(customer_account.account_balance, 900, "Списано 100")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 40, "Доля кассира без налога")
	TEST_ASSERT_EQUAL(service.account.account_balance - budget_before, 60, "Доля отдела")
	TEST_ASSERT_EQUAL(register.total_sales, 100, "Выручка кассы")
	TEST_ASSERT(!length(seller.order), "После оплаты счёт пуст")
	TEST_ASSERT(!tip(customer, REGISTER_PRICE_MAX + 1), "Чаевые выше потолка кассы")
	TEST_ASSERT(!tip(customer, -5), "Отрицательные чаевые")
	TEST_ASSERT(!tip(cashier, 5), "Чаевые самому себе")
	TEST_ASSERT(tip(customer, 25), "Чаевые")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 65, "Чаевые кассиру целиком")
	TEST_ASSERT_EQUAL(customer_account.account_balance, 875, "Чаевые списаны")
	TEST_ASSERT(!tip(customer, 5), "Чаевые подряд ждут общий кулдаун личных платежей")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted_before, "Касса не создаёт денег")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned, burned_before, "Касса не сжигает денег")

/// Несколько штук одной позиции и разные позиции в одном счёте: сумма по количеству, потолок штук, убранная из меню позиция уходит из счёта.
/datum/unit_test/economy_register/quantity/Run()
	setup_register()
	open_with_item(20)
	TEST_ASSERT(register.register_act(cashier, "add_item", list("name" = "Сок", "price" = 15)), "Вторая позиция")
	TEST_ASSERT(order(cashier, 1, 2), "Ещё два пива")
	TEST_ASSERT(order(cashier, 2), "Сок")
	var/datum/register_cashier/seller = till()
	TEST_ASSERT_EQUAL(register.order_total(seller), 75, "Три пива и сок")
	TEST_ASSERT(!order(customer, 1), "Клиент не правит счёт")
	TEST_ASSERT(order(cashier, 1, 1000), "Количество зажато сверху")
	var/list/lines = register.order_lines(seller)
	var/list/beer = lines[1]
	TEST_ASSERT_EQUAL(beer["count"], REGISTER_ORDER_COUNT_MAX, "Потолок штук одной позиции")
	TEST_ASSERT(order(cashier, 1, -(REGISTER_ORDER_COUNT_MAX - 3)), "Лишнее пиво убрано")
	TEST_ASSERT(pay(customer), "Оплачен счёт из нескольких позиций")
	TEST_ASSERT_EQUAL(customer_account.account_balance, 925, "Списано 3 x 20 + 15")
	TEST_ASSERT(order(cashier, 2, 2), "Новый счёт")
	TEST_ASSERT(register.register_act(cashier, "remove_item", list("index" = 2)), "Сок убран из меню")
	TEST_ASSERT(!length(seller.order), "Убранная позиция ушла из счёта")
	TEST_ASSERT(order(cashier, 1, 2), "Два пива")
	TEST_ASSERT(register.register_act(cashier, "clear", list()), "Счёт очищен")
	TEST_ASSERT(!length(seller.order), "Счёт пуст")
	pay(customer)
	TEST_ASSERT_EQUAL(customer_account.account_balance, 925, "Пустой счёт не платится")

/// Два кассира: у каждого свой счёт, клиент платит выбранный, второй остаётся; коллега встаёт вторым свайпом, клиент свайпом за кассу не встаёт.
/datum/unit_test/economy_register/two_cashiers/Run()
	setup_register()
	open_with_item(20)
	var/mob/living/carbon/human/colleague = make_person("econ_test_waiter", ACCOUNT_SRV)
	register.register_act(cashier, "clear", list())
	swipe(customer)
	TEST_ASSERT(!register.is_cashier(customer), "Клиент свайпом не встаёт вторым кассиром")
	swipe(colleague)
	TEST_ASSERT(register.is_cashier(colleague), "Коллега по отделу встал вторым свайпом")
	var/mob/living/carbon/human/stranger = make_person("econ_test_stranger", null)
	TEST_ASSERT(!register.register_act(stranger, "join", list()), "Третьему места нет, пока оба на месте")
	TEST_ASSERT(order(cashier, 1, 3), "Первый кассир набрал три пива")
	TEST_ASSERT(order(colleague), "Второй кассир набрал одно")
	var/list/rows = register.ui_data(customer)["cashiers"]
	TEST_ASSERT_EQUAL(length(rows), 2, "Клиент видит оба счёта")
	var/list/first_row = rows[1]
	var/list/second_row = rows[2]
	TEST_ASSERT(first_row["total"] == 60 && second_row["total"] == 20, "Суммы счетов в окне")
	TEST_ASSERT_NULL(first_row["pay_problem"], "Счёт можно оплатить")
	var/datum/register_cashier/second = till(colleague)
	TEST_ASSERT(pay(customer, second), "Оплачен счёт второго кассира")
	TEST_ASSERT_EQUAL(customer_account.account_balance, 980, "Списано 20")
	TEST_ASSERT_EQUAL(register.order_total(till(cashier)), 60, "Счёт первого кассира цел")
	TEST_ASSERT(!length(second.order), "Счёт второго закрыт")
	var/datum/register_cashier/first = till(cashier)
	first.order_at -= REGISTER_SELECT_GRACE
	swipe(customer)
	TEST_ASSERT_EQUAL(customer_account.account_balance, 920, "Единственный открытый счёт оплачен свайпом")
	swipe(colleague)
	TEST_ASSERT(!register.is_cashier(colleague), "Второй кассир отошёл")
	TEST_ASSERT(register.is_cashier(cashier), "Первый остался")

/// Наличные: купюры берутся пачкой с округлением вверх и сдачей голочипом, голочип - ровно на сумму; денег не создаётся и не сжигается, чек сразу.
/datum/unit_test/economy_register/cash/Run()
	setup_register()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	service.register_cashier_share = 40
	open_with_item(25)
	TEST_ASSERT(order(cashier), "Два пива по 25")
	var/datum/register_cashier/seller = till()
	seller.order_at -= REGISTER_SELECT_GRACE
	var/budget_before = service.account.account_balance
	var/cash_before = SSeconomy.cash_account.account_balance
	var/minted_before = SSeconomy.ledger.minted
	var/burned_before = SSeconomy.ledger.burned
	var/obj/item/card/id/card = customer.get_active_held_item()
	customer.dropItemToGround(card)
	var/obj/item/stack/spacecash/c20/bills = allocate(/obj/item/stack/spacecash/c20, null, 5)
	customer.put_in_active_hand(bills)
	bills.melee_attack_chain(customer, register)
	TEST_ASSERT_EQUAL(bills.amount, 2, "Взяты три купюры по 20 на счёт 50")
	var/obj/item/holochip/change = locate() in customer.held_items
	TEST_ASSERT(change?.credits == 10, "Сдача 10 голочипом")
	var/obj/item/econ_receipt/receipt = find_receipt(customer)
	TEST_ASSERT(receipt && findtext(jointext(receipt.lines, " "), "Итого: 50 кр., наличными, сдача 10 кр."), "Чек наличной оплаты сразу")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 20, "Доля кассира")
	TEST_ASSERT_EQUAL(service.account.account_balance - budget_before, 30, "Доля отдела")
	TEST_ASSERT_EQUAL(cash_before - SSeconomy.cash_account.account_balance, 50, "Из наличных в обороте ушло 50")
	TEST_ASSERT_EQUAL(customer_account.account_balance, 1000, "Счёт клиента не тронут")
	TEST_ASSERT(!length(seller.order), "Счёт закрыт")
	QDEL_NULL(change)
	QDEL_NULL(receipt)
	QDEL_NULL(bills)
	TEST_ASSERT(order(cashier, 1, 2), "Новый счёт на 50")
	seller.order_at -= REGISTER_SELECT_GRACE
	var/obj/item/holochip/small = allocate(/obj/item/holochip, null, 30)
	customer.put_in_active_hand(small)
	small.melee_attack_chain(customer, register)
	TEST_ASSERT_EQUAL(small.credits, 30, "Голочипа не хватило - он цел")
	TEST_ASSERT_EQUAL(register.order_total(seller), 50, "Счёт ждёт оплаты")
	QDEL_NULL(small)
	var/obj/item/holochip/chip = allocate(/obj/item/holochip, null, 120)
	customer.put_in_active_hand(chip)
	chip.melee_attack_chain(customer, register)
	TEST_ASSERT_EQUAL(chip.credits, 70, "С голочипа списано ровно 50")
	TEST_ASSERT_EQUAL(register.total_sales, 100, "Выручка за два счёта")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted_before, "Касса не создаёт денег")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned, burned_before, "Касса не сжигает денег")
	var/atom/counter = register.drop_location()
	for(var/obj/item/econ_receipt/extra in customer.held_items + counter.contents)
		qdel(extra)
	QDEL_NULL(chip)

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
	TEST_ASSERT_EQUAL(register.order_total(till()), 100, "Счёт ждёт оплаты")

/// Кассира, замороженного или заблокированного после входа, касса не оплачивает ни картой, ни наличными; замороженный за кассу не встаёт.
/datum/unit_test/economy_register/blocked_cashier/Run()
	setup_register()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	open_with_item(100)
	var/budget_before = service.account.account_balance
	cashier_account.state = ACCOUNT_FROZEN
	TEST_ASSERT(findtext(register.charge_problem(customer_account, till()), "кассира"), "Отказ объясняет, что дело в кассире")
	TEST_ASSERT(!pay(customer), "Замороженному кассиру оплата не идёт")
	var/obj/item/holochip/chip = allocate(/obj/item/holochip, null, 200)
	TEST_ASSERT(!register.pay_cash(customer, chip, till()), "Наличными замороженному кассиру тоже нет")
	TEST_ASSERT_EQUAL(chip.credits, 200, "Голочип цел")
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
	TEST_ASSERT(!length(register.cashiers), "Замороженный счёт за кассу не встаёт")

/// Свайп: свободная касса - вход, кассир - выход, клиент - оплата, но не сразу после правки счёта.
/datum/unit_test/economy_register/card_swipe/Run()
	setup_register()
	open_with_item(100)
	swipe(customer)
	TEST_ASSERT_EQUAL(customer_account.account_balance, 1000, "Сразу после правки счёта свайп не платит")
	var/datum/register_cashier/seller = till()
	seller.order_at -= REGISTER_SELECT_GRACE
	swipe(customer)
	TEST_ASSERT_EQUAL(customer_account.account_balance, 900, "Свайп оплатил счёт")
	TEST_ASSERT(!register.is_cashier(customer), "Клиент не встал за кассу")
	swipe(cashier)
	TEST_ASSERT(!length(register.cashiers), "Кассир отошёл от кассы")
	TEST_ASSERT_EQUAL(length(register.menu), 1, "Меню осталось после выхода")

/// Меню правит только кассир; цена от 1 до потолка, длина меню ограничена; правка меню не сбивает счёт.
/datum/unit_test/economy_register/menu_rules/Run()
	setup_register()
	swipe(cashier)
	TEST_ASSERT(!register.register_act(customer, "add_item", list("name" = "Чужое", "price" = 10)), "Клиент не правит меню")
	TEST_ASSERT(!register.register_act(cashier, "add_item", list("name" = "Дорого", "price" = REGISTER_PRICE_MAX + 1)), "Потолок цены")
	TEST_ASSERT(!register.register_act(cashier, "add_item", list("name" = "Отрицательно", "price" = -5)), "Отрицательная цена")
	TEST_ASSERT(!register.register_act(cashier, "add_item", list("name" = "Даром", "price" = 0)), "Нулевая цена")
	TEST_ASSERT(!register.register_act(cashier, "add_item", list("name" = "", "price" = 5)), "Пустое название")
	for(var/i in 1 to REGISTER_MENU_MAX)
		TEST_ASSERT(register.register_act(cashier, "add_item", list("name" = "Позиция [i]", "price" = 10 + i)), "Позиция [i] добавлена")
	TEST_ASSERT(!register.register_act(cashier, "add_item", list("name" = "Лишняя", "price" = 10)), "Потолок меню")
	TEST_ASSERT(!register.register_act(customer, "remove_item", list("index" = 1)), "Клиент не убирает позицию")
	TEST_ASSERT(order(cashier, 3), "Кассир поставил позицию в счёт")
	TEST_ASSERT(register.register_act(cashier, "remove_item", list("index" = 2)), "Кассир убрал другую позицию")
	TEST_ASSERT_EQUAL(length(register.menu), REGISTER_MENU_MAX - 1, "Позиция убрана")
	TEST_ASSERT_EQUAL(register.order_total(till()), 13, "Счёт держится за ту же позицию при правке меню перед ней")

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
	TEST_ASSERT(!length(register.cashiers), "За кассу не встать картой бюджета")
	swipe(cashier, customer.get_active_held_item())
	TEST_ASSERT(!length(register.cashiers), "За кассу не встать чужой картой")
	open_with_item(100)
	sleep(REGISTER_SELECT_GRACE)
	var/budget_before = service.account.account_balance
	swipe(customer, budget_card)
	TEST_ASSERT_EQUAL(service.account.account_balance, budget_before, "Картой бюджета не заплатить")
	var/datum/register_cashier/seller = till()
	TEST_ASSERT(length(seller.order), "Счёт не оплачен")
	TEST_ASSERT(!pay(cashier), "Кассир не платит сам себе")
	TEST_ASSERT_EQUAL(service.account.account_balance, budget_before, "Бюджет не тронут")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 0, "Кассиру ничего")

/// Место ушедшего далеко или умершего кассира занимает следующий; меню остаётся, выручка новому кассиру; без отдела выручка вся кассиру.
/datum/unit_test/economy_register/takeover/Run()
	setup_register()
	var/mob/living/carbon/human/assistant = make_person("Econ Test Assistant", null)
	var/datum/bank_account/assistant_account = econ_account_of(assistant)
	var/obj/item/card/id/assistant_card = assistant.get_active_held_item()
	assistant_card.registered_name = "Econ Test Assistant"
	var/mob/living/carbon/human/third = make_person("Econ Test Third", null)
	open_with_item(30)
	register.register_act(cashier, "clear", list())
	swipe(assistant)
	TEST_ASSERT(!register.is_cashier(assistant), "Пока кассир рядом, чужой свайпом не встаёт")
	TEST_ASSERT(register.register_act(assistant, "join", list()), "Вторым кассиром встают из окна")
	TEST_ASSERT(!register.register_act(third, "join", list()), "Оба на месте - места нет")
	var/turf/far_turf = locate(min(run_loc_floor_bottom_left.x + REGISTER_CASHIER_RANGE + 1, world.maxx), run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	cashier.forceMove(far_turf)
	TEST_ASSERT(register.register_act(third, "join", list()), "Место ушедшего далеко кассира занял новый")
	TEST_ASSERT(!register.is_cashier(cashier), "Ушедший больше не кассир")
	TEST_ASSERT_EQUAL(length(register.menu), 1, "Меню осталось при перехвате")
	TEST_ASSERT(order(assistant), "Ассистент набрал счёт")
	var/datum/register_cashier/seller = till(assistant)
	TEST_ASSERT(findtext(register.payment_line(seller), "Econ Test Assistant"), "Подтверждение называет получателя: [register.payment_line(seller)]")
	TEST_ASSERT(pay(customer, seller), "Оплачено")
	TEST_ASSERT_EQUAL(assistant_account.account_balance, 30, "Без отдела выручка вся кассиру")
	TEST_ASSERT_EQUAL(cashier_account.account_balance, 0, "Прежнему кассиру ничего")
	cashier.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(!register.register_act(cashier, "join", list()), "Живых кассиров рядом не сменить")
	assistant.death()
	TEST_ASSERT(register.register_act(cashier, "join", list()), "Место умершего кассира занял новый")
	TEST_ASSERT(!register.is_cashier(assistant), "Умерший больше не кассир")

/// Касса без кассира погашена, оплатившему картой печатает чек из окна один раз, в том числе когда кассир уже отошёл.
/datum/unit_test/economy_register/receipt/Run()
	setup_register()
	TEST_ASSERT_EQUAL(register.icon_state, "bar_off", "Касса без кассира погашена")
	open_with_item(100)
	TEST_ASSERT_EQUAL(register.icon_state, "bar", "За кассой кассир - экран горит")
	TEST_ASSERT(order(cashier), "Второе пиво")
	TEST_ASSERT(pay(customer), "Оплата прошла")
	swipe(cashier)
	TEST_ASSERT(!length(register.cashiers), "Кассир отошёл")
	TEST_ASSERT(register.ui_data(customer)["receipt"], "Чек доступен и без кассира")
	econ_ui_press(customer, register, "CashRegister", "receipt")
	econ_ui_press(customer, register, "CashRegister", "receipt")
	var/list/receipts = list()
	for(var/obj/item/econ_receipt/receipt in customer.held_items)
		receipts += receipt
	TEST_ASSERT_EQUAL(length(receipts), 1, "Один чек на одну оплату")
	if(length(receipts))
		var/obj/item/econ_receipt/receipt = receipts[1]
		var/text = jointext(receipt.lines, " ")
		TEST_ASSERT(findtext(text, "Пиво x2 - 200 кр.") && findtext(text, "Итого: 200 кр."), "В чеке позиция, количество и итог: [text]")
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

/// Кассу откручивают ключом, перетаскивают на стол и прикручивают обратно.
/datum/unit_test/economy_register/wrench_onto_table/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/table_turf = get_step(start_turf, EAST)
	var/obj/structure/table/table = allocate(/obj/structure/table, table_turf)
	register = allocate(/obj/machinery/cash_register/bar, start_turf)
	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human, start_turf)
	var/obj/item/wrench/wrench = allocate(/obj/item/wrench)
	engineer.put_in_active_hand(wrench)

	TEST_ASSERT(register.anchored, "Касса с карты прикручена")
	wrench.melee_attack_chain(engineer, register)
	TEST_ASSERT(!register.anchored, "Ключ откручивает кассу")
	TEST_ASSERT(register.Move(table_turf), "Открученная касса заезжает на стол")
	TEST_ASSERT_EQUAL(register.loc, table_turf, "Касса стоит на столе")
	engineer.forceMove(start_turf)
	wrench.melee_attack_chain(engineer, register)
	TEST_ASSERT(register.anchored, "Ключ прикручивает кассу на столе")
	qdel(table)
