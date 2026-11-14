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
	wanted_objects = typecacheof(list(/obj/structure/reagent_dispensers/fueltank))

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
	var/obj/structure/reagent_dispensers/fueltank/tank = allocate(/obj/structure/reagent_dispensers/fueltank, run_loc_floor_top_right)
	var/turf/first_spot = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/unit_test_horde/infected_like/first = allocate(/mob/living/simple_animal/hostile/unit_test_horde/infected_like, first_spot)
	var/mob/living/simple_animal/hostile/unit_test_horde/infected_like/neighbour = allocate(/mob/living/simple_animal/hostile/unit_test_horde/infected_like, get_step(first_spot, NORTH))
	var/mob/living/simple_animal/hostile/unit_test_horde/infected_like/far = allocate(/mob/living/simple_animal/hostile/unit_test_horde/infected_like, locate(first_spot.x + 4, first_spot.y + 4, first_spot.z))
	var/datum/ai_pack_scan/pack_scan = horde_pack_scan(first)
	TEST_ASSERT_NOTNULL(pack_scan, "Object hunters of one type must share a pack scan")

	var/list/first_hits = finder.find_wanted_objects(first, 25, pack_scan)
	TEST_ASSERT(length(first_hits) == 1 && first_hits[1] == tank, "Sanity: the first scan must find the fuel tank, found [length(first_hits)] objects")
	var/scans_before = GLOB.ai_metrics.object_scans
	var/list/neighbour_hits = finder.find_wanted_objects(neighbour, 25, pack_scan)
	TEST_ASSERT_EQUAL(GLOB.ai_metrics.object_scans, scans_before, "A packmate one tile away must not run its own oview")
	TEST_ASSERT(neighbour_hits == first_hits && (tank in neighbour_hits), "A packmate one tile away must reuse the stored object scan")
	TEST_ASSERT(finder.find_wanted_objects(neighbour, 9, pack_scan) != first_hits, "Another scan range must not reuse the stored object scan")
	//дальний обзор делится на четверть дальности, ближний - на три клетки
	TEST_ASSERT(finder.find_wanted_objects(far, 25, pack_scan) == first_hits, "A packmate four tiles away must reuse a long-range object scan")
	var/turf/seven_away = locate(first_spot.x + 7, first_spot.y, first_spot.z)
	TEST_ASSERT_NULL(pack_scan.shared_objects(seven_away, 25), "A packmate seven tiles away must look for itself")
	var/list/short_hits = finder.find_wanted_objects(first, 9, pack_scan)
	TEST_ASSERT(tank in short_hits, "Sanity: the short scan must find the fuel tank")
	TEST_ASSERT(pack_scan.shared_objects(get_turf(neighbour), 9) == short_hits, "Sanity: a short scan is shared one tile away")
	TEST_ASSERT_NULL(pack_scan.shared_objects(get_turf(far), 9), "A short scan must not be shared four tiles away")
	ai_pack_scans_reset()
	ai_pack_object_scans_reset()
	TEST_ASSERT(!length(GLOB.ai_pack_object_scans), "The object window reset must drop every stored scan")

///Смэшер, ведущий цель без LOS, не берёт вещь из обзора сородича по ту сторону стены: видимость вещи ему потом никто не проверит
/datum/unit_test/hostile_ai_horde_ignore_sight_skips_shared_objects/Run()
	ai_pack_scans_reset()
	ai_pack_object_scans_reset()
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/turf/corner = run_loc_floor_bottom_left
	var/list/walls = list()
	for(var/offset in 0 to 4)
		var/turf/wall_turf = locate(corner.x + 2, corner.y + offset, corner.z)
		walls[wall_turf] = wall_turf.type
		wall_turf.ChangeTurf(/turf/closed/wall)
	var/obj/structure/reagent_dispensers/fueltank/tank = allocate(/obj/structure/reagent_dispensers/fueltank, locate(corner.x + 4, corner.y, corner.z))
	var/mob/living/simple_animal/hostile/unit_test_horde/infected_like/seer = allocate(/mob/living/simple_animal/hostile/unit_test_horde/infected_like, locate(corner.x + 3, corner.y + 1, corner.z))
	var/mob/living/simple_animal/hostile/unit_test_horde/infected_like/smasher = allocate(/mob/living/simple_animal/hostile/unit_test_horde/infected_like, locate(corner.x + 1, corner.y + 1, corner.z))
	var/obj/item/paper/old_target = allocate(/obj/item/paper, locate(corner.x, corner.y + 4, corner.z))
	for(var/mob/living/simple_animal/hostile/hunter as anything in list(seer, smasher))
		hunter.wanted_objects = typecacheof(/obj/structure/reagent_dispensers/fueltank)
		hunter.ai_controller.set_blackboard_key(BB_AI_TARGETING_STRATEGY, /datum/targeting_strategy/hostile_legacy/ignore_sight)
	var/datum/ai_controller/smasher_controller = smasher.ai_controller
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(/datum/targeting_strategy/hostile_legacy/ignore_sight)
	smasher.target = old_target

	finder.perform(0.5, seer.ai_controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/seer_target = seer.ai_controller.blackboard[BB_AI_CURRENT_TARGET]
	var/sanity_pack = horde_pack_scan(smasher) == horde_pack_scan(seer)
	var/sanity_ignores = strategy.ignores_sight(smasher)
	finder.perform(0.5, smasher_controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/smasher_target = smasher_controller.blackboard[BB_AI_CURRENT_TARGET]

	smasher.target = null
	for(var/turf/wall_turf as anything in walls)
		wall_turf.ChangeTurf(walls[wall_turf])
	ai_pack_scans_reset()
	ai_pack_object_scans_reset()
	TEST_ASSERT(seer_target == tank, "Sanity: the packmate with a clear view must take the fuel tank")
	TEST_ASSERT(sanity_pack, "Sanity: both smashers must share one pack scan")
	TEST_ASSERT(sanity_ignores, "Sanity: an engaged smasher must ignore sight")
	TEST_ASSERT(smasher_target != tank, "An engaged smasher took a fuel tank behind a wall from its packmate's view")

///Окно ячеек грида не пересобирается шагом внутри тех же ячеек, но пересобирается при выходе из них
/datum/unit_test/hostile_ai_horde_cell_window_skip/Run()
	var/mob/living/simple_animal/hostile/unit_test_horde/walker = allocate(/mob/living/simple_animal/hostile/unit_test_horde, run_loc_floor_bottom_left)
	var/datum/cell_tracker/tracker = walker.ai_controller.our_cells
	TEST_ASSERT_NOTNULL(tracker, "Sanity: a hostile controller must track grid cells")
	var/turf/from_turf
	var/turf/to_turf
	for(var/offset in 0 to 3)
		var/turf/candidate_from = locate(run_loc_floor_bottom_left.x + offset, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
		var/turf/candidate_to = get_step(candidate_from, EAST)
		var/list/from_cells = SSspatial_grid.get_cells_in_bounds(candidate_from, tracker.outer_window_x_radius, tracker.outer_window_y_radius)
		var/list/to_cells = SSspatial_grid.get_cells_in_bounds(candidate_to, tracker.outer_window_x_radius, tracker.outer_window_y_radius)
		if(from_cells ~= to_cells)
			from_turf = candidate_from
			to_turf = candidate_to
			break
	TEST_ASSERT_NOTNULL(from_turf, "Sanity: the floor must have a step inside the same grid cells")
	walker.forceMove(from_turf)
	var/list/cells_before = tracker.member_cells.Copy()
	var/windows_before = GLOB.ai_metrics.cell_windows
	walker.forceMove(to_turf)
	TEST_ASSERT_EQUAL(GLOB.ai_metrics.cell_windows, windows_before, "A step inside the same grid cells must not rebuild the cell window")
	TEST_ASSERT(tracker.member_cells ~= cells_before, "A step inside the same grid cells must keep the tracked cells")

	var/turf/far_turf = locate(to_turf.x + SPATIAL_GRID_CELLSIZE * 3, to_turf.y, to_turf.z)
	walker.forceMove(far_turf)
	TEST_ASSERT_EQUAL(GLOB.ai_metrics.cell_windows, windows_before + 1, "Leaving the grid cells must rebuild the cell window")
	var/list/far_cells = SSspatial_grid.get_cells_in_bounds(far_turf, tracker.outer_window_x_radius, tracker.outer_window_y_radius)
	TEST_ASSERT(tracker.member_cells ~= far_cells, "The rebuilt window must track the cells around the new spot")
	walker.forceMove(to_turf)

///Взведённый профиль тикера планирования раскладывает проход по парам контроллер@паун и снимается в конце прохода
/datum/unit_test/hostile_ai_controller_ticker_profile/Run()
	var/mob/living/simple_animal/hostile/unit_test_horde/planner = allocate(/mob/living/simple_animal/hostile/unit_test_horde, run_loc_floor_bottom_left)
	var/datum/ai_controller/controller = planner.ai_controller
	var/saved_can_fire = detach_subsystem(SSai_controllers)
	var/saved_limit = Master.current_ticklimit
	var/saved_cooldown = SSai_controllers.profile_cooldown_until
	var/alist/counts = alist()
	SSai_controllers.profile_armed = TRUE
	SSai_controllers.profile_cost_by_type = alist()
	SSai_controllers.profile_count_by_type = counts
	SSai_controllers.profile_max_by_type = alist()
	SSai_controllers.profile_worst_by_type = alist()
	SSai_controllers.profile_sleepers_by_type = alist()
	SSai_controllers.state = SS_RUNNING
	Master.current_ticklimit = INFINITY
	SSai_controllers.currentrun = list(controller)
	SSai_controllers.fire(TRUE)
	Master.current_ticklimit = saved_limit
	release_subsystem(SSai_controllers, saved_can_fire)
	var/armed_after = SSai_controllers.profile_armed
	var/counts_after = SSai_controllers.profile_count_by_type
	SSai_controllers.profile_cooldown_until = saved_cooldown
	TEST_ASSERT_EQUAL(counts["[controller.type]@[planner.type]"], 1, "An armed planning pass must note the planned controller under its type and the pawn type")
	TEST_ASSERT_NULL(counts[controller.type], "A shared controller type alone must not hide which mobs it drives")
	TEST_ASSERT(!armed_after, "The finished pass must disarm the profile")
	TEST_ASSERT_NULL(counts_after, "The finished pass must drop its profile lists")

///Пропуск пересчёта окна безопасен: где трекер говорит "то же окно", пересчёт ничего бы не поменял
/datum/unit_test/hostile_ai_horde_cell_window_invariant/Run()
	var/datum/cell_tracker/tracker = new(9, 9, 2)
	var/turf/start = run_loc_floor_bottom_left
	tracker.recalculate_cells(start)
	var/skipped = 0
	var/rebuilt = 0
	for(var/index in 1 to SPATIAL_GRID_CELLSIZE * 3)
		var/turf/center = locate(start.x + index, start.y + round(index / 2), start.z)
		if(tracker.window_unchanged(center))
			skipped++
			var/list/changes = tracker.recalculate_cells(center)
			TEST_ASSERT(!length(changes[1]) && !length(changes[2]), "An unchanged window must not gain or lose cells, step [index]")
			continue
		rebuilt++
		tracker.recalculate_cells(center)
	TEST_ASSERT(skipped > rebuilt, "Most steps must stay inside the same window ([skipped] skipped, [rebuilt] rebuilt)")
	TEST_ASSERT(rebuilt > 0, "Crossing grid cells must rebuild the window")
	tracker.forget_cells()
	TEST_ASSERT(!tracker.window_unchanged(start), "A forgotten window must be rebuilt")
	qdel(tracker, TRUE)

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

#define BRAWL_ARENA_SIZE 60
#define BRAWL_HORDE_COUNT 200
#define BRAWL_FOE_COUNT 80
#define BRAWL_WARMUP (3 SECONDS)
#define BRAWL_SEGMENTS 8
#define BRAWL_SEGMENT_TIME (3 SECONDS)
#define BRAWL_TOP_PROCS 30

GLOBAL_VAR_INIT(ai_crowd_savings, TRUE)
///Что бенч драки суммирует из профиля по режимам
GLOBAL_LIST_INIT(brawl_bench_procs, list(
	"/datum/ai_controller/hostile_adapter/SelectBehaviors" = "plan",
	"/datum/ai_controller/process" = "behaviors",
	"/datum/controller/subsystem/movement/fire" = "movement",
	"/datum/ai_behavior/find_potential_targets/perform" = "finder",
	"/datum/ai_behavior/find_potential_targets/proc/filter_candidates" = "filter",
	"/datum/ai_behavior/find_potential_targets/proc/find_wanted_objects" = "objects",
	"/datum/ai_controller/proc/update_grid" = "grid",
))

///Противник орды из другой фракции, отвечает ей тем же
/mob/living/simple_animal/hostile/unit_test_horde/brawl_foe
	faction = list("unit_test_brawl_foe")

///Орда заражённых (200) против отряда (80) на открытом месте и в коридорах: цена тикеров ИИ и топ проков
/datum/unit_test/hostile_ai_horde_brawl_bench
	priority = TEST_LONGER
	var/datum/turf_reservation/arena
	var/mob/dead/observer/watcher
	var/list/clutter = list()

/datum/unit_test/hostile_ai_horde_brawl_bench/proc/arena_turf(x, y)
	return locate(arena.bottom_left_coords[1] + x - 1, arena.bottom_left_coords[2] + y - 1, arena.bottom_left_coords[3])

///Коридоры шириной 3: поперечные через 12 клеток, продольные через 20
/datum/unit_test/hostile_ai_horde_brawl_bench/proc/is_corridor(x, y)
	return ((y - 2) % 12) < 3 || ((x - 2) % 20) < 3

/datum/unit_test/hostile_ai_horde_brawl_bench/proc/build_layout(layout)
	for(var/x in 1 to BRAWL_ARENA_SIZE)
		for(var/y in 1 to BRAWL_ARENA_SIZE)
			var/turf/tile = arena_turf(x, y)
			var/wall = x == 1 || y == 1 || x == BRAWL_ARENA_SIZE || y == BRAWL_ARENA_SIZE
			if(!wall && layout == "corridors")
				wall = !is_corridor(x, y)
			tile.ChangeTurf(wall ? /turf/closed/indestructible/wall : /turf/open/indestructible/boss/air)
			//станционная клетка не пуста: обзор и шаги платят за её содержимое
			if(!wall)
				clutter += new /obj/item/paper(tile)

/datum/unit_test/hostile_ai_horde_brawl_bench/proc/open_tiles(min_x, max_x)
	. = list()
	for(var/x in min_x to max_x)
		for(var/y in 2 to BRAWL_ARENA_SIZE - 1)
			var/turf/tile = arena_turf(x, y)
			if(!tile.density)
				. += tile

/datum/unit_test/hostile_ai_horde_brawl_bench/proc/spawn_side(mob_type, count, list/tiles)
	. = list()
	for(var/index in 1 to count)
		var/turf/spot = tiles[((index * 37) % length(tiles)) + 1]
		var/mob/living/simple_animal/hostile/brawler = new mob_type(spot)
		brawler.ai_controller.can_idle = FALSE
		brawler.ai_controller.set_ai_status(AI_STATUS_ON)
		. += brawler

/proc/brawl_probe_oview(turf/origin, list/wanted)
	return typecache_filter_list(oview(25, origin), wanted)

/proc/brawl_probe_range(turf/origin, list/wanted)
	return typecache_filter_list(range(25, origin), wanted)

/proc/brawl_probe_range_obj(turf/origin, list/wanted)
	. = list()
	for(var/obj/thing in range(25, origin))
		if(wanted[thing.type])
			. += thing

///Цена обзора объектов на дальность заражённого: oview против range
/datum/unit_test/hostile_ai_horde_brawl_bench/proc/probe_object_scans()
	var/list/wanted = typecacheof(list(/obj/structure/reagent_dispensers/fueltank))
	world.Profile(PROFILE_CLEAR)
	world.Profile(PROFILE_START)
	for(var/i in 1 to 30)
		var/turf/origin = arena_turf(10 + i, 30)
		brawl_probe_oview(origin, wanted)
		brawl_probe_range(origin, wanted)
		brawl_probe_range_obj(origin, wanted)
		CHECK_TICK
	var/profile_data = world.Profile(PROFILE_REFRESH, format = "json")
	world.Profile(PROFILE_STOP)
	world.Profile(PROFILE_CLEAR)
	for(var/list/entry as anything in json_decode(profile_data))
		if(findtext(entry["name"], "brawl_probe"))
			log_world("BRAWL probe: [entry["name"]] [round(entry["total"] * 1000 / max(entry["calls"], 1), 0.01)]ms per call, [entry["calls"]] calls")

///Прогоны тикеров ИИ от 40% тика из кольца детектора спайков: имя -> list(число, максимум)
/datum/unit_test/hostile_ai_horde_brawl_bench/proc/note_heavy_runs(list/heavy, since)
	if(!SStick_spikes?.heavy_time)
		return
	for(var/index in 1 to length(SStick_spikes.heavy_time))
		var/run_time = SStick_spikes.heavy_time[index]
		var/name = SStick_spikes.heavy_name[index]
		if(isnull(run_time) || run_time < since || !findtext(name, "AI"))
			continue
		var/list/runs = heavy[name]
		if(!runs)
			runs = list(0, 0)
			heavy[name] = runs
		runs[1]++
		runs[2] = max(runs[2], SStick_spikes.heavy_usage[index])

/datum/unit_test/hostile_ai_horde_brawl_bench/Run()
	arena = SSmapping.RequestBlockReservation(BRAWL_ARENA_SIZE, BRAWL_ARENA_SIZE)
	TEST_ASSERT_NOTNULL(arena, "Failed to reserve the brawl arena")
	var/arena_z = arena_turf(1, 1).z
	if(!islist(SSmobs.clients_by_zlevel) || arena_z > length(SSmobs.clients_by_zlevel))
		SSmobs.MaxZChanged()
	//резерв лежит в космической зоне без гравитации: орда парила бы и платила за невесомость
	var/area/space_area = get_area(arena_turf(1, 1))
	var/area/arena_area = new /area/start
	var/list/arena_turfs = block(arena_turf(1, 1), arena_turf(BRAWL_ARENA_SIZE, BRAWL_ARENA_SIZE))
	arena_area.contents.Add(arena_turfs)
	watcher = new(arena_turf(30, 30))
	SSmobs.clients_by_zlevel[arena_z] |= watcher

	for(var/layout in list("open", "corridors", "open paced"))
		QDEL_LIST(clutter)
		build_layout(layout == "corridors" ? layout : "open")
		var/obj/structure/reagent_dispensers/fueltank/bait = new(arena_turf(32, 3))
		if(layout == "open")
			probe_object_scans()
		Master.pacing_forced = layout == "open paced"
		run_brawl(layout)
		Master.pacing_forced = FALSE
		qdel(bait)
	QDEL_LIST(clutter)

	SSmobs.clients_by_zlevel[arena_z] -= watcher
	QDEL_NULL(watcher)
	space_area.contents.Add(arena_turfs)
	qdel(arena_area)
	QDEL_NULL(arena)

/datum/unit_test/hostile_ai_horde_brawl_bench/proc/run_brawl(layout)
	var/list/mobs = spawn_side(/mob/living/simple_animal/hostile/unit_test_horde/infected_like, BRAWL_HORDE_COUNT, open_tiles(2, 24))
	mobs += spawn_side(/mob/living/simple_animal/hostile/unit_test_horde/brawl_foe, BRAWL_FOE_COUNT, open_tiles(37, BRAWL_ARENA_SIZE - 1))
	sleep(BRAWL_WARMUP)
	//с экономией и без в одном мире, порядок ABBA гасит дрейф чужой нагрузки на машине
	var/list/modes = list("on" = list(), "off" = list())
	var/list/self_ms = list()
	var/list/total_ms = list()
	var/list/calls = list()
	var/list/heavy = list()
	for(var/segment in 1 to BRAWL_SEGMENTS)
		var/mode = (segment % 4 < 2) ? "on" : "off"
		GLOB.ai_crowd_savings = mode == "on"
		var/list/mode_totals = modes[mode]
		ai_pack_scans_reset()
		ai_pack_object_scans_reset()
		var/list/metrics_before = GLOB.ai_metrics.snapshot()
		world.Profile(PROFILE_CLEAR)
		world.Profile(PROFILE_START)
		var/real_start = world.timeofday
		var/world_start = world.time
		sleep(BRAWL_SEGMENT_TIME)
		mode_totals["drift"] += ((world.timeofday - real_start) - (world.time - world_start)) * 100
		var/profile_data = world.Profile(PROFILE_REFRESH, format = "json")
		world.Profile(PROFILE_STOP)
		world.Profile(PROFILE_CLEAR)
		var/list/metrics = GLOB.ai_metrics.delta_since(metrics_before)
		mode_totals["oviews"] += metrics["object_scans"]
		mode_totals["windows"] += metrics["cell_windows"]
		mode_totals["candidates"] += metrics["candidates_examined"]
		if(mode == "on")
			note_heavy_runs(heavy, world_start)
		for(var/list/entry as anything in json_decode(profile_data))
			var/name = entry["name"]
			var/short_name = GLOB.brawl_bench_procs[name]
			if(short_name)
				mode_totals[short_name] += entry["total"] * 1000
			if(mode != "on")
				continue
			self_ms[name] += entry["self"] * 1000
			total_ms[name] += entry["total"] * 1000
			calls[name] += entry["calls"]
	GLOB.ai_crowd_savings = TRUE
	var/seconds = BRAWL_SEGMENTS * BRAWL_SEGMENT_TIME / 20
	var/list/mode_lines = list()
	for(var/mode in modes)
		var/list/mode_totals = modes[mode]
		var/list/parts = list()
		for(var/short_name in mode_totals)
			parts += "[short_name]=[round(mode_totals[short_name] / seconds, 0.1)]"
		mode_lines += "[mode]: [jointext(parts, " ")]"
	var/list/on = modes["on"]
	var/list/off = modes["off"]
	var/ai_on = on["plan"] + on["behaviors"] + on["movement"]
	var/ai_off = off["plan"] + off["behaviors"] + off["movement"]
	log_world("BRAWL [layout]: [BRAWL_HORDE_COUNT] infected vs [BRAWL_FOE_COUNT] foes, [seconds]s per mode, per second | [jointext(mode_lines, " | ")] | AI off/on [round(ai_off / seconds)]/[round(ai_on / seconds)] = [round(ai_off / max(ai_on, 1), 0.01)]x")
	for(var/name in heavy)
		var/list/runs = heavy[name]
		log_world("BRAWL [layout] heavy runs (on): [name] [runs[1]] runs >= 40% tick, max [round(runs[2], 0.1)]% tick")
	sortTim(self_ms, GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
	var/shown = 0
	for(var/name in self_ms)
		if(++shown > BRAWL_TOP_PROCS)
			break
		log_world("BRAWL [layout] self (on): [name] self [round(self_ms[name] / seconds, 0.1)]ms/s total [round(total_ms[name] / seconds, 0.1)]ms/s calls [round(calls[name] / seconds)]/s")
	sortTim(total_ms, GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
	shown = 0
	for(var/name in total_ms)
		if(++shown > BRAWL_TOP_PROCS)
			break
		log_world("BRAWL [layout] total (on): [name] total [round(total_ms[name] / seconds, 0.1)]ms/s self [round(self_ms[name] / seconds, 0.1)]ms/s calls [round(calls[name] / seconds)]/s")
	QDEL_LIST(mobs)
	sleep(1 SECONDS)

#undef BRAWL_ARENA_SIZE
#undef BRAWL_HORDE_COUNT
#undef BRAWL_FOE_COUNT
#undef BRAWL_WARMUP
#undef BRAWL_SEGMENTS
#undef BRAWL_SEGMENT_TIME
#undef BRAWL_TOP_PROCS

#undef HORDE_ARENA_SIZE
#undef HORDE_MOB_COUNT
#undef HORDE_WARMUP
#undef HORDE_SEGMENT_TIME

#endif
