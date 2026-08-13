//generic procs copied from obj/effect/alien
/obj/structure/spider
	name = "web"
	icon = 'icons/effects/effects.dmi'
	desc = "It's stringy and sticky."
	anchored = TRUE
	density = FALSE
	max_integrity = 15

/obj/structure/spider/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	if(damage_type == BURN)//the stickiness of the web mutes all attack sounds except fire damage type
		playsound(loc, 'sound/items/welder.ogg', 100, 1)


/obj/structure/spider/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir)
	if(damage_flag == MELEE)
		switch(damage_type)
			if(BURN)
				damage_amount *= 2
			if(BRUTE)
				damage_amount *= 0.25
	. = ..()

/obj/structure/spider/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/atmos_sensitive, mapload)

/obj/structure/spider/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > 300)
		take_damage(5, BURN, 0, 0)

/obj/structure/spider/should_atmos_process(datum/gas_mixture/exposed_air, exposed_temperature)
	return exposed_temperature > ATMOS_EXPOSURE_MINIMUM_TEMPERATURE

/obj/structure/spider/atmos_expose(datum/gas_mixture/exposed_air, exposed_temperature)
	take_damage(5, BURN, 0, 0)

/obj/structure/spider/stickyweb
	var/genetic = FALSE
	icon_state = "stickyweb1"

/obj/structure/spider/stickyweb/Initialize(mapload)
	if(prob(50))
		icon_state = "stickyweb2"
	. = ..()

/obj/structure/spider/stickyweb/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if (genetic)
		return
	if(isarachnid(mover))
		return TRUE
	if(istype(mover, /mob/living/simple_animal/hostile/poison/giant_spider))
		return TRUE
	else if(isliving(mover))
		if(istype(mover.pulledby, /mob/living/simple_animal/hostile/poison/giant_spider))
			return TRUE
		if(prob(50))
			to_chat(mover, "<span class='danger'>You get stuck in \the [src] for a moment.</span>")
			return FALSE
	else if(istype(mover, /obj/item/projectile))
		return prob(30)

/obj/structure/spider/stickyweb/genetic //for the spider genes in genetics
	genetic = TRUE
	var/mob/living/allowed_mob

/obj/structure/spider/stickyweb/genetic/Initialize(mapload, allowedmob)
	allowed_mob = allowedmob
	. = ..()

/obj/structure/spider/stickyweb/genetic/CanPass(atom/movable/mover, turf/target, mob/living/carbon/human/H)
	. = ..() //this is the normal spider web return aka a spider would make this TRUE
	if(mover == allowed_mob)
		return TRUE
	else if(isliving(mover)) //we change the spider to not be able to go through here
		if(mover.pulledby == allowed_mob)
			return TRUE
		if(prob(50))
			to_chat(mover, "<span class='danger'>You get stuck in \the [src] for a moment.</span>")
			H.AdjustConfused(10 SECONDS)
			return FALSE
		return TRUE
	else if(istype(mover, /obj/item/projectile))
		return prob(30)

/obj/structure/spider/eggcluster
	name = "egg cluster"
	desc = "They seem to pulse slightly with an inner life."
	icon_state = "eggs"
	var/amount_grown = 0
	var/player_spiders = 0
	var/directive = "" //Message from the mother
	var/poison_type = "toxin"
	var/poison_per_bite = 5
	var/list/faction = list("spiders")

/obj/structure/spider/eggcluster/Initialize(mapload)
	pixel_x = rand(3,-3)
	pixel_y = rand(3,-3)
	START_PROCESSING(SSobj, src)
	. = ..()

/obj/structure/spider/eggcluster/process()
	amount_grown += rand(0,2)
	if(amount_grown >= 100)
		var/num = rand(3,12)
		for(var/i=0, i<num, i++)
			var/obj/structure/spider/spiderling/S = new /obj/structure/spider/spiderling(src.loc)
			S.poison_type = poison_type
			S.poison_per_bite = poison_per_bite
			S.faction = faction.Copy()
			S.directive = directive
			if(player_spiders)
				S.player_spiders = 1
				S.no_nurses = TRUE
		qdel(src)

/obj/structure/spider/spiderling
	name = "spiderling"
	desc = "It never stays still for long."
	icon_state = "spiderling"
	anchored = FALSE
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	max_integrity = 3
	var/amount_grown = 0
	var/grow_as = null
	var/obj/machinery/atmospherics/components/unary/vent_pump/entry_vent
	var/travelling_in_vent = 0
	var/player_spiders = 0
	var/directive = "" //Message from the mother
	var/poison_type = "toxin"
	var/poison_per_bite = 5
	var/list/faction = list("spiders")
	var/no_nurses = FALSE
	attack_hand_speed = CLICK_CD_MELEE
	attack_hand_is_action = TRUE
	/// Вентиль, из которого паучок собирается вылезти.
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent_travel_exit
	/// Идентификатор отложенного шага прогулки по вентиляции. Снимается в Destroy():
	/// раньше здесь стоял spawn(), и он доносил паучка forceMove'ом до живого вентиля
	/// уже после qdel - в раунде 9860 это дало восемь "doMove qdel-нутого" подряд.
	var/vent_travel_timer

/obj/structure/spider/spiderling/Destroy()
	stop_vent_travel()
	walk(src, 0) //встроенный walk_to держит и паучка, и цель жёсткой ссылкой мимо GC
	new/obj/effect/decal/cleanable/insectguts(get_turf(src))
	new/obj/item/reagent_containers/food/snacks/spiderling(get_turf(src))
	. = ..()

/obj/structure/spider/spiderling/Initialize(mapload)
	. = ..()
	pixel_x = rand(6,-6)
	pixel_y = rand(6,-6)
	START_PROCESSING(SSobj, src)
	AddComponent(/datum/component/swarming)

/obj/structure/spider/spiderling/hunter
	grow_as = /mob/living/simple_animal/hostile/poison/giant_spider/hunter

/obj/structure/spider/spiderling/nurse
	grow_as = /mob/living/simple_animal/hostile/poison/giant_spider/nurse

/obj/structure/spider/spiderling/midwife
	grow_as = /mob/living/simple_animal/hostile/poison/giant_spider/nurse/midwife

/obj/structure/spider/spiderling/viper
	grow_as = /mob/living/simple_animal/hostile/poison/giant_spider/hunter/viper

/obj/structure/spider/spiderling/tarantula
	grow_as = /mob/living/simple_animal/hostile/poison/giant_spider/tarantula

/obj/structure/spider/spiderling/Bump(atom/user)
	if(istype(user, /obj/structure/table))
		forceMove(user.loc)
	else
		..()

/obj/structure/spider/spiderling/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(user.a_intent != INTENT_HELP)
		user.do_attack_animation(src)
		user.visible_message("<span class='warning'>[user] splats [src].</span>", "<span class='warning'>You splat [src].</span>", "<span class='italics'>You hear a splat...</span>")
		playsound(loc, 'sound/effects/snap.ogg', 25)
		qdel(src)
		return TRUE

/obj/structure/spider/spiderling/proc/random_skitter()
	var/list/available_turfs = list()
	for(var/turf/open/floor/holofloor/S in oview(10, src))
		// no !isspaceturf check needed since /turf/simulated is not a subtype of /turf/space
		if(S.density)
			continue
		available_turfs += S
	if(!length(available_turfs))
		return FALSE
	walk_to(src, pick(available_turfs))
	return TRUE

/// Снимает отложенные шаги прогулки по вентиляции и отпускает ссылки на вентили.
/// Обязателен в Destroy(): пока цепочка жива, колбэк держит паучка жёсткой ссылкой,
/// а её последний шаг возвращает уже удалённого паучка в contents живого вентиля.
/obj/structure/spider/spiderling/proc/stop_vent_travel()
	if(vent_travel_timer)
		deltimer(vent_travel_timer)
		vent_travel_timer = null
	entry_vent = null
	vent_travel_exit = null
	travelling_in_vent = 0

/// Выбирает вентиль на выходе и заводит отложенную цепочку перемещения.
/obj/structure/spider/spiderling/proc/begin_vent_travel()
	var/datum/pipeline/entry_vent_parent = length(entry_vent.parents) ? entry_vent.parents[1] : null
	if(!entry_vent_parent)
		entry_vent = null
		return
	var/list/vents = list()
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in entry_vent_parent.other_atmosmch)
		vents += temp_vent
	if(!length(vents))
		entry_vent = null
		return
	vent_travel_exit = pick(vents)
	if(prob(50))
		visible_message("<B>[src] scrambles into the ventilation ducts!</B>", \
						"<span class='italics'>You hear something scampering through the ventilation ducts.</span>")
	vent_travel_timer = addtimer(CALLBACK(src, PROC_REF(vent_travel_enter)), rand(20, 60), TIMER_STOPPABLE)

/// Шаг 1: паучок забирается внутрь вентиля, через который залезал.
/obj/structure/spider/spiderling/proc/vent_travel_enter()
	vent_travel_timer = null
	if(QDELETED(entry_vent) || QDELETED(vent_travel_exit))
		stop_vent_travel()
		return
	travelling_in_vent = 1
	forceMove(entry_vent)
	var/travel_time = max(round(get_dist(entry_vent, vent_travel_exit) / 2), 1)
	vent_travel_timer = addtimer(CALLBACK(src, PROC_REF(vent_travel_halfway), travel_time), travel_time, TIMER_STOPPABLE)

/// Шаг 2: середина пути, слышно шуршание в трубах.
/obj/structure/spider/spiderling/proc/vent_travel_halfway(travel_time)
	vent_travel_timer = null
	if(QDELETED(vent_travel_exit) || vent_travel_exit.welded)
		abort_vent_travel()
		return
	if(prob(50))
		audible_message("<span class='italics'>You hear something scampering through the ventilation ducts.</span>")
	vent_travel_timer = addtimer(CALLBACK(src, PROC_REF(vent_travel_emerge)), travel_time, TIMER_STOPPABLE)

/// Шаг 3: паучок вылезает у вентиля назначения.
/obj/structure/spider/spiderling/proc/vent_travel_emerge()
	vent_travel_timer = null
	if(QDELETED(vent_travel_exit) || vent_travel_exit.welded)
		abort_vent_travel()
		return
	var/turf/exit_turf = get_turf(vent_travel_exit)
	stop_vent_travel()
	if(exit_turf)
		forceMove(exit_turf)

/// Дорогу перекрыли - вылезаем там же, где залезли, а не остаёмся навсегда
/// в contents вентиля (оттуда travelling_in_vent уже никогда не сбрасывался).
/obj/structure/spider/spiderling/proc/abort_vent_travel()
	var/turf/entry_turf = get_turf(entry_vent)
	stop_vent_travel()
	if(entry_turf)
		forceMove(entry_turf)

/obj/structure/spider/spiderling/process()
	if(travelling_in_vent)
		if(isturf(loc))
			travelling_in_vent = 0
			entry_vent = null
			vent_travel_exit = null
	else if(entry_vent)
		if(QDELETED(entry_vent))
			entry_vent = null
		else if(get_dist(src, entry_vent) <= 1)
			begin_vent_travel()
	else if(prob(33))
		var/list/nearby = oview(10, src)
		if(nearby.len)
			var/atom/target_atom = pick(nearby)
			//Идём на турф цели, а не за самой целью: встроенный walk_to держит цель
			//жёсткой ссылкой мимо GC, и любой подобранный из oview предмет хардделился.
			walk_to(src, get_turf(target_atom))
			if(prob(40))
				src.visible_message("<span class='notice'>\The [src] skitters[pick(" away"," around","")].</span>")
	else if(prob(10))
		//ventcrawl!
		for(var/obj/machinery/atmospherics/components/unary/vent_pump/v in view(7,src))
			if(!v.welded)
				entry_vent = v
				walk_to(src, get_turf(entry_vent), 1)
				break
	if(isturf(loc))
		amount_grown += rand(0,2)
		if(amount_grown >= 100)
			if(!grow_as)
				if(no_nurses)
					grow_as = pick(/mob/living/simple_animal/hostile/poison/giant_spider, /mob/living/simple_animal/hostile/poison/giant_spider/hunter, /mob/living/simple_animal/hostile/poison/giant_spider/hunter/viper, /mob/living/simple_animal/hostile/poison/giant_spider/tarantula)
				else if(prob(3))
					grow_as = pick(/mob/living/simple_animal/hostile/poison/giant_spider/tarantula, /mob/living/simple_animal/hostile/poison/giant_spider/hunter/viper, /mob/living/simple_animal/hostile/poison/giant_spider/nurse/midwife)
				else
					grow_as = pick(/mob/living/simple_animal/hostile/poison/giant_spider, /mob/living/simple_animal/hostile/poison/giant_spider/hunter, /mob/living/simple_animal/hostile/poison/giant_spider/nurse)
			var/mob/living/simple_animal/hostile/poison/giant_spider/S = new grow_as(src.loc)
			S.poison_per_bite = poison_per_bite
			S.poison_type = poison_type
			S.faction = faction.Copy()
			S.directive = directive
			if(player_spiders)
				S.playable_spider = TRUE
				notify_ghosts("Spider [S.name] can be controlled", null, enter_link="<a href=?src=[REF(S)];activate=1>(Click to play)</a>", source=S, action=NOTIFY_ATTACK, ignore_key = POLL_IGNORE_SPIDER, ignore_dnr_observers = TRUE)
			qdel(src)



/obj/structure/spider/cocoon
	name = "cocoon"
	desc = "Something wrapped in silky spider web."
	icon_state = "cocoon1"
	max_integrity = 60

/obj/structure/spider/cocoon/Initialize(mapload)
	icon_state = pick("cocoon1","cocoon2","cocoon3")
	. = ..()

/obj/structure/spider/cocoon/container_resist(mob/living/user)
	var/breakout_time = 600
	to_chat(user, "<span class='notice'>You struggle against the tight bonds... (This will take about [DisplayTimeText(breakout_time)].)</span>")
	visible_message("You see something struggling and writhing in \the [src]!")
	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src)
			return
		qdel(src)

/obj/structure/spider/cocoon/Destroy()
	var/turf/T = get_turf(src)
	src.visible_message("<span class='warning'>\The [src] splits open.</span>")
	for(var/atom/movable/A in contents)
		A.forceMove(T)
	return ..()
