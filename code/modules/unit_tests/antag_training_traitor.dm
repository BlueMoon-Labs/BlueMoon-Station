/datum/unit_test/proc/antag_training_class_weights()
	var/list/weights = list()
	for(var/class_type in GLOB.traitor_classes)
		var/datum/traitor_class/class = GLOB.traitor_classes[class_type]
		weights += "[class_type]=[class.weight]"
	return jointext(weights, ", ")

/datum/unit_test/proc/antag_training_uplink_entry(datum/component/uplink/uplink, item_type)
	for(var/category in uplink.uplink_items)
		if(category == "Discounted Gear")
			continue
		for(var/item_name in uplink.uplink_items[category])
			var/datum/uplink_item/item = uplink.uplink_items[category][item_name]
			if(item.type == item_type)
				return item
	return null

/datum/unit_test/proc/antag_training_uplink_buy(datum/component/uplink/uplink, mob/living/buyer, datum/uplink_item/item)
	var/datum/tgui/shop = allocate(/datum/tgui, buyer, uplink, "UplinkInteQ")
	shop.status = UI_INTERACTIVE
	usr = buyer
	uplink.ui_act("buy", list("name" = item.name), shop)
	usr = null

/datum/unit_test/proc/antag_training_logged_purchases(datum/component/uplink/uplink)
	. = 0
	for(var/hash in uplink.purchase_log.purchase_log)
		var/datum/uplink_purchase_entry/entry = uplink.purchase_log.purchase_log[hash]
		. += entry.amount_purchased

/datum/unit_test/proc/antag_training_random_tally()
	. = 0
	for(var/datum/feedback_variable/feedback as anything in SSblackbox.feedback)
		if(feedback.key != "traitor_random_uplink_items_gotten")
			continue
		var/list/tally = feedback.json["data"]
		for(var/item_name in tally)
			. += tally[item_name]

/datum/component/uplink/antag_training/refusal_probe
	var/refusals_checked = 0

/datum/component/uplink/antag_training/refusal_probe/refuse_purchase(mob/user, datum/uplink_item/item)
	refusals_checked++
	return ..()

/// Программа предателя выдаёт учебного предателя выбранного класса с учебным аплинк-имплантом на полный счёт и учебными кодовыми словами, не трогая режим и веса классов раунда.
/datum/unit_test/antag_training_traitor_setup/Run()
	var/traitors_before = length(SSticker.mode.traitors)
	var/logs_before = LAZYLEN(GLOB.uplink_purchase_logs_by_key)
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/traitor)
	var/weights_before = antag_training_class_weights()
	TEST_ASSERT(session.prepare(), "Полигон готовит предателя.")
	var/datum/antag_training_program/antag/traitor/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/traitor/training/role = program.role(session)
	TEST_ASSERT(istype(role), "Кукла получает учебного предателя.")
	TEST_ASSERT_EQUAL(role.traitor_kind?.type, TRAITOR_HUMAN, "Стартовый класс - свободный.")
	var/obj/item/implant/uplink/antag_training/implant = locate() in body.implants
	TEST_ASSERT_NOTNULL(implant, "Аплинк вживлён учебным имплантом.")
	TEST_ASSERT_EQUAL(role.uplink, implant.GetComponent(/datum/component/uplink), "Роль знает свой аплинк.")
	TEST_ASSERT_EQUAL(role.uplink.telecrystals, TELECRYSTALS_DEFAULT, "На счету полный стартовый запас.")
	TEST_ASSERT(isnull(role.uplink.owner) && role.uplink.purchase_log && isnull(role.uplink.purchase_log.owner), "Лог покупок аплинка без владельца.")
	TEST_ASSERT_EQUAL(LAZYLEN(GLOB.uplink_purchase_logs_by_key), logs_before, "Лог покупок не попадает в логи раунда по ckey.")

	TEST_ASSERT(length(GLOB.syndicate_code_phrase) && length(role.training_phrases) && length(role.training_responses), "Кодовые слова раунда и учебные сгенерированы.")
	var/round_phrases = jointext(GLOB.syndicate_code_phrase, ", ")
	var/training_phrases = jointext(role.training_phrases, ", ")
	TEST_ASSERT(training_phrases != round_phrases, "Учебные кодовые фразы - не фразы раунда.")
	var/briefing = role.briefing()
	TEST_ASSERT(findtext(briefing, training_phrases) && findtext(briefing, jointext(role.training_responses, ", ")), "Приветствие называет учебные фразы и ответы.")
	TEST_ASSERT(!findtext(briefing, round_phrases) && !findtext(briefing, jointext(GLOB.syndicate_code_response, ", ")), "Приветствие не выдаёт слов раунда.")
	TEST_ASSERT(findtext(role.antag_memory, training_phrases) && !findtext(role.antag_memory, round_phrases), "В заметках роли - учебные фразы.")
	TEST_ASSERT_EQUAL(role.ui_static_data(body)["phrases"], training_phrases, "Окно роли показывает учебные фразы.")

	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")
	TEST_ASSERT_EQUAL(("Сменить класс: Угонщик" in program.options), !!GLOB.traitor_classes[/datum/traitor_class/human/hijack], "Угонщик в пульте, только если класс есть в раунде.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "restart", list("program" = "[/datum/antag_training_program/antag]"))
	TEST_ASSERT_EQUAL(session.program, program, "Пульт не перезапускает сеанс заготовкой программ ролей.")
	TEST_ASSERT(!session.restart(/datum/antag_training_program/antag), "Смена программы не принимает заготовку.")
	antag_training_console_act(session, console, "program_option", list("option" = "Сменить класс: Ассасин"))
	var/datum/antagonist/traitor/training/assassin = program.role(session)
	TEST_ASSERT(QDELETED(role) && istype(assassin), "Смена класса перевыдаёт роль.")
	TEST_ASSERT_EQUAL(assassin.traitor_kind?.type, /datum/traitor_class/human/subterfuge/assassin, "Выбранный в пульте класс - ассасин.")
	TEST_ASSERT(QDELETED(implant) && assassin.training_implant && (assassin.training_implant in body.implants), "Новая роль - с новым имплантом вместо прежнего.")
	TEST_ASSERT_EQUAL(length(body.implants), 1, "Аплинк-имплант один.")
	TEST_ASSERT_EQUAL(length(SSticker.mode.traitors), traitors_before, "Учебный предатель не записан в предатели режима.")
	TEST_ASSERT_EQUAL(antag_training_class_weights(), weights_before, "Веса классов раунда не меняются.")

/// Аплинк полигона продаёт предметы на полигон и списывает ТК, предметы с призраками не продаёт, «Пополнить ТК» доводит счёт до полного; обычный аплинк продаёт тот же закрытый предмет.
/datum/unit_test/antag_training_traitor_uplink/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/traitor)
	TEST_ASSERT(session.prepare(), "Полигон готовит предателя.")
	var/datum/antag_training_program/antag/traitor/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/traitor/training/role = program.role(session)
	var/datum/component/uplink/antag_training/uplink = role.uplink
	role.training_implant.ui_action_click()
	TEST_ASSERT(uplink.active && !uplink.locked, "Кнопка импланта открывает аплинк.")

	var/datum/uplink_item/emag = antag_training_uplink_entry(uplink, /datum/uplink_item/device_tools/emag)
	TEST_ASSERT_NOTNULL(emag, "В магазине есть криптографический секвенсор.")
	antag_training_uplink_buy(uplink, body, emag)
	TEST_ASSERT_EQUAL(uplink.telecrystals, TELECRYSTALS_DEFAULT - emag.cost, "Покупка списывает ТК.")
	var/obj/item/card/emag/card = locate() in body.held_items
	TEST_ASSERT_NOTNULL(card, "Купленный предмет в руках.")
	TEST_ASSERT(session.arena.owns_area(get_area(card)), "Купленный предмет на полигоне.")
	TEST_ASSERT(length(uplink.purchase_log.purchase_log), "Покупка записана в учебный лог.")

	var/datum/uplink_item/guardian = antag_training_uplink_entry(uplink, /datum/uplink_item/dangerous/guardian)
	TEST_ASSERT_NOTNULL(guardian, "Голопаразит есть в магазине полигона при любом онлайне.")
	var/telecrystals = uplink.telecrystals
	antag_training_uplink_buy(uplink, body, guardian)
	TEST_ASSERT_EQUAL(uplink.telecrystals, telecrystals, "Голопаразит не списывает ТК.")
	var/turf/counter = get_turf(body)
	TEST_ASSERT_NULL(locate(/obj/item/storage/box/syndie_kit/guardian) in body.GetAllContents() + counter.contents, "Голопаразит не выдаётся.")
	TEST_ASSERT(findtext(uplink.refusal(guardian), "На полигоне недоступно"), "Отказ объясняет, что на полигоне голопаразит недоступен.")
	uplink.selected_cat = guardian.category
	var/list/shop = uplink.ui_data(body)
	var/guardian_desc
	for(var/list/category as anything in shop["categories"])
		for(var/list/entry as anything in category["items"])
			if(entry["name"] == guardian.name)
				guardian_desc = entry["desc"]
	TEST_ASSERT(findtext(guardian_desc, "На полигоне недоступно"), "Описание закрытого предмета в магазине говорит о полигоне.")

	var/datum/uplink_item/monkey = antag_training_uplink_entry(uplink, /datum/uplink_item/support/monkey_agent)
	antag_training_uplink_buy(uplink, body, monkey)
	TEST_ASSERT_EQUAL(uplink.telecrystals, telecrystals, "Агент-обезьяна на полигоне не продаётся.")
	var/mob/living/carbon/human/agent = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	agent.mind_initialize()
	allocated += agent.mind
	var/obj/item/pen/station_pen = allocate(/obj/item/pen, run_loc_floor_bottom_left)
	var/datum/component/uplink/station_uplink = station_pen.AddComponent(/datum/component/uplink, null, FALSE, TRUE)
	agent.put_in_hands(station_pen)
	antag_training_uplink_buy(station_uplink, agent, antag_training_uplink_entry(station_uplink, /datum/uplink_item/support/monkey_agent))
	var/obj/item/antag_spawner/monkey_agent/beacon = locate() in agent.held_items
	allocated += beacon
	TEST_ASSERT_NOTNULL(beacon, "Обычный аплинк продаёт агента-обезьяну.")
	TEST_ASSERT_EQUAL(station_uplink.telecrystals, TELECRYSTALS_DEFAULT - monkey.cost, "Обычный аплинк списывает цену агента.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Пополнить ТК"))
	TEST_ASSERT_EQUAL(uplink.telecrystals, TELECRYSTALS_DEFAULT, "«Пополнить ТК» доводит счёт до полного.")
	antag_training_console_act(session, console, "program_option", list("option" = "Выдать ручку с аплинком"))
	var/obj/item/pen/pen = locate() in body.held_items
	var/datum/component/uplink/antag_training/pen_uplink = pen?.GetComponent(/datum/component/uplink)
	TEST_ASSERT(istype(pen_uplink) && pen_uplink.locked && length(pen_uplink.unlock_code), "Ручка с учебным аплинком выдаётся запертой, с кодом.")
	TEST_ASSERT(findtext(role.antag_memory, pen_uplink.unlock_note), "Код ручки записан в заметки роли.")
	TEST_ASSERT(isnull(pen_uplink.owner) && session.arena.owns_area(get_area(pen)), "Ручка учебная и лежит на полигоне.")

/// Учебные ликвидация и кража назначаются на манекен и документы в хранилище макета и засчитываются игровым путём; удалённый манекен снимает задание.
/datum/unit_test/antag_training_traitor_objectives/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/traitor)
	TEST_ASSERT(session.prepare(), "Полигон готовит предателя.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/datum/antag_training_program/antag/traitor/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/traitor/training/role = program.role(session)
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")

	antag_training_console_act(session, console, "program_option", list("option" = "Учебная цель: ликвидация"))
	TEST_ASSERT_NULL(role.kill_objective, "Без учебной цели ликвидация не назначается.")
	antag_training_console_act(session, console, "spawn", list("id" = "human", "zone" = "laboratory"))
	var/mob/living/carbon/human/dummy = arena.targets[length(arena.targets)]
	antag_training_console_act(session, console, "program_option", list("option" = "Учебная цель: ликвидация"))
	var/datum/objective/antag_training/kill = role.kill_objective
	TEST_ASSERT(kill && kill.target == dummy.mind && (kill in role.objectives), "Ликвидация назначена на последнюю учебную цель.")
	TEST_ASSERT(kill.target in arena.target_minds, "Цель ликвидации - учебная.")
	var/list/console_data = session.ui_data(body)
	var/list/goals = console_data["role_objectives"]
	TEST_ASSERT(length(goals) == 1 && !goals[1]["done"] && goals[1]["text"] == kill.explanation_text, "«Моя роль» показывает невыполненную ликвидацию: [json_encode(goals)].")
	TEST_ASSERT_EQUAL(console_data["role_next"], kill.explanation_text, "Что дальше - ликвидация.")
	dummy.death()
	TEST_ASSERT(kill.completed, "Смерть манекена засчитывает ликвидацию.")
	console_data = session.ui_data(body)
	goals = console_data["role_objectives"]
	TEST_ASSERT(length(goals) == 1 && goals[1]["done"], "После учебной ликвидации цель в пульте отмечена выполненной: [json_encode(goals)].")
	TEST_ASSERT_NULL(console_data["role_next"], "Все цели выполнены, упражнения нет - подсказки «что дальше» нет.")
	TEST_ASSERT(!kill.check_completion() && !kill.find_target(), "Раунд не засчитывает учебное задание и не перевыбирает его цель.")
	TEST_ASSERT_EQUAL(SSmetadollars.potential_antag_metadollars(role.owner), 0, "Учебные задания не дают метадолларов.")
	antag_training_console_act(session, console, "target_delete", list("id" = REF(dummy)))
	TEST_ASSERT(QDELETED(kill) && isnull(role.kill_objective) && !(kill in role.objectives), "Удалённый манекен снимает задание ликвидации.")

	antag_training_console_act(session, console, "program_option", list("option" = "Учебная цель: кража"))
	var/datum/objective/antag_training/theft = role.steal_objective
	var/obj/item/loot = role.loot_ref?.resolve()
	TEST_ASSERT(theft && loot && (theft in role.objectives), "Кража назначена на учебные документы.")
	TEST_ASSERT_EQUAL(get_turf(loot), station.landmark_turf("vault"), "Документы лежат в хранилище макета.")
	TEST_ASSERT(!theft.completed, "Кража не засчитана, пока документы в хранилище.")
	body.forceMove(get_turf(loot))
	loot.attack_hand(body)
	TEST_ASSERT(loot in body.held_items, "Участник берёт документы в руки.")
	TEST_ASSERT(theft.completed, "Документы в руках засчитывают кражу.")
	qdel(session)
	TEST_ASSERT(QDELETED(role) && QDELETED(theft) && QDELETED(loot), "Выход снимает роль, задания и учебные документы.")

/// «Тихая ликвидация»: покупка через магазин аплинка, смерть цели в кабинете главы и документы в руках в зале прибытия засчитываются по шагам, тело убитой цели можно разорвать; смерть цели за пределами кабинета проваливает упражнение.
/datum/unit_test/antag_training_traitor_exercise/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/traitor)
	TEST_ASSERT(session.prepare(), "Полигон готовит предателя.")
	var/datum/antag_training_program/antag/traitor/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/traitor/training/role = program.role(session)
	var/datum/component/uplink/antag_training/uplink = role.uplink
	TEST_ASSERT(findtext(role.briefing(), "Тихая ликвидация"), "Приветствие называет упражнение.")
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	var/datum/antag_training_sector/station = enter_training_sector(session, console, "station")
	TEST_ASSERT_EQUAL(session.arena.match_zone(body), "station", "Участник в станционном макете.")
	var/datum/antag_training_exercise_run/run = start_training_drill(session, console, "traitor_quiet_kill")
	TEST_ASSERT(run && !run.ended, "Упражнение предателя стартует в макете.")
	var/mob/living/carbon/human/dummy = run.find_prop(/mob/living/carbon/human)
	var/obj/item/documents/nanotrasen/papers = run.find_prop(/obj/item/documents/nanotrasen)
	var/list/office = antag_training_room_turfs(station.landmark_turf("head_office"), station)
	TEST_ASSERT(length(office), "Кабинет главы - замкнутая комната.")
	TEST_ASSERT(dummy?.mind && (get_turf(dummy) in office), "Цель сидит в кабинете главы.")
	TEST_ASSERT(papers && (get_turf(papers) in office), "Документы лежат в кабинете главы.")

	role.training_implant.ui_action_click()
	var/datum/uplink_item/dagger = antag_training_uplink_entry(uplink, /datum/uplink_item/stealthy_weapons/edagger)
	TEST_ASSERT_NOTNULL(dagger, "В магазине есть Energy Dagger из подсказки шага.")
	antag_training_uplink_buy(uplink, body, dagger)
	TEST_ASSERT_EQUAL(uplink.telecrystals, TELECRYSTALS_DEFAULT - dagger.cost, "Кинжал куплен.")
	TEST_ASSERT_EQUAL(run.step_index, 2, "Покупка в аплинке засчитана.")

	dummy.death()
	TEST_ASSERT_EQUAL(run.step_index, 3, "Смерть цели в кабинете засчитана: [run.result_text]")
	dummy.gib()
	TEST_ASSERT(!run.ended, "Разорванное после убийства тело цели не проваливает вынос документов: [run.result_text]")
	body.forceMove(get_turf(papers))
	body.drop_all_held_items()
	papers.attack_hand(body)
	TEST_ASSERT(papers in body.held_items, "Участник берёт документы.")
	TEST_ASSERT(!wait_for_drill_step(run, 4, 2 SECONDS), "В кабинете вынос не засчитан.")
	body.forceMove(station.landmark_turf("arrivals"))
	TEST_ASSERT(wait_for_drill_step(run, 4) && run.ended && run.success, "Документы в зале прибытия завершают упражнение: [run.result_text]")

	run = start_training_drill(session, console, "traitor_quiet_kill")
	TEST_ASSERT(run && !run.ended, "Упражнение начинается заново.")
	dummy = run.find_prop(/mob/living/carbon/human)
	antag_training_uplink_buy(uplink, body, dagger)
	TEST_ASSERT_EQUAL(run.step_index, 2, "Вторая покупка засчитана.")
	var/turf/corridor = station.spawn_turf()
	TEST_ASSERT(!(corridor in office), "Вход в макет - не кабинет главы.")
	dummy.forceMove(corridor)
	dummy.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "свидетели"), "Убийство вне кабинета проваливает упражнение: [run.result_text]")

/// Каждый предмет блок-листа аплинк полигона отказывается продавать и не списывает ТК.
/datum/unit_test/antag_training_traitor_blocked_items/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/traitor)
	TEST_ASSERT(session.prepare(), "Полигон готовит предателя.")
	var/datum/antag_training_program/antag/traitor/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/traitor/training/role = program.role(session)
	var/datum/component/uplink/antag_training/uplink = role.uplink
	role.training_implant.ui_action_click()
	uplink.telecrystals = TELECRYSTALS_DEFAULT * 10
	var/turf/counter = get_turf(body)
	var/items_before = length(body.GetAllContents()) + length(counter.contents)
	for(var/station_effect in list(/datum/uplink_item/device_tools/suspiciousphone, /datum/uplink_item/explosives/syndicate_detonator, /datum/uplink_item/stealthy_weapons/romerol_kit, /datum/uplink_item/dangerous/guardian, /datum/uplink_item/bundles_tc/contract_kit, /datum/uplink_item/bundles_tc/bundle))
		TEST_ASSERT(station_effect in GLOB.antag_training_blocked_uplink_items, "[station_effect] закрыт на полигоне.")
	var/listed = 0
	for(var/blocked_type in GLOB.antag_training_blocked_uplink_items)
		var/datum/uplink_item/item = antag_training_uplink_entry(uplink, blocked_type)
		var/in_shop = !!item
		if(!in_shop)
			item = new blocked_type
			allocated += item
		var/stock = item.limited_stock
		if(in_shop)
			listed++
			antag_training_uplink_buy(uplink, body, item)
		else
			uplink.MakePurchase(body, item)
		TEST_ASSERT_EQUAL(uplink.telecrystals, TELECRYSTALS_DEFAULT * 10, "[blocked_type]: ТК не списаны.")
		TEST_ASSERT_EQUAL(item.limited_stock, stock, "[blocked_type]: запас не тратится.")
		TEST_ASSERT(findtext(uplink.refusal(item), "На полигоне недоступно"), "[blocked_type]: отказ объясняет закрытый предмет.")
	TEST_ASSERT(listed, "Закрытые предметы есть в магазине полигона.")
	for(var/category in uplink.uplink_items)
		for(var/item_name in uplink.uplink_items[category])
			var/datum/uplink_item/item = uplink.uplink_items[category][item_name]
			if(!uplink.blocked_reason(item))
				continue
			antag_training_uplink_buy(uplink, body, item)
			TEST_ASSERT_EQUAL(uplink.telecrystals, TELECRYSTALS_DEFAULT * 10, "[item.type] из «[category]»: ТК не списаны.")
	TEST_ASSERT_EQUAL(length(body.GetAllContents()) + length(counter.contents), items_before, "Закрытые предметы не появляются.")

/// Карта, купленная на полигоне, не привязывается к счетам станции; такая же карта на станции привязывается.
/datum/unit_test/antag_training_traitor_card_accounts/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/traitor)
	TEST_ASSERT(session.prepare(), "Полигон готовит предателя.")
	var/datum/antag_training_program/antag/traitor/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/traitor/training/role = program.role(session)
	var/datum/component/uplink/antag_training/uplink = role.uplink
	role.training_implant.ui_action_click()
	antag_training_uplink_buy(uplink, body, antag_training_uplink_entry(uplink, /datum/uplink_item/stealthy_tools/agent_card_inteq))
	var/obj/item/card/id/inteq/card = locate() in body.held_items
	TEST_ASSERT_NOTNULL(card, "Агентская карта куплена.")
	TEST_ASSERT(findtext(card.training_bank_refusal(), "полигоне"), "Карта на полигоне не привязывается к счетам станции.")
	var/obj/item/card/id/inteq/station_card = allocate(/obj/item/card/id/inteq, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(station_card.training_bank_refusal(), "На станции карта привязывается как обычно.")

/// Открытые на полигоне предметы аплинка не несут внутри КПК, аплинка раунда, ромерола и предметов блок-листа; Old hero Bundle закрыт.
/datum/unit_test/antag_training_traitor_open_kits/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/traitor)
	TEST_ASSERT(session.prepare(), "Полигон готовит предателя.")
	var/datum/antag_training_program/antag/traitor/program = session.program
	var/datum/antagonist/traitor/training/role = program.role(session)
	var/datum/component/uplink/antag_training/uplink = role.uplink
	var/datum/uplink_item/bundle = antag_training_uplink_entry(uplink, /datum/uplink_item/bundles_tc/bundle)
	TEST_ASSERT(bundle && ispath(bundle.item, /obj/item/storage/box/inteq_kit/new_heroes), "В магазине предателя - Old hero Bundle.")
	TEST_ASSERT(findtext(uplink.refusal(bundle), "На полигоне недоступно"), "Old hero Bundle на полигоне закрыт.")
	var/list/closed_paths = list(/obj/item/modular_computer/pda, /obj/item/implanter/uplink, /obj/item/guardiancreator, /obj/item/inteq_drone_creator, /obj/item/antag_spawner)
	var/list/closed_types = list()
	for(var/blocked_type in GLOB.antag_training_blocked_uplink_items)
		var/datum/uplink_item/blocked = blocked_type
		if(ispath(initial(blocked.item), /obj/item))
			closed_types |= initial(blocked.item)
	var/turf/spot = get_turf(session.current_body)
	var/kits = 0
	for(var/category in uplink.uplink_items)
		if(category == "Discounted Gear")
			continue
		for(var/item_name in uplink.uplink_items[category])
			var/datum/uplink_item/item = uplink.uplink_items[category][item_name]
			if(uplink.blocked_reason(item) || !ispath(item.item, /obj) || ispath(item.item, /obj/effect))
				continue
			var/obj/sold = new item.item(spot)
			var/list/contents = sold.GetAllContents()
			if(length(contents) > 1)
				kits++
			for(var/atom/movable/content as anything in contents)
				var/datum/component/uplink/hidden = content.GetComponent(/datum/component/uplink)
				TEST_ASSERT(!hidden || istype(hidden, /datum/component/uplink/antag_training), "[item.type]: [content.type] несёт аплинк раунда.")
				TEST_ASSERT(!content.reagents?.has_reagent(/datum/reagent/romerol), "[item.type]: в [content.type] ромерол.")
				for(var/closed_path in closed_paths)
					TEST_ASSERT(!istype(content, closed_path), "[item.type]: внутри [content.type], закрытый на полигоне.")
				TEST_ASSERT(!(content.type in closed_types), "[item.type]: внутри [content.type], закрытый на полигоне.")
			qdel(sold)
	TEST_ASSERT(kits, "Наборы аплинка проверены.")

/// Random Item аплинка полигона выбирает только среди открытых предметов и не пишет статистику раунда.
/datum/unit_test/antag_training_traitor_random_item/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/traitor)
	TEST_ASSERT(session.prepare(), "Полигон готовит предателя.")
	var/datum/antag_training_program/antag/traitor/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/traitor/training/role = program.role(session)
	var/datum/component/uplink/antag_training/uplink = role.uplink
	role.training_implant.ui_action_click()
	uplink.telecrystals = 1
	var/datum/uplink_item/random = antag_training_uplink_entry(uplink, /datum/uplink_item/bundles_tc/random)
	var/datum/uplink_item/decoy_disk = antag_training_uplink_entry(uplink, /datum/uplink_item/device_tools/fakenucleardisk)
	TEST_ASSERT(random && decoy_disk && decoy_disk.cost <= uplink.telecrystals, "В магазине Random Item и закрытый предмет по карману.")
	var/list/candidates = uplink.random_item_candidates(body, random)
	TEST_ASSERT(length(candidates), "Random Item есть из чего выбрать.")
	for(var/datum/uplink_item/candidate as anything in candidates)
		TEST_ASSERT_NULL(uplink.blocked_reason(candidate), "Random Item не выбирает закрытый [candidate.type].")
	uplink.selected_cat = random.category
	var/random_desc
	for(var/list/category as anything in uplink.ui_data(body)["categories"])
		for(var/list/entry as anything in category["items"])
			if(entry["name"] == random.name)
				random_desc = entry["desc"]
	TEST_ASSERT(findtext(random_desc, "только среди открытых"), "Описание Random Item говорит о выборе на полигоне.")
	TEST_ASSERT(!SSblackbox.sealed, "Статистика раунда пишется.")
	var/tally = antag_training_random_tally()
	for(var/attempt in 1 to 3)
		uplink.telecrystals = 1
		var/logged = antag_training_logged_purchases(uplink)
		antag_training_uplink_buy(uplink, body, random)
		TEST_ASSERT(uplink.telecrystals < 1 || antag_training_logged_purchases(uplink) > logged, "Random Item покупает открытый предмет (попытка [attempt]).")
	TEST_ASSERT_EQUAL(antag_training_random_tally(), tally, "Random Item полигона не пишет статистику раунда.")

/// Отказ полигона звучит после проверок покупки: обездвиженный покупатель и скрытый по профессии предмет до него не доходят.
/datum/unit_test/antag_training_traitor_refusal_after_guards/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/traitor)
	TEST_ASSERT(session.prepare(), "Полигон готовит предателя.")
	var/mob/living/carbon/human/body = session.current_body
	var/obj/item/pen/pen = allocate(/obj/item/pen, get_turf(body))
	var/datum/component/uplink/antag_training/refusal_probe/probe = pen.AddComponent(/datum/component/uplink/antag_training/refusal_probe, null, FALSE, TRUE)
	var/datum/uplink_item/guardian = antag_training_uplink_entry(probe, /datum/uplink_item/dangerous/guardian)
	var/datum/uplink_item/eightball = antag_training_uplink_entry(probe, /datum/uplink_item/role_restricted/haunted_magic_eightball)
	TEST_ASSERT(guardian && eightball && probe.active, "Открытый аплинк полигона продаёт голопаразита и шар.")
	TEST_ASSERT(!probe.is_uplink_item_visible_to_user(body, eightball), "Шар скрыт от участника без профессии библиотекаря.")
	antag_training_uplink_buy(probe, body, eightball)
	TEST_ASSERT_EQUAL(probe.refusals_checked, 0, "Скрытый по профессии предмет не доходит до отказа полигона.")
	body.Paralyze(10 SECONDS, ignore_canstun = TRUE)
	TEST_ASSERT(body.incapacitated(), "Участник обездвижен.")
	antag_training_uplink_buy(probe, body, guardian)
	TEST_ASSERT_EQUAL(probe.refusals_checked, 0, "Обездвиженный покупатель не доходит до отказа полигона.")
	body.SetParalyzed(0, ignore_canstun = TRUE)
	antag_training_uplink_buy(probe, body, guardian)
	TEST_ASSERT_EQUAL(probe.refusals_checked, 1, "Покупка голопаразита доходит до отказа полигона.")
	TEST_ASSERT_EQUAL(probe.telecrystals, TELECRYSTALS_DEFAULT, "Отказ не списывает кредиты.")
