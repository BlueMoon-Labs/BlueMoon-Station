/datum/round_event_control/supernova
	name = "Supernova"
	typepath = /datum/round_event/supernova
	weight = 10
	max_occurrences = 1
	min_players = 30
	category = EVENT_CATEGORY_ANOMALIES
	// Категория ANOMALIES по умолчанию даёт MAJOR (cost 20, intensity 40), но видимая часть
	// события - лотерея силы: громкий анонс с шансом prob(сила*25), рад-штормы только при
	// больших роллах. Гарантированы лишь буст соляров и допплер-пинг - это цена среднего,
	// а не съеденный кошелёк крупного при intensity 40 на 10 минут.
	severity = DIRECTOR_SEVERITY_MODERATE

/datum/round_event/supernova
	announce_when = 40
	start_when = 1
	end_when = 300
	var/power = 1
	var/datum/sun/supernova
	var/storm_count = 0
	var/announced = FALSE

/datum/round_event/supernova/setup()
	announce_when = rand(4, 60)
	supernova = new
	SSsun.suns += supernova
	switch(rand(1,5))
		if(1)
			power = rand(5,100) / 100
		if(2)
			power = rand(5,500) / 100
		if(3)
			power = rand(5,1000) / 100
		if(4, 5)
			power = rand(5,5000) / 100
	supernova.azimuth = rand(0, 359)
	supernova.power_mod = 0

/datum/round_event/supernova/announce()
	var/message = "[station_name()]: Наша Тахионно-Доплеровская матрица обнаружила сверхновую в вашей окрестности. Пиковый поток от сверхновой оценивается как [round(power,0.1)] в раз больше текущего солнечного потока; если волна сверхновой приблизится к вашей Звезде, ваши солнечные панели смогут получить это как прибавку к мощности.[power > 1 ? " Возможны короткие вспышки радиации, поэтому подготовьтесь соответствующим образом." : "Судя по датчикам, вашей станции не следует ожидать ещё больше радиационных всплесков."] Мы надеемся, что вам понравится свет от взрыва Сверхновой!"
	if(prob(power * 25))
		priority_announce(message, sender_override = "Отдел метеорологии NanoTrasen", has_important_message = TRUE)
		announced = TRUE
	else
		print_command_report(message)


/datum/round_event/supernova/start()
	supernova.power_mod = 0.001 * power
	var/explosion_size = rand(1000000000, 10000000000)
	var/turf/epicenter = get_turf_in_angle(supernova.azimuth, SSmapping.get_station_center(), round(world.maxx * 0.45))
	for(var/array in GLOB.doppler_arrays)
		var/obj/machinery/doppler_array/A = array
		A.sense_explosion(epicenter, explosion_size/2, explosion_size, 0, 107000000 / power, explosion_size/2, explosion_size, 0)
	if(power > 1 && SSticker.mode.bloodsucker_sunlight?.time_til_cycle > 90)
		var/obj/effect/sunlight/sucker_light = SSticker.mode.bloodsucker_sunlight
		sucker_light.time_til_cycle = 90
		sucker_light.warn_daylight(1,"<span class = 'danger'>A supernova will bombard the station with dangerous UV in [90 / 60] minutes. <b>Prepare to seek cover in a coffin or closet.</b></span>")
		sucker_light.give_home_power()

/datum/round_event/supernova/tick()
	var/midpoint = round((end_when-start_when)/2)
	if(activeFor < midpoint)
		supernova.power_mod = min(supernova.power_mod*1.2, power)
	if(activeFor > end_when-10)
		supernova.power_mod /= 4
	if(prob(round(supernova.power_mod)) && prob(5-storm_count) && !SSweather.get_weather_by_type(/datum/weather/rad_storm))
		SSweather.run_weather(/datum/weather/rad_storm/supernova)
		storm_count++

/datum/round_event/supernova/end()
	SSsun.suns -= supernova
	qdel(supernova)
	if(announced)
		priority_announce("The supernova's flux is now negligible. Radiation storms have ceased. Have a pleasant shift, [station_name()], and thank you for bearing with nature.",
		sender_override = "Nanotrasen Meteorology Division")

/datum/weather/rad_storm/supernova
	weather_duration_lower = 50
	weather_duration_upper = 100
	telegraph_duration = 200
	radiation_intensity = 50
	weather_sound = null
	telegraph_message = "<span class='userdanger'>The air begins to grow very warm!</span>"
