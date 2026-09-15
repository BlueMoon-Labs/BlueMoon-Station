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
	var/obj/effect/proc_holder/spell/power = knowledge.combat_power
	if(istype(knowledge, /datum/eldritch_knowledge/base_moon))
		var/datum/eldritch_knowledge/base_moon/moon = knowledge
		power = moon.reflection_spell
	else if(istype(knowledge, /datum/eldritch_knowledge/base_cosmic))
		var/datum/eldritch_knowledge/base_cosmic/cosmic = knowledge
		power = cosmic.manifest_spell
	else if(istype(knowledge, /datum/eldritch_knowledge/base_lock))
		var/datum/eldritch_knowledge/base_lock/lock = knowledge
		power = lock.seal_spell
	var/atom/movable/screen/alert/heretic_resource/indicator = body.throw_alert(HERETIC_RESOURCE_ALERT, /atom/movable/screen/alert/heretic_resource, no_anim = TRUE)
	indicator.update_resource(path, resource, feedback, power)
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
	var/datum/weakref/power_ref
	COOLDOWN_DECLARE(resource_sound)

/atom/movable/screen/alert/heretic_resource/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/living/user = usr
	return activate_power(user)

/atom/movable/screen/alert/heretic_resource/proc/activate_power(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/obj/effect/proc_holder/spell/power = power_ref?.resolve()
	if(QDELETED(src) || user != owner || !heretic || heretic.role_removed || heretic.owner?.current != user)
		return FALSE
	if(user.incapacitated())
		to_chat(user, span_warning("Вы не можете действовать: дождитесь окончания оглушения или освободитесь."))
		return FALSE
	if(QDELETED(power) || !(power in user.mind.spell_list))
		to_chat(user, span_warning("Способность этого значка больше недоступна. Проверьте изученные способности в кодексе."))
		return FALSE
	if(!power.cast_check(FALSE, user))
		return FALSE
	power.choose_targets(user)
	return TRUE

/atom/movable/screen/alert/heretic_resource/proc/update_resource(datum/heretic_path/path, list/resource, feedback, obj/effect/proc_holder/spell/power)
	var/value = resource["value"]
	var/capacity = resource["max"]
	var/difference = isnull(displayed_value) ? 0 : value - displayed_value
	displayed_value = value
	displayed_max = capacity
	name = resource["name"]
	desc = "[name]: [value]/[capacity]. [resource["description"]]"
	power_ref = QDELETED(power) ? null : WEAKREF(power)
	if(power_ref)
		name += " — [power.name]"
		desc += " Нажмите на этот значок, чтобы применить «[power.name]». Если способность требует цель, затем укажите её на игровом поле."
	if(path.id == PATH_BLOOD)
		name = value ? "Кровный долг — взыскать" : "Кровный долг — связать"
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

#define HERETIC_CODEX_ALERT "heretic_codex"

/datum/antagonist/heretic
	var/codex_summoned = FALSE

/datum/antagonist/heretic/proc/update_codex_alert(mob/living/body)
	body ||= innate_body || owner?.current
	if(QDELETED(body))
		return
	if(role_removed || codex_summoned || !(locate(/obj/item/forbidden_book) in summon_items))
		body.clear_alert(HERETIC_CODEX_ALERT)
		return
	body.throw_alert(HERETIC_CODEX_ALERT, /atom/movable/screen/alert/heretic_codex, no_anim = TRUE)

/datum/antagonist/heretic/proc/clear_codex_alert(mob/living/body)
	body?.clear_alert(HERETIC_CODEX_ALERT)

/datum/antagonist/heretic/proc/on_codex_summoned()
	codex_summoned = TRUE
	update_codex_alert()

/atom/movable/screen/alert/heretic_codex
	name = "Кодекс ждёт"
	desc = "Кодекс ещё не призван. Нажмите сюда или на способность «Призвать кодекс», чтобы получить книгу и выбрать путь."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "codex"

/atom/movable/screen/alert/heretic_codex/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/living/user = usr
	if(!istype(user) || user != owner)
		return
	var/obj/effect/proc_holder/spell/self/heretic_summon/book/spell = locate() in user.mind?.spell_list
	spell?.choose_targets(user)

#undef HERETIC_CODEX_ALERT
