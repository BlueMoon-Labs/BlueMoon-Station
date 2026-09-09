/**
 * История операций счёта росла НАВСЕГДА.
 *
 * add_log_to_history() снимал РОВНО ОДНУ запись при длине >= 20 и тут же добавлял ДВЕ:
 * ассоциативную строку для приложения НТ и датум /datum/transaction для распечатки. Итог
 * +1 за вызов, а вызовов на сотню счетов - двенадцать пейдеев в час плюс каждая покупка
 * в автомате. Ещё четыре места добавления не обрезали историю вовсе.
 */

/// Сколько вызовов прогнать: заведомо больше капа, чтобы прежняя арифметика "+1 за вызов"
/// успела уехать далеко за него.
#define BANK_HISTORY_TEST_CALLS 60

/// Кап держится независимо от числа вызовов, и обе записи (строка UI и датум распечатки)
/// в истории остаются.
/datum/unit_test/bank_transaction_history_is_capped/Run()
	// add_to_accounts - вар, а не аргумент New(): счёт встаёт в SSeconomy.bank_accounts
	// и снимается оттуда своим Destroy(), поэтому пара new/qdel сходится сама.
	var/datum/bank_account/account = new("unit_test_history")

	for(var/i in 1 to BANK_HISTORY_TEST_CALLS)
		account.add_log_to_history(10, "тест [i]")

	var/length_after = length(account.transaction_history)
	var/list/history = account.transaction_history.Copy()
	qdel(account)

	TEST_ASSERT(length_after <= 20, "История обязана держаться в пределах капа, а не расти на +1 за вызов: [length_after] записей после [BANK_HISTORY_TEST_CALLS] вызовов")
	var/datums = 0
	var/rows = 0
	for(var/entry in history)
		if(istype(entry, /datum/transaction))
			datums++
		else if(islist(entry))
			rows++
	TEST_ASSERT(datums > 0, "Датумы распечатки не должны вытесняться целиком: [datums] из [length_after]")
	TEST_ASSERT(rows > 0, "Строки приложения НТ не должны вытесняться целиком: [rows] из [length_after]")

/// Вытесненный датум обязан УДАЛЯТЬСЯ, а не просто выпадать из списка: иначе обрезка
/// экономит слот списка и оставляет сам объект висеть.
/datum/unit_test/bank_transaction_history_qdels_evicted/Run()
	// add_to_accounts - вар, а не аргумент New(): счёт встаёт в SSeconomy.bank_accounts
	// и снимается оттуда своим Destroy(), поэтому пара new/qdel сходится сама.
	var/datum/bank_account/account = new("unit_test_history")

	for(var/i in 1 to 21)
		account.add_log_to_history(1, "тест [i]")
	// Первым в списке лежит датум самой ранней операции, дожившей до этого момента.
	var/datum/oldest = null
	for(var/entry in account.transaction_history)
		if(istype(entry, /datum/transaction))
			oldest = entry
			break
	TEST_ASSERT_NOTNULL(oldest, "В истории обязан быть хоть один датум операции")

	for(var/i in 1 to 40)
		account.add_log_to_history(1, "вытесняющий [i]")

	var/evicted = QDELETED(oldest)
	qdel(account)

	TEST_ASSERT(evicted, "Вытесненный датум операции обязан уходить в qdel, а не просто выпадать из списка")

#undef BANK_HISTORY_TEST_CALLS
