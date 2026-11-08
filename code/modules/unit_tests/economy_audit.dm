/datum/unit_test/economy_audit
	abstract_type = /datum/unit_test/economy_audit
	var/list/saved_flags
	var/list/saved_balances = list()
	var/saved_tax_rate
	var/saved_trace_depth
	var/list/saved_crypto_paid

/datum/unit_test/economy_audit/New()
	. = ..()
	saved_crypto_paid = SSeconomy.crypto_paid
	SSeconomy.crypto_paid = list()
	SSeconomy.crypto_paid_tick = SSeconomy.fire_count
	saved_flags = SSeconomy.audit_flags
	SSeconomy.audit_flags = list()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		saved_balances[id] = department.account.account_balance
	saved_tax_rate = SSeconomy.tax_rate
	SSeconomy.tax_rate = 0
	saved_trace_depth = SSeconomy.settings.audit_trace_depth

/datum/unit_test/economy_audit/Destroy()
	QDEL_LIST(SSeconomy.audit_flags)
	SSeconomy.audit_flags = saved_flags
	for(var/id in saved_balances)
		var/datum/economy_department/department = SSeconomy.departments[id]
		econ_test_set_balance(department.account, saved_balances[id])
	SSeconomy.tax_rate = saved_tax_rate
	SSeconomy.settings.audit_trace_depth = saved_trace_depth
	SSeconomy.crypto_paid = saved_crypto_paid
	return ..()

/datum/unit_test/economy_audit/proc/make_account(holder, balance = 0)
	var/datum/bank_account/account = new(holder)
	allocated += account
	if(balance)
		econ_test_set_balance(account, balance)
	return account

/// Человек со своим счётом (как после выдачи должности) и картой в руке.
/datum/unit_test/economy_audit/proc/make_person(holder, list/access, job_type, department_id)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = make_account(holder)
	account.department_id = department_id
	account.pay_grade = department_id ? PAY_GRADE_EASY : null
	person.account_id = account.account_id
	account.bind_owner(person)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = account
	card.registered_name = holder
	card.access = access ? access.Copy() : list()
	person.put_in_hands(card)
	if(job_type)
		var/datum/job/job = SSjob.GetJobType(job_type)
		person.mind_initialize()
		person.mind.assigned_role = job.title
		card.assignment = job.title
	return person

/datum/unit_test/economy_audit/proc/flags_of_kind(datum/bank_account/account, kind)
	. = list()
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.flags_for(account))
		if(flag.kind == kind)
			. += flag

/datum/unit_test/economy_audit/proc/case_fee(amount)
	return round(amount * SSeconomy.settings.audit_case_fee_percent / 100)

/datum/unit_test/economy_audit/proc/transfer(datum/bank_account/source, datum/bank_account/target, amount)
	COOLDOWN_RESET(source, personal_payment_cooldown)
	return SSeconomy.send_transfer(source, target, amount)

/// Списание с неопознанного устройства помечается на обоих счетах без имени владельца устройства, повторы копятся в одном деле; откуп бюджетом не помечается.
/datum/unit_test/economy_audit/skim_flag/Run()
	var/datum/bank_account/victim = make_account("Econ Audit Victim", 5000)
	var/datum/bank_account/thief = make_account("Econ Audit Thief")
	SSeconomy.move(victim, thief, 1000, ECON_SKIM)
	var/list/flags = SSeconomy.flags_for(victim)
	TEST_ASSERT_EQUAL(length(flags), 1, "Один флаг на счёте жертвы")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT_EQUAL(flag.kind, AUDIT_FLAG_UNKNOWN_DEVICE, "Неопознанное устройство")
	TEST_ASSERT_EQUAL(flag.amount, 1000, "Сумма флага")
	TEST_ASSERT_EQUAL(flag.account_number, victim.account_id, "Деньги ушли со счёта жертвы")
	TEST_ASSERT_EQUAL(flag.counterparty_number, thief.account_id, "Деньги пришли на счёт вора")
	TEST_ASSERT(!findtext(flag.text, thief.account_holder), "Текст не называет владельца устройства")
	TEST_ASSERT(flag in SSeconomy.flags_for(thief), "Флаг виден и на счёте получателя")
	SSeconomy.move(victim, thief, 500, ECON_SKIM)
	TEST_ASSERT_EQUAL(length(SSeconomy.flags_for(victim)), 1, "Повторное списание тем же путём - то же дело")
	TEST_ASSERT_EQUAL(flag.amount, 1500, "Сумма дела выросла")
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/datum/bank_account/inspection = make_account("Econ Audit Inspection")
	inspection.offstation = TRUE
	econ_test_set_balance(cargo, 1000)
	SSeconomy.move(cargo, inspection, 500, ECON_SKIM)
	TEST_ASSERT_EQUAL(length(SSeconomy.flags_for(cargo)), 0, "Откуп из бюджета отдела не неопознанное устройство")

/// Дробление: серия личных переводов одному получателю за окно; другим получателям не считается.
/datum/unit_test/economy_audit/structuring/Run()
	var/count = SSeconomy.settings.audit_structuring_count
	var/datum/bank_account/alice = make_account("Econ Audit Alice", 1000)
	var/datum/bank_account/bob = make_account("Econ Audit Bob")
	var/datum/bank_account/carol = make_account("Econ Audit Carol")
	for(var/i in 1 to count - 1)
		TEST_ASSERT_NULL(transfer(alice, bob, 10), "Перевод [i] проходит")
	TEST_ASSERT_NULL(transfer(alice, carol, 10), "Перевод другому получателю проходит")
	TEST_ASSERT_EQUAL(length(flags_of_kind(alice, AUDIT_FLAG_STRUCTURING)), 0, "До порога флага нет")
	TEST_ASSERT_NULL(transfer(alice, bob, 10), "Последний перевод серии проходит")
	var/list/flags = flags_of_kind(alice, AUDIT_FLAG_STRUCTURING)
	TEST_ASSERT_EQUAL(length(flags), 1, "Дробление замечено")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT_EQUAL(flag.counterparty_number, bob.account_id, "Получатель серии")
	TEST_ASSERT_EQUAL(flag.amount, count * 10, "Сумма серии")
	TEST_ASSERT_NULL(transfer(alice, bob, 10), "Следующий перевод проходит")
	TEST_ASSERT_EQUAL(length(flags_of_kind(alice, AUDIT_FLAG_STRUCTURING)), 1, "Продолжение серии - то же дело")
	TEST_ASSERT_EQUAL(flag.amount, (count + 1) * 10, "Сумма дела выросла")

/// Обычная игра флагов не даёт: зарплата, премии отделу, работа, контракт, чаевые, касса, налог, разовый перевод.
/datum/unit_test/economy_audit/normal_play_no_flags/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	econ_test_set_balance(engineering.account, 5000)
	SSeconomy.tax_rate = 10
	var/mob/living/carbon/human/chief = make_person("Econ Audit Chief", list(ACCESS_CE), null, ACCOUNT_ENG)
	var/list/staff = list()
	for(var/i in 1 to SSeconomy.settings.audit_structuring_count + 1)
		var/mob/living/carbon/human/engineer = make_person("Econ Audit Engineer [i]", null, null, ACCOUNT_ENG)
		var/datum/bank_account/member = econ_account_of(engineer)
		staff += member
		TEST_ASSERT(engineering.pay_bonus(member, 200, chief), "Премия сотруднику [i]")
	var/datum/bank_account/worker = staff[1]
	TEST_ASSERT(worker.payday() > 0, "Зарплата выплачена")
	TEST_ASSERT(SSeconomy.record_work(ACCOUNT_ENG, WORK_ENG_INTEGRITY, 1, chief) > 0, "Работа оплачена")
	TEST_ASSERT(SSeconomy.pay_personal(null, worker, 300, ECON_CONTRACT) > 0, "Контракт оплачен")
	var/obj/machinery/cash_register/register = allocate(/obj/machinery/cash_register/bar)
	var/mob/living/carbon/human/bartender = make_person("Econ Audit Bartender", null, null, ACCOUNT_SRV)
	var/mob/living/carbon/human/customer = make_person("Econ Audit Guest")
	var/datum/bank_account/guest = econ_account_of(customer)
	econ_test_set_balance(guest, 1000)
	var/obj/item/card/id/bartender_card = bartender.get_active_held_item()
	bartender_card.melee_attack_chain(bartender, register)
	TEST_ASSERT(register.is_cashier(bartender), "Бармен за кассой")
	TEST_ASSERT(register.register_act(bartender, "add_item", list("name" = "Пиво", "price" = 20)), "Позиция добавлена")
	var/datum/register_cashier/till = register.cashier_of(bartender)
	var/list/beer = register.menu[1]
	for(var/i in 1 to SSeconomy.settings.audit_structuring_count + 1)
		TEST_ASSERT(register.register_act(bartender, "order", list("id" = beer["id"], "delta" = 1)), "Пиво в счёте [i]")
		TEST_ASSERT(register.register_act(customer, "pay", list("cashier" = till.account.account_id, "rev" = till.order_rev, "total" = 20)), "Оплата на кассе [i]")
	TEST_ASSERT(register.register_act(customer, "tip", list("amount" = 10, "cashier" = till.account.account_id)), "Чаевые на кассе")
	COOLDOWN_RESET(guest, personal_payment_cooldown)
	TEST_ASSERT_NULL(SSeconomy.send_tip(guest, worker, 50), "Чаевые")
	TEST_ASSERT_NULL(transfer(guest, worker, 100), "Разовый перевод")
	TEST_ASSERT_EQUAL(length(SSeconomy.audit_flags), 0, "Ни одного флага")

/// Премия главы самому себе помечается всегда.
/datum/unit_test/economy_audit/self_bonus/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	econ_test_set_balance(engineering.account, 500)
	var/mob/living/carbon/human/chief = make_person("Econ Audit Chief", list(ACCESS_CE), null, ACCOUNT_ENG)
	var/datum/bank_account/own = econ_account_of(chief)
	TEST_ASSERT(engineering.pay_bonus(own, 100, chief), "Премия себе проходит")
	var/list/flags = flags_of_kind(own, AUDIT_FLAG_SELF_BONUS)
	TEST_ASSERT_EQUAL(length(flags), 1, "Премия себе помечена")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT_EQUAL(flag.account_number, engineering.account.account_id, "Деньги ушли из бюджета")
	TEST_ASSERT_EQUAL(flag.counterparty_number, own.account_id, "Деньги пришли главе")
	TEST_ASSERT_EQUAL(length(flags_of_kind(own, AUDIT_FLAG_BUDGET_SIPHON)), 0, "Премия себе не считается ещё и выводом")

/// Доход криптомайнера на личный счёт - одно дело на бюджете снабжения с местом майнера, возврат идёт снабжению; доход снабжению дела не открывает.
/datum/unit_test/economy_audit/cryptominer/Run()
	var/obj/machinery/cryptominer/miner = allocate(/obj/machinery/cryptominer)
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	miner.produce_points(1)
	TEST_ASSERT_EQUAL(length(SSeconomy.audit_flags), 0, "Доход снабжению открыл дело")
	var/mob/living/carbon/human/owner = make_person("Econ Audit Miner")
	var/datum/bank_account/personal = econ_account_of(owner)
	miner.pay_me = personal
	miner.produce_points(1)
	miner.produce_points(1)
	var/list/flags = flags_of_kind(personal, AUDIT_FLAG_CRYPTOMINER)
	TEST_ASSERT_EQUAL(length(flags), 1, "Доход майнера на личный счёт - не одно дело")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT_EQUAL(flag.account_number, cargo.account_id, "Дело не на бюджете снабжения")
	TEST_ASSERT_EQUAL(flag.amount, miner.miningpoints, "Сумма дела не первый доход майнера")
	TEST_ASSERT(findtext(flag.text, get_area_name(miner, TRUE)), "Дело без места майнера: [flag.text]")
	var/mob/living/carbon/human/auditor = make_person("Econ Audit Miner Auditor", list(ACCESS_HOS))
	TEST_ASSERT(SSeconomy.freeze_account(personal, auditor, "майнер"), "Заморозка")
	var/cargo_before = cargo.account_balance
	TEST_ASSERT(SSeconomy.refund(personal, cargo, miner.miningpoints, auditor, flag.uid), "Возврат снабжению не прошёл")
	TEST_ASSERT_EQUAL(cargo.account_balance - cargo_before, miner.miningpoints - case_fee(miner.miningpoints), "Снабжение не получило возврат")

/// Майнер Синдиката, как обещает его описание, мимо аудита.
/datum/unit_test/economy_audit/cryptominer_syndie/Run()
	var/datum/bank_account/personal = econ_account_of(make_person("Econ Audit Syndie Miner"))
	var/obj/machinery/cryptominer/syndie/syndie = allocate(/obj/machinery/cryptominer/syndie)
	syndie.pay_me = personal
	syndie.produce_points(1)
	TEST_ASSERT_EQUAL(length(flags_of_kind(personal, AUDIT_FLAG_CRYPTOMINER)), 0, "Майнер Синдиката открыл дело аудита")

/// Доход майнера на личный счёт уходит в аудит одной записью за интервал, остаток - при разборе майнера.
/datum/unit_test/economy_audit/cryptominer_throttle/Run()
	var/datum/bank_account/personal = econ_account_of(make_person("Econ Audit Throttle"))
	var/obj/machinery/cryptominer/miner = allocate(/obj/machinery/cryptominer)
	miner.pay_me = personal
	miner.produce_points(1)
	miner.produce_points(1)
	var/list/flags = flags_of_kind(personal, AUDIT_FLAG_CRYPTOMINER)
	TEST_ASSERT_EQUAL(length(flags), 1, "Доход майнера на личный счёт не попал в аудит")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT_EQUAL(flag.amount, miner.miningpoints, "Доход внутри интервала записан в аудит сразу")
	var/points = miner.miningpoints
	qdel(miner)
	TEST_ASSERT_EQUAL(flag.amount, points * 2, "Накопленный доход не записан при разборе майнера")

/// В холоде майнер платит за тик один раз.
/datum/unit_test/economy_audit/cryptominer_single_payout/Run()
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/obj/machinery/cryptominer/heater = allocate(/obj/machinery/cryptominer)
	var/turf/open/floor = get_turf(heater)
	var/datum/gas_mixture/air = floor.return_air()
	var/saved_temperature = air.return_temperature()
	air.set_temperature((CONFIG_GET(number/crypto_heat_threshold_min) + CONFIG_GET(number/crypto_heat_threshold_mid)) / 2)
	var/cargo_before = cargo.account_balance
	heater.process()
	air.set_temperature(saved_temperature)
	TEST_ASSERT_EQUAL(cargo.account_balance - cargo_before, heater.miningpoints, "Майнер заплатил за тик не один раз")

/// Вывод из бюджета: премии одному человеку за окно от порога и крупное открытие счёта из казны.
/datum/unit_test/economy_audit/budget_siphon/Run()
	var/threshold = SSeconomy.settings.audit_bonus_threshold
	var/part = round(threshold * 0.6)
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	econ_test_set_balance(engineering.account, threshold * 3)
	var/mob/living/carbon/human/chief = make_person("Econ Audit Chief", list(ACCESS_CE), null, ACCOUNT_ENG)
	var/mob/living/carbon/human/engineer = make_person("Econ Audit Engineer", null, null, ACCOUNT_ENG)
	var/datum/bank_account/member = econ_account_of(engineer)
	TEST_ASSERT(engineering.pay_bonus(member, part, chief), "Первая премия")
	TEST_ASSERT_EQUAL(length(SSeconomy.flags_for(member)), 0, "Одна премия ниже порога не помечена")
	TEST_ASSERT(engineering.pay_bonus(member, part, chief), "Вторая премия")
	var/list/flags = flags_of_kind(member, AUDIT_FLAG_BUDGET_SIPHON)
	TEST_ASSERT_EQUAL(length(flags), 1, "Премии выше порога за окно помечены")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT_EQUAL(flag.amount, part * 2, "Сумма дела - обе премии")
	TEST_ASSERT_EQUAL(flag.account_number, engineering.account.account_id, "Из бюджета инженерии")
	var/datum/bank_account/treasury = SSeconomy.treasury()
	econ_test_set_balance(treasury, threshold * 2)
	var/mob/living/carbon/human/captain = make_person("Econ Audit Captain", list(ACCESS_CAPTAIN))
	var/datum/bank_account/opened = SSeconomy.open_account("Econ Audit Opened", threshold, captain)
	TEST_ASSERT_NOTNULL(opened, "Счёт открыт")
	allocated += opened
	TEST_ASSERT_EQUAL(length(flags_of_kind(opened, AUDIT_FLAG_BUDGET_SIPHON)), 1, "Крупное открытие счёта из казны помечено")

/// След денег: жертва -> вор -> мул и наличные; наличные не раскрываются дальше, глубина ограничена настройкой, старое за окном не видно.
/datum/unit_test/economy_audit/trace/Run()
	SSeconomy.settings.audit_trace_depth = 3
	var/datum/bank_account/victim = make_account("Econ Audit Victim", 5000)
	var/datum/bank_account/thief = make_account("Econ Audit Thief")
	var/datum/bank_account/mule = make_account("Econ Audit Mule")
	var/datum/bank_account/second = make_account("Econ Audit Second")
	var/datum/bank_account/third = make_account("Econ Audit Third")
	SSeconomy.move(victim, thief, 1000, ECON_SKIM)
	TEST_ASSERT_NULL(transfer(thief, mule, 600), "Вор переводит мулу")
	TEST_ASSERT(SSeconomy.move(thief, SSeconomy.cash_account, 100, ECON_CASH_OUT), "Вор снимает наличные")
	TEST_ASSERT_NULL(transfer(mule, second, 300), "Мул переводит дальше")
	TEST_ASSERT_NULL(transfer(second, third, 200), "И ещё дальше")
	TEST_ASSERT_NULL(transfer(mule, victim, 50), "Часть вернулась жертве")
	var/list/tree = SSeconomy.trace_money(victim, 99)
	TEST_ASSERT_EQUAL(length(tree), 1, "Один получатель")
	var/list/first = tree[1]
	TEST_ASSERT_EQUAL(first["number"], thief.account_id, "Первый узел - вор")
	TEST_ASSERT_EQUAL(first["amount"], 1000, "Сумма к вору")
	var/list/thief_children = first["children"]
	TEST_ASSERT_EQUAL(length(thief_children), 2, "У вора мул и наличные")
	var/list/mule_node
	var/list/cash_node
	for(var/list/node as anything in thief_children)
		if(node["number"] == mule.account_id)
			mule_node = node
		if(node["number"] == SSeconomy.cash_account.account_id)
			cash_node = node
	TEST_ASSERT_NOTNULL(mule_node, "Узел мула")
	TEST_ASSERT_NOTNULL(cash_node, "Узел наличных")
	TEST_ASSERT_EQUAL(mule_node["amount"], 600, "Сумма мулу")
	TEST_ASSERT_EQUAL(length(cash_node["children"]), 0, "Наличные дальше не раскрываются")
	var/list/mule_children = mule_node["children"]
	TEST_ASSERT_EQUAL(length(mule_children), 2, "У мула второй и жертва")
	for(var/list/node as anything in mule_children)
		TEST_ASSERT_EQUAL(length(node["children"]), 0, "Третий уровень - последний, жертва не раскрывается повторно")
	SSeconomy.settings.audit_trace_depth = 1
	var/list/shallow = SSeconomy.trace_money(victim, 3)
	var/list/shallow_first = shallow[1]
	TEST_ASSERT_EQUAL(length(shallow_first["children"]), 0, "Глубина из настроек 1 - только первый получатель")
	for(var/number in victim.audit_outflows)
		for(var/list/bucket as anything in victim.audit_outflows[number])
			bucket[AUDIT_BUCKET_START] -= SSeconomy.settings.audit_trace_minutes MINUTES + AUDIT_BUCKET
	TEST_ASSERT_EQUAL(length(SSeconomy.trace_money(victim, 3)), 0, "Операции старше окна не видны")

/// Заморозка и возврат: только с замороженного счёта получателя на счёт, откуда ушли деньги, не больше суммы дела, один раз; СБ получает сбор с получателя, деньги не создаются.
/datum/unit_test/economy_audit/refund_closes_case/Run()
	var/mob/living/carbon/human/detective = make_person("Econ Audit Detective", list(ACCESS_FORENSICS_LOCKERS), /datum/job/detective)
	var/datum/bank_account/victim = make_account("Econ Audit Victim", 5000)
	var/datum/bank_account/thief = make_account("Econ Audit Thief")
	var/datum/bank_account/mule = make_account("Econ Audit Mule")
	SSeconomy.move(victim, thief, 1000, ECON_SKIM)
	var/list/flags = SSeconomy.flags_for(victim)
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT(!SSeconomy.refund(thief, victim, 1000, detective, flag.uid), "Без заморозки возврата нет")
	TEST_ASSERT(SSeconomy.freeze_account(thief, detective, "кража"), "Заморожен")
	TEST_ASSERT_EQUAL(thief.state, ACCOUNT_FROZEN, "Состояние заморозки")
	TEST_ASSERT_EQUAL(transfer(thief, mule, 100), "Ваш счёт заморожен.", "Замороженный не переводит")
	TEST_ASSERT(!SSeconomy.refund(thief, mule, 100, detective, flag.uid), "На чужой счёт не вернуть")
	TEST_ASSERT(!SSeconomy.refund(thief, victim, 1001, detective, flag.uid), "Больше суммы дела не вернуть")
	TEST_ASSERT(!SSeconomy.refund(thief, victim, 0, detective, flag.uid), "Пустой возврат не проходит")
	var/datum/bank_account/sec = SSeconomy.get_dep_account(ACCOUNT_SEC)
	var/datum/bank_account/detective_account = econ_account_of(detective)
	var/sec_before = sec.account_balance
	var/detective_before = detective_account.account_balance
	var/minted = SSeconomy.ledger.minted
	var/burned = SSeconomy.ledger.burned
	var/fee = case_fee(1000)
	TEST_ASSERT(fee > 0, "Сбор по умолчанию не нулевой")
	TEST_ASSERT(SSeconomy.refund(thief, victim, 1000, detective, flag.uid), "Возврат")
	TEST_ASSERT_EQUAL(victim.account_balance, 5000 - fee, "Пострадавшему вернулось всё, кроме сбора")
	TEST_ASSERT_EQUAL(thief.account_balance, 0, "Списаны с вора")
	TEST_ASSERT(flag.closed, "Дело закрыто")
	TEST_ASSERT_EQUAL(flag.refunded, 1000 - fee, "Возвращено по делу")
	TEST_ASSERT_EQUAL(sec.account_balance - sec_before, fee, "Сбор отделу безопасности")
	TEST_ASSERT_EQUAL(detective_account.account_balance, detective_before, "Аудитору ничего не начислено")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted, "Возврат не печатает деньги")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned, burned, "Возврат не сжигает деньги")
	econ_test_set_balance(thief, 1000)
	TEST_ASSERT(!SSeconomy.refund(thief, victim, 100, detective, flag.uid), "Второй возврат по тому же делу запрещён")
	TEST_ASSERT_EQUAL(thief.account_balance, 1000, "Отказ ничего не списал")

/// Аудит доступен детективу и ГП по должности, главе СБ и капитану по доступу; не офицеру и не клерку; свой счёт и бюджеты не замораживаются.
/datum/unit_test/economy_audit/needs_access/Run()
	var/datum/bank_account/suspect = make_account("Econ Audit Suspect")
	var/mob/living/carbon/human/clerk = make_person("Econ Audit Clerk")
	var/mob/living/carbon/human/officer = make_person("Econ Audit Officer", list(ACCESS_SECURITY, ACCESS_FORENSICS_LOCKERS))
	var/mob/living/carbon/human/detective = make_person("Econ Audit Detective", list(ACCESS_FORENSICS_LOCKERS), /datum/job/detective)
	var/mob/living/carbon/human/hop = make_person("Econ Audit HoP", list(ACCESS_HOP), /datum/job/hop)
	var/mob/living/carbon/human/hos = make_person("Econ Audit HoS", list(ACCESS_HOS))
	var/mob/living/carbon/human/captain = make_person("Econ Audit Captain", list(ACCESS_CAPTAIN))
	TEST_ASSERT(!SSeconomy.can_audit(clerk), "Клерк не аудитор")
	TEST_ASSERT(!SSeconomy.can_audit(officer), "Офицер с доступом криминалистики не аудитор")
	var/mob/living/carbon/human/fired = make_person("Econ Audit Fired", null, /datum/job/detective)
	TEST_ASSERT(!SSeconomy.can_audit(fired), "Детектив без доступа на ID не аудитор")
	TEST_ASSERT(!SSeconomy.freeze_account(suspect, fired, "x"), "Уволенный детектив не замораживает")
	var/mob/living/carbon/human/stripped_hop = make_person("Econ Audit Stripped HoP", null, /datum/job/hop)
	TEST_ASSERT(!SSeconomy.can_audit(stripped_hop), "ГП без доступа на ID не аудитор")
	TEST_ASSERT(SSeconomy.can_audit(detective), "Детектив")
	TEST_ASSERT(SSeconomy.can_audit(hop), "ГП")
	TEST_ASSERT(SSeconomy.can_audit(hos), "Глава СБ")
	TEST_ASSERT(SSeconomy.can_audit(captain), "Капитан")
	TEST_ASSERT(!SSeconomy.freeze_account(suspect, clerk, "x"), "Без доступа не заморозить")
	TEST_ASSERT(!SSeconomy.freeze_account(suspect, detective, ""), "Без причины не заморозить")
	TEST_ASSERT(!SSeconomy.freeze_account(SSeconomy.get_dep_account(ACCOUNT_ENG), detective, "x"), "Бюджет отдела не замораживается")
	TEST_ASSERT(!SSeconomy.freeze_account(SSeconomy.cash_account, detective, "x"), "Системный счёт не замораживается")
	var/datum/bank_account/detective_account = econ_account_of(detective)
	TEST_ASSERT(!SSeconomy.freeze_account(detective_account, detective, "x"), "Свой счёт не заморозить")
	TEST_ASSERT(SSeconomy.freeze_account(detective_account, hos, "проверка"), "Глава СБ замораживает детектива")
	TEST_ASSERT(!SSeconomy.unfreeze_account(detective_account, detective), "Свой счёт не разморозить")
	TEST_ASSERT(SSeconomy.unfreeze_account(detective_account, captain), "Капитан размораживает")
	TEST_ASSERT(SSeconomy.freeze_account(suspect, detective, "проверка"), "Детектив замораживает")
	TEST_ASSERT_EQUAL(suspect.freeze_reason, "проверка", "Причина сохранена")
	TEST_ASSERT_EQUAL(suspect.frozen_by, "Econ Audit Detective, Detective", "Кто заморозил")
	TEST_ASSERT(!SSeconomy.freeze_account(suspect, hop, "ещё раз"), "Повторно не заморозить")
	TEST_ASSERT(!SSeconomy.unfreeze_account(suspect, clerk), "Без доступа не разморозить")
	TEST_ASSERT(SSeconomy.unfreeze_account(suspect, hop), "ГП размораживает")
	TEST_ASSERT_EQUAL(suspect.state, ACCOUNT_ACTIVE, "Счёт снова активен")
	TEST_ASSERT_NULL(suspect.freeze_reason, "Причина снята")
	TEST_ASSERT_NULL(suspect.frozen_by, "Заморозивший снят")

/// Замороженный счёт: исходящие, наличные и премии закрыты; входящие, налог и возврат проходят; зарплата копится долгом и приходит после разморозки.
/datum/unit_test/economy_audit/frozen_account/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	econ_test_set_balance(engineering.account, 5000)
	var/mob/living/carbon/human/chief = make_person("Econ Audit Chief", list(ACCESS_CE), null, ACCOUNT_ENG)
	var/mob/living/carbon/human/engineer = make_person("Econ Audit Engineer", null, null, ACCOUNT_ENG)
	var/mob/living/carbon/human/detective = make_person("Econ Audit Detective", list(ACCESS_FORENSICS_LOCKERS), /datum/job/detective)
	var/datum/bank_account/member = econ_account_of(engineer)
	var/datum/bank_account/friend = make_account("Econ Audit Friend", 500)
	econ_test_set_balance(member, 300)
	TEST_ASSERT(SSeconomy.freeze_account(member, detective, "проверка"), "Заморожен")
	TEST_ASSERT(!SSeconomy.move(member, SSeconomy.cash_account, 100, ECON_CASH_OUT), "Наличные не снять")
	TEST_ASSERT(!engineering.pay_bonus(member, 100, chief), "Премию на замороженный счёт не выписать")
	TEST_ASSERT_NULL(transfer(friend, member, 100), "Входящий перевод проходит")
	TEST_ASSERT(SSeconomy.move(member, SSeconomy.treasury(), 10, ECON_TAX), "Налог списывается")
	var/wage = member.wage_amount()
	TEST_ASSERT_EQUAL(member.payday(), 0, "Зарплата не выплачена")
	TEST_ASSERT_EQUAL(member.owed_wages, wage, "Зарплата в долгу отдела")
	TEST_ASSERT_EQUAL(member.account_balance, 390, "Баланс не изменился")
	TEST_ASSERT(SSeconomy.unfreeze_account(member, detective), "Разморожен")
	TEST_ASSERT_EQUAL(member.payday(), wage * 2, "После разморозки пришёл и долг")

/// Закрытие дела без возврата: с причиной, правами аудита и не по своему счёту; денег не двигает, закрытое дело не вернуть. Дело снятия с анонимного счёта закрывается так же.
/datum/unit_test/economy_audit/close_without_refund/Run()
	var/mob/living/carbon/human/clerk = make_person("Econ Audit Clerk")
	var/mob/living/carbon/human/hos = make_person("Econ Audit HoS", list(ACCESS_HOS))
	var/datum/bank_account/victim = make_account("Econ Audit Victim", 1000)
	var/datum/bank_account/thief = make_account("Econ Audit Thief")
	SSeconomy.move(victim, thief, 400, ECON_SKIM)
	var/list/flags = SSeconomy.flags_for(victim)
	var/datum/econ_audit_flag/flag = flags[1]
	var/mob/living/carbon/human/victim_auditor = make_person("Econ Audit Victim HoS", list(ACCESS_HOS))
	victim.bind_owner(victim_auditor)
	TEST_ASSERT(!SSeconomy.close_case(flag.uid, clerk, "ошибка"), "Без прав не закрыть")
	TEST_ASSERT(!SSeconomy.close_case(flag.uid, hos, ""), "Без причины не закрыть")
	TEST_ASSERT(!SSeconomy.close_case(flag.uid, victim_auditor, "ошибка"), "Дело по своему счёту не закрыть")
	var/datum/bank_account/sec = SSeconomy.get_dep_account(ACCOUNT_SEC)
	var/sec_before = sec.account_balance
	var/minted = SSeconomy.ledger.minted
	TEST_ASSERT(SSeconomy.close_case(flag.uid, hos, "перевод по договорённости"), "Дело закрыто")
	TEST_ASSERT(flag.closed, "Закрыто")
	TEST_ASSERT_EQUAL(flag.close_reason, "перевод по договорённости", "Причина сохранена")
	TEST_ASSERT_EQUAL(flag.closed_by, "Econ Audit HoS, без должности", "Кто закрыл")
	TEST_ASSERT_EQUAL(victim.account_balance, 600, "Деньги жертвы не тронуты")
	TEST_ASSERT_EQUAL(thief.account_balance, 400, "Деньги получателя не тронуты")
	TEST_ASSERT_EQUAL(sec.account_balance, sec_before, "СБ ничего не получила")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted, "Ничего не напечатано")
	TEST_ASSERT(!SSeconomy.close_case(flag.uid, hos, "ещё раз"), "Повторно не закрыть")
	TEST_ASSERT(SSeconomy.freeze_account(thief, hos, "кража"), "Заморожен")
	TEST_ASSERT(!SSeconomy.refund(thief, victim, 400, hos, flag.uid), "Закрытое дело не вернуть")
	var/mob/living/carbon/human/cashier = allocate(/mob/living/carbon/human)
	var/obj/item/anon_account_card/anon = allocate(/obj/item/anon_account_card)
	var/datum/bank_account/anon_account = anon.account
	allocated += anon_account
	econ_test_set_balance(anon_account, 300)
	allocated += anon.cash_out(200, cashier)
	var/list/anon_flags = flags_of_kind(anon_account, AUDIT_FLAG_ANON_CASHOUT)
	TEST_ASSERT_EQUAL(length(anon_flags), 1, "Снятие с анонимного счёта в аудите")
	var/datum/econ_audit_flag/anon_flag = anon_flags[1]
	TEST_ASSERT(SSeconomy.close_case(anon_flag.uid, hos, "владелец установлен"), "Дело снятия закрыто без возврата")
	TEST_ASSERT(anon_flag.closed, "Закрыто")

/datum/unit_test/economy_audit/proc/open_flags_of_kind(datum/bank_account/account, kind)
	. = list()
	for(var/datum/econ_audit_flag/flag as anything in flags_of_kind(account, kind))
		if(!flag.closed)
			. += flag

/// После возврата по делу дробления прежние переводы пары не попадают в новое дело.
/datum/unit_test/economy_audit/structuring_refund_once/Run()
	var/count = SSeconomy.settings.audit_structuring_count
	var/mob/living/carbon/human/detective = make_person("Econ Audit Detective", list(ACCESS_FORENSICS_LOCKERS), /datum/job/detective)
	var/datum/bank_account/detective_account = econ_account_of(detective)
	var/datum/bank_account/alice = make_account("Econ Audit Alice", 1000)
	var/datum/bank_account/bob = make_account("Econ Audit Bob")
	for(var/i in 1 to count)
		TEST_ASSERT_NULL(transfer(alice, bob, 10), "Перевод [i]")
	var/list/flags = open_flags_of_kind(alice, AUDIT_FLAG_STRUCTURING)
	TEST_ASSERT_EQUAL(length(flags), 1, "Дробление замечено")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT(SSeconomy.freeze_account(bob, detective, "дробление"), "Получатель заморожен")
	var/datum/bank_account/sec = SSeconomy.get_dep_account(ACCOUNT_SEC)
	var/sec_before = sec.account_balance
	var/detective_before = detective_account.account_balance
	TEST_ASSERT(SSeconomy.refund(bob, alice, count * 10, detective, flag.uid), "Возврат")
	TEST_ASSERT(flag.closed, "Дело закрыто")
	TEST_ASSERT_EQUAL(sec.account_balance - sec_before, case_fee(count * 10), "СБ получила только сбор")
	TEST_ASSERT_EQUAL(detective_account.account_balance, detective_before, "Аудитору ничего не начислено")
	TEST_ASSERT_NULL(transfer(alice, bob, 1), "Перевод после закрытия")
	TEST_ASSERT_EQUAL(length(open_flags_of_kind(alice, AUDIT_FLAG_STRUCTURING)), 0, "Старые переводы в новое дело не попали")
	for(var/i in 1 to count - 1)
		TEST_ASSERT_NULL(transfer(alice, bob, 1), "Новая серия [i]")
	flags = open_flags_of_kind(alice, AUDIT_FLAG_STRUCTURING)
	TEST_ASSERT_EQUAL(length(flags), 1, "Новая серия - новое дело")
	var/datum/econ_audit_flag/second = flags[1]
	TEST_ASSERT_EQUAL(second.amount, count, "Новое дело ровно на новые переводы")

/// После возврата по делу оттока бюджета прежние премии пары не попадают в новое дело.
/datum/unit_test/economy_audit/siphon_refund_once/Run()
	var/threshold = SSeconomy.settings.audit_bonus_threshold
	var/part = round(threshold * 0.6)
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	econ_test_set_balance(engineering.account, threshold * 5)
	var/mob/living/carbon/human/chief = make_person("Econ Audit Chief", list(ACCESS_CE), null, ACCOUNT_ENG)
	var/mob/living/carbon/human/engineer = make_person("Econ Audit Engineer", null, null, ACCOUNT_ENG)
	var/mob/living/carbon/human/hos = make_person("Econ Audit HoS", list(ACCESS_HOS))
	var/datum/bank_account/member = econ_account_of(engineer)
	TEST_ASSERT(engineering.pay_bonus(member, part, chief), "Первая премия")
	TEST_ASSERT(engineering.pay_bonus(member, part, chief), "Вторая премия")
	var/list/flags = open_flags_of_kind(member, AUDIT_FLAG_BUDGET_SIPHON)
	TEST_ASSERT_EQUAL(length(flags), 1, "Отток замечен")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT(SSeconomy.freeze_account(member, hos, "отток"), "Заморожен")
	var/datum/bank_account/sec = SSeconomy.get_dep_account(ACCOUNT_SEC)
	var/sec_before = sec.account_balance
	TEST_ASSERT(SSeconomy.refund(member, engineering.account, part * 2, hos, flag.uid), "Возврат в бюджет")
	TEST_ASSERT_EQUAL(sec.account_balance - sec_before, case_fee(part * 2), "СБ получила только сбор")
	TEST_ASSERT(SSeconomy.unfreeze_account(member, hos), "Разморожен")
	TEST_ASSERT(engineering.pay_bonus(member, part, chief), "Премия после закрытия")
	TEST_ASSERT_EQUAL(length(open_flags_of_kind(member, AUDIT_FLAG_BUDGET_SIPHON)), 0, "Возвращённые премии в новое дело не попали")
	TEST_ASSERT(engineering.pay_bonus(member, part, chief), "Ещё премия")
	flags = open_flags_of_kind(member, AUDIT_FLAG_BUDGET_SIPHON)
	TEST_ASSERT_EQUAL(length(flags), 1, "Новое дело")
	var/datum/econ_audit_flag/second = flags[1]
	TEST_ASSERT_EQUAL(second.amount, part * 2, "Новое дело ровно на новые премии")

/// Мелкие премии другим сотрудникам между крупными не прячут отток одному человеку.
/datum/unit_test/economy_audit/siphon_not_evicted/Run()
	var/threshold = SSeconomy.settings.audit_bonus_threshold
	var/part = round(threshold * 0.9)
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	econ_test_set_balance(engineering.account, threshold * 3)
	var/mob/living/carbon/human/chief = make_person("Econ Audit Chief", list(ACCESS_CE), null, ACCOUNT_ENG)
	var/mob/living/carbon/human/engineer = make_person("Econ Audit Accomplice", null, null, ACCOUNT_ENG)
	var/datum/bank_account/accomplice = econ_account_of(engineer)
	TEST_ASSERT(engineering.pay_bonus(accomplice, part, chief), "Первая крупная премия")
	for(var/i in 1 to 50)
		var/datum/bank_account/other = make_account("Econ Audit Staff [i]")
		other.department_id = ACCOUNT_ENG
		TEST_ASSERT(engineering.pay_bonus(other, 1, chief), "Мелкая премия [i]")
	TEST_ASSERT(engineering.pay_bonus(accomplice, part, chief), "Вторая крупная премия")
	var/list/flags = open_flags_of_kind(accomplice, AUDIT_FLAG_BUDGET_SIPHON)
	TEST_ASSERT_EQUAL(length(flags), 1, "Отток замечен")
	var/datum/econ_audit_flag/flag = flags[1]
	TEST_ASSERT_EQUAL(flag.amount, part * 2, "Обе крупные премии в деле")

/// Лимит дел вытесняет только закрытые; открытые сверх лимита остаются.
/datum/unit_test/economy_audit/trim_keeps_open/Run()
	var/list/closed_flags = list()
	for(var/i in 1 to AUDIT_FLAGS_MAX + 2)
		var/datum/econ_audit_flag/flag = new
		flag.uid = -i
		if(i == 2 || i == 5)
			flag.closed = TRUE
			closed_flags += flag
		SSeconomy.audit_flags += flag
	SSeconomy.trim_audit_flags()
	TEST_ASSERT_EQUAL(length(SSeconomy.audit_flags), AUDIT_FLAGS_MAX, "Вытеснены два дела")
	for(var/datum/econ_audit_flag/flag as anything in closed_flags)
		TEST_ASSERT(!(flag in SSeconomy.audit_flags), "Вытеснено закрытое дело")
	for(var/i in 1 to 3)
		SSeconomy.audit_flags += new /datum/econ_audit_flag
	SSeconomy.trim_audit_flags()
	TEST_ASSERT_EQUAL(length(SSeconomy.audit_flags), AUDIT_FLAGS_MAX + 3, "Открытые дела не вытесняются")
	TEST_ASSERT(SSeconomy.audit_flags_overflow_logged, "Переполнение отмечено в логе")
	SSeconomy.audit_flags_overflow_logged = FALSE

/// Все майнеры вместе зачисляют на один счёт не больше потолка за тик экономики, с личного дохода удерживается налог; в новом тике платят снова.
/datum/unit_test/economy_audit/cryptominer_cap/Run()
	var/datum/bank_account/personal = econ_account_of(make_person("Econ Audit Miner Cap"))
	var/obj/machinery/cryptominer/syndie/first = allocate(/obj/machinery/cryptominer/syndie)
	var/obj/machinery/cryptominer/syndie/second = allocate(/obj/machinery/cryptominer/syndie)
	first.pay_me = personal
	second.pay_me = personal
	SSeconomy.tax_rate = 10
	var/cap = SSeconomy.settings.crypto_cap_per_tick
	var/before = personal.account_balance
	for(var/i in 1 to cap)
		first.produce_points(1)
		second.produce_points(1)
	var/gained = personal.account_balance - before
	TEST_ASSERT_EQUAL(SSeconomy.crypto_paid["[personal.account_id]"], cap, "Майнеры зачислили на счёт не ровно потолок")
	TEST_ASSERT(gained > 0 && gained < cap, "С дохода майнера не удержан налог или доход не пришёл: [gained] из [cap]")
	var/saved_fire_count = SSeconomy.fire_count
	SSeconomy.fire_count++
	var/next_before = personal.account_balance
	first.produce_points(1)
	SSeconomy.fire_count = saved_fire_count
	TEST_ASSERT(personal.account_balance > next_before, "В новом тике экономики майнер не платит")
