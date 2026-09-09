// ===== Восприятие, память и скоринг целей hostile AI =====
//
// Проверяют: легаси-паритет стратегии, поиск целей через
// грид (без hearers), LOS-гейт, детерминированный скоринг с гистерезисом,
// хелперы памяти и pack-канал передачи целей.

///Тестовый контроллер-охотник с настроенным таргетированием
/datum/ai_controller/unit_test_hunter
	blackboard = list(
		BB_AI_TARGETING_STRATEGY = /datum/targeting_strategy/hostile_legacy,
		BB_AI_AGGRO_RANGE = 14,
	)

/datum/unit_test/ai_blackboard_redundant_clear_noop
	var/clear_signals = 0

/datum/unit_test/ai_blackboard_redundant_clear_noop/proc/on_target_cleared()
	SIGNAL_HANDLER
	clear_signals++

///Clearing an absent key must not make adapters repeat target-loss side effects.
/datum/unit_test/ai_blackboard_redundant_clear_noop/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	RegisterSignal(pawn, COMSIG_AI_BLACKBOARD_KEY_CLEARED(BB_AI_CURRENT_TARGET), PROC_REF(on_target_cleared))

	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(clear_signals, 0, "An already absent target key must not broadcast CLEARED")
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(clear_signals, 1, "Clearing a real target must still broadcast exactly once")

	UnregisterSignal(pawn, COMSIG_AI_BLACKBOARD_KEY_CLEARED(BB_AI_CURRENT_TARGET))
	qdel(controller)

///Non-exact faction checks must retain overlap semantics without an intersection allocation.
/datum/unit_test/faction_check_fast_path_semantics/Run()
	TEST_ASSERT(faction_check(list("alpha", "shared"), list("shared", "beta")), "An overlapping faction must match")
	TEST_ASSERT(!faction_check(list("alpha", "one"), list("beta", "two")), "Disjoint factions must not match")
	TEST_ASSERT(!faction_check(list(), list("alpha")), "An empty faction must not match")
	TEST_ASSERT(faction_check(list("alpha"), list("alpha", "beta"), TRUE), "Exact legacy semantics treat the left faction as a subset")

///Стратегия hostile_legacy обязана давать те же вердикты, что и CanAttack()
/datum/unit_test/ai_targeting_legacy_parity/Run()
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(/datum/targeting_strategy/hostile_legacy)
	TEST_ASSERT_NOTNULL(strategy, "hostile_legacy strategy singleton must exist")

	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/simple_animal/hostile/packmate = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human)
	corpse.death()

	var/list/verdict_matrix = list(packmate, prey, corpse)
	for(var/atom/candidate as anything in verdict_matrix)
		TEST_ASSERT_EQUAL(strategy.can_attack(hunter, candidate), hunter.CanAttack(candidate), "Strategy verdict must match CanAttack for [candidate]")

	//обиды и attack_same тоже должны совпадать через делегацию
	hunter.RetaliateAgainst(packmate)
	TEST_ASSERT_EQUAL(strategy.can_attack(hunter, packmate), hunter.CanAttack(packmate), "Strategy must match CanAttack for a grudge target")
	TEST_ASSERT(strategy.can_attack(hunter, packmate), "Sanity: a grudge same-faction target must be attackable")
	hunter.LoseTarget()

///Поиск целей через грид покрывает дистанцию 12 без hearers(). +12 выходит за
///резервацию 5x5, поэтому цель здесь УЖЕ приобретена: ignore_sight ведёт её
///сквозь границу без LOS (холодный LOS-гейт покрыт ai_targeting_los_gate).
/datum/unit_test/ai_targeting_grid_search/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	pawn.vision_range = 14 //живой радиус зрения охватывает дистанцию 12
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 12, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)

	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_TARGETING_STRATEGY, /datum/targeting_strategy/hostile_legacy/ignore_sight)
	pawn.target = prey //engaged: ignore_sight ведёт уже приобретённую цель без LOS
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)

	var/hearers_before = GLOB.ai_metrics.hearers_calls
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "Grid-based search must find the human at distance 12")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_KNOWN_POS], prey_turf, "Finding a target must remember its position")
	TEST_ASSERT(controller.blackboard[BB_AI_LAST_SEEN_TIME] > 0, "Finding a target must remember the time")
	TEST_ASSERT_EQUAL(GLOB.ai_metrics.hearers_calls, hearers_before, "Grid-based search must never call hearers()")

	qdel(controller)

///LOS-гейт: стена блокирует ХОЛОДНОЕ приобретение и у сайтед-стратегии, и у
///ignore_sight. Смэшер ведёт сквозь стены только УЖЕ приобретённую цель
///(engaged-ветку покрывает ai_smasher_unprovoked_los_gate). Легаси acquisition
///шёл через hearers(), а он блокируется стенами.
/datum/unit_test/ai_targeting_los_gate/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 8, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	allocate(/mob/living/carbon/human, prey_turf)

	//стена посередине прямой линии восточного направления
	var/turf/wall_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)

	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)

	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/target_sighted = controller.blackboard[BB_AI_CURRENT_TARGET]

	//смэш-стратегия без уже приобретённой цели тоже уважает стену на приобретении
	controller.set_blackboard_key(BB_AI_TARGETING_STRATEGY, /datum/targeting_strategy/hostile_legacy/ignore_sight)
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/target_smash_cold = controller.blackboard[BB_AI_CURRENT_TARGET]

	//вернуть турф до ассертов
	wall_turf.ChangeTurf(saved_turf_type)
	qdel(controller)

	TEST_ASSERT_NULL(target_sighted, "A wall must block target acquisition for the sighted strategy")
	TEST_ASSERT_NULL(target_smash_cold, "A wall must also block cold acquisition for the ignore_sight strategy")

///Target scoring must prune an open crowd to one LOS check, while a hidden
///high-priority candidate falls through to the next visible target.
/datum/unit_test/ai_targeting_los_after_scoring/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/mob/living/carbon/human/visible_prey = allocate(/mob/living/carbon/human, get_step(start_turf, NORTH))
	var/turf/hidden_turf = locate(start_turf.x + 8, start_turf.y, start_turf.z)
	var/mob/living/carbon/human/hidden_attacker = allocate(/mob/living/carbon/human, hidden_turf)
	var/turf/wall_turf = locate(start_turf.x + 4, start_turf.y, start_turf.z)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)

	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	controller.note_attacker(hidden_attacker)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/los_before = GLOB.ai_metrics.los_checks
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/los_delta = GLOB.ai_metrics.los_checks - los_before

	wall_turf.ChangeTurf(saved_turf_type)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], visible_prey, "A hidden scoring leader must fall through to the next visible candidate")
	TEST_ASSERT_EQUAL(los_delta, 2, "The finder must check only the hidden leader and the visible winner, not the full pool")
	qdel(controller)

/datum/unit_test/ai_targeting_open_pool_single_los/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	// Keep the whole pool inside the reserved test floor. Extending east into
	// the station made map walls add a legitimate hidden-leader LOS fallback.
	var/turf/prey_turf = get_step(start_turf, NORTH)
	for(var/i in 1 to 8)
		allocate(/mob/living/carbon/human, prey_turf)

	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/los_before = GLOB.ai_metrics.los_checks
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/los_delta = GLOB.ai_metrics.los_checks - los_before

	TEST_ASSERT_NOTNULL(controller.blackboard[BB_AI_CURRENT_TARGET], "The open candidate pool must produce a target")
	TEST_ASSERT_EQUAL(los_delta, 1, "An open candidate pool must raycast only its scoring winner")
	qdel(controller)

///Скоринг: обидчик побеждает ближнего незнакомца, текущая цель липкая
/datum/unit_test/ai_targeting_scorer/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/near_stranger = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/turf/far_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, far_turf)

	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/datum/target_scorer/scorer = GET_TARGET_SCORER(/datum/target_scorer)

	//возмездие: дальний обидчик важнее ближнего незнакомца
	controller.note_attacker(attacker)
	var/atom/grudge_pick = scorer.select(controller, list(near_stranger, attacker), null)
	TEST_ASSERT_EQUAL(grudge_pick, attacker, "The last attacker must outscore a nearer stranger")

	//гистерезис: текущая цель удерживается против чуть более близкой альтернативы
	controller.clear_blackboard_key(BB_AI_LAST_ATTACKER)
	controller.remove_thing_from_blackboard_key(BB_AI_GRUDGE_LIST, attacker)
	var/atom/sticky_pick = scorer.select(controller, list(near_stranger, attacker), attacker)
	TEST_ASSERT_EQUAL(sticky_pick, attacker, "A valid current target must be kept against a slightly closer alternative")

	//фрустрация ломает гистерезис: недостижимая цель уступает
	controller.blackboard[BB_AI_FRUSTRATION] = 5
	var/atom/frustrated_pick = scorer.select(controller, list(near_stranger, attacker), attacker)
	TEST_ASSERT_EQUAL(frustrated_pick, near_stranger, "High frustration must let a reachable candidate win over the stuck current target")

	qdel(controller)

///Память: note_attacker будит спящего, обиды протухают, pack-канал делится целью
/datum/unit_test/ai_targeting_memory/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/enemy = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	register_fake_player(enemy, get_turf(enemy))

	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/datum/ai_controller/unit_test_hunter/ally_controller = new(ally)

	//спящий контроллер просыпается от боли
	if(controller.ai_status != AI_STATUS_IDLE)
		controller.set_ai_status(AI_STATUS_IDLE)
	controller.note_attacker(enemy)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_ATTACKER], enemy, "note_attacker must remember the attacker")
	TEST_ASSERT(controller.holds_grudge_against(enemy), "note_attacker must create a grudge")
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Pain must wake a sleeping controller")

	//протухание обиды
	var/list/grudges = controller.blackboard[BB_AI_GRUDGE_LIST]
	grudges[enemy] = world.time - AI_GRUDGE_TIMEOUT - 1
	TEST_ASSERT(!controller.holds_grudge_against(enemy), "An expired grudge must not hold")

	//pack-канал: союзнику уходит ТОЧКА контакта и приметы, не сам атом
	if(ally_controller.ai_status != AI_STATUS_IDLE)
		ally_controller.set_ai_status(AI_STATUS_IDLE)
	var/shared = controller.report_contact_to_allies(enemy, 7)
	TEST_ASSERT(shared >= 1, "report_contact_to_allies must reach the same-faction ally")
	TEST_ASSERT_NULL(ally_controller.blackboard[BB_AI_CURRENT_TARGET], "An ally report must not hand over the live atom as a target")
	TEST_ASSERT_EQUAL(ally_controller.blackboard[BB_AI_CONTACT_TARGET], enemy, "The ally must remember who it is looking for")
	TEST_ASSERT_EQUAL(ally_controller.blackboard[BB_AI_LAST_KNOWN_POS], get_turf(enemy), "The ally must receive the reported point")
	TEST_ASSERT_EQUAL(ally_controller.blackboard[BB_AI_STATE], AI_STATE_SEARCH, "The ally must go investigate the point, not teleport-aggro")
	TEST_ASSERT_EQUAL(ally_controller.ai_status, AI_STATUS_ON, "A contact report must wake the sleeping ally")

	unregister_fake_player(enemy)
	qdel(controller)
	qdel(ally_controller)

///Keeping a current target between refreshes costs exactly one honesty raycast
///(the live LOS confirmation), never a full rescan.
/datum/unit_test/ai_targeting_cached_target_skips_los/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = world.time + 1 MINUTES
	controller.blackboard[BB_AI_FRUSTRATION] = 0

	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/los_before = GLOB.ai_metrics.los_checks
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "The eligible cached target must be retained")
	TEST_ASSERT_EQUAL(GLOB.ai_metrics.los_checks, los_before + 1, "A cached target costs one live-LOS confirmation per pass, not a rescan")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_KNOWN_POS], get_turf(prey), "The confirmed position must stay fresh on the cheap path")
	qdel(controller)

///Losing LOS demotes the live target to a contact after the short peek grace:
///no GPS pursuit of the real atom behind the wall. The evidence turf stays
///where the target was last actually seen, and only the mob's own sight
///re-acquires it.
///Вся геометрия строго внутри 5x5 комнаты теста: восточнее x+4 лежат ЧУЖИЕ
///резервации (шаттловый транзит с непрозрачными бортами появляется там в
///зависимости от порядка тестов).
/datum/unit_test/ai_targeting_corner_pursuit_memory/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/turf/visible_turf = locate(start_turf.x + 1, start_turf.y, start_turf.z)
	var/turf/wall_turf = locate(start_turf.x + 2, start_turf.y, start_turf.z)
	var/turf/hidden_turf = locate(start_turf.x + 4, start_turf.y, start_turf.z)
	var/saved_turf_type = wall_turf.type
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, visible_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)

	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "Sanity: the visible prey must be acquired")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_KNOWN_POS], visible_turf, "Sanity: acquisition must store the visible turf")

	wall_turf.ChangeTurf(/turf/closed/wall)
	prey.forceMove(hidden_turf)
	//первый скрытый цикл - грейс (пик из-за угла не обнуляет ENGAGE), демоушен
	//наступает после его истечения
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "The first hidden pass must grace the target, not demote it")
	controller.blackboard[BB_AI_LOS_LOST_AT] = world.time - AI_LOS_DEMOTE_GRACE - 1
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)

	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "Lost LOS must demote the live target once the grace expires")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CONTACT_TARGET], prey, "The demoted target must be remembered as the hunted contact")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_KNOWN_POS], visible_turf, "The evidence turf must not update through the wall")
	TEST_ASSERT(controller.blackboard[BB_AI_TARGET_REFRESH_AT] <= world.time + AI_TARGET_LOST_REFRESH_COOLDOWN, "A fresh contact must use the short reacquisition cadence")

	//собственное восприятие: стена пала - розыск закрывается мгновенным захватом
	wall_turf.ChangeTurf(saved_turf_type)
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = world.time
	var/finder_verdict = finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT(finder_verdict & AI_BEHAVIOR_SUCCEEDED, "The reacquisition pass must report success")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "Own LOS must re-acquire the hunted contact")
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CONTACT_TARGET], "Re-acquisition must close the manhunt")

	qdel(controller)

///Регресс репорта "майнер терял меня за углом и не возобновлял погоню": у
///мобов с двухуровневым зрением (шамблер: vision 3 / aggro 7) разжалование
///цели роняет живой vision_range через LoseTarget->LoseAggro, и SEARCH искал
///жертву слепым холодным радиусом. Пока контакт свеж, охотник настороже:
///переприобретение обязано идти на боевом aggro_vision_range (LOS-гейт
///сохраняется), а после сдачи поиска восприятие снова остывает.
/datum/unit_test/ai_fresh_contact_alert_vision/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	pawn.vision_range = 3
	pawn.aggro_vision_range = 7
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_AGGRO_RANGE, 7)
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(/datum/targeting_strategy/hostile_legacy)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)

	//холодное восприятие: живой vision_range (паритет фикса overaggro вотчера)
	TEST_ASSERT_EQUAL(strategy.get_aggro_range(pawn, 7), 3, "Cold acquisition must stay at the live vision range")
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "A distance-4 stranger must stay invisible to cold vision 3")

	//цель была захвачена и скрылась за углом: разжалована в свежий контакт
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.demote_target_to_contact(BB_AI_CURRENT_TARGET)
	controller.blackboard[BB_AI_LAST_SEEN_TIME] = world.time
	TEST_ASSERT_EQUAL(strategy.get_aggro_range(pawn, 7), 7, "A fresh contact must raise acquisition to the alert vision range")

	//жертва вышла из-за угла в 4 тайлах: настороженный охотник переприобретает
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = null
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], prey, "The searching hunter must reacquire a visible target inside its alert radius")
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CONTACT_TARGET], "Reacquisition by own senses must close the contact")

	//поиск сдался - память чиста, восприятие снова холодное
	controller.demote_target_to_contact(BB_AI_CURRENT_TARGET)
	controller.clear_engagement_memory()
	TEST_ASSERT_EQUAL(strategy.get_aggro_range(pawn, 7), 3, "After the search gives up the perception must cool back down")

	qdel(controller)

///Настороженность от полученного урона: моб с коротким пассивным зрением после
///удара ищет на боевом aggro_vision_range, даже если цели и контакта нет, а
///точка обидчика становится уликой розыска. Розыскной КОНТАКТ при этом не
///создаётся - бонус скоринга контакта не должен дублировать обиду (плейтест
///22.06: shambling miner с vision 3 стоял столбом под выстрелами с 4+ тайлов).
/datum/unit_test/ai_combat_alert_survives_target_loss/Run()
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	victim.vision_range = 3
	victim.aggro_vision_range = 7
	var/turf/shooter_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, shooter_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(victim)
	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(/datum/targeting_strategy/hostile_legacy)

	TEST_ASSERT_EQUAL(strategy.get_aggro_range(victim, 7), 3, "Санити: холодное зрение обязано быть пассивным")
	controller.note_attacker(shooter)
	TEST_ASSERT(controller.is_combat_alert(), "Полученный удар обязан взводить настороженность")
	TEST_ASSERT_EQUAL(strategy.get_aggro_range(victim, 7), 7, "Настороженный моб обязан искать на боевом aggro_vision_range")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_KNOWN_POS], shooter_turf, "Точка обидчика обязана стать уликой розыска")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CONTACT_TARGET), "Удар не имеет права создавать розыскной контакт")

	//окно протухло - восприятие остывает
	controller.blackboard[BB_AI_COMBAT_ALERT_UNTIL] = world.time - 1
	TEST_ASSERT_EQUAL(strategy.get_aggro_range(victim, 7), 3, "Протухшая настороженность обязана остужать зрение")

	qdel(controller)

///Фрустрация проходит через живой finder и действительно меняет цель.
/datum/unit_test/ai_targeting_live_retarget/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/turf/far_turf = locate(run_loc_floor_bottom_left.x + 6, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/stuck_target = allocate(/mob/living/carbon/human, far_turf)
	var/mob/living/carbon/human/reachable_target = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, stuck_target)
	controller.set_blackboard_key(BB_AI_TARGET_HIDING_LOCATION, far_turf)
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = world.time + 1 MINUTES
	controller.blackboard[BB_AI_FRUSTRATION] = 5

	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/verdict = finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)

	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "Frustration must force an immediate live target comparison")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], reachable_target, "The reachable candidate must replace the stuck current target")
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_TARGET_HIDING_LOCATION), "Retargeting to an exposed target must clear the previous target's hiding container")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_FRUSTRATION], 0, "Changing target must clear accumulated path frustration")
	TEST_ASSERT(controller.blackboard[BB_AI_TARGET_REFRESH_AT] > world.time, "A completed comparison must arm the refresh cadence")
	TEST_ASSERT(controller.blackboard[BB_AI_TARGET_REFRESH_AT] <= world.time + AI_TARGET_REFRESH_COOLDOWN + AI_TARGET_REFRESH_JITTER, "The staggered refresh must stay within its bounded cadence")

	qdel(controller)

///Реестр враждебных машин: регистрация на Initialize, снятие на Destroy
/datum/unit_test/ai_targeting_hostile_machines/Run()
	var/obj/machinery/porta_turret/turret = new(run_loc_floor_bottom_left)
	var/z_level = run_loc_floor_bottom_left.z
	TEST_ASSERT(turret in GLOB.hostile_machines, "A turret must register in GLOB.hostile_machines on Initialize")
	TEST_ASSERT(turret in GLOB.hostile_machines_by_zlevel[z_level], "A turret must register in its hostile-machine z bucket")
	turret.moveToNullspace()
	TEST_ASSERT(!(turret in GLOB.hostile_machines_by_zlevel[z_level]), "A nullspace machine must leave its old z bucket immediately")
	turret.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(turret in GLOB.hostile_machines_by_zlevel[z_level], "A machine returning from nullspace must restore its z registration")
	qdel(turret)
	TEST_ASSERT(!(turret in GLOB.hostile_machines), "A destroyed turret must leave GLOB.hostile_machines")
	TEST_ASSERT(!(turret in GLOB.hostile_machines_by_zlevel[z_level]), "A destroyed turret must leave its hostile-machine z bucket")

///Мех с пилотом - легитимная цель, и целью обязан становиться САМ мех: его моб
///может бить (attack_animal), а пилот в потрохах для милишки недосягаем (Adjacent
///через не-турф loc всегда FALSE - моб застывал бы столбом). Репорт плейтеста:
///"мобы не агрятся на игроков в мехе".
/datum/unit_test/ai_targets_occupied_mecha/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/turf/mech_turf = locate(start_turf.x + 3, start_turf.y, start_turf.z)
	var/obj/vehicle/sealed/mecha/combat/gygax/mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, mech_turf)
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, mech_turf)
	//низкоуровневая посадка: moved_inside() требует клиента, которого у тестовых мобов нет
	pilot.forceMove(mech)
	mech.add_occupant(pilot)
	TEST_ASSERT_EQUAL(pilot.loc, mech, "Санити: пилот обязан сидеть внутри меха")
	TEST_ASSERT(pawn.CanAttack(mech), "Санити: мех с пилотом обязан быть атакуемым")

	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	var/verdict = finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT(verdict & AI_BEHAVIOR_SUCCEEDED, "The finder must acquire a target from an occupied mech scene")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], mech, "The acquired target must be the mech itself, not the pilot inside it")

	//пилот, севший в мех ПОСЛЕ приобретения, обязан разжаловаться на ревалидации
	//(иначе моб вечно держит недосягаемую цель и стоит столбом у брони)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, pilot)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_NOTEQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], pilot, "A target that boarded a sealed vehicle must not survive revalidation")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], mech, "The rescan must swap the boarded pilot for the mech")

	qdel(controller)

///Пустой мех целью не является: CanAttack без атакуемых окупантов - FALSE
/datum/unit_test/ai_ignores_empty_mecha/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start_turf)
	var/turf/mech_turf = locate(start_turf.x + 3, start_turf.y, start_turf.z)
	var/obj/vehicle/sealed/mecha/combat/gygax/mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, mech_turf)
	TEST_ASSERT(!pawn.CanAttack(mech), "An empty mech must not be attackable")

	var/datum/ai_controller/unit_test_hunter/controller = new(pawn)
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "An empty mech must not be acquired as a target")
	qdel(controller)

///Майнбот не поворачивается против владельца. Прод, раунд 9875: шахтёр ткнул
///своего бота сумкой с рудой (урон ноль, NEWHP не изменился) - бот ответил
///через 258 мс и до конца раунда стрелял в него из кинетика. Причина: обида
///писалась независимо от урона, а foes[цель] в CanAttack бьёт проверку фракции.
/datum/unit_test/minebot_does_not_turn_on_its_faction/Run()
	var/mob/living/simple_animal/hostile/mining_drone/bot = allocate(/mob/living/simple_animal/hostile/mining_drone, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	QDEL_NULL(bot.ai_controller) //чистая бухгалтерия обид без контроллера

	TEST_ASSERT(bot.faction_check_mob(owner), "Санити: майнбот и человек обязаны быть в общей фракции neutral")
	TEST_ASSERT(!bot.CanAttack(owner), "Санити: до всякой обиды владелец не цель")

	TEST_ASSERT(!bot.consider_retaliation(owner, 0), "Тычок с нулевым уроном не имеет права создать обиду")
	TEST_ASSERT(!bot.CanAttack(owner), "После тычка с нулевым уроном владелец обязан остаться не-целью")

	//даже настоящий урон не разворачивает бота против своей фракции
	TEST_ASSERT(!bot.consider_retaliation(owner, bot.maxHealth), "Бот не имеет права заводить обиду на свою фракцию ни при каком уроне")
	TEST_ASSERT(!bot.CanAttack(owner), "Владелец обязан остаться не-целью и после настоящего урона")

///Обычная фауна сокомандника терпит, но не бесконечно: порог по накопленному
///урону за окно, а не по числу ударов - три щекотки не равны трём ударам кувалдой.
/datum/unit_test/hostile_tolerates_light_friendly_fire/Run()
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, EAST))
	QDEL_NULL(victim.ai_controller)

	var/threshold = victim.maxHealth * AI_FRIENDLY_FIRE_TOLERANCE
	TEST_ASSERT(threshold > 2, "Санити: порог обязан быть больше одного тестового удара")

	TEST_ASSERT(!victim.consider_retaliation(ally, 0), "Нулевой урон от своего не копится")
	TEST_ASSERT(!victim.consider_retaliation(ally, 1), "Одиночная царапина от своего не переводит в враги")
	TEST_ASSERT(!victim.CanAttack(ally), "Сокомандник ниже порога обязан остаться не-целью")

	TEST_ASSERT(victim.consider_retaliation(ally, threshold), "Накопленный урон выше порога обязан создать обиду")
	TEST_ASSERT(victim.CanAttack(ally), "После превышения порога сокомандник становится валидной целью")

///Чужак остаётся врагом с первого касания: толерантность - только к своим.
/datum/unit_test/hostile_retaliates_against_outsider_at_once/Run()
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/outsider = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, EAST))
	QDEL_NULL(victim.ai_controller)
	outsider.faction = list("ai_unit_test_outsiders")

	TEST_ASSERT(victim.consider_retaliation(outsider, 0), "Обида на чужую фракцию не гейтится уроном")
	TEST_ASSERT(outsider in victim.enemies, "Чужак обязан попасть в enemies")

///Грейс потери LOS: мигнувшая за углом цель не разжалуется мгновенно - пик
///из-за угла на полсекунды не должен обнулять ENGAGE (плейтест round-23.35.57)
/datum/unit_test/ai_finder_los_grace_before_demote/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, prey_turf)
	var/turf/blocker_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	allocate(/obj/effect/ai_unit_test_opaque_blocker, blocker_turf)
	var/datum/ai_controller/unit_test_hunter/controller = new(hunter)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)

	TEST_ASSERT(!can_see(hunter, prey, 14), "Санити: преграда обязана скрывать цель")
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)

	//первый цикл со скрытой целью: грейс, а не мгновенный демоушен
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "Мигнувший LOS не имеет права мгновенно разжаловать цель")
	TEST_ASSERT((controller.blackboard[BB_AI_LOS_LOST_AT] || 0) > 0, "Первый скрытый цикл обязан ставить отметку потери LOS")

	//цель показалась обратно: отметка снимается, цель держится
	var/turf/visible_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	prey.forceMove(visible_turf)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "Показавшаяся цель обязана удерживаться")
	TEST_ASSERT(isnull(controller.blackboard[BB_AI_LOS_LOST_AT]), "Возвращённый LOS обязан снимать отметку потери")

	//грейс истёк, цель всё ещё скрыта: честный демоушен в контакт
	prey.forceMove(prey_turf)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	controller.blackboard[BB_AI_LOS_LOST_AT] = world.time - AI_LOS_DEMOTE_GRACE - 1
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "Истёкший грейс обязан разжаловать скрытую цель")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CONTACT_TARGET], prey, "Разжалованная цель обязана стать розыскным контактом")

	qdel(controller)

///Свежепомеченная непробиваемой цель не реаквайрится финдером: иначе моб мерцает
///"взял-бросил" каждые полсекунды, стоя вплотную к врагу, которого нечем пробить
/datum/unit_test/ai_finder_skips_impervious_target/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/armored = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/datum/ai_controller/unit_test_hunter/controller = new(hunter)
	controller.blackboard[BB_AI_TARGET_IMPERVIOUS_REF] = WEAKREF(armored)
	controller.blackboard[BB_AI_TARGET_IMPERVIOUS_UNTIL] = world.time + AI_IMPERVIOUS_MEMORY

	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET), "Свежая непробиваемая пометка обязана исключать цель из выбора")

	//босс (pursuit_leashed = FALSE) пометку игнорирует: его погоня - содержание боя
	controller.pursuit_leashed = FALSE
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = 0
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], armored, "Отписанный от поводка контроллер не фильтрует непробиваемых")

	//пометка протухла: обычный контроллер снова берёт цель
	controller.pursuit_leashed = TRUE
	controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = 0
	controller.blackboard[BB_AI_TARGET_IMPERVIOUS_UNTIL] = 0
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], armored, "Протухшая пометка обязана возвращать цель в выбор")

	qdel(controller)
