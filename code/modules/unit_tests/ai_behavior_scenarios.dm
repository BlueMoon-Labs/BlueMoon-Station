#ifdef AI_BEHAVIOR_SCENE_BENCH

// ===== Живая сцена поведенческих сценариев hostile AI =====
//
// В отличие от синхронных пассов ai_benchmark.dm здесь работает настоящий
// Master Controller: тест спит и семплирует, поэтому идут FSM-таймеры
// (SEARCH/поджидание/ALERT), реальное движение и снаряды. Марионетка-жертва -
// человек в CLIENTS-канале (presence для пробуждения AI), которого скрипт
// водит по вейпоинтам с шагом игрока.
//
// Каждый сценарий = мини-декорация + подопытный моб + сценарный цикл с
// ассертами корректности и баланса. Отчёт с трассами состояний и таймингами
// пишется в data/ai_behavior_scenes_v1.json (материал для тюнинга).
//
// Запуск: tools/mob_bench/run_headless.ps1 -Mode Scenes
// Обычный dm-test этот файл не компилирует (AI_BEHAVIOR_SCENE_BENCH).

#define AI_SCENE_SIZE 24
#define AI_SCENE_SEED 9137
#define AI_SCENE_SAMPLE_INTERVAL (0.5 SECONDS)
///Стены сцен неразрушимые: снаряды сценариев не должны перекраивать декорацию
#define AI_SCENE_WALL /turf/closed/indestructible/wall
#define AI_SCENE_FLOOR /turf/open/floor/plasteel

///Милишный преследователь сцены: реальный урон обязателен - детектор атак
///в семплере считает ДЕЛЬТУ здоровья марионетки, а у базового хостайла
///melee_damage = 0 и удары невидимы
/mob/living/simple_animal/hostile/unit_test_scene_chaser
	move_to_delay = 3
	melee_damage_lower = 10
	melee_damage_upper = 10

///Медленный шамблер угловых сценариев: жертва ОБЯЗАНА быть быстрее (репортный
///кейс), иначе двухтайловый хвост не отстаёт и LOS не рвётся никогда.
///Замедлять надо move_to_delay МОБА: прямой луп гибридного мувера ходит на
///легаси-скорости пауна, controller.movement_delay он не читает.
///environment_smash снят: стенолом получает ignore_sight-стратегию и по
///легаси-паритету ведёт захваченную цель СКВОЗЬ стены (шестой прогон это
///подтвердил) - а сценарии угла проверяют sighted-восприятие vision 3/aggro 7.
/mob/living/simple_animal/hostile/asteroid/miner/unit_test_scene_slow
	move_to_delay = 15
	environment_smash = NONE

/datum/unit_test/ai_behavior_scenes
	priority = TEST_LONGER
	///резервация сцены
	var/datum/turf_reservation/scene
	var/scene_z
	///марионетка-жертва (presence + цель)
	var/mob/living/carbon/human/puppet
	///подопытные мобы текущего сценария
	var/list/scenario_mobs = list()
	///стены текущей декорации (для восстановления пола)
	var/list/built_walls = list()
	///итоговый отчёт: имя сценария -> трасса и метрики
	var/list/report = list()
	///маршрут марионетки: список турфов-вейпоинтов
	var/list/puppet_route = list()
	///шаг марионетки раз в N семплов (2 = 1 тайл/с при семпле 0.5с)
	var/puppet_step_every = 2
	var/puppet_step_phase = 0
	///гравитация area сцены до нашего вмешательства
	var/scene_area_old_gravity = FALSE
	///накопленный урон по марионетке (лечится каждый семпл)
	var/puppet_damage_total = 0
	///кулдаун оружия подопытного на прошлом семпле (счётчик выстрелов)
	var/subject_last_ranged_cooldown = 0

/datum/unit_test/ai_behavior_scenes/Run()
	scene = SSmapping.RequestBlockReservation(AI_SCENE_SIZE, AI_SCENE_SIZE)
	TEST_ASSERT_NOTNULL(scene, "Failed to reserve the behavior scene")
	scene_z = scene_turf(1, 1).z
	if(!islist(SSmobs.clients_by_zlevel) || scene_z > length(SSmobs.clients_by_zlevel))
		SSmobs.MaxZChanged()
	build_scene_shell()
	//на резервационном z нет гравитации: марионетка-человек дрейфовала после
	//каждого шага (2-3 тайла/с вместо тайла в секунду) и укатывалась за конец
	//маршрута - вся геометрия сценариев требует твёрдого пола
	var/area/scene_area = get_area(scene_turf(1, 1))
	scene_area_old_gravity = scene_area.has_gravity
	scene_area.has_gravity = STANDARD_GRAVITY

	report["_meta"] = list(
		"schema_version" = 1,
		"generated_at" = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss"),
		"commit" = GLOB.revdata?.commit,
		"byond" = "[world.byond_version].[world.byond_build]",
		"seed" = AI_SCENE_SEED,
		"sample_interval_ds" = AI_SCENE_SAMPLE_INTERVAL,
	)

	scenario_pursuit_open()
	scenario_corner_loss_search()
	scenario_search_reacquire()
	scenario_search_give_up()
	scenario_ranged_covering_hold()
	scenario_kite_band()
	scenario_cornered_pointblank()
	scenario_pack_contact_share()

	var/report_path = "data/ai_behavior_scenes_v1.json"
	fdel(report_path)
	text2file(json_encode(report), report_path)

	var/area/scene_area_restore = get_area(scene_turf(1, 1))
	scene_area_restore.has_gravity = scene_area_old_gravity
	qdel(scene)
	scene = null

//////////// Сценарии ////////////

///Погоня в открытом зале: жертва уходит шагом, охотник обязан догнать и ударить.
///Холодное обнаружение проходит читаемую ALERT-паузу перед броском.
/datum/unit_test/ai_behavior_scenes/proc/scenario_pursuit_open()
	rand_seed(AI_SCENE_SEED + 1)
	var/mob/living/simple_animal/hostile/subject = spawn_subject(/mob/living/simple_animal/hostile/unit_test_scene_chaser, 4, 12)
	spawn_puppet(9, 12)
	//жертва замирает, пока охотник её не заметит: холодное приобретение идёт
	//каденсом поиска целей (~2с), убегать раньше = гонка, а не сценарий
	var/alert_seen = FALSE
	var/waited = 0
	while(waited < 8 SECONDS && subject.ai_controller?.blackboard[BB_AI_STATE] != AI_STATE_ENGAGE)
		if(subject.ai_controller?.blackboard[BB_AI_STATE] == AI_STATE_ALERT)
			alert_seen = TRUE
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		waited += AI_SCENE_SAMPLE_INTERVAL
	set_puppet_route(list(scene_turf(20, 12), scene_turf(20, 18)), step_every = 2)

	var/list/timeline = list()
	var/list/transitions = list()
	var/first_damage_at = -1
	var/initial_distance = get_dist(subject, puppet)
	var/elapsed = 0
	while(elapsed < 15 SECONDS)
		var/list/snap = sample_scene(subject, elapsed, timeline, transitions)
		if(snap["state"] == AI_STATE_ALERT)
			alert_seen = TRUE
		if(first_damage_at < 0 && puppet_damage_total > 0)
			first_damage_at = elapsed
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		elapsed += AI_SCENE_SAMPLE_INTERVAL

	var/final_distance = get_dist(subject, puppet)
	finish_scenario("pursuit_open", timeline, transitions, list(
		"initial_distance" = initial_distance,
		"final_distance" = final_distance,
		"first_damage_at_ds" = first_damage_at,
		"damage_total" = puppet_damage_total,
		"alert_seen" = alert_seen,
	))
	TEST_ASSERT(alert_seen, "Cold pursuit acquisition must pass through a readable ALERT beat")
	TEST_ASSERT(first_damage_at >= 0, "The chaser must land at least one hit on a walking victim")
	TEST_ASSERT(first_damage_at <= 10 SECONDS, "The first hit must come within 10 seconds (got [first_damage_at / 10]s)")
	TEST_ASSERT(final_distance <= initial_distance, "A pursuit must close distance, not lose ground")

///Жертва скрывается за углом: цель честно разжалуется в контакт, моб уходит в
///SEARCH и идёт к последней подтверждённой точке (без GPS-волхака сквозь стену).
/datum/unit_test/ai_behavior_scenes/proc/scenario_corner_loss_search()
	rand_seed(AI_SCENE_SEED + 2)
	build_corner_wall()
	//шамблер из репорта: vision 3 / aggro_vision 7
	var/mob/living/simple_animal/hostile/subject = spawn_subject(/mob/living/simple_animal/hostile/asteroid/miner/unit_test_scene_slow, 6, 12)
	spawn_puppet(8, 12) //в холодном радиусе 3 - честное приобретение
	//жертва стоит, пока её не заметят, и только потом убегает за поворот:
	//на восток по коридору, вверх за торец и НА ЗАПАД за стену - диагональный
	//LOS через открытый торцевой тайл (17,13) при этом рвётся гарантированно
	var/engaged_seen = wait_for_engage(subject)
	set_puppet_route(list(scene_turf(17, 12), scene_turf(17, 15), scene_turf(13, 15)), step_every = 1)

	var/list/timeline = list()
	var/list/transitions = list()
	var/los_lost_at = -1
	var/search_entered_at = -1
	var/elapsed = 0
	while(elapsed < 14 SECONDS)
		var/list/snap = sample_scene(subject, elapsed, timeline, transitions)
		if(snap["state"] == AI_STATE_ENGAGE)
			engaged_seen = TRUE
		if(engaged_seen && los_lost_at < 0 && !snap["los"])
			los_lost_at = elapsed
		if(search_entered_at < 0 && snap["state"] == AI_STATE_SEARCH)
			search_entered_at = elapsed
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		elapsed += AI_SCENE_SAMPLE_INTERVAL

	var/turf/evidence = subject.ai_controller?.blackboard[BB_AI_LAST_KNOWN_POS]
	var/evidence_gap = isturf(evidence) ? get_dist(scene_turf(17, 12), evidence) : -1
	finish_scenario("corner_loss_search", timeline, transitions, list(
		"los_lost_at_ds" = los_lost_at,
		"search_entered_at_ds" = search_entered_at,
		"evidence_gap_from_corner" = evidence_gap,
	))
	TEST_ASSERT(engaged_seen, "The shambler must engage the puppet inside its cold vision")
	TEST_ASSERT(los_lost_at >= 0, "The route must actually break line of sight behind the wall")
	TEST_ASSERT(search_entered_at >= 0, "Losing sight must move the FSM into SEARCH")
	TEST_ASSERT(search_entered_at - los_lost_at <= 4 SECONDS, "SEARCH must start within 4s of losing sight (got [(search_entered_at - los_lost_at) / 10]s)")
	TEST_ASSERT(isturf(evidence) && evidence_gap <= 4, "The evidence turf must sit near the corner where the victim was last seen, not track through the wall")

///Жертва выглядывает из-за угла во время розыска: настороженный охотник обязан
///переприобрести её собственным зрением на боевом радиусе (фикс слепого майнера).
/datum/unit_test/ai_behavior_scenes/proc/scenario_search_reacquire()
	rand_seed(AI_SCENE_SEED + 3)
	build_corner_wall()
	var/mob/living/simple_animal/hostile/subject = spawn_subject(/mob/living/simple_animal/hostile/asteroid/miner/unit_test_scene_slow, 8, 12)
	spawn_puppet(10, 12)
	//прогретый бой (улика подтверждена finder-ом), затем телепорт за стену В
	//ПРЕДЕЛАХ боевого радиуса: разжалование с контактом на первом же пассе
	subject.GiveTarget(puppet)
	TEST_ASSERT(warm_up_engagement(subject), "Sanity: the finder must confirm the victim's position before the teleport")
	//глубоко за середину стены: ОБА обхода (западный и восточный торцы) длиннее
	//2-секундного окна каденса файндера - хвостовое движение к живому атому
	//не успеет срезать угол до честного разжалования
	puppet.forceMove(scene_turf(11, 16))

	var/list/timeline = list()
	var/list/transitions = list()
	var/search_entered_at = -1
	var/peeked_at = -1
	var/reacquired_at = -1
	var/elapsed = 0
	while(elapsed < 20 SECONDS)
		var/list/snap = sample_scene(subject, elapsed, timeline, transitions)
		if(search_entered_at < 0 && snap["state"] == AI_STATE_SEARCH)
			search_entered_at = elapsed
		//моб дошёл до розыска - жертва выглядывает на прямую видимость: 4
		//открытых тайла по кардиналу от ищущего (больше холодного зрения 3,
		//внутри настороженного 7 - ровно окно фикса слепого майнера)
		if(search_entered_at >= 0 && peeked_at < 0 && elapsed >= search_entered_at + 2 SECONDS)
			var/turf/peek_turf
			for(var/direction in GLOB.cardinals)
				var/turf/candidate = get_turf(subject)
				var/lane_clear = TRUE
				for(var/step_count in 1 to 4)
					candidate = get_step(candidate, direction)
					if(!candidate || !isopenturf(candidate) || candidate.is_blocked_turf(source_atom = puppet))
						lane_clear = FALSE
						break
				if(lane_clear)
					peek_turf = candidate
					break
			if(peek_turf)
				puppet.forceMove(peek_turf)
				peeked_at = elapsed
		if(peeked_at >= 0 && reacquired_at < 0 && subject.ai_controller?.blackboard[BB_AI_CURRENT_TARGET] == puppet)
			reacquired_at = elapsed
			break
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		elapsed += AI_SCENE_SAMPLE_INTERVAL

	finish_scenario("search_reacquire", timeline, transitions, list(
		"search_entered_at_ds" = search_entered_at,
		"peeked_at_ds" = peeked_at,
		"reacquired_at_ds" = reacquired_at,
	))
	TEST_ASSERT(search_entered_at >= 0, "The teleported victim must be demoted to a contact and hunted through SEARCH")
	TEST_ASSERT(peeked_at >= 0, "Scenario must reach the peek phase")
	TEST_ASSERT(reacquired_at >= 0, "A victim stepping back into the open must be reacquired by the searcher's own senses")
	TEST_ASSERT(reacquired_at - peeked_at <= 4 SECONDS, "Reacquisition must happen within 4s of the peek (got [(reacquired_at - peeked_at) / 10]s)")

///Жертва пропала насовсем: розыск обязан честно сдаться за конечное время,
///вычистить память и вернуть моба к мирной жизни.
/datum/unit_test/ai_behavior_scenes/proc/scenario_search_give_up()
	rand_seed(AI_SCENE_SEED + 4)
	build_corner_wall()
	//глухая келья для марионетки: presence остаётся, зрению её не достать
	for(var/direction in GLOB.alldirs)
		add_wall(get_step(scene_turf(3, 20), direction))
	var/mob/living/simple_animal/hostile/subject = spawn_subject(/mob/living/simple_animal/hostile/asteroid/miner, 8, 12)
	spawn_puppet(10, 12)
	subject.GiveTarget(puppet)
	TEST_ASSERT(warm_up_engagement(subject), "Sanity: the finder must confirm the victim's position before the vanish")
	puppet.forceMove(scene_turf(3, 20))

	var/list/timeline = list()
	var/list/transitions = list()
	var/search_entered_at = -1
	var/search_ended_at = -1
	var/elapsed = 0
	while(elapsed < 30 SECONDS)
		var/list/snap = sample_scene(subject, elapsed, timeline, transitions)
		if(search_entered_at < 0 && snap["state"] == AI_STATE_SEARCH)
			search_entered_at = elapsed
		if(search_entered_at >= 0 && search_ended_at < 0 && snap["state"] != AI_STATE_SEARCH)
			search_ended_at = elapsed
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		elapsed += AI_SCENE_SAMPLE_INTERVAL

	var/search_duration = (search_entered_at >= 0 && search_ended_at >= 0) ? search_ended_at - search_entered_at : -1
	var/final_state = subject.ai_controller?.blackboard[BB_AI_STATE]
	var/turf/remembered_evidence = subject.ai_controller?.blackboard[BB_AI_LAST_KNOWN_POS]
	finish_scenario("search_give_up", timeline, transitions, list(
		"search_entered_at_ds" = search_entered_at,
		"search_ended_at_ds" = search_ended_at,
		"search_duration_ds" = search_duration,
		"final_state" = final_state,
	))
	TEST_ASSERT(search_entered_at >= 0, "A vanished victim must trigger a SEARCH")
	TEST_ASSERT(search_ended_at >= 0, "A fruitless SEARCH must actually end")
	//ранний выход штатен: осмотрел точки возле улики и закончил, не тупя 15с
	TEST_ASSERT(search_duration >= 2 SECONDS, "The search must not give up instantly (got [search_duration / 10]s)")
	TEST_ASSERT(search_duration <= 25 SECONDS, "The search must not run forever (got [search_duration / 10]s)")
	TEST_ASSERT_EQUAL(final_state, AI_STATE_IDLE, "A finished manhunt must return the mob to peace")
	TEST_ASSERT_NULL(remembered_evidence, "Giving up must clear the remembered evidence")

///Поджидание: дальник, потерявший жертву из виду, сначала держит прикрывающую
///позицию с линией на последнюю точку, а не слепо бежит в упор к углу.
/datum/unit_test/ai_behavior_scenes/proc/scenario_ranged_covering_hold()
	rand_seed(AI_SCENE_SEED + 5)
	build_corner_wall()
	var/mob/living/simple_animal/hostile/subject = spawn_subject(/mob/living/simple_animal/hostile/unit_test_ai_benchmark_ranged, 6, 12)
	spawn_puppet(10, 12)
	subject.GiveTarget(puppet)
	TEST_ASSERT(warm_up_engagement(subject), "Sanity: the finder must confirm the victim's position before it hides")
	puppet.forceMove(scene_turf(17, 15)) //за стену, дальше боевого радиуса

	var/list/timeline = list()
	var/list/transitions = list()
	var/turf/evidence_probe
	var/search_entered_at = -1
	var/min_evidence_gap_during_hold = 99
	var/elapsed = 0
	while(elapsed < 16 SECONDS)
		var/list/snap = sample_scene(subject, elapsed, timeline, transitions)
		if(search_entered_at < 0 && snap["state"] == AI_STATE_SEARCH)
			search_entered_at = elapsed
			evidence_probe = subject.ai_controller?.blackboard[BB_AI_LAST_KNOWN_POS]
		//окно поджидания: первые 10с розыска дальник не лезет в упор к точке
		if(search_entered_at >= 0 && isturf(evidence_probe) && elapsed <= search_entered_at + 10 SECONDS)
			min_evidence_gap_during_hold = min(min_evidence_gap_during_hold, get_dist(subject, evidence_probe))
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		elapsed += AI_SCENE_SAMPLE_INTERVAL

	finish_scenario("ranged_covering_hold", timeline, transitions, list(
		"search_entered_at_ds" = search_entered_at,
		"min_evidence_gap_during_hold" = min_evidence_gap_during_hold,
	))
	TEST_ASSERT(search_entered_at >= 0, "A hidden victim must send the ranged mob into SEARCH")
	TEST_ASSERT(isturf(evidence_probe), "SEARCH must remember the last confirmed point")
	TEST_ASSERT(min_evidence_gap_during_hold >= 2, "During the covering-hold window the shooter must watch the corner from distance, not blindly rush it (closest approach [min_evidence_gap_during_hold])")

///Кайт: наступающая жертва, стрелок держит боевую дистанцию и продолжает огонь.
/datum/unit_test/ai_behavior_scenes/proc/scenario_kite_band()
	rand_seed(AI_SCENE_SEED + 6)
	var/mob/living/simple_animal/hostile/subject = spawn_subject(/mob/living/simple_animal/hostile/unit_test_ai_benchmark_ranged, 12, 12)
	spawn_puppet(7, 12)
	subject.GiveTarget(puppet)

	var/list/timeline = list()
	var/list/transitions = list()
	var/band_samples = 0
	var/counted_samples = 0
	var/shots_fired = 0
	var/adjacent_streak = 0
	var/max_adjacent_streak = 0
	var/elapsed = 0
	while(elapsed < 20 SECONDS)
		//жертва давит на стрелка: каждый второй семпл шаг к нему
		set_puppet_route(list(get_turf(subject)), step_every = 2)
		var/list/snap = sample_scene(subject, elapsed, timeline, transitions)
		shots_fired += snap["shot_fired"]
		//первые 3с - сближение и построение, band считаем после
		if(elapsed >= 3 SECONDS)
			counted_samples++
			var/distance = snap["distance"]
			if(distance >= 3 && distance <= 7)
				band_samples++
			if(distance <= 1)
				adjacent_streak++
				max_adjacent_streak = max(max_adjacent_streak, adjacent_streak)
			else
				adjacent_streak = 0
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		elapsed += AI_SCENE_SAMPLE_INTERVAL

	var/band_fraction = counted_samples ? band_samples / counted_samples : 0
	finish_scenario("kite_band", timeline, transitions, list(
		"band_fraction" = band_fraction,
		"shots_fired" = shots_fired,
		"max_adjacent_streak" = max_adjacent_streak,
		"damage_total" = puppet_damage_total,
	))
	TEST_ASSERT(band_fraction >= 0.6, "The kiter must hold its combat band most of the fight (got [round(band_fraction * 100)]%)")
	TEST_ASSERT(shots_fired >= 2, "Kiting must not silence the gun (got [shots_fired] shots in 20s)")
	TEST_ASSERT(max_adjacent_streak <= 3, "A kiter in the open must not stay pinned point-blank (streak [max_adjacent_streak] samples)")

///Зажим в тупике: лава-имп из репорта. Зажатый вплотную стрелок обязан наносить
///урон (выстрел в упор/когти), а не пытаться убежать в стену.
/datum/unit_test/ai_behavior_scenes/proc/scenario_cornered_pointblank()
	rand_seed(AI_SCENE_SEED + 7)
	//тупик: стены с трёх сторон и по диагоналям запада
	var/turf/nook = scene_turf(4, 12)
	add_wall(get_step(nook, NORTH))
	add_wall(get_step(nook, SOUTH))
	add_wall(get_step(nook, WEST))
	add_wall(get_step(nook, NORTHWEST))
	add_wall(get_step(nook, SOUTHWEST))
	var/mob/living/simple_animal/hostile/subject = spawn_subject(/mob/living/simple_animal/hostile/asteroid/imp, 4, 12)
	spawn_puppet(5, 12) //перекрывает единственный выход
	subject.GiveTarget(puppet)

	var/list/timeline = list()
	var/list/transitions = list()
	var/first_damage_at = -1
	var/attack_events = 0
	var/elapsed = 0
	while(elapsed < 10 SECONDS)
		var/list/snap = sample_scene(subject, elapsed, timeline, transitions)
		if(snap["damage_delta"] > 0)
			attack_events++
			if(first_damage_at < 0)
				first_damage_at = elapsed
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		elapsed += AI_SCENE_SAMPLE_INTERVAL

	finish_scenario("cornered_pointblank", timeline, transitions, list(
		"first_damage_at_ds" = first_damage_at,
		"attack_events" = attack_events,
		"damage_total" = puppet_damage_total,
	))
	TEST_ASSERT(first_damage_at >= 0, "A cornered imp must fight back, not shuffle into the wall")
	TEST_ASSERT(first_damage_at <= 5 SECONDS, "The cornered imp must start fighting within 5s (got [first_damage_at / 10]s)")
	TEST_ASSERT(attack_events >= 2, "The cornered imp must keep fighting, not land a single accidental hit (got [attack_events] events)")

///Стая: ударили одного - сокомандники получают ТОЧКУ контакта и идут проверять
///через SEARCH, но не захватывают чужую цель сквозь стену GPS-ом.
/datum/unit_test/ai_behavior_scenes/proc/scenario_pack_contact_share()
	rand_seed(AI_SCENE_SEED + 8)
	//коридор жертвы (ряды 11-13) отгорожен от рядов сокомандников стенами
	for(var/wall_x in 10 to 16)
		add_wall(scene_turf(wall_x, 10))
		add_wall(scene_turf(wall_x, 14))
	var/mob/living/simple_animal/hostile/victim_ally = spawn_subject(/mob/living/simple_animal/hostile, 8, 12)
	var/mob/living/simple_animal/hostile/north_ally = spawn_subject(/mob/living/simple_animal/hostile, 8, 16)
	var/mob/living/simple_animal/hostile/south_ally = spawn_subject(/mob/living/simple_animal/hostile, 8, 8)
	spawn_puppet(14, 12)
	TEST_ASSERT(!can_see(north_ally, puppet, 9), "Sanity: the north ally must not see the puppet through the wall")
	TEST_ASSERT(!can_see(south_ally, puppet, 9), "Sanity: the south ally must not see the puppet through the wall")

	//жертва бьёт ближайшего моба - RetaliateAgainst разошлёт herd-контакт
	var/obj/item/scene_blade = new(puppet)
	victim_ally.attacked_by(scene_blade, puppet)

	var/list/timeline = list()
	var/list/transitions = list()
	var/north_contact_at = -1
	var/south_contact_at = -1
	var/gps_violations = 0
	var/elapsed = 0
	while(elapsed < 8 SECONDS)
		sample_scene(victim_ally, elapsed, timeline, transitions)
		if(north_contact_at < 0 && north_ally.ai_controller?.blackboard[BB_AI_STATE] == AI_STATE_SEARCH)
			north_contact_at = elapsed
		if(south_contact_at < 0 && south_ally.ai_controller?.blackboard[BB_AI_STATE] == AI_STATE_SEARCH)
			south_contact_at = elapsed
		//захват сквозь стену без собственного LOS = GPS-волхак
		if(north_ally.ai_controller?.blackboard[BB_AI_CURRENT_TARGET] == puppet && !can_see(north_ally, puppet, 9))
			gps_violations++
		if(south_ally.ai_controller?.blackboard[BB_AI_CURRENT_TARGET] == puppet && !can_see(south_ally, puppet, 9))
			gps_violations++
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		elapsed += AI_SCENE_SAMPLE_INTERVAL

	finish_scenario("pack_contact_share", timeline, transitions, list(
		"north_contact_at_ds" = north_contact_at,
		"south_contact_at_ds" = south_contact_at,
		"gps_violations" = gps_violations,
	))
	TEST_ASSERT(north_contact_at >= 0, "The herd alert must send the north ally investigating")
	TEST_ASSERT(south_contact_at >= 0, "The herd alert must send the south ally investigating")
	TEST_ASSERT(north_contact_at <= 4 SECONDS && south_contact_at <= 4 SECONDS, "Allies must react to the alert within 4s (north [north_contact_at / 10]s, south [south_contact_at / 10]s)")
	TEST_ASSERT_EQUAL(gps_violations, 0, "An ally report shares a POINT: nobody may acquire the attacker through a wall")
	qdel(scene_blade)

//////////// Инфраструктура ////////////

/datum/unit_test/ai_behavior_scenes/proc/scene_turf(x, y)
	RETURN_TYPE(/turf)
	return locate(scene.bottom_left_coords[1] + x - 1, scene.bottom_left_coords[2] + y - 1, scene.bottom_left_coords[3])

///Пол + неразрушимый периметр: мобы не выйдут в резервационный космос
/datum/unit_test/ai_behavior_scenes/proc/build_scene_shell()
	for(var/turf/tile as anything in block(scene_turf(1, 1), scene_turf(AI_SCENE_SIZE, AI_SCENE_SIZE)))
		tile.ChangeTurf(AI_SCENE_FLOOR)
	for(var/edge in 1 to AI_SCENE_SIZE)
		scene_turf(edge, 1).ChangeTurf(AI_SCENE_WALL)
		scene_turf(edge, AI_SCENE_SIZE).ChangeTurf(AI_SCENE_WALL)
		scene_turf(1, edge).ChangeTurf(AI_SCENE_WALL)
		scene_turf(AI_SCENE_SIZE, edge).ChangeTurf(AI_SCENE_WALL)

///Стандартная угловая декорация: стена-РЯД y=13 (x=6..16). Жертва убегает по
///коридору ряда 12 и сворачивает на север за восточным торцом стены (x=17) -
///классический поворот, за которым рвётся линия зрения преследователя.
/datum/unit_test/ai_behavior_scenes/proc/build_corner_wall()
	for(var/wall_x in 6 to 16)
		add_wall(scene_turf(wall_x, 13))

///Дождаться, пока finder подтвердит позицию цели (BB_AI_LAST_KNOWN_POS):
///без подтверждённой улики потеря цели не оставит точки для SEARCH
/datum/unit_test/ai_behavior_scenes/proc/warm_up_engagement(mob/living/simple_animal/hostile/subject, max_wait = 6 SECONDS)
	var/waited = 0
	while(waited < max_wait && isnull(subject.ai_controller?.blackboard[BB_AI_LAST_KNOWN_POS]))
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		waited += AI_SCENE_SAMPLE_INTERVAL
	return !isnull(subject.ai_controller?.blackboard[BB_AI_LAST_KNOWN_POS])

///Дождаться холодного обнаружения (ENGAGE): жертва не убегает, пока охотник
///не увидел её - иначе каденс поиска целей (2с) превращает сценарий в гонку
/datum/unit_test/ai_behavior_scenes/proc/wait_for_engage(mob/living/simple_animal/hostile/subject, max_wait = 8 SECONDS)
	var/waited = 0
	while(waited < max_wait && subject.ai_controller?.blackboard[BB_AI_STATE] != AI_STATE_ENGAGE)
		sleep(AI_SCENE_SAMPLE_INTERVAL)
		waited += AI_SCENE_SAMPLE_INTERVAL
	return subject.ai_controller?.blackboard[BB_AI_STATE] == AI_STATE_ENGAGE

/datum/unit_test/ai_behavior_scenes/proc/add_wall(turf/tile)
	if(!tile || iswallturf(tile))
		return
	built_walls += tile
	tile.ChangeTurf(AI_SCENE_WALL)

/datum/unit_test/ai_behavior_scenes/proc/spawn_subject(mob_type, x, y)
	var/mob/living/simple_animal/hostile/subject = new mob_type(scene_turf(x, y))
	scenario_mobs += subject
	subject.ai_controller?.set_ai_status(AI_STATUS_ON)
	return subject

/datum/unit_test/ai_behavior_scenes/proc/spawn_puppet(x, y)
	puppet = new(scene_turf(x, y))
	SSmobs.clients_by_zlevel[scene_z] |= puppet
	puppet.enable_client_mobs_in_contents()
	puppet_damage_total = 0
	puppet_route = list()
	puppet_step_phase = 0

/datum/unit_test/ai_behavior_scenes/proc/set_puppet_route(list/route, step_every = 2)
	puppet_route = route
	puppet_step_every = step_every

///Один шаг марионетки по маршруту (раз в step_every семплов)
/datum/unit_test/ai_behavior_scenes/proc/advance_puppet()
	if(!length(puppet_route) || QDELETED(puppet))
		return
	puppet_step_phase++
	if(puppet_step_phase % puppet_step_every)
		return
	var/turf/waypoint = puppet_route[1]
	var/turf/puppet_turf = get_turf(puppet)
	if(puppet_turf == waypoint)
		puppet_route.Cut(1, 2)
		if(!length(puppet_route))
			return
		waypoint = puppet_route[1]
	var/turf/next_step = get_step(puppet, get_dir(puppet, waypoint))
	if(next_step && !next_step.is_blocked_turf(source_atom = puppet))
		puppet.Move(next_step, get_dir(puppet, next_step))

///Семпл сцены: шаг марионетки, счёт урона/выстрелов/состояний, лечение жертвы
/datum/unit_test/ai_behavior_scenes/proc/sample_scene(mob/living/simple_animal/hostile/subject, elapsed, list/timeline, list/transitions)
	advance_puppet()

	var/damage_delta = 0
	if(!QDELETED(puppet))
		damage_delta = puppet.getBruteLoss() + puppet.getFireLoss() + puppet.getToxLoss() + puppet.getOxyLoss()
		if(damage_delta > 0)
			puppet_damage_total += damage_delta
			puppet.adjustBruteLoss(-puppet.getBruteLoss())
			puppet.adjustFireLoss(-puppet.getFireLoss())
			puppet.adjustToxLoss(-puppet.getToxLoss())
			puppet.adjustOxyLoss(-puppet.getOxyLoss())
		if(puppet.fire_stacks > 0)
			puppet.adjust_fire_stacks(-puppet.fire_stacks)
			puppet.ExtinguishMob()

	var/shot_fired = 0
	if(!QDELETED(subject) && subject.ranged_cooldown > subject_last_ranged_cooldown)
		shot_fired = 1
		subject_last_ranged_cooldown = subject.ranged_cooldown

	var/state = QDELETED(subject) ? null : subject.ai_controller?.blackboard[BB_AI_STATE]
	var/distance = (QDELETED(subject) || QDELETED(puppet)) ? -1 : get_dist(subject, puppet)
	var/los = (QDELETED(subject) || QDELETED(puppet)) ? FALSE : can_see(subject, puppet, 12)
	var/turf/subject_turf = QDELETED(subject) ? null : get_turf(subject)
	var/turf/puppet_turf = QDELETED(puppet) ? null : get_turf(puppet)
	var/datum/ai_controller/controller = QDELETED(subject) ? null : subject.ai_controller
	var/turf/movement_goal = controller ? get_turf(controller.current_movement_target) : null
	var/turf/search_point = controller ? controller.blackboard[BB_AI_SEARCH_POINT] : null
	var/turf/last_known = controller ? controller.blackboard[BB_AI_LAST_KNOWN_POS] : null
	var/list/snap = list(
		"t_ds" = elapsed,
		"wt_ds" = world.time,
		"state" = state,
		"status" = controller ? controller.ai_status : -1,
		"has_tgt" = controller ? !isnull(controller.blackboard[BB_AI_CURRENT_TARGET]) : FALSE,
		"distance" = distance,
		"los" = los,
		"damage_delta" = damage_delta,
		"shot_fired" = shot_fired,
		"sx" = subject_turf ? subject_turf.x - scene.bottom_left_coords[1] + 1 : -1,
		"sy" = subject_turf ? subject_turf.y - scene.bottom_left_coords[2] + 1 : -1,
		"px" = puppet_turf ? puppet_turf.x - scene.bottom_left_coords[1] + 1 : -1,
		"py" = puppet_turf ? puppet_turf.y - scene.bottom_left_coords[2] + 1 : -1,
		"mtx" = movement_goal ? movement_goal.x - scene.bottom_left_coords[1] + 1 : -1,
		"mty" = movement_goal ? movement_goal.y - scene.bottom_left_coords[2] + 1 : -1,
		"spx" = search_point ? search_point.x - scene.bottom_left_coords[1] + 1 : -1,
		"spy" = search_point ? search_point.y - scene.bottom_left_coords[2] + 1 : -1,
		"lkx" = last_known ? last_known.x - scene.bottom_left_coords[1] + 1 : -1,
		"lky" = last_known ? last_known.y - scene.bottom_left_coords[2] + 1 : -1,
		"search_left_ds" = controller ? max(0, (controller.blackboard[BB_AI_SEARCH_UNTIL] || 0) - world.time) : -1,
	)
	timeline += list(snap)
	var/last_state = length(transitions) ? transitions[length(transitions)]["to"] : null
	if(state != last_state)
		transitions += list(list("t_ds" = elapsed, "from" = last_state, "to" = state))
	return snap

///Записать сценарий в отчёт и разобрать декорацию
/datum/unit_test/ai_behavior_scenes/proc/finish_scenario(scenario_name, list/timeline, list/transitions, list/metrics)
	var/list/entry = list(
		"metrics" = metrics,
		"transitions" = transitions,
		"timeline" = timeline,
	)
	report[scenario_name] = entry
	teardown_scenario()

/datum/unit_test/ai_behavior_scenes/proc/teardown_scenario()
	for(var/mob/living/subject as anything in scenario_mobs)
		qdel(subject)
	scenario_mobs.Cut()
	if(puppet)
		SSmobs.clients_by_zlevel[scene_z] -= puppet
		puppet.clear_important_client_contents()
		qdel(puppet)
		puppet = null
	//снаряды держат ссылки на стрелков - подчищаем прежде чем рушить декорацию
	for(var/turf/tile as anything in block(scene_turf(2, 2), scene_turf(AI_SCENE_SIZE - 1, AI_SCENE_SIZE - 1)))
		for(var/obj/item/projectile/stray in tile)
			qdel(stray)
	for(var/turf/wall_tile as anything in built_walls)
		wall_tile.ChangeTurf(AI_SCENE_FLOOR)
	built_walls.Cut()
	puppet_route = list()
	puppet_step_phase = 0
	subject_last_ranged_cooldown = 0
	puppet_damage_total = 0

#undef AI_SCENE_SIZE
#undef AI_SCENE_SEED
#undef AI_SCENE_SAMPLE_INTERVAL
#undef AI_SCENE_WALL
#undef AI_SCENE_FLOOR

#endif

///Усталость погони. До неё у преследования не было условия окончания вовсе:
///пока держится LOS, цель не теряется, а на открытой лаве LOS не рвётся никогда.
///Прод 9887: watcher вёл ползущего в крите игрока 118 секунд на 26 тайлов.
/datum/unit_test/ai_pursuit_fatigue_ends_endless_chase/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(hunter)
	var/datum/ai_planning_subtree/hostile_fsm/fsm = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]
	TEST_ASSERT_NOTNULL(fsm, "Санити: синглтон FSM-сабтри не найден")

	//свежая погоня от текущей точки бросаться не имеет права
	controller.blackboard[BB_AI_PURSUIT_ORIGIN] = pawn_turf
	controller.blackboard[BB_AI_LAST_EXCHANGE_AT] = world.time
	TEST_ASSERT(!fsm.should_abandon_pursuit(controller), "Свежая погоня не имеет права прерываться")

	//ушли за поводок от точки взятия цели - случай watcher: попадания идут,
	//то есть по обмену уроном погоня "продуктивна", но моб уводится через полкарты
	var/leash_gap = AI_PURSUIT_LEASH + 4
	var/far_x = (pawn_turf.x > leash_gap) ? (pawn_turf.x - leash_gap) : (pawn_turf.x + leash_gap)
	var/turf/far_origin = locate(far_x, pawn_turf.y, pawn_turf.z)
	TEST_ASSERT_NOTNULL(far_origin, "Санити: точка за поводком обязана существовать на карте")
	TEST_ASSERT(get_dist(pawn_turf, far_origin) > AI_PURSUIT_LEASH, "Санити: точка обязана быть именно за поводком")
	controller.blackboard[BB_AI_PURSUIT_ORIGIN] = far_origin
	TEST_ASSERT(fsm.should_abandon_pursuit(controller), "Уход за поводок от точки взятия цели обязан прерывать погоню")

	//обратный случай: моб рядом с домом, но цель не может достать вообще
	controller.blackboard[BB_AI_PURSUIT_ORIGIN] = pawn_turf
	controller.blackboard[BB_AI_LAST_EXCHANGE_AT] = world.time - (AI_PURSUIT_PATIENCE * 2)
	TEST_ASSERT(fsm.should_abandon_pursuit(controller), "Погоня без единого обмена уроном обязана выдохнуться")

	//босс и сценарные преследователи отписаны: их погоня и есть содержание боя
	controller.pursuit_leashed = FALSE
	TEST_ASSERT(!fsm.should_abandon_pursuit(controller), "Отписанный от поводка контроллер погоню не бросает")

	qdel(controller)

///Экстраполяция побега: SEARCH продлевает точку потери LOS вдоль последнего
///наблюдаемого направления движения цели и упирается в геометрию - за угол
///преследователь заворачивает, а не топчется на месте потери.
/datum/unit_test/ai_search_projects_escape_vector/Run()
	var/turf/pawn_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(hunter)
	var/datum/ai_planning_subtree/hostile_fsm/fsm = GLOB.ai_subtrees[/datum/ai_planning_subtree/hostile_fsm]

	var/turf/corner = locate(pawn_turf.x + 2, pawn_turf.y, pawn_turf.z)
	controller.set_blackboard_key(BB_AI_LAST_KNOWN_POS, corner)
	controller.blackboard[BB_AI_LAST_KNOWN_DIR] = NORTH
	fsm.enter_search(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_SEARCH_POINT], locate(corner.x, corner.y + AI_SEARCH_PURSUIT_PROJECTION, corner.z), "SEARCH обязан продлять улику вдоль направления побега")

	//геометрия режет проекцию: стена в двух тайлах останавливает на первом
	var/turf/wall_turf = locate(corner.x, corner.y + 2, corner.z)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)
	fsm.enter_search(controller)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_SEARCH_POINT], locate(corner.x, corner.y + 1, corner.z), "Проекция обязана упираться в геометрию, а не проходить сквозь стену")
	wall_turf.ChangeTurf(saved_turf_type)

	//без наблюдаемого направления проекции нет - розыск стартует с точки потери
	controller.blackboard[BB_AI_LAST_KNOWN_DIR] = null
	fsm.enter_search(controller)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_SEARCH_POINT], "Без наблюдаемого направления SEARCH стартует с точки потери")

	qdel(controller)
