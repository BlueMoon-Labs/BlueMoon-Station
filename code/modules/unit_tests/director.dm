/// Проверяет, что классификация экипажа отсекает гост-роли и мёртвых.
/datum/unit_test/director_effective_crew

/datum/unit_test/director_effective_crew/Run()
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human)
	crew.mind_initialize()
	crew.mind.assigned_role = "Assistant"
	TEST_ASSERT(is_effective_crew_mob(crew), "Ассистент с mind должен считаться экипажем")

	crew.mind.assigned_role = "Security Officer"
	TEST_ASSERT_EQUAL(director_dept_of_job(crew.mind.assigned_role), DIRECTOR_DEPT_SECURITY, "Офицер должен попадать в отдел СБ")

	var/mob/living/carbon/human/ghost_role = allocate(/mob/living/carbon/human)
	ghost_role.mind_initialize()
	ghost_role.mind.assigned_role = "Ash Walker"
	TEST_ASSERT(!is_effective_crew_mob(ghost_role), "Гост-роль не должна считаться экипажем")

	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human)
	corpse.mind_initialize()
	corpse.mind.assigned_role = "Assistant"
	corpse.death()
	TEST_ASSERT(!is_effective_crew_mob(corpse), "Мёртвый не должен считаться экипажем")

	var/mob/living/carbon/human/no_mind = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!is_effective_crew_mob(no_mind), "Моб без mind не должен считаться экипажем")

/// Тестовое действие: без переопределений can_fire ведёт себя по базовому контракту.
/datum/director_action/test_stub
	severity = DIRECTOR_SEVERITY_MINOR
	weight = 10

/datum/director_action/test_stub/execute_action()
	return TRUE

/datum/unit_test/director_action_gates

/datum/unit_test/director_action_gates/Run()
	var/datum/director_signals/signals = new
	signals.effective_crew = 30
	signals.staffing = list(DIRECTOR_DEPT_SECURITY = 2, DIRECTOR_DEPT_ENGINEERING = 0,
		DIRECTOR_DEPT_MEDICAL = 0, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 0)

	var/datum/director_action/test_stub/action = new
	TEST_ASSERT(action.can_fire(signals), "Действие без ограничений должно проходить")

	action.enabled = FALSE
	TEST_ASSERT(!action.can_fire(signals), "enabled = FALSE должен блокировать")
	action.enabled = TRUE

	action.admin_only = TRUE
	TEST_ASSERT(!action.can_fire(signals), "admin_only должен блокировать естественный запуск")
	action.admin_only = FALSE

	action.min_players = 50
	TEST_ASSERT(!action.can_fire(signals), "min_players выше экипажа должен блокировать")
	action.min_players = 0

	action.max_occurrences = 1
	action.occurrences = 1
	TEST_ASSERT(!action.can_fire(signals), "Достигнутый max_occurrences должен блокировать")
	action.occurrences = 0

	action.min_staffing = list(DIRECTOR_DEPT_ENGINEERING = 1)
	TEST_ASSERT(!action.can_fire(signals), "Пустой инженерный отдел должен блокировать min_staffing")
	action.min_staffing = list(DIRECTOR_DEPT_SECURITY = 1)
	TEST_ASSERT(action.can_fire(signals), "Заполненный отдел должен проходить min_staffing")

/// Проверяет, что round_event_control реально наследует director_action и несёт правильный kind.
/datum/unit_test/director_event_control_contract

/datum/unit_test/director_event_control_contract/Run()
	TEST_ASSERT(ispath(/datum/round_event_control, /datum/director_action), "round_event_control должен наследовать director_action")
	for(var/datum/round_event_control/control_path as anything in typesof(/datum/round_event_control))
		if(!initial(control_path.typepath))
			continue
		TEST_ASSERT_EQUAL(initial(control_path.director_kind), DIRECTOR_KIND_EVENT, "[control_path] должен иметь kind = EVENT")

/// Проверяет, что dynamic_ruleset реально наследует director_action и несёт правильный severity.
/datum/unit_test/director_ruleset_contract

/datum/unit_test/director_ruleset_contract/Run()
	TEST_ASSERT(ispath(/datum/dynamic_ruleset, /datum/director_action), "dynamic_ruleset должен наследовать director_action")
	for(var/datum/dynamic_ruleset/ruleset_path as anything in subtypesof(/datum/dynamic_ruleset))
		if(!initial(ruleset_path.name))
			continue
		var/ruleset_severity = initial(ruleset_path.severity)
		TEST_ASSERT(DIRECTOR_IS_ANTAG_POOL(ruleset_severity), "[ruleset_path] должен иметь severity ANTAG или GHOST, а не [ruleset_severity]")

/datum/unit_test/director_profiles

/datum/unit_test/director_profiles/Run()
	var/list/needed = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT, ROUNDTYPE_EXTENDED)
	for(var/round_type in needed)
		var/datum/director_profile/profile = director_profile_for(round_type)
		TEST_ASSERT_NOTNULL(profile, "Нет профиля для [round_type]")
		TEST_ASSERT_EQUAL(profile.round_type, round_type, "director_profile_for вернул чужой профиль для [round_type]")
		for(var/severity in list(DIRECTOR_SEVERITY_FLAVOR, DIRECTOR_SEVERITY_MINOR, DIRECTOR_SEVERITY_MODERATE, DIRECTOR_SEVERITY_MAJOR, DIRECTOR_SEVERITY_ANTAG, DIRECTOR_SEVERITY_GHOST))
			TEST_ASSERT(!isnull(profile.pool_shares[severity]), "[round_type]: нет доли для [severity]")

	TEST_ASSERT_EQUAL(piecewise_eval(list(list(0, 0), list(10, 1)), 5), 0.5, "Интерполяция середины")
	TEST_ASSERT_EQUAL(piecewise_eval(list(list(0, 0), list(10, 1)), -5), 0, "Кламп слева")
	TEST_ASSERT_EQUAL(piecewise_eval(list(list(0, 0), list(10, 1)), 20), 1, "Кламп справа")

/// Проверяет фильтры темпа в filter_candidates(): потолок intensity, бюджет, эвакуация, spacing ступеней.
/datum/unit_test/director_beat_logic

/datum/unit_test/director_beat_logic/Run()
	// Тест мутирует живой SSdirector (profile/budgets/actions/spacing). capture/restore из симулятора
	// возвращает боевое состояние даже если TEST_ASSERT упадёт (try/catch + restore + re-throw) -
	// иначе упавший ассерт стрендил бы пустой каталог в следующий по алфавиту тест.
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.actions = list()
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		// Прогоняем последние запуски далеко в прошлое, а не полагаемся на world.time (в юнит-тестах
		// сервер только что стартовал и world.time может быть меньше severity_spacing любой ступени).
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MODERATE = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MODERATE] - 1,
			DIRECTOR_SEVERITY_MAJOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MAJOR] - 1,
		)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		// потолок intensity закрывает всё кроме FLAVOR
		signals.active_intensity = profile.intensity_cap
		var/datum/director_action/test_stub/hostile = new
		hostile.severity = DIRECTOR_SEVERITY_MODERATE
		SSdirector.actions = list(hostile)
		var/list/candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT_EQUAL(length(candidates), 0, "При полном потолке intensity враждебное действие не должно быть кандидатом")

		// при свободном потолке - кандидат есть
		signals.active_intensity = 0
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT_EQUAL(length(candidates), 1, "При свободном потолке действие должно быть кандидатом")

		// кошелёк ступени гейтит (MODERATE-кошелёк не покрывает cost)
		hostile.cost = 500
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT_EQUAL(length(candidates), 0, "Нехватка кошелька ступени должна отсекать")
		hostile.cost = 0

		// эвакуация закрывает MAJOR/ANTAG
		hostile.severity = DIRECTOR_SEVERITY_MAJOR
		signals.evac_state = DIRECTOR_EVAC_CALLED
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT_EQUAL(length(candidates), 0, "После вызова эвакуации MAJOR должен быть закрыт")
		signals.evac_state = DIRECTOR_EVAC_NONE

		// spacing: сразу после запуска той же ступени - блок
		hostile.severity = DIRECTOR_SEVERITY_MODERATE
		SSdirector.last_fired_at[DIRECTOR_SEVERITY_MODERATE] = world.time
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT_EQUAL(length(candidates), 0, "Пауза ступени должна отсекать")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Латеджойн-рулсет для теста изоляции пула битов.
/// weight = 0 на типе, чтобы init_rulesets живого раунда его не подобрал; тест ставит вес сам.
/datum/dynamic_ruleset/latejoin/test_pool_isolation
	name = "Test Latejoin Pool Isolation"
	weight = 0
	cost = 0
	requirements = list(0,0,0,0,0,0,0,0,0,0)
	required_round_type = null // не зависеть от GLOB.round_type тестового раунда

/// Midround-контроль с теми же параметрами: обязан проходить фильтры бита.
/datum/dynamic_ruleset/midround/test_pool_isolation
	name = "Test Midround Pool Isolation"
	weight = 0
	cost = 0
	requirements = list(0,0,0,0,0,0,0,0,0,0)
	required_round_type = null

/// Проверяет, что latejoin-рулсеты не попадают в кандидаты битов (их единственный путь -
/// on_latejoin с кандидатом-новичком), а midround с теми же параметрами - попадает
/// (контроль, что тест не вакуумный из-за других фильтров).
/datum/unit_test/director_latejoin_pool_isolation

/datum/unit_test/director_latejoin_pool_isolation/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch возвращает состояние даже при падении
	// ассерта (см. комментарий в director_beat_logic/Run()).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_ANTAG = world.time - profile.antag_light_spacing - 1,
		)
		SSdirector.last_antag_heavy_at = world.time - profile.antag_heavy_spacing - 1

		var/datum/dynamic_ruleset/latejoin/test_pool_isolation/latejoin_rule = new
		var/datum/dynamic_ruleset/midround/test_pool_isolation/midround_rule = new
		// Отвязываем от режима тестового раунда: can_fire с mode = null проверяет только базовые гейты.
		latejoin_rule.mode = null
		midround_rule.mode = null
		latejoin_rule.weight = 10
		midround_rule.weight = 10
		SSdirector.actions = list(latejoin_rule, midround_rule)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/list/candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(!(latejoin_rule in candidates), "Латеджойн-рулсет не должен попадать в пул битов")
		TEST_ASSERT(midround_rule in candidates, "Midround-контроль с теми же параметрами обязан пройти фильтры бита")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Раундстарт-фикстура для проверки вклада исполненных раундстартовых рулсетов.
/// weight = 0 на типе, чтобы init_rulesets живого раунда его не подобрал; intensity ставит тест.
/// LONE_RULESET - только ради dynamic_roundstart_ruleset_sanity (не-lone обязан иметь scaling_cost).
/datum/dynamic_ruleset/roundstart/test_roundstart_intensity
	name = "Test Roundstart Intensity"
	weight = 0
	cost = 0
	requirements = list(0,0,0,0,0,0,0,0,0,0)
	required_round_type = null
	flags = LONE_RULESET

/// Проверяет динамический вклад живых рулсетов в get_active_intensity(): доля выживших,
/// строки разбивки для панели, вытеснение моста из ledger и суммирование с обычными записями.
/// Плюс нейтрализация и раундстарт: разантаженный (без жёстких антаг-датумов) и посаженный
/// в пермабриг не считаются угрозой, исполненные раундстарт-рулсеты дают вклад из
/// executed_rules динамика и затухают с возрастом раунда.
/datum/unit_test/director_ruleset_intensity_breakdown

/// Минимальный жёсткий (не soft_antag) антаг-датум: маркер "разум всё ещё антагонист"
/// для расчёта вклада, без контент-эффектов конкретных ролей.
/datum/unit_test/director_ruleset_intensity_breakdown/proc/grant_hard_antag(datum/mind/target_mind)
	var/datum/antagonist/marker = new
	marker.silent = TRUE
	target_mind.add_antag_datum(marker)

/datum/unit_test/director_ruleset_intensity_breakdown/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch возвращает состояние даже при падении
	// ассерта (см. комментарий в director_beat_logic/Run()).
	var/list/saved = SSdirector.capture_simulation_state()
	var/datum/game_mode/dynamic/mode = SSticker.mode
	var/datum/dynamic_ruleset/roundstart/test_roundstart_intensity/roundstart_rule
	try
		var/datum/dynamic_ruleset/midround/test_pool_isolation/rule = new
		rule.intensity = 15
		rule.occurrences = 1
		var/mob/living/carbon/human/alive = allocate(/mob/living/carbon/human)
		alive.mind_initialize()
		grant_hard_antag(alive.mind)
		var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human)
		corpse.mind_initialize()
		corpse.death()
		rule.assigned = list(alive.mind, corpse.mind)
		SSdirector.actions = list(rule)
		// Обычная запись события + мост рулсета, оставшийся между schedule и execute:
		// мост обязан вытесниться динамическим расчётом, а не задваивать вклад.
		SSdirector.intensity_ledger = list(
			list("Тестовое событие", 5, 0, null),
			list(rule.action_name(), rule.intensity, 0, rule.severity),
		)

		var/list/breakdown = list()
		var/total = SSdirector.get_active_intensity(breakdown)
		// Свежий антаг без единого проявления весит DIRECTOR_ACTIVITY_MULT_MIN своей доли.
		TEST_ASSERT_EQUAL(total, 15 * 0.5 * DIRECTOR_ACTIVITY_MULT_MIN + 5, "Итог: вклад рулсета по доле живых с множителем тихони плюс запись события, без моста")
		TEST_ASSERT_EQUAL(length(SSdirector.intensity_ledger), 1, "Мост исполненного рулсета должен вытесниться из ledger")
		TEST_ASSERT_EQUAL(length(breakdown), 1, "Живой рулсет должен дать ровно одну строку разбивки")
		var/list/row = breakdown[1]
		TEST_ASSERT_EQUAL(row[1], rule.action_name(), "Имя строки разбивки должно совпадать с именем рулсета")
		TEST_ASSERT_EQUAL(row[2], 15 * 0.5 * DIRECTOR_ACTIVITY_MULT_MIN, "Вклад строки = intensity * активность живых / назначенные")
		TEST_ASSERT_EQUAL(row[3], 1, "Число живых в строке разбивки")
		TEST_ASSERT_EQUAL(row[4], 2, "Число назначенных в строке разбивки")

		// Активность: буйный антаг (score на капе) весит максимум своей доли - "занял всё СБ"
		// насыщает клапан давления сильнее тихони.
		SSdirector.bump_antag_activity(alive.mind, DIRECTOR_ACTIVITY_CAP * 2)
		total = SSdirector.get_active_intensity()
		TEST_ASSERT_EQUAL(total, 15 * 0.5 * DIRECTOR_ACTIVITY_MULT_MAX + 5, "Антаг на капе активности должен весить максимум своей доли")
		alive.mind.director_activity = 0

		// Разантаженный (деконверсия, снятие роли админом) больше не угроза, хоть и жив.
		alive.mind.remove_antag_datum(/datum/antagonist)
		total = SSdirector.get_active_intensity()
		TEST_ASSERT_EQUAL(total, 5, "Назначенный без жёстких антаг-датумов не должен давать вклада")
		grant_hard_antag(alive.mind)

		// Пойманный: сидящий в пермабриге антаг не двигает раунд (только если на карте CI есть перма).
		var/area/prison_area = GLOB.areas_by_type[/area/security/prison]
		var/turf/prison_turf
		if(prison_area)
			for(var/turf/prison_candidate in prison_area)
				prison_turf = prison_candidate
				break
		if(prison_turf)
			var/turf/home_turf = get_turf(alive)
			alive.forceMove(prison_turf)
			total = SSdirector.get_active_intensity()
			TEST_ASSERT_EQUAL(total, 5, "Антаг в пермабриге не должен давать вклада")
			alive.forceMove(home_turf)

		// Раундстарт-рулсет: в actions не регистрируется, вклад обязан идти из executed_rules динамика.
		TEST_ASSERT(istype(mode), "Тестовый раунд обязан идти на динамике (источник executed_rules)")
		roundstart_rule = new
		roundstart_rule.intensity = 30
		roundstart_rule.assigned = list(alive.mind, corpse.mind)
		mode.executed_rules += roundstart_rule
		// Свежий раунд (time_override двигает часы now()): затухания ещё нет.
		SSdirector.time_override = SSticker.round_start_time + 1 MINUTES
		breakdown = list()
		total = SSdirector.get_active_intensity(breakdown)
		TEST_ASSERT_EQUAL(total, (15 * 0.5 + 30 * 0.5) * DIRECTOR_ACTIVITY_MULT_MIN + 5, "Итог обязан включать вклад раундстарт-рулсета по доле живых")
		TEST_ASSERT_EQUAL(length(breakdown), 2, "Живой раундстарт-рулсет обязан дать свою строку разбивки")
		// Поздний раунд: вклад раундстарта затухает до пола; midround без штампа запуска
		// (executed_at = 0) считается от старта раунда и затухает так же.
		SSdirector.time_override = SSticker.round_start_time + 200 MINUTES
		total = SSdirector.get_active_intensity()
		TEST_ASSERT_EQUAL(total, (15 * 0.5 * 0.25 + 30 * 0.5 * 0.25) * DIRECTOR_ACTIVITY_MULT_MIN + 5, "Поздним раундом вклад рулсетов без штампа обязан затухнуть до пола")
		// Свежая инжекция (executed_at = только что) даёт полный вклад независимо от возраста раунда.
		rule.executed_at = SSdirector.now() - 1 MINUTES
		total = SSdirector.get_active_intensity()
		TEST_ASSERT_EQUAL(total, (15 * 0.5 + 30 * 0.5 * 0.25) * DIRECTOR_ACTIVITY_MULT_MIN + 5, "Свежая инжекция не должна затухать по возрасту раунда")
		rule.executed_at = 0
		SSdirector.time_override = 0

		// Полностью мёртвые рулсеты не дают ни вклада, ни строк.
		alive.death()
		breakdown = list()
		total = SSdirector.get_active_intensity(breakdown)
		TEST_ASSERT_EQUAL(total, 5, "Мёртвый рулсет не должен давать вклада")
		TEST_ASSERT_EQUAL(length(breakdown), 0, "Мёртвый рулсет не должен давать строк разбивки")
	catch(var/exception/e)
		if(istype(mode) && roundstart_rule)
			mode.executed_rules -= roundstart_rule
		SSdirector.restore_simulation_state(saved)
		throw e
	if(istype(mode) && roundstart_rule)
		mode.executed_rules -= roundstart_rule
	SSdirector.restore_simulation_state(saved)

/// Гост-рулсет фикстура: weight = 0, чтобы init_rulesets живого раунда его не подобрал;
/// makeBody = FALSE и пустой finish_setup - тесту нужен только путь наполнения assigned.
/datum/dynamic_ruleset/midround/from_ghosts/test_assigned_minds
	name = "Test From Ghosts Assigned"
	weight = 0
	cost = 0
	required_candidates = 1 // база = 0: без этого цикл назначения review_applications не крутится
	requirements = list(0,0,0,0,0,0,0,0,0,0)
	required_round_type = null
	makeBody = FALSE

/datum/dynamic_ruleset/midround/from_ghosts/test_assigned_minds/finish_setup(mob/new_character, index)
	return // антаг-датум контенту не нужен: тест проверяет только содержимое assigned

/// Регрессия "Space Dragon не учитывался в intensity": review_applications клал в assigned
/// моба-призрака вместо mind. tally_ruleset_intensity молча пропускал не-mind (вклад 0),
/// а live_names при этом помечался - и get_active_intensity вытеснял мост рулсета из ledger.
/// Итог: ни один from_ghosts-рулсет (вся ступень гост-антагов) не давал intensity вовсе.
/datum/unit_test/director_from_ghosts_assigned_minds

/datum/unit_test/director_from_ghosts_assigned_minds/Run()
	var/datum/dynamic_ruleset/midround/from_ghosts/test_assigned_minds/rule = new
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer)
	var/datum/mind/ghost_mind = allocate(/datum/mind, "unit_test_from_ghosts")
	ghost_mind.current = ghost
	ghost.mind = ghost_mind
	rule.candidates = list(ghost)
	rule.review_applications()
	TEST_ASSERT_EQUAL(length(rule.assigned), 1, "review_applications должен назначить одного кандидата")
	var/datum/mind/assigned_mind = rule.assigned[1]
	TEST_ASSERT(istype(assigned_mind), "В assigned обязан лежать mind, а не моб: по нему директор считает вклад рулсета в intensity")
	TEST_ASSERT_EQUAL(assigned_mind, ghost_mind, "В assigned обязан лежать mind назначенного кандидата")

/// Проверяет независимость ступеней ANTAG и GHOST: запуск одной не двигает паузы другой
/// (и лёгкие, и тяжёлые треки раздельны), кошельки не пересекаются, эвакуация закрывает обе.
/datum/unit_test/director_ghost_pool_independence

/datum/unit_test/director_ghost_pool_independence/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/datum/director_action/test_stub/crew_antag = new
		crew_antag.severity = DIRECTOR_SEVERITY_ANTAG
		var/datum/director_action/test_stub/ghost_antag = new
		ghost_antag.severity = DIRECTOR_SEVERITY_GHOST
		SSdirector.actions = list(crew_antag, ghost_antag)

		// Обе паузы прогнаны в прошлое - чистый стол.
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_ANTAG = world.time - profile.antag_light_spacing - 1,
			DIRECTOR_SEVERITY_GHOST = world.time - profile.ghost_light_spacing - 1,
		)
		SSdirector.last_antag_heavy_at = world.time - profile.antag_heavy_spacing - 1
		SSdirector.last_ghost_heavy_at = world.time - profile.ghost_heavy_spacing - 1

		var/list/candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(crew_antag in candidates, "ANTAG-стаб обязан проходить на чистом столе")
		TEST_ASSERT(ghost_antag in candidates, "GHOST-стаб обязан проходить на чистом столе")

		// Лёгкая пауза: свежий запуск ANTAG не должен закрывать GHOST.
		SSdirector.last_fired_at[DIRECTOR_SEVERITY_ANTAG] = world.time
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(!(crew_antag in candidates), "Свежий запуск ANTAG должен закрывать ANTAG по паузе")
		TEST_ASSERT(ghost_antag in candidates, "Свежий запуск ANTAG не должен закрывать GHOST")

		// И наоборот.
		SSdirector.last_fired_at[DIRECTOR_SEVERITY_ANTAG] = world.time - profile.antag_light_spacing - 1
		SSdirector.last_fired_at[DIRECTOR_SEVERITY_GHOST] = world.time
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(crew_antag in candidates, "Свежий запуск GHOST не должен закрывать ANTAG")
		TEST_ASSERT(!(ghost_antag in candidates), "Свежий запуск GHOST должен закрывать GHOST по паузе")
		SSdirector.last_fired_at[DIRECTOR_SEVERITY_GHOST] = world.time - profile.ghost_light_spacing - 1

		// Тяжёлые треки раздельны: heavy-запуск ANTAG (культ) не откладывает heavy GHOST (нюков).
		crew_antag.antag_heavy = TRUE
		ghost_antag.antag_heavy = TRUE
		SSdirector.last_antag_heavy_at = world.time
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(!(crew_antag in candidates), "Свежий heavy ANTAG должен закрывать heavy ANTAG")
		TEST_ASSERT(ghost_antag in candidates, "Свежий heavy ANTAG не должен закрывать heavy GHOST")
		SSdirector.last_antag_heavy_at = world.time - profile.antag_heavy_spacing - 1
		crew_antag.antag_heavy = FALSE
		ghost_antag.antag_heavy = FALSE

		// note_fired обязан роутить heavy-таймстемп в трек своей ступени.
		var/datum/director_action/test_stub/ghost_heavy = new
		ghost_heavy.severity = DIRECTOR_SEVERITY_GHOST
		ghost_heavy.antag_heavy = TRUE
		var/antag_heavy_before = SSdirector.last_antag_heavy_at
		SSdirector.note_fired(ghost_heavy)
		TEST_ASSERT_EQUAL(SSdirector.last_ghost_heavy_at, SSdirector.now(), "note_fired heavy GHOST должен обновлять ghost-трек")
		TEST_ASSERT_EQUAL(SSdirector.last_antag_heavy_at, antag_heavy_before, "note_fired heavy GHOST не должен трогать antag-трек")
		SSdirector.last_ghost_heavy_at = world.time - profile.ghost_heavy_spacing - 1
		SSdirector.fired_counts = list()

		// Кошельки не пересекаются: пустой ANTAG-кошелёк не отсекает GHOST-кандидата.
		crew_antag.cost = 5
		ghost_antag.cost = 5
		SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] = 0
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(!(crew_antag in candidates), "Пустой ANTAG-кошелёк должен отсекать ANTAG")
		TEST_ASSERT(ghost_antag in candidates, "Пустой ANTAG-кошелёк не должен отсекать GHOST")
		SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] = 100
		crew_antag.cost = 0
		ghost_antag.cost = 0

		// Эвакуация закрывает обе антаг-ступени.
		signals.evac_state = DIRECTOR_EVAC_CALLED
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(!(crew_antag in candidates), "После вызова эвакуации ANTAG должен быть закрыт")
		TEST_ASSERT(!(ghost_antag in candidates), "После вызова эвакуации GHOST должен быть закрыт")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет по-действийные вердикты для панели: инвариант "ровно один вердикт на действие",
/// причину и деталь у отсеянных, eff_weight у прошедших и расшифровку can_fire по полям
/// базового контракта (diagnose_can_fire).
/datum/unit_test/director_pool_verdicts

/datum/unit_test/director_pool_verdicts/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1,
			DIRECTOR_SEVERITY_MODERATE = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MODERATE] - 1,
		)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/datum/director_action/test_stub/ready_action = new
		var/datum/director_action/test_stub/disabled_action = new
		disabled_action.enabled = FALSE
		var/datum/director_action/test_stub/poor_action = new
		poor_action.severity = DIRECTOR_SEVERITY_MODERATE
		poor_action.cost = 500
		SSdirector.actions = list(ready_action, disabled_action, poor_action)

		var/list/verdicts = list()
		SSdirector.filter_candidates(signals, FALSE, null, verdicts)
		TEST_ASSERT_EQUAL(length(verdicts), 3, "Каждое действие должно получить ровно один вердикт")
		var/list/by_verdict = list()
		for(var/list/entry in verdicts)
			by_verdict[entry["verdict"]] = entry
		var/list/ok_entry = by_verdict[DIRECTOR_VERDICT_OK]
		TEST_ASSERT_NOTNULL(ok_entry, "Проходное действие должно получить вердикт OK")
		TEST_ASSERT_NOTNULL(ok_entry["eff_weight"], "У прошедшего действия должен быть эффективный вес")
		TEST_ASSERT_NOTNULL(by_verdict[DIRECTOR_CANTFIRE_DISABLED], "Выключенное действие должно получить расшифровку disabled, а не общий can_fire")
		var/list/budget_entry = by_verdict[DIRECTOR_REJECT_BUDGET]
		TEST_ASSERT_NOTNULL(budget_entry, "Действие дороже кошелька должно отсеяться по бюджету")
		TEST_ASSERT_NOTNULL(budget_entry["detail"], "У отсева по бюджету должна быть деталь \"сколько из скольких\"")

		// Боевой путь (без verdicts) не должен меняться: те же гейты, только счётчики отсева.
		var/list/reject_stats = list()
		var/list/candidates = SSdirector.filter_candidates(signals, FALSE, reject_stats)
		TEST_ASSERT_EQUAL(length(candidates), 1, "Из трёх действий пройти должно ровно одно")
		TEST_ASSERT_NOTNULL(reject_stats[DIRECTOR_SEVERITY_MODERATE], "Отсев по бюджету должен считаться в reject_stats")

		// Расшифровка can_fire: гейты в порядке базового контракта, с деталями где есть числа.
		var/datum/director_action/test_stub/probe = new
		probe.admin_only = TRUE
		var/list/diag = SSdirector.diagnose_can_fire(probe, signals)
		TEST_ASSERT_EQUAL(diag["reason"], DIRECTOR_CANTFIRE_ADMIN_ONLY, "admin_only должен диагностироваться")
		probe.admin_only = FALSE
		probe.max_occurrences = 1
		probe.occurrences = 1
		diag = SSdirector.diagnose_can_fire(probe, signals)
		TEST_ASSERT_EQUAL(diag["reason"], DIRECTOR_CANTFIRE_OCCURRENCES, "Достигнутый max_occurrences должен диагностироваться")
		probe.occurrences = 0
		probe.max_occurrences = 0
		probe.earliest_start = 1000 HOURS
		diag = SSdirector.diagnose_can_fire(probe, signals)
		TEST_ASSERT_EQUAL(diag["reason"], DIRECTOR_CANTFIRE_EARLY, "Недостигнутый earliest_start должен диагностироваться")
		TEST_ASSERT_NOTNULL(diag["detail"], "У ранней диагностики должна быть деталь с минутами")
		probe.earliest_start = 0
		probe.min_players = 50
		diag = SSdirector.diagnose_can_fire(probe, signals)
		TEST_ASSERT_EQUAL(diag["reason"], DIRECTOR_CANTFIRE_MIN_PLAYERS, "min_players выше экипажа должен диагностироваться")
		probe.min_players = 0
		diag = SSdirector.diagnose_can_fire(probe, signals)
		TEST_ASSERT_EQUAL(diag["reason"], DIRECTOR_CANTFIRE_SPECIAL, "Проходное по базовым полям действие должно давать SPECIAL-фолбэк")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет гейт пустой станции: без эффективного экипажа биты простаивают и капля
/// не копится, с экипажем тот же сетап стреляет и копит (контроль от вакуума).
/datum/unit_test/director_empty_station_gate

/datum/unit_test/director_empty_station_gate/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		// За глобальной паузой (иначе контрольный бит с экипажем отсёкся бы global_spacing),
		// но до порога затишья - гарантированный бит не должен маскировать обычный путь.
		SSdirector.last_any_fired_at = world.time - profile.global_spacing - 1
		SSdirector.last_real_fired_at = world.time - profile.global_spacing - 1
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1,
		)
		// dry_run: решение учитывается (бюджет/счётчики), но не исполняется и не трогает форс-праздники.
		SSdirector.dry_run = TRUE

		var/datum/director_action/test_stub/ready_action = new
		SSdirector.actions = list(ready_action)

		var/datum/director_signals/empty_signals = new
		empty_signals.effective_crew = 0
		empty_signals.staffing = list(DIRECTOR_DEPT_SECURITY = 0, DIRECTOR_DEPT_ENGINEERING = 0,
			DIRECTOR_DEPT_MEDICAL = 0, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 0)

		TEST_ASSERT_EQUAL(SSdirector.run_beat(empty_signals), DIRECTOR_BEAT_IDLE, "Бит на пустой станции должен простаивать")
		TEST_ASSERT_EQUAL(SSdirector.fired_counts[DIRECTOR_SEVERITY_MINOR] || 0, 0, "Пустая станция не должна получать запуски")

		SSdirector.last_signals = empty_signals
		var/budget_before = SSdirector.total_budget()
		SSdirector.accumulate_drip()
		TEST_ASSERT_EQUAL(SSdirector.total_budget(), budget_before, "Капля не должна копиться на пустой станции")

		// Контроль: с экипажем тот же сетап стреляет и капает.
		var/datum/director_signals/crewed_signals = new
		crewed_signals.effective_crew = 40
		crewed_signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)
		TEST_ASSERT_EQUAL(SSdirector.run_beat(crewed_signals), DIRECTOR_BEAT_FIRED, "Контрольный бит с экипажем обязан стрелять")
		SSdirector.last_signals = crewed_signals
		budget_before = SSdirector.total_budget()
		SSdirector.accumulate_drip()
		TEST_ASSERT(SSdirector.total_budget() > budget_before, "Контрольная капля с экипажем обязана копиться")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет затухание повторов: математику repeat_falloff и то, что в кандидатах бита
/// уже стрелявшее действие весит меньше свежего с теми же параметрами.
/datum/unit_test/director_repeat_falloff

/datum/unit_test/director_repeat_falloff/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		profile.repeat_penalty = 0.5
		SSdirector.profile = profile

		var/datum/director_action/test_stub/fresh = new
		TEST_ASSERT_EQUAL(SSdirector.repeat_falloff(fresh), 1, "Без запусков затухания быть не должно")
		fresh.occurrences = 2
		TEST_ASSERT_EQUAL(SSdirector.repeat_falloff(fresh), 0.5, "Два запуска при penalty 0.5 должны дать множитель 0.5")
		fresh.repeat_penalty = 0
		TEST_ASSERT_EQUAL(SSdirector.repeat_falloff(fresh), 1, "Персональный repeat_penalty = 0 должен выключать затухание")
		fresh.repeat_penalty = null
		fresh.occurrences = 0

		// Интеграция: ветеран с двумя запусками весит в кандидатах вдвое меньше свежего.
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1,
		)
		var/datum/director_action/test_stub/veteran = new
		veteran.occurrences = 2
		SSdirector.actions = list(fresh, veteran)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)
		var/list/candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(fresh in candidates, "Свежее действие должно быть кандидатом")
		TEST_ASSERT(veteran in candidates, "Затухание должно резать вес, а не выкидывать из пула")
		TEST_ASSERT(candidates[veteran] < candidates[fresh], "Повторявшееся действие должно весить меньше свежего ([candidates[veteran]] против [candidates[fresh]])")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет счётчики причин отсева: spacing, пустой кошелёк и can_fire считаются
/// по своим ступеням, кандидатов при этом нет.
/datum/unit_test/director_reject_stats

/datum/unit_test/director_reject_stats/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(0)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time,
			DIRECTOR_SEVERITY_MODERATE = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MODERATE] - 1,
		)

		var/datum/director_action/test_stub/spaced = new // MINOR только что стрелял - пауза ступени
		var/datum/director_action/test_stub/broke = new
		broke.severity = DIRECTOR_SEVERITY_MODERATE
		broke.cost = 50 // кошелёк MODERATE пуст
		var/datum/director_action/test_stub/disabled = new
		disabled.severity = DIRECTOR_SEVERITY_MODERATE
		disabled.enabled = FALSE // отсеется в can_fire
		SSdirector.actions = list(spaced, broke, disabled)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)
		var/list/reject_stats = list()
		var/list/candidates = SSdirector.filter_candidates(signals, FALSE, reject_stats)
		TEST_ASSERT_EQUAL(length(candidates), 0, "Все три действия должны отсеяться")
		var/list/minor_stats = reject_stats[DIRECTOR_SEVERITY_MINOR]
		var/list/moderate_stats = reject_stats[DIRECTOR_SEVERITY_MODERATE]
		TEST_ASSERT_NOTNULL(minor_stats, "Отсев MINOR должен быть посчитан")
		TEST_ASSERT_NOTNULL(moderate_stats, "Отсев MODERATE должен быть посчитан")
		TEST_ASSERT_EQUAL(minor_stats[DIRECTOR_REJECT_SPACING], 1, "Пауза ступени должна попасть в счётчик spacing")
		TEST_ASSERT_EQUAL(moderate_stats[DIRECTOR_REJECT_BUDGET], 1, "Пустой кошелёк должен попасть в счётчик budget")
		TEST_ASSERT_EQUAL(moderate_stats[DIRECTOR_REJECT_CAN_FIRE], 1, "Выключенное действие должно попасть в счётчик can_fire")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет применение config/director.json к профилю: известные ключи (в т.ч. минутные) применяются,
/// неизвестный ключ фиксируется в config_error, а не рантаймит.
/datum/unit_test/director_config_apply

/datum/unit_test/director_config_apply/Run()
	var/datum/director_profile/profile = new /datum/director_profile/medium
	SSdirector.profile = profile
	SSdirector.apply_profile_config(profile, list("base_drip" = 2.5, "max_quiet_time" = 5, "repeat_penalty" = 0.7, "global_spacing" = 4, "family_spacing" = 20))
	TEST_ASSERT_EQUAL(profile.base_drip, 2.5, "base_drip должен примениться")
	TEST_ASSERT_EQUAL(profile.max_quiet_time, 5 MINUTES, "max_quiet_time должен конвертироваться из минут")
	TEST_ASSERT_EQUAL(profile.repeat_penalty, 0.7, "repeat_penalty профиля должен примениться")
	TEST_ASSERT_EQUAL(profile.global_spacing, 4 MINUTES, "global_spacing должен конвертироваться из минут")
	TEST_ASSERT_EQUAL(profile.family_spacing, 20 MINUTES, "family_spacing должен конвертироваться из минут")
	// Частичный мердж множителей навязчивости: тронутая метка меняется, остальные не сбрасываются.
	SSdirector.apply_profile_config(profile, list("disruption_weight_mults" = list(DIRECTOR_DISRUPTION_DISRUPTIVE = 0.2)))
	TEST_ASSERT_EQUAL(profile.disruption_weight_mults[DIRECTOR_DISRUPTION_DISRUPTIVE], 0.2, "Множитель навязчивости должен примениться")
	TEST_ASSERT_EQUAL(profile.disruption_weight_mults[DIRECTOR_DISRUPTION_AMBIENT], 1, "Нетронутые множители навязчивости должны сохраняться")
	SSdirector.apply_profile_config(profile, list("no_such_key" = 1))
	TEST_ASSERT_NOTNULL(SSdirector.config_error, "Неизвестный ключ должен фиксироваться как ошибка")
	SSdirector.config_error = null

	var/datum/director_action/test_stub/action = new
	SSdirector.apply_action_config(action, list("repeat_penalty" = 2, "earliest_start" = 10, "family" = "cfg_family", "disruption" = DIRECTOR_DISRUPTION_AMBIENT))
	TEST_ASSERT_EQUAL(action.repeat_penalty, 2, "repeat_penalty действия должен примениться")
	TEST_ASSERT_EQUAL(action.earliest_start, 10 MINUTES, "earliest_start действия должен конвертироваться из минут")
	TEST_ASSERT_EQUAL(action.family, "cfg_family", "family действия должен применяться из конфига")
	TEST_ASSERT_EQUAL(action.get_disruption(), DIRECTOR_DISRUPTION_AMBIENT, "disruption действия должен применяться из конфига")
	SSdirector.apply_action_config(action, list("no_such_key" = 1))
	TEST_ASSERT_NOTNULL(SSdirector.config_error, "Неизвестный ключ действия должен фиксироваться как ошибка")
	SSdirector.config_error = null
	SSdirector.profile = null

/// Проверяет тегирование severity/cost/intensity у всех действий директора.
/// Цикл 1 проходит живой SSdirector.actions: в этом тестовом мире Box Station реально стартует
/// (dynamic pre_setup отрабатывает), поэтому там уже есть и события, и midround/latejoin рулсеты -
/// цикл ловит любые коллизии action_name() между ними. Цикл 2 - независимая подстраховка по
/// subtypesof с кратковременной инстанциацией (как test_pool_isolation выше в этом файле): проверяет
/// severity/intensity рулсетов и их взаимную уникальность даже если бы pre_setup не отработал
/// (другой режим раунда).
/datum/unit_test/director_action_tagging

/datum/unit_test/director_action_tagging/Run()
	var/list/valid = list(DIRECTOR_SEVERITY_FLAVOR, DIRECTOR_SEVERITY_MINOR, DIRECTOR_SEVERITY_MODERATE, DIRECTOR_SEVERITY_MAJOR, DIRECTOR_SEVERITY_ANTAG, DIRECTOR_SEVERITY_GHOST)
	var/list/seen_names = list()
	for(var/datum/director_action/action as anything in SSdirector.actions)
		var/action_name = action.action_name()
		TEST_ASSERT(!isnull(action.severity) && (action.severity in valid), "[action_name]: невалидная severity [action.severity]")
		TEST_ASSERT(action.cost >= 0, "[action_name]: отрицательный cost")
		TEST_ASSERT(action.intensity >= 0, "[action_name]: отрицательная intensity")
		if(action.severity != DIRECTOR_SEVERITY_FLAVOR && !action.admin_only && action.enabled && action.director_kind == DIRECTOR_KIND_EVENT)
			TEST_ASSERT(action.cost > 0, "[action_name]: враждебное событие с нулевым cost")
		TEST_ASSERT(!(action_name in seen_names), "[action_name]: неуникальное имя действия (ключ конфига)")
		seen_names += action_name

	// Рулсеты: severity/intensity проверяются через реальные инстансы (severity могла бы быть
	// переопределена в теле датума, а не только унаследована от базы). Имена собираются отдельно
	// от событийных seen_names, чтобы диагностика коллизии ruleset-vs-ruleset не путалась с event-vs-ruleset.
	// test_pool_isolation и test_roundstart_intensity - фикстуры других тестов в этом же файле,
	// не реальный игровой контент; требования тегирования на них не распространяются.
	var/list/tagging_test_fixtures = list(/datum/dynamic_ruleset/midround/test_pool_isolation, /datum/dynamic_ruleset/latejoin/test_pool_isolation, /datum/dynamic_ruleset/roundstart/test_roundstart_intensity, /datum/dynamic_ruleset/midround/from_ghosts/test_assigned_minds)
	var/list/ruleset_names = list()
	for(var/datum/dynamic_ruleset/midround/ruleset_path as anything in subtypesof(/datum/dynamic_ruleset/midround))
		if(!initial(ruleset_path.name) || (ruleset_path in tagging_test_fixtures))
			continue
		var/datum/dynamic_ruleset/midround/ruleset = new ruleset_path()
		// Классификация по источнику игрока: наблюдательские рулсеты (ветка from_ghosts плюс
		// swarmers/pirates/raiders) обязаны лежать в GHOST, рулсеты по живому экипажу - в ANTAG.
		var/expected_severity = (ruleset.required_type == /mob/dead/observer) ? DIRECTOR_SEVERITY_GHOST : DIRECTOR_SEVERITY_ANTAG
		TEST_ASSERT_EQUAL(ruleset.severity, expected_severity, "[ruleset_path]: severity обязана соответствовать источнику игроков ([expected_severity])")
		TEST_ASSERT(ruleset.intensity >= 0, "[ruleset_path]: отрицательная intensity")
		TEST_ASSERT(ruleset.intensity > 0, "[ruleset_path]: рулсет без вклада в intensity")
		var/ruleset_action_name = ruleset.action_name()
		TEST_ASSERT(!(ruleset_action_name in ruleset_names), "[ruleset_action_name]: неуникальное имя рулсета (ключ конфига/intensity_ledger)")
		ruleset_names += ruleset_action_name
	for(var/datum/dynamic_ruleset/latejoin/ruleset_path as anything in subtypesof(/datum/dynamic_ruleset/latejoin))
		if(!initial(ruleset_path.name) || (ruleset_path in tagging_test_fixtures))
			continue
		var/datum/dynamic_ruleset/latejoin/ruleset = new ruleset_path()
		TEST_ASSERT_EQUAL(ruleset.severity, DIRECTOR_SEVERITY_ANTAG, "[ruleset_path]: рулсет обязан иметь severity ANTAG")
		TEST_ASSERT(ruleset.intensity >= 0, "[ruleset_path]: отрицательная intensity")
		TEST_ASSERT(ruleset.intensity > 0, "[ruleset_path]: рулсет без вклада в intensity")
		var/ruleset_action_name = ruleset.action_name()
		TEST_ASSERT(!(ruleset_action_name in ruleset_names), "[ruleset_action_name]: неуникальное имя рулсета (ключ конфига/intensity_ledger)")
		ruleset_names += ruleset_action_name

	// Раундстарт-рулсеты не регистрируются в actions, но их intensity читает get_ruleset_intensity
	// через executed_rules динамика, а action_name - ключ строк разбивки/live_names, поэтому
	// тегирование и уникальность имён проверяются тем же субтайп-обходом. Extended и Meteor никого
	// не назначают (assigned пуст) - вклада в intensity у них нет по построению.
	var/list/roundstart_no_intensity = list(/datum/dynamic_ruleset/roundstart/extended, /datum/dynamic_ruleset/roundstart/meteor)
	for(var/datum/dynamic_ruleset/roundstart/ruleset_path as anything in subtypesof(/datum/dynamic_ruleset/roundstart))
		if(!initial(ruleset_path.name) || (ruleset_path in tagging_test_fixtures))
			continue
		var/datum/dynamic_ruleset/roundstart/ruleset = new ruleset_path()
		TEST_ASSERT_EQUAL(ruleset.severity, DIRECTOR_SEVERITY_ANTAG, "[ruleset_path]: раундстарт-рулсет обязан иметь severity ANTAG")
		TEST_ASSERT(ruleset.intensity >= 0, "[ruleset_path]: отрицательная intensity")
		if(!(ruleset_path in roundstart_no_intensity))
			TEST_ASSERT(ruleset.intensity > 0, "[ruleset_path]: рулсет без вклада в intensity")
		var/ruleset_action_name = ruleset.action_name()
		TEST_ASSERT(!(ruleset_action_name in ruleset_names), "[ruleset_action_name]: неуникальное имя рулсета (ключ конфига/intensity_ledger)")
		ruleset_names += ruleset_action_name

	// Отдельной сверки ruleset_names против seen_names здесь нет: в этом тестовом мире dynamic
	// pre_setup реально отрабатывает (SSticker поднимает раунд на Box Station), поэтому midround/
	// latejoin рулсеты УЖЕ живут внутри SSdirector.actions и покрыты циклом 1 (seen_names). Сверка
	// с заново заинстансированными в этом цикле объектами тех же типов давала бы ложные срабатывания
	// (тот же тип дважды под разными ссылками, а не настоящая коллизия).

/// Проверяет, что геймод Extended поднимает директора. Регрессия: setup_profile() звался только из
/// dynamic, а master_mode "Extended" в pick_mode() матчится на config_tag геймода extended/announced -
/// dynamic не создавался, profile оставался null и гейт fire() глушил каплю и биты весь раунд.
/datum/unit_test/director_extended_gamemode

/datum/unit_test/director_extended_gamemode/Run()
	// Мутирует живой SSdirector и GLOB.round_type - capture/restore c try/catch (см. director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	var/saved_round_type = GLOB.round_type
	try
		SSdirector.profile = null
		// Форс/секрет-путь: round_type мог остаться от прошлого выбора - профиль всё равно обязан быть Extended.
		GLOB.round_type = ROUNDTYPE_DYNAMIC_MEDIUM
		var/datum/game_mode/extended/mode = new
		TEST_ASSERT(mode.pre_setup(), "pre_setup Extended должен проходить")
		TEST_ASSERT_NOTNULL(SSdirector.profile, "Extended должен поднимать профиль директора")
		TEST_ASSERT_EQUAL(SSdirector.profile.round_type, ROUNDTYPE_EXTENDED, "Extended должен получать профиль Extended, а не фолбэк")
		TEST_ASSERT_EQUAL(GLOB.round_type, ROUNDTYPE_EXTENDED, "pre_setup Extended должен выставлять round_type для контент-гейтов")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		GLOB.round_type = saved_round_type
		throw e
	SSdirector.restore_simulation_state(saved)
	GLOB.round_type = saved_round_type

/// CI-санити пейсинга: 2 симулированных часа Medium при 40 экипажа не должны быть ни пустыми
/// (гарантированный бит сломан), ни беспрерывными (fired на каждом бите - спейсинг ступеней
/// не работает), ни захлёбывающимися (потолок intensity не держит). Рулсеты режима
/// зарегистрировать не можем (тестовый раунд не обязан быть Dynamic Medium) - симулируем на реальных
/// событиях из SSdirector.actions, этого достаточно для санити пейсинга.
/datum/unit_test/director_simulation_sanity

/datum/unit_test/director_simulation_sanity/Run()
	var/list/log_out = director_simulate(ROUNDTYPE_DYNAMIC_MEDIUM, 2, 40)
	var/fired = 0
	var/max_intensity = 0
	var/quiet_streak = 0
	var/max_quiet_streak = 0
	var/list/fired_by_severity = list()
	for(var/list/entry in log_out)
		if(entry["result"] == DIRECTOR_BEAT_FIRED || entry["result"] == DIRECTOR_BEAT_GUARANTEED)
			fired++
			quiet_streak = 0
			var/sev = entry["severity"] || "?"
			fired_by_severity[sev] = (fired_by_severity[sev] || 0) + 1
		else
			quiet_streak++
			max_quiet_streak = max(max_quiet_streak, quiet_streak)
		max_intensity = max(max_intensity, entry["intensity"])
	// Состав по ступеням в лог CI: сырьё для тюнинга темпа без ручного прогона симулятора.
	var/list/composition = list()
	for(var/sev in fired_by_severity)
		composition += "[sev]=[fired_by_severity[sev]]"
	log_world("DIRECTOR SIM: Medium@40, 2ч: [fired] запусков ([composition.Join(", ")]), пик intensity [max_intensity], макс. тишина [max_quiet_streak] мин")
	TEST_ASSERT(fired >= 8, "За 2 часа Medium при 40 экипажа должно случиться не меньше 8 действий, случилось [fired]")
	// Верхний порог ловит регрессию "директор стреляет каждый бит" (дыра нулевого FLAVOR-spacing,
	// починена в профилях). Норма Medium ~58 из 120 битов - запас двукратный в обе стороны.
	TEST_ASSERT(fired <= 90, "За 2 часа Medium при 40 экипажа случилось [fired] действий из 120 битов - биты разучились простаивать")
	TEST_ASSERT(max_intensity <= 100 + 40, "Пик intensity [max_intensity] не должен превышать потолок больше чем на одно MAJOR-действие")
	TEST_ASSERT(max_quiet_streak <= 20, "Тихое окно [max_quiet_streak] минут - гарантированный бит не работает")

	// Регрессия голодания тяжёлых ступеней (кошельки бюджета по ступеням). При едином бюджете дешёвые
	// MINOR/MODERATE осушали общий счёт и MAJOR (cost 25) не набирался. С кошельками при капле Hard@60
	// (base 1.5 * pop 1.4 = 2.1/мин) доля MAJOR стабильно копит на cost и обязана выстрелить за 2 часа.
	var/list/hard_log = director_simulate(ROUNDTYPE_DYNAMIC_HARD, 2, 60)
	var/heavy_fired = 0
	var/list/hard_by_severity = list()
	for(var/list/entry in hard_log)
		if(entry["result"] != DIRECTOR_BEAT_FIRED && entry["result"] != DIRECTOR_BEAT_GUARANTEED)
			continue
		var/sev = entry["severity"] || "?"
		hard_by_severity[sev] = (hard_by_severity[sev] || 0) + 1
		if(entry["severity"] == DIRECTOR_SEVERITY_MAJOR || (DIRECTOR_IS_ANTAG_POOL(entry["severity"]) && entry["antag_heavy"]))
			heavy_fired++
	var/list/hard_composition = list()
	for(var/sev in hard_by_severity)
		hard_composition += "[sev]=[hard_by_severity[sev]]"
	log_world("DIRECTOR SIM: Hard@60, 2ч: состав [hard_composition.Join(", ")]")
	TEST_ASSERT(heavy_fired >= 1, "За 2 часа Hard при 60 экипажа тяжёлая ступень (MAJOR или тяжёлый ANTAG) ни разу не выстрелила - голодание вернулось")

	// Мягкие профили: Light и Extended живут (в т.ч. гост-антаги - регрессия "на эксте раньше
	// спаунились антаги"), но без MAJOR и без тяжёлых антаг-команд. Teambased обязан кормить
	// антаг-пулы. Экипажи прогонов подобраны под min_players гост-событий (кошмар/дракон = 30).
	// Гост-ассерты стохастические: одиночный 2ч-прогон даёт 0 гост-запусков с шансом ~10%
	// (копилка пула может весь прогон копить на дорогую цель, CI-статистика: 5 падений на 38
	// прогонов карт). Ретраи давят флейк, не пряча структурную регрессию: мёртвый пул (нулевая
	// доля, все действия отфильтрованы) даст 0 во ВСЕХ попытках. Детерминированные инварианты
	// профиля (без MAJOR, без тяжёлых команд) проверяются на каждой попытке - ретрай их не размывает.
	var/list/soft_specs = list(
		list(ROUNDTYPE_DYNAMIC_LIGHT, 30, 4),
		list(ROUNDTYPE_EXTENDED, 30, 3),
		list(ROUNDTYPE_DYNAMIC_TEAMBASED, 40, 8),
	)
	for(var/list/spec in soft_specs)
		var/spec_type = spec[1]
		var/spec_crew = spec[2]
		var/spec_min_fired = spec[3]
		var/spec_fired = 0
		var/spec_ghost = 0
		for(var/attempt in 1 to 4)
			var/list/spec_log = director_simulate(spec_type, 2, spec_crew)
			spec_fired = 0
			spec_ghost = 0
			var/spec_heavy = 0
			var/spec_major = 0
			var/list/spec_by_severity = list()
			for(var/list/entry in spec_log)
				if(entry["result"] != DIRECTOR_BEAT_FIRED && entry["result"] != DIRECTOR_BEAT_GUARANTEED)
					continue
				spec_fired++
				var/sev = entry["severity"] || "?"
				spec_by_severity[sev] = (spec_by_severity[sev] || 0) + 1
				if(entry["antag_heavy"])
					spec_heavy++
				if(sev == DIRECTOR_SEVERITY_GHOST)
					spec_ghost++
				if(sev == DIRECTOR_SEVERITY_MAJOR)
					spec_major++
			var/list/spec_composition = list()
			for(var/sev in spec_by_severity)
				spec_composition += "[sev]=[spec_by_severity[sev]]"
			log_world("DIRECTOR SIM: [spec_type]@[spec_crew], 2ч, попытка [attempt]: [spec_fired] запусков ([spec_composition.Join(", ")])")
			if(spec_type == ROUNDTYPE_DYNAMIC_LIGHT || spec_type == ROUNDTYPE_EXTENDED)
				TEST_ASSERT_EQUAL(spec_heavy, 0, "[spec_type]: тяжёлые антаг-действия обязаны быть выключены профилем, случилось [spec_heavy]")
				TEST_ASSERT_EQUAL(spec_major, 0, "[spec_type]: MAJOR-события обязаны быть недоступны (доля 0), случилось [spec_major]")
			if(spec_fired >= spec_min_fired && spec_ghost >= 1)
				break
		TEST_ASSERT(spec_fired >= spec_min_fired, "За 2 часа [spec_type] при [spec_crew] экипажа должно случиться не меньше [spec_min_fired] действий, случилось [spec_fired] (после 4 попыток)")
		TEST_ASSERT(spec_ghost >= 1, "[spec_type]: за 2 часа гост-антаг обязан появиться хотя бы раз (Light/Extended - регрессия отсутствия антагов, Teambased - антаг-крен обязан кормить гост-пул), случилось [spec_ghost] (после 4 попыток)")

/// Проверяет механику семейств: общий фолл-офф повторов (запуски любого члена гасят вес всех),
/// паузу семейства в filter_candidates и учёт запусков в note_fired.
/datum/unit_test/director_family_mechanics

/datum/unit_test/director_family_mechanics/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.family_fired_counts = list()
		SSdirector.family_last_fired_at = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1,
		)

		var/datum/director_action/test_stub/kin_one = new
		kin_one.family = "test_kin"
		var/datum/director_action/test_stub/kin_two = new
		kin_two.family = "test_kin"
		var/datum/director_action/test_stub/loner = new
		SSdirector.actions = list(kin_one, kin_two, loner)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		// Чистый стол: все трое - кандидаты.
		var/list/candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT_EQUAL(length(candidates), 3, "На чистом столе все три действия должны быть кандидатами")

		// note_fired обязан вести счётчики семейства.
		SSdirector.note_fired(kin_one)
		TEST_ASSERT_EQUAL(SSdirector.family_fired_counts["test_kin"], 1, "note_fired должен считать запуск семейства")
		TEST_ASSERT_EQUAL(SSdirector.family_last_fired_at["test_kin"], SSdirector.now(), "note_fired должен обновлять время семейства")
		// note_fired двигает и паузу ступени - возвращаем её в прошлое, чтобы проверить именно семейный гейт.
		SSdirector.last_fired_at[DIRECTOR_SEVERITY_MINOR] = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1

		// Пауза семейства: оба родственника отсечены, одиночка проходит.
		var/list/reject_stats = list()
		candidates = SSdirector.filter_candidates(signals, FALSE, reject_stats)
		TEST_ASSERT(!(kin_one in candidates), "Свежий запуск семейства должен отсекать его члена")
		TEST_ASSERT(!(kin_two in candidates), "Свежий запуск семейства должен отсекать ДРУГОГО члена семейства")
		TEST_ASSERT(loner in candidates, "Действие вне семейства не должно гейтиться чужой паузой")
		var/list/minor_stats = reject_stats[DIRECTOR_SEVERITY_MINOR]
		TEST_ASSERT_EQUAL(minor_stats[DIRECTOR_REJECT_FAMILY], 2, "Оба члена семейства должны попасть в счётчик family_spacing")

		// Пауза истекла: семейство снова в пуле, но фолл-офф общий - kin_two ни разу не стрелял сам,
		// а весит как ветеран из-за запуска kin_one.
		SSdirector.family_last_fired_at["test_kin"] = world.time - profile.family_spacing - 1
		kin_one.occurrences = 1 // боевой путь: spend_and_execute инкрементирует стрелявшему
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(kin_two in candidates, "После истечения паузы член семейства должен вернуться в пул")
		TEST_ASSERT(candidates[kin_two] < candidates[loner], "Фолл-офф семейства должен резать вес не стрелявшего члена ([candidates[kin_two]] против [candidates[loner]])")
		TEST_ASSERT_EQUAL(candidates[kin_one], candidates[kin_two], "Члены семейства с общим счётчиком должны весить одинаково")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет глобальную паузу битов: сразу после любого запуска бит простаивает целиком,
/// после истечения паузы стреляет, форс админа проходит мимо гейта.
/datum/unit_test/director_global_spacing

/datum/unit_test/director_global_spacing/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1,
		)
		// dry_run: решения учитываются без реального исполнения и форс-праздников.
		SSdirector.dry_run = TRUE
		SSdirector.pending_action = null

		var/datum/director_action/test_stub/ready_action = new
		SSdirector.actions = list(ready_action)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		// Только что был запуск: бит обязан простаивать, причина - в статистике отсева.
		// Таймер тишины тоже свежий - гарантия не должна пробивать глобальную паузу в этом тесте.
		SSdirector.last_any_fired_at = world.time
		SSdirector.last_real_fired_at = world.time
		TEST_ASSERT_EQUAL(SSdirector.run_beat(signals), DIRECTOR_BEAT_IDLE, "Бит внутри глобальной паузы должен простаивать")
		TEST_ASSERT_EQUAL(SSdirector.fired_counts[DIRECTOR_SEVERITY_MINOR] || 0, 0, "Внутри глобальной паузы запусков быть не должно")

		// Форс админа проходит мимо гейта.
		TEST_ASSERT_EQUAL(SSdirector.run_beat(signals, forced = TRUE), DIRECTOR_BEAT_FIRED, "Форс-бит должен игнорировать глобальную паузу")
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1,
		)

		// Пауза истекла (но затишье короче max_quiet_time - обычный путь, не гарантированный).
		SSdirector.last_any_fired_at = world.time - profile.global_spacing - 1
		TEST_ASSERT_EQUAL(SSdirector.run_beat(signals), DIRECTOR_BEAT_FIRED, "Бит за глобальной паузой обязан стрелять")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет уровни навязчивости: дефолты от severity, явную метку, множитель веса профиля
/// и полное исключение метки нулевым множителем.
/datum/unit_test/director_disruption

/datum/unit_test/director_disruption/Run()
	// Дефолты get_disruption от ступени и приоритет явной метки.
	var/datum/director_action/test_stub/probe = new
	probe.severity = DIRECTOR_SEVERITY_FLAVOR
	TEST_ASSERT_EQUAL(probe.get_disruption(), DIRECTOR_DISRUPTION_AMBIENT, "Флавор по умолчанию фоновый")
	probe.severity = DIRECTOR_SEVERITY_MINOR
	TEST_ASSERT_EQUAL(probe.get_disruption(), DIRECTOR_DISRUPTION_MILD, "MINOR по умолчанию mild")
	probe.severity = DIRECTOR_SEVERITY_MODERATE
	TEST_ASSERT_EQUAL(probe.get_disruption(), DIRECTOR_DISRUPTION_DISRUPTIVE, "MODERATE по умолчанию disruptive")
	probe.severity = DIRECTOR_SEVERITY_MINOR
	probe.disruption = DIRECTOR_DISRUPTION_DISRUPTIVE
	TEST_ASSERT_EQUAL(probe.get_disruption(), DIRECTOR_DISRUPTION_DISRUPTIVE, "Явная метка должна перекрывать дефолт от ступени")

	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		profile.disruption_weight_mults = list(
			DIRECTOR_DISRUPTION_AMBIENT = 1,
			DIRECTOR_DISRUPTION_MILD = 0.5,
			DIRECTOR_DISRUPTION_DISRUPTIVE = 0,
		)
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1,
		)

		var/datum/director_action/test_stub/ambient_action = new
		ambient_action.disruption = DIRECTOR_DISRUPTION_AMBIENT
		var/datum/director_action/test_stub/mild_action = new // MINOR -> mild по дефолту
		var/datum/director_action/test_stub/heavy_action = new
		heavy_action.disruption = DIRECTOR_DISRUPTION_DISRUPTIVE
		SSdirector.actions = list(ambient_action, mild_action, heavy_action)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/list/reject_stats = list()
		var/list/candidates = SSdirector.filter_candidates(signals, FALSE, reject_stats)
		TEST_ASSERT(ambient_action in candidates, "Фоновое действие должно проходить")
		TEST_ASSERT(mild_action in candidates, "Mild-действие должно проходить с урезанным весом")
		TEST_ASSERT(!(heavy_action in candidates), "Нулевой множитель метки должен исключать действие")
		TEST_ASSERT_EQUAL(candidates[mild_action], candidates[ambient_action] / 2, "Множитель 0.5 должен вдвое резать вес mild-действия")
		var/list/minor_stats = reject_stats[DIRECTOR_SEVERITY_MINOR]
		TEST_ASSERT_EQUAL(minor_stats[DIRECTOR_REJECT_DISRUPTION], 1, "Исключение по навязчивости должно попасть в счётчик disruption")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет филлер-гейт гарантированного бита: пустышки (filler = TRUE) не выбираются после
/// долгой тишины, но живут в обычных битах наравне со всеми.
/datum/unit_test/director_filler_guaranteed

/datum/unit_test/director_filler_guaranteed/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1,
		)

		var/datum/director_action/test_stub/filler_action = new
		filler_action.filler = TRUE
		var/datum/director_action/test_stub/real_action = new
		SSdirector.actions = list(filler_action, real_action)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/list/candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(filler_action in candidates, "Филлер должен участвовать в обычном бите")
		TEST_ASSERT(real_action in candidates, "Контрольное действие должно участвовать в обычном бите")

		candidates = SSdirector.filter_candidates(signals, guaranteed = TRUE)
		TEST_ASSERT(!(filler_action in candidates), "Гарантированный бит не должен выбирать филлер")
		TEST_ASSERT(real_action in candidates, "Гарантированный бит обязан видеть реальное действие")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет гарантированный бит при стелс-антагах и флейвор-маскировке: таймер тишины двигает
/// только реальный контент (не флейвор и не филлер), порог intensity смотрит на видимую
/// событийную нагрузку (event_intensity), а не на стелс-вклад живых рулсетов, бюджет игнорируется.
/datum/unit_test/director_quiet_guarantee

/datum/unit_test/director_quiet_guarantee/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(0) // кошельки пусты: гарантия обязана стрелять мимо бюджета
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		// Тесты бегут в начале мира: world.time мал, и пустой last_fired_at (точка отсчёта 0)
		// не проходит паузу ступени - ставим последний запуск явно за паузой.
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1,
		)
		SSdirector.dry_run = TRUE
		SSdirector.pending_action = null

		var/datum/director_action/test_stub/real_action = new
		real_action.cost = 5
		SSdirector.actions = list(real_action)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		// Видимая нагрузка: события и внешние вклады считаются, антаг-пул (мосты) - нет.
		SSdirector.intensity_ledger = list(
			list("Тестовое событие", 10, 0, DIRECTOR_SEVERITY_MODERATE),
			list("Мост антаг-инжекции", 15, 0, DIRECTOR_SEVERITY_ANTAG),
			list("Внешний вклад", 5, 0, null),
		)
		TEST_ASSERT_EQUAL(SSdirector.get_event_intensity(), 15, "Видимая нагрузка = события + внешние вклады, без антаг-пула")
		SSdirector.intensity_ledger = list()

		// Флейвор капал только что (глобальная пауза активна), реального контента не было дольше
		// max_quiet_time, стелс-intensity высокая, но видимой нагрузки нет - гарантия обязана
		// пробить и глобальную паузу, и пустой кошелёк, и стелс-intensity.
		SSdirector.last_any_fired_at = world.time - 30 SECONDS
		SSdirector.last_real_fired_at = world.time - profile.max_quiet_time - 1
		signals.active_intensity = 60
		signals.event_intensity = 0
		var/list/probe_stats = list()
		var/list/probe = SSdirector.filter_candidates(signals, TRUE, probe_stats)
		TEST_ASSERT(length(probe), "Стаб обязан проходить гарантированный фильтр, отсев: [json_encode(probe_stats)]")
		TEST_ASSERT_EQUAL(SSdirector.run_beat(signals), DIRECTOR_BEAT_GUARANTEED, "Гарантия обязана пробивать флейвор-маскировку, стелс-intensity и пустой кошелёк")
		TEST_ASSERT_EQUAL(SSdirector.fired_counts[DIRECTOR_SEVERITY_MINOR], 1, "Гарантированный бит обязан реально запустить действие")

		// Контроль: видимая событийная нагрузка на пороге глушит гарантию, бит держит глобальная пауза.
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1,
		)
		SSdirector.last_any_fired_at = world.time - 30 SECONDS
		SSdirector.last_real_fired_at = world.time - profile.max_quiet_time - 1
		signals.event_intensity = profile.quiet_intensity_threshold
		TEST_ASSERT_EQUAL(SSdirector.run_beat(signals), DIRECTOR_BEAT_IDLE, "При видимой нагрузке на пороге гарантия молчит и глобальная пауза держит бит")

		// note_fired: флейвор и филлер не двигают таймер тишины, реальный контент двигает.
		var/datum/director_action/test_stub/flavor_action = new
		flavor_action.severity = DIRECTOR_SEVERITY_FLAVOR
		var/datum/director_action/test_stub/filler_action = new
		filler_action.filler = TRUE
		SSdirector.last_real_fired_at = 12345
		SSdirector.note_fired(flavor_action)
		TEST_ASSERT_EQUAL(SSdirector.last_real_fired_at, 12345, "Флейвор не должен двигать таймер тишины")
		SSdirector.note_fired(filler_action)
		TEST_ASSERT_EQUAL(SSdirector.last_real_fired_at, 12345, "Филлер не должен двигать таймер тишины")
		SSdirector.note_fired(real_action)
		TEST_ASSERT_NOTEQUAL(SSdirector.last_real_fired_at, 12345, "Реальный контент обязан двигать таймер тишины")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет клапан антаг-давления: цель масштабируется от экипажа, дефицит удваивает долю
/// антаг-пулов в капле (сумма раздачи не меняется), насыщение останавливает накопление
/// и закрывает антаг-действия в битах причиной antag_saturated.
/datum/unit_test/director_antag_pressure_valve

/datum/unit_test/director_antag_pressure_valve/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(0)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.actions = list()

		TEST_ASSERT_EQUAL(SSdirector.antag_target(40), 40 * profile.antag_intensity_per_crew, "Цель антаг-нагрузки должна масштабироваться от экипажа")

		// Дефицит (антагов нет вообще): полный, антаг-капля идёт полным ходом.
		TEST_ASSERT_EQUAL(SSdirector.antag_deficit(40), 1, "Станция без антагов - полный дефицит")
		SSdirector.feed_antag_pools(10)
		var/antag_wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT(abs(antag_wallets - 10) < 0.01, "feed_antag_pools обязан отдавать всю сумму антаг-кошелькам ([antag_wallets] из 10)")
		var/expected_antag_split = 10 * profile.pool_shares[DIRECTOR_SEVERITY_ANTAG] / (profile.pool_shares[DIRECTOR_SEVERITY_ANTAG] + profile.pool_shares[DIRECTOR_SEVERITY_GHOST])
		TEST_ASSERT(abs(SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] - expected_antag_split) < 0.01, "Раздача антаг-капли должна делиться по pool_shares")

		// Событийная капля антаг-кошельки не трогает: у них собственный дефицит-поток.
		SSdirector.reset_budgets(0)
		SSdirector.distribute_to_budgets(10, include_antag_pools = FALSE)
		TEST_ASSERT_EQUAL(SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG], 0, "Событийная капля не должна кормить антаг-кошельки")
		var/total = SSdirector.total_budget()
		TEST_ASSERT(abs(total - 10) < 0.01, "Событийная капля обязана раздать всю сумму по событийным ступеням ([total] из 10)")
		// Разовые вливания (донат, initial_grant, кнопка админа) раздаются по всем кошелькам.
		SSdirector.reset_budgets(0)
		SSdirector.distribute_to_budgets(10)
		TEST_ASSERT(SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] > 0, "Разовые вливания должны кормить и антаг-кошельки")

		// Полунагрузка: дефицит пропорционален (1 - load/target).
		SSdirector.intensity_ledger = list(list("Полунагрузка", SSdirector.antag_target(40) * 0.5, 0, DIRECTOR_SEVERITY_ANTAG))
		TEST_ASSERT(abs(SSdirector.antag_deficit(40) - 0.5) < 0.01, "Дефицит при нагрузке в полцели должен быть 0.5")

		// Насыщение: антаг-нагрузка в ledger выше цели - дефицит нулевой, капля стоит.
		SSdirector.intensity_ledger = list(list("Тяжёлая инжекция", SSdirector.antag_target(40) + 5, 0, DIRECTOR_SEVERITY_ANTAG))
		TEST_ASSERT_EQUAL(SSdirector.antag_deficit(40), 0, "Нагрузка на цели должна останавливать накопление антаг-кошельков")

		// Гейт насыщения в битах: антаг-действие отсеивается с причиной antag_saturated.
		var/datum/director_action/test_stub/antag_action = new
		antag_action.severity = DIRECTOR_SEVERITY_ANTAG
		SSdirector.actions = list(antag_action)
		SSdirector.reset_budgets(100)
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_ANTAG = world.time - profile.antag_light_spacing - 1,
		)
		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)
		var/list/reject_stats = list()
		var/list/candidates = SSdirector.filter_candidates(signals, FALSE, reject_stats)
		TEST_ASSERT(!(antag_action in candidates), "Насыщение должно закрывать антаг-действия в битах")
		var/list/antag_stats = reject_stats[DIRECTOR_SEVERITY_ANTAG]
		TEST_ASSERT_EQUAL(antag_stats[DIRECTOR_REJECT_ANTAG_SATURATED], 1, "Отсев должен считаться причиной antag_saturated")

		// Контроль: без нагрузки то же действие проходит фильтры.
		SSdirector.intensity_ledger = list()
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(antag_action in candidates, "Без нагрузки антаг-действие обязано проходить фильтры")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет копилку антаг-пула: цель роллится по весам без оглядки на кошелёк (латеджойны
/// целью не становятся), дешёвые соседи по пулу блокируются причиной saving и не выжигают
/// кошелёк, накопленный кошелёк пропускает цель, запуск цели снимает копилку.
/datum/unit_test/director_antag_pool_saving

/datum/unit_test/director_antag_pool_saving/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(10)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.pool_saving = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_ANTAG = world.time - profile.antag_light_spacing - 1,
		)

		var/datum/director_action/test_stub/cheap = new
		cheap.severity = DIRECTOR_SEVERITY_ANTAG
		cheap.cost = 5
		cheap.weight = 0 // ролл цели обязан детерминированно выбрать дорогое
		var/datum/director_action/test_stub/expensive = new
		expensive.severity = DIRECTOR_SEVERITY_ANTAG
		expensive.cost = 20
		// Латеджойн с огромным весом: целью копилки стать не должен (стреляет только в окно захода).
		var/datum/dynamic_ruleset/latejoin/test_pool_isolation/latejoin_rule = new
		latejoin_rule.mode = null
		latejoin_rule.weight = 100
		SSdirector.actions = list(cheap, expensive, latejoin_rule)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/datum/director_action/target = SSdirector.roll_pool_target(DIRECTOR_SEVERITY_ANTAG, signals)
		TEST_ASSERT_EQUAL(target, expensive, "Ролл цели должен идти по весам без гейта кошелька и мимо латеджойнов")

		// Кошелёк 10: дешёвое (5) заблокировано копилкой, дорогое (20) - кошельком. Пул копит.
		cheap.weight = 10
		var/list/reject_stats = list()
		var/list/candidates = SSdirector.filter_candidates(signals, FALSE, reject_stats)
		TEST_ASSERT(!(cheap in candidates), "Дешёвое действие не должно выжигать копилку пула")
		TEST_ASSERT(!(expensive in candidates), "Цель без накопленного кошелька ещё не кандидат")
		var/list/antag_stats = reject_stats[DIRECTOR_SEVERITY_ANTAG]
		TEST_ASSERT_EQUAL(antag_stats[DIRECTOR_REJECT_SAVING], 1, "Дешёвое должно отсеиваться причиной saving")

		// Накопили: цель проходит, дешёвое всё ещё ждёт своей очереди.
		SSdirector.reset_budgets(25)
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(expensive in candidates, "Накопленный кошелёк обязан пропустить цель")
		TEST_ASSERT(!(cheap in candidates), "Дешёвое ждёт, пока цель не исполнится")

		// Запуск цели снимает копилку - следующий бит отроллит новую.
		SSdirector.note_fired(expensive)
		TEST_ASSERT(isnull(SSdirector.pool_saving[DIRECTOR_SEVERITY_ANTAG]), "Запуск цели должен снимать копилку")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Проверяет независимость латеджойн-канала от полосы битов: note_fired(from_latejoin = TRUE)
/// двигает только свой трек (last_latejoin_at) и штампует executed_at рулсета, не трогая
/// ступенчатые паузы, глобальную паузу, таймер тишины и счётчики долей ступеней.
/datum/unit_test/director_latejoin_channel

/datum/unit_test/director_latejoin_channel/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list()
		SSdirector.last_latejoin_at = 0
		SSdirector.last_any_fired_at = world.time - 5 MINUTES
		SSdirector.last_real_fired_at = world.time - 5 MINUTES
		var/frozen_any = SSdirector.last_any_fired_at
		var/frozen_real = SSdirector.last_real_fired_at

		var/datum/dynamic_ruleset/latejoin/test_pool_isolation/rule = new
		rule.mode = null
		SSdirector.note_fired(rule, from_latejoin = TRUE)
		TEST_ASSERT(SSdirector.last_latejoin_at > 0, "Латеджойн-инжекция должна двигать свой трек спейсинга")
		TEST_ASSERT(rule.executed_at > 0, "Латеджойн-инжекция должна штамповать executed_at рулсета")
		TEST_ASSERT(isnull(SSdirector.last_fired_at[DIRECTOR_SEVERITY_ANTAG]), "Латеджойн не должен запирать полосу ANTAG битов")
		TEST_ASSERT_EQUAL(SSdirector.last_any_fired_at, frozen_any, "Латеджойн не должен трогать глобальную паузу битов")
		TEST_ASSERT_EQUAL(SSdirector.last_real_fired_at, frozen_real, "Латеджойн не должен сбрасывать таймер тишины")
		TEST_ASSERT(!SSdirector.fired_counts[DIRECTOR_SEVERITY_ANTAG], "Латеджойн не должен искажать доли ступеней (share_correction)")

		// Контроль: тот же запуск через бит двигает и полосу ступени, и счётчики.
		SSdirector.note_fired(rule)
		TEST_ASSERT(!isnull(SSdirector.last_fired_at[DIRECTOR_SEVERITY_ANTAG]), "Запуск битом обязан двигать полосу ступени")
		TEST_ASSERT_EQUAL(SSdirector.fired_counts[DIRECTOR_SEVERITY_ANTAG], 1, "Запуск битом обязан считаться в долях ступеней")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Сторожевой тест инварианта основателя: верхушка малой категории - пустышка "Nothing"
/// и лампочки "Faulty Lighting". Никакое другое включённое MINOR-событие не должно весить больше.
/datum/unit_test/director_minor_filler_top

/datum/unit_test/director_minor_filler_top/Run()
	var/datum/round_event_control/nothing/nothing_control = locate() in SSdirector.actions
	var/datum/round_event_control/faulty_lighting/lighting_control = locate() in SSdirector.actions
	TEST_ASSERT_NOTNULL(nothing_control, "Событие Nothing должно быть зарегистрировано у директора")
	TEST_ASSERT_NOTNULL(lighting_control, "Событие Faulty Lighting должно быть зарегистрировано у директора")
	TEST_ASSERT(nothing_control.enabled && !nothing_control.admin_only, "Nothing должно быть доступно естественному выбору")
	TEST_ASSERT(lighting_control.enabled && !lighting_control.admin_only, "Faulty Lighting должно быть доступно естественному выбору")
	for(var/datum/director_action/action as anything in SSdirector.actions)
		if(action.severity != DIRECTOR_SEVERITY_MINOR || !action.enabled || action.admin_only)
			continue
		if(action.director_kind != DIRECTOR_KIND_EVENT)
			continue
		TEST_ASSERT(action.weight <= nothing_control.weight, "[action.action_name()] весит больше пустышки ([action.weight] против [nothing_control.weight]) - верхушка малой категории должна оставаться за \"ничего и лампочками\"")

/// Проверяет активность антагов: гейт "только жёсткие антаги" в bump, кап, ленивое затухание
/// с полураспадом (без перезаписи score чтением) и перевод score в множитель вклада.
/datum/unit_test/director_antag_activity

/datum/unit_test/director_antag_activity/Run()
	var/mob/living/carbon/human/antag = allocate(/mob/living/carbon/human)
	antag.mind_initialize()
	var/datum/antagonist/marker = new
	marker.silent = TRUE
	antag.mind.add_antag_datum(marker)

	var/mob/living/carbon/human/civilian = allocate(/mob/living/carbon/human)
	civilian.mind_initialize()

	// Не-антаг игнорируется: шум мирного экипажа не должен попадать в score.
	SSdirector.bump_antag_activity(civilian.mind, DIRECTOR_ACTIVITY_KILL)
	TEST_ASSERT_EQUAL(civilian.mind.director_activity, 0, "bump не должен начислять score не-антагу")

	// Начисление и кап.
	SSdirector.bump_antag_activity(antag.mind, DIRECTOR_ACTIVITY_KILL)
	TEST_ASSERT_EQUAL(SSdirector.antag_activity(antag.mind), DIRECTOR_ACTIVITY_KILL, "bump должен начислять score антагу")
	SSdirector.bump_antag_activity(antag.mind, DIRECTOR_ACTIVITY_CAP * 10)
	TEST_ASSERT_EQUAL(SSdirector.antag_activity(antag.mind), DIRECTOR_ACTIVITY_CAP, "score должен клампиться на капе")

	// Затухание: через полураспад остаётся ровно половина, чтение не переписывает score.
	antag.mind.director_activity = DIRECTOR_ACTIVITY_CAP
	antag.mind.director_activity_at = world.time - DIRECTOR_ACTIVITY_HALF_LIFE
	TEST_ASSERT_EQUAL(SSdirector.antag_activity(antag.mind), DIRECTOR_ACTIVITY_CAP / 2, "Через полураспад должна остаться половина score")
	TEST_ASSERT_EQUAL(antag.mind.director_activity, DIRECTOR_ACTIVITY_CAP, "Чтение активности не должно переписывать score на mind")

	// Множитель вклада: тихоня на минимуме, кап - на максимуме.
	antag.mind.director_activity = 0
	TEST_ASSERT_EQUAL(SSdirector.antag_activity_mult(antag.mind), DIRECTOR_ACTIVITY_MULT_MIN, "Тихоня должен весить минимум")
	antag.mind.director_activity = DIRECTOR_ACTIVITY_CAP
	antag.mind.director_activity_at = world.time
	TEST_ASSERT_EQUAL(SSdirector.antag_activity_mult(antag.mind), DIRECTOR_ACTIVITY_MULT_MAX, "Кап активности должен весить максимум")

/// Проверяет профильный гейт тяжёлых антагов (antag_heavy_enabled = FALSE у Light/Extended):
/// heavy-действие отсеивается причиной antag_heavy_off и не становится целью копилки,
/// лёгкое живёт; включённый профиль пропускает heavy (контроль от вакуума).
/datum/unit_test/director_antag_heavy_gate

/datum/unit_test/director_antag_heavy_gate/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		profile.antag_heavy_enabled = FALSE
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.pool_saving = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_GHOST = world.time - profile.ghost_light_spacing - 1,
		)
		SSdirector.last_ghost_heavy_at = world.time - profile.ghost_heavy_spacing - 1

		var/datum/director_action/test_stub/light_action = new
		light_action.severity = DIRECTOR_SEVERITY_GHOST
		var/datum/director_action/test_stub/heavy_action = new
		heavy_action.severity = DIRECTOR_SEVERITY_GHOST
		heavy_action.antag_heavy = TRUE
		heavy_action.weight = 100 // ролл цели детерминированно выбрал бы его, если бы гейт не работал
		SSdirector.actions = list(light_action, heavy_action)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/list/reject_stats = list()
		var/list/candidates = SSdirector.filter_candidates(signals, FALSE, reject_stats)
		TEST_ASSERT(light_action in candidates, "Лёгкое гост-действие должно проходить при выключенных heavy")
		TEST_ASSERT(!(heavy_action in candidates), "Heavy-действие при antag_heavy_enabled = FALSE должно отсеиваться")
		var/list/ghost_stats = reject_stats[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(ghost_stats[DIRECTOR_REJECT_ANTAG_HEAVY], 1, "Отсев должен считаться причиной antag_heavy_off")

		TEST_ASSERT_EQUAL(SSdirector.roll_pool_target(DIRECTOR_SEVERITY_GHOST, signals), light_action, "Цель копилки не должна выбирать выключенный heavy")

		// Контроль: профиль с включёнными heavy пропускает то же действие.
		profile.antag_heavy_enabled = TRUE
		SSdirector.pool_saving = list()
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(heavy_action in candidates, "При antag_heavy_enabled = TRUE heavy-действие обязано проходить")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Сторожевой тест регрессии "на эксте раньше спаунились антаги": все события-спавнеры гост-ролей
/// обязаны жить в GHOST-пуле (а не в MAJOR, который у Light/Extended выключен долей 0), с ненулевыми
/// cost/intensity и долгим linger - вклад держит antag_load, пока спавненный антаг живёт.
/// Исключения: wizard-события (пул Summon Events), праздничные (holidayID) и осознанно
/// не-антагские (sentience - дружелюбная, qareen - джинн не гарантированно враждебен).
/datum/unit_test/director_ghost_event_classification

/datum/unit_test/director_ghost_event_classification/Run()
	// По именам, не тайп-пасам: qareen живёт в modular_splurt и не входит в текущую сборку -
	// ссылка на его тип не компилируется, а событие при подключении обязано остаться исключением.
	var/list/exempt_names = list("Random Human-level Intelligence", "Station-wide Human-level Intelligence", "Spawn Qareen")
	for(var/datum/round_event_control/control as anything in SSdirector.event_controls())
		if(control.wizardevent || control.holidayID || (control.name in exempt_names))
			continue
		if(!ispath(control.typepath, /datum/round_event/ghost_role))
			continue
		var/control_name = control.action_name()
		TEST_ASSERT_EQUAL(control.severity, DIRECTOR_SEVERITY_GHOST, "[control_name]: событие-спавнер гост-роли обязано жить в GHOST-пуле")
		TEST_ASSERT(control.cost > 0, "[control_name]: гост-антаг событие без cost")
		TEST_ASSERT(control.intensity > 0, "[control_name]: гост-антаг событие без intensity")
		TEST_ASSERT(control.intensity_linger >= 30 MINUTES, "[control_name]: вклад гост-антага обязан жить после спавнера (linger)")
	// Пираты и рейдеры реализованы обычными событиями (не ghost_role), но поллят призраков.
	var/datum/round_event_control/pirates/pirates_control = locate() in SSdirector.actions
	TEST_ASSERT_NOTNULL(pirates_control, "Событие Space Pirates должно быть зарегистрировано у директора")
	TEST_ASSERT_EQUAL(pirates_control.severity, DIRECTOR_SEVERITY_GHOST, "Space Pirates обязаны жить в GHOST-пуле")
	var/datum/round_event_control/raiders/raiders_control = locate() in SSdirector.actions
	TEST_ASSERT_NOTNULL(raiders_control, "Событие InteQ Raiders должно быть зарегистрировано у директора")
	TEST_ASSERT_EQUAL(raiders_control.severity, DIRECTOR_SEVERITY_GHOST, "InteQ Raiders обязаны жить в GHOST-пуле")

	// Профили: гост-пул реально достижим на Light/Extended (сама причина регрессии - доля 0),
	// тяжёлые антаг-команды на фоновых профилях выключены.
	var/datum/director_profile/extended_profile = director_profile_for(ROUNDTYPE_EXTENDED)
	TEST_ASSERT(extended_profile.pool_shares[DIRECTOR_SEVERITY_GHOST] > 0, "У Extended должна быть ненулевая доля GHOST - иначе гост-антаги не появятся никогда")
	TEST_ASSERT(!extended_profile.antag_heavy_enabled, "Extended не должен пускать тяжёлые антаг-команды")
	var/datum/director_profile/light_profile = director_profile_for(ROUNDTYPE_DYNAMIC_LIGHT)
	TEST_ASSERT(light_profile.pool_shares[DIRECTOR_SEVERITY_GHOST] > 0, "У Light должна быть ненулевая доля GHOST")
	TEST_ASSERT(light_profile.pool_shares[DIRECTOR_SEVERITY_ANTAG] > 0, "У Light должна быть ненулевая доля ANTAG")
	TEST_ASSERT(!light_profile.antag_heavy_enabled, "Light не должен пускать тяжёлые антаг-команды")

/// Политика Dynamic Light: автоматические гост-инжекции ограничены малыми беглецами
/// и мирным вариантом Lone Operative, который защищает диск.
/// Боевые гост-антаги исторически убраны из Light у dynamic-ruleset'ов и не должны возвращаться
/// через одноимённые event control'ы директора (именно так в Light смог выпасть Space Dragon).
/datum/unit_test/director_light_ghost_policy

/datum/unit_test/director_light_ghost_policy/Run()
	var/list/allowed_light_ghost_controls = list(
		/datum/round_event_control/fugitives,
		/datum/round_event_control/operative/keeper,
	)
	var/datum/round_event_control/operative/keeper/keeper_control = locate() in SSdirector.event_controls()
	TEST_ASSERT_NOTNULL(keeper_control, "Случайный защитник диска должен быть зарегистрирован у директора")
	TEST_ASSERT(!keeper_control.admin_only, "Защитник диска должен выпадать случайно, а не только через админ-форс")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_LIGHT in keeper_control.required_round_type, "Защитник диска должен быть доступен в Dynamic Light")
	TEST_ASSERT_EQUAL(keeper_control.typepath, /datum/round_event/ghost_role/operative/keeper, "Случайный Lone Operative должен получать роль защитника диска")
	for(var/datum/round_event_control/control as anything in SSdirector.event_controls())
		if(control.severity != DIRECTOR_SEVERITY_GHOST || !control.enabled || control.admin_only || control.weight <= 0)
			continue
		if(control.required_round_type && !(ROUNDTYPE_DYNAMIC_LIGHT in control.required_round_type))
			continue
		var/is_allowed = FALSE
		for(var/allowed_type in allowed_light_ghost_controls)
			if(istype(control, allowed_type))
				is_allowed = TRUE
				break
		TEST_ASSERT(is_allowed, "[control.action_name()]: автоматический гост-антаг не разрешён политикой Dynamic Light")

/// Проверяет рефанд провального спавна гост-роли: попытка, кошелёк ступени и вклад intensity
/// возвращаются сразу (иначе фантомная нагрузка глушила бы клапан давления 30 минут),
/// форс админа (не triggered_randomly) кошелёк не трогает.
/datum/unit_test/director_ghost_spawn_refund

/datum/unit_test/director_ghost_spawn_refund/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. комментарий в director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	var/datum/round_event/ghost_role/event
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(0)
		SSdirector.intensity_ledger = list()
		var/datum/round_event_control/nightmare/control = locate() in SSdirector.actions
		TEST_ASSERT_NOTNULL(control, "Событие Spawn Nightmare должно быть зарегистрировано у директора")

		// Ручная симуляция боевого запуска: учёт попытки + вклад в ledger (кошелёк уже списан в 0).
		var/occurrences_before = control.occurrences
		control.occurrences++
		SSdirector.intensity_ledger += list(list(control.action_name(), control.intensity, 0, control.severity))
		event = new(FALSE)
		SSdirector.running -= event // тестовый датум не должен тикаться подсистемой
		event.control = control
		event.triggered_randomly = TRUE
		event.refund_failed_spawn()
		TEST_ASSERT_EQUAL(control.occurrences, occurrences_before, "Провал спавна должен возвращать попытку")
		TEST_ASSERT_EQUAL(length(SSdirector.intensity_ledger), 0, "Провал спавна должен снимать вклад сразу, без linger")
		TEST_ASSERT_EQUAL(SSdirector.budgets[control.severity], control.cost, "Провал спавна должен возвращать кошелёк ступени")

		// Форс админа шёл мимо кошельков - и рефанд не должен дарить бюджет.
		SSdirector.reset_budgets(0)
		control.occurrences++
		SSdirector.intensity_ledger += list(list(control.action_name(), control.intensity, 0, control.severity))
		event.triggered_randomly = FALSE
		event.refund_failed_spawn()
		TEST_ASSERT_EQUAL(control.occurrences, occurrences_before, "Провал форс-спавна тоже должен возвращать попытку")
		TEST_ASSERT_EQUAL(SSdirector.budgets[control.severity], 0, "Провал форс-спавна не должен дарить кошельку бюджет")
	catch(var/exception/e)
		if(event)
			SSdirector.running -= event
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.running -= event
	SSdirector.restore_simulation_state(saved)
