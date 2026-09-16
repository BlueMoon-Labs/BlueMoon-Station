//Radiation storms occur when the station passes through an irradiated area, and irradiate anyone not standing in protected areas (maintenance, emergency storage, etc.)
/datum/weather/rad_storm
	parallax_profile = "ion_blizzard"
	name = "radiation storm"
	desc = "Интенсивное облако радиации проходит сквозь зону, нанося радиационный вред всем, кто от него не защищён."

	telegraph_duration = 400
	telegraph_message = span_danger("Воздух вокруг вас нагревается.")

	weather_message = span_userdanger("<i>Вы ощущаете волну жара, окатывающую вас! Ищите укрытие!</i>")
	weather_overlay = "ash_storm"
	weather_duration_lower = 600
	weather_duration_upper = 1500
	weather_color = "green"
	weather_sound = 'sound/misc/bloblarm.ogg'

	end_duration = 100
	end_message = span_notice("Кажется, воздух вокруг вас стал охлаждаться...")

	priority_end_message = "Облако радиации миновало космическую станцию. Пожалуйста, вернитесь на свои рабочие места."

	area_type = /area
	protected_areas = list(/area/maintenance, /area/ai_monitored/turret_protected/ai_upload, /area/ai_monitored/turret_protected/ai_upload_foyer, /area/commons/toilet, /area/security/prison, /area/security/brig,
	/area/ai_monitored/turret_protected/ai, /area/commons/storage/emergency/starboard, /area/commons/storage/emergency/port, /area/shuttle, /area/ruin/lavaland, /area/commons/dorms,
	/area/service/electronic_marketing_den, /area/service/hydroponics/garden/abandoned, /area/service/abandoned_gambling_den)
	target_trait = ZTRAIT_STATION

	immunity_type = TRAIT_RADSTORM_IMMUNE

	var/radiation_intensity = 100

/datum/weather/rad_storm/telegraph()
	..()
	status_alarm(TRUE)

/datum/weather/rad_storm/weather_act(mob/living/L)
	var/resist = L.getarmor(null, RAD)
	var/ratio = 1 - (min(resist, 100) / 100)
	L.rad_act(radiation_intensity * ratio)

/datum/weather/rad_storm/end()
	if(..())
		return
	priority_announce(priority_end_message, "ВНИМАНИЕ: АНОМАЛИЯ")
	status_alarm(FALSE)

/datum/weather/rad_storm/proc/status_alarm(active)	//Makes the status displays show the radiation warning for those who missed the announcement.
	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)
	if(!frequency)
		return

	var/datum/signal/signal = new
	if (active)
		signal.data["command"] = "alert"
		signal.data["picture_state"] = "radiation"
	else
		signal.data["command"] = "shuttle"

	var/atom/movable/virtualspeaker/virt = new(null)
	frequency.post_signal(virt, signal)
