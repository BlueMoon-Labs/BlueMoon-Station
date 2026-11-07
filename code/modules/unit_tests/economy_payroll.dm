/datum/unit_test/economy_payroll
	abstract_type = /datum/unit_test/economy_payroll
	var/datum/bank_account/worker
	var/datum/economy_department/department
	var/saved_budget
	var/saved_tax

/datum/unit_test/economy_payroll/proc/setup_worker(budget)
	department = SSeconomy.get_department(ACCOUNT_SRV)
	saved_budget = department.account.account_balance
	saved_tax = SSeconomy.tax_rate
	SSeconomy.tax_rate = 0
	department.account.debit(saved_budget, ECON_ADMIN)
	if(budget)
		department.account.credit(budget, ECON_ADMIN)
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	worker = new("econ_test_worker")
	worker.department_id = ACCOUNT_SRV
	worker.pay_grade = PAY_GRADE_EASY
	worker.bind_owner(owner)
	worker.away_since = 0

/datum/unit_test/economy_payroll/Destroy()
	if(department)
		department.account.debit(max(department.account.account_balance, 0), ECON_ADMIN)
		department.account.credit(saved_budget, ECON_ADMIN)
		SSeconomy.tax_rate = saved_tax
	QDEL_NULL(worker)
	return ..()

/// Зарплата идёт из бюджета отдела по грейду с надбавкой.
/datum/unit_test/economy_payroll/from_budget/Run()
	setup_worker(10000)
	worker.wage_bonus = 20
	var/expected = round(SSeconomy.settings.wages[PAY_GRADE_EASY] * 1.2)
	var/paid = worker.payday()
	TEST_ASSERT_EQUAL(paid, expected, "Сумма зарплаты")
	TEST_ASSERT_EQUAL(worker.account_balance, expected, "Баланс сотрудника")

/// Пустой бюджет: долг копится, NT платит минимум, долг гасится при поступлениях.
/datum/unit_test/economy_payroll/owed_and_floor/Run()
	setup_worker(0)
	var/wage = SSeconomy.settings.wages[PAY_GRADE_EASY]
	worker.payday()
	TEST_ASSERT_EQUAL(worker.account_balance, SSeconomy.settings.wage_floor, "Гарантированный минимум")
	TEST_ASSERT_EQUAL(worker.owed_wages, wage, "Долг отдела")
	department.account.credit(wage * 3, ECON_ADMIN)
	worker.payday()
	TEST_ASSERT_EQUAL(worker.owed_wages, 0, "Долг погашен")
	TEST_ASSERT_EQUAL(worker.account_balance, SSeconomy.settings.wage_floor + wage * 2, "Долг и новая зарплата")

/// Налог: доля NT сгорает, остальное уходит в казну, в истории отдельными строками.
/datum/unit_test/economy_payroll/tax/Run()
	setup_worker(10000)
	SSeconomy.tax_rate = 10
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/treasury_before = treasury.account_balance
	var/burned_before = SSeconomy.ledger.by_reason[ECON_TAX_NT]
	var/wage = SSeconomy.settings.wages[PAY_GRADE_EASY]
	var/tax = round(wage / 10)
	var/nt_part = round(tax * SSeconomy.settings.tax_nt_share / 100)
	worker.payday()
	TEST_ASSERT_EQUAL(SSeconomy.ledger.by_reason[ECON_TAX_NT] - burned_before, nt_part, "Доля NT с налога сгорела")
	TEST_ASSERT_EQUAL(treasury.account_balance - treasury_before, tax - nt_part, "Остальное в казне")
	TEST_ASSERT_EQUAL(worker.account_balance, wage - round(wage / 10), "Зарплата за вычетом налога")
	var/datum/transaction/last_entry = worker.transaction_history[length(worker.transaction_history)]
	TEST_ASSERT_EQUAL(last_entry.reason, ECON_TAX, "Налог отдельной строкой в истории")

/// Владелец без клиента дольше порога - счёт спит и зарплату не получает.
/datum/unit_test/economy_payroll/dormant/Run()
	setup_worker(10000)
	worker.away_since = world.time - (SSeconomy.settings.dormant_after_minutes MINUTES) - 1
	worker.update_dormancy()
	TEST_ASSERT_EQUAL(worker.state, ACCOUNT_DORMANT, "Счёт уснул")
	TEST_ASSERT_EQUAL(worker.payday(), 0, "Спящему не платят")

/// Замороженный счёт копит зарплату долгом отдела и получает её после разморозки.
/datum/unit_test/economy_payroll/frozen/Run()
	setup_worker(10000)
	worker.state = ACCOUNT_FROZEN
	worker.payday()
	var/wage = SSeconomy.settings.wages[PAY_GRADE_EASY]
	TEST_ASSERT_EQUAL(worker.account_balance, 0, "Замороженному не платят")
	TEST_ASSERT_EQUAL(worker.owed_wages, wage, "Зарплата ждёт")
	worker.state = ACCOUNT_ACTIVE
	worker.payday()
	TEST_ASSERT_EQUAL(worker.account_balance, wage * 2, "Выплачено после разморозки")

/// Тик SSeconomy с выплатой проходит по личным счетам: спящий без клиента не получает, приписанный получает.
/datum/unit_test/economy_payroll/run_payroll/Run()
	setup_worker(10000)
	var/datum/bank_account/sleeper = new("econ_test_sleeper")
	sleeper.department_id = ACCOUNT_SRV
	sleeper.pay_grade = PAY_GRADE_EASY
	sleeper.bind_owner(allocate(/mob/living/carbon/human))
	sleeper.away_since = world.time - (SSeconomy.settings.dormant_after_minutes MINUTES) - 1
	SSeconomy.run_payroll()
	var/sleeper_balance = sleeper.account_balance
	var/sleeper_state = sleeper.state
	qdel(sleeper)
	TEST_ASSERT_EQUAL(sleeper_state, ACCOUNT_DORMANT, "Спящий уснул на выплате")
	TEST_ASSERT_EQUAL(sleeper_balance, 0, "Спящему не заплатили")
	TEST_ASSERT_EQUAL(worker.account_balance, SSeconomy.settings.wages[PAY_GRADE_EASY], "Сотруднику заплатили")

/// Гарантированный минимум NT не облагается налогом.
/datum/unit_test/economy_payroll/floor_untaxed/Run()
	setup_worker(0)
	SSeconomy.tax_rate = 10
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/treasury_before = treasury.account_balance
	worker.payday()
	TEST_ASSERT_EQUAL(worker.account_balance, SSeconomy.settings.wage_floor, "Минимум на руки")
	TEST_ASSERT_EQUAL(treasury.account_balance, treasury_before, "С минимума взят налог")

/// После гиба или клонирования счёт находит новое тело по разуму и просыпается, когда владелец в игре.
/datum/unit_test/economy_payroll/new_body/Run()
	setup_worker(10000)
	var/mob/living/carbon/human/old_body = allocate(/mob/living/carbon/human)
	old_body.mind_initialize()
	worker.bind_owner(old_body)
	worker.away_since = world.time - (SSeconomy.settings.dormant_after_minutes MINUTES) - 1
	worker.update_dormancy()
	TEST_ASSERT_EQUAL(worker.state, ACCOUNT_DORMANT, "Счёт без клиента уснул")
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human)
	old_body.mind.transfer_to(new_body)
	qdel(old_body)
	new_body.mock_client = new /datum/client_interface()
	worker.update_dormancy()
	var/datum/weakref/bound = worker.owner_ref
	var/woke_state = worker.state
	var/paid = worker.payday()
	new_body.mock_client = null
	TEST_ASSERT(bound.resolve() == new_body, "Счёт не перепривязан к новому телу")
	TEST_ASSERT_EQUAL(woke_state, ACCOUNT_ACTIVE, "Счёт не проснулся в новом теле")
	TEST_ASSERT_EQUAL(paid, SSeconomy.settings.wages[PAY_GRADE_EASY], "Зарплата новому телу")

/// Смена должности и увольнение в консоли ID меняют грейд и отдел счёта.
/datum/unit_test/economy_payroll/id_console/Run()
	setup_worker(10000)
	var/obj/machinery/modular_computer/console/preset/id/console = allocate(/obj/machinery/modular_computer/console/preset/id)
	var/obj/item/modular_computer/processor/cpu = console.cpu
	var/datum/computer_file/program/card_mod/program = cpu.find_file_by_name("plexagonidwriter")
	TEST_ASSERT_NOTNULL(program, "Нет программы ID-консоли")
	program.computer = cpu
	var/obj/item/card/id/head_card = allocate(/obj/item/card/id, console.loc)
	head_card.access = list(ACCESS_CHANGE_IDS)
	var/obj/item/card/id/target_card = allocate(/obj/item/card/id, console.loc)
	target_card.registered_account = worker
	var/obj/item/computer_hardware/card_slot/main_slot = cpu.all_components[MC_CARD]
	var/obj/item/computer_hardware/card_slot/target_slot = cpu.all_components[MC_CARD2]
	TEST_ASSERT(main_slot.try_insert(head_card), "Карта главы не вставлена")
	TEST_ASSERT(target_slot.try_insert(target_card), "Карта сотрудника не вставлена")
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	TEST_ASSERT(program.run_program(head), "Программа не запустилась")
	var/datum/tgui/window = allocate(/datum/tgui, head, program, program.tgui_id)
	window.status = UI_INTERACTIVE
	var/datum/job/engineer = SSjob.GetJob("Station Engineer")
	TEST_ASSERT(program.ui_act("PRG_assign", list("assign_target" = engineer.title), window), "Назначение не прошло")
	TEST_ASSERT_EQUAL(worker.pay_grade, econ_pay_grade(engineer.paycheck), "Грейд новой должности")
	TEST_ASSERT_EQUAL(worker.department_id, engineer.paycheck_department, "Отдел новой должности")
	TEST_ASSERT(program.ui_act("PRG_terminate", list(), window), "Увольнение не прошло")
	TEST_ASSERT_NULL(worker.pay_grade, "Уволенному оставлен грейд")
	TEST_ASSERT_NULL(worker.department_id, "Уволенный числится в отделе")
	var/floor = SSeconomy.settings.wage_floor
	TEST_ASSERT_EQUAL(worker.payday(), floor, "Уволенному не платят минимум NT")
	TEST_ASSERT_EQUAL(worker.account_balance, floor, "Уволенный получил не минимум NT")

/// Экипаж без отдела или без грейда получает минимум NT; казна честно говорит, что оклад не платится.
/datum/unit_test/economy_payroll/floor_without_department/Run()
	setup_worker(10000)
	var/floor = SSeconomy.settings.wage_floor
	worker.department_id = null
	TEST_ASSERT_EQUAL(worker.payday(), floor, "Грейд без отдела: не минимум NT")
	worker.pay_grade = null
	worker.department_id = ACCOUNT_SRV
	var/budget_before = department.account.account_balance
	TEST_ASSERT_EQUAL(worker.payday(), floor, "Отдел без грейда: не минимум NT")
	TEST_ASSERT_EQUAL(department.account.account_balance, budget_before, "Отдел без грейда платит")
	TEST_ASSERT_EQUAL(worker.account_balance, floor * 2, "Минимум NT не на счёте")
	worker.offstation = TRUE
	TEST_ASSERT_EQUAL(worker.payday(), 0, "Гост-роли без оклада платят минимум")
	worker.offstation = FALSE
	var/obj/machinery/computer/account_database/console = allocate(/obj/machinery/computer/account_database)
	var/mob/living/carbon/human/hop = allocate(/mob/living/carbon/human)
	hop.mind_initialize()
	var/datum/job/hop/hop_job = /datum/job/hop
	hop.mind.assigned_role = initial(hop_job.title)
	econ_test_badge(hop, list(ACCESS_HOP))
	usr = hop
	var/datum/tgui/window = allocate(/datum/tgui, hop, console, "NtosTreasury")
	window.status = UI_INTERACTIVE
	console.ui_act("set_department", list("number" = "[worker.account_id]", "department" = ACCOUNT_ENG), window)
	var/department_note = console.program.messages[REF(hop)]
	worker.department_id = null
	console.ui_act("set_grade", list("number" = "[worker.account_id]", "grade" = PAY_GRADE_EASY), window)
	var/grade_note = console.program.messages[REF(hop)]
	usr = null
	TEST_ASSERT(findtext(department_note, "Грейд не назначен") && findtext(department_note, "[floor] кр."), "Отдел без грейда обещает зарплату: [department_note]")
	TEST_ASSERT(findtext(grade_note, "отдел не назначен") && findtext(grade_note, "[floor] кр."), "Грейд без отдела обещает оклад: [grade_note]")

/// Долг по зарплате принадлежит отделу: перевод в другой отдел его обнуляет, в тот же - нет.
/datum/unit_test/economy_payroll/transfer_clears_owed/Run()
	setup_worker(0)
	var/datum/job/cook = SSjob.GetJob("Cook")
	var/datum/job/bartender = SSjob.GetJob("Bartender")
	var/datum/job/engineer = SSjob.GetJob("Station Engineer")
	worker.set_job(cook)
	worker.owed_wages = 100
	worker.set_job(bartender)
	TEST_ASSERT_EQUAL(worker.owed_wages, 100, "Долг сброшен при смене должности в том же отделе")
	worker.set_job(engineer)
	TEST_ASSERT_EQUAL(worker.department_id, engineer.paycheck_department, "Отдел новой должности")
	TEST_ASSERT_EQUAL(worker.owed_wages, 0, "Долг старого отдела перешёл в новый")

/// Должность с отделом, но без зарплаты не числит счёт в отделе.
/datum/unit_test/economy_payroll/unpaid_job_no_department/Run()
	setup_worker(0)
	var/datum/job/unpaid = allocate(/datum/job)
	unpaid.paycheck = 0
	unpaid.paycheck_department = ACCOUNT_SRV
	worker.set_job(unpaid)
	TEST_ASSERT_NULL(worker.pay_grade, "Грейд без зарплаты")
	TEST_ASSERT_NULL(worker.department_id, "Отдел без зарплаты")

/// Казна: создание счёта только из её денег.
/datum/unit_test/economy_treasury_open_account/Run()
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/before = treasury.account_balance
	var/datum/bank_account/opened = SSeconomy.open_account("econ_test_opened", 300)
	TEST_ASSERT_NOTNULL(opened, "Счёт открыт")
	TEST_ASSERT_EQUAL(opened.account_balance, 300, "Начальная сумма")
	TEST_ASSERT_EQUAL(before - treasury.account_balance, 300, "Списано с казны")
	var/datum/bank_account/too_rich = SSeconomy.open_account("econ_test_rich", treasury.account_balance + 1)
	qdel(opened)
	TEST_ASSERT_NULL(too_rich, "Больше казны не открыть")

/// Ставка налога не выходит за потолок из настроек, переводы казны не уходят в саму казну.
/datum/unit_test/economy_treasury_transfers/Run()
	var/saved_tax = SSeconomy.tax_rate
	SSeconomy.set_tax_rate(SSeconomy.settings.tax_max + 5)
	var/capped_tax = SSeconomy.tax_rate
	SSeconomy.tax_rate = saved_tax
	TEST_ASSERT_EQUAL(capped_tax, SSeconomy.settings.tax_max, "Ставка выше потолка")
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/economy_department/science = SSeconomy.get_department(ACCOUNT_SCI)
	TEST_ASSERT(!SSeconomy.treasury_transfer(command, 10), "Перевод из казны в казну")
	var/medical_before = medical.account.account_balance
	TEST_ASSERT(SSeconomy.treasury_transfer(medical, 10), "Перевод из казны отделу не прошёл")
	TEST_ASSERT_EQUAL(medical.account.account_balance - medical_before, 10, "Отдел получил перевод казны")
	TEST_ASSERT(SSeconomy.department_transfer(medical, science, 10), "Перевод между отделами не прошёл")
	TEST_ASSERT_EQUAL(medical.account.account_balance, medical_before, "Отдел отдал перевод")
	TEST_ASSERT(!SSeconomy.department_transfer(medical, medical, 10), "Перевод отдела самому себе")
	SSeconomy.department_transfer(science, command, 10)

/datum/unit_test/economy_job_starting_funds
	var/datum/bank_account/account

/datum/unit_test/economy_job_starting_funds/Destroy()
	QDEL_NULL(account)
	return ..()

/// Вход в раунд: счёт с грейдом и отделом должности, стартовые деньги по грейду, карта привязана по номеру.
/datum/unit_test/economy_job_starting_funds/Run()
	var/mob/living/carbon/human/crewman = allocate(/mob/living/carbon/human)
	var/datum/job/job = SSjob.GetJob("Botanist")
	job.equip(crewman, announce = FALSE)
	account = SSeconomy.find_account(crewman.account_id)
	TEST_ASSERT_NOTNULL(account, "Счёт должности не найден по номеру")
	TEST_ASSERT_EQUAL(account.pay_grade, econ_pay_grade(job.paycheck), "Грейд должности")
	TEST_ASSERT_EQUAL(account.department_id, job.paycheck_department, "Отдел должности")
	TEST_ASSERT(account.owner_ref?.resolve() == crewman, "Владелец не привязан")
	TEST_ASSERT_EQUAL(account.account_balance, account.wage_amount() * SSeconomy.settings.starting_paychecks, "Стартовые деньги")
	var/obj/item/card/id/card = crewman.wear_id
	TEST_ASSERT(istype(card), "Нет карты")
	TEST_ASSERT(card.registered_account == account, "Карта не привязана к счёту")

/datum/unit_test/economy_stowaway_no_wage
	var/datum/bank_account/account

/datum/unit_test/economy_stowaway_no_wage/Destroy()
	QDEL_NULL(account)
	return ..()

/// Безбилетник без зарплаты: ни подъёмных, ни минимума NT.
/datum/unit_test/economy_stowaway_no_wage/Run()
	var/mob/living/carbon/human/stowaway = allocate(/mob/living/carbon/human)
	var/datum/job/job = SSjob.GetJob("Stowaway")
	job.equip(stowaway, announce = FALSE)
	account = SSeconomy.find_account(stowaway.account_id)
	TEST_ASSERT_NOTNULL(account, "Счёт безбилетника не найден по номеру")
	TEST_ASSERT_NULL(account.pay_grade, "Безбилетнику выдан грейд")
	TEST_ASSERT_EQUAL(account.account_balance, 0, "Безбилетнику выданы подъёмные")
	TEST_ASSERT_EQUAL(account.payday(), 0, "Безбилетнику платят")
	TEST_ASSERT_EQUAL(account.account_balance, 0, "Безбилетник получил минимум NT")
