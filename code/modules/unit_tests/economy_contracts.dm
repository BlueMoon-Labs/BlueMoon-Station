/// Снимает контракты, появившиеся после снимка before.
/proc/econ_test_drop_new_contracts(list/before)
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts() - before)
		qdel(contract)

/// Убирает доски отделов на время теста, чтобы контракты не платили отделам сверх проверяемого.
/proc/econ_test_stash_contracts()
	. = list()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		.[id] = department.contracts
		department.contracts = list()

/proc/econ_test_restore_contracts(list/stash)
	for(var/id in stash)
		var/datum/economy_department/department = SSeconomy.departments[id]
		var/list/during_test = department.contracts
		department.contracts = stash[id]
		for(var/datum/econ_contract/contract as anything in during_test)
			qdel(contract)
	SSeconomy.contract_demand.Cut()

/// После обновления у каждого станционного отдела, кроме командования, есть контракты.
/datum/unit_test/economy_contracts_generated/Run()
	SSeconomy.refresh_contracts(force = TRUE)
	for(var/id in list(ACCOUNT_SEC, ACCOUNT_ENG, ACCOUNT_MED, ACCOUNT_SCI, ACCOUNT_CAR, ACCOUNT_SRV, ACCOUNT_CIV))
		var/datum/economy_department/department = SSeconomy.get_department(id)
		TEST_ASSERT(length(department.contracts) >= 1, "Нет контрактов у [id]")
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	TEST_ASSERT_EQUAL(length(command.contracts), 0, "У командования контрактов нет")

/// Номера выдаются, только если на станции стоит пресс.
/datum/unit_test/economy_contracts_plates_need_press
	var/list/hidden_presses = list()

/datum/unit_test/economy_contracts_plates_need_press/Destroy()
	for(var/obj/machinery/plate_press/press as anything in hidden_presses)
		press.forceMove(hidden_presses[press])
	hidden_presses = null
	return ..()

/datum/unit_test/economy_contracts_plates_need_press/Run()
	for(var/obj/machinery/plate_press/press in GLOB.machines)
		if(is_station_level(press.z))
			hidden_presses[press] = press.loc
			press.moveToNullspace()
	var/datum/bounty/item/security/plates/plates = allocate(/datum/bounty/item/security/plates)
	TEST_ASSERT(!plates.econ_available(), "Номера доступны без пресса на станции")
	TEST_ASSERT(!SSeconomy.pick_bounty(list(/datum/bounty/item/security/plates)), "Доска выдала номера без пресса")
	TEST_ASSERT(!try_add_bounty(plates), "Особый заказ на номера выставлен без пресса")
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "На станции нет свободной клетки")
	allocate(/obj/machinery/plate_press, station_turf)
	TEST_ASSERT(plates.econ_available(), "Номера недоступны при прессе на станции")

/// Контракт деятельности засчитывается по записям работы взявшего и платит отделу и исполнителю.
/datum/unit_test/economy_work/activity_contract/Run()
	setup_pair()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/econ_contract/activity/contract = new /datum/econ_contract/activity/medical_discharges(ACCOUNT_MED)
	contract.target = 2
	medical.contracts += contract
	TEST_ASSERT(contract.take(performer_account), "Взят")
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_DISCHARGE_LIGHT, 1, performer)
	TEST_ASSERT(!contract.completed, "Один из двух")
	var/before = performer_account.account_balance
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_DISCHARGE_LIGHT, 1, performer)
	TEST_ASSERT(contract.completed, "Выполнен")
	TEST_ASSERT(performer_account.account_balance - before >= round(contract.reward * SSeconomy.settings.contract_performer_share / 100) - round(contract.reward * SSeconomy.tax_rate / 100), "Доля исполнителя")
	TEST_ASSERT(!(contract in medical.contracts), "Снят с доски")

/// Контракты общей работы отдела (энергия, руда) не платят бюджету второй раз за уже оплаченную работу: награда целиком уходит людям.
/datum/unit_test/economy_work/department_work_contract/Run()
	var/datum/bank_account/member = new("econ_test_engineer")
	var/list/contract_departments = list(/datum/econ_contract/activity/engineering_export = ACCOUNT_ENG, /datum/econ_contract/activity/cargo_ore = ACCOUNT_CAR)
	for(var/contract_type in contract_departments)
		var/datum/econ_contract/activity/contract = new contract_type(contract_departments[contract_type])
		var/datum/economy_department/department = SSeconomy.get_department(contract.department_id)
		department.contracts += contract
		member.department_id = contract.department_id
		econ_test_set_balance(member, 0)
		var/list/shares = contract.reward_shares(contract.payout())
		var/to_people = 0
		for(var/datum/bank_account/account as anything in shares)
			to_people += shares[account]
		TEST_ASSERT(shares[member] > 0, "[contract_type]: сотрудник на смене без доли")
		TEST_ASSERT(contract.payout() - to_people < length(shares), "[contract_type]: людям [to_people] из [contract.payout()]")
		var/saved_budget = department.account.account_balance
		var/price = SSeconomy.settings.work_prices[contract.work_type]
		var/paid = SSeconomy.record_work(contract.department_id, contract.work_type, CEILING(contract.target / price, 1))
		TEST_ASSERT(contract.completed, "[contract_type] не выполнен")
		TEST_ASSERT_EQUAL(department.account.account_balance - saved_budget, paid, "[contract_type] заплатил бюджету сверх оплаты работы")
		TEST_ASSERT(member.account_balance > 0, "[contract_type] не заплатил сотруднику")
		econ_test_set_balance(department.account, saved_budget)
	qdel(member)

/// Чужая работа, работа другого отдела и другого типа взятый контракт деятельности не двигают.
/datum/unit_test/economy_work/activity_contract_filters/Run()
	setup_pair()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/econ_contract/activity/contract = new /datum/econ_contract/activity/medical_surgeries(ACCOUNT_MED)
	medical.contracts += contract
	TEST_ASSERT(contract.take(performer_account), "Взят")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	var/datum/bank_account/service = SSeconomy.get_dep_account(ACCOUNT_SRV)
	var/saved_service = service.account_balance
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, stranger)
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_REVIVE, 1, performer)
	SSeconomy.record_work(ACCOUNT_SRV, WORK_MED_SURGERY, 1, performer)
	econ_test_set_balance(service, saved_service)
	TEST_ASSERT_EQUAL(contract.progress, 0, "Засчитана чужая или не та работа")
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, performer)
	TEST_ASSERT_EQUAL(contract.progress, 1, "Своя операция засчитана")
	qdel(contract)

/// Контракт поставки засчитывается отгрузкой подходящего предмета.
/datum/unit_test/economy_delivery_contract/Run()
	var/datum/economy_department/civilian = SSeconomy.get_department(ACCOUNT_CIV)
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_CIV, new /datum/bounty/item/assistant/scooter)
	civilian.contracts.Insert(1, contract)
	var/datum/bounty/item/wanted = contract.bounty
	var/wanted_type = wanted.wanted_types[1]
	var/obj/thing = allocate(wanted_type)
	var/before = civilian.account.account_balance
	SSeconomy.contract_demand.Cut()
	var/expected = contract.payout()
	var/saved_modifier = SSeconomy.bounty_modifier
	SSeconomy.bounty_modifier = 2
	var/doubled = contract.payout()
	SSeconomy.bounty_modifier = 1
	var/saved_mult = SSeconomy.settings.contract_delivery_mult
	SSeconomy.settings.contract_delivery_mult = 0.25
	var/halved = contract.payout()
	SSeconomy.settings.contract_delivery_mult = saved_mult
	SSeconomy.bounty_modifier = saved_modifier
	var/civilian_mult = SSeconomy.settings.contract_civilian_mult
	var/datum/econ_contract/delivery/security_order = new(ACCOUNT_SEC, new /datum/bounty/item/assistant/scooter)
	var/security_payout = security_order.payout()
	qdel(security_order)
	TEST_ASSERT(econ_contracts_ship(thing), "Предмет засчитан")
	TEST_ASSERT(contract.completed, "Выполнен (самокат нужен один)")
	TEST_ASSERT(QDELETED(thing), "Засчитанный предмет уходит")
	TEST_ASSERT_EQUAL(civilian.account.account_balance - before, expected, "Без взявшего вся награда отделу")
	econ_test_set_balance(civilian.account, before)
	SSeconomy.contract_demand.Cut()
	TEST_ASSERT_EQUAL(doubled, round(contract.reward * 2 * saved_mult * civilian_mult), "Модификатор наград применяется к выплате")
	TEST_ASSERT_EQUAL(halved, round(contract.reward * 0.25 * civilian_mult), "Множитель contract_delivery_mult применяется к выплате")
	TEST_ASSERT(civilian_mult < 1, "Гражданские поделки не дешевле остальных заказов по умолчанию")
	TEST_ASSERT_EQUAL(expected, round(contract.reward * saved_mult * civilian_mult), "Гражданский заказ без множителя поделок")
	TEST_ASSERT_EQUAL(security_payout, round(contract.reward * saved_mult), "Множитель поделок задел заказ не гражданского отдела")

/// Пять искусственных блюспейс-кристаллов закрывают контракт Synthetic Bluespace Crystals.
/datum/unit_test/economy_delivery_contract_artificial_crystals/Run()
	var/datum/economy_department/science = SSeconomy.get_department(ACCOUNT_SCI)
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_SCI, new /datum/bounty/item/science/fakecrystals)
	science.contracts.Insert(1, contract)
	var/saved_balance = science.account.account_balance
	SSeconomy.contract_demand.Cut()
	var/obj/item/stack/ore/bluespace_crystal/artificial/crystals = allocate(/obj/item/stack/ore/bluespace_crystal/artificial, run_loc_floor_bottom_left, 5)
	TEST_ASSERT(econ_contracts_ship(crystals), "Искусственные кристаллы не засчитаны")
	TEST_ASSERT(contract.completed, "Контракт на пять кристаллов не выполнен")
	econ_test_set_balance(science.account, saved_balance)
	SSeconomy.contract_demand.Cut()

/// Взятый срочный контракт, не выполненный к сроку, снимается при обновлении.
/datum/unit_test/economy_contract_expiry/Run()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/datum/econ_contract/activity/contract = new /datum/econ_contract/activity/service_dishes(ACCOUNT_SRV)
	contract.urgent = TRUE
	contract.deadline = world.time - 1
	service.contracts += contract
	SSeconomy.refresh_contracts()
	TEST_ASSERT(!(contract in service.contracts), "Просроченный снят")

/// Один взятый контракт на счёт, взятая поставка получает срок, контракт всего отдела не берётся, удалённый счёт освобождает контракт.
/datum/unit_test/economy_contract_take_rules/Run()
	var/datum/economy_department/civilian = SSeconomy.get_department(ACCOUNT_CIV)
	var/datum/econ_contract/first = new /datum/econ_contract/delivery(ACCOUNT_CIV, new /datum/bounty/item/assistant/scooter)
	var/datum/econ_contract/second = new /datum/econ_contract/activity/service_cleaning(ACCOUNT_SRV)
	var/datum/econ_contract/department_only = new /datum/econ_contract/activity/engineering_export(ACCOUNT_ENG)
	civilian.contracts += first
	var/datum/bank_account/account = new("econ_test_taker")
	TEST_ASSERT_EQUAL(first.deadline, 0, "У невзятой поставки срока нет")
	var/taken_from = world.time
	TEST_ASSERT(first.take(account), "Первый взят")
	TEST_ASSERT(first.deadline >= taken_from + ECON_CONTRACT_TAKEN_TIME && first.deadline <= world.time + ECON_CONTRACT_TAKEN_TIME, "Взятая поставка получила срок [ECON_CONTRACT_TAKEN_TIME], а не [first.deadline - taken_from]")
	TEST_ASSERT(!second.take(account), "Второй тем же счётом не взят")
	TEST_ASSERT(!department_only.take(account), "Контракт отдела не берётся")
	var/datum/bank_account/visitor = new("econ_test_visitor")
	visitor.offstation = TRUE
	TEST_ASSERT(!second.take(visitor), "Счёт вне станции контракт не берёт")
	qdel(visitor)
	qdel(account)
	TEST_ASSERT_NULL(first.taker, "Удалённый счёт снят с контракта")
	qdel(first)
	qdel(second)
	qdel(department_only)

/datum/unit_test/economy_special_contract
	var/list/contracts_before

/datum/unit_test/economy_special_contract/Destroy()
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts() - contracts_before)
		if(contract.pinned)
			qdel(contract)
	return ..()

/// Особый заказ ЦК переживает ротацию и не занимает место обычного контракта.
/datum/unit_test/economy_special_contract/Run()
	contracts_before = SSeconomy.all_contracts()
	TEST_ASSERT(try_add_bounty(new /datum/bounty/item/hk47_core), "Заказ выставлен")
	TEST_ASSERT(!try_add_bounty(new /datum/bounty/item/hk47_core), "Второй такой же не выставляется")
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/datum/econ_contract/delivery/special
	for(var/datum/econ_contract/delivery/contract in cargo.contracts)
		if(istype(contract.bounty, /datum/bounty/item/hk47_core))
			special = contract
	TEST_ASSERT_NOTNULL(special, "Заказ на ядро у снабжения")
	TEST_ASSERT(!special.takeable, "Особый заказ не берут")
	SSeconomy.refresh_contracts(force = TRUE)
	TEST_ASSERT(special in cargo.contracts, "Ротация не сняла особый заказ")
	var/regular = 0
	for(var/datum/econ_contract/contract as anything in cargo.contracts)
		if(!contract.pinned)
			regular++
	TEST_ASSERT_EQUAL(regular, SSeconomy.settings.contracts_per_department, "Обычных контрактов полный набор")

/// Настройки контрактов: значения из JSON, нулевая ротация и доля выше 100% отвергаются.
/datum/unit_test/economy_contract_settings/Run()
	var/path = "data/unit_test_economy_contracts.json"
	fdel(path)
	text2file("{\"settings\": {\"contract_rotation_ticks\": 0, \"contract_performer_share\": 101, \"contract_urgent_mult\": 2, \"contracts_per_department\": 2}}", path)
	var/datum/economy_settings/settings = new
	var/list/errors = settings.load(path)
	fdel(path)
	TEST_ASSERT_EQUAL(length(errors), 2, "Ошибки: ротация и доля ([jointext(errors, "; ")])")
	TEST_ASSERT_EQUAL(settings.contract_rotation_ticks, initial(settings.contract_rotation_ticks), "Нулевая ротация принята")
	TEST_ASSERT_EQUAL(settings.contract_performer_share, initial(settings.contract_performer_share), "Доля выше 100% принята")
	TEST_ASSERT_EQUAL(settings.contract_urgent_mult, 2, "Множитель срочности из JSON")
	TEST_ASSERT_EQUAL(settings.contracts_per_department, 2, "Число контрактов из JSON")

/datum/unit_test/economy_contract_incident
	var/list/stashed_contracts
	var/saved_started
	var/saved_budget
	var/list/saved_baseline
	var/list/saved_ready
	/// Щиток -> заряд его батареи до теста
	var/list/darkened = list()
	/// Щиток -> его operating до теста
	var/list/switched = list()
	/// Щитки, которым тест устроил сбой сети
	var/list/failed = list()

/datum/unit_test/economy_contract_incident/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	saved_started = SSeconomy.contracts_started
	var/datum/economy_department/engineering/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	saved_budget = engineering.account.account_balance
	saved_baseline = engineering.incident_baseline
	saved_ready = engineering.incident_ready_at
	engineering.incident_baseline = list()
	engineering.incident_ready_at = list()

/datum/unit_test/economy_contract_incident/Destroy()
	for(var/obj/machinery/power/apc/apc as anything in darkened)
		apc.cell?.charge = darkened[apc]
	for(var/obj/machinery/power/apc/apc as anything in switched)
		apc.operating = switched[apc]
		apc.update()
	for(var/obj/machinery/power/apc/apc as anything in failed)
		apc.failure_timer = 0
		apc.update()
	darkened = null
	switched = null
	failed = null
	econ_test_restore_contracts(stashed_contracts)
	var/datum/economy_department/engineering/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	engineering.incident_baseline = saved_baseline
	engineering.incident_ready_at = saved_ready
	econ_test_set_balance(engineering.account, saved_budget)
	SSeconomy.contracts_started = saved_started
	return ..()

/datum/unit_test/economy_contract_incident/proc/working_apcs()
	. = list()
	for(var/obj/machinery/power/apc/apc as anything in GLOB.apcs_list)
		if(is_station_level(apc.z) && apc.operating && !apc.failure_timer && apc.cell?.charge > 0 && !(apc.machine_stat & (BROKEN|MAINT)))
			. += apc

/datum/unit_test/economy_contract_incident/proc/no_incidents(datum/economy_department/engineering/engineering, why)
	for(var/kind in GLOB.econ_incident_kinds)
		var/datum/econ_contract/incident/incident = engineering.active_incident(kind)
		TEST_ASSERT_NULL(incident, "[why] выставили аварию \"[incident?.title]\": [incident?.desc]")

/// Авария питания: тик экономики с заметно большим числом тёмных щитков выставляет инженерии контракт без надбавки срочности, он закрывается сам, когда щитки снова под питанием, и платит отделу; мелкая поломка и пауза после аварии нового не дают.
/datum/unit_test/economy_contract_incident/Run()
	SSeconomy.contracts_started = TRUE
	var/datum/economy_department/engineering/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/list/working = working_apcs()
	var/list/damage = engineering.station_damage()
	var/normal = damage["outage_apcs"]
	engineering.check_incidents(damage)
	TEST_ASSERT_EQUAL(engineering.incident_baseline[ECON_INCIDENT_POWER], normal, "Первый тик не запомнил обычное число тёмных щитков")
	var/threshold = max(ECON_INCIDENT_POWER_MIN, round(damage["apcs"] * ECON_INCIDENT_MIN_SHARE))
	var/list/minor = damage.Copy()
	minor["outage_apcs"] = normal + threshold - 1
	engineering.check_incidents(minor)
	TEST_ASSERT_NULL(engineering.active_incident(ECON_INCIDENT_POWER), "Мелкая поломка выставила аварию")
	var/list/outage = damage.Copy()
	outage["outage_apcs"] = normal + threshold
	outage["outage_areas"] = list("Мостик" = 1, "Бар" = 2, "Кухня" = 1, "Склад" = 1)
	engineering.check_incidents(outage)
	var/datum/econ_contract/incident/incident = engineering.active_incident(ECON_INCIDENT_POWER)
	TEST_ASSERT_NOTNULL(incident, "Авария питания не выставлена")
	TEST_ASSERT(incident in engineering.contracts, "Авария не на доске инженерии")
	TEST_ASSERT(incident.deadline > world.time && !incident.takeable, "Авария без срока или берётся")
	TEST_ASSERT(!incident.occupies_slot(), "Авария заняла место обычного контракта")
	TEST_ASSERT_EQUAL(incident.reward, round(incident.needed() * SSeconomy.settings.contract_incident_unit_reward, ECON_CONTRACT_REWARD_STEP), "Награда аварии - за каждую поломку")
	TEST_ASSERT_EQUAL(incident.payout(), incident.reward, "Аварии добавлена надбавка срочности")
	TEST_ASSERT(findtext(incident.desc, "Хуже всего: Бар, "), "Худший отсек не первым в описании: [incident.desc]")
	TEST_ASSERT_EQUAL(length(incident.worst_areas), ECON_INCIDENT_WORST_AREAS, "Названо не [ECON_INCIDENT_WORST_AREAS] худших отсека: [incident.desc]")
	var/to_darken = incident.limit() - normal + 1
	TEST_ASSERT(length(working) >= to_darken, "На станции [length(working)] исправных щитков, нужно [to_darken]")
	for(var/number in 1 to to_darken)
		var/obj/machinery/power/apc/apc = working[number]
		darkened[apc] = apc.cell.charge
		apc.cell.charge = 0
	incident.check()
	TEST_ASSERT(!incident.completed, "Авария закрылась, пока щитки без питания")
	TEST_ASSERT_EQUAL(incident.current, normal + to_darken, "Проверка не увидела тёмные щитки")
	var/obj/machinery/power/apc/first_dark = working[1]
	TEST_ASSERT(first_dark.area.name in incident.worst_areas, "Отсек тёмного щитка не назван: [incident.desc]")
	for(var/obj/machinery/power/apc/apc as anything in darkened)
		apc.cell.charge = darkened[apc]
	darkened.Cut()
	var/budget_before = engineering.account.account_balance
	incident.check()
	TEST_ASSERT(incident.completed, "Свет вернулся, а авария не закрыта")
	TEST_ASSERT(!(incident in engineering.contracts), "Закрытая авария осталась на доске")
	TEST_ASSERT(engineering.account.account_balance > budget_before, "Бюджет инженерии не получил награду аварии")
	TEST_ASSERT_EQUAL(engineering.incident_baseline[ECON_INCIDENT_POWER], normal, "Норма после аварии - не то, что осталось")
	engineering.check_incidents(outage)
	TEST_ASSERT_NULL(engineering.active_incident(ECON_INCIDENT_POWER), "Новая авария выставлена сразу после прошлой")

/// Сбой сети (Grid Check, блэкаут контрактора) и щитки, выключенные вручную, проходят сами и аварию не выставляют.
/datum/unit_test/economy_contract_incident/not_damage/Run()
	SSeconomy.contracts_started = TRUE
	var/datum/economy_department/engineering/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/list/working = working_apcs()
	var/list/damage = engineering.station_damage()
	engineering.check_incidents(damage)
	var/to_switch = max(ECON_INCIDENT_POWER_MIN, round(damage["apcs"] * ECON_INCIDENT_MIN_SHARE))
	TEST_ASSERT(length(working) >= to_switch, "На станции [length(working)] исправных щитков, нужно [to_switch]")
	for(var/number in 1 to to_switch)
		var/obj/machinery/power/apc/apc = working[number]
		switched[apc] = apc.operating
		apc.operating = FALSE
		apc.update()
	engineering.check_incidents(engineering.station_damage())
	no_incidents(engineering, "Выключатели на [to_switch] щитках")
	for(var/obj/machinery/power/apc/apc as anything in switched)
		apc.operating = switched[apc]
		apc.update()
	switched.Cut()
	power_fail(30, 120)
	for(var/obj/machinery/power/apc/apc as anything in GLOB.apcs_list)
		if(apc.failure_timer)
			failed += apc
	TEST_ASSERT(length(failed) >= to_switch, "Сбой сети задел [length(failed)] щитков")
	engineering.check_incidents(engineering.station_damage())
	no_incidents(engineering, "Сбой сети")

/datum/unit_test/economy_contract_incident/casualties
	var/saved_medical
	var/list/saved_medical_ready
	var/list/victims = list()

/datum/unit_test/economy_contract_incident/casualties/Destroy()
	for(var/mob/living/carbon/human/victim as anything in victims)
		victim.mock_client = null
	victims = null
	. = ..()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	if(!isnull(saved_medical))
		econ_test_set_balance(medical.account, saved_medical)
		medical.incident_ready_at = saved_medical_ready

/datum/unit_test/economy_contract_incident/casualties/proc/victim(turf/where, has_client = TRUE, dead = FALSE, offstation = FALSE)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, where)
	var/datum/bank_account/account = new("econ_test_victim")
	allocated += account
	account.offstation = offstation
	body.account_id = account.account_id
	if(has_client)
		body.mock_client = new /datum/client_interface()
		victims += body
	body.setOxyLoss(body.maxHealth + 10)
	if(dead)
		body.death()
	return body

/// Массовые пострадавшие: живые игроки экипажа в крите на станции выставляют медицине контракт без надбавки срочности, трупы, тела без игрока, гости и люди вне станции не в счёт; контракт закрывают выписки, долю получает выписавший медик, следующий - не раньше паузы.
/datum/unit_test/economy_contract_incident/casualties/Run()
	SSeconomy.contracts_started = TRUE
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	saved_medical = medical.account.account_balance
	saved_medical_ready = medical.incident_ready_at
	medical.incident_ready_at = list()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/before = econ_station_casualties()
	victim(station_turf, dead = TRUE)
	victim(station_turf, has_client = FALSE)
	victim(station_turf, offstation = TRUE)
	victim(run_loc_floor_bottom_left)
	for(var/number in 1 to ECON_CASUALTIES_MIN - 1)
		var/mob/living/carbon/human/body = victim(station_turf)
		TEST_ASSERT(body.InCritical(), "Пострадавший не в крите: здоровье [body.health], состояние [body.stat]")
	TEST_ASSERT_EQUAL(econ_station_casualties() - before, ECON_CASUALTIES_MIN - 1, "Посчитаны не только живые игроки экипажа в крите на станции")
	medical.on_economy_tick()
	TEST_ASSERT_NULL(medical.active_incident(ECON_INCIDENT_CASUALTIES), "Контракт выставлен ниже порога")
	victim(station_turf)
	medical.on_economy_tick()
	var/datum/econ_contract/incident/casualties/incident = medical.active_incident(ECON_INCIDENT_CASUALTIES)
	TEST_ASSERT_NOTNULL(incident, "Массовые пострадавшие не выставлены")
	TEST_ASSERT(!incident.takeable && !incident.occupies_slot(), "Контракт берётся или занимает место на доске")
	TEST_ASSERT_EQUAL(incident.payout(), incident.reward, "Надбавка срочности")
	TEST_ASSERT_EQUAL(incident.reward, round(incident.needed() * SSeconomy.settings.contract_incident_unit_reward, ECON_CONTRACT_REWARD_STEP), "Награда - за каждого пострадавшего")
	var/mob/living/carbon/human/medic = allocate(/mob/living/carbon/human, station_turf)
	var/datum/bank_account/medic_account = new("econ_test_medic")
	allocated += medic_account
	medic_account.department_id = ACCOUNT_MED
	medic.account_id = medic_account.account_id
	econ_test_set_balance(medic_account, 0)
	for(var/number in 1 to incident.needed() - 1)
		SSeconomy.record_work(ACCOUNT_MED, WORK_MED_DISCHARGE_CRIT, 1, medic)
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, medic)
	TEST_ASSERT(!incident.completed, "Контракт закрылся до последней выписки ([incident.progress_text()])")
	var/balance_before = medic_account.account_balance
	SSeconomy.record_work(ACCOUNT_MED, WORK_MED_DISCHARGE_LIGHT, 1, medic)
	TEST_ASSERT(incident.completed, "Выписки не закрыли контракт ([incident.progress_text()])")
	TEST_ASSERT(!(incident in medical.contracts), "Закрытый контракт остался на доске")
	TEST_ASSERT(medic_account.account_balance - balance_before >= round(incident.reward * SSeconomy.settings.contract_team_share / 100 * (100 - SSeconomy.tax_rate) / 100) - 1, "Выписавший медик не получил долю")
	medical.on_economy_tick()
	TEST_ASSERT_NULL(medical.active_incident(ECON_INCIDENT_CASUALTIES), "Новый контракт сразу после прошлого")

/datum/unit_test/economy_contract_relay_taken
	var/list/stashed_contracts
	var/saved_service
	var/list/contract_moves = list()

/datum/unit_test/economy_contract_relay_taken/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	var/datum/bank_account/service = SSeconomy.get_dep_account(ACCOUNT_SRV)
	saved_service = service.account_balance

/datum/unit_test/economy_contract_relay_taken/Destroy()
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	econ_test_restore_contracts(stashed_contracts)
	econ_test_set_balance(SSeconomy.get_dep_account(ACCOUNT_SRV), saved_service)
	return ..()

/datum/unit_test/economy_contract_relay_taken/proc/on_moved(datum/source, datum/bank_account/from, datum/bank_account/target, amount, reason, mob/actor)
	SIGNAL_HANDLER
	if(reason == ECON_CONTRACT)
		contract_moves[target] += 1

/// Взятый "Банкет" не снять, поэтому этапом эстафеты становится он сам: второй такой же контракт не выставляется, одна работа - одна выплата.
/datum/unit_test/economy_contract_relay_taken/Run()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/mob/living/carbon/human/cook = allocate(/mob/living/carbon/human)
	var/datum/bank_account/cook_account = new("econ_test_cook")
	allocated += cook_account
	cook_account.department_id = ACCOUNT_SRV
	cook.account_id = cook_account.account_id
	var/datum/econ_contract/activity/service_dishes/banquet = new(ACCOUNT_SRV)
	service.contracts += banquet
	TEST_ASSERT(banquet.take(cook_account), "Банкет не взят: [banquet.take_refusal(cook_account)]")
	var/list/template
	for(var/list/candidate as anything in GLOB.econ_relay_templates)
		var/list/stages = candidate["stages"]
		for(var/list/spec as anything in stages)
			if(spec["contract"] == banquet.type)
				template = candidate
	TEST_ASSERT_NOTNULL(template, "Нет эстафеты с банкетом")
	var/datum/econ_relay/relay = new(template)
	SSeconomy.relays += relay
	var/list/stages = template["stages"]
	for(var/number in 1 to length(stages))
		var/list/spec = stages[number]
		if(spec["contract"] == banquet.type)
			relay.stage = number - 1
	var/datum/econ_contract/stage_contract = relay.advance()
	TEST_ASSERT(stage_contract == banquet, "Этапом стал не взятый банкет, а [stage_contract?.type]")
	TEST_ASSERT(banquet.relay == relay, "Банкет не знает о своей эстафете")
	var/banquets = 0
	for(var/datum/econ_contract/activity/service_dishes/same in service.contracts)
		banquets++
	TEST_ASSERT_EQUAL(banquets, 1, "На доске два банкета")
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_moved))
	for(var/attempt in 1 to banquet.target)
		SSeconomy.record_work(ACCOUNT_SRV, WORK_SRV_DISH, 1, cook)
	TEST_ASSERT(banquet.completed, "Банкет не выполнен ([banquet.progress_text()])")
	TEST_ASSERT_EQUAL(contract_moves[cook_account], 1, "Одна работа заплатила повару [contract_moves[cook_account]] раз")

/datum/unit_test/economy_contract_mech_models
	var/list/stashed_contracts
	var/saved_science
	var/list/saved_mechs

/datum/unit_test/economy_contract_mech_models/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	var/datum/economy_department/science/science = SSeconomy.get_department(ACCOUNT_SCI)
	saved_science = science.account.account_balance
	saved_mechs = science.mechs_seen
	science.mechs_seen = list()

/datum/unit_test/economy_contract_mech_models/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	var/datum/economy_department/science/science = SSeconomy.get_department(ACCOUNT_SCI)
	econ_test_set_balance(science.account, saved_science)
	science.mechs_seen = saved_mechs
	return ..()

/datum/unit_test/economy_contract_mech_models/proc/build_ripley(turf/where, mob/living/builder)
	var/obj/item/mecha_parts/chassis/ripley/chassis = new(where)
	var/datum/component/construction/mecha/ripley/construction = chassis.AddComponent(/datum/component/construction/mecha/ripley)
	construction.spawn_result(builder)
	var/obj/vehicle/sealed/mecha/working/ripley/mech = locate() in where
	TEST_ASSERT_NOTNULL(mech, "Мех не собран")
	allocated += mech
	return mech

/// Наука получает плату за первого собранного на станции меха каждой модели за смену: второй такой же не оплачивается и не двигает контракт на технику.
/datum/unit_test/economy_contract_mech_models/Run()
	var/datum/economy_department/science/science = SSeconomy.get_department(ACCOUNT_SCI)
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/mob/living/carbon/human/roboticist = allocate(/mob/living/carbon/human, station_turf)
	var/before = science.account.account_balance
	var/obj/vehicle/sealed/mecha/first = build_ripley(station_turf, roboticist)
	TEST_ASSERT(science.account.account_balance > before, "Первый Ripley не оплачен")
	qdel(first)
	var/datum/econ_contract/activity/science_mechs/order = new(ACCOUNT_SCI)
	science.contracts += order
	before = science.account.account_balance
	var/obj/vehicle/sealed/mecha/second = build_ripley(station_turf, roboticist)
	qdel(second)
	TEST_ASSERT_EQUAL(science.account.account_balance, before, "Второй Ripley за смену оплачен")
	TEST_ASSERT_EQUAL(order.progress, 0, "Второй Ripley засчитан в контракт на технику")

/// Блюдо и коктейль, которые съело или выпило тело без игрока или труп, сервису не платят, а гость в номере без игрока не оплачивает поднос.
/datum/unit_test/economy_work/service/consumer_needs_player/Run()
	setup_service()
	var/before = budget.account_balance
	var/mob/living/carbon/human/sleeper = new_guest()
	sleeper.mock_client = null
	players -= sleeper
	var/obj/item/reagent_containers/food/snacks/dish = chef_dish(/obj/item/reagent_containers/food/snacks/meat/steak, 1)
	dish.attack(sleeper, sleeper)
	var/obj/item/reagent_containers/food/drinks/drinkingglass/glass = glass_of(/datum/reagent/consumable/ethanol/screwdrivercocktail)
	glass.attack(sleeper, sleeper)
	TEST_ASSERT(sleeper.reagents.has_reagent(/datum/reagent/consumable/ethanol/screwdrivercocktail), "Тело без игрока не отпило")
	var/mob/living/carbon/human/corpse = new_guest()
	corpse.death()
	econ_food_eaten(dish, corpse)
	econ_drink_consumed(glass_of(/datum/reagent/consumable/ethanol/screwdrivercocktail), corpse)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Сервису заплатили за тело без игрока или труп")
	TEST_ASSERT(!dish.econ_paid, "Блюдо помечено оплаченным")
	TEST_ASSERT(!econ_consumer_counts(sleeper) && !econ_consumer_counts(corpse), "Гость в номере без игрока или мёртвый оплачивает поднос")
	econ_food_eaten(dish, patient)
	TEST_ASSERT(budget.account_balance > before, "Живой игрок не оплатил блюдо")

/datum/unit_test/economy_contract_patrol
	var/list/stashed_contracts
	var/saved_security

/datum/unit_test/economy_contract_patrol/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	var/datum/bank_account/security = SSeconomy.get_dep_account(ACCOUNT_SEC)
	saved_security = security.account_balance

/datum/unit_test/economy_contract_patrol/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	econ_test_set_balance(SSeconomy.get_dep_account(ACCOUNT_SEC), saved_security)
	return ..()

/// Обход берёт только сотрудник СБ, бара в маршруте нет; засчитывается отсек, где он побывал в сознании и в игре, а пройдя все - контракт выполнен и оплачен. Отказ сбрасывает пройденное.
/datum/unit_test/economy_contract_patrol/Run()
	var/datum/economy_department/security = SSeconomy.get_department(ACCOUNT_SEC)
	var/datum/econ_contract/patrol/patrol = new(ACCOUNT_SEC)
	security.contracts += patrol
	TEST_ASSERT(patrol.postable(), "На станции нет общих отсеков для обхода")
	var/mob/living/carbon/human/officer = allocate(/mob/living/carbon/human)
	var/datum/bank_account/officer_account = new("econ_test_officer")
	allocated += officer_account
	officer_account.department_id = ACCOUNT_SEC
	officer.account_id = officer_account.account_id
	officer_account.bind_owner(officer)
	var/datum/bank_account/stranger = new("econ_test_stranger")
	allocated += stranger
	stranger.department_id = ACCOUNT_CIV
	TEST_ASSERT(findtext(patrol.take_refusal(stranger), "службы безопасности"), "Обход взял не сотрудник СБ")
	TEST_ASSERT(patrol.take(officer_account), "Сотрудник СБ не взял обход: [patrol.take_refusal(officer_account)]")
	var/list/route = patrol.route.Copy()
	for(var/area/hall as anything in route)
		TEST_ASSERT(!istype(hall, /area/service/bar), "В обходе бар: [hall.name]")
	var/area/first = route[1]
	officer.forceMove(locate(/turf/open) in first)
	patrol.check()
	TEST_ASSERT_EQUAL(patrol.visited(), 0, "Засчитан отсек, где тело обходчика без игрока")
	officer.mock_client = new /datum/client_interface()
	officer.set_stat(UNCONSCIOUS)
	patrol.check()
	TEST_ASSERT_EQUAL(patrol.visited(), 0, "Засчитан отсек, где обходчик без сознания")
	officer.set_stat(CONSCIOUS)
	patrol.check()
	TEST_ASSERT_EQUAL(patrol.visited(), 1, "Отсек обхода не засчитан")
	TEST_ASSERT(!findtext(patrol.desc, first.name), "Пройденный отсек остался в задании")
	TEST_ASSERT(patrol.drop(officer_account), "Отказ от начатого обхода")
	TEST_ASSERT(QDELETED(patrol), "После отказа пройденное не сбросилось и обход остался")
	COOLDOWN_RESET(officer_account, contract_drop_cooldown)
	var/datum/econ_contract/patrol/second = new(ACCOUNT_SEC)
	security.contracts += second
	TEST_ASSERT(second.take(officer_account), "Второй обход не взят")
	var/reward = second.payout()
	var/budget_before = security.account.account_balance
	for(var/area/hall as anything in second.route.Copy())
		officer.forceMove(locate(/turf/open) in hall)
		second.check()
	officer.mock_client = null
	TEST_ASSERT(second.completed, "Обход всех отсеков не закрыл контракт ([second.progress_text()])")
	TEST_ASSERT(officer_account.account_balance > 0, "Обходчику ничего не пришло")
	TEST_ASSERT_EQUAL(security.account.account_balance - budget_before, reward - round(reward * second.performer_share() / 100), "Остальное - бюджету СБ")

/datum/unit_test/economy_alien_organs_printed
	var/list/stashed_contracts
	var/saved_science

/datum/unit_test/economy_alien_organs_printed/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	var/datum/bank_account/science = SSeconomy.get_dep_account(ACCOUNT_SCI)
	saved_science = science.account_balance

/datum/unit_test/economy_alien_organs_printed/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	econ_test_set_balance(SSeconomy.get_dep_account(ACCOUNT_SCI), saved_science)
	return ..()

/// Заказ ЦК на органы ксеноморфов не закрыть органом из биопринтера станции, а пад объясняет почему; орган из тела засчитывается.
/datum/unit_test/economy_alien_organs_printed/Run()
	var/datum/economy_department/science = SSeconomy.get_department(ACCOUNT_SCI)
	var/datum/bounty/item/alien_organs/bounty = new
	bounty.required_count = 1
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_SCI, bounty)
	science.contracts += contract
	var/datum/design/design = SSresearch.techweb_design_by_id("plasmavessel_alt")
	TEST_ASSERT_NOTNULL(design, "Нет чертежа плазменного мешка биопринтера")
	var/obj/item/organ/printed = allocate(design.build_path)
	// Так do_print() метит всё, что печатают лейты и биопринтер
	econ_mark_station_made(printed, design.materials)
	TEST_ASSERT(!econ_contracts_ship(printed), "Напечатанный орган ксеноморфа засчитан")
	TEST_ASSERT(!contract.completed, "Заказ закрыт напечатанным органом")
	var/list/notes = econ_contracts_shortfalls(printed)
	TEST_ASSERT(length(notes) && findtext(notes[1], "напечатан"), "Пад не объясняет, почему орган не принят: [jointext(notes, "; ")]")
	var/obj/item/organ/alien/plasmavessel/harvested = allocate(/obj/item/organ/alien/plasmavessel)
	TEST_ASSERT(econ_contracts_ship(harvested), "Орган из тела не засчитан")
	TEST_ASSERT(contract.completed, "Заказ на органы не закрыт органом из тела")

/datum/unit_test/economy_contract_machines
	abstract_type = /datum/unit_test/economy_contract_machines
	var/datum/economy_department/civilian
	var/saved_civilian
	var/datum/bank_account/taker_account
	var/mob/living/carbon/human/user
	var/list/contracts_before
	var/list/stashed_contracts
	var/saved_repeat_limit

/// Тесты пульта сдают один и тот же самокат много раз: лимит повторов на человека проверяет свой тест.
/datum/unit_test/economy_contract_machines/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	saved_repeat_limit = SSeconomy.settings.contract_repeat_per_person
	SSeconomy.settings.contract_repeat_per_person = 0

/datum/unit_test/economy_contract_machines/proc/setup()
	civilian = SSeconomy.get_department(ACCOUNT_CIV)
	saved_civilian = civilian.account.account_balance
	contracts_before = SSeconomy.all_contracts()
	user = allocate(/mob/living/carbon/human)
	taker_account = new("econ_test_contractor")
	user.account_id = taker_account.account_id

/datum/unit_test/economy_contract_machines/Destroy()
	SSeconomy.settings.contract_repeat_per_person = saved_repeat_limit
	econ_test_drop_new_contracts(contracts_before)
	econ_test_restore_contracts(stashed_contracts)
	if(civilian)
		econ_test_set_balance(civilian.account, saved_civilian)
	civilian = null
	QDEL_NULL(taker_account)
	return ..()

/datum/unit_test/economy_contract_machines/proc/post_scooter_contract()
	return post_contract(/datum/bounty/item/assistant/scooter)

/datum/unit_test/economy_contract_machines/proc/post_contract(bounty_type)
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_CIV, new bounty_type)
	civilian.contracts.Insert(1, contract)
	return contract

/// Ошибка манифеста иногда удаляет предмет из ящика, поэтому несколько попыток.
/datum/unit_test/economy_contract_machines/proc/buy_toolbox(turf/where)
	for(var/attempt in 1 to 5)
		var/datum/supply_order/order = new(SSshuttle.supply_packs[/datum/supply_pack/goody/toolbox], "econ_test", "econ_test", "econ_test", "econ_test")
		var/obj/structure/closet/crate/crate = order.generate(where)
		qdel(order)
		allocated += crate
		var/obj/item/storage/toolbox/toolbox = locate() in crate
		if(toolbox)
			return toolbox

/datum/unit_test/economy_contract_machines/proc/click(obj/machinery/console, action, list/params = list())
	var/datum/tgui/window = allocate(/datum/tgui, user, console, "contracts")
	window.status = UI_INTERACTIVE
	usr = user
	console.ui_act(action, params, window)
	usr = null

/datum/unit_test/economy_contract_machines/proc/build_pad(turf/where)
	var/obj/machinery/piratepad/civilian/pad = allocate(/obj/machinery/piratepad/civilian, where)
	pad.warmup_time = 0
	var/obj/machinery/computer/piratepad_control/civilian/console = allocate(/obj/machinery/computer/piratepad_control/civilian, where)
	var/obj/item/multitool/tool = allocate(/obj/item/multitool)
	pad.multitool_act(user, tool)
	console.multitool_act(user, tool)
	TEST_ASSERT(console.linked_pad() == pad, "Пульт связан с падом мультитулом")
	return console

/// Пункт подработки на станции: контракт берётся с пульта, отправка с пада засчитывает поставку и платит взявшему долю.
/datum/unit_test/economy_contract_machines/pad_on_station/Run()
	setup()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/computer/piratepad_control/civilian/console = build_pad(station_turf)
	var/obj/machinery/piratepad/pad = console.linked_pad()
	var/datum/econ_contract/delivery/contract = post_scooter_contract()
	var/list/data = console.ui_data(user)
	TEST_ASSERT_EQUAL(length(data["contracts"]), length(SSeconomy.all_contracts()), "Пульт показывает все контракты")
	TEST_ASSERT_EQUAL(data["my_account"], taker_account.account_id, "Пульт знает счёт пользователя")
	click(console, "take", list("uid" = contract.uid))
	TEST_ASSERT(contract.taker == taker_account, "Контракт взят с пульта")
	var/obj/scooter = allocate(/obj/vehicle/ridden/scooter, get_turf(pad))
	var/obj/item/stack/sheet/metal/leftover = allocate(/obj/item/stack/sheet/metal, get_turf(pad))
	var/civilian_before = civilian.account.account_balance
	var/reward = contract.payout()
	click(console, "send")
	TEST_ASSERT(QDELETED(scooter), "Самокат ушёл ЦК")
	TEST_ASSERT(!QDELETED(leftover) && leftover.loc == get_turf(pad), "Лишнее осталось на паде")
	TEST_ASSERT(contract.completed, "Контракт выполнен")
	var/share = round(reward * SSeconomy.settings.contract_performer_share / 100)
	TEST_ASSERT_EQUAL(taker_account.account_balance, share - round(share * SSeconomy.tax_rate / 100), "Доля взявшего за вычетом налога")
	TEST_ASSERT_EQUAL(civilian.account.account_balance - civilian_before, reward - share, "Остальное отделу")

/// Контракт на баллон газа говорит, сколько газа нужно; баллон с недобором пад не отправляет и пишет, сколько газа в нём есть из нужного; полный уходит.
/datum/unit_test/economy_contract_machines/gas_tank_shortfall/Run()
	setup()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/computer/piratepad_control/civilian/console = build_pad(station_turf)
	var/obj/machinery/piratepad/pad = console.linked_pad()
	var/datum/econ_contract/delivery/contract = post_contract(/datum/bounty/item/engineering/gas/tritium_tank)
	var/datum/bounty/item/engineering/gas/bounty = contract.bounty
	TEST_ASSERT(findtext(contract.desc, "[bounty.moles_required] моль трития") && findtext(contract.desc, "кПа"), "Описание называет, сколько газа нужно: [contract.desc]")
	var/obj/item/tank/internals/oxygen/empty/tank = allocate(/obj/item/tank/internals/oxygen/empty, get_turf(pad))
	tank.air_contents.set_moles(GAS_TRITIUM, 8)
	click(console, "recalc")
	TEST_ASSERT(findtext(console.status_report, "трития 8 из [bounty.moles_required] моль"), "Пульт говорит, сколько газа в баллоне: [console.status_report]")
	click(console, "send")
	TEST_ASSERT(!QDELETED(tank) && !contract.completed, "Баллон с недобором остался на паде")
	TEST_ASSERT(findtext(console.status_report, "Не хватает"), "После отправки пульт объясняет отказ: [console.status_report]")
	tank.air_contents.set_moles(GAS_TRITIUM, bounty.moles_required + 1)
	click(console, "send")
	TEST_ASSERT(QDELETED(tank), "Полный баллон ушёл ЦК: [console.status_report]")
	TEST_ASSERT(contract.completed, "Контракт на газ выполнен")

/// Контракт на другой газ впереди на доске не прячет пояснение к газу, который в баллоне есть.
/datum/unit_test/economy_contract_machines/gas_shortfall_other_gas_first/Run()
	setup()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/computer/piratepad_control/civilian/console = build_pad(station_turf)
	var/obj/machinery/piratepad/pad = console.linked_pad()
	var/datum/econ_contract/delivery/tritium = post_contract(/datum/bounty/item/engineering/gas/tritium_tank)
	var/datum/econ_contract/delivery/bz = post_contract(/datum/bounty/item/engineering/gas/bz_tank)
	var/list/contracts = econ_delivery_contracts_for(null)
	TEST_ASSERT(contracts.Find(bz) < contracts.Find(tritium), "Контракт на BZ идёт раньше контракта на тритий")
	var/obj/item/tank/internals/oxygen/empty/tank = allocate(/obj/item/tank/internals/oxygen/empty, get_turf(pad))
	tank.air_contents.set_moles(GAS_TRITIUM, 8)
	click(console, "recalc")
	TEST_ASSERT(findtext(console.status_report, "трития 8 из"), "Пульт называет тритий в баллоне: [console.status_report]")
	TEST_ASSERT(!findtext(console.status_report, "BZ 0 из"), "Пульт не подменяет тритий пустым BZ: [console.status_report]")
	tank.air_contents.set_moles(GAS_TRITIUM, 0)
	click(console, "recalc")
	TEST_ASSERT(findtext(console.status_report, "Не хватает"), "Для пустого баллона пульт всё равно поясняет, чего ждут: [console.status_report]")

/// Пад подработки вне станции ничего не засчитывает.
/datum/unit_test/economy_contract_machines/pad_off_station/Run()
	setup()
	TEST_ASSERT(!is_station_level(run_loc_floor_bottom_left.z), "Тестовая резервация не станция")
	var/obj/machinery/computer/piratepad_control/civilian/console = build_pad(run_loc_floor_bottom_left)
	var/datum/econ_contract/delivery/contract = post_scooter_contract()
	var/obj/scooter = allocate(/obj/vehicle/ridden/scooter, run_loc_floor_bottom_left)
	click(console, "send")
	TEST_ASSERT(!QDELETED(scooter), "Самокат остался")
	TEST_ASSERT(!contract.completed, "Контракт не засчитан")
	TEST_ASSERT(findtext(console.status_report, "вне станции"), "Пульт объясняет отказ: [console.status_report]")

/// Консоль контрактов карго показывает доску всех отделов и даёт взять контракт.
/datum/unit_test/economy_contract_machines/cargo_console/Run()
	setup()
	var/obj/machinery/computer/bounty/console = allocate(/obj/machinery/computer/bounty)
	var/datum/econ_contract/delivery/contract = post_scooter_contract()
	var/list/data = console.ui_data(user)
	var/list/shown = list()
	for(var/list/entry as anything in data["contracts"])
		shown += entry["uid"]
	TEST_ASSERT(contract.uid in shown, "Новый контракт на доске карго")
	TEST_ASSERT_EQUAL(length(shown), length(SSeconomy.all_contracts()), "Доска показывает все отделы")
	click(console, "take", list("uid" = contract.uid))
	TEST_ASSERT(contract.taker == taker_account, "Контракт взят с консоли карго")

/// Отгрузка шаттлом: предмет по контракту засчитан и не продан, остальное из ящика продано.
/datum/unit_test/economy_cargo/contract_shuttle/Run()
	setup()
	var/datum/economy_department/civilian = SSeconomy.get_department(ACCOUNT_CIV)
	var/saved_civilian = civilian.account.account_balance
	var/turf/open/floor = shuttle_floor()
	TEST_ASSERT_NOTNULL(floor, "Есть пол шаттла снабжения")
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_CIV, new /datum/bounty/item/assistant/scooter)
	civilian.contracts.Insert(1, contract)
	SSeconomy.contract_demand.Cut()
	var/expected = contract.payout()
	var/obj/structure/closet/crate/crate = allocate(/obj/structure/closet/crate, floor)
	var/obj/scooter = new /obj/vehicle/ridden/scooter(crate)
	new /obj/item/stack/sheet/metal/fifty(crate)
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(scooter), "Самокат ушёл по контракту")
	TEST_ASSERT(contract.completed, "Контракт выполнен шаттлом")
	TEST_ASSERT(QDELETED(crate), "Ящик продан")
	TEST_ASSERT_EQUAL(length(moved_to(cargo, ECON_EXPORT)), 1, "Металл продан снабжением")
	TEST_ASSERT_EQUAL(civilian.account.account_balance - saved_civilian, expected, "Награда отделу-заказчику")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "контрактам NT"), "ЦК сообщает о приёме: [SSshuttle.centcom_message]")
	econ_test_set_balance(civilian.account, saved_civilian)

/// Ротация снимает старые невзятые контракты без прогресса, а начатую поставку и свежий контракт оставляет.
/datum/unit_test/economy_contract_machines/rotation_by_age/Run()
	setup()
	var/rotation_age = SSeconomy.contract_rotation_age()
	var/datum/econ_contract/delivery/started = post_contract(/datum/bounty/item/assistant/toolbox)
	var/datum/econ_contract/delivery/stale = post_contract(/datum/bounty/item/assistant/scooter)
	var/datum/econ_contract/delivery/fresh = post_contract(/datum/bounty/item/assistant/soap)
	started.created = world.time - rotation_age - 1
	stale.created = world.time - rotation_age - 1
	var/obj/item/storage/toolbox/toolbox = allocate(/obj/item/storage/toolbox/mechanical)
	TEST_ASSERT(econ_contracts_ship(toolbox), "Ящик для инструментов засчитан")
	TEST_ASSERT(started.has_progress() && !started.completed, "Поставка начата, но не закрыта")
	var/list/entry = fresh.ui_entry()
	TEST_ASSERT(abs(entry["rotates_in"] - rotation_age / (1 SECONDS)) <= 1, "Доска показывает время до смены: [entry["rotates_in"]]")
	SSeconomy.refresh_contracts()
	TEST_ASSERT(started in civilian.contracts, "Начатая поставка пережила ротацию")
	TEST_ASSERT(fresh in civilian.contracts, "Свежий контракт не снят раньше своего возраста")
	TEST_ASSERT(QDELETED(stale), "Старый ничей контракт снят")
	SSeconomy.refresh_contracts(force = TRUE)
	TEST_ASSERT(started in civilian.contracts, "Принудительная ротация не снимает начатую поставку")
	entry = started.ui_entry()
	TEST_ASSERT(entry["started"], "Доска помечает начатую поставку")
	TEST_ASSERT(abs(entry["rotates_in"] - (rotation_age * ECON_CONTRACT_STALE_ROTATIONS - rotation_age - 1) / (1 SECONDS)) <= 1, "Доска показывает, когда снимется начатая поставка: [entry["rotates_in"]]")
	started.created = world.time - rotation_age * ECON_CONTRACT_STALE_ROTATIONS - 1
	SSeconomy.refresh_contracts()
	TEST_ASSERT(QDELETED(started), "Начатая ничья поставка снята через [ECON_CONTRACT_STALE_ROTATIONS] возраста ротации")

/// Купленное через снабжение (ящик пака и сборный ящик мелочи) не засчитывается, такой же предмет из другого источника засчитывается.
/datum/unit_test/economy_contract_machines/imported_refused/Run()
	setup()
	var/datum/econ_contract/delivery/contract = post_contract(/datum/bounty/item/assistant/toolbox)
	var/obj/item/storage/toolbox/bought = buy_toolbox(run_loc_floor_bottom_left)
	TEST_ASSERT_NOTNULL(bought, "В ящике пака есть ящик для инструментов")
	TEST_ASSERT(bought.econ_imported, "Купленное помечено")
	TEST_ASSERT(!econ_contracts_ship(bought.loc), "Ящик пака не засчитан")
	TEST_ASSERT(!QDELETED(bought), "Купленное не удалено")
	var/obj/structure/closet/crate/combo = allocate(/obj/structure/closet/crate)
	var/datum/supply_order/order = new(SSshuttle.supply_packs[/datum/supply_pack/goody/toolbox], "econ_test", "econ_test", "econ_test", "econ_test")
	order.generateCombo(combo, "econ_test", list(/obj/item/storage/toolbox/mechanical))
	qdel(order)
	TEST_ASSERT(!econ_contracts_ship(combo), "Сборный ящик мелочи не засчитан")
	var/datum/bounty/item/bounty = contract.bounty
	TEST_ASSERT_EQUAL(bounty.shipped_count, 0, "Ничего купленного не засчитано")
	var/obj/item/storage/toolbox/found = allocate(/obj/item/storage/toolbox/mechanical)
	TEST_ASSERT(econ_contracts_ship(found), "Не купленный ящик засчитан")
	TEST_ASSERT_EQUAL(bounty.shipped_count, 1, "Засчитан один")

/// Пад подработки объясняет, почему купленное через снабжение не ушло.
/datum/unit_test/economy_contract_machines/pad_imported/Run()
	setup()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/computer/piratepad_control/civilian/console = build_pad(station_turf)
	post_contract(/datum/bounty/item/assistant/toolbox)
	var/obj/item/storage/toolbox/bought = buy_toolbox(station_turf)
	click(console, "send")
	TEST_ASSERT(!QDELETED(bought), "Купленное осталось на паде")
	TEST_ASSERT(findtext(console.status_report, "через снабжение"), "Пульт объясняет отказ: [console.status_report]")

/// Машина, собранная из платы, купленной через снабжение, помечена и не засчитывается; из своей платы - засчитывается.
/datum/unit_test/economy_contract_machines/imported_board_machine/Run()
	setup()
	var/datum/econ_contract/delivery/contract = post_contract(/datum/bounty/item/engineering/pacman)
	var/obj/machinery/power/port_gen/pacman/bought = assemble_pacman(TRUE)
	TEST_ASSERT_NOTNULL(bought, "Машина из купленной платы собрана")
	TEST_ASSERT(bought.econ_imported, "Машина унаследовала метку платы")
	TEST_ASSERT(!econ_contracts_ship(bought), "Машина из купленной платы не засчитана")
	var/obj/machinery/power/port_gen/pacman/crafted = assemble_pacman(FALSE)
	TEST_ASSERT_NOTNULL(crafted, "Машина из своей платы собрана")
	TEST_ASSERT(!crafted.econ_imported, "Своя машина не помечена")
	TEST_ASSERT(econ_contracts_ship(crafted), "Машина из своей платы засчитана")
	TEST_ASSERT(contract.completed, "Контракт выполнен")

/datum/unit_test/economy_contract_machines/imported_board_machine/proc/assemble_pacman(imported)
	var/turf/where = imported ? run_loc_floor_bottom_left : run_loc_floor_top_right
	var/obj/structure/frame/machine/frame = allocate(/obj/structure/frame/machine, where)
	var/obj/item/circuitboard/machine/pacman/board = new(frame)
	board.econ_imported = imported
	frame.circuit = board
	frame.state = 3
	frame.req_components = list()
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)
	frame.attackby(screwdriver, user)
	var/obj/machinery/power/port_gen/pacman/machine = locate() in where
	if(machine)
		allocated += machine
	return machine

/// Взятый контракт снимается в срок по таймеру, а до снятия уже не держит слот взявшего и не принимает поставку.
/datum/unit_test/economy_contract_machines/taken_expiry_frees_slot/Run()
	setup()
	var/datum/econ_contract/delivery/expired = post_contract(/datum/bounty/item/assistant/cheesiehonkers)
	var/datum/econ_contract/delivery/next = post_scooter_contract()
	TEST_ASSERT(expired.take(taker_account), "Первый взят")
	TEST_ASSERT(length(expired.active_timers), "Взятие ставит таймер срока")
	expired.deadline = world.time - 1
	TEST_ASSERT(!expired.wants(allocate(/obj/item/reagent_containers/food/snacks/cheesiehonkers)), "Просроченный поставку не принимает")
	TEST_ASSERT(next.take(taker_account), "Просроченный не держит слот до снятия")
	expired.expire()
	TEST_ASSERT(QDELETED(expired), "Просроченный снят по таймеру")
	TEST_ASSERT(!(expired in civilian.contracts), "Снят с доски")

/// Купленное в автомате пад не отправляет и говорит почему; такой же предмет не из автомата уходит.
/datum/unit_test/economy_contract_machines/pad_vended/Run()
	setup()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/computer/piratepad_control/civilian/console = build_pad(station_turf)
	var/obj/machinery/piratepad/pad = console.linked_pad()
	var/datum/econ_contract/delivery/contract = post_contract(/datum/bounty/item/assistant/cheesiehonkers)
	var/list/vended = list()
	for(var/i in 1 to 3)
		var/obj/item/snack = allocate(/obj/item/reagent_containers/food/snacks/cheesiehonkers, get_turf(pad))
		econ_mark_vended(snack, 10)
		vended += snack
	click(console, "send")
	for(var/obj/item/snack as anything in vended)
		TEST_ASSERT(!QDELETED(snack), "Купленное в автомате осталось на паде")
	TEST_ASSERT(findtext(console.status_report, "в автоматах"), "Пульт объясняет отказ: [console.status_report]")
	for(var/i in 1 to 3)
		allocate(/obj/item/reagent_containers/food/snacks/cheesiehonkers, get_turf(pad))
	click(console, "send")
	TEST_ASSERT(contract.completed, "Найденные снеки засчитаны")

/// Отказ от взятого контракта: неначатый уходит с доски, начатый снова свободен без срока взятия, у срочного срок остаётся; чужой не снять, новый - после паузы.
/datum/unit_test/economy_contract_machines/drop/Run()
	setup()
	var/obj/machinery/computer/bounty/console = allocate(/obj/machinery/computer/bounty)
	var/datum/econ_contract/delivery/fresh = post_scooter_contract()
	click(console, "take", list("uid" = fresh.uid))
	TEST_ASSERT(fresh.taker == taker_account, "Контракт взят")
	var/datum/bank_account/stranger = new("econ_test_stranger")
	TEST_ASSERT(!econ_try_drop_contract(user, fresh.uid, stranger)[1], "Чужой контракт снят")
	qdel(stranger)
	TEST_ASSERT(fresh.taker == taker_account, "Чужой отказ снял исполнителя")
	click(console, "drop", list("uid" = fresh.uid))
	TEST_ASSERT(QDELETED(fresh), "Неначатый контракт после отказа остался на доске")

	var/datum/econ_contract/delivery/started = post_scooter_contract()
	var/datum/bounty/item/wanted = started.bounty
	wanted.required_count = 3
	wanted.shipped_count = 1
	TEST_ASSERT(!econ_try_take_contract(user, started.uid, taker_account)[1], "Новый контракт взят сразу после отказа")
	COOLDOWN_RESET(taker_account, contract_drop_cooldown)
	TEST_ASSERT(econ_try_take_contract(user, started.uid, taker_account)[1], "После паузы контракт берётся")
	TEST_ASSERT(started.deadline, "Взятый получил срок")
	click(console, "drop", list("uid" = started.uid))
	TEST_ASSERT(!QDELETED(started) && (started in civilian.contracts), "Начатый контракт ушёл с доски")
	TEST_ASSERT_NULL(started.taker, "Исполнитель остался после отказа")
	TEST_ASSERT_EQUAL(started.deadline, 0, "Срок взятия остался после отказа")
	TEST_ASSERT_EQUAL(wanted.shipped_count, 1, "Отгруженное по контракту пропало")

	var/datum/econ_contract/delivery/urgent = post_scooter_contract()
	urgent.urgent = TRUE
	urgent.set_deadline(world.time + 10 MINUTES)
	var/urgent_deadline = urgent.deadline
	COOLDOWN_RESET(taker_account, contract_drop_cooldown)
	TEST_ASSERT(urgent.take(taker_account), "Срочный взят")
	var/datum/bounty/item/urgent_wanted = urgent.bounty
	urgent_wanted.required_count = 3
	urgent_wanted.shipped_count = 1
	TEST_ASSERT(urgent.drop(taker_account), "От срочного не отказаться")
	TEST_ASSERT_EQUAL(urgent.deadline, urgent_deadline, "Срочный потерял свой срок")
