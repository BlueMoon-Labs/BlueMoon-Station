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

/datum/unit_test/economy_ledger_absurd_amount
	allowed_runtime_patterns = list("SSeconomy.move: недопустимая сумма")

/// Бесконечная, NaN, текстовая и запредельная сумма отвергаются, не трогая балансов и журнала; крупная законная проходит.
/datum/unit_test/economy_ledger_absurd_amount/Run()
	var/datum/bank_account/alpha = allocate(/datum/bank_account, "econ_test_alpha")
	var/datum/bank_account/beta = allocate(/datum/bank_account, "econ_test_beta")
	alpha.credit(100, ECON_ADMIN)
	var/cash_before = SSeconomy.cash_account.account_balance
	var/minted_before = SSeconomy.ledger.minted
	var/huge = 1e30
	var/infinite = huge * huge
	var/not_a_number = infinite - infinite
	TEST_ASSERT(isnum(not_a_number) && !(not_a_number == not_a_number), "Тест получил NaN: [not_a_number]")
	TEST_ASSERT(!SSeconomy.move(SSeconomy.cash_account, alpha, INFINITY, ECON_CASH_IN), "INFINITY отвергнута")
	TEST_ASSERT(!SSeconomy.move(SSeconomy.cash_account, alpha, infinite, ECON_CASH_IN), "Бесконечность отвергнута")
	TEST_ASSERT(!SSeconomy.move(SSeconomy.cash_account, alpha, not_a_number, ECON_CASH_IN), "NaN отвергнут")
	TEST_ASSERT(!SSeconomy.move(SSeconomy.cash_account, alpha, ECON_MOVE_AMOUNT_MAX, ECON_CASH_IN), "Сумма на пороге отвергнута")
	TEST_ASSERT(!alpha.credit(1e34, ECON_ADMIN), "Эмиссия 1e34 отвергнута")
	TEST_ASSERT(!SSeconomy.move(alpha, beta, "50", ECON_TRANSFER), "Текст вместо суммы отвергнут")
	TEST_ASSERT_EQUAL(alpha.account_balance, 100, "Баланс не тронут")
	TEST_ASSERT_EQUAL(SSeconomy.cash_account.account_balance, cash_before, "Наличные не ушли в минус")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted_before, "Журнал эмиссии не тронут")
	TEST_ASSERT(SSeconomy.move(SSeconomy.cash_account, alpha, 1000000, ECON_CASH_IN), "Миллион проходит")
	// Миллион пришёл эмиссией найденных наличных: сжечь его, а не вернуть в оборот, иначе следующие тесты видят богатую станцию
	SSeconomy.move(alpha, null, 1000000, ECON_ADMIN)

/// Конечная сумма от потолка - ввод игрока, а не баг: отказ без рантайма, строкой в econ.log с суммой, счетами, причиной и кто; суммы от миллиона пишутся цифрами.
/datum/unit_test/economy_ledger_amount_cap_quiet/Run()
	var/datum/bank_account/alpha = allocate(/datum/bank_account, "econ_test_cap_alpha")
	var/datum/bank_account/beta = allocate(/datum/bank_account, "econ_test_cap_beta")
	var/mob/living/carbon/human/actor = allocate(/mob/living/carbon/human)
	alpha.credit(100, ECON_ADMIN)
	var/log_start = econ_test_log_length()
	TEST_ASSERT(!SSeconomy.move(alpha, beta, ECON_MOVE_AMOUNT_MAX, ECON_TRANSFER, actor), "Сумма на потолке отвергнута")
	TEST_ASSERT(!alpha.credit(1e9, ECON_ADMIN), "Миллиард отвергнут")
	TEST_ASSERT(alpha.credit(1500000, ECON_ADMIN), "Полтора миллиона проходят")
	var/text = jointext(econ_test_log_since(log_start), "\n")
	TEST_ASSERT(findtext(text, "Отклонено: 10000000 кр.: econ_test_cap_alpha -> econ_test_cap_beta (transfer)"), "Отказ назван в econ.log: [text]")
	TEST_ASSERT(findtext(text, key_name(actor)), "Отказ называет, кто двигал: [text]")
	TEST_ASSERT(findtext(text, "Отклонено: 1000000000 кр.: эмиссия -> econ_test_cap_alpha (admin)"), "Отказ эмиссии в econ.log: [text]")
	TEST_ASSERT(findtext(text, "1500000 кр.: эмиссия -> econ_test_cap_alpha (admin)"), "Сумма от миллиона цифрами, а не 1.5e+006: [text]")
	TEST_ASSERT_EQUAL(alpha.account_balance, 1500100, "Отказы баланс не тронули")
	TEST_ASSERT_EQUAL(beta.account_balance, 0, "Получателю ничего не пришло")

/// Исполнитель желаний кладёт в тележку 500 тыс. наличными, а не пачки на бесконечность.
/datum/unit_test/economy_wishgranter_cart/Run()
	var/obj/structure/closet/crate/trashcart/moneywish/cart = allocate(/obj/structure/closet/crate/trashcart/moneywish)
	var/total = 0
	for(var/obj/item/stack/spacecash/bills in cart.contents)
		total += bills.get_item_credit_value()
	TEST_ASSERT_EQUAL(total, 500000, "Сумма в тележке")

/datum/unit_test/economy_absurd_cash_deposit
	allowed_runtime_patterns = list("SSeconomy.move: недопустимая сумма")

/// Карта, мешок с деньгами и хранилище снабжения не принимают пачку на бесконечность и не съедают её; отказ называет деньги их именем.
/datum/unit_test/economy_absurd_cash_deposit/Run()
	var/mob/living/carbon/human/person = econ_test_card_holder(src, "econ_test_depositor", 100)
	var/obj/item/card/id/card = person.get_idcard(TRUE)
	var/datum/bank_account/account = card.registered_account
	var/obj/item/stack/spacecash/c1000/bills = allocate(/obj/item/stack/spacecash/c1000)
	bills.amount = bills.max_amount
	GLOB.unit_test_chat_capture = list()
	card.attackby(bills, person)
	var/list/chat = GLOB.unit_test_chat_capture
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(!QDELETED(bills), "Карта не съела пачку")
	TEST_ASSERT_EQUAL(account.account_balance, 100, "На карту ничего не зачислено")
	var/refusal = econ_test_chat_to(chat, person)
	TEST_ASSERT(findtext(refusal, "Банк не принял [bills.name]") && !findtext(refusal, "the "), "Отказ называет пачку по имени: [refusal]")
	var/obj/item/storage/bag/money/bag = allocate(/obj/item/storage/bag/money)
	bills.forceMove(bag)
	card.attackby(bag, person)
	TEST_ASSERT(!QDELETED(bills), "Мешок не съел пачку")
	TEST_ASSERT_EQUAL(account.account_balance, 100, "Из мешка ничего не зачислено")
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/cargo_before = cargo.account_balance
	var/obj/machinery/computer/bank_machine/vault = allocate(/obj/machinery/computer/bank_machine)
	GLOB.unit_test_chat_capture = list()
	vault.attackby(bills, person)
	chat = GLOB.unit_test_chat_capture
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(!QDELETED(bills), "Хранилище не съело пачку")
	TEST_ASSERT_EQUAL(cargo.account_balance, cargo_before, "Бюджет снабжения не тронут")
	refusal = econ_test_chat_to(chat, person)
	TEST_ASSERT(findtext(refusal, "Банк не принял [bills.name]") && !findtext(refusal, "the "), "Отказ хранилища называет пачку по имени: [refusal]")

/// Все сообщения в чат target из перехваченного GLOB.unit_test_chat_capture одной строкой.
/proc/econ_test_chat_to(list/chat, target)
	var/list/lines = list()
	for(var/list/line as anything in chat)
		if(line[1] == target)
			lines += "[line[2]]"
	return jointext(lines, " | ")

/proc/econ_test_chat_count(list/chat, target)
	. = 0
	for(var/list/line as anything in chat)
		if(line[1] == target)
			.++

/// Хранилище снабжения пишет в истории бюджета, кто внёс наличные, - по ID-карте, а не настоящим именем.
/datum/unit_test/economy_vault_deposit_memo/Run()
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = "Econ Vault Depositor"
	person.equip_to_slot(card, ITEM_SLOT_ID)
	var/obj/item/holochip/chip = allocate(/obj/item/holochip, null, 250)
	person.put_in_active_hand(chip)
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/cargo_before = cargo.account_balance
	var/obj/machinery/computer/bank_machine/vault = allocate(/obj/machinery/computer/bank_machine)
	vault.attackby(chip, person)
	var/delta = cargo.account_balance - cargo_before
	var/datum/transaction/entry = cargo.transaction_history[length(cargo.transaction_history)]
	if(delta)
		cargo.debit(delta, ECON_ADMIN)
	TEST_ASSERT_EQUAL(delta, 250, "Голочип зачислен в бюджет снабжения")
	TEST_ASSERT(findtext(entry.purpose, "Econ Vault Depositor"), "История бюджета называет вкладчика по карте: [entry.purpose]")
	TEST_ASSERT(!findtext(entry.purpose, person.real_name), "История бюджета не раскрывает настоящее имя: [entry.purpose]")

/// Клик ID-картой по куче денег на полу вносит всё, что лежит на тайле, одной операцией: одна строка econ.log с числом предметов и одно сообщение.
/datum/unit_test/economy_cash_pile_deposit/Run()
	var/mob/living/carbon/human/person = econ_test_card_holder(src, "econ_test_pile", 0)
	var/obj/item/card/id/card = person.get_idcard(TRUE)
	var/datum/bank_account/account = card.registered_account
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/item/holochip/chip = allocate(/obj/item/holochip, floor, 300)
	var/obj/item/holochip/second_chip = allocate(/obj/item/holochip, floor, 200)
	var/obj/item/stack/spacecash/c100/bills = allocate(/obj/item/stack/spacecash/c100, floor, 2)
	var/log_start = econ_test_log_length()
	GLOB.unit_test_chat_capture = list()
	chip.attackby(card, person)
	var/list/chat = GLOB.unit_test_chat_capture
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT_EQUAL(account.account_balance, 700, "Внесена вся куча")
	TEST_ASSERT(QDELETED(chip) && QDELETED(second_chip) && QDELETED(bills), "Куча исчезла")
	var/list/deposits = list()
	for(var/line in econ_test_log_since(log_start))
		if(findtext(line, "-> econ_test_pile (cash_in"))
			deposits += line
	TEST_ASSERT_EQUAL(length(deposits), 1, "Одна строка econ.log на кучу: [jointext(deposits, " | ")]")
	TEST_ASSERT(length(deposits) && findtext(deposits[1], "700 кр.") && findtext(deposits[1], "3 предм."), "Строка называет сумму и число предметов: [jointext(deposits, " | ")]")
	TEST_ASSERT_EQUAL(econ_test_chat_count(chat, person), 1, "Одно сообщение на кучу: [econ_test_chat_to(chat, person)]")
	TEST_ASSERT(findtext(econ_test_chat_to(chat, person), "700"), "Сообщение называет сумму: [econ_test_chat_to(chat, person)]")
	var/obj/item/stack/spacecash/c20/more_bills = allocate(/obj/item/stack/spacecash/c20, floor, 5)
	var/obj/item/holochip/more_chip = allocate(/obj/item/holochip, floor, 50)
	more_bills.attackby(card, person)
	TEST_ASSERT_EQUAL(account.account_balance, 850, "Клик по пачке тоже вносит всю кучу")
	TEST_ASSERT(QDELETED(more_bills) && QDELETED(more_chip), "Вторая куча исчезла")

/// Внесение кучи не засыпает между подсчётом и удалением: второй клик на занятом тике не вносит ту же кучу ещё раз, а удалённые деньги не считаются.
/datum/unit_test/economy_cash_pile_no_double/Run()
	var/mob/living/carbon/human/person = econ_test_card_holder(src, "econ_test_pile_twice", 0)
	var/obj/item/card/id/card = person.get_idcard(TRUE)
	var/datum/bank_account/account = card.registered_account
	var/turf/floor = run_loc_floor_bottom_left
	var/list/pile = list()
	pile += allocate(/obj/item/holochip, floor, 300)
	pile += allocate(/obj/item/holochip, floor, 200)
	pile += allocate(/obj/item/stack/spacecash/c100, floor, 2)
	var/saved_ticklimit = Master.current_ticklimit
	Master.current_ticklimit = -1
	INVOKE_ASYNC(card, TYPE_PROC_REF(/obj/item/card/id, mass_insert_money), pile.Copy(), person)
	Master.current_ticklimit = saved_ticklimit
	card.mass_insert_money(pile.Copy(), person)
	sleep(5)
	TEST_ASSERT_EQUAL(account.account_balance, 700, "Куча зачислена один раз")
	for(var/obj/item/money as anything in pile)
		TEST_ASSERT(QDELETED(money), "[money] не исчез")
	TEST_ASSERT(!card.mass_insert_money(pile.Copy(), person), "Удалённые деньги внесены ещё раз")
	TEST_ASSERT_EQUAL(account.account_balance, 700, "Удалённые деньги зачислены")

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

/// Закрытый счёт отпускает все привязанные к нему карты: ID-карта и анонимная карта не держат удалённый счёт.
/datum/unit_test/economy_account_close_unlinks_cards/Run()
	var/obj/item/anon_account_card/anon = allocate(/obj/item/anon_account_card)
	var/datum/bank_account/account = anon.account
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = account
	account.bank_cards += card
	qdel(account)
	TEST_ASSERT_NULL(card.registered_account, "ID-карта держит закрытый счёт")
	TEST_ASSERT_NULL(anon.account, "Анонимная карта держит закрытый счёт")
	TEST_ASSERT(!length(account.bank_cards), "Закрытый счёт держит карты")

/datum/unit_test/economy_cash_account
	var/saved_cash

/datum/unit_test/economy_cash_account/Destroy()
	if(!isnull(saved_cash))
		econ_test_set_balance(SSeconomy.cash_account, saved_cash)
	return ..()

/// Снятие и внесение наличных идут через системный счёт; наличные сверх снятых (лут, кошельки) эмитируются как найденные, и оборот не уходит в минус.
/datum/unit_test/economy_cash_account/Run()
	var/datum/bank_account/cash = SSeconomy.cash_account
	saved_cash = cash.account_balance
	econ_test_set_balance(cash, 0)
	var/datum/bank_account/alpha = allocate(/datum/bank_account, "econ_test_alpha")
	alpha.credit(100, ECON_ADMIN)
	var/found_before = SSeconomy.ledger.minted_by_reason[ECON_FOUND_CASH] || 0
	var/minted_before = SSeconomy.ledger.minted
	var/money_before = SSeconomy.total_money()
	var/list/totals_before = SSeconomy.state_totals()
	TEST_ASSERT(SSeconomy.move(alpha, cash, 40, ECON_CASH_OUT), "Снятие")
	TEST_ASSERT(SSeconomy.move(cash, alpha, 60, ECON_CASH_IN), "Внесение больше снятого допустимо")
	TEST_ASSERT_EQUAL(cash.account_balance, 0, "Наличные в обороте не уходят в минус")
	TEST_ASSERT_EQUAL(alpha.account_balance, 120, "Баланс владельца")
	TEST_ASSERT_EQUAL((SSeconomy.ledger.minted_by_reason[ECON_FOUND_CASH] || 0) - found_before, 20, "Недостача эмитирована как найденные наличные")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted - minted_before, 20, "Эмиссия смены видит найденные наличные")
	TEST_ASSERT_EQUAL(SSeconomy.total_money() - money_before, 20, "Деньги станции выросли на найденное, а не остались прежними")
	var/list/totals = SSeconomy.state_totals()
	TEST_ASSERT_EQUAL(totals["money"] - totals_before["money"], 20, "Подсчёт бедности видит найденное")
	TEST_ASSERT(SSeconomy.move(cash, null, 30, ECON_BLACKMARKET), "Наличные сверх оборота уходят в сток")
	TEST_ASSERT_EQUAL(cash.account_balance, 0, "Сток наличными тоже не уводит оборот в минус")
	TEST_ASSERT_EQUAL((SSeconomy.ledger.minted_by_reason[ECON_FOUND_CASH] || 0) - found_before, 50, "Сток найденных наличных эмитирован перед сжиганием")

/datum/unit_test/economy_found_cash_origin
	var/saved_cash

/datum/unit_test/economy_found_cash_origin/Destroy()
	if(!isnull(saved_cash))
		econ_test_set_balance(SSeconomy.cash_account, saved_cash)
	return ..()

/// Внесение наличных сверх снятых пишет одну строку econ.log, из каких пачек и голочипов найденное: тип, номинал, где, когда и кем создана пачка. Деление и слияние пачек это сохраняют.
/datum/unit_test/economy_found_cash_origin/Run()
	var/datum/bank_account/cash = SSeconomy.cash_account
	saved_cash = cash.account_balance
	econ_test_set_balance(cash, 0)
	var/mob/living/carbon/human/person = econ_test_card_holder(src, "econ_test_found_cash", 5000)
	var/obj/item/card/id/card = person.get_idcard(TRUE)
	var/datum/bank_account/account = card.registered_account
	var/obj/item/stack/spacecash/c1000/bills = allocate(/obj/item/stack/spacecash/c1000, run_loc_floor_bottom_left, 3)
	var/floor_origin = bills.origin
	TEST_ASSERT(findtext(floor_origin, "на полу"), "Пачка на полу помнит, где создана: [floor_origin]")
	TEST_ASSERT(findtext(floor_origin, "allocate") && findtext(floor_origin, "([type])"), "Пачка помнит, какой прок какого типа её создал: [floor_origin]")
	var/obj/item/stack/spacecash/c1000/part = bills.split_stack(null, 1)
	TEST_ASSERT_EQUAL(part.origin, floor_origin, "Отделённая часть помнит происхождение пачки")
	var/log_start = econ_test_log_length()
	card.attackby(part, person)
	var/list/found = list()
	for(var/line in econ_test_log_since(log_start))
		if(findtext(line, "Найденные наличные:"))
			found += line
	TEST_ASSERT_EQUAL(length(found), 1, "Одна строка о найденных наличных: [jointext(found, " | ")]")
	if(length(found))
		TEST_ASSERT(findtext(found[1], "1000 кр.") && findtext(found[1], "[/obj/item/stack/spacecash/c1000] x1") && findtext(found[1], floor_origin), "Строка называет сумму, пачку и её происхождение: [found[1]]")
	var/obj/item/stack/spacecash/c1000/held = allocate(/obj/item/stack/spacecash/c1000, person)
	TEST_ASSERT(findtext(held.origin, "у ") && findtext(held.origin, person.real_name), "Пачка в вещах моба помнит владельца: [held.origin]")
	held.merge(bills)
	TEST_ASSERT(findtext(bills.origin, floor_origin) && findtext(bills.origin, person.real_name), "Слитая пачка помнит оба происхождения: [bills.origin]")
	TEST_ASSERT(SSeconomy.move(account, cash, bills.get_item_credit_value(), ECON_CASH_OUT), "Снятие на сумму пачки")
	var/merged_origin = bills.origin
	log_start = econ_test_log_length()
	card.attackby(bills, person)
	var/list/unbacked = list()
	for(var/line in econ_test_log_since(log_start))
		TEST_ASSERT(!findtext(line, "Найденные наличные:"), "Внесение в пределах оборота пишет найденные наличные: [line]")
		if(findtext(line, "Наличные не со снятия со счёта:"))
			unbacked += line
	TEST_ASSERT_EQUAL(length(unbacked), 1, "Пачки не со снятия со счёта от [ECON_CASH_IN_LOG_MIN] кр. пишут строку и в пределах оборота: [jointext(unbacked, " | ")]")
	if(length(unbacked))
		TEST_ASSERT(findtext(unbacked[1], "3000 кр.") && findtext(unbacked[1], merged_origin), "Строка называет сумму и происхождение пачки: [unbacked[1]]")
	var/obj/item/holochip/chip = allocate(/obj/item/holochip, run_loc_floor_bottom_left, 500)
	var/chip_origin = chip.origin
	log_start = econ_test_log_length()
	card.attackby(chip, person)
	var/chip_line = jointext(econ_test_log_since(log_start), "\n")
	TEST_ASSERT(findtext(chip_line, "Найденные наличные: 500 кр.") && findtext(chip_line, "[/obj/item/holochip] на 500 кр. ([chip_origin])"), "Голочип тоже называет происхождение: [chip_line]")

/// Строки econ.log о наличных из одного внесения, с этим заголовком
/proc/econ_test_cash_lines(log_start, head)
	. = list()
	for(var/line in econ_test_log_since(log_start))
		if(findtext(line, head))
			. += line

/// Чужие необеспеченные деньги "съели" оборот, а строку о найденных получил честный голочип: необеспеченная пачка от порога названа при своём внесении, снятый со счёта чип помечен, мелочь в пределах оборота и снятое строк не пишут.
/datum/unit_test/economy_found_cash_origin/withdrawn_and_unbacked/Run()
	var/datum/bank_account/cash = SSeconomy.cash_account
	saved_cash = cash.account_balance
	econ_test_set_balance(cash, 0)
	var/mob/living/carbon/human/person = econ_test_card_holder(src, "econ_test_cash_mix", 5000)
	var/obj/item/card/id/card = person.get_idcard(TRUE)
	var/datum/bank_account/account = card.registered_account
	TEST_ASSERT(SSeconomy.move(account, cash, 2000, ECON_CASH_OUT, person), "Честное снятие")
	var/obj/item/holochip/honest = allocate(/obj/item/holochip, run_loc_floor_bottom_left, 2000)
	econ_cash_mark_withdrawn(honest, account, person)
	TEST_ASSERT(honest.withdrawn && findtext(honest.origin, "снято со счёта [account.account_holder]"), "Снятый чип помечен: [honest.origin]")
	var/obj/item/stack/spacecash/c500/unbacked = allocate(/obj/item/stack/spacecash/c500, run_loc_floor_bottom_left, 3)
	var/unbacked_origin = unbacked.origin
	var/log_start = econ_test_log_length()
	card.attackby(unbacked, person)
	var/list/lines = econ_test_cash_lines(log_start, "Наличные не со снятия со счёта: 1500 кр.")
	TEST_ASSERT_EQUAL(length(lines), 1, "Необеспеченная пачка от порога не названа при своём внесении, пока оборот её покрывал")
	if(length(lines))
		TEST_ASSERT(findtext(lines[1], unbacked_origin), "Строка называет происхождение пачки: [lines[1]]")
	var/honest_origin = honest.origin
	log_start = econ_test_log_length()
	card.attackby(honest, person)
	lines = econ_test_cash_lines(log_start, "Найденные наличные: 1500 кр.")
	TEST_ASSERT_EQUAL(length(lines), 1, "Найденные наличные при внесении честного чипа: [jointext(econ_test_log_since(log_start), " | ")]")
	if(length(lines))
		TEST_ASSERT(findtext(lines[1], honest_origin), "Строка показывает, что чип снят со счёта: [lines[1]]")
	TEST_ASSERT(SSeconomy.move(account, cash, 1500, ECON_CASH_OUT, person), "Ещё снятие")
	var/obj/item/holochip/again = allocate(/obj/item/holochip, run_loc_floor_bottom_left, 1500)
	econ_cash_mark_withdrawn(again, account, person)
	var/obj/item/holochip/small = allocate(/obj/item/holochip, run_loc_floor_bottom_left, ECON_CASH_IN_LOG_MIN - 1)
	econ_test_set_balance(cash, cash.account_balance + small.credits)
	log_start = econ_test_log_length()
	card.attackby(again, person)
	card.attackby(small, person)
	TEST_ASSERT_EQUAL(length(econ_test_cash_lines(log_start, "Вносили:")), 0, "Снятое и мелочь в пределах оборота пишут состав: [jointext(econ_test_log_since(log_start), " | ")]")
	var/obj/item/holochip/withdrawn = allocate(/obj/item/holochip, run_loc_floor_bottom_left, 100)
	econ_cash_mark_withdrawn(withdrawn, account, person)
	var/obj/item/holochip/found = allocate(/obj/item/holochip, run_loc_floor_bottom_left, 100)
	withdrawn.attackby(found, person)
	TEST_ASSERT(!withdrawn.withdrawn, "Чип со слитыми в него найденными деньгами всё ещё считается снятым")

/// Отказ банка из-за суммы называет, что вносили; суммы в составе - без экспоненты.
/datum/unit_test/economy_found_cash_origin/rejected_and_digits/Run()
	var/datum/bank_account/cash = SSeconomy.cash_account
	saved_cash = cash.account_balance
	econ_test_set_balance(cash, 0)
	var/mob/living/carbon/human/person = econ_test_card_holder(src, "econ_test_cash_absurd", 0)
	var/obj/item/card/id/card = person.get_idcard(TRUE)
	var/obj/item/holochip/absurd = allocate(/obj/item/holochip, run_loc_floor_bottom_left, 1e34)
	var/absurd_origin = absurd.origin
	var/log_start = econ_test_log_length()
	card.attackby(absurd, person)
	var/list/lines = econ_test_cash_lines(log_start, "Отклонено внесение наличных:")
	TEST_ASSERT_EQUAL(length(lines), 1, "Отказ из-за суммы не называет, что вносили: [jointext(econ_test_log_since(log_start), " | ")]")
	if(length(lines))
		TEST_ASSERT(findtext(lines[1], "[/obj/item/holochip] на") && findtext(lines[1], absurd_origin) && findtext(lines[1], key_name(person)), "Строка отказа с составом, происхождением и кто вносил: [lines[1]]")
	TEST_ASSERT_EQUAL(card.registered_account.account_balance, 0, "Отклонённое не зачислено")
	var/obj/item/holochip/big = allocate(/obj/item/holochip, run_loc_floor_bottom_left, 1234567)
	log_start = econ_test_log_length()
	card.attackby(big, person)
	var/text = jointext(econ_test_cash_lines(log_start, "Найденные наличные:"), " | ")
	TEST_ASSERT(findtext(text, "[/obj/item/holochip] на 1234567 кр."), "Сумма в составе с экспонентой: [text]")

/// Аплинк чёрного рынка, игровой автомат и стенд оплаты пишут состав внесённых наличных с происхождением; вывод из аплинка наследует происхождение.
/datum/unit_test/economy_found_cash_origin/other_entries/Run()
	var/datum/bank_account/cash = SSeconomy.cash_account
	saved_cash = cash.account_balance
	econ_test_set_balance(cash, 0)
	var/mob/living/carbon/human/person = econ_test_card_holder(src, "econ_test_cash_entries", 0)
	var/obj/item/blackmarket_uplink/uplink = allocate(/obj/item/blackmarket_uplink, run_loc_floor_bottom_left)
	var/obj/item/holochip/chip = allocate(/obj/item/holochip, run_loc_floor_bottom_left, 500)
	var/chip_origin = chip.origin
	var/log_start = econ_test_log_length()
	uplink.attackby(chip, person)
	TEST_ASSERT_EQUAL(uplink.money, 500, "Аплинк принял чип")
	var/text = jointext(econ_test_cash_lines(log_start, "Найденные наличные: 500 кр."), " | ")
	TEST_ASSERT(findtext(text, chip_origin), "Аплинк не называет, откуда найденные наличные: [jointext(econ_test_log_since(log_start), " | ")]")
	var/obj/item/holochip/washed = uplink.withdraw_money(person, 300)
	allocated += washed
	TEST_ASSERT(findtext(washed.origin, "из аплинка чёрного рынка") && findtext(washed.origin, chip_origin) && !washed.withdrawn, "Вывод из аплинка не наследует происхождение внесённого: [washed.origin]")
	econ_test_set_balance(cash, 0)
	var/obj/machinery/computer/slot_machine/slots = allocate(/obj/machinery/computer/slot_machine, run_loc_floor_bottom_left)
	var/obj/item/holochip/slot_chip = allocate(/obj/item/holochip, run_loc_floor_bottom_left, 1500)
	var/slot_origin = slot_chip.origin
	log_start = econ_test_log_length()
	slots.attackby(slot_chip, person)
	slots.balance = 0
	text = jointext(econ_test_cash_lines(log_start, "Наличные сверх оборота: 1500 кр."), " | ")
	TEST_ASSERT(findtext(text, slot_origin), "Автомат не называет голочип сверх оборота: [jointext(econ_test_log_since(log_start), " | ")]")
	var/mob/living/carbon/human/seller = econ_test_card_holder(src, "econ_test_cash_stand", 0)
	var/obj/machinery/paystand/stand = allocate(/obj/machinery/paystand, run_loc_floor_bottom_left)
	stand.my_card = seller.get_idcard(TRUE)
	var/obj/item/holochip/stand_chip = allocate(/obj/item/holochip, run_loc_floor_bottom_left, 1200)
	var/stand_origin = stand_chip.origin
	log_start = econ_test_log_length()
	TEST_ASSERT(stand.pay_holochip(person, stand_chip, 1200), "Оплата голочипом на стенде")
	stand.my_card = null
	text = jointext(econ_test_cash_lines(log_start, "Найденные наличные: 1200 кр."), " | ")
	TEST_ASSERT(findtext(text, stand_origin), "Стенд не называет, откуда найденные наличные: [jointext(econ_test_log_since(log_start), " | ")]")

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
	TEST_ASSERT(findtext(text, "ENG 4000/1000/2100/600/[budget.account_balance]"), "Отдел: пришло, выдано, сожжено, возврат и остаток отдельно: [text]")
	var/datum/bank_account/department/security = SSeconomy.get_dep_account(ACCOUNT_SEC)
	var/security_before = security.account_balance
	TEST_ASSERT(SSeconomy.move(security, worker, 300, ECON_WAGE), "Выплата из бюджета СБ: на нём [security_before] кр.")
	text = jointext(SSeconomy.ledger.round_summary(), "\n")
	econ_test_set_balance(security, security_before)
	TEST_ASSERT(findtext(text, "SEC 0/300/0/0/"), "Выплата из стартового бюджета не даёт отрицательного прихода: [text]")

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
	var/datum/economy_ledger/live = SSeconomy.ledger
	TEST_ASSERT(!live.outpost_minted_by_reason[ECON_STARTING_FUNDS], "Стартовые бюджеты в эмиссии аванпостов: [live.outpost_minted_by_reason[ECON_STARTING_FUNDS]]")
	for(var/id in SSeconomy.departments)
		TEST_ASSERT(!(id in live.outpost_flows), "Отдел станции [id] среди аванпостов в итоге смены")
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
	TEST_ASSERT(findtext(text, "DS 5000/500/1000/[outpost.account_balance] (export 5000)"), "Deep Space в строке аванпостов с эмиссией по причинам: [text]")
	TEST_ASSERT(findtext(text, "TAR 0/0/0/[other_outpost.account_balance]") && !findtext(text, "TAR 0/0/0/[other_outpost.account_balance] ("), "Тарков в строке аванпостов без движений: [text]")

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
	SSeconomy.crypto_paid_tick = -1
	var/crypto_after_end = SSeconomy.pay_crypto(budget, 100)
	var/minted_after_end = SSeconomy.ledger.minted
	var/snapshots_after_end = length(SSeconomy.ledger.snapshots)
	var/first_summary = econ_log_round_summary()
	var/second_summary = econ_log_round_summary()
	SSticker.current_state = previous_ticker_state
	previous_ticker_state = null
	var/paid_in_round = SSeconomy.record_work(ACCOUNT_ENG, WORK_ENG_POWER_EXPORT, 100)

	TEST_ASSERT_EQUAL(fires_after, fires, "Тик экономики после конца раунда пропущен")
	TEST_ASSERT_EQUAL(paid_after_end, 0, "Работа после конца раунда не оплачена")
	TEST_ASSERT_EQUAL(crypto_after_end, 0, "Майнеры после конца раунда не платят")
	TEST_ASSERT_EQUAL(minted_after_end, 0, "Эмиссии после конца раунда нет")
	TEST_ASSERT_EQUAL(snapshots_after_end, 0, "Снимок журнала после конца раунда не снят")
	TEST_ASSERT(first_summary, "Итог смены записан")
	TEST_ASSERT(!second_summary, "Итог смены записан один раз")
	TEST_ASSERT(paid_in_round > 0, "Во время раунда работа оплачивается: [paid_in_round]")
