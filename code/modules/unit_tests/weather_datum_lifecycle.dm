/// Погода - датум на один шторм: SSweather заводит новый на каждый цикл (weather.dm:64-70,
/// буря раз в 7-12 минут; в переписи раунда 10060 - 3-6 /datum/weather/ash_storm за
/// 30-минутный интервал). Отработавший датум никто не qdel-ит, его подбирает рефкаунт - но
/// ровно до тех пор, пока последняя ссылка на него действительно снимается. Единственный
/// держатель боевой бури - очередь SSweather.processing, и снимает её только end().
/datum/unit_test/weather_end_releases_processing

/datum/unit_test/weather_end_releases_processing/Run()
	var/datum/weather/storm = new(list(run_loc_floor_bottom_left.z))
	storm.stage = MAIN_STAGE
	START_PROCESSING(SSweather, storm)
	TEST_ASSERT(storm in SSweather.processing, "Фикстура должна попасть в очередь SSweather")

	storm.end()
	TEST_ASSERT_EQUAL(storm.stage, END_STAGE, "end() обязан перевести бурю в финальную стадию")
	TEST_ASSERT(!(storm in SSweather.processing), "end() обязан снять бурю с обработки - иначе SSweather держит её до конца раунда")

/// Пепельная буря ведёт плейлист звуков в ГЛОБАЛЬНОМ списке (GLOB.ash_storm_sounds) с записью
/// на каждую область затронутого z. Фазы бури его не наращивают, а перекладывают: telegraph
/// кладёт тихий пресет, start меняет тихий на громкий, wind_down - громкий обратно на тихий,
/// end снимает тихий. Любая несведённая пара превратила бы штатный цикл SSweather в рост
/// глобального списка на каждую бурю до конца раунда, а вместе с ним - в удержание областей.
/datum/unit_test/weather_ash_storm_playlist_balance

/datum/unit_test/weather_ash_storm_playlist_balance/Run()
	var/area/probe_area = get_area(run_loc_floor_bottom_left)
	TEST_ASSERT_NOTNULL(probe_area, "Тестовой арене нужна область для записи в плейлист")

	// Ни одного сна до конца проверки: плейлист глобальный, и настоящая буря на лаваленде
	// сдвинула бы baseline, пока тест ждёт. Мир однопоточный - без снов он стоит.
	var/baseline = length(GLOB.ash_storm_sounds)
	// Фикстура без z-уровней: бухгалтерия плейлиста от них не зависит, а пустой список
	// отсекает рассылку сообщений и звуков живым мобам тестовой арены.
	var/datum/weather/ash_storm/storm = new(list())
	// telegraph() ради impacted_areas обходит все области мира - в тесте достаточно одной
	// области и той единственной записи в глобальный плейлист, которую он делает. Профиль
	// параллакса гасим: он про SSparallax, а проверяем мы бухгалтерию плейлиста.
	// perpetual - чтобы start() не заводил таймер wind_down на уже разобранную фикстуру.
	storm.parallax_profile = null
	storm.perpetual = TRUE
	storm.weak_sounds[probe_area] = /datum/looping_sound/weak_outside_ashstorm
	storm.strong_sounds[probe_area] = /datum/looping_sound/active_outside_ashstorm
	GLOB.ash_storm_sounds += storm.weak_sounds
	storm.stage = STARTUP_STAGE
	TEST_ASSERT_EQUAL(length(GLOB.ash_storm_sounds), baseline + 1, "Фикстура должна стоять в плейлисте одной записью")

	storm.start()
	TEST_ASSERT_EQUAL(length(GLOB.ash_storm_sounds), baseline + 1, "start() обязан ЗАМЕНИТЬ тихий пресет громким, а не добавить второй")
	TEST_ASSERT_EQUAL(GLOB.ash_storm_sounds[probe_area], /datum/looping_sound/active_outside_ashstorm, "После start() область должна звучать громким пресетом")

	storm.wind_down()
	TEST_ASSERT_EQUAL(length(GLOB.ash_storm_sounds), baseline + 1, "wind_down() обязан вернуть тихий пресет, не наращивая плейлист")
	TEST_ASSERT_EQUAL(GLOB.ash_storm_sounds[probe_area], /datum/looping_sound/weak_outside_ashstorm, "После wind_down() область должна звучать тихим пресетом")

	storm.end()
	TEST_ASSERT_EQUAL(length(GLOB.ash_storm_sounds), baseline, "end() обязан снять все записи бури из глобального плейлиста")
