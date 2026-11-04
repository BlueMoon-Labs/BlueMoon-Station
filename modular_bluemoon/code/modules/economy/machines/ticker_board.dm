#define TICKER_BOARD_LINES 2
/// С этой цены дробная часть не влезает в строку табло
#define TICKER_BOARD_WHOLE_PRICE 1000

/obj/structure/sign/ticker_board
	name = "stock ticker board"
	desc = "Табло котировок биржи сектора: цены обновляются раз в минуту с тихим щелчком, компании идут по кругу. Рамка мигает жёлтым, если торги по компании на табло остановлены, и вспыхивает на новостях компаний и на событиях станции, двигающих акции. При остановке торгов и обвале рынка табло бьёт тревогу, при возобновлении торгов и буме в секторе звонит."
	icon = 'icons/obj/economy/ticker_board.dmi'
	icon_state = "board"
	buildable_sign = FALSE
	maptext_x = 7
	maptext_y = 8
	maptext_width = 52
	maptext_height = 21
	/// С какой компании начнётся следующая страница
	var/offset = 0
	COOLDOWN_DECLARE(alarm_cooldown)

/obj/structure/sign/ticker_board/Initialize(mapload)
	. = ..()
	RegisterSignal(SSmarket, COMSIG_MARKET_STOCKS_TICKED, PROC_REF(update_ticker))
	RegisterSignal(SSmarket, COMSIG_MARKET_COMPANY_EVENT, PROC_REF(on_company_event))
	RegisterSignal(SSmarket, COMSIG_MARKET_STATION_EVENT, PROC_REF(on_station_event))
	update_ticker()

/obj/structure/sign/ticker_board/Destroy()
	UnregisterSignal(SSmarket, list(COMSIG_MARKET_STOCKS_TICKED, COMSIG_MARKET_COMPANY_EVENT, COMSIG_MARKET_STATION_EVENT))
	return ..()

/obj/structure/sign/ticker_board/proc/on_company_event(datum/source, datum/market_event/event)
	SIGNAL_HANDLER
	board_flash("board_event")

/obj/structure/sign/ticker_board/proc/on_station_event(datum/source, key)
	SIGNAL_HANDLER
	switch(key)
		if("market_crash")
			market_alarm(MARKET_SOUND_CRASH)
			return
		if("sector_boom")
			market_alarm(MARKET_SOUND_BELL)
	board_flash("board_event")

/obj/structure/sign/ticker_board/proc/board_flash(animation)
	flick(animation, src)

/// Вспышка тревоги на каждой остановке торгов и обвале; тик цен звучит всегда, звонок и тревога - не чаще MARKET_ALARM_COOLDOWN.
/obj/structure/sign/ticker_board/proc/market_alarm(kind)
	if(kind == MARKET_SOUND_CRASH)
		board_flash("board_halt")
	if(kind != MARKET_SOUND_TICK)
		if(!COOLDOWN_FINISHED(src, alarm_cooldown))
			return
		COOLDOWN_START(src, alarm_cooldown, MARKET_ALARM_COOLDOWN)
	play_market_sound(kind)

/obj/structure/sign/ticker_board/proc/play_market_sound(kind)
	econ_market_sound(src, kind)

/obj/structure/sign/ticker_board/proc/update_ticker(datum/source, list/halted, list/relisted)
	SIGNAL_HANDLER
	var/list/companies = SSmarket.companies
	var/count = length(companies)
	if(!count)
		maptext = null
		return
	var/list/lines = list()
	var/shown_halted = FALSE
	for(var/index in 1 to min(TICKER_BOARD_LINES, count))
		var/datum/stock_company/company = companies[companies[((offset + index - 1) % count) + 1]]
		lines += ticker_line(company)
		shown_halted ||= company.is_halted()
	offset = (offset + TICKER_BOARD_LINES) % count
	maptext = MAPTEXT_TINY_UNICODE(jointext(lines, "<br>"))
	icon_state = shown_halted ? "board_halt" : "board"
	if(source)
		market_alarm(econ_market_tick_sound(halted, relisted))

/obj/structure/sign/ticker_board/proc/ticker_line(datum/stock_company/company)
	if(company.is_halted())
		// В TinyUnicode нет кириллицы: «СТОП» ушёл бы в запасной крупный шрифт и сломал строку
		return "<span style='color:#f4b400'>[company.ticker] STOP</span>"
	var/change = company.change_percent()
	var/color = change > 0 ? "#66ff66" : (change < 0 ? "#ff6666" : "#cccccc")
	var/shown_price = round(company.price, company.price >= TICKER_BOARD_WHOLE_PRICE ? 1 : 0.1)
	return "<span style='color:[color]'>[company.ticker] [shown_price]</span>"

/obj/structure/sign/ticker_board/examine(mob/user)
	. = ..()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		if(company.is_halted())
			. += "[ticker] ([company.name]): торги остановлены."
		else
			. += "[ticker] ([company.name]): [round(company.price, 0.01)] кр., [SSmarket.signed_percent(company.change_percent())]."
	. += span_notice("Новости компаний выходят в канале «[MARKET_NEWS_CHANNEL]» на ньюскастерах, торговать можно в программе «Биржа» КПК и на терминале биржи.")

/obj/structure/sign/ticker_board/wrench_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(!tool.use_tool(src, user, 4 SECONDS, volume = 50))
		return
	user.visible_message(span_notice("[user] снимает [src] со стены."), span_notice("Вы снимаете [src] со стены."))
	new /obj/item/sign/ticker_board(get_turf(user))
	qdel(src)

/obj/item/sign/ticker_board
	name = "stock ticker board"
	desc = "Табло котировок биржи сектора. Крепится на стену."
	sign_path = /obj/structure/sign/ticker_board

/datum/supply_pack/service/ticker_board
	name = "Stock Ticker Board Crate"
	desc = "Настенное табло котировок биржи сектора."
	cost = 1000
	contains = list(/obj/item/sign/ticker_board)
	crate_name = "ticker board crate"

#undef TICKER_BOARD_LINES
#undef TICKER_BOARD_WHOLE_PRICE
