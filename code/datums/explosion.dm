#define EXPLOSION_THROW_SPEED 4

GLOBAL_LIST_EMPTY(explosions)
//Against my better judgement, I will return the explosion datum
//If I see any GC errors for it I will find you
//and I will gib you
/proc/explosion(atom/epicenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, adminlog = TRUE, ignorecap = FALSE, flame_range = 0, silent = FALSE, smoke = FALSE, mob/living/attacker = null)
	return new /datum/explosion(epicenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, adminlog, ignorecap, flame_range, silent, smoke, attacker)

//This datum creates 3 async tasks
//1 GatherSpiralTurfsProc runs spiral_range_turfs(tick_checked = TRUE) to populate the affected_turfs list
//2 CaculateExplosionBlock adds the blockings to the cached_exp_block list
//3 The main thread explodes the prepared turfs

/datum/explosion
	var/explosion_id
	var/atom/explosion_source
	var/mob/living/explosion_attacker
	var/started_at
	var/running = TRUE
	var/stopped = 0		//This is the number of threads stopped !DOESN'T COUNT THREAD 2!
	var/static/id_counter = 0

#define EX_PREPROCESS_EXIT_CHECK \
	if(!running) {\
		stopped = 2;\
		qdel(src);\
		return;\
	}

#define EX_PREPROCESS_CHECK_TICK \
	if(TICK_CHECK) {\
		stoplag();\
		EX_PREPROCESS_EXIT_CHECK\
	}

#define CREAK_DELAY 5 SECONDS //Time taken for the creak to play after explosion, if applicable.
#define FAR_UPPER 60 //Upper limit for the far_volume, distance, clamped.
#define FAR_LOWER 40 //lower limit for the far_volume, distance, clamped.
#define SHAKE_CLAMP 2.5 //The limit for how much the camera can shake for out of view booms.
#define VOLUME_UPPER 80 //The upper limit for the randomly selected volume.
#define VOLUME_LOWER 50 //The lower of the above.
/// How many on-Z mobs to process in the explosion sound loop before a CHECK_TICK (per-mob was yielding constantly on highpop).
#define EX_EXPLOSION_SOUND_BATCH 24
/// How many overloaded ticks to accumulate before stoplag() while applying ex_act (yield-every-turf made maxcaps take 10+ seconds of real time).
#define EX_EXPLOSION_TICK_BATCH 8

/**
 * Прок для звука взрыва и тряски камеры
 */
/proc/generate_explosion_near_sounds(mob/M, turf/epicenter, dist, range, shake_range = null, frequency = null, max_distance = null, sound/explosion_sound = null)
	if(!M || !epicenter || range < 0)
		return FALSE
	if(isnull(shake_range))
		shake_range = range
	if(isnull(frequency))
		frequency = get_rand_frequency()
	if(!explosion_sound)
		explosion_sound = sound(get_sfx("explosion"))
	if(dist > round(range + world.view - 2, 1))
		return

	var/baseshakeamount
	if(shake_range - dist > 0)
		baseshakeamount = sqrt((shake_range - dist) * 0.1)

	M.playsound_local(epicenter, null, 100, 1, frequency, max_distance = max_distance, S = explosion_sound)
	if(baseshakeamount > 0)
		shake_camera(M, 25, clamp(baseshakeamount, 0, 10))

/**
 * Проверка и санити чек на достягаемость звука взрыва до моба с учётом атмосферы: в космосе взрывы не слышно
 */
/proc/explosion_sound_audible(mob/M, turf/epicenter, turf/listener_turf, dist, pressure_affected = TRUE, distance_multiplier = SOUND_DEFAULT_DISTANCE_MULTIPLIER, max_distance = null)
	if(!M?.client || !M.can_hear() || !listener_turf)
		return FALSE
	var/distance = dist * distance_multiplier
	if(max_distance && distance >= max_distance)
		return FALSE
	if(!pressure_affected || distance <= 1)
		return TRUE

	var/datum/gas_mixture/hearer_env = listener_turf.return_air()
	var/datum/gas_mixture/source_env = epicenter.return_air()
	if(!hearer_env || !source_env)
		return FALSE

	return min(hearer_env.return_pressure(), source_env.return_pressure()) > SOUND_MINIMUM_PRESSURE

/**
 * Generates the nearby explosion sound and camera shake without applying gameplay effects.
 */
/proc/generate_explosion_sounds(atom/epicenter, range, shake_range = null, frequency = null)
	epicenter = get_turf(epicenter)
	if(!epicenter || range < 0)
		return
	if(isnull(shake_range))
		shake_range = range
	if(isnull(frequency))
		frequency = get_rand_frequency()
	var/sound/explosion_sound = sound(get_sfx("explosion"))

	for(var/mob/M as anything in GLOB.player_list)
		if(M.z != epicenter.z)
			continue
		var/turf/M_turf = get_turf(M)
		if(!M_turf)
			continue

		generate_explosion_near_sounds(M, epicenter, get_dist(M_turf, epicenter), range, shake_range, frequency, explosion_sound = explosion_sound)

/**
 * Прок для звуков эхо, дальнего взрыва и прочих ненаблюдаемых мощных взрывов
 */
/proc/play_explosion_distant_effect(mob/M, turf/epicenter, turf/listener_turf, dist, far_dist, shake_range, devastation_range, heavy_impact_range, frequency, creaking_explosion, sound/far_explosion_sound, sound/creaking_explosion_sound, sound/explosion_echo_sound)
	if(!M || !epicenter || !listener_turf)
		return FALSE

	var/distant_dist = far_dist + world.view
	if(dist > distant_dist)
		return FALSE

	var/baseshakeamount
	if(shake_range - dist > 0)
		baseshakeamount = sqrt((shake_range - dist) * 0.1)

	var/far_volume = clamp(far_dist/2, FAR_LOWER, FAR_UPPER)
	var/heard_explosion =  explosion_sound_audible(M, epicenter, listener_turf, dist)
	if(dist <= far_dist)
		if(heard_explosion)
			if(istype(get_area(listener_turf), /area/maintenance))
				M.playsound_local(epicenter, null, far_volume, 1, frequency, S = far_explosion_sound, distance_multiplier = 0) // Sound is muffled in maintenance tunnels.
			else if(creaking_explosion)
				M.playsound_local(epicenter, null, far_volume, 1, frequency, S = creaking_explosion_sound, distance_multiplier = 0)
			else
				M.playsound_local(epicenter, null, far_volume, 1, frequency, S = explosion_echo_sound, distance_multiplier = 0)

		if(baseshakeamount > 0 || devastation_range)
			if(!baseshakeamount) // Devastating explosions rock the station and ground
				baseshakeamount = devastation_range*3
			shake_camera(M, 10, clamp(baseshakeamount*0.25, 0, SHAKE_CLAMP))
	else
		if(heard_explosion)
			M.playsound_local(epicenter, null, far_volume, 1, frequency, S = explosion_echo_sound, distance_multiplier = 0)
		if(baseshakeamount > 0 || devastation_range)
			if(!baseshakeamount)
				baseshakeamount = devastation_range
			shake_camera(M, 10, clamp(baseshakeamount*0.25, 0, SHAKE_CLAMP))

	return heard_explosion

/**
 * Прок скрипа станционной конструкции после сильного взрыва, проигрываемый спустя время по таймеру
 */
/proc/schedule_explosion_creaking(mob/M, turf/epicenter, frequency, sound/hull_creaking_sound, delay)
	if(!M || !epicenter || !hull_creaking_sound)
		return

	addtimer(CALLBACK(M, TYPE_PROC_REF(/mob, playsound_local), epicenter, null, rand(VOLUME_LOWER, VOLUME_UPPER), 1, frequency, null, null, FALSE, hull_creaking_sound, 0), delay)

/datum/explosion/New(atom/epicenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, adminlog, ignorecap, flame_range, silent, smoke, mob/living/attacker = null)
	set waitfor = FALSE

	var/id = ++id_counter
	explosion_id = id
	explosion_source = epicenter
	explosion_attacker = attacker

	epicenter = get_turf(epicenter)
	if(!epicenter)
		return

	GLOB.explosions += src
	if(isnull(flame_range))
		flame_range = light_impact_range
	if(isnull(flash_range))
		flash_range = devastation_range

	// Archive the uncapped explosion for the doppler array
	var/orig_dev_range = devastation_range
	var/orig_heavy_range = heavy_impact_range
	var/orig_light_range = light_impact_range

	var/orig_max_distance = max(devastation_range, heavy_impact_range, light_impact_range, flash_range, flame_range)

	//Zlevel specific bomb cap multiplier
	var/cap_multiplier = SSmapping.level_trait(epicenter.z, ZTRAIT_BOMBCAP_MULTIPLIER)
	if (isnull(cap_multiplier))
		cap_multiplier = 1

	if(!ignorecap)
		devastation_range = min(GLOB.MAX_EX_DEVESTATION_RANGE * cap_multiplier, devastation_range)
		heavy_impact_range = min(GLOB.MAX_EX_HEAVY_RANGE * cap_multiplier, heavy_impact_range)
		light_impact_range = min(GLOB.MAX_EX_LIGHT_RANGE * cap_multiplier, light_impact_range)
		flash_range = min(GLOB.MAX_EX_FLASH_RANGE * cap_multiplier, flash_range)
		flame_range = min(GLOB.MAX_EX_FLAME_RANGE * cap_multiplier, flame_range)

	//DO NOT REMOVE THIS STOPLAG, IT BREAKS THINGS
	//not sleeping causes us to ex_act() the thing that triggered the explosion
	//doing that might cause it to trigger another explosion
	//this is bad
	//I would make this not ex_act the thing that triggered the explosion,
	//but everything that explodes gives us their loc or a get_turf()
	//and somethings expect us to ex_act them so they can qdel()
	//stoplag() //tldr, let the calling proc call qdel(src) before we explode
	// no - use sleep. stoplag() results in quirky things like explosions taking too long to process and hanging mid-air for no reason.
	sleep(0)

	EX_PREPROCESS_EXIT_CHECK

	started_at = REALTIMEOFDAY

	var/max_range = max(devastation_range, heavy_impact_range, light_impact_range, flame_range)

	if(adminlog)
		message_admins("Explosion with size ([devastation_range], [heavy_impact_range], [light_impact_range], [flame_range]) in [ADMIN_VERBOSEJMP(epicenter)]")
		log_admin("Explosion with size ([devastation_range], [heavy_impact_range], [light_impact_range], [flame_range]) in [loc_name(epicenter)]")

	deadchat_broadcast("<span class='deadsay bold'>An explosion with size ([devastation_range], [heavy_impact_range], [light_impact_range], [flame_range]) has occured at ([get_area(epicenter)])</span>", turf_target = get_turf(epicenter))

	var/x0 = epicenter.x
	var/y0 = epicenter.y
	var/z0 = epicenter.z
	var/area/areatype = get_area(epicenter)
	SSblackbox.record_feedback("associative", "explosion", 1, list("dev" = devastation_range, "heavy" = heavy_impact_range, "light" = light_impact_range, "flash" = flash_range, "flame" = flame_range, "orig_dev" = orig_dev_range, "orig_heavy" = orig_heavy_range, "orig_light" = orig_light_range, "x" = x0, "y" = y0, "z" = z0, "area" = areatype.type, "time" = TIME_STAMP("YYYY-MM-DD hh:mm:ss", 1)))

	// Play sounds; we want sounds to be different depending on distance so we will manually do it ourselves.
	// Stereo users will also hear the direction of the explosion!

	// Calculate far explosion sound range. Only allow the sound effect for heavy/devastating explosions.
	// 3/7/14 will calculate to 80 + 35

	var/far_dist = 0
	far_dist += heavy_impact_range * 15 // Large explosions carry further
	far_dist += devastation_range * 20

	if(!silent)
		var/frequency = get_rand_frequency()
		var/sound/explosion_sound = sound(get_sfx("explosion"))
		var/sound/far_explosion_sound = sound('sound/effects/explosionfar.ogg')
		var/sound/creaking_explosion_sound = sound(get_sfx("explosion_creaking"))
		var/sound/hull_creaking_sound = sound(get_sfx("hull_creaking"))
		var/sound/explosion_echo_sound = sound('sound/effects/explosion_distant.ogg')
		var/on_station = SSmapping.level_trait(epicenter.z, ZTRAIT_STATION)
		// The light range is the user-facing bombcap value (the third number in bomb notation).
		var/cap_explosion = orig_light_range >= GLOB.MAX_EX_LIGHT_RANGE * cap_multiplier
		var/sound/near_explosion_sound = cap_explosion ? sound('sound/effects/explosion3.ogg') : explosion_sound
		var/creaking_explosion = FALSE
		var/near_dist = round(max_range + world.view - 2, 1)
		var/medium_dist = far_dist
		var/explosion_strength = devastation_range * 30 + heavy_impact_range * 5
		var/guaranteed_creaking_strength = (2 * 30) + (4 * 5) // Минимум как у бомбы ниндзя

		if(on_station && (explosion_strength >= guaranteed_creaking_strength || prob(explosion_strength)))
			creaking_explosion = TRUE // prob over 100 always returns true

		var/explosion_sound_batch = 0
		for(var/mob/M as anything in GLOB.player_list)
			// Early z-level filter before expensive get_turf()
			if(M.z != z0)
				continue
			var/turf/M_turf = get_turf(M)
			if(!M_turf)
				continue
			var/dist = get_dist(M_turf, epicenter)
			var/heard_explosion = FALSE
			if(dist <= near_dist)
				generate_explosion_near_sounds(M, epicenter, dist, max_range, orig_max_distance, frequency, explosion_sound = near_explosion_sound)
				if(creaking_explosion)
					heard_explosion = explosion_sound_audible(M, epicenter, M_turf, dist, max_distance = orig_max_distance)
			else
				heard_explosion = play_explosion_distant_effect(M, epicenter, M_turf, dist, medium_dist, orig_max_distance, devastation_range, heavy_impact_range, frequency, creaking_explosion && on_station, far_explosion_sound, creaking_explosion_sound, explosion_echo_sound)

			if(creaking_explosion && on_station && heard_explosion) // 5 seconds after the bang, the station begins to creak
				schedule_explosion_creaking(M, epicenter, frequency, hull_creaking_sound, CREAK_DELAY)

			if(++explosion_sound_batch >= EX_EXPLOSION_SOUND_BATCH)
				explosion_sound_batch = 0
				EX_PREPROCESS_CHECK_TICK

		EX_PREPROCESS_CHECK_TICK

	//postpone processing for a bit
	var/postponeCycles = max(round(devastation_range/8),1)
	SSlighting.postpone(postponeCycles)
	SSmachines.postpone(postponeCycles)

	if(heavy_impact_range > 1)
		var/datum/effect_system/explosion/E
		if(smoke)
			E = new /datum/effect_system/explosion/smoke
		else
			E = new
		E.set_up(epicenter)
		E.start()

	EX_PREPROCESS_CHECK_TICK

	//flash mobs
	if(flash_range)
		for(var/mob/living/L in viewers(flash_range, epicenter))
			L.flash_act()

	EX_PREPROCESS_CHECK_TICK

	var/list/exploded_this_tick = list()	//open turfs that need to be blocked off while we sleep
	var/list/affected_turfs = GatherSpiralTurfs(max_range, epicenter)

	var/reactionary = CONFIG_GET(flag/reactionary_explosions)
	var/list/cached_exp_block

	if(reactionary)
		cached_exp_block = CaculateExplosionBlock(affected_turfs)

	//lists are guaranteed to contain at least 1 turf at this point

	var/iteration = 0
	var/explosion_tick_batch = 0
	var/affTurfLen = length(affected_turfs)
	var/expBlockLen = length(cached_exp_block)
	for(var/TI in affected_turfs)
		var/turf/T = TI
		++iteration
		var/init_dist = cheap_hypotenuse(T.x, T.y, x0, y0)
		var/dist = init_dist

		if(reactionary)
			var/turf/Trajectory = T
			while(Trajectory != epicenter)
				Trajectory = get_step_towards(Trajectory, epicenter)
				dist += cached_exp_block[Trajectory]

		var/flame_dist = dist < flame_range
		var/throw_dist = dist

		if(dist < devastation_range)
			dist = EXPLODE_DEVASTATE
		else if(dist < heavy_impact_range)
			dist = EXPLODE_HEAVY
		else if(dist < light_impact_range)
			dist = EXPLODE_LIGHT
		else
			dist = EXPLODE_NONE

		//------- EX_ACT AND TURF FIRES -------

		if((T == epicenter) && !QDELETED(explosion_source) && ismovable(explosion_source) && (get_turf(explosion_source) == T)) // Ensures explosives detonating from bags trigger other explosives in that bag
			var/list/atoms = list()
			for(var/atom/A in explosion_source.loc)		// the ismovableatom check 2 lines above makes sure we don't nuke an /area
				atoms += A
			for(var/i in atoms)
				var/atom/A = i
				if(QDELETED(A))
					continue
				A.ex_act(dist, null, src)
				if(QDELETED(A) || !ismovable(A))
					continue
				var/atom/movable/AM = A
				LAZYADD(AM.acted_explosions, explosion_id)

		if(flame_dist && prob(40) && !isspaceturf(T) && !T.density)
			new /obj/effect/hotspot(T) //Mostly for ambience!

		if(dist > EXPLODE_NONE)
			T.explosion_level = max(T.explosion_level, dist)	//let the bigger one have it
			T.explosion_id = id
			T.ex_act(dist, origin = src)
			exploded_this_tick += T

		//--- THROW ITEMS AROUND ---

		var/throw_dir = get_dir(epicenter,T)
		for(var/obj/item/I in T)
			if(QDELETED(I) || I.anchored)
				continue
			var/throw_range = rand(throw_dist, max_range)
			var/turf/throw_at = get_ranged_target_turf(I, throw_dir, throw_range)
			I.throw_speed = EXPLOSION_THROW_SPEED //Temporarily change their throw_speed for embedding purposes (Reset when it finishes throwing, regardless of hitting anything)
			I.throw_at(throw_at, throw_range, EXPLOSION_THROW_SPEED)

		//wait for the lists to repop
		var/break_condition
		if(reactionary)
			//If we've caught up to the density checker thread and there are no more turfs to process
			break_condition = iteration == expBlockLen && iteration < affTurfLen
		else
			//If we've caught up to the turf gathering thread and it's still running
			break_condition = iteration == affTurfLen && !stopped

		var/should_stoplag = FALSE
		if(break_condition)
			explosion_tick_batch = 0
			should_stoplag = TRUE
		else if(TICK_CHECK)
			explosion_tick_batch++
			if(explosion_tick_batch >= EX_EXPLOSION_TICK_BATCH)
				explosion_tick_batch = 0
				should_stoplag = TRUE
		else
			explosion_tick_batch = 0

		if(should_stoplag)
			stoplag()

			if(!running)
				break

			//update the trackers
			affTurfLen = length(affected_turfs)
			expBlockLen = length(cached_exp_block)

			if(break_condition)
				if(reactionary)
					//until there are more block checked turfs than what we are currently at
					//or the explosion has stopped
					UNTIL(iteration < affTurfLen || !running)
				else
					//until there are more gathered turfs than what we are currently at
					//or there are no more turfs to gather/the explosion has stopped
					UNTIL(iteration < expBlockLen || stopped)

				if(!running)
					break

				//update the trackers
				affTurfLen = length(affected_turfs)
				expBlockLen = length(cached_exp_block)

			var/circumference = (PI * (init_dist + 4) * 2) //+4 to radius to prevent shit gaps
			if(exploded_this_tick.len > circumference)	//only do this every revolution
				for(var/Unexplode in exploded_this_tick)
					var/turf/UnexplodeT = Unexplode
					UnexplodeT.explosion_level = 0
				exploded_this_tick.Cut()

	//unfuck the shit
	for(var/Unexplode in exploded_this_tick)
		var/turf/UnexplodeT = Unexplode
		UnexplodeT.explosion_level = 0
	exploded_this_tick.Cut()

	var/took = (REALTIMEOFDAY - started_at) / 10

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_EXPLOSION,epicenter, devastation_range, heavy_impact_range, light_impact_range, took, orig_dev_range, orig_heavy_range, orig_light_range)

	//You need to press the DebugGame verb to see these now....they were getting annoying and we've collected a fair bit of data. Just -test- changes to explosion code using this please so we can compare
	if(GLOB.Debug2)
		log_world("## DEBUG: Explosion([x0],[y0],[z0])(d[devastation_range],h[heavy_impact_range],l[light_impact_range]): Took [took] seconds.")

	if(running)	//if we aren't in a hurry
		//Machines which report explosions.
		for(var/obj/machinery/doppler_array/A as anything in GLOB.doppler_arrays)
			A.sense_explosion(epicenter, devastation_range, heavy_impact_range, light_impact_range, took,orig_dev_range, orig_heavy_range, orig_light_range)

	++stopped
	qdel(src)

#undef CREAK_DELAY
#undef FAR_UPPER
#undef FAR_LOWER
#undef SHAKE_CLAMP
#undef VOLUME_UPPER
#undef VOLUME_LOWER
#undef EX_EXPLOSION_SOUND_BATCH
#undef EX_EXPLOSION_TICK_BATCH

#undef EX_PREPROCESS_EXIT_CHECK
#undef EX_PREPROCESS_CHECK_TICK

//asyncly populate the affected_turfs list
/datum/explosion/proc/GatherSpiralTurfs(range, turf/epicenter)
	set waitfor = FALSE
	. = list()
	spiral_range_turfs(range, epicenter, outlist = ., tick_checked = TRUE)
	++stopped

/datum/explosion/proc/CaculateExplosionBlock(list/affected_turfs)
	set waitfor = FALSE

	. = list()
	var/processed = 0
	while(running)
		var/I
		for(I in (processed + 1) to length(affected_turfs)) // we cache the explosion block rating of every turf in the explosion area
			var/turf/T = affected_turfs[I]
			var/current_exp_block = T.density ? T.explosion_block : 0

			for(var/obj/O in T)
				var/the_block = O.explosion_block
				current_exp_block += the_block == EXPLOSION_BLOCK_PROC ? O.GetExplosionBlock() : the_block

			.[T] = current_exp_block

			if(TICK_CHECK)
				break

		processed = I
		stoplag()

/datum/explosion/Destroy()
	running = FALSE
	if(stopped < 2)	//wait for main thread and spiral_range thread
		return QDEL_HINT_IWILLGC
	GLOB.explosions -= src
	explosion_source = null
	explosion_attacker = null
	return ..()

/client/proc/check_bomb_impacts()
	set name = "Check Bomb Impact"
	set category = "Debug.7) Testing"

	var/newmode = alert("Use reactionary explosions?","Check Bomb Impact", "Yes", "No")
	var/turf/epicenter = get_turf(mob)
	if(!epicenter)
		return

	var/dev = 0
	var/heavy = 0
	var/light = 0
	var/list/choices = list("Small Bomb","Medium Bomb","Big Bomb","Custom Bomb")
	var/choice = input("Bomb Size?") in choices
	switch(choice)
		if(null)
			return FALSE
		if("Small Bomb")
			dev = 1
			heavy = 2
			light = 3
		if("Medium Bomb")
			dev = 2
			heavy = 3
			light = 4
		if("Big Bomb")
			dev = 3
			heavy = 5
			light = 7
		if("Custom Bomb")
			dev = tgui_input_number("Devastation range (Tiles):")
			heavy = tgui_input_number("Heavy impact range (Tiles):")
			light = tgui_input_number("Light impact range (Tiles):")

	var/max_range = max(dev, heavy, light)
	var/x0 = epicenter.x
	var/y0 = epicenter.y
	var/list/wipe_colours = list()
	for(var/turf/T in spiral_range_turfs(max_range, epicenter))
		wipe_colours += T
		var/dist = cheap_hypotenuse(T.x, T.y, x0, y0)

		if(newmode == "Yes")
			var/turf/TT = T
			while(TT != epicenter)
				TT = get_step_towards(TT,epicenter)
				if(TT.density)
					dist += TT.explosion_block

				for(var/obj/O in T)
					var/the_block = O.explosion_block
					dist += the_block == EXPLOSION_BLOCK_PROC ? O.GetExplosionBlock() : the_block

		if(dist < dev)
			T.color = "red"
			T.maptext = MAPTEXT("Dev")
		else if (dist < heavy)
			T.color = "yellow"
			T.maptext = MAPTEXT("Heavy")
		else if (dist < light)
			T.color = "blue"
			T.maptext = MAPTEXT("Light")
		else
			continue

	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(wipe_color_and_text), wipe_colours), 100)

/proc/wipe_color_and_text(list/atom/wiping)
	for(var/i in wiping)
		var/atom/A = i
		A.color = null
		A.maptext = ""

/proc/dyn_explosion(turf/epicenter, power, flash_range, adminlog = TRUE, ignorecap = FALSE, flame_range = 0, silent = FALSE, smoke = TRUE) //BLUEMOON CHANGE ранее был ignorecap = TRUE (нелимитированные взрывы - плохо)
	if(!power)
		return
	var/range = 0
	range = round((2 * power)**GLOB.DYN_EX_SCALE)
	explosion(epicenter, round(range * 0.25), round(range * 0.5), round(range), flash_range*range, adminlog, ignorecap, flame_range*range, silent, smoke)

// Using default dyn_ex scale:
// 100 explosion power is a (5, 10, 20) explosion.
// 75 explosion power is a (4, 8, 17) explosion.
// 50 explosion power is a (3, 7, 14) explosion.
// 25 explosion power is a (2, 5, 10) explosion.
// 10 explosion power is a (1, 3, 6) explosion.
// 5 explosion power is a (0, 1, 3) explosion.
// 1 explosion power is a (0, 0, 1) explosion.
