/datum/unit_test/economy_work/proc/mark_performer_attack()
	patient.lastattackerckey = ckey(performer.mind.key)
	patient.lastattacker_time = world.time

/datum/unit_test/economy_work/proc/age_performer_attack()
	patient.lastattacker_time = world.time - (SSeconomy.settings.work_subject_cooldown_minutes MINUTES) - 1

/// Медик и пациент рядом на станционном полу с воздухом: медицина платит только за работу на станции.
/datum/unit_test/economy_work/proc/setup_station_pair()
	setup_pair()
	for(var/area_name in GLOB.teleportlocs)
		var/area/candidate_area = GLOB.teleportlocs[area_name]
		if(istype(candidate_area, /area/space))
			continue
		for(var/turf/open/floor/spot in get_area_turfs(candidate_area.type))
			var/turf/open/floor/neighbour = get_step(spot, EAST)
			if(!istype(neighbour) || !is_station_level(spot.z) || spot.is_blocked_turf() || neighbour.is_blocked_turf())
				continue
			var/datum/gas_mixture/air = spot.return_air()
			if(air.return_pressure() < WARNING_LOW_PRESSURE)
				continue
			performer.forceMove(spot)
			patient.forceMove(neighbour)
			return
	TEST_FAIL("Нет станционного пола с воздухом и свободным соседом на востоке")

/datum/unit_test/economy_work/proc/start_offstation_pair()
	setup_pair()
	TEST_ASSERT(!is_station_level(performer.z), "Тестовая резервация не станция")
	patient.forceMove(get_step(performer, EAST))

/datum/unit_test/economy_work/proc/defib_patient()
	var/obj/item/defibrillator/loaded/defib = allocate(/obj/item/defibrillator/loaded)
	TEST_ASSERT(performer.equip_to_slot_if_possible(defib, ITEM_SLOT_BACK), "Дефибриллятор на спине")
	usr = performer
	defib.attack_hand(performer)
	usr = null
	var/obj/item/shockpaddles/paddles = defib.paddles
	TEST_ASSERT(paddles in performer.held_items, "Лопасти в руках")
	paddles.attack_self(performer)
	TEST_ASSERT(paddles.wielded, "Лопасти в обеих руках")
	paddles.melee_attack_chain(performer, patient)
	var/list/wait = new_wait_budget(45 SECONDS, "реанимация")
	while(patient.stat == DEAD && wait_budget_tick(wait))
		continue
	TEST_ASSERT(patient.stat != DEAD, "Пациент ожил")

/// Тяжёлая травма отмечается, сканирование вылеченного пациента само выписывает его, платит медицине и закрывает травму.
/datum/unit_test/economy_work/discharge/Run()
	setup_station_pair()
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	performer.put_in_active_hand(analyzer)
	patient.forceMove(get_step(performer, EAST))
	patient.adjustBruteLoss(70)
	TEST_ASSERT_EQUAL(patient.econ_injury_severity, ECON_INJURY_HEAVY, "Тяжёлая травма отмечена")
	var/before = budget.account_balance
	analyzer.attack(patient, performer)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Невылеченного пациента скан не выписывает")
	TEST_ASSERT_EQUAL(patient.econ_injury_severity, ECON_INJURY_HEAVY, "Травма открыта до лечения")
	patient.fully_heal()
	analyzer.attack(patient, performer)
	TEST_ASSERT_EQUAL(budget.account_balance - before, SSeconomy.settings.work_prices[WORK_MED_DISCHARGE_HEAVY], "Оплата выписки при скане")
	TEST_ASSERT_EQUAL(patient.econ_injury_severity, ECON_INJURY_NONE, "Травма закрыта выпиской")
	var/after = budget.account_balance
	analyzer.attack(patient, performer)
	TEST_ASSERT_EQUAL(budget.account_balance, after, "Повторный скан не платит второй раз")

/// Выписывать может только сотрудник медицины и не самого себя.
/datum/unit_test/economy_work/discharge_needs_medic/Run()
	setup_station_pair()
	performer_account.department_id = ACCOUNT_SRV
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	patient.forceMove(get_step(performer, EAST))
	patient.adjustBruteLoss(70)
	patient.fully_heal()
	TEST_ASSERT(patient.econ_can_discharge(), "Пациент готов к выписке")
	TEST_ASSERT_EQUAL(analyzer.try_discharge(performer, patient), 0, "Не медик")
	performer_account.department_id = ACCOUNT_MED
	patient.account_id = performer_account.account_id
	TEST_ASSERT(!analyzer.econ_discharge_ready(patient, patient), "Медик не выписывает сам себя")

/// Выписки разной тяжести делят один кулдаун на пациента.
/datum/unit_test/economy_work/discharge_shared_cooldown/Run()
	setup_station_pair()
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	patient.forceMove(get_step(performer, EAST))
	patient.adjustBruteLoss(30)
	TEST_ASSERT_EQUAL(patient.econ_injury_severity, ECON_INJURY_LIGHT, "Лёгкая травма отмечена")
	patient.fully_heal()
	TEST_ASSERT_EQUAL(analyzer.try_discharge(performer, patient), SSeconomy.settings.work_prices[WORK_MED_DISCHARGE_LIGHT], "Лёгкая выписка")
	patient.adjustBruteLoss(70)
	TEST_ASSERT_EQUAL(patient.econ_injury_severity, ECON_INJURY_HEAVY, "Новая тяжёлая травма отмечена")
	patient.fully_heal()
	TEST_ASSERT_EQUAL(analyzer.try_discharge(performer, patient), 0, "Тяжёлая выписка того же пациента в окне кулдауна")

/// Травма, нанесённая самим медиком, не оплачивается выпиской и после кулдауна работы.
/datum/unit_test/economy_work/discharge_own_injury/Run()
	setup_station_pair()
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	patient.forceMove(get_step(performer, EAST))
	mark_performer_attack()
	patient.adjustBruteLoss(70)
	age_performer_attack()
	patient.fully_heal()
	TEST_ASSERT_EQUAL(analyzer.try_discharge(performer, patient), 0, "Своя травма")

/// После конца раунда выписка не платит и молчит, а не пишет медику про кулдаун выписки.
/datum/unit_test/economy_work/discharge_after_round_end/Run()
	setup_station_pair()
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	patient.adjustBruteLoss(30)
	patient.fully_heal()
	TEST_ASSERT(analyzer.econ_discharge_ready(performer, patient), "Пациент готов к выписке")
	var/previous_state = SSticker.current_state
	SSticker.current_state = GAME_STATE_FINISHED
	GLOB.unit_test_chat_capture = list()
	var/paid = analyzer.try_discharge(performer, patient)
	var/list/heard = GLOB.unit_test_chat_capture
	GLOB.unit_test_chat_capture = null
	SSticker.current_state = previous_state
	TEST_ASSERT_EQUAL(paid, 0, "Выписка после конца раунда оплачена")
	for(var/list/entry as anything in heard)
		TEST_ASSERT(!findtext(entry[2], "не засчитана"), "Ложное сообщение о выписке после конца раунда: [entry[2]]")

/// Реанимация дефибриллятором платит медицине.
/datum/unit_test/economy_work/defib_revive/Run()
	setup_station_pair()
	patient.forceMove(get_step(performer, EAST))
	patient.death()
	var/before = budget.account_balance
	defib_patient()
	TEST_ASSERT_EQUAL(budget.account_balance - before, SSeconomy.settings.work_prices[WORK_MED_REVIVE], "Оплата реанимации")

/// Реанимация убитого самим оператором не оплачивается и после кулдауна работы.
/datum/unit_test/economy_work/defib_own_kill/Run()
	setup_station_pair()
	patient.forceMove(get_step(performer, EAST))
	mark_performer_attack()
	patient.death()
	age_performer_attack()
	var/before = budget.account_balance
	defib_patient()
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Свой труп")

/// Лечебная операция на здоровом не платит.
/datum/unit_test/economy_work/surgery_healthy/Run()
	setup_station_pair()
	var/before = budget.account_balance
	var/datum/surgery/healing = new /datum/surgery/healing/brute/basic(patient, BODY_ZONE_CHEST, patient.get_bodypart(BODY_ZONE_CHEST))
	healing.complete(performer)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Операция на здоровом")

/// Косметика, ампутация и пересадки не платят и за свежую травму.
/datum/unit_test/economy_work/surgery_excluded/Run()
	setup_station_pair()
	var/before = budget.account_balance
	patient.adjustBruteLoss(30)
	for(var/surgery_type in list(/datum/surgery/plastic_surgery, /datum/surgery/amputation, /datum/surgery/amputation/robotic, /datum/surgery/organ_manipulation, /datum/surgery/prosthetic_replacement))
		var/datum/surgery/excluded = new surgery_type(patient, BODY_ZONE_CHEST, patient.get_bodypart(BODY_ZONE_CHEST))
		excluded.complete(performer)
		TEST_ASSERT_EQUAL(budget.account_balance, before, "[surgery_type] не платит")
	var/datum/surgery/healing = new /datum/surgery/healing/brute/basic(patient, BODY_ZONE_CHEST, patient.get_bodypart(BODY_ZONE_CHEST))
	healing.complete(performer)
	TEST_ASSERT_EQUAL(budget.account_balance - before, SSeconomy.settings.work_prices[WORK_MED_SURGERY], "Лечебная операция на травмированном")

/// Операция над травмой, нанесённой самим хирургом, не оплачивается и после кулдауна работы.
/datum/unit_test/economy_work/surgery_own_injury/Run()
	setup_station_pair()
	mark_performer_attack()
	patient.adjustBruteLoss(30)
	age_performer_attack()
	var/before = budget.account_balance
	var/datum/surgery/healing = new /datum/surgery/healing/brute/basic(patient, BODY_ZONE_CHEST, patient.get_bodypart(BODY_ZONE_CHEST))
	healing.complete(performer)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Своя травма")

/// Лечебная операция вне станции медицине не платит.
/datum/unit_test/economy_work/offstation_surgery/Run()
	start_offstation_pair()
	patient.adjustBruteLoss(30)
	var/before = budget.account_balance
	var/datum/surgery/healing = new /datum/surgery/healing/brute/basic(patient, BODY_ZONE_CHEST, patient.get_bodypart(BODY_ZONE_CHEST))
	healing.complete(performer)
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Операция вне станции оплачена")

/// Выписка вне станции не предлагается и не платит.
/datum/unit_test/economy_work/offstation_discharge/Run()
	start_offstation_pair()
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	patient.adjustBruteLoss(70)
	patient.fully_heal()
	var/before = budget.account_balance
	TEST_ASSERT(!analyzer.econ_discharge_ready(performer, patient), "Выписка вне станции предложена")
	TEST_ASSERT_EQUAL(analyzer.try_discharge(performer, patient), 0, "Выписка вне станции оплачена")
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Бюджет медицины вырос")

/// Реанимация вне станции медицине не платит.
/datum/unit_test/economy_work/offstation_revive/Run()
	start_offstation_pair()
	patient.death()
	var/before = budget.account_balance
	defib_patient()
	TEST_ASSERT_EQUAL(budget.account_balance, before, "Реанимация вне станции оплачена")

/datum/unit_test/economy_work/proc/budget_entries(prefix, list/before)
	. = list()
	for(var/datum/transaction/entry as anything in budget.transaction_history - before)
		if(findtext(entry.purpose, prefix) == 1)
			. += entry.purpose

/// Журнал бюджета медицины и сообщение медику называют выписанного пациента по ID-карте, а не настоящим именем.
/datum/unit_test/economy_work/discharge_public_name/Run()
	setup_station_pair()
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	patient.adjustBruteLoss(70)
	patient.fully_heal()
	var/list/history = budget.transaction_history.Copy()
	GLOB.unit_test_chat_capture = list()
	var/paid = analyzer.try_discharge(performer, patient)
	var/list/chat = GLOB.unit_test_chat_capture
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(paid > 0, "Выписка не оплачена")
	var/list/memos = budget_entries("Выписка", history)
	TEST_ASSERT(length(memos), "Нет записи о выписке в бюджете медицины")
	for(var/memo in memos)
		TEST_ASSERT(!findtext(memo, patient.real_name), "Журнал бюджета раскрывает настоящее имя: [memo]")
		TEST_ASSERT(findtext(memo, econ_public_name(patient)), "Журнал бюджета не называет пациента по карте: [memo]")
	for(var/list/line as anything in chat)
		if(line[1] == performer)
			TEST_ASSERT(!findtext(line[2], patient.real_name), "Сообщение медику раскрывает настоящее имя: [line[2]]")

/// Журнал бюджета медицины называет реанимированного по ID-карте, а не настоящим именем.
/datum/unit_test/economy_work/revive_public_name/Run()
	setup_station_pair()
	patient.death()
	var/list/history = budget.transaction_history.Copy()
	defib_patient()
	var/list/memos = budget_entries("Реанимация", history)
	TEST_ASSERT(length(memos), "Нет записи о реанимации в бюджете медицины")
	for(var/memo in memos)
		TEST_ASSERT(!findtext(memo, patient.real_name), "Журнал бюджета раскрывает настоящее имя: [memo]")
