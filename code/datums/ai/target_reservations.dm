// Небольшой общий примитив резервирования задач между AI. Отдельный datum
// слушает удаление цели, поэтому глобальный реестр не удерживает qdeleted atom,
// а контроллеры не регистрируют второй конфликтующий QDELETING-сигнал.

/datum/ai_target_reservation
	var/atom/target
	var/list/holders = list()
	var/max_holders = 1

/datum/ai_target_reservation/New(atom/new_target, new_max_holders = 1)
	if(QDELETED(new_target))
		qdel(src)
		return
	target = new_target
	max_holders = max(1, new_max_holders)
	GLOB.ai_target_reservations[target] = src
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(on_target_qdeleting))

/datum/ai_target_reservation/Destroy(force)
	if(target)
		UnregisterSignal(target, COMSIG_PARENT_QDELETING)
		if(GLOB.ai_target_reservations[target] == src)
			GLOB.ai_target_reservations -= target
	for(var/datum/ai_controller/controller as anything in holders)
		if(controller.task_reservation == src)
			controller.task_reservation = null
	holders.Cut()
	target = null
	return ..()

/datum/ai_target_reservation/proc/on_target_qdeleting(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/ai_target_reservation/proc/try_acquire(datum/ai_controller/controller)
	if(QDELETED(controller) || QDELETED(target))
		return FALSE
	if(holders[controller])
		return TRUE
	prune_holders()
	if(length(holders) >= max_holders)
		return FALSE
	holders[controller] = controller.ai_pack_role
	controller.task_reservation = src
	return TRUE

/datum/ai_target_reservation/proc/prune_holders()
	for(var/datum/ai_controller/existing as anything in holders)
		if(QDELETED(existing) || existing.task_reservation != src)
			holders -= existing

/datum/ai_target_reservation/proc/can_acquire(datum/ai_controller/controller)
	prune_holders()
	return !!holders[controller] || length(holders) < max_holders

/datum/ai_target_reservation/proc/release(datum/ai_controller/controller)
	holders -= controller
	if(controller?.task_reservation == src)
		controller.task_reservation = null
	if(!length(holders) && !QDELETED(src))
		qdel(src)

/datum/ai_controller/proc/reserve_ai_target(atom/new_target, max_holders = 1)
	if(QDELETED(new_target))
		return FALSE
	if(task_reservation?.target == new_target)
		return task_reservation.try_acquire(src)
	release_ai_target_reservation()
	var/datum/ai_target_reservation/reservation = GLOB.ai_target_reservations[new_target]
	if(QDELETED(reservation))
		reservation = new(new_target, max_holders)
	return reservation.try_acquire(src)

/datum/ai_controller/proc/release_ai_target_reservation()
	if(task_reservation)
		task_reservation.release(src)
