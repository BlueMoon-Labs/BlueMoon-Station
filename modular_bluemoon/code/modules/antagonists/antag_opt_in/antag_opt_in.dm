GLOBAL_LIST_INIT(antag_opt_in_strings, list(
	"[ANTAG_OPT_IN_NOT_TARGET]" = "Не цель заданий",
	"[ANTAG_OPT_IN_TEMPORARY]" = "Цель без убийства",
	"[ANTAG_OPT_IN_KILL]" = "Цель убийства",
	"[ANTAG_OPT_IN_ROUND_REMOVE]" = "Цель любых заданий",
))

GLOBAL_VAR_INIT(antag_opt_in_disclaimer, "Это не защита от смерти: в драке, при самообороне, задержании или если персонаж встал у антагониста на пути, его по-прежнему могут убить. Уровень решает только, может ли персонаж выпасть целью задания.")

GLOBAL_LIST_INIT(antag_opt_in_colors, list(
	"[ANTAG_OPT_IN_NOT_TARGET]" = "#8a8a8a",
	"[ANTAG_OPT_IN_TEMPORARY]" = "#4a90d9",
	"[ANTAG_OPT_IN_KILL]" = "#e08a2c",
	"[ANTAG_OPT_IN_ROUND_REMOVE]" = "#d64545",
))

GLOBAL_LIST_INIT(antag_opt_in_descriptions, list(
	"[ANTAG_OPT_IN_NOT_TARGET]" = "Персонаж не выпадает целью заданий антагонистов, кроме задания на защиту: защищаемому оно ничем не грозит. Убить персонажа вне задания всё равно могут.",
	"[ANTAG_OPT_IN_TEMPORARY]" = "Персонаж может стать целью кражи, похищения, подставы, помощи в побеге и выкупа души, но не задания на убийство. Убить персонажа вне задания всё равно могут.",
	"[ANTAG_OPT_IN_KILL]" = "Персонаж может стать целью убийства, после которого его можно вернуть в раунд: разовое убийство, контракт, охота еретика.",
	"[ANTAG_OPT_IN_ROUND_REMOVE]" = "Персонаж может стать целью любого задания, включая окончательное устранение: уничтожение, кража мозга, жертва культа.",
))

/// Включённая хотя бы одна из этих антаг-ролей поднимает порог согласия на время смены.
GLOBAL_LIST_INIT(antag_opt_in_forcing_roles, list(
	ROLE_TRAITOR,
	ROLE_BROTHER,
	ROLE_CHANGELING,
	ROLE_MALF,
	ROLE_REV,
	ROLE_CULTIST,
	ROLE_HERETIC,
	ROLE_BLOODSUCKER,
	ROLE_DEVIL,
	ROLE_SERVANT_OF_RATVAR,
	ROLE_OVERTHROW,
	ROLE_INTERNAL_AFFAIRS,
	ROLE_FAMILIES,
	ROLE_OPERATIVE,
	ROLE_WIZARD,
	ROLE_SLAVER,
	ROLE_MONKEY,
	ROLE_MASS_SHOOTER,
))

/proc/antag_opt_in_level_name(level)
	return GLOB.antag_opt_in_strings["[level]"] || GLOB.antag_opt_in_strings["[ANTAG_OPT_IN_ROUND_REMOVE]"]

/proc/antag_opt_in_level_color(level)
	return GLOB.antag_opt_in_colors["[level]"] || GLOB.antag_opt_in_colors["[ANTAG_OPT_IN_ROUND_REMOVE]"]

/proc/antag_opt_in_default_level()
	return CONFIG_GET(number/antag_opt_in_default_level)

/proc/antag_opt_in_allows(datum/mind/target_mind, required_level)
	if(!target_mind)
		return FALSE
	return target_mind.get_effective_antag_opt_in_level() >= required_level

/proc/antag_opt_in_prefs_force_minimum(datum/preferences/prefs)
	if(!prefs || (prefs.toggles & NO_ANTAG))
		return FALSE
	for(var/role in GLOB.antag_opt_in_forcing_roles)
		if(role in prefs.be_special)
			return TRUE
	return FALSE

/datum/mind
	/// Уровень из настроек персонажа; null - значение по умолчанию из конфига.
	var/antag_opt_in_level
	/// Порог за включённые антаг-роли, снятый при выходе из лобби.
	var/antag_opt_in_spawn_minimum = ANTAG_OPT_IN_NOT_TARGET

/datum/mind/proc/apply_antag_opt_in_prefs(datum/preferences/prefs)
	if(!prefs)
		return
	antag_opt_in_level = prefs.antag_opt_in_level
	antag_opt_in_spawn_minimum = antag_opt_in_prefs_force_minimum(prefs) ? CONFIG_GET(number/antag_opt_in_antag_enabled_min) : ANTAG_OPT_IN_NOT_TARGET

/datum/mind/proc/get_antag_opt_in_job_minimum()
	. = ANTAG_OPT_IN_NOT_TARGET
	if(assigned_role in GLOB.security_positions)
		. = max(., CONFIG_GET(number/antag_opt_in_security_min))
	if(assigned_role in GLOB.command_positions)
		. = max(., CONFIG_GET(number/antag_opt_in_command_min))

/datum/mind/proc/get_antag_opt_in_minimum()
	return max(get_antag_opt_in_job_minimum(), antag_opt_in_spawn_minimum)

/datum/mind/proc/get_effective_antag_opt_in_level()
	var/chosen = isnull(antag_opt_in_level) ? antag_opt_in_default_level() : antag_opt_in_level
	return clamp(max(chosen, get_antag_opt_in_minimum()), ANTAG_OPT_IN_NOT_TARGET, ANTAG_OPT_IN_ROUND_REMOVE)

/datum/objective
	/// Минимальный уровень согласия цели. Тип без явного уровня считается самым жёстким.
	var/required_opt_in_level = ANTAG_OPT_IN_ROUND_REMOVE

/datum/objective/proc/opt_in_valid(datum/mind/target_mind)
	return antag_opt_in_allows(target_mind, required_opt_in_level)

/datum/objective/assassinate/once
	required_opt_in_level = ANTAG_OPT_IN_KILL

/datum/objective/assassinate/internal
	required_opt_in_level = ANTAG_OPT_IN_KILL

/datum/objective/mutiny
	required_opt_in_level = ANTAG_OPT_IN_KILL

/datum/objective/destroy
	required_opt_in_level = ANTAG_OPT_IN_KILL

/datum/objective/contract
	required_opt_in_level = ANTAG_OPT_IN_KILL

/datum/objective/overthrow
	required_opt_in_level = ANTAG_OPT_IN_KILL

/datum/objective/escape/escape_with_identity
	required_opt_in_level = ANTAG_OPT_IN_TEMPORARY

/datum/objective/kidnap
	required_opt_in_level = ANTAG_OPT_IN_TEMPORARY

/datum/objective/frame
	required_opt_in_level = ANTAG_OPT_IN_TEMPORARY

/datum/objective/breakout
	required_opt_in_level = ANTAG_OPT_IN_TEMPORARY

/datum/objective/rescue_prisoner
	required_opt_in_level = ANTAG_OPT_IN_TEMPORARY

/datum/objective/devil/buy_target
	required_opt_in_level = ANTAG_OPT_IN_TEMPORARY

/datum/objective/protect
	required_opt_in_level = ANTAG_OPT_IN_NOT_TARGET
