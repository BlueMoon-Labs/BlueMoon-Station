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

/// Проверяет динамический вклад живых рулсетов в get_active_intensity(): доля выживших,
/// строки разбивки для панели, вытеснение моста из ledger и суммирование с обычными записями.
/datum/unit_test/director_ruleset_intensity_breakdown

/datum/unit_test/director_ruleset_intensity_breakdown/Run()
	// Мутирует живой SSdirector - capture/restore c try/catch возвращает состояние даже при падении
	// ассерта (см. комментарий в director_beat_logic/Run()).
	var/list/saved = SSdirector.capture_simulation_state()
	try
		var/datum/dynamic_ruleset/midround/test_pool_isolation/rule = new
		rule.intensity = 15
		rule.occurrences = 1
		var/mob/living/carbon/human/alive = allocate(/mob/living/carbon/human)
		alive.mind_initialize()
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
		TEST_ASSERT_EQUAL(total, 15 * 0.5 + 5, "Итог: вклад рулсета по доле живых плюс запись события, без моста")
		TEST_ASSERT_EQUAL(length(SSdirector.intensity_ledger), 1, "Мост исполненного рулсета должен вытесниться из ledger")
		TEST_ASSERT_EQUAL(length(breakdown), 1, "Живой рулсет должен дать ровно одну строку разбивки")
		var/list/row = breakdown[1]
		TEST_ASSERT_EQUAL(row[1], rule.action_name(), "Имя строки разбивки должно совпадать с именем рулсета")
		TEST_ASSERT_EQUAL(row[2], 7.5, "Вклад строки = intensity * живые / назначенные")
		TEST_ASSERT_EQUAL(row[3], 1, "Число живых в строке разбивки")
		TEST_ASSERT_EQUAL(row[4], 2, "Число назначенных в строке разбивки")

		// Полностью мёртвый рулсет не даёт ни вклада, ни строки.
		alive.death()
		breakdown = list()
		total = SSdirector.get_active_intensity(breakdown)
		TEST_ASSERT_EQUAL(total, 5, "Мёртвый рулсет не должен давать вклада")
		TEST_ASSERT_EQUAL(length(breakdown), 0, "Мёртвый рулсет не должен давать строк разбивки")
	catch(var/exception/e)
		SSdirector.restore_simulation_state(saved)
		throw e
	SSdirector.restore_simulation_state(saved)

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
	// test_pool_isolation - фикстуры другого теста (director_latejoin_pool_isolation) в этом же файле,
	// не реальный игровой контент; требования тегирования на них не распространяются.
	var/list/tagging_test_fixtures = list(/datum/dynamic_ruleset/midround/test_pool_isolation, /datum/dynamic_ruleset/latejoin/test_pool_isolation)
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
	for(var/list/entry in log_out)
		if(entry["result"] == DIRECTOR_BEAT_FIRED || entry["result"] == DIRECTOR_BEAT_GUARANTEED)
			fired++
			quiet_streak = 0
		else
			quiet_streak++
			max_quiet_streak = max(max_quiet_streak, quiet_streak)
		max_intensity = max(max_intensity, entry["intensity"])
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
	for(var/list/entry in hard_log)
		if(entry["result"] != DIRECTOR_BEAT_FIRED && entry["result"] != DIRECTOR_BEAT_GUARANTEED)
			continue
		if(entry["severity"] == DIRECTOR_SEVERITY_MAJOR || (DIRECTOR_IS_ANTAG_POOL(entry["severity"]) && entry["antag_heavy"]))
			heavy_fired++
	TEST_ASSERT(heavy_fired >= 1, "За 2 часа Hard при 60 экипажа тяжёлая ступень (MAJOR или тяжёлый ANTAG) ни разу не выстрелила - голодание вернулось")

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
		SSdirector.last_any_fired_at = world.time
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
