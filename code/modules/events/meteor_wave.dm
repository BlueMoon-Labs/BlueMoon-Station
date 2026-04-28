// Normal strength

#define SINGULO_BEACON_DISTURBANCE 0.2 //singularity beacon also improve the odds of meteor waves and speed them up a little.
#define SINGULO_BEACON_MAX_DISTURBANCE 0.6 //maximum cap due to how meteor waves can be potentially round ending.

/datum/round_event_control/meteor_wave
	name = "Meteor Wave: Normal"
	typepath = /datum/round_event/meteor_wave
	weight = 6
	min_players = 40
	max_occurrences = 1
	earliest_start = 60 MINUTES
	category = EVENT_CATEGORY_SPACE
	gamemode_blacklist = list(ROUNDTYPE_EXTENDED)

/datum/round_event/meteor_wave
	start_when		= 6
	end_when			= 66
	announce_when	= 1
	threat = 50
	var/list/wave_type
	var/wave_name = "normal"
	var/direction

/datum/round_event/meteor_wave/setup()
	announce_when = 1
	start_when = 150		// 5 minutes
	if(GLOB.singularity_counter)
		start_when *= 1 - min(GLOB.singularity_counter * SINGULO_BEACON_DISTURBANCE, SINGULO_BEACON_MAX_DISTURBANCE)
	end_when = start_when + 60

/datum/round_event/meteor_wave/New()
	..()
	if(!wave_type)
		determine_wave_type()

/datum/round_event/meteor_wave/proc/determine_wave_type()
	if(!wave_name)
		wave_name = pickweight(list(
			"normal" = 90,
			"threatening" = 5,
			"catastrophic" = 5))
	if(!direction)
		direction = pick(GLOB.cardinals)
	switch(wave_name)
		if("normal")
			wave_type = GLOB.meteors_normal
		if("threatening")
			wave_type = GLOB.meteors_threatening
		if("catastrophic")
			if(SSevents.holidays && SSevents.holidays[HALLOWEEN])
				wave_type = GLOB.meteorsSPOOKY
			else
				wave_type = GLOB.meteors_catastrophic
		if("meaty")
			wave_type = GLOB.meteorsB
		if("space dust")
			wave_type = GLOB.meteorsC
		if("halloween")
			wave_type = GLOB.meteorsSPOOKY
		else
			WARNING("Wave name of [wave_name] not recognised.")
			kill()

/datum/round_event/meteor_wave/announce(fake)
	priority_announce(generateMeteorString(start_when,TRUE,direction), "BНИМАНИЕ: МЕТЕОРЫ", "meteors", has_important_message = TRUE)
	if(wave_name == "threatening" || wave_name == "catastrophic")
		INVOKE_ASYNC(SSsecurity_level, TYPE_PROC_REF(/datum/controller/subsystem/security_level, minimum_security_level), SEC_LEVEL_ORANGE, FALSE)

/proc/generateMeteorString(start_when,syndiealert,direction)
	var/directionstring
	switch(direction)
		if(NORTH)
			directionstring = " с северной стороны"
		if(SOUTH)
			directionstring = " с южной стороны"
		if(EAST)
			directionstring = " с восточной стороны"
		if(WEST)
			directionstring = " с западной стороны"
	return "Метеоры были обнаружены на пути столкновения со станцией - [directionstring]. Время до столкновения: [round((start_when * SSevents.wait) / 10, 0.1)] секунд.[GLOB.singularity_counter && syndiealert ? " Предупреждение: Обнаружен аномальный гравитационный импульс, возможно вмешательство технологии Синдиката." : ""]"

/datum/round_event/meteor_wave/tick()
	if(ISMULTIPLE(activeFor, 3))
		spawn_meteors(5, wave_type, direction) //meteor list types defined in gamemode/meteor/meteors.dm

/datum/round_event/meteor_wave/end()
	. = ..()
	var/kill_count = 0
	for(var/obj/machinery/satellite/meteor_shield/meteor_satellite in GLOB.meteor_satellites)
		kill_count += meteor_satellite.kill_counter
	for(var/obj/machinery/satellite/meteor_shield/meteor_satellite in GLOB.meteor_satellites)
		if(meteor_satellite.active)
			meteor_satellite.radio.talk_into(meteor_satellite, "Оповещение системы противометеоритной защиты. Всего за последние 24 часа уничтожено целей: [kill_count]") // В общий канал сообщает
			break

/datum/round_event_control/meteor_wave/threatening
	name = "Meteor Wave: Threatening"
	typepath = /datum/round_event/meteor_wave/threatening
	weight = 4
	min_players = 50
	max_occurrences = 1
	earliest_start = 120 MINUTES
	category = EVENT_CATEGORY_SPACE

/datum/round_event/meteor_wave/threatening
	wave_name = "threatening"
	threat = 100

/datum/round_event_control/meteor_wave/catastrophic
	name = "Meteor Wave: Catastrophic"
	typepath = /datum/round_event/meteor_wave/catastrophic
	weight = 2
	min_players = 60
	max_occurrences = 1
	earliest_start = 120 MINUTES
	category = EVENT_CATEGORY_SPACE

/datum/round_event/meteor_wave/catastrophic
	wave_name = "catastrophic"
	threat = 150

#undef SINGULO_BEACON_DISTURBANCE
#undef SINGULO_BEACON_MAX_DISTURBANCE
