//A reference to this list is passed into area sound managers, and it's modified in a manner that preserves that reference in ash_storm.dm
GLOBAL_LIST_EMPTY(ash_storm_sounds)

#define MAXIMUM_WEATHER_SEVERITY 100
#define INVERSE_LERP(a, b, value) (((value) - (a)) / ((b) - (a)))

/atom/movable/screen/weather_holder
	icon = null
	appearance_flags = TILE_BOUND | PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	screen_loc = "CENTER,CENTER"
	plane = FULLSCREEN_PLANE
	layer = FULLSCREEN_LAYER

/datum/weather/particle
	parent_type = /datum/weather
	var/particles/weather/particle_type
	var/particles/weather/emissive_type

	var/min_severity = 1
	var/max_severity = MAXIMUM_WEATHER_SEVERITY
	var/severity_variation = 5
	var/optimal_severity = 70
	var/severity_cooldown = 5 SECONDS

	var/severity = 0
	var/last_severity_tick = 0
	var/wind_sign = 0

	/// assoc list: mob client => list of /atom/movable/screen/weather_holder
	var/list/particle_viewers = list()
	/// TIMER_LOOP id for particle_tick; null when inactive
	var/particle_timer_id

/datum/weather/particle/telegraph()
	. = ..()
	if(!particle_timer_id && (particle_type || emissive_type))
		particle_timer_id = addtimer(CALLBACK(src, PROC_REF(particle_tick)), 1 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)

/datum/weather/particle/end()
	if(particle_timer_id)
		deltimer(particle_timer_id)
		particle_timer_id = null
	remove_all_particle_viewers()
	return ..()

/datum/weather/particle/Destroy()
	if(particle_timer_id)
		deltimer(particle_timer_id)
		particle_timer_id = null
	remove_all_particle_viewers()
	return ..()

// ---- particle tick (driven by TIMER_LOOP) --------------------------------

/datum/weather/particle/proc/particle_tick()
	if(QDELETED(src) || stage == END_STAGE)
		return
	process_particles()
	update_particle_viewers()

/datum/weather/particle/proc/process_particles()
	if(last_severity_tick + severity_cooldown > world.time)
		return
	last_severity_tick = world.time
	var/new_severity = severity
	switch(stage)
		if(STARTUP_STAGE)
			new_severity += rand() * severity_variation * (1 - severity / min_severity)
		if(MAIN_STAGE)
			var/low = -severity_variation * clamp(INVERSE_LERP(min_severity, optimal_severity, severity), 0, 1)
			var/high = severity_variation * clamp(INVERSE_LERP(max_severity, optimal_severity, severity), 0, 1)
			new_severity += LERP(low, high, rand())
			new_severity = clamp(new_severity, min(new_severity, min_severity), max_severity)
		if(WIND_DOWN_STAGE)
			new_severity += rand() * -severity_variation * 4 * max(severity / min_severity, 1)
	animate_severity(new_severity)

/datum/weather/particle/proc/animate_severity(new_severity)
	if(!wind_sign)
		wind_sign = pick(-1, 1)
	severity = clamp(new_severity, 0, max_severity)
	for(var/viewer as anything in particle_viewers)
		for(var/atom/movable/screen/weather_holder/holder as anything in particle_viewers[viewer])
			var/particles/weather/particle_effect = holder.particles
			if(!isnull(particle_effect))
				particle_effect.animate_severity(severity / max_severity, wind_sign)

// ---- viewer management ----------------------------------------------------

/datum/weather/particle/proc/update_particle_viewers()
	if(stage == END_STAGE)
		remove_all_particle_viewers()
		return
	// Build set of wanted viewers (clients on impacted z-levels, inside an affected area.
	// This keeps the storm visuals confined to the outdoors / lavaland territory instead
	// of blanketing every player on the whole z-level including inside sheltered ruins.)
	var/list/wanted_viewers = list()
	for(var/mob/possible_viewer as anything in GLOB.player_list)
		if(isnull(possible_viewer.client))
			continue
		var/turf/possible_turf = get_turf(possible_viewer)
		if(isnull(possible_turf))
			continue
		if(possible_turf.z in impacted_z_levels && (possible_turf.loc in impacted_areas))
			wanted_viewers += possible_viewer
	// Remove stale viewers
	for(var/mob/old_viewer as anything in particle_viewers)
		if(!(old_viewer in wanted_viewers))
			remove_particle_viewer(old_viewer)
	// Add new viewers
	for(var/mob/new_viewer as anything in wanted_viewers)
		if(!(new_viewer in particle_viewers))
			add_particle_viewer(new_viewer)

/datum/weather/particle/proc/add_particle_viewer(mob/viewer)
	if(isnull(viewer?.client))
		return
	var/list/new_holders = list()
	if(particle_type)
		var/atom/movable/screen/weather_holder/holder = new()
		holder.particles = new particle_type()
		new_holders += holder
	if(emissive_type)
		var/atom/movable/screen/weather_holder/holder = new()
		holder.particles = new emissive_type()
		holder.layer = FULLSCREEN_LAYER + 0.1
		new_holders += holder
	for(var/atom/movable/screen/weather_holder/holder as anything in new_holders)
		viewer.client.screen += holder
	particle_viewers[viewer] = new_holders

/datum/weather/particle/proc/remove_particle_viewer(mob/viewer)
	var/list/holders = particle_viewers[viewer]
	if(isnull(holders))
		return
	if(viewer?.client)
		for(var/atom/movable/screen/weather_holder/holder as anything in holders)
			viewer.client.screen -= holder
			qdel(holder)
	else
		for(var/atom/movable/screen/weather_holder/holder as anything in holders)
			qdel(holder)
	particle_viewers -= viewer

/datum/weather/particle/proc/remove_all_particle_viewers()
	for(var/mob/viewer as anything in particle_viewers)
		remove_particle_viewer(viewer)
	particle_viewers = list()

// ---------------------------------------------------------------------------
// Base weather particle system
// ---------------------------------------------------------------------------
/particles/weather
	spawning = 0
	width = 800
	height = 800
	count = 8000

	lifespan = 30 SECONDS
	fade = 1 SECONDS
	fadein = 0.5 SECONDS

	/// Increase in speed per tick
	var/wind_strength = 0
	/// Minimum number of spawned particles per tick for easing
	var/min_spawn = 0
	/// Maximum amount of spawned particles at full strength
	var/max_spawn = 0

/particles/weather/proc/animate_severity(severity, wind_sign)
	if(severity <= 0)
		spawning = 0
		return
	var/wind = wind_strength * severity * wind_sign
	spawning = LERP(min_spawn, max_spawn, severity)
	if(islist(gravity) && length(gravity))
		gravity[1] = wind
	else
		gravity = list(wind)

// ---------------------------------------------------------------------------
// Ash-storm particles
// ---------------------------------------------------------------------------

/particles/weather/ash_storm
	icon = 'icons/effects/particles/smoke.dmi'
	icon_state = list("chill_1" = 4, "chill_2" = 3, "chill_3" = 2)
	position = generator("box", list(-510, -256, 0), list(400, 512, 0))
	grow = list(-0.01, -0.01)
	gravity = list(0, -7, 0.5)
	drift = generator("box", list(-1, -1, 0), list(1, 0, 0))
	friction = 0.3
	min_spawn = 20
	max_spawn = 400
	wind_strength = 16
	spin = generator("num", -5, 5)
	var/gravity_power = -12

/particles/weather/ash_storm/animate_severity(severity, wind_sign)
	. = ..()
	if(length(gravity) > 1)
		gravity[2] = gravity_power * severity
	else
		gravity = list(length(gravity) ? gravity[1] : 0, gravity_power * severity, 0.5)

/particles/weather/ash_storm/embers
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = list("dot" = 4, "cross" = 2, "curl" = 1)
	color = LIGHT_COLOR_FIRE
	min_spawn = 10
	max_spawn = 80

/particles/weather/ash_storm/emberfall
	min_spawn = 20
	max_spawn = 200
	wind_strength = 3
	gravity_power = -2

/particles/weather/ash_storm/embers/emberfall
	min_spawn = 20
	max_spawn = 200
	wind_strength = 3
	gravity_power = -2

// ---------------------------------------------------------------------------
// Ash storm datum
//
// parent_type is set to /datum/weather/particle so that the ash_storm inherits
// the particle framework while keeping the /datum/weather/ash_storm path
// unchanged (required by the unit test and all external references).
// ---------------------------------------------------------------------------

/datum/weather/ash_storm
	parent_type = /datum/weather/particle
	parallax_profile = "planet_embers_storm"
	name = "ash storm"
	desc = "An intense atmospheric storm lifts ash off of the planet's surface and billows it down across the area, dealing intense fire damage to the unprotected."

	particle_type = /particles/weather/ash_storm
	emissive_type = /particles/weather/ash_storm/embers

	telegraph_message = "<span class='boldwarning'>Жуткий Вой поднялся по округе. Облака горящего пепла застилают горизонт. Ищите Убежище!</span>"
	telegraph_duration = 300
	telegraph_overlay = "light_ash"

	weather_message = "<span class='userdanger'><i>Тлеющие облака раскаленного пепла вздымаются вокруг вас! Ищите Укрытие!</i></span>"
	weather_duration_lower = 600
	weather_duration_upper = 1200
	weather_overlay = "ash_storm"

	end_message = "<span class='boldannounce'>Пронзительный ветер сдувает остатки пепла и стихает до своего обычного шепота. Теперь выходить из Укрытия можно; должно быть, уже безопасно!</span>"
	end_duration = 300
	end_overlay = "light_ash"

	// The storm only hits areas inside impacted_areas (all outdoors turfs on the
	// impacted z-level). Shelters, ruins and other indoors areas are excluded.
	// Particles are additionally gated in update_particle_viewers() the same way.
	area_type = /area
	protect_indoors = TRUE
	target_trait = ZTRAIT_ASHSTORM

	immunity_type = TRAIT_ASHSTORM_IMMUNE

	probability = 90

	barometer_predictable = TRUE
	var/list/weak_sounds = list()
	var/list/strong_sounds = list()

	/// Chance per particle_tick (≈ 1 s) to strike a random turf with lightning.
	var/thunder_chance = 0.005
	/// Color applied to the thunderbolt visual
	var/thunder_color = "#7a0000"

// ---- sound management (unit-test contract) ---------------------------------

/datum/weather/ash_storm/telegraph()
	var/list/eligible_areas = list()
	for(var/z in impacted_z_levels)
		eligible_areas += SSmapping.areas_in_z["[z]"]
	for(var/i in 1 to eligible_areas.len)
		var/area/place = eligible_areas[i]
		if(place.outdoors)
			weak_sounds[place] = /datum/looping_sound/weak_outside_ashstorm
			strong_sounds[place] = /datum/looping_sound/active_outside_ashstorm
		else
			weak_sounds[place] = /datum/looping_sound/weak_inside_ashstorm
			strong_sounds[place] = /datum/looping_sound/active_inside_ashstorm
		CHECK_TICK

	//We modify this list instead of setting it to weak/strong sounds in order to preserve things that hold a reference to it
	//It's essentially a playlist for a bunch of components that chose what sound to loop based on the area a player is in
	GLOB.ash_storm_sounds += weak_sounds
	return ..()

/datum/weather/ash_storm/start()
	GLOB.ash_storm_sounds -= weak_sounds
	GLOB.ash_storm_sounds += strong_sounds
	return ..()

/datum/weather/ash_storm/wind_down()
	GLOB.ash_storm_sounds -= strong_sounds
	GLOB.ash_storm_sounds += weak_sounds
	return ..()

/datum/weather/ash_storm/end()
	GLOB.ash_storm_sounds -= weak_sounds
	for(var/turf/open/floor/plating/asteroid/basalt/basalt as anything in GLOB.dug_up_basalt)
		if(!(basalt.loc in impacted_areas) || !(basalt.z in impacted_z_levels))
			continue
		basalt.refill_dug()
	return ..()

// ---- immunity & damage -----------------------------------------------------

/datum/weather/ash_storm/proc/is_ash_immune(atom/L)
	while(L && !isturf(L))
		if(ismecha(L))
			return TRUE
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(H.easy_thermal_protection() >= FIRE_IMMUNITY_MAX_TEMP_PROTECT)
				return TRUE
		L = L.loc
	return FALSE

/datum/weather/ash_storm/weather_act(mob/living/L)
	if(is_ash_immune(L))
		return
	if(is_species(L, /datum/species/lizard/ashwalker) || HAS_TRAIT(L, TRAIT_ASHRESISTANCE))
		if(L.getStaminaLoss() < (STAMINA_CRIT - 40))
			L.adjustStaminaLoss(4)
		return
	L.adjustFireLoss(4)

// ---- thunder --------------------------------------------------------------

/datum/weather/ash_storm/particle_tick()
	. = ..()
	if(!aesthetic && stage == MAIN_STAGE && prob(thunder_chance * 100))
		thunder_act()

/datum/weather/ash_storm/proc/thunder_act()
	if(!length(impacted_areas))
		return
	var/area/picked_area = pick(impacted_areas)
	var/list/candidate_turfs = list()
	for(var/turf/open/possible in picked_area.contents)
		if(possible.z in impacted_z_levels)
			candidate_turfs += possible
			if(length(candidate_turfs) >= 200)
				break
	if(!length(candidate_turfs))
		return
	var/turf/strike_target = pick(candidate_turfs)

	strike_target.flash_lighting_fx(_range = 7, _power = 2, _color = thunder_color, _duration = 1 SECONDS)
	playsound(strike_target, 'sound/magic/lightningbolt.ogg', 100, extrarange = 10, falloff_distance = 10)
	strike_target.visible_message(span_danger("A thunderbolt strikes [strike_target]!"))
	new /obj/effect/hotspot(strike_target)

	for(var/mob/living/hit_mob in strike_target.contents)
		to_chat(hit_mob, span_userdanger("You've been struck by lightning!"))
		hit_mob.electrocute_act(50, "thunder", flags = SHOCK_TESLA | SHOCK_NOGLOVES)

	for(var/obj/item/stack/ore/hit_ore in strike_target.contents)
		if(QDELETED(hit_ore))
			continue
		hit_ore.fire_act(30000)

// ---------------------------------------------------------------------------
// Emberfalls are the result of an ash storm passing by close to the playable
// area of lavaland.  They have a 10% chance to trigger in place of an ash storm.
// ---------------------------------------------------------------------------

/datum/weather/ash_storm/emberfall
	name = "emberfall"
	desc = "A passing ash storm blankets the area in harmless embers."

	particle_type = /particles/weather/ash_storm/emberfall
	emissive_type = /particles/weather/ash_storm/embers/emberfall

	weather_message = "<span class='notice'>Гладкий пепел осыпается вокруг вас, как гротескный снег. Шторм, кажется, прошел мимо...</span>"
	weather_overlay = "light_ash"

	end_message = "<span class='notice'>Падение пепла замедляется и останавливается. Еще один слой затвердевшей сажи на базальте под вашими ногами.</span>"
	end_sound = null

	aesthetic = TRUE

	probability = 10

#undef MAXIMUM_WEATHER_SEVERITY
#undef INVERSE_LERP
