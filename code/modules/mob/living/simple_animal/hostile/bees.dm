
#define BEE_IDLE_ROAMING		70 //The value of idle at which a bee in a beebox will try to wander
#define BEE_IDLE_GOHOME			0  //The value of idle at which a bee will try to go home
#define BEE_PROB_GOHOME			35 //Probability to go home when idle is below BEE_IDLE_GOHOME
#define BEE_PROB_GOROAM			5 //Probability to go roaming when idle is above BEE_IDLE_ROAMING
#define BEE_TRAY_RECENT_VISIT	200	//How long in deciseconds until a tray can be visited by a bee again
#define BEE_DEFAULT_COLOUR		"#e5e500" //the colour we make the stripes of the bee if our reagent has no colour (or we have no reagent)

#define BEE_POLLINATE_YIELD_CHANCE		33
#define BEE_POLLINATE_PEST_CHANCE		33
#define BEE_POLLINATE_POTENCY_CHANCE	50

/mob/living/simple_animal/hostile/poison/bees
	name = "bee"
	desc = "Buzzy buzzy bee, stingy sti- Ouch!"
	icon_state = ""
	icon_living = ""
	icon = 'icons/mob/bees.dmi'
	gender = FEMALE
	speak_emote = list("buzzes")
	emote_hear = list("buzzes")
	turns_per_move = 0
	melee_damage_lower = 1
	melee_damage_upper = 1
	attack_verb_continuous = "stings"
	attack_verb_simple = "sting"
	response_help_continuous = "shoos"
	response_help_simple = "shoo"
	response_disarm_continuous = "swats away"
	response_disarm_simple = "swat away"
	response_harm_continuous = "squashes"
	response_harm_simple = "squash"
	maxHealth = 10
	health = 10
	spacewalk = TRUE
	faction = list("hostile")
	move_to_delay = 0
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	density = FALSE
	mob_size = MOB_SIZE_TINY
	mob_biotypes = MOB_ORGANIC|MOB_BUG
	movement_type = FLYING
	gold_core_spawnable = HOSTILE_SPAWN
	search_objects = 1 //have to find those plant trays!

	//Spaceborn beings don't get hurt by space
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	del_on_death = 1

	var/datum/reagent/beegent = null //hehe, beegent
	var/obj/structure/beebox/beehome = null
	var/idle = 0
	var/isqueen = FALSE
	var/icon_base = "bee"
	var/static/beehometypecache = typecacheof(/obj/structure/beebox)
	var/static/hydroponicstypecache = typecacheof(/obj/machinery/hydroponics)
	var/held_icon = "" // bees are small and have no held icon (aka the coder doesn't know how to sprite it)

/mob/living/simple_animal/hostile/poison/bees/Initialize(mapload)
	. = ..()
	generate_bee_visuals()
	AddComponent(/datum/component/swarming)

/mob/living/simple_animal/hostile/poison/bees/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/mob_holder, held_icon, escape_on_find = TRUE)

/mob/living/simple_animal/hostile/poison/bees/Destroy()
	if(beehome)
		beehome.bees -= src
		beehome = null
	beegent = null
	return ..()


/mob/living/simple_animal/hostile/poison/bees/death(gibbed)
	if(beehome)
		beehome.bees -= src
		beehome = null
	beegent = null
	..()


/mob/living/simple_animal/hostile/poison/bees/examine(mob/user)
	. = ..()
	if(!beehome)
		. += "<span class='warning'>This bee is homeless!</span>"

/mob/living/simple_animal/hostile/poison/bees/proc/generate_bee_visuals()
	cut_overlays()

	var/col = BEE_DEFAULT_COLOUR
	if(beegent && beegent.color)
		col = beegent.color

	add_overlay("[icon_base]_base")

	var/static/mutable_appearance/greyscale_overlay
	greyscale_overlay = greyscale_overlay || mutable_appearance('icons/mob/bees.dmi')
	greyscale_overlay.icon_state = "[icon_base]_grey"
	greyscale_overlay.color = col
	add_overlay(greyscale_overlay)

	add_overlay("[icon_base]_wings")


//We don't attack beekeepers/people dressed as bees//Todo: bee costume
/mob/living/simple_animal/hostile/poison/bees/CanAttack(atom/the_target)
	. = ..()
	if(!.)
		return FALSE
	if(isliving(the_target))
		var/mob/living/H = the_target
		return !H.bee_friendly()


/mob/living/simple_animal/hostile/poison/bees/AttackingTarget()
 	//Pollinate
	if(istype(target, /obj/machinery/hydroponics))
		var/obj/machinery/hydroponics/Hydro = target
		pollinate(Hydro)
	else if(istype(target, /obj/structure/beebox))
		if(target == beehome)
			var/obj/structure/beebox/BB = target
			forceMove(BB)
			toggle_ai(AI_IDLE)
			target = null
			wanted_objects -= beehometypecache //so we don't attack beeboxes when not going home
		return //no don't attack the goddamm box
	else
		. = ..()
		if(. && beegent && isliving(target))
			var/mob/living/L = target
			if(L.reagents)
				beegent.reaction_mob(L, INJECT)
				L.reagents.add_reagent(beegent.type, rand(1,5))


/mob/living/simple_animal/hostile/poison/bees/proc/assign_reagent(datum/reagent/R)
	if(istype(R))
		beegent = R
		name = "[initial(name)] ([R.name])"
		generate_bee_visuals()


/mob/living/simple_animal/hostile/poison/bees/proc/pollinate(obj/machinery/hydroponics/Hydro)
	if(!istype(Hydro) || !Hydro.myseed || Hydro.dead || Hydro.recent_bee_visit)
		target = null
		return

	target = null //so we pick a new hydro tray on the next target scan, instead of loving the same plant for eternity
	wanted_objects -= hydroponicstypecache //so we only hunt them while they're alive/seeded/not visisted
	Hydro.recent_bee_visit = TRUE
	spawn(BEE_TRAY_RECENT_VISIT)
		if(Hydro)
			Hydro.recent_bee_visit = FALSE

	var/growth = health //Health also means how many bees are in the swarm, roughly.
	//better healthier plants!
	Hydro.adjustHealth(growth*0.5)
	if(prob(BEE_POLLINATE_PEST_CHANCE))
		Hydro.adjustPests(-10)
	if(prob(BEE_POLLINATE_YIELD_CHANCE))
		Hydro.myseed.adjust_yield(1)
		Hydro.yieldmod = 2
	if(prob(BEE_POLLINATE_POTENCY_CHANCE))
		Hydro.myseed.adjust_potency(1)

	if(beehome)
		beehome.bee_resources = min(beehome.bee_resources + growth, 100)


/mob/living/simple_animal/hostile/poison/bees/toxin/Initialize(mapload)
	. = ..()
	var/datum/reagent/R = pick(typesof(/datum/reagent/toxin))
	assign_reagent(GLOB.chemical_reagents_list[R])

/mob/living/simple_animal/hostile/poison/bees/queen
	name = "queen bee"
	desc = "She's the queen of bees, BZZ BZZ!"
	icon_base = "queen"
	isqueen = TRUE


//leave pollination for the peasent bees
/mob/living/simple_animal/hostile/poison/bees/queen/AttackingTarget()
	. = ..()
	if(. && beegent && isliving(target))
		var/mob/living/L = target
		beegent.reaction_mob(L, TOUCH)
		L.reagents.add_reagent(beegent.type, rand(1,5))


//PEASENT BEES
/mob/living/simple_animal/hostile/poison/bees/queen/pollinate()
	return


/mob/living/simple_animal/hostile/poison/bees/proc/reagent_incompatible(mob/living/simple_animal/hostile/poison/bees/B)
	if(!B)
		return FALSE
	if(B.beegent && beegent && B.beegent.type != beegent.type || B.beegent && !beegent || !B.beegent && beegent)
		return TRUE
	return FALSE


/obj/item/queen_bee
	name = "queen bee"
	desc = "She's the queen of bees, BZZ BZZ!"
	icon_state = "queen_item"
	item_state = ""
	icon = 'icons/mob/bees.dmi'
	var/mob/living/simple_animal/hostile/poison/bees/queen/queen


/obj/item/queen_bee/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/S = I
		var/jelly_amount = S.reagents.get_reagent_amount(/datum/reagent/royal_bee_jelly)
		if(jelly_amount)
			if(jelly_amount >= 5)
				S.reagents.remove_reagent(/datum/reagent/royal_bee_jelly, 5)
				var/obj/item/queen_bee/qb = new(user.drop_location())
				qb.queen = new(qb)
				if(queen && queen.beegent)
					qb.queen.assign_reagent(queen.beegent) //Bees use the global singleton instances of reagents, so we don't need to worry about one bee being deleted and her copies losing their reagents.
				user.put_in_active_hand(qb)
				user.visible_message("<span class='notice'>[user] injects [src] with royal bee jelly, causing it to split into two bees, MORE BEES!</span>","<span class ='warning'>You inject [src] with royal bee jelly, causing it to split into two bees, MORE BEES!</span>")
			else
				to_chat(user, "<span class='warning'>You don't have enough royal bee jelly to split a bee in two!</span>")
		else
			var/datum/reagent/R = GLOB.chemical_reagents_list[S.reagents.get_master_reagent_id()]
			if(R && S.reagents.has_reagent(R.type, 5))
				S.reagents.remove_reagent(R.type,5)
				if(R.can_synth)
					queen.assign_reagent(R)
					user.visible_message("<span class='warning'>[user] injects [src]'s genome with [R.name], mutating it's DNA!</span>","<span class='warning'>You inject [src]'s genome with [R.name], mutating it's DNA!</span>")
					name = queen.name
				else
					user.visible_message("<span class='warning'>[user] injects [src]'s genome with [R.name]... but nothing happens.</span>","<span class='warning'>You inject [src]'s genome with [R.name]... but nothing happens.</span>")
			else
				to_chat(user, "<span class='warning'>You don't have enough units of that chemical to modify the bee's DNA!</span>")
	..()


/obj/item/queen_bee/bought/Initialize(mapload)
	. = ..()
	queen = new(src)


/obj/item/queen_bee/Destroy()
	QDEL_NULL(queen)
	return ..()

/mob/living/simple_animal/hostile/poison/bees/short
	desc = "These bees seem unstable and won't survive for long."

/mob/living/simple_animal/hostile/poison/bees/short/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(death)), 50 SECONDS)

/mob/living/simple_animal/hostile/poison/bees/space
	name = "killer space bee"
	desc = "I mean, killer is 'IN' the name..."
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500

// ===== Адаптер-профиль =====
// Легаси-цикл пчелы декомпозирован: грядки идут штатным search_objects-путём
// find_potential_targets (валидность из Found() проверяет стратегия
// hostile_legacy/bee, приоритет работы над жертвами - скорер bee_work_first,
// как легаси Found() лочил грядку до перебора мобов), а улей (счётчик отдыха,
// возврат домой, сон в коробке, вылет, усыновление бездомных) - сабтри
// bee_hive_cycle с каденсом NPC-пула. Вход в улей и опыление - делегацией
// легаси AttackingTarget; укусы обидчиков - штатная машина обид.

///world.time следующего 2-секундного тика цикла улья (легаси-каденс NPC-пула)
#define BB_BEE_NEXT_HIVE_TICK "BB_bee_next_hive_tick"
///Флаг "летим домой" (легаси target = beehome)
#define BB_BEE_GOING_HOME "BB_bee_going_home"
///Работа важнее жертв: бонус перекрывает сумму бонусов обидчика/текущей цели/контакта
#define BEE_WORK_SCORE_BONUS 100

///Профиль пчелы: цикл улья -> поиск целей -> бой
/datum/ai_controller/hostile_adapter/bee
	planning_subtrees = list(
		/datum/ai_planning_subtree/bee_hive_cycle,
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

/datum/ai_controller/hostile_adapter/bee/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy/bee
	blackboard[BB_AI_TARGET_SCORER] = /datum/target_scorer/bee_work_first

///Гейт валидной грядки из легаси Found(): опыляем только живую засеянную и
///непосещённую; королева не опыляет; после удара (LoseSearchObjects) пчела
///временно жалит, а не работает. Всё остальное - делегацией CanAttack
///(bee_friendly-гейт жертв, объекты через wanted_objects).
/datum/targeting_strategy/hostile_legacy/bee

/datum/targeting_strategy/hostile_legacy/bee/can_attack(mob/living/living_mob, atom/target, vision_range)
	if(istype(target, /obj/machinery/hydroponics))
		var/mob/living/simple_animal/hostile/poison/bees/bee = living_mob
		if(!istype(bee) || bee.isqueen || !bee.search_objects)
			return FALSE
		var/obj/machinery/hydroponics/tray = target
		return !isnull(tray.myseed) && !tray.dead && !tray.recent_bee_visit
	return ..()

///Работа важнее жертв: легаси Found() лочил валидную грядку до перебора мобов
/datum/target_scorer/bee_work_first

/datum/target_scorer/bee_work_first/score(datum/ai_controller/controller, atom/candidate, atom/current_target, candidate_distance)
	. = ..()
	if(istype(candidate, /obj/machinery/hydroponics))
		. += BEE_WORK_SCORE_BONUS

///Цикл улья. Стоит ПЕРВЫМ: пчела в коробке не охотится и не бродит вовсе
///(легаси-парность consider_wakeup), а начатый возврат домой не отменяется
///патруль-возвратом FSM.
/datum/ai_planning_subtree/bee_hive_cycle

/datum/ai_planning_subtree/bee_hive_cycle/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/poison/bees/bee = controller.pawn
	if(!istype(bee))
		return
	//дома: отдых. Никакой охоты и брождения; счётчик растёт, изредка вылетаем
	if(bee.beehome && bee.loc == bee.beehome)
		controller.blackboard[BB_BEE_GOING_HOME] = null
		if(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
			controller.clear_blackboard_key(BB_AI_CURRENT_TARGET)
		if(hive_tick_due(controller))
			bee.idle = min(100, ++bee.idle)
			if(!bee.isqueen && bee.idle >= BEE_IDLE_ROAMING && prob(BEE_PROB_GOROAM))
				controller.queue_behavior(/datum/ai_behavior/bee_emerge)
		return SUBTREE_RETURN_FINISH_PLANNING
	//снаружи: между тиками только доигрываем начатый возврат домой
	if(!hive_tick_due(controller))
		if(controller.blackboard[BB_BEE_GOING_HOME])
			return plan_return_home(controller, bee)
		return
	//усыновление: бездомная пчела вступает в совместимый улей рядом (легаси-скан)
	if(!bee.beehome)
		for(var/obj/structure/beebox/BB in view(bee.vision_range, bee))
			if(bee.reagent_incompatible(BB.queen_bee) || BB.bees.len >= BB.get_max_bees())
				continue
			BB.bees |= bee
			bee.beehome = BB
			break // End loop after the first compatible find.
	//the Queen doesn't leave the box on her own, and she CERTAINLY doesn't pollinate
	if(bee.isqueen)
		return
	//поддержка охоты на грядки: легаси Found() держал typecache в wanted_objects,
	//пока рядом есть живая грядка (pollinate его снимает); валидность - в стратегии
	if(bee.search_objects)
		bee.wanted_objects |= bee.hydroponicstypecache
	bee.idle = max(0, --bee.idle)
	if(controller.blackboard[BB_BEE_GOING_HOME])
		return plan_return_home(controller, bee)
	//домой только без добычи (легаси-гейт if(!FindTarget()))
	if(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	if(bee.beehome && bee.idle <= BEE_IDLE_GOHOME && prob(BEE_PROB_GOHOME))
		controller.blackboard[BB_BEE_GOING_HOME] = TRUE
		return plan_return_home(controller, bee)

///Каденс NPC-пула: счётчик отдыха легаси тикал раз в 2 секунды
/datum/ai_planning_subtree/bee_hive_cycle/proc/hive_tick_due(datum/ai_controller/controller)
	if(world.time < (controller.blackboard[BB_BEE_NEXT_HIVE_TICK] || 0))
		return FALSE
	controller.blackboard[BB_BEE_NEXT_HIVE_TICK] = world.time + SSnpcpool.wait
	return TRUE

///Спланировать перелёт домой; жертва/грядка перебивает возврат, как легаси
/datum/ai_planning_subtree/bee_hive_cycle/proc/plan_return_home(datum/ai_controller/controller, mob/living/simple_animal/hostile/poison/bees/bee)
	if(QDELETED(bee.beehome) || controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		controller.blackboard[BB_BEE_GOING_HOME] = null
		return
	controller.queue_behavior(/datum/ai_behavior/bee_return_home)
	return SUBTREE_RETURN_FINISH_PLANNING

///Вылет из улья (легаси toggle_ai(AI_ON) + drop_location)
/datum/ai_behavior/bee_emerge
	action_cooldown = 2 SECONDS

/datum/ai_behavior/bee_emerge/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/poison/bees/bee = controller.pawn
	if(!istype(bee) || QDELETED(bee.beehome) || bee.loc != bee.beehome)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	bee.forceMove(bee.beehome.drop_location())
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Возврат в улей: подлёт вплотную и легаси-вход. AttackingTarget дергает
///toggle_ai(AI_IDLE) -> CancelActions, но это безопасно: повторный
///finish_action идемпотентен, а сам легаси-путь входа не спит.
/datum/ai_behavior/bee_return_home
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 1
	action_cooldown = 1 SECONDS

/datum/ai_behavior/bee_return_home/setup(datum/ai_controller/controller)
	. = ..()
	var/mob/living/simple_animal/hostile/poison/bees/bee = controller.pawn
	if(!istype(bee) || QDELETED(bee.beehome))
		return FALSE
	set_movement_target(controller, bee.beehome)

/datum/ai_behavior/bee_return_home/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/poison/bees/bee = controller.pawn
	if(!istype(bee) || QDELETED(bee.beehome))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(bee.loc == bee.beehome) //уже внутри
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	var/atom/reach_origin = bee.targets_from || bee
	if(!bee.beehome.Adjacent(reach_origin))
		return AI_BEHAVIOR_INSTANT //ещё летим
	bee.ai_enter_home()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/bee_return_home/finish_action(datum/ai_controller/controller, succeeded)
	. = ..()
	controller.blackboard[BB_BEE_GOING_HOME] = null

///Вход контроллерной пчелы в улей: легаси-процедура AttackingTarget (forceMove
///внутрь, снятие цели, чистка wanted_objects) + возврат контроллера из
///легаси-IDLE: сном пчелы в улье управляет штатное окно интересности (клиенты
///рядом), а не легаси-пул consider_wakeup.
/mob/living/simple_animal/hostile/poison/bees/proc/ai_enter_home()
	if(QDELETED(src) || QDELETED(beehome) || stat == DEAD)
		return
	target = beehome
	AttackingTarget()
	if(loc == beehome && ai_controller && ai_controller.ai_status == AI_STATUS_IDLE)
		ai_controller.set_ai_status(ai_controller.get_expected_ai_status())

#undef BEE_WORK_SCORE_BONUS
