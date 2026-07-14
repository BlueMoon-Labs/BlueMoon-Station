/// Exported playlist objects must never be accepted where a sequential track array is expected.
/datum/unit_test/jukebox_import_shape_validation/Run()
	var/list/exported_playlists = list(
		"Imported playlist" = list("Valid Track")
	)
	TEST_ASSERT(is_assoc_list(exported_playlists), "Тестовые плейлисты не являются ассоциативным списком")
	TEST_ASSERT(!jukebox_track_list_is_valid(exported_playlists), "Объект плейлистов принят как массив избранных треков")
	TEST_ASSERT(!length(sanitize_jukebox_track_list(exported_playlists)), "Восстановление избранного сохранило ассоциативный список")

	var/list/valid_tracks = list("First Track", "Second Track")
	TEST_ASSERT(jukebox_track_list_is_valid(valid_tracks), "Корректный массив треков отклонён")

/// Persisted malformed nested values are recovered into JSON-safe arrays before opening TGUI.
/datum/unit_test/jukebox_saved_preferences_recovery/Run()
	var/list/saved_playlists = list(
		"Valid" = list("First Track", "First Track", "Second Track"),
		"Broken" = "not an array"
	)
	var/list/recovered = sanitize_jukebox_playlists(saved_playlists)
	TEST_ASSERT_EQUAL(length(recovered["Valid"]), 2, "Восстановление не удалило дубликаты треков")
	TEST_ASSERT(islist(recovered["Broken"]), "Повреждённый плейлист не преобразован в безопасный массив")
	TEST_ASSERT(!length(recovered["Broken"]), "Повреждённый плейлист сохранил скалярное значение")
	TEST_ASSERT(!jukebox_playlists_are_valid(saved_playlists), "Импорт принял плейлист со скалярным значением")
