/datum/round_event_control/aurora_caelus
	name = "Aurora Caelus"
	typepath = /datum/round_event/aurora_caelus
	max_occurrences = 4
	weight = 10
	earliest_start = 5 MINUTES
	category = EVENT_CATEGORY_FRIENDLY
	description = "A colourful display can be seen through select windows. And the kitchen."

/datum/round_event_control/aurora_caelus/canSpawnEvent(players, gamemode)
	if(!CONFIG_GET(flag/starlight))
		return FALSE
	return ..()

/datum/round_event/aurora_caelus
	announce_when = 1
	start_when = 9
	end_when = 90
	var/list/aurora_colors = list("#A2FF80", "#A2FF8B", "#A2FF96", "#A2FFA5", "#A2FFB6", "#A2FFC7", "#A2FFDE", "#A2FFEE")
	var/aurora_progress = 0 //this cycles from 1 to 8, slowly changing colors from gentle green to gentle blue
	var/list/ion_overlays = list()

/datum/round_event/aurora_caelus/announce()
	priority_announce("[station_name()]: Безвредное облако ионов приближается к вашей станции, истощая свою энергию и стукаясь о корпус. NanoTrasen разрешает всем сотрудникам сделать короткий перерыв, чтобы расслабиться и понаблюдать за этим редким событием. В это время звездный свет будет ярким, но мягким, переходя от тихого зеленого к яркому синему цвету. Любой сотрудник, желающий увидеть эти огни самостоятельно, может отправиться в ближайший к ним район с видом на космос. Надеемся, что вам понравится это сияние.",
	sound = 'sound/misc/notice2.ogg',
	sender_override = "Отдел Метеорологии NanoTrasen")
	for(var/V in GLOB.player_list)
		var/mob/M = V
		if((M.client.prefs.toggles & SOUND_MIDI) && is_station_level(M.z))
			M.playsound_local(M, 'sound/ambience/aurora_caelus.ogg', 20, FALSE, pressure_affected = FALSE)

/datum/round_event/aurora_caelus/start()
	for(var/area in GLOB.sortedAreas)
		var/area/A = area
		if(initial(A.dynamic_lighting) == DYNAMIC_LIGHTING_IFSTARLIGHT)
			for(var/turf/open/space/S in A)
				S.set_light(S.light_range * 3, S.light_power * 0.5)
	for(var/V in GLOB.player_list)
		var/mob/M = V
		if(is_station_level(M.z))
			ADD_TRAIT(M, TRAIT_PACIFISM, "event_effect")
	for(var/client/C in GLOB.clients)
		if(!C.mob || !is_station_level(C.mob.z))
			continue
		add_ion_overlay(C)

/datum/round_event/aurora_caelus/tick()
	if(activeFor % 5 == 0)
		aurora_progress++
		var/aurora_color = aurora_colors[aurora_progress]
		for(var/area in GLOB.sortedAreas)
			var/area/A = area
			if(initial(A.dynamic_lighting) == DYNAMIC_LIGHTING_IFSTARLIGHT)
				for(var/turf/open/space/S in A)
					S.set_light(l_color = aurora_color)
		for(var/client/C in ion_overlays)
			var/atom/movable/screen/aurora_ion_overlay/overlay = ion_overlays[C]
			if(overlay)
				overlay.update_ion_color(aurora_color)

/datum/round_event/aurora_caelus/end()
	for(var/area in GLOB.sortedAreas)
		var/area/A = area
		if(initial(A.dynamic_lighting) == DYNAMIC_LIGHTING_IFSTARLIGHT)
			for(var/turf/open/space/S in A)
				fade_to_black(S)
	for(var/V in GLOB.player_list)
		var/mob/M = V
		if(is_station_level(M.z))
			REMOVE_TRAIT(M, TRAIT_PACIFISM, "event_effect")
	// Частицы продолжают летать ещё ~минуту после завершения события
	lingering_ion_fadeout()
	priority_announce("Событие, связанное с Космическим Сиянием, заканчивается. Звездный свет постепенно возвращается в нормальное состояние. Возвращайтесь на свое рабочее место и продолжайте работать в обычном режиме. Приятной смены [station_name()] и спасибо, что посмотрели за этим событием с нами.",
	sound = 'sound/misc/notice2.ogg',
	sender_override = "Отдел Метеорологии NanoTrasen")

/datum/round_event/aurora_caelus/proc/fade_to_black(turf/open/space/S)
	set waitfor = FALSE
	var/new_light = initial(S.light_range)
	while(S.light_range > new_light)
		S.set_light(S.light_range - 0.2)
		sleep(30)
	S.set_light(new_light, initial(S.light_power), initial(S.light_color))

/datum/round_event/aurora_caelus/proc/add_ion_overlay(client/C)
	if(!C || ion_overlays[C])
		return
	var/atom/movable/screen/aurora_ion_overlay/overlay = new
	ion_overlays[C] = overlay
	C.screen += overlay
	overlay.fade_in(30)

/datum/round_event/aurora_caelus/proc/lingering_ion_fadeout()
	for(var/client/C in ion_overlays)
		var/atom/movable/screen/aurora_ion_overlay/overlay = ion_overlays[C]
		if(overlay?.particles)
			overlay.particles.spawning = 2
	addtimer(CALLBACK(src, PROC_REF(ion_stop_spawning)), 300)
	addtimer(CALLBACK(src, PROC_REF(ion_final_cleanup)), 600)

/datum/round_event/aurora_caelus/proc/ion_stop_spawning()
	for(var/client/C in ion_overlays)
		var/atom/movable/screen/aurora_ion_overlay/overlay = ion_overlays[C]
		if(overlay?.particles)
			overlay.particles.spawning = 0

/datum/round_event/aurora_caelus/proc/ion_final_cleanup()
	for(var/client/C in ion_overlays)
		var/atom/movable/screen/aurora_ion_overlay/overlay = ion_overlays[C]
		if(overlay)
			overlay.fade_out(50)
			QDEL_IN(overlay, 60)
		C?.screen -= overlay
	ion_overlays.Cut()

/datum/round_event/aurora_caelus/proc/remove_all_ion_overlays()
	for(var/client/C in ion_overlays)
		var/atom/movable/screen/aurora_ion_overlay/overlay = ion_overlays[C]
		if(overlay)
			overlay.fade_out(50)
			C?.screen -= overlay
			QDEL_IN(overlay, 60)
	ion_overlays.Cut()

