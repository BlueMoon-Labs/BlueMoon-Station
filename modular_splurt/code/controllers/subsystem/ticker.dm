// В BM-лобби PLAYER_READY_TO_OBSERVE никогда не выставляется:
// игроки нажимают кнопку «Быть наблюдателем» → make_me_an_observer() напрямую.
/datum/controller/subsystem/ticker/proc/create_observers()
	return
