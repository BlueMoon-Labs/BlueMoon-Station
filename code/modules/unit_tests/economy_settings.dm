/// economy.json из репозитория грузится без ошибок и задаёт ненулевые основные числа.
/datum/unit_test/economy_settings_repo_config/Run()
	var/datum/economy_settings/settings = new
	var/list/errors = settings.load(ECONOMY_CONFIG_PATH)
	TEST_ASSERT(!length(errors), "economy.json: [jointext(errors, "; ")]")
	TEST_ASSERT(settings.wage_floor > 0, "wage_floor не задан")
	TEST_ASSERT_EQUAL(length(settings.wages), 6, "Шесть грейдов зарплаты")
	TEST_ASSERT(islist(settings.raw), "Сырой JSON сохранён для секций рынка")

/// Неверный тип и неизвестный ключ отвергаются, дефолт остаётся.
/datum/unit_test/economy_settings_rejects_bad_keys/Run()
	var/path = "data/unit_test_economy_bad.json"
	fdel(path)
	text2file("{\"settings\": {\"wage_floor\": \"много\", \"no_such_key\": 1, \"_note\": \"x\"}}", path)
	var/datum/economy_settings/settings = new
	var/list/errors = settings.load(path)
	fdel(path)
	TEST_ASSERT_EQUAL(length(errors), 2, "Две ошибки: тип и неизвестный ключ; ключ с _ игнорируется")
	TEST_ASSERT_EQUAL(settings.wage_floor, initial(settings.wage_floor), "Дефолт не перезаписан мусором")

/// Валидный ключ из JSON перекрывает дефолт, нулевой интервал и зарплаты без грейда отвергаются.
/datum/unit_test/economy_settings_validates_values/Run()
	var/path = "data/unit_test_economy_values.json"
	fdel(path)
	text2file("{\"settings\": {\"tax_max\": 7, \"payroll_interval_ticks\": 0, \"tax_default\": 101, \"wage_floor\": -1, \"wages\": {\"assistant\": 1}}}", path)
	var/datum/economy_settings/settings = new
	var/list/errors = settings.load(path)
	fdel(path)
	TEST_ASSERT_EQUAL(settings.tax_max, 7, "Значение из JSON не применилось")
	TEST_ASSERT_EQUAL(length(errors), 4, "Ошибки: интервал, процент, сумма, зарплаты ([jointext(errors, "; ")])")
	TEST_ASSERT_EQUAL(settings.payroll_interval_ticks, initial(settings.payroll_interval_ticks), "Нулевой интервал выплат принят")
	TEST_ASSERT_EQUAL(settings.tax_default, initial(settings.tax_default), "Налог выше 100% принят")
	TEST_ASSERT_EQUAL(settings.wage_floor, initial(settings.wage_floor), "Отрицательная сумма принята")
	TEST_ASSERT_EQUAL(length(settings.wages), 6, "Зарплаты без грейдов приняты")

/// Любое число баланса перекрывается из economy.json без правки кода: каждый ключ настроек принимается, новые числа стоков и цены работ применяются.
/datum/unit_test/economy_settings_all_keys_overridable/Run()
	var/datum/economy_settings/defaults = new
	var/datum/bare = new
	var/list/section = list()
	for(var/var_name in defaults.vars)
		if((var_name in bare.vars) || var_name == "raw")
			continue
		section[var_name] = defaults.vars[var_name]
	qdel(bare)
	section["tax_nt_share"] = 40
	section["budget_cap_paydays"] = 8
	section["budget_cap_return_share"] = 30
	section["budget_cap_grace_ticks"] = 5
	section["saving_goal_minutes"] = 45
	section["slot_house_edge"] = 12
	section["slot_card_deposit_max"] = 2000
	section["lottery_house_share"] = 20
	section["vend_premium_sink_share"] = 70
	section["grant_payroll_share"] = 90
	section["contract_work_mult"] = 0.8
	section["department_sink_target_min"] = 55
	section["work_prices"] = list(WORK_MED_SURGERY = 321, WORK_ENG_INTEGRITY = 3)
	var/path = "data/unit_test_economy_all_keys.json"
	fdel(path)
	text2file(json_encode(list("settings" = section)), path)
	var/datum/economy_settings/settings = new
	var/list/errors = settings.load(path)
	fdel(path)
	TEST_ASSERT(!length(errors), "Ключи настроек отвергнуты: [jointext(errors, "; ")]")
	TEST_ASSERT_EQUAL(settings.tax_nt_share, 40, "tax_nt_share")
	TEST_ASSERT_EQUAL(settings.budget_cap_paydays, 8, "budget_cap_paydays")
	TEST_ASSERT_EQUAL(settings.budget_cap_return_share, 30, "budget_cap_return_share")
	TEST_ASSERT_EQUAL(settings.budget_cap_grace_ticks, 5, "budget_cap_grace_ticks")
	TEST_ASSERT_EQUAL(settings.saving_goal_minutes, 45, "saving_goal_minutes")
	TEST_ASSERT_EQUAL(settings.slot_house_edge, 12, "slot_house_edge")
	TEST_ASSERT_EQUAL(settings.slot_card_deposit_max, 2000, "slot_card_deposit_max")
	TEST_ASSERT_EQUAL(settings.lottery_house_share, 20, "lottery_house_share")
	TEST_ASSERT_EQUAL(settings.vend_premium_sink_share, 70, "vend_premium_sink_share")
	TEST_ASSERT_EQUAL(settings.grant_payroll_share, 90, "grant_payroll_share")
	TEST_ASSERT(abs(settings.contract_work_mult - 0.8) < 0.001, "contract_work_mult")
	TEST_ASSERT_EQUAL(settings.department_sink_target_min, 55, "department_sink_target_min")
	TEST_ASSERT_EQUAL(settings.work_prices[WORK_MED_SURGERY], 321, "Цена операции")
	TEST_ASSERT_EQUAL(settings.work_prices[WORK_ENG_INTEGRITY], 3, "Цена исправности")
	TEST_ASSERT_EQUAL(settings.work_prices[WORK_MED_REVIVE], defaults.work_prices[WORK_MED_REVIVE], "Неуказанная цена работы сохранилась")

/// Каждая причина имеет категорию и русское название.
/datum/unit_test/economy_reasons_complete/Run()
	for(var/reason in GLOB.econ_reason_category)
		TEST_ASSERT(GLOB.econ_reason_names[reason], "Нет названия у причины [reason]")
	TEST_ASSERT_EQUAL(econ_pay_grade(PAYCHECK_COMMAND), PAY_GRADE_COMMAND, "Командный грейд")
	TEST_ASSERT_EQUAL(econ_pay_grade(PAYCHECK_ASSISTANT), PAY_GRADE_ASSISTANT, "Грейд ассистента")

/datum/unit_test/economy_abstract_parent
	abstract_type = /datum/unit_test/economy_abstract_parent

/// Абстрактный родитель без Run() не попадает в запуск ни полным списком, ни файлом-списком.
/datum/unit_test/economy_abstract_parent/child/Run()
	var/list/runnable = runnable_unit_tests()
	TEST_ASSERT(!(/datum/unit_test/economy_abstract_parent in runnable), "Абстрактный родитель в полном списке запуска")
	TEST_ASSERT(type in runnable, "Подтип абстрактного родителя выпал из списка запуска")
	var/path = "data/unit_test_abstract_list.txt"
	fdel(path)
	text2file("/datum/unit_test/economy_abstract_parent\n[type]\n", path)
	var/list/results = list()
	var/list/listed = unit_tests_from_list_file(path, results)
	fdel(path)
	TEST_ASSERT_EQUAL(length(results), 0, "Абстрактный родитель в файле-списке засчитан как ошибка")
	TEST_ASSERT_EQUAL(length(listed), 1, "Из файла-списка запускается только подтип")
	TEST_ASSERT(listed[1] == type, "Из файла-списка запускается только подтип")
