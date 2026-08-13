#define GOOSE_SATIATED 50
///Легаси-каденс ярости: prob(5) на 2-секундный тик NPC-пула = 2.5%/с планировщика
#define GOOSE_RAGE_PROB_PER_SECOND 2.5

/mob/living/simple_animal/hostile/retaliate/goose
	name = "goose"
	desc = "It's loose"
	icon_state = "goose" // sprites by cogwerks from goonstation, used with permission
	icon_living = "goose"
	icon_dead = "goose_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak_chance = 0
	turns_per_move = 5
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 2)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	emote_taunt = list("hisses")
	taunt_chance = 30
	speed = 0
	maxHealth = 25
	health = 25
	harm_intent_damage = 5
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_verb_continuous = "pecks"
	attack_verb_simple = "peck"
	attack_sound = "goose"
	speak_emote = list("honks")
	faction = list("neutral")
	attack_same = TRUE
	gold_core_spawnable = HOSTILE_SPAWN
	var/random_retaliate = TRUE

// ===== Адаптер-профиль =====
// Retaliate-семейство целиком закрывает базовая стратегия (enemies-гейт из
// setup_from_pawn); единственная особость гуся - случайный запуск Retaliate()
// из движения ("гусь на взводе"). Звуки и эмоуты агра не трогаем: их играет
// легаси Aggro() при зеркалировании цели в pawn.target.

///Профиль гуся: обычный мили-ретал + случайная ярость
/datum/ai_controller/hostile_adapter/melee_chaser/goose
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/goose_random_rage,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/hostile_dodge,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

///Случайная ярость: как в легаси, ролл не гейтится наличием цели - уже
///разъярённый гусь продолжает набирать обидчиков (сам Retaliate() и так
///троттлит групповой скан пятисекундным кулдауном)
/datum/ai_planning_subtree/goose_random_rage

/datum/ai_planning_subtree/goose_random_rage/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/goose/angry_bird = controller.pawn
	if(!istype(angry_bird) || !angry_bird.random_retaliate)
		return
	if(!SPT_PROB(GOOSE_RAGE_PROB_PER_SECOND, delta_time))
		return
	controller.queue_behavior(/datum/ai_behavior/goose_random_rage)

///Взбеситься: записать видимых соседей в обиды штатным Retaliate() -
///дальше цель берёт обычный retaliate-поиск по машине обид
/datum/ai_behavior/goose_random_rage
	action_cooldown = 2 SECONDS

/datum/ai_behavior/goose_random_rage/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/retaliate/goose/angry_bird = controller.pawn
	if(!istype(angry_bird))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	angry_bird.Retaliate()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

#undef GOOSE_RAGE_PROB_PER_SECOND
