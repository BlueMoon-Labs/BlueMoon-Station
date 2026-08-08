// Threat-aware tactical positioning helpers for ranged hostile AI.
// All procs are cheap and non-sleeping: local geometry + one cached spatial-grid
// query. Most scoring is controller-free; ai_score_fire_tile uses
// shooter.ai_controller.cover_quality() when scoring cover and needs a controller.

///Штраф за тайл отклонения от боевой дистанции при выборе огневой позиции
#define TARGET_TILE_BAND_PENALTY 5

///Минимальная дистанция от тайла до любой угрозы (INFINITY при пустом списке)
/proc/ai_nearest_threat_distance(turf/tile, list/threats)
	. = INFINITY
	if(!tile || !length(threats))
		return
	for(var/mob/living/threat as anything in threats)
		if(QDELETED(threat))
			continue
		var/distance = get_dist(tile, threat)
		if(distance < .)
			. = distance

///Тактическая ценность огневого тайла: чистая линия огня доминирует, дальше -
///держим боевую дистанцию, дальше от ближайшей угрозы, под прикрытием стен и не
///толкаясь со своими стрелками. allies - свои AI-мобы для разноса позиций.
/proc/ai_score_fire_tile(mob/living/simple_animal/hostile/shooter, turf/tile, atom/target, list/threats, ideal_min, ideal_max, list/allies, atom/cover_from)
	if(!tile)
		return -INFINITY
	. = 0
	//прикрытость от того, кто по нам сейчас работает, С УЧЁТОМ ТИПА ЕГО СНАРЯДА.
	//Считается ровно для одного стрелка, а не для всего списка угроз: cover_quality
	//зовёт can_see, и делать это для каждой пары "кандидат x угроза" дороже, чем
	//всё остальное планирование вместе взятое.
	if(cover_from && shooter?.ai_controller)
		var/datum/ai_controller/shooter_controller = shooter.ai_controller
		if(shooter_controller.cover_quality(tile, cover_from) == AI_COVER_FULL)
			. += AI_FIRE_TILE_THREAT_COVER_BONUS
	//линия огня по реальной трассе снаряда из гипотетического тайла: чистая линия
	//доминирует, стрельба через дальнее пробиваемое укрытие ценится, но меньше
	if(istype(shooter) && target)
		switch(shooter.CheckRangedFireLaneStateFrom(target, tile))
			if(AI_FIRE_LANE_CLEAR)
				. += AI_FIRE_TILE_LANE_BONUS
			if(AI_FIRE_LANE_COVER)
				. += AI_FIRE_TILE_COVER_LANE_BONUS
	//боевая дистанция: штраф за выход из band [ideal_min, ideal_max]
	if(target && (ideal_min || ideal_max))
		var/target_distance = get_dist(tile, target)
		if(target_distance < ideal_min)
			. -= (ideal_min - target_distance) * TARGET_TILE_BAND_PENALTY
		else if(target_distance > ideal_max)
			. -= (target_distance - ideal_max) * TARGET_TILE_BAND_PENALTY
	//дальше от ближайшего врага = безопаснее
	var/nearest = ai_nearest_threat_distance(tile, threats)
	if(nearest != INFINITY)
		. += nearest
	//враги вплотную к тайлу - плохо (в шаге от нового окружения)
	for(var/mob/living/threat as anything in threats)
		if(QDELETED(threat))
			continue
		if(get_dist(tile, threat) <= 1)
			. -= AI_FIRE_TILE_ADJACENT_THREAT_PENALTY
	//разнос: свой стрелок вплотную к тайлу штрафуется, чтобы не толкаться за один
	for(var/mob/living/ally as anything in allies)
		if(QDELETED(ally))
			continue
		if(get_dist(tile, ally) <= 1)
			. -= AI_FIRE_TILE_ALLY_CROWD_PENALTY
	//укрытие: плотные соседи мешают окружить (стены коридора)
	for(var/direction in GLOB.alldirs)
		var/turf/neighbor = get_step(tile, direction)
		if(neighbor?.is_blocked_turf())
			. += AI_FIRE_TILE_COVER_BONUS

///Ближние угрозы (враги по стратегии таргетинга) через AI_TARGETS-грид.
///Кэшируется на один тик планирования: несколько поведений в одном плане
///переиспользуют один запрос грида.
/datum/ai_controller/proc/get_nearby_threats(radius = AI_THREAT_SCAN_RANGE)
	if(blackboard[BB_AI_THREAT_CACHE_AT] == world.time && islist(blackboard[BB_AI_THREAT_CACHE]))
		return blackboard[BB_AI_THREAT_CACHE]
	var/list/threats = list()
	var/mob/living/living_pawn = pawn
	if(isliving(living_pawn))
		var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(blackboard[BB_AI_TARGETING_STRATEGY])
		for(var/mob/living/candidate as anything in SSspatial_grid.orthogonal_range_search(living_pawn, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, radius))
			if(candidate == living_pawn || QDELETED(candidate))
				continue
			if(get_dist(living_pawn, candidate) > radius)
				continue
			if(strategy && !strategy.can_attack(living_pawn, candidate, radius))
				continue
			threats |= candidate
	//текущая цель всегда входит в набор угроз, даже вне грида
	var/mob/living/current = blackboard[BB_AI_CURRENT_TARGET]
	if(isliving(current) && !QDELETED(current))
		threats |= current
	blackboard[BB_AI_THREAT_CACHE] = threats
	blackboard[BB_AI_THREAT_CACHE_AT] = world.time
	return threats

///Ближние союзники (свои AI-мобы одной фракции) для разноса огневых позиций:
///два стрелка не должны драться за один тайл. Радиус мал (спейсинг локальный),
///кэшируется на тик планирования, как и угрозы.
/datum/ai_controller/proc/get_nearby_allies(radius = AI_ALLY_SPACING_RANGE)
	//кэш валиден только для своего радиуса: стайный idle спрашивает шире
	//спейсинга, и ответ одного не должен подменять ответ другого
	if(blackboard[BB_AI_ALLY_CACHE_AT] == world.time && blackboard[BB_AI_ALLY_CACHE_RANGE] == radius && islist(blackboard[BB_AI_ALLY_CACHE]))
		return blackboard[BB_AI_ALLY_CACHE]
	var/list/allies = list()
	var/mob/living/living_pawn = pawn
	if(isliving(living_pawn))
		for(var/mob/living/candidate in range(radius, living_pawn))
			if(candidate == living_pawn || QDELETED(candidate))
				continue
			if(!candidate.ai_controller || candidate.client)
				continue
			if(!living_pawn.faction_check_mob(candidate))
				continue
			allies += candidate
	blackboard[BB_AI_ALLY_CACHE] = allies
	blackboard[BB_AI_ALLY_CACHE_AT] = world.time
	blackboard[BB_AI_ALLY_CACHE_RANGE] = radius
	return allies

///Лучший огневой тайл среди 8 соседей плюс текущий; текущий держится, если
///проигрывает лидеру меньше AI_HOLD_TOLERANCE (анти-джиттер / удержание позиции).
///Результат кэшируется: пока паун и цель стоят на месте, девять трасс линии
///огня каждые полсекунды дают тот же ответ. Ключ инвалидируется движением
///любой стороны, сменой параметров и изменением числа угроз; закэшированный
///тайл перед выдачей перепроверяется на проходимость (разрушение/заставили).
/datum/ai_controller/proc/best_reposition_tile(atom/target, list/threats, want_lane = TRUE, ideal_min = 0, ideal_max = 0)
	var/mob/living/simple_animal/hostile/shooter = pawn
	var/turf/current_turf = get_turf(pawn)
	if(!current_turf)
		return null
	var/turf/target_turf = get_turf(target)
	var/list/allies = get_nearby_allies()
	//От кого именно ищем прикрытие: тот, кто по нам реально работает, а если
	//такого нет - сама цель. Один атом, а не весь список угроз: цена cover_quality
	//линейна по кандидатам, и множить её на число угроз незачем.
	var/atom/cover_from = blackboard[BB_AI_LAST_ATTACKER]
	if(QDELETED(cover_from))
		cover_from = target
	var/cache_key = "[REF(current_turf)]|[target_turf ? REF(target_turf) : "-"]|[want_lane]|[ideal_min]|[ideal_max]|[length(threats)]|[length(allies)]|[cover_from ? REF(cover_from) : "-"]"
	if(blackboard[BB_AI_COVER_CACHE_KEY] == cache_key && world.time - (blackboard[BB_AI_COVER_CACHE_AT] || -INFINITY) < AI_COVER_CACHE_TIME)
		var/turf/cached = blackboard[BB_AI_COVER_CACHE]
		if(cached && (cached == current_turf || (can_enter_turf(cached) && !cached.is_blocked_turf(source_atom = pawn))))
			return cached
	var/turf/best = current_turf
	var/best_score = ai_score_fire_tile(shooter, current_turf, target, threats, ideal_min, ideal_max, allies, cover_from)
	for(var/direction in GLOB.alldirs)
		var/turf/candidate = get_step(current_turf, direction)
		if(!candidate || !can_enter_turf(candidate) || candidate.is_blocked_turf(source_atom = pawn))
			continue
		if(want_lane && istype(shooter) && target && shooter.CheckRangedFireLaneFrom(target, candidate))
			continue
		var/candidate_score = ai_score_fire_tile(shooter, candidate, target, threats, ideal_min, ideal_max, allies, cover_from)
		if(candidate_score > best_score + AI_HOLD_TOLERANCE)
			best = candidate
			best_score = candidate_score
	blackboard[BB_AI_COVER_CACHE] = best
	blackboard[BB_AI_COVER_CACHE_KEY] = cache_key
	blackboard[BB_AI_COVER_CACHE_AT] = world.time
	return best

///Свободный румб кольца боевой дистанции вокруг цели с ЧИСТОЙ линией огня,
///ближайший к стрелку. Решает очередь стрелков в затылок: когда соседний тайл
///линию не открывает (вся колонна перекрыта союзниками), а свободный фланг в
///паре шагов - открывает. Цена - до восьми трасс линии огня, поэтому зовётся
///только из подтверждённо застрявшего состояния (BB_AI_LANE_STUCK_AT) и не
///чаще AI_FLANK_RETRY_COOLDOWN. Тайлы, закоммиченные союзниками, заняты:
///без разноса вся группа выбирала одну точку и толкалась за неё телами.
/datum/ai_controller/proc/find_flank_fire_tile(atom/target)
	var/mob/living/simple_animal/hostile/shooter = pawn
	var/turf/target_turf = get_turf(target)
	var/turf/pawn_turf = get_turf(pawn)
	if(!istype(shooter) || !target_turf || !pawn_turf)
		return null
	var/ideal_min = blackboard[BB_AI_MIN_DISTANCE] || 0
	var/ideal_max = max(blackboard[BB_AI_MAX_DISTANCE] || 0, ideal_min)
	//кольцо на текущей дистанции, зажатое в боевой band: фланг - это манёвр
	//вбок, а не сближение и не отход
	var/flank_radius = clamp(get_dist(pawn_turf, target_turf), max(ideal_min, AI_FLANK_MIN_RADIUS), max(ideal_max, AI_FLANK_MIN_RADIUS))
	var/list/allies = get_nearby_allies(AI_FLANK_CLAIM_ALLY_RANGE)
	var/turf/best
	var/best_travel = INFINITY
	for(var/direction in GLOB.alldirs)
		var/candidate_x = target_turf.x + ((direction & EAST) ? flank_radius : ((direction & WEST) ? -flank_radius : 0))
		var/candidate_y = target_turf.y + ((direction & NORTH) ? flank_radius : ((direction & SOUTH) ? -flank_radius : 0))
		if(candidate_x < 1 || candidate_x > world.maxx || candidate_y < 1 || candidate_y > world.maxy)
			continue
		var/turf/candidate = locate(candidate_x, candidate_y, target_turf.z)
		if(!candidate || candidate == pawn_turf)
			continue
		var/travel = get_dist(pawn_turf, candidate)
		if(travel >= best_travel)
			continue
		if(flank_tile_claimed_by_ally(candidate, allies))
			continue
		if(!can_enter_turf(candidate) || candidate.is_blocked_turf(source_atom = pawn))
			continue
		if(shooter.CheckRangedFireLaneFrom(target, candidate))
			continue
		best = candidate
		best_travel = travel
	return best

///Занят ли фланговый тайл живым манёвром союзника
/datum/ai_controller/proc/flank_tile_claimed_by_ally(turf/candidate, list/allies)
	for(var/mob/living/ally as anything in allies)
		if(QDELETED(ally) || QDELETED(ally.ai_controller))
			continue
		if(ally.ai_controller.blackboard[BB_AI_FLANK_TILE] == candidate)
			return TRUE
	return FALSE

///Снять фланговый манёвр: ключи коммита и, если ведётся, само движение на фланг
/datum/ai_controller/proc/clear_flank_commit()
	if(isnull(blackboard[BB_AI_FLANK_TILE]))
		return
	clear_blackboard_key(BB_AI_FLANK_TILE)
	blackboard[BB_AI_FLANK_UNTIL] = null
	var/datum/ai_behavior/flank_hold = GET_AI_BEHAVIOR(/datum/ai_behavior/hold_covering_position)
	if(current_behaviors[flank_hold])
		fail_behavior(flank_hold)

///Тайл отхода при кайте: уходим от ближайшей угрозы, штрафуя шаг вплотную к
///другим (не пятиться во второго фланкера). Возвращает лучший доступный сосед
///или null, если ходить некуда (тогда сработает hostile_break_away).
///allow_lateral - после серии зажатых планов разрешён боковой шаг РАВНОЙ
///дистанции: скольжение вдоль стены выводит из кармана, где строго-дальних
///тайлов нет вовсе, а зажатый стрелок стоял столбом минутами (round-23.35.57).
/datum/ai_controller/proc/best_retreat_tile(list/threats, allow_lateral = FALSE)
	var/turf/current_turf = get_turf(pawn)
	if(!current_turf || !length(threats))
		return null
	//от кого именно бежим: ближайшая к текущей позиции угроза
	var/atom/nearest_threat
	var/nearest_distance = INFINITY
	for(var/mob/living/threat as anything in threats)
		if(QDELETED(threat))
			continue
		var/distance = get_dist(current_turf, threat)
		if(distance < nearest_distance)
			nearest_distance = distance
			nearest_threat = threat
	if(!nearest_threat)
		return null
	var/turf/best
	var/best_score
	var/previous_dir = blackboard[BB_AI_LAST_RETREAT_DIR]
	for(var/direction in GLOB.alldirs)
		var/turf/candidate = get_step(current_turf, direction)
		if(!candidate || !can_enter_turf(candidate) || candidate.is_blocked_turf(source_atom = pawn))
			continue
		var/candidate_distance = get_dist(candidate, nearest_threat)
		//контракт "null, если ходить некуда": отход обязан СТРОГО увеличивать
		//дистанцию до ближайшей угрозы. Равноудалённый сосед - это пляска у
		//стены вплотную к жертве, а не отступление: из-за неё зажатый в тупике
		//стрелок вечно планировал step_away и никогда не признавал себя
		//зажатым, так что point_blank_shot/прорыв не наступали вовсе.
		//Исключение - явная эскалация (allow_lateral): равная дистанция
		//разрешена, но без разворота в прошлое направление, чтобы скольжение
		//вдоль стены не выродилось в ту же пляску.
		if(candidate_distance < nearest_distance)
			continue
		if(candidate_distance == nearest_distance)
			if(!allow_lateral)
				continue
			if(previous_dir && direction == REVERSE_DIR(previous_dir))
				continue
		//дальше от ближайшей угрозы - лучше; шаг вплотную к ДРУГОЙ угрозе штрафуется
		var/candidate_score = candidate_distance
		//гистерезис: продолжение прошлого направления даёт читаемую линию
		//отступления вместо рваного зигзага, по которому нельзя попасть
		if(previous_dir && direction == previous_dir)
			candidate_score += AI_RETREAT_DIR_HYSTERESIS
		for(var/mob/living/threat as anything in threats)
			if(QDELETED(threat) || threat == nearest_threat)
				continue
			if(get_dist(candidate, threat) <= 1)
				candidate_score -= AI_FIRE_TILE_ADJACENT_THREAT_PENALTY
		if(isnull(best) || candidate_score > best_score)
			best = candidate
			best_score = candidate_score
	if(best)
		blackboard[BB_AI_LAST_RETREAT_DIR] = get_dir(current_turf, best)
	return best

///Огневой тайл, прикрывающий направление toward (последняя известная позиция),
///с чистой линией к нему; для поджидания скрывшейся цели.
/datum/ai_controller/proc/best_covering_tile(turf/toward, list/threats, ideal_min, ideal_max)
	if(!toward)
		return null
	return best_reposition_tile(toward, threats, want_lane = TRUE, ideal_min = ideal_min, ideal_max = ideal_max)

///Тайл-укрытие от конкретного стрелка: сосед, с которого стрелка НЕ видно
///(разрыв линии огня доминирует), иначе хотя бы дальше от него. Кандидаты
///фильтруются по атмосфере - зажатый давлением моб прячется внутри безопасной
///зоны, а не стоит лёгкой мишенью на её краю.
/datum/ai_controller/proc/best_hiding_tile(atom/shooter)
	var/turf/current_turf = get_turf(pawn)
	var/turf/shooter_turf = get_turf(shooter)
	if(!current_turf || !shooter_turf)
		return null
	var/mob/living/simple_animal/simple_pawn = pawn
	var/datum/obstacle_policy/atmos_policy
	if(istype(simple_pawn) && simple_pawn.requires_safe_atmosphere())
		atmos_policy = GET_OBSTACLE_POLICY(blackboard[BB_AI_OBSTACLE_POLICY] || /datum/obstacle_policy)
	var/turf/best
	var/best_score
	for(var/direction in GLOB.alldirs)
		var/turf/candidate = get_step(current_turf, direction)
		if(!candidate || !can_enter_turf(candidate) || candidate.is_blocked_turf(source_atom = pawn))
			continue
		if(atmos_policy && !atmos_policy.step_preserves_atmosphere(simple_pawn, current_turf, candidate))
			continue
		var/candidate_score = get_dist(candidate, shooter_turf)
		//Прикрытие считается от ТИПА снаряда, а не от голой видимости: окно
		//держит пулю и пропускает луч, поэтому прятаться за стеклом от лазерщика
		//бессмысленно, а от баллистики - осмысленно (см. threat_model.dm).
		if(cover_quality(candidate, shooter) == AI_COVER_FULL)
			candidate_score += AI_HIDING_LOS_BONUS
		if(isnull(best) || candidate_score > best_score)
			best = candidate
			best_score = candidate_score
	return best

///Тайл прорыва из зажима: самый дальний достижимый открытый тайл от угроз в
///пределах AI_BREAK_AWAY_RANGE (JPS уведёт к нему через двери/в обход). Возвращает
///турф или null. Целью движения его ставит вызывающее поведение.
/datum/ai_controller/proc/plot_break_away(list/threats)
	var/turf/current_turf = get_turf(pawn)
	if(!current_turf || !length(threats))
		return null
	var/turf/best
	var/best_distance = ai_nearest_threat_distance(current_turf, threats)
	for(var/turf/candidate in oview(AI_BREAK_AWAY_RANGE, pawn))
		if(!isopenturf(candidate) || !can_enter_turf(candidate) || candidate.is_blocked_turf(source_atom = pawn))
			continue
		var/candidate_distance = ai_nearest_threat_distance(candidate, threats)
		if(candidate_distance > best_distance)
			best = candidate
			best_distance = candidate_distance
	return best

#undef TARGET_TILE_BAND_PENALTY
