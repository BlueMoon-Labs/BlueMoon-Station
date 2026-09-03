// Координатор окружения стаи. На одну цель держит до AI_ENCIRCLE_MAX
// координирующих контроллеров и занятое каждым НАПРАВЛЕНИЕ-слот вокруг цели, чтобы
// стая расходилась по разным сторонам и закрывала пути отхода, а не толпилась.
// Отдельный datum слушает удаление цели, поэтому глобальный реестр не удерживает
// qdeleted atom. Паттерн жизненного цикла повторяет /datum/ai_target_reservation.

/datum/ai_controller
	/// Текущий координатор окружения (задачная привязка к живой цели), если координируем.
	var/datum/ai_pack_focus/pack_focus

/datum/ai_pack_focus
	var/atom/target
	/// controller -> занятое направление (NONE = член есть, но слот ещё не выбран)
	var/list/members = list()
	var/max_members = AI_ENCIRCLE_MAX

/datum/ai_pack_focus/New(atom/new_target)
	if(QDELETED(new_target))
		qdel(src)
		return
	target = new_target
	GLOB.ai_pack_focuses[target] = src
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(on_target_qdeleting))

/datum/ai_pack_focus/Destroy(force)
	if(target)
		UnregisterSignal(target, COMSIG_PARENT_QDELETING)
		if(GLOB.ai_pack_focuses[target] == src)
			GLOB.ai_pack_focuses -= target
	for(var/datum/ai_controller/controller as anything in members)
		if(controller.pack_focus == src)
			controller.pack_focus = null
	members.Cut()
	target = null
	return ..()

/datum/ai_pack_focus/proc/on_target_qdeleting(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// Снять из состава ушедших и рассинхронизированных членов.
/datum/ai_pack_focus/proc/prune()
	for(var/datum/ai_controller/existing as anything in members)
		if(QDELETED(existing) || existing.pack_focus != src)
			members -= existing

/// Вступить в координатор (идемпотентно). FALSE = кап полон, координировать нельзя.
/datum/ai_pack_focus/proc/try_join(datum/ai_controller/controller)
	if(QDELETED(controller) || QDELETED(target))
		return FALSE
	if(controller in members)
		return TRUE
	prune()
	if(length(members) >= max_members)
		return FALSE
	members[controller] = NONE //член есть, направление ещё не выбрано
	controller.pack_focus = src
	return TRUE

/// Занять направление-слот вокруг цели.
/datum/ai_pack_focus/proc/claim_direction(datum/ai_controller/controller, direction)
	if(!(controller in members))
		return FALSE
	members[controller] = direction
	return TRUE

/// Направления, уже занятые ДРУГИМИ членами (для исключения и подсчёта брешей).
/datum/ai_pack_focus/proc/taken_directions(datum/ai_controller/except)
	. = list()
	for(var/datum/ai_controller/member as anything in members)
		if(member == except || QDELETED(member))
			continue
		var/claimed = members[member]
		if(claimed)
			. += claimed

/datum/ai_pack_focus/proc/release(datum/ai_controller/controller)
	members -= controller
	if(controller?.pack_focus == src)
		controller.pack_focus = null
	if(!length(members) && !QDELETED(src))
		qdel(src)

/// Подключиться к координатору новой цели (освободив прежний). FALSE = кап полон.
/datum/ai_controller/proc/join_pack_focus(atom/new_target)
	if(QDELETED(new_target))
		return FALSE
	if(pack_focus?.target == new_target)
		return pack_focus.try_join(src)
	release_pack_focus()
	var/datum/ai_pack_focus/focus = GLOB.ai_pack_focuses[new_target]
	if(QDELETED(focus))
		focus = new(new_target)
	return focus.try_join(src)

/datum/ai_controller/proc/release_pack_focus()
	if(pack_focus)
		pack_focus.release(src)
