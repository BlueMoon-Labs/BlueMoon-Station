/// Восемь компаний из конфига, цены положительные, у каждого партнёра с компанией она есть на бирже.
/datum/unit_test/economy_stocks_loaded/Run()
	TEST_ASSERT_EQUAL(length(SSmarket.companies), 8, "Восемь компаний")
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT_EQUAL(company.ticker, ticker, "Тикер компании")
		TEST_ASSERT(company.price > 0, "[ticker] цена")
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
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
	TEST_ASSERT_EQUAL(length(SSmarket.scheduled_events), length(SSmarket.companies) - 1, "По событию на каждую торгуемую компанию")
	for(var/datum/market_event/event as anything in SSmarket.scheduled_events)
		TEST_ASSERT(event.company != halted, "Событие у остановленной компании")
		TEST_ASSERT(event.eta >= world.time + STOCK_EVENT_ETA_MIN && event.eta <= world.time + STOCK_EVENT_ETA_MAX, "ETA вне 3-5 минут")
		TEST_ASSERT(!findtext(event.headline, "%NAME%") && findtext(event.headline, event.company.name), "Заголовок без названия компании: [event.headline]")
		event.eta = world.time
	SSmarket.company_event_chance = 0
	SSmarket.fire()
	TEST_ASSERT_EQUAL(length(SSmarket.scheduled_events), 0, "Созревшие события не вышли")
	TEST_ASSERT_EQUAL(length(company_events), length(SSmarket.companies) - 1, "Сигналы выхода событий")

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

/// Ложная тревога о метеорах, пыли и эпидемии не двигает акции и не тратит кулдаун события станции.
/datum/unit_test/economy_stocks/false_alarm/Run()
	SSmarket.station_event_cooldowns.Cut()
	var/list/prices = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		prices[ticker] = company.price
	for(var/event_type in list(/datum/round_event/meteor_wave, /datum/round_event/meteor_wave/major_dust, /datum/round_event/meteor_wave/meaty, /datum/round_event/disease_outbreak))
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

/// Начало тревоги «дельта» бьёт по НТ; уровень тревоги возвращается.
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

/// Проваленный по сроку спецзаказ роняет акции компании партнёра.
/datum/unit_test/economy_stocks/offer_fail/Run()
	SSmarket.company_event_chance = 0
	var/datum/trade_partner/partner = SSmarket.get_partner("vey_med")
	var/datum/stock_company/company = SSmarket.get_company(partner.company)
	var/datum/market_offer/offer = new(partner.id, /obj/item/stack/sheet/bone, "тест", 5, 2, 20)
	partner.offers += offer
	offer.accepted = TRUE
	offer.deadline = world.time - 1
	var/event_mult_before = company.event_mult
	SSmarket.expire_offers()
	TEST_ASSERT(QDELETED(offer), "Спецзаказ не провалился")
	TEST_ASSERT(company.event_mult < event_mult_before, "Провал спецзаказа не ударил по акциям [company.ticker]")
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
	)
	errors = SSmarket.load_settings(bad)
	TEST_ASSERT_EQUAL(length(errors), 11, "Ошибки: шанс, цена, не объект, неизвестная компания, ключ partner, волатильность, компания партнёра, эффект события, тикер, не объект, неизвестное событие ([jointext(errors, "; ")])")
	var/datum/stock_company/prospectors_company = SSmarket.get_company("PRSP")
	TEST_ASSERT_NULL(prospectors_company.partner_id, "Компания осталась за партнёром, который на неё не ссылается")
	TEST_ASSERT_EQUAL(SSmarket.company_event_chance, initial(SSmarket.company_event_chance), "Шанс выше 100 принят")
	TEST_ASSERT_EQUAL(length(SSmarket.companies), 8, "Неизвестная компания добавлена")
	TEST_ASSERT(SSmarket.get_company("NTRN") == nt, "Перечитывание заменило компанию")
	TEST_ASSERT_EQUAL(nt.base_price, default_base, "Отрицательная цена принята")
	TEST_ASSERT(abs(nt.price - 12.5) < 0.01, "Перечитывание сбросило цену")
	TEST_ASSERT_EQUAL(length(SSmarket.company_event_templates), default_events, "Битый список событий компаний принят частично")
	var/list/delam = SSmarket.station_events["sm_delam"]
	TEST_ASSERT(islist(delam) && ("NTRN" in delam), "Битое событие станции затёрло встроенное")
	TEST_ASSERT(!("alien_invasion" in SSmarket.station_events), "Неизвестное событие станции принято")
	errors = SSmarket.load_settings("мусор")
	TEST_ASSERT_EQUAL(length(errors), 1, "Секция не объект - одна ошибка ([jointext(errors, "; ")])")
	TEST_ASSERT_EQUAL(length(SSmarket.companies), 8, "Встроенные компании при битой секции")

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
