/// Звук биржи там, где стоит табло или терминал: тик цен тихий, звонок и тревога слышны только рядом, не по всей станции.
/proc/econ_market_sound(atom/source, kind)
	switch(kind)
		if(MARKET_SOUND_TICK)
			playsound(source, 'sound/economy/ticker_tick.ogg', 15, TRUE, SILENCED_SOUND_EXTRARANGE)
		if(MARKET_SOUND_BELL)
			playsound(source, 'sound/economy/market_bell.ogg', 40, FALSE)
		if(MARKET_SOUND_CRASH)
			playsound(source, 'sound/economy/market_crash.ogg', 50, FALSE)

/// Что прозвучит на биржевом тике: тревога при остановке торгов, звонок при возобновлении, иначе тик цен.
/proc/econ_market_tick_sound(list/halted, list/relisted)
	if(length(halted))
		return MARKET_SOUND_CRASH
	if(length(relisted))
		return MARKET_SOUND_BELL
	return MARKET_SOUND_TICK
