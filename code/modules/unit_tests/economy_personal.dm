/datum/unit_test/economy_personal
	abstract_type = /datum/unit_test/economy_personal
	var/saved_tax_rate
	var/saved_treasury_balance

/datum/unit_test/economy_personal/New()
	. = ..()
	saved_tax_rate = SSeconomy.tax_rate
	var/datum/bank_account/treasury = SSeconomy.treasury()
	saved_treasury_balance = treasury.account_balance

/datum/unit_test/economy_personal/Destroy()
	SSeconomy.tax_rate = saved_tax_rate
	econ_test_set_balance(SSeconomy.treasury(), saved_treasury_balance)
	return ..()

/datum/unit_test/economy_personal/proc/make_account(holder, balance = 0)
	var/datum/bank_account/account = new(holder)
	allocated += account
	if(balance)
		econ_test_set_balance(account, balance)
	return account

/datum/unit_test/economy_personal/proc/make_person(holder, balance = 0, list/access)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = make_account(holder, balance)
	if(access)
		card.access = access
	person.put_in_active_hand(card)
	return person

/datum/unit_test/economy_personal/proc/card_of(mob/living/carbon/human/person)
	return person.get_idcard(TRUE)

/datum/unit_test/economy_personal/proc/account_of(mob/living/carbon/human/person)
	var/obj/item/card/id/card = card_of(person)
	return card.registered_account

/// Перевод между личными счетами: целиком, без налога и эмиссии; отказ себе, выше лимита, без денег, с бюджета, на бюджет, с замороженного и в кулдаун.
/datum/unit_test/economy_personal/transfer/Run()
	var/datum/bank_account/alice = make_account("Econ Test Alice", 1000)
	var/datum/bank_account/bob = make_account("Econ Test Bob")
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	SSeconomy.tax_rate = 10
	var/minted = SSeconomy.ledger.minted
	var/burned = SSeconomy.ledger.burned
	TEST_ASSERT_NULL(SSeconomy.send_transfer(alice, bob, 300), "Перевод проходит")
	TEST_ASSERT_EQUAL(bob.account_balance, 300, "Перевод дошёл целиком, без налога")
	TEST_ASSERT_EQUAL(alice.account_balance, 700, "Списано 300")
	TEST_ASSERT_NOTNULL(SSeconomy.send_transfer(alice, bob, 10), "Второй перевод сразу - кулдаун")
	COOLDOWN_RESET(alice, personal_payment_cooldown)
	TEST_ASSERT_NOTNULL(SSeconomy.send_transfer(alice, alice, 10), "Себе нельзя")
	TEST_ASSERT_NOTNULL(SSeconomy.send_transfer(alice, bob, SSeconomy.settings.transfer_max + 1), "Выше лимита нельзя")
	TEST_ASSERT_NOTNULL(SSeconomy.send_transfer(alice, bob, 0.4), "Меньше кредита нельзя")
	TEST_ASSERT_NOTNULL(SSeconomy.send_transfer(alice, bob, 701), "Больше баланса нельзя")
	TEST_ASSERT_NOTNULL(SSeconomy.send_transfer(budget, bob, 10), "С бюджета отдела личным переводом нельзя")
	TEST_ASSERT_NOTNULL(SSeconomy.send_transfer(alice, budget, 10), "На бюджет отдела личным переводом нельзя")
	alice.state = ACCOUNT_FROZEN
	var/frozen_error = SSeconomy.send_transfer(alice, bob, 10)
	alice.state = ACCOUNT_ACTIVE
	TEST_ASSERT_EQUAL(frozen_error, "Ваш счёт заморожен.", "С замороженного счёта нельзя")
	alice.transferable = FALSE
	var/blocked_source_error = SSeconomy.send_transfer(alice, bob, 10)
	alice.transferable = TRUE
	TEST_ASSERT_EQUAL(blocked_source_error, "Ваш счёт заблокирован.", "С приостановленного счёта нельзя")
	bob.transferable = FALSE
	var/blocked_target_error = SSeconomy.send_transfer(alice, bob, 10)
	bob.transferable = TRUE
	TEST_ASSERT_EQUAL(blocked_target_error, "Счёт получателя заблокирован.", "На приостановленный счёт нельзя")
	TEST_ASSERT_EQUAL(alice.account_balance, 700, "Отказы ничего не списали")
	TEST_ASSERT_EQUAL(bob.account_balance, 300, "Отказы ничего не зачислили")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted, "Переводы не печатают деньги")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned, burned, "Переводы не сжигают деньги")

/// Чаевые: целиком получателю с причиной ECON_TIP, отказы те же, общий кулдаун с переводами.
/datum/unit_test/economy_personal/tip/Run()
	var/datum/bank_account/guest = make_account("Econ Test Guest", 200)
	var/datum/bank_account/waiter = make_account("Econ Test Waiter")
	SSeconomy.tax_rate = 10
	var/tips_before = SSeconomy.ledger.by_reason[ECON_TIP] || 0
	TEST_ASSERT_NULL(SSeconomy.send_tip(guest, waiter, 50), "Чаевые проходят")
	TEST_ASSERT_EQUAL(waiter.account_balance, 50, "Чаевые без налога")
	TEST_ASSERT_EQUAL((SSeconomy.ledger.by_reason[ECON_TIP] || 0) - tips_before, 50, "Причина - чаевые")
	TEST_ASSERT_NOTNULL(SSeconomy.send_transfer(guest, waiter, 10), "После чаевых перевод ждёт кулдаун")
	COOLDOWN_RESET(guest, personal_payment_cooldown)
	TEST_ASSERT_NOTNULL(SSeconomy.send_tip(guest, guest, 5), "Чаевые себе нельзя")
	TEST_ASSERT_NOTNULL(SSeconomy.send_tip(guest, SSeconomy.get_dep_account(ACCOUNT_SRV), 5), "Чаевые бюджету нельзя")
	guest.transferable = FALSE
	var/suspended_source_error = SSeconomy.send_tip(guest, waiter, 5)
	guest.transferable = TRUE
	TEST_ASSERT_NOTNULL(suspended_source_error, "С приостановленного счёта чаевых нет")
	waiter.transferable = FALSE
	var/suspended_target_error = SSeconomy.send_tip(guest, waiter, 5)
	waiter.transferable = TRUE
	TEST_ASSERT_NOTNULL(suspended_target_error, "На приостановленный счёт чаевых нет")
	TEST_ASSERT_EQUAL(guest.account_balance, 150, "Отказы ничего не списали")

/// Поиск по имени: без учёта регистра, тёзки - никого, спящий тёзка не мешает.
/datum/unit_test/economy_personal/find_by_name/Run()
	var/datum/bank_account/unique = make_account("Econ Test Unique")
	TEST_ASSERT(SSeconomy.find_account_by_name("econ test unique ") == unique, "Имя без учёта регистра и пробелов")
	var/datum/bank_account/twin_a = make_account("Econ Test Twin")
	var/datum/bank_account/twin_b = make_account("Econ Test Twin")
	TEST_ASSERT_NULL(SSeconomy.find_account_by_name("Econ Test Twin"), "Тёзки - перевод по имени невозможен")
	twin_b.state = ACCOUNT_DORMANT
	TEST_ASSERT(SSeconomy.find_account_by_name("Econ Test Twin") == twin_a, "Спящий тёзка не мешает")
	TEST_ASSERT_NULL(SSeconomy.find_account_by_name("Econ Test Nobody"), "Нет такого")
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	TEST_ASSERT_NULL(SSeconomy.find_account_by_name(budget.account_holder), "Бюджеты не ищутся")

/// Перевод из мессенджера идёт на счёт с именем получателя, а не тому, кто держит его КПК; тёзки и бюджетная карта - отказ.
/datum/unit_test/economy_personal/messenger/Run()
	var/mob/living/carbon/human/sender = make_person("Econ Test Sender", 1000)
	var/obj/item/card/id/sender_card = card_of(sender)
	var/datum/bank_account/sender_account = sender_card.registered_account
	var/datum/bank_account/recipient_account = make_account("Econ Test Recipient")
	var/mob/living/carbon/human/thief = make_person("Econ Test Thief")
	var/datum/bank_account/thief_account = account_of(thief)

	var/obj/item/modular_computer/pda/sender_pda = allocate(/obj/item/modular_computer/pda)
	sender.drop_all_held_items()
	sender_pda.InsertID(sender_card)
	sender_pda.saved_identification = sender_account.account_holder
	sender.put_in_active_hand(sender_pda)
	var/obj/item/modular_computer/pda/recipient_pda = allocate(/obj/item/modular_computer/pda)
	recipient_pda.saved_identification = recipient_account.account_holder
	thief.put_in_inactive_hand(recipient_pda)
	var/datum/computer_file/program/messenger/sender_messenger = locate() in sender_pda.get_all_files()
	var/datum/computer_file/program/messenger/recipient_messenger = locate() in recipient_pda.get_all_files()

	send_money(sender, sender_messenger, recipient_messenger, 100)
	TEST_ASSERT_EQUAL(recipient_account.account_balance, 100, "Деньги ушли владельцу КПК по имени")
	TEST_ASSERT_EQUAL(thief_account.account_balance, 0, "Держатель чужого КПК ничего не получил")
	TEST_ASSERT_EQUAL(sender_account.account_balance, 900, "Списано 100")

	COOLDOWN_RESET(sender_account, personal_payment_cooldown)
	send_money(sender, sender_messenger, recipient_messenger, SSeconomy.settings.transfer_max + 1)
	TEST_ASSERT_EQUAL(sender_account.account_balance, 900, "Выше лимита не уходит")

	var/datum/bank_account/twin = make_account("Econ Test Recipient")
	send_money(sender, sender_messenger, recipient_messenger, 50)
	TEST_ASSERT_EQUAL(sender_account.account_balance, 900, "Тёзка у получателя - перевод не уходит")
	TEST_ASSERT_EQUAL(twin.account_balance + recipient_account.account_balance + thief_account.account_balance, 100, "Тёзки ничего не получили")

	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	var/budget_before = budget.account_balance
	econ_test_set_balance(budget, budget_before + 500)
	sender_card.registered_account = budget
	qdel(twin)
	send_money(sender, sender_messenger, recipient_messenger, 50)
	sender_card.registered_account = sender_account
	var/budget_left = budget.account_balance
	econ_test_set_balance(budget, budget_before)
	TEST_ASSERT_EQUAL(budget_left, budget_before + 500, "Бюджетная карта в КПК не переводит деньги отдела")
	TEST_ASSERT_EQUAL(recipient_account.account_balance, 100, "С бюджета ничего не дошло")

/datum/unit_test/economy_personal/proc/send_money(mob/living/carbon/human/sender, datum/computer_file/program/messenger/from, datum/computer_file/program/messenger/to_messenger, amount)
	var/datum/tgui/window = allocate(/datum/tgui, sender, from.computer, "NtosMessenger")
	window.status = UI_INTERACTIVE
	usr = sender
	from.ui_act("PDA_sendMoney", list("ref" = REF(to_messenger), "amount" = "[amount]", "currency" = "credits"), window)
	usr = null

/datum/unit_test/economy_personal/proc/make_stall(rentable = TRUE)
	var/obj/machinery/vending/custom/stall = allocate(/obj/machinery/vending/custom)
	stall.set_machine_stat(stall.machine_stat & ~NOPOWER)
	stall.rentable = rentable
	return stall

/datum/unit_test/economy_personal/proc/stall_listens_to(datum/bank_account/account)
	var/list/lookup = account.comp_lookup
	return lookup && lookup[COMSIG_PARENT_QDELETING]

/datum/unit_test/economy_personal/proc/swipe(mob/living/carbon/human/person, obj/machinery/vending/custom/stall, times = 2)
	var/obj/item/card/id/card = card_of(person)
	for(var/swipe_number in 1 to times)
		card.melee_attack_chain(person, stall)

/datum/unit_test/economy_personal/proc/stock(mob/living/carbon/human/renter, obj/machinery/vending/custom/stall, price)
	var/obj/item/trash/can/goods = allocate(/obj/item/trash/can)
	goods.custom_price = price
	renter.swap_hand()
	renter.put_in_active_hand(goods)
	goods.melee_attack_chain(renter, stall)
	renter.swap_hand()
	return goods

/datum/unit_test/economy_personal/proc/buy(mob/living/carbon/human/buyer, obj/machinery/vending/custom/stall, obj/item/goods)
	var/datum/tgui/window = allocate(/datum/tgui, buyer, stall, "Vending")
	window.status = UI_INTERACTIVE
	usr = buyer
	stall.ui_act("dispense", list("item" = format_text(goods.name)), window)
	usr = null

/// Аренда прилавка двумя свайпами карты: плата в казну, выручка арендатору, чужой и бюджетной картой не арендовать и не платить.
/datum/unit_test/economy_personal/stall_rent/Run()
	var/obj/machinery/vending/custom/stall = make_stall()
	var/fee = SSeconomy.settings.stall_rent_fee
	var/mob/living/carbon/human/renter = make_person("Econ Test Renter", fee + 100)
	var/mob/living/carbon/human/buyer = make_person("Econ Test Buyer", 1000)
	var/datum/bank_account/renter_account = account_of(renter)
	var/datum/bank_account/buyer_account = account_of(buyer)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/treasury_before = treasury.account_balance

	stall.set_machine_stat(stall.machine_stat | NOPOWER)
	swipe(renter, stall)
	stall.set_machine_stat(stall.machine_stat & ~NOPOWER)
	TEST_ASSERT_NULL(stall.linked_account, "Обесточенный прилавок не сдаётся")
	TEST_ASSERT_EQUAL(renter_account.account_balance, fee + 100, "За обесточенный прилавок ничего не списано")

	var/obj/item/card/id/renter_card = card_of(renter)
	var/obj/item/card/id/other_card = allocate(/obj/item/card/id)
	other_card.registered_account = make_account("Econ Test Other Card", fee)
	swipe(renter, stall, 1)
	renter_card.registered_account = other_card.registered_account
	swipe(renter, stall, 1)
	renter_card.registered_account = renter_account
	TEST_ASSERT_NULL(stall.linked_account, "Свайп другой картой после первого не арендует без показа условий")
	TEST_ASSERT_EQUAL(other_card.registered_account.account_balance, fee, "С другой карты ничего не списано")

	swipe(renter, stall, 1)
	TEST_ASSERT_NULL(stall.linked_account, "Первый свайп только называет цену")
	TEST_ASSERT_EQUAL(renter_account.account_balance, fee + 100, "Первый свайп ничего не списал")
	swipe(renter, stall, 1)
	TEST_ASSERT(stall.linked_account == renter_account, "Второй свайп арендует прилавок")
	TEST_ASSERT_EQUAL(treasury.account_balance - treasury_before, fee, "Плата за аренду в казну")
	TEST_ASSERT_EQUAL(renter_account.account_balance, 100, "Плата списана с арендатора")
	TEST_ASSERT_EQUAL(round((stall.rented_until - world.time) / (1 MINUTES), 1), SSeconomy.settings.stall_rent_minutes, "Срок аренды из настроек")
	TEST_ASSERT_NOTNULL(SSeconomy.rent_stall(stall, renter_account), "Арендованный прилавок второй раз не сдаётся")
	swipe(buyer, stall)
	TEST_ASSERT(stall.linked_account == renter_account, "Чужой свайп не перехватывает аренду")
	TEST_ASSERT_EQUAL(buyer_account.account_balance, 1000, "Чужой свайп ничего не списал")

	var/obj/item/sold = stock(renter, stall, 40)
	var/obj/item/unsold = stock(renter, stall, 60)
	TEST_ASSERT(sold.loc == stall && unsold.loc == stall, "Арендатор выставил товар")
	buy(buyer, stall, sold)
	TEST_ASSERT_EQUAL(buyer_account.account_balance, 960, "Покупатель заплатил цену")
	TEST_ASSERT_EQUAL(renter_account.account_balance, 140, "Выручка на счёт арендатора")

	var/mob/living/carbon/human/budget_holder = make_person("Econ Test Budget Holder")
	var/obj/item/card/id/budget_card = card_of(budget_holder)
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	var/budget_before = budget.account_balance
	econ_test_set_balance(budget, budget_before + 500)
	budget_card.registered_account = budget
	buy(budget_holder, stall, unsold)
	var/budget_left = budget.account_balance
	econ_test_set_balance(budget, budget_before)
	TEST_ASSERT_EQUAL(budget_left, budget_before + 500, "Бюджетной картой в прилавке не платят")
	TEST_ASSERT(unsold.loc == stall, "Товар не выдан за бюджет")

	buyer_account.state = ACCOUNT_FROZEN
	buy(buyer, stall, unsold)
	buyer_account.state = ACCOUNT_ACTIVE
	TEST_ASSERT(unsold.loc == stall, "Замороженный покупатель товар не получил")
	TEST_ASSERT_EQUAL(buyer_account.account_balance, 960, "С замороженного счёта не списано")

	renter_account.transferable = FALSE
	buy(buyer, stall, unsold)
	renter_account.transferable = TRUE
	TEST_ASSERT(unsold.loc == stall, "Приостановленный арендатор не продаёт")
	TEST_ASSERT_EQUAL(buyer_account.account_balance, 960, "Без продажи не списано")

	renter_account.state = ACCOUNT_DORMANT
	buy(buyer, stall, unsold)
	renter_account.state = ACCOUNT_ACTIVE
	TEST_ASSERT_EQUAL(renter_account.account_balance, 200, "Спящий арендатор до конца срока получает выручку")

	var/obj/item/restocked = stock(renter, stall, 10)
	var/turf/stall_turf = get_turf(stall)
	qdel(stall)
	TEST_ASSERT(restocked.loc == stall_turf, "Товар удалённого прилавка выпал на пол")
	TEST_ASSERT(!stall_listens_to(renter_account), "Удалённый прилавок отписан от счёта арендатора")

/// Аренда истекла: продажи закрыты, другой не арендует с чужим товаром, ГП освобождает прилавок и товар выпадает; удалённый счёт отвязывается.
/datum/unit_test/economy_personal/stall_expiry/Run()
	var/obj/machinery/vending/custom/stall = make_stall()
	var/fee = SSeconomy.settings.stall_rent_fee
	var/mob/living/carbon/human/renter = make_person("Econ Test Renter", fee)
	var/mob/living/carbon/human/buyer = make_person("Econ Test Buyer", fee + 100)
	var/mob/living/carbon/human/manager = make_person("Econ Test Captain", 0, list(ACCESS_CAPTAIN))
	var/datum/bank_account/renter_account = account_of(renter)
	var/datum/bank_account/buyer_account = account_of(buyer)
	swipe(renter, stall)
	TEST_ASSERT(stall.linked_account == renter_account, "Арендовано")
	var/obj/item/goods = stock(renter, stall, 50)
	stall.rented_until = world.time - 1

	buy(buyer, stall, goods)
	TEST_ASSERT(goods.loc == stall, "После срока товар не продаётся")
	TEST_ASSERT_EQUAL(buyer_account.account_balance, fee + 100, "После срока деньги не списаны")
	swipe(buyer, stall)
	TEST_ASSERT(stall.linked_account == renter_account, "С чужим товаром внутри прилавок не сдаётся другому")
	TEST_ASSERT_EQUAL(buyer_account.account_balance, fee + 100, "Отказ в аренде ничего не списал")

	swipe(manager, stall)
	TEST_ASSERT_NULL(stall.linked_account, "Капитан освободил прилавок")
	TEST_ASSERT(goods.loc == stall.drop_location(), "Товар выпал наружу")
	TEST_ASSERT_EQUAL(stall.loaded_items, 0, "Счётчик товаров сброшен")

	swipe(buyer, stall)
	TEST_ASSERT(stall.linked_account == buyer_account, "Освобождённый прилавок арендует другой")
	var/obj/item/card/id/buyer_card = card_of(buyer)
	buyer_card.registered_account = null
	qdel(buyer_account)
	TEST_ASSERT_NULL(stall.linked_account, "Удалённый счёт отвязан от прилавка")
	TEST_ASSERT_EQUAL(stall.rented_until, 0, "Аренда удалённого счёта снята")

/// Собранный автомат: бесплатно привязывается к первому личному счёту, платят только личные счета, приостановленный владелец не продаёт.
/datum/unit_test/economy_personal/stall_free/Run()
	var/obj/machinery/vending/custom/built = allocate(/obj/machinery/vending/custom)
	TEST_ASSERT(!built.rentable, "Собранный вне карты автомат не сдаётся в аренду")
	built.set_machine_stat(built.machine_stat & ~NOPOWER)
	var/mob/living/carbon/human/owner = make_person("Econ Test Owner")
	var/mob/living/carbon/human/buyer = make_person("Econ Test Buyer", 100)
	var/datum/bank_account/owner_account = account_of(owner)
	var/datum/bank_account/buyer_account = account_of(buyer)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/treasury_before = treasury.account_balance
	swipe(owner, built, 1)
	TEST_ASSERT(built.linked_account == owner_account, "Первый свайп бесплатно привязал автомат")
	TEST_ASSERT_EQUAL(treasury.account_balance, treasury_before, "Привязка без платы")
	swipe(buyer, built)
	TEST_ASSERT(built.linked_account == owner_account, "Чужой свайп не перехватывает автомат")
	TEST_ASSERT_NOTNULL(SSeconomy.rent_stall(built, buyer_account), "Собранный автомат не арендуется")

	var/obj/item/goods = stock(owner, built, 30)
	owner_account.transferable = FALSE
	buy(buyer, built, goods)
	owner_account.transferable = TRUE
	TEST_ASSERT(goods.loc == built, "Приостановленный владелец не продаёт")
	buy(buyer, built, goods)
	TEST_ASSERT_EQUAL(buyer_account.account_balance, 70, "Покупатель заплатил")
	TEST_ASSERT_EQUAL(owner_account.account_balance, 30, "Выручка владельцу без аренды")

/// Стенд оплаты и витрина не берут деньги с бюджетной карты, не платят приостановленному продавцу, с личной карты берут.
/datum/unit_test/economy_personal/budget_card_sinks/Run()
	var/mob/living/carbon/human/seller = make_person("Econ Test Seller")
	var/datum/bank_account/seller_account = account_of(seller)
	var/mob/living/carbon/human/customer = make_person("Econ Test Customer", 200)
	var/datum/bank_account/customer_account = account_of(customer)
	var/mob/living/carbon/human/budget_holder = make_person("Econ Test Budget Holder")
	var/obj/item/card/id/budget_card = card_of(budget_holder)
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	var/budget_before = budget.account_balance
	econ_test_set_balance(budget, budget_before + 500)
	budget_card.registered_account = budget

	var/obj/machinery/paystand/stand = allocate(/obj/machinery/paystand)
	stand.my_card = card_of(seller)
	stand.force_fee = 50
	budget_card.melee_attack_chain(budget_holder, stand)
	var/obj/item/card/id/customer_card = card_of(customer)
	seller_account.transferable = FALSE
	customer_card.melee_attack_chain(customer, stand)
	seller_account.transferable = TRUE
	TEST_ASSERT_EQUAL(customer_account.account_balance, 200, "Приостановленному продавцу на стенде не платят")
	customer_card.melee_attack_chain(customer, stand)
	stand.my_card = null

	var/obj/structure/displaycase/forsale/tray = allocate(/obj/structure/displaycase/forsale)
	var/obj/item/goods = allocate(/obj/item/trash/can, tray)
	tray.showpiece = goods
	tray.payments_acc = seller_account
	tray.sale_price = 30
	var/datum/tgui/window = allocate(/datum/tgui, budget_holder, tray, "Vendatray")
	window.status = UI_INTERACTIVE
	usr = budget_holder
	tray.ui_act("Buy", list(), window)
	usr = null
	var/budget_left = budget.account_balance
	econ_test_set_balance(budget, budget_before)
	TEST_ASSERT_EQUAL(budget_left, budget_before + 500, "Бюджетной картой на стенде и витрине не платят")
	TEST_ASSERT(tray.showpiece == goods, "Витрина не отдала товар за бюджет")
	seller_account.transferable = FALSE
	window = allocate(/datum/tgui, customer, tray, "Vendatray")
	window.status = UI_INTERACTIVE
	usr = customer
	tray.ui_act("Buy", list(), window)
	usr = null
	seller_account.transferable = TRUE
	TEST_ASSERT(tray.showpiece == goods, "Витрина приостановленного продавца не продаёт")
	TEST_ASSERT_EQUAL(customer_account.account_balance, 150, "Личной картой на стенде платят")
	TEST_ASSERT_EQUAL(seller_account.account_balance, 50, "Продавцу дошла только оплата с личного счёта")

/datum/unit_test/economy_personal/proc/map_load_stall(turf/where)
	SSatoms.map_loader_begin()
	var/obj/machinery/vending/custom/stall = new(where)
	SSatoms.map_loader_stop()
	allocated += stall
	SSatoms.InitializeAtoms(list(stall))
	return stall

/// Прилавок, поставленный загрузчиком карты на станционном z, сдаётся в аренду; на z резервации и построенный во время загрузки шаблона - нет.
/datum/unit_test/economy_personal/stall_mapload/Run()
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	var/turf/station_turf = locate(1, 1, station_levels[1])
	var/obj/machinery/vending/custom/station_stall = map_load_stall(station_turf)
	TEST_ASSERT(station_stall.rentable, "Прилавок с карты станции сдаётся в аренду")
	var/obj/machinery/vending/custom/reserved_stall = map_load_stall(run_loc_floor_bottom_left)
	TEST_ASSERT(!reserved_stall.rentable, "Прилавок вне станционного z бесплатный")
	var/saved_mode = SSatoms.initialized
	SSatoms.initialized = INITIALIZATION_INNEW_MAPLOAD
	var/obj/machinery/vending/custom/built = new(station_turf)
	SSatoms.initialized = saved_mode
	allocated += built
	TEST_ASSERT(!built.rentable, "Построенный во время загрузки шаблона автомат бесплатный")
