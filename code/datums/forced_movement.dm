//Just new and forget
/datum/forced_movement
	var/atom/movable/victim
	var/atom/target
	var/last_processed
	var/steps_per_tick
	var/allow_climbing
	var/datum/callback/on_step
	var/moved_at_all = FALSE
	var/drift_released = FALSE // BLUEMOON ADD - скольжение уже передало жертву космическому дрейфу
															//as fast as ssfastprocess
/datum/forced_movement/New(atom/movable/_victim, atom/_target, _steps_per_tick = 0.5, _allow_climbing = FALSE, datum/callback/_on_step = null)
	victim = _victim
	target = _target
	steps_per_tick = _steps_per_tick
	allow_climbing = _allow_climbing
	on_step = _on_step

	. = ..()

	if(_victim && _target && _steps_per_tick && !_victim.force_moving)
		last_processed = world.time
		_victim.force_moving = src
		START_PROCESSING(SSfastprocess, src)
	else
		qdel(src)	//if you want to overwrite the current forced movement, call qdel(victim.force_moving) before creating this

/datum/forced_movement/Destroy()
	if(victim.force_moving == src)
		victim.force_moving = null
		if(moved_at_all)
			victim.forceMove(victim.loc)	//get the side effects of moving here that require us to currently not be force_moving aka reslipping on ice
		STOP_PROCESSING(SSfastprocess, src)
	victim = null
	target = null
	return ..()

/datum/forced_movement/process()
	if(QDELETED(victim) || !victim.loc || QDELETED(target) || !target.loc)
		qdel(src)
		return
	var/steps_to_take = round(steps_per_tick * (world.time - last_processed))
	if(steps_to_take)
		for(var/i in 1 to steps_to_take)
			if(TryMove())
				moved_at_all = TRUE
				if(on_step)
					on_step.InvokeAsync()
			else
				qdel(src)
				return
		last_processed = world.time

/datum/forced_movement/proc/TryMove(recursive = FALSE)
	var/atom/movable/vic = victim	//sanic
	var/atom/tar = target

	if(!recursive)
		. = step_towards(vic, tar)

	//shit way for getting around corners
	if(!.)
		if(tar.x > vic.x)
			if(step(vic, EAST))
				. = TRUE
		else if(tar.x < vic.x)
			if(step(vic, WEST))
				. = TRUE

		if(!.)
			if(tar.y > vic.y)
				if(step(vic, NORTH))
					. = TRUE
			else if(tar.y < vic.y)
				if(step(vic, SOUTH))
					. = TRUE

			if(!.)
				if(recursive)
					return FALSE
				else
					. = TryMove(TRUE)

	. = . && (vic.loc != tar.loc)

/mob/Bump(atom/A)
	. = ..()
	if(force_moving && force_moving.allow_climbing && isstructure(A))
		var/obj/structure/S = A
		if(S.climbable)
			S.do_climb(src)

/// BLUEMOON ADD - on_step-коллбек скольжения с флагом SLIDE_INTO_SPACE (суперлубрикант).
/// Крутит жертву, как обычное скольжение. Как только тело покидает гравитацию,
/// принудительное скольжение НЕ тянется бесконечно: даём ему сделать ещё один шаг
/// по курсу и передаём тело честному ньютоновскому дрейфу. Дальше игрок выбирается
/// сам - бросок предмета меняет траекторию, работает джетпак, можно подхватить.
/proc/slide_into_space_step(mob/living/carbon/victim, slide_dir)
	if(!istype(victim) || QDELETED(victim))
		return
	victim.spin(1, 1)
	var/datum/forced_movement/FM = victim.force_moving
	if(!FM || QDELETED(FM))
		return
	var/turf/T = get_turf(victim)
	if(!T || T.has_gravity(victim))
		return // ещё на полу - обычное скольжение
	if(FM.drift_released)
		return // финальный шаг уже назначен
	FM.drift_released = TRUE
	FM.target = get_step(T, slide_dir) // доехали до этой клетки - и всё, datum завершится сам
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(release_into_space_drift), WEAKREF(victim), slide_dir), 2)

/// Запуск дрейфа после завершения forced_movement (Destroy() сбрасывает инерцию,
/// поэтому newtonian_move зовём только когда victim.force_moving уже пуст)
/proc/release_into_space_drift(datum/weakref/W, slide_dir)
	var/mob/living/carbon/victim = W?.resolve()
	if(!istype(victim) || QDELETED(victim))
		return
	if(victim.force_moving) // ещё шагает - повторим попытку следующим тиком
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(release_into_space_drift), W, slide_dir), 2)
		return
	victim.newtonian_move(slide_dir)
