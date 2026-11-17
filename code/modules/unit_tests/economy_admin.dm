/datum/unit_test/economy_market/admin
	abstract_type = /datum/unit_test/economy_market/admin

/datum/unit_test/economy_market/admin/proc/make_user(rights = R_ADMIN)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/client_interface/player = new
	if(rights)
		var/datum/admins/holder = new(null, null, FALSE, FALSE, TRUE)
		holder.rank = new /datum/admin_rank("economy test", rights)
		player.holder = holder
		allocated += holder
		allocated += holder.rank
	user.mock_client = player
	return user

/datum/unit_test/economy_market/admin/proc/press(mob/user, datum/economy_panel/panel, action, list/params = list())
	var/datum/tgui/window = allocate(/datum/tgui, user, panel, "EconomyAdmin")
	window.status = UI_INTERACTIVE
	panel.ui_act(action, params, window)

/datum/unit_test/economy_market/admin/proc/new_account(money = 0)
	var/datum/bank_account/account = allocate(/datum/bank_account, "econ_test_admin")
	if(money)
		econ_test_set_balance(account, money)
	return account

/// Без прав админа ни одно действие не проходит, даже при открытом окне.
/datum/unit_test/economy_market/admin/access/Run()
	var/datum/economy_panel/panel = allocate(/datum/economy_panel)
	var/datum/bank_account/account = new_account()
	var/mob/player = make_user(NONE)
	var/mob/coder = make_user(R_DEBUG)
	var/tax_before = SSeconomy.tax_rate
	for(var/mob/user in list(player, coder))
		press(user, panel, "adjust", list("number" = "[account.account_id]", "amount" = "300", "comment" = "проверка"))
		press(user, panel, "set_tax", list("rate" = "0", "comment" = "проверка"))
		press(user, panel, "freeze", list("number" = "[account.account_id]", "comment" = "проверка"))
	TEST_ASSERT_EQUAL(account.account_balance, 0, "Без R_ADMIN счёт не корректируется")
	TEST_ASSERT_EQUAL(SSeconomy.tax_rate, tax_before, "Без R_ADMIN налог не меняется")
	TEST_ASSERT_EQUAL(account.state, ACCOUNT_ACTIVE, "Без R_ADMIN счёт не морозится")
	TEST_ASSERT(!panel.panel_act(null, "adjust", list("number" = account.account_id, "amount" = 300, "comment" = "проверка")), "Без пользователя действие не принято")
	TEST_ASSERT_EQUAL(account.account_balance, 0, "Без пользователя счёт не корректируется")
	var/mob/admin = make_user()
	press(admin, panel, "adjust", list("number" = "[account.account_id]", "amount" = "300", "comment" = "проверка"))
	TEST_ASSERT_EQUAL(account.account_balance, 300, "Админ корректирует счёт")

/// Корректировка идёт через журнал с причиной ECON_ADMIN, требует комментарий и пишет его в админ-лог.
/datum/unit_test/economy_market/admin/adjust/Run()
	var/datum/economy_panel/panel = allocate(/datum/economy_panel)
	var/datum/bank_account/account = new_account()
	var/mob/admin = make_user()
	var/minted = SSeconomy.ledger.minted
	var/admin_moved = SSeconomy.ledger.by_reason[ECON_ADMIN]
	press(admin, panel, "adjust", list("number" = "[account.account_id]", "amount" = "300", "comment" = "   "))
	TEST_ASSERT_EQUAL(account.account_balance, 0, "Без комментария нельзя")
	TEST_ASSERT(findtext(panel.message, "комментарий"), "Отказ называет комментарий: [panel.message]")
	press(admin, panel, "adjust", list("number" = "[account.account_id]", "amount" = "300", "comment" = "компенсация за баг"))
	TEST_ASSERT_EQUAL(account.account_balance, 300, "С комментарием можно")
	TEST_ASSERT(SSeconomy.ledger.minted - minted >= 300, "Начисление - эмиссия через журнал")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.by_reason[ECON_ADMIN] - admin_moved, 300, "Причина ECON_ADMIN")
	TEST_ASSERT(findtext(last_admin_log(), "компенсация за баг"), "Комментарий в админ-логе: [last_admin_log()]")
	var/datum/transaction/entry = account.transaction_history[length(account.transaction_history)]
	TEST_ASSERT_EQUAL(entry.purpose, econ_reason_name(ECON_ADMIN), "Владелец видит корректировку NT без админского комментария")
	var/burned = SSeconomy.ledger.burned
	press(admin, panel, "adjust", list("number" = "[account.account_id]", "amount" = "-100", "comment" = "откат"))
	TEST_ASSERT_EQUAL(account.account_balance, 200, "Отрицательная сумма списывает")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned, 100, "Списание - сток через журнал")
	for(var/bad_amount in list("-500", "[ECON_ADMIN_ADJUST_MAX + 1]", "мусор", "0", "1e999"))
		press(admin, panel, "adjust", list("number" = "[account.account_id]", "amount" = bad_amount, "comment" = "проверка"))
		TEST_ASSERT_EQUAL(account.account_balance, 200, "Сумма [bad_amount] отклонена")
	var/list/data = panel.ui_static_data(admin)
	for(var/key in list("ledger", "snapshots", "departments", "accounts", "flags", "commodities", "partners", "companies", "config_errors"))
		TEST_ASSERT(!isnull(data[key]), "Нет данных окна [key]")
	var/list/ledger = data["ledger"]
	var/found = FALSE
	for(var/list/category as anything in ledger["by_category"])
		if(category["id"] == ECON_CAT_ADMIN)
			found = category["amount"] >= 400
	TEST_ASSERT(found, "Категория администрации в журнале окна")

/// Заморозка из панели: причина для владельца отдельно от комментария, переводы закрыты, корректировка проходит; разморозка возвращает спящее состояние.
/datum/unit_test/economy_market/admin/frozen/Run()
	var/datum/economy_panel/panel = allocate(/datum/economy_panel)
	var/datum/bank_account/econ_test_spy/account = allocate(/datum/bank_account/econ_test_spy, "econ_test_admin")
	econ_test_set_balance(account, 500)
	var/datum/bank_account/other = new_account()
	var/mob/admin = make_user()
	press(admin, panel, "freeze", list("number" = "[account.account_id]", "reason" = "проверка счёта", "comment" = ""))
	TEST_ASSERT_EQUAL(account.state, ACCOUNT_ACTIVE, "Заморозка без комментария не проходит")
	press(admin, panel, "freeze", list("number" = "[account.account_id]", "reason" = " ", "comment" = "тикет 42"))
	TEST_ASSERT_EQUAL(account.state, ACCOUNT_ACTIVE, "Заморозка без причины для владельца не проходит")
	account.state = ACCOUNT_DORMANT
	press(admin, panel, "freeze", list("number" = "[account.account_id]", "reason" = "проверка счёта", "comment" = "тикет 42"))
	TEST_ASSERT_EQUAL(account.state, ACCOUNT_FROZEN, "Счёт заморожен")
	TEST_ASSERT_EQUAL(account.frozen_by, ECON_ADMIN_FROZEN_BY, "Кем заморожен")
	TEST_ASSERT_EQUAL(account.freeze_reason, "проверка счёта", "Причина для владельца")
	var/card_message = jointext(account.card_messages, "|")
	TEST_ASSERT(findtext(card_message, "проверка счёта") && !findtext(card_message, "тикет 42"), "На карту уходит причина, а не комментарий: [card_message]")
	TEST_ASSERT(findtext(last_admin_log(), "тикет 42"), "Комментарий в админ-логе")
	TEST_ASSERT_NOTNULL(SSeconomy.send_transfer(account, other, 10), "Перевод с замороженного счёта отклонён")
	press(admin, panel, "adjust", list("number" = "[account.account_id]", "amount" = "-200", "comment" = "изъятие"))
	TEST_ASSERT_EQUAL(account.account_balance, 300, "Списание проходит заморозку")
	press(admin, panel, "adjust", list("number" = "[account.account_id]", "amount" = "50", "comment" = "возврат"))
	TEST_ASSERT_EQUAL(account.account_balance, 350, "Начисление на замороженный счёт")
	var/datum/economy_department/science = SSeconomy.departments[ACCOUNT_SCI]
	var/datum/bank_account/department/budget = science.account
	press(admin, panel, "freeze", list("number" = "[budget.account_id]", "reason" = "проверка", "comment" = "проверка"))
	TEST_ASSERT_NOTEQUAL(budget.state, ACCOUNT_FROZEN, "Бюджет не морозится")
	press(admin, panel, "unfreeze", list("number" = "[account.account_id]", "comment" = "закрыто"))
	TEST_ASSERT_EQUAL(account.state, ACCOUNT_DORMANT, "Спящий счёт после разморозки снова спящий")
	TEST_ASSERT_NULL(account.frozen_by, "После разморозки нет отметки")

/// Сброс сектора только с фразой подтверждения; файл состояния удаляется по пути SSmarket.
/datum/unit_test/economy_market/admin/reset/Run()
	var/datum/economy_panel/panel = allocate(/datum/economy_panel)
	var/mob/admin = make_user()
	var/saved_path = SSmarket.state_path
	var/test_path = "[GLOB.econ_sector_test_dir]admin_reset.json"
	SSmarket.state_path = test_path
	text2file("{}", test_path)
	var/datum/stock_company/company = SSmarket.get_company("AGRO")
	company.price = company.base_price * 2
	press(admin, panel, "reset_sector", list("comment" = "новый сезон"))
	var/kept_unconfirmed = fexists(test_path) && abs(company.price - company.base_price * 2) < 0.01
	press(admin, panel, "reset_sector", list("comment" = "новый сезон", "confirm" = "да"))
	var/kept_wrong = fexists(test_path) && abs(company.price - company.base_price * 2) < 0.01
	press(admin, panel, "reset_sector", list("comment" = "", "confirm" = ECON_ADMIN_RESET_PHRASE))
	var/kept_uncommented = fexists(test_path)
	press(admin, panel, "reset_sector", list("comment" = "новый сезон", "confirm" = " [ECON_ADMIN_RESET_PHRASE] "))
	var/removed = !fexists(test_path)
	var/reset_log = last_admin_log()
	company = SSmarket.get_company("AGRO")
	var/reset_price = company.price
	var/list/saved_raw = SSeconomy.settings.raw
	var/list/saved_errors = GLOB.economy_config_errors
	GLOB.economy_config_errors = list()
	SSeconomy.settings.raw = list("market" = list("partners" = "мусор"))
	press(admin, panel, "reset_sector", list("comment" = "битые партнёры", "confirm" = ECON_ADMIN_RESET_PHRASE))
	var/list/reset_errors = GLOB.economy_config_errors
	SSeconomy.settings.raw = saved_raw
	GLOB.economy_config_errors = saved_errors
	SSmarket.state_path = saved_path
	fdel(test_path)
	TEST_ASSERT(length(reset_errors) && findtext(reset_errors[1], "market.partners"), "Ошибки партнёров при сбросе видны в панели: [jointext(reset_errors, "; ")]")
	TEST_ASSERT(kept_unconfirmed, "Без подтверждения сектор не сброшен")
	TEST_ASSERT(kept_wrong, "Неверная фраза не сбрасывает")
	TEST_ASSERT(kept_uncommented, "Без комментария не сбрасывает")
	TEST_ASSERT(removed, "Сброс удалил файл состояния")
	TEST_ASSERT(abs(reset_price - company.base_price) < 0.01, "Цена акций вернулась к базе: [reset_price]")
	TEST_ASSERT(findtext(reset_log, "новый сезон"), "Сброс в админ-логе: [reset_log]")

/// События рынка из панели идут через процы рынка: обвал и бум с кулдауном, событие компании упирается в потолки.
/datum/unit_test/economy_market/admin/market_event/Run()
	var/datum/economy_panel/panel = allocate(/datum/economy_panel)
	var/mob/admin = make_user()
	var/list/before = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		before[ticker] = company.price
	press(admin, panel, "market_event", list("kind" = "crash", "comment" = "проверка"))
	var/list/crash_effects = SSmarket.station_events["market_crash"]
	var/shock = 1 + crash_effects[STOCK_ALL_COMPANIES]
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT(abs(company.price - max(before[ticker] * shock, STOCK_PRICE_MIN)) < 0.01, "[ticker]: обвал сдвинул цену [before[ticker]] -> [company.price]")
		before[ticker] = company.price
	press(admin, panel, "market_event", list("kind" = "crash", "comment" = "проверка"))
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT(abs(company.price - before[ticker]) < 0.01, "[ticker]: повтор обвала в кулдауне не действует")
	TEST_ASSERT(findtext(panel.message, "повтор через"), "Админ видит кулдаун: [panel.message]")
	var/shifts = SSmarket.shift_count
	press(admin, panel, "market_event", list("kind" = "shift", "comment" = "проверка"))
	TEST_ASSERT_EQUAL(SSmarket.shift_count, shifts + 1, "Сдвиг рынка")
	var/datum/stock_company/agro = SSmarket.get_company("AGRO")
	agro.event_mult = STOCK_EVENT_MULT_MAX - 0.5
	agro.price = agro.base_price * 4
	press(admin, panel, "market_event", list("kind" = "company_event", "ticker" = "AGRO", "effect" = "100", "headline" = "", "comment" = "проверка"))
	TEST_ASSERT_EQUAL(length(SSmarket.scheduled_events), 0, "Без заголовка событие не ставится")
	press(admin, panel, "market_event", list("kind" = "company_event", "ticker" = "AGRO", "effect" = "500", "headline" = "Урожай века", "comment" = "проверка"))
	TEST_ASSERT_EQUAL(length(SSmarket.scheduled_events), 0, "Шок вне пределов не ставится")
	press(admin, panel, "market_event", list("kind" = "company_event", "ticker" = "AGRO", "effect" = "100", "headline" = "Урожай века", "comment" = "проверка"))
	TEST_ASSERT_EQUAL(length(SSmarket.scheduled_events), 1, "Событие в очереди")
	SSmarket.run_due_events()
	TEST_ASSERT_EQUAL(length(SSmarket.scheduled_events), 0, "Событие вышло на тике биржи")
	TEST_ASSERT(abs(agro.event_mult - STOCK_EVENT_MULT_MAX) < 0.001, "Множитель событий на потолке: [agro.event_mult]")
	TEST_ASSERT(agro.price <= agro.base_price * STOCK_PRICE_MAX_RATIO + 0.01, "Цена не выше потолка: [agro.price]")

/// Налог через сеттер казны с её пределами.
/datum/unit_test/economy_market/admin/tax/Run()
	var/datum/economy_panel/panel = allocate(/datum/economy_panel)
	var/mob/admin = make_user()
	var/saved_rate = SSeconomy.tax_rate
	press(admin, panel, "set_tax", list("rate" = "999", "comment" = "проверка"))
	var/capped = SSeconomy.tax_rate
	press(admin, panel, "set_tax", list("rate" = "мусор", "comment" = "проверка"))
	var/after_garbage = SSeconomy.tax_rate
	press(admin, panel, "set_tax", list("rate" = "5", "comment" = "проверка"))
	var/set_rate = SSeconomy.tax_rate
	SSeconomy.tax_rate = saved_rate
	TEST_ASSERT_EQUAL(capped, SSeconomy.settings.tax_max, "Налог упирается в потолок конфига")
	TEST_ASSERT_EQUAL(after_garbage, capped, "Мусор не меняет налог")
	TEST_ASSERT_EQUAL(set_rate, 5, "Налог выставлен")

/// Перечитка конфига: с ошибками не применяется и показывает их, без ошибок заменяет настройки.
/datum/unit_test/economy_market/admin/reload/Run()
	var/datum/economy_panel/panel = allocate(/datum/economy_panel)
	var/mob/admin = make_user()
	var/datum/economy_settings/saved_settings = SSeconomy.settings
	var/list/saved_errors = GLOB.economy_config_errors
	var/bad_path = "[GLOB.econ_sector_test_dir]admin_bad_economy.json"
	text2file(json_encode(list("settings" = list("tax_max" = 500))), bad_path)
	panel.config_path = bad_path
	press(admin, panel, "reload_config")
	var/kept = SSeconomy.settings == saved_settings
	var/list/data = panel.ui_static_data(admin)
	var/list/errors = data["config_errors"]
	var/shown = length(errors) && findtext(errors[1], "tax_max")
	panel.config_path = ECONOMY_CONFIG_PATH
	press(admin, panel, "reload_config")
	var/replaced = SSeconomy.settings != saved_settings
	var/clean = !length(GLOB.economy_config_errors)
	var/same_tax_max = SSeconomy.settings.tax_max == saved_settings.tax_max
	SSeconomy.settings = saved_settings
	GLOB.economy_config_errors = saved_errors
	fdel(bad_path)
	TEST_ASSERT(kept, "Конфиг с ошибкой не применён")
	TEST_ASSERT(shown, "Ошибка конфига видна в окне")
	TEST_ASSERT(replaced, "Конфиг без ошибок заменил настройки")
	TEST_ASSERT(clean, "Конфиг репозитория без ошибок")
	TEST_ASSERT(same_tax_max, "Значения из того же файла")
