// --------------------------------------------------------------------------------
// --------------------- TERROR SPIDERS: TARGETING CODE -----------------------
// --------------------------------------------------------------------------------

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/LoseTarget()
	if(target && isliving(target))
		var/mob/living/T = target
		if(T.stat > 0)
			killcount++
	attackstep = 0
	attackcycles = 0
	..()

// --------------------------------------------------------------------------------
// --------------------- TERROR SPIDERS: AI BEHAVIOR CODE -------------------------
// --------------------------------------------------------------------------------


/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/proc/resume_automated_movement()
	stop_automated_movement = 0

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/adjustBruteLoss(amount, updating_health = TRUE, forced, only_robotic, only_organic)
	. = ..()
	Retaliate()

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/adjustFireLoss(amount, updating_health, forced, only_robotic, only_organic)
	. = ..()
	Retaliate()

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/Retaliate()
	// Легаси oview(src, 7) материализовал каждый видимый атом на КАЖДЫЙ удар
	// (adjustBruteLoss/adjustFireLoss). Грид AI_TARGETS + can_see() воспроизводят
	// ту же LOS-границу радиусом 7 без массового скана. Троттл как у базового
	// retaliate: настоящего обидчика на каждый удар всё равно фиксирует
	// RetaliateAgainst(), тут только широкое доразведывание врагов/союзников.
	if(world.time < next_retaliation_scan)
		return 0
	next_retaliation_scan = world.time + 5 SECONDS

	var/list/ts_nearby = list()
	for(var/mob/living/nearby_mob as anything in SSspatial_grid.orthogonal_range_search(src, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, 7))
		if(nearby_mob == src || QDELETED(nearby_mob) || (nearby_mob in enemies) || get_dist(src, nearby_mob) > 7)
			continue
		AI_METRIC_INC(los_checks)
		if(!can_see(src, nearby_mob, 7))
			continue
		if(isterrorspider(nearby_mob))
			ts_nearby += nearby_mob
			continue
		if(!("terrorspiders" in nearby_mob.faction))
			add_enemy(nearby_mob)

	// Мехи не живые AI_TARGETS - берём их из поддерживаемого реестра (как база).
	for(var/obj/vehicle/sealed/mecha/nearby_mecha as anything in GLOB.mechas_list)
		if(QDELETED(nearby_mecha) || nearby_mecha.z != z || !LAZYLEN(nearby_mecha.occupants) || (nearby_mecha in enemies) || get_dist(src, nearby_mecha) > 7)
			continue
		AI_METRIC_INC(los_checks)
		if(!can_see(src, nearby_mecha, 7))
			continue
		add_enemy(nearby_mecha)
		for(var/mob/living/occupant as anything in nearby_mecha.occupants)
			add_enemy(occupant)

	for(var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/H in ts_nearby)
		var/retaliate_faction_check = 0
		for(var/F in faction)
			if(F in H.faction)
				retaliate_faction_check = 1
				break
		if(retaliate_faction_check && !attack_same && !H.attack_same)
			for(var/atom/movable/the_enemy in enemies)
				H.add_enemy(the_enemy)
	return 0

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/proc/handle_cocoon_target()
	if(cocoon_target)
		if(get_dist(src, cocoon_target) <= 1)
			spider_steps_taken = 0
			DoWrap()
		else
			if(spider_steps_taken > spider_max_steps)
				spider_steps_taken = 0
				cocoon_target = null
				busy = 0
				stop_automated_movement = 0
			else
				spider_steps_taken++
				CreatePath(cocoon_target)
				step_to(src,cocoon_target)
				if(spider_debug)
					visible_message("<span class='notice'>[src] moves towards [cocoon_target] to cocoon it.</span>")

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/proc/seek_cocoon_target()
	last_cocoon_object = world.time
	var/list/can_see = view(src, 10)
	for(var/mob/living/C in can_see)
		if(C.stat == DEAD && !isterrorspider(C) && !C.anchored)
			spider_steps_taken = 0
			cocoon_target = C
			return
	for(var/obj/O in can_see)
		if(O.anchored)
			continue
		if(istype(O, /obj/item) || istype(O, /obj/structure) || istype(O, /obj/machinery))
			if(!istype(O, /obj/item/paper))
				cocoon_target = O
				stop_automated_movement = 1
				spider_steps_taken = 0
				return

// --------------------------------------------------------------------------------
// --------------------- TERROR SPIDERS: PATHING CODE -----------------------------
// --------------------------------------------------------------------------------

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/proc/CreatePath(mygoal)
	var/m2 = get_turf(src)
	if(m2 == mylocation)
		chasecycles++
		ClearObstacle(get_turf(mygoal))
		if(chasecycles >= 1)
			chasecycles = 0
			if(spider_opens_doors)
				var/tgt_dir = get_dir(src,mygoal)
				for(var/obj/machinery/door/airlock/A in view(1, src))
					if(A.density)
						spawn(0)
							try_open_airlock(A)
				for(var/obj/machinery/door/firedoor/F in view(1, src))
					if(tgt_dir == get_dir(src,F) && F.density && !F.welded)
						visible_message("<span class='danger'>[src] pries open the firedoor!</span>")
						F.open()

	else
		mylocation = m2
		chasecycles = 0

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/proc/ClearObstacle(turf/target_turf)
	var/list/valid_obstacles = list(/obj/structure/window, /obj/structure/closet, /obj/structure/table, /obj/structure/grille, /obj/structure/rack, /obj/machinery/door/window)
	for(var/dir in GLOB.cardinals) // North, South, East, West
		var/obj/structure/obstacle = locate(/obj/structure, get_step(src, dir))
		if(is_type_in_list(obstacle, valid_obstacles))
			obstacle.attack_animal(src)

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/proc/TSVentCrawlRandom()
	if(entry_vent)
		if(get_dist(src, entry_vent) <= 2)
			if(ai_ventbreaker && entry_vent.welded)
				entry_vent.welded = 0
				entry_vent.update_icon()
				entry_vent.visible_message("<span class='danger'>[src] smashes the welded cover off [entry_vent]!</span>")
			var/list/vents = list()
			var/datum/pipeline/entry_vent_parent = entry_vent.parents[1]
			for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in entry_vent_parent.other_atmosmch)
				vents.Add(temp_vent)
			if(!vents.len)
				entry_vent = null
				return
			var/obj/machinery/atmospherics/components/unary/vent_pump/exit_vent = pick(vents)
			visible_message("<B>[src] scrambles into the ventillation ducts!</B>", "<span class='notice'>You hear something squeezing through the ventilation ducts.</span>")
			spawn(rand(20,60))
				var/original_location = loc
				forceMove(exit_vent)
				var/travel_time = round(get_dist(loc, exit_vent.loc) / 2)
				spawn(travel_time)
					if(!exit_vent || (exit_vent.welded && !ai_ventbreaker))
						forceMove(original_location)
						entry_vent = null
						return
					if(prob(50))
						audible_message("<span class='notice'>You hear something squeezing through the ventilation ducts.</span>")
					spawn(travel_time)
						if(!exit_vent || (exit_vent.welded && !ai_ventbreaker))
							forceMove(original_location)
							entry_vent = null
							return
						if(ai_ventbreaker && exit_vent.welded)
							exit_vent.welded = 0
							exit_vent.update_icon()
							exit_vent.visible_message("<span class='danger'>[src] smashes the welded cover off [exit_vent]!</span>")
							playsound(exit_vent.loc, 'sound/machines/airlock_alien_prying.ogg', 50, 0)
						forceMove(exit_vent.loc)
						entry_vent = null
						var/area/new_area = get_area(loc)
						if(new_area)
							new_area.Entered(src)

// --------------------------------------------------------------------------------
// --------------------- TERROR SPIDERS: ENVIRONMENT CODE -------------------------
// --------------------------------------------------------------------------------

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/DestroySurroundings()
	if(!target)
		return
	. = ..()

// --------------------------------------------------------------------------------
// --------------------- TERROR SPIDERS: MISC AI CODE -----------------------------
// --------------------------------------------------------------------------------

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/proc/UnlockBlastDoors(target_id_tag)
	for(var/obj/machinery/door/poddoor/P in GLOB.airlocks)
		if(P.density && P.id == target_id_tag && P.z == z && !P.operating)
			P.open()
