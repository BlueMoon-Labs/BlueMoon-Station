/**
 * Дерево строк BYOND упорядочено по алфавиту и перестраивается целиком (0.2-0.7 с), когда новая строка ложится глубже ~1000 уровней.
 * Удерживаемые метки времени идут по возрастанию и тянут одну ветку; минута суток в обоих форматах уже в дереве - ветка не длиннее минуты.
 */
GLOBAL_LIST_INIT(string_tree_anchors, build_string_tree_anchors())

/proc/build_string_tree_anchors()
	var/list/minutes = list()
	for(var/minute in 0 to 1439)
		minutes += minute
	// Подряд якоря сами вытянулись бы веткой.
	shuffle_inplace(minutes)
	. = list()
	for(var/minute in minutes)
		. += time2text(minute MINUTES, "hh:mm", 0)
		// Как SQLtime() от world.timeofday: дату у времени суток даёт тот же time2text.
		. += time2text(minute MINUTES + 1, "YYYY-MM-DD hh:mm")
