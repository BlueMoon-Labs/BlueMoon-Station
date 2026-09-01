// Координированное окружение стаи (A.1). Милишные мобы стаи расходятся по разным
// сторонам общей цели и закрывают её пути отхода, различаясь по роли: TANK держит
// фронт, HUNTER режет открытую сторону отхода, SKIRMISHER заходит с фланга. Через
// координатор /datum/ai_pack_focus с капом AI_ENCIRCLE_MAX - большой спавнер не даёт
// идеального death-box. Не координируется (соло / кап полон / нет открытого слота) ->
// no-op, работает обычный tactical_approach.
//
// Ставится ПЕРЕД tactical_approach; на успехе взводит общий троттл
// BB_AI_APPROACH_TILE_AT, поэтому tactical_approach уступает согласованный тайл.
// Файлы движения и tactical_positioning.dm не трогаются - только уже потребляемый
// ключ BB_AI_APPROACH_TILE.

/// Минимальная угловая разница двух углов в градусах, [0, 180].
/proc/ai_angle_delta(angle_a, angle_b)
	var/delta = abs(angle_a - angle_b) % 360
	return delta > 180 ? 360 - delta : delta

/datum/ai_planning_subtree/pack_encircle

/datum/ai_planning_subtree/pack_encircle/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/pawn = controller.pawn
	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]
	if(!isliving(pawn) || QDELETED(target) || !isliving(target))
		controller.release_pack_focus()
		return
	//окружаем только в активном бою: убегающий/ищущий/сзади-держащийся моб не лезет
	if(controller.blackboard[BB_AI_STATE] != AI_STATE_ENGAGE)
		controller.release_pack_focus()
		return
	var/target_distance = get_dist(pawn, target)
	if(target_distance <= 1 || target_distance > AI_WEAVE_MAX_DIST)
		controller.release_pack_focus()
		return
	//кап полон и мы не член -> обычный tactical_approach
	if(!controller.join_pack_focus(target))
		return
	//троттл общий с tactical_approach: держим выбранный тайл, не джиттерим
	if(world.time < (controller.blackboard[BB_AI_APPROACH_TILE_AT] || 0))
		return
	var/datum/ai_pack_focus/focus = controller.pack_focus
	var/chosen_dir = pick_encircle_dir(controller, pawn, target, focus)
	var/turf/chosen_turf = chosen_dir ? get_step(get_turf(target), chosen_dir) : null
	if(isnull(chosen_turf) || !controller.can_enter_turf(chosen_turf) || chosen_turf.is_blocked_turf(source_atom = pawn))
		return //слот не согласован - троттл НЕ взводим, ход у tactical_approach
	focus.claim_direction(controller, chosen_dir)
	controller.set_blackboard_key(BB_AI_APPROACH_TILE, chosen_turf)
	controller.blackboard[BB_AI_APPROACH_TILE_AT] = world.time + AI_APPROACH_REPICK_COOLDOWN

/// Лучшее свободное направление-слот вокруг цели по роли. NONE = нет открытого.
/datum/ai_planning_subtree/pack_encircle/proc/pick_encircle_dir(datum/ai_controller/controller, mob/living/pawn, atom/target, datum/ai_pack_focus/focus)
	var/turf/target_turf = get_turf(target)
	var/turf/pawn_turf = get_turf(pawn)
	if(!target_turf || !pawn_turf)
		return NONE
	var/list/taken = focus.taken_directions(controller)
	var/role = controller.blackboard[BB_AI_PACK_ROLE]
	var/approach_dir = get_dir(target_turf, pawn_turf) //с какой стороны заходит паун
	var/best_dir = NONE
	var/best_score = null
	for(var/direction in GLOB.alldirs)
		if(direction in taken)
			continue
		var/turf/tile = get_step(target_turf, direction)
		if(!tile || !controller.can_enter_turf(tile) || tile.is_blocked_turf(source_atom = pawn))
			continue
		//tie-break: ближе к пауну = меньше крюк (роль-бонусы доминируют над ним)
		var/score = -get_dist(pawn_turf, tile)
		score += role_slot_bonus(role, direction, approach_dir, taken)
		if(!isnull(best_score) && score <= best_score)
			continue
		best_score = score
		best_dir = direction
	return best_dir

/// Ролевой бонус выбора направления-слота вокруг цели.
/datum/ai_planning_subtree/pack_encircle/proc/role_slot_bonus(role, direction, approach_dir, list/taken)
	switch(role)
		if(AI_ROLE_TANK, AI_ROLE_FRONTLINE)
			return (direction == approach_dir) ? 100 : 0 //держать фронт со стороны пауна
		if(AI_ROLE_SKIRMISHER)
			//около перпендикуляра к оси захода = фланг
			return (abs(ai_angle_delta(dir2angle(direction), dir2angle(approach_dir)) - 90) <= 45) ? 100 : 0
		if(AI_ROLE_HUNTER)
			return cutoff_bonus(direction, approach_dir, taken)
	//прочие роли мягко тянутся закрыть брешь
	return cutoff_bonus(direction, approach_dir, taken) * 0.5

/// Отрезание отхода: дальше всех от занятых слотов; при пустом составе - дальняя
/// от захода сторона цели.
/datum/ai_planning_subtree/pack_encircle/proc/cutoff_bonus(direction, approach_dir, list/taken)
	var/dir_angle = dir2angle(direction)
	if(!length(taken))
		return ai_angle_delta(dir_angle, dir2angle(approach_dir)) //противоположно заходу
	var/min_gap = 360
	for(var/claimed in taken)
		min_gap = min(min_gap, ai_angle_delta(dir_angle, dir2angle(claimed)))
	return min_gap
