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

/// Фикстура синхронного отказа: директор не должен записывать такой выбор как успешный запуск.
/datum/director_action/test_stub/fails

/datum/director_action/test_stub/fails/execute_action()
	return FALSE

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
	var/saved_antag_deficit = SSdirector.last_antag_deficit
	var/expected_antag_deficit = 0.37
	SSdirector.last_antag_deficit = expected_antag_deficit
	var/list/log_out = director_simulate(ROUNDTYPE_DYNAMIC_MEDIUM, 2, 40)
	var/restored_antag_deficit = SSdirector.last_antag_deficit
	SSdirector.last_antag_deficit = saved_antag_deficit
	TEST_ASSERT_EQUAL(restored_antag_deficit, expected_antag_deficit, "Симуляция обязана восстановить реальный кэш дефицита антагов")
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

	// Мягкие профили: Light и Extended живут, но без MAJOR и без тяжёлых антаг-команд;
	// Teambased держит собственный темп. Случайный состав одного прогона годится для диагностики,
	// но не для ассерта "обязательно выпал GHOST": даже живой пул законно может проиграть все
	// pickweight-роллы за два часа. Структурную достижимость GHOST (контент, долю и накопление
	// бюджета) без RNG проверяет director_profile_ghost_reachability ниже.
	var/list/soft_specs = list(
		list(ROUNDTYPE_DYNAMIC_LIGHT, 30, 4),
		list(ROUNDTYPE_EXTENDED, 30, 3),
		list(ROUNDTYPE_DYNAMIC_TEAMBASED, 40, 8),
	)
	for(var/list/spec in soft_specs)
		var/spec_type = spec[1]
		var/spec_crew = spec[2]
		var/spec_min_fired = spec[3]
		var/list/spec_log = director_simulate(spec_type, 2, spec_crew)
		var/spec_fired = 0
		var/spec_ghost = 0
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
		log_world("DIRECTOR SIM: [spec_type]@[spec_crew], 2ч: [spec_fired] запусков ([spec_composition.Join(", ")]), GHOST [spec_ghost]")
		if(spec_type == ROUNDTYPE_DYNAMIC_LIGHT || spec_type == ROUNDTYPE_EXTENDED)
			TEST_ASSERT_EQUAL(spec_heavy, 0, "[spec_type]: тяжёлые антаг-действия обязаны быть выключены профилем, случилось [spec_heavy]")
			TEST_ASSERT_EQUAL(spec_major, 0, "[spec_type]: MAJOR-события обязаны быть недоступны (доля 0), случилось [spec_major]")
		TEST_ASSERT(spec_fired >= spec_min_fired, "За 2 часа [spec_type] при [spec_crew] экипажа должно случиться не меньше [spec_min_fired] действий, случилось [spec_fired]")

/// Детерминированная замена стохастическому ассерту simulation_sanity: для каждого профиля,
/// от которого ожидаются гост-антаги, существует хотя бы одно естественное лёгкое GHOST-действие,
/// доступное заданному онлайну в первые два часа, а полный дефицит-поток успевает оплатить его.
/// Фактический запуск всё ещё зависит от призраков и pickweight — это условия раунда, не инварианты.
/datum/unit_test/director_profile_ghost_reachability

/datum/unit_test/director_profile_ghost_reachability/Run()
	var/list/specs = list(
		// Light оставляет только мягкие гост-конфликты: беглецы и рейд воксов (единственный профиль воксов).
		list(ROUNDTYPE_DYNAMIC_LIGHT, 30, 1),
		list(ROUNDTYPE_EXTENDED, 30, 2),
		list(ROUNDTYPE_DYNAMIC_MEDIUM, 40, 12),
		list(ROUNDTYPE_DYNAMIC_HARD, 40, 12),
		list(ROUNDTYPE_DYNAMIC_TEAMBASED, 40, 12),
	)
	for(var/list/spec in specs)
		var/spec_type = spec[1]
		var/spec_crew = spec[2]
		var/min_role_types = spec[3]
		var/datum/director_profile/profile = director_profile_for(spec_type)
		var/antag_share = profile.pool_shares[DIRECTOR_SEVERITY_ANTAG] || 0
		var/ghost_share = profile.pool_shares[DIRECTOR_SEVERITY_GHOST] || 0
		var/total_antag_share = antag_share + ghost_share
		TEST_ASSERT(ghost_share > 0, "[spec_type]: доля GHOST должна быть ненулевой")
		TEST_ASSERT(profile.antag_drip > 0, "[spec_type]: GHOST-пул не накопит бюджет при antag_drip = 0")
		TEST_ASSERT(total_antag_share > 0, "[spec_type]: сумма долей ANTAG/GHOST должна быть ненулевой")

		var/min_reachable_cost
		var/list/reachable_names = list()
		for(var/datum/round_event_control/control as anything in SSdirector.event_controls())
			if(control.severity != DIRECTOR_SEVERITY_GHOST || !control.enabled || control.admin_only || control.weight <= 0)
				continue
			if(control.antag_heavy && !profile.antag_heavy_enabled)
				continue
			if(control.min_players > spec_crew || control.earliest_start > 2 HOURS)
				continue
			if(control.required_round_type && !(spec_type in control.required_round_type))
				continue
			if(profile.disruption_mult(control) <= 0)
				continue
			reachable_names += control.action_name()
			if(isnull(min_reachable_cost) || control.cost < min_reachable_cost)
				min_reachable_cost = control.cost
		TEST_ASSERT(length(reachable_names) >= min_role_types, "[spec_type]: доступно GHOST-действий [length(reachable_names)] из требуемых [min_role_types] для онлайна [spec_crew] в первые два часа ([reachable_names.Join(", ")])")

		// При пустой антаг-нагрузке deficit = 1; feed_antag_pools делит поток ровно по
		// соотношению ANTAG/GHOST. Это нижняя структурная проверка кошелька без случайного выбора.
		var/two_hour_ghost_budget = profile.antag_drip * 120 * ghost_share / total_antag_share
		TEST_ASSERT(two_hour_ghost_budget >= min_reachable_cost, "[spec_type]: за два часа GHOST-пул накопит [round(two_hour_ghost_budget, 0.1)], но самое дешёвое доступное действие [min_reachable_cost] ([reachable_names.Join(", ")])")

/// Профили намеренно отдают гостам большую часть антаг-канала: каталог шире, а роль не забирается
/// у уже играющего члена экипажа. antag_target по-прежнему ограничивает число живых угроз.
/datum/unit_test/director_antag_pool_balance

/datum/unit_test/director_antag_pool_balance/Run()
	var/list/profile_paths = list(
		/datum/director_profile/light,
		/datum/director_profile/medium,
		/datum/director_profile/hard,
		/datum/director_profile/teambased,
	)
	for(var/profile_path in profile_paths)
		var/datum/director_profile/profile = new profile_path
		var/antag_share = profile.pool_shares[DIRECTOR_SEVERITY_ANTAG]
		var/ghost_share = profile.pool_shares[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT(ghost_share > antag_share, "[profile.round_type]: доля GHOST [ghost_share] должна быть выше ANTAG [antag_share]")
		TEST_ASSERT(profile.ghost_light_spacing < profile.antag_light_spacing, "[profile.round_type]: лёгкий GHOST-трек должен восстанавливаться быстрее ANTAG")
		if(profile.antag_heavy_enabled)
			TEST_ASSERT(profile.ghost_heavy_spacing < profile.antag_heavy_spacing, "[profile.round_type]: тяжёлый GHOST-трек должен восстанавливаться быстрее ANTAG")
		else
			TEST_ASSERT(profile.ghost_heavy_spacing <= profile.antag_heavy_spacing, "[profile.round_type]: выключенный GHOST-heavy трек не должен быть медленнее ANTAG")
		var/ghost_budget = profile.antag_drip * 120 * ghost_share / (antag_share + ghost_share)
		var/antag_budget = profile.antag_drip * 120 * antag_share / (antag_share + ghost_share)
		TEST_ASSERT(ghost_budget > antag_budget, "[profile.round_type]: за два часа GHOST должен получать больше антаг-бюджета, чем ANTAG")

	var/total_ghost_weight = 0
	var/max_ghost_weight = 0
	var/natural_ghost_actions = 0
	var/list/natural_families = list()
	for(var/datum/director_action/action as anything in SSdirector.actions)
		if(action.severity != DIRECTOR_SEVERITY_GHOST || !action.enabled || action.admin_only || action.weight <= 0)
			continue
		if(action.required_round_type && !(ROUNDTYPE_DYNAMIC_MEDIUM in action.required_round_type))
			continue
		natural_ghost_actions++
		total_ghost_weight += action.weight
		max_ghost_weight = max(max_ghost_weight, action.weight)
		if(action.family)
			TEST_ASSERT(!(action.family in natural_families), "GHOST-семейство [action.family] задублировано естественными действиями")
			natural_families += action.family
	TEST_ASSERT(natural_ghost_actions >= 15, "Medium должен иметь хотя бы 15 естественных GHOST-действий, найдено [natural_ghost_actions]")
	TEST_ASSERT(total_ghost_weight > 0 && max_ghost_weight / total_ghost_weight <= 0.15, "Одно GHOST-действие занимает [round(max_ghost_weight / max(1, total_ghost_weight) * 100, 0.1)]% базового веса пула")

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
		// "Реальный" для таймера тишины MINOR обязан нести intensity: лотереи и бумажные
		// события с нулевым вкладом больше не маскируют мёртвый эфир (см. is_real_content).
		real_action.intensity = 5
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

/// Sleeper Agent не должен повторно гейтиться старым глобальным счётчиком антагов: Director уже
/// сравнивает живую антаг-нагрузку со своей целью до can_fire(). Глобальный список может содержать
/// гост-роли/устаревшие тела и в прод-дампе блокировал единственного лёгкого ANTAG-кандидата Medium.
/datum/unit_test/director_autotraitor_uses_pressure_valve

/datum/unit_test/director_autotraitor_uses_pressure_valve/Run()
	var/list/saved = SSdirector.capture_simulation_state()
	var/saved_round_type = GLOB.round_type
	var/datum/game_mode/dynamic/test_mode = new
	var/datum/dynamic_ruleset/midround/autotraitor/rule = new
	try
		TEST_ASSERT_EQUAL(rule.antag_flag_override, ROLE_TRAITOR, "Sleeper Agent обязан использовать существующий общий преференс трейтора")
		GLOB.round_type = ROUNDTYPE_DYNAMIC_MEDIUM
		test_mode.threat_level = 100 // гарантированно проходит базовый requirements-гейт
		test_mode.current_players[CURRENT_LIVING_PLAYERS] = list(
			"crew01", "crew02", "crew03", "crew04", "crew05", "crew06", "crew07", "crew08",
			"crew09", "crew10", "crew11", "crew12", "crew13", "crew14", "crew15", "crew16",
		)
		// Старый autotraitor/acceptable считал бы 3 >= round(16 / 16) + 1 и закрыл действие,
		// хотя собственная нагрузка Director ниже цели (ledger пуст).
		test_mode.current_players[CURRENT_LIVING_ANTAGS] = list("stale_antag1", "stale_antag2", "stale_antag3")
		rule.mode = test_mode

		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(0)
		SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] = rule.cost
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.pool_saving = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_ANTAG = world.time - profile.antag_light_spacing - 1,
		)
		SSdirector.actions = list(rule)

		var/datum/director_signals/signals = new
		signals.effective_crew = 16
		signals.staffing = list(
			DIRECTOR_DEPT_SECURITY = 2,
			DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1,
			DIRECTOR_DEPT_SCIENCE = 1,
			DIRECTOR_DEPT_SUPPLY = 1,
			DIRECTOR_DEPT_COMMAND = 1,
		)
		var/list/candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(rule in candidates, "Sleeper Agent должен проходить при накопленном ANTAG-кошельке и дефиците нагрузки")
	catch(var/exception/e)
		GLOB.round_type = saved_round_type
		SSdirector.restore_simulation_state(saved)
		qdel(rule)
		qdel(test_mode)
		throw e
	GLOB.round_type = saved_round_type
	SSdirector.restore_simulation_state(saved)
	qdel(rule)
	qdel(test_mode)

/// Регресс рантайма "list index out of bounds" в ready(): хард-профиль давал витринную угрозу
/// 110.5 (бюджет 43 + оценка капли 67.5), band-индекс required_enemies выходил за 10 и ронял
/// каждый преflight антаг-пула. Угроза ниже 10 даёт band 0 - тоже мимо списка (экста/форс).
/// ready() обязан клампить band в границы списка, а оценка угрозы - держать шкалу 0-100.
/datum/unit_test/dynamic_threat_scale_bounds

/datum/unit_test/dynamic_threat_scale_bounds/Run()
	var/datum/game_mode/dynamic/test_mode = new
	var/datum/dynamic_ruleset/midround/test_pool_isolation/midround_rule = new
	var/datum/dynamic_ruleset/latejoin/test_pool_isolation/latejoin_rule = new
	try
		test_mode.current_players[CURRENT_LIVING_PLAYERS] = list()
		midround_rule.mode = test_mode
		latejoin_rule.mode = test_mode
		midround_rule.required_enemies = list(0,0,0,0,0,0,0,0,0,0)
		latejoin_rule.required_enemies = list(0,0,0,0,0,0,0,0,0,0)

		test_mode.threat_level = 110.5
		TEST_ASSERT(midround_rule.ready(FALSE), "midround ready() должен переживать угрозу выше 100 (band клампится в границы required_enemies)")
		TEST_ASSERT(latejoin_rule.ready(FALSE), "latejoin ready() должен переживать угрозу выше 100 (band клампится в границы required_enemies)")

		test_mode.threat_level = 5
		TEST_ASSERT(midround_rule.ready(FALSE), "midround ready() должен переживать угрозу ниже 10 (band клампится в 1)")
		TEST_ASSERT(latejoin_rule.ready(FALSE), "latejoin ready() должен переживать угрозу ниже 10 (band клампится в 1)")

		TEST_ASSERT_EQUAL(test_mode.estimate_display_threat(43, 1.5), 100, "витринная оценка угрозы обязана капаться шкалой 0-100 (прод-репро: 43 + 1.5 * 45 = 110.5)")
		// Допуск: round(x, 0.1) во float32 может дать 65.000001
		var/in_scale = test_mode.estimate_display_threat(20, 1)
		TEST_ASSERT(abs(in_scale - 65) < 0.01, "оценка в пределах шкалы не должна искажаться капом (ожидали ~65, получили [in_scale])")
	catch(var/exception/e)
		qdel(midround_rule)
		qdel(latejoin_rule)
		qdel(test_mode)
		throw e
	qdel(midround_rule)
	qdel(latejoin_rule)
	qdel(test_mode)

/// Проверяет копилку антаг-пула: цель роллится по весам без оглядки на кошелёк (латеджойны
/// целью не становятся), дешёвые соседи по пулу блокируются причиной saving и не выжигают
/// кошелёк. Временно закрытый второй трек может тратить только излишек сверх полного резерва.
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

		// Один кошелёк обслуживает два независимых трека. Закрытая heavy-цель остаётся планом
		// и защищает полную цену; готовая light-роль может потратить только бюджет сверх неё.
		var/datum/director_action/test_stub/heavy = new
		heavy.severity = DIRECTOR_SEVERITY_ANTAG
		heavy.antag_heavy = TRUE
		heavy.cost = 20
		heavy.weight = 100
		cheap.weight = 10
		SSdirector.actions = list(cheap, heavy)
		SSdirector.pool_saving[DIRECTOR_SEVERITY_ANTAG] = heavy
		SSdirector.last_fired_at[DIRECTOR_SEVERITY_ANTAG] = world.time - profile.antag_light_spacing - 1
		SSdirector.last_antag_heavy_at = world.time
		SSdirector.ensure_pool_targets(signals)
		TEST_ASSERT_EQUAL(SSdirector.pool_saving[DIRECTOR_SEVERITY_ANTAG], heavy, "Heavy-цель обязана сохраняться на cooldown, иначе light будет постоянно съедать накопление")

		SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] = heavy.cost + cheap.cost - 1
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(!(cheap in candidates), "Light не должен залезать в полный резерв heavy-цели")

		SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] = heavy.cost + cheap.cost
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(cheap in candidates, "Light должен использовать излишек сверх уже накопленной heavy-цели")
		TEST_ASSERT(SSdirector.spend_and_execute(cheap), "Запуск light из свободного остатка должен пройти")
		TEST_ASSERT_EQUAL(SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG], heavy.cost, "После light полная цена heavy должна остаться в кошельке")
		TEST_ASSERT_EQUAL(SSdirector.pool_saving[DIRECTOR_SEVERITY_ANTAG], heavy, "Запуск соседнего трека не должен сбрасывать heavy-план")

		SSdirector.last_fired_at[DIRECTOR_SEVERITY_ANTAG] = world.time - profile.antag_light_spacing - 1
		SSdirector.last_antag_heavy_at = world.time - profile.antag_heavy_spacing - 1
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(heavy in candidates, "Накопленная heavy-цель должна стать кандидатом сразу после cooldown")
		TEST_ASSERT(!(cheap in candidates), "Готовая heavy-цель должна исполниться до новых light-трат")
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
	TEST_ASSERT_EQUAL(antag.mind.director_activity_total, DIRECTOR_ACTIVITY_KILL + DIRECTOR_ACTIVITY_CAP * 10, "Накопленная активность для страховки не должна теряться из-за капа текущего score")

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

/// Прод-регрессия: два roundstart-трейтора за 17 очков исчезли к 27-й минуте, antag_load упал
/// в ноль, а директору вручную вернули 20 бюджета. Подтверждённая стоимость должна делиться
/// между реально выданными ролями, тихая ранняя потеря — возвращать свою долю ровно один раз,
/// активная или слишком поздняя потеря — ничего.
/datum/unit_test/director_antag_loss_refund

/datum/unit_test/director_antag_loss_refund/Run()
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(0)
		SSdirector.time_override = world.time + 1 MINUTES

		var/mob/living/carbon/human/quiet = allocate(/mob/living/carbon/human)
		quiet.mind_initialize()
		var/datum/antagonist/quiet_marker = new
		quiet_marker.silent = TRUE
		quiet.mind.add_antag_datum(quiet_marker)

		var/mob/living/carbon/human/active = allocate(/mob/living/carbon/human)
		active.mind_initialize()
		var/datum/antagonist/active_marker = new
		active_marker.silent = TRUE
		active.mind.add_antag_datum(active_marker)

		var/datum/dynamic_ruleset/midround/test_pool_isolation/rule = new
		rule.intensity = 15
		rule.assigned = list(quiet.mind, active.mind)
		// Точная цена случая из прод-лога: traitor cost 8 + scaling_cost 9.
		rule.director_pending_cost = 17
		SSdirector.confirm_action_success(rule)
		TEST_ASSERT_EQUAL(rule.total_cost, 17, "Подтверждение должно перенести фактически списанную цену в total_cost")
		TEST_ASSERT_EQUAL(length(rule.director_loss_refund_values), 2, "Каждая подтверждённо выданная роль должна получить отдельный полис")

		quiet.stat = DEAD
		SSdirector.tally_ruleset_intensity(rule)
		var/antag_wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(round(antag_wallets, 0.1), 8.5, "Тихая потеря одного из двух трейторов должна вернуть половину цены 17")
		SSdirector.tally_ruleset_intensity(rule)
		antag_wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(round(antag_wallets, 0.1), 8.5, "Повторный подсчёт мёртвой роли не должен печатать бюджет")

		SSdirector.bump_antag_activity(active.mind, profile.antag_loss_activity_threshold)
		active.stat = DEAD
		SSdirector.tally_ruleset_intensity(rule)
		antag_wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(round(antag_wallets, 0.1), 8.5, "Полностью отработавшая роль не должна возвращать свою долю")

		var/mob/living/carbon/human/late = allocate(/mob/living/carbon/human)
		late.mind_initialize()
		var/datum/antagonist/late_marker = new
		late_marker.silent = TRUE
		late.mind.add_antag_datum(late_marker)
		var/datum/dynamic_ruleset/midround/test_pool_isolation/late_rule = new
		late_rule.assigned = list(late.mind)
		late_rule.director_pending_cost = 8
		SSdirector.confirm_action_success(late_rule)
		SSdirector.time_override += profile.antag_loss_refund_window + 1
		late.stat = DEAD
		SSdirector.tally_ruleset_intensity(late_rule)
		antag_wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(round(antag_wallets, 0.1), 8.5, "Потеря после окна страховки не должна возвращать бюджет")

		// Крио удаляет текущее тело mind: ранняя потеря должна закрыть полис и выплатиться один раз.
		SSdirector.time_override = world.time + 2 MINUTES
		var/mob/living/carbon/human/cryo = allocate(/mob/living/carbon/human)
		cryo.mind_initialize()
		var/datum/mind/cryo_mind = cryo.mind
		var/datum/antagonist/cryo_marker = new
		cryo_marker.silent = TRUE
		cryo_mind.add_antag_datum(cryo_marker)
		var/datum/dynamic_ruleset/midround/test_pool_isolation/cryo_rule = new
		cryo_rule.assigned = list(cryo_mind)
		cryo_rule.director_pending_cost = 6
		SSdirector.confirm_action_success(cryo_rule)
		var/before_cryo = antag_wallets
		cryo_mind.set_current(null)
		SSdirector.tally_ruleset_intensity(cryo_rule)
		antag_wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(round(antag_wallets - before_cryo, 0.1), 6, "Ранняя потеря роли через крио должна вернуть её стоимость")
		SSdirector.tally_ruleset_intensity(cryo_rule)
		TEST_ASSERT_EQUAL(round(SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST] - before_cryo, 0.1), 6, "Повторный подсчёт крио не должен возвращать стоимость повторно")

		// Снятие последнего hard-antag datum при живом теле — такая же окончательная потеря роли.
		var/mob/living/carbon/human/removed = allocate(/mob/living/carbon/human)
		removed.mind_initialize()
		var/datum/antagonist/removed_marker = new
		removed_marker.silent = TRUE
		removed.mind.add_antag_datum(removed_marker)
		var/datum/dynamic_ruleset/midround/test_pool_isolation/removed_rule = new
		removed_rule.assigned = list(removed.mind)
		removed_rule.director_pending_cost = 7
		SSdirector.confirm_action_success(removed_rule)
		var/before_removed = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		removed.mind.remove_antag_datum(removed_marker.type)
		SSdirector.tally_ruleset_intensity(removed_rule)
		antag_wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(round(antag_wallets - before_removed, 0.1), 7, "Раннее снятие antagonist datum должно вернуть стоимость роли")
		SSdirector.tally_ruleset_intensity(removed_rule)
		TEST_ASSERT_EQUAL(round(SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST] - before_removed, 0.1), 7, "Повторный подсчёт снятой роли не должен возвращать стоимость повторно")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

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

/// Каталог действий панели должен показывать структурные рулсеты ещё в лобби, а после Dynamic
/// pre_setup() дополняться или заменяться живыми экземплярами без необходимости переоткрывать UI.
/datum/unit_test/director_panel_ruleset_catalog_refresh

/datum/unit_test/director_panel_ruleset_catalog_refresh/Run()
	var/list/saved_actions = SSdirector.actions
	var/datum/director_panel/panel = new
	var/datum/round_event_control/nothing/event_control = new
	var/datum/dynamic_ruleset/midround/test_pool_isolation/ruleset = new
	try
		SSdirector.actions = list(event_control)
		var/list/before_registration = panel.profile_actions_data()
		var/catalog_rulesets = 0
		for(var/list/row as anything in before_registration)
			if(row["kind"] == DIRECTOR_KIND_RULESET)
				catalog_rulesets++
		TEST_ASSERT(catalog_rulesets > 0, "Предпросмотр профиля должен показывать рулсеты до Dynamic.pre_setup(), а не 0 / 0")

		// Нулевая фикстура не входит в структурный каталог, но после живой регистрации обязана
		// появиться в следующем ui_data() уже открытой панели.
		SSdirector.actions += ruleset
		var/list/after_registration = panel.profile_actions_data()
		TEST_ASSERT_EQUAL(length(after_registration), length(before_registration) + 1, "Живой рулсет должен дополнить структурный каталог без потери превью")
		var/found_live_ruleset = FALSE
		for(var/list/row as anything in after_registration)
			if(row["name"] == ruleset.name)
				found_live_ruleset = TRUE
				break
		TEST_ASSERT(found_live_ruleset, "Обновлённый каталог панели должен содержать зарегистрированный живой рулсет")
	catch(var/exception/e)
		SSdirector.actions = saved_actions
		qdel(panel)
		qdel(event_control)
		qdel(ruleset)
		throw e
	SSdirector.actions = saved_actions
	qdel(panel)
	qdel(event_control)
	qdel(ruleset)

/// Сторожевой тест регрессии "на эксте раньше спаунились антаги": все события-спавнеры гост-ролей
/// обязаны жить в GHOST-пуле (а не в MAJOR, который у Light/Extended выключен долей 0), с ненулевыми
/// cost/intensity и метаданными точного preflight. После спавна вклад переводится на живой
/// трекинг созданного моба, поэтому фиксированный долгий linger больше не нужен.
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
		TEST_ASSERT(control.director_ghost_minimum > 0, "[control_name]: preflight гост-роли не знает минимального числа кандидатов")
		TEST_ASSERT(control.director_ghost_preference, "[control_name]: preflight гост-роли не знает требуемый preference")
	// Пираты и рейдеры реализованы обычными событиями (не ghost_role), но поллят призраков.
	var/datum/round_event_control/pirates/pirates_control = locate() in SSdirector.actions
	TEST_ASSERT_NOTNULL(pirates_control, "Событие Space Pirates должно быть зарегистрировано у директора")
	TEST_ASSERT_EQUAL(pirates_control.severity, DIRECTOR_SEVERITY_GHOST, "Space Pirates обязаны жить в GHOST-пуле")
	TEST_ASSERT(!pirates_control.admin_only, "Прямое событие Space Pirates должно оставаться в естественном пуле")
	var/datum/round_event_control/raiders/raiders_control = locate() in SSdirector.actions
	TEST_ASSERT_NOTNULL(raiders_control, "Событие InteQ Raiders должно быть зарегистрировано у директора")
	TEST_ASSERT_EQUAL(raiders_control.severity, DIRECTOR_SEVERITY_GHOST, "InteQ Raiders обязаны жить в GHOST-пуле")
	TEST_ASSERT(!raiders_control.admin_only, "Прямое событие InteQ Raiders должно оставаться в естественном пуле")
	var/datum/round_event_control/vox_scavengers/vox_control = locate() in SSdirector.actions
	TEST_ASSERT_NOTNULL(vox_control, "Прямое событие Vox Scavengers должно быть зарегистрировано у директора")
	TEST_ASSERT(!vox_control.admin_only, "Прямое событие Vox Scavengers должно оставаться естественным GHOST-действием")
	TEST_ASSERT_EQUAL(length(vox_control.required_round_type), 1, "Vox Scavengers должны быть доступны ровно в одном профиле")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_LIGHT in vox_control.required_round_type, "Vox Scavengers должны быть доступны только в Dynamic Light")
	TEST_ASSERT(vox_control.earliest_start >= 30 MINUTES, "Рейд воксов не должен падать на первых минутах лёгкого раунда")
	var/datum/round_event_control/morph/morph_control = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/from_ghosts/morph/morph_ruleset = locate() in SSdirector.actions
	var/datum/round_event_control/changeling/changeling_control = locate() in SSdirector.actions
	var/datum/round_event_control/revenant/revenant_control = locate() in SSdirector.actions
	var/datum/round_event_control/sentient_disease/disease_control = locate() in SSdirector.actions
	TEST_ASSERT_NOTNULL(morph_control, "Spawn Morph должен быть зарегистрирован у директора")
	TEST_ASSERT(!morph_control.admin_only, "Прямое событие Spawn Morph должно оставаться в естественном пуле")
	TEST_ASSERT(morph_control.weight > 0, "Прямое событие Spawn Morph должно иметь ненулевой естественный вес")
	TEST_ASSERT(!(ROUNDTYPE_DYNAMIC_LIGHT in morph_control.required_round_type), "Spawn Morph должен быть исключён из Dynamic Light")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_MEDIUM in morph_control.required_round_type, "Spawn Morph должен быть доступен на Dynamic Medium")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_HARD in morph_control.required_round_type, "Spawn Morph должен быть доступен на Dynamic Hard")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_TEAMBASED in morph_control.required_round_type, "Spawn Morph должен быть доступен на Dynamic Team-Based")
	TEST_ASSERT_NOTNULL(morph_ruleset, "Legacy-рулсет Morph должен быть зарегистрирован у директора")
	TEST_ASSERT_NOTNULL(changeling_control, "Changeling Meteor должен быть зарегистрирован у директора")
	TEST_ASSERT_NOTNULL(revenant_control, "Spawn Revenant должен быть зарегистрирован у директора")
	TEST_ASSERT_NOTNULL(disease_control, "Spawn Sentient Disease должен быть зарегистрирован у директора")
	TEST_ASSERT(!(ROUNDTYPE_DYNAMIC_LIGHT in changeling_control.required_round_type), "Changeling Meteor должен быть исключён из Dynamic Light")
	TEST_ASSERT(!(ROUNDTYPE_DYNAMIC_LIGHT in revenant_control.required_round_type), "Spawn Revenant должен быть исключён из Dynamic Light")
	TEST_ASSERT(!(ROUNDTYPE_DYNAMIC_LIGHT in disease_control.required_round_type), "Spawn Sentient Disease должен быть исключён из Dynamic Light")
	var/datum/dynamic_ruleset/midround/pirates/pirates_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/raiders/raiders_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/swarmers/swarmers_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/from_ghosts/blob/blob_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/xeno_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/from_ghosts/terror_spiders/terror_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/from_ghosts/nightmare/nightmare_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/from_ghosts/space_dragon/dragon_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/from_ghosts/abductors/abductor_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/from_ghosts/space_ninja/ninja_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/from_ghosts/revenant/revenant_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/from_ghosts/sentient_disease/disease_ruleset = locate() in SSdirector.actions
	var/datum/dynamic_ruleset/midround/vox_scavengers/vox_ruleset = locate() in SSdirector.actions
	TEST_ASSERT(pirates_ruleset?.admin_only, "Legacy-рулсет Space Pirates не должен дублировать прямое событие в естественном пуле")
	TEST_ASSERT(raiders_ruleset?.admin_only, "Legacy-рулсет InteQ Raiders не должен дублировать прямое событие в естественном пуле")
	TEST_ASSERT(swarmers_ruleset?.admin_only, "Legacy-рулсет Swarmers не должен дублировать Spawn Swarmer Shell в естественном пуле")
	TEST_ASSERT(blob_ruleset?.admin_only, "Legacy-рулсет Blob не должен дублировать прямое событие Blob в естественном пуле")
	TEST_ASSERT(xeno_ruleset?.admin_only, "Legacy-рулсет Alien Infestation не должен дублировать прямое событие")
	TEST_ASSERT(terror_ruleset?.admin_only, "Legacy-рулсет Terror Infestation не должен дублировать прямое событие")
	TEST_ASSERT(nightmare_ruleset?.admin_only, "Legacy-рулсет Nightmare не должен дублировать прямое событие")
	TEST_ASSERT(dragon_ruleset?.admin_only, "Legacy-рулсет Space Dragon не должен дублировать прямое событие")
	TEST_ASSERT(abductor_ruleset?.admin_only, "Legacy-рулсет Abductors не должен дублировать прямое событие")
	TEST_ASSERT(ninja_ruleset?.admin_only, "Legacy-рулсет Space Ninja не должен дублировать прямое событие")
	TEST_ASSERT(revenant_ruleset?.admin_only, "Legacy-рулсет Revenant не должен дублировать прямое событие")
	TEST_ASSERT(disease_ruleset?.admin_only, "Legacy-рулсет Sentient Disease не должен дублировать прямое событие")
	TEST_ASSERT(vox_ruleset?.admin_only, "Legacy-рулсет Vox Scavengers не должен дублировать прямое событие")
	TEST_ASSERT(morph_ruleset?.admin_only, "Legacy-рулсет Morph не должен дублировать Spawn Morph в естественном пуле")
	var/datum/dynamic_ruleset/midround/blob_infection/blob_infection = locate() in SSdirector.actions
	TEST_ASSERT(blob_infection?.admin_only, "Blob Infection не должен забирать члена экипажа естественным выбором директора")
	var/datum/round_event_control/blob/blob_control = locate() in SSdirector.actions
	TEST_ASSERT(!blob_control?.admin_only && blob_control?.weight > 0, "Гостовый Blob должен оставаться в естественном GHOST-пуле")

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
/// и условным Lone Operative. Защитник диска в Light приходит только второй волной после него;
/// самостоятельно control защитника доступен исключительно в Extended.
/// Боевые гост-антаги исторически убраны из Light у dynamic-ruleset'ов и не должны возвращаться
/// через одноимённые event control'ы директора (именно так в Light смог выпасть Space Dragon).
/datum/unit_test/director_light_ghost_policy

/datum/unit_test/director_light_ghost_policy/Run()
	var/list/allowed_light_ghost_controls = list(
		/datum/round_event_control/fugitives,
		// Воксы - гост-команда со своего корабля, но не antag_heavy: решением геймдизайна это
		// единственный рейд лёгкого профиля, и живёт он только в нём (см. vox_scavengers_event.dm).
		/datum/round_event_control/vox_scavengers,
	)
	var/datum/round_event_control/operative/operative_control = locate() in SSdirector.event_controls()
	var/datum/round_event_control/operative/keeper/keeper_control = locate() in SSdirector.event_controls()
	TEST_ASSERT_NOTNULL(operative_control, "Lone Operative должен быть зарегистрирован у директора")
	TEST_ASSERT(!operative_control.admin_only, "Lone Operative должен входить в условный автоматический пул")
	TEST_ASSERT_EQUAL(initial(operative_control.weight), 0, "Lone Operative не должен иметь шанс до срабатывания условия неподвижного диска")
	TEST_ASSERT(initial(operative_control.weight_can_change), "Панель должна знать, что нулевой вес Lone Operative меняется во время раунда")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_LIGHT in operative_control.required_round_type, "Lone Operative должен быть доступен в Dynamic Light")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_MEDIUM in operative_control.required_round_type, "Lone Operative должен быть доступен в Dynamic Medium")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_HARD in operative_control.required_round_type, "Lone Operative должен быть доступен в Dynamic Hard")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_TEAMBASED in operative_control.required_round_type, "Lone Operative должен быть доступен в Dynamic Team-Based")
	TEST_ASSERT(!(ROUNDTYPE_EXTENDED in operative_control.required_round_type), "Боевой Lone Operative не должен входить в пул Extended")
	TEST_ASSERT_NOTNULL(keeper_control, "Случайный защитник диска должен быть зарегистрирован у директора")
	TEST_ASSERT(!keeper_control.admin_only, "Защитник диска должен выпадать случайно, а не только через админ-форс")
	TEST_ASSERT_EQUAL(length(keeper_control.required_round_type), 1, "Самостоятельный защитник диска должен иметь ровно один разрешённый профиль")
	TEST_ASSERT(ROUNDTYPE_EXTENDED in keeper_control.required_round_type, "Самостоятельный защитник диска должен быть доступен в Extended")
	TEST_ASSERT(!(ROUNDTYPE_DYNAMIC_LIGHT in keeper_control.required_round_type), "Защитник диска не должен выпадать в Light без Lone Operative")
	TEST_ASSERT(ROUNDTYPE_DYNAMIC_LIGHT in keeper_control.director_linked_round_types, "Панель должна показывать защитника как связанную вторую волну в Dynamic Light")
	TEST_ASSERT(keeper_control.director_linked_detail, "Связанное событие защитника должно объяснять условие появления в панели")
	TEST_ASSERT_EQUAL(keeper_control.typepath, /datum/round_event/ghost_role/operative/keeper, "Случайный Lone Operative должен получать роль защитника диска")
	var/datum/round_event/ghost_role/operative/operative_event = new(FALSE)
	operative_event.kill()
	TEST_ASSERT(operative_event.should_spawn_linked_keeper(FALSE, ROUNDTYPE_DYNAMIC_LIGHT), "Обычный Lone Operative в Light должен планировать защитника")
	TEST_ASSERT(!operative_event.should_spawn_linked_keeper(TRUE, ROUNDTYPE_DYNAMIC_LIGHT), "Сам защитник не должен рекурсивно планировать ещё одного защитника")
	TEST_ASSERT(!operative_event.should_spawn_linked_keeper(FALSE, ROUNDTYPE_DYNAMIC_MEDIUM), "В Medium после Lone Operative не должен появляться защитник")
	TEST_ASSERT(!operative_event.should_spawn_linked_keeper(FALSE, ROUNDTYPE_DYNAMIC_HARD), "В Hard после Lone Operative не должен появляться защитник")
	TEST_ASSERT(!operative_event.should_spawn_linked_keeper(FALSE, ROUNDTYPE_DYNAMIC_TEAMBASED), "В Team-Based после Lone Operative не должен появляться защитник")
	TEST_ASSERT(!operative_event.should_spawn_linked_keeper(FALSE, ROUNDTYPE_EXTENDED), "Extended использует самостоятельный control защитника, а не пару")
	qdel(operative_event)
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
	var/list/saved_beat_log = SSdirector.beat_log.Copy()
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
		SSdirector.fired_counts[control.severity] = 1
		SSdirector.intensity_ledger += list(list(control.action_name(), control.intensity, 0, control.severity))
		event = new(FALSE)
		SSdirector.running -= event // тестовый датум не должен тикаться подсистемой
		event.control = control
		event.triggered_randomly = TRUE
		event.refund_failed_spawn()
		TEST_ASSERT_EQUAL(control.occurrences, occurrences_before, "Провал спавна должен возвращать попытку")
		TEST_ASSERT_EQUAL(SSdirector.fired_counts[control.severity], 0, "Провал спавна не должен считаться успешным запуском ступени")
		TEST_ASSERT_EQUAL(length(SSdirector.intensity_ledger), 0, "Провал спавна должен снимать вклад сразу, без linger")
		TEST_ASSERT_EQUAL(SSdirector.budgets[control.severity], control.cost, "Провал спавна должен возвращать кошелёк ступени")

		// Форс админа шёл мимо кошельков - и рефанд не должен дарить бюджет.
		SSdirector.reset_budgets(0)
		control.occurrences++
		SSdirector.fired_counts[control.severity] = 1
		SSdirector.intensity_ledger += list(list(control.action_name(), control.intensity, 0, control.severity))
		event.triggered_randomly = FALSE
		event.refund_failed_spawn()
		TEST_ASSERT_EQUAL(control.occurrences, occurrences_before, "Провал форс-спавна тоже должен возвращать попытку")
		TEST_ASSERT_EQUAL(SSdirector.fired_counts[control.severity], 0, "Провал форс-спавна тоже должен откатить счётчик ступени")
		TEST_ASSERT_EQUAL(SSdirector.budgets[control.severity], 0, "Провал форс-спавна не должен дарить кошельку бюджет")
	catch(var/exception/e)
		if(event)
			SSdirector.running -= event
		SSdirector.beat_log = saved_beat_log
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.running -= event
	SSdirector.beat_log = saved_beat_log
	SSdirector.restore_simulation_state(saved)

/// Регрессия из прод-дампа: Morph четыре раза попадал в director.json как fired, хотя ready()
/// не находил подходящих призраков и опрос даже не открывался. Preflight обязан убрать такой
/// рулсет и из боевого пула, и из целей копилки, оставив точную причину для панели.
/datum/unit_test/director_ghost_ruleset_preflight

/datum/unit_test/director_ghost_ruleset_preflight/Run()
	var/list/saved = SSdirector.capture_simulation_state()
	var/datum/game_mode/dynamic/mode = SSticker.mode
	var/list/saved_dead = mode.current_players[CURRENT_DEAD_PLAYERS]
	var/list/saved_observers = mode.current_players[CURRENT_OBSERVERS]
	var/datum/dynamic_ruleset/midround/from_ghosts/test_assigned_minds/rule
	var/rule_was_candidate
	var/readiness_rejects
	var/verdict
	var/detail
	var/has_pool_target
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		// Изолируем тест от реальных roundstart-антаг-вкладов unit-test раунда.
		profile.antag_intensity_per_crew = 1000
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.pool_saving = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_GHOST = world.time - profile.ghost_light_spacing - 1,
		)
		mode.current_players[CURRENT_DEAD_PLAYERS] = list()
		mode.current_players[CURRENT_OBSERVERS] = list()

		// Общая from_ghosts-фикстура изолирует проверку кандидатов от дополнительных
		// map-гейтов Morph (на MultiZ Debug нет xeno_spawn).
		rule = new
		rule.mode = mode
		rule.weight = 10
		rule.enemy_roles = list()
		rule.required_enemies = list(0,0,0,0,0,0,0,0,0,0)
		rule.required_applicants = 1
		SSdirector.actions = list(rule)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)
		var/list/reject_stats = list()
		var/list/verdicts = list()
		var/list/candidates = SSdirector.filter_candidates(signals, FALSE, reject_stats, verdicts)
		rule_was_candidate = (rule in candidates)
		readiness_rejects = reject_stats[DIRECTOR_SEVERITY_GHOST]?[DIRECTOR_REJECT_READINESS] || 0
		var/list/first_verdict = length(verdicts) ? verdicts[1] : null
		verdict = first_verdict?["verdict"]
		detail = first_verdict?["detail"]
		has_pool_target = !isnull(SSdirector.roll_pool_target(DIRECTOR_SEVERITY_GHOST, signals))
	catch(var/exception/e)
		mode.current_players[CURRENT_DEAD_PLAYERS] = saved_dead
		mode.current_players[CURRENT_OBSERVERS] = saved_observers
		SSdirector.restore_simulation_state(saved)
		throw e
	mode.current_players[CURRENT_DEAD_PLAYERS] = saved_dead
	mode.current_players[CURRENT_OBSERVERS] = saved_observers
	SSdirector.restore_simulation_state(saved)
	qdel(rule)
	// TEST_ASSERT делает ранний return из Run(), поэтому проверки идут только после восстановления
	// глобального состояния — иначе одно падение загрязняет все последующие director-тесты.
	TEST_ASSERT(!rule_was_candidate, "Гост-рулсет без подходящих призраков не должен доходить до выбора")
	TEST_ASSERT_EQUAL(readiness_rejects, 1, "Отказ должен иметь отдельную причину readiness")
	TEST_ASSERT_EQUAL(verdict, DIRECTOR_REJECT_READINESS, "Панель должна получить readiness, а не ложный ok")
	TEST_ASSERT(findtext(detail, "подходящих гостов 0 из 1"), "В панели должно быть точное число подходящих гостов")
	TEST_ASSERT(!has_pool_target, "Неисполнимый гост-рулсет не должен становиться целью копилки")

/// Синхронный execute_action(FALSE) раньше всё равно попадал в историю как "fired".
/datum/unit_test/director_failed_action_is_not_fired

/datum/unit_test/director_failed_action_is_not_fired/Run()
	var/list/saved = SSdirector.capture_simulation_state()
	var/list/saved_beat_log = SSdirector.beat_log.Copy()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(0)
		SSdirector.budgets[DIRECTOR_SEVERITY_MINOR] = 10
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.last_fired_at = list(DIRECTOR_SEVERITY_MINOR = world.time - profile.severity_spacing[DIRECTOR_SEVERITY_MINOR] - 1)
		SSdirector.last_any_fired_at = world.time - profile.global_spacing - 1
		var/datum/director_action/test_stub/fails/action = new
		action.cost = 2
		SSdirector.actions = list(action)

		var/datum/director_signals/signals = new
		signals.effective_crew = 10
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 1, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 0)
		var/beat_result = SSdirector.run_beat(signals, forced = TRUE)
		var/list/last_entry = SSdirector.beat_log[length(SSdirector.beat_log)]
		TEST_ASSERT_EQUAL(beat_result, DIRECTOR_BEAT_FAILED, "run_beat должен вернуть фактический результат синхронного отказа")
		TEST_ASSERT_EQUAL(last_entry["result"], DIRECTOR_BEAT_FAILED, "execute_action(FALSE) должен логироваться как failed, не fired")
		TEST_ASSERT(findtext(last_entry["detail"], "бюджет возвращён"), "История должна объяснять синхронный провал")
		TEST_ASSERT_EQUAL(SSdirector.budgets[DIRECTOR_SEVERITY_MINOR], 10, "Синхронный провал должен полностью вернуть кошелёк")
		TEST_ASSERT_EQUAL(action.occurrences, 0, "Синхронный провал не должен съедать occurrence")
	catch(var/exception/e)
		SSdirector.beat_log = saved_beat_log
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.beat_log = saved_beat_log
	SSdirector.restore_simulation_state(saved)

/// Провал после note_fired обязан полностью откатить пейсинг. Это сценарий Ratvar из прод-лога:
/// бюджет вернулся, но ANTAG heavy-spacing и глобальная пауза оставались на 30 минут.
/datum/unit_test/director_failed_action_rolls_back_spacing

/datum/unit_test/director_failed_action_rolls_back_spacing/Run()
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(0)
		SSdirector.intensity_ledger = list()
		SSdirector.fired_counts = list()
		SSdirector.family_fired_counts = list()
		SSdirector.family_last_fired_at = list()
		SSdirector.action_failure_cooldowns = list()
		SSdirector.action_attempt_rollbacks = list()
		SSdirector.last_fired_at = list()
		var/datum/dynamic_ruleset/midround/ratvar_awakening/rule = new
		rule.family = "test_clockcult"
		var/old_severity = world.time - profile.antag_light_spacing - 1
		var/old_any = world.time - 20 MINUTES
		var/old_real = world.time - 21 MINUTES
		var/old_heavy = world.time - profile.antag_heavy_spacing - 1
		var/old_family = world.time - profile.family_spacing - 1
		SSdirector.last_fired_at[rule.severity] = old_severity
		SSdirector.last_any_fired_at = old_any
		SSdirector.last_real_fired_at = old_real
		SSdirector.last_antag_heavy_at = old_heavy
		SSdirector.family_last_fired_at[rule.family] = old_family
		SSdirector.pool_saving = list(DIRECTOR_SEVERITY_ANTAG = rule)
		rule.executed_at = world.time - 30 MINUTES
		var/old_executed_at = rule.executed_at
		var/spent = rule.cost - 3
		rule.director_pending_cost = spent
		rule.occurrences++
		SSdirector.note_fired(rule)
		TEST_ASSERT_EQUAL(SSdirector.last_antag_heavy_at, world.time, "Предварительный запуск должен поставить heavy-spacing")
		TEST_ASSERT_NULL(SSdirector.pool_saving[DIRECTOR_SEVERITY_ANTAG], "Предварительный запуск должен снять исполненную цель копилки")
		// Не создаём реальный двухсекундный таймер внутри unit test, но проверяем карантин замены.
		SSdirector.dry_run = TRUE
		SSdirector.note_failed_action(rule, refund_budget = TRUE, retry_replacement = TRUE)
		SSdirector.dry_run = FALSE
		TEST_ASSERT_EQUAL(SSdirector.last_any_fired_at, old_any, "Провал обязан вернуть global-spacing")
		TEST_ASSERT_EQUAL(SSdirector.last_real_fired_at, old_real, "Провал обязан вернуть таймер реальной тишины")
		TEST_ASSERT_EQUAL(SSdirector.last_fired_at[rule.severity], old_severity, "Провал обязан вернуть паузу ступени")
		TEST_ASSERT_EQUAL(SSdirector.last_antag_heavy_at, old_heavy, "Провал обязан вернуть ANTAG heavy-spacing")
		TEST_ASSERT_EQUAL(SSdirector.family_last_fired_at[rule.family], old_family, "Провал обязан вернуть паузу семейства")
		TEST_ASSERT_EQUAL(rule.executed_at, old_executed_at, "Провал обязан вернуть возраст исполнения рулсета")
		TEST_ASSERT_EQUAL(rule.occurrences, 0, "Провал не должен съедать occurrence")
		TEST_ASSERT_EQUAL(SSdirector.fired_counts[rule.severity], 0, "Провал не должен считаться в доле ступени")
		TEST_ASSERT_EQUAL(SSdirector.budgets[rule.severity], spent, "Провал обязан вернуть фактически списанный бюджет")
		TEST_ASSERT_EQUAL(length(SSdirector.intensity_ledger), 0, "Провал обязан удалить временный intensity-мост конкретной попытки")
		TEST_ASSERT(SSdirector.action_recently_failed(rule), "Сам провалившийся вариант должен временно исключаться ради замены")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Статический linger Spawn Slaughter Demon раньше держал 30 intensity ещё десятки минут после
/// смерти. Живая группа должна дать вклад при жизни и исчезнуть сразу после смерти моба.
/// Свежая тихая роль на станции весит intensity * DIRECTOR_ACTIVITY_MULT_MIN: гост-команды
/// считаются как рулсеты (активность/присутствие/затухание), тест-зона живёт на reserved z.
/datum/unit_test/director_ghost_role_intensity_tracks_life

/datum/unit_test/director_ghost_role_intensity_tracks_life/Run()
	var/list/saved = SSdirector.capture_simulation_state()
	try
		SSdirector.profile = new /datum/director_profile/medium
		SSdirector.reset_budgets(0)
		var/datum/round_event_control/slaughter/control = locate() in SSdirector.actions
		TEST_ASSERT_NOTNULL(control, "Spawn Slaughter Demon должен быть зарегистрирован у директора")
		var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
		TEST_ASSERT(length(station_levels), "В тестовом мире нет станционного z-уровня")
		var/turf/station_turf = locate(round(world.maxx / 2), round(world.maxy / 2), station_levels[1])
		var/mob/living/carbon/human/spawned = allocate(/mob/living/carbon/human)
		spawned.mind_initialize()
		spawned.forceMove(station_turf)
		SSdirector.actions = list(control)
		SSdirector.intensity_ledger = list(list(control.action_name(), control.intensity, 0, control.severity))
		SSdirector.live_ghost_role_spawns = list()
		TEST_ASSERT(SSdirector.track_ghost_role_spawn(control, list(spawned), budget_backed = TRUE, log_execution = FALSE), "Успешный гост-спаун должен перейти на живой трекинг")
		TEST_ASSERT_EQUAL(length(SSdirector.intensity_ledger), 0, "Статический мост должен сниматься после реального спауна")
		TEST_ASSERT_EQUAL(SSdirector.get_active_intensity(), control.intensity * DIRECTOR_ACTIVITY_MULT_MIN, "Живой тихий демон на станции должен давать вклад с множителем тихони")
		spawned.stat = DEAD
		TEST_ASSERT_EQUAL(SSdirector.get_active_intensity(), 0, "Мёртвый демон не должен занимать intensity")
		TEST_ASSERT_EQUAL(length(SSdirector.live_ghost_role_spawns), 0, "Пустая живая группа должна удаляться")
		var/antag_wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(round(antag_wallets, 0.1), control.cost, "Ранняя тихая смерть естественной гост-роли должна вернуть её цену в антаг-кошельки")
		SSdirector.get_active_intensity()
		TEST_ASSERT_EQUAL(round(SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST], 0.1), control.cost, "Удалённая группа гост-роли не должна получить повторную выплату")

		// Даже без страхового policy снятие выданной hard-antag роли должно немедленно
		// освободить intensity; budget_backed = FALSE не должен удерживать живого бывшего антага.
		var/mob/living/carbon/human/unbacked = allocate(/mob/living/carbon/human)
		unbacked.mind_initialize()
		unbacked.forceMove(station_turf)
		var/datum/antagonist/unbacked_marker = new
		unbacked_marker.silent = TRUE
		unbacked.mind.add_antag_datum(unbacked_marker)
		SSdirector.intensity_ledger = list(list(control.action_name(), control.intensity, 0, control.severity))
		TEST_ASSERT(SSdirector.track_ghost_role_spawn(control, list(unbacked), budget_backed = FALSE, log_execution = FALSE), "Незастрахованный гост-спаун тоже должен перейти на живой трекинг")
		TEST_ASSERT_EQUAL(SSdirector.get_active_intensity(), control.intensity * DIRECTOR_ACTIVITY_MULT_MIN, "Живая незастрахованная роль должна давать intensity с множителем тихони")
		unbacked.mind.remove_antag_datum(unbacked_marker.type)
		TEST_ASSERT_EQUAL(SSdirector.get_active_intensity(), 0, "Снятая незастрахованная роль не должна продолжать давать intensity")
		TEST_ASSERT_EQUAL(length(SSdirector.live_ghost_role_spawns), 0, "Группа без оставшихся hard-antag ролей должна удаляться")
		TEST_ASSERT_EQUAL(round(SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST], 0.1), control.cost, "Незастрахованная роль не должна печатать возврат бюджета")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Swarmers и командные события завершают первичное действие до фактического занятия роли.
/// Поздний spawn обязан убрать даже уже истекающий статический мост рулсета и жить по мобу.
/// Тихая роль на станции весит intensity * DIRECTOR_ACTIVITY_MULT_MIN (см. tracks_life выше).
/datum/unit_test/director_deferred_ruleset_spawn_tracks_life

/datum/unit_test/director_deferred_ruleset_spawn_tracks_life/Run()
	var/list/saved = SSdirector.capture_simulation_state()
	try
		SSdirector.profile = new /datum/director_profile/medium
		SSdirector.reset_budgets(0)
		var/datum/dynamic_ruleset/midround/swarmers/rule = new
		var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
		TEST_ASSERT(length(station_levels), "В тестовом мире нет станционного z-уровня")
		var/mob/living/carbon/human/spawned = allocate(/mob/living/carbon/human)
		spawned.mind_initialize()
		spawned.forceMove(locate(round(world.maxx / 2), round(world.maxy / 2), station_levels[1]))
		SSdirector.actions = list(rule)
		SSdirector.intensity_ledger = list(list(rule.action_name(), rule.intensity, world.time + 10 MINUTES, rule.severity))
		SSdirector.live_ghost_role_spawns = list()
		TEST_ASSERT(SSdirector.track_ghost_role_spawn(rule, list(spawned), budget_backed = TRUE, log_execution = FALSE), "Поздняя роль рулсета должна перейти на живой трекинг")
		TEST_ASSERT_EQUAL(length(SSdirector.intensity_ledger), 0, "Живой spawn должен снять истекающий прогнозный мост рулсета")
		TEST_ASSERT_EQUAL(SSdirector.get_active_intensity(), rule.intensity * DIRECTOR_ACTIVITY_MULT_MIN, "Живая тихая поздняя роль должна давать intensity с множителем тихони")
		spawned.stat = DEAD
		TEST_ASSERT_EQUAL(SSdirector.get_active_intensity(), 0, "После смерти поздняя роль не должна занимать intensity")
		var/antag_wallets = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG] + SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT_EQUAL(round(antag_wallets, 0.1), rule.cost, "Ранняя потеря поздней роли должна вернуть цену в антаг-кошельки")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Ratvar не должен становиться планом ANTAG-пула, если после prefs/ban/job/antag фильтров
/// некому выдать роль. Раньше его ready() проверял только контрроли и пропускал пустой candidates.
/datum/unit_test/director_ratvar_preflight_requires_candidates

/datum/unit_test/director_ratvar_preflight_requires_candidates/Run()
	var/datum/game_mode/dynamic/mode = SSticker.mode
	var/list/saved_living = mode.current_players[CURRENT_LIVING_PLAYERS]
	try
		mode.current_players[CURRENT_LIVING_PLAYERS] = list()
		var/datum/dynamic_ruleset/midround/ratvar_awakening/rule = new
		rule.mode = mode
		rule.required_candidates = 1
		rule.enemy_roles = list()
		TEST_ASSERT(!rule.director_preflight(), "Ratvar без подходящего экипажа обязан провалить preflight")
		TEST_ASSERT(findtext(rule.director_preflight_failure, "подходящих членов экипажа 0 из 1"), "Ratvar должен объяснить точное число кандидатов")
	catch(var/exception/e)
		mode.current_players[CURRENT_LIVING_PLAYERS] = saved_living
		throw e
	mode.current_players[CURRENT_LIVING_PLAYERS] = saved_living

/// Регрессия Medieval Warmongers: переопределённый preRunEvent() без вызова ..() проваливался
/// в конец прока и возвращал null. null не равен ни одному коду EVENT_*, поэтому execute_action()
/// отваливался на проверке result != EVENT_READY: событие не запускалось ни разу за весь раунд,
/// а директор терял на нём бит гост-антагов. preRunEvent() обязан возвращать код EVENT_*.
/datum/unit_test/director_prerun_event_never_null

/datum/unit_test/director_prerun_event_never_null/Run()
	for(var/datum/round_event_control/control_path as anything in typesof(/datum/round_event_control))
		if(!initial(control_path.typepath))
			continue
		// admin_window = FALSE: без окна отмены preRunEvent не спит и не пишет админам,
		// а COMSIG_GLOB_PRE_RANDOM_EVENT никто не слушает - проверка чистая.
		var/datum/round_event_control/control = allocate(control_path)
		var/result = control.preRunEvent(admin_window = FALSE)
		TEST_ASSERT(!isnull(result), "[control_path] ([control.name]): preRunEvent() вернул null - \
			переопределение не зовёт ..(). execute_action() провалит такой запуск (null != EVENT_READY)")

/// Событие, которое preRunEvent объявил незапускаемым (например, корабельное на карте без космоса),
/// обязано выключиться до конца раунда. Ветка EVENT_CANT_RUN гасила его через max_occurrences = 0,
/// но базовый контракт директора читает 0 как "без лимита" (can_fire: if(max_occurrences && ...)) -
/// выключатель делал обратное, и действие оставалось вечным кандидатом, жгущим биты на провалах.
/datum/unit_test/director_cant_run_event_is_disabled

/datum/unit_test/director_cant_run_event_is_disabled/Run()
	var/datum/director_signals/signals = new
	signals.effective_crew = 40
	signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
		DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

	// Базовый контроль без typepath: preRunEvent честно возвращает EVENT_CANT_RUN (тот же путь,
	// что у корабельных событий на карте без космоса), а в реестр директора он не попадает.
	var/datum/round_event_control/control = allocate(/datum/round_event_control)
	control.earliest_start = 0
	TEST_ASSERT(control.can_fire(signals), "Контроль: до провала событие обязано проходить can_fire")
	TEST_ASSERT(!control.execute_action(), "Событие без typepath обязано провалить запуск")
	TEST_ASSERT(!control.can_fire(signals), "Незапускаемое событие обязано выключиться, а не остаться кандидатом на весь раунд")

/// Живые жёсткие антаги, которых директор не создавал (выданные админом/жетоном, спавнеры карт,
/// обращённые), обязаны попадать в antag_load - иначе клапан давления считает раунд недогруженным
/// и льёт ещё антагов поверх реальных (прод-жалоба "еретик не учитывался директором"). Разум,
/// уже посчитанный рулсетом, не должен задваиваться третьим источником.
/datum/unit_test/director_untracked_antag_load

/// Минимальный жёсткий (не soft_antag) антаг-датум-маркер: "разум всё ещё антагонист".
/datum/unit_test/director_untracked_antag_load/proc/grant_hard_antag(datum/mind/target_mind)
	var/datum/antagonist/marker = new
	marker.silent = TRUE
	target_mind.add_antag_datum(marker)

/datum/unit_test/director_untracked_antag_load/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	var/mob/living/carbon/human/admin_antag
	var/mob/living/carbon/human/soft_holder
	try
		SSdirector.profile = new /datum/director_profile/medium
		SSdirector.actions = list()
		SSdirector.intensity_ledger = list()
		SSdirector.live_ghost_role_spawns = list()
		var/mult_min = DIRECTOR_ACTIVITY_MULT_MIN
		// Дельты от базовой линии: тест устойчив к любым живым антагам самого раунда CI.
		var/baseline = SSdirector.antag_load()

		// Живой жёсткий антаг без рулсета/гост-роли - аналог выданного админом/жетоном еретика.
		// Тестовая зона живёт на reserved z: свежесозданный антаг НЕ на станции и давить
		// на клапан не должен (прод-жалоба "нагрузка есть, антагов не видно").
		admin_antag = allocate(/mob/living/carbon/human)
		admin_antag.mind_initialize()
		grant_hard_antag(admin_antag.mind)
		TEST_ASSERT_EQUAL(SSdirector.antag_load() - baseline, 0, "Untracked-антаг вне станционного z не должен давать нагрузки")

		// На станции - полноценный вклад лёгкого соло-тира. Гейт смотрит только на z-трейт,
		// поэтому годится любой турф станционного уровня (latejoin_trackers в CI-мире пуст).
		var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
		TEST_ASSERT(length(station_levels), "В тестовом мире нет станционного z-уровня")
		admin_antag.forceMove(locate(round(world.maxx / 2), round(world.maxy / 2), station_levels[1]))
		TEST_ASSERT_EQUAL(SSdirector.antag_load() - baseline, DIRECTOR_UNTRACKED_ANTAG_INTENSITY * mult_min, "Антаг без рулсета (админ/жетон) обязан давать нагрузку через untracked-источник")

		// Затухание по возрасту, как у рулсетов: старый untracked-антаг оседает к полу 0.25.
		admin_antag.mind.director_untracked_since = SSdirector.now() - 150 MINUTES
		TEST_ASSERT_EQUAL(SSdirector.antag_load() - baseline, DIRECTOR_UNTRACKED_ANTAG_INTENSITY * mult_min * 0.25, "Часовой untracked-антаг обязан затухать к полу, как старый рулсет")
		admin_antag.mind.director_untracked_since = SSdirector.now()

		// Тот же разум в assigned рулсета - считается рулсетом; untracked дедупит, не задваивает
		// (задвоение дало бы 15 * mult_min + 15 * mult_min). time_override держит свежий раунд без затухания.
		SSdirector.time_override = SSticker.round_start_time + 1 MINUTES
		var/datum/dynamic_ruleset/midround/test_pool_isolation/rule = new
		rule.intensity = 15
		rule.occurrences = 1
		rule.assigned = list(admin_antag.mind)
		SSdirector.actions = list(rule)
		TEST_ASSERT_EQUAL(SSdirector.antag_load() - baseline, 15 * mult_min, "Разум в assigned рулсета не должен считаться повторно как untracked")
		SSdirector.actions = list()
		SSdirector.time_override = 0
		qdel(rule)

		// Мёртвый untracked-антаг не считается.
		admin_antag.death()
		TEST_ASSERT_EQUAL(SSdirector.antag_load() - baseline, 0, "Мёртвый untracked-антаг не даёт нагрузки")

		// Soft-антаг (мирная гост-роль) не считается даже живым.
		soft_holder = allocate(/mob/living/carbon/human)
		soft_holder.mind_initialize()
		var/datum/antagonist/soft = new
		soft.silent = TRUE
		soft.soft_antag = TRUE
		soft_holder.mind.add_antag_datum(soft)
		TEST_ASSERT_EQUAL(SSdirector.antag_load() - baseline, 0, "Soft-антаг не должен давать антаг-нагрузки")
		soft_holder.mind.remove_antag_datum(/datum/antagonist)
	catch(var/exception/e)
		admin_antag?.mind?.remove_antag_datum(/datum/antagonist)
		soft_holder?.mind?.remove_antag_datum(/datum/antagonist)
		SSdirector.time_override = 0
		SSdirector.restore_simulation_state(saved)
		throw e
	admin_antag?.mind?.remove_antag_datum(/datum/antagonist)
	soft_holder?.mind?.remove_antag_datum(/datum/antagonist)
	SSdirector.restore_simulation_state(saved)

/// Разбивка antag_load обязана отдавать строку untracked-источника (админ/жетон/вербовка):
/// без неё панель показывает нагрузку одним числом, и админ не видит, от кого она
/// (прод-раунд Families: 70+ нагрузки от завербованных гангстеров при пустых "Активных вкладах").
/datum/unit_test/director_untracked_antag_breakdown

/// Минимальный жёсткий (не soft_antag) антаг-датум-маркер: "разум всё ещё антагонист".
/datum/unit_test/director_untracked_antag_breakdown/proc/grant_hard_antag(datum/mind/target_mind)
	var/datum/antagonist/marker = new
	marker.silent = TRUE
	target_mind.add_antag_datum(marker)

/// Строка untracked-источника в разбивке: list(имя, вклад, голов). null, если строки нет.
/// Имя строки теперь несёт список имён антагов после двоеточия - матчим по префиксу.
/datum/unit_test/director_untracked_antag_breakdown/proc/untracked_row(list/breakdown)
	for(var/list/row in breakdown)
		if(findtext(row[1], DIRECTOR_UNTRACKED_SOURCE_NAME) == 1)
			return row
	return null

/datum/unit_test/director_untracked_antag_breakdown/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. director_untracked_antag_load).
	var/list/saved = SSdirector.capture_simulation_state()
	var/mob/living/carbon/human/admin_antag
	try
		SSdirector.profile = new /datum/director_profile/medium
		SSdirector.actions = list()
		SSdirector.intensity_ledger = list()
		SSdirector.live_ghost_role_spawns = list()
		// Дельты от базовой линии: тест устойчив к любым живым антагам самого раунда CI.
		var/list/baseline_rows = list()
		SSdirector.antag_load(baseline_rows)
		var/list/base_row = untracked_row(baseline_rows)
		var/base_value = base_row ? base_row[2] : 0
		var/base_heads = base_row ? base_row[3] : 0

		admin_antag = allocate(/mob/living/carbon/human)
		admin_antag.mind_initialize()
		grant_hard_antag(admin_antag.mind)
		// Тестовая зона живёт на reserved z - для учёта антаг должен стоять на станции.
		// Гейт смотрит только на z-трейт (latejoin_trackers в CI-мире пуст).
		var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
		TEST_ASSERT(length(station_levels), "В тестовом мире нет станционного z-уровня")
		admin_antag.forceMove(locate(round(world.maxx / 2), round(world.maxy / 2), station_levels[1]))
		var/list/rows = list()
		SSdirector.antag_load(rows)
		var/list/row = untracked_row(rows)
		TEST_ASSERT_NOTNULL(row, "Разбивка antag_load обязана содержать строку untracked-источника")
		TEST_ASSERT_EQUAL(row[2] - base_value, DIRECTOR_UNTRACKED_ANTAG_INTENSITY * DIRECTOR_ACTIVITY_MULT_MIN, "Строка untracked обязана прибавить вклад нового антага")
		TEST_ASSERT_EQUAL(row[3] - base_heads, 1, "Строка untracked обязана считать головы")
		TEST_ASSERT(findtext(row[1], admin_antag.real_name), "Строка untracked обязана называть антагов по именам - безымянная строка заставляла админов гадать, от кого нагрузка")

		// Мёртвый антаг уходит из строки: при нулевом остатке строки может не быть вовсе.
		admin_antag.death()
		var/list/after_death_rows = list()
		SSdirector.antag_load(after_death_rows)
		var/list/dead_row = untracked_row(after_death_rows)
		TEST_ASSERT_EQUAL(dead_row ? dead_row[2] : 0, base_value, "Мёртвый антаг не должен оставаться в строке untracked")
	catch(var/exception/e)
		admin_antag?.mind?.remove_antag_datum(/datum/antagonist)
		SSdirector.restore_simulation_state(saved)
		throw e
	admin_antag?.mind?.remove_antag_datum(/datum/antagonist)
	SSdirector.restore_simulation_state(saved)

/// Регрессия прод-раунда: визард-рулсеты не были persistent -> mode.process() не звал их
/// rule_process() -> снятие Summon Events (wizardmode) со смертью мага не срабатывало -> директор
/// глох на весь остаток раунда (все обычные события валили can_fire по wizardevent != wizardmode).
/datum/unit_test/director_wizard_summon_events_clears

/datum/unit_test/director_wizard_summon_events_clears/Run()
	var/datum/dynamic_ruleset/midround/wizard/crew_wizard = new
	var/datum/dynamic_ruleset/midround/from_ghosts/wizard/ghost_wizard = new
	TEST_ASSERT(crew_wizard.persistent, "Crew-визард обязан быть persistent, иначе rule_process не снимет wizardmode")
	TEST_ASSERT(ghost_wizard.persistent, "Гост-визард обязан быть persistent, иначе rule_process не снимет wizardmode")

	var/saved_wizardmode = SSdirector.wizardmode
	var/mob/living/carbon/human/mage = allocate(/mob/living/carbon/human)
	mage.mind_initialize()
	ghost_wizard.wizard = mage.mind
	try
		// Волшебник жив: режим не снимается, рулсет продолжает обрабатываться.
		SSdirector.wizardmode = TRUE
		TEST_ASSERT_EQUAL(ghost_wizard.rule_process(), FALSE, "Пока волшебник жив, rule_process не должен останавливаться")
		TEST_ASSERT(SSdirector.wizardmode, "Пока волшебник жив, Summon Events не снимается")
		// Волшебник мёртв: rule_process снимает wizardmode и останавливает обработку.
		mage.death()
		TEST_ASSERT_EQUAL(ghost_wizard.rule_process(), RULESET_STOP_PROCESSING, "Смерть волшебника обязана остановить обработку рулсета")
		TEST_ASSERT(!SSdirector.wizardmode, "Смерть волшебника обязана снять Summon Events")
	catch(var/exception/e)
		SSdirector.wizardmode = saved_wizardmode
		qdel(crew_wizard)
		qdel(ghost_wizard)
		throw e
	SSdirector.wizardmode = saved_wizardmode
	qdel(crew_wizard)
	qdel(ghost_wizard)

/// Во время Summon Events обычные события валят can_fire по wizardevent != wizardmode. diagnose
/// обязан назвать причину явно (wizardmode), а не сваливать весь пул в невнятное special.
/datum/unit_test/director_wizardmode_verdict

/datum/unit_test/director_wizardmode_verdict/Run()
	var/saved_wizardmode = SSdirector.wizardmode
	var/datum/director_signals/signals = new
	signals.effective_crew = 30
	signals.staffing = list(DIRECTOR_DEPT_SECURITY = 0, DIRECTOR_DEPT_ENGINEERING = 0,
		DIRECTOR_DEPT_MEDICAL = 0, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 0)
	var/datum/round_event_control/nothing/probe = new
	try
		SSdirector.wizardmode = FALSE
		TEST_ASSERT(probe.can_fire(signals), "Обычное событие вне Summon Events должно проходить can_fire")
		SSdirector.wizardmode = TRUE
		TEST_ASSERT(!probe.can_fire(signals), "Во время Summon Events обычное событие не должно проходить can_fire")
		var/list/diag = SSdirector.diagnose_can_fire(probe, signals)
		TEST_ASSERT_EQUAL(diag["reason"], DIRECTOR_CANTFIRE_WIZARDMODE, "Отказ во время Summon Events обязан диагностироваться как wizardmode, а не special")
	catch(var/exception/e)
		SSdirector.wizardmode = saved_wizardmode
		qdel(probe)
		throw e
	SSdirector.wizardmode = saved_wizardmode
	qdel(probe)

/// Регрессия "в харду каждый раунд дьявол": цель копилки, зафиксированная в бедном пуле
/// первых минут (единственный доступный вариант), обязана перевыбираться, когда в пуле
/// появляются действия, которых на момент выбора не было.
/datum/unit_test/director_pool_target_growth_reroll

/datum/unit_test/director_pool_target_growth_reroll/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		SSdirector.profile = new /datum/director_profile/medium
		SSdirector.pool_saving = list()
		SSdirector.pool_target_options = list()
		SSdirector.action_failure_cooldowns = list()

		var/datum/director_signals/signals = new
		signals.effective_crew = 30
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 2, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/datum/director_action/test_stub/lone = new
		lone.severity = DIRECTOR_SEVERITY_GHOST
		// Другой подтип стаба: детект роста ключуется по action_name() (уникально у реального
		// контента - см. director_action_tagging), одинаковый тип сделал бы тест вакуумным.
		var/datum/director_action/test_stub/fails/newcomer = new
		newcomer.severity = DIRECTOR_SEVERITY_GHOST
		newcomer.min_players = 50 // пока закрыт по онлайну - "ранний пул из одного дьявола"
		SSdirector.actions = list(lone, newcomer)

		SSdirector.ensure_pool_targets(signals)
		TEST_ASSERT_EQUAL(SSdirector.pool_saving[DIRECTOR_SEVERITY_GHOST], lone, "Единственный доступный вариант обязан стать целью копилки")

		// Пул не изменился - валидная цель стабильна (план не дёргается каждый бит).
		SSdirector.ensure_pool_targets(signals)
		TEST_ASSERT_EQUAL(SSdirector.pool_saving[DIRECTOR_SEVERITY_GHOST], lone, "Без роста пула валидная цель не должна перевыбираться")

		// Пул вырос: newcomer открылся по онлайну. Детектор роста ассертим прямо: реролл в
		// ensure_pool_targets срабатывает и по затуханию веса старой цели (см.
		// director_pool_target_weight_staleness), интеграционный ассерт ниже их не различает.
		newcomer.min_players = 0
		var/list/grown = SSdirector.collect_pool_options(DIRECTOR_SEVERITY_GHOST, signals)
		TEST_ASSERT(SSdirector.pool_options_grew(DIRECTOR_SEVERITY_GHOST, grown), "Открывшееся действие обязано детектиться как рост пула")
		lone.weight = 0 // делает перевыбор детерминированным: единственная опция - newcomer
		SSdirector.ensure_pool_targets(signals)
		TEST_ASSERT_EQUAL(SSdirector.pool_saving[DIRECTOR_SEVERITY_GHOST], newcomer, "Рост пула обязан перевыбирать цель, зафиксированную в бедном наборе")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Копилка обязана отражать живое условие веса. Вес Lone Operative растёт, пока диск лежит
/// без движения, и затухает при переноске (nuclearbomb.dm): план, нацеленный при лежащем
/// диске, обязан сниматься, как только вес затух до нуля, - иначе оперативник приходит
/// спустя полчаса после того, как диск давно носят (жалоба прода "спавнится рандомно").
/datum/unit_test/director_pool_target_weight_staleness

/datum/unit_test/director_pool_target_weight_staleness/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		SSdirector.profile = new /datum/director_profile/medium
		SSdirector.pool_saving = list()
		SSdirector.pool_target_options = list()
		SSdirector.action_failure_cooldowns = list()

		var/datum/director_signals/signals = new
		signals.effective_crew = 30
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 2, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/datum/director_action/test_stub/lone = new
		lone.severity = DIRECTOR_SEVERITY_GHOST
		lone.weight = 1 // диск полежал: событие едва открылось
		SSdirector.actions = list(lone)

		SSdirector.ensure_pool_targets(signals)
		TEST_ASSERT_EQUAL(SSdirector.pool_saving[DIRECTOR_SEVERITY_GHOST], lone, "Действие с живым весом обязано становиться целью копилки")

		// Диск унесли: вес затух до нуля. План обязан сняться, а не висеть до исполнения.
		lone.weight = 0
		SSdirector.ensure_pool_targets(signals)
		TEST_ASSERT_NULL(SSdirector.pool_saving[DIRECTOR_SEVERITY_GHOST], "Цель с затухшим до нуля весом обязана сниматься с копилки")

		// Диск снова лежит: вес вернулся - действие снова может стать планом.
		lone.weight = 1
		SSdirector.ensure_pool_targets(signals)
		TEST_ASSERT_EQUAL(SSdirector.pool_saving[DIRECTOR_SEVERITY_GHOST], lone, "Вернувшийся вес обязан возвращать действие в план копилки")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Замена после провала гост-опроса обязана быть по средствам: перевыбранная цель дороже
/// кошелька уступает исполнимому сейчас варианту (прод-раунд: после провала метеора копилка
/// целилась в рейдеров за 15 при 12.5 в кошельке - "запрошена замена" без замены).
/datum/unit_test/director_pool_affordable_replacement

/datum/unit_test/director_pool_affordable_replacement/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		SSdirector.profile = new /datum/director_profile/medium
		SSdirector.pool_target_options = list()
		SSdirector.action_failure_cooldowns = list()

		var/datum/director_signals/signals = new
		signals.effective_crew = 30
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 2, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/datum/director_action/test_stub/expensive = new
		expensive.severity = DIRECTOR_SEVERITY_GHOST
		expensive.cost = 15
		var/datum/director_action/test_stub/cheap = new
		cheap.severity = DIRECTOR_SEVERITY_GHOST
		cheap.cost = 8
		SSdirector.actions = list(expensive, cheap)

		SSdirector.budgets[DIRECTOR_SEVERITY_GHOST] = 10
		SSdirector.pool_saving = list(DIRECTOR_SEVERITY_GHOST = expensive)
		SSdirector.reroll_pool_target_affordable(DIRECTOR_SEVERITY_GHOST, signals)
		TEST_ASSERT_EQUAL(SSdirector.pool_saving[DIRECTOR_SEVERITY_GHOST], cheap, "Цель дороже кошелька обязана уступить варианту по средствам")

		// Вариантов по средствам нет - дорогой план остаётся копиться, а не обнуляется.
		SSdirector.pool_saving[DIRECTOR_SEVERITY_GHOST] = expensive
		SSdirector.budgets[DIRECTOR_SEVERITY_GHOST] = 5
		SSdirector.reroll_pool_target_affordable(DIRECTOR_SEVERITY_GHOST, signals)
		TEST_ASSERT_EQUAL(SSdirector.pool_saving[DIRECTOR_SEVERITY_GHOST], expensive, "Без вариантов по средствам дорогой план должен сохраниться")

		// Цель уже по средствам - план стабилен, даже если рядом жирная альтернатива.
		SSdirector.budgets[DIRECTOR_SEVERITY_GHOST] = 20
		cheap.weight = 100
		SSdirector.reroll_pool_target_affordable(DIRECTOR_SEVERITY_GHOST, signals)
		TEST_ASSERT_EQUAL(SSdirector.pool_saving[DIRECTOR_SEVERITY_GHOST], expensive, "Цель по средствам не должна перевыбираться")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Кнопка "замены" обязана реально предлагать замену: у ANTAG/GHOST-пиков список кандидатов
/// почти всегда из одного действия (гейт копилки), и раньше реролл молча очищал pending,
/// ничего не предлагая взамен.
/datum/unit_test/director_admin_reroll_replaces

/datum/unit_test/director_admin_reroll_replaces/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/profile = new /datum/director_profile/medium
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.live_ghost_role_spawns = list()
		SSdirector.fired_counts = list()
		SSdirector.pool_saving = list()
		SSdirector.pool_target_options = list()
		SSdirector.action_failure_cooldowns = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_GHOST = world.time - profile.ghost_light_spacing - 1,
		)
		SSdirector.last_ghost_heavy_at = world.time - profile.ghost_heavy_spacing - 1
		SSdirector.last_any_fired_at = world.time - profile.global_spacing - 1

		var/datum/director_signals/signals = new
		signals.effective_crew = 30
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 2, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/datum/director_action/test_stub/picked = new
		picked.severity = DIRECTOR_SEVERITY_GHOST
		picked.cost = 5
		var/datum/director_action/test_stub/alternative = new
		alternative.severity = DIRECTOR_SEVERITY_GHOST
		alternative.cost = 5
		SSdirector.actions = list(picked, alternative)

		// Типичный антаг-пик: единственный кандидат (гейт копилки оставил только цель).
		SSdirector.pending_action = picked
		SSdirector.pending_candidates = list()
		SSdirector.pending_candidates[picked] = 100
		SSdirector.pending_guaranteed = FALSE
		SSdirector.pending_signals = signals
		SSdirector.replace_pending_action(signals)
		TEST_ASSERT_EQUAL(SSdirector.pending_action, alternative, "Реролл единственного кандидата обязан предложить замену свежим отбором той же ступени")
		TEST_ASSERT(SSdirector.action_recently_failed(picked), "Отклонённое действие обязано получить карантин, иначе отбор предложит его же")
		deltimer(SSdirector.pending_timer_id)
		SSdirector.pending_action = null
		SSdirector.pending_candidates = null
		SSdirector.pending_signals = null
		SSdirector.pending_timer_id = null

		// Замены нет вовсе (второе действие в карантине с прошлого реролла): pending чисто
		// снимается без рантайма и без зависшего таймера.
		SSdirector.pending_action = alternative
		SSdirector.pending_candidates = list()
		SSdirector.pending_candidates[alternative] = 100
		SSdirector.pending_signals = signals
		SSdirector.replace_pending_action(signals)
		TEST_ASSERT_NULL(SSdirector.pending_action, "Без готовой замены pending обязан сняться, а не зависнуть")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Новые экипажные конверсии обязаны жить в ANTAG-пуле рядом со слипером: пул из одного
/// лёгкого рулсета делал каждую экипажную инжекцию трейтором ("никакого разнообразия").
/datum/unit_test/director_crew_conversion_variants

/datum/unit_test/director_crew_conversion_variants/Run()
	var/datum/dynamic_ruleset/midround/crew_conversion/base_path = /datum/dynamic_ruleset/midround/crew_conversion
	TEST_ASSERT_EQUAL(initial(base_path.name), "", "Каркас crew_conversion не должен регистрироваться сам (init_rulesets отсекает пустые имена)")
	var/datum/dynamic_ruleset/midround/crew_conversion/heretic/heretic_rule = new
	var/datum/dynamic_ruleset/midround/crew_conversion/changeling/changeling_rule = new
	try
		for(var/datum/dynamic_ruleset/midround/crew_conversion/rule as anything in list(heretic_rule, changeling_rule))
			TEST_ASSERT_EQUAL(rule.severity, DIRECTOR_SEVERITY_ANTAG, "[rule.name]: экипажная конверсия обязана жить в ANTAG-пуле")
			TEST_ASSERT(rule.weight > 0, "[rule.name]: конверсия обязана участвовать в естественном выборе")
			TEST_ASSERT(!rule.admin_only, "[rule.name]: конверсия не должна быть admin_only")
			TEST_ASSERT(rule.intensity > 0, "[rule.name]: конверсия обязана давать вклад в intensity")
			TEST_ASSERT(ROUNDTYPE_DYNAMIC_MEDIUM in rule.required_round_type, "[rule.name]: конверсия обязана быть доступна в Medium")
			TEST_ASSERT_NOTNULL(rule.antag_datum, "[rule.name]: конверсия обязана нести антаг-датум")
	catch(var/exception/e)
		qdel(heretic_rule)
		qdel(changeling_rule)
		throw e
	qdel(heretic_rule)
	qdel(changeling_rule)

/// Гост-команды затухают по возрасту, а вне станции давят вполсилы: улетевшие с лутом
/// рейдеры (прод-раунд: 45 нагрузки до конца смены) больше не запирают антаг-каналы
/// навсегда. Слежение через weakref-моба - без множителя активности, детерминированно.
/datum/unit_test/director_ghost_spawn_decay

/datum/unit_test/director_ghost_spawn_decay/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		SSdirector.profile = new /datum/director_profile/medium
		SSdirector.actions = list()
		SSdirector.intensity_ledger = list()
		SSdirector.live_ghost_role_spawns = list()
		var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
		TEST_ASSERT(length(station_levels), "В тестовом мире нет станционного z-уровня")
		var/turf/station_turf = locate(round(world.maxx / 2), round(world.maxy / 2), station_levels[1])
		var/mob/living/carbon/human/raider = allocate(/mob/living/carbon/human)
		// Тест-зона живёт на reserved z (не станция): прямая проверка веса присутствия.
		TEST_ASSERT_EQUAL(SSdirector.ghost_member_presence(raider), DIRECTOR_OFFSTATION_ANTAG_MULT,
			"Вне станции член гост-команды должен давить вполсилы")
		raider.forceMove(station_turf)
		TEST_ASSERT_EQUAL(SSdirector.ghost_member_presence(raider), 1, "На станции член гост-команды даёт полный вес")

		SSdirector.live_ghost_role_spawns = list(list(
			"name" = "Test Ghost Team",
			"intensity" = 40,
			"severity" = DIRECTOR_SEVERITY_GHOST,
			"minds" = list(),
			"hard_minds" = list(),
			"mobs" = list(WEAKREF(raider)),
			"refund_values" = list(),
			"at" = SSticker.round_start_time,
		))
		// Свежая команда на станции - полный вклад.
		SSdirector.time_override = SSticker.round_start_time + 1 MINUTES
		TEST_ASSERT_EQUAL(SSdirector.get_ghost_role_intensity(only_antag = TRUE), 40,
			"Свежая гост-команда на станции обязана давать полную intensity")
		// Старая команда оседает к полу затухания, как рулсет.
		SSdirector.time_override = SSticker.round_start_time + 150 MINUTES
		TEST_ASSERT_EQUAL(SSdirector.get_ghost_role_intensity(only_antag = TRUE), 40 * DIRECTOR_RULESET_DECAY_FLOOR,
			"Старая гост-команда обязана затухать к полу, как рулсет")
		// Команда улетела со станции - вклад вполсилы.
		SSdirector.time_override = SSticker.round_start_time + 1 MINUTES
		raider.forceMove(run_loc_floor_bottom_left)
		TEST_ASSERT_EQUAL(SSdirector.get_ghost_role_intensity(only_antag = TRUE), 40 * DIRECTOR_OFFSTATION_ANTAG_MULT,
			"Улетевшая гост-команда обязана давить вполсилы")
	catch(var/exception/e)
		SSdirector.time_override = 0
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.time_override = 0
	SSdirector.restore_simulation_state(saved)

/// Гейты запаса цели: тяжёлая команда покупается только в достаточно пустой раунд,
/// а лёгкая роль теряет вес пропорционально нехватке места (прод-раунд: рейдеры 45
/// в запас 9.8 пробили цель почти вдвое и заперли антаг-каналы до конца смены).
/datum/unit_test/director_antag_headroom

/datum/unit_test/director_antag_headroom/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/medium/profile = new
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.live_ghost_role_spawns = list()
		SSdirector.fired_counts = list()
		SSdirector.pool_saving = list()
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_GHOST = world.time - profile.ghost_light_spacing - 1,
		)
		SSdirector.last_ghost_heavy_at = world.time - profile.ghost_heavy_spacing - 1

		var/datum/director_action/test_stub/heavy_team = new
		heavy_team.severity = DIRECTOR_SEVERITY_GHOST
		heavy_team.antag_heavy = TRUE
		heavy_team.intensity = 45
		var/datum/director_action/test_stub/light_control = new
		light_control.severity = DIRECTOR_SEVERITY_GHOST
		light_control.intensity = 0 // без intensity headroom-вес не применяется - контроль
		var/datum/director_action/test_stub/light_big = new
		light_big.severity = DIRECTOR_SEVERITY_GHOST
		light_big.intensity = 40 // не влезает в остаток цели - вес у пола
		SSdirector.actions = list(heavy_team, light_control, light_big)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40 // цель Medium = 60, порог heavy = 30
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		// Дельта от живой базы CI-раунда: нужную нагрузку доводим мостом в ledger.
		var/base_load = SSdirector.antag_load()
		TEST_ASSERT(base_load < 20, "База CI-раунда неожиданно нагружена ([base_load]) - тест недостоверен")
		// Нагрузка 40: выше порога heavy (30), ниже цели (60) - heavy отсечён, лёгкие живы.
		SSdirector.intensity_ledger = list(list("Тестовый мост нагрузки", 40 - base_load, 0, DIRECTOR_SEVERITY_GHOST))
		var/list/reject_stats = list()
		var/list/candidates = SSdirector.filter_candidates(signals, FALSE, reject_stats)
		TEST_ASSERT(!(heavy_team in candidates), "Тяжёлая команда при нагрузке выше порога не должна быть кандидатом")
		var/list/ghost_rejects = reject_stats[DIRECTOR_SEVERITY_GHOST]
		TEST_ASSERT(islist(ghost_rejects) && ghost_rejects[DIRECTOR_REJECT_ANTAG_HEADROOM],
			"Отсев тяжёлой команды обязан значиться причиной antag_headroom")
		TEST_ASSERT(light_control in candidates, "Лёгкая роль без intensity обязана остаться кандидатом")
		TEST_ASSERT(light_big in candidates, "Лёгкая роль с большой intensity остаётся кандидатом (вес у пола, не отсев)")
		TEST_ASSERT(candidates[light_big] < candidates[light_control],
			"Не влезающая в запас роль обязана весить меньше контрольной")
		// Пустой раунд: heavy возвращается в кандидаты.
		SSdirector.intensity_ledger = list()
		candidates = SSdirector.filter_candidates(signals)
		TEST_ASSERT(heavy_team in candidates, "В пустом раунде тяжёлая команда обязана вернуться в кандидаты")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Гарантия после двойной тишины при дефиците антагов может купить гост-роль,
/// но только за честную цену из кошелька GHOST - бесплатных антагов гарантия не раздаёт.
/datum/unit_test/director_guaranteed_ghost

/datum/unit_test/director_guaranteed_ghost/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch (см. director_beat_logic).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/director_profile/medium/profile = new
		SSdirector.profile = profile
		SSdirector.reset_budgets(100)
		SSdirector.intensity_ledger = list()
		SSdirector.live_ghost_role_spawns = list()
		SSdirector.fired_counts = list()
		SSdirector.pool_saving = list()
		SSdirector.pending_action = null
		SSdirector.last_fired_at = list(
			DIRECTOR_SEVERITY_GHOST = world.time - profile.ghost_light_spacing - 1,
		)
		var/datum/director_action/test_stub/ghost_role = new
		ghost_role.severity = DIRECTOR_SEVERITY_GHOST
		ghost_role.cost = 10
		ghost_role.intensity = 15
		SSdirector.actions = list(ghost_role)

		var/datum/director_signals/signals = new
		signals.effective_crew = 40
		signals.staffing = list(DIRECTOR_DEPT_SECURITY = 4, DIRECTOR_DEPT_ENGINEERING = 1,
			DIRECTOR_DEPT_MEDICAL = 1, DIRECTOR_DEPT_SCIENCE = 0, DIRECTOR_DEPT_SUPPLY = 0, DIRECTOR_DEPT_COMMAND = 1)

		var/list/candidates = SSdirector.filter_candidates(signals, TRUE)
		TEST_ASSERT(!(ghost_role in candidates), "Обычная гарантия не должна видеть GHOST")
		candidates = SSdirector.filter_candidates(signals, TRUE, allow_ghost_guarantee = TRUE)
		TEST_ASSERT(ghost_role in candidates, "Расширенная гарантия обязана видеть GHOST при полном кошельке")
		SSdirector.budgets[DIRECTOR_SEVERITY_GHOST] = 0
		candidates = SSdirector.filter_candidates(signals, TRUE, allow_ghost_guarantee = TRUE)
		TEST_ASSERT(!(ghost_role in candidates), "Гарантия не должна выдавать гост-роль бесплатно")

		// Проводка run_beat: двойная тишина + полный дефицит открывают GHOST гарантии.
		SSdirector.budgets[DIRECTOR_SEVERITY_GHOST] = 100
		SSdirector.dry_run = TRUE
		SSdirector.last_any_fired_at = world.time - 30 SECONDS
		SSdirector.last_real_fired_at = world.time - profile.max_quiet_time * 2 - 1
		SSdirector.last_antag_deficit = 1
		signals.event_intensity = 0
		TEST_ASSERT_EQUAL(SSdirector.run_beat(signals), DIRECTOR_BEAT_GUARANTEED,
			"Гарантия двойной тишины обязана исполнить гост-роль")
		TEST_ASSERT_EQUAL(SSdirector.fired_counts[DIRECTOR_SEVERITY_GHOST], 1,
			"Гарантированный бит обязан реально запустить гост-роль")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

/// Аванс антаг-кошельков на setup_profile: первая гост-роль больше не ждёт ~25 минут
/// дефицит-капли - GHOST стартует с долей аванса поверх общего initial_grant.
/datum/unit_test/director_antag_initial_grant

/datum/unit_test/director_antag_initial_grant/Run()
	// Мутирует живой SSdirector и GLOB.round_type - восстанавливаем оба даже при падении.
	var/list/saved = SSdirector.capture_simulation_state()
	var/saved_round_type = GLOB.round_type
	try
		GLOB.round_type = ROUNDTYPE_DYNAMIC_MEDIUM
		SSdirector.reset_budgets(0)
		SSdirector.setup_profile()
		var/datum/director_profile/profile = SSdirector.profile
		TEST_ASSERT_EQUAL(profile.round_type, ROUNDTYPE_DYNAMIC_MEDIUM, "setup_profile обязан выбрать Medium по типу раунда")
		var/ghost_after = SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		var/antag_after = SSdirector.budgets[DIRECTOR_SEVERITY_ANTAG]
		// Контроль: раздача только общего аванса тем же профилем - разница и есть антаг-аванс.
		SSdirector.reset_budgets(0)
		SSdirector.distribute_to_budgets(profile.initial_grant)
		var/ghost_base = SSdirector.budgets[DIRECTOR_SEVERITY_GHOST]
		var/ghost_share = profile.pool_shares[DIRECTOR_SEVERITY_GHOST] || 0
		var/antag_share = profile.pool_shares[DIRECTOR_SEVERITY_ANTAG] || 0
		TEST_ASSERT(ghost_share + antag_share > 0, "У Medium должны быть антаг-доли")
		var/expected_bonus = profile.antag_initial_grant * ghost_share / (ghost_share + antag_share)
		TEST_ASSERT(abs((ghost_after - ghost_base) - expected_bonus) < 0.01,
			"GHOST-кошелёк обязан получить аванс [expected_bonus] поверх общей доли (получил [ghost_after - ghost_base])")
		TEST_ASSERT(antag_after > 0, "ANTAG-кошелёк обязан получить свою долю аванса")
	catch(var/exception/e)
		GLOB.round_type = saved_round_type
		SSdirector.restore_simulation_state(saved)
		throw e
	GLOB.round_type = saved_round_type
	SSdirector.restore_simulation_state(saved)

/// Критерий реального контента для таймера тишины: MINOR без intensity (лотереи,
/// бумажные события) не считается происходящим, MODERATE и MINOR с вкладом - считаются.
/datum/unit_test/director_real_content

/datum/unit_test/director_real_content/Run()
	var/datum/director_action/test_stub/probe = new
	probe.severity = DIRECTOR_SEVERITY_MINOR
	probe.intensity = 0
	TEST_ASSERT(!SSdirector.is_real_content(probe), "MINOR без intensity не должен считаться реальным контентом")
	probe.intensity = 5
	TEST_ASSERT(SSdirector.is_real_content(probe), "MINOR с intensity обязан считаться реальным контентом")
	probe.severity = DIRECTOR_SEVERITY_FLAVOR
	probe.intensity = 10
	TEST_ASSERT(!SSdirector.is_real_content(probe), "Флейвор не считается реальным контентом даже с intensity")
	probe.severity = DIRECTOR_SEVERITY_MODERATE
	probe.intensity = 0
	TEST_ASSERT(SSdirector.is_real_content(probe), "MODERATE считается реальным контентом независимо от intensity")
	probe.filler = TRUE
	TEST_ASSERT(!SSdirector.is_real_content(probe), "Филлер не считается реальным контентом на любой ступени")
	qdel(probe)
