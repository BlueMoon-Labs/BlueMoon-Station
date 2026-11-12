// ===== Орда hostile-мобов: экономия ИИ на стае =====
//
// Обычный прогон проверяет инварианты экономии счётчиками, а не временем: общие на стаю
// отказы can_attack и oview, пропуск неизменного подхода и плана. Живой замер орды
// (120 мобов против бегающих людей, профиль по поведениям) включается сборкой с
// --define=AI_HORDE_BENCH и пишет data/horde_profile_<вариант>.json.

/mob/living/simple_animal/hostile/unit_test_horde
	faction = list("unit_test_horde")
	melee_damage_lower = 0
	melee_damage_upper = 0
	maxHealth = 1000
	health = 1000
	///Сколько раз на этой особи звался CanAttack
	var/can_attack_calls = 0

/mob/living/simple_animal/hostile/unit_test_horde/CanAttack(atom/the_target)
	can_attack_calls++
	return ..()

///Заражённый из тест-мержа Black Mesa: дальнозоркий, ищет ещё и объекты
/mob/living/simple_animal/hostile/unit_test_horde/infected_like
	vision_range = 25
	aggro_vision_range = 30
	robust_searching = 1
	search_objects = 1
	speed = 0
	turns_per_move = 0

/mob/living/simple_animal/hostile/unit_test_horde/infected_like/Initialize(mapload)
	. = ..()
	wanted_objects = typecacheof(list(/obj/structure/reagent_dispensers/fueltank), TRUE)

///Эталон фильтра пула без общей памяти: candidate_passes() на каждого кандидата
/proc/horde_reference_filter(mob/living/simple_animal/hostile/hunter, list/pool)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(hunter.ai_controller.blackboard[BB_AI_TARGETING_STRATEGY])
	. = list()
	for(var/atom/candidate as anything in pool)
		if(finder.candidate_passes(hunter, candidate, strategy, hunter.vision_range, FALSE))
			. += candidate

/proc/horde_filter(mob/living/simple_animal/hostile/hunter, list/pool, datum/ai_pack_scan/pack_scan)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(hunter.ai_controller.blackboard[BB_AI_TARGETING_STRATEGY])
	return finder.filter_candidates(hunter, hunter, pool, strategy, hunter.vision_range, null, null, pack_scan)

/proc/horde_pack_scan(mob/living/simple_animal/hostile/hunter)
	return ai_pack_scan_for(hunter, GET_TARGETING_STRATEGY(hunter.ai_controller?.blackboard[BB_AI_TARGETING_STRATEGY] || /datum/targeting_strategy/hostile_legacy))

///Сородичи делят отказы: второй скан не прогоняет CanAttack по союзникам, а результат тот же
/datum/unit_test/hostile_ai_horde_pack_rejections/Run()
	ai_pack_scans_reset()
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/list/horde = list()
	for(var/index in 1 to 20)
		horde += allocate(/mob/living/simple_animal/hostile/unit_test_horde, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/unit_test_horde/first = horde[1]
	var/mob/living/simple_animal/hostile/unit_test_horde/second = horde[2]
	var/list/pool = horde + prey

	var/list/reference = horde_reference_filter(first, pool - first)
	TEST_ASSERT_EQUAL(length(reference), 1, "Only the human must pass the reference filter")
	TEST_ASSERT(reference[1] == prey, "Only the human must pass the reference filter")

	var/datum/ai_pack_scan/pack_scan = horde_pack_scan(first)
	TEST_ASSERT_NOTNULL(pack_scan, "Plain hostiles of one type and faction must share a pack scan")
	TEST_ASSERT(GLOB.ai_pack_scan_reset_armed, "A new pack scan window must arm its reset")
	TEST_ASSERT(horde_pack_scan(second) == pack_scan, "Packmates must get the same pack scan inside one window")

	first.can_attack_calls = 0
	var/list/first_result = horde_filter(first, pool - first, pack_scan)
	TEST_ASSERT(first_result ~= reference, "The pack filter must match the reference for the first scanner")
	TEST_ASSERT_EQUAL(first.can_attack_calls, length(pool) - 1, "The first scanner pays for every candidate")

	second.can_attack_calls = 0
	var/list/second_result = horde_filter(second, pool - second, pack_scan)
	TEST_ASSERT(second_result ~= reference, "The pack filter must match the reference for a packmate")
	//первого сканера в его собственном пуле не было, а годная цель перепроверяется всегда
	TEST_ASSERT_EQUAL(second.can_attack_calls, 2, "A packmate must re-check only the human and the first scanner")

	//питомец первого сканера (его личная фракция-ссылка) отвергнут первым, но сородичу не союзник
	var/mob/living/simple_animal/hostile/unit_test_horde/pet = horde[4]
	pet.faction = list("someone_else", REF(first))
	pack_scan.rejected -= pet
	pack_scan.note_rejection(pet, REF(first))
	TEST_ASSERT(!pack_scan.rejected[pet], "A rejection through the hunter's own faction ref must stay personal")
	pack_scan.note_rejection(prey, REF(first))
	TEST_ASSERT(pack_scan.rejected[prey], "Sanity: a plain rejection is shared")
	pack_scan.rejected -= prey

	var/mob/living/simple_animal/hostile/unit_test_horde/grudge_holder = horde[3]
	grudge_holder.foes = list()
	grudge_holder.foes[prey] = 1
	TEST_ASSERT_NULL(horde_pack_scan(grudge_holder), "A hostile with personal foes must not share rejections")
	grudge_holder.foes = null

	var/mob/living/simple_animal/hostile/gorilla/ape = allocate(/mob/living/simple_animal/hostile/gorilla, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(horde_pack_scan(ape), "A type whose CanAttack reads its own state must not share rejections")

	ai_pack_scans_reset()
	TEST_ASSERT(QDELETED(pack_scan), "The window reset must delete the pack scan")
	TEST_ASSERT(!length(GLOB.ai_pack_scans), "The window reset must drop every pack scan")
	TEST_ASSERT(!GLOB.ai_pack_scan_reset_armed, "The window reset must disarm itself")

///oview объектов берётся у сородича, только что смотревшего почти с той же точки
/datum/unit_test/hostile_ai_horde_shared_object_scan/Run()
	ai_pack_scans_reset()
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	allocate(/obj/structure/reagent_dispensers/fueltank, run_loc_floor_top_right)
	var/turf/first_spot = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/unit_test_horde/infected_like/first = allocate(/mob/living/simple_animal/hostile/unit_test_horde/infected_like, first_spot)
	var/mob/living/simple_animal/hostile/unit_test_horde/infected_like/neighbour = allocate(/mob/living/simple_animal/hostile/unit_test_horde/infected_like, get_step(first_spot, NORTH))
	var/mob/living/simple_animal/hostile/unit_test_horde/infected_like/far = allocate(/mob/living/simple_animal/hostile/unit_test_horde/infected_like, locate(first_spot.x + 4, first_spot.y + 4, first_spot.z))
	var/datum/ai_pack_scan/pack_scan = horde_pack_scan(first)
	TEST_ASSERT_NOTNULL(pack_scan, "Object hunters of one type must share a pack scan")

	var/list/first_hits = finder.find_wanted_objects(first, 25, pack_scan)
	TEST_ASSERT(finder.find_wanted_objects(neighbour, 25, pack_scan) == first_hits, "A packmate one tile away must reuse the stored object scan")
	TEST_ASSERT(finder.find_wanted_objects(neighbour, 9, pack_scan) != first_hits, "Another scan range must not reuse the stored object scan")
	TEST_ASSERT(finder.find_wanted_objects(far, 25, pack_scan) != first_hits, "A packmate four tiles away must look for itself")
	ai_pack_scans_reset()
	ai_pack_object_scans_reset()
	TEST_ASSERT(!length(GLOB.ai_pack_object_scans), "The object window reset must drop every stored scan")

///Клетки вокруг цели стая проверяет один раз за тик, ответ совпадает с прямой проверкой
/datum/unit_test/hostile_ai_horde_approach_tile_memo/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	allocate(/obj/structure/table, get_step(center, WEST))
	var/mob/living/simple_animal/hostile/unit_test_horde/first = allocate(/mob/living/simple_animal/hostile/unit_test_horde, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/unit_test_horde/second = allocate(/mob/living/simple_animal/hostile/unit_test_horde, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/unit_test_horde/climber = allocate(/mob/living/simple_animal/hostile/unit_test_horde, run_loc_floor_bottom_left)
	climber.pass_flags |= PASSTABLE
	for(var/direction in GLOB.alldirs)
		var/turf/tile = get_step(center, direction)
		var/expected = first.ai_controller.can_enter_turf(tile) && !tile.is_blocked_turf(source_atom = first)
		TEST_ASSERT_EQUAL(ai_approach_tile_open(first.ai_controller, tile), expected, "The pack tile check must match the direct check")
		TEST_ASSERT_EQUAL(ai_approach_tile_open(second.ai_controller, tile), expected, "A packmate must get the same answer")
	var/turf/table_tile = get_step(center, WEST)
	TEST_ASSERT(!ai_approach_tile_open(first.ai_controller, table_tile), "Sanity: the table blocks a plain hostile")
	TEST_ASSERT(ai_approach_tile_open(climber.ai_controller, table_tile), "A table climber must not reuse the plain hostile's answer")

///Подход без сдвигов не перепроверяется каждый проход, но любой сдвиг или конец окна - перепроверка
/datum/unit_test/hostile_ai_horde_melee_approach_skip/Run()
	var/datum/ai_behavior/hostile_melee_attack/melee = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)
	var/mob/living/simple_animal/hostile/unit_test_horde/chaser = allocate(/mob/living/simple_animal/hostile/unit_test_horde, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/datum/ai_controller/controller = chaser.ai_controller
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	TEST_ASSERT(melee.setup(controller, BB_AI_CURRENT_TARGET), "Melee must set up against a valid target")

	TEST_ASSERT_EQUAL(melee.perform(0.1, controller, BB_AI_CURRENT_TARGET), AI_BEHAVIOR_INSTANT, "A distant target means we are still approaching")
	TEST_ASSERT(controller.approach_probe_until > world.time, "An approach pass must remember its snapshot")

	chaser.can_attack_calls = 0
	TEST_ASSERT_EQUAL(melee.perform(0.1, controller, BB_AI_CURRENT_TARGET), AI_BEHAVIOR_INSTANT, "An unchanged approach stays an approach")
	TEST_ASSERT_EQUAL(chaser.can_attack_calls, 0, "An unchanged approach must not re-run the checks")

	prey.forceMove(get_step(prey, NORTH))
	melee.perform(0.1, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(chaser.can_attack_calls, 0, "A target that is still out of reach needs no re-check")

	prey.forceMove(get_step(chaser, EAST))
	TEST_ASSERT_EQUAL(melee.perform(0.1, controller, BB_AI_CURRENT_TARGET), AI_BEHAVIOR_DELAY, "A target that stepped next to us must be attacked at once")
	TEST_ASSERT_EQUAL(chaser.can_attack_calls, 1, "A target in reach must re-run the checks")

	prey.forceMove(locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y + 3, run_loc_floor_bottom_left.z))
	melee.perform(0.1, controller, BB_AI_CURRENT_TARGET)
	chaser.can_attack_calls = 0
	controller.approach_probe_until = world.time
	melee.perform(0.1, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(chaser.can_attack_calls, 1, "An expired snapshot must re-run the checks")

	//годность цели перепроверяется не реже окна: невалидная цель бросается самое позднее с ним
	prey.status_flags |= GODMODE
	TEST_ASSERT_EQUAL(melee.perform(0.1, controller, BB_AI_CURRENT_TARGET), AI_BEHAVIOR_INSTANT, "Inside the window the approach keeps going")
	controller.approach_probe_until = world.time
	TEST_ASSERT(melee.perform(0.1, controller, BB_AI_CURRENT_TARGET) & AI_BEHAVIOR_FAILED, "Once the window ends an invalid target must be dropped")
	prey.status_flags &= ~GODMODE
	melee.finish_action(controller, FALSE, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(controller.approach_probe_until, 0, "Finishing the behavior must drop the snapshot")

///Неизменный план пропускается не больше одного раза подряд и сбрасывается любым сдвигом
/datum/unit_test/hostile_ai_horde_plan_skip/Run()
	var/mob/living/simple_animal/hostile/unit_test_horde/chaser = allocate(/mob/living/simple_animal/hostile/unit_test_horde, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/datum/ai_controller/hostile_adapter/controller = chaser.ai_controller
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.set_blackboard_key(BB_AI_STATE, AI_STATE_ENGAGE)

	controller.SelectBehaviors(0.5)
	TEST_ASSERT(length(controller.current_behaviors), "An engaged hostile must plan something")
	TEST_ASSERT(!controller.plan_probe_skipped, "The first plan is never skipped")
	controller.SelectBehaviors(0.5)
	TEST_ASSERT(controller.plan_probe_skipped, "An unchanged hostile skips one plan")
	controller.SelectBehaviors(0.5)
	TEST_ASSERT(!controller.plan_probe_skipped, "Two plans in a row are never skipped")

	controller.SelectBehaviors(0.5)
	TEST_ASSERT(controller.plan_probe_skipped, "Sanity: settled again")
	chaser.forceMove(get_step(chaser, NORTH))
	controller.SelectBehaviors(0.5)
	TEST_ASSERT(!controller.plan_probe_skipped, "A pawn that moved must plan")

	controller.SelectBehaviors(0.5)
	TEST_ASSERT(controller.plan_probe_skipped, "Sanity: settled after the move")
	controller.SelectBehaviors(0.5)
	chaser.adjustBruteLoss(10)
	controller.SelectBehaviors(0.5)
	TEST_ASSERT(!controller.plan_probe_skipped, "A pawn that took damage must plan")

/mob/living/simple_animal/hostile/unit_test_horde/plan_charger
	charger = TRUE

/mob/living/simple_animal/hostile/unit_test_horde/plan_boss
	ai_profile_type = /datum/ai_controller/hostile_adapter/boss

///Кулдаун способности моба кончился между планами: способность ставится в тот же план, а не через пропущенный
/datum/unit_test/hostile_ai_horde_plan_skip_ability_timer/Run()
	var/mob/living/simple_animal/hostile/unit_test_horde/plan_charger/charger = allocate(/mob/living/simple_animal/hostile/unit_test_horde/plan_charger, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + charger.charge_distance, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/datum/ai_controller/hostile_adapter/controller = charger.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/brute_charger), "Sanity: a charger must get the charger profile")
	var/datum/ai_behavior/charge = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_charge)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.set_blackboard_key(BB_AI_STATE, AI_STATE_ENGAGE)
	COOLDOWN_START(charger, charge_cooldown, 1 MINUTES)

	controller.SelectBehaviors(0.5)
	TEST_ASSERT(!(charge in controller.current_behaviors), "Sanity: no charge while it cools down")
	controller.SelectBehaviors(0.5)
	TEST_ASSERT(controller.plan_probe_skipped, "Sanity: a settled charger skips a plan")
	controller.SelectBehaviors(0.5)
	COOLDOWN_RESET(charger, charge_cooldown)
	controller.SelectBehaviors(0.5)
	TEST_ASSERT(!controller.plan_probe_skipped, "A charge that came off cooldown must not wait out a skipped plan")
	TEST_ASSERT(charge in controller.current_behaviors, "A charge that came off cooldown must be planned at once")

///Готовность каста визарда входит в сводку плана, как и у чарджа
/datum/unit_test/hostile_ai_horde_plan_signature_caster/Run()
	var/mob/living/simple_animal/hostile/wizard/caster = allocate(/mob/living/simple_animal/hostile/wizard, run_loc_floor_bottom_left)
	var/datum/ai_controller/hostile_adapter/controller = caster.ai_controller
	caster.next_cast = world.time + 1 MINUTES
	var/cooling_signature = controller.plan_signature()
	caster.next_cast = world.time
	TEST_ASSERT(controller.plan_signature() != cooling_signature, "A spell coming off cooldown must change the plan signature")

///Босс никогда не пропускает план: темп его способностей и есть содержание боя
/datum/unit_test/hostile_ai_horde_plan_skip_boss/Run()
	var/mob/living/simple_animal/hostile/unit_test_horde/plan_boss/boss = allocate(/mob/living/simple_animal/hostile/unit_test_horde/plan_boss, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/datum/ai_controller/hostile_adapter/controller = boss.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/boss), "Sanity: the boss profile must be used")
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.set_blackboard_key(BB_AI_STATE, AI_STATE_ENGAGE)
	for(var/i in 1 to 3)
		controller.SelectBehaviors(0.5)
		TEST_ASSERT(length(controller.current_behaviors), "Sanity: an engaged boss must plan something")
		TEST_ASSERT(!controller.plan_probe_skipped, "A boss must plan every time, plan [i] was skipped")

#ifdef AI_HORDE_BENCH

#define HORDE_ARENA_SIZE 40
#define HORDE_MOB_COUNT 120
#define HORDE_WARMUP (2 SECONDS)
#define HORDE_SEGMENT_TIME (5 SECONDS)

GLOBAL_VAR_INIT(ai_horde_savings, TRUE)
GLOBAL_VAR_INIT(ai_path_savings, TRUE)
///Счётчики поведения орды за сегмент: поиски пути, удачные шаги, застрявшие, удары
GLOBAL_LIST_EMPTY(horde_path_notes)
///Что бенч суммирует из профиля: полное имя прока -> короткое
GLOBAL_LIST_INIT(horde_bench_procs, list(
	"/datum/ai_controller/process" = "process",
	"/datum/ai_controller/hostile_adapter/SelectBehaviors" = "plan",
	"/datum/ai_behavior/find_potential_targets/perform" = "finder",
	"/datum/ai_behavior/hostile_melee_attack/perform" = "melee",
	"/mob/living/simple_animal/hostile/proc/MeleeAction" = "attack",
	"/datum/ai_behavior/ranged_skirmish/proc/fire_at" = "attack",
	"/datum/controller/subsystem/movement/fire" = "movement",
	"/proc/get_path_to" = "path",
	"/mob/living/simple_animal/proc/can_safely_enter_turf" = "safe",
	"/turf/proc/LinkBlockedWithAccess" = "link",
	"/datum/ai_controller/proc/best_reposition_tile" = "reposition",
	"/mob/living/simple_animal/hostile/proc/ranged_fire_lane_state" = "lane",
))

/mob/living/simple_animal/hostile/unit_test_horde/ranged
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 6
	ranged_cooldown_time = 3 SECONDS
	projectiletype = /obj/item/projectile/beam/disabler
	projectilesound = 'sound/weapons/laser.ogg'

/mob/living/simple_animal/hostile/unit_test_horde/charger
	charger = TRUE

///Живая орда в зале со столбами и столами против шести бегающих людей, через настоящий МК
/datum/unit_test/hostile_ai_horde_bench
	priority = TEST_LONGER
	var/datum/turf_reservation/arena
	var/mob/dead/observer/watcher
	var/list/spawned = list()
	///Какую экономию бенч выключает в сегментах off
	var/savings_toggle = "horde"
	///Сегментов замера, по половине на режим, порядок ABBA
	var/segments = 4
	var/segment_time = HORDE_SEGMENT_TIME

/datum/unit_test/hostile_ai_horde_bench/proc/set_savings(on)
	if(savings_toggle == "path")
		GLOB.ai_path_savings = on
	else
		GLOB.ai_horde_savings = on

/datum/unit_test/hostile_ai_horde_bench/proc/arena_turf(x, y)
	return locate(arena.bottom_left_coords[1] + x - 1, arena.bottom_left_coords[2] + y - 1, arena.bottom_left_coords[3])

/datum/unit_test/hostile_ai_horde_bench/Run()
	arena = SSmapping.RequestBlockReservation(HORDE_ARENA_SIZE, HORDE_ARENA_SIZE)
	TEST_ASSERT_NOTNULL(arena, "Failed to reserve the horde arena")
	for(var/x in 1 to HORDE_ARENA_SIZE)
		for(var/y in 1 to HORDE_ARENA_SIZE)
			var/turf/tile = arena_turf(x, y)
			if(x == 1 || y == 1 || x == HORDE_ARENA_SIZE || y == HORDE_ARENA_SIZE || (x % 6 == 0 && (y % 6 == 0 || y % 6 == 1)))
				tile.ChangeTurf(/turf/closed/indestructible/wall)
				continue
			tile.ChangeTurf(/turf/open/indestructible/boss/air)
			//грязь на клетке сливается в одну, слитые копии сразу в qdel и держать их нельзя
			for(var/i in 1 to 3)
				var/obj/effect/decal/cleanable/dirt/dirt = new(tile)
				if(!QDELETED(dirt))
					spawned += dirt
	for(var/x in list(10, 30))
		for(var/y in 12 to 28)
			if(y % 4)
				spawned += new /obj/structure/table(arena_turf(x, y))
	var/arena_z = arena_turf(1, 1).z
	if(!islist(SSmobs.clients_by_zlevel) || arena_z > length(SSmobs.clients_by_zlevel))
		SSmobs.MaxZChanged()
	watcher = new(arena_turf(20, 20))
	SSmobs.clients_by_zlevel[arena_z] |= watcher

	run_variant("melee", /mob/living/simple_animal/hostile/unit_test_horde)
	run_variant("infected", /mob/living/simple_animal/hostile/unit_test_horde/infected_like)
	run_variant("ranged", /mob/living/simple_animal/hostile/unit_test_horde/ranged)
	run_variant("charger", /mob/living/simple_animal/hostile/unit_test_horde/charger)

	SSmobs.clients_by_zlevel[arena_z] -= watcher
	QDEL_NULL(watcher)
	QDEL_LIST(spawned)
	QDEL_NULL(arena)

/datum/unit_test/hostile_ai_horde_bench/proc/run_variant(tag, mob_type)
	var/list/humans = list()
	for(var/list/spot as anything in list(list(8, 8), list(32, 32), list(8, 32), list(32, 8), list(20, 14), list(20, 26)))
		humans += new /mob/living/carbon/human(arena_turf(spot[1], spot[2]))
	var/list/mobs = list()
	for(var/index in 1 to HORDE_MOB_COUNT)
		var/turf/spot = arena_turf(3 + ((index * 7) % 34), 3 + ((index * 13) % 34))
		if(spot.density)
			spot = get_step(spot, EAST)
		var/mob/living/simple_animal/hostile/horde_mob = new mob_type(spot)
		mobs += horde_mob
		horde_mob.ai_controller.can_idle = FALSE
		horde_mob.ai_controller.set_ai_status(AI_STATUS_ON)
	sleep(HORDE_WARMUP)
	//с экономией и без в одном мире, порядок ABBA гасит дрейф фоновой нагрузки
	var/list/totals = list("on" = list(), "off" = list())
	var/list/notes = list("on" = list(), "off" = list())
	for(var/segment in 1 to segments)
		var/mode = (segment % 4 < 2) ? "on" : "off"
		set_savings(mode == "on")
		GLOB.horde_path_notes = list()
		var/moves_before = GLOB.ai_metrics.successful_moves
		var/searches_before = GLOB.ai_metrics.jps_requests
		var/list/start_spots = list()
		for(var/mob/living/horde_mob as anything in mobs)
			start_spots += horde_mob.loc
		ai_pack_scans_reset()
		ai_pack_object_scans_reset()
		world.Profile(PROFILE_CLEAR)
		world.Profile(PROFILE_START)
		var/elapsed = 0
		while(elapsed < segment_time)
			sleep(5)
			elapsed += 5
			for(var/mob/living/carbon/human/prey as anything in humans)
				var/turf/step = get_step(prey, pick(GLOB.cardinals))
				if(step && !step.density && get_dist(step, arena_turf(20, 20)) < 16)
					prey.Move(step)
		var/profile_data = world.Profile(PROFILE_REFRESH, format = "json")
		GLOB.horde_path_notes["moves_ok"] += GLOB.ai_metrics.successful_moves - moves_before
		GLOB.horde_path_notes["searches"] += GLOB.ai_metrics.jps_requests - searches_before
		//застрял: за весь сегмент не сдвинулся и не стоит вплотную ни к одной жертве
		for(var/index in 1 to length(mobs))
			var/mob/living/horde_mob = mobs[index]
			if(horde_mob.loc != start_spots[index])
				continue
			var/next_to_prey = FALSE
			for(var/mob/living/carbon/human/prey as anything in humans)
				if(get_dist(horde_mob, prey) <= 1)
					next_to_prey = TRUE
					break
			if(!next_to_prey)
				GLOB.horde_path_notes["stuck"] += 1
		world.Profile(PROFILE_STOP)
		world.Profile(PROFILE_CLEAR)
		if(segment <= 4)
			fdel("data/horde_profile_[tag]_[segment][mode].json")
			text2file(profile_data, "data/horde_profile_[tag]_[segment][mode].json")
		var/list/mode_totals = totals[mode]
		for(var/list/entry as anything in json_decode(profile_data))
			var/short_name = GLOB.horde_bench_procs[entry["name"]]
			if(short_name)
				mode_totals[short_name] += entry["total"] * 1000
				if(short_name == "attack")
					GLOB.horde_path_notes["attacks"] += entry["calls"]
		var/list/mode_notes = notes[mode]
		for(var/reason in GLOB.horde_path_notes)
			mode_notes[reason] += GLOB.horde_path_notes[reason]
	set_savings(TRUE)
	for(var/mode in notes)
		var/list/mode_notes = notes[mode]
		var/list/note_parts = list()
		for(var/reason in mode_notes)
			note_parts += "[reason]=[mode_notes[reason]]"
		log_world("HORDE [tag] path notes [mode]: [jointext(note_parts, " ")]")
	var/list/lines = list()
	for(var/mode in totals)
		var/list/mode_totals = totals[mode]
		var/list/parts = list()
		for(var/short_name in mode_totals)
			parts += "[short_name]=[round(mode_totals[short_name])]"
		lines += "[mode]: [jointext(parts, " ")]"
	var/list/on = totals["on"]
	var/list/off = totals["off"]
	var/ai_on = on["process"] + on["plan"]
	var/ai_off = off["process"] + off["plan"]
	var/decide_on = ai_on - on["attack"]
	var/decide_off = ai_off - off["attack"]
	log_world("HORDE [savings_toggle] [tag]: [HORDE_MOB_COUNT] mobs, [segments / 2]x[segment_time / 10]s per mode | [jointext(lines, " | ")] | AI off/on [round(ai_off)]/[round(ai_on)] = [round(ai_off / max(ai_on, 1), 0.01)]x, without attack execution [round(decide_off)]/[round(decide_on)] = [round(decide_off / max(decide_on, 1), 0.01)]x")
	QDEL_LIST(mobs)
	QDEL_LIST(humans)
	sleep(1 SECONDS)

///Тот же зал, но в сегментах off выключена экономия поиска пути
/datum/unit_test/hostile_ai_path_bench
	parent_type = /datum/unit_test/hostile_ai_horde_bench
	savings_toggle = "path"
	//короткие сегменты гасят всплески чужой нагрузки на машине, бьющие в один режим
	segments = 40
	segment_time = 1 SECONDS

/datum/unit_test/hostile_ai_path_bench/Run()
	return ..()

#undef HORDE_ARENA_SIZE
#undef HORDE_MOB_COUNT
#undef HORDE_WARMUP
#undef HORDE_SEGMENT_TIME

#endif
