/datum/unit_test/proc/antag_training_ling_feedback()
	. = ""
	for(var/datum/feedback_variable/feedback as anything in SSblackbox.feedback)
		if(feedback.key == "changeling_power_purchase" || feedback.key == "changeling_powers")
			. += "[feedback.key]=[json_encode(feedback.json)];"

/datum/unit_test/proc/antag_training_wait_status_tick(datum/status_effect/effect, max_wait)
	var/scheduled = effect.next_tick
	var/list/budget = new_wait_budget(max_wait, "[effect.type].next_tick > [scheduled]")
	while(!QDELETED(effect) && effect.next_tick <= scheduled)
		if(!wait_budget_tick(budget))
			break
	return !QDELETED(effect) && effect.next_tick > scheduled

/datum/unit_test/proc/antag_training_ling_evolve(datum/antagonist/changeling/changeling, mob/living/buyer, power_name)
	var/datum/tgui/shop = allocate(/datum/tgui, buyer, changeling.cellular_emporium, "CellularEmporium")
	shop.status = UI_INTERACTIVE
	usr = buyer
	changeling.cellular_emporium.ui_act("evolve", list("name" = power_name), shop)
	usr = null

/datum/unit_test/proc/antag_training_ling_power(datum/antagonist/changeling/changeling, power_type)
	for(var/datum/action/changeling/power as anything in changeling.purchasedpowers)
		if(istype(power, power_type))
			return power
	return null

/datum/unit_test/proc/antag_training_heard(mob/listener, marker)
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		var/target = entry[1]
		if((target == listener || (islist(target) && (listener in target))) && findtext(entry[2], marker))
			return TRUE
	return FALSE

/datum/unit_test/proc/antag_training_station_ling(turf/spot)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, spot)
	crew.mind_initialize()
	allocated += crew.mind
	var/datum/antagonist/changeling/station_ling = new
	station_ling.silent = TRUE
	station_ling.give_objectives = FALSE
	crew.mind.add_antag_datum(station_ling)
	return station_ling

/// Программа выдаёт учебного генокрада с полными химикатами и геномом, эмпориум продаёт способности, кнопки пульта пополняют и сбрасывают, не трогая имена и статистику раунда.
/datum/unit_test/antag_training_changeling_setup/Run()
	var/ids_before = length(GLOB.possible_changeling_IDs)
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/changeling)
	TEST_ASSERT(session.prepare(), "Полигон готовит генокрада.")
	var/datum/antag_training_program/antag/changeling/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/changeling/training/role = program.role(session)
	TEST_ASSERT(istype(role), "Кукла получает учебного генокрада.")
	TEST_ASSERT_EQUAL(role.training, session, "Роль знает свою сессию.")
	TEST_ASSERT_EQUAL(length(GLOB.possible_changeling_IDs), ids_before, "Имя учебного генокрада не берётся из пула раунда.")
	TEST_ASSERT(findtext(role.changelingID, "Учебный генокрад") == 1, "Учебное имя - «Учебный генокрад N», а не [role.changelingID].")
	TEST_ASSERT(!length(role.objectives), "У учебного генокрада нет заданий раунда.")
	TEST_ASSERT_EQUAL(role.chem_charges, role.chem_storage, "Химикаты на старте полные.")
	TEST_ASSERT_EQUAL(role.geneticpoints, role.maxgeneticpoints, "Очки генома на старте полные.")
	TEST_ASSERT(role.emporium_action in body.actions, "Кнопка эмпориума выдана.")
	TEST_ASSERT(findtext(role.briefing(), "Моя роль"), "Приветствие называет кнопки пульта.")

	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")

	TEST_ASSERT(!SSblackbox.sealed, "Статистика раунда пишется.")
	var/feedback = antag_training_ling_feedback()
	var/datum/action/changeling/panacea/panacea_type = /datum/action/changeling/panacea
	antag_training_ling_evolve(role, body, initial(panacea_type.name))
	var/datum/action/changeling/panacea/panacea = antag_training_ling_power(role, panacea_type)
	TEST_ASSERT_NOTNULL(panacea, "Эмпориум продаёт способность.")
	TEST_ASSERT(panacea in body.actions, "Купленная способность на панели.")
	TEST_ASSERT_EQUAL(role.geneticpoints, role.maxgeneticpoints - panacea.dna_cost, "Покупка списывает очки генома.")
	panacea.Trigger()
	TEST_ASSERT_EQUAL(role.chem_charges, role.chem_storage - panacea.chemical_cost, "Способность тратит химикаты.")
	TEST_ASSERT_EQUAL(antag_training_ling_feedback(), feedback, "Учебные покупка и способность не пишут статистику раунда.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Пополнить химикаты и геном"))
	TEST_ASSERT_EQUAL(role.chem_charges, role.chem_storage, "«Пополнить химикаты и геном» доводит химикаты до максимума.")
	TEST_ASSERT_EQUAL(role.geneticpoints, role.maxgeneticpoints, "«Пополнить химикаты и геном» доводит очки генома до максимума.")
	TEST_ASSERT_EQUAL(role.cellular_emporium.ui_data(body)["genetic_points_remaining"], role.maxgeneticpoints, "Эмпориум показывает пополненные очки.")
	TEST_ASSERT(antag_training_ling_power(role, panacea_type), "Пополнение не снимает купленное.")

	antag_training_console_act(session, console, "program_option", list("option" = "Сбросить способности"))
	TEST_ASSERT_NULL(antag_training_ling_power(role, panacea_type), "Сброс снимает купленные способности.")
	TEST_ASSERT(!(panacea in body.actions), "Снятая способность уходит с панели.")
	TEST_ASSERT(antag_training_ling_power(role, /datum/action/changeling/absorbDNA), "Бесплатные способности остаются после сброса.")
	TEST_ASSERT_EQUAL(role.geneticpoints, role.maxgeneticpoints, "Сброс возвращает очки генома.")
	TEST_ASSERT_EQUAL(antag_training_ling_feedback(), feedback, "Учебный сброс не пишет статистику раунда.")

/// Удушающий захват учебной цели и «Absorb DNA» поглощают её: генокрад получает ДНК, цель умирает и не становится зомби-генокрадом.
/datum/unit_test/antag_training_changeling_absorb/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/changeling)
	TEST_ASSERT(session.prepare(), "Полигон готовит генокрада.")
	var/datum/antag_training_program/antag/changeling/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/changeling/training/role = program.role(session)
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "move", list("zone" = "laboratory"))
	var/targets_before = length(session.arena.targets)
	antag_training_console_act(session, console, "program_option", list("option" = "Цель для поглощения"))
	TEST_ASSERT_EQUAL(length(session.arena.targets), targets_before + 1, "Кнопка создаёт учебную цель.")
	var/mob/living/carbon/human/dummy = session.arena.targets[length(session.arena.targets)]
	TEST_ASSERT(dummy.mind in session.arena.target_minds, "Цель - учебный манекен.")
	TEST_ASSERT_EQUAL(get_dist(dummy, body), 1, "Цель встаёт рядом с генокрадом.")

	var/absorbed_before = role.absorbedcount
	var/feedback = antag_training_ling_feedback()
	body.start_pulling(dummy)
	body.setGrabState(GRAB_KILL)
	TEST_ASSERT(body.pulling == dummy && body.grab_state > GRAB_NECK, "Генокрад держит цель удушающим захватом.")
	var/datum/action/changeling/absorbDNA/absorb = antag_training_ling_power(role, /datum/action/changeling/absorbDNA)
	TEST_ASSERT_NOTNULL(absorb, "Поглощение выдано бесплатно.")
	INVOKE_ASYNC(absorb, TYPE_PROC_REF(/datum/action/changeling, Trigger))
	TEST_ASSERT(role.isabsorbing, "Поглощение началось.")
	TEST_ASSERT(wait_for_var(role, "absorbedcount", absorbed_before + 1, 1 MINUTES), "Поглощение завершается, пока держится захват.")
	TEST_ASSERT_EQUAL(role.trueabsorbs, 1, "Поглощение засчитано как настоящее.")
	TEST_ASSERT(role.get_dna(dummy.real_name), "ДНК цели в профилях генокрада.")
	TEST_ASSERT_EQUAL(dummy.stat, DEAD, "Поглощённая цель мертва.")
	TEST_ASSERT(HAS_TRAIT_FROM(dummy, TRAIT_HUSK, CHANGELING_DRAIN), "Поглощённая цель иссушена.")
	TEST_ASSERT_NULL(dummy.GetComponent(/datum/component/changeling_zombie_infection), "Манекен не заражается зомби-генокрадом.")
	TEST_ASSERT_NULL(dummy.mind.has_antag_datum(/datum/antagonist/changeling_zombie), "Манекен не получает роль зомби-генокрада.")
	TEST_ASSERT(!can_become_changeling_zombie(dummy), "Учебная цель не может стать зомби-генокрадом.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT(can_become_changeling_zombie(crew), "Человек станции по-прежнему может стать зомби-генокрадом.")
	TEST_ASSERT_EQUAL(antag_training_ling_feedback(), feedback, "Учебное поглощение не пишет статистику раунда.")
	TEST_ASSERT(role.can_respec, "Поглощение открывает переадаптацию.")
	antag_training_console_act(session, console, "program_option", list("option" = "Сбросить способности"))
	TEST_ASSERT(role.can_respec, "Сброс из пульта не тратит переадаптацию, заработанную поглощением.")

/// Улей и рецепторы учебного генокрада связывают только генокрадов этой арены: генокрад станции и учебный не слышат и не чуют друг друга, а банк ДНК у полигона свой.
/datum/unit_test/antag_training_changeling_hivemind
	var/list/added_players = list()
	var/list/saved_ids

/datum/unit_test/antag_training_changeling_hivemind/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/changeling)
	TEST_ASSERT(session.prepare(), "Полигон готовит генокрада.")
	var/datum/antag_training_program/antag/changeling/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/changeling/training/role = program.role(session)
	var/datum/action/changeling/hivemind_comms/hive_type = /datum/action/changeling/hivemind_comms
	var/hive_name = initial(hive_type.name)
	antag_training_ling_evolve(role, body, hive_name)
	TEST_ASSERT(role.changeling_speak, "Hivemind Communication открывает улей.")
	TEST_ASSERT(role.hive_bank() != GLOB.hivemind_bank, "Банк ДНК улья полигона - не банк раунда.")

	var/turf/arena_spot = get_step(body, EAST)
	var/mob/living/carbon/human/trainee = allocate(/mob/living/carbon/human, arena_spot)
	TEST_ASSERT(trainee.training_origin && trainee.training_origin == body.training_origin, "Второй учебный генокрад стоит на той же арене.")
	trainee.mind_initialize()
	allocated += trainee.mind
	var/datum/antagonist/changeling/training/trainee_ling = new
	trainee_ling.silent = TRUE
	trainee.mind.add_antag_datum(trainee_ling)
	trainee_ling.purchase_power(hive_name)

	saved_ids = GLOB.possible_changeling_IDs.Copy()
	var/datum/antagonist/changeling/station_ling = antag_training_station_ling(locate(arena_spot.x, arena_spot.y, run_loc_floor_bottom_left.z))
	var/mob/living/carbon/human/crew = station_ling.owner.current
	TEST_ASSERT_NULL(crew.training_origin, "Генокрад станции вне полигона.")
	var/feedback = antag_training_ling_feedback()
	station_ling.purchase_power(hive_name)
	TEST_ASSERT(antag_training_ling_feedback() != feedback, "Покупка генокрада станции пишет статистику раунда.")
	TEST_ASSERT(station_ling.changeling_speak, "Генокрад станции говорит в улей.")
	var/datum/antagonist/changeling/station_listener = antag_training_station_ling(run_loc_floor_bottom_left)
	var/mob/living/carbon/human/crew_listener = station_listener.owner.current
	station_listener.purchase_power(hive_name)
	added_players = list(body, trainee, crew, crew_listener) - GLOB.player_list
	GLOB.player_list += added_players
	GLOB.unit_test_chat_capture = list()

	body.say("[MODE_TOKEN_CHANGELING] hive-arena-probe")
	TEST_ASSERT(antag_training_heard(trainee, "hive-arena-probe"), "Генокрад этой арены слышит учебный улей.")
	TEST_ASSERT(!antag_training_heard(crew, "hive-arena-probe"), "Генокрад станции не слышит учебный улей.")
	TEST_ASSERT(!antag_training_heard(crew_listener, "hive-arena-probe"), "Второй генокрад станции не слышит учебный улей.")
	crew.say("[MODE_TOKEN_CHANGELING] hive-station-probe")
	TEST_ASSERT(antag_training_heard(crew_listener, "hive-station-probe"), "Генокрады станции слышат друг друга.")
	TEST_ASSERT(!antag_training_heard(trainee, "hive-station-probe"), "Учебный генокрад не слышит улей станции.")
	TEST_ASSERT(!antag_training_heard(body, "hive-station-probe"), "Участник полигона не слышит улей станции.")
	station_listener.owner.remove_antag_datum(/datum/antagonist/changeling)

	var/datum/action/changeling/pheromone_receptors/receptors_type = /datum/action/changeling/pheromone_receptors
	station_ling.purchase_power(initial(receptors_type.name))
	var/datum/action/changeling/pheromone_receptors/station_receptors = antag_training_ling_power(station_ling, receptors_type)
	station_receptors.Trigger()
	trainee_ling.purchase_power(initial(receptors_type.name))
	var/datum/action/changeling/pheromone_receptors/trainee_receptors = antag_training_ling_power(trainee_ling, receptors_type)
	trainee_receptors.Trigger()
	var/datum/status_effect/agent_pinpointer/changeling/station_scent = crew.has_status_effect(/datum/status_effect/agent_pinpointer/changeling)
	var/datum/status_effect/agent_pinpointer/changeling/trainee_scent = trainee.has_status_effect(/datum/status_effect/agent_pinpointer/changeling)
	TEST_ASSERT(station_scent && trainee_scent, "Рецепторы феромонов включены.")
	TEST_ASSERT(wait_for_var(trainee_scent, "scan_target", body, 10 SECONDS), "Учебный генокрад чует генокрада своей арены.")
	TEST_ASSERT(antag_training_wait_status_tick(station_scent, 10 SECONDS), "Рецепторы станции обновились.")
	TEST_ASSERT_NULL(station_scent.scan_target, "Генокрад станции не чует учебных генокрадов.")
	station_ling.owner.remove_antag_datum(/datum/antagonist/changeling)

/datum/unit_test/antag_training_changeling_hivemind/Destroy()
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= added_players
	added_players.Cut()
	if(saved_ids)
		GLOB.possible_changeling_IDs = saved_ids
	return ..()

/// Эмпориум полигона не продаёт силы, зовущие призраков: отказ с объяснением, очки генома не списаны; генокрад станции ту же силу покупает.
/datum/unit_test/antag_training_changeling_closed_powers
	var/list/saved_ids

/datum/unit_test/antag_training_changeling_closed_powers/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/changeling)
	TEST_ASSERT(session.prepare(), "Полигон готовит генокрада.")
	var/datum/antag_training_program/antag/changeling/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/changeling/training/role = program.role(session)
	var/datum/action/changeling/spiders/spiders_type = /datum/action/changeling/spiders
	TEST_ASSERT(spiders_type in GLOB.antag_training_blocked_changeling_powers, "Spread Infestation закрыта на полигоне.")
	GLOB.unit_test_chat_capture = list()
	antag_training_ling_evolve(role, body, initial(spiders_type.name))
	TEST_ASSERT_NULL(antag_training_ling_power(role, spiders_type), "Учебный генокрад не покупает Spread Infestation.")
	TEST_ASSERT_EQUAL(role.geneticpoints, role.maxgeneticpoints, "Отказ не списывает очки генома.")
	TEST_ASSERT(antag_training_heard(body, "На полигоне недоступно"), "Отказ объясняет, что сила закрыта на полигоне.")

	saved_ids = GLOB.possible_changeling_IDs.Copy()
	var/datum/antagonist/changeling/station_ling = antag_training_station_ling(run_loc_floor_bottom_left)
	antag_training_ling_evolve(station_ling, station_ling.owner.current, initial(spiders_type.name))
	TEST_ASSERT(antag_training_ling_power(station_ling, spiders_type), "Генокрад станции покупает Spread Infestation.")
	TEST_ASSERT_EQUAL(station_ling.geneticpoints, station_ling.maxgeneticpoints - initial(spiders_type.dna_cost), "Генокрад станции платит очками генома.")
	station_ling.owner.remove_antag_datum(/datum/antagonist/changeling)

/datum/unit_test/antag_training_changeling_closed_powers/Destroy()
	GLOB.unit_test_chat_capture = null
	if(saved_ids)
		GLOB.possible_changeling_IDs = saved_ids
	return ..()

/// «Поглощение и облик»: щелчки захвата до удушающего, «Absorb DNA» и облик жертвы засчитываются по шагам; смерть цели до поглощения проваливает упражнение.
/datum/unit_test/antag_training_changeling_exercise/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/changeling)
	TEST_ASSERT(session.prepare(), "Полигон готовит генокрада.")
	var/datum/antag_training_program/antag/changeling/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/changeling/training/role = program.role(session)
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "move", list("zone" = "laboratory"))
	var/datum/antag_training_exercise_run/run = start_training_drill(session, console, "changeling_absorb")
	TEST_ASSERT(run && !run.ended, "Упражнение генокрада стартует в лаборатории.")
	var/mob/living/carbon/human/dummy = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT(dummy?.mind && (dummy.mind in session.arena.target_minds), "Цель упражнения - учебный манекен.")
	TEST_ASSERT(session.arena.inside_bounds(get_turf(dummy), session.arena.zones["laboratory"]["bounds"]), "Цель стоит в лаборатории.")

	dummy.forceMove(get_step(body, EAST))
	var/datum/action/changeling/sting/extract_dna/extract = antag_training_ling_power(role, /datum/action/changeling/sting/extract_dna)
	if(!extract)
		antag_training_ling_evolve(role, body, /datum/action/changeling/sting/extract_dna::name)
		extract = antag_training_ling_power(role, /datum/action/changeling/sting/extract_dna)
	TEST_ASSERT_NOTNULL(extract, "У генокрада есть жало извлечения ДНК.")
	extract.try_to_sting(body, dummy)
	TEST_ASSERT_NOTNULL(role.get_dna(dummy.real_name), "Жало взяло ДНК цели до поглощения.")
	TEST_ASSERT(role.can_absorb_dna(dummy, FALSE), "Взятая жалом ДНК не мешает поглощению: has_dna не узнаёт копию с отдельным списком признаков.")
	dummy.grabbedby(body)
	TEST_ASSERT_EQUAL(body.pulling, dummy, "Первый щелчок захвата тащит цель.")
	for(var/upgrade in 1 to 3)
		dummy.grabbedby(body)
	TEST_ASSERT_EQUAL(body.grab_state, GRAB_KILL, "Три щелчка усиливают захват до удушающего.")
	TEST_ASSERT(wait_for_drill_step(run, 2), "Удушающий захват засчитан.")

	var/datum/action/changeling/absorbDNA/absorb = antag_training_ling_power(role, /datum/action/changeling/absorbDNA)
	INVOKE_ASYNC(absorb, TYPE_PROC_REF(/datum/action/changeling, Trigger))
	TEST_ASSERT(wait_for_drill_step(run, 3, 1 MINUTES), "Поглощение засчитано: [run.result_text]")
	TEST_ASSERT(dummy.stat == DEAD && !run.ended, "Поглощённая цель мертва, а упражнение продолжается.")
	var/datum/changelingprofile/profile = role.get_dna(dummy.real_name)
	TEST_ASSERT_NOTNULL(profile, "Облик цели среди профилей генокрада.")
	TEST_ASSERT(body.real_name != dummy.real_name, "До превращения генокрад в своём облике.")
	// Transform выбирает облик круговым меню без клиента; выбранный профиль надевает тот же changeling_transform().
	changeling_transform(body, profile)
	TEST_ASSERT(wait_for_drill_step(run, 4) && run.ended && run.success, "Облик жертвы завершает упражнение: [run.result_text]")

	run = start_training_drill(session, console, "changeling_absorb")
	TEST_ASSERT(run && !run.ended, "Упражнение начинается заново.")
	dummy = run.find_prop(/mob/living/carbon/human)
	dummy.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "раньше поглощения"), "Смерть цели до поглощения проваливает упражнение: [run.result_text]")

/// Выход с полигона в хитиновой броне и с рукой-клинком: кукла удаляется уже без разума, снятие способностей не падает на mind (10600).
/datum/unit_test/antag_training_changeling_exit_mutations/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/changeling)
	TEST_ASSERT(session.prepare(), "Полигон готовит генокрада.")
	var/datum/antag_training_program/antag/changeling/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/changeling/training/role = program.role(session)
	for(var/power_type in list(/datum/action/changeling/suit/armor, /datum/action/changeling/weapon/arm_blade))
		var/datum/action/changeling/power_path = power_type
		antag_training_ling_evolve(role, body, initial(power_path.name))
		var/datum/action/changeling/power = antag_training_ling_power(role, power_type)
		TEST_ASSERT_NOTNULL(power, "Эмпориум продаёт [initial(power_path.name)].")
		power.Trigger()
	TEST_ASSERT(istype(body.wear_suit, /obj/item/clothing/suit/armor/changeling), "Броня выросла.")
	TEST_ASSERT(locate(/obj/item/melee/arm_blade) in body.held_items, "Клинок вырос.")
	session.finish()
	TEST_ASSERT(QDELETED(body), "Выход удаляет куклу.")
