/// Хардделы ксенобио-фермы из прод-раунда 10151 (2026-08-29).
///
/// За 30 минут раунда 126 `/mob/living/carbon/monkey`, 123
/// `/mob/living/simple_animal/slime`, 5 мышей и 8 людей провалили GC с
/// "внешних ссылок: 1" у КАЖДОГО и были снесены хард-делитом по 175-195 мс -
/// суммарно около 52 секунд замороженного сервера. Все пробы warnfail
/// (loc/vis_locs, buckled, mind.current, таймеры, DF_ISPROCESSING, блэкборд AI,
/// клиентские структуры) молчали.
///
/// Файл держит два слоя:
///   1. Фундаментальные замеры - кто вообще способен удержать моба ровно одной
///      ссылкой, невидимой полному ref-скану мира (нативные циклы walk_*).
///   2. Сценарии жизненного цикла фермы - слайм ест обезьяну, гонится за ней,
///      обезьяна огрызается, слайма убивают.
///
/// ВАЖНО: весь жизненный цикл проверяемого моба живёт в отдельном хелпер-проке.
/// BYOND VM пиннит датумы во временных слотах фрейма, поэтому qdel прямо в
/// Run() даёт фантомного держателя, которого не видит ни один скан.

/datum/unit_test/harddel_10151_base
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/harddel_10151_base/Run()
	return

/// Число внешних держателей цели по её ref-строке.
/// Зовётся ТОЛЬКО отдельным проком: локалка и temp-слот locate() сами пиннят датум,
/// EXTERNAL_REFCOUNT вычитает ровно одну локальную ссылку этого фрейма.
/// -1 = ref больше не резолвится (объект физически освобождён - чистая сборка),
/// -2 = ref переиспользован под живой объект.
/datum/unit_test/harddel_10151_base/proc/count_external_refs(ref_string)
	var/datum/leaked = locate(ref_string)
	if(isnull(leaked))
		return -1
	if(!QDELING(leaked))
		return -2
	return EXTERNAL_REFCOUNT(leaked)

/// Даёт миру несколько тиков: асинхронные хвосты (INVOKE_ASYNC, спящие Destroy,
/// нативные циклы движения) должны доехать до замера.
/datum/unit_test/harddel_10151_base/proc/settle(ticks = 3)
	for(var/i in 1 to ticks)
		sleep(world.tick_lag)

/// Замер + отчёт в tests.log. Возвращает число держателей.
/datum/unit_test/harddel_10151_base/proc/measure(list/record, stage)
	var/holders = count_external_refs(record["ref"])
	log_test("[record["label"]] ([stage]): внешних держателей [holders]")
	return holders

/// Полных сканов мира за прогон. Скан по мобу доходит до прохода по атомам -
/// это десятки секунд; диагностике хватает первых нескольких, дальше только счёт.
GLOBAL_VAR_INIT(harddel_10151_scans_done, 0)
#define HARDDEL_10151_MAX_SCANS 4

/// База "чистого" моба по типу: типпас -> число держателей через settle() после qdel.
GLOBAL_LIST_EMPTY(harddel_10151_baselines)

/// Сколько держателей остаётся у ЧИСТОГО моба этого типа.
///
/// Свежеудалённый моб через три тика ещё держится собственным графом - органы,
/// конечности, компоненты и худы сами стоят в очереди сборки и указывают на
/// хозяина. Замер показал базу 4 у обезьяны и у слайма, так что абсолютное число
/// не значит ничего: смысл имеет только ПРЕВЫШЕНИЕ над этой базой. Именно так
/// сценарии сравниваются с контролем - одна переменная за раз.
/datum/unit_test/harddel_10151_base/proc/baseline_for(type_path)
	var/key = "[type_path]"
	var/cached = GLOB.harddel_10151_baselines[key]
	if(!isnull(cached))
		return cached
	var/list/record = spawn_clean_and_qdel(type_path)
	settle()
	var/baseline = max(count_external_refs(record["ref"]), 0)
	GLOB.harddel_10151_baselines[key] = baseline
	log_test("БАЗА [key]: держателей у чистого моба [baseline]")
	return baseline

/// Чистый жизненный цикл в отдельном фрейме: создать и удалить, ничего больше.
/datum/unit_test/harddel_10151_base/proc/spawn_clean_and_qdel(type_path)
	var/mob/living/victim = allocate(type_path, run_loc_floor_bottom_left)
	var/list/record = target_record(victim, "база [type_path]")
	allocated -= victim
	qdel(victim)
	return record

/// Минимальное число держателей, наблюдённое за несколько тиков ожидания.
///
/// Собственный граф моба (органы, компоненты, худы) оседает не за один тик, и
/// разовый замер даёт случайный хвост сверх базы. НАСТОЯЩИЙ держатель ниже базы
/// не опустится никогда, сколько ни жди, - поэтому ждём до первого достижения
/// базы и репортим лучший результат.
/datum/unit_test/harddel_10151_base/proc/settled_holders(list/record, baseline)
	var/best = count_external_refs(record["ref"])
	for(var/attempt in 1 to 20)
		if(best <= baseline)
			break
		settle(2)
		var/current = count_external_refs(record["ref"])
		if(current < best)
			best = current
	log_test("[record["label"]] (осело): внешних держателей [best] при базе [baseline]")
	return best

/// Провал теста с полным скан-логом держателя в harddels.log.
/datum/unit_test/harddel_10151_base/proc/assert_no_holder(list/record)
	settle()
	var/baseline = baseline_for(record["type_path"])
	var/holders = settled_holders(record, baseline)
	if(holders <= baseline)
		return
	if(GLOB.harddel_10151_scans_done < HARDDEL_10151_MAX_SCANS)
		GLOB.harddel_10151_scans_done++
		scan_holders(record, "тест 10151")
	TEST_FAIL("[record["label"]]: после qdel держателей [holders] при базе [baseline] - лишние [holders - baseline]; держатель назван в data/logs/<раунд>/harddels.log")

/// КАЛИБРОВКА измерителя: чистый моб, созданный и удалённый в хелпер-фрейме,
/// обязан показать НОЛЬ держателей. Если этот тест красный - врёт измеритель, а
/// не проверяемый код, и все выводы ниже недействительны.
/datum/unit_test/xenobio_harddel_probe_calibration
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/xenobio_harddel_probe_calibration/proc/measure_clean(type_path, label)
	var/list/record = spawn_clean_and_qdel(type_path)
	settle()
	return measure(record, label)

/datum/unit_test/xenobio_harddel_probe_calibration/Run()
	for(var/type_path in list(/mob/living/carbon/monkey, /mob/living/simple_animal/slime, /mob/living/simple_animal/mouse))
		var/first = measure_clean(type_path, "калибровка [type_path] #1")
		var/second = measure_clean(type_path, "калибровка [type_path] #2")
		//Замер обязан быть ВОСПРОИЗВОДИМЫМ: сравнивать сценарии с базой можно только
		//тогда, когда сама база не гуляет. Ноль тут не ожидается - см. baseline_for().
		TEST_ASSERT_EQUAL(first, second, "База [type_path] не воспроизводится ([first] против [second]) - сравнение с базой недействительно")
		TEST_ASSERT(first >= 0, "База [type_path] отрицательная ([first]): ref не резолвится, измеритель сломан")
		TEST_ASSERT_EQUAL(baseline_for(type_path), first, "baseline_for() не совпал с прямым замером базы [type_path]")

/// ФУНДАМЕНТАЛЬНЫЙ ЗАМЕР: держит ли нативный цикл BYOND (walk_to/walk_away/
/// walk_towards) свою ЦЕЛЬ жёсткой ссылкой после её qdel.
///
/// Такая ссылка невидима любому DM-скану (её нет ни в одной переменной и ни в
/// одном списке), но refcount() её видит - то есть это ровно та сигнатура, что
/// в проде: "внешних ссылок: 1", все пробы молчат, полный скан находит 0 из 1.
/// Кодбаза уже знает про этот класс: spiders.dm:147 и immovable_rod.dm:63.
/datum/unit_test/native_walk_loop_reference
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/native_walk_loop_reference/proc/start_walk_and_qdel(mob/living/walker, mode)
	var/mob/living/simple_animal/slime/quarry = allocate(/mob/living/simple_animal/slime, get_step(run_loc_floor_bottom_left, EAST))
	var/list/record = target_record(quarry, "нативный [mode]: /mob/living/simple_animal/slime")
	switch(mode)
		if("walk_to")
			walk_to(walker, quarry, 1, 5)
		if("walk_away")
			walk_away(walker, quarry, 7, 5)
		if("walk_towards")
			walk_towards(walker, quarry, 5)
	allocated -= quarry
	qdel(quarry)
	return record

/datum/unit_test/native_walk_loop_reference/proc/probe_mode(mob/living/walker, mode)
	var/list/record = start_walk_and_qdel(walker, mode)
	settle()
	var/held = measure(record, "цикл [mode] жив")
	walk(walker, 0)
	settle()
	var/released = measure(record, "после walk(walker, 0)")
	return list("held" = held, "released" = released)

/datum/unit_test/native_walk_loop_reference/Run()
	var/mob/living/carbon/monkey/walker = allocate(/mob/living/carbon/monkey, run_loc_floor_bottom_left)

	var/list/to_result = probe_mode(walker, "walk_to")
	var/list/away_result = probe_mode(walker, "walk_away")
	var/list/towards_result = probe_mode(walker, "walk_towards")

	// Замер, а не догма: если BYOND сам отпускает удалённую цель, held будет 0 и
	// весь класс держателей закрыт - но тогда это надо знать точно.
	log_test("Нативные циклы: walk_to держит [to_result["held"]], walk_away держит [away_result["held"]], walk_towards держит [towards_result["held"]]")

	//ЗАМЕР, а не догма: каждый нативный цикл держит цель РОВНО одной ссылкой, и
	//walk(walker, 0) её отпускает. Ссылка невидима полному ref-скану мира (её нет
	//ни в одной переменной и ни в одном списке) - ровно та сигнатура, что в проде.
	//Поэтому любой сеттер цели у моба обязан гасить нативный цикл.
	TEST_ASSERT_EQUAL(to_result["held"] - to_result["released"], 1, "walk_to обязан держать цель ровно одной ссылкой и отпускать её по walk(walker, 0)")
	TEST_ASSERT_EQUAL(away_result["held"] - away_result["released"], 1, "walk_away обязан держать цель ровно одной ссылкой и отпускать её по walk(walker, 0)")
	TEST_ASSERT_EQUAL(towards_result["held"] - towards_result["released"], 1, "walk_towards обязан держать цель ровно одной ссылкой и отпускать её по walk(walker, 0)")
	TEST_ASSERT_EQUAL(to_result["released"], baseline_for(/mob/living/simple_animal/slime), "После walk(walker, 0) у цели не должно остаться держателей сверх базы")

/// СЦЕНАРИЙ (a): слайм кормится обезьяной, обезьяна умирает от кормёжки, потом
/// её удаляют (рециклер/qdel). Именно этот цикл крутится на ферме сотнями раз.
/datum/unit_test/xenobio_feed_cycle_releases_prey
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/xenobio_feed_cycle_releases_prey/proc/feed_to_death()
	var/turf/pen = run_loc_floor_bottom_left
	var/mob/living/simple_animal/slime/feeder = allocate(/mob/living/simple_animal/slime, pen)
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, get_step(pen, EAST))
	feeder.set_nutrition(feeder.get_starve_nutrition() - 1)
	feeder.set_slime_target(prey)
	feeder.slime_wake_pursuit()
	feeder.Feedon(prey)
	TEST_ASSERT_EQUAL(feeder.buckled, prey, "Sanity: слайм обязан прицепиться к обезьяне")

	for(var/i in 1 to 4)
		feeder.handle_feeding()
	prey.death()
	feeder.handle_feeding() //ветка "жертва умерла": Feedstop + вербовка друга
	TEST_ASSERT_NULL(feeder.buckled, "Sanity: смерть жертвы обязана отцепить слайма")

	var/list/record = target_record(prey, "съеденная обезьяна: /mob/living/carbon/monkey")
	allocated -= prey
	qdel(prey)
	return record

/datum/unit_test/xenobio_feed_cycle_releases_prey/Run()
	assert_no_holder(feed_to_death())

/// СЦЕНАРИЙ (b): слайм гонится за обезьяной, обезьяну удаляют посреди погони.
/// Классический случай фермы - смотритель чистит пен, пока слаймы бегут.
/datum/unit_test/xenobio_chase_releases_deleted_prey
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/xenobio_chase_releases_deleted_prey/proc/chase_and_delete()
	var/turf/pen = run_loc_floor_bottom_left
	var/mob/living/simple_animal/slime/hunter = allocate(/mob/living/simple_animal/slime, pen)
	var/turf/prey_turf = locate(pen.x + 3, pen.y, pen.z)
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, prey_turf)
	hunter.set_nutrition(hunter.get_starve_nutrition() - 1)

	hunter.handle_targets()
	TEST_ASSERT_EQUAL(hunter.Target, prey, "Sanity: голодный слайм обязан взять обезьяну целью")
	drive_ai_planning(hunter.ai_controller)
	hunter.ai_controller.process(0.5)
	TEST_ASSERT_EQUAL(hunter.ai_controller.current_movement_target, prey, "Sanity: погоня обязана поставить цель движения")

	var/list/record = target_record(prey, "цель погони: /mob/living/carbon/monkey")
	allocated -= prey
	qdel(prey)

	// Слайм уходит спать: рядом никого, поведение больше не тикает. Именно так
	// цель и застревала в держателях до конца раунда.
	hunter.ai_controller.set_ai_status(AI_STATUS_IDLE)
	return record

/datum/unit_test/xenobio_chase_releases_deleted_prey/Run()
	assert_no_holder(chase_and_delete())

/// СЦЕНАРИЙ (f): слайма убивают, тушку удаляют. Слаймы утекают почти столько же,
/// сколько обезьяны, - значит и обратная сторона пары обязана собираться.
/datum/unit_test/xenobio_dead_slime_releases
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/xenobio_dead_slime_releases/proc/kill_and_delete()
	var/turf/pen = run_loc_floor_bottom_left
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, get_step(pen, EAST))
	var/mob/living/simple_animal/slime/victim = allocate(/mob/living/simple_animal/slime, pen)
	victim.set_nutrition(victim.get_starve_nutrition() - 1)
	victim.set_slime_target(prey)
	victim.slime_wake_pursuit()

	//обезьяна огрызается: слайм попадает в enemies и становится её target
	prey.retaliate(victim)
	TEST_ASSERT_EQUAL(prey.target, victim, "Sanity: retaliate обязан навести обезьяну на слайма")

	victim.death()
	var/list/record = target_record(victim, "убитый слайм: /mob/living/simple_animal/slime")
	allocated -= victim
	qdel(victim)
	return record

/datum/unit_test/xenobio_dead_slime_releases/Run()
	assert_no_holder(kill_and_delete())

/// СЦЕНАРИЙ: обезьяна наведена на моба-НЕ-обезьяну (вербовка сородичей и смена
/// цели ставят `target` в обход `enemies`, то есть без подписки на qdel), после
/// чего засыпает - рядом нет игрока, `handle_combat()` не тикает и некому
/// заметить, что цель удалена. Уборка в `monkey/Destroy` обходит только
/// GLOB.carbon_list, поэтому слайма/мышь/человека она не спасает.
/datum/unit_test/monkey_target_releases_deleted_mob
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/monkey_target_releases_deleted_mob/proc/aim_and_delete(mob/living/carbon/monkey/hunter, type_path, label)
	var/mob/living/quarry = allocate(type_path, get_step(run_loc_floor_bottom_left, EAST))
	//путь "switch targets"/"recruit other monkies": цель ставится напрямую,
	//без enemies и без подписки на удаление
	hunter.set_monkey_target(quarry)
	hunter.mode = MONKEY_HUNT
	var/list/record = target_record(quarry, label)
	allocated -= quarry
	qdel(quarry)
	return record

/datum/unit_test/monkey_target_releases_deleted_mob/Run()
	var/mob/living/carbon/monkey/hunter = allocate(/mob/living/carbon/monkey, run_loc_floor_bottom_left)

	assert_no_holder(aim_and_delete(hunter, /mob/living/simple_animal/slime, "цель обезьяны: /mob/living/simple_animal/slime"))
	assert_no_holder(aim_and_delete(hunter, /mob/living/simple_animal/mouse, "цель обезьяны: /mob/living/simple_animal/mouse"))
	assert_no_holder(aim_and_delete(hunter, /mob/living/carbon/human, "цель обезьяны: /mob/living/carbon/human"))

/// СЦЕНАРИЙ (e): рециклер перемалывает мёртвую обезьяну.
/datum/unit_test/xenobio_recycler_releases_monkey
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/xenobio_recycler_releases_monkey/proc/grind()
	var/turf/spot = run_loc_floor_bottom_left
	var/obj/machinery/monkey_recycler/grinder = allocate(/obj/machinery/monkey_recycler, spot)
	var/mob/living/carbon/human/operator = allocate(/mob/living/carbon/human, get_step(spot, NORTH))
	var/mob/living/carbon/monkey/carcass = allocate(/mob/living/carbon/monkey, get_step(spot, EAST))
	carcass.death()

	var/list/record = target_record(carcass, "перемолотая обезьяна: /mob/living/carbon/monkey")
	allocated -= carcass
	grinder.stuff_monkey_in(carcass, operator)
	return record

/datum/unit_test/xenobio_recycler_releases_monkey/Run()
	assert_no_holder(grind())

/// СЦЕНАРИЙ (h): мышь. Мыши утекают тем же классом, что обезьяны, - значит
/// держатель общий для любого /mob/living, а не специфичен для ксенобио.
/datum/unit_test/xenobio_mouse_prey_releases
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/xenobio_mouse_prey_releases/proc/hunt_mouse()
	var/turf/pen = run_loc_floor_bottom_left
	var/mob/living/simple_animal/slime/hunter = allocate(/mob/living/simple_animal/slime, pen)
	var/mob/living/simple_animal/mouse/prey = allocate(/mob/living/simple_animal/mouse, get_step(pen, EAST))
	hunter.set_nutrition(hunter.get_starve_nutrition() - 1)
	hunter.set_slime_target(prey)
	hunter.slime_wake_pursuit()
	drive_ai_planning(hunter.ai_controller)
	hunter.ai_controller.process(0.5)

	var/list/record = target_record(prey, "мышь-добыча: /mob/living/simple_animal/mouse")
	allocated -= prey
	qdel(prey)
	hunter.ai_controller.set_ai_status(AI_STATUS_IDLE)
	return record

/datum/unit_test/xenobio_mouse_prey_releases/Run()
	assert_no_holder(hunt_mouse())

/// Консоль ксенобио обязана отпускать оператора, потерявшего клиент.
///
/// `remove_eye_control()` начинается с `if(isnull(user?.client)) return`, а
/// `/mob/Logout()` зовёт `unset_machine()` уже ПОСЛЕ отвязки клиента - то есть
/// штатный выход игрока из тела за консолью проходит мимо всей уборки, и
/// `console.current_user` держит тело до конца раунда. `unset_machine()` при
/// этом обнуляет `mob.machine`, так что второго шанса убраться не будет.
/datum/unit_test/xenobio_console_releases_clientless_user
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/xenobio_console_releases_clientless_user/proc/seat_and_drop(obj/machinery/computer/camera_advanced/xenobio/console)
	var/mob/living/carbon/human/operator = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	//состояние, в котором игрока застаёт логаут: контроль выдан, клиента уже нет
	console.current_user = operator
	console.eyeobj.eye_user = operator
	operator.remote_control = console.eyeobj
	console.GrantActions(operator)
	operator.set_machine(console)

	var/list/record = target_record(operator, "оператор консоли ксенобио: /mob/living/carbon/human")
	allocated -= operator
	operator.unset_machine() //ровно то, что делает /mob/Logout()
	qdel(operator)
	return record

/datum/unit_test/xenobio_console_releases_clientless_user/Run()
	var/obj/machinery/computer/camera_advanced/xenobio/console = allocate(/obj/machinery/computer/camera_advanced/xenobio, run_loc_floor_bottom_left)
	if(isnull(console.eyeobj)) //глаз консоль заводит лениво, на первом обращении
		console.CreateEye()
	TEST_ASSERT_NOTNULL(console.eyeobj, "Sanity: консоли нужен глаз, иначе сценарий не воспроизводится")

	var/list/record = seat_and_drop(console)
	TEST_ASSERT_NULL(console.current_user, "Консоль удержала оператора, ушедшего без клиента")
	TEST_ASSERT_NULL(console.eyeobj.eye_user, "Глаз консоли удержал оператора, ушедшего без клиента")
	assert_no_holder(record)

/// ИНТЕГРАЦИЯ: маленький загон фермы. Слаймы и обезьяны варятся вместе, потом
/// смотритель уходит (клиентов рядом больше нет), и только ПОСЛЕ этого пару
/// удаляют - ровно порядок событий прод-раунда 10151.
/datum/unit_test/xenobio_farm_pen_releases_pair
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/xenobio_farm_pen_releases_pair/proc/run_pen(mob/living/carbon/human/keeper)
	var/turf/pen = run_loc_floor_bottom_left
	var/list/slimes = list()
	var/list/monkeys = list()
	for(var/i in 1 to 2)
		slimes += allocate(/mob/living/simple_animal/slime, locate(pen.x + i, pen.y, pen.z))
		monkeys += allocate(/mob/living/carbon/monkey, locate(pen.x + i, pen.y + 1, pen.z))

	for(var/mob/living/simple_animal/slime/hungry as anything in slimes)
		hungry.set_nutrition(hungry.get_starve_nutrition() - 1)
		hungry.handle_targets()
		drive_ai_planning(hungry.ai_controller)
		hungry.ai_controller.process(0.5)

	//обезьяны огрызаются и вербуют сородичей - именно так target расползается
	//по загону мимо enemies
	var/mob/living/simple_animal/slime/first_slime = slimes[1]
	for(var/mob/living/carbon/monkey/ape as anything in monkeys)
		ape.retaliate(first_slime)
		ape.handle_combat()
	var/mob/living/carbon/monkey/recruit = monkeys[2]
	recruit.set_monkey_target(slimes[2])
	recruit.mode = MONKEY_HUNT

	//смотритель ушёл: handle_combat() обезьян больше не тикает
	unregister_fake_player(keeper)
	for(var/mob/living/simple_animal/slime/dozing as anything in slimes)
		dozing.ai_controller.set_ai_status(AI_STATUS_IDLE)

	var/mob/living/carbon/monkey/doomed_monkey = monkeys[1]
	var/mob/living/simple_animal/slime/doomed_slime = slimes[2]
	var/list/records = list(
		target_record(doomed_monkey, "загон: /mob/living/carbon/monkey"),
		target_record(doomed_slime, "загон: /mob/living/simple_animal/slime"),
	)
	allocated -= doomed_monkey
	allocated -= doomed_slime
	qdel(doomed_monkey)
	qdel(doomed_slime)
	return records

/datum/unit_test/xenobio_farm_pen_releases_pair/Run()
	var/mob/living/carbon/human/keeper = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	register_fake_player(keeper, run_loc_floor_bottom_left)

	var/list/records = run_pen(keeper)
	for(var/list/record as anything in records)
		assert_no_holder(record)

/// Проба warnfail обязана НАЗЫВАТЬ держателя этого класса.
///
/// В прод-раунде 10151 строка улик была пустой у всех 262 хардделов - потому что
/// ни одна проверка не смотрела в переменные соседних мобов. Тест проверяет обе
/// стороны контракта: держателя проба находит, а на чистом мобе молчит (иначе
/// улика превратится в шум на каждом warnfail).
/datum/unit_test/warnfail_probe_names_mob_target_holder
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/warnfail_probe_names_mob_target_holder/Run()
	var/mob/living/carbon/monkey/holder = allocate(/mob/living/carbon/monkey, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/slime/quarry = allocate(/mob/living/simple_animal/slime, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/simple_animal/slime/innocent = allocate(/mob/living/simple_animal/slime, get_step(run_loc_floor_bottom_left, WEST))

	var/list/silent = SSgarbage.collect_mob_target_holders(innocent)
	TEST_ASSERT(!length(silent), "Проба выдала улику на мобе, которого никто не держит: [length(silent) ? silent[1] : ""]")

	holder.target = quarry
	var/list/found = SSgarbage.collect_mob_target_holders(quarry)
	TEST_ASSERT_EQUAL(length(found), 1, "Проба не нашла держателя в monkey.target")
	TEST_ASSERT(findtext(found[1], "/mob/living/carbon/monkey"), "Улика не называет тип держателя: [found[1]]")
	TEST_ASSERT(findtext(found[1], "target"), "Улика не называет переменную-держателя: [found[1]]")

	holder.target = null
	var/mob/living/simple_animal/slime/slime_holder = innocent
	slime_holder.Target = quarry
	var/list/slime_found = SSgarbage.collect_mob_target_holders(quarry)
	TEST_ASSERT_EQUAL(length(slime_found), 1, "Проба не нашла держателя в slime.Target")
	slime_holder.Target = null

	// Полная строка улик warnfail обязана донести находку до лога. Цель уводим в
	// nullspace: живой моб на турфе даёт улику "всё ещё в loc", а проба держателей
	// намеренно ищет только там, где остальные промолчали.
	holder.target = quarry
	quarry.moveToNullspace()
	var/context = SSgarbage.build_warnfail_context(quarry)
	holder.target = null
	quarry.forceMove(get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT(findtext(context, "держит"), "Строка улик warnfail не содержит держателя: [context]")

/// Полный путь SSmobs, а не отдельные проки: мобы прогоняются через настоящий
/// `Life()` - с троттлом, гейтом "рядом есть игрок", боевым автоматом обезьяны и
/// нативными циклами движения. Именно на этом пути живёт прод.
/datum/unit_test/xenobio_life_driven_pen_releases
	parent_type = /datum/unit_test/harddel_10151_base

/// Один проход SSmobs руками: Life() каждому участнику загона.
/datum/unit_test/xenobio_life_driven_pen_releases/proc/run_life(list/pen_mobs, fires)
	for(var/fire in 1 to fires)
		for(var/mob/living/participant as anything in pen_mobs)
			if(QDELETED(participant))
				continue
			participant.Life(2, SSmobs.times_fired + fire)

/datum/unit_test/xenobio_life_driven_pen_releases/proc/simulate(mob/living/carbon/human/keeper)
	var/turf/pen = run_loc_floor_bottom_left
	var/mob/living/simple_animal/slime/hunter = allocate(/mob/living/simple_animal/slime, locate(pen.x + 1, pen.y, pen.z))
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, locate(pen.x + 2, pen.y, pen.z))
	hunter.set_nutrition(hunter.get_starve_nutrition() - 1)
	prey.aggressive = TRUE //агрессивная обезьяна берёт цель мимо enemies - путь без подписки

	var/list/pen_mobs = list(hunter, prey)
	run_life(pen_mobs, 4)
	//обезьяна отбивается от слайма, слайм гонится за обезьяной
	prey.retaliate(hunter)
	hunter.set_slime_target(prey)
	hunter.slime_wake_pursuit()
	run_life(pen_mobs, 4)

	//смотритель ушёл из загона: обезьяний handle_combat() больше не вызывается
	unregister_fake_player(keeper)
	run_life(pen_mobs, 2)

	var/list/record = target_record(hunter, "загон под Life: /mob/living/simple_animal/slime")
	allocated -= hunter
	qdel(hunter)
	//мир продолжает жить: у уборки есть все шансы доехать
	run_life(list(prey), 4)
	return record

/datum/unit_test/xenobio_life_driven_pen_releases/Run()
	var/mob/living/carbon/human/keeper = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	register_fake_player(keeper, run_loc_floor_bottom_left)
	assert_no_holder(simulate(keeper))

/// Кот и мышь: `movement_target` кота чистится ТОЛЬКО внутри
/// `handle_automated_movement()` и только раз в шесть тиков, да ещё под гейтом
/// "жив, стоит, не пристёгнут". Кот в шкафу, спящий, мёртвый или с выключенным
/// ИИ держит удалённую мышь бессрочно - плюс нативный `walk_to()`, который
/// вообще никакому DM-скану не виден. В раунде 10151 утекло 5 мышей.
/datum/unit_test/pet_cat_releases_deleted_mouse
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/pet_cat_releases_deleted_mouse/proc/chase_and_delete(mob/living/simple_animal/pet/cat/hunter)
	var/mob/living/simple_animal/mouse/snack = allocate(/mob/living/simple_animal/mouse, get_step(run_loc_floor_bottom_left, EAST))
	//то же состояние, что оставляет handle_automated_movement коту при добыче
	hunter.set_cat_movement_target(snack)
	hunter.stop_automated_movement = 1
	walk_to(hunter, snack, 0, 3)

	var/list/record = target_record(snack, "добыча кота: /mob/living/simple_animal/mouse")
	allocated -= snack
	qdel(snack)
	//кот засыпает: автодвижение больше не тикает, чистить цель некому
	hunter.toggle_ai(AI_OFF)
	return record

/datum/unit_test/pet_cat_releases_deleted_mouse/Run()
	var/mob/living/simple_animal/pet/cat/hunter = allocate(/mob/living/simple_animal/pet/cat, run_loc_floor_bottom_left)
	assert_no_holder(chase_and_delete(hunter))

#undef HARDDEL_10151_MAX_SCANS
