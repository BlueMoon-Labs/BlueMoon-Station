/// Сделки на копии биржи без шума с шансом событий из конфига; биржа тикает только по вызову теста, дела аудита и кулдаун фальшивок восстанавливаются.
/datum/unit_test/economy_trading/insider
	abstract_type = /datum/unit_test/economy_trading/insider
	var/list/saved_flags
	var/saved_cooldown
	var/saved_can_fire

/datum/unit_test/economy_trading/insider/New()
	. = ..()
	saved_can_fire = SSmarket.can_fire
	SSmarket.can_fire = FALSE
	saved_flags = SSeconomy.audit_flags
	SSeconomy.audit_flags = list()
	saved_cooldown = SSeconomy.settings.press_release_cooldown_minutes
	SSmarket.company_event_chance = saved_market["company_event_chance"]
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/each = SSmarket.companies[ticker]
		each.volatility = 0

/datum/unit_test/economy_trading/insider/Destroy()
	QDEL_LIST(SSeconomy.audit_flags)
	SSeconomy.audit_flags = saved_flags
	SSeconomy.settings.press_release_cooldown_minutes = saved_cooldown
	SSmarket.can_fire = saved_can_fire
	return ..()

/datum/unit_test/economy_trading/insider/proc/insider_flags(datum/bank_account/account)
	. = list()
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.flags_for(account))
		if(flag.kind == AUDIT_FLAG_INSIDER)
			. += flag

/// Акций на сумму чуть выше порога инсайда по текущей цене.
/datum/unit_test/economy_trading/insider/proc/over_threshold(datum/stock_company/target)
	return round(SSeconomy.settings.audit_insider_threshold / target.price) + 1

/datum/unit_test/economy_trading/insider/proc/queued_refutation(datum/stock_company/target)
	for(var/datum/market_event/event as anything in SSmarket.scheduled_events)
		if(event.company == target && event.refutes)
			return event

/// Минутный тик биржи без новых случайных событий.
/datum/unit_test/economy_trading/insider/proc/market_tick()
	var/chance = SSmarket.company_event_chance
	SSmarket.company_event_chance = 0
	SSmarket.tick_stocks()
	SSmarket.company_event_chance = chance

/datum/unit_test/economy_trading/insider/proc/release_on_tick(datum/market_event/event)
	event.eta = world.time
	market_tick()

/// Фальшивый релиз сдвигает цену только на тике, как настоящее событие того же знака, выходит новостью и не двигает денег; опровержение через настройку после выхода возвращает цену, кулдаун со случайной добавкой держит второй релиз, о той же компании - не проходит.
/datum/unit_test/economy_trading/insider/fake_release/Run()
	var/minted = SSeconomy.ledger.minted
	var/burned = SSeconomy.ledger.burned
	var/money = SSeconomy.total_money()
	var/price_before = company.price
	var/headline = SSmarket.fake_press_release(company, TRUE, "тестовый источник")
	TEST_ASSERT(headline, "Релиз не вышел")
	TEST_ASSERT_EQUAL(company.price, price_before, "Фальшивка сдвинула цену между тиками")
	var/cooldown = SSeconomy.settings.press_release_cooldown_minutes MINUTES
	var/wait_left = SSmarket.press_release_ready_at - world.time
	TEST_ASSERT(wait_left >= cooldown - 1 SECONDS && wait_left <= cooldown * (1 + PRESS_RELEASE_COOLDOWN_JITTER) + 1 SECONDS, "Кулдаун [wait_left] вне [cooldown]..[cooldown * (1 + PRESS_RELEASE_COOLDOWN_JITTER)]")
	TEST_ASSERT_NULL(queued_refutation(company), "Опровержение до выхода фальшивки")
	market_tick()
	var/effect = company.price / price_before - 1
	var/matched = FALSE
	for(var/list/template as anything in SSmarket.company_event_templates)
		if(template["effect"] > 0 && abs(template["effect"] - effect) < 0.001 && replacetext(template["headline"], "%NAME%", company.name) == headline)
			matched = TRUE
	TEST_ASSERT(matched, "Сдвиг [effect] и заголовок \"[headline]\" не совпадают ни с одним настоящим хорошим событием")
	TEST_ASSERT(findtext(jointext(SSmarket.pending_news, "|"), html_encode(headline)), "Новость о релизе не ушла в \"Сводку сектора\"")
	var/datum/market_event/refutation = queued_refutation(company)
	TEST_ASSERT_NOTNULL(refutation, "Опровержение не встало в очередь")
	TEST_ASSERT(abs(refutation.eta - world.time - SSeconomy.settings.press_release_refute_minutes MINUTES) < 1 SECONDS, "Срок опровержения не от выхода фальшивки")
	TEST_ASSERT(refutation.fake, "Опровержение видно пейджеру как настоящее событие")
	var/list/saved = SSmarket.serialize_state()
	var/list/saved_agro = saved["companies"]["AGRO"]
	TEST_ASSERT(abs(saved_agro["price_ratio"] - price_before / company.base_price) < 0.0001 && abs(saved_agro["event_mult"] - 1) < 0.0001, "Фальшивка до опровержения переходит в следующую смену")
	var/datum/stock_company/other = SSmarket.get_company("NKMR")
	TEST_ASSERT(findtext(SSmarket.press_release_problem(other), "через"), "Кулдаун сектора не держит второй релиз")
	TEST_ASSERT_NULL(SSmarket.fake_press_release(other, FALSE), "Второй релиз прошёл в кулдаун")
	release_on_tick(refutation)
	TEST_ASSERT_EQUAL(round(company.price, 0.01), round(price_before, 0.01), "Опровержение не вернуло цену")
	TEST_ASSERT(abs(company.event_mult - 1) < 0.0001, "Опровержение не вернуло накопленный эффект событий")
	TEST_ASSERT(findtext(jointext(SSmarket.pending_news, "|"), "фальшивый пресс-релиз, тестовый источник"), "Опровержение не вышло новостью")
	SSmarket.press_release_ready_at = world.time
	TEST_ASSERT(findtext(SSmarket.press_release_problem(company), "уже выходил"), "Вторая фальшивка о той же компании за смену")
	TEST_ASSERT_NULL(SSmarket.press_release_problem(other), "Другая компания после кулдауна")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted, "Релиз напечатал деньги")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned, burned, "Релиз сжёг деньги")
	TEST_ASSERT_EQUAL(SSeconomy.total_money(), money, "Релиз сдвинул деньги")

/// У потолка хорошая фальшивка не принимается и ничего не тратит; цена и накопленный эффект после опровержения возвращаются каждый своим множителем, даже когда фальшивку срезал потолок.
/datum/unit_test/economy_trading/insider/caps/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	econ_test_traitor(user)
	var/obj/item/press_release_kit/kit = allocate(/obj/item/press_release_kit)
	user.put_in_hands(kit)
	company.event_mult = STOCK_EVENT_MULT_MAX
	TEST_ASSERT(findtext(SSmarket.press_release_problem(company, TRUE), "потолке"), "Хорошая фальшивка на потолке event_mult")
	TEST_ASSERT(!kit.use_kit(user, company, TRUE), "Релиз без запаса принят")
	TEST_ASSERT(!QDELETED(kit) && !length(SSmarket.press_released) && !SSmarket.press_release_ready_at, "Отказ потратил черновик или кулдаун")
	TEST_ASSERT_NULL(SSmarket.press_release_problem(company, FALSE), "Плохая новость на потолке")
	company.event_mult = 2.9
	company.price = company.base_price * 4.9
	TEST_ASSERT(SSmarket.fake_press_release(company, TRUE), "Релиз у потолка не вышел")
	market_tick()
	TEST_ASSERT(abs(company.event_mult - STOCK_EVENT_MULT_MAX) < 0.0001 && abs(company.price - company.base_price * STOCK_PRICE_MAX_RATIO) < 0.01, "Фальшивка не упёрлась в потолки")
	release_on_tick(queued_refutation(company))
	TEST_ASSERT(abs(company.event_mult - 2.9) < 0.0001, "Накопленный эффект после опровержения [company.event_mult]")
	TEST_ASSERT(abs(company.price - company.base_price * 4.9) < 0.01, "Цена после опровержения [company.price]")

/// "Купил после плохой новости - продал после опровержения" в игре даёт модельный выигрыш; по общему расчёту ожидание лучшей публичной стратегии ниже порога окупаемости, на тихой бирже и при опасном кулдауне релиз не принимается, а конфиг поднимает кулдаун.
/datum/unit_test/economy_trading/insider/refutation_expectation/Run()
	var/datum/bank_account/trader = new_trader(50000)
	var/price_before = company.price
	TEST_ASSERT(SSmarket.fake_press_release(company, FALSE), "Релиз не вышел")
	market_tick()
	var/effect = company.price / price_before - 1
	var/start = trader.account_balance
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(trader, "AGRO", 200), "Покупка после плохой новости")
	var/spent = start - trader.account_balance
	release_on_tick(queued_refutation(company))
	expire_cooldown(trader, "AGRO")
	var/before_sell = trader.account_balance
	TEST_ASSERT_NULL(SSmarket.try_sell_shares(trader, "AGRO", 200), "Продажа после опровержения")
	var/measured = (trader.account_balance - before_sell) / spent
	var/model = 1 / (1 + effect) / breakeven()
	TEST_ASSERT(abs(measured - model) < 0.005, "Круг через опровержение дал [measured], модель [model]")

	var/list/negative = list()
	var/list/positive = list()
	for(var/list/template as anything in SSmarket.company_event_templates)
		if(template["effect"] < 0)
			negative += template["effect"]
		else if(template["effect"] > 0)
			positive += template["effect"]
	var/cycle_minutes = 100 / SSmarket.company_event_chance + STOCK_EVENT_ETA_MAX / (1 MINUTES)
	var/real_per_hour = SSmarket.real_company_count() * 60 / cycle_minutes
	var/fakes_per_hour = 60 / SSmarket.press_release_cooldown()
	var/total = length(SSmarket.company_event_templates)
	var/negative_share = fakes_per_hour / (fakes_per_hour + real_per_hour * length(negative) / total)
	var/positive_share = fakes_per_hour / (fakes_per_hour + real_per_hour * length(positive) / total)
	var/best = 1
	for(var/each_effect in negative)
		best = max(best, 1 + negative_share * (1 / (1 + each_effect) - 1))
	for(var/each_effect in positive)
		best = max(best, 1 + positive_share * each_effect)
	var/edge = SSmarket.press_release_edge()
	TEST_ASSERT(abs(edge - best / breakeven()) < 0.000001, "Расчёт ожидания [edge] расходится с проверочным [best / breakeven()]")
	TEST_ASSERT(edge < 1, "При конфиге публичная стратегия окупается: [edge]")

	var/datum/stock_company/other = SSmarket.get_company("NKMR")
	SSmarket.press_release_ready_at = 0
	var/list/halted = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/each = SSmarket.companies[ticker]
		if(each != other && length(halted) < length(SSmarket.companies) / 2)
			each.halted_until = world.time + STOCK_HALT_TIME
			halted += each
	TEST_ASSERT(findtext(SSmarket.press_release_problem(other, FALSE), "тихо"), "Половина биржи стоит, а релиз принимается: [SSmarket.press_release_edge()]")
	for(var/datum/stock_company/each as anything in halted)
		each.halted_until = 0
	TEST_ASSERT_EQUAL(SSmarket.press_release_cooldown(), SSeconomy.settings.press_release_cooldown_minutes, "Безопасный кулдаун из конфига подменён")
	TEST_ASSERT_EQUAL(length(SSmarket.check_press_release_cooldown()), 0, "Ошибка на безопасном кулдауне")
	SSeconomy.settings.press_release_cooldown_minutes = 10
	TEST_ASSERT(SSmarket.press_release_edge(10, SSmarket.real_company_count()) >= 1, "Кулдаун 10 мин. считается безопасным")
	TEST_ASSERT_EQUAL(length(SSmarket.check_press_release_cooldown()), 1, "Опасный кулдаун без ошибки настройки")
	TEST_ASSERT(SSmarket.press_release_cooldown() > 10 && SSmarket.press_release_edge() < 1, "Действующий кулдаун не безопасен: [SSmarket.press_release_cooldown()]")
	TEST_ASSERT_EQUAL(SSeconomy.settings.press_release_cooldown_minutes, 10, "Проверка переписала настройку")
	TEST_ASSERT(SSmarket.fake_press_release(other, FALSE), "Релиз при поднятом кулдауне")
	TEST_ASSERT(SSmarket.press_release_ready_at - world.time >= SSmarket.press_release_cooldown() MINUTES - 1 SECONDS, "Релиз взял опасный кулдаун из настройки")
	SSeconomy.settings.press_release_cooldown_minutes = saved_cooldown
	SSmarket.company_event_templates += list(list("key" = "moon", "headline" = "%NAME% строит базу на Луне", "effect" = 0.45))
	TEST_ASSERT(SSmarket.press_release_edge(saved_cooldown, SSmarket.real_company_count()) >= 1, "Большой хороший шаблон считается безопасным: продать после хорошей новости и откупить окупается")
	TEST_ASSERT_EQUAL(length(SSmarket.check_press_release_cooldown()), 1, "Большой хороший шаблон без ошибки настройки")
	SSmarket.company_event_templates.len--
	SSmarket.company_event_chance = 0
	SSmarket.press_release_ready_at = 0
	TEST_ASSERT(findtext(SSmarket.press_release_problem(SSmarket.get_company("EINS"), FALSE), "отключены"), "Отказ при выключенных событиях не говорит правду")

/// Шаблон из конфига с ключом опровержения остаётся обычным событием: опровержение опознаётся по ссылке на фальшивку.
/datum/unit_test/economy_trading/insider/refutation_key_template/Run()
	var/price_before = company.price
	var/datum/market_event/event = SSmarket.schedule_company_event(company, STOCK_REFUTATION_KEY, "Настоящее событие с ключом опровержения", 0.2, STOCK_EVENT_ETA_MIN)
	release_on_tick(event)
	TEST_ASSERT(abs(company.price - price_before * 1.2) < 0.01 && abs(company.event_mult - 1.2) < 0.0001, "Событие с ключом опровержения сработало не как событие: [company.price], [company.event_mult]")
	TEST_ASSERT(abs(company.last_real_event_at - world.time) < 1 SECONDS, "Не учтено как настоящее событие")

/// Фальшивка ждёт, пока у компании стоит настоящая новость и ещё STOCK_EVENT_ETA_MIN с тиком после её выхода; черновик тратится сразу, фальшивка не теряется.
/datum/unit_test/economy_trading/insider/hold_near_real/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	econ_test_traitor(user)
	var/obj/item/press_release_kit/kit = allocate(/obj/item/press_release_kit)
	user.put_in_hands(kit)
	var/datum/market_event/real = SSmarket.schedule_company_event(company, "contract_won", "Настоящий контракт", 0.2, STOCK_EVENT_ETA_MIN)
	var/price_before = company.price
	TEST_ASSERT(kit.use_kit(user, company, FALSE), "Черновик не принят")
	TEST_ASSERT(QDELETED(kit), "Черновик не потрачен")
	market_tick()
	TEST_ASSERT_EQUAL(company.price, price_before, "Фальшивка вышла, пока в очереди настоящая новость")
	release_on_tick(real)
	var/after_real = company.price
	TEST_ASSERT(abs(after_real - price_before * 1.2) < 0.01, "Настоящая новость не вышла")
	TEST_ASSERT_NULL(queued_refutation(company), "Фальшивка вышла вместе с настоящей новостью")
	market_tick()
	TEST_ASSERT_EQUAL(company.price, after_real, "Фальшивка вышла сразу после настоящей новости")
	company.last_real_event_at -= STOCK_EVENT_ETA_MIN + SSmarket.wait + 1 SECONDS
	market_tick()
	TEST_ASSERT(company.price < after_real, "Фальшивка не вышла после паузы")
	TEST_ASSERT_NOTNULL(queued_refutation(company), "Опровержение не встало после выхода")

/// Крупные сделки в сторону события после его постановки в очередь - дело аудита с биржи на трейдера, повтор дописывает новость в открытое дело; сделки до очереди, мелкие, встречные, взаимно погашенные и после выхода новости - нет.
/datum/unit_test/economy_trading/insider/flag_real/Run()
	var/count = over_threshold(company)
	var/datum/bank_account/early = new_trader(20000)
	var/datum/bank_account/insider = new_trader(30000)
	var/datum/bank_account/splitter = new_trader(20000)
	var/datum/bank_account/small = new_trader(20000)
	var/datum/bank_account/washer = new_trader(20000)
	var/datum/bank_account/seller = new_trader(20000)
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(early, "AGRO", count), "Покупка до события")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(seller, "AGRO", count), "Покупка продавца")
	var/datum/market_event/event = SSmarket.schedule_company_event(company, "merger", "Тестовое слияние", 0.25, STOCK_EVENT_ETA_MIN)
	var/value = round(count * company.price)
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(insider, "AGRO", count), "Покупка инсайдера")
	var/half = round(count / 2) + 1
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(splitter, "AGRO", half), "Первая часть")
	expire_cooldown(splitter, "AGRO")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(splitter, "AGRO", half), "Вторая часть")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(small, "AGRO", round(count / 2)), "Мелкая покупка")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(washer, "AGRO", count), "Покупка с обратной продажей")
	expire_cooldown(washer, "AGRO")
	TEST_ASSERT_NULL(SSmarket.try_sell_shares(washer, "AGRO", count), "Обратная продажа")
	expire_cooldown(seller, "AGRO")
	TEST_ASSERT_NULL(SSmarket.try_sell_shares(seller, "AGRO", count), "Встречная продажа")
	release_on_tick(event)
	var/list/flags = insider_flags(insider)
	TEST_ASSERT_EQUAL(length(flags), 1, "Инсайд не замечен")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT_EQUAL(flag.account_number, SSeconomy.market_account.account_id, "Источник дела - не биржа")
	TEST_ASSERT_EQUAL(flag.counterparty_number, insider.account_id, "Получатель дела - не инсайдер")
	TEST_ASSERT(abs(flag.amount - round(value * 0.25)) <= 1, "Сумма дела [flag.amount] не выгода от сдвига [round(value * 0.25)]")
	TEST_ASSERT_EQUAL(length(insider_flags(splitter)), 1, "Дробная покупка не замечена")
	for(var/datum/bank_account/clean as anything in list(early, small, washer, seller))
		TEST_ASSERT_EQUAL(length(insider_flags(clean)), 0, "Ложное дело у [clean.account_holder]")

	var/datum/bank_account/after_news = new_trader(20000)
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(after_news, "AGRO", over_threshold(company)), "Покупка после новости")
	var/datum/market_event/next = SSmarket.schedule_company_event(company, "contract_won", "Тестовый контракт", 0.2, STOCK_EVENT_ETA_MIN)
	expire_cooldown(insider, "AGRO")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(insider, "AGRO", over_threshold(company)), "Вторая покупка инсайдера")
	release_on_tick(next)
	TEST_ASSERT_EQUAL(length(insider_flags(after_news)), 0, "Честная покупка после новости попала в дело следующего события")
	flags = insider_flags(insider)
	TEST_ASSERT_EQUAL(length(flags), 1, "Повтор открыл второе дело")
	flag = flags[1]
	TEST_ASSERT(findtext(flag.text, "Тестовое слияние") && findtext(flag.text, "Тестовый контракт"), "Открытое дело не дописало новость: [flag.text]")

	expire_cooldown(early, "AGRO")
	var/datum/market_event/scandal = SSmarket.schedule_company_event(company, "scandal", "Тестовый скандал", -0.2, STOCK_EVENT_ETA_MIN)
	TEST_ASSERT_NULL(SSmarket.try_sell_shares(early, "AGRO", count), "Продажа перед плохой новостью")
	release_on_tick(scandal)
	TEST_ASSERT_EQUAL(length(insider_flags(early)), 1, "Продажа перед плохой новостью не замечена")

/// Дело инсайда помнит, кто торговал: аудитор не закрывает дело по своим сделкам.
/datum/unit_test/economy_trading/insider/flag_actors/Run()
	var/mob/living/carbon/human/auditor = allocate(/mob/living/carbon/human)
	auditor.mind_initialize()
	econ_test_badge(auditor, list(ACCESS_HOS))
	var/datum/bank_account/insider = new_trader(30000)
	var/datum/market_event/event = SSmarket.schedule_company_event(company, "merger", "Тестовое слияние", 0.25, STOCK_EVENT_ETA_MIN)
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(insider, "AGRO", over_threshold(company), auditor), "Покупка инсайдера")
	release_on_tick(event)
	var/list/flags = insider_flags(insider)
	TEST_ASSERT_EQUAL(length(flags), 1, "Инсайд не замечен")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT(flag.acted_by(auditor), "Дело инсайда не помнит трейдера")
	TEST_ASSERT_EQUAL(SSeconomy.close_case_problem(flag.uid, auditor), AUDIT_OWN_MOVES_REFUSAL, "Аудитор закрывает дело по своим сделкам")

/// Сделка в сторону фальшивого релиза за окно до него - дело с пометкой о фальшивке, старше окна - нет; автор, купивший на просадке после своей плохой фальшивки, пойман опровержением, честная мелкая покупка на просадке - нет.
/datum/unit_test/economy_trading/insider/flag_fake/Run()
	var/count = over_threshold(company)
	var/datum/bank_account/pumper = new_trader(20000)
	var/datum/bank_account/stale = new_trader(20000)
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(stale, "AGRO", count), "Давняя покупка")
	var/list/stale_trade = SSmarket.recent_trades[length(SSmarket.recent_trades)]
	stale_trade[INSIDER_TRADE_TIME] -= (SSeconomy.settings.audit_insider_window_minutes + 1) MINUTES
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(pumper, "AGRO", count), "Покупка перед релизом")
	var/headline = SSmarket.fake_press_release(company, TRUE)
	TEST_ASSERT(headline, "Релиз не вышел")
	market_tick()
	var/list/flags = insider_flags(pumper)
	TEST_ASSERT_EQUAL(length(flags), 1, "Покупка перед релизом не замечена")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT(findtext(flag.text, "фальшивого пресс-релиза \"[headline]\""), "Дело не говорит, что новость фальшивая: [flag.text]")
	TEST_ASSERT_EQUAL(length(insider_flags(stale)), 0, "Сделка старше окна попала в дело")
	release_on_tick(queued_refutation(company))

	var/datum/stock_company/other = SSmarket.get_company("PRSP")
	SSmarket.press_release_ready_at = 0
	var/datum/bank_account/author = new_trader(20000)
	var/datum/bank_account/dip_buyer = new_trader(20000)
	var/fake_headline = SSmarket.fake_press_release(other, FALSE)
	TEST_ASSERT(fake_headline, "Плохой релиз не вышел")
	market_tick()
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(author, "PRSP", over_threshold(other)), "Автор покупает на просадке")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(dip_buyer, "PRSP", round(over_threshold(other) / 2)), "Мелкая покупка на просадке")
	release_on_tick(queued_refutation(other))
	flags = insider_flags(author)
	TEST_ASSERT_EQUAL(length(flags), 1, "Автор фальшивки не пойман опровержением")
	flag = flags[1]
	TEST_ASSERT(findtext(flag.text, "после фальшивого пресс-релиза \"[fake_headline]\""), "Дело не говорит о фальшивке: [flag.text]")
	TEST_ASSERT_EQUAL(length(insider_flags(dip_buyer)), 0, "Мелкая покупка на просадке попала в дело")

/// Экран пейджера показывает настоящее событие в очереди со сроком и не показывает фальшивку и её опровержение.
/datum/unit_test/economy_trading/insider/pager/Run()
	var/obj/item/insider_pager/pager = allocate(/obj/item/insider_pager)
	var/mob/living/carbon/human/reader = allocate(/mob/living/carbon/human)
	reader.put_in_hands(pager)
	TEST_ASSERT_EQUAL(length(pager.queued_events()), 0, "Пустой пейджер")
	SSmarket.schedule_company_event(company, "contract_won", "Настоящее событие", 0.2, STOCK_EVENT_ETA_MIN)
	var/fake_headline = SSmarket.fake_press_release(SSmarket.get_company("NKMR"), FALSE)
	TEST_ASSERT(fake_headline, "Релиз не вышел")
	var/list/screen = pager.queued_events()
	TEST_ASSERT_EQUAL(length(screen), 1, "Пейджер видит фальшивку")
	var/list/entry = screen[1]
	TEST_ASSERT(entry["ticker"] == "AGRO" && entry["headline"] == "Настоящее событие" && entry["effect"] == 20 && entry["eta"] > 0, "Пейджер не показывает настоящее событие: [json_encode(entry)]")
	market_tick()
	screen = pager.queued_events()
	TEST_ASSERT_EQUAL(length(screen), 1, "Пейджер видит опровержение: [json_encode(screen)]")
	pager.attack_self(reader)

/// Мигание пейджера при событии в очереди видит только держатель-предатель, сам пейджер для всех обычный.
/datum/unit_test/economy_trading/insider/pager_alert/Run()
	var/obj/item/insider_pager/pager = allocate(/obj/item/insider_pager)
	var/mob/living/carbon/human/traitor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human)
	econ_test_traitor(traitor)
	traitor.put_in_hands(pager)
	TEST_ASSERT_NULL(pager.alert, "Без событий пейджер не мигает")
	SSmarket.schedule_company_event(company, "contract_won", "Настоящее событие", 0.2, STOCK_EVENT_ETA_MIN)
	market_tick()
	TEST_ASSERT_EQUAL(pager.icon_state, "pager", "Событие в очереди изменило пейджер для всех")
	var/datum/atom_hud/alternate_appearance/basic/onePerson/alert = pager.alert
	TEST_ASSERT_NOTNULL(alert, "Держатель-предатель не видит мигания")
	TEST_ASSERT(alert.hudusers[traitor] && !alert.hudusers[outsider], "Мигание видит не только держатель")
	TEST_ASSERT_EQUAL(alert.theImage.icon_state, "pager_alert", "Мигание - стейт pager_alert")
	traitor.dropItemToGround(pager)
	TEST_ASSERT(isnull(pager.alert) && QDELETED(alert), "Выброшенный пейджер мигает")
	outsider.put_in_hands(pager)
	market_tick()
	TEST_ASSERT_NULL(pager.alert, "Пейджер мигает в руках постороннего")
	TEST_ASSERT_EQUAL(pager.icon_state, "pager", "Пейджер постороннего изменился")

/// Емаг перепрошивает ньюскастер за один заряд, повтор заряд не тратит; ньюскастер выпускает один релиз с местом в опровержении, мультитул сбрасывает взлом.
/datum/unit_test/economy_trading/insider/newscaster/Run()
	var/mob/living/carbon/human/hacker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	econ_test_traitor(hacker)
	var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/machinery/newscaster/caster = allocate(/obj/machinery/newscaster, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/item/card/emag/emag = allocate(/obj/item/card/emag)
	hacker.put_in_hands(emag)
	var/uses = emag.uses
	caster.AltClick(hacker)
	TEST_ASSERT(!caster.issue_press_release(hacker, company, TRUE), "Релиз с невзломанного ньюскастера")
	var/saved_round_type = GLOB.round_type
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	emag.melee_attack_chain(hacker, caster)
	var/light_hacked = caster.econ_hacked
	var/light_uses = emag.uses
	GLOB.round_type = saved_round_type
	TEST_ASSERT(!light_hacked, "В Лайте емаг перепрошил ньюскастер под фальшивки")
	TEST_ASSERT_EQUAL(light_uses, uses, "В Лайте бесполезный взлом потратил заряд")
	emag.melee_attack_chain(hacker, caster)
	TEST_ASSERT(caster.econ_hacked, "Емаг не взломал ньюскастер")
	TEST_ASSERT_EQUAL(emag.uses, uses - 1, "Взлом не потратил заряд")
	emag.melee_attack_chain(hacker, caster)
	TEST_ASSERT_EQUAL(emag.uses, uses - 1, "Повторный взлом потратил заряд")
	caster.AltClick(hacker)
	TEST_ASSERT(caster.econ_hacked && !length(SSmarket.press_released), "Alt-клик без выбора выпустил релиз")
	caster.set_machine_stat(NOPOWER)
	TEST_ASSERT(!caster.issue_press_release(hacker, company, TRUE), "Релиз с обесточенного ньюскастера")
	caster.set_machine_stat(0)
	TEST_ASSERT(!caster.issue_press_release(outsider, company, TRUE), "Взломанный ньюскастер выпустил релиз не предателю")
	var/price_before = company.price
	TEST_ASSERT(caster.issue_press_release(hacker, company, TRUE), "Взломанный ньюскастер не выпустил релиз")
	TEST_ASSERT(!caster.econ_hacked, "Взлом не одноразовый")
	market_tick()
	TEST_ASSERT(company.price > price_before, "Цена не выросла на тике")
	var/datum/market_event/refutation = queued_refutation(company)
	TEST_ASSERT(findtext(refutation.headline, get_area_name(caster, TRUE)), "Опровержение не называет место ньюскастера: [refutation.headline]")
	emag.melee_attack_chain(hacker, caster)
	TEST_ASSERT(caster.econ_hacked, "Повторный взлом после релиза")
	var/obj/item/multitool/tool = allocate(/obj/item/multitool)
	hacker.put_in_hands(tool)
	tool.melee_attack_chain(hacker, caster)
	TEST_ASSERT(!caster.econ_hacked, "Мультитул не сбросил взлом")

/// Черновик релиза: одноразовый, отказ не тратит его; не предателю и в Лайте не работает.
/datum/unit_test/economy_trading/insider/kit/Run()
	var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human)
	var/obj/item/press_release_kit/kit = allocate(/obj/item/press_release_kit)
	outsider.put_in_hands(kit)
	TEST_ASSERT(!kit.use_kit(outsider, company, FALSE), "Черновик сработал у не предателя")
	TEST_ASSERT(!QDELETED(kit) && !length(SSmarket.press_released), "Отказ не предателю потратил черновик")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	econ_test_traitor(user)
	user.put_in_hands(kit)
	kit.attack_self(user)
	TEST_ASSERT(!QDELETED(kit), "Черновик пропал без выбора")
	var/saved_round_type = GLOB.round_type
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/light_used = kit.use_kit(user, company, FALSE)
	var/light_problem = SSmarket.press_release_problem(company, FALSE, user.mind)
	GLOB.round_type = saved_round_type
	TEST_ASSERT(!light_used && !QDELETED(kit), "Черновик сработал в Лайте")
	TEST_ASSERT(length(light_problem), "В Лайте нет объяснения отказа")
	SSmarket.press_release_ready_at = world.time + 1 MINUTES
	TEST_ASSERT(!kit.use_kit(user, company, FALSE), "Релиз прошёл в кулдаун")
	TEST_ASSERT(!QDELETED(kit), "Отказ потратил черновик")
	SSmarket.press_release_ready_at = 0
	TEST_ASSERT(kit.use_kit(user, company, FALSE), "Черновик не сработал")
	TEST_ASSERT(QDELETED(kit), "Черновик не одноразовый")

/// Описания в аплинке берут числа из настроек; предметы только у предателей.
/datum/unit_test/economy_trading/insider/uplink_text/Run()
	var/datum/uplink_item/stealthy_tools/insider_pager/pager_item = allocate(/datum/uplink_item/stealthy_tools/insider_pager)
	var/datum/uplink_item/stealthy_tools/press_release/release_item = allocate(/datum/uplink_item/stealthy_tools/press_release)
	var/cooldown = SSeconomy.settings.press_release_cooldown_minutes
	var/threshold_text = "[SSeconomy.settings.audit_insider_threshold] кр."
	TEST_ASSERT(!findtext(pager_item.desc, threshold_text) && !findtext(release_item.desc, threshold_text), "Порог инсайда в описаниях аплинка")
	TEST_ASSERT(findtext(pager_item.desc, "Крупные сделки в сторону события"), "Инсайд в описании пейджера")
	TEST_ASSERT(findtext(release_item.desc, "Через [SSeconomy.settings.press_release_refute_minutes] мин."), "Срок опровержения в описании релиза")
	TEST_ASSERT(findtext(release_item.desc, "через [cooldown]-[round(cooldown * (1 + PRESS_RELEASE_COOLDOWN_JITTER))] мин."), "Кулдаун в описании релиза")
	TEST_ASSERT_EQUAL(pager_item.purchasable_from, UPLINK_TRAITORS, "Пейджер только у предателей")
	TEST_ASSERT_EQUAL(release_item.purchasable_from, UPLINK_TRAITORS, "Релиз только у предателей")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_LIGHT in release_item.blocked_round_types, "Релиз продаётся в Лайте")
	TEST_ASSERT_EQUAL(pager_item.cost, 3, "Цена пейджера")
	TEST_ASSERT_EQUAL(release_item.cost, 2, "Цена релиза")

/// Пейджер, черновик и взломанный ньюскастер создаются и удаляются чисто.
/datum/unit_test/economy_trading/insider/create_and_destroy/Run()
	var/obj/item/insider_pager/pager = new(run_loc_floor_bottom_left)
	var/obj/item/press_release_kit/kit = new(run_loc_floor_bottom_left)
	var/obj/machinery/newscaster/caster = new(run_loc_floor_bottom_left)
	caster.econ_hacked = TRUE
	qdel(pager)
	qdel(kit)
	qdel(caster)
	TEST_ASSERT(QDELETED(pager) && QDELETED(kit) && QDELETED(caster), "Не удалились")
	TEST_ASSERT(!(caster in GLOB.allCasters), "Ньюскастер остался в списке")
