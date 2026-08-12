/datum/game_mode/extended
	name = "secret extended"
	config_tag = "secret_extended"
	false_report_weight = 5
	required_players = 0
	chaos = 0

	announce_span = "notice"
	announce_text = "Just have fun and enjoy the game!"

/datum/game_mode/extended/pre_setup()
	// Профиль директора поднимает dynamic, но Extended - отдельный геймод (master_mode "Extended"
	// матчится на config_tag в pick_mode), поэтому поднимаем сами - иначе директор стоит весь раунд.
	// Форс/секрет-пути могли оставить round_type от прошлого выбора - без этого setup_profile()
	// взял бы чужой профиль, а контент-гейты Extended (аплинк, гост-роли) не сработали бы.
	GLOB.round_type = ROUNDTYPE_EXTENDED
	SSdirector.setup_profile()
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
