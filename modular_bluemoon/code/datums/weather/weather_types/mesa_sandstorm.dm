/datum/weather/ash_storm/mesa_sandstorm
	name = "sandstorm"
	desc = "A localized sandstorm is kicking up dust across the surface."

	telegraph_message = "<span class='boldwarning'>Ветер усиливается, поднимая тучи песка с поверхности.</span>"
	telegraph_duration = 300
	telegraph_overlay = "dust_low"

	weather_message = "<span class='userdanger'><i>Вас окутывает плотная песчаная буря!</i></span>"
	weather_overlay = "dust_low"
	weather_color = "#d2b48c"

	end_message = "<span class='boldannounce'>Ветер стихает, и песок оседает на землю.</span>"
	end_duration = 300
	end_overlay = "dust_low"

	aesthetic = FALSE
	probability = 0

	weather_duration_lower = 1800
	weather_duration_upper = 3600

	area_type = /area/awaymission/ihategordon/outsideofmesa
	protect_indoors = TRUE
	protected_areas = list(/area/awaymission/ihategordon/rocks)

	var/storm_stage = 0 // 0 = dust_low, 1 = dust_med, 2 = dust_high
	var/stage_timer = 0
	var/stage_duration = 600 // 1 minute per stage (600 deciseconds)

/datum/weather/ash_storm/mesa_sandstorm/start()
	. = ..()
	SSblackmesa_events.mesa_announce("Внимание! Зафиксирована интенсивная песчаная буря в Секторе H. Видимость критически низкая. Всем находиться в помещениях!", "Sandstorm Warning", 'modular_bluemoon/sound/ambience/mesa/BMAS2.ogg')
	storm_stage = 0
	stage_timer = 0

/datum/weather/ash_storm/mesa_sandstorm/wind_down()
	for(var/mob/living/L in GLOB.mob_living_list)
		L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm)
		L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_med)
		L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_high)
		L.clear_fullscreen("mesa_storm")
	return ..()

/datum/weather/ash_storm/mesa_sandstorm/weather_act(mob/living/L)
	if(is_ash_immune(L))
		L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm)
		L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_med)
		L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_high)
		L.clear_fullscreen("mesa_storm")
		return

	// Apply effects based on current stage
	switch(storm_stage)
		if(0) // dust_low - no slowdown, screen overlay
			L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm)
			L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_med)
			L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_high)
			L.overlay_fullscreen("mesa_storm", /atom/movable/screen/fullscreen/tiled/dust_low)
		if(1) // dust_med - slowdown, no screen overlay
			L.add_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_med)
			L.clear_fullscreen("mesa_storm")
		if(2) // dust_high - slowdown, no screen overlay
			L.add_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_high)
			L.clear_fullscreen("mesa_storm")

/datum/weather/ash_storm/mesa_sandstorm/process()
	if(aesthetic || (stage != MAIN_STAGE))
		return

	// Handle stage cycling
	stage_timer++
	if(stage_timer >= stage_duration)
		stage_timer = 0
		storm_stage++
		if(storm_stage > 2)
			storm_stage = 0 // Cycle back to dust_low

	// Update weather overlay based on stage
	switch(storm_stage)
		if(0)
			weather_overlay = "dust_low"
		if(1)
			weather_overlay = "dust_med"
		if(2)
			weather_overlay = "dust_high"

	for(var/mob/living/L in GLOB.mob_living_list)
		var/turf/mob_turf = get_turf(L)
		var/area/mob_area = get_area(L)
		if(!mob_turf || !(mob_turf.z in impacted_z_levels) || !mob_area || !(mob_area in impacted_areas))
			L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm)
			L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_med)
			L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_high)
			L.clear_fullscreen("mesa_storm")
		else if(can_weather_act(L))
			weather_act(L)

/datum/weather/ash_storm/mesa_sandstorm/end()
	for(var/mob/living/L in GLOB.mob_living_list)
		L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm)
		L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_med)
		L.remove_movespeed_modifier(/datum/movespeed_modifier/mesa_storm_high)
		L.clear_fullscreen("mesa_storm")
	return ..()

// Dust effects
/atom/movable/screen/fullscreen/tiled/dust_low
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "cloudy"
	color = "#d2b48c"
	alpha = 100

/atom/movable/screen/fullscreen/tiled/dust_med
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "cloudy"
	color = "#c4a574"
	alpha = 150

/atom/movable/screen/fullscreen/tiled/dust_high
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "cloudy"
	color = "#b89560"
	alpha = 200

/atom/movable/screen/fullscreen/tiled/mesa_sandstorm
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "cloudy"
	color = "#d2b48c"
	alpha = 150
