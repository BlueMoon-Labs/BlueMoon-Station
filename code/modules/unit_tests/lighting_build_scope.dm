/**
 * Один и тот же z-уровень поднимается дважды, и это ломало две вещи.
 *
 * Два моба, шагнувшие на неосвещённый z в одном тике, оба проходят
 * should_ondemand_init_zlevel() и ставят по INVOKE_ASYNC. Первый выставляет
 * lighting_initialized, второй упирается в self-heal гард zlevel_has_deferred_lighting(),
 * который не отличает "прошлый заход оборвался" от "прямо сейчас идёт", - и проходит следом.
 * В логах прода это пары строк "On-demand init for z-level 7" подряд (раунды 10119, 10121).
 *
 * Сам повторный проход не создаёт НИ ОДНОГО объекта (фаза 0 пропускает турфы с
 * T.lighting_object) и памяти не стоит: в 10121 повторный подъём z6 честно показал 0 МБ.
 * Гнаться за его тактами лизой занятости оказалось дороже, чем они стоят: единственные
 * вызовы, которым нужен синхронный результат, - резервация в /datum/unit_test/New()
 * (unit_test.dm:91) и стыковка шаттла, и мгновенный выход по занятой лизе оставлял бы их
 * без света. Осталось починить то, что реально вредило:
 *
 * 1. init_in_progress был булевым на весь мир. Проход, закончивший первым, гасил состояние
 *    тому, кто ещё крутил свои 65 тыс. турфов, - а на этот флаг смотрят снос света
 *    (lighting.dm, abort_reason "другой проход строит свет") и батчинг старлайта в
 *    lighting_object/New(). Теперь это счётчик проходов.
 * 2. Прибор цены света отчитывался и за пустой проход. Его окно замера перекрывается с
 *    окном соседнего живого прохода, поэтому одна и та же работа записывалась дважды:
 *    в 10121 на z7 вышли +83.9 и +109 МБ за один подъём, и обе цифры уехали в счётчик,
 *    из которого прибор подключения вычитает фон.
 */

/// Счётчик держится, пока не закрылся ПОСЛЕДНИЙ проход.
/datum/unit_test/lighting_build_scope_survives_concurrent_pass/Run()
	var/restore = SSlighting.init_in_progress
	SSlighting.init_in_progress = 0

	SSlighting.begin_lighting_build()
	SSlighting.begin_lighting_build()
	SSlighting.end_lighting_build()
	var/still_building = SSlighting.init_in_progress
	SSlighting.end_lighting_build()
	var/done_building = !SSlighting.init_in_progress

	SSlighting.init_in_progress = restore

	TEST_ASSERT(still_building, "Пока идёт второй проход, состояние постройки обязано держаться")
	TEST_ASSERT(done_building, "После закрытия обоих проходов состояние обязано сняться")

/// Лишнее закрытие не загоняет счётчик в минус: отрицательный счётчик читался бы как
/// "постройка идёт всегда" и запер бы снос света до конца раунда.
/datum/unit_test/lighting_build_scope_never_goes_negative/Run()
	var/restore = SSlighting.init_in_progress
	SSlighting.init_in_progress = 0

	SSlighting.end_lighting_build()
	SSlighting.end_lighting_build()
	var/floored = SSlighting.init_in_progress >= 0
	var/reads_as_idle = !SSlighting.init_in_progress

	SSlighting.init_in_progress = restore

	TEST_ASSERT(floored, "Счётчик проходов не должен уходить в минус")
	TEST_ASSERT(reads_as_idle, "Пустой счётчик обязан читаться как \"постройка не идёт\"")

/// Пустой проход о себе не отчитывается: его окно замера перекрывается с окном соседнего
/// живого прохода, и одна и та же работа записалась бы дважды.
/datum/unit_test/lighting_cost_report_skips_empty_pass/Run()
	var/list/fake_memory = list("vsz" = 1000, "rss" = 500)

	TEST_ASSERT(!should_report_zlevel_lighting_cost(0, fake_memory), "Проход, не создавший ни одного объекта, отчитываться не должен")
	TEST_ASSERT(should_report_zlevel_lighting_cost(65025, fake_memory), "Проход, построивший уровень, отчитаться обязан")

/// Без замера памяти (Windows, /proc не читается) отчитываться нечем даже настоящему
/// проходу - иначе в счётчик фоновой работы уедет мусор.
/datum/unit_test/lighting_cost_report_needs_memory_probe/Run()
	TEST_ASSERT(!should_report_zlevel_lighting_cost(65025, null), "Без замера памяти отчёта быть не может")

/// Счётчик фоновой работы монотонный: прибор подключения вычитает его ПРИРОСТ за этап, и
/// уход счётчика вниз выставил бы игроку чужие мегабайты вместо того, чтобы их снять.
/datum/unit_test/lighting_cost_counter_is_monotonic/Run()
	var/restore = GLOB.memory_attributed_elsewhere_mb
	GLOB.memory_attributed_elsewhere_mb = 100

	log_zlevel_lighting_cost(1, "тестовый уровень", null, 0)
	log_zlevel_lighting_cost(1, "тестовый уровень", list("vsz" = 1000, "rss" = 500), 0)
	var/after = GLOB.memory_attributed_elsewhere_mb

	GLOB.memory_attributed_elsewhere_mb = restore

	TEST_ASSERT_EQUAL(after, 100, "Пустые проходы не должны двигать счётчик фоновой работы")

/**
 * Проход по уже поднятому уровню объектов почти не создаёт - он только флашит
 * запаркованные атомы. Раунд 10121 дал одиннадцать строк "On-demand init" при двух
 * реальных постройках: обе формулировки читались одинаково, и разбор ушёл в ложную улику.
 */
/datum/unit_test/lighting_pass_line_names_self_heal/Run()
	var/real_build = zlevel_lighting_pass_line(7, "Lavaland", self_heal = FALSE)
	var/flush_pass = zlevel_lighting_pass_line(1, "CentCom", self_heal = TRUE)

	TEST_ASSERT(findtext(real_build, "On-demand init"), "Настоящая постройка обязана остаться прежней строкой: [real_build]")
	TEST_ASSERT(!findtext(flush_pass, "On-demand init"), "Флаш отложенных атомов не должен называться постройкой уровня: [flush_pass]")
	TEST_ASSERT(findtext(flush_pass, "Self-heal"), "Флаш обязан называть себя своим именем: [flush_pass]")
