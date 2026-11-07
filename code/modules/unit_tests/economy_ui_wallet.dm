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
	TEST_ASSERT_EQUAL(refusal, "У вас уже есть взятый контракт.", "Отказ объяснён")
	var/datum/computer_file/program/wallet/wallet = wallet_of(owner)
	var/list/data = wallet.wallet_data(owner)
	TEST_ASSERT_EQUAL(length(data["contracts"]), 2, "Окно видит доску контрактов")
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
