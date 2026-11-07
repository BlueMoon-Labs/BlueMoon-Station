/**
 * История операций счёта росла НАВСЕГДА.
 *
 * add_log_to_history() снимал одну запись при длине >= 20 и добавлял две, ещё четыре места
 * добавления не обрезали историю вовсе.
 */

/// Сколько вызовов прогнать: заведомо больше капа, чтобы прежняя арифметика "+1 за вызов"
/// успела уехать далеко за него.
#define BANK_HISTORY_TEST_CALLS 60

/// Кап держится независимо от числа вызовов, в истории ровно последние BANK_TRANSACTION_HISTORY_MAX операций.
/datum/unit_test/bank_transaction_history_is_capped/Run()
	// add_to_accounts - вар, а не аргумент New(): счёт встаёт в SSeconomy.bank_accounts
	// и снимается оттуда своим Destroy(), поэтому пара new/qdel сходится сама.
	var/datum/bank_account/account = new("unit_test_history")

	for(var/i in 1 to BANK_HISTORY_TEST_CALLS)
		account.add_log_to_history(10, "тест [i]")

	var/length_after = length(account.transaction_history)
	var/list/history = account.transaction_history.Copy()
	qdel(account)

	TEST_ASSERT_EQUAL(length_after, 20, "История держит ровно 20 последних операций после [BANK_HISTORY_TEST_CALLS] вызовов")
	for(var/entry in history)
		TEST_ASSERT(istype(entry, /datum/transaction), "В истории только операции /datum/transaction")
	var/datum/transaction/newest = history[length(history)]
	TEST_ASSERT_EQUAL(newest.purpose, "тест [BANK_HISTORY_TEST_CALLS]", "Последней лежит последняя операция")

/// На вытесненную операцию после обрезки ссылается только сам тест: висеть ей негде.
/datum/unit_test/bank_transaction_history_frees_evicted/Run()
	// add_to_accounts - вар, а не аргумент New(): счёт встаёт в SSeconomy.bank_accounts
	// и снимается оттуда своим Destroy(), поэтому пара new/qdel сходится сама.
	var/datum/bank_account/account = new("unit_test_history")

	for(var/i in 1 to 21)
		account.add_log_to_history(1, "тест [i]")
	var/datum/transaction/oldest = account.transaction_history[1]
	TEST_ASSERT(istype(oldest), "Первой в истории лежит операция")

	for(var/i in 1 to 40)
		account.add_log_to_history(1, "вытесняющий [i]")

	var/references = refcount(oldest)
	var/still_listed = (oldest in account.transaction_history)
	qdel(account)

	TEST_ASSERT(!still_listed, "Вытесненная операция ушла из истории")
	TEST_ASSERT(references == 1, "На вытесненную операцию держит ссылку не только тест: [references]")

#undef BANK_HISTORY_TEST_CALLS
