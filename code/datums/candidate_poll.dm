/datum/candidate_poll
	var/role
	var/show_role_on_hud = TRUE
	var/question
	var/duration
	var/atom/jump_to_me
	var/ignoring_category
	var/list/mob/signed_up
	var/list/atom/movable/screen/alert/poll_alert/alert_buttons = list()
	var/time_started
	var/finished = FALSE
	var/poll_key
	var/list/response_messages = list(
		POLL_RESPONSE_SIGNUP = "Вы записались на роль %ROLE%!",
		POLL_RESPONSE_ALREADY_SIGNED = "Вы уже записаны на этот опрос.",
		POLL_RESPONSE_NOT_SIGNED = "Вы не записаны на этот опрос.",
		POLL_RESPONSE_TOO_LATE_TO_UNREGISTER = "Слишком поздно!",
		POLL_RESPONSE_UNREGISTERED = "Вы снялись с получения %ROLE%.",
	)
	var/list/chosen_candidates = list()

/datum/candidate_poll/New(polled_role, polled_question, poll_duration, poll_ignoring_category, poll_jumpable, list/custom_response_messages = list(), show_role_on_hud = TRUE)
	role = polled_role
	src.show_role_on_hud = show_role_on_hud
	question = polled_question
	duration = poll_duration
	ignoring_category = poll_ignoring_category
	jump_to_me = poll_jumpable
	signed_up = list()
	time_started = world.time
	poll_key = "[question]_[role ? role : "0"]"
	if(custom_response_messages.len)
		response_messages = custom_response_messages
	for(var/key in response_messages)
		response_messages[key] = replacetext(response_messages[key], "%ROLE%", "[role]")
	return ..()

/datum/candidate_poll/Destroy()
	if(SSpolling?.currently_polling && (src in SSpolling.currently_polling))
		SSpolling.currently_polling -= src
	jump_to_me = null
	signed_up = null
	alert_buttons = null
	return ..()

/datum/candidate_poll/proc/clear_alert_ref(atom/movable/screen/alert/poll_alert/source)
	SIGNAL_HANDLER
	alert_buttons -= source

/datum/candidate_poll/proc/sign_up(mob/candidate, silent = FALSE)
	if(!istype(candidate) || isnull(candidate.key) || isnull(candidate.client))
		return FALSE
	if(candidate in signed_up)
		if(!silent)
			to_chat(candidate, span_warning(response_messages[POLL_RESPONSE_ALREADY_SIGNED]))
		return FALSE
	if(time_left() <= 0)
		if(!silent)
			to_chat(candidate, span_danger("Слишком поздно для записи!"))
			SEND_SOUND(candidate, 'sound/machines/buzz-sigh.ogg')
		return FALSE

	signed_up += candidate
	log_game("Ghost poll: [candidate.key] signed up for [role] ([question]).")

	if(!silent)
		to_chat(candidate, span_notice(response_messages[POLL_RESPONSE_SIGNUP]))

	for(var/datum/candidate_poll/existing_poll as anything in SSpolling.currently_polling)
		if(src != existing_poll && poll_key == existing_poll.poll_key && !(candidate in existing_poll.signed_up))
			existing_poll.sign_up(candidate, TRUE)
	for(var/atom/movable/screen/alert/poll_alert/linked_button as anything in alert_buttons)
		linked_button.update_candidates_number_overlay()
	return TRUE

/datum/candidate_poll/proc/remove_candidate(mob/candidate, silent = FALSE)
	if(!istype(candidate) || isnull(candidate.key) || isnull(candidate.client))
		return FALSE
	if(!(candidate in signed_up))
		if(!silent)
			to_chat(candidate, span_warning(response_messages[POLL_RESPONSE_NOT_SIGNED]))
		return FALSE
	if(time_left() <= 0)
		if(!silent)
			to_chat(candidate, span_danger(response_messages[POLL_RESPONSE_TOO_LATE_TO_UNREGISTER]))
		return FALSE

	signed_up -= candidate
	log_game("Ghost poll: [candidate.key] removed from [role].")

	if(!silent)
		to_chat(candidate, span_danger(response_messages[POLL_RESPONSE_UNREGISTERED]))

	for(var/datum/candidate_poll/existing_poll as anything in SSpolling.currently_polling)
		if(src != existing_poll && poll_key == existing_poll.poll_key && (candidate in existing_poll.signed_up))
			existing_poll.remove_candidate(candidate, TRUE)
	for(var/atom/movable/screen/alert/poll_alert/linked_button as anything in alert_buttons)
		linked_button.update_candidates_number_overlay()
	return TRUE

/datum/candidate_poll/proc/do_never_for_this_round(mob/candidate)
	if(!ignoring_category)
		return
	var/list/ignore_list = GLOB.poll_ignore[ignoring_category]
	if(!ignore_list)
		GLOB.poll_ignore[ignoring_category] = list()
	GLOB.poll_ignore[ignoring_category] += candidate.ckey
	to_chat(candidate, span_danger("Выбрано: не предлагать эту роль до конца раунда."))
	remove_candidate(candidate, silent = TRUE)

/datum/candidate_poll/proc/undo_never_for_this_round(mob/candidate)
	if(!ignoring_category)
		return
	GLOB.poll_ignore[ignoring_category] -= candidate.ckey
	to_chat(candidate, span_notice("Снова доступны опросы этой категории."))

/datum/candidate_poll/proc/trim_candidates()
	listclearnulls(signed_up)
	for(var/mob/candidate as anything in signed_up)
		if(isnull(candidate.key) || isnull(candidate.client))
			signed_up -= candidate

/datum/candidate_poll/proc/time_left()
	return duration - (world.time - time_started)
