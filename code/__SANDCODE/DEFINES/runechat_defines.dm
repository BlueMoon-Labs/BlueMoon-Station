/*
 * # runechat_color_names
 * Used for remembering what color a player's speech would be.
 * It's associative, entries are built like this:
 * list("John" = "#FFFFFF")
 * Both values are strings.
*/
GLOBAL_LIST_EMPTY(runechat_color_names)

/*
 * # runechat_color_names_darkened
 * Затемнённый вариант того же цвета, тем же ключом - именем говорящего. Курсивный рунчат
 * красится им, а считать color_shift() на каждое сообщение дорого.
 *
 * Кэш общий, а не по атому: цвет выводится из имени целиком, поэтому у одинаковых имён он
 * одинаков, и три слота под него на КАЖДОМ атоме мира стоили 27 МБ адресного пространства
 * при полутора миллионах атомов - при том, что готовый общий кэш рядом уже лежал.
*/
GLOBAL_LIST_EMPTY(runechat_color_names_darkened)
