/datum/game_mode/extended
	name = "secret extended"
	config_tag = "secret_extended"
	false_report_weight = 5
	required_players = 0
	chaos = 0

	announce_span = "notice"
	announce_text = "Just have fun and enjoy the game!"

/datum/game_mode/extended/pre_setup()
	return TRUE

/datum/game_mode/extended/generate_report()
	return "В перехваченной передаче в основном не упоминался ваш сектор. Возможно, что в вашем Секторе Системы Синих Лун нет ничего, что могло бы угрожать вашему Объекту во время этой смены."

/datum/game_mode/extended/announced
	name = "Extended"
	config_tag = "Extended"
	false_report_weight = 0

/datum/game_mode/extended/announced/generate_station_goals()
	if(flipseclevel) //CIT CHANGE - allows the sec level to be flipped roundstart
		return ..()
	for(var/T in subtypesof(/datum/station_goal))
		var/datum/station_goal/G = new T
		if(!G.can_be_selected())
			qdel(G)
			continue
		station_goals += G
		G.send_report(announce_report = FALSE)

/datum/game_mode/extended/announced/send_intercept(report = 0)
	if(flipseclevel) //CIT CHANGE - allows the sec level to be flipped roundstart
		return ..()
	priority_announce("Благодаря неустанным усилиям наших отделов Безопасности и Разведки, в настоящее время не существует достоверных угроз для '[station_name()]'. Все проекты по строительству на вашем Объекте были утверждены. Удачной смены! Развлекайтесь!!", "Отчет о безопасности.", SSstation.announcer.get_rand_report_sound())
