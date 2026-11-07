/datum/unit_test/antag_training_space_dragon/proc/station_spot(datum/antag_training_sector/station, offset_x, offset_y)
	return locate(station.origin_x + offset_x, station.origin_y + offset_y, station.arena.private_level.z_value)

/datum/unit_test/antag_training_space_dragon/proc/open_rift(mob/living/simple_animal/hostile/space_dragon/training/dragon)
	var/opened_before = length(dragon.rift_list)
	INVOKE_ASYNC(dragon.rift, TYPE_PROC_REF(/datum/action, Trigger))
	var/list/budget = new_wait_budget(15 SECONDS, "дракон открывает разлом")
	while(length(dragon.rift_list) == opened_before && wait_budget_tick(budget))
		continue
	return length(dragon.rift_list) > opened_before ? dragon.rift_list[length(dragon.rift_list)] : null

/datum/unit_test/antag_training_space_dragon/proc/swallow(mob/living/simple_animal/hostile/space_dragon/training/dragon, mob/living/corpse)
	var/list/budget = new_wait_budget(6 SECONDS, "дракон готов к атаке")
	while(!dragon.CheckActionCooldown(immediate = TRUE) && wait_budget_tick(budget))
		continue
	INVOKE_ASYNC(dragon, TYPE_PROC_REF(/mob, ClickOn), corpse)
	budget = new_wait_budget(6 SECONDS, "дракон глотает [corpse]")
	while(corpse.loc != dragon && wait_budget_tick(budget))
		continue
	return corpse.loc == dragon

/// Учебный дракон открывает разломы в станционном макете действием «Summon Rift», а пульт их заряжает: три заряженных - учебная победа без объявлений; призраки не оповещаются; разлом не ставится вне макета и рядом с другим, уничтоженный снимается «Отдыхом», убранный пультом не штрафует, карпов у заряженного разлома не больше предела и после победы нет, а новое тело после смерти убирает прежние разломы.
/datum/unit_test/antag_training_space_dragon/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/space_dragon)
	TEST_ASSERT(session.prepare(), "Полигон готовит дракона.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/datum/antag_training_program/creature/space_dragon/program = session.program
	var/mob/living/simple_animal/hostile/space_dragon/training/dragon = session.current_body
	TEST_ASSERT(istype(dragon) && dragon.mind == session.avatar_mind, "Разум участника в учебном драконе.")
	var/list/budget = new_wait_budget(10 SECONDS, "дракон в макете")
	while(!arena.inside_bounds(get_turf(dragon), station.bounds) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(arena.inside_bounds(get_turf(dragon), station.bounds), "Дракон начинает в станционном макете.")
	TEST_ASSERT(dragon.chosen_color, "Цвет задан заранее: вход не спрашивает имя и цвет.")
	TEST_ASSERT(istype(dragon.rift, /datum/action/innate/summon_rift/training), "Действие разлома учебное.")
	for(var/option in program.options)
		TEST_ASSERT(length(program.option_hints[option]), "У кнопки «[option]» есть подсказка.")
	var/datum/action/innate/summon_rift/training/action = dragon.rift
	var/datum/tgui/console = allocate(/datum/tgui, dragon, session, "AntagTraining")
	var/list/news_before = news_messages()
	GLOB.unit_test_ghost_notifications = list()
	var/obj/structure/carp_rift/control = allocate(/obj/structure/carp_rift, run_loc_floor_bottom_left)
	control.last_carp_inc = control.carp_interval
	control.update_check()
	TEST_ASSERT_EQUAL(length(GLOB.unit_test_ghost_notifications), 1, "Перехват видит оповещение призраков от разлома раунда.")
	qdel(control)
	GLOB.unit_test_ghost_notifications = list()

	dragon.forceMove(arena.entry_turf)
	action.Trigger()
	TEST_ASSERT(!length(dragon.rift_list) && dragon.rift == action, "Вне станционного макета разлом не открывается.")

	dragon.forceMove(station_spot(station, 3, 4))
	var/obj/structure/carp_rift/training/opened = open_rift(dragon)
	TEST_ASSERT(istype(opened), "Действие открывает учебный разлом.")
	TEST_ASSERT((opened in arena.targets) && opened.training_owner?.resolve() == session, "Разлом стоит в лимите целей и принадлежит участнику.")
	TEST_ASSERT_NULL(dragon.rift, "Пока разлом заряжается, нового не открыть.")
	opened.take_damage(opened.max_integrity * 2, BRUTE, MELEE, FALSE)
	TEST_ASSERT(QDELETED(opened) && !length(dragon.rift_list), "Разлом разрушается ударами.")
	TEST_ASSERT(dragon.riftTimer == -1 && dragon.has_movespeed_modifier(/datum/movespeed_modifier/dragon_depression), "Уничтоженный разлом замедляет дракона и запрещает новые.")
	antag_training_console_act(session, console, "program_option", list("option" = "Отдых"))
	TEST_ASSERT(istype(dragon.rift, /datum/action/innate/summon_rift/training) && dragon.riftTimer == 0, "«Отдых» возвращает действие разлома.")
	TEST_ASSERT(!dragon.has_movespeed_modifier(/datum/movespeed_modifier/dragon_depression) && dragon.tiredness_mult == 1, "«Отдых» снимает замедление и усталость.")
	opened = open_rift(dragon)
	TEST_ASSERT(istype(opened), "Разлом открыт снова.")
	opened.ex_act(EXPLODE_DEVASTATE)
	TEST_ASSERT(QDELETED(opened), "Разлом разрушается взрывом.")
	TEST_ASSERT(dragon.riftTimer == -1 && dragon.has_movespeed_modifier(/datum/movespeed_modifier/dragon_depression), "Разлом, разрушенный взрывом, штрафует дракона.")
	antag_training_console_act(session, console, "program_option", list("option" = "Отдых"))
	TEST_ASSERT(istype(dragon.rift, /datum/action/innate/summon_rift/training), "«Отдых» возвращает действие и после взрыва.")

	var/list/spots = list(list(3, 4), list(6, 23), list(36, 24))
	var/list/carps
	for(var/index in 1 to length(spots))
		var/list/offset = spots[index]
		dragon.forceMove(station_spot(station, offset[1], offset[2]))
		opened = open_rift(dragon)
		TEST_ASSERT(istype(opened), "Разлом [index] открыт.")
		if(index == 2)
			antag_training_console_act(session, console, "target_delete", list("id" = REF(opened)))
			TEST_ASSERT(QDELETED(opened), "Пульт убирает разлом из целей.")
			TEST_ASSERT(dragon.riftTimer != -1 && !dragon.has_movespeed_modifier(/datum/movespeed_modifier/dragon_depression), "Уборка разлома пультом не штрафует дракона.")
			TEST_ASSERT(istype(dragon.rift, /datum/action/innate/summon_rift/training) && dragon.rifts_charged == 1, "После уборки разлома можно открыть новый, заряженные учтены.")
			opened = open_rift(dragon)
			TEST_ASSERT(istype(opened), "Разлом [index] открыт заново.")
		antag_training_console_act(session, console, "program_option", list("option" = "Зарядить разлом"))
		TEST_ASSERT(opened.time_charged >= opened.max_charge && (opened.resistance_flags & INDESTRUCTIBLE), "«Зарядить разлом» заряжает разлом [index] до конца.")
		TEST_ASSERT_EQUAL(dragon.rifts_charged, index, "Заряженных разломов: [index].")
		if(index != 1)
			continue
		action = dragon.rift
		dragon.forceMove(station_spot(station, 7, 4))
		action.Trigger()
		TEST_ASSERT_EQUAL(length(dragon.rift_list), 1, "Разлом не открывается ближе [action.min_spacing] клеток к другому.")
		for(var/attempt in 1 to ANTAG_TRAINING_TARGET_LIMIT * 4)
			opened.process((1 MINUTES) / (1 SECONDS))
		carps = arena_carps(arena)
		TEST_ASSERT_EQUAL(length(carps), opened.carp_limit, "Заряженный разлом выпускает не больше [opened.carp_limit] карпов.")
		for(var/mob/living/simple_animal/hostile/carp/carp as anything in carps)
			TEST_ASSERT(carp in arena.targets, "Каждый карп разлома учтён в лимите целей.")
			TEST_ASSERT(arena.inside_bounds(get_turf(carp), station.bounds), "Карп разлома остаётся в станционном макете.")
		antag_training_console_act(session, console, "target_delete", list("id" = REF(opened)))
		TEST_ASSERT(QDELETED(opened) && !dragon.has_movespeed_modifier(/datum/movespeed_modifier/dragon_depression), "Заряженный разлом убирается пультом без штрафа.")
		TEST_ASSERT_EQUAL(dragon.rifts_charged, 0, "Убранный заряженный разлом снимается со счёта, счёт не уходит в минус.")
		opened = open_rift(dragon)
		TEST_ASSERT(istype(opened), "После уборки заряженного разлома открывается новый.")
		antag_training_console_act(session, console, "program_option", list("option" = "Зарядить разлом"))
		TEST_ASSERT_EQUAL(dragon.rifts_charged, 1, "Новый разлом снова в счёте.")
	TEST_ASSERT(dragon.objective_complete, "Три заряженных разлома - победа дракона.")
	TEST_ASSERT(findtext(session.ui_data(dragon)["last_feedback"], "Учебная победа дракона"), "Пульт сообщает об учебной победе.")
	var/list/fresh_news = list()
	for(var/datum/news/feed_message/message as anything in news_messages() - news_before)
		if(!findtext(message.body, "Отдел ССО ПАКТа Синих Лун"))
			fresh_news += message.body
	TEST_ASSERT(!length(fresh_news), "Разломы и победа не дают объявлений: [jointext(fresh_news, "; ")]")
	TEST_ASSERT_NULL(dragon.rift, "После победы новых разломов нет.")
	var/datum/antagonist/space_dragon/training/role = program.role(session)
	for(var/datum/objective/objective as anything in role.objectives)
		TEST_ASSERT(objective.completed, "Учебная цель дракона отмечена выполненной.")
	carps = arena_carps(arena)
	for(var/obj/structure/carp_rift/training/charged as anything in dragon.rift_list)
		for(var/attempt in 1 to ANTAG_TRAINING_TARGET_LIMIT)
			charged.process((1 MINUTES) / (1 SECONDS))
	TEST_ASSERT_EQUAL(length(arena_carps(arena)), length(carps), "После учебной победы разломы карпов не выпускают.")
	TEST_ASSERT(!length(GLOB.unit_test_ghost_notifications), "Учебные разломы не оповещают призраков: [jointext(GLOB.unit_test_ghost_notifications, "; ")]")
	GLOB.unit_test_ghost_notifications = null

	antag_training_console_act(session, console, "program_option", list("option" = "Цели"))
	var/mob/living/carbon/human/meal
	for(var/mob/living/carbon/human/dummy in arena.targets)
		if(dummy.training_owner?.resolve() == session && arena.inside_bounds(get_turf(dummy), station.bounds))
			meal = dummy
	TEST_ASSERT_NOTNULL(meal, "«Цели» ставит манекен рядом с драконом.")
	meal.death()
	meal.forceMove(get_step(dragon, WEST))
	TEST_ASSERT(swallow(dragon, meal), "Дракон проглатывает мёртвый манекен.")
	TEST_ASSERT(meal in arena.targets, "Проглоченный манекен остаётся в лимите целей.")
	var/datum/antag_training_session/other = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(other.prepare(arena), "Второй участник входит на тот же полигон.")
	other.auto_recover = FALSE
	var/mob/living/carbon/human/other_body = other.current_body
	other_body.forceMove(get_step(dragon, EAST))
	other_body.death()
	TEST_ASSERT(!swallow(dragon, other_body), "Тело другого участника дракон не проглатывает.")
	qdel(other)

	var/list/old_rifts = dragon.rift_list.Copy()
	dragon.death()
	TEST_ASSERT(antag_training_wait_new_body(session, dragon, "дракон после смерти"), "После смерти появляется новый дракон.")
	var/mob/living/simple_animal/hostile/space_dragon/training/rebuilt = session.current_body
	TEST_ASSERT(QDELETED(dragon), "Прежнее тело убрано.")
	for(var/obj/structure/carp_rift/old_rift as anything in old_rifts)
		TEST_ASSERT(QDELETED(old_rift), "Разломы прежнего тела убраны с ним.")
	TEST_ASSERT(istype(rebuilt.rift, /datum/action/innate/summon_rift/training) && !rebuilt.rifts_charged && !rebuilt.objective_complete, "Новый дракон начинает с действием разлома.")
	TEST_ASSERT(arena.inside_bounds(get_turf(rebuilt), station.bounds), "Новый дракон появляется в станционном макете.")
	pass(view(0, run_loc_floor_bottom_left))

/datum/unit_test/antag_training_space_dragon/Destroy()
	GLOB.unit_test_ghost_notifications = null
	return ..()

/// Сообщения ленты новостей; сводка угроз раунда приходит по своему таймеру и в проверку не входит.
/datum/unit_test/antag_training_space_dragon/proc/news_messages()
	. = list()
	for(var/datum/news/feed_channel/channel as anything in GLOB.news_network.network_channels)
		. += channel.messages

/datum/unit_test/antag_training_space_dragon/proc/arena_carps(datum/antag_training_arena/arena)
	. = list()
	for(var/mob/living/simple_animal/hostile/carp/carp in GLOB.mob_living_list)
		if(carp.training_origin?.resolve() == arena)
			. += carp
