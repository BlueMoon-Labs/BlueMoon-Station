/datum/unit_test/proc/antag_training_xeno_ability(mob/living/carbon/body, ability_type)
	for(var/obj/effect/proc_holder/alien/ability as anything in body.abilities)
		if(istype(ability, ability_type))
			return ability
	return null

/datum/unit_test/proc/antag_training_xeno_devour(mob/living/carbon/alien/humanoid/eater, mob/living/carbon/prey)
	eater.start_pulling(prey, GRAB_AGGRESSIVE, supress_message = TRUE)
	eater.setGrabState(GRAB_AGGRESSIVE)
	eater.a_intent = INTENT_GRAB
	INVOKE_ASYNC(eater, TYPE_PROC_REF(/mob/living, grabbedby), eater)
	var/list/budget = new_wait_budget(8 SECONDS, "[eater] глотает [prey]")
	while(prey.loc != eater && wait_budget_tick(budget))
		continue
	eater.stop_pulling()
	return prey.loc == eater

/// Королевские особи полигона и станции не мешают эволюции друг друга, улей и смерть королевы не выходят за полигон, эволюция сохраняет учебный датум.
/datum/unit_test/antag_training_xeno_hive
	var/list/added_players = list()
	var/list/keyed = list()

/datum/unit_test/antag_training_xeno_hive/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/xeno)
	TEST_ASSERT(session.prepare(), "Полигон готовит ксеноморфа.")
	var/datum/antag_training_program/creature/xeno/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/alien/humanoid/drone/drone = session.current_body
	TEST_ASSERT(istype(drone), "Каста по умолчанию - дрон.")
	var/datum/antagonist/xeno/training/role = program.role(session)
	TEST_ASSERT(istype(role) && role.training == session, "Дрон получает учебный датум сеанса.")
	TEST_ASSERT_NULL(role.get_team(), "Учебный ксеноморф не вступает в улей раунда.")
	for(var/option in program.options)
		TEST_ASSERT(length(program.option_hints[option]), "У кнопки «[option]» есть подсказка.")
	drone.forceMove(arena.zones["melee"]["spawn"])

	var/mob/living/carbon/alien/humanoid/royal/queen/station_queen = allocate(/mob/living/carbon/alien/humanoid/royal/queen, run_loc_floor_bottom_left)
	station_queen.key = "unit_test_station_queen"
	keyed += station_queen
	TEST_ASSERT_NULL(station_queen.training_origin, "Королева станции вне полигона.")
	TEST_ASSERT_EQUAL(get_alien_type(/mob/living/carbon/alien/humanoid/royal), station_queen, "Станция видит свою королеву как раньше.")
	TEST_ASSERT(!get_alien_type(/mob/living/carbon/alien/humanoid/royal, drone), "Улей полигона не видит королеву станции.")

	var/datum/tgui/console = allocate(/datum/tgui, drone, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Плазма до максимума"))
	var/obj/item/organ/alien/plasmavessel/vessel = drone.getorgan(/obj/item/organ/alien/plasmavessel)
	TEST_ASSERT_EQUAL(drone.getPlasma(), vessel.max_plasma, "Кнопка заполняет плазму до предела касты.")
	var/obj/effect/proc_holder/alien/evolve/evolve = antag_training_xeno_ability(drone, /obj/effect/proc_holder/alien/evolve)
	evolve.Trigger(drone)
	var/mob/living/carbon/alien/humanoid/royal/praetorian/praetorian = session.current_body
	TEST_ASSERT(istype(praetorian), "Дрон полигона становится преторианцем при живой королеве станции.")
	TEST_ASSERT(QDELETED(drone), "Тело дрона убрано эволюцией.")
	TEST_ASSERT_EQUAL(praetorian.mind, session.avatar_mind, "Разум участника в преторианце.")
	TEST_ASSERT_EQUAL(program.role(session), role, "Учебный датум переживает эволюцию.")
	TEST_ASSERT_EQUAL(praetorian.training_origin?.resolve(), arena, "Преторианец принадлежит полигону.")
	TEST_ASSERT_EQUAL(program.body_ref?.resolve(), praetorian, "Программа следит за телом после эволюции.")
	TEST_ASSERT(locate(/datum/action/antag_training_controls) in praetorian.actions, "Пульт переходит к преторианцу.")
	praetorian.key = "unit_test_training_praetorian"

	var/mob/living/carbon/alien/humanoid/drone/station_drone = allocate(/mob/living/carbon/alien/humanoid/drone, run_loc_floor_bottom_left)
	TEST_ASSERT(!get_alien_type(/mob/living/carbon/alien/humanoid/royal/praetorian, station_drone), "Станция не видит преторианца полигона.")
	TEST_ASSERT_EQUAL(get_alien_type(/mob/living/carbon/alien/humanoid/royal/praetorian, praetorian), praetorian, "Полигон видит своего преторианца.")
	praetorian.key = null

	var/mob/living/carbon/alien/larva/arena_larva = allocate(/mob/living/carbon/alien/larva, get_step(praetorian, EAST))
	TEST_ASSERT_EQUAL(arena_larva.training_origin?.resolve(), arena, "Вторая особь улья на полигоне.")
	added_players = list(praetorian, arena_larva, station_queen, station_drone) - GLOB.player_list
	GLOB.player_list += added_players
	GLOB.unit_test_chat_capture = list()
	praetorian.say(":a hive-arena-probe")
	TEST_ASSERT(antag_training_heard(arena_larva, "hive-arena-probe"), "Улей полигона слышит учебного ксеноморфа.")
	TEST_ASSERT(!antag_training_heard(station_drone, "hive-arena-probe"), "Ксеноморф станции не слышит улей полигона.")
	TEST_ASSERT(!antag_training_heard(station_queen, "hive-arena-probe"), "Королева станции не слышит улей полигона.")
	station_drone.say(":a hive-station-probe")
	TEST_ASSERT(antag_training_heard(station_queen, "hive-station-probe"), "Ксеноморфы станции слышат друг друга.")
	TEST_ASSERT(!antag_training_heard(praetorian, "hive-station-probe"), "Учебный ксеноморф не слышит улей станции.")

	var/obj/item/organ/alien/hivenode/station_node = station_drone.getorgan(/obj/item/organ/alien/hivenode)
	var/obj/item/organ/alien/hivenode/arena_node = arena_larva.getorgan(/obj/item/organ/alien/hivenode)
	station_queen.key = null
	station_queen.death()
	TEST_ASSERT(station_node.recent_queen_death, "Смерть королевы станции оглушает ксеноморфов станции.")
	TEST_ASSERT(!arena_node.recent_queen_death, "Смерть королевы станции не трогает улей полигона.")
	station_node.recent_queen_death = 0

	program.fill_plasma(praetorian)
	var/obj/effect/proc_holder/alien/royal/praetorian/evolve/royal_evolve = antag_training_xeno_ability(praetorian, /obj/effect/proc_holder/alien/royal/praetorian/evolve)
	royal_evolve.Trigger(praetorian)
	var/mob/living/carbon/alien/humanoid/royal/queen/queen = session.current_body
	TEST_ASSERT(istype(queen) && queen.mind == session.avatar_mind, "Преторианец полигона становится королевой.")
	TEST_ASSERT_EQUAL(program.role(session), role, "Учебный датум переживает вторую эволюцию.")
	queen.key = "unit_test_training_queen"
	keyed += queen
	TEST_ASSERT_EQUAL(get_alien_type(/mob/living/carbon/alien/humanoid/royal, queen), queen, "Улей полигона видит свою живую королеву.")

	program.fill_plasma(station_drone)
	var/obj/effect/proc_holder/alien/evolve/station_evolve = antag_training_xeno_ability(station_drone, /obj/effect/proc_holder/alien/evolve)
	station_evolve.Trigger(station_drone)
	var/mob/living/carbon/alien/humanoid/royal/praetorian/station_praetorian = locate() in run_loc_floor_bottom_left
	allocated += station_praetorian
	TEST_ASSERT(QDELETED(station_drone) && station_praetorian, "Дрон станции эволюционирует при живой королеве полигона.")
	var/obj/item/organ/alien/hivenode/station_praetorian_node = station_praetorian.getorgan(/obj/item/organ/alien/hivenode)

	queen.key = null
	queen.death()
	TEST_ASSERT(arena_node.recent_queen_death, "Смерть королевы полигона оглушает её улей.")
	TEST_ASSERT(!station_praetorian_node.recent_queen_death, "Смерть королевы полигона не трогает ксеноморфов станции.")

/datum/unit_test/antag_training_xeno_hive/Destroy()
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= added_players
	added_players.Cut()
	for(var/mob/keyed_mob as anything in keyed)
		if(!QDELETED(keyed_mob))
			keyed_mob.key = null
	keyed.Cut()
	return ..()

/// Яйцо королевы, лицехват, эмбрион в учебной цели и личинка из неё идут в лимит целей, а личинка вылезает без опроса призраков.
/datum/unit_test/antag_training_xeno_brood
	var/list/added_players = list()

/datum/unit_test/antag_training_xeno_brood/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/xeno)
	TEST_ASSERT(session.prepare(), "Полигон готовит ксеноморфа.")
	var/datum/antag_training_program/creature/xeno/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	var/datum/tgui/console = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option(/mob/living/carbon/alien/humanoid/royal/queen)))
	var/mob/living/carbon/alien/humanoid/royal/queen/queen = session.current_body
	TEST_ASSERT(istype(queen) && queen.mind == session.avatar_mind, "Пульт меняет касту на королеву.")
	queen.forceMove(arena.zones["melee"]["spawn"])
	console = allocate(/datum/tgui, queen, session, "AntagTraining")

	var/obj/effect/proc_holder/alien/lay_egg/lay_egg = antag_training_xeno_ability(queen, /obj/effect/proc_holder/alien/lay_egg)
	var/plasma_before = queen.getPlasma()
	lay_egg.Trigger(queen)
	var/obj/structure/alien/egg/egg = locate() in get_turf(queen)
	TEST_ASSERT_NOTNULL(egg, "Королева откладывает яйцо.")
	TEST_ASSERT_EQUAL(queen.getPlasma(), plasma_before - lay_egg.plasma_cost, "Яйцо стоит плазмы.")
	var/obj/item/clothing/mask/facehugger/hugger = egg.child
	TEST_ASSERT((egg in arena.targets) && (hugger in arena.targets), "Яйцо и лицехват в нём - в лимите целей.")
	TEST_ASSERT(egg.training_owner?.resolve() == session && hugger.training_owner?.resolve() == session, "Яйцо и лицехват принадлежат участнику.")

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для хаггера"))
	var/mob/living/carbon/human/host
	for(var/mob/living/carbon/human/candidate in arena.targets)
		host = candidate
	TEST_ASSERT(host && host.training_owner?.resolve() == session, "Цель для хаггера создана для участника.")
	TEST_ASSERT(get_dist(host, egg) <= 1, "Цель встаёт рядом с королевой.")

	egg.Grow()
	var/turf/beside = get_turf(host)
	host.forceMove(get_step(get_step(beside, get_dir(egg, beside)), get_dir(egg, beside)))
	host.forceMove(beside)
	var/list/budget = new_wait_budget(25 SECONDS, "лицехват подсаживает эмбрион")
	while(!host.getorgan(/obj/item/organ/body_egg/alien_embryo) && wait_budget_tick(budget))
		continue
	var/obj/item/organ/body_egg/alien_embryo/embryo = host.getorgan(/obj/item/organ/body_egg/alien_embryo)
	TEST_ASSERT_NOTNULL(embryo, "Лицехват из созревшего яйца подсаживает эмбрион цели.")
	TEST_ASSERT_EQUAL(hugger.stat, DEAD, "Лицехват гибнет после заражения.")
	TEST_ASSERT((embryo in arena.targets) && embryo.training_owner?.resolve() == session, "Эмбрион в лимите целей участника.")

	var/targets_before = length(arena.targets)
	embryo.stage = 5
	for(var/attempt in 1 to 50)
		if(QDELETED(embryo))
			break
		embryo.egg_process()
	var/mob/living/carbon/alien/larva/larva = locate() in get_turf(host)
	TEST_ASSERT(QDELETED(embryo), "Созревший эмбрион выходит из цели.")
	TEST_ASSERT_NOTNULL(larva, "Из цели вылезает личинка без опроса призраков.")
	TEST_ASSERT(!larva.key && !larva.mind, "Личинка полигона без игрока.")
	TEST_ASSERT((larva in arena.targets) && larva.training_owner?.resolve() == session, "Личинка заменяет эмбрион в лимите целей.")
	TEST_ASSERT_EQUAL(length(arena.targets), targets_before, "Выход личинки не меняет число целей.")
	TEST_ASSERT_EQUAL(host.stat, DEAD, "Цель погибает, когда из неё вырывается личинка.")

	var/datum/antag_training_session/guest = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(guest.prepare(arena), "Второй участник входит на полигон.")
	var/mob/living/carbon/human/guest_body = guest.current_body
	guest_body.forceMove(get_turf(host))
	TEST_ASSERT(!antag_training_xeno_devour(queen, guest_body), "Королева не глотает тело другого участника.")
	TEST_ASSERT(antag_training_xeno_devour(queen, host), "Королева глотает учебную цель.")
	guest_body.forceMove(arena.zones["melee"]["target"])
	var/obj/item/organ/body_egg/alien_embryo/transplanted = new(guest_body)
	transplanted.stage = 5
	for(var/attempt in 1 to 50)
		if(QDELETED(transplanted))
			break
		transplanted.egg_process()
	TEST_ASSERT(QDELETED(transplanted), "Созревший эмбрион в участнике выходит.")
	TEST_ASSERT(guest_body.stat != DEAD && !(locate(/mob/living/carbon/alien/larva) in get_turf(guest_body)), "Эмбрион в участнике рассасывается без личинки и не убивает его.")

	var/turf/spot = arena.zones["melee"]["target"]
	while(arena.has_target_room())
		TEST_ASSERT(arena.claim_target(new /obj/item/pen(spot), session), "Свободное место в лимите принимает цель.")
	for(var/turf/open/free in orange(1, queen))
		if(!(locate(/obj/structure/alien/egg) in free) && !free.is_blocked_turf())
			queen.forceMove(free)
			break
	TEST_ASSERT_NULL(locate(/obj/structure/alien/egg) in get_turf(queen), "Королева отошла от яйца.")
	program.fill_plasma(queen)
	plasma_before = queen.getPlasma()
	added_players = list(queen) - GLOB.player_list
	GLOB.player_list += added_players
	GLOB.unit_test_chat_capture = list()
	lay_egg.Trigger(queen)
	TEST_ASSERT_NULL(locate(/obj/structure/alien/egg) in get_turf(queen), "Сверх лимита яйцо не откладывается.")
	TEST_ASSERT_EQUAL(queen.getPlasma(), plasma_before, "Отказ не тратит плазму.")
	TEST_ASSERT(antag_training_heard(queen, "это предел"), "Отказ объясняет лимит целей.")

	antag_training_console_act(session, console, "program_option", list("option" = "Личинка выросла"))
	TEST_ASSERT(antag_training_heard(queen, "Кнопка для личинки"), "Рост личинки не действует на королеву.")
	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option(/mob/living/carbon/alien/larva)))
	var/mob/living/carbon/alien/larva/own_larva = session.current_body
	TEST_ASSERT(istype(own_larva) && own_larva.mind == session.avatar_mind, "Пульт меняет касту на личинку.")
	TEST_ASSERT(QDELETED(queen), "Прежнее тело королевы убрано.")
	console = allocate(/datum/tgui, own_larva, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Личинка выросла"))
	TEST_ASSERT_EQUAL(own_larva.amount_grown, own_larva.max_grown, "Кнопка выращивает личинку.")
	pass(view(0, run_loc_floor_bottom_left))

/datum/unit_test/antag_training_xeno_brood/Destroy()
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= added_players
	added_players.Cut()
	return ..()

/// «Улей»: трава и стена из смолы у дрона и эмбрион от лицехвата из открытого яйца засчитываются по шагам и уходят с прогоном; каста без смоляной железы упражнение не начинает, узел, посаженный до прогона, не засчитан, смерть цели до заражения проваливает упражнение.
/datum/unit_test/antag_training_xeno_exercise/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/xeno)
	TEST_ASSERT(session.prepare(), "Полигон готовит ксеноморфа.")
	var/datum/antag_training_program/creature/xeno/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antagonist/xeno/training/role = program.role(session)
	TEST_ASSERT(findtext(role.briefing(), "Улей"), "Приветствие называет упражнение.")
	var/datum/tgui/console = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, console, "move", list("zone" = "laboratory"))
	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option(/mob/living/carbon/alien/humanoid/hunter)))
	var/mob/living/carbon/alien/humanoid/hunter/hunter = session.current_body
	TEST_ASSERT(istype(hunter) && arena.match_zone(hunter) == "laboratory", "Охотник стоит в лаборатории.")
	console = allocate(/datum/tgui, hunter, session, "AntagTraining")
	TEST_ASSERT_NULL(start_training_drill(session, console, "xeno_hive"), "Каста без смоляной железы упражнение не начинает.")

	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option(/mob/living/carbon/alien/humanoid/drone)))
	var/mob/living/carbon/alien/humanoid/drone/drone = session.current_body
	TEST_ASSERT(istype(drone) && arena.match_zone(drone) == "laboratory", "Дрон стоит в лаборатории.")
	console = allocate(/datum/tgui, drone, session, "AntagTraining")
	var/datum/antag_training_exercise_run/run = start_training_drill(session, console, "xeno_hive")
	TEST_ASSERT(run && !run.ended, "Упражнение улья стартует в лаборатории.")
	var/mob/living/carbon/human/host = run.find_prop(/mob/living/carbon/human)
	var/obj/structure/alien/egg/egg = run.find_prop(/obj/structure/alien/egg)
	TEST_ASSERT(host?.mind && (host.mind in arena.target_minds), "Цель упражнения - учебный манекен.")
	TEST_ASSERT(egg?.child && get_dist(egg, host) == 1, "Созревшее яйцо стоит вплотную к цели.")

	program.fill_plasma(drone)
	var/obj/effect/proc_holder/alien/plant/plant = antag_training_xeno_ability(drone, /obj/effect/proc_holder/alien/plant)
	plant.Trigger(drone)
	TEST_ASSERT_NOTNULL(locate(/obj/structure/alien/weeds/node) in get_turf(drone), "Под дроном вырос узел травы.")
	TEST_ASSERT(wait_for_drill_step(run, 2), "Трава засчитана: [run.result_text]")
	// «Secrete Resin» выбирает постройку окном input() клиента; выбранная стена встаёт так же, как в fire().
	new /obj/structure/alien/resin/membrane(drone.loc)
	TEST_ASSERT(!wait_for_drill_step(run, 3, 2 SECONDS), "Мембрана вместо стены не засчитана.")
	for(var/turf/open/floor/spot in orange(1, drone))
		if(!spot.is_blocked_turf(exclude_mobs = FALSE) && !(locate(/obj/structure/alien/resin) in spot) && !(locate(/obj/structure/alien/egg) in spot))
			drone.forceMove(spot)
			break
	TEST_ASSERT_NULL(locate(/obj/structure/alien/resin) in get_turf(drone), "Дрон отошёл на свободную клетку.")
	new /obj/structure/alien/resin/wall(drone.loc)
	TEST_ASSERT(wait_for_drill_step(run, 3), "Стена из смолы засчитана: [run.result_text]")

	var/turf/beside
	for(var/turf/open/spot in orange(1, egg))
		if(spot != get_turf(host) && !spot.is_blocked_turf(exclude_mobs = FALSE))
			beside = spot
			break
	TEST_ASSERT_NOTNULL(beside, "Возле яйца есть свободная клетка.")
	drone.forceMove(beside)
	egg.attack_alien(drone)
	TEST_ASSERT(wait_for_drill_step(run, 4, 30 SECONDS) && run.ended && run.success, "Эмбрион в цели завершает упражнение: [run.result_text]")
	var/obj/item/organ/body_egg/alien_embryo/embryo = host.getorgan(/obj/item/organ/body_egg/alien_embryo)
	TEST_ASSERT(embryo && (embryo in arena.targets), "Лицехват подсадил цели эмбрион в лимите целей.")

	var/obj/structure/alien/weeds/node/old_node = run.find_prop(/obj/structure/alien/weeds/node)
	var/obj/structure/alien/resin/wall/old_wall = run.find_prop(/obj/structure/alien/resin/wall)
	TEST_ASSERT(old_node && old_wall, "Засчитанные узел травы и стена уходят вместе с прогоном.")
	var/turf/old_spot = get_turf(old_node)
	var/list/old_weeds = list()
	// Рост травы - expand() раз в 15-20 с; здесь трава вокруг узла ставится сразу.
	for(var/turf/open/floor/spot in orange(1, old_spot))
		if(!(locate(/obj/structure/alien) in spot))
			old_weeds += new /obj/structure/alien/weeds(spot)
	TEST_ASSERT(length(old_weeds), "Трава расползлась от узла.")
	var/turf/open/floor/leftover_spot
	for(var/turf/open/floor/spot in range(10, old_spot))
		if(get_dist(spot, old_spot) >= old_node.node_range + 3 && arena.inside_bounds(spot, arena.zones["laboratory"]["bounds"]) && !spot.is_blocked_turf(exclude_mobs = FALSE) && !(locate(/obj/structure/alien) in spot))
			leftover_spot = spot
			break
	TEST_ASSERT_NOTNULL(leftover_spot, "В лаборатории есть место вдали от узла.")
	drone.forceMove(leftover_spot)
	program.fill_plasma(drone)
	plant.Trigger(drone)
	var/obj/structure/alien/weeds/node/leftover = locate() in leftover_spot
	TEST_ASSERT_NOTNULL(leftover, "Дрон посадил узел между прогонами.")

	run = start_training_drill(session, console, "xeno_hive")
	TEST_ASSERT(run && !run.ended, "Упражнение начинается заново.")
	TEST_ASSERT(QDELETED(old_node) && QDELETED(old_wall), "Узел и стена прошлого прогона убраны.")
	for(var/obj/structure/alien/weeds/weed as anything in old_weeds)
		TEST_ASSERT(QDELETED(weed), "Трава от узла прошлого прогона убрана.")
	TEST_ASSERT(!QDELETED(leftover) && get_turf(drone) == leftover_spot, "Дрон стоит на узле, посаженном до прогона.")
	TEST_ASSERT(!wait_for_drill_step(run, 2, 2 SECONDS), "Узел, посаженный до прогона, не засчитан.")
	host = run.find_prop(/mob/living/carbon/human)
	host.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "раньше, чем лицехват"), "Смерть цели до заражения проваливает упражнение: [run.result_text]")
