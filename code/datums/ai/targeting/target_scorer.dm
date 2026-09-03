// Скоринг целей hostile AI: замена случайного PickTarget().
// Кандидаты уже прошли eligibility (targeting_strategy) - здесь только оценка
// тактической ценности. Синглтоны в SSai_behaviors.target_scorers.
//
// Правило выбора (select): топ-K по счёту, детерминированный тай-брейк -
// больший счёт, затем меньшая дистанция, затем порядок обхода. Случайность
// допускается только внутри топ-K через pick(), чтобы поведение не было
// идеально предсказуемым, но и не металось (гистерезис текущей цели).

///Бонус текущей цели: защита от таргет-трэшинга
#define TARGET_SCORE_CURRENT_BONUS 25
///Бонус обидчику (непротухшая обида)
#define TARGET_SCORE_GRUDGE_BONUS 40
///Бонус разыскиваемому контакту (своя потерянная цель или доклад союзника)
#define TARGET_SCORE_CONTACT_BONUS 20
///Штраф за тайл дистанции
#define TARGET_SCORE_DISTANCE_PENALTY 2
///Штраф текущей цели за единицу фрустрации (не можем дойти - ищем другую)
#define TARGET_SCORE_FRUSTRATION_PENALTY 10
///Бонус беспомощной цели (стан/крит) для профилей-падальщиков
#define TARGET_SCORE_VULNERABLE_BONUS 10
///Насколько текущая цель может проигрывать лидеру, оставаясь целью
#define TARGET_SCORE_STICKINESS 15
///Разброс счёта, внутри которого свежие кандидаты равноценны для pick()
#define TARGET_SCORE_PICK_GAP 10

/datum/target_scorer
	///Учитывать ли уязвимость (не-CONSCIOUS stat) как бонус
	var/prefer_vulnerable = FALSE

///Численная ценность кандидата; больше - приоритетнее
/datum/target_scorer/proc/score(datum/ai_controller/controller, atom/candidate, atom/current_target, candidate_distance)
	var/mob/living/pawn = controller.pawn
	. = 0

	//гистерезис: не бросать валидную цель ради соседней
	if(candidate == current_target)
		. += TARGET_SCORE_CURRENT_BONUS
		. -= TARGET_SCORE_FRUSTRATION_PENALTY * (controller.blackboard[BB_AI_FRUSTRATION] || 0)

	//возмездие: только непротухшие обиды (LAST_ATTACKER всегда записан и в обиды,
	//так что отдельная бессрочная ветка ему не положена)
	if(controller.holds_grudge_against(candidate))
		. += TARGET_SCORE_GRUDGE_BONUS

	//разыскиваемый контакт: своя скрывшаяся цель или доклад союзника
	if(candidate == controller.blackboard[BB_AI_CONTACT_TARGET] && controller.has_fresh_contact())
		. += TARGET_SCORE_CONTACT_BONUS

	//дистанция: ближе - лучше
	. -= (isnull(candidate_distance) ? get_dist(pawn, candidate) : candidate_distance) * TARGET_SCORE_DISTANCE_PENALTY

	//уязвимость: только для профилей, которым это интересно
	if(prefer_vulnerable && isliving(candidate))
		var/mob/living/living_candidate = candidate
		if(living_candidate.stat != CONSCIOUS || !(living_candidate.mobility_flags & MOBILITY_STAND))
			. += TARGET_SCORE_VULNERABLE_BONUS

///Порядковый ключ ранжирования: счёт доминирует, меньшая дистанция - тай-брейк.
///Дистанция всегда меньше 100, поэтому не пересекается с целочисленным счётом.
#define TARGET_ORDERING(candidate_score, candidate_dist) ((candidate_score) * 100 - (candidate_dist))

///Ранжировать кандидатов по предпочтению за ОДИН проход скоринга.
///Правила: валидная текущая цель идёт первой, пока не проигрывает лидеру больше
///чем на TARGET_SCORE_STICKINESS (детерминированный гистерезис); тай-брейк -
///меньшая дистанция; случайность только между свежими кандидатами в пределах
///TARGET_SCORE_PICK_GAP от лидера. Вызывающий обходит список по порядку и
///платит за дорогие проверки (LOS) только до первого прошедшего.
/datum/target_scorer/proc/rank(datum/ai_controller/controller, list/candidates, atom/current_target)
	if(length(candidates) <= 1)
		return candidates.Copy()

	var/mob/living/pawn = controller.pawn
	var/list/ordering = list()
	for(var/atom/candidate as anything in candidates)
		var/candidate_dist = get_dist(pawn, candidate)
		ordering[candidate] = TARGET_ORDERING(score(controller, candidate, current_target, candidate_dist), candidate_dist)
	sortTim(ordering, GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)

	var/list/ranked = ordering.Copy()
	var/best_ordering = ordering[ranked[1]]

	//гистерезис: текущая цель держится в лидерах, пока не проигрывает ощутимо
	if(current_target && !isnull(ordering[current_target]))
		if(ordering[current_target] >= best_ordering - TARGET_SCORE_STICKINESS * 100)
			ranked -= current_target
			ranked.Insert(1, current_target)
		return ranked

	//свежий выбор: непредсказуемость только среди почти равных лидеров
	var/near_best_count = 0
	for(var/atom/candidate as anything in ranked)
		if(ordering[candidate] < best_ordering - TARGET_SCORE_PICK_GAP * 100)
			break
		near_best_count++
	if(near_best_count > 1)
		var/list/near_best = ranked.Copy(1, near_best_count + 1)
		ranked.Cut(1, near_best_count + 1)
		while(length(near_best))
			var/atom/shuffled = pick(near_best)
			near_best -= shuffled
			ranked.Insert(1, shuffled)
	return ranked

///Выбрать одну цель за ОДИН проход без сортировки (частый открытый случай,
///где лидер сразу видим и полное ранжирование не нужно). null при пустом
///списке. Семантика совпадает с головой rank().
/datum/target_scorer/proc/select(datum/ai_controller/controller, list/candidates, atom/current_target)
	if(!length(candidates))
		return null
	if(length(candidates) == 1)
		return candidates[1]

	var/mob/living/pawn = controller.pawn
	var/list/scores = list()
	var/atom/best
	var/best_score
	var/best_dist
	for(var/atom/candidate as anything in candidates)
		var/candidate_dist = get_dist(pawn, candidate)
		var/candidate_score = score(controller, candidate, current_target, candidate_dist)
		scores[candidate] = candidate_score
		if(isnull(best) \
			|| candidate_score > best_score \
			|| (candidate_score == best_score && candidate_dist < best_dist))
			best = candidate
			best_score = candidate_score
			best_dist = candidate_dist

	//гистерезис: текущая цель держится, пока не проигрывает лидеру ощутимо
	if(current_target && (current_target in scores) && scores[current_target] >= best_score - TARGET_SCORE_STICKINESS)
		return current_target

	//свежий выбор: непредсказуемость только среди почти равных лидеров
	if(isnull(current_target))
		var/list/near_best = list()
		for(var/atom/candidate as anything in scores)
			if(scores[candidate] >= best_score - TARGET_SCORE_PICK_GAP)
				near_best += candidate
		if(length(near_best) > 1)
			return pick(near_best)
	return best

#undef TARGET_ORDERING

///Падальщик: предпочитает беспомощные цели
/datum/target_scorer/prefer_vulnerable
	prefer_vulnerable = TRUE

#undef TARGET_SCORE_PICK_GAP
#undef TARGET_SCORE_STICKINESS
#undef TARGET_SCORE_VULNERABLE_BONUS
#undef TARGET_SCORE_FRUSTRATION_PENALTY
#undef TARGET_SCORE_DISTANCE_PENALTY
#undef TARGET_SCORE_CONTACT_BONUS
#undef TARGET_SCORE_GRUDGE_BONUS
#undef TARGET_SCORE_CURRENT_BONUS
