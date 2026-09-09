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
	note_combat_exchange()
	set_blackboard_key_assoc_lazylist(BB_AI_GRUDGE_LIST, attacker, world.time)
	prune_grudges()
	blackboard[BB_AI_ROUTE_RETRY_AT] = null
	//удар - это восприятие: моб знает, что по нему работают, и ОТКУДА прилетело.
	//Настороженность держит боевое зрение (get_aggro_range) даже после потери
	//цели - иначе моб с коротким пассивным зрением, потеряв цель (исчерпанный
	//маршрут, поводок), мгновенно слепнет, и стрелка в 4+ тайлах можно
	//расстреливать безнаказанно (плейтест 22.06: shambling miner с vision_range 3
	//стоял столбом под выстрелами и дрался только вплотную). Точка обидчика
	//становится уликой SEARCH, но НЕ розыскным контактом: бонус скоринга
	//контакта не должен дублировать обиду (фрустрация и протухание обид обязаны
	//работать как прежде).
	AI_TRACE_THROTTLED(src, "alert", "удар от [attacker] - настороженность взведена")
	blackboard[BB_AI_COMBAT_ALERT_UNTIL] = world.time + AI_CONTACT_FRESH_TIME
	if(!blackboard_key_exists(BB_AI_CURRENT_TARGET))
		var/turf/attacker_turf = get_turf(attacker)
		if(attacker_turf)
			set_blackboard_key(BB_AI_LAST_KNOWN_POS, attacker_turf)
			blackboard[BB_AI_LAST_SEEN_TIME] = world.time
			blackboard[BB_AI_STATE] = AI_STATE_SEARCH
			blackboard[BB_AI_STATE_ENTERED_AT] = world.time
			blackboard[BB_AI_SEARCH_UNTIL] = world.time + (blackboard[BB_AI_SEARCH_TIME] || AI_DEFAULT_SEARCH_TIME)
			blackboard[BB_AI_SEARCH_POINTS_LEFT] = AI_SEARCH_INVESTIGATE_POINTS
			clear_blackboard_key(BB_AI_SEARCH_POINT)
			//дальник поджидает, а не идёт пешком к стрелявшему в упор (паритет
			//с enter_search: пешая разведка - работа мили-мобов)
			var/mob/living/simple_animal/hostile/hostile_pawn = pawn
			if(istype(hostile_pawn) && hostile_pawn.ranged)
				blackboard[BB_AI_HOLD_UNTIL] = blackboard[BB_AI_SEARCH_UNTIL]
	//боль перепроверяет и IDLE, и OFF: OFF мог остаться от пустого z-level,
	//а реальные причины отключения get_expected_ai_status() сохранит
	if(ai_status != AI_STATUS_ON)
		set_ai_status(get_expected_ai_status())

///Отметить обмен уроном: моб либо получил по себе, либо сам достал цель.
///Кормит усталость погони - без неё преследование не имело условия окончания
///вовсе, пока держится LOS.
/datum/ai_controller/proc/note_combat_exchange()
	blackboard[BB_AI_LAST_EXCHANGE_AT] = world.time

///Учёт бесполезных ударов. Если серия попаданий подряд не сняла с цели ничего,
///цель помечается непробиваемой, и погоня по ней прекращается (hostile_fsm).
///Броня, которую моб физически не пробивает, - самая частая причина, по которой
///фауна часами грызла человека в скафандре, не нанося ему ни единицы урона.
///
///Снимок берётся ПЕРЕД ударом, поэтому следующий вызов сравнивает здоровье цели
///с тем, каким оно было до ПРЕДЫДУЩЕГО удара - то есть измеряет именно его эффект.
/datum/ai_controller/proc/note_melee_attempt(mob/living/target)
	if(!isliving(target))
		return
	var/datum/weakref/target_ref = WEAKREF(target)
	var/previous_health = blackboard[BB_AI_TARGET_HEALTH]
	var/datum/weakref/previous_ref = blackboard[BB_AI_TARGET_HEALTH_REF]
	blackboard[BB_AI_TARGET_HEALTH] = target.health
	blackboard[BB_AI_TARGET_HEALTH_REF] = target_ref
	//сменилась цель или это первый удар по ней - сравнивать не с чем
	if(previous_ref?.resolve() != target || isnull(previous_health))
		blackboard[BB_AI_FUTILE_HITS] = 0
		return
	//упало - пробиваем; ВЫРОСЛО - цель лечат или она регенится, и "не пробить"
	//не доказано: наш урон реален, его перекрывает чужое лечение. Доказательство
	//брони - серия из строго НЕИЗМЕННОГО здоровья, иначе фауна бросала жертву,
	//которую медик лечил быстрее, чем она её грызла.
	if(target.health != previous_health)
		blackboard[BB_AI_FUTILE_HITS] = 0
		return
	var/futile_hits = (blackboard[BB_AI_FUTILE_HITS] || 0) + 1
	blackboard[BB_AI_FUTILE_HITS] = futile_hits
	if(futile_hits < AI_FUTILE_HITS_THRESHOLD)
		return
	AI_TRACE(src, "combat", "[target] непробиваем ([AI_FUTILE_HITS_THRESHOLD] ударов без урона) - помечен на [AI_IMPERVIOUS_MEMORY / 10]с")
	blackboard[BB_AI_TARGET_IMPERVIOUS_UNTIL] = world.time + AI_IMPERVIOUS_MEMORY
	blackboard[BB_AI_TARGET_IMPERVIOUS_REF] = target_ref
	blackboard[BB_AI_FUTILE_HITS] = 0

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
		//хардделнутые мобы оставляют в ячейках грида null, а as anything его не
		//фильтрует - проверяем самого союзника раньше, чем его контроллер
		if(QDELETED(ally) || ally == living_pawn || QDELETED(ally.ai_controller))
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
	AI_TRACE(src, "contact", "принял контакт [reported_target || "?"] у ([reported_turf.x],[reported_turf.y],[reported_turf.z]) от [source]")
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

///TRUE, пока моб настороже: свежий розыскной контакт либо недавно полученный
///урон. Кормит подъём зрения до aggro_vision_range в get_aggro_range и быстрый
///каденс реакквизиции - но НЕ скоринг (тот читает только настоящий контакт).
/datum/ai_controller/proc/is_combat_alert()
	if(world.time < (blackboard[BB_AI_COMBAT_ALERT_UNTIL] || 0))
		return TRUE
	return has_fresh_contact()

///Разжаловать живую цель в контакт: LOS потерян, движение к реальной позиции
///атома прекращается. Улика (последняя подтверждённая точка) сохраняется,
///FSM переведёт моба в SEARCH на следующем плане.
/datum/ai_controller/proc/demote_target_to_contact(target_key)
	blackboard[BB_AI_LOS_LOST_AT] = null
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
	blackboard[BB_AI_LAST_KNOWN_DIR] = null
	blackboard[BB_AI_HOLD_UNTIL] = null
	blackboard[BB_AI_LANE_STUCK_AT] = null
	blackboard[BB_AI_FLANK_RETRY_AT] = null
	blackboard[BB_AI_LANE_DEADLOCK_UNTIL] = null
	blackboard[BB_AI_SIEGE_UNTIL] = null
	blackboard[BB_AI_LOS_LOST_AT] = null
	blackboard[BB_AI_KITE_PINNED_STREAK] = null
	clear_flank_commit()
	clear_mob_congestion()

///A hostile that exhausted its movement attempts must not immediately rebuild
///the identical plan forever. Release the target briefly so it may wander out
///of a firing lane or choose another visible enemy; taking damage wakes it at once.
///Разжалуем в контакт, а не стираем: цель недостижима ШАГАМИ, но не восприятием.
///Улика уводит моба в SEARCH к последней точке (attack_obstructions по пути
///копает, если моб умеет), а свежий контакт держит боевое зрение - полное
///стирание роняло vision_range до пассивного через LoseTarget->LoseAggro, и
///стрелок в 4+ тайлах становился невидим сразу после того, как всадил обойму.
///
///Два исключения (плейтест round-23.35.57):
///1) недостижимый ФЛАНГОВЫЙ манёвр снимает сам манёвр, а не цель - иначе
///   неудачный обход стоил стрелку всего боя;
///2) видимая цель в паре шагов не разжалуется, а осаждается: между нами мебель,
///   и цикл "взял-исчерпал-разжаловал-взял" крутился вечно (34 цикла за 2.5
///   минуты у стеклянного стола), не давая мобу ни стоять осмысленно, ни бить
///   преграду. Осаду разыгрывает hostile_fsm/plan_siege.
/datum/ai_controller/hostile_adapter/on_pathing_attempts_exhausted()
	if(!blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	if(!isnull(blackboard[BB_AI_FLANK_TILE]))
		AI_TRACE(src, "lane", "фланг недостижим - манёвр снят")
		clear_flank_commit()
		blackboard[BB_AI_FLANK_RETRY_AT] = world.time + AI_FLANK_RETRY_COOLDOWN
		return
	var/atom/unreachable_target = blackboard[BB_AI_CURRENT_TARGET]
	var/mob/living/living_pawn = pawn
	if(isliving(living_pawn) && !QDELETED(unreachable_target) \
		&& get_dist(living_pawn, unreachable_target) <= AI_SIEGE_HOLD_RANGE \
		&& can_see(living_pawn, unreachable_target, AI_SIEGE_HOLD_RANGE))
		blackboard[BB_AI_SIEGE_UNTIL] = world.time + AI_SIEGE_HOLD_TIME
		AI_TRACE(src, "move", "маршрут исчерпан, но [unreachable_target] на виду (дист [get_dist(living_pawn, unreachable_target)]) - осада")
		return
	AI_TRACE(src, "move", "маршрут исчерпан: [unreachable_target] разжалован в контакт[ai_trace_route_block_hint(unreachable_target)]")
	demote_target_to_contact(BB_AI_CURRENT_TARGET)
	blackboard[BB_AI_ROUTE_RETRY_AT] = world.time + AI_UNREACHABLE_ROUTE_RETRY
