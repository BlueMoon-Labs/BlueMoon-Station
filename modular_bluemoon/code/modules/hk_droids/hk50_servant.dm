#define HK50_SERVANT_MARK_SCORE 1000
#define HK50_SERVANT_ORDERS_HELP "Укажите жестом (Point) на цель в боевом интенте (harm) - пара займётся ею; жест на себя или на слугу отменяет приказ. Без приказа слуги держатся рядом, бьют только тех, кто нападает на вас или на них, и догоняют вас на двигателях, если вы ушли на другой уровень, - но не на ЦК и не на шаттл в полёте."

GLOBAL_LIST_EMPTY(hk50_servant_components)

/// Вызвать пару HK-50 на службу хозяину; null, если у него уже есть живые слуги.
/proc/hk50_summon_servant_pair(mob/living/master, turf/drop_turf)
	if(!istype(master) || master.stat == DEAD || !drop_turf || length(hk50_servants_of(master)))
		return null
	var/list/pair = list()
	var/list/spots = hk50_servant_spots(drop_turf, master)
	for(var/i in 1 to HK50_SERVANT_PAIR_SIZE)
		var/mob/living/simple_animal/hostile/hk50/servant = new(i <= length(spots) ? spots[i] : drop_turf)
		servant.AddComponent(/datum/component/hk50_servant, master)
		pair += servant
	do_sparks(3, FALSE, drop_turf)
	var/mob/living/simple_animal/hostile/hk50/lead = pair[1]
	lead.hk50_say("Подкрепление прибыло. Укажите мешок с мясом, хозяин.", forced = TRUE)
	to_chat(master, span_notice("Пара HK-50 прибыла и прослужит [DisplayTimeText(HK50_SERVANT_LIFETIME)]. [HK50_SERVANT_ORDERS_HELP]"))
	return pair

/// Свободные клетки у места посадки, ближние к хозяину первыми; клетку хозяина слуги не занимают.
/proc/hk50_servant_spots(turf/center, mob/living/master)
	var/turf/master_turf = get_turf(master)
	var/list/near = list()
	var/list/far = list()
	for(var/turf/open/spot in shuffle(RANGE_TURFS(1, center)))
		if(spot == master_turf || spot.is_blocked_turf() || !center.Adjacent(spot))
			continue
		if(master_turf && get_dist(spot, master_turf) <= 1)
			near += spot
		else
			far += spot
	return near + far

/// Живые слуги HK-50 этого хозяина.
/proc/hk50_servants_of(mob/living/master)
	. = list()
	if(isnull(master))
		return
	for(var/datum/component/hk50_servant/servitude as anything in GLOB.hk50_servant_components)
		var/mob/living/servant = servitude.parent
		if(servant.stat != DEAD && servitude.master_ref?.resolve() == master)
			. += servant

/// HK-50 на службе: охраняет хозяина, бьёт указанную им цель и обидчиков, по сроку или без хозяина самоуничтожается.
/datum/component/hk50_servant
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/master_ref
	var/datum/weakref/marked_ref
	/// WEAKREF(обидчик) -> TRUE: напавшие на хозяина или на слугу
	var/list/hostile_refs
	var/lifetime_timer
	var/countdown_timer
	var/countdown_left = 0
	var/destructing = FALSE
	var/catch_up_timer

/datum/component/hk50_servant/Initialize(mob/living/master, lifetime = HK50_SERVANT_LIFETIME)
	if(!istype(parent, /mob/living/simple_animal/hostile/hk50) || !istype(master) || QDELETED(master))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/simple_animal/hostile/hk50/servant = parent
	master_ref = WEAKREF(master)
	servant.faction = list(FACTION_HK_DROIDS, "[REF(master)]", "[REF(servant)]")
	if(master.mind)
		servant.AddComponent(/datum/component/hk_loyalty, master.mind)
	var/datum/antagonist/hk47/hunter = master.mind?.has_antag_datum(/datum/antagonist/hk47)
	if(hunter)
		servant.AddComponent(/datum/component/hk_side_hits, hunter)
	if(servant.ai_controller)
		var/datum/ai_controller/controller = new /datum/ai_controller/hostile_adapter/ranged_skirmisher/hk50_servant(servant)
		controller.set_blackboard_key(BB_HK50_MASTER, master)
	RegisterSignal(master, COMSIG_LIVING_ATTACKER_SET, PROC_REF(on_attacked))
	RegisterSignal(master, COMSIG_LIVING_HIT_BY_PROJECTILE, PROC_REF(on_master_shot))
	RegisterSignal(master, COMSIG_MOB_POINTED, PROC_REF(on_master_pointed))
	RegisterSignal(master, list(COMSIG_LIVING_DEATH, COMSIG_HK_MASTER_CHANGED), PROC_REF(on_master_lost))
	RegisterSignal(master, COMSIG_PARENT_QDELETING, PROC_REF(on_master_deleted))
	RegisterSignal(master, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_master_changed_level))
	lifetime_timer = addtimer(CALLBACK(src, PROC_REF(expire)), lifetime, TIMER_STOPPABLE)
	GLOB.hk50_servant_components += src

/datum/component/hk50_servant/RegisterWithParent()
	parent.AddElement(/datum/element/relay_attackers)
	RegisterSignal(parent, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_attacked))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/hk50_servant/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ATOM_WAS_ATTACKED, COMSIG_PARENT_EXAMINE))

/datum/component/hk50_servant/Destroy(force, silent)
	GLOB.hk50_servant_components -= src
	release_master()
	deltimer(lifetime_timer)
	deltimer(countdown_timer)
	deltimer(catch_up_timer)
	return ..()

/datum/component/hk50_servant/proc/release_master()
	var/mob/living/master = master_ref?.resolve()
	if(master)
		UnregisterSignal(master, list(COMSIG_LIVING_ATTACKER_SET, COMSIG_LIVING_HIT_BY_PROJECTILE, COMSIG_MOB_POINTED, COMSIG_LIVING_DEATH, COMSIG_HK_MASTER_CHANGED, COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_Z_CHANGED))

/// Можно ли слуге атаковать цель: только указанную хозяином и обидчиков, хозяина и его технику - никогда.
/datum/component/hk50_servant/proc/allows_target(atom/target)
	var/mob/living/master = master_ref?.resolve()
	if(isnull(master) || destructing || isnull(target) || target == master || target == parent)
		return FALSE
	var/obj/vehicle/vehicle = target
	if(istype(vehicle))
		if(vehicle.is_occupant(master))
			return FALSE
		for(var/mob/occupant as anything in vehicle.occupants)
			if(is_ordered(occupant))
				return TRUE
	else if(istype(target.loc, /obj/vehicle) && is_ordered(target.loc))
		return TRUE
	return is_ordered(target)

/datum/component/hk50_servant/proc/is_ordered(atom/target)
	if(target == marked_ref?.resolve())
		return TRUE
	return !isnull(target.weak_reference) && LAZYACCESS(hostile_refs, target.weak_reference)

/// Запомнить обидчика; FALSE - его трогать нельзя (хозяин, свой, слуга уже на отсчёте).
/datum/component/hk50_servant/proc/record_hostile(atom/movable/attacker)
	var/mob/living/master = master_ref?.resolve()
	if(QDELETED(attacker) || destructing || isnull(master) || attacker == master || attacker == parent)
		return FALSE
	var/datum/component/hk50_servant/fellow = attacker.GetComponent(/datum/component/hk50_servant)
	if(fellow?.master_ref?.resolve() == master)
		return FALSE
	LAZYSET(hostile_refs, WEAKREF(attacker), TRUE)
	return TRUE

/// Слуга занят приказом, пока указанная цель досягаема.
/datum/component/hk50_servant/proc/busy_with_order(atom/attacker)
	var/atom/marked = marked_ref?.resolve()
	if(isnull(marked) || marked == attacker)
		return FALSE
	var/mob/living/simple_animal/hostile/hk50/servant = parent
	return servant.CanAttack(marked)

/datum/component/hk50_servant/proc/is_lead()
	var/list/servants = hk50_servants_of(master_ref?.resolve())
	return !length(servants) || servants[1] == parent

/datum/component/hk50_servant/proc/on_attacked(datum/source, atom/movable/attacker)
	SIGNAL_HANDLER
	var/mob/living/simple_animal/hostile/hk50/servant = parent
	servant.RetaliateAgainst(attacker)

/datum/component/hk50_servant/proc/on_master_shot(mob/living/source, obj/item/projectile/projectile, def_zone)
	SIGNAL_HANDLER
	if(projectile.firer)
		on_attacked(source, projectile.firer)

/datum/component/hk50_servant/proc/on_master_pointed(mob/living/source, atom/pointed)
	SIGNAL_HANDLER
	if(destructing)
		return
	if(pointed == source || is_fellow(pointed))
		cancel_order()
		return
	if(source.a_intent != INTENT_HARM || !can_mark(pointed))
		return
	marked_ref = WEAKREF(pointed)
	var/mob/living/simple_animal/hostile/hk50/servant = parent
	var/datum/ai_controller/controller = servant.ai_controller
	if(controller)
		controller.blackboard[BB_AI_TARGET_REFRESH_AT] = 0
		controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
		controller.modify_cooldown(GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets), world.time)
		if(controller.ai_status != AI_STATUS_ON)
			controller.set_ai_status(controller.get_expected_ai_status())
	if(is_lead())
		servant.hk50_say("Цель принята, хозяин. Мешок с мясом будет устранён.")

/datum/component/hk50_servant/proc/can_mark(atom/pointed)
	var/mob/living/master = master_ref?.resolve()
	if(pointed == master || pointed == parent)
		return FALSE
	var/obj/vehicle/vehicle = pointed
	if(istype(vehicle))
		return !vehicle.is_occupant(master)
	var/mob/living/living_target = pointed
	if(!istype(living_target) || living_target.stat == DEAD)
		return FALSE
	return !is_fellow(living_target)

/datum/component/hk50_servant/proc/is_fellow(datum/candidate)
	var/datum/component/hk50_servant/fellow = candidate?.GetComponent(/datum/component/hk50_servant)
	return !isnull(fellow) && fellow.master_ref?.resolve() == master_ref?.resolve()

/// Снять приказ: указанная цель снова неприкосновенна, если сама не нападала.
/datum/component/hk50_servant/proc/cancel_order()
	var/atom/marked = marked_ref?.resolve()
	marked_ref = null
	if(isnull(marked))
		return
	var/mob/living/simple_animal/hostile/hk50/servant = parent
	if(servant.target == marked && !is_ordered(marked))
		servant.LoseTarget()
	if(is_lead())
		servant.hk50_say("Приказ отменён, хозяин.", forced = TRUE)

/datum/component/hk50_servant/proc/on_master_changed_level(mob/living/source, old_z, new_z)
	SIGNAL_HANDLER
	if(destructing || catch_up_timer)
		return
	catch_up_timer = addtimer(CALLBACK(src, PROC_REF(catch_up)), HK50_SERVANT_CATCH_UP_DELAY, TIMER_STOPPABLE)

/// Хозяин так и не вернулся на уровень слуги: слуга прилетает к нему на маневровых двигателях. На ЦК и в резерв (шаттл в полёте, карманные измерения) не летит.
/datum/component/hk50_servant/proc/catch_up()
	catch_up_timer = null
	var/mob/living/simple_animal/hostile/hk50/servant = parent
	var/mob/living/master = master_ref?.resolve()
	var/turf/master_turf = get_turf(master)
	var/turf/servant_turf = get_turf(servant)
	if(destructing || servant.stat == DEAD || !master_turf || !servant_turf || master_turf.z == servant_turf.z)
		return FALSE
	if(is_centcom_level(master_turf.z) || is_reserved_level(master_turf.z))
		return FALSE
	servant.LoseTarget()
	do_sparks(3, FALSE, servant)
	servant.visible_message(span_warning("[servant] врубает маневровые двигатели и уносится вслед за хозяином."))
	servant.forceMove(hk47_reinforcement_turf(master))
	do_sparks(3, FALSE, servant)
	playsound(servant, 'sound/effects/podwoosh.ogg', 40, TRUE)
	servant.visible_message(span_warning("[servant] влетает на маневровых двигателях и встаёт рядом с хозяином."))
	return TRUE

/datum/component/hk50_servant/proc/on_master_lost(datum/source)
	SIGNAL_HANDLER
	start_self_destruct("Хозяин потерян. Запускаю самоликвидацию.")

/datum/component/hk50_servant/proc/on_master_deleted(datum/source)
	SIGNAL_HANDLER
	release_master()
	start_self_destruct("Хозяин потерян. Запускаю самоликвидацию.")

/datum/component/hk50_servant/proc/expire()
	lifetime_timer = null
	start_self_destruct("Срок службы истёк. Запускаю самоликвидацию.")

/// Обратный отсчёт писком и миганием, затем искры и гибель без взрыва.
/datum/component/hk50_servant/proc/start_self_destruct(line)
	if(destructing)
		return
	destructing = TRUE
	deltimer(lifetime_timer)
	lifetime_timer = null
	var/mob/living/simple_animal/hostile/hk50/servant = parent
	if(servant.stat == DEAD)
		return
	servant.LoseTarget()
	servant.ai_controller?.PauseAi(HK50_SERVANT_SELF_DESTRUCT_DELAY)
	if(is_lead())
		servant.hk50_say(line, forced = TRUE, voice = "hk50_selfdestruct")
	animate(servant, color = COLOR_RED, time = 0.5 SECONDS, loop = -1)
	animate(color = null, time = 0.5 SECONDS)
	countdown_left = HK50_SERVANT_SELF_DESTRUCT_DELAY / (1 SECONDS)
	countdown_tick()

/datum/component/hk50_servant/proc/countdown_tick()
	countdown_timer = null
	var/mob/living/simple_animal/hostile/hk50/servant = parent
	if(QDELETED(servant) || servant.stat == DEAD)
		return
	if(countdown_left <= 0)
		do_sparks(5, FALSE, servant)
		servant.silent_death = TRUE
		servant.death()
		return
	countdown_left--
	playsound(servant, 'sound/machines/beep.ogg', 50, FALSE)
	countdown_timer = addtimer(CALLBACK(src, PROC_REF(countdown_tick)), 1 SECONDS, TIMER_STOPPABLE)

/datum/component/hk50_servant/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/mob/living/master = master_ref?.resolve()
	if(destructing)
		examine_list += span_warning("Корпус мигает красным и пищит: идёт самоликвидация.")
		return
	if(isnull(master))
		return
	if(user != master)
		examine_list += span_notice("Хозяин: [master.name]. Держится рядом и стреляет только по тем, на кого укажет хозяин или кто нападёт на него или на дроида.")
		return
	examine_list += span_notice("Ваш слуга. [HK50_SERVANT_ORDERS_HELP]")
	examine_list += span_notice("До самоликвидации: [DisplayTimeText(timeleft(lifetime_timer), 1)].")

/mob/living/simple_animal/hostile/hk50/RetaliateAgainst(atom/movable/the_attacker)
	var/datum/component/hk50_servant/servitude = GetComponent(/datum/component/hk50_servant)
	if(servitude && (!servitude.record_hostile(the_attacker) || servitude.busy_with_order(the_attacker)))
		return
	return ..()

/mob/living/simple_animal/hostile/hk50/ranged_fire_turf_state(turf/lane_turf, atom/A, turf/origin_turf, traversal_flags, no_hit_flags, obj/item/projectile/projectile_path, check_obstacles, protect_allies)
	. = ..()
	if(. == AI_FIRE_LANE_BLOCKED || !protect_allies || !lane_turf)
		return
	var/datum/component/hk50_servant/servitude = GetComponent(/datum/component/hk50_servant)
	if(isnull(servitude))
		return
	for(var/mob/living/bystander in lane_turf)
		if(bystander == A || bystander == src || bystander.stat == DEAD || (no_hit_flags & bystander.pass_flags_self))
			continue
		if(!servitude.allows_target(bystander))
			return AI_FIRE_LANE_BLOCKED

/// Стрелок-слуга: без цели держится у хозяина и не бродит сам.
/datum/ai_controller/hostile_adapter/ranged_skirmisher/hk50_servant
	blackboard = list(BB_AI_TARGET_SCORER = /datum/target_scorer/hk50_servant)
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hk50_follow_master,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_break_away,
	)
	idle_behavior = null
	can_idle = FALSE

/datum/ai_planning_subtree/hk50_follow_master

/datum/ai_planning_subtree/hk50_follow_master/SelectBehaviors(datum/ai_controller/controller, delta_time)
	if(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	var/mob/living/master = controller.blackboard[BB_HK50_MASTER]
	var/turf/master_turf = get_turf(master)
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(master_turf && pawn_turf && master_turf.z == pawn_turf.z && get_dist(pawn_turf, master_turf) > HK50_SERVANT_FOLLOW_DISTANCE)
		controller.queue_behavior(/datum/ai_behavior/travel_towards/hk50_master, BB_HK50_MASTER)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/travel_towards/hk50_master
	required_distance = HK50_SERVANT_FOLLOW_DISTANCE

/// Указанная хозяином цель важнее любой другой.
/datum/target_scorer/hk50_servant

/datum/target_scorer/hk50_servant/score(datum/ai_controller/controller, atom/candidate, atom/current_target, candidate_distance)
	. = ..()
	var/datum/component/hk50_servant/servitude = controller.pawn.GetComponent(/datum/component/hk50_servant)
	if(servitude && candidate == servitude.marked_ref?.resolve())
		. += HK50_SERVANT_MARK_SCORE

#undef HK50_SERVANT_MARK_SCORE
#undef HK50_SERVANT_ORDERS_HELP
