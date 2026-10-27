/datum/mood_event/brother_fallen
	description = span_boldwarning("Мой брат мёртв. Нить между нами провисла и тянет душу.\n")
	mood_change = -8
	timeout = BROTHER_GRIEF_MOOD_TIME

/datum/mood_event/brother_severed
	description = span_warning("Связь с братом оборвалась, будто от меня отрезали кусок.\n")
	mood_change = -5
	timeout = 10 MINUTES

/atom/movable/screen/alert/brother_fallen
	name = "Брат пал"
	desc = "Нить к брату провисла. На душе тяжело, пока его не вернут к жизни, но со временем отпустит."
	icon = 'modular_bluemoon/icons/mob/blood_brothers/alerts.dmi'
	icon_state = "fallen"

/// Смерть брата бьёт по живому незаглушённому брату; со стороны горе не видно
/datum/antagonist/brother/proc/grieve(datum/mind/fallen)
	var/mob/living/body = owner.current
	if(!isliving(body) || body.stat == DEAD || is_muted())
		return FALSE
	body.blur_eyes(BROTHER_GRIEF_BLUR)
	SEND_SIGNAL(body, COMSIG_ADD_MOOD_EVENT, "brother_fallen", /datum/mood_event/brother_fallen)
	body.throw_alert("brother_fallen", /atom/movable/screen/alert/brother_fallen, duration_ds = BROTHER_GRIEF_MOOD_TIME)
	to_chat(body, span_userdanger("[fallen.name] пал[fallen.current?.ru_a()]. Нить между вами провисла."))
	body.playsound_local(get_turf(body), 'modular_bluemoon/sound/blood_brothers/brother_fallen.ogg', BROTHER_FALLEN_VOLUME, FALSE, pressure_affected = FALSE)
	trigger_fury(force = TRUE, play_sound = FALSE)
	return TRUE

/// Снять «Брат пал» с тела
/datum/antagonist/brother/proc/clear_grief(mob/living/body = owner.current)
	if(!isliving(body))
		return
	SEND_SIGNAL(body, COMSIG_CLEAR_MOOD_EVENT, "brother_fallen")
	body.clear_alert("brother_fallen")

/// Мёртвых братьев больше не ждут: горе снимается со всех
/datum/team/brother_team/proc/end_grief()
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		brother.clear_grief()

/// Ушедшего не ждут и не оплакивают; разрыв клятвы бьёт по оставшимся
/datum/team/brother_team/proc/forget_departed(datum/mind/departed, reason)
	last_states -= departed
	if(departed in fallen_minds)
		fallen_minds -= departed
		if(!length(fallen_minds))
			end_grief()
	if(reason != BROTHER_DEPARTURE_SEVERED)
		return
	for(var/mob/living/body as anything in living_brothers())
		SEND_SIGNAL(body, COMSIG_ADD_MOOD_EVENT, "brother_severed", /datum/mood_event/brother_severed)
