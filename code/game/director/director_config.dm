/// Поля профиля, задаваемые в минутах в конфиге и конвертируемые в децисекунды при применении.
#define DIRECTOR_CONFIG_MINUTE_FIELDS list("max_quiet_time", "antag_light_spacing", "antag_heavy_spacing", "ghost_light_spacing", "ghost_heavy_spacing", "latejoin_spacing", "admin_cancel_time", "global_spacing", "family_spacing")
/// То же для полей действий: в коде они в децисекундах, оператору - в минутах.
#define DIRECTOR_CONFIG_ACTION_MINUTE_FIELDS list("earliest_start", "intensity_linger")

/datum/controller/subsystem/director
	/// Текст последней ошибки config/director.json (парсинг или неизвестный ключ), null если всё чисто.
	var/config_error
	/// Последний распарсенный director.json. В pre_setup load_config() отрабатывает ДО регистрации
	/// рулсетов (setup_profile внутри generate_threat), поэтому секция actions их не видит; кэш
	/// позволяет доприменить конфиг к рулсетам в register_ruleset_actions.
	var/list/cached_config

/// Читает config/director.json и накатывает переопределения на активный профиль и на действия.
/// Файл опционален: дефолты живут в коде, отсутствие файла - не ошибка.
/datum/controller/subsystem/director/proc/load_config()
	config_error = null
	var/path = "config/director.json"
	if(!fexists(path))
		return
	var/raw = file2text(path)
	var/list/data
	try
		data = json_decode(raw)
	catch(var/exception/e)
		config_error = "director.json не парсится: [e]"
		message_admins("DIRECTOR: [config_error]")
		return
	if(!islist(data))
		config_error = "director.json: верхний уровень должен быть объектом"
		message_admins("DIRECTOR: [config_error]")
		return
	cached_config = data
	var/list/profiles_conf = data["profiles"]
	if(islist(profiles_conf) && profile)
		var/list/my_conf = profiles_conf[GLOB.round_type]
		if(islist(my_conf))
			apply_profile_config(profile, my_conf)
	var/list/actions_conf = data["actions"]
	if(islist(actions_conf))
		for(var/datum/director_action/action as anything in actions)
			var/list/action_conf = actions_conf[action.action_name()]
			if(islist(action_conf))
				apply_action_config(action, action_conf)

/// Накатывает один объект конфига на профиль. Неизвестные ключи не рантайм, а config_error + сообщение админам.
/// quiet - без жалоб на неизвестные ключи: панель применяет секции НЕактивных профилей при каждой
/// сборке static-данных, и чужая опечатка спамила бы админ-чат на каждое открытие вкладки.
/datum/controller/subsystem/director/proc/apply_profile_config(datum/director_profile/target, list/conf, quiet = FALSE)
	for(var/key in conf)
		if(key == "severity_spacing" || key == "pool_shares" || key == "disruption_weight_mults")
			var/list/sub = conf[key]
			var/list/dest = target.vars[key]
			for(var/sev in sub)
				dest[sev] = (key == "severity_spacing") ? (sub[sev] MINUTES) : sub[sev]
			continue
		if(!(key in target.vars))
			if(!quiet)
				config_error = "Неизвестный ключ профиля: [key]"
				message_admins("DIRECTOR: [config_error]")
			continue
		var/value = conf[key]
		if(key in DIRECTOR_CONFIG_MINUTE_FIELDS)
			value = value MINUTES
		target.vars[key] = value

/// Накатывает один объект конфига на действие (событие или динамик-рулсет).
/datum/controller/subsystem/director/proc/apply_action_config(datum/director_action/action, list/conf)
	for(var/key in conf)
		if(!(key in action.vars))
			config_error = "Неизвестный ключ действия [action.action_name()]: [key]"
			message_admins("DIRECTOR: [config_error]")
			continue
		var/value = conf[key]
		if(key in DIRECTOR_CONFIG_ACTION_MINUTE_FIELDS)
			value = value MINUTES
		action.vars[key] = value

/// Защита ролей от антагонизма: серверный флаг config.txt (не director.json), поэтому применяется
/// отдельно от apply_action_config. Вызывается dynamic-режимом при создании каждого рулсета
/// (roundstart/midround/latejoin).
/datum/controller/subsystem/director/proc/apply_role_protection(datum/dynamic_ruleset/ruleset)
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		ruleset.restricted_roles |= ruleset.protected_roles
	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		ruleset.restricted_roles |= "Assistant"

/client/proc/reload_director_config()
	set category = "Admin.Events"
	set name = "Reload Director Config"
	if(!check_rights(R_ADMIN))
		return
	SSdirector.load_config()
	message_admins("[key_name_admin(usr)] перезагрузил director.json[SSdirector.config_error ? " (ОШИБКА: [SSdirector.config_error])" : ""].")

#undef DIRECTOR_CONFIG_MINUTE_FIELDS
#undef DIRECTOR_CONFIG_ACTION_MINUTE_FIELDS
