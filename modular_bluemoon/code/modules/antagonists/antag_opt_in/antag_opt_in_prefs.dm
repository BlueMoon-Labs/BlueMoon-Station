/datum/preferences
	/// Уровень согласия персонажа быть целью антагонистов; null - значение по умолчанию из конфига.
	var/antag_opt_in_level
	var/antag_opt_in_notice_seen = FALSE

/proc/sanitize_antag_opt_in_level(value)
	if(!isnum(value) || value != round(value) || value < ANTAG_OPT_IN_NOT_TARGET || value > ANTAG_OPT_IN_ROUND_REMOVE)
		return null
	return value

/proc/antag_opt_in_thresholds_text()
	return "СБ на своей работе не опускается ниже «[antag_opt_in_level_name(CONFIG_GET(number/antag_opt_in_security_min))]», \
		командование на своей работе - ниже «[antag_opt_in_level_name(CONFIG_GET(number/antag_opt_in_command_min))]», \
		игрок с включённой антаг-ролью экипажа - ниже «[antag_opt_in_level_name(CONFIG_GET(number/antag_opt_in_antag_enabled_min))]»."

/datum/preferences/proc/get_antag_opt_in_pref_level()
	return isnull(antag_opt_in_level) ? antag_opt_in_default_level() : antag_opt_in_level

/datum/preferences/proc/antag_opt_in_pref_html()
	var/level = get_antag_opt_in_pref_level()
	var/default_suffix = isnull(antag_opt_in_level) ? " (по умолчанию)" : ""
	return "<span title='Кем персонаж может стать в заданиях антагонистов. [GLOB.antag_opt_in_descriptions["[level]"]]'>Цель антагонистов : <a href='?_src_=prefs;preference=antag_opt_in_level;task=input'><font color='[antag_opt_in_level_color(level)]'>[antag_opt_in_level_name(level)][default_suffix]</font></a></span><br>"

/datum/preferences/proc/choose_antag_opt_in_level(mob/user)
	var/list/choices = list()
	var/list/explanation = list()
	for(var/level in ANTAG_OPT_IN_NOT_TARGET to ANTAG_OPT_IN_ROUND_REMOVE)
		var/level_name = antag_opt_in_level_name(level)
		choices[level_name] = level
		explanation += "[level_name]: [GLOB.antag_opt_in_descriptions["[level]"]]"
	var/message = "Кем ваш персонаж может стать в заданиях антагонистов?\n\n[jointext(explanation, "\n")]\n\nНастройка ограничивает только выбор целей заданий, а не насилие в игре. [antag_opt_in_thresholds_text()]"
	var/choice = tgui_input_list(user, message, "Цель антагонистов", choices, antag_opt_in_level_name(get_antag_opt_in_pref_level()))
	if(isnull(choice) || !(choice in choices))
		return
	antag_opt_in_level = choices[choice]

/datum/preferences/proc/show_antag_opt_in_notice()
	if(antag_opt_in_notice_seen || !parent)
		return
	antag_opt_in_notice_seen = TRUE
	save_pref_var("antag_opt_in_notice_seen")
	var/list/level_names = list()
	for(var/level in ANTAG_OPT_IN_NOT_TARGET to ANTAG_OPT_IN_ROUND_REMOVE)
		level_names += "«[antag_opt_in_level_name(level)]»"
	to_chat(parent, examine_block("<span class='notice'><b>Новая настройка: согласие быть целью антагонистов.</b><br>\
		В редакторе персонажа, в блоке Consent preferences, можно выбрать, кем персонаж может стать в заданиях антагонистов: [english_list(level_names, and_text = " или ")]. \
		Сейчас у текущего персонажа: «[antag_opt_in_level_name(get_antag_opt_in_pref_level())]».<br>\
		Настройка ограничивает только выбор целей заданий, а не насилие в игре. [antag_opt_in_thresholds_text()] \
		В раунде уровень меняется в меню взаимодействий, на вкладке настроек персонажа.<br>\
		<a href='?_src_=prefs;preference=antag_opt_in_level;task=input'>Выбрать уровень</a> (после выбора сохраните персонажа). Подробности - в вики, раздел «Политика антагонистов».</span>"))

/datum/component/interaction_menu_granter/proc/antag_opt_in_ui_data(mob/living/self)
	var/datum/mind/self_mind = self?.mind
	var/datum/preferences/prefs = self?.client?.prefs
	var/chosen = prefs ? prefs.get_antag_opt_in_pref_level() : antag_opt_in_default_level()
	if(self_mind)
		chosen = isnull(self_mind.antag_opt_in_level) ? antag_opt_in_default_level() : self_mind.antag_opt_in_level
	var/list/levels = list()
	for(var/level in ANTAG_OPT_IN_NOT_TARGET to ANTAG_OPT_IN_ROUND_REMOVE)
		levels += list(list(
			"value" = level,
			"name" = antag_opt_in_level_name(level),
			"color" = antag_opt_in_level_color(level),
			"description" = GLOB.antag_opt_in_descriptions["[level]"],
		))
	return list(
		"level" = chosen,
		"effective" = self_mind ? self_mind.get_effective_antag_opt_in_level() : chosen,
		"levels" = levels,
		"thresholds" = antag_opt_in_thresholds_text(),
	)

/datum/component/interaction_menu_granter/proc/set_antag_opt_in_level(mob/living/self, level)
	level = sanitize_antag_opt_in_level(level)
	if(isnull(level) || !self)
		return FALSE
	var/datum/preferences/prefs = self.client?.prefs
	if(prefs)
		prefs.antag_opt_in_level = level
		prefs.save_character()
	if(self.mind)
		self.mind.antag_opt_in_level = level
	log_game("[key_name(self)] меняет согласие быть целью антагонистов на «[antag_opt_in_level_name(level)]».")
	var/effective = self.mind ? self.mind.get_effective_antag_opt_in_level() : level
	to_chat(self, span_notice("Согласие быть целью антагонистов: «[antag_opt_in_level_name(level)]», итоговый уровень «[antag_opt_in_level_name(effective)]». Действует на новые выборы целей, уже выданные задания не меняются."))
	return TRUE

/mob/dead/new_player/Login()
	. = ..()
	if(client?.prefs && !client.prefs.antag_opt_in_notice_seen)
		addtimer(CALLBACK(client.prefs, TYPE_PROC_REF(/datum/preferences, show_antag_opt_in_notice)), 5 SECONDS)
