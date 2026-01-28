/datum/round_event_control/rogue_drone
	name = "Rogue Drones"
	description = "Группа боевых дронов, оперируемых с борта Одного из Боевых Фрегатов ПАКТа, не вернулась с зачистки сектора. В случае контакта с дронами проявляйте осторожность."
	typepath = /datum/round_event/rogue_drone
	weight = 50
	max_occurrences = 2
	category = EVENT_CATEGORY_ENTITIES

/datum/round_event/rogue_drone
	start_when = 10
	end_when = 1000
	var/list/drones_list = list()

/datum/round_event/rogue_drone/start()
	var/list/possible_spawns = list()
	for(var/thing in GLOB.landmarks_list)
		var/obj/effect/landmark/C = thing
		if(C.name == "carpspawn") //spawn them at the same place as carp
			possible_spawns.Add(C)

	var/num = rand(2, 12)
	for(var/i = 0, i < num, i++)
		var/mob/living/simple_animal/hostile/malf_drone/D = new(get_turf(pick(possible_spawns)))
		drones_list.Add(D)

/datum/round_event/rogue_drone/announce()
	var/msg
	if(prob(33))
		msg = "Группа боевых дронов, оперируемых с борта Одного из Боевых Фрегатов ПАКТа, не вернулась с зачистки сектора. В случае контакта с дронами проявляйте осторожность."
	else if(prob(50))
		msg = "Потеряна связь с группой боевых дронов, оперируемых с Одного из Боевых Фрегатов ПАКТа. В случае контакта с дронами проявляйте осторожность."
	else
		msg = "Неопознанные хакеры взломали систему контроля боевых дронов, оперируемых с Одного из Боевых Фрегатов ПАКТа. В случае контакта с дронами проявляйте осторожность."
	priority_announce(msg, "ВНИМАНИЕ: СБОЙНЫЕ ДРОНЫ.")

/datum/round_event/rogue_drone/tick()
	return

/datum/round_event/rogue_drone/end()
	var/num_recovered = 0
	for(var/mob/living/simple_animal/hostile/malf_drone/D in drones_list)
		do_sparks(3, 0, D.loc)
		qdel(D)
		num_recovered++

	if(num_recovered > drones_list.len * 0.75)
		priority_announce("Система контроля боевых дронов сообщает, что все единицы успешно вернулись на борт Одного из Боевых Фрегатов ПАКТа.", "ВНИМАНИЕ: СБОЙНЫЕ ДРОНЫ.")
	else
		priority_announce("Система контроля боевых дронов сообщает о потере всех боевых единиц, однако жертв не зарегистрировано.", "ВНИМАНИЕ: СБОЙНЫЕ ДРОНЫ.")
