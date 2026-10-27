/datum/unit_test/proc/training_hk50_pair(datum/antag_training_session/session)
	var/list/pair = list()
	for(var/mob/living/simple_animal/hostile/hk50/droid in session.arena.targets)
		if(droid.training_owner?.resolve() == session)
			pair += droid
	return pair

/// Программа HK-47 собирает куклу как событие, держит имя после входа, а выход удаляет HK и возвращает призрака.
/datum/unit_test/antag_training_hk47_setup/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/hk47)
	TEST_ASSERT(session.prepare(), "Полигон готовит HK-47.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/droid = session.avatar
	TEST_ASSERT(is_species(droid, /datum/species/ipc/hk/hk47), "Кукла становится HK-47.")
	TEST_ASSERT(istype(droid.back, /obj/item/gun/energy/hk_rifle), "Винтовка HK висит на спине.")
	TEST_ASSERT_NULL(locate(/obj/item) in get_turf(droid), "Учебная форма не остаётся лежать под HK.")
	TEST_ASSERT(droid.GetComponent(/datum/component/hk_loyalty), "У HK-47 есть блок лояльности.")
	var/datum/antagonist/hk47/training/role = droid.mind.has_antag_datum(/datum/antagonist/hk47/training)
	TEST_ASSERT(role, "Кукла получает учебную роль HK-47.")
	TEST_ASSERT(role.soft_antag && !role.show_in_roundend && !role.show_in_antagpanel && !role.show_in_check_antagonists && !role.show_to_ghosts, "Учебная роль не попадает в отчёт раунда и админские списки.")
	var/list/programs = list()
	for(var/list/entry as anything in session.ui_static_data(droid)["programs"])
		programs += entry["id"]
	TEST_ASSERT("[/datum/antag_training_program/hk47]" in programs, "Программа HK-47 есть в списке пульта.")
	var/list/data = session.ui_data(droid)
	TEST_ASSERT(!data["heretic"], "Пульт HK-47 не показывает разделы еретика.")
	for(var/option in session.program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	observer.real_name = "Training Ghost"
	TEST_ASSERT(session.connect(observer), "Призрак входит в HK-47.")
	TEST_ASSERT_EQUAL(droid.real_name, HK47_NAME, "Вход не заменяет имя HK-47 именем призрака.")
	var/mob/dead/observer/returned = session.finish()
	allocated += returned
	TEST_ASSERT_EQUAL(returned.real_name, "Training Ghost", "Выход возвращает прежнего призрака.")
	TEST_ASSERT_EQUAL(get_turf(returned), run_loc_floor_bottom_left, "Призрак возвращается на прежнее место.")
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Полигон очищается после выхода.")
	TEST_ASSERT(QDELETED(droid) && QDELETED(role), "Выход удаляет тело HK и учебную роль.")

/// Своя кукла становится HK-47 целиком: протезы и ампутации слота не переходят на шасси ни при входе, ни при восстановлении.
/datum/unit_test/antag_training_hk47_own_doll/Run()
	var/datum/preferences/preferences = new
	allocated += preferences
	preferences.pref_species = new /datum/species/lizard
	preferences.real_name = "Training Doll"
	preferences.modified_limbs = list(BODY_ZONE_R_ARM = list(LOADOUT_LIMB_PROSTHETIC, "prosthetic"), BODY_ZONE_L_LEG = list(LOADOUT_LIMB_AMPUTATED))
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/hk47, preferences)
	TEST_ASSERT(session.prepare(), "Полигон готовит HK-47 из своей куклы.")
	for(var/stage in list("Вход", "Восстановление"))
		if(stage == "Восстановление")
			session.heal_self()
		var/mob/living/carbon/human/droid = session.avatar
		TEST_ASSERT(is_species(droid, /datum/species/ipc/hk/hk47), "[stage]: кукла остаётся HK-47.")
		TEST_ASSERT_EQUAL(droid.real_name, HK47_NAME, "[stage]: имя из слота заменяется на HK-47.")
		TEST_ASSERT(droid.get_bodypart(BODY_ZONE_L_LEG), "[stage]: ампутация из слота не снимает ногу HK.")
		var/obj/item/bodypart/arm = droid.get_bodypart(BODY_ZONE_R_ARM)
		TEST_ASSERT(arm && !arm.is_robotic_limb(FALSE), "[stage]: протез из слота не заменяет руку HK.")

/// Кнопки HK-47 дают очки, заряд, ЭМИ вне центра, пару HK-50 и перепрошивку на учебную цель.
/datum/unit_test/antag_training_hk47_options/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/hk47)
	TEST_ASSERT(session.prepare(), "Полигон готовит HK-47.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/droid = session.avatar
	var/datum/antagonist/hk47/training/role = droid.mind.has_antag_datum(/datum/antagonist/hk47/training)
	var/obj/item/gun/energy/hk_rifle/rifle = droid.back
	var/datum/antag_training_program/program = session.program

	program.handle_choice(session, droid, "Добавить очки")
	TEST_ASSERT_EQUAL(role.points, ANTAG_TRAINING_POINTS, "Очки пополняются до учебного запаса.")

	droid.set_nutrition(NUTRITION_LEVEL_STARVING)
	rifle.cell.use(rifle.cell.charge)
	program.handle_choice(session, droid, "Полный заряд")
	TEST_ASSERT_EQUAL(droid.nutrition, NUTRITION_LEVEL_WELL_FED, "Заряд шасси полный.")
	TEST_ASSERT_EQUAL(rifle.cell.charge, rifle.cell.maxcharge, "Батарея винтовки полная.")

	program.handle_choice(session, droid, "ЭМИ по себе")
	TEST_ASSERT_EQUAL(rifle.cell.charge, rifle.cell.maxcharge, "В безопасном центре ЭМИ не срабатывает.")
	droid.forceMove(arena.zones["pve"]["spawn"])
	program.handle_choice(session, droid, "ЭМИ по себе")
	TEST_ASSERT(is_hk_droid_disabled(droid), "ЭМИ отключает шасси HK.")
	TEST_ASSERT(rifle.cell.charge < rifle.cell.maxcharge, "ЭМИ разряжает винтовку.")

	program.handle_choice(session, droid, "Вызвать HK-50 для боя")
	var/list/pair = training_hk50_pair(session)
	TEST_ASSERT_EQUAL(length(pair), ANTAG_TRAINING_HK50_PAIR, "Вызывается пара HK-50.")
	for(var/mob/living/simple_animal/hostile/hk50/hk50 as anything in pair)
		TEST_ASSERT(arena.inside_bounds(get_turf(hk50), arena.zones["pve"]["bounds"]), "HK-50 появляется в секторе HK-47.")
		TEST_ASSERT(hk50.ai_controller && !HAS_TRAIT(hk50, TRAIT_AI_PAUSED), "HK-50 сразу вступает в бой.")
	arena.next_spawn_at = 0
	program.handle_choice(session, droid, "Вызвать HK-50 для боя")
	TEST_ASSERT_EQUAL(length(training_hk50_pair(session)), ANTAG_TRAINING_HK50_PAIR, "Одновременно на поле одна пара.")
	var/list/bounds = arena.zones["pve"]["bounds"]
	var/obj/structure/antag_training_barrier/door
	for(var/turf/wall_tile as anything in block(locate(bounds[1], bounds[3], arena.private_level.z_value), locate(bounds[1], bounds[4], arena.private_level.z_value)))
		door ||= locate(/obj/structure/antag_training_barrier) in wall_tile
	TEST_ASSERT(door, "У сектора есть дверь.")
	TEST_ASSERT(!door.CanPass(pair[2], get_turf(door)) && door.CanPass(droid, get_turf(door)), "Дверь сектора пропускает HK-47, но не HK-50.")
	var/mob/living/simple_animal/hostile/hk50/escapee = pair[1]
	escapee.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(arena.owns_area(get_area(escapee)), "HK-50 не покидает полигон.")

	var/datum/component/hk_loyalty/loyalty = droid.GetComponent(/datum/component/hk_loyalty)
	program.handle_choice(session, droid, "Перепрошить меня")
	TEST_ASSERT_NULL(loyalty.get_master(), "Без учебной цели хозяин сбрасывается.")
	var/mob/living/carbon/human/dummy = arena.spawn_creature("human", "laboratory", creator = session)
	program.handle_choice(session, droid, "Перепрошить меня")
	TEST_ASSERT_EQUAL(loyalty.get_master(), dummy.mind, "Хозяином становится учебная цель.")
	TEST_ASSERT_NULL(droid.mind.has_antag_datum(/datum/antagonist/hk47), "Перепрошивка снимает роль HK-47, как в раунде.")

/// Уход HK-47 убирает его HK-50, смена роли возвращает обычное тело, последний выход очищает всё.
/datum/unit_test/antag_training_hk47_cleanup/Run()
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/hk47)
	TEST_ASSERT(first.prepare(), "Полигон готовит первого HK-47.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/hk47)
	TEST_ASSERT(second.prepare(), "Второй HK-47 входит на тот же полигон.")
	var/datum/antag_training_arena/arena = first.arena
	first.current_body.forceMove(arena.zones["pve"]["spawn"])
	first.program.handle_choice(first, first.current_body, "Вызвать HK-50 для боя")
	arena.next_spawn_at = 0
	second.current_body.forceMove(arena.zones["range"]["spawn"])
	second.program.handle_choice(second, second.current_body, "Вызвать HK-50 для боя")
	var/list/first_pair = training_hk50_pair(first)
	var/list/second_pair = training_hk50_pair(second)
	TEST_ASSERT(length(first_pair) && length(second_pair), "Каждый HK-47 вызывает свою пару.")

	var/mob/living/carbon/human/old_body = first.avatar
	var/datum/antagonist/hk47/training/old_role = old_body.mind.has_antag_datum(/datum/antagonist/hk47/training)
	TEST_ASSERT(first.restart(/datum/antag_training_program/free), "HK-47 меняет роль.")
	TEST_ASSERT(QDELETED(old_body) && QDELETED(old_role), "Смена роли удаляет тело и роль HK-47.")
	TEST_ASSERT(!is_species(first.avatar, /datum/species/ipc/hk), "Новая кукла не остаётся дроидом HK.")
	TEST_ASSERT_NULL(first.avatar.mind.has_antag_datum(/datum/antagonist/hk47), "Новая кукла без роли HK-47.")

	qdel(first)
	var/deadline = world.time + 10 SECONDS
	while(world.time < deadline)
		var/remaining = FALSE
		for(var/mob/living/hk50 as anything in first_pair)
			if(!QDELETED(hk50))
				remaining = TRUE
		if(!remaining)
			break
		stoplag()
	for(var/mob/living/hk50 as anything in first_pair)
		TEST_ASSERT(QDELETED(hk50), "HK-50 ушедшего участника удаляются.")
	for(var/mob/living/hk50 as anything in second_pair)
		TEST_ASSERT(!QDELETED(hk50), "HK-50 оставшегося участника сохраняются.")
	TEST_ASSERT(!QDELETED(second.current_body), "Второй HK-47 продолжает тренировку.")

	var/mob/living/carbon/human/second_body = second.avatar
	qdel(second)
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Последний выход очищает полигон.")
	TEST_ASSERT(QDELETED(second_body), "Тело последнего HK-47 удаляется.")
	for(var/mob/living/hk50 as anything in second_pair)
		TEST_ASSERT(QDELETED(hk50), "Очистка полигона удаляет все HK-50.")

/// Учебные контракты всех видов назначаются на манекены и закрываются внутри сектора.
/datum/unit_test/antag_training_hk47_contracts/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/hk47)
	TEST_ASSERT(session.prepare(), "Полигон готовит HK-47.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/droid = session.avatar
	var/datum/antagonist/hk47/training/role = droid.mind.has_antag_datum(/datum/antagonist/hk47/training)
	var/datum/antag_training_program/hk47/program = session.program
	TEST_ASSERT(role.terminal && droid.has_status_effect(/datum/status_effect/hk47_tracker), "Учебный HK-47 получает терминал и целеуказатель.")
	droid.forceMove(arena.zones["pve"]["spawn"])
	program.handle_choice(session, droid, "Контракт: ликвидация")
	TEST_ASSERT_NULL(role.active_contract, "Без учебной цели контракт не назначается.")

	var/mob/living/carbon/human/dummy = arena.spawn_creature("human", "pve", creator = session)
	program.target_created(session, dummy)
	dummy.forceMove(get_step(droid, EAST))
	program.handle_choice(session, droid, "Контракт: ликвидация")
	var/datum/hk_contract/contract = role.active_contract
	TEST_ASSERT(istype(contract?.task, /datum/hk_contract_task/kill) && contract.target_mind() == dummy.mind, "Ликвидация назначена на отмеченную учебную цель.")
	dummy.death()
	TEST_ASSERT(role.try_scan(dummy), "Скан трупа манекена закрывает ликвидацию.")
	TEST_ASSERT_EQUAL(role.contracts_done, 1, "Ликвидация засчитана.")
	dummy.revive(full_heal = TRUE, admin_revive = TRUE)

	program.handle_choice(session, droid, "Контракт: захват")
	contract = role.active_contract
	TEST_ASSERT(istype(contract?.task, /datum/hk_contract_task/capture), "Захват назначен.")
	dummy.Paralyze(ANTAG_TRAINING_KNOCKDOWN, ignore_canstun = TRUE)
	TEST_ASSERT(role.try_capture(dummy), "Учебная капсула вызывается к обездвиженной цели.")
	role.finish_practice_capture(WEAKREF(contract), WEAKREF(dummy), get_turf(dummy))
	TEST_ASSERT_EQUAL(role.contracts_done, 2, "Захват засчитан учебной капсулой.")
	TEST_ASSERT(arena.owns_area(get_area(dummy)), "Захваченный манекен остаётся на полигоне.")
	dummy.SetParalyzed(0)

	program.handle_choice(session, droid, "Контракт: кража")
	var/obj/item/card/id/card = dummy.wear_id
	TEST_ASSERT(istype(card) && card.registered_name == dummy.real_name, "У цели кражи есть её ID-карта.")
	dummy.temporarilyRemoveItemFromInventory(card, TRUE)
	droid.put_in_hands(card)
	TEST_ASSERT(role.try_scan(), "Скан карты цели в руке закрывает кражу.")
	TEST_ASSERT(QDELETED(card) && role.contracts_done == 3, "Карта ушла заказчику, кража засчитана.")

	program.handle_choice(session, droid, "Контракт: охрана")
	contract = role.active_contract
	TEST_ASSERT(istype(contract?.task, /datum/hk_contract_task/protect), "Охрана назначена.")
	TEST_ASSERT(round(contract.deadline() - world.time, 1) <= ANTAG_TRAINING_HK47_PROTECT_TIME, "Учебная охрана короче раундовой.")
	contract.protect_time_up()
	TEST_ASSERT_EQUAL(role.contracts_done, 4, "Охрана засчитана.")

	program.handle_choice(session, droid, "Контракт: саботаж")
	contract = role.active_contract
	var/obj/machinery/antag_training_server/server = contract?.get_target()
	TEST_ASSERT(istype(server) && arena.inside_bounds(get_turf(server), arena.zones["pve"]["bounds"]), "Учебный сервер стоит в секторе HK-47.")
	server.take_damage(server.max_integrity * server.integrity_failure + 1)
	TEST_ASSERT_EQUAL(role.contracts_done, 5, "Поломка сервера закрывает саботаж.")

	var/list/before = arena.targets.Copy()
	program.handle_choice(session, droid, "Контракт: охота с опознанием")
	contract = role.active_contract
	var/list/lineup = arena.targets - before
	TEST_ASSERT(contract?.is_hunt() && !contract.identified, "Охота с неизвестной целью.")
	TEST_ASSERT_EQUAL(length(lineup), ANTAG_TRAINING_HK47_SUSPECTS, "Для охоты встают манекены-подозреваемые.")
	var/mob/living/carbon/human/hunted = contract.target_body()
	TEST_ASSERT(hunted in lineup, "Цель охоты - один из манекенов.")
	var/mob/living/carbon/human/decoy = (lineup - hunted)[1]
	droid.forceMove(get_turf(decoy))
	TEST_ASSERT(length(role.terminal.suspects(droid)), "Терминал видит манекены рядом как подозреваемых.")
	TEST_ASSERT(!role.try_identify(decoy), "Манекен-обманка не опознаётся.")
	COOLDOWN_RESET(role, identify_cooldown)
	droid.forceMove(get_turf(hunted))
	TEST_ASSERT(role.try_identify(hunted), "Цель охоты опознаётся вблизи.")
	hunted.Paralyze(ANTAG_TRAINING_KNOCKDOWN, ignore_canstun = TRUE)
	TEST_ASSERT(role.try_capture(hunted), "Опознанную цель охоты можно захватить.")
	role.finish_practice_capture(WEAKREF(role.active_contract), WEAKREF(hunted), get_turf(hunted))
	TEST_ASSERT_EQUAL(role.contracts_done, 6, "Охота засчитана.")

/// Кража на манекен из обычного предложения терминала, а не с пульта, тоже выполнима: манекен получает свою ID-карту.
/datum/unit_test/antag_training_hk47_offered_theft/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/hk47)
	TEST_ASSERT(session.prepare(), "Полигон готовит HK-47.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/droid = session.avatar
	var/datum/antagonist/hk47/training/role = droid.mind.has_antag_datum(/datum/antagonist/hk47/training)
	var/datum/antag_training_program/hk47/program = session.program
	droid.forceMove(arena.zones["pve"]["spawn"])
	var/mob/living/carbon/human/dummy = arena.spawn_creature("human", "pve", creator = session)
	program.target_created(session, dummy)
	dummy.forceMove(get_step(droid, EAST))
	TEST_ASSERT_NULL(dummy.wear_id, "Манекен появляется без ID-карты.")

	var/datum/hk_contract/offer = role.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/theft, /datum/hk_contract_modifier/no_witnesses, dummy.mind)
	role.offers += offer
	TEST_ASSERT(role.accept(offer), "Предложенная кража на манекен принимается.")
	var/obj/item/card/id/card = dummy.wear_id
	TEST_ASSERT(istype(card) && card.registered_name == dummy.real_name, "Цель предложенной кражи получает свою ID-карту.")
	dummy.temporarilyRemoveItemFromInventory(card, TRUE)
	droid.put_in_hands(card)
	TEST_ASSERT(role.try_scan(), "Скан карты закрывает предложенную кражу.")
	TEST_ASSERT_EQUAL(role.contracts_done, 1, "Предложенная кража засчитана.")

/// Учебный HK-47 не доходит до станции: раскрытия без объявлений, записей и пеленгатора, HK-50 с разумом закрыт, пара встаёт в секторе, выход всё убирает.
/datum/unit_test/antag_training_hk47_isolation/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/hk47)
	TEST_ASSERT(session.prepare(), "Полигон готовит HK-47.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/droid = session.avatar
	var/datum/antagonist/hk47/training/role = droid.mind.has_antag_datum(/datum/antagonist/hk47/training)
	var/datum/antag_training_program/hk47/program = session.program
	var/list/station = role.terminal_status_data()
	TEST_ASSERT_EQUAL(station["status_name"], "учебный режим", "Терминал показывает учебный режим вместо статуса для станции.")

	var/mob/living/carbon/human/dummy = arena.spawn_creature("human", "laboratory", creator = session)
	program.target_created(session, dummy)
	var/news_before = GLOB.news_network.lastAction
	var/records_before = length(GLOB.data_core.security)
	var/bounties_before = length(GLOB.bounties_list)
	for(var/reveal in 1 to HK47_TRACKER_REVEAL)
		var/datum/hk_contract/dirty = role.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/kill, null, dummy.mind)
		SEND_SIGNAL(droid, COMSIG_HK47_CONTRACT_COMPLETED, dirty, TRUE)
		qdel(dirty)
	TEST_ASSERT_EQUAL(role.reveals, HK47_TRACKER_REVEAL, "Раскрытия при свидетелях считаются.")
	TEST_ASSERT_EQUAL(role.status, HK47_STATUS_COVERT, "Статус для станции не меняется.")
	TEST_ASSERT_NULL(role.record_id, "Записи СБ нет.")
	TEST_ASSERT_EQUAL(length(GLOB.data_core.security), records_before, "База СБ не пополняется.")
	TEST_ASSERT_EQUAL(GLOB.news_network.lastAction, news_before, "Объявлений станции нет.")
	TEST_ASSERT_EQUAL(length(GLOB.bounties_list), bounties_before, "Заказа на ядро нет.")
	TEST_ASSERT_NULL(locate(/obj/item/pinpointer/hk47) in world, "Пеленгатора нет.")
	role.contracts_done = HK47_CONTRACTS_TO_WIN
	TEST_ASSERT(findtext(role.extraction_refusal(droid), "полигон"), "Эвакуации на полигоне нет.")

	role.points = 0
	program.handle_choice(session, droid, "Добавить очки")
	var/total_cost = 0
	for(var/module_price in HK47_MODULE_PRICES)
		total_cost += module_price
	var/list/servant_prices = HK47_SERVANT_PRICES
	var/datum/hk47_upgrade/ghost_upgrade = GLOB.hk47_upgrades["ghost_servant"]
	total_cost += servant_prices[1] + ghost_upgrade.cost
	TEST_ASSERT(role.points >= total_cost, "Учебных очков хватает на все модули по растущим ценам.")
	var/datum/hk47_upgrade/ghost_servant = GLOB.hk47_upgrades["ghost_servant"]
	TEST_ASSERT(findtext(ghost_servant.refusal(role), "полигон"), "Терминал объясняет, почему HK-50 с разумом закрыт.")
	var/points = role.points
	TEST_ASSERT(!role.buy_upgrade("ghost_servant"), "HK-50 с разумом не покупается и призраков не зовёт.")
	TEST_ASSERT_EQUAL(role.points, points, "Очки за закрытый модуль не списываются.")
	TEST_ASSERT(role.buy_upgrade("servants"), "Пара HK-50 покупается.")
	var/list/servants = hk50_servants_of(droid)
	TEST_ASSERT_EQUAL(length(servants), HK50_SERVANT_PAIR_SIZE, "Пара прибывает сразу, без капсулы.")
	for(var/mob/living/servant as anything in servants)
		TEST_ASSERT(arena.inside_bounds(get_turf(servant), arena.zones["pve"]["bounds"]), "Из центра пара встаёт на арене противников.")
		TEST_ASSERT_EQUAL(servant.training_owner?.resolve(), session, "Пара принадлежит участнику и уходит вместе с ним.")

	droid.forceMove(arena.zones["pve"]["spawn"])
	program.handle_choice(session, droid, "Контракт: саботаж")
	var/obj/machinery/server = role.active_contract?.get_target()
	var/list/before = arena.targets.Copy()
	program.handle_choice(session, droid, "Контракт: охота с опознанием")
	var/list/lineup = arena.targets - before
	var/datum/hk_contract/contract = role.active_contract
	var/datum/hk_terminal/terminal = role.terminal
	var/datum/status_effect/hk47_tracker/tracker = droid.has_status_effect(/datum/status_effect/hk47_tracker)
	TEST_ASSERT(server && contract && terminal && tracker && length(lineup), "Перед выходом есть контракт, терминал, целеуказатель, сервер и манекены.")
	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Полигон очищается после выхода.")
	TEST_ASSERT(QDELETED(role) && QDELETED(contract) && QDELETED(terminal) && QDELETED(tracker) && QDELETED(server), "Выход удаляет роль, контракт, терминал, целеуказатель и сервер.")
	for(var/mob/living/leftover as anything in servants + lineup)
		TEST_ASSERT(QDELETED(leftover), "Выход удаляет HK-50 и манекены.")

/// Учебный HK-47 при гибели не роняет настоящее ядро памяти: баунти карго - только за HK из раунда.
/datum/unit_test/antag_training_hk47_no_core/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/hk47)
	TEST_ASSERT(session.prepare(), "Полигон готовит HK-47.")
	var/mob/living/carbon/human/droid = session.avatar
	var/turf/death_spot = get_turf(droid)
	droid.death()
	TEST_ASSERT_NULL(locate(/obj/item/hk47_core) in death_spot, "Ядро памяти на полигоне не выпадает.")
