/atom/movable
	var/datum/weakref/training_origin
	var/datum/weakref/training_owner

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
		if(destination_area != origin.room)
			return origin.pocket_allows(destination)
		if(origin.duel && origin.duel.phase != "invite" && isliving(src) && origin.inside_bounds(get_turf(destination), origin.zones["melee"]["bounds"]))
			if(src != origin.duel.challenger.current_body && src != origin.duel.opponent.current_body)
				return FALSE
		if(origin.reset_zone_id == "all")
			return origin.inside_bounds(get_turf(destination), origin.zones["hub"]["bounds"])
		return !origin.reset_zone_id || !origin.inside_bounds(get_turf(destination), origin.zones[origin.reset_zone_id]["bounds"])
	if(istype(destination_area) && destination_area.arena && !destination_area.arena.finished)
		if(!get_turf(src))
			training_origin = WEAKREF(destination_area.arena)
			destination_area.arena.created_atoms += WEAKREF(src)
			return TRUE
		return get_area(src) == destination_area
	return TRUE

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

/datum/antag_training_session/proc/update_safety()
	SIGNAL_HANDLER
	if(QDELETED(current_body) || !arena)
		return
	var/safe = arena.inside_bounds(get_turf(current_body), arena.zones["hub"]["bounds"])
	if(safe)
		if(!current_body.alerts["antag_training_safe"])
			to_chat(current_body, span_notice("Безопасный центр: урон и оглушение отключены. Для проверки способностей перейдите на боевую площадку."))
		current_body.throw_alert("antag_training_safe", /atom/movable/screen/alert/antag_training_safe)
		current_body.status_flags |= GODMODE
		ADD_TRAIT(current_body, TRAIT_PACIFISM, REF(src))
		ADD_TRAIT(current_body, TRAIT_STUNIMMUNE, REF(src))
	else
		current_body.clear_alert("antag_training_safe")
		current_body.status_flags &= ~GODMODE
		REMOVE_TRAIT(current_body, TRAIT_PACIFISM, REF(src))
		REMOVE_TRAIT(current_body, TRAIT_STUNIMMUNE, REF(src))

/atom/movable/screen/alert/antag_training_safe
	name = "Безопасный центр"
	desc = "Здесь отключены урон и оглушение. Перейдите в зону ближнего боя, тир или арену противников. Еретики защищены от магии друг друга и за пределами центра: для проверки выберите сопернику роль «Снаряжение и бой»."
	icon_state = "locked"

/datum/antag_training_session/proc/heal_self()
	if(arena?.duel?.includes(src) && arena.duel.phase != "invite")
		arena.duel.finish("Дуэль завершена: участник использовал восстановление.")
	deltimer(recovery_timer)
	recovery_timer = null
	current_body.status_flags &= ~GODMODE
	current_body.revive(full_heal = TRUE, admin_revive = TRUE)
	if(character_preferences && current_body == avatar)
		character_preferences.apply_prefs_modified_limbs(avatar)
		character_preferences.apply_tattoos_to_human(avatar)
	current_body.updatehealth()
	update_safety()
