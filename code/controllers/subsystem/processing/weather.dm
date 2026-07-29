#define STARTUP_STAGE 1
#define MAIN_STAGE 2
#define WIND_DOWN_STAGE 3
#define END_STAGE 4

//Used for all kinds of weather, ex. lavaland ash storms.
PROCESSING_SUBSYSTEM_DEF(weather)
	name = "Weather"
	flags = SS_BACKGROUND
	wait = 10
	runlevels = RUNLEVEL_GAME
	var/list/eligible_zlevels = list()
	var/list/next_hit_by_zlevel = list() //Used by barometers to know when the next storm is coming
	/// Weather used to call one datum which synchronously walked every living mob.
	/// Keep the active datum and its snapshot across MC resumes so the budget can
	/// be checked between victims instead of after a whole population scan.
	var/datum/weather/current_weather
	var/list/current_weather_mobs = list()

/datum/controller/subsystem/processing/weather/fire(resumed = FALSE)
	var/slice_start_usage = TICK_USAGE
	if(!resumed)
		currentrun = processing.Copy()
		current_weather = null
		current_weather_mobs = list()
		current_pass_cost_ms = 0
	var/profiling = profile_armed

	while(current_weather || length(currentrun))
		if(!current_weather)
			current_weather = currentrun[length(currentrun)]
			currentrun.len--
			if(QDELETED(current_weather) || current_weather.aesthetic || current_weather.stage != MAIN_STAGE)
				current_weather = null
				continue
			current_weather_mobs = GLOB.mob_living_list.Copy()

		// The stage may change while a long population scan is suspended.
		if(QDELETED(current_weather) || current_weather.aesthetic || current_weather.stage != MAIN_STAGE)
			current_weather = null
			current_weather_mobs = list()
			continue

		while(length(current_weather_mobs))
			var/mob/living/living_mob = current_weather_mobs[length(current_weather_mobs)]
			current_weather_mobs.len--
			if(!QDELETED(living_mob))
				var/item_type
				var/item_start_usage
				if(profiling)
					item_type = "[current_weather.type] -> [living_mob.type]"
					item_start_usage = TICK_USAGE
				if(current_weather.can_weather_act(living_mob))
					current_weather.weather_act(living_mob)
				if(profiling)
					profile_note(item_type, max(0, TICK_DELTA_TO_MS(TICK_USAGE - item_start_usage)))
			if(MC_TICK_CHECK)
				current_pass_cost_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - slice_start_usage))
				return

		current_weather = null
		current_weather_mobs = list()

	// start random weather on relevant levels
	for(var/z in eligible_zlevels)
		var/possible_weather = eligible_zlevels[z]
		var/datum/weather/W = pickweight(possible_weather)
		run_weather(W, list(text2num(z)))
		eligible_zlevels -= z
		var/randTime = rand(3000, 6000)
		addtimer(CALLBACK(src, PROC_REF(make_eligible), z, possible_weather), randTime + initial(W.weather_duration_upper), TIMER_UNIQUE) //Around 5-10 minutes between weathers
		next_hit_by_zlevel["[z]"] = world.time + randTime + initial(W.telegraph_duration)

	current_pass_cost_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - slice_start_usage))
	on_pass_finished(length(GLOB.mob_living_list))

/datum/controller/subsystem/processing/weather/Initialize(start_timeofday)
	for(var/V in subtypesof(/datum/weather))
		var/datum/weather/W = V
		var/probability = initial(W.probability)
		var/target_trait = initial(W.target_trait)

		// any weather with a probability set may occur at random
		if (probability)
			for(var/z in SSmapping.levels_by_trait(target_trait))
				LAZYINITLIST(eligible_zlevels["[z]"])
				eligible_zlevels["[z]"][W] = probability
	return ..()

/datum/controller/subsystem/processing/weather/proc/run_weather(datum/weather/weather_datum_type, z_levels)
	if (istext(weather_datum_type))
		for (var/V in subtypesof(/datum/weather))
			var/datum/weather/W = V
			if (initial(W.name) == weather_datum_type)
				weather_datum_type = V
				break
	if (!ispath(weather_datum_type, /datum/weather))
		CRASH("run_weather called with invalid weather_datum_type: [weather_datum_type || "null"]")

	if (isnull(z_levels))
		z_levels = SSmapping.levels_by_trait(initial(weather_datum_type.target_trait))
	else if (isnum(z_levels))
		z_levels = list(z_levels)
	else if (!islist(z_levels))
		CRASH("run_weather called with invalid z_levels: [z_levels || "null"]")

	var/datum/weather/W = new weather_datum_type(z_levels)
	W.telegraph()

/datum/controller/subsystem/processing/weather/proc/make_eligible(z, possible_weather)
	eligible_zlevels[z] = possible_weather
	next_hit_by_zlevel["[z]"] = null

/datum/controller/subsystem/processing/weather/proc/get_weather(z, area/active_area)
	var/datum/weather/A
	for(var/V in processing)
		var/datum/weather/W = V
		if((z in W.impacted_z_levels) && W.area_type == active_area.type)
			A = W
			break
	return A

/datum/controller/subsystem/processing/weather/proc/get_weather_by_type(datum/weather/weather_datum_type)
	for(var/V in processing)
		if(istype(V,weather_datum_type))
			return V
