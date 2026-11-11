#define ALLIANCE_VOX_WORDS 46
#define TETRIS_MUSIC_TRACKS 6

/// Файл звука - настоящий Ogg: клиент без кэша качает его при первом проигрыше.
/proc/unit_test_sound_is_ogg(file)
	var/path = "[file]"
	if(!fexists(path) || copytext(path, -4) != ".ogg")
		return FALSE
	return copytext(file2text(path), 1, 5) == "OggS"

/// Слова VOX всех голосов на месте и в ogg, у Alliance ни одно слово не потерялось.
/datum/unit_test/vox_words_are_ogg

/datum/unit_test/vox_words_are_ogg/Run()
#ifdef AI_VOX
	for(var/voice in GLOB.vox_types)
		var/list/words = GLOB.vox_types[voice]
		for(var/word in words)
			var/path = "[words[word]]"
			TEST_ASSERT(fexists(path), "Слово [word] голоса [voice] ссылается на несуществующий файл [path]")
			TEST_ASSERT_EQUAL(copytext(path, -4), ".ogg", "Слово [word] голоса [voice] не в ogg: [path]")
	var/list/alliance = GLOB.vox_types["Alliance"]
	TEST_ASSERT_EQUAL(length(alliance), ALLIANCE_VOX_WORDS, "У голоса Alliance не то число слов")
	for(var/word in alliance)
		TEST_ASSERT(unit_test_sound_is_ogg(alliance[word]), "Слово Alliance [word] - не Ogg внутри: [alliance[word]]")
#endif

/// Саундтрек тетриса - разные мелодии в настоящем ogg, без копий одного трека.
/datum/unit_test/tetris_music_tracks_unique_ogg

/datum/unit_test/tetris_music_tracks_unique_ogg/Run()
	var/obj/machinery/computer/arcade/tetris/arcade = allocate(/obj/machinery/computer/arcade/tetris)
	var/list/tracks = arcade.music_tracks
	TEST_ASSERT_EQUAL(length(tracks), TETRIS_MUSIC_TRACKS, "Не то число треков тетриса")
	var/list/hashes = list()
	for(var/track in tracks)
		TEST_ASSERT(unit_test_sound_is_ogg(track), "Трек тетриса [track] - не Ogg")
		var/hash = md5(file("[track]"))
		TEST_ASSERT(!(hash in hashes), "Трек [track] - байтовая копия [hashes[hash]]")
		hashes[hash] = track

#undef ALLIANCE_VOX_WORDS
#undef TETRIS_MUSIC_TRACKS
