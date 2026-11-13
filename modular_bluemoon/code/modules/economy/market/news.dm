/// Новости рынка о событиях станции, у которых нет своего объявления.
GLOBAL_LIST_INIT(market_station_event_news, list(
	"market_crash" = "Обвал на рынке сектора: акции всех компаний резко падают.",
	"sector_boom" = "Бум в секторе: акции всех компаний растут.",
))

/datum/controller/subsystem/market
	var/news_published = 0
	/// Памятка по экономике выходит в канал один раз за раунд
	var/guide_published = FALSE
	/// Раз во сколько минут выходит сводка сектора
	var/digest_minutes = 15
	/// Между любыми двумя статьями канала проходит не меньше стольких минут
	var/news_flash_minutes = 7
	var/next_digest = 0
	var/last_news = 0
	/// Лидеры биржи, остановленные торги и спецзаказы прошлой сводки: без перемен пустая сводка не выходит
	var/last_digest_key
	var/list/pending_news = list()
	/// id товаров, ставших горячими после последнего выпуска
	var/list/pending_hot = list()

/datum/controller/subsystem/market/proc/setup_news()
	news_channel()
	if(!guide_published)
		guide_published = TRUE
		GLOB.news_network.SubmitArticle(econ_guide_summary_text(), MARKET_NEWS_AUTHOR, MARKET_NEWS_CHANNEL)
	RegisterSignal(src, COMSIG_MARKET_HOT, PROC_REF(on_hot), override = TRUE)
	RegisterSignal(src, COMSIG_MARKET_PARTNER_UNLOCKED, PROC_REF(on_partner_unlocked), override = TRUE)
	RegisterSignal(src, COMSIG_MARKET_COMPANY_EVENT, PROC_REF(on_company_event), override = TRUE)

/// Закрытый канал "Сводка сектора", создаётся при первом обращении.
/datum/controller/subsystem/market/proc/news_channel()
	for(var/datum/news/feed_channel/channel as anything in GLOB.news_network.network_channels)
		if(channel.channel_name == MARKET_NEWS_CHANNEL)
			return channel
	GLOB.news_network.CreateFeedChannel(MARKET_NEWS_CHANNEL, MARKET_NEWS_AUTHOR, TRUE)
	return GLOB.news_network.network_channels[length(GLOB.news_network.network_channels)]

/// Статья в канал сразу, мимо очереди срочных новостей.
/datum/controller/subsystem/market/proc/publish(text)
	var/datum/news/feed_channel/channel = news_channel()
	GLOB.news_network.SubmitArticle(text, MARKET_NEWS_AUTHOR, MARKET_NEWS_CHANNEL)
	news_published++
	last_news = world.time
	if(length(channel.messages) > MARKET_NEWS_KEEP)
		channel.messages.Cut(1, length(channel.messages) - MARKET_NEWS_KEEP + 1)

/datum/controller/subsystem/market/proc/post_news(text)
	pending_news += text
	if(length(pending_news) > MARKET_NEWS_PENDING_MAX)
		pending_news.Cut(1, length(pending_news) - MARKET_NEWS_PENDING_MAX + 1)

/datum/controller/subsystem/market/proc/on_hot(datum/source, datum/commodity/commodity)
	SIGNAL_HANDLER
	pending_hot |= commodity.id

/datum/controller/subsystem/market/proc/on_partner_unlocked(datum/source, datum/trade_partner/partner)
	SIGNAL_HANDLER
	if(partner.contraband)
		return
	post_news("[partner.name] открывает торговлю со станцией. [partner.desc]")

/datum/controller/subsystem/market/proc/on_company_event(datum/source, datum/market_event/event)
	SIGNAL_HANDLER
	var/datum/stock_company/company = event.company
	post_news("[company.ticker]: [html_encode(event.headline)]. Котировка после события - [round(company.price, 0.01)] кр.")

/// Срочная новость, когда сдвиг от работы станции ушёл от прошлой новости на STOCK_WORK_NEWS_STEP; по компании не чаще STOCK_WORK_NEWS_COOLDOWN.
/datum/controller/subsystem/market/proc/note_work_news(datum/stock_company/company, work_type)
	if(abs(company.work_boost - company.work_news_boost) < STOCK_WORK_NEWS_STEP || world.time < company.work_news_ready_at)
		return
	company.work_news_boost = company.work_boost
	company.work_news_ready_at = world.time + STOCK_WORK_NEWS_COOLDOWN
	var/capped = abs(company.work_boost) >= work_stock_cap
	log_econ("Работа станции сдвинула [company.ticker] на [round(company.work_boost * 100, 0.1)]% за смену, последняя - [work_type]")
	post_news("[company.name] ([company.ticker]) [signed_percent(round(company.work_boost * 100, 0.1))] за смену от работы станции: [market_work_reason(work_type)].[capped ? " Дальше работа станции цену в эту смену не двигает." : ""]")

/datum/controller/subsystem/market/proc/hot_entry(datum/commodity/commodity)
	return "[commodity.name] ×[round(commodity.hot_mult, 0.1)]"

/// Накопленные срочные новости; товары, остывшие до выпуска, не попадают.
/datum/controller/subsystem/market/proc/take_pending_news()
	. = pending_news
	pending_news = list()
	var/list/hot = list()
	for(var/id in pending_hot)
		var/datum/commodity/commodity = commodities[id]
		if(commodity?.hot_mult > 1)
			hot += hot_entry(commodity)
	pending_hot = list()
	if(length(hot))
		. += "Партнёры платят больше обычного за горячие товары: [jointext(hot, ", ")]."

/// Минутный выпуск: сводка по расписанию, между сводками - накопленные срочные новости; статьи не чаще раза в news_flash_minutes.
/datum/controller/subsystem/market/proc/news_tick()
	if(!next_digest)
		next_digest = world.time + digest_minutes MINUTES
	if(last_news && world.time < last_news + news_flash_minutes MINUTES)
		return
	if(world.time >= next_digest)
		next_digest = world.time + digest_minutes MINUTES
		pending_hot = list()
		var/list/recent = take_pending_news()
		var/list/state = digest_state()
		var/key = digest_key(state)
		if(!length(recent) && !length(state["hot"]) && key == last_digest_key)
			return
		last_digest_key = key
		publish(build_digest(recent, state))
		return
	if(!length(pending_news) && !length(pending_hot))
		return
	var/list/lines = take_pending_news()
	if(length(lines))
		publish(jointext(lines, "<br>"))

/datum/controller/subsystem/market/proc/signed_percent(value)
	return "[value > 0 ? "+" : ""][value]%"

/// Горячие товары, лидеры роста и падения, остановленные торги и невзятые спецзаказы для сводки.
/datum/controller/subsystem/market/proc/digest_state()
	var/list/hot = list()
	for(var/id in commodities)
		var/datum/commodity/commodity = commodities[id]
		if(commodity.hot_mult > 1)
			hot += hot_entry(commodity)
	var/datum/stock_company/best
	var/datum/stock_company/worst
	var/list/halted = list()
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		if(company.is_halted())
			halted += ticker
			continue
		var/change = company.change_percent()
		if(change > 0 && (!best || change > best.change_percent()))
			best = company
		if(change < 0 && (!worst || change < worst.change_percent()))
			worst = company
	var/list/offers = list()
	for(var/datum/market_offer/offer as anything in all_offers())
		var/datum/trade_partner/partner = offer.get_partner()
		if(offer.accepted || !offer.open() || partner.contraband)
			continue
		offers += "[partner.name] - [offer.wanted_name], [offer.quantity] шт."
	return list("hot" = hot, "best" = best, "worst" = worst, "halted" = halted, "offers" = offers)

/datum/controller/subsystem/market/proc/digest_key(list/state)
	var/datum/stock_company/best = state["best"]
	var/datum/stock_company/worst = state["worst"]
	return "[best?.ticker]|[worst?.ticker]|[jointext(state["halted"], ",")]|[jointext(state["offers"], ";")]"

/// Текст сводки: горячие товары, лидеры биржи, невзятые спецзаказы, индекс цен и накопленные новости.
/datum/controller/subsystem/market/proc/build_digest(list/recent, list/state)
	if(!state)
		state = digest_state()
	var/list/lines = list("<b>[MARKET_NEWS_CHANNEL]</b>")
	var/list/hot = state["hot"]
	lines += length(hot) ? "Горячие товары, партнёры платят за них больше обычного: [jointext(hot, ", ")]." : "Горячих товаров сейчас нет."
	var/datum/stock_company/best = state["best"]
	var/datum/stock_company/worst = state["worst"]
	if(best)
		lines += "Лидер роста на бирже - [best.ticker] ([best.name]) [signed_percent(best.change_percent())]."
	if(worst)
		lines += "Лидер падения на бирже - [worst.ticker] ([worst.name]) [signed_percent(worst.change_percent())]."
	var/list/halted = state["halted"]
	if(length(halted))
		lines += "Торги остановлены: [jointext(halted, ", ")]."
	var/list/offers = state["offers"]
	if(length(offers))
		lines += "Спецзаказы партнёров ждут снабжение: [jointext(offers, "; ")]."
	lines += "Индекс цен сектора: ×[round(SSeconomy.price_index(), 0.01)]."
	if(length(recent))
		lines += "<br>С прошлого выпуска:"
		lines += recent
	return jointext(lines, "<br>")
