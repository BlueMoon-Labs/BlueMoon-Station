// Содержит проки /datum/preferences которые связаны с компонентой jukebox
#define SAVE_TIMER addtimer(CALLBACK(src, PROC_REF(save_preferences)), 4 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)
#define POPUP_ID "tracks_export"
#define PLAYLIST_MAX_NAME_LEN 35
#define PLAYLIST_MAX_COUNT 40

/// Strict validation for imported track arrays. Associative/hybrid lists are never track arrays.
/proc/jukebox_track_list_is_valid(candidate, allow_empty = FALSE)
	if(!islist(candidate))
		return FALSE
	var/list/tracks = candidate
	if(is_assoc_list(tracks) || (!allow_empty && !length(tracks)))
		return FALSE
	for(var/song in tracks)
		if(!istext(song) || !length(song))
			return FALSE
	return TRUE

/// Strict validation for the object produced by exporting all playlists.
/proc/jukebox_playlists_are_valid(candidate)
	if(!islist(candidate))
		return FALSE
	var/list/imported_playlists = candidate
	if(!length(imported_playlists) || !is_assoc_list(imported_playlists) || length(imported_playlists) > PLAYLIST_MAX_COUNT)
		return FALSE
	for(var/playlist_name in imported_playlists)
		if(!istext(playlist_name) || !length(playlist_name) || length_char(playlist_name) > PLAYLIST_MAX_NAME_LEN)
			return FALSE
		if(strip_control_chars(playlist_name) != playlist_name)
			return FALSE
		if(!jukebox_track_list_is_valid(imported_playlists[playlist_name], allow_empty = TRUE))
			return FALSE
	return TRUE

/// Recovers a persisted preference into a JSON-safe sequential array.
/proc/sanitize_jukebox_track_list(candidate)
	if(!islist(candidate))
		return list()
	var/list/tracks = candidate
	if(is_assoc_list(tracks))
		return list()
	var/list/sanitized = list()
	for(var/song in tracks)
		if(istext(song) && length(song))
			sanitized |= song
	return sanitized

/// Recovers persisted playlists, enforcing the same shape and limits as the import UI.
/proc/sanitize_jukebox_playlists(candidate)
	if(!islist(candidate))
		return list()
	var/list/imported_playlists = candidate
	if(length(imported_playlists) && !is_assoc_list(imported_playlists))
		return list()
	var/list/sanitized = list()
	for(var/playlist_name in imported_playlists)
		if(length(sanitized) >= PLAYLIST_MAX_COUNT)
			break
		if(!istext(playlist_name))
			continue
		var/clean_name = copytext_char(strip_control_chars(playlist_name), 1, PLAYLIST_MAX_NAME_LEN + 1)
		if(!length(clean_name) || (clean_name in sanitized))
			continue
		sanitized[clean_name] = sanitize_jukebox_track_list(imported_playlists[playlist_name])
	return sanitized

////////////////////	ОБЩИЕ 	////////////////////
/datum/preferences/proc/tracks_move(list/track_list, track, up = TRUE)
	if(!LAZYLEN(track_list) || !track)
		return

	// Индексы в UI идут в обратном порядке
	var/to_index = up ? track_list.Find(next_list_item(track, track_list)) : track_list.Find(previous_list_item(track, track_list))
	var/track_index = track_list.Find(track)
	if(!to_index || !track_index)
		return

	if(to_index == track_list.len)
		track_list -= track
		track_list += track
	else if(to_index == 1)
		track_list -= track
		track_list.Insert(to_index, track)
	else
		track_list.Swap(track_index, to_index)

	return TRUE

/datum/preferences/proc/track_set_index(list/track_list, track, ui_index)
	if(!isnum(ui_index) || !LAZYLEN(track_list) || !track)
		return

	var/from = track_list.Find(track)
	if(!from)
		return

	ui_index = ui_index < 0 ? track_list.len : clamp(ui_index, 1, track_list.len)

	var/to_index = track_list.len - ui_index + 1 // Индексы в UI идут в обратном порядке

	return moveElementToPos(track_list, from, to_index)

/datum/preferences/proc/track_import_check(new_track_list, allow_empty = FALSE)
	return jukebox_track_list_is_valid(new_track_list, allow_empty)

//////////////////// ИЗБРАННОЕ ////////////////////
/datum/preferences/proc/favorite_tracks_toggle(track)
	if(!track)
		return
	if(track in favorite_tracks)
		favorite_tracks -= track
	else
		favorite_tracks += track

	SAVE_TIMER
	return TRUE

/datum/preferences/proc/favorite_tracks_move(track, up = TRUE)
	. = tracks_move(favorite_tracks, track, up)
	if(.)
		SAVE_TIMER

/datum/preferences/proc/favorite_track_set_index(ui_index, track)
	. = track_set_index(favorite_tracks, track, ui_index)
	if(.)
		SAVE_TIMER

/datum/preferences/proc/favorite_tracks_json()
	var/manage_mode = tgui_alert(parent, "Что требуется сделать с избранным?", "Менеджемент избранного", list("Экспорт", "Импорт"))
	if(!manage_mode)
		return
	if(manage_mode == "Импорт")
		var/import_json = tgui_input_text(parent, "Вставьте экспортированный список", "Import", multiline = TRUE)
		if(isnull(import_json))
			return
		var/decoded = safe_json_decode(import_json)
		if(!islist(decoded))
			to_chat(parent, span_warning("Список поврежден: ожидался JSON-массив названий треков."))
			return
		var/list/new_track_list = decoded
		if(!track_import_check(new_track_list))
			to_chat(parent, span_warning("Список поврежден: ожидался JSON-массив непустых названий треков."))
			return
		if(favorite_tracks.len)
			var/mode = tgui_alert(parent, "Желаете заменить список или добавить треки в конец,", "Режим добавления", list("Добавить", "Заменить"))
			if(!mode)
				return

			if(mode == "Заменить")
				var/confirm = tgui_alert(parent, "Вы уверены, что хотите полностью очистить избранное перед импортом?\nТреков в избранном: [favorite_tracks.len], треков в новом избранном: [new_track_list.len] (без учета дубликатов)", "Очистка избранного", list("Нет", "Да"))
				if(!confirm || confirm == "Нет")
					return

				favorite_tracks.Cut()
		favorite_tracks |= new_track_list
		save_preferences()
	else
		if(!favorite_tracks.len)
			to_chat(parent, span_warning("У вас нет треков в избранном"))
			return
		var/datum/browser/popup = new(parent.mob, POPUP_ID, "", 600, 600)
		popup.set_content(safe_json_encode(favorite_tracks))
		popup.open()

	return TRUE

//////////////////// ПЛЕЙЛИСТЫ ////////////////////
/datum/preferences/proc/playlists_new()
	var/new_playlist_name = tgui_input_text(parent, "Введите имя нового плейлиста", "Создание плейлиста", multiline = FALSE, max_length = PLAYLIST_MAX_NAME_LEN)
	if(!new_playlist_name)
		return
	if(new_playlist_name in playlists)
		tgui_alert_async(parent, "Такой плейлист уже существует!")
		return
	if(playlists.len >= PLAYLIST_MAX_COUNT)
		tgui_alert_async(parent, "Уже достигнут максимум в [PLAYLIST_MAX_COUNT] плейлистов!")
		return
	playlists[new_playlist_name] = list()

	SAVE_TIMER
	return new_playlist_name

/datum/preferences/proc/playlists_change(playlist_name, delete = FALSE)
	if(!playlist_name || !(playlist_name in playlists))
		return
	if(delete)
		var/confirm = tgui_alert(parent,"Вы уверены, что хотите удалить плейлист [playlist_name]?", "Удаление плейлиста", list("Нет", "Да"))
		if(confirm != "Да")
			return
		playlists -= playlist_name
	else
		var/new_playlist_name = tgui_input_text(parent, "Введите имя нового плейлиста", "Изменение плейлиста [playlist_name]", multiline = FALSE, max_length = PLAYLIST_MAX_NAME_LEN)
		if(!new_playlist_name)
			return
		if(new_playlist_name in playlists)
			tgui_alert_async(parent, "Такой плейлист уже существует!")
			return
		if(!change_assoc_key_preserve_index(playlists, new_playlist_name, playlist_name))
			return

	SAVE_TIMER
	return TRUE

/datum/preferences/proc/playlist_track_change(track, playlist_name, remove = FALSE)
	if(!track || !playlist_name)
		return
	var/list/current_playlist = playlists[playlist_name]
	if(!current_playlist)
		return
	if(remove)
		current_playlist -= track
	else
		current_playlist |= track

	SAVE_TIMER
	return TRUE

/datum/preferences/proc/playlist_tack_move(track, playlist_name, up = TRUE)
	if(!track || !playlist_name)
		return
	var/list/current_playlist = playlists[playlist_name]
	if(!current_playlist)
		return
	. = tracks_move(current_playlist, track, up)
	if(.)
		SAVE_TIMER

/datum/preferences/proc/playlist_track_set_index(ui_index, track, playlist_name)
	if(!playlist_name || !track)
		return
	var/list/current_playlist = playlists[playlist_name]
	if(!current_playlist)
		return
	. = track_set_index(current_playlist, track, ui_index)
	if(.)
		SAVE_TIMER

/datum/preferences/proc/playlists_json()
	var/manage_mode = tgui_alert(parent, "Что требуется сделать с плейлистами?", "Менеджемент плейлистов", list("Экспорт", "Импорт"))
	if(!manage_mode)
		return
	if(manage_mode == "Импорт")
		var/import_json = tgui_input_text(parent, "Вставьте экспортированный список", "Импорт", multiline = TRUE)
		if(isnull(import_json))
			return
		var/decoded = safe_json_decode(import_json)
		if(!islist(decoded))
			to_chat(parent, span_warning("Список поврежден: ожидался JSON-массив треков или объект плейлистов."))
			return
		var/list/new_track_list = decoded
		if(!length(new_track_list))
			return

		//Если вставили все плейлисты
		if(is_assoc_list(new_track_list))
			if(!jukebox_playlists_are_valid(new_track_list))
				to_chat(parent, span_warning("Список поврежден: проверьте названия плейлистов и массивы треков."))
				return
			var/list/imported_playlists = sanitize_jukebox_playlists(new_track_list)
			if(playlists.len)
				var/confirm = tgui_alert(parent, "Будут заменены ВСЕ плейлисты. Продолжить?", "Замена всех плейлистов", list("Нет", "Да"))
				if(confirm != "Да")
					return
			playlists.Cut()

			for(var/playlist_name in imported_playlists)
				playlists[playlist_name] = imported_playlists[playlist_name]
			save_preferences()
			return TRUE

		if(!track_import_check(new_track_list))
			to_chat(parent, span_warning("Список поврежден: ожидался JSON-массив непустых названий треков."))
			return

		var/current_playlist_name
		var/list/track_list
		var/choise
		if(playlists.len)
			choise = tgui_alert(parent, "Создать новый плейлист или хотите добавить треки в существующий?", "Импорт плейлистов", list("Новый", "Существующий"))
			if(!choise)
				return
			if(choise == "Существующий")
				current_playlist_name = tgui_input_list(parent, "В какой плейлист добавить треки?", "Плейлисты", playlists)
				if(!(current_playlist_name in playlists))
					return
				track_list = playlists[current_playlist_name]
		if(!playlists.len || choise == "Новый")
			current_playlist_name = playlists_new()
			if(!current_playlist_name)
				return
			track_list = playlists[current_playlist_name]

		track_list |= new_track_list
		save_preferences()

	else if(manage_mode == "Экспорт")
		if(!LAZYLEN(playlists))
			to_chat(parent, span_warning("У вас нет плейлистов"))
			return
		var/list/to_export = playlists
		var/choise = tgui_alert(parent, "Хотите экспортировать все плейлисты или конкретный?", "Экспорт плейлистов", list("Все", "Конкретный"))
		if(!choise)
			return
		if(choise == "Конкретный")
			var/current_playlist_name = tgui_input_list(parent, "Выберите плейлист к экспорту", "Экспорт плейлистов", playlists)
			if(!(current_playlist_name in playlists))
				return
			to_export = playlists[current_playlist_name]
			if(!LAZYLEN(to_export))
				to_chat(parent, span_warning("Этот плейлист пуст!"))
				return
		var/datum/browser/popup = new(parent.mob, POPUP_ID, "", 600, 600)
		popup.set_content(safe_json_encode(to_export))
		popup.open()

	return TRUE

#undef SAVE_TIMER
#undef POPUP_ID
#undef PLAYLIST_MAX_NAME_LEN
#undef PLAYLIST_MAX_COUNT
