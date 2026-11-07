/// У каждого станционного отдела есть датум и бюджет; TAR и DS - только бюджет.
/datum/unit_test/economy_departments_exist/Run()
	for(var/id in list(ACCOUNT_CMD, ACCOUNT_SEC, ACCOUNT_ENG, ACCOUNT_MED, ACCOUNT_SCI, ACCOUNT_CAR, ACCOUNT_SRV, ACCOUNT_CIV))
		var/datum/economy_department/department = SSeconomy.get_department(id)
		TEST_ASSERT_NOTNULL(department, "Нет отдела [id]")
		TEST_ASSERT(department.account == SSeconomy.get_dep_account(id), "Бюджет отдела [id]")
	TEST_ASSERT_NOTNULL(SSeconomy.get_dep_account(ACCOUNT_TAR), "Бюджет Tarkon")
	TEST_ASSERT_NULL(SSeconomy.get_department(ACCOUNT_TAR), "Tarkon вне станционной экономики")

/// Грант растёт с числом сотрудников на смене.
/datum/unit_test/economy_department_grant/Run()
	var/datum/economy_department/department = SSeconomy.get_department(ACCOUNT_SRV)
	var/datum/bank_account/worker = new("econ_test_worker")
	worker.department_id = ACCOUNT_SRV
	worker.pay_grade = PAY_GRADE_EASY
	var/before = department.account.account_balance
	department.grant()
	var/with_one = department.account.account_balance - before
	qdel(worker)
	var/datum/economy_settings/settings = SSeconomy.settings
	var/expected_min = settings.grant_base + round(settings.wages[PAY_GRADE_EASY] * settings.grant_payroll_share / 100 / settings.payroll_interval_ticks)
	TEST_ASSERT(with_one >= expected_min, "Грант с одним сотрудником: [with_one] < [expected_min]")

/// Долг перед NT гасится из поступлений, но не ниже нуля.
/datum/unit_test/economy_department_owed/Run()
	var/datum/economy_department/department = SSeconomy.get_department(ACCOUNT_CAR)
	var/balance = department.account.account_balance
	department.add_owed(balance + 500)
	department.settle_owed()
	var/after_settle = department.account.account_balance
	var/left_owed = department.owed
	department.owed = 0
	department.account.credit(balance, ECON_ADMIN)
	TEST_ASSERT_EQUAL(after_settle, 0, "Баланс ушёл на долг целиком")
	TEST_ASSERT_EQUAL(left_owed, 500, "Остаток долга")

/// Пустая станция (нет людей) не роняет fire().
/datum/unit_test/economy_fire_without_crew/Run()
	var/fires = SSeconomy.fire_count
	SSeconomy.fire()
	TEST_ASSERT_EQUAL(SSeconomy.fire_count, fires + 1, "fire() дошёл до конца")
