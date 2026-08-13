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
	playable_by_ghost = TRUE
	taunt_chance = 30
	speed = 0
	maxHealth = 250
	health = 250
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
	search_objects = 1
	wanted_objects = list(/obj/item)
	var/random_retaliate = TRUE
	/// Keep swallowed items in contents instead of deleting them (Birdboat only)
	var/conserve_food = FALSE
	/// Choking / mid-vomit: stop hunting snacks
	var/goose_panicked = FALSE
	/// Chance (percent) to spontaneously vomit while moving while satiated; Birdboat ramps this up
	var/vomit_chance = 0
	/// Extra vomit duration from gross snacks
	var/vomit_extra_duration = 0
	COOLDOWN_DECLARE(eat_fail_feedback_cooldown)
	var/datum/action/cooldown/goose_vomit/vomit_action

/mob/living/simple_animal/hostile/retaliate/goose/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)

/mob/living/simple_animal/hostile/retaliate/goose/Destroy()
	QDEL_NULL(vomit_action)
	return ..()

/mob/living/simple_animal/hostile/retaliate/goose/death(gibbed)
	if(!gibbed && length(contents))
		var/turf/drop_turf = drop_location()
		if(isopenturf(drop_turf))
			playsound(drop_turf, 'sound/effects/splat.ogg', 50, TRUE)
			drop_turf.add_vomit_floor(src)
			for(var/atom/movable/thing as anything in contents)
				thing.forceMove(drop_turf)
	return ..()

/mob/living/simple_animal/hostile/retaliate/goose/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(stat == DEAD || goose_panicked)
		return
	try_eat_floor_scrap()

/mob/living/simple_animal/hostile/retaliate/goose/attackby(obj/item/O, mob/user, params)
	if(can_gobble(O))
		try_gobble(O, user)
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/retaliate/goose/AttackingTarget()
	if(isitem(target) && can_gobble(target))
		try_gobble(target)
		return
	return ..()

/mob/living/simple_animal/hostile/retaliate/goose/CanAttack(atom/the_target)
	if(isitem(the_target))
		if(goose_panicked || length(contents) >= GOOSE_SATIATED)
			return FALSE
		return can_gobble(the_target)
	return ..()

/// Edible snacks or anything with plastic in its materials
/mob/living/simple_animal/hostile/retaliate/goose/proc/can_gobble(obj/item/potential_food)
	if(!istype(potential_food) || QDELETED(potential_food))
		return FALSE
	if(potential_food.anchored || potential_food == src)
		return FALSE
	if(IS_EDIBLE(potential_food))
		return TRUE
	return has_plastic_material(potential_food)

/mob/living/simple_animal/hostile/retaliate/goose/proc/has_plastic_material(obj/item/thing)
	if(!length(thing.custom_materials))
		return FALSE
	return !!thing.custom_materials[/datum/material/plastic]

/mob/living/simple_animal/hostile/retaliate/goose/proc/get_foodtypes(obj/item/food)
	var/foodtypes = NONE
	if(istype(food, /obj/item/reagent_containers/food))
		var/obj/item/reagent_containers/food/snack = food
		foodtypes |= snack.foodtype
	var/datum/component/edible/edible = food.GetComponent(/datum/component/edible)
	if(edible)
		foodtypes |= edible.foodtypes
	return foodtypes

/mob/living/simple_animal/hostile/retaliate/goose/proc/try_eat_floor_scrap()
	if(stat == DEAD || goose_panicked || length(contents) >= GOOSE_SATIATED)
		return
	var/obj/item/scrap = locate(/obj/item) in loc
	if(!scrap || !can_gobble(scrap))
		return
	try_gobble(scrap)

/**
 * Swallow an item. Returns TRUE if something was eaten.
 * At critical mass Birdboat refuses another bite and empties the tank.
 */
/mob/living/simple_animal/hostile/retaliate/goose/proc/try_gobble(obj/item/food, mob/feeder)
	if(stat == DEAD || goose_panicked || !can_gobble(food))
		return FALSE
	if(length(contents) >= GOOSE_SATIATED)
		if(COOLDOWN_FINISHED(src, eat_fail_feedback_cooldown))
			visible_message(span_notice("[src] looks too full to eat [food]!"))
			COOLDOWN_START(src, eat_fail_feedback_cooldown, 5 SECONDS)
		// Only the vomit-capable subtype actually chunders from overfill
		if(vomit_action)
			vomit()
		return FALSE

	visible_message(span_notice("[src] hungrily gobbles up [food]!"))
	playsound(src, 'sound/items/eatfood.ogg', 70, TRUE)

	if(has_plastic_material(food))
		food.forceMove(src)
		choke(food)
		return TRUE

	if(conserve_food)
		food.forceMove(src)
	else
		qdel(food)

	on_gobbled(food, feeder)
	return TRUE

/mob/living/simple_animal/hostile/retaliate/goose/proc/on_gobbled(obj/item/food, mob/feeder)
	return

/mob/living/simple_animal/hostile/retaliate/goose/proc/choke(obj/item/not_food_after_all)
	visible_message(span_boldwarning("[src] is choking on [not_food_after_all]!"))
	apply_status_effect(/datum/status_effect/goose_choking)

/mob/living/simple_animal/hostile/retaliate/goose/proc/vomit()
	if(stat == DEAD || !vomit_action)
		return
	vomit_action.Trigger()

/mob/living/simple_animal/hostile/retaliate/goose/proc/on_started_vomiting(mob/living/owner, datum/action/cooldown/activated)
	SIGNAL_HANDLER
	if(activated != vomit_action)
		return NONE
	// Must not return remove_status_effect()'s TRUE — that equals COMPONENT_BLOCK_ABILITY_START
	remove_status_effect(/datum/status_effect/goose_choking)
	return NONE

// ===== Birdboat: calmer scavenger, messier guts =====

/mob/living/simple_animal/hostile/retaliate/goose/vomit
	name = "Birdboat"
	real_name = "Birdboat"
	desc = "It's a sick-looking goose, probably ate too much maintenance trash. Best not to move it around too much."
	gender = MALE
	gold_core_spawnable = NO_SPAWN
	random_retaliate = FALSE
	conserve_food = TRUE
	vomit_chance = 0

/mob/living/simple_animal/hostile/retaliate/goose/vomit/Initialize(mapload)
	. = ..()
	vomit_action = new(src)
	vomit_action.Grant(src)
	RegisterSignal(src, COMSIG_MOB_ABILITY_STARTED, PROC_REF(on_started_vomiting))
	if(prob(5))
		desc = "[initial(desc)] It's waddling more than usual. It seems to be possessed."
		deadchat_plays_goose()

/mob/living/simple_animal/hostile/retaliate/goose/vomit/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(stat == DEAD || goose_panicked)
		return
	// Like Bubber chance ramp, but only after the stomach hits critical mass
	if(length(contents) >= GOOSE_SATIATED && vomit_chance && prob(vomit_chance))
		vomit()

/mob/living/simple_animal/hostile/retaliate/goose/vomit/on_gobbled(obj/item/food, mob/feeder)
	var/foodtypes = get_foodtypes(food)
	if(foodtypes & GROSS)
		vomit_chance += 3
		vomit_extra_duration += 0.2 SECONDS
	else
		vomit_chance += 1

/mob/living/simple_animal/hostile/retaliate/goose/vomit/examine(mob/user)
	. = ..()
	. += span_notice("Somehow, it still looks hungry.")

/mob/living/simple_animal/hostile/retaliate/goose/vomit/choke(obj/item/not_food_after_all)
	if(prob(75))
		return ..()
	visible_message(span_warning("[src] is gagging on [not_food_after_all]!"))
	emote("me", EMOTE_VISIBLE, "gags!")
	addtimer(CALLBACK(src, PROC_REF(vomit)), 5 SECONDS)

/mob/living/simple_animal/hostile/retaliate/goose/vomit/proc/deadchat_plays_goose()
	stop_automated_movement = TRUE
	AddComponent(/datum/component/deadchat_control/cardinal_movement, ANARCHY_MODE, list(
		"vomit" = CALLBACK(src, PROC_REF(vomit)),
		"honk" = CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), "HONK!!!"),
		"spin" = CALLBACK(src, TYPE_PROC_REF(/mob, emote), "spin"),
	), 12 SECONDS)

// ===== Адаптер-профиль =====
// Retaliate-семейство целиком закрывает базовая стратегия (enemies-гейт из
// setup_from_pawn); единственная особость гуся - случайный запуск Retaliate()
// из движения ("гусь на взводе"). Звуки и эмоуты агра не трогаем: их играет
// легаси Aggro() при зеркалировании цели в pawn.target.

///Профиль гуся: обычный мили-ретал + случайная ярость + жор предметов
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

/datum/ai_controller/hostile_adapter/melee_chaser/goose/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	//Предметы еды/пластика обходят enemies-гейт, как мыши у змеи
	blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy/retaliate/goose

///Гусь жрёт подходящие предметы без обиды; к живым — обычный retaliate-гейт
/datum/targeting_strategy/hostile_legacy/retaliate/goose

/datum/targeting_strategy/hostile_legacy/retaliate/goose/can_attack(mob/living/living_mob, atom/target, vision_range)
	if(isitem(target))
		var/mob/living/simple_animal/hostile/retaliate/goose/bird = living_mob
		if(!istype(bird))
			return FALSE
		return bird.CanAttack(target)
	return ..()

///Случайная ярость: как в легаси, ролл не гейтится наличием цели - уже
///разъярённый гусь продолжает набирать обидчиков (сам Retaliate() и так
///троттлит групповой скан пятисекундным кулдауном)
/datum/ai_planning_subtree/goose_random_rage

/datum/ai_planning_subtree/goose_random_rage/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/goose/angry_bird = controller.pawn
	if(!istype(angry_bird) || !angry_bird.random_retaliate)
		return
	if(angry_bird.goose_panicked)
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

// ===== Vomit action + status effects =====

/datum/action/cooldown/goose_vomit
	name = "Vomit"
	desc = "Empty your stomach all over the floor. Artistic."
	check_flags = AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE
	icon_icon = 'icons/mob/animal.dmi'
	button_icon_state = "vomit"
	cooldown_time = INFINITY
	text_cooldown = FALSE
	click_to_activate = FALSE
	var/extra_duration = 0

/datum/action/cooldown/goose_vomit/Grant(mob/granted_to)
	. = ..()
	if(!owner)
		return
	RegisterSignals(owner, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED), PROC_REF(update_status_on_signal))

/datum/action/cooldown/goose_vomit/Remove(mob/removed_from)
	if(owner)
		UnregisterSignal(owner, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED))
	return ..()

/datum/action/cooldown/goose_vomit/IsAvailable(silent = FALSE)
	if(!..())
		return FALSE
	if(!length(owner?.contents))
		if(!silent)
			owner?.balloon_alert(owner, "stomach empty!")
		return FALSE
	var/mob/living/living_owner = owner
	if(living_owner?.has_status_effect(/datum/status_effect/goose_vomit))
		if(!silent)
			living_owner.balloon_alert(living_owner, "already vomiting!")
		return FALSE
	return TRUE

/datum/action/cooldown/goose_vomit/Activate(atom/target)
	StartCooldown(INFINITY)
	var/mob/living/simple_animal/hostile/retaliate/goose/bird = owner
	if(istype(bird))
		extra_duration = bird.vomit_extra_duration
		bird.vomit_extra_duration = 0
		bird.vomit_chance = 0
		bird.icon_state = "vomit"
		flick("vomit_start", bird)
		addtimer(CALLBACK(src, PROC_REF(start_vomiting)), 1.3 SECONDS)
	else
		start_vomiting()
	return TRUE

/datum/action/cooldown/goose_vomit/proc/start_vomiting()
	if(QDELETED(src) || QDELETED(owner) || owner.stat == DEAD)
		StartCooldown(0)
		return
	var/mob/living/living_owner = owner
	living_owner.apply_status_effect(/datum/status_effect/goose_vomit, extra_duration)
	extra_duration = 0

/datum/status_effect/goose_vomit
	id = "goose_vomit"
	alert_type = null
	duration = -1
	tick_interval = 1 SECONDS
	var/vomit_duration = 2.5 SECONDS
	var/elapsed_time = 0
	var/move_chance = 80
	var/vomit_item_chance = 50

/datum/status_effect/goose_vomit/on_creation(mob/living/new_owner, extra_duration = 0)
	vomit_duration += extra_duration
	return ..()

/datum/status_effect/goose_vomit/on_apply()
	. = ..()
	if(!.)
		return FALSE
	owner.Jitter(max(vomit_duration, 1))
	var/mob/living/simple_animal/hostile/retaliate/goose/bird = owner
	if(istype(bird))
		bird.goose_panicked = TRUE
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_owner_died))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved))
	return TRUE

/datum/status_effect/goose_vomit/on_remove()
	UnregisterSignal(owner, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED))
	var/mob/living/simple_animal/hostile/retaliate/goose/bird = owner
	if(istype(bird))
		bird.goose_panicked = FALSE
		if(bird.stat != DEAD)
			flick("vomit_end", bird)
			bird.icon_state = bird.icon_living
	var/datum/action/cooldown/goose_vomit/vomit_action = locate() in owner.actions
	vomit_action?.StartCooldown(0)
	return ..()

/datum/status_effect/goose_vomit/proc/on_owner_died()
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/goose_vomit/proc/on_owner_moved()
	SIGNAL_HANDLER
	vomit_iteratively(can_move = FALSE)

/datum/status_effect/goose_vomit/tick()
	elapsed_time += tick_interval
	if(!length(owner.contents))
		qdel(src)
		return
	if(elapsed_time <= vomit_duration)
		vomit_iteratively()
	else
		vomit_finale()

/datum/status_effect/goose_vomit/proc/vomit_iteratively(can_move = TRUE)
	if(prob(vomit_item_chance))
		hurl_item()
	else
		make_mess(owner.drop_location())
	if(can_move && prob(move_chance))
		var/move_dir = pick(GLOB.alldirs)
		owner.Move(get_step(owner, move_dir), move_dir)

/datum/status_effect/goose_vomit/proc/vomit_finale()
	tick_interval = 0.2 SECONDS
	owner.Jitter(1 SECONDS)
	hurl_item(vomit_strongly = TRUE)
	if(!length(owner.contents))
		qdel(src)

/datum/status_effect/goose_vomit/proc/hurl_item(vomit_strongly = FALSE)
	if(!length(owner.contents))
		return
	var/atom/movable/thing = pick(owner.contents)
	if(!ismovable(thing))
		qdel(thing)
		return
	var/drop_location = owner.drop_location()
	thing.forceMove(drop_location)
	if(isopenturf(drop_location))
		make_mess(drop_location)
	var/destination = get_edge_target_turf(drop_location, pick(GLOB.alldirs))
	var/throw_range = vomit_strongly ? rand(2, 8) : 1
	thing.safe_throw_at(destination, throw_range, 2)

/datum/status_effect/goose_vomit/proc/make_mess(turf/open/drop_turf)
	if(!istype(drop_turf))
		return
	playsound(drop_turf, 'sound/effects/splat.ogg', 50, TRUE)
	drop_turf.add_vomit_floor(owner)

/datum/status_effect/goose_choking
	id = "goose_choking"
	alert_type = null
	duration = 30 SECONDS
	tick_interval = 2 SECONDS
	var/static/list/choke_emotes = list(
		"chokes.",
		"coughs.",
		"gasps.",
		"tries urgently to breathe.",
		"shudders violently.",
		"wheezes.",
	)

/datum/status_effect/goose_choking/on_apply()
	. = ..()
	if(!.)
		return FALSE
	owner.Jitter(duration)
	var/mob/living/simple_animal/hostile/retaliate/goose/bird = owner
	if(istype(bird))
		bird.goose_panicked = TRUE
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_owner_died))
	return TRUE

/datum/status_effect/goose_choking/tick()
	if(prob(36))
		owner.emote("me", EMOTE_VISIBLE, pick(choke_emotes))

/datum/status_effect/goose_choking/on_remove()
	UnregisterSignal(owner, COMSIG_LIVING_DEATH)
	var/mob/living/simple_animal/hostile/retaliate/goose/bird = owner
	if(istype(bird) && !bird.has_status_effect(/datum/status_effect/goose_vomit))
		bird.goose_panicked = FALSE
	// Saved early (vomit / admin) if duration still in the future
	var/should_die = (duration == -1) || (duration <= world.time)
	var/mob/living/simple_animal/dying = owner
	. = ..()
	if(should_die && istype(dying) && !QDELETED(dying) && dying.stat != DEAD)
		dying.deathmessage = "lets out one final oxygen-deprived honk before [dying.p_they()] go[dying.p_es()] limp and lifeless.."
		dying.death()
	return .

/datum/status_effect/goose_choking/proc/on_owner_died()
	SIGNAL_HANDLER
	qdel(src)

#undef GOOSE_RAGE_PROB_PER_SECOND
#undef GOOSE_SATIATED
