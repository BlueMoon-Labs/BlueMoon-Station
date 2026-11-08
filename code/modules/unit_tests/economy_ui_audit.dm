/datum/unit_test/economy_ui_audit
	abstract_type = /datum/unit_test/economy_ui_audit
	var/list/saved_flags
	var/saved_sec_balance
	var/saved_tax_rate

/datum/unit_test/economy_ui_audit/New()
	. = ..()
	saved_flags = SSeconomy.audit_flags
	SSeconomy.audit_flags = list()
	var/datum/bank_account/security = SSeconomy.get_dep_account(ACCOUNT_SEC)
	saved_sec_balance = security.account_balance
	saved_tax_rate = SSeconomy.tax_rate
	SSeconomy.tax_rate = 0

/datum/unit_test/economy_ui_audit/Destroy()
	QDEL_LIST(SSeconomy.audit_flags)
	SSeconomy.audit_flags = saved_flags
	econ_test_set_balance(SSeconomy.get_dep_account(ACCOUNT_SEC), saved_sec_balance)
	SSeconomy.tax_rate = saved_tax_rate
	return ..()

/// Счёт, который запоминает сообщения на свою карту.
/datum/bank_account/econ_test_spy
	var/list/card_messages = list()

/datum/bank_account/econ_test_spy/bank_card_talk(message, force, talk_sound, balloon, quiet)
	card_messages += message

/datum/unit_test/economy_ui_audit/proc/make_account(holder, balance = 0, account_type = /datum/bank_account)
	var/datum/bank_account/account = new account_type(holder)
	allocated += account
	if(balance)
		econ_test_set_balance(account, balance)
	return account

/// Человек со своим счётом и КПК в руке, в КПК - его ID-карта; с job_type - по должности и её доступу.
/datum/unit_test/economy_ui_audit/proc/make_person(holder, list/access, job_type, pda_type = /obj/item/modular_computer/pda/detective)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human)
	person.mind_initialize()
	var/datum/bank_account/account = make_account(holder)
	account.bind_owner(person)
	person.account_id = account.account_id
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = account
	card.registered_name = holder
	if(job_type)
		var/datum/job/job = SSjob.GetJobType(job_type)
		access = job.access
		person.mind.assigned_role = job.title
		card.assignment = job.title
	card.access = access ? access.Copy() : list()
	var/obj/item/modular_computer/pda/pda = allocate(pda_type)
	pda.InsertID(card)
	person.put_in_active_hand(pda)
	return person

/datum/unit_test/economy_ui_audit/proc/program_of(mob/living/carbon/human/person)
	var/obj/item/modular_computer/pda/pda = person.get_active_held_item()
	return locate(/datum/computer_file/program/financial_audit) in pda.get_all_files()

/datum/unit_test/economy_ui_audit/proc/press(mob/living/carbon/human/person, action, list/params = list())
	var/datum/computer_file/program/financial_audit/program = program_of(person)
	var/datum/tgui/window = allocate(/datum/tgui, person, program, "NtosFinancialAudit")
	window.status = UI_INTERACTIVE
	usr = person
	program.ui_act(action, params, window)
	usr = null
	return program.messages[REF(person)]

/datum/unit_test/economy_ui_audit/proc/case_row(mob/living/carbon/human/person, uid)
	var/datum/computer_file/program/financial_audit/program = program_of(person)
	var/list/data = program.audit_data(person)
	for(var/list/entry as anything in data["cases"])
		if(entry["uid"] == uid)
			return entry

/// Приложение стоит в КПК ГСБ, детектива, ГП и капитана, у офицера его нет.
/datum/unit_test/economy_ui_audit/presets/Run()
	for(var/pda_type in list(/obj/item/modular_computer/pda/heads/hos, /obj/item/modular_computer/pda/detective, /obj/item/modular_computer/pda/heads/hop, /obj/item/modular_computer/pda/heads/captain))
		var/obj/item/modular_computer/pda/pda = allocate(pda_type)
		TEST_ASSERT_NOTNULL(locate(/datum/computer_file/program/financial_audit) in pda.get_all_files(), "Аудит в [pda_type]")
	var/obj/item/modular_computer/pda/officer_pda = allocate(/obj/item/modular_computer/pda/security)
	TEST_ASSERT_NULL(locate(/datum/computer_file/program/financial_audit) in officer_pda.get_all_files(), "У офицера аудита нет")

/// Офицер и детектив без доступа своей должности на ID получают отказ и не видят дел; детектив с доступом видит дела и правила.
/datum/unit_test/economy_ui_audit/rights/Run()
	var/datum/bank_account/victim = make_account("Econ UI Audit Victim", 1000)
	var/datum/bank_account/thief = make_account("Econ UI Audit Thief")
	SSeconomy.move(victim, thief, 500, ECON_SKIM)
	var/mob/living/carbon/human/officer = make_person("Econ UI Audit Officer", list(ACCESS_SECURITY, ACCESS_FORENSICS_LOCKERS, ACCESS_BRIG))
	var/mob/living/carbon/human/demoted = make_person("Econ UI Audit Demoted", job_type = /datum/job/detective)
	var/obj/item/card/id/demoted_card = demoted.get_idcard(TRUE)
	demoted_card.access = list(ACCESS_SECURITY)
	var/mob/living/carbon/human/detective = make_person("Econ UI Audit Detective", job_type = /datum/job/detective)
	var/refusal = press(officer, "freeze", list("number" = "[thief.account_id]", "reason" = "кража"))
	TEST_ASSERT_EQUAL(refusal, "Нужны права финансового аудита: [SSeconomy.audit_rights_text()].", "Офицеру отказано с объяснением")
	press(demoted, "freeze", list("number" = "[thief.account_id]", "reason" = "кража"))
	TEST_ASSERT_EQUAL(thief.state, ACCOUNT_ACTIVE, "Без прав счёт не заморожен")
	var/datum/computer_file/program/financial_audit/officer_program = program_of(officer)
	var/list/officer_data = officer_program.audit_data(officer)
	TEST_ASSERT(!officer_data["can_audit"], "Офицер без прав")
	TEST_ASSERT(!("cases" in officer_data), "Офицеру дела не видны")
	TEST_ASSERT(!("rules" in officer_data), "Офицеру пороги не видны")
	TEST_ASSERT_EQUAL(officer_data["audit_rights"], SSeconomy.audit_rights_text(), "Кто ведёт аудит - в справке")
	var/datum/computer_file/program/financial_audit/demoted_program = program_of(demoted)
	TEST_ASSERT(!demoted_program.audit_data(demoted)["can_audit"], "Детектив без доступа на ID без прав")
	var/datum/computer_file/program/financial_audit/program = program_of(detective)
	var/list/data = program.audit_data(detective)
	TEST_ASSERT(data["can_audit"], "Детектив с доступом ведёт аудит")
	TEST_ASSERT_EQUAL(length(data["cases"]), 1, "Дело видно")
	var/list/rules = data["rules"]
	TEST_ASSERT_EQUAL(rules["siphon_threshold"], SSeconomy.settings.audit_bonus_threshold, "Порог оттока из настроек")
	TEST_ASSERT_EQUAL(rules["fee_percent"], SSeconomy.settings.audit_case_fee_percent, "Сбор СБ из настроек")

/// Поиск по части имени и по номеру, след до получателя, заморозка с причиной и разморозка - через действия окна.
/datum/unit_test/economy_ui_audit/search_trace_freeze/Run()
	var/mob/living/carbon/human/detective = make_person("Econ UI Audit Sleuth", job_type = /datum/job/detective)
	var/datum/bank_account/victim = make_account("Econ UI Audit Victim", 1000)
	var/datum/bank_account/thief = make_account("Econ UI Audit Thief")
	SSeconomy.move(victim, thief, 500, ECON_SKIM)
	var/datum/computer_file/program/financial_audit/program = program_of(detective)
	press(detective, "search", list("query" = "ui audit victim"))
	var/list/results = program.audit_data(detective)["results"]
	TEST_ASSERT_EQUAL(length(results), 1, "Найден по части имени без учёта регистра")
	var/list/found = results[1]
	TEST_ASSERT_EQUAL(found["number"], victim.account_id, "Найден нужный счёт")
	press(detective, "search", list("query" = "[thief.account_id]"))
	results = program.audit_data(detective)["results"]
	TEST_ASSERT_EQUAL(length(results), 1, "Найден по номеру")
	var/empty = press(detective, "search", list("query" = list("мусор")))
	TEST_ASSERT_EQUAL(empty, "Введите имя владельца или номер счёта.", "Не строка - пустой запрос")
	press(detective, "trace", list("number" = "[victim.account_id]"))
	var/list/trace = program.audit_data(detective)["trace"]
	var/list/tree = trace["tree"]
	TEST_ASSERT_EQUAL(length(tree), 1, "След до вора")
	var/list/node = tree[1]
	TEST_ASSERT_EQUAL(node["number"], thief.account_id, "След ведёт на счёт вора")
	TEST_ASSERT_EQUAL(node["amount"], 500, "Сумма в следе")
	var/no_reason = press(detective, "freeze", list("number" = "[thief.account_id]", "reason" = "  "))
	TEST_ASSERT_EQUAL(thief.state, ACCOUNT_ACTIVE, "Без причины не замораживается")
	TEST_ASSERT_EQUAL(no_reason, "Укажите причину заморозки: владелец увидит её на карте.", "Отказ без причины объяснён")
	var/long_reason = ""
	for(var/i in 1 to AUDIT_REASON_MAX * 2)
		long_reason += "я"
	press(detective, "freeze", list("number" = "[thief.account_id]", "reason" = long_reason))
	TEST_ASSERT_EQUAL(thief.state, ACCOUNT_FROZEN, "Заморожен")
	TEST_ASSERT(length_char(thief.freeze_reason) <= AUDIT_REASON_MAX, "Причина обрезана")
	TEST_ASSERT(findtext(thief.frozen_by, "Econ UI Audit Sleuth"), "Кто заморозил")
	var/datum/bank_account/own_account = econ_account_of(detective)
	var/own = press(detective, "freeze", list("number" = "[own_account.account_id]", "reason" = "проверка"))
	TEST_ASSERT_EQUAL(own, "Свой счёт заморозить или разморозить нельзя.", "Свой счёт не замораживается")
	press(detective, "select", list("number" = "[thief.account_id]"))
	var/list/selected = program.audit_data(detective)["selected"]
	TEST_ASSERT_EQUAL(selected["status"], "frozen", "Карточка счёта показывает заморозку")
	TEST_ASSERT_EQUAL(length(selected["cases"]), 1, "Карточка счёта показывает дело")
	TEST_ASSERT(length(selected["history"]) >= 1, "История счёта в карточке")
	press(detective, "unfreeze", list("number" = thief.account_id))
	TEST_ASSERT_EQUAL(thief.state, ACCOUNT_ACTIVE, "Разморожен")
	TEST_ASSERT_NULL(thief.frozen_by, "Отметка о заморозке снята")

/// Поиск по имени отдаёт не больше двадцати счетов.
/datum/unit_test/economy_ui_audit/search_cap/Run()
	var/mob/living/carbon/human/detective = make_person("Econ UI Audit Seeker", job_type = /datum/job/detective)
	for(var/i in 1 to 25)
		make_account("Econ UI Audit Crowd [i]")
	var/message = press(detective, "search", list("query" = "Econ UI Audit Crowd"))
	var/datum/computer_file/program/financial_audit/program = program_of(detective)
	TEST_ASSERT_EQUAL(length(program.audit_data(detective)["results"]), 20, "Не больше двадцати результатов")
	TEST_ASSERT(findtext(message, "уточните запрос"), "Просьба уточнить запрос")

/// Возврат по делу из окна: только с замороженного получателя, сбор СБ с суммы, дело закрыто, повтор запрещён, денег не создаётся.
/datum/unit_test/economy_ui_audit/refund/Run()
	var/mob/living/carbon/human/hos = make_person("Econ UI Audit HoS", list(ACCESS_HOS), pda_type = /obj/item/modular_computer/pda/heads/hos)
	var/datum/bank_account/victim = make_account("Econ UI Audit Victim", 1000)
	var/datum/bank_account/thief = make_account("Econ UI Audit Thief")
	var/datum/bank_account/security = SSeconomy.get_dep_account(ACCOUNT_SEC)
	econ_test_set_balance(security, 0)
	SSeconomy.move(victim, thief, 1000, ECON_SKIM)
	var/datum/econ_audit_flag/flag = SSeconomy.flags_for(victim)[1]
	var/minted = SSeconomy.ledger.minted
	var/burned = SSeconomy.ledger.burned
	var/early = press(hos, "refund", list("uid" = "[flag.uid]", "amount" = "1000"))
	TEST_ASSERT_EQUAL(early, "Сначала заморозьте счёт получателя.", "Без заморозки возврата нет")
	TEST_ASSERT_EQUAL(thief.account_balance, 1000, "Деньги не тронуты")
	press(hos, "freeze", list("number" = "[thief.account_id]", "reason" = "скиммер"))
	var/too_much = press(hos, "refund", list("uid" = "[flag.uid]", "amount" = "5000"))
	TEST_ASSERT_EQUAL(too_much, "Больше суммы по делу: не больше 1000 кр.", "Не больше суммы дела")
	var/fee = round(1000 * SSeconomy.settings.audit_case_fee_percent / 100)
	var/done = press(hos, "refund", list("uid" = "[flag.uid]", "amount" = "1000"))
	TEST_ASSERT_EQUAL(done, "Дело №[flag.uid] закрыто: пострадавшему возвращено [1000 - fee] кр., сбор отдела безопасности [fee] кр.", "Итог возврата в окне")
	TEST_ASSERT_EQUAL(victim.account_balance, 1000 - fee, "Пострадавшему за вычетом сбора")
	TEST_ASSERT_EQUAL(security.account_balance, fee, "Сбор в бюджет СБ")
	TEST_ASSERT_EQUAL(thief.account_balance, 0, "Списано с получателя")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted, "Возврат не печатает деньги")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned, burned, "Возврат не сжигает деньги")
	var/list/row = case_row(hos, flag.uid)
	TEST_ASSERT(row["closed"], "Дело закрыто")
	TEST_ASSERT_EQUAL(row["refunded"], 1000 - fee, "Возвращённая сумма в деле")
	TEST_ASSERT(findtext(row["closed_by"], "Econ UI Audit HoS"), "Кто закрыл")
	var/again = press(hos, "refund", list("uid" = "[flag.uid]", "amount" = "1"))
	TEST_ASSERT_EQUAL(again, "Дело уже закрыто, повторный возврат запрещён.", "Повторного возврата нет")
	var/missing = press(hos, "refund", list("uid" = "abc", "amount" = "1"))
	TEST_ASSERT_EQUAL(missing, "Дело не найдено.", "Мусор вместо номера дела")

/// Закрытие дела без возврата: нужна причина, свои дела закрывает другой аудитор, в списке видны кто и почему закрыл.
/datum/unit_test/economy_ui_audit/close_case/Run()
	var/mob/living/carbon/human/captain = make_person("Econ UI Audit Captain", list(ACCESS_CAPTAIN), pda_type = /obj/item/modular_computer/pda/heads/captain)
	var/datum/bank_account/victim = make_account("Econ UI Audit Victim", 1000)
	var/datum/bank_account/thief = make_account("Econ UI Audit Thief")
	SSeconomy.move(victim, thief, 300, ECON_SKIM)
	var/datum/econ_audit_flag/flag = SSeconomy.flags_for(victim)[1]
	var/no_reason = press(captain, "close_case", list("uid" = "[flag.uid]", "reason" = ""))
	TEST_ASSERT_EQUAL(no_reason, "Укажите причину закрытия: её увидят владельцы обоих счетов.", "Без причины не закрывается")
	TEST_ASSERT(!flag.closed, "Дело открыто")
	press(captain, "close_case", list("uid" = "[flag.uid]", "reason" = "<b>Сам себе</b> перевёл"))
	var/list/row = case_row(captain, flag.uid)
	TEST_ASSERT(row["closed"], "Дело закрыто")
	TEST_ASSERT(!findtext(row["close_reason"], "<b>"), "Разметка из причины убрана")
	TEST_ASSERT(findtext(row["close_reason"], "перевёл"), "Причина сохранена")
	TEST_ASSERT(findtext(row["closed_by"], "Econ UI Audit Captain"), "Кто закрыл")
	TEST_ASSERT_EQUAL(thief.account_balance, 300, "Закрытие без возврата денег не двигает")
	var/datum/bank_account/own = econ_account_of(captain)
	econ_test_set_balance(own, 500)
	SSeconomy.move(own, thief, 200, ECON_SKIM)
	var/datum/econ_audit_flag/own_flag = SSeconomy.flags_for(own)[1]
	var/refusal = press(captain, "close_case", list("uid" = own_flag.uid, "reason" = "ошибка"))
	TEST_ASSERT_EQUAL(refusal, "Дело, где замешан ваш счёт, ведёт другой аудитор.", "Своё дело не закрыть")
	TEST_ASSERT(!own_flag.closed, "Своё дело открыто")

/// Объединённое дело оттока: возврат с первого и последнего получателя не больше его доли, повтор с выплаченного запрещён, подставной получатель на 1 кр. ничего не меняет.
/datum/unit_test/economy_ui_audit/pooled_refund
	var/saved_engineering
	var/list/saved_engineering_audit

/datum/unit_test/economy_ui_audit/pooled_refund/New()
	. = ..()
	var/datum/bank_account/engineering = SSeconomy.get_dep_account(ACCOUNT_ENG)
	saved_engineering = engineering.account_balance
	saved_engineering_audit = list(engineering.audit_outflows, engineering.audit_watch, engineering.audit_pool)
	engineering.audit_outflows = null
	engineering.audit_watch = null
	engineering.audit_pool = null

/datum/unit_test/economy_ui_audit/pooled_refund/Destroy()
	var/datum/bank_account/engineering = SSeconomy.get_dep_account(ACCOUNT_ENG)
	econ_test_set_balance(engineering, saved_engineering)
	engineering.audit_outflows = saved_engineering_audit[1]
	engineering.audit_watch = saved_engineering_audit[2]
	engineering.audit_pool = saved_engineering_audit[3]
	return ..()

/datum/unit_test/economy_ui_audit/pooled_refund/Run()
	var/mob/living/carbon/human/hos = make_person("Econ UI Audit HoS", list(ACCESS_HOS), pda_type = /obj/item/modular_computer/pda/heads/hos)
	var/datum/bank_account/engineering = SSeconomy.get_dep_account(ACCOUNT_ENG)
	var/part = round(SSeconomy.settings.audit_bonus_threshold * 0.6)
	econ_test_set_balance(engineering, part * 2 + 1)
	econ_test_set_balance(SSeconomy.get_dep_account(ACCOUNT_SEC), 0)
	var/datum/bank_account/first = make_account("Econ UI Pool First")
	var/datum/bank_account/last = make_account("Econ UI Pool Last")
	var/datum/bank_account/decoy = make_account("Econ UI Pool Decoy")
	SSeconomy.move(engineering, first, part, ECON_BONUS)
	SSeconomy.move(engineering, last, part, ECON_BONUS)
	SSeconomy.move(engineering, decoy, 1, ECON_BONUS)
	var/list/flags = SSeconomy.flags_for(first)
	TEST_ASSERT_EQUAL(length(flags), 1, "Одно объединённое дело")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT(flag.pooled, "Дело объединённое")
	TEST_ASSERT((flag in SSeconomy.flags_for(last)) && (flag in SSeconomy.flags_for(decoy)), "Дело находится по любому получателю")
	TEST_ASSERT_EQUAL(flag.amount, part * 2 + 1, "Сумма дела")
	var/list/row = case_row(hos, flag.uid)
	TEST_ASSERT_EQUAL(length(row["recipients"]), 3, "Все получатели в окне")
	for(var/datum/bank_account/recipient as anything in list(first, last, decoy))
		press(hos, "freeze", list("number" = "[recipient.account_id]", "reason" = "отток"))
	var/decoy_refusal = press(hos, "refund", list("uid" = "[flag.uid]", "amount" = "[part]", "recipient" = "[decoy.account_id]"))
	TEST_ASSERT_EQUAL(decoy_refusal, "Больше, чем ушло на этот счёт по делу: не больше 1 кр.", "С подставного не больше его доли")
	var/too_much = press(hos, "refund", list("uid" = "[flag.uid]", "amount" = "[part + 1]", "recipient" = "[first.account_id]"))
	TEST_ASSERT_EQUAL(too_much, "Больше, чем ушло на этот счёт по делу: не больше [part] кр.", "Не больше доли получателя")
	press(hos, "refund", list("uid" = "[flag.uid]", "amount" = "[part]", "recipient" = "[first.account_id]"))
	TEST_ASSERT_EQUAL(first.account_balance, 0, "Возврат с первого получателя")
	TEST_ASSERT(!flag.closed, "Дело открыто, пока вернули не всё")
	var/again = press(hos, "refund", list("uid" = "[flag.uid]", "amount" = "1", "recipient" = "[first.account_id]"))
	TEST_ASSERT_EQUAL(again, "С этого получателя по делу уже всё возвращено.", "Повтор с выплаченного запрещён")
	var/fee = round(part * SSeconomy.settings.audit_case_fee_percent / 100)
	var/message = press(hos, "refund", list("uid" = "[flag.uid]", "amount" = "[part]", "recipient" = "[last.account_id]"))
	TEST_ASSERT_EQUAL(last.account_balance, 0, "Возврат с последнего получателя")
	TEST_ASSERT_EQUAL(message, "По делу №[flag.uid] со счёта №[last.account_id] пострадавшему возвращено [part - fee] кр., сбор отдела безопасности [fee] кр. Дело открыто, осталось вернуть: с этого счёта 0 кр., с других получателей 1 кр.", "Остаток в ответе")
	TEST_ASSERT_EQUAL(flag.amount, part * 2 + 1, "Сумма дела равна сумме по получателям")
	TEST_ASSERT_EQUAL(engineering.account_balance, (part - fee) * 2, "Бюджет получил оба возврата")
	press(hos, "refund", list("uid" = "[flag.uid]", "amount" = "1", "recipient" = "[decoy.account_id]"))
	TEST_ASSERT(flag.closed, "Дело закрыто, когда вернули всё")
	row = case_row(hos, flag.uid)
	for(var/list/recipient_row as anything in row["recipients"])
		TEST_ASSERT_EQUAL(recipient_row["left"], 0, "Остаток по [recipient_row["holder"]]")

/// Поиск по имени без учёта регистра в кириллице, числовой запрос ищет и номер, и имя.
/datum/unit_test/economy_ui_audit/search_names/Run()
	var/mob/living/carbon/human/detective = make_person("Econ UI Audit Finder", job_type = /datum/job/detective)
	var/datum/computer_file/program/financial_audit/program = program_of(detective)
	var/datum/bank_account/ivan = make_account("Иванушка Аудитович")
	press(detective, "search", list("query" = "иванушка аудит"))
	var/list/results = program.audit_data(detective)["results"]
	TEST_ASSERT_EQUAL(length(results), 1, "Кириллица без учёта регистра")
	var/list/found = results[1]
	TEST_ASSERT_EQUAL(found["number"], ivan.account_id, "Найден Иванушка")
	var/datum/bank_account/twin = make_account("Двойник [ivan.account_id]")
	press(detective, "search", list("query" = "[ivan.account_id]"))
	results = program.audit_data(detective)["results"]
	TEST_ASSERT_EQUAL(length(results), 2, "Числовой запрос - по номеру и по имени")
	var/list/first = results[1]
	var/list/second = results[2]
	TEST_ASSERT_EQUAL(first["number"], ivan.account_id, "Сначала точный номер")
	TEST_ASSERT_EQUAL(second["number"], twin.account_id, "Потом совпадение в имени")

/// Причины заморозки и закрытия хранятся без HTML-сущностей и не режутся посередине символа; закрытие дела приходит на карты обоих счетов.
/datum/unit_test/economy_ui_audit/reasons_and_notice/Run()
	var/mob/living/carbon/human/captain = make_person("Econ UI Audit Chief", list(ACCESS_CAPTAIN), pda_type = /obj/item/modular_computer/pda/heads/captain)
	var/datum/bank_account/econ_test_spy/victim = make_account("Econ UI Audit Victim", 1000, /datum/bank_account/econ_test_spy)
	var/datum/bank_account/econ_test_spy/thief = make_account("Econ UI Audit Thief", 0, /datum/bank_account/econ_test_spy)
	SSeconomy.move(victim, thief, 300, ECON_SKIM)
	var/datum/econ_audit_flag/flag = SSeconomy.flags_for(victim)[1]
	var/long_reason = ""
	for(var/i in 1 to AUDIT_REASON_MAX - 1)
		long_reason += "я"
	press(captain, "freeze", list("number" = "[thief.account_id]", "reason" = long_reason + "\"\"\""))
	TEST_ASSERT_EQUAL(thief.freeze_reason, long_reason + "\"", "Кавычка цела, обрезка по символам")
	press(captain, "unfreeze", list("number" = "[thief.account_id]"))
	press(captain, "freeze", list("number" = "[thief.account_id]", "reason" = "\"кража\" & <b>скиммер</b>"))
	TEST_ASSERT_EQUAL(thief.freeze_reason, "\"кража\" & скиммер", "Причина заморозки без сущностей и тегов")
	thief.card_messages.Cut()
	victim.card_messages.Cut()
	press(captain, "close_case", list("uid" = "[flag.uid]", "reason" = "Сделка \"по-дружески\" & <i>ок</i>"))
	TEST_ASSERT_EQUAL(flag.close_reason, "Сделка \"по-дружески\" & ок", "Причина закрытия без сущностей и тегов")
	var/list/row = case_row(captain, flag.uid)
	TEST_ASSERT_EQUAL(row["close_reason"], "Сделка \"по-дружески\" & ок", "В окне та же причина")
	var/notice = "Дело финансового аудита №[flag.uid] по вашему счёту закрыто без возврата ([flag.closed_by]): [html_encode(flag.close_reason)]."
	TEST_ASSERT_EQUAL(length(victim.card_messages), 1, "Пострадавшему одно сообщение")
	TEST_ASSERT_EQUAL(victim.card_messages[1], notice, "Пострадавший получил сообщение на карту")
	TEST_ASSERT_EQUAL(length(thief.card_messages), 1, "Получателю одно сообщение")
	TEST_ASSERT_EQUAL(thief.card_messages[1], notice, "Получатель получил сообщение на карту")

/// След записывает платежи в бюджеты отделов конечными узлами; на пороги аудита они не влияют.
/datum/unit_test/economy_ui_audit/trace_budget
	var/saved_service
	var/list/saved_service_audit

/datum/unit_test/economy_ui_audit/trace_budget/New()
	. = ..()
	var/datum/bank_account/service = SSeconomy.get_dep_account(ACCOUNT_SRV)
	saved_service = service.account_balance
	saved_service_audit = list(service.audit_outflows, service.audit_watch, service.audit_pool)
	service.audit_outflows = null
	service.audit_watch = null
	service.audit_pool = null

/datum/unit_test/economy_ui_audit/trace_budget/Destroy()
	var/datum/bank_account/service = SSeconomy.get_dep_account(ACCOUNT_SRV)
	econ_test_set_balance(service, saved_service)
	service.audit_outflows = saved_service_audit[1]
	service.audit_watch = saved_service_audit[2]
	service.audit_pool = saved_service_audit[3]
	return ..()

/datum/unit_test/economy_ui_audit/trace_budget/Run()
	var/mob/living/carbon/human/detective = make_person("Econ UI Audit Tracer", job_type = /datum/job/detective)
	var/datum/bank_account/service = SSeconomy.get_dep_account(ACCOUNT_SRV)
	var/big = SSeconomy.settings.audit_bonus_threshold * 2
	var/datum/bank_account/payer = make_account("Econ UI Audit Diner", big)
	var/datum/bank_account/waiter = make_account("Econ UI Audit Waiter")
	econ_test_set_balance(service, 0)
	SSeconomy.move(payer, service, big, ECON_REGISTER)
	SSeconomy.move(service, waiter, 10, ECON_BONUS)
	TEST_ASSERT_EQUAL(length(SSeconomy.audit_flags), 0, "Платёж в бюджет дела не открывает")
	TEST_ASSERT_NULL(payer.audit_watch, "Платёж в бюджет не копится к порогам")
	press(detective, "trace", list("number" = "[payer.account_id]"))
	var/datum/computer_file/program/financial_audit/program = program_of(detective)
	var/list/trace = program.audit_data(detective)["trace"]
	var/list/tree = trace["tree"]
	TEST_ASSERT_EQUAL(length(tree), 1, "Бюджет в следе")
	var/list/node = tree[1]
	TEST_ASSERT_EQUAL(node["number"], service.account_id, "Узел - бюджет сервиса")
	TEST_ASSERT_EQUAL(node["amount"], big, "Сумма платежа")
	TEST_ASSERT_EQUAL(length(node["children"]), 0, "Бюджет дальше не раскрывается")

/// Кто сам выводил деньги по делу (и до порога, и после), тот его не закрывает и не возвращает; другой аудитор - может.
/datum/unit_test/economy_ui_audit/own_moves
	var/saved_treasury
	var/list/saved_treasury_audit
	var/list/accounts_before

/datum/unit_test/economy_ui_audit/own_moves/New()
	. = ..()
	var/datum/bank_account/treasury = SSeconomy.treasury()
	saved_treasury = treasury.account_balance
	saved_treasury_audit = list(treasury.audit_outflows, treasury.audit_watch, treasury.audit_pool, treasury.audit_watch_actors)
	treasury.audit_outflows = null
	treasury.audit_watch = null
	treasury.audit_pool = null
	treasury.audit_watch_actors = null
	accounts_before = SSeconomy.bank_accounts.Copy()

/datum/unit_test/economy_ui_audit/own_moves/Destroy()
	for(var/datum/bank_account/opened as anything in SSeconomy.bank_accounts - accounts_before)
		qdel(opened)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	econ_test_set_balance(treasury, saved_treasury)
	treasury.audit_outflows = saved_treasury_audit[1]
	treasury.audit_watch = saved_treasury_audit[2]
	treasury.audit_pool = saved_treasury_audit[3]
	treasury.audit_watch_actors = saved_treasury_audit[4]
	return ..()

/datum/unit_test/economy_ui_audit/own_moves/Run()
	var/mob/living/carbon/human/captain = make_person("Econ UI Audit Captain", list(ACCESS_CAPTAIN), pda_type = /obj/item/modular_computer/pda/heads/captain)
	var/mob/living/carbon/human/clerk = make_person("Econ UI Audit Clerk")
	var/mob/living/carbon/human/hos = make_person("Econ UI Audit HoS", list(ACCESS_HOS), pda_type = /obj/item/modular_computer/pda/heads/hos)
	var/part = round(SSeconomy.settings.audit_bonus_threshold * 0.6)
	econ_test_set_balance(SSeconomy.treasury(), part * 2)
	var/datum/bank_account/first = SSeconomy.open_account("Econ UI Own First", part, captain)
	var/datum/bank_account/second = SSeconomy.open_account("Econ UI Own Second", part, clerk)
	TEST_ASSERT(first && second, "Счета открыты")
	var/list/flags = SSeconomy.flags_for(first)
	TEST_ASSERT_EQUAL(length(flags), 1, "Объединённое дело открыто")
	var/datum/econ_audit_flag/flag = flags[1]
	press(captain, "freeze", list("number" = "[first.account_id]", "reason" = "отток"))
	var/refund_refusal = press(captain, "refund", list("uid" = "[flag.uid]", "amount" = "10", "recipient" = "[first.account_id]"))
	TEST_ASSERT_EQUAL(refund_refusal, AUDIT_OWN_MOVES_REFUSAL, "Капитан, открывший счёт до порога, не возвращает")
	var/close_refusal = press(captain, "close_case", list("uid" = "[flag.uid]", "reason" = "так надо"))
	TEST_ASSERT_EQUAL(close_refusal, AUDIT_OWN_MOVES_REFUSAL, "Капитан не закрывает своё дело")
	TEST_ASSERT(!flag.closed, "Дело открыто")
	var/list/row = case_row(captain, flag.uid)
	TEST_ASSERT(row["mine"], "Окно капитана помечает дело своим")
	row = case_row(hos, flag.uid)
	TEST_ASSERT(!row["mine"], "Для главы СБ дело чужое")
	press(hos, "close_case", list("uid" = "[flag.uid]", "reason" = "проверено"))
	TEST_ASSERT(flag.closed, "Другой аудитор закрыл дело")

/// Заморозку ЦК аудитор не снимает: отказ с объяснением, карточка показывает его вместо кнопки.
/datum/unit_test/economy_ui_audit/admin_freeze/Run()
	var/mob/living/carbon/human/detective = make_person("Econ UI Audit Warden", job_type = /datum/job/detective)
	var/datum/bank_account/suspect = make_account("Econ UI Audit Suspect", 100)
	SSeconomy.apply_freeze(suspect, ECON_ADMIN_FROZEN_BY, "проверка ЦК")
	var/answer = press(detective, "unfreeze", list("number" = "[suspect.account_id]"))
	TEST_ASSERT_EQUAL(suspect.state, ACCOUNT_FROZEN, "Аудитор не снимает заморозку ЦК")
	TEST_ASSERT_EQUAL(answer, ECON_ADMIN_FREEZE_LOCKED, "Отказ объяснён")
	press(detective, "select", list("number" = "[suspect.account_id]"))
	var/datum/computer_file/program/financial_audit/program = program_of(detective)
	var/list/selected = program.audit_data(detective)["selected"]
	TEST_ASSERT_EQUAL(selected["freeze_locked"], ECON_ADMIN_FREEZE_LOCKED, "Карточка показывает, кто может разморозить")
	SSeconomy.apply_unfreeze(suspect, ECON_ADMIN_FROZEN_BY)
	SSeconomy.apply_freeze(suspect, SSeconomy.auditor_name(detective), "проверка")
	press(detective, "select", list("number" = "[suspect.account_id]"))
	selected = program.audit_data(detective)["selected"]
	TEST_ASSERT_NULL(selected["freeze_locked"], "Заморозку аудитом аудитор снимает")
