/datum/unit_test/economy_vending
	abstract_type = /datum/unit_test/economy_vending
	var/obj/machinery/vending/snack/machine
	var/datum/data/vending_product/record
	var/datum/bank_account/owner
	var/owner_before
	var/burned_before

/datum/unit_test/economy_vending/proc/setup_machine()
	machine = allocate(/obj/machinery/vending/snack)
	record = machine.product_records[1]
	owner = SSeconomy.get_dep_account(machine.payment_department)
	owner_before = owner.account_balance
	burned_before = SSeconomy.ledger.burned

/datum/unit_test/economy_vending/proc/buy(mob/living/buyer)
	var/datum/tgui/window = allocate(/datum/tgui, buyer, machine, "Vending")
	window.status = UI_INTERACTIVE
	usr = buyer
	machine.ui_act("vend", list("ref" = REF(record)), window)
	usr = null
	for(var/obj/item/bought in buyer.contents + machine.loc.contents)
		if(bought.type == record.product_path)
			qdel(bought)

/datum/unit_test/economy_vending/proc/wholesale_of(price)
	return round(price * SSeconomy.settings.vend_wholesale_share / 100)

/datum/unit_test/economy_vending/Destroy()
	if(owner)
		econ_test_set_balance(owner, owner_before)
	return ..()

/// Покупка в автомате: половина в бюджет отдела-владельца, половина сгорает как себестоимость.
/datum/unit_test/economy_vending/split/Run()
	setup_machine()
	var/mob/living/carbon/human/buyer = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	var/datum/bank_account/account = new("econ_test_buyer")
	account.credit(1000, ECON_ADMIN)
	card.registered_account = account
	buyer.put_in_active_hand(card)
	var/price = record.custom_price || machine.default_price
	buy(buyer)
	var/spent = 1000 - account.account_balance
	var/owner_gain = owner.account_balance - owner_before
	var/burned = SSeconomy.ledger.burned - burned_before
	card.registered_account = null
	qdel(account)
	TEST_ASSERT_EQUAL(spent, price, "Списана цена")
	TEST_ASSERT_EQUAL(owner_gain, price - wholesale_of(price), "Доля отдела")
	TEST_ASSERT_EQUAL(burned, wholesale_of(price), "Себестоимость сгорела")

/// Силикон платит из бюджета науки один раз, доля отдела-владельца та же.
/datum/unit_test/economy_vending/silicon/Run()
	setup_machine()
	var/datum/bank_account/science = SSeconomy.get_dep_account(ACCOUNT_SCI)
	var/science_saved = science.account_balance
	econ_test_set_balance(science, 1000)
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot, run_loc_floor_bottom_left)
	var/price = record.custom_price || machine.default_price
	buy(borg)
	var/science_spent = 1000 - science.account_balance
	var/owner_gain = owner.account_balance - owner_before
	econ_test_set_balance(science, science_saved)
	TEST_ASSERT_EQUAL(science_spent, price, "Наука заплатила цену один раз")
	TEST_ASSERT_EQUAL(owner_gain, price - wholesale_of(price), "Доля отдела с покупки силикона")

/// Без денег на счёте автомат отказывает и ничего не списывает.
/datum/unit_test/economy_vending/no_money/Run()
	setup_machine()
	var/mob/living/carbon/human/buyer = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	var/datum/bank_account/account = new("econ_test_poor")
	card.registered_account = account
	buyer.put_in_active_hand(card)
	var/amount_before = record.amount
	buy(buyer)
	var/amount_after = record.amount
	card.registered_account = null
	qdel(account)
	TEST_ASSERT_EQUAL(amount_after, amount_before, "Товар выдан без оплаты")
	TEST_ASSERT_EQUAL(owner.account_balance, owner_before, "Отдел получил деньги без оплаты")

/// Цены автомата следуют индексу цен.
/datum/unit_test/economy_vending_price_index/Run()
	var/obj/machinery/vending/snack/machine = allocate(/obj/machinery/vending/snack)
	var/base = initial(machine.default_price)
	var/extra_base = initial(machine.extra_price)
	var/saved = SSeconomy.price_surge_mult
	SSeconomy.price_surge_mult = 1.5
	var/index = SSeconomy.price_index()
	machine.refresh_prices()
	var/raised = machine.default_price
	var/extra_raised = machine.extra_price
	var/raised_index = machine.last_price_index
	var/list/wrong_records = list()
	for(var/datum/data/vending_product/record as anything in machine.product_records)
		var/obj/item/product = record.product_path
		if(record.custom_price != round(initial(product.custom_price) * index))
			wrong_records += record.name
	SSeconomy.price_surge_mult = saved
	machine.refresh_prices()
	TEST_ASSERT(abs(index - SSmarket.price_index * 1.5) < 0.001, "Индекс сектора [index] - не индекс рынка с поправкой на обвал")
	TEST_ASSERT_EQUAL(raised, round(base * index), "Цена выросла с индексом")
	TEST_ASSERT_EQUAL(extra_raised, round(extra_base * index), "Премиум-цена выросла с индексом")
	TEST_ASSERT(abs(raised_index - index) < 0.001, "Индекс запомнен")
	TEST_ASSERT(!length(wrong_records), "Цены товаров не по индексу: [wrong_records.Join(", ")]")
	TEST_ASSERT_EQUAL(machine.default_price, round(base * SSeconomy.price_index()), "Цена вернулась")

/// Штраф инспекции становится долгом отдела, а не вечным allow_debt.
/datum/unit_test/economy_inspection_fine_is_owed/Run()
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/owed_before = cargo.owed
	var/balance_before = cargo.account.account_balance
	var/datum/bank_account/inspection = allocate(/datum/bank_account, "econ_test_inspection")
	var/charged = sol_inspection_charge_fine(balance_before + 1000, inspection, "unit test")
	var/balance_after = cargo.account.account_balance
	var/owed_after = cargo.owed
	var/received = inspection.account_balance
	cargo.owed = owed_before
	econ_test_set_balance(cargo.account, balance_before)
	TEST_ASSERT(charged, "Штраф не взыскан")
	TEST_ASSERT_EQUAL(balance_after, 0, "Бюджет Карго отдал всё, что было")
	TEST_ASSERT_EQUAL(received, balance_before, "Инспекция получила оплаченную часть")
	TEST_ASSERT_EQUAL(owed_after - owed_before, 1000, "Остаток записан долгом")
	TEST_ASSERT(!cargo.account.allow_debt, "Бюджет не уходит в минус навсегда")
