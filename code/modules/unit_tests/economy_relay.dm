/datum/unit_test/economy_relay
	abstract_type = /datum/unit_test/economy_relay
	var/list/stashed_contracts
	var/saved_relay_chance
	var/list/saved_relays

/datum/unit_test/economy_relay/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	saved_relay_chance = SSeconomy.settings.contract_relay_chance
	SSeconomy.settings.contract_relay_chance = 0
	saved_relays = SSeconomy.relays
	SSeconomy.relays = list()

/datum/unit_test/economy_relay/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	for(var/datum/econ_relay/relay as anything in SSeconomy.relays.Copy())
		qdel(relay)
	SSeconomy.relays = saved_relays
	SSeconomy.settings.contract_relay_chance = saved_relay_chance
	return ..()

/datum/unit_test/economy_relay/proc/template_titled(title)
	for(var/list/template as anything in GLOB.econ_relay_templates)
		if(template["title"] == title)
			return template

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

/// Невзятый этап эстафеты переживает обычную ротацию, принудительную смену доски и сброс главой; снимает его только свой срок, и тогда отдел слышит, что эстафета оборвалась, а место на доске освобождается.
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
	TEST_ASSERT(!first.board_reset_removes(null), "Сброс доски главой снимет этап")
	var/list/entry = first.ui_entry()
	TEST_ASSERT_EQUAL(entry["kind"], "relay", "Карточка не помечена эстафетой")
	TEST_ASSERT_EQUAL(entry["relay_minutes"], relay.stage_minutes(), "Карточка не знает срока этапа")
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
