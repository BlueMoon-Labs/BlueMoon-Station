/datum/unit_test/economy_management
	abstract_type = /datum/unit_test/economy_management
	var/list/stashed_contracts
	var/list/saved_balances = list()
	var/saved_treasury_requests
	/// Перехваченные COMSIG_ECONOMY_MOVED: list(source, target, amount, reason, actor)
	var/list/moves = list()

/datum/unit_test/economy_management/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		saved_balances[id] = department.account.account_balance
	saved_treasury_requests = SSeconomy.treasury_requests
	SSeconomy.treasury_requests = list()
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_moved))

/datum/unit_test/economy_management/Destroy()
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	econ_test_restore_contracts(stashed_contracts)
	for(var/id in saved_balances)
		var/datum/economy_department/department = SSeconomy.departments[id]
		econ_test_set_balance(department.account, saved_balances[id])
	QDEL_LIST(SSeconomy.treasury_requests)
	SSeconomy.treasury_requests = saved_treasury_requests
	return ..()

/datum/unit_test/economy_management/proc/on_moved(datum/source, datum/bank_account/from, datum/bank_account/target, amount, reason, mob/actor)
	SIGNAL_HANDLER
	moves += list(list(from, target, amount, reason, actor))

/datum/unit_test/economy_management/proc/make_staff(department_id, list/access)
	var/mob/living/carbon/human/staff = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new("econ_test_[department_id]")
	account.department_id = department_id
	account.pay_grade = PAY_GRADE_EASY
	staff.account_id = account.account_id
	allocated += account
	if(access)
		var/obj/item/card/id/card = allocate(/obj/item/card/id)
		card.access = access
		staff.put_in_hands(card)
	return staff

/datum/unit_test/economy_management/proc/make_with_job(job_type)
	var/datum/job/job = SSjob.GetJobType(job_type)
	var/mob/living/carbon/human/staff = make_staff(job.paycheck_department, job.access.Copy())
	staff.mind_initialize()
	staff.mind.assigned_role = job.title
	return staff

/// Премия: только глава, только своему сотруднику, из бюджета отдела и не больше его.
/datum/unit_test/economy_management/bonus/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/mob/living/carbon/human/engineer = make_staff(ACCOUNT_ENG)
	var/datum/bank_account/member = econ_account_of(engineer)
	econ_test_set_balance(engineering.account, 500)
	var/tax = round(200 * SSeconomy.tax_rate / 100)
	TEST_ASSERT(engineering.pay_bonus(member, 200, chief), "Глава выдал премию")
	TEST_ASSERT_EQUAL(engineering.account.account_balance, 300, "Премия списана с бюджета")
	TEST_ASSERT_EQUAL(member.account_balance, 200 - tax, "Премия дошла за вычетом налога")
	TEST_ASSERT(member in engineering.staff_accounts(), "Сотрудник в списке отдела")
	TEST_ASSERT(!engineering.pay_bonus(member, 400, chief), "Премия больше бюджета не выдаётся")
	TEST_ASSERT(!engineering.pay_bonus(member, 100, engineer), "Не глава премию не выдаёт")
	TEST_ASSERT(!engineering.pay_bonus(member, -100, chief), "Отрицательная премия не выдаётся")
	member.offstation = TRUE
	TEST_ASSERT(!engineering.pay_bonus(member, 100, chief), "Внестанционному счёту премию не выдать")
	member.offstation = FALSE
	var/mob/living/carbon/human/medic = make_staff(ACCOUNT_MED)
	TEST_ASSERT(!engineering.pay_bonus(econ_account_of(medic), 100, chief), "Чужому сотруднику премию не выдать")
	TEST_ASSERT(!engineering.pay_bonus(SSeconomy.get_dep_account(ACCOUNT_MED), 100, chief), "Бюджету отдела премию не выдать")
	TEST_ASSERT_EQUAL(engineering.account.account_balance, 300, "Отказы не тронули бюджет")

/// Премия самому себе проходит и видна аудиту: причина ECON_BONUS, действующее лицо - владелец счёта-получателя.
/datum/unit_test/economy_management/bonus_to_self/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/datum/bank_account/own = econ_account_of(chief)
	econ_test_set_balance(engineering.account, 500)
	moves.Cut()
	TEST_ASSERT(engineering.pay_bonus(own, 100, chief), "Глава выписал премию себе")
	var/found = FALSE
	for(var/list/move as anything in moves)
		if(move[1] == engineering.account && move[2] == own && move[4] == ECON_BONUS && move[5] == chief)
			found = TRUE
	TEST_ASSERT(found, "Движение премии несёт счёт главы получателем и главу действующим лицом")

/// Надбавка: глава своему сотруднику, обрезается потолком, чужому нельзя.
/datum/unit_test/economy_management/wage_bonus/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/mob/living/carbon/human/engineer = make_staff(ACCOUNT_ENG)
	var/datum/bank_account/member = econ_account_of(engineer)
	var/base_wage = member.wage_amount()
	TEST_ASSERT(engineering.set_wage_bonus(member, 999, chief), "Надбавка выставлена")
	TEST_ASSERT_EQUAL(member.wage_bonus, SSeconomy.settings.max_wage_bonus, "Надбавка обрезана потолком")
	TEST_ASSERT_EQUAL(member.wage_amount(), round(base_wage * (100 + SSeconomy.settings.max_wage_bonus) / 100), "Зарплата выросла на надбавку")
	TEST_ASSERT(engineering.set_wage_bonus(member, -20, chief), "Отрицательная надбавка обнуляет")
	TEST_ASSERT_EQUAL(member.wage_bonus, 0, "Надбавка не уходит ниже нуля")
	TEST_ASSERT(!engineering.set_wage_bonus(member, 10, engineer), "Не глава надбавку не ставит")
	var/mob/living/carbon/human/medic = make_staff(ACCOUNT_MED)
	var/datum/bank_account/foreign = econ_account_of(medic)
	TEST_ASSERT(!engineering.set_wage_bonus(foreign, 10, chief), "Чужому сотруднику надбавку не ставить")
	TEST_ASSERT_EQUAL(foreign.wage_bonus, 0, "Чужая надбавка не изменилась")

/// Надбавка остаётся при переводе внутри отдела и обнуляется при переводе в другой отдел.
/datum/unit_test/economy_management/wage_bonus_transfer/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/mob/living/carbon/human/engineer = make_staff(ACCOUNT_ENG)
	var/datum/bank_account/member = econ_account_of(engineer)
	member.set_job(SSjob.GetJobType(/datum/job/engineer))
	TEST_ASSERT(engineering.set_wage_bonus(member, 30, chief), "Надбавка выставлена")
	member.set_job(SSjob.GetJobType(/datum/job/atmos))
	TEST_ASSERT_EQUAL(member.wage_bonus, 30, "Перевод внутри отдела надбавку не трогает")
	member.set_job(SSjob.GetJobType(/datum/job/doctor))
	TEST_ASSERT_EQUAL(member.department_id, ACCOUNT_MED, "Счёт перешёл в медицину")
	TEST_ASSERT_EQUAL(member.wage_bonus, 0, "Надбавка старого отдела не переходит в новый")

/// Потолок долга по зарплате считается от ставки грейда: снижение надбавки не списывает накопленный долг.
/datum/unit_test/economy_management/owed_cap_ignores_bonus/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/mob/living/carbon/human/engineer = make_staff(ACCOUNT_ENG)
	var/datum/bank_account/member = econ_account_of(engineer)
	econ_test_set_balance(engineering.account, 0)
	TEST_ASSERT(engineering.set_wage_bonus(member, SSeconomy.settings.max_wage_bonus, chief), "Надбавка выставлена")
	for(var/i in 1 to SSeconomy.settings.owed_wages_cap_paychecks + 2)
		member.payday()
	var/owed = member.owed_wages
	TEST_ASSERT_EQUAL(owed, SSeconomy.settings.wages[PAY_GRADE_EASY] * SSeconomy.settings.owed_wages_cap_paychecks, "Долг упёрся в потолок по ставке грейда")
	TEST_ASSERT(engineering.set_wage_bonus(member, 0, chief), "Надбавка снята")
	member.payday()
	TEST_ASSERT_EQUAL(member.owed_wages, owed, "Снятие надбавки не списало долг")

/// Запрос в казну: подаёт глава, одобряют капитан или ГП, деньги переходят отделу.
/datum/unit_test/economy_management/treasury_request/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/mob/living/carbon/human/engineer = make_staff(ACCOUNT_ENG)
	var/mob/living/carbon/human/captain = make_staff(ACCOUNT_CMD, list(ACCESS_CAPTAIN))
	var/mob/living/carbon/human/hop = make_with_job(/datum/job/hop)
	econ_test_set_balance(treasury, 1000)
	TEST_ASSERT_NULL(engineering.request_treasury(300, "тест", engineer), "Не глава запрос не подаёт")
	TEST_ASSERT_NULL(engineering.request_treasury(0, "тест", chief), "Нулевой запрос не принять")
	TEST_ASSERT_NULL(engineering.request_treasury(SSeconomy.settings.treasury_request_max + 1, "тест", chief), "Запрос сверх потолка не принять")
	var/datum/econ_request/treasury/request = engineering.request_treasury(300, "тест", chief)
	TEST_ASSERT_NOTNULL(request, "Глава подал запрос")
	TEST_ASSERT(request in SSeconomy.treasury_requests, "Запрос виден казне")
	TEST_ASSERT_EQUAL(request.requester_account_id, chief.account_id, "Запрос помнит счёт главы для уведомления")
	TEST_ASSERT(!SSeconomy.resolve_treasury_request(request.uid, TRUE, chief), "Глава отдела сам не одобряет")
	var/before = engineering.account.account_balance
	TEST_ASSERT(SSeconomy.resolve_treasury_request(request.uid, TRUE, captain), "Капитан одобрил")
	TEST_ASSERT_EQUAL(engineering.account.account_balance - before, 300, "Деньги дошли отделу")
	TEST_ASSERT_EQUAL(treasury.account_balance, 700, "Деньги ушли из казны")
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_APPROVED, "Запрос одобрен")
	TEST_ASSERT(!SSeconomy.resolve_treasury_request(request.uid, TRUE, captain), "Одобренный запрос второй раз не оплатить")
	var/datum/econ_request/treasury/second = engineering.request_treasury(200, "тест", chief)
	TEST_ASSERT_NOTNULL(second, "Второй запрос принят")
	TEST_ASSERT(SSeconomy.resolve_treasury_request(second.uid, FALSE, hop), "ГП отклонил")
	TEST_ASSERT_EQUAL(second.status, ECON_REQUEST_DENIED, "Запрос отклонён")
	TEST_ASSERT_EQUAL(treasury.account_balance, 700, "Отказ не тронул казну")
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	TEST_ASSERT_NULL(command.request_treasury(100, "тест", captain), "Казна не просит сама у себя")

/// Пустая казна: одобрение не проходит, запрос ждёт, деньги никуда не делись. Ожидающих запросов отдела не больше лимита.
/datum/unit_test/economy_management/treasury_request_limits/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/mob/living/carbon/human/captain = make_staff(ACCOUNT_CMD, list(ACCESS_CAPTAIN))
	econ_test_set_balance(treasury, 100)
	var/datum/econ_request/treasury/request = engineering.request_treasury(300, "тест", chief)
	TEST_ASSERT_NOTNULL(request, "Запрос принят")
	var/before = engineering.account.account_balance
	TEST_ASSERT(!SSeconomy.resolve_treasury_request(request.uid, TRUE, captain), "Без денег в казне не одобрить")
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_PENDING, "Запрос ждёт денег")
	TEST_ASSERT_EQUAL(treasury.account_balance, 100, "Казна не тронута")
	TEST_ASSERT_EQUAL(engineering.account.account_balance, before, "Отдел ничего не получил")
	for(var/i in 2 to SSeconomy.settings.treasury_requests_pending_per_department)
		TEST_ASSERT_NOTNULL(engineering.request_treasury(100, "тест", chief), "Запрос [i] принят")
	TEST_ASSERT_NULL(engineering.request_treasury(100, "тест", chief), "Сверх лимита ожидающих запросов не принять")
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	TEST_ASSERT_NOTNULL(medical.request_treasury(100, "тест", captain), "Лимит считается по отделу")

/datum/unit_test/economy_management/research_grant
	var/list/saved_points

/datum/unit_test/economy_management/research_grant/New()
	. = ..()
	saved_points = SSresearch.science_tech.research_points.Copy()

/datum/unit_test/economy_management/research_grant/Destroy()
	SSresearch.science_tech.research_points = saved_points
	var/datum/economy_department/science/science = SSeconomy.get_department(ACCOUNT_SCI)
	science.grant_points_in_window = 0
	science.grant_window_start = 0
	return ..()

/// Грант науке: очки техвеба за бюджет отдела, только главой, с часовым потолком.
/datum/unit_test/economy_management/research_grant/Run()
	var/datum/economy_department/science/science = SSeconomy.get_department(ACCOUNT_SCI)
	var/mob/living/carbon/human/director = make_staff(ACCOUNT_SCI, list(ACCESS_RD))
	var/mob/living/carbon/human/scientist = make_staff(ACCOUNT_SCI)
	var/cap = SSeconomy.settings.research_grant_cap_hour
	var/price = SSeconomy.settings.research_grant_price_per_point
	science.grant_points_in_window = 0
	science.grant_window_start = world.time
	econ_test_set_balance(science.account, cap * price * 2)
	var/points_before = SSresearch.science_tech.research_points[TECHWEB_POINT_TYPE_GENERIC]
	TEST_ASSERT(!science.buy_research_grant(cap, scientist), "Не глава грант не покупает")
	TEST_ASSERT(science.buy_research_grant(cap, director), "Глава купил грант")
	TEST_ASSERT_EQUAL(SSresearch.science_tech.research_points[TECHWEB_POINT_TYPE_GENERIC] - points_before, cap, "Очки начислены сразу")
	TEST_ASSERT_EQUAL(science.account.account_balance, cap * price, "Списана цена очков")
	TEST_ASSERT(!science.buy_research_grant(1, director), "Сверх часового потолка нельзя")
	science.grant_window_start = world.time - 1 HOURS - 1
	var/one_point_cost = CEILING(price, 1)
	econ_test_set_balance(science.account, one_point_cost - 1)
	points_before = SSresearch.science_tech.research_points[TECHWEB_POINT_TYPE_GENERIC]
	TEST_ASSERT(!science.buy_research_grant(1, director), "Без денег гранта нет")
	TEST_ASSERT_EQUAL(SSresearch.science_tech.research_points[TECHWEB_POINT_TYPE_GENERIC], points_before, "Без денег очков нет")
	econ_test_set_balance(science.account, one_point_cost)
	TEST_ASSERT(science.buy_research_grant(1, director), "Через час потолок обнулился")

/// Грант не окупается обратно: самые дешёвые узлы под контракт науки стоят в гранте дороже, чем платят контракт и оплата исследований.
/datum/unit_test/economy_management/research_grant_no_farm/Run()
	var/list/costs = list()
	for(var/node_id in SSresearch.techweb_nodes)
		var/datum/techweb_node/node = SSresearch.techweb_nodes[node_id]
		var/list/node_costs = node.get_price(SSresearch.science_tech)
		var/cost = node_costs ? node_costs[TECHWEB_POINT_TYPE_GENERIC] : 0
		if(!node.starting_node && cost > 0)
			costs += cost
	var/datum/econ_contract/activity/science_nodes/contract = new(ACCOUNT_SCI)
	var/nodes_needed = contract.target
	var/contract_pay = contract.reward * SSeconomy.settings.contract_urgent_mult
	qdel(contract)
	TEST_ASSERT(length(costs) >= nodes_needed, "Узлов техвеба хватает на контракт")
	sortTim(costs, GLOBAL_PROC_REF(cmp_numeric_asc))
	var/points = 0
	for(var/i in 1 to nodes_needed)
		points += costs[i]
	var/grant_cost = points * SSeconomy.settings.research_grant_price_per_point
	var/node_pay = points / ECON_NODE_POINTS_UNIT * SSeconomy.settings.work_prices[WORK_SCI_NODE] * (100 + SSeconomy.settings.work_personal_share) / 100
	TEST_ASSERT(grant_cost > node_pay + contract_pay, "Грант [grant_cost] кр. окупается: узлы [node_pay] + контракт [contract_pay]")
