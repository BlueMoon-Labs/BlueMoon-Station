// ===== Специализированные кластеры на контроллерах =====
//
// Terror spiders (декомпозированный idle-AI), мегафауна на боссовом профиле
// с peaceful/enemies-гейтом, карпы-стайники, retaliate-гейт стратегии.

///Пробник легаси-дальнего пути для боссов без таблицы атак.
/mob/living/simple_animal/hostile/megafauna/unit_test_legacy_ranged
	ranged = TRUE
	var/open_fire_calls = 0

/mob/living/simple_animal/hostile/megafauna/unit_test_legacy_ranged/OpenFire(atom/shot_target)
	open_fire_calls++

///Пробник восприятия мегафауны: маленькие радиусы, чтобы вся геометрия
///помещалась в резервацию тестовой комнаты
/mob/living/simple_animal/hostile/megafauna/unit_test_perception
	vision_range = 2
	aggro_vision_range = 8

///Пробник восприятия рядовой роющей фауны (вотчер/голиаф/василиск): маленький
///базовый vision_range, большой aggro_vision_range и наследованный
///environment_smash = ENVIRONMENT_SMASH_WALLS от /asteroid. Радиусы малы, чтобы
///геометрия помещалась в резервацию тестовой комнаты.
/mob/living/simple_animal/hostile/asteroid/unit_test_smasher
	vision_range = 2
	aggro_vision_range = 9

///Пробник роющего СТРЕЛКА (голиаф): ENVIRONMENT_SMASH_WALLS без
///ranged_ignores_vision и с кастомным OpenFire без снаряда - ровно тот набор
///флагов, на котором геометрический гейт линии огня бессилен (он пропускает
///способности без projectiletype), так что единственной защитой остаётся LOS.
/mob/living/simple_animal/hostile/asteroid/unit_test_smasher/ranged
	ranged = TRUE
	var/open_fire_calls = 0

/mob/living/simple_animal/hostile/asteroid/unit_test_smasher/ranged/OpenFire(atom/shot_target)
	open_fire_calls++

///Тот же стрелок, но с легаси-правом бить вслепую (мегафауна, лавалендские элитки)
/mob/living/simple_animal/hostile/asteroid/unit_test_smasher/ranged/blind
	ranged_ignores_vision = TRUE

/mob/living/simple_animal/hostile/unit_test_rapid_melee
	rapid_melee = 16
	var/unit_test_attacks = 0

/mob/living/simple_animal/hostile/unit_test_rapid_melee/AttackingTarget()
	unit_test_attacks++
	return TRUE

/datum/unit_test_enemy_qdel_mutator

/datum/unit_test_enemy_qdel_mutator/proc/unregister_during_qdel(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)

///Terror spider получает свой профиль, скорер и политику препятствий
/datum/unit_test/ai_terror_spider_profile/Run()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/spider = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight)

	var/datum/ai_controller/hostile_adapter/terror_spider/controller = spider.ai_controller
	TEST_ASSERT(istype(controller), "A terror spider must possess the terror profile controller")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGET_SCORER], /datum/target_scorer/terror_spider, "The terror profile must use the terror scorer")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy, "Terrors are aggressive: no retaliate gate")

///Разбивание ламп: сабтри гейтится каденсом, поведение бьёт лампу рядом
/datum/unit_test/ai_terror_break_lights/Run()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/spider = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight)
	var/datum/ai_controller/controller = spider.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: the spider must have a controller")

	var/obj/machinery/light/lamp = new(get_step(run_loc_floor_bottom_left, EAST))
	lamp.status = LIGHT_OK
	spider.forceMove(run_loc_floor_bottom_left)
	spider.last_break_light = 0 //каденс истёк

	var/datum/ai_behavior/terror_break_light/smasher = GET_AI_BEHAVIOR(/datum/ai_behavior/terror_break_light)
	var/verdict = smasher.perform(0.5, controller)

	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "The spider must smash an intact adjacent light")
	TEST_ASSERT(spider.last_break_light > 0, "Smashing must reset the light-break cadence")
	qdel(lamp)

///Паутина: кладётся на пустой турф, не дублируется
/datum/unit_test/ai_terror_spin_webs/Run()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/spider = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight)
	var/datum/ai_controller/controller = spider.ai_controller
	spider.forceMove(run_loc_floor_bottom_left)
	spider.web_type = /obj/structure/spider/terrorweb
	spider.last_spins_webs = 0

	var/datum/ai_behavior/terror_spin_web/spinner = GET_AI_BEHAVIOR(/datum/ai_behavior/terror_spin_web)
	var/first_verdict = spinner.perform(0.5, controller)
	var/obj/structure/spider/terrorweb/web = locate() in run_loc_floor_bottom_left
	var/second_verdict = spinner.perform(0.5, controller)

	TEST_ASSERT(first_verdict & AI_BEHAVIOR_SUCCEEDED, "The first spin must lay a web")
	TEST_ASSERT_NOTNULL(web, "The web must exist on the spider's turf")
	TEST_ASSERT(second_verdict & AI_BEHAVIOR_FAILED, "A second spin on the same turf must refuse")
	qdel(web)

///Мегафауна: боссовый профиль + enemies-гейт после первого удара
///(субъект - легион: обычная фракция mining/boss; lesser drake нарочно neutral)
/datum/unit_test/ai_megafauna_boss_profile/Run()
	var/mob/living/simple_animal/hostile/megafauna/legion/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/legion)
	var/mob/living/carbon/human/first_prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))

	var/datum/ai_controller/hostile_adapter/boss/controller = boss_mob.ai_controller
	TEST_ASSERT(istype(controller), "Megafauna must possess the boss profile controller")
	TEST_ASSERT(controller.cross_dangerous_turfs, "A boss must not fear lava")
	TEST_ASSERT(!controller.can_idle, "A boss must not sleep")

	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(istype(strategy, /datum/targeting_strategy/hostile_legacy/ignore_sight/megafauna), "Megafauna must use the enemies-gated strategy")

	//без enemies босс агрессивен ко всем
	TEST_ASSERT(strategy.can_attack(boss_mob, first_prey), "With no enemies the boss must be free-aggressive")
	//после удара - только обидчики
	boss_mob.add_enemy(first_prey)
	TEST_ASSERT(strategy.can_attack(boss_mob, first_prey), "The attacker must remain a valid target")
	TEST_ASSERT(!strategy.can_attack(boss_mob, bystander), "With enemies recorded, bystanders must be filtered out")

///Погибший обидчик мегафауны остаётся целью, хотя его уже нет в living-only гриде
/datum/unit_test/ai_megafauna_dead_enemy_acquisition/Run()
	var/mob/living/simple_animal/hostile/megafauna/legion/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/legion)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	boss_mob.forceMove(run_loc_floor_bottom_left)

	var/datum/ai_controller/hostile_adapter/boss/controller = boss_mob.ai_controller
	boss_mob.add_enemy(attacker)
	attacker.death()

	var/list/grid_targets = SSspatial_grid.orthogonal_range_search(boss_mob, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, boss_mob.aggro_vision_range)
	TEST_ASSERT(!(attacker in grid_targets), "Sanity: a dead attacker must be absent from the living-only target grid")
	TEST_ASSERT(bystander in grid_targets, "Sanity: the living bystander must remain in the target grid")

	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/verdict = finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)

	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "Megafauna must acquire its dead personal enemy outside the living-only grid")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], attacker, "The dead attacker must be selected instead of a living bystander")

///Personal aggro follows a player mind into the replacement body created by respawn.
/datum/unit_test/ai_hostile_grudge_follows_mind_transfer/Run()
	var/mob/living/simple_animal/hostile/megafauna/legion/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/legion, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/old_body = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	old_body.mind_initialize()

	var/datum/ai_controller/hostile_adapter/boss/controller = boss_mob.ai_controller
	boss_mob.add_enemy(old_body)
	boss_mob.GiveTarget(old_body)
	var/datum/mind/player_mind = old_body.mind
	player_mind.transfer_to(new_body)

	TEST_ASSERT(!(old_body in boss_mob.enemies), "The abandoned body must leave the personal enemy list")
	TEST_ASSERT(new_body in boss_mob.enemies, "The replacement body must inherit the personal grudge")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], new_body, "The boss must immediately pursue the replacement body")
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(strategy.can_attack(boss_mob, new_body), "The enemies-gated boss strategy must accept the respawned player")

///Без обидчиков мегафауна замечает цели только в своём живом vision_range,
///а не в полном профильном радиусе aggro_vision_range
/datum/unit_test/ai_megafauna_unprovoked_vision_range/Run()
	var/mob/living/simple_animal/hostile/megafauna/unit_test_perception/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/unit_test_perception, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)

	var/datum/ai_controller/hostile_adapter/boss/controller = boss_mob.ai_controller
	TEST_ASSERT(istype(controller), "Sanity: the perception probe must possess the boss profile controller")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_AGGRO_RANGE], 8, "Sanity: the profile acquisition radius must come from aggro_vision_range")

	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "An unprovoked boss must not acquire a target beyond its live vision_range")

	//живое значение: расширенное зрение сразу расширяет и обнаружение
	boss_mob.vision_range = 6
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "A prey inside the live vision_range must be acquired")

///Без обидчиков мегафауна обязана видеть цель (LOS), сквозь стены она
///преследует только записанных врагов
/datum/unit_test/ai_megafauna_unprovoked_los_gate/Run()
	var/mob/living/simple_animal/hostile/megafauna/unit_test_perception/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/unit_test_perception, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/turf/wall_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)
	boss_mob.vision_range = 6

	var/datum/ai_controller/hostile_adapter/boss/controller = boss_mob.ai_controller
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/atom/unprovoked_pick = controller.blackboard[BB_AI_CURRENT_TARGET]

	//обидчик преследуется и без прямой видимости
	boss_mob.add_enemy(prey)
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/atom/grudge_pick = controller.blackboard[BB_AI_CURRENT_TARGET]

	wall_turf.ChangeTurf(saved_turf_type)
	TEST_ASSERT_NULL(unprovoked_pick, "An unprovoked boss must not acquire a target hidden behind a wall")
	TEST_ASSERT_EQUAL(grudge_pick, prey, "A recorded enemy must be pursued through the wall")

///Рядовая роющая фауна (environment_smash) замечает цель только в СВОЁМ живом
///vision_range, а не в раздутом max(vision, aggro_vision). Легаси-паритет:
///обнаружение шло через hearers(vision_range); aggro_vision_range расширял радиус
///только ПОСЛЕ агра (Aggro() поднимал vision_range). Регресс: вотчер (vision 2,
///aggro 9) агрился через полэкрана.
/datum/unit_test/ai_smasher_unprovoked_vision_range/Run()
	var/mob/living/simple_animal/hostile/asteroid/unit_test_smasher/beast = allocate(/mob/living/simple_animal/hostile/asteroid/unit_test_smasher, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)

	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(beast)
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(istype(strategy, /datum/targeting_strategy/hostile_legacy/ignore_sight), "Sanity: a wall-smasher must use the ignore_sight strategy")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_AGGRO_RANGE], 9, "Sanity: the cached profile radius must be max(vision, aggro_vision)")

	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "An unprovoked smasher must not detect prey beyond its live vision_range, even though aggro_vision reaches it")

	//живое расширение зрения (как Aggro()) сразу расширяет и обнаружение
	beast.vision_range = 6
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "Prey inside the live vision_range must be acquired")

	qdel(controller)

///Рядовая роющая фауна обязана ВИДЕТЬ цель (LOS), чтобы её приобрести: стена
///блокирует холодное приобретение так же, как легаси hearers(). Сквозь стены
///смэшер ведёт только уже приобретённую цель (environment_smash-преследование).
/datum/unit_test/ai_smasher_unprovoked_los_gate/Run()
	var/mob/living/simple_animal/hostile/asteroid/unit_test_smasher/beast = allocate(/mob/living/simple_animal/hostile/asteroid/unit_test_smasher, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/turf/wall_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)
	beast.vision_range = 6 //дальности хватает - барьером остаётся только стена

	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(beast)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/atom/cold_pick = controller.blackboard[BB_AI_CURRENT_TARGET]

	//приобретённую цель смэшер держит и ведёт сквозь стену
	beast.GiveTarget(prey)
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/atom/engaged_pick = controller.blackboard[BB_AI_CURRENT_TARGET]

	wall_turf.ChangeTurf(saved_turf_type)
	TEST_ASSERT_NULL(cold_pick, "An unprovoked smasher must require LOS to acquire, not see the prey through the wall")
	TEST_ASSERT_EQUAL(engaged_pick, prey, "An already-engaged smasher must pursue its target through the wall")

	qdel(controller)

///Стрелок-ломатель стен обязан ВИДЕТЬ цель, чтобы выстрелить по ней. Легаси
///разделял два разных разрешения: environment_smash давал право ПРЕСЛЕДОВАТЬ
///цель без прямой видимости (MoveToTarget: Goto + FindHidden, стрельбы в той
///ветке не было), и только ranged_ignores_vision давал право СТРЕЛЯТЬ вслепую.
///Контроллер склеил их в один ignores_sight, и голиаф (SMASH_WALLS, но не
///ranged_ignores_vision) начал класть щупальца сквозь стену, держа жертву
///в стан-локе до смерти.
/datum/unit_test/ai_ranged_smasher_wall_gate/Run()
	var/mob/living/simple_animal/hostile/asteroid/unit_test_smasher/ranged/beast = allocate(/mob/living/simple_animal/hostile/asteroid/unit_test_smasher/ranged, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/turf/wall_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)
	beast.vision_range = 6 //дальности хватает - барьером остаётся только стена

	var/datum/ai_controller/hostile_adapter/controller = beast.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: the ranged smasher must possess a hostile adapter")
	controller.set_ai_status(AI_STATUS_OFF) //стреляем только руками теста, без гонки с планировщиком
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(istype(strategy, /datum/targeting_strategy/hostile_legacy/ignore_sight), "Sanity: a wall-smasher must keep the ignore_sight pursuit strategy")

	//цель уже приобретена: смэшер ведёт её сквозь стену, но стрелять не должен
	beast.GiveTarget(prey)
	TEST_ASSERT(strategy.ignores_sight(beast), "Sanity: an engaged smasher must still pursue without line of sight")

	var/datum/ai_behavior/ranged_skirmish/gun = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)
	gun.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, AI_RANGED_MAX_FIRE_RANGE, 2)
	var/shots_through_wall = beast.open_fire_calls

	wall_turf.ChangeTurf(saved_turf_type)
	beast.ranged_cooldown = 0
	gun.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, AI_RANGED_MAX_FIRE_RANGE, 2)
	var/shots_in_the_open = beast.open_fire_calls

	TEST_ASSERT_EQUAL(shots_through_wall, 0, "A wall-smasher without ranged_ignores_vision must not fire at a target behind a wall")
	TEST_ASSERT_EQUAL(shots_in_the_open, 1, "The same smasher must fire once the wall is gone")

///Легаси-паритет обратной стороны: ranged_ignores_vision (мегафауна, элитки)
///обязан продолжать добивать цель сквозь стену - гейт выше не должен их задеть.
/datum/unit_test/ai_ranged_blind_fire_preserved/Run()
	var/mob/living/simple_animal/hostile/asteroid/unit_test_smasher/ranged/blind/beast = allocate(/mob/living/simple_animal/hostile/asteroid/unit_test_smasher/ranged/blind, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/turf/wall_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)
	beast.vision_range = 6

	var/datum/ai_controller/hostile_adapter/controller = beast.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: the blind-firing smasher must possess a hostile adapter")
	controller.set_ai_status(AI_STATUS_OFF)
	beast.GiveTarget(prey)

	var/datum/ai_behavior/ranged_skirmish/gun = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)
	gun.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, AI_RANGED_MAX_FIRE_RANGE, 2)
	var/blind_shots = beast.open_fire_calls

	wall_turf.ChangeTurf(saved_turf_type)
	TEST_ASSERT_EQUAL(blind_shots, 1, "ranged_ignores_vision must keep firing through the wall, as the legacy loop did")

///Инвариант щупалец голиафа: кулдаун между щупальцами обязан быть строго
///длиннее самого долгого стана захвата. Задержка всплытия одинакова у обоих
///щупалец и из неравенства сокращается, поэтому окно на действие = кулдаун
///минус стан. При кулдауне <= стана следующее щупальце приземляется, пока
///жертва ещё лежит, Stun() обновляется на полную длительность - и цепочка
///держит жертву до смерти без единого тика на ответ.
/datum/unit_test/goliath_tentacle_leaves_action_window/Run()
	var/longest_stun = max(\
		(/obj/effect/temp_visual/goliath_tentacle)::grab_stun,\
		(/obj/effect/temp_visual/goliath_tentacle)::grab_stun_armored,\
		(/obj/effect/temp_visual/goliath_tentacle)::grab_stun_vulnerable)
	TEST_ASSERT(longest_stun > 0, "Sanity: the tentacle must actually stun its victim")

	for(var/mob/living/simple_animal/hostile/asteroid/goliath/breed as anything in typesof(/mob/living/simple_animal/hostile/asteroid/goliath))
		var/cooldown = initial(breed.ranged_cooldown_time)
		TEST_ASSERT(cooldown > longest_stun, "[breed] plants a tentacle every [cooldown] ds but holds its victim for up to [longest_stun] ds - the chain never releases")

///Права на снос турфов обязаны проверяться в самом CanSmashTurfs: легаси-путь
///DestroyObjectsInDirection бьёт по его ответу, а attack_animal стены играет
///анимацию удара ДО проверки прав. Без гейта моб со SMASH_STRUCTURES бесконечно
///молотил стену без единицы урона.
/datum/unit_test/mob_smash_rights_gate_turfs/Run()
	var/mob/living/simple_animal/hostile/structures_only = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/asteroid/unit_test_smasher/wall_breaker = allocate(/mob/living/simple_animal/hostile/asteroid/unit_test_smasher, run_loc_floor_bottom_left)
	var/wall_x = run_loc_floor_bottom_left.x + 2
	var/wall_y = run_loc_floor_bottom_left.y
	var/wall_z = run_loc_floor_bottom_left.z
	var/turf/wall_loc = locate(wall_x, wall_y, wall_z)
	var/saved_turf_type = wall_loc.type

	TEST_ASSERT(structures_only.environment_smash & ENVIRONMENT_SMASH_STRUCTURES, "Sanity: the plain hostile must smash structures")
	TEST_ASSERT(!(structures_only.environment_smash & (ENVIRONMENT_SMASH_WALLS|ENVIRONMENT_SMASH_RWALLS)), "Sanity: the plain hostile must have no wall rights")
	TEST_ASSERT(wall_breaker.environment_smash & ENVIRONMENT_SMASH_WALLS, "Sanity: the asteroid smasher must have wall rights")

	wall_loc.ChangeTurf(/turf/closed/wall)
	var/turf/plain_wall = locate(wall_x, wall_y, wall_z)
	var/structures_only_verdict = structures_only.CanSmashTurfs(plain_wall)
	var/wall_breaker_verdict = wall_breaker.CanSmashTurfs(plain_wall)

	plain_wall.ChangeTurf(/turf/closed/wall/r_wall)
	var/turf/reinforced_wall = locate(wall_x, wall_y, wall_z)
	var/wall_breaker_rwall_verdict = wall_breaker.CanSmashTurfs(reinforced_wall)

	reinforced_wall.ChangeTurf(saved_turf_type)

	TEST_ASSERT(!structures_only_verdict, "A structures-only smasher must not report a wall as breakable")
	TEST_ASSERT(wall_breaker_verdict, "A wall smasher must still report a plain wall as breakable")
	TEST_ASSERT(!wall_breaker_rwall_verdict, "ENVIRONMENT_SMASH_WALLS must not cover reinforced walls")

///Стена обязана пережить первый удар ломателя. Мгновенный dismantle_wall(1)
///читался игроками как "голиаф сносит стену касанием" и обесценивал любой
///построенный загон; теперь стена копит урон и рушится, исчерпав запас.
/datum/unit_test/wall_takes_several_mob_hits/Run()
	var/mob/living/simple_animal/hostile/asteroid/goliath/breaker = allocate(/mob/living/simple_animal/hostile/asteroid/goliath, run_loc_floor_bottom_left)
	var/wall_x = run_loc_floor_bottom_left.x + 2
	var/wall_y = run_loc_floor_bottom_left.y
	var/wall_z = run_loc_floor_bottom_left.z
	var/turf/wall_loc = locate(wall_x, wall_y, wall_z)
	var/saved_turf_type = wall_loc.type
	wall_loc.ChangeTurf(/turf/closed/wall)

	var/turf/closed/wall/standing = locate(wall_x, wall_y, wall_z)
	TEST_ASSERT(istype(standing), "Sanity: the test turf must have become a wall")
	TEST_ASSERT(breaker.obj_damage > 0, "Sanity: a goliath must deal object damage")
	TEST_ASSERT(breaker.obj_damage < standing.mob_damage_cap, "One smasher hit must not cover the whole reserve of a wall")

	//бьём, пока стена не рухнет; потолок цикла - страховка от бесконечности
	var/hits_taken = 0
	while(hits_taken < 20)
		var/turf/current_turf = locate(wall_x, wall_y, wall_z)
		if(!iswallturf(current_turf))
			break
		var/turf/closed/wall/target_wall = current_turf
		target_wall.take_mob_smash_damage(breaker)
		hits_taken++

	var/turf/aftermath = locate(wall_x, wall_y, wall_z)
	var/wall_still_standing = iswallturf(aftermath)
	aftermath.ChangeTurf(saved_turf_type)

	TEST_ASSERT(!wall_still_standing, "Sustained smasher hits must still bring the wall down")
	TEST_ASSERT(hits_taken > 1, "A wall must survive the first smasher hit; it fell after [hits_taken]")

///Peaceful-мегафауна (гладиатор) без записанных обидчиков не трогает никого
/datum/unit_test/ai_megafauna_peaceful_gate/Run()
	var/mob/living/simple_animal/hostile/megafauna/unit_test_perception/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/unit_test_perception, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))

	TEST_ASSERT(initial((/mob/living/simple_animal/hostile/megafauna/gladiator)::peaceful), "Sanity: the gladiator must start peaceful")

	var/datum/ai_controller/hostile_adapter/boss/controller = boss_mob.ai_controller
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	boss_mob.peaceful = TRUE

	TEST_ASSERT(!strategy.can_attack(boss_mob, prey), "A peaceful boss with no recorded enemies must not attack anyone")

	//арена/удар записывают обидчика - он становится единственной законной целью
	boss_mob.add_enemy(prey)
	TEST_ASSERT(strategy.can_attack(boss_mob, prey), "A peaceful boss must attack its recorded enemy")
	TEST_ASSERT(!strategy.can_attack(boss_mob, bystander), "A peaceful boss must still ignore bystanders")

	//потеря peaceful (урон) возвращает обычную агрессию
	boss_mob.remove_enemy(prey)
	boss_mob.peaceful = FALSE
	TEST_ASSERT(strategy.can_attack(boss_mob, prey), "A provoked boss must return to normal aggression")

///Богиня финальной комнаты гейта Killthemall неприкосновенна, пока её не тронут:
///карточный AIStatus = AI_Z_OFF контроллерный моб не читает, гейт живёт на типе
/datum/unit_test/ai_gate_goddess_starts_peaceful/Run()
	var/mob/living/simple_animal/hostile/megafauna/sand/goddess = allocate(/mob/living/simple_animal/hostile/megafauna/sand, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/looter = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))

	TEST_ASSERT(goddess.peaceful, "The gate goddess must spawn peaceful")

	var/datum/ai_controller/hostile_adapter/boss/controller = goddess.ai_controller
	TEST_ASSERT(istype(controller), "The gate goddess must possess the boss profile controller")

	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(!strategy.can_attack(goddess, looter), "The gate goddess must ignore anyone who has not touched her")

	goddess.add_enemy(looter)
	TEST_ASSERT(strategy.can_attack(goddess, looter), "The gate goddess must strike back at whoever touched her")

///Чардж-свинг гладиатора по уже потерянной цели не должен звать Bump(null)
/datum/unit_test/ai_gladiator_charge_swing_lost_target/Run()
	var/mob/living/simple_animal/hostile/megafauna/gladiator/gladiator = allocate(/mob/living/simple_animal/hostile/megafauna/gladiator, run_loc_floor_bottom_left)
	gladiator.charging = TRUE
	gladiator.target = null
	gladiator.AttackingTarget()
	TEST_ASSERT(gladiator.charging, "A charge swing with no target must not discharge through a null Bump")
	TEST_ASSERT(!gladiator.teleport(null), "A post-attack teleport must reject a target cleared by the melee hit")

///The target may be deleted during the teleport smoke telegraph.
/datum/unit_test/ai_gladiator_teleport_qdeleted_target/Run()
	var/mob/living/simple_animal/hostile/megafauna/gladiator/gladiator = allocate(/mob/living/simple_animal/hostile/megafauna/gladiator, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/turf/start_turf = get_turf(gladiator)

	INVOKE_ASYNC(gladiator, TYPE_PROC_REF(/mob/living/simple_animal/hostile/megafauna/gladiator, teleport), prey)
	sleep(1)
	qdel(prey)
	sleep(4)
	TEST_ASSERT_EQUAL(get_turf(gladiator), start_turf, "Gladiator teleported after its target was deleted during the telegraph")

///Retaliate() вербует только реальных участников боя рядом: базовый радиус,
///без своей фракции; прямых атакеров и так флагают attacked_by/bullet_act
/datum/unit_test/ai_megafauna_retaliation_scope/Run()
	var/mob/living/simple_animal/hostile/megafauna/unit_test_perception/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/unit_test_perception, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/brawler = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/turf/bystander_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, bystander_turf)
	var/mob/living/simple_animal/hostile/fauna = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, NORTH))
	fauna.faction = boss_mob.faction.Copy()
	var/turf/ally_turf = locate(run_loc_floor_bottom_left.x, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/megafauna/unit_test_perception/ally = allocate(/mob/living/simple_animal/hostile/megafauna/unit_test_perception, ally_turf)

	//боевое состояние: Aggro() расширил зрение до aggro_vision_range
	boss_mob.Aggro()
	TEST_ASSERT_EQUAL(boss_mob.vision_range, 8, "Sanity: an aggroed boss must see at its aggro_vision_range")
	boss_mob.Retaliate()

	TEST_ASSERT(brawler in boss_mob.enemies, "A combatant next to the boss must be recorded as an enemy")
	TEST_ASSERT(!(bystander in boss_mob.enemies), "A bystander beyond the base vision_range must not be recorded")
	TEST_ASSERT(!(fauna in boss_mob.enemies), "Same-faction fauna must not be recorded as an enemy")
	TEST_ASSERT(!(ally in boss_mob.enemies), "An allied boss must never be recorded as an enemy")
	TEST_ASSERT(brawler in ally.enemies, "A nearby allied boss must inherit the real grudge")
	TEST_ASSERT(!(bystander in ally.enemies), "A nearby allied boss must not inherit bystanders")

///Watcher должен держать дистанцию, а не автоматически переходить в профиль мили-добивания
/datum/unit_test/ai_watcher_ranged_profile/Run()
	var/mob/living/simple_animal/hostile/asteroid/basilisk/watcher/watcher = allocate(/mob/living/simple_animal/hostile/asteroid/basilisk/watcher)
	var/datum/ai_controller/hostile_adapter/ranged_skirmisher/controller = watcher.ai_controller

	TEST_ASSERT(istype(controller), "A watcher must use the ranged skirmisher profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_MIN_DISTANCE], 3, "A watcher must retreat inside three tiles")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_MAX_DISTANCE], 5, "A watcher must pursue only beyond five tiles")

///Watchers are flying, lava-immune lavaland mobs. Their controller must not
///treat the lava they spawn beside as an impassable pursuit boundary.
/datum/unit_test/ai_watcher_can_pursue_across_lava/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/lava_turf = get_step(start_turf, EAST)
	var/saved_turf_type = lava_turf.type
	lava_turf.ChangeTurf(/turf/open/lava)
	lava_turf = get_step(start_turf, EAST)

	var/mob/living/simple_animal/hostile/asteroid/basilisk/watcher/watcher = allocate(/mob/living/simple_animal/hostile/asteroid/basilisk/watcher, start_turf)
	var/datum/ai_controller/hostile_adapter/ranged_skirmisher/controller = watcher.ai_controller
	TEST_ASSERT(HAS_TRAIT(watcher, TRAIT_LAVA_IMMUNE), "Sanity: a watcher must inherit lavaland lava immunity")
	TEST_ASSERT(controller.can_enter_dangerous_turf(lava_turf), "A watcher must treat lava as traversable")
	TEST_ASSERT(controller.can_enter_turf(lava_turf), "The complete tactical turf gate must admit a watcher over lava")

	lava_turf.ChangeTurf(saved_turf_type)

///Скирмишер отходит, пока есть РЕАЛЬНЫЙ отход (тайл строго дальше от угроз),
///но дерётся, когда зажат. Равноудалённый боковой тайл отходом не считается:
///это пляска у стены, из-за которой зажатый стрелок не атаковал вовсе.
/datum/unit_test/ai_watcher_cornered_melee_fallback/Run()
	var/mob/living/simple_animal/hostile/asteroid/basilisk/watcher/watcher = allocate(/mob/living/simple_animal/hostile/asteroid/basilisk/watcher, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/hostile_adapter/ranged_skirmisher/controller = watcher.ai_controller
	controller.CancelActions()
	controller.planned_behaviors.Cut()
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_planning_subtree/maintain_distance/maintain = GLOB.ai_subtrees[/datum/ai_planning_subtree/maintain_distance]
	var/datum/ai_planning_subtree/hostile_melee_when_cornered/fallback = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_melee_when_cornered]
	var/datum/ai_behavior/step_away/retreat = GET_AI_BEHAVIOR(/datum/ai_behavior/step_away)
	var/datum/ai_behavior/hostile_melee_attack/melee = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)

	//открытое поле: тайл строго дальше от жертвы существует - отходим, не деремся
	maintain.SelectBehaviors(controller, 0.5)
	fallback.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(controller.planned_behaviors[retreat], "A watcher with a genuine escape tile must plan a retreat")
	TEST_ASSERT(!controller.planned_behaviors[melee], "A watcher must not replace a viable retreat with melee")

	controller.CancelActions()
	controller.planned_behaviors.Cut()
	//полная блокада: все семь свободных сторон заняты плотными мобами
	for(var/direction in GLOB.alldirs)
		if(direction == EAST)
			continue
		allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, direction))
	maintain.SelectBehaviors(controller, 0.5)
	fallback.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!controller.planned_behaviors[retreat], "A watcher must reject escape tiles occupied by dense mobs")
	TEST_ASSERT(controller.planned_behaviors[melee], "A fully cornered watcher must defend itself in melee")

///Hierophant и другие боссы без новой таблицы сохраняют legacy OpenFire вдали.
/datum/unit_test/ai_boss_legacy_ranged_fallback/Run()
	var/mob/living/simple_animal/hostile/megafauna/unit_test_legacy_ranged/boss = allocate(/mob/living/simple_animal/hostile/megafauna/unit_test_legacy_ranged, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/ai_controller/hostile_adapter/boss/controller = boss.ai_controller
	controller.CancelActions()
	controller.planned_behaviors.Cut()
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	TEST_ASSERT(!length(controller.blackboard[BB_AI_BOSS_ATTACKS]), "Sanity: the probe boss must not have a new attack table")
	var/datum/ai_planning_subtree/boss_legacy_ranged/legacy_ranged = GLOB.ai_subtrees[/datum/ai_planning_subtree/boss_legacy_ranged]
	legacy_ranged.SelectBehaviors(controller, 0.5)

	var/datum/ai_behavior/ranged_skirmish/ranged_attack = GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)
	TEST_ASSERT(controller.planned_behaviors[ranged_attack], "A ranged boss without an attack table must plan legacy OpenFire")
	var/verdict = ranged_attack.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, INFINITY, 2)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "The legacy ranged behavior must execute successfully")
	TEST_ASSERT_EQUAL(boss.open_fire_calls, 1, "The legacy ranged behavior must call the boss OpenFire exactly once")

///Карпы - стайники: профиль pack_hunter с call_reinforcements
///
///И, главное, с милишным хвостом. Профиль был копией дальнобойного набора: цель движения
///мили-пауну ставит только hostile_melee, поэтому карпы агрились, звали стаю и стояли на месте.
///Прод-раунд 9832: ~38 карпов дали 7 атак за смену, мегакарп 54 минуты эмоутил "gnashes at" с
///одной клетки. Проверяем не список сабтри, а факт: планировщик обязан выдать мили-атаку и цель
///движения по цели в трёх клетках.
/datum/unit_test/ai_carp_pack_profile/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/carp/fish = allocate(/mob/living/simple_animal/hostile/carp, floor)
	var/datum/ai_controller/hostile_adapter/pack_hunter/controller = fish.ai_controller
	TEST_ASSERT(istype(controller), "Carp must school on the pack_hunter profile")
	TEST_ASSERT(GLOB.ai_subtrees[/datum/ai_planning_subtree/call_reinforcements] in controller.planning_subtrees, "The pack profile must include reinforcements")

	var/turf/prey_turf = locate(floor.x + 3, floor.y, floor.z)
	TEST_ASSERT_NOTNULL(prey_turf, "Нет турфа для жертвы - тест ничего не проверяет")
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)

	controller.blackboard[BB_AI_CURRENT_TARGET] = prey
	// Холодное обнаружение обязано отыграть паузу ALERT, бой начинается только со второго
	// прохода планировщика - иначе тест проверял бы состояние, в котором мили не планируется
	// никогда, ни до правки, ни после.
	drive_ai_planning(controller)
	controller.blackboard[BB_AI_STATE_ENTERED_AT] = world.time - AI_ALERT_REACTION_TIME - 1
	drive_ai_planning(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ENGAGE, "FSM обязан войти в бой - тест ничего не проверяет")

	var/datum/ai_behavior/melee = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	TEST_ASSERT(controller.planned_behaviors[melee], "Стайный мили-моб обязан планировать милишную атаку по цели в трёх клетках, иначе он только агрится и стоит")
	TEST_ASSERT_NOTNULL(controller.current_movement_target, "Мили-атака обязана задать цель движения - без неё карп не подходит к жертве")

///Дальнобойный сородич в том же стайном профиле обязан остаться кайтером: мили-хвост
///pack_hunter гейтится melee_only, иначе магикарп после выстрела полез бы в упор.
/datum/unit_test/ai_pack_ranged_stays_ranged/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/carp/ranged/magicarp = allocate(/mob/living/simple_animal/hostile/carp/ranged, floor)
	var/datum/ai_controller/hostile_adapter/controller = magicarp.ai_controller
	TEST_ASSERT(istype(controller), "У магикарпа нет контроллера - тест ничего не проверяет")
	TEST_ASSERT(magicarp.ranged, "Магикарп обязан быть дальнобойным - тест ничего не проверяет")

	var/turf/prey_turf = locate(floor.x + 3, floor.y, floor.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)

	controller.blackboard[BB_AI_CURRENT_TARGET] = prey
	// Тот же прогон через ALERT в бой, что и у мили-сородича: иначе ассерт "мили не планируется"
	// прошёл бы вакуумно, просто потому что до боя дело не дошло.
	drive_ai_planning(controller)
	controller.blackboard[BB_AI_STATE_ENTERED_AT] = world.time - AI_ALERT_REACTION_TIME - 1
	drive_ai_planning(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ENGAGE, "FSM обязан войти в бой - тест ничего не проверяет")

	var/datum/ai_behavior/melee = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	TEST_ASSERT(!controller.planned_behaviors[melee], "Дальнобойный паун не имеет права планировать милишную атаку из стайного профиля")

///Семейные профили не должны затирать ranged-флаг сабтипов.
/datum/unit_test/ai_mixed_family_ranged_subtypes/Run()
	var/mob/living/simple_animal/hostile/carp/ranged/magicarp = allocate(/mob/living/simple_animal/hostile/carp/ranged, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/ai_controller/hostile_adapter/pack_hunter/carp_controller = magicarp.ai_controller
	carp_controller.CancelActions()
	carp_controller.planned_behaviors.Cut()
	carp_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_planning_subtree/ranged_skirmish/ranged_subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/ranged_skirmish]
	ranged_subtree.SelectBehaviors(carp_controller, 0.5)
	TEST_ASSERT(carp_controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)], "A ranged carp must keep its ranged attack inside the pack profile")

	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/builder/builder = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/builder, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/terror_spider/spider_controller = builder.ai_controller
	spider_controller.CancelActions()
	spider_controller.planned_behaviors.Cut()
	spider_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	ranged_subtree.SelectBehaviors(spider_controller, 0.5)
	TEST_ASSERT(spider_controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/ranged_skirmish)], "A ranged terror spider must keep its ranged attack inside the terror profile")

///search_objects-мобы сохраняют легаси-поиск предметов рядом.
/datum/unit_test/ai_search_objects_acquisition/Run()
	var/mob/living/simple_animal/hostile/asteroid/gutlunch/scavenger = allocate(/mob/living/simple_animal/hostile/asteroid/gutlunch, run_loc_floor_bottom_left)
	var/obj/effect/decal/cleanable/blood/gibs/food = allocate(/obj/effect/decal/cleanable/blood/gibs, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/controller = scavenger.ai_controller
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)

	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/verdict = finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "A search_objects hostile must acquire a nearby wanted object")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], food, "The wanted object must become the controller target")

///Plague rat использует целевой vent-профиль и ищет маршрут только к дальней цели.
/datum/unit_test/ai_target_aware_vent_profile/Run()
	var/mob/living/simple_animal/hostile/plaguerat/rat = allocate(/mob/living/simple_animal/hostile/plaguerat, run_loc_floor_bottom_left)
	var/turf/target_turf = locate(run_loc_floor_bottom_left.x + 12, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, target_turf)
	var/datum/ai_controller/hostile_adapter/vent_hunter/controller = rat.ai_controller
	TEST_ASSERT(istype(controller), "Plague rats must use the target-aware vent hunter profile")
	controller.CancelActions()
	controller.planned_behaviors.Cut()
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	var/datum/ai_planning_subtree/opportunistic_ventcrawler/venting = GLOB.ai_subtrees[/datum/ai_planning_subtree/opportunistic_ventcrawler]
	venting.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(controller.planned_behaviors[GET_AI_BEHAVIOR(/datum/ai_behavior/find_targeted_vent_route)], "A far target must trigger connected entry/exit route search")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_VENT_FINAL_TARGET], prey, "The combat target must anchor exit selection")

///Retaliate-гейт: гусь не трогает чужих без обиды, обида включает агро и будит
/datum/unit_test/ai_retaliate_gate/Run()
	var/mob/living/simple_animal/hostile/retaliate/grudger = allocate(/mob/living/simple_animal/hostile/retaliate)
	var/mob/living/simple_animal/hostile/carp/stranger = allocate(/mob/living/simple_animal/hostile/carp)
	register_fake_player(stranger, get_turf(stranger))

	var/datum/ai_controller/controller = grudger.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: retaliate mob must be migrated")
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(istype(strategy, /datum/targeting_strategy/hostile_legacy/retaliate), "Retaliate mobs must use the enemies-gated strategy")

	TEST_ASSERT(!strategy.can_attack(grudger, stranger), "Without a grudge the retaliate mob must not target even foreign factions")

	if(controller.ai_status != AI_STATUS_IDLE)
		controller.set_ai_status(AI_STATUS_IDLE)
	grudger.add_enemy(stranger)
	TEST_ASSERT(strategy.can_attack(grudger, stranger), "A grudge must make the enemy targetable")
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "A new grudge must wake the sleeping controller")
	unregister_fake_player(stranger)

///Controller rapid melee is cadence-controlled and must not fan out timer callbacks.
/datum/unit_test/ai_rapid_melee_timer_backpressure/Run()
	var/mob/living/simple_animal/hostile/unit_test_rapid_melee/controller_mob = allocate(/mob/living/simple_animal/hostile/unit_test_rapid_melee, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/controller = controller_mob.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: rapid melee test mob must have a controller")
	controller_mob.target = prey
	controller_mob.MeleeAction(FALSE)

	TEST_ASSERT_EQUAL(controller_mob.unit_test_attacks, 1, "A controller pass must execute one attack, not an entire delayed burst")
	TEST_ASSERT_NULL(controller_mob.rapid_melee_timer_id, "Controller rapid melee must not create a timer")
	TEST_ASSERT_EQUAL(controller_mob.rapid_melee_attacks_left, 0, "Controller rapid melee must not retain a legacy burst")
	var/datum/ai_behavior/hostile_melee_attack/melee_behavior = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	TEST_ASSERT_EQUAL(melee_behavior.get_cooldown(controller), max(world.tick_lag, SSnpcpool.wait * AI_MELEE_CADENCE_SCALE / controller_mob.rapid_melee), "Rapid melee cadence must be represented by the behavior cooldown")

	controller_mob.rapid = 3
	controller_mob.OpenFire(prey)
	TEST_ASSERT_NOTNULL(controller_mob.rapid_fire_timer_id, "A rapid volley must own one stoppable timer")
	TEST_ASSERT_EQUAL(controller_mob.rapid_fire_shots_left, controller_mob.rapid, "The one volley timer must own all remaining shots")
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[controller_mob.rapid_fire_timer_id], "The rapid-fire timer must be registered for cleanup")
	var/rapid_fire_timer_id = controller_mob.rapid_fire_timer_id
	controller_mob.OpenFire(prey)
	TEST_ASSERT_EQUAL(controller_mob.rapid_fire_timer_id, rapid_fire_timer_id, "A repeated ranged action must not overlap a second volley")
	controller_mob.cancel_rapid_fire_sequence()

/// Damage and rapid attacks may call GainPatience several times in one tick.
/// They must extend one long timeout instead of replacing its timer each time.
/datum/unit_test/ai_patience_timer_backpressure/Run()
	var/mob/living/simple_animal/hostile/hostile_mob = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	hostile_mob.target = prey
	hostile_mob.GainPatience()
	var/first_timer_id = hostile_mob.lose_patience_timer_id
	TEST_ASSERT_NOTNULL(first_timer_id, "The first patience refresh must create a stoppable timer")
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[first_timer_id], "The patience timer must be registered for cleanup")

	hostile_mob.GainPatience()
	TEST_ASSERT_EQUAL(hostile_mob.lose_patience_timer_id, first_timer_id, "Same-tick patience refreshes must reuse the existing timer")
	hostile_mob.LoseTarget()
	TEST_ASSERT_NULL(hostile_mob.lose_patience_timer_id, "Losing the target must clear the patience timer id")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[first_timer_id], "Losing the target must remove the patience timer")

///Retaliation still shares enemies, while one ally coalesces the whole damage burst.
/datum/unit_test/ai_retaliate_group_scan_coalesces/Run()
	var/mob/living/simple_animal/hostile/retaliate/leader = allocate(/mob/living/simple_animal/hostile/retaliate, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/retaliate/ally = allocate(/mob/living/simple_animal/hostile/retaliate, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	leader.add_enemy(attacker)
	leader.Retaliate()

	TEST_ASSERT(attacker in ally.enemies, "A visible same-faction retaliate ally must inherit the leader's enemy")
	TEST_ASSERT(ally.next_retaliation_scan >= leader.next_retaliation_scan, "The ally must reuse the completed group scan during the same damage burst")
	TEST_ASSERT(leader.next_retaliation_scan >= world.time + 4 SECONDS, "Supplementary retaliation discovery must coalesce sustained damage for about five seconds")

/// Megafauna has a separate retaliation implementation: a boss group must
/// share one bounded scan instead of rescanning and re-adding every grudge.
/datum/unit_test/ai_megafauna_retaliate_group_scan_coalesces/Run()
	var/mob/living/simple_animal/hostile/megafauna/leader = allocate(/mob/living/simple_animal/hostile/megafauna, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/megafauna/ally = allocate(/mob/living/simple_animal/hostile/megafauna, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	leader.add_enemy(attacker)
	leader.Retaliate()

	TEST_ASSERT(attacker in ally.enemies, "A visible same-faction megafauna ally must inherit the leader's enemy")
	TEST_ASSERT(ally.next_retaliation_scan >= leader.next_retaliation_scan, "A megafauna ally must reuse the completed group scan during the same damage burst")
	TEST_ASSERT(leader.next_retaliation_scan >= world.time + 4 SECONDS, "Megafauna retaliation discovery must coalesce sustained damage for about five seconds")

///Deleting a shared enemy must synchronously clear every hostile holder.
/datum/unit_test/ai_retaliate_shared_enemy_qdel/Run()
	var/mob/living/simple_animal/hostile/syndicate/ranged/shotgun/space/stormtrooper/anthro/enemy = new(run_loc_floor_bottom_left)
	// Reproduce another cleanup listener mutating the emitter's listener list
	// before the 25 retaliate callbacks have all been dispatched.
	var/datum/unit_test_enemy_qdel_mutator/mutator = new
	mutator.RegisterSignal(enemy, COMSIG_PARENT_QDELETING, TYPE_PROC_REF(/datum/unit_test_enemy_qdel_mutator, unregister_during_qdel))
	var/list/mob/living/simple_animal/hostile/holders = list()
	for(var/i in 1 to 25)
		var/mob/living/simple_animal/hostile/megafauna/holder = allocate(/mob/living/simple_animal/hostile/megafauna, run_loc_floor_bottom_left)
		holder.add_enemy(enemy)
		holders += holder

	qdel(enemy)
	for(var/mob/living/simple_animal/hostile/holder as anything in holders)
		TEST_ASSERT(!(enemy in holder.enemies), "A qdeleted shared enemy must leave every hostile enemies list")
	qdel(mutator)

///Дальность преследования тянется от aggro range, но радиус поиска пути от него НЕ раздувается:
///дальнюю цель добираем дешёвым bee-line, а JPS держим на проверенном дефолте.
/datum/unit_test/ai_megafauna_range_contract/Run()
	var/mob/living/simple_animal/hostile/megafauna/legion/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/legion)
	var/datum/ai_controller/hostile_adapter/boss/controller = boss_mob.ai_controller
	var/detect_range = max(boss_mob.vision_range, boss_mob.aggro_vision_range)

	TEST_ASSERT(controller.max_target_distance >= detect_range, "The controller must not abandon targets inside the pawn's aggro range")
	TEST_ASSERT_EQUAL(controller.max_path_length, AI_MAX_PATH_LENGTH, "A long sight line must not inflate the pathfinding search radius into pathological open-terrain searches")

///Honour guard наследует retaliate технически, но по legacy Found() агрессивна.
/datum/unit_test/ai_honour_guard_stays_aggressive/Run()
	var/mob/living/simple_animal/hostile/retaliate/goat/guard/guard = allocate(/mob/living/simple_animal/hostile/retaliate/goat/guard)
	var/datum/ai_controller/hostile_adapter/guard_defender/aggressive_retaliate/controller = guard.ai_controller
	TEST_ASSERT(istype(controller), "An honour guard must use the territorial guard profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy, "An honour guard must use aggressive targeting despite its retaliate parent")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_HOME_TURF], get_turf(guard), "The guard profile must remember its home turf")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_PACK_ROLE], AI_ROLE_GUARD, "The guard profile must advertise its group role")

	var/turf/outside_leash = locate(run_loc_floor_bottom_left.x + 6, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/intruder = allocate(/mob/living/carbon/human, outside_leash)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, intruder)
	var/datum/ai_planning_subtree/hostile_fsm/fsm = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]
	var/verdict = fsm.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(verdict & SUBTREE_RETURN_FINISH_PLANNING, "A territorial guard must stop combat planning for a target outside its leash")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "A territorial guard must drop a target outside its home leash")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_GUARD, "Dropping an out-of-territory target must return the guard to guard state")

///Падальщик получает не только scorer, но и реальный coward-профиль.
/datum/unit_test/ai_gutlunch_coward_scavenger_profile/Run()
	var/mob/living/simple_animal/hostile/asteroid/gutlunch/scavenger = allocate(/mob/living/simple_animal/hostile/asteroid/gutlunch)
	var/datum/ai_controller/hostile_adapter/coward_scavenger/controller = scavenger.ai_controller
	TEST_ASSERT(istype(controller), "Gutlunch must use the coward/scavenger profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGET_SCORER], /datum/target_scorer/prefer_vulnerable, "A scavenger must prefer vulnerable prey")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_PACK_ROLE], AI_ROLE_SCAVENGER, "A scavenger must advertise its group role")

///Закрытый crate-мимик не просыпается через комнату, но trigger снимает гейт.
/datum/unit_test/ai_mimic_ambush_profile/Run()
	var/mob/living/simple_animal/hostile/mimic/crate/mimic = allocate(/mob/living/simple_animal/hostile/mimic/crate, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/ai_controller/hostile_adapter/ambusher/mimic/controller = mimic.ai_controller
	TEST_ASSERT(istype(controller), "A crate mimic must use the ambusher profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_AGGRO_RANGE], 1, "A disguised crate must preserve its one-tile legacy wake range")

	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/verdict = finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT(verdict & AI_BEHAVIOR_FAILED, "A closed mimic must ignore prey two tiles away")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "A closed mimic must remain disguised without a nearby target")

	mimic.GiveTarget(prey)
	TEST_ASSERT(mimic.attempt_open, "Acquiring a controller target must trigger the crate disguise")
	TEST_ASSERT(controller.blackboard[BB_AI_AGGRO_RANGE] > 1, "A triggered mimic must restore its normal pursuit range")

///Creator exclusion moved from ListTargets into CanAttack, which the grid strategy uses.
/datum/unit_test/ai_mimic_copy_creator_gate/Run()
	var/mob/living/carbon/human/creator = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	var/obj/item/crowbar/source_object = allocate(/obj/item/crowbar, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/mimic/copy/copied = allocate(/mob/living/simple_animal/hostile/mimic/copy, run_loc_floor_bottom_left, source_object, creator)
	var/datum/ai_controller/hostile_adapter/adaptive_hunter/controller = copied.ai_controller
	TEST_ASSERT(istype(controller), "A copied mimic must use the runtime-adaptive hunter profile")
	TEST_ASSERT(!copied.CanAttack(creator), "A copied mimic must never target its creator through grid acquisition")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_PACK_ROLE], AI_ROLE_AMBUSHER, "A copied mimic must advertise its ambusher role")

///Два artificer не толкаются за одного союзника: задача резервируется и
///передаётся следующему только после удара/освобождения.
/datum/unit_test/ai_artificer_support_reservations/Run()
	var/turf/target_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/turf/second_turf = get_step(target_turf, EAST)
	var/mob/living/simple_animal/hostile/construct/builder/hostile/first = allocate(/mob/living/simple_animal/hostile/construct/builder/hostile, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/construct/builder/hostile/second = allocate(/mob/living/simple_animal/hostile/construct/builder/hostile, second_turf)
	var/mob/living/simple_animal/hostile/construct/armored/hostile/wounded = allocate(/mob/living/simple_animal/hostile/construct/armored/hostile, target_turf)
	wounded.adjustHealth(15)

	var/datum/ai_controller/hostile_adapter/support/artificer/first_controller = first.ai_controller
	var/datum/ai_controller/hostile_adapter/support/artificer/second_controller = second.ai_controller
	TEST_ASSERT(istype(first_controller) && istype(second_controller), "Hostile artificers must use the support profile")
	TEST_ASSERT_EQUAL(first_controller.blackboard[BB_AI_PACK_ROLE], AI_ROLE_SUPPORT, "Artificers must advertise their support role")

	var/datum/ai_planning_subtree/support_repair_construct/support = GLOB.ai_subtrees[/datum/ai_planning_subtree/support_repair_construct]
	support.SelectBehaviors(first_controller, 0.5)
	support.SelectBehaviors(second_controller, 0.5)
	TEST_ASSERT_EQUAL(first_controller.task_reservation?.target, wounded, "The first artificer must reserve the wounded ally")
	TEST_ASSERT_NULL(second_controller.task_reservation, "A second artificer must not duplicate an occupied repair task")

	var/health_before = wounded.health
	var/datum/ai_behavior/support_repair_construct/repair = GET_AI_BEHAVIOR(/datum/ai_behavior/support_repair_construct)
	var/verdict = repair.perform(0.5, first_controller, BB_AI_SUPPORT_TARGET)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "An adjacent artificer must execute its repair")
	TEST_ASSERT(wounded.health > health_before, "The support action must restore construct health")
	repair.finish_action(first_controller, TRUE, BB_AI_SUPPORT_TARGET)

	support.SelectBehaviors(second_controller, 0.5)
	TEST_ASSERT_EQUAL(second_controller.task_reservation?.target, wounded, "The repair reservation must hand off after the first action finishes")

// ===== Curseblob: закреплённая жертва проклятия =====

///Curseblob на адаптере: жертва жёстко закреплена, движение - собственный
///телепорт-цикл (легаси move_loop), милишка - делегатом MeleeAction.
/datum/unit_test/ai_curseblob_pinned_pursuit/Run()
	var/turf/spawn_turf = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(spawn_turf, NORTH))
	var/mob/living/simple_animal/hostile/asteroid/curseblob/blob = allocate(/mob/living/simple_animal/hostile/asteroid/curseblob, spawn_turf)

	var/datum/ai_controller/hostile_adapter/curseblob/controller = blob.ai_controller
	TEST_ASSERT(istype(controller), "A curseblob must possess the curseblob profile controller")
	TEST_ASSERT(!controller.can_idle, "A curse missile must never idle: its victim can leave the wake window")

	//спавн-путь проклятия: set_target + GiveTarget() закрепляют жертву и запускают легаси-цикл
	blob.set_target = victim
	blob.GiveTarget()
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], victim, "GiveTarget must pin the cursed victim into the blackboard")
	TEST_ASSERT(blob.doing_move_loop, "GiveTarget must start the legacy teleport-step loop")
	TEST_ASSERT_EQUAL(get_dist(blob, victim), 2, "The legacy loop must have teleport-stepped towards the victim")

	//стратегия закреплённой цели: никого, кроме собственной жертвы
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	TEST_ASSERT(istype(strategy, /datum/targeting_strategy/curseblob_victim), "The curseblob must use the pinned-victim strategy")
	TEST_ASSERT(strategy.can_attack(blob, victim), "The pinned victim must be attackable")
	TEST_ASSERT(!strategy.can_attack(blob, bystander), "A bystander must never become a curseblob target")
	TEST_ASSERT(strategy.ignores_sight(blob), "The curse must track its victim through walls, like the legacy loop")

	//план: единственное поведение - сабтри-делегат преследования
	drive_ai_planning(controller)
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/curseblob_pursuit) in controller.current_behaviors, "The plan must queue the pursuit delegate")

	//закрепление восстанавливается, даже если блэкборд насильно очистили
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
	var/datum/ai_behavior/curseblob_pursuit/pursuit = GET_AI_BEHAVIOR(/datum/ai_behavior/curseblob_pursuit)
	pursuit.perform(0.5, controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], victim, "The pursuit delegate must re-pin the cursed victim")

	//вплотную делегат бьёт через легаси MeleeAction/AttackingTarget
	blob.forceMove(get_step(run_loc_floor_bottom_left, EAST))
	var/health_before = victim.health
	pursuit.perform(0.5, controller)
	TEST_ASSERT(victim.health < health_before, "An adjacent pursuit tick must damage the victim through the legacy attack chain")
	TEST_ASSERT(blob.in_melee, "Melee pursuit must set the legacy in_melee flag")

///Curseblob исчезает вместе с потерянной жертвой (легаси check_for_target),
///но qdel пауна уходит на таймер, а не рвёт цикл контроллера изнутри.
/datum/unit_test/ai_curseblob_expires_with_victim/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/asteroid/curseblob/blob = allocate(/mob/living/simple_animal/hostile/asteroid/curseblob, get_step(run_loc_floor_bottom_left, EAST))
	blob.set_target = victim
	blob.GiveTarget()

	var/datum/ai_controller/hostile_adapter/curseblob/controller = blob.ai_controller
	victim.set_stat(UNCONSCIOUS)
	var/datum/ai_behavior/curseblob_pursuit/pursuit = GET_AI_BEHAVIOR(/datum/ai_behavior/curseblob_pursuit)
	var/verdict = pursuit.perform(0.5, controller)
	TEST_ASSERT(verdict & AI_BEHAVIOR_FAILED, "Pursuit of an unconscious victim must fail")
	TEST_ASSERT(!QDELETED(blob), "The pawn must not be deleted synchronously from its own perform")
	//растворение висит на addtimer: ждём проход SStimer, а не один деци
	wait_for_qdeleted(blob)
	TEST_ASSERT(QDELETED(blob), "Losing the victim must dissolve the curseblob via the legacy check")

// ===== Goldgrub: трусливый рудоед =====

///Голдграб находит руду штатным find_potential_targets (search_objects-путь)
///и ест её вплотную через легаси AttackingTarget/EatOre.
/datum/unit_test/ai_goldgrub_hunts_ore/Run()
	var/mob/living/simple_animal/hostile/asteroid/goldgrub/grub = allocate(/mob/living/simple_animal/hostile/asteroid/goldgrub, run_loc_floor_bottom_left)
	grub.will_burrow = FALSE //герметичность: без таймера самоудаления посреди сюиты
	var/turf/ore_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/item/stack/ore/gold/nugget = allocate(/obj/item/stack/ore/gold, ore_turf)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	register_fake_player(fake_player, locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y + 4, run_loc_floor_bottom_left.z))
	fake_player.status_flags |= GODMODE //будит контроллер, но сам не цель

	var/datum/ai_controller/hostile_adapter/coward_scavenger/goldgrub/controller = grub.ai_controller
	TEST_ASSERT(istype(controller), "A goldgrub must use the goldgrub coward-scavenger profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_FLEE_DISTANCE], 10, "The profile must keep the legacy 10-tile flee distance")
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_RETREAT_HEALTH_FRAC], "Goldgrub fear is target-typed, not health-gated")

	drive_ai_planning(controller)
	controller.process(0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], nugget, "The target finder must acquire ore through the search_objects path")
	TEST_ASSERT_EQUAL(grub.target, nugget, "The ore target must mirror into the legacy pawn target")

	//вплотную милишный делегат ест руду легаси-цепочкой
	grub.forceMove(get_step(ore_turf, WEST))
	var/loot_before = length(grub.loot)
	var/datum/ai_behavior/hostile_melee_attack/jaws = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	jaws.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(QDELETED(nugget), "An adjacent bite must swallow the ore stack whole")
	TEST_ASSERT(length(grub.loot) > loot_before, "Swallowed ore must land in the legacy loot belly")

	unregister_fake_player(fake_player)

///Живой противник обращает голдграба в бегство (легаси-испуг GiveTarget),
///а не в бой; руда бегства не вызывает.
/datum/unit_test/ai_goldgrub_flees_living/Run()
	var/mob/living/simple_animal/hostile/asteroid/goldgrub/grub = allocate(/mob/living/simple_animal/hostile/asteroid/goldgrub, run_loc_floor_bottom_left)
	grub.will_burrow = FALSE
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/datum/ai_controller/hostile_adapter/coward_scavenger/goldgrub/controller = grub.ai_controller

	//удар: возмездие фокусит обидчика, легаси-GiveTarget включает испуг
	grub.RetaliateAgainst(attacker)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], attacker, "Retaliation must focus the attacker")
	TEST_ASSERT_EQUAL(grub.target, attacker, "The attacker must mirror into the legacy target")
	TEST_ASSERT_EQUAL(grub.retreat_distance, 10, "The legacy GiveTarget fright plumbing must still fire")
	TEST_ASSERT_EQUAL(grub.vision_range, grub.aggro_vision_range, "Fright must Aggro the grub up to its alert vision")

	//решение: бегство с обрывом боевого планирования, не милишка
	var/datum/ai_planning_subtree/flee_target/goldgrub/flee = GLOB.ai_subtrees[/datum/ai_planning_subtree/flee_target/goldgrub]
	var/verdict = flee.SelectBehaviors(controller, 0.5)
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "A living target must divert planning into flight")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_RETREAT, "Flight must read as the RETREAT state")

	//полный план: милишная атака по живой цели не ставится вовсе
	drive_ai_planning(controller)
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack) in controller.current_behaviors), "A frightened grub must not plan melee against a living target")

	//руда бегства не вызывает
	var/obj/item/stack/ore/gold/nugget = allocate(/obj/item/stack/ore/gold, get_step(run_loc_floor_bottom_left, EAST))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, nugget)
	TEST_ASSERT_NULL(flee.SelectBehaviors(controller, 0.5), "An ore target must not trigger flight")

// ===== Gorilla: мили-громила =====

///Горилла: базовый мили-чейзер по авто-настройке адаптера; проверки
///конечностей/оружия остаются в её легаси CanAttack/AttackingTarget.
/datum/unit_test/ai_gorilla_melee_chaser/Run()
	var/mob/living/simple_animal/hostile/gorilla/ape = allocate(/mob/living/simple_animal/hostile/gorilla, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = ape.ai_controller
	TEST_ASSERT(istype(controller), "A gorilla must migrate onto the melee chaser profile")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy/ignore_sight, "A wall-smasher must keep pursuing an acquired target through walls")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_OBSTACLE_POLICY], /datum/obstacle_policy, "A wall-smasher must use the full obstacle policy")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGET_SCORER], /datum/target_scorer/prefer_vulnerable, "stat_attack UNCONSCIOUS must select the vulnerable-prey scorer")

	//легаси CanAttack работает через стратегию: обезьяны исключены
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	var/mob/living/carbon/monkey/monkey = allocate(/mob/living/carbon/monkey, get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT(!strategy.can_attack(ape, monkey), "The legacy monkey exclusion must gate grid acquisition")
	TEST_ASSERT(strategy.can_attack(ape, prey), "A human must remain a valid gorilla target")

	//полный цикл: планировщик находит цель и зеркалирует её в pawn.target
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	register_fake_player(fake_player, locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y + 4, run_loc_floor_bottom_left.z))
	fake_player.status_flags |= GODMODE //будит контроллер, но сам не цель

	drive_ai_planning(controller)
	controller.process(0.5)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "Target search must acquire the human")
	TEST_ASSERT_EQUAL(ape.target, prey, "The target must mirror into the legacy pawn target")

	//ALERT-пауза отыграна - FSM входит в бой и ставит милишный план
	drive_ai_planning(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ALERT, "A cold acquisition must pass through the ALERT pause")
	controller.blackboard[BB_AI_STATE_ENTERED_AT] = world.time - AI_ALERT_REACTION_TIME - 1
	drive_ai_planning(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_STATE], AI_STATE_ENGAGE, "The FSM must engage the acquired human")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack) in controller.current_behaviors, "A melee plan must be queued")

	unregister_fake_player(fake_player)

///Familiar-горилла выключена сценарием и контроллер не получает
/datum/unit_test/ai_gorilla_familiar_stays_off/Run()
	var/mob/living/simple_animal/hostile/gorilla/familiar/pet = allocate(/mob/living/simple_animal/hostile/gorilla/familiar)
	TEST_ASSERT_NULL(pet.ai_controller, "An AI_OFF familiar gorilla must not receive a controller")
	TEST_ASSERT_EQUAL(pet.AIStatus, AI_OFF, "A familiar gorilla must remain AI_OFF")

///Характер особи: пресеты состоятельны, и два разных характера действительно
///дают разное решение при одинаковом состоянии. Вся вариативность поведения до
///этого была на уровне ТИПА - каждый экземпляр вёл себя одинаково.
/datum/unit_test/ai_temperament_presets_shift_decisions/Run()
	for(var/temperament_type in GLOB.ai_temperament_weights)
		var/datum/ai_temperament/preset = get_ai_temperament(temperament_type)
		TEST_ASSERT_NOTNULL(preset, "Каждый пресет характера обязан инстанцироваться: [temperament_type]")
		TEST_ASSERT(preset.retreat_threshold_mult > 0, "[preset.name]: множитель порога отступления обязан быть положительным")
		TEST_ASSERT(preset.alert_pause_mult > 0, "[preset.name]: множитель паузы обнаружения обязан быть положительным")
		TEST_ASSERT(preset.pursuit_mult > 0, "[preset.name]: множитель погони обязан быть положительным")
		TEST_ASSERT(preset.dodge_mult > 0, "[preset.name]: множитель уворота обязан быть положительным")
		TEST_ASSERT_EQUAL(get_ai_temperament(temperament_type), preset, "Характеры обязаны быть синглтонами")

	//сам ролл обязан давать тип из пула (в тестах get_temperament намеренно
	//возвращает нейтральный характер, поэтому ролл проверяется отдельно)
	for(var/attempt in 1 to 20)
		TEST_ASSERT(pickweight(GLOB.ai_temperament_weights) in GLOB.ai_temperament_weights, "Ролл характера обязан давать тип из пула")

	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(hunter)
	var/datum/ai_planning_subtree/hostile_fsm/fsm = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]

	//точка взятия цели на дистанции между поводками робкого и упрямого
	var/leash_gap = round(AI_PURSUIT_LEASH * 0.75)
	var/far_x = (pawn_turf.x > leash_gap) ? (pawn_turf.x - leash_gap) : (pawn_turf.x + leash_gap)
	var/turf/origin = locate(far_x, pawn_turf.y, pawn_turf.z)
	TEST_ASSERT_NOTNULL(origin, "Санити: точка отсчёта погони обязана существовать")
	controller.blackboard[BB_AI_PURSUIT_ORIGIN] = origin
	controller.blackboard[BB_AI_LAST_EXCHANGE_AT] = world.time

	controller.temperament = get_ai_temperament(/datum/ai_temperament/skittish)
	TEST_ASSERT(fsm.should_abandon_pursuit(controller), "Робкая особь на этой дистанции обязана бросить погоню")

	controller.temperament = get_ai_temperament(/datum/ai_temperament/stubborn)
	TEST_ASSERT(!fsm.should_abandon_pursuit(controller), "Упрямая особь на той же дистанции обязана гнаться дальше")

	qdel(controller)

///Фоновая рутина выбирается по тому, что это за моб, а не одна на всех.
/datum/unit_test/ai_idle_routine_matches_mob_kind/Run()
	var/mob/living/simple_animal/hostile/subject = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)

	subject.mob_biotypes = MOB_ORGANIC|MOB_BUG
	TEST_ASSERT_EQUAL(ai_idle_routine_for(subject), /datum/idle_behavior/idle_random_walk/hostile_ambience/flocking, "Рой обязан держаться стаи")

	subject.mob_biotypes = MOB_ORGANIC|MOB_BEAST
	subject.mob_size = MOB_SIZE_SMALL
	TEST_ASSERT_EQUAL(ai_idle_routine_for(subject), /datum/idle_behavior/idle_random_walk/hostile_ambience/skittish, "Мелочь обязана суетиться рывками")

	subject.mob_size = MOB_SIZE_LARGE
	subject.melee_damage_upper = AI_GRAZER_MELEE_DAMAGE
	TEST_ASSERT_EQUAL(ai_idle_routine_for(subject), /datum/idle_behavior/idle_random_walk/hostile_ambience/grazing, "Безобидное крупное животное обязано пастись")

	subject.melee_damage_upper = 20
	TEST_ASSERT_EQUAL(ai_idle_routine_for(subject), /datum/idle_behavior/idle_random_walk/hostile_ambience/denning, "Хищник обязан держаться логова")

///Стайный idle реально тянется к сородичу за комфортным радиусом. Радиус поиска
///обязан быть шире комфортного: дефолтный спейсинг-радиус (2) меньше комфортных
///(3), и с ним любой найденный сородич уже был "в стае" - ветка притяжения не
///срабатывала никогда, рутина молча вырождалась в случайный шаг.
/datum/unit_test/ai_flocking_pulls_toward_distant_ally/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/bug = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/turf/mate_turf = locate(pawn_turf.x + AI_FLOCK_COMFORT_RADIUS + 1, pawn_turf.y, pawn_turf.z)
	TEST_ASSERT_NOTNULL(mate_turf, "Санити: тестовой карте не хватило места для сородича за комфортным радиусом")
	var/mob/living/simple_animal/hostile/flockmate = allocate(/mob/living/simple_animal/hostile, mate_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(bug)
	var/datum/ai_controller/unit_test_hunter/mate_controller = new(flockmate)

	var/datum/idle_behavior/idle_random_walk/hostile_ambience/flocking/routine = new
	TEST_ASSERT_EQUAL(routine.pick_idle_direction(bug, controller), EAST, "Сородич за комфортным радиусом обязан притягивать стайного моба")

	qdel(routine)
	qdel(mate_controller)
	qdel(controller)

///Боевая адаптация: серия ударов, не снявшая с цели ничего, помечает её
///непробиваемой, и погоня по такой цели прекращается. Броня, которую моб
///физически не пробивает, - причина, по которой фауна часами грызла скафандр.
/datum/unit_test/ai_marks_impervious_target_after_futile_hits/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/biter = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/mob/living/carbon/human/armored = allocate(/mob/living/carbon/human, get_step(pawn_turf, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(biter)

	//удары идут, здоровье цели не меняется
	for(var/attempt in 1 to AI_FUTILE_HITS_THRESHOLD + 1)
		controller.note_melee_attempt(armored)
	TEST_ASSERT(controller.blackboard[BB_AI_TARGET_IMPERVIOUS_UNTIL] > world.time, "Серия бесполезных ударов обязана пометить цель непробиваемой")

	var/datum/ai_planning_subtree/hostile_fsm/fsm = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, armored)
	controller.blackboard[BB_AI_PURSUIT_ORIGIN] = pawn_turf
	controller.blackboard[BB_AI_LAST_EXCHANGE_AT] = world.time
	TEST_ASSERT(fsm.should_abandon_pursuit(controller), "Непробиваемая цель обязана прекращать погоню, даже если моб рядом с домом")

	//пометка адресная: второй противник без брони не наследует чужую непробиваемость
	var/mob/living/carbon/human/second_attacker = allocate(/mob/living/carbon/human, get_step(pawn_turf, NORTH))
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, second_attacker)
	TEST_ASSERT(!fsm.should_abandon_pursuit(controller), "Непробиваемость доказана про конкретную цель и не должна усмирять моба против новой")
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, armored)

	//настоящее попадание обнуляет счёт: цель снова стоит усилий
	controller.blackboard[BB_AI_TARGET_IMPERVIOUS_UNTIL] = 0
	controller.note_melee_attempt(armored)
	armored.adjustBruteLoss(10)
	controller.note_melee_attempt(armored)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_FUTILE_HITS], 0, "Успешный удар обязан обнулять счёт бесполезных")

	qdel(controller)

///Быстрая потеря здоровья за короткое окно поднимает порог отступления на
///стычку: моб перестаёт одинаково лезть под кулаки и под дробовик.
/datum/unit_test/ai_danger_signal_raises_retreat_threshold/Run()
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/datum/ai_controller/unit_test_hunter/controller = new(victim)
	var/datum/ai_planning_subtree/hostile_fsm/fsm = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]

	//первый проход только снимает эталон
	fsm.update_combat_signals(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_SELF_HEALTH], victim.health, "Первый проход обязан снять эталон здоровья")
	TEST_ASSERT(!(controller.blackboard[BB_AI_DANGER_UNTIL] > world.time), "Без потери здоровья вывода об опасности быть не может")

	victim.adjustBruteLoss(victim.maxHealth * (AI_DANGER_HEALTH_FRAC + 0.1))
	fsm.update_combat_signals(controller)
	TEST_ASSERT(controller.blackboard[BB_AI_DANGER_UNTIL] > world.time, "Быстрая просадка здоровья обязана включать вывод об опасности")

	qdel(controller)
