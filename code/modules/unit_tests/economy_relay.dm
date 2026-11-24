/datum/unit_test/economy_relay
	abstract_type = /datum/unit_test/economy_relay
	var/list/stashed_contracts
	var/saved_relay_chance
	var/list/saved_relays
	var/saved_rotations
	var/saved_started
	var/list/crew_bodies = list()

/datum/unit_test/economy_relay/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	saved_relay_chance = SSeconomy.settings.contract_relay_chance
	SSeconomy.settings.contract_relay_chance = 0
	saved_relays = SSeconomy.relays
	SSeconomy.relays = list()
	saved_rotations = SSeconomy.settings.contract_relay_stage_rotations
	saved_started = SSeconomy.contracts_started

/datum/unit_test/economy_relay/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	for(var/datum/econ_relay/relay as anything in SSeconomy.relays.Copy())
		qdel(relay)
	SSeconomy.relays = saved_relays
	SSeconomy.settings.contract_relay_chance = saved_relay_chance
	SSeconomy.settings.contract_relay_stage_rotations = saved_rotations
	SSeconomy.contracts_started = saved_started
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		COOLDOWN_RESET(department, contract_reset_cooldown)
	for(var/mob/living/body as anything in crew_bodies)
		body.mock_client = null
	return ..()

/datum/unit_test/economy_relay/proc/template_titled(title)
	for(var/list/template as anything in GLOB.econ_relay_templates)
		if(template["title"] == title)
			return template

/// Сотрудник отдела в игре: живое тело с клиентом и привязанный счёт.
/datum/unit_test/economy_relay/proc/crew_member(department_id, name)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new(name)
	allocated += account
	account.department_id = department_id
	body.account_id = account.account_id
	account.bind_owner(body)
	body.mock_client = new /datum/client_interface()
	crew_bodies += body
	return account

/// Строки шпиона, которые начинаются с prefix.
/datum/unit_test/economy_relay/proc/heard_starting(obj/item/radio/headset/econ_test_spy/spy, prefix)
	. = list()
	for(var/line in spy.heard)
		if(findtext(line, prefix) == 1)
			. += line

/// Рабочая система оповещения станции первой в списке, с гарнитурой-шпионом.
/datum/unit_test/economy_relay/proc/spy_announcer()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/obj/machinery/announcement_system/announcer = allocate(/obj/machinery/announcement_system, locate(2, 2, station_z))
	announcer.machine_stat = NONE
	qdel(announcer.radio)
	var/obj/item/radio/headset/econ_test_spy/spy = new(announcer)
	announcer.radio = spy
	GLOB.announcement_systems -= announcer
	GLOB.announcement_systems.Insert(1, announcer)
	TEST_ASSERT(announcer.is_operational(), "Система оповещений станции работает")
	return spy

/// Сдвигает время выставления этапа назад, будто прошло elapsed; секунда сверху - запас на неточность дробного world.time.
/datum/unit_test/economy_relay/proc/age_stage(datum/econ_relay/relay, elapsed)
	relay.stage_posted_at -= elapsed + 1 SECONDS
	relay.current.created -= elapsed + 1 SECONDS

/// Невзятый этап эстафеты переживает обычную ротацию и принудительную смену доски; снимает его только свой срок, и тогда отдел слышит, что эстафета оборвалась, а место на доске освобождается.
/datum/unit_test/economy_relay/stage_lifetime/Run()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/list/template = template_titled("Лекарства для медбея")
	TEST_ASSERT_NOTNULL(template, "Нет эстафеты «Лекарства для медбея»")
	var/datum/econ_contract/first = SSeconomy.begin_relay(template)
	TEST_ASSERT_NOTNULL(first, "Первый этап не выставлен")
	var/datum/econ_relay/relay = first.relay
	TEST_ASSERT(first in medical.contracts, "Этап не на доске медицины")
	var/age = SSeconomy.contract_rotation_age()
	var/rotations = SSeconomy.settings.contract_relay_stage_rotations
	TEST_ASSERT(rotations > 1, "Этап живёт не дольше обычного контракта: [rotations] ротаций")
	TEST_ASSERT_EQUAL(relay.stage_minutes(), round(age * rotations / (1 MINUTES)), "Срок этапа в минутах")

	age_stage(relay, age)
	SSeconomy.refresh_contracts()
	TEST_ASSERT(!QDELETED(first) && (first in medical.contracts), "Этап снят первой же ротацией")
	SSeconomy.refresh_contracts(force = TRUE)
	TEST_ASSERT(!QDELETED(first) && (first in medical.contracts), "Этап снят принудительной сменой доски")
	var/list/entry = first.ui_entry()
	TEST_ASSERT_EQUAL(entry["kind"], "relay", "Карточка не помечена эстафетой")
	TEST_ASSERT_EQUAL(entry["relay_minutes"], round(age * (rotations - 1) / (1 MINUTES)), "Карточка не знает, сколько осталось этапу")
	TEST_ASSERT(abs(entry["rotates_in"] - (age * (rotations - 1) - 1 SECONDS) / (1 SECONDS)) <= 1, "До снятия этапа на карточке [entry["rotates_in"]] с")
	TEST_ASSERT(length(spy.heard) >= 1 && findtext(spy.heard[1], "[RADIO_CHANNEL_MEDICAL]: Эстафета «Лекарства для медбея» началась") == 1, "Начало эстафеты не прозвучало в канале медицины: [jointext(spy.heard, " | ")]")

	spy.heard.Cut()
	age_stage(relay, age * (rotations - 1))
	SSeconomy.refresh_contracts()
	TEST_ASSERT(QDELETED(first), "Этап пережил свой срок")
	TEST_ASSERT(QDELETED(relay), "Эстафета не оборвалась вместе с этапом")
	TEST_ASSERT(!(relay in SSeconomy.relays), "Оборванная эстафета осталась в списке идущих")
	TEST_ASSERT(!(first in medical.contracts), "Снятый этап остался на доске")
	TEST_ASSERT_EQUAL(medical.regular_contracts(), SSeconomy.settings.contracts_per_department, "Место этапа на доске не занял новый контракт")
	TEST_ASSERT_EQUAL(length(spy.heard), 1, "Обрыв эстафеты прозвучал не один раз: [jointext(spy.heard, " | ")]")
	var/line = spy.heard[1]
	TEST_ASSERT(findtext(line, "[RADIO_CHANNEL_MEDICAL]: Эстафета «Лекарства для медбея» оборвалась") == 1, "Обрыв не в канале медицины: [line]")
	TEST_ASSERT(findtext(line, "за [round(age * rotations / (1 MINUTES))] мин. этап никто не выполнил"), "В сообщении нет причины: [line]")

/// Этап-деятельность не снимается своим сроком деятельности раньше срока этапа; взятый этап ротация не трогает, срок ему ставит взятие.
/datum/unit_test/economy_relay/activity_stage/Run()
	var/list/template = template_titled("От грядки до бокала")
	TEST_ASSERT_NOTNULL(template, "Нет эстафеты «От грядки до бокала»")
	var/datum/econ_contract/activity/first = SSeconomy.begin_relay(template)
	TEST_ASSERT(istype(first), "Первый этап не деятельность: [first?.type]")
	var/datum/econ_relay/relay = first.relay
	TEST_ASSERT(!first.deadline || first.deadline >= relay.stage_due_at(), "Срок деятельности снимет этап раньше срока этапа")
	TEST_ASSERT(first.rotation_due_at() >= relay.stage_due_at(), "Ротация снимет этап раньше его срока")
	var/datum/bank_account/gardener = new("econ_test_gardener")
	allocated += gardener
	gardener.department_id = ACCOUNT_SRV
	TEST_ASSERT(first.take(gardener), "Этап не взят: [first.take_refusal(gardener)]")
	TEST_ASSERT_NULL(first.rotation_due_at(), "Ротация снимет взятый этап")
	TEST_ASSERT_EQUAL(first.deadline, world.time + ECON_CONTRACT_TAKEN_TIME, "Взятому этапу не поставлен срок")
	age_stage(relay, relay.stage_lifetime())
	SSeconomy.refresh_contracts()
	TEST_ASSERT(!QDELETED(first), "Взятый этап снят ротацией")

/// Отказ взявшего от первого этапа эстафету не обрывает: этап снова свободен, без срока взявшего, и ждёт отдел до срока этапа.
/datum/unit_test/economy_relay/drop_keeps_stage/Run()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/econ_contract/first = SSeconomy.begin_relay(template_titled("Лекарства для медбея"))
	TEST_ASSERT_NOTNULL(first, "Первый этап не выставлен")
	var/datum/econ_relay/relay = first.relay
	var/datum/bank_account/chemist = new("econ_test_chemist")
	allocated += chemist
	chemist.department_id = ACCOUNT_MED
	TEST_ASSERT(first.take(chemist), "Этап не взят: [first.take_refusal(chemist)]")
	TEST_ASSERT(first.deadline, "Взятому этапу не поставлен срок")
	spy.heard.Cut()
	TEST_ASSERT(first.drop(chemist), "Отказ от этапа не принят")
	TEST_ASSERT(!QDELETED(first) && (first in medical.contracts), "Отказ снял этап с доски")
	TEST_ASSERT(!QDELETED(relay) && relay.current == first, "Отказ оборвал эстафету")
	TEST_ASSERT_NULL(first.taker, "У этапа остался взявший")
	TEST_ASSERT_EQUAL(first.deadline, 0, "После отказа у этапа остался срок взявшего")
	TEST_ASSERT_EQUAL(first.rotation_due_at(), relay.stage_due_at(), "Свободный этап снимется не в срок этапа")
	TEST_ASSERT_EQUAL(length(spy.heard), 0, "После отказа что-то прозвучало: [jointext(spy.heard, " | ")]")

/// Срочный контракт, ставший этапом, после отказа взявшего и после удаления счёта взявшего остаётся срочным и со своим сроком.
/datum/unit_test/economy_relay/urgent_stage_drop/Run()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/datum/econ_contract/activity/service_plants/plants = new(ACCOUNT_SRV)
	service.contracts += plants
	plants.urgent = TRUE
	plants.set_deadline(world.time + 20 MINUTES)
	var/urgent_deadline = plants.deadline
	var/datum/bank_account/gardener = new("econ_test_gardener")
	allocated += gardener
	gardener.department_id = ACCOUNT_SRV
	TEST_ASSERT(plants.take(gardener), "Урожай не взят: [plants.take_refusal(gardener)]")
	var/datum/econ_contract/first = SSeconomy.begin_relay(template_titled("От грядки до бокала"))
	TEST_ASSERT(first == plants, "Этапом стал не взятый урожай, а [first?.type]")
	TEST_ASSERT(first.drop(gardener), "Отказ от этапа не принят")
	TEST_ASSERT(!QDELETED(first) && first.relay, "Отказ оборвал эстафету")
	TEST_ASSERT(first.urgent, "Этап перестал быть срочным")
	TEST_ASSERT_EQUAL(first.deadline, urgent_deadline, "Срочный этап после отказа потерял свой срок")

	var/datum/bank_account/cook = new("econ_test_cook")
	allocated += cook
	cook.department_id = ACCOUNT_SRV
	TEST_ASSERT(first.take(cook), "Этап не взят снова: [first.take_refusal(cook)]")
	qdel(cook)
	TEST_ASSERT_NULL(first.taker, "Удалённый счёт остался взявшим")
	TEST_ASSERT(!QDELETED(first) && first.relay, "Удаление счёта взявшего оборвало эстафету")
	TEST_ASSERT_EQUAL(first.deadline, urgent_deadline, "Срочный этап без счёта взявшего потерял свой срок")

/// Отказ от этапа, чей срок вышел, пока этап держал взявший, не рвёт эстафету на ближайшей ротации: отдел слышит предупреждение и ждёт ещё ротацию.
/datum/unit_test/economy_relay/late_drop_warns/Run()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	TEST_ASSERT(SSeconomy.settings.contract_relay_stage_rotations > 1, "Этап живёт одну ротацию, предупреждать некогда")
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/econ_contract/first = SSeconomy.begin_relay(template_titled("Лекарства для медбея"))
	TEST_ASSERT_NOTNULL(first, "Первый этап не выставлен")
	var/datum/econ_relay/relay = first.relay
	var/datum/bank_account/chemist = new("econ_test_chemist")
	allocated += chemist
	chemist.department_id = ACCOUNT_MED
	TEST_ASSERT(first.take(chemist), "Этап не взят: [first.take_refusal(chemist)]")
	age_stage(relay, relay.stage_lifetime())
	TEST_ASSERT(world.time > relay.stage_due_at(), "Срок этапа не вышел, проверка ничего не скажет")
	spy.heard.Cut()
	TEST_ASSERT(first.drop(chemist), "Отказ от этапа не принят")
	SSeconomy.refresh_contracts()
	TEST_ASSERT(!QDELETED(first) && (first in medical.contracts), "Этап сняли на первой же ротации после отказа")
	TEST_ASSERT(!QDELETED(relay) && relay.current == first, "Эстафета оборвалась на первой же ротации после отказа")
	// Следующая ротация - чуть позже отказа, а не в тот же миг
	age_stage(relay, 0)
	SSeconomy.refresh_contracts()
	TEST_ASSERT(!QDELETED(first) && (first in medical.contracts), "Этап сняли раньше, чем отдел услышал предупреждение")
	var/warning = "[RADIO_CHANNEL_MEDICAL]: Эстафета «Лекарства для медбея»: этап «[first.title]» всё ещё ждёт"
	TEST_ASSERT_EQUAL(length(heard_starting(spy, warning)), 1, "Отдел не услышал предупреждение: [jointext(spy.heard, " | ")]")

/// Сброс доски снимает свободный первый этап, а добор доски не запускает ту же эстафету заново.
/datum/unit_test/economy_relay/reset_no_restart/Run()
	SSeconomy.contracts_started = TRUE
	SSeconomy.settings.contract_relay_chance = 100
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	crew_member(ACCOUNT_MED, "econ_test_chemist")
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_CAPTAIN)
	head.put_in_hands(card)
	var/datum/econ_contract/first = SSeconomy.start_relay(ACCOUNT_MED)
	TEST_ASSERT_NOTNULL(first, "Эстафета не началась при медике в игре")
	var/datum/econ_relay/relay = first.relay
	var/list/result = medical.reset_contracts(head)
	TEST_ASSERT(result[1], "Сброс не прошёл: [result[2]]")
	TEST_ASSERT(QDELETED(relay), "Эстафета не оборвалась вместе со снятым этапом")
	TEST_ASSERT_NULL(SSeconomy.relay_running("Лекарства для медбея"), "Добор доски после сброса тут же запустил ту же эстафету")
	TEST_ASSERT_EQUAL(medical.regular_contracts(), SSeconomy.settings.contracts_per_department, "Доска не добрана после сброса")

/// Эстафета не стартует, если её некому пройти: у отдела какого-то этапа нет никого в игре или первый этап все в игре уже выполнили до лимита.
/datum/unit_test/economy_relay/start_needs_crew/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	TEST_ASSERT_EQUAL(length(medical.staff_in_game()), 0, "В медицине уже кто-то в игре")
	TEST_ASSERT_NULL(SSeconomy.start_relay(ACCOUNT_MED), "Эстафета началась без медиков в игре")
	TEST_ASSERT_EQUAL(length(SSeconomy.relays), 0, "Без медиков эстафета всё же завелась")

	var/datum/bank_account/chemist = crew_member(ACCOUNT_MED, "econ_test_chemist")
	var/limit = SSeconomy.settings.contract_repeat_per_person
	TEST_ASSERT(limit > 0, "Лимит повторов выключен")
	LAZYINITLIST(chemist.contract_repeats)
	for(var/bounty_type in typesof(/datum/bounty/reagent/chemical))
		chemist.contract_repeats[bounty_type] = limit
	TEST_ASSERT_NULL(SSeconomy.start_relay(ACCOUNT_MED), "Эстафета началась, хотя первый этап медику в игре уже не взять")
	TEST_ASSERT_EQUAL(length(SSeconomy.relays), 0, "Несостоявшаяся эстафета осталась в списке идущих")
	TEST_ASSERT_EQUAL(length(medical.contracts), 0, "Несостоявшаяся эстафета оставила контракт на доске")
	chemist.contract_repeats = null
	var/datum/econ_contract/first = SSeconomy.start_relay(ACCOUNT_MED)
	TEST_ASSERT_NOTNULL(first, "Эстафета не началась при медике в игре")
	TEST_ASSERT_EQUAL(first.relay?.title, "Лекарства для медбея", "Началась не та эстафета")

	crew_member(ACCOUNT_CAR, "econ_test_miner")
	var/datum/economy_department/science = SSeconomy.get_department(ACCOUNT_SCI)
	TEST_ASSERT_EQUAL(length(science.staff_in_game()), 0, "В науке уже кто-то в игре")
	TEST_ASSERT_NULL(SSeconomy.start_relay(ACCOUNT_CAR), "Эстафета в науку началась без учёных в игре")
	crew_member(ACCOUNT_SCI, "econ_test_scientist")
	TEST_ASSERT_NOTNULL(SSeconomy.start_relay(ACCOUNT_CAR), "Эстафета не началась при шахтёре и учёном в игре")

/// Сброс доски главой снимает свободный первый этап, и эстафета обрывается с этой причиной; взятый этап и этапы со второго сброс не трогает.
/datum/unit_test/economy_relay/board_reset/Run()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	SSeconomy.contracts_started = TRUE
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_CAPTAIN)
	head.put_in_hands(card)
	TEST_ASSERT(medical.can_manage(head), "Капитан не управляет медициной")
	var/list/template = template_titled("Лекарства для медбея")
	var/datum/econ_contract/first = SSeconomy.begin_relay(template)
	TEST_ASSERT_NOTNULL(first, "Первый этап не выставлен")
	var/datum/econ_relay/relay = first.relay
	var/datum/bank_account/chemist = new("econ_test_chemist")
	allocated += chemist
	chemist.department_id = ACCOUNT_MED
	TEST_ASSERT(first.take(chemist), "Этап не взят: [first.take_refusal(chemist)]")
	TEST_ASSERT(!first.board_reset_removes(null), "Сброс снимет взятый первый этап")
	TEST_ASSERT(first.drop(chemist), "Отказ от этапа не принят")
	TEST_ASSERT(first.board_reset_removes(null), "Сброс не снимет свободный первый этап")

	spy.heard.Cut()
	var/list/result = medical.reset_contracts(head)
	TEST_ASSERT(result[1], "Сброс не прошёл: [result[2]]")
	TEST_ASSERT(QDELETED(first), "Сброс не снял свободный первый этап")
	TEST_ASSERT(QDELETED(relay), "Эстафета не оборвалась вместе со снятым этапом")
	var/list/lost = heard_starting(spy, "[RADIO_CHANNEL_MEDICAL]: Эстафета «Лекарства для медбея» оборвалась")
	TEST_ASSERT_EQUAL(length(lost), 1, "Обрыв прозвучал не один раз: [jointext(spy.heard, " | ")]")
	TEST_ASSERT(length(lost) && findtext(lost[1], "доску отдела сбросили"), "В обрыве не та причина: [jointext(lost, " | ")]")

	var/datum/econ_contract/second = SSeconomy.begin_relay(template)
	TEST_ASSERT_NOTNULL(second, "Эстафета не выставлена повторно")
	second.relay.stage = 2
	TEST_ASSERT(!second.board_reset_removes(null), "Сброс снимет этап со второго")
	second.relay.stage = 1

/// Невзятая серия поставок после этапа ждёт новый срок ротации, а не остаток срока первого этапа.
/datum/unit_test/economy_relay/chain_fresh_rotation/Run()
	var/datum/economy_department/civilian = SSeconomy.get_department(ACCOUNT_CIV)
	var/saved_budget = civilian.account.account_balance
	var/datum/econ_contract/delivery/chain/chain = new(ACCOUNT_CIV, new /datum/bounty/item/assistant/skateboard, list(/datum/bounty/item/assistant/soap))
	civilian.contracts += chain
	var/age = SSeconomy.contract_rotation_age()
	chain.created -= age * 2
	chain.finish_stage(null)
	econ_test_set_balance(civilian.account, saved_budget)
	TEST_ASSERT_EQUAL(chain.stage, 2, "Серия не перешла ко второму этапу")
	TEST_ASSERT_EQUAL(chain.rotation_due_at(), world.time + age * ECON_CONTRACT_STALE_ROTATIONS, "Второй этап невзятой серии ждёт остаток срока первого")

/// Ручка contract_relay_stage_rotations = 1: этап, и первый, и со второго, ждёт ровно одну ротацию; меньше единицы ручка не принимает.
/datum/unit_test/economy_relay/one_rotation/Run()
	SSeconomy.settings.contract_relay_stage_rotations = 1
	var/age = SSeconomy.contract_rotation_age()
	var/datum/econ_contract/first = SSeconomy.begin_relay(template_titled("Лекарства для медбея"))
	TEST_ASSERT_NOTNULL(first, "Первый этап не выставлен")
	var/datum/econ_relay/relay = first.relay
	TEST_ASSERT_EQUAL(relay.stage_minutes(), round(age / (1 MINUTES)), "Срок этапа при одной ротации")
	TEST_ASSERT_EQUAL(first.rotation_due_at(), relay.stage_due_at(), "Первый этап снимется не в срок этапа")
	TEST_ASSERT_EQUAL(first.ui_entry()["relay_minutes"], round(age / (1 MINUTES)), "Карточка обещает не тот срок")
	relay.stage = 2
	TEST_ASSERT_EQUAL(first.rotation_due_at(), relay.stage_due_at(), "Этап со второго ждёт дольше одной ротации")
	relay.stage = 1
	TEST_ASSERT_EQUAL(SSeconomy.settings.check_value("contract_relay_stage_rotations", 0), "меньше 1", "Ручка принимает ноль ротаций")

/// Если этапом стал уже взятый контракт, радио и карточка называют срок взявшего, а не срок этапа.
/datum/unit_test/economy_relay/taken_stage_minutes/Run()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/datum/econ_contract/activity/service_plants/plants = new(ACCOUNT_SRV)
	service.contracts += plants
	var/datum/bank_account/gardener = new("econ_test_gardener")
	allocated += gardener
	gardener.department_id = ACCOUNT_SRV
	TEST_ASSERT(plants.take(gardener), "Урожай не взят: [plants.take_refusal(gardener)]")
	var/datum/econ_contract/first = SSeconomy.begin_relay(template_titled("От грядки до бокала"))
	TEST_ASSERT(first == plants, "Этапом стал не взятый урожай, а [first?.type]")
	var/taken_minutes = CEILING((plants.deadline - world.time) / (1 MINUTES), 1)
	TEST_ASSERT(taken_minutes != first.relay.stage_minutes(), "Срок взявшего совпал со сроком этапа, проверка ничего не скажет")
	TEST_ASSERT_EQUAL(first.ui_entry()["relay_minutes"], taken_minutes, "Карточка обещает срок этапа, а не срок взявшего")
	var/list/started = heard_starting(spy, "[RADIO_CHANNEL_SERVICE]: Эстафета «От грядки до бокала» началась")
	TEST_ASSERT_EQUAL(length(started), 1, "Начало эстафеты не прозвучало: [jointext(spy.heard, " | ")]")
	TEST_ASSERT(length(started) && findtext(started[1], "этап уже взят, у взявшего [taken_minutes] мин."), "Радио обещает не тот срок: [jointext(started, " | ")]")

/// За ротацию до снятия невзятого этапа отдел один раз слышит предупреждение; пройденная эстафета звучит в каналах всех своих отделов по разу, с суммой и премией.
/datum/unit_test/economy_relay/finale_and_warning/Run()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	TEST_ASSERT(SSeconomy.settings.contract_relay_stage_rotations > 1, "Этап живёт одну ротацию, предупреждать некогда")
	var/datum/econ_contract/first = SSeconomy.begin_relay(template_titled("Лекарства для медбея"))
	TEST_ASSERT_NOTNULL(first, "Первый этап не выставлен")
	var/datum/econ_relay/relay = first.relay
	var/age = SSeconomy.contract_rotation_age()
	var/warning = "[RADIO_CHANNEL_MEDICAL]: Эстафета «Лекарства для медбея»: этап «[first.title]» всё ещё ждёт"
	age_stage(relay, relay.stage_lifetime() - age * 2)
	SSeconomy.refresh_contracts()
	TEST_ASSERT_EQUAL(length(heard_starting(spy, warning)), 0, "Предупреждение раньше последней ротации: [jointext(spy.heard, " | ")]")
	age_stage(relay, age)
	SSeconomy.refresh_contracts()
	SSeconomy.refresh_contracts()
	TEST_ASSERT(!QDELETED(first), "Этап снят раньше срока")
	TEST_ASSERT_EQUAL(length(heard_starting(spy, warning)), 1, "Предупреждение прозвучало не один раз: [jointext(spy.heard, " | ")]")
	qdel(relay)

	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/datum/economy_department/science = SSeconomy.get_department(ACCOUNT_SCI)
	var/saved_cargo = cargo.account.account_balance
	var/saved_science = science.account.account_balance
	var/datum/econ_contract/ore = SSeconomy.begin_relay(template_titled("Руда для науки"))
	TEST_ASSERT_NOTNULL(ore, "Первый этап «Руды для науки» не выставлен")
	var/datum/econ_relay/ore_relay = ore.relay
	var/first_total = ore.final_payout()
	ore.complete(null)
	var/datum/econ_contract/nodes = ore_relay.current
	TEST_ASSERT_NOTNULL(nodes, "Второй этап не выставлен")
	var/final_total = nodes.final_payout()
	var/bonus = final_total - nodes.payout()
	TEST_ASSERT(bonus > 0, "Последний этап без премии")
	spy.heard.Cut()
	nodes.complete(null)
	econ_test_set_balance(cargo.account, saved_cargo)
	econ_test_set_balance(science.account, saved_science)
	TEST_ASSERT(QDELETED(ore_relay), "Пройденная эстафета не закрыта")
	var/finale = "Эстафета «Руда для науки» пройдена, выплачено [first_total + final_total] кр., из них премия [bonus] кр."
	for(var/channel in list(RADIO_CHANNEL_SUPPLY, RADIO_CHANNEL_SCIENCE))
		TEST_ASSERT_EQUAL(length(heard_starting(spy, "[channel]: [finale]")), 1, "Итог эстафеты в канале [channel]: [jointext(spy.heard, " | ")]")
	TEST_ASSERT_EQUAL(length(heard_starting(spy, "[RADIO_CHANNEL_SUPPLY]: Эстафета «Руда для науки» пройдена")) + length(heard_starting(spy, "[RADIO_CHANNEL_SCIENCE]: Эстафета «Руда для науки» пройдена")), length(spy.heard), "Кроме итога прозвучало лишнее: [jointext(spy.heard, " | ")]")
