/// Опоздавшему слушателю трек досылается с той же секунды, что слышат остальные, а смещение
/// после досылки снимается с общего датума звука.
///
/// У /sound offset по умолчанию null, и это НЕ то же самое, что ноль: null означает "позицию не
/// трогать", ноль - "перемотать в начало". Датум звука один на всех слушателей и живёт весь трек,
/// поэтому оставленный после досылки ноль уезжает дальше с каждым SOUND_UPDATE, а их fire() шлёт
/// раз в полсекунды каждому, кто слышит.
/datum/unit_test/jukebox_catchup_offset_clears_to_null

/datum/unit_test/jukebox_catchup_offset_clears_to_null/Run()
	var/sound/song = sound('sound/machines/ping.ogg')
	TEST_ASSERT_NULL(song.offset, "Свежий /sound пришёл со смещением - инвариант BYOND изменился, вся проверка ниже держится на нём")

	SSjukeboxes.set_catchup_offset(song, world.time - 30 SECONDS)
	TEST_ASSERT_EQUAL(song.offset, 30, "Опоздавший слушатель подхватывает трек не с той секунды, что остальные")

	SSjukeboxes.clear_catchup_offset(song)
	TEST_ASSERT_NULL(song.offset, "После досылки на общем датуме осталось смещение: каждый SOUND_UPDATE будет перематывать канал в начало")
