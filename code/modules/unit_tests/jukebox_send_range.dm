/**
 * Ресурс трека шлётся всем, кому он СЛЫШЕН, а не только тем, кто стоит в зоне джукбокса или
 * в семи тайлах от него.
 *
 * Досылка по факту входа в радиус слышимости появилась, чтобы не раздавать многомегабайтные
 * личные треки всему серверу. Но радиус взяли с потолка: hearers(7) либо та же зона. Позиционное
 * затухание BYOND несёт звук куда дальше - при штатной громкости тайлов на пятнадцать, у
 * взломанной колонки на весь сектор. Слушатель в соседней комнате слышал предыдущий трек
 * приглушённым, а следующий не получал вовсе: ресурс до него не доходил, пока он не подойдёт.
 *
 * Порог - доля громкости JUKEBOX_AUDIBLE_GAIN: громкость на расстоянии d за пределами falloff
 * равна falloff / d, где d считается в единицах звука (тайл = SOUND_DEFAULT_DISTANCE_MULTIPLIER).
 */
/datum/unit_test/jukebox_send_range_follows_falloff
	requires_full_map = FALSE

/datum/unit_test/jukebox_send_range_follows_falloff/Run()
	// Штатная громкость 70 -> falloff 2. Семь тайлов - старый радиус, обязан остаться слышимым.
	var/default_falloff = 70 / 35
	TEST_ASSERT(jukebox_audible_at(default_falloff, 7 * SOUND_DEFAULT_DISTANCE_MULTIPLIER, 5, 0), \
		"семь тайлов при штатной громкости обязаны быть слышны - это старый радиус досылки")
	// Соседняя комната: тайлов двенадцать. Громкость 2 / 30.4 = 6.6% - слышно.
	TEST_ASSERT(jukebox_audible_at(default_falloff, 12 * SOUND_DEFAULT_DISTANCE_MULTIPLIER, 5, 0), \
		"двенадцать тайлов при штатной громкости слышны, ресурс обязан уйти в соседнюю комнату")
	// Тридцать тайлов: 2 / 75 = 2.7% - неслышно, слать незачем.
	TEST_ASSERT(!jukebox_audible_at(default_falloff, 30 * SOUND_DEFAULT_DISTANCE_MULTIPLIER, 5, 0), \
		"тридцать тайлов при штатной громкости неслышны, ресурс не должен уходить")
	// Выключенная громкость: falloff 0, слать некому.
	TEST_ASSERT(!jukebox_audible_at(0, 0, 5, 0), \
		"при нулевой громкости трек не слышен даже вплотную")
	// Взломанная колонка на максимуме: громкость 1000 -> falloff 28.6, слышно через весь сектор.
	var/emagged_falloff = 1000 / 35
	TEST_ASSERT(jukebox_audible_at(emagged_falloff, 200 * SOUND_DEFAULT_DISTANCE_MULTIPLIER, 5, 0), \
		"взломанная колонка на максимуме обязана быть слышна за двести тайлов - в этом её смысл")

	// Живой расчёт по турфам: та же формула координат, что кладётся в /sound.
	var/turf/source = run_loc_floor_bottom_left
	var/turf/near = locate(source.x + 2, source.y + 2, source.z)
	TEST_ASSERT_NOTNULL(near, "предпосылка: резервация даёт турф в двух клетках от угла")
	var/list/audible_zlevels = list(source.z)
	TEST_ASSERT(SSjukeboxes.jukebox_within_earshot(source, near, default_falloff, audible_zlevels), \
		"слушатель в двух клетках на том же z обязан попадать в радиус досылки")
	TEST_ASSERT(!SSjukeboxes.jukebox_within_earshot(source, near, default_falloff, list()), \
		"слушатель на недостижимом z не должен получать ресурс, как бы близко он ни стоял")
