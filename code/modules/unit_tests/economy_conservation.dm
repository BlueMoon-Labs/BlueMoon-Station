/// Деньги на всех счетах равны эмиссии минус стоки за раунд, и ни один баланс не дробный.
/datum/unit_test/economy_money_conserved
	priority = TEST_LONGER

/datum/unit_test/economy_money_conserved/Run()
	var/list/fractional = list()
	for(var/number in SSeconomy.accounts_by_number)
		var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
		if(account.account_balance != round(account.account_balance))
			fractional += "[account.account_holder]: [account.account_balance]"
	TEST_ASSERT(!length(fractional), "Дробные балансы: [jointext(fractional, ", ")]")
	TEST_ASSERT_EQUAL(SSeconomy.total_money(), SSeconomy.ledger.minted - SSeconomy.ledger.burned, "Расхождение журнала и балансов")

/// Дробные суммы журнал округляет: после серии движений и закрытия счетов деньги сходятся.
/datum/unit_test/economy_fractional_moves/Run()
	var/drift_before = SSeconomy.total_money() - (SSeconomy.ledger.minted - SSeconomy.ledger.burned)
	var/datum/bank_account/alpha = new("econ_test_alpha")
	var/datum/bank_account/beta = new("econ_test_beta")
	alpha.credit(100.7, ECON_ADMIN)
	SSeconomy.move(alpha, beta, 33.3, ECON_TRANSFER)
	beta.debit(0.5, ECON_PURCHASE)
	var/alpha_balance = alpha.account_balance
	var/beta_balance = beta.account_balance
	qdel(alpha)
	qdel(beta)
	TEST_ASSERT_EQUAL(alpha_balance, 67, "Остаток отправителя целый")
	TEST_ASSERT_EQUAL(beta_balance, 33, "Остаток получателя целый")
	TEST_ASSERT_EQUAL(SSeconomy.total_money() - (SSeconomy.ledger.minted - SSeconomy.ledger.burned), drift_before, "Закрытие счетов сходится с журналом")

/// В игровом коде нет записи баланса мимо журнала.
/datum/unit_test/economy_no_direct_balance_writes/Run()
	var/list/offenders = list()
	for(var/path in list("code", "modular_bluemoon", "modular_splurt", "modular_sand", "modular_citadel"))
		econ_scan_balance_writes(path, offenders)
	TEST_ASSERT(!length(offenders), "Запись account_balance мимо журнала: [jointext(offenders, ", ")]")

/proc/econ_scan_balance_writes(path, list/offenders)
	var/regex/write = regex(@"[^/]account_balance\s*[-+]?=[^=]|adjust_money\(|transfer_money\(")
	for(var/entry in flist("[path]/"))
		var/full = "[path]/[entry]"
		if(copytext(entry, -1) == "/")
			if(full == "code/modules/unit_tests/")
				continue
			econ_scan_balance_writes(copytext(full, 1, -1), offenders)
			continue
		if(copytext(entry, -3) != ".dm" || findtext(full, "economy/core/ledger.dm"))
			continue
		if(write.Find(file2text(full)))
			offenders += full

/// Выставить баланс счёта через журнал, как корректировка NT.
/proc/econ_test_set_balance(datum/bank_account/account, balance)
	var/delta = balance - account.account_balance
	if(delta > 0)
		account.credit(delta, ECON_ADMIN)
	else if(delta < 0)
		var/had_debt = account.allow_debt
		account.allow_debt = TRUE
		account.debit(-delta, ECON_ADMIN)
		account.allow_debt = had_debt
