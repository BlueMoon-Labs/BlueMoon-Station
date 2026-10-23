//WHITE-STEEL PORT: subsystem/zclear
//BLUEMOON ADAPTATIONS:
// - get_all_contents_ignoring() does not exist; replaced with GetAllContents() + typecache filter.
// - transfer_area_lighting() does not exist (modern per-turf lighting); ChangeTurf handles it, call dropped.
// - NO_RUINS turf flag is spelled NO_RUINS_1 in bluemoon.
// - mob.get_ghost() takes a single arg in bluemoon.

#define CLEAR_TURF_PROCESSING_TIME (120 SECONDS)	//Time it takes to clear all turfs
#define CLEAR_TURF_ATOMS_PROCESSING_TIME (120 SECONDS)	//Time it takes to clear all atoms (отдельно от пересоздания турфов)
#define CHECK_ZLEVEL_TICKS (10 SECONDS)			//Every 10 seconds check if a tracked z-level is free.
//WHITE-STEEL FIX (bluemoon): пул готовых уровней на старт раунда и лимит динамических z-уровней.
//Без этого каждый новый маяк/объект при пустом пуле плодил новый пустой z-уровень (world.maxz
//растёт навсегда), что давало взрывы TD (перф CSVs: 17->32->34, starlight очередь 10.6M).
#define ZCLEAR_SEEDED_POOL_LEVELS 4
#define ZCLEAR_MAX_NEW_DYNAMIC_LEVELS 4

GLOBAL_LIST_EMPTY(zclear_atoms)
GLOBAL_LIST_EMPTY(zclear_blockers)

SUBSYSTEM_DEF(zclear)
	name = "Аннигилятор"
	wait = 1

	flags = SS_NO_INIT
	runlevels = RUNLEVEL_GAME

	//List of z-levels to be auto-wiped when they are left
	//Assoc list
	var/list/datum/space_level/autowipe

	//List of free, empty z-levels.
	var/list/datum/space_level/free_levels

	//WHITE-STEEL FIX: количество готовых z-уровней, создаваемых в пул на старте раунда.
	var/seeded_pool_levels = ZCLEAR_SEEDED_POOL_LEVELS
	//WHITE-STEEL FIX: лимит вновь создаваемых z-уровней сверх пула за раунд.
	var/max_dynamic_levels = ZCLEAR_MAX_NEW_DYNAMIC_LEVELS
	//WHITE-STEEL FIX: сколько уровней уже создано динамически в этом раунде.
	var/dynamic_levels_created = 0
	//WHITE-STEEL FIX: анти-спам для предупреждения о переполнении пула.
	var/last_deferred_announce = 0

	//List of processing Z-Levels
	var/list/datum/zclear_data/processing_levels

	//List of atoms to ignore
	var/list/ignored_atoms = null


	//List of z-levels being docked with
	var/list/docking_levels = list()

	//Announced zombie levels
	var/list/announced_zombie_levels = list()

/datum/controller/subsystem/zclear/New()
	. = ..()
	ignored_atoms = typecacheof(list(/mob/dead, /mob/camera, /mob/dview, /obj/effect/abstract/mirage_holder))

/datum/controller/subsystem/zclear/fire(resumed)
	if(times_fired % CHECK_ZLEVEL_TICKS == 0)
		check_for_empty_levels()
	for(var/datum/zclear_data/cleardata as() in processing_levels)
		continue_wipe(cleardata)

/*
 * Checks for empty z-levels and wipes them.
*/
/datum/controller/subsystem/zclear/proc/check_for_empty_levels()
	var/list/active_levels = list()
	//Levels that have living mobs
	var/list/living_levels = list()
	//Levels with mobs dead/alive
	var/list/mob_levels = list()
	//Check active mobs
	for(var/mob/living/L in GLOB.mob_list)
		//Dead mobs get sent to new ruins
		if(!L)
			continue
		if(L.ckey || L.mind || L.client)
			var/turf/T = get_turf(L)
			if(!T)
				continue
			mob_levels["[T.z]"] = TRUE
			if(L.stat != DEAD)
				active_levels["[T.z]"] = TRUE
				living_levels["[T.z]"] = TRUE
	//Check active nukes
	for(var/obj/machinery/nuclearbomb/decomission/bomb in GLOB.decomission_bombs)
		if(!bomb)
			continue
		if(bomb.timing)
			active_levels["[bomb.z]"] = TRUE
			living_levels["[bomb.z]"] = TRUE	//Dont perform mob saving actions on mobs about to be blown to smitherines.
	//Block z-clear from these levels.
	for(var/atom/A as() in GLOB.zclear_blockers)
		if(!A)
			continue
		active_levels["[A.z]"] = TRUE
	//Check for shuttles
	for(var/obj/docking_port/mobile/M in SSshuttle.mobile)
		if(!M)
			continue
		active_levels["[M.z]"] = TRUE
		//Check shuttle destination
		if(M.destination)
			active_levels["[M.destination.z]"] = TRUE
			living_levels["[M.destination.z]"] = TRUE
	//Check for shuttles docking
	for(var/port_id in SSorbits.assoc_shuttles)
		var/datum/orbital_object/shuttle/shuttle = SSorbits.assoc_shuttles[port_id]
		if(!shuttle)
			continue
		if(shuttle.docking_target)
			for(var/datum/space_level/level in shuttle.docking_target.linked_z_level)
				if(!level)
					continue
				active_levels["[level.z_value]"] = TRUE
				living_levels["[level.z_value]"] = TRUE
	//Check for shuttles coming in
	for(var/docking_level in docking_levels)
		active_levels["[docking_level]"] = TRUE
		living_levels["[docking_level]"] = TRUE

	for(var/datum/space_level/level as() in autowipe)
		if(!level)
			continue
		//Check if free
		if(active_levels["[level.z_value]"])
			if(!living_levels["[level.z_value]"] && mob_levels["[level.z_value]"] && !announced_zombie_levels["[level.z_value]"])
				//Zombie level detected.
				announced_zombie_levels["[level.z_value]"] = TRUE
				if(level.orbital_body)
					priority_announce("Датчики дальнего действия NanoTrasen показали, что все разумные формы жизни находящиеся в приоритетной точке [level.orbital_body.name] более не подают признаков жизни. Командованию рекомендуется организовать спасательную операцию для извлечения тел. В связи с характером угрозы в этом месте, сотрудникам службы безопасности, вооруженным смертоносным оружием, рекомендуется сопровождать спасательную команду.", "Сенсоры дальнего обнаружения NanoTrasen")
			continue
		//Level is free, do the wiping thing.
		LAZYREMOVE(autowipe, level)
		//Reset orbital body.
		QDEL_NULL(level.orbital_body)
		//Continue tracking after
		wipe_z_level(level.z_value, TRUE)

//Temporarily stops a z from being wiped for 30 seconds.
/datum/controller/subsystem/zclear/proc/temp_keep_z(z_level)
	docking_levels |= z_level
	addtimer(CALLBACK(src, .proc/unkeep_z, z_level), 2 MINUTES)

/datum/controller/subsystem/zclear/proc/unkeep_z(z_level)
	docking_levels -= z_level

/*
 * Создаёт на старте раунда пул готовых пустых z-уровней.
 * Каждый уровень полностью инициализируется (Initialize/параллакс) при создании,
 * а не при выдаче, поэтому выдача из пула ничего не стоит и не сажает тик.
 * Уровни возвращаются в пул после автозатирки, пока их не заняли снова.
 */
/datum/controller/subsystem/zclear/proc/seed_initial_pool()
	if(!LAZYLEN(free_levels) && seeded_pool_levels > 0)
		for(var/i in 1 to seeded_pool_levels)
			var/datum/space_level/picked_level = SSmapping.add_new_zlevel("Dynamic free level [i]", ZTRAITS_SPACE, orbital_body_type = null)
			initialize_space_level(picked_level.z_value)
			LAZYADD(free_levels, picked_level)

/*
 * Returns a free space level.
 * After a 60 second grace period of allocation, the z-level will be put back into the pool of z-levels to clear.
 * Will create a new z-level if none are available, but only up to a hard cap.
 *	Returns null when no level is available and the cap is reached - the caller should retry later.
*/
/datum/controller/subsystem/zclear/proc/get_free_z_level()
	while(LAZYLEN(free_levels))
		var/datum/space_level/picked_level = pick(free_levels)
		LAZYREMOVE(free_levels, picked_level)
		//In 1 minute we will begine tracking when all mobs have left the z-level.
		//Begin tracking. In the rare case that someone got into a free z-level then just allow them to float there with no ruins. Space is pretty empty you know.
		addtimer(CALLBACK(src, .proc/begin_tracking, picked_level), 60 SECONDS)
		//Check if the z-level is actually free. (Someone might have drifted into the z-level.)
		var/free = TRUE
		for(var/mob/living/L in GLOB.player_list)
			var/turf/T = get_turf(L)
			if(!T)
				continue
			if(T.z == picked_level.z_value)
				free = FALSE
				break
		if(free)
			return picked_level
	//Создаём новый z-уровень только пока не упёрлись в лимит.
	if(dynamic_levels_created < max_dynamic_levels)
		dynamic_levels_created++
		var/datum/space_level/picked_level = SSmapping.add_new_zlevel("Dynamic free level [seeded_pool_levels + dynamic_levels_created]", ZTRAITS_SPACE, orbital_body_type = null)
		//Новый уровень BYOND заполнен world.turf (/turf/open/space/basic) без Initialize - вокруг
		//руины оставался «мёртвый» космос без параллакса. Заменяем на полноценный /turf/open/space.
		initialize_space_level(picked_level.z_value)
		addtimer(CALLBACK(src, .proc/begin_tracking, picked_level), 60 SECONDS)
		message_admins("SSORBITS: Created a new dynamic free level ([dynamic_levels_created] now created) as none were available at the time.")
		return picked_level
	if(world.time > last_deferred_announce)
		last_deferred_announce = world.time + 1 MINUTES
		message_admins("SSORBITS: All free z-levels are in use, POI generation deferred until one clears.")
	return null

/*
 * Приводит космос свежесозданного динамического z-уровня к полноценному /turf/open/space.
 * BYOND заполняет новый уровень world.turf = /turf/open/space/basic, у которого пустой New()
 * намеренно пропускает Initialize (оптимизация маплоадера): нет SPACE_ICON_STATE, нет
 * visibilityChanged() и регистрации в атмосе. Из-за этого пространство вокруг сгенерированной
 * руины выглядит как второй тип турфа «space» - без параллакса и без нормального взаимодействия.
 * ChangeTurf(/turf/open/space) сам пересоздаёт турф с корректным Initialize.
 */
/datum/controller/subsystem/zclear/proc/initialize_space_level(z_level)
	if(!z_level)
		return
	for(var/turf/T as() in block(locate(1, 1, z_level), locate(world.maxx, world.maxy, z_level)))
		if(istype(T, /turf/open/space/basic))
			T.ChangeTurf(/turf/open/space, flags = CHANGETURF_IGNORE_AIR | CHANGETURF_DEFER_CHANGE)
		CHECK_TICK

/datum/controller/subsystem/zclear/proc/begin_tracking(datum/space_level/sl)
	LAZYOR(autowipe, sl)


/*
 * Adds a z-level to the queue to be deleted.
 * If tracking is TRUE, then we will re-wipe the z-level when mobs leave it again.
*/
/datum/controller/subsystem/zclear/proc/wipe_z_level(z_level, tracking = FALSE, datum/callback/completion_callback)
	if(!z_level)
		return

	SSair.pause_z(z_level)

	var/list/turfs = block(locate(1, 1, z_level), locate(world.maxx, world.maxy, z_level))

	//WHITE-STEEL FIX: раньше обе фазы считались с CLEAR_TURF_PROCESSING_TIME * 0.5, т.е. каждая
	//длилась всего 60 секунд при 1084 турфов/тик - массовые qdel/ChangeTurf давали спайки в
	//Garbage (576-929% в логах). Теперь пересоздание турфов и очистка атомов идут отдельными
	//фазами по 120 секунд каждая (~542 турфа/тик), суммарно - заявленные 120 секунд.
	var/reset_process_time = CLEAR_TURF_PROCESSING_TIME
	var/atom_process_time = CLEAR_TURF_ATOMS_PROCESSING_TIME

	//Divide the turfs into groups for the turf-resetting phase
	var/group_size = CEILING(turfs.len / reset_process_time, 1)
	var/list/divided_turfs = list()
	var/list/current_group = list()
	for(var/i in 1 to turfs.len)
		var/turf/T = turfs[i]
		current_group += T
		if(i % group_size == 0)
			divided_turfs += list(current_group)
			current_group = list()
	divided_turfs += list(current_group)

	//Divide the turfs into (finer) groups for the atom-clearing phase.
	var/atom_group_size = CEILING(turfs.len / atom_process_time, 1)
	var/list/divided_atom_turfs = list()
	var/list/current_atom_group = list()
	for(var/i in 1 to turfs.len)
		var/turf/T = turfs[i]
		current_atom_group += T
		if(i % atom_group_size == 0)
			divided_atom_turfs += list(current_atom_group)
			current_atom_group = list()
	divided_atom_turfs += list(current_atom_group)

	//Create the wipe data datum
	var/datum/zclear_data/data = new()
	data.zvalue = z_level
	data.divided_turfs = divided_turfs
	data.divided_atom_turfs = divided_atom_turfs
	data.process_num = 0
	data.completion_callback = completion_callback
	data.tracking = tracking

	//Add the thing to the wiping levels list.
	LAZYADD(processing_levels, data)

	//Pre-clear anything that needs to be cleared first (Air alarms.)
	for(var/atom/A in GLOB.zclear_atoms)
		if(!A)
			continue
		if(A.z == z_level)
			qdel(A, TRUE)

	//Unannounce zombie level
	announced_zombie_levels["[z_level]"] = FALSE

/*
 * Continues the process of wiping a z-level.
*/
/datum/controller/subsystem/zclear/proc/continue_wipe(datum/zclear_data/cleardata)
	var/list_element = (cleardata.process_num % CLEAR_TURF_PROCESSING_TIME) + 1
	var/atom_list_element = ((cleardata.process_num - CLEAR_TURF_PROCESSING_TIME) % CLEAR_TURF_ATOMS_PROCESSING_TIME) + 1
	switch(cleardata.process_num)
		if(0 to CLEAR_TURF_PROCESSING_TIME-1)
			if(list_element <= length(cleardata.divided_turfs))
				reset_turfs(cleardata.divided_turfs[list_element])
		if(CLEAR_TURF_PROCESSING_TIME to CLEAR_TURF_PROCESSING_TIME + CLEAR_TURF_ATOMS_PROCESSING_TIME - 1)
			if(atom_list_element <= length(cleardata.divided_atom_turfs))
				clear_turf_atoms(cleardata.divided_atom_turfs[atom_list_element])
		else
			//Done
			LAZYREMOVE(processing_levels, cleardata)
			//Finalize area
			SSair.unpause_z(cleardata.zvalue)
			var/area/spaceA = GLOB.areas_by_type[/area/space]
			spaceA.reg_in_areas_in_z()	//<< Potentially slow proc
			if(cleardata.completion_callback)
				cleardata.completion_callback.Invoke(cleardata.zvalue)
			if(cleardata.tracking)
				LAZYADD(free_levels, SSmapping.z_list[cleardata.zvalue])
				//WHITE-STEEL PORT: анонс про «пропавших членов экипажа, которых можно найти»
				//удалён вместе с буфером nullspaced_mobs - переносить тела в следующую руину
				//больше нечем, анонсировать некого.
	cleardata.process_num ++

/*
 * Deletes all the atoms within a given turf.
*/
/datum/controller/subsystem/zclear/proc/clear_turf_atoms(list/turfs)
	//Clear atoms
	for(var/turf/T as() in turfs)
		// Remove all atoms except abstract mobs
		var/list/allowed_contents = T.GetAllContents()
		allowed_contents -= T
		for(var/i in 1 to allowed_contents.len)
			var/thing = allowed_contents[i]
			if(is_type_in_typecache(thing, ignored_atoms))
				continue
			//Отвязываем кабель от powernet без дорогого propagate: remove_cable убирает его из
			//powernet.cables, обнуляет cable.powernet и qdel-ит опустевшую сеть. Просто обнулять
			//cable.powernet нельзя: кабель остаётся в Datums -> /datum/powernet -> cables, из-за
			//чего последующий qdel/hard-delete идёт через поиск ссылок (~190-450 мс на кабель).
			if(istype(thing, /obj/structure/cable))
				var/obj/structure/cable/cable = thing
				if(cable.powernet)
					cable.powernet.remove_cable(cable)
			if(ismob(thing))
				if(!isliving(thing))
					continue
				var/mob/living/M = thing
				if(M.mind || M.key)
					if(M.stat == DEAD)
						//WHITE-STEEL PORT: труп больше не «спасается» в буфер nullspaced-мобов.
						//Раньше мёртвый моб с mind'ом переживал вайп уровня, а генератор руин
						//переносил его в СЛЕДУЮЩУЮ руину - тела кочевали от миссии к миссии
						//бесконечно, держали z-уровни от возврата в пул свободных уровней и
						//висели до ручной чистки администрацией. Теперь труп удаляется вместе
						//с уровнем.
						M.ghostize(TRUE)
						delete_atom(thing)
					else
						//If the mob has a key (but is DC) then teleport them to a safe z-level where they can potentially be retrieved.
						//Since the wiping takes 90 seconds they could potentially still be on the z-level as it is wiping if they reconnect in time
						random_teleport_atom(M)
						M.Knockdown(5)
						to_chat(M, span_warning("You feel sick as your body lurches through space and time, the ripples of the starship that brought you here eminate no more and you get the horrible feeling that you have been left behind."))
				else
					delete_atom(thing)
			else
				delete_atom(thing)

/*
 * DELETES AN ATOM OR TELEPORTS IT TO A RANDOM LOCATION IF IT IS INDESTRUCTIBLE
*/
/datum/controller/subsystem/zclear/proc/delete_atom(atom/A)
	//Dont delete indestructible items, but indestructible structures can go
	if(isitem(A))
		var/obj/O = A
		//Handled by the mob
		if(ismob(O.loc))
			return
		if(O.resistance_flags & INDESTRUCTIBLE)
			random_teleport_atom(A)
			return
	//Force delete effects and docking ports, normal delete everything else.
	//Probably gunna cause problems in testing.
	qdel(A, force = (iseffect(A) || istype(A, /obj/docking_port)))

/*
 * Randomly teleports an atom to a random z-level
 * Copy and paste of turf/open/space/transit, could probably be a global proc
*/
/datum/controller/subsystem/zclear/proc/random_teleport_atom(atom/movable/AM)
	set waitfor = FALSE
	if(!AM || istype(AM, /obj/docking_port))
		return
	if(AM.loc != get_turf(AM)) 	// Multi-tile objects are "in" multiple locs but its loc is it's true placement.
		return					// Don't move multi tile objects if their origin isnt in transit
	var/max = world.maxx-TRANSITIONEDGE
	var/min = 1+TRANSITIONEDGE

	var/list/possible_transtitons = list()
	for(var/datum/space_level/D as() in SSmapping.z_list)
		if(!D)
			continue
		if (D.linkage == CROSSLINKED)
			possible_transtitons += D.z_value
	var/_z = safepick(possible_transtitons)
	if(!_z)
		_z = 2

	//now select coordinates for a border turf
	var/_x = rand(min,max)
	var/_y = rand(min,max)

	var/turf/T = locate(_x, _y, _z)
	AM.forceMove(T)

/datum/controller/subsystem/zclear/proc/reset_turfs(list/turfs)
	var/list/new_turfs = list()
	for(var/turf/T as() in turfs)
		//TODO: This doesn't update turfs around it.
		var/turf/newT
		//basic - подтип /turf/open/space, но без Initialize: его тоже надо пересоздать,
		//иначе после вайпа уровень снова вернётся в пул с «мёртвым» космосом.
		if(istype(T, /turf/open/space) && !istype(T, /turf/open/space/basic))
			newT = T
		else
			newT = T.ChangeTurf(/turf/open/space, flags = CHANGETURF_IGNORE_AIR | CHANGETURF_DEFER_CHANGE)
		if(!istype(newT.loc, /area/space))
			var/area/newA = GLOB.areas_by_type[/area/space]
			newA.contents += newT
		newT.turf_flags &= ~NO_RUINS_1
		new_turfs += newT
	return new_turfs

/datum/zclear_data
	var/zvalue
	var/list/divided_turfs
	var/list/divided_atom_turfs
	var/process_num
	var/tracking
	//Callback when completed, z value passed as parameters
	var/datum/callback/completion_callback
