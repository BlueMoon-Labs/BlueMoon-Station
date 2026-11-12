/// Эмиссия, перевод и сток меняют балансы и журнал ровно на свои суммы.
/datum/unit_test/economy_ledger_moves/Run()
	var/minted_before = SSeconomy.ledger.minted
	var/burned_before = SSeconomy.ledger.burned
	var/datum/bank_account/alpha = new("econ_test_alpha")
	var/datum/bank_account/beta = new("econ_test_beta")
	TEST_ASSERT(alpha.credit(500, ECON_ADMIN), "Эмиссия на счёт")
	TEST_ASSERT(SSeconomy.move(alpha, beta, 200, ECON_TRANSFER), "Перевод")
	TEST_ASSERT(beta.debit(50, ECON_PURCHASE), "Сток")
	var/alpha_balance = alpha.account_balance
	var/beta_balance = beta.account_balance
	var/minted = SSeconomy.ledger.minted - minted_before
	var/burned = SSeconomy.ledger.burned - burned_before
	qdel(alpha)
	qdel(beta)
	var/burned_after_close = SSeconomy.ledger.burned - burned_before
	TEST_ASSERT_EQUAL(alpha_balance, 300, "Остаток отправителя")
	TEST_ASSERT_EQUAL(beta_balance, 150, "Остаток получателя")
	TEST_ASSERT(minted >= 500, "Эмиссия учтена: [minted]")
	TEST_ASSERT(burned >= 50, "Сток учтён: [burned]")
	TEST_ASSERT(burned_after_close >= 50 + 300 + 150, "Закрытие счетов с остатком учтено: [burned_after_close]")

/datum/unit_test/economy_ledger_refusals
	allowed_runtime_patterns = list("SSeconomy.move: неизвестная причина")

/// Нехватка денег, заморозка, неизвестная причина и неположительная сумма отвергаются без следа.
/datum/unit_test/economy_ledger_refusals/Run()
	var/datum/bank_account/alpha = new("econ_test_alpha")
	var/datum/bank_account/beta = new("econ_test_beta")
	alpha.credit(100, ECON_ADMIN)
	var/refused_poor = SSeconomy.move(alpha, beta, 101, ECON_TRANSFER)
	var/refused_zero = SSeconomy.move(alpha, beta, 0, ECON_TRANSFER)
	var/refused_reason = SSeconomy.move(alpha, beta, 10, "no_such_reason")
	alpha.state = ACCOUNT_FROZEN
	var/refused_frozen = SSeconomy.move(alpha, beta, 10, ECON_TRANSFER)
	var/refund_from_frozen = SSeconomy.move(alpha, beta, 10, ECON_REFUND)
	var/alpha_balance = alpha.account_balance
	var/beta_balance = beta.account_balance
	qdel(alpha)
	qdel(beta)
	TEST_ASSERT(!refused_poor, "Нехватка")
	TEST_ASSERT(!refused_zero, "Ноль")
	TEST_ASSERT(!refused_reason, "Неизвестная причина")
	TEST_ASSERT(!refused_frozen, "Заморожен")
	TEST_ASSERT(refund_from_frozen, "Возврат с замороженного разрешён")
	TEST_ASSERT_EQUAL(alpha_balance, 90, "Только возврат списан")
	TEST_ASSERT_EQUAL(beta_balance, 10, "Только возврат зачислен")

/// Номер счёта уникален, по нему находится счёт, после qdel - не находится.
/datum/unit_test/economy_account_registry/Run()
	var/datum/bank_account/alpha = new("econ_test_alpha")
	var/number = alpha.account_id
	TEST_ASSERT(SSeconomy.find_account(number) == alpha, "Поиск по номеру")
	var/datum/bank_account/beta = new("econ_test_beta")
	TEST_ASSERT(beta.account_id != number, "Номера разные")
	qdel(alpha)
	qdel(beta)
	TEST_ASSERT_NULL(SSeconomy.find_account(number), "После qdel номер свободен")

/// Снятие и внесение наличных идут через системный счёт и не создают денег.
/datum/unit_test/economy_cash_account/Run()
	var/datum/bank_account/alpha = new("econ_test_alpha")
	alpha.credit(100, ECON_ADMIN)
	var/cash_before = SSeconomy.cash_account.account_balance
	TEST_ASSERT(SSeconomy.move(alpha, SSeconomy.cash_account, 40, ECON_CASH_OUT), "Снятие")
	TEST_ASSERT(SSeconomy.move(SSeconomy.cash_account, alpha, 60, ECON_CASH_IN), "Внесение больше снятого допустимо")
	var/cash_delta = SSeconomy.cash_account.account_balance - cash_before
	var/alpha_balance = alpha.account_balance
	qdel(alpha)
	TEST_ASSERT_EQUAL(cash_delta, -20, "Системный счёт уходит в минус на разницу")
	TEST_ASSERT_EQUAL(alpha_balance, 120, "Баланс владельца")

/datum/unit_test/economy_vv_balance_edit
	var/list/moves = list()

/// Правка баланса через VV пишется в журнал и рассылает COMSIG_ECONOMY_MOVED, как обычное движение.
/datum/unit_test/economy_vv_balance_edit/Run()
	var/datum/bank_account/alpha = new("econ_test_alpha")
	var/minted_before = SSeconomy.ledger.minted
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_moved))
	alpha.vv_edit_var(NAMEOF(alpha, account_balance), 250)
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	var/minted = SSeconomy.ledger.minted - minted_before
	var/list/move = length(moves) ? moves[1] : null
	var/edited_target = move && move[2] == alpha
	qdel(alpha)
	TEST_ASSERT_EQUAL(minted, 250, "Эмиссия правкой VV в журнале")
	TEST_ASSERT_EQUAL(length(moves), 1, "Один сигнал на правку")
	TEST_ASSERT(edited_target, "Сигнал указывает на изменённый счёт")
	TEST_ASSERT_EQUAL(move[3], 250, "Сумма в сигнале")
	TEST_ASSERT_EQUAL(move[4], ECON_ADMIN, "Причина в сигнале")

/datum/unit_test/economy_vv_balance_edit/proc/on_moved(datum/source, datum/bank_account/sender, datum/bank_account/receiver, amount, reason)
	SIGNAL_HANDLER
	moves += list(list(sender, receiver, amount, reason))

/// Итог смены в econ.log называет эмиссию и сток по причинам и долю стока отделов с возвратом излишка и без него.
/datum/unit_test/economy_round_summary
	var/datum/economy_ledger/saved_ledger
	var/datum/bank_account/budget
	var/old_balance

/datum/unit_test/economy_round_summary/Destroy()
	if(budget)
		econ_test_set_balance(budget, old_balance)
	if(saved_ledger)
		var/datum/economy_ledger/test_ledger = SSeconomy.ledger
		SSeconomy.ledger = saved_ledger
		qdel(test_ledger)
	return ..()

/datum/unit_test/economy_round_summary/Run()
	saved_ledger = SSeconomy.ledger
	SSeconomy.ledger = new /datum/economy_ledger
	budget = SSeconomy.get_dep_account(ACCOUNT_ENG)
	old_balance = budget.account_balance
	var/datum/bank_account/worker = allocate(/datum/bank_account, "econ_test_worker")

	budget.credit(3000, ECON_CONTRACT)
	budget.credit(1000, ECON_GRANT)
	SSeconomy.move(budget, worker, 1000, ECON_WAGE)
	budget.debit(1500, ECON_IMPORT)
	budget.debit(600, ECON_BUDGET_RETURN)
	worker.debit(200, ECON_PURCHASE)

	var/list/lines = SSeconomy.ledger.round_summary()
	var/text = jointext(lines, "\n")
	TEST_ASSERT(findtext(text, "эмиссия 4000 кр. (contract 3000, grant 1000)"), "Эмиссия по причинам: [text]")
	TEST_ASSERT(findtext(text, "сток 2300 кр. (import 1500, budget_return 600, purchase 200)"), "Сток по причинам: [text]")
	TEST_ASSERT(findtext(text, "сток отделов 70%, без возврата излишка 62%"), "Доля стока отделов: [text]")
