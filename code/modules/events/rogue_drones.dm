/datum/round_event_control/rogue_drone
	name = "Rogue Drones"
	description = "Группа боевых дронов, оперируемых с борта Одного из Боевых Фрегатов ПАКТа, не вернулась с зачистки сектора. В случае контакта с дронами проявляйте осторожность."
	typepath = /datum/round_event/rogue_drone
	weight = 50
	max_occurrences = 2
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_MINOR
	disruption = DIRECTOR_DISRUPTION_DISRUPTIVE // враждебные дроны, а не фоновая мелочь

/datum/round_event/rogue_drone
	start_when = 10
	end_when = 1000
	var/list/drones_list = list()
	/// Сколько дронов вообще выпустили. Считать долю вернувшихся по длине
	/// drones_list больше нельзя: подписка на qdel вычёркивает из него убитых, и
	/// к end() там лежат только живые - деление дало бы "вернулись все" всегда.
	var/drones_spawned = 0

/datum/round_event/rogue_drone/start()
	var/list/possible_spawns = list()
	for(var/thing in GLOB.landmarks_list)
		var/obj/effect/landmark/C = thing
		if(C.name == "carpspawn") //spawn them at the same place as carp
			possible_spawns.Add(C)

	var/num = rand(2, 12)
	drones_spawned = num
	for(var/i = 0, i < num, i++)
		var/mob/living/simple_animal/hostile/malf_drone/D = new(get_turf(pick(possible_spawns)))
		drones_list.Add(D)
		// У дрона del_on_death, то есть убитый игроками он удаляет себя сам. Список
		// же жил до end() на 1000-м тике и всё это время держал труп жёсткой
		// ссылкой - гарантированный харддел. Заодно чинится счёт "вернулось": он
		// сравнивался с длиной списка, в котором лежали мёртвые.
		RegisterSignal(D, COMSIG_PARENT_QDELETING, PROC_REF(on_drone_qdeleting))

/datum/round_event/rogue_drone/proc/on_drone_qdeleting(datum/source)
	SIGNAL_HANDLER
	drones_list -= source

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
	// По КОПИИ: qdel рассылает COMSIG_PARENT_QDELETING синхронно, наш же обработчик
	// вычёркивает дрона из drones_list, а обход list в DM идёт по индексу - удаление
	// текущего элемента перепрыгивало бы через следующего. Половина дронов оставалась
	// бы на станции живой и после конца ивента.
	for(var/mob/living/simple_animal/hostile/malf_drone/D in drones_list.Copy())
		do_sparks(3, 0, D.loc)
		qdel(D)
		num_recovered++

	if(num_recovered > drones_spawned * 0.75)
		priority_announce("Система контроля боевых дронов сообщает, что все единицы успешно вернулись на борт Одного из Боевых Фрегатов ПАКТа.", "ВНИМАНИЕ: СБОЙНЫЕ ДРОНЫ.")
	else
		priority_announce("Система контроля боевых дронов сообщает о потере всех боевых единиц, однако жертв не зарегистрировано.", "ВНИМАНИЕ: СБОЙНЫЕ ДРОНЫ.")
