// Ключи - номера z полигонов: alist не требует проверки границ в горячем пути движения.
GLOBAL_LIST_INIT(antag_training_z, alist())

/atom/movable
	var/datum/weakref/training_origin
	var/datum/weakref/training_owner
	/// Сеанс, с чьим стартовым набором выдан предмет. Очистка своих объектов эту метку не читает.
	var/datum/weakref/training_kit_owner

/// Атом полигона: создан на арене или стоит на уровне живой арены.
/proc/is_antag_training_atom(atom/thing)
	var/atom/movable/movable = thing
	if(istype(movable) && movable.training_origin)
		return TRUE
	if(!length(GLOB.antag_training_z))
		return FALSE
	var/turf/spot = get_turf(thing)
	return !!(spot && GLOB.antag_training_z[spot.z])

/// Камеры полигона видны только с полигона, камеры станции - только со станции.
/proc/antag_training_camera_visible(obj/machinery/camera/camera, atom/viewer)
	return is_antag_training_atom(camera) == is_antag_training_atom(viewer)

/// Сообщение и запись для администраторов; с полигона - только запись в лог игры.
/proc/antag_training_admin_log(atom/where, admin_text, log_text)
	if(is_antag_training_atom(where))
		log_game(log_text)
		return
	message_admins(admin_text)
	log_admin(log_text)

/// Как antag_training_admin_log, но запись в лог игры и вне полигона, как у раундовых сообщений о бомбах и взрывах.
/proc/antag_training_game_log(atom/where, admin_text, log_text)
	if(!is_antag_training_atom(where))
		message_admins(admin_text)
	log_game(log_text)

/// Датумы, снятые с GLOB.antagonists, пока тело владельца - атом полигона. Обходы, которые чистят ссылки, идут и по этому списку.
GLOBAL_LIST_EMPTY(antag_training_unlisted_antagonists)

/// Датум тела полигона не виден раундовым обходам GLOB.antagonists; снятый так возвращается туда, когда тело уже не на полигоне.
/// Разум полигона без current transfer_to() пускает в тело станции, и его датумы тогда возвращаются в GLOB.antagonists.
/datum/antagonist/proc/sync_training_listing()
	if(owner?.current && is_antag_training_atom(owner.current))
		if(src in GLOB.antagonists)
			GLOB.antagonists -= src
			GLOB.antag_training_unlisted_antagonists += src
		return
	if(src in GLOB.antag_training_unlisted_antagonists)
		GLOB.antag_training_unlisted_antagonists -= src
		GLOB.antagonists += src

/// Запись станции по имени; для атома полигона станционных записей нет.
/proc/antag_training_station_record(list/records_by_name, record_name, atom/subject)
	if(!record_name || is_antag_training_atom(subject))
		return null
	return records_by_name[record_name]

/datum/antag_training_arena/proc/set_level_gate(active)
	var/level = private_level?.z_value
	if(!level)
		return
	if(active && !QDELETED(src))
		GLOB.antag_training_z[level] = TRUE
	else
		GLOB.antag_training_z -= level

/atom/movable/proc/training_move_allowed(atom/destination)
	if(isobserver(src))
		return TRUE
	var/area/antag_training/destination_area = get_area(destination)
	if(!training_origin && !istype(destination_area) && isturf(loc) && !istype(loc.loc, /area/antag_training))
		return TRUE
	if(!training_origin)
		register_training_atom()
		var/atom/movable/container = loc
		while(!training_origin && istype(container))
			training_origin = container.training_origin
			if(training_origin)
				var/datum/antag_training_arena/container_arena = training_origin.resolve()
				if(container_arena && !QDELETED(src))
					container_arena.created_atoms += WEAKREF(src)
			container = container.loc
	if(istype(src, /mob/camera) && !training_origin && istype(destination_area) && destination_area.arena)
		return FALSE
	var/datum/antag_training_arena/origin = training_origin?.resolve()
	if(training_origin && destination && !QDELETED(src))
		if(!origin || origin.finished)
			return FALSE
		if(!origin.owns_area(destination_area))
			return origin.pocket_allows(destination)
		// Выход из «тени» на её же клетку: иначе удаляемая тень унесёт тело с собой.
		if(ismob(src) && istype(loc, /obj/effect/dummy/phased_mob) && isturf(destination) && destination == get_turf(loc))
			return TRUE
		// «Тень» прыжка идёт по полигону за того, кто в ней.
		var/mob/walker = ismob(src) ? src : training_jaunter()
		if(walker && origin.member_move_refusal(walker, destination))
			return FALSE
		if(walker && walker != src && origin.pad_move_refusal(walker, destination))
			return FALSE
		if(origin.duel && origin.duel.phase != "invite" && isliving(walker) && origin.inside_bounds(get_turf(destination), origin.zones["melee"]["bounds"]))
			if(walker != origin.duel.challenger.current_body && walker != origin.duel.opponent.current_body)
				return FALSE
		if(origin.reset_zone_id == "all")
			var/turf/spot = get_turf(destination)
			return origin.inside_bounds(spot, origin.zones["hub"]["bounds"]) || origin.hub?.contains(spot)
		var/list/reset_zone = origin.zones[origin.reset_zone_id]
		return !reset_zone || !origin.inside_bounds(get_turf(destination), reset_zone["bounds"])
	if(istype(destination_area) && destination_area.arena && !destination_area.arena.finished)
		if(!get_turf(src))
			training_origin = WEAKREF(destination_area.arena)
			destination_area.arena.created_atoms += WEAKREF(src)
			return TRUE
		return get_area(src) == destination_area
	return TRUE

/// Почему тело участника не сдвинуть на destination, или null: ИИ своими командами не переносит ядро, в чужой занятый сектор не войти.
/datum/antag_training_arena/proc/member_move_refusal(mob/mover, atom/destination)
	if(isAI(mover) && usr == mover && isturf(mover.loc) && isturf(destination))
		var/datum/antag_training_session/session = session_of(mover)
		if(session)
			var/refusal = "Ядро ИИ не переносится: зоны и сектора ИИ смотрит через камеры."
			session.move_notice(refusal)
			return refusal
	return booking_move_refusal(mover, get_turf(destination))

/// Вход площадки хаба для того, кто идёт сквозь стены в «тени»: барьер его не видит, а пускать его можно не больше, чем пешком.
/datum/antag_training_arena/proc/pad_move_refusal(mob/mover, atom/destination)
	var/turf/spot = get_turf(destination)
	var/datum/antag_training_hub_pad/pad = hub?.pad_at(spot)
	if(!pad || pad.contains(mover))
		return null
	var/datum/antag_training_session/session = session_of(mover)
	var/refusal = pad.entry_refusal(session)
	session?.move_notice(refusal)
	return refusal

/// Тот, кто идёт по полигону в этом контейнере прыжка, или null.
/atom/movable/proc/training_jaunter()
	return null

/obj/effect/dummy/phased_mob/training_jaunter()
	return locate(/mob/living) in src

/datum/antag_training_session/proc/move_notice(message)
	if(!message || world.time < next_move_notice_at)
		return
	next_move_notice_at = world.time + 2 SECONDS
	practice_message(message)

/// Изнанка учебного еретика этой арены - продолжение полигона: туда и по ней можно ходить.
/datum/antag_training_arena/proc/pocket_allows(atom/destination)
	var/turf/spot = get_turf(destination)
	if(!istype(spot?.loc, /area/heretic_pocket))
		return FALSE
	for(var/datum/heretic_pocket/pocket as anything in GLOB.heretic_pockets)
		var/datum/antagonist/heretic/training/heretic = pocket.owner
		if(istype(heretic) && heretic.training?.arena == src && pocket.contains(spot))
			return TRUE
	return FALSE

/atom/movable/proc/register_training_atom()
	var/area/antag_training/location = get_area(src)
	if(training_origin || QDELETED(src) || isobserver(src) || !istype(location) || !location.arena || istype(src, /atom/movable/lighting_object))
		return
	training_origin = WEAKREF(location.arena)
	location.arena.created_atoms += WEAKREF(src)
	if(location.arena.ready && !location.arena.resetting && ismob(usr) && usr.ckey)
		var/datum/antag_training_session/session = GLOB.antag_training_sessions[usr.ckey]
		if(session?.arena == location.arena && session.current_body == usr)
			training_owner = WEAKREF(session)

/// Атом, созданный вне арены для её атома (глаз учебного ИИ), получает тот же полигон и убирается вместе с ним.
/atom/movable/proc/share_training_origin(atom/movable/source)
	if(training_origin || QDELETED(src))
		return FALSE
	var/datum/antag_training_arena/arena = source?.training_origin?.resolve()
	if(!arena || arena.finished)
		return FALSE
	training_origin = source.training_origin
	arena.created_atoms += WEAKREF(src)
	return TRUE

/mob/camera/aiEye/setLoc(T, force_update = FALSE, dir)
	share_training_origin(ai)
	return ..()

/mob/camera/aiEye/pic_in_pic/setLoc(turf/T)
	share_training_origin(screen?.ai)
	return ..()

// Окно мультикамеры ставит центр до привязки к ИИ: глаз получает полигон и встаёт на центр после неё.
/atom/movable/screen/movable/pic_in_pic/ai/set_ai(mob/living/silicon/ai/new_ai)
	. = ..()
	if(aiEye.share_training_origin(new_ai) && center)
		aiEye.setLoc(get_turf(center))

/datum/antag_training_session/proc/mark_kit(atom/movable/holder)
	var/datum/weakref/kit_owner = WEAKREF(src)
	for(var/atom/movable/kit_item as anything in holder?.GetAllContents())
		kit_item.training_kit_owner = kit_owner

/// Почему существу участника нельзя съесть или разобрать цель: внутри другой участник или вещь чужого сеанса. null - можно.
/datum/antag_training_arena/proc/foreign_part_refusal(atom/target, datum/antag_training_session/session, mob/actor)
	for(var/atom/movable/part in target.GetAllContents())
		if(part == actor)
			continue
		if(ismob(part))
			var/datum/antag_training_session/holder = session_of(part)
			if(holder && holder != session)
				return "Других участников полигона трогать нельзя."
		var/datum/antag_training_session/owner = part.training_owner?.resolve()
		var/datum/antag_training_session/kit_owner = part.training_kit_owner?.resolve()
		if((owner && !session?.same_squad(owner)) || (kit_owner && !session?.same_squad(kit_owner)))
			return "[part] - вещь или цель другого участника полигона."
	return null

/datum/antag_training_session/proc/update_safety()
	SIGNAL_HANDLER
	var/mob/living/body = current_body
	if(QDELETED(body) || !isliving(body) || !arena)
		return
	var/turf/spot = get_turf(body)
	arena.hub?.note_presence(spot)
	var/safe = arena.safe_turf(spot)
	if(safe)
		if(!body.alerts["antag_training_safe"])
			to_chat(body, span_notice("Безопасная зона: урон и оглушение отключены. Для проверки способностей перейдите на боевую площадку, в сектор или в мини-станцию хаба."))
		body.throw_alert("antag_training_safe", /atom/movable/screen/alert/antag_training_safe)
		body.status_flags |= GODMODE
		ADD_TRAIT(body, TRAIT_PACIFISM, REF(src))
		ADD_TRAIT(body, TRAIT_STUNIMMUNE, REF(src))
	else
		body.clear_alert("antag_training_safe")
		body.status_flags &= ~GODMODE
		REMOVE_TRAIT(body, TRAIT_PACIFISM, REF(src))
		REMOVE_TRAIT(body, TRAIT_STUNIMMUNE, REF(src))

/atom/movable/screen/alert/antag_training_safe
	name = "Безопасная зона"
	desc = "В центре ядра и в вестибюле хаба отключены урон и оглушение. Перейдите в зону ближнего боя, тир, арену противников, сектор или мини-станцию хаба. Еретики защищены от магии друг друга и за пределами центра: для проверки выберите сопернику роль «Снаряжение и бой»."
	icon_state = "locked"

/datum/antag_training_session/proc/heal_self()
	if(arena?.duel?.includes(src) && arena.duel.phase != "invite")
		arena.duel.finish("Дуэль завершена: участник использовал восстановление.")
	deltimer(recovery_timer)
	recovery_timer = null
	var/mob/living/body = current_body
	if(!isliving(body))
		if(program.rebuild_body(src))
			return TRUE
		to_chat(body, span_warning("Это тело восстановить нельзя: смените программу в разделе «Моя роль» или выйдите с полигона."))
		return FALSE
	body.status_flags &= ~GODMODE
	body.revive(full_heal = TRUE, admin_revive = TRUE)
	if(character_preferences && body == avatar && avatar.dna.species.type == character_preferences.pref_species.type)
		character_preferences.apply_prefs_modified_limbs(avatar)
		character_preferences.apply_tattoos_to_human(avatar)
	body.updatehealth()
	update_safety()
	return TRUE

/// Призрак слышит чат антагов и оповещения о говорящем: с полигона - только на его z, вне полигона - как раньше.
/proc/antag_training_observer_hears(mob/observer, atom/speaker)
	if(!length(GLOB.antag_training_z) || !is_antag_training_atom(speaker))
		return TRUE
	var/turf/speaker_turf = get_turf(speaker)
	if(!speaker_turf)
		return is_antag_training_atom(observer)
	var/turf/observer_turf = get_turf(observer)
	return observer_turf?.z == speaker_turf.z
