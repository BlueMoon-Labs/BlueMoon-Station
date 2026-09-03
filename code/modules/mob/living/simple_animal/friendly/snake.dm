/mob/living/simple_animal/hostile/retaliate/poison
	var/poison_per_bite = 0
	var/poison_type = /datum/reagent/toxin

/mob/living/simple_animal/hostile/retaliate/poison/AttackingTarget()
	. = ..()
	if(. && isliving(target))
		var/mob/living/L = target
		if(L.reagents && !poison_per_bite == 0)
			L.reagents.add_reagent(poison_type, poison_per_bite)
	return

/mob/living/simple_animal/hostile/retaliate/poison/snake
	name = "snake"
	desc = "A slithery snake. These legless reptiles are the bane of mice and adventurers alike."
	icon_state = "snake"
	icon_living = "snake"
	icon_dead = "snake_dead"
	speak_emote = list("hisses")
	health = 20
	maxHealth = 20
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	melee_damage_lower = 5
	melee_damage_upper = 6
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "shoos"
	response_disarm_simple = "shoo"
	response_harm_continuous = "steps on"
	response_harm_simple = "step on"
	faction = list("hostile")
	density = FALSE
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_SMALL
	mob_biotypes = MOB_ORGANIC|MOB_BEAST|MOB_REPTILE
	gold_core_spawnable = FRIENDLY_SPAWN
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE

/mob/living/simple_animal/hostile/retaliate/poison/snake/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)


/mob/living/simple_animal/hostile/retaliate/poison/snake/AttackingTarget()
	if(istype(target, /mob/living/simple_animal/mouse))
		visible_message("<span class='notice'>[name] consumes [target] in a single gulp!</span>", "<span class='notice'>You consume [target] in a single gulp!</span>")
		QDEL_NULL(target)
		adjustBruteLoss(-2)
	else
		return ..()

// ===== Адаптер-профиль =====
// Легаси ListTargets змеи (выше) сначала выбирал мышей и лишь при их
// отсутствии применял retaliate-гейт. Новый путь раскладывает это на
// стратегию small_prey (мыши - цели без обид) и скорер small_prey_first
// (видимая мышь важнее любого обидчика). Съедание мыши остаётся в
// AttackingTarget через делегацию.

///Бонус мыши: перевешивает обиду (+40) и липкость текущей цели (+25) вместе
#define TARGET_SCORE_SMALL_PREY_BONUS 100

///Скорер змеи: мышь важнее всего остального, как в легаси ListTargets
/datum/target_scorer/small_prey_first

/datum/target_scorer/small_prey_first/score(datum/ai_controller/controller, atom/candidate, atom/current_target, candidate_distance)
	. = ..()
	if(istype(candidate, /mob/living/simple_animal/mouse))
		. += TARGET_SCORE_SMALL_PREY_BONUS

#undef TARGET_SCORE_SMALL_PREY_BONUS

///Профиль змеи: обычный мили-охотник со стратегией мелкой добычи
/datum/ai_controller/hostile_adapter/melee_chaser/snake/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy/retaliate/small_prey
	blackboard[BB_AI_TARGET_SCORER] = /datum/target_scorer/small_prey_first
