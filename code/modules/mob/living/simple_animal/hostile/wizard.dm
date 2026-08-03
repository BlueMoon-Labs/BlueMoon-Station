/mob/living/simple_animal/hostile/wizard
	name = "Space Wizard"
	desc = "EI NATH?"
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "wizard"
	icon_living = "wizard"
	icon_dead = "wizard_dead"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	speak_chance = 0
	turns_per_move = 3
	speed = 0
	maxHealth = 100
	health = 100
	harm_intent_damage = 5
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_verb_continuous = "punches"
	attack_verb_simple = "punch"
	attack_sound = 'sound/weapons/punch1.ogg'
	a_intent = INTENT_HARM
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	faction = list(ROLE_WIZARD)
	status_flags = CANPUSH

	retreat_distance = 3 //out of fireball range
	minimum_distance = 3
	del_on_death = 1
	loot = list(/obj/effect/mob_spawn/human/corpse/wizard,
				/obj/item/staff)

	var/obj/effect/proc_holder/spell/aimed/fireball/fireball = null
	var/obj/effect/proc_holder/spell/targeted/turf_teleport/blink/blink = null
	var/obj/effect/proc_holder/spell/targeted/projectile/magic_missile/mm = null

	var/next_cast = 0

	footstep_type = FOOTSTEP_MOB_SHOE

/mob/living/simple_animal/hostile/wizard/Initialize(mapload)
	. = ..()
	fireball = new /obj/effect/proc_holder/spell/aimed/fireball
	fireball.clothes_req = NONE
	fireball.mobs_whitelist = null
	fireball.player_lock = FALSE
	AddSpell(fireball)
	var/obj/item/implant/exile/I = new
	I.implant(src, null, TRUE)

	mm = new /obj/effect/proc_holder/spell/targeted/projectile/magic_missile
	mm.clothes_req = NONE
	mm.mobs_whitelist = null
	mm.player_lock = FALSE
	AddSpell(mm)

	blink = new /obj/effect/proc_holder/spell/targeted/turf_teleport/blink
	blink.clothes_req = NONE
	blink.mobs_whitelist = null
	blink.player_lock = FALSE
	blink.outer_tele_radius = 3
	AddSpell(blink)

/mob/living/simple_animal/hostile/wizard/Destroy()
	QDEL_NULL(fireball)
	QDEL_NULL(mm)
	QDEL_NULL(blink)
	return ..()

/mob/living/simple_animal/hostile/wizard/proc/AutomatedCast()
	if(target && next_cast < world.time)
		if((get_dir(src,target) in list(SOUTH,EAST,WEST,NORTH)) && fireball.cast_check(0,src)) //Lined up for fireball
			src.setDir(get_dir(src,target))
			fireball.perform(list(target), user = src)
			next_cast = world.time + 10 //One spell per second
			return .
		if(mm.cast_check(0,src))
			mm.choose_targets(src)
			next_cast = world.time + 10
			return .
		if(blink.cast_check(0,src)) //Spam Blink when you can
			blink.choose_targets(src)
			next_cast = world.time + 10
			return .

// ===== Адаптер-профиль =====
// Кастер-скирмишер: держит дистанцию фаербола (кайт-band из легаси
// retreat_distance/minimum_distance, которые setup_from_pawn для не-ranged
// мобов не читает) и кастует делегатом. Сами заклинания, их приоритет
// "фаербол в линию -> магмиссайл -> блинк" и каденс next_cast живут в легаси
// AutomatedCast - поведение лишь дёргает его, как boss_attack оборачивает
// легаси-атаки боссов. Зажатый вплотную визард огрызается кулаками через
// hostile_break_away (легаси-паритет: MeleeAction, когда цель Adjacent).

///Профиль визарда: кайт + касты + защита в упоре
/datum/ai_controller/hostile_adapter/ranged_skirmisher/wizard
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/maintain_distance/spellcaster,
		/datum/ai_planning_subtree/wizard_spellcasting,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_break_away,
	)

/datum/ai_controller/hostile_adapter/ranged_skirmisher/wizard/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	var/mob/living/simple_animal/hostile/caster = new_pawn
	if(!istype(caster) || isnull(caster.retreat_distance))
		return
	//кайт-band из легаси-переменных: та же формула, что в setup_from_pawn
	//для ranged-мобов ("retreat = ближе нельзя, minimum = докуда подходим")
	blackboard[BB_AI_MIN_DISTANCE] = caster.retreat_distance
	blackboard[BB_AI_MAX_DISTANCE] = max(caster.minimum_distance, caster.retreat_distance + 2)

///Каст по ситуации: цель есть и легаси-каденс "один спелл в секунду" свободен
/datum/ai_planning_subtree/wizard_spellcasting

/datum/ai_planning_subtree/wizard_spellcasting/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/wizard/caster = controller.pawn
	if(!istype(caster))
		return
	if(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	if(caster.next_cast > world.time)
		return
	controller.queue_behavior(/datum/ai_behavior/wizard_cast, BB_AI_CURRENT_TARGET)

///Делегат легаси-каста: выбор заклинания и next_cast живут в AutomatedCast
/datum/ai_behavior/wizard_cast
	action_cooldown = 1 SECONDS //легаси: next_cast = world.time + 10
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/wizard_cast/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/simple_animal/hostile/wizard/caster = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!istype(caster) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	caster.target = target //легаси AutomatedCast читает src.target
	//спеллы могут спать в инвокациях/проекциях - не вешаем тикер поведений
	INVOKE_ASYNC(caster, TYPE_PROC_REF(/mob/living/simple_animal/hostile/wizard, AutomatedCast))
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
