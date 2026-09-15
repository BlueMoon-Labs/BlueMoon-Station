#define HERETIC_FLESH_STITCH_DAMAGE 15
#define HERETIC_FLESH_STITCH_HEALING 15
#define HERETIC_FLESH_STITCH_STEPS 2
#define HERETIC_FLESHLING_COST 2
#define HERETIC_FLESHLING_LIFETIME (90 SECONDS)
#define HERETIC_FLESHLING_LEASH 9
#define HERETIC_FLESHLING_STEP_DELAY (0.4 SECONDS)
#define HERETIC_FLESHLING_PATH_DELAY (1 SECONDS)
#define HERETIC_FLESHLING_PATH_LIMIT 12

/datum/eldritch_knowledge/base_flesh
	var/mob/living/simple_animal/heretic_fleshling/fleshling

/datum/eldritch_knowledge/base_flesh/Destroy()
	QDEL_NULL(fleshling)
	return ..()

/datum/eldritch_knowledge/base_flesh/proc/grow_fleshling(mob/living/user, obj/item/organ/organ)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(QDELETED(organ) || !isturf(organ.loc) || !user.Adjacent(organ) || user.incapacitated() || !heretic || heretic.role_removed || heretic.selected_path != PATH_FLESH || heretic.get_knowledge(type) != src || !heretic.get_knowledge(/datum/eldritch_knowledge/flesh_ghoul))
		return FALSE
	if(!QDELETED(fleshling) || !heretic.can_add_servant() || combat_resource < HERETIC_FLESHLING_COST)
		to_chat(user, span_warning("Нужны две биомассы и свободное место в свите. Можно удерживать только одного сшитого ползуна."))
		return FALSE
	if(!spend_combat_resource(HERETIC_FLESHLING_COST))
		return FALSE
	fleshling = new(get_turf(organ), heretic, heretic.get_knowledge(/datum/eldritch_knowledge/flesh_ghoul))
	fleshling.mind_initialize()
	var/datum/antagonist/heretic_monster/servant = new
	servant.set_master(heretic)
	fleshling.mind.add_antag_datum(servant)
	if(QDELETED(fleshling))
		return FALSE
	RegisterSignal(fleshling, COMSIG_PARENT_QDELETING, PROC_REF(on_fleshling_deleted))
	track_flesh_servant(servant)
	START_PROCESSING(SSfastprocess, fleshling)
	qdel(organ)
	user.visible_message(span_warning("[user] вытягивает из органа сухожилия; сшитый ползун поднимается на тонких лапах."))
	return TRUE

/datum/eldritch_knowledge/base_flesh/proc/on_fleshling_deleted(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	fleshling = null

/mob/living/simple_animal/heretic_fleshling
	name = "stitched crawler"
	desc = "Небольшой слуга из сшитых органов. Живёт полторы минуты и слушается указаний хозяина через Живой шов. Хозяин может коснуться его на помощи, чтобы отменить преследование. Дальше девяти клеток от хозяина распадается."
	icon = 'modular_bluemoon/icons/mob/heretic_demons.dmi'
	icon_state = "raw_prophet"
	icon_living = "raw_prophet"
	health = 40
	maxHealth = 40
	melee_damage_lower = 6
	melee_damage_upper = 6
	attack_verb_continuous = "терзает"
	attack_verb_simple = "терзает"
	attack_sound = 'sound/effects/wounds/blood1.ogg'
	faction = list("heretics")
	wander = FALSE
	del_on_death = TRUE
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = INFINITY
	var/datum/weakref/master_ref
	var/datum/weakref/prey_ref
	var/datum/weakref/knowledge_ref
	var/list/movement_path = list()
	var/pathfinding = FALSE
	var/expires_at
	COOLDOWN_DECLARE(attack_cooldown)
	COOLDOWN_DECLARE(step_cooldown)
	COOLDOWN_DECLARE(path_cooldown)

/mob/living/simple_animal/heretic_fleshling/Initialize(mapload, datum/antagonist/heretic/master, datum/eldritch_knowledge/required)
	. = ..()
	if(QDELETED(master) || QDELETED(required))
		return INITIALIZE_HINT_QDEL
	master_ref = WEAKREF(master)
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	expires_at = world.time + HERETIC_FLESHLING_LIFETIME

/mob/living/simple_animal/heretic_fleshling/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	master_ref = null
	prey_ref = null
	knowledge_ref = null
	movement_path = null
	return ..()

/mob/living/simple_animal/heretic_fleshling/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/mob/living/simple_animal/heretic_fleshling/proc/command_prey(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	if(master?.owner?.current != user || !isturf(user.loc) || !isturf(victim?.loc) || user.incapacitated() || !heretic_can_affect(user, victim, chargecost = 0) || get_dist(user, victim) > 5 || user.z != victim.z || !can_see(user, victim, 5))
		return FALSE
	prey_ref = WEAKREF(victim)
	movement_path.Cut()
	return TRUE

/mob/living/simple_animal/heretic_fleshling/attack_hand(mob/living/carbon/human/user)
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	if(master?.owner?.current == user && user.a_intent == INTENT_HELP && !user.incapacitated() && user.Adjacent(src))
		prey_ref = null
		movement_path.Cut()
		to_chat(user, span_notice("Ползун прекращает преследование и возвращается к вам."))
		return
	return ..()

/mob/living/simple_animal/heretic_fleshling/process()
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	var/mob/living/user = master?.owner?.current
	var/datum/antagonist/heretic_monster/servant = IS_HERETIC_MONSTER(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	var/turf/master_turf = get_turf(user)
	var/turf/crawler_turf = get_turf(src)
	if(QDELETED(user) || QDELETED(required) || !master_turf || !crawler_turf || master.role_removed || master.get_knowledge(required.type) != required || user.stat == DEAD || stat == DEAD || servant?.master != master || world.time >= expires_at || master_turf.z != crawler_turf.z || get_dist(master_turf, crawler_turf) > HERETIC_FLESHLING_LEASH)
		qdel(src)
		return
	if(client || !isturf(loc) || !isturf(user.loc) || incapacitated() || user.incapacitated() || !CHECK_MOBILITY(src, MOBILITY_USE))
		return
	var/mob/living/prey = prey_ref?.resolve()
	if(!isturf(prey?.loc) || !heretic_can_affect(user, prey, chargecost = 0) || prey.z != user.z || get_dist(user, prey) > 5 || !can_see(user, prey, 5))
		if(prey_ref)
			movement_path.Cut()
		prey_ref = null
		prey = null
	if(prey && Adjacent(prey))
		if(COOLDOWN_FINISHED(src, attack_cooldown) && heretic_can_affect(user, prey))
			COOLDOWN_START(src, attack_cooldown, 2 SECONDS)
			prey.attack_animal(src)
		return
	var/atom/destination = prey || user
	if(Adjacent(destination) || anchored || buckled || pulledby || !CHECK_MULTIPLE_BITFIELDS(mobility_flags, MOBILITY_STAND | MOBILITY_MOVE) || !COOLDOWN_FINISHED(src, step_cooldown))
		return
	if(!pathfinding && COOLDOWN_FINISHED(src, path_cooldown))
		pathfinding = TRUE
		COOLDOWN_START(src, path_cooldown, HERETIC_FLESHLING_PATH_DELAY)
		INVOKE_ASYNC(src, PROC_REF(plan_path), destination)
	if(!length(movement_path))
		return
	var/turf/next_step = movement_path[1]
	if(get_dist(src, next_step) != 1 || z != next_step.z)
		movement_path.Cut()
		return
	COOLDOWN_START(src, step_cooldown, HERETIC_FLESHLING_STEP_DELAY)
	if(step_towards(src, next_step) && get_turf(src) == next_step)
		movement_path.Cut(1, 2)
	else
		movement_path.Cut()

/mob/living/simple_animal/heretic_fleshling/proc/plan_path(atom/destination)
	var/turf/origin = get_turf(src)
	var/list/new_path = get_path_to(src, destination, HERETIC_FLESHLING_PATH_LIMIT, 1, cancel_source = src)
	if(QDELETED(src))
		return
	pathfinding = FALSE
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	if(loc != origin || QDELETED(destination) || (prey_ref?.resolve() || master?.owner?.current) != destination)
		return
	movement_path = new_path

/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch
	name = "Живой шов"
	desc = "Протяните сухожилие на 5 клеток: враг получает 15 ушибов и замедляется на 3 секунды. Свой слуга вместо этого восстанавливает по 15 ушибов и ожогов и подтягивается к вам на два шага за 1 биомассу. Шов по врагу направляет на него вашего сшитого ползуна. Стены и закрытые двери прерывают шов; пристёгнутого слугу можно вылечить, но нельзя сдвинуть."
	clothes_req = FALSE
	charge_max = 15 SECONDS
	range = 5
	invocation = "S'UT'RE"
	invocation_type = "whisper"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "flesh_mend"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/proc/valid_user(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && heretic && !heretic.role_removed && heretic.selected_path == PATH_FLESH && heretic.owner?.current == user && user.stat == CONSCIOUS && !user.incapacitated() && heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh) && heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)

/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/can_cast(mob/user, skipcharge, silent)
	return ..() && valid_user(user)

/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!valid_user(user) || !isliving(target) || QDELETED(target) || target == user || !isturf(user.loc) || !isturf(target.loc))
		return FALSE
	var/mob/living/victim = target
	if(victim.stat == DEAD || user.z != victim.z || get_dist(user, victim) > range)
		return FALSE
	var/turf/previous
	for(var/turf/tile as anything in get_line(user, victim))
		if(!isopenturf(tile) || tile.is_blocked_turf(exclude_mobs = TRUE))
			return FALSE
		if(previous && previous.x != tile.x && previous.y != tile.y)
			var/turf/side_horizontal = locate(previous.x, tile.y, tile.z)
			var/turf/side_vertical = locate(tile.x, previous.y, tile.z)
			if(!isopenturf(side_horizontal) || !isopenturf(side_vertical) || side_horizontal.is_blocked_turf(exclude_mobs = TRUE) || side_vertical.is_blocked_turf(exclude_mobs = TRUE))
				return FALSE
		previous = tile
	var/datum/antagonist/heretic_monster/servant = IS_HERETIC_MONSTER(victim)
	if(servant?.master == heretic)
		var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
		var/needs_healing = victim.getBruteLoss() > 0 || victim.getFireLoss() > 0
		var/can_reposition = get_dist(user, victim) > 1 && !victim.anchored && !victim.buckled
		return path?.combat_resource > 0 && (needs_healing || can_reposition) && !victim.check_magic_resistance(chargecost = 0)
	return heretic_can_affect(user, victim, chargecost = 0)

/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/cast(list/targets, mob/user)
	if(!length(targets) || !can_target(targets[1], user, TRUE))
		revert_cast(user)
		return
	var/mob/living/victim = targets[1]
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/antagonist/heretic_monster/servant = IS_HERETIC_MONSTER(victim)
	if(servant?.master == heretic)
		var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
		if(!path?.spend_combat_resource())
			revert_cast(user)
			return
		heretic_heal_damage(victim, HERETIC_FLESH_STITCH_HEALING, HERETIC_FLESH_STITCH_HEALING)
		if(!victim.anchored && !victim.buckled)
			for(var/step_index in 1 to HERETIC_FLESH_STITCH_STEPS)
				if(get_dist(user, victim) <= 1 || !step_towards(victim, user))
					break
		new /obj/effect/temp_visual/heretic_oldpath/flesh/mend(get_turf(victim))
		to_chat(victim, span_notice("Живой шов затягивает ваши раны и тянет к хозяину."))
	else
		if(!heretic_can_affect(user, victim))
			return
		victim.adjustBruteLoss(HERETIC_FLESH_STITCH_DAMAGE)
		victim.apply_status_effect(/datum/status_effect/heretic_flesh_stitch)
		var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
		path?.fleshling?.command_prey(user, victim)
		new /obj/effect/temp_visual/heretic_oldpath/flesh(get_turf(victim))
		to_chat(victim, span_warning("Сухожилие впивается в вас и стягивает движения!"))
	user.Beam(victim, icon_state = "drainbeam", time = 0.8 SECONDS)
	playsound(user, 'sound/effects/wounds/blood2.ogg', 60, TRUE)

/datum/status_effect/heretic_flesh_stitch
	id = "heretic_flesh_stitch"
	duration = 3 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	on_remove_on_mob_delete = TRUE

/datum/status_effect/heretic_flesh_stitch/on_apply()
	. = ..()
	if(!.)
		return FALSE
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_flesh_stitch)
	return TRUE

/datum/status_effect/heretic_flesh_stitch/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_flesh_stitch)
	return ..()

/datum/movespeed_modifier/heretic_flesh_stitch
	multiplicative_slowdown = 1

#undef HERETIC_FLESH_STITCH_DAMAGE
#undef HERETIC_FLESH_STITCH_HEALING
#undef HERETIC_FLESH_STITCH_STEPS
#undef HERETIC_FLESHLING_COST
#undef HERETIC_FLESHLING_LIFETIME
#undef HERETIC_FLESHLING_LEASH
#undef HERETIC_FLESHLING_STEP_DELAY
#undef HERETIC_FLESHLING_PATH_DELAY
#undef HERETIC_FLESHLING_PATH_LIMIT
