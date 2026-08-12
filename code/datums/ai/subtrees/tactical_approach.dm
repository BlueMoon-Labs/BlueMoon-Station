// Мили-виляние hostile AI: лёгкий уворот/распределение пути мили-мобов против
// дальнобойных врагов. Только уровень планирования: сабтри выставляет СМЕЩЁННУЮ
// цель движения, а обычный гибридный мувер сам выгибает путь. Файлы движения и
// ranged-тактику параллельного агента (tactical_positioning.dm) не трогаем.

///Дальнобойная ли угроза эта цель: ranged-simple-моб или моб с пушкой в руках.
/proc/ai_target_is_ranged(atom/target)
	var/mob/living/simple_animal/hostile/hostile_target = target
	if(istype(hostile_target))
		return hostile_target.ranged
	var/mob/mob_target = target
	if(ismob(mob_target))
		return mob_target.is_holding_item_of_type(/obj/item/gun) ? TRUE : FALSE
	return FALSE

///Планировщик тайла подхода мили-моба. Две задачи:
///1) окружение вместо очереди: если прямой шаг занят союзником, целью движения
///   становится СВОБОДНАЯ клетка вплотную к цели, а не спина сокомандника;
///2) виляние против дальника: под прицелом (цель ranged или по нам стреляли)
///   лобовая клетка штрафуется - моб заходит с фланга, не стоя на линии огня.
///Сабтри только ведёт ключ BB_AI_APPROACH_TILE; движение переключает
///hostile_melee_attack на своём обычном тике.
/datum/ai_planning_subtree/tactical_approach

/datum/ai_planning_subtree/tactical_approach/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/pawn = controller.pawn
	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]
	if(!isliving(pawn) || QDELETED(target))
		clear_approach_tile(controller)
		return
	//Опознание стрелка идёт памятью, а не проверкой рук: запись в модели угрозы
	//появляется от факта попадания снаряда и переживает и убранный ствол, и КА,
	//и мех, и турель.
	var/known_shooter = ai_target_is_ranged(target) || controller.knows_target_shoots(target)
	var/target_distance = get_dist(pawn, target)
	//Против опознанного стрелка уклончивый подход действует на всей дистанции
	//обстрела, а не только внутри экрана.
	var/weave_range = known_shooter ? AI_SHOOTER_WEAVE_MAX_DIST : AI_WEAVE_MAX_DIST
	if(target_distance <= 1 || target_distance > weave_range)
		clear_approach_tile(controller)
		return
	var/weaving = known_shooter || (controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] > world.time)
	var/queued_behind_ally = controller.is_mob_only_blocked_step(get_step_towards(pawn, target))
	if(!weaving && !queued_behind_ally)
		clear_approach_tile(controller)
		return
	if(world.time < (controller.blackboard[BB_AI_APPROACH_TILE_AT] || 0))
		return
	controller.blackboard[BB_AI_APPROACH_TILE_AT] = world.time + AI_APPROACH_REPICK_COOLDOWN
	//Перебежка под прикрытием важнее выбора финальной клетки: пока моб далеко,
	//вопрос не "с какой стороны подойти", а "как дойти живым".
	var/turf/chosen = known_shooter ? pick_covered_bound(controller, pawn, target) : null
	if(!chosen)
		chosen = pick_approach_tile(controller, pawn, target, weaving)
	if(chosen)
		controller.set_blackboard_key(BB_AI_APPROACH_TILE, chosen)
	else
		clear_approach_tile(controller)

///Шаг перебежки: сосед, прикрытый от стрелка и СТРОГО ближе к цели.
///
///Это намеренно не полноценный слой стоимости простреливаемости на маршруте:
///пересчёт прикрытости для каждого узла пути стоил бы дороже всего остального
///планирования вместе взятого. Локальная перебежка от укрытия к укрытию даёт то
///же наблюдаемое поведение - моб не бежит по прямой в створ, - и стоит восьми
///проверок раз в AI_APPROACH_REPICK_COOLDOWN. Если прикрытого шага вперёд нет,
///возвращается null, и подход планируется обычной логикой: моб не окапывается.
/datum/ai_planning_subtree/tactical_approach/proc/pick_covered_bound(datum/ai_controller/controller, mob/living/pawn, atom/target)
	var/turf/pawn_turf = get_turf(pawn)
	var/turf/target_turf = get_turf(target)
	if(!pawn_turf || !target_turf)
		return null
	var/atom/shooter = controller.blackboard[BB_AI_LAST_ATTACKER]
	if(QDELETED(shooter))
		shooter = target
	var/turf/best
	var/best_distance = get_dist(pawn_turf, target_turf)
	for(var/direction in GLOB.alldirs)
		var/turf/candidate = get_step(pawn_turf, direction)
		if(!candidate || !controller.can_enter_turf(candidate) || candidate.is_blocked_turf(source_atom = pawn))
			continue
		var/candidate_distance = get_dist(candidate, target_turf)
		if(candidate_distance >= best_distance)
			continue
		if(controller.cover_quality(candidate, shooter) != AI_COVER_FULL)
			continue
		best = candidate
		best_distance = candidate_distance
	return best

/datum/ai_planning_subtree/tactical_approach/proc/clear_approach_tile(datum/ai_controller/controller)
	if(!isnull(controller.blackboard[BB_AI_APPROACH_TILE]))
		controller.clear_blackboard_key(BB_AI_APPROACH_TILE)

///Зажатый под огнём моб, которому некуда идти (цель недостижима: давление,
///пропасть, исчерпанная фрустрация пути), уходит за укрытие от стрелка вместо
///стояния лёгкой мишенью на открытом месте.
/datum/ai_planning_subtree/take_cover_when_pinned

/datum/ai_planning_subtree/take_cover_when_pinned/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	if(!(controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] > world.time))
		return
	var/mob/living/pawn = controller.pawn
	if(!isliving(pawn))
		return
	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]
	//цель есть и путь к ней ещё не исчерпан - обычный бой важнее пряток
	if(!QDELETED(target) && (controller.blackboard[BB_AI_FRUSTRATION] || 0) < AI_PINNED_FRUSTRATION)
		return
	var/atom/shooter = controller.blackboard[BB_AI_LAST_ATTACKER]
	if(QDELETED(shooter))
		shooter = target
	var/turf/pawn_turf = get_turf(pawn)
	var/turf/shooter_turf = QDELETED(shooter) ? null : get_turf(shooter)
	if(!pawn_turf || !shooter_turf || pawn_turf.z != shooter_turf.z)
		return
	//уже скрыты от стрелка - стоим в укрытии, не выбегаем обратно
	if(!can_see(pawn_turf, shooter, AI_HIDING_LOS_RANGE))
		return SUBTREE_RETURN_FINISH_PLANNING
	var/turf/hiding = controller.best_hiding_tile(shooter)
	if(isnull(hiding) || hiding == pawn_turf)
		return
	controller.queue_behavior(/datum/ai_behavior/hold_covering_position, hiding)
	return SUBTREE_RETURN_FINISH_PLANNING

///Лучшая свободная клетка вплотную к цели: ближе к мобу - лучше (меньше крюк),
///занятые союзниками исключены, при вилянии лобовая клетка штрафуется.
/datum/ai_planning_subtree/tactical_approach/proc/pick_approach_tile(datum/ai_controller/controller, mob/living/pawn, atom/target, weaving)
	var/turf/target_turf = get_turf(target)
	var/turf/pawn_turf = get_turf(pawn)
	if(!target_turf || !pawn_turf)
		return null
	var/dir_to_pawn = get_dir(target_turf, pawn_turf)
	var/turf/best
	var/best_score
	for(var/direction in GLOB.alldirs)
		var/turf/tile = get_step(target_turf, direction)
		if(!tile)
			continue
		if(!controller.can_enter_turf(tile) || tile.is_blocked_turf(source_atom = pawn))
			continue
		var/tile_score = -get_dist(pawn_turf, tile) * 2
		if(direction & dir_to_pawn)
			tile_score += 1 //своя сторона цели - меньше крюк
		if(weaving && direction == dir_to_pawn)
			tile_score -= 4 //лобовая клетка на линии огня - предпочесть фланг
		if(!isnull(best_score) && tile_score <= best_score)
			continue
		best = tile
		best_score = tile_score
	return best
