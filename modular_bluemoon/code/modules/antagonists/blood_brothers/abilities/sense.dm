/// Алерт на одного брата: по своей категории на каждого, поэтому alert_type у эффекта пустой
/datum/status_effect/brother_sense
	id = "brother_sense"
	status_type = STATUS_EFFECT_MULTIPLE
	tick_interval = -1
	alert_type = null
	on_remove_on_mob_delete = TRUE
	var/datum/mind/tracked
	var/alert_category

/datum/status_effect/brother_sense/on_creation(mob/living/new_owner, datum/mind/tracked_mind)
	tracked = tracked_mind
	return ..()

/datum/status_effect/brother_sense/on_apply()
	. = ..()
	if(!tracked)
		return FALSE
	alert_category = "[id]_[REF(tracked)]"
	var/atom/movable/screen/alert/status_effect/brother_sense/alert = owner.throw_alert(alert_category, /atom/movable/screen/alert/status_effect/brother_sense)
	alert.attached_effect = src
	linked_alert = alert
	refresh()

/datum/status_effect/brother_sense/on_remove()
	owner.clear_alert(alert_category)
	return ..()

/datum/status_effect/brother_sense/Destroy()
	tracked = null
	return ..()

/datum/status_effect/brother_sense/refresh()
	if(!linked_alert || !tracked)
		return
	linked_alert.name = tracked.name
	var/datum/antagonist/brother/own_brother = owner.mind?.has_antag_datum(/datum/antagonist/brother)
	if(own_brother?.is_muted())
		linked_alert.icon_state = "muted"
		linked_alert.desc = "Связь заглушена: [own_brother.mute_text()]. Вы не чувствуете брата."
		return
	var/datum/antagonist/brother/tracked_brother = tracked.has_antag_datum(/datum/antagonist/brother)
	var/state = tracked_brother ? tracked_brother.brother_state() : BROTHER_STATE_GONE
	linked_alert.desc = "Состояние: [brother_state_text(state, tracked.current)]."
	if(state == BROTHER_STATE_MUTED)
		linked_alert.icon_state = "muted"
		return
	if(state == BROTHER_STATE_GONE)
		linked_alert.icon_state = "sense_null"
		return
	var/turf/here = get_turf(owner)
	var/turf/there = get_turf(tracked.current)
	linked_alert.desc += "<br>Где: [blood_bond_direction_text(here, there) || "не понять"]."
	linked_alert.desc += own_brother?.fury_area_hint(state, there)
	point_alert(here, there)

/// Стрелка алерта от here к there; на другом этаже - вверх или вниз, направление остаётся в подсказке
/datum/status_effect/brother_sense/proc/point_alert(turf/here, turf/there)
	var/list/bearing = blood_bond_bearing(here, there)
	if(!bearing)
		linked_alert.icon_state = "sense_null"
		return
	if(bearing["levels"])
		linked_alert.icon_state = bearing["levels"] > 0 ? "sense_up" : "sense_down"
		return
	var/distance = bearing["distance"]
	if(!bearing["dir"] || distance <= 1)
		linked_alert.icon_state = "sense_direct"
		return
	linked_alert.setDir(bearing["dir"])
	if(distance <= BROTHER_SENSE_RANGE_CLOSE)
		linked_alert.icon_state = "sense_close"
	else if(distance <= BROTHER_SENSE_RANGE_FAR)
		linked_alert.icon_state = "sense_medium"
	else
		linked_alert.icon_state = "sense_far"

/atom/movable/screen/alert/status_effect/brother_sense
	name = "Чутьё брата"
	desc = "Где брат и что с ним."
	icon = 'modular_bluemoon/icons/mob/blood_brothers/alerts.dmi'
	icon_state = "sense_null"

/// Состояние брата словами для Чутья
/proc/brother_state_text(state, mob/living/body)
	var/female = body?.gender == FEMALE
	switch(state)
		if(BROTHER_STATE_OK)
			return "в порядке"
		if(BROTHER_STATE_HURT)
			return female ? "ранена" : "ранен"
		if(BROTHER_STATE_CRIT)
			return "без сознания"
		if(BROTHER_STATE_DEAD)
			return female ? "мертва" : "мёртв"
		if(BROTHER_STATE_CUFFED)
			return "в наручниках"
		if(BROTHER_STATE_MUTED)
			return "связь заглушена"
	return "связь пропала"

/// Направление по плоскости, расстояние в тайлах и сдвиг по этажам; null, если уровни не связаны
/proc/blood_bond_bearing(turf/here, turf/there)
	if(!here || !there)
		return null
	var/list/stack = SSmapping.get_connected_levels(here.z)
	var/there_level = stack.Find(there.z)
	if(!there_level)
		return null
	var/turf/flat = locate(there.x, there.y, here.z)
	return list("dir" = get_dir(here, flat), "distance" = max(get_dist(here, flat), 0), "levels" = there_level - stack.Find(here.z))

/// Где цель относительно смотрящего: «северо-восток, близко», «выше», «рядом»; null, если турфа нет
/proc/blood_bond_direction_text(turf/here, turf/there)
	if(!here || !there)
		return null
	var/list/bearing = blood_bond_bearing(here, there)
	if(!bearing)
		return "очень далеко"
	var/list/parts = list()
	var/distance = bearing["distance"]
	if(bearing["dir"] && distance > 1)
		parts += dir2text_ru(bearing["dir"])
		if(distance <= BROTHER_SENSE_RANGE_CLOSE)
			parts += "близко"
		else if(distance <= BROTHER_SENSE_RANGE_FAR)
			parts += "недалеко"
		else
			parts += "далеко"
	if(bearing["levels"])
		parts += bearing["levels"] > 0 ? "выше" : "ниже"
	return length(parts) ? parts.Join(", ") : "рядом"
