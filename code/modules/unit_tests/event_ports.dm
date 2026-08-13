// Тесты портированных малых событий (Market Crash, Shipping Error, Shuttle Insurance).
// Проверяются экономические примитивы и интеграции - визуальные/спавн-события
// (почта, парковка, космоцвета, конденсат) покрываются штатными контрактными
// тестами директора и create_and_destroy.

/// Обвал рынка: множитель влияет на inflation_value(), kill() гарантированно
/// откатывает цены даже в обход end() (админ снял событие).
/datum/unit_test/market_crash_price_surge/Run()
	var/old_mult = SSeconomy.price_surge_mult
	SSeconomy.price_surge_mult = 1
	var/base_inflation = SSeconomy.inflation_value()

	var/datum/round_event/market_crash/crash = new(FALSE)
	crash.start()
	TEST_ASSERT(SSeconomy.price_surge_mult >= 2, "Market crash start() must raise the price surge multiplier (got [SSeconomy.price_surge_mult])")
	TEST_ASSERT(SSeconomy.inflation_value() >= base_inflation * 2, "Inflation value must reflect the surge multiplier (base [base_inflation], surged [SSeconomy.inflation_value()])")

	crash.kill()
	TEST_ASSERT_EQUAL(SSeconomy.price_surge_mult, 1, "Market crash kill() must reset the price surge multiplier")
	qdel(crash)
	SSeconomy.price_surge_mult = old_mult

/// Ошибка отгрузки: start() ставит ровно один валидный заказ в очередь карго.
/datum/unit_test/shipping_error_queues_order/Run()
	TEST_ASSERT(length(SSshuttle.supply_packs), "Premise broken: SSshuttle.supply_packs must be populated in CI")
	var/before = length(SSshuttle.shoppinglist)

	var/datum/round_event/shipping_error/event_stub = new(FALSE)
	event_stub.start()
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), before + 1, "Shipping error must queue exactly one order")

	var/datum/supply_order/order = SSshuttle.shoppinglist[length(SSshuttle.shoppinglist)]
	TEST_ASSERT(!order.pack.hidden && !order.pack.contraband && !order.pack.special && !order.pack.DropPodOnly, "Shipping error must not order hidden/contraband/special packs (got [order.pack.name])")
	TEST_ASSERT(order.pack.cost >= 200 && order.pack.cost <= 3000, "Shipping error pack cost must stay within the nuisance band (got [order.pack.cost] for [order.pack.name])")
	TEST_ASSERT_NULL(order.paying_account, "Shipping error orders must be paid by the department budget, not a personal account")

	SSshuttle.shoppinglist -= order
	qdel(order)
	event_stub.kill()
	qdel(event_stub)

/// Страховка шаттла: застрахованная катастрофа не подменяет шаттл и не съедает
/// слот покупки, а лишь выплачивает премию с ЦК.
/datum/unit_test/shuttle_insurance_covers_catastrophe/Run()
	var/old_insurance = SSshuttle.shuttle_insurance
	var/old_purchased = SSshuttle.shuttle_purchased
	var/datum/bank_account/cargo_account = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/old_balance = cargo_account ? cargo_account.account_balance : 0

	SSshuttle.shuttle_insurance = TRUE
	// setup() зовётся из New(): со страховкой шаттл-замена не выбирается вовсе
	var/datum/round_event/shuttle_catastrophe/catastrophe = new(FALSE)
	TEST_ASSERT_NULL(catastrophe.new_shuttle, "Insured catastrophe must not roll a replacement shuttle in setup()")

	catastrophe.start()
	TEST_ASSERT_EQUAL(SSshuttle.shuttle_purchased, old_purchased, "Insured catastrophe must not consume the shuttle purchase slot")
	if(cargo_account)
		TEST_ASSERT(cargo_account.account_balance > old_balance, "Insured catastrophe must award a cargo bonus")
		cargo_account.adjust_money(old_balance - cargo_account.account_balance)

	catastrophe.kill()
	qdel(catastrophe)
	SSshuttle.shuttle_insurance = old_insurance
	SSshuttle.shuttle_purchased = old_purchased
