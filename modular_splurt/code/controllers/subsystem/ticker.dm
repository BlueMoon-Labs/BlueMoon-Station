// В BM-лобби PLAYER_READY_TO_OBSERVE никогда не выставляется:
// игроки нажимают кнопку «Быть наблюдателем» → make_me_an_observer() напрямую.
// Проц оставлен для совместимости с цепочкой ticker/fire().
/datum/controller/subsystem/ticker/proc/create_observers()
	for(var/mob/dead/new_player/player in GLOB.player_list)
		if(player.ready == PLAYER_READY_TO_OBSERVE && player.mind)
			//Break chain since this has a sleep input in it
			addtimer(CALLBACK(player, TYPE_PROC_REF(/mob/dead/new_player, make_me_an_observer)), 1)
