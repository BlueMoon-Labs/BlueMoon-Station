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

	// Отметку реального времени тут НЕ подставляем: REALTIMEOFDAY - настенные часы, между
	// подготовкой аргумента и замером внутри прока они успевают уйти вперёд, и ассерт на
	// равенство падал бы через раз. Реальный отсчёт проверяет чистая функция ниже, где
	// "сейчас" передаётся явно; здесь достаточно запасной ветки по world.time - оно внутри
	// одного тика не двигается, а тест не спит.
	SSjukeboxes.set_catchup_offset(song, null, world.time - 30 SECONDS)
	TEST_ASSERT_EQUAL(song.offset, 30, "Опоздавший слушатель подхватывает трек не с той секунды, что остальные")

	SSjukeboxes.clear_catchup_offset(song)
	TEST_ASSERT_NULL(song.offset, "После досылки на общем датуме осталось смещение: каждый SOUND_UPDATE будет перематывать канал в начало")

/**
 * Подхват считается по РЕАЛЬНОМУ времени, а не по world.time.
 *
 * world.time - игровое время: под дилатацией оно отстаёт от настенного, и в раунде 10137
 * сервер шёл на 67%. За десять реальных минут трека world.time насчитывал около шести, и
 * опоздавший слушатель стартовал на шестой минуте, пока у всех остальных играла десятая.
 * Чем дольше играет трек, тем больше расхождение.
 *
 * Чистой функцией и с явным "сейчас": иначе дилатацию не воспроизвести, не поспав.
 */
/datum/unit_test/jukebox_catchup_uses_real_time
	requires_full_map = FALSE

/datum/unit_test/jukebox_catchup_uses_real_time/Run()
	// Трек играет 10 реальных минут, сервер всё это время шёл на 60%.
	var/real_start = 100000
	var/real_now = real_start + 10 MINUTES
	var/world_start = 50000
	var/world_now = world_start + 6 MINUTES

	TEST_ASSERT_EQUAL(jukebox_catchup_seconds(real_start, world_start, real_now, world_now), 600, \
		"подхват обязан считаться по настенным часам: под дилатацией world.time отстаёт от них")

	// Отметки реального времени нет (трек заведён до появления поля) - падаем на world.time.
	TEST_ASSERT_EQUAL(jukebox_catchup_seconds(null, world_start, real_now, world_now), 360, \
		"без отметки реального времени обязан работать запасной отсчёт по world.time")

	// Обеих отметок нет: подхватывать не от чего, играем с начала.
	TEST_ASSERT_EQUAL(jukebox_catchup_seconds(null, null, real_now, world_now), 0, \
		"без единой отметки старта смещения быть не должно")

	// Отметка "в будущем" (снята до первого обновления счётчика суток). Отрицательное
	// смещение /sound понимает как перемотку в начало, поэтому режем снизу нулём.
	TEST_ASSERT_EQUAL(jukebox_catchup_seconds(real_now + 5 MINUTES, world_start, real_now, world_now), 0, \
		"отметка старта в будущем обязана давать нулевое смещение, а не отрицательное")

/**
 * Ограничение зоны берётся по ТЕКУЩЕЙ зоне джукбокса, а не по той, где включили трек.
 *
 * Значение снималось один раз в addjukebox() и после этого решало судьбу каждого нового
 * слушателя. Переносную шкатулку включают в номере отеля и выносят в руках: застывшее
 * ограничение продолжало требовать той самой комнаты, в которой шкатулки уже нет, и первая
 * досылка любому новому слушателю закрывалась навсегда - трек слышали только те, кому его
 * успели выслать в комнате.
 */
/datum/unit_test/jukebox_area_limit_follows_jukebox
	requires_full_map = FALSE
	var/area/touched_area
	var/saved_restrain = FALSE

/datum/unit_test/jukebox_area_limit_follows_jukebox/Destroy()
	// Уборка в Destroy(): провалившийся TEST_ASSERT выходит из Run() немедленно, а зона
	// тестового турфа общая на весь прогон - чужой флаг протёк бы в соседние тесты.
	if(touched_area)
		touched_area.jukebox_restrain = saved_restrain
	return ..()

/datum/unit_test/jukebox_area_limit_follows_jukebox/Run()
	var/area/test_area = get_area(run_loc_floor_bottom_left)
	TEST_ASSERT_NOTNULL(test_area, "предпосылка: у тестового турфа обязана быть зона")
	touched_area = test_area
	saved_restrain = test_area.jukebox_restrain

	test_area.jukebox_restrain = FALSE
	var/unrestrained = SSjukeboxes.get_jukebox_area_limit(test_area)

	test_area.jukebox_restrain = TRUE
	var/restrained = SSjukeboxes.get_jukebox_area_limit(test_area)

	test_area.jukebox_restrain = saved_restrain
	touched_area = null

	// Зоны нет вовсе (джукбокс в нигде) - ограничения тоже нет, иначе первая досылка
	// закрылась бы для всех.
	var/no_area = SSjukeboxes.get_jukebox_area_limit(null)

	TEST_ASSERT_NULL(unrestrained, "зона без jukebox_restrain не должна давать ограничения")
	TEST_ASSERT_EQUAL(restrained, test_area, "зона с jukebox_restrain обязана запирать музыку в себе")
	TEST_ASSERT_NULL(no_area, "джукбокс без зоны не должен получать ограничения")
