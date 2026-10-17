/// Где there относительно here в связке уровней станции; null - другая связка или нет турфа.
/proc/hk47_level_relation(turf/here, turf/there)
	if(!here || !there)
		return null
	if(here.z == there.z)
		return HK47_LEVEL_SAME
	var/list/stack = SSmapping.get_connected_levels(here.z)
	var/here_index = stack.Find(here.z)
	var/there_index = stack.Find(there.z)
	if(!here_index || !there_index)
		return null
	return there_index > here_index ? HK47_LEVEL_ABOVE : HK47_LEVEL_BELOW

/// Машина саботажа, вещь для кражи или тело цели: то, на что смотрит целеуказатель.
/datum/hk_contract/proc/tracked_atom()
	var/atom/movable/thing = get_target()
	if(istype(thing))
		return thing
	return target_body()

/// След охоты для терминала и целеуказателя, без имени цели.
/datum/hk_contract/proc/trace_text()
	var/text
	if(isnull(trace_area))
		text = "След не найден: цель ещё не проявила себя."
	else
		var/minutes = round(trace_age() / (1 MINUTES))
		text = "След: [trace_area], [minutes ? "[minutes] мин. назад" : "только что"]"
		text += trace_cold() ? " - след остыл." : "."
	if(target_near())
		text += " Сигнатура рядом!"
	return text

/// Направление и полоса дальности до цели; null - цель охоты не опознана, по ней только след.
/datum/hk_contract/proc/radar_reading(atom/from)
	if(!trackable())
		return null
	var/turf/here = get_turf(from)
	var/turf/there = get_turf(tracked_atom())
	if(!here || !there)
		return list("lost" = TRUE)
	if(here.z != there.z)
		return list("other_level" = TRUE, "level" = hk47_level_relation(here, there))
	// get_dist от турфа до него же даёт -1.
	var/distance = max(get_dist(here, there), 0)
	var/band = "far"
	if(distance <= HK47_TRACKER_NEAR)
		band = "near"
	else if(distance <= HK47_TRACKER_MID)
		band = "mid"
	return list(
		"distance" = distance,
		"band" = band,
		"dir" = get_dir(here, there),
		"direction" = distance ? dir2text_ru(get_dir(here, there)) : null,
		"angle" = distance ? round(Get_Angle(here, there)) : 0,
	)

/// Стрелка на цель активного контракта: направление и полоса дальности, только на одном уровне.
/datum/status_effect/hk47_tracker
	id = "hk47_tracker"
	duration = -1
	tick_interval = 1 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/hk_pointer/hk47
	/// Состояние стрелки из icons/obj/device.dmi.
	var/pointer

/datum/status_effect/hk47_tracker/on_creation(mob/living/new_owner, ...)
	. = ..()
	if(.)
		update_pointer()

/datum/status_effect/hk47_tracker/tick()
	update_pointer()

/datum/status_effect/hk47_tracker/proc/update_pointer()
	var/datum/antagonist/hk47/hunter = owner?.mind?.has_antag_datum(/datum/antagonist/hk47)
	if(!hunter)
		qdel(src)
		return
	var/datum/hk_contract/contract = hunter.active_contract
	var/new_pointer = "pinonnull"
	var/direction = SOUTH
	var/text
	if(!contract)
		text = "Активного контракта нет. Примите предложение в терминале."
	else if(!contract.trackable())
		text = "Цель не опознана, стрелки нет. [contract.trace_text()]"
	else
		var/static/list/band_names = list("near" = "рядом", "mid" = "близко", "far" = "далеко")
		var/list/reading = contract.radar_reading(owner)
		if(reading["lost"])
			text = "[contract.display_target()]: сигнал потерян."
		else if(reading["other_level"])
			var/static/list/level_names = list(HK47_LEVEL_ABOVE = "выше, на другом уровне", HK47_LEVEL_BELOW = "ниже, на другом уровне")
			text = "[contract.display_target()]: [level_names[reading["level"]] || "на другом уровне"]."
		else
			var/distance = reading["distance"]
			direction = reading["dir"]
			new_pointer = hk_tracker_pointer(distance)
			text = "[contract.display_target()]: [band_names[reading["band"]]][distance ? ", [dir2text_ru(direction)]" : ""]."
	pointer = new_pointer
	var/atom/movable/screen/alert/status_effect/hk_pointer/alert = linked_alert
	alert?.show_pointer(new_pointer, direction, text)

/// Стрелка целеуказателя HK на HUD: корпус пинпоинтера, стрелка оверлеем поворачивается вместе с алертом.
/atom/movable/screen/alert/status_effect/hk_pointer
	icon = 'icons/obj/device.dmi'
	icon_state = "pinpointer"
	var/shown_pointer

/atom/movable/screen/alert/status_effect/hk_pointer/proc/show_pointer(new_pointer, direction, text)
	desc = text
	setDir(direction)
	if(new_pointer == shown_pointer)
		return
	shown_pointer = new_pointer
	cut_overlays()
	add_overlay(new_pointer)

/proc/hk_tracker_pointer(distance)
	if(distance <= 1)
		return "pinondirect"
	if(distance <= HK47_TRACKER_NEAR)
		return "pinonclose"
	if(distance <= HK47_TRACKER_MID)
		return "pinonmedium"
	return "pinonfar"

/atom/movable/screen/alert/status_effect/hk_pointer/hk47
	name = "HK target tracker"
	desc = "Целеуказатель контракта."
	icon_state = "pinpointer_syndicate"

/atom/movable/screen/alert/status_effect/hk_pointer/hk47/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/datum/antagonist/hk47/hunter = owner.mind?.has_antag_datum(/datum/antagonist/hk47)
	hunter?.terminal?.ui_interact(owner)
