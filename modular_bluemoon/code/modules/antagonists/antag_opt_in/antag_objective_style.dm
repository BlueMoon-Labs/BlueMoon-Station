GLOBAL_LIST_INIT(antag_objective_styles, list(
	ANTAG_OBJECTIVE_STYLE_QUIET = "Без убийств",
	ANTAG_OBJECTIVE_STYLE_NORMAL = "Как выпадет",
	ANTAG_OBJECTIVE_STYLE_VIOLENT = "Больше убийств",
))

GLOBAL_LIST_INIT(antag_objective_style_descriptions, list(
	ANTAG_OBJECTIVE_STYLE_QUIET = "Предатель и генокрад не получают заданий на убийство: вместо них кражи, саботаж, подстава и другие. Дроиду HK-47 не предлагают ликвидаций, а охоту на антагониста - только захватом. Если так выбрал хоть один кровный брат, клятвы его братства обходятся без убийств: Месть кончается удержанием цели, Угона нет. Драться и убивать по ходу раунда это не запрещает.",
	ANTAG_OBJECTIVE_STYLE_NORMAL = "Задания выпадают как обычно.",
	ANTAG_OBJECTIVE_STYLE_VIOLENT = "Предателю чаще выпадает задание на убийство. В Хард-динамике шанс в полтора раза выше, в Медиуме - немного (с 25% до [25 + ANTAG_OBJECTIVE_VIOLENT_SOFT_BONUS]%) и только разовое убийство, после которого цель можно вернуть. Кровным братьям, если так выбрали все братья, чаще выпадает клятва Мести: в Харде в [BROTHER_VENDETTA_VIOLENT_HARD_MULT] раза, в Медиуме в [BROTHER_VENDETTA_VIOLENT_MEDIUM_MULT] раза. В Лайте и Экстенде убийств нет. У дроида HK-47 вес ликвидаций среди заказов в [ANTAG_OBJECTIVE_VIOLENT_KILL_MULT] раза выше.",
))

/proc/sanitize_antag_objective_style(style)
	return (style in GLOB.antag_objective_styles) ? style : ANTAG_OBJECTIVE_STYLE_NORMAL

/datum/preferences
	/// Какие задания игрок предпочитает получать, когда становится антагонистом.
	var/antag_objective_style = ANTAG_OBJECTIVE_STYLE_NORMAL

/datum/preferences/save_preferences(bypass_cooldown = FALSE, silent = FALSE)
	. = ..()
	if(!istype(., /savefile))
		return
	WRITE_FILE(.["antag_objective_style"], antag_objective_style)

/datum/preferences/load_preferences(bypass_cooldown = FALSE)
	. = ..()
	if(!istype(., /savefile))
		return
	.["antag_objective_style"] >> antag_objective_style
	antag_objective_style = sanitize_antag_objective_style(antag_objective_style)

/proc/antag_objective_style_options()
	var/list/styles = list()
	for(var/style in GLOB.antag_objective_styles)
		styles += list(list(
			"value" = style,
			"name" = GLOB.antag_objective_styles[style],
			"description" = GLOB.antag_objective_style_descriptions[style],
		))
	return styles

/datum/mind/proc/get_antag_objective_style()
	var/datum/preferences/prefs = key ? GLOB.preferences_datums[ckey(key)] : null
	return prefs ? sanitize_antag_objective_style(prefs.antag_objective_style) : ANTAG_OBJECTIVE_STYLE_NORMAL
