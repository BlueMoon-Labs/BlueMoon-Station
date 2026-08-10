// ===== Детерминированный headless-бенчмарк систем мобов =====
//
// Фиксированная арена 24x24 на отдельной резервации + синхронные полные пассы
// SSmobs, legacy NPC, controller AI, spatial targeting и JPS с измерением CPU
// (TICK_USAGE), native proc-profile и счётчиков /datum/ai_metrics. Пишет один
// versioned JSON-отчёт в data/mob_benchmark_v3.json с per-pass samples и
// median/p95/p99.
// Ассерты здесь - только инварианты семантики
// (что именно молотит/спит легаси-путь), не скорость.
//
// Детерминизм: rand_seed на входе каждого сценария; внутри сценария нет
// sleep(), поэтому MC не интерливит наш код; глобальные бакеты simple_animals
// на время замера изолируются и восстанавливаются после.

/mob/living/simple_animal/hostile/unit_test_ai_benchmark_ranged
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 6
	ranged_cooldown_time = 6 SECONDS
	projectiletype = /obj/item/projectile/beam/laser
	projectilesound = 'sound/weapons/laser.ogg'

/datum/unit_test/ai_benchmark_baseline
	priority = TEST_LONGER
	///резервация арены
	var/datum/turf_reservation/arena
	///мобы текущего сценария
	var/list/scenario_mobs = list()
	///carbon-цели/Life-нагрузка отдельно: AI-циклы выше могут считать список hostile-гомогенным
	var/list/scenario_humans = list()
	///service bots для отдельного замера NPC-pool target scan
	var/list/scenario_bots = list()
	///прочие объекты текущего сценария (машины-цели)
	var/list/scenario_objects = list()
	///"игрок" текущего сценария (клиентless-мышь в CLIENTS-канале грида)
	var/mob/living/carbon/human/fake_player
	///бэкап глобальных бакетов simple_animals на время замера
	var/list/bucket_backup
	///бэкапы очередей controller-AI: замер не должен включать фон карты
	var/list/controller_status_backup
	var/list/unplanned_backup
	var/list/behavior_processing_backup
	var/list/controller_currentrun_backup
	///бэкапы общего SSmobs-пула: Life-сценарии не должны мерить фон карты
	var/list/mob_living_backup
	var/list/mobs_currentrun_backup
	var/saved_mobs_times_fired
	var/list/clients_on_arena_z_backup
	///сохранённый Master.current_ticklimit
	var/saved_ticklimit
	///итоговый отчёт: имя сценария -> измерения
	var/list/report = list()
	///имя сценария, чей native proc-profile сейчас собирается headless-прогоном
	var/current_profile_scenario

#define AI_BENCH_SEED 4242
//100 samples make p95/p99 actual tail percentiles instead of aliases for max().
#define AI_BENCH_PASSES 100
#define AI_BENCH_ARENA_SIZE 24

/datum/unit_test/ai_benchmark_baseline/Run()
	arena = SSmapping.RequestBlockReservation(AI_BENCH_ARENA_SIZE, AI_BENCH_ARENA_SIZE)
	TEST_ASSERT_NOTNULL(arena, "Failed to reserve the benchmark arena")
	build_floor()

	//бакеты и z-списки должны существовать до всех манипуляций
	if(!islist(SSmobs.clients_by_zlevel) || arena_turf(1, 1).z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	SSidlenpcpool.MaxZChanged()
	report["_meta"] = list(
		"schema_version" = 3,
		"generated_at" = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss"),
		"commit" = GLOB.revdata?.commit,
		"origin_commit" = GLOB.revdata?.originmastercommit,
		"byond" = "[world.byond_version].[world.byond_build]",
		"seed" = AI_BENCH_SEED,
		"passes" = AI_BENCH_PASSES,
		"arena_size" = AI_BENCH_ARENA_SIZE,
	)

	scenario_dormant_no_players()
	scenario_dormant_far_player()
	scenario_controllers_dormant()
	scenario_controllers_active()
	scenario_controllers_ranged()
	scenario_controllers_jps_maze()
	scenario_controllers_smasher_breakthrough()
	scenario_controllers_boss_selector()
	scenario_controllers_machine_acquisition()
	scenario_mobs_life_empty_z()
	scenario_mobs_life_far_alive()
	scenario_mobs_life_near_alive()
	scenario_mobs_life_far_dead()
	scenario_mobs_life_near_dead()
	scenario_slime_hunt()
	scenario_cleanbot_idle_scan()
	scenario_cleanbot_dense_target_scan()
	scenario_floorbot_unreachable_targets()
	scenario_controllers_planning_only()
	scenario_controllers_dense_acquisition()
	scenario_ai_noise_storm()

	//v3 не дописывается в вечный JSONL: один запуск = один самодостаточный документ.
	var/report_path = "data/mob_benchmark_v3.json"
	fdel(report_path)
	text2file(json_encode(report), report_path)

	qdel(arena)
	arena = null

	//семантические инварианты idle-пула (проверяются ПОСЛЕ восстановления мира)
	var/list/dormant_far = report["dormant_far_player"]
	TEST_ASSERT_EQUAL(dormant_far["metrics"]["planning_cycles"], 0, "Dormant mobs with a far player must not plan")
	TEST_ASSERT_EQUAL(dormant_far["metrics"]["hearers_calls"], 0, "Dormant mobs with a far player must not run hearers()")

	//критерии приёмки контроллер-системы
	var/list/ctrl_dormant = report["controllers_dormant"]
	TEST_ASSERT_EQUAL(ctrl_dormant["metrics"]["planning_cycles"], 0, "Dormant controllers must never plan (acceptance)")
	TEST_ASSERT_EQUAL(ctrl_dormant["processing_entries"], 0, "Dormant controllers must be absent from every processing queue (acceptance)")
	var/list/ctrl_active = report["controllers_active"]
	TEST_ASSERT_EQUAL(ctrl_active["metrics"]["hearers_calls"], 0, "Controller-driven acquisition must never call hearers() (acceptance)")
	TEST_ASSERT(ctrl_active["metrics"]["planning_cycles"] > 0, "Active controllers must actually plan")
	TEST_ASSERT(ctrl_active["targets_acquired"] >= 45, "Nearly all active controllers must acquire the player as a target")
	TEST_ASSERT_EQUAL(ctrl_active["woken_synchronously"], 50, "A client entering tracked cells must wake all controllers synchronously")
	var/list/ctrl_jps = report["controllers_jps_maze"]
	TEST_ASSERT_EQUAL(ctrl_jps["metrics"]["jps_requests"], 25 * AI_BENCH_PASSES, "The JPS scenario must execute one route request per controller per pass")
	TEST_ASSERT(ctrl_jps["paths_found"] > 0, "The controller JPS budget must find routes through the benchmark maze")
	//Улучшение: смэшеры пробивают камень напрямую и не платят за JPS-детур
	var/list/ctrl_smash = report["controllers_smasher_breakthrough"]
	TEST_ASSERT_EQUAL(ctrl_smash["smasher_switched_to_jps"], 0, "Wall-smashers must break through the rock on their line without a single JPS detour")
	TEST_ASSERT_EQUAL(ctrl_smash["smasher_jps_requests"], 0, "Breaking through the wall must issue zero pathfinder requests")
	TEST_ASSERT_EQUAL(ctrl_smash["nosmash_switched_to_jps"], ctrl_smash["mob_count"], "The same mobs without smash must each fall back to a JPS detour (proving the layout truly needs pathing)")
	TEST_ASSERT(ctrl_smash["nosmash_jps_requests"] > 0, "The non-smashing detour must actually hit the pathfinder, so the smasher zero is a real saving")
	var/list/ctrl_boss = report["controllers_boss_selector"]
	TEST_ASSERT_EQUAL(ctrl_boss["selections"], 10 * AI_BENCH_PASSES, "Every boss must produce one table selection per pass")
	var/list/ctrl_machines = report["controllers_machine_acquisition"]
	TEST_ASSERT(ctrl_machines["targets_acquired"] >= 45, "Nearly all machine hunters must acquire the indexed turret")
	var/list/cleanbot_dense = report["cleanbot_dense_target_scan"]
	TEST_ASSERT_EQUAL(cleanbot_dense["targets_found"], AI_BENCH_PASSES, "Dense cleanbot scan must preserve one visible target per pass")
	var/list/floorbot_unreachable = report["floorbot_unreachable_targets"]
	TEST_ASSERT_EQUAL(floorbot_unreachable["metrics"]["jps_requests"], 1, "Failed floorbot paths must stay on cooldown during synchronous benchmark passes")

//////////// Сценарии ////////////

///100 спящих (AI_IDLE) хостайлов, игроков нет вообще: первый же пасс уводит в AI_Z_OFF
/datum/unit_test/ai_benchmark_baseline/proc/scenario_dormant_no_players()
	rand_seed(AI_BENCH_SEED)
	spawn_hostiles(100, 14, 22, 9)
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.toggle_ai(AI_IDLE)
	begin_measurement("dormant_no_players")
	var/list/costs = measure_passes(SSidlenpcpool, AI_BENCH_PASSES)
	var/z_off_count = 0
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		if(subject.AIStatus == AI_Z_OFF)
			z_off_count++
	end_measurement("dormant_no_players", costs, list("z_off_after" = z_off_count))
	teardown_scenario()

///100 спящих, игрок на том же z, но дальше NEARBY_PLAYER_DISTANCE: рекуррентная стоимость поллинга
/datum/unit_test/ai_benchmark_baseline/proc/scenario_dormant_far_player()
	rand_seed(AI_BENCH_SEED)
	spawn_hostiles(100, 18, 24, 7)
	place_player(1, 1)
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.toggle_ai(AI_IDLE)
	begin_measurement("dormant_far_player")
	var/list/costs = measure_passes(SSidlenpcpool, AI_BENCH_PASSES)
	end_measurement("dormant_far_player", costs)
	teardown_scenario()

///100 спящих контроллеров: ноль планирования и ноль очередей обработки
/datum/unit_test/ai_benchmark_baseline/proc/scenario_controllers_dormant()
	rand_seed(AI_BENCH_SEED)
	spawn_controller_mobs(100, 14, 22, 9)
	begin_measurement("controllers_dormant")
	//усыпить вручную (в CI нет клиентов - без этого контроллеры просто OFF)
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.ai_controller?.set_ai_status(AI_STATUS_IDLE)
	var/list/costs = measure_passes(SSai_controllers, AI_BENCH_PASSES)
	//дормант обязан отсутствовать во всех очередях
	var/processing_entries = 0
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		var/datum/ai_controller/controller = subject.ai_controller
		if(!controller)
			continue
		if(controller in SSai_behaviors.processing)
			processing_entries++
		if(controller in GLOB.unplanned_controllers)
			processing_entries++
		if(controller in SSai_controllers.currentrun)
			processing_entries++
	end_measurement("controllers_dormant", costs, list("processing_entries" = processing_entries))
	teardown_scenario()

///50 активных контроллеров: синхронное пробуждение, поиск целей через грид
/datum/unit_test/ai_benchmark_baseline/proc/scenario_controllers_active()
	rand_seed(AI_BENCH_SEED)
	spawn_controller_mobs(50, 5, 19, 7)
	begin_measurement("controllers_active")
	//пока клиентов нет - усыпляем; приход игрока обязан разбудить сигналом ячейки
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.ai_controller?.set_ai_status(AI_STATUS_IDLE)
	place_player(12, 12)
	var/woken = 0
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		if(subject.ai_controller?.ai_status == AI_STATUS_ON)
			woken++

	//полный цикл: планирование + исполнение поведения (поиск целей, милишка)
	mark_combat_veterans(fake_player)
	var/list/costs = measure_controller_passes(AI_BENCH_PASSES)

	var/targets_acquired = 0
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		if(subject.ai_controller?.blackboard[BB_AI_CURRENT_TARGET] == fake_player)
			targets_acquired++

	end_measurement("controllers_active", costs, list("woken_synchronously" = woken, "targets_acquired" = targets_acquired))
	teardown_scenario()

///50 controller-рейнджеров: maintain-distance, стрельба и safe-fire checks.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_controllers_ranged()
	rand_seed(AI_BENCH_SEED)
	spawn_controller_mobs(50, 5, 19, 7, /mob/living/simple_animal/hostile/unit_test_ai_benchmark_ranged)
	begin_measurement("controllers_ranged")
	place_player(12, 12)
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.ai_controller?.set_ai_status(AI_STATUS_ON)
		subject.ai_controller?.set_blackboard_key(BB_AI_CURRENT_TARGET, fake_player)
	mark_combat_veterans(fake_player)
	var/list/costs = measure_controller_passes(AI_BENCH_PASSES)
	var/targets_acquired = 0
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		if(subject.ai_controller?.blackboard[BB_AI_CURRENT_TARGET] == fake_player)
			targets_acquired++
	end_measurement("controllers_ranged", costs, list("targets_acquired" = targets_acquired))
	teardown_scenario()

///25 controller-мобов строят дальние JPS-маршруты вокруг стены с двумя проходами.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_controllers_jps_maze()
	rand_seed(AI_BENCH_SEED)
	place_player(2, 12)
	for(var/wall_y in 4 to 20)
		arena_turf(12, wall_y).ChangeTurf(/turf/closed/wall)
	spawn_controller_mobs(25, 17, 22, 5)
	begin_measurement("controllers_jps_maze")
	var/list/cpu_samples = list()
	var/paths_found = 0
	var/wall_start = REALTIMEOFDAY
	for(var/pass in 1 to AI_BENCH_PASSES)
		var/cpu_start = TICK_USAGE_REAL
		for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
			var/datum/ai_controller/controller = subject.ai_controller
			var/list/path = get_path_to(subject, fake_player, controller.max_path_length, controller.get_minimum_distance(), controller.get_access())
			if(length(path))
				paths_found++
		cpu_samples += TICK_USAGE_TO_MS(cpu_start)
	end_measurement("controllers_jps_maze", summarize_samples(cpu_samples, REALTIMEOFDAY - wall_start), list("paths_found" = paths_found))
	teardown_scenario()
	for(var/wall_y in 4 to 20)
		var/turf/wall_turf = arena_turf(12, wall_y)
		if(iswallturf(wall_turf))
			wall_turf.ChangeTurf(/turf/open/floor/plasteel)

///Прорыв vs детур: одни и те же контроллер-мобы вплотную к каменной стене на пути
///к игроку. Смэшеры обязаны бить сквозь стену (гейт attack_obstacle_in_path) и НЕ
///запускать дорогой JPS-обход; без environment_smash те же мобы уходят в JPS.
///Сравнение self-contained: дельта jps_requests в одном прогоне и есть экономия.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_controllers_smasher_breakthrough()
	rand_seed(AI_BENCH_SEED)
	place_player(2, 12)
	//колонна камня x=6 отделяет мобов (вплотную, x=7) от игрока (x=2)
	for(var/wall_y in 2 to AI_BENCH_ARENA_SIZE - 1)
		arena_turf(6, wall_y).ChangeTurf(/turf/closed/wall)
	spawn_controller_mobs(12, 7, 18, 1) //одна колонна вплотную к стене
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.ai_controller?.set_ai_status(AI_STATUS_ON)
		subject.ai_controller?.set_blackboard_key(BB_AI_CURRENT_TARGET, fake_player)

	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	begin_measurement("controllers_smasher_breakthrough")

	//Фаза 1: смэшеры - прямой луп держится, гейт бьёт стену, JPS не запускается
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.environment_smash = ENVIRONMENT_SMASH_WALLS | ENVIRONMENT_SMASH_RWALLS
	var/smasher_cpu_start = TICK_USAGE_REAL
	var/smasher_switches = drive_direct_break_decisions(mover)
	var/smasher_cpu_ms = TICK_USAGE_TO_MS(smasher_cpu_start)
	var/smasher_jps = GLOB.ai_metrics.jps_requests

	//Фаза 2: те же мобы без environment_smash обязаны строить JPS-обход
	GLOB.ai_metrics.reset()
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.environment_smash = NONE
	var/nosmash_cpu_start = TICK_USAGE_REAL
	var/nosmash_switches = drive_direct_break_decisions(mover)
	var/nosmash_cpu_ms = TICK_USAGE_TO_MS(nosmash_cpu_start)
	var/nosmash_jps = GLOB.ai_metrics.jps_requests

	end_measurement("controllers_smasher_breakthrough", summarize_samples(list(smasher_cpu_ms, nosmash_cpu_ms), 0), list(
		"mob_count" = length(scenario_mobs),
		"smasher_switched_to_jps" = smasher_switches,
		"nosmash_switched_to_jps" = nosmash_switches,
		"smasher_jps_requests" = smasher_jps,
		"nosmash_jps_requests" = nosmash_jps,
		"smasher_cpu_ms" = smasher_cpu_ms,
		"nosmash_cpu_ms" = nosmash_cpu_ms,
	))
	//вернуть пол на месте стены
	for(var/wall_y in 2 to AI_BENCH_ARENA_SIZE - 1)
		var/turf/wall_turf = arena_turf(6, wall_y)
		if(iswallturf(wall_turf))
			wall_turf.ChangeTurf(/turf/open/floor/plasteel)
	teardown_scenario()

///Прогнать каждый моб через решение прямого шага у преграды; вернуть число
///переключений на JPS-луп. Смэшеры держат прямой луп (0), остальные детурят.
/datum/unit_test/ai_benchmark_baseline/proc/drive_direct_break_decisions(datum/ai_movement/hybrid/mover)
	var/switches = 0
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		var/datum/ai_controller/controller = subject.ai_controller
		if(!controller)
			continue
		mover.start_moving_towards(controller, fake_player, 1)
		var/datum/move_loop/loop = SSmove_manager.processing_on(subject, SSai_movement)
		if(istype(loop) && !istype(loop, /datum/move_loop/has_target/jps))
			mover.pre_move_direct(loop)
		if(istype(SSmove_manager.processing_on(subject, SSai_movement), /datum/move_loop/has_target/jps))
			switches++
		mover.stop_moving_towards(controller)
	return switches

///10 легионов: чистая стоимость табличного выбора без асинхронных атак.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_controllers_boss_selector()
	rand_seed(AI_BENCH_SEED)
	place_player(12, 12)
	spawn_controller_mobs(10, 6, 18, 5, /mob/living/simple_animal/hostile/megafauna/legion)
	begin_measurement("controllers_boss_selector")
	var/datum/ai_planning_subtree/boss_ability_selection/selector = GLOB.ai_subtrees[/datum/ai_planning_subtree/boss_ability_selection]
	var/list/cpu_samples = list()
	var/selections = 0
	var/wall_start = REALTIMEOFDAY
	for(var/pass in 1 to AI_BENCH_PASSES)
		var/cpu_start = TICK_USAGE_REAL
		for(var/mob/living/simple_animal/hostile/megafauna/legion/boss as anything in scenario_mobs)
			var/datum/ai_controller/hostile_adapter/boss/controller = boss.ai_controller
			boss.ranged_cooldown = 0
			for(var/datum/boss_attack/attack as anything in controller.blackboard[BB_AI_BOSS_ATTACKS])
				attack.next_use_time = 0
			controller.set_blackboard_key(BB_AI_CURRENT_TARGET, fake_player)
			selector.SelectBehaviors(controller, 0.5)
			if(controller.blackboard[BB_AI_BOSS_CHOSEN_ATTACK])
				selections++
			controller.CancelActions()
		cpu_samples += TICK_USAGE_TO_MS(cpu_start)
	end_measurement("controllers_boss_selector", summarize_samples(cpu_samples, REALTIMEOFDAY - wall_start), list("selections" = selections))
	teardown_scenario()

///50 контроллеров ищут одну hostile-машину только в своём z-бакете.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_controllers_machine_acquisition()
	rand_seed(AI_BENCH_SEED)
	var/obj/machinery/porta_turret/syndicate/turret = new(arena_turf(12, 12))
	scenario_objects += turret
	spawn_controller_mobs(50, 8, 16, 7)
	begin_measurement("controllers_machine_acquisition")
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.ai_controller?.set_ai_status(AI_STATUS_ON)
	mark_combat_veterans(turret)
	var/list/costs = measure_controller_passes(AI_BENCH_PASSES)
	var/targets_acquired = 0
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		if(subject.ai_controller?.blackboard[BB_AI_CURRENT_TARGET] == turret)
			targets_acquired++
	end_measurement("controllers_machine_acquisition", costs, list("targets_acquired" = targets_acquired))
	teardown_scenario()

///Очередь из автомата: 12 выстрелов из одной точки за окно коалесцирования,
///60 слушателей вокруг. Дедуп источника обязан резать повторные грид-сканы
///одной очереди до единственного.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_ai_noise_storm()
	rand_seed(AI_BENCH_SEED)
	place_player(12, 12)
	spawn_controller_mobs(60, 5, 19, 8)
	var/turf/epicenter = arena_turf(12, 12)
	begin_measurement("ai_noise_storm")
	var/list/cpu_samples = list()
	var/wall_start = REALTIMEOFDAY
	for(var/pass in 1 to AI_BENCH_PASSES)
		//каждая пачка - новая очередь: свежее окно дедупа и троттлы слушателей
		GLOB.ai_recent_noise.Cut()
		for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
			var/datum/ai_controller/listener = subject.ai_controller
			if(listener)
				listener.blackboard[BB_AI_NOISE_COOLDOWN] = 0
		var/cpu_start = TICK_USAGE_REAL
		for(var/shot in 1 to 12)
			ai_broadcast_noise(epicenter, AI_NOISE_GUNSHOT_RANGE, fake_player)
		cpu_samples += TICK_USAGE_TO_MS(cpu_start)
	var/investigations = 0
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		var/datum/ai_controller/listener = subject.ai_controller
		if(listener && listener.blackboard[BB_AI_STATE] == AI_STATE_SEARCH)
			investigations++
	end_measurement("ai_noise_storm", summarize_samples(cpu_samples, REALTIMEOFDAY - wall_start), list("shots_per_pass" = 12, "investigations" = investigations))
	teardown_scenario()

///100 живых clientless humans на z без игроков: быстрый early-out общего SSmobs.Life.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_mobs_life_empty_z()
	rand_seed(AI_BENCH_SEED)
	spawn_humans(100, 5, 19, 10)
	begin_measurement("mobs_life_empty_z")
	var/list/costs = measure_mob_life_passes(AI_BENCH_PASSES)
	end_measurement("mobs_life_empty_z", costs, list("mob_count" = 100))
	teardown_scenario()

///100 живых humans далеко от игрока: staggered Life (полный цикл раз в четыре fire).
/datum/unit_test/ai_benchmark_baseline/proc/scenario_mobs_life_far_alive()
	rand_seed(AI_BENCH_SEED)
	place_player(1, 1)
	spawn_humans(100, 17, 23, 7)
	begin_measurement("mobs_life_far_alive")
	var/list/costs = measure_mob_life_passes(AI_BENCH_PASSES)
	end_measurement("mobs_life_far_alive", costs, list("mob_count" = 100, "full_life_passes" = AI_BENCH_PASSES / 4))
	teardown_scenario()

///50 живых humans рядом с игроком: полный Physical/Biological/status Life каждый fire.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_mobs_life_near_alive()
	rand_seed(AI_BENCH_SEED)
	place_player(12, 12)
	spawn_humans(50, 8, 16, 9)
	begin_measurement("mobs_life_near_alive")
	var/list/costs = measure_mob_life_passes(AI_BENCH_PASSES)
	end_measurement("mobs_life_near_alive", costs, list("mob_count" = 50, "full_life_passes" = AI_BENCH_PASSES))
	teardown_scenario()

///100 мёртвых humans далеко от игрока: biological decay cadence раз в 15 fire.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_mobs_life_far_dead()
	rand_seed(AI_BENCH_SEED)
	place_player(1, 1)
	spawn_humans(100, 17, 23, 7, TRUE)
	begin_measurement("mobs_life_far_dead")
	var/list/costs = measure_mob_life_passes(AI_BENCH_PASSES)
	end_measurement("mobs_life_far_dead", costs, list("mob_count" = 100, "full_life_passes" = FLOOR(AI_BENCH_PASSES / 15, 1)))
	teardown_scenario()

///100 мёртвых clientless humans РЯДОМ с игроком. До рычага 1: полный
///BiologicalLife каждый fire (труп в медбэе жуёт органы/гниение каждые 2с). После:
///decay cadence раз в 4 fire (8с). Прямое доказательство рычага 1.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_mobs_life_near_dead()
	rand_seed(AI_BENCH_SEED)
	place_player(12, 12)
	spawn_humans(100, 8, 16, 9, TRUE)
	begin_measurement("mobs_life_near_dead")
	//within-run A/B (устраняет межпрогонный шум): A = throttle как в проде,
	//B = полный BiologicalLife на каждом трупе каждый пасс (цена ДО рычага 1).
	var/list/throttled = measure_mob_life_passes(AI_BENCH_PASSES)
	var/list/full_samples = list()
	var/dead_seconds = SSmobs.wait * 0.1
	for(var/pass in 1 to AI_BENCH_PASSES)
		var/cpu_start = TICK_USAGE_REAL
		for(var/mob/living/carbon/human/corpse as anything in scenario_humans)
			corpse.BiologicalLife(dead_seconds, pass)
		full_samples += TICK_USAGE_TO_MS(cpu_start)
	var/list/full = summarize_samples(full_samples, 0)
	end_measurement("mobs_life_near_dead", throttled, list(
		"mob_count" = 100,
		"throttled_median_ms" = throttled["median_ms"],
		"unthrottled_median_ms" = full["median_ms"],
	))
	teardown_scenario()

///20 слаймов сканируют добычу среди 40 живых мобов в открытом загоне. Изолирует
///handle_targets() (view(7) до рычага 3, spatial-grid после): дельта baseline/
///optimized и есть цена перцепционного скана.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_slime_hunt()
	rand_seed(AI_BENCH_SEED)
	place_player(1, 1)
	spawn_slimes(20, 6, 18, 7)
	spawn_humans(40, 5, 19, 8) //живая добыча в радиусе скана
	begin_measurement("slime_hunt")
	var/list/variants = measure_slime_scan_variants(AI_BENCH_PASSES)
	//primary cost = grid_only (как в проде после рычага 3); within-run view и
	//grid_cansee рядом для сравнения (can_see оказался в 2.2x дороже view).
	end_measurement("slime_hunt", variants["grid_only"], list(
		"slime_count" = 20,
		"prey_count" = 40,
		"view_median_ms" = variants["view"]["median_ms"],
		"grid_cansee_median_ms" = variants["grid_cansee"]["median_ms"],
		"grid_only_median_ms" = variants["grid_only"]["median_ms"],
	))
	teardown_scenario()

///20 idle cleanbots with every optional target class enabled and no valid
///targets. This reproduces the live-round worst case: four full scans over the
///same cached view on every NPC-pool action.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_cleanbot_idle_scan()
	rand_seed(AI_BENCH_SEED)
	spawn_cleanbots(20)
	begin_measurement("cleanbot_idle_scan")
	var/list/costs = measure_cleanbot_scan_passes(AI_BENCH_PASSES)
	end_measurement("cleanbot_idle_scan", costs, list(
		"bot_count" = length(scenario_bots),
		"actions" = length(scenario_bots) * AI_BENCH_PASSES,
	))
	teardown_scenario()

///One cleanbot searches a dense visible scene containing a single valid target.
///This covers the live outlier that the empty-grid scenario deliberately skips:
///once the spatial grid returns a candidate, LOS still has to inspect view().
/datum/unit_test/ai_benchmark_baseline/proc/scenario_cleanbot_dense_target_scan()
	rand_seed(AI_BENCH_SEED)
	var/mob/living/simple_animal/bot/cleanbot/subject = new(arena_turf(12, 12))
	scenario_bots += subject
	for(var/turf/tile as anything in block(arena_turf(5, 5), arena_turf(19, 19)))
		for(var/index in 1 to 5)
			scenario_objects += new /obj/item/paper(tile)
	var/obj/effect/decal/cleanable/dirt/target = new(arena_turf(18, 12))
	scenario_objects += target

	begin_measurement("cleanbot_dense_target_scan")
	var/list/results = measure_cleanbot_target_scan_passes(AI_BENCH_PASSES)
	end_measurement("cleanbot_dense_target_scan", results["costs"], list(
		"bot_count" = length(scenario_bots),
		"visible_noise_atoms" = length(scenario_objects) - 1,
		"targets_found" = results["targets_found"],
	))
	teardown_scenario()

///A floorbot can see repair targets but is sealed behind transparent full-tile
///windows. It reproduces the repeated failed JPS searches from the live round.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_floorbot_unreachable_targets()
	rand_seed(AI_BENCH_SEED)
	var/mob/living/simple_animal/bot/floorbot/subject = new(arena_turf(12, 12))
	subject.emagged = 2
	subject.auto_patrol = FALSE
	scenario_bots += subject
	for(var/direction in GLOB.alldirs)
		scenario_objects += new /obj/structure/window/reinforced/fulltile(get_step(subject, direction))
	subject.target = arena_turf(14, 12)

	begin_measurement("floorbot_unreachable_targets")
	var/list/costs = measure_floorbot_path_failures(AI_BENCH_PASSES)
	end_measurement("floorbot_unreachable_targets", costs, list(
		"bot_count" = length(scenario_bots),
		"actions" = length(scenario_bots) * AI_BENCH_PASSES,
	))
	teardown_scenario()

///50 активных контроллеров: только SSai_controllers.SelectBehaviors, без execution.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_controllers_planning_only()
	rand_seed(AI_BENCH_SEED)
	spawn_controller_mobs(50, 5, 19, 7)
	place_player(12, 12)
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.ai_controller?.set_ai_status(AI_STATUS_ON)
		subject.ai_controller?.set_blackboard_key(BB_AI_CURRENT_TARGET, fake_player)
	mark_combat_veterans(fake_player)
	begin_measurement("controllers_planning_only")
	var/list/costs = measure_passes(SSai_controllers, AI_BENCH_PASSES)
	var/queued_behaviors = 0
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		queued_behaviors += length(subject.ai_controller?.current_behaviors)
	end_measurement("controllers_planning_only", costs, list("queued_behaviors" = queued_behaviors))
	teardown_scenario()

///Плотный worst-case perception: 30 контроллеров заново выбирают среди 60 humans.
/datum/unit_test/ai_benchmark_baseline/proc/scenario_controllers_dense_acquisition()
	rand_seed(AI_BENCH_SEED)
	spawn_controller_mobs(30, 3, 9, 7)
	spawn_humans(60, 11, 22, 10)
	place_player(12, 12)
	begin_measurement("controllers_dense_acquisition")
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/list/cpu_samples = list()
	var/acquisitions = 0
	var/wall_start = REALTIMEOFDAY
	for(var/pass in 1 to AI_BENCH_PASSES)
		var/cpu_start = TICK_USAGE_REAL
		for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
			var/datum/ai_controller/controller = subject.ai_controller
			if(!controller)
				continue
			controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
			controller.blackboard[BB_AI_TARGET_REFRESH_AT] = 0
			finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
			if(controller.blackboard[BB_AI_CURRENT_TARGET])
				acquisitions++
		cpu_samples += TICK_USAGE_TO_MS(cpu_start)
	end_measurement("controllers_dense_acquisition", summarize_samples(cpu_samples, REALTIMEOFDAY - wall_start), list("acquisitions" = acquisitions, "controllers" = 30, "candidate_mobs" = 60))
	teardown_scenario()

///Пометить мобов сценария "ветеранами" боя: агрессор их уже бил, поэтому
///читаемая ALERT-пауза обнаружения пропускается. Пассы замера идут в одном
///world.time, где ALERT не истекает и занизил бы стоимость планирования.
/datum/unit_test/ai_benchmark_baseline/proc/mark_combat_veterans(atom/aggressor)
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		subject.ai_controller?.set_blackboard_key(BB_AI_LAST_ATTACKER, aggressor)

///Спавн мобов с СОХРАНЕНИЕМ адаптер-контроллеров (сценарии новой системы)
/datum/unit_test/ai_benchmark_baseline/proc/spawn_controller_mobs(count, min_coord, max_coord, row_length, mob_type = /mob/living/simple_animal/hostile)
	var/index = 0
	while(index < count)
		var/spawn_x = min_coord + (index % row_length)
		var/spawn_y = min_coord + round(index / row_length)
		if(spawn_y > max_coord)
			spawn_y = max_coord
		var/mob/living/simple_animal/hostile/subject = new mob_type(arena_turf(spawn_x, spawn_y))
		scenario_mobs += subject
		index++

///Разложить humans по сетке; dead=TRUE переводит их в штатное DEAD-состояние до замера.
/datum/unit_test/ai_benchmark_baseline/proc/spawn_humans(count, min_coord, max_coord, row_length, dead = FALSE)
	var/index = 0
	while(index < count)
		var/spawn_x = min_coord + (index % row_length)
		var/spawn_y = min_coord + round(index / row_length)
		if(spawn_y > max_coord)
			spawn_y = max_coord
		var/mob/living/carbon/human/subject = new(arena_turf(spawn_x, spawn_y))
		if(dead)
			subject.death()
		scenario_humans += subject
		index++

///Разложить count слаймов по сетке; кладём в scenario_mobs (simple_animals-путь teardown).
/datum/unit_test/ai_benchmark_baseline/proc/spawn_slimes(count, min_coord, max_coord, row_length)
	var/index = 0
	while(index < count)
		var/spawn_x = min_coord + (index % row_length)
		var/spawn_y = min_coord + round(index / row_length)
		if(spawn_y > max_coord)
			spawn_y = max_coord
		var/mob/living/simple_animal/slime/subject = new(arena_turf(spawn_x, spawn_y))
		scenario_mobs += subject
		index++

///Разложить cleanbot по сетке без соседних клеток: они видят друг друга, но
///ни один из них не является валидным pest/cleanable/trash target.
/datum/unit_test/ai_benchmark_baseline/proc/spawn_cleanbots(count)
	var/index = 0
	while(index < count)
		var/spawn_x = 5 + (index % 5) * 3
		var/spawn_y = 5 + round(index / 5) * 3
		var/mob/living/simple_animal/bot/cleanbot/subject = new(arena_turf(spawn_x, spawn_y))
		subject.pests = TRUE
		subject.trash = TRUE
		subject.get_targets()
		scenario_bots += subject
		index++

//////////// Инфраструктура ////////////

/datum/unit_test/ai_benchmark_baseline/proc/arena_turf(x, y)
	RETURN_TYPE(/turf)
	return locate(arena.bottom_left_coords[1] + x - 1, arena.bottom_left_coords[2] + y - 1, arena.bottom_left_coords[3])

/datum/unit_test/ai_benchmark_baseline/proc/build_floor()
	for(var/turf/tile as anything in block(arena_turf(1, 1), arena_turf(AI_BENCH_ARENA_SIZE, AI_BENCH_ARENA_SIZE)))
		tile.ChangeTurf(/turf/open/floor/plasteel)

///Разложить count мобов по сетке от min_coord с шириной ряда row_length, детерминированно.
///Бенчмарк меряет ЛЕГАСИ-путь: контроллер миграции снимается, моб возвращается
///в легаси-пулы (сценарии контроллеров спавнят своих мобов отдельно).
/datum/unit_test/ai_benchmark_baseline/proc/spawn_hostiles(count, min_coord, max_coord, row_length)
	var/index = 0
	while(index < count)
		var/spawn_x = min_coord + (index % row_length)
		var/spawn_y = min_coord + round(index / row_length)
		if(spawn_y > max_coord)
			spawn_y = max_coord
		var/mob/living/simple_animal/hostile/subject = new(arena_turf(spawn_x, spawn_y))
		QDEL_NULL(subject.ai_controller)
		subject.toggle_ai(AI_ON)
		scenario_mobs += subject
		index++

/datum/unit_test/ai_benchmark_baseline/proc/place_player(x, y)
	fake_player = new(arena_turf(x, y))
	restore_player_presence()

/datum/unit_test/ai_benchmark_baseline/proc/remove_player_presence()
	if(!fake_player)
		return
	SSmobs.clients_by_zlevel[arena_turf(1, 1).z] -= fake_player
	fake_player.clear_important_client_contents()

/datum/unit_test/ai_benchmark_baseline/proc/restore_player_presence()
	if(!fake_player)
		return
	SSmobs.clients_by_zlevel[arena_turf(1, 1).z] |= fake_player
	fake_player.enable_client_mobs_in_contents()

///Изоляция мира: только наши мобы в бакетах, тик-лимит снят, счётчики обнулены
/datum/unit_test/ai_benchmark_baseline/proc/begin_measurement(scenario_name)
	var/arena_z = arena_turf(1, 1).z
	clients_on_arena_z_backup = SSmobs.clients_by_zlevel[arena_z].Copy()
	SSmobs.clients_by_zlevel[arena_z].Cut()
	if(fake_player)
		SSmobs.clients_by_zlevel[arena_z] += fake_player

	var/list/world_living_mobs = GLOB.mob_living_list
	mob_living_backup = world_living_mobs.Copy()
	world_living_mobs.Cut()
	world_living_mobs += scenario_mobs
	world_living_mobs += scenario_humans
	world_living_mobs += scenario_bots
	mobs_currentrun_backup = SSmobs.currentrun.Copy()
	SSmobs.currentrun.Cut()
	saved_mobs_times_fired = SSmobs.times_fired

	bucket_backup = list()
	for(var/bucket_index in 1 to 4)
		var/list/simple_animal_bucket = GLOB.simple_animals[bucket_index]
		bucket_backup += list(simple_animal_bucket.Copy())
		simple_animal_bucket.Cut()
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		GLOB.simple_animals[subject.AIStatus] |= subject

	controller_status_backup = list()
	for(var/status in list(AI_STATUS_ON, AI_STATUS_OFF, AI_STATUS_IDLE))
		var/list/status_controllers = GLOB.ai_controllers_by_status[status]
		controller_status_backup[status] = status_controllers.Copy()
		status_controllers.Cut()
	unplanned_backup = GLOB.unplanned_controllers.Copy()
	behavior_processing_backup = SSai_behaviors.processing.Copy()
	controller_currentrun_backup = SSai_controllers.currentrun.Copy()
	GLOB.unplanned_controllers.Cut()
	SSai_behaviors.processing.Cut()
	SSai_controllers.currentrun.Cut()
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		var/datum/ai_controller/controller = subject.ai_controller
		if(!controller)
			continue
		GLOB.ai_controllers_by_status[controller.ai_status] |= controller
		if(controller.ai_status == AI_STATUS_ON)
			if(controller in behavior_processing_backup)
				SSai_behaviors.processing |= controller
			if(controller in unplanned_backup)
				GLOB.unplanned_controllers |= controller
	saved_ticklimit = Master.current_ticklimit
	Master.current_ticklimit = INFINITY
	GLOB.ai_metrics.reset()
#ifdef AI_HEADLESS_BENCH
	current_profile_scenario = scenario_name
	world.Profile(PROFILE_CLEAR)
	world.Profile(PROFILE_START)
#endif

///Полные синхронные пассы подсистемы; вернуть list(cpu_ms, wall_ds, passes).
///Master.current_ticklimit = INFINITY, поэтому один fire(FALSE) обрабатывает
///весь currentrun (MC_TICK_CHECK никогда не срабатывает).
/datum/unit_test/ai_benchmark_baseline/proc/measure_passes(datum/controller/subsystem/target_subsystem, pass_count)
	var/list/cpu_samples = list()
	var/wall_start = REALTIMEOFDAY
	//MC_TICK_CHECK внутри fire() зовёт pause() при state != SS_RUNNING - при
	//прямом вызове мимо MC состояние надо подложить самим (и вернуть назад)
	var/saved_state = target_subsystem.state
	for(var/pass in 1 to pass_count)
		target_subsystem.state = SS_RUNNING
		var/cpu_start = TICK_USAGE_REAL
		target_subsystem.fire(FALSE)
		cpu_samples += TICK_USAGE_TO_MS(cpu_start)
	target_subsystem.state = saved_state
	return summarize_samples(cpu_samples, REALTIMEOFDAY - wall_start)

///Полные синхронные SSmobs-пассы с настоящим times_fired: нужны throttle cadence 4/15.
/datum/unit_test/ai_benchmark_baseline/proc/measure_mob_life_passes(pass_count)
	var/list/cpu_samples = list()
	var/wall_start = REALTIMEOFDAY
	var/saved_state = SSmobs.state
	for(var/pass in 1 to pass_count)
		SSmobs.state = SS_RUNNING
		SSmobs.times_fired = pass
		var/cpu_start = TICK_USAGE_REAL
		SSmobs.fire(FALSE)
		cpu_samples += TICK_USAGE_TO_MS(cpu_start)
	SSmobs.state = saved_state
	return summarize_samples(cpu_samples, REALTIMEOFDAY - wall_start)

///Within-run 3-полосный A/B цены перцепционного скана слайма на ОДНИХ И ТЕХ ЖЕ
///мобах (устраняет межпрогонный шум окружения). Полосы:
/// view        - легаси for(L in view(7)) + isslime/dead фильтр (LOS от view);
/// grid_cansee - grid AI_TARGETS + get_dist + can_see (как в проде после рычага 3);
/// grid_only   - grid + get_dist без can_see (что стоит без восстановления LOS).
///Возвращает list("view"=summary, "grid_cansee"=summary, "grid_only"=summary).
/datum/unit_test/ai_benchmark_baseline/proc/measure_slime_scan_variants(pass_count)
	var/list/view_samples = list()
	var/list/grid_cansee_samples = list()
	var/list/grid_only_samples = list()
	for(var/pass in 1 to pass_count)
		var/cpu_view = TICK_USAGE_REAL
		for(var/mob/living/simple_animal/slime/subject as anything in scenario_mobs)
			for(var/mob/living/candidate in view(7, subject))
				if(isslime(candidate) || candidate.stat == DEAD)
					continue
		view_samples += TICK_USAGE_TO_MS(cpu_view)

		var/cpu_grid_cansee = TICK_USAGE_REAL
		for(var/mob/living/simple_animal/slime/subject as anything in scenario_mobs)
			for(var/mob/living/candidate as anything in SSspatial_grid.orthogonal_range_search(subject, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, 7))
				if(isslime(candidate) || candidate.stat == DEAD)
					continue
				if(get_dist(subject, candidate) > 7)
					continue
				if(!can_see(subject, candidate, 7))
					continue
		grid_cansee_samples += TICK_USAGE_TO_MS(cpu_grid_cansee)

		var/cpu_grid_only = TICK_USAGE_REAL
		for(var/mob/living/simple_animal/slime/subject as anything in scenario_mobs)
			for(var/mob/living/candidate as anything in SSspatial_grid.orthogonal_range_search(subject, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, 7))
				if(isslime(candidate) || candidate.stat == DEAD)
					continue
				if(get_dist(subject, candidate) > 7)
					continue
		grid_only_samples += TICK_USAGE_TO_MS(cpu_grid_only)

	return list(
		"view" = summarize_samples(view_samples, 0),
		"grid_cansee" = summarize_samples(grid_cansee_samples, 0),
		"grid_only" = summarize_samples(grid_only_samples, 0),
	)

///Изолировать target scan cleanbot от cadence и очереди SSnpcpool: один sample
///равен одному синхронному action каждого бота с пустой целью.
/datum/unit_test/ai_benchmark_baseline/proc/measure_cleanbot_scan_passes(pass_count)
	var/list/cpu_samples = list()
	var/wall_start = REALTIMEOFDAY
	for(var/pass in 1 to pass_count)
		var/cpu_start = TICK_USAGE_REAL
		for(var/mob/living/simple_animal/bot/cleanbot/subject as anything in scenario_bots)
			subject.target = null
			subject.handle_automated_action()
		cpu_samples += TICK_USAGE_TO_MS(cpu_start)
	return summarize_samples(cpu_samples, REALTIMEOFDAY - wall_start)

///Measure the candidate-positive scan path without movement/pathfinding noise.
/datum/unit_test/ai_benchmark_baseline/proc/measure_cleanbot_target_scan_passes(pass_count)
	var/list/cpu_samples = list()
	var/targets_found = 0
	var/wall_start = REALTIMEOFDAY
	for(var/pass in 1 to pass_count)
		var/cpu_start = TICK_USAGE_REAL
		for(var/mob/living/simple_animal/bot/cleanbot/subject as anything in scenario_bots)
			if(subject.scan_for_target())
				targets_found++
		cpu_samples += TICK_USAGE_TO_MS(cpu_start)
	return list(
		"costs" = summarize_samples(cpu_samples, REALTIMEOFDAY - wall_start),
		"targets_found" = targets_found,
	)

///Drive automatic target acquisition through an unreachable transparent cage.
/datum/unit_test/ai_benchmark_baseline/proc/measure_floorbot_path_failures(pass_count)
	var/list/cpu_samples = list()
	var/wall_start = REALTIMEOFDAY
	for(var/pass in 1 to pass_count)
		var/cpu_start = TICK_USAGE_REAL
		for(var/mob/living/simple_animal/bot/floorbot/subject as anything in scenario_bots)
			subject.handle_automated_action()
		cpu_samples += TICK_USAGE_TO_MS(cpu_start)
	return summarize_samples(cpu_samples, REALTIMEOFDAY - wall_start)

///Полный controller-pass: планировщик + одно исполнение каждого активного плана.
/datum/unit_test/ai_benchmark_baseline/proc/measure_controller_passes(pass_count)
	var/list/cpu_samples = list()
	var/wall_start = REALTIMEOFDAY
	var/saved_state = SSai_controllers.state
	for(var/pass in 1 to pass_count)
		var/cpu_start = TICK_USAGE_REAL
		SSai_controllers.state = SS_RUNNING
		SSai_controllers.fire(FALSE)
		for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
			var/datum/ai_controller/controller = subject.ai_controller
			if(controller?.ai_status == AI_STATUS_ON && length(controller.current_behaviors))
				controller.process(0.5)
		cpu_samples += TICK_USAGE_TO_MS(cpu_start)
	SSai_controllers.state = saved_state
	return summarize_samples(cpu_samples, REALTIMEOFDAY - wall_start)

///Свести per-pass samples в стабильные распределения для сравнения прогонов.
/datum/unit_test/ai_benchmark_baseline/proc/summarize_samples(list/cpu_samples, wall_ds)
	var/list/sorted = sortTim(cpu_samples.Copy(), GLOBAL_PROC_REF(cmp_numeric_asc))
	var/sample_count = length(sorted)
	var/total_cpu_ms = 0
	for(var/sample in sorted)
		total_cpu_ms += sample
	return list(
		"cpu_ms" = total_cpu_ms,
		"wall_ds" = wall_ds,
		"passes" = sample_count,
		"samples_ms" = cpu_samples.Copy(),
		"median_ms" = percentile_sample(sorted, 0.5),
		"p95_ms" = percentile_sample(sorted, 0.95),
		"p99_ms" = percentile_sample(sorted, 0.99),
	)

/datum/unit_test/ai_benchmark_baseline/proc/percentile_sample(list/sorted, fraction)
	if(!length(sorted))
		return 0
	var/index = clamp(CEILING(length(sorted) * fraction, 1), 1, length(sorted))
	return sorted[index]

///Снять счётчики, вернуть мир на место, записать сценарий в отчёт
/datum/unit_test/ai_benchmark_baseline/proc/end_measurement(scenario_name, list/costs, list/extra)
	var/list/entry = costs.Copy()
	entry["metrics"] = GLOB.ai_metrics.snapshot()
	if(extra)
		entry += extra
	report[scenario_name] = entry
#ifdef AI_HEADLESS_BENCH
	var/current_profile_data = world.Profile(PROFILE_REFRESH, format = "json")
	world.Profile(PROFILE_STOP)
	if(length(current_profile_data))
		var/profile_path = "data/ai_benchmark_profile_[current_profile_scenario].json"
		fdel(profile_path)
		text2file(current_profile_data, profile_path)
	current_profile_scenario = null
#endif
	Master.current_ticklimit = saved_ticklimit
	var/arena_z = arena_turf(1, 1).z
	SSmobs.clients_by_zlevel[arena_z].Cut()
	SSmobs.clients_by_zlevel[arena_z] += clients_on_arena_z_backup
	clients_on_arena_z_backup = null
	var/list/world_living_mobs = GLOB.mob_living_list
	world_living_mobs.Cut()
	world_living_mobs += mob_living_backup
	world_living_mobs -= scenario_mobs
	world_living_mobs -= scenario_humans
	world_living_mobs -= scenario_bots
	if(fake_player)
		world_living_mobs -= fake_player
	SSmobs.currentrun.Cut()
	SSmobs.currentrun += mobs_currentrun_backup
	SSmobs.currentrun -= scenario_mobs
	SSmobs.currentrun -= scenario_humans
	SSmobs.times_fired = saved_mobs_times_fired
	mob_living_backup = null
	mobs_currentrun_backup = null
	for(var/bucket_index in 1 to 4)
		var/list/simple_animal_bucket = GLOB.simple_animals[bucket_index]
		simple_animal_bucket.Cut()
		simple_animal_bucket += bucket_backup[bucket_index]
		//Сценарные мобы существовали в момент backup; не возвращаем их в
		//мировой бакет перед teardown (иначе получаются ложные stranded-GC логи).
		simple_animal_bucket -= scenario_mobs
	bucket_backup = null
	for(var/status in list(AI_STATUS_ON, AI_STATUS_OFF, AI_STATUS_IDLE))
		var/list/status_controllers = GLOB.ai_controllers_by_status[status]
		status_controllers.Cut()
		status_controllers += controller_status_backup[status]
	GLOB.unplanned_controllers.Cut()
	GLOB.unplanned_controllers += unplanned_backup
	SSai_behaviors.processing.Cut()
	SSai_behaviors.processing += behavior_processing_backup
	SSai_controllers.currentrun.Cut()
	SSai_controllers.currentrun += controller_currentrun_backup
	//Тот же принцип для controller-очередей: восстановить только внешний мир.
	for(var/mob/living/simple_animal/hostile/subject as anything in scenario_mobs)
		var/datum/ai_controller/controller = subject.ai_controller
		if(!controller)
			continue
		for(var/status in list(AI_STATUS_ON, AI_STATUS_OFF, AI_STATUS_IDLE))
			GLOB.ai_controllers_by_status[status] -= controller
		GLOB.unplanned_controllers -= controller
		SSai_behaviors.processing -= controller
		SSai_controllers.currentrun -= controller
	controller_status_backup = null
	unplanned_backup = null
	behavior_processing_backup = null
	controller_currentrun_backup = null

///Убрать мобов, снаряды и игрока сценария (бакеты уже восстановлены, Destroy чистит остальное)
/datum/unit_test/ai_benchmark_baseline/proc/teardown_scenario()
	for(var/mob/living/subject as anything in scenario_mobs)
		qdel(subject)
	scenario_mobs.Cut()
	for(var/mob/living/carbon/human/subject as anything in scenario_humans)
		qdel(subject)
	scenario_humans.Cut()
	for(var/mob/living/simple_animal/bot/subject as anything in scenario_bots)
		qdel(subject)
	scenario_bots.Cut()
	for(var/atom/movable/scenario_object as anything in scenario_objects)
		qdel(scenario_object)
	scenario_objects.Cut()
	//снаряды рейндж-сценария держат жёсткие ссылки на удалённых стрелков - подчищаем
	for(var/turf/tile as anything in block(arena_turf(1, 1), arena_turf(AI_BENCH_ARENA_SIZE, AI_BENCH_ARENA_SIZE)))
		for(var/obj/item/projectile/stray in tile)
			qdel(stray)
	if(fake_player)
		remove_player_presence()
		qdel(fake_player)
		fake_player = null

#undef AI_BENCH_ARENA_SIZE
#undef AI_BENCH_PASSES
#undef AI_BENCH_SEED
