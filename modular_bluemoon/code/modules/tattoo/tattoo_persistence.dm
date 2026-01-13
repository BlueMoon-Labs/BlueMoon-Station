// Система сохранения татуировок между раундами
// Татуировки сохраняются сразу при нанесении/удалении
// Загружаются при спавне персонажа

// Формат сохранения татуировок
// Используем ~ и ^ как разделители вместо ; и | чтобы избежать конфликтов с HTML
#define TATTOO_SAVE_VERS 1
#define TATTOO_SAVE_ZONE 2
#define TATTOO_SAVE_TEXT 3
#define TATTOO_SAVE_LENGTH 3

#define TATTOO_CURRENT_VERSION 1

// Разделители для формата сохранения (не должны встречаться в обычном тексте)
#define TATTOO_RECORD_SEPARATOR "~"
#define TATTOO_FIELD_SEPARATOR "^"

// Расширение preferences для хранения татуировок
/datum/preferences
	/// Включены ли постоянные татуировки
	var/persistent_tattoos = TRUE
	/// Сохранённые татуировки персонажа (формат: "VERSION|ZONE|TEXT;VERSION|ZONE|TEXT;...")
	var/tattoos_string = ""

// Загрузка настроек татуировок
// tattoopref загружается/сохраняется в modular_citadel/code/modules/client/preferences_savefile.dm
/datum/preferences/proc/load_tattoo_prefs(savefile/S)
	var/temp_persistent
	var/temp_tattoos
	var/list/temp_pending_removals
	S["persistent_tattoos"] >> temp_persistent
	S["tattoos_string"] >> temp_tattoos
	S["pending_tattoo_removals"] >> temp_pending_removals

	persistent_tattoos = sanitize_integer(temp_persistent, 0, 1, TRUE)
	tattoos_string = sanitize_text(temp_tattoos)
	pending_tattoo_removals = islist(temp_pending_removals) ? temp_pending_removals : list()

// Сохранение настроек татуировок
/datum/preferences/proc/save_tattoo_prefs(savefile/S)
	WRITE_FILE(S["persistent_tattoos"], persistent_tattoos)
	WRITE_FILE(S["tattoos_string"], tattoos_string)
	WRITE_FILE(S["pending_tattoo_removals"], pending_tattoo_removals)

// Экранирование разделителей в тексте татуировки для безопасного сохранения
/proc/escape_tattoo_text(text)
	// Заменяем разделители на безопасные последовательности
	text = replacetext(text, TATTOO_FIELD_SEPARATOR, "&#94;")   // ^ -> &#94;
	text = replacetext(text, TATTOO_RECORD_SEPARATOR, "&#126;") // ~ -> &#126;
	return text

// Восстановление разделителей из экранированного текста
/proc/unescape_tattoo_text(text)
	text = replacetext(text, "&#94;", TATTOO_FIELD_SEPARATOR)   // &#94; -> ^
	text = replacetext(text, "&#126;", TATTOO_RECORD_SEPARATOR) // &#126; -> ~
	return text

// Форматирование татуировок для сохранения
/mob/living/carbon/human/proc/format_tattoos()
	var/tattoos = ""
	for(var/obj/item/bodypart/BP as anything in bodyparts)
		// Обычные татуировки
		if(length(BP.tattoo_text))
			var/escaped_text = escape_tattoo_text(BP.tattoo_text)
			tattoos += "[TATTOO_CURRENT_VERSION][TATTOO_FIELD_SEPARATOR][BP.body_zone][TATTOO_FIELD_SEPARATOR][escaped_text][TATTOO_RECORD_SEPARATOR]"
		// Интимные татуировки (хранятся на груди)
		if(BP.body_zone == BODY_ZONE_CHEST)
			for(var/zone in GLOB.tattoo_zone_data)
				var/list/data = GLOB.tattoo_zone_data[zone]
				var/text = BP.vars[data[TATTOO_DATA_VAR]]
				if(length(text))
					tattoos += "[TATTOO_CURRENT_VERSION][TATTOO_FIELD_SEPARATOR][zone][TATTOO_FIELD_SEPARATOR][escape_tattoo_text(text)][TATTOO_RECORD_SEPARATOR]"
	return tattoos

// Загрузка одной татуировки из сохранённых данных
/mob/living/carbon/human/proc/load_tattoo(tattoo_line)
	var/list/tattoo_data = splittext(tattoo_line, TATTOO_FIELD_SEPARATOR)
	if(length(tattoo_data) != TATTOO_SAVE_LENGTH)
		return FALSE

	var/version = text2num(tattoo_data[TATTOO_SAVE_VERS])
	if(!version || version < TATTOO_CURRENT_VERSION)
		return FALSE

	var/zone = tattoo_data[TATTOO_SAVE_ZONE]
	var/text = unescape_tattoo_text(tattoo_data[TATTOO_SAVE_TEXT])

	// Определяем интимную зону через centralized data
	var/intimate_zone = zone_to_intimate_zone(zone)
	if(!intimate_zone && (zone in GLOB.tattoo_zone_data))
		intimate_zone = zone
	var/actual_zone = intimate_zone ? BODY_ZONE_CHEST : zone

	var/obj/item/bodypart/the_part = get_bodypart(actual_zone)
	if(!the_part)
		return FALSE

	set_tattoo_text_for_zone(the_part, intimate_zone, text)
	return TRUE

// Хук для загрузки татуировок при создании персонажа
/datum/preferences/proc/apply_tattoos_to_human(mob/living/carbon/human/H)
	if(!persistent_tattoos)
		return

	// Сначала применяем помеченные для удаления татуировки
	if(length(pending_tattoo_removals))
		apply_pending_tattoo_removals()
		// Сохраняем изменения
		save_character()

	// Загружаем текстовые татуировки
	if(tattoos_string)
		var/valid_tattoos = ""
		for(var/tattoo_line in splittext(tattoos_string, TATTOO_RECORD_SEPARATOR))
			if(!length(tattoo_line))
				continue
			if(H.load_tattoo(tattoo_line))
				valid_tattoos += "[tattoo_line][TATTOO_RECORD_SEPARATOR]"
		tattoos_string = valid_tattoos

// Сохранение татуировок (вызывается при нанесении/удалении татуировки)
/mob/living/carbon/human/proc/save_tattoos_now()
	if(!client?.prefs?.persistent_tattoos)
		return FALSE

	client.prefs.tattoos_string = format_tattoos()
	client.prefs.save_character()
	return TRUE
