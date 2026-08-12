SUBSYSTEM_DEF(mobs)
	name = "Mobs"
	priority = FIRE_PRIORITY_MOBS
	flags = SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 20 
	var/list/currentrun = list()
	var/static/list/clients_by_zlevel[][]
	var/static/list/dead_players_by_zlevel[][] = list(list()) // Needs to support zlevel 1 here, MaxZChanged only happens when z2 is created and new_players can login before that.
	var/static/list/cubemonkeys = list()
	var/static/list/cheeserats = list()
	///Мобов, пропущенных бакетом за текущий проход (см. life_next_fire).
	var/skipped_this_pass = 0
	///Сколько бакет пропустил за прошлый ПОЛНЫЙ проход - для stat_entry.
	var/skipped_last_pass = 0

/datum/controller/subsystem/mobs/stat_entry(msg)
	msg = "P:[length(GLOB.mob_living_list)] Bkt:[skipped_last_pass]"
	return ..()

/datum/controller/subsystem/mobs/proc/MaxZChanged()
	if (!islist(clients_by_zlevel))
		clients_by_zlevel = new /list(world.maxz,0)
		dead_players_by_zlevel = new /list(world.maxz,0)
	while (clients_by_zlevel.len < world.maxz)
		clients_by_zlevel.len++
		clients_by_zlevel[clients_by_zlevel.len] = list()
		dead_players_by_zlevel.len++
		dead_players_by_zlevel[dead_players_by_zlevel.len] = list()

/datum/controller/subsystem/mobs/fire(resumed = 0)
	// Инструментация адаптивного профиля (см. базовый subsystem.dm): дорогие
	// проходы Life() именуют виновников по типам мобов - "нагрузка от мобов"
	// в логе перестаёт быть анонимной.
	var/slice_start_usage = TICK_USAGE
	var/seconds = wait * 0.1
	if (!resumed)
		src.currentrun.len = 0
		src.currentrun += GLOB.mob_living_list
		current_pass_cost_ms = 0
		skipped_this_pass = 0

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	var/times_fired = src.times_fired
	var/profiling = profile_armed
	while(currentrun.len)
		var/mob/living/L = currentrun[currentrun.len]
		currentrun.len--
		if(L)
			// Бакет: моб сам забронировал фаер, раньше которого его Life() - это
			// гарантированный no-op (троттл дальних/мёртвых/пустых z-уровней в
			// life.dm). Срочные переходы снимают бронь через wake_life().
			if(L.life_next_fire > times_fired)
				skipped_this_pass++
			else if(profiling)
				var/item_type = L.type
				var/item_start_usage = TICK_USAGE
				// Если Life() поспал, замер захватил чужую работу - помечаем, иначе
				// один "26мс" моб уводит расследование не туда.
				var/item_start_time = world.time
				L.Life(seconds, times_fired)
				profile_note(item_type, max(0, TICK_DELTA_TO_MS(TICK_USAGE - item_start_usage)), L, world.time != item_start_time)
			else
				L.Life(seconds, times_fired)
		else
			GLOB.mob_living_list.Remove(L)
		if (MC_TICK_CHECK)
			current_pass_cost_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - slice_start_usage))
			return

	current_pass_cost_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - slice_start_usage))
	skipped_last_pass = skipped_this_pass
	on_pass_finished(length(GLOB.mob_living_list))
