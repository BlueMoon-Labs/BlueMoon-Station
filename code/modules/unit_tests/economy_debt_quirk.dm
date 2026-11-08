/// Квирк «В долгах»: подъёмные уходят в счёт долга NT, дальше долг гасится долей зарплаты на руки, счёт остаётся рабочим.
/datum/unit_test/economy_debt_quirk
	var/saved_tax_rate

/datum/unit_test/economy_debt_quirk/New()
	. = ..()
	saved_tax_rate = SSeconomy.tax_rate
	SSeconomy.tax_rate = 0

/datum/unit_test/economy_debt_quirk/Destroy()
	SSeconomy.tax_rate = saved_tax_rate
	return ..()

/datum/unit_test/economy_debt_quirk/Run()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/mob/living/carbon/human/debtor = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new("econ_test_debtor")
	account.department_id = ACCOUNT_SRV
	account.pay_grade = PAY_GRADE_EASY
	account.bind_owner(debtor)
	debtor.account_id = account.account_id
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/saved_service = service.account.account_balance
	econ_test_set_balance(service.account, 100000)
	var/start_funds = 400
	account.credit(start_funds, ECON_STARTING_FUNDS)
	debtor.add_quirk(/datum/quirk/nt_debt, TRUE)
	TEST_ASSERT_EQUAL(account.account_balance, 0, "Подъёмные не ушли в счёт долга")
	TEST_ASSERT_EQUAL(account.nt_debt, settings.quirk_debt_amount - start_funds, "Долг после подъёмных")
	var/debt_before = account.nt_debt
	account.payday()
	var/wage = settings.wages[PAY_GRADE_EASY]
	var/expected_payment = round(wage * settings.quirk_debt_wage_share / 100)
	TEST_ASSERT_EQUAL(debt_before - account.nt_debt, expected_payment, "Зарплата не погасила свою долю долга")
	TEST_ASSERT_EQUAL(account.account_balance, wage - expected_payment, "На руки не остаток зарплаты после долга")
	account.nt_debt = 10
	var/balance_before = account.account_balance
	account.payday()
	TEST_ASSERT_EQUAL(account.nt_debt, 0, "Остаток долга не погашен")
	TEST_ASSERT_EQUAL(account.account_balance - balance_before, wage - 10, "Погашение списало больше остатка долга")
	econ_test_set_balance(service.account, saved_service)
	qdel(account)
