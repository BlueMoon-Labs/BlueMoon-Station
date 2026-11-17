/**
 * Дерево строк BYOND упорядочено по алфавиту и перестраивается целиком (0.2-0.7 с), когда новая строка ложится глубже ~1000 уровней.
 * Удерживаемые метки времени идут по возрастанию и тянут одну ветку; минута суток в обоих форматах уже в дереве - ветка не длиннее минуты.
 */
GLOBAL_LIST_INIT(string_tree_anchors, build_string_tree_anchors())
/// Минуты SQLtime() текущих суток world.timeofday: на смене суток у меток новая дата, update_midnight_rollover() строит их заново.
GLOBAL_LIST_INIT(string_tree_sql_anchors, build_string_tree_sql_anchors())

/// Минуты суток вперемешку: подряд якоря сами вытянулись бы веткой.
/proc/string_tree_anchor_minutes()
	. = list()
	for(var/minute in 0 to 1439)
		. += minute
	shuffle_inplace(.)

/proc/build_string_tree_anchors()
	. = list()
	for(var/minute in string_tree_anchor_minutes())
		. += time2text(minute MINUTES, "hh:mm", 0)

/// Без date - как SQLtime() от world.timeofday: дату у времени суток даёт тот же time2text, в поясе сервера сутки ложатся на две даты.
/proc/build_string_tree_sql_anchors(date)
	. = list()
	for(var/minute in string_tree_anchor_minutes())
		. += date ? "[date] [time2text(minute MINUTES, "hh:mm", 0)]" : time2text(minute MINUTES + 1, "YYYY-MM-DD hh:mm")

/proc/update_string_tree_sql_anchors()
	if(islist(GLOB.string_tree_sql_anchors))
		GLOB.string_tree_sql_anchors = build_string_tree_sql_anchors()
