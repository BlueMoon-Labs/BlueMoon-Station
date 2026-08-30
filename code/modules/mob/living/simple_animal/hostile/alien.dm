/mob/living/simple_animal/hostile/alien
	name = "alien hunter"
	desc = "Hiss!"
	icon = 'icons/Xeno/castes/hunter.dmi'
	icon_state = "Hunter Walking"
	icon_living = "Hunter Walking"
	icon_dead = "Hunter Dead"
	icon_gib = "syndicate_gib"
	gender = FEMALE
	response_help_continuous = "pokes"
	response_help_simple = "poke"
	response_disarm_continuous = "shoves"
	response_disarm_simple = "shove"
	response_harm_continuous = "hits"
	response_harm_simple = "hit"
	speed = 0
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/xeno = 4,
							/obj/item/stack/sheet/animalhide/xeno = 1)
	maxHealth = 125
	health = 125
	harm_intent_damage = 5
	obj_damage = 60
	melee_damage_lower = 25
	melee_damage_upper = 25
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	gold_core_spawnable = HOSTILE_SPAWN
	speak_emote = list("hisses")
	bubble_icon = "alien"
	a_intent = INTENT_HARM
	attack_sound = 'sound/weapons/bladeslice.ogg'
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	faction = list(ROLE_ALIEN)
	status_flags = CANPUSH
	minbodytemp = 0
	see_in_dark = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	unique_name = 1
	death_sound = 'sound/voice/hiss6.ogg'
	deathmessage = "lets out a waning guttural screech, green blood bubbling from its maw..."

/mob/living/simple_animal/hostile/alien/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/footstep, FOOTSTEP_MOB_CLAW)

/mob/living/simple_animal/hostile/alien/drone
	name = "alien drone"
	icon = 'icons/Xeno/castes/drone.dmi'
	icon_state = "Drone Walking"
	icon_living = "Drone Walking"
	icon_dead = "Drone Dead"
	melee_damage_lower = 15
	melee_damage_upper = 15
	var/plant_cooldown = 30
	var/plants_off = 0

/mob/living/simple_animal/hostile/alien/sentinel
	name = "alien sentinel"
	icon = 'icons/Xeno/castes/sentinel.dmi'
	icon_state = "Sentinel Walking"
	icon_living = "Sentinel Walking"
	icon_dead = "Sentinel Dead"
	health = 150
	maxHealth = 150
	melee_damage_lower = 15
	melee_damage_upper = 15
	ranged = 1
	retreat_distance = 5
	minimum_distance = 5
	projectiletype = /obj/item/projectile/neurotox
	projectilesound = 'sound/weapons/pierce.ogg'

/mob/living/simple_animal/hostile/alien/sentinel/cube
	gold_core_spawnable = NO_SPAWN
	health = 220
	maxHealth = 220
	melee_damage_lower = 20
	melee_damage_upper = 20
	del_on_death = TRUE
	loot = list(/obj/effect/mob_spawn/alien/corpse/humanoid/sentinel)

/mob/living/simple_animal/hostile/alien/queen
	name = "alien queen"
	icon = 'icons/Xeno/castes/queen.dmi'
	icon_state = "Queen Walking"
	icon_living = "Queen Walking"
	icon_dead = "Queen Dead"
	pixel_x = -16
	health = 250
	maxHealth = 250
	melee_damage_lower = 15
	melee_damage_upper = 15
	ranged = 1
	retreat_distance = 5
	minimum_distance = 5
	move_to_delay = 4
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/xeno = 4,
							/obj/item/stack/sheet/animalhide/xeno = 1)
	projectiletype = /obj/item/projectile/neurotox
	projectilesound = 'sound/weapons/pierce.ogg'
	gold_core_spawnable = NO_SPAWN
	status_flags = 0
	unique_name = 0
	var/sterile = 1
	var/plants_off = 0
	var/egg_cooldown = 30
	var/plant_cooldown = 30

/mob/living/simple_animal/hostile/alien/queen/Initialize(mapload)
	. = ..()
	if(prob(1))
		icon_state = "Queen rouny Walking"
		icon_living = "Queen rouny Walking"
		icon_dead = "Queen rouny Dead"
		// if(istype(src, /mob/living/simple_animal/hostile/alien/queen/large))
		// 	health_doll_icon = "Queen rouny Walking"


/mob/living/simple_animal/hostile/alien/proc/SpreadPlants()
	if(!isturf(loc) || isspaceturf(loc))
		return
	if(locate(/obj/structure/alien/weeds/node) in get_turf(src))
		return
	visible_message("<span class='alertalien'>[src] has planted some alien weeds!</span>")
	new /obj/structure/alien/weeds/node(loc)

/mob/living/simple_animal/hostile/alien/proc/LayEggs()
	if(!isturf(loc) || isspaceturf(loc))
		return
	if(locate(/obj/structure/alien/egg) in get_turf(src))
		return
	visible_message("<span class='alertalien'>[src] has laid an egg!</span>")
	new /obj/structure/alien/egg(loc)

/mob/living/simple_animal/hostile/alien/queen/large
	name = "alien empress"
	icon = 'icons/Xeno/castes/queen.dmi'
	icon_state = "Queen Walking"
	icon_living = "Queen Walking"
	icon_dead = "Queen Dead"
	health_doll_icon = "Queen Walking"
	bubble_icon = "alienroyal"
	move_to_delay = 4
	maxHealth = 400
	health = 400
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/xeno = 10,
							/obj/item/stack/sheet/animalhide/xeno = 2)
	mob_size = MOB_SIZE_LARGE
	gold_core_spawnable = NO_SPAWN

/obj/item/projectile/neurotox
	name = "neurotoxin"
	icon_state = "toxin"
	damage = 30

/mob/living/simple_animal/hostile/alien/handle_temperature_damage()
	if(bodytemperature < minbodytemp)
		adjustBruteLoss(2)
	else if(bodytemperature > maxbodytemp)
		adjustBruteLoss(20)


/mob/living/simple_animal/hostile/alien/maid
	name = "lusty xenomorph maid"
	melee_damage_lower = 0
	melee_damage_upper = 0
	a_intent = INTENT_HELP
	friendly_verb_continuous = "caresses"
	friendly_verb_simple = "caress"
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	gold_core_spawnable = HOSTILE_SPAWN
	icon = 'modular_bluemoon/icons/mob/alien_maid_splurt.dmi'
	icon_state = "maid"
	icon_living = "maid"
	icon_dead = "maid_dead"

/mob/living/simple_animal/hostile/alien/maid/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/cleaning)

/mob/living/simple_animal/hostile/alien/maid/AttackingTarget()
	if(ismovable(target))
		if(istype(target, /obj/effect/decal/cleanable))
			visible_message("[src] cleans up \the [target].")
			qdel(target)
			return TRUE
		var/atom/movable/M = target
		SEND_SIGNAL(M, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
		M.clean_blood()
		visible_message("[src] polishes \the [target].")
		return TRUE

// ===== Адаптер-профили улья =====
// Охотник и горничная - обычные милишники (кастомная уборка горничной живёт в
// её AttackingTarget и работает через делегацию), сентинел - авто-скирмишер по
// легаси-флагам ranged/retreat_distance. Особость кластера - "дела улья" дрона
// и королевы: легаси handle_automated_action сажал сорняки и откладывал яйца
// только в AI_IDLE; здесь тот же цикл декомпозирован в сабтри с гейтом
// "нет цели" (образец - терроры) и легаси-каденсом через дедлайны блэкборда.

///Легаси-каденс дел улья: prob(10) на 6-секундный тик idle-пула = ~1.7%/с планировщика
#define ALIEN_HIVE_DUTY_PROB_PER_SECOND 1.7
///Легаси-счётчик plant_cooldown/egg_cooldown: 30 тиков idle-пула (60 ds) = 3 минуты
#define ALIEN_HIVE_DUTY_COOLDOWN (3 MINUTES)

///Дрон: обычный милишник + сорняки в тихую минуту
/datum/ai_controller/hostile_adapter/melee_chaser/alien_drone
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/alien_hive_duties/drone,
		/datum/ai_planning_subtree/hostile_dodge,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

///Королева: кайт-плевки скирмишера + сорняки и кладка яиц
/datum/ai_controller/hostile_adapter/ranged_skirmisher/alien_queen
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/alien_hive_duties/queen,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_break_away,
	)

///База дел улья: помощники гейта "нет цели" и легаси-каденса
/datum/ai_planning_subtree/alien_hive_duties

///Улейные дела только у живого ксена без боевой цели (легаси-гейт AI_IDLE)
/datum/ai_planning_subtree/alien_hive_duties/proc/get_idle_hive_worker(datum/ai_controller/controller)
	if(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return null
	var/mob/living/simple_animal/hostile/alien/xeno = controller.pawn
	if(!istype(xeno) || xeno.stat)
		return null
	return xeno

///Ролл посадки: дедлайн каденса + легаси-вероятность
/datum/ai_planning_subtree/alien_hive_duties/proc/plant_roll_passes(datum/ai_controller/controller, delta_time)
	if(world.time < controller.blackboard[BB_AI_NEXT_PLANT_AT])
		return FALSE
	return SPT_PROB(ALIEN_HIVE_DUTY_PROB_PER_SECOND, delta_time)

///Дрон: только сорняки (легаси plant_cooldown/plants_off)
/datum/ai_planning_subtree/alien_hive_duties/drone/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/alien/drone/worker = get_idle_hive_worker(controller)
	if(!istype(worker) || worker.plants_off)
		return
	if(!plant_roll_passes(controller, delta_time))
		return
	controller.queue_behavior(/datum/ai_behavior/alien_spread_plants)

///Королева: сорняки + яйца (легаси sterile/egg_cooldown); роллы независимы,
///как независимы были два prob(10) одного легаси-тика
/datum/ai_planning_subtree/alien_hive_duties/queen/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/alien/queen/matriarch = get_idle_hive_worker(controller)
	if(!istype(matriarch))
		return
	if(!matriarch.plants_off && plant_roll_passes(controller, delta_time))
		controller.queue_behavior(/datum/ai_behavior/alien_spread_plants)
	if(matriarch.sterile)
		return
	if(world.time < controller.blackboard[BB_AI_NEXT_EGG_AT])
		return
	if(!SPT_PROB(ALIEN_HIVE_DUTY_PROB_PER_SECOND, delta_time))
		return
	controller.queue_behavior(/datum/ai_behavior/alien_lay_eggs)

///Посадка сорняков легаси-процем SpreadPlants (проверки турфа/узла внутри него)
/datum/ai_behavior/alien_spread_plants
	action_cooldown = 2 SECONDS

/datum/ai_behavior/alien_spread_plants/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/alien/xeno = controller.pawn
	if(!istype(xeno))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	//легаси-паритет: каденс взводится по факту ролла, даже если тайл занят
	controller.blackboard[BB_AI_NEXT_PLANT_AT] = world.time + ALIEN_HIVE_DUTY_COOLDOWN
	xeno.SpreadPlants()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Кладка яйца легаси-процем LayEggs (проверки турфа/яйца внутри него)
/datum/ai_behavior/alien_lay_eggs
	action_cooldown = 2 SECONDS

/datum/ai_behavior/alien_lay_eggs/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/alien/queen/matriarch = controller.pawn
	if(!istype(matriarch))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	controller.blackboard[BB_AI_NEXT_EGG_AT] = world.time + ALIEN_HIVE_DUTY_COOLDOWN
	matriarch.LayEggs()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

#undef ALIEN_HIVE_DUTY_PROB_PER_SECOND
#undef ALIEN_HIVE_DUTY_COOLDOWN
