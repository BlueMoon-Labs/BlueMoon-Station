/**
 * Книга недатумных аллокаций.
 *
 * ЗАЧЕМ. Раунд 10126 (Box Station, 87-105 игроков) вырос на 428 МБ после замера базы, и весь
 * этот рост пришёл двадцатью тремя ступенями по 10-70 МБ. В КАЖДОЙ детектор скачков написал
 * "объектов не прибавилось - платили НЕ датумами", перепись инстансов не сдвинулась, перепись
 * датумов не сдвинулась, тяжёлых прогонов подсистем в те тики не было и медленных единиц
 * работы тоже. Отдельно стоит кластер в лобби: девять скачков за 2.5 секунды на 450.7 МБ -
 * 11% потолка адресного пространства - при нуле новых объектов.
 *
 * То есть весь наличный инструментарий заточен под датумы, а платим мы не ими. Книга закрывает
 * ровно эту дыру: считает то, что аллоцирует мимо переписи, в местах, через которые эта работа
 * обязана пройти.
 *
 * ЧТО ЭТО НЕ ЕСТЬ. Это не аллокатор и не профайлер: BYOND не отдаёт ни байта статистики о куче.
 * Книга считает РАБОТУ известных тяжёлых аллокаторов (сколько иконок собрано, сколько байтов
 * ушло клиенту, сколько прочитано с диска), а не занятую ими память. Связь между работой и
 * мегабайтами устанавливает читатель лога, сопоставляя дельту книги с шагом VmSize в том же
 * окне. Категория, которая при ступени в 60 МБ стоит на нуле, - это отвод подозрения, и он
 * стоит ровно столько же, сколько попадание.
 *
 * ЦЕНА. Инкремент элемента плоского числового списка на вызов. Самая горячая точка - getFlatIcon
 * (2005 вызовов за раунд по профилю из perf_optimizations.dm), остальные на порядок реже.
 *
 * ГДЕ КАТЕГОРИИ. Номера категорий - в code/__DEFINES/nondatum_ledger.dm: они нужны
 * файлам, которые включаются раньше этого (icons.dm), а дефайн обязан быть объявлен до
 * первого использования по порядку включения в tgstation.dme.
 *
 * КУДА СМОТРЕТЬ. Дельта за окно печатается в блоке "=== СКАЧОК ПАМЯТИ ===" в tick_spikes.log
 * рядом с "сколько" и "кто работал"; кумулятив уходит в перф-CSV колонками ledger_*.
 */

/**
 * Кумулятивные счётчики книги. Плоский числовой список, а не assoc: инкремент по
 * константному индексу стоит дешевле поиска по ключу, а снимок и разность - это Copy() и
 * цикл по индексам, без выравнивания ключей.
 */
GLOBAL_LIST_INIT(nondatum_ledger, list(0, 0, 0, 0, 0, 0, 0))

/// Записать работу в книгу. Единственная точка записи: нулевые и отрицательные величины
/// отсекаются здесь, чтобы вызывающие не проверяли каждый свой аргумент сами.
/proc/note_nondatum_alloc(category, amount = 1)
	if(amount <= 0)
		return
	GLOB.nondatum_ledger[category] += amount

/// Снимок книги. Copy(), а не ссылка: снимок обязан пережить следующие инкременты.
/proc/nondatum_ledger_snapshot()
	return GLOB.nondatum_ledger.Copy()

/**
 * Человекочитаемая дельта книги между двумя снимками.
 *
 * Печатаются ТОЛЬКО ненулевые категории: строка, в которой семь нулей из семи, ничего не
 * сообщает, а читается как содержательная. Пустая дельта называет себя вслух - это ответ
 * "ни один известный недатумный аллокатор в это окно не работал", и он важнее любого числа.
 */
/proc/nondatum_ledger_delta_line(list/before, list/after)
	if(!islist(before) || !islist(after) || length(before) != NONDATUM_LEDGER_LEN || length(after) != NONDATUM_LEDGER_LEN)
		return "книга недатумных аллокаций: снимка нет"
	var/list/parts = list()
	var/icons = after[NONDATUM_LEDGER_ICONS] - before[NONDATUM_LEDGER_ICONS]
	if(icons > 0)
		var/pixels = after[NONDATUM_LEDGER_ICON_PIXELS] - before[NONDATUM_LEDGER_ICON_PIXELS]
		parts += "иконок [icons] ([round(pixels / 1000000, 0.01)] Мпикс)"
	var/asset_bytes = after[NONDATUM_LEDGER_ASSET_BYTES] - before[NONDATUM_LEDGER_ASSET_BYTES]
	if(asset_bytes > 0)
		parts += "ассетов клиентам [nondatum_ledger_mb(asset_bytes)]"
	var/rsc_bytes = after[NONDATUM_LEDGER_RSC_BYTES] - before[NONDATUM_LEDGER_RSC_BYTES]
	if(rsc_bytes > 0)
		parts += "ресурсов по игровому соединению [nondatum_ledger_mb(rsc_bytes)]"
	var/tgui_bytes = after[NONDATUM_LEDGER_TGUI_BYTES] - before[NONDATUM_LEDGER_TGUI_BYTES]
	if(tgui_bytes > 0)
		parts += "нагрузок tgui [nondatum_ledger_mb(tgui_bytes)]"
	var/statpanel_bytes = after[NONDATUM_LEDGER_STATPANEL_BYTES] - before[NONDATUM_LEDGER_STATPANEL_BYTES]
	if(statpanel_bytes > 0)
		parts += "нагрузок статбраузера [nondatum_ledger_mb(statpanel_bytes)]"
	var/sheets = after[NONDATUM_LEDGER_SPRITESHEETS] - before[NONDATUM_LEDGER_SPRITESHEETS]
	if(sheets > 0)
		parts += "сборок спрайтшитов [sheets]"
	if(!length(parts))
		return "книга недатумных аллокаций за окно: пусто - ни один известный недатумный аллокатор не работал"
	return "книга недатумных аллокаций за окно: [parts.Join(", ")]"

/// Байты мегабайтами для строки лога. Отдельным проком: делитель обязан быть один на всю книгу.
/proc/nondatum_ledger_mb(bytes)
	return "[round(bytes / 1048576, 0.01)] МБ"
