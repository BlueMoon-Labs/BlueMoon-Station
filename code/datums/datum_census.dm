/**
 * Перепись НЕ-атомных датумов: сколько их создано за раунд и сколько пережило qdel.
 *
 * Перепись инстансов (SStime_track.run_instance_census()) перебирает world.contents, а туда
 * BYOND кладёт только турфы, зоны, объекты и мобов. Всё остальное - компоненты, элементы,
 * /datum/gas_mixture, /datum/lighting_corner, таймеры, коллбеки, реагенты, ИИ-контроллеры,
 * /datum/mind, tgui-датумы - в мире не числится вовсе, и до этого файла ни один прибор
 * их не считал. Раунд 10048 показал +466 МБ адресного пространства при +23 458 инстансах,
 * то есть по 20 КБ на инстанс, чего не бывает: рост шёл мимо переписи, и мимо неё же
 * шло всё, что перечислено выше.
 *
 * КАК ЭТО РАБОТАЕТ И ПОЧЕМУ ЭТО НЕ ЛОВИТ АТОМЫ
 *
 * /atom/New() (code/game/atoms.dm) родителя НЕ зовёт - цепочка New() у любого атома там
 * и обрывается. Значит, определённый здесь /datum/New() физически недостижим для турфов,
 * объектов и мобов, и счётчик по построению считает ровно то, чего не видит перепись
 * инстансов. Это не фильтр, который можно забыть обновить, а свойство дерева типов;
 * если /atom/New() однажды начнёт звать ..(), атомы поедут в эту перепись потоком, и
 * увидеть это можно будет сразу - по появлению /obj/... в топе создания.
 *
 * ЧЕГО ЭТА ПЕРЕПИСЬ НЕ ЗНАЕТ
 *
 * Разница "создано минус qdel" - это НЕ число живых. Датум, потерявший последнюю ссылку
 * без qdel(), BYOND собирает молча, и Destroy() у него не зовётся: так уходят коллбеки,
 * газовые смеси, большая часть временных датумов. Поэтому разница читается как "столько
 * штук ушло не через qdel" - либо живут, либо собраны молча. Для типов, которые обязаны
 * удаляться явно (компоненты, таймеры, chatmessage), разница - это прямо утечка.
 *
 * Обратный промах тоже есть: подтип, чей New() не зовёт ..(), в счёт создания не попадёт,
 * а в счёт удаления попадёт, и разница у него уйдёт в минус. Минус в отчёте - не ошибка
 * прибора, а метка такого типа.
 *
 * И ещё одно, неочевидное: /image, /mutable_appearance и /sound - тоже датумы, и в перепись
 * они идут наравне со всеми. В локальном прогоне MetaStation они занимают три первых места
 * с большим отрывом (189 тысяч /mutable_appearance за одиннадцать минут БЕЗ единого игрока),
 * и это нормальный оборот, а не утечка: живут они доли секунды. Ради них отчёт и считает
 * разницу с прошлой переписью, а не итог за раунд.
 */

#ifdef DATUM_CENSUS

/// Тип -> сколько инстансов создано за раунд. Заполняется из /datum/New().
GLOBAL_REAL_VAR(list/datum_census_created)
/// Тип -> сколько раз отработал /datum/Destroy(). Атомы сюда попадают тоже, но в отчёт не идут:
/// отчёт перебирает ключи created, а туда атом не доходит (см. комментарий про /atom/New()).
GLOBAL_REAL_VAR(list/datum_census_destroyed)
/// Снимок created на прошлой переписи. Отчёт отдаёт РАЗНИЦУ: за раунд создаётся полмиллиона
/// /mutable_appearance, и в абсолютном топе кроме них не видно ничего и никогда.
GLOBAL_REAL_VAR(list/datum_census_snapshot_created)
/// Снимок остатка "создано минус qdel" на прошлой переписи, по той же причине.
GLOBAL_REAL_VAR(list/datum_census_snapshot_residue)

/**
 * Инкремент счётчика создания.
 *
 * Прок висит на самом горячем месте игры, поэтому здесь нет ни проверки типа, ни вызова
 * помощника: замер на изолированном стенде (два миллиона созданий, четыре чередующихся
 * прогона) даёт 0.21 мкс на датум - 422 мс против 838 мс на два миллиона ГОЛЫХ датумов. В относительных
 * величинах это удвоение, в абсолютных - пятая доля микросекунды, и у настоящего датума,
 * который в New() что-то делает, доля теряется в шуме.
 *
 * Список создаётся лениво, а не инициализатором глобала: GLOB собирается в
 * /datum/controller/master/New(), а датумы появляются и до него.
 *
 * ВЫЗОВ ..() ЗДЕСЬ ОБЯЗАТЕЛЕН, И НЕ РАДИ ПОРЯДКА.
 *
 * У /client стоит parent_type = /datum (client_defines.dm), поэтому ..() из /client/New()
 * приходит СЮДА. Пока этого прока не существовало, ..() из /client/New() попадал во
 * встроенный New(), а встроенное действие клиента - это и есть создание моба world.mob и
 * вызов его Login(). Стоит определить /datum/New() и не позвать родителя - и клиент
 * остаётся без моба, /client/New() возвращает null, а BYOND трактует это как отказ и
 * молча рвёт соединение: игрок видит "Connection closed.", в логах только Login/Logout
 * подряд, ни одного рантайма ни в runtime.log, ни в консоли DreamDaemon.
 */
/datum/New()
	var/list/created = datum_census_created
	if(!created)
		created = list()
		datum_census_created = created
	created[type] += 1
	return ..()

/**
 * Строки переписи датумов для лога мира плюс обновление снимка.
 *
 * Снимок нужен потому, что отчёт отдаёт РАЗНИЦУ с прошлой переписью, а не итог за раунд.
 * Итог бесполезен: локальный прогон MetaStation без единого игрока за одиннадцать минут
 * создал 189 тысяч /mutable_appearance и 119 тысяч /datum/lighting_corner, и в абсолютном
 * топе они стоят вечно, закрывая собой всё, что реально нажил раунд.
 *
 * Аргументы:
 * * top_n - сколько типов выписывать в каждый топ
 */
/proc/datum_census_lines(top_n)
	var/list/created = datum_census_created
	var/list/destroyed = datum_census_destroyed
	var/list/lines = datum_census_report_lines(created, destroyed, datum_census_snapshot_created, datum_census_snapshot_residue, top_n)

	// Снимок берётся ПОСЛЕ отчёта и копией: боевые счётчики продолжат наполняться из
	// /datum/New() прямо в эту же секунду, и отданная им наружу ссылка превратила бы
	// "разницу с прошлой переписью" в ноль.
	datum_census_snapshot_created = created?.Copy()
	datum_census_snapshot_residue = datum_census_residue(created, destroyed)
	return lines

/**
 * Остаток по типам: создано минус ушедшее через qdel.
 *
 * Отдельным проком, потому что его зовут дважды - на отчёт и на снимок, - и повторять
 * арифметику в двух местах значит однажды поправить только одно из них.
 */
/proc/datum_census_residue(list/created, list/destroyed)
	var/list/residue = list()
	if(!length(destroyed))
		// Ни одного Destroy() ещё не было: обращение по индексу к null - это рантайм, а не
		// ноль, и без этой ветки первая же перепись раннего раунда упала бы.
		return created ? created.Copy() : residue
	for(var/type_path in created)
		// destroyed[отсутствующий ключ] даёт null, а null в арифметике DM - ноль, то есть
		// тип, который ни разу не удалялся, честно остаётся при всём своём количестве.
		residue[type_path] = created[type_path] - destroyed[type_path]
	return residue

/**
 * Сборка строк отчёта из счётчиков и снимка прошлой переписи.
 *
 * Отдельным проком от datum_census_lines(), потому что это единственная часть переписи,
 * которую можно проверить юнит-тестом: боевые счётчики трогать нельзя (они наполняются
 * из /datum/New() прямо во время прогона), а арифметику разницы и сортировку топов -
 * надо: ошибка в них даёт правдоподобный и полностью выдуманный список.
 *
 * Две строки, а не одна: топ по созданию отвечает на вопрос "что мир перемалывает", топ по
 * остатку - на вопрос "что из этого не удаляется". Это разные списки, и путать их нельзя:
 * тип может лидировать по обороту и честно уходить в ноль, и наоборот.
 *
 * Аргументы:
 * * created - тип -> сколько создано за раунд
 * * destroyed - тип -> сколько раз отработал Destroy(); ключи-атомы здесь допустимы и игнорируются
 * * previous_created - снимок created на прошлой переписи, null на первой
 * * previous_residue - снимок остатка на прошлой переписи, null на первой
 * * top_n - сколько типов выписывать в каждый топ
 */
/proc/datum_census_report_lines(list/created, list/destroyed, list/previous_created, list/previous_residue, top_n)
	if(!length(created))
		return list("## MEMORY: перепись датумов: пусто")

	var/list/residue = datum_census_residue(created, destroyed)
	var/total_created = 0
	var/total_residue = 0
	for(var/type_path in created)
		total_created += created[type_path]
		total_residue += residue[type_path]

	var/growth_report = !isnull(previous_created)
	var/list/created_delta = growth_report ? datum_census_growth(created, previous_created) : created.Copy()
	var/list/residue_delta = growth_report ? datum_census_growth(residue, previous_residue) : residue.Copy()

	sortTim(created_delta, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)
	sortTim(residue_delta, GLOBAL_PROC_REF(cmp_numeric_dsc), TRUE)

	var/list/top_created = list()
	for(var/type_path in created_delta)
		if(length(top_created) >= top_n)
			break
		top_created += "[type_path] x[num2text(created_delta[type_path], 12)]"

	var/list/top_residue = list()
	for(var/type_path in residue_delta)
		if(length(top_residue) >= top_n)
			break
		top_residue += "[type_path] x[num2text(residue_delta[type_path], 12)]"

	// num2text по всему файлу по одной причине: обороты тут шестизначные, а BYOND
	// интерполирует такие числа шестью значащими цифрами, и в лог поедет "1.65592e+006".
	return list(
		"## MEMORY: перепись датумов: [length(created)] типов, создано за раунд [num2text(total_created, 12)], \
			не удалено через qdel [num2text(total_residue, 12)]; \
			[growth_report ? "создано с прошлой переписи" : "больше всего создано"]: \
			[length(top_created) ? top_created.Join(", ") : "пусто"]",
		"## MEMORY: датумы мимо qdel (живут либо собраны молча), \
			[growth_report ? "прирост с прошлой переписи" : "всего за раунд"]: \
			[length(top_residue) ? top_residue.Join(", ") : "пусто"]",
	)

/**
 * Разница двух срезов переписи датумов: тип -> насколько его стало больше.
 *
 * Убыль отбрасывается намеренно, как и в переписи инстансов: вопрос всегда один - что
 * копится, - а тип, которого стало меньше, на него не отвечает, но место в топе занимает.
 * Минус здесь возможен только у остатка (тип, чей New() не зовёт ..(), уходит в минус на
 * своих же qdel), и выбрасывать его тем более правильно.
 */
/proc/datum_census_growth(list/current, list/previous)
	var/list/growth = list()
	if(!length(previous))
		return current ? current.Copy() : growth
	for(var/type_path in current)
		var/delta = current[type_path] - previous[type_path]
		if(delta > 0)
			growth[type_path] = delta
	return growth

#endif
