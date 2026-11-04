/datum/unit_test/economy_trading/ui
	abstract_type = /datum/unit_test/economy_trading/ui

/// Человек со своим счётом и, если заданы доступы, ID-картой с ними.
/datum/unit_test/economy_trading/ui/proc/make_user(money, list/access)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new_trader(money)
	user.account_id = account.account_id
	if(access)
		econ_test_badge(user, access)
	return user

/datum/unit_test/economy_trading/ui/proc/install_program(mob/living/carbon/human/user)
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda)
	var/datum/computer_file/program/stock_exchange/program = new
	var/obj/item/computer_hardware/hard_drive/drive = pda.all_components[MC_HDD]
	drive.store_file(program)
	user.put_in_active_hand(pda)
	return program

/datum/unit_test/economy_trading/ui/proc/press(mob/user, datum/target, interface, action, list/params = list())
	var/datum/tgui/window = allocate(/datum/tgui, user, target, interface)
	window.status = UI_INTERACTIVE
	usr = user
	target.ui_act(action, params, window)
	usr = null

/datum/unit_test/economy_trading/ui/proc/message_of(datum/computer_file/program/stock_exchange/program, mob/user)
	return program.messages[REF(user)]

/// Пустая строка, если ключи списка ровно ожидаемые, иначе лишние и недостающие.
/datum/unit_test/economy_trading/ui/proc/key_mismatch(list/data, list/expected)
	var/list/keys = list()
	for(var/key in data)
		keys += key
	var/list/extra = keys - expected
	var/list/missing = expected - keys
	if(!length(extra) && !length(missing))
		return ""
	return "лишние: [jointext(extra, ", ")]; нет: [jointext(missing, ", ")]"

/// Покупка и продажа из КПК: деньги и акции на личном счёте, кулдаун и неверное количество отказывают с текстом.
/datum/unit_test/economy_trading/ui/program_trade/Run()
	var/mob/living/carbon/human/user = make_user(5000)
	var/datum/bank_account/own = econ_account_of(user)
	var/datum/computer_file/program/stock_exchange/program = install_program(user)
	company.price = 50
	press(user, program, "NtosStockExchange", "buy", list("ticker" = "AGRO", "count" = 5))
	var/cost = CEILING(50 * 5 * (100 + SSeconomy.settings.stock_spread) / 100, 1)
	var/paid = cost + CEILING(cost * SSeconomy.settings.stock_fee / 100, 1)
	TEST_ASSERT_EQUAL(own.shares["AGRO"], 5, "Куплено пять")
	TEST_ASSERT_EQUAL(own.account_balance, 5000 - paid, "Списана цена со спредом и комиссией")
	TEST_ASSERT_EQUAL(message_of(program, user), "Куплено 5 AGRO за [paid] кр. с учётом спреда и комиссии.", "Ответ окна")
	press(user, program, "NtosStockExchange", "buy", list("ticker" = "AGRO", "count" = 1))
	TEST_ASSERT_EQUAL(message_of(program, user), "Слишком частые сделки по AGRO.", "Кулдаун отказывает")
	var/list/data = program.stocks_data(user)
	var/list/cooldowns = data["cooldowns"]
	TEST_ASSERT(cooldowns["AGRO"] > 0, "Окно показывает остаток кулдауна")
	expire_cooldown(own, "AGRO")
	press(user, program, "NtosStockExchange", "buy", list("ticker" = "AGRO", "count" = "мусор"))
	TEST_ASSERT_EQUAL(message_of(program, user), "Неверная заявка.", "Строка вместо числа")
	TEST_ASSERT_EQUAL(own.shares["AGRO"], 5, "Отказы не меняют позицию")
	press(user, program, "NtosStockExchange", "sell", list("ticker" = "AGRO", "count" = 5))
	TEST_ASSERT(!("AGRO" in own.shares), "Позиция продана")
	TEST_ASSERT_EQUAL(copytext_char(message_of(program, user), 1, 15), "Продано 5 AGRO", "Ответ о продаже")

/// Глава персонала управляет казной по должности, но без доступа капитана торговать из неё не может.
/datum/unit_test/economy_trading/ui/treasury_hop/Run()
	var/datum/job/hop/hop_job = /datum/job/hop
	var/mob/living/carbon/human/hop = make_user(1000, list(ACCESS_HOP))
	hop.mind_initialize()
	hop.mind.assigned_role = initial(hop_job.title)
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	TEST_ASSERT(command.can_manage(hop), "ГП управляет казной")
	var/datum/computer_file/program/stock_exchange/hop_program = install_program(hop)
	press(hop, hop_program, "NtosStockExchange", "use_treasury", list("value" = TRUE))
	var/list/hop_data = hop_program.stocks_data(hop)
	TEST_ASSERT(!hop_data["using_treasury"], "ГП не торгует из казны")
	TEST_ASSERT_EQUAL(message_of(hop_program, hop), "Из казны торгует только капитан.", "Отказ объяснён")
	TEST_ASSERT(!hop_data["can_treasury"], "Окно ГП не предлагает казну")

/// Капитан по ID-карте торгует из казны с её лимитом, без карты - снова с личного счёта; счёт из параметров клиента не принимается.
/datum/unit_test/economy_trading/ui/treasury_captain/Run()
	var/datum/bank_account/treasury_account = use_treasury(10000)
	var/mob/living/carbon/human/captain = make_user(1000, list(ACCESS_CAPTAIN))
	var/datum/bank_account/own = econ_account_of(captain)
	var/datum/computer_file/program/stock_exchange/program = install_program(captain)
	press(captain, program, "NtosStockExchange", "use_treasury", list("value" = TRUE))
	var/list/data = program.stocks_data(captain)
	TEST_ASSERT(data["using_treasury"], "Капитан включил казну")
	TEST_ASSERT_EQUAL(data["balance"], treasury_account.account_balance, "Окно показывает баланс казны")
	TEST_ASSERT_EQUAL(data["position_cap"], SSeconomy.settings.stock_position_cap * SSeconomy.settings.stock_treasury_cap_mult, "Лимит позиции казны")
	company.price = 50
	press(captain, program, "NtosStockExchange", "buy", list("ticker" = "AGRO", "count" = 2, "account" = own.account_id))
	TEST_ASSERT_EQUAL(treasury_account.shares["AGRO"], 2, "Куплено из казны")
	TEST_ASSERT(!own.shares["AGRO"], "Личный счёт не тронут")

	qdel(captain.wear_id)
	data = program.stocks_data(captain)
	TEST_ASSERT(!data["using_treasury"], "Без карты капитана окно показывает личный счёт")
	TEST_ASSERT_EQUAL(data["position_cap"], SSeconomy.settings.stock_position_cap, "Личный лимит позиции")
	expire_cooldown(treasury_account, "AGRO")
	press(captain, program, "NtosStockExchange", "buy", list("ticker" = "AGRO", "count" = 1))
	TEST_ASSERT_EQUAL(own.shares["AGRO"], 1, "Без карты покупка идёт с личного счёта")
	TEST_ASSERT_EQUAL(treasury_account.shares["AGRO"], 2, "Казна не тронута")

/// Окно получает ровно котировки, счёт и правила из настроек, без очереди событий, их заголовков, сроков и порогов аудита.
/datum/unit_test/economy_trading/ui/data/Run()
	var/mob/living/carbon/human/user = make_user(1000)
	var/datum/computer_file/program/stock_exchange/program = install_program(user)
	var/datum/stock_company/halted = SSmarket.get_company("CYBS")
	halted.halted_until = world.time + STOCK_HALT_TIME
	var/datum/market_event/queued = SSmarket.schedule_company_event(company, "scandal", "Секретный заголовок теста", -0.2, STOCK_EVENT_ETA_MIN)
	var/list/data = program.stocks_data(user)
	var/list/static_data = program.stocks_static_data()
	var/encoded = json_encode(data) + json_encode(static_data)
	qdel(queued)
	halted.halted_until = 0
	var/static/list/data_keys = list("companies", "has_account", "account_name", "holdings", "cooldowns", "balance", "portfolio", "realized", "frozen", "can_treasury", "using_treasury", "message", "position_cap")
	var/static/list/static_keys = list("history", "fee", "spread", "cooldown", "personal_cap", "treasury_cap_mult", "halt_ratio", "halt_minutes", "relist_ratio", "news_channel", "news_delay", "refute_minutes", "persist_decay")
	var/static/list/company_keys = list("ticker", "name", "price", "change", "halted", "base_price")
	var/mismatch = key_mismatch(data, data_keys)
	TEST_ASSERT(!mismatch, "Ключи данных окна: [mismatch]")
	mismatch = key_mismatch(static_data, static_keys)
	TEST_ASSERT(!mismatch, "Ключи правил окна: [mismatch]")
	TEST_ASSERT_EQUAL(length(data["companies"]), length(SSmarket.companies), "Все компании")
	var/list/halted_entry
	for(var/list/entry as anything in data["companies"])
		mismatch = key_mismatch(entry, company_keys)
		TEST_ASSERT(!mismatch, "Ключи компании [entry["ticker"]]: [mismatch]")
		if(entry["ticker"] == "CYBS")
			halted_entry = entry
	TEST_ASSERT(halted_entry["halted"], "Остановка торгов видна")
	TEST_ASSERT_EQUAL(halted_entry["base_price"], halted.base_price, "Базовая цена для лимита")
	TEST_ASSERT_EQUAL(static_data["fee"], SSeconomy.settings.stock_fee, "Комиссия из настроек")
	TEST_ASSERT_EQUAL(static_data["spread"], SSeconomy.settings.stock_spread, "Спред из настроек")
	TEST_ASSERT_EQUAL(static_data["cooldown"], SSeconomy.settings.stock_trade_cooldown_seconds, "Кулдаун из настроек")
	TEST_ASSERT_EQUAL(static_data["refute_minutes"], SSeconomy.settings.press_release_refute_minutes, "Срок опровержения")
	TEST_ASSERT_EQUAL(static_data["persist_decay"], SSmarket.persist_decay, "Затухание между сменами")
	TEST_ASSERT_EQUAL(static_data["news_delay"], SSmarket.news_flash_minutes, "Задержка новостей")
	TEST_ASSERT(!findtext(encoded, "Секретный заголовок теста"), "Заголовок события из очереди утёк в окно")

/// Терминал торгует тем же путём, у каждого пользователя свои ответ и режим казны, закрытие окна их сбрасывает; программа удаляется вместе с терминалом.
/datum/unit_test/economy_trading/ui/terminal/Run()
	var/datum/bank_account/treasury_account = use_treasury(10000)
	var/mob/living/carbon/human/captain = make_user(1000, list(ACCESS_CAPTAIN))
	var/mob/living/carbon/human/visitor = make_user(5000)
	var/datum/bank_account/own = econ_account_of(visitor)
	var/obj/machinery/computer/stock_terminal/terminal = allocate(/obj/machinery/computer/stock_terminal)
	var/datum/computer_file/program/stock_exchange/program = terminal.program
	company.price = 50
	press(captain, terminal, "StockTerminal", "use_treasury", list("value" = TRUE))
	press(captain, terminal, "StockTerminal", "buy", list("ticker" = "AGRO", "count" = 2))
	TEST_ASSERT_EQUAL(treasury_account.shares["AGRO"], 2, "Капитан купил из казны с терминала")
	var/list/visitor_data = terminal.ui_data(visitor)
	TEST_ASSERT(!visitor_data["using_treasury"], "Режим казны перешёл к следующему игроку")
	TEST_ASSERT_EQUAL(visitor_data["message"], "", "Ответ капитану виден следующему игроку")
	press(visitor, terminal, "StockTerminal", "buy", list("ticker" = "AGRO", "count" = 3))
	TEST_ASSERT_EQUAL(own.shares["AGRO"], 3, "Куплено с личного счёта на терминале")
	visitor_data = terminal.ui_data(visitor)
	var/list/holdings = visitor_data["holdings"]
	TEST_ASSERT_EQUAL(holdings["AGRO"], 3, "Терминал показывает позицию")
	var/list/captain_data = terminal.ui_data(captain)
	TEST_ASSERT(captain_data["using_treasury"] && findtext(captain_data["message"], "Куплено 2 AGRO"), "Состояние капитана сбилось чужой сделкой")
	terminal.ui_close(captain)
	captain_data = terminal.ui_data(captain)
	TEST_ASSERT(!captain_data["using_treasury"] && captain_data["message"] == "", "Закрытие окна не сбросило режим казны и ответ")
	qdel(terminal)
	TEST_ASSERT(QDELETED(program), "Программа терминала удалена")

/// Табло обновляется на тике биржи страницами по две компании, показывает шок вышедшего события на том же тике, помечает остановленные торги и укорачивает четырёхзначные цены.
/datum/unit_test/economy_trading/ui/ticker_board/Run()
	var/obj/structure/sign/ticker_board/board = allocate(/obj/structure/sign/ticker_board)
	var/list/tickers = SSmarket.companies.Copy()
	reset_company(company)
	board.offset = tickers.Find(company.ticker) - 1
	var/expected = company.price * 1.5
	SSmarket.schedule_company_event(company, "contract_won", "Тестовый контракт", 0.5, 0)
	SSmarket.tick_stocks()
	TEST_ASSERT(findtext(board.maptext, "[company.ticker] [round(expected, 0.1)]<"), "Шок события не виден на том же тике: [board.maptext]")
	board.offset = 0
	var/datum/stock_company/first = SSmarket.companies[tickers[1]]
	first.halted_until = world.time + STOCK_HALT_TIME
	SSmarket.tick_stocks()
	var/first_page = board.maptext
	TEST_ASSERT_EQUAL(board.icon_state, "board_halt", "Рамка табло мигает на остановленных торгах")
	SSmarket.tick_stocks()
	var/second_page = board.maptext
	first.halted_until = 0
	TEST_ASSERT(findtext(first_page, "[tickers[1]] STOP"), "Остановленные торги на табло: [first_page]")
	TEST_ASSERT(findtext(first_page, tickers[2]), "Две компании на странице")
	TEST_ASSERT(!findtext(first_page, tickers[3]), "Третья компания - на следующей странице")
	TEST_ASSERT(findtext(second_page, tickers[3]), "Табло листает страницы на тике")
	TEST_ASSERT_EQUAL(board.icon_state, "board", "Без остановленных торгов на странице рамка обычная")
	company.price = 1234.56
	board.offset = tickers.Find(company.ticker) - 1
	board.update_ticker()
	reset_company(company)
	TEST_ASSERT(findtext(board.maptext, "[company.ticker] 1235<"), "Четырёхзначная цена на табло с дробной частью: [board.maptext]")
	qdel(board)
	var/list/lookup = SSmarket.comp_lookup
	var/listeners = lookup ? lookup[COMSIG_MARKET_STOCKS_TICKED] : null
	TEST_ASSERT(listeners != board && !(islist(listeners) && (board in listeners)), "Табло отписалось от тика")
