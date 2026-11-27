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

/// Держателям приходит скачок цены от STOCK_HOLDER_ALERT_MIN и остановка торгов; мелкое движение и чужие акции - нет.
/datum/unit_test/economy_trading/holder_alerts/Run()
	var/datum/bank_account/holder = new_trader(1000)
	holder.shares["AGRO"] = 10
	var/datum/bank_account/other = new_trader(1000)
	other.shares["VYMD"] = 5
	var/holders = 0
	for(var/number in SSeconomy.accounts_by_number)
		var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
		if(account.shares["AGRO"])
			holders++
	TEST_ASSERT(holders >= 1, "Держатель AGRO зарегистрирован в банке")
	var/price_before = company.price
	TEST_ASSERT_EQUAL(SSmarket.alert_holders(company, price_before), 0, "Без движения цены сообщений нет")
	company.set_price(price_before * (1 + STOCK_HOLDER_ALERT_MIN / 2))
	TEST_ASSERT_EQUAL(SSmarket.alert_holders(company, price_before), 0, "Мелкое движение не беспокоит держателей")
	price_before = company.price
	company.apply_shock(-0.2)
	TEST_ASSERT_EQUAL(SSmarket.alert_holders(company, price_before), holders, "Падение на 20% приходит каждому держателю AGRO")
	TEST_ASSERT_EQUAL(SSmarket.alert_holders_halted(company), holders, "Остановка торгов приходит держателям")
	TEST_ASSERT_EQUAL(SSmarket.alert_holders(null, price_before), 0, "Без компании - тишина")

/// "Макс" покупает ровно столько, сколько позволяют деньги или лимит позиции: на одну акцию больше уже не проходит; "продать всё" продаёт всё.
/datum/unit_test/economy_trading/ui/buy_max/Run()
	var/mob/living/carbon/human/user = make_user(1000)
	var/datum/bank_account/own = econ_account_of(user)
	var/datum/computer_file/program/stock_exchange/program = install_program(user)
	company.price = 47.3
	var/by_money = SSmarket.max_buy_count(own, company)
	TEST_ASSERT(by_money > 0, "Есть что купить на 1000 кр.")
	var/datum/bank_account/probe = new_trader(1000)
	TEST_ASSERT(SSmarket.try_buy_shares(probe, "AGRO", by_money + 1, user), "На одну акцию больше \"Макс\" не по карману")
	var/list/entry
	var/list/data = program.stocks_data(user)
	for(var/list/each as anything in data["companies"])
		if(each["ticker"] == "AGRO")
			entry = each
	TEST_ASSERT_EQUAL(entry["max_buy"], by_money, "Окно показывает тот же \"Макс\"")
	press(user, program, "NtosStockExchange", "buy", list("ticker" = "AGRO", "count" = "max"))
	TEST_ASSERT_EQUAL(own.shares["AGRO"], by_money, "Куплено на все деньги")
	TEST_ASSERT_EQUAL(SSmarket.max_buy_count(own, company), 0, "Денег на ещё одну нет")
	expire_cooldown(own, "AGRO")
	press(user, program, "NtosStockExchange", "buy", list("ticker" = "AGRO", "count" = "max"))
	TEST_ASSERT_EQUAL(message_of(program, user), "Купить нечего: позиция упёрлась в лимит или не хватает денег.", "Пустой \"Макс\" объясняет отказ")
	expire_cooldown(own, "AGRO")
	press(user, program, "NtosStockExchange", "sell", list("ticker" = "AGRO", "count" = "max"))
	TEST_ASSERT(!own.shares["AGRO"], "Продано всё")

	var/datum/bank_account/rich = new_trader(SSeconomy.settings.stock_position_cap * 3)
	var/by_cap = SSmarket.max_buy_count(rich, company)
	TEST_ASSERT_EQUAL(by_cap, round(SSeconomy.settings.stock_position_cap / max(company.price, company.base_price)), "Богатого ограничивает лимит позиции")
	TEST_ASSERT(!SSmarket.try_buy_shares(rich, "AGRO", by_cap, user), "\"Макс\" по лимиту проходит")
	company.halted_until = world.time + STOCK_HALT_TIME
	TEST_ASSERT_EQUAL(SSmarket.max_buy_count(probe, company), 0, "На остановленных торгах купить нечего")
	company.halted_until = 0

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
	var/static/list/data_keys = list("companies", "has_account", "account_name", "holdings", "cooldowns", "balance", "portfolio", "realized", "frozen", "can_treasury", "using_treasury", "message", "position_cap", "orders", "evac")
	var/static/list/static_keys = list("history", "drivers", "moves", "work_cap", "common_drivers", "event_min", "event_max", "station_event_cooldown", "fee", "spread", "cooldown", "personal_cap", "treasury_cap_mult", "halt_ratio", "halt_minutes", "relist_ratio", "news_channel", "news_delay", "refute_minutes", "persist_decay", "dividend_share", "payroll_minutes", "orders_max")
	var/static/list/company_keys = list("ticker", "name", "price", "change", "halted", "base_price", "max_buy", "index", "dividend_pool", "dividend_per_share")
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

/// Сноски биржи: у каждой компании колебания, партнёр с его товарами и свои события станции с итоговым сдвигом; события для всех - общей строкой.
/datum/unit_test/economy_trading/ui/drivers/Run()
	var/datum/computer_file/program/stock_exchange/program = new
	var/list/static_data = program.stocks_static_data()
	qdel(program)
	var/list/drivers = static_data["drivers"]
	TEST_ASSERT_EQUAL(length(drivers), length(SSmarket.companies), "Сноски у каждой компании")
	TEST_ASSERT(static_data["event_min"] < 0 && static_data["event_max"] > 0, "Разброс новостей компаний: [static_data["event_min"]]..[static_data["event_max"]]")
	SSmarket.station_events["meteors"] = list("NTRN" = 0.1, STOCK_ALL_COMPANIES = 0.1)
	var/datum/stock_company/nt = SSmarket.get_company("NTRN")
	var/datum/stock_company/vey = SSmarket.get_company("VYMD")
	var/datum/stock_company/naka = SSmarket.get_company("NKMR")
	var/list/ntrn = driver_labels(nt.price_drivers())
	var/list/vymd = driver_labels(vey.price_drivers())
	var/list/nkmr = driver_labels(naka.price_drivers())
	TEST_ASSERT_EQUAL(ntrn[GLOB.market_station_event_names["sm_delam"]], -25, "Расслоение СМ у Нанотрейзен")
	TEST_ASSERT_EQUAL(nkmr[GLOB.market_station_event_names["sm_delam"]], 10, "Расслоение СМ у Накамуры")
	TEST_ASSERT(!(GLOB.market_station_event_names["market_crash"] in ntrn), "Обвал рынка - в общей строке, а не у каждой компании")
	var/list/common = driver_labels(market_common_drivers())
	TEST_ASSERT_EQUAL(common[GLOB.market_station_event_names["market_crash"]], -20, "Обвал рынка касается всех")
	TEST_ASSERT_EQUAL(common[GLOB.market_station_event_names["sector_boom"]], 10, "Бум касается всех")
	TEST_ASSERT_EQUAL(common[GLOB.market_station_event_names["meteors"]], 10, "Общая часть метеоритов в общей строке")
	TEST_ASSERT_EQUAL(ntrn[GLOB.market_station_event_names["meteors"]], 21, "Свой и общий шок одного события складываются как в station_event()")
	TEST_ASSERT(!(GLOB.market_station_event_names["disease_outbreak"] in ntrn), "Вспышка болезни Нанотрейзен не касается")
	TEST_ASSERT_EQUAL(vymd[GLOB.market_station_event_names["disease_outbreak"]], 20, "Вспышка болезни у Вей-Мед")
	var/datum/stock_company/hephaestus = SSmarket.get_company("HEPH")
	var/datum/stock_company/bishop = SSmarket.get_company("BSHP")
	var/list/heph = driver_labels(hephaestus.price_drivers())
	var/list/bshp = driver_labels(bishop.price_drivers())
	TEST_ASSERT_EQUAL(heph[GLOB.market_station_event_names["delta_alert"]], 10, "Код \"Дельта\" поднимает Гефест")
	TEST_ASSERT_EQUAL(bshp[GLOB.market_station_event_names["disease_outbreak"]], 5, "Вспышка болезни поднимает Бишоп")
	TEST_ASSERT_EQUAL(bshp[GLOB.market_station_event_names["sm_delam"]], -5, "Расслоение СМ роняет Бишоп")
	TEST_ASSERT(!hephaestus.partner_id && !bishop.partner_id, "У новых компаний нет торгового партнёра")
	var/datum/trade_partner/vey_med = SSmarket.get_partner("vey_med")
	var/list/sale = vymd["Продажи станции через снабжение партнёру \"[vey_med.name]\""]
	TEST_ASSERT(sale, "Продажи партнёру в сносках Вей-Мед")
	TEST_ASSERT_EQUAL(sale["effect"], STOCK_TRADE_BOOST_MAX * 100, "Потолок роста от продаж")
	TEST_ASSERT(findtext(sale["note"], "медикаменты"), "Товары партнёра строчными: [sale["note"]]")
	var/datum/trade_partner/nakamura = SSmarket.get_partner("nakamura")
	nakamura.unlocked = FALSE
	nkmr = driver_labels(naka.price_drivers())
	sale = nkmr["Продажи станции через снабжение партнёру \"[nakamura.name]\""]
	TEST_ASSERT(findtext(sale["note"], "пока не торгует"), "Закрытый партнёр помечен: [sale["note"]]")
	var/datum/trade_partner/nt_logistics = SSmarket.get_partner("nt_logistics")
	var/list/nt_sale = ntrn["Продажи станции через снабжение партнёру \"[nt_logistics.name]\""]
	TEST_ASSERT(findtext(nt_sale["note"], "любые товары"), "Партнёр без ограничений покупает любые товары: [nt_sale["note"]]")

/// Сноски по подписи: сдвиг события станции числом, у продаж партнёру - вся запись.
/datum/unit_test/economy_trading/ui/proc/driver_labels(list/drivers)
	. = list()
	for(var/list/driver as anything in drivers)
		.[driver["label"]] = driver["note"] ? driver : driver["effect"]

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

/// Заявки из окна: "add_order" ставит заявку на торговый счёт пользователя и отвечает текстом, неверный ввод отказывает, окно получает список; "cancel_order" снимает по id. Фонд дивидендов и выплата на акцию видны в котировках.
/datum/unit_test/economy_trading/ui/orders/Run()
	var/mob/living/carbon/human/user = make_user(5000)
	var/datum/bank_account/own = econ_account_of(user)
	var/datum/computer_file/program/stock_exchange/program = install_program(user)
	company.price = 50
	press(user, program, "NtosStockExchange", "add_order", list("ticker" = "AGRO", "side" = STOCK_ORDER_BUY_BELOW, "count" = 3, "price" = 40))
	TEST_ASSERT_EQUAL(length(own.stock_orders), 1, "Заявка не поставлена")
	TEST_ASSERT_EQUAL(message_of(program, user), "Заявка принята: купить 3 шт. AGRO, если цена ≤ 40. Проверяется раз в минуту после смены цен.", "Ответ окна")
	press(user, program, "NtosStockExchange", "add_order", list("ticker" = "AGRO", "side" = "steal", "count" = 3, "price" = 40))
	TEST_ASSERT_EQUAL(message_of(program, user), "Неверный вид заявки.", "Неверный вид")
	press(user, program, "NtosStockExchange", "add_order", list("ticker" = "AGRO", "side" = STOCK_ORDER_SELL_ABOVE, "count" = 3, "price" = 60))
	TEST_ASSERT_EQUAL(message_of(program, user), "Акций AGRO на счёте нет.", "Продажа без акций")
	TEST_ASSERT_EQUAL(length(own.stock_orders), 1, "Отказ поставил заявку")
	company.dividend_pool = 30
	var/list/data = program.stocks_data(user)
	var/list/orders = data["orders"]
	TEST_ASSERT_EQUAL(length(orders), 1, "Окно не видит заявку")
	var/list/order = orders[1]
	TEST_ASSERT(order["ticker"] == "AGRO" && order["side"] == STOCK_ORDER_BUY_BELOW && order["count"] == 3 && order["price"] == 40, "Заявка в окне: [json_encode(order)]")
	var/list/agro_entry
	var/list/index_entry
	for(var/list/entry as anything in data["companies"])
		if(entry["ticker"] == "AGRO")
			agro_entry = entry
		if(entry["ticker"] == STOCK_INDEX_TICKER)
			index_entry = entry
	TEST_ASSERT(agro_entry["dividend_pool"] == 30 && agro_entry["dividend_per_share"] == 30, "Фонд дивидендов без держателей: [json_encode(agro_entry)]")
	TEST_ASSERT(index_entry && index_entry["index"] && !agro_entry["index"], "Индекс помечен в котировках")
	press(user, program, "NtosStockExchange", "buy", list("ticker" = "AGRO", "count" = 4))
	data = program.stocks_data(user)
	for(var/list/entry as anything in data["companies"])
		if(entry["ticker"] == "AGRO")
			agro_entry = entry
	TEST_ASSERT_EQUAL(agro_entry["dividend_per_share"], 7.5, "Выплата на акцию при четырёх акциях")
	press(user, program, "NtosStockExchange", "cancel_order", list("id" = 999))
	TEST_ASSERT_EQUAL(message_of(program, user), "Такой заявки уже нет.", "Чужой id")
	press(user, program, "NtosStockExchange", "cancel_order", list("id" = order["id"]))
	TEST_ASSERT_EQUAL(message_of(program, user), "Заявка снята.", "Ответ на снятие")
	TEST_ASSERT(!length(own.stock_orders), "Заявка не снята")

/// Счёт, до держателя которого карта достаёт и без клиента; запоминает сообщения карты.
/datum/bank_account/econ_test_evac_ear
	var/list/card_messages = list()

/datum/bank_account/econ_test_evac_ear/card_talk_reaches(mob/holder, force)
	return TRUE

/datum/bank_account/econ_test_evac_ear/bank_card_talk(message, force, talk_sound, balloon, quiet)
	card_messages += message

/// Счёт с настоящими сообщениями карты: без клиента они доходят только до listener; запоминает, кому показана всплывашка.
/datum/bank_account/econ_test_card_ear
	var/mob/listener
	var/list/reached = list()

/datum/bank_account/econ_test_card_ear/Destroy(force, ...)
	listener = null
	reached.Cut()
	return ..()

/datum/bank_account/econ_test_card_ear/card_talk_reaches(mob/holder, force)
	return holder == listener || ..()

/datum/bank_account/econ_test_card_ear/show_card_balloon(mob/holder, text)
	reached += holder

/// Счета с ID-картами на людях; карты отвязываются в Destroy().
/datum/unit_test/economy_trading/card_holders
	abstract_type = /datum/unit_test/economy_trading/card_holders
	var/list/cards = list()

/datum/unit_test/economy_trading/card_holders/Destroy()
	for(var/obj/item/card/id/card as anything in cards)
		card.registered_account?.bank_cards -= card
		card.registered_account = null
	cards.Cut()
	return ..()

/// ID-карта счёта account на holder, с доступами access.
/datum/unit_test/economy_trading/card_holders/proc/link_card(datum/bank_account/account, mob/living/carbon/human/holder, list/access = list())
	var/obj/item/card/id/card = econ_test_badge(holder, access)
	card.registered_account = account
	account.bank_cards += card
	cards += card
	return card

/// Счёт с акциями shares и его ID-карта на человеке.
/datum/unit_test/economy_trading/card_holders/proc/new_holder(list/shares, list/access = list())
	var/datum/bank_account/econ_test_evac_ear/account = new("econ_test_evac_[length(traders) + 1]")
	traders += account
	account.shares = shares
	for(var/ticker in shares)
		account.cost_basis[ticker] = 100
	link_card(account, allocate(/mob/living/carbon/human), access)
	return account

/// Сообщение карты доходит до держателя второй карты счёта, даже если первая - у того, кто его не услышит.
/datum/unit_test/economy_trading/card_holders/card_talk/Run()
	var/datum/bank_account/econ_test_card_ear/account = new("econ_test_card_ear")
	traders += account
	var/mob/living/carbon/human/sleeper = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/listener = allocate(/mob/living/carbon/human)
	link_card(account, sleeper)
	link_card(account, listener)
	account.listener = listener
	account.bank_card_talk("Биржа: проверка второй карты.", balloon = "проверка")
	TEST_ASSERT(length(account.reached) == 1 && account.reached[1] == listener, "Сообщение не дошло до второй карты: [length(account.reached)]")

/// Во время эвакуации держатель акций узнаёт с карты, что в конце смены акции продадутся по рынку, и что даст продажа сейчас: раз за каждый вызов шаттла; без акций, до вызова, после отзыва и мёртвому карта молчит, ожившему напомнит. За казну узнаёт капитан.
/datum/unit_test/economy_trading/card_holders/evac_warning
	var/saved_wave
	var/saved_underway
	var/saved_treasury_wave

/datum/unit_test/economy_trading/card_holders/evac_warning/New()
	..()
	saved_wave = SSmarket.evac_wave
	saved_underway = SSmarket.evac_was_underway
	var/datum/bank_account/treasury_account = SSeconomy.treasury()
	saved_treasury_wave = treasury_account.stock_evac_wave

/datum/unit_test/economy_trading/card_holders/evac_warning/Destroy()
	SSmarket.evac_wave = saved_wave
	SSmarket.evac_was_underway = saved_underway
	var/datum/bank_account/treasury_account = SSeconomy.treasury()
	treasury_account.stock_evac_wave = saved_treasury_wave
	return ..()

/datum/unit_test/economy_trading/card_holders/evac_warning/Run()
	company.price = 50
	var/datum/bank_account/econ_test_evac_ear/investor = new_holder(list("AGRO" = 4))
	var/datum/bank_account/econ_test_evac_ear/loser = new_holder(list("AGRO" = 4))
	loser.cost_basis["AGRO"] = 1000
	var/datum/bank_account/econ_test_evac_ear/saver = new_holder(list())
	var/datum/bank_account/econ_test_evac_ear/fallen = new_holder(list("AGRO" = 2))
	var/obj/item/card/id/fallen_card = fallen.bank_cards[1]
	var/mob/living/carbon/human/fallen_body = fallen_card.loc
	fallen_body.death()
	SSmarket.warn_holders_before_evac(SHUTTLE_IDLE)
	TEST_ASSERT(!length(investor.card_messages), "Предупреждение до вызова шаттла")
	SSmarket.warn_holders_before_evac(SHUTTLE_CALL)
	TEST_ASSERT_EQUAL(length(investor.card_messages), 1, "Держатель не узнал о продаже акций в конце смены")
	var/warning = investor.card_messages[1]
	var/list/amounts = SSmarket.sale_amounts(company, 4)
	var/profit = amounts[1] - amounts[2] - 100
	TEST_ASSERT(findtext(warning, "продадутся по рыночной цене") && findtext(warning, "[SSmarket.portfolio_value(investor)] кр."), "Предупреждение без сути или стоимости акций: [warning]")
	TEST_ASSERT(findtext(warning, "зафиксируете +[profit] кр. прибыли"), "Предупреждение без прибыли от продажи сейчас ([profit] кр.): [warning]")
	TEST_ASSERT(findtext(loser.card_messages[1], "зафиксируете [1000 - amounts[1] + amounts[2]] кр. убытка"), "Предупреждение без убытка: [loser.card_messages[1]]")
	TEST_ASSERT(!findtext(warning, "сгор"), "Предупреждение обещает, что акции сгорят: [warning]")
	TEST_ASSERT(!findtext(warning, investor.account_holder), "Предупреждение называет владельца счёта: [warning]")
	TEST_ASSERT(!length(saver.card_messages), "Предупреждение счёту без акций")
	TEST_ASSERT(!length(fallen.card_messages), "Предупреждение мёртвому держателю")
	SSmarket.warn_holders_before_evac(SHUTTLE_DOCKED)
	TEST_ASSERT_EQUAL(length(investor.card_messages), 1, "Предупреждение повторилось, пока шаттл у станции")
	SSmarket.warn_holders_before_evac(SHUTTLE_RECALL)
	TEST_ASSERT_EQUAL(length(investor.card_messages), 1, "Предупреждение после отзыва шаттла")
	SSmarket.warn_holders_before_evac(SHUTTLE_CALL)
	TEST_ASSERT_EQUAL(length(investor.card_messages), 2, "Новый вызов шаттла после отзыва не предупредил")
	fallen_body.revive(TRUE, TRUE)
	SSmarket.warn_holders_before_evac(SHUTTLE_ESCAPE)
	TEST_ASSERT_EQUAL(length(fallen.card_messages), 1, "Ожившему держателю не напомнили")
	TEST_ASSERT_EQUAL(length(investor.card_messages), 2, "Шаттл улетел - тот же вызов, а предупреждение повторилось")
	saver.shares["AGRO"] = 1
	SSmarket.warn_holders_before_evac(SHUTTLE_ENDGAME)
	TEST_ASSERT(!length(saver.card_messages), "Предупреждение после конца смены")

/// Казна без карт: о её акциях во время эвакуации узнаёт капитан на личную карту, раз за вызов шаттла; без доступа капитана - нет.
/datum/unit_test/economy_trading/card_holders/evac_warning/treasury/Run()
	var/datum/bank_account/treasury_account = use_treasury(0)
	company.price = 50
	treasury_account.shares["AGRO"] = 6
	treasury_account.cost_basis["AGRO"] = 100
	var/datum/bank_account/econ_test_evac_ear/captain = new_holder(list(), list(ACCESS_CAPTAIN))
	var/datum/bank_account/econ_test_evac_ear/clerk = new_holder(list(), list(ACCESS_HOP))
	SSmarket.warn_holders_before_evac(SHUTTLE_CALL)
	TEST_ASSERT_EQUAL(length(captain.card_messages), 1, "Капитан не узнал об акциях казны")
	TEST_ASSERT(findtext(captain.card_messages[1], "акции казны") && findtext(captain.card_messages[1], "[SSmarket.portfolio_value(treasury_account)] кр."), "Предупреждение капитану не про казну: [captain.card_messages[1]]")
	TEST_ASSERT(!length(clerk.card_messages), "Об акциях казны узнал не капитан")
	SSmarket.warn_holders_before_evac(SHUTTLE_DOCKED)
	TEST_ASSERT_EQUAL(length(captain.card_messages), 1, "Предупреждение за казну повторилось в тот же вызов")
	SSmarket.warn_holders_before_evac(SHUTTLE_RECALL)
	SSmarket.warn_holders_before_evac(SHUTTLE_CALL)
	TEST_ASSERT_EQUAL(length(captain.card_messages), 2, "Новый вызов шаттла не напомнил капитану о казне")

/// «Продать все акции» продаёт всё обычными сделками; остановленные торги и кулдаун пропускает с объяснением; пустой и замороженный счёт отказывают; из казны - только капитан в режиме казны.
/datum/unit_test/economy_trading/ui/sell_all/Run()
	var/mob/living/carbon/human/user = make_user(0)
	var/datum/bank_account/own = econ_account_of(user)
	var/datum/computer_file/program/stock_exchange/program = install_program(user)
	company.price = 50
	var/datum/stock_company/halted = SSmarket.get_company("CYBS")
	own.shares = list("AGRO" = 4, "CYBS" = 2, "VYMD" = 3)
	own.cost_basis = list("AGRO" = 100, "CYBS" = 100, "VYMD" = 100)
	own.trade_cooldowns["VYMD"] = world.time
	var/list/amounts = SSmarket.sale_amounts(company, 4)
	var/net = amounts[1] - amounts[2]
	own.state = ACCOUNT_FROZEN
	press(user, program, "NtosStockExchange", "sell_all")
	own.state = ACCOUNT_ACTIVE
	TEST_ASSERT_EQUAL(message_of(program, user), "Счёт заморожен: продать нельзя.", "Замороженный счёт продал")
	TEST_ASSERT_EQUAL(own.shares["AGRO"], 4, "Замороженный счёт продал AGRO")
	halted.halted_until = world.time + STOCK_HALT_TIME
	press(user, program, "NtosStockExchange", "sell_all")
	halted.halted_until = 0
	TEST_ASSERT_EQUAL(message_of(program, user), "Продано 4 AGRO на [net] кр. с учётом спреда и комиссии. Не продано: Торги CYBS остановлены. Слишком частые сделки по VYMD.", "Ответ на продажу всего")
	TEST_ASSERT(!own.shares["AGRO"], "AGRO не продан")
	TEST_ASSERT_EQUAL(own.shares["CYBS"], 2, "Остановленные торги продались")
	TEST_ASSERT_EQUAL(own.shares["VYMD"], 3, "Продано в кулдаун")
	TEST_ASSERT_EQUAL(own.account_balance, net, "Зачислено не как за обычную продажу")
	TEST_ASSERT_EQUAL(own.realized_stock_profit, net - 100, "Прибыль продажи всего")

	var/mob/living/carbon/human/empty = make_user(0)
	var/datum/computer_file/program/stock_exchange/empty_program = install_program(empty)
	press(empty, empty_program, "NtosStockExchange", "sell_all")
	TEST_ASSERT_EQUAL(message_of(empty_program, empty), "Продавать нечего: акций на счёте нет.", "Ответ пустому счёту")

	var/datum/bank_account/treasury_account = use_treasury(0)
	treasury_account.shares["AGRO"] = 2
	treasury_account.cost_basis["AGRO"] = 50
	var/mob/living/carbon/human/captain = make_user(0, list(ACCESS_CAPTAIN))
	var/datum/computer_file/program/stock_exchange/captain_program = install_program(captain)
	press(captain, captain_program, "NtosStockExchange", "sell_all")
	TEST_ASSERT_EQUAL(treasury_account.shares["AGRO"], 2, "Казна продала без режима казны")
	press(captain, captain_program, "NtosStockExchange", "use_treasury", list("value" = TRUE))
	press(captain, captain_program, "NtosStockExchange", "sell_all")
	TEST_ASSERT(!treasury_account.shares["AGRO"], "Капитан в режиме казны не продал её акции")
