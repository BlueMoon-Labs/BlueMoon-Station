/datum/unit_test/economy_work
	abstract_type = /datum/unit_test/economy_work
	var/mob/living/carbon/human/performer
	var/mob/living/carbon/human/patient
	var/datum/bank_account/performer_account
	var/datum/bank_account/department/budget
	var/saved_budget
	var/list/stashed_contracts

/// В тестовом мире клиентов нет, а медицина оживляет только тело с игроком: пациент проходит ту же проверку, что учебная цель полигона.
/mob/living/carbon/human/econ_test_patient

/mob/living/carbon/human/econ_test_patient/is_antag_training_patient()
	return TRUE

/datum/unit_test/economy_work/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()

/datum/unit_test/economy_work/proc/setup_pair()
	performer = allocate(/mob/living/carbon/human)
	patient = allocate(/mob/living/carbon/human/econ_test_patient, run_loc_floor_top_right)
	performer.mind_initialize()
	patient.mind_initialize()
	performer.mind.key = "econ_test_medic"
	patient.mind.key = "econ_test_patient"
	performer_account = new("econ_test_medic")
	performer_account.department_id = ACCOUNT_MED
	performer.account_id = performer_account.account_id
	budget = SSeconomy.get_dep_account(ACCOUNT_MED)
	saved_budget = budget.account_balance

/datum/unit_test/economy_work/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	if(budget)
		budget.debit(max(budget.account_balance, 0), ECON_ADMIN)
		budget.credit(saved_budget, ECON_ADMIN)
		budget = null
	QDEL_NULL(performer_account)
	return ..()

/// Работа платит отделу по прайсу и исполнителю премию, повтор на того же субъекта - нет.
/datum/unit_test/economy_work/pays_and_cools_down/Run()
	setup_pair()
	var/before = budget.account_balance
	var/paid = SSeconomy.record_work(ACCOUNT_MED, WORK_MED_REVIVE, 1, performer, patient)
	var/price = SSeconomy.settings.work_prices[WORK_MED_REVIVE]
	TEST_ASSERT_EQUAL(paid, price, "Выплата отделу")
	TEST_ASSERT_EQUAL(budget.account_balance - before, price, "Бюджет вырос")
	TEST_ASSERT(performer_account.account_balance > 0, "Премия исполнителю")
	var/datum/economy_department/department = SSeconomy.get_department(ACCOUNT_MED)
	var/list/last_work = department.work_log[length(department.work_log)]
	TEST_ASSERT_EQUAL(last_work["type"], econ_work_name(WORK_MED_REVIVE), "Работа в журнале отдела")
	TEST_ASSERT_EQUAL(SSeconomy.record_work(ACCOUNT_MED, WORK_MED_REVIVE, 1, performer, patient), 0, "Кулдаун на субъекта")

/// Сам себе, свежий свой урон, моб без исполнителя и субъект без игрока - без выплаты; старый удар не мешает.
/datum/unit_test/economy_work/refusals/Run()
	setup_pair()
	TEST_ASSERT_EQUAL(SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, performer, performer), 0, "Сам себе")
	TEST_ASSERT_EQUAL(SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, null, patient), 0, "Моб без исполнителя")
	patient.set_last_attacker(performer)
	TEST_ASSERT_EQUAL(patient.lastattacker_time, world.time, "Время удара запомнено")
	patient.lastattackerckey = ckey(performer.mind.key)
	TEST_ASSERT_EQUAL(SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, performer, patient), 0, "Свежий свой урон")
	patient.lastattackerckey = null
	TEST_ASSERT(SSeconomy.record_work(ACCOUNT_MED, WORK_MED_DISCHARGE_HEAVY, 1, performer, patient) > 0, "Без удара исполнителя работа платится")
	patient.lastattackerckey = ckey(performer.mind.key)
	patient.lastattacker_time = world.time - (SSeconomy.settings.work_subject_cooldown_minutes MINUTES) - 1
	TEST_ASSERT(SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, performer, patient) > 0, "Удар старше окна не мешает")
	patient.mind.key = null
	TEST_ASSERT_EQUAL(SSeconomy.record_work(ACCOUNT_MED, WORK_MED_DISCHARGE_LIGHT, 1, performer, patient), 0, "Субъект без игрока")

/// Личная премия упирается в часовой потолок.
/datum/unit_test/economy_work/premium_cap/Run()
	setup_pair()
	var/cap = SSeconomy.settings.work_personal_cap_hour
	var/saved_tax = SSeconomy.tax_rate
	SSeconomy.tax_rate = 0
	for(var/i in 1 to 50)
		SSeconomy.record_work(ACCOUNT_MED, WORK_MED_REVIVE, 10, performer)
	SSeconomy.tax_rate = saved_tax
	TEST_ASSERT_EQUAL(performer_account.account_balance, cap, "Премия не выше потолка")

/// Работа без цены в прайсе и неизвестный отдел не платят.
/datum/unit_test/economy_work/unknown/Run()
	setup_pair()
	TEST_ASSERT_EQUAL(SSeconomy.record_work(ACCOUNT_MED, "no_such_work", 1, performer), 0, "Нет цены")
	TEST_ASSERT_EQUAL(SSeconomy.record_work("NOPE", WORK_MED_REVIVE, 1, performer), 0, "Нет отдела")

/// У каждой работы есть встроенная цена, economy.json перекрывает только отличное от встроенных чисел, частичный прайс меняет только свои цены, мусор отвергается.
/datum/unit_test/economy_work/prices_config/Run()
	var/datum/economy_settings/defaults = new
	var/datum/economy_settings/settings = new
	TEST_ASSERT(!length(settings.load(ECONOMY_CONFIG_PATH)), "economy.json грузится без ошибок")
	for(var/work_type in GLOB.econ_work_names)
		TEST_ASSERT(isnum(defaults.work_prices[work_type]), "Нет цены у работы [work_type]")
	var/list/overrides = settings.raw["settings"] || list()
	for(var/key in overrides)
		if(ECON_CONFIG_COMMENT_KEY(key))
			continue
		if(!(key in defaults.vars))
			TEST_FAIL("economy.json: неизвестный ключ settings.[key]")
			continue
		var/list/nested = overrides[key]
		if(!islist(nested))
			TEST_ASSERT(overrides[key] != defaults.vars[key], "economy.json повторяет встроенное settings.[key]")
			continue
		var/list/builtin = defaults.vars[key]
		if(!islist(builtin))
			TEST_FAIL("economy.json: settings.[key] - список, а встроенное значение нет")
			continue
		for(var/entry in nested)
			TEST_ASSERT(nested[entry] != builtin[entry], "economy.json повторяет встроенное settings.[key].[entry]")
	var/path = "data/unit_test_economy_work_prices.json"
	fdel(path)
	text2file("{\"settings\": {\"work_prices\": {\"med_revive\": 999, \"med_surgery\": -5, \"no_such_work\": 1}}}", path)
	var/datum/economy_settings/partial = new
	var/list/errors = partial.load(path)
	fdel(path)
	TEST_ASSERT_EQUAL(length(errors), 2, "Отрицательная цена и неизвестная работа ([jointext(errors, "; ")])")
	TEST_ASSERT_EQUAL(partial.work_prices[WORK_MED_REVIVE], 999, "Указанная цена применилась")
	TEST_ASSERT_EQUAL(length(partial.work_prices), length(defaults.work_prices), "Неизвестная работа не добавлена")
	for(var/work_type in defaults.work_prices)
		if(work_type != WORK_MED_REVIVE)
			TEST_ASSERT_EQUAL(partial.work_prices[work_type], defaults.work_prices[work_type], "Цена [work_type] сохранилась")
	text2file("{\"settings\": {\"work_prices\": {}}}", path)
	var/datum/economy_settings/empty = new
	empty.load(path)
	fdel(path)
	TEST_ASSERT_EQUAL(empty.work_prices[WORK_MED_REVIVE], defaults.work_prices[WORK_MED_REVIVE], "Пустой прайс не обнуляет цены")
