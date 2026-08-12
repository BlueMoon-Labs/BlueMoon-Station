// Профиль AI terror spiders.
//
// Легаси-цепочка приоритетов из handle_automated_movement (terror_ai.dm:104)
// декомпозирована в сабтри в том же порядке: вент-путь -> свет -> паутина ->
// венткраул -> классовый special. Каждый шаг гейтится теми же переменными
// каденса (last_break_light/freq_break_light и т.д.), так что возврат моба
// игроку и обратно сохраняет тайминги. Классовые особенности (гнездо
// королевы, массовая паутина люркера, яйца нурса) идут через passthrough
// spider_special_action() - их код не менялся.

/datum/ai_controller/hostile_adapter/terror_spider
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/chokepoint_ambush,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/terror_vent_path,
		/datum/ai_planning_subtree/terror_break_lights,
		/datum/ai_planning_subtree/terror_spin_webs,
		/datum/ai_planning_subtree/terror_start_ventcrawl,
		/datum/ai_planning_subtree/terror_special_action,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_melee_when_cornered/adaptive,
	)

/datum/ai_controller/hostile_adapter/terror_spider/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = new_pawn
	if(!istype(spider))
		return AI_CONTROLLER_INCOMPATIBLE
	//терроры агрессивны: retaliate-гейт родителя не для них (их легаси
	//ListTargets не фильтровал по enemies), приоритеты целей - скорером
	blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy
	blackboard[BB_AI_TARGET_SCORER] = /datum/target_scorer/terror_spider
	switch(spider.spider_opens_doors)
		if(2)
			blackboard[BB_AI_OBSTACLE_POLICY] = /datum/obstacle_policy/forceful
		if(1)
			blackboard[BB_AI_OBSTACLE_POLICY] = /datum/obstacle_policy
		else
			blackboard[BB_AI_OBSTACLE_POLICY] = /datum/obstacle_policy/breacher

///Скорер терроров: жертвы с яйцами/токсином не интересны (легаси-бакеты
///ai_target_method воспроизведены штрафом, а не жёсткой фильтрацией)
/datum/target_scorer/terror_spider

/datum/target_scorer/terror_spider/score(datum/ai_controller/controller, atom/candidate, atom/current_target)
	. = ..()
	if(!iscarbon(candidate))
		return
	var/mob/living/carbon/carbon_candidate = candidate
	if(locate(/obj/item/organ/body_egg/terror_eggs) in carbon_candidate.internal_organs)
		. -= 40
	else if(carbon_candidate.reagents?.has_reagent(/datum/reagent/terror_black_toxin))
		. -= 25

// ===== Сабтри легаси-цепочки =====

///База спайдер-сабтри: только без цели и только на пауне-терроре
/datum/ai_planning_subtree/terror_action

/datum/ai_planning_subtree/terror_action/proc/get_idle_spider(datum/ai_controller/controller)
	if(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return null
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = controller.pawn
	if(!istype(spider))
		return null
	return spider

///Довести начатый вент-путь до конца (path_to_vent/entry_vent - легаси-вары)
/datum/ai_planning_subtree/terror_vent_path
	parent_type = /datum/ai_planning_subtree/terror_action

/datum/ai_planning_subtree/terror_vent_path/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = get_idle_spider(controller)
	if(!spider || !spider.path_to_vent)
		return
	if(QDELETED(spider.entry_vent))
		spider.path_to_vent = 0
		spider.entry_vent = null
		return
	controller.queue_behavior(/datum/ai_behavior/terror_vent_crawl)
	return SUBTREE_RETURN_FINISH_PLANNING

///Разбить лампу рядом (каденс freq_break_light)
/datum/ai_planning_subtree/terror_break_lights
	parent_type = /datum/ai_planning_subtree/terror_action

/datum/ai_planning_subtree/terror_break_lights/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = get_idle_spider(controller)
	if(!spider || !spider.ai_break_lights)
		return
	if(world.time <= spider.last_break_light + spider.freq_break_light)
		return
	controller.queue_behavior(/datum/ai_behavior/terror_break_light)

///Сплести паутину на своём турфе (каденс freq_spins_webs)
/datum/ai_planning_subtree/terror_spin_webs
	parent_type = /datum/ai_planning_subtree/terror_action

/datum/ai_planning_subtree/terror_spin_webs/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = get_idle_spider(controller)
	if(!spider || !spider.ai_spins_webs || !spider.web_type)
		return
	if(world.time <= spider.last_spins_webs + spider.freq_spins_webs)
		return
	controller.queue_behavior(/datum/ai_behavior/terror_spin_web)

///Решить уйти в вентиляцию (каденс idle/combat по смертям улья)
/datum/ai_planning_subtree/terror_start_ventcrawl
	parent_type = /datum/ai_planning_subtree/terror_action

/datum/ai_planning_subtree/terror_start_ventcrawl/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = get_idle_spider(controller)
	if(!spider || !spider.ai_ventcrawls)
		return
	var/my_ventcrawl_freq = spider.freq_ventcrawl_idle
	if(GLOB.ts_count_dead > 0 && world.time < (GLOB.ts_death_last + GLOB.ts_death_window))
		my_ventcrawl_freq = spider.freq_ventcrawl_combat
	if(world.time <= spider.last_ventcrawl_time + my_ventcrawl_freq)
		return
	if(!prob(spider.idle_ventcrawl_chance))
		spider.last_ventcrawl_time = world.time //легаси: неудачный ролл тоже сдвигал каденс
		return
	controller.queue_behavior(/datum/ai_behavior/terror_pick_vent)

///Классовый special (гнездо королевы, яйца нурса, массовая паутина люркера...)
/datum/ai_planning_subtree/terror_special_action
	parent_type = /datum/ai_planning_subtree/terror_action

/datum/ai_planning_subtree/terror_special_action/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = get_idle_spider(controller)
	if(!spider)
		return
	controller.queue_behavior(/datum/ai_behavior/terror_special_action)

// ===== Поведения =====

///Идти к выбранному венту и нырнуть (TSVentCrawlRandom - легаси-траверс с
///случайным выходом и взломом заваренных крышек у ai_ventbreaker)
/datum/ai_behavior/terror_vent_crawl
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 1
	action_cooldown = 1 SECONDS

/datum/ai_behavior/terror_vent_crawl/setup(datum/ai_controller/controller, ...)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = controller.pawn
	if(QDELETED(spider.entry_vent))
		return FALSE
	set_movement_target(controller, spider.entry_vent)

/datum/ai_behavior/terror_vent_crawl/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = controller.pawn
	var/obj/machinery/atmospherics/components/unary/vent_pump/target_vent = spider.entry_vent
	if(QDELETED(target_vent))
		spider.path_to_vent = 0
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(get_dist(spider, target_vent) > 1)
		return AI_BEHAVIOR_DELAY //ещё идём
	spider.path_to_vent = 0
	spider.spider_steps_taken = 0
	INVOKE_ASYNC(spider, TYPE_PROC_REF(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider, TSVentCrawlRandom), target_vent)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/terror_vent_crawl/finish_action(datum/ai_controller/controller, succeeded)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = controller.pawn
	if(istype(spider) && !succeeded)
		spider.path_to_vent = 0
		spider.entry_vent = null

///Разбить нерабочую лампу в шаге (легаси-последовательность)
/datum/ai_behavior/terror_break_light
	action_cooldown = 2 SECONDS

/datum/ai_behavior/terror_break_light/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = controller.pawn
	spider.last_break_light = world.time
	for(var/obj/machinery/light/lamp in range(1, spider))
		if(lamp.status)
			continue
		step_to(spider, lamp)
		lamp.on = 1
		INVOKE_ASYNC(lamp, TYPE_PROC_REF(/obj/machinery/light, break_light_tube))
		spider.do_attack_animation(lamp)
		spider.visible_message("<span class='danger'>[spider] smashes the [lamp.name].</span>")
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

///Паутина на своём турфе, если её ещё нет
/datum/ai_behavior/terror_spin_web
	action_cooldown = 2 SECONDS

/datum/ai_behavior/terror_spin_web/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = controller.pawn
	spider.last_spins_webs = world.time
	var/obj/structure/spider/terrorweb/existing_web = locate() in get_turf(spider)
	if(existing_web)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	new spider.web_type(spider.loc)
	spider.visible_message("<span class='notice'>[spider] puts up some spider webs.</span>")
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Выбрать ближайший пригодный вент (легаси: view(10), заваренные - только ventbreaker)
/datum/ai_behavior/terror_pick_vent
	action_cooldown = 2 SECONDS

/datum/ai_behavior/terror_pick_vent/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = controller.pawn
	spider.last_ventcrawl_time = world.time
	var/best_distance = 99
	var/obj/machinery/atmospherics/components/unary/vent_pump/chosen_vent
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/vent in view(10, spider))
		if(vent.welded && !spider.ai_ventbreaker)
			continue
		var/vent_distance = get_dist(spider, vent)
		if(vent_distance < best_distance)
			chosen_vent = vent
			best_distance = vent_distance
	if(!chosen_vent)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	spider.entry_vent = chosen_vent
	spider.path_to_vent = 1
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Passthrough классового special (может спать - гнездо королевы с do_after)
/datum/ai_behavior/terror_special_action
	action_cooldown = 2 SECONDS

/datum/ai_behavior/terror_special_action/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = controller.pawn
	INVOKE_ASYNC(spider, TYPE_PROC_REF(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider, spider_special_action))
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
