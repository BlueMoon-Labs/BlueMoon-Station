/// Десять компаний из конфига и индекс сектора, цены положительные, у каждой компании логотип, у каждого партнёра с компанией она есть на бирже.
/datum/unit_test/economy_stocks_loaded/Run()
	TEST_ASSERT_EQUAL(SSmarket.real_company_count(), 10, "Десять компаний")
	var/datum/asset/spritesheet/simple/economy_logos/logos = get_asset_datum(/datum/asset/spritesheet/simple/economy_logos)
	for(var/ticker in GLOB.market_default_companies)
		TEST_ASSERT(logos.assets["logo-[lowertext(ticker)]"], "Нет логотипа [ticker]")
	var/datum/stock_company/fund = SSmarket.get_company(STOCK_INDEX_TICKER)
	TEST_ASSERT(istype(fund, /datum/stock_company/index), "Нет индекса сектора")
	TEST_ASSERT_EQUAL(length(SSmarket.companies), 11, "Компании и индекс")
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT_EQUAL(company.ticker, ticker, "Тикер компании")
		TEST_ASSERT(company.price > 0, "[ticker] цена")
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		if(partner.company)
			TEST_ASSERT_NOTNULL(SSmarket.get_company(partner.company), "Нет компании [partner.company] партнёра [id]")

/// Без событий цена блуждает без сноса, остаётся положительной и не выше потолка; история ограничена.
/datum/unit_test/economy_stocks_tick/Run()
	rand_seed(99)
	var/datum/stock_company/company = new
	company.base_price = 100
	company.price = 40
	company.volatility = 0.05
	for(var/i in 1 to 120)
		company.tick()
		TEST_ASSERT(company.price > 0 && company.price <= company.base_price * STOCK_PRICE_MAX_RATIO, "Цена вне коридора: [company.price]")
	company.halted_until = 0
	company.volatility = 0
	var/price_before = company.price
	company.tick()
	TEST_ASSERT_EQUAL(company.price, price_before, "Цена без шума сдвинулась")
	TEST_ASSERT_EQUAL(length(company.history), STOCK_HISTORY_MAX, "История ограничена")
	var/list/entry = company.ui_entry()
	TEST_ASSERT(abs(entry["change"] - (company.price - company.history[1]) / company.history[1] * 100) < 0.1, "Изменение в процентах от начала истории: [entry["change"]]")
	TEST_ASSERT(abs(entry["price"] - company.price) < 0.01 && !entry["halted"], "Цена и статус в ui_entry")
	qdel(company)
	rand_seed(world.realtime + world.timeofday)

/// Падение ниже 5% базы останавливает торги, затем повторный листинг на 20% базы.
/datum/unit_test/economy_stocks_bankruptcy/Run()
	var/datum/stock_company/company = new
	company.base_price = 100
	company.price = 4
	company.tick()
	TEST_ASSERT(company.is_halted(), "Торги остановлены")
	var/halted_price = company.price
	company.tick()
	TEST_ASSERT(company.is_halted() && company.price == halted_price, "Цена стоит, пока торги остановлены")
	company.halted_until = world.time - 1
	company.tick()
	TEST_ASSERT(!company.is_halted(), "Торги возобновлены")
	TEST_ASSERT(company.price >= 100 * STOCK_RELIST_RATIO * 0.9, "Повторный листинг около 20% базы: [company.price]")
	qdel(company)

/// Тесты на изолированной копии рынка и биржи из конфига репозитория, состояние SSmarket возвращается.
/datum/unit_test/economy_stocks
	abstract_type = /datum/unit_test/economy_stocks
	var/list/saved_market
	var/saved_centcom_message
	var/list/company_events = list()

/datum/unit_test/economy_stocks/New()
	..()
	saved_market = econ_test_swap_market()
	SSmarket.next_shift = world.time + 1 HOURS
	SSmarket.next_restock = world.time + 1 HOURS
	SSmarket.next_offers = world.time + 1 HOURS
	saved_centcom_message = SSshuttle.centcom_message
	RegisterSignal(SSmarket, COMSIG_MARKET_COMPANY_EVENT, PROC_REF(on_company_event))

/datum/unit_test/economy_stocks/Destroy()
	UnregisterSignal(SSmarket, COMSIG_MARKET_COMPANY_EVENT)
	company_events.Cut()
	SSshuttle.centcom_message = saved_centcom_message
	econ_test_restore_market(saved_market)
	rand_seed(world.realtime + world.timeofday)
	return ..()

/datum/unit_test/economy_stocks/proc/on_company_event(datum/source, datum/market_event/event)
	SIGNAL_HANDLER
	company_events += "[event.company.ticker]:[event.key]"

/// Событие планируется заранее и выходит в момент ETA, сразу двигая цену.
/datum/unit_test/economy_stocks/scheduled_event/Run()
	var/datum/stock_company/company = SSmarket.get_company("VYMD")
	var/price_before = company.price
	var/datum/market_event/later = SSmarket.schedule_company_event(company, "recall", "позже", -0.2, 3 MINUTES)
	var/datum/market_event/event = SSmarket.schedule_company_event(company, "product_launch", "тест", 0.2, 0)
	TEST_ASSERT(event in SSmarket.scheduled_events, "В очереди")
	SSmarket.run_due_events()
	TEST_ASSERT(!(event in SSmarket.scheduled_events), "Вышло")
	TEST_ASSERT(later in SSmarket.scheduled_events, "Событие с ETA в будущем вышло раньше срока")
	TEST_ASSERT(company.price > price_before, "Цена выросла сразу")
	TEST_ASSERT_EQUAL(jointext(company_events, ","), "VYMD:product_launch", "Сигнал выхода события")

/// Минутный тик подсистемы двигает цены, планирует события компаний с ETA 3-5 минут и выпускает созревшие.
/datum/unit_test/economy_stocks/fire_ticks/Run()
	SSmarket.company_event_chance = 100
	var/datum/stock_company/halted = SSmarket.get_company("AGRO")
	halted.halted_until = world.time + 1 HOURS
	var/list/history_before = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		history_before[ticker] = length(company.history)
	SSmarket.fire()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		if(company == halted)
			TEST_ASSERT_EQUAL(length(company.history), history_before[ticker], "Остановленная компания торгуется")
		else
			TEST_ASSERT_EQUAL(length(company.history), history_before[ticker] + 1, "Тик не записал цену [ticker]")
	TEST_ASSERT_EQUAL(length(SSmarket.scheduled_events), SSmarket.real_company_count() - 1, "По событию на каждую торгуемую компанию, у индекса событий нет")
	for(var/datum/market_event/event as anything in SSmarket.scheduled_events)
		TEST_ASSERT(event.company != halted, "Событие у остановленной компании")
		TEST_ASSERT(event.eta >= world.time + STOCK_EVENT_ETA_MIN && event.eta <= world.time + STOCK_EVENT_ETA_MAX, "ETA вне 3-5 минут")
		TEST_ASSERT(!findtext(event.headline, "%NAME%") && findtext(event.headline, event.company.name), "Заголовок без названия компании: [event.headline]")
		event.eta = world.time
	SSmarket.company_event_chance = 0
	SSmarket.fire()
	TEST_ASSERT_EQUAL(length(SSmarket.scheduled_events), 0, "Созревшие события не вышли")
	TEST_ASSERT_EQUAL(length(company_events), SSmarket.real_company_count() - 1, "Сигналы выхода событий")

/// Событие станции бьёт по привязанной компании, повтор в окне кулдауна не действует, "*" бьёт по всем.
/datum/unit_test/economy_stocks/station_event/Run()
	var/datum/stock_company/nt = SSmarket.get_company("NTRN")
	var/datum/stock_company/nakamura = SSmarket.get_company("NKMR")
	var/nt_before = nt.price
	var/nakamura_before = nakamura.price
	SSmarket.station_event("sm_delam")
	TEST_ASSERT(nt.price < nt_before, "Дестабилизация бьёт по НТ")
	TEST_ASSERT(nakamura.price > nakamura_before, "Дестабилизация поднимает Накамуру")
	var/nt_after = nt.price
	SSmarket.station_event("sm_delam")
	TEST_ASSERT(nt.price == nt_after, "Повтор события станции в окне кулдауна")
	SSmarket.station_event("no_such_event")
	var/list/before = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		before[ticker] = company.price
	SSmarket.station_event("market_crash")
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT(company.price < before[ticker], "Обвал не задел [ticker]")

/// Объявление метеоритной волны поднимает Накамуру, начало той же волны - уже нет; волна без объявления поднимает в start().
/datum/unit_test/economy_stocks/meteors/Run()
	var/datum/stock_company/nakamura = SSmarket.get_company("NKMR")
	var/before = nakamura.price
	var/datum/round_event/meteor_wave/wave = new(FALSE)
	wave.announce(FALSE)
	TEST_ASSERT(nakamura.price > before, "Объявление метеоров не подняло Накамуру")
	var/announced = nakamura.price
	SSmarket.station_event_cooldowns.Cut()
	wave.start()
	wave.kill()
	qdel(wave)
	TEST_ASSERT(nakamura.price == announced, "Начало объявленной волны снова подняло Накамуру")
	SSmarket.station_event_cooldowns.Cut()
	var/datum/round_event/meteor_wave/silent = new(FALSE)
	silent.start()
	silent.kill()
	qdel(silent)
	TEST_ASSERT(nakamura.price > announced, "Волна без объявления не подняла Накамуру")

/// Ложная тревога о метеорах, пыли, эпидемии, радиации и сбое энергосети не двигает акции и не тратит кулдаун события станции.
/datum/unit_test/economy_stocks/false_alarm/Run()
	SSmarket.station_event_cooldowns.Cut()
	var/list/prices = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		prices[ticker] = company.price
	for(var/event_type in list(/datum/round_event/meteor_wave, /datum/round_event/meteor_wave/major_dust, /datum/round_event/meteor_wave/meaty, /datum/round_event/disease_outbreak, /datum/round_event/radiation_storm, /datum/round_event/grid_check))
		var/datum/round_event_control/control
		for(var/datum/round_event_control/candidate in SSdirector.event_controls())
			if(candidate.typepath == event_type)
				control = candidate
				break
		TEST_ASSERT_NOTNULL(control, "Нет события [event_type] у директора")
		var/datum/round_event/falsealarm/alarm = new(FALSE)
		alarm.forced_type = control
		alarm.announce(FALSE)
		alarm.kill()
		qdel(alarm)
		TEST_ASSERT_EQUAL(length(SSmarket.station_event_cooldowns), 0, "Ложная тревога [event_type] заняла кулдаун события станции")
	for(var/ticker in prices)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT(company.price == prices[ticker], "Ложная тревога сдвинула [ticker]")
	var/datum/stock_company/vey_med = SSmarket.get_company("VYMD")
	var/datum/round_event/disease_outbreak/outbreak = new(FALSE)
	outbreak.announce(FALSE)
	outbreak.kill()
	qdel(outbreak)
	TEST_ASSERT(vey_med.price > prices["VYMD"], "Настоящая эпидемия не подняла Вей-Мед")

/// Ложная тревога до выбора профиля директора (лобби, админский запуск) не падает.
/datum/unit_test/economy_stocks/false_alarm_without_profile
	var/datum/director_profile/saved_profile

/datum/unit_test/economy_stocks/false_alarm_without_profile/Destroy()
	SSdirector.profile = saved_profile
	saved_profile = null
	return ..()

/datum/unit_test/economy_stocks/false_alarm_without_profile/Run()
	saved_profile = SSdirector.profile
	SSdirector.profile = null
	var/datum/round_event_control/control
	for(var/datum/round_event_control/candidate in SSdirector.event_controls())
		if(candidate.typepath == /datum/round_event/meteor_wave/major_dust)
			control = candidate
			break
	TEST_ASSERT_NOTNULL(control, "Нет пыли у директора")
	var/datum/round_event/falsealarm/alarm = new(FALSE)
	alarm.forced_type = control
	alarm.announce(FALSE)
	alarm.kill()
	qdel(alarm)
	TEST_ASSERT(islist(gather_false_events()), "Список ложных тревог без профиля директора не собран")

/// Отменённый отсчёт кристалла не двигает акции.
/datum/unit_test/economy_stocks/sm_countdown_cancelled/Run()
	var/turf/open/spot = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(spot, "Есть станционный турф")
	var/obj/machinery/power/supermatter_crystal/shard/unit_test_detonation_probe/crystal = allocate(/obj/machinery/power/supermatter_crystal/shard/unit_test_detonation_probe, spot)
	SSair.stop_processing_machine(crystal)
	SSmarket.station_event_cooldowns.Cut()
	var/datum/stock_company/nt = SSmarket.get_company("NTRN")
	var/before = nt.price
	crystal.damage = crystal.explosion_point
	crystal.countdown()
	crystal.damage = 0
	TEST_ASSERT(wait_for_var(crystal, "final_countdown", FALSE, 5 SECONDS), "Отсчёт не отменился")
	TEST_ASSERT(!crystal.detonated, "Кристалл взорвался")
	TEST_ASSERT(nt.price == before, "Отменённый отсчёт обрушил акции НТ")
	TEST_ASSERT_NULL(SSmarket.station_event_cooldowns["sm_delam"], "Отменённый отсчёт занял кулдаун события станции")

/// Множитель событий без нижнего зажима: после серии падений рост действует ровно на свою долю.
/datum/unit_test/economy_stocks/event_floor/Run()
	var/datum/stock_company/company = SSmarket.get_company("NKMR")
	var/expected = company.price
	for(var/effect in list(-0.9, -0.9, -0.5, 1, 1))
		company.apply_shock(effect)
		expected *= 1 + effect
	TEST_ASSERT(abs(company.price - expected) / expected < 0.0001, "Цена [company.price] вместо [expected]: пол множителя событий съел падение")

/// Начало тревоги "дельта" бьёт по НТ; уровень тревоги возвращается.
/datum/unit_test/economy_stocks/delta/Run()
	var/datum/stock_company/nt = SSmarket.get_company("NTRN")
	var/before = nt.price
	var/saved_level = GLOB.security_level
	SSsecurity_level.delta_process()
	GLOB.security_level = saved_level
	SEND_SIGNAL(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED)
	SSnightshift.check_nightshift()
	TEST_ASSERT(nt.price < before, "Дельта не ударила по НТ")

/// Объявление о вспышке болезни поднимает Вей-Мед.
/datum/unit_test/economy_stocks/disease/Run()
	var/datum/stock_company/vey = SSmarket.get_company("VYMD")
	var/before = vey.price
	var/datum/round_event/disease_outbreak/outbreak = new(FALSE)
	outbreak.announce(FALSE)
	outbreak.kill()
	qdel(outbreak)
	TEST_ASSERT(vey.price > before, "Объявление вспышки не подняло Вей-Мед")

/// Сотня положительных шоков, настоящих и фальшивых, не выводит цену и множитель событий за потолки; фальшивое событие у компании в очереди одно.
/datum/unit_test/economy_stocks/caps/Run()
	SSmarket.company_event_chance = 0
	var/datum/stock_company/company = SSmarket.get_company("NKMR")
	company.volatility = 0
	var/price_cap = company.base_price * STOCK_PRICE_MAX_RATIO
	for(var/i in 1 to 100)
		SSmarket.schedule_company_event(company, "boom", "тест", STOCK_EFFECT_MAX, 0)
		SSmarket.schedule_company_event(company, "press_release", "тест", STOCK_EFFECT_MAX, 0, TRUE)
		SSmarket.station_event_cooldowns.Cut()
		SSmarket.station_event("sector_boom")
		SSmarket.station_event("meteors")
		SSmarket.fire()
		TEST_ASSERT(company.price > 0 && company.price <= price_cap, "Цена вне коридора: [company.price]")
		TEST_ASSERT(company.event_mult <= STOCK_EVENT_MULT_MAX, "Множитель событий выше потолка: [company.event_mult]")
	TEST_ASSERT(company.price > company.base_price * 2, "Шоки не подняли цену: [company.price]")
	TEST_ASSERT_NOTNULL(SSmarket.schedule_company_event(company, "press_release", "тест", 0.1, 3 MINUTES, TRUE), "Первое фальшивое событие")
	TEST_ASSERT_NULL(SSmarket.schedule_company_event(company, "press_release", "тест", 0.1, 3 MINUTES, TRUE), "Второе фальшивое событие у той же компании")
	TEST_ASSERT_NOTNULL(SSmarket.schedule_company_event(company, "boom", "тест", 0.1, 3 MINUTES), "Настоящее событие рядом с фальшивым")

/// Перечитывание конфига не трогает очередь событий и кулдауны событий станции.
/datum/unit_test/economy_stocks/reload_keeps_queue/Run()
	var/datum/stock_company/nt = SSmarket.get_company("NTRN")
	var/datum/market_event/event = SSmarket.schedule_company_event(nt, "scandal", "тест", -0.2, 3 MINUTES)
	SSmarket.station_event("delta_alert")
	var/after = nt.price
	SSmarket.load_settings(SSeconomy.settings.raw?["market"])
	TEST_ASSERT(event in SSmarket.scheduled_events, "Перечитывание сняло событие")
	TEST_ASSERT(event.company == SSmarket.get_company("NTRN"), "Событие ссылается на старую компанию")
	SSmarket.station_event("delta_alert")
	TEST_ASSERT(nt.price == after, "Перечитывание сбросило кулдаун события станции")

/// Продажи партнёру сразу поднимают цену его компании до потолка торговли, и она не сползает обратно сама.
/datum/unit_test/economy_stocks/trade_volume/Run()
	SSmarket.company_event_chance = 0
	var/datum/trade_partner/partner = SSmarket.get_partner("prospectors")
	var/datum/stock_company/company = SSmarket.get_company(partner.company)
	var/datum/stock_company/idle = SSmarket.get_company("EINS")
	company.volatility = 0
	idle.volatility = 0
	var/start_price = company.price
	partner.note_sale(STOCK_TRADE_SCALE * STOCK_TRADE_BOOST_MAX / 2)
	TEST_ASSERT(abs(company.price - start_price * (1 + STOCK_TRADE_BOOST_MAX / 2)) < 0.01, "Продажа не подняла цену сразу: [company.price]")
	partner.note_sale(STOCK_TRADE_SCALE * 10)
	TEST_ASSERT(company.trade_volume >= STOCK_TRADE_SCALE * 10, "Продажа партнёру не учтена в объёме торговли")
	var/boosted = start_price * (1 + STOCK_TRADE_BOOST_MAX)
	TEST_ASSERT(abs(company.price - boosted) < 0.01, "Цена не на потолке торговли: [company.price]")
	for(var/i in 1 to 30)
		SSmarket.fire()
	TEST_ASSERT(abs(company.price - boosted) < 0.01, "Цена после торговли сдвинулась сама: [company.price]")
	TEST_ASSERT(abs(idle.price - idle.base_price) < 0.01, "Компания без торговли сдвинулась: [idle.price]")
	TEST_ASSERT_EQUAL(newest_move(company), "Станция продаёт товары партнёру \"[partner.name]\"", "Причина скачка от продаж в ленте")
	TEST_ASSERT_EQUAL(length(company.moves), 1, "Продажи подряд не слились в одну строку ленты")
	var/datum/trade_partner/grey = SSmarket.get_partner("free_traders")
	var/datum/stock_company/grey_company = SSmarket.get_company(grey.company)
	grey.note_sale(STOCK_TRADE_SCALE * STOCK_TRADE_BOOST_MAX / 2)
	TEST_ASSERT_EQUAL(newest_move(grey_company), "Сделки на сером рынке сектора", "Лента выдала продажи станции контрабандному партнёру")

/datum/unit_test/economy_stocks/proc/newest_move(datum/stock_company/company)
	if(!length(company.moves))
		return null
	var/list/move = company.moves[length(company.moves)]
	return move["text"]

/datum/unit_test/economy_stocks/proc/work_driver_of(datum/stock_company/company)
	for(var/list/driver as anything in company.price_drivers())
		if(findtext(driver["label"], "Работа станции") == 1)
			return driver

/// Работа отдела сразу поднимает цену привязанной компании и пишет причину в ленту, повторы копятся одной строкой; рост упирается в потолок за смену.
/datum/unit_test/economy_stocks/work_moves_price/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/balance_before = medical.account.account_balance
	var/datum/stock_company/vey = SSmarket.get_company("VYMD")
	var/datum/stock_company/idle = SSmarket.get_company("EINS")
	var/list/shares = SSmarket.work_stocks[WORK_MED_REVIVE]
	TEST_ASSERT(islist(shares) && shares["VYMD"] > 0, "Реанимация не привязана к Вей-Мед")
	var/start = vey.price
	var/paid = SSeconomy.record_work(ACCOUNT_MED, WORK_MED_REVIVE, 1)
	TEST_ASSERT(paid > 0, "Реанимация не оплачена")
	var/expected = start * (1 + paid * shares["VYMD"] / STOCK_WORK_CREDITS)
	TEST_ASSERT(abs(vey.price - expected) < 0.01, "Цена после реанимации [vey.price] вместо [expected]")
	TEST_ASSERT(abs(idle.price - idle.base_price) < 0.01, "Работа медиков сдвинула [idle.ticker]: [idle.price]")
	TEST_ASSERT_EQUAL(newest_move(vey), market_work_reason(WORK_MED_REVIVE), "Причина скачка от работы в ленте")
	for(var/i in 1 to 100)
		SSeconomy.record_work(ACCOUNT_MED, WORK_MED_REVIVE, 1)
	econ_test_set_balance(medical.account, balance_before)
	TEST_ASSERT(abs(vey.price - start * (1 + SSmarket.work_stock_cap)) < 0.01, "Цена [vey.price] не упёрлась в потолок работы за смену")
	TEST_ASSERT_EQUAL(length(vey.moves), 1, "Повторы одной работы не слились в одну строку ленты")
	var/list/feed = vey.moves_ui()
	var/list/entry = feed[1]
	TEST_ASSERT(abs(entry["effect"] - SSmarket.work_stock_cap * 100) < 0.11, "Строка ленты [entry["effect"]]% вместо потолка")
	var/report = jointext(econ_market_report(), "\n")
	TEST_ASSERT(findtext(report, "Работа отделов сдвинула акции: ") && findtext(report, "[vey.name] +[round(SSmarket.work_stock_cap * 100, 0.1)]%"), "Итоги смены без сдвига от работы: [report]")
	TEST_ASSERT(!findtext(report, idle.name), "Итоги смены называют компанию без работы")

/// Изъятая контрабанда поднимает Гефест и роняет Киберсан; остановленные торги работа не двигает.
/datum/unit_test/economy_stocks/work_signs/Run()
	var/datum/economy_department/security = SSeconomy.get_department(ACCOUNT_SEC)
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/security_before = security.account.account_balance
	var/cargo_before = cargo.account.account_balance
	var/datum/stock_company/hephaestus = SSmarket.get_company("HEPH")
	var/datum/stock_company/cybersun = SSmarket.get_company("CYBS")
	var/heph_before = hephaestus.price
	var/cybs_before = cybersun.price
	var/paid = SSeconomy.record_work(ACCOUNT_SEC, WORK_SEC_CONTRABAND, 1000)
	var/datum/stock_company/miners = SSmarket.get_company("PRSP")
	miners.halted_until = world.time + 1 HOURS
	var/halted_price = miners.price
	var/mined = SSeconomy.record_work(ACCOUNT_CAR, WORK_MINING_ORE, 1000)
	miners.halted_until = 0
	econ_test_set_balance(security.account, security_before)
	econ_test_set_balance(cargo.account, cargo_before)
	TEST_ASSERT(paid > 0 && mined > 0, "Работа не оплачена: [paid], [mined]")
	TEST_ASSERT(hephaestus.price > heph_before, "Изъятие контрабанды не подняло Гефест")
	TEST_ASSERT(cybersun.price < cybs_before, "Изъятие контрабанды не уронило Киберсан")
	TEST_ASSERT(miners.price == halted_price && !miners.work_boost && !length(miners.moves), "Работа сдвинула остановленные торги [miners.ticker]")

/// Сноски называют работу, которая двигает компанию, с потолком за смену и знаком; новые события станции видны у своих компаний.
/datum/unit_test/economy_stocks/work_drivers/Run()
	var/datum/stock_company/vey = SSmarket.get_company("VYMD")
	var/list/driver = work_driver_of(vey)
	TEST_ASSERT_NOTNULL(driver, "У Вей-Мед нет сноски о работе станции")
	TEST_ASSERT(findtext(driver["label"], market_work_driver_name(WORK_MED_DISCHARGE_LIGHT)) && findtext(driver["label"], market_work_driver_name(WORK_MED_SURGERY)), "Сноска не называет работу: [driver["label"]]")
	TEST_ASSERT_EQUAL(driver["effect"], round(SSmarket.work_stock_cap * 100, 0.1), "Потолок роста от работы")
	TEST_ASSERT(driver["upto"], "Сдвиг от работы - потолок, а не скачок")
	var/list/shares = SSmarket.work_stocks[WORK_MED_REVIVE]
	var/rate = SSmarket.signed_percent(round(shares["VYMD"] * 100 * STOCK_WORK_NOTE_CREDITS / STOCK_WORK_CREDITS, 0.01))
	TEST_ASSERT(findtext(driver["note"], "[rate]") && findtext(driver["note"], "[STOCK_WORK_NOTE_CREDITS] кр."), "Сноска без шага: [driver["note"]]")
	var/list/cybersun = work_driver_of(SSmarket.get_company("CYBS"))
	TEST_ASSERT_EQUAL(cybersun["effect"], -round(SSmarket.work_stock_cap * 100, 0.1), "Изъятие контрабанды роняет Киберсан")
	TEST_ASSERT_NULL(work_driver_of(SSmarket.get_company(STOCK_INDEX_TICKER)), "У индекса сноска о работе")
	var/datum/stock_company/nakamura = SSmarket.get_company("NKMR")
	var/list/labels = list()
	for(var/list/each as anything in nakamura.price_drivers())
		labels[each["label"]] = each["effect"]
	TEST_ASSERT_EQUAL(labels[GLOB.market_station_event_names["power_failure"]], -10, "Сбой энергосети в сносках Накамуры")
	TEST_ASSERT_EQUAL(labels[GLOB.market_station_event_names["gravity_lost"]], -10, "Отказ гравитации в сносках Накамуры")

/// Заметный сдвиг от работы станции выходит срочной новостью рынка, повтор до кулдауна - нет.
/datum/unit_test/economy_stocks/work_news/Run()
	var/datum/economy_department/security = SSeconomy.get_department(ACCOUNT_SEC)
	var/balance_before = security.account.account_balance
	var/datum/stock_company/hephaestus = SSmarket.get_company("HEPH")
	var/list/shares = SSmarket.work_stocks[WORK_SEC_CONTRABAND]
	var/units = STOCK_WORK_NEWS_STEP * 0.6 * STOCK_WORK_CREDITS / shares["HEPH"] / SSeconomy.settings.work_prices[WORK_SEC_CONTRABAND]
	SSeconomy.record_work(ACCOUNT_SEC, WORK_SEC_CONTRABAND, units)
	var/list/news_small = news_about(hephaestus)
	SSeconomy.record_work(ACCOUNT_SEC, WORK_SEC_CONTRABAND, units)
	var/list/news_step = news_about(hephaestus)
	for(var/i in 1 to 3)
		SSeconomy.record_work(ACCOUNT_SEC, WORK_SEC_CONTRABAND, units)
	econ_test_set_balance(security.account, balance_before)
	TEST_ASSERT_EQUAL(length(news_small), 0, "Новость о сдвиге меньше шага")
	TEST_ASSERT_EQUAL(length(news_step), 1, "Нет новости о заметном сдвиге от работы")
	TEST_ASSERT(findtext(news_step[1], hephaestus.name) && findtext(news_step[1], market_work_reason(WORK_SEC_CONTRABAND)), "Новость без компании или причины: [news_step[1]]")
	TEST_ASSERT_EQUAL(length(news_about(hephaestus)), 1, "Вторая новость о работе раньше кулдауна")

/datum/unit_test/economy_stocks/work_news/proc/news_about(datum/stock_company/company)
	. = list()
	for(var/line in SSmarket.pending_news)
		if(findtext(line, "([company.ticker])"))
			. += line

/// Сдвиг от работы отделов в следующую смену не переходит: состояние сектора хранит цену без него.
/datum/unit_test/economy_stocks/work_not_persisted/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/balance_before = medical.account.account_balance
	var/datum/stock_company/vey = SSmarket.get_company("VYMD")
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_REVIVE, 1)
	econ_test_set_balance(medical.account, balance_before)
	TEST_ASSERT(vey.price > vey.base_price, "Работа не подняла цену")
	var/list/state = SSmarket.serialize_state()
	var/list/saved_companies = state["companies"]
	var/list/saved = saved_companies["VYMD"]
	TEST_ASSERT(abs(saved["price_ratio"] - 1) < 0.0001, "Сдвиг от работы ушёл в следующую смену: [saved["price_ratio"]]")

/// Сбой энергосети, отказ гравитации, радиационный шторм и красный код двигают привязанные акции и пишут причину в ленту.
/datum/unit_test/economy_stocks/station_troubles/Run()
	var/datum/stock_company/nakamura = SSmarket.get_company("NKMR")
	var/datum/stock_company/nt = SSmarket.get_company("NTRN")
	var/datum/stock_company/agro = SSmarket.get_company("AGRO")
	var/datum/stock_company/hephaestus = SSmarket.get_company("HEPH")
	var/before = nakamura.price
	var/datum/round_event/grid_check/outage = new(FALSE)
	var/list/saved_apcs = GLOB.apcs_list
	GLOB.apcs_list = list()
	outage.start()
	GLOB.apcs_list = saved_apcs
	outage.kill()
	qdel(outage)
	TEST_ASSERT(nakamura.price < before, "Сбой энергосети не уронил Накамуру")
	TEST_ASSERT_EQUAL(newest_move(nakamura), GLOB.market_station_event_names["power_failure"], "Причина в ленте Накамуры")

	var/obj/machinery/gravity_generator/main/generator
	for(var/obj/machinery/gravity_generator/main/candidate as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/gravity_generator/main))
		if(is_station_level(candidate.z))
			generator = candidate
			break
	TEST_ASSERT_NOTNULL(generator, "На станции нет генератора гравитации")
	var/was_on = generator.on
	if(!was_on)
		generator.set_state(TRUE)
	before = nakamura.price
	generator.set_state(FALSE)
	var/after_gravity = nakamura.price
	generator.set_state(TRUE)
	if(!was_on)
		generator.set_state(FALSE)
	TEST_ASSERT(after_gravity < before, "Отказ гравитации не уронил Накамуру")
	TEST_ASSERT(nakamura.price == after_gravity, "Возврат гравитации сдвинул Накамуру")

	before = agro.price
	var/datum/round_event/radiation_storm/storm = new(FALSE)
	storm.announce(FALSE)
	storm.kill()
	qdel(storm)
	TEST_ASSERT(agro.price < before, "Радиационный шторм не уронил Аграрный союз")

	var/saved_level = GLOB.security_level
	if(saved_level >= SEC_LEVEL_RED)
		SSsecurity_level.set_level(SEC_LEVEL_GREEN, bypass_keycard_lock = TRUE)
	before = nt.price
	var/heph_before = hephaestus.price
	SSsecurity_level.set_level(SEC_LEVEL_RED, bypass_keycard_lock = TRUE)
	SSsecurity_level.set_level(saved_level, bypass_keycard_lock = TRUE)
	TEST_ASSERT(nt.price < before, "Красный код не уронил НТ")
	TEST_ASSERT(hephaestus.price > heph_before, "Красный код не поднял Гефест")
	TEST_ASSERT_EQUAL(newest_move(nt), GLOB.market_station_event_names["red_alert"], "Причина в ленте НТ")

/// Лента причин: новость компании и событие станции пишутся с процентом и временем, новые сверху, не больше STOCK_MOVES_MAX; окно получает ленту и потолок работы.
/datum/unit_test/economy_stocks/moves_feed/Run()
	SSmarket.company_event_chance = 0
	var/datum/stock_company/nt = SSmarket.get_company("NTRN")
	SSmarket.schedule_company_event(nt, "product_launch", "Тестовая новость НТ", 0.2, 0)
	SSmarket.run_due_events()
	var/list/feed = nt.moves_ui()
	var/list/top = length(feed) ? feed[1] : list()
	TEST_ASSERT_EQUAL(top["text"], "Тестовая новость НТ", "Новость компании не в ленте")
	TEST_ASSERT(abs(top["effect"] - 20) < 0.11, "Сдвиг новости в ленте: [top["effect"]]")
	TEST_ASSERT(istext(top["time"]) && length(top["time"]), "Нет времени скачка")
	SSmarket.station_event("sm_delam")
	feed = nt.moves_ui()
	top = feed[1]
	TEST_ASSERT_EQUAL(top["text"], GLOB.market_station_event_names["sm_delam"], "Новое событие не сверху")
	TEST_ASSERT(abs(top["effect"] + 25) < 0.11, "Сдвиг события в ленте: [top["effect"]]")
	for(var/key in list("delta_alert", "power_failure", "gravity_lost", "red_alert"))
		SSmarket.station_event(key)
	feed = nt.moves_ui()
	TEST_ASSERT_EQUAL(length(feed), STOCK_MOVES_MAX, "Лента не ограничена")
	var/list/oldest = feed[length(feed)]
	TEST_ASSERT_EQUAL(oldest["text"], GLOB.market_station_event_names["sm_delam"], "Старая строка не вытеснена")
	var/datum/stock_company/solar = SSmarket.get_company("SOLX")
	TEST_ASSERT(!length(solar.moves), "События без SOLX попали в его ленту")
	var/datum/computer_file/program/stock_exchange/program = new
	var/list/static_data = program.stocks_static_data()
	qdel(program)
	var/list/moves = static_data["moves"]
	TEST_ASSERT_EQUAL(length(moves["NTRN"]), STOCK_MOVES_MAX, "Окно не получило ленту НТ")
	TEST_ASSERT_EQUAL(static_data["work_cap"], round(SSmarket.work_stock_cap * 100, 0.1), "Потолок работы в окне")

/// Проваленный по сроку спецзаказ роняет акции компании партнёра.
/datum/unit_test/economy_stocks/offer_fail/Run()
	SSmarket.company_event_chance = 0
	var/datum/trade_partner/partner = SSmarket.get_partner("vey_med")
	var/datum/stock_company/company = SSmarket.get_company(partner.company)
	var/datum/market_offer/offer = new(partner.id, /obj/item/stack/sheet/bone, "тест", 5, 2, 20)
	partner.offers += offer
	TEST_ASSERT(offer.accept(), "Спецзаказ не взят")
	offer.deadline = world.time - 1
	var/event_mult_before = company.event_mult
	SSmarket.expire_offers()
	TEST_ASSERT(QDELETED(offer), "Спецзаказ не провалился")
	TEST_ASSERT(company.event_mult < event_mult_before, "Провал спецзаказа не ударил по акциям [company.ticker]")
	TEST_ASSERT_EQUAL(newest_move(company), "Станция сорвала спецзаказ партнёра \"[partner.name]\"", "Причина скачка от провала в ленте")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "оценка акций [company.ticker] -[MARKET_OFFER_FAIL_STOCK_SHOCK * 100]%"), "Сообщение ЦК не говорит об акциях: [SSshuttle.centcom_message]")

/// Компании и события из economy.json совпадают со встроенными; битые записи пишут ошибки и оставляют встроенное; перечитывание сохраняет цены.
/datum/unit_test/economy_stocks/config/Run()
	var/list/errors = SSmarket.load_settings(SSeconomy.settings.raw?["market"])
	TEST_ASSERT(!length(errors), "economy.json market: [jointext(errors, "; ")]")
	var/list/configured = snapshot()
	SSmarket.load_settings(list())
	var/list/builtin = snapshot()
	TEST_ASSERT_EQUAL(length(builtin), length(configured), "Число параметров")
	for(var/key in configured)
		TEST_ASSERT_EQUAL(builtin[key], configured[key], "Встроенное [key] расходится с economy.json")
	var/datum/stock_company/nt = SSmarket.get_company("NTRN")
	var/default_base = nt.base_price
	nt.price = 12.5
	var/default_events = length(SSmarket.company_event_templates)
	TEST_ASSERT_EQUAL(nt.partner_id, "nt_logistics", "Партнёр компании берётся из market.partners")
	var/datum/stock_company/independent = SSmarket.get_company("EINS")
	TEST_ASSERT_NULL(independent.partner_id, "У компании без партнёра нет партнёра")
	var/list/market_section = SSeconomy.settings.raw["market"]
	var/list/bad_partners = market_section["partners"]
	bad_partners = bad_partners.Copy()
	var/list/prospectors_entry = bad_partners["prospectors"]
	prospectors_entry = prospectors_entry.Copy()
	prospectors_entry["company"] = "ZZZZ"
	bad_partners["prospectors"] = prospectors_entry
	var/list/bad = list(
		"company_event_chance" = 500,
		"commodities" = market_section["commodities"],
		"partners" = bad_partners,
		"companies" = list(
			"NTRN" = list("price" = -5),
			"PRSP" = "плохо",
			"ACME" = list("name" = "Акме"),
			"VYMD" = list("partner" = "nobody"),
			"NKMR" = list("volatility" = 5),
		),
		"company_events" = list(
			list("key" = "boom", "headline" = "%NAME% растёт", "effect" = 0.1),
			list("key" = "bad", "headline" = "%NAME% падает", "effect" = 7),
		),
		"station_events" = list(
			"sm_delam" = list("NOPE" = -0.1),
			"meteors" = "плохо",
			"alien_invasion" = list("NTRN" = -0.1),
		),
		"work_stock_cap" = 5,
		"work_stocks" = list(
			"no_such_work" = list("VYMD" = 0.1),
			"med_revive" = list("ZZZZ" = 0.1),
			"srv_dish" = "плохо",
			"mining_ore" = list("PRSP" = 7),
			"sci_node" = list(STOCK_INDEX_TICKER = 0.1),
		),
	)
	errors = SSmarket.load_settings(bad)
	TEST_ASSERT_EQUAL(length(errors), 17, "Ошибки: шанс, цена, не объект, неизвестная компания, ключ partner, волатильность, компания партнёра, эффект события, тикер, не объект, неизвестное событие, потолок работы, вид работы, тикер работы, не объект, доля, индекс ([jointext(errors, "; ")])")
	TEST_ASSERT_EQUAL(SSmarket.work_stock_cap, initial(SSmarket.work_stock_cap), "Потолок работы выше допустимого принят")
	var/list/revive = SSmarket.work_stocks[WORK_MED_REVIVE]
	TEST_ASSERT(islist(revive) && revive["VYMD"] > 0 && !("ZZZZ" in revive), "Битая привязка работы затёрла встроенную")
	TEST_ASSERT(!("no_such_work" in SSmarket.work_stocks), "Неизвестный вид работы принят")
	var/datum/stock_company/prospectors_company = SSmarket.get_company("PRSP")
	TEST_ASSERT_NULL(prospectors_company.partner_id, "Компания осталась за партнёром, который на неё не ссылается")
	TEST_ASSERT_EQUAL(SSmarket.company_event_chance, initial(SSmarket.company_event_chance), "Шанс выше 100 принят")
	TEST_ASSERT_EQUAL(SSmarket.real_company_count(), 10, "Неизвестная компания добавлена")
	TEST_ASSERT(SSmarket.get_company("NTRN") == nt, "Перечитывание заменило компанию")
	TEST_ASSERT_EQUAL(nt.base_price, default_base, "Отрицательная цена принята")
	TEST_ASSERT(abs(nt.price - 12.5) < 0.01, "Перечитывание сбросило цену")
	TEST_ASSERT_EQUAL(length(SSmarket.company_event_templates), default_events, "Битый список событий компаний принят частично")
	var/list/delam = SSmarket.station_events["sm_delam"]
	TEST_ASSERT(islist(delam) && ("NTRN" in delam), "Битое событие станции затёрло встроенное")
	TEST_ASSERT(!("alien_invasion" in SSmarket.station_events), "Неизвестное событие станции принято")
	errors = SSmarket.load_settings("мусор")
	TEST_ASSERT_EQUAL(length(errors), 1, "Секция не объект - одна ошибка ([jointext(errors, "; ")])")
	TEST_ASSERT_EQUAL(SSmarket.real_company_count(), 10, "Встроенные компании при битой секции")
	TEST_ASSERT(SSmarket.get_company(STOCK_INDEX_TICKER), "Индекс пропал при битой секции")

/datum/unit_test/economy_stocks/config/proc/snapshot()
	. = list("chance" = "[SSmarket.company_event_chance]")
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		.[ticker] = "[company.name]|[company.base_price]|[company.volatility]|[company.partner_id]"
	var/index = 0
	for(var/list/template as anything in SSmarket.company_event_templates)
		index++
		.["event[index]"] = "[template["key"]]|[template["headline"]]|[template["effect"]]"
	for(var/key in SSmarket.station_events)
		var/list/effects = SSmarket.station_events[key]
		var/list/texts = list()
		for(var/ticker in effects)
			texts += "[ticker]=[effects[ticker]]"
		.["station_[key]"] = jointext(texts, ",")
	.["work_cap"] = "[SSmarket.work_stock_cap]"
	for(var/work_type in SSmarket.work_stocks)
		var/list/shares = SSmarket.work_stocks[work_type]
		var/list/texts = list()
		for(var/ticker in shares)
			texts += "[ticker]=[shares[ticker]]"
		.["work_[work_type]"] = jointext(texts, ",")

/// Вторая ссылка партнёра на занятую компанию и неизвестный тикер - ошибки конфига; компания остаётся за первым партнёром, битые ссылки сбрасываются.
/datum/unit_test/economy_stocks/partner_links/Run()
	var/list/market_section = json_decode(json_encode(SSeconomy.settings.raw["market"]))
	var/list/partner_entries = market_section["partners"]
	var/list/agrarian_entry = partner_entries["agrarian"]
	agrarian_entry["company"] = "PRSP"
	var/list/free_traders_entry = partner_entries["free_traders"]
	free_traders_entry["company"] = "ZZZZ"
	var/list/errors = SSmarket.load_settings(market_section)
	TEST_ASSERT_EQUAL(length(errors), 2, "Ошибки: занятая компания, неизвестный тикер ([jointext(errors, "; ")])")
	var/datum/stock_company/prospectors_company = SSmarket.get_company("PRSP")
	TEST_ASSERT_EQUAL(prospectors_company.partner_id, "prospectors", "Компанию перехватил второй партнёр")
	var/datum/trade_partner/agrarian = SSmarket.get_partner("agrarian")
	TEST_ASSERT_NULL(agrarian.company, "Второй партнёр сохранил занятую компанию")
	var/datum/stock_company/agro = SSmarket.get_company("AGRO")
	TEST_ASSERT_NULL(agro.partner_id, "Компания без ссылки осталась за партнёром")
	var/datum/trade_partner/free_traders = SSmarket.get_partner("free_traders")
	TEST_ASSERT_NULL(free_traders.company, "Партнёр сохранил неизвестный тикер")

/// Продажа шаттлом партнёру поднимает объём торговли его компании, закупка пака у партнёра - нет.
/datum/unit_test/economy_partners/stock_trade_volume/Run()
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/datum/stock_company/prospectors_company = SSmarket.get_company(prospectors.company)
	var/turf/open/floor = shuttle_floor()
	TEST_ASSERT_NOTNULL(floor, "Есть пол шаттла снабжения")
	var/obj/structure/closet/crate/shipment = allocate(/obj/structure/closet/crate, floor)
	new /obj/item/stack/sheet/metal/fifty(shipment)
	SSshuttle.supply.sell()
	TEST_ASSERT(prospectors_company.trade_volume > 0, "Продажа шаттлом не учтена в объёме торговли [prospectors_company.ticker]")
	var/datum/trade_partner/vey = SSmarket.get_partner("vey_med")
	var/datum/stock_company/vey_company = SSmarket.get_company(vey.company)
	var/datum/supply_pack/pack = crate_pack_of(vey)
	TEST_ASSERT_NOTNULL(pack, "Вей-Мед продаёт пак в ящике")
	econ_test_set_balance(cargo, vey.pack_price(pack) * 10)
	var/list/crates_before = shuttle_crates()
	var/datum/supply_order/order = new(pack, "Тест", "Тест", null, "Тест")
	SSshuttle.shoppinglist += order
	SSshuttle.supply.buy()
	SSshuttle.orderhistory -= order
	qdel(order)
	for(var/obj/structure/closet/crate/crate as anything in shuttle_crates() - crates_before)
		allocated += crate.GetAllContents()
	var/bought = FALSE
	for(var/list/trade as anything in trade_signals)
		if(trade[1] == vey && !trade[3])
			bought = TRUE
	TEST_ASSERT(bought, "Пак не куплен у Вей-Мед")
	TEST_ASSERT_EQUAL(vey_company.trade_volume, 0, "Закупка пака подняла объём торговли [vey_company.ticker]")
