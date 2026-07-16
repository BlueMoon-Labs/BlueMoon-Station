// Стоимость бита SSdirector: прод-раунд ловил 255-524мс на бит, потому что
// count_eligible_ghosts() пересобирал get_all_ghost_role_eligible() на КАЖДОЕ
// гост-действие (~24-50 раз за бит), а can_reenter_round() внутри делал линейный
// `src in GLOB.ghost_eligible_mobs` по списку, который вызывающий и так итерирует
// (O(гостов^2)). Фиксы: кэш списка на тик + быстрый путь без скана членства.

/// Кэш гост-элиджиблов живёт один тик: внутри бита (и одной перерисовки панели)
/// все прифлайты работают по одному и тому же списку.
/datum/unit_test/director_ghost_pool_cache/Run()
	var/list/first = SSdirector.get_eligible_ghosts_cached()
	TEST_ASSERT_NOTNULL(first, "get_eligible_ghosts_cached должен вернуть список")
	var/list/second = SSdirector.get_eligible_ghosts_cached()
	TEST_ASSERT(first == second, "в одном тике кэш обязан вернуть тот же самый инстанс списка")
	sleep(world.tick_lag)
	var/list/third = SSdirector.get_eligible_ghosts_cached()
	TEST_ASSERT(first != third, "в новом тике кэш обязан пересобраться заново")

/// Быстрый путь can_reenter_round: вызывающий, уже итерирующий GLOB.ghost_eligible_mobs,
/// ручается за членство и пропускает линейный скан. Для моба в списке оба пути эквивалентны.
/datum/unit_test/ghost_reenter_membership_fast_path/Run()
	var/mob/living/carbon/human/candidate = allocate(/mob/living/carbon/human)

	TEST_ASSERT(!candidate.can_reenter_round(TRUE), "моб вне ghost_eligible_mobs не проходит дефолтный путь")
	TEST_ASSERT(candidate.can_reenter_round(TRUE, skip_eligibility_scan = TRUE), "быстрый путь доверяет вызывающему и решает только по таймаутам")

	GLOB.ghost_eligible_mobs |= candidate
	var/default_path = candidate.can_reenter_round(TRUE)
	var/fast_path = candidate.can_reenter_round(TRUE, skip_eligibility_scan = TRUE)
	GLOB.ghost_eligible_mobs -= candidate
	TEST_ASSERT_EQUAL(default_path, fast_path, "для моба в списке быстрый путь обязан совпадать с дефолтным")
	TEST_ASSERT(default_path, "моб в списке и без таймаутов может вернуться в раунд")
