/obj/machinery/computer/stock_terminal
	name = "stock exchange terminal"
	desc = "Терминал биржи сектора: котировки компаний и торговля акциями с личного счёта, у капитана - и из казны станции. График на экране показывает, растут ли акции в среднем, и сразу перерисовывается на событиях станции, двигающих акции. При остановке торгов и обвале рынка терминал бьёт тревогу, при возобновлении торгов и буме в секторе звонит."
	icon = 'icons/obj/machines/economy/stock_terminal.dmi'
	icon_state = "terminal"
	icon_screen = "terminal_ticker"
	icon_keyboard = null
	unique_icon = TRUE
	circuit = /obj/item/circuitboard/computer/stock_terminal
	light_color = LIGHT_COLOR_GREEN
	var/datum/computer_file/program/stock_exchange/program
	/// График на экране: рынок в среднем вырос за окно истории котировок
	var/market_up = TRUE
	COOLDOWN_DECLARE(alarm_cooldown)

/obj/machinery/computer/stock_terminal/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	program = new
	RegisterSignal(SSmarket, COMSIG_MARKET_STOCKS_TICKED, PROC_REF(on_stocks_ticked))
	RegisterSignal(SSmarket, COMSIG_MARKET_STATION_EVENT, PROC_REF(on_station_event))

/obj/machinery/computer/stock_terminal/Destroy()
	UnregisterSignal(SSmarket, list(COMSIG_MARKET_STOCKS_TICKED, COMSIG_MARKET_STATION_EVENT))
	QDEL_NULL(program)
	return ..()

/obj/machinery/computer/stock_terminal/proc/on_station_event(datum/source, key)
	SIGNAL_HANDLER
	switch(key)
		if("market_crash")
			market_alarm(MARKET_SOUND_CRASH)
		if("sector_boom")
			market_alarm(MARKET_SOUND_BELL)
	update_chart()

/// Звонок и тревога биржи на включённом терминале, не чаще MARKET_ALARM_COOLDOWN; тик цен терминал не озвучивает.
/obj/machinery/computer/stock_terminal/proc/market_alarm(kind)
	if(kind == MARKET_SOUND_TICK || (machine_stat & (NOPOWER|BROKEN)) || !COOLDOWN_FINISHED(src, alarm_cooldown))
		return
	COOLDOWN_START(src, alarm_cooldown, MARKET_ALARM_COOLDOWN)
	play_market_sound(kind)

/obj/machinery/computer/stock_terminal/proc/play_market_sound(kind)
	econ_market_sound(src, kind)

/obj/machinery/computer/stock_terminal/proc/on_stocks_ticked(datum/source, list/halted, list/relisted)
	SIGNAL_HANDLER
	market_alarm(econ_market_tick_sound(halted, relisted))
	update_chart()
	if(length(SStgui.open_uis_by_src[REF(src)]))
		INVOKE_ASYNC(src, TYPE_PROC_REF(/datum, update_static_data_for_all_viewers))

/obj/machinery/computer/stock_terminal/proc/update_chart()
	var/total = 0
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		if(!company.is_halted())
			total += company.change_percent()
	if(market_up == (total >= 0))
		return
	market_up = total >= 0
	update_appearance()

/obj/machinery/computer/stock_terminal/update_icon_state()
	icon_state = (machine_stat & NOPOWER) && !(machine_stat & BROKEN) ? "terminal_off" : "terminal"
	return ..()

/obj/machinery/computer/stock_terminal/update_overlays()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		return
	var/chart = market_up ? "terminal_up" : "terminal_down"
	. += mutable_appearance(icon, chart)
	. += emissive_appearance(icon, chart, offset_spokesman = src)

/obj/machinery/computer/stock_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "StockTerminal", name)
		ui.open()

/obj/machinery/computer/stock_terminal/ui_static_data(mob/user)
	return program.stocks_static_data()

/obj/machinery/computer/stock_terminal/ui_data(mob/user)
	return program.stocks_data(user)

/obj/machinery/computer/stock_terminal/ui_close(mob/user)
	. = ..()
	program.forget_user(user)

/obj/machinery/computer/stock_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return program.stocks_act(usr, action, params)

/obj/item/circuitboard/computer/stock_terminal
	name = "Stock Exchange Terminal (Computer Board)"
	icon_state = "supply"
	build_path = /obj/machinery/computer/stock_terminal

/datum/design/board/stock_terminal
	name = "Computer Design (Stock Exchange Terminal)"
	desc = "Плата терминала биржи сектора."
	id = "stock_terminal"
	build_path = /obj/item/circuitboard/computer/stock_terminal
	category = list("Computer Boards")
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/techweb_node/comptech/New()
	. = ..()
	design_ids += "stock_terminal"
