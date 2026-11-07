/// Должность на полигоне - снаряжение, доступ и импланты без следа в манифесте, банке, слотах, мессенджере и assigned_role.
/datum/unit_test/antag_training_role_crew_isolation/Run()
	var/datum/job/officer = SSjob.GetJob("Security Officer")
	var/positions_before = officer.current_positions
	var/accounts_before = length(SSeconomy.bank_accounts)
	var/records_before = length(GLOB.data_core.general)
	var/messengers_before = length(GLOB.pda_messengers)
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("crew:Security Officer")
	TEST_ASSERT(session.role, "Реестр знает должность офицера.")
	TEST_ASSERT(session.prepare(), "Полигон готовит офицера.")
	var/mob/living/carbon/human/body = session.current_body
	var/obj/item/card/id/card = body.get_idcard()
	TEST_ASSERT(card && (ACCESS_SECURITY in card.access), "ID офицера с доступом СБ.")
	TEST_ASSERT(locate(/obj/item/implant/mindshield) in body.implants, "Офицер с майндшилдом.")
	TEST_ASSERT(istype(body.ears, /obj/item/radio/headset/headset_sec), "Офицер с гарнитурой СБ.")
	TEST_ASSERT(body.mind.assigned_role != officer.title, "assigned_role не офицер: должность не копит время и метадоллары.")
	TEST_ASSERT_EQUAL(officer.current_positions, positions_before, "Слот офицера не занят.")
	TEST_ASSERT_EQUAL(length(SSeconomy.bank_accounts), accounts_before, "Банковский счёт не создан.")
	TEST_ASSERT_EQUAL(length(GLOB.data_core.general), records_before, "Манифест не тронут.")
	TEST_ASSERT_EQUAL(length(GLOB.pda_messengers), messengers_before, "КПК не в мессенджере станции.")
	for(var/trait in officer.mind_traits)
		TEST_ASSERT(HAS_TRAIT(body.mind, trait), "Трейт должности [trait] выдан.")

/// Врач-предатель: смена программы сохраняет должность, смена должности пересобирает тело с той же программой.
/datum/unit_test/antag_training_role_restart/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("crew:Medical Doctor")
	TEST_ASSERT(session.prepare(), "Полигон готовит врача.")
	session.next_restart_at = 0
	TEST_ASSERT(session.restart(/datum/antag_training_program/antag/traitor), "Смена программы на предателя.")
	var/obj/item/card/id/card = session.current_body.get_idcard()
	TEST_ASSERT(card && (ACCESS_MEDICAL in card.access), "Предатель остался врачом.")
	TEST_ASSERT(session.avatar_mind.has_antag_datum(/datum/antagonist/traitor), "Поверх должности выдан учебный предатель.")
	session.next_restart_at = 0
	TEST_ASSERT(session.set_role("crew:Station Engineer"), "Смена должности на инженера.")
	card = session.current_body.get_idcard()
	TEST_ASSERT(card && (ACCESS_ENGINE in card.access) && !(ACCESS_MEDICAL in card.access), "Новое тело - инженер без доступа врача.")
	TEST_ASSERT(session.avatar_mind.has_antag_datum(/datum/antagonist/traitor), "Программа предателя сохранилась.")
	TEST_ASSERT(!session.set_role("crew:Nonexistent"), "Неизвестная должность отклонена.")
	TEST_ASSERT_EQUAL(session.role.id, "crew:Station Engineer", "После отказа роль прежняя.")

/// Пират извне не получает должность участника.
/datum/unit_test/antag_training_role_ignored/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/crew/pirate)
	session.role = antag_training_role("crew:Captain")
	TEST_ASSERT(session.prepare(), "Полигон готовит пирата.")
	var/obj/item/card/id/card = session.current_body.get_idcard()
	TEST_ASSERT(!card || !(ACCESS_CAPTAIN in card.access), "Пират без капитанского доступа.")
	var/list/data = session.ui_data(session.current_body)
	TEST_ASSERT(!data["role_applies"], "Пульт показывает, что должность к пирату не применяется.")

/// Пульт отдаёт должности по отделам и меняет роль действием set_role.
/datum/unit_test/antag_training_role_console/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/list/static_data = session.ui_static_data(session.current_body)
	var/found = FALSE
	for(var/list/entry as anything in static_data["roles"])
		if(entry["id"] == "crew:Medical Doctor")
			found = entry["department"] == "Медицина"
	TEST_ASSERT(found, "Врач в списке должностей в отделе медицины.")
	var/list/data = session.ui_data(session.current_body)
	TEST_ASSERT_EQUAL(data["role"], ANTAG_TRAINING_ROLE_DEFAULT, "По умолчанию учебное тело.")
	TEST_ASSERT(data["role_applies"], "Свободная тренировка применяет должность.")
	var/datum/tgui/console = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	session.next_restart_at = 0
	antag_training_console_act(session, console, "set_role", list("role" = "crew:Medical Doctor"))
	TEST_ASSERT_EQUAL(session.role.id, "crew:Medical Doctor", "Пульт сменил должность.")

/datum/unit_test/antag_training_role_radio
	var/list/hearings = list()

/// Офицеры на полигоне слышат друг друга по каналу СБ; станция их не слышит, они не слышат станцию.
/datum/unit_test/antag_training_role_radio/Run()
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/free)
	first.role = antag_training_role("crew:Security Officer")
	TEST_ASSERT(first.prepare(), "Первый офицер на полигоне.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	second.role = antag_training_role("crew:Security Officer")
	TEST_ASSERT(second.prepare(first.arena), "Второй офицер на полигоне.")
	allocate(/obj/machinery/telecomms/allinone, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/station_speaker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/station_listener = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	for(var/mob/living/carbon/human/crew as anything in list(station_speaker, station_listener))
		var/obj/item/radio/headset/headset_sec/headset = allocate(/obj/item/radio/headset/headset_sec, get_turf(crew))
		TEST_ASSERT(crew.equip_to_slot_if_possible(headset, ITEM_SLOT_EARS_LEFT), "Офицер станции надевает гарнитуру.")
	var/mob/living/carbon/human/trainee = first.current_body
	var/mob/living/carbon/human/partner = second.current_body
	for(var/mob/listener as anything in list(trainee, partner, station_speaker, station_listener))
		RegisterSignal(listener, COMSIG_MOVABLE_HEAR, PROC_REF(on_hear))
	trainee.say(":s arena-sec-probe")
	TEST_ASSERT(wait_heard(partner, "arena-sec-probe"), "Офицеры полигона слышат друг друга.")
	TEST_ASSERT(!heard(station_listener, "arena-sec-probe") && !heard(station_speaker, "arena-sec-probe"), "Станция не слышит полигон.")
	station_speaker.say(":s station-sec-probe")
	TEST_ASSERT(wait_heard(station_listener, "station-sec-probe"), "Станция слышит себя: проверка не пустая.")
	TEST_ASSERT(!heard(trainee, "station-sec-probe") && !heard(partner, "station-sec-probe"), "Полигон не слышит станцию.")

/datum/unit_test/antag_training_role_radio/proc/on_hear(mob/source, list/hearing_args)
	SIGNAL_HANDLER
	hearings += list(list(source, hearing_args[HEARING_RAW_MESSAGE]))

/datum/unit_test/antag_training_role_radio/proc/heard(mob/listener, marker)
	for(var/list/entry as anything in hearings)
		if(entry[1] == listener && findtext(entry[2], marker))
			return TRUE
	return FALSE

/datum/unit_test/antag_training_role_radio/proc/wait_heard(mob/listener, marker)
	var/list/budget = new_wait_budget(5 SECONDS, "доставка радио")
	while(!heard(listener, marker))
		if(!wait_budget_tick(budget))
			return FALSE
	return TRUE

/// Роль ИИ: учебный ИИ в ядре мини-станции хаба, без вызова шаттла и КПК; человеческий аватар убран.
/datum/unit_test/antag_training_role_ai/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("silicon:ai")
	TEST_ASSERT(session.role, "Реестр знает роль ИИ.")
	TEST_ASSERT(session.prepare(), "Полигон готовит ИИ.")
	var/mob/living/silicon/ai/training/core = session.current_body
	TEST_ASSERT(istype(core), "Тело участника - учебный ИИ.")
	TEST_ASSERT_EQUAL(get_turf(core), session.arena.hub.landmark_turf("hub_ai_core"), "ИИ стоит в ядре мини-станции хаба.")
	TEST_ASSERT(!(core in GLOB.shuttle_caller_list), "Учебный ИИ не вызывает шаттл.")
	TEST_ASSERT(!core.aiPDA, "У учебного ИИ нет КПК.")
	TEST_ASSERT_NULL(session.avatar, "Человеческий аватар убран.")

/// Роль киборга: учебный киборг подключается к учебному ИИ другого участника и скрыт от станционных консолей.
/datum/unit_test/antag_training_role_cyborg/Run()
	var/datum/antag_training_session/ai_session = allocate_training_session(/datum/antag_training_program/free)
	ai_session.role = antag_training_role("silicon:ai")
	TEST_ASSERT(ai_session.prepare(), "Полигон готовит ИИ.")
	var/datum/antag_training_session/borg_session = allocate_training_session(/datum/antag_training_program/free)
	borg_session.role = antag_training_role("silicon:cyborg")
	TEST_ASSERT(borg_session.prepare(ai_session.arena), "Полигон готовит киборга.")
	var/mob/living/silicon/robot/training/borg = borg_session.current_body
	TEST_ASSERT(istype(borg), "Тело участника - учебный киборг.")
	TEST_ASSERT(borg.scrambledcodes, "Киборг скрыт от консоли робототехники.")
	TEST_ASSERT_EQUAL(borg.connected_ai, ai_session.current_body, "Киборг подключён к учебному ИИ арены.")

/// Свободная тренировка разрешает синтетика, предатель - нет; смена человек -> киборг -> человек.
/datum/unit_test/antag_training_role_silicon_switch/Run()
	TEST_ASSERT(antag_training_role_compatible(/datum/antag_training_program/free, antag_training_role("silicon:cyborg")), "Свободная тренировка с киборгом.")
	TEST_ASSERT(!antag_training_role_compatible(/datum/antag_training_program/antag/traitor, antag_training_role("silicon:cyborg")), "Предатель-киборг недопустим.")
	TEST_ASSERT(antag_training_role_compatible(/datum/antag_training_program/creature/blob, antag_training_role("silicon:cyborg")), "Существо роль игнорирует - пара допустима.")
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("crew:Station Engineer")
	TEST_ASSERT(session.prepare(), "Полигон готовит инженера.")
	session.next_restart_at = 0
	TEST_ASSERT(session.set_role("silicon:cyborg"), "Инженер -> киборг.")
	TEST_ASSERT(istype(session.current_body, /mob/living/silicon/robot/training), "Тело - киборг.")
	session.next_restart_at = 0
	TEST_ASSERT(!session.restart(/datum/antag_training_program/antag/traitor), "Киборгу не дают программу предателя.")
	TEST_ASSERT(istype(session.current_body, /mob/living/silicon/robot/training), "После отказа тело прежнее.")
	session.next_restart_at = 0
	TEST_ASSERT(session.set_role("crew:Station Engineer"), "Киборг -> инженер.")
	TEST_ASSERT(ishuman(session.current_body), "Тело снова человек.")
	session.next_restart_at = 0
	TEST_ASSERT(session.restart(/datum/antag_training_program/antag/traitor), "Инженер-предатель допустим.")
	session.next_restart_at = 0
	TEST_ASSERT(!session.set_role("silicon:cyborg"), "Предатель не становится киборгом.")
	TEST_ASSERT(ishuman(session.current_body), "Тело осталось человеком.")

/// Пульт не двигает ядро ИИ, а погибший ИИ восстанавливается в своём ядре, а не в вестибюле.
/datum/unit_test/antag_training_role_ai_core_fixed/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("silicon:ai")
	TEST_ASSERT(session.prepare(), "Полигон готовит ИИ.")
	var/mob/living/silicon/ai/training/core = session.current_body
	var/turf/core_spot = session.arena.hub.landmark_turf("hub_ai_core")
	TEST_ASSERT_EQUAL(get_turf(core), core_spot, "ИИ в ядре хаба.")
	var/datum/tgui/console = allocate(/datum/tgui, core, session, "AntagTraining")
	antag_training_console_act(session, console, "move", list("zone" = "melee"))
	TEST_ASSERT_EQUAL(get_turf(core), core_spot, "Кнопка зоны не переносит ядро ИИ.")
	TEST_ASSERT(findtext(session.last_feedback, "Ядро ИИ"), "ИИ объяснено, почему ядро на месте: [session.last_feedback].")
	antag_training_console_act(session, console, "hub", list())
	TEST_ASSERT_EQUAL(get_turf(core), core_spot, "Кнопка «В хаб» не переносит ядро ИИ.")
	core.death()
	var/list/budget = new_wait_budget(10 SECONDS, "восстановление ИИ")
	while(core.stat == DEAD && wait_budget_tick(budget))
		continue
	TEST_ASSERT(core.stat != DEAD, "ИИ восстановлен.")
	TEST_ASSERT_EQUAL(get_turf(core), core_spot, "ИИ восстановлен в своём ядре.")

/// Общий сброс полигона не убирает учебный ретранслятор: офицеры слышат друг друга и после него.
/datum/unit_test/antag_training_role_radio/after_reset/Run()
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/free)
	first.role = antag_training_role("crew:Security Officer")
	TEST_ASSERT(first.prepare(), "Первый офицер на полигоне.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	second.role = antag_training_role("crew:Security Officer")
	TEST_ASSERT(second.prepare(first.arena), "Второй офицер на полигоне.")
	var/datum/antag_training_arena/arena = first.arena
	var/obj/machinery/relay = arena.relay
	var/datum/tgui/first_console = allocate(/datum/tgui, first.current_body, first, "AntagTraining")
	var/datum/tgui/second_console = allocate(/datum/tgui, second.current_body, second, "AntagTraining")
	antag_training_console_act(first, first_console, "reset_zone", list("zone" = "all"))
	antag_training_console_act(second, second_console, "reset_approve", list())
	TEST_ASSERT(wait_for_var(arena, "resetting", FALSE, 1 MINUTES) && !arena.pending_reset_zone, "Общий сброс прошёл.")
	TEST_ASSERT(!QDELETED(relay) && arena.relay == relay, "Ретранслятор пережил общий сброс.")
	var/mob/living/carbon/human/trainee = first.current_body
	var/mob/living/carbon/human/partner = second.current_body
	RegisterSignal(partner, COMSIG_MOVABLE_HEAR, PROC_REF(on_hear))
	trainee.say(":s arena-reset-probe")
	TEST_ASSERT(wait_heard(partner, "arena-reset-probe"), "После общего сброса офицеры слышат друг друга.")
