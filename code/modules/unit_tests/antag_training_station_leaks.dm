#define ANTAG_TRAINING_LEAK_SIGNAL_CODE 77
#define ANTAG_TRAINING_LEAK_TRANSFER 10
#define ANTAG_TRAINING_LEAK_BALANCE 100
/// Стадия READY химгранаты: её дефайн закрыт в chem_grenade.dm.
#define ANTAG_TRAINING_LEAK_GRENADE_READY 3
/// Спящая часть емага киборга (сообщения и смена законов) длится около 7 секунд.
#define ANTAG_TRAINING_LEAK_EMAG_WAIT (8 SECONDS)

/// Гарнитура, которая запоминает сказанное в неё вместо передачи.
/obj/item/radio/headset/antag_training_leak_spy
	var/list/heard = list()

/obj/item/radio/headset/antag_training_leak_spy/talk_into(atom/movable/M, message, channel, list/spans, datum/language/language)
	heard += message
	return ITALICS | REDUCE_RANGE

/// Сигналлер, который считает принятые сигналы своего кода.
/obj/item/assembly/signaler/antag_training_leak_probe
	var/received = 0

/obj/item/assembly/signaler/antag_training_leak_probe/receive_signal(datum/signal/signal)
	if(signal?.data["code"] == code)
		received++

/datum/unit_test/antag_training_station_leaks
	var/admin_entries_before = 0

/datum/unit_test/antag_training_station_leaks/proc/start_capture()
	GLOB.unit_test_admin_messages = list()
	admin_entries_before = length(GLOB.admin_log_entries)

/// Сообщения и записи администраторам с начала захвата.
/datum/unit_test/antag_training_station_leaks/proc/captured()
	. = GLOB.unit_test_admin_messages.Copy()
	for(var/index in admin_entries_before + 1 to length(GLOB.admin_log_entries))
		. += GLOB.admin_log_entries[index]
	GLOB.unit_test_admin_messages = null

/datum/unit_test/antag_training_station_leaks/Destroy()
	GLOB.unit_test_admin_messages = null
	return ..()

/// Капитан и глава персонала полигона: без устава и бюджетных карт, устав и карта на полигоне не действуют на станцию, код сейфа на записке ложный.
/datum/unit_test/antag_training_station_leaks/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("crew:Captain")
	TEST_ASSERT(session.prepare(), "Полигон готовит капитана.")
	var/mob/living/carbon/human/captain = session.current_body
	for(var/atom/movable/kit_item as anything in captain.GetAllContents())
		TEST_ASSERT(!istype(kit_item, /obj/item/station_charter), "Капитан полигона без устава станции.")
		TEST_ASSERT(!istype(kit_item, /obj/item/syndicate_uplink/station), "Капитан полигона без станционного аплинка.")
		TEST_ASSERT(!istype(kit_item, /obj/item/card/id/departmental_budget), "Капитан полигона без бюджетной карты.")
	var/obj/item/card/id/captain_card = captain.get_idcard()
	TEST_ASSERT(captain_card && (ACCESS_CAPTAIN in captain_card.access), "Капитан полигона с капитанским доступом.")

	var/turf/arena_floor = session.arena.zones["melee"]["spawn"]
	var/old_station_name = station_name()
	var/obj/item/station_charter/charter = new(arena_floor)
	charter.admin_approved = TRUE
	charter.check_state("Training Leak Station 13", captain.name, captain.real_name, key_name(captain))
	var/renamed_to = station_name()
	if(renamed_to != old_station_name)
		set_station_name(old_station_name)
	qdel(charter)
	TEST_ASSERT_EQUAL(renamed_to, old_station_name, "Устав на полигоне не переименовывает станцию.")

	var/datum/bank_account/civilian_budget = SSeconomy.get_dep_account(ACCOUNT_CIV)
	TEST_ASSERT_NOTNULL(civilian_budget, "У станции есть гражданский бюджет.")
	var/obj/structure/closet/secure_closet/captains/locker = new(arena_floor)
	var/obj/item/card/id/departmental_budget/arena_card = locate() in locker
	TEST_ASSERT_NOTNULL(arena_card, "В капитанском шкафу на полигоне лежит бюджетная карта.")
	var/arena_card_account = arena_card.registered_account
	var/arena_card_listed = (arena_card in SSeconomy.dep_cards) || (arena_card in civilian_budget.bank_cards)
	qdel(locker)
	TEST_ASSERT_NULL(arena_card_account, "Карта шкафа на полигоне не привязана к бюджету отдела.")
	TEST_ASSERT(!arena_card_listed, "Бюджет станции не знает карту полигона.")
	var/obj/item/card/id/departmental_budget/civ/station_card = allocate(/obj/item/card/id/departmental_budget/civ)
	TEST_ASSERT(station_card.registered_account == civilian_budget, "Карта на станции по-прежнему привязана к бюджету.")

	var/obj/structure/safe/spare_id/safe = GLOB.spare_id_safe
	if(!safe)
		safe = allocate(/obj/structure/safe/spare_id)
		GLOB.spare_id_safe = safe
	var/real_code = jointext(safe.tumblers, "-")
	var/obj/item/folder/biscuit/confidential/spare_id_safe_code/station_biscuit = allocate(/obj/item/folder/biscuit/confidential/spare_id_safe_code)
	TEST_ASSERT(findtext(station_biscuit.contained_slip.get_raw_text(), real_code), "Записка на станции знает код сейфа.")
	session.next_restart_at = 0
	TEST_ASSERT(session.set_role("crew:Head of Personnel"), "Смена должности на главу персонала.")
	var/obj/item/paper/paperslip/spare_id_safe_code/slip = locate() in session.current_body.GetAllContents()
	TEST_ASSERT_NOTNULL(slip, "Глава персонала полигона получает записку с кодом.")
	TEST_ASSERT(!findtext(slip.get_raw_text(), real_code), "Записка полигона не раскрывает код сейфа станции.")

/// Учебные КПК не видны станции и наоборот, сообщения и переводы между ними не проходят.
/datum/unit_test/antag_training_station_leaks/messenger/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("crew:Security Officer")
	TEST_ASSERT(session.prepare(), "Полигон готовит офицера.")
	var/mob/living/carbon/human/officer = session.current_body
	var/obj/item/modular_computer/pda/arena_pda = locate() in officer.GetAllContents()
	TEST_ASSERT_NOTNULL(arena_pda, "У офицера полигона есть КПК.")
	var/obj/item/card/id/officer_card = new(get_turf(officer))
	officer_card.registered_name = officer.real_name
	officer_card.assignment = "Security Officer"
	arena_pda.InsertID(officer_card)
	TEST_ASSERT(arena_pda.saved_identification, "Карта в КПК полигона подписывает его именем участника.")
	var/datum/computer_file/program/messenger/arena_messenger = locate() in arena_pda.get_all_files()

	var/mob/living/carbon/human/payer = allocate(/mob/living/carbon/human)
	var/obj/item/modular_computer/pda/station_pda = allocate(/obj/item/modular_computer/pda)
	var/obj/item/card/id/payer_card = allocate(/obj/item/card/id)
	payer_card.registered_name = "Station Payer"
	var/datum/bank_account/payer_account = allocate(/datum/bank_account, "Station Payer")
	payer_account.adjust_money(ANTAG_TRAINING_LEAK_BALANCE)
	payer_card.registered_account = payer_account
	station_pda.InsertID(payer_card)
	payer.put_in_hands(station_pda)
	var/datum/computer_file/program/messenger/station_messenger = locate() in station_pda.get_all_files()
	var/obj/item/modular_computer/pda/neighbour_pda = allocate(/obj/item/modular_computer/pda)
	var/obj/item/card/id/neighbour_card = allocate(/obj/item/card/id)
	neighbour_card.registered_name = "Station Neighbour"
	neighbour_pda.InsertID(neighbour_card)
	var/datum/computer_file/program/messenger/neighbour_messenger = locate() in neighbour_pda.get_all_files()

	GLOB.pda_messenger_directory_time = -1
	var/list/station_sees = station_messenger.get_messengers()
	var/list/arena_sees = arena_messenger.get_messengers()
	TEST_ASSERT(REF(neighbour_messenger) in station_sees, "Станционный КПК видит соседа по станции.")
	TEST_ASSERT(!(REF(arena_messenger) in station_sees), "Станционный КПК не видит учебный.")
	TEST_ASSERT(!(REF(station_messenger) in arena_sees), "Учебный КПК не видит станционный.")

	// Открытый мессенджер станции попадает в общий список, как при запуске программы.
	add_messenger(station_messenger)
	add_messenger(neighbour_messenger)
	var/datum/bank_account/officer_account = allocate(/datum/bank_account, officer.real_name)
	officer_account.adjust_money(ANTAG_TRAINING_LEAK_BALANCE)
	officer_card.registered_account = officer_account
	arena_messenger.transfer_money_to_chat(officer, REF(station_messenger), ANTAG_TRAINING_LEAK_TRANSFER)
	officer_card.registered_account = null
	TEST_ASSERT_EQUAL(officer_account.account_balance, ANTAG_TRAINING_LEAK_BALANCE, "Перевод с полигона на станцию не проходит.")
	TEST_ASSERT_EQUAL(payer_account.account_balance, ANTAG_TRAINING_LEAK_BALANCE, "Счёт станции не получает перевод с полигона.")

	var/saved_debug = SSnetworks.ntnet_debug_global_signal
	SSnetworks.ntnet_debug_global_signal = TRUE
	var/station_chats_before = length(station_messenger.saved_chats)
	var/sent_from_arena = arena_messenger.send_message(officer, "Утечка с полигона", list(station_messenger))
	var/station_chats_after = length(station_messenger.saved_chats)
	var/sent_to_neighbour = station_messenger.send_message(payer, "Сосед на станции", list(neighbour_messenger))
	SSnetworks.ntnet_debug_global_signal = saved_debug
	TEST_ASSERT(!sent_from_arena, "Сообщение с полигона на станцию не отправляется.")
	TEST_ASSERT_EQUAL(station_chats_after, station_chats_before, "Сообщение с полигона не доходит до станции.")
	TEST_ASSERT(sent_to_neighbour, "Сообщение по станции отправляется.")

/// Сигнал с полигона не доходит до станции и наоборот, внутри одной стороны доходит.
/datum/unit_test/antag_training_station_leaks/signals/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/turf/arena_floor = session.arena.zones["melee"]["spawn"]
	var/list/probes = list()
	for(var/where in list("arena_sender", "arena_receiver", "station_sender", "station_receiver"))
		var/obj/item/assembly/signaler/antag_training_leak_probe/probe = new(findtext(where, "arena") ? arena_floor : run_loc_floor_bottom_left)
		probe.code = ANTAG_TRAINING_LEAK_SIGNAL_CODE
		probes[where] = probe
		allocated += probe
	var/obj/item/assembly/signaler/antag_training_leak_probe/arena_sender = probes["arena_sender"]
	var/obj/item/assembly/signaler/antag_training_leak_probe/arena_receiver = probes["arena_receiver"]
	var/obj/item/assembly/signaler/antag_training_leak_probe/station_sender = probes["station_sender"]
	var/obj/item/assembly/signaler/antag_training_leak_probe/station_receiver = probes["station_receiver"]
	arena_sender.signal()
	TEST_ASSERT_EQUAL(arena_receiver.received, 1, "Сигнал на полигоне доходит до сигналлера полигона.")
	TEST_ASSERT_EQUAL(station_receiver.received, 0, "Сигнал с полигона не доходит до станции.")
	station_sender.signal()
	TEST_ASSERT_EQUAL(station_receiver.received, 1, "Сигнал на станции доходит до станционного сигналлера.")
	TEST_ASSERT_EQUAL(arena_receiver.received, 1, "Сигнал станции не доходит до полигона.")

/// Сигналер в КПК учёного полигона будит сигналеры полигона и не будит станционные.
/datum/unit_test/antag_training_station_leaks/signals_pda/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("crew:Scientist")
	TEST_ASSERT(session.prepare(), "Полигон готовит учёного.")
	var/mob/living/carbon/human/scientist = session.current_body
	var/obj/item/modular_computer/pda/pda = locate() in scientist.GetAllContents()
	TEST_ASSERT_NOTNULL(pda, "У учёного полигона есть КПК.")
	var/datum/computer_file/program/signaler/signaler = locate() in pda.get_all_files()
	TEST_ASSERT_NOTNULL(signaler, "В КПК учёного есть сигналер.")
	var/turf/arena_floor = session.arena.zones["melee"]["spawn"]
	var/obj/item/assembly/signaler/antag_training_leak_probe/arena_receiver = allocate(/obj/item/assembly/signaler/antag_training_leak_probe, arena_floor)
	var/obj/item/assembly/signaler/antag_training_leak_probe/station_receiver = allocate(/obj/item/assembly/signaler/antag_training_leak_probe, run_loc_floor_bottom_left)
	for(var/obj/item/assembly/signaler/antag_training_leak_probe/probe as anything in list(arena_receiver, station_receiver))
		probe.code = signaler.signal_code
		probe.set_frequency(signaler.signal_frequency)
	var/datum/tgui/ui = allocate(/datum/tgui, scientist, pda, "NtosSignaler")
	ui.status = UI_INTERACTIVE
	usr = scientist
	signaler.ui_act("signal", list(), ui)
	usr = null
	TEST_ASSERT_EQUAL(arena_receiver.received, 1, "Сигнал КПК полигона доходит до сигналера полигона.")
	TEST_ASSERT_EQUAL(station_receiver.received, 0, "Сигнал КПК полигона не доходит до станции.")

/// Журнал законов пишет загрузку по владельцу законов: учебный киборг со станции не попадает в журнал, станционный ИИ с полигона попадает.
/datum/unit_test/antag_training_station_leaks/law_owner/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("silicon:cyborg")
	TEST_ASSERT(session.prepare(), "Полигон готовит киборга.")
	var/mob/living/silicon/robot/training/borg = session.current_body
	var/mob/living/carbon/human/station_admin = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/ai_module/core/full/asimov/law_board = allocate(/obj/item/ai_module/core/full/asimov, run_loc_floor_bottom_left)
	var/lawchanges_before = length(GLOB.lawchanges)
	start_capture()
	law_board.install(borg.laws, station_admin)
	var/list/noise = captured()
	TEST_ASSERT(!length(noise), "Законы учебного киборга, загруженные со станции, не пишут администраторам: [jointext(noise, "; ")].")
	TEST_ASSERT_EQUAL(length(GLOB.lawchanges), lawchanges_before, "Законы учебного киборга не попадают в журнал законов станции.")

	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/silicon/ai/station_ai = allocate(/mob/living/silicon/ai, run_loc_floor_bottom_left, null, donor)
	lawchanges_before = length(GLOB.lawchanges)
	start_capture()
	law_board.install(station_ai.laws, borg)
	noise = captured()
	TEST_ASSERT_EQUAL(length(GLOB.lawchanges), lawchanges_before + 1, "Загрузка законов станционному ИИ с полигона попадает в журнал законов.")
	TEST_ASSERT(length(noise), "Загрузка законов станционному ИИ с полигона видна администраторам.")

/// Отказ учебного киборга не объявляется в научный канал станции.
/datum/unit_test/antag_training_station_leaks/cyborg_death/Run()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/obj/machinery/announcement_system/announcer = allocate(/obj/machinery/announcement_system, locate(2, 2, station_z))
	announcer.machine_stat = NONE
	qdel(announcer.radio)
	var/obj/item/radio/headset/antag_training_leak_spy/spy = new(announcer)
	announcer.radio = spy
	GLOB.announcement_systems -= announcer
	GLOB.announcement_systems.Insert(1, announcer)
	TEST_ASSERT(announcer.is_operational(), "Система оповещений станции работает.")

	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("silicon:cyborg")
	TEST_ASSERT(session.prepare(), "Полигон готовит киборга.")
	var/mob/living/silicon/robot/training/borg = session.current_body
	TEST_ASSERT(istype(borg), "Тело участника - учебный киборг.")
	borg.death()
	TEST_ASSERT_EQUAL(borg.stat, DEAD, "Киборг умер.")
	TEST_ASSERT(!length(spy.heard), "Смерть учебного киборга не объявлена станции: [jointext(spy.heard, "; ")].")

/// Емаг учебного киборга не пишет администраторам и в журнал законов.
/datum/unit_test/antag_training_station_leaks/cyborg_emag/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("silicon:cyborg")
	TEST_ASSERT(session.prepare(), "Полигон готовит киборга.")
	var/mob/living/silicon/robot/training/borg = session.current_body
	var/mob/living/carbon/human/emagger = new(get_turf(borg))
	allocated += emagger
	borg.opened = TRUE
	borg.locked = FALSE
	borg.wiresexposed = FALSE
	var/lawchanges_before = length(GLOB.lawchanges)
	start_capture()
	borg.emag_act(emagger)
	var/list/noise = captured()
	var/lawchanges_after = length(GLOB.lawchanges)
	sleep(ANTAG_TRAINING_LEAK_EMAG_WAIT)
	TEST_ASSERT(borg.emagged, "Емаг взламывает учебного киборга.")
	TEST_ASSERT(!length(noise), "Емаг учебного киборга не пишет администраторам: [jointext(noise, "; ")].")
	TEST_ASSERT_EQUAL(lawchanges_after, lawchanges_before, "Емаг учебного киборга не попадает в журнал законов.")

/// Морозильник и химгранаты с запалом на полигоне не пишут администраторам.
/datum/unit_test/antag_training_station_leaks/admin_noise/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/mob/living/carbon/human/participant = session.current_body
	var/turf/arena_floor = session.arena.zones["melee"]["spawn"]
	participant.forceMove(arena_floor)
	participant.drop_all_held_items()

	var/obj/machinery/atmospherics/components/unary/thermomachine/freezer/freezer = new(arena_floor)
	var/was_on = freezer.on
	start_capture()
	freezer.CtrlClick(participant)
	var/list/noise = captured()
	var/switched = freezer.on != was_on
	qdel(freezer)
	TEST_ASSERT(switched, "Ctrl-клик переключает морозильник полигона.")
	TEST_ASSERT(!length(noise), "Морозильник полигона не пишет администраторам: [jointext(noise, "; ")].")

	var/obj/item/ai_module/core/full/asimov/law_board = new(arena_floor)
	var/datum/ai_laws/laws = new
	var/lawchanges_before = length(GLOB.lawchanges)
	start_capture()
	law_board.install(laws, participant)
	noise = captured()
	qdel(law_board)
	qdel(laws)
	TEST_ASSERT(!length(noise), "Загрузка законов на полигоне не пишет администраторам: [jointext(noise, "; ")].")
	TEST_ASSERT_EQUAL(length(GLOB.lawchanges), lawchanges_before, "Загрузка законов на полигоне не попадает в журнал законов раунда.")

	for(var/grenade_type in list(/obj/item/grenade/chem_grenade, /obj/item/grenade/chem_grenade/adv_release))
		var/obj/item/grenade/chem_grenade/grenade = new grenade_type(arena_floor)
		var/obj/item/assembly_holder/fuse = new(arena_floor)
		fuse.assemble(new /obj/item/assembly/igniter(arena_floor), new /obj/item/assembly/signaler(arena_floor), null)
		participant.put_in_hands(fuse)
		grenade.attackby(fuse, participant)
		var/obj/item/reagent_containers/glass/beaker/beaker = new(arena_floor)
		beaker.reagents.add_reagent(/datum/reagent/water, 10)
		participant.put_in_hands(beaker)
		grenade.attackby(beaker, participant)
		var/obj/item/screwdriver/screwdriver = new(arena_floor)
		participant.put_in_hands(screwdriver)
		grenade.attackby(screwdriver, participant)
		qdel(screwdriver)
		var/assembled = grenade.stage == ANTAG_TRAINING_LEAK_GRENADE_READY && grenade.nadeassembly == fuse
		start_capture()
		fuse.process_activation(fuse.a_right)
		noise = captured()
		if(!QDELETED(grenade))
			qdel(grenade)
		TEST_ASSERT(assembled, "[grenade_type] с запалом собрана.")
		TEST_ASSERT(!length(noise), "[grenade_type] с запалом на полигоне не пишет администраторам: [jointext(noise, "; ")].")

/// Плазмамен в должности офицера одет как на станции: ID с доступом, гарнитура и дыхание из баллона.
/datum/unit_test/antag_training_station_leaks/plasmaman_role/Run()
	var/datum/preferences/preferences = new
	allocated += preferences
	preferences.pref_species = new /datum/species/plasmaman
	preferences.real_name = "Training Plasmaman"
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free, preferences)
	session.role = antag_training_role("crew:Security Officer")
	TEST_ASSERT(session.prepare(), "Полигон готовит офицера-плазмамена.")
	var/mob/living/carbon/human/body = session.current_body
	TEST_ASSERT(isplasmaman(body), "Тело участника - плазмамен.")
	var/obj/item/card/id/card = body.get_idcard()
	TEST_ASSERT(card && (ACCESS_SECURITY in card.access), "Плазмамен-офицер с ID и доступом СБ.")
	TEST_ASSERT(istype(body.ears, /obj/item/radio/headset/headset_sec), "Плазмамен-офицер с гарнитурой СБ.")
	var/obj/item/tank/breath = body.internal
	TEST_ASSERT(istype(breath) && breath.air_contents.get_moles(GAS_PLASMA) > 0, "Плазмамен дышит плазмой из баллона.")

#undef ANTAG_TRAINING_LEAK_SIGNAL_CODE
#undef ANTAG_TRAINING_LEAK_TRANSFER
#undef ANTAG_TRAINING_LEAK_BALANCE
#undef ANTAG_TRAINING_LEAK_GRENADE_READY
#undef ANTAG_TRAINING_LEAK_EMAG_WAIT
