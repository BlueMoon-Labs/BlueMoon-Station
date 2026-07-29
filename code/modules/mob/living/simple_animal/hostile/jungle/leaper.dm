#define PLAYER_HOP_DELAY 25

//Huge, carnivorous toads that spit an immobilizing toxin at its victims before leaping onto them.
//It has no melee attack, and its damage comes from the toxin in its bubbles and its crushing leap.
//Its eyes will turn red to signal an imminent attack!
/mob/living/simple_animal/hostile/jungle/leaper
	name = "leaper"
	desc = "Commonly referred to as 'leapers', the Geron Toad is a massive beast that spits out highly pressurized bubbles containing a unique toxin, knocking down its prey and then crushing it with its girth."
	icon = 'icons/mob/jungle/leaper.dmi'
	icon_state = "leaper"
	icon_living = "leaper"
	icon_dead = "leaper_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	maxHealth = 300
	health = 300
	ranged = TRUE
	projectiletype = /obj/item/projectile/leaper
	projectilesound = 'sound/weapons/pierce.ogg'
	ranged_cooldown_time = 30
	pixel_x = -16
	layer = LARGE_MOB_LAYER
	speed = 10
	stat_attack = UNCONSCIOUS
	robust_searching = 1
	var/hopping = FALSE
	var/hop_cooldown = 0 //Strictly for player controlled leapers
	var/projectile_ready = FALSE //Stopping AI leapers from firing whenever they want, and only doing it after a hop has finished instead

	footstep_type = FOOTSTEP_MOB_HEAVY

/obj/item/projectile/leaper
	name = "leaper bubble"
	icon_state = "leaper"
	knockdown = 50
	damage = 0
	range = 7
	hitsound = 'sound/effects/snap.ogg'
	nondirectional_sprite = TRUE
	impact_effect_type = /obj/effect/temp_visual/leaper_projectile_impact

/obj/item/projectile/leaper/on_hit(atom/target, blocked = FALSE)
	..()
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		C.reagents.add_reagent(/datum/reagent/toxin/leaper_venom, 5)
		return
	if(isanimal(target))
		var/mob/living/simple_animal/L = target
		L.adjustHealth(25)

/obj/item/projectile/leaper/on_range()
	var/turf/T = get_turf(src)
	..()
	new /obj/structure/leaper_bubble(T)

/obj/effect/temp_visual/leaper_projectile_impact
	name = "leaper bubble"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "leaper_bubble_pop"
	layer = ABOVE_ALL_MOB_LAYER
	duration = 3

/obj/effect/temp_visual/leaper_projectile_impact/Initialize(mapload)
	. = ..()
	new /obj/effect/decal/cleanable/leaper_sludge(get_turf(src))

/obj/effect/decal/cleanable/leaper_sludge
	name = "leaper sludge"
	desc = "A small pool of sludge, containing trace amounts of leaper venom."
	icon = 'icons/effects/tomatodecal.dmi'
	icon_state = "tomato_floor1"

/obj/structure/leaper_bubble
	name = "leaper bubble"
	desc = "A floating bubble containing leaper venom. The contents are under a surprising amount of pressure."
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "leaper"
	max_integrity = 10
	density = FALSE

/obj/structure/leaper_bubble/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, float), TRUE)
	QDEL_IN(src, 100)

/obj/structure/leaper_bubble/Destroy()
	new /obj/effect/temp_visual/leaper_projectile_impact(get_turf(src))
	playsound(src,'sound/effects/snap.ogg',50, 1, -1)
	return ..()

/obj/structure/leaper_bubble/Crossed(atom/movable/AM)
	if(isliving(AM))
		var/mob/living/L = AM
		if(!istype(L, /mob/living/simple_animal/hostile/jungle/leaper))
			playsound(src,'sound/effects/snap.ogg',50, 1, -1)
			L.DefaultCombatKnockdown(50)
			if(iscarbon(L))
				var/mob/living/carbon/C = L
				C.reagents.add_reagent(/datum/reagent/toxin/leaper_venom, 5)
			if(isanimal(L))
				var/mob/living/simple_animal/A = L
				A.adjustHealth(25)
			qdel(src)
	return ..()

/datum/reagent/toxin/leaper_venom
	name = "Leaper venom"
	description = "A toxin spat out by leapers that, while harmless in small doses, quickly creates a toxic reaction if too much is in the body."
	color = "#801E28" // rgb: 128, 30, 40
	toxpwr = 0
	taste_description = "french cuisine"
	taste_mult = 1.3

/datum/reagent/toxin/leaper_venom/on_mob_life(mob/living/carbon/M)
	if(volume >= 10)
		M.adjustToxLoss(5, 0)
	..()

/obj/effect/temp_visual/leaper_crush
	name = "grim tidings"
	desc = "Incoming leaper!"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "lily_pad"
	layer = BELOW_MOB_LAYER
	pixel_x = -32
	pixel_y = -32
	duration = 30

/mob/living/simple_animal/hostile/jungle/leaper/Initialize(mapload)
	. = ..()
	remove_verb(src, /mob/living/verb/pulled)

/mob/living/simple_animal/hostile/jungle/leaper/CtrlClickOn(atom/A)
	face_atom(A)
	target = A
	if(!isturf(loc))
		return
	if(!CheckActionCooldown())
		return
	if(hopping)
		return
	if(isliving(A))
		var/mob/living/L = A
		if(L.incapacitated())
			BellyFlop()
			return
	if(hop_cooldown <= world.time)
		Hop(player_hop = TRUE)

/mob/living/simple_animal/hostile/jungle/leaper/AttackingTarget()
	if(isliving(target))
		return
	return ..()

///AI-цикл прыжков жив: легаси AI_ON либо адаптер-контроллер (без игрока).
///Единый гейт для веток Hop/FinishHop/OpenFire/update_icons, которые легаси
///проверял как AIStatus == AI_ON && !ckey.
/mob/living/simple_animal/hostile/jungle/leaper/proc/ai_hop_cycle_active()
	if(ckey)
		return FALSE
	if(ai_controller)
		return !QDELETED(ai_controller)
	return AIStatus == AI_ON

/mob/living/simple_animal/hostile/jungle/leaper/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		return
	update_icons()

/mob/living/simple_animal/hostile/jungle/leaper/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(prob(33) && !ckey)
		ranged_cooldown = 0 //Keeps em on their toes instead of a constant rotation
	..()

/mob/living/simple_animal/hostile/jungle/leaper/OpenFire()
	face_atom(target)
	if(ranged_cooldown <= world.time)
		if(ckey)
			if(hopping)
				return
			if(isliving(target))
				var/mob/living/L = target
				if(L.incapacitated())
					return //No stunlocking. Hop on them after you stun them, you donk.
		if(ai_hop_cycle_active() && !projectile_ready)
			return
		. = ..(target)
		projectile_ready = FALSE
		update_icons()

/mob/living/simple_animal/hostile/jungle/leaper/proc/Hop(player_hop = FALSE)
	if(z != target.z)
		return
	hopping = TRUE
	density = FALSE
	pass_flags |= PASSMOB
	mob_transforming = TRUE
	var/turf/new_turf = locate((target.x + rand(-3,3)),(target.y + rand(-3,3)),target.z)
	if(player_hop)
		new_turf = get_turf(target)
		hop_cooldown = world.time + PLAYER_HOP_DELAY
	if(ai_hop_cycle_active() && ranged_cooldown <= world.time)
		projectile_ready = TRUE
		update_icons()
	throw_at(new_turf, max(3,get_dist(src,new_turf)), 1, src, FALSE, callback = CALLBACK(src, PROC_REF(FinishHop)))

/mob/living/simple_animal/hostile/jungle/leaper/proc/FinishHop()
	density = TRUE
	mob_transforming = FALSE
	pass_flags &= ~PASSMOB
	hopping = FALSE
	playsound(src.loc, 'sound/effects/meteorimpact.ogg', 100, 1)
	if(target && ai_hop_cycle_active() && projectile_ready)
		face_atom(target)
		addtimer(CALLBACK(src, PROC_REF(OpenFire), target), 5)

/mob/living/simple_animal/hostile/jungle/leaper/proc/BellyFlop()
	var/turf/new_turf = get_turf(target)
	hopping = TRUE
	mob_transforming = TRUE
	new /obj/effect/temp_visual/leaper_crush(new_turf)
	addtimer(CALLBACK(src, PROC_REF(BellyFlopHop), new_turf), 30)

/mob/living/simple_animal/hostile/jungle/leaper/proc/BellyFlopHop(turf/T)
	density = FALSE
	throw_at(T, get_dist(src,T),1,src, FALSE, callback = CALLBACK(src, PROC_REF(Crush)))

/mob/living/simple_animal/hostile/jungle/leaper/proc/Crush()
	hopping = FALSE
	density = TRUE
	mob_transforming = FALSE
	playsound(src, 'sound/effects/meteorimpact.ogg', 200, 1)
	for(var/mob/living/L in orange(1, src))
		L.adjustBruteLoss(35)
		if(!QDELETED(L)) // Some mobs are deleted on death
			var/throw_dir = get_dir(src, L)
			if(L.loc == loc)
				throw_dir = pick(GLOB.alldirs)
			var/throwtarget = get_edge_target_turf(src, throw_dir)
			L.throw_at(throwtarget, 3, 1)
			visible_message("<span class='warning'>[L] is thrown clear of [src]!</span>")
	if(ckey)//Lessens ability to chain stun as a player
		ranged_cooldown = ranged_cooldown_time + world.time
		update_icons()

/mob/living/simple_animal/hostile/jungle/leaper/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	return

/mob/living/simple_animal/hostile/jungle/leaper/update_icons()
	. = ..()
	if(stat)
		icon_state = "leaper_dead"
		return
	if(ranged_cooldown <= world.time)
		if((ai_hop_cycle_active() && projectile_ready) || ckey)
			icon_state = "leaper_alert"
			return
	icon_state = "leaper"

// ===== Адаптер-профиль =====
// Леапер не ходит вовсе (легаси Goto - no-op, движение = сами прыжки), поэтому
// контроллер без FSM и мили: только поиск целей и прыжковый цикл. Прыжки/плюха
// идут делегацией легаси Hop/BellyFlop; между приземлением и выстрелом
// (projectile_ready, легаси-фриз handle_automated_action) планирование стоит,
// а сам выстрел ставит легаси FinishHop таймером OpenFire.

///Леапер вкопан в прыжковый цикл: ходьбы у контроллера нет
/mob/living/simple_animal/hostile/jungle/leaper/can_ai_controller_move()
	return FALSE

///Профиль: заморозка фаз прыжка + поиск целей
/datum/ai_controller/hostile_adapter/leaper
	planning_subtrees = list(
		/datum/ai_planning_subtree/leaper_assault,
		/datum/ai_planning_subtree/find_hostile_targets,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Прыжковый цикл: фриз во время прыжка и взведённого выстрела, иначе - прыжок
/datum/ai_planning_subtree/leaper_assault

/datum/ai_planning_subtree/leaper_assault/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/jungle/leaper/toad = controller.pawn
	if(!istype(toad))
		return
	if(toad.hopping || toad.projectile_ready)
		//легаси-фриз: между приземлением и выстрелом FinishHop планирование стоит
		return SUBTREE_RETURN_FINISH_PLANNING
	if(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	controller.queue_behavior(/datum/ai_behavior/leaper_pounce, BB_AI_CURRENT_TARGET)

///Прыжок: обездвиженная жертва получает легаси BellyFlop, стоячая - Hop
/datum/ai_behavior/leaper_pounce
	action_cooldown = 2 SECONDS //легаси-каденс NPC-пула

/datum/ai_behavior/leaper_pounce/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/simple_animal/hostile/jungle/leaper/toad = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!istype(toad) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(toad.hopping || toad.projectile_ready)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/datum/targeting_strategy/targeting_strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	if(targeting_strategy && !targeting_strategy.can_attack(toad, target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	toad.target = target //легаси Hop/BellyFlop читают src.target
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target.incapacitated())
			//плюха с телеграфом; таймеры фазы сами доведут до Crush
			INVOKE_ASYNC(toad, TYPE_PROC_REF(/mob/living/simple_animal/hostile/jungle/leaper, BellyFlop))
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	if(toad.z != target.z)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	INVOKE_ASYNC(toad, TYPE_PROC_REF(/mob/living/simple_animal/hostile/jungle/leaper, Hop))
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

#undef PLAYER_HOP_DELAY
