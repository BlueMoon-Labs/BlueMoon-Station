// File for movement procs for atom/movable


////////////////////////////////////////
// Here's where we rewrite how byond handles movement except slightly different
// To be removed on step_ conversion
// All this work to prevent a second bump
/atom/movable/Move(atom/newloc, direct=0, glide_size_override = 0)
	. = FALSE
	if(!newloc || newloc == loc)
		return

	if(!direct)
		direct = get_dir(src, newloc)
	setDir(direct)

	if(!loc.Exit(src, newloc))
		return

	if(!newloc.Enter(src, src.loc))
		return

	if (SEND_SIGNAL(src, COMSIG_MOVABLE_PRE_MOVE, newloc) & COMPONENT_MOVABLE_BLOCK_PRE_MOVE)
		return

	// Past this is the point of no return
	var/atom/oldloc = loc
	var/area/oldarea = get_area(oldloc)
	var/area/newarea = get_area(newloc)
	loc = newloc
	. = TRUE
	oldloc.Exited(src, newloc)
	if(oldarea != newarea)
		oldarea.Exited(src, newloc)

	if(length(oldloc.contents))
		for(var/atom/movable/thing as anything in oldloc)
			if(thing == src) // Multi tile objects
				continue
			thing.Uncrossed(src)

	newloc.Entered(src, oldloc)
	if(oldarea != newarea)
		newarea.Entered(src, oldloc)

	if(loc && length(loc.contents))
		for(var/atom/movable/thing as anything in loc)
			if(thing == src) // Multi tile objects
				continue
			thing.Crossed(src)

/**
 * meant for movement with zero side effects. only use for objects that are supposed to move "invisibly" (like camera mobs or ghosts)
 * if you want something to move onto a tile with a beartrap or recycler or tripmine or mouse without that object knowing about it at all, use this
 * most of the time you want forceMove()
 */
/atom/movable/proc/abstract_move(atom/new_loc)
	var/atom/old_loc = loc
	// move_stacks++
	loc = new_loc
	Moved(old_loc)

/atom/movable/Move(atom/newloc, direct, glide_size_override = 0)
	var/atom/movable/pullee = pulling
	var/turf/T = loc
	if(!moving_from_pull)
		check_pulling()
	if(!loc || !newloc)
		return FALSE
	var/atom/oldloc = loc
	//Early override for some cases like diagonal movement
	if(glide_size_override)
		set_glide_size(glide_size_override, FALSE)

	if(loc != newloc)
		if (!(direct & (direct - 1))) //Cardinal move
			. = ..()
		else //Diagonal move, split it into cardinal moves
			moving_diagonally = FIRST_DIAG_STEP
			var/first_step_dir
			// The `&& moving_diagonally` checks are so that a forceMove taking
			// place due to a Crossed, Bumped, etc. call will interrupt
			// the second half of the diagonal movement, or the second attempt
			// at a first half if step() fails because we hit something.
			if (direct & NORTH)
				if (direct & EAST)
					if (step(src, NORTH) && moving_diagonally)
						first_step_dir = NORTH
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, EAST)
					else if (moving_diagonally && step(src, EAST))
						first_step_dir = EAST
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, NORTH)
				else if (direct & WEST)
					if (step(src, NORTH) && moving_diagonally)
						first_step_dir = NORTH
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, WEST)
					else if (moving_diagonally && step(src, WEST))
						first_step_dir = WEST
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, NORTH)
			else if (direct & SOUTH)
				if (direct & EAST)
					if (step(src, SOUTH) && moving_diagonally)
						first_step_dir = SOUTH
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, EAST)
					else if (moving_diagonally && step(src, EAST))
						first_step_dir = EAST
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, SOUTH)
				else if (direct & WEST)
					if (step(src, SOUTH) && moving_diagonally)
						first_step_dir = SOUTH
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, WEST)
					else if (moving_diagonally && step(src, WEST))
						first_step_dir = WEST
						moving_diagonally = SECOND_DIAG_STEP
						. = step(src, SOUTH)
			if(moving_diagonally == SECOND_DIAG_STEP)
				if(!.)
					setDir(first_step_dir)
					// Half-finished diagonal: one cardinal step succeeded — match old inertia (Moved skipped newtonian during split).
					if(!inertia_moving && first_step_dir)
						inertia_next_move = world.time + inertia_move_delay
						newtonian_move(first_step_dir, drift_force = self_thrust_force, controlled_cap = self_thrust_cap)
				else if (!inertia_moving)
					inertia_next_move = world.time + inertia_move_delay
					// Single combined impulse — do not stack with per-cardinal Moved() calls during this diagonal.
					newtonian_move(direct, drift_force = self_thrust_force, controlled_cap = self_thrust_cap)
			moving_diagonally = 0
			return

	if(!loc || (loc == oldloc && oldloc != newloc))
		last_move = 0
		return

	setDir(direct)
	if(.)
		Moved(oldloc, direct)
	if(. && pulling && pulling == pullee && pulling != moving_from_pull) //we were pulling a thing and didn't lose it during our move.
		if(pulling.anchored)
			stop_pulling()
		else
			var/pull_dir = get_dir(src, pulling)
			//puller and pullee more than one tile away or in diagonal position
			if(get_dist(src, pulling) > 1 || (moving_diagonally != SECOND_DIAG_STEP && ((pull_dir - 1) & pull_dir)))
				pulling.moving_from_pull = src
				pulling.Move(T, get_dir(pulling, T), glide_size) //the pullee tries to reach our previous position
				pulling.moving_from_pull = null
			check_pulling()


	//glide_size strangely enough can change mid movement animation and update correctly while the animation is playing
	//This means that if you don't override it late like this, it will just be set back by the movement update that's called when you move turfs.
	if(glide_size_override)
		set_glide_size(glide_size_override, FALSE)

	last_move = direct
	if(. && has_buckled_mobs() && !handle_buckled_mob_movement(loc, direct, glide_size_override)) //movement failed due to buckled mob(s)
		return FALSE

/atom/movable/proc/handle_buckled_mob_movement(newloc, direct, glide_size_override)
	for(var/mob/living/buckled_mob as anything in buckled_mobs)
		if(!buckled_mob.Move(newloc, direct, glide_size_override))
			forceMove(buckled_mob.loc)
			last_move = buckled_mob.last_move
			inertia_dir = last_move
			buckled_mob.inertia_dir = last_move
			return FALSE
	return TRUE

//Called after a successful Move(). By this point, we've already moved
/atom/movable/proc/Moved(atom/OldLoc, Dir, Forced = FALSE)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_MOVABLE_MOVED, OldLoc, Dir, Forced)

	//спатиал-грид: перекладываем содержимое наших каналов при пересечении
	//границы ячеек (для большинства movables это одна null-проверка ключа)
	if(HAS_SPATIAL_GRID_CONTENTS(src))
		var/turf/old_turf = get_turf(OldLoc)
		var/turf/new_turf = get_turf(src)
		if(old_turf && new_turf && (old_turf.z != new_turf.z \
			|| GET_SPATIAL_INDEX(old_turf.x) != GET_SPATIAL_INDEX(new_turf.x) \
			|| GET_SPATIAL_INDEX(old_turf.y) != GET_SPATIAL_INDEX(new_turf.y)))
			SSspatial_grid.exit_cell(src, old_turf)
			SSspatial_grid.enter_cell(src, new_turf)
		else if(old_turf && !new_turf)
			SSspatial_grid.exit_cell(src, old_turf)
		else if(new_turf && !old_turf)
			SSspatial_grid.enter_cell(src, new_turf)
	// Diagonal intents are split into two cardinals inside Move(); defer newtonian to one call at split end (see above).
	if (!inertia_moving && !HAS_TRAIT(src, TRAIT_HYPERSPACED) && !moving_diagonally)
		inertia_next_move = world.time + inertia_move_delay
		// Потолок собственной тяги: шаг доливает дрейф до крейсерской скорости своего
		// двигателя и дальше не разгоняет. Взрыв или отдача выше потолка не срезаются -
		// controlled_cap берётся как max(текущая сила, потолок).
		newtonian_move(Dir, drift_force = self_thrust_force, controlled_cap = self_thrust_cap)
	return TRUE

// Make sure you know what you're doing if you call this, this is intended to only be called by byond directly.
// You probably want CanPass()
/atom/movable/Cross(atom/movable/AM)
	. = TRUE
	SEND_SIGNAL(src, COMSIG_MOVABLE_CROSS, AM)
	return CanPass(AM, AM.loc, TRUE)

//oldloc = old location on atom, inserted when forceMove is called and ONLY when forceMove is called!
/atom/movable/Crossed(atom/movable/AM, oldloc)
	// SHOULD_CALL_PARENT(TRUE)
	. = ..()
	SEND_SIGNAL(src, COMSIG_MOVABLE_CROSSED, AM)

/**
 * Спрашивают, когда что-то СОБИРАЕТСЯ покинуть турф, на котором мы стоим -
 * вернуть FALSE значит не пустить. Так работают бордюрные объекты: боковое окно
 * или перила пропускают во все стороны, кроме своей.
 *
 * Зовётся только из [/turf/Exit] и только для атомов с `blocks_exit_checks`.
 * Нативный проход BYOND по contents отключён (см. [/atom/Exit]), потому что он
 * дёргал этот прок на КАЖДОМ атоме в турфе при каждом шаге - 553k вызовов за 78
 * секунд раунда 9800, притом что запретить выход не могло почти ничто.
 *
 * Поэтому переопределение Uncross() на типе, у которого `blocks_exit_checks`
 * выключен (любой /mob, любой /obj/item), НЕ РАБОТАЕТ - оно просто не будет
 * вызвано. Нужен запрет выхода на таком типе - вешай COMSIG_ATOM_EXIT через
 * /datum/element/connect_loc, это дешевле и не требует обхода contents.
 */
/atom/movable/Uncross(atom/movable/AM, atom/newloc)
	. = ..()
	if(SEND_SIGNAL(src, COMSIG_MOVABLE_UNCROSS, AM) & COMPONENT_MOVABLE_BLOCK_UNCROSS)
		return FALSE
	if(isturf(newloc) && !CheckExit(AM, newloc))
		return FALSE

/atom/movable/Uncrossed(atom/movable/AM)
	SEND_SIGNAL(src, COMSIG_MOVABLE_UNCROSSED, AM)

/atom/movable/Bump(atom/A)
	if(!A)
		CRASH("Bump was called with no argument.")
	SEND_SIGNAL(src, COMSIG_MOVABLE_BUMP, A)
	. = ..()
	if(!QDELETED(throwing))
		throwing.finalize(hit = TRUE, target = A)
		. = TRUE
		if(QDELETED(A))
			return
	A.Bumped(src)

/atom/movable/proc/onTransitZ(old_z,new_z)
	SEND_SIGNAL(src, COMSIG_MOVABLE_Z_CHANGED, old_z, new_z)
	for (var/atom/movable/AM as anything in src) // Notify contents of Z-transition. This can be overridden IF we know the items contents do not care.
		AM.onTransitZ(old_z,new_z)

///Separate from COMSIG_MOVABLE_Z_CHANGED: its older listeners do not all accept a null destination.
/atom/movable/proc/onEnteredNullspace(old_z)
	SEND_SIGNAL(src, COMSIG_MOVABLE_ENTERED_NULLSPACE, old_z, null)
	for(var/atom/movable/movable_content as anything in src)
		movable_content.onEnteredNullspace(old_z)

///Proc to modify the movement_type and hook behavior associated with it changing.
/atom/movable/proc/setMovetype(newval)
	if(movement_type == newval)
		return
	. = movement_type
	movement_type = newval

///////////// FORCED MOVEMENT /////////////

/atom/movable/proc/forceMove(atom/destination)
	. = FALSE
	if(destination == null) //destination destroyed due to explosion
		return

	if(destination)
		. = doMove(destination)
	else
		CRASH("No valid destination passed into forceMove")

/atom/movable/proc/moveToNullspace()
	return doMove(null)

/atom/movable/proc/doMove(atom/destination)
	. = FALSE
	if(destination)
		// Возврат qdel-нутого мувера в мир = вечный пин ссылкой из contents турфа
		// (класс "post-qdel forceMove" по уликам warnfail раунда 9746: обсерверы,
		// оффхенды). Отказываем и именуем виновника - стек тут синхронный.
		if(QDELETED(src))
			stack_trace("doMove qdel-нутого [type] в [destination] ([destination.type])")
			return
		if(pulledby)
			pulledby.stop_pulling()
		var/atom/oldloc = loc
		var/same_loc = oldloc == destination
		var/area/old_area = get_area(oldloc)
		var/area/destarea = get_area(destination)

		loc = destination
		moving_diagonally = 0

		if(!same_loc)
			if(oldloc)
				oldloc.Exited(src, destination)
				if(old_area && old_area != destarea)
					old_area.Exited(src, destination)
			if(oldloc && length(oldloc.contents))
				for(var/atom/movable/AM as anything in oldloc)
					AM.Uncrossed(src)
			var/turf/oldturf = get_turf(oldloc)
			var/turf/destturf = get_turf(destination)
			var/old_z = (oldturf ? oldturf.z : null)
			var/dest_z = (destturf ? destturf.z : null)
			if (old_z != dest_z)
				onTransitZ(old_z, dest_z)
			destination.Entered(src, oldloc)
			if(destarea && old_area != destarea)
				destarea.Entered(src, oldloc)

			if(length(destination.contents))
				for(var/atom/movable/AM as anything in destination)
					if(AM == src)
						continue
					AM.Crossed(src, oldloc)

		Moved(oldloc, NONE, TRUE)
		. = TRUE

	//If no destination, move the atom into nullspace (don't do this unless you know what you're doing)
	else
		. = TRUE
		if (loc)
			var/atom/oldloc = loc
			var/turf/old_turf = get_turf(oldloc)
			var/area/old_area = get_area(oldloc)
			//эта ветка не зовёт Moved(), поэтому спатиал-грид чистим сами:
			//иначе уход в nullspace оставит вечную ссылку в старой ячейке,
			//а возврат зарегистрирует вторую (см. Moved в этом файле)
			if(HAS_SPATIAL_GRID_CONTENTS(src))
				var/turf/old_grid_turf = get_turf(oldloc)
				if(old_grid_turf)
					SSspatial_grid.exit_cell(src, old_grid_turf)
			oldloc.Exited(src, null)
			if(old_area)
				old_area.Exited(src, null)
			loc = null
			if(old_turf)
				onEnteredNullspace(old_turf.z)

/**
 * Called whenever an object moves and by mobs when they attempt to move themselves through space
 * And when an object or action applies a force on src, see [newtonian_move][/atom/movable/proc/newtonian_move]
 *
 * return FALSE to have src start/keep drifting in a no-grav area and 1 to stop/not start drifting
 *
 * Mobs should return TRUE if they should be able to move of their own volition, see [/client/proc/Move]
 *
 * Arguments:
 * * movement_dir - 0 when stopping or any dir when trying to move
 * * continuous_move - TRUE when checking from the newtonian drift loop (not client step intent)
 */
/atom/movable/proc/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	if(has_gravity(src))
		return TRUE

	if(pulledby && (pulledby.pulledby != src || moving_from_pull))
		return TRUE

	if(throwing)
		return TRUE

	if(!isturf(loc))
		return TRUE

	var/turf/T = get_turf(src)
	if(length(T.contents) && (locate(/obj/structure/lattice) in T))
		return TRUE
	for(var/dir in GLOB.alldirs)
		var/turf/adj = get_step(T, dir)
		if(adj && length(adj.contents) && (locate(/obj/structure/lattice) in adj))
			return TRUE

	return FALSE

/// Subtype hook (e.g. lattice); [Process_Spacemove] already handles lattice on /atom/movable — mobs override and use backups
/atom/movable/proc/handle_spacemove_grabbing()
	return FALSE

/**
 * Объявляет, что [source] толкает нас собственной тягой: джетпак, имплант-трастеры, крылья.
 *
 * Источники держатся списком, а не пишут [self_thrust_cap] напрямую, потому что носитель
 * может нести сразу несколько, и выключенный первым затёр бы цифры оставшегося. Складываем
 * по максимуму: потолок задаёт лучший из работающих двигателей.
 *
 * Ключ - строка REF, а не сам датум: список живёт на мобе, и жёсткая ссылка на снятый
 * джетпак пережила бы его удаление. Сам источник лежит слабой ссылкой, и запись, чей источник
 * не воскрес, отсеивается на ближайшем пересчёте.
 */
/atom/movable/proc/register_thrust_source(datum/source, force = INERTIA_THRUST_FORCE_DEFAULT, cap = INERTIA_THRUST_CAP_JETPACK)
	if(QDELETED(source))
		return FALSE
	LAZYSET(thrust_sources, REF(source), list(force, cap, WEAKREF(source)))
	recalculate_self_thrust()
	return TRUE

/atom/movable/proc/unregister_thrust_source(datum/source)
	if(isnull(source) || !LAZYACCESS(thrust_sources, REF(source)))
		return FALSE
	LAZYREMOVE(thrust_sources, REF(source))
	recalculate_self_thrust()
	return TRUE

/**
 * Передаёт наш текущий дрейф отпущенному грузу.
 *
 * `controlled_cap` ставится равным передаваемой силе: груз получает ровно наш вектор, не
 * больше, и собственная тяга груза от этого не растёт.
 */
/atom/movable/proc/hand_off_drift(atom/movable/cargo)
	if(QDELETED(cargo) || isnull(drift_handler) || isnull(drift_handler.drifting_loop))
		return FALSE
	var/carried_force = drift_handler.drift_force
	if(carried_force <= 0)
		return FALSE
	// Пауза до нашего следующего шага: без неё груз обгонит буксир и врежется в него.
	var/start_delay = max(0, drift_handler.drifting_loop.timer - world.time + world.tick_lag)
	return cargo.newtonian_move(
		angle2dir(drift_handler.drifting_loop.angle),
		start_delay = start_delay,
		drift_force = carried_force,
		controlled_cap = carried_force,
	)

/// Пересобирает [self_thrust_force] и [self_thrust_cap] по живым источникам. Зовётся только при правке списка — [Moved] читает готовые значения.
/atom/movable/proc/recalculate_self_thrust()
	var/force = INERTIA_THRUST_FORCE_DEFAULT
	var/cap = INERTIA_THRUST_CAP_UNAIDED
	var/list/stale
	for(var/source_key in thrust_sources)
		var/list/profile = thrust_sources[source_key]
		var/datum/weakref/source_ref = profile[THRUST_SOURCE_REF]
		if(!source_ref?.resolve())
			// Вычищаем после обхода: правка списка внутри for-in сдвигает индексы и пропускает записи.
			LAZYADD(stale, source_key)
			continue
		force = max(force, profile[THRUST_SOURCE_FORCE])
		cap = max(cap, profile[THRUST_SOURCE_CAP])
	for(var/source_key in stale)
		LAZYREMOVE(thrust_sources, source_key)
	self_thrust_force = force
	self_thrust_cap = cap

/// Only moves the object if it's under no gravity. Uses smooth drift when possible. [inertia_dir] is a BYOND dir flag.
/atom/movable/proc/newtonian_move(
	inertia_dir,
	instant = FALSE,
	start_delay = 0,
	drift_force = 1,
	controlled_cap = null,
	force_loop = TRUE,
)
	if(!isturf(loc))
		src.inertia_dir = 0
		if(drift_handler)
			QDEL_IN(drift_handler, 0)
		return FALSE

	if(!inertia_dir)
		src.inertia_dir = 0
		if(drift_handler)
			QDEL_IN(drift_handler, 0)
		return TRUE

	if(Process_Spacemove(inertia_dir, TRUE))
		src.inertia_dir = 0
		if(drift_handler)
			QDEL_IN(drift_handler, 0)
		return FALSE

	SSspacedrift.processing -= src
	src.inertia_dir = inertia_dir
	var/inertia_angle = dir2angle(inertia_dir)
	var/capped = isnull(controlled_cap) ? drift_force : min(drift_force, controlled_cap)

	if(!isnull(drift_handler) && !QDELETED(drift_handler))
		if(drift_handler.newtonian_impulse(inertia_angle, start_delay, capped, controlled_cap, force_loop))
			return TRUE
		if(QDELETED(src))
			return FALSE

	// Defer: Destroy() must not clear a replacement drift_handler (see /datum/drift_handler/Destroy)
	if(drift_handler)
		var/datum/drift_handler/old_drift = drift_handler
		QDEL_IN(old_drift, 0)
	new /datum/drift_handler(src, inertia_angle, instant, start_delay, capped)
	if(QDELETED(drift_handler))
		src.inertia_dir = 0
		return FALSE
	return TRUE
