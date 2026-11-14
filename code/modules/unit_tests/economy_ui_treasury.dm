/datum/unit_test/economy_ui_treasury
	abstract_type = /datum/unit_test/economy_ui_treasury
	var/list/saved_balances = list()
	var/list/saved_treasury_requests
	var/saved_tax_rate
	var/list/accounts_before
	/// Списки аудита казны: тесты открывают счета из неё
	var/list/saved_treasury_audit

/datum/unit_test/economy_ui_treasury/New()
	. = ..()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		saved_balances[id] = department.account.account_balance
	saved_treasury_requests = SSeconomy.treasury_requests
	SSeconomy.treasury_requests = list()
	saved_tax_rate = SSeconomy.tax_rate
	accounts_before = SSeconomy.bank_accounts.Copy()
	var/datum/bank_account/treasury = SSeconomy.treasury()
	saved_treasury_audit = list(treasury.audit_outflows, treasury.audit_watch, treasury.audit_pool)
	treasury.audit_outflows = null
	treasury.audit_watch = null
	treasury.audit_pool = null

/datum/unit_test/economy_ui_treasury/Destroy()
	for(var/datum/bank_account/opened as anything in SSeconomy.bank_accounts - accounts_before)
		qdel(opened)
	for(var/id in saved_balances)
		var/datum/economy_department/department = SSeconomy.departments[id]
		econ_test_set_balance(department.account, saved_balances[id])
	QDEL_LIST(SSeconomy.treasury_requests)
	SSeconomy.treasury_requests = saved_treasury_requests
	SSeconomy.tax_rate = saved_tax_rate
	var/datum/bank_account/treasury = SSeconomy.treasury()
	treasury.audit_outflows = saved_treasury_audit[1]
	treasury.audit_watch = saved_treasury_audit[2]
	treasury.audit_pool = saved_treasury_audit[3]
	return ..()

/// Человек со своим счётом отдела; с job_type - по должности и её доступу, иначе с заданными доступами на ID.
/datum/unit_test/economy_ui_treasury/proc/make_person(department_id, list/access, job_type)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new("econ_test_treasury_[department_id]")
	account.department_id = department_id
	account.pay_grade = PAY_GRADE_EASY
	account.bind_owner(person)
	person.account_id = account.account_id
	if(job_type)
		var/datum/job/job = SSjob.GetJobType(job_type)
		access = job.access.Copy()
		person.mind_initialize()
		person.mind.assigned_role = job.title
	if(access)
		econ_test_badge(person, access)
	return person

/datum/unit_test/economy_ui_treasury/proc/press(mob/living/user, datum/host, action, list/params = list())
	var/datum/tgui/window = allocate(/datum/tgui, user, host, "NtosTreasury")
	window.status = UI_INTERACTIVE
	usr = user
	host.ui_act(action, params, window)
	usr = null
	var/datum/computer_file/program/treasury/program = host
	var/obj/machinery/computer/account_database/console = host
	if(istype(console))
		program = console.program
	return program.messages[REF(user)]

/// Клерк и мостовой офицер с доступом ГП казной не управляют; ГП по должности и капитан по ID - управляют, налог не выше потолка.
/datum/unit_test/economy_ui_treasury/rights/Run()
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/mob/living/carbon/human/clerk = make_person(ACCOUNT_CIV)
	var/mob/living/carbon/human/bridge_officer = make_person(ACCOUNT_SEC, list(ACCESS_HOP, ACCESS_HEADS))
	var/mob/living/carbon/human/hop = make_person(ACCOUNT_SRV, job_type = /datum/job/hop)
	var/mob/living/carbon/human/captain = make_person(ACCOUNT_SEC, list(ACCESS_CAPTAIN))
	SSeconomy.tax_rate = 5
	var/refusal = press(clerk, console, "set_tax", list("rate" = "25"))
	TEST_ASSERT_EQUAL(SSeconomy.tax_rate, 5, "Клерк налог не меняет")
	TEST_ASSERT_EQUAL(refusal, "Казной управляют только капитан и глава персонала.", "Отказ объяснён")
	press(bridge_officer, console, "set_tax", list("rate" = "25"))
	TEST_ASSERT_EQUAL(SSeconomy.tax_rate, 5, "Доступ ГП на ID без должности не даёт прав")
	press(hop, console, "set_tax", list("rate" = "25"))
	TEST_ASSERT_EQUAL(SSeconomy.tax_rate, min(25, SSeconomy.settings.tax_max), "ГП меняет налог")
	press(captain, console, "set_tax", list("rate" = "1000"))
	TEST_ASSERT_EQUAL(SSeconomy.tax_rate, SSeconomy.settings.tax_max, "Налог не выше потолка")
	var/garbage = press(captain, console, "set_tax", list("rate" = "много"))
	TEST_ASSERT_EQUAL(garbage, "Неверная ставка.", "Строка вместо числа")
	TEST_ASSERT_EQUAL(SSeconomy.tax_rate, SSeconomy.settings.tax_max, "Мусор налог не меняет")
	var/list/clerk_data = console.program.treasury_data(clerk)
	TEST_ASSERT(!clerk_data["can_manage"], "Клерк видит казну только для чтения")
	TEST_ASSERT(!("accounts" in clerk_data), "Клерку не видны счета экипажа")
	var/list/hop_data = console.program.treasury_data(hop)
	TEST_ASSERT(hop_data["can_manage"], "ГП управляет")
	TEST_ASSERT_EQUAL(length(hop_data["accounts"]), length(SSeconomy.bank_accounts), "ГП видит все личные счета")

/// Перевод из казны в бюджет и между бюджетами: только отделам, сумма из строки, без новых денег, без казны как отдела.
/datum/unit_test/economy_ui_treasury/budgets/Run()
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/mob/living/carbon/human/captain = make_person(ACCOUNT_SEC, list(ACCESS_CAPTAIN))
	var/mob/living/carbon/human/clerk = make_person(ACCOUNT_CIV)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/economy_department/science = SSeconomy.get_department(ACCOUNT_SCI)
	econ_test_set_balance(treasury, 1000)
	econ_test_set_balance(medical.account, 0)
	econ_test_set_balance(science.account, 0)
	var/minted = SSeconomy.ledger.minted
	var/burned = SSeconomy.ledger.burned
	press(clerk, console, "fund", list("department" = ACCOUNT_MED, "amount" = "400"))
	TEST_ASSERT_EQUAL(medical.account.account_balance, 0, "Клерк не переводит из казны")
	press(captain, console, "fund", list("department" = ACCOUNT_MED, "amount" = "400"))
	TEST_ASSERT_EQUAL(medical.account.account_balance, 400, "Медицина получила из казны")
	TEST_ASSERT_EQUAL(treasury.account_balance, 600, "Казна списана")
	var/short = press(captain, console, "fund", list("department" = ACCOUNT_MED, "amount" = 5000))
	TEST_ASSERT_EQUAL(short, "В казне не хватает денег.", "Больше казны не переводится")
	for(var/bad_amount in list(-100, 0, "abc", null))
		press(captain, console, "fund", list("department" = ACCOUNT_SCI, "amount" = bad_amount))
	press(captain, console, "fund", list("department" = ACCOUNT_CMD, "amount" = 100))
	press(captain, console, "fund", list("department" = "NOPE", "amount" = 100))
	TEST_ASSERT_EQUAL(treasury.account_balance, 600, "Неверные переводы казну не трогают")
	press(captain, console, "move_budget", list("from" = ACCOUNT_MED, "to" = ACCOUNT_SCI, "amount" = "150"))
	TEST_ASSERT_EQUAL(medical.account.account_balance, 250, "Списано с медицины")
	TEST_ASSERT_EQUAL(science.account.account_balance, 150, "Зачислено науке")
	press(captain, console, "move_budget", list("from" = ACCOUNT_MED, "to" = ACCOUNT_MED, "amount" = "50"))
	press(captain, console, "move_budget", list("from" = ACCOUNT_CMD, "to" = ACCOUNT_SCI, "amount" = "50"))
	press(captain, console, "move_budget", list("from" = ACCOUNT_MED, "to" = ACCOUNT_SCI, "amount" = "9999"))
	TEST_ASSERT_EQUAL(medical.account.account_balance, 250, "Неверные переводы бюджеты не трогают")
	TEST_ASSERT_EQUAL(treasury.account_balance, 600, "Казна как отдел не выбирается")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted, "Переводы не печатают деньги")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned, burned, "Переводы не сжигают деньги")

/// Запрос главы в казну: одобрение переводит сумму, uid и решение приходят строками, без денег в казне запрос ждёт, решённый не меняется.
/datum/unit_test/economy_ui_treasury/requests/Run()
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/mob/living/carbon/human/hop = make_person(ACCOUNT_SRV, job_type = /datum/job/hop)
	var/mob/living/carbon/human/chief = make_person(ACCOUNT_ENG, list(ACCESS_CE))
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	econ_test_set_balance(engineering.account, 0)
	econ_test_set_balance(treasury, 300)
	var/datum/econ_request/treasury/first = engineering.request_treasury(500, "Ремонт", chief)
	var/datum/econ_request/treasury/second = engineering.request_treasury(100, "Лампы", chief)
	TEST_ASSERT(first && second, "Запросы поданы")
	press(chief, console, "resolve_request", list("uid" = "[second.uid]", "approve" = 1))
	TEST_ASSERT_EQUAL(second.status, ECON_REQUEST_PENDING, "Глава отдела сам себе не одобряет")
	var/list/data = console.program.treasury_data(hop)
	var/list/requests = data["requests"]
	TEST_ASSERT_EQUAL(length(requests), 2, "Запросы видны в казне")
	var/list/entry = requests[1]
	TEST_ASSERT_EQUAL(entry["department_name"], engineering.name, "Название отдела в запросе")
	var/short = press(hop, console, "resolve_request", list("uid" = "[first.uid]", "approve" = 1))
	TEST_ASSERT_EQUAL(first.status, ECON_REQUEST_PENDING, "Без денег запрос ждёт")
	TEST_ASSERT_EQUAL(short, "В казне не хватает денег: запрос №[first.uid] ждёт решения.", "Отказ объяснён")
	press(hop, console, "resolve_request", list("uid" = "[second.uid]", "approve" = "1"))
	TEST_ASSERT_EQUAL(second.status, ECON_REQUEST_APPROVED, "ГП одобрил")
	TEST_ASSERT_EQUAL(engineering.account.account_balance, 100, "Деньги в бюджете отдела")
	TEST_ASSERT_EQUAL(treasury.account_balance, 200, "Деньги из казны")
	var/repeat = press(hop, console, "resolve_request", list("uid" = "[second.uid]", "approve" = 0))
	TEST_ASSERT_EQUAL(second.status, ECON_REQUEST_APPROVED, "Решённый запрос не меняется")
	TEST_ASSERT_EQUAL(repeat, "Запрос не найден или уже решён.", "Повтор объяснён")
	var/garbage = press(hop, console, "resolve_request", list("uid" = "[first.uid]", "approve" = "да"))
	TEST_ASSERT_EQUAL(garbage, "Неверное решение.", "Решение не числом отвергнуто")
	press(hop, console, "resolve_request", list("uid" = "[first.uid]", "approve" = 0))
	TEST_ASSERT_EQUAL(first.status, ECON_REQUEST_DENIED, "ГП отклонил")
	TEST_ASSERT_EQUAL(treasury.account_balance, 200, "Отказ казну не трогает")

/// Счёт открывается из казны с бумагой; грейд, отдел и блокировка меняются у чужого счёта экипажа, свой и внестанционный счёт не меняются.
/datum/unit_test/economy_ui_treasury/accounts/Run()
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/mob/living/carbon/human/hop = make_person(ACCOUNT_SRV, job_type = /datum/job/hop)
	var/mob/living/carbon/human/worker = make_person(ACCOUNT_CIV)
	var/datum/bank_account/own = econ_account_of(hop)
	var/datum/bank_account/member = econ_account_of(worker)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	econ_test_set_balance(treasury, 1000)
	var/minted = SSeconomy.ledger.minted
	var/list/before = SSeconomy.bank_accounts.Copy()
	var/broke = press(hop, console, "open_account", list("holder" = "Иван", "funds" = "5000"))
	TEST_ASSERT_EQUAL(broke, "В казне не хватает денег на начальный взнос.", "Взнос больше казны")
	TEST_ASSERT_EQUAL(length(SSeconomy.bank_accounts - before), 0, "Счёт без денег в казне не открыт")
	press(hop, console, "open_account", list("holder" = "<b>Иван</b> Петров", "funds" = "300"))
	var/list/opened_list = SSeconomy.bank_accounts - before
	TEST_ASSERT_EQUAL(length(opened_list), 1, "Счёт открыт")
	var/datum/bank_account/opened = opened_list[1]
	TEST_ASSERT_EQUAL(opened.account_holder, "Иван Петров", "Имя очищено от разметки")
	TEST_ASSERT_EQUAL(opened.account_balance, 300, "Начальный взнос")
	TEST_ASSERT_EQUAL(treasury.account_balance, 700, "Взнос из казны")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted, "Открытие счёта не печатает деньги")
	var/obj/item/paper/notice = locate() in hop.held_items
	TEST_ASSERT_NOTNULL(notice, "Бумага со счётом в руке ГП")
	allocated += notice
	TEST_ASSERT(findtext(notice.get_raw_text(), "[opened.account_id]"), "На бумаге номер счёта")
	press(hop, console, "set_grade", list("number" = "[member.account_id]", "grade" = PAY_GRADE_HARD))
	TEST_ASSERT_EQUAL(member.pay_grade, PAY_GRADE_HARD, "Грейд счёта")
	press(hop, console, "set_grade", list("number" = "[member.account_id]", "grade" = "god"))
	TEST_ASSERT_EQUAL(member.pay_grade, PAY_GRADE_HARD, "Неизвестный грейд не ставится")
	var/self = press(hop, console, "set_grade", list("number" = "[own.account_id]", "grade" = PAY_GRADE_COMMAND))
	TEST_ASSERT_EQUAL(own.pay_grade, PAY_GRADE_EASY, "Свой оклад не меняется")
	TEST_ASSERT_EQUAL(self, "Свой счёт так менять нельзя.", "Отказ себе объяснён")
	var/unowned = press(hop, console, "set_grade", list("number" = "[opened.account_id]", "grade" = PAY_GRADE_EASY))
	TEST_ASSERT_NULL(opened.pay_grade, "Счёт без владельца на смене не ставится на оклад")
	TEST_ASSERT_EQUAL(unowned, "Оклад назначается только счёту члена экипажа.", "Отказ объяснён")
	member.owed_wages = 40
	member.wage_bonus = 10
	press(hop, console, "set_department", list("number" = "[member.account_id]", "department" = ACCOUNT_ENG))
	TEST_ASSERT_EQUAL(member.department_id, ACCOUNT_ENG, "Отдел счёта")
	TEST_ASSERT_EQUAL(member.owed_wages, 0, "Долг прежнего отдела снят")
	TEST_ASSERT_EQUAL(member.wage_bonus, 0, "Надбавка прежнего главы снята")
	press(hop, console, "set_department", list("number" = "[member.account_id]", "department" = ACCOUNT_CMD))
	TEST_ASSERT_EQUAL(member.department_id, ACCOUNT_ENG, "Казна не платит зарплату")
	press(hop, console, "toggle_block", list("number" = "[member.account_id]"))
	TEST_ASSERT(!member.transferable, "Счёт заблокирован")
	press(hop, console, "toggle_block", list("number" = "[member.account_id]"))
	TEST_ASSERT(member.transferable, "Счёт разблокирован")
	press(hop, console, "toggle_block", list("number" = "[own.account_id]"))
	TEST_ASSERT(own.transferable, "Свой счёт не блокируется")

/// Окно открывает счёт с историей и делом аудита, печатает выписку и сводку; поля правил - ровно ожидаемые, без порогов аудита.
/datum/unit_test/economy_ui_treasury/details/Run()
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/mob/living/carbon/human/hop = make_person(ACCOUNT_SRV, job_type = /datum/job/hop)
	var/mob/living/carbon/human/worker = make_person(ACCOUNT_CIV)
	var/datum/bank_account/member = econ_account_of(worker)
	member.credit(77, ECON_ADMIN)
	press(hop, console, "select_account", list("number" = "[member.account_id]"))
	var/list/data = console.program.treasury_data(hop)
	var/list/details = data["account"]
	TEST_ASSERT_NOTNULL(details, "Счёт открыт в окне")
	TEST_ASSERT_EQUAL(details["number"], member.account_id, "Тот самый счёт")
	var/list/history = details["history"]
	var/list/last = history[length(history)]
	TEST_ASSERT_EQUAL(last["amount"], 77, "История операций")
	press(hop, console, "print_account", list("number" = "[member.account_id]"))
	var/obj/item/paper/report = locate() in hop.held_items
	TEST_ASSERT_NOTNULL(report, "Выписка напечатана")
	allocated += report
	TEST_ASSERT(findtext(report.get_raw_text(), member.account_holder), "В выписке владелец")
	var/busy = press(hop, console, "print_summary")
	TEST_ASSERT_EQUAL(busy, "Принтер ещё печатает.", "Печать не чаще раза в несколько секунд")
	COOLDOWN_RESET(console.program, print_cooldown)
	qdel(report)
	press(hop, console, "print_summary")
	var/obj/item/paper/summary = locate() in hop.held_items
	TEST_ASSERT_NOTNULL(summary, "Сводка напечатана")
	allocated += summary
	var/list/static_data = console.program.treasury_static_data()
	var/static/list/expected = list("tax_max", "grades", "holder_max", "economy_minutes", "wage_minutes", "wage_floor", "owed_cap", "tax_nt_share", "cap_share", "grace_minutes", "treasury_max", "treasury_pending_max", "stall_fee", "stall_minutes", "rich_per_capita", "poor_per_capita", "audit_rights", "unowned_max")
	TEST_ASSERT_EQUAL(length(static_data), length(expected), "Лишние или недостающие поля правил")
	for(var/key in expected)
		TEST_ASSERT(key in static_data, "Нет поля [key]")
	var/list/grades = static_data["grades"]
	TEST_ASSERT_EQUAL(length(grades), length(GLOB.econ_pay_grade_names), "Все грейды в окне")

/// Консоль создаёт и удаляет свою программу; ГП и капитан получают казну в КПК; дата для бумаг станции выставлена без консоли.
/datum/unit_test/economy_ui_treasury/console/Run()
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/datum/computer_file/program/treasury/inner = console.program
	TEST_ASSERT_NOTNULL(inner, "Программа консоли")
	TEST_ASSERT(istype(console.circuit, /obj/item/circuitboard/computer/account_database), "Плата консоли")
	qdel(console)
	TEST_ASSERT(QDELETED(inner), "Программа удалена с консолью")
	for(var/pda_type in list(/obj/item/modular_computer/pda/heads/captain, /obj/item/modular_computer/pda/heads/hop))
		var/obj/item/modular_computer/pda/pda = allocate(pda_type)
		TEST_ASSERT_NOTNULL(locate(/datum/computer_file/program/treasury) in pda.get_all_files(), "[pda_type] без казны")
	TEST_ASSERT(length(GLOB.current_date_string), "Дата станции для бумаг")
	var/mob/living/carbon/human/hop = make_person(ACCOUNT_SRV, job_type = /datum/job/hop)
	var/obj/item/modular_computer/pda/heads/hop/pda = allocate(/obj/item/modular_computer/pda/heads/hop)
	hop.put_in_hands(pda)
	var/datum/computer_file/program/treasury/app = locate() in pda.get_all_files()
	TEST_ASSERT_NOTNULL(app, "Казна в КПК ГП")
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	econ_test_set_balance(SSeconomy.treasury(), 100)
	econ_test_set_balance(service.account, 0)
	press(hop, app, "fund", list("department" = ACCOUNT_SRV, "amount" = 100))
	TEST_ASSERT_EQUAL(service.account.account_balance, 100, "ГП переводит из КПК")

/// Станционный прилавок виден в казне с арендатором и сроком.
/datum/unit_test/economy_ui_treasury/stalls/Run()
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/mob/living/carbon/human/hop = make_person(ACCOUNT_SRV, job_type = /datum/job/hop)
	var/mob/living/carbon/human/renter = make_person(ACCOUNT_CIV)
	var/datum/bank_account/renter_account = econ_account_of(renter)
	var/obj/machinery/vending/custom/stall = allocate(/obj/machinery/vending/custom)
	stall.make_rentable()
	stall.set_renter(renter_account, world.time + 10 MINUTES)
	var/list/data = console.program.treasury_data(hop)
	var/list/found
	for(var/list/entry as anything in data["stalls"])
		if(entry["renter"] == renter_account.account_holder)
			found = entry
	TEST_ASSERT_NOTNULL(found, "Прилавок с арендатором в казне")
	TEST_ASSERT(found["active"], "Аренда идёт")
	TEST_ASSERT_EQUAL(found["until"], stall.rent_end_text(), "Срок аренды")
	stall.set_renter(null, 0)

/// Взносы из казны ниже порога на разные новые счета без владельца складываются в одно дело оттока.
/datum/unit_test/economy_ui_treasury/pooled_siphon
	var/list/saved_flags

/datum/unit_test/economy_ui_treasury/pooled_siphon/New()
	. = ..()
	saved_flags = SSeconomy.audit_flags
	SSeconomy.audit_flags = list()

/datum/unit_test/economy_ui_treasury/pooled_siphon/Destroy()
	QDEL_LIST(SSeconomy.audit_flags)
	SSeconomy.audit_flags = saved_flags
	return ..()

/datum/unit_test/economy_ui_treasury/pooled_siphon/Run()
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/mob/living/carbon/human/hop = make_person(ACCOUNT_SRV, job_type = /datum/job/hop)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/part = round(SSeconomy.settings.audit_bonus_threshold * 0.4)
	econ_test_set_balance(treasury, part * 3)
	for(var/i in 1 to 3)
		COOLDOWN_RESET(console.program, print_cooldown)
		press(hop, console, "open_account", list("holder" = "Пустой [i]", "funds" = "[part]"))
		for(var/obj/item/paper/notice in hop.held_items)
			qdel(notice)
		if(i < 3)
			TEST_ASSERT_EQUAL(length(SSeconomy.flags_for(treasury)), 0, "Взнос [i] ниже порога не помечен")
	TEST_ASSERT_EQUAL(treasury.account_balance, 0, "Все три счёта открыты")
	var/list/flags = SSeconomy.flags_for(treasury)
	TEST_ASSERT_EQUAL(length(flags), 1, "Три взноса на разные счета без владельца - одно дело")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT_EQUAL(flag.kind, AUDIT_FLAG_BUDGET_SIPHON, "Дело оттока")
	TEST_ASSERT_EQUAL(flag.amount, part * 3, "Сумма дела - все взносы")

/datum/unit_test/economy_ui_treasury/orbital
	abstract_type = /datum/unit_test/economy_ui_treasury/orbital
	var/datum/orbital_objective/saved_objective
	var/saved_cargo_points
	var/saved_cargo_mult

/datum/unit_test/economy_ui_treasury/orbital/New()
	. = ..()
	saved_objective = SSorbits.current_objective
	saved_cargo_points = GLOB.cargo_objective_points
	saved_cargo_mult = SSeconomy.settings.orbital_cargo_mult

/datum/unit_test/economy_ui_treasury/orbital/Destroy()
	SSorbits.current_objective = saved_objective
	GLOB.cargo_objective_points = saved_cargo_points
	SSeconomy.settings.orbital_cargo_mult = saved_cargo_mult
	return ..()

/// Орбитальная доля, эмиссионная раздача всем счетам, не достаётся пустому счёту, открытому из казны.
/datum/unit_test/economy_ui_treasury/orbital/needs_owner/Run()
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/mob/living/carbon/human/hop = make_person(ACCOUNT_SRV, job_type = /datum/job/hop)
	var/datum/bank_account/crew = econ_account_of(hop)
	econ_test_set_balance(SSeconomy.treasury(), 0)
	var/list/before = SSeconomy.bank_accounts.Copy()
	press(hop, console, "open_account", list("holder" = "Пустой счёт", "funds" = "0"))
	var/list/opened_list = SSeconomy.bank_accounts - before
	TEST_ASSERT_EQUAL(length(opened_list), 1, "Пустой счёт открыт")
	var/datum/bank_account/empty = opened_list[1]
	for(var/obj/item/paper/notice in hop.held_items)
		qdel(notice)
	var/crew_before = crew.account_balance
	var/datum/orbital_objective/objective = new
	objective.payout = 1000
	SSorbits.current_objective = objective
	objective.complete_objective()
	TEST_ASSERT_EQUAL(empty.account_balance, 0, "Пустой счёт без орбитальной доли")
	TEST_ASSERT(crew.account_balance > crew_before, "Член экипажа получил орбитальную долю")

/// Доля экипажа в орбитальном задании облагается налогом и пишется своей причиной, снабжение получает долю награды из настроек.
/datum/unit_test/economy_ui_treasury/orbital/taxed/Run()
	var/mob/living/carbon/human/hop = make_person(ACCOUNT_SRV, job_type = /datum/job/hop)
	var/datum/bank_account/crew = econ_account_of(hop)
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	SSeconomy.tax_rate = 10
	SSeconomy.settings.orbital_cargo_mult = 0.5
	var/cargo_before = cargo.account_balance
	var/list/history = crew.transaction_history.Copy()
	var/datum/orbital_objective/objective = new
	objective.payout = 100000
	SSorbits.current_objective = objective
	objective.complete_objective()
	TEST_ASSERT_EQUAL(cargo.account_balance - cargo_before, 50000, "Снабжению доля награды из orbital_cargo_mult")
	var/paid = 0
	var/taxed = FALSE
	for(var/datum/transaction/entry as anything in crew.transaction_history - history)
		if(entry.reason == ECON_ORBITAL)
			paid += entry.amount
		if(entry.reason == ECON_TAX || entry.reason == ECON_TAX_NT)
			taxed = TRUE
	TEST_ASSERT(paid > 0, "Доля экипажа записана причиной орбитального задания")
	TEST_ASSERT(taxed, "С доли экипажа удержан налог")

/// Казна держит не больше treasury_unowned_accounts_max счетов без владельца; отрицательный лимит в настройках отвергается.
/datum/unit_test/economy_ui_treasury/unowned_limit
	var/saved_limit

/datum/unit_test/economy_ui_treasury/unowned_limit/New()
	. = ..()
	saved_limit = SSeconomy.settings.treasury_unowned_accounts_max

/datum/unit_test/economy_ui_treasury/unowned_limit/Destroy()
	SSeconomy.settings.treasury_unowned_accounts_max = saved_limit
	return ..()

/datum/unit_test/economy_ui_treasury/unowned_limit/Run()
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/mob/living/carbon/human/hop = make_person(ACCOUNT_SRV, job_type = /datum/job/hop)
	SSeconomy.settings.treasury_unowned_accounts_max = SSeconomy.unowned_treasury_accounts() + 1
	var/list/before = SSeconomy.bank_accounts.Copy()
	press(hop, console, "open_account", list("holder" = "Первый", "funds" = "0"))
	TEST_ASSERT_EQUAL(length(SSeconomy.bank_accounts - before), 1, "Счёт в пределах лимита открыт")
	for(var/obj/item/paper/notice in hop.held_items)
		qdel(notice)
	COOLDOWN_RESET(console.program, print_cooldown)
	var/refusal = press(hop, console, "open_account", list("holder" = "Второй", "funds" = "0"))
	TEST_ASSERT_EQUAL(length(SSeconomy.bank_accounts - before), 1, "Сверх лимита счёт не открыт")
	TEST_ASSERT_EQUAL(refusal, "Из казны уже открыто [SSeconomy.settings.treasury_unowned_accounts_max] счетов, не принадлежащих никому из экипажа: больше открыть нельзя.", "Отказ объяснён")
	TEST_ASSERT_NULL(SSeconomy.open_account("Третий", 0), "Лимит держит и прямой вызов")
	TEST_ASSERT_NOTNULL(SSeconomy.settings.check_value("treasury_unowned_accounts_max", -1), "Отрицательный лимит отвергается")
