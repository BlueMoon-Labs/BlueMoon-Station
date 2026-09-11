#define HERETIC_RESOURCE_ALERT "heretic_path_resource"

/datum/antagonist/heretic
	var/datum/weakref/resource_alert_body

/// Состояние берётся из того же источника, что и запись в кодексе.
/datum/antagonist/heretic/proc/update_combat_resource_alert(feedback = FALSE, mob/living/body)
	body ||= owner?.current
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	var/datum/eldritch_knowledge/knowledge = path ? get_knowledge(path.knowledge[1]) : null
	var/list/resource = knowledge?.get_combat_resource_data()
	if(role_removed || QDELETED(body) || !resource)
		clear_combat_resource_alert()
		return
	var/mob/living/previous_body = resource_alert_body?.resolve()
	if(previous_body && previous_body != body)
		clear_combat_resource_alert(previous_body)
	resource_alert_body = WEAKREF(body)
	var/atom/movable/screen/alert/heretic_resource/indicator = body.throw_alert(HERETIC_RESOURCE_ALERT, /atom/movable/screen/alert/heretic_resource, no_anim = TRUE)
	indicator.update_resource(path, resource, feedback)
	return indicator

/datum/antagonist/heretic/proc/clear_combat_resource_alert(mob/living/body)
	body ||= resource_alert_body?.resolve()
	body?.clear_alert(HERETIC_RESOURCE_ALERT)
	if(body == resource_alert_body?.resolve())
		resource_alert_body = null

/atom/movable/screen/alert/heretic_resource
	name = "Запас силы пути"
	desc = "Запас силы выбранного пути."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_blade"
	maptext_width = 32
	maptext_height = 12
	maptext_y = 1
	var/displayed_value
	var/displayed_max
	COOLDOWN_DECLARE(resource_sound)

/atom/movable/screen/alert/heretic_resource/proc/update_resource(datum/heretic_path/path, list/resource, feedback)
	var/value = resource["value"]
	var/capacity = resource["max"]
	var/difference = isnull(displayed_value) ? 0 : value - displayed_value
	displayed_value = value
	displayed_max = capacity
	name = resource["name"]
	desc = "[name]: [value]/[capacity]. [resource["description"]]"
	icon_state = "sigil_[lowertext(path.id)]"
	var/counter_color = value ? "#ffffff" : "#ff9e88"
	maptext = MAPTEXT("<div style='text-align:center;color:[counter_color];font-size:8px;background-color:#17111d'>[value]/[capacity]</div>")
	if(!feedback || !difference)
		return
	// Цвет и масштаб возвращаются без таймера, который мог бы удержать старое тело.
	animate(src)
	color = difference > 0 ? "#b5ffc5" : "#ffc293"
	transform = matrix() * 1.12
	animate(src, color = null, transform = matrix(), time = 0.4 SECONDS)
	if(owner?.client && COOLDOWN_FINISHED(src, resource_sound))
		COOLDOWN_START(src, resource_sound, 0.7 SECONDS)
		owner.playsound_local(get_turf(owner), difference > 0 ? 'modular_bluemoon/sound/heretic/resource_gain.ogg' : 'modular_bluemoon/sound/heretic/resource_spend.ogg', 14, FALSE, pressure_affected = FALSE)

#undef HERETIC_RESOURCE_ALERT
