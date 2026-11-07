/datum/unit_test/proc/antag_training_terror_switch(datum/antag_training_session/session, spider_type)
	var/datum/antag_training_program/creature/terror_spider/program = session.program
	var/datum/tgui/console = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option(spider_type)))
	return session.current_body

/datum/unit_test/proc/antag_training_terror_brood(mob/living/simple_animal/hostile/retaliate/poison/terror_spider/mother)
	. = list()
	for(var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider as anything in GLOB.ts_spiderlist)
		if(spider.spider_mymother == mother && !QDELETED(spider))
			. += spider

/datum/unit_test/proc/antag_training_terror_green_eggs(datum/antag_training_session/session, mob/living/simple_animal/hostile/retaliate/poison/terror_spider/healer/healer, turf/spot)
	healer.forceMove(spot)
	var/datum/tgui/console = allocate(/datum/tgui, healer, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Здоровье и кладки"))
	healer.greeneggs_action.Trigger()
	return locate(/obj/structure/spider/eggcluster/terror_eggcluster) in spot

/// Королева и лекарь полигона кладут яйца только в лимит целей, королевских яиц нет, выводок - пауки полигона, недоступные призракам, а смена вида не оставляет выводку ссылок на прежнее тело.
/datum/unit_test/antag_training_terror_spider_brood
	var/list/added_players = list()

/datum/unit_test/antag_training_terror_spider_brood/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/terror_spider)
	TEST_ASSERT(session.prepare(), "Полигон готовит паука.")
	var/datum/antag_training_program/creature/terror_spider/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	for(var/option in program.options)
		TEST_ASSERT(length(program.option_hints[option]), "У кнопки «[option]» есть подсказка.")
	TEST_ASSERT(!(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/empress in program.choices), "Императрицы среди видов нет.")
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/queen = antag_training_terror_switch(session, /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen)
	TEST_ASSERT_EQUAL(queen?.type, /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen, "Пульт меняет вид на королеву.")
	TEST_ASSERT_EQUAL(queen.mind, session.avatar_mind, "Разум участника в королеве.")
	TEST_ASSERT(queen.mind.has_antag_datum(/datum/antagonist/terror_spiders/training) && !queen.mind.has_antag_datum(/datum/antagonist/terror_spiders, FALSE), "У королевы учебный датум, а не датум раунда.")
	TEST_ASSERT(!queen.spider_growinstantly && queen.spider_spawnfrequency == initial(queen.spider_spawnfrequency), "Яйца растут и копятся как в раунде.")
	var/turf/lay_spot = arena.zones["melee"]["spawn"]
	queen.forceMove(lay_spot)
	queen.spider_creation_time = world.time - 30 MINUTES
	var/list/egg_types = queen.ListAvailableEggTypes()
	TEST_ASSERT(("Knight - ASSAULT" in egg_types) && !("Princess - HORDE" in egg_types) && !("Mother - SUPPORT" in egg_types) && !("Defiler - INFECT" in egg_types), "Королевских яиц на полигоне нет и через 25 минут.")
	queen.NestMode()

	var/turf/spot = arena.zones["melee"]["target"]
	while(arena.has_target_room())
		TEST_ASSERT(arena.claim_target(new /obj/item/pen(spot), session), "Свободное место в лимите принимает цель.")
	var/eggs_before = length(GLOB.ts_egg_list)
	var/canlay = queen.canlay
	GLOB.unit_test_chat_capture = list()
	queen.queeneggs_action.Trigger()
	TEST_ASSERT(antag_training_heard(queen, "Кладка не ложится"), "Королева видит отказ кладки при полном лимите.")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT_EQUAL(queen.canlay, canlay, "Отказ не тратит яйца.")
	TEST_ASSERT_EQUAL(length(GLOB.ts_egg_list), eggs_before, "При полном лимите яйца королевы не ложатся.")

	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/healer/healer = antag_training_terror_switch(session, /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/healer)
	TEST_ASSERT(istype(healer), "Пульт меняет вид на лекаря.")
	TEST_ASSERT_NULL(antag_training_terror_green_eggs(session, healer, get_step(lay_spot, NORTH)), "При полном лимите лекарь не кладёт яйца.")
	TEST_ASSERT_EQUAL(healer.fed, healer.feedings_to_lay, "Отказ не тратит пищу лекаря.")
	for(var/freed in 1 to 2)
		qdel(locate(/obj/item/pen) in spot)
	var/list/clusters = list()
	for(var/step_dir in list(EAST, WEST))
		var/obj/structure/spider/eggcluster/terror_eggcluster/cluster = antag_training_terror_green_eggs(session, healer, get_step(lay_spot, step_dir))
		TEST_ASSERT(cluster && (cluster in arena.targets), "Кладка лекаря в лимите встаёт в цели полигона.")
		TEST_ASSERT_EQUAL(cluster.training_owner?.resolve(), session, "Кладка принадлежит участнику.")
		clusters += cluster
	TEST_ASSERT_EQUAL(healer.fed, 0, "Кладка тратит пищу лекаря.")
	TEST_ASSERT_NULL(antag_training_terror_green_eggs(session, healer, get_step(lay_spot, SOUTH)), "Третья кладка сверх лимита не ложится.")

	for(var/obj/structure/spider/eggcluster/terror_eggcluster/cluster as anything in clusters)
		cluster.amount_grown = 139
	var/list/budget = new_wait_budget(30 SECONDS, "выводок вылупился и вырос")
	while(length(antag_training_terror_brood(healer)) < 2 && wait_budget_tick(budget))
		continue
	var/list/brood = antag_training_terror_brood(healer)
	TEST_ASSERT_EQUAL(length(brood), 2, "Из двух кладок выросли два паука.")
	for(var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider as anything in brood)
		TEST_ASSERT_EQUAL(spider.training_origin?.resolve(), arena, "Паук выводка принадлежит полигону.")
		TEST_ASSERT_EQUAL(spider.training_owner?.resolve(), session, "Паук выводка принадлежит участнику.")
		TEST_ASSERT(spider in arena.targets, "Паук выводка в лимите целей.")
	TEST_ASSERT(length(arena.targets) <= ANTAG_TRAINING_TARGET_LIMIT, "Выводок не превышает лимит целей.")

	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/offspring = brood[1]
	TEST_ASSERT(offspring.spider_awaymission, "Паук выводка помечен как недоступный призракам.")
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, get_turf(offspring))
	added_players = list(observer) - GLOB.player_list
	GLOB.player_list += added_players
	GLOB.unit_test_chat_capture = list()
	INVOKE_ASYNC(offspring, TYPE_PROC_REF(/atom, attack_ghost), observer)
	TEST_ASSERT(antag_training_heard(observer, "part of an away mission"), "Призрак получает отказ вселения в паука выводка.")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT_NULL(offspring.key, "Призрак не вселяется в паука выводка.")

	qdel(locate(/obj/item/pen) in spot)
	var/obj/item/pen/grudge_target = locate() in spot
	healer.add_enemy(grudge_target)
	var/obj/structure/spider/eggcluster/terror_eggcluster/pending = antag_training_terror_green_eggs(session, healer, get_step(lay_spot, SOUTH))
	TEST_ASSERT_EQUAL(pending?.spider_mymother, healer, "Кладка помнит отложившего её лекаря.")
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/knight = antag_training_terror_switch(session, /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight)
	TEST_ASSERT(istype(knight), "Пульт меняет вид на рыцаря.")
	TEST_ASSERT(QDELETED(healer), "Прежнее тело лекаря убрано.")
	TEST_ASSERT(!QDELETED(pending) && !QDELETED(offspring), "Выводок и кладка переживают смену вида.")
	var/datum/weakref/grudge = length(pending.enemies) == 1 ? pending.enemies[1] : null
	TEST_ASSERT(istype(grudge) && grudge.resolve() == grudge_target, "Кладка помнит врагов лекаря слабой ссылкой, а не его списком.")
	for(var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider as anything in GLOB.ts_spiderlist)
		TEST_ASSERT(spider.spider_mymother != healer && spider.spider_myqueen != healer, "Паук выводка не держит прежнее тело.")
	for(var/obj/structure/spider/eggcluster/terror_eggcluster/cluster as anything in GLOB.ts_egg_list)
		TEST_ASSERT(cluster.spider_mymother != healer && cluster.spider_myqueen != healer, "Кладка не держит прежнее тело.")
	for(var/obj/structure/spider/spiderling/terror_spiderling/spiderling as anything in GLOB.ts_spiderling_list)
		TEST_ASSERT(spiderling.spider_mymother != healer && spiderling.spider_myqueen != healer, "Паучонок не держит прежнее тело.")
	pass(view(0, run_loc_floor_bottom_left))

/datum/unit_test/antag_training_terror_spider_brood/Destroy()
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= added_players
	added_players.Cut()
	return ..()

/// Улей и чутьё улья полигона не доходят до пауков станции, месть королевы не размечает их врагов, а смерть пауков полигона не трогает счётчики раунда.
/datum/unit_test/antag_training_terror_spider_hive
	var/list/added_players = list()
	var/saved_dead
	var/saved_death_last

/datum/unit_test/antag_training_terror_spider_hive/Run()
	saved_dead = GLOB.ts_count_dead
	saved_death_last = GLOB.ts_death_last
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/terror_spider)
	TEST_ASSERT(session.prepare(), "Полигон готовит паука.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/queen = antag_training_terror_switch(session, /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen)
	TEST_ASSERT(istype(queen), "Тело участника - королева.")
	queen.forceMove(arena.zones["melee"]["spawn"])
	GLOB.unit_test_chat_capture = list()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/listener = new(arena.zones["melee"]["target"])
	TEST_ASSERT(arena.claim_target(listener, session), "Паук полигона встаёт в цели.")
	listener.toggle_ai(AI_OFF)
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/station = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight, run_loc_floor_bottom_left)
	station.toggle_ai(AI_OFF)
	TEST_ASSERT_NULL(station.training_origin, "Паук станции вне полигона.")
	TEST_ASSERT(antag_training_heard(queen, "[listener] has grown"), "Чутьё улья полигона сообщает о новом пауке полигона.")
	TEST_ASSERT(!antag_training_heard(station, "[listener] has grown"), "Паук станции не чует пауков полигона.")
	TEST_ASSERT(!antag_training_heard(queen, "[station] has grown"), "Участник не чует пауков станции.")

	added_players = list(queen, listener, station) - GLOB.player_list
	GLOB.player_list += added_players
	queen.say(":t hive-arena-probe")
	TEST_ASSERT(antag_training_heard(listener, "hive-arena-probe"), "Паук полигона слышит улей участника.")
	TEST_ASSERT(!antag_training_heard(station, "hive-arena-probe"), "Паук станции не слышит улей полигона.")
	station.say(":t hive-station-probe")
	TEST_ASSERT(antag_training_heard(station, "hive-station-probe"), "Улей станции работает.")
	TEST_ASSERT(!antag_training_heard(queen, "hive-station-probe") && !antag_training_heard(listener, "hive-station-probe"), "Пауки полигона не слышат улей станции.")
	GLOB.unit_test_chat_capture = null

	var/datum/tgui/console = allocate(/datum/tgui, queen, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Цель для укуса"))
	var/mob/living/carbon/human/dummy
	for(var/mob/living/carbon/human/candidate in arena.targets)
		if(candidate.stat != DEAD && candidate.training_owner?.resolve() == session)
			dummy = candidate
	TEST_ASSERT_NOTNULL(dummy, "Цель для укуса встаёт рядом.")
	TEST_ASSERT(get_dist(dummy, queen) <= ANTAG_TRAINING_SPAWN_RADIUS, "Цель для укуса рядом с королевой.")
	queen.add_enemy(dummy)
	queen.adjustBruteLoss(10)
	TEST_ASSERT(dummy in listener.enemies, "Месть королевы передаётся паукам полигона.")
	TEST_ASSERT(!(dummy in station.enemies), "Месть королевы полигона не доходит до пауков станции.")

	var/dead_before = GLOB.ts_count_dead
	var/death_last_before = GLOB.ts_death_last
	listener.death()
	queen.death()
	TEST_ASSERT_EQUAL(GLOB.ts_count_dead, dead_before, "Смерть пауков полигона не меняет счётчик смертей раунда.")
	TEST_ASSERT_EQUAL(GLOB.ts_death_last, death_last_before, "Смерть пауков полигона не сдвигает время последней смерти.")
	TEST_ASSERT(antag_training_wait_new_body(session, queen, "королева после смерти"), "После смерти появляется новая королева.")
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/revived = session.current_body
	TEST_ASSERT(istype(revived) && revived.stat == CONSCIOUS && revived.mind == session.avatar_mind, "Новая королева жива и с разумом участника.")
	TEST_ASSERT(abs(revived.health - revived.maxHealth) < 0.1, "Новая королева с полным здоровьем.")
	TEST_ASSERT_EQUAL(get_turf(revived), arena.entry_turf, "Королева после смерти появляется в центре.")
	station.death()
	TEST_ASSERT_EQUAL(GLOB.ts_count_dead, dead_before + 1, "Смерть паука станции считается как раньше.")

/datum/unit_test/antag_training_terror_spider_hive/Destroy()
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= added_players
	added_players.Cut()
	if(!isnull(saved_dead))
		GLOB.ts_count_dead = saved_dead
		GLOB.ts_death_last = saved_death_last
	return ..()

/// Паук оборачивает в кокон учебный труп рядом, кокон держит его в лимите, а тело другого участника кнопка «Wrap» не уносит.
/datum/unit_test/antag_training_terror_spider_cocoon/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/terror_spider)
	TEST_ASSERT(session.prepare(), "Полигон готовит паука.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/knight = session.current_body
	TEST_ASSERT(istype(knight), "По умолчанию тело - рыцарь.")
	knight.forceMove(arena.zones["melee"]["spawn"])

	var/datum/antag_training_session/other = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(other.prepare(arena), "Второй участник вошёл.")
	other.auto_recover = FALSE
	var/mob/living/carbon/human/other_body = other.current_body
	other_body.forceMove(get_step(knight, NORTH))
	other_body.death()
	knight.cocoon_target = other_body
	INVOKE_ASYNC(knight.wrap_action, TYPE_PROC_REF(/datum/action, Trigger))
	var/list/budget = new_wait_budget(10 SECONDS, "попытка кокона вокруг участника")
	while((knight.busy || knight.cocoon_target) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!knight.busy && !knight.cocoon_target, "Попытка кокона завершилась.")
	TEST_ASSERT(isturf(other_body.loc), "Тело другого участника в кокон не уносится.")
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, get_step(knight, SOUTH))
	other.avatar_mind.transfer_to(new_body)
	TEST_ASSERT(other.current_body == new_body && other.avatar == other_body, "Разум второго участника перешёл в другое тело, кукла осталась.")
	knight.cocoon_target = other_body
	INVOKE_ASYNC(knight.wrap_action, TYPE_PROC_REF(/datum/action, Trigger))
	budget = new_wait_budget(10 SECONDS, "попытка кокона вокруг оставленной куклы")
	while((knight.busy || knight.cocoon_target) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!knight.busy && !knight.cocoon_target, "Вторая попытка кокона завершилась.")
	TEST_ASSERT(isturf(other_body.loc), "Оставленная кукла другого участника в кокон не уносится.")

	var/datum/tgui/console = allocate(/datum/tgui, knight, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Труп для кокона"))
	var/mob/living/carbon/human/corpse
	for(var/mob/living/carbon/human/candidate in arena.targets)
		if(candidate.stat == DEAD)
			corpse = candidate
	TEST_ASSERT_NOTNULL(corpse, "Учебный труп лежит рядом.")
	knight.cocoon_target = corpse
	INVOKE_ASYNC(knight.wrap_action, TYPE_PROC_REF(/datum/action, Trigger))
	budget = new_wait_budget(10 SECONDS, "кокон вокруг трупа")
	while(!istype(corpse.loc, /obj/structure/spider/cocoon) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(istype(corpse.loc, /obj/structure/spider/cocoon), "Кнопка «Wrap» оборачивает труп в кокон.")
	TEST_ASSERT_EQUAL(knight.fed, 1, "Кокон с трупом кормит паука.")
	TEST_ASSERT(corpse in arena.targets, "Труп в коконе остаётся учебной целью.")
	qdel(corpse)
	TEST_ASSERT(!(corpse in arena.targets), "Удалённый из кокона труп снимается с учёта.")
	pass(view(0, run_loc_floor_bottom_left))
