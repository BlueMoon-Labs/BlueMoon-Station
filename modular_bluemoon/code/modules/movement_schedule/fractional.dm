/datum/fractional_movement_schedule
	var/render_mode = FRACTIONAL_MOVEMENT_NATIVE
	var/datum/weakref/mover_ref
	var/active = FALSE
	var/in_step = FALSE
	var/interrupted = FALSE
	var/visual_valid = FALSE
	var/remainder = 0
	var/next_target = 0
	var/owned_target = 0
	var/step_cost = 0
	var/step_interval = 0
	var/last_tick_lag = 0
	var/applied_glide = 0
	var/previous_glide = 0
	var/saved_animation
	var/client/camera
	var/list/observer_cameras
	var/render_slot = 0
	var/render_delay = 0
	var/render_ready_at = 0
	var/start_x = 0
	var/start_y = 0
	var/start_z = 0
	var/visual_distance = 0
	var/visual_duration = 0

/datum/fractional_movement_schedule/New(new_render_mode = FRACTIONAL_MOVEMENT_NATIVE)
	. = ..()
	render_mode = new_render_mode

/datum/fractional_movement_schedule/Destroy()
	unwatch()
	return ..()

/datum/fractional_movement_schedule/proc/unwatch()
	invalidate()
	var/mob/mover = mover_ref?.resolve()
	if(mover)
		UnregisterSignal(mover, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_MOB_RESET_PERSPECTIVE))
	mover_ref = null

/datum/fractional_movement_schedule/proc/invalidate()
	active = FALSE
	visual_valid = FALSE
	remainder = 0
	interrupted = TRUE
	stop_rendering()

/datum/fractional_movement_schedule/proc/stop_rendering()
	var/mob/mover = mover_ref?.resolve()
	if(mover && !isnull(saved_animation))
		stop_animations(mover)
		if(mover.animate_movement == NO_STEPS)
			mover.animate_movement = saved_animation
	saved_animation = null
	render_ready_at = 0
	var/client/viewer = camera
	if(viewer)
		stop_animations(viewer)
	camera = null
	for(var/datum/weakref/observer_ref as anything in observer_cameras)
		stop_observer_camera(observer_ref)
	observer_cameras = null

/datum/fractional_movement_schedule/proc/stop_observer_camera(datum/weakref/observer_ref)
	var/mob/observer = observer_ref.resolve()
	if(observer)
		UnregisterSignal(observer, list(COMSIG_MOB_RESET_PERSPECTIVE, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_PARENT_QDELETING))
	var/client/viewer = observer_cameras[observer_ref]
	if(viewer)
		stop_animations(viewer)

/datum/fractional_movement_schedule/proc/on_observer_changed(mob/observer)
	SIGNAL_HANDLER
	var/datum/weakref/observer_ref = observer.weak_reference
	if(!observer_ref || !observer_cameras?[observer_ref])
		return
	stop_observer_camera(observer_ref)
	observer_cameras -= observer_ref

/datum/fractional_movement_schedule/proc/watch_observers(mob/mover)
	for(var/datum/weakref/observer_ref as anything in observer_cameras?.Copy())
		var/mob/observer = observer_ref.resolve()
		if(observer?.client?.eye != mover)
			stop_observer_camera(observer_ref)
			observer_cameras -= observer_ref
	for(var/mob/observer as anything in mover.observers)
		if(observer.client?.eye != mover)
			continue
		if(!observer_cameras)
			observer_cameras = list()
		var/datum/weakref/observer_ref = WEAKREF(observer)
		if(observer_cameras[observer_ref])
			continue
		observer_cameras[observer_ref] = observer.client
		RegisterSignal(observer, list(COMSIG_MOB_RESET_PERSPECTIVE, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_PARENT_QDELETING), PROC_REF(on_observer_changed))

/datum/fractional_movement_schedule/proc/stop_animations(datum/target)
	for(var/slot in 0 to FRACTIONAL_MOVEMENT_ANIMATION_SLOTS - 1)
		animate(target, tag = "fractional_movement_[slot]", flags = ANIMATION_END_NOW)

/datum/fractional_movement_schedule/proc/on_moved(datum/source, atom/old_loc, direction, forced)
	SIGNAL_HANDLER
	if(!in_step || forced)
		invalidate()

/datum/fractional_movement_schedule/proc/on_deleted(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_MOB_RESET_PERSPECTIVE))
	unwatch()

/datum/fractional_movement_schedule/proc/on_perspective_changed(mob/source)
	SIGNAL_HANDLER
	if(source.client?.eye != source)
		invalidate()

/datum/fractional_movement_schedule/proc/on_client_logout(datum/source)
	SIGNAL_HANDLER
	unwatch()

/datum/fractional_movement_schedule/proc/begin_step(mob/mover, current_target, now, tick_lag)
	if(mover_ref?.resolve() == mover && !isnull(saved_animation) && mover.animate_movement != NO_STEPS)
		unwatch()
		return FALSE
	var/animation_mode = mover_ref?.resolve() == mover && !isnull(saved_animation) ? saved_animation : mover.animate_movement
	if(!isturf(mover.loc) || mover.movement_type & FLOATING || mover.pulling || mover.pulledby || mover.buckled || length(mover.buckled_mobs) || animation_mode != SLIDE_STEPS || tick_lag <= 0)
		invalidate()
		return FALSE
	if(mover_ref?.resolve() != mover)
		unwatch()
		mover_ref = WEAKREF(mover)
		RegisterSignal(mover, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
		RegisterSignal(mover, COMSIG_PARENT_QDELETING, PROC_REF(on_deleted))
		RegisterSignal(mover, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_client_logout))
		RegisterSignal(mover, COMSIG_MOB_RESET_PERSPECTIVE, PROC_REF(on_perspective_changed))
	if(last_tick_lag != tick_lag)
		invalidate()
	last_tick_lag = tick_lag
	if(!active || current_target != next_target || now != next_target)
		remainder = 0
	render_delay = 0
	if(render_mode == FRACTIONAL_MOVEMENT_QUEUED)
		render_delay = tick_lag - remainder
		if(isnull(saved_animation))
			saved_animation = mover.animate_movement
			render_ready_at = now + tick_lag
		mover.animate_movement = NO_STEPS
		// Клиент должен получить NO_STEPS раньше первого перемещения с компенсацией.
		if(now < render_ready_at)
			return FRACTIONAL_MOVEMENT_PREPARING
		if(mover.client?.eye == mover)
			camera = mover.client
		else if(camera)
			var/client/previous_viewer = camera
			if(previous_viewer)
				stop_animations(previous_viewer)
			camera = null
		watch_observers(mover)
	start_x = mover.x
	start_y = mover.y
	start_z = mover.z
	previous_glide = mover.glide_size
	in_step = TRUE
	interrupted = FALSE
	return TRUE

/datum/fractional_movement_schedule/proc/finish_step(mob/mover, base_delay, diagonal, now, external_target, tick_lag, icon_size, dilation)
	in_step = FALSE
	step_cost = max(tick_lag, base_delay * (diagonal ? SQRT_2 : 1))
	var/delta_x = mover.x - start_x
	var/delta_y = mover.y - start_y
	var/moved = delta_x || delta_y
	var/regular_step = !interrupted && mover_ref?.resolve() == mover && isturf(mover.loc) && mover.z == start_z && max(abs(delta_x), abs(delta_y)) <= 1
	if(!regular_step || !moved)
		remainder = 0
	active = regular_step && moved
	plan_step(step_cost, now, external_target, tick_lag)
	if(!regular_step)
		invalidate()
		return
	if(!moved)
		mover.set_glide_size(previous_glide)
		return
	visual_duration = render_delay + step_cost
	visual_distance = max(abs(delta_x), abs(delta_y)) * icon_size
	applied_glide = min(MAX_GLIDE_SIZE, icon_size * tick_lag / step_cost * dilation)
	visual_valid = TRUE
	mover.set_glide_size(applied_glide)
	if(render_mode == FRACTIONAL_MOVEMENT_NATIVE)
		return
	render_slot = (render_slot + 1) % FRACTIONAL_MOVEMENT_ANIMATION_SLOTS
	var/tag_name = "fractional_movement_[render_slot]"
	var/duration_scale = 1 / max(dilation, MOVEMENT_TICK_EPSILON)
	queue_animation(mover, delta_x * icon_size, delta_y * icon_size, render_delay * duration_scale, step_cost * duration_scale, tag_name)
	var/client/viewer = camera
	if(viewer?.eye == mover)
		queue_animation(viewer, delta_x * icon_size, delta_y * icon_size, render_delay * duration_scale, step_cost * duration_scale, tag_name)
	for(var/datum/weakref/observer_ref as anything in observer_cameras)
		var/client/observer_viewer = observer_cameras[observer_ref]
		if(observer_viewer?.eye == mover && observer_viewer != viewer)
			queue_animation(observer_viewer, delta_x * icon_size, delta_y * icon_size, render_delay * duration_scale, step_cost * duration_scale, tag_name)

/datum/fractional_movement_schedule/proc/queue_animation(datum/target, delta_x, delta_y, wait_time, step_time, tag_name)
	// Нулевая ступень animate() оставляет лишнее смещение при смене dir в BYOND 516.1687.
	if(istype(target, /client))
		var/client/viewer = target
		viewer.pixel_x -= delta_x
		viewer.pixel_y -= delta_y
	else
		var/atom/movable/mover = target
		mover.pixel_x -= delta_x
		mover.pixel_y -= delta_y
	animate(target, pixel_x = 0, pixel_y = 0, time = wait_time, flags = ANIMATION_RELATIVE | ANIMATION_END_NOW, tag = tag_name)
	animate(pixel_x = delta_x, pixel_y = delta_y, time = step_time, flags = ANIMATION_RELATIVE)

/datum/fractional_movement_schedule/proc/plan_step(cost, now, external_target, tick_lag)
	step_cost = max(tick_lag, cost)
	step_interval = movement_ticks_until(step_cost - remainder, 0, tick_lag) * tick_lag
	remainder = clamp(step_interval - step_cost + remainder, 0, tick_lag)
	if(remainder < MOVEMENT_TICK_EPSILON)
		remainder = 0
	next_target = now + step_interval
	owned_target = next_target
	// Штраф, выданный внутри Move(), не принадлежит расписанию шага.
	if(external_target > now + tick_lag)
		next_target = max(next_target, external_target)
		active = FALSE
		remainder = 0

/client/proc/fractional_movement_toggle()
	set name = "Дробное движение"
	set category = "Debug"
	set desc = "Выбрать основной режим движения или режим для сравнения"
	if(!check_rights(R_DEBUG))
		return
	var/list/modes = list("Прежнее: округлённый шаг", "Дробное: штатный glide", "Дробное: сглаженная очередь (основной)")
	var/current_mode = fractional_movement ? (fractional_movement.render_mode == FRACTIONAL_MOVEMENT_QUEUED ? modes[3] : modes[2]) : modes[1]
	var/selected = tgui_input_list(src, "Режим только для вашего подключения. При входе включается сглаженная очередь. FPS не меняется.", "Дробное движение", modes, current_mode)
	if(!selected || !check_rights(R_DEBUG))
		return
	QDEL_NULL(fractional_movement)
	if(selected == modes[1])
		to_chat(src, span_notice("Выбрано прежнее движение с округлением цены шага. При следующем подключении включится сглаженная очередь."))
	else
		fractional_movement = new(selected == modes[2] ? FRACTIONAL_MOVEMENT_NATIVE : FRACTIONAL_MOVEMENT_QUEUED)
		to_chat(src, span_notice("Выбран режим: [selected]. Скорость меняется со следующего шага. Транспорт, пуллинг, ИИ и дрейф используют прежнее расписание."))
		if(selected == modes[3])
			to_chat(src, span_notice("Очередь добавляет один тик визуальной задержки; первый шаг после прерывания требует ещё тик подготовки."))
	last_step_target = 0
	last_step_cost = 0
	log_admin("[key_name(src)] selected movement mode: [selected].")
