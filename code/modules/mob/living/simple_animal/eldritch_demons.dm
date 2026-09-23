/mob/living/simple_animal/hostile/eldritch
	name = "demon"
	real_name = "demon"
	desc = ""
	gender = NEUTER
	mob_biotypes = NONE
	speak_emote = list("кричит")
	response_help_continuous = "thinks better of touching"
	response_help_simple = "think better of touching"
	response_disarm_continuous = "flails at"
	response_disarm_simple = "flail at"
	response_harm_continuous = "reaps"
	response_harm_simple = "tears"
	speak_chance = 1
	icon = 'icons/mob/eldritch_mobs.dmi'
	speed = 0
	a_intent = INTENT_HARM
	stop_automated_movement = 1
	//Чистый гост-вессель: ритуал призыва отдаёт тело призраку либо удаляет
	//моба; AI не включается никогда и никем. Постоянное исключение миграции
	//на ai_controller - см. hostile_adapter/MIGRATION_EXCEPTIONS.md и пин
	//ai_eldritch_stays_player_vessel.
	AIStatus = AI_OFF
	attack_sound = 'sound/weapons/punch1.ogg'
	see_in_dark = 7
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = INFINITY
	healable = 0
	movement_type = GROUND
	pressure_resistance = 100
	del_on_death = TRUE
	deathmessage = "implodes into itself"
	faction = list("heretics")
	simple_mob_flags = SILENCE_RANGED_MESSAGE
	///Innate spells that are supposed to be added when a beast is created
	var/list/spells_to_add

/mob/living/simple_animal/hostile/eldritch/Initialize(mapload)
	. = ..()
	add_spells()

/**
  * Add_spells
  *
  * Goes through spells_to_add and adds each spell to the mind.
  */
/mob/living/simple_animal/hostile/eldritch/proc/add_spells()
	for(var/spell in spells_to_add)
		AddSpell(new spell())

/mob/living/simple_animal/hostile/eldritch/raw_prophet
	name = "raw prophet"
	real_name = "raw prophet"
	desc = "Чудовище, сшитое из отрубленных конечностей."
	icon = 'modular_bluemoon/icons/mob/heretic_demons.dmi'
	icon_state = "raw_prophet"
	status_flags = CANPUSH
	icon_living = "raw_prophet"
	melee_damage_lower = 5
	melee_damage_upper = 10
	maxHealth = 50
	health = 50
	sight = SEE_MOBS|SEE_OBJS|SEE_TURFS
	spells_to_add = list(/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash/long,/obj/effect/proc_holder/spell/pointed/manse_link,/obj/effect/proc_holder/spell/targeted/telepathy/eldritch,/obj/effect/proc_holder/spell/pointed/trigger/blind/eldritch)

	var/list/linked_mobs = list()

/mob/living/simple_animal/hostile/eldritch/raw_prophet/Initialize(mapload)
	. = ..()
	link_mob(src)

/mob/living/simple_animal/hostile/eldritch/raw_prophet/Login()
	. = ..()
	client.change_view(10)

/mob/living/simple_animal/hostile/eldritch/raw_prophet/proc/link_mob(mob/living/mob_linked)
	if(QDELETED(mob_linked) || mob_linked.stat == DEAD)
		return FALSE
	if(HAS_TRAIT(mob_linked, TRAIT_MINDSHIELD)) //mindshield implant, no dice
		return FALSE
	if(mob_linked.anti_magic_check(FALSE, FALSE, TRUE, 0))
		return FALSE
	if(linked_mobs[mob_linked])
		return FALSE

	to_chat(mob_linked, span_notice("В ваш разум проникает чужое присутствие. Далёкий шёпот и крики ужаса сливаются в приветствие: [src] связывает вас с Мансусом."))
	var/datum/action/innate/mansus_speech/action = new(src)
	linked_mobs[mob_linked] = action
	action.Grant(mob_linked)
	RegisterSignal(mob_linked, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING) , PROC_REF(unlink_mob))
	return TRUE

/mob/living/simple_animal/hostile/eldritch/raw_prophet/proc/unlink_mob(mob/living/mob_linked)
	if(!linked_mobs[mob_linked])
		return
	UnregisterSignal(mob_linked, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING))
	var/datum/action/innate/mansus_speech/action = linked_mobs[mob_linked]
	action.Remove(mob_linked)
	qdel(action)
	to_chat(mob_linked, span_notice("Связь с Мансусом обрывается. Голос [src] исчезает из вашего разума."))
	mob_linked.emote("realagony")
	//micro stun
	mob_linked.AdjustParalyzed(0.5 SECONDS)
	linked_mobs -= mob_linked

/mob/living/simple_animal/hostile/eldritch/raw_prophet/death(gibbed)
	for(var/linked_mob in linked_mobs.Copy())
		unlink_mob(linked_mob)
	return ..()

/mob/living/simple_animal/hostile/eldritch/raw_prophet/Destroy()
	for(var/linked_mob in linked_mobs.Copy())
		unlink_mob(linked_mob)
	return ..()

/mob/living/simple_animal/hostile/eldritch/raw_prophet/Logout()
	client?.change_view(world.view)
	return ..()

/mob/living/simple_animal/hostile/eldritch/armsy
	name = "terror of the night"
	real_name = "many-armed horror"
	desc = "Чудовище, сшитое из отрубленных конечностей."
	icon = 'modular_bluemoon/icons/mob/heretic_demons.dmi'
	icon_state = "armsy_start"
	icon_living = "armsy_start"
	maxHealth = 400
	health = 400
	obj_damage = 80
	melee_damage_lower = 10
	melee_damage_upper = 15
	move_resist = MOVE_FORCE_OVERPOWERING+1
	movement_type = GROUND
	environment_smash = ENVIRONMENT_SMASH_RWALLS
	sight = SEE_MOBS
	spells_to_add = list(/obj/effect/proc_holder/spell/targeted/worm_contract)
	ranged = TRUE
	///Previous segment in the chain
	var/mob/living/simple_animal/hostile/eldritch/armsy/back
	///Next segment in the chain
	var/mob/living/simple_animal/hostile/eldritch/armsy/front
	///Your old location
	var/oldloc
	///Allow / disallow pulling
	var/allow_pulling = FALSE
	///How many arms do we have to eat to expand?
	var/stacks_to_grow = 2
	///Currently eaten arms
	var/current_stacks = 0

//I tried Initalize but it didnt work, like at all. This proc just wouldnt fire if it was Initalize instead of New
/mob/living/simple_animal/hostile/eldritch/armsy/Initialize(mapload,spawn_more = TRUE,len = 6)
	. = ..()
	oldloc = loc
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(update_chain_links))
	RegisterSignal(src, COMSIG_PARENT_PREQDELETED, PROC_REF(release_body))
	if(!spawn_more)
		return
	allow_pulling = TRUE
	len = clamp(len, 3, 12)
	var/mob/living/simple_animal/hostile/eldritch/armsy/previous = src
	for(var/index in 2 to len)
		var/mob/living/simple_animal/hostile/eldritch/armsy/segment = new type(drop_location(), FALSE)
		previous.back = segment
		segment.front = previous
		segment.icon_state = index == len ? "armsy_end" : "armsy_mid"
		segment.icon_living = segment.icon_state
		previous = segment

//we are literally a vessel of otherworldly destruction, we bring our own gravity unto this plane
/mob/living/simple_animal/hostile/eldritch/armsy/has_gravity(turf/T)
	return TRUE


/mob/living/simple_animal/hostile/eldritch/armsy/can_be_pulled()
	return FALSE

///Updates chain links to force move onto a single tile
/mob/living/simple_animal/hostile/eldritch/armsy/proc/contract_next_chain_into_single_tile()
	if(back)
		back.forceMove(loc)
		back.contract_next_chain_into_single_tile()
	return

/mob/living/simple_animal/hostile/eldritch/armsy/proc/get_length()
	. += 1
	if(back)
		. += back.get_length()

///Updates the next mob in the chain to move to our last location, fixed the worm if somehow broken.
/mob/living/simple_animal/hostile/eldritch/armsy/proc/update_chain_links()
	gib_trail()
	if(back && back.loc != oldloc)
		back.Move(oldloc)
	// self fixing properties if somehow broken
	if(front && loc != front.oldloc)
		forceMove(front.oldloc)
	oldloc = loc

/mob/living/simple_animal/hostile/eldritch/armsy/proc/gib_trail()
	if(front) // head makes gibs
		return
	var/chosen_decal = pick(typesof(/obj/effect/decal/cleanable/blood/tracks))
	var/obj/effect/decal/cleanable/blood/gibs/decal = new chosen_decal(drop_location())
	decal.setDir(dir)

/mob/living/simple_animal/hostile/eldritch/armsy/proc/release_body()
	SIGNAL_HANDLER
	var/list/released = list()
	// transfer_to() обращается к языкам старого тела до отметки QDELING.
	for(var/mob/living/inside in contents.Copy())
		inside.forceMove(drop_location())
		inside.remove_status_effect(STATUS_EFFECT_STASIS, STASIS_ASCENSION_EFFECT)
		if(mind && !inside.mind)
			mind.transfer_to(inside, TRUE)
		released += inside
	if(stat == DEAD && length(released))
		var/list/worm_shape = flesh_shape()
		for(var/mob/living/inside as anything in released)
			heretic_flesh_expel_fx(inside, worm_shape)

/mob/living/simple_animal/hostile/eldritch/armsy/Destroy()
	if(front)
		front.icon_state = "armsy_end"
		front.icon_living = "armsy_end"
		front.back = null
	if(back)
		QDEL_NULL(back) // chain destruction baby
	return ..()

/mob/living/simple_animal/hostile/eldritch/armsy/BiologicalLife(delta_time, times_fired)
	. = ..()
	if(stat != DEAD)
		adjustBruteLoss(-delta_time)

/mob/living/simple_animal/hostile/eldritch/armsy/proc/heal()
	if(health == maxHealth)
		if(back)
			back.heal()
			return
		else
			current_stacks++
			if(current_stacks >= stacks_to_grow)
				grow_tail()

	adjustBruteLoss(-maxHealth * 0.5, FALSE)
	adjustFireLoss(-maxHealth * 0.5 ,FALSE)

/mob/living/simple_animal/hostile/eldritch/armsy/proc/grow_tail()
	var/mob/living/simple_animal/hostile/eldritch/armsy/head = src
	while(head.front)
		head = head.front
	if(head.get_length() >= HERETIC_FLESH_WORM_MAX_LENGTH)
		return null
	var/mob/living/simple_animal/hostile/eldritch/armsy/segment = new type(drop_location(), FALSE)
	icon_state = front ? "armsy_mid" : "armsy_start"
	icon_living = icon_state
	back = segment
	segment.icon_state = "armsy_end"
	segment.icon_living = "armsy_end"
	segment.front = src
	segment.toggle_ai(AI_OFF)
	current_stacks = 0
	return segment

/mob/living/simple_animal/hostile/eldritch/armsy/proc/get_tail()
	var/mob/living/simple_animal/hostile/eldritch/armsy/tail = src
	while(tail.back)
		tail = tail.back
	return tail

/mob/living/simple_animal/hostile/eldritch/armsy/proc/chain_health()
	for(var/mob/living/simple_animal/hostile/eldritch/armsy/segment = src, segment, segment = segment.back)
		. += segment.health

/mob/living/simple_animal/hostile/eldritch/armsy/proc/heal_chain(amount)
	for(var/mob/living/simple_animal/hostile/eldritch/armsy/segment = src, segment && amount > 0, segment = segment.back)
		var/healed = min(amount, segment.maxHealth - segment.health)
		segment.adjustHealth(-healed)
		amount -= healed


/mob/living/simple_animal/hostile/eldritch/armsy/Shoot(atom/targeted_atom)
	target = targeted_atom
	AttackingTarget()


/mob/living/simple_animal/hostile/eldritch/armsy/AttackingTarget()
	if(QDELETED(target))
		return
	if(Adjacent(target) && (istype(target,/obj/item/bodypart/r_arm) || istype(target,/obj/item/bodypart/l_arm)))
		qdel(target)
		heal()
		return
	if(target == back || target == front)
		return
	if(back)
		back.target = target
		back.AttackingTarget()
	if(!Adjacent(target))
		return
	do_attack_animation(target)
	//have fun
	//if(istype(target,/turf/closed/wall))
		//var/turf/closed/wall = target
		//wall.ScrapeAway()


	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(HAS_TRAIT(C, TRAIT_NODISMEMBER))
			return
		var/list/parts = list()
		for(var/X in C.bodyparts)
			var/obj/item/bodypart/bodypart = X
			if(bodypart.body_part != HEAD && bodypart.body_part != CHEST)
				if(bodypart.dismemberable)
					parts += bodypart
		if(length(parts) && prob(10))
			var/obj/item/bodypart/bodypart = pick(parts)
			bodypart.dismember()

	return ..()

/mob/living/simple_animal/hostile/eldritch/armsy/prime
	name = "lord of the night"
	real_name = "lord of decay"
	maxHealth = 800
	health = 800
	melee_damage_lower = 20
	melee_damage_upper = 25
	var/feeding = FALSE

/mob/living/simple_animal/hostile/eldritch/armsy/prime/Initialize(mapload,spawn_more = TRUE,len = 9)
	. = ..()
	var/matrix/matrix_transformation = matrix()
	matrix_transformation.Scale(1.4,1.4)
	transform = matrix_transformation

/mob/living/simple_animal/hostile/eldritch/armsy/prime/AttackingTarget()
	if(feeding)
		return
	if(can_devour(target))
		INVOKE_ASYNC(src, PROC_REF(devour), target)
		return
	return ..()

/mob/living/simple_animal/hostile/eldritch/armsy/prime/proc/can_devour(atom/food)
	if(QDELETED(food) || front || stat == DEAD || !ishuman(food) || !isturf(food.loc) || !Adjacent(food))
		return FALSE
	var/mob/living/carbon/human/corpse = food
	if(corpse.stat != DEAD || IS_HERETIC(corpse) || IS_HERETIC_MONSTER(corpse))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(src)
	var/datum/eldritch_knowledge/final_eldritch/flesh_final/finale = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/flesh_final)
	return finale?.applied_body == src

/mob/living/simple_animal/hostile/eldritch/armsy/prime/proc/devour(mob/living/carbon/human/corpse)
	feeding = TRUE
	visible_message(span_danger("[src] вгрызается в [corpse]!"), span_notice("Вы начинаете пожирать [corpse]."))
	playsound(src, 'modular_bluemoon/sound/heretic/flesh_screech.ogg', 50, TRUE)
	// Рывки головы стартуют таймером: сбой рисования не оставит червя навсегда занятым трапезой.
	addtimer(CALLBACK(src, PROC_REF(start_feast), WEAKREF(corpse)), world.tick_lag)
	var/fed = do_after(src, HERETIC_FLESH_WORM_FEED_TIME, corpse, extra_checks = CALLBACK(src, PROC_REF(unhurt_while_feeding), list(chain_health())))
	feeding = FALSE
	stop_feast()
	if(!fed || !can_devour(corpse))
		return FALSE
	var/turf/gore_spot = get_turf(corpse)
	visible_message(span_danger("[src] пожирает [corpse]!"), span_notice("Вы пожираете [corpse]."))
	playsound(src, 'sound/magic/Demon_consume.ogg', 50, TRUE)
	log_combat(src, corpse, "devoured")
	corpse.gib(no_bodyparts = TRUE, drop_items = TRUE)
	heal_chain(HERETIC_FLESH_WORM_FEED_HEAL)
	var/mob/living/simple_animal/hostile/eldritch/armsy/tail = get_tail()
	tail.grow_tail()
	feast_gulp(gore_spot)
	return TRUE

/mob/living/simple_animal/hostile/eldritch/armsy/prime/proc/unhurt_while_feeding(list/last_health)
	var/current_health = chain_health()
	if(current_health < last_health[1])
		return FALSE
	last_health[1] = current_health
	return TRUE


/mob/living/simple_animal/hostile/eldritch/rust_spirit
	name = "rust walker"
	real_name = "rust walker"
	desc = "Непостижимое чудовище, вытягивающее жизнь из всего вокруг."
	icon_state = "rust_walker_s"
	status_flags = CANPUSH
	icon_living = "rust_walker_s"
	maxHealth = 200
	health = 200
	melee_damage_lower = 25
	melee_damage_upper = 35
	sight = SEE_TURFS
	spells_to_add = list(/obj/effect/proc_holder/spell/aoe_turf/rust_conversion/small,/obj/effect/proc_holder/spell/aimed/rust_wave/short)

/mob/living/simple_animal/hostile/eldritch/rust_spirit/setDir(newdir, ismousemovement)
    . = ..()
    if(newdir == NORTH)
        icon_state = "rust_walker_n"
    else if(newdir == SOUTH)
        icon_state = "rust_walker_s"
    update_icon()

/mob/living/simple_animal/hostile/eldritch/rust_spirit/Moved()
	. = ..()
	playsound(src, 'sound/effects/footstep/rustystep1.ogg', 100, TRUE)

/mob/living/simple_animal/hostile/eldritch/rust_spirit/Life()
	if(stat == DEAD)
		return ..()
	var/turf/T = get_turf(src)
	if(istype(T,/turf/open/floor/plating/rust))
		adjustBruteLoss(-3, FALSE)
		adjustFireLoss(-3, FALSE)
	return ..()

/mob/living/simple_animal/hostile/eldritch/ash_spirit
	name = "ash spirit"
	real_name = "ash spirit"
	desc = "Непостижимое чудовище, вытягивающее жизнь из всего вокруг."
	icon = 'modular_bluemoon/icons/mob/heretic_demons.dmi'
	icon_state = "ash_walker"
	status_flags = CANPUSH
	icon_living = "ash_walker"
	maxHealth = 75
	health = 75
	melee_damage_lower = 15
	melee_damage_upper = 20
	sight = SEE_TURFS
	spells_to_add = list(/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash,/obj/effect/proc_holder/spell/pointed/cleave/long,/obj/effect/proc_holder/spell/aoe_turf/fire_cascade)

/mob/living/simple_animal/hostile/eldritch/stalker
	name = "flesh stalker"
	real_name = "flesh stalker"
	desc = "Чудовище, сшитое из отрубленных конечностей."
	icon = 'modular_bluemoon/icons/mob/heretic_demons.dmi'
	icon_state = "stalker"
	status_flags = CANPUSH
	icon_living = "stalker"
	maxHealth = 300
	health = 300
	melee_damage_lower = 15
	melee_damage_upper = 20
	sight = SEE_MOBS
	spells_to_add = list(/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash,/obj/effect/proc_holder/spell/targeted/shapeshift/eldritch,/obj/effect/proc_holder/spell/targeted/emplosion/eldritch)
