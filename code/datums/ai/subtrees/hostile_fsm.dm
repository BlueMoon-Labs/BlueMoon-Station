// FSM hostile-профилей:
// IDLE -> ALERT -> ENGAGE -> SEARCH -> RETREAT/GUARD -> IDLE.
// Сабтри ставится в план ПОСЛЕ find_potential_targets и ПЕРЕД боевыми:
// бой планируют последующие сабтри (state = ENGAGE, планирование
// продолжается), а ALERT/SEARCH/RETREAT/GUARD ставят свои поведения и
// обрывают план. Поиск потерянной цели идёт к последней ПОДТВЕРЖДЁННОЙ
// точке БЕЗ волхака: живой атом при потере LOS разжалован в контакт ещё
// в find_potential_targets, и реакквизиция возможна только через его LOS-гейт.

/datum/ai_planning_subtree/hostile_fsm

///Сменить состояние с отметкой времени входа
/datum/ai_planning_subtree/hostile_fsm/proc/set_state(datum/ai_controller/controller, new_state)
	if(controller.blackboard[BB_AI_STATE] == new_state)
		return
	AI_TRACE(controller, "fsm", "[controller.blackboard[BB_AI_STATE] || "старт"] -> [new_state]")
	controller.blackboard[BB_AI_STATE] = new_state
	controller.blackboard[BB_AI_STATE_ENTERED_AT] = world.time

/datum/ai_planning_subtree/hostile_fsm/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	update_combat_signals(controller)
	var/state = controller.blackboard[BB_AI_STATE] || AI_STATE_IDLE
	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]

	//есть цель - бой; сам бой планируют сабтри дальше по списку
	if(!QDELETED(target))
		var/turf/home_turf = controller.blackboard[BB_AI_HOME_TURF]
		var/guard_leash = controller.blackboard[BB_AI_GUARD_LEASH] || 5
		if(home_turf && (target.z != home_turf.z || get_dist(target, home_turf) > guard_leash))
			controller.clear_engagement_memory()
			set_state(controller, AI_STATE_GUARD)
			if(get_dist(controller.pawn, home_turf) > 0)
				controller.queue_behavior(/datum/ai_behavior/travel_towards, BB_AI_HOME_TURF)
			return SUBTREE_RETURN_FINISH_PLANNING

		//усталость погони: моб перестаёт быть вечным. До этого условия окончания
		//не было вовсе - пока держится LOS, цель не теряется, а на открытой лаве
		//LOS не рвётся никогда (прод 9887: watcher вёл ползущего в крите игрока
		//118 секунд на 26 тайлов и всё это время стрелял).
		if(should_abandon_pursuit(controller))
			var/atom/dropped_target = controller.blackboard[BB_AI_CURRENT_TARGET]
			controller.clear_engagement_memory()
			//бросили - значит бросили: без этой паузы цель, оставшаяся на виду,
			//реакквизится первым же каденсом финдера со свежей точкой отсчёта
			//поводка, и усталость погони не работает вовсе. Урон снимает паузу
			//немедленно (note_attacker) - бой в спину не глохнет.
			controller.blackboard[BB_AI_ROUTE_RETRY_AT] = world.time + AI_PURSUIT_ABANDON_COOLDOWN
			//и не стоять вплотную к брошенному: "сдавшийся" моб в упор к врагу
			//читался сломанным и умирал бесплатно - отходим на несколько тайлов
			if(isliving(dropped_target) && !QDELETED(dropped_target) && get_dist(controller.pawn, dropped_target) <= AI_ABANDON_AVOID_RANGE)
				controller.set_blackboard_key(BB_AI_ABANDON_AVOID, dropped_target)
				controller.blackboard[BB_AI_ABANDON_AVOID_UNTIL] = world.time + AI_PURSUIT_ABANDON_COOLDOWN
			return_to_peace(controller)
			if(plan_abandon_avoid(controller))
				return SUBTREE_RETURN_FINISH_PLANNING
			return plan_patrol_return(controller)

		//отступление: мораль/здоровье с гистерезисом и разворотом при зажиме
		if(should_retreat(controller))
			if(plan_retreat(controller))
				return SUBTREE_RETURN_FINISH_PLANNING
			//зажат в угол: короткий запрет бегства, дерёмся
			set_state(controller, AI_STATE_ENGAGE)
			return

		//читаемая пауза обнаружения: моб замечает жертву прежде чем броситься
		if(state != AI_STATE_ENGAGE && state != AI_STATE_ALERT && should_alert_pause(controller, target, state))
			set_state(controller, AI_STATE_ALERT)
			controller.queue_behavior(/datum/ai_behavior/alert_reaction, BB_AI_CURRENT_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		var/datum/ai_temperament/alert_temperament = controller.get_temperament()
		if(state == AI_STATE_ALERT && world.time < (controller.blackboard[BB_AI_STATE_ENTERED_AT] || 0) + (AI_ALERT_REACTION_TIME * alert_temperament.alert_pause_mult))
			controller.queue_behavior(/datum/ai_behavior/alert_reaction, BB_AI_CURRENT_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING

		set_state(controller, AI_STATE_ENGAGE)
		//осада: маршрут к близкой видимой цели исчерпан (мебель между нами) -
		//мили-моб стоит лицом к цели и бьёт преграду вместо пересборки мёртвого
		//плана движения каждые полсекунды. Дальники продолжают обычный план:
		//их линия/фланг/сближение сами разберутся, а стрелять осада не мешает.
		if(world.time < (controller.blackboard[BB_AI_SIEGE_UNTIL] || 0))
			var/mob/living/simple_animal/hostile/siege_pawn = controller.pawn
			if((!istype(siege_pawn) || !siege_pawn.ranged) && get_dist(controller.pawn, target) > 1)
				return plan_siege(controller, target)
		return

	switch(state)
		if(AI_STATE_ENGAGE) //цель только что потеряна (разжалована в контакт)
			var/turf/last_pos = controller.blackboard[BB_AI_LAST_KNOWN_POS]
			if(last_pos)
				enter_search(controller)
				return plan_search(controller)
			return_to_peace(controller)
			return

		if(AI_STATE_SEARCH)
			if(world.time < (controller.blackboard[BB_AI_SEARCH_UNTIL] || 0))
				return plan_search(controller)
			//не нашли - забываем и возвращаемся к мирной жизни
			controller.clear_engagement_memory()
			return_to_peace(controller)
			return

		if(AI_STATE_GUARD)
			var/turf/home_turf = controller.blackboard[BB_AI_HOME_TURF]
			if(home_turf && get_dist(controller.pawn, home_turf) > (controller.blackboard[BB_AI_GUARD_LEASH] || 5))
				controller.queue_behavior(/datum/ai_behavior/travel_towards, BB_AI_HOME_TURF)
				return SUBTREE_RETURN_FINISH_PLANNING
			return

		else //IDLE/ALERT/RETREAT без цели - к мирной жизни
			return_to_peace(controller)
			if(plan_abandon_avoid(controller))
				return SUBTREE_RETURN_FINISH_PLANNING
			if(controller.blackboard[BB_AI_STATE] == AI_STATE_IDLE)
				return plan_patrol_return(controller)

///Вернуться к мирному состоянию: охрана дома либо покой
/datum/ai_planning_subtree/hostile_fsm/proc/return_to_peace(datum/ai_controller/controller)
	if(controller.blackboard[BB_AI_HOME_TURF])
		set_state(controller, AI_STATE_GUARD)
	else
		set_state(controller, AI_STATE_IDLE)

// ===== БОЕВАЯ АДАПТАЦИЯ =====

///Вывод "здесь опасно", снимаемый раз в планировочный цикл: если за окно
///наблюдения здоровье просело больше чем на AI_DANGER_HEALTH_FRAC, порог
///отступления на время поднимается. Раньше моб реагировал только на АБСОЛЮТНЫЙ
///уровень здоровья и одинаково лез что под кулаки, что под дробовик.
///
///Считается здесь, а не хуком на урон, намеренно: планировочный цикл всё равно
///идёт каждые полсекунды, этого хватает с запасом, а лишних хуков на горячем
///пути получения урона не появляется.
/datum/ai_planning_subtree/hostile_fsm/proc/update_combat_signals(datum/ai_controller/controller)
	var/mob/living/living_pawn = controller.pawn
	if(!isliving(living_pawn) || living_pawn.maxHealth <= 0)
		return
	var/snapshot_at = controller.blackboard[BB_AI_SELF_HEALTH_AT]
	var/snapshot = controller.blackboard[BB_AI_SELF_HEALTH]
	if(isnull(snapshot) || isnull(snapshot_at) || world.time - snapshot_at > AI_DANGER_WINDOW)
		controller.blackboard[BB_AI_SELF_HEALTH] = living_pawn.health
		controller.blackboard[BB_AI_SELF_HEALTH_AT] = world.time
		return
	if((snapshot - living_pawn.health) < living_pawn.maxHealth * AI_DANGER_HEALTH_FRAC)
		return
	controller.blackboard[BB_AI_DANGER_UNTIL] = world.time + AI_DANGER_MEMORY
	controller.blackboard[BB_AI_SELF_HEALTH] = living_pawn.health
	controller.blackboard[BB_AI_SELF_HEALTH_AT] = world.time

// ===== УСТАЛОСТЬ ПОГОНИ =====

///Пора ли бросить погоню. Два независимых условия, и оба нужны:
///
///1. Поводок от точки взятия цели. Ловит именно случай watcher: моб исправно
///   попадает, то есть по обмену уроном погоня "продуктивна", но уводит его
///   через полкарты от собственной территории.
///2. Терпение без единого обмена уроном. Ловит обратный случай: моб бесконечно
///   идёт за целью, которую не может достать.
///
///Сценарные преследователи и боссы отписаны через pursuit_leashed: у них
///погоня и есть содержание боя.
/datum/ai_planning_subtree/hostile_fsm/proc/should_abandon_pursuit(datum/ai_controller/controller)
	if(!controller.pursuit_leashed)
		return FALSE

	//цель, которую доказанно нечем пробить, держать незачем: это третий выход
	//из погони, и он про бесполезность, а не про расстояние или время.
	//Пометка адресная: непробиваемость доказана про КОНКРЕТНУЮ цель, и на
	//нового противника (второго нападающего без брони) не распространяется.
	var/datum/weakref/impervious_ref = controller.blackboard[BB_AI_TARGET_IMPERVIOUS_REF]
	var/atom/impervious_target = impervious_ref?.resolve()
	if(world.time < (controller.blackboard[BB_AI_TARGET_IMPERVIOUS_UNTIL] || 0) \
		&& impervious_target && impervious_target == controller.blackboard[BB_AI_CURRENT_TARGET])
		AI_TRACE(controller, "pursuit", "бросил [controller.blackboard[BB_AI_CURRENT_TARGET]]: непробиваем")
		return TRUE

	//упрямая особь гонится дольше и дальше, робкая - меньше (см. temperament.dm)
	var/datum/ai_temperament/temperament = controller.get_temperament()
	var/turf/origin = controller.blackboard[BB_AI_PURSUIT_ORIGIN]
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(origin && pawn_turf)
		if(pawn_turf.z != origin.z)
			AI_TRACE(controller, "pursuit", "бросил [controller.blackboard[BB_AI_CURRENT_TARGET]]: увели с z поводка")
			return TRUE
		var/leash = (controller.blackboard[BB_AI_PURSUIT_LEASH] || AI_PURSUIT_LEASH) * temperament.pursuit_mult
		if(get_dist(pawn_turf, origin) > leash)
			AI_TRACE(controller, "pursuit", "бросил [controller.blackboard[BB_AI_CURRENT_TARGET]]: поводок [get_dist(pawn_turf, origin)] > [leash]")
			return TRUE

	var/last_exchange = controller.blackboard[BB_AI_LAST_EXCHANGE_AT]
	if(isnull(last_exchange))
		return FALSE
	if((world.time - last_exchange) > (AI_PURSUIT_PATIENCE * temperament.pursuit_mult))
		AI_TRACE(controller, "pursuit", "бросил [controller.blackboard[BB_AI_CURRENT_TARGET]]: [round((world.time - last_exchange) / 10)]с без обмена уроном")
		return TRUE
	return FALSE

// ===== ОСАДА =====

///Осадный план ENGAGE: маршрут исчерпан, но цель на виду в паре шагов. Под
///огнём без укрытия - шаг за укрытие; иначе стоим лицом к цели и бьём преграду
///на прямой, пока осада не протухнет и путь не перепроложится заново.
/datum/ai_planning_subtree/hostile_fsm/proc/plan_siege(datum/ai_controller/controller, atom/target)
	var/mob/living/living_pawn = controller.pawn
	if(world.time < (controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] || 0))
		var/atom/siege_shooter = controller.blackboard[BB_AI_LAST_ATTACKER]
		if(QDELETED(siege_shooter))
			siege_shooter = target
		if(!QDELETED(siege_shooter) && !controller.current_position_covered(siege_shooter))
			var/turf/siege_hiding = controller.best_hiding_tile(siege_shooter)
			if(siege_hiding && siege_hiding != get_turf(living_pawn) \
				&& controller.cover_quality(siege_hiding, siege_shooter) == AI_COVER_FULL)
				controller.queue_behavior(/datum/ai_behavior/hold_covering_position, siege_hiding)
				return SUBTREE_RETURN_FINISH_PLANNING
	if(ai_get_blocked_path_turf(living_pawn, target))
		controller.queue_behavior(/datum/ai_behavior/attack_obstructions, BB_AI_CURRENT_TARGET)
	controller.queue_behavior(/datum/ai_behavior/alert_reaction, BB_AI_CURRENT_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

// ===== ОТХОД ОТ БРОШЕННОЙ ЦЕЛИ =====

///Отход от брошенной бесполезной цели: пока окно живо и враг всё ещё рядом,
///моб отступает, а не стоит вплотную в idle. FALSE - окно закрыто/врага нет.
/datum/ai_planning_subtree/hostile_fsm/proc/plan_abandon_avoid(datum/ai_controller/controller)
	var/atom/avoid_target = controller.blackboard[BB_AI_ABANDON_AVOID]
	if(isnull(avoid_target))
		return FALSE
	if(QDELETED(avoid_target) || world.time >= (controller.blackboard[BB_AI_ABANDON_AVOID_UNTIL] || 0) \
		|| get_dist(controller.pawn, avoid_target) > AI_ABANDON_AVOID_RANGE)
		controller.clear_blackboard_key(BB_AI_ABANDON_AVOID)
		controller.blackboard[BB_AI_ABANDON_AVOID_UNTIL] = null
		return FALSE
	controller.queue_behavior(/datum/ai_behavior/run_away_from_target/retreat, BB_AI_ABANDON_AVOID, BB_AI_TARGET_HIDING_LOCATION)
	return TRUE

// ===== ALERT =====

///Пауза обнаружения уместна только на холодном контакте: нас ещё не бьют,
///мы не под огнём и не знали, что враг рядом (иначе - мгновенный ENGAGE)
/datum/ai_planning_subtree/hostile_fsm/proc/should_alert_pause(datum/ai_controller/controller, atom/target, state)
	if(state != AI_STATE_IDLE && state != AI_STATE_GUARD)
		return FALSE
	if(target == controller.blackboard[BB_AI_LAST_ATTACKER])
		return FALSE
	if(world.time < (controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] || 0))
		return FALSE
	if(controller.has_fresh_contact())
		return FALSE
	return TRUE

// ===== RETREAT =====

///Нужно ли отступать: профильный порог здоровья с гистерезисом выхода
/datum/ai_planning_subtree/hostile_fsm/proc/should_retreat(datum/ai_controller/controller)
	var/retreat_frac = controller.blackboard[BB_AI_RETREAT_HEALTH_FRAC]
	if(!retreat_frac)
		return FALSE
	if(world.time < (controller.blackboard[BB_AI_RETREAT_BACKOFF_UNTIL] || 0))
		return FALSE
	var/mob/living/living_pawn = controller.pawn
	if(!isliving(living_pawn) || living_pawn.maxHealth <= 0)
		return FALSE
	//характер особи и свежий опыт этой стычки: робкий отступает раньше дерзкого,
	//а тот, кого только что быстро разобрали, - раньше себя же вчерашнего
	var/datum/ai_temperament/retreat_temperament = controller.get_temperament()
	retreat_frac *= retreat_temperament.retreat_threshold_mult
	if(world.time < (controller.blackboard[BB_AI_DANGER_UNTIL] || 0))
		retreat_frac *= AI_DANGER_RETREAT_MULT
	retreat_frac = min(retreat_frac, 1)
	var/health_frac = living_pawn.health / living_pawn.maxHealth
	//вошёл в RETREAT ниже порога - выходит только восстановившись с запасом
	if(controller.blackboard[BB_AI_STATE] == AI_STATE_RETREAT)
		return health_frac < min(1, retreat_frac + AI_RETREAT_RECOVER_MARGIN)
	return health_frac < retreat_frac

///Спланировать бегство. FALSE = моб зажат (не сдвинулся несколько планов
///подряд): взводится backoff, вызывающий переводит его в ENGAGE - драться.
/datum/ai_planning_subtree/hostile_fsm/proc/plan_retreat(datum/ai_controller/controller)
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(controller.blackboard[BB_AI_STATE] == AI_STATE_RETREAT && controller.blackboard[BB_AI_RETREAT_LAST_POS] == pawn_turf)
		var/fails = (controller.blackboard[BB_AI_RETREAT_FAILS] || 0) + 1
		controller.blackboard[BB_AI_RETREAT_FAILS] = fails
		if(fails >= AI_RETREAT_CORNERED_FRUSTRATION)
			controller.blackboard[BB_AI_RETREAT_BACKOFF_UNTIL] = world.time + AI_RETREAT_BACKOFF_TIME
			controller.blackboard[BB_AI_RETREAT_FAILS] = 0
			controller.clear_blackboard_key(BB_AI_RETREAT_LAST_POS)
			return FALSE
	else
		controller.set_blackboard_key(BB_AI_RETREAT_LAST_POS, pawn_turf)
		controller.blackboard[BB_AI_RETREAT_FAILS] = 0
	set_state(controller, AI_STATE_RETREAT)
	controller.queue_behavior(/datum/ai_behavior/run_away_from_target/retreat, BB_AI_CURRENT_TARGET, BB_AI_TARGET_HIDING_LOCATION)
	return TRUE

// ===== SEARCH =====

///Вход в SEARCH: таймер, счётчик точек осмотра, окно поджидания для дальников
/datum/ai_planning_subtree/hostile_fsm/proc/enter_search(datum/ai_controller/controller)
	set_state(controller, AI_STATE_SEARCH)
	controller.blackboard[BB_AI_SEARCH_UNTIL] = world.time + (controller.blackboard[BB_AI_SEARCH_TIME] || AI_DEFAULT_SEARCH_TIME)
	controller.blackboard[BB_AI_SEARCH_POINTS_LEFT] = AI_SEARCH_INVESTIGATE_POINTS
	controller.clear_blackboard_key(BB_AI_SEARCH_POINT)
	//экстраполяция побега: жертва не остановилась на точке потери LOS. Первая
	//точка осмотра продлевается вдоль последнего наблюдаемого направления её
	//движения, насколько пускает геометрия, - преследователь заворачивает за
	//угол, а не топчется на месте (плейтест 22.06: "зайдя за угол, они теряют
	//меня крайне легко").
	var/turf/projected = project_escape_point(controller)
	if(projected)
		controller.set_blackboard_key(BB_AI_SEARCH_POINT, projected)
		AI_TRACE(controller, "search", "экстраполяция побега -> ([projected.x],[projected.y],[projected.z])")
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(istype(hostile_pawn) && hostile_pawn.ranged)
		//дальник поджидает ВЕСЬ розыск: хвост "иди осматривать точки" приводил
		//стрелка вплотную к укрытию жертвы, и та выходила из-за мешков в упор к
		//дулу (плейтест 22.06). Пешая разведка - работа мили-мобов; стрелок
		//держит огневую позицию с линией на точку потери, пока розыск не сдастся.
		controller.blackboard[BB_AI_HOLD_UNTIL] = controller.blackboard[BB_AI_SEARCH_UNTIL]

///Продлить точку потери вдоль последнего направления движения цели: шагаем от
///улики, пока пускает проходимость, максимум AI_SEARCH_PURSUIT_PROJECTION тайлов.
///null, если направления нет или первый же шаг упирается в геометрию.
/datum/ai_planning_subtree/hostile_fsm/proc/project_escape_point(datum/ai_controller/controller)
	var/escape_dir = controller.blackboard[BB_AI_LAST_KNOWN_DIR]
	var/turf/evidence = controller.blackboard[BB_AI_LAST_KNOWN_POS]
	if(!escape_dir || !evidence)
		return null
	var/turf/projected = evidence
	for(var/step_count in 1 to AI_SEARCH_PURSUIT_PROJECTION)
		var/turf/next_turf = get_step(projected, escape_dir)
		if(!next_turf || !controller.can_enter_turf(next_turf) || next_turf.is_blocked_turf(source_atom = controller.pawn))
			break
		projected = next_turf
	if(projected == evidence)
		return null
	return projected

///Спланировать текущий шаг SEARCH: дальник сначала держит прикрывающую позицию
///к последней точке, остальные идут к улике и осматривают 2-3 точки вокруг
/datum/ai_planning_subtree/hostile_fsm/proc/plan_search(datum/ai_controller/controller)
	var/turf/evidence = controller.blackboard[BB_AI_LAST_KNOWN_POS]
	if(!evidence)
		controller.clear_engagement_memory()
		return_to_peace(controller)
		return

	//под обстрелом с исчерпанной фрустрацией к улике не ходят: моб, которого
	//расстреливали лазером сквозь стекло, шёл к точке стрелка, утыкался в окно
	//и умирал стоя. Сначала выйти из-под огня - розыск подождёт.
	if(world.time < (controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] || 0) \
		&& (controller.blackboard[BB_AI_FRUSTRATION] || 0) >= AI_PINNED_FRUSTRATION)
		var/atom/search_shooter = controller.blackboard[BB_AI_LAST_ATTACKER]
		if(!QDELETED(search_shooter) && !controller.current_position_covered(search_shooter))
			var/turf/search_hiding = controller.best_hiding_tile(search_shooter)
			if(search_hiding && search_hiding != get_turf(controller.pawn) \
				&& controller.cover_quality(search_hiding, search_shooter) == AI_COVER_FULL)
				controller.queue_behavior(/datum/ai_behavior/hold_covering_position, search_hiding)
				return SUBTREE_RETURN_FINISH_PLANNING

	//поджидание: скрывшаяся цель часто выглядывает обратно - дальник занимает
	//огневую позицию с линией на последнюю точку вместо слепого сближения
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(istype(hostile_pawn) && hostile_pawn.ranged && world.time < (controller.blackboard[BB_AI_HOLD_UNTIL] || 0))
		var/list/threats = controller.get_nearby_threats()
		var/ideal_min = controller.blackboard[BB_AI_MIN_DISTANCE] || 0
		var/ideal_max = controller.blackboard[BB_AI_MAX_DISTANCE] || 0
		var/turf/hold_tile = controller.best_covering_tile(evidence, threats, ideal_min, ideal_max)
		if(hold_tile && hold_tile != get_turf(controller.pawn))
			controller.queue_behavior(/datum/ai_behavior/hold_covering_position, hold_tile)
		return SUBTREE_RETURN_FINISH_PLANNING

	//осмотр: дошли до точки - выбираем следующую вокруг улики, пока есть лимит
	var/turf/waypoint = controller.blackboard[BB_AI_SEARCH_POINT] || evidence
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(pawn_turf && get_dist(pawn_turf, waypoint) <= 1)
		var/points_left = controller.blackboard[BB_AI_SEARCH_POINTS_LEFT]
		if(isnull(points_left))
			points_left = AI_SEARCH_INVESTIGATE_POINTS
		if(points_left <= 0)
			controller.clear_engagement_memory()
			return_to_peace(controller)
			return
		controller.blackboard[BB_AI_SEARCH_POINTS_LEFT] = points_left - 1
		var/turf/next_point = pick_investigation_point(controller, evidence)
		if(next_point)
			controller.set_blackboard_key(BB_AI_SEARCH_POINT, next_point)
		//некуда идти - стоим настороже, таймер SEARCH дотикает сам
		return SUBTREE_RETURN_FINISH_PLANNING

	var/waypoint_key = controller.blackboard[BB_AI_SEARCH_POINT] ? BB_AI_SEARCH_POINT : BB_AI_LAST_KNOWN_POS
	if(ai_get_blocked_path_turf(controller.pawn, waypoint))
		controller.queue_behavior(/datum/ai_behavior/attack_obstructions/search, waypoint_key)
	controller.queue_behavior(/datum/ai_behavior/travel_towards, waypoint_key)
	return SUBTREE_RETURN_FINISH_PLANNING

///Случайная проходимая точка осмотра вокруг улики. Первые попытки смещены в
///переднюю полуплоскость последнего направления побега: смотреть надо туда,
///КУДА жертва бежала, а не за собственную спину; не нашлось - обычный разброс.
/datum/ai_planning_subtree/hostile_fsm/proc/pick_investigation_point(datum/ai_controller/controller, turf/evidence)
	var/escape_dir = controller.blackboard[BB_AI_LAST_KNOWN_DIR]
	for(var/try_count in 1 to 6)
		var/turf/candidate = locate(
			evidence.x + rand(-AI_SEARCH_WANDER_RADIUS, AI_SEARCH_WANDER_RADIUS),
			evidence.y + rand(-AI_SEARCH_WANDER_RADIUS, AI_SEARCH_WANDER_RADIUS),
			evidence.z)
		if(!candidate || candidate == evidence || !isopenturf(candidate))
			continue
		if(escape_dir && try_count <= 3 && !(get_dir(evidence, candidate) & escape_dir))
			continue
		if(!controller.can_enter_turf(candidate) || candidate.is_blocked_turf(source_atom = controller.pawn))
			continue
		return candidate
	return null

// ===== Возврат мирного патруля =====

///Уведённый от якоря моб возвращается домой ШТАТНЫМ мувером (JPS, двери,
///задержки движения), а не сырым Move(). Недостижимый якорь после нескольких
///планов без прогресса переезжает на текущее место - дом не теряется навсегда.
/datum/ai_planning_subtree/hostile_fsm/proc/plan_patrol_return(datum/ai_controller/controller)
	var/turf/anchor = controller.blackboard[BB_AI_PATROL_ANCHOR]
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(!anchor || !pawn_turf || anchor.z != pawn_turf.z)
		return
	if(get_dist(pawn_turf, anchor) <= AI_PATROL_LEASH)
		controller.blackboard[BB_AI_PATROL_RETURN_FAILS] = 0
		controller.clear_blackboard_key(BB_AI_PATROL_RETURN_FROM)
		return
	if(controller.blackboard[BB_AI_PATROL_RETURN_FROM] == pawn_turf)
		var/fails = (controller.blackboard[BB_AI_PATROL_RETURN_FAILS] || 0) + 1
		controller.blackboard[BB_AI_PATROL_RETURN_FAILS] = fails
		if(fails >= AI_PATROL_RETURN_GIVE_UP)
			controller.set_blackboard_key(BB_AI_PATROL_ANCHOR, pawn_turf)
			controller.blackboard[BB_AI_PATROL_RETURN_FAILS] = 0
			controller.clear_blackboard_key(BB_AI_PATROL_RETURN_FROM)
			return
	else
		controller.set_blackboard_key(BB_AI_PATROL_RETURN_FROM, pawn_turf)
		controller.blackboard[BB_AI_PATROL_RETURN_FAILS] = 0
	controller.queue_behavior(/datum/ai_behavior/travel_towards/patrol_return, BB_AI_PATROL_ANCHOR)
	return SUBTREE_RETURN_FINISH_PLANNING

// ===== Поведения FSM =====

///Читаемая реакция обнаружения: развернуться к цели, собраться перед атакой
/datum/ai_behavior/alert_reaction
	action_cooldown = 0.4 SECONDS
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/alert_reaction/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/living_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!isliving(living_pawn) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	living_pawn.setDir(get_dir(living_pawn, target))
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Отступление FSM: провал бегства не должен стирать цель - решение о
///развороте принимает plan_retreat() по отсутствию прогресса
/datum/ai_behavior/run_away_from_target/retreat
	clear_failed_targets = FALSE
