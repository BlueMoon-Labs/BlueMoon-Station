// ===== Миграция легаси-кластеров hostile-мобов на адаптер-контроллер =====
//
// Проверяют: goose (базовый retaliate-профиль + случайная ярость из легаси
// handle_automated_movement), snake (охота на мышей поверх retaliate-гейта),
// tentacles (неподвижный захватчик без преследования), крысиное королевство
// (король с королевскими делами + крысы на службе), gremlin (порча техники,
// поводок погони, вент-брождение), minebot (переключаемые режимы сбор/бой),
// headcrab (прыжок-захват и зомби-форма), wizard (кастер-скирмишер
// с делегацией AutomatedCast), statue (плачущий ангел: замирание под взглядами),
// insane clown (телепорт-сталкер с закреплённой жертвой), floor cluwne
// (сценарный сталкер с закреплённой жертвой), eldritch demons (пин
// постоянного исключения: гост-вессели без AI), AI-сварнеры (боевой контур
// делегацией + фуражирский цикл + легаси-паузы StartAction через мост),
// giant spiders (перебежки + цикл няньки), bees (опыление/улей),
// morph (маскировка/засада), SPLURT-оборотни и дефклавы (реактивный чардж
// из bullet_act + комбо-атаки делегацией), капсульные петы (приказы
// хозяина через Hear/new_order).

///Проходимый станционный турф для сценариев, требующих is_station_level
/datum/unit_test/proc/find_walkable_station_turf()
	for(var/area_name in GLOB.teleportlocs)
		var/area/candidate_area = GLOB.teleportlocs[area_name]
		if(istype(candidate_area, /area/space))
			continue
		for(var/turf/open/area_turf in get_area_turfs(candidate_area.type))
			if(!is_station_level(area_turf.z) || area_turf.is_blocked_turf())
				continue
			return area_turf
	return null

///Гусь мирный, пока цел; случайная ярость поднимает штатную машину обид
/datum/unit_test/ai_goose_random_rage/Run()
	var/mob/living/simple_animal/hostile/retaliate/goose/loose = allocate(/mob/living/simple_animal/hostile/retaliate/goose, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))

	var/datum/ai_controller/hostile_adapter/controller = loose.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/melee_chaser/goose), "A goose must migrate onto its adapter profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy/retaliate/goose, "A goose must keep the retaliate enemies gate with snack hunting")

	//мирный: без обид штатный поиск целей никого не берёт
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "A peaceful goose must not acquire targets")

	//гейт random_retaliate: выключен - сабтри молчит даже при форс-вероятности
	var/datum/ai_planning_subtree/goose_random_rage/rage_tree = GLOB.ai_subtrees[/datum/ai_planning_subtree/goose_random_rage]
	loose.random_retaliate = FALSE
	rage_tree.SelectBehaviors(controller, 1000) //SPT_PROB с таким delta_time = гарантированный ролл
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/goose_random_rage) in controller.current_behaviors), "random_retaliate = FALSE must silence the rage subtree")

	//включен: поведение ярости встаёт в план
	loose.random_retaliate = TRUE
	rage_tree.SelectBehaviors(controller, 1000)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/goose_random_rage) in controller.current_behaviors, "The rage subtree must queue its behavior")
	controller.CancelActions()

	//ярость: прохожий попадает в обиды, дальше работает штатная машина retaliate
	var/datum/ai_behavior/goose_random_rage/rage = GET_AI_BEHAVIOR(/datum/ai_behavior/goose_random_rage)
	rage.perform(0.5, controller)
	TEST_ASSERT(bystander in loose.enemies, "Random rage must add the nearby bystander to the enemies list")
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], bystander, "An enraged goose must hunt its victim through the standard grudge machinery")
	TEST_ASSERT_EQUAL(loose.target, bystander, "The legacy pawn.target must mirror the controller target")

///Змея охотится на мышей без обид, к остальным - retaliate; мышь важнее обидчика
/datum/unit_test/ai_snake_hunts_small_prey/Run()
	var/mob/living/simple_animal/hostile/retaliate/poison/snake/noodle = allocate(/mob/living/simple_animal/hostile/retaliate/poison/snake, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))

	var/datum/ai_controller/hostile_adapter/controller = noodle.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/melee_chaser/snake), "A snake must migrate onto its adapter profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy/retaliate/small_prey, "A snake must use the small-prey strategy")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGET_SCORER], /datum/target_scorer/small_prey_first, "A snake must rank small prey first")

	//незнакомый человек - не цель: retaliate-гейт обидчиков сохранён
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "A stranger must not become a snake target without a grudge")

	//мышь - цель безо всяких обид (легаси-охота на мелочь)
	var/mob/living/simple_animal/mouse/lunch = allocate(/mob/living/simple_animal/mouse, get_step(run_loc_floor_bottom_left, EAST))
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], lunch, "A mouse must be hunted with no grudges at all")

	//приоритет легаси ListTargets: пока видна мышь, даже обидчик подождёт
	noodle.RetaliateAgainst(bystander)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], bystander, "Sanity: retaliation must focus the attacker first")
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], lunch, "A visible mouse must outrank even the snake's attacker")

	//пасть: мышь съедается легаси AttackingTarget через делегацию
	var/datum/ai_behavior/hostile_melee_attack/fangs = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	fangs.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(QDELETED(lunch), "The snake must gulp the mouse through its legacy AttackingTarget")

	//мышей не осталось - обычный retaliate: обидчик снова цель
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], bystander, "With no mice left the retaliate grudge target must win")

///Тентакли неподвижны: цель не преследуется, вплотную - легаси-захват
/datum/unit_test/ai_tentacles_stationary_grab/Run()
	var/mob/living/simple_animal/hostile/tentacles/lewd = allocate(/mob/living/simple_animal/hostile/tentacles, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))

	var/datum/ai_controller/hostile_adapter/controller = lewd.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/stationary_grappler), "Tentacles must migrate onto the stationary grappler profile")
	TEST_ASSERT(!lewd.can_ai_controller_move(), "Tentacles must refuse controller movement entirely")

	//преф-гейт CanAttack работает через делегацию: манекен без клиента - не цель
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(!strategy.can_attack(lewd, prey), "The consent pref gate must keep working through CanAttack delegation")

	//захват: жертва вплотную схвачена легаси AttackingTarget без единого шага
	controller.set_blackboard_key(BB_AI_TARGETING_STRATEGY, /datum/targeting_strategy/anything) //обойти преф-гейт для манекена
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	var/datum/ai_behavior/hostile_melee_attack/stationary/graspers = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack/stationary)
	graspers.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(prey.pulledby, lewd, "An adjacent victim must be grabbed through the legacy AttackingTarget")
	TEST_ASSERT_EQUAL(lewd.grab_state, GRAB_NECK, "The legacy grab must come with the instant neck grip")

	//цель на дистанции: пережидаем на месте, никаких мув-лупов и точек движения
	var/turf/far_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	prey.forceMove(far_turf)
	var/verdict = graspers.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(verdict & AI_BEHAVIOR_FAILED, "An out-of-reach victim must simply be waited out")

	//полный цикл планирования: профиль ставит только неподвижную милишку
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	drive_ai_planning(controller)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack/stationary) in controller.current_behaviors, "The stationary profile must plan its no-move melee")
	TEST_ASSERT_NULL(controller.current_movement_target, "The stationary behavior must never set a movement target")
	var/datum/move_loop/loop = lewd.move_packet ? lewd.move_packet.existing_loops[SSai_movement] : null
	TEST_ASSERT_NULL(loop, "Tentacles must never register an AI movement loop")
	controller.CancelActions()

// ===== Крысиное королевство: regalrat + rat =====

///Король: королевский профиль, вражда к чужим королям/крысам через делегацию
///CanAttack, королевские дела (riot/coffer) сабтри с легаси-вероятностями
/datum/unit_test/ai_regalrat_royal_court/Run()
	var/mob/living/simple_animal/hostile/regalrat/king = allocate(/mob/living/simple_animal/hostile/regalrat, run_loc_floor_bottom_left)
	var/turf/rival_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/regalrat/rival = allocate(/mob/living/simple_animal/hostile/regalrat, rival_turf)
	var/mob/living/simple_animal/hostile/rat/subject = allocate(/mob/living/simple_animal/hostile/rat, get_step(run_loc_floor_bottom_left, NORTH))

	var/datum/ai_controller/hostile_adapter/melee_chaser/regalrat/controller = king.ai_controller
	TEST_ASSERT(istype(controller), "A regal rat must migrate onto its royal profile")

	//вражда: чужой король - всегда цель, верная крыса - никогда (делегация CanAttack)
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(strategy.can_attack(king, rival), "A rival king must be a valid target through CanAttack delegation")
	TEST_ASSERT(!strategy.can_attack(king, subject), "A loyal same-faction rat must never be a royal target")
	var/mob/living/simple_animal/hostile/rat/foreign = allocate(/mob/living/simple_animal/hostile/rat, get_step(run_loc_floor_bottom_left, NORTHEAST))
	foreign.faction = list("blackrat")
	TEST_ASSERT(strategy.can_attack(king, foreign), "A rat serving another king must be a valid royal target")

	//поиск целей: штатный finder приобретает врага короны, несмотря на общую фракцию
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/atom/royal_pick = controller.blackboard[BB_AI_CURRENT_TARGET]
	TEST_ASSERT(royal_pick == rival || royal_pick == foreign, "The royal finder must acquire an enemy of the crown")
	TEST_ASSERT_EQUAL(king.target, royal_pick, "The royal target must mirror into the legacy pawn target")
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)

	//королевские дела роллятся вероятностью и в бою (легаси-паритет handle_automated_action)
	var/datum/ai_planning_subtree/regalrat_royal_duties/duties = GLOB.ai_subtrees[/datum/ai_planning_subtree/regalrat_royal_duties]
	duties.SelectBehaviors(controller, 1000) //SPT_PROB с таким delta_time = гарантированный ролл
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/regalrat_royal_duty/riot) in controller.current_behaviors, "A forced roll must queue the Raise Army duty")
	controller.CancelActions()

	//риот: мышь превращается в крысу королевской фракции легаси-действием
	var/turf/mouse_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/mob/living/simple_animal/mouse/minion = allocate(/mob/living/simple_animal/mouse, mouse_turf)
	var/datum/ai_behavior/regalrat_royal_duty/riot_duty = GET_AI_BEHAVIOR(/datum/ai_behavior/regalrat_royal_duty/riot)
	riot_duty.perform(0.5, controller)
	TEST_ASSERT(QDELETED(minion), "Raise Army must mutate the nearby mouse")
	var/mob/living/simple_animal/hostile/rat/recruit = locate() in mouse_turf
	TEST_ASSERT_NOTNULL(recruit, "The mutated mouse must leave a rat behind")
	TEST_ASSERT(king.faction_check_mob(recruit, TRUE), "The recruit must serve the king's own faction")
	TEST_ASSERT(king.riot.next_use_time > world.time, "Raise Army must start its legacy action cooldown")
	qdel(recruit)

	//коффер: сокровищница пополняется, легаси-кулдаун взводится
	var/datum/ai_behavior/regalrat_royal_duty/coffer_duty = GET_AI_BEHAVIOR(/datum/ai_behavior/regalrat_royal_duty/coffer)
	coffer_duty.perform(0.5, controller)
	TEST_ASSERT(king.coffer.next_use_time > world.time, "Fill Coffers must start its legacy action cooldown")

///Крыса стягивается на цель своего короля наводкой-контактом, а не GPS-целью
/datum/unit_test/ai_rat_serves_king/Run()
	var/mob/living/simple_animal/hostile/regalrat/king = allocate(/mob/living/simple_animal/hostile/regalrat, run_loc_floor_bottom_left)
	var/turf/soldier_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/rat/soldier = allocate(/mob/living/simple_animal/hostile/rat, soldier_turf)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)

	var/datum/ai_controller/hostile_adapter/melee_chaser/rat/controller = soldier.ai_controller
	TEST_ASSERT(istype(controller), "A rat must migrate onto its subject profile")

	//без королевской цели служить нечему
	var/datum/ai_behavior/rat_heed_the_king/heed = GET_AI_BEHAVIOR(/datum/ai_behavior/rat_heed_the_king)
	var/verdict = heed.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_FAILED, "With no royal target there must be nothing to heed")

	//чужому королю не служим
	king.GiveTarget(prey)
	soldier.faction = list("blackrat")
	verdict = heed.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_FAILED, "A rat of another king must ignore the royal order")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CONTACT_TARGET), "A foreign rat must not receive the royal contact")

	//верная крыса получает НАВОДКУ (точку и приметы), не сам атом
	soldier.faction = list("rat")
	verdict = heed.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "A loyal rat must heed the king's order")
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "The order must not hand the live atom as a target")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CONTACT_TARGET], prey, "The royal target must arrive as a combat contact")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_KNOWN_POS], prey_turf, "The contact must carry the confirmed point")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_SEARCH, "The ordered rat must go investigate the point")

	//сабтри: занятая боем крыса приказы не переспрашивает
	var/datum/ai_planning_subtree/rat_serve_king/service = GLOB.ai_subtrees[/datum/ai_planning_subtree/rat_serve_king]
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.CancelActions()
	service.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!(heed in controller.current_behaviors), "A rat with its own target must not poll for royal orders")

///Крыса грызёт кабели легаси-процем: безопасная грызня рвёт провод, удар током убивает
/datum/unit_test/ai_rat_gnaws_cables/Run()
	var/mob/living/simple_animal/hostile/rat/vermin = allocate(/mob/living/simple_animal/hostile/rat, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/melee_chaser/rat/controller = vermin.ai_controller
	TEST_ASSERT(istype(controller), "A rat must migrate onto its subject profile")

	//план: грызня ставится с форс-вероятностью
	var/datum/ai_planning_subtree/rat_gnaw_cables/gnawing = GLOB.ai_subtrees[/datum/ai_planning_subtree/rat_gnaw_cables]
	gnawing.SelectBehaviors(controller, 1000) //SPT_PROB с таким delta_time = гарантированный ролл
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/rat_gnaw_cables) in controller.current_behaviors, "A forced roll must queue the cable gnawing")
	controller.CancelActions()

	//прикрытый пол и обесточенный кабель неинтересны
	var/turf/open/floor/floor = run_loc_floor_bottom_left
	TEST_ASSERT(istype(floor), "Sanity: the test room floor must be a real floor")
	floor.intact = FALSE
	var/obj/structure/cable/dead_wire = allocate(/obj/structure/cable, floor)
	TEST_ASSERT(!vermin.try_chew_cables(FALSE), "An unpowered cable must not be chewed")
	TEST_ASSERT(!QDELETED(dead_wire), "An unpowered cable must survive the gnawing")

	//запитанный кабель: безопасная грызня рвёт провод, крыса цела
	if(!dead_wire.powernet)
		var/datum/powernet/isolated_net = new()
		isolated_net.add_cable(dead_wire)
	dead_wire.powernet.avail = 1000
	TEST_ASSERT(vermin.try_chew_cables(FALSE), "A powered cable must be chewed through")
	TEST_ASSERT(QDELETED(dead_wire), "The safe gnaw must deconstruct the cable")
	TEST_ASSERT(vermin.stat != DEAD, "The safe gnaw must leave the rat alive")

	//разряд: та же грызня с шок-роллом убивает крысу вместе с кабелем
	var/obj/structure/cable/live_wire = allocate(/obj/structure/cable, floor)
	if(!live_wire.powernet)
		var/datum/powernet/second_net = new()
		second_net.add_cable(live_wire)
	live_wire.powernet.avail = 1000
	TEST_ASSERT(vermin.try_chew_cables(TRUE), "A powered cable must be chewed even on the shock roll")
	TEST_ASSERT(QDELETED(live_wire), "The shock gnaw must still deconstruct the cable")
	TEST_ASSERT_EQUAL(vermin.stat, DEAD, "The shock roll must toast the rat")

// ===== Gremlin: порча техники, поводок погони, вент-брождение =====

///Гремлин: vent_hunter-база, техника/еда как цели через search_objects-путь,
///мобы игнорируются полностью (search_objects = 3 в легаси CanAttack)
/datum/unit_test/ai_gremlin_saboteur/Run()
	var/mob/living/simple_animal/hostile/gremlin/imp = allocate(/mob/living/simple_animal/hostile/gremlin, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/vent_hunter/gremlin/controller = imp.ai_controller
	TEST_ASSERT(istype(controller), "A gremlin must migrate onto its saboteur profile")

	//мобы - не цели вовсе: даже незнакомый человек прозрачен для гремлина
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(!strategy.can_attack(imp, bystander), "A gremlin must completely ignore mobs through CanAttack delegation")

	//еда находится search_objects-путём штатного finder'а
	var/turf/snack_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/item/reagent_containers/food/snacks/cheesewedge/snack = allocate(/obj/item/reagent_containers/food/snacks/cheesewedge, snack_turf)
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], snack, "The finder must acquire wanted food through the search_objects path")

	//вплотную легаси AttackingTarget пожирает еду делегацией
	imp.forceMove(get_step(snack_turf, WEST))
	var/datum/ai_behavior/hostile_melee_attack/jaws = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	jaws.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(QDELETED(snack), "An adjacent gremlin must devour the food through its legacy AttackingTarget")
	TEST_ASSERT(imp.next_eat > world.time, "Eating must arm the legacy hunger cooldown")

///Поводок погони: цель старше легаси-лимита бросается с коротким бэкоффом
/datum/unit_test/ai_gremlin_chase_leash/Run()
	var/mob/living/simple_animal/hostile/gremlin/imp = allocate(/mob/living/simple_animal/hostile/gremlin, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/vent_hunter/gremlin/controller = imp.ai_controller
	var/turf/snack_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/item/reagent_containers/food/snacks/cheesewedge/snack = allocate(/obj/item/reagent_containers/food/snacks/cheesewedge, snack_turf)

	var/datum/ai_planning_subtree/gremlin_chase_leash/leash = GLOB.ai_subtrees[/datum/ai_planning_subtree/gremlin_chase_leash]
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, snack)
	controller.blackboard[BB_AI_TARGET_ACQUIRED_AT] = world.time
	leash.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "A fresh chase must not be abandoned")

	controller.blackboard[BB_AI_TARGET_ACQUIRED_AT] = world.time - leash.max_chase_time - 1
	leash.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "An overdue chase must be abandoned like the legacy time_chasing_target")
	TEST_ASSERT(controller.blackboard[BB_AI_ROUTE_RETRY_AT] > world.time, "Abandoning a chase must arm a short retry backoff")

///Вент-брождение: легаси-кулдаун 90с, случайный маршрут, подход и вход в вент
/datum/unit_test/ai_gremlin_vent_wander/Run()
	var/mob/living/simple_animal/hostile/gremlin/imp = allocate(/mob/living/simple_animal/hostile/gremlin, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/vent_hunter/gremlin/controller = imp.ai_controller
	var/datum/ai_planning_subtree/gremlin_vent_wander/wandering = GLOB.ai_subtrees[/datum/ai_planning_subtree/gremlin_vent_wander]

	//легаси-кулдаун между кроулами держит даже форс-ролл
	imp.min_next_vent = world.time + 1 MINUTES
	wandering.SelectBehaviors(controller, 1000)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/gremlin_pick_vent_route) in controller.current_behaviors), "The legacy vent cooldown must gate wandering")

	//кулдаун истёк - форс-ролл ставит выбор маршрута
	imp.min_next_vent = 0
	wandering.SelectBehaviors(controller, 1000)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/gremlin_pick_vent_route) in controller.current_behaviors, "An expired cooldown must queue vent route picking")
	controller.CancelActions()

	//вентов рядом нет / вент заварен / вент без сети - выбор честно проваливается
	var/datum/ai_behavior/gremlin_pick_vent_route/scout = GET_AI_BEHAVIOR(/datum/ai_behavior/gremlin_pick_vent_route)
	var/verdict = scout.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_FAILED, "With no vents around, route picking must simply fail")
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = allocate(/obj/machinery/atmospherics/components/unary/vent_pump, get_step(run_loc_floor_bottom_left, EAST))
	vent.welded = TRUE
	verdict = scout.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_FAILED, "A welded vent must not open a wander route")
	vent.welded = FALSE
	verdict = scout.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_FAILED, "A vent with no pipe network must not open a wander route")

	//готовый маршрут: сперва подход к вентшахте, на её тайле - вход
	controller.set_blackboard_key(BB_AI_ENTRY_VENT, vent)
	wandering.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/travel_towards) in controller.current_behaviors, "A distant armed route must walk the gremlin to its entry vent")
	controller.CancelActions()
	imp.forceMove(get_turf(vent))
	controller.set_blackboard_key(BB_AI_ENTRY_VENT, vent)
	wandering.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/enter_vent) in controller.current_behaviors, "On the entry tile the gremlin must climb into the vent")
	controller.CancelActions()

// ===== Minebot: переключаемые режимы сбор/бой =====

///Пробник дальнего боя майнбота: считает вызовы OpenFire без реального выстрела
/mob/living/simple_animal/hostile/mining_drone/unit_test_probe
	var/open_fire_calls = 0

/mob/living/simple_animal/hostile/mining_drone/unit_test_probe/OpenFire(atom/A)
	open_fire_calls++

///Режим сбора: руда через search_objects-путь, живые прозрачны, CollectOre делегацией
/datum/unit_test/ai_minebot_collects_ore/Run()
	var/mob/living/simple_animal/hostile/mining_drone/bot = allocate(/mob/living/simple_animal/hostile/mining_drone, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/minebot/controller = bot.ai_controller
	TEST_ASSERT(istype(controller), "A minebot must migrate onto its minebot profile")

	//первый план закрепляет режим сбора (Initialize ставит SetCollectBehavior после миграции)
	var/datum/ai_planning_subtree/minebot_mode_sync/sync = GLOB.ai_subtrees[/datum/ai_planning_subtree/minebot_mode_sync]
	sync.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_MIN_DISTANCE), "Collect mode must not keep a ranged kite band")

	//живые - не цели в режиме сбора (search_objects = 2 в легаси CanAttack)
	var/mob/living/simple_animal/hostile/fauna = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, NORTH))
	fauna.faction = list("wildlife")
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(!strategy.can_attack(bot, fauna), "Collect mode must ignore living wildlife")

	//руда находится search_objects-путём штатного finder'а и зеркалируется в pawn.target
	var/turf/ore_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/item/stack/ore/gold/nugget = allocate(/obj/item/stack/ore/gold, ore_turf)
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], nugget, "The finder must acquire loose ore through the search_objects path")
	TEST_ASSERT_EQUAL(bot.target, nugget, "The ore target must mirror into the legacy pawn target")

	//вплотную легаси AttackingTarget всасывает руду в трюм
	bot.forceMove(get_step(ore_turf, WEST))
	var/datum/ai_behavior/hostile_melee_attack/scoop = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	scoop.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(nugget.loc, bot, "An adjacent collect swing must vacuum the ore into the bot")

///Переключение режимов: легаси-хуки меняют переменные моба, mode_sync пересчитывает
///контроллер; бой = кайт-band из legacy retreat/minimum + OpenFire делегацией
/datum/unit_test/ai_minebot_mode_switch/Run()
	var/mob/living/simple_animal/hostile/mining_drone/unit_test_probe/bot = allocate(/mob/living/simple_animal/hostile/mining_drone/unit_test_probe, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/minebot/controller = bot.ai_controller
	var/datum/ai_planning_subtree/minebot_mode_sync/sync = GLOB.ai_subtrees[/datum/ai_planning_subtree/minebot_mode_sync]
	sync.SelectBehaviors(controller, 0.5) //закрепить режим сбора

	//протухающая цель: руда в блэкборде на момент смены режима
	var/obj/item/stack/ore/gold/nugget = allocate(/obj/item/stack/ore/gold, get_step(run_loc_floor_bottom_left, EAST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, nugget)

	//урон - легаси adjustHealth сам переводит бота в боевой режим (фолбэк-хук жив)
	bot.adjustHealth(5)
	TEST_ASSERT(bot.ranged, "Damage must flip the legacy minebot into attack mode")

	//синк подхватывает режим: кайт-band из легаси retreat/minimum, руда сброшена
	sync.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_MIN_DISTANCE], 2, "Attack mode must inherit the legacy retreat distance")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_MAX_DISTANCE], 4, "Attack mode must derive its pursuit edge from the legacy band")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "A mode flip must drop the stale ore target")

	//боевой режим: живность - цель, дальний план стреляет легаси-OpenFire
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/fauna = allocate(/mob/living/simple_animal/hostile, prey_turf)
	fauna.faction = list("wildlife")
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(strategy.can_attack(bot, fauna), "Attack mode must target living wildlife")

	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, fauna)
	var/datum/ai_planning_subtree/ranged_skirmish/gun_tree = GLOB.ai_subtrees[/datum/ai_planning_subtree/ranged_skirmish]
	gun_tree.SelectBehaviors(controller, 0.5)
	var/datum/ai_behavior/ranged_skirmish/gun = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)
	TEST_ASSERT(gun in controller.current_behaviors, "Attack mode must plan the ranged attack")
	controller.CancelActions()

	bot.ranged_cooldown = 0
	var/verdict = gun.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, 9, 2)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "A clear shot at visible wildlife must succeed")
	TEST_ASSERT_EQUAL(bot.open_fire_calls, 1, "The ranged behavior must fire through the legacy OpenFire delegate")

	//обратно в сбор (легаси toggle_mode с руки) - синк убирает кайт-band и цель
	bot.toggle_mode()
	TEST_ASSERT(!bot.ranged, "toggle_mode must flip the legacy minebot back to collect mode")
	sync.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_MIN_DISTANCE), "Returning to collect mode must clear the kite band")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "Returning to collect mode must drop the combat target")

	//в сборе дальний план не ставится вовсе (гейт по живому ranged-флагу)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, nugget)
	gun_tree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!(gun in controller.current_behaviors), "Collect mode must never plan ranged attacks")
	controller.CancelActions()

// ===== Ксеноморфы: дела улья дрона и королевы =====

///Дрон: милишный профиль + сорняки в тихую минуту; сентинел - авто-скирмишер
///по легаси-флагам ranged/retreat_distance
/datum/unit_test/ai_alien_drone_hive_duties/Run()
	var/mob/living/simple_animal/hostile/alien/drone/worker = allocate(/mob/living/simple_animal/hostile/alien/drone, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/melee_chaser/alien_drone/controller = worker.ai_controller
	TEST_ASSERT(istype(controller), "A drone must migrate onto its hive worker profile")

	//сентинел: авто-подбор скирмишера по ranged/retreat_distance + легаси кайт-band
	var/mob/living/simple_animal/hostile/alien/sentinel/spitter = allocate(/mob/living/simple_animal/hostile/alien/sentinel, get_step(run_loc_floor_bottom_left, NORTH))
	TEST_ASSERT(istype(spitter.ai_controller, /datum/ai_controller/hostile_adapter/ranged_skirmisher), "A sentinel must auto-select the ranged skirmisher profile")
	TEST_ASSERT_EQUAL(spitter.ai_controller.blackboard[BB_AI_MIN_DISTANCE], 5, "A sentinel must keep its legacy retreat distance as the kite band floor")

	//с целью улейные дела не планируются вовсе (гейт "нет цели", как у терроров)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_planning_subtree/alien_hive_duties/drone/duties = GLOB.ai_subtrees[/datum/ai_planning_subtree/alien_hive_duties/drone]
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	duties.SelectBehaviors(controller, 1000) //SPT_PROB с таким delta_time = гарантированный ролл
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/alien_spread_plants) in controller.current_behaviors), "Hive duties must never be planned while a target exists")
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)

	//без цели форс-ролл ставит посадку сорняков
	duties.SelectBehaviors(controller, 1000)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/alien_spread_plants) in controller.current_behaviors, "An idle drone must roll its weed planting")
	controller.CancelActions()

	//посадка: легаси SpreadPlants сажает узел и взводит дедлайн каденса
	var/datum/ai_behavior/alien_spread_plants/planting = GET_AI_BEHAVIOR(/datum/ai_behavior/alien_spread_plants)
	planting.perform(0.5, controller)
	var/obj/structure/alien/weeds/node/planted = locate() in get_turf(worker)
	TEST_ASSERT_NOTNULL(planted, "The planting duty must plant a legacy weed node")
	TEST_ASSERT(controller.blackboard[BB_AI_NEXT_PLANT_AT] > world.time, "Planting must arm the legacy cadence deadline")

	//дедлайн держит даже форс-ролл; plants_off глушит дела насовсем
	duties.SelectBehaviors(controller, 1000)
	TEST_ASSERT(!(planting in controller.current_behaviors), "The cadence deadline must gate the next planting")
	controller.blackboard[BB_AI_NEXT_PLANT_AT] = 0
	worker.plants_off = TRUE
	duties.SelectBehaviors(controller, 1000)
	TEST_ASSERT(!(planting in controller.current_behaviors), "plants_off must silence the hive duties")
	qdel(planted)

///Королева: скирмишер-профиль, стерильность гейтит яйца, LayEggs делегацией
/datum/unit_test/ai_alien_queen_lays_eggs/Run()
	var/mob/living/simple_animal/hostile/alien/queen/matriarch = allocate(/mob/living/simple_animal/hostile/alien/queen, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/ranged_skirmisher/alien_queen/controller = matriarch.ai_controller
	TEST_ASSERT(istype(controller), "A queen must migrate onto its royal skirmisher profile")

	//база стерильна (легаси sterile = 1): яйца не планируются даже форс-роллом,
	//но сорняки королева сажает как обычно
	var/datum/ai_planning_subtree/alien_hive_duties/queen/royal_duties = GLOB.ai_subtrees[/datum/ai_planning_subtree/alien_hive_duties/queen]
	royal_duties.SelectBehaviors(controller, 1000)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/alien_lay_eggs) in controller.current_behaviors), "A sterile queen must never plan egg laying")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/alien_spread_plants) in controller.current_behaviors, "An idle queen must still plan her weeds")
	controller.CancelActions()

	//плодовитая королева планирует и откладывает легаси-яйцо
	matriarch.sterile = FALSE
	royal_duties.SelectBehaviors(controller, 1000)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/alien_lay_eggs) in controller.current_behaviors, "A fertile queen must plan egg laying")
	controller.CancelActions()
	var/datum/ai_behavior/alien_lay_eggs/laying = GET_AI_BEHAVIOR(/datum/ai_behavior/alien_lay_eggs)
	laying.perform(0.5, controller)
	var/obj/structure/alien/egg/clutch = locate() in get_turf(matriarch)
	TEST_ASSERT_NOTNULL(clutch, "The laying duty must lay a legacy egg")
	TEST_ASSERT(controller.blackboard[BB_AI_NEXT_EGG_AT] > world.time, "Laying must arm the legacy cadence deadline")

	//дедлайн держит даже форс-ролл
	royal_duties.SelectBehaviors(controller, 1000)
	TEST_ASSERT(!(laying in controller.current_behaviors), "The cadence deadline must gate the next egg")
	qdel(clutch)

// ===== Джунглевая фауна: фазовые машины атак =====

///Мук: staged-профиль; активная фаза запирает движение и планирование;
///милишка и прыжок уходят в легаси WarmupAttack через делегацию
/datum/unit_test/ai_jungle_mook_staged_attacks/Run()
	var/mob/living/simple_animal/hostile/jungle/mook/wanderer = allocate(/mob/living/simple_animal/hostile/jungle/mook, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/ranged_chaser/jungle_staged/controller = wanderer.ai_controller
	TEST_ASSERT(istype(controller), "A mook must migrate onto the staged jungle profile")

	//нейтральный мук свободен; фаза (легаси MOOK_ATTACK_WARMUP = 1) запирает всё
	TEST_ASSERT(wanderer.can_ai_controller_move(), "A neutral mook must be free to move")
	var/datum/ai_planning_subtree/jungle_phase_guard/guard = GLOB.ai_subtrees[/datum/ai_planning_subtree/jungle_phase_guard]
	TEST_ASSERT_NULL(guard.SelectBehaviors(controller, 0.5), "A neutral mook must not trip the phase guard")
	wanderer.attack_state = 1 //MOOK_ATTACK_WARMUP (файл-локальный define мука)
	TEST_ASSERT(!wanderer.can_ai_controller_move(), "A phased mook must refuse controller movement")
	TEST_ASSERT_EQUAL(guard.SelectBehaviors(controller, 0.5), SUBTREE_RETURN_FINISH_PLANNING, "An active phase must freeze the whole plan")
	wanderer.attack_state = initial(wanderer.attack_state)

	//вплотную милишный делегат запускает легаси-разминку фазовой машины
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	wanderer.ranged_cooldown = 0
	var/datum/ai_behavior/hostile_melee_attack/hatchet = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	hatchet.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(wanderer.attack_state != initial(wanderer.attack_state), "An adjacent swing must start the legacy warmup phase")
	wanderer.attack_state = initial(wanderer.attack_state)

	//издали прыжок = легаси OpenFire через дальний делегат
	var/turf/far_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	prey.forceMove(far_turf)
	wanderer.ranged_cooldown = 0
	var/datum/ai_behavior/ranged_skirmish/leap = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)
	var/verdict = leap.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, 9, 2)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "A clear ranged attack at distant prey must succeed")
	TEST_ASSERT_EQUAL(wanderer.attack_state, 1, "The delegated OpenFire must start the legacy leap warmup")
	wanderer.attack_state = initial(wanderer.attack_state)

///Сидлинг: staged-профиль; фаза глушит уже запущенные поведения; GiveTarget-гард
///держит фокус мид-залпа; милишка вплотную уходит в легаси OpenFire
/datum/unit_test/ai_jungle_seedling_turret/Run()
	var/mob/living/simple_animal/hostile/jungle/seedling/turret = allocate(/mob/living/simple_animal/hostile/jungle/seedling, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/ranged_chaser/jungle_staged/controller = turret.ai_controller
	TEST_ASSERT(istype(controller), "A seedling must migrate onto the staged jungle profile")

	//фаза замораживает план и глушит поведения в полёте
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.queue_behavior(/datum/ai_behavior/hostile_melee_attack, BB_AI_CURRENT_TARGET)
	var/datum/ai_planning_subtree/jungle_phase_guard/guard = GLOB.ai_subtrees[/datum/ai_planning_subtree/jungle_phase_guard]
	turret.combatant_state = 1 //SEEDLING_STATE_WARMUP (файл-локальный define сидлинга)
	TEST_ASSERT_EQUAL(guard.SelectBehaviors(controller, 0.5), SUBTREE_RETURN_FINISH_PLANNING, "An active phase must freeze the whole plan")
	TEST_ASSERT(!length(controller.current_behaviors), "The phase guard must cancel behaviors already in flight")
	TEST_ASSERT(!turret.can_ai_controller_move(), "A phased seedling must refuse controller movement")

	//легаси-гард: мид-залпа цель не переключается (никакого 180 в лицо)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	turret.target = prey
	turret.GiveTarget(second)
	TEST_ASSERT_EQUAL(turret.target, prey, "A firing seedling must refuse to switch targets mid-volley")
	turret.combatant_state = initial(turret.combatant_state)

	//вплотную милишный делегат уходит в легаси OpenFire -> WarmupAttack
	turret.ranged_cooldown = 0
	turret.target = prey
	var/datum/ai_behavior/hostile_melee_attack/lash = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	lash.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(turret.combatant_state, 1, "An adjacent seedling must funnel its melee into the legacy warmup")
	turret.combatant_state = initial(turret.combatant_state)

///Леапер: прыжковый профиль без ходьбы; фриз между приземлением и выстрелом;
///Hop под контроллером взводит projectile_ready; плюха по обездвиженной жертве
/datum/unit_test/ai_jungle_leaper_hops/Run()
	var/mob/living/simple_animal/hostile/jungle/leaper/toad = allocate(/mob/living/simple_animal/hostile/jungle/leaper, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/leaper/controller = toad.ai_controller
	TEST_ASSERT(istype(controller), "A leaper must migrate onto its hopping profile")
	TEST_ASSERT(!toad.can_ai_controller_move(), "A leaper must never walk under controller movement")

	// Hop picks a landing point within three tiles of the target. Keep the
	// target four tiles away so that random choice can never be the start turf.
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	//легаси-фриз: между приземлением и выстрелом планирование стоит
	var/datum/ai_planning_subtree/leaper_assault/assault = GLOB.ai_subtrees[/datum/ai_planning_subtree/leaper_assault]
	toad.projectile_ready = TRUE
	TEST_ASSERT_EQUAL(assault.SelectBehaviors(controller, 0.5), SUBTREE_RETURN_FINISH_PLANNING, "projectile_ready must freeze assault planning")
	TEST_ASSERT(!length(controller.current_behaviors), "The armed shot window must not plan a new pounce")
	toad.projectile_ready = FALSE

	//прыжок: делегация легаси Hop; под контроллером он взводит projectile_ready
	assault.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/leaper_pounce) in controller.current_behaviors, "A standing target must plan the pounce")
	controller.CancelActions()
	toad.ranged_cooldown = 0
	//CancelActions может смыть цель через finish_action отменённых поведений, а
	//легаси Hop() первой строкой читает target пауна - перепиновка для детерминизма
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	toad.target = prey
	var/datum/ai_behavior/leaper_pounce/pounce = GET_AI_BEHAVIOR(/datum/ai_behavior/leaper_pounce)
	var/verdict = pounce.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "A pounce at a standing target must succeed")
	TEST_ASSERT(toad.hopping, "The pounce must delegate into the legacy Hop")
	TEST_ASSERT(toad.projectile_ready, "A controller-driven Hop must arm the post-hop shot like legacy AI_ON")

	//плюха: обездвиженная жертва получает легаси BellyFlop с телеграфом
	var/mob/living/simple_animal/hostile/jungle/leaper/second_toad = allocate(/mob/living/simple_animal/hostile/jungle/leaper, get_step(run_loc_floor_bottom_left, NORTH))
	var/datum/ai_controller/hostile_adapter/leaper/second_controller = second_toad.ai_controller
	second_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	prey.Stun(10 SECONDS)
	second_toad.ranged_cooldown = 0
	verdict = pounce.perform(0.5, second_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "A flop at a downed target must succeed")
	TEST_ASSERT(second_toad.hopping, "The flop must delegate into the legacy BellyFlop")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/leaper_crush) in get_turf(prey), "BellyFlop must telegraph the crush zone")

///Мега-арахнид: скирмишер с живым кайт-бандом, который BiologicalLife
///продолжает крутить в легаси-переменных застенчивости
/datum/unit_test/ai_jungle_mega_arachnid_shy_band/Run()
	var/mob/living/simple_animal/hostile/jungle/mega_arachnid/spider = allocate(/mob/living/simple_animal/hostile/jungle/mega_arachnid, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/ranged_skirmisher/mega_arachnid/controller = spider.ai_controller
	TEST_ASSERT(istype(controller), "A mega arachnid must migrate onto its shy skirmisher profile")

	//боевой band: Life снял отход - жмём вплотную (легаси walk_to с minimum 0)
	var/datum/ai_planning_subtree/mega_arachnid_band_sync/sync = GLOB.ai_subtrees[/datum/ai_planning_subtree/mega_arachnid_band_sync]
	spider.retreat_distance = 0
	spider.minimum_distance = 0
	sync.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_MIN_DISTANCE], 1, "An engaged arachnid must close to melee range")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_MAX_DISTANCE], 1, "An engaged arachnid must pursue all the way in")

	//застенчивый band: Life отвёл дистанцию 9 - контроллер кайтится
	spider.retreat_distance = 9
	spider.minimum_distance = 9
	sync.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_MIN_DISTANCE], 9, "A shy arachnid must keep its legacy stalking distance")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_MAX_DISTANCE], 11, "A shy arachnid must derive its pursuit edge from the band")

// ===== Headcrab: прыжок-захват и зомби-форма =====

///Хедкраб: авто-профиль ranged_chaser (прыжок = легаси OpenFire с throw_at),
///CanAttack-гейт трупов через делегацию, зомби-форма снимает прыжок живым флагом
/datum/unit_test/ai_headcrab_leaper/Run()
	var/mob/living/simple_animal/hostile/headcrab/crab = allocate(/mob/living/simple_animal/hostile/headcrab, run_loc_floor_bottom_left)
	crab.faction = list("zombie") //база "neutral" делит фракцию с людьми - боевой тест требует ксена
	var/datum/ai_controller/hostile_adapter/ranged_chaser/controller = crab.ai_controller
	TEST_ASSERT(istype(controller), "A headcrab must auto-select the ranged chaser profile")

	//живая цель валидна, прыжок планируется дальним сабтри
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(strategy.can_attack(crab, prey), "A living human must be a valid headcrab target")

	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	var/datum/ai_planning_subtree/ranged_skirmish/leap_tree = GLOB.ai_subtrees[/datum/ai_planning_subtree/ranged_skirmish]
	leap_tree.SelectBehaviors(controller, 0.5)
	var/datum/ai_behavior/ranged_skirmish/leap = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)
	TEST_ASSERT(leap in controller.current_behaviors, "Distant prey must plan the leap")
	controller.CancelActions()

	//исполнение: легаси OpenFire кидает краба и взводит легаси-кулдаун
	crab.ranged_cooldown = 0
	var/verdict = leap.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, 9, 2)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "A clear leap at visible prey must succeed")
	TEST_ASSERT(crab.ranged_cooldown > world.time, "The leap must arm the legacy ranged cooldown")

	//охота на трупы: легаси-гейт "мёртвое, но не человек - не цель" через делегацию
	crab.stat_attack = DEAD
	var/mob/living/simple_animal/hostile/critter = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, NORTH))
	critter.faction = list("wildlife")
	critter.death()
	TEST_ASSERT(!strategy.can_attack(crab, critter), "A dead non-human must be rejected by the legacy CanAttack override")
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	corpse.death()
	TEST_ASSERT(strategy.can_attack(crab, corpse), "A dead human must remain a valid infection target")
	crab.stat_attack = initial(crab.stat_attack)

	//зомбификация: легаси Zombify пересобирает моба, прыжок пропадает из планов
	crab.Zombify(corpse)
	TEST_ASSERT(crab.is_zombie, "Zombify must raise the zombie form")
	TEST_ASSERT(!crab.ranged, "Zombify must ground the crab")
	TEST_ASSERT_EQUAL(corpse.loc, crab, "The host body must ride inside the zombie")
	leap_tree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!(leap in controller.current_behaviors), "A zombie must never plan leaps")
	TEST_ASSERT_EQUAL(crab.ai_controller, controller, "The zombie form must keep the same controller for its melee subtrees")
	controller.CancelActions()
///Визард: кайт-band из легаси retreat/minimum_distance и делегация AutomatedCast -
///приоритет "фаербол в линию -> магмиссайл -> блинк" с каденсом "один спелл в секунду"
/datum/unit_test/ai_wizard_spellcasting/Run()
	var/mob/living/simple_animal/hostile/wizard/caster = allocate(/mob/living/simple_animal/hostile/wizard, run_loc_floor_bottom_left)
	var/turf/east_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, east_turf)

	var/datum/ai_controller/hostile_adapter/controller = caster.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/ranged_skirmisher/wizard), "The wizard must migrate onto its spellcaster profile")
	//не-ranged моб не получает band в setup_from_pawn - его обязан выставить профиль
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_MIN_DISTANCE], caster.retreat_distance, "The kite band minimum must come from the legacy retreat_distance")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_MAX_DISTANCE], caster.retreat_distance + 2, "The kite band maximum must extend past the legacy retreat_distance")

	//сабтри: без цели каст не планируется
	var/datum/ai_planning_subtree/wizard_spellcasting/casting_tree = GLOB.ai_subtrees[/datum/ai_planning_subtree/wizard_spellcasting]
	casting_tree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/wizard_cast) in controller.current_behaviors), "No target must mean no queued cast")

	//легаси-каденс next_cast гейтит сабтри
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	caster.next_cast = world.time + 10 SECONDS
	casting_tree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/wizard_cast) in controller.current_behaviors), "The legacy one-spell-per-second cadence must gate the subtree")
	caster.next_cast = 0
	casting_tree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/wizard_cast) in controller.current_behaviors, "A target with a free cadence must queue the cast")
	controller.CancelActions()

	//дальше кастуем вручную: глушим живой контроллер, чтобы фоновый тикер
	//не кастовал и не кайтил сам во время sleep-ов теста
	controller.set_ai_status(AI_STATUS_OFF)

	//кардинальная линия: уходит фаербол (снаряд глушим - не подрываем тест-комнату)
	caster.fireball.projectile_type = null
	var/datum/ai_behavior/wizard_cast/cast = GET_AI_BEHAVIOR(/datum/ai_behavior/wizard_cast)
	cast.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	sleep(2)
	TEST_ASSERT(caster.next_cast > world.time, "A lined-up cast must arm the legacy spell cadence")
	TEST_ASSERT(caster.fireball.charge_counter < caster.fireball.charge_max, "A lined-up target must eat the fireball")
	TEST_ASSERT_EQUAL(caster.dir, EAST, "The legacy cast must face the wizard towards its victim")

	//диагональ: фаербол заряжен, но не в линию - уходит магмиссайл
	var/turf/diag_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	prey.forceMove(diag_turf)
	caster.fireball.charge_counter = caster.fireball.charge_max
	caster.next_cast = 0
	cast.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	sleep(2)
	TEST_ASSERT(caster.next_cast > world.time, "A diagonal cast must still arm the cadence")
	TEST_ASSERT_EQUAL(caster.fireball.charge_counter, caster.fireball.charge_max, "A diagonal target must not be fireballed")
	TEST_ASSERT(caster.mm.charge_counter < caster.mm.charge_max, "A diagonal target must eat the magic missile")

	//атакующие спеллы в откате: "Spam Blink when you can"
	caster.fireball.charge_counter = 0
	caster.mm.charge_counter = 0
	caster.blink.charge_counter = caster.blink.charge_max
	caster.next_cast = 0
	cast.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	sleep(2)
	TEST_ASSERT(caster.next_cast > world.time, "With attack spells down the wizard must spam blink")
	TEST_ASSERT(caster.blink.charge_counter < caster.blink.charge_max, "The blink charge must be consumed")

	//всё в откате: каденс не тратится впустую
	caster.blink.charge_counter = 0
	caster.next_cast = 0
	cast.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	sleep(2)
	TEST_ASSERT_EQUAL(caster.next_cast, 0, "With every spell recharging the cadence must stay untouched")

///Пробник ангела: наблюдение управляется тестом (реальных клиентов в CI нет)
/mob/living/simple_animal/hostile/statue/unit_test_watched
	var/mob/unit_test_watcher

/mob/living/simple_animal/hostile/statue/unit_test_watched/can_be_seen(turf/destination)
	return unit_test_watcher

///Плачущий ангел: под взглядом заморожен целиком (план, мувер, легаси-гейты),
///без взгляда - обычная милишная погоня; рентген-стратегия и каденс атак 1:1
/datum/unit_test/ai_statue_freezes_when_watched/Run()
	var/mob/living/simple_animal/hostile/statue/unit_test_watched/angel = allocate(/mob/living/simple_animal/hostile/statue/unit_test_watched, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))

	var/datum/ai_controller/hostile_adapter/controller = angel.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/melee_chaser/statue), "The statue must migrate onto its adapter profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy/statue, "The statue must use the xray strategy")

	//рентген легаси search_objects=1 + SEE_MOBS: цели видны сквозь стены
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(strategy.ignores_sight(angel), "The statue must acquire targets without line of sight")

	//скорость 1:1 - фишка ангела: легаси-каденс атак без компромиссного ускорения
	//и легаси-конверсия move_to_delay = 0 (шаг каждый мировой тик)
	var/datum/ai_behavior/hostile_melee_attack/claws = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	TEST_ASSERT_EQUAL(claws.get_cooldown(controller), SSnpcpool.wait, "The statue must keep the exact legacy melee cadence")
	TEST_ASSERT_EQUAL(controller.movement_delay, AI_LEGACY_MOVE_DELAY_DS(0), "The statue must keep its legacy top movement speed")

	//клиент-гейт CanAttack через делегацию: манекен без ckey - не цель
	TEST_ASSERT(!strategy.can_attack(angel, prey), "A clientless mob must not be a statue target")
	prey.ckey = "unit_test_statue_prey"
	TEST_ASSERT(strategy.can_attack(angel, prey), "A player mob must be a valid statue target")

	//создатель неприкосновенен (легаси ListTargets() - creator)
	angel.creator = prey
	TEST_ASSERT(!strategy.can_attack(angel, prey), "The statue must never target its creator")
	angel.creator = null

	//под взглядом: движение заперто и боевой план обрывается
	angel.unit_test_watcher = prey
	TEST_ASSERT(!angel.can_ai_controller_move(), "A watched statue must refuse controller movement")
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	drive_ai_planning(controller)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack) in controller.current_behaviors), "A watched statue must not plan melee")
	var/turf/north_turf = get_step(run_loc_floor_bottom_left, NORTH)
	angel.Move(north_turf)
	TEST_ASSERT_EQUAL(get_turf(angel), run_loc_floor_bottom_left, "The legacy Move gate must hold a watched statue in place")

	//взгляд отведён: движение свободно, FSM доходит до милишного плана
	angel.unit_test_watcher = null
	TEST_ASSERT(angel.can_ai_controller_move(), "An unwatched statue must move freely")
	drive_ai_planning(controller)
	controller.blackboard[BB_AI_STATE_ENTERED_AT] = world.time - AI_ALERT_REACTION_TIME - 1 //пауза ALERT отыграна
	drive_ai_planning(controller)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack) in controller.current_behaviors, "An unwatched statue must plan its melee")

	//дальше бьём вручную: глушим живой контроллер, чтобы фоновый тикер
	//не дублировал удары во время sleep-ов теста
	controller.CancelActions()
	controller.set_ai_status(AI_STATUS_OFF)

	//удар проходит только без взгляда: AttackingTarget-гейт работает через делегацию
	controller.blackboard[BB_AI_CURRENT_TARGET] = prey //OFF-статус мог снести ключ - бьём вручную
	var/health_before = prey.health
	claws.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	sleep(1)
	TEST_ASSERT(prey.health < health_before, "An unwatched statue must claw its victim through the legacy AttackingTarget")
	angel.unit_test_watcher = prey
	health_before = prey.health
	claws.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	sleep(1)
	TEST_ASSERT_EQUAL(prey.health, health_before, "A watched statue must not land a single blow")
	controller.CancelActions()

///Безумный клоун: retaliate-гейт целей, закреплённая жертва, телепорт-сталкинг
///делегатом легаси stalk() и отложенное растворение над трупом
/datum/unit_test/ai_insane_clown_stalks/Run()
	var/mob/living/simple_animal/hostile/retaliate/clown/insane/stalker = allocate(/mob/living/simple_animal/hostile/retaliate/clown/insane, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))

	var/datum/ai_controller/hostile_adapter/controller = stalker.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/insane_clown), "The insane clown must migrate onto its stalker profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy/retaliate, "The clown must keep the retaliate enemies gate")
	TEST_ASSERT(!stalker.can_ai_controller_move(), "The clown must never walk: teleporting is its only movement")
	TEST_ASSERT(!controller.can_idle, "The stalker must not sleep when its victim leaves the wake window")

	//мирный: без обид штатный поиск целей никого не берёт (Retaliate() пуст)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "A stranger must not become a clown target without a grudge")

	//удар: обидчик записан и закреплён как жертва сталкинга
	stalker.RetaliateAgainst(victim)
	TEST_ASSERT(victim in stalker.enemies, "A direct attacker must enter the enemies list")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], victim, "The attacker must become the live target")
	drive_ai_planning(controller)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/insane_clown_stalk) in controller.current_behaviors, "A pinned victim must queue the stalk delegate")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STALK_VICTIM], victim, "The victim must be pinned for stalking")
	TEST_ASSERT_NULL(controller.current_movement_target, "The stalker must never set a movement target")

	//дальше сталкерим вручную: глушим живой контроллер, чтобы фоновый тикер
	//не тикал таймер сам во время sleep-ов теста
	controller.CancelActions()
	controller.set_ai_status(AI_STATUS_OFF)

	//таймер дотикал: хонк и телепорт на жертву легаси-проком stalk()
	var/turf/far_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	victim.forceMove(far_turf)
	stalker.timer = 1
	var/datum/ai_behavior/insane_clown_stalk/stalk = GET_AI_BEHAVIOR(/datum/ai_behavior/insane_clown_stalk)
	stalk.perform(0.5, controller)
	TEST_ASSERT(stalker.timer >= 5 && stalker.timer <= 15, "The legacy stalk() must rewind its own timer")
	//легаси spawn(12) перед forceMove: ждём сам переезд, а не отмеренные 14 деци -
	//под нагрузкой раннера отложенный spawn в это окно не укладывался
	wait_for_var(stalker, NAMEOF(stalker, loc), far_turf)
	TEST_ASSERT_EQUAL(get_turf(stalker), far_turf, "The legacy stalk() must teleport the clown onto its victim")

	//смерть жертвы: смех и растворение легаси-проком, отложенно от планировщика
	victim.death()
	stalk.perform(0.5, controller)
	wait_for_qdeleted(stalker)
	TEST_ASSERT(QDELETED(stalker), "A dead victim must dissolve the clown through the legacy stalk()")
// ===== Floor cluwne: сценарный сталкер с закреплённой жертвой =====

///Floor cluwne на адаптере: жертву назначает сценарий (Acquire_Victim),
///контроллер преследует её сквозь стены, замирает на явлении (легаси-гейт
///Goto -> can_ai_controller_move) и не может подменить жертву планировщиком.
/datum/unit_test/ai_floor_cluwne_stalks_scenario_victim/Run()
	var/turf/victim_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(victim_turf, "Sanity: the scenario checks need a walkable station turf")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, victim_turf)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, victim_turf)

	//Acquire_Victim выбирает жертву из player_list и требует станционный z
	var/turf/spawn_turf = get_step(victim_turf, EAST) || victim_turf
	GLOB.player_list += victim
	var/mob/living/simple_animal/hostile/floor_cluwne/creep = allocate(/mob/living/simple_animal/hostile/floor_cluwne, spawn_turf)
	GLOB.player_list -= victim

	TEST_ASSERT(!QDELETED(creep), "Sanity: the cluwne must survive spawn with a valid victim available")
	TEST_ASSERT_EQUAL(creep.current_victim, victim, "The spawn scenario must acquire the registered victim")

	var/datum/ai_controller/hostile_adapter/floor_cluwne/controller = creep.ai_controller
	TEST_ASSERT(istype(controller), "A floor cluwne must possess the floor cluwne profile controller")
	TEST_ASSERT(!controller.can_idle, "The scenario stalker must never idle: its victim can leave the wake window")

	//стратегия закреплённой жертвы: никого, кроме жертвы сценария
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(istype(strategy, /datum/targeting_strategy/floor_cluwne_victim), "The cluwne must use the pinned-victim strategy")
	TEST_ASSERT(strategy.can_attack(creep, victim), "The scenario victim must be the valid pursuit target")
	TEST_ASSERT(!strategy.can_attack(creep, bystander), "A bystander must never become a cluwne target")
	TEST_ASSERT(strategy.ignores_sight(creep), "The cluwne must track its victim through walls, like the legacy loop")

	//план: закрепление жертвы + бессрочное преследование
	drive_ai_planning(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], victim, "Planning must pin the scenario victim into the blackboard")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/floor_cluwne_stalk) in controller.current_behaviors, "The plan must queue the stalk behavior")
	TEST_ASSERT_EQUAL(controller.current_movement_target, victim, "The stalk behavior must pursue the victim itself")

	//насильно очищенный блэкборд восстанавливается закреплением сценария
	controller.CancelActions()
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
	drive_ai_planning(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], victim, "Re-planning must re-pin the scenario victim")

	//легаси-гейт Goto: явление и недоступные зоны запирают шаги контроллера
	TEST_ASSERT(creep.can_ai_controller_move(), "An unmanifested cluwne with a reachable victim must be free to stalk")
	creep.manifested = TRUE
	TEST_ASSERT(!creep.can_ai_controller_move(), "A manifested cluwne must hold still for its scenario do_afters")
	creep.manifested = FALSE
	victim.forceMove(run_loc_floor_bottom_left) //резервация - не станционный z
	TEST_ASSERT(!creep.can_ai_controller_move(), "A victim off the station must stop the walk, like the legacy Goto gate")

	controller.CancelActions()

// ===== Eldritch demons: постоянное исключение (гост-вессели) =====

///Пин исключения (MIGRATION_EXCEPTIONS.md): демоны еретиков - чистые
///гост-вессели. AI выключен с рождения и контроллер не аттачится, а червь
///armsy ходит хвостом за головой сценарной кинематикой на сигналах движения,
///без всякого AI.
/datum/unit_test/ai_eldritch_stays_player_vessel/Run()
	var/mob/living/simple_animal/hostile/eldritch/raw_prophet/prophet = allocate(/mob/living/simple_animal/hostile/eldritch/raw_prophet, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(prophet.ai_controller, "A ghost-vessel demon must not receive an adapter controller")
	TEST_ASSERT_EQUAL(prophet.AIStatus, AI_OFF, "A ghost-vessel demon must stay AI_OFF")
	TEST_ASSERT(!(prophet in GLOB.simple_animals[AI_ON]), "A ghost-vessel demon must not enroll into the active legacy pool")

	//червь: голова + сегменты; хвост следует за головой сигналом движения
	var/mob/living/simple_animal/hostile/eldritch/armsy/worm = allocate(/mob/living/simple_animal/hostile/eldritch/armsy, run_loc_floor_bottom_left, TRUE, 3)
	TEST_ASSERT_NOTNULL(worm.back, "Sanity: the worm must have body segments")
	TEST_ASSERT_NULL(worm.ai_controller, "The worm head must not receive an adapter controller")
	for(var/mob/living/simple_animal/hostile/eldritch/armsy/segment = worm.back, segment, segment = segment.back)
		TEST_ASSERT_NULL(segment.ai_controller, "Worm segments must not receive adapter controllers")
		TEST_ASSERT_EQUAL(segment.AIStatus, AI_OFF, "Worm segments must stay AI_OFF")

	//кинематика: два шага головы - первый сегмент шагает в её прошлый турф
	var/turf/first_step = get_step(run_loc_floor_bottom_left, EAST)
	var/turf/second_step = get_step(first_step, EAST)
	step(worm, EAST)
	step(worm, EAST)
	TEST_ASSERT_EQUAL(get_turf(worm), second_step, "Sanity: the head must have moved two tiles")
	TEST_ASSERT_EQUAL(get_turf(worm.back), first_step, "The first segment must follow the head through the movement signal")

	//декали gib_trail с пола резервации подчищаем за червём
	for(var/turf/nearby as anything in RANGE_TURFS(3, run_loc_floor_bottom_left))
		for(var/obj/effect/decal/cleanable/mess in nearby)
			qdel(mess)

// ===== AI-сварнеры: фуражирский цикл + легаси-паузы через мост =====

///Ресурсный сварнер: поиск еды, поедание делегацией (Integrate + обучение
///typecache), приоритеты починки/репликации и гейт "живая угроза важнее
///хозяйства"; легаси-паузы StartAction/EndAction ходят через toggle_ai-мост.
/datum/unit_test/ai_swarmer_forage_cycle/Run()
	var/mob/living/simple_animal/hostile/swarmer/ai/resource/forager = allocate(/mob/living/simple_animal/hostile/swarmer/ai/resource, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/swarmer/resource/controller = forager.ai_controller
	TEST_ASSERT(istype(controller), "A resource swarmer must migrate onto the swarmer resource profile")
	TEST_ASSERT(controller.cross_dangerous_turfs, "Swarmers must treat lava as passable: their legacy Move override lays catwalks")

	//еда: гаечный ключ (железо в custom_materials) в двух тайлах
	var/turf/food_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/item/wrench/food = allocate(/obj/item/wrench, food_turf)

	var/datum/ai_planning_subtree/swarmer_forage/forage = GLOB.ai_subtrees[/datum/ai_planning_subtree/swarmer_forage]
	forage.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/swarmer_find_food) in controller.current_behaviors, "An idle resource swarmer must plan a food search")

	var/datum/ai_behavior/swarmer_find_food/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/swarmer_find_food)
	var/verdict = finder.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "The food search must find an edible object")
	TEST_ASSERT(isobj(controller.blackboard[BB_AI_CURRENT_TARGET]), "The found food must become the controller target")
	controller.CancelActions()

	//вплотную милишный делегат съедает предмет легаси-цепочкой Integrate
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, food)
	TEST_ASSERT_EQUAL(forager.target, food, "The food target must mirror into the legacy pawn target")
	forager.forceMove(get_step(food_turf, WEST))
	var/resources_before = forager.resources
	var/datum/ai_behavior/hostile_melee_attack/jaws = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	jaws.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(QDELETED(food), "An adjacent bite must integrate the wrench")
	TEST_ASSERT(forager.resources > resources_before, "Integration must convert the item into resources")
	TEST_ASSERT(forager.sharedWanted[/obj/item/wrench], "A successful meal must teach the shared wanted typecache")

	//приоритет самопочинки над едой
	controller.CancelActions()
	forager.health = forager.maxHealth * 0.2
	forage.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/swarmer_scenario_action/self_repair) in controller.current_behaviors, "A wounded swarmer must plan self-repair first")
	controller.CancelActions()
	forager.health = forager.maxHealth

	//репликация при 50+ ресурсах под капом роя
	forager.resources = 50
	forage.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/swarmer_scenario_action/replicate) in controller.current_behaviors, "A rich swarmer under the swarm cap must plan replication")
	controller.CancelActions()

	//живая угроза глушит всё хозяйство
	var/mob/living/carbon/human/threat = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, threat)
	TEST_ASSERT_NULL(forage.SelectBehaviors(controller, 0.5), "A living threat must silence the forage cycle")
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/swarmer_scenario_action/replicate) in controller.current_behaviors), "No replication may be planned while a living threat is targeted")
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
	forager.resources = 0

	//мост легаси-пауз: StartAction гасит контроллер, EndAction возвращает
	forager.StartAction(50)
	TEST_ASSERT(HAS_TRAIT(forager, TRAIT_AI_PAUSED), "StartAction must pause the controller through the legacy toggle bridge")
	TEST_ASSERT(!controller.able_to_run, "A paused swarmer controller must be unable to run")
	forager.EndAction()
	TEST_ASSERT(!HAS_TRAIT(forager, TRAIT_AI_PAUSED), "EndAction must lift the legacy pause")
	TEST_ASSERT(controller.able_to_run, "A resumed swarmer controller must be able to run")
	TEST_ASSERT(!forager.stop_automated_movement, "EndAction must clear the scenario move lock")

///Боевые сварнеры: профили по легаси-флагам, электрошок/диспёрс делегацией,
///лавовый шаг стелет катвок легаси-Move (профиль обязан пускать в лаву).
/datum/unit_test/ai_swarmer_combat_subtypes/Run()
	var/mob/living/simple_animal/hostile/swarmer/ai/generic = allocate(/mob/living/simple_animal/hostile/swarmer/ai, get_step(run_loc_floor_bottom_left, WEST))
	TEST_ASSERT_EQUAL(generic.ai_controller?.type, /datum/ai_controller/hostile_adapter/swarmer, "The abstract AI swarmer must use the base swarmer profile")

	var/mob/living/simple_animal/hostile/swarmer/ai/ranged_combat/gunner = allocate(/mob/living/simple_animal/hostile/swarmer/ai/ranged_combat, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/swarmer/skirmisher/gunner_controller = gunner.ai_controller
	TEST_ASSERT(istype(gunner_controller), "A ranged swarmer must use the swarmer skirmisher profile")
	TEST_ASSERT_EQUAL(gunner_controller.blackboard[BB_AI_MIN_DISTANCE], 3, "The legacy retreat_distance must set the kite band floor")
	TEST_ASSERT_EQUAL(gunner_controller.blackboard[BB_AI_MAX_DISTANCE], 5, "The legacy minimum_distance must set the kite band ceiling")

	var/mob/living/simple_animal/hostile/swarmer/ai/melee_combat/brawler = allocate(/mob/living/simple_animal/hostile/swarmer/ai/melee_combat, get_step(run_loc_floor_bottom_left, NORTH))
	var/datum/ai_controller/hostile_adapter/swarmer/brawler/brawler_controller = brawler.ai_controller
	TEST_ASSERT(istype(brawler_controller), "A melee swarmer must use the swarmer brawler profile")

	//электрошок либо телепорт-диспёрс: обе ветки легаси AttackingTarget валидны
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(get_turf(brawler), EAST))
	brawler_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	var/datum/ai_behavior/hostile_melee_attack/shock = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	shock.perform(0.5, brawler_controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(prey.getStaminaLoss() > 0 || brawler.stop_automated_movement, "The legacy melee must shock the prey or begin its teleport dispersal")

	//лавовый шаг: легаси-Move стелет катвок вместо самоубийственного шага
	var/turf/lava_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/saved_turf_type = lava_turf.type
	lava_turf.ChangeTurf(/turf/open/lava)
	lava_turf = get_step(run_loc_floor_bottom_left, EAST)
	TEST_ASSERT(gunner_controller.can_enter_dangerous_turf(lava_turf), "A swarmer controller must treat lava as traversable")
	step(gunner, EAST)
	var/obj/structure/lattice/catwalk/swarmer_catwalk/catwalk = locate() in lava_turf
	TEST_ASSERT_NOTNULL(catwalk, "Stepping into unsafe lava must lay a swarmer catwalk through the legacy Move override")
	TEST_ASSERT_EQUAL(get_turf(gunner), run_loc_floor_bottom_left, "The catwalk-laying step must not enter the lava tile")
	qdel(catwalk)
	lava_turf.ChangeTurf(saved_turf_type)
	gunner.EndAction() //снять сценарную паузу катвока до конца теста
///Гигантский паук: профиль с перебежками; сабтри гейтится боем и занятостью,
///перебежка ограничена легаси-таймером и переносит мирный якорь
/datum/unit_test/ai_giant_spider_idle_skitter/Run()
	var/mob/living/simple_animal/hostile/poison/giant_spider/spider = allocate(/mob/living/simple_animal/hostile/poison/giant_spider, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/controller = spider.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/melee_chaser/giant_spider), "A giant spider must migrate onto its adapter profile")

	var/datum/ai_planning_subtree/spider_idle_skitter/legs = GLOB.ai_subtrees[/datum/ai_planning_subtree/spider_idle_skitter]
	var/datum/ai_behavior/spider_skitter/skitter = GET_AI_BEHAVIOR(/datum/ai_behavior/spider_skitter)

	//бой глушит перебежку даже при гарантированном ролле
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	legs.SelectBehaviors(controller, 1000) //SPT_PROB с таким delta_time = гарантированный ролл
	TEST_ASSERT(!(skitter in controller.current_behaviors), "A spider in combat must not plan a skitter")
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)

	//занятость (плетение/кокон) глушит перебежку, как легаси-гейт !busy
	spider.busy = 1 //SPINNING_WEB
	legs.SelectBehaviors(controller, 1000)
	TEST_ASSERT(!(skitter in controller.current_behaviors), "A busy spider must not plan a skitter")
	spider.busy = 0 //SPIDER_IDLE

	//свободный паук стартует перебежку: дедлайн взведён, точка движения выбрана
	//(шанс всего 0.5%/с - форс-ролл требует огромного delta_time)
	legs.SelectBehaviors(controller, 1000000)
	TEST_ASSERT(skitter in controller.current_behaviors, "An idle spider must plan its random skitter")
	TEST_ASSERT(controller.blackboard[BB_SPIDER_SKITTER_UNTIL] > world.time, "The skitter must arm its legacy five-second deadline")
	TEST_ASSERT_NOTNULL(controller.current_movement_target, "The skitter must pick a destination turf")

	//истёкший дедлайн завершает перебежку и переносит мирный якорь (легаси-разбредание)
	controller.set_blackboard_key(BB_AI_PATROL_ANCHOR, run_loc_floor_bottom_left)
	controller.blackboard[BB_SPIDER_SKITTER_UNTIL] = world.time - 1
	var/verdict = skitter.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "An expired skitter must finish successfully")
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_PATROL_ANCHOR], "A finished skitter must relocate the patrol anchor (legacy diffusion)")
	controller.CancelActions()

///Нянька: труп -> кокон -> паутина -> яйца -> обмотка предметов; бой сбрасывает цикл
/datum/unit_test/ai_nurse_spider_cocoon_cycle/Run()
	var/mob/living/simple_animal/hostile/poison/giant_spider/nurse/nurse = allocate(/mob/living/simple_animal/hostile/poison/giant_spider/nurse, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/controller = nurse.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/melee_chaser/giant_spider/nurse), "A nurse spider must migrate onto the nurse profile")

	var/datum/ai_behavior/spider_nurse_weave/weave = GET_AI_BEHAVIOR(/datum/ai_behavior/spider_nurse_weave)
	var/datum/ai_behavior/spider_wrap_target/wrap = GET_AI_BEHAVIOR(/datum/ai_behavior/spider_wrap_target)

	//решение: беспомощный труп рядом выбирается в кокон (легаси-приоритет 1)
	var/turf/corpse_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, corpse_turf)
	corpse.death()
	var/verdict = weave.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "The weave decision must pick the helpless corpse")
	TEST_ASSERT_EQUAL(nurse.cocoon_target, corpse, "The corpse must become the cocoon target")
	TEST_ASSERT_EQUAL(nurse.busy, 3, "The nurse must enter the legacy MOVING_TO_TARGET state")

	//вплотную: обмотка стартует легаси-коконом (busy = SPINNING_COCOON до do_after)
	verdict = wrap.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "An adjacent wrap must start the legacy cocoon")
	TEST_ASSERT_EQUAL(nurse.busy, 4, "The legacy cocoon must be spinning")
	sleep(52) //легаси do_after 50
	var/obj/structure/spider/cocoon/wrap_result = locate() in corpse_turf
	TEST_ASSERT_NOTNULL(wrap_result, "The finished cocoon must exist on the corpse turf")
	TEST_ASSERT_EQUAL(corpse.loc, wrap_result, "The corpse must be wrapped inside the cocoon")
	TEST_ASSERT_EQUAL(nurse.fed, 1, "Consuming the corpse must feed the nurse for one egg clutch")
	TEST_ASSERT_EQUAL(nurse.busy, 0, "A finished cocoon must return the nurse to idle")

	//бой прерывает плетение, как легаси-ветка сброса busy
	nurse.busy = 1 //SPINNING_WEB
	var/mob/living/carbon/human/threat = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, threat)
	var/datum/ai_planning_subtree/spider_nurse_cycle/cycle = GLOB.ai_subtrees[/datum/ai_planning_subtree/spider_nurse_cycle]
	cycle.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(nurse.busy, 0, "Combat must reset the weaving state like the legacy else-branch")
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)

	//паутина: без трупов и без паутины на турфе нянька начинает плести (приоритет 2)
	qdel(corpse)
	qdel(wrap_result)
	verdict = weave.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "With no corpses the nurse must decide to spin a web")
	TEST_ASSERT_EQUAL(nurse.busy, 1, "The legacy web spin must be in progress")
	sleep(42) //легаси do_after 40
	TEST_ASSERT_NOTNULL(locate(/obj/structure/spider/stickyweb) in run_loc_floor_bottom_left, "The finished web must exist on the nurse turf")

	//яйца: сытая нянька на паутине откладывает кладку (приоритет 3)
	verdict = weave.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "A fed nurse on a web must decide to lay eggs")
	TEST_ASSERT_EQUAL(nurse.busy, 2, "The legacy egg laying must be in progress")
	sleep(52) //легаси do_after 50
	TEST_ASSERT_NOTNULL(locate(/obj/structure/spider/eggcluster) in run_loc_floor_bottom_left, "The egg cluster must exist on the nurse turf")
	TEST_ASSERT_EQUAL(nurse.fed, 0, "Laying eggs must spend the stored feeding")

	//обмотка утвари: с паутиной и без голода нянька коконит незакреплённый предмет (приоритет 4)
	var/obj/item/wrench/tool = allocate(/obj/item/wrench, get_step(run_loc_floor_bottom_left, NORTH))
	verdict = weave.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "With everything woven the nurse must wrap loose items")
	TEST_ASSERT_EQUAL(nurse.cocoon_target, tool, "The loose item must become the cocoon target")
	TEST_ASSERT_EQUAL(nurse.busy, 3, "The nurse must approach the item in the legacy state")
	controller.CancelActions()

	//не-allocate постройки не должны пережить тест (кладка растит спайдерлингов)
	qdel(locate(/obj/structure/spider/eggcluster) in run_loc_floor_bottom_left)
	qdel(locate(/obj/structure/spider/stickyweb) in run_loc_floor_bottom_left)

///Пчела: грядки через search_objects-путь файндера, опыление делегацией,
///работа важнее жертв, удар временно выключает поиск растений
/datum/unit_test/ai_bee_pollination/Run()
	var/mob/living/simple_animal/hostile/poison/bees/worker = allocate(/mob/living/simple_animal/hostile/poison/bees, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/controller = worker.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/bee), "A bee must migrate onto its adapter profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy/bee, "A bee must use the bee targeting strategy")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGET_SCORER], /datum/target_scorer/bee_work_first, "A bee must rank work above victims")

	//гейт валидной грядки из легаси Found(): пустая - не цель, засеянная - цель
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(/datum/targeting_strategy/hostile_legacy/bee)
	var/obj/machinery/hydroponics/tray = allocate(/obj/machinery/hydroponics, get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT(!strategy.can_attack(worker, tray), "An empty tray must not be a pollination target")
	tray.myseed = new /obj/item/seeds/wheat(tray)
	TEST_ASSERT(strategy.can_attack(worker, tray), "A seeded live tray must be a pollination target")

	//королева не опыляет (легаси queen/Found() = FALSE)
	var/mob/living/simple_animal/hostile/poison/bees/queen/royal = allocate(/mob/living/simple_animal/hostile/poison/bees/queen, get_step(run_loc_floor_bottom_left, SOUTH))
	TEST_ASSERT(!strategy.can_attack(royal, tray), "The queen must never pollinate")

	//hive-тик поддерживает охоту на грядки (легаси Found() держал typecache)
	var/datum/ai_planning_subtree/bee_hive_cycle/hive = GLOB.ai_subtrees[/datum/ai_planning_subtree/bee_hive_cycle]
	controller.blackboard[BB_BEE_NEXT_HIVE_TICK] = null
	hive.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(is_type_in_typecache(tray, worker.wanted_objects), "The hive tick must maintain the legacy hydroponics typecache")

	//файндер берёт грядку через search_objects-путь
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], tray, "The seeded tray must become the bee target")

	//работа важнее жертв: человек вплотную не перебивает валидную грядку
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], tray, "A valid tray must outrank a nearby victim (legacy Found priority)")
	TEST_ASSERT_NOTNULL(victim, "Sanity: the victim must exist for the priority check")

	//опыление делегацией легаси AttackingTarget
	var/datum/ai_behavior/hostile_melee_attack/sting = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	sting.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(tray.recent_bee_visit, "Pollination must mark the tray as recently visited")
	TEST_ASSERT_NULL(worker.target, "Pollination must clear the legacy target for the next tray")
	TEST_ASSERT(!strategy.can_attack(worker, tray), "A freshly visited tray must not be re-targeted")

	//удар - fight or flight: поиск растений выключается на легаси-таймер.
	//AI глушим: иначе пчела жалит жертву рядом, та бьёт в ответ и снова
	//сбрасывает search_objects уже после RegainSearchObjects.
	controller.set_ai_status(AI_STATUS_OFF)
	controller.CancelActions()
	tray.recent_bee_visit = FALSE
	worker.adjustBruteLoss(1)
	TEST_ASSERT_EQUAL(worker.search_objects, 0, "Damage must trigger the legacy LoseSearchObjects")
	TEST_ASSERT(!strategy.can_attack(worker, tray), "An angry bee must sting, not pollinate")
	//возврат поиска висит на addtimer: одного деци запаса поверх задержки под
	//нагрузкой раннера не хватало, ждём фактического снятия гейта
	wait_for_var(worker, NAMEOF(worker, search_objects), 1, worker.search_objects_regain_time + 2 SECONDS)
	TEST_ASSERT_EQUAL(worker.search_objects, 1, "The bee must regain plant search after the legacy delay")
	TEST_ASSERT(strategy.can_attack(worker, tray), "A calmed bee must go back to work")
	controller.CancelActions()

///Улей: усыновление бездомной пчелы, возврат домой, отдых в коробке и вылет
/datum/unit_test/ai_bee_hive_cycle/Run()
	var/mob/living/simple_animal/hostile/poison/bees/worker = allocate(/mob/living/simple_animal/hostile/poison/bees, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/controller = worker.ai_controller
	var/obj/structure/beebox/home = allocate(/obj/structure/beebox, get_step(run_loc_floor_bottom_left, EAST))
	//без сот у улья нулевая вместимость (get_max_bees) - как в игре, даём рамку
	home.honey_frames += new /obj/item/honey_frame(home)
	var/datum/ai_planning_subtree/bee_hive_cycle/hive = GLOB.ai_subtrees[/datum/ai_planning_subtree/bee_hive_cycle]

	//бездомная пчела усыновляется совместимым ульем на hive-тике
	controller.blackboard[BB_BEE_NEXT_HIVE_TICK] = null
	hive.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(worker.beehome, home, "A homeless bee must adopt the compatible beebox")
	TEST_ASSERT(worker in home.bees, "The beebox must enroll its new bee")

	//возврат домой: перелёт планируется и не отменяется, вход - легаси-процедурой
	controller.blackboard[BB_BEE_GOING_HOME] = TRUE
	controller.blackboard[BB_BEE_NEXT_HIVE_TICK] = null
	hive.SelectBehaviors(controller, 0.5)
	var/datum/ai_behavior/bee_return_home/homing = GET_AI_BEHAVIOR(/datum/ai_behavior/bee_return_home)
	TEST_ASSERT(homing in controller.current_behaviors, "The homing bee must plan its return flight")
	var/verdict = homing.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "An adjacent bee must start the legacy hive entry")
	TEST_ASSERT_EQUAL(worker.loc, home, "The bee must enter its beebox through the legacy AttackingTarget")

	//в улье: сабтри обрывает планирование и тикает счётчик отдыха
	worker.idle = 50
	controller.blackboard[BB_BEE_NEXT_HIVE_TICK] = null
	verdict = hive.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "A bee at home must not hunt or wander")
	TEST_ASSERT_EQUAL(worker.idle, 51, "Resting at home must raise the idle counter")

	//вылет: легаси drop_location возвращает пчелу на пол
	var/datum/ai_behavior/bee_emerge/wings = GET_AI_BEHAVIOR(/datum/ai_behavior/bee_emerge)
	verdict = wings.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "A rested bee must be able to emerge")
	TEST_ASSERT(isturf(worker.loc), "Emerging must drop the bee back onto the floor")
	controller.CancelActions()

///Морф: маскировка без цели, засада, раскрытие при захвате цели легаси-путём,
///холодное зрение вплотную без contact-буста
/datum/unit_test/ai_morph_ambush_disguise/Run()
	var/mob/living/simple_animal/hostile/morph/sneak = allocate(/mob/living/simple_animal/hostile/morph, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/controller = sneak.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/ambusher/morph), "A morph must migrate onto its ambusher profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy/morph, "A morph must use its no-contact-boost strategy")

	//без цели морф решает замаскироваться и принимает форму предмета рядом
	var/obj/item/wrench/prop = allocate(/obj/item/wrench, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_planning_subtree/morph_disguise/mask_tree = GLOB.ai_subtrees[/datum/ai_planning_subtree/morph_disguise]
	var/datum/ai_behavior/morph_disguise/mask = GET_AI_BEHAVIOR(/datum/ai_behavior/morph_disguise)
	var/verdict = mask_tree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "An undisguised idle morph must commit to disguising")
	TEST_ASSERT(mask in controller.current_behaviors, "The disguise behavior must be planned")
	verdict = mask.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "The morph must find something nearby to imitate")
	TEST_ASSERT(sneak.morphed, "The morph must be disguised")
	TEST_ASSERT_NOTNULL(sneak.form, "The disguise must remember the imitated atom")
	TEST_ASSERT_NOTNULL(prop, "Sanity: the prop must exist to be imitated")
	controller.CancelActions()

	//замаскированный без цели лежит в засаде: план обрывается без новых поведений
	verdict = mask_tree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "A disguised morph must lie in wait")
	TEST_ASSERT(!(mask in controller.current_behaviors), "A disguised morph must not re-disguise")

	//захват цели раскрывает маскировку легаси-путём (GiveTarget -> Aggro -> restore)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	TEST_ASSERT(!sneak.morphed, "Acquiring a target must burst the disguise through the legacy Aggro")
	TEST_ASSERT_EQUAL(sneak.vision_range, sneak.aggro_vision_range, "Combat must widen the morph's vision (legacy Aggro)")
	//в бою сабтри маскировки молчит
	mask_tree.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!(mask in controller.current_behaviors), "A fighting morph must not try to disguise")

	//потеря цели: зрение возвращается к вплотную (легаси LoseAggro), и даже
	//свежий контакт не раздувает холодный радиус приобретения
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(sneak.vision_range, 1, "Losing the target must narrow the morph's vision back (legacy LoseAggro)")
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(/datum/targeting_strategy/hostile_legacy/morph)
	controller.set_blackboard_key(BB_AI_CONTACT_TARGET, prey)
	controller.blackboard[BB_AI_LAST_SEEN_TIME] = world.time
	TEST_ASSERT(controller.has_fresh_contact(), "Sanity: the contact must be fresh")
	TEST_ASSERT_EQUAL(strategy.get_aggro_range(sneak, controller.blackboard[BB_AI_AGGRO_RANGE]), 1, "A fresh contact must not widen the morph's cold acquisition radius")
	controller.CancelActions()

// ===== SPLURT-оборотни: werewolf/the_mosley/ice_wolf/hellhound =====

///Оборотни: авто-профиль melee_chaser у всех четырёх корней, реактивный чардж
///(bullet_act) гейтит контроллер-движение и милишку, комбо-атаки делегацией
/datum/unit_test/ai_splurt_werewolf_charge_gates/Run()
	var/mob/living/simple_animal/hostile/werewolf/wolf = allocate(/mob/living/simple_animal/hostile/werewolf, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))

	//все родственные корневые типы мигрируют одним и тем же авто-профилем
	var/turf/kin_turf = get_step(run_loc_floor_bottom_left, NORTH)
	var/mob/living/simple_animal/hostile/the_mosley/mosley = allocate(/mob/living/simple_animal/hostile/the_mosley, kin_turf)
	var/mob/living/simple_animal/hostile/ice_wolf/frosty = allocate(/mob/living/simple_animal/hostile/ice_wolf, kin_turf)
	var/mob/living/simple_animal/hostile/hellhound/hound = allocate(/mob/living/simple_animal/hostile/hellhound, kin_turf)
	TEST_ASSERT(istype(wolf.ai_controller, /datum/ai_controller/hostile_adapter/melee_chaser), "A werewolf must migrate onto the melee chaser profile")
	TEST_ASSERT(istype(mosley.ai_controller, /datum/ai_controller/hostile_adapter/melee_chaser), "The Mosley must migrate onto the melee chaser profile")
	TEST_ASSERT(istype(frosty.ai_controller, /datum/ai_controller/hostile_adapter/melee_chaser), "An ice wolf must migrate onto the melee chaser profile")
	TEST_ASSERT(istype(hound.ai_controller, /datum/ai_controller/hostile_adapter/melee_chaser), "A hellhound must migrate onto the melee chaser profile")

	var/datum/ai_controller/hostile_adapter/controller = wolf.ai_controller
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy, "A werewolf must keep the plain legacy strategy")

	//штатный finder берёт жертву и зеркалирует её в легаси pawn.target
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "The finder must acquire the adjacent prey")
	TEST_ASSERT_EQUAL(wolf.target, prey, "The controller target must mirror into the legacy pawn target")

	//свой чардж (реактивный, из bullet_act): в полёте контроллер не шагает,
	//милишка не бьёт (гейты charging легаси-цикла сохранены)
	wolf.charging = TRUE
	TEST_ASSERT(!wolf.can_ai_controller_move(), "A charging werewolf must lock out controller movement")
	var/pre_charge_health = prey.health
	wolf.AttackingTarget()
	TEST_ASSERT_EQUAL(prey.health, pre_charge_health, "A charging werewolf must not land melee hits")

	//конец чарджа: под контроллером легаси Goto (walk_to) НЕ запускается -
	//преследование возобновляет штатный мувер
	wolf.charge_end()
	TEST_ASSERT(!wolf.charging, "charge_end must reset the charging state")
	TEST_ASSERT(wolf.can_ai_controller_move(), "A landed werewolf must release the movement lock")

	//friendly-режим: делегация сохраняет пацифист-гейт AttackingTarget
	wolf.werewolf_mode = "friendly"
	wolf.AttackingTarget()
	TEST_ASSERT_EQUAL(prey.health, pre_charge_health, "A friendly werewolf must never strike")

	//боевой режим: комбо-атака работает через делегацию без изменений
	wolf.werewolf_mode = "hostile"
	wolf.AttackingTarget()
	TEST_ASSERT(prey.health < pre_charge_health, "A hostile werewolf must claw through the legacy AttackingTarget")

// ===== Дефклавы: deathclaw/funclaw/капсульные петы =====

///Дефклав: авто-профиль melee_chaser, чардж-гейты как у оборотней; funclaw
///сверху - преф-гейт CanAttack делегацией и личные враги через машину обид
/datum/unit_test/ai_deathclaw_funclaw_grudges/Run()
	var/mob/living/simple_animal/hostile/deathclaw/claw = allocate(/mob/living/simple_animal/hostile/deathclaw, run_loc_floor_bottom_left)
	TEST_ASSERT(istype(claw.ai_controller, /datum/ai_controller/hostile_adapter/melee_chaser), "A deathclaw must migrate onto the melee chaser profile")

	//чардж-гейты идентичны оборотням: та же копия легаси-цикла
	claw.charging = TRUE
	TEST_ASSERT(!claw.can_ai_controller_move(), "A charging deathclaw must lock out controller movement")
	claw.charge_end()
	TEST_ASSERT(!claw.charging, "charge_end must reset the charging state")

	//funclaw: обычный человек без согласия - не цель (преф-гейт через делегацию)
	var/turf/claw_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/deathclaw/funclaw/lewdclaw = allocate(/mob/living/simple_animal/hostile/deathclaw/funclaw, claw_turf)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(claw_turf, EAST))
	var/datum/ai_controller/hostile_adapter/funclaw_controller = lewdclaw.ai_controller
	TEST_ASSERT(istype(funclaw_controller, /datum/ai_controller/hostile_adapter/melee_chaser), "A funclaw must migrate onto the melee chaser profile")
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(funclaw_controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(!strategy.can_attack(lewdclaw, victim), "A clientless bystander must be rejected by the funclaw consent gate")

	//обидчик: легаси mark_enemy_if_hurt пишет и в enemies, и в память обид
	//контроллера - скорер предпочтёт его, как легаси PickTarget
	lewdclaw.mark_enemy_if_hurt(victim, lewdclaw.health + 1)
	TEST_ASSERT(victim in lewdclaw.enemies, "A hurt funclaw must remember its personal enemy")
	TEST_ASSERT(funclaw_controller.holds_grudge_against(victim), "The personal enemy must land in the controller grudge memory")
	TEST_ASSERT(strategy.can_attack(lewdclaw, victim), "A personal enemy must become a valid funclaw target")

	//штатный finder берёт врага и зеркалирует его в легаси pawn.target
	funclaw_controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, funclaw_controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(funclaw_controller.blackboard[BB_AI_CURRENT_TARGET], victim, "The finder must acquire the personal enemy")
	TEST_ASSERT_EQUAL(lewdclaw.target, victim, "The enemy target must mirror into the legacy pawn target")

///Капсульный пет: вне приказа целей не видит вовсе, приказы хозяина
///синхронизируются в контроллер через GiveTarget/LoseTarget
/datum/unit_test/ai_capsule_pet_orders/Run()
	var/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/pet_femclaw/pet = allocate(/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/pet_femclaw, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))

	var/datum/ai_controller/hostile_adapter/controller = pet.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/melee_chaser/capsule_pet), "A pet femclaw must migrate onto the capsule pet profile")
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(istype(strategy, /datum/targeting_strategy/hostile_legacy/capsule_pet), "A capsule pet must use the live-vision strategy")

	//покой: живой vision 0 держит радиус в нуле, даже хозяин вплотную - не цель
	TEST_ASSERT_EQUAL(strategy.get_aggro_range(pet, 9), 0, "An idle pet must have a zero acquisition radius")
	TEST_ASSERT(!strategy.can_attack(pet, owner), "An idle pet must ignore even its adjacent owner")

	//приказ: зрение поднимается, цель уходит в контроллер синком GiveTarget
	pet.capsule_owner = owner
	pet.speech_buffer = "fuck me"
	pet.new_order()
	TEST_ASSERT_EQUAL(pet.vision_range, 9, "The order must raise the pet's live vision")
	TEST_ASSERT_EQUAL(strategy.get_aggro_range(pet, 9), 9, "The order must open the acquisition radius")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], owner, "The order must sync the owner into the controller target")
	TEST_ASSERT_EQUAL(pet.target, owner, "The order must keep the legacy pawn target in step")

	//отбой: зрение в ноль, цель снята и в контроллере, и в легаси
	pet.speech_buffer = "stop"
	pet.new_order()
	TEST_ASSERT_EQUAL(pet.vision_range, 0, "The stop order must blind the pet again")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "The stop order must clear the controller target")
	TEST_ASSERT_NULL(pet.target, "The stop order must clear the legacy pawn target")
	TEST_ASSERT(!strategy.can_attack(pet, owner), "A stopped pet must not re-acquire its adjacent owner")

	//остальные капсульные петы мигрируют тем же профилем
	var/turf/kennel_turf = get_step(run_loc_floor_bottom_left, NORTH)
	var/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/pet_deathclaw/kennel_claw = allocate(/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/pet_deathclaw, kennel_turf)
	var/mob/living/simple_animal/hostile/ice_wolf/funwolf/gentle/pet_ice_wolf/kennel_wolf = allocate(/mob/living/simple_animal/hostile/ice_wolf/funwolf/gentle/pet_ice_wolf, kennel_turf)
	TEST_ASSERT(istype(kennel_claw.ai_controller, /datum/ai_controller/hostile_adapter/melee_chaser/capsule_pet), "A pet deathclaw must migrate onto the capsule pet profile")
	TEST_ASSERT(istype(kennel_wolf.ai_controller, /datum/ai_controller/hostile_adapter/melee_chaser/capsule_pet), "A pet ice wolf must migrate onto the capsule pet profile")

// ===== Конструкты: боевые hostile-варианты =====

///Джаггернаут: базовый мили-профиль; фракционный гейт культа через делегацию;
///игровые оболочки (AI_OFF) остаются без контроллера, артифисер хранит support
/datum/unit_test/ai_construct_juggernaut/Run()
	var/mob/living/simple_animal/hostile/construct/armored/hostile/tank = allocate(/mob/living/simple_animal/hostile/construct/armored/hostile, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = tank.ai_controller
	TEST_ASSERT(istype(controller), "A hostile juggernaut must migrate onto the melee chaser profile")

	//цель берётся штатным поиском и зеркалируется в легаси-переменную
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "The juggernaut finder must acquire the human")
	TEST_ASSERT_EQUAL(tank.target, prey, "The target must mirror into the legacy pawn target")

	//союзный конструкт культа неприкасаем (фракционный CanAttack через делегацию)
	var/mob/living/simple_animal/hostile/construct/wraith/ally = allocate(/mob/living/simple_animal/hostile/construct/wraith, get_step(run_loc_floor_bottom_left, NORTH))
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(!strategy.can_attack(tank, ally), "A fellow cult construct must never be a target")
	TEST_ASSERT_NULL(ally.ai_controller, "A player shell construct must not get a controller")

	//AI-артифисер сохраняет свой support-профиль (регресс-гвард)
	var/turf/medic_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/construct/builder/hostile/medic = allocate(/mob/living/simple_animal/hostile/construct/builder/hostile, medic_turf)
	TEST_ASSERT(istype(medic.ai_controller, /datum/ai_controller/hostile_adapter/support/artificer), "An AI artificer must keep its support profile")

///Рейт: скиттиш-профиль "ужалил-отскочил" по легаси retreat_distance
/datum/unit_test/ai_construct_wraith_hit_and_run/Run()
	var/mob/living/simple_animal/hostile/construct/wraith/hostile/stalker = allocate(/mob/living/simple_animal/hostile/construct/wraith/hostile, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/melee_chaser/construct_wraith/controller = stalker.ai_controller
	TEST_ASSERT(istype(controller), "A hostile wraith must migrate onto its hit-and-run profile")

	//дальше поводка отхода танец молчит - работает обычная погоня hostile_melee
	var/turf/far_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, far_turf)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	var/datum/ai_planning_subtree/melee_hit_and_run/dance = GLOB.ai_subtrees[/datum/ai_planning_subtree/melee_hit_and_run]
	TEST_ASSERT_NULL(dance.SelectBehaviors(controller, 0.5), "Beyond the retreat leash the dance subtree must stay silent")
	TEST_ASSERT(!length(controller.current_behaviors), "No dance behaviors must be planned at range")

	//вплотную: жалим на месте и отскакиваем, обычная милишка не планируется
	prey.forceMove(get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT_EQUAL(dance.SelectBehaviors(controller, 0.5), SUBTREE_RETURN_FINISH_PLANNING, "In stinging range the dance must own the plan")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack/stationary) in controller.current_behaviors, "An adjacent victim must be stung in place")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/step_away) in controller.current_behaviors, "The wraith must plan its hop away")
	controller.CancelActions()

	//на дистанции 2 (внутри поводка, не вплотную) - только отскок
	prey.forceMove(locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	dance.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack/stationary) in controller.current_behaviors), "Out of arm reach there must be no sting")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/step_away) in controller.current_behaviors, "Inside the leash the wraith must keep backing away")
	controller.CancelActions()

// ===== Guardians: постоянное исключение (игровые духи-паразиты) =====

///Пин исключения (MIGRATION_EXCEPTIONS.md): холопаразиты - чисто игровые
///мобы. AIStatus = AI_OFF прямо на типе, единственный путь спавна -
///guardiancreator с гост-кандидатом (моб сразу получает key), и ни одна
///строка кластера не зовёт toggle_ai. Контроллер не аттачится (гейт
///AIStatus != AI_OFF в Initialize), в легаси-пулы моб не попадает - от
///легаси-планировщика guardians не зависят и его снос переживут.
/datum/unit_test/ai_guardian_stays_player_shell/Run()
	var/mob/living/simple_animal/hostile/guardian/punch/spirit = allocate(/mob/living/simple_animal/hostile/guardian/punch, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(spirit.ai_controller, "A guardian must not receive an adapter controller")
	TEST_ASSERT_EQUAL(spirit.AIStatus, AI_OFF, "A guardian must stay AI_OFF from birth")
	TEST_ASSERT(!(spirit in GLOB.simple_animals[AI_ON]), "A guardian must not enroll into the active legacy pool")
	TEST_ASSERT_NULL(spirit.ai_profile_type, "The guardian opt-out must stay documented as null")

	//ranged-вариант того же кластера ведёт себя одинаково
	var/mob/living/simple_animal/hostile/guardian/ranged/archer = allocate(/mob/living/simple_animal/hostile/guardian/ranged, get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT_NULL(archer.ai_controller, "A ranged guardian must not receive an adapter controller")
	TEST_ASSERT_EQUAL(archer.AIStatus, AI_OFF, "A ranged guardian must stay AI_OFF")

// ===== Herald mirror: постоянное исключение (марионетка хозяина) =====

///Пин исключения (MIGRATION_EXCEPTIONS.md): зеркало вестника не планирует
///само НИЧЕГО - toggle_ai(AI_OFF) в Initialize выводит его из легаси-пулов,
///контроллер не аттачится (ai_profile_type = null перебивает боссовый
///профиль элиток). Атаки зеркалу раздаёт хозяин: боссовые обёртки
///ai_trishot/ai_directionalshot/ai_teleshot зовут его напрямую, поэтому
///снос легаси-планировщика мост зеркалирования не заденет.
/datum/unit_test/ai_herald_mirror_stays_marionette/Run()
	var/mob/living/simple_animal/hostile/asteroid/elite/herald/prophet = allocate(/mob/living/simple_animal/hostile/asteroid/elite/herald, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))

	//хозяин - обычный мигрант боссового профиля с таблицей атак
	var/datum/ai_controller/hostile_adapter/boss/controller = prophet.ai_controller
	TEST_ASSERT(istype(controller), "The herald itself must stay on the boss profile")
	TEST_ASSERT(length(controller.blackboard[BB_AI_BOSS_ATTACKS]), "The herald must carry its boss attack table")

	//зеркало: без контроллера, AI_OFF, вне легаси-пулов
	prophet.herald_mirror()
	var/mob/living/simple_animal/hostile/asteroid/elite/herald/mirror/glass = prophet.my_mirror
	TEST_ASSERT_NOTNULL(glass, "Sanity: herald_mirror() must summon the mirror")
	TEST_ASSERT_NULL(glass.ai_controller, "The mirror must not receive an adapter controller")
	TEST_ASSERT_EQUAL(glass.AIStatus, AI_OFF, "The mirror must switch itself AI_OFF at spawn")
	TEST_ASSERT(!(glass in GLOB.simple_animals[AI_ON]), "The mirror must not enroll into the active legacy pool")

	//мост зеркалирования: боссовая обёртка хозяина стреляет и зеркалом
	prophet.GiveTarget(prey)
	var/mirror_cooldown_before = glass.ranged_cooldown
	prophet.ai_trishot()
	TEST_ASSERT(glass.ranged_cooldown > mirror_cooldown_before, "The master's boss-table attack must fire through the mirror as well")
	qdel(glass)

// ===== Иллюзии: боевые клоны и escape-приманка =====

///Боевой клон: базовый мили-профиль, спавн с целью зеркалом GiveTarget,
///размножение при ударе легаси AttackingTarget - и клон клона тоже с целью
/datum/unit_test/ai_illusion_fights_with_pinned_target/Run()
	var/mob/living/simple_animal/hostile/illusion/fake = allocate(/mob/living/simple_animal/hostile/illusion, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))

	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = fake.ai_controller
	TEST_ASSERT(istype(controller), "A combat illusion must migrate onto the base melee chaser")

	//спавн-сценарий: Copy_Parent + GiveTarget, цель уходит в блэкборд зеркалом
	fake.Copy_Parent(caster, 600, 100, 5, 100)
	fake.GiveTarget(victim)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], victim, "The spawn-time GiveTarget must mirror into the controller")

	//удар вплотную: урон и самокопия через легаси AttackingTarget делегацией
	var/datum/ai_behavior/hostile_melee_attack/gore = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	gore.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(victim.getBruteLoss() > 0, "An adjacent swing must wound the victim through the legacy delegation")
	var/mob/living/simple_animal/hostile/illusion/spawnling
	for(var/mob/living/simple_animal/hostile/illusion/candidate in get_turf(fake))
		if(candidate == fake)
			continue
		spawnling = candidate
		break
	TEST_ASSERT_NOTNULL(spawnling, "A forced multiply roll must copy the illusion")
	TEST_ASSERT(istype(spawnling.ai_controller, /datum/ai_controller/hostile_adapter/melee_chaser), "The copy must migrate onto the same profile")
	var/datum/ai_controller/hostile_adapter/spawnling_controller = spawnling.ai_controller
	TEST_ASSERT_EQUAL(spawnling_controller.blackboard[BB_AI_CURRENT_TARGET], victim, "The copy must inherit the victim as its pinned target")
	qdel(spawnling)

///Escape-приманка: профиль decoy_escape, бегство от закреплённого владельца
///внутри легаси-кольца retreat_distance = 10
/datum/unit_test/ai_illusion_escape_decoy_flees/Run()
	var/mob/living/simple_animal/hostile/illusion/escape/decoy = allocate(/mob/living/simple_animal/hostile/illusion/escape, run_loc_floor_bottom_left)
	var/turf/caster_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human, caster_turf)

	var/datum/ai_controller/hostile_adapter/decoy_escape/controller = decoy.ai_controller
	TEST_ASSERT(istype(controller), "An escape illusion must migrate onto the decoy profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_FLEE_DISTANCE], 10, "The decoy must inherit its legacy retreat ring")

	//спавн-сценарий приманки: GiveTarget(владелец) закрепляется зеркалом
	decoy.Copy_Parent(caster, 50)
	decoy.GiveTarget(caster)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], caster, "The spawn-time GiveTarget must mirror into the controller")

	//внутри кольца план - бегство retreat-поведением в сторону от владельца
	var/datum/ai_planning_subtree/flee_target/illusion_decoy/flight = GLOB.ai_subtrees[/datum/ai_planning_subtree/flee_target/illusion_decoy]
	TEST_ASSERT_EQUAL(flight.SelectBehaviors(controller, 0.5), SUBTREE_RETURN_FINISH_PLANNING, "Inside the ring the decoy must own the plan with its flight")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/run_away_from_target/retreat) in controller.current_behaviors, "The flight must use the retreat behavior that keeps the pinned target")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_RETREAT, "The flight must read as the RETREAT state")
	TEST_ASSERT_NOTNULL(controller.current_movement_target, "The flight must pick an escape turf")
	TEST_ASSERT(get_dist(caster, controller.current_movement_target) > get_dist(caster, get_turf(decoy)), "The escape turf must lie further from the pursuer")
	controller.CancelActions()

	//за кольцом сабтри молчит: приманка стоит и дразнит погоню
	controller.blackboard[BB_AI_FLEE_DISTANCE] = 2
	caster.forceMove(locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	TEST_ASSERT_NULL(flight.SelectBehaviors(controller, 0.5), "Beyond the ring the flight subtree must stay silent")
	TEST_ASSERT(!length(controller.current_behaviors), "No flight behaviors must be planned beyond the ring")

// ===== Блоб-мобы: базовый профиль + мост приказов оверлорда =====

///Спора: базовый мили-профиль, фракционный гейт делегацией, приказ Rally
///Spores приходит ТОЧКОЙ сбора (SEARCH-марш), а не GPS-целью
/datum/unit_test/ai_blobspore_base_profile_and_rally/Run()
	var/mob/living/simple_animal/hostile/blob/blobspore/spore = allocate(/mob/living/simple_animal/hostile/blob/blobspore, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = spore.ai_controller
	TEST_ASSERT(istype(controller), "A blob spore must migrate onto the base melee chaser")

	//фракция блоба через делегацию CanAttack: экипаж - цель, свои - никогда
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/simple_animal/hostile/blob/blobspore/sibling = allocate(/mob/living/simple_animal/hostile/blob/blobspore, get_step(run_loc_floor_bottom_left, NORTH))
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(strategy.can_attack(spore, prey), "A crew member must be a valid spore target")
	TEST_ASSERT(!strategy.can_attack(spore, sibling), "A fellow blob mob must never be a spore target")

	//приказ сбора: точка-улика + SEARCH-марш, живой цели приказ не даёт
	var/turf/rally_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	spore.receive_rally_order(rally_turf)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "The rally order must not hand out a live target")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_KNOWN_POS], rally_turf, "The rally order must arrive as the confirmed point")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_SEARCH, "The ordered spore must march to investigate the point")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CONTACT_SOURCE], AI_CONTACT_ALLY, "The rally must read as an allied contact")

	//независимый блоббернавт - полноценный NPC на том же базовом профиле
	var/turf/naut_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/blob/blobbernaut/independent/naut = allocate(/mob/living/simple_animal/hostile/blob/blobbernaut/independent, naut_turf)
	TEST_ASSERT(istype(naut.ai_controller, /datum/ai_controller/hostile_adapter/melee_chaser), "An independent blobbernaut must migrate onto the base melee chaser")

// ===== Space dragon: боссовый профиль без таблицы способностей =====

///Дракон: boss-профиль; огненное дыхание - легаси-сабтри boss_legacy_ranged
///делегацией OpenFire; фаза крыло-порыва запирает контроллерное движение
/datum/unit_test/ai_space_dragon_boss_profile/Run()
	var/mob/living/simple_animal/hostile/space_dragon/leviathan = allocate(/mob/living/simple_animal/hostile/space_dragon, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/boss/controller = leviathan.ai_controller
	TEST_ASSERT(istype(controller), "A space dragon must migrate onto the boss profile")
	TEST_ASSERT(!length(controller.blackboard[BB_AI_BOSS_ATTACKS]), "The dragon has no ability table: fire breath must stay on the legacy ranged subtree")

	//фаза крыло-порыва: движение контроллера заперто, как легаси Move()
	TEST_ASSERT(leviathan.can_ai_controller_move(), "A calm dragon must be free to move")
	leviathan.using_special = TRUE
	TEST_ASSERT(!leviathan.can_ai_controller_move(), "A dragon mid-gust must refuse controller movement")
	leviathan.using_special = FALSE

	//без таблицы дальний план - boss_legacy_ranged с делегацией OpenFire
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	leviathan.ranged_cooldown = 0
	var/datum/ai_planning_subtree/boss_legacy_ranged/breath = GLOB.ai_subtrees[/datum/ai_planning_subtree/boss_legacy_ranged]
	breath.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish) in controller.current_behaviors, "The tableless boss must plan its legacy ranged delegate")
	controller.CancelActions()

// ===== Mecha pilot: сабтри-делегат FSM пилотирования =====

///Пилот: угон меха пешей делегацией, оператор водит сам мех мув-лупами,
///фазовая эвакуация выбрасывает пилота и глушит лупы меха
/datum/unit_test/ai_mecha_pilot_hijack_and_operate/Run()
	var/mob/living/simple_animal/hostile/syndicate/mecha_pilot/no_mech/pilot = allocate(/mob/living/simple_animal/hostile/syndicate/mecha_pilot/no_mech, run_loc_floor_bottom_left)
	pilot.faction = list(ROLE_SYNDICATE)
	var/datum/ai_controller/hostile_adapter/mecha_pilot/controller = pilot.ai_controller
	TEST_ASSERT(istype(controller), "A mecha pilot must migrate onto its pilot profile")
	TEST_ASSERT(!controller.can_idle, "The pilot must never idle: its Moved does not fire inside a mech")

	//пеший скан: свободный заряженный мех становится целью зеркалом GiveTarget
	var/turf/mech_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/vehicle/sealed/mecha/combat/gygax/ride = allocate(/obj/vehicle/sealed/mecha/combat/gygax, mech_turf)
	TEST_ASSERT(pilot.is_valid_mecha(ride), "Sanity: a fresh gygax must be a valid theft target")
	var/datum/ai_behavior/mecha_pilot_seek_mecha/scouting = GET_AI_BEHAVIOR(/datum/ai_behavior/mecha_pilot_seek_mecha)
	var/verdict = scouting.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "The on-foot scan must spot the free mech")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], ride, "The spotted mech must mirror into the controller target")
	TEST_ASSERT_EQUAL(pilot.target, ride, "The spotted mech must mirror into the legacy pawn target")

	//вплотную милишный делегат сажает пилота в мех через легаси AttackingTarget
	pilot.forceMove(get_step(mech_turf, WEST))
	var/datum/ai_behavior/hostile_melee_attack/fists = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	fists.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(pilot.mecha, ride, "An adjacent pilot must climb in through the legacy AttackingTarget")
	TEST_ASSERT_EQUAL(pilot.loc, ride, "The pilot must live inside the mech")
	TEST_ASSERT_EQUAL(pilot.targets_from, ride, "The mech must become the pilot's attack origin")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "Entering must clear the mirrored mech target")

	//план в мехе: FSM замораживает штатные сабтри и ставит оператора
	var/datum/ai_planning_subtree/mecha_pilot_fsm/piloting = GLOB.ai_subtrees[/datum/ai_planning_subtree/mecha_pilot_fsm]
	TEST_ASSERT_EQUAL(piloting.SelectBehaviors(controller, 0.5), SUBTREE_RETURN_FINISH_PLANNING, "Inside the mech the pilot FSM must own the plan")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/mecha_pilot_operate) in controller.current_behaviors, "The in-mech plan must queue the operator")
	controller.CancelActions()

	//оператор: цель на дистанции - мех едет собственным мув-лупом
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	pilot.a_intent = INTENT_HARM //мех бьёт, а не толкает
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(strategy.can_attack(pilot, prey), "Sanity: a human must be a valid in-mech combat target")
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	var/datum/ai_behavior/mecha_pilot_operate/operating = GET_AI_BEHAVIOR(/datum/ai_behavior/mecha_pilot_operate)
	operating.perform(0.5, controller)
	var/datum/move_loop/mech_loop = ride.move_packet ? ride.move_packet.existing_loops[SSai_movement] : null
	TEST_ASSERT_NOTNULL(mech_loop, "Operating must drive the mech itself with an SSai_movement loop")

	//вплотную: mech_melee_attack через легаси AttackingTarget делегацией
	prey.forceMove(get_step(mech_turf, EAST))
	operating.perform(0.5, controller)
	TEST_ASSERT(prey.health < prey.maxHealth, "An adjacent victim must take the mech melee attack")

	//фазовая эвакуация: крит по прочности выбрасывает пилота и глушит лупы
	ride.obj_integrity = ride.max_integrity * 0.05
	operating.perform(0.5, controller)
	TEST_ASSERT_NULL(pilot.mecha, "The critical damage phase must eject the pilot")
	TEST_ASSERT(isturf(pilot.loc), "The ejected pilot must stand on a turf again")
	TEST_ASSERT(!pilot.ranged, "The ejected pilot must fall back to melee stats")
	mech_loop = ride.move_packet ? ride.move_packet.existing_loops[SSai_movement] : null
	TEST_ASSERT_NULL(mech_loop, "Ejecting must stop the mech's movement loops")
	controller.CancelActions()
