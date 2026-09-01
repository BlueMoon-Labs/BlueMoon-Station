///Дальность щупалец: экранный радиус, чтобы нельзя было схватить за кадром
#define GOLIATH_TENTACLE_RANGE 7
///На сколько урон по голиафу приближает следующее щупальце
#define GOLIATH_TENTACLE_RAGE_STEP (0.5 SECONDS)

//A slow but strong beast that tries to stun using its tentacles
/mob/living/simple_animal/hostile/asteroid/goliath
	name = "goliath"
	desc = "A massive beast that uses long tentacles to ensnare its prey, threatening them is not advised under any conditions."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "Goliath"
	icon_living = "Goliath"
	icon_aggro = "Goliath_alert"
	icon_dead = "Goliath_dead"
	icon_gib = "syndicate_gib"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	move_to_delay = 10
	ranged = 1
	//Кулдаун обязан быть длиннее самого долгого стана щупальца (grab_stun_*),
	//иначе следующее щупальце приземляется, пока жертва ещё лежит, Stun()
	//обновляется на полную - и голиаф держит её до смерти. Разница кулдауна
	//и стана - это окно, в котором жертва может встать и ответить.
	ranged_cooldown_time = 100
	friendly_verb_continuous = "wails at"
	friendly_verb_simple = "wail at"
	speak_emote = list("bellows")
	speed = 3
	maxHealth = 300
	health = 300
	harm_intent_damage = 0
	obj_damage = 100
	melee_damage_lower = 18
	melee_damage_upper = 18
	melee_telegraph_duration = 0.4 SECONDS
	attack_verb_continuous = "pulverizes"
	attack_verb_simple = "pulverize"
	attack_sound = 'sound/weapons/punch1.ogg'
	throw_message = "does nothing to the rocky hide of the"
	vision_range = 4
	aggro_vision_range = 7
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	var/pre_attack = 0
	var/pre_attack_icon = "Goliath_preattack"
	loot = list(/obj/item/stack/sheet/animalhide/goliath_hide)

	footstep_type = FOOTSTEP_MOB_HEAVY

/mob/living/simple_animal/hostile/asteroid/goliath/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		return
	handle_preattack()

/mob/living/simple_animal/hostile/asteroid/goliath/proc/handle_preattack()
	if(ranged_cooldown <= world.time + ranged_cooldown_time*0.25 && !pre_attack)
		pre_attack++
	if(!pre_attack || stat || get_effective_ai_status() == AI_IDLE)
		return
	icon_state = pre_attack_icon

/mob/living/simple_animal/hostile/asteroid/goliath/revive(full_heal = 0, admin_revive = 0, excess_healing = 0)
	if(..())
		anchored = TRUE
		. = 1

/mob/living/simple_animal/hostile/asteroid/goliath/death(gibbed)
	move_force = MOVE_FORCE_DEFAULT
	move_resist = MOVE_RESIST_DEFAULT
	pull_force = PULL_FORCE_DEFAULT
	..(gibbed)

/mob/living/simple_animal/hostile/asteroid/goliath/OpenFire()
	var/turf/tturf = get_turf(target)
	if(!isturf(tturf))
		return
	if(get_dist(src, target) > GOLIATH_TENTACLE_RANGE)//Screen range check, so you can't get tentacle'd offscreen
		return
	//Щупальце вырастает прямо под целью, поэтому голиаф обязан её видеть.
	//Своей геометрии у этой способности нет: гейт линии огня пропускает
	//всё без projectiletype, а стратегию ignore_sight голиаф получает лишь
	//за ENVIRONMENT_SMASH_WALLS - право ломиться сквозь стену, не бить сквозь неё.
	if(!can_see(src, target, GOLIATH_TENTACLE_RANGE))
		return
	visible_message("<span class='warning'>[src] digs its tentacles under [target]!</span>")
	new /obj/effect/temp_visual/goliath_tentacle/original(tturf, src)
	ranged_cooldown = world.time + ranged_cooldown_time
	icon_state = icon_aggro
	pre_attack = 0

/mob/living/simple_animal/hostile/asteroid/goliath/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	//Ускорение щупалец - награда за УРОН по голиафу. Без гейта по фактически
	//нанесённому урону кулдаун срезало любое обращение к adjustHealth, включая
	//лечение и нулевые вызовы, и реальная каденс щупалец выходила короче
	//настроенной - ровно за счёт окна, в котором жертва может действовать.
	if(. <= 0)
		return
	ranged_cooldown -= GOLIATH_TENTACLE_RAGE_STEP
	handle_preattack()

/mob/living/simple_animal/hostile/asteroid/goliath/Aggro()
	vision_range = aggro_vision_range
	handle_preattack()
	if(icon_state != icon_aggro)
		icon_state = icon_aggro

//Lavaland Goliath
/mob/living/simple_animal/hostile/asteroid/goliath/beast
	name = "goliath"
	desc = "A hulking, armor-plated beast with long tendrils arching from its back."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "goliath"
	icon_living = "goliath"
	icon_aggro = "goliath"
	icon_dead = "goliath_dead"
	throw_message = "does nothing to the tough hide of the"
	pre_attack_icon = "goliath2"
	crusher_loot = /obj/item/crusher_trophy/goliath_tentacle
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/goliath = 2, /obj/item/stack/sheet/bone = 2)
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/goliath_hide = 1)
	loot = list()
	stat_attack = UNCONSCIOUS
	robust_searching = 1

/mob/living/simple_animal/hostile/asteroid/goliath/beast/random/Initialize(mapload)
	. = ..()
	if(prob(1))
		new /mob/living/simple_animal/hostile/asteroid/goliath/beast/ancient(loc)
		return INITIALIZE_HINT_QDEL

/mob/living/simple_animal/hostile/asteroid/goliath/beast/ancient
	name = "ancient goliath"
	desc = "Goliaths are biologically immortal, and rare specimens have survived for centuries. This one is clearly ancient, and its tentacles constantly churn the earth around it."
	icon_state = "Goliath"
	icon_living = "Goliath"
	icon_aggro = "Goliath_alert"
	icon_dead = "Goliath_dead"
	maxHealth = 800
	health = 800
	speed = 4
	//всё ещё чаще обычного голиафа, но окно на действие сохраняется
	ranged_cooldown_time = 90
	pre_attack_icon = "Goliath_preattack"
	throw_message = "does nothing to the rocky hide of the"
	loot = list(/obj/item/stack/sheet/animalhide/goliath_hide) //A throwback to the asteroid days
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/goliath = 2, /obj/item/stack/sheet/bone = 2)
	guaranteed_butcher_results = list()
	crusher_drop_mod = 30
	wander = FALSE
	var/list/cached_tentacle_turfs
	var/turf/last_location
	var/tentacle_recheck_cooldown = 100

// Отключаю тентаклиевую фауну вокруг древних, из за огромного срача в память удалеными тентаклями и таймерами.
// Если кто перепишет работу тентаклей (/obj/effect/temp_visual/goliath_tentacle/ и далее по цепочки проки)
// без их постоянного создания и удаления, жизнь можно включить обратно.
/*
/mob/living/simple_animal/hostile/asteroid/goliath/beast/ancient/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		return
	if(isturf(loc))
		if(!LAZYLEN(cached_tentacle_turfs) || loc != last_location || tentacle_recheck_cooldown <= world.time)
			LAZYCLEARLIST(cached_tentacle_turfs)
			last_location = loc
			tentacle_recheck_cooldown = world.time + initial(tentacle_recheck_cooldown)
			for(var/turf/open/T in orange(4, loc))
				LAZYADD(cached_tentacle_turfs, T)
		for(var/t in cached_tentacle_turfs)
			if(isopenturf(t))
				if(prob(10))
					new /obj/effect/temp_visual/goliath_tentacle(t, src)
			else
				cached_tentacle_turfs -= t
*/

/mob/living/simple_animal/hostile/asteroid/goliath/beast/tendril
	fromtendril = TRUE

//tentacles
/obj/effect/temp_visual/goliath_tentacle
	name = "goliath tentacle"
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "Goliath_tentacle_spawn"
	layer = BELOW_MOB_LAYER
	/// Weak reference so tentacles don't keep their owner alive through timer callbacks.
	var/datum/weakref/spawner_ref
	///Стан обычного захвата. Все три тира обязаны быть короче ranged_cooldown_time
	///голиафа: разница и есть окно, в котором жертва встаёт и отвечает. Стан
	///длиннее кулдауна означает, что следующее щупальце застаёт её лежащей и
	///просто обновляет Stun() - цепочка не отпускает до смерти.
	var/grab_stun = 7.5 SECONDS
	///Захват сквозь броню с GOLIATH_RESISTANCE
	var/grab_stun_armored = 2.5 SECONDS
	///Захват через одежду с GOLIATH_WEAKNESS (HEVA): дольше всех, но не бесконечно
	var/grab_stun_vulnerable = 8.5 SECONDS

/obj/effect/temp_visual/goliath_tentacle/proc/get_spawner()
	return spawner_ref?.resolve()

/obj/effect/temp_visual/goliath_tentacle/Initialize(mapload, mob/living/new_spawner)
	. = ..()
	for(var/obj/effect/temp_visual/goliath_tentacle/T in loc)
		if(T != src)
			return INITIALIZE_HINT_QDEL
	if(!QDELETED(new_spawner))
		spawner_ref = WEAKREF(new_spawner)
	if(ismineralturf(loc))
		var/turf/closed/mineral/M = loc
		M.gets_drilled()
	deltimer(timerid)
	timerid = addtimer(CALLBACK(src, PROC_REF(tripanim)), 7, TIMER_STOPPABLE)

/obj/effect/temp_visual/goliath_tentacle/original/Initialize(mapload, new_spawner)
	. = ..()
	var/mob/living/spawner = get_spawner()
	var/list/directions = GLOB.cardinals.Copy()
	for(var/i in 1 to 3)
		var/spawndir = pick_n_take(directions)
		var/turf/T = get_step(src, spawndir)
		if(T)
			new /obj/effect/temp_visual/goliath_tentacle(T, spawner)

/obj/effect/temp_visual/goliath_tentacle/proc/tripanim()
	icon_state = "Goliath_tentacle_wiggle"
	deltimer(timerid)
	timerid = addtimer(CALLBACK(src, PROC_REF(trip)), 3, TIMER_STOPPABLE)

/obj/effect/temp_visual/goliath_tentacle/proc/trip()
	var/latched = FALSE
	var/mob/living/spawner = get_spawner()
	for(var/mob/living/L in loc)
		if((spawner && spawner.faction_check_mob(L)) || L.stat == DEAD)
			continue
		visible_message("<span class='danger'>[src] grabs hold of [L]!</span>")
		var/obj/item/clothing/S = L.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		if(S && S.resistance_flags & GOLIATH_RESISTANCE)
			L.Stun(grab_stun_armored)
		else if(S && S.resistance_flags & GOLIATH_WEAKNESS)
			L.Stun(grab_stun_vulnerable)
		else
			L.Stun(grab_stun)
		L.adjustBruteLoss(rand(15,20)) // Less stun more harm
		latched = TRUE
	for(var/obj/vehicle/sealed/mecha/M in loc)
		M.take_damage(20, BRUTE, null, null, null, 25)
	if(!latched)
		retract()
	else
		deltimer(timerid)
		timerid = addtimer(CALLBACK(src, PROC_REF(retract)), 10, TIMER_STOPPABLE)

/obj/effect/temp_visual/goliath_tentacle/proc/retract()
	icon_state = "Goliath_tentacle_retract"
	deltimer(timerid)
	timerid = QDEL_IN_STOPPABLE(src, 7)

#undef GOLIATH_TENTACLE_RANGE
#undef GOLIATH_TENTACLE_RAGE_STEP
