/datum/round_event_control/grid_check
	name = "Grid Check"
	typepath = /datum/round_event/grid_check
	weight = 25
	max_occurrences = 2
	category = EVENT_CATEGORY_ENGINEERING
	description = "Turns off all APCs for a while, or until they are manually rebooted."

/datum/round_event/grid_check
	announce_when	= 1
	start_when = 1

/datum/round_event/grid_check/announce(fake)
	switch(rand(1, 10))
		if(1 to 5)
			priority_announce("Обнаружена аномальная активность в энергосети [station_name()]. В качестве меры предосторожности электропитание станции будет отключено на неопределенный срок.", "Критический Сбой Питания", 'sound/announcer/classic/poweroff2.ogg')
		if(6 to 7)
			priority_announce("Обнаружено физиологическое вмешательство в энергосеть [station_name()]. В качестве меры предосторожности электропитание станции будет отключено на неопределенный срок.", "Критический Сбой Питания", 'sound/announcer/classic/poweroff.ogg')
		if(8 to 10)
			priority_announce("Сегодня на Аванпосту Центрального Командования отмечается праздник «Приведи Своего Отца». В электропитание [station_name()] обнаружено вмешательство. Приносим свои извинения за доставленные неудобства.", "Критический Сбой Питания", 'sound/announcer/intern/poweroff_boomer.ogg')

/datum/round_event/grid_check/start()
	power_fail(30, 120)
