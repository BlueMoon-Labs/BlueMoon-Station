// Память hostile-контроллера: возмездие, боевые контакты (свои и доложенные),
// последняя подтверждённая позиция, фрустрация.
// Все хелперы безопасны для вызова из сигнал-хендлеров (не спят).
//
// Контакт - это НЕ цель. BB_AI_CURRENT_TARGET держит только то, что моб
// воспринимает сам; контакт (BB_AI_CONTACT_TARGET + BB_AI_LAST_KNOWN_POS +
// BB_AI_LAST_SEEN_TIME + BB_AI_CONTACT_SOURCE) - улика, к которой ходят
// искать. Живой атом снова становится целью только через собственный LOS
// в find_potential_targets.

///Максимум записей в списке обид; сверх этого протухшие и старейшие вычищаются
#define AI_GRUDGE_LIST_MAX 12

///Запомнить атакующего: обида + пробуждение; зовётся из хуков урона пауна
/datum/ai_controller/proc/note_attacker(atom/movable/attacker)
	if(QDELETED(attacker) || attacker == pawn)
		return
	set_blackboard_key(BB_AI_LAST_ATTACKER, attacker)
	set_blackboard_key_assoc_lazylist(BB_AI_GRUDGE_LIST, attacker, world.time)
	prune_grudges()
	blackboard[BB_AI_ROUTE_RETRY_AT] = null
	//боль перепроверяет и IDLE, и OFF: OFF мог остаться от пустого z-level,
	//а реальные причины отключения get_expected_ai_status() сохранит
	if(ai_status != AI_STATUS_ON)
		set_ai_status(get_expected_ai_status())

///TRUE, если обида на цель ещё не протухла
/datum/ai_controller/proc/holds_grudge_against(atom/movable/the_enemy)
	var/list/grudges = blackboard[BB_AI_GRUDGE_LIST]
	if(!grudges)
		return FALSE
	var/grudge_time = grudges[the_enemy]
	if(!grudge_time)
		return FALSE
	if(world.time - grudge_time > AI_GRUDGE_TIMEOUT)
		remove_thing_from_blackboard_key(BB_AI_GRUDGE_LIST, the_enemy)
		return FALSE
	return TRUE

///Ограниченная чистка обид: протухшие всегда, старейшие - при переполнении.
///Держит tracked-ссылки списка конечными даже под очередью из толпы обидчиков.
/datum/ai_controller/proc/prune_grudges()
	var/list/grudges = blackboard[BB_AI_GRUDGE_LIST]
	if(length(grudges) <= AI_GRUDGE_LIST_MAX)
		return
	var/atom/movable/oldest
	var/oldest_time = INFINITY
	//итерация по копии ключей: удаление из живого списка во время обхода
	//молча пропускает соседние записи
	for(var/atom/movable/the_enemy as anything in grudges.Copy())
		if(world.time - grudges[the_enemy] > AI_GRUDGE_TIMEOUT)
			remove_thing_from_blackboard_key(BB_AI_GRUDGE_LIST, the_enemy)
			continue
		if(grudges[the_enemy] < oldest_time)
			oldest_time = grudges[the_enemy]
			oldest = the_enemy
	if(length(grudges) > AI_GRUDGE_LIST_MAX && oldest)
		remove_thing_from_blackboard_key(BB_AI_GRUDGE_LIST, oldest)

#undef AI_GRUDGE_LIST_MAX

///Доложить союзникам о контакте (pack-канал): передаётся ТОЧКА и приметы, не
///GPS-маячок. Получатель идёт проверять точку через SEARCH и захватывает цель
///только собственным восприятием.
///
///Паритет с легаси: summon_backup обходил oview(distance) - союзник обязан
///РЕАЛЬНО ВИДЕТЬ зовущего. Грид-обход стен не знает, поэтому LOS-гейт стоит
///здесь явно, а радиус дополнительно клампится потолком AI_ALLY_ALERT_RANGE.
///Моб, который сам поднят чужим зовом, эстафету не продолжает - иначе один
///выстрел разгонял волну агра по всему аванпосту.
/datum/ai_controller/proc/report_contact_to_allies(atom/target, share_range = AI_ALLY_ALERT_RANGE, source = AI_CONTACT_ALLY)
	if(QDELETED(target) || !isliving(pawn))
		return
	if(world.time < (blackboard[BB_AI_ALLY_RELAY_MUTED_UNTIL] || 0))
		return 0
	var/turf/reported_turf = get_turf(target)
	if(!reported_turf)
		return
	share_range = min(share_range, AI_ALLY_ALERT_RANGE)
	var/mob/living/living_pawn = pawn
	var/shared_count = 0
	for(var/mob/living/ally as anything in SSspatial_grid.orthogonal_range_search(living_pawn, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, share_range))
		if(ally == living_pawn || QDELETED(ally.ai_controller))
			continue
		if(get_dist(living_pawn, ally) > share_range)
			continue
		if(!living_pawn.faction_check_mob(ally))
			continue
		//стена гасит зов: сосед по комнате слышит, сосед за шлюзом - нет
		if(!can_see(living_pawn, ally, share_range))
			continue
		if(ally.ai_controller.receive_combat_contact(target, reported_turf, source))
			shared_count++
	return shared_count

///Принять сведения о контакте (доклад союзника или шум). Занятые боем мобы
///игнорируют: у них есть собственное восприятие. Возвращает TRUE, если принято.
/datum/ai_controller/proc/receive_combat_contact(atom/reported_target, turf/reported_turf, source = AI_CONTACT_ALLY)
	if(!reported_turf || QDELETED(pawn))
		return FALSE
	if(blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return FALSE
	//поднятый чужим зовом сам зов дальше не рассылает: иначе прибежавший
	//союзник открывает новый пузырь оповещения и волна идёт эстафетой
	if(source == AI_CONTACT_ALLY)
		blackboard[BB_AI_ALLY_RELAY_MUTED_UNTIL] = world.time + AI_ALLY_RELAY_MUTE_TIME
	if(!isnull(reported_target) && !QDELETED(reported_target))
		set_blackboard_key(BB_AI_CONTACT_TARGET, reported_target)
	set_blackboard_key(BB_AI_LAST_KNOWN_POS, reported_turf)
	blackboard[BB_AI_LAST_SEEN_TIME] = world.time
	blackboard[BB_AI_CONTACT_SOURCE] = source
	blackboard[BB_AI_STATE] = AI_STATE_SEARCH
	blackboard[BB_AI_STATE_ENTERED_AT] = world.time
	blackboard[BB_AI_SEARCH_UNTIL] = world.time + (blackboard[BB_AI_SEARCH_TIME] || AI_DEFAULT_SEARCH_TIME)
	blackboard[BB_AI_SEARCH_POINTS_LEFT] = AI_SEARCH_INVESTIGATE_POINTS
	clear_blackboard_key(BB_AI_SEARCH_POINT)
	if(ai_status != AI_STATUS_ON)
		set_ai_status(get_expected_ai_status())
	return TRUE

///TRUE, пока контакт достаточно свеж для бонуса скоринга при повторном захвате
/datum/ai_controller/proc/has_fresh_contact()
	if(!blackboard_key_exists(BB_AI_CONTACT_TARGET))
		return FALSE
	return world.time - (blackboard[BB_AI_LAST_SEEN_TIME] || 0) < AI_CONTACT_FRESH_TIME

///Разжаловать живую цель в контакт: LOS потерян, движение к реальной позиции
///атома прекращается. Улика (последняя подтверждённая точка) сохраняется,
///FSM переведёт моба в SEARCH на следующем плане.
/datum/ai_controller/proc/demote_target_to_contact(target_key)
	var/atom/lost_target = blackboard[target_key]
	if(QDELETED(lost_target))
		clear_blackboard_key(target_key)
		return
	set_blackboard_key(BB_AI_CONTACT_TARGET, lost_target)
	blackboard[BB_AI_CONTACT_SOURCE] = AI_CONTACT_PERSONAL
	clear_mob_congestion(lost_target)
	clear_blackboard_key(target_key)
	clear_blackboard_key(BB_AI_TARGET_HIDING_LOCATION)

///Отметить неудачный шаг/недостижимость: растит фрустрацию до сброса цели
/datum/ai_controller/proc/note_move_failure()
	blackboard[BB_AI_FRUSTRATION] = (blackboard[BB_AI_FRUSTRATION] || 0) + 1

///Record a repeated mob-only obstruction without treating one moving neighbour
///as an unreachable route. Once the threshold is reached, the normal target
///finder gets one prompt chance to prefer a nearby enemy with an open approach.
/datum/ai_controller/proc/note_mob_congestion(atom/movement_target)
	if(QDELETED(movement_target) || movement_target != blackboard[BB_AI_CURRENT_TARGET])
		clear_mob_congestion_streak()
		return
	if(blackboard[BB_AI_MOB_BLOCKED_TARGET] != movement_target)
		clear_mob_congestion_streak()
		set_blackboard_key(BB_AI_MOB_BLOCKED_TARGET, movement_target)
	var/blocked_steps = (blackboard[BB_AI_MOB_BLOCKED_STEPS] || 0) + 1
	blackboard[BB_AI_MOB_BLOCKED_STEPS] = blocked_steps
	if(blocked_steps < AI_MOB_CONGESTION_RETRY_THRESHOLD)
		return
	set_blackboard_key(BB_AI_CONGESTED_TARGET, movement_target)
	blackboard[BB_AI_CONGESTED_UNTIL] = world.time + AI_MOB_CONGESTION_MEMORY
	blackboard[BB_AI_TARGET_REFRESH_AT] = 0
	clear_mob_congestion_streak()

///Break the consecutive-block streak while preserving an already armed short
///retarget window until it is consumed, expires, or movement succeeds.
/datum/ai_controller/proc/clear_mob_congestion_streak()
	clear_blackboard_key(BB_AI_MOB_BLOCKED_TARGET)
	blackboard[BB_AI_MOB_BLOCKED_STEPS] = 0

///Clear congestion state for a matching movement target. A different target
///must not erase the old marker before the target finder consumes it.
/datum/ai_controller/proc/clear_mob_congestion(atom/movement_target)
	clear_mob_congestion_streak()
	if(movement_target && blackboard[BB_AI_CONGESTED_TARGET] != movement_target)
		return
	clear_blackboard_key(BB_AI_CONGESTED_TARGET)
	blackboard[BB_AI_CONGESTED_UNTIL] = null

///Сбросить боевую память (потеря цели, возврат к охране/покою)
/datum/ai_controller/proc/clear_engagement_memory()
	clear_blackboard_key(BB_AI_CURRENT_TARGET)
	clear_blackboard_key(BB_AI_TARGET_HIDING_LOCATION)
	clear_blackboard_key(BB_AI_LAST_KNOWN_POS)
	clear_blackboard_key(BB_AI_CONTACT_TARGET)
	clear_blackboard_key(BB_AI_SEARCH_POINT)
	clear_blackboard_key(BB_AI_APPROACH_TILE)
	blackboard[BB_AI_CONTACT_SOURCE] = null
	blackboard[BB_AI_SEARCH_POINTS_LEFT] = null
	blackboard[BB_AI_FRUSTRATION] = 0
	blackboard[BB_AI_LAST_SEEN_TIME] = null
	blackboard[BB_AI_HOLD_UNTIL] = null
	clear_mob_congestion()

///A hostile that exhausted its movement attempts must not immediately rebuild
///the identical plan forever. Release the target briefly so it may wander out
///of a firing lane or choose another visible enemy; taking damage wakes it at once.
/datum/ai_controller/hostile_adapter/on_pathing_attempts_exhausted()
	if(!blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	clear_engagement_memory()
	blackboard[BB_AI_ROUTE_RETRY_AT] = world.time + AI_UNREACHABLE_ROUTE_RETRY
