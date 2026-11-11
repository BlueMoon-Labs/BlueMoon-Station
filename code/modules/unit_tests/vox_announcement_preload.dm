/// Объявление ИИ: звук откладывается на предзагрузку, слова уходят в проигрыш все и по порядку.
/datum/unit_test/vox_announcement_preload

/datum/unit_test/vox_announcement_preload/Run()
#ifdef AI_VOX
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/ai = allocate(/mob/living/silicon/ai, run_loc_floor_bottom_left, null, donor)
	var/timer_id = ai.announcement("Female", "Alert security alert hello")
	TEST_ASSERT_NOTNULL(timer_id, "Объявление не запланировало проигрыш")
	TEST_ASSERT(timeleft(timer_id) > 0, "Проигрыш объявления не ждёт предзагрузки слов")
	var/datum/timedevent/playback = SStimer.timer_id_dict[timer_id]
	var/list/arguments = playback.callBack.arguments
	TEST_ASSERT_EQUAL(jointext(arguments[1], " "), "Alert security alert hello", "Проигрыш получил не те слова")
	TEST_ASSERT_EQUAL(arguments[2], ai.z, "Проигрыш идёт не на z ИИ")
	TEST_ASSERT_EQUAL(arguments[3], "Female", "Проигрыш идёт не тем голосом")
	deltimer(timer_id)
	TEST_ASSERT_NULL(ai.announcement("Female", "security"), "Кулдаун объявления не сработал")
#endif

#define VOX_TEST_MIN_OGG_BYTES 1024

/// Размер слова VOX - настоящий размер файла, а не обрывок до первого нулевого байта.
/datum/unit_test/vox_file_bytes

/datum/unit_test/vox_file_bytes/Run()
#ifdef AI_VOX
	var/file = GLOB.vox_types["Female"]["alert"]
	var/expected = length(file("[file]"))
	TEST_ASSERT(expected > VOX_TEST_MIN_OGG_BYTES, "Слово alert весит [expected] Б - меньше любого ogg")
	TEST_ASSERT_EQUAL(vox_file_bytes(file), expected, "Размер слова не совпал с файлом")
	TEST_ASSERT_EQUAL(vox_file_bytes(file), expected, "Повторный промер дал другое число")
#endif

#undef VOX_TEST_MIN_OGG_BYTES
