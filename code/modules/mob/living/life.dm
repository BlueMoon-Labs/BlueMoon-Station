///Фаеров подряд, которые бакет держит моба на z-уровне без клиентов, прежде чем
///перепроверить обстановку. Такой моб не делает ничего, кроме handle_fire, а
///горящий из бакета исключён явно.
#define LIFE_EMPTY_Z_SKIP_FIRES 4
///Каденс Life живого моба вдали от игроков, в фаерах SSmobs (4 фаера = 8 секунд).
#define LIFE_FAR_ALIVE_CADENCE 4
///Каденс Life трупа вдали от игроков, в фаерах SSmobs (15 фаеров = 30 секунд).
#define LIFE_FAR_DEAD_CADENCE 15
///Каденс Life трупа рядом с игроком, в фаерах SSmobs.
#define LIFE_NEAR_DEAD_CADENCE 4
///Ближайший times_fired строго больше current, на котором (fire + phase) % cadence == 0.
///Корректен только когда сам current НЕ кратен каденсу - то есть в ветке пропуска.
#define LIFE_NEXT_DUE_FIRE(current, phase, cadence) ((current) + ((cadence) - (((current) + (phase)) % (cadence))))

/**
  * Called by SSmobs at an interval of 2 seconds.
  * Splits off into PhysicalLife() and BiologicalLife(). Override those instead of this.
  */
/mob/living/proc/Life(seconds, times_fired)
	SHOULD_NOT_SLEEP(TRUE)
	if(QDELETED(src)) // моб qdel-нут посреди фаера SSmobs, но currentrun ещё держит хардреф
		return

	// Фаеры, которые бакет пропустил мимо Life() целиком, для учёта долга времени
	// ничем не отличаются от фаеров, на которых Life() зашёл и сразу вышел.
	// Считается до выхода по mob_transforming, иначе долгая трансформация
	// раздула бы долг так, будто моба всё это время держал бакет.
	var/fires_elapsed = life_last_fire ? max(1, times_fired - life_last_fire) : 1
	life_last_fire = times_fired
	var/skipped_seconds = seconds * fires_elapsed
	// Бронь снимается на каждом входе: ветки троттла ниже выставят её заново, а
	// клиентские и ближние мобы останутся с нулём - им положен каждый фаер.
	life_next_fire = 0

	if(mob_transforming)
		return

	// BLUEMOON OPTIMIZATION: throttle clientless mobs far from players.
	// Троттл СОХРАНЯЕТ игровое время: пропущенные секунды копятся в
	// life_time_debt и доезжают следующим обработанным тиком, а ленивые фазовые
	// бакеты размазывают дальних мобов по тикам вместо синхронного залпа
	// каждый N-й фаер (залп давал p95 ~50мс при медиане ~4мс).
	if(!client)
		var/turf/our_turf = get_turf(src)
		if(our_turf)
			var/list/clients_on_z = SSmobs.clients_by_zlevel
			if(islist(clients_on_z) && our_turf.z <= length(clients_on_z))
				if(!length(clients_on_z[our_turf.z]))
					// No players on this Z-level: skip everything except fire
					if(on_fire)
						handle_fire()
					else
						life_next_fire = times_fired + LIFE_EMPTY_Z_SKIP_FIRES
					return
				// Lever 4: memoize proximity (TTL 2 fires); the throttle only acts on
				// the result every 4th/15th fire, so hitting the grid every fire for
				// hundreds of clientless mobs was pure overhead.
				var/nearby_player = has_nearby_player_cached(times_fired)
				// Players on Z-level but none nearby: stagger processing
				if(!nearby_player && !should_bypass_life_throttle())
					if(stat == DEAD)
						// Dead far from players: process once per 30 sec
						if((times_fired + life_stagger_phase) % LIFE_FAR_DEAD_CADENCE != 0)
							life_time_debt += skipped_seconds
							life_next_fire = LIFE_NEXT_DUE_FIRE(times_fired, life_stagger_phase, LIFE_FAR_DEAD_CADENCE)
							return
						if(fires_elapsed > 1) //фаеры, съеденные бакетом, тоже игровое время
							life_time_debt += seconds * (fires_elapsed - 1)
						var/dead_seconds = seconds + life_time_debt
						life_time_debt = 0
						life_next_fire = times_fired + LIFE_FAR_DEAD_CADENCE
						BiologicalLife(dead_seconds, times_fired)
						return
					// Alive far from players: process once per 8 sec
					if((times_fired + life_stagger_phase) % LIFE_FAR_ALIVE_CADENCE != 0)
						life_time_debt += skipped_seconds
						life_next_fire = LIFE_NEXT_DUE_FIRE(times_fired, life_stagger_phase, LIFE_FAR_ALIVE_CADENCE)
						return
					// Фаер настал - бронируем следующий сразу. Иначе SSmobs звал бы
					// Life() и на промежуточных фаерах, только чтобы тот ушёл в
					// бакет: 2 вызова из 4 вместо одного.
					life_next_fire = times_fired + LIFE_FAR_ALIVE_CADENCE
				// Lever 1: a corpse NEAR a player - slow decay cadence (organs/rot/
				// disease are slow; defib and the zombie organ run via SSobj, not
				// Life). Exempt corpses carrying a dead-process reagent (revival).
				else if(nearby_player && stat == DEAD && !should_bypass_life_throttle() && !dead_life_is_time_sensitive())
					if((times_fired + life_stagger_phase) % LIFE_NEAR_DEAD_CADENCE != 0)
						life_time_debt += skipped_seconds
						life_next_fire = LIFE_NEXT_DUE_FIRE(times_fired, life_stagger_phase, LIFE_NEAR_DEAD_CADENCE)
						return
					life_next_fire = times_fired + LIFE_NEAR_DEAD_CADENCE
	// END BLUEMOON OPTIMIZATION

	// Фаеры, которые бакет пропустил мимо Life() до этого прохода, тоже игровое
	// время: без этого наступивший фаер каденса (или пробуждение через
	// wake_life) молча съедал бы 6-28 секунд метаболизма.
	if(fires_elapsed > 1)
		life_time_debt += seconds * (fires_elapsed - 1)

	// накопленный долг времени доезжает первым же полноценным тиком
	if(life_time_debt)
		seconds += life_time_debt
		life_time_debt = 0

	. = SEND_SIGNAL(src, COMSIG_LIVING_LIFE, seconds, times_fired)
	// Dead clientless mobs: only need BiologicalLife for rot/disease/organ decay, skip expensive PhysicalLife and status effects
	if(stat == DEAD && !client)
		if(!(. & COMPONENT_INTERRUPT_LIFE_BIOLOGICAL))
			BiologicalLife(seconds, times_fired)
		return
	if(!(. & COMPONENT_INTERRUPT_LIFE_PHYSICAL))
		PhysicalLife(seconds, times_fired)
	if(!(. & COMPONENT_INTERRUPT_LIFE_BIOLOGICAL))
		BiologicalLife(seconds, times_fired)
	if(!(. & COMPONET_INTERRUPT_STATUS_EFFECTS))
		handle_status_effects() //all special effects, stun, knockdown, jitteryness, hallucination, sleeping, etc
	// CODE BELOW SHOULD ONLY BE THINGS THAT SHOULD HAPPEN NO MATTER WHAT AND CAN NOT BE SUSPENDED!
	// Otherwise, it goes into one of the two split Life procs!

	if (client)
		var/turf/T = get_turf(src)
		if(!T)
			for(var/obj/effect/landmark/error/E in GLOB.landmarks_list)
				forceMove(E.loc)
				break
			var/msg = "[key_name_admin(src)] [ADMIN_JMP(src)] was found to have no .loc with an attached client, if the cause is unknown it would be wise to ask how this was accomplished."
			message_admins(msg)
			INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(send2tgs_adminless_only), "Mob", msg, R_ADMIN)
			log_game("[key_name(src)] was found to have no .loc with an attached client.")

		// This is a temporary error tracker to make sure we've caught everything
		else if (registered_z != T.z)
#ifdef TESTING
			message_admins("[src] [ADMIN_FLW(src)] has somehow ended up in Z-level [T.z] despite being registered in Z-level [registered_z]. If you could ask them how that happened and notify coderbus, it would be appreciated.")
#endif
			log_game("Z-TRACKING: [src] has somehow ended up in Z-level [T.z] despite being registered in Z-level [registered_z].")
			update_z(T.z)
	else if (registered_z)
		log_game("Z-TRACKING: [src] of type [src.type] has a Z-registration despite not having a client.")
		update_z(null)

///Дальний моб, которому нельзя резать каденс Life: горит, не в сознании
///(крит/агония) или ведёт активный бой - его состояние меняется прямо сейчас,
///и восьмисекундная дискретизация была бы заметна снаружи.
/mob/living/proc/should_bypass_life_throttle()
	if(on_fire)
		return TRUE
	if(stat != CONSCIOUS && stat != DEAD)
		return TRUE
	if(ai_controller && ai_controller.ai_status == AI_STATUS_ON && !isnull(ai_controller.blackboard[BB_AI_CURRENT_TARGET]))
		return TRUE
	return FALSE

/**
  * Handles biological life processes like chemical metabolism, breathing, etc
  * Returns TRUE or FALSE based on if we were interrupted. This is used by overridden variants to check if they should stop.
  */
/mob/living/proc/BiologicalLife(delta_time, times_fired)
	SEND_SIGNAL(src,COMSIG_LIVING_BIOLOGICAL_LIFE, delta_time, times_fired)
	handle_diseases()// DEAD check is in the proc itself; we want it to spread even if the mob is dead, but to handle its disease-y properties only if you're not.

	handle_wounds()

	// Everything after this shouldn't process while dead (as of the time of writing)
	if(stat == DEAD)
		return FALSE

	//Mutations and radiation
	handle_mutations_and_radiation()

	//Breathing, if applicable
	handle_breathing(times_fired)

	if (QDELETED(src)) // diseases can qdel the mob via transformations
		return FALSE

	//Random events (vomiting etc)
	handle_random_events()

	//stuff in the stomach
	handle_stomach()

	handle_block_parry(delta_time)

	handle_traits() // eye, ear, brain damages

	return TRUE

/**
  * Handles physical life processes like being on fire. Don't ask why this is considered "Life".
  * Returns TRUE or FALSE based on if we were interrupted. This is used by overridden variants to check if they should stop.
  */
/mob/living/proc/PhysicalLife(seconds, times_fired)
	SEND_SIGNAL(src,COMSIG_LIVING_PHYSICAL_LIFE, seconds, times_fired)
	if(digitalinvis)
		handle_diginvis() //AI becomes unable to see mob

	if((movement_type & FLYING) && !(movement_type & FLOATING))	//TODO: Better floating
		INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, float), TRUE)

	if(!loc)
		return FALSE

	// Skip expensive environment/gravity processing for clientless mobs on Z-levels with no players
	if(!client)
		var/turf/T = get_turf(src)
		if(T)
			var/list/clients_on_z = SSmobs.clients_by_zlevel
			if(islist(clients_on_z) && T.z <= length(clients_on_z) && !length(clients_on_z[T.z]))
				if(on_fire)
					handle_fire()
				return TRUE

	//Handle temperature/pressure differences between body and environment
	if(!environment_processing_immune)
		var/datum/gas_mixture/environment = loc.return_air()
		if(environment)
			handle_environment(environment)

	handle_fire()

	handle_gravity()

	if(machine)
		machine.check_eye(src)
	return TRUE

/mob/living/proc/handle_breathing(times_fired)
	return

/mob/living/proc/handle_mutations_and_radiation()
	radiation = 0 //so radiation don't accumulate in simple animals
	return

/mob/living/proc/handle_diseases()
	return

/mob/living/proc/handle_wounds()
	return

/mob/living/proc/handle_diginvis()
	if(!digitaldisguise)
		src.digitaldisguise = image(loc = src)
	src.digitaldisguise.override = 1
	for(var/mob/living/silicon/ai/AI in GLOB.player_list)
		AI.client.images |= src.digitaldisguise


/mob/living/proc/handle_random_events()
	return

/mob/living/proc/handle_environment(datum/gas_mixture/environment)
	return

/mob/living/proc/handle_fire()
	if(fire_stacks < 0) //If we've doused ourselves in water to avoid fire, dry off slowly
		fire_stacks = min(0, fire_stacks + 1)//So we dry ourselves back to default, nonflammable.
	if(!on_fire)
		return TRUE
	if(fire_stacks > 0)
		adjust_fire_stacks(-0.1) //the fire is slowly consumed
	else
		ExtinguishMob()
		return
	var/datum/gas_mixture/G = loc.return_air() // Check if we're standing in an oxygenless environment
	if(!G.get_moles(GAS_O2, 1))
		ExtinguishMob() //If there's no oxygen in the tile we're on, put out the fire
		return
	var/turf/location = get_turf(src)
	location.hotspot_expose(700, 10, 1)

/mob/living/proc/handle_stomach()
	return

/*
 * this updates some effects: mostly old stuff such as drunkness, druggy, stuttering, etc.
 * that should be converted to status effect datums one day.
 */
/mob/living/proc/handle_status_effects()
	if(confused)
		confused = max(0, confused - 1)

	if(stuttering)
		stuttering = max(stuttering-1, 0)

	if(slurring)
		slurring = max(slurring-1,0)

	if(cultslurring)
		cultslurring = max(cultslurring-1, 0)

	if(clockcultslurring)
		clockcultslurring = max(clockcultslurring-1, 0)

/mob/living/proc/handle_traits()
	//Eyes
	if(eye_blind)			//blindness, heals slowly over time
		if(!stat && !(HAS_TRAIT(src, TRAIT_BLIND)))
			eye_blind = max(eye_blind-1,0)
			if(client && !eye_blind)
				clear_alert("blind")
				clear_fullscreen("blind")
		else
			eye_blind = max(eye_blind-1,1)
	else if(eye_blurry)			//blurry eyes heal slowly
		eye_blurry = max(eye_blurry-1, 0)
		if(client)
			update_eye_blur()

/mob/living/proc/update_damage_hud()
	return

/**
  * Кэширующая версия refresh_gravity(): помнит loc и результат, чтобы
  * handle_gravity() не опрашивал has_gravity() на каждом тике Life, и не зовёт
  * update_gravity() впустую, когда значение не изменилось.
  */
/mob/living/refresh_gravity(skip_if_unchanged = FALSE)
	gravity_cache_dirty = FALSE
	var/gravity = mob_has_gravity()
	if(skip_if_unchanged && gravity == cached_gravity_value)
		return gravity
	cached_gravity_value = gravity
	update_gravity(gravity)
	return gravity

/mob/living/proc/handle_gravity()
	// has_gravity() платился на каждого моба каждый тик Life. Пока моб стоит на
	// том же месте, пересчитывать нечего: всё, что меняет гравитацию без
	// перемещения (генератор, магботы, forced_gravity, смена вида), зовёт
	// refresh_gravity() само, а перемещение поднимает gravity_cache_dirty.
	if(gravity_cache_dirty)
		refresh_gravity(skip_if_unchanged = TRUE)
	if(cached_gravity_value > STANDARD_GRAVITY)
		gravity_animate()
		handle_high_gravity(cached_gravity_value)

/mob/living/proc/gravity_animate()
	if(!get_filter("gravity"))
		add_filter("gravity",1, GRAVITY_MOTION_BLUR)
	INVOKE_ASYNC(src, PROC_REF(gravity_pulse_animation))

/mob/living/proc/gravity_pulse_animation()
	animate(get_filter("gravity"), y = 1, time = 10)
	sleep(10)
	animate(get_filter("gravity"), y = 0, time = 10)

/mob/living/proc/handle_high_gravity(gravity)
	if(gravity >= GRAVITY_DAMAGE_TRESHOLD) //Aka gravity values of 3 or more
		var/grav_stregth = gravity - GRAVITY_DAMAGE_TRESHOLD
		adjustBruteLoss(min(grav_stregth,3))
