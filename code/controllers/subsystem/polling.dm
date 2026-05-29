SUBSYSTEM_DEF(polling)
	name = "Polling"
	flags = SS_BACKGROUND | SS_NO_INIT
	wait = 1 SECONDS
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	var/list/datum/candidate_poll/currently_polling
	var/total_polls = 0

/datum/controller/subsystem/polling/Initialize()
	currently_polling = list()
	return ..()

/datum/controller/subsystem/polling/fire()
	if(!currently_polling)
		currently_polling = list()
	for(var/datum/candidate_poll/running_poll as anything in currently_polling)
		if(running_poll.time_left() <= 0)
			polling_finished(running_poll)

/datum/controller/subsystem/polling/proc/poll_ghost_prefiltered(
	question,
	poll_time = 30 SECONDS,
	ignore_category = null,
	flash_window = TRUE,
	list/group = null,
	role_name_text = null,
	alert_pic = null,
	jump_target = null,
	chat_text_border_icon = null,
)
	var/list/result = list()
	if(!LAZYLEN(group))
		return result
	if(!question)
		question = "Would you like to be a special role?"
	var/rnam = role_name_text || "Ghost role"
	var/show_hud_role = !isnull(role_name_text) && length(role_name_text)
	if(isnull(jump_target) && isatom(alert_pic))
		jump_target = alert_pic

	total_polls++
	var/datum/candidate_poll/new_poll = new /datum/candidate_poll(rnam, question, poll_time, ignore_category, jump_target, list(), show_hud_role)
	LAZYADD(currently_polling, new_poll)

	var/category = "[new_poll.poll_key]_poll_alert"

	for(var/mob/candidate_mob as anything in group)
		if(!candidate_mob.client)
			continue
		if(flash_window)
			window_flash(candidate_mob.client)
		SEND_SOUND(candidate_mob, sound('sound/misc/notice2.ogg'))

		var/atom/movable/screen/alert/poll_alert/current_alert = LAZYACCESS(candidate_mob.alerts, category)
		var/alert_time = poll_time
		var/datum/candidate_poll/alert_poll = new_poll
		if(current_alert && istype(current_alert, /atom/movable/screen/alert/poll_alert) && current_alert.timeout > (world.time + poll_time - world.tick_lag))
			alert_time = current_alert.timeout - world.time + world.tick_lag
			alert_poll = current_alert.poll

		var/atom/movable/screen/alert/poll_alert/poll_alert_button = candidate_mob.throw_alert(category, /atom/movable/screen/alert/poll_alert, null, null, FALSE, alert_time, TRUE)
		if(!poll_alert_button)
			continue

		new_poll.alert_buttons += poll_alert_button
		new_poll.RegisterSignal(poll_alert_button, COMSIG_PARENT_QDELETING, TYPE_PROC_REF(/datum/candidate_poll, clear_alert_ref))

		if(candidate_mob.client?.prefs?.UI_style)
			poll_alert_button.icon = ui_style2icon(candidate_mob.client.prefs.UI_style)
		poll_alert_button.desc = "[question]"
		poll_alert_button.show_time_left = TRUE
		poll_alert_button.poll = alert_poll
		poll_alert_button.set_role_overlay()
		poll_alert_button.update_stacks_overlay()
		poll_alert_button.update_candidates_number_overlay()
		poll_alert_button.update_signed_up_overlay()

		for(var/datum/candidate_poll/other_poll as anything in currently_polling)
			if(new_poll == other_poll || new_poll.poll_key != other_poll.poll_key)
				continue
			if((candidate_mob in other_poll.signed_up) && new_poll.sign_up(candidate_mob, TRUE))
				break

		var/mutable_appearance/poll_image
		if(ispath(alert_pic, /atom) || isatom(alert_pic))
			poll_image = new /mutable_appearance(alert_pic)
			if(ispath(alert_pic, /atom))
				poll_image.pixel_z = 0
		else if(!isnull(alert_pic))
			poll_image = alert_pic
		else
			poll_image = mutable_appearance('icons/effects/effects.dmi', "static")

		if(poll_image)
			poll_image.layer = FLOAT_LAYER
			poll_image.plane = poll_alert_button.plane
			poll_alert_button.add_overlay(poll_image)

		var/surrounding_icon = ""
		if(chat_text_border_icon)
			if(ispath(chat_text_border_icon))
				surrounding_icon = icon2html(image(chat_text_border_icon), candidate_mob, sourceonly = TRUE)
			else
				surrounding_icon = icon2html(chat_text_border_icon, candidate_mob, sourceonly = TRUE)

		var/chat_body = "[surrounding_icon ? "[surrounding_icon] " : ""]<span class='boldnotice'>[question]</span><br><span class='notice'>Иконка опроса справа сверху. Клик — записаться / отписаться. Таймер на иконке.</span>"
		if(ignore_category)
			chat_body += "<br><span class='warning'>Категория игнора: можно отказаться от этой роли на раунд через опрос (ALT+ЛКМ по иконке, если доступно).</span>"
		to_chat(candidate_mob, chat_body)

		START_PROCESSING(SSprocessing, poll_alert_button)

	UNTIL(new_poll.finished)

	for(var/mob/M in new_poll.signed_up)
		if(M?.key && M?.client && !QDELETED(M))
			result += M
	listclearnulls(result)
	return result

/datum/controller/subsystem/polling/proc/polling_finished(datum/candidate_poll/finishing_poll)
	if(!finishing_poll)
		return
	currently_polling -= finishing_poll
	var/length_pre_trim = length(finishing_poll.signed_up)
	finishing_poll.trim_candidates()

	log_game("Ghost poll finished: [finishing_poll.role], signed [length_pre_trim], kept [length(finishing_poll.signed_up)].")

	finishing_poll.finished = TRUE

	if(length(finishing_poll.alert_buttons))
		for(var/atom/movable/screen/alert/poll_alert/alert as anything in finishing_poll.alert_buttons)
			if(!QDELETED(alert) && alert.owner)
				alert.owner.clear_alert("[finishing_poll.poll_key]_poll_alert")

	QDEL_IN(finishing_poll, 0.5 SECONDS)

/datum/controller/subsystem/polling/proc/duplicate_message_check(datum/candidate_poll/poll_to_check)
	for(var/datum/candidate_poll/running_poll as anything in currently_polling)
		if((running_poll.poll_key == poll_to_check.poll_key && running_poll != poll_to_check) && running_poll.time_left() > 0)
			return TRUE
	return FALSE
