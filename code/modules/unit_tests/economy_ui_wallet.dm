/datum/unit_test/economy_ui_wallet
	abstract_type = /datum/unit_test/economy_ui_wallet
	var/list/stashed_contracts
	var/saved_tax_rate

/datum/unit_test/economy_ui_wallet/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	saved_tax_rate = SSeconomy.tax_rate

/datum/unit_test/economy_ui_wallet/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	SSeconomy.tax_rate = saved_tax_rate
	QDEL_LIST(GLOB.econ_pay_requests)
	return ..()

/datum/unit_test/economy_ui_wallet/proc/make_account(holder, balance = 0)
	var/datum/bank_account/account = new(holder)
	allocated += account
	if(balance)
		econ_test_set_balance(account, balance)
	return account

/// Человек с КПК в руке, в КПК - его ID-карта со счётом.
/datum/unit_test/economy_ui_wallet/proc/make_owner(holder, balance = 0)
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = make_account(holder, balance)
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda)
	pda.InsertID(card)
	owner.put_in_active_hand(pda)
	return owner

/datum/unit_test/economy_ui_wallet/proc/wallet_of(mob/living/carbon/human/owner)
	var/obj/item/modular_computer/pda/pda = owner.get_active_held_item()
	return locate(/datum/computer_file/program/wallet) in pda.get_all_files()

/datum/unit_test/economy_ui_wallet/proc/account_of(mob/living/carbon/human/owner)
	var/obj/item/modular_computer/pda/pda = owner.get_active_held_item()
	return pda.stored_id.registered_account

/datum/unit_test/economy_ui_wallet/proc/press(mob/living/carbon/human/owner, action, list/params = list())
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/datum/tgui/window = allocate(/datum/tgui, owner, wallet, "NtosWallet")
	window.status = UI_INTERACTIVE
	usr = owner
	wallet.ui_act(action, params, window)
	usr = null
	return wallet.message

/// КПК ставится с кошельком вместо старого NT Pay; данные окна - баланс, номер, состояние и зарплата.
/datum/unit_test/economy_ui_wallet/data/Run()
	var/mob/living/carbon/human/owner = make_owner("Econ Wallet Owner", 1500)
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	TEST_ASSERT_NOTNULL(wallet, "Кошелёк установлен в КПК")
	var/datum/bank_account/account = account_of(owner)
	account.owed_wages = 40
	SSeconomy.tax_rate = 12
	var/list/data = wallet.wallet_data(owner)
	TEST_ASSERT(data["has_account"], "Счёт найден по карте в КПК")
	TEST_ASSERT(data["from_card"], "Счёт взят с карты")
	TEST_ASSERT_EQUAL(data["balance"], 1500, "Баланс")
	TEST_ASSERT_EQUAL(data["number"], account.account_id, "Номер счёта")
	TEST_ASSERT_EQUAL(data["state"], "active", "Состояние")
	var/list/wage = data["wage"]
	TEST_ASSERT_EQUAL(wage["tax_rate"], 12, "Налог")
	TEST_ASSERT_EQUAL(wage["owed"], 40, "Долг отдела")
	TEST_ASSERT_EQUAL(wage["tax_nt_share"], SSeconomy.tax_nt_share_now(), "Доля NT в налоге")
	TEST_ASSERT_EQUAL(wage["tax_mood_progress"], SSeconomy.tax_mood_progress(), "Сколько налог держится в полосе")
	var/list/static_data = wallet.wallet_static_data()
	TEST_ASSERT_EQUAL(static_data["transfer_max"], SSeconomy.settings.transfer_max, "Лимит перевода из настроек")
	TEST_ASSERT_EQUAL(static_data["wage_floor"], SSeconomy.settings.wage_floor, "Гарантированный минимум")
	TEST_ASSERT_EQUAL(static_data["name_max"], MAX_NAME_LEN, "Длина имени получателя")
	TEST_ASSERT_EQUAL(static_data["audit_rights"], SSeconomy.audit_rights_text(), "Кто проводит аудит")
	account.bind_owner(owner)
	data = wallet.wallet_data(owner)
	wage = data["wage"]
	TEST_ASSERT(wage["floor_only"], "Экипажу без оклада кошелёк не показывает минимум NT")

/// Без карты в КПК кошелёк берёт собственный счёт игрока, без счёта - отказы с объяснением.
/datum/unit_test/economy_ui_wallet/no_card/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda)
	owner.put_in_active_hand(pda)
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/datum/econ_contract/contract = new /datum/econ_contract/activity/service_dishes(ACCOUNT_SRV)
	service.contracts += contract
	var/list/data = wallet.wallet_data(owner)
	TEST_ASSERT(!data["has_account"], "Без карты и своего счёта счёта нет")
	var/refusal = press(owner, "take", list("uid" = contract.uid))
	TEST_ASSERT_NULL(contract.taker, "Без счёта контракт не взят")
	TEST_ASSERT_EQUAL(refusal, "Нет банковского счёта.", "Отказ объяснён")
	var/datum/bank_account/own = make_account("Econ Wallet Cardless", 70)
	owner.account_id = own.account_id
	data = wallet.wallet_data(owner)
	TEST_ASSERT(data["has_account"], "Найден собственный счёт игрока")
	TEST_ASSERT(!data["from_card"], "Счёт не с карты")
	TEST_ASSERT_EQUAL(data["number"], own.account_id, "Номер своего счёта")
	TEST_ASSERT_EQUAL(data["message"], "", "Ответ прежнего счёта стёрт")

/// Окно показывает 20 последних операций, а не половину.
/datum/unit_test/economy_ui_wallet/history_limit/Run()
	var/mob/living/carbon/human/owner = make_owner("Econ Wallet Busy")
	var/datum/bank_account/own = account_of(owner)
	for(var/operation in 1 to 25)
		SSeconomy.move(null, own, operation, ECON_ADMIN, memo = "Операция [operation]")
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/list/data = wallet.wallet_data(owner)
	var/list/history = data["history"]
	TEST_ASSERT_EQUAL(length(history), 20, "В окне 20 операций")
	var/list/oldest = history[1]
	var/list/newest = history[20]
	TEST_ASSERT_EQUAL(oldest["label"], "Операция 6", "Старейшая из двадцати последних")
	TEST_ASSERT_EQUAL(newest["label"], "Операция 25", "Последняя операция")

/// Перевод по имени и по номеру через ui_act: доходит, история пишется, строка вместо числа и бюджет отвергаются.
/datum/unit_test/economy_ui_wallet/transfer/Run()
	var/mob/living/carbon/human/owner = make_owner("Econ Wallet Payer", 500)
	var/datum/bank_account/own = account_of(owner)
	var/datum/bank_account/other = make_account("Econ Wallet Target")
	press(owner, "transfer", list("target" = "econ wallet target", "amount" = 200, "memo" = "за обед"))
	TEST_ASSERT_EQUAL(other.account_balance, 200, "Перевод по имени дошёл")
	TEST_ASSERT_EQUAL(own.account_balance, 300, "Списано 200")
	COOLDOWN_RESET(own, personal_payment_cooldown)
	var/bad_amount = press(owner, "transfer", list("target" = "[other.account_id]", "amount" = "сто"))
	TEST_ASSERT_EQUAL(bad_amount, "Неверная сумма.", "Строка вместо суммы отвергнута")
	press(owner, "transfer", list("target" = "[other.account_id]", "amount" = "50"))
	TEST_ASSERT_EQUAL(other.account_balance, 250, "Перевод по номеру дошёл")
	COOLDOWN_RESET(own, personal_payment_cooldown)
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	var/budget_before = budget.account_balance
	press(owner, "transfer", list("target" = "[budget.account_id]", "amount" = 10))
	TEST_ASSERT_EQUAL(budget.account_balance, budget_before, "На бюджет отдела личным переводом нельзя")
	press(owner, "transfer", list("target" = "Econ Wallet Nobody", "amount" = 10))
	TEST_ASSERT_EQUAL(own.account_balance, 250, "Отказы ничего не списали")
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/list/data = wallet.wallet_data(owner)
	var/list/sent
	for(var/list/entry as anything in data["history"])
		if(entry["amount"] == -200)
			sent = entry
	TEST_ASSERT_NOTNULL(sent, "История: перевод со знаком минус")
	TEST_ASSERT(findtext(sent["label"], "за обед"), "История: назначение перевода")
	TEST_ASSERT(findtext(sent["counterparty"], "[other.account_id]"), "История: номер второй стороны")

/// Чаевые через ui_act доходят без налога и делят кулдаун с переводом.
/datum/unit_test/economy_ui_wallet/tip/Run()
	var/mob/living/carbon/human/owner = make_owner("Econ Wallet Guest", 300)
	var/datum/bank_account/own = account_of(owner)
	var/datum/bank_account/waiter = make_account("Econ Wallet Waiter")
	SSeconomy.tax_rate = 10
	press(owner, "tip", list("target" = "Econ Wallet Waiter", "amount" = 40))
	TEST_ASSERT_EQUAL(waiter.account_balance, 40, "Чаевые целиком, без налога")
	var/cooldown_message = press(owner, "transfer", list("target" = "Econ Wallet Waiter", "amount" = 10))
	TEST_ASSERT(findtext(cooldown_message, "Слишком часто"), "После чаевых перевод ждёт общий кулдаун")
	TEST_ASSERT_EQUAL(own.account_balance, 260, "Списаны только чаевые")
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/list/data = wallet.wallet_data(owner)
	TEST_ASSERT(data["cooldown_left"] >= 1, "Окно видит остаток кулдауна")

/// Замороженный счёт: окно показывает кто и почему, перевод отвергнут; заморозку ЦК окно называет отдельно.
/datum/unit_test/economy_ui_wallet/frozen/Run()
	var/mob/living/carbon/human/owner = make_owner("Econ Wallet Suspect", 300)
	var/datum/bank_account/own = account_of(owner)
	var/datum/bank_account/other = make_account("Econ Wallet Partner")
	own.state = ACCOUNT_FROZEN
	own.frozen_by = "Econ Auditor, Detective"
	own.freeze_reason = "дробление"
	var/refusal = press(owner, "transfer", list("target" = "Econ Wallet Partner", "amount" = 100))
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/list/data = wallet.wallet_data(owner)
	own.frozen_by = ECON_ADMIN_FROZEN_BY
	var/list/admin_data = wallet.wallet_data(owner)
	own.state = ACCOUNT_ACTIVE
	TEST_ASSERT_EQUAL(refusal, "Ваш счёт заморожен.", "Перевод с замороженного отвергнут")
	TEST_ASSERT_EQUAL(other.account_balance, 0, "Ничего не дошло")
	TEST_ASSERT_EQUAL(data["state"], "frozen", "Окно видит заморозку")
	TEST_ASSERT_EQUAL(data["frozen_by"], "Econ Auditor, Detective", "Кто заморозил")
	TEST_ASSERT_EQUAL(data["freeze_reason"], "дробление", "Почему")
	TEST_ASSERT_EQUAL(data["freeze_source"], "финансовым аудитом (Econ Auditor, Detective)", "Заморожен аудитом")
	TEST_ASSERT_EQUAL(admin_data["freeze_source"], "Центральным командованием NT, разморозить может только ЦК", "Заморожен ЦК")

/// Контракт берётся из кошелька по uid числом или строкой, второй - отказ по лимиту.
/datum/unit_test/economy_ui_wallet/take/Run()
	var/mob/living/carbon/human/owner = make_owner("Econ Wallet Worker")
	var/datum/bank_account/own = account_of(owner)
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/datum/econ_contract/first = new /datum/econ_contract/activity/service_dishes(ACCOUNT_SRV)
	var/datum/econ_contract/second = new /datum/econ_contract/activity/service_cleaning(ACCOUNT_SRV)
	service.contracts += first
	service.contracts += second
	press(owner, "take", list("uid" = "[first.uid]"))
	TEST_ASSERT(first.taker == own, "Контракт взят по uid строкой")
	var/refusal = press(owner, "take", list("uid" = second.uid))
	TEST_ASSERT_NULL(second.taker, "Второй контракт не взят")
	TEST_ASSERT_EQUAL(refusal, "У вас уже взято контрактов: 1 из 1. Больше одновременно позволяет репутация подрядчика.", "Отказ объяснён")
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/list/data = wallet.wallet_data(owner)
	var/board_contracts = 0
	var/personal_offers = 0
	for(var/list/entry as anything in data["contracts"])
		if(entry["kind"] == "personal")
			personal_offers++
		else
			board_contracts++
	TEST_ASSERT_EQUAL(board_contracts, 2, "Окно видит доску контрактов")
	TEST_ASSERT_EQUAL(personal_offers, SSeconomy.contracts_started ? SSeconomy.settings.contract_personal_offers : 0, "Окно видит личные заказы владельца")
	TEST_ASSERT_EQUAL(data["my_account"], own.account_id, "Окно знает свой номер для доски")

/// Акции на счёте видны в кошельке со стоимостью по текущей цене.
/datum/unit_test/economy_ui_wallet/shares/Run()
	var/mob/living/carbon/human/owner = make_owner("Econ Wallet Investor")
	var/datum/bank_account/own = account_of(owner)
	var/ticker = SSmarket.companies[1]
	var/datum/stock_company/company = SSmarket.get_company(ticker)
	own.shares[ticker] = 3
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/list/data = wallet.wallet_data(owner)
	var/list/shares = data["shares"]
	var/list/entry = shares[1]
	TEST_ASSERT_EQUAL(entry["ticker"], ticker, "Тикер")
	TEST_ASSERT_EQUAL(entry["count"], 3, "Количество")
	TEST_ASSERT_EQUAL(entry["value"], round(company.price * 3), "Стоимость")
	TEST_ASSERT_EQUAL(data["portfolio"], round(company.price * 3), "Портфель")

/// Без клиента метадоллары недоступны: снятие ничего не создаёт.
/datum/unit_test/economy_ui_wallet/metadollars_no_client/Run()
	var/mob/living/carbon/human/owner = make_owner("Econ Wallet Ghostless")
	var/turf/spot = get_turf(owner)
	var/refusal = press(owner, "md_withdraw", list("amount" = 5))
	TEST_ASSERT_NULL(locate(/obj/item/stack/metadollar) in spot, "Стопка не появилась")
	TEST_ASSERT(!owner.is_holding_item_of_type(/obj/item/stack/metadollar), "В руках стопки нет")
	TEST_ASSERT_EQUAL(refusal, "Нет связи с вашим счётом метадолларов.", "Отказ объяснён")
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/list/data = wallet.wallet_data(owner)
	TEST_ASSERT(!data["metadollars_available"], "Вкладка M$ знает, что связи нет")

/// Человек в клетке dx, dy от левого нижнего угла пола, с ID-картой в руке и счётом account; card_name - имя на карте.
/datum/unit_test/economy_ui_wallet/proc/make_bystander(datum/bank_account/account, card_name, dx, dy)
	var/turf/spot = locate(run_loc_floor_bottom_left.x + dx, run_loc_floor_bottom_left.y + dy, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human, spot)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = card_name
	card.assignment = "Bartender"
	card.registered_account = account
	person.put_in_hands(card)
	return person

/// Оплата человеку рядом: кошелёк видит людей в паре шагов по имени с их ID-карты, а не по имени владельца счёта; перевод доходит с комментарием, получатель видит имя с карты плательщика; дальний, ушедший и сумма выше лимита - отказ без списания; анонимный счёт на карте принимает оплату.
/datum/unit_test/economy_ui_wallet/pay_nearby/Run()
	var/mob/living/carbon/human/owner = make_owner("Econ Nearby Payer Real", 100000)
	var/datum/bank_account/own = account_of(owner)
	var/obj/item/modular_computer/pda/pda = owner.get_active_held_item()
	pda.stored_id.registered_name = "Econ Payer Alias"
	var/datum/bank_account/econ_test_ear/waiter_account = new("Econ Nearby Waiter Real")
	allocated += waiter_account
	var/mob/living/carbon/human/waiter = make_bystander(waiter_account, "Econ Waiter Alias", 2, 0)
	var/datum/bank_account/far_account = make_account("Econ Nearby Far")
	make_bystander(far_account, "Econ Far Alias", 4, 4)
	var/mob/living/carbon/human/ghostly = make_bystander(make_account("Econ Nearby Cloaked"), "Econ Cloaked Alias", 1, 0)
	ghostly.alpha = ECON_NEARBY_MIN_ALPHA - 1
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/list/nearby = wallet.wallet_data(owner)["nearby"]
	TEST_ASSERT_EQUAL(length(nearby), 1, "Кошелёк видит не только соседа: [json_encode(nearby)]")
	var/list/entry = nearby[1]
	TEST_ASSERT_EQUAL(entry["name"], "Econ Waiter Alias", "Сосед назван не по ID-карте")
	TEST_ASSERT(!findtext(json_encode(nearby), waiter_account.account_holder), "Окно выдало владельца счёта на чужой карте")

	var/reply = press(owner, "pay_nearby", list("ref" = entry["ref"], "amount" = SSeconomy.settings.transfer_max + 1))
	TEST_ASSERT(findtext(reply, "лимит"), "Сумма выше лимита не отказала: [reply]")
	reply = press(owner, "pay_nearby", list("ref" = REF(far_account), "amount" = 10))
	TEST_ASSERT(findtext(reply, "нет рядом"), "Оплата не соседу не отказала: [reply]")
	TEST_ASSERT_EQUAL(own.account_balance, 100000, "Отказы списали деньги")

	reply = press(owner, "pay_nearby", list("ref" = entry["ref"], "amount" = 150, "memo" = "за коктейль"))
	TEST_ASSERT_EQUAL(waiter_account.account_balance, 150, "Оплата соседу не дошла: [reply]")
	TEST_ASSERT_EQUAL(own.account_balance, 100000 - 150, "Списана не сумма оплаты")
	TEST_ASSERT(findtext(reply, "Econ Waiter Alias"), "Ответ не называет получателя по карте: [reply]")
	var/heard = jointext(waiter_account.heard, "\n")
	TEST_ASSERT(findtext(heard, "Econ Payer Alias") && findtext(heard, "за коктейль"), "Получатель не увидел имя с карты плательщика и комментарий: [heard]")
	TEST_ASSERT(!findtext(heard, own.account_holder), "Получатель узнал владельца счёта плательщика: [heard]")
	var/list/sent
	for(var/list/line as anything in wallet.wallet_data(owner)["history"])
		if(line["amount"] == -150)
			sent = line
	TEST_ASSERT(sent && findtext(sent["label"], "за коктейль"), "Оплата рядом не записана переводом с комментарием")
	TEST_ASSERT_EQUAL(sent["counterparty"], "Econ Waiter Alias", "История плательщика называет получателя не по карте или с номером счёта")
	var/list/received
	for(var/list/line as anything in waiter_account.ui_history())
		if(line["amount"] == 150)
			received = line
	TEST_ASSERT_EQUAL(received?["counterparty"], "Econ Payer Alias", "История получателя называет плательщика не по карте или с номером счёта")

	COOLDOWN_RESET(own, personal_payment_cooldown)
	waiter.forceMove(locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y + 4, run_loc_floor_bottom_left.z))
	reply = press(owner, "pay_nearby", list("ref" = entry["ref"], "amount" = 10))
	TEST_ASSERT(findtext(reply, "нет рядом"), "Оплата ушедшему не отказала: [reply]")
	TEST_ASSERT_EQUAL(waiter_account.account_balance, 150, "Ушедший получил деньги")

	var/datum/bank_account/anonymous/anon = new
	allocated += anon
	make_bystander(anon, "Econ Masked Guest", 1, 1)
	nearby = wallet.wallet_data(owner)["nearby"]
	TEST_ASSERT_EQUAL(length(nearby), 1, "Кошелёк не видит соседа с анонимным счётом: [json_encode(nearby)]")
	entry = nearby[1]
	press(owner, "pay_nearby", list("ref" = entry["ref"], "amount" = 20))
	TEST_ASSERT_EQUAL(anon.account_balance, 20, "Оплата на анонимный счёт с карты не дошла")

/// Запрос оплаты у человека рядом: проситель выбирает его из списка рядом, у того в Кошельке и на карте «X просит N кр. за Y»; оплата - перевод с именами с карт в историях; SSD в список запросов не попадает; пауза просителя и пара, отказ и заглушка просителя.
/datum/unit_test/economy_ui_wallet/pay_request/Run()
	var/mob/living/carbon/human/seller = make_owner("Econ Request Seller Real", 0)
	var/datum/bank_account/seller_account = account_of(seller)
	var/obj/item/modular_computer/pda/seller_pda = seller.get_active_held_item()
	seller_pda.stored_id.registered_name = "Econ Seller Alias"
	var/mob/living/carbon/human/client_person = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/datum/bank_account/econ_test_ear/buyer_account = new("Econ Request Buyer Real")
	allocated += buyer_account
	econ_test_set_balance(buyer_account, 1000)
	var/obj/item/card/id/buyer_card = allocate(/obj/item/card/id)
	buyer_card.registered_name = "Econ Buyer Alias"
	buyer_card.registered_account = buyer_account
	var/obj/item/modular_computer/pda/buyer_pda = allocate(/obj/item/modular_computer/pda)
	buyer_pda.InsertID(buyer_card)
	client_person.put_in_active_hand(buyer_pda)
	var/datum/computer_file/program/wallet/seller_wallet = wallet_of(seller)
	var/list/entry = seller_wallet.wallet_data(seller)["nearby"][1]
	TEST_ASSERT(!entry["requestable"], "SSD можно попросить оплату")
	var/reply = press(seller, "request_payment", list("ref" = entry["ref"], "amount" = 120, "reason" = "за коктейль"))
	TEST_ASSERT(findtext(reply, "нет рядом"), "Запрос к SSD не отказал: [reply]")
	client_person.mock_client = new /datum/client_interface()
	entry = seller_wallet.wallet_data(seller)["nearby"][1]
	TEST_ASSERT(entry["requestable"], "Человека с клиентом нельзя попросить оплату")
	reply = press(seller, "request_payment", list("ref" = entry["ref"], "amount" = 120, "reason" = ""))
	TEST_ASSERT(findtext(reply, "за что"), "Запрос без причины не отказал: [reply]")
	reply = press(seller, "request_payment", list("ref" = entry["ref"], "amount" = 120, "reason" = "за коктейль"))
	TEST_ASSERT(findtext(reply, "отправлен"), "Запрос не отправлен: [reply]")
	var/heard = jointext(buyer_account.heard, "\n")
	TEST_ASSERT(findtext(heard, "Econ Seller Alias просит 120 кр.") && findtext(heard, "за коктейль"), "Карта плательщика не сказала, кто, сколько и за что просит: [heard]")
	TEST_ASSERT(!findtext(heard, seller_account.account_holder), "Карта плательщика назвала владельца счёта просителя")
	reply = press(seller, "request_payment", list("ref" = entry["ref"], "amount" = 50, "reason" = "ещё"))
	TEST_ASSERT(findtext(reply, "не чаще"), "Второй запрос подряд не отказал: [reply]")
	COOLDOWN_RESET(seller_account, personal_payment_cooldown)
	COOLDOWN_RESET(seller_account, pay_request_cooldown)
	reply = press(seller, "request_payment", list("ref" = entry["ref"], "amount" = 50, "reason" = "ещё"))
	TEST_ASSERT(findtext(reply, "недавно"), "Запрос тому же человеку раньше паузы пары не отказал: [reply]")

	var/datum/computer_file/program/wallet/buyer_wallet = wallet_of(client_person)
	var/list/requests = buyer_wallet.wallet_data(client_person)["pay_requests"]
	TEST_ASSERT_EQUAL(length(requests), 1, "Запрос не ждёт в Кошельке плательщика")
	var/list/request = requests[1]
	TEST_ASSERT_EQUAL(request["from"], "Econ Seller Alias", "Кошелёк называет просителя не по карте")
	TEST_ASSERT_EQUAL(request["amount"], 120, "Кошелёк показывает не ту сумму")
	press(client_person, "pay_request_answer", list("id" = request["id"], "answer" = "pay"))
	TEST_ASSERT_EQUAL(seller_account.account_balance, 120, "Оплата запроса не дошла: [buyer_wallet.message]")
	TEST_ASSERT_EQUAL(buyer_account.account_balance, 880, "С плательщика списана не сумма запроса")
	TEST_ASSERT(!length(buyer_wallet.wallet_data(client_person)["pay_requests"]), "Оплаченный запрос всё ещё ждёт")
	var/list/paid_line = buyer_account.ui_history()[length(buyer_account.ui_history())]
	TEST_ASSERT_EQUAL(paid_line["counterparty"], "Econ Seller Alias", "История плательщика называет просителя не по карте")
	var/list/got_line = seller_account.ui_history()[length(seller_account.ui_history())]
	TEST_ASSERT_EQUAL(got_line["counterparty"], "Econ Buyer Alias", "История просителя называет плательщика не по карте")

	COOLDOWN_RESET(seller_account, pay_request_cooldown)
	seller_account.pay_request_pair_ready = null
	press(seller, "request_payment", list("ref" = entry["ref"], "amount" = 30, "reason" = "чаевые"))
	request = buyer_wallet.wallet_data(client_person)["pay_requests"][1]
	press(client_person, "pay_request_answer", list("id" = request["id"], "answer" = "mute"))
	TEST_ASSERT_EQUAL(buyer_account.account_balance, 880, "Отклонённый запрос списал деньги")
	TEST_ASSERT(!length(buyer_wallet.wallet_data(client_person)["pay_requests"]), "Отклонённый запрос всё ещё ждёт")
	COOLDOWN_RESET(seller_account, pay_request_cooldown)
	seller_account.pay_request_pair_ready = null
	reply = press(seller, "request_payment", list("ref" = entry["ref"], "amount" = 30, "reason" = "чаевые"))
	TEST_ASSERT(findtext(reply, "не принимает"), "Заглушённый проситель снова просит: [reply]")
	client_person.mock_client = null
