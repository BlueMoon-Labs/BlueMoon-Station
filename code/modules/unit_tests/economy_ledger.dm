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
	QDEL_LIST(allocated)
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

/// Бюджеты аванпостов идут в итоге смены своей строкой, а их эмиссия отделена от станционной.
/datum/unit_test/economy_round_summary_outposts
	var/datum/economy_ledger/saved_ledger
	var/datum/bank_account/department/outpost
	var/old_balance

/datum/unit_test/economy_round_summary_outposts/Destroy()
	if(outpost)
		econ_test_set_balance(outpost, old_balance)
	QDEL_LIST(allocated)
	if(saved_ledger)
		var/datum/economy_ledger/test_ledger = SSeconomy.ledger
		SSeconomy.ledger = saved_ledger
		qdel(test_ledger)
	return ..()

/datum/unit_test/economy_round_summary_outposts/Run()
	saved_ledger = SSeconomy.ledger
	SSeconomy.ledger = new /datum/economy_ledger
	outpost = SSeconomy.get_dep_account(ACCOUNT_DS)
	TEST_ASSERT_NOTNULL(outpost, "Бюджет Deep Space есть")
	old_balance = outpost.account_balance
	var/datum/bank_account/department/other_outpost = SSeconomy.get_dep_account(ACCOUNT_TAR)
	var/datum/bank_account/worker = allocate(/datum/bank_account, "econ_test_worker")

	worker.credit(700, ECON_WAGE)
	outpost.credit(5000, ECON_EXPORT)
	outpost.debit(1000, ECON_IMPORT)
	SSeconomy.move(outpost, worker, 500, ECON_TRANSFER)

	var/text = jointext(SSeconomy.ledger.round_summary(), "\n")
	TEST_ASSERT(findtext(text, "эмиссия станции 700 кр., аванпостов 5000 кр. (export 5000)"), "Эмиссия разделена: [text]")
	TEST_ASSERT(findtext(text, "Итог смены по аванпостам (пришло/потрачено/сожжено/остаток): "), "Строка аванпостов: [text]")
	TEST_ASSERT(findtext(text, "DS 5000/500/1000/[outpost.account_balance]"), "Deep Space в строке аванпостов: [text]")
	TEST_ASSERT(findtext(text, "TAR 0/0/0/[other_outpost.account_balance]"), "Тарков в строке аванпостов без движений: [text]")

/// После конца раунда тик экономики и оплата работы не начисляют, а итог смены пишется один раз.
/datum/unit_test/economy_round_over_no_accrual
	var/datum/economy_ledger/saved_ledger
	var/previous_ticker_state
	var/datum/bank_account/department/budget
	var/old_balance

/datum/unit_test/economy_round_over_no_accrual/Destroy()
	if(!isnull(previous_ticker_state))
		SSticker.current_state = previous_ticker_state
	if(budget)
		econ_test_set_balance(budget, old_balance)
	QDEL_LIST(allocated)
	if(saved_ledger)
		var/datum/economy_ledger/test_ledger = SSeconomy.ledger
		SSeconomy.ledger = saved_ledger
		qdel(test_ledger)
	return ..()

/datum/unit_test/economy_round_over_no_accrual/Run()
	saved_ledger = SSeconomy.ledger
	SSeconomy.ledger = new /datum/economy_ledger
	budget = SSeconomy.get_dep_account(ACCOUNT_ENG)
	old_balance = budget.account_balance
	previous_ticker_state = SSticker.current_state
	SSticker.current_state = GAME_STATE_FINISHED
	var/fires = SSeconomy.fire_count
	SSeconomy.fire()
	var/fires_after = SSeconomy.fire_count
	var/paid_after_end = SSeconomy.record_work(ACCOUNT_ENG, WORK_ENG_POWER_EXPORT, 100)
	var/minted_after_end = SSeconomy.ledger.minted
	var/snapshots_after_end = length(SSeconomy.ledger.snapshots)
	var/first_summary = econ_log_round_summary()
	var/second_summary = econ_log_round_summary()
	SSticker.current_state = previous_ticker_state
	previous_ticker_state = null
	var/paid_in_round = SSeconomy.record_work(ACCOUNT_ENG, WORK_ENG_POWER_EXPORT, 100)

	TEST_ASSERT_EQUAL(fires_after, fires, "Тик экономики после конца раунда пропущен")
	TEST_ASSERT_EQUAL(paid_after_end, 0, "Работа после конца раунда не оплачена")
	TEST_ASSERT_EQUAL(minted_after_end, 0, "Эмиссии после конца раунда нет")
	TEST_ASSERT_EQUAL(snapshots_after_end, 0, "Снимок журнала после конца раунда не снят")
	TEST_ASSERT(first_summary, "Итог смены записан")
	TEST_ASSERT(!second_summary, "Итог смены записан один раз")
	TEST_ASSERT(paid_in_round > 0, "Во время раунда работа оплачивается: [paid_in_round]")
