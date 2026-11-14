/datum/unit_test/proc/antag_training_nukeop_kit(datum/antag_training_session/session)
	var/datum/antag_training_program/antag/nukeop/program = session.program
	var/list/budget = new_wait_budget(30 SECONDS, "учебные бомба и диск в хранилище")
	while(!program.training_bomb() || !program.training_disk())
		if(!wait_budget_tick(budget))
			return FALSE
	return TRUE

/datum/unit_test/proc/antag_training_nukeop_uplink(mob/living/carbon/human/body)
	var/obj/item/inteq/uplink/radio/nuclear/training/radio = locate() in body.GetAllContents()
	return radio?.GetComponent(/datum/component/uplink)

/datum/unit_test/proc/antag_training_chat_heard(mob/listener, marker)
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		var/target = entry[1]
		if((target == listener || (islist(target) && (listener in target))) && findtext(entry[2], marker))
			return TRUE
	return FALSE

/obj/item/disk/nuclear/unit_test_authentic
	stationloving = FALSE

/obj/item/disk/nuclear/unit_test_authentic/Initialize(mapload)
	. = ..()
	GLOB.poi_list -= src
	STOP_PROCESSING(SSobj, src)

/proc/antag_training_nuke_codes()
	var/list/codes = list()
	for(var/obj/machinery/nuclearbomb/bomb as anything in GLOB.nuke_list)
		codes += "[REF(bomb)]=[bomb.r_code]"
	return jointext(codes, ", ")

/// Программа выдаёт оперативника и лидера с учебной командой вне раунда, аплинком без подкреплений и кодом учебной бомбы; бомбы раунда не меняются.
/datum/unit_test/antag_training_nukeop_setup/Run()
	var/nukes_before = antag_training_nuke_codes()
	var/teams_before = length(GLOB.antagonist_teams)
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/nukeop)
	TEST_ASSERT(session.prepare(), "Полигон готовит оперативника.")
	var/datum/antag_training_program/antag/nukeop/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/nukeop/training/role = program.role(session)
	TEST_ASSERT(istype(role) && !role.leader, "Кукла получает учебного оперативника.")
	TEST_ASSERT(istype(role.nuke_team, /datum/team/nuclear/training) && role.nuke_team == program.team, "Команда оперативника - учебная команда программы.")
	TEST_ASSERT(!(role.nuke_team in GLOB.antagonist_teams), "Учебной команды нет среди команд раунда.")
	TEST_ASSERT(!(role in GLOB.antagonists) && !(role.owner in get_antag_minds(/datum/antagonist/nukeop)), "Сканеры оперативников раунда учебного не видят.")
	TEST_ASSERT_NULL(role.nuke_team.roundend_report(), "Учебная команда не пишет итог раунда.")

	var/datum/component/uplink/antag_training/nuclear/uplink = antag_training_nukeop_uplink(body)
	TEST_ASSERT(istype(uplink) && !uplink.allow_restricted && uplink.uplink_flag == UPLINK_NUKE_OPS, "В рюкзаке учебная аплинк-рация оперативника без закрытых позиций.")
	TEST_ASSERT_EQUAL(uplink.telecrystals, antag_training_nukeop_telecrystals(), "На счету рации полный запас оперативника.")
	TEST_ASSERT(isnull(uplink.owner) && isnull(uplink.purchase_log?.owner), "Лог покупок рации без владельца.")
	for(var/support in list(/datum/uplink_item/support/reinforcement, /datum/uplink_item/support/reinforcement/assault_borg, /datum/uplink_item/support/reinforcement/medical_borg, /datum/uplink_item/device_tools/assault_pod))
		TEST_ASSERT_NULL(antag_training_uplink_entry(uplink, support), "[support] нет в учебном аплинке.")
	TEST_ASSERT_NULL(locate(/obj/item/nuclear_challenge) in body.GetAllContents(), "Объявления войны нет.")
	TEST_ASSERT_NULL(locate(/obj/item/implant/explosive) in (body.implants || list()), "Микробомбы в теле нет.")
	TEST_ASSERT(istype(body.w_uniform, /obj/item/clothing/under/inteq) && istype(body.l_store, /obj/item/pinpointer/nuke_training), "Наряд оперативника заменил одежду участника.")
	TEST_ASSERT(locate(/obj/item/restraints/handcuffs) in body.back, "Наручники участника переложены в рюкзак.")
	TEST_ASSERT(role.nuke_team.memorized_code == program.nuke_code && findtext(role.antag_memory, program.nuke_code), "Код учебной бомбы записан в заметках роли.")
	TEST_ASSERT(findtext(role.briefing(), program.nuke_code), "Приветствие называет код учебной бомбы.")
	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")

	TEST_ASSERT(antag_training_nukeop_kit(session), "Учебные бомба и диск появляются.")
	var/obj/machinery/nuclearbomb/training/bomb = program.training_bomb()
	var/obj/item/disk/nuclear/training/disk = program.training_disk()
	var/datum/antag_training_sector/station = session.arena.sectors["station"]
	var/turf/vault = station.landmark_turf("vault")
	TEST_ASSERT_EQUAL(get_turf(bomb), vault, "Бомба стоит в хранилище макета.")
	TEST_ASSERT(get_area(disk) == get_area(vault) && get_dist(disk, vault) <= 1, "Диск лежит в хранилище макета.")
	TEST_ASSERT_EQUAL(bomb.r_code, program.nuke_code, "Код роли - код учебной бомбы.")
	TEST_ASSERT_EQUAL(antag_training_nuke_codes(), nukes_before, "Бомбы раунда и их коды не меняются.")
	TEST_ASSERT(!(bomb in GLOB.nuke_list) && !(bomb in GLOB.poi_list) && !(disk in GLOB.poi_list), "Учебные бомба и диск не в списках раунда.")
	TEST_ASSERT(!disk.GetComponent(/datum/component/stationloving) && !(disk.datum_flags & DF_ISPROCESSING), "Диск не тянется на станцию и не меняет веса директора.")
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, get_turf(disk))
	var/ghost_view = jointext(disk.examine(ghost), " ")
	TEST_ASSERT(!findtext(ghost_view, "fake") && findtext(ghost_view, "Учебный диск"), "Призрак видит учебный диск, а не подделку.")
	var/verifier_view = jointext(disk.examine_more(body), " ")
	TEST_ASSERT(HAS_TRAIT(body.mind, TRAIT_DISK_VERIFIER) && !findtext(verifier_view, "incorrect") && findtext(verifier_view, "учебные"), "Оперативник видит учебные серийные номера, а не неверные.")
	var/obj/item/pinpointer/nuke_training/pinpointer = body.l_store
	pinpointer.scan_for_target()
	TEST_ASSERT_EQUAL(pinpointer.target, disk, "Учебный пинпоинтер ведёт к учебному диску.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Сменить роль: Лидер"))
	var/datum/antagonist/nukeop/training/leader = program.role(session)
	TEST_ASSERT(QDELETED(role) && istype(leader) && leader.leader, "Кнопка выбора перевыдаёт роль лидером.")
	TEST_ASSERT(leader.nuke_team == program.team && length(program.team.members) == 1, "Лидер остаётся единственным в той же учебной команде.")
	var/obj/item/paper/code_paper = locate() in body.held_items
	TEST_ASSERT_EQUAL(code_paper?.name, "training nuclear bomb code", "Лидер получает бумагу с кодом.")
	antag_training_console_act(session, console, "program_option", list("option" = "Сменить роль: Оперативник"))
	antag_training_console_act(session, console, "program_option", list("option" = "Сменить роль: Лидер"))
	leader = program.role(session)
	var/papers = 0
	var/turf/leader_spot = get_turf(body)
	for(var/obj/item/paper/paper in body.GetAllContents() + leader_spot.contents)
		if(paper.name == "training nuclear bomb code")
			papers++
	TEST_ASSERT(QDELETED(code_paper) && papers == 1, "Повторная смена на лидера заменяет бумагу с кодом, а не добавляет новую.")
	TEST_ASSERT_NOTNULL(locate(/obj/item/card/id/inteq/nuke_leader) in body.GetAllContents(), "Лидер получает карту лидера.")
	TEST_ASSERT_NULL(locate(/obj/item/nuclear_challenge) in body.GetAllContents(), "Лидер не получает объявления войны.")
	TEST_ASSERT_EQUAL(leader.training_uplink(), uplink, "Новая роль находит прежнюю аплинк-рацию.")
	var/radios = 0
	for(var/obj/item/inteq/uplink/radio/nuclear/training/radio in body.GetAllContents())
		radios++
	TEST_ASSERT_EQUAL(radios, 1, "Аплинк-рация одна.")
	TEST_ASSERT_EQUAL(length(GLOB.antagonist_teams), teams_before, "Команды раунда не меняются.")

	var/datum/antag_training_session/rival = allocate_training_session(/datum/antag_training_program/antag/nukeop)
	TEST_ASSERT(rival.prepare(), "Полигон готовит второго оперативника.")
	TEST_ASSERT(antag_training_nukeop_kit(rival), "У второго оперативника свои бомба и диск.")
	var/datum/antag_training_program/antag/nukeop/rival_program = rival.program
	var/obj/item/pinpointer/nuke_training/rival_pinpointer = locate() in rival.current_body.GetAllContents()
	rival_pinpointer.scan_for_target()
	pinpointer.scan_for_target()
	TEST_ASSERT(rival_pinpointer.target == rival_program.training_disk() && pinpointer.target == disk, "Пинпоинтер каждого оперативника ведёт к диску своей программы.")

/// Диск, код и взвод через пульт бомбы запускают учебный отсчёт; учебный взрыв вспыхивает только участникам, возвращает бомбу и диск в хранилище и не трогает тревогу, вход и раунд.
/datum/unit_test/antag_training_nukeop_detonation/Run()
	var/security_before = GLOB.security_level
	var/enter_before = GLOB.enter_allowed
	var/roundend_paused_before = SSticker.roundend_check_paused
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/nukeop)
	TEST_ASSERT(session.prepare(), "Полигон готовит оперативника.")
	TEST_ASSERT(antag_training_nukeop_kit(session), "Учебные бомба и диск появляются.")
	var/datum/antag_training_program/antag/nukeop/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/obj/machinery/nuclearbomb/training/bomb = program.training_bomb()
	var/obj/item/disk/nuclear/training/disk = program.training_disk()
	var/turf/vault = get_turf(bomb)
	var/turf/disk_spot = get_turf(disk)

	body.forceMove(disk_spot)
	var/datum/tgui/panel = allocate(/datum/tgui, body, bomb, "NuclearBomb")
	panel.status = UI_INTERACTIVE
	var/obj/item/disk/nuclear/unit_test_authentic/station_disk = allocate(/obj/item/disk/nuclear/unit_test_authentic, disk_spot)
	TEST_ASSERT(body.put_in_hands(station_disk), "Участник держит неучебный диск.")
	usr = body
	bomb.ui_act("eject_disk", list(), panel)
	usr = null
	TEST_ASSERT(isnull(bomb.auth) && (station_disk in body.held_items), "Учебная бомба не принимает неучебный диск.")
	qdel(station_disk)
	disk.attack_hand(body)
	TEST_ASSERT(disk in body.held_items, "Участник берёт учебный диск.")
	usr = body
	bomb.ui_act("eject_disk", list(), panel)
	TEST_ASSERT_EQUAL(bomb.auth, disk, "Пульт бомбы принимает диск из рук.")
	for(var/index in 1 to length(program.nuke_code))
		bomb.ui_act("keypad", list("digit" = copytext(program.nuke_code, index, index + 1)), panel)
	bomb.ui_act("keypad", list("digit" = "E"), panel)
	TEST_ASSERT(bomb.yes_code, "Код учебной бомбы принят.")
	var/timer_text = "[ANTAG_TRAINING_NUKE_TIMER / (1 SECONDS)]"
	for(var/index in 1 to length(timer_text))
		bomb.ui_act("keypad", list("digit" = copytext(timer_text, index, index + 1)), panel)
	bomb.ui_act("keypad", list("digit" = "E"), panel)
	TEST_ASSERT(!bomb.safety, "Время задано, предохранитель снят.")
	bomb.ui_act("arm", list(), panel)
	usr = null
	TEST_ASSERT(bomb.timing, "Бомба взведена.")
	TEST_ASSERT_EQUAL(round(bomb.detonation_timer - world.time, 1), ANTAG_TRAINING_NUKE_TIMER, "Учебный отсчёт - ANTAG_TRAINING_NUKE_TIMER.")
	TEST_ASSERT_EQUAL(GLOB.security_level, security_before, "Взвод не меняет уровень тревоги станции.")

	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/pinpointer/nuke/station_pinpointer = allocate(/obj/item/pinpointer/nuke, run_loc_floor_bottom_left)
	TEST_ASSERT(!findtext(jointext(station_pinpointer.examine(bystander), " "), "Arming signal"), "Пинпоинтер станции не замечает взведённую учебную бомбу.")

	bomb.detonation_timer = world.time - 1
	GLOB.unit_test_chat_capture = list()
	bomb.process()
	TEST_ASSERT(antag_training_chat_heard(body, "Учебная бомба взорвана"), "Участник получает сообщение об учебном взрыве.")
	TEST_ASSERT(!antag_training_chat_heard(bystander, "Учебная бомба взорвана"), "Человек вне полигона сообщения не получает.")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT_NOTNULL(body.fullscreens["flash"], "Вспышка учебного взрыва достаётся участнику.")
	TEST_ASSERT_NULL(bystander.fullscreens["flash"], "Человек вне полигона вспышки не видит.")
	TEST_ASSERT(program.detonation_objective.completed, "Учебная задача засчитана.")
	TEST_ASSERT(!bomb.timing && !bomb.exploding && bomb.safety && !bomb.auth, "После взрыва бомба выключена и без диска.")
	TEST_ASSERT_EQUAL(get_turf(bomb), vault, "Бомба вернулась в хранилище.")
	TEST_ASSERT_EQUAL(get_turf(disk), disk_spot, "Диск вернулся в хранилище.")
	TEST_ASSERT_EQUAL(GLOB.security_level, security_before, "Уровень тревоги станции прежний.")
	TEST_ASSERT_EQUAL(GLOB.enter_allowed, enter_before, "Вход в раунд не закрыт.")
	TEST_ASSERT(SSticker.roundend_check_paused == roundend_paused_before && !SSticker.mode.station_was_nuked, "Раунд не ждёт синематика и не считает станцию взорванной.")

	disk.attack_hand(body)
	TEST_ASSERT(disk in body.held_items, "Участник снова берёт диск.")
	bomb.forceMove(get_step(vault, NORTH))
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	session.next_supply_at = 0
	antag_training_console_act(session, console, "program_option", list("option" = "Вернуть бомбу и диск"))
	TEST_ASSERT(get_turf(bomb) == vault && get_turf(disk) == disk_spot && !(disk in body.held_items), "«Вернуть бомбу и диск» забирает диск из рук и ставит обоих в хранилище.")
	qdel(session)
	TEST_ASSERT(QDELETED(bomb) && QDELETED(disk), "Выход убирает учебные бомбу и диск.")

/// Учебный аплинк оперативника отказывает в закрытых предметах без списания ТК, открытые наборы не несут закрытого, «Пополнить ТК» доводит счёт и выдаёт потерянную рацию.
/datum/unit_test/antag_training_nukeop_uplink/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/nukeop)
	TEST_ASSERT(session.prepare(), "Полигон готовит оперативника.")
	var/mob/living/carbon/human/body = session.current_body
	var/datum/component/uplink/antag_training/nuclear/uplink = antag_training_nukeop_uplink(body)
	TEST_ASSERT(uplink?.active, "Аплинк-рация открыта.")
	uplink.telecrystals = antag_training_nukeop_telecrystals() * 10
	for(var/station_effect in list(/datum/uplink_item/dangerous/nukieguardian, /datum/uplink_item/device_tools/singularity_beacon, /datum/uplink_item/support/monkey_agent, /datum/uplink_item/bundles_tc/surplus/super))
		var/datum/uplink_item/item = antag_training_uplink_entry(uplink, station_effect)
		TEST_ASSERT(item && uplink.blocked_reason(item), "[station_effect] есть в магазине оперативника и закрыт на полигоне.")
	var/turf/counter = get_turf(body)
	var/items_before = length(body.GetAllContents()) + length(counter.contents)
	var/blocked = 0
	for(var/category in uplink.uplink_items)
		for(var/item_name in uplink.uplink_items[category])
			var/datum/uplink_item/item = uplink.uplink_items[category][item_name]
			if(!uplink.blocked_reason(item))
				continue
			blocked++
			antag_training_uplink_buy(uplink, body, item)
			TEST_ASSERT_EQUAL(uplink.telecrystals, antag_training_nukeop_telecrystals() * 10, "[item.type]: ТК не списаны.")
			TEST_ASSERT(findtext(uplink.refusal(item), "На полигоне недоступно"), "[item.type]: отказ объясняет закрытый предмет.")
	TEST_ASSERT(blocked, "Закрытые предметы проверены.")
	TEST_ASSERT_EQUAL(length(body.GetAllContents()) + length(counter.contents), items_before, "Закрытые предметы не появляются.")

	var/list/closed_paths = list(/obj/item/nuclear_challenge, /obj/item/antag_spawner, /obj/item/guardiancreator, /obj/item/implanter/uplink, /obj/item/modular_computer/pda, /obj/item/inteq_drone_creator)
	var/list/closed_types = list()
	var/list/problems = list()
	for(var/blocked_type in GLOB.antag_training_blocked_uplink_items)
		var/datum/uplink_item/closed = blocked_type
		if(ispath(initial(closed.item), /obj/item))
			closed_types |= initial(closed.item)
	for(var/category in uplink.uplink_items)
		if(category == "Discounted Gear")
			continue
		for(var/item_name in uplink.uplink_items[category])
			var/datum/uplink_item/item = uplink.uplink_items[category][item_name]
			if(uplink.blocked_reason(item) || !ispath(item.item, /obj) || ispath(item.item, /obj/effect))
				continue
			var/obj/sold = new item.item(counter)
			for(var/atom/movable/content as anything in sold.GetAllContents())
				var/datum/component/uplink/hidden = content.GetComponent(/datum/component/uplink)
				if((hidden && !istype(hidden, /datum/component/uplink/antag_training)) || is_type_in_list(content, closed_paths) || (content.type in closed_types))
					problems += "[item.type]: [content.type]"
			qdel(sold)
	TEST_ASSERT(!length(problems), "Открытые предметы несут закрытое на полигоне: [jointext(problems, "; ")].")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	uplink.telecrystals = 0
	antag_training_console_act(session, console, "program_option", list("option" = "Пополнить ТК"))
	TEST_ASSERT_EQUAL(uplink.telecrystals, antag_training_nukeop_telecrystals(), "«Пополнить ТК» доводит счёт до полного.")
	qdel(uplink.parent)
	session.next_supply_at = 0
	antag_training_console_act(session, console, "program_option", list("option" = "Пополнить ТК"))
	var/obj/item/inteq/uplink/radio/nuclear/training/radio = locate() in body.held_items
	var/datum/component/uplink/antag_training/nuclear/fresh = radio?.GetComponent(/datum/component/uplink)
	TEST_ASSERT(istype(fresh) && fresh.telecrystals == antag_training_nukeop_telecrystals(), "Потерянная рация выдаётся заново с полным счётом.")
	TEST_ASSERT(session.arena.owns_area(get_area(radio)), "Новая рация на полигоне.")

/datum/unit_test/antag_training_nukeop_detonation/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/// Канал InteQ не связывает полигон со станцией: радио раунда слышат друг друга, учебная гарнитура не слышит их, а сигнал с полигона не доходит до станции и через перехват all-in-one.
/datum/unit_test/antag_training_nukeop_radio
	var/list/hearings = list()

/datum/unit_test/antag_training_nukeop_radio/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/nukeop)
	TEST_ASSERT(session.prepare(), "Полигон готовит оперативника.")
	var/mob/living/carbon/human/trainee = session.current_body
	var/obj/item/radio/headset/inteq/alt/arena_headset = trainee.ears
	TEST_ASSERT(istype(arena_headset) && arena_headset.frequency == FREQ_INTEQ, "Учебный оперативник носит гарнитуру InteQ на частоте InteQ.")
	var/obj/machinery/telecomms/allinone/relay = allocate(/obj/machinery/telecomms/allinone, run_loc_floor_top_right)
	relay.intercept = TRUE
	relay.freq_listening = list(FREQ_SYNDICATE, FREQ_INTEQ, FREQ_PIRATE)
	var/mob/living/carbon/human/agent = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	for(var/mob/living/carbon/human/listener as anything in list(agent, partner))
		var/obj/item/radio/headset/inteq/alt/headset = allocate(/obj/item/radio/headset/inteq/alt, get_turf(listener))
		headset.set_frequency(FREQ_INTEQ)
		TEST_ASSERT(listener.equip_to_slot_if_possible(headset, ITEM_SLOT_EARS_LEFT), "Агент раунда надевает гарнитуру InteQ.")
	for(var/mob/listener as anything in list(trainee, agent, partner))
		RegisterSignal(listener, COMSIG_MOVABLE_HEAR, PROC_REF(on_hear))

	agent.say("; inteq-station-probe")
	TEST_ASSERT(heard(partner, "inteq-station-probe"), "Радио InteQ раунда слышат друг друга.")
	TEST_ASSERT(!heard(trainee, "inteq-station-probe"), "Учебная гарнитура не слышит InteQ раунда.")
	trainee.say("; inteq-arena-probe")
	TEST_ASSERT(!heard(agent, "inteq-arena-probe") && !heard(partner, "inteq-arena-probe"), "Радио InteQ раунда не слышат учебную гарнитуру.")
	var/atom/movable/virtualspeaker/speaker = new(null, trainee, arena_headset)
	allocated += speaker
	relay.receive_signal(new /datum/signal/subspace/vocal(arena_headset, FREQ_INTEQ, speaker, null, "inteq-relay-probe", list()))
	TEST_ASSERT(!heard(agent, "inteq-relay-probe") && !heard(partner, "inteq-relay-probe"), "Перехват all-in-one не доносит сигнал полигона до радио раунда.")

/datum/unit_test/antag_training_nukeop_radio/proc/on_hear(mob/source, list/hearing_args)
	SIGNAL_HANDLER
	hearings += list(list(source, hearing_args[HEARING_RAW_MESSAGE]))

/datum/unit_test/antag_training_nukeop_radio/proc/heard(mob/listener, marker)
	for(var/list/entry as anything in hearings)
		if(entry[1] == listener && findtext(entry[2], marker))
			return TRUE
	return FALSE

/// «Сменить роль: Клоун-оперативник» выдаёт учебного клоуна с клоунским набором и магазином клоунов-оперативников в той же рации, без подкреплений, Clown Bomb, микробомбы и объявления войны; смена роли обратно снимает клоунское.
/datum/unit_test/antag_training_nukeop_clownop/Run()
	var/teams_before = length(GLOB.antagonist_teams)
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/nukeop)
	TEST_ASSERT(session.prepare(), "Полигон готовит оперативника.")
	var/datum/antag_training_program/antag/nukeop/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/component/uplink/antag_training/nuclear/uplink = antag_training_nukeop_uplink(body)
	TEST_ASSERT(istype(uplink) && uplink.uplink_flag == UPLINK_NUKE_OPS, "Оперативник начинает с рацией магазина оперативников.")
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option("clownop")))
	var/datum/antagonist/nukeop/training/clownop/clown = program.role(session)
	TEST_ASSERT(istype(clown) && !clown.leader, "Кнопка выдаёт учебного клоуна-оперативника.")
	TEST_ASSERT(clown.nuke_team == program.team && !(clown.nuke_team in GLOB.antagonist_teams), "Клоун в учебной команде программы, вне команд раунда.")
	TEST_ASSERT(!(clown in GLOB.antagonists) && !(clown.owner in get_antag_minds(/datum/antagonist/nukeop)), "Сканеры оперативников раунда учебного клоуна не видят.")
	TEST_ASSERT(HAS_TRAIT(body.mind, TRAIT_CLOWN_MENTALITY), "Клоун получает клоунское мышление.")
	TEST_ASSERT(istype(body.shoes, /obj/item/clothing/shoes/clown_shoes/combat) && istype(body.wear_mask, /obj/item/clothing/mask/gas/clown_hat), "Клоун в боевых клоунских ботинках и маске.")
	TEST_ASSERT(locate(/obj/item/bikehorn) in body.GetAllContents(), "При клоуне гудок.")
	TEST_ASSERT_NULL(locate(/obj/item/nuclear_challenge) in body.GetAllContents(), "Объявления войны нет.")
	TEST_ASSERT_NULL(locate(/obj/item/implant/explosive) in (body.implants || list()), "Микробомбы в теле нет.")
	var/briefing = clown.briefing()
	TEST_ASSERT(findtext(briefing, "клоуна-оперативника") && findtext(briefing, program.nuke_code), "Приветствие клоуна называет роль и код учебной бомбы.")
	var/list/data = session.ui_data(body)
	TEST_ASSERT(length(data["option_hints"][program.choice_option("clownop")]), "У кнопки клоуна есть подсказка.")

	TEST_ASSERT_EQUAL(antag_training_nukeop_uplink(body), uplink, "Клоун получает прежнюю аплинк-рацию.")
	var/radios = 0
	for(var/obj/item/inteq/uplink/radio/nuclear/training/radio in body.GetAllContents())
		radios++
	TEST_ASSERT_EQUAL(radios, 1, "Аплинк-рация одна.")
	TEST_ASSERT_EQUAL(uplink.uplink_flag, UPLINK_CLOWN_OPS, "Рация открывает магазин клоунов-оперативников.")
	TEST_ASSERT_NOTNULL(antag_training_uplink_entry(uplink, /datum/uplink_item/dangerous/clownsword), "В магазине клоуна бананиевый меч.")
	TEST_ASSERT_NULL(antag_training_uplink_entry(uplink, /datum/uplink_item/support/clown_reinforcement), "Подкреплений клоунов в магазине нет.")
	var/datum/uplink_item/clown_bomb = antag_training_uplink_entry(uplink, /datum/uplink_item/explosives/clown_bomb_clownops)
	TEST_ASSERT(clown_bomb && findtext(uplink.refusal(clown_bomb), "На полигоне недоступно"), "Clown Bomb в магазине закрыта на полигоне.")
	var/turf/counter = get_turf(body)
	var/telecrystals = uplink.telecrystals
	antag_training_uplink_buy(uplink, body, clown_bomb)
	TEST_ASSERT_EQUAL(uplink.telecrystals, telecrystals, "Clown Bomb не продаётся и ТК не списывает.")
	TEST_ASSERT_NULL(locate(/obj/item/sbeacondrop) in (body.GetAllContents() + counter.contents), "Маяк бомбы не появляется.")

	var/list/closed_paths = list(/obj/item/nuclear_challenge, /obj/item/antag_spawner, /obj/item/guardiancreator, /obj/item/implanter/uplink, /obj/item/modular_computer/pda, /obj/item/inteq_drone_creator, /obj/item/sbeacondrop)
	var/list/problems = list()
	for(var/category in uplink.uplink_items)
		if(category == "Discounted Gear")
			continue
		for(var/item_name in uplink.uplink_items[category])
			var/datum/uplink_item/item = uplink.uplink_items[category][item_name]
			if(uplink.blocked_reason(item) || (item.purchasable_from & UPLINK_NUKE_OPS) || !ispath(item.item, /obj) || ispath(item.item, /obj/effect))
				continue
			var/obj/sold = new item.item(counter)
			for(var/atom/movable/content as anything in sold.GetAllContents())
				var/datum/component/uplink/hidden = content.GetComponent(/datum/component/uplink)
				if((hidden && !istype(hidden, /datum/component/uplink/antag_training)) || is_type_in_list(content, closed_paths))
					problems += "[item.type]: [content.type]"
			qdel(sold)
	TEST_ASSERT(!length(problems), "Клоунские предметы несут закрытое на полигоне: [jointext(problems, "; ")].")

	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option("operative")))
	var/datum/antagonist/nukeop/training/operative = program.role(session)
	TEST_ASSERT(QDELETED(clown) && istype(operative) && !istype(operative, /datum/antagonist/nukeop/training/clownop), "Смена роли возвращает оперативника.")
	TEST_ASSERT(!HAS_TRAIT(body.mind, TRAIT_CLOWN_MENTALITY), "Клоунское мышление снято.")
	TEST_ASSERT(!istype(body.shoes, /obj/item/clothing/shoes/clown_shoes) && !istype(body.wear_mask, /obj/item/clothing/mask/gas/clown_hat), "Клоунские ботинки и маска уступили набору оперативника.")
	TEST_ASSERT(istype(body.shoes, /obj/item/clothing/shoes/combat), "Оперативник снова в боевых ботинках.")
	TEST_ASSERT_EQUAL(antag_training_nukeop_uplink(body), uplink, "Рация та же.")
	TEST_ASSERT_EQUAL(uplink.uplink_flag, UPLINK_NUKE_OPS, "Рация снова открывает магазин оперативников.")
	TEST_ASSERT_NULL(antag_training_uplink_entry(uplink, /datum/uplink_item/dangerous/clownsword), "Клоунских товаров у оперативника нет.")
	TEST_ASSERT_EQUAL(length(GLOB.antagonist_teams), teams_before, "Команды раунда не меняются.")
