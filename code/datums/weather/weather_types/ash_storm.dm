//A reference to this list is passed into area sound managers, and it's modified in a manner that preserves that reference in ash_storm.dm
GLOBAL_LIST_EMPTY(ash_storm_sounds)
/datum/weather/ash_storm
	name = "ash storm"
	desc = "An intense atmospheric storm lifts ash off of the planet's surface and billows it down across the area, dealing intense fire damage to the unprotected."

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

	area_type = /area
	protect_indoors = TRUE
	target_trait = ZTRAIT_ASHSTORM

	immunity_type = TRAIT_ASHSTORM_IMMUNE

	probability = 90

	barometer_predictable = TRUE
	var/list/weak_sounds = list()
	var/list/strong_sounds = list()

/datum/weather/ash_storm/telegraph()
	var/list/eligible_areas = list()
	for (var/z in impacted_z_levels)
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

	//We modify this list instead of setting it to weak/stron sounds in order to preserve things that hold a reference to it
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

/datum/weather/ash_storm/proc/is_ash_immune(atom/L)
	while (L && !isturf(L))
		if(ismecha(L)) //Mechs are immune
			return TRUE
		if(ishuman(L)) //Are you immune?
			var/mob/living/carbon/human/H = L
			var/thermal_protection = H.easy_thermal_protection()
			if(thermal_protection >= FIRE_IMMUNITY_MAX_TEMP_PROTECT)
				return TRUE
		// if(istype(L, /obj/structure/closet))
		// 	var/obj/structure/closet/the_locker = L
		// 	if(the_locker.weather_protection)
		// 		if("ash" in the_locker.weather_protection)
		// 			return TRUE
		L = L.loc //Check parent items immunities (recurses up to the turf)
	return FALSE //RIP you

/datum/weather/ash_storm/weather_act(mob/living/L)
	if(is_ash_immune(L))
		return
	if(is_species(L, /datum/species/lizard/ashwalker) || HAS_TRAIT(L, TRAIT_ASHRESISTANCE))
		if(L.getStaminaLoss() < (STAMINA_CRIT - 40))
			L.adjustStaminaLoss(4)
		return
	L.adjustFireLoss(4)

/datum/weather/ash_storm/end()
	GLOB.ash_storm_sounds -= weak_sounds
	for(var/turf/open/floor/plating/asteroid/basalt/basalt as anything in GLOB.dug_up_basalt)
		if(!(basalt.loc in impacted_areas) || !(basalt.z in impacted_z_levels))
			continue
		basalt.refill_dug()
	return ..()

//Emberfalls are the result of an ash storm passing by close to the playable area of lavaland. They have a 10% chance to trigger in place of an ash storm.
/datum/weather/ash_storm/emberfall
	name = "emberfall"
	desc = "A passing ash storm blankets the area in harmless embers."

	weather_message = "<span class='notice'>Гладкий пепел осыпается вокруг вас, как гротескный снег. Шторм, кажется, прошел мимо...</span>"
	weather_overlay = "light_ash"

	end_message = "<span class='notice'>Падение пепла замедляется и останавливается. Еще один слой затвердевшей сажи на базальте под вашими ногами.</span>"
	end_sound = null

	aesthetic = TRUE

	probability = 10
